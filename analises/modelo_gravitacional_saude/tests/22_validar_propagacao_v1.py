"""Compara a entrega preservada e os derivados corrigidos, sem gerar os dados."""
from pathlib import Path
import hashlib
import json
import sys
import pandas as pd
from pandas.testing import assert_frame_equal

HERE = Path(__file__).resolve().parents[1]
OUT = HERE / 'outputs'
SNAP = OUT / 'auditoria_alternativas/antes_propagacao_2026_09_25'

def read(path):
    return pd.read_csv(path, dtype={'id_municipio':str,'cnpj_raiz_8':str,'cnes':str})

keys = ['id_municipio','cnpj_raiz_8','ano']
flags = read(OUT/'auditoria_alternativas/conflitos_nome_documento.csv').set_index(keys)
report = {}
for kind in ['financeira','gravitacional']:
    path = 'base_v1/base_'+kind+'_v1.csv'
    old, new = [read(folder/path).set_index(keys) for folder in [SNAP,OUT]]
    assert old.index.equals(new.index)
    changed = [c for c in old if not old[c].equals(new[c])]
    assert set(new)-set(old) == {'conflito_credor_mides','valor_credor_conflitante'}
    assert_frame_equal(old.drop(columns=changed),new[old.columns].drop(columns=changed),check_exact=True)
    assert new.conflito_credor_mides.tolist() == new.index.isin(flags.index).tolist()
    expected = flags.valor_conflitante.reindex(new.index).fillna(0)
    assert (abs(new.valor_credor_conflitante-expected)<1e-8).all()
    if kind=='financeira':
        assert not changed and new.conflito_credor_mides.sum()==17
        assert abs(new.valor_credor_conflitante.sum()-1352846.55)<.01
    else:
        assert set(changed)=={'n_destinos_clinicos_dezembro','n_municipios_clinicos_dezembro',
            'tempo_minimo_min','tempo_mediano_min','tempo_maximo_min',
            'distancia_minima_km','destino_clinico_mais_proximo_id'}
        for c in changed:
            affected=new[old[c]!=new[c]]
            assert set(affected.index.get_level_values('cnpj_raiz_8'))=={'00079634'}
        paid=new.valor_total>0
        assert (old.loc[paid,'tempo_minimo_min']==new.loc[paid,'tempo_minimo_min']).all()
        report['alteracoes_por_coluna']={c:int((old[c]!=new[c]).sum()) for c in changed}
    report[kind]={'linhas':len(new),'colunas':len(new.columns)+3,
                  'conflitos':int(new.conflito_credor_mides.sum()),'valor':float(new.valor_total.sum())}

# Snapshot completo, nao somente copia de totais.
manifest=read(SNAP/'base_v1/manifesto.csv')
for r in manifest[manifest.papel=='saida'].itertuples():
    assert hashlib.sha256((SNAP/'base_v1'/Path(r.arquivo).name).read_bytes()).hexdigest()==r.sha256
units=read(OUT/'auditoria_alternativas/unidades_cnes_dezembro_corrigidas.csv')
atlas=read(OUT/'atlas_unidades_consorcio_periodo.csv')
old_atlas=read(SNAP/'atlas_unidades_consorcio_periodo.csv')
assert not atlas.cnes.isin(['5101034','5254191']).any()
assert len(old_atlas)-len(atlas)==16
assert_frame_equal(old_atlas[old_atlas.ano=='atual'].reset_index(drop=True),
                   atlas[atlas.ano=='atual'].reset_index(drop=True),check_exact=True)
unit_keys=['cnpj_raiz_8','ano','cnes']
expected=set(map(tuple,units[unit_keys].astype(str).values))
assert set(map(tuple,atlas[atlas.ano!='atual'][unit_keys].astype(str).values))==expected
data=json.loads((OUT/'visuais_v1/dados/visuais.json').read_text(encoding='utf-8'))
assert len(data['auditoria'])==17
assert sum(r['conflito_credor_mides'] for r in data['payments'])==17
assert not any(r['cnes'] in ['5101034','5254191'] for r in data['units'])
html=(OUT/'visuais_v1/index.html').read_text(encoding='utf-8')
assert '__ADESAO_ATUAL__' not in html
assert 'Adesão financeira · 2019' in html and 'query-conflict' in html
assert '52.886' in html and '45.209' in html and 'S3 · Misto, 62' in html
assert '&gt;99,99%' in html
report.update(status='OK',registros_cnes_retirados=16,tempos_minimos_pagos_alterados=0)
if '--browser' in sys.argv:
    from playwright.sync_api import sync_playwright
    shots=OUT/'visuais_v1/qa_2026_09_25'
    shots.mkdir(exist_ok=True)
    with sync_playwright() as pw:
        browser=pw.chromium.launch(headless=True)
        page=browser.new_page(viewport={'width':1440,'height':1050})
        errors=[]
        page.on('pageerror',lambda e:errors.append(str(e)))
        page.goto((OUT/'visuais_v1/index.html').as_uri())
        assert page.evaluate("valueText(1234.56,'valor_credor_conflitante')")=='1.234,56'
        for section in ['panorama','construcao','pagamentos','capacidade','atlas','consulta','modelo']:
            page.locator(f'nav button[data-page="{section}"]').click()
            assert page.locator(f'#{section}').is_visible()
            assert page.evaluate('document.documentElement.scrollWidth <= innerWidth+1'),section
            page.screenshot(path=str(shots/f'{section}_desktop.png'))
        page.get_by_role('heading',name='Quatro exemplos reais',exact=True).scroll_into_view_if_needed()
        page.screenshot(path=str(shots/'modelo_exemplos.png'))
        assert page.locator('#piloto-anterior').get_attribute('open') is None
        page.locator('#piloto-anterior > summary').click()
        assert page.locator('#model-calculation').inner_text()
        page.locator('nav button[data-page="capacidade"]').click()
        annual=page.locator('#cnes-annual tbody tr').filter(has=page.get_by_role('rowheader',name='2019',exact=True))
        assert annual.locator('td').nth(1).inner_text()=='62'
        page.locator('#cnes-annual').scroll_into_view_if_needed()
        page.screenshot(path=str(shots/'cnes_anual.png'))
        page.locator('nav button[data-page="atlas"]').click()
        page.locator('#atlas-entity').select_option('00079634')
        page.locator('#atlas-year').select_option('2019')
        assert '5101034' not in page.locator('#unit-list').inner_text()
        assert '6230261' in page.locator('#unit-list').inner_text()
        page.locator('#map-municipality').select_option('316120')
        assert 'conflita' in page.locator('#map-selection').inner_text()
        page.locator('#main-map').scroll_into_view_if_needed()
        page.screenshot(path=str(shots/'cismarg_corrigido.png'))
        page.locator('nav button[data-page="consulta"]').click()
        page.locator('#query-year').select_option('all')
        page.locator('#query-conflict').select_option('yes')
        page.locator('#query-load').click()
        page.wait_for_function('document.getElementById("query-status").textContent.startsWith("17 linhas")',timeout=120000)
        assert page.locator('#query-table tbody tr').count()==17
        page.screenshot(path=str(shots/'consulta_alertas.png'))
        page.locator('#query-base').select_option('direta')
        page.locator('#query-year').select_option('2019')
        page.locator('#query-load').click()
        page.wait_for_function('document.getElementById("query-status").textContent.startsWith("2 linhas")',timeout=60000)
        assert page.locator('#query-table tbody tr').count()==2
        page.set_viewport_size({'width':390,'height':844})
        for section in ['panorama','construcao','pagamentos','capacidade','atlas','consulta','modelo']:
            page.locator(f'nav button[data-page="{section}"]').click()
            assert page.evaluate('document.documentElement.scrollWidth <= innerWidth+1'),section
            page.screenshot(path=str(shots/f'{section}_mobile.png'))
        assert not errors,errors
        browser.close()
    report['navegador']={'abas_desktop_mobile':7,'erros_javascript':errors,
                         'consulta_conflitos_todos_anos':17,'consulta_direta_2019':2}
(HERE/'checks/22_propagacao_v1.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
