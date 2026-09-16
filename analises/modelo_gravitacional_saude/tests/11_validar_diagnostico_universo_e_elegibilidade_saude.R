# Valida os produtos do diagnostico das 18 entidades e do filtro funcional.

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
out_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude/outputs")
evidence_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude/evidencias")

read_chars <- function(name) read.csv(
  file.path(out_dir, name), check.names = FALSE, stringsAsFactors = FALSE,
  colClasses = "character"
)

current <- read_chars("elegibilidade_assistencial_unidades_atuais_saude_mg.csv")
historical <- read_chars("elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv")
entity_year <- read_chars("elegibilidade_assistencial_entidade_ano_saude_mg_2014_2021.csv")
audit_18 <- read_chars("auditoria_18_entidades_sem_mides_saude_mg.csv")
comparison <- read_chars("comparacao_entidades_com_sem_mides_saude_mg.csv")
multiarea <- read_chars("auditoria_multiarea_saude_mg.csv")
decisions <- read_chars("decisoes_documentais_91_entidades_ano.csv")
original <- read_chars("dossie_91_entidades_ano_sem_fixa.csv")
audit_21 <- read.csv(
  file.path(evidence_dir, "auditoria_documental_21_entidades_2026_09_16.csv"),
  check.names = FALSE, stringsAsFactors = FALSE, colClasses = "character"
)

stopifnot(
  nrow(current) == 670L,
  sum(current$funcao_assistencial == "unidade_movel") == 587L,
  sum(current$funcao_assistencial == "destino_clinico_fixo") == 63L,
  sum(current$funcao_assistencial == "estrutura_fixa_nao_clinica") == 20L,
  sum(current$funcao_assistencial == "pendente_nome_tipo") == 0L,
  current$funcao_assistencial[current$cnes == "5563003"] == "unidade_movel",
  current$funcao_assistencial[current$cnes == "3987981"] == "destino_clinico_fixo",
  nrow(historical) == 1868L,
  sum(historical$funcao_assistencial == "unidade_movel") == 1396L,
  sum(historical$funcao_assistencial == "destino_clinico_fixo") == 398L,
  sum(historical$funcao_assistencial == "estrutura_fixa_nao_clinica") == 74L,
  sum(historical$funcao_assistencial == "pendente_tipo_historico") == 0L,
  nrow(entity_year) == 672L,
  !anyDuplicated(entity_year[c("cnpj_raiz_8", "ano")]),
  nrow(audit_18) == 18L,
  !anyDuplicated(audit_18$cnpj_raiz_8),
  sum(audit_18$classificacao_auditoria_18 == "abertura_apos_2021") == 2L,
  sum(audit_18$classificacao_auditoria_18 == "ativa_sem_mides_e_sem_evidencia_assistencial") == 1L,
  sum(audit_18$classificacao_auditoria_18 == "inativa_sem_mides_e_sem_oferta_cnes_2014_2021") == 15L,
  identical(sort(as.integer(comparison$n_entidades)), c(18L, 66L)),
  identical(sort(multiarea$cnpj_raiz_8), c("01260691", "01272081", "06070075", "07306549")),
  sum(multiarea$decisao_analitica == "manter_sensibilidade_multiarea") == 3L,
  multiarea$decisao_analitica[multiarea$cnpj_raiz_8 == "01260691"] == "alerta_estatutario_para_sensibilidade",
  nrow(decisions) == 91L,
  identical(decisions[names(original)], original),
  length(unique(decisions$cnpj_raiz_8)) == 28L,
  abs(sum(as.numeric(decisions$valor_mides)) - 151093325.68) < 0.01,
  all(decisions$zero_capacidade_autorizado == "FALSE"),
  nrow(audit_21) == 21L,
  !anyDuplicated(audit_21$cnpj_raiz_8),
  all(audit_21$decisao_modelo_principal %in% c(
    "excluir_destino_fixo", "excluir_na_fotografia_de_dezembro",
    "excluir_destino_clinico_fixo"
  )),
  all(nzchar(audit_21$fonte_principal))
)

figures <- file.path(
  out_dir, "figuras",
  c("mapa_entidades_saude_mg_presenca_mides.png", "mapa_unidades_cnes_saude_mg_por_funcao.png")
)
stopifnot(all(file.exists(figures)), all(file.info(figures)$size > 50000L))

cat("Diagnostico das 18 entidades, filtro funcional e mapas validados.\n")
