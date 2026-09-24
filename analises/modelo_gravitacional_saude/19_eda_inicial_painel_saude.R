# EDA inicial do passo 7: selecao, zeros e extremos antes da estimacao.
suppressPackageStartupMessages(library(dplyr))
Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8")
out <- file.path(getwd(), "outputs")
p <- readRDS(file.path(out, "painel_anual_integrado_saude_mg_2014_2021.rds"))

safe_quantile <- function(x, prob) if (length(x)) unname(quantile(x, prob,
  na.rm = TRUE)) else NA_real_

annual <- p |>
  group_by(ano) |>
  summarise(
    alternativas_diretas = sum(alternativa_direta_com_tempo),
    alternativas_diretas_sem_pagamento = sum(alternativa_direta_com_tempo &
      !presente_mides),
    pagadores_total = sum(presente_mides),
    pagadores_principal = sum(universo_intensidade_principal),
    pagadores_excluidos_sem_polo = sum(presente_mides &
      alternativa_cadastral_saude & !alternativa_direta_com_tempo),
    pagadores_excluidos_escopo = sum(presente_mides &
      !alternativa_cadastral_saude),
    valor_principal = sum(valor_total[universo_intensidade_principal]),
    valor_total = sum(valor_total),
    rcl_no_principal = sum(universo_intensidade_principal &
      !is.na(rcl_municipal)),
    tempo_p50_principal = safe_quantile(tempo_minimo_min[
      universo_intensidade_principal], .5),
    tempo_p95_principal = safe_quantile(tempo_minimo_min[
      universo_intensidade_principal], .95),
    tempo_max_principal = max(tempo_minimo_min[
      universo_intensidade_principal]),
    entidades_principal = n_distinct(cnpj_raiz_8[
      universo_intensidade_principal]),
    .groups = "drop") |>
  mutate(fracao_pagadores_principal = pagadores_principal / pagadores_total,
    fracao_valor_principal = valor_principal / valor_total)

stopifnot(all(annual$alternativas_diretas ==
  annual$alternativas_diretas_sem_pagamento + annual$pagadores_principal),
  all(annual$pagadores_total == annual$pagadores_principal +
    annual$pagadores_excluidos_sem_polo + annual$pagadores_excluidos_escopo),
  all(annual$tempo_p95_principal <= annual$tempo_max_principal))

write.csv(annual, file.path(out, "eda_inicial_painel_saude_2014_2021.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
outliers <- p |>
  filter(universo_intensidade_principal, tempo_minimo_min > 300) |>
  select(ano, id_municipio, municipio, cnpj_raiz_8, sigla, valor_total,
    tempo_minimo_min, destino_clinico_mais_proximo_id) |>
  arrange(desc(tempo_minimo_min), ano)
write.csv(outliers, file.path(out, "eda_tempos_acima_300min_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
print(annual, width = Inf)
cat("Pares pagantes com tempo acima de 300 minutos:", nrow(outliers), "\n")
