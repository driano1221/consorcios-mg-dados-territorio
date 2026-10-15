"""Confere o diagnóstico público e a ausência de resultados dos modelos."""
from pathlib import Path

import pandas as pd


root = Path(__file__).resolve().parents[1]
site = root / "outputs/visuais_publicos"
home = (site / "index.html").read_text(encoding="utf-8")
report = (site / "estabilidade.html").read_text(encoding="utf-8")
financial = pd.read_csv(root / "outputs/base_v1/base_financeira_v1.csv",
                        usecols=["cnpj_raiz_8", "id_municipio", "ano", "valor_total"],
                        dtype={"cnpj_raiz_8": str, "id_municipio": str})
counts = (financial[financial.valor_total.gt(0)]
          .groupby("cnpj_raiz_8").id_municipio.nunique())
assert counts[counts.le(2)].to_dict() == {"02287790": 1}
annual_max = (financial[financial.valor_total.gt(0)]
              .groupby(["cnpj_raiz_8", "ano"]).id_municipio.nunique()
              .groupby("cnpj_raiz_8").max())
assert annual_max[annual_max.le(2)].to_dict() == {"00840724": 1, "02287790": 1}
assert 'href="estabilidade.html"' in home
assert 'href="index.html"' in report
assert 'href="#modelo"' not in home and 'data-page="modelo"' not in home
assert '<section id="modelos"' not in report
assert all(term not in report for term in ("Modelo A", "Modelo B", "Brier", "53/62"))
assert 'CIS/UBA' in report and 'três municípios diferentes' in report
assert 'Dois consórcios nunca passaram de um pagador por ano' in report
assert 'id="max-filter"' in report and 'id="annual-payers"' in report
assert '<option value="small">Até 2 pagadores</option>' in report
assert 'Trajetórias MIDES' in home and 'Rotatividade anual' in report
assert not any(p.name.startswith("modelo_") for p in site.rglob("*"))
print("Site público: máximo anual, tabela filtrável e ausência da aba Modelo conferidos.")
