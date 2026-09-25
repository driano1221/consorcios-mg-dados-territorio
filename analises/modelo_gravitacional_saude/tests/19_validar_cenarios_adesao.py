"""Concilia os tres cenarios com v1 e unidades CNES, sem estimar modelos."""
from pathlib import Path
from collections import defaultdict, Counter
import csv
import hashlib
import json
import math

HERE = Path(__file__).resolve().parents[1]
OUT = HERE / 'outputs/cenarios_adesao'

def read(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))

def close(a, b):
    assert math.isclose(float(a), float(b), rel_tol=1e-11, abs_tol=1e-7), (a, b)

finance = {(r['id_municipio'], r['cnpj_raiz_8']): r for r in
           read(HERE / 'outputs/base_v1/base_financeira_v1.csv') if r['ano'] == '2019'}
assert len(finance) == 853*73
unit_hours = defaultdict(lambda: defaultdict(float))
unit_counts = Counter()
for name in ('auditoria_alternativas/unidades_cnes_dezembro_corrigidas.csv',):
    for r in read(HERE / 'outputs' / name):
        if r['ano'] == '2019':
            unit_hours[r['cnpj_raiz_8']][r['funcao_assistencial']] += float(r['carga_horaria_sus'])
            unit_counts[r['cnpj_raiz_8']] += 1
inventory = {r['cnpj_raiz_8']: r for r in read(OUT/'inventario_consorcios_2019.csv')}
assert len(inventory) == 73
for root, r in inventory.items():
    if unit_counts[root] == 0:
        assert r['horas_base'] == '' and r['horas_todas'] == ''
    elif int(r['n_clinicas']) > 0:
        close(r['horas_base'], unit_hours[root]['destino_clinico_fixo'])
    else:
        close(r['horas_base'], sum(unit_hours[root].values()))
assert sum(r['horas_base'] == '' for r in inventory.values()) == 10
assert sum(r['horas_base'] == '0' for r in inventory.values()) == 1

# Conferencia independente dos pesos/rotas de cada par e da agregacao da impedancia.
route_summary = defaultdict(lambda: [math.inf, math.inf, 0., 0., 0., 0., 0.])
route_keys = set()
for r in read(OUT/'rotas_por_ponto_2019.csv'):
    key = (r['cenario'], r['id_municipio'], r['cnpj_raiz_8'])
    unique = (*key, r['ponto_id'])
    assert unique not in route_keys
    route_keys.add(unique)
    d, t = float(r['distancia_km']), float(r['tempo_min'])
    assert d >= 0 and t >= 0
    if r['id_municipio'] == r['id_destino']:
        assert d == 0 and t == 0
    v = route_summary[key]
    v[0], v[1] = min(v[0], d), min(v[1], t)
    if r['peso_horas']:
        w = float(r['peso_horas'])
        close(w, float(r['horas_ponto'])/float(r['horas_base']))
        v[2] += w*d
        v[3] += w*t
        v[4] += w*math.log1p(d)
        v[5] += w*math.log1p(t)
        v[6] += w

rows = read(OUT/'grade_candidata_cenarios_2019.csv')
keys = {(r['cenario'], r['id_municipio'], r['cnpj_raiz_8']) for r in rows}
assert len(keys) == len(rows) == 3*len(finance)
counts = defaultdict(Counter)
values = defaultdict(float)
by_key = {}
for r in rows:
    key = r['id_municipio'], r['cnpj_raiz_8']
    source = finance[key]
    close(r['valor_total'], source['valor_total'])
    close(r['populacao_ibge'], source['populacao_ibge'])
    assert int(r['adesao_financeira']) == int(float(source['valor_total']) > 0)
    scenario_key = r['cenario'], *key
    by_key[scenario_key] = r
    if r['destino_identificado'] == 'TRUE':
        v = route_summary[scenario_key]
        close(r['distancia_min_km'], v[0])
        close(r['tempo_minimo_min'], v[1])
        if r['pre_elegivel_horas_positivas'] == 'TRUE':
            close(v[6], 1)
            for k, expected in zip(('distancia_media_horas_km','tempo_medio_horas_min',
                                    'impedancia_log_km_horas','impedancia_log_min_horas'),v[2:6]):
                close(r[k], expected)
        else:
            assert r['impedancia_log_km_horas'] == ''
    for rule in ('pre_elegivel_cadastral','pre_elegivel_horas_positivas','amostra_comum'):
        if r[rule] == 'TRUE':
            c = counts[(r['cenario'],rule)]
            c['linhas'] += 1
            c['positivos'] += int(r['adesao_financeira'])
            c['zeros'] += 1-int(r['adesao_financeira'])
            values[(r['cenario'],rule)] += float(r['valor_total'])
for r in read(OUT/'comparacao_cenarios_2019.csv'):
    key = r['cenario'],r['regra']
    for field in ('linhas','positivos','zeros'):
        assert counts[key][field] == int(r[field])
    close(values[key],r['valor_pago'])
    close(float(r['fracao_relacoes']),int(r['positivos'])/sum(float(s['valor_total'])>0 for s in finance.values()))

# Misto = unidades nos consorcios clinicos; sedes no complemento.
for (scenario, origin, root), r in by_key.items():
    if scenario == 'S3_misto':
        comparison = 'S1_unidades' if int(inventory[root]['n_clinicas']) > 0 else 'S2_sedes'
        expected = by_key[(comparison, origin, root)]
        for field in ('horas_base','distancia_min_km','tempo_minimo_min','impedancia_log_km_horas'):
            assert r[field] == expected[field], (root, field)

# Exemplo real protege origem/destino e unidade/consorcio de trocas acidentais.
example = [r for r in rows if r['id_municipio']=='3130101' and r['cnpj_raiz_8']=='05802877']
assert len(example)==3
for r in example:
    close(r['valor_total'],4740790.51)
    close(r['horas_base'],1651)
    close(r['tempo_minimo_min'],8.4 if r['cenario']=='S2_sedes' else 15.1)
for r in read(OUT/'fontes.csv'):
    assert hashlib.sha256((HERE/r['arquivo']).read_bytes()).hexdigest()==r['sha256']
for r in read(OUT/'manifesto_produtos.csv'):
    assert hashlib.sha256((OUT/r['arquivo']).read_bytes()).hexdigest()==r['sha256']
new_fields = set(rows[0])-set(next(iter(finance.values())))
documented = {r['variavel'] for r in read(OUT/'dicionario_campos_novos.csv')}
assert new_fields == documented, (new_fields-documented, documented-new_fields)
monthly = read(OUT/'cismep_brumadinho_presenca_mensal.csv')
assert next(r for r in monthly if r['ano']=='2021')['meses_presente']=='01 | 02 | 03 | 04 | 05 | 06'
report = dict(status='OK',ano=2019,linhas_conciliadas=len(rows),municipios=853,
              consorcios_financeiros=73,sem_capacidade=10,horas_zero=1,
              verificacoes=['pagamentos e populacao iguais a v1','horas iguais ao CNES por modalidade',
                           'rotas e pesos sem duplicacao','misto consistente com origem do destino',
                           'resumos recontados','ausencia distinta de zero','hashes preservados'],
              estimacao_executada=False)
(HERE/'checks/19_cenarios_adesao.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
