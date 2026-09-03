# =============================================================================
# 02_validar_cotejamento_mides_munic_saude_2019.R
# =============================================================================

root <- "analises/modelo_gravitacional_saude/outputs"
base1 <- readRDS("dashboards/base1_shiny/data/base_1_vinculos_2015_2019.rds")
pairs <- readRDS(file.path(root, "cotejamento_mides_munic_saude_mg_2019.rds"))
entities <- readRDS(file.path(root, "resumo_entidades_mides_munic_saude_mg_2019.rds"))
sample_review <- read.csv(
  file.path(root, "amostra_revisao_mides_munic_saude_mg_2019.csv"),
  stringsAsFactors = FALSE,
  colClasses = c(cod_ibge_6 = "character", cnpj_raiz_8 = "character")
)
overall <- read.csv(
  file.path(root, "resumo_geral_mides_munic_saude_mg_2019.csv"),
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(pairs) == 1311L,
  nrow(entities) == 84L,
  sum(pairs$grupo_concordancia == "MIDES+MUNIC") == 630L,
  sum(pairs$grupo_concordancia == "somente_MIDES") == 658L,
  sum(pairs$grupo_concordancia == "somente_MUNIC") == 23L,
  length(unique(pairs$cod_ibge_6)) == 819L,
  length(unique(pairs$cnpj_raiz_8)) == 66L,
  sum(entities$categoria_evidencia_2019 == "fontes_com_municipio_em_comum") == 61L,
  sum(entities$categoria_evidencia_2019 == "duas_fontes_sem_municipio_em_comum") == 1L,
  sum(entities$categoria_evidencia_2019 == "somente_MIDES") == 3L,
  sum(entities$categoria_evidencia_2019 == "somente_MUNIC") == 1L,
  sum(entities$categoria_evidencia_2019 == "sem_evidencia_2019") == 18L,
  sum(entities$tem_doc_municipios) == 23L,
  sum(entities$tem_rateio) == 24L,
  sum(entities$tem_protocolo) == 30L,
  sum(entities$tem_estatuto) == 32L,
  sum(pairs$consolidou_multiplos_cnpjs) == 5L,
  nrow(sample_review) == 50L,
  sum(sample_review$grupo_concordancia == "somente_MUNIC") == 23L,
  anyDuplicated(pairs[c("cod_ibge_6", "cnpj_raiz_8")]) == 0L,
  !any(pairs$grupo_concordancia == "sem_fonte"),
  abs(
    sum(pairs$valor_mides_total_2019) -
      sum(base1$valor_mides_total[base1$ano == 2019L & base1$cnpj_consorcio %in% unlist(strsplit(paste(pairs$cnpjs_originais, collapse = ";"), ";", fixed = TRUE))], na.rm = TRUE)
  ) < 0.01,
  abs(overall$valor_mides_munic + overall$valor_somente_mides - overall$valor_mides_total_2019) < 0.01,
  overall$pct_valor_mides_munic >= 0,
  overall$pct_valor_mides_munic <= 1
)

cat("Validacao aprovada: cotejamento MIDES x MUNIC saude 2019 consistente.\n")
