# =============================================================================
# 01_materializar_movimentos_mides.R
#
# Materializa a serie anual de movimentos observados no MIDES.
#
# Unidade: municipio x CNPJ do consorcio x ano (2014-2021).
# Presenca observada: valor_total > 0. Essa regra representa pagamento
# observado no MIDES; nao deve ser interpretada como filiacao juridica.
#
# CNPJs de matriz e filial permanecem separados nesta etapa.
# =============================================================================

library(dplyr)
library(tidyr)
library(stringr)
library(readr)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
input_path <- file.path(project_dir, "dados", "processado", "painel_mg_anual.rds")
lookup_path <- file.path(project_dir, "dashboards", "base1_shiny", "data", "mides_municipios_lookup.rds")
out_dir <- file.path(project_dir, "analises", "movimentos_espaciais", "outputs")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_path)) stop("Painel MIDES anual nao encontrado: ", input_path)
if (!file.exists(lookup_path)) stop("Lookup municipal nao encontrado: ", lookup_path)

message("Carregando painel anual MIDES...")
painel <- readRDS(input_path)
municipios <- readRDS(lookup_path) |>
  transmute(
    cod_ibge_6 = str_pad(as.character(cod_ibge_6), width = 6, side = "left", pad = "0"),
    municipio = as.character(municipio)
  )

anos <- seq.int(min(painel$ano, na.rm = TRUE), max(painel$ano, na.rm = TRUE))
regra_presenca <- "valor_total_positivo"

# O painel de origem ja esta agregado por municipio x CNPJ x ano. A agregacao
# defensiva abaixo protege a reexecucao caso o arquivo de origem seja atualizado.
painel_padrao <- painel |>
  transmute(
    cod_ibge_6 = str_sub(as.character(id_municipio), 1, 6),
    cnpj_consorcio = str_pad(as.character(documento_credor), width = 14, side = "left", pad = "0"),
    ano = as.integer(ano),
    valor_corrente = as.numeric(valor_corrente),
    valor_restos = as.numeric(valor_restos),
    valor_total = as.numeric(valor_total),
    n_transacoes = as.integer(n_transacoes),
    tem_pagamento_corrente = as.logical(tem_pagamento_corrente),
    razao_social_mides = as.character(nome_credor_freq)
  ) |>
  summarise(
    valor_corrente = sum(valor_corrente, na.rm = TRUE),
    valor_restos = sum(valor_restos, na.rm = TRUE),
    valor_total = sum(valor_total, na.rm = TRUE),
    n_transacoes = sum(n_transacoes, na.rm = TRUE),
    tem_pagamento_corrente = any(tem_pagamento_corrente, na.rm = TRUE),
    razao_social_mides = first(sort(unique(razao_social_mides[!is.na(razao_social_mides)]))),
    .by = c(cod_ibge_6, cnpj_consorcio, ano)
  )

identidade_cnpj <- painel_padrao |>
  summarise(
    razao_social_mides = first(sort(unique(razao_social_mides[!is.na(razao_social_mides)]))),
    .by = cnpj_consorcio
  )

# Todos os pares observados ao menos uma vez recebem os oito anos da janela.
# Ausencia de linha MIDES e diferente de valor zero explicitamente registrado.
movimentos <- painel_padrao |>
  select(cod_ibge_6, cnpj_consorcio) |>
  distinct() |>
  crossing(ano = anos) |>
  left_join(painel_padrao, by = c("cod_ibge_6", "cnpj_consorcio", "ano")) |>
  left_join(municipios, by = "cod_ibge_6") |>
  left_join(identidade_cnpj, by = "cnpj_consorcio", suffix = c("", "_padrao")) |>
  mutate(
    razao_social_mides = coalesce(razao_social_mides, razao_social_mides_padrao),
    tem_registro_mides = !is.na(valor_total),
    valor_corrente = coalesce(valor_corrente, 0),
    valor_restos = coalesce(valor_restos, 0),
    valor_total = coalesce(valor_total, 0),
    n_transacoes = coalesce(n_transacoes, 0L),
    tem_pagamento_corrente = coalesce(tem_pagamento_corrente, FALSE),
    presente_mides = valor_total > 0,
    regra_presenca = regra_presenca
  ) |>
  select(-razao_social_mides_padrao) |>
  arrange(cnpj_consorcio, cod_ibge_6, ano) |>
  group_by(cod_ibge_6, cnpj_consorcio) |>
  mutate(
    presente_mides_anterior = lag(presente_mides, default = FALSE),
    houve_presenca_anterior = lag(cumany(presente_mides), default = FALSE),
    evento_movimento = case_when(
      ano == min(ano) & presente_mides ~ "base_inicial",
      ano == min(ano) ~ "ausente",
      presente_mides & presente_mides_anterior ~ "permaneceu",
      presente_mides & !presente_mides_anterior & houve_presenca_anterior ~ "retorno_observado",
      presente_mides & !presente_mides_anterior ~ "entrada_observada",
      !presente_mides & presente_mides_anterior ~ "saida_observada",
      TRUE ~ "ausente"
    ),
    delta_presenca = case_when(
      evento_movimento %in% c("entrada_observada", "retorno_observado") ~ 1L,
      evento_movimento == "saida_observada" ~ -1L,
      TRUE ~ 0L
    ),
    primeiro_ano_observado = if_else(any(presente_mides), min(ano[presente_mides]), NA_integer_),
    ultimo_ano_observado = if_else(any(presente_mides), max(ano[presente_mides]), NA_integer_),
    n_entradas_observadas = sum(evento_movimento %in% c("entrada_observada", "retorno_observado")),
    n_saidas_observadas = sum(evento_movimento == "saida_observada"),
    n_transicoes = n_entradas_observadas + n_saidas_observadas,
    movimento_recorrente = n_transicoes >= 2L
  ) |>
  ungroup() |>
  select(
    ano, cod_ibge_6, municipio, cnpj_consorcio, razao_social_mides,
    regra_presenca, tem_registro_mides, presente_mides, presente_mides_anterior,
    tem_pagamento_corrente, valor_corrente, valor_restos, valor_total, n_transacoes,
    evento_movimento, delta_presenca, primeiro_ano_observado, ultimo_ano_observado,
    n_entradas_observadas, n_saidas_observadas, n_transicoes, movimento_recorrente
  )

resumo_par <- movimentos |>
  summarise(
    municipio = first(municipio),
    razao_social_mides = first(razao_social_mides),
    primeiro_ano_observado = first(primeiro_ano_observado),
    ultimo_ano_observado = first(ultimo_ano_observado),
    anos_com_pagamento_observado = sum(presente_mides),
    valor_total_periodo = sum(valor_total),
    n_entradas_observadas = first(n_entradas_observadas),
    n_saidas_observadas = first(n_saidas_observadas),
    n_transicoes = first(n_transicoes),
    movimento_recorrente = first(movimento_recorrente),
    .by = c(cod_ibge_6, cnpj_consorcio)
  ) |>
  arrange(desc(movimento_recorrente), desc(n_transicoes), cnpj_consorcio, cod_ibge_6)

resumo_consorcio_ano <- movimentos |>
  summarise(
    razao_social_mides = first(razao_social_mides),
    pares_ativos = sum(presente_mides),
    pares_base_inicial = sum(evento_movimento == "base_inicial"),
    pares_entraram = sum(evento_movimento %in% c("entrada_observada", "retorno_observado")),
    pares_retornaram = sum(evento_movimento == "retorno_observado"),
    pares_sairam = sum(evento_movimento == "saida_observada"),
    pares_permaneceram = sum(evento_movimento == "permaneceu"),
    saldo_liquido_observado = sum(delta_presenca),
    municipios_ativos = n_distinct(cod_ibge_6[presente_mides]),
    valor_total_mides = sum(valor_total),
    .by = c(ano, cnpj_consorcio)
  ) |>
  arrange(ano, cnpj_consorcio)

resumo_municipio_ano <- movimentos |>
  summarise(
    pares_ativos = sum(presente_mides),
    pares_base_inicial = sum(evento_movimento == "base_inicial"),
    pares_entraram = sum(evento_movimento %in% c("entrada_observada", "retorno_observado")),
    pares_sairam = sum(evento_movimento == "saida_observada"),
    pares_permaneceram = sum(evento_movimento == "permaneceu"),
    saldo_liquido_observado = sum(delta_presenca),
    valor_total_mides = sum(valor_total),
    .by = c(ano, cod_ibge_6, municipio)
  ) |>
  arrange(ano, cod_ibge_6)

write_csv(movimentos, file.path(out_dir, "movimentos_municipio_consorcio_ano.csv"), na = "")
write_csv(resumo_par, file.path(out_dir, "movimentos_resumo_par.csv"), na = "")
write_csv(resumo_consorcio_ano, file.path(out_dir, "movimentos_consorcio_ano.csv"), na = "")
write_csv(resumo_municipio_ano, file.path(out_dir, "movimentos_municipio_ano.csv"), na = "")

saveRDS(movimentos, file.path(out_dir, "movimentos_municipio_consorcio_ano.rds"))
saveRDS(resumo_par, file.path(out_dir, "movimentos_resumo_par.rds"))
saveRDS(resumo_consorcio_ano, file.path(out_dir, "movimentos_consorcio_ano.rds"))
saveRDS(resumo_municipio_ano, file.path(out_dir, "movimentos_municipio_ano.rds"))

message("\nMovimentos MIDES materializados")
message("  Anos: ", min(anos), "-", max(anos))
message("  Pares unicos: ", nrow(resumo_par))
message("  Linhas municipio x CNPJ x ano: ", nrow(movimentos))
message("  Pares com movimento recorrente: ", sum(resumo_par$movimento_recorrente))
message("  Saida: ", out_dir)
