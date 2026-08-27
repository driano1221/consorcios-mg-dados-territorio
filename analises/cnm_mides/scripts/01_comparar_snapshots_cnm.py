from __future__ import annotations

import re
import hashlib
import json
from pathlib import Path

import pandas as pd


PROJECT = Path(__file__).resolve().parents[3]
ANALYSIS = PROJECT / "analises" / "cnm_mides"
OUTPUT = ANALYSIS / "outputs"
CHECKS = ANALYSIS / "checks"
SNAPSHOTS = Path(r"C:\IPEA\dados cnm\snapshots")
OLD = SNAPSHOTS / "2026-05-14"
NEW = SNAPSHOTS / "2026-08-27"


def read_snapshot(root: Path, name: str) -> pd.DataFrame:
    return pd.read_csv(root / "data" / name, sep=";", encoding="utf-8-sig", dtype=str).fillna("")


def digits(value: object) -> str:
    return re.sub(r"\D+", "", str(value or ""))


def valid_cnpj(value: object) -> bool:
    cnpj = digits(value)
    if len(cnpj) != 14 or len(set(cnpj)) == 1:
        return False
    nums = [int(x) for x in cnpj]
    w1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    w2 = [6] + w1
    d1 = sum(nums[i] * w1[i] for i in range(12)) % 11
    d1 = 0 if d1 < 2 else 11 - d1
    d2 = sum(nums[i] * w2[i] for i in range(13)) % 11
    d2 = 0 if d2 < 2 else 11 - d2
    return nums[12:] == [d1, d2]


def save(df: pd.DataFrame, name: str) -> None:
    df.to_csv(OUTPUT / name, sep=";", index=False, encoding="utf-8-sig")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_manifest(root: Path, snapshot_date: str, cons: pd.DataFrame, rel: pd.DataFrame) -> None:
    core_files = [
        root / "data" / "base_unificada_consorcios_macroareas.csv",
        root / "data" / "municipio_consorcio.csv",
    ]
    manifest = {
        "snapshot_date": snapshot_date,
        "source": "https://consorcios.cnm.org.br/",
        "consorcios": int(len(cons)),
        "municipios_unicos": int(rel["municipio_ibge"].nunique()),
        "vinculos_brutos": int(len(rel)),
        "pares_unicos": int(rel["par"].nunique()),
        "core_files": {
            path.name: {"bytes": path.stat().st_size, "sha256": sha256(path)}
            for path in core_files
        },
    }
    (root / "manifest_snapshot.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )


def field_changes(old: pd.DataFrame, new: pd.DataFrame) -> pd.DataFrame:
    fields = {
        "consorcio_cnpj": "CNPJ",
        "consorcio_nome": "Nome",
        "consorcio_sigla": "Sigla",
        "consorcio_status": "Status",
        "consorcio_situacao_cnpj": "Situacao CNPJ",
        "sede_municipio_ibge": "Sede IBGE",
        "sede_municipio_nome": "Sede nome",
        "sede_municipio_uf": "Sede UF",
        "consorcio_area_atuacao": "Finalidade/tipo",
    }
    both = old.merge(new, on="consorcio_uuid", how="inner", suffixes=("_maio", "_agosto"))
    rows: list[dict[str, str]] = []
    for field, label in fields.items():
        changed = both[both[f"{field}_maio"].astype(str).str.strip() != both[f"{field}_agosto"].astype(str).str.strip()]
        for _, row in changed.iterrows():
            rows.append(
                {
                    "consorcio_uuid": row["consorcio_uuid"],
                    "consorcio_nome_atual": row.get("consorcio_nome_agosto", ""),
                    "campo": label,
                    "valor_maio": row[f"{field}_maio"],
                    "valor_agosto": row[f"{field}_agosto"],
                }
            )
    return pd.DataFrame(rows)


def area_changes(old: pd.DataFrame, new: pd.DataFrame) -> pd.DataFrame:
    area_cols = sorted(set(c for c in old.columns if c.startswith("area_")) & set(c for c in new.columns if c.startswith("area_")))
    both = old[["consorcio_uuid", "consorcio_nome", *area_cols]].merge(
        new[["consorcio_uuid", "consorcio_nome", *area_cols]], on="consorcio_uuid", suffixes=("_maio", "_agosto")
    )
    rows = []
    for _, row in both.iterrows():
        before = {c for c in area_cols if str(row[f"{c}_maio"]) in {"1", "1.0"}}
        after = {c for c in area_cols if str(row[f"{c}_agosto"]) in {"1", "1.0"}}
        if before != after:
            rows.append(
                {
                    "consorcio_uuid": row["consorcio_uuid"],
                    "consorcio_nome": row["consorcio_nome_agosto"],
                    "areas_adicionadas": " | ".join(sorted(after - before)),
                    "areas_removidas": " | ".join(sorted(before - after)),
                    "n_areas_maio": len(before),
                    "n_areas_agosto": len(after),
                }
            )
    return pd.DataFrame(rows)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    CHECKS.mkdir(parents=True, exist_ok=True)

    cons_old = read_snapshot(OLD, "base_unificada_consorcios_macroareas.csv")
    cons_new = read_snapshot(NEW, "base_unificada_consorcios_macroareas.csv")
    rel_old = read_snapshot(OLD, "municipio_consorcio.csv")
    rel_new = read_snapshot(NEW, "municipio_consorcio.csv")

    old_ids, new_ids = set(cons_old.consorcio_uuid), set(cons_new.consorcio_uuid)
    added = cons_new[cons_new.consorcio_uuid.isin(new_ids - old_ids)].copy()
    removed = cons_old[cons_old.consorcio_uuid.isin(old_ids - new_ids)].copy()
    changes = field_changes(cons_old, cons_new)
    areas = area_changes(cons_old, cons_new)

    for df in (rel_old, rel_new):
        df["municipio_ibge"] = df["municipio_ibge"].map(digits)
        df["par"] = df["consorcio_uuid"] + "|" + df["municipio_ibge"]
    old_pairs, new_pairs = set(rel_old.par), set(rel_new.par)
    links_added = rel_new[rel_new.par.isin(new_pairs - old_pairs)].drop(columns="par")
    links_removed = rel_old[rel_old.par.isin(old_pairs - new_pairs)].drop(columns="par")

    cons_new["cnpj_limpo"] = cons_new.consorcio_cnpj.map(digits)
    invalid_cnpj = cons_new[(cons_new.cnpj_limpo != "") & ~cons_new.cnpj_limpo.map(valid_cnpj)]
    duplicated_cnpj = cons_new[(cons_new.cnpj_limpo != "") & cons_new.duplicated("cnpj_limpo", keep=False)]
    # A plataforma CNM entrega o codigo IBGE municipal sem o digito verificador: 6 digitos.
    invalid_ibge = rel_new[~rel_new.municipio_ibge.str.fullmatch(r"\d{6}", na=False)]
    duplicate_links = rel_new[rel_new.duplicated(["consorcio_uuid", "municipio_ibge"], keep=False)].copy()

    write_manifest(OLD, "2026-05-14", cons_old, rel_old)
    write_manifest(NEW, "2026-08-27", cons_new, rel_new)

    summary = pd.DataFrame(
        [
            {"indicador": "consorcios", "maio": len(cons_old), "agosto": len(cons_new), "diferenca": len(cons_new) - len(cons_old)},
            {"indicador": "municipios_unicos", "maio": rel_old.municipio_ibge.nunique(), "agosto": rel_new.municipio_ibge.nunique(), "diferenca": rel_new.municipio_ibge.nunique() - rel_old.municipio_ibge.nunique()},
            {"indicador": "vinculos_brutos", "maio": len(rel_old), "agosto": len(rel_new), "diferenca": len(rel_new) - len(rel_old)},
            {"indicador": "pares_unicos", "maio": len(old_pairs), "agosto": len(new_pairs), "diferenca": len(new_pairs) - len(old_pairs)},
            {"indicador": "consorcios_adicionados", "maio": 0, "agosto": len(added), "diferenca": len(added)},
            {"indicador": "consorcios_removidos", "maio": len(removed), "agosto": 0, "diferenca": -len(removed)},
            {"indicador": "vinculos_adicionados", "maio": 0, "agosto": len(links_added), "diferenca": len(links_added)},
            {"indicador": "vinculos_removidos", "maio": len(links_removed), "agosto": 0, "diferenca": -len(links_removed)},
        ]
    )

    save(summary, "comparacao_snapshots_resumo.csv")
    save(added, "consorcios_adicionados.csv")
    save(removed, "consorcios_removidos.csv")
    save(changes, "mudancas_cadastrais.csv")
    save(areas, "mudancas_areas_atuacao.csv")
    save(links_added, "vinculos_adicionados.csv")
    save(links_removed, "vinculos_removidos.csv")
    save(invalid_cnpj, "auditoria_cnpjs_invalidos.csv")
    save(duplicated_cnpj, "auditoria_cnpjs_repetidos.csv")
    save(invalid_ibge, "auditoria_municipios_ibge_invalidos.csv")
    save(duplicate_links, "auditoria_vinculos_repetidos.csv")

    report = f"""# Comparacao dos snapshots CNM

**Snapshot anterior:** 2026-05-14
**Snapshot atual:** 2026-08-27

## Resumo

{summary.to_markdown(index=False)}

## Mudancas e auditorias

| Item | Registros |
|---|---:|
| Mudancas cadastrais campo a campo | {len(changes)} |
| Consorcios com mudanca de areas | {len(areas)} |
| CNPJs invalidos | {len(invalid_cnpj)} |
| CNPJs repetidos | {len(duplicated_cnpj)} |
| Linhas com IBGE invalido | {len(invalid_ibge)} |
| Linhas em pares repetidos | {len(duplicate_links)} |

Os vinculos sao comparados por `consorcio_uuid + municipio_ibge`. A comparacao identifica mudancas entre fotografias cadastrais; ela nao reconstrui a data exata da entrada ou saida do municipio.
"""
    (CHECKS / "COMPARACAO_SNAPSHOTS_CNM.md").write_text(report, encoding="utf-8")
    print(summary.to_string(index=False))
    print({"mudancas_cadastrais": len(changes), "mudancas_areas": len(areas), "cnpjs_invalidos": len(invalid_cnpj), "linhas_pares_repetidos": len(duplicate_links)})


if __name__ == "__main__":
    main()
