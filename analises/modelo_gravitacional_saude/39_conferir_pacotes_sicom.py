"""Confere downloads públicos do TCE, sem alterar MIDES, v1 ou estimativas.
Python 39_conferir_pacotes_sicom.py; bibliotecas padrão apenas.
Baixar na UI Dados Abertos > Jurisdicionado > Despesas por município/ano.
O conteúdo do ZIP, e não só o filtro da tela, determina ano e município.
"""
from pathlib import Path
from collections import Counter
from decimal import Decimal as D
from datetime import datetime, timezone
import csv
import hashlib
import io
import json
import shutil
import zipfile

HERE = Path(__file__).resolve().parent
OUT = HERE/'outputs/auditoria_alternativas/busca_historica_2026_09_25'
RAW = OUT/'sicom'
RAW.mkdir(parents=True, exist_ok=True)
SOURCE = 'https://dadosabertos.tce.mg.gov.br/#/public/detalhar-categoria/jurisdicionado/menu/despesa'
CASES = [
    (2018, '3131307', 'Ipatinga', '00853908000148', 'CONSA'),
    (2019, '3131307', 'Ipatinga', '00853908000148', 'CONSA'),
    (2019, '3150158', 'Piedade de Caratinga', '00980259000146', 'MIRECAR'),
    (2019, '3161205', 'São Francisco de Paula', '00079634000181', 'CISMARG'),
    (2014, '3154606', 'Ribeirão das Neves', '05802877000110', 'CISMEP'),
    (2019, '3118403', 'Conselheiro Pena', '00639952000150', 'CISVI'),
    (2018, '3161205', 'São Francisco de Paula', '00079634000181', 'CISMARG'),
]

def read_csv(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))

def save_csv(name, rows):
    assert rows, name
    with (OUT/name).open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)

original=read_csv(HERE/'outputs/auditoria_alternativas/conciliacao_financeira_2026_09_25/transacoes_originais_prioritarias.csv')
cp=read_csv(HERE/'outputs/auditoria_alternativas/cisvi_conselheiro_pena_2019_transacoes.csv')
summary=[]; selected=[]; manifests=[]
for year,code,city,cnpj,term in CASES:
    name=f'SICOM.{year}.{code}.despesa.zip'
    path=RAW/name
    download=Path.home()/'Downloads'/name
    if not path.exists() and download.exists():
        shutil.copy2(download,path)
    if not path.exists():
        manifests.append(dict(arquivo=name,status='nao_baixado',url=SOURCE))
        continue
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None, name
        member=f'{year}.{code}.despesa.pagamento.csv'
        rows=list(csv.DictReader(io.StringIO(z.read(member).decode('utf-8-sig')),delimiter=';'))
    assert rows and {r['num_ano_referencia'] for r in rows}=={str(year)}, name
    # Uma linha é pagamento-fonte. Não eliminar duplicatas por valor/data.
    target=[r for r in rows if r['num_doc_credor']==cnpj]
    other=[r for r in rows if r['num_doc_credor']!=cnpj and term in (r['nom_credor']+' '+r['dsc_pagamento']).upper()]
    total=sum((D(r['vlr_pag_fonte']) for r in target),D(0))
    annulled=sum((D(r['vlr_anu_fonte']) for r in target),D(0))
    prior=[r for r in original if r['id_municipio']==code and r['ano']==str(year)]
    if code=='3118403':
        prior=cp
    matches='nao_comparado'
    if prior:
        left=Counter((r['dat_pagamento'],D(r['vlr_pag_fonte'])) for r in target)
        right=Counter((r['data'].replace('-',''),D(r['valor_final'])) for r in prior)
        assert left==right, (city,year,left-right,right-left)
        matches='datas_valores_e_multiplicidades_iguais'
    for row in target:
        selected.append(dict(ano=str(year),id_municipio=code,municipio=city,
            cnpj=cnpj,arquivo=name,seq_pagamento=row['seq_pagamento'],
            seq_orgao=row['seq_orgao'],cod_orgao=row['cod_orgao'],
            num_empenho=row['num_empenho'],num_ord_pagamento=row['num_ord_pagamento'],
            dat_pagamento=row['dat_pagamento'],nom_credor=row['nom_credor'],
            seq_rsp=row['seq_rsp'],dsc_tipo_pagamento=row['dsc_tipo_pagamento'],
            dsc_fonte_recurso=row['dsc_fonte_recurso'],dsc_pagamento=row['dsc_pagamento'],
            vlr_pag_fonte=row['vlr_pag_fonte'],vlr_anu_fonte=row['vlr_anu_fonte']))
    summary.append(dict(ano=year,id_municipio=code,municipio=city,cnpj=cnpj,
        linhas_arquivo=len(rows),meses=','.join(sorted({r['num_mes_referencia'] for r in rows},key=int)),
        linhas_cnpj=len(target),pago_bruto=str(total),anulacoes=str(annulled),
        mencoes_outro_cnpj=len(other),comparacao_mides=matches))
    manifests.append(dict(arquivo=name,status='baixado',url=SOURCE,sha256=digest,
        bytes=path.stat().st_size,verificado_utc=datetime.now(timezone.utc).isoformat(),
        origem='Download pela interface pública TCE-MG; filtros município/ano; botão despesa',
        membro_pagamentos=member,limite='SICOM pode compartilhar origem com MIDES; não é comprovação bancária independente.'))

save_csv('pagamentos_sicom_prioritarios.csv',selected)
save_csv('resumo_sicom.csv',summary)
(OUT/'manifesto_sicom.json').write_text(json.dumps(manifests,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False,indent=2))
