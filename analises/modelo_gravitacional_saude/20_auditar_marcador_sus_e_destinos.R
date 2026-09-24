# Auditoria de dados: tempo ate clinicas com algum marcador SUS no CNES.
# Nao redefine o painel principal nem presume ausencia de atendimento.
suppressPackageStartupMessages(library(dplyr))
Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8")
out <- file.path(getwd(), "outputs")
p <- readRDS(file.path(out, "painel_anual_integrado_saude_mg_2014_2021.rds"))
read_units <- function(name) read.csv(file.path(out, name),
  colClasses = c(cnpj_raiz_8 = "character", codigo_ibge_6 = "character",
    cnes = "character"), fileEncoding = "UTF-8-BOM") |>
  transmute(cnpj_raiz_8, ano = as.integer(ano), cnes, codigo_ibge_6,
    funcao_assistencial,
    vinculo_sus = tolower(as.character(vinculo_sus)) == "true",
    leitos_sus = as.numeric(leitos_sus),
    servicos_sus = as.numeric(n_servicos_especializados_sus),
    profissionais_sus = as.numeric(n_profissionais_sus_distintos))
clinical <- bind_rows(
  read_units("elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv"),
  read_units("candidatas_cnes_capacidade_unidades_2014_2021.csv")) |>
  filter(funcao_assistencial == "destino_clinico_fixo") |>
  mutate(capacidade_sus_positiva = leitos_sus > 0 | servicos_sus > 0 |
      profissionais_sus > 0,
    marcador_sus = vinculo_sus | capacidade_sus_positiva)
stopifnot(nrow(clinical) == 469L,
  !anyNA(clinical$marcador_sus),
  !anyDuplicated(clinical[c("cnpj_raiz_8", "ano", "cnes")]))

unit_audit <- clinical |>
  group_by(ano, vinculo_sus, capacidade_sus_positiva) |>
  summarise(unidades_ano = n(), .groups = "drop")
write.csv(unit_audit, file.path(out, "eda_marcadores_sus_unidades.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
root_year <- clinical |>
  group_by(cnpj_raiz_8, ano) |>
  summarise(n_clinicas = n(), n_clinicas_marcador_sus = sum(marcador_sus),
    n_clinicas_capacidade_sus = sum(capacidade_sus_positiva),
    .groups = "drop")

municipios <- p |>
  distinct(id_municipio, cod_ibge_6)
marked_dest <- clinical |>
  filter(marcador_sus) |>
  distinct(cnpj_raiz_8, ano, codigo_ibge_6) |>
  left_join(municipios |>
    transmute(codigo_ibge_6 = cod_ibge_6, destino_id = id_municipio),
    by = "codigo_ibge_6", relationship = "many-to-one")
stopifnot(!anyNA(marked_dest$destino_id))
road <- readRDS(file.path(out, "rotas_mg_distbrasil_cache.rds")) |>
  select(a, b, tempo_min)
marked_time <- merge(municipios |> select(id_municipio), marked_dest,
  by = NULL) |>
  as_tibble() |>
  mutate(a = pmin(id_municipio, destino_id),
    b = pmax(id_municipio, destino_id)) |>
  left_join(road, by = c("a", "b"), relationship = "many-to-one") |>
  mutate(tempo_min = if_else(id_municipio == destino_id, 0, tempo_min)) |>
  group_by(id_municipio, cnpj_raiz_8, ano) |>
  summarise(tempo_ate_marcador_sus_min = min(tempo_min), .groups = "drop")
stopifnot(!anyNA(marked_time$tempo_ate_marcador_sus_min))

comparison <- p |>
  filter(alternativa_direta_com_tempo) |>
  select(ano, id_municipio, municipio, cnpj_raiz_8, sigla,
    presente_mides, valor_total, tempo_minimo_min) |>
  left_join(root_year, by = c("cnpj_raiz_8", "ano"),
    relationship = "many-to-one") |>
  left_join(marked_time, by = c("id_municipio", "cnpj_raiz_8", "ano"),
    relationship = "one-to-one") |>
  mutate(sem_marcador_sus = n_clinicas_marcador_sus == 0,
    sem_capacidade_sus_positiva = n_clinicas_capacidade_sus == 0,
    aumento_tempo_min = tempo_ate_marcador_sus_min - tempo_minimo_min)
stopifnot(nrow(comparison) == sum(p$alternativa_direta_com_tempo),
  all(comparison$sem_marcador_sus ==
    is.na(comparison$tempo_ate_marcador_sus_min)),
  all(comparison$aumento_tempo_min >= -1e-8, na.rm = TRUE))
cisvas_2019 <- comparison |>
  filter(ano == 2019L, cnpj_raiz_8 == "00794962", presente_mides)
igarape_2019 <- comparison |>
  filter(ano == 2019L, cnpj_raiz_8 == "05802877", municipio == "Igarapé")
stopifnot(nrow(cisvas_2019) == 10L, all(cisvas_2019$sem_marcador_sus),
  nrow(igarape_2019) == 1L,
  abs(igarape_2019$tempo_minimo_min - 15.1) < 1e-8,
  abs(igarape_2019$tempo_ate_marcador_sus_min - 15.1) < 1e-8)

annual <- comparison |>
  group_by(ano) |>
  summarise(n_entidades_sem_marcador = n_distinct(cnpj_raiz_8[
      sem_marcador_sus]),
    pagadores_sem_marcador = sum(presente_mides & sem_marcador_sus),
    valor_sem_marcador = sum(valor_total[sem_marcador_sus]),
    pagadores_sem_capacidade_sus = sum(presente_mides &
      sem_capacidade_sus_positiva),
    valor_sem_capacidade_sus = sum(valor_total[sem_capacidade_sus_positiva]),
    pagadores_com_tempo_maior = sum(presente_mides &
      aumento_tempo_min > 1e-8, na.rm = TRUE),
    valor_com_tempo_maior = sum(valor_total[aumento_tempo_min > 1e-8],
      na.rm = TRUE),
    maior_aumento_min = max(aumento_tempo_min, na.rm = TRUE),
    maior_aumento_pagadores_min = max(c(0,
      aumento_tempo_min[presente_mides & !is.na(aumento_tempo_min)])),
    .groups = "drop")
write.csv(annual, file.path(out, "eda_efeito_marcador_sus_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
write.csv(comparison |>
  filter(presente_mides, sem_marcador_sus | aumento_tempo_min > 1e-8) |>
  arrange(ano, desc(valor_total)),
  file.path(out, "eda_pares_afetados_marcador_sus_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
print(annual, width = Inf)
