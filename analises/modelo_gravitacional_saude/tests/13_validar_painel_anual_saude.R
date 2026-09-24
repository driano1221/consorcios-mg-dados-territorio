# Valida conservacao financeira, temporalidade e separacao de escopos.
suppressPackageStartupMessages(library(dplyr))
Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8")
model <- normalizePath(file.path(getwd(), "analises/modelo_gravitacional_saude"),
  winslash = "/")
out <- file.path(model, "outputs")
p <- readRDS(file.path(out, "painel_anual_integrado_saude_mg_2014_2021.rds"))
old <- readRDS(file.path(out, "painel_analitico_saude_mg.rds"))

stopifnot(nrow(p) == 853L * 97L * 8L,
  !anyDuplicated(p[c("id_municipio", "cnpj_raiz_8", "ano")]),
  n_distinct(p$cnpj_raiz_8) == 97L,
  n_distinct(p$id_municipio) == 853L,
  abs(sum(p$valor_total[p$origem_universo == "original_84"]) -
    sum(old$valor_total)) < .01,
  all(!is.na(p$populacao_ibge)),
  all(is.na(p$tempo_minimo_min[!p$clinica_direta_dezembro])),
  all(is.na(p$leitos_sus_clinicos[!p$clinica_direta_dezembro])),
  all(is.na(p$regiao_saude[p$ano < 2019L])),
  all(!is.na(p$regiao_saude[p$ano >= 2019L])),
  all(is.na(p$rcl_municipal[p$ano == 2014L])),
  all(!p$alternativa_90min_diagnostica | p$alternativa_direta_com_tempo),
  all(!p$alternativa_direta_com_tempo | p$alternativa_cadastral_saude),
  all(!p$universo_intensidade_principal |
    (p$presente_mides & p$alternativa_direta_com_tempo)),
  all(!p$risco_entrada_com_tempo_t_1 |
    (p$risco_primeiro_pagamento & p$ano > 2014L)),
  all(!p$risco_interrupcao_com_tempo_t_1 |
    (p$risco_interrupcao & p$ano > 2014L)))
stopifnot(nrow(p |> filter(!is.na(decisao_destino_fixo_anual)) |>
  distinct(cnpj_raiz_8, ano)) == 91L,
  nrow(p |> filter(!is.na(decisao_sete_prioritarias)) |>
    distinct(cnpj_raiz_8, ano)) == 56L)

igarape <- p |> filter(cod_ibge_6 == "313010", cnpj_raiz_8 == "05802877", ano == 2019L)
stopifnot(nrow(igarape) == 1L,
  abs(igarape$valor_total - 4740790.51) < .01,
  igarape$n_destinos_clinicos_dezembro == 2L,
  igarape$tempo_minimo_min > 0,
  igarape$tempo_minimo_t_1 == p$tempo_minimo_min[
    p$cod_ibge_6 == "313010" & p$cnpj_raiz_8 == "05802877" & p$ano == 2018L])

ciesp <- p |> filter(cnpj_raiz_8 == "07356999")
stopifnot(nrow(ciesp) == 853L * 8L,
  abs(sum(ciesp$valor_total) - 37349881.30) < .01,
  all(ciesp$grupo_escopo == "saude_candidata_documental"))
cimbaje <- p |> filter(cnpj_raiz_8 == "07306549")
stopifnot(all(cimbaje$grupo_escopo == "multiarea_sensibilidade"),
  !any(cimbaje$alternativa_cadastral_saude))
cimams <- p |> filter(cnpj_raiz_8 == "21505692")
stopifnot(!any(cimams$clinica_direta_dezembro),
  all(is.na(cimams$tempo_minimo_min)))
cat("OK: painel anual conserva MIDES, respeita CNES historico e separa alternativas.\n")
