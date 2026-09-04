"""Temporaliza a oferta CNES diretamente vinculada aos consorcios de saude.

Fonte: arquivos mensais disseminados pelo DATASUS/CNES. A fotografia principal
de cada ano e dezembro, para compatibilidade com o painel MIDES anual.

O script nao atribui prestadores indiretos e nao retroage a fotografia atual.
Ele liga ST (estabelecimentos) a LT (leitos), SR (servicos) e PF
(profissionais) pelo codigo CNES e produz uma grade entidade x ano completa.
"""

from __future__ import annotations

import csv
import hashlib
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
from collections import defaultdict
from datetime import datetime
from pathlib import Path

from dbfread import DBF


YEARS = tuple(range(2014, 2022))
TABLES = ("ST", "LT", "SR", "PF")
MOBILE_TYPES = {"32", "40", "42"}
FTP_BASE = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados"

ANALYSIS_DIR = Path(__file__).resolve().parent
REPO_DIR = ANALYSIS_DIR.parents[1]
OUT_DIR = ANALYSIS_DIR / "outputs"
CACHE_DIR = OUT_DIR / "cache_cnes_historico"
UNIVERSE_PATH = OUT_DIR / "universo_saude_mg_entidades.csv"
CURRENT_UNITS_PATH = OUT_DIR / "capacidade_unidades_cnes_saude_mg.csv"

UNIT_OUTPUT = OUT_DIR / "cnes_historico_unidades_saude_mg_2014_2021.csv"
ENTITY_OUTPUT = OUT_DIR / "cnes_historico_entidades_saude_mg_2014_2021.csv"
SUMMARY_OUTPUT = OUT_DIR / "resumo_cnes_historico_saude_mg.csv"
MANIFEST_OUTPUT = OUT_DIR / "manifesto_cnes_historico_saude_mg.csv"
MONTHLY_OUTPUT = OUT_DIR / "cnes_historico_presenca_mensal_saude_mg_2014_2021.csv"


def read_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise FileNotFoundError(f"Arquivo obrigatorio ausente: {path}")
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def digits(value: object, width: int | None = None) -> str:
    text = "" if value is None else "".join(ch for ch in str(value) if ch.isdigit())
    return text.zfill(width) if width and text else text


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def is_positive(value: object) -> bool:
    return as_int(value) > 0


def cnpj_root(value: object, target_roots: set[str]) -> str | None:
    code = digits(value, 14)
    if len(code) != 14 or code == "0" * 14:
        return None
    root = code[:8]
    return root if root in target_roots else None


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download(url: str, destination: Path) -> None:
    if destination.exists() and destination.stat().st_size > 0:
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    partial = destination.with_suffix(destination.suffix + ".part")
    curl = shutil.which("curl.exe") or shutil.which("curl")
    if not curl:
        raise RuntimeError("curl nao encontrado; instale-o ou disponibilize-o no PATH.")
    command = [
        curl,
        "--disable-epsv",
        "--fail",
        "--location",
        "--retry",
        "4",
        "--retry-delay",
        "2",
        "--max-time",
        "900",
        "--silent",
        "--show-error",
        "--output",
        str(partial),
        url,
    ]
    subprocess.run(command, check=True)
    partial.replace(destination)


def locate_blast_dbf() -> Path:
    configured = os.environ.get("BLAST_DBF")
    if configured:
        candidate = Path(configured)
    else:
        try:
            import dbc_reader  # type: ignore
        except ImportError as exc:
            raise RuntimeError(
                "Conversor DBC ausente. Instale requirements_cnes_historico.txt "
                "ou defina BLAST_DBF."
            ) from exc
        candidate = Path(dbc_reader.__file__).resolve().parent / "bin" / "blast-dbf.exe"
    if not candidate.exists():
        raise FileNotFoundError(f"Conversor DBC nao encontrado: {candidate}")
    return candidate


def to_wsl_path(path: Path) -> str:
    resolved = str(path.resolve())
    drive, tail = os.path.splitdrive(resolved)
    if not drive:
        raise ValueError(f"Caminho Windows sem unidade: {resolved}")
    return f"/mnt/{drive[0].lower()}/{tail.lstrip(os.sep).replace(os.sep, '/')}"


def convert_dbc(dbc_path: Path, dbf_path: Path, converter: Path) -> None:
    if os.name == "nt":
        if not shutil.which("wsl"):
            raise RuntimeError("WSL nao encontrado; ele e necessario para o conversor DBC no Windows.")
        shell_command = (
            f"{shlex.quote(to_wsl_path(converter))} < "
            f"{shlex.quote(to_wsl_path(dbc_path))} > {shlex.quote(to_wsl_path(dbf_path))}"
        )
        subprocess.run(["wsl", "bash", "-lc", shell_command], check=True)
    else:
        with dbc_path.open("rb") as source, dbf_path.open("wb") as target:
            subprocess.run([str(converter)], stdin=source, stdout=target, check=True)
    if not dbf_path.exists() or dbf_path.stat().st_size == 0:
        raise RuntimeError(f"Conversao DBC vazia: {dbc_path}")


def dbf_rows(dbc_path: Path, converter: Path):
    with tempfile.TemporaryDirectory(prefix="cnes_dbf_") as temp_dir:
        dbf_path = Path(temp_dir) / dbc_path.with_suffix(".dbf").name
        convert_dbc(dbc_path, dbf_path, converter)
        yield from DBF(
            str(dbf_path),
            load=False,
            encoding="latin1",
            char_decode_errors="ignore",
        )


def source_path(table: str, year: int, month: int = 12) -> tuple[str, Path]:
    competence = f"{str(year)[2:]}{month:02d}"
    filename = f"{table}MG{competence}.dbc"
    url = f"{FTP_BASE}/{table}/{filename}"
    return url, CACHE_DIR / filename


def prepare_sources() -> list[dict]:
    manifest = []
    for year in YEARS:
        periods = [("ST", month) for month in range(1, 13)] + [
            (table, 12) for table in ("LT", "SR", "PF")
        ]
        for table, month in periods:
            url, path = source_path(table, year, month)
            print(f"CNES {year}-{month:02d} {table}: {path.name}", flush=True)
            download(url, path)
            stat = path.stat()
            manifest.append(
                {
                    "ano": year,
                    "competencia": f"{year}{month:02d}",
                    "tabela": table,
                    "arquivo": path.name,
                    "url_origem": url,
                    "tamanho_bytes": stat.st_size,
                    "sha256": file_sha256(path),
                    "data_arquivo_local": datetime.fromtimestamp(stat.st_mtime).isoformat(timespec="seconds"),
                }
            )
    return manifest


def select_establishments(
    dbc_path: Path,
    converter: Path,
    roots: set[str],
    entities: dict[str, dict[str, str]],
    current_names: dict[str, dict[str, str]],
    year: int,
    month: int,
) -> dict[str, dict]:
    selected_units: dict[str, dict] = {}
    for row in dbf_rows(dbc_path, converter):
        own_root = cnpj_root(row.get("CPF_CNPJ"), roots)
        maintainer_root = cnpj_root(row.get("CNPJ_MAN"), roots)
        if not own_root and not maintainer_root:
            continue
        if own_root and maintainer_root and own_root != maintainer_root:
            raise RuntimeError(
                f"CNES {row.get('CNES')} liga duas raizes-alvo distintas: "
                f"{own_root} e {maintainer_root}."
            )
        root = own_root or maintainer_root
        cnes = digits(row.get("CNES"), 7)
        if cnes in selected_units and selected_units[cnes]["cnpj_raiz_8"] != root:
            raise RuntimeError(f"CNES {cnes} duplicado entre entidades em {year}-{month:02d}.")
        current = current_names.get(cnes, {})
        unit_type = digits(row.get("TP_UNID"), 2)
        selected_units[cnes] = {
            "cnpj_raiz_8": root,
            "cnpj_canonico": entities[root].get("cnpj_canonico", ""),
            "sigla_canonica": entities[root].get("sigla_canonica", ""),
            "ano": year,
            "competencia_referencia": f"{year}{month:02d}",
            "cnes": cnes,
            "nome_estabelecimento_snapshot_atual": current.get("nome_estabelecimento_cnes", ""),
            "codigo_ibge_6": digits(row.get("CODUFMUN"), 6),
            "municipio_snapshot_atual": current.get("municipio_cnes", ""),
            "cnpj_proprio_cnes": digits(row.get("CPF_CNPJ"), 14),
            "cnpj_mantenedora_cnes": digits(row.get("CNPJ_MAN"), 14),
            "tipo_vinculo_cnpj": (
                "cnpj_proprio_e_mantenedora"
                if own_root and maintainer_root
                else "cnpj_proprio"
                if own_root
                else "cnpj_mantenedora"
            ),
            "tipo_unidade_codigo": unit_type,
            "unidade_movel": unit_type in MOBILE_TYPES,
            "vinculo_sus": is_positive(row.get("VINC_SUS")),
            "atendimento_ambulatorial": is_positive(row.get("ATENDAMB")),
            "atendimento_hospitalar": is_positive(row.get("ATENDHOS")),
            "competencia_atualizacao_cadastro": digits(row.get("DT_ATUAL"), 6),
        }
    return selected_units


def capacity_by_unit(dbc_path: Path, converter: Path, selected: set[str], table: str) -> dict:
    result: dict[str, dict] = defaultdict(dict)
    if table == "LT":
        for row in dbf_rows(dbc_path, converter):
            cnes = digits(row.get("CNES"), 7)
            if cnes not in selected:
                continue
            item = result[cnes]
            item["leitos_existentes"] = item.get("leitos_existentes", 0) + as_int(row.get("QT_EXIST"))
            item["leitos_sus"] = item.get("leitos_sus", 0) + as_int(row.get("QT_SUS"))
            item.setdefault("tipos_leito", set()).add(digits(row.get("CODLEITO")))
    elif table == "SR":
        for row in dbf_rows(dbc_path, converter):
            cnes = digits(row.get("CNES"), 7)
            if cnes not in selected:
                continue
            item = result[cnes]
            service = f"{digits(row.get('SERV_ESP'))}:{digits(row.get('CLASS_SR'))}"
            item.setdefault("servicos", set()).add(service)
            if is_positive(row.get("AMB_SUS")) or is_positive(row.get("HOSP_SUS")):
                item.setdefault("servicos_sus", set()).add(service)
    elif table == "PF":
        for row in dbf_rows(dbc_path, converter):
            cnes = digits(row.get("CNES"), 7)
            if cnes not in selected:
                continue
            item = result[cnes]
            cbo = digits(row.get("CBO"))
            person = digits(row.get("CNS_PROF")) or str(row.get("CPF_PROF") or "").strip()
            if cbo:
                item.setdefault("cbos", set()).add(cbo)
            if person:
                item.setdefault("profissionais", set()).add(person)
            if is_positive(row.get("PROF_SUS")):
                if cbo:
                    item.setdefault("cbos_sus", set()).add(cbo)
                    if cbo.startswith("225"):
                        item.setdefault("cbos_medicos_sus", set()).add(cbo)
                if person:
                    item.setdefault("profissionais_sus", set()).add(person)
                item["carga_horaria_sus"] = item.get("carga_horaria_sus", 0) + sum(
                    as_int(row.get(field)) for field in ("HORAOUTR", "HORAHOSP", "HORA_AMB")
                )
    else:
        raise ValueError(f"Tabela de capacidade desconhecida: {table}")
    return result


def merge_set(target: set, source: object) -> None:
    if isinstance(source, set):
        target.update(source)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    universe_rows = read_csv(UNIVERSE_PATH)
    entities = {row["cnpj_raiz_8"].zfill(8): row for row in universe_rows}
    if len(entities) != 84:
        raise RuntimeError(f"Esperadas 84 entidades; encontradas {len(entities)}.")
    roots = set(entities)

    current_names: dict[str, dict[str, str]] = {}
    if CURRENT_UNITS_PATH.exists():
        for row in read_csv(CURRENT_UNITS_PATH):
            current_names[digits(row.get("cnes"), 7)] = row

    converter = locate_blast_dbf()
    manifest = prepare_sources()
    unit_rows: list[dict] = []
    entity_year: dict[tuple[str, int], dict] = {}
    monthly_presence: dict[tuple[str, int, str], dict] = {}
    selected_by_period: dict[tuple[int, int], dict[str, dict]] = {}

    for year in YEARS:
        for month in range(1, 13):
            _, st_path = source_path("ST", year, month)
            selected = select_establishments(
                st_path, converter, roots, entities, current_names, year, month
            )
            selected_by_period[(year, month)] = selected
            for cnes, unit in selected.items():
                key = (unit["cnpj_raiz_8"], year, cnes)
                item = monthly_presence.setdefault(
                    key,
                    {
                        "cnpj_raiz_8": unit["cnpj_raiz_8"],
                        "cnpj_canonico": unit["cnpj_canonico"],
                        "sigla_canonica": unit["sigla_canonica"],
                        "ano": year,
                        "cnes": cnes,
                        "meses": set(),
                        "meses_fixa": set(),
                        "tipos_unidade": set(),
                        "codigos_ibge": set(),
                    },
                )
                item["meses"].add(month)
                item["tipos_unidade"].add(unit["tipo_unidade_codigo"])
                item["codigos_ibge"].add(unit["codigo_ibge_6"])
                if not unit["unidade_movel"]:
                    item["meses_fixa"].add(month)
        print(f"Presenca mensal CNES concluida: {year}", flush=True)

    for root, entity in entities.items():
        for year in YEARS:
            entity_year[(root, year)] = {
                "cnpj_raiz_8": root,
                "cnpj_canonico": entity.get("cnpj_canonico", ""),
                "sigla_canonica": entity.get("sigla_canonica", ""),
                "razao_social_canonica": entity.get("razao_social_canonica", ""),
                "ano": year,
                "competencia_referencia": f"{year}12",
                "unidades": set(),
                "unidades_fixas": set(),
                "unidades_moveis": set(),
                "municipios_fixas": set(),
                "leitos_existentes": 0,
                "leitos_sus": 0,
                "tipos_leito": set(),
                "servicos": set(),
                "servicos_sus": set(),
                "cbos": set(),
                "cbos_sus": set(),
                "cbos_medicos_sus": set(),
                "profissionais": set(),
                "profissionais_sus": set(),
                "carga_horaria_sus": 0,
            }

    for year in YEARS:
        selected_units = selected_by_period[(year, 12)]

        selected = set(selected_units)
        capacities = {}
        for table in ("LT", "SR", "PF"):
            _, table_path = source_path(table, year)
            capacities[table] = capacity_by_unit(table_path, converter, selected, table)

        for cnes, unit in selected_units.items():
            beds = capacities["LT"].get(cnes, {})
            services = capacities["SR"].get(cnes, {})
            professionals = capacities["PF"].get(cnes, {})
            unit.update(
                {
                    "leitos_existentes": beds.get("leitos_existentes", 0),
                    "leitos_sus": beds.get("leitos_sus", 0),
                    "n_tipos_leito": len(beds.get("tipos_leito", set())),
                    "n_servicos_especializados": len(services.get("servicos", set())),
                    "n_servicos_especializados_sus": len(services.get("servicos_sus", set())),
                    "n_cbo_distintos": len(professionals.get("cbos", set())),
                    "n_cbo_sus_distintos": len(professionals.get("cbos_sus", set())),
                    "n_cbo_medicos_sus_distintos": len(professionals.get("cbos_medicos_sus", set())),
                    "n_profissionais_distintos": len(professionals.get("profissionais", set())),
                    "n_profissionais_sus_distintos": len(professionals.get("profissionais_sus", set())),
                    "carga_horaria_sus": professionals.get("carga_horaria_sus", 0),
                }
            )
            unit_rows.append(unit)

            aggregate = entity_year[(unit["cnpj_raiz_8"], year)]
            aggregate["unidades"].add(cnes)
            if unit["unidade_movel"]:
                aggregate["unidades_moveis"].add(cnes)
                continue
            aggregate["unidades_fixas"].add(cnes)
            aggregate["municipios_fixas"].add(unit["codigo_ibge_6"])
            aggregate["leitos_existentes"] += unit["leitos_existentes"]
            aggregate["leitos_sus"] += unit["leitos_sus"]
            aggregate["carga_horaria_sus"] += unit["carga_horaria_sus"]
            merge_set(aggregate["tipos_leito"], beds.get("tipos_leito"))
            merge_set(aggregate["servicos"], services.get("servicos"))
            merge_set(aggregate["servicos_sus"], services.get("servicos_sus"))
            for key in (
                "cbos",
                "cbos_sus",
                "cbos_medicos_sus",
                "profissionais",
                "profissionais_sus",
            ):
                merge_set(aggregate[key], professionals.get(key))
        print(f"Capacidade de dezembro concluida: {year}", flush=True)

    monthly_rows = []
    monthly_entity: dict[tuple[str, int], dict[str, set]] = defaultdict(
        lambda: {"unidades": set(), "unidades_fixas": set(), "meses_fixa": set()}
    )
    for key in sorted(monthly_presence):
        item = monthly_presence[key]
        monthly_rows.append(
            {
                "cnpj_raiz_8": item["cnpj_raiz_8"],
                "cnpj_canonico": item["cnpj_canonico"],
                "sigla_canonica": item["sigla_canonica"],
                "ano": item["ano"],
                "cnes": item["cnes"],
                "n_meses_presente": len(item["meses"]),
                "meses_presente": " | ".join(f"{month:02d}" for month in sorted(item["meses"])),
                "n_meses_como_unidade_fixa": len(item["meses_fixa"]),
                "meses_como_unidade_fixa": " | ".join(
                    f"{month:02d}" for month in sorted(item["meses_fixa"])
                ),
                "tipos_unidade_codigo": " | ".join(sorted(item["tipos_unidade"])),
                "codigos_ibge_6": " | ".join(sorted(item["codigos_ibge"])),
            }
        )
        entity_item = monthly_entity[(item["cnpj_raiz_8"], item["ano"])]
        entity_item["unidades"].add(item["cnes"])
        if item["meses_fixa"]:
            entity_item["unidades_fixas"].add(item["cnes"])
            entity_item["meses_fixa"].update(item["meses_fixa"])

    entity_rows: list[dict] = []
    for key in sorted(entity_year):
        item = entity_year[key]
        fixed = len(item["unidades_fixas"])
        total = len(item["unidades"])
        annual_presence = monthly_entity[(item["cnpj_raiz_8"], item["ano"])]
        row = {
            "cnpj_raiz_8": item["cnpj_raiz_8"],
            "cnpj_canonico": item["cnpj_canonico"],
            "sigla_canonica": item["sigla_canonica"],
            "razao_social_canonica": item["razao_social_canonica"],
            "ano": item["ano"],
            "competencia_referencia": item["competencia_referencia"],
            "n_unidades_cnes": total,
            "n_unidades_fixas": fixed,
            "n_unidades_moveis": len(item["unidades_moveis"]),
            "n_unidades_cnes_algum_mes": len(annual_presence["unidades"]),
            "n_unidades_fixas_algum_mes": len(annual_presence["unidades_fixas"]),
            "n_meses_com_unidade_fixa": len(annual_presence["meses_fixa"]),
            "dezembro_sem_fixa_mas_algum_mes_com_fixa": (
                fixed == 0 and bool(annual_presence["unidades_fixas"])
            ),
            "n_municipios_oferta_fixa": len(item["municipios_fixas"]),
            "cnes_unidades_fixas": " | ".join(sorted(item["unidades_fixas"])),
            "codigos_ibge_oferta_fixa": " | ".join(sorted(item["municipios_fixas"])),
            "status_cobertura_dezembro": (
                "estrutura_fixa_direta_cnes"
                if fixed
                else "somente_unidade_movel"
                if total
                else "sem_unidade_cnes_direta_na_competencia"
            ),
            "leitos_existentes_rede_direta": item["leitos_existentes"] if fixed else "",
            "leitos_sus_rede_direta": item["leitos_sus"] if fixed else "",
            "n_tipos_leito_rede_direta": len(item["tipos_leito"]) if fixed else "",
            "n_servicos_especializados_rede_direta": len(item["servicos"]) if fixed else "",
            "n_servicos_especializados_sus_rede_direta": len(item["servicos_sus"]) if fixed else "",
            "n_cbo_rede_direta": len(item["cbos"]) if fixed else "",
            "n_cbo_sus_rede_direta": len(item["cbos_sus"]) if fixed else "",
            "n_cbo_medicos_sus_rede_direta": len(item["cbos_medicos_sus"]) if fixed else "",
            "n_profissionais_rede_direta": len(item["profissionais"]) if fixed else "",
            "n_profissionais_sus_rede_direta": len(item["profissionais_sus"]) if fixed else "",
            "carga_horaria_sus_rede_direta": item["carga_horaria_sus"] if fixed else "",
            "regra_temporal": "fotografia_cnes_dezembro",
            "fonte": "DATASUS/CNES ST+LT+SR+PF",
        }
        entity_rows.append(row)

    unit_fields = [
        "cnpj_raiz_8", "cnpj_canonico", "sigla_canonica", "ano",
        "competencia_referencia", "cnes", "nome_estabelecimento_snapshot_atual",
        "codigo_ibge_6", "municipio_snapshot_atual", "cnpj_proprio_cnes",
        "cnpj_mantenedora_cnes", "tipo_vinculo_cnpj", "tipo_unidade_codigo",
        "unidade_movel", "vinculo_sus", "atendimento_ambulatorial",
        "atendimento_hospitalar", "competencia_atualizacao_cadastro",
        "leitos_existentes", "leitos_sus", "n_tipos_leito",
        "n_servicos_especializados", "n_servicos_especializados_sus",
        "n_cbo_distintos", "n_cbo_sus_distintos", "n_cbo_medicos_sus_distintos",
        "n_profissionais_distintos", "n_profissionais_sus_distintos", "carga_horaria_sus",
    ]
    entity_fields = list(entity_rows[0])
    manifest_fields = list(manifest[0])
    write_csv(UNIT_OUTPUT, sorted(unit_rows, key=lambda x: (x["ano"], x["cnpj_raiz_8"], x["cnes"])), unit_fields)
    write_csv(ENTITY_OUTPUT, entity_rows, entity_fields)
    write_csv(MONTHLY_OUTPUT, monthly_rows, list(monthly_rows[0]))
    write_csv(MANIFEST_OUTPUT, manifest, manifest_fields)

    summary_rows = []
    for year in YEARS:
        rows = [row for row in entity_rows if row["ano"] == year]
        units = [row for row in unit_rows if row["ano"] == year]
        summary_rows.append(
            {
                "ano": year,
                "entidades_universo": len(rows),
                "entidades_com_unidade": sum(row["n_unidades_cnes"] > 0 for row in rows),
                "entidades_com_unidade_fixa": sum(row["n_unidades_fixas"] > 0 for row in rows),
                "entidades_com_unidade_fixa_algum_mes": sum(
                    row["n_unidades_fixas_algum_mes"] > 0 for row in rows
                ),
                "entidades_dezembro_sem_fixa_mas_algum_mes_com_fixa": sum(
                    row["dezembro_sem_fixa_mas_algum_mes_com_fixa"] for row in rows
                ),
                "entidades_somente_moveis": sum(row["status_cobertura_dezembro"] == "somente_unidade_movel" for row in rows),
                "unidades_cnes": len(units),
                "unidades_fixas": sum(not row["unidade_movel"] for row in units),
                "unidades_moveis": sum(row["unidade_movel"] for row in units),
                "leitos_sus_rede_direta": sum(
                    int(row["leitos_sus_rede_direta"] or 0) for row in rows
                ),
                "servicos_especializados_sus_distintos_somados": sum(
                    int(row["n_servicos_especializados_sus_rede_direta"] or 0) for row in rows
                ),
                "profissionais_sus_distintos_somados": sum(
                    int(row["n_profissionais_sus_rede_direta"] or 0) for row in rows
                ),
            }
        )
    write_csv(SUMMARY_OUTPUT, summary_rows, list(summary_rows[0]))

    print(
        f"OK: {len(entity_rows)} entidades-ano, {len(unit_rows)} unidades-ano e "
        f"{len(manifest)} arquivos oficiais registrados."
    )


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        print(f"Falha em comando externo: {exc}", file=sys.stderr)
        raise
