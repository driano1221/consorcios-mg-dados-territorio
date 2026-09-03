# =============================================================================
# 01_fechar_universo_saude_mg.R
#
# Fecha o universo cadastral de consorcios de saude em MG, consolida matriz e
# filiais pela raiz do CNPJ e registra a presenca financeira observada no MIDES.
# Nenhum registro bruto e alterado.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
})

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
class_path <- file.path(
  project_dir,
  "analises/classificacao_politicas/outputs/classificacao_areas_politica_mg_v0_5_completa.csv"
)
crosswalk_path <- file.path(
  project_dir,
  "analises/base_nacional/outputs/crosswalk_cnpj_matriz_filial_nacional.rds"
)
mides_path <- file.path(project_dir, "dados/processado/painel_mg_anual.rds")
out_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude/outputs")
check_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude/checks")

for (path in c(class_path, crosswalk_path, mides_path)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(check_dir, recursive = TRUE, showWarnings = FALSE)

collapse_values <- function(x) {
  values <- sort(unique(trimws(na.omit(as.character(x)))))
  values <- values[nzchar(values)]
  if (length(values) == 0L) NA_character_ else paste(values, collapse = " | ")
}

area_tokens <- function(x) {
  values <- trimws(unlist(strsplit(paste(na.omit(x), collapse = ";"), ";", fixed = TRUE)))
  sort(unique(values[nzchar(values)]))
}

contains_token <- function(x, tokens) {
  any(area_tokens(x) %in% tokens)
}

classify_health_scope <- function(x, health_tokens) {
  tokens <- area_tokens(x)
  if (all(tokens %in% health_tokens)) "saude_setorial" else "saude_multiarea"
}

classification <- read.csv(
  class_path,
  check.names = FALSE,
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8",
  colClasses = c(cnpj_consorcio = "character")
)
crosswalk <- readRDS(crosswalk_path)
painel_mg <- readRDS(mides_path)

health_tokens <- c("saude", "urgencia_emergencia", "vigilancia_em_saude")
is_health <- vapply(
  classification$area_politica_final,
  contains_token,
  logical(1),
  tokens = health_tokens
)

health_establishments <- classification[is_health, ] |>
  left_join(crosswalk, by = c("cnpj_consorcio" = "cnpj_original"))

if (any(is.na(health_establishments$cnpj_raiz_8))) {
  stop("Ha CNPJ de saude sem correspondencia no crosswalk matriz-filial.")
}
if (anyDuplicated(health_establishments$cnpj_consorcio)) {
  stop("Ha CNPJ duplicado no universo de saude.")
}

health_roots <- unique(health_establishments$cnpj_raiz_8)
all_root_establishments <- crosswalk |>
  filter(cnpj_raiz_8 %in% health_roots)

if (nrow(all_root_establishments) != nrow(health_establishments)) {
  stop("Uma raiz de saude possui estabelecimento sem classificacao de saude.")
}

mides_positive <- painel_mg |>
  transmute(
    cod_ibge_6 = str_sub(as.character(id_municipio), 1, 6),
    cnpj_original = str_pad(
      str_remove_all(as.character(documento_credor), "[^0-9]"),
      width = 14,
      side = "left",
      pad = "0"
    ),
    ano = as.integer(ano),
    valor_total = as.numeric(valor_total),
    n_transacoes = as.integer(n_transacoes)
  ) |>
  filter(valor_total > 0, cnpj_original %in% health_establishments$cnpj_consorcio)

first_mides_year <- min(painel_mg$ano, na.rm = TRUE)
last_mides_year <- max(painel_mg$ano, na.rm = TRUE)

mides_by_original <- mides_positive |>
  summarise(
    primeiro_ano_mides_original = min(ano),
    ultimo_ano_mides_original = max(ano),
    n_anos_mides_original = n_distinct(ano),
    n_municipios_mides_original = n_distinct(cod_ibge_6),
    n_linhas_anuais_mides_original = n(),
    n_transacoes_mides_original = sum(n_transacoes, na.rm = TRUE),
    valor_total_mides_original = sum(valor_total, na.rm = TRUE),
    .by = cnpj_original
  )

mides_with_root <- mides_positive |>
  inner_join(
    crosswalk |> select(cnpj_original, cnpj_raiz_8, cnpj_canonico),
    by = "cnpj_original"
  )

root_key_audit <- mides_with_root |>
  summarise(
    n_cnpjs_originais = n_distinct(cnpj_original),
    valor_total = sum(valor_total),
    .by = c(cnpj_raiz_8, cod_ibge_6, ano)
  ) |>
  filter(n_cnpjs_originais > 1L)

mides_by_root <- mides_with_root |>
  summarise(
    aparece_mides_mg = TRUE,
    primeiro_ano_mides = min(ano),
    ultimo_ano_mides = max(ano),
    anos_mides = paste(sort(unique(ano)), collapse = ";"),
    n_anos_mides = n_distinct(ano),
    n_municipios_mides = n_distinct(cod_ibge_6),
    n_pares_mides = n_distinct(paste(cod_ibge_6, cnpj_raiz_8)),
    n_linhas_anuais_mides = n_distinct(paste(cod_ibge_6, ano)),
    n_transacoes_mides = sum(n_transacoes, na.rm = TRUE),
    valor_total_mides = sum(valor_total, na.rm = TRUE),
    n_cnpjs_originais_mides = n_distinct(cnpj_original),
    cnpjs_originais_mides = collapse_values(cnpj_original),
    .by = cnpj_raiz_8
  )

root_universe <- health_establishments |>
  summarise(
    cnpj_canonico = first(cnpj_canonico),
    cnpj_matriz = first(cnpj_matriz),
    razao_social_canonica = first(razao_social_canonica),
    sigla_canonica = first(sigla_canonica),
    uf_sede_canonica = first(uf_sede_canonica),
    municipio_sede_canonico = first(municipio_sede_canonico),
    situacao_matriz = first(situacao_matriz),
    ano_abertura_matriz = first(ano_abertura_matriz),
    n_estabelecimentos = first(n_estabelecimentos),
    n_filiais = first(n_filiais),
    tem_filial = first(n_filiais) > 0L,
    cnpjs_estabelecimentos = collapse_values(cnpj_consorcio),
    cnpjs_filiais = collapse_values(cnpj_consorcio[tipo_estabelecimento == "filial"]),
    situacoes_estabelecimentos = collapse_values(situacao_estabelecimento),
    status_estabelecimentos_misto = n_distinct(situacao_estabelecimento) > 1L,
    areas_politica = paste(area_tokens(area_politica_final), collapse = "; "),
    macroareas = paste(area_tokens(macroarea_final), collapse = "; "),
    perfis_institucionais = collapse_values(perfil_institucional),
    fontes_classificacao = collapse_values(fonte_principal),
    status_classificacao = collapse_values(status_validacao),
    precisa_revisao_classificacao = any(precisa_revisao),
    escopo_saude = classify_health_scope(area_politica_final, health_tokens),
    macroarea_saude_informada = contains_token(macroarea_final, "saude"),
    .by = cnpj_raiz_8
  ) |>
  left_join(mides_by_root, by = "cnpj_raiz_8") |>
  mutate(
    aparece_mides_mg = coalesce(aparece_mides_mg, FALSE),
    n_anos_mides = coalesce(n_anos_mides, 0L),
    n_municipios_mides = coalesce(n_municipios_mides, 0L),
    n_pares_mides = coalesce(n_pares_mides, 0L),
    n_linhas_anuais_mides = coalesce(n_linhas_anuais_mides, 0L),
    n_transacoes_mides = coalesce(n_transacoes_mides, 0L),
    valor_total_mides = coalesce(valor_total_mides, 0),
    n_cnpjs_originais_mides = coalesce(n_cnpjs_originais_mides, 0L),
    abertura_apos_periodo_mides = ano_abertura_matriz > last_mides_year,
    incluir_universo_cadastral_saude = TRUE,
    incluir_universo_mides_observado = aparece_mides_mg,
    incluir_modelo_principal_preliminar = aparece_mides_mg & escopo_saude == "saude_setorial",
    incluir_sensibilidade_multiarea = aparece_mides_mg & escopo_saude == "saude_multiarea",
    camada_analitica = case_when(
      incluir_modelo_principal_preliminar ~ "nucleo_setorial_observado",
      incluir_sensibilidade_multiarea ~ "sensibilidade_multiarea_observada",
      TRUE ~ "cadastro_sem_pagamento_mides_observado"
    ),
    revisar_escopo_multiarea = escopo_saude == "saude_multiarea",
    revisar_status_inativo_com_mides = situacao_matriz != "Ativa" & aparece_mides_mg,
    revisar_ativa_sem_mides_na_janela = situacao_matriz == "Ativa" &
      !aparece_mides_mg & ano_abertura_matriz <= last_mides_year,
    revisar_macroarea_saude_ausente = !macroarea_saude_informada
  ) |>
  arrange(desc(aparece_mides_mg), escopo_saude, situacao_matriz, razao_social_canonica)

review_reasons <- character(nrow(root_universe))
for (i in seq_len(nrow(root_universe))) {
  reasons <- c(
    if (root_universe$revisar_escopo_multiarea[i]) "escopo_saude_multiarea",
    if (root_universe$revisar_status_inativo_com_mides[i]) "matriz_inativa_com_pagamento_mides",
    if (root_universe$revisar_ativa_sem_mides_na_janela[i]) "matriz_ativa_sem_mides_na_janela",
    if (root_universe$revisar_macroarea_saude_ausente[i]) "macroarea_saude_ausente"
  )
  review_reasons[i] <- paste(reasons, collapse = "; ")
}

root_universe <- root_universe |>
  mutate(
    motivos_revisao_universo = review_reasons,
    precisa_revisao_universo = nzchar(motivos_revisao_universo)
  )

establishment_universe <- health_establishments |>
  left_join(mides_by_original, by = c("cnpj_consorcio" = "cnpj_original")) |>
  left_join(
    root_universe |>
      select(
        cnpj_raiz_8, escopo_saude, camada_analitica,
        aparece_mides_mg_raiz = aparece_mides_mg,
        precisa_revisao_universo, motivos_revisao_universo
      ),
    by = "cnpj_raiz_8"
  ) |>
  mutate(
    aparece_mides_mg_original = !is.na(primeiro_ano_mides_original),
    n_anos_mides_original = coalesce(n_anos_mides_original, 0L),
    n_municipios_mides_original = coalesce(n_municipios_mides_original, 0L),
    n_linhas_anuais_mides_original = coalesce(n_linhas_anuais_mides_original, 0L),
    n_transacoes_mides_original = coalesce(n_transacoes_mides_original, 0L),
    valor_total_mides_original = coalesce(valor_total_mides_original, 0)
  ) |>
  arrange(cnpj_raiz_8, desc(tipo_estabelecimento == "matriz"), cnpj_consorcio)

review_cases <- root_universe |>
  filter(precisa_revisao_universo) |>
  select(
    cnpj_raiz_8, cnpj_canonico, sigla_canonica, razao_social_canonica,
    situacao_matriz, ano_abertura_matriz, escopo_saude, aparece_mides_mg,
    primeiro_ano_mides, ultimo_ano_mides, areas_politica, macroareas,
    motivos_revisao_universo
  )

summary_metrics <- tibble::tribble(
  ~indicador, ~valor,
  "periodo_mides_inicio", first_mides_year,
  "periodo_mides_fim", last_mides_year,
  "cnpjs_estabelecimentos_saude", nrow(establishment_universe),
  "entidades_saude_consolidadas", nrow(root_universe),
  "filiais_incorporadas", sum(establishment_universe$tipo_estabelecimento == "filial"),
  "entidades_com_filial", sum(root_universe$tem_filial),
  "entidades_matriz_ativa", sum(root_universe$situacao_matriz == "Ativa"),
  "entidades_matriz_inapta", sum(root_universe$situacao_matriz == "Inapta"),
  "entidades_matriz_baixada", sum(root_universe$situacao_matriz == "Baixada"),
  "cnpjs_originais_observados_mides", sum(establishment_universe$aparece_mides_mg_original),
  "entidades_observadas_mides", sum(root_universe$aparece_mides_mg),
  "nucleo_setorial_observado", sum(root_universe$incluir_modelo_principal_preliminar),
  "sensibilidade_multiarea_observada", sum(root_universe$incluir_sensibilidade_multiarea),
  "entidades_cadastrais_sem_mides", sum(!root_universe$aparece_mides_mg),
  "entidades_abertas_apos_periodo_mides", sum(root_universe$abertura_apos_periodo_mides),
  "entidades_para_revisao_universo", nrow(review_cases),
  "classificacoes_documentais_pendentes", sum(root_universe$precisa_revisao_classificacao),
  "raizes_com_multiplos_cnpjs_no_mides", sum(root_universe$n_cnpjs_originais_mides > 1L),
  "chaves_municipio_ano_com_soma_matriz_filial", nrow(root_key_audit),
  "raizes_com_soma_na_mesma_chave", n_distinct(root_key_audit$cnpj_raiz_8)
)

write.csv(
  establishment_universe,
  file.path(out_dir, "universo_saude_mg_estabelecimentos.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
write.csv(
  root_universe,
  file.path(out_dir, "universo_saude_mg_entidades.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
write.csv(
  review_cases,
  file.path(out_dir, "casos_revisao_universo_saude_mg.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
write.csv(
  summary_metrics,
  file.path(out_dir, "resumo_universo_saude_mg.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
saveRDS(establishment_universe, file.path(out_dir, "universo_saude_mg_estabelecimentos.rds"))
saveRDS(root_universe, file.path(out_dir, "universo_saude_mg_entidades.rds"))

table_rows <- apply(review_cases, 1, function(row) {
  values <- gsub("\\|", "/", as.character(row))
  names(values) <- names(row)
  sigla <- if (is.na(row[["sigla_canonica"]]) || !nzchar(row[["sigla_canonica"]])) {
    "(sem sigla)"
  } else {
    values[["sigla_canonica"]]
  }
  periodo_mides <- if (identical(row[["aparece_mides_mg"]], "TRUE")) {
    paste0(values[["primeiro_ano_mides"]], "-", values[["ultimo_ano_mides"]])
  } else {
    "Nao observado"
  }
  paste0(
    "| `", values[["cnpj_canonico"]], "` | ", sigla,
    " | ", values[["situacao_matriz"]], " | ", periodo_mides,
    " | ", values[["motivos_revisao_universo"]], " |"
  )
})

report <- c(
  "# Validacao Do Universo De Consorcios De Saude Em MG",
  "",
  paste0("**Periodo MIDES:** ", first_mides_year, "-", last_mides_year),
  "",
  "## Resultado",
  "",
  paste0("- 100 estabelecimentos CNPJ classificados em saude foram consolidados em **", nrow(root_universe), " entidades**."),
  paste0("- **", sum(root_universe$aparece_mides_mg), " entidades** aparecem no MIDES MG; 18 nao possuem pagamento observado no periodo."),
  paste0("- O nucleo setorial preliminar possui **", sum(root_universe$incluir_modelo_principal_preliminar), " entidades**."),
  paste0("- Duas entidades multiarea observadas ficam em camada de sensibilidade, sem exclusao dos arquivos."),
  paste0("- A consolidacao incorporou **", sum(establishment_universe$tipo_estabelecimento == "filial"), " filiais** em ", sum(root_universe$tem_filial), " raizes com mais de um estabelecimento."),
  paste0("- Foram encontradas ", nrow(root_key_audit), " chaves municipio-ano com pagamentos simultaneos a mais de um CNPJ da mesma raiz."),
  "",
  "## Camadas",
  "",
  "| Camada | Entidades | Uso |",
  "|---|---:|---|",
  paste0("| Universo cadastral amplo | ", nrow(root_universe), " | Toda entidade com area explicita de saude, urgencia ou vigilancia. |"),
  paste0("| Universo MIDES observado | ", sum(root_universe$aparece_mides_mg), " | Entidades com pagamento positivo em MG. |"),
  paste0("| Nucleo setorial preliminar | ", sum(root_universe$incluir_modelo_principal_preliminar), " | Analise principal antes das validacoes documentais. |"),
  paste0("| Sensibilidade multiarea | ", sum(root_universe$incluir_sensibilidade_multiarea), " | Saude explicita junto com outras areas. |"),
  "",
  "## Casos Para Revisao Do Universo",
  "",
  "Esses casos nao sao erros automaticos. Eles exigem decisao de escopo, leitura temporal ou correcao de metadado.",
  "",
  "| CNPJ canonico | Sigla | Situacao atual | MIDES 2014-2021 | Motivo |",
  "|---|---|---|---|---|",
  table_rows,
  "",
  "## Regras",
  "",
  "1. Saude inclui as areas `saude`, `urgencia_emergencia` e `vigilancia_em_saude` da classificacao v0.5.",
  "2. Matriz e filiais usam a raiz de oito digitos; o CNPJ canonico e a matriz `0001`.",
  "3. A situacao cadastral da entidade e a situacao atual da matriz. Ela nao reconstrui a situacao historica de 2014-2021.",
  "4. Presenca MIDES significa pagamento positivo observado, nao adesao juridica.",
  "5. Consorcios multiarea com saude explicita sao preservados e separados para sensibilidade.",
  "6. A inclusao definitiva no conjunto de risco depende das proximas validacoes documental, MUNIC e CNES."
)
writeLines(report, file.path(check_dir, "VALIDACAO_UNIVERSO_SAUDE_MG.md"), useBytes = TRUE)

message("Universo de saude MG materializado.")
print(summary_metrics)
