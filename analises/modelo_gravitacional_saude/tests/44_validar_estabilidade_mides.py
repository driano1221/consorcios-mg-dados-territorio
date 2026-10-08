"""Conferência independente das saídas de 45_auditar_estabilidade_mides.py."""
from pathlib import Path
import hashlib

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "outputs/estabilidade_mides_saude_mg"
financial = pd.read_csv(ROOT / "outputs/base_v1/base_financeira_v1.csv",
                        dtype={"id_municipio": str, "cnpj_raiz_8": str})
annual = pd.read_csv(OUT / "consorcio_ano.csv", dtype={"cnpj_raiz_8": str})
small = pd.read_csv(OUT / "ate_dois_consorcio_ano.csv", dtype={"cnpj_raiz_8": str})
period = pd.read_csv(OUT / "consorcios_periodo_completo.csv", dtype={"cnpj_raiz_8": str})
period_small = pd.read_csv(OUT / "ate_dois_periodo_completo.csv", dtype={"cnpj_raiz_8": str})
identity = pd.read_csv(OUT / "corte_2019_amostra_identica.csv")
period_identity = pd.read_csv(OUT / "corte_periodo_amostra_identica.csv")
metrics = pd.read_csv(OUT / "metricas_modelos_mesmas_linhas.csv")
pred = pd.read_csv(OUT / "previsoes_sem_AMVAP.csv.gz", dtype={"cnpj_raiz_8": str})

assert len(financial) == 491328 and financial.valor_total.gt(0).sum() == 10735
assert len(annual) == 576 and annual.pagadores.sum() == 10735
assert np.isclose(annual.valor.sum(), financial.valor_total.sum(), atol=.01)
assert len(small) == 17 and small.cnpj_raiz_8.nunique() == 6
assert small.pagadores.between(1, 2).all() and small.pagadores.sum() == 20
assert len(small[small.ano.eq(2019)]) == 3
assert len(period) == 73 and period.pagadores_distintos.min() == 1
assert len(period_small) == 1 and period_small.cnpj_raiz_8.item() == "02287790"
assert period_small.pagadores_distintos.item() == 1
assert period_small.pares_ano_pagos.item() == 7
assert financial.loc[financial.cnpj_raiz_8.eq("02287790") &
                     financial.valor_total.gt(0), "municipio"].unique().tolist() == ["Serra Dos Aimorés"]
assert period.loc[period.cnpj_raiz_8.isin(["00840724", "31974558"]),
                  "pagadores_distintos"].eq(3).all()
assert (period_identity.pares_antes == period_identity.pares_depois).all()
assert (period_identity.raizes_antes == period_identity.raizes_depois).all()
assert (identity.pares_antes == identity.pares_depois).all()
assert (identity.raizes_antes == identity.raizes_depois).all()
assert len(metrics) == 32 and len(pred) == 4 * 2 * 853 * 52 + 2 * 2 * 853 * 9 - 8
assert not pred.cnpj_raiz_8.isin(small.cnpj_raiz_8).any()
assert pred.conhecida.all() and pred.resposta.isin([0, 1]).all()
for row in metrics.itertuples(index=False):
    subset = pred[pred.cenario.eq(row.cenario) & pred.validacao.eq(row.validacao)]
    col = {("A", "original_nas_linhas_restantes"): "prob_auditada",
           ("B", "original_nas_linhas_restantes"): "prob_paulo_binaria",
           ("A", "reestimado_sem_AMVAP"): "A_sem_raiz",
           ("B", "reestimado_sem_AMVAP"): "B_sem_raiz"}[row.modelo, row.versao]
    assert len(subset) == row.pares and subset.resposta.sum() == row.pagos
    assert np.isclose(np.mean((subset.resposta - subset[col]) ** 2), row.brier, atol=1e-13)
for source in pd.read_csv(OUT / "fontes.csv").itertuples(index=False):
    assert hashlib.sha256((ROOT / source.caminho).read_bytes()).hexdigest() == source.sha256
print("Auditoria independente: contagens, valores, amostra, Brier e hashes conferidos.")
