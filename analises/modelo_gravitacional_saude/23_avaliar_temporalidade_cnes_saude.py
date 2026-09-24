"""Diagnostica a necessidade mensal e extrai um piloto sem alterar o painel anual.

--coletar-piloto baixa LT/SR/PF de cinco meses e reutiliza ST e dezembro/2017.
As competencias pontuais nao representam medias anuais nem capacidade contratada.
"""
import argparse
import csv
import importlib.util
import hashlib
import urllib.request
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / 'outputs'
CLINICAL = {'04', '05', '22', '36', '39', '62', '70'}
PILOT = {
    (2015, 1): ('97550393', '6150063', 'direto_ultimo_mes_clinico'),
    (2016, 6): ('01111142', '6776434', 'direto_ultimo_mes_clinico'),
    (2017, 6): ('64486822', '2143674', 'direto_ultimo_mes_clinico'),
    (2017, 10): ('01260691', '6311709', 'direto_ultimo_mes_clinico'),
    (2017, 4): ('71203715', '6019463', 'municipal_vinculo_documental_parcial'),
    (2017, 12): ('71203715', '6019463', 'municipal_sem_continuidade_anual_comprovada'),
}


def read(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def write(name, rows):
    assert rows, name
    with (OUT / name).open('w', encoding='utf-8-sig', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


def pilot():
    spec = importlib.util.spec_from_file_location('hist', HERE / '09_temporalizar_cnes_historico_saude.py')
    h = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(h)
    converter = h.locate_blast_dbf()
    rows, manifest = [], []
    for (year, month), (root, cnes, relation) in sorted(PILOT.items()):
        print(f'Piloto {year}{month:02} CNES {cnes}', flush=True)
        paths = {}
        for table in ('ST', 'LT', 'SR', 'PF'):
            url, path = h.source_path(table, year, month)
            cached = path.exists()
            h.download(url, path)
            paths[table] = path
            manifest.append(dict(competencia=f'{year}{month:02}', tabela=table,
                url=url, arquivo=path.relative_to(HERE).as_posix(), sha256=h.file_sha256(path),
                bytes=path.stat().st_size, ja_em_cache=cached,
                verificado_utc=datetime.now(timezone.utc).isoformat()))
        matches = [r for r in h.dbf_rows(paths['ST'], converter) if h.digits(r['CNES'], 7) == cnes]
        assert len(matches) == 1, (year, month, cnes, len(matches))
        st = matches[0]
        own, maint = h.digits(st['CPF_CNPJ'], 14), h.digits(st['CNPJ_MAN'], 14)
        direct = root in {own[:8], maint[:8]}
        assert direct == relation.startswith('direto'), (root, cnes, own, maint)
        cap = {t: h.capacity_by_unit(paths[t], converter, {cnes}, t).get(cnes, {})
               for t in ('LT', 'SR', 'PF')}
        beds, services, staff = (cap[t] for t in ('LT', 'SR', 'PF'))
        rows.append(dict(cnpj_raiz_8=root, competencia=f'{year}{month:02}', cnes=cnes,
            tipo_cnes=h.digits(st['TP_UNID'], 2), codigo_ibge_6=h.digits(st['CODUFMUN'], 6),
            cnpj_proprio=own, cnpj_mantenedora=maint, vinculo_cnpj_direto=direct,
            natureza_vinculo=relation, vinculo_sus=h.is_positive(st.get('VINC_SUS')),
            leitos_sus=beds.get('leitos_sus', 0),
            servicos_sus=len(services.get('servicos_sus', set())),
            profissionais_sus=len(staff.get('profissionais_sus', set())),
            cbo_medicos_sus=len(staff.get('cbos_medicos_sus', set())),
            carga_horaria_sus=staff.get('carga_horaria_sus', 0),
            fonte='outputs/manifesto_cnes_piloto_temporal.csv',
            limite='fotografia_mensal; nao_media_anual; capacidade_da_unidade_nao_cota_do_consorcio'))
        write('piloto_cnes_competencias_saude.csv', rows)
        write('manifesto_cnes_piloto_temporal.csv', manifest)


def archive_sources():
    folder = OUT / 'fontes_conciliacao'
    folder.mkdir(exist_ok=True)
    manifest = []
    for source in read(HERE / 'evidencias/fontes_prioritarios_2026_09_24.csv'):
        path = folder / source['arquivo_local']
        status = 'cache_local_conferido'
        try:
            if not path.exists():
                with urllib.request.urlopen(source['url'], timeout=45) as response:
                    path.write_bytes(response.read())
                status = 'baixado'
        except Exception as exc:
            status = f'{type(exc).__name__}: {exc}'
        manifest.append(dict(id_fonte=source['id_fonte'], url=source['url'],
            arquivo=path.relative_to(HERE).as_posix(), status=status,
            sha256=hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else '',
            verificado_utc=datetime.now(timezone.utc).isoformat()))
    write('manifesto_fontes_prioritarios_saude.csv', manifest)


def check_candidate():
    # A ficha atual nao prova nem exclui existencia antiga sob outro CNPJ.
    spec = importlib.util.spec_from_file_location('hist', HERE / '09_temporalizar_cnes_historico_saude.py')
    h = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(h)
    converter = h.locate_blast_dbf()
    rows = []
    for year in range(2014, 2022):
        url, path = h.source_path('ST', year)
        assert path.exists(), path
        found = [r for r in h.dbf_rows(path, converter) if h.digits(r['CNES'], 7) == '5941954']
        assert len(found) <= 1
        st = found[0] if found else {}
        rows.append(dict(competencia=f'{year}12', cnes='5941954', presente=bool(found),
            cnpj_proprio=h.digits(st.get('CPF_CNPJ'), 14) if found else '',
            cnpj_mantenedora=h.digits(st.get('CNPJ_MAN'), 14) if found else '',
            tipo_cnes=h.digits(st.get('TP_UNID'), 2) if found else '',
            fonte=url, arquivo=path.relative_to(HERE).as_posix(), sha256=h.file_sha256(path),
            limite='oito_dezembros; ausencia_nao_prova_inexistencia_de_atendimento'))
        print('Candidato CONSARDOCE', year, bool(found), flush=True)
    write('verificacao_cnes_candidato_consardoce.csv', rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--coletar-piloto', action='store_true')
    parser.add_argument('--arquivar-fontes', action='store_true')
    parser.add_argument('--verificar-candidato', action='store_true')
    args = parser.parse_args()
    december = {}
    for name in ('elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv',
                 'candidatas_cnes_capacidade_unidades_2014_2021.csv'):
        for r in read(OUT / name):
            december[r['cnpj_raiz_8'], r['ano'], r['cnes']] = r
    units = []
    for name in ('cnes_historico_presenca_mensal_saude_mg_2014_2021.csv',
                 'candidatas_cnes_presenca_mensal_2014_2021.csv'):
        for r in read(OUT / name):
            types = set(r.get('tipos_unidade_codigo', r.get('tipos_cnes', '')).split(' | '))
            if not types & CLINICAL:
                continue
            months = r['meses_presente'].split(' | ')
            dec = december.get((r['cnpj_raiz_8'], r['ano'], r['cnes']), {})
            clinical_dec = dec.get('funcao_assistencial') == 'destino_clinico_fixo'
            units.append(dict(cnpj_raiz_8=r['cnpj_raiz_8'], ano=r['ano'], cnes=r['cnes'],
                n_meses_presente=len(months), meses_presente=r['meses_presente'],
                tipos_no_ano=' | '.join(sorted(types)), clinica_dezembro=clinical_dec,
                presenca_parcial=len(months) < 12, mudanca_tipo=len(types) > 1,
                prioridade_temporal=(not clinical_dec or len(months) < 12 or len(types) > 1),
                limite='presenca_cadastral; meses_presente_nao_sao_necessariamente_meses_de_tipo_clinico'))
    write('diagnostico_necessidade_mensal_unidades_saude.csv', units)
    annual = defaultdict(list)
    for r in units:
        annual[r['cnpj_raiz_8'], r['ano']].append(r)
    rows = []
    for (root, year), own in sorted(annual.items()):
        rows.append(dict(cnpj_raiz_8=root, ano=year, unidades_tipo_clinico_algum_mes=len(own),
            unidades_clinicas_dezembro=sum(r['clinica_dezembro'] for r in own),
            unidades_presenca_parcial=sum(r['presenca_parcial'] for r in own),
            unidades_mudanca_tipo=sum(r['mudanca_tipo'] for r in own),
            unidades_prioridade_temporal=sum(r['prioridade_temporal'] for r in own),
            classe_temporal=('priorizar_coleta_mensal' if any(r['prioridade_temporal'] for r in own)
                             else 'presenca_e_tipo_estaveis_capacidade_mensal_nao_verificada')))
    write('diagnostico_necessidade_mensal_entidades_saude.csv', rows)
    if args.coletar_piloto:
        pilot()
    if args.arquivar_fontes:
        archive_sources()
    if args.verificar_candidato:
        check_candidate()
    print('Unidades-ano com algum tipo clinico:', len(units),
          '| entidades-ano:', len(rows),
          '| entidades-ano prioritarias:', sum(r['unidades_prioridade_temporal'] > 0 for r in rows))


if __name__ == '__main__':
    main()
