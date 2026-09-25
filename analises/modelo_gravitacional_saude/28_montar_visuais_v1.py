"""Empacota o HTML local e registra fontes/produtos. Executar depois de 26 e 27."""
from pathlib import Path
import csv
import hashlib
import json
from html import escape
from zipfile import ZipFile, ZIP_DEFLATED

HERE = Path(__file__).resolve().parent
DEST = HERE / 'outputs' / 'visuais_v1'

def rows(relative):
    with (HERE / 'outputs' / relative).open(encoding='utf-8-sig', newline='') as handle:
        return list(csv.DictReader(handle))

def number(value, digits=0):
    return f'{float(value):,.{digits}f}'.replace(',', '_').replace('.', ',').replace('_', '.')

def table(headers, values):
    return '<div class="table-wrap"><table><thead><tr>' + ''.join(
        '<th scope="col">'+escape(h)+'</th>' for h in headers) + '</tr></thead><tbody>' + ''.join(
        '<tr>'+''.join('<td>'+escape(str(v))+'</td>' for v in line)+'</tr>' for line in values)+'</tbody></table></div>'

model_sources = ['adesao_financeira/'+name+'.csv' for name in
                 ('amostras', 'validacao', 'coeficientes', 'exemplos')]
model_sources += ['auditoria_alternativas/cobertura_regras.csv']
samples, validation, coefficients, examples, territory = [rows(p) for p in model_sources]
model_sources += ['adesao_financeira/maiores_erros.csv']
examples += rows(model_sources[-1])
main_models = {'clinicas53':'S1 · Clínicas, 53', 'sedes53':'S2 · Sedes, mesmos 53',
               'sedes62':'S2 · Sedes, 62', 'misto62':'S3 · Misto, 62'}
results = []
for key, label in main_models.items():
    sample = next(r for r in samples if r['modelo']==key)
    metrics = [next(r for r in validation if r['modelo']==key and r['fold']=='0'
                   and r['referencia']=='modelo' and r['validacao']==scheme)
               for scheme in ('municipios','espacial')]
    results.append([label, number(sample['linhas']), number(sample['positivos']),
                    *[number(r['brier'],5) for r in metrics]])
coef = {r['termo']:float(r['coeficiente']) for r in coefficients if r['modelo']=='clinicas53'}
example_keys = [('3130101','05802877'),('3170107','09310999'),('3137205','05802877'),('3118403','00639952')]
example_notes = ['Pagamento observado; previsão compatível com o vínculo financeiro.',
    'Zero confirmado no relatório de contas municipal, p. 80. Previsão excessiva mesmo com destino no próprio município.',
    'Pagamento observado além de 120 minutos; um corte de duas horas perderia esta relação.',
    'Credor aparece como Ministério da Fazenda. Mantido sob alerta; não apresentar como vínculo validado.']
example_rows = []
for key, note in zip(example_keys, example_notes):
    r = next(r for r in examples if (r['id_municipio'],r['cnpj_raiz_8'])==key
             and r['modelo']=='clinicas53' and r['validacao']=='municipios')
    probability = float(r['prob_validacao'])*100
    display_probability = '>99,99%' if probability > 99.99 else number(probability,2)+'%'
    example_rows.append([r['municipio']+' × '+r['entidade'], 'R$ '+number(r['valor_total'],2),
                         display_probability, note])
rule_names={'ate120min':'Até 120 minutos','ate180min':'Até 180 minutos',
            'mesma_micro':'Mesma microrregião de saúde','cinco_proximos':'Cinco mais próximos (com empates)'}
territory_rows=[[rule_names[r['regra']],number(r['positivos_excluidos']),
                 'R$ '+number(r['valor_excluido'],2),number(r['sem_candidato'])]
                for r in territory if r['modelo']=='clinicas53' and r['regra'] in rule_names]
binary = '''<div class="section-intro"><div class="eyebrow">Adesão financeira · 2019</div>
<h1>Distância e capacidade ajudam a explicar quem paga a cada consórcio?</h1>
<p>Adesão significa pagamento positivo no MIDES, conforme a decisão da equipe. Cada município pode pagar a vários consórcios. Estimamos uma probabilidade para cada par; elas não precisam somar 100%.</p></div>
<ol class="pipeline compact"><li><h2>73 consórcios de saúde em 2019</h2><p>A financeira contém 853 municípios × 73 consórcios, com 1.376 relações pagas. O cenário estadual é exploratório: cadastro não comprova acesso institucional.</p></li>
<li><h2>53 com clínica e horas SUS positivas</h2><p>54 têm clínica direta em dezembro, com 62 unidades após a correção do CNES. Uma entidade tem zero horas SUS; fica fora da especificação com logaritmo das horas. Restam 45.209 pares, 771 pagos.</p></li>
<li><h2>Três cenários espaciais</h2><p>S1 usa municípios das clínicas. S2 usa a sede cadastral e é comparado primeiro nos mesmos 53. S2 e S3 ampliados têm 62: nove entidades acrescentam horas de outras modalidades. S3 usa clínica quando há e sede nos demais casos. A sede não tem vigência histórica comprovada.</p></li>
<li><h2>Prever fora do grupo de treino</h2><p>Cinco grupos de municípios, depois cinco blocos geográficos. Todas as linhas de uma origem ficam juntas. A avaliação espacial testa áreas deixadas fora do ajuste; não é previsão de outro ano.</p></li></ol>
<h2 class="subsection">Resultados dos cenários</h2><p>Erro de Brier é a média de (probabilidade − resultado observado)². Menor é melhor; zero seria previsão perfeita. Compare S1 e S2 nos mesmos 53. Ampliar para 62 também muda quem está na amostra.</p>'''
binary += table(['Cenário','Pares','Pagos','Brier municipal','Brier espacial'],results)
baseline = next(r for r in validation if r['modelo']=='clinicas53' and r['fold']=='0'
                and r['referencia']=='prevalencia' and r['validacao']=='municipios')
binary += '<p class="note">No S1, prever só a frequência média de pagamento do treino dá Brier '+number(baseline['brier'],5)+'. O modelo melhora essa referência, mas ainda erra casos importantes. A distância tem associação negativa; o efeito das horas entre clínicas é incerto (intervalo de 95% inclui zero). A sede não trouxe vantagem relevante na amostra comum.</p>'
binary += '<h2 class="subsection">Quatro exemplos reais</h2><p>Probabilidades calculadas sem usar o município no treino, no S1. Uma previsão alta não comprova filiação nem atendimento.</p>'+table(['Município × consórcio','MIDES 2019','Probabilidade','Leitura'],example_rows)
binary += '''<h2 class="subsection">Como a conta usa a base</h2><div class="model-equations"><div><span>Resultado observado</span><p>yᵢⱼ = 1 se pagamento &gt; 0; caso contrário, 0</p></div><div><span>Impedância entre municípios</span><p>Lᵢⱼ = Σᵤ (Hⱼᵤ / Hⱼ) ln(1 + kmᵢᵤ)</p></div><div><span>Probabilidade</span><p>pᵢⱼ = 1 / (1 + exp(−ηᵢⱼ))</p></div></div>'''
binary += '<p class="note">No ajuste S1: η = '+number(coef['(Intercept)'],3)+' − '+number(-coef['log_populacao'],3)+' ln(população) + '+number(coef['log_horas'],3)+' ln(horas SUS) − '+number(-coef['impedancia'],3)+' L. As horas ponderam as distâncias às unidades do consórcio; o +1 permite distância municipal zero. População e horas não recebem +1: exigimos valores positivos.</p>'
binary += '''<p>Em Igarapé × CISMEP, a população é 43.045 e as clínicas de Betim e Brumadinho somam 1.651 horas SUS cadastradas. A impedância ponderada é 2,9667. O ajuste completo produz cerca de 95,94%; a previsão sem Igarapé no treino é a da tabela. São probabilidades de pagamento, não parcelas do dinheiro. O sinal da população é condicional às demais variáveis e não estabelece uma causa.</p>
<h2 class="subsection">O que aconteceu ao restringir as alternativas</h2><p>Denominador: as 771 relações pagas do S1, R$ 360,34 milhões. Nenhum corte foi adotado como regra definitiva.</p>'''+table(['Regra testada','Pagos excluídos','Valor excluído','Municípios sem opção'],territory_rows)
binary += '''<div class="data-layers"><article><h3>Erros de cadastro tratados</h3><p>Dois consultórios PF foram retirados do CISMARG. As quatro estimativas principais ficaram iguais, pois essas unidades tinham zero horas SUS. Mínimos de viagem e mapas foram corrigidos.</p></article><article><h3>Pagamentos sob verificação</h3><p>17 pares-ano, R$ 1,35 milhão, têm conflito de credor na v1. Dois pertencem a 2019. Excluí-los em sensibilidade mudou pouco as métricas; os registros não foram transformados em zero.</p></article><article><h3>Distância zero continua sendo um limite</h3><p>A matriz liga sedes municipais, não endereços. No grupo de 57 pares intramunicipais do S1, a previsão média é 99,07% e 52 pagaram (91,23%). O excesso de confiança não está resolvido.</p></article><article><h3>O que ainda precisa de evidência</h3><p>Contratos e regras de acesso podem explicar vínculos e zeros que a geografia não explica. Horas são cadastro de dezembro, não consultas realizadas. Não há validação causal nem modelo final aprovado.</p></article></div>
<details class="trace"><summary>Fontes e reprodução desta versão</summary><p>Scripts 31 e 32: cenários e adesão financeira. Scripts 33 a 35: identificação CNES, alternativas territoriais e credores MIDES. Testes 19 a 21 verificam os dados e reconstroem estimativas e validações. As referências primárias e seus limites estão em METODOLOGIA_GERAL.md e evidencias/referencias_auditoria_alternativas_2026_09_24.csv. A correção da v1 é reproduzida pelo script 25, preservando a entrega anterior.</p><p>CNES/DATASUS de dezembro/2019, MIDES/Base dos Dados, população IBGE e matriz Distbrasil. A evidência de Uberaba vem do <a href="https://www.uberaba.mg.gov.br/portal/acervo/portal_transparencia/arquivos/2019/prestacao%20contas/Relatorio%20do%20Controle%20Interno.pdf" target="_blank" rel="noreferrer">relatório municipal de controle interno de 2019, p. 80</a>. A notificação trata do contrato de rateio; não comprova saída jurídica de todos os instrumentos.</p></details>'''
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
                             'modelo_v1.js', 'visuais_v1.html', 'visuais_v1.css', 'visuais_v1.js')]
sources += [HERE / 'outputs/piloto_participacoes/piloto.json']
sources += [HERE / 'outputs' / p for p in model_sources]
products = [DEST / 'index.html']
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
print(f'{len(data["catalog"])} figuras; {len(data["entities"])} entidades no atlas; fontes registradas.')
with ZipFile(DEST.parent / 'visuais_v1.zip', 'w', compression=ZIP_DEFLATED) as bundle:
    for path in products + [DEST / 'dados' / 'manifesto.csv']:
        bundle.write(path, Path('visuais_v1') / path.relative_to(DEST))
print('Copia para compartilhar: outputs/visuais_v1.zip (extrair a pasta inteira).')
