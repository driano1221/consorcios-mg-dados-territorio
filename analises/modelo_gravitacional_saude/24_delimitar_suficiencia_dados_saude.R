# Mede o alcance dos recortes existentes; nao altera dados, amostra ou modelos.
suppressPackageStartupMessages(library(dplyr))
out <- "outputs"
p <- readRDS(file.path(out, "painel_anual_integrado_saude_mg_2014_2021.rds"))
stopifnot(nrow(p) == 661928L, ncol(p) == 60L,
          !anyDuplicated(p[c("id_municipio", "cnpj_raiz_8", "ano")]))
read_table <- function(path) read.csv(path, colClasses = "character",
  fileEncoding = "UTF-8-BOM", check.names = FALSE)
save_table <- function(x, name) write.csv(x, file.path(out, name), row.names = FALSE,
                                        na = "", fileEncoding = "UTF-8")
temporal <- read_table(file.path(out, "diagnostico_necessidade_mensal_entidades_saude.csv"))
priority <- temporal[temporal$classe_temporal == "priorizar_coleta_mensal", ]
key <- function(x) paste(x$cnpj_raiz_8, x$ano, sep = "_")
health <- p$alternativa_cadastral_saude
direct <- p$alternativa_direta_com_tempo
masks <- list(grade_97 = rep(TRUE, nrow(p)), cadastral_saude = health,
              clinica_direta_com_tempo = direct,
              saude_sem_clinica_direta = health & !direct,
              direto_com_rcl = direct & !is.na(p$rcl_municipal),
              direto_com_pdr = direct & !is.na(p$regiao_saude),
              direto_com_rcl_e_pdr = direct & !is.na(p$rcl_municipal) & !is.na(p$regiao_saude),
              saude_prioridade_temporal = health & key(p) %in% key(priority))
summary_rows <- list()
for (period in c("2014-2021", as.character(2014:2021))) {
  for (name in names(masks)) {
    select <- masks[[name]] & (period == "2014-2021" | as.character(p$ano) == period)
    z <- p[select, ]
    paid <- z[z$presente_mides, ]
    summary_rows[[length(summary_rows) + 1L]] <- data.frame(
      periodo = period, recorte = name, linhas = nrow(z),
      linhas_sem_pagamento_positivo = sum(!z$presente_mides),
      pares_ano_pagos = nrow(paid), entidades_ano_pagas = length(unique(key(paid))),
      municipios_pagadores = n_distinct(paid$id_municipio),
      valor_mides = sum(z$valor_total),
      pares_pagos_com_rcl = sum(!is.na(paid$rcl_municipal)),
      pares_pagos_com_pdr = sum(!is.na(paid$regiao_saude)))
  }
}
summary <- bind_rows(summary_rows)
save_table(summary, "matriz_suficiencia_recortes_saude.csv")
annual <- p |> filter(presente_mides & alternativa_cadastral_saude) |>
  group_by(cnpj_raiz_8, ano) |>
  summarise(pares_pagos = n(), valor_mides = sum(valor_total), .groups = "drop")
annual$ano <- as.character(annual$ano)
impact <- left_join(priority, annual, by = c("cnpj_raiz_8", "ano"))
impact$pares_pagos[is.na(impact$pares_pagos)] <- 0L
impact$valor_mides[is.na(impact$valor_mides)] <- 0
save_table(impact, "impacto_prioridade_temporal_saude.csv")

# Complemento documental separado: conserva as 181 chaves e a classificacao anterior.
old <- read_table("evidencias/conciliacao_181_entidades_ano_2026_09_24.csv")
review <- read_table("evidencias/revisao_prioritarios_2026_09_24.csv")
stopifnot(nrow(review) == 14L, !anyDuplicated(key(review)), all(key(review) %in% key(old)))
updated <- left_join(old, review, by = c("cnpj_raiz_8", "ano"))
updated$decisao_vigente <- coalesce(updated$decisao_revisada, updated$classificacao_conciliada)
stopifnot(nrow(updated) == 181L, identical(key(updated), key(old)),
          identical(updated$valor_mides, old$valor_mides))
save_table(updated, "conciliacao_lacunas_com_revisao_prioritaria_saude.csv")

# Comparar datas financeiras com quatro janelas clinicas ja identificadas.
# Data de pagamento nao e data de atendimento; fora da janela nao e erro financeiro.
raw <- readRDS("../../dados/bruto/mides_mg_atualizado.rds")
raw$cnpj_raiz_8 <- substr(gsub("[^0-9]", "", raw$documento_credor), 1, 8)
exceptions <- data.frame(cnpj_raiz_8 = c("97550393", "01111142", "64486822", "01260691"),
                        ano = c(2015L, 2016L, 2017L, 2017L), ultimo_mes_clinico = c(1L, 6L, 6L, 10L))
transactions <- inner_join(raw, exceptions, by = c("cnpj_raiz_8", "ano"))
# Mesma medida financeira do painel e da conferencia do script 21.
stopifnot(!anyNA(transactions$valor_final))
transactions$mes_pagamento <- suppressWarnings(as.integer(format(as.Date(transactions$data), "%m")))
transactions$janela <- ifelse(is.na(transactions$mes_pagamento), "data_ausente",
  ifelse(transactions$mes_pagamento <= transactions$ultimo_mes_clinico,
         "mes_com_tipo_clinico", "mes_apos_ultimo_tipo_clinico"))
timing <- transactions |> group_by(cnpj_raiz_8, ano, janela) |>
  summarise(transacoes = n(), valor_mides = sum(valor_final), .groups = "drop")
check <- timing |> group_by(cnpj_raiz_8, ano) |>
  summarise(valor = sum(valor_mides), transacoes = sum(transacoes), .groups = "drop")
expected <- inner_join(p, exceptions, by = c("cnpj_raiz_8", "ano")) |>
  group_by(cnpj_raiz_8, ano) |> summarise(valor_painel = sum(valor_total),
    transacoes_painel = sum(n_transacoes), .groups = "drop")
check <- left_join(check, expected, by = c("cnpj_raiz_8", "ano"))
stopifnot(nrow(check) == 4L, all(abs(check$valor - check$valor_painel) < .01),
          all(check$transacoes == check$transacoes_painel))
save_table(timing, "pagamentos_janelas_clinicas_piloto_saude.csv")
print(summary[summary$periodo == "2014-2021", ], row.names = FALSE)
print(timing)
cat("Prioridade temporal:", nrow(impact), "entidades-ano; com pagamento:",
    sum(impact$pares_pagos > 0), "; R$", sum(impact$valor_mides), "\n")
