"""Três modelos financeiros exploratórios com escolha anual definida em t-1.

Não infere filiação jurídica ou efeito causal. Executar após o script 41.
"""
from pathlib import Path
import gzip
import hashlib
import json
import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.special import expit
from sklearn.metrics import average_precision_score, roc_auc_score

HERE = Path(__file__).resolve().parent
OUT = HERE / 'outputs/longitudinal_exploratorio'
INPUT = OUT / 'pares_risco.csv.gz'
SOURCE_HASH = hashlib.sha256(INPUT.read_bytes()).hexdigest()
DT = {'id_municipio':str,'cnpj_raiz_8':str}
data = pd.read_csv(INPUT,dtype=DT,low_memory=False)
assert len(data) == 260165 and not data.duplicated(['id_municipio','cnpj_raiz_8','ano']).any()
assert data.ano.between(2015,2021).all()
data['log_pop'] = np.log(data.populacao_anterior)
data['log_horas'] = np.log(data.horas_anteriores)
data['log_tempo'] = np.log1p(data.tempo_anterior_min)
for floor in (5,15,30):
    data[f'log_tempo_piso{floor}'] = np.log1p(np.where(
        data.tempo_anterior_min.eq(0),floor,data.tempo_anterior_min))
data['ano_centrado'] = data.ano-2015
data['log_valor_anterior'] = np.log1p(data.valor_anterior)
FEATURES = {
 'referencia':['log_pop','ano_centrado'],
 'gravitacional':['log_pop','ano_centrado','log_horas','log_tempo'],
 'grav_valor_anterior':['log_pop','ano_centrado','log_horas','log_tempo','log_valor_anterior'],
}
for floor in (5,15,30):
    FEATURES[f'gravitacional_piso{floor}'] = ['log_pop','ano_centrado','log_horas',f'log_tempo_piso{floor}']
TASKS = {'primeiro':'risco_primeiro','interrupcao':'risco_continuidade','valor_positivo':'risco_valor'}
RULES = {'estadual':'estadual','ate180min':'ate180min','cinco_proximos':'cinco_proximos'}

def fit(x,y,binary):
    mu = x.mean(axis=0)
    sd = x.std(axis=0)
    assert np.isfinite(x).all() and (sd > 0).all() and np.isfinite(y).all()
    z = np.column_stack((np.ones(len(x)),(x-mu)/sd))
    if binary:
        assert 0 < y.sum() < len(y)
        def loss(b):
            eta = z@b
            return np.mean(np.logaddexp(0,eta)-y*eta)
        def grad(b):
            return z.T@(expit(z@b)-y)/len(y)
        def hess(b):
            q = expit(z@b)
            return (z.T*(q*(1-q)))@z/len(y)
        b0 = np.zeros(z.shape[1]); b0[0] = np.log(y.mean()/(1-y.mean()))
        result = minimize(loss,b0,jac=grad,hess=hess,method='trust-exact',
                          options={'gtol':1e-10,'maxiter':100})
        assert np.max(np.abs(grad(result.x))) < 1e-8, result.message
        scaled = result.x
    else:
        scaled = np.linalg.lstsq(z,y,rcond=None)[0]
        assert np.max(np.abs(z.T@(y-z@scaled)))/len(y) < 1e-8
    beta = np.r_[scaled[0]-np.sum(mu*scaled[1:]/sd),scaled[1:]/sd]
    return beta

def predict(x,beta,binary):
    eta = beta[0]+x@beta[1:]
    return expit(eta) if binary else eta

def baselines(train,test,binary):
    if binary:
        global_value = (train.y.sum()+.5)/(len(train)+1)
        grouped = train.groupby('cnpj_raiz_8').y.agg(['sum','count'])
        by_entity = (grouped['sum']+.5)/(grouped['count']+1)
    else:
        global_value = train.y.mean()
        by_entity = train.groupby('cnpj_raiz_8').y.mean()
    return np.full(len(test),global_value),test.cnpj_raiz_8.map(by_entity).fillna(global_value).to_numpy()

def metrics(y,p,binary):
    if binary:
        q = np.clip(p,1e-15,1-1e-15)
        return dict(brier=float(np.mean((y-p)**2)),
          logloss=float(-np.mean(y*np.log(q)+(1-y)*np.log1p(-q))),
          precisao_media=float(average_precision_score(y,p)) if 0<y.sum()<len(y) else None,
          auc=float(roc_auc_score(y,p)) if 0<y.sum()<len(y) else None,
          previsto_medio=float(p.mean()))
    return dict(rmse_log=float(np.sqrt(np.mean((y-p)**2))),
                mae_log=float(np.mean(np.abs(y-p))),
                previsto_medio=float(p.mean()))

specs = []
for rule in RULES:
    for version in (['original','auditado','estrito'] if rule=='estadual' else ['auditado']):
        for task in TASKS:
            choices = ['referencia','gravitacional'] if rule=='estadual' and version=='auditado' else ['gravitacional']
            if task=='interrupcao' and rule=='estadual' and version=='auditado':
                choices.append('grav_valor_anterior')
            for model in choices:
                specs.append(dict(regra=rule,versao=version,tarefa=task,modelo=model,
                                  fase='protocolo_inicial' if version!='estrito' else 'sensibilidade_documental_posterior'))
for floor in (5,15,30):
    specs.append(dict(regra='estadual',versao='auditado',tarefa='primeiro',
                      modelo=f'gravitacional_piso{floor}',fase='diagnostico_intramunicipal_posterior'))
assert len(specs)==22

samples=[]; coefs=[]; scores=[]
pred_path=OUT/'previsoes_longitudinais.csv.gz'
with gzip.open(pred_path,'wt',encoding='utf-8',newline='') as file:
  for i,spec in enumerate(specs):
    rule,version,task,model = (spec[k] for k in ('regra','versao','tarefa','modelo'))
    risk = TASKS[task]+'_'+version
    d = data.loc[data[rule] & data[risk],
        ['id_municipio','cnpj_raiz_8','ano','municipios','espacial','valor_total']+FEATURES[model]+[f'pago_{version}']].copy()
    d['y'] = (np.log(d.valor_total) if task=='valor_positivo' else
              1-d[f'pago_{version}'] if task=='interrupcao' else d[f'pago_{version}'])
    binary = task!='valor_positivo'
    assert d.y.notna().all() and len(d)>1000
    if binary: assert 0<d.y.sum()<len(d) and d.y.isin([0,1]).all()
    X=d[FEATURES[model]].to_numpy(dtype=float)
    y=d.y.to_numpy(dtype=float)
    samples.append(dict(**spec,linhas=len(d),eventos=int(y.sum()) if binary else len(d),
                        municipios=d.id_municipio.nunique(),consorcios=d.cnpj_raiz_8.nunique(),
                        valor_nominal=float(d.valor_total.sum())))
    full=fit(X,y,binary)
    for term,b in zip(['(Intercept)']+FEATURES[model],full):
        coefs.append(dict(**spec,validacao='amostra_inteira',fold=0,termo=term,
                          coeficiente=float(b),treino=len(d),eventos_treino=int(y.sum()) if binary else len(d)))
    for suffix in ('cv','espacial'):
        d['prev_'+suffix]=np.nan;d['ref_global_'+suffix]=np.nan;d['ref_consorcio_'+suffix]=np.nan
    d['prev_2021']=np.nan;d['ref_global_2021']=np.nan;d['ref_consorcio_2021']=np.nan
    for scheme,suffix in [('municipios','cv'),('espacial','espacial')]:
        for fold in range(1,6):
            test=d[scheme].eq(fold).to_numpy();train=~test
            assert not set(d.id_municipio[test]) & set(d.id_municipio[train])
            b=fit(X[train],y[train],binary)
            d.loc[test,'prev_'+suffix]=predict(X[test],b,binary)
            global_p,entity_p=baselines(d.iloc[np.where(train)[0]],d.iloc[np.where(test)[0]],binary)
            d.loc[test,'ref_global_'+suffix]=global_p;d.loc[test,'ref_consorcio_'+suffix]=entity_p
            for term,v in zip(['(Intercept)']+FEATURES[model],b):
                coefs.append(dict(**spec,validacao=scheme,fold=fold,termo=term,
                                  coeficiente=float(v),treino=int(train.sum()),
                                  eventos_treino=int(y[train].sum()) if binary else int(train.sum())))
    train=d.ano.lt(2021).to_numpy();test=~train
    assert test.sum()>0 and train.sum()>0 and d.loc[test,'ano'].eq(2021).all()
    b=fit(X[train],y[train],binary)
    d.loc[test,'prev_2021']=predict(X[test],b,binary)
    global_p,entity_p=baselines(d.iloc[np.where(train)[0]],d.iloc[np.where(test)[0]],binary)
    d.loc[test,'ref_global_2021']=global_p;d.loc[test,'ref_consorcio_2021']=entity_p
    for term,v in zip(['(Intercept)']+FEATURES[model],b):
        coefs.append(dict(**spec,validacao='prever_2021',fold=2021,termo=term,
                          coeficiente=float(v),treino=int(train.sum()),
                          eventos_treino=int(y[train].sum()) if binary else int(train.sum())))
    for scheme,ix,suffix in [('municipios',np.ones(len(d),dtype=bool),'cv'),
                             ('espacial',np.ones(len(d),dtype=bool),'espacial'),
                             ('prever_2021',test,'2021')]:
        for ref,col in [('modelo','prev_'+suffix),('global','ref_global_'+suffix),
                        ('consorcio','ref_consorcio_'+suffix)]:
            q=d.loc[ix,col].to_numpy()
            assert np.isfinite(q).all()
            if binary:assert ((q>0)&(q<1)).all()
            scores.append(dict(**spec,validacao=scheme,referencia=ref,
                linhas=int(ix.sum()),eventos=int(y[ix].sum()) if binary else int(ix.sum()),
                **metrics(y[ix],q,binary)))
    d[['id_municipio','cnpj_raiz_8','ano','municipios','espacial','y','prev_cv','ref_global_cv',
       'ref_consorcio_cv','prev_espacial','ref_global_espacial','ref_consorcio_espacial',
       'prev_2021','ref_global_2021','ref_consorcio_2021']].assign(**spec).to_csv(
           file,index=False,header=i==0)
    print(f'{i+1}/{len(specs)} {rule} {version} {task} {model}: {len(d)} linhas',flush=True)

pd.DataFrame(specs).to_csv(OUT/'especificacoes.csv',index=False)
pd.DataFrame(samples).to_csv(OUT/'amostras_modelos.csv',index=False)
pd.DataFrame(coefs).to_csv(OUT/'coeficientes_modelos.csv',index=False)
pd.DataFrame(scores).to_csv(OUT/'metricas_modelos.csv',index=False)
assert hashlib.sha256(INPUT.read_bytes()).hexdigest()==SOURCE_HASH
(OUT/'fonte_modelos.json').write_text(json.dumps({'arquivo':str(INPUT.relative_to(HERE)),
 'sha256':SOURCE_HASH,'formulas':FEATURES,'especificacoes':len(specs),
 'interpretacao':'Modelos associativos de pagamento, não filiação jurídica ou causalidade.',
 'validacao':['cinco grupos municipais','cinco grupos espaciais sem buffer',
              'treino 2015-2020, teste 2021']},
 ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(pd.DataFrame(scores).query("validacao=='prever_2021' and referencia=='modelo'").to_string(index=False))
