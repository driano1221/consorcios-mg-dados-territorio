# =============================================================================
# 02_features_espaciais_fronteira.R
#
# Constroi vizinhanca municipal por fronteira compartilhada e calcula features
# espaciais dos pares MIDES. A geometria oficial e usada apenas no processamento;
# o dashboard permanece com a geometria leve de exibicao.
#
# Vizinhos por ponto de contato nao entram. Arestas exigem divisa compartilhada
# com comprimento positivo, em quilometros.
# =============================================================================

library(dplyr)
library(sf)
library(geobr)
library(readr)
library(stringr)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
in_dir <- file.path(project_dir, "analises", "movimentos_espaciais", "outputs")
out_dir <- in_dir
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

movimentos_path <- file.path(in_dir, "movimentos_municipio_consorcio_ano.rds")
if (!file.exists(movimentos_path)) {
  stop("Execute primeiro 01_materializar_movimentos_mides.R")
}

movimentos <- readRDS(movimentos_path) |>
  mutate(cod_ibge_6 = str_pad(as.character(cod_ibge_6), width = 6, side = "left", pad = "0"))

# A malha completa do geobr/IBGE preserva a topologia necessaria para a
# vizinhanca. A malha web do dashboard e simplificada e nao deve ser usada aqui.
vizinhos_path <- file.path(out_dir, "vizinhos_municipais_mg.rds")

if (file.exists(vizinhos_path)) {
  message("Reutilizando vizinhanca municipal ja validada...")
  vizinhos <- readRDS(vizinhos_path)
} else {
  geometria_cache <- file.path(out_dir, "31municipality_2020_oficial.gpkg")
  geometria_url <- "https://www.ipea.gov.br/geobr/data_gpkg/municipality/2020/31municipality_2020.gpkg"

  if (!file.exists(geometria_cache)) {
    message("Baixando malha municipal oficial do geobr (MG, 2020)...")
    download.file(geometria_url, geometria_cache, mode = "wb", quiet = FALSE)
  }

  message("Lendo malha municipal oficial do geobr (MG, 2020)...")
  municipios_sf <- st_read(geometria_cache, quiet = TRUE) |>
  transmute(
    cod_ibge_6 = str_sub(as.character(code_muni), 1, 6),
    municipio_geo = as.character(name_muni),
    geometry = geom
  ) |>
  st_make_valid() |>
  st_transform(5880)

  if (nrow(municipios_sf) != 853L) stop("A malha oficial deveria conter 853 municipios de MG.")
  if (!all(st_is_valid(municipios_sf))) stop("Ha geometrias invalidas apos st_make_valid().")

# DE-9IM F***1**** seleciona apenas pares cuja intersecao das fronteiras tem
# dimensao 1: uma linha compartilhada, excluindo municipios que so se tocam no
# canto. Trabalhar em CRS metrico permite registrar o comprimento da divisa.
  indice_vizinhos <- st_relate(municipios_sf, pattern = "F***1****", sparse = TRUE)
  arestas_indice <- tibble(
  i = rep(seq_along(indice_vizinhos), lengths(indice_vizinhos)),
  j = unlist(indice_vizinhos, use.names = FALSE)
) |>
  filter(i < j)

  if (nrow(arestas_indice) == 0L) stop("Nenhuma fronteira compartilhada foi identificada.")

  comprimento_divisa_km <- vapply(seq_len(nrow(arestas_indice)), function(linha) {
  i <- arestas_indice$i[[linha]]
  j <- arestas_indice$j[[linha]]
  fronteira <- suppressWarnings(st_intersection(
    st_boundary(st_geometry(municipios_sf)[i]),
    st_boundary(st_geometry(municipios_sf)[j])
  ))
  as.numeric(sum(st_length(fronteira))) / 1000
  }, numeric(1))

  vizinhos <- arestas_indice |>
  mutate(comprimento_divisa_km = comprimento_divisa_km) |>
  filter(comprimento_divisa_km > 0) |>
  transmute(
    municipio_a = municipios_sf$cod_ibge_6[i],
    nome_municipio_a = municipios_sf$municipio_geo[i],
    municipio_b = municipios_sf$cod_ibge_6[j],
    nome_municipio_b = municipios_sf$municipio_geo[j],
    comprimento_divisa_km
  ) |>
  arrange(municipio_a, municipio_b)
}

vizinhos_direcionados <- bind_rows(
  vizinhos |>
    transmute(cod_ibge_6 = municipio_a, vizinho_ibge_6 = municipio_b, comprimento_divisa_km),
  vizinhos |>
    transmute(cod_ibge_6 = municipio_b, vizinho_ibge_6 = municipio_a, comprimento_divisa_km)
)

grau_municipio <- vizinhos_direcionados |>
  summarise(
    n_vizinhos_total = n(),
    comprimento_total_divisas_km = sum(comprimento_divisa_km),
    .by = cod_ibge_6
  )

if (nrow(grau_municipio) != 853L || any(grau_municipio$n_vizinhos_total == 0L)) {
  stop("A vizinhanca oficial deixou municipios sem vizinhos; revisar a malha/geometria.")
}

# Features contemporaneas sao calculadas somente quando o municipio participa
# do par. Para testar eventos, as mesmas features sao depois defasadas em um ano.
ativos <- movimentos |>
  filter(presente_mides) |>
  select(ano, cod_ibge_6, cnpj_consorcio)

features_ativas <- ativos |>
  inner_join(vizinhos_direcionados, by = "cod_ibge_6", relationship = "many-to-many") |>
  left_join(
    ativos |>
      transmute(ano, cnpj_consorcio, vizinho_ibge_6 = cod_ibge_6, vizinho_no_consorcio = TRUE),
    by = c("ano", "cnpj_consorcio", "vizinho_ibge_6")
  ) |>
  mutate(vizinho_no_consorcio = coalesce(vizinho_no_consorcio, FALSE)) |>
  summarise(
    n_vizinhos_total = n(),
    n_vizinhos_no_consorcio = sum(vizinho_no_consorcio),
    n_vizinhos_fora_consorcio = sum(!vizinho_no_consorcio),
    prop_vizinhos_no_consorcio = n_vizinhos_no_consorcio / n_vizinhos_total,
    prop_vizinhos_fora_consorcio = n_vizinhos_fora_consorcio / n_vizinhos_total,
    comprimento_divisa_no_consorcio_km = sum(comprimento_divisa_km[vizinho_no_consorcio]),
    comprimento_divisa_fora_consorcio_km = sum(comprimento_divisa_km[!vizinho_no_consorcio]),
    municipio_borda = n_vizinhos_fora_consorcio > 0L,
    municipio_isolado = n_vizinhos_no_consorcio == 0L,
    .by = c(ano, cod_ibge_6, cnpj_consorcio)
  )

features_defasadas <- features_ativas |>
  transmute(
    ano = ano + 1L,
    cod_ibge_6,
    cnpj_consorcio,
    n_vizinhos_total_t_1 = n_vizinhos_total,
    n_vizinhos_no_consorcio_t_1 = n_vizinhos_no_consorcio,
    n_vizinhos_fora_consorcio_t_1 = n_vizinhos_fora_consorcio,
    prop_vizinhos_no_consorcio_t_1 = prop_vizinhos_no_consorcio,
    prop_vizinhos_fora_consorcio_t_1 = prop_vizinhos_fora_consorcio,
    municipio_borda_t_1 = municipio_borda,
    municipio_isolado_t_1 = municipio_isolado,
    tipo_exposicao_t_1 = "membro_no_consorcio"
  )

# Para entradas, o municipio ainda nao era membro em t-1. O risco relevante e
# estar fora do consorcio, mas fazer fronteira com um ou mais membros em t-1.
# Essa tabela forma o universo de candidatos de borda para analises futuras de
# entrada, sem supor que todo municipio de MG e candidato equivalente.
ativos_anterior <- ativos |>
  transmute(
    ano = ano + 1L,
    cnpj_consorcio,
    membro_ibge_6 = cod_ibge_6
  ) |>
  filter(ano %in% sort(unique(movimentos$ano)))

candidatos_entrada <- ativos_anterior |>
  inner_join(
    vizinhos_direcionados,
    by = c("membro_ibge_6" = "cod_ibge_6"),
    relationship = "many-to-many"
  ) |>
  left_join(
    ativos_anterior |>
      transmute(ano, cnpj_consorcio, vizinho_ibge_6 = membro_ibge_6, era_membro_t_1 = TRUE),
    by = c("ano", "cnpj_consorcio", "vizinho_ibge_6")
  ) |>
  filter(is.na(era_membro_t_1)) |>
  rename(cod_ibge_6 = vizinho_ibge_6) |>
  summarise(
    n_vizinhos_no_consorcio_t_1 = n(),
    comprimento_divisa_no_consorcio_t_1_km = sum(comprimento_divisa_km),
    .by = c(ano, cod_ibge_6, cnpj_consorcio)
  ) |>
  left_join(grau_municipio, by = "cod_ibge_6") |>
  mutate(
    n_vizinhos_fora_consorcio_t_1 = n_vizinhos_total - n_vizinhos_no_consorcio_t_1,
    prop_vizinhos_no_consorcio_t_1 = n_vizinhos_no_consorcio_t_1 / n_vizinhos_total,
    prop_vizinhos_fora_consorcio_t_1 = n_vizinhos_fora_consorcio_t_1 / n_vizinhos_total,
    municipio_borda_t_1 = n_vizinhos_fora_consorcio_t_1 > 0L,
    municipio_isolado_t_1 = FALSE,
    tipo_exposicao_t_1 = "candidato_vizinho_do_consorcio"
  ) |>
  left_join(
    movimentos |>
      select(ano, cod_ibge_6, cnpj_consorcio, presente_mides, evento_movimento) |>
      rename(presente_mides_t = presente_mides, evento_movimento_t = evento_movimento),
    by = c("ano", "cod_ibge_6", "cnpj_consorcio")
  ) |>
  mutate(
    entrou_observado = evento_movimento_t %in% c("entrada_observada", "retorno_observado")
  ) |>
  arrange(ano, cnpj_consorcio, cod_ibge_6)

exposicao_t_1 <- bind_rows(
  features_defasadas,
  candidatos_entrada |>
    select(
      ano, cod_ibge_6, cnpj_consorcio,
      n_vizinhos_total_t_1 = n_vizinhos_total,
      n_vizinhos_no_consorcio_t_1,
      n_vizinhos_fora_consorcio_t_1,
      prop_vizinhos_no_consorcio_t_1,
      prop_vizinhos_fora_consorcio_t_1,
      municipio_borda_t_1,
      municipio_isolado_t_1,
      tipo_exposicao_t_1
    )
  )

features_painel <- movimentos |>
  left_join(features_ativas, by = c("ano", "cod_ibge_6", "cnpj_consorcio")) |>
  left_join(exposicao_t_1, by = c("ano", "cod_ibge_6", "cnpj_consorcio")) |>
  mutate(
    fonte_geometria = "geobr municipio 2020 completo (IBGE)",
    regra_vizinhanca = "fronteira compartilhada por linha (DE-9IM F***1****)",
    features_defasadas_disponiveis = !is.na(prop_vizinhos_no_consorcio_t_1)
  ) |>
  arrange(cnpj_consorcio, cod_ibge_6, ano)

resumo_consorcio_ano <- features_painel |>
  filter(presente_mides) |>
  summarise(
    pares_ativos = n(),
    municipios_borda = sum(municipio_borda),
    municipios_isolados = sum(municipio_isolado),
    pct_municipios_borda = municipios_borda / pares_ativos,
    pct_municipios_isolados = municipios_isolados / pares_ativos,
    prop_media_vizinhos_no_consorcio = mean(prop_vizinhos_no_consorcio),
    prop_media_vizinhos_fora_consorcio = mean(prop_vizinhos_fora_consorcio),
    .by = c(ano, cnpj_consorcio, razao_social_mides)
  ) |>
  arrange(ano, cnpj_consorcio)

write_csv(vizinhos, file.path(out_dir, "vizinhos_municipais_mg.csv"), na = "")
write_csv(grau_municipio, file.path(out_dir, "grau_vizinhanca_municipal_mg.csv"), na = "")
write_csv(candidatos_entrada, file.path(out_dir, "risco_entrada_fronteira_municipio_consorcio_ano.csv"), na = "")
write_csv(features_painel, file.path(out_dir, "features_espaciais_municipio_consorcio_ano.csv"), na = "")
write_csv(resumo_consorcio_ano, file.path(out_dir, "features_espaciais_consorcio_ano.csv"), na = "")

saveRDS(vizinhos, file.path(out_dir, "vizinhos_municipais_mg.rds"))
saveRDS(grau_municipio, file.path(out_dir, "grau_vizinhanca_municipal_mg.rds"))
saveRDS(candidatos_entrada, file.path(out_dir, "risco_entrada_fronteira_municipio_consorcio_ano.rds"))
saveRDS(features_painel, file.path(out_dir, "features_espaciais_municipio_consorcio_ano.rds"))
saveRDS(resumo_consorcio_ano, file.path(out_dir, "features_espaciais_consorcio_ano.rds"))

message("\nFeatures espaciais materializadas")
message("  Municipios: ", nrow(grau_municipio))
message("  Fronteiras compartilhadas: ", nrow(vizinhos))
message("  Candidatos de entrada por borda: ", nrow(candidatos_entrada))
message("  Linhas de features: ", nrow(features_painel))
message("  Saida: ", out_dir)
