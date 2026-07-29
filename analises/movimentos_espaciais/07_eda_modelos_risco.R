# =============================================================================
# 07_eda_modelos_risco.R
# EDA reproduzivel dos universos completos de entrada e saida.
# =============================================================================

library(dplyr)
library(readr)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(project_dir, "analises", "movimentos_espaciais", "outputs")

entrada <- readRDS(file.path(out_dir, "risco_entrada_completo_municipio_consorcio_ano.rds"))
saida <- readRDS(file.path(out_dir, "risco_saida_municipio_consorcio_ano.rds"))
fora_risco <- read_csv(
  file.path(out_dir, "eventos_entrada_fora_universo_modelo.csv"),
  show_col_types = FALSE
) |>
  filter(regra_presenca == "principal_total_positivo")

resumo_anual <- full_join(
  entrada |>
    summarise(
      exposicoes_entrada = n(),
      entradas_novas = sum(entrada_nova_observada),
      retornos = sum(retorno_observado),
      entradas_total = sum(entrou_observado),
      entradas_adjacentes = sum(entrou_observado & candidato_externo_adjacente_t_1),
      entradas_sem_vizinho = sum(entrou_observado & !candidato_externo_adjacente_t_1),
      .by = ano
    ),
  saida |>
    summarise(
      exposicoes_saida = n(),
      saidas = sum(saiu_observado),
      saidas_isoladas = sum(saiu_observado & participante_isolado_t_1),
      .by = ano
    ),
  by = "ano"
) |>
  arrange(ano)

resumo_exclusoes <- fora_risco |>
  count(ano, motivo_exclusao, name = "eventos") |>
  arrange(ano, motivo_exclusao)

set.seed(20260728)
amostra <- bind_rows(
  entrada |>
    filter(entrada_nova_observada, candidato_externo_adjacente_t_1) |>
    slice_sample(n = 5L) |>
    mutate(grupo_amostra = "entrada_nova_com_vizinho"),
  entrada |>
    filter(entrada_nova_observada, !candidato_externo_adjacente_t_1) |>
    slice_sample(n = 5L) |>
    mutate(grupo_amostra = "entrada_nova_sem_vizinho"),
  entrada |>
    filter(retorno_observado) |>
    slice_sample(n = 5L) |>
    mutate(grupo_amostra = "retorno"),
  saida |>
    filter(saiu_observado, participante_isolado_t_1) |>
    slice_sample(n = 5L) |>
    mutate(grupo_amostra = "saida_isolada"),
  saida |>
    filter(saiu_observado, prop_vizinhos_no_consorcio_t_1 > .8) |>
    slice_sample(n = 5L) |>
    mutate(grupo_amostra = "saida_muito_integrada")
) |>
  select(
    grupo_amostra, ano, cod_ibge_6, municipio, cnpj_consorcio,
    razao_social_mides, membros_consorcio_t_1,
    n_vizinhos_total, n_vizinhos_no_consorcio_t_1,
    prop_vizinhos_no_consorcio_t_1
  )

write_csv(resumo_anual, file.path(out_dir, "modelos_eda_resumo_anual.csv"), na = "")
write_csv(resumo_exclusoes, file.path(out_dir, "modelos_eda_exclusoes.csv"), na = "")
write_csv(amostra, file.path(out_dir, "modelos_eda_amostra_eventos.csv"), na = "")

message("EDA dos modelos concluida")
