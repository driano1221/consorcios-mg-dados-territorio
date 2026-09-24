# Diagnostico do passo 6: cobertura das regras de alternativa e perdas MIDES.
suppressPackageStartupMessages(library(dplyr))
Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8")
out <- file.path(getwd(), "outputs")
p <- readRDS(file.path(out, "painel_anual_integrado_saude_mg_2014_2021.rds"))

diagnostico <- p |>
  group_by(ano) |>
  summarise(
    pagadores_todos = sum(presente_mides),
    valor_todos = sum(valor_total),
    pagadores_nucleo_cadastral = sum(presente_mides & alternativa_cadastral_saude),
    valor_nucleo_cadastral = sum(valor_total[alternativa_cadastral_saude]),
    alternativas_cadastrais = sum(alternativa_cadastral_saude),
    alternativas_clinicas_diretas = sum(alternativa_direta_com_tempo),
    pagadores_com_tempo_direto = sum(presente_mides & alternativa_direta_com_tempo),
    valor_com_tempo_direto = sum(valor_total[alternativa_direta_com_tempo]),
    alternativas_90min = sum(alternativa_90min_diagnostica),
    pagadores_90min = sum(presente_mides & alternativa_90min_diagnostica),
    alternativas_120min = sum(alternativa_direta_com_tempo & tempo_minimo_min <= 120,
      na.rm = TRUE),
    pagadores_120min = sum(presente_mides & alternativa_direta_com_tempo &
      tempo_minimo_min <= 120, na.rm = TRUE),
    alternativas_180min = sum(alternativa_direta_com_tempo & tempo_minimo_min <= 180,
      na.rm = TRUE),
    pagadores_180min = sum(presente_mides & alternativa_direta_com_tempo &
      tempo_minimo_min <= 180, na.rm = TRUE),
    alternativas_mesma_micro_2019 = sum(alternativa_mesma_micro_2019_diagnostica),
    pagadores_mesma_micro_2019 = sum(presente_mides &
      alternativa_mesma_micro_2019_diagnostica),
    pagadores_com_rcl = sum(presente_mides & !is.na(rcl_municipal)),
    entradas_observadas = sum(evento_movimento == "primeiro_pagamento_observado"),
    retornos_observados = sum(evento_movimento == "retorno_observado"),
    interrupcoes_observadas = sum(evento_movimento == "interrupcao_observada"),
    risco_entrada_principal = sum(risco_entrada_com_tempo_t_1),
    entradas_no_risco_principal = sum(risco_entrada_com_tempo_t_1 &
      evento_movimento == "primeiro_pagamento_observado"),
    risco_retorno_principal = sum(risco_retorno_com_tempo_t_1),
    retornos_no_risco_principal = sum(risco_retorno_com_tempo_t_1 &
      evento_movimento == "retorno_observado"),
    risco_interrupcao_principal = sum(risco_interrupcao_com_tempo_t_1),
    interrupcoes_no_risco_principal = sum(risco_interrupcao_com_tempo_t_1 &
      evento_movimento == "interrupcao_observada"),
    intensidade_principal = sum(universo_intensidade_principal),
    .groups = "drop") |>
  mutate(fracao_valor_com_tempo = valor_com_tempo_direto / valor_todos,
    fracao_pagadores_com_tempo = pagadores_com_tempo_direto / pagadores_todos,
    fracao_pagadores_90min = pagadores_90min / pagadores_todos)

write.csv(diagnostico, file.path(out, "diagnostico_alternativas_painel_saude_2014_2021.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
print(diagnostico, width = Inf)

municipios <- p |>
  group_by(ano, id_municipio) |>
  summarise(n_90min = sum(alternativa_90min_diagnostica),
    n_mesma_micro_2019 = sum(alternativa_mesma_micro_2019_diagnostica),
    .groups = "drop") |>
  group_by(ano) |>
  summarise(municipios_sem_opcao_90min = sum(n_90min == 0),
    municipios_sem_opcao_mesma_micro_2019 = if (first(ano) >= 2019L)
      sum(n_mesma_micro_2019 == 0) else NA_integer_, .groups = "drop")
write.csv(municipios, file.path(out, "diagnostico_municipios_sem_alternativa_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
print(municipios)
