# =============================================================================
# 08_completar_cobertura_assistencial_saude.R
#
# Consolida a auditoria complementar de cobertura assistencial. Distingue:
# - unidade/rede CNES diretamente vinculada por CNPJ;
# - rede ou servico indireto documentado;
# - servico movel sem destino fixo;
# - entidade historica/inativa;
# - ausencia de evidencia suficiente.
#
# O passo conclui a auditoria, nao imputa capacidade, prestador ou hospital.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
})

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
analysis_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude")
out_dir <- file.path(analysis_dir, "outputs")
check_dir <- file.path(analysis_dir, "checks")
evidence_dir <- file.path(analysis_dir, "evidencias")

paths <- c(
  universe = file.path(out_dir, "universo_saude_mg_entidades.rds"),
  capacity = file.path(out_dir, "capacidade_entidades_saude_mg.rds"),
  units = file.path(out_dir, "unidades_cnes_vinculadas_saude_mg.csv"),
  baseline = file.path(out_dir, "baseline_capacidade_entidades_saude_mg_antes_cnpj_proprio_2026_09_03.csv"),
  indirect = file.path(evidence_dir, "catalogo_cobertura_assistencial_indireta.csv"),
  alerts = file.path(evidence_dir, "decisoes_alertas_universo_saude.csv")
)
for (path in paths) if (!file.exists(path)) stop("Arquivo obrigatorio ausente: ", path)

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(check_dir, recursive = TRUE, showWarnings = FALSE)

read_utf8 <- function(path, ...) {
  read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8", ...)
}

collapse_values <- function(x) {
  values <- sort(unique(trimws(na.omit(as.character(x)))))
  values <- values[nzchar(values)]
  if (length(values) == 0L) NA_character_ else paste(values, collapse = " | ")
}

universe <- readRDS(paths[["universe"]])
capacity <- readRDS(paths[["capacity"]])
units <- read_utf8(
  paths[["units"]],
  colClasses = c(cnpj_raiz_8 = "character", cnpj_canonico = "character", cnpj_consultado = "character", co_unidade = "character", cnes = "character")
)
baseline <- read_utf8(
  paths[["baseline"]],
  colClasses = c(cnpj_raiz_8 = "character", cnpj_canonico = "character")
)
indirect <- read_utf8(paths[["indirect"]], colClasses = c(cnpj_raiz_8 = "character"))
alerts <- read_utf8(paths[["alerts"]], colClasses = c(cnpj_raiz_8 = "character"))

if (anyDuplicated(universe$cnpj_raiz_8)) stop("Universo possui raiz duplicada.")
if (anyDuplicated(capacity$cnpj_raiz_8)) stop("Capacidade possui raiz duplicada.")
if (anyDuplicated(indirect$cnpj_raiz_8)) stop("Catalogo indireto possui raiz duplicada.")
if (anyDuplicated(alerts$cnpj_raiz_8)) stop("Decisoes de alertas possuem raiz duplicada.")

unit_sources <- units |>
  group_by(cnpj_raiz_8) |>
  summarise(
    n_unidades_cnes_total_auditado = n_distinct(cnes),
    n_unidades_cnpj_proprio = n_distinct(cnes[vinculo_cnpj_proprio_direto %in% TRUE]),
    n_unidades_cnpj_mantenedora = n_distinct(cnes[vinculo_cnpj_mantenedora_direto %in% TRUE]),
    cnes_cnpj_proprio = collapse_values(cnes[vinculo_cnpj_proprio_direto %in% TRUE]),
    .groups = "drop"
  )

baseline_status <- baseline |>
  select(cnpj_raiz_8, capacidade_status_antes = capacidade_status)

coverage <- universe |>
  select(
    cnpj_raiz_8, cnpj_canonico, razao_social_canonica, sigla_canonica,
    situacao_matriz, escopo_saude, aparece_mides_mg,
    incluir_modelo_principal_preliminar, incluir_sensibilidade_multiarea
  ) |>
  left_join(
    capacity |>
      select(
        cnpj_raiz_8, capacidade_status, decisao_polo_atracao,
        n_unidades_cnes_vinculadas, n_unidades_fixas_cnes,
        n_unidades_moveis_ou_itinerantes, n_municipios_oferta_direta,
        municipios_unidades_cnes, cnes_unidades_fixas,
        cbo_medicos_sus_ativos_rede_direta, leitos_sus_rede_direta
      ),
    by = "cnpj_raiz_8"
  ) |>
  left_join(unit_sources, by = "cnpj_raiz_8") |>
  left_join(baseline_status, by = "cnpj_raiz_8") |>
  left_join(indirect, by = "cnpj_raiz_8") |>
  mutate(
    across(
      c(n_unidades_cnes_total_auditado, n_unidades_cnpj_proprio, n_unidades_cnpj_mantenedora),
      ~ coalesce(.x, 0L)
    ),
    recuperada_consulta_cnpj_proprio =
      capacidade_status_antes %in% c(
        "sem_unidade_cnes_direta_nao_interpretar_como_zero",
        "somente_unidades_moveis_sem_polo_fixo"
      ) & n_unidades_cnpj_proprio > 0L & n_unidades_fixas_cnes > 0L,
    tem_estrutura_fixa_direta = capacidade_status == "capacidade_direta_cnes_atual" & n_unidades_fixas_cnes > 0L,
    tem_rede_indireta_documentada = rede_indireta_documentada %in% TRUE,
    cobertura_classificacao = case_when(
      tem_estrutura_fixa_direta & n_unidades_fixas_cnes == 1L ~ "unidade_fixa_cnes_direta",
      tem_estrutura_fixa_direta & n_unidades_fixas_cnes > 1L ~ "rede_fixa_cnes_direta",
      !is.na(classificacao_documental) & nzchar(classificacao_documental) ~ classificacao_documental,
      capacidade_status == "somente_unidades_moveis_sem_polo_fixo" ~ "somente_unidade_movel_sem_polo_fixo",
      situacao_matriz %in% c("Baixada", "Inapta") & !aparece_mides_mg ~ "fora_universo_modelavel_atual",
      situacao_matriz == "Ativa" & !aparece_mides_mg ~ "ativa_sem_mides_e_sem_evidencia_assistencial",
      TRUE ~ "sem_evidencia_assistencial_suficiente"
    ),
    tem_um_unico_destino_fixo_atual = tem_estrutura_fixa_direta & n_unidades_fixas_cnes == 1L,
    uso_modelo_cobertura = case_when(
      !is.na(decisao_uso_modelo) & nzchar(decisao_uso_modelo) ~ decisao_uso_modelo,
      tem_estrutura_fixa_direta & incluir_modelo_principal_preliminar ~
        "Estrutura direta identificada; validar se existia em cada ano antes de usar capacidade atual na janela 2014-2021.",
      tem_estrutura_fixa_direta & incluir_sensibilidade_multiarea ~
        "Estrutura direta identificada; usar apenas na sensibilidade multiarea e sem retroagir a fotografia atual.",
      tem_estrutura_fixa_direta & !aparece_mides_mg ~
        "Estrutura atual identificada, mas fora do painel MIDES de saude por ausencia de pagamento observado.",
      cobertura_classificacao == "fora_universo_modelavel_atual" ~
        "Excluir do universo atual; manter somente no cadastro tecnico e historico.",
      TRUE ~ "Nao usar capacidade nem tempo ate obter evidencia assistencial suficiente."
    ),
    status_auditoria = "concluida",
    estrutura_direta_disponivel_mides = tem_estrutura_fixa_direta & aparece_mides_mg,
    capacidade_direta_com_cbo_medico_sus =
      tem_estrutura_fixa_direta & cbo_medicos_sus_ativos_rede_direta > 0L,
    pendencia_material = case_when(
      estrutura_direta_disponivel_mides & !capacidade_direta_com_cbo_medico_sus ~
        "Validar equipe, producao ou rede contratada; a unidade existe, mas o CNES direto nao registra CBO medico SUS ativo.",
      estrutura_direta_disponivel_mides ~ "Validar temporalidade da unidade e capacidade por ano.",
      tem_rede_indireta_documentada ~ "Identificar prestadores, enderecos e vigencia contratual por servico/ano.",
      cobertura_classificacao == "fora_universo_modelavel_atual" ~ "Nenhuma para o modelo atual.",
      str_detect(cobertura_classificacao, "historica_inativa") ~ "Mapear sucessao somente se houver documento explicito.",
      TRUE ~ "Localizar evidencia documental adicional; nao imputar polo."
    ),
    data_auditoria = as.character(Sys.Date())
  ) |>
  arrange(desc(aparece_mides_mg), cnpj_raiz_8)

alert_audit <- alerts |>
  left_join(
    universe |>
      select(cnpj_raiz_8, cnpj_canonico, razao_social_canonica, sigla_canonica, situacao_matriz, aparece_mides_mg),
    by = "cnpj_raiz_8"
  ) |>
  left_join(
    coverage |>
      select(cnpj_raiz_8, cobertura_classificacao, estrutura_direta_disponivel_mides),
    by = "cnpj_raiz_8"
  ) |>
  select(
    cnpj_raiz_8, cnpj_canonico, sigla_canonica, razao_social_canonica,
    alerta_original, decisao_auditoria, modelo_principal,
    analise_sensibilidade, status_resolucao, fundamento,
    situacao_matriz, aparece_mides_mg, cobertura_classificacao,
    estrutura_direta_disponivel_mides
  ) |>
  arrange(cnpj_raiz_8)

original_pending <- coverage |>
  filter(capacidade_status_antes %in% c(
    "sem_unidade_cnes_direta_nao_interpretar_como_zero",
    "somente_unidades_moveis_sem_polo_fixo"
  ))

summary <- coverage |>
  count(cobertura_classificacao, name = "entidades") |>
  arrange(desc(entidades), cobertura_classificacao)

write.csv(coverage, file.path(out_dir, "cobertura_assistencial_entidades_saude_mg.csv"), row.names = FALSE, fileEncoding = "UTF-8")
saveRDS(coverage, file.path(out_dir, "cobertura_assistencial_entidades_saude_mg.rds"))
write.csv(original_pending, file.path(out_dir, "auditoria_38_casos_cobertura_assistencial_saude_mg.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(alert_audit, file.path(out_dir, "auditoria_alertas_universo_saude_mg.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(summary, file.path(out_dir, "resumo_cobertura_assistencial_saude_mg.csv"), row.names = FALSE, fileEncoding = "UTF-8")

stopifnot(
  nrow(coverage) == nrow(universe),
  nrow(original_pending) == 38L,
  sum(coverage$recuperada_consulta_cnpj_proprio) == 15L,
  sum(coverage$tem_estrutura_fixa_direta) == 61L,
  nrow(alert_audit) == 7L,
  all(alert_audit$status_resolucao == "resolvido"),
  !anyDuplicated(coverage$cnpj_raiz_8)
)

check_lines <- c(
  "# Validacao: Cobertura Assistencial Complementar (MG)",
  "",
  paste0("- Data: `", Sys.Date(), "`."),
  paste0("- Entidades no universo: **", nrow(coverage), "**."),
  paste0("- Casos originalmente pendentes: **", nrow(original_pending), "** (36 sem unidade direta e 2 somente moveis)."),
  paste0("- Entidades recuperadas pela consulta de CNPJ proprio: **", sum(coverage$recuperada_consulta_cnpj_proprio), "**."),
  paste0("- Entidades com ao menos uma estrutura fixa CNES direta apos a correcao: **", sum(coverage$tem_estrutura_fixa_direta), "** (antes: 46)."),
  paste0("- Alertas de universo com decisao registrada: **", nrow(alert_audit), " de 7**."),
  "",
  "## Resultado Por Classificacao",
  "",
  "| classificacao | entidades |",
  "|---|---:|",
  vapply(seq_len(nrow(summary)), function(i) paste0("| ", summary$cobertura_classificacao[[i]], " | ", summary$entidades[[i]], " |"), character(1)),
  "",
  "## Exemplos Auditados",
  "",
  "- **CISARP:** a rota antiga retornava zero; a busca por CNPJ proprio identificou a clinica CNES 7918747 em Taiobeiras.",
  "- **CONSONORTE:** a rota antiga nao encontrava unidade; a busca por CNPJ proprio identificou a clinica CNES 0975397 e dois vacimoveis.",
  "- **CIMES/CISNES:** permanece sem destino fixo unico; ha unidade movel e oferta indireta documentada, mas nao um hospital atribuivel ao consorcio.",
  "- **CIAS:** a oferta e uma rede regional de SAMU; a sede administrativa nao foi convertida em hospital.",
  "- **CIS/UBA:** os pagamentos historicos foram preservados, mas a entidade inapta nao entra como alternativa atual.",
  "",
  "## Invariantes",
  "",
  "- Nenhum hospital foi atribuido por proximidade ou semelhanca de nome.",
  "- Ausencia de unidade CNES nao foi convertida em capacidade zero.",
  "- Evidencia atual nao foi retroagida automaticamente para 2014-2021.",
  "- Redes moveis ou com prestadores multiplos nao foram reduzidas a um polo fixo ficticio."
)
writeLines(check_lines, file.path(check_dir, "VALIDACAO_COBERTURA_ASSISTENCIAL_COMPLEMENTAR_SAUDE_MG.md"), useBytes = TRUE)

message(
  "Cobertura auditada: ", nrow(coverage), " entidades; ",
  sum(coverage$recuperada_consulta_cnpj_proprio), " recuperadas; ",
  sum(coverage$tem_estrutura_fixa_direta), " com estrutura fixa direta."
)
