"""Confere transcrições públicas, integridade analítica e apresentação estática.

Não testa navegação/layout no navegador. Não transforma ausência de busca em zero.
Execute: python tests/24_validar_conciliacao_e_modelos.py
"""
from pathlib import Path
from decimal import Decimal as D
from collections import Counter
from html.parser import HTMLParser
import csv
import hashlib
import json
from zipfile import ZipFile
from PIL import Image

HERE = Path(__file__).resolve().parents[1]
def read(path):
    with (HERE / path).open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

ledger = read('evidencias/conciliacao_portais_2026_09_25.csv')
empenhos = read('evidencias/conselheiro_pena_empenhos_2019_portal.csv')
assert len(ledger) == 7 and len({r['id'] for r in ledger}) == 7
assert len(empenhos) == len({r['empenho'] for r in empenhos}) == 14
assert all(r['limite'] and r['url'].startswith('https://') for r in ledger)
assert all(r['cnpj'] == '00639952000150' for r in empenhos)
assert all(D(r['valor_pago']) == D(r['valor_empenhado']) == D(r['valor_liquidado']) for r in empenhos)
mides = read('outputs/auditoria_alternativas/cisvi_conselheiro_pena_2019_transacoes.csv')
assert Counter(D(r['valor_pago']) for r in empenhos) == Counter(D(r['valor_final']) for r in mides)
assert sum(D(r['valor_pago']) for r in empenhos) == D('11468.66')
objetos = [r for r in empenhos if r['objeto_consultado'] == 'TRUE']
assert {r['empenho'] for r in objetos} == {'671', '6337'}
assert all(r['descricao_transcrita'] and r['url_detalhe'] for r in objetos)
assert sum(D(r['valor_pago']) for r in objetos) == D('8836.43')
assert all(not r['descricao_transcrita'] for r in empenhos if r['objeto_consultado'] == 'FALSE')
dates_portal = Counter((r['data_empenho'], D(r['valor_pago'])) for r in empenhos)
dates_mides = Counter((r['data'], D(r['valor_final'])) for r in mides)
assert dates_portal - dates_mides == Counter({('2019-09-24', D('10')): 1})
assert dates_mides - dates_portal == Counter({('2019-09-26', D('10')): 1})
# Data do empenho não é automaticamente a data da transação MIDES.
financial = {(r['municipio'].casefold(), r['cnpj_raiz_8'], r['ano']): r
             for r in read('outputs/base_v1/base_financeira_v1.csv')
             if r['cnpj_raiz_8'] in {x['cnpj_raiz_8'] for x in ledger}}
for row in ledger:
    key = row['municipio'].casefold(), row['cnpj_raiz_8'], row['ano']
    assert D(financial[key]['valor_total']).quantize(D('.01')) == D(row['valor_mides'])
    if row['status'] in {'nao_localizado_na_consulta', 'ano_nao_oferecido', 'falha_conexao'}:
        assert row['valor_pago_portal'] == ''
assert D(ledger[3]['valor_mides']) - D(ledger[3]['valor_pago_portal']) == D('137077.88')
assert D(ledger[1]['valor_mides']) == D(ledger[1]['valor_pago_portal'])

invariants = read('evidencias/invariantes_nove_pares_2026_09_25.csv')
for row in invariants:
    path = HERE / row['arquivo']
    if path.suffix == '.html':
        path = HERE / 'outputs/auditoria_alternativas/antes_revisao_visual_2026_09_25/index.html'
    assert sha(path) == row['sha256'], path
html = (HERE / 'outputs/visuais_v1/index.html').read_text(encoding='utf-8')
class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.ids=[]; self.targets=[]; self.images=[]
    def handle_starttag(self, tag, attrs):
        a=dict(attrs)
        if 'id' in a: self.ids.append(a['id'])
        if a.get('href','').startswith('#bin-'): self.targets.append(a['href'][1:])
        if tag == 'img' and 'modelo_' in a.get('src',''): self.images.append(a)
parser = Links(); parser.feed(html)
assert len(parser.ids) == len(set(parser.ids))
assert set(parser.targets) <= set(parser.ids)
assert len(parser.images) == 3 and all(a.get('alt') for a in parser.images)
assert '53 → 62' in html and '8.836,43' in html and '137.077,88' in html
assert '__ADESAO_ATUAL__' not in html
with (HERE/'outputs/visuais_v1/dados/manifesto.csv').open(encoding='utf-8-sig',newline='') as f:
    manifest=list(csv.DictReader(f,delimiter=';'))
for row in manifest:
    path=HERE.parents[1]/row['arquivo']
    assert path.stat().st_size == int(row['bytes']) and sha(path) == row['sha256'], path
with ZipFile(HERE/'outputs/visuais_v1.zip') as bundle:
    assert bundle.read('visuais_v1/index.html') == (HERE/'outputs/visuais_v1/index.html').read_bytes()
    assert len([n for n in bundle.namelist() if n.endswith('.png')]) == 8
assert all(f'id="{name}"' in html for name in ['bin-radio-m','bin-radio-e','bin-municipios','bin-espacial'])
metrics = read('outputs/adesao_financeira/validacao.csv')
for row in metrics:
    if row['modelo'] in {'clinicas53','sedes53','sedes62','misto62'} and row['fold']=='0' and row['referencia']=='modelo':
        for field,digits in [('brier',5),('average_precision',3)]:
            assert f"{float(row[field]):.{digits}f}".replace('.',',') in html
figures={}
for name in ['modelo_brier_municipios','modelo_brier_espacial','modelo_calibracao']:
    path = HERE / 'outputs/visuais_v1/figuras' / (name+'.png')
    with Image.open(path) as im:
        assert im.width > 2000 and im.info['dpi'][0] >= 299
        figures[name]={'pixels':list(im.size),'dpi':im.info['dpi'][0]}
report={
    'status':'OK', 'data':'2026-09-25', 'consultas_registradas':len(ledger),
    'empenhos_valores_conferidos_com_mides':14, 'total_conselheiro_pena':'11468.66',
    'objetos_consultados':2, 'valor_objetos_nao_consorciais':'8836.43',
    'objetos_pendentes':12, 'datas_coincidentes':13,
    'diferenca_data_10_reais':'Empenho 24/09; MIDES 26/09. Não são necessariamente o mesmo evento.',
    'piedade_2021_pago_conferido':'779355.34','ipatinga_2018_diferenca_aberta':'137077.88',
    'zeros_2019_com_causa_encerrada':0, 'bases_e_estimativas_alteradas':False,
    'html_anterior_preservado':True,'figuras_modelos':figures,
    'html_ids_ancoras_numeros_manifesto_pacote':'OK',
    'qa_navegador':'Não executado: abertura do HTML local bloqueada pela política do navegador. QA anterior não se aplica à nova composição.',
    'fontes':{str(p.relative_to(HERE)):sha(p) for p in [
        HERE/'evidencias/conciliacao_portais_2026_09_25.csv',
        HERE/'evidencias/conselheiro_pena_empenhos_2019_portal.csv']}
}
(HERE/'checks/24_conciliacao_e_modelos.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
