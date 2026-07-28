# =============================================================================
# 02_auditar_consolidacao_munic.R
# Auditoria da consolidacao de setores MUNIC por CNPJ de consorcio
#
# Objetivo: verificar se a uniao de todos os setores MUNIC observados para um
# CNPJ deve ser usada como classificacao substantiva. A rotina nao altera a
# classificacao final; ela produz uma camada de diagnostico e recomendacao.
# =============================================================================

library(dplyr)
library(readr)
library(stringr)
library(tidyr)
library(writexl)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
app_data_dir <- file.path(project_dir, "dashboards", "base1_shiny", "data")
class_dir <- file.path(project_dir, "analises", "classificacao_politicas")
out_dir <- file.path(class_dir, "outputs")

path_base1 <- file.path(app_data_dir, "base_1_vinculos_2015_2019.rds")
path_classificacao <- file.path(out_dir, "classificacao_areas_politica_mg_v0_2.rds")

for (path in c(path_base1, path_classificacao)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

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

to_ascii_upper <- function(x) {
  x <- ifelse(is.na(x), "", as.character(x))
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT")
  x <- toupper(x)
  x <- gsub("[^A-Z0-9]+", " ", x)
  trimws(gsub("\\s+", " ", x))
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
)

map_sector <- function(x) {
  mapped <- unname(area_dictionary[to_ascii_upper(x)])
  ifelse(is.na(mapped), NA_character_, mapped)
}

to_macroareas <- function(x) {
  areas <- split_terms(x)
  macro <- unname(area_to_macro[areas])
  macro <- macro[!is.na(macro)]
  if (length(macro) == 0L) return(NA_character_)
  paste(sort(unique(macro)), collapse = "; ")
}

set_equal <- function(x, y) {
  identical(sort(unique(split_terms(x))), sort(unique(split_terms(y))))
}

set_subset <- function(x, y) {
  x_terms <- split_terms(x)
  y_terms <- split_terms(y)
  length(x_terms) > 0L && all(x_terms %in% y_terms)
}

message("Carregando Base 1 e classificacao v0.2...")
base1 <- readRDS(path_base1)
classificacao <- readRDS(path_classificacao)

munic_linhas <- base1 |>
  filter(tem_munic) |>
  transmute(
    cnpj_consorcio,
    ano,
    cod_ibge_6,
    municipio,
    setor_munic_bruto = setores_munic
  ) |>
  separate_rows(setor_munic_bruto, sep = "\\s*[,;+|]\\s*") |>
  mutate(
    setor_munic_bruto = str_trim(setor_munic_bruto),
    area_munic = map_sector(setor_munic_bruto),
    macroarea_munic = unname(area_to_macro[area_munic])
  ) |>
  filter(!is.na(area_munic))

if (nrow(munic_linhas) == 0L) stop("Nenhum registro MUNIC mapeado.")

setores_detalhe <- munic_linhas |>
  summarise(
    anos = paste(sort(unique(ano)), collapse = "; "),
    n_pares_municipio_ano = n_distinct(paste(ano, cod_ibge_6)),
    n_municipios = n_distinct(cod_ibge_6),
    municipios_exemplo = paste(sort(unique(municipio))[seq_len(min(5L, n_distinct(municipio)))], collapse = "; "),
    .by = c(cnpj_consorcio, area_munic, macroarea_munic)
  )

totais_cnpj <- munic_linhas |>
  summarise(
    anos_munic_observados = paste(sort(unique(ano)), collapse = "; "),
    n_pares_municipio_ano_munic = n_distinct(paste(ano, cod_ibge_6)),
    n_municipios_munic = n_distinct(cod_ibge_6),
    .by = cnpj_consorcio
  )

setores_cnpj <- setores_detalhe |>
  left_join(totais_cnpj, by = "cnpj_consorcio") |>
  mutate(
    pct_pares_municipio_ano = round(100 * n_pares_municipio_ano / n_pares_municipio_ano_munic, 1),
    pct_municipios = round(100 * n_municipios / n_municipios_munic, 1)
  )

por_ano <- munic_linhas |>
  summarise(
    areas_no_ano = paste(sort(unique(area_munic)), collapse = "; "),
    macroareas_no_ano = paste(sort(unique(macroarea_munic)), collapse = "; "),
    n_pares_municipio_ano = n_distinct(paste(ano, cod_ibge_6)),
    .by = c(cnpj_consorcio, ano)
  ) |>
  pivot_wider(
    id_cols = cnpj_consorcio,
    names_from = ano,
    values_from = c(areas_no_ano, macroareas_no_ano, n_pares_municipio_ano),
    names_glue = "{.value}_{ano}"
  )

auditoria <- setores_cnpj |>
  summarise(
    areas_munic_auditadas = paste(sort(unique(area_munic)), collapse = "; "),
    macroareas_munic_auditadas = paste(sort(unique(macroarea_munic)), collapse = "; "),
    n_areas_munic = n_distinct(area_munic),
    n_macroareas_munic = n_distinct(macroarea_munic),
    setor_munic_dominante = area_munic[which.max(n_pares_municipio_ano)],
    pct_pares_setor_dominante = max(pct_pares_municipio_ano),
    setores_munic_por_suporte = paste(
      paste0(area_munic, " (", pct_pares_municipio_ano, "%)"),
      collapse = "; "
    ),
    .by = cnpj_consorcio
  ) |>
  left_join(totais_cnpj, by = "cnpj_consorcio") |>
  left_join(por_ano, by = "cnpj_consorcio") |>
  left_join(
    classificacao |>
      select(
        cnpj_consorcio, sigla, razao_social,
        areas_cadastro_ipea, areas_tipo_arquivo, areas_nome_razao_social,
        areas_politica_final, macroareas_final,
        perfil_institucional_final, confianca_final, revisao_documental_status
      ),
    by = "cnpj_consorcio"
  ) |>
  rowwise() |>
  mutate(
    comparacao_2015_2019 = case_when(
      is.na(areas_no_ano_2015) && is.na(areas_no_ano_2019) ~ "sem_observacao_2015_2019",
      is.na(areas_no_ano_2015) || is.na(areas_no_ano_2019) ~ "observado_em_um_ano",
      set_equal(areas_no_ano_2015, areas_no_ano_2019) ~ "setores_estaveis_entre_anos",
      TRUE ~ "setores_diferentes_entre_anos"
    ),
    apoio_cadastro_ipea = case_when(
      is.na(areas_cadastro_ipea) && is.na(areas_tipo_arquivo) ~ "sem_referencia_cadastro",
      set_subset(areas_munic_auditadas, split_unique(areas_cadastro_ipea, areas_tipo_arquivo)) ~ "cadastro_cobre_todas_as_areas_munic",
      length(intersect(split_terms(areas_munic_auditadas), split_terms(split_unique(areas_cadastro_ipea, areas_tipo_arquivo)))) > 0L ~ "cadastro_cobre_parte_das_areas_munic",
      TRUE ~ "cadastro_nao_confirma_areas_munic"
    ),
    regra_recomendada_munic = case_when(
      n_areas_munic == 1L ~ "usar_setor_MUNIC_como_evidencia_setorial",
      n_macroareas_munic == 1L ~ "usar_MUNIC_como_evidencia_multiarea_mesma_macroarea",
      apoio_cadastro_ipea == "cadastro_cobre_todas_as_areas_munic" ~ "usar_areas_MUNIC_com_apoio_do_cadastro",
      TRUE ~ "nao_unir_automaticamente_areas_MUNIC"
    ),
    prioridade_revisao_munic = case_when(
      regra_recomendada_munic == "nao_unir_automaticamente_areas_MUNIC" &&
        apoio_cadastro_ipea == "sem_referencia_cadastro" ~ "alta",
      regra_recomendada_munic == "nao_unir_automaticamente_areas_MUNIC" ~ "media",
      comparacao_2015_2019 == "setores_diferentes_entre_anos" ~ "media",
      TRUE ~ "baixa"
    ),
    motivo_auditoria_munic = case_when(
      regra_recomendada_munic == "nao_unir_automaticamente_areas_MUNIC" ~
        "MUNIC registra areas em mais de uma macroarea sem cobertura integral do cadastro",
      comparacao_2015_2019 == "setores_diferentes_entre_anos" ~
        "Setores MUNIC diferem entre 2015 e 2019",
      n_areas_munic > 1L ~
        "Multiplos setores MUNIC, mas concentrados em uma macroarea ou cobertos pelo cadastro",
      TRUE ~ "Setor MUNIC unico e estavel ou sem sinal de heterogeneidade"
    )
  ) |>
  ungroup() |>
  arrange(desc(prioridade_revisao_munic), desc(n_macroareas_munic), desc(n_areas_munic), sigla, razao_social)

resumo <- bind_rows(
  auditoria |>
    count(regra_recomendada_munic, prioridade_revisao_munic, name = "n_cnpjs") |>
    mutate(secao = "regra_recomendada"),
  auditoria |>
    count(comparacao_2015_2019, name = "n_cnpjs") |>
    mutate(secao = "comparacao_2015_2019", prioridade_revisao_munic = NA_character_),
  auditoria |>
    count(apoio_cadastro_ipea, name = "n_cnpjs") |>
    mutate(secao = "apoio_cadastro", prioridade_revisao_munic = NA_character_)
) |>
  select(secao, regra_recomendada_munic, prioridade_revisao_munic, comparacao_2015_2019, apoio_cadastro_ipea, n_cnpjs)

casos_revisao <- auditoria |>
  filter(regra_recomendada_munic == "nao_unir_automaticamente_areas_MUNIC")

out_auditoria <- file.path(out_dir, "auditoria_consolidacao_setores_munic_v0_1.csv")
out_detalhe <- file.path(out_dir, "auditoria_consolidacao_setores_munic_detalhe_v0_1.csv")
out_resumo <- file.path(out_dir, "resumo_auditoria_consolidacao_setores_munic_v0_1.csv")
out_xlsx <- file.path(out_dir, "auditoria_consolidacao_setores_munic_v0_1.xlsx")
out_md <- file.path(class_dir, "AUDITORIA_CONSOLIDACAO_MUNIC.md")

write_csv(auditoria, out_auditoria, na = "")
write_csv(setores_cnpj, out_detalhe, na = "")
write_csv(resumo, out_resumo, na = "")
write_xlsx(
  list(
    resumo = resumo,
    auditoria_cnpj = auditoria,
    casos_prioritarios = casos_revisao,
    detalhe_setor = setores_cnpj
  ),
  out_xlsx
)

md_lines <- c(
  "# Auditoria da Consolidacao de Setores MUNIC",
  "",
  "**Data:** 2026-07-22  ",
  "**Unidade:** CNPJ de consorcio no recorte MG do cadastro IPEA.  ",
  "**Fonte MUNIC:** Base 1, anos 2015 e 2019; cada observacao e um par municipio-consorcio com setor(es) declarado(s).",
  "",
  "## Objetivo",
  "",
  "Verificar se e metodologicamente adequado unir todos os setores MUNIC observados para um CNPJ. Esta auditoria nao altera a classificacao de areas; ela gera uma recomendacao rastreavel para uma proxima versao.",
  "",
  "## Regra recomendada",
  "",
  "1. **Setor unico:** usar MUNIC como evidencia setorial.",
  "2. **Multiplos setores na mesma macroarea:** usar MUNIC como evidencia multiarea, preservando os setores e a distribuicao de suporte.",
  "3. **Multiplas macroareas:** nao unir automaticamente, exceto quando o cadastro IPEA cobrir todas as areas MUNIC; revisar antes de transformar a uniao em classificacao final.",
  "",
  "## Resultados",
  "",
  paste0("- CNPJs com registro MUNIC: ", nrow(auditoria), "."),
  paste0("- Casos para nao unir automaticamente: ", nrow(casos_revisao), "."),
  paste0("- Casos de prioridade alta: ", sum(casos_revisao$prioridade_revisao_munic == "alta"), "."),
  "",
  "Os arquivos CSV e XLSX registram, por CNPJ, os setores, anos, municipios de exemplo, suporte de cada setor, comparacao 2015/2019, relacao com o cadastro IPEA e recomendacao.",
  "",
  "## Limite",
  "",
  "MUNIC informa o setor declarado no vinculo municipio-consorcio. A coexistencia de setores em um CNPJ pode refletir atividade real multissetorial ou heterogeneidade de declaracao; esta auditoria identifica essa distincao como questao de revisao, mas nao presume erro."
)
writeLines(md_lines, out_md, useBytes = TRUE)

stopifnot(nrow(auditoria) > 0L)
stopifnot(all(auditoria$cnpj_consorcio %in% classificacao$cnpj_consorcio))
stopifnot(!anyDuplicated(auditoria$cnpj_consorcio))
stopifnot(nrow(casos_revisao) == sum(auditoria$regra_recomendada_munic == "nao_unir_automaticamente_areas_MUNIC"))

message("Auditoria MUNIC concluida.")
message("  CNPJs com MUNIC: ", nrow(auditoria))
message("  Nao unir automaticamente: ", nrow(casos_revisao))
message("  Prioridade alta: ", sum(casos_revisao$prioridade_revisao_munic == "alta"))
