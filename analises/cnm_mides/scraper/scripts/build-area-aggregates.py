from __future__ import annotations

import re
import os
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ROOT = Path(os.environ.get("CNM_WORKDIR", PROJECT_ROOT)).resolve()
DATA = ROOT / "data"
REPORT_TABLES = ROOT / "reports" / "eda" / "tables"


EIXO_BY_GRUPO = {
    "Agricultura": "Agricultura",
    "Assistência Social": "Social, educação e cultura",
    "Cultura": "Social, educação e cultura",
    "Defesa Civil": "Segurança e defesa civil",
    "Desenvolvimento Econômico": "Desenvolvimento e gestão",
    "Desenvolvimento Regional": "Desenvolvimento e gestão",
    "Educação": "Social, educação e cultura",
    "Elaboração de Projetos e Captação de Recursos": "Desenvolvimento e gestão",
    "Escola de Governo": "Desenvolvimento e gestão",
    "Esportes": "Social, educação e cultura",
    "Habitação": "Social, educação e cultura",
    "Iluminação Pública": "Infraestrutura, território e mobilidade",
    "Infraestrutura": "Infraestrutura, território e mobilidade",
    "Licitação Compartilhada": "Desenvolvimento e gestão",
    "Meio Ambiente": "Meio ambiente e saneamento",
    "Municípios Inteligentes": "Tecnologia e municípios inteligentes",
    "Planejamento Urbano": "Infraestrutura, território e mobilidade",
    "Saneamento": "Meio ambiente e saneamento",
    "Mobilidade": "Infraestrutura, território e mobilidade",
    "Trânsito": "Infraestrutura, território e mobilidade",
    "Previdência": "Previdência",
    "Saúde": "Saúde",
    "Segurança Pública": "Segurança e defesa civil",
    "Tecnologia": "Tecnologia e municípios inteligentes",
    "Turismo": "Turismo",
    "Outra": "Outra",
}


def read_csv(name: str) -> pd.DataFrame:
    return pd.read_csv(DATA / name, sep=";", encoding="utf-8-sig")


def write_csv(df: pd.DataFrame, name: str) -> None:
    df.to_csv(DATA / name, sep=";", index=False, encoding="utf-8-sig")


def write_report_csv(df: pd.DataFrame, name: str) -> None:
    REPORT_TABLES.mkdir(parents=True, exist_ok=True)
    df.to_csv(REPORT_TABLES / name, sep=";", index=False, encoding="utf-8-sig")


def slug(text: str) -> str:
    import unicodedata

    normalized = unicodedata.normalize("NFD", text)
    ascii_text = "".join(ch for ch in normalized if unicodedata.category(ch) != "Mn")
    return re.sub(r"[^a-z0-9]+", "_", ascii_text.lower()).strip("_")


def area_group(nome: str) -> str:
    text = str(nome).strip()
    if "(" in text:
        return text.split("(", 1)[0].strip()
    if text == "Infraestrutura Asfáltica":
        return "Infraestrutura"
    return text


def main() -> None:
    areas = read_csv("dicionario_areas_pivot.csv")
    cons = read_csv("base_unificada_consorcios.csv")
    vinc = read_csv("base_unificada_municipio_consorcio.csv")

    areas["area_grupo"] = areas["nome"].map(area_group)
    areas["area_eixo"] = areas["area_grupo"].map(EIXO_BY_GRUPO).fillna(areas["area_grupo"])
    areas["coluna_grupo"] = "grupo_area_" + areas["area_grupo"].map(slug)
    areas["coluna_eixo"] = "eixo_area_" + areas["area_eixo"].map(slug)

    for df in [cons, vinc]:
        for group, sub in areas.groupby("coluna_grupo"):
            df[group] = df[sub["column"].tolist()].max(axis=1)
        for eixo, sub in areas.groupby("coluna_eixo"):
            df[eixo] = df[sub["column"].tolist()].max(axis=1)
        group_cols = sorted(areas["coluna_grupo"].unique())
        eixo_cols = sorted(areas["coluna_eixo"].unique())
        df["qtd_grupos_area"] = df[group_cols].sum(axis=1)
        df["qtd_eixos_area"] = df[eixo_cols].sum(axis=1)

    write_csv(areas[["id", "nome", "column", "area_grupo", "coluna_grupo", "area_eixo", "coluna_eixo"]], "dicionario_areas_agregadas.csv")
    write_csv(cons, "base_unificada_consorcios_macroareas.csv")
    write_csv(vinc, "base_unificada_municipio_consorcio_macroareas.csv")

    for level, name_col, binary_col in [
        ("grupo", "area_grupo", "coluna_grupo"),
        ("eixo", "area_eixo", "coluna_eixo"),
    ]:
        rows = []
        for name, sub in areas.groupby(name_col):
            col = sub[binary_col].iloc[0]
            rows.append(
                {
                    level: name,
                    "qtd_subareas": len(sub),
                    "consorcios": int(cons[col].sum()),
                    "pct_consorcios": cons[col].mean(),
                    "vinculos": int(vinc[col].sum()),
                    "pct_vinculos": vinc[col].mean(),
                }
            )
        summary = pd.DataFrame(rows).sort_values("consorcios", ascending=False)
        write_report_csv(summary, f"areas_por_{level}_agregado.csv")

    eixo_rows = []
    for eixo, sub in areas.groupby("area_eixo"):
        col = sub["coluna_eixo"].iloc[0]
        for tipo, count in cons.groupby("consorcio_area_atuacao", dropna=False)[col].sum().items():
            eixo_rows.append({"area_eixo": eixo, "consorcio_area_atuacao": tipo, "consorcios": int(count)})
    write_report_csv(pd.DataFrame(eixo_rows), "tipo_consorcio_por_eixo_area.csv")

    print(
        {
            "areas": len(areas),
            "grupos": areas["area_grupo"].nunique(),
            "eixos": areas["area_eixo"].nunique(),
            "base_unificada_consorcios_macroareas": cons.shape,
            "base_unificada_municipio_consorcio_macroareas": vinc.shape,
        }
    )


if __name__ == "__main__":
    main()
