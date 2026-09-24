# EDA inicial do passo 7: selecao, zeros e extremos antes da estimacao.
suppressPackageStartupMessages(library(dplyr))
Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8")
out <- file.path(getwd(), "outputs")
p <- readRDS(file.path(out, "painel_anual_integrado_saude_mg_2014_2021.rds"))

safe_quantile <- function(x, prob) if (length(x)) unname(quantile(x, prob,
  na.rm = TRUE)) else NA_real_

annual <- p |>
  group_by(ano) |>
  summarise(
    alternativas_diretas = sum(alternativa_direta_com_tempo),
    alternativas_diretas_sem_pagamento = sum(alternativa_direta_com_tempo &
      !presente_mides),
    pagadores_total = sum(presente_mides),
    pagadores_principal = sum(universo_intensidade_principal),
    pagadores_excluidos_sem_polo = sum(presente_mides &
      alternativa_cadastral_saude & !alternativa_direta_com_tempo),
    pagadores_excluidos_escopo = sum(presente_mides &
      !alternativa_cadastral_saude),
    zeros_no_universo_direto = sum(alternativa_direta_com_tempo &
      !presente_mides),
    primeiros_pagamentos_no_risco = sum(risco_entrada_com_tempo_t_1 &
      evento_movimento == "primeiro_pagamento_observado"),
    retornos_no_risco = sum(risco_retorno_com_tempo_t_1 &
      evento_movimento == "retorno_observado"),
    interrupcoes_no_risco = sum(risco_interrupcao_com_tempo_t_1 &
      evento_movimento == "interrupcao_observada"),
    permanencias_no_principal = sum(universo_intensidade_principal &
      evento_movimento == "permanencia"),
    valor_principal = sum(valor_total[universo_intensidade_principal]),
    valor_total = sum(valor_total),
    rcl_no_principal = sum(universo_intensidade_principal &
      !is.na(rcl_municipal)),
    tempo_p50_principal = safe_quantile(tempo_minimo_min[
      universo_intensidade_principal], .5),
    tempo_p95_principal = safe_quantile(tempo_minimo_min[
      universo_intensidade_principal], .95),
    tempo_max_principal = max(tempo_minimo_min[
      universo_intensidade_principal]),
    entidades_principal = n_distinct(cnpj_raiz_8[
      universo_intensidade_principal]),
    .groups = "drop") |>
  mutate(fracao_pagadores_principal = pagadores_principal / pagadores_total,
    fracao_valor_principal = valor_principal / valor_total)

stopifnot(all(annual$alternativas_diretas ==
  annual$alternativas_diretas_sem_pagamento + annual$pagadores_principal),
  all(annual$pagadores_total == annual$pagadores_principal +
    annual$pagadores_excluidos_sem_polo + annual$pagadores_excluidos_escopo),
  all(annual$tempo_p95_principal <= annual$tempo_max_principal))

write.csv(annual, file.path(out, "eda_inicial_painel_saude_2014_2021.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")

payers <- p |>
  filter(presente_mides) |>
  mutate(grupo = case_when(
    universo_intensidade_principal ~ "polo_direto_e_tempo",
    alternativa_cadastral_saude ~ "saude_sem_polo_direto",
    TRUE ~ "fora_escopo_restrito"))
selection <- payers |>
  group_by(ano, grupo) |>
  summarise(n_pares = n(), n_municipios = n_distinct(id_municipio),
    n_entidades = n_distinct(cnpj_raiz_8), valor = sum(valor_total),
    pagamento_mediano = median(valor_total),
    populacao_mediana = median(populacao_ibge),
    pares_com_rcl = sum(!is.na(rcl_municipal)), .groups = "drop")
write.csv(selection, file.path(out, "eda_selecao_pagadores_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
selection_by_entity <- payers |>
  group_by(ano, grupo, cnpj_raiz_8, sigla) |>
  summarise(n_municipios = n(), valor = sum(valor_total),
    n_transacoes = sum(n_transacoes),
    classificacao_documental = first(classificacao_assistencial_documental),
    decisao_destino_fixo = first(decisao_destino_fixo_anual),
    decisao_prioritaria = first(decisao_sete_prioritarias),
    .groups = "drop") |>
  arrange(ano, grupo, desc(valor))
write.csv(selection_by_entity, file.path(out, "eda_selecao_entidades_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
rcl_selection <- payers |>
  filter(grupo == "polo_direto_e_tempo") |>
  mutate(rcl_disponivel = !is.na(rcl_municipal)) |>
  group_by(ano, rcl_disponivel) |>
  summarise(n_pares = n(), n_municipios = n_distinct(id_municipio),
    valor = sum(valor_total), pagamento_mediano = median(valor_total),
    populacao_mediana = median(populacao_ibge), .groups = "drop")
write.csv(rcl_selection, file.path(out, "eda_selecao_rcl_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")

capacity_coverage <- p |>
  filter(alternativa_direta_com_tempo) |>
  distinct(ano, cnpj_raiz_8, n_destinos_clinicos_dezembro,
    leitos_sus_clinicos, servicos_sus_clinicos_soma_unidades,
    profissionais_sus_clinicos_soma_unidades) |>
  group_by(ano) |>
  summarise(n_entidades = n(), sem_leitos_sus = sum(leitos_sus_clinicos == 0),
    sem_servicos_sus = sum(servicos_sus_clinicos_soma_unidades == 0),
    sem_profissionais_sus = sum(profissionais_sus_clinicos_soma_unidades == 0),
    mediana_unidades = median(n_destinos_clinicos_dezembro),
    mediana_servicos = median(servicos_sus_clinicos_soma_unidades),
    mediana_profissionais = median(profissionais_sus_clinicos_soma_unidades),
    .groups = "drop")
write.csv(capacity_coverage, file.path(out, "eda_cobertura_capacidade_cnes_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")

# Regras territoriais: quantos pares, valores e municipios cada uma retem?
rules <- list(
  direto_sem_corte = p$alternativa_direta_com_tempo,
  ate_90_min = p$alternativa_direta_com_tempo & p$tempo_minimo_min <= 90,
  ate_120_min = p$alternativa_direta_com_tempo & p$tempo_minimo_min <= 120,
  ate_180_min = p$alternativa_direta_com_tempo & p$tempo_minimo_min <= 180,
  mesma_micro_2019 = p$alternativa_mesma_micro_2019_diagnostica)
sensitivity <- bind_rows(lapply(names(rules), function(rule) {
  p |>
    mutate(elegivel = coalesce(rules[[rule]], FALSE)) |>
    filter(rule != "mesma_micro_2019" | ano >= 2019L) |>
    group_by(ano, id_municipio) |>
    summarise(n_alternativas_municipio = sum(elegivel),
      n_pagadores_municipio = sum(elegivel & presente_mides),
      valor_municipio = sum(valor_total[elegivel]), .groups = "drop") |>
    group_by(ano) |>
    summarise(regra = rule,
      municipios_sem_alternativa = sum(n_alternativas_municipio == 0),
      alternativas = sum(n_alternativas_municipio),
      pagadores = sum(n_pagadores_municipio), valor = sum(valor_municipio),
      .groups = "drop")
})) |>
  left_join(annual |> select(ano, pagadores_principal, valor_principal),
    by = "ano", relationship = "many-to-one") |>
  mutate(fracao_pares_do_direto = pagadores / pagadores_principal,
    fracao_valor_do_direto = valor / valor_principal)
stopifnot(all(sensitivity$fracao_pares_do_direto <= 1 + 1e-8),
  all(sensitivity$fracao_valor_do_direto <= 1 + 1e-8))
prior <- read.csv(file.path(out, "diagnostico_municipios_sem_alternativa_saude.csv"))
check90 <- sensitivity |>
  filter(regra == "ate_90_min") |>
  left_join(prior, by = "ano", relationship = "one-to-one")
checkmicro <- sensitivity |>
  filter(regra == "mesma_micro_2019") |>
  left_join(prior, by = "ano", relationship = "one-to-one")
stopifnot(all(check90$municipios_sem_alternativa ==
    check90$municipios_sem_opcao_90min),
  all(checkmicro$municipios_sem_alternativa ==
    checkmicro$municipios_sem_opcao_mesma_micro_2019))
write.csv(sensitivity, file.path(out, "eda_sensibilidade_alternativas_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")

outliers <- p |>
  filter(universo_intensidade_principal, tempo_minimo_min > 300) |>
  select(ano, id_municipio, municipio, cnpj_raiz_8, sigla,
    origem_universo, grupo_escopo, valor_total, n_transacoes,
    n_destinos_clinicos_dezembro, tempo_minimo_min,
    destino_clinico_mais_proximo_id) |>
  arrange(desc(tempo_minimo_min), ano)
names_municipios <- p |>
  distinct(id_municipio, municipio) |>
  rename(destino_clinico_mais_proximo_id = id_municipio,
    municipio_destino = municipio)
outliers <- outliers |>
  left_join(names_municipios, by = "destino_clinico_mais_proximo_id",
    relationship = "many-to-one") |>
  mutate(a = pmin(id_municipio, destino_clinico_mais_proximo_id),
    b = pmax(id_municipio, destino_clinico_mais_proximo_id)) |>
  left_join(readRDS(file.path(out, "rotas_mg_distbrasil_cache.rds")) |>
    select(a, b, tempo_min, distancia_km), by = c("a", "b"),
    relationship = "many-to-one")
stopifnot(nrow(outliers) > 0L,
  all(outliers$n_transacoes > 0),
  all(outliers$n_destinos_clinicos_dezembro > 0),
  all(abs(outliers$tempo_minimo_min - outliers$tempo_min) < 1e-8))
# Conferencia pontual independente contra os extratos financeiros anteriores.
old_money <- read.csv(file.path(out, "mides_saude_mg_consolidado_entidade_ano.csv"),
  colClasses = c(id_municipio = "character", cnpj_raiz_8 = "character")) |>
  select(id_municipio, cnpj_raiz_8, ano, valor_fonte = valor_total,
    transacoes_fonte = n_transacoes)
new_money <- read.csv(file.path(out, "atlas_pagamentos_entidade_municipio_ano.csv"),
  colClasses = c(cnpj_raiz_8 = "character", codigo_ibge_6 = "character")) |>
  select(codigo_ibge_6, cnpj_raiz_8, ano, valor_fonte = valor,
    transacoes_fonte = n_transacoes)
check_old <- outliers |>
  filter(origem_universo == "original_84") |>
  left_join(old_money, by = c("id_municipio", "cnpj_raiz_8", "ano"),
    relationship = "many-to-one")
check_new <- outliers |>
  filter(origem_universo == "candidata_externa_13") |>
  mutate(codigo_ibge_6 = substr(id_municipio, 1, 6)) |>
  left_join(new_money, by = c("codigo_ibge_6", "cnpj_raiz_8", "ano"),
    relationship = "many-to-one")
stopifnot(nrow(check_old) + nrow(check_new) == nrow(outliers),
  all(abs(check_old$valor_total - check_old$valor_fonte) < .01),
  all(abs(check_new$valor_total - check_new$valor_fonte) < .01),
  all(check_old$n_transacoes == check_old$transacoes_fonte),
  all(check_new$n_transacoes == check_new$transacoes_fonte))
write.csv(outliers, file.path(out, "eda_tempos_acima_300min_saude.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
print(annual, width = Inf)
cat("Pares pagantes com tempo acima de 300 minutos:", nrow(outliers), "\n")
cat("Valor desses pares sobre o recorte direto:",
  sum(outliers$valor_total) / sum(annual$valor_principal), "\n")
print(capacity_coverage, width = Inf)
print(sensitivity |> filter(ano == 2019L), width = Inf)
