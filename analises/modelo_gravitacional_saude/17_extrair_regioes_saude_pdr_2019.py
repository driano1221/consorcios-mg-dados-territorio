"""Extrai os 853 vinculos territoriais do Anexo I do PDR-SUS/MG 2019.

O documento entrou em vigor em outubro de 2019; nao atribui sua configuracao
a 2014-2018. Codigos de 4, 5 e 6 digitos identificam macro, micro e municipio.
"""
import csv
import re
from pathlib import Path

import pdfplumber
import requests

OUT = Path(__file__).resolve().parent / 'outputs'
URL = ('https://www.saude.mg.gov.br/wp-content/uploads/2019/11/'
       'Del-3013-SUBGR_SDCAR_DREA-Ajuste-PDR-versao-CIB-alterada-15.10-a71.pdf')
PDF = OUT / 'pdr_mg_2019_deliberacao_3013_fonte.pdf'


def main():
    if not PDF.exists():
        response = requests.get(URL, timeout=60)
        response.raise_for_status()
        PDF.write_bytes(response.content)
    macro = micro = None
    rows = []
    with pdfplumber.open(PDF) as document:
        assert len(document.pages) == 46
        for page in document.pages[5:30]:
            for line in (page.extract_text() or '').splitlines():
                match = re.match(r'^\s*(31\d{2,4})\s+', line)
                if not match:
                    continue
                code = match.group(1)
                if len(code) == 4:
                    macro = code
                elif len(code) == 5:
                    micro = code
                else:
                    assert macro and micro, f'Municipio sem regiao: {code}'
                    rows.append(dict(codigo_ibge_6=code, macro_saude_2019=macro,
                                     micro_saude_2019=micro))
    assert len(rows) == len({r['codigo_ibge_6'] for r in rows}) == 853
    assert len({r['macro_saude_2019'] for r in rows}) == 12
    assert len({r['micro_saude_2019'] for r in rows}) == 66
    path = OUT / 'regionalizacao_saude_mg_pdr_2019.csv'
    with path.open('w', encoding='utf-8-sig', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(sorted(rows, key=lambda r: r['codigo_ibge_6']))
    print(f'OK: {len(rows)} municipios, 66 microrregioes, 12 macrorregioes.')


if __name__ == '__main__':
    main()
