"""Recalcula o Brier exibido na aba Modelo a partir das previsões fora do treino."""
from pathlib import Path
import hashlib
import json
import math

import pandas as pd


HERE = Path(__file__).resolve().parents[1]
OUT = HERE / "outputs"
scores = pd.read_csv(OUT / "atracao_relativa_paulo_2019/metricas_mesma_amostra.csv")
folds = pd.read_csv(OUT / "atracao_relativa_paulo_2019/metricas_por_fold.csv")
predictions = pd.read_csv(
    OUT / "atracao_relativa_paulo_2019/previsoes.csv.gz",
    usecols=["modelo", "validacao", "resposta", "prob_auditada", "prob_paulo_binaria"],
)
html = (OUT / "visuais_v1/index.html").read_text(encoding="utf-8")

assert len(predictions) == 392372
assert len(scores) == 24 and len(folds) == 120
assert html.count('class="model-compare"') == 1
assert "45.208 pares" in html and "52.885 pares" in html
assert "770 pagamentos confirmados" in html and "1.298 pagamentos confirmados" in html

verified = []
for (model, validation), group in predictions.groupby(["modelo", "validacao"]):
    assert len(group) in (45208, 52885)
    assert group.resposta.sum() in (770, 1298)
    assert not group[["resposta", "prob_auditada", "prob_paulo_binaria"]].isna().any().any()
    assert group[["prob_auditada", "prob_paulo_binaria"]].ge(0).all().all()
    assert group[["prob_auditada", "prob_paulo_binaria"]].le(1).all().all()
    for spec, field in (("atual", "prob_auditada"),
                        ("atracao_relativa", "prob_paulo_binaria")):
        expected = scores[(scores.modelo == model) & (scores.validacao == validation) &
                          (scores.especificacao == spec)]
        assert len(expected) == 1
        measured = ((group.resposta - group[field]) ** 2).mean()
        assert math.isclose(measured, expected.iloc[0].brier, rel_tol=0, abs_tol=1e-12)
        verified.append({"recorte": model, "validacao": validation,
                         "especificacao": spec, "brier": measured})

assert (folds.pivot(index=["modelo", "validacao", "fold"],
                    columns="especificacao", values="brier").atracao_relativa <
        folds.pivot(index=["modelo", "validacao", "fold"],
                    columns="especificacao", values="brier").atual).all()
for validation in ("municipios", "espacial"):
    assert (OUT / f"visuais_v1/figuras/modelo_comparacao_{validation}.png").is_file()
    assert (OUT / f"visuais_v1/figuras/modelo_comparacao_{validation}.svg").is_file()
    assert f'id="mc-{validation}"' in html
assert "Igarapé × CISMEP" in html and "Jacinto × CISRAL" in html
assert "1,70% dos pares têm pagamento" in html
source_paths = [OUT / "atracao_relativa_paulo_2019/metricas_mesma_amostra.csv",
                OUT / "atracao_relativa_paulo_2019/metricas_por_fold.csv",
                OUT / "atracao_relativa_paulo_2019/previsoes.csv.gz"]
report = {"status": "OK", "previsoes_fora_treino": len(predictions),
          "brier_recalculados": verified, "folds_com_melhora": 40,
          "fontes_sha256": {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                             for p in source_paths}}
(HERE / "checks/43_comparacao_modelos.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("OK: Brier recalculado nas 8 comparações; 40 grupos, exemplos e artefatos conferidos.")
