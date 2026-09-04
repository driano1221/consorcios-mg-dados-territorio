# =============================================================================
# Validacao estrutural do passo 5: tempo rodoviario da oferta fixa (MG)
# =============================================================================

suppressPackageStartupMessages(library(dplyr))

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
out_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude/outputs")

dest_path <- file.path(out_dir, "tempo_rodoviario_municipio_destino_saude_mg.rds")
unit_path <- file.path(out_dir, "tempo_rodoviario_municipio_unidade_saude_mg.rds")
entity_path <- file.path(out_dir, "tempo_rodoviario_municipio_entidade_saude_mg.rds")

for (path in c(dest_path, unit_path, entity_path)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

dest <- readRDS(dest_path)
units <- readRDS(unit_path)
entities <- readRDS(entity_path)

stopifnot(nrow(dest) == 853L * 238L)
stopifnot(n_distinct(dest$id_municipio_origem) == 853L)
stopifnot(n_distinct(dest$id_municipio_destino) == 238L)
stopifnot(!anyDuplicated(dest[c("id_municipio_origem", "id_municipio_destino")]))
stopifnot(!anyNA(dest[c("distancia_rodoviaria_m", "tempo_rodoviario_min")]))
stopifnot(sum(dest$mesmo_municipio_destino) == 238L)
stopifnot(all(dest$tempo_rodoviario_min[dest$mesmo_municipio_destino] == 0))
stopifnot(all(dest$distancia_rodoviaria_m[dest$mesmo_municipio_destino] == 0))
stopifnot(all(dest$tempo_rodoviario_min[!dest$mesmo_municipio_destino] > 0))
stopifnot(all(dest$distancia_rodoviaria_m[!dest$mesmo_municipio_destino] > 0))
stopifnot(all(dest$fonte_assume_simetria))
stopifnot(!any(dest$considera_transito_por_horario))

mirrors <- dest |>
  filter(id_municipio_origem %in% unique(id_municipio_destino)) |>
  select(
    id_municipio_origem,
    id_municipio_destino,
    distancia_ida = distancia_rodoviaria_m,
    tempo_ida = tempo_rodoviario_min
  ) |>
  inner_join(
    dest |>
      select(
        id_municipio_origem,
        id_municipio_destino,
        distancia_volta = distancia_rodoviaria_m,
        tempo_volta = tempo_rodoviario_min
      ),
    by = c(
      "id_municipio_origem" = "id_municipio_destino",
      "id_municipio_destino" = "id_municipio_origem"
    )
  )
stopifnot(nrow(mirrors) == 238L * 238L)
stopifnot(all(mirrors$distancia_ida == mirrors$distancia_volta))
stopifnot(all(mirrors$tempo_ida == mirrors$tempo_volta))

stopifnot(nrow(units) == 853L * 389L)
stopifnot(n_distinct(units$cnes) == 389L)
stopifnot(n_distinct(units$cnpj_raiz_8) == 61L)
stopifnot(!anyDuplicated(units[c("id_municipio_origem", "cnpj_raiz_8", "cnes")]))
stopifnot(!anyNA(units[c("distancia_rodoviaria_m", "tempo_rodoviario_min")]))

stopifnot(nrow(entities) == 853L * 84L)
stopifnot(!anyDuplicated(entities[c("id_municipio_origem", "cnpj_raiz_8")]))
available <- entities$tempo_status == "tempo_disponivel_unidades_fixas"
without_direct <- entities$tempo_status == "sem_unidade_direta_destino_nao_definido"
mobile_only <- entities$tempo_status == "somente_unidades_moveis_sem_tempo_fixo"
stopifnot(sum(available) == 853L * 61L)
stopifnot(sum(without_direct) == 853L * 21L)
stopifnot(sum(mobile_only) == 853L * 2L)
stopifnot(!anyNA(entities$tempo_minimo_min[available]))
stopifnot(all(is.na(entities$tempo_minimo_min[without_direct | mobile_only])))
stopifnot(all(entities$tempo_minimo_min[available] <= entities$tempo_mediano_min[available]))
stopifnot(all(entities$tempo_mediano_min[available] <= entities$tempo_maximo_min[available]))
stopifnot(all(entities$distancia_minima_km[available] <= entities$distancia_mediana_km[available]))
stopifnot(all(entities$distancia_mediana_km[available] <= entities$distancia_maxima_km[available]))

cat(
  "OK: tempo rodoviario validado para 853 municipios, 389 unidades fixas e 84 entidades.\n"
)
