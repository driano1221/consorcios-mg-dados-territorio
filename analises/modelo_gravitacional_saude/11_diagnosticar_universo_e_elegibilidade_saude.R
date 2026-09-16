# =============================================================================
# 11_diagnosticar_universo_e_elegibilidade_saude.R
#
# Compara as 66 entidades com MIDES às 18 sem MIDES, classifica a funcao das
# unidades CNES atuais e historicas e produz mapas diagnosticos. Reutiliza as
# bases existentes; nao consulta novamente o CNES e nao define a amostra final.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(sf)
  library(stringi)
})

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
analysis_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude")
out_dir <- file.path(analysis_dir, "outputs")
figure_dir <- file.path(out_dir, "figuras")

paths <- list(
  universe = file.path(out_dir, "universo_saude_mg_entidades.csv"),
  current_units = file.path(out_dir, "capacidade_unidades_cnes_saude_mg.csv"),
  historical_units = file.path(out_dir, "cnes_historico_unidades_saude_mg_2014_2021.csv"),
  historical_entities = file.path(out_dir, "cnes_historico_entidades_saude_mg_2014_2021.csv"),
  municipalities = file.path(project_dir, "dashboards/base1_shiny/data/mg_municipios_sf_web.rds"),
  multiarea = file.path(analysis_dir, "evidencias/auditoria_multiarea_2026_09_16.csv"),
  documentary = file.path(analysis_dir, "evidencias/auditoria_documental_21_entidades_2026_09_16.csv"),
  dossie = file.path(out_dir, "dossie_91_entidades_ano_sem_fixa.csv"),
  conflicts = file.path(analysis_dir, "evidencias/decisoes_fichas_cnes_conflitantes_2026_09_16.csv")
)
missing_paths <- unlist(paths)[!file.exists(unlist(paths))]
if (length(missing_paths)) stop("Arquivos obrigatorios ausentes: ", paste(missing_paths, collapse = "; "))
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

read_chars <- function(path) {
  data <- read.csv(
    path, check.names = FALSE, stringsAsFactors = FALSE,
    colClasses = "character"
  )
  names(data)[grepl("cnpj_raiz_8$", names(data))] <- "cnpj_raiz_8"
  data
}

as_flag <- function(x) toupper(trimws(as.character(x))) == "TRUE"
as_int <- function(x) suppressWarnings(as.integer(x))

decode_unicode_tags <- function(x) {
  decode_one <- function(value) {
    if (is.na(value)) return(NA_character_)
    repeat {
      hit <- regexpr("<U\\+[0-9A-Fa-f]{4,6}>", value, perl = TRUE)
      if (hit[[1]] < 0L) break
      token <- regmatches(value, hit)
      code <- strtoi(gsub("<U\\+|>", "", token), base = 16L)
      before <- if (hit[[1]] > 1L) substr(value, 1L, hit[[1]] - 1L) else ""
      after_start <- hit[[1]] + attr(hit, "match.length")
      after <- if (after_start <= nchar(value)) substr(value, after_start, nchar(value)) else ""
      value <- paste0(before, intToUtf8(code), after)
    }
    value
  }
  vapply(x, decode_one, character(1), USE.NAMES = FALSE)
}

normalize_name <- function(x) {
  value <- decode_unicode_tags(as.character(x))
  value <- stri_trans_general(value, "Latin-ASCII")
  value <- toupper(trimws(value))
  gsub("[^A-Z0-9]+", " ", value) |> gsub("[[:space:]]+", " ", x = _)
}

universe <- read_chars(paths$universe) |>
  mutate(
    aparece_mides_mg = as_flag(aparece_mides_mg),
    abertura_apos_periodo_mides = as_flag(abertura_apos_periodo_mides),
    ano_abertura_matriz = as_int(ano_abertura_matriz)
  )

current_clinical_types <- c(
  "CLINICA/CENTRO DE ESPECIALIDADE", "POLICLINICA",
  "UNIDADE DE APOIO DIAGNOSE E TERAPIA (SADT ISOLADO)",
  "HOSPITAL/DIA - ISOLADO"
)
current_nonclinical_types <- c(
  "CENTRAL DE GESTAO EM SAUDE", "CENTRAL DE REGULACAO MEDICA DAS URGENCIAS",
  "FARMACIA", "UNIDADE DE VIGILANCIA EM SAUDE", "TELESSAUDE"
)

conflicts <- read_chars(paths$conflicts) |>
  select(cnpj_raiz_8, cnes, decisao_retrato_atual, evidencia_oficial)
stopifnot(!anyDuplicated(conflicts[c("cnpj_raiz_8", "cnes")]))
current_units <- read_chars(paths$current_units) |>
  left_join(conflicts, by = c("cnpj_raiz_8", "cnes"), relationship = "many-to-one") |>
  mutate(
    unidade_movel_ou_itinerante = as_flag(unidade_movel_ou_itinerante),
    classificacao_fixa_pendente = as_flag(classificacao_fixa_pendente),
    codigo_ibge_6 = substr(paste0(codigo_ibge_cnes, "000000"), 1L, 6L),
    codigo_ibge_6 = ifelse(is.na(codigo_ibge_cnes) | !nzchar(codigo_ibge_cnes), NA_character_, codigo_ibge_6),
    funcao_assistencial = case_when(
      !is.na(decisao_retrato_atual) ~ decisao_retrato_atual,
      classificacao_fixa_pendente ~ "pendente_nome_tipo",
      unidade_movel_ou_itinerante ~ "unidade_movel",
      tipo_estabelecimento_cnes %in% current_clinical_types ~ "destino_clinico_fixo",
      tipo_estabelecimento_cnes %in% current_nonclinical_types ~ "estrutura_fixa_nao_clinica",
      TRUE ~ "pendente_tipo_atual"
    ),
    regra_classificacao_funcional = case_when(
      cnes == "5563003" ~ "nome_vacimovel_confirmado_em_lista_oficial_cnes",
      cnes == "3987981" ~ "tipo_clinica_com_atendimento_e_profissionais_sus",
      classificacao_fixa_pendente ~ "conflito_nome_tipo_ainda_pendente",
      unidade_movel_ou_itinerante ~ "tipo_ou_nome_movel",
      tipo_estabelecimento_cnes %in% current_clinical_types ~ "tipo_cnes_clinico",
      TRUE ~ "tipo_cnes_sem_destino_clinico_presencial"
    ),
    decisao_tempo_principal = funcao_assistencial == "destino_clinico_fixo"
  )

historical_clinical_types <- c("04", "05", "22", "36", "39", "62")
historical_nonclinical_types <- c("64", "68", "76", "81")

historical_units <- read_chars(paths$historical_units) |>
  mutate(
    tipo_unidade_codigo = sprintf("%02d", as_int(tipo_unidade_codigo)),
    unidade_movel = as_flag(unidade_movel),
    funcao_assistencial = case_when(
      unidade_movel ~ "unidade_movel",
      tipo_unidade_codigo %in% historical_clinical_types ~ "destino_clinico_fixo",
      tipo_unidade_codigo %in% historical_nonclinical_types ~ "estrutura_fixa_nao_clinica",
      TRUE ~ "pendente_tipo_historico"
    ),
    decisao_tempo_principal = funcao_assistencial == "destino_clinico_fixo"
  )

current_by_entity <- current_units |>
  summarise(
    n_unidades_cnes_atual = n(),
    n_destinos_clinicos_fixos_atual = sum(funcao_assistencial == "destino_clinico_fixo"),
    n_estruturas_fixas_nao_clinicas_atual = sum(funcao_assistencial == "estrutura_fixa_nao_clinica"),
    n_unidades_moveis_atual = sum(funcao_assistencial == "unidade_movel"),
    n_unidades_pendentes_atual = sum(grepl("^pendente_", funcao_assistencial)),
    tem_destino_clinico_fixo_atual = any(funcao_assistencial == "destino_clinico_fixo"),
    .by = cnpj_raiz_8
  )

historical_by_entity_year <- historical_units |>
  summarise(
    n_unidades_cnes_historicas = n(),
    n_destinos_clinicos_fixos = sum(funcao_assistencial == "destino_clinico_fixo"),
    n_estruturas_fixas_nao_clinicas = sum(funcao_assistencial == "estrutura_fixa_nao_clinica"),
    n_unidades_moveis = sum(funcao_assistencial == "unidade_movel"),
    n_unidades_pendentes = sum(funcao_assistencial == "pendente_tipo_historico"),
    tem_destino_clinico_fixo = any(funcao_assistencial == "destino_clinico_fixo"),
    .by = c(cnpj_raiz_8, ano)
  )

historical_entities <- read_chars(paths$historical_entities)
entity_year_eligibility <- historical_entities |>
  select(cnpj_raiz_8, cnpj_canonico, sigla_canonica, razao_social_canonica, ano) |>
  left_join(historical_by_entity_year, by = c("cnpj_raiz_8", "ano")) |>
  mutate(
    across(starts_with("n_"), ~ coalesce(as_int(.x), 0L)),
    tem_destino_clinico_fixo = coalesce(tem_destino_clinico_fixo, FALSE),
    uso_tempo_principal = if_else(
      tem_destino_clinico_fixo,
      "usar_destino_clinico_diretamente_vinculado",
      "sem_destino_clinico_direto_documentado"
    )
  )

historical_ever <- entity_year_eligibility |>
  summarise(
    n_anos_destino_clinico_historico = sum(tem_destino_clinico_fixo),
    primeiro_ano_destino_clinico = if (any(tem_destino_clinico_fixo)) min(as_int(ano[tem_destino_clinico_fixo])) else NA_integer_,
    ultimo_ano_destino_clinico = if (any(tem_destino_clinico_fixo)) max(as_int(ano[tem_destino_clinico_fixo])) else NA_integer_,
    tem_destino_clinico_historico = any(tem_destino_clinico_fixo),
    .by = cnpj_raiz_8
  )

entity_diagnostic <- universe |>
  left_join(current_by_entity, by = "cnpj_raiz_8") |>
  left_join(historical_ever, by = "cnpj_raiz_8") |>
  mutate(
    across(
      c(n_unidades_cnes_atual, n_destinos_clinicos_fixos_atual,
        n_estruturas_fixas_nao_clinicas_atual, n_unidades_moveis_atual,
        n_unidades_pendentes_atual, n_anos_destino_clinico_historico),
      ~ coalesce(as_int(.x), 0L)
    ),
    tem_destino_clinico_fixo_atual = coalesce(tem_destino_clinico_fixo_atual, FALSE),
    tem_destino_clinico_historico = coalesce(tem_destino_clinico_historico, FALSE)
  )

audit_18 <- entity_diagnostic |>
  filter(!aparece_mides_mg) |>
  mutate(
    classificacao_auditoria_18 = case_when(
      abertura_apos_periodo_mides ~ "abertura_apos_2021",
      situacao_matriz != "Ativa" ~ "inativa_sem_mides_e_sem_oferta_cnes_2014_2021",
      !tem_destino_clinico_fixo_atual & !tem_destino_clinico_historico ~ "ativa_sem_mides_e_sem_evidencia_assistencial",
      TRUE ~ "revisao_individual"
    ),
    decisao_modelo_2014_2021 = case_when(
      classificacao_auditoria_18 == "abertura_apos_2021" ~ "fora_do_periodo; preservar para extensao futura",
      classificacao_auditoria_18 == "inativa_sem_mides_e_sem_oferta_cnes_2014_2021" ~ "fora_do_modelo_principal; manter cadastro historico",
      classificacao_auditoria_18 == "ativa_sem_mides_e_sem_evidencia_assistencial" ~ "excluir do principal ate surgir evidencia; usar em sensibilidade cadastral",
      TRUE ~ "revisao humana"
    ),
    evidencia_insuficiente_nao_significa_inexistencia = TRUE
  ) |>
  select(
    cnpj_raiz_8, cnpj_canonico, sigla_canonica, razao_social_canonica,
    municipio_sede_canonico, situacao_matriz, ano_abertura_matriz,
    abertura_apos_periodo_mides, escopo_saude, n_unidades_cnes_atual,
    n_destinos_clinicos_fixos_atual, n_estruturas_fixas_nao_clinicas_atual,
    n_unidades_moveis_atual, n_unidades_pendentes_atual,
    n_anos_destino_clinico_historico, primeiro_ano_destino_clinico,
    ultimo_ano_destino_clinico, classificacao_auditoria_18,
    decisao_modelo_2014_2021, evidencia_insuficiente_nao_significa_inexistencia
  ) |>
  arrange(factor(classificacao_auditoria_18, levels = c(
    "abertura_apos_2021", "ativa_sem_mides_e_sem_evidencia_assistencial",
    "inativa_sem_mides_e_sem_oferta_cnes_2014_2021", "revisao_individual"
  )), razao_social_canonica)

comparison <- entity_diagnostic |>
  mutate(grupo_mides = if_else(aparece_mides_mg, "com_pagamento_mides", "sem_pagamento_mides")) |>
  summarise(
    n_entidades = n(),
    n_ativas_atualmente = sum(situacao_matriz == "Ativa"),
    pct_ativas_atualmente = round(100 * mean(situacao_matriz == "Ativa"), 1),
    n_abertas_apos_2021 = sum(abertura_apos_periodo_mides),
    n_com_cnes_atual = sum(n_unidades_cnes_atual > 0L),
    pct_com_cnes_atual = round(100 * mean(n_unidades_cnes_atual > 0L), 1),
    n_com_destino_clinico_fixo_atual = sum(tem_destino_clinico_fixo_atual),
    pct_com_destino_clinico_fixo_atual = round(100 * mean(tem_destino_clinico_fixo_atual), 1),
    n_com_destino_clinico_historico = sum(tem_destino_clinico_historico),
    pct_com_destino_clinico_historico = round(100 * mean(tem_destino_clinico_historico), 1),
    n_unidades_cnes_atual = sum(n_unidades_cnes_atual),
    n_destinos_clinicos_fixos_atual = sum(n_destinos_clinicos_fixos_atual),
    n_estruturas_fixas_nao_clinicas_atual = sum(n_estruturas_fixas_nao_clinicas_atual),
    n_unidades_moveis_atual = sum(n_unidades_moveis_atual),
    n_unidades_pendentes_atual = sum(n_unidades_pendentes_atual),
    .by = grupo_mides
  ) |>
  arrange(desc(grupo_mides == "com_pagamento_mides"))

multiarea <- read_chars(paths$multiarea) |>
  left_join(
    entity_diagnostic |>
      select(
        cnpj_raiz_8, aparece_mides_mg, n_unidades_cnes_atual,
        n_destinos_clinicos_fixos_atual, n_unidades_moveis_atual,
        n_anos_destino_clinico_historico
      ),
    by = "cnpj_raiz_8"
  )

# Acrescenta a rodada documental sem sobrescrever a triagem cadastral de 10/09.
# A evidencia de uma entidade nao e promovida a prova de oferta em cada ano.
documentary <- read_chars(paths$documentary)
stopifnot(!anyDuplicated(documentary$cnpj_raiz_8))
dossie_final <- read_chars(paths$dossie) |>
  left_join(
    documentary |> select(cnpj_raiz_8, evidencia_documental, fonte_principal,
      classificacao_final, decisao_modelo_principal, uso_sensibilidade, limite),
    by = "cnpj_raiz_8", relationship = "many-to-one"
  ) |>
  mutate(
    rodada_documental = case_when(
      !is.na(classificacao_final) ~ "pesquisa_16_09_decisao_com_limites",
      cnpj_raiz_8 %in% c("01272081", "06070075") ~ "pesquisa_multiarea_16_09_sem_polo_anual_adicional",
      TRUE ~ "pesquisa_prioritaria_10_09_decisao_com_limites"
    ),
    data_fechamento_decisao = "2026-09-16"
  )
stopifnot(nrow(dossie_final) == 91L,
          !anyDuplicated(dossie_final[c("cnpj_raiz_8", "ano")]))
write.csv(dossie_final, file.path(out_dir, "decisoes_documentais_91_entidades_ano.csv"),
          row.names = FALSE, na = "", fileEncoding = "UTF-8")

write.csv(
  current_units,
  file.path(out_dir, "elegibilidade_assistencial_unidades_atuais_saude_mg.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8"
)
write.csv(
  historical_units,
  file.path(out_dir, "elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8"
)
write.csv(
  entity_year_eligibility,
  file.path(out_dir, "elegibilidade_assistencial_entidade_ano_saude_mg_2014_2021.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8"
)
write.csv(
  audit_18,
  file.path(out_dir, "auditoria_18_entidades_sem_mides_saude_mg.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8"
)
write.csv(
  comparison,
  file.path(out_dir, "comparacao_entidades_com_sem_mides_saude_mg.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8"
)
write.csv(
  multiarea,
  file.path(out_dir, "auditoria_multiarea_saude_mg.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8"
)

mg_sf <- readRDS(paths$municipalities) |>
  mutate(cod_ibge_6 = substr(as.character(cod_ibge_6), 1L, 6L))
mg_lookup <- mg_sf |>
  st_drop_geometry() |>
  transmute(cod_ibge_6, municipio_chave = normalize_name(municipio_geo))
mg_centroids <- suppressWarnings(st_point_on_surface(mg_sf)) |>
  select(cod_ibge_6)

entity_locations <- entity_diagnostic |>
  mutate(
    municipio_chave = normalize_name(municipio_sede_canonico),
    categoria_universo = case_when(
      aparece_mides_mg ~ "66 com MIDES",
      abertura_apos_periodo_mides ~ "Sem MIDES: abertura apos 2021",
      situacao_matriz == "Ativa" ~ "Sem MIDES: ativa sem evidencia",
      TRUE ~ "Sem MIDES: inativa ou inapta"
    )
  ) |>
  left_join(mg_lookup, by = "municipio_chave") |>
  left_join(mg_centroids, by = "cod_ibge_6") |>
  st_as_sf()

if (nrow(entity_locations) != 84L || any(st_is_empty(entity_locations))) {
  missing_flag <- is.na(entity_locations$cod_ibge_6) | st_is_empty(entity_locations)
  missing_seats <- entity_locations[missing_flag, ] |>
    st_drop_geometry() |>
    distinct(municipio_sede_canonico, municipio_chave)
  message(paste(capture.output(print(missing_seats)), collapse = "\n"))
  stop("Falha ao localizar as 84 sedes no mapa municipal de MG.")
}

entity_palette <- c(
  "66 com MIDES" = "#1F6F8B",
  "Sem MIDES: abertura apos 2021" = "#E69F00",
  "Sem MIDES: ativa sem evidencia" = "#CC3311",
  "Sem MIDES: inativa ou inapta" = "#777777"
)

p_entities <- ggplot() +
  geom_sf(data = mg_sf, fill = "#F6F7F8", color = "#D5DADD", linewidth = 0.08) +
  geom_sf(
    data = entity_locations,
    aes(color = categoria_universo), size = 2.2, alpha = 0.88
  ) +
  scale_color_manual(values = entity_palette, name = NULL) +
  labs(
    title = "Entidades de saude em MG: presenca no MIDES",
    subtitle = "Pontos representam municipios das sedes cadastrais; presenca financeira nao equivale a filiacao juridica",
    caption = "Fontes: cadastro IPEA, MIDES 2014-2021 e malha municipal do dashboard (IBGE/geobr)."
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", color = "#173B52"),
    legend.position = "bottom",
    plot.caption = element_text(color = "#58666E")
  )

unit_locations <- current_units |>
  filter(!is.na(codigo_ibge_6), nzchar(codigo_ibge_6)) |>
  count(codigo_ibge_6, funcao_assistencial, name = "n_unidades") |>
  rename(cod_ibge_6 = codigo_ibge_6) |>
  left_join(mg_centroids, by = "cod_ibge_6") |>
  st_as_sf()

unit_labels <- c(
  destino_clinico_fixo = "Destino clinico fixo",
  estrutura_fixa_nao_clinica = "Estrutura fixa nao clinica",
  unidade_movel = "Unidade movel",
  pendente_nome_tipo = "Classificacao pendente"
)
unit_locations <- unit_locations |>
  mutate(
    funcao_assistencial = factor(
      funcao_assistencial,
      levels = names(unit_labels), labels = unname(unit_labels)
    )
  )

p_units <- ggplot() +
  geom_sf(data = mg_sf, fill = "#F6F7F8", color = "#D5DADD", linewidth = 0.05) +
  geom_sf(
    data = unit_locations,
    aes(size = n_unidades), color = "#7B2CBF", fill = "#C9A7E8",
    shape = 21, alpha = 0.82, stroke = 0.35
  ) +
  facet_wrap(~ funcao_assistencial, ncol = 2) +
  scale_size_area(max_size = 9, breaks = c(1, 5, 10, 25, 50), name = "Unidades no municipio") +
  labs(
    title = "Distribuicao municipal das unidades CNES vinculadas",
    subtitle = "Pontos representativos dos municipios; unidades moveis nao representam destino fixo de viagem",
    caption = "CNES: coleta 03/09/2026; filtro 16/09/2026. Mapa: 669/670 unidades; movel 5563003 sem municipio no cache."
  ) +
  theme_void(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", color = "#173B52"),
    strip.text = element_text(face = "bold", color = "#173B52"),
    legend.position = "bottom",
    plot.caption = element_text(color = "#58666E")
  )

ggsave(
  file.path(figure_dir, "mapa_entidades_saude_mg_presenca_mides.png"),
  p_entities, device = grDevices::png,
  width = 11.5, height = 8.5, dpi = 220, bg = "white"
)
ggsave(
  file.path(figure_dir, "mapa_unidades_cnes_saude_mg_por_funcao.png"),
  p_units, device = grDevices::png,
  width = 13.5, height = 10, dpi = 220, bg = "white"
)

cat("Diagnostico concluido.\n")
print(comparison)
print(count(audit_18, classificacao_auditoria_18))
print(count(current_units, funcao_assistencial))
print(count(historical_units, funcao_assistencial))
