# =============================================================================
# 03_validar_revisao_documental_2019.R
# =============================================================================

root <- "analises/modelo_gravitacional_saude"
review <- read.csv(
  file.path(root, "outputs/revisao_documental_divergencias_saude_mg_2019.csv"),
  stringsAsFactors = FALSE,
  colClasses = c(cod_ibge_6 = "character", cnpj_raiz_8 = "character")
)
catalog <- read.csv(
  file.path(root, "evidencias/catalogo_revisao_documental_2019.csv"),
  stringsAsFactors = FALSE,
  colClasses = c(cnpj_raiz_8 = "character", cod_ibge_6_override = "character")
)

allowed_results <- c(
  "evidencia_direta_ate_2019",
  "historicamente_compativel",
  "corroborado_em_fonte_posterior",
  "relacao_financeira_sem_filiacao_comprovada",
  "nao_corroborado_com_indicio_alternativo"
)

stopifnot(
  nrow(review) == 50L,
  nrow(catalog) == 28L,
  anyDuplicated(review[c("cod_ibge_6", "cnpj_raiz_8")]) == 0L,
  sum(review$grupo_concordancia == "somente_MUNIC") == 23L,
  sum(review$grupo_concordancia == "somente_MIDES") == 27L,
  all(review$resultado_revisao %in% allowed_results),
  all(nzchar(review$fonte_url)),
  all(grepl("^https://", review$fonte_url)),
  all(review$grau_evidencia %in% c("forte", "moderado", "fraco")),
  sum(review$resultado_revisao == "relacao_financeira_sem_filiacao_comprovada") == 1L,
  sum(review$resultado_revisao == "nao_corroborado_com_indicio_alternativo") == 1L,
  review$resultado_revisao[
    review$cod_ibge_6 == "313670" & review$cnpj_raiz_8 == "01203485"
  ] == "relacao_financeira_sem_filiacao_comprovada",
  review$resultado_revisao[
    review$cod_ibge_6 == "316380" & review$cnpj_raiz_8 == "11592737"
  ] == "nao_corroborado_com_indicio_alternativo"
)

cat("Validacao aprovada: revisao documental de 50 divergencias consistente.\n")
