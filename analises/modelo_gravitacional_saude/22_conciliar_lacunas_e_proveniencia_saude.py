"""Concilia a EDA com CNES e dossies sem modificar o painel ou imputar destinos.

Executar apos o script 21. --verificar-cismas le 12 ST ja baixados de 2016;
--baixar-fontes guarda as novas fontes publicas em cache local, sem credenciais.
"""
import argparse
import csv
import hashlib
import importlib.util
import re
import urllib.request
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT, EVID = HERE / 'outputs', HERE / 'evidencias'
DATE = '2026-09-24'
CLINICAL = {'04', '05', '22', '36', '39', '62', '70'}
GROUPS = {
    'movel_regulacao_ou_transporte': {
        'oferta_movel_cadastrada', 'samu_regional_documentado', 'inicio_samu_durante_ano',
        'samu_regulacao_documentada_sem_polo_fixo', 'servico_aeromedico_movel_documentado',
        'transporte_documentado_sem_destino_clinico'},
    'fase_anterior_operacao_samu': {'pre_operacao_samu_regional'},
    'redes_indiretas_ou_programas': {
        'programas_documentados_sem_destino_clinico_identificado',
        'programas_fixos_documentados_sem_cnes_e_endereco', 'rede_indireta_documentada_no_periodo',
        'rede_indireta_documentada_sem_destinos_anuais', 'rede_indireta_e_movel_sem_vinculo_de_capacidade',
        'rede_indireta_sem_destinos_anuais', 'rede_multidestino_documentada_no_fim_da_janela'},
    'cadastro_intrano_ou_posterior': {'tipo_clinico_em_outros_meses_fora_dezembro', 'registro_fixo_posterior'},
    'historicas_sem_polo': {'historica_sem_polo_documentado'},
    'demais_sem_destino_clinico_suficientemente_documentado': {
        'evidencia_insuficiente', 'implantacao_planejada_operacao_nao_comprovada',
        'sem_evidencia_suficiente_de_polo_no_ano', 'sem_vinculo_direto_identificado',
        'somente_estrutura_nao_clinica_cadastrada'},
}


def read(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def write(path, rows):
    assert rows, f'Saida vazia: {path}'
    with path.open('w', encoding='utf-8-sig', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


def clean(value):
    if value in ('', 'NA', None):
        return ''
    return re.sub(r'<U\+([0-9A-Fa-f]{4,6})>',
                  lambda m: chr(int(m[1], 16)), value).strip()


def sha(path):
    with path.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def key(row):
    return row['cnpj_raiz_8'], row['ano']


def join(values):
    return ' | '.join(sorted({clean(v) for v in values if clean(v)}))


def verify_cismas():
    spec = importlib.util.spec_from_file_location('hist', HERE / '09_temporalizar_cnes_historico_saude.py')
    hist = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(hist)
    converter = hist.locate_blast_dbf()
    rows = []
    for month in range(1, 13):
        url, path = hist.source_path('ST', 2016, month)
        found = hist.select_establishments(path, converter, {'01111142'},
                                          {'01111142': {}}, {}, 2016, month)
        unit = found['6776434']
        rows.append(dict(competencia=f'2016{month:02}', cnpj_raiz_8='01111142',
                         cnes='6776434', tipo_cnes=unit['tipo_unidade_codigo'],
                         municipio=unit['codigo_ibge_6'], fonte_url=url,
                         sha256=sha(path)))
    assert len(rows) == 12 and rows[-1]['tipo_cnes'] == '64'
    assert any(r['tipo_cnes'] == '36' for r in rows)
    write(OUT / 'conciliacao_cismas_2016_mensal.csv', rows)


def archive_sources(sources):
    folder = OUT / 'fontes_conciliacao'
    folder.mkdir(exist_ok=True)

    def fetch(s):
        ext = '.pdf' if '.pdf' in s['url'] or 'download-sub-pagina' in s['url'] else '.html'
        path = folder / ('ses_rdqa_2021_volume1.pdf' if s['id_fonte'] == 'consurge_inicio'
                         else s['id_fonte'] + ext)
        result = dict(id_fonte=s['id_fonte'], url=s['url'],
                      consulta_utc=datetime.now(timezone.utc).isoformat(),
                      arquivo_local='', sha256='', status='')
        # Os dois PDFs ja devolveram HTTP 403 nesta auditoria; nao repetir.
        if s['id_fonte'].startswith('circuito_ata'):
            result['status'] = 'HTTP_403_previamente_observado; conteudo_nao_utilizado'
            return result
        try:
            if not path.exists():
                with urllib.request.urlopen(s['url'], timeout=25) as response:
                    data = response.read()
                if ext == '.pdf' and not data.startswith(b'%PDF'):
                    raise ValueError('Resposta nao e PDF')
                path.write_bytes(data)
            result.update(arquivo_local=path.relative_to(HERE).as_posix(),
                          sha256=sha(path), status='cache_local_disponivel')
        except Exception as exc:
            result['status'] = f'{type(exc).__name__}: {str(exc)[:120]}'
        return result

    with ThreadPoolExecutor(max_workers=4) as pool:
        rows = list(pool.map(fetch, sources))
    write(folder / 'manifesto.csv', rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verificar-cismas', action='store_true')
    parser.add_argument('--baixar-fontes', action='store_true')
    args = parser.parse_args()
    if args.verificar_cismas:
        verify_cismas()
    cismas_path = OUT / 'conciliacao_cismas_2016_mensal.csv'
    if not cismas_path.exists():
        raise FileNotFoundError('Primeira execucao: usar --verificar-cismas para conferir o ST mensal.')
    cismas_months = read(cismas_path)
    sources = read(EVID / 'fontes_conciliacao_2026_09_24.csv')
    if args.baixar_fontes:
        archive_sources(sources)
    starts = {s['cnpj_raiz_8']: s for s in sources if s['inicio_servico']}
    gaps = read(OUT / 'eda_lacunas_polo_entidade_ano_saude.csv')
    old = {key(r): r for r in read(OUT / 'decisoes_documentais_91_entidades_ano.csv')}
    docs = {r['cnpj_raiz_8']: r for r in read(EVID / 'auditoria_documental_21_entidades_2026_09_16.csv')}
    seven = {r['cnpj_raiz_8']: r for r in read(EVID / 'decisoes_sete_entidades_2026_09_10.csv')}
    external = {r['cnpj_raiz_8']: r for r in read(EVID / 'revisao_fora_84_2026_09_16.csv')}
    names = {r['cnpj_raiz_8']: r['razao_social_canonica']
             for r in read(OUT / 'universo_saude_mg_entidades.csv')}
    units, monthly = defaultdict(list), defaultdict(list)
    for name in ('elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv',
                 'candidatas_cnes_capacidade_unidades_2014_2021.csv'):
        for r in read(OUT / name):
            units[key(r)].append(r)
    for name in ('cnes_historico_presenca_mensal_saude_mg_2014_2021.csv',
                 'candidatas_cnes_presenca_mensal_2014_2021.csv'):
        for r in read(OUT / name):
            monthly[key(r)].append(r)
    manifest = {r['competencia']: r for r in read(OUT / 'manifesto_cnes_historico_saude_mg.csv')
                if r['tabela'] == 'ST'}
    for year in range(2014, 2022):
        source = manifest[f'{year}12']
        assert sha(OUT / 'cache_cnes_historico' / source['arquivo']) == source['sha256']

    rows = []
    for g in gaps:
        root, year_s = key(g)
        year = int(year_s)
        dec = units[key(g)]
        nmobile = sum(u['funcao_assistencial'] == 'unidade_movel' for u in dec)
        nnonclinical = sum(u['funcao_assistencial'] == 'estrutura_fixa_nao_clinica' for u in dec)
        assert len(dec) == nmobile + nnonclinical, f'Clinica em caso sem polo: {key(g)}'
        clinical_other = [u for u in monthly[key(g)] if CLINICAL.intersection(
            u.get('tipos_unidade_codigo', u.get('tipos_cnes', '')).split(' | '))]
        previous = clean(g['classificacao_assistencial_documental'])
        d, e, s, o = docs.get(root, {}), external.get(root, {}), seven.get(root, {}), old.get(key(g), {})
        contextual_urls = join([d.get('fonte_principal'), d.get('fonte_complementar'),
                                e.get('fonte'), s.get('fonte_url')])
        annual_url = join([o.get('fonte_principal'), o.get('fonte_complementar_url')])
        evidence = clean(o.get('evidencia_documental')) or clean(s.get('alcance_da_evidencia'))
        limit = 'CNES direto por CNPJ em dezembro; ausencia nao prova inexistencia de atendimento terceirizado.'
        # Fontes antigas ficam explicitas como contexto; nao se estendem anos automaticamente.
        context = join([d.get('anos_mides_sem_fixa_dezembro'), e.get('periodo_evidencia'), s.get('alcance_da_evidencia')])
        classification = 'sem_vinculo_direto_identificado'
        treatment = 'localizar_prestador_e_vigencia; manter_sem_tempo_clinico'
        basis = 'CNES_historico_e_contexto_documental'
        start_date = ''
        if root in starts:
            src = starts[root]
            start_date = src['inicio_servico']
            start_year = int(start_date[:4])
            classification = ('pre_operacao_samu_regional' if year < start_year else
                              'inicio_samu_durante_ano' if year == start_year else
                              'samu_regional_documentado')
            treatment = ('preservar_pagamento_de_fase_pre_operacional' if year < start_year else
                         'especificacao_movel_com_vigencia_propria')
            annual_url, evidence = src['url'], src['resumo']
            limit += ' ' + src['limite']
            basis = f"evidencias/fontes_conciliacao_2026_09_24.csv#{src['id_fonte']}"
        elif clinical_other:
            classification = 'tipo_clinico_em_outros_meses_fora_dezembro'
            treatment = 'sensibilidade_mensal_sem_imputar_capacidade_dezembro'
            evidence = 'ST mensal contem tipo clinico no ano; dezembro nao contem destino clinico.'
            limit += ' Lista anual de tipos nao identifica sozinha os meses de cada tipo.'
            basis = 'CNES_ST_mensal; outputs/manifesto_cnes_historico_saude_mg.csv'
        elif nmobile:
            classification = 'oferta_movel_cadastrada'
            treatment = 'especificacao_movel; nao_usar_central_como_clinica'
            evidence = 'Ha unidades moveis diretamente vinculadas na competencia de dezembro.'
            basis = 'CNES_ST_dezembro'
        elif previous:
            classification = previous
            treatment = clean(g['decisao_destino_fixo_anual']) or 'manter_sem_tempo_clinico'
            basis = 'outputs/decisoes_documentais_91_entidades_ano.csv; evidencias/decisoes_sete_entidades_2026_09_10.csv'
        elif nnonclinical:
            classification = 'somente_estrutura_nao_clinica_cadastrada'
            evidence = 'CNES de dezembro contem somente centrais de gestao ou regulacao.'
            basis = 'CNES_ST_dezembro'
        if root == '71203715' and year == 2016:
            classification = 'programas_documentados_sem_destino_clinico_identificado'
            annual_url, evidence = d['fonte_principal'], d['evidencia_documental']
            limit += (' Leitura inicial utilizou o trecho Fhemig 2014-2016; a revisao complementar '
                      'reconhece instrumentos 2017-2019 nas paginas 9-10. Consultar revisao_prioritarios_2026_09_24.csv.')
            basis = 'auditoria_documental_21_entidades_2026_09_16.csv; alcance_explicito_do_texto'
        if root == '71203715' and year == 2017:
            limit += ' Ata de 17/11/2017 localizada no indice; acesso ao PDF HTTP 403; conteudo nao utilizado.'
        if root == '01111142' and year == 2016:
            evidence = 'CNES 6776434: ' + join([
                f"{r['competencia']} tipo {r['tipo_cnes']}" for r in cismas_months])
            basis = 'outputs/conciliacao_cismas_2016_mensal.csv; 12 fontes ST com URL e SHA256'
            limit = ('Tipo 36 em janeiro-junho e 64 em julho-dezembro; mudanca cadastral nao prova fechamento '
                     'ou ausencia de atendimento. Capacidade clinica dos meses iniciais nao foi estimada.')
        if not evidence:
            evidence = 'Sem clinica diretamente vinculada recuperada para dezembro; consultar fonte contextual sem retroacao.'
        group = [name for name, classes in GROUPS.items() if classification in classes]
        assert len(group) == 1, classification
        source = manifest[f'{year}12']
        rows.append(dict(cnpj_raiz_8=root, ano=year, entidade=clean(g['sigla']) or clean(names.get(root, root)),
            origem_universo=g['origem_universo'], pares_pagantes=int(g['pares']), valor_mides=g['valor'],
            classificacao_anterior_painel=previous or 'sem_classificacao_anual_no_painel',
            grupo_conciliacao=group[0], classificacao_conciliada=classification, tratamento_dados=treatment,
            n_unidades_moveis_dezembro=nmobile, n_estruturas_nao_clinicas_dezembro=nnonclinical,
            cnes_dezembro=join([u['cnes'] for u in dec]),
            tipos_cnes_dezembro=join([u['tipo_unidade_codigo'] for u in dec]),
            municipios_cadastro_dezembro=join([u['codigo_ibge_6'] for u in dec]),
            cnes_com_tipo_clinico_em_algum_mes=join([u['cnes'] for u in clinical_other]),
            inicio_servico_documentado=start_date, fundamento=evidence,
            fonte_decisao=basis, fonte_documental_aplicada=annual_url,
            referencias_contextuais_nao_automaticamente_anuais=contextual_urls,
            alcance_contexto_original=context, fonte_cnes_url=source['url_origem'],
            fonte_cnes_sha256=source['sha256'], competencia_cnes=f'{year}12',
            polo_clinico_anual_recuperado='FALSE', limite=limit, data_conciliacao=DATE))
    rows.sort(key=lambda r: (r['ano'], -Decimal(r['valor_mides']), r['cnpj_raiz_8']))
    assert len(rows) == 181 and len({(r['cnpj_raiz_8'], r['ano']) for r in rows}) == 181
    assert sum(r['pares_pagantes'] for r in rows) == 5123
    assert abs(sum(Decimal(r['valor_mides']) for r in rows) - Decimal('450467803.61')) < Decimal('.01')
    assert sum(r['classificacao_anterior_painel'] != 'sem_classificacao_anual_no_painel' for r in rows) == 84
    write(EVID / 'conciliacao_181_entidades_ano_2026_09_24.csv', rows)
    totals = defaultdict(lambda: [0, 0, Decimal(0)])
    for r in rows:
        t = totals[r['grupo_conciliacao']]
        t[0] += 1
        t[1] += r['pares_pagantes']
        t[2] += Decimal(r['valor_mides'])
    summary = [dict(grupo_conciliacao=k, entidades_ano=v[0], pares_pagantes=v[1],
                    valor_mides=f'{v[2]:.2f}') for k, v in sorted(totals.items())]
    write(OUT / 'resumo_conciliacao_lacunas_saude.csv', summary)

    labels = []
    annual_finance = read(OUT / 'mides_saude_mg_consolidado_entidade_ano.csv')
    for r in read(OUT / 'universo_saude_mg_entidades.csv'):
        if clean(r['sigla_canonica']):
            continue
        paid = [x for x in annual_finance if x['cnpj_raiz_8'] == r['cnpj_raiz_8'] and Decimal(x['valor_total']) > 0]
        if not paid:
            continue
        labels.append(dict(cnpj_raiz_8=r['cnpj_raiz_8'], sigla_original='',
                           rotulo_exibicao=clean(r['razao_social_canonica']),
                           origem_rotulo='universo_saude_mg_entidades.csv:razao_social_canonica',
                           pares_pagos=len(paid), sigla_inventada='FALSE'))
    assert sum(r['pares_pagos'] for r in labels) == 314
    write(OUT / 'rotulos_entidades_sem_sigla_saude.csv', labels)
    inventory()
    print('Conciliacao:', len(rows), 'entidades-ano;', len({r['cnpj_raiz_8'] for r in rows}), 'entidades')
    for r in summary:
        print(r)


def inventory():
    # Indice de localizacao; referencias no codigo nao sao prova de autoria do arquivo.
    scripts = {p.name: p.read_text(encoding='utf-8-sig') for p in HERE.iterdir()
               if p.suffix in {'.py', '.R', '.sql', '.js'}}
    rows = []
    for p in sorted(OUT.iterdir()):
        if not p.is_file() or p.name in {'inventario_produtos_saude.csv', 'manifesto_entradas_conciliacao_saude.csv'}:
            continue
        rows.append(dict(arquivo=p.relative_to(HERE).as_posix(), tamanho_bytes=p.stat().st_size,
                         sha256=sha(p),
                         modificacao_local_nao_e_data_extracao=datetime.fromtimestamp(p.stat().st_mtime).isoformat(),
                         scripts_que_referenciam=join([n for n, code in scripts.items() if p.name in code]),
                         fonte_e_reproducao='DICIONARIO_TECNICO.md; consultar scripts e manifestos',
                         versionado_no_git='FALSE'))
    write(OUT / 'inventario_produtos_saude.csv', rows)
    inputs = [ROOT / 'dados/bruto/mides_mg_atualizado.rds', ROOT / 'dados/processado/painel_mg_anual.rds',
              OUT / 'painel_anual_integrado_saude_mg_2014_2021.rds',
              OUT / 'fronteira_mides_complementar.csv', OUT / 'fronteira_consulta_mides_manifesto.json',
              OUT / 'manifesto_cnes_historico_saude_mg.csv',
              OUT / 'conciliacao_cismas_2016_mensal.csv']
    inputs += sorted(EVID.glob('*.csv'))
    write(OUT / 'manifesto_entradas_conciliacao_saude.csv',
          [dict(arquivo=p.relative_to(ROOT).as_posix(), sha256=sha(p), tamanho_bytes=p.stat().st_size,
                data_auditoria=DATE) for p in inputs])


if __name__ == '__main__':
    main()
