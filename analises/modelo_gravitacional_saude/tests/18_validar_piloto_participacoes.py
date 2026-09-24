"""Verificacao independente do piloto R usando CSVs v1 e NumPy/SciPy.

Executar da raiz ou desta pasta. Nao estima alternativas novas nem altera fontes.
"""
from pathlib import Path
from collections import Counter
import csv
import hashlib
import json
import math
import re
import numpy as np
from scipy.optimize import minimize
from scipy.special import logsumexp, softmax

HERE = Path(__file__).resolve().parents[1]
OUT = HERE / 'outputs/piloto_participacoes'

def read(path):
    with path.open(encoding='utf-8-sig', newline='') as handle:
        return list(csv.DictReader(handle))

rows = read(OUT / 'base_estimacao_2019.csv')
source = { (r['id_municipio'], r['cnpj_raiz_8']): r
          for r in read(HERE / 'outputs/base_v1/base_gravitacional_v1.csv') if r['ano']=='2019'}
assert len(rows)==37962 and len(source)==46062
keys = [(r['id_municipio'],r['cnpj_raiz_8']) for r in rows]
assert len(keys)==len(set(keys))
for r,key in zip(rows,keys):
    s=source[key]
    for k,value in s.items():
        try: assert math.isclose(float(value),float(r[k]),rel_tol=1e-12,abs_tol=1e-7)
        except ValueError: assert value==r[k], (key,k)

n,j=703,54
array=lambda key:np.array([float(r[key]) for r in rows]).reshape(n,j)
y=array('participacao'); money=array('valor_total'); total=money.sum(axis=1)
assert (total>0).all() and (money>0).sum()==781
np.testing.assert_allclose(y,money/total[:,None],atol=1e-13)
np.testing.assert_allclose(array('total_direto'),np.repeat(total[:,None],j,axis=1),atol=1e-6)
assert Counter((money>0).sum(axis=1))=={1:628,2:72,3:3}
x=np.stack([np.log1p(array('profissionais_sus_clinicos_soma_unidades')),-array('tempo_minimo_min')/60],axis=2)
coeff=read(OUT/'coeficientes.csv')
b=np.array([float(next(r['coeficiente'] for r in coeff if r['modelo']=='profissionais_tempo' and r['termo']==term)) for term in ['capacidade','tempo']])
def objective(beta,x=x,y=y):
    v=x@beta
    return np.mean(logsumexp(v,axis=1)-(y*v).sum(axis=1))
independent=minimize(objective,np.array([1.,1.]),method='BFGS',options={'gtol':1e-7})
np.testing.assert_allclose(independent.x,b,atol=2e-5)
np.testing.assert_allclose(softmax(x@b,axis=1),array('previsto_ajuste'),atol=2e-12)
# Teste substantivo de ausencia de vazamento: o coeficiente salvo deve resolver
# as equacoes do treino, e suas previsoes devem corresponder ao grupo omitido.
fold_coeff=read(OUT/'coeficientes_validacao.csv')
metrics=read(OUT/'validacao.csv')
for scheme,fold_key,pred_key in [('municipios','fold','previsto_validacao'),('espacial','bloco_espacial','previsto_espacial')]:
    folds=array(fold_key)[:,0]
    assert set(folds)=={1,2,3,4,5}
    expected=np.empty_like(y)
    for k in range(1,6):
        bc=np.array([float(next(r['coeficiente'] for r in fold_coeff if r['validacao']==scheme and r['modelo']=='profissionais_tempo' and r['fold']==str(k) and r['termo']==term)) for term in ['capacidade','tempo']])
        train=folds!=k; test=~train
        delta=softmax(x[train]@bc,axis=1)-y[train]
        grad=(delta[:,:,None]*x[train]).sum(axis=1).mean(axis=0)
        assert np.max(np.abs(grad))<1e-5
        expected[test]=softmax(x[test]@bc,axis=1)
    np.testing.assert_allclose(expected,array(pred_key),atol=2e-12)
    np.testing.assert_allclose(expected.sum(axis=1),1,atol=1e-12)
    m=next(r for r in metrics if r['validacao']==scheme and r['modelo']=='profissionais_tempo')
    computed=[-np.mean(np.sum(y*np.log(expected),axis=1)),50*np.abs(y-expected).sum(axis=1).mean(),100*np.mean(y.argmax(axis=1)==expected.argmax(axis=1))]
    np.testing.assert_allclose(computed,[float(m[k]) for k in ['entropia','distancia_total_pct','acerto_principal_pct']],atol=1e-10)

selection=read(OUT/'selecao_consorcios_2019.csv')
assert Counter(r['destino_v1'] for r in selection)=={'financeira_e_gravitacional':54,'somente_financeira_sem_polo_direto':19,'fora_escopo_nucleo_saude':21,'fora_antes_abertura':3}
payload=json.loads((OUT/'piloto.json').read_text(encoding='utf-8'))
html=(HERE/'outputs/visuais_v1/index.html').read_text(encoding='utf-8')
embedded=json.loads(re.search(r'<script type="application/json" id="data">(.*?)</script>',html,re.S)[1])
assert embedded['model']==payload, 'HTML desatualizado; executar script 28'
assert html.count('id="modelo"')==1 and 'id="model-calculation"' in html
assert len(payload['municipios'])==n and len(payload['consorcios'])==j
for i,mun in enumerate(payload['municipios']):
    # Municipio exportado vem ordenado pela mesma chave, nao por rotulo.
    raw=payload['linhas'][mun['id_municipio']]
    assert len(raw)==54
    np.testing.assert_allclose([r[5] for r in raw],y[i],atol=1e-11)
    np.testing.assert_allclose([r[7] for r in raw],array('previsto_validacao')[i],atol=1e-11)
for r in read(OUT/'fontes.csv'):
    assert hashlib.sha256((HERE/r['arquivo']).read_bytes()).hexdigest()==r['sha256']
assert all(m['acerto_principal_pct'] is None for m in payload['validacao'] if m['modelo']=='uniforme')
report={'status':'OK','municipios':n,'consorcios':j,'linhas':len(rows),'positivos':781,'zeros':37181,
 'coeficientes_R':b.tolist(),'coeficientes_scipy':independent.x.tolist(),
 'verificado':'Celulas originais preservadas; participacoes, selecao, softmax e metricas conciliadas; otimizacao independente; gradiente do treino e previsoes dos 10 grupos conferidos; hashes intactos.'}
(HERE/'checks/18_piloto_participacoes.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
