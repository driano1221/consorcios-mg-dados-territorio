invisible(Sys.setlocale("LC_ALL", "Portuguese_Brazil.1252"))

library(dplyr)

project_dir <- "."
out_dir <- file.path(project_dir, "analises", "base_nacional", "outputs")

raw <- readRDS(file.path(out_dir, "mides_ipea_nacional_transacoes.rds"))
original <- readRDS(file.path(out_dir, "painel_mides_nacional_cnpj_original_ano.rds"))
consolidado <- readRDS(file.path(out_dir, "painel_mides_nacional_raiz_ano.rds"))
participacao <- readRDS(file.path(out_dir, "painel_mides_nacional_participacao_raiz.rds"))
sem_chave <- readRDS(file.path(out_dir, "mides_nacional_registros_sem_chave_municipal.rds"))

metricas <- c(
  "valor_corrente", "valor_restos", "valor_indicador_restos_ausente",
  "valor_total", "valor_liquido_recebido"
)
for (metrica in metricas) {
  antes <- sum(original[[metrica]], na.rm = TRUE)
  depois <- sum(consolidado[[metrica]], na.rm = TRUE)
  if (!isTRUE(all.equal(antes, depois, tolerance = 1e-10))) {
    stop("Valor nao conservado em ", metrica, ": ", antes, " != ", depois)
  }
}

stopifnot(sum(original$n_transacoes) + nrow(sem_chave) == nrow(raw))
stopifnot(sum(consolidado$n_transacoes) + nrow(sem_chave) == nrow(raw))
stopifnot(!anyDuplicated(original[c("uf_municipio_pagador", "id_municipio", "cnpj_original", "ano")]))
stopifnot(!anyDuplicated(consolidado[c("uf_municipio_pagador", "id_municipio", "cnpj_raiz_8", "ano")]))
stopifnot(!anyDuplicated(participacao[c("uf_municipio_pagador", "id_municipio", "cnpj_raiz_8")]))
stopifnot(n_distinct(raw$sigla_uf) == 8L)
stopifnot(n_distinct(original$cnpj_original) == 512L)
stopifnot(n_distinct(consolidado$cnpj_raiz_8) == 505L)
stopifnot(nrow(consolidado) <= nrow(original))
stopifnot(sum(consolidado$consolidou_no_municipio_ano) > 0L)
stopifnot(nrow(sem_chave) == 681L)
stopifnot(all(sem_chave$sigla_uf == "SC"))
stopifnot(isTRUE(all.equal(
  sum(raw$valor_final, na.rm = TRUE),
  sum(consolidado$valor_total, na.rm = TRUE) + sum(sem_chave$valor_final, na.rm = TRUE),
  tolerance = 1e-10
)))
stopifnot(all(abs(
  consolidado$valor_total - consolidado$valor_corrente -
    consolidado$valor_restos - consolidado$valor_indicador_restos_ausente
) < 0.01))

# O recorte MG da nova camada original deve reproduzir exatamente o painel
# historico antes de qualquer consolidacao por raiz.
painel_mg_path <- file.path(project_dir, "dados", "processado", "painel_mg_anual.rds")
if (file.exists(painel_mg_path)) {
  mg_antigo <- readRDS(painel_mg_path) |>
    transmute(
      id_municipio = as.character(id_municipio),
      cnpj_original = stringr::str_pad(as.character(documento_credor), 14, pad = "0"),
      ano = as.integer(ano),
      valor_corrente_antigo = valor_corrente,
      valor_restos_antigo = valor_restos,
      valor_total_antigo = valor_total,
      n_transacoes_antigo = n_transacoes
    )
  mg_novo <- original |>
    filter(uf_municipio_pagador == "MG") |>
    select(
      id_municipio, cnpj_original, ano,
      valor_corrente_novo = valor_corrente,
      valor_restos_novo = valor_restos,
      valor_total_novo = valor_total,
      n_transacoes_novo = n_transacoes
    )
  mg_comparacao <- full_join(
    mg_antigo, mg_novo,
    by = c("id_municipio", "cnpj_original", "ano")
  )
  stopifnot(nrow(mg_antigo) == 15135L, nrow(mg_novo) == 15135L)
  stopifnot(!anyNA(mg_comparacao$valor_total_antigo), !anyNA(mg_comparacao$valor_total_novo))
  stopifnot(all(abs(mg_comparacao$valor_corrente_antigo - mg_comparacao$valor_corrente_novo) < 0.001))
  stopifnot(all(abs(mg_comparacao$valor_restos_antigo - mg_comparacao$valor_restos_novo) < 0.001))
  stopifnot(all(abs(mg_comparacao$valor_total_antigo - mg_comparacao$valor_total_novo) < 0.001))
  stopifnot(all(mg_comparacao$n_transacoes_antigo == mg_comparacao$n_transacoes_novo))
}

cat("OK - MIDES nacional consolidado validado\n")
cat("Transacoes:", nrow(raw), "\n")
cat("UFs:", paste(sort(unique(raw$sigla_uf)), collapse = ", "), "\n")
cat("CNPJs observados:", n_distinct(original$cnpj_original), "\n")
cat("Raizes observadas:", n_distinct(consolidado$cnpj_raiz_8), "\n")
cat("Linhas originais:", nrow(original), "\n")
cat("Linhas consolidadas:", nrow(consolidado), "\n")
cat("Valor total conservado:", format(sum(consolidado$valor_total), scientific = FALSE), "\n")
cat("Registros sem chave municipal preservados:", nrow(sem_chave), "\n")
cat("Compatibilidade integral com o painel MG anterior: OK\n")
