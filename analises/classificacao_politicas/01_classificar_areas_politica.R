# =============================================================================
# 01_classificar_areas_politica.R
# Classificacao auditavel de areas de politica publica - consorcios de MG
#
# Unidade: CNPJ de consorcio
# Escopo: recorte MG do cadastro IPEA (223 CNPJs)
#
# Esta rotina nao altera os setores originais e nao reclassifica valores MIDES.
# Ela consolida evidencias, preserva as fontes e separa casos para revisao.
# =============================================================================

library(dplyr)
library(readr)
library(stringr)
library(writexl)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
data_dir <- file.path(project_dir, "dados", "processado")
app_data_dir <- file.path(project_dir, "dashboards", "base1_shiny", "data")
out_dir <- file.path(project_dir, "analises", "classificacao_politicas", "outputs")
input_dir <- file.path(project_dir, "analises", "classificacao_politicas", "inputs")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(input_dir, recursive = TRUE, showWarnings = FALSE)

path_cadastro <- file.path(data_dir, "cadastro_base.rds")
path_base1 <- file.path(app_data_dir, "base_1_vinculos_2015_2019.rds")
path_mides <- file.path(data_dir, "painel_mg_anual.rds")
path_revisao_documental <- file.path(input_dir, "revisao_documental_39_cnpjs_v0_2.csv")

for (path in c(path_cadastro, path_base1, path_mides)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

to_ascii_upper <- function(x) {
  x <- ifelse(is.na(x), "", as.character(x))
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT")
  x <- toupper(x)
  x <- gsub("[^A-Z0-9]+", " ", x)
  trimws(gsub("\\s+", " ", x))
}

non_empty <- function(x) {
  x <- as.character(x)
  x[!is.na(x) & trimws(x) != ""]
}

split_unique <- function(...) {
  x <- unlist(list(...), use.names = FALSE)
  x <- non_empty(x)
  if (length(x) == 0L) return(NA_character_)
  x <- unlist(strsplit(x, "\\s*[,;+|]\\s*"), use.names = FALSE)
  x <- trimws(x)
  x <- x[x != ""]
  if (length(x) == 0L) return(NA_character_)
  paste(sort(unique(x)), collapse = "; ")
}

split_terms <- function(x) {
  x <- non_empty(x)
  if (length(x) == 0L) return(character(0))
  x <- unlist(strsplit(x, "\\s*[,;+|]\\s*"), use.names = FALSE)
  x <- trimws(x)
  x[x != ""]
}

area_dictionary <- c(
  "SAUDE" = "saude",
  "ASSIST SOCIAL" = "assistencia_social",
  "ASSIST DES SOCIAL" = "assistencia_social",
  "EDUCACAO" = "educacao",
  "CULTURA" = "cultura",
  "TURISMO" = "turismo",
  "ESPORTE" = "esporte",
  "GESTAO AGUA" = "recursos_hidricos",
  "GESTAO AGUAS" = "recursos_hidricos",
  "SANEAMENTO" = "saneamento_basico",
  "SANEAM BASICO" = "saneamento_basico",
  "MANEJO RES SOLIDO" = "residuos_solidos",
  "MEIO AMBIENTE" = "meio_ambiente",
  "DES URBANO" = "desenvolvimento_urbano",
  "DESENVOLVIMENTO URBANO" = "desenvolvimento_urbano",
  "DESENVOLVIMENTO REGIONAL" = "desenvolvimento_regional",
  "TRANSPORTE" = "transporte",
  "HABITACAO" = "habitacao",
  "AGRICULTURA" = "agricultura",
  "ILUMINACAO PUBLICA" = "iluminacao_publica",
  "LICITACAO COMPARTILHADA" = "licitacao_compras_compartilhadas",
  "LICITACAO" = "licitacao_compras_compartilhadas",
  "GESTAO PUBLICA" = "gestao_publica"
)

map_source_areas <- function(x) {
  terms <- to_ascii_upper(split_terms(x))
  mapped <- unname(area_dictionary[terms])
  mapped <- mapped[!is.na(mapped)]
  if (length(mapped) == 0L) return(NA_character_)
  paste(sort(unique(mapped)), collapse = "; ")
}

map_name_areas <- function(x) {
  txt <- to_ascii_upper(x)
  if (txt == "") return(NA_character_)
  areas <- character(0)

  if (str_detect(txt, "SAUDE")) areas <- c(areas, "saude")
  if (str_detect(txt, "URGENCIA|EMERGENCIA|SAMU")) areas <- c(areas, "urgencia_emergencia")
  if (str_detect(txt, "SANEAMENTO|ESGOT|ABASTECIMENTO")) areas <- c(areas, "saneamento_basico")
  if (str_detect(txt, "RESIDU|ATERRO|LIXO")) areas <- c(areas, "residuos_solidos")
  if (str_detect(txt, "AMBIENT|CONSERVACAO|ECOLOG")) areas <- c(areas, "meio_ambiente")
  if (str_detect(txt, "RECURSOS HIDRIC|BACIA HIDRO|GESTAO DAS AGUAS")) areas <- c(areas, "recursos_hidricos")
  if (str_detect(txt, "AGRICULT|AGROPEC|RURAL|CAFE")) areas <- c(areas, "agricultura")
  if (str_detect(txt, "ILUMINACAO")) areas <- c(areas, "iluminacao_publica")
  if (str_detect(txt, "LICITACAO|COMPRA[S ]+COMPARTILH|GESTAO PUBLICA")) areas <- c(areas, "licitacao_compras_compartilhadas")
  if (str_detect(txt, "TRANSPORTE|MOBILIDADE")) areas <- c(areas, "transporte")
  if (str_detect(txt, "INFRAESTRUTURA|OBRAS")) areas <- c(areas, "infraestrutura")
  if (str_detect(txt, "HABITAC")) areas <- c(areas, "habitacao")
  if (str_detect(txt, "EDUCAC")) areas <- c(areas, "educacao")
  if (str_detect(txt, "CULTURA")) areas <- c(areas, "cultura")
  if (str_detect(txt, "TURIS")) areas <- c(areas, "turismo")
  if (str_detect(txt, "ESPORTE")) areas <- c(areas, "esporte")
  if (str_detect(txt, "ASSISTENCIA SOCIAL|ASSIST SOCIAL|CIDADANIA")) areas <- c(areas, "assistencia_social")
  if (str_detect(txt, "DESENVOLVIMENTO")) areas <- c(areas, "desenvolvimento_regional")

  if (length(areas) == 0L) return(NA_character_)
  paste(sort(unique(areas)), collapse = "; ")
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
  "iluminacao_publica" = "gestao_publica",
  "licitacao_compras_compartilhadas" = "gestao_publica",
  "gestao_publica" = "gestao_publica"
  ,"vigilancia_em_saude" = "saude"
  ,"inspecao_produtos_origem_animal" = "desenvolvimento_rural"
  ,"seguranca_publica" = "seguranca_cidadania"
)

to_macroareas <- function(x) {
  areas <- split_terms(x)
  macro <- unname(area_to_macro[areas])
  macro <- macro[!is.na(macro)]
  if (length(macro) == 0L) return(NA_character_)
  paste(sort(unique(macro)), collapse = "; ")
}

has_overlap <- function(x, y) {
  x <- split_terms(x)
  y <- split_terms(y)
  length(x) > 0L && length(y) > 0L && length(intersect(x, y)) > 0L
}

append_reason <- function(...) {
  reasons <- non_empty(c(...))
  if (length(reasons) == 0L) return(NA_character_)
  paste(unique(reasons), collapse = "; ")
}

message("Carregando cadastro, Base 1 e MIDES...")

cadastro_mg <- readRDS(path_cadastro) |>
  filter(uf == "MG") |>
  transmute(
    cnpj_consorcio = str_pad(as.character(cnpj), width = 14, side = "left", pad = "0"),
    sigla,
    razao_social,
    setores_cadastro_original = setores,
    tipo_cadastro_legado = tipo,
    tipo_fonte_legado = tipo_fonte,
    situacao,
    ano_fundacao
  )

base1 <- readRDS(path_base1)

munic_por_cnpj <- base1 |>
  filter(tem_munic) |>
  summarise(
    setores_munic_original = split_unique(setores_munic),
    anos_munic = paste(sort(unique(ano)), collapse = "; "),
    n_pares_ano_munic = n_distinct(paste(ano, cod_ibge_6)),
    .by = cnpj_consorcio
  )

mides_nomes <- readRDS(path_mides) |>
  transmute(
    cnpj_consorcio = str_pad(as.character(documento_credor), width = 14, side = "left", pad = "0"),
    nome_credor_freq
  ) |>
  filter(!is.na(cnpj_consorcio), cnpj_consorcio != "") |>
  summarise(
    nomes_mides = paste(sort(unique(non_empty(nome_credor_freq))), collapse = " | "),
    .by = cnpj_consorcio
  )

classificacao <- cadastro_mg |>
  left_join(munic_por_cnpj, by = "cnpj_consorcio") |>
  left_join(mides_nomes, by = "cnpj_consorcio") |>
  rowwise() |>
  mutate(
    areas_cadastro_ipea = map_source_areas(setores_cadastro_original),
    areas_tipo_arquivo = if_else(tipo_fonte_legado == "arquivo", map_source_areas(tipo_cadastro_legado), NA_character_),
    areas_munic = map_source_areas(setores_munic_original),
    areas_nome_razao_social = map_name_areas(paste(razao_social, nomes_mides)),
    areas_diretas = split_unique(areas_cadastro_ipea, areas_tipo_arquivo, areas_munic),
    macroareas_diretas = to_macroareas(areas_diretas),
    macroareas_nome = to_macroareas(areas_nome_razao_social),
    ha_evidencia_direta = !is.na(areas_diretas),
    areas_politica_detalhadas = if_else(ha_evidencia_direta, areas_diretas, areas_nome_razao_social),
    macroareas_politica = to_macroareas(areas_politica_detalhadas),
    qtd_areas_detalhadas = length(split_terms(areas_politica_detalhadas)),
    qtd_macroareas = length(split_terms(macroareas_politica)),
    multifinalitario_explicito = str_detect(to_ascii_upper(paste(sigla, razao_social, nomes_mides)), "MULTIFINALIT|MULTISSETORIAL"),
    perfil_institucional = case_when(
      multifinalitario_explicito ~ "multifinalitario_explicito",
      qtd_areas_detalhadas >= 2L ~ "multiarea_documentada",
      qtd_areas_detalhadas == 1L ~ "setorial",
      TRUE ~ "sem_classificacao"
    ),
    classe_analitica_proposta = case_when(
      multifinalitario_explicito ~ "multifinalitario",
      qtd_areas_detalhadas >= 2L ~ "multiarea",
      qtd_areas_detalhadas == 1L ~ areas_politica_detalhadas,
      TRUE ~ "sem_classificacao"
    ),
    fontes_evidencia_disponiveis = paste(
      c(
        if (!is.na(areas_cadastro_ipea)) "cadastro_ipea",
        if (!is.na(areas_tipo_arquivo)) "cadastro_ipea_tipo_arquivo",
        if (!is.na(areas_munic)) "munic",
        if (!is.na(areas_nome_razao_social)) "nome_razao_social"
      ),
      collapse = "; "
    ),
    origem_classificacao = case_when(
      ha_evidencia_direta ~ paste(
        c(
          if (!is.na(areas_cadastro_ipea)) "cadastro_ipea",
          if (!is.na(areas_tipo_arquivo)) "cadastro_ipea_tipo_arquivo",
          if (!is.na(areas_munic)) "munic"
        ),
        collapse = "; "
      ),
      !is.na(areas_nome_razao_social) ~ "nome_razao_social",
      TRUE ~ "sem_classificacao"
    ),
    regra_classificacao = case_when(
      ha_evidencia_direta ~ "consolidacao_de_evidencias_cadastro_e_munic_v0_1",
      !is.na(areas_nome_razao_social) ~ "fallback_regex_nome_v0_1",
      TRUE ~ "sem_regra"
    ),
    conflito_fontes_diretas = {
      sinais <- Filter(
        function(z) !is.na(z),
        list(
          to_macroareas(areas_cadastro_ipea),
          to_macroareas(areas_tipo_arquivo),
          to_macroareas(areas_munic)
        )
      )
      length(sinais) >= 2L && length(Reduce(intersect, lapply(sinais, split_terms))) == 0L
    },
    conflito_nome_com_direta = ha_evidencia_direta &&
      !is.na(macroareas_nome) &&
      !has_overlap(macroareas_diretas, macroareas_nome),
    necessita_revisao = conflito_fontes_diretas ||
      conflito_nome_com_direta ||
      is.na(areas_politica_detalhadas) ||
      (multifinalitario_explicito && is.na(areas_diretas)),
    motivo_revisao = append_reason(
      if (conflito_fontes_diretas) "conflito_entre_fontes_diretas",
      if (conflito_nome_com_direta) "nome_diverge_das_fontes_diretas",
      if (is.na(areas_politica_detalhadas)) "sem_area_identificada",
      if (multifinalitario_explicito && is.na(areas_diretas)) "multifinalitario_sem_area_documentada"
    ),
    confianca_classificacao = case_when(
      necessita_revisao ~ "revisar",
      ha_evidencia_direta && !is.na(areas_nome_razao_social) && has_overlap(macroareas_diretas, macroareas_nome) ~ "alta",
      ha_evidencia_direta ~ "media",
      !is.na(areas_nome_razao_social) ~ "baixa",
      TRUE ~ "sem_classificacao"
    )
  ) |>
  ungroup() |>
  mutate(
    fontes_evidencia_disponiveis = na_if(fontes_evidencia_disponiveis, "")
  ) |>
  select(
    cnpj_consorcio, sigla, razao_social, situacao, ano_fundacao,
    perfil_institucional, classe_analitica_proposta,
    areas_politica_detalhadas, macroareas_politica,
    qtd_areas_detalhadas, qtd_macroareas,
    origem_classificacao, fontes_evidencia_disponiveis, regra_classificacao, confianca_classificacao,
    necessita_revisao, motivo_revisao,
    setores_cadastro_original, tipo_cadastro_legado, tipo_fonte_legado,
    setores_munic_original, anos_munic, n_pares_ano_munic,
    nomes_mides,
    areas_cadastro_ipea, areas_tipo_arquivo, areas_munic,
    areas_nome_razao_social, areas_diretas, macroareas_diretas, macroareas_nome,
    multifinalitario_explicito, conflito_fontes_diretas, conflito_nome_com_direta
  ) |>
  arrange(desc(necessita_revisao), perfil_institucional, sigla, razao_social)

# A revisao documental e uma camada posterior e explicita. Ela nao substitui os
# campos automaticos: gera campos finais e conserva a trilha de decisao.
if (file.exists(path_revisao_documental)) {
  revisao_documental <- read_csv(
    path_revisao_documental,
    show_col_types = FALSE,
    col_types = cols(.default = col_character())
  ) |>
    mutate(cnpj_consorcio = str_pad(cnpj_consorcio, 14, side = "left", pad = "0"))

  if (anyDuplicated(revisao_documental$cnpj_consorcio) > 0L) {
    stop("CNPJ duplicado na revisao documental.")
  }
  if (!all(revisao_documental$cnpj_consorcio %in% classificacao$cnpj_consorcio)) {
    stop("A revisao documental contem CNPJ fora do cadastro MG.")
  }

  classificacao <- classificacao |>
    left_join(revisao_documental, by = "cnpj_consorcio") |>
    mutate(
      revisao_documental_status = coalesce(status_revisao_documental, "nao_revisado"),
      revisao_documental_decisao = coalesce(decisao_documental, ""),
      revisao_documental_justificativa = coalesce(justificativa_documental, ""),
      revisao_documental_fontes = coalesce(fontes_documentais, ""),
      areas_politica_final = if_else(
        !is.na(areas_validadas_documental) & areas_validadas_documental != "",
        areas_validadas_documental,
        areas_politica_detalhadas
      ),
      macroareas_final = vapply(areas_politica_final, to_macroareas, character(1)),
      perfil_institucional_final = if_else(
        !is.na(perfil_validado_documental) & perfil_validado_documental != "",
        perfil_validado_documental,
        perfil_institucional
      ),
      classe_analitica_final = if_else(
        !is.na(classe_validada_documental) & classe_validada_documental != "",
        classe_validada_documental,
        classe_analitica_proposta
      ),
      origem_classificacao_final = case_when(
        revisao_documental_status %in% c("confirmado", "ajustado") ~ "revisao_documental_v0_2",
        TRUE ~ origem_classificacao
      ),
      confianca_final = case_when(
        !is.na(confianca_documental) & confianca_documental != "" ~ confianca_documental,
        TRUE ~ confianca_classificacao
      ),
      necessita_revisao_final = case_when(
        revisao_documental_status %in% c("confirmado", "ajustado") ~ FALSE,
        TRUE ~ necessita_revisao
      )
    )
} else {
  classificacao <- classificacao |>
    mutate(
      revisao_documental_status = "arquivo_nao_encontrado",
      revisao_documental_decisao = "",
      revisao_documental_justificativa = "",
      revisao_documental_fontes = "",
      areas_politica_final = areas_politica_detalhadas,
      macroareas_final = macroareas_politica,
      perfil_institucional_final = perfil_institucional,
      classe_analitica_final = classe_analitica_proposta,
      origem_classificacao_final = origem_classificacao,
      confianca_final = confianca_classificacao,
      necessita_revisao_final = necessita_revisao
    )
}

if (nrow(classificacao) != 223L) stop("A classificacao deve conter 223 CNPJs MG.")
if (anyDuplicated(classificacao$cnpj_consorcio) > 0L) stop("CNPJ duplicado na classificacao.")
if (any(is.na(classificacao$perfil_institucional_final))) stop("Perfil institucional final ausente.")

resumo_classe <- classificacao |>
  count(perfil_institucional_final, classe_analitica_final, confianca_final, name = "n_cnpjs") |>
  arrange(desc(n_cnpjs), perfil_institucional_final, classe_analitica_final)

resumo_origem <- classificacao |>
  count(origem_classificacao, confianca_classificacao, name = "n_cnpjs") |>
  arrange(desc(n_cnpjs), origem_classificacao)

resumo_revisao <- classificacao |>
  count(revisao_documental_status, necessita_revisao_final, motivo_revisao, name = "n_cnpjs") |>
  arrange(desc(n_cnpjs), necessita_revisao_final)

revisao_manual <- classificacao |>
  filter(necessita_revisao_final) |>
  select(
    cnpj_consorcio, sigla, razao_social, perfil_institucional,
    classe_analitica_proposta, areas_politica_detalhadas, macroareas_politica,
    motivo_revisao, origem_classificacao, fontes_evidencia_disponiveis, regra_classificacao, confianca_classificacao,
    setores_cadastro_original, tipo_cadastro_legado, tipo_fonte_legado,
    setores_munic_original, anos_munic, nomes_mides,
    areas_cadastro_ipea, areas_tipo_arquivo, areas_munic, areas_nome_razao_social,
    areas_diretas, macroareas_diretas, macroareas_nome,
    revisao_documental_status, revisao_documental_decisao,
    revisao_documental_justificativa, revisao_documental_fontes,
    areas_politica_final, macroareas_final, perfil_institucional_final,
    classe_analitica_final, origem_classificacao_final, confianca_final
  )

out_csv <- file.path(out_dir, "classificacao_areas_politica_mg_v0_2.csv")
out_rds <- file.path(out_dir, "classificacao_areas_politica_mg_v0_2.rds")
out_xlsx <- file.path(out_dir, "revisao_classificacao_areas_politica_mg_v0_2.xlsx")
out_resumo <- file.path(out_dir, "resumo_classificacao_areas_politica_mg_v0_2.csv")

write_csv(classificacao, out_csv, na = "")
saveRDS(classificacao, out_rds)
write_csv(bind_rows(
  resumo_classe |> mutate(secao = "perfil_e_classe"),
  resumo_origem |> mutate(secao = "origem"),
  resumo_revisao |> mutate(secao = "revisao")
), out_resumo, na = "")
write_xlsx(
  list(
    revisao_manual = revisao_manual,
    classificacao_completa = classificacao,
    resumo_classe = resumo_classe,
    resumo_origem = resumo_origem,
    resumo_revisao = resumo_revisao
  ),
  out_xlsx
)

message("Classificacao concluida.")
message("  CNPJs MG: ", nrow(classificacao))
message("  Para revisao final: ", sum(classificacao$necessita_revisao_final))
message("  CSV: ", out_csv)
message("  RDS: ", out_rds)
message("  XLSX: ", out_xlsx)
