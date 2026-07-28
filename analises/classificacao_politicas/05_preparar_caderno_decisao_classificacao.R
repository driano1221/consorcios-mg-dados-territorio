# =============================================================================
# 05_preparar_caderno_decisao_classificacao.R
# Exporta os casos nao confirmados para o caderno de decisao em Excel.
# =============================================================================

library(dplyr)
library(readr)
library(jsonlite)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
class_dir <- file.path(project_dir, "analises", "classificacao_politicas")
out_dir <- file.path(class_dir, "outputs", "caderno_decisao_v0_3")
source_path <- file.path(class_dir, "outputs", "classificacao_areas_politica_mg_v0_3_tecnica.csv")
output_path <- file.path(out_dir, "casos_para_caderno.json")

if (!file.exists(source_path)) stop("Arquivo nao encontrado: ", source_path)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

casos <- read_csv(source_path, show_col_types = FALSE) |>
  mutate(
    grupo_decisao = case_when(
      status_validacao_v0_3 == "provisoria_coerente" ~ "Provisoria coerente",
      status_validacao_v0_3 == "provisoria_cadastro" ~ "Provisoria cadastro IPEA",
      status_validacao_v0_3 == "provisoria_nome" ~ "Provisoria por nome",
      status_validacao_v0_3 == "provisoria_multifinalitario" ~ "Multifinalitario",
      status_validacao_v0_3 == "pendente_documento" ~ "Sem area suficiente",
      status_validacao_v0_3 == "aguardar_matriz_filial" ~ "Filiais sem classificacao tematica",
      TRUE ~ NA_character_
    )
  ) |>
  filter(!is.na(grupo_decisao)) |>
  mutate(across(everything(), ~ ifelse(is.na(.x), "", as.character(.x))))

write_json(casos, output_path, dataframe = "rows", auto_unbox = TRUE, pretty = FALSE)

cat("Casos exportados para o caderno:", nrow(casos), "\n")
cat("Arquivo:", output_path, "\n")
