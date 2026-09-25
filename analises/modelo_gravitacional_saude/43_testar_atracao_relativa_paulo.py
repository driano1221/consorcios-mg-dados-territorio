"""Compara atração relativa com o logit binário auditado de 2019.

Executar nesta pasta após os scripts 31, 32 e 40. Não altera a v1 ou a interface.
"""
from pathlib import Path
import hashlib
import json
import platform

import numpy as np
import pandas as pd
import scipy
import sklearn
import matplotlib
import matplotlib.pyplot as plt
from scipy.optimize import minimize
from scipy.special import expit, logsumexp
from sklearn.metrics import average_precision_score, roc_auc_score


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "outputs/atracao_relativa_paulo_2019"
OUT.mkdir(parents=True, exist_ok=True)
SOURCES = [
    "outputs/cenarios_adesao/grade_candidata_cenarios_2019.csv",
    "outputs/cenarios_adesao/rotas_por_ponto_2019.csv",
    "outputs/adesao_financeira/grupos_validacao.csv",
    "outputs/auditoria_sicom_modelo_2019/previsoes_comparacao.csv.gz",
    "evidencias/decisoes_sicom_2026_09_25.csv",
]
DT = {"id_municipio": str, "cnpj_raiz_8": str}
CASES = [
    ("clinicas53", "S1_unidades", "amostra_comum"),
    ("sedes53", "S2_sedes", "amostra_comum"),
    ("sedes62", "S2_sedes", "pre_elegivel_horas_positivas"),
    ("misto62", "S3_misto", "pre_elegivel_horas_positivas"),
]


def sha(path):
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()


hashes = [sha(path) for path in SOURCES]
grade = pd.read_csv(ROOT / SOURCES[0], dtype=DT, low_memory=False)
routes = pd.read_csv(ROOT / SOURCES[1], dtype=DT, low_memory=False)
folds = pd.read_csv(ROOT / SOURCES[2], dtype={"id_municipio": str})
old = pd.read_csv(ROOT / SOURCES[3], dtype=DT, low_memory=False)
decisions = pd.read_csv(ROOT / SOURCES[4], dtype={"id_municipio": str, "cnpj": str})
reject = decisions[(decisions.ano == 2019) &
                   (decisions.status == "objetos_contradizem_atribuicao_consorcial")]
assert len(reject) == 1
rejected_key = (reject.iloc[0].id_municipio, reject.iloc[0].cnpj[:8])
assert rejected_key == ("3118403", "00639952")
assert not folds.id_municipio.duplicated().any() and len(folds) == 853


class Case:
    def __init__(self, name, scenario, rule):
        g = grade[(grade.cenario == scenario) & grade[rule]].copy()
        g = g.sort_values(["id_municipio", "cnpj_raiz_8"]).reset_index(drop=True)
        g = g.merge(folds[["id_municipio", "municipios", "espacial"]],
                    on="id_municipio", validate="many_to_one")
        origins = np.sort(g.id_municipio.unique())
        roots = np.sort(g.cnpj_raiz_8.unique())
        n_origins, n_roots = len(origins), len(roots)
        assert n_origins == 853 and n_roots in (53, 62)
        assert len(g) == n_origins * n_roots
        assert np.array_equal(g.id_municipio.to_numpy(), np.repeat(origins, n_roots))
        assert np.array_equal(g.cnpj_raiz_8.to_numpy(), np.tile(roots, n_origins))
        assert g.horas_base.gt(0).all() and not g.adesao_financeira.isna().any()
        assert g.ano.eq(2019).all()

        pair_key = g[["id_municipio", "cnpj_raiz_8"]].copy()
        pair_key["pair"] = np.arange(len(g))
        r = routes[routes.cenario == scenario].merge(
            pair_key, on=["id_municipio", "cnpj_raiz_8"], how="inner",
            validate="many_to_one")
        assert r.pair.nunique() == len(g) and r.distancia_km.ge(0).all()
        assert r.peso_horas.notna().all() and r.peso_horas.ge(0).all()
        weight_sum = np.bincount(r.pair.to_numpy(), weights=r.peso_horas,
                                 minlength=len(g))
        np.testing.assert_allclose(weight_sum, 1, atol=1e-12)
        weighted_logdist = np.bincount(r.pair.to_numpy(),
            weights=r.peso_horas * np.log1p(r.distancia_km), minlength=len(g))
        np.testing.assert_allclose(weighted_logdist, g.impedancia_log_km_horas,
                                   atol=1e-10)

        self.name = name
        self.g = g
        self.origins = origins
        self.roots = roots
        self.n_origins = n_origins
        self.n_roots = n_roots
        self.n_pairs = len(g)
        self.pair = r.pair.to_numpy(dtype=int)
        self.weight = r.peso_horas.to_numpy(dtype=float)
        self.ldist = np.log1p(r.distancia_km.to_numpy(dtype=float))
        self.loghours = np.log(g.horas_base.to_numpy(dtype=float)).reshape(n_origins, n_roots)
        self.logpop = (g.log_populacao.to_numpy(dtype=float) - 10).reshape(n_origins, n_roots)
        self.y = g.adesao_financeira.to_numpy(dtype=float).reshape(n_origins, n_roots)
        self.municipios = g.municipios.to_numpy().reshape(n_origins, n_roots)[:, 0]
        self.espacial = g.espacial.to_numpy().reshape(n_origins, n_roots)[:, 0]
        self.known = np.ones((n_origins, n_roots), dtype=bool)
        self.known[g.id_municipio.eq(rejected_key[0]).to_numpy().reshape(n_origins, n_roots) &
                   g.cnpj_raiz_8.eq(rejected_key[1]).to_numpy().reshape(n_origins, n_roots)] = False
        assert self.known.sum() == len(g) - 1
        assert self.y[~self.known].item() == 1
        assert g.loc[g.id_municipio.eq("3161205") &
                     g.cnpj_raiz_8.eq("00079634"), "adesao_financeira"].eq(1).all()

    def raw_attraction(self, beta_hours, gamma, derivatives=False):
        # H_j^beta * soma_u (h_ju/H_j) / (1+d_iu)^gamma.
        weighted = self.weight * np.exp(-gamma * self.ldist)
        spatial = np.bincount(self.pair, weights=weighted,
                              minlength=self.n_pairs).reshape(self.n_origins, self.n_roots)
        assert np.isfinite(spatial).all() and spatial.min() > 0
        log_a = beta_hours * self.loghours + np.log(spatial)
        if not derivatives:
            return log_a
        weighted_ld = np.bincount(self.pair, weights=weighted * self.ldist,
                                  minlength=self.n_pairs).reshape(self.n_origins, self.n_roots)
        return log_a, -weighted_ld / spatial

    def attraction(self, beta_hours, gamma, derivatives=False):
        if derivatives:
            log_a, d_gamma = self.raw_attraction(beta_hours, gamma, True)
        else:
            log_a = self.raw_attraction(beta_hours, gamma)
        log_share = log_a - logsumexp(log_a, axis=1, keepdims=True)
        share = np.exp(log_share)
        # Somente a estabilidade numérica é truncada; nenhum tempo é imputado.
        safe = np.clip(share, 1e-14, 1 - 1e-14)
        log_relative_odds = np.log(safe) - np.log1p(-safe)
        if not derivatives:
            return share, log_relative_odds
        mean_h = (share * self.loghours).sum(axis=1, keepdims=True)
        mean_gamma = (share * d_gamma).sum(axis=1, keepdims=True)
        dt_h = (self.loghours - mean_h) / (1 - safe)
        dt_gamma = (d_gamma - mean_gamma) / (1 - safe)
        return share, log_relative_odds, dt_h, dt_gamma

    def objective(self, parameters, training, relative=True):
        if not relative:
            intercept, beta_pop, beta_hours, gamma = parameters
            log_a, d_gamma = self.raw_attraction(beta_hours, gamma, True)
            eta = intercept + beta_pop * self.logpop + log_a
            use = training[:, None] & self.known
            y, z = self.y[use], eta[use]
            residual = expit(z) - y
            return np.mean(np.logaddexp(0, z) - y * z), np.array([
                residual.mean(),
                np.mean(residual * self.logpop[use]),
                np.mean(residual * self.loghours[use]),
                np.mean(residual * d_gamma[use]),
            ])
        intercept, beta_pop, beta_hours, gamma, multiplier = parameters
        _, log_odds, dt_h, dt_gamma = self.attraction(beta_hours, gamma, True)
        eta = intercept + beta_pop * self.logpop + multiplier * log_odds
        use = training[:, None] & self.known
        y, z = self.y[use], eta[use]
        loss = np.mean(np.logaddexp(0, z) - y * z)
        residual = expit(z) - y
        gradients = np.array([
            residual.mean(),
            np.mean(residual * self.logpop[use]),
            np.mean(residual * multiplier * dt_h[use]),
            np.mean(residual * multiplier * dt_gamma[use]),
            np.mean(residual * log_odds[use]),
        ])
        return loss, gradients

    def fit(self, training, relative=True):
        prevalence = self.y[training][self.known[training]].mean()
        intercept = np.log(prevalence / (1 - prevalence)) + 4
        starts = ([[intercept, 0, 1, 1, 1], [intercept, 0, .5, 3, 1]] if relative
                  else [[intercept, 0, 1, 1], [intercept, 0, .5, 3]])
        bounds = [(-100, 100), (-10, 10), (0, 5), (0, 10)]
        if relative:
            bounds.append((0, 10))
        fits = [minimize(lambda p: self.objective(p, training, relative), x,
                         jac=True, bounds=bounds, method="L-BFGS-B",
                         options={"ftol": 1e-12, "gtol": 1e-7, "maxiter": 250})
                for x in starts]
        best = min(fits, key=lambda result: result.fun)
        assert best.success and np.isfinite(best.x).all(), best.message
        for parameter, gradient, (lower, upper) in zip(best.x, best.jac, bounds):
            if parameter <= lower + 1e-7:
                assert gradient >= -1e-4
            elif parameter >= upper - 1e-7:
                assert gradient <= 1e-4
            else:
                assert abs(gradient) < 1e-4
        return best, abs(fits[0].fun - fits[1].fun)

    def predict(self, parameters, relative=True):
        if not relative:
            intercept, beta_pop, beta_hours, gamma = parameters
            log_a = self.raw_attraction(beta_hours, gamma)
            probability = expit(intercept + beta_pop * self.logpop + log_a)
            assert np.isfinite(probability).all()
            return None, probability
        intercept, beta_pop, beta_hours, gamma, multiplier = parameters
        share, log_odds = self.attraction(beta_hours, gamma)
        probability = expit(intercept + beta_pop * self.logpop + multiplier * log_odds)
        assert np.isfinite(probability).all() and np.isfinite(share).all()
        np.testing.assert_allclose(share.sum(axis=1), 1, atol=1e-12)
        return share, probability


def score(y, p):
    assert len(y) == len(p) and 0 < y.sum() < len(y)
    q = np.clip(p, 1e-15, 1 - 1e-15)
    return dict(n=len(y), positivos=int(y.sum()),
        brier=float(np.mean((y-p)**2)),
        logloss=float(-np.mean(y*np.log(q) + (1-y)*np.log1p(-q))),
        precisao_media=float(average_precision_score(y, p)),
        auc=float(roc_auc_score(y, p)),
        probabilidade_media=float(p.mean()))


def check_gradient(case):
    training = case.municipios != 1
    for relative, vector in ((False, np.array([-8., .3, .5, 2.])),
                             (True, np.array([-4., .3, .5, 2., 2.]))):
        loss, gradient = case.objective(vector, training, relative)
        assert np.isfinite(loss) and np.isfinite(gradient).all()
        numeric = np.empty_like(vector)
        step = 1e-5
        for i in range(len(vector)):
            upper, lower = vector.copy(), vector.copy()
            upper[i] += step
            lower[i] -= step
            numeric[i] = (case.objective(upper, training, relative)[0] -
                          case.objective(lower, training, relative)[0]) / (2 * step)
        np.testing.assert_allclose(gradient, numeric, rtol=1e-5, atol=1e-7)


parameters = []
summaries = []
predictions = []
calibration = []
by_fold = []
paired = []
draws = np.random.default_rng(24092026).integers(0, 853, size=(2000, 853))
for name, scenario, rule in CASES:
    case = Case(name, scenario, rule)
    if name == "clinicas53":
        check_gradient(case)
    model_old = old[old.modelo == name]
    assert set(model_old.validacao) == {"municipios", "espacial"}
    for validation in ("municipios", "espacial"):
        group = case.municipios if validation == "municipios" else case.espacial
        predicted = np.full((case.n_origins, case.n_roots), np.nan)
        predicted_own = np.full_like(predicted, np.nan)
        shares = np.full_like(predicted, np.nan)
        for fold in range(1, 6):
            train = group != fold
            for label, relative in (("atracao_propria_unidades", False),
                                    ("atracao_relativa", True)):
                fit, start_difference = case.fit(train, relative)
                s, p = case.predict(fit.x, relative)
                if relative:
                    predicted[~train] = p[~train]
                    shares[~train] = s[~train]
                else:
                    predicted_own[~train] = p[~train]
                parameters.append(dict(modelo=name, validacao=validation, fold=fold,
                    especificacao=label, treino_municipios=int(train.sum()),
                    treino_pares=int((train[:, None] & case.known).sum()),
                    perda_treino=float(fit.fun), diferenca_inicios=float(start_difference),
                    iteracoes=int(fit.nit), convergiu=bool(fit.success),
                    intercepto=float(fit.x[0]), beta_pop=float(fit.x[1]),
                    beta_horas=float(fit.x[2]), gamma_distancia=float(fit.x[3]),
                    peso_relativo=float(fit.x[4]) if relative else np.nan))
        assert np.isfinite(predicted).all() and np.isfinite(shares).all()
        assert np.isfinite(predicted_own).all()
        q = case.g[["id_municipio", "municipio", "cnpj_raiz_8", "entidade",
                    "valor_total", "horas_base", "distancia_min_km"]].copy()
        q["fold"] = np.repeat(group, case.n_roots)
        q["atracao_relativa"] = shares.ravel()
        q["prob_paulo_binaria"] = predicted.ravel()
        q["prob_propria_unidades"] = predicted_own.ravel()
        q["resposta"] = case.y.ravel()
        q["conhecida"] = case.known.ravel()
        q["modelo"] = name
        q["validacao"] = validation
        baseline = model_old[model_old.validacao == validation][
            ["id_municipio", "cnpj_raiz_8", "prob_auditada", "fold"]]
        assert not baseline.duplicated(["id_municipio", "cnpj_raiz_8"]).any()
        q = q.merge(baseline, on=["id_municipio", "cnpj_raiz_8", "fold"],
                    how="left", validate="one_to_one")
        assert q.loc[q.conhecida, "prob_auditada"].notna().all()
        assert q.loc[~q.conhecida, "prob_auditada"].isna().all()
        q = q[q.conhecida].copy()
        assert len(q) in (45208, 52885)
        y = q.resposta.to_numpy()
        current, own, relative = (q.prob_auditada.to_numpy(),
                                  q.prob_propria_unidades.to_numpy(),
                                  q.prob_paulo_binaria.to_numpy())
        for label, comparator in (("atual", current),
                                  ("atracao_propria_unidades", own)):
            differences = pd.DataFrame({"id_municipio": q.id_municipio,
                "ganho": (y-comparator)**2 - (y-relative)**2})
            groups = differences.groupby("id_municipio", sort=True).agg(
                ganho=("ganho", "sum"), pares=("ganho", "size"))
            assert len(groups) == 853
            gain = groups.ganho.to_numpy()
            count = groups.pares.to_numpy()
            simulated = gain[draws].sum(axis=1) / count[draws].sum(axis=1)
            paired.append(dict(modelo=name, validacao=validation,
                comparador=label, ganho_brier=float(gain.sum()/count.sum()),
                limite_025=float(np.quantile(simulated, .025)),
                limite_975=float(np.quantile(simulated, .975)),
                metodo="2000 reamostragens pareadas de municípios; previsões OOF fixas"))
        for label, probabilities in (("atual", current),
                                     ("atracao_propria_unidades", own),
                                     ("atracao_relativa", relative)):
            summaries.append(dict(modelo=name, validacao=validation,
                                  especificacao=label, **score(y, probabilities)))
            for fold in range(1, 6):
                ix = q.fold.to_numpy() == fold
                by_fold.append(dict(modelo=name, validacao=validation,
                                    especificacao=label, fold=fold,
                                    **score(y[ix], probabilities[ix])))
            bands = pd.cut(probabilities, [-.001, .01, .05, .2, .5, 1],
                           labels=["até 1%", "1-5%", "5-20%", "20-50%", ">50%"])
            for band in bands.categories:
                ix = bands == band
                if ix.sum():
                    calibration.append(dict(modelo=name, validacao=validation,
                        especificacao=label, faixa=str(band), n=int(ix.sum()),
                        pagos=int(y[ix].sum()), observado=float(y[ix].mean()),
                        previsto=float(probabilities[ix].mean())))
        predictions.append(q)
        print(f"{name}/{validation}: {len(q)} pares, {int(y.sum())} pagos; "
              f"Brier atual {score(y,current)['brier']:.6f}, "
              f"propria {score(y,own)['brier']:.6f}, relativo {score(y,relative)['brier']:.6f}",
              flush=True)

pd.DataFrame(parameters).to_csv(OUT / "parametros_validacao.csv", index=False)
pd.DataFrame(summaries).to_csv(OUT / "metricas_mesma_amostra.csv", index=False)
pd.DataFrame(by_fold).to_csv(OUT / "metricas_por_fold.csv", index=False)
pd.DataFrame(paired).to_csv(OUT / "ganhos_pareados.csv", index=False)
pd.DataFrame(calibration).to_csv(OUT / "calibracao.csv", index=False)
pd.concat(predictions, ignore_index=True).to_csv(OUT / "previsoes.csv.gz",
                                               index=False, compression="gzip")
metrics = pd.DataFrame(summaries)
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(13, 5), layout="constrained")
labels = ["Clínicas 53", "Sedes 53", "Sedes 62", "Misto 62"]
colors = {"municipios": "#1976ad", "espacial": "#d47a2d"}
for validation, color in colors.items():
    vals = []
    for name, _, _ in CASES:
        m = metrics[(metrics.modelo == name) & (metrics.validacao == validation)]
        base = m.loc[m.especificacao == "atual", "brier"].item()
        new = m.loc[m.especificacao == "atracao_relativa", "brier"].item()
        vals.append(100 * (base - new) / base)
    pos = np.arange(4) + (-.18 if validation == "municipios" else .18)
    ax1.bar(pos, vals, width=.34, color=color,
            label="Municípios" if validation == "municipios" else "Espacial")
ax1.set_xticks(np.arange(4), labels, rotation=25, ha="right")
ax1.set_ylabel("Redução do Brier em relação ao piloto atual (%)")
ax1.set_title("Ganho fora do treino, na mesma amostra")
ax1.legend(frameon=False)
ax1.spines[["top", "right"]].set_visible(False)
cal = pd.DataFrame(calibration)
cal = cal[(cal.modelo == "clinicas53") & (cal.validacao == "municipios")]
for label, color in (("atual", "#677782"),
                     ("atracao_propria_unidades", "#a7b0b7"),
                     ("atracao_relativa", "#1976ad")):
    rows = cal[cal.especificacao == label]
    ax2.plot(rows.previsto, rows.observado, marker="o", color=color,
             label={"atual": "Piloto atual", "atracao_propria_unidades": "Atração própria",
                    "atracao_relativa": "Atração relativa"}[label])
ax2.plot([0, 1], [0, 1], linestyle="--", color="#9aa6ae", label="Calibração perfeita")
ax2.set(xlabel="Pagamento previsto na faixa", ylabel="Pagamento observado na faixa",
        title="Calibração: clínicas 53, validação municipal", xlim=(0, .9), ylim=(0, .9))
ax2.spines[["top", "right"]].set_visible(False)
ax2.legend(frameon=False, fontsize=9)
fig.savefig(OUT / "diagnostico_validacao.png", dpi=160)
plt.close(fig)
assert [sha(path) for path in SOURCES] == hashes
pd.DataFrame({"arquivo": SOURCES, "sha256": hashes}).to_csv(OUT / "fontes.csv", index=False)
(OUT / "resumo.json").write_text(json.dumps({
    "status": "EXPLORATORIO_SEPARADO", "ano": 2019, "cenarios": [name for name, _, _ in CASES],
    "formula_atracao": "H_j^beta * soma_u (horas_ju/H_j)/(1+distancia_iu_km)^gamma",
    "formula_vinculo": "logit Pr(pagamento_ij>0) = intercepto + beta_pop*ln(P_i) + peso_relativo*logit(atracao_ij/soma_k atracao_ik)",
    "ablacao": "Mesmo índice de atração de cada consórcio, mas sem normalizar pelos demais: logit Pr = intercepto + beta_pop*ln(P_i) + ln(atracao_ij).",
    "ambiente": {"python": platform.python_version(), "numpy": np.__version__,
                 "pandas": pd.__version__, "scipy": scipy.__version__,
                 "scikit_learn": sklearn.__version__, "matplotlib": matplotlib.__version__},
    "reamostragem": {"municipios": 853, "replicacoes": 2000, "seed": 24092026,
                     "limite": "Intervalos descritivos com previsoes OOF fixas; nao corrigem dependencia espacial nem refazem ajustes."},
    "denominador": "Todos os candidatos do cenário, inclusive zeros e par com resposta indeterminada; esta resposta não entra no treino/teste.",
    "limites": ["Vínculos múltiplos; frações de atração somam um, probabilidades binárias não.",
                 "Horas SUS e distâncias são atributos cadastrais de 2019, não produção ou trajetos de pacientes.",
                 "Sedes são referências cadastrais; disponibilidade jurídica anual não comprovada.",
                 "Comparações sempre na mesma amostra auditada por cenário/validação; não comparar 53 e 62 pelo escore."],
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
