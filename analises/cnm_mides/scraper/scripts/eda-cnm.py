from __future__ import annotations

import json
import math
import os
import re
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ROOT = Path(os.environ.get("CNM_WORKDIR", PROJECT_ROOT)).resolve()
DATA = ROOT / "data"
REPORTS = ROOT / "reports" / "eda"
TABLES = REPORTS / "tables"
FIGURES = REPORTS / "figures"


AREA_PREFIX = "area_"
KEY_CONSORCIO = "consorcio_uuid"
KEY_MUNICIPIO = "municipio_ibge"


def read_csv(name: str) -> pd.DataFrame:
    return pd.read_csv(DATA / name, sep=";", encoding="utf-8-sig")


def write_csv(df: pd.DataFrame, name: str) -> None:
    df.to_csv(TABLES / name, sep=";", index=False, encoding="utf-8-sig")


def md_table(df: pd.DataFrame, max_rows: int = 20) -> str:
    if df.empty:
        return "_Sem registros._"
    view = df.head(max_rows).copy()
    return view.to_markdown(index=False, disable_numparse=True)


def fmt_int(value: float | int) -> str:
    if pd.isna(value):
        return ""
    return f"{int(value):,}".replace(",", ".")


def fmt_pct(value: float) -> str:
    if pd.isna(value):
        return ""
    return f"{value:.1%}".replace(".", ",")


def clean_cnpj(value: object) -> str:
    return re.sub(r"\D+", "", "" if pd.isna(value) else str(value))


def is_valid_cnpj(value: object) -> bool:
    cnpj = clean_cnpj(value)
    if len(cnpj) != 14 or len(set(cnpj)) == 1:
        return False
    nums = [int(x) for x in cnpj]
    weights_1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    weights_2 = [6] + weights_1
    d1 = sum(nums[i] * weights_1[i] for i in range(12)) % 11
    d1 = 0 if d1 < 2 else 11 - d1
    d2 = sum(nums[i] * weights_2[i] for i in range(13)) % 11
    d2 = 0 if d2 < 2 else 11 - d2
    return nums[12] == d1 and nums[13] == d2


def safe_slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")


def save_bar(df: pd.DataFrame, x: str, y: str, title: str, filename: str, horizontal: bool = True) -> None:
    plt.figure(figsize=(11, max(4.5, min(14, 0.35 * len(df) + 2))))
    if horizontal:
        sns.barplot(data=df, x=y, y=x, color="#0072B2")
        plt.xlabel(y)
        plt.ylabel("")
    else:
        sns.barplot(data=df, x=x, y=y, color="#0072B2")
        plt.xticks(rotation=45, ha="right")
        plt.xlabel("")
        plt.ylabel(y)
    plt.title(title)
    plt.tight_layout()
    plt.savefig(FIGURES / filename, dpi=180)
    plt.close()


def save_hist(series: pd.Series, title: str, xlabel: str, filename: str, bins: int = 30) -> None:
    plt.figure(figsize=(10, 5.5))
    sns.histplot(series.dropna(), bins=bins, color="#009E73")
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel("Frequência")
    plt.tight_layout()
    plt.savefig(FIGURES / filename, dpi=180)
    plt.close()


def summarize_dataset(name: str, df: pd.DataFrame) -> dict:
    return {
        "base": name,
        "linhas": len(df),
        "colunas": df.shape[1],
        "celulas": int(df.shape[0] * df.shape[1]),
        "celulas_nulas": int(df.isna().sum().sum()),
        "pct_celulas_nulas": df.isna().sum().sum() / max(df.shape[0] * df.shape[1], 1),
        "linhas_duplicadas_exatas": int(df.duplicated().sum()),
    }


def missingness(df: pd.DataFrame, base: str) -> pd.DataFrame:
    out = pd.DataFrame(
        {
            "base": base,
            "coluna": df.columns,
            "tipo": [str(df[c].dtype) for c in df.columns],
            "nulos": [int(df[c].isna().sum()) for c in df.columns],
            "pct_nulos": [df[c].isna().mean() for c in df.columns],
            "unicos": [int(df[c].nunique(dropna=True)) for c in df.columns],
            "pct_unicos": [df[c].nunique(dropna=True) / max(len(df), 1) for c in df.columns],
        }
    )
    return out.sort_values(["pct_nulos", "unicos"], ascending=[False, False])


def top_values(df: pd.DataFrame, column: str, n: int = 20) -> pd.DataFrame:
    counts = df[column].value_counts(dropna=False).head(n).reset_index()
    counts.columns = [column, "linhas"]
    counts["pct"] = counts["linhas"] / len(df)
    return counts


def main() -> None:
    TABLES.mkdir(parents=True, exist_ok=True)
    FIGURES.mkdir(parents=True, exist_ok=True)
    sns.set_theme(style="whitegrid")

    cons = read_csv("base_unificada_consorcios.csv")
    vinc = read_csv("base_unificada_municipio_consorcio.csv")
    mun = read_csv("municipios.csv")
    rel = read_csv("municipio_consorcio.csv")
    areas_dict = read_csv("dicionario_areas_pivot.csv")

    area_cols = [c for c in cons.columns if c.startswith(AREA_PREFIX)]
    non_area_cols = [c for c in cons.columns if c not in area_cols]

    inventory = pd.DataFrame(
        [
            summarize_dataset("base_unificada_consorcios", cons),
            summarize_dataset("base_unificada_municipio_consorcio", vinc),
            summarize_dataset("municipios", mun),
            summarize_dataset("municipio_consorcio", rel),
            summarize_dataset("dicionario_areas_pivot", areas_dict),
        ]
    )
    write_csv(inventory, "inventario_bases.csv")

    miss = pd.concat(
        [
            missingness(cons, "base_unificada_consorcios"),
            missingness(vinc, "base_unificada_municipio_consorcio"),
            missingness(mun, "municipios"),
            missingness(rel, "municipio_consorcio"),
        ],
        ignore_index=True,
    )
    write_csv(miss, "nulos_cardinalidade_colunas.csv")

    cons_key_dup = cons[cons.duplicated(KEY_CONSORCIO, keep=False)].sort_values(KEY_CONSORCIO)
    vinc_pair_dup = vinc[vinc.duplicated([KEY_CONSORCIO, KEY_MUNICIPIO], keep=False)].sort_values(
        [KEY_CONSORCIO, KEY_MUNICIPIO]
    )
    mun_key_dup = mun[mun.duplicated("ibge", keep=False)].sort_values("ibge")
    rel_pair_dup = rel[rel.duplicated(["consorcio_uuid", "municipio_ibge"], keep=False)].sort_values(
        ["consorcio_uuid", "municipio_ibge"]
    )

    write_csv(cons_key_dup, "duplicatas_chave_consorcios.csv")
    write_csv(vinc_pair_dup, "duplicatas_chave_vinculos_base_unificada.csv")
    write_csv(mun_key_dup, "duplicatas_chave_municipios.csv")
    write_csv(rel_pair_dup, "duplicatas_chave_municipio_consorcio.csv")

    linked_uuids = set(vinc[KEY_CONSORCIO].dropna())
    cons_sem_vinculo = cons[~cons[KEY_CONSORCIO].isin(linked_uuids)].copy()
    write_csv(
        cons_sem_vinculo[
            [
                KEY_CONSORCIO,
                "consorcio_id",
                "consorcio_nome",
                "consorcio_sigla",
                "consorcio_cnpj",
                "sede_municipio_nome",
                "sede_municipio_uf",
                "quantidade_municipios",
                "quantidade_areas",
            ]
        ],
        "consorcios_sem_vinculo_municipal.csv",
    )

    vinc_count = vinc.groupby(KEY_CONSORCIO, dropna=False).agg(
        linhas_vinculo=("municipio_ibge", "size"),
        municipios_unicos_vinculo=("municipio_ibge", "nunique"),
    )
    consistency = cons.merge(vinc_count, left_on=KEY_CONSORCIO, right_index=True, how="left")
    consistency["linhas_vinculo"] = consistency["linhas_vinculo"].fillna(0).astype(int)
    consistency["municipios_unicos_vinculo"] = consistency["municipios_unicos_vinculo"].fillna(0).astype(int)
    consistency["soma_areas_pivot"] = cons[area_cols].sum(axis=1).astype(int)
    consistency["diff_qtd_municipios_linhas"] = consistency["quantidade_municipios"] - consistency["linhas_vinculo"]
    consistency["diff_qtd_municipios_unicos"] = consistency["quantidade_municipios"] - consistency["municipios_unicos_vinculo"]
    consistency["diff_qtd_areas_pivot"] = consistency["quantidade_areas"] - consistency["soma_areas_pivot"]
    consistency_issues = consistency[
        (consistency["diff_qtd_municipios_linhas"] != 0)
        | (consistency["diff_qtd_municipios_unicos"] != 0)
        | (consistency["diff_qtd_areas_pivot"] != 0)
    ].copy()
    write_csv(
        consistency_issues[
            [
                KEY_CONSORCIO,
                "consorcio_nome",
                "consorcio_sigla",
                "quantidade_municipios",
                "linhas_vinculo",
                "municipios_unicos_vinculo",
                "diff_qtd_municipios_linhas",
                "diff_qtd_municipios_unicos",
                "quantidade_areas",
                "soma_areas_pivot",
                "diff_qtd_areas_pivot",
            ]
        ],
        "inconsistencias_contagens.csv",
    )

    repeated_inside = vinc_pair_dup[
        [
            KEY_CONSORCIO,
            "consorcio_nome",
            "consorcio_sigla",
            "municipio_ibge",
            "municipio_nome",
            "municipio_uf",
        ]
    ].copy()
    write_csv(repeated_inside, "municipios_repetidos_no_mesmo_consorcio.csv")

    cons["cnpj_limpo"] = cons["consorcio_cnpj"].map(clean_cnpj)
    cons["cnpj_valido"] = cons["consorcio_cnpj"].map(is_valid_cnpj)
    invalid_cnpj = cons[(cons["consorcio_cnpj"].notna()) & (~cons["cnpj_valido"])].copy()
    duplicated_cnpj = cons[
        (cons["cnpj_limpo"] != "") & cons.duplicated("cnpj_limpo", keep=False)
    ].sort_values("cnpj_limpo")
    write_csv(
        invalid_cnpj[[KEY_CONSORCIO, "consorcio_nome", "consorcio_sigla", "consorcio_cnpj", "cnpj_limpo"]],
        "cnpjs_invalidos.csv",
    )
    write_csv(
        duplicated_cnpj[[KEY_CONSORCIO, "consorcio_nome", "consorcio_sigla", "consorcio_cnpj", "cnpj_limpo"]],
        "cnpjs_repetidos.csv",
    )

    dates = pd.to_datetime(cons["consorcio_data_constituicao"], errors="coerce")
    date_issues = cons[
        cons["consorcio_data_constituicao"].notna()
        & (dates.isna() | (dates.dt.year < 1900) | (dates > pd.Timestamp.today()))
    ].copy()
    write_csv(
        date_issues[[KEY_CONSORCIO, "consorcio_nome", "consorcio_sigla", "consorcio_data_constituicao"]],
        "datas_constituicao_suspeitas.csv",
    )

    url_pattern = re.compile(r"^https?://", flags=re.I)
    site_missing = cons["consorcio_site"].isna().sum()
    site_invalid = cons[
        cons["consorcio_site"].notna() & ~cons["consorcio_site"].astype(str).str.match(url_pattern)
    ].copy()
    write_csv(
        site_invalid[[KEY_CONSORCIO, "consorcio_nome", "consorcio_sigla", "consorcio_site"]],
        "sites_formato_suspeito.csv",
    )

    areas_summary = pd.DataFrame(
        {
            "coluna": area_cols,
            "consorcios": [int(cons[c].sum()) for c in area_cols],
            "pct_consorcios": [cons[c].mean() for c in area_cols],
        }
    ).merge(areas_dict, left_on="coluna", right_on="column", how="left")
    areas_summary = areas_summary[["id", "nome", "coluna", "consorcios", "pct_consorcios"]].sort_values(
        "consorcios", ascending=False
    )
    write_csv(areas_summary, "areas_frequencia_consorcios.csv")

    cons_by_region = (
        cons["sede_regiao"].value_counts(dropna=False).rename_axis("sede_regiao").reset_index(name="consorcios")
    )
    vinc_by_region = (
        vinc["municipio_regiao"].value_counts(dropna=False).rename_axis("municipio_regiao").reset_index(name="vinculos")
    )
    mun_by_region = (
        mun["uf"]
        .map(
            {
                "AC": "Norte",
                "AL": "Nordeste",
                "AM": "Norte",
                "AP": "Norte",
                "BA": "Nordeste",
                "CE": "Nordeste",
                "DF": "Centro-Oeste",
                "ES": "Sudeste",
                "GO": "Centro-Oeste",
                "MA": "Nordeste",
                "MG": "Sudeste",
                "MS": "Centro-Oeste",
                "MT": "Centro-Oeste",
                "PA": "Norte",
                "PB": "Nordeste",
                "PE": "Nordeste",
                "PI": "Nordeste",
                "PR": "Sul",
                "RJ": "Sudeste",
                "RN": "Nordeste",
                "RO": "Norte",
                "RR": "Norte",
                "RS": "Sul",
                "SC": "Sul",
                "SE": "Nordeste",
                "SP": "Sudeste",
                "TO": "Norte",
            }
        )
        .value_counts(dropna=False)
        .rename_axis("municipio_regiao")
        .reset_index(name="municipios")
    )
    write_csv(cons_by_region, "consorcios_por_regiao_sede.csv")
    write_csv(vinc_by_region, "vinculos_por_regiao_municipio.csv")
    write_csv(mun_by_region, "municipios_por_regiao.csv")

    vinc_by_uf = vinc["municipio_uf"].value_counts().rename_axis("uf").reset_index(name="vinculos")
    cons_sede_by_uf = cons["sede_municipio_uf"].value_counts().rename_axis("uf").reset_index(name="consorcios_sede")
    mun_by_uf = mun["uf"].value_counts().rename_axis("uf").reset_index(name="municipios")
    uf_summary = vinc_by_uf.merge(cons_sede_by_uf, on="uf", how="outer").merge(mun_by_uf, on="uf", how="outer").fillna(0)
    for c in ["vinculos", "consorcios_sede", "municipios"]:
        uf_summary[c] = uf_summary[c].astype(int)
    uf_summary["vinculos_por_municipio"] = uf_summary["vinculos"] / uf_summary["municipios"].replace(0, np.nan)
    uf_summary = uf_summary.sort_values("vinculos", ascending=False)
    write_csv(uf_summary, "resumo_por_uf.csv")

    mun_participation = (
        vinc.groupby(["municipio_ibge", "municipio_nome", "municipio_uf", "municipio_regiao"])
        .agg(consorcios_participa=(KEY_CONSORCIO, "nunique"), linhas=("consorcio_uuid", "size"))
        .reset_index()
        .sort_values(["consorcios_participa", "linhas"], ascending=False)
    )
    write_csv(mun_participation, "municipios_por_qtd_consorcios.csv")

    cons_size = (
        consistency[
            [
                KEY_CONSORCIO,
                "consorcio_nome",
                "consorcio_sigla",
                "sede_municipio_uf",
                "quantidade_municipios",
                "municipios_unicos_vinculo",
                "quantidade_areas",
                "populacao_atendida",
                "abrangencia_territorial",
            ]
        ]
        .copy()
        .sort_values("quantidade_municipios", ascending=False)
    )
    write_csv(cons_size, "consorcios_por_tamanho.csv")

    # Outliers by IQR for main numeric fields.
    outlier_rows = []
    for column in ["quantidade_municipios", "quantidade_areas", "populacao_atendida", "abrangencia_territorial"]:
        s = pd.to_numeric(cons[column], errors="coerce").dropna()
        if s.empty:
            continue
        q1, q3 = s.quantile([0.25, 0.75])
        iqr = q3 - q1
        low, high = q1 - 1.5 * iqr, q3 + 1.5 * iqr
        flagged = cons[(pd.to_numeric(cons[column], errors="coerce") < low) | (pd.to_numeric(cons[column], errors="coerce") > high)]
        for _, row in flagged.iterrows():
            outlier_rows.append(
                {
                    "coluna": column,
                    "limite_inferior_iqr": low,
                    "limite_superior_iqr": high,
                    KEY_CONSORCIO: row[KEY_CONSORCIO],
                    "consorcio_nome": row["consorcio_nome"],
                    "consorcio_sigla": row["consorcio_sigla"],
                    "valor": row[column],
                }
            )
    outliers = pd.DataFrame(outlier_rows)
    write_csv(outliers, "outliers_iqr.csv")

    # Figures.
    save_bar(cons_by_region, "sede_regiao", "consorcios", "Consórcios por região da sede", "consorcios_por_regiao_sede.png")
    save_bar(vinc_by_region, "municipio_regiao", "vinculos", "Vínculos por região do município", "vinculos_por_regiao_municipio.png")
    save_bar(uf_summary.sort_values("vinculos", ascending=True), "uf", "vinculos", "Vínculos por UF", "vinculos_por_uf.png")
    save_bar(
        areas_summary.head(20).sort_values("consorcios", ascending=True),
        "nome",
        "consorcios",
        "Top 20 áreas de atuação por quantidade de consórcios",
        "top20_areas_atuacao.png",
    )
    save_hist(cons["quantidade_municipios"], "Distribuição do tamanho dos consórcios", "Municípios por consórcio", "hist_municipios_por_consorcio.png")
    save_hist(mun_participation["consorcios_participa"], "Distribuição de participação municipal", "Consórcios por município", "hist_consorcios_por_municipio.png", bins=20)

    plt.figure(figsize=(10, 6))
    scatter_df = cons.dropna(subset=["quantidade_municipios", "populacao_atendida"]).copy()
    sns.scatterplot(data=scatter_df, x="quantidade_municipios", y="populacao_atendida", hue="sede_regiao", alpha=0.75)
    plt.yscale("log")
    plt.title("População atendida x quantidade de municípios")
    plt.xlabel("Municípios por consórcio")
    plt.ylabel("População atendida (escala log)")
    plt.tight_layout()
    plt.savefig(FIGURES / "scatter_populacao_municipios.png", dpi=180)
    plt.close()

    top_area_cols = areas_summary.head(25)["coluna"].tolist()
    if len(top_area_cols) > 1:
        corr = cons[top_area_cols].corr()
        labels = areas_summary.set_index("coluna").loc[top_area_cols, "id"].astype(str).tolist()
        plt.figure(figsize=(12, 10))
        sns.heatmap(corr, cmap="vlag", center=0, xticklabels=labels, yticklabels=labels, square=True)
        plt.title("Correlação entre as 25 áreas mais frequentes (rótulo = id da área)")
        plt.tight_layout()
        plt.savefig(FIGURES / "heatmap_correlacao_areas_top25.png", dpi=180)
        plt.close()

    # Text summaries.
    status_counts = top_values(cons, "consorcio_status")
    situacao_counts = top_values(cons, "consorcio_situacao_cnpj")
    natureza_counts = top_values(cons, "consorcio_natureza_juridica")
    area_tipo_counts = top_values(cons, "consorcio_area_atuacao")

    for name, df in [
        ("status_consorcios.csv", status_counts),
        ("situacao_cnpj_consorcios.csv", situacao_counts),
        ("natureza_juridica_consorcios.csv", natureza_counts),
        ("area_atuacao_macro_consorcios.csv", area_tipo_counts),
    ]:
        write_csv(df, name)

    numeric_summary = cons[
        ["quantidade_municipios", "quantidade_areas", "populacao_atendida", "abrangencia_territorial"]
    ].describe(percentiles=[0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99]).T.reset_index(names="variavel")
    write_csv(numeric_summary, "resumo_numerico_consorcios.csv")

    key_findings = [
        {
            "item": "Consórcios na base cadastral",
            "valor": len(cons),
            "observacao": "Unidade: uma linha por consórcio.",
        },
        {
            "item": "Consórcios com vínculo municipal",
            "valor": vinc[KEY_CONSORCIO].nunique(),
            "observacao": "A base de vínculo não cobre consórcios sem municípios associados.",
        },
        {
            "item": "Consórcios sem vínculo municipal",
            "valor": len(cons_sem_vinculo),
            "observacao": "Devem ser analisados como cadastro incompleto ou consórcio sem municípios informados.",
        },
        {
            "item": "Municípios únicos",
            "valor": mun["ibge"].nunique(),
            "observacao": "Total esperado conforme painel do site.",
        },
        {
            "item": "Vínculos município-consórcio",
            "valor": len(vinc),
            "observacao": "Unidade: uma linha por par município-consórcio; há duplicatas de par.",
        },
        {
            "item": "Pares município-consórcio duplicados",
            "valor": int(vinc.duplicated([KEY_CONSORCIO, KEY_MUNICIPIO]).sum()),
            "observacao": "Indica município repetido dentro do mesmo consórcio.",
        },
        {
            "item": "CNPJs inválidos por dígito verificador",
            "valor": len(invalid_cnpj),
            "observacao": "Pode ser erro de preenchimento no cadastro de origem.",
        },
        {
            "item": "CNPJs repetidos",
            "valor": duplicated_cnpj["cnpj_limpo"].nunique(),
            "observacao": "Mesmo CNPJ associado a mais de um registro de consórcio.",
        },
        {
            "item": "Sites ausentes",
            "valor": int(site_missing),
            "observacao": "Campo vazio em cadastro do consórcio.",
        },
        {
            "item": "Datas de constituição suspeitas",
            "valor": len(date_issues),
            "observacao": "Datas inválidas, futuras ou anteriores a 1900.",
        },
    ]
    findings_df = pd.DataFrame(key_findings)
    write_csv(findings_df, "achados_principais.csv")

    figures = [
        "consorcios_por_regiao_sede.png",
        "vinculos_por_regiao_municipio.png",
        "vinculos_por_uf.png",
        "top20_areas_atuacao.png",
        "hist_municipios_por_consorcio.png",
        "hist_consorcios_por_municipio.png",
        "scatter_populacao_municipios.png",
        "heatmap_correlacao_areas_top25.png",
    ]

    report = f"""# EDA da Base CNM de Consórcios Públicos

Data da análise: 2026-05-21
Fonte local analisada: `data/`

## Escopo

Esta EDA verifica estrutura, chaves, duplicatas, nulos, cardinalidade, consistência entre bases, distribuições, outliers e padrões espaciais por UF/região. A base geográfica disponível no projeto não contém polígonos ou coordenadas municipais; por isso, a exploração espacial aqui usa UF e região.

## Inventário das bases

{md_table(inventory.assign(**{
    "linhas": inventory["linhas"].map(fmt_int),
    "colunas": inventory["colunas"].map(fmt_int),
    "celulas": inventory["celulas"].map(fmt_int),
    "celulas_nulas": inventory["celulas_nulas"].map(fmt_int),
    "pct_celulas_nulas": inventory["pct_celulas_nulas"].map(fmt_pct),
    "linhas_duplicadas_exatas": inventory["linhas_duplicadas_exatas"].map(fmt_int),
}), 10)}

## Achados principais

{md_table(findings_df.assign(valor=findings_df["valor"].map(fmt_int)), 20)}

## Qualidade de chaves e duplicatas

| Verificação | Resultado |
|---|---:|
| Duplicatas de `consorcio_uuid` na base por consórcio | {fmt_int(len(cons_key_dup))} |
| Duplicatas de `ibge` em `municipios.csv` | {fmt_int(len(mun_key_dup))} |
| Linhas duplicadas por par `consorcio_uuid` + `municipio_ibge` na base unificada de vínculos | {fmt_int(len(vinc_pair_dup))} |
| Linhas duplicadas por par `consorcio_uuid` + `municipio_ibge` em `municipio_consorcio.csv` | {fmt_int(len(rel_pair_dup))} |

Arquivos de auditoria:

- `reports/eda/tables/duplicatas_chave_consorcios.csv`
- `reports/eda/tables/duplicatas_chave_municipios.csv`
- `reports/eda/tables/duplicatas_chave_vinculos_base_unificada.csv`
- `reports/eda/tables/municipios_repetidos_no_mesmo_consorcio.csv`

## Consistência entre bases

Foram comparadas as contagens declaradas na ficha do consórcio com:

- número de linhas na base de vínculos;
- número de municípios únicos vinculados;
- soma das 60 colunas binárias de áreas.

Registros com alguma divergência: **{fmt_int(len(consistency_issues))}**.

Arquivo detalhado: `reports/eda/tables/inconsistencias_contagens.csv`

Principais divergências:

{md_table(consistency_issues[[
    KEY_CONSORCIO,
    "consorcio_sigla",
    "quantidade_municipios",
    "linhas_vinculo",
    "municipios_unicos_vinculo",
    "diff_qtd_municipios_unicos",
    "quantidade_areas",
    "soma_areas_pivot",
    "diff_qtd_areas_pivot",
]].head(15), 15)}

## Nulos e cardinalidade

Tabela completa: `reports/eda/tables/nulos_cardinalidade_colunas.csv`

Colunas com maior percentual de nulos na base por consórcio:

{md_table(miss[miss["base"].eq("base_unificada_consorcios")].head(15).assign(
    pct_nulos=lambda x: x["pct_nulos"].map(fmt_pct),
    pct_unicos=lambda x: x["pct_unicos"].map(fmt_pct),
), 15)}

## Distribuições cadastrais

### Status

{md_table(status_counts.assign(pct=status_counts["pct"].map(fmt_pct)), 20)}

### Situação CNPJ

{md_table(situacao_counts.assign(pct=situacao_counts["pct"].map(fmt_pct)), 20)}

### Área de atuação macro

{md_table(area_tipo_counts.assign(pct=area_tipo_counts["pct"].map(fmt_pct)), 20)}

### Natureza jurídica inferida

{md_table(natureza_counts.assign(pct=natureza_counts["pct"].map(fmt_pct)), 20)}

## Resumo numérico

{md_table(numeric_summary.round(2), 20)}

## Maiores consórcios por quantidade de municípios

{md_table(cons_size.head(20), 20)}

## Municípios com maior número de participações

{md_table(mun_participation.head(20), 20)}

## Áreas de atuação

Total de áreas pivotadas: **{fmt_int(len(area_cols))}**.

Top 20 áreas:

{md_table(areas_summary.head(20).assign(pct_consorcios=areas_summary.head(20)["pct_consorcios"].map(fmt_pct)), 20)}

## Exploração espacial por UF e região

Resumo por UF: `reports/eda/tables/resumo_por_uf.csv`

Top UFs por vínculos:

{md_table(uf_summary.head(15).assign(vinculos_por_municipio=lambda x: x["vinculos_por_municipio"].round(2)), 15)}

## Outliers

Outliers foram marcados pelo método IQR em `quantidade_municipios`, `quantidade_areas`, `populacao_atendida` e `abrangencia_territorial`.

Total de linhas sinalizadas: **{fmt_int(len(outliers))}**.

Arquivo detalhado: `reports/eda/tables/outliers_iqr.csv`

## Figuras

""" + "\n".join([f"![{f}](figures/{f})" for f in figures]) + """

## Interpretação técnica

1. A base `base_unificada_consorcios.csv` é a referência cadastral para os 728 consórcios.
2. A base `base_unificada_municipio_consorcio.csv` é a referência analítica para vínculos, mas não cobre os 55 consórcios sem municípios vinculados.
3. Há pares município-consórcio duplicados. Isso afeta contagens simples de vínculos e deve ser tratado antes de análises de rede ou mapas.
4. Campos inferidos a partir das respostas da ficha técnica, como natureza jurídica e tipo de sede, têm alto volume de nulos. Eles são úteis, mas não devem ser assumidos como preenchimento censitário.
5. A análise espacial municipal completa exigiria anexar uma malha geográfica oficial por código IBGE. Com os dados atuais, a granularidade espacial segura é UF/região.
"""
    (REPORTS / "EDA_CNM.md").write_text(report, encoding="utf-8")

    print(
        json.dumps(
            {
                "report": str(REPORTS / "EDA_CNM.md"),
                "tables": str(TABLES),
                "figures": str(FIGURES),
                "consorcios": len(cons),
                "vinculos": len(vinc),
                "municipios": mun["ibge"].nunique(),
                "consorcios_sem_vinculo": len(cons_sem_vinculo),
                "duplicatas_pares_vinculo": int(vinc.duplicated([KEY_CONSORCIO, KEY_MUNICIPIO]).sum()),
                "inconsistencias_contagens": len(consistency_issues),
                "cnpjs_invalidos": len(invalid_cnpj),
                "cnpjs_repetidos": int(duplicated_cnpj["cnpj_limpo"].nunique()),
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
