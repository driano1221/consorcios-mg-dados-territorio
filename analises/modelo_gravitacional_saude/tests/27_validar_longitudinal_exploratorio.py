"""Audita as coortes, decisões anuais, treinos e previsões longitudinais."""
from pathlib import Path
import hashlib
import json
import numpy as np
import pandas as pd
from scipy.special import expit
from sklearn.metrics import average_precision_score, roc_auc_score

HERE=Path(__file__).resolve().parents[1]
OUT=HERE/'outputs/longitudinal_exploratorio'
DT={'id_municipio':str,'cnpj_raiz_8':str}
KEY=['ano','id_municipio','cnpj_raiz_8']
def read(p):return pd.read_csv(p,dtype=DT,low_memory=False)
def close(a,b):np.testing.assert_allclose(a,b,atol=1e-8,rtol=1e-7)

for r in read(OUT/'fontes.csv').itertuples():
    assert hashlib.sha256((HERE/r.arquivo).read_bytes()).hexdigest()==r.sha256
provenance=json.loads((OUT/'fonte_modelos.json').read_text(encoding='utf-8'))
assert hashlib.sha256((HERE/provenance['arquivo']).read_bytes()).hexdigest()==provenance['sha256']
b=read(OUT/'pares_risco.csv.gz')
c=read(OUT/'cobertura_alternativas.csv')
spec=read(OUT/'especificacoes.csv')
samp=read(OUT/'amostras_modelos.csv')
coef=read(OUT/'coeficientes_modelos.csv')
metric=read(OUT/'metricas_modelos.csv')
p=read(OUT/'previsoes_longitudinais.csv.gz')
g=read(HERE/'outputs/base_v1/base_gravitacional_v1.csv')
f=read(HERE/'outputs/base_v1/base_financeira_v1.csv')
folds=read(HERE/'outputs/adesao_financeira/grupos_validacao.csv').set_index('id_municipio')
assert len(b)==260165 and len(spec)==22 and len(samp)==22 and len(metric)==198
assert (spec.fase=='diagnostico_intramunicipal_posterior').sum()==3
assert not b.duplicated(KEY).any()
assert b.ano.between(2015,2021).all()
assert (b.municipios.to_numpy()==folds.loc[b.id_municipio,'municipios'].to_numpy()).all()
assert (b.espacial.to_numpy()==folds.loc[b.id_municipio,'espacial'].to_numpy()).all()
assert (b.ate180min==b.tempo_anterior_min.le(180)).all()
close(b.ordem_tempo,b.groupby(['ano','id_municipio']).tempo_anterior_min.rank(method='min'))
assert (b.cinco_proximos==b.ordem_tempo.le(5)).all()
prior=g[['id_municipio','cnpj_raiz_8','ano','horas_sus_clinicas_soma_registros','tempo_minimo_min']].copy()
prior.ano+=1
q=b[KEY+['horas_anteriores','tempo_anterior_min']].merge(prior,on=KEY,validate='one_to_one')
close(q.horas_anteriores,q.horas_sus_clinicas_soma_registros)
close(q.tempo_anterior_min,q.tempo_minimo_min)
assert b.horas_anteriores.gt(0).all() and b.populacao_anterior.gt(0).all()
f=f.sort_values(['id_municipio','cnpj_raiz_8','ano']).reset_index(drop=True)
prev=f.groupby(['id_municipio','cnpj_raiz_8']).ano.shift(1)
expected=f.merge(prior,on=KEY,how='left',validate='one_to_one')
expected=expected[expected.ano.between(2015,2021)&prev.eq(expected.ano-1)&
                  expected.horas_sus_clinicas_soma_registros.gt(0)]
assert set(map(tuple,expected[KEY].to_numpy()))==set(map(tuple,b[KEY].to_numpy()))
assert len(c)==72 and set(c.versao)=={'original','auditado','estrito'}
tot=c[c.ano.eq(0)].set_index(['versao','regra'])
assert tot.loc[('original','estadual'),'primeiros']==173
assert tot.loc[('auditado','estadual'),'primeiros']==173
assert tot.loc[('auditado','estadual'),'interromperam']==208
assert tot.loc[('auditado','estadual'),'pagamentos']==4660
assert tot.loc[('auditado','ate180min'),'origens_ano_sem_candidato']==354
for version in ('original','auditado','estrito'):
    for rule in ('estadual','ate180min','cinco_proximos'):
        d=b[b[rule]];r=tot.loc[(version,rule)]
        assert r.candidatos==len(d) and r.pagamentos==d[f'pago_{version}'].eq(1).sum()
        for risk,col in [('risco_primeiro','risco_primeiro'),('risco_continuidade','risco_continuidade'),('risco_valor','risco_valor')]:
            if risk=='risco_primeiro': assert r.risco_primeiro==d[f'{col}_{version}'].sum()
            if risk=='risco_continuidade':assert r.risco_continuidade==d[f'{col}_{version}'].sum()
            if risk=='risco_valor':assert r.pagamentos_com_valor==d[f'{col}_{version}'].sum()
neves=b[(b.id_municipio=='3154606')&(b.cnpj_raiz_8=='05802877')&(b.ano==2015)]
if len(neves):
    assert neves.iloc[0].indeterminados_antes_auditado==1
    assert not neves.iloc[0].risco_primeiro_auditado
pena=b[(b.id_municipio=='3118403')&(b.cnpj_raiz_8=='00639952')&(b.ano==2019)]
assert len(pena)==1 and pena.iloc[0].pago_original==1 and np.isnan(pena.iloc[0].pago_auditado)
assert np.isnan(pena.iloc[0].pago_estrito)
sfp=b[(b.id_municipio=='3161205')&(b.cnpj_raiz_8=='00079634')&(b.ano==2019)]
assert len(sfp)==1 and sfp.iloc[0].pago_auditado==sfp.iloc[0].pago_estrito==1

features={'referencia':['log_pop','ano_centrado'],
          'gravitacional':['log_pop','ano_centrado','log_horas','log_tempo'],
          'grav_valor_anterior':['log_pop','ano_centrado','log_horas','log_tempo','log_valor_anterior']}
for floor in (5,15,30):
    features[f'gravitacional_piso{floor}']=['log_pop','ano_centrado','log_horas',f'log_tempo_piso{floor}']
for specrow in spec.itertuples():
    sel=(p.regra==specrow.regra)&(p.versao==specrow.versao)&(
        p.tarefa==specrow.tarefa)&(p.modelo==specrow.modelo)
    d=p[sel].copy()
    risk={'primeiro':'risco_primeiro','interrupcao':'risco_continuidade',
          'valor_positivo':'risco_valor'}[specrow.tarefa]+'_'+specrow.versao
    src=b[b[specrow.regra]&b[risk]]
    assert len(d)==len(src)==samp[(samp.regra==specrow.regra)&(samp.versao==specrow.versao)&
        (samp.tarefa==specrow.tarefa)&(samp.modelo==specrow.modelo)].iloc[0].linhas
    assert set(map(tuple,d[KEY].to_numpy()))==set(map(tuple,src[KEY].to_numpy()))
    d=d.merge(src[KEY+['valor_total','valor_anterior','populacao_anterior',
        'horas_anteriores','tempo_anterior_min',f'pago_{specrow.versao}']],on=KEY,validate='one_to_one')
    assert (d.municipios==folds.loc[d.id_municipio,'municipios'].to_numpy()).all()
    assert (d.espacial==folds.loc[d.id_municipio,'espacial'].to_numpy()).all()
    paid=d[f'pago_{specrow.versao}'].to_numpy()
    y=(np.log(d.valor_total) if specrow.tarefa=='valor_positivo' else
       1-paid if specrow.tarefa=='interrupcao' else paid)
    close(d.y,y)
    xcols=features[specrow.modelo]
    raw={'log_pop':np.log(d.populacao_anterior),'ano_centrado':d.ano-2015,
         'log_horas':np.log(d.horas_anteriores),'log_tempo':np.log1p(d.tempo_anterior_min),
         'log_valor_anterior':np.log1p(d.valor_anterior)}
    for floor in (5,15,30):
        raw[f'log_tempo_piso{floor}']=np.log1p(np.where(
            d.tempo_anterior_min.eq(0),floor,d.tempo_anterior_min))
        assert np.array_equal(raw[f'log_tempo_piso{floor}'][d.tempo_anterior_min.gt(0)],
                              raw['log_tempo'][d.tempo_anterior_min.gt(0)])
    X=np.column_stack([np.ones(len(d))]+[raw[k] for k in xcols])
    binary=specrow.tarefa!='valor_positivo'
    cc=coef[(coef.regra==specrow.regra)&(coef.versao==specrow.versao)&
        (coef.tarefa==specrow.tarefa)&(coef.modelo==specrow.modelo)]
    for scheme in ('amostra_inteira','municipios','espacial','prever_2021'):
        folds_to_check=[0] if scheme=='amostra_inteira' else range(1,6) if scheme in ('municipios','espacial') else [2021]
        for fold in folds_to_check:
            train=np.ones(len(d),dtype=bool) if scheme=='amostra_inteira' else (
                d[scheme].ne(fold).to_numpy() if scheme in ('municipios','espacial') else d.ano.lt(2021).to_numpy())
            test=d[scheme].eq(fold).to_numpy() if scheme in ('municipios','espacial') else d.ano.eq(2021).to_numpy()
            cf=cc[(cc.validacao==scheme)&(cc.fold==fold)].set_index('termo')
            beta=cf.loc[['(Intercept)']+xcols,'coeficiente'].to_numpy()
            prediction=expit(X@beta) if binary else X@beta
            residual=np.asarray(y)-prediction
            assert np.max(np.abs(X[train].T@residual[train]))/train.sum()<1e-7
            assert (cf.treino==train.sum()).all()
            if scheme!='amostra_inteira':
                col='prev_cv' if scheme=='municipios' else 'prev_espacial' if scheme=='espacial' else 'prev_2021'
                close(d.loc[test,col],prediction[test])
                if scheme in ('municipios','espacial'):assert not set(d.id_municipio[train])&set(d.id_municipio[test])
    for scheme,suffix in [('municipios','cv'),('espacial','espacial'),('prever_2021','2021')]:
        ix=np.ones(len(d),dtype=bool) if scheme!='prever_2021' else d.ano.eq(2021).to_numpy()
        for ref,col in [('modelo','prev_'+suffix),('global','ref_global_'+suffix),
                        ('consorcio','ref_consorcio_'+suffix)]:
            m=metric[(metric.regra==specrow.regra)&(metric.versao==specrow.versao)&
                (metric.tarefa==specrow.tarefa)&(metric.modelo==specrow.modelo)&
                (metric.validacao==scheme)&(metric.referencia==ref)].iloc[0]
            yy=np.asarray(y)[ix];q=d.loc[ix,col].to_numpy()
            assert m.linhas==len(yy) and np.isfinite(q).all()
            if binary:
                close(m.brier,np.mean((yy-q)**2))
                close(m.logloss,-np.mean(yy*np.log(q)+(1-yy)*np.log1p(-q)))
                close(m.precisao_media,average_precision_score(yy,q))
                close(m.auc,roc_auc_score(yy,q))
            else:
                close(m.rmse_log,np.sqrt(np.mean((yy-q)**2)))
                close(m.mae_log,np.mean(np.abs(yy-q)))

report={'status':'OK','pares_ano_elegiveis':len(b),'especificacoes':len(spec),
        'treinos_municipais':len(spec)*5,'treinos_espaciais':len(spec)*5,
        'treinos_temporais':len(spec),
        'casos':'Neves 2014 e Pena 2019 indeterminados; São Francisco 2019 positivo',
        'verificacoes':['fontes SHA256','destino e capacidade apenas t-1',
          'perdas das alternativas','riscos e exemplos reais','score de cada treino',
          'previsões e métricas independentes']}
(HERE/'checks/27_longitudinal_exploratorio.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
