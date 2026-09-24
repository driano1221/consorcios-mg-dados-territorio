"""Reestima GLM em SciPy e confere inferencia, validacao e preservacao das fontes."""
from pathlib import Path
import hashlib
import json
import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.special import expit
from sklearn.metrics import average_precision_score, roc_auc_score

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'outputs/adesao_financeira'
DTYPES = {'id_municipio': str, 'cnpj_raiz_8': str}

def read(name):
    return pd.read_csv(OUT / name, dtype=DTYPES)

def close(a, b, atol=1e-8):
    np.testing.assert_allclose(a, b, atol=atol, rtol=1e-7)

p = read('previsoes.csv.gz')
c = read('coeficientes.csv')
fc = read('coeficientes_validacao.csv')
specs = read('especificacoes.csv').set_index('modelo')
metrics = read('validacao.csv')
folds = read('grupos_validacao.csv').set_index('id_municipio')
source = pd.read_csv(ROOT / 'outputs/cenarios_adesao/grade_candidata_cenarios_2019.csv', dtype=DTYPES)
source = source.set_index(['cenario', 'id_municipio', 'cnpj_raiz_8'])
routes = pd.read_csv(ROOT/'outputs/cenarios_adesao/rotas_por_ponto_2019.csv', dtype=DTYPES, low_memory=False)
routes = routes[(routes.cenario=='S1_unidades') & (routes.horas_base>0)].copy()
alternative = {}
for key, ref in [('L05',.5),('L5',5.)]:
    routes[key] = routes.peso_horas*np.log1p(routes.distancia_km/ref)
    alternative[key] = routes.groupby(['id_municipio','cnpj_raiz_8'])[key].sum()
assert len(specs) == 12 and len(folds) == 853
assert not p.duplicated(['modelo', 'validacao', 'id_municipio', 'cnpj_raiz_8']).any()
fits = 0
for (name, scheme), d in p.groupby(['modelo', 'validacao'], sort=False):
    assert d.id_municipio.nunique() == 853
    assert (d.groupby('id_municipio').fold.nunique() == 1).all()
    assert (d.fold.to_numpy() == folds.loc[d.id_municipio, scheme].to_numpy()).all()
    co = c[c.modelo == name].set_index('termo')
    terms = co.index.tolist()
    X = np.column_stack([np.ones(len(d)) if t == '(Intercept)' else d[t] for t in terms])
    y = d.adesao_financeira.to_numpy()
    beta = co.coeficiente.to_numpy()
    fitted = expit(X @ beta)
    close(fitted, d.prob_ajuste)
    assert np.max(np.abs(X.T @ (y - fitted)))/len(d) < 1e-8
    s = specs.loc[name]
    keys = pd.MultiIndex.from_arrays([np.repeat(s.cenario, len(d)), d.id_municipio, d.cnpj_raiz_8])
    original = source.loc[keys]
    close(d.valor_total, original.valor_total)
    close(y, original.adesao_financeira)
    close(d.log_populacao, original.log_populacao)
    close(d.log_horas, original[s.massa])
    if s.impedancia not in ('L05', 'L5', 'minima', 'zero'):
        close(d.impedancia, original[s.impedancia])
    elif s.impedancia in alternative:
        pair_keys = pd.MultiIndex.from_arrays([d.id_municipio,d.cnpj_raiz_8])
        close(d.impedancia, alternative[s.impedancia].loc[pair_keys])
    elif s.impedancia == 'minima':
        close(d.impedancia, np.log1p(original.distancia_min_km))
    else:
        close(d.impedancia, np.where(original.horas_base==0,np.log1p(original.distancia_min_km),
                                    original.impedancia_log_km_horas))
    close(d.mesmo_municipio_destino, original.distancia_min_km == 0)
    if scheme == 'municipios':
        # Algoritmo diferente do IRLS de R, sem inicializar nos coeficientes de R.
        means = X.mean(axis=0); means[0] = 0
        scales = X.std(axis=0); scales[0] = 1
        Z = (X - means) / scales
        b0 = np.zeros(X.shape[1]); b0[0] = np.log(y.mean() / (1-y.mean()))
        def loss(b):
            eta = Z @ b
            return np.mean(np.logaddexp(0, eta) - y*eta)
        def grad(b):
            return Z.T @ (expit(Z @ b)-y)/len(y)
        def hess(b):
            q = expit(Z @ b)
            return (Z.T * (q*(1-q))) @ Z/len(y)
        r = minimize(loss, b0, jac=grad, hess=hess, method='trust-exact', options={'gtol': 1e-11})
        assert np.max(np.abs(grad(r.x))) < 1e-8
        b = r.x/scales; b[0] -= np.sum(means*b)
        close(b, beta, atol=3e-5)
        fits += 1
        # Reconstroi sandwich HC1 municipio + consorcio - HC0 dos pares unicos.
        scores = X * (y-fitted)[:, None]
        meat = np.zeros((X.shape[1], X.shape[1]))
        for field in ('id_municipio', 'cnpj_raiz_8'):
            labels, unique = pd.factorize(d[field])
            sums = np.zeros((len(unique), X.shape[1]))
            np.add.at(sums, labels, scores)
            meat += len(unique)/(len(unique)-1) * (sums.T @ sums)
        meat *= (len(d)-1)/(len(d)-X.shape[1])
        meat -= scores.T @ scores
        bread = np.linalg.inv((X.T * (fitted*(1-fitted))) @ X)
        se = np.sqrt(np.diag(bread @ meat @ bread))
        close(se, co.erro_cluster_duplo, atol=1e-6)
    for k in range(1, 6):
        test = d.fold.to_numpy() == k
        train = ~test
        assert not (set(d.id_municipio[test]) & set(d.id_municipio[train]))
        cv = fc[(fc.modelo == name) & (fc.validacao == scheme) & (fc.fold == k)].set_index('termo')
        b = cv.loc[terms, 'coeficiente'].to_numpy()
        # A solucao de cada fold deve satisfazer o score APENAS no treino.
        assert np.max(np.abs(X[train].T @ (y[train]-expit(X[train] @ b))))/train.sum() < 1e-8
        close(expit(X[test] @ b), d.prob_validacao[test])
        close(d.prob_prevalencia[test], y[train].mean())
        rates = d.loc[train].groupby('cnpj_raiz_8').adesao_financeira.agg(['sum', 'count'])
        rates['p'] = (rates['sum']+.5)/(rates['count']+1)
        close(d.prob_frequencia_consorcio[test], rates.loc[d.cnpj_raiz_8[test], 'p'])
    for ref, field in [('modelo','prob_validacao'),('prevalencia','prob_prevalencia'),
                       ('frequencia_consorcio','prob_frequencia_consorcio')]:
        for k in range(6):
            use = np.ones(len(d), dtype=bool) if k == 0 else d.fold.to_numpy() == k
            yy = y[use]; q = d[field].to_numpy()[use]
            assert ((q > 0) & (q < 1)).all()
            expected = metrics[(metrics.modelo == name) & (metrics.validacao == scheme) &
                               (metrics.referencia == ref) & (metrics.fold == k)].iloc[0]
            close(expected.logloss, -np.mean(yy*np.log(q)+(1-yy)*np.log1p(-q)))
            close(expected.brier, np.mean((yy-q)**2))
            close(expected.average_precision, average_precision_score(yy,q))
            close(expected.roc_auc, roc_auc_score(yy,q))

assert fits == 12
example = p[(p.id_municipio=='3130101') & (p.cnpj_raiz_8=='05802877') &
            (p.modelo=='clinicas53') & (p.validacao=='municipios')]
assert len(example) == 1 and example.iloc[0].adesao_financeira == 1
close(example.iloc[0].valor_total,4740790.51)
close(example.iloc[0].horas_base,1651)
for _, r in read('fontes.csv').iterrows():
    assert hashlib.sha256((ROOT/r.arquivo).read_bytes()).hexdigest() == r.sha256
for _, r in read('manifesto_produtos.csv').iterrows():
    assert hashlib.sha256((OUT/r.arquivo).read_bytes()).hexdigest() == r.sha256
report = dict(status='OK',modelos_reestimados_scipy=fits,linhas_previsoes=len(p),
    checagens=['fontes e produtos SHA256','desfecho e valores iguais a preparacao',
               'coeficientes IRLS versus trust-exact','erros agrupados em duas dimensoes',
               'municipios sem vazamento entre treino e teste','score de cada ajuste no treino',
               'previsoes e referencias refeitas','metricas conferidas com sklearn',
               'exemplo Igarape CISMEP'])
(ROOT/'checks/20_adesao_financeira.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
