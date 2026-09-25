"""Baixa apenas URLs catalogadas; guarda originais, SHA256 e texto por página.
Executar na pasta do modelo: python 38_coletar_documentos_historicos.py
Não altera dados financeiros nem infere pagamentos pela ausência de texto.
"""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import csv
import hashlib
import json
import requests
import fitz

HERE = Path(__file__).resolve().parent
DEST = HERE/'outputs/auditoria_alternativas/busca_historica_2026_09_25'
DEST.mkdir(parents=True, exist_ok=True)
with (HERE/'evidencias/fontes_busca_historica_2026_09_25.csv').open(encoding='utf-8-sig',newline='') as f:
    sources = list(csv.DictReader(f))
assert len({r['id'] for r in sources}) == len(sources)

def collect(row):
    result = dict(row)
    path = DEST/(row['id']+'.pdf')
    try:
        if not path.exists():
            response = requests.get(row['url'], timeout=45)
            response.raise_for_status()
            if not response.content.startswith(b'%PDF'):
                raise ValueError('Resposta não é PDF: '+response.headers.get('Content-Type',''))
            path.write_bytes(response.content)
        data=path.read_bytes()
        with fitz.open(path) as doc:
            pages=[{'pagina_pdf':i+1,'texto':p.get_text()} for i,p in enumerate(doc)]
        (DEST/(row['id']+'.json')).write_text(json.dumps(pages,ensure_ascii=False,indent=2),encoding='utf-8')
        result.update(status='baixado',arquivo=path.relative_to(HERE).as_posix(),
                      sha256=hashlib.sha256(data).hexdigest(),bytes=len(data),paginas=len(pages),
                      consulta_utc=datetime.now(timezone.utc).isoformat())
        terms=['consórc','consorc','cismirecar','consaude','consaúde','cismarg','sometal','emive','137.077']
        hits=[p for p in pages if any(t in p['texto'].lower() for t in terms)]
        print(json.dumps({'id':row['id'],'paginas':len(pages),'paginas_com_termos':[p['pagina_pdf'] for p in hits]},ensure_ascii=False),flush=True)
    except Exception as e:
        result.update(status='falha',erro=str(e))
        print(row['id']+': '+str(e),flush=True)
    return result

with ThreadPoolExecutor(max_workers=3) as pool:
    results=list(pool.map(collect,sources))
(DEST/'manifesto.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Documentos baixados:',sum(r['status']=='baixado' for r in results),'/',len(results))
