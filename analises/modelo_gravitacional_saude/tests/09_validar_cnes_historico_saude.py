"""Validacao estrutural da camada historica anual CNES."""

from __future__ import annotations

import csv
from pathlib import Path


ANALYSIS_DIR = Path(__file__).resolve().parents[1]
OUT_DIR = ANALYSIS_DIR / "outputs"


def read(name: str) -> list[dict[str, str]]:
    path = OUT_DIR / name
    assert path.exists(), f"Arquivo ausente: {path}"
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


entities = read("cnes_historico_entidades_saude_mg_2014_2021.csv")
units = read("cnes_historico_unidades_saude_mg_2014_2021.csv")
manifest = read("manifesto_cnes_historico_saude_mg.csv")
monthly = read("cnes_historico_presenca_mensal_saude_mg_2014_2021.csv")

assert len(entities) == 84 * 8
assert len({(row["cnpj_raiz_8"], row["ano"]) for row in entities}) == len(entities)
assert len({(row["cnpj_raiz_8"], row["ano"], row["cnes"]) for row in units}) == len(units)
assert {int(row["ano"]) for row in entities} == set(range(2014, 2022))
assert all(row["competencia_referencia"] == f'{row["ano"]}12' for row in entities)
assert all(row["competencia_referencia"] == f'{row["ano"]}12' for row in units)

assert len(manifest) == 8 * 15
assert len({(row["competencia"], row["tabela"]) for row in manifest}) == len(manifest)
assert {(int(row["ano"]), row["tabela"]) for row in manifest} == {
    (year, table) for year in range(2014, 2022) for table in ("ST", "LT", "SR", "PF")
}
assert {
    (f"{year}{month:02d}", "ST") for year in range(2014, 2022) for month in range(1, 13)
} <= {(row["competencia"], row["tabela"]) for row in manifest}
assert {
    (f"{year}12", table)
    for year in range(2014, 2022)
    for table in ("LT", "SR", "PF")
} <= {(row["competencia"], row["tabela"]) for row in manifest}
assert all(len(row["sha256"]) == 64 for row in manifest)
assert len({(row["cnpj_raiz_8"], row["ano"], row["cnes"]) for row in monthly}) == len(monthly)
assert all(1 <= int(row["n_meses_presente"]) <= 12 for row in monthly)
assert all(0 <= int(row["n_meses_como_unidade_fixa"]) <= 12 for row in monthly)

mobile_types = {"32", "40", "42"}
for row in units:
    assert (row["unidade_movel"] == "True") == (row["tipo_unidade_codigo"] in mobile_types)
    assert row["tipo_vinculo_cnpj"] in {
        "cnpj_proprio", "cnpj_mantenedora", "cnpj_proprio_e_mantenedora"
    }
    assert row["codigo_ibge_6"].startswith("31")
    assert int(row["leitos_sus"]) <= int(row["leitos_existentes"])

for row in entities:
    fixed = int(row["n_unidades_fixas"])
    capacity_fields = (
        "leitos_existentes_rede_direta",
        "leitos_sus_rede_direta",
        "n_servicos_especializados_sus_rede_direta",
        "n_profissionais_sus_rede_direta",
    )
    if fixed == 0:
        assert all(row[field] == "" for field in capacity_fields)
    else:
        assert all(row[field] != "" for field in capacity_fields)

for forbidden in ("NOMEPROF", "CNS_PROF", "CPF_PROF", "nome_profissional"):
    assert all(forbidden not in row for row in units)

december_keys = {(row["cnpj_raiz_8"], row["ano"], row["cnes"]) for row in units}
monthly_keys = {(row["cnpj_raiz_8"], row["ano"], row["cnes"]) for row in monthly}
assert december_keys <= monthly_keys

print(
    f"OK: camada historica validada com {len(entities)} entidades-ano, "
    f"{len(units)} unidades-ano e {len(manifest)} arquivos-fonte."
)
