"""Triagem fora das 84: cadastro MG + CNM, com CNES historico ja baixado.

Nao altera o universo original nem interpreta ausencia no CNES como ausencia
de saude. O produto distingue triagem cadastral de decisao documental.
"""
import csv
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = HERE / 'outputs'
CNM = Path('C:/IPEA/dados cnm/snapshots/2026-08-27/data/base_unificada_consorcios_macroareas.csv')
SPEC = importlib.util.spec_from_file_location('historico', HERE / '09_temporalizar_cnes_historico_saude.py')
hist = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(hist)


def read(path, encoding='utf-8-sig', delimiter=','):
    with Path(path).open(encoding=encoding, newline='') as f:
        return list(csv.DictReader(f, delimiter=delimiter))


def main():
    original = {r['cnpj_raiz_8'] for r in read(OUT / 'universo_saude_mg_entidades.csv')}
    classification = read(ROOT / 'analises/classificacao_politicas/outputs/classificacao_areas_politica_mg_v0_5_completa.csv')
    national = read(ROOT / 'analises/base_nacional/outputs/cadastro_consorcios_nacional_consolidado.csv', 'cp1252')
    cnm = [r for r in read(CNM, delimiter=';') if r['sede_municipio_uf'] == 'MG']
    catalog = {}
    for r in national:
        if r['uf_sede_canonica'] == 'MG' and r['cnpj_raiz_8'] not in original:
            root = r['cnpj_raiz_8']
            areas = sorted({c['area_politica_final'] for c in classification if c['cnpj_consorcio'][:8] == root})
            catalog[root] = dict(cnpj_raiz_8=root, cnpj_canonico=r['cnpj_canonico'],
                sigla_canonica=r['sigla_canonica'], razao_social=r['razao_social_canonica'],
                municipio_sede=r['municipio_sede_canonico'], origem='cadastro_ipea_mg',
                area_v05=' | '.join(areas), situacao=r['situacao_matriz'],
                ano_abertura=r['ano_abertura_matriz'], cnm_saude='0', cnm_areas='', cnm_url='')
    for r in cnm:
        cnpj = hist.digits(r['consorcio_cnpj'], 14)
        root = cnpj[:8]
        if root in original:
            continue
        if root not in catalog:
            catalog[root] = dict(cnpj_raiz_8=root, cnpj_canonico=cnpj,
                sigla_canonica=r['consorcio_sigla'], razao_social=r['consorcio_nome'],
                municipio_sede=r['sede_municipio_nome'], origem='somente_cnm_mg', area_v05='',
                situacao=r['consorcio_situacao_cnpj'], ano_abertura=r['consorcio_data_constituicao'][:4])
        catalog[root].update(cnm_saude=r['grupo_area_saude'], cnm_areas=r['areas_atuacao'],
                             cnm_url=r['consorcio_site'])
    assert len(catalog) == 137 and not original.intersection(catalog)
    hist.write_csv(OUT / 'fronteira_universo_cadastro.csv', list(catalog.values()), list(next(iter(catalog.values()))))
    # Reusa conversao e selecao do script 09; oito arquivos ST de dezembro,
    # sem nova transferencia ou alteracao das 120 fontes originais.
    converter = hist.locate_blast_dbf()
    units, manifest = [], []
    for year in hist.YEARS:
        url, path = hist.source_path('ST', year)
        if not path.exists():
            raise FileNotFoundError(path)
        selected = hist.select_establishments(path, converter, set(catalog), catalog, {}, year, 12)
        units.extend(selected.values())
        manifest.append(dict(ano=year, arquivo=path.name, sha256=hist.file_sha256(path), url=url))
        print(f'Fronteira CNES {year}: {len(selected)} unidades', flush=True)
    for u in units:
        t = u['tipo_unidade_codigo']
        u['funcao_assistencial'] = ('unidade_movel' if t in hist.MOBILE_TYPES else
            'destino_clinico_fixo' if t in {'04','05','22','36','39','62','70'} else
            'estrutura_fixa_nao_clinica' if t in {'64','68','76','81'} else 'tipo_a_revisar')
    assert all(u['funcao_assistencial'] != 'tipo_a_revisar' for u in units), sorted({u['tipo_unidade_codigo'] for u in units})
    hist.write_csv(OUT / 'fronteira_cnes_unidades_2014_2021.csv', units, list(units[0]))
    hist.write_csv(OUT / 'fronteira_cnes_fontes.csv', manifest, list(manifest[0]))
    for root, row in catalog.items():
        own = [u for u in units if u['cnpj_raiz_8'] == root]
        row.update(n_unidades_ano_cnes=len(own), anos_cnes=' | '.join(map(str, sorted({u['ano'] for u in own}))),
                   cnes=' | '.join(sorted({u['cnes'] for u in own})))
    hist.write_csv(OUT / 'fronteira_universo_cadastro.csv', list(catalog.values()), list(next(iter(catalog.values()))))
    print(json.dumps([r for r in catalog.values() if r['n_unidades_ano_cnes']], ensure_ascii=True, indent=2))


if __name__ == '__main__':
    main()
