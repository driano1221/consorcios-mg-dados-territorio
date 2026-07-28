# =============================================================================
# 07_consolidar_classificacao_v0_5.R
# Registra a decisao de validar os casos provisoria_coerente para uso analitico.
# A v0.4 continua preservada como trilha historica.
# =============================================================================

library(dplyr)
library(readr)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
class_dir <- file.path(project_dir, "analises", "classificacao_politicas")
out_dir <- file.path(class_dir, "outputs")

path_v04 <- file.path(out_dir, "classificacao_areas_politica_mg_v0_4_completa.csv")
if (!file.exists(path_v04)) stop("Arquivo nao encontrado: ", path_v04)

v04 <- read_csv(path_v04, show_col_types = FALSE)
stopifnot(nrow(v04) == 223L)
stopifnot(sum(v04$status_validacao == "provisoria_coerente") == 94L)

v05 <- v04 |>
  mutate(
    excluir_associacao = cnpj_consorcio == "20362307000140",
    status_validacao_v0_5 = if_else(
      status_validacao == "provisoria_coerente",
      "validada_usuario_coerente",
      status_validacao
    ),
    decisao_usuario_v0_5 = if_else(
      status_validacao == "provisoria_coerente",
      "validar_provisoria_coerente",
      decisao_usuario
    ),
    justificativa_v0_5 = if_else(
      status_validacao == "provisoria_coerente",
      "Area validada pelo usuario para uso analitico. A fonte e a trilha de evidencia da v0.4 foram preservadas.",
      justificativa
    ),
    perfil_institucional_v0_5 = case_when(
      excluir_associacao ~ NA_character_,
      perfil_institucional %in% c("multifinalitario", "multissetorial") ~ "multifinalitario_ou_multissetorial",
      TRUE ~ perfil_institucional
    ),
    area_politica_final_v0_5 = if_else(excluir_associacao, NA_character_, area_politica_final),
    macroarea_final_v0_5 = if_else(excluir_associacao, NA_character_, macroarea_final),
    fonte_principal_v0_5 = if_else(excluir_associacao, "fora_escopo", fonte_principal),
    status_validacao_v0_5 = if_else(excluir_associacao, "excluida_associacao_municipal", status_validacao_v0_5),
    decisao_usuario_v0_5 = if_else(excluir_associacao, "excluir_associacao_municipal", decisao_usuario_v0_5),
    justificativa_v0_5 = if_else(excluir_associacao, "Entidade associativa, e nao consorcio intermunicipal. Preservada no arquivo tecnico e retirada da camada analitica de consorcios.", justificativa_v0_5),
    ativo_analise_v0_5 = if_else(excluir_associacao, FALSE, ativo_analise),
    precisa_revisao_v0_5 = status_validacao_v0_5 == "validada_usuario_perfil_sem_area"
  ) |>
  select(
    cnpj_consorcio, sigla, razao_social, situacao, ano_fundacao,
    area_politica_final = area_politica_final_v0_5,
    macroarea_final = macroarea_final_v0_5,
    perfil_institucional = perfil_institucional_v0_5,
    fonte_principal, status_validacao = status_validacao_v0_5,
    ativo_analise = ativo_analise_v0_5, decisao_usuario = decisao_usuario_v0_5,
    precisa_revisao = precisa_revisao_v0_5, justificativa = justificativa_v0_5
  ) |>
  arrange(!ativo_analise, sigla, razao_social)

ativa <- v05 |> filter(ativo_analise)
resumo <- v05 |>
  count(ativo_analise, status_validacao, fonte_principal, name = "n_cnpjs") |>
  arrange(!ativo_analise, desc(n_cnpjs), status_validacao)

stopifnot(nrow(ativa) == 216L)
stopifnot(sum(ativa$status_validacao == "validada_usuario_coerente") == 94L)
stopifnot(sum(ativa$precisa_revisao) == 16L)
stopifnot(sum(v05$status_validacao == "excluida_associacao_municipal") == 1L)
stopifnot(!any(ativa$perfil_institucional %in% c("multifinalitario", "multissetorial", "associacao_municipal")))

write_csv(v05, file.path(out_dir, "classificacao_areas_politica_mg_v0_5_completa.csv"), na = "")
write_csv(ativa, file.path(out_dir, "classificacao_areas_politica_mg_v0_5_analitica_ativa.csv"), na = "")
saveRDS(ativa, file.path(out_dir, "classificacao_areas_politica_mg_v0_5_analitica_ativa.rds"))
write_csv(resumo, file.path(out_dir, "resumo_classificacao_areas_politica_mg_v0_5.csv"), na = "")

cat("Classificacao v0.5 concluida. Camada ativa:", nrow(ativa), "CNPJs.\n")
