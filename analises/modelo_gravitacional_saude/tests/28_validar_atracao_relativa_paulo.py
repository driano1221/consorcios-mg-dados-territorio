"""Audita amostra, folds, denominador e previsoes do ensaio de Paulo."""
from pathlib import Path
import hashlib
import json

import numpy as np
import pandas as pd
from scipy.special import expit
from sklearn.metrics import average_precision_score


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "outputs/atracao_relativa_paulo_2019"
KEY = ["id_municipio", "cnpj_raiz_8"]
DT = {"id_municipio": str, "cnpj_raiz_8": str}


def read(path):
    return pd.read_csv(path, dtype=DT, low_memory=False)


for source in read(OUT / "fontes.csv").itertuples():
    assert hashlib.sha256((ROOT / source.arquivo).read_bytes()).hexdigest() == source.sha256

pred = read(OUT / "previsoes.csv.gz")
metrics = read(OUT / "metricas_mesma_amostra.csv")
by_fold = read(OUT / "metricas_por_fold.csv")
paired = read(OUT / "ganhos_pareados.csv")
parameters = read(OUT / "parametros_validacao.csv")
routes = read(ROOT / "outputs/cenarios_adesao/rotas_por_ponto_2019.csv")
grade = read(ROOT / "outputs/cenarios_adesao/grade_candidata_cenarios_2019.csv")
old = read(ROOT / "outputs/auditoria_sicom_modelo_2019/previsoes_comparacao.csv.gz")
folds = read(ROOT / "outputs/adesao_financeira/grupos_validacao.csv")

assert len(metrics) == 24 and len(by_fold) == 120 and len(parameters) == 80
assert len(paired) == 16 and paired.limite_025.gt(0).all()
for measure, better_high in (("brier", False), ("logloss", False),
                             ("precisao_media", True)):
    comparison = metrics.pivot(index=["modelo", "validacao"],
                               columns="especificacao", values=measure)
    assert ((comparison.atracao_relativa > comparison.atual) if better_high else
            (comparison.atracao_relativa < comparison.atual)).all()
fold_comparison = by_fold.pivot(index=["modelo", "validacao", "fold"],
                                columns="especificacao", values="brier")
assert (fold_comparison.atracao_relativa < fold_comparison.atual).all()
assert set(pred.modelo) == {"clinicas53", "sedes53", "sedes62", "misto62"}
assert set(pred.validacao) == {"municipios", "espacial"}
assert not pred.duplicated(["modelo", "validacao"] + KEY).any()
assert (pred.resposta == pred.valor_total.gt(0)).all()
assert pred[["prob_auditada", "prob_propria_unidades", "prob_paulo_binaria",
             "atracao_relativa"]].ge(0).all().all()
assert pred[["prob_auditada", "prob_propria_unidades", "prob_paulo_binaria",
             "atracao_relativa"]].le(1).all().all()
assert pred.atracao_relativa.between(1e-14, 1-1e-14).all()
assert parameters.convergiu.all()
assert parameters.diferenca_inicios.max() < 1e-8
assert parameters.beta_horas.ge(0).all() and parameters.gamma_distancia.ge(0).all()
assert parameters.loc[parameters.especificacao == "atracao_relativa", "peso_relativo"].ge(0).all()
for p in parameters.itertuples():
    assert p.treino_municipios == (folds[p.validacao] != p.fold).sum()
    excluded_in_training = int(folds.set_index("id_municipio").loc["3118403", p.validacao] != p.fold)
    nroots = 53 if p.modelo.endswith("53") else 62
    assert p.treino_pares == p.treino_municipios * nroots - excluded_in_training

joined = pred.merge(old[["modelo", "validacao"] + KEY + ["fold", "prob_auditada",
                       "adesao_financeira", "valor_total"]],
                    on=["modelo", "validacao"] + KEY, validate="one_to_one", suffixes=("", "_old"))
assert len(joined) == len(pred)
for col in ("fold", "prob_auditada", "valor_total"):
    np.testing.assert_allclose(joined[col], joined[col + "_old"], atol=1e-12)
np.testing.assert_allclose(joined.resposta, joined.adesao_financeira)

cases = {"clinicas53": ("S1_unidades", "amostra_comum", 53, 45208, 770),
         "sedes53": ("S2_sedes", "amostra_comum", 53, 45208, 770),
         "sedes62": ("S2_sedes", "pre_elegivel_horas_positivas", 62, 52885, 1298),
         "misto62": ("S3_misto", "pre_elegivel_horas_positivas", 62, 52885, 1298)}
for (model, validation), q in pred.groupby(["modelo", "validacao"]):
    scenario, rule, nroots, nrows, npaid = cases[model]
    assert len(q) == nrows and q.resposta.sum() == npaid
    assert q.id_municipio.nunique() == 853 and q.cnpj_raiz_8.nunique() == nroots
    assert not ((q.id_municipio == "3118403") & (q.cnpj_raiz_8 == "00639952")).any()
    fold_map = folds.set_index("id_municipio")[validation]
    assert (q.fold.to_numpy() == fold_map.loc[q.id_municipio].to_numpy()).all()
    share_sums = q.groupby("id_municipio").atracao_relativa.sum()
    np.testing.assert_allclose(share_sums.drop("3118403"), 1, atol=1e-12)
    assert 0 < share_sums.loc["3118403"] < 1
    assert (q.groupby("id_municipio").prob_paulo_binaria.sum() > 1).any()
    raw = grade[(grade.cenario == scenario) & grade[rule]]
    assert len(raw) == nroots * 853
    original_keys = set(zip(raw.id_municipio, raw.cnpj_raiz_8))
    output_keys = set(zip(q.id_municipio, q.cnpj_raiz_8))
    assert original_keys - output_keys == {("3118403", "00639952")}
    for label, col in (("atual", "prob_auditada"),
                       ("atracao_propria_unidades", "prob_propria_unidades"),
                       ("atracao_relativa", "prob_paulo_binaria")):
        for fold in [None, 1, 2, 3, 4, 5]:
            subset = q if fold is None else q[q.fold == fold]
            row = (metrics if fold is None else by_fold)
            row = row[(row.modelo == model) & (row.validacao == validation) &
                      (row.especificacao == label)]
            if fold is not None:
                row = row[row.fold == fold]
            assert len(row) == 1
            row = row.iloc[0]
            y, p = subset.resposta.to_numpy(), subset[col].to_numpy()
            np.testing.assert_allclose(row.brier, np.mean((y-p)**2), atol=1e-12)
            np.testing.assert_allclose(row.logloss,
                -np.mean(y*np.log(np.clip(p, 1e-15, 1-1e-15)) +
                         (1-y)*np.log1p(-np.clip(p, 1e-15, 1-1e-15))), atol=1e-12)
            np.testing.assert_allclose(row.precisao_media, average_precision_score(y, p), atol=1e-12)
            assert row.n == len(subset) and row.positivos == y.sum()

    # Refaz a soma de atracao de TODOS os candidatos para uma origem real.
    sample = q[q.municipio == "Igarapé"].sort_values("cnpj_raiz_8")
    assert len(sample) == nroots
    fold = int(sample.fold.iloc[0])
    params = parameters[(parameters.modelo == model) & (parameters.validacao == validation) &
                        (parameters.fold == fold) & (parameters.especificacao == "atracao_relativa")].iloc[0]
    selected_routes = routes[(routes.cenario == scenario) &
                             (routes.id_municipio == sample.id_municipio.iloc[0])]
    selected_routes = selected_routes[selected_routes.cnpj_raiz_8.isin(sample.cnpj_raiz_8)]
    spatial = selected_routes.assign(
        contribution=selected_routes.peso_horas /
        (1 + selected_routes.distancia_km)**params.gamma_distancia
    ).groupby("cnpj_raiz_8").contribution.sum()
    attraction = (sample.horas_base.to_numpy()**params.beta_horas *
                  spatial.loc[sample.cnpj_raiz_8].to_numpy())
    share = attraction / attraction.sum()
    np.testing.assert_allclose(sample.atracao_relativa, share, rtol=1e-10)
    np.testing.assert_allclose(sample.prob_paulo_binaria,
        expit(params.intercepto + params.beta_pop*(np.log(
            grade.loc[grade.id_municipio == sample.id_municipio.iloc[0], "populacao_ibge"].iloc[0])-10)
            + params.peso_relativo*np.log(share/(1-share))), rtol=1e-10)

comparison = metrics.pivot(index=["modelo", "validacao"], columns="especificacao",
                           values=["brier", "logloss", "precisao_media"])
comparison.columns = [f"{measure}_{spec}" for measure, spec in comparison.columns]
report = {"status": "OK", "pares_validacao": int(len(pred)), "ajustes": len(parameters),
          "modelos": 4, "especificacoes": 3, "validacoes": 2,
          "checagens": "Fontes, decisao indeterminada, folds, mesmos pares, metricas, gradiente e denominador por ponto em Igarape",
          "metricas": comparison.reset_index().to_dict(orient="records")}
(ROOT / "checks/28_atracao_relativa_paulo.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({key: value for key, value in report.items() if key != "metricas"},
                 ensure_ascii=False))
