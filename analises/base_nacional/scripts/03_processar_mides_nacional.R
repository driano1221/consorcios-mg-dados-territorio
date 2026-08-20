# =============================================================================
# 03_processar_mides_nacional.R
#
# Agrega o MIDES em duas camadas auditaveis:
#   1. municipio pagador x CNPJ original x ano;
#   2. municipio pagador x raiz canonica do consorcio x ano.
# A segunda camada soma matriz e filiais sem perder os CNPJs de origem.
# =============================================================================

invisible(Sys.setlocale("LC_ALL", "Portuguese_Brazil.1252"))

library(dplyr)
library(stringr)

project_dir <- "."
out_dir <- file.path(project_dir, "analises", "base_nacional", "outputs")

raw_path <- file.path(out_dir, "mides_ipea_nacional_transacoes.rds")
crosswalk_path <- file.path(out_dir, "crosswalk_cnpj_matriz_filial_nacional.rds")
if (!file.exists(raw_path)) stop("Execute primeiro 02_baixar_mides_nacional.R")
if (!file.exists(crosswalk_path)) stop("Crosswalk CNPJ nao encontrado.")

collapse_values <- function(x) {
  x <- sort(unique(na.omit(as.character(x))))
  x <- x[nzchar(x)]
  if (length(x) == 0L) NA_character_ else paste(x, collapse = " | ")
}

mode_text <- function(x) {
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(x)]
  if (length(x) == 0L) return(NA_character_)
  tab <- sort(table(x), decreasing = TRUE)
  names(tab)[1]
}

safe_year <- function(year, flag, fn = min) {
  valid <- flag %in% TRUE & !is.na(year)
  if (!any(valid)) return(NA_integer_)
  as.integer(fn(year[valid]))
}

mides <- readRDS(raw_path)
crosswalk <- readRDS(crosswalk_path)

mides_identificado <- mides |>
  mutate(
    cnpj_original = str_pad(as.character(documento_credor), 14, pad = "0"),
    pagamento_corrente = indicador_restos_pagar %in% FALSE,
    pagamento_restos = indicador_restos_pagar %in% TRUE,
    indicador_restos_ausente = is.na(indicador_restos_pagar),
    chave_municipal_valida = !is.na(id_municipio) & nzchar(id_municipio) & !is.na(ano) & !is.na(sigla_uf)
  ) |>
  left_join(
    crosswalk |>
      select(
        cnpj_original, cnpj_raiz_8, cnpj_canonico, cnpj_matriz,
        tipo_estabelecimento, razao_social_canonica, sigla_canonica,
        uf_sede_canonica, municipio_sede_canonico,
        n_estabelecimentos, n_filiais
      ),
    by = "cnpj_original"
  )

if (any(is.na(mides_identificado$cnpj_canonico))) stop("Ha transacao sem identidade canonica.")

registros_sem_chave_municipal <- mides_identificado |>
  filter(!chave_municipal_valida) |>
  select(
    sigla_uf, ano, data, id_municipio, nome_credor,
    cnpj_original, cnpj_raiz_8, cnpj_canonico,
    indicador_restos_pagar, fonte, valor_final, valor_liquido_recebido
  )

mides_analitico <- mides_identificado |>
  filter(chave_municipal_valida)

painel_original <- mides_analitico |>
  summarise(
    cnpj_raiz_8 = first(cnpj_raiz_8),
    cnpj_canonico = first(cnpj_canonico),
    tipo_estabelecimento = first(tipo_estabelecimento),
    razao_social_canonica = first(razao_social_canonica),
    sigla_canonica = first(sigla_canonica),
    uf_sede_canonica = first(uf_sede_canonica),
    nome_credor_freq = mode_text(nome_credor),
    valor_corrente = sum(valor_final[pagamento_corrente], na.rm = TRUE),
    valor_restos = sum(valor_final[pagamento_restos], na.rm = TRUE),
    valor_indicador_restos_ausente = sum(valor_final[indicador_restos_ausente], na.rm = TRUE),
    valor_total = sum(valor_final, na.rm = TRUE),
    valor_liquido_recebido = sum(valor_liquido_recebido, na.rm = TRUE),
    n_transacoes = n(),
    tem_pagamento_corrente = any(pagamento_corrente),
    .by = c(sigla_uf, id_municipio, cnpj_original, ano)
  ) |>
  rename(uf_municipio_pagador = sigla_uf) |>
  arrange(uf_municipio_pagador, id_municipio, cnpj_original, ano)

painel_consolidado <- painel_original |>
  summarise(
    cnpj_canonico = first(cnpj_canonico),
    razao_social_canonica = first(razao_social_canonica),
    sigla_canonica = first(sigla_canonica),
    uf_sede_canonica = first(uf_sede_canonica),
    cnpjs_originais_observados = collapse_values(cnpj_original),
    tipos_estabelecimento_observados = collapse_values(tipo_estabelecimento),
    nomes_credores_observados = collapse_values(nome_credor_freq),
    n_cnpjs_originais_observados = n_distinct(cnpj_original),
    valor_corrente = sum(valor_corrente, na.rm = TRUE),
    valor_restos = sum(valor_restos, na.rm = TRUE),
    valor_indicador_restos_ausente = sum(valor_indicador_restos_ausente, na.rm = TRUE),
    valor_total = sum(valor_total, na.rm = TRUE),
    valor_liquido_recebido = sum(valor_liquido_recebido, na.rm = TRUE),
    n_transacoes = sum(n_transacoes),
    tem_pagamento_corrente = any(tem_pagamento_corrente),
    consolidou_no_municipio_ano = n_cnpjs_originais_observados > 1L,
    .by = c(uf_municipio_pagador, id_municipio, cnpj_raiz_8, ano)
  ) |>
  arrange(uf_municipio_pagador, id_municipio, cnpj_raiz_8, ano)

participacao_consolidada <- painel_consolidado |>
  summarise(
    cnpj_canonico = first(cnpj_canonico),
    razao_social_canonica = first(razao_social_canonica),
    sigla_canonica = first(sigla_canonica),
    uf_sede_canonica = first(uf_sede_canonica),
    primeiro_ano_corrente = safe_year(ano, tem_pagamento_corrente, min),
    ultimo_ano_corrente = safe_year(ano, tem_pagamento_corrente, max),
    n_anos_com_registro = n_distinct(ano),
    n_anos_pagamento_corrente = sum(tem_pagamento_corrente),
    valor_total_periodo = sum(valor_total, na.rm = TRUE),
    n_transacoes_periodo = sum(n_transacoes),
    .by = c(uf_municipio_pagador, id_municipio, cnpj_raiz_8)
  ) |>
  arrange(uf_municipio_pagador, id_municipio, cnpj_raiz_8)

cobertura_uf <- painel_consolidado |>
  summarise(
    ano_min = min(ano),
    ano_max = max(ano),
    n_anos = n_distinct(ano),
    municipios_pagadores = n_distinct(id_municipio),
    cnpjs_originais = n_distinct(unlist(str_split(cnpjs_originais_observados, fixed(" | ")))),
    consorcios_consolidados = n_distinct(cnpj_raiz_8),
    pares_municipio_consorcio = n_distinct(paste(id_municipio, cnpj_raiz_8)),
    linhas_anuais = n(),
    valor_total = sum(valor_total),
    .by = uf_municipio_pagador
  ) |>
  arrange(uf_municipio_pagador)

saveRDS(painel_original, file.path(out_dir, "painel_mides_nacional_cnpj_original_ano.rds"))
saveRDS(painel_consolidado, file.path(out_dir, "painel_mides_nacional_raiz_ano.rds"))
saveRDS(participacao_consolidada, file.path(out_dir, "painel_mides_nacional_participacao_raiz.rds"))
saveRDS(registros_sem_chave_municipal, file.path(out_dir, "mides_nacional_registros_sem_chave_municipal.rds"))
write.csv(cobertura_uf, file.path(out_dir, "painel_mides_nacional_cobertura_uf.csv"), row.names = FALSE, na = "")

message("MIDES nacional processado.")
print(cobertura_uf, n = Inf)
message("Linhas CNPJ original: ", nrow(painel_original))
message("Linhas raiz consolidada: ", nrow(painel_consolidado))
message("Pares consolidados: ", nrow(participacao_consolidada))
message("Registros preservados sem chave municipal: ", nrow(registros_sem_chave_municipal))
