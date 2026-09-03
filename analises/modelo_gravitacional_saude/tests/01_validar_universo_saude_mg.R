# =============================================================================
# 01_validar_universo_saude_mg.R
# Validacoes minimas do universo de saude consolidado.
# =============================================================================

root <- "analises/modelo_gravitacional_saude/outputs"
entities <- readRDS(file.path(root, "universo_saude_mg_entidades.rds"))
establishments <- readRDS(file.path(root, "universo_saude_mg_estabelecimentos.rds"))
reviews <- read.csv(
  file.path(root, "casos_revisao_universo_saude_mg.csv"),
  stringsAsFactors = FALSE,
  colClasses = c(cnpj_raiz_8 = "character", cnpj_canonico = "character")
)

stopifnot(
  nrow(establishments) == 100L,
  nrow(entities) == 84L,
  sum(establishments$tipo_estabelecimento == "filial") == 16L,
  sum(entities$tem_filial) == 11L,
  sum(entities$situacao_matriz == "Ativa") == 67L,
  sum(entities$situacao_matriz == "Inapta") == 13L,
  sum(entities$situacao_matriz == "Baixada") == 4L,
  sum(establishments$aparece_mides_mg_original) == 72L,
  sum(entities$aparece_mides_mg) == 66L,
  sum(entities$incluir_modelo_principal_preliminar) == 64L,
  sum(entities$incluir_sensibilidade_multiarea) == 2L,
  sum(!entities$aparece_mides_mg) == 18L,
  sum(entities$abertura_apos_periodo_mides) == 2L,
  sum(entities$escopo_saude == "saude_multiarea") == 4L,
  sum(entities$precisa_revisao_classificacao) == 0L,
  nrow(reviews) == 7L,
  anyDuplicated(establishments$cnpj_consorcio) == 0L,
  anyDuplicated(entities$cnpj_raiz_8) == 0L,
  all(entities$uf_sede_canonica == "MG"),
  abs(sum(establishments$valor_total_mides_original) - sum(entities$valor_total_mides)) < 0.01
)

cat("Validacao aprovada: universo de saude MG consistente.\n")
