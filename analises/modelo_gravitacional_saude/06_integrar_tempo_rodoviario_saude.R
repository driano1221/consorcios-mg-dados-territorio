# =============================================================================
# Passo 5 cientifico: tempo rodoviario para a oferta assistencial fixa (MG)
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
})

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
model_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude")
out_dir <- file.path(model_dir, "outputs")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

source_path <- file.path(
  project_dir,
  "dados/bruto/externo/distbrasil/dist_brasil_zenodo_11400243.rds"
)
source_url <- paste0(
  "https://zenodo.org/api/records/11400243/files/",
  "dist_brasil.rds/content"
)
units_path <- file.path(out_dir, "capacidade_unidades_cnes_saude_mg.csv")
entities_path <- file.path(out_dir, "capacidade_entidades_saude_mg.rds")
map_path <- file.path(project_dir, "dashboards/base1_shiny/data/mg_municipios_sf_web.rds")

for (path in c(units_path, entities_path, map_path)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

if (!file.exists(source_path)) {
  dir.create(dirname(source_path), recursive = TRUE, showWarnings = FALSE)
  message("Baixando fonte rodoviaria do Zenodo 11400243...")
  utils::download.file(
    source_url,
    destfile = source_path,
    mode = "wb",
    method = "libcurl",
    quiet = FALSE
  )
}

expected_md5 <- "39f71b10ddf9fda7c53e2b39fa6bd202"
actual_md5 <- unname(tools::md5sum(source_path))
if (!identical(actual_md5, expected_md5)) {
  stop("Checksum inesperado para dist_brasil.rds: ", actual_md5)
}

collapse_values <- function(x) {
  values <- sort(unique(x[!is.na(x) & nzchar(x)]))
  if (length(values) == 0L) NA_character_ else paste(values, collapse = "; ")
}

dist_raw <- readRDS(source_path)
required_dist <- c("orig", "dest", "dist", "dur")
if (!all(required_dist %in% names(dist_raw))) {
  stop("Fonte rodoviaria sem as colunas esperadas: ", paste(required_dist, collapse = ", "))
}

dist_mg <- dist_raw |>
  filter(
    orig >= 3100000L, orig < 3200000L,
    dest >= 3100000L, dest < 3200000L
  ) |>
  transmute(
    id_a = sprintf("%07d", pmin(orig, dest)),
    id_b = sprintf("%07d", pmax(orig, dest)),
    distancia_rodoviaria_m = as.numeric(dist),
    tempo_rodoviario_min = as.numeric(dur)
  )
rm(dist_raw)
gc(verbose = FALSE)

if (nrow(dist_mg) != choose(853L, 2L)) {
  stop("A fonte nao possui todos os pares entre os 853 municipios de MG.")
}
if (anyDuplicated(dist_mg[c("id_a", "id_b")])) {
  stop("A fonte possui pares rodoviarios duplicados em MG.")
}
if (anyNA(dist_mg[c("distancia_rodoviaria_m", "tempo_rodoviario_min")])) {
  stop("A fonte possui rotas ausentes entre municipios de MG.")
}

codes_7 <- sort(unique(c(dist_mg$id_a, dist_mg$id_b)))
code_lookup <- data.frame(
  id_municipio = codes_7,
  cod_ibge_6 = substr(codes_7, 1L, 6L),
  stringsAsFactors = FALSE
)
if (nrow(code_lookup) != 853L || anyDuplicated(code_lookup$cod_ibge_6)) {
  stop("Falha ao construir o crosswalk IBGE de seis para sete digitos.")
}

map_mg <- readRDS(map_path)
municipalities <- sf::st_drop_geometry(map_mg) |>
  transmute(
    cod_ibge_6 = sprintf("%06d", as.integer(cod_ibge_6)),
    municipio = as.character(municipio_geo)
  ) |>
  distinct(cod_ibge_6, .keep_all = TRUE) |>
  left_join(code_lookup, by = "cod_ibge_6") |>
  select(id_municipio, cod_ibge_6, municipio) |>
  arrange(id_municipio)

if (nrow(municipalities) != 853L || anyNA(municipalities$id_municipio)) {
  stop("Mapa municipal nao corresponde integralmente aos 853 codigos da fonte rodoviaria.")
}

units <- read.csv(
  units_path,
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8",
  colClasses = c(
    cnpj_raiz_8 = "character",
    cnpj_canonico = "character",
    cnpj_consultado = "character",
    co_unidade = "character",
    cnes = "character",
    codigo_ibge_cnes = "character"
  )
)
entities <- readRDS(entities_path)

fixed_units <- units |>
  filter(unidade_fixa_elegivel) |>
  mutate(cod_ibge_6_destino = sprintf("%06d", as.integer(codigo_ibge_cnes))) |>
  left_join(
    municipalities |>
      transmute(
        id_municipio_destino = id_municipio,
        cod_ibge_6_destino = cod_ibge_6,
        municipio_destino = municipio
      ),
    by = "cod_ibge_6_destino"
  )

if (nrow(fixed_units) != 366L || anyNA(fixed_units$id_municipio_destino)) {
  stop("Unidades fixas nao foram integralmente ligadas aos municipios de destino.")
}
if (n_distinct(fixed_units$cnpj_raiz_8) != 46L) {
  stop("Quantidade inesperada de entidades com unidade fixa.")
}

destination_municipalities <- fixed_units |>
  distinct(id_municipio_destino, cod_ibge_6_destino, municipio_destino) |>
  arrange(id_municipio_destino)

route_grid <- merge(
  municipalities |>
    rename(
      id_municipio_origem = id_municipio,
      cod_ibge_6_origem = cod_ibge_6,
      municipio_origem = municipio
    ),
  destination_municipalities,
  by = NULL
) |>
  as_tibble() |>
  mutate(
    mesmo_municipio_destino = id_municipio_origem == id_municipio_destino,
    id_a = pmin(id_municipio_origem, id_municipio_destino),
    id_b = pmax(id_municipio_origem, id_municipio_destino)
  ) |>
  left_join(dist_mg, by = c("id_a", "id_b")) |>
  mutate(
    distancia_rodoviaria_m = if_else(
      mesmo_municipio_destino,
      0,
      distancia_rodoviaria_m
    ),
    tempo_rodoviario_min = if_else(
      mesmo_municipio_destino,
      0,
      tempo_rodoviario_min
    ),
    distancia_rodoviaria_km = distancia_rodoviaria_m / 1000,
    tempo_rodoviario_h = tempo_rodoviario_min / 60,
    fonte_tempo = "Saldanha/Zenodo 11400243; OSRM/OpenStreetMap, perfil car",
    referencia_origem_destino = "sede municipal IBGE 2010",
    data_publicacao_fonte = as.Date("2024-05-31"),
    fonte_assume_simetria = TRUE,
    considera_transito_por_horario = FALSE,
    horario_partida = NA_character_
  ) |>
  select(-id_a, -id_b) |>
  arrange(id_municipio_origem, id_municipio_destino)

if (anyNA(route_grid[c("distancia_rodoviaria_m", "tempo_rodoviario_min")])) {
  stop("Ha rotas ausentes na grade MG x municipios de oferta fixa.")
}

unit_routes <- route_grid |>
  inner_join(
    fixed_units |>
      select(
        cnpj_raiz_8, cnpj_canonico, cnpj_consultado,
        co_unidade, cnes, nome_estabelecimento_cnes,
        id_municipio_destino, cod_ibge_6_destino, municipio_destino,
        tipo_estabelecimento_cnes,
        leitos_existentes, leitos_sus,
        atendimento_ambulatorial_sus, internacao_sus, sadt_sus,
        n_vinculos_sus_ativos, n_cbo_sus_ativos_distintos,
        n_vinculos_medicos_sus_ativos, n_cbo_medicos_sus_ativos_distintos
      ),
    by = c(
      "id_municipio_destino",
      "cod_ibge_6_destino",
      "municipio_destino"
    ),
    relationship = "many-to-many"
  ) |>
  left_join(
    entities |>
      select(cnpj_raiz_8, razao_social_canonica, sigla_canonica),
    by = "cnpj_raiz_8"
  ) |>
  arrange(cnpj_raiz_8, id_municipio_origem, id_municipio_destino, cnes)

entity_destinations <- fixed_units |>
  group_by(
    cnpj_raiz_8,
    id_municipio_destino,
    cod_ibge_6_destino,
    municipio_destino
  ) |>
  summarise(
    n_unidades_fixas_destino = n(),
    cnes_destino = collapse_values(cnes),
    .groups = "drop"
  )

entity_route_details <- route_grid |>
  inner_join(
    entity_destinations,
    by = c(
      "id_municipio_destino",
      "cod_ibge_6_destino",
      "municipio_destino"
    ),
    relationship = "many-to-many"
  )

entity_route_summary <- entity_route_details |>
  arrange(
    cnpj_raiz_8,
    id_municipio_origem,
    tempo_rodoviario_min,
    id_municipio_destino
  ) |>
  group_by(
    id_municipio_origem,
    cod_ibge_6_origem,
    municipio_origem,
    cnpj_raiz_8
  ) |>
  summarise(
    n_municipios_oferta_fixa = n_distinct(id_municipio_destino),
    n_unidades_fixas = sum(n_unidades_fixas_destino),
    tempo_minimo_min = min(tempo_rodoviario_min),
    tempo_mediano_min = median(tempo_rodoviario_min),
    tempo_medio_min = mean(tempo_rodoviario_min),
    tempo_maximo_min = max(tempo_rodoviario_min),
    distancia_minima_km = min(distancia_rodoviaria_km),
    distancia_mediana_km = median(distancia_rodoviaria_km),
    distancia_maxima_km = max(distancia_rodoviaria_km),
    id_municipio_destino_mais_proximo = first(id_municipio_destino),
    cod_ibge_6_destino_mais_proximo = first(cod_ibge_6_destino),
    municipio_destino_mais_proximo = first(municipio_destino),
    cnes_destino_mais_proximo = first(cnes_destino),
    mesmo_municipio_de_alguma_oferta = any(mesmo_municipio_destino),
    .groups = "drop"
  )

entity_grid <- merge(
  municipalities |>
    rename(
      id_municipio_origem = id_municipio,
      cod_ibge_6_origem = cod_ibge_6,
      municipio_origem = municipio
    ),
  entities |>
    select(
      cnpj_raiz_8, cnpj_canonico, razao_social_canonica, sigla_canonica,
      aparece_mides_mg, incluir_modelo_principal_preliminar,
      incluir_sensibilidade_multiarea, capacidade_status
    ),
  by = NULL
) |>
  as_tibble() |>
  left_join(
    entity_route_summary,
    by = c(
      "id_municipio_origem",
      "cod_ibge_6_origem",
      "municipio_origem",
      "cnpj_raiz_8"
    )
  ) |>
  mutate(
    tempo_status = case_when(
      capacidade_status == "capacidade_direta_cnes_atual" & !is.na(tempo_minimo_min) ~
        "tempo_disponivel_unidades_fixas",
      capacidade_status == "sem_unidade_cnes_direta_nao_interpretar_como_zero" ~
        "sem_unidade_direta_destino_nao_definido",
      capacidade_status == "somente_unidades_moveis_sem_polo_fixo" ~
        "somente_unidades_moveis_sem_tempo_fixo",
      TRUE ~ "revisar"
    ),
    fonte_tempo = if_else(
      tempo_status == "tempo_disponivel_unidades_fixas",
      "Saldanha/Zenodo 11400243; OSRM/OpenStreetMap, perfil car",
      NA_character_
    ),
    referencia_origem_destino = if_else(
      tempo_status == "tempo_disponivel_unidades_fixas",
      "sede municipal IBGE 2010",
      NA_character_
    ),
    data_publicacao_fonte = if_else(
      tempo_status == "tempo_disponivel_unidades_fixas",
      as.Date("2024-05-31"),
      as.Date(NA)
    ),
    fonte_assume_simetria = if_else(
      tempo_status == "tempo_disponivel_unidades_fixas",
      TRUE,
      NA
    ),
    considera_transito_por_horario = if_else(
      tempo_status == "tempo_disponivel_unidades_fixas",
      FALSE,
      NA
    ),
    horario_partida = NA_character_
  ) |>
  arrange(cnpj_raiz_8, id_municipio_origem)

write.csv(
  route_grid,
  file.path(out_dir, "tempo_rodoviario_municipio_destino_saude_mg.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8",
  na = ""
)
saveRDS(
  route_grid,
  file.path(out_dir, "tempo_rodoviario_municipio_destino_saude_mg.rds"),
  compress = "xz"
)
write.csv(
  unit_routes,
  file.path(out_dir, "tempo_rodoviario_municipio_unidade_saude_mg.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8",
  na = ""
)
saveRDS(
  unit_routes,
  file.path(out_dir, "tempo_rodoviario_municipio_unidade_saude_mg.rds"),
  compress = "xz"
)
write.csv(
  entity_grid,
  file.path(out_dir, "tempo_rodoviario_municipio_entidade_saude_mg.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8",
  na = ""
)
saveRDS(
  entity_grid,
  file.path(out_dir, "tempo_rodoviario_municipio_entidade_saude_mg.rds"),
  compress = "xz"
)

message(
  "Passo 5 concluido: ",
  n_distinct(route_grid$id_municipio_origem), " origens; ",
  n_distinct(route_grid$id_municipio_destino), " municipios de destino; ",
  nrow(fixed_units), " unidades fixas; ",
  n_distinct(fixed_units$cnpj_raiz_8), " entidades com tempo disponivel."
)
