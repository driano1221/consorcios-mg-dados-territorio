"""Empacota a v1 local; os modelos são lidos sem nova estimação."""
from pathlib import Path
import csv
import hashlib
import json
from zipfile import ZipFile, ZIP_DEFLATED
from adesao_visual import render, SOURCES

HERE = Path(__file__).resolve().parent
DEST = HERE / 'outputs' / 'visuais_v1'
model_sources = SOURCES
binary, model_figures = render(DEST)
data = json.loads((DEST / 'dados' / 'visuais.json').read_text(encoding='utf-8'))
data['model'] = json.loads((HERE / 'outputs/piloto_participacoes/piloto.json').read_text(encoding='utf-8'))
active_figures = {'01_pagamentos_anuais', '06_cobertura', '09_funcoes_cnes',
                  '11_capacidade_2019', '14_tempos_distribuicao'}
data['catalog'] = [r for r in json.loads((DEST / 'dados' / 'catalogo_figuras.json').read_text(encoding='utf-8'))
                   if r['id'] in active_figures]
with (DEST / 'dados' / 'tempos_extremos.csv').open(encoding='utf-8-sig', newline='') as handle:
    data['extremes'] = list(csv.DictReader(handle, delimiter=';'))
    for row in data['extremes']:
        for key in ('tempo_minimo_min', 'valor_total'):
            row[key] = float(row[key].replace(',', '.'))
assert len(data['catalog']) == 5 and len(data['entities']) == 73
assert data['summary']['relacoes'] == 10735 and data['summary']['relacoes_diretas'] == 5612
template = (HERE / 'visuais_v1.html').read_text(encoding='utf-8')
with (DEST / 'dados/capacidade.csv').open(encoding='utf-8-sig', newline='') as handle:
    capacity = list(csv.DictReader(handle, delimiter=';'))
assert len({(r['cnpj_raiz_8'], r['ano']) for r in capacity}) == len(capacity)
assert {int(r['ano']) for r in capacity} == set(range(2014, 2022))
capacity_fields = ('n_destinos_clinicos_dezembro', 'profissionais_sus_clinicos_soma_unidades',
                   'servicos_sus_clinicos_soma_unidades', 'horas_sus_clinicas_soma_registros',
                   'leitos_sus_clinicos')
annual_rows = []
for year in range(2014, 2022):
    selected = [r for r in capacity if int(r['ano']) == year]
    totals = [sum(float(r[k].replace(',', '.')) for r in selected) for k in capacity_fields]
    assert all(v.is_integer() for v in totals)
    if year == 2019:
        assert len(selected) == 54 and totals[0] == 62
    annual_rows.append('<tr><th scope="row">' + str(year) + '</th>' + ''.join(
        '<td>' + format(int(v), ',').replace(',', '.') + '</td>'
        for v in [len(selected), *totals]) + '</tr>')
parts = {'__CSS__': (HERE / 'visuais_v1.css').read_text(encoding='utf-8'),
         '__ADESAO_ATUAL__': binary,
         '__CNES_ANNUAL__': ''.join(annual_rows),
         '__JS__': (HERE / 'visuais_v1.js').read_text(encoding='utf-8') + '\n' + (HERE / 'modelo_v1.js').read_text(encoding='utf-8'),
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
    'auditoria_alternativas/unidades_cnes_dezembro_corrigidas.csv',
    'auditoria_alternativas/conflitos_nome_documento.csv')]
sources += [HERE.parents[1] / 'dashboards' / 'base1_shiny' / 'data' / 'mg_municipios_sf_web.rds']
sources += [HERE / f for f in ('26_preparar_visuais_v1.R', '27_renderizar_visuais_v1.R',
                             '28_montar_visuais_v1.py', '30_estimar_piloto_participacoes.R',
                             'modelo_v1.js', 'adesao_visual.py', 'visuais_v1.html', 'visuais_v1.css', 'visuais_v1.js')]
sources += [HERE / 'outputs/piloto_participacoes/piloto.json']
sources += [HERE / 'outputs' / p for p in model_sources]
sources += [HERE / 'evidencias' / p for p in (
    'conciliacao_portais_2026_09_25.csv', 'conselheiro_pena_empenhos_2019_portal.csv',
    'solicitacoes_financeiras_pendentes_2026_09_25.csv')]
sources += [HERE / '37_conciliar_transacoes_portais.R']
sources += [HERE / 'outputs/auditoria_alternativas/conciliacao_financeira_2026_09_25' / p
            for p in ('resumo_por_restos.csv', 'decisao_conselheiro_pena_2019.csv')]
products = [DEST / 'index.html', *model_figures]
products += [DEST / 'figuras' / (figure + '.' + ext) for figure in sorted(active_figures) for ext in ('png', 'svg')]
products += [DEST / 'dados' / name for name in sorted({r['dados'] for r in data['catalog']} | {'visuais.json'})]
products += sorted((DEST / 'dados' / 'consulta').glob('*.js'))
with (DEST / 'dados' / 'manifesto.csv').open('w', encoding='utf-8-sig', newline='') as handle:
    writer = csv.writer(handle, delimiter=';')
    writer.writerow(('papel', 'arquivo', 'bytes', 'sha256'))
    for role, paths in (('entrada', sources), ('saida', products)):
        for path in paths:
            writer.writerow((role, path.relative_to(HERE.parents[1]).as_posix(), path.stat().st_size,
                             hashlib.sha256(path.read_bytes()).hexdigest()))
print(f'HTML pronto: {DEST / "index.html"}')
print(f'{len(data["catalog"])} figuras de base e {len(model_figures)//2} de modelos; {len(data["entities"])} entidades no atlas; fontes registradas.')
with ZipFile(DEST.parent / 'visuais_v1.zip', 'w', compression=ZIP_DEFLATED) as bundle:
    for path in products + [DEST / 'dados' / 'manifesto.csv']:
        bundle.write(path, Path('visuais_v1') / path.relative_to(DEST))
print('Copia para compartilhar: outputs/visuais_v1.zip (extrair a pasta inteira).')
