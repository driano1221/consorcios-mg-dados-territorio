"""Confere que diagnóstico e modelos estão acessíveis no mesmo site."""
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
assert 'data-page="modelo"' in home and '<section id="modelo" hidden>' in home
assert 'id="mc-validacao"' in home and 'Igarapé × CISMEP' in home
assert '0,008886' in home and '0,007084' in home
assert all((site / "figuras" / name).is_file() for name in (
    "modelo_brier_espacial.svg", "modelo_brier_municipios.svg",
    "modelo_calibracao.svg", "modelo_comparacao_espacial.svg",
    "modelo_comparacao_municipios.svg"))
assert 'href="index.html#modelo"' in report
assert '<section id="modelos"' not in report
assert all(term not in report for term in ("Brier", "53/62", "reestimado"))
assert 'CIS/UBA' in report and 'três municípios diferentes' in report
assert 'Dois consórcios nunca passaram de um pagador por ano' in report
assert 'id="max-filter"' in report and 'id="annual-payers"' in report
assert '<option value="small">Até 2 pagadores</option>' in report
assert 'Trajetórias MIDES' in home and 'Rotatividade anual' in report
assert 'Correlação por consórcio' in report and report.count('class="corr-row"') == 64
assert 'id="corr-search"' in report and 'data-name="CIS/PARANAIBA"' in report
assert 'Ausência de pagamento em um ano foi guardada à parte' not in report
assert 'um ano pequeno não define a entidade' not in report
assert 'Um ano de poucos pagamentos não resume' not in report
assert '<h3>Exemplo: AMVAP Saúde</h3>' in report
assert '<section id="proxima-etapa">' in report
assert 'Modelo A · oferta própria' in report and 'Modelo B · oferta relativa' in report
assert 'Igarapé pagou ao CISMEP em 2019' in report
assert not any(term in report for term in ('Brier', '0,008689', '98,15%', '96,72%'))
print("Site público: Trajetórias MIDES e aba Modelo com resultados conferidos.")
