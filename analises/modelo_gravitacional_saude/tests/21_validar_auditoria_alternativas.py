"""Confere identificadores, escolhas geograficas, folds, ajustes e perdas reais.

Recalcula regras a partir de destinos/regioes e metricas com sklearn.
O score de cada treino verifica que coeficientes vieram apenas daqueles dados.
"""
from pathlib import Path
from unittest.mock import patch
import hashlib
import importlib.util
import json
import numpy as np
import pandas as pd
from scipy.special import expit
from sklearn.metrics import average_precision_score, roc_auc_score

HERE=Path(__file__).resolve().parents[1]
OUT=HERE/'outputs/auditoria_alternativas'
DT={'id_municipio':str,'id_destino':str,'cnpj_raiz_8':str,'cnes':str,
    'ponto_id':str,'codigo_ibge_6':str,'documento_credor':str}
def read(p):return pd.read_csv(p,dtype=DT,low_memory=False)
def close(a,b):np.testing.assert_allclose(a,b,atol=1e-8,rtol=1e-7)

spec=importlib.util.spec_from_file_location('hist',HERE/'09_temporalizar_cnes_historico_saude.py')
h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h)
roots={'00079634'}
assert h.cnpj_root('00.079.634/0001-81',roots)=='00079634'
assert h.cnpj_root('00079634000999',roots) is None
assert h.cnpj_root('00000000000000',roots) is None
assert h.cnpj_root(None,roots) is None
# PF nunca vale como CNPJ proprio, mesmo se o campo tiver digitos de CNPJ valido.
synthetic={'CNES':'1234567','PF_PJ':'1','CPF_CNPJ':'00079634000181','CNPJ_MAN':''}
with patch.object(h,'dbf_rows',return_value=iter([synthetic])):
    assert not h.select_establishments(None,None,roots,{'00079634':{}},{},2019,12)
synthetic['CNPJ_MAN']='00079634000181'
with patch.object(h,'dbf_rows',return_value=iter([synthetic])):
    assert h.select_establishments(None,None,roots,{'00079634':{}},{},2019,12)['1234567']['tipo_vinculo_cnpj']=='cnpj_mantenedora'

a=read(OUT/'identificadores_cnes.csv');u=read(OUT/'unidades_cnes_dezembro_corrigidas.csv')
bad=a[~a.vinculo_valido]
assert len(a)==1942 and len(u)==1926 and len(bad)==16
assert set(bad.cnes)=={'5101034','5254191'} and (bad.pf_pj==1).all() and bad.horas_sus.sum()==0
assert not u.duplicated(['cnpj_raiz_8','ano','cnes']).any()
assert not set(u.cnes)&set(bad.cnes)
for r in u.itertuples():
    assert any(h.cnpj_root(v,{r.cnpj_raiz_8})==r.cnpj_raiz_8 for v in
               (r.cnpj_proprio_cnes,r.cnpj_mantenedora_cnes))
# A unidade legitima em Oliveira nao e apagada por proximidade ou horas zero.
assert ((u.cnes=='6230261') & (u.ano==2019)).sum()==1

g=read(HERE/'outputs/cenarios_adesao/grade_candidata_cenarios_2019.csv')
oldg=read(OUT/'antes_correcao/cenarios_adesao/grade_candidata_cenarios_2019.csv')
keys=['cenario','id_municipio','cnpj_raiz_8']
joined=g.merge(oldg,on=keys,suffixes=('_novo','_antes'),validate='one_to_one')
for col in ['horas_base','valor_total','impedancia_log_km_horas']:
    np.testing.assert_allclose(joined[col+'_novo'],joined[col+'_antes'],equal_nan=True)
changed=joined[(joined.distancia_min_km_novo.fillna(-1)!=joined.distancia_min_km_antes.fillna(-1)) |
               (joined.tempo_minimo_min_novo.fillna(-1)!=joined.tempo_minimo_min_antes.fillna(-1))]
assert set(changed.cnpj_raiz_8)=={'00079634'}
changed[keys+['distancia_min_km_antes','distancia_min_km_novo','tempo_minimo_min_antes',
              'tempo_minimo_min_novo']].to_csv(OUT/'impacto_correcao_rotas_2019.csv',index=False)
co=read(HERE/'outputs/adesao_financeira/coeficientes.csv')
oldco=read(OUT/'antes_correcao/adesao_financeira/coeficientes.csv')
main=['clinicas53','sedes53','sedes62','misto62']
close(co[co.modelo.isin(main)].coeficiente,oldco[oldco.modelo.isin(main)].coeficiente)

finance=read(OUT/'conciliacao_financeira_2019.csv')
assert len(finance)==62269 and (abs(finance.diferenca)<1e-6).all()
assert (finance.n_transacoes==finance.transacoes_fonte).all()
assert not finance.duplicated(['id_municipio','cnpj_raiz_8']).any()
names=read(OUT/'nomes_credores_financeira_v1.csv')
f=read(HERE/'outputs/base_v1/base_financeira_v1.csv')
n=names.groupby(['ano','id_municipio','cnpj_raiz_8']).agg(valor=('valor_total','sum'),n=('n_transacoes','sum')).reset_index()
nf=f.merge(n,how='left',on=['ano','id_municipio','cnpj_raiz_8'],validate='one_to_one')
close(nf.valor_total,nf.valor.fillna(0));close(nf.n_transacoes,nf.n.fillna(0))
conflict=read(OUT/'conflitos_nome_documento.csv')
assert len(conflict)==17 and len(conflict[conflict.ano==2019])==2
assert (conflict.valor_conflitante==conflict.valor_total).all()
assert set(conflict.cnpj_raiz_8)=={'00079634','05802877','00639952'}
bad19=set(zip(conflict.loc[conflict.ano==2019,'id_municipio'],conflict.loc[conflict.ano==2019,'cnpj_raiz_8']))

rules=read(OUT/'regras_por_par.csv')
routes=read(HERE/'outputs/cenarios_adesao/rotas_por_ponto_2019.csv')
reg=read(HERE/'outputs/regionalizacao_saude_mg_pdr_2019.csv').set_index('codigo_ibge_6')
folds=read(HERE/'outputs/adesao_financeira/grupos_validacao.csv').set_index('id_municipio')
pred=read(OUT/'previsoes_territoriais.csv.gz')
coef=read(OUT/'coeficientes_treino_territorial.csv')
metric=read(OUT/'validacao_territorial.csv')
coverage=read(OUT/'cobertura_regras.csv')
lost=read(OUT/'pagamentos_excluidos_por_regra.csv')
state=read(HERE/'outputs/adesao_financeira/previsoes.csv.gz')
assert not pred.duplicated(['modelo','regra','validacao','id_municipio','cnpj_raiz_8']).any()
scenarios={'clinicas53':'S1_unidades','sedes53':'S2_sedes','sedes62':'S2_sedes','misto62':'S3_misto'}
rule_names=['estadual','ate90min','ate120min','ate180min','mesma_macro','mesma_micro','cinco_proximos','sem_conflito_credor']
base_by_model={}
for model,scenario in scenarios.items():
    flag='amostra_comum' if model.endswith('53') else 'pre_elegivel_horas_positivas'
    base=g[(g.cenario==scenario)&g[flag]].copy().set_index(['id_municipio','cnpj_raiz_8'])
    base_by_model[model]=base
    rt=routes[(routes.cenario==scenario)&routes.cnpj_raiz_8.isin(base.index.get_level_values(1))].copy()
    for level in ['macro','micro']:
        col=level+'_saude_2019'
        rt['equal']=rt.id_municipio.str[:6].map(reg[col])==rt.id_destino.str[:6].map(reg[col])
        expected=rt.groupby(['id_municipio','cnpj_raiz_8']).equal.any().reindex(base.index)
        base['mesma_'+level]=expected
    base['estadual']=True
    for limit in [90,120,180]:base[f'ate{limit}min']=base.tempo_minimo_min<=limit
    base['cinco_proximos']=base.groupby(level=0).tempo_minimo_min.rank(method='min')<=5
    base['sem_conflito_credor']=[k not in bad19 for k in base.index]
    saved=rules[rules.modelo==model].set_index(['id_municipio','cnpj_raiz_8']).reindex(base.index)
    for rule in rule_names:
        assert (saved[rule]==base[rule]).all()
        z=base[base[rule]];exc=base[(~base[rule])&(base.adesao_financeira==1)]
        cov=coverage[(coverage.modelo==model)&(coverage.regra==rule)].iloc[0]
        assert cov.pares==len(z) and cov.positivos==z.adesao_financeira.sum()
        assert cov.positivos_excluidos==len(exc) and cov.sem_candidato==853-z.index.get_level_values(0).nunique()
        close(cov.valor_excluido,exc.valor_total.sum());close(cov.fracao_valor,z.valor_total.sum()/base.valor_total.sum())
        ex=lost[(lost.modelo==model)&(lost.regra==rule)].set_index(['id_municipio','cnpj_raiz_8'])
        assert set(ex.index)==set(exc.index)

fits=0
for (model,rule,scheme),d in pred.groupby(['modelo','regra','validacao'],sort=False):
    base=base_by_model[model];expected=base[base[rule]]
    keys=list(zip(d.id_municipio,d.cnpj_raiz_8))
    assert set(keys)==set(expected.index)
    assert (d.fold.to_numpy()==folds.loc[d.id_municipio,scheme].to_numpy()).all()
    y=d.adesao_financeira.to_numpy()
    X=np.column_stack([np.ones(len(d)),d.log_populacao,d.log_horas_positivas,d.impedancia_log_km_horas])
    src=base.loc[keys]
    close(y,src.adesao_financeira);close(d.valor_total,src.valor_total)
    for c in ['log_populacao','log_horas_positivas','impedancia_log_km_horas']:close(d[c],src[c])
    statewide=state[(state.modelo==model)&(state.validacao==scheme)].set_index(['id_municipio','cnpj_raiz_8'])
    close(d.prob_estadual,statewide.loc[keys,'prob_validacao'])
    for k in range(1,6):
        train=d.fold.to_numpy()!=k;test=~train
        assert not set(d.loc[train,'id_municipio'])&set(d.loc[test,'id_municipio'])
        cc=coef[(coef.modelo==model)&(coef.regra==rule)&(coef.validacao==scheme)&(coef.fold==k)]
        beta=cc.set_index('termo').loc[['(Intercept)','log_populacao','log_horas_positivas','impedancia_log_km_horas'],'coeficiente'].to_numpy()
        assert max(abs(X[train].T@(y[train]-expit(X[train]@beta))))/train.sum()<1e-8
        close(d.loc[test,'prob_reajustada'],expit(X[test]@beta))
        close(d.loc[test,'prob_prevalencia'],y[train].mean())
        assert (cc.n_treino==train.sum()).all() and (cc.positivos_treino==y[train].sum()).all()
        fits+=1
    for field in ['prob_estadual','prob_reajustada','prob_prevalencia']:
        for k in range(6):
            ix=np.ones(len(d),dtype=bool) if k==0 else d.fold.to_numpy()==k
            yy=y[ix];q=d.loc[ix,field].to_numpy();qq=np.clip(q,1e-15,1-1e-15)
            m=metric[(metric.modelo==model)&(metric.regra==rule)&(metric.validacao==scheme)&(metric.previsao==field)&(metric.fold==k)].iloc[0]
            close(m.logloss,-np.mean(yy*np.log(qq)+(1-yy)*np.log1p(-qq)))
            close(m.brier,np.mean((yy-q)**2));close(m.average_precision,average_precision_score(yy,q))
            close(m.roc_auc,roc_auc_score(yy,q))
    if rule=='estadual':close(d.prob_estadual,d.prob_reajustada)
assert fits==320
for name in ['fontes_identificadores.csv','fontes_territoriais.csv','fontes_credores.csv']:
    for r in read(OUT/name).itertuples():
        assert hashlib.sha256((HERE/r.arquivo).read_bytes()).hexdigest()==r.sha256
report=dict(status='OK',unidades_ano_conferidas=1942,vinculos_cnes_rejeitados=16,
 pares_financeiros_2019_conciliados=62269,conflitos_credores_2014_2021=17,
 ajustes_treino_verificados=fits,combinacoes_territoriais=28,sensibilidades_documentais=4,
 linhas_previsoes=len(pred),pares_cenario_com_rota_corrigida=len(changed),
 verificacoes=['CPF nao vira CNPJ; mantenedora legitima preservada','regras reconstruidas sem pagamentos',
 'positivos fora das regras listados sem reinclusao forcada','folds por municipio e espaco sem vazamento',
 'score de cada treino e previsoes refeitas','metricas independentes sklearn','fontes SHA256 intactas',
 'quatro modelos principais invariantes a correcao CNES'])
(HERE/'checks/21_auditoria_alternativas.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
