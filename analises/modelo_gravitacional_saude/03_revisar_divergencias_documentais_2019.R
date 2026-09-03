# =============================================================================
# 03_revisar_divergencias_documentais_2019.R
#
# Aplica o catalogo de evidencias documentais a amostra prioritaria de 50
# divergencias MIDES x MUNIC. A revisao nao altera as fontes originais.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
})

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
model_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude")
out_dir <- file.path(model_dir, "outputs")
check_dir <- file.path(model_dir, "checks")
sample_path <- file.path(out_dir, "amostra_revisao_mides_munic_saude_mg_2019.csv")
catalog_path <- file.path(model_dir, "evidencias/catalogo_revisao_documental_2019.csv")

for (path in c(sample_path, catalog_path)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

sample_review <- read.csv(
  sample_path,
  stringsAsFactors = FALSE,
  colClasses = c(cod_ibge_6 = "character", cnpj_raiz_8 = "character"),
  check.names = FALSE
)
catalog <- read.csv(
  catalog_path,
  stringsAsFactors = FALSE,
  colClasses = c(cnpj_raiz_8 = "character", cod_ibge_6_override = "character"),
  check.names = FALSE
) |>
  mutate(cod_ibge_6_override = na_if(cod_ibge_6_override, ""))

defaults <- catalog |>
  filter(is.na(cod_ibge_6_override)) |>
  select(-cod_ibge_6_override)
overrides <- catalog |>
  filter(!is.na(cod_ibge_6_override)) |>
  rename(cod_ibge_6 = cod_ibge_6_override) |>
  mutate(chave_override = paste(cnpj_raiz_8, cod_ibge_6, sep = "|")) |>
  select(-cnpj_raiz_8, -cod_ibge_6)

review <- sample_review |>
  left_join(defaults, by = "cnpj_raiz_8") |>
  mutate(chave_override = paste(cnpj_raiz_8, cod_ibge_6, sep = "|")) |>
  left_join(overrides, by = "chave_override", suffix = c("", "_override"))

fields <- c(
  "fonte_titulo", "fonte_url", "ano_evidencia", "resultado_revisao",
  "cobertura_temporal", "grau_evidencia", "nota"
)
for (field in fields) {
  override_field <- paste0(field, "_override")
  if (override_field %in% names(review)) {
    review[[field]] <- coalesce(review[[override_field]], review[[field]])
  }
}

review <- review |>
  select(-chave_override, -ends_with("_override")) |>
  mutate(
    decisao_para_modelo = case_when(
      resultado_revisao == "evidencia_direta_ate_2019" ~ "manter_com_evidencia_temporal",
      resultado_revisao == "historicamente_compativel" ~ "manter_com_ressalva_temporal",
      resultado_revisao == "corroborado_em_fonte_posterior" ~ "manter_divergencia_para_sensibilidade",
      resultado_revisao == "relacao_financeira_sem_filiacao_comprovada" ~ "nao_converter_pagamento_em_filiacao",
      resultado_revisao == "nao_corroborado_com_indicio_alternativo" ~ "revisao_humana_prioritaria",
      TRUE ~ "revisao_humana_prioritaria"
    )
  ) |>
  arrange(desc(grupo_concordancia == "somente_MUNIC"), cnpj_raiz_8, cod_ibge_6)

if (nrow(review) != 50L) stop("A revisao deve conter exatamente 50 pares.")
if (anyDuplicated(review[c("cod_ibge_6", "cnpj_raiz_8")])) {
  stop("Ha duplicidade na chave municipio x entidade da revisao.")
}
if (any(is.na(review$resultado_revisao) | !nzchar(review$resultado_revisao))) {
  stop("Existem pares sem resultado documental.")
}

summary_result <- review |>
  count(resultado_revisao, cobertura_temporal, grau_evidencia, name = "n_pares") |>
  arrange(desc(n_pares), resultado_revisao)
summary_group <- review |>
  count(grupo_concordancia, resultado_revisao, name = "n_pares") |>
  arrange(grupo_concordancia, desc(n_pares))

write.csv(
  review,
  file.path(out_dir, "revisao_documental_divergencias_saude_mg_2019.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
write.csv(
  summary_result,
  file.path(out_dir, "resumo_revisao_documental_saude_mg_2019.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

lines <- c(
  "# Validacao Documental Das Divergencias De 2019",
  "",
  "## Escopo",
  "",
  paste0(
    "Revisao dos ", nrow(review),
    " pares prioritarios do cotejamento MIDES x MUNIC: todos os pares somente MUNIC e os 27 maiores valores somente MIDES."
  ),
  "",
  "A pesquisa documental nao altera MIDES ou MUNIC. Ela qualifica a divergencia e separa filiacao formal, evidencia financeira e confirmacao fora do ano de referencia.",
  "",
  "## Resultado",
  "",
  "| Resultado documental | Cobertura temporal | Grau | Pares |",
  "|---|---|---|---:|",
  apply(summary_result, 1, function(x) {
    paste0("| `", x[["resultado_revisao"]], "` | `", x[["cobertura_temporal"]], "` | `", x[["grau_evidencia"]], "` | ", x[["n_pares"]], " |")
  }),
  "",
  "## Leitura Por Divergencia",
  "",
  "| Fonte de divergencia | Resultado documental | Pares |",
  "|---|---|---:|",
  apply(summary_group, 1, function(x) {
    paste0("| `", x[["grupo_concordancia"]], "` | `", x[["resultado_revisao"]], "` | ", x[["n_pares"]], " |")
  }),
  "",
  "## Casos Criticos",
  "",
  "- `Juiz de Fora x ACISPES`: pagamento MIDES e prestacao de servico nao comprovam filiacao municipal; a fonte institucional distingue consorciados de cidades apenas atendidas.",
  "- `Sao Miguel do Anta x SIMSAUDE`: nao houve corroboracao documental; uma fonte municipal posterior registra parceria com outro consorcio, exigindo revisao humana.",
  "- `Itabira x CIAS`: a MUNIC sem MIDES em 2019 e compativel com fonte oficial de 2016; a ausencia na lista atual sugere mudanca temporal e nao erro automatico.",
  "",
  "## Decisao Metodologica",
  "",
  "- Evidencia anterior ou igual a 2019 pode sustentar o vinculo historico, mas ainda nao garante contribuicao anual.",
  "- Fonte posterior apenas corrobora plausibilidade institucional; esses pares permanecem em sensibilidade.",
  "- Pagamento MIDES continua sendo evidencia financeira, nunca sinonimo automatico de adesao juridica.",
  "- Ausencia documental nesta busca nao prova inexistencia do vinculo.",
  "",
  "Catalogo versionado: `evidencias/catalogo_revisao_documental_2019.csv`.",
  "Resultado detalhado local: `outputs/revisao_documental_divergencias_saude_mg_2019.csv`."
)
writeLines(
  lines,
  con = file.path(check_dir, "VALIDACAO_DOCUMENTAL_DIVERGENCIAS_2019.md"),
  useBytes = TRUE
)

cat("Revisao documental concluida para 50 pares.\n")
print(summary_result)
