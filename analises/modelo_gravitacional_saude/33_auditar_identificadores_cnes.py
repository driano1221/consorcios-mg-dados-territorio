"""Audita os oito ST de dezembro; cria insumo corrigido sem sobrescrever a v1.

Executar antes de 31/32/34. Reusa DBC locais e o extrator 09 corrigido.
Nao publica CPF: o registro de auditoria contem CNES, tipo e validade apenas.
"""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import importlib.util
import json
import pandas as pd

HERE = Path(__file__).resolve().parent
OUT = HERE / 'outputs/auditoria_alternativas'
SPEC = importlib.util.spec_from_file_location('hist', HERE/'09_temporalizar_cnes_historico_saude.py')
hist = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(hist)
SOURCES = ['elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv',
           'candidatas_cnes_capacidade_unidades_2014_2021.csv']


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    units = pd.concat([pd.read_csv(HERE/'outputs'/p, dtype=str).fillna('') for p in SOURCES],
                      ignore_index=True).fillna('')
    assert not units.duplicated(['cnpj_raiz_8','ano','cnes']).any()
    converter = hist.locate_blast_dbf()

    def audit_year(year):
        old = units[units.ano == str(year)].set_index('cnes')
        roots = set(units.cnpj_raiz_8)
        rows = []
        url, path = hist.source_path('ST', year)
        seen = set()
        for r in hist.dbf_rows(path, converter):
            cnes = hist.digits(r['CNES'], 7)
            if cnes not in old.index:
                continue
            assert cnes not in seen
            seen.add(cnes)
            before = old.loc[cnes]
            own = None if str(r.get('PF_PJ')) == '1' else hist.cnpj_root(r.get('CPF_CNPJ'), roots)
            maintainer = hist.cnpj_root(r.get('CNPJ_MAN'), roots)
            assert not (own and maintainer and own != maintainer)
            keep = before.cnpj_raiz_8 in (own, maintainer)
            # Verifica que estamos auditando exatamente a fonte dos derivados.
            assert hist.digits(r['CPF_CNPJ'],14) == before.cnpj_proprio_cnes
            assert hist.digits(r['CNPJ_MAN'],14) == before.cnpj_mantenedora_cnes
            rows.append(dict(ano=year,cnes=cnes,cnpj_raiz_8=before.cnpj_raiz_8,
                pf_pj=str(r.get('PF_PJ')),vinculo_valido=keep,
                documento_proprio_cnpj_valido=bool(hist.cnpj_root(r['CPF_CNPJ'],roots)),
                mantenedora_alvo_valida=bool(maintainer),
                horas_sus=float(before.carga_horaria_sus),
                motivo='vinculo_cnpj_validado' if keep else 'cpf_nao_e_cnpj_do_consorcio'))
        assert len(seen) == len(old)
        print(f'{year}: {len(rows)} unidades conferidas no ST bruto', flush=True)
        return rows, dict(arquivo=str(path.relative_to(HERE)),url=url,
                         sha256=hist.file_sha256(path))

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(audit_year, hist.YEARS))
    audit = pd.DataFrame([r for rows,_ in results for r in rows])
    rejected = audit[~audit.vinculo_valido]
    keys = set(zip(rejected.cnpj_raiz_8,rejected.ano.astype(str),rejected.cnes))
    keep = [k not in keys for k in zip(units.cnpj_raiz_8,units.ano,units.cnes)]
    corrected = units.loc[keep].copy()
    # Nao propaga identificadores de pessoa fisica aos novos derivados.
    cpf_keys = set(zip(audit.loc[audit.pf_pj=='1','ano'].astype(str),audit.loc[audit.pf_pj=='1','cnes']))
    corrected.loc[[(y,c) in cpf_keys for y,c in zip(corrected.ano,corrected.cnes)],'cnpj_proprio_cnes'] = ''
    assert len(audit)==len(units) and rejected.horas_sus.sum()==0
    for name, data in [('identificadores_cnes',audit),('vinculos_cnes_rejeitados',rejected),
                       ('unidades_cnes_dezembro_corrigidas',corrected)]:
        data.to_csv(OUT/f'{name}.csv',index=False,encoding='utf-8-sig')
    manifest = [m for _,m in results]
    for p in SOURCES:
        path=HERE/'outputs'/p
        manifest.append(dict(arquivo=str(path.relative_to(HERE)),url='derivado_local',sha256=hist.file_sha256(path)))
    pd.DataFrame(manifest).to_csv(OUT/'fontes_identificadores.csv',index=False)
    summary=dict(unidades_ano_antes=len(units),unidades_ano_depois=len(corrected),
        rejeitadas=len(rejected),cnes_rejeitados=sorted(set(rejected.cnes)),
        horas_sus_retiradas=float(rejected.horas_sus.sum()),
        escopo='oito dezembros; serie mensal e v1 publicadas preservadas, requerem republicacao')
    (OUT/'resumo_identificadores.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    print(summary)


if __name__ == '__main__':
    main()
