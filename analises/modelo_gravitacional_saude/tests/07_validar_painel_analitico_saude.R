# =============================================================================
# Validacao estrutural do passo 6: painel analitico de saude (MG)
# =============================================================================

suppressPackageStartupMessages(library(dplyr))

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
out_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude/outputs")

panel_path <- file.path(out_dir, "painel_analitico_saude_mg.rds")
source_path <- file.path(out_dir, "mides_saude_mg_consolidado_entidade_ano.rds")
pair_path <- file.path(out_dir, "painel_analitico_saude_mg_resumo_par.rds")
for (path in c(panel_path, source_path, pair_path)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

panel <- readRDS(panel_path)
source <- readRDS(source_path)
pairs <- readRDS(pair_path)

stopifnot(nrow(panel) == 853L * 84L * 8L)
stopifnot(n_distinct(panel$id_municipio) == 853L)
stopifnot(n_distinct(panel$cnpj_raiz_8) == 84L)
stopifnot(identical(sort(unique(panel$ano)), 2014:2021))
stopifnot(!anyDuplicated(panel[c("id_municipio", "cnpj_raiz_8", "ano")]))
stopifnot(nrow(pairs) == 853L * 84L)
stopifnot(!anyDuplicated(pairs[c("id_municipio", "cnpj_raiz_8")]))

stopifnot(nrow(source) == 10059L)
stopifnot(sum(source$n_cnpjs_originais_no_ano) == 10080L)
stopifnot(n_distinct(source$cnpj_raiz_8) == 66L)
stopifnot(n_distinct(source$id_municipio) == 843L)
stopifnot(sum(source$n_cnpjs_originais_no_ano > 1L) == 21L)
stopifnot(sum(source$valor_total <= 0) == 1L)
stopifnot(isTRUE(all.equal(
  sum(panel$valor_total),
  sum(source$valor_total),
  tolerance = 0.01
)))
stopifnot(isTRUE(all.equal(
  sum(panel$valor_total),
  3101980422.83,
  tolerance = 0.01
)))

stopifnot(all(panel$presente_mides == (panel$valor_total > 0)))
stopifnot(sum(panel$presente_mides) == 10058L)
stopifnot(all(is.na(panel$presente_t_1[panel$ano == 2014L])))
stopifnot(!any(panel$evento_primeiro_pagamento[panel$ano == 2014L]))
stopifnot(!any(panel$evento_retorno[panel$ano == 2014L]))
stopifnot(!any(panel$evento_interrupcao[panel$ano == 2014L]))
stopifnot(all(
  panel$evento_movimento[panel$ano == 2014L] %in%
    c("estoque_inicial_2014", "ausencia_inicial_2014")
))

event_counts <- table(panel$evento_movimento)
expected_counts <- c(
  ausencia = 492165L,
  ausencia_inicial_2014 = 70460L,
  estoque_inicial_2014 = 1192L,
  interrupcao_observada = 533L,
  permanencia = 8188L,
  primeiro_pagamento_observado = 426L,
  retorno_observado = 252L
)
stopifnot(identical(
  as.integer(event_counts[names(expected_counts)]),
  as.integer(expected_counts)
))

first_payment <- panel |> filter(evento_primeiro_pagamento)
returns <- panel |> filter(evento_retorno)
interruptions <- panel |> filter(evento_interrupcao)
permanence <- panel |> filter(evento_permanencia)
stopifnot(all(first_payment$presente_mides & !first_payment$presente_t_1 & !first_payment$teve_presenca_antes_t))
stopifnot(all(returns$presente_mides & !returns$presente_t_1 & returns$teve_presenca_antes_t))
stopifnot(all(!interruptions$presente_mides & interruptions$presente_t_1))
stopifnot(all(permanence$presente_mides & permanence$presente_t_1))

stopifnot(all(!panel$universo_preliminar_primeiro_pagamento[panel$ano == 2014L]))
stopifnot(all(!panel$universo_preliminar_entrada_ou_retorno[panel$ano == 2014L]))
stopifnot(all(!panel$universo_preliminar_interrupcao[panel$ano == 2014L]))
stopifnot(all(panel$tempo_capacidade_disponivel == (
  panel$tempo_status == "tempo_disponivel_unidades_fixas" &
    panel$capacidade_status == "capacidade_direta_cnes_atual"
)))
stopifnot(all(panel$universo_preliminar_interrupcao <= panel$incluir_modelo_principal_preliminar))
stopifnot(all(panel$universo_preliminar_interrupcao_com_tempo <= panel$universo_preliminar_interrupcao))
stopifnot(all(panel$universo_intensidade_observada <= panel$presente_mides))
stopifnot(all(panel$universo_intensidade_observada_com_tempo <= panel$universo_intensidade_observada))

cat(
  "OK: painel validado para 853 municipios, 84 entidades, oito anos e valor MIDES conservado.\n"
)
