"""Extrai RCL municipal do RREO-Anexo 03, sexto bimestre, sem a confundir com receita total.

Usa a API publica da STN; produz um CSV por ano para permitir retomada.
As 853 consultas de 2014 nao retornaram a conta RCL do sexto bimestre.
"""
import csv
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import requests

OUT = Path(__file__).resolve().parent / 'outputs'
URL = 'https://apidatalake.tesouro.gov.br/ords/siconfi/tt/rreo'
ACCOUNTS = {'ReceitaCorrenteLiquida', 'RREO3ReceitaCorrenteLiquida'}


def fetch(municipality, year):
    params = dict(an_exercicio=year, nr_periodo=6, co_tipo_demonstrativo='RREO',
                  no_anexo='RREO-Anexo 03', id_ente=municipality)
    error = ''
    for attempt in range(3):
        try:
            response = requests.get(URL, params=params, timeout=30)
            response.raise_for_status()
            payload = response.json()
            matches = [r for r in payload['items']
                       if r.get('cod_conta') in ACCOUNTS
                       and r.get('coluna', '').startswith('TOTAL')]
            if len(matches) > 1:
                raise ValueError(f'RCL ambigua: {len(matches)} linhas')
            return dict(ano=year, id_municipio=municipality,
                        rcl_municipal=matches[0]['valor'] if matches else '',
                        status='encontrada' if matches else 'sem_rcl_no_rreo_6_bimestre',
                        cod_conta=matches[0]['cod_conta'] if matches else '',
                        n_linhas_resposta=len(payload['items']))
        except (requests.RequestException, ValueError, KeyError) as exc:
            error = str(exc)
            time.sleep(1 + attempt * 2)
    return dict(ano=year, id_municipio=municipality, rcl_municipal='',
                status='erro_api', cod_conta='', n_linhas_resposta='', erro=error[:250])


def main():
    years = [int(a) for a in sys.argv[1:]] or list(range(2015, 2022))
    with (OUT / 'populacao_municipal_ibge_2014_2021.csv').open(
            encoding='utf-8-sig', newline='') as handle:
        municipalities = sorted({r['id_municipio'] for r in csv.DictReader(handle)})
    assert len(municipalities) == 853
    for year in years:
        path = OUT / f'rcl_siconfi_mg_{year}.csv'
        if path.exists():
            with path.open(encoding='utf-8-sig', newline='') as handle:
                done = {r['id_municipio']: r for r in csv.DictReader(handle)}
        else:
            done = {}
        todo = [code for code in municipalities if code not in done or done[code]['status'] == 'erro_api']
        print(f'RCL {year}: {len(todo)} consultas pendentes', flush=True)
        with ThreadPoolExecutor(max_workers=8) as pool:
            tasks = {pool.submit(fetch, code, year): code for code in todo}
            for i, task in enumerate(as_completed(tasks), 1):
                row = task.result()
                done[row['id_municipio']] = row
                if i % 50 == 0 or i == len(tasks):
                    fields = ['ano', 'id_municipio', 'rcl_municipal', 'status',
                              'cod_conta', 'n_linhas_resposta', 'erro']
                    with path.open('w', encoding='utf-8-sig', newline='') as handle:
                        writer = csv.DictWriter(handle, fieldnames=fields)
                        writer.writeheader()
                        writer.writerows(done[k] for k in sorted(done))
                    print(f'RCL {year}: {i}/{len(tasks)} novas; {sum(r["status"] == "encontrada" for r in done.values())} encontradas', flush=True)
        assert len(done) == 853


if __name__ == '__main__':
    main()
