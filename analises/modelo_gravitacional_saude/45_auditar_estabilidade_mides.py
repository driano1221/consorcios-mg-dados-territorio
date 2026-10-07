"""Audita pagadores anuais e reestima A/B sem raízes pequenas em qualquer ano.

Executar da pasta do modelo: python 45_auditar_estabilidade_mides.py
Saídas separadas em outputs/estabilidade_mides_saude_mg/. Não altera a v1.
"""
from __future__ import annotations

from collections import defaultdict
from html import escape
from pathlib import Path
import hashlib
import json

import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.special import expit, logsumexp


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "outputs/estabilidade_mides_saude_mg"
OUT.mkdir(parents=True, exist_ok=True)
SOURCES = {
    "financeira": "outputs/base_v1/base_financeira_v1.csv",
    "grade": "outputs/cenarios_adesao/grade_candidata_cenarios_2019.csv",
    "rotas": "outputs/cenarios_adesao/rotas_por_ponto_2019.csv",
    "grupos": "outputs/adesao_financeira/grupos_validacao.csv",
    "previsoes": "outputs/atracao_relativa_paulo_2019/previsoes.csv.gz",
    "decisoes": "evidencias/decisoes_sicom_2026_09_25.csv",
}
CASES = [
    ("clinicas53", "S1_unidades", "amostra_comum"),
    ("sedes53", "S2_sedes", "amostra_comum"),
    ("sedes62", "S2_sedes", "pre_elegivel_horas_positivas"),
    ("misto62", "S3_misto", "pre_elegivel_horas_positivas"),
]
hashes = {key: hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
          for key, path in SOURCES.items()}


def br(value: float, decimals: int = 0) -> str:
    return f"{value:,.{decimals}f}".replace(",", "#").replace(".", ",").replace("#", ".")


def pct(value: float, decimals: int = 1) -> str:
    return f"{br(100 * value, decimals)}%"


def score(y: np.ndarray, p: np.ndarray) -> dict:
    assert len(y) == len(p) and np.isfinite(p).all() and 0 < y.sum() < len(y)
    q = np.clip(p, 1e-15, 1 - 1e-15)
    return {"pares": len(y), "pagos": int(y.sum()),
            "brier": float(np.mean((y - p) ** 2)),
            "logloss": float(-np.mean(y * np.log(q) + (1 - y) * np.log1p(-q))),
            "prevalencia": float(y.mean())}


# A unidade financeira e municipio x raiz CNPJ x ano. A grade v1 conserva
# zeros; a contagem de pagadores usa somente valor_total estritamente positivo.
financial = pd.read_csv(ROOT / SOURCES["financeira"],
    dtype={"id_municipio": str, "cnpj_raiz_8": str},
    usecols=["id_municipio", "cnpj_raiz_8", "entidade", "ano", "valor_total", "ano_abertura"])
assert len(financial) == 491328 and financial.cnpj_raiz_8.nunique() == 73
assert not financial.duplicated(["id_municipio", "cnpj_raiz_8", "ano"]).any()
assert financial.valor_total.ge(0).all() and financial.ano.between(2014, 2021).all()
annual = (financial.groupby(["cnpj_raiz_8", "entidade", "ano", "ano_abertura"],
                            dropna=False, as_index=False)
          .agg(pagadores=("valor_total", lambda s: int(s.gt(0).sum())),
               valor=("valor_total", "sum")))
assert len(annual) == 576 and annual.groupby("cnpj_raiz_8").size().between(1, 8).all()
annual["ate_dois"] = annual.pagadores.between(1, 2)
annual["sem_pagador"] = annual.pagadores.eq(0)
annual["valor_por_pagador"] = annual.valor.div(annual.pagadores.replace(0, np.nan))
small = annual[annual.ate_dois].copy()
small_2019 = set(small.loc[small.ano.eq(2019), "cnpj_raiz_8"])
small_ever = set(small.cnpj_raiz_8)
assert len(small) == 17 and len(small_ever) == 6 and len(small_2019) == 3
assert annual.valor.sum() == financial.valor_total.sum()

# Entradas/saidas sao mudancas entre conjuntos de pagadores, nao de filiados.
payers = defaultdict(set)
for row in financial.loc[financial.valor_total.gt(0),
                         ["cnpj_raiz_8", "ano", "id_municipio"]].itertuples(index=False):
    payers[row.cnpj_raiz_8, row.ano].add(row.id_municipio)
transitions = []
for root, years in annual.groupby("cnpj_raiz_8", sort=True):
    years = years.sort_values("ano")
    for before, after in zip(years.itertuples(index=False),
                             years.iloc[1:].itertuples(index=False)):
        if after.ano != before.ano + 1:
            continue
        a, b = payers[root, before.ano], payers[root, after.ano]
        entrants, exits = len(b - a), len(a - b)
        assert len(a & b) + entrants == after.pagadores
        assert len(a & b) + exits == before.pagadores
        transitions.append({"cnpj_raiz_8": root, "entidade": before.entidade,
            "ano_anterior": before.ano, "ano": after.ano,
            "pagadores_anteriores": before.pagadores, "pagadores": after.pagadores,
            "entradas": entrants, "saidas": exits, "permanecem": len(a & b),
            "valor_anterior": before.valor, "valor": after.valor,
            "rotatividade_reuniao": ((entrants + exits) / after.pagadores
                                    if after.pagadores else np.nan),
            "ambos_anos_positivos": before.pagadores > 0 and after.pagadores > 0,
            "sentidos_opostos": ((after.pagadores - before.pagadores) *
                                 (after.valor - before.valor) < 0)})
transitions = pd.DataFrame(transitions)
assert len(transitions) <= 73 * 7
correlations = []
for root, years in annual.groupby("cnpj_raiz_8", sort=True):
    active = years[years.pagadores.gt(0)]
    enough = (len(active) >= 4 and active.pagadores.nunique() > 1 and
              active.valor.nunique() > 1)
    valid_t = transitions[(transitions.cnpj_raiz_8 == root) &
                          transitions.ambos_anos_positivos]
    correlations.append({"cnpj_raiz_8": root, "entidade": years.entidade.iloc[0],
        "anos_positivos": len(active),
        "correlacao_pearson": (float(active.pagadores.corr(active.valor)) if enough else np.nan),
        "motivo_sem_correlacao": ("" if enough else
            "menos de 4 anos positivos ou série constante"),
        "transicoes_positivas": len(valid_t),
        "rotatividade_mediana": valid_t.rotatividade_reuniao.median(),
        "mudancas_opostas": int(valid_t.sentidos_opostos.sum()),
        "valor_total": years.valor.sum(),
        "anos_ate_dois": int(years.ate_dois.sum())})
correlations = pd.DataFrame(correlations)

grade = pd.read_csv(ROOT / SOURCES["grade"],
    dtype={"id_municipio": str, "cnpj_raiz_8": str}, low_memory=False)
routes = pd.read_csv(ROOT / SOURCES["rotas"],
    dtype={"id_municipio": str, "cnpj_raiz_8": str}, low_memory=False)
folds = pd.read_csv(ROOT / SOURCES["grupos"], dtype={"id_municipio": str})
baseline = pd.read_csv(ROOT / SOURCES["previsoes"],
    dtype={"id_municipio": str, "cnpj_raiz_8": str}, low_memory=False)
decisions = pd.read_csv(ROOT / SOURCES["decisoes"],
    dtype={"id_municipio": str, "cnpj": str})
rejected = decisions[(decisions.ano == 2019) &
                     (decisions.status == "objetos_contradizem_atribuicao_consorcial")]
assert len(rejected) == 1
rejected_pair = (rejected.iloc[0].id_municipio, rejected.iloc[0].cnpj[:8])
assert rejected_pair == ("3118403", "00639952")
assert len(folds) == 853 and not folds.id_municipio.duplicated().any()


class Scenario:
    def __init__(self, name: str, source: str, rule: str, excluded: set[str]):
        g = grade[(grade.cenario.eq(source)) & grade[rule] &
                  ~grade.cnpj_raiz_8.isin(excluded)].copy()
        g = (g.merge(folds[["id_municipio", "municipios", "espacial"]],
                     on="id_municipio", validate="many_to_one")
             .sort_values(["id_municipio", "cnpj_raiz_8"]).reset_index(drop=True))
        origins, roots = np.sort(g.id_municipio.unique()), np.sort(g.cnpj_raiz_8.unique())
        n, m = len(origins), len(roots)
        assert n == 853 and len(g) == n * m and g.horas_base.gt(0).all()
        assert np.array_equal(g.id_municipio, np.repeat(origins, m))
        assert np.array_equal(g.cnpj_raiz_8, np.tile(roots, n))
        key = g[["id_municipio", "cnpj_raiz_8"]].copy()
        key["pair"] = np.arange(len(g))
        r = routes[routes.cenario.eq(source)].merge(
            key, on=["id_municipio", "cnpj_raiz_8"], validate="many_to_one")
        assert r.pair.nunique() == len(g) and r.peso_horas.ge(0).all()
        pair = r.pair.to_numpy(dtype=int)
        weight = r.peso_horas.to_numpy(dtype=float)
        ldist = np.log1p(r.distancia_km.to_numpy(dtype=float))
        np.testing.assert_allclose(np.bincount(pair, weight, minlength=len(g)), 1, atol=1e-12)
        weighted_logdist = np.bincount(pair, weight * ldist, minlength=len(g))
        np.testing.assert_allclose(weighted_logdist, g.impedancia_log_km_horas, atol=1e-10)
        self.name, self.source, self.g = name, source, g
        self.origins, self.roots, self.n, self.m = origins, roots, n, m
        self.pair, self.weight, self.ldist = pair, weight, ldist
        self.loghours = np.log(g.horas_base.to_numpy()).reshape(n, m)
        self.logpop = (g.log_populacao.to_numpy() - 10).reshape(n, m)
        self.y = g.adesao_financeira.to_numpy(dtype=float).reshape(n, m)
        self.x_a = np.column_stack([np.ones(len(g)), g.log_populacao,
                                    g.log_horas_positivas, g.impedancia_log_km_horas])
        self.known = np.ones((n, m), dtype=bool)
        ix = np.flatnonzero(g.id_municipio.eq(rejected_pair[0]) &
                            g.cnpj_raiz_8.eq(rejected_pair[1]))
        assert len(ix) == 1
        self.known.ravel()[ix] = False
        assert self.y.ravel()[ix].item() == 1
        self.groups = {v: g[v].to_numpy().reshape(n, m)[:, 0]
                       for v in ("municipios", "espacial")}

    def raw_attraction(self, beta_hours, gamma, deriv=False):
        w = self.weight * np.exp(-gamma * self.ldist)
        spatial = np.bincount(self.pair, w, minlength=self.n * self.m).reshape(self.n, self.m)
        assert np.isfinite(spatial).all() and spatial.min() > 0
        log_a = beta_hours * self.loghours + np.log(spatial)
        if not deriv:
            return log_a
        d_gamma = -np.bincount(self.pair, w * self.ldist,
            minlength=self.n * self.m).reshape(self.n, self.m) / spatial
        return log_a, d_gamma

    def relative(self, beta_hours, gamma, deriv=False):
        log_a, d_gamma = self.raw_attraction(beta_hours, gamma, True)
        share = np.exp(log_a - logsumexp(log_a, axis=1, keepdims=True))
        safe = np.clip(share, 1e-14, 1 - 1e-14)
        odds = np.log(safe) - np.log1p(-safe)
        if not deriv:
            return share, odds
        mean_h = (share * self.loghours).sum(axis=1, keepdims=True)
        mean_gamma = (share * d_gamma).sum(axis=1, keepdims=True)
        return odds, (self.loghours - mean_h) / (1 - safe), (d_gamma - mean_gamma) / (1 - safe)

    def fit_a(self, train):
        use = (train[:, None] & self.known).ravel()
        x, y = self.x_a[use], self.y.ravel()[use]
        start = np.array([np.log(y.mean() / (1-y.mean())), 0., 0., 0.])
        def objective(beta):
            eta = x @ beta
            residual = expit(eta) - y
            return np.mean(np.logaddexp(0, eta) - y * eta), x.T @ residual / len(y)
        fit = minimize(objective, start, jac=True, method="BFGS",
                       options={"gtol": 1e-6, "maxiter": 400})
        assert np.isfinite(fit.x).all() and np.max(abs(objective(fit.x)[1])) < 1e-6
        beta = fit.x.copy()
        for _ in range(12):
            p = expit(x @ beta)
            step = np.linalg.solve(x.T @ ((p * (1-p))[:, None] * x), x.T @ (y-p))
            beta += step
            if np.max(abs(step)) < 1e-11:
                break
        assert np.max(abs(objective(beta)[1])) < 1e-10
        return beta

    def predict_a(self, beta):
        return expit(self.x_a @ beta).reshape(self.n, self.m)

    def fit_b(self, train):
        use = train[:, None] & self.known
        y = self.y[use]
        intercept = np.log(y.mean() / (1 - y.mean())) + 4
        bounds = [(-100, 100), (-10, 10), (0, 5), (0, 10), (0, 10)]
        def objective(par):
            a, bp, bh, gamma, lam = par
            odds, dh, dg = self.relative(bh, gamma, True)
            eta = a + bp * self.logpop + lam * odds
            z, yy = eta[use], self.y[use]
            residual = expit(z) - yy
            return np.mean(np.logaddexp(0, z) - yy * z), np.array([
                residual.mean(), np.mean(residual * self.logpop[use]),
                np.mean(residual * lam * dh[use]),
                np.mean(residual * lam * dg[use]),
                np.mean(residual * odds[use])])
        fits = [minimize(objective, start, jac=True, bounds=bounds,
                         method="L-BFGS-B",
                         options={"ftol": 1e-12, "gtol": 1e-7, "maxiter": 250})
                for start in ([intercept, 0, 1, 1, 1], [intercept, 0, .5, 3, 1])]
        fit = min(fits, key=lambda result: result.fun)
        assert fit.success and np.isfinite(fit.x).all(), fit.message
        return fit.x

    def predict_b(self, par):
        a, bp, bh, gamma, lam = par
        share, odds = self.relative(bh, gamma)
        np.testing.assert_allclose(share.sum(axis=1), 1, atol=1e-12)
        return expit(a + bp * self.logpop + lam * odds)


case_roots = {}
for name, source, rule in CASES:
    case_roots[name] = set(grade.loc[grade.cenario.eq(source) & grade[rule], "cnpj_raiz_8"])
assert all(not (roots & small_2019) for roots in case_roots.values())
assert all(roots & small_ever == {"18151467"} for roots in case_roots.values())

# Verificação de reprodução: mesmas entradas, mesmo fold e nenhum corte devem
# reproduzir as previsões guardadas pelos scripts 40 (A) e 43 (B).
reference = Scenario("clinicas53", "S1_unidades", "amostra_comum", set())
test = reference.groups["municipios"] == 1
ref_a = reference.predict_a(reference.fit_a(~test))[test].ravel()
ref_b = reference.predict_b(reference.fit_b(~test))[test].ravel()
ref_rows = reference.g.loc[np.repeat(test, reference.m),
                           ["id_municipio", "cnpj_raiz_8"]].copy()
ref_rows["A_reproduzido"], ref_rows["B_reproduzido"] = ref_a, ref_b
ref_rows = ref_rows.merge(baseline[(baseline.modelo.eq("clinicas53")) &
    (baseline.validacao.eq("municipios")) & baseline.fold.eq(1)][
    ["id_municipio", "cnpj_raiz_8", "prob_auditada", "prob_paulo_binaria"]],
    on=["id_municipio", "cnpj_raiz_8"], validate="one_to_one")
ref_rows = ref_rows.dropna(subset=["prob_auditada", "prob_paulo_binaria"])
max_a = abs(ref_rows.A_reproduzido - ref_rows.prob_auditada).max()
max_b = abs(ref_rows.B_reproduzido - ref_rows.prob_paulo_binaria).max()
print(f"Reproducao baseline, fold 1: A max diff={max_a:.2e}; B max diff={max_b:.2e}", flush=True)
assert max_a < 1e-7 and max_b < 1e-7
pd.DataFrame([{"cenario": "clinicas53", "validacao": "municipios", "fold": 1,
    "pares_conhecidos": len(ref_rows), "max_diferenca_A": max_a,
    "max_diferenca_B": max_b}]).to_csv(OUT / "verificacao_reproducao.csv", index=False)

# Sem raízes com <=2 pagadores EM 2019, as duas matrizes do modelo são
# idênticas: mesmas linhas, oferta, denominador, treino e previsões.
annual_identity = []
for name, source, rule in CASES:
    g = grade[grade.cenario.eq(source) & grade[rule]]
    kept = g[~g.cnpj_raiz_8.isin(small_2019)]
    assert g.equals(kept)
    annual_identity.append({"cenario": name, "raizes_antes": g.cnpj_raiz_8.nunique(),
                            "raizes_depois": kept.cnpj_raiz_8.nunique(),
                            "pares_antes": len(g), "pares_depois": len(kept),
                            "resultado": "identico por identidade da amostra"})

# Sensibilidade distinta: retirar a raiz INTEIRA se teve <=2 pagadores em
# qualquer ano. Aqui AMVAP Saúde sai também de 2019, embora tenha 19 pagadores.
result = []
predictions = []
parameters = []
for name, source, rule in CASES:
    case = Scenario(name, source, rule, small_ever)
    assert case.m == (52 if name.endswith("53") else 61)
    old = baseline[(baseline.modelo.eq(name)) &
                   ~baseline.cnpj_raiz_8.isin(small_ever)].copy()
    assert len(old) == 2 * (853 * case.m - 1)
    for validation in ("municipios", "espacial"):
        group = case.groups[validation]
        pred_a = np.full((case.n, case.m), np.nan)
        pred_b = np.full_like(pred_a, np.nan)
        for fold in range(1, 6):
            train = group != fold
            ba = case.fit_a(train)
            bb = case.fit_b(train)
            pa, pb = case.predict_a(ba), case.predict_b(bb)
            pred_a[~train], pred_b[~train] = pa[~train], pb[~train]
            parameters.extend([{"cenario": name, "validacao": validation,
                                "fold": fold, "modelo": "A", "coeficientes": json.dumps(ba.tolist())},
                               {"cenario": name, "validacao": validation,
                                "fold": fold, "modelo": "B", "coeficientes": json.dumps(bb.tolist())}])
        assert np.isfinite(pred_a).all() and np.isfinite(pred_b).all()
        q = case.g[["id_municipio", "cnpj_raiz_8", "entidade", "valor_total"]].copy()
        q["fold"] = np.repeat(group, case.m)
        q["resposta"] = case.y.ravel()
        q["conhecida"] = case.known.ravel()
        q["A_sem_raiz"] = pred_a.ravel()
        q["B_sem_raiz"] = pred_b.ravel()
        q = q.merge(old[old.validacao.eq(validation)][["id_municipio", "cnpj_raiz_8",
            "fold", "prob_auditada", "prob_paulo_binaria"]],
            on=["id_municipio", "cnpj_raiz_8", "fold"], validate="one_to_one")
        assert not q.duplicated(["id_municipio", "cnpj_raiz_8"]).any()
        q = q[q.conhecida].copy()
        assert len(q) == 853 * case.m - 1
        y = q.resposta.to_numpy()
        for model, old_col, new_col in (("A", "prob_auditada", "A_sem_raiz"),
                                        ("B", "prob_paulo_binaria", "B_sem_raiz")):
            for version, column in (("original_nas_linhas_restantes", old_col),
                                    ("reestimado_sem_AMVAP", new_col)):
                result.append({"cenario": name, "validacao": validation,
                               "modelo": model, "versao": version,
                               **score(y, q[column].to_numpy())})
        q["cenario"], q["validacao"] = name, validation
        predictions.append(q)
        print(f"{name}/{validation}: {len(q)} pares, {int(y.sum())} pagos; "
              f"Brier A {result[-4]['brier']:.6f}->{result[-3]['brier']:.6f}; "
              f"B {result[-2]['brier']:.6f}->{result[-1]['brier']:.6f}", flush=True)

annual.to_csv(OUT / "consorcio_ano.csv", index=False)
small.to_csv(OUT / "ate_dois_consorcio_ano.csv", index=False)
transitions.to_csv(OUT / "transicoes.csv", index=False)
correlations.to_csv(OUT / "diagnostico_consorcios.csv", index=False)
pd.DataFrame(annual_identity).to_csv(OUT / "corte_2019_amostra_identica.csv", index=False)
pd.DataFrame(result).to_csv(OUT / "metricas_modelos_mesmas_linhas.csv", index=False)
pd.DataFrame(parameters).to_csv(OUT / "parametros_modelos.csv", index=False)
pd.concat(predictions).to_csv(OUT / "previsoes_sem_AMVAP.csv.gz",
                              index=False, compression="gzip")
pd.DataFrame([{"fonte": key, "caminho": path, "sha256": hashes[key]}
              for key, path in SOURCES.items()]).to_csv(OUT / "fontes.csv", index=False)
assert hashes == {key: hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
                  for key, path in SOURCES.items()}


def hist_svg(values, edges, labels, title, color="#2980B9"):
    counts = np.histogram(np.asarray(values, dtype=float), bins=edges)[0]
    width, height = 680, 200
    left, right, top, bottom = 38, 15, 24, 53
    usable = width - left - right
    ymax = max(counts.max(), 1)
    parts = [f'<svg viewBox="0 0 {width} {height}" role="img" aria-label="{escape(title)}">',
             f'<line x1="{left}" y1="{height-bottom}" x2="{width-right}" y2="{height-bottom}" stroke="#CCD8DF"/>']
    for i, (count, label) in enumerate(zip(counts, labels)):
        cell = usable / len(counts)
        x = left + i * cell + cell * .16
        bw = cell * .68
        bh = (height-top-bottom) * count / ymax
        parts.append(f'<rect x="{x:.1f}" y="{height-bottom-bh:.1f}" width="{bw:.1f}" height="{bh:.1f}" fill="{color}"/>')
        parts.append(f'<text x="{x+bw/2:.1f}" y="{height-bottom-bh-6:.1f}" text-anchor="middle" class="svg-value">{count}</text>')
        parts.append(f'<text x="{x+bw/2:.1f}" y="{height-bottom+20}" text-anchor="middle" class="svg-label">{escape(label)}</text>')
    return "".join(parts) + "</svg>"


def annual_svg(rows, column, color, suffix=""):
    width, height = 420, 170
    xs = np.linspace(33, width-17, len(rows))
    vals = rows[column].to_numpy(dtype=float)
    ymax = max(vals) * 1.12 if max(vals) else 1
    ys = 125 - vals / ymax * 100
    points = " ".join(f"{x:.1f},{y:.1f}" for x, y in zip(xs, ys))
    lines = [f'<svg viewBox="0 0 {width} {height}" role="img" aria-label="Série anual de {escape(column)}">',
             '<line x1="33" y1="125" x2="403" y2="125" stroke="#CCD8DF"/>',
             f'<polyline points="{points}" fill="none" stroke="{color}" stroke-width="3"/>']
    for x, y, row in zip(xs, ys, rows.itertuples(index=False)):
        lines.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="3.7" fill="{color}"/>')
        lines.append(f'<text x="{x:.1f}" y="148" text-anchor="middle" class="svg-label">{row.ano}</text>')
    lines.append(f'<text x="403" y="{max(17,ys[-1]-8):.1f}" text-anchor="end" class="svg-value">{br(vals[-1]/1e6,1) if suffix=="mi" else int(vals[-1])}{" mi" if suffix=="mi" else ""}</text>')
    return "".join(lines) + "</svg>"


valid = transitions[transitions.ambos_anos_positivos].rotatividade_reuniao.dropna()
corr = correlations.correlacao_pearson.dropna()
metrics = pd.DataFrame(result)
amvap = annual[annual.cnpj_raiz_8.eq("18151467")].sort_values("ano")
amvap_2019 = amvap[amvap.ano.eq(2019)].iloc[0]
assert amvap_2019.pagadores == 19 and abs(amvap_2019.valor - 6332519.73) < .01
negative = int(corr.lt(0).sum())
hist_churn = hist_svg(valid, [0, .1, .25, .5, 1, np.inf],
    ["0–0,1", "0,1–0,25", "0,25–0,5", "0,5–1", "mais de 1"],
    "Distribuição da rotatividade entre anos com pagamento nos dois lados")
hist_corr = hist_svg(corr, [-1.001, -.5, 0, .5, 1.001],
    ["−1 a −0,5", "−0,5 a 0", "0 a 0,5", "0,5 a 1"],
    "Distribuição da correlação entre pagadores e valor recebido", "#7F8C8D")
small_table = "".join(
    f'<tr><td>{escape(row.entidade)}</td><td>{row.ano}</td><td>{row.pagadores}</td><td>R$ {br(row.valor,2)}</td></tr>'
    for row in small.sort_values(["ano","entidade"]).itertuples(index=False))
entity_table = "".join(
    f'<tr><td>{escape(row.entidade)}</td><td>{row.anos_positivos}</td><td>{row.anos_ate_dois}</td>'
    f'<td>{br(row.rotatividade_mediana,2) if pd.notna(row.rotatividade_mediana) else "—"}</td>'
    f'<td>{br(row.correlacao_pearson,2) if pd.notna(row.correlacao_pearson) else "—"}</td>'
    f'<td>{row.mudancas_opostas}</td></tr>'
    for row in correlations.sort_values(["anos_ate_dois","entidade"],ascending=[False,True]).itertuples(index=False))
metric_rows = []
for (scenario, validation, model), group in metrics.groupby(["cenario","validacao","modelo"],sort=False):
    old_score = group[group.versao.eq("original_nas_linhas_restantes")].iloc[0]
    new_score = group[group.versao.eq("reestimado_sem_AMVAP")].iloc[0]
    delta = new_score.brier - old_score.brier
    metric_rows.append(f'<tr><td>{escape(scenario)}</td><td>{"Municípios" if validation=="municipios" else "Blocos geográficos"}</td>'
                       f'<td>{model}</td><td>{br(old_score.brier,6)}</td><td>{br(new_score.brier,6)}</td>'
                       f'<td class="{ "up" if delta>0 else "down" }">{("+" if delta>0 else "")+br(delta,6)}</td></tr>')
metric_table = "".join(metric_rows)
main = metrics[(metrics.cenario.eq("clinicas53")) & metrics.validacao.eq("municipios")]
headline = {}
for model in ("A", "B"):
    group = main[main.modelo.eq(model)]
    headline[model] = (group[group.versao.eq("original_nas_linhas_restantes")].brier.item(),
                       group[group.versao.eq("reestimado_sem_AMVAP")].brier.item())

html = f'''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Estabilidade dos pagamentos | saúde MG</title>
<style>
:root{{--ink:#1A252F;--blue:#2980B9;--red:#C0392B;--gray:#7F8C8D;--muted:#566570;--line:#DCE3E7;--soft:#F6F8F9}}
*{{box-sizing:border-box}}html{{scroll-behavior:smooth}}body{{margin:0;background:white;color:var(--ink);font:16px/1.6 Arial,Helvetica,sans-serif}}
.wrap{{max-width:1100px;margin:auto;padding:0 28px}}header{{border-bottom:1px solid var(--line);padding:19px 0}}.brand{{font-size:12px;font-weight:700;letter-spacing:.09em;color:var(--blue)}}
nav{{display:flex;gap:24px;flex-wrap:wrap;font-size:13px}}nav a,a{{color:#1D628F;text-underline-offset:3px}}.top{{display:flex;justify-content:space-between;gap:20px;align-items:center}}
main{{padding-bottom:70px}}section{{border-bottom:1px solid var(--line);padding:50px 0}}h1,h2,h3{{line-height:1.2;margin:0 0 16px}}h1{{font-size:42px;max-width:24ch}}h2{{font-size:28px}}h3{{font-size:19px}}
p{{max-width:78ch;margin:12px 0;color:var(--muted)}}.lead{{font-size:19px;color:var(--ink);max-width:68ch}}.eyebrow{{font-size:11px;font-weight:700;letter-spacing:.1em;color:#1D628F;text-transform:uppercase;margin-bottom:12px}}
.stats{{display:grid;grid-template-columns:repeat(4,1fr);gap:20px;border-block:2px solid var(--ink);margin-top:32px;padding:20px 0}}.stats strong{{font-size:31px;display:block;line-height:1.15}}.stats span{{font-size:13px;color:var(--muted)}}
.flow{{display:grid;grid-template-columns:repeat(4,1fr);gap:18px;margin:26px 0}}.flow article{{border-top:3px solid var(--blue);padding-top:12px}}.flow b{{font-size:15px}}.flow p{{font-size:13px;margin:5px 0}}.note{{border-left:3px solid var(--blue);padding:3px 0 3px 16px;max-width:80ch}}.warn{{border-color:var(--red)}}
.split{{display:grid;grid-template-columns:1fr 1fr;gap:38px}}.figure{{margin:16px 0 0}}svg{{display:block;max-width:100%;height:auto}}.svg-label{{font:12px Arial;fill:#566570}}.svg-value{{font:bold 13px Arial;fill:#1A252F}}figcaption{{color:var(--muted);font-size:12px;line-height:1.5;margin-top:7px}}
.table-wrap{{overflow:auto;max-height:420px;border-block:1px solid var(--line);margin-top:20px}}table{{border-collapse:collapse;width:100%;font-size:13px}}th,td{{padding:10px 12px;text-align:left;border-bottom:1px solid var(--line);white-space:nowrap}}th{{background:var(--soft);position:sticky;top:0;color:var(--ink)}}td:first-child{{white-space:normal;min-width:160px}}.up{{color:var(--red);font-weight:700}}.down{{color:#1D628F;font-weight:700}}
.case{{border-top:2px solid var(--ink);padding-top:18px}}.case strong{{font-size:28px}}details{{margin-top:24px;border-top:1px solid var(--line);padding-top:15px}}summary{{cursor:pointer;font-weight:700}}input[type=search]{{padding:10px 12px;border:1px solid #A8B6BF;width:100%;max-width:400px;font:inherit;margin-top:14px}}
.comparison{{display:grid;grid-template-columns:1fr 1fr;gap:28px;margin:20px 0}}.comparison article{{border-top:3px solid var(--blue);padding-top:13px}}.comparison article+article{{border-color:var(--red)}}.comparison strong{{font-size:22px}}.comparison small{{display:block;color:var(--muted)}}footer{{font-size:12px;color:var(--muted);padding:22px 0 35px}}
@media(max-width:720px){{.top{{display:block}}nav{{margin-top:12px;gap:8px 18px}}.wrap{{padding:0 19px}}section{{padding:35px 0}}h1{{font-size:31px}}h2{{font-size:24px}}.stats{{grid-template-columns:1fr 1fr}}.flow,.split,.comparison{{grid-template-columns:1fr}}.flow{{gap:12px}}.table-wrap{{max-height:350px}}}}
</style></head><body><header><div class="wrap top"><div class="brand">IPEA · CONSÓRCIOS DE SAÚDE EM MG</div><nav><a href="#corte">O corte</a><a href="#trajetorias">Trajetórias</a><a href="#modelos">Modelos A e B</a><a href="#consulta">Consultar</a></nav></div></header>
<main class="wrap"><section><div class="eyebrow">Diagnóstico para discussão · MIDES 2014–2021</div><h1>Três consórcios têm até dois pagadores em 2019</h1>
<p class="lead">Eles permanecem na base financeira, mas nenhum entrou nos recortes de 53 ou 62 consórcios usados nos modelos. Retirá-los em 2019 deixa a amostra e as previsões exatamente iguais.</p>
<div class="stats"><div><strong>73</strong><span>consórcios no núcleo financeiro</span></div><div><strong>17</strong><span>consórcios-ano com 1 ou 2 pagadores, de 576 elegíveis</span></div><div><strong>3</strong><span>consórcios nessa situação em 2019</span></div><div><strong>0</strong><span>deles entre os 53 ou 62 modelados em 2019</span></div></div>
<p>Fonte: base financeira v1, uma linha por município × consórcio × ano. “Pagador” significa valor MIDES positivo naquele ano; não é sinônimo de filiação jurídica.</p></section>
<section id="corte"><div class="eyebrow">01 / O que foi contado</div><h2>Do pagamento municipal ao caso de revisão</h2>
<div class="flow"><article><b>73 raízes</b><p>Consórcios de saúde do núcleo financeiro de MG.</p></article><article><b>576 consórcios-ano</b><p>Anos presentes na grade v1; 559 têm algum pagamento positivo.</p></article><article><b>17 anos com 1 ou 2</b><p>Vinte relações pagas, em seis consórcios distintos.</p></article><article><b>3 em 2019</b><p>CIS/UBA, raiz 02287790 e CISAME: quatro relações e R$ {br(small[small.ano.eq(2019)].valor.sum(),2)}.</p></article></div>
<p class="note">Nos oito anos, os 17 consórcios-ano somam R$ {br(small.valor.sum(),2)}. O corte foi medido por <em>consórcio-ano</em>; um mesmo consórcio pode aparecer em mais de um ano.</p>
<details><summary>Ver os 17 consórcios-ano com até dois pagadores</summary><div class="table-wrap"><table><thead><tr><th>Consórcio</th><th>Ano</th><th>Pagadores</th><th>Valor recebido</th></tr></thead><tbody>{small_table}</tbody></table></div></details>
<p class="note warn">Ausência de pagamento em um ano foi guardada à parte. Também não tratei o primeiro ano observado como uma “entrada” comprovada.</p></section>
<section id="trajetorias"><div class="eyebrow">02 / Séries 2014–2021</div><h2>Oscilação indica onde olhar primeiro</h2>
<p>Rotatividade, como proposta na reunião, é a soma de pagadores que entraram e saíram dividida pelo número de pagadores do ano atual. O gráfico usa apenas transições com pagamento nos dois anos. A medida pode passar de 1; com zero pagadores no ano atual, fica indefinida.</p>
<div class="split"><figure class="figure"><h3>Rotatividade anual</h3>{hist_churn}<figcaption>{len(valid)} transições entre dois anos com pagamento. Eixo: (entradas + saídas) / pagadores do ano.</figcaption></figure>
<figure class="figure"><h3>Pagadores e valor caminham juntos?</h3>{hist_corr}<figcaption>{len(corr)} consórcios têm pelo menos quatro anos positivos e variação nas duas séries; {negative} apresentam correlação negativa. Os demais não recebem correlação interpretável.</figcaption></figure></div>
<p class="note warn">Correlação negativa é sinal para conferir a série, não prova de erro. Pagamentos nominais podem crescer com reajustes ou maior gasto por município mesmo quando o número de pagadores cai.</p>
<div class="case" style="margin-top:30px"><h3>AMVAP Saúde: um ano pequeno não define a entidade</h3><p>Em 2015, só um município pagou R$ 9.900. Em 2019, foram <strong>19 pagadores</strong> e <strong>R$ {br(amvap_2019.valor/1e6,2)} milhões</strong>. Excluir toda a raiz por causa de 2015 retiraria seus 19 vínculos de 2019 do teste.</p></div>
<div class="split"><figure class="figure"><h3>Municípios pagadores</h3>{annual_svg(amvap,"pagadores","#2980B9")}</figure><figure class="figure"><h3>Valor anual, nominal</h3>{annual_svg(amvap,"valor","#7F8C8D","mi")}</figure></div></section>
<section id="modelos"><div class="eyebrow">03 / Sensibilidade dos pilotos de 2019</div><h2>Dois cortes que respondem a perguntas diferentes</h2>
<div class="comparison"><article><h3>Corte pelo próprio 2019</h3><strong>Sem mudança</strong><small>Três consórcios financeiros retirados; zero dos recortes 53/62.</small><p>As linhas, as horas, os destinos, os denominadores da atração e as previsões A/B continuam idênticos. Não há ganho de desempenho a estimar.</p></article>
<article><h3>Corte pela série inteira</h3><strong>AMVAP sai</strong><small>Se qualquer ano tiver 1 ou 2 pagadores, a raiz toda sai.</small><p>Esse teste remove a AMVAP dos recortes de 2019 por causa de 2015. Ambos os modelos foram reestimados, com os mesmos cinco grupos municipais e espaciais.</p></article></div>
<p>No recorte clínico, a amostra auditada passa de 45.208 pares/770 pagos para <b>44.355 pares/751 pagos</b>. O Brier mede erro de probabilidade: menor é melhor. Para comparar com justiça, o resultado antigo foi recalculado <em>nas mesmas linhas restantes</em>, antes de ser confrontado com o novo ajuste.</p>
<div class="comparison"><article><h3>Modelo A · clínica/53 · municípios</h3><strong>{br(headline['A'][0],6)} → {br(headline['A'][1],6)}</strong><small>Brier antigo nas linhas restantes → reestimado sem AMVAP</small></article><article><h3>Modelo B · clínica/53 · municípios</h3><strong>{br(headline['B'][0],6)} → {br(headline['B'][1],6)}</strong><small>Mesmo cálculo; B refaz a soma da atração sem AMVAP.</small></article></div>
<p class="note warn">Este segundo corte não foi aprovado pela equipe. Ele serve para mostrar o custo de transformar um ano incomum em exclusão permanente. O desempenho dos modelos não valida filiação, acesso ou qualidade do MIDES.</p>
<details><summary>Ver os quatro cenários e as duas validações</summary><div class="table-wrap"><table><thead><tr><th>Cenário</th><th>Validação</th><th>Modelo</th><th>Antigo, mesmas linhas</th><th>Reestimado</th><th>Δ Brier</th></tr></thead><tbody>{metric_table}</tbody></table></div><p>As previsões são fora do treino do município testado. “Clínicas 53” e “Sedes 53” usam os mesmos candidatos; “Sedes 62” e “Misto 62” usam o conjunto ampliado. Depois do corte histórico, ficam 52/61.</p></details></section>
<section id="consulta"><div class="eyebrow">04 / Conferir os casos</div><h2>Todos os 73 consórcios</h2><p>A tabela deixa visíveis anos com poucos pagadores, rotatividade mediana e correlação quando há série suficiente. Um traço significa que não há base para calcular ou interpretar aquela medida.</p>
<input type="search" id="search" aria-label="Buscar consórcio" placeholder="Buscar consórcio..."><div class="table-wrap"><table id="entities"><thead><tr><th>Consórcio</th><th>Anos pagos</th><th>Anos com 1–2</th><th>Rotatividade mediana</th><th>Correlação</th><th>Mudanças opostas</th></tr></thead><tbody>{entity_table}</tbody></table></div>
<p>Rotatividade mediana considera transições entre dois anos positivos. “Mudanças opostas” conta anos em que pagadores e valor mudaram em direções diferentes. Nenhuma dessas colunas é um selo de confiabilidade.</p></section>
<section><div class="eyebrow">Método e limites</div><h2>O que esta página permite concluir</h2><p>O filtro anual de até dois pagadores não altera os pilotos atuais porque esses consórcios já não tinham massa clínica ou complementar utilizável em 2019. O filtro permanente altera a amostra por excluir AMVAP Saúde. Escolher um recorte pela estabilidade do próprio pagamento pode tornar o exercício menos representativo e favorecer artificialmente a previsão do pagamento.</p>
<p>Fontes: MIDES consolidado na base financeira v1; CNES/Distbrasil e grupos de validação dos cenários de 2019; decisão documental que retira Conselheiro Pena–CISVI da resposta auditada. CNPJs agrupados por raiz; valores nominais; nenhum zero foi imputado como saída jurídica. As entradas e os scripts usados estão listados em <code>fontes.csv</code> nesta pasta.</p>
<p>Arquivos de conferência: <code>consorcio_ano.csv</code>, <code>transicoes.csv</code>, <code>diagnostico_consorcios.csv</code>, <code>metricas_modelos_mesmas_linhas.csv</code> e <code>previsoes_sem_AMVAP.csv.gz</code>. Reproduzir na pasta do projeto com <code>python 45_auditar_estabilidade_mides.py</code>.</p></section></main>
<footer class="wrap">Dados: MIDES, CNES/DATASUS e Distbrasil. Período financeiro: 2014–2021. Modelos: exercício de 2019.</footer>
<script>document.getElementById('search').addEventListener('input',function(){{let q=this.value.toLocaleLowerCase('pt-BR');document.querySelectorAll('#entities tbody tr').forEach(tr=>tr.hidden=!tr.cells[0].textContent.toLocaleLowerCase('pt-BR').includes(q))}})</script>
</body></html>'''
(OUT / "index.html").write_text(html, encoding="utf-8")
(OUT / "resumo.json").write_text(json.dumps({
    "estado": "sensibilidade_exploratoria", "anos": [2014, 2021],
    "consorcios": 73, "consorcio_ano": len(annual),
    "consorcio_ano_positivos": int(annual.pagadores.gt(0).sum()),
    "ate_dois_consorcio_ano": len(small), "raizes_com_ano_ate_dois": len(small_ever),
    "ate_dois_em_2019": sorted(small_2019),
    "intersecao_corte_2019_modelos": {name: sorted(roots & small_2019) for name, roots in case_roots.items()},
    "intersecao_corte_historico_modelos": {name: sorted(roots & small_ever) for name, roots in case_roots.items()},
    "limites": ["Pagamento positivo não comprova filiação jurídica",
                "Correlação é descritiva, com poucos anos",
                "Corte histórico não foi aprovado pela equipe",
                "Seleção com base no desfecho pode enviesar a modelagem"]},
    ensure_ascii=False, indent=2).encode('utf-8').decode('utf-8') + "\n", encoding="utf-8")
print("Relatório:", OUT / "index.html", flush=True)
