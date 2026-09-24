"""Confere cobertura, dinheiro, temporalidade e rastreabilidade da conciliacao."""
import csv
import hashlib
from decimal import Decimal
from pathlib import Path

HERE = Path(__file__).resolve().parents[1]
ROOT, OUT = HERE.parents[1], HERE / 'outputs'


def read(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def key(r):
    return r['cnpj_raiz_8'], r['ano']


gaps = {key(r): r for r in read(OUT / 'eda_lacunas_polo_entidade_ano_saude.csv')}
rows = read(HERE / 'evidencias/conciliacao_181_entidades_ano_2026_09_24.csv')
audit = {key(r): r for r in rows}
assert len(rows) == len(audit) == 181 and audit.keys() == gaps.keys()
assert len({r['cnpj_raiz_8'] for r in rows}) == 37
assert sum(int(r['pares_pagantes']) for r in rows) == 5123
assert abs(sum(Decimal(r['valor_mides']) for r in rows) - Decimal('450467803.61')) < Decimal('.01')
for k, r in audit.items():
    assert Decimal(r['valor_mides']) == Decimal(gaps[k]['valor'])
    assert int(r['pares_pagantes']) == int(gaps[k]['pares'])
    assert r['classificacao_conciliada'] and r['tratamento_dados'] and r['limite']
    assert r['fonte_decisao'] and r['fonte_cnes_url'] and len(r['fonte_cnes_sha256']) == 64
    assert r['polo_clinico_anual_recuperado'] == 'FALSE'
assert sum(r['classificacao_anterior_painel'] == 'sem_classificacao_anual_no_painel' for r in rows) == 97

# Datas institucionais nao devem virar disponibilidade integral retroativa.
assert audit['13985869', '2014']['classificacao_conciliada'] == 'pre_operacao_samu_regional'
for root, year, date in [('13985869', '2015', '2015-01-31'),
                         ('20059618', '2017', '2017-06-07'),
                         ('19455924', '2018', '2018-07-03'),
                         ('20101246', '2020', '2020-12-28')]:
    assert audit[root, year]['classificacao_conciliada'] == 'inicio_samu_durante_ano'
    assert audit[root, year]['inicio_servico_documentado'] == date
assert all(r['classificacao_conciliada'] == 'pre_operacao_samu_regional'
           for r in rows if r['cnpj_raiz_8'] == '20433216')
assert audit['71203715', '2016']['classificacao_conciliada'] == 'programas_documentados_sem_destino_clinico_identificado'
assert '403' in audit['71203715', '2017']['limite']
monthly = read(OUT / 'conciliacao_cismas_2016_mensal.csv')
assert len(monthly) == 12 and monthly[-1]['tipo_cnes'] == '64'
assert {r['tipo_cnes'] for r in monthly} == {'36', '64'}
assert [r['tipo_cnes'] for r in monthly] == ['36'] * 6 + ['64'] * 6
for r in monthly:
    with (OUT / 'cache_cnes_historico' / f"STMG{r['competencia'][2:]}.dbc").open('rb') as f:
        assert hashlib.file_digest(f, 'sha256').hexdigest() == r['sha256']
assert audit['01111142', '2016']['cnes_com_tipo_clinico_em_algum_mes'] == '6776434'

financial = read(OUT / 'eda_extremos_conferidos_na_fonte_saude.csv')
assert len(financial) == 60 and all(r['conferencia_ok'] == 'TRUE' for r in financial)
assert all(abs(Decimal(r['diferenca_valor'])) < Decimal('.01') for r in financial)
assert all(r['n_transacoes'] == r['transacoes_recalculadas'] for r in financial)
zero = [r for r in financial if r['id_municipio'] == '3162450' and key(r) == ('00905312', '2021')]
assert len(zero) == 1 and zero[0]['transacoes_zeradas'] == '4'
assert zero[0]['valores_transacionais_nulos'] == '0' and Decimal(zero[0]['valor_total']) == 0
labels = read(OUT / 'rotulos_entidades_sem_sigla_saude.csv')
assert len(labels) == 5 and sum(int(r['pares_pagos']) for r in labels) == 314
assert all(r['rotulo_exibicao'] and r['sigla_inventada'] == 'FALSE' for r in labels)

# Entradas e produtos devem corresponder aos hashes registrados nesta auditoria.
for filename, base in [('manifesto_entradas_conciliacao_saude.csv', ROOT),
                       ('inventario_produtos_saude.csv', HERE)]:
    for r in read(OUT / filename):
        with (base / r['arquivo']).open('rb') as f:
            assert hashlib.file_digest(f, 'sha256').hexdigest() == r['sha256'], r['arquivo']
print('OK: 181 lacunas conciliadas, 60 conferencias financeiras, datas e hashes validos; nenhum polo imputado.')
