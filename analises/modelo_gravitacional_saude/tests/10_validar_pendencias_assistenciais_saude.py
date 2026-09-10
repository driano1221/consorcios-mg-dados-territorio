"""Verifica integridade temporal/documental e preservacao financeira do dossie."""
import csv
from collections import defaultdict
from decimal import Decimal
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
OUT = BASE / "outputs"


def read(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    assert rows and all(None not in r and None not in r.values() for r in rows), path
    return rows


hist = {(r["cnpj_raiz_8"], r["ano"]): r for r in read(OUT / "cnes_historico_entidades_saude_mg_2014_2021.csv")}
money = defaultdict(lambda: Decimal("0"))
for r in read(OUT / "mides_saude_mg_consolidado_entidade_ano.csv"):
    money[r["cnpj_raiz_8"], r["ano"]] += Decimal(r["valor_total"])
rows = read(OUT / "dossie_91_entidades_ano_sem_fixa.csv")
keys = [(r["cnpj_raiz_8"], r["ano"]) for r in rows]
expected = {key for key, value in money.items() if value > 0 and hist[key]["n_unidades_fixas"] == "0"}
assert len(keys) == len(set(keys)) == 91 and set(keys) == expected
assert len({root for root, year in keys}) == 28
for r in rows:
    key = r["cnpj_raiz_8"], r["ano"]
    assert Decimal(r["valor_mides"]) == money[key]
    assert r["decisao_principal"] == "excluir_da_especificacao_de_destino_fixo"
    assert r["zero_capacidade_autorizado"] == r["sucessao_imputada"] == "FALSE"
    assert not r["cnes_unidades_fixas"]
assert sum(Decimal(r["valor_mides"]) for r in rows) == Decimal("151093325.68")
assert {k for r, k in zip(rows, keys) if r["classificacao"] == "fixa_em_outros_meses_ausente_em_dezembro"} == {
    ("01260691", "2017"), ("64486822", "2017"), ("97550393", "2015")}
priorities = read(OUT / "decisoes_anuais_sete_entidades.csv")
assert len(priorities) == 56
policy = read(BASE / "evidencias/decisoes_sete_entidades_2026_09_10.csv")
historical_units = read(OUT / "cnes_historico_unidades_saude_mg_2014_2021.csv")
assert len(policy) == len({r["cnpj_raiz_8"] for r in policy}) == 7
for r in policy:
    assert r["fonte_url"].startswith("https://")
    actual = {p["ano"] for p in priorities if p["cnpj_raiz_8"] == r["cnpj_raiz_8"] and int(p["n_unidades_fixas"]) > 0}
    documented = set(r["anos_com_polo_cadastral_dezembro"].split(" | ")) if r["anos_com_polo_cadastral_dezembro"] else set()
    assert actual == documented, r["cnpj_raiz_8"]
    fixed_units = [u for u in historical_units if u["cnpj_raiz_8"] == r["cnpj_raiz_8"] and u["unidade_movel"] == "False"]
    assert {u["cnes"] for u in fixed_units} == (set(r["cnes_historicos"].split(" | ")) if r["cnes_historicos"] else set())
    assert {u["codigo_ibge_6"] for u in fixed_units} == (set(r["municipios_ibge_6"].split(" | ")) if r["municipios_ibge_6"] else set())
    assert all(p["fonte_complementar_url"] == r["fonte_url"] for p in priorities if p["cnpj_raiz_8"] == r["cnpj_raiz_8"])
assert not ({"00773222", "07333598"} & {root for root, year in keys})
print("OK: 91 casos reconciliados com MIDES/CNES; 7 decisoes temporalmente consistentes; sem zero ou sucessao imputados.")
