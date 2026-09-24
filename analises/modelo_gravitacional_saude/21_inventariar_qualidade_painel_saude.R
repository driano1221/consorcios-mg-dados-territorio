# Inventario reproduzivel de todas as colunas do painel, sem alterar a base.
out <- if (file.exists(file.path("outputs",
  "painel_anual_integrado_saude_mg_2014_2021.rds"))) "outputs" else
  file.path("analises", "modelo_gravitacional_saude", "outputs")
p <- readRDS(file.path(out, "painel_anual_integrado_saude_mg_2014_2021.rds"))
stopifnot(nrow(p) == 853L * 97L * 8L, ncol(p) == 60L,
  !anyDuplicated(p[c("id_municipio", "cnpj_raiz_8", "ano")]))

profile <- function(x, variable, year, universe) {
  observed <- x[!is.na(x)]
  numeric <- is.numeric(x)
  quant <- function(prob) if (length(observed) && numeric)
    unname(quantile(observed, prob, names = FALSE)) else NA_real_
  data.frame(ano = year, universo = universe, variavel = variable,
    classe = paste(class(x), collapse = "/"), n_linhas = length(x),
    n_nulos = sum(is.na(x)), n_observados = length(observed),
    n_vazios = if (is.character(x)) sum(trimws(observed) == "") else NA_integer_,
    n_distintos = length(unique(observed)),
    n_zeros = if (numeric) sum(observed == 0) else NA_integer_,
    n_false = if (is.logical(x)) sum(observed == FALSE) else NA_integer_,
    n_true = if (is.logical(x)) sum(observed == TRUE) else NA_integer_,
    minimo = if (numeric && length(observed)) min(observed) else NA_real_,
    p25 = quant(.25), mediana = quant(.5), p75 = quant(.75),
    p95 = quant(.95), maximo = if (numeric && length(observed))
      max(observed) else NA_real_, stringsAsFactors = FALSE)
}

profiles <- vector("list", 8L * 3L * ncol(p))
i <- 0L
for (year in 2014:2021) {
  y <- p[p$ano == year, ]
  universes <- list(grade = rep(TRUE, nrow(y)),
    pagadores_saude = y$presente_mides & y$alternativa_cadastral_saude,
    pagadores_diretos = y$universo_intensidade_principal)
  for (universe in names(universes)) {
    z <- y[universes[[universe]], ]
    for (variable in names(z)) {
      i <- i + 1L
      profiles[[i]] <- profile(z[[variable]], variable, year, universe)
    }
  }
}
profiles <- do.call(rbind, profiles)
profiles$pct_nulos <- ifelse(profiles$n_linhas > 0,
  100 * profiles$n_nulos / profiles$n_linhas, NA_real_)
stopifnot(nrow(profiles) == 8L * 3L * ncol(p),
  all(profiles$n_linhas == profiles$n_nulos + profiles$n_observados))
write.csv(profiles, file.path(out, "eda_inventario_60_variaveis_painel_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")

annual <- do.call(rbind, lapply(2014:2021, function(year) {
  y <- p[p$ano == year, ]
  paid <- y$presente_mides
  health <- paid & y$alternativa_cadastral_saude
  direct <- y$alternativa_direta_com_tempo
  municipality <- !duplicated(y$id_municipio)
  root <- !duplicated(y$cnpj_raiz_8)
  root_year <- !duplicated(y[c("cnpj_raiz_8", "ano")])
  data.frame(ano = year, linhas = nrow(y), municipios = sum(municipality),
    entidades = sum(root), pares_pagantes = sum(paid),
    valor_pago = sum(y$valor_total[paid]),
    pagadores_saude = sum(health),
    valor_pagadores_saude = sum(y$valor_total[health]),
    pagadores_saude_sem_polo_direto = sum(health & !direct),
    valor_saude_sem_polo_direto = sum(y$valor_total[health & !direct]),
    pagadores_diretos = sum(paid & direct),
    valor_pagadores_diretos = sum(y$valor_total[paid & direct]),
    entidades_ano_com_clinica = sum(root_year & y$clinica_direta_dezembro),
    alternativas_diretas = sum(direct),
    municipio_ano_com_rcl = sum(municipality & !is.na(y$rcl_municipal)),
    pagadores_saude_com_rcl = sum(health & !is.na(y$rcl_municipal)),
    pagadores_diretos_com_rcl = sum(paid & direct & !is.na(y$rcl_municipal)),
    pagadores_saude_com_pdr = sum(health & !is.na(y$regiao_saude)),
    pagadores_diretos_sem_servicos_sus = sum(paid & direct &
      y$servicos_sus_clinicos_soma_unidades == 0, na.rm = TRUE),
    pagadores_diretos_sem_profissionais_sus = sum(paid & direct &
      y$profissionais_sus_clinicos_soma_unidades == 0, na.rm = TRUE),
    pagadores_diretos_sem_leitos_sus = sum(paid & direct &
      y$leitos_sus_clinicos == 0, na.rm = TRUE))
}))
stopifnot(all(annual$linhas == 853L * 97L),
  all(annual$pares_pagantes >= annual$pagadores_saude),
  all(annual$pagadores_saude == annual$pagadores_diretos +
    annual$pagadores_saude_sem_polo_direto))
write.csv(annual, file.path(out, "eda_cobertura_anual_painel_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")

gap_rows <- p[p$presente_mides & p$alternativa_cadastral_saude &
  !p$alternativa_direta_com_tempo,
  c("ano", "cnpj_raiz_8", "sigla", "origem_universo", "grupo_escopo",
    "valor_total", "classificacao_assistencial_documental",
    "decisao_destino_fixo_anual", "decisao_sete_prioritarias")]
keys <- c("ano", "cnpj_raiz_8", "sigla", "origem_universo", "grupo_escopo")
meta <- unique(gap_rows[c(keys, "classificacao_assistencial_documental",
  "decisao_destino_fixo_anual", "decisao_sete_prioritarias")])
stopifnot(!anyDuplicated(meta[keys]))
gaps <- aggregate(cbind(pares = rep(1L, nrow(gap_rows)),
  valor = gap_rows$valor_total),
  by = gap_rows[keys], FUN = sum)
gaps <- merge(gaps, meta, by = keys, all.x = TRUE, sort = FALSE)
stopifnot(!anyDuplicated(gaps[keys]))
gaps <- gaps[order(gaps$ano, -gaps$valor), ]
stopifnot(sum(gaps$pares) == sum(annual$pagadores_saude_sem_polo_direto),
  abs(sum(gaps$valor) - sum(annual$valor_saude_sem_polo_direto)) < .01)
write.csv(gaps, file.path(out, "eda_lacunas_polo_entidade_ano_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")

check <- c(
  chave_ou_ano_nulo = sum(is.na(p$id_municipio) | is.na(p$cnpj_raiz_8) |
    is.na(p$ano)),
  pagamento_negativo = sum(p$valor_total < 0, na.rm = TRUE),
  transacoes_negativas = sum(p$n_transacoes < 0, na.rm = TRUE),
  pagamento_sem_transacao = sum(p$valor_total > 0 & p$n_transacoes == 0,
    na.rm = TRUE),
  registro_sem_pagamento_positivo = sum(p$tem_registro_mides &
    !p$presente_mides, na.rm = TRUE),
  transacoes_sem_valor_positivo = sum(p$n_transacoes > 0 &
    p$valor_total == 0, na.rm = TRUE),
  flag_pagamento_diverge = sum(p$presente_mides != (p$valor_total > 0),
    na.rm = TRUE),
  capacidade_negativa = sum(p$n_destinos_clinicos_dezembro < 0 |
    p$leitos_sus_clinicos < 0 |
    p$servicos_sus_clinicos_soma_unidades < 0 |
    p$profissionais_sus_clinicos_soma_unidades < 0, na.rm = TRUE),
  tempo_negativo = sum(p$tempo_minimo_min < 0, na.rm = TRUE),
  tempo_fora_ordem = sum(p$tempo_minimo_min > p$tempo_mediano_min |
    p$tempo_mediano_min > p$tempo_maximo_min, na.rm = TRUE),
  tempo_sem_clinica = sum(!is.na(p$tempo_minimo_min) &
    !p$clinica_direta_dezembro),
  alternativa_direta_sem_tempo = sum(p$alternativa_direta_com_tempo &
    is.na(p$tempo_minimo_min)),
  rcl_nao_positiva = sum(p$rcl_municipal <= 0, na.rm = TRUE),
  populacao_nao_positiva = sum(p$populacao_ibge <= 0, na.rm = TRUE),
  pdr_antes_2019 = sum(p$ano < 2019 & !is.na(p$regiao_saude)),
  pagamento_antes_abertura = sum(p$presente_mides &
    !p$instituicao_aberta_no_ano, na.rm = TRUE),
  populacao_inconsistente_no_municipio_ano = sum(duplicated(
    unique(p[c("id_municipio", "ano", "populacao_ibge")])[
      c("id_municipio", "ano")])),
  rcl_inconsistente_no_municipio_ano = sum(duplicated(
    unique(p[c("id_municipio", "ano", "rcl_municipal")])[
      c("id_municipio", "ano")])),
  capacidade_inconsistente_na_entidade_ano = sum(duplicated(
    unique(p[c("cnpj_raiz_8", "ano", "n_destinos_clinicos_dezembro",
      "leitos_sus_clinicos", "servicos_sus_clinicos_soma_unidades",
      "profissionais_sus_clinicos_soma_unidades")])[
      c("cnpj_raiz_8", "ano")])),
  sigla_vazia_em_pagamento = sum(p$presente_mides &
    trimws(p$sigla) == "", na.rm = TRUE))
anomalies <- data.frame(verificacao = names(check), n_linhas = as.integer(check))
write.csv(anomalies, file.path(out, "eda_anomalias_painel_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")

# Extremos sao candidatos a inspecao, nao erros nem exclusoes automaticas.
paid <- p[p$presente_mides, c("ano", "id_municipio", "municipio",
  "cnpj_raiz_8", "sigla", "grupo_escopo", "valor_total", "n_transacoes",
  "populacao_ibge", "valor_por_habitante", "tempo_minimo_min",
  "alternativa_direta_com_tempo")]
extremes <- do.call(rbind, lapply(c("valor_total", "valor_por_habitante",
  "tempo_minimo_min"), function(metric) {
  valid <- paid[!is.na(paid[[metric]]), ]
  top <- head(valid[order(-valid[[metric]]), ], 20L)
  top$metrica <- metric
  top
}))
write.csv(extremes, file.path(out, "eda_extremos_exploratorios_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
print(annual, row.names = FALSE)
print(anomalies, row.names = FALSE)
cat("Variaveis:", ncol(p), "| perfis:", nrow(profiles),
  "| entidade-ano com pagamento sem polo:", nrow(gaps), "\n")
