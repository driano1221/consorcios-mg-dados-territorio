# =============================================================================
# Validacao estrutural do passo 4: capacidade assistencial direta CNES (MG)
# =============================================================================

suppressPackageStartupMessages(library(dplyr))

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
out_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude/outputs")
units_path <- file.path(out_dir, "capacidade_unidades_cnes_saude_mg.csv")
entities_path <- file.path(out_dir, "capacidade_entidades_saude_mg.rds")
polos_path <- file.path(out_dir, "polos_atracao_saude_mg.rds")

for (path in c(units_path, entities_path, polos_path)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

units <- read.csv(
  units_path,
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8",
  colClasses = c(cnpj_raiz_8 = "character", cnpj_canonico = "character", cnpj_consultado = "character", co_unidade = "character", cnes = "character")
)
entities <- readRDS(entities_path)
polos <- readRDS(polos_path)

required_units <- c(
  "cnpj_raiz_8", "cnpj_canonico", "cnes", "municipio_cnes", "unidade_movel_ou_itinerante",
  "leitos_existentes", "leitos_sus", "n_vinculos_sus_ativos", "n_cbo_medicos_sus_ativos_distintos",
  "consulta_cnes_completa", "data_extracao_cnes"
)
required_entities <- c(
  "cnpj_raiz_8", "decisao_polo_atracao", "capacidade_status", "medida_recomendada_passo_modelo",
  "data_extracao_cnes"
)
stopifnot(all(required_units %in% names(units)))
stopifnot(all(required_entities %in% names(entities)))
stopifnot(nrow(entities) == nrow(polos))
stopifnot(!anyDuplicated(entities$cnpj_raiz_8))
stopifnot(!anyDuplicated(units[c("cnpj_raiz_8", "cnes")]))
stopifnot(nrow(units) == 670L)
stopifnot(all(units$consulta_cnes_completa))
stopifnot(all(is.na(units$modulos_com_erro)))
stopifnot(sum(!units$unidade_movel_ou_itinerante) == 389L)
stopifnot(sum(units$unidade_movel_ou_itinerante) == 281L)
stopifnot(all(units$leitos_existentes >= 0 | is.na(units$leitos_existentes)))
stopifnot(all(units$leitos_sus >= 0 | is.na(units$leitos_sus)))
stopifnot(all(units$leitos_sus <= units$leitos_existentes | is.na(units$leitos_sus) | is.na(units$leitos_existentes)))
stopifnot(!any(units$status_leitos == "ficha_sem_total_identificavel", na.rm = TRUE))
stopifnot(all(units$n_vinculos_sus_ativos >= 0 | is.na(units$n_vinculos_sus_ativos)))

without_direct_unit <- entities$decisao_polo_atracao == "sede_administrativa_apenas_ancora_sensibilidade"
stopifnot(all(entities$capacidade_status[without_direct_unit] == "sem_unidade_cnes_direta_nao_interpretar_como_zero"))
mobile_only <- entities$n_unidades_cnes_vinculadas > 0L &
  entities$n_unidades_moveis_ou_itinerantes == entities$n_unidades_cnes_vinculadas
stopifnot(sum(mobile_only) == 2L)
stopifnot(all(entities$capacidade_status[mobile_only] == "somente_unidades_moveis_sem_polo_fixo"))
stopifnot(!any(entities$capacidade_status == "capacidade_pendente_por_consulta"))
stopifnot(sum(entities$capacidade_status == "capacidade_direta_cnes_atual") == 61L)
stopifnot(sum(entities$capacidade_status == "sem_unidade_cnes_direta_nao_interpretar_como_zero") == 21L)
stopifnot(sum(entities$capacidade_status == "somente_unidades_moveis_sem_polo_fixo") == 2L)
direct <- entities$capacidade_status == "capacidade_direta_cnes_atual"
stopifnot(sum(entities$cbo_medicos_sus_ativos_rede_direta[direct] > 0L) == 58L)
stopifnot(sum(entities$cbo_medicos_sus_ativos_rede_direta[direct] == 0L) == 3L)
stopifnot(!any(is.na(entities$leitos_sus_rede_direta[direct])))
stopifnot(sum(entities$leitos_sus_rede_direta[direct] > 0L) == 1L)
stopifnot(sum(entities$leitos_sus_rede_direta[direct] == 0L) == 60L)

cat("OK: capacidade CNES validada para", nrow(entities), "entidades e", nrow(units), "unidades diretamente vinculadas.\n")
