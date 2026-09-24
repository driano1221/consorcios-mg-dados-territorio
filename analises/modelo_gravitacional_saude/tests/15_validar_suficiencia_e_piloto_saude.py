"""Protege periodos, identidade dos prestadores e conservacao financeira."""
import csv
import hashlib
from decimal import Decimal
from pathlib import Path

HERE = Path(__file__).resolve().parents[1]
OUT = HERE / 'outputs'


def read(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def key(r):
    return r['cnpj_raiz_8'], r['ano']


old = read(HERE / 'evidencias/conciliacao_181_entidades_ano_2026_09_24.csv')
updated = read(OUT / 'conciliacao_lacunas_com_revisao_prioritaria_saude.csv')
assert len(updated) == 181 and [key(r) for r in old] == [key(r) for r in updated]
assert [r['valor_mides'] for r in old] == [r['valor_mides'] for r in updated]
assert sum(bool(r['decisao_revisada']) for r in updated) == 14
assert all(r['decisao_vigente'] for r in updated)
assert all(r['polo_anual_integral_recuperado'] == 'FALSE' for r in updated if r['decisao_revisada'])
audit = {key(r): r for r in updated}
assert audit['71203715', '2017']['cnes_associado'] == '6019463'
assert audit['97550393', '2019']['cnes_associado'] == ''
assert 'tres meses' in audit['97550393', '2019']['periodo_documentado']
assert all(not r['cnes_associado'] for r in updated if r['cnpj_raiz_8'] == '01124788')
sources = {r['id_fonte'] for r in read(HERE / 'evidencias/fontes_prioritarios_2026_09_24.csv')}
candidate = read(OUT / 'verificacao_cnes_candidato_consardoce.csv')
assert len(candidate) == 8 and all(r['presente'] == 'False' for r in candidate)
for r in updated:
    if r['decisao_revisada']:
        assert set(r['fontes_ids'].split(';')) <= sources

units = read(OUT / 'diagnostico_necessidade_mensal_unidades_saude.csv')
annual = read(OUT / 'diagnostico_necessidade_mensal_entidades_saude.csv')
assert len(units) == len({(*key(r), r['cnes']) for r in units}) == 482
assert sum(r['prioridade_temporal'] == 'True' for r in units) == 58
assert sum(int(r['unidades_prioridade_temporal']) > 0 for r in annual) == 53
for k in [('97550393', '2015'), ('01111142', '2016'), ('64486822', '2017'), ('01260691', '2017')]:
    r = next(r for r in annual if key(r) == k)
    assert int(r['unidades_clinicas_dezembro']) == 0
    assert r['classe_temporal'] == 'priorizar_coleta_mensal'

pilot = read(OUT / 'piloto_cnes_competencias_saude.csv')
assert len(pilot) == 6
assert {r['tipo_cnes'] for r in pilot} <= {'04', '05', '22', '36', '39', '62', '70'}
municipal = [r for r in pilot if r['cnpj_raiz_8'] == '71203715']
assert len(municipal) == 2 and all(r['vinculo_cnpj_direto'] == 'False' for r in municipal)
assert all(r['cnpj_mantenedora'] == '18188219000121' for r in municipal)
assert {r['competencia']: r['profissionais_sus'] for r in municipal} == {'201704': '35', '201712': '22'}
assert next(r for r in pilot if r['competencia'] == '201606')['profissionais_sus'] == '3'
assert next(r for r in pilot if r['competencia'] == '201706')['leitos_sus'] == '12'
for r in pilot:
    assert all(float(r[c]) >= 0 for c in ['leitos_sus', 'servicos_sus', 'profissionais_sus', 'carga_horaria_sus'])
    assert 'nao_media_anual' in r['limite']
for file in ['manifesto_cnes_piloto_temporal.csv', 'manifesto_fontes_prioritarios_saude.csv',
             'verificacao_cnes_candidato_consardoce.csv']:
    rows = read(OUT / file)
    if file.startswith('manifesto_cnes'):
        assert len(rows) == len({(r['competencia'], r['tabela']) for r in rows}) == 24
    for r in rows:
        if r['sha256']:
            with (HERE / r['arquivo']).open('rb') as f:
                assert hashlib.file_digest(f, 'sha256').hexdigest() == r['sha256']

summary = {(r['periodo'], r['recorte']): r for r in read(OUT / 'matriz_suficiencia_recortes_saude.csv')}
for year in ['2014-2021'] + list(map(str, range(2014, 2022))):
    health, direct, missing = [summary[year, x] for x in
        ['cadastral_saude', 'clinica_direta_com_tempo', 'saude_sem_clinica_direta']]
    assert int(health['pares_ano_pagos']) == int(direct['pares_ano_pagos']) + int(missing['pares_ano_pagos'])
    assert abs(Decimal(health['valor_mides']) - Decimal(direct['valor_mides']) - Decimal(missing['valor_mides'])) < Decimal('.01')
assert summary['2014', 'direto_com_rcl']['linhas'] == '0'
assert all(summary[str(y), 'direto_com_pdr']['linhas'] == '0' for y in range(2014, 2019))
assert summary['2014-2021', 'direto_com_rcl']['pares_ano_pagos'] == '1052'
timing = read(OUT / 'pagamentos_janelas_clinicas_piloto_saude.csv')
assert len(timing) == 8 and all(r['janela'] != 'data_ausente' for r in timing)
assert sum(int(r['transacoes']) for r in timing) == 1022
print('OK: 14 revisoes, 181 chaves conservadas, 53 prioridades temporais, seis fotografias CNES e recortes coerentes.')
