"""Valida fontes baixadas, decisões e preservação dos quatro produtos analíticos."""
from pathlib import Path
from decimal import Decimal as D
import csv
import hashlib
import json
import zipfile

HERE=Path(__file__).resolve().parents[1]
OUT=HERE/'outputs/auditoria_alternativas/busca_historica_2026_09_25'
def read(path):
    with path.open(encoding='utf-8-sig',newline='') as f:
        return list(csv.DictReader(f))
def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()
rows=read(OUT/'pagamentos_sicom_prioritarios.csv')
decisions=read(HERE/'evidencias/decisoes_sicom_2026_09_25.csv')
manifest=json.loads((OUT/'manifesto_sicom.json').read_text(encoding='utf-8'))
assert len(decisions)==6 and len(rows)==130
assert all(None not in r and all(v is not None for v in r.values()) for r in decisions)
catalog=read(HERE/'evidencias/fontes_busca_historica_2026_09_25.csv')
assert len(catalog)==29 and len({r['url'] for r in catalog})==29
pdf_manifest=json.loads((OUT/'manifesto.json').read_text(encoding='utf-8'))
assert {r['id'] for r in pdf_manifest}=={r['id'] for r in catalog}
for source in pdf_manifest:
    if source['status']=='baixado':
        assert sha(HERE/source['arquivo'])==source['sha256']
for source in manifest:
    if source['status']=='baixado':
        p=OUT/'sicom'/source['arquivo']
        assert sha(p)==source['sha256']
        with zipfile.ZipFile(p) as z:
            assert z.testzip() is None
            source_rows=list(csv.DictReader(z.read(source['membro_pagamentos']).decode('utf-8-sig').splitlines(),delimiter=';'))
        for r in (r for r in rows if r['arquivo']==source['arquivo']):
            assert any(x['seq_pagamento']==r['seq_pagamento'] and
                       x['num_doc_credor']==r['cnpj'] and
                       x['dsc_pagamento']==r['dsc_pagamento'] and
                       x['vlr_pag_fonte']==r['vlr_pag_fonte'] for x in source_rows)
sfp=[r for r in rows if r['id_municipio']=='3161205' and r['ano']=='2019']
explicit=[r for r in sfp if 'CISMARG' in r['dsc_pagamento']]
assert len(sfp)==55 and sum(D(r['vlr_pag_fonte']) for r in sfp)==D('188969.82')
assert len(explicit)==30 and sum(D(r['vlr_pag_fonte']) for r in explicit)==D('59226.60')
assert all(any(t in r['dsc_pagamento'] for t in ['CISMARG','TRANSPORTE','EXAMES','PROCEDIMENTOS']) for r in sfp)
neves=[r for r in rows if r['id_municipio']=='3154606']
assert len(neves)==2 and sum(D(r['vlr_pag_fonte']) for r in neves)==D('321.16')
assert all('monitoramento' in r['dsc_pagamento'].lower() and 'camara' in r['dsc_pagamento'].lower() for r in neves)
for row in decisions:
    if row['status']=='objetos_contradizem_atribuicao_consorcial':
        assert row['y_original']=='1' and row['y_auditado']=='' and row['usar_como_positivo_validado']=='FALSE'
    if row['valor_mides']=='0':
        assert row['y_auditado']=='' and row['usar_como_positivo_validado']==''
for row in read(HERE/'evidencias/invariantes_nove_pares_2026_09_25.csv'):
    if not row['arquivo'].endswith('.html'):
        assert sha(HERE/row['arquivo'])==row['sha256'], row['arquivo']
summary=read(OUT/'resumo_sicom.csv')
assert {r['id_municipio'] for r in summary if r['linhas_cnpj']=='0'}=={'3131307','3150158'}
assert all(r['meses']=='1,2,3,4,5,6,7,8,9,10,11,12' for r in summary)
report=dict(status='OK',pacotes_baixados=sum(r['status']=='baixado' for r in manifest),
    linhas_prioritarias=len(rows),decisoes=len(decisions),bases_e_estimativas_preservadas=True,
    fontes=manifest,resumo=summary,decisoes_sha256=sha(HERE/'evidencias/decisoes_sicom_2026_09_25.csv'),
    limite='SICOM não é comprovante bancário independente; zeros anuais sem causa encerrada; sem nova validação visual do HTML.')
(HERE/'checks/25_busca_historica.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('OK: seis pacotes; 130 registros priorizados; decisões e invariantes conferidos.')
