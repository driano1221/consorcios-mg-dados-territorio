# =============================================================================
# 05_preparar_dashboard_nacional.R
#
# Materializa artefatos leves da camada nacional para o dashboard. Movimentos
# sao calculados somente entre anos consecutivos com cobertura observada na UF
# pagadora; lacunas nao geram entradas ou saidas artificiais.
# =============================================================================

invisible(Sys.setlocale("LC_ALL", "Portuguese_Brazil.1252"))

library(dplyr)
library(sf)
library(stringr)
library(tidyr)

project_dir <- "."
source_dir <- file.path(project_dir, "analises", "base_nacional", "outputs")
app_data_dir <- file.path(project_dir, "dashboards", "base1_shiny", "data")
dir.create(app_data_dir, recursive = TRUE, showWarnings = FALSE)

required <- c(
  "painel_mides_nacional_raiz_ano.rds",
  "cadastro_consorcios_nacional_consolidado.rds",
  "mides_ipea_nacional_transacoes.rds",
  "mides_nacional_registros_sem_chave_municipal.rds"
)
missing <- required[!file.exists(file.path(source_dir, required))]
if (length(missing) > 0L) stop("Outputs nacionais ausentes: ", paste(missing, collapse = ", "))

collapse_values <- function(x) {
  x <- sort(unique(na.omit(as.character(x))))
  x <- x[nzchar(x)]
  if (length(x) == 0L) NA_character_ else paste(x, collapse = " | ")
}

painel <- readRDS(file.path(source_dir, "painel_mides_nacional_raiz_ano.rds"))
cadastro <- readRDS(file.path(source_dir, "cadastro_consorcios_nacional_consolidado.rds"))
raw <- readRDS(file.path(source_dir, "mides_ipea_nacional_transacoes.rds"))
sem_municipio_raw <- readRDS(file.path(source_dir, "mides_nacional_registros_sem_chave_municipal.rds"))

ufs_financeiras <- sort(unique(painel$uf_municipio_pagador))
anos_cobertura <- raw |>
  filter(!is.na(sigla_uf), !is.na(ano)) |>
  distinct(uf_municipio_pagador = sigla_uf, ano = as.integer(ano)) |>
  arrange(uf_municipio_pagador, ano) |>
  mutate(
    ano_anterior_coberto = (ano - 1L) %in% ano,
    .by = uf_municipio_pagador
  )

codigos_uf <- c(
  AC = "12", AL = "27", AM = "13", AP = "16", BA = "29", CE = "23",
  DF = "53", ES = "32", GO = "52", MA = "21", MG = "31", MS = "50",
  MT = "51", PA = "15", PB = "25", PE = "26", PI = "22", PR = "41",
  RJ = "33", RN = "24", RO = "11", RR = "14", RS = "43", SC = "42",
  SE = "28", SP = "35", TO = "17"
)

read_geobr_release <- function(filenames) {
  cache_dir <- file.path(tempdir(), "geobr_release_1_7_0")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  paths <- file.path(cache_dir, filenames)
  urls <- paste0(
    "https://github.com/ipeaGIT/geobr/releases/download/v1.7.0/",
    filenames
  )
  missing <- !file.exists(paths) | file.info(paths)$size == 0
  if (any(missing)) {
    downloaded <- curl::multi_download(
      urls[missing], paths[missing], progress = TRUE, resume = TRUE
    )
    if (any(!downloaded$success)) stop("Falha ao baixar malha geobr oficial.")
  }
  bind_rows(lapply(paths, sf::st_read, quiet = TRUE))
}

municipios_sf <- read_geobr_release(paste0(
  unname(codigos_uf[ufs_financeiras]), "municipality_2020_simplified.gpkg"
)) |>
  transmute(
    id_municipio = str_pad(as.character(code_muni), 7, pad = "0"),
    cod_ibge_6 = str_sub(id_municipio, 1, 6),
    municipio = name_muni,
    uf_municipio = abbrev_state
  ) |>
  st_make_valid()

# Simplificacao adicional em projecao nacional para reduzir o SVG interativo.
municipios_sf_web <- municipios_sf |>
  st_transform(5880) |>
  st_simplify(dTolerance = 1200, preserveTopology = TRUE) |>
  st_transform(4674)

estados_sf_web <- municipios_sf |>
  group_by(uf_municipio) |>
  summarise(nome_uf = first(uf_municipio), .groups = "drop") |>
  rename(uf = uf_municipio) |>
  st_make_valid() |>
  st_transform(5880) |>
  st_simplify(dTolerance = 2500, preserveTopology = TRUE) |>
  st_transform(4674)

brasil_contorno_sf_web <- read_geobr_release("country_2020_simplified.gpkg") |>
  st_make_valid() |>
  st_transform(5880) |>
  st_simplify(dTolerance = 4000, preserveTopology = TRUE) |>
  st_transform(4674)

lookup_municipios <- municipios_sf |>
  st_drop_geometry() |>
  distinct(id_municipio, cod_ibge_6, municipio, uf_municipio)

painel_app <- painel |>
  left_join(lookup_municipios, by = "id_municipio") |>
  mutate(
    ano = as.integer(ano),
    municipio = coalesce(municipio, paste0("IBGE ", id_municipio)),
    uf_municipio = coalesce(uf_municipio, uf_municipio_pagador),
    cnpj_canonico = str_pad(as.character(cnpj_canonico), 14, pad = "0"),
    cnpj_raiz_8 = str_pad(as.character(cnpj_raiz_8), 8, pad = "0"),
    sigla_canonica = if_else(
      is.na(sigla_canonica) | sigla_canonica == "", "(sem sigla)", sigla_canonica
    ),
    pesquisa = str_to_lower(paste(
      municipio, uf_municipio_pagador, sigla_canonica,
      razao_social_canonica, cnpj_canonico, cnpj_raiz_8,
      cnpjs_originais_observados
    ))
  )

cadastro_app <- cadastro |>
  mutate(
    cnpj_raiz_8 = str_pad(as.character(cnpj_raiz_8), 8, pad = "0"),
    cnpj_canonico = str_pad(as.character(cnpj_canonico), 14, pad = "0"),
    sigla_canonica = if_else(
      is.na(sigla_canonica) | sigla_canonica == "", "(sem sigla)", sigla_canonica
    ),
    encontrado_mides = cnpj_raiz_8 %in% painel_app$cnpj_raiz_8,
    pesquisa = str_to_lower(paste(
      sigla_canonica, razao_social_canonica, cnpj_canonico, cnpj_raiz_8,
      uf_sede_canonica, municipio_sede_canonico, cnpjs_estabelecimentos
    ))
  )

pares <- painel_app |>
  distinct(
    uf_municipio_pagador, id_municipio, cod_ibge_6, municipio,
    cnpj_raiz_8, cnpj_canonico, sigla_canonica,
    razao_social_canonica, uf_sede_canonica
  )

movimentos <- pares |>
  inner_join(anos_cobertura, by = "uf_municipio_pagador", relationship = "many-to-many") |>
  left_join(
    painel_app |>
      select(
        uf_municipio_pagador, id_municipio, cnpj_raiz_8, ano,
        valor_corrente, valor_restos, valor_indicador_restos_ausente,
        valor_total, n_transacoes
      ),
    by = c("uf_municipio_pagador", "id_municipio", "cnpj_raiz_8", "ano")
  ) |>
  mutate(
    across(
      c(valor_corrente, valor_restos, valor_indicador_restos_ausente, valor_total, n_transacoes),
      ~ coalesce(.x, 0)
    ),
    presente_mides = valor_total > 0
  ) |>
  arrange(uf_municipio_pagador, id_municipio, cnpj_raiz_8, ano) |>
  mutate(
    presente_anterior = lag(presente_mides),
    houve_presenca_antes = lag(cumany(presente_mides), default = FALSE),
    comparavel_ano_anterior = ano_anterior_coberto & !is.na(presente_anterior),
    evento_movimento = case_when(
      !comparavel_ano_anterior & presente_mides ~ "base_ou_reinicio_cobertura",
      !comparavel_ano_anterior ~ "sem_comparacao_temporal",
      presente_anterior & presente_mides ~ "permaneceu",
      presente_anterior & !presente_mides ~ "saida_observada",
      !presente_anterior & presente_mides & houve_presenca_antes ~ "retorno_observado",
      !presente_anterior & presente_mides ~ "entrada_observada",
      TRUE ~ "ausente"
    ),
    delta_presenca = case_when(
      !comparavel_ano_anterior ~ 0L,
      presente_mides & !presente_anterior ~ 1L,
      !presente_mides & presente_anterior ~ -1L,
      TRUE ~ 0L
    ),
    n_mudancas_periodo = sum(abs(delta_presenca), na.rm = TRUE),
    movimento_recorrente = n_mudancas_periodo >= 2L,
    .by = c(uf_municipio_pagador, id_municipio, cnpj_raiz_8)
  )

sem_municipio_app <- sem_municipio_raw |>
  summarise(
    razao_social_canonica = first(na.omit(nome_credor)),
    cnpjs_originais_observados = collapse_values(cnpj_original),
    valor_total = sum(valor_final, na.rm = TRUE),
    n_transacoes = n(),
    .by = c(sigla_uf, ano, cnpj_raiz_8, cnpj_canonico)
  ) |>
  rename(uf_municipio_pagador = sigla_uf) |>
  mutate(ano = as.integer(ano))

cobertura_app <- anos_cobertura |>
  summarise(
    anos = paste(ano, collapse = ";"),
    ano_min = min(ano),
    ano_max = max(ano),
    n_anos = n_distinct(ano),
    .by = uf_municipio_pagador
  ) |>
  left_join(
    painel_app |>
      summarise(
        municipios = n_distinct(id_municipio),
        consorcios = n_distinct(cnpj_raiz_8),
        linhas_anuais = n(),
        valor_municipal = sum(valor_total),
        .by = uf_municipio_pagador
      ),
    by = "uf_municipio_pagador"
  ) |>
  left_join(
    sem_municipio_app |>
      summarise(
        transacoes_sem_municipio = sum(n_transacoes),
        valor_sem_municipio = sum(valor_total),
        .by = uf_municipio_pagador
      ),
    by = "uf_municipio_pagador"
  ) |>
  mutate(
    transacoes_sem_municipio = coalesce(transacoes_sem_municipio, 0L),
    valor_sem_municipio = coalesce(valor_sem_municipio, 0)
  ) |>
  arrange(uf_municipio_pagador)

saveRDS(painel_app, file.path(app_data_dir, "mides_nacional_anual_app.rds"), compress = "xz")
saveRDS(cadastro_app, file.path(app_data_dir, "cadastro_nacional_consolidado_app.rds"), compress = "xz")
saveRDS(movimentos, file.path(app_data_dir, "mides_nacional_movimentos_app.rds"), compress = "xz")
saveRDS(municipios_sf_web, file.path(app_data_dir, "brasil_municipios_mides_sf_web.rds"), compress = "xz")
saveRDS(estados_sf_web, file.path(app_data_dir, "brasil_estados_contorno_sf_web.rds"), compress = "xz")
saveRDS(brasil_contorno_sf_web, file.path(app_data_dir, "brasil_contorno_sf_web.rds"), compress = "xz")
saveRDS(cobertura_app, file.path(app_data_dir, "mides_nacional_cobertura_app.rds"), compress = "xz")
saveRDS(sem_municipio_app, file.path(app_data_dir, "mides_nacional_sem_municipio_app.rds"), compress = "xz")

message("Artefatos nacionais do dashboard materializados.")
print(cobertura_app, n = Inf)
message("Cadastro consolidado: ", nrow(cadastro_app))
message("Consorcios com MIDES: ", n_distinct(painel_app$cnpj_raiz_8))
message("Painel anual: ", nrow(painel_app))
message("Movimentos balanceados por cobertura: ", nrow(movimentos))
message("Municipios cartografados nas oito UFs: ", nrow(municipios_sf_web))
