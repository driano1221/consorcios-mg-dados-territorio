"""Complemento do passo cientifico 3: decisoes anuais sem imputar capacidade.

Executar com Python 3.11+, de qualquer pasta. Usa somente a biblioteca padrao
e os produtos existentes dos scripts 07/09. Nao altera fontes nem o painel.
"""
import csv
from collections import defaultdict, Counter
from decimal import Decimal
from pathlib import Path

BASE = Path(__file__).resolve().parent
OUT = BASE / "outputs"


def read(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def write(name, rows):
    with (OUT / name).open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def main():
    hist = read(OUT / "cnes_historico_entidades_saude_mg_2014_2021.csv")
    policies = {r["cnpj_raiz_8"]: r for r in read(BASE / "evidencias/decisoes_sete_entidades_2026_09_10.csv")}
    payments = defaultdict(lambda: Decimal("0"))
    municipalities = defaultdict(set)
    for r in read(OUT / "mides_saude_mg_consolidado_entidade_ano.csv"):
        key = (r["cnpj_raiz_8"], r["ano"])
        value = Decimal(r["valor_total"])
        payments[key] += value
        if value > 0:
            municipalities[key].add(r["id_municipio"])
    first = {}
    for r in hist:
        if int(r["n_unidades_fixas_algum_mes"]):
            root = r["cnpj_raiz_8"]
            first[root] = min(first.get(root, 9999), int(r["ano"]))
    dossier, priority = [], []
    for r in hist:
        root, year = r["cnpj_raiz_8"], r["ano"]
        key = (root, year)
        fixed = int(r["n_unidades_fixas"])
        some = int(r["n_unidades_fixas_algum_mes"])
        policy = policies.get(root, {})
        if fixed:
            category = "polo_cadastral_dezembro_confirmado"
        elif some:
            category = "fixa_em_outros_meses_ausente_em_dezembro"
        elif root in {"00840724", "02287790"}:
            category = "historica_sem_polo_documentado"
        elif root == "97550393" and year == "2021":
            category = "samu_regulacao_documentada_sem_polo_fixo"
        elif root == "23866705":
            category = "implantacao_planejada_operacao_nao_comprovada"
        elif first.get(root, 0) > int(year):
            category = "sem_vinculo_no_ano_com_registro_fixo_posterior"
        else:
            category = "sem_evidencia_suficiente_de_polo_no_ano"
        row = {k: r[k] for k in (
            "cnpj_raiz_8", "sigla_canonica", "ano", "competencia_referencia",
            "n_unidades_fixas", "n_unidades_moveis", "n_unidades_fixas_algum_mes",
            "n_meses_com_unidade_fixa", "cnes_unidades_fixas", "codigos_ibge_oferta_fixa")}
        row.update(valor_mides=str(payments[key]), n_municipios_pagadores=len(municipalities[key]),
            primeiro_ano_fixo_observado=first.get(root, ""), classificacao=category,
            decisao_principal="candidato_com_filtro_assistencial_pendente" if fixed else "excluir_da_especificacao_de_destino_fixo",
            decisao_sensibilidade="usar_capacidade_do_proprio_ano" if fixed else (
                "usar_presenca_mensal_sem_imputar_capacidade_de_dezembro" if some else "manter_pagamentos_sem_imputar_polo_ou_capacidade"),
            zero_capacidade_autorizado="FALSE", sucessao_imputada="FALSE",
            fonte_local="cnes_historico_entidades_saude_mg_2014_2021.csv; cnes_historico_presenca_mensal_saude_mg_2014_2021.csv; manifesto_cnes_historico_saude_mg.csv",
            fonte_complementar_url=policy.get("fonte_url", ""),
            limite_documental=policy.get("alcance_da_evidencia", "Ausencia de vinculo direto ao CNPJ nao prova ausencia de oferta. Registro posterior nao comprova cadastro tardio nem operacao anterior."),
            pendencia=policy.get("pendencia", "Localizar prestador e vigencia em fontes documentais; ate la preservar exclusao/sensibilidade explicita."),
            data_auditoria="2026-09-10")
        if root in policies:
            priority.append(row)
        if payments[key] > 0 and not fixed:
            dossier.append(row)
    grouped = []
    for root in sorted({r["cnpj_raiz_8"] for r in dossier}):
        rows = [r for r in dossier if r["cnpj_raiz_8"] == root]
        grouped.append(dict(cnpj_raiz_8=root, sigla_canonica=rows[0]["sigla_canonica"],
            anos=" | ".join(r["ano"] for r in rows), n_entidades_ano=len(rows),
            valor_mides=str(sum((Decimal(r["valor_mides"]) for r in rows), Decimal("0"))),
            classificacoes=" | ".join(sorted({r["classificacao"] for r in rows})),
            decisao="Exclusao da especificacao principal de destino fixo; preservar pagamentos e sensibilidades documentadas.",
            pesquisa_documental="prioritaria_executada_com_limites_registrados" if root in policies else "triagem_cnes_concluida_pesquisa_documental_individual_pendente"))
    assert len(dossier) == 91 and len(grouped) == 28 and len(priority) == 56
    write("dossie_91_entidades_ano_sem_fixa.csv", dossier)
    write("resumo_28_entidades_sem_fixa.csv", grouped)
    write("decisoes_anuais_sete_entidades.csv", priority)
    print("91 entidades-ano / 28 entidades; 56 decisoes anuais para 7 prioritarias.")
    print(dict(Counter(r["classificacao"] for r in dossier)))
    print("MIDES dos 91 casos:", sum((Decimal(r["valor_mides"]) for r in dossier), Decimal("0")))


if __name__ == "__main__":
    main()
