"""Confere os nove casos documentais sem alterar v1, mapas ou modelos.

Execute: python 36_consolidar_auditoria_documental.py
Requer as extrações existentes e os documentos locais catalogados. Não baixa
fontes nem promove menção institucional a pagamento/filiação comprovada.
"""
from pathlib import Path
from decimal import Decimal
from collections import Counter
import csv
import hashlib
import json

HERE = Path(__file__).resolve().parent
EV = HERE / 'evidencias'
OUT = HERE / 'outputs/auditoria_alternativas/documental_2026_09_25'


def read(path):
    with Path(path).open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def money(value):
    return Decimal(value).quantize(Decimal('0.01'))


def save(name, rows):
    with (OUT / name).open('w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


cases = read(EV / 'auditoria_nove_pares_2026_09_25.csv')
sources = read(EV / 'fontes_nove_pares_2026_09_25.csv')
invariants = read(EV / 'invariantes_nove_pares_2026_09_25.csv')
assert len(cases) == 9 and len({c['caso_id'] for c in cases}) == 9
assert Counter(c['tipo'] for c in cases) == {'zero_2019': 6, 'conflito_credor': 3}
assert all(c['alterar_base'] == 'FALSE' for c in cases)
source_ids = {s['id_fonte'] for s in sources}
assert len(source_ids) == len(sources)
for c in cases:
    assert set(c['fontes'].split(';')) <= source_ids
    assert len(c['id_municipio']) == 7 and len(c['cnpj_raiz_8']) == 8
    assert c['achado'] and c['limite'] and c['proxima_conferencia']

verified = []
unavailable = []
for s in sources:
    if s['arquivo_local']:
        path = Path(s['arquivo_local'])
        if not path.is_absolute():
            path = HERE / path
        assert path.is_file(), path
        assert sha(path) == s['sha256'], path
        verified.append(s['id_fonte'])
    else:
        assert s['acesso'] in {'indice_web_sem_copia_original', 'conexao_encerrada'}
        assert not s['sha256']
        unavailable.append(s['id_fonte'])

for record in invariants:
    assert sha(HERE / record['arquivo']) == record['sha256'], record['arquivo']

pair_cases = {(c['id_municipio'], c['cnpj_raiz_8']): c for c in cases}
assert len(pair_cases) == 9
annual = []
with (HERE / 'outputs/base_v1/base_financeira_v1.csv').open(encoding='utf-8-sig', newline='') as f:
    for row in csv.DictReader(f):
        key = row['id_municipio'], row['cnpj_raiz_8']
        if key not in pair_cases:
            continue
        case = pair_cases[key]
        annual.append({
            'caso_id': case['caso_id'], 'id_municipio': key[0],
            'municipio': row['municipio'], 'cnpj_raiz_8': key[1],
            'entidade': row['entidade'], 'ano': row['ano'],
            'valor_mides': row['valor_total'], 'n_transacoes': row['n_transacoes'],
            'conflito_credor_mides': row['conflito_credor_mides'],
            'valor_credor_conflitante': row['valor_credor_conflitante'],
            'status_documental': case['status'],
        })
assert len(annual) == 72
assert len({(r['caso_id'], r['ano']) for r in annual}) == 72
for c in cases:
    rows = [r for r in annual if r['caso_id'] == c['caso_id']]
    assert {int(r['ano']) for r in rows} == set(range(2014, 2022))
    if c['tipo'] == 'zero_2019':
        year = next(r for r in rows if r['ano'] == '2019')
        assert money(year['valor_mides']) == 0 and int(year['n_transacoes']) == 0

flagged = [r for r in annual if r['conflito_credor_mides'] == 'TRUE']
assert len(flagged) == 17
assert sum(money(r['valor_credor_conflitante']) for r in flagged) == Decimal('1352846.55')
assert sum(int(r['n_transacoes']) for r in flagged) == 429
# Conferência independente contra a auditoria de nomes, anterior a esta tabela.
prior = read(HERE / 'outputs/auditoria_alternativas/conflitos_nome_documento.csv')
key = lambda r: (r['id_municipio'], r['cnpj_raiz_8'], r['ano'])
assert {key(r) for r in prior} == {key(r) for r in flagged}
assert {key(r): money(r['valor_conflitante']) for r in prior} == {
    key(r): money(r['valor_credor_conflitante']) for r in flagged}

summaries = []
for c in cases:
    rows = [r for r in annual if r['caso_id'] == c['caso_id']]
    positives = [r for r in rows if money(r['valor_mides']) > 0]
    flagged_rows = [r for r in rows if r['conflito_credor_mides'] == 'TRUE']
    summaries.append({**c,
        'anos_pagamento_positivo': ';'.join(sorted(r['ano'] for r in positives)),
        'total_mides_2014_2021': str(sum(money(r['valor_mides']) for r in rows)),
        'valor_2019': next(r['valor_mides'] for r in rows if r['ano'] == '2019'),
        'pares_ano_conflitantes': len(flagged_rows),
        'valor_conflitante': str(sum(money(r['valor_credor_conflitante']) for r in rows)),
    })

OUT.mkdir(parents=True, exist_ok=True)
save('trajetorias_72_pares_ano.csv', sorted(annual, key=lambda r: (r['caso_id'], r['ano'])))
save('decisoes_nove_pares.csv', summaries)
report = {
    'data_revisao': '2026-09-25', 'casos': len(cases), 'trajetorias_pares_ano': len(annual),
    'status': dict(Counter(c['status'] for c in cases)),
    'fontes_com_copia_conferida': verified, 'fontes_sem_copia': unavailable,
    'zeros_2019_conciliados_com_extracao': 6,
    'zeros_com_causa_financeira_anual_encerrada_nesta_rodada': 0,
    'conflitos_credor_resolvidos_nesta_rodada': 0,
    'pares_ano_conflitantes_preservados': len(flagged),
    'valor_conflitante_preservado': '1352846.55',
    'transacoes_conflitantes_preservadas': 429,
    'arquivos_analiticos_preservados': [r['arquivo'] for r in invariants],
    'entradas': {str(p.relative_to(HERE)): sha(p) for p in [
        EV / 'auditoria_nove_pares_2026_09_25.csv',
        EV / 'fontes_nove_pares_2026_09_25.csv',
        EV / 'invariantes_nove_pares_2026_09_25.csv']},
}
(HERE / 'checks/23_auditoria_documental_nove_pares.json').write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, ensure_ascii=False, indent=2))
