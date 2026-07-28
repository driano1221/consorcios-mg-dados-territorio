# =============================================================================
# 03_consolidar_classificacao_v0_3.R
# Camada analitica simplificada da classificacao de politicas publicas
#
# A v0.3 preserva v0.2 e a auditoria MUNIC. Ela nao soma automaticamente
# setores MUNIC heterogeneos para definir a area final de um consorcio.
# =============================================================================

library(dplyr)
library(readr)
library(stringr)
library(writexl)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
class_dir <- file.path(project_dir, "analises", "classificacao_politicas")
out_dir <- file.path(class_dir, "outputs")
input_dir <- file.path(class_dir, "inputs")

path_v0_2 <- file.path(out_dir, "classificacao_areas_politica_mg_v0_2.rds")
path_auditoria_munic <- file.path(out_dir, "auditoria_consolidacao_setores_munic_v0_1.csv")
path_decisoes <- file.path(input_dir, "decisoes_documentais_v0_3.csv")

for (path in c(path_v0_2, path_auditoria_munic, path_decisoes)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

split_terms <- function(x) {
  x <- as.character(x)
  x <- x[!is.na(x) & trimws(x) != ""]
  if (length(x) == 0L) return(character(0))
  x <- unlist(strsplit(x, "\\s*[,;+|]\\s*"), use.names = FALSE)
  x <- trimws(x)
  x[x != ""]
}

split_unique <- function(...) {
  values <- split_terms(unlist(list(...), use.names = FALSE))
  if (length(values) == 0L) return(NA_character_)
  paste(sort(unique(values)), collapse = "; ")
}

has_overlap <- function(x, y) {
  x_terms <- split_terms(x)
  y_terms <- split_terms(y)
  length(x_terms) > 0L && length(y_terms) > 0L && length(intersect(x_terms, y_terms)) > 0L
}

area_to_macro <- c(
  "saude" = "saude",
  "urgencia_emergencia" = "saude",
  "saneamento_basico" = "ambiente_saneamento",
  "residuos_solidos" = "ambiente_saneamento",
  "meio_ambiente" = "ambiente_saneamento",
  "recursos_hidricos" = "ambiente_saneamento",
  "assistencia_social" = "politicas_sociais",
  "educacao" = "politicas_sociais",
  "esporte" = "politicas_sociais",
  "cultura" = "cultura_turismo",
  "turismo" = "cultura_turismo",
  "desenvolvimento_urbano" = "desenvolvimento_territorial",
  "desenvolvimento_regional" = "desenvolvimento_territorial",
  "transporte" = "desenvolvimento_territorial",
  "infraestrutura" = "desenvolvimento_territorial",
  "habitacao" = "desenvolvimento_territorial",
  "agricultura" = "desenvolvimento_rural",
  "inspecao_produtos_origem_animal" = "desenvolvimento_rural",
  "iluminacao_publica" = "gestao_publica",
  "licitacao_compras_compartilhadas" = "gestao_publica",
  "gestao_publica" = "gestao_publica",
  "defesa_consumidor" = "seguranca_cidadania"
)

to_macroareas <- function(x) {
  areas <- split_terms(x)
  macro <- unname(area_to_macro[areas])
  macro <- macro[!is.na(macro)]
  if (length(macro) == 0L) return(NA_character_)
  paste(sort(unique(macro)), collapse = "; ")
}

message("Carregando classificacao v0.2, auditoria MUNIC e decisoes v0.3...")
v0_2 <- readRDS(path_v0_2)
auditoria_munic <- read_csv(path_auditoria_munic, show_col_types = FALSE)
decisoes <- read_csv(path_decisoes, show_col_types = FALSE, na = c("", "NA")) |>
  mutate(cnpj_consorcio = str_pad(as.character(cnpj_consorcio), width = 14, side = "left", pad = "0"))

if (anyDuplicated(decisoes$cnpj_consorcio)) stop("CNPJ duplicado nas decisoes v0.3.")
if (!all(decisoes$cnpj_consorcio %in% v0_2$cnpj_consorcio)) stop("Decisao v0.3 fora da classificacao v0.2.")

# Regras de precedencia:
# 1. decisao documental v0.3;
# 2. decisao documental confirmada/ajustada v0.2;
# 3. nome juridico especifico quando confirmado pela MUNIC;
# 4. MUNIC consistente (setor unico ou mesma macroarea);
# 5. cadastro IPEA legado sem conflito com nome;
# 6. nome juridico como classificacao provisoria;
# 7. pendencia.
classificacao_v0_3 <- v0_2 |>
  left_join(
    auditoria_munic |>
      select(
        cnpj_consorcio, areas_munic_auditadas, macroareas_munic_auditadas,
        comparacao_2015_2019, apoio_cadastro_ipea, regra_recomendada_munic,
        prioridade_revisao_munic, setores_munic_por_suporte
      ),
    by = "cnpj_consorcio"
  ) |>
  left_join(
    decisoes |>
      rename(
        area_decisao_v0_3 = area_politica_final,
        perfil_decisao_v0_3 = perfil_institucional,
        fonte_decisao_v0_3 = fonte_principal,
        status_decisao_v0_3 = status_validacao,
        justificativa_decisao_v0_3 = justificativa,
        fontes_decisao_v0_3 = fontes
      ),
    by = "cnpj_consorcio"
  ) |>
  rowwise() |>
  mutate(
    nome_confirmado_pela_munic = !is.na(areas_nome_razao_social) &&
      !is.na(areas_munic_auditadas) &&
      has_overlap(areas_nome_razao_social, areas_munic_auditadas),
    cadastro_sem_conflito_nome = !is.na(areas_cadastro_ipea) &&
      (is.na(areas_nome_razao_social) || has_overlap(areas_cadastro_ipea, areas_nome_razao_social)),
    decisao_documental_v0_2 = revisao_documental_status %in% c("confirmado", "ajustado"),
    pendencia_documental_v0_2 = revisao_documental_status == "evidencia_insuficiente",
    area_politica_final_v0_3 = case_when(
      !is.na(status_decisao_v0_3) ~ area_decisao_v0_3,
      decisao_documental_v0_2 ~ areas_politica_final,
      pendencia_documental_v0_2 ~ NA_character_,
      multifinalitario_explicito ~ NA_character_,
      nome_confirmado_pela_munic && regra_recomendada_munic %in% c(
        "usar_setor_MUNIC_como_evidencia_setorial",
        "usar_MUNIC_como_evidencia_multiarea_mesma_macroarea",
        "usar_areas_MUNIC_com_apoio_do_cadastro"
      ) ~ split_unique(areas_nome_razao_social, areas_munic_auditadas),
      nome_confirmado_pela_munic ~ areas_nome_razao_social,
      regra_recomendada_munic %in% c(
        "usar_setor_MUNIC_como_evidencia_setorial",
        "usar_MUNIC_como_evidencia_multiarea_mesma_macroarea",
        "usar_areas_MUNIC_com_apoio_do_cadastro"
      ) ~ areas_munic_auditadas,
      cadastro_sem_conflito_nome ~ areas_cadastro_ipea,
      !is.na(areas_nome_razao_social) ~ areas_nome_razao_social,
      TRUE ~ NA_character_
    ),
    fonte_principal_v0_3 = case_when(
      !is.na(status_decisao_v0_3) ~ fonte_decisao_v0_3,
      decisao_documental_v0_2 ~ "revisao_documental_v0_2",
      pendencia_documental_v0_2 ~ "revisao_documental_v0_2",
      multifinalitario_explicito ~ "perfil_institucional",
      nome_confirmado_pela_munic ~ "nome_juridico_e_MUNIC",
      regra_recomendada_munic %in% c(
        "usar_setor_MUNIC_como_evidencia_setorial",
        "usar_MUNIC_como_evidencia_multiarea_mesma_macroarea",
        "usar_areas_MUNIC_com_apoio_do_cadastro"
      ) ~ "MUNIC_auditada",
      cadastro_sem_conflito_nome ~ "cadastro_ipea_arquivo",
      !is.na(areas_nome_razao_social) ~ "nome_juridico",
      TRUE ~ "sem_evidencia"
    ),
    status_validacao_v0_3 = case_when(
      !is.na(status_decisao_v0_3) ~ status_decisao_v0_3,
      decisao_documental_v0_2 ~ "confirmada",
      pendencia_documental_v0_2 ~ "pendente_documento",
      multifinalitario_explicito ~ "provisoria_multifinalitario",
      nome_confirmado_pela_munic ~ "provisoria_coerente",
      regra_recomendada_munic %in% c(
        "usar_setor_MUNIC_como_evidencia_setorial",
        "usar_MUNIC_como_evidencia_multiarea_mesma_macroarea",
        "usar_areas_MUNIC_com_apoio_do_cadastro"
      ) ~ "provisoria_coerente",
      cadastro_sem_conflito_nome ~ "provisoria_cadastro",
      !is.na(areas_nome_razao_social) ~ "provisoria_nome",
      TRUE ~ "pendente_documento"
    ),
    perfil_institucional_v0_3 = case_when(
      !is.na(status_decisao_v0_3) ~ perfil_decisao_v0_3,
      multifinalitario_explicito ~ "multifinalitario",
      is.na(area_politica_final_v0_3) ~ "indeterminado",
      length(split_terms(area_politica_final_v0_3)) == 1L ~ "setorial",
      TRUE ~ "multiarea"
    ),
    macroarea_final_v0_3 = to_macroareas(area_politica_final_v0_3),
    precisa_revisao_v0_3 = status_validacao_v0_3 %in% c(
      "pendente_documento", "aguardar_matriz_filial", "provisoria_multifinalitario"
    ),
    justificativa_v0_3 = case_when(
      !is.na(status_decisao_v0_3) ~ justificativa_decisao_v0_3,
      decisao_documental_v0_2 ~ revisao_documental_justificativa,
      pendencia_documental_v0_2 ~ revisao_documental_justificativa,
      multifinalitario_explicito ~ "Perfil multifinalitario identificado; nao inferir area final a partir da uniao MUNIC.",
      nome_confirmado_pela_munic ~ "Nome juridico e MUNIC compartilham ao menos uma area; setores heterogeneos adicionais da MUNIC nao ampliam automaticamente a classificacao.",
      regra_recomendada_munic %in% c(
        "usar_setor_MUNIC_como_evidencia_setorial",
        "usar_MUNIC_como_evidencia_multiarea_mesma_macroarea",
        "usar_areas_MUNIC_com_apoio_do_cadastro"
      ) ~ "MUNIC auditada sem heterogeneidade entre macroareas nao confirmada.",
      cadastro_sem_conflito_nome ~ "Classificacao herdada do cadastro IPEA arquivo, sem conflito detectado com o nome juridico.",
      !is.na(areas_nome_razao_social) ~ "Classificacao provisoria derivada do nome juridico; requer documento para confirmacao.",
      TRUE ~ "Sem evidencia suficiente para atribuir area de politica publica."
    ),
    fontes_v0_3 = case_when(
      !is.na(status_decisao_v0_3) ~ fontes_decisao_v0_3,
      decisao_documental_v0_2 ~ revisao_documental_fontes,
      pendencia_documental_v0_2 ~ revisao_documental_fontes,
      TRUE ~ NA_character_
    )
  ) |>
  ungroup() |>
  arrange(status_validacao_v0_3, sigla, razao_social)

analitica <- classificacao_v0_3 |>
  transmute(
    cnpj_consorcio, sigla, razao_social, situacao, ano_fundacao,
    area_politica_final = area_politica_final_v0_3,
    macroarea_final = macroarea_final_v0_3,
    perfil_institucional = perfil_institucional_v0_3,
    fonte_principal = fonte_principal_v0_3,
    status_validacao = status_validacao_v0_3,
    precisa_revisao = precisa_revisao_v0_3
  )

pendencias <- classificacao_v0_3 |>
  filter(precisa_revisao_v0_3 | status_validacao_v0_3 == "pendente_documento") |>
  transmute(
    cnpj_consorcio, sigla, razao_social, situacao, ano_fundacao,
    area_politica_final = area_politica_final_v0_3,
    perfil_institucional = perfil_institucional_v0_3,
    fonte_principal = fonte_principal_v0_3,
    status_validacao = status_validacao_v0_3,
    justificativa = justificativa_v0_3,
    setores_MUNIC_observados = areas_munic_auditadas,
    suporte_setores_MUNIC = setores_munic_por_suporte,
    recomendacao_MUNIC = regra_recomendada_munic,
    fontes = fontes_v0_3
  )

resumo <- bind_rows(
  analitica |>
    count(status_validacao, fonte_principal, name = "n_cnpjs") |>
    mutate(secao = "status_e_fonte"),
  analitica |>
    count(perfil_institucional, name = "n_cnpjs") |>
    mutate(secao = "perfil", status_validacao = NA_character_, fonte_principal = NA_character_)
) |>
  select(secao, status_validacao, fonte_principal, perfil_institucional, n_cnpjs)

out_analitica_csv <- file.path(out_dir, "classificacao_areas_politica_mg_v0_3_analitica.csv")
out_analitica_rds <- file.path(out_dir, "classificacao_areas_politica_mg_v0_3_analitica.rds")
out_analitica_xlsx <- file.path(out_dir, "classificacao_areas_politica_mg_v0_3_analitica.xlsx")
out_tecnica_csv <- file.path(out_dir, "classificacao_areas_politica_mg_v0_3_tecnica.csv")
out_resumo_csv <- file.path(out_dir, "resumo_classificacao_areas_politica_mg_v0_3.csv")
out_pendencias_xlsx <- file.path(out_dir, "revisao_pendente_classificacao_mg_v0_3.xlsx")

write_csv(analitica, out_analitica_csv, na = "")
saveRDS(analitica, out_analitica_rds)
write_xlsx(list(resumo = resumo, classificacao_analitica = analitica), out_analitica_xlsx)
write_csv(classificacao_v0_3, out_tecnica_csv, na = "")
write_csv(resumo, out_resumo_csv, na = "")
write_xlsx(list(resumo = resumo, pendencias = pendencias, classificacao_analitica = analitica), out_pendencias_xlsx)

stopifnot(nrow(analitica) == 223L)
stopifnot(!anyDuplicated(analitica$cnpj_consorcio))
stopifnot(all(analitica$status_validacao %in% c(
  "confirmada", "provisoria_coerente", "provisoria_cadastro", "provisoria_nome",
  "provisoria_multifinalitario", "pendente_documento", "fora_escopo", "aguardar_matriz_filial"
)))
stopifnot(all(analitica$cnpj_consorcio[analitica$status_validacao == "confirmada"] %in% classificacao_v0_3$cnpj_consorcio))

message("Classificacao v0.3 concluida.")
message("  CNPJs: ", nrow(analitica))
message("  Confirmadas: ", sum(analitica$status_validacao == "confirmada"))
message("  Pendentes/revisao: ", sum(analitica$precisa_revisao))
