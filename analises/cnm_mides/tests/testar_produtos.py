from __future__ import annotations

import json
from pathlib import Path

import pandas as pd
from PIL import Image, ImageStat


PROJECT = Path(__file__).resolve().parents[3]
ANALYSIS = PROJECT / "analises" / "cnm_mides"
OUTPUT = ANALYSIS / "outputs"
FIGURES = ANALYSIS / "checks" / "figures"
SNAPSHOTS = Path(r"C:\IPEA\dados cnm\snapshots")


def read_csv(name: str) -> pd.DataFrame:
    return pd.read_csv(OUTPUT / name, sep=";", decimal=",", dtype=str).fillna("")


def validate_image(name: str) -> None:
    image = Image.open(FIGURES / name).convert("RGB")
    assert image.width >= 2000 and image.height >= 1000
    assert sum(ImageStat.Stat(image.resize((100, 100))).var) > 100


def main() -> None:
    current_manifest = json.loads((SNAPSHOTS / "2026-08-27" / "manifest_snapshot.json").read_text(encoding="utf-8"))
    assert current_manifest["consorcios"] == 727
    assert current_manifest["pares_unicos"] == 13109

    invalid_ibge = read_csv("auditoria_municipios_ibge_invalidos.csv")
    duplicate_links = read_csv("auditoria_vinculos_repetidos.csv")
    assert len(invalid_ibge) == 0
    assert len(duplicate_links) == 48
    assert duplicate_links.groupby(["consorcio_uuid", "municipio_ibge"]).size().eq(2).all()

    crosswalk = read_csv("crosswalk_cnm_ipea_cnpj.csv")
    assert len(crosswalk) == 727
    assert crosswalk["cnm_uuid"].is_unique
    assert (crosswalk["situacao_pareamento"] == "exato_cnpj").sum() == 655
    automatic = crosswalk["identidade_validada_automaticamente"].str.upper() == "TRUE"
    assert crosswalk.loc[automatic, "cnpj_canonico"].ne("").all()
    assert crosswalk.loc[~automatic, "cnpj_canonico"].eq("").all()

    annual = read_csv("cnm_mides_mg_municipio_consorcio_ano.csv")
    pairs = read_csv("cnm_mides_mg_pares_periodo.csv")
    consortia = read_csv("cnm_mides_mg_resumo_consorcio.csv")
    assert len(annual) == 28283
    assert not annual.duplicated(["cod_ibge_6", "consorcio_chave", "ano"]).any()
    assert sorted(annual["ano"].unique()) == [str(year) for year in range(2014, 2022)]
    assert len(pairs) == 3912
    assert pairs["consorcio_chave"].nunique() == 180
    assert len(consortia) == 180
    assert pairs["situacao_periodo"].value_counts().to_dict() == {
        "CNM + MIDES": 2163,
        "Somente CNM": 914,
        "Somente MIDES": 658,
        "Nao pareado": 177,
    }

    example = pairs[(pairs["cod_ibge_6"] == "310020") & (pairs["sigla_consorcio"] == "COMASF")]
    assert len(example) == 1
    assert example.iloc[0]["situacao_periodo"] == "CNM + MIDES"
    assert example.iloc[0]["anos_mides"] == "2014;2015;2016;2017;2018;2019;2020;2021"

    validate_image("mapa_concordancia_cnm_mides_mg.png")
    validate_image("linha_tempo_cnm_mides_mg.png")
    print("OK: snapshots, auditorias, crosswalk, cotejamento e figuras validados.")


if __name__ == "__main__":
    main()
