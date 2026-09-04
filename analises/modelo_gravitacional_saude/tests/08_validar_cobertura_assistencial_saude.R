# =============================================================================
# Validacao estrutural da auditoria complementar de cobertura assistencial.
# =============================================================================

suppressPackageStartupMessages(library(dplyr))

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
out_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude/outputs")

coverage_path <- file.path(out_dir, "cobertura_assistencial_entidades_saude_mg.rds")
pending_path <- file.path(out_dir, "auditoria_38_casos_cobertura_assistencial_saude_mg.csv")
alerts_path <- file.path(out_dir, "auditoria_alertas_universo_saude_mg.csv")

for (path in c(coverage_path, pending_path, alerts_path)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

coverage <- readRDS(coverage_path)
pending <- read.csv(pending_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8", colClasses = c(cnpj_raiz_8 = "character"))
alerts <- read.csv(alerts_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8", colClasses = c(cnpj_raiz_8 = "character"))

stopifnot(nrow(coverage) == 84L)
stopifnot(nrow(pending) == 38L)
stopifnot(nrow(alerts) == 7L)
stopifnot(!anyDuplicated(coverage$cnpj_raiz_8))
stopifnot(!anyDuplicated(pending$cnpj_raiz_8))
stopifnot(!anyDuplicated(alerts$cnpj_raiz_8))
stopifnot(sum(coverage$recuperada_consulta_cnpj_proprio) == 15L)
stopifnot(sum(coverage$tem_estrutura_fixa_direta) == 61L)
stopifnot(sum(coverage$estrutura_direta_disponivel_mides) == 59L)
stopifnot(sum(coverage$capacidade_direta_com_cbo_medico_sus) == 58L)
stopifnot(all(alerts$status_resolucao == "resolvido"))
stopifnot(!any(coverage$status_auditoria != "concluida"))

# Casos sentinela que protegem as principais decisoes metodologicas.
cisarp <- coverage |> filter(cnpj_raiz_8 == "01172959")
stopifnot(cisarp$recuperada_consulta_cnpj_proprio, cisarp$cnes_cnpj_proprio == "7918747")

ciscen <- coverage |> filter(cnpj_raiz_8 == "00773222")
stopifnot(ciscen$cobertura_classificacao == "servico_movel_e_rede_credenciada_sem_polo_unico")
stopifnot(!ciscen$tem_estrutura_fixa_direta)

cisuba <- coverage |> filter(cnpj_raiz_8 == "00840724")
stopifnot(cisuba$cobertura_classificacao == "entidade_historica_inativa_sem_polo_atual")
stopifnot(!cisuba$estrutura_direta_disponivel_mides)

cat("OK: cobertura assistencial complementar validada para 84 entidades, 38 casos pendentes e 7 alertas.\n")
