"""Confere a decisão documental, amostra constante e os 40 treinos auditados."""
from pathlib import Path
import hashlib
import json
import numpy as np
import pandas as pd
from scipy.special import expit
from sklearn.metrics import average_precision_score, roc_auc_score

HERE = Path(__file__).resolve().parents[1]
OUT = HERE / 'outputs/auditoria_sicom_modelo_2019'
DT = {'id_municipio': str, 'cnpj_raiz_8': str, 'cnpj': str}
KEY = ['id_municipio', 'cnpj_raiz_8']
TERMS = ['(Intercept)', 'log_populacao', 'log_horas_positivas', 'impedancia_log_km_horas']

def read(path):
    return pd.read_csv(path, dtype=DT, low_memory=False)

for r in read(OUT/'fontes.csv').itertuples():
    assert hashlib.sha256((HERE/r.arquivo).read_bytes()).hexdigest() == r.sha256

dec = read(HERE/'evidencias/decisoes_sicom_2026_09_25.csv')
assert len(dec) == 6
assert set(dec.loc[dec.status == 'objetos_contradizem_atribuicao_consorcial', 'ano']) == {2014, 2019}
sample = read(OUT/'amostras.csv').set_index('modelo')
pred = read(OUT/'previsoes_comparacao.csv.gz')
coef = read(OUT/'coeficientes_validacao.csv')
full_coef = read(OUT/'coeficientes.csv')
metric = read(OUT/'validacao_mesma_amostra.csv')
grade = read(HERE/'outputs/cenarios_adesao/grade_candidata_cenarios_2019.csv')
prior = read(HERE/'outputs/adesao_financeira/previsoes.csv.gz')
folds = read(HERE/'outputs/adesao_financeira/grupos_validacao.csv').set_index('id_municipio')
assert len(sample) == 4 and len(metric) == 16 and len(coef) == 160
assert len(full_coef) == 16 and not full_coef.isna().any().any()
np.testing.assert_allclose(full_coef.coeficiente_auditado-full_coef.coeficiente_original,
                           full_coef.diferenca)
assert set(pred.modelo) == set(sample.index)
assert not pred.duplicated(['modelo', 'validacao']+KEY).any()

fits = 0
for (model, scheme), d in pred.groupby(['modelo', 'validacao'], sort=False):
    original = prior[(prior.modelo == model) & (prior.validacao == scheme)]
    src = grade[grade.cenario == ('S1_unidades' if model == 'clinicas53' else
                                   'S3_misto' if model == 'misto62' else 'S2_sedes')]
    src = src[src.amostra_comum if model.endswith('53') else src.pre_elegivel_horas_positivas]
    assert len(original) == len(src) == sample.loc[model, 'pares_original']
    assert len(d) == len(original)-1 == sample.loc[model, 'pares_auditado']
    assert d.adesao_financeira.sum() == original.adesao_financeira.sum()-1
    assert set(zip(original.id_municipio, original.cnpj_raiz_8))-set(zip(d.id_municipio,d.cnpj_raiz_8)) == {
        ('3118403','00639952')}
    sfp = d[(d.id_municipio == '3161205') & (d.cnpj_raiz_8 == '00079634')]
    assert len(sfp) == 1 and sfp.iloc[0].adesao_financeira == 1
    assert abs(sfp.iloc[0].valor_total-188969.82) < .01
    assert (d.fold.to_numpy() == folds.loc[d.id_municipio,scheme].to_numpy()).all()
    from_original = d[KEY+['prob_original']].merge(original[KEY+['prob_validacao']],
        on=KEY,validate='one_to_one')
    np.testing.assert_allclose(from_original.prob_original,from_original.prob_validacao,atol=1e-12)
    from_source = d[KEY+['adesao_financeira','valor_total']].merge(
        src[KEY+['adesao_financeira','valor_total']],on=KEY,validate='one_to_one',suffixes=('_a','_f'))
    np.testing.assert_allclose(from_source.adesao_financeira_a,from_source.adesao_financeira_f)
    np.testing.assert_allclose(from_source.valor_total_a,from_source.valor_total_f)
    X = np.column_stack((np.ones(len(d)),d[TERMS[1:]].to_numpy()))
    y = d.adesao_financeira.to_numpy()
    for k in range(1,6):
        test = d.fold.to_numpy() == k
        train = ~test
        assert not set(d.id_municipio[test]) & set(d.id_municipio[train])
        cc = coef[(coef.modelo == model) & (coef.validacao == scheme) & (coef.fold == k)].set_index('termo')
        b = cc.loc[TERMS,'coeficiente'].to_numpy()
        assert (cc.n_treino == train.sum()).all()
        assert (cc.positivos_treino == y[train].sum()).all()
        assert np.max(np.abs(X[train].T @ (y[train]-expit(X[train]@b))))/train.sum() < 1e-8
        np.testing.assert_allclose(d.loc[test,'prob_auditada'],expit(X[test]@b),atol=1e-8)
        fits += 1
    for version, field in [('original_mesma_amostra','prob_original'),('auditado','prob_auditada')]:
        q = d[field].to_numpy()
        m = metric[(metric.modelo == model) & (metric.validacao == scheme) & (metric.versao == version)].iloc[0]
        assert m.pares == len(d) and m.positivos == y.sum()
        np.testing.assert_allclose(m.brier,np.mean((y-q)**2))
        np.testing.assert_allclose(m.logloss,-np.mean(y*np.log(q)+(1-y)*np.log1p(-q)))
        np.testing.assert_allclose(m.average_precision,average_precision_score(y,q))
        np.testing.assert_allclose(m.roc_auc,roc_auc_score(y,q))

assert fits == 40
report = {'status':'OK','modelos':4,'validacoes':2,'treinos_conferidos':fits,
          'decisao':'São Francisco/2019 mantido; Conselheiro Pena/2019 retirado, sem recodificar zero',
          'limite':'Neves/2014 fica para o modelo longitudinal; comprovação bancária independente ausente.'}
(HERE/'checks/26_piloto_auditado_sicom.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
