"""Concilia os visuais com CSVs originais, sem depender dos scripts geradores.

Execute da raiz. A revisao de navegador e visual e registrada separadamente.
"""
from collections import defaultdict
from decimal import Decimal
from pathlib import Path
import csv
import hashlib
from html.parser import HTMLParser
import json
import math
import re
import struct
import xml.etree.ElementTree as ET
from zipfile import ZipFile

HERE = Path(__file__).resolve().parents[1]
ROOT = HERE.parents[1]
OUT = HERE / 'outputs'
DEST = OUT / 'visuais_v1'

def read(path, delimiter=','):
    with path.open(encoding='utf-8-sig', newline='') as handle:
        yield from csv.DictReader(handle, delimiter=delimiter)

def dec(value):
    return Decimal(value.replace(',', '.'))

data = json.loads((DEST / 'dados/visuais.json').read_text(encoding='utf-8'))
source = json.loads((OUT / 'atlas_dados.json').read_text(encoding='utf-8'))
def same_value(raw, value):
    if isinstance(value, bool): return raw.lower() == str(value).lower()
    if isinstance(value, (int, float)): return math.isclose(float(raw), value, rel_tol=1e-12, abs_tol=1e-8)
    raw = re.sub(r'<U\+([0-9A-Fa-f]+)>', lambda m: chr(int(m[1],16)), raw)
    return raw == value or (raw == '' and value is None)

def checked_rows(filename, kind):
    current_year, chunk, index, total = None, None, 0, 0
    for row in read(OUT / 'base_v1' / filename):
        year = int(row['ano'])
        if year != current_year:
            if chunk is not None: assert index == len(chunk['rows'])
            script = (DEST / 'dados/consulta' / f'{kind}_{year}.js').read_text(encoding='utf-8').strip()
            prefix = f'window.receiveBaseRows("{kind}",{year},'
            assert script.startswith(prefix) and script.endswith(');')
            chunk = json.loads(script[len(prefix):-2]); current_year=year; index=0
            assert chunk['columns'] == list(row)
        values = chunk['rows'][index]
        assert len(values) == len(row)
        assert all(same_value(row[key], value) for key, value in zip(chunk['columns'],values)), (kind, year, index)
        if total < 5:
            sample=data['overview']['previews'][kind]['head'][total]
            assert all(same_value(row[key], sample[key]) for key in row)
        index+=1; total+=1
        yield row
    assert index == len(chunk['rows'])
    assert total == (491328 if kind=='financeira' else 323287)

totals, direct = defaultdict(lambda: [0, Decimal(0), set(), set()]), defaultdict(lambda: [0, Decimal(0)])
financial_keys=set(); payment_source={}
for row in checked_rows('base_financeira_v1.csv', 'financeira'):
    financial_keys.add((row['cnpj_raiz_8'],row['ano']))
    value = Decimal(row['valor_total'])
    if value > 0:
        key = int(row['ano']); totals[key][0] += 1; totals[key][1] += value
        totals[key][2].add(row['id_municipio']); totals[key][3].add(row['cnpj_raiz_8'])
        payment_source[(row['cnpj_raiz_8'],key,row['id_municipio'][:6])] = value
for row in checked_rows('base_gravitacional_v1.csv', 'direta'):
    value = Decimal(row['valor_total'])
    if value > 0:
        key = int(row['ano']); direct[key][0] += 1; direct[key][1] += value
for row in data['annual']:
    key = row['ano']; actual = totals[key]
    assert row['relacoes'] == actual[0] and abs(Decimal(str(row['valor'])) - actual[1]) < Decimal('.01')
    assert row['municipios'] == len(actual[2]) and row['consorcios'] == len(actual[3])
    assert row['relacoes_diretas'] == direct[key][0]
    assert abs(Decimal(str(row['valor_direto'])) - direct[key][1]) < Decimal('.01')
assert sum(r[0] for r in totals.values()) == 10735
assert sum(r[0] for r in direct.values()) == 5612
assert len(data['cap']) == 379
assert len({(r['cnpj_raiz_8'], r['ano']) for r in data['cap']}) == 379
assert len(data['entities']) == 73 and len(data['polys']) == 853
assert {e['raiz'] for e in data['entities']} == {k[0] for k in financial_keys}
assert 'cnm' not in data and 'aux' not in data
expected_units=[r for r in source['units'] if (r['cnpj_raiz_8'],str(r['ano'])) in financial_keys]
assert len(data['units']) == len(expected_units)
assert len(data['payments']) == len(payment_source) == 10735
for payment in data['payments']:
    assert abs(Decimal(str(payment['valor']))-payment_source[(payment['cnpj_raiz_8'],payment['ano'],payment['codigo_ibge_6'])]) < Decimal('.01')
for original, prepared in zip(expected_units, data['units']):
    for key in ('cnpj_raiz_8', 'ano', 'cnes', 'codigo_ibge_6', 'funcao'):
        assert original[key] == prepared[key]
assert sum(r['relacoes'] for r in data['absence']) == 5123
assert all(str(r['ano']) in {str(y) for y in range(2014,2022)} for r in data['units'])
assert [(s['linhas'],s['colunas'],s['nulos']) for s in data['overview']['stats']] == [(491328,19,0),(323287,30,0)]
assert len(data['overview']['variables']) == 30
time_rows = list(read(DEST / 'dados/tempos_relacoes.csv', ';'))
assert len(time_rows) == 5612 and max(dec(r['tempo_minimo_min']) for r in time_rows) == Decimal('761.3')
assert sum(dec(r['tempo_minimo_min']) == 0 for r in time_rows) == 368
for field in ('fracao_relacoes','fracao_valor'):
    values = [dec(r[field]) for r in read(DEST / 'dados/tempos_acumulada.csv', ';')]
    assert values[-1] == 1 and values == sorted(values)
for year in ['2014-2021'] + [str(y) for y in range(2014,2022)]:
    rows = [r for r in data['ranking'] if r['periodo'] == year]
    assert abs(sum(r['participacao'] for r in rows) - 1) < .00001
    assert abs(rows[-1]['acumulada'] - 1) < .00001
    assert [r['posicao'] for r in rows] == list(range(1, len(rows)+1))

catalog = json.loads((DEST / 'dados/catalogo_figuras.json').read_text(encoding='utf-8'))
assert len(catalog) == 20
for row in catalog:
    assert (DEST / 'dados' / row['dados']).is_file(), row
    svg_path = DEST / 'figuras' / (row['id'] + '.svg')
    root = ET.parse(svg_path).getroot()
    texts = [''.join(e.itertext()) for e in root.iter() if e.tag.endswith('}text')]
    assert any('Fonte' in s for s in texts), svg_path
    assert not any('Adriano' in s or '24/09/2026' in s for s in texts), svg_path
    assert not re.search(r'\b(?:NaN|Infinity)\b|<U\+[0-9A-F]+>', svg_path.read_text(encoding='utf-8'))
    png_path = DEST / 'figuras' / (row['id'] + '.png')
    content = png_path.read_bytes(); assert content[:8] == b'\x89PNG\r\n\x1a\n'
    offset = 8; dpi_found = False
    while offset < len(content):
        n = struct.unpack('>I', content[offset:offset+4])[0]; kind = content[offset+4:offset+8]
        if kind == b'pHYs':
            x, y, unit = struct.unpack('>IIB', content[offset+8:offset+17]); assert unit == 1 and abs(x*.0254-300)<.1 and abs(y*.0254-300)<.1; dpi_found=True
        offset += n+12
    assert dpi_found, png_path

class Links(HTMLParser):
    def __init__(self): super().__init__(); self.targets=[]; self.ids=[]
    def handle_starttag(self, tag, attrs):
        attrs=dict(attrs)
        if 'id' in attrs: self.ids.append(attrs['id'])
        for key in ('src','href'):
            if key in attrs: self.targets.append(attrs[key])

html = (DEST / 'index.html').read_text(encoding='utf-8')
parser=Links(); parser.feed(html)
assert len(parser.ids) == len(set(parser.ids))
for target in parser.targets:
    if not target.startswith(('http:', 'https:', '#', 'data:')):
        assert (DEST / target).is_file(), target
assert '__DATA__' not in html and '__CSS__' not in html and '__JS__' not in html
assert 'Proposta visual 02' not in html and 'ainda em aprovação' not in html
assert ' download' not in html and 'layer-cnm' not in html and 'Elaboração:' not in html
assert 'id="query-table"' in html and 'id="base-preview"' in html
embedded = json.loads(re.search(r'<script type="application/json" id="data">(.*?)</script>',html,re.S)[1])
assert len(embedded['catalog']) == 5
for row in read(DEST / 'dados/manifesto.csv',';'):
    path = ROOT / row['arquivo']
    assert path.stat().st_size == int(row['bytes'])
    assert hashlib.sha256(path.read_bytes()).hexdigest() == row['sha256'], path

with ZipFile(OUT / 'visuais_v1.zip') as bundle:
    assert bundle.testzip() is None
    for name in bundle.namelist():
        relative = Path(name).relative_to('visuais_v1')
        assert bundle.read(name) == (DEST / relative).read_bytes()
    assert 'visuais_v1/index.html' in bundle.namelist()
    assert len([n for n in bundle.namelist() if n.endswith('.png')]) == 5
    assert len([n for n in bundle.namelist() if '/consulta/' in n]) == 16

report={'status':'OK','figuras_na_consulta':5,'figuras_de_origem':20,'formatos':['PNG 300 dpi','SVG'],'relacoes_financeiras':10735,
        'relacoes_diretas':5612,'entidades_mapa_v1':73,'unidades_periodo_v1':len(data['units']),
        'linhas_consultaveis':814615,'colunas_financeira':19,'colunas_direta':30,
        'verificado':'Todas as celulas das duas tabelas consultaveis conciliadas com CSVs v1; escopo anual, valores, fontes, capacidade, tempos, arquivos e manifestos.'}
(HERE / 'checks/17_visuais_v1.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
