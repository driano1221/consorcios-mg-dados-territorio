# =============================================================================
# Validacao estrutural do passo 3: polos de atracao em saude (MG)
# =============================================================================

suppressPackageStartupMessages(library(dplyr))

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
out_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude/outputs")
universe_path <- file.path(out_dir, "universo_saude_mg_entidades.rds")
polos_path <- file.path(out_dir, "polos_atracao_saude_mg.rds")
units_path <- file.path(out_dir, "unidades_cnes_vinculadas_saude_mg.csv")
consultas_path <- file.path(out_dir, "consultas_cnes_polo_saude_mg.csv")

for (path in c(universe_path, polos_path, units_path, consultas_path)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

universe <- readRDS(universe_path)
polos <- readRDS(polos_path)
units <- read.csv(units_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
consultas <- read.csv(consultas_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")

stopifnot(nrow(polos) == nrow(universe))
stopifnot(!anyDuplicated(polos$cnpj_raiz_8))
stopifnot(all(!is.na(polos$municipio_ancora_administrativa) & nzchar(polos$municipio_ancora_administrativa)))
stopifnot(all(polos$decisao_polo_atracao %in% c(
  "estabelecimento_cnes_unico",
  "rede_vinculada_sem_polo_unico",
  "sede_administrativa_apenas_ancora_sensibilidade",
  "pendente_ficha_cnes",
  "unidade_movel_sem_polo_fixo",
  "pendente_cnpj_consultavel",
  "pendente_por_consulta_incompleta"
)))

single <- polos$decisao_polo_atracao == "estabelecimento_cnes_unico"
stopifnot(all(!is.na(polos$cnes_polo_assistencial[single])))
stopifnot(all(!is.na(polos$municipio_polo_assistencial[single])))

network <- polos$decisao_polo_atracao == "rede_vinculada_sem_polo_unico"
stopifnot(all(is.na(polos$cnes_polo_assistencial[network])))

incomplete <- polos$decisao_polo_atracao == "pendente_por_consulta_incompleta"
stopifnot(all(polos$n_erros_consulta_cnes[incomplete] > 0L))

missing_cnpj <- polos$decisao_polo_atracao == "pendente_cnpj_consultavel"
stopifnot(all(polos$n_cnpjs_consultados_cnes[missing_cnpj] == 0L))

mobile <- polos$decisao_polo_atracao == "unidade_movel_sem_polo_fixo"
stopifnot(all(polos$n_unidades_moveis_ou_itinerantes[mobile] > 0L))
stopifnot(all(is.na(polos$cnes_polo_assistencial[mobile])))

if (nrow(units) > 0L) {
  stopifnot(all(units$cnpj_consultado %in% consultas$cnpj_consultado))
  stopifnot(all(units$vinculo_cnpj_mantenedora_direto %in% TRUE))
}

cat("OK: polo de atracao validado para", nrow(polos), "entidades;", nrow(units), "unidades CNES vinculadas.\n")
