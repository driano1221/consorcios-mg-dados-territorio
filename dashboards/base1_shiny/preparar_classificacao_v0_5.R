# Prepara a copia leve da classificacao para o pacote de publicacao Shiny.
# A fonte de verdade permanece em analises/classificacao_politicas/outputs/.

library(readr)
library(dplyr)
library(stringr)

app_dir <- normalizePath("dashboards/base1_shiny", winslash = "/", mustWork = TRUE)
project_dir <- normalizePath(file.path(app_dir, "..", ".."), winslash = "/", mustWork = TRUE)
source_path <- file.path(
  project_dir,
  "analises/classificacao_politicas/outputs/classificacao_areas_politica_mg_v0_5_completa.csv"
)
target_path <- file.path(app_dir, "data/classificacao_areas_politica_mg_v0_5.rds")

if (!file.exists(source_path)) stop("Arquivo nao encontrado: ", source_path)

classificacao <- read_csv(source_path, show_col_types = FALSE) |>
  mutate(cnpj_consorcio = str_pad(cnpj_consorcio, 14, side = "left", pad = "0")) |>
  distinct(cnpj_consorcio, .keep_all = TRUE)

stopifnot(nrow(classificacao) == 223L)
stopifnot(sum(classificacao$ativo_analise) == 217L)
stopifnot(sum(classificacao$status_validacao == "validada_usuario_coerente") == 94L)

dir.create(dirname(target_path), recursive = TRUE, showWarnings = FALSE)
saveRDS(classificacao, target_path)

cat("Arquivo preparado:", target_path, "\n")
