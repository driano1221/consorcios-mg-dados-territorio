"""Empacota o HTML local e registra fontes/produtos. Executar depois de 26 e 27."""
from pathlib import Path
import csv
import hashlib
import json
from zipfile import ZipFile, ZIP_DEFLATED

HERE = Path(__file__).resolve().parent
DEST = HERE / 'outputs' / 'visuais_v1'
data = json.loads((DEST / 'dados' / 'visuais.json').read_text(encoding='utf-8'))
data['catalog'] = json.loads((DEST / 'dados' / 'catalogo_figuras.json').read_text(encoding='utf-8'))
with (DEST / 'dados' / 'tempos_extremos.csv').open(encoding='utf-8-sig', newline='') as handle:
    data['extremes'] = list(csv.DictReader(handle, delimiter=';'))
    for row in data['extremes']:
        for key in ('tempo_minimo_min', 'valor_total'):
            row[key] = float(row[key].replace(',', '.'))
assert len(data['catalog']) == 20
assert data['summary']['relacoes'] == 10735 and data['summary']['relacoes_diretas'] == 5612
template = (HERE / 'visuais_v1.html').read_text(encoding='utf-8')
parts = {'__CSS__': (HERE / 'visuais_v1.css').read_text(encoding='utf-8'),
         '__JS__': (HERE / 'visuais_v1.js').read_text(encoding='utf-8'),
         '__DATA__': json.dumps(data, ensure_ascii=False, separators=(',', ':')).replace('</', '<\\/')}
for marker, content in parts.items():
    assert template.count(marker) == 1
    template = template.replace(marker, content)
(DEST / 'index.html').write_text(template, encoding='utf-8')
# Arquivos pequenos ja existentes de proveniencia ficam disponiveis para consulta.
sources = [HERE / 'outputs' / 'base_v1' / f for f in
           ('base_financeira_v1.rds', 'base_gravitacional_v1.rds', 'capacidade_entidade_ano.csv',
            'inclusao_entidade_ano.csv', 'manifesto.csv')]
sources += [HERE / 'outputs' / f for f in ('atlas_dados.json',
    'elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv',
    'candidatas_cnes_capacidade_unidades_2014_2021.csv')]
sources += [HERE.parents[1] / 'dashboards' / 'base1_shiny' / 'data' / 'mg_municipios_sf_web.rds']
sources += [HERE / f for f in ('26_preparar_visuais_v1.R', '27_renderizar_visuais_v1.R',
                             '28_montar_visuais_v1.py', 'visuais_v1.html', 'visuais_v1.css', 'visuais_v1.js')]
products = [DEST / 'index.html'] + sorted((DEST / 'figuras').glob('*'))
products += [p for p in sorted((DEST / 'dados').glob('*')) if p.name != 'manifesto.csv']
with (DEST / 'dados' / 'manifesto.csv').open('w', encoding='utf-8-sig', newline='') as handle:
    writer = csv.writer(handle, delimiter=';')
    writer.writerow(('papel', 'arquivo', 'bytes', 'sha256'))
    for role, paths in (('entrada', sources), ('saida', products)):
        for path in paths:
            writer.writerow((role, path.relative_to(HERE.parents[1]).as_posix(), path.stat().st_size,
                             hashlib.sha256(path.read_bytes()).hexdigest()))
print(f'HTML pronto: {DEST / "index.html"}')
print(f'{len(data["catalog"])} figuras; {len(data["entities"])} entidades no atlas; fontes registradas.')
with ZipFile(DEST.parent / 'visuais_v1.zip', 'w', compression=ZIP_DEFLATED) as bundle:
    for path in products + [DEST / 'dados' / 'manifesto.csv']:
        bundle.write(path, Path('visuais_v1') / path.relative_to(DEST))
print('Copia para compartilhar: outputs/visuais_v1.zip (extrair a pasta inteira).')
