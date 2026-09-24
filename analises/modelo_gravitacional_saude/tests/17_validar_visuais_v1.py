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
totals, direct = defaultdict(lambda: [0, Decimal(0), set(), set()]), defaultdict(lambda: [0, Decimal(0)])
for row in read(OUT / 'base_v1/base_financeira_v1.csv'):
    value = Decimal(row['valor_total'])
    if value > 0:
        key = int(row['ano']); totals[key][0] += 1; totals[key][1] += value
        totals[key][2].add(row['id_municipio']); totals[key][3].add(row['cnpj_raiz_8'])
for row in read(OUT / 'base_v1/base_gravitacional_v1.csv'):
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
assert len(data['entities']) == 221 and len(data['polys']) == 853
assert len(data['units']) == len(source['units']) == 2612
unlocated = [r for r in data['units'] if r['cnes'] == '5563003' and r['ano'] == 'atual']
assert len(unlocated) == 1 and unlocated[0]['x'] is None and unlocated[0]['municipio'] is None
assert data['payments'] == source['payments']
for original, prepared in zip(source['units'], data['units']):
    for key in ('cnpj_raiz_8', 'ano', 'cnes', 'codigo_ibge_6', 'funcao'):
        assert original[key] == prepared[key]
assert sum(r['relacoes'] for r in data['absence']) == 5123
assert {r['cnpj_raiz_8'] for r in data['aux']} == {'01272081','06070075','07306549'}
aux = {r['entidade']: r for r in data['aux'] if r['ano'] == 2019}
assert aux['CISREC']['unidades'] is None
assert aux['CONVALES']['unidades'] == 1 and aux['CONVALES']['servicos'] == 0
assert aux['CIMBAJE']['profissionais'] == 23
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
    assert len([n for n in bundle.namelist() if n.endswith('.png')]) == 20

report={'status':'OK','figuras':20,'formatos':['PNG 300 dpi','SVG'],'relacoes_financeiras':10735,
        'relacoes_diretas':5612,'entidades_atlas':221,'unidades_periodo':2612,
        'verificado':'Conservacao dos valores anuais, fontes, denominadores, capacidade, ausencias, tempos, arquivos e manifestos.'}
(HERE / 'checks/17_visuais_v1.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
