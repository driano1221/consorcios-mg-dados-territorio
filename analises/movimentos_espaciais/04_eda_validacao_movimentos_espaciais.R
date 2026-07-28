# =============================================================================
# 04_eda_validacao_movimentos_espaciais.R
# EDA reproduzivel das bases anuais e espaciais do MIDES completo.
# =============================================================================

library(dplyr)
library(readr)
library(stringr)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(project_dir, "analises", "movimentos_espaciais", "outputs")

movimentos <- readRDS(file.path(out_dir, "movimentos_municipio_consorcio_ano.rds"))
features <- readRDS(file.path(out_dir, "features_espaciais_municipio_consorcio_ano.rds"))
vizinhos <- readRDS(file.path(out_dir, "vizinhos_municipais_mg.rds"))
grau <- readRDS(file.path(out_dir, "grau_vizinhanca_municipal_mg.rds"))
candidatos <- readRDS(file.path(out_dir, "risco_entrada_fronteira_municipio_consorcio_ano.rds"))
raw <- readRDS(file.path(project_dir, "dados", "processado", "painel_mg_anual.rds"))

integridade <- tibble(
  metrica = c(
    "linhas_balanceadas", "pares_unicos", "municipios", "cnpjs", "anos",
    "duplicatas_chave", "valores_negativos", "registros_explicitos_zero",
    "linhas_presentes", "diferenca_valor_total_origem"
  ),
  valor = c(
    nrow(movimentos),
    nrow(distinct(movimentos, cod_ibge_6, cnpj_consorcio)),
    n_distinct(movimentos$cod_ibge_6),
    n_distinct(movimentos$cnpj_consorcio),
    n_distinct(movimentos$ano),
    nrow(movimentos) - nrow(distinct(movimentos, ano, cod_ibge_6, cnpj_consorcio)),
    sum(movimentos$valor_total < 0),
    sum(movimentos$tem_registro_mides & movimentos$valor_total == 0),
    sum(movimentos$presente_mides),
    sum(movimentos$valor_total) - sum(raw$valor_total)
  )
)

resumo_anual <- movimentos |>
  summarise(
    pares_ativos = sum(presente_mides),
    base_inicial = sum(evento_movimento == "base_inicial"),
    entradas_novas = sum(evento_movimento == "entrada_observada"),
    retornos = sum(evento_movimento == "retorno_observado"),
    saidas = sum(evento_movimento == "saida_observada"),
    permanencias = sum(evento_movimento == "permaneceu"),
    saldo_liquido = sum(delta_presenca),
    .by = ano
  ) |>
  arrange(ano)

resumo_transicoes <- movimentos |>
  distinct(cod_ibge_6, cnpj_consorcio, n_transicoes, movimento_recorrente) |>
  count(n_transicoes, movimento_recorrente, name = "pares")

alertas_valor <- tibble(
  metrica = c(
    "linhas_apenas_restos", "pares_apenas_restos_no_periodo",
    "entradas_ou_retornos_apenas_restos", "valores_positivos_abaixo_100",
    "valores_positivos_abaixo_1000", "registros_explicitos_zero"
  ),
  valor = c(
    sum(movimentos$presente_mides & movimentos$valor_corrente == 0 & movimentos$valor_restos > 0),
    movimentos |>
      summarise(corrente = sum(valor_corrente), total = sum(valor_total), .by = c(cod_ibge_6, cnpj_consorcio)) |>
      filter(total > 0, corrente == 0) |>
      nrow(),
    sum(
      movimentos$valor_corrente == 0 &
        movimentos$valor_restos > 0 &
        movimentos$evento_movimento %in% c("entrada_observada", "retorno_observado")
    ),
    sum(movimentos$valor_total > 0 & movimentos$valor_total < 100),
    sum(movimentos$valor_total > 0 & movimentos$valor_total < 1000),
    sum(movimentos$tem_registro_mides & movimentos$valor_total == 0)
  )
)

risco_saida <- features |>
  filter(ano > min(ano), tipo_exposicao_t_1 == "membro_no_consorcio") |>
  mutate(
    saiu = evento_movimento == "saida_observada",
    faixa_integracao = cut(
      prop_vizinhos_no_consorcio_t_1,
      breaks = c(-Inf, 0, .2, .4, .6, .8, Inf),
      labels = c("0%", "0-20%", "20-40%", "40-60%", "60-80%", ">80%")
    )
  )

saida_por_integracao <- risco_saida |>
  summarise(
    exposicoes = n(),
    saidas = sum(saiu),
    taxa_saida = mean(saiu),
    .by = faixa_integracao
  )

entrada_por_integracao <- candidatos |>
  mutate(
    faixa_integracao = cut(
      prop_vizinhos_no_consorcio_t_1,
      breaks = c(-Inf, .2, .4, .6, .8, Inf),
      labels = c("<=20%", "20-40%", "40-60%", "60-80%", ">80%")
    )
  ) |>
  summarise(
    candidatos = n(),
    entradas = sum(entrou_observado),
    taxa_entrada = mean(entrou_observado),
    .by = faixa_integracao
  )

movimentos_raiz <- movimentos |>
  mutate(raiz_cnpj = str_sub(cnpj_consorcio, 1, 8))

raizes_multiplas <- movimentos_raiz |>
  distinct(raiz_cnpj, cnpj_consorcio) |>
  count(raiz_cnpj, name = "n_cnpjs") |>
  filter(n_cnpjs > 1)

presenca_raiz <- movimentos_raiz |>
  filter(raiz_cnpj %in% raizes_multiplas$raiz_cnpj) |>
  summarise(
    presente_raiz = any(presente_mides),
    .by = c(ano, cod_ibge_6, raiz_cnpj)
  ) |>
  arrange(cod_ibge_6, raiz_cnpj, ano) |>
  group_by(cod_ibge_6, raiz_cnpj) |>
  mutate(
    presente_raiz_anterior = lag(presente_raiz, default = FALSE),
    evento_raiz = case_when(
      ano == min(ano) & presente_raiz ~ "base_inicial",
      presente_raiz & presente_raiz_anterior ~ "permaneceu",
      presente_raiz & !presente_raiz_anterior ~ "entrou",
      !presente_raiz & presente_raiz_anterior ~ "saiu",
      TRUE ~ "ausente"
    )
  ) |>
  ungroup()

impacto_matriz_filial <- movimentos_raiz |>
  filter(
    raiz_cnpj %in% raizes_multiplas$raiz_cnpj,
    evento_movimento %in% c("entrada_observada", "retorno_observado", "saida_observada")
  ) |>
  left_join(
    presenca_raiz |>
      select(ano, cod_ibge_6, raiz_cnpj, evento_raiz),
    by = c("ano", "cod_ibge_6", "raiz_cnpj")
  ) |>
  mutate(transicao_interna_raiz = evento_raiz == "permaneceu") |>
  summarise(
    eventos_cnpj = n(),
    transicoes_internas_raiz = sum(transicao_interna_raiz),
    percentual_interno = mean(transicao_interna_raiz),
    .by = evento_movimento
  )

set.seed(20260728)
sequencias <- movimentos |>
  summarise(
    padrao_presenca = paste0(as.integer(presente_mides), collapse = ""),
    anos_ativos = paste(ano[presente_mides], collapse = ", "),
    .by = c(cod_ibge_6, cnpj_consorcio)
  )

valor_anterior <- movimentos |>
  transmute(
    ano = ano + 1L,
    cod_ibge_6,
    cnpj_consorcio,
    valor_anterior = valor_total
  )

amostra_eventos <- features |>
  left_join(valor_anterior, by = c("ano", "cod_ibge_6", "cnpj_consorcio")) |>
  left_join(sequencias, by = c("cod_ibge_6", "cnpj_consorcio")) |>
  filter(evento_movimento %in% c("entrada_observada", "retorno_observado", "saida_observada")) |>
  group_by(evento_movimento) |>
  mutate(ordem_aleatoria = runif(n())) |>
  arrange(ordem_aleatoria, .by_group = TRUE) |>
  slice_head(n = 5) |>
  ungroup() |>
  select(
    evento_movimento, ano, municipio, cnpj_consorcio, razao_social_mides,
    valor_anterior, valor_total, padrao_presenca,
    prop_vizinhos_no_consorcio_t_1, municipio_borda_t_1, municipio_isolado_t_1
  )

amostra_recorrentes <- movimentos |>
  summarise(
    municipio = first(municipio),
    razao_social_mides = first(razao_social_mides),
    n_transicoes = first(n_transicoes),
    padrao_presenca = paste0(as.integer(presente_mides), collapse = ""),
    anos_ativos = paste(ano[presente_mides], collapse = ", "),
    eventos = paste(
      paste0(
        ano[evento_movimento %in% c("entrada_observada", "retorno_observado", "saida_observada")],
        ":",
        evento_movimento[evento_movimento %in% c("entrada_observada", "retorno_observado", "saida_observada")]
      ),
      collapse = " | "
    ),
    .by = c(cod_ibge_6, cnpj_consorcio)
  ) |>
  filter(n_transicoes >= 2) |>
  mutate(ordem_aleatoria = runif(n())) |>
  arrange(ordem_aleatoria) |>
  slice_head(n = 10) |>
  select(-ordem_aleatoria)

write_csv(integridade, file.path(out_dir, "eda_integridade.csv"))
write_csv(resumo_anual, file.path(out_dir, "eda_resumo_anual.csv"))
write_csv(resumo_transicoes, file.path(out_dir, "eda_resumo_transicoes.csv"))
write_csv(alertas_valor, file.path(out_dir, "eda_alertas_valor.csv"))
write_csv(saida_por_integracao, file.path(out_dir, "eda_saida_por_integracao.csv"))
write_csv(entrada_por_integracao, file.path(out_dir, "eda_entrada_por_integracao.csv"))
write_csv(impacto_matriz_filial, file.path(out_dir, "eda_impacto_matriz_filial.csv"))
write_csv(amostra_eventos, file.path(out_dir, "eda_amostra_eventos.csv"))
write_csv(amostra_recorrentes, file.path(out_dir, "eda_amostra_recorrentes.csv"))

message("EDA concluida. Saidas em: ", out_dir)
