"""Completa a capacidade das candidatas externas com o cache CNES 2014-2021.

Preserva os produtos das 84 originais. Dezembro mede capacidade; os demais
meses registram presenca para sensibilidade, sem imputar capacidade mensal.
"""
import csv
import importlib.util
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / 'outputs'
spec = importlib.util.spec_from_file_location('historico', HERE / '09_temporalizar_cnes_historico_saude.py')
hist = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hist)


def read(name):
    with (OUT / name).open(encoding='utf-8-sig', newline='') as handle:
        return list(csv.DictReader(handle))


def function(code):
    if code in hist.MOBILE_TYPES:
        return 'unidade_movel'
    if code in {'04', '05', '22', '36', '39', '62', '70'}:
        return 'destino_clinico_fixo'
    if code in {'64', '68', '76', '81'}:
        return 'estrutura_fixa_nao_clinica'
    raise ValueError(f'Tipo CNES nao classificado: {code}')


def main():
    candidates = {r['cnpj_raiz_8']: r for r in read('revisao_fora_84_resultado.csv')
                  if r['decisao'] in {'candidato_saude_historica', 'saude_historica_escopo_a_segregar'}}
    assert len(candidates) == 13
    converter = hist.locate_blast_dbf()
    monthly = defaultdict(set)
    month_types = defaultdict(set)
    rows = []
    for year in hist.YEARS:
        december = None
        for month in range(1, 13):
            _, path = hist.source_path('ST', year, month)
            selected = hist.select_establishments(path, converter, set(candidates), candidates, {}, year, month)
            for unit in selected.values():
                key = unit['cnpj_raiz_8'], year, unit['cnes']
                monthly[key].add(month)
                month_types[key].add(unit['tipo_unidade_codigo'])
            if month == 12:
                december = selected
        assert december is not None
        codes = set(december)
        cap = {table: hist.capacity_by_unit(hist.source_path(table, year)[1], converter, codes, table)
               for table in ('LT', 'SR', 'PF')}
        for unit in december.values():
            cnes = unit['cnes']
            beds, services, staff = (cap[t].get(cnes, {}) for t in ('LT', 'SR', 'PF'))
            unit.update(funcao_assistencial=function(unit['tipo_unidade_codigo']),
                        leitos_sus=beds.get('leitos_sus', 0),
                        leitos_existentes=beds.get('leitos_existentes', 0),
                        n_servicos_especializados_sus=len(services.get('servicos_sus', set())),
                        n_cbo_medicos_sus_distintos=len(staff.get('cbos_medicos_sus', set())),
                        n_profissionais_sus_distintos=len(staff.get('profissionais_sus', set())),
                        carga_horaria_sus=staff.get('carga_horaria_sus', 0),
                        n_meses_presente=len(monthly[(unit['cnpj_raiz_8'], year, cnes)]))
            rows.append(unit)
        print(f'CNES candidatas {year}: {len(december)} unidades em dezembro', flush=True)
    assert len(rows) == 74
    hist.write_csv(OUT / 'candidatas_cnes_capacidade_unidades_2014_2021.csv', rows, list(rows[0]))
    entity_year = []
    for root, candidate in sorted(candidates.items()):
        for year in hist.YEARS:
            own = [r for r in rows if r['cnpj_raiz_8'] == root and r['ano'] == year]
            clinical = [r for r in own if r['funcao_assistencial'] == 'destino_clinico_fixo']
            any_clinical = {cnes for (r, y, cnes), types in month_types.items()
                            if (r, y) == (root, year) and any(function(t) == 'destino_clinico_fixo' for t in types)}
            entity_year.append(dict(
                cnpj_raiz_8=root, ano=year, decisao=candidate['decisao'],
                n_unidades_dezembro=len(own), n_destinos_clinicos_dezembro=len(clinical),
                n_estruturas_nao_clinicas_dezembro=sum(r['funcao_assistencial'] == 'estrutura_fixa_nao_clinica' for r in own),
                n_destinos_clinicos_algum_mes=len(any_clinical),
                n_municipios_clinicos_dezembro=len({r['codigo_ibge_6'] for r in clinical}),
                leitos_sus_clinicos=sum(r['leitos_sus'] for r in clinical) if clinical else '',
                servicos_sus_clinicos_soma_unidades=sum(r['n_servicos_especializados_sus'] for r in clinical) if clinical else '',
                cbo_medicos_sus_clinicos_soma_unidades=sum(r['n_cbo_medicos_sus_distintos'] for r in clinical) if clinical else '',
                profissionais_sus_clinicos_soma_unidades=sum(r['n_profissionais_sus_distintos'] for r in clinical) if clinical else '',
                carga_horaria_sus_clinicos=sum(r['carga_horaria_sus'] for r in clinical) if clinical else '',
                capacidade_status='clinica_direta_dezembro' if clinical else 'sem_clinica_direta_dezembro'))
    hist.write_csv(OUT / 'candidatas_cnes_capacidade_entidade_ano_2014_2021.csv',
                   entity_year, list(entity_year[0]))
    presence = [dict(cnpj_raiz_8=root, ano=year, cnes=cnes,
                     meses_presente=' | '.join(f'{m:02d}' for m in sorted(months)),
                     tipos_cnes=' | '.join(sorted(month_types[(root, year, cnes)])))
                for (root, year, cnes), months in sorted(monthly.items())]
    hist.write_csv(OUT / 'candidatas_cnes_presenca_mensal_2014_2021.csv', presence, list(presence[0]))
    print(f'OK: {len(rows)} unidades-ano, {len(entity_year)} entidades-ano, {len(presence)} presencas por unidade-ano.')


if __name__ == '__main__':
    main()
