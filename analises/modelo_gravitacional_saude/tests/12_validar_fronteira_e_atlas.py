"""Valida a ampliacao da busca sem ampliar silenciosamente o universo original.

--browser acrescenta verificacao funcional offline e capturas com Playwright.
"""
import csv
import hashlib
import json
import sys
from collections import Counter
from decimal import Decimal
from pathlib import Path

HERE = Path(__file__).resolve().parents[1]
OUT = HERE / 'outputs'


def read(name):
    with (OUT / name).open(encoding='utf-8-sig', newline='') as handle:
        return list(csv.DictReader(handle))


original = {r['cnpj_raiz_8'] for r in read('universo_saude_mg_entidades.csv')}
audit = read('revisao_fora_84_resultado.csv')
outside = {r['cnpj_raiz_8'] for r in audit}
assert len(original) == 84 and len(audit) == len(outside) == 137
assert not original & outside
assert Counter(r['origem'] for r in audit) == {'cadastro_ipea_mg': 122, 'somente_cnm_mg': 15}
assert sum(r['revisao_documental'] == 'TRUE' for r in audit) == 28
assert sum(r['cnm_saude'] == '1' for r in audit) == 24
assert all(r['revisao_documental'] == 'TRUE' for r in audit
           if r['cnm_saude'] == '1' or int(r['n_unidades_ano_cnes']) > 0)
new_health = [r for r in audit if r['origem'] == 'somente_cnm_mg' and r['cnm_saude'] == '1']
assert len(new_health) == 9 and all(r['n_anos_mides'] == '8' for r in new_health)
assert sum(Decimal(r['valor_mides']) for r in new_health) == Decimal('258359912.14')
assert sum(r['decisao'] == 'candidato_saude_historica' for r in audit) == 10
assert sum(r['decisao'] == 'saude_historica_escopo_a_segregar' for r in audit) == 3

extra = read('fronteira_cnes_unidades_2014_2021.csv')
assert len(extra) == 74 and len({r['cnpj_raiz_8'] for r in extra}) == 11
assert Counter(r['funcao_assistencial'] for r in extra) == {
    'destino_clinico_fixo': 71, 'estrutura_fixa_nao_clinica': 3}
assert all(r['funcao_assistencial'] == 'estrutura_fixa_nao_clinica'
           for r in extra if r['cnpj_raiz_8'] == '21505692')
sources = read('fronteira_cnes_fontes.csv')
assert len(sources) == 8
for source in sources:
    path = OUT / 'cache_cnes_historico' / source['arquivo']
    assert hashlib.file_digest(path.open('rb'), 'sha256').hexdigest() == source['sha256']

units = read('atlas_unidades_consorcio_periodo.csv')
assert len(units) == len({(r['cnpj_raiz_8'], r['ano'], r['cnes']) for r in units}) == 2612
assert Counter('original' if r['cnpj_raiz_8'] in original else 'externo' for r in units) == {'original': 2538, 'externo': 74}
current = [r for r in units if r['ano'] == 'atual']
assert len(current) == 670 and sum(bool(r['lat']) for r in current) == 669
def cismep_clinics(year):
    return [r for r in units if r['cnpj_raiz_8'] == '05802877' and r['ano'] == year
            and r['funcao'] == 'destino_clinico_fixo']
assert len(cismep_clinics('2019')) == 2 and len(cismep_clinics('atual')) == 4
payments = read('atlas_pagamentos_entidade_municipio_ano.csv')
assert len(payments) == len({(r['cnpj_raiz_8'], r['codigo_ibge_6'], r['ano']) for r in payments})
preserved = sum(Decimal(r['valor']) for r in payments if r['cnpj_raiz_8'] in original and Decimal(r['valor']) > 0)
assert preserved.quantize(Decimal('.01')) == Decimal('3101980422.83')
igarape = [r for r in payments if (r['cnpj_raiz_8'], r['codigo_ibge_6'], r['ano']) == ('05802877', '313010', '2019')]
assert len(igarape) == 1 and Decimal(igarape[0]['valor']) == Decimal('4740790.51')
payload = json.loads((OUT / 'atlas_dados.json').read_text(encoding='utf-8'))
assert len(payload['entities']) == 221 and len(payload['municipalities']['features']) == 853
assert (OUT / 'atlas_consorcios_saude_mg.html').stat().st_size > 100000

if '--browser' in sys.argv:
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 1440, 'height': 1150})
        errors, requests = [], []
        page.on('pageerror', lambda error: errors.append(str(error)))
        page.on('request', lambda request: requests.append(request.url))
        page.goto((OUT / 'atlas_consorcios_saude_mg.html').as_uri())
        page.wait_for_selector('#entity')
        assert page.locator('#entity option').count() == 221
        assert page.locator('tbody tr').count() == 2
        page.locator('#period').select_option('atual')
        page.locator('#function').select_option('destino_clinico_fixo')
        assert page.locator('tbody tr').count() == 4
        page.locator('#function').select_option('all')
        page.locator('#period').select_option('2019')
        page.locator('#fit').click()
        page.wait_for_timeout(600)
        page.screenshot(path=str(OUT / 'atlas_cismep_2019.png'), full_page=True)
        page.locator('#entity').select_option('07356999')  # CIESP, CAPS historico
        page.locator('#type').select_option('Centro de atencao psicossocial')
        assert page.locator('tbody tr').count() == 1
        assert '7483066' in page.locator('tbody').inner_text()
        with page.expect_download() as download:
            page.locator('#csv').click()
        exported = Path(download.value.path()).read_text(encoding='utf-8-sig')
        assert '7483066' in exported and len(exported.splitlines()) == 2
        page.locator('#type').select_option('all')
        page.locator('#fit').click()
        page.locator('#cnm').check()
        page.wait_for_timeout(600)
        page.screenshot(path=str(OUT / 'atlas_ciesp_2019.png'), full_page=True)
        page.locator('#entity').select_option('21505692')  # CIMAMS nao e clinica
        page.locator('#function').select_option('destino_clinico_fixo')
        assert 'Nenhuma unidade' in page.locator('tbody').inner_text()
        page.locator('#function').select_option('all')
        assert 'Central gestao saude' in page.locator('tbody').inner_text()
        page.locator('#entity').select_option('01080759')
        page.locator('#period').select_option('atual')
        assert 'não coletado' in page.locator('#atlas-notice').inner_text()
        page.locator('#period').select_option('2019')
        assert page.locator('tbody tr').count() == 1
        page.set_viewport_size({'width': 390, 'height': 844})
        assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
        assert not errors, errors
        assert not [url for url in requests if url.startswith(('http:', 'https:'))], requests
        browser.close()
    print('Browser: filtros, tempo, tipo, CSV, avisos, tela estreita e uso offline validados.')
print('Fronteira/atlas: chaves, temporalidade, fontes e valores preservados; validacao concluida.')
