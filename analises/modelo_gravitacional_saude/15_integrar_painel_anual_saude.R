# Painel anual auditavel: pagamentos, oferta clinica em dezembro e impedancia.
# Executar a partir deste diretorio. Nao sobrescreve a grade preliminar 07.
# Populacao: SELECT ano,id_municipio,populacao FROM
# `basedosdados.br_ibge_populacao.municipio` WHERE sigla_uf='MG'
# AND ano BETWEEN 2014 AND 2021 (BigQuery, projeto de cobranca ipea-consorcios).
suppressPackageStartupMessages(library(dplyr))
Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8")

out <- file.path(getwd(), "outputs")
repo <- normalizePath(file.path(getwd(), "../.."), winslash = "/")
csv <- function(name, cols = NULL) read.csv(file.path(out, name),
  stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM", colClasses = cols,
  check.names = FALSE)
assert <- function(ok, message) if (!isTRUE(ok)) stop(message, call. = FALSE)

old <- readRDS(file.path(out, "painel_analitico_saude_mg.rds"))
original <- csv("universo_saude_mg_entidades.csv", c(cnpj_raiz_8 = "character"))
review <- csv("revisao_fora_84_resultado.csv", c(cnpj_raiz_8 = "character"))
review <- review |> filter(decisao %in% c("candidato_saude_historica",
  "saude_historica_escopo_a_segregar"))
assert(nrow(original) == 84L && nrow(review) == 13L, "Universo nao tem 84 + 13 raizes")
assert(!any(review$cnpj_raiz_8 %in% original$cnpj_raiz_8), "Candidata ja integra as 84")

municipios <- old |> distinct(id_municipio, cod_ibge_6, municipio)
assert(nrow(municipios) == 853L, "Municipios MG: esperado 853")
regions <- csv("regionalizacao_saude_mg_pdr_2019.csv",
  c(codigo_ibge_6 = "character", macro_saude_2019 = "character",
    micro_saude_2019 = "character"))
assert(nrow(regions) == 853L && !anyDuplicated(regions$codigo_ibge_6),
  "Regionalizacao PDR 2019 invalida")
municipios <- municipios |>
  left_join(regions, by = c("cod_ibge_6" = "codigo_ibge_6"),
    relationship = "one-to-one")
assert(!anyNA(municipios$micro_saude_2019), "Municipio MG sem micro de saude")
roots_original <- original |>
  transmute(cnpj_raiz_8, sigla = sigla_canonica, origem_universo = "original_84",
    ano_abertura = suppressWarnings(as.integer(ano_abertura_matriz)),
    grupo_escopo = if_else(cnpj_raiz_8 %in% c("01272081", "06070075", "07306549"),
      "multiarea_sensibilidade", if_else(incluir_modelo_principal_preliminar == "TRUE",
      "saude_prioritaria", "fora_nucleo_preliminar")))
roots_new <- review |>
  transmute(cnpj_raiz_8, sigla = sigla, origem_universo = "candidata_externa_13",
    ano_abertura = suppressWarnings(as.integer(ano_abertura)),
    grupo_escopo = if_else(decisao == "saude_historica_escopo_a_segregar",
      "multiarea_sensibilidade", "saude_candidata_documental"))
roots <- bind_rows(roots_original, roots_new)
assert(nrow(roots) == 97L && !anyDuplicated(roots$cnpj_raiz_8), "Duplicata na lista de raizes")

# Financeiro original ja consolidado por matriz/filiais no passo 07; atlas
# complementar entra apenas nas 13 candidatas, sem somar duas vezes.
finance_old <- old |>
  select(id_municipio, cnpj_raiz_8, ano, valor_total, n_transacoes, tem_registro_mides)
atlas <- csv("atlas_pagamentos_entidade_municipio_ano.csv",
  c(cnpj_raiz_8 = "character", codigo_ibge_6 = "character"))
finance_new <- atlas |>
  filter(cnpj_raiz_8 %in% review$cnpj_raiz_8) |>
  left_join(municipios |> select(id_municipio, cod_ibge_6),
    by = c("codigo_ibge_6" = "cod_ibge_6"), relationship = "many-to-one") |>
  transmute(id_municipio, cnpj_raiz_8, ano = as.integer(ano),
    valor_total = as.numeric(valor), n_transacoes = as.integer(n_transacoes),
    tem_registro_mides = TRUE)
assert(!anyNA(finance_new$id_municipio), "MIDES externo sem municipio MG")
assert(!anyDuplicated(finance_new[c("id_municipio", "cnpj_raiz_8", "ano")]),
  "Financeiro externo tem chave duplicada")
assert(abs(sum(finance_old$valor_total) - 3101980422.83) < .02,
  "Total MIDES original mudou")
assert(abs(sum(finance_new$valor_total) - sum(as.numeric(atlas$valor[atlas$cnpj_raiz_8 %in%
  review$cnpj_raiz_8]))) < .02, "MIDES complementar nao foi conservado")

# O arquivo de elegibilidade e o CNES de dezembro ja filtrados funcionalmente
# pelos passos 09-11. A extracao 14 aplica a mesma funcao as candidatas.
units_old <- csv("elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv",
  c(cnpj_raiz_8 = "character", codigo_ibge_6 = "character", cnes = "character"))
units_new <- csv("candidatas_cnes_capacidade_unidades_2014_2021.csv",
  c(cnpj_raiz_8 = "character", codigo_ibge_6 = "character", cnes = "character"))
unit_subset <- function(df) df |>
  transmute(cnpj_raiz_8, ano = as.integer(ano), cnes, codigo_ibge_6,
    funcao_assistencial,
    leitos_sus = as.numeric(leitos_sus),
    n_servicos_especializados_sus = as.numeric(n_servicos_especializados_sus),
    n_profissionais_sus_distintos = as.numeric(n_profissionais_sus_distintos))
units <- bind_rows(unit_subset(units_old), unit_subset(units_new))
assert(nrow(units_old) == 1868L && nrow(units_new) == 74L,
  "Quantidade inesperada de unidades-ano CNES")
assert(!anyDuplicated(units[c("cnpj_raiz_8", "ano", "cnes")]),
  "CNES duplicado por entidade-ano")
clinical <- units |> filter(funcao_assistencial == "destino_clinico_fixo")
capacity <- clinical |>
  group_by(cnpj_raiz_8, ano) |>
  summarise(n_destinos_clinicos_dezembro = n(),
    n_municipios_clinicos_dezembro = n_distinct(codigo_ibge_6),
    leitos_sus_clinicos = sum(leitos_sus, na.rm = TRUE),
    servicos_sus_clinicos_soma_unidades = sum(n_servicos_especializados_sus, na.rm = TRUE),
    profissionais_sus_clinicos_soma_unidades = sum(n_profissionais_sus_distintos, na.rm = TRUE),
    .groups = "drop")
decisions91 <- csv("decisoes_documentais_91_entidades_ano.csv",
  c(cnpj_raiz_8 = "character")) |>
  transmute(cnpj_raiz_8, ano = as.integer(ano),
    classificacao_assistencial_documental = if_else(nzchar(classificacao_final),
      classificacao_final, classificacao),
    decisao_destino_fixo_anual = if_else(nzchar(decisao_modelo_principal),
      decisao_modelo_principal, decisao_principal),
    uso_sensibilidade_documental = if_else(nzchar(uso_sensibilidade),
      uso_sensibilidade, decisao_sensibilidade))
decisions7 <- csv("decisoes_anuais_sete_entidades.csv",
  c(cnpj_raiz_8 = "character")) |>
  transmute(cnpj_raiz_8, ano = as.integer(ano),
    decisao_sete_prioritarias = decisao_principal)
assert(nrow(decisions91) == 91L && nrow(decisions7) == 56L &&
  !anyDuplicated(decisions91[c("cnpj_raiz_8", "ano")]) &&
  !anyDuplicated(decisions7[c("cnpj_raiz_8", "ano")]),
  "Decisoes documentais com chave inesperada")

source_road <- file.path(repo, "dados/bruto/externo/distbrasil/dist_brasil_zenodo_11400243.rds")
assert(identical(unname(tools::md5sum(source_road)), "39f71b10ddf9fda7c53e2b39fa6bd202"),
  "Matriz rodoviaria com checksum inesperado")
road_cache <- file.path(out, "rotas_mg_distbrasil_cache.rds")
if (file.exists(road_cache)) {
  road <- readRDS(road_cache)
} else {
  road <- readRDS(source_road) |>
    filter(orig >= 3100000L, orig < 3200000L,
      dest >= 3100000L, dest < 3200000L) |>
    transmute(a = pmin(as.character(orig), as.character(dest)),
      b = pmax(as.character(orig), as.character(dest)),
      tempo_min = as.numeric(dur), distancia_km = as.numeric(dist) / 1000)
  saveRDS(road, road_cache, compress = "gzip")
}
assert(nrow(road) == choose(853L, 2L) && !anyNA(road$tempo_min),
  "Matriz rodoviaria MG incompleta")
destinations <- clinical |>
  distinct(cnpj_raiz_8, ano, codigo_ibge_6) |>
  left_join(municipios |> select(destino_id = id_municipio, codigo_ibge_6 = cod_ibge_6,
    micro_destino_2019 = micro_saude_2019),
    by = "codigo_ibge_6", relationship = "many-to-one")
assert(!anyNA(destinations$destino_id), "Destino clinico fora dos municipios MG")
routes <- merge(municipios |> select(id_municipio, micro_origem_2019 = micro_saude_2019),
  destinations, by = NULL) |>
  as_tibble() |>
  mutate(a = pmin(as.character(id_municipio), as.character(destino_id)),
    b = pmax(as.character(id_municipio), as.character(destino_id))) |>
  left_join(road, by = c("a", "b"), relationship = "many-to-one") |>
  mutate(tempo_min = if_else(id_municipio == destino_id, 0, tempo_min),
    distancia_km = if_else(id_municipio == destino_id, 0, distancia_km))
assert(!anyNA(routes$tempo_min), "Rota para destino clinico nao encontrada")
times <- routes |>
  group_by(id_municipio, cnpj_raiz_8, ano) |>
  arrange(tempo_min, destino_id, .by_group = TRUE) |>
  summarise(tempo_minimo_min = first(tempo_min),
    tempo_mediano_min = median(tempo_min),
    tempo_maximo_min = max(tempo_min),
    distancia_minima_km = first(distancia_km),
    destino_clinico_mais_proximo_id = first(destino_id),
    algum_destino_mesma_micro_2019 = any(micro_origem_2019 == micro_destino_2019),
    .groups = "drop")

population <- csv("populacao_municipal_ibge_2014_2021.csv",
  c(id_municipio = "character")) |>
  mutate(ano = as.integer(ano), populacao_ibge = as.numeric(populacao)) |>
  select(id_municipio, ano, populacao_ibge)
assert(nrow(population) == 853L * 8L && !anyDuplicated(population[c("id_municipio", "ano")]),
  "Populacao IBGE incompleta ou duplicada")
rcl_files <- list.files(out, pattern = "^rcl_siconfi_mg_20[0-9]{2}\\.csv$", full.names = TRUE)
rcl <- if (length(rcl_files)) bind_rows(lapply(rcl_files, function(path) {
  read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM",
    colClasses = c(id_municipio = "character")) |>
    transmute(id_municipio, ano = as.integer(ano),
      rcl_municipal = as.numeric(rcl_municipal), status_rcl = status)
})) else tibble(id_municipio = character(), ano = integer(),
  rcl_municipal = numeric(), status_rcl = character())
assert(!anyDuplicated(rcl[c("id_municipio", "ano")]), "RCL duplicada")

grid <- merge(merge(municipios, roots, by = NULL), data.frame(ano = 2014:2021), by = NULL) |>
  as_tibble() |>
  left_join(finance_old, by = c("id_municipio", "cnpj_raiz_8", "ano"),
    relationship = "one-to-one") |>
  left_join(finance_new, by = c("id_municipio", "cnpj_raiz_8", "ano"),
    relationship = "one-to-one", suffix = c("", "_externo")) |>
  mutate(valor_total = coalesce(valor_total, valor_total_externo, 0),
    n_transacoes = coalesce(n_transacoes, n_transacoes_externo, 0L),
    tem_registro_mides = coalesce(tem_registro_mides, tem_registro_mides_externo, FALSE)) |>
  select(-ends_with("_externo")) |>
  left_join(capacity, by = c("cnpj_raiz_8", "ano"), relationship = "many-to-one") |>
  left_join(decisions91, by = c("cnpj_raiz_8", "ano"), relationship = "many-to-one") |>
  left_join(decisions7, by = c("cnpj_raiz_8", "ano"), relationship = "many-to-one") |>
  left_join(times, by = c("id_municipio", "cnpj_raiz_8", "ano"),
    relationship = "one-to-one") |>
  left_join(population, by = c("id_municipio", "ano"),
    relationship = "many-to-one") |>
  left_join(rcl, by = c("id_municipio", "ano"), relationship = "many-to-one") |>
  mutate(instituicao_aberta_no_ano = is.na(ano_abertura) | ano >= ano_abertura,
    status_rcl = if_else(ano == 2014L, "rreo_2014_nao_disponivel_api",
      coalesce(status_rcl, "ano_ainda_nao_consultado")),
    clinica_direta_dezembro = !is.na(n_destinos_clinicos_dezembro),
    # Ausencia de CNES direto nao e prova de ausencia de rede indireta.
    alternativa_cadastral_saude = instituicao_aberta_no_ano &
      grupo_escopo %in% c("saude_prioritaria", "saude_candidata_documental"),
    alternativa_direta_com_tempo = alternativa_cadastral_saude &
      clinica_direta_dezembro & !is.na(tempo_minimo_min),
    alternativa_90min_diagnostica = alternativa_direta_com_tempo & tempo_minimo_min <= 90,
    alternativa_mesma_micro_2019_diagnostica = ano >= 2019L &
      alternativa_direta_com_tempo & coalesce(algum_destino_mesma_micro_2019, FALSE),
    valor_por_habitante = valor_total / populacao_ibge,
    regiao_saude = if_else(ano >= 2019L, micro_saude_2019, NA_character_),
    versao_regiao_saude = if_else(ano >= 2019L, "PDR_MG_2019_referencia",
      "sem_mapa_historico_validado"),
    ano_ciclo_mandato = (ano - 2013L) %% 4L + 1L) |>
  group_by(id_municipio, cnpj_raiz_8) |>
  arrange(ano, .by_group = TRUE) |>
  mutate(presente_mides = valor_total > 0,
    presente_t_1 = lag(presente_mides),
    valor_total_t_1 = lag(valor_total),
    ja_pagou_antes_t = lag(cumany(presente_mides), default = FALSE),
    evento_movimento = case_when(
      ano == 2014L & presente_mides ~ "estoque_inicial_2014",
      ano == 2014L ~ "ausencia_inicial_2014",
      presente_mides & coalesce(presente_t_1, FALSE) ~ "permanencia",
      presente_mides & ja_pagou_antes_t ~ "retorno_observado",
      presente_mides ~ "primeiro_pagamento_observado",
      coalesce(presente_t_1, FALSE) ~ "interrupcao_observada",
      TRUE ~ "ausencia"),
    # Preditores defasados sao os unicos admitidos nos modelos de entrada.
    tempo_minimo_t_1 = lag(tempo_minimo_min),
    leitos_sus_clinicos_t_1 = lag(leitos_sus_clinicos),
    n_destinos_clinicos_t_1 = lag(n_destinos_clinicos_dezembro),
    alternativa_direta_t_1 = lag(alternativa_direta_com_tempo),
    risco_primeiro_pagamento = ano > 2014L & alternativa_cadastral_saude &
      !ja_pagou_antes_t,
    risco_retorno = ano > 2014L & alternativa_cadastral_saude &
      ja_pagou_antes_t & !coalesce(presente_t_1, FALSE),
    risco_interrupcao = ano > 2014L & alternativa_cadastral_saude &
      coalesce(presente_t_1, FALSE),
    universo_intensidade_observada = presente_mides,
    universo_intensidade_cadastral = presente_mides & alternativa_cadastral_saude,
    universo_intensidade_principal = presente_mides & alternativa_direta_com_tempo,
    risco_entrada_com_tempo_t_1 = risco_primeiro_pagamento &
      coalesce(alternativa_direta_t_1, FALSE),
    risco_retorno_com_tempo_t_1 = risco_retorno &
      coalesce(alternativa_direta_t_1, FALSE),
    risco_interrupcao_com_tempo_t_1 = risco_interrupcao &
      coalesce(alternativa_direta_t_1, FALSE)) |>
  ungroup()

assert(nrow(grid) == 853L * 97L * 8L &&
  !anyDuplicated(grid[c("id_municipio", "cnpj_raiz_8", "ano")]), "Grade anual invalida")
assert(all(!is.na(grid$populacao_ibge)), "Populacao ausente na grade")
assert(abs(sum(grid$valor_total[grid$origem_universo == "original_84"]) -
  sum(finance_old$valor_total)) < .02, "Valor original nao conservado")
assert(abs(sum(grid$valor_total[grid$origem_universo == "candidata_externa_13"]) -
  sum(finance_new$valor_total)) < .02, "Valor das candidatas nao conservado")
assert(all(is.na(grid$tempo_minimo_min[!grid$clinica_direta_dezembro])),
  "Tempo imputado sem clinica direta")

saveRDS(grid, file.path(out, "painel_anual_integrado_saude_mg_2014_2021.rds"), compress = "gzip")
summary <- grid |>
  group_by(ano) |>
  summarise(n_entidades = n_distinct(cnpj_raiz_8), n_pares_pagantes = sum(presente_mides),
    valor_mides = sum(valor_total), n_entidades_clinica_direta =
      n_distinct(cnpj_raiz_8[clinica_direta_dezembro]),
    n_alternativas_cadastrais = sum(alternativa_cadastral_saude),
    n_alternativas_diretas = sum(alternativa_direta_com_tempo),
    n_alternativas_90min = sum(alternativa_90min_diagnostica),
    n_alternativas_mesma_micro_2019 = sum(alternativa_mesma_micro_2019_diagnostica),
    pagamentos_sem_tempo_direto = sum(presente_mides & is.na(tempo_minimo_min)),
    .groups = "drop")
write.csv(summary, file.path(out, "painel_anual_integrado_resumo.csv"), row.names = FALSE,
  fileEncoding = "UTF-8")
print(summary, n = 8)
cat("OK:", nrow(grid), "linhas; financeiro original e externo preservados.\n")
