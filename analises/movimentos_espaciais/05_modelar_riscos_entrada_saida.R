# =============================================================================
# 05_modelar_riscos_entrada_saida.R
#
# Materializa universos completos de risco e estima associacoes exploratorias
# entre integracao territorial em t-1 e movimentos MIDES em t.
#
# Interpretacao obrigatoria: presenca e movimento representam pagamentos
# observados no MIDES, nao filiacao, adesao ou desligamento juridico.
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(sandwich)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(project_dir, "analises", "movimentos_espaciais", "outputs")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

raw_path <- file.path(project_dir, "dados", "processado", "painel_mg_anual.rds")
municipios_path <- file.path(
  project_dir, "dashboards", "base1_shiny", "data", "mides_municipios_lookup.rds"
)
vizinhos_path <- file.path(out_dir, "vizinhos_municipais_mg.rds")

stopifnot(file.exists(raw_path), file.exists(municipios_path), file.exists(vizinhos_path))

raw <- readRDS(raw_path) |>
  transmute(
    ano = as.integer(ano),
    cod_ibge_6 = str_sub(as.character(id_municipio), 1, 6),
    cnpj_consorcio = str_pad(as.character(documento_credor), 14, pad = "0"),
    valor_corrente = as.numeric(valor_corrente),
    valor_restos = as.numeric(valor_restos),
    valor_total = as.numeric(valor_total),
    razao_social_mides = as.character(nome_credor_freq)
  )

municipios <- readRDS(municipios_path) |>
  transmute(
    cod_ibge_6 = str_pad(as.character(cod_ibge_6), 6, pad = "0"),
    municipio = as.character(municipio)
  ) |>
  distinct(cod_ibge_6, .keep_all = TRUE)

vizinhos <- readRDS(vizinhos_path)
vizinhos_direcionados <- bind_rows(
  vizinhos |>
    transmute(
      cod_ibge_6 = municipio_a,
      vizinho_ibge_6 = municipio_b,
      comprimento_divisa_km
    ),
  vizinhos |>
    transmute(
      cod_ibge_6 = municipio_b,
      vizinho_ibge_6 = municipio_a,
      comprimento_divisa_km
    )
)

grau <- vizinhos_direcionados |>
  summarise(
    n_vizinhos_total = n(),
    comprimento_total_divisas_km = sum(comprimento_divisa_km),
    .by = cod_ibge_6
  )

identidade_cnpj <- raw |>
  filter(!is.na(razao_social_mides), razao_social_mides != "") |>
  summarise(
    razao_social_mides = first(sort(unique(razao_social_mides))),
    .by = cnpj_consorcio
  )

anos <- sort(unique(raw$ano))
ano_min <- min(anos)
ano_max <- max(anos)

regras <- list(
  principal_total_positivo = function(d) d$valor_total > 0,
  somente_corrente_positivo = function(d) d$valor_corrente > 0,
  total_minimo_100 = function(d) d$valor_total >= 100,
  total_minimo_1000 = function(d) d$valor_total >= 1000
)

construir_riscos <- function(nome_regra, regra_fn) {
  message("Construindo universo: ", nome_regra)

  ativos <- raw |>
    filter(regra_fn(pick(everything()))) |>
    distinct(ano, cod_ibge_6, cnpj_consorcio)

  primeiro_ano_par <- ativos |>
    summarise(primeiro_ano_ativo = min(ano), .by = c(cod_ibge_6, cnpj_consorcio))

  # So existe risco de difusao em t quando o CNPJ tinha ao menos um municipio
  # ativo em t-1. O primeiro aparecimento coletivo do CNPJ e documentado fora
  # do modelo, pois nao possui exposicao espacial anterior observada.
  consorcios_em_risco <- ativos |>
    count(ano, cnpj_consorcio, name = "membros_consorcio_t_1") |>
    transmute(
      ano = ano + 1L,
      cnpj_consorcio,
      membros_consorcio_t_1
    ) |>
    filter(ano <= ano_max)

  membros_t_1 <- ativos |>
    transmute(
      ano = ano + 1L,
      cod_ibge_6,
      cnpj_consorcio,
      era_membro_t_1 = TRUE
    ) |>
    filter(ano <= ano_max)

  membros_t <- ativos |>
    transmute(ano, cod_ibge_6, cnpj_consorcio, presente_t = TRUE)

  # Para cada municipio, conta quantos de seus vizinhos eram membros do CNPJ.
  vizinhos_ativos_t_1 <- membros_t_1 |>
    rename(vizinho_ibge_6 = cod_ibge_6) |>
    inner_join(
      vizinhos_direcionados,
      by = "vizinho_ibge_6",
      relationship = "many-to-many"
    ) |>
    summarise(
      n_vizinhos_no_consorcio_t_1 = n(),
      comprimento_divisa_no_consorcio_t_1_km = sum(comprimento_divisa_km),
      .by = c(ano, cnpj_consorcio, cod_ibge_6)
    )

  universo <- crossing(
    consorcios_em_risco,
    municipios
  ) |>
    left_join(
      membros_t_1,
      by = c("ano", "cod_ibge_6", "cnpj_consorcio")
    ) |>
    left_join(
      membros_t,
      by = c("ano", "cod_ibge_6", "cnpj_consorcio")
    ) |>
    left_join(
      vizinhos_ativos_t_1,
      by = c("ano", "cod_ibge_6", "cnpj_consorcio")
    ) |>
    left_join(grau, by = "cod_ibge_6") |>
    left_join(primeiro_ano_par, by = c("cod_ibge_6", "cnpj_consorcio")) |>
    left_join(identidade_cnpj, by = "cnpj_consorcio") |>
    mutate(
      era_membro_t_1 = coalesce(era_membro_t_1, FALSE),
      presente_t = coalesce(presente_t, FALSE),
      n_vizinhos_no_consorcio_t_1 = coalesce(n_vizinhos_no_consorcio_t_1, 0L),
      comprimento_divisa_no_consorcio_t_1_km = coalesce(
        comprimento_divisa_no_consorcio_t_1_km, 0
      ),
      n_vizinhos_fora_consorcio_t_1 =
        n_vizinhos_total - n_vizinhos_no_consorcio_t_1,
      prop_vizinhos_no_consorcio_t_1 =
        n_vizinhos_no_consorcio_t_1 / n_vizinhos_total,
      prop_vizinhos_fora_consorcio_t_1 =
        n_vizinhos_fora_consorcio_t_1 / n_vizinhos_total,
      candidato_externo_adjacente_t_1 =
        !era_membro_t_1 & n_vizinhos_no_consorcio_t_1 > 0L,
      participante_na_borda_t_1 =
        era_membro_t_1 & n_vizinhos_fora_consorcio_t_1 > 0L,
      participante_isolado_t_1 =
        era_membro_t_1 & n_vizinhos_no_consorcio_t_1 == 0L,
      regra_presenca = nome_regra
    )

  risco_entrada <- universo |>
    filter(!era_membro_t_1) |>
    mutate(
      entrou_observado = presente_t,
      entrada_nova_observada = presente_t & ano == primeiro_ano_ativo,
      retorno_observado = presente_t & ano > primeiro_ano_ativo,
      tipo_evento_t = case_when(
        entrada_nova_observada ~ "entrada_nova_observada",
        retorno_observado ~ "retorno_observado",
        TRUE ~ "nao_entrou"
      )
    ) |>
    select(
      ano, cod_ibge_6, municipio, cnpj_consorcio, razao_social_mides,
      regra_presenca, primeiro_ano_ativo, membros_consorcio_t_1,
      n_vizinhos_total, n_vizinhos_no_consorcio_t_1,
      n_vizinhos_fora_consorcio_t_1, prop_vizinhos_no_consorcio_t_1,
      prop_vizinhos_fora_consorcio_t_1,
      comprimento_divisa_no_consorcio_t_1_km,
      candidato_externo_adjacente_t_1,
      entrou_observado, entrada_nova_observada, retorno_observado, tipo_evento_t
    )

  risco_saida <- universo |>
    filter(era_membro_t_1) |>
    mutate(
      saiu_observado = !presente_t,
      tipo_evento_t = if_else(saiu_observado, "saida_observada", "permaneceu")
    ) |>
    select(
      ano, cod_ibge_6, municipio, cnpj_consorcio, razao_social_mides,
      regra_presenca, membros_consorcio_t_1,
      n_vizinhos_total, n_vizinhos_no_consorcio_t_1,
      n_vizinhos_fora_consorcio_t_1, prop_vizinhos_no_consorcio_t_1,
      prop_vizinhos_fora_consorcio_t_1,
      comprimento_divisa_no_consorcio_t_1_km,
      participante_na_borda_t_1, participante_isolado_t_1,
      saiu_observado, tipo_evento_t
    )

  eventos_primeiro_ano_cnpj <- ativos |>
    summarise(primeiro_ano_cnpj = min(ano), .by = cnpj_consorcio) |>
    inner_join(ativos, by = c("cnpj_consorcio", "primeiro_ano_cnpj" = "ano")) |>
    filter(primeiro_ano_cnpj > ano_min) |>
    count(primeiro_ano_cnpj, cnpj_consorcio, name = "municipios_primeiro_aparecimento")

  primeiro_ano_cnpj <- ativos |>
    summarise(primeiro_ano_cnpj = min(ano), .by = cnpj_consorcio)

  eventos_entrada_fora_risco <- ativos |>
    filter(ano > ano_min) |>
    left_join(
      membros_t_1 |>
        rename(ativo_par_t_1 = era_membro_t_1),
      by = c("ano", "cod_ibge_6", "cnpj_consorcio")
    ) |>
    filter(is.na(ativo_par_t_1)) |>
    left_join(
      consorcios_em_risco |>
        transmute(ano, cnpj_consorcio, consorcio_ativo_t_1 = TRUE),
      by = c("ano", "cnpj_consorcio")
    ) |>
    filter(is.na(consorcio_ativo_t_1)) |>
    left_join(primeiro_ano_cnpj, by = "cnpj_consorcio") |>
    left_join(municipios, by = "cod_ibge_6") |>
    left_join(identidade_cnpj, by = "cnpj_consorcio") |>
    mutate(
      motivo_exclusao = if_else(
        ano == primeiro_ano_cnpj,
        "primeiro_aparecimento_cnpj_na_janela",
        "reaparecimento_apos_cnpj_sem_ativos_t_1"
      )
    ) |>
    select(
      ano, cod_ibge_6, municipio, cnpj_consorcio, razao_social_mides,
      primeiro_ano_cnpj, motivo_exclusao
    )

  list(
    entrada = risco_entrada,
    saida = risco_saida,
    eventos_primeiro_ano_cnpj = eventos_primeiro_ano_cnpj,
    eventos_entrada_fora_risco = eventos_entrada_fora_risco
  )
}

ajustar_modelo <- function(dados, resposta, exposicao) {
  formula_modelo <- reformulate(
    c(exposicao, "log1p(membros_consorcio_t_1)", "n_vizinhos_total", "factor(ano)"),
    response = resposta
  )
  modelo <- glm(
    formula_modelo,
    data = dados,
    family = binomial(),
    model = TRUE,
    x = FALSE,
    y = FALSE
  )
  if (!isTRUE(modelo$converged)) stop("Modelo nao convergiu: ", resposta, " ~ ", exposicao)
  termos_exposicao <- startsWith(names(coef(modelo)), exposicao)
  if (!any(termos_exposicao & !is.na(coef(modelo)))) {
    stop("Exposicao nao estimada: ", exposicao)
  }
  modelo
}

extrair_estimativa <- function(modelo, dados, termo, escala, nome_modelo, regra) {
  # Erros-padrao agrupados em duas dimensoes: municipio e consorcio.
  vcov_agrupada <- sandwich::vcovCL(
    modelo,
    cluster = dados[c("cod_ibge_6", "cnpj_consorcio")],
    type = "HC1",
    cadjust = TRUE
  )
  beta <- unname(coef(modelo)[termo])
  erro <- sqrt(diag(vcov_agrupada))[[termo]]
  resposta_modelo <- model.response(modelo$model)
  tibble(
    regra_presenca = regra,
    modelo = nome_modelo,
    termo = termo,
    escala_interpretacao = escala,
    coeficiente_logit = beta,
    erro_padrao_agrupado = erro,
    odds_ratio = exp(beta * escala),
    ic95_inferior = exp((beta - 1.96 * erro) * escala),
    ic95_superior = exp((beta + 1.96 * erro) * escala),
    n_exposicoes = nrow(dados),
    n_eventos = sum(resposta_modelo),
    taxa_evento = mean(resposta_modelo)
  )
}

faixa_integracao <- function(x) {
  cut(
    x,
    breaks = c(-Inf, 0, .2, .4, .6, .8, Inf),
    labels = c("0%", "0-20%", "20-40%", "40-60%", "60-80%", ">80%")
  )
}

resultados_modelos <- list()
resultados_faixas <- list()
resumos_universos <- list()
primeiros_aparecimentos <- list()
entradas_fora_risco <- list()

for (nome_regra in names(regras)) {
  riscos <- construir_riscos(nome_regra, regras[[nome_regra]])
  entrada <- riscos$entrada
  saida <- riscos$saida

  if (nome_regra == "principal_total_positivo") {
    saveRDS(entrada, file.path(out_dir, "risco_entrada_completo_municipio_consorcio_ano.rds"))
    saveRDS(saida, file.path(out_dir, "risco_saida_municipio_consorcio_ano.rds"))
    write_csv(saida, file.path(out_dir, "risco_saida_municipio_consorcio_ano.csv"), na = "")
    write_csv(
      entrada |> filter(candidato_externo_adjacente_t_1),
      file.path(out_dir, "risco_entrada_adjacente_municipio_consorcio_ano.csv"),
      na = ""
    )
  }

  resumos_universos[[nome_regra]] <- bind_rows(
    entrada |>
      summarise(
        universo = "entrada_todos_nao_membros",
        exposicoes = n(),
        eventos = sum(entrou_observado),
        taxa = mean(entrou_observado),
        adjacentes = sum(candidato_externo_adjacente_t_1),
        eventos_adjacentes = sum(entrou_observado & candidato_externo_adjacente_t_1)
      ),
    entrada |>
      filter(is.na(primeiro_ano_ativo) | primeiro_ano_ativo >= ano) |>
      summarise(
        universo = "entrada_nova_sem_presenca_anterior",
        exposicoes = n(),
        eventos = sum(entrada_nova_observada),
        taxa = mean(entrada_nova_observada),
        adjacentes = sum(candidato_externo_adjacente_t_1),
        eventos_adjacentes = sum(
          entrada_nova_observada & candidato_externo_adjacente_t_1
        )
      ),
    entrada |>
      filter(primeiro_ano_ativo < ano) |>
      summarise(
        universo = "retorno_com_presenca_anterior",
        exposicoes = n(),
        eventos = sum(retorno_observado),
        taxa = mean(retorno_observado),
        adjacentes = sum(candidato_externo_adjacente_t_1),
        eventos_adjacentes = sum(retorno_observado & candidato_externo_adjacente_t_1)
      ),
    saida |>
      summarise(
        universo = "saida_membros_ativos_t_1",
        exposicoes = n(),
        eventos = sum(saiu_observado),
        taxa = mean(saiu_observado),
        adjacentes = NA_integer_,
        eventos_adjacentes = NA_integer_
      )
  ) |>
    mutate(regra_presenca = nome_regra, .before = 1)

  resultados_faixas[[paste0(nome_regra, "_entrada")]] <- entrada |>
    mutate(faixa = faixa_integracao(prop_vizinhos_no_consorcio_t_1)) |>
    summarise(
      regra_presenca = nome_regra,
      universo = "entrada_todos_nao_membros",
      exposicoes = n(),
      eventos = sum(entrou_observado),
      taxa_evento = mean(entrou_observado),
      .by = faixa
    )

  resultados_faixas[[paste0(nome_regra, "_saida")]] <- saida |>
    mutate(faixa = faixa_integracao(prop_vizinhos_no_consorcio_t_1)) |>
    summarise(
      regra_presenca = nome_regra,
      universo = "saida_membros_ativos_t_1",
      exposicoes = n(),
      eventos = sum(saiu_observado),
      taxa_evento = mean(saiu_observado),
      .by = faixa
    )

  modelo_entrada_prop <- ajustar_modelo(
    entrada, "entrou_observado", "prop_vizinhos_no_consorcio_t_1"
  )
  modelo_saida_prop <- ajustar_modelo(
    saida, "saiu_observado", "prop_vizinhos_no_consorcio_t_1"
  )

  resultados_modelos[[paste0(nome_regra, "_entrada_prop")]] <- extrair_estimativa(
    modelo_entrada_prop, entrada, "prop_vizinhos_no_consorcio_t_1", .1,
    "entrada_prop_vizinhos_10pp", nome_regra
  )
  resultados_modelos[[paste0(nome_regra, "_saida_prop")]] <- extrair_estimativa(
    modelo_saida_prop, saida, "prop_vizinhos_no_consorcio_t_1", .1,
    "saida_prop_vizinhos_10pp", nome_regra
  )

  if (nome_regra == "principal_total_positivo") {
    risco_entrada_nova <- entrada |>
      filter(is.na(primeiro_ano_ativo) | primeiro_ano_ativo >= ano)
    risco_retorno <- entrada |>
      filter(primeiro_ano_ativo < ano)

    modelo_entrada_adjacencia <- ajustar_modelo(
      entrada, "entrou_observado", "candidato_externo_adjacente_t_1"
    )
    modelo_entrada_nova_prop <- ajustar_modelo(
      risco_entrada_nova,
      "entrada_nova_observada",
      "prop_vizinhos_no_consorcio_t_1"
    )
    modelo_retorno_prop <- ajustar_modelo(
      risco_retorno, "retorno_observado", "prop_vizinhos_no_consorcio_t_1"
    )
    modelo_saida_isolamento <- ajustar_modelo(
      saida, "saiu_observado", "participante_isolado_t_1"
    )
    modelo_saida_borda <- ajustar_modelo(
      saida, "saiu_observado", "participante_na_borda_t_1"
    )
    resultados_modelos[["principal_entrada_adjacencia"]] <- extrair_estimativa(
      modelo_entrada_adjacencia, entrada, "candidato_externo_adjacente_t_1TRUE", 1,
      "entrada_candidato_adjacente", nome_regra
    )
    resultados_modelos[["principal_entrada_nova_prop"]] <- extrair_estimativa(
      modelo_entrada_nova_prop, risco_entrada_nova,
      "prop_vizinhos_no_consorcio_t_1", .1,
      "entrada_nova_prop_vizinhos_10pp", nome_regra
    )
    resultados_modelos[["principal_retorno_prop"]] <- extrair_estimativa(
      modelo_retorno_prop, risco_retorno,
      "prop_vizinhos_no_consorcio_t_1", .1,
      "retorno_prop_vizinhos_10pp", nome_regra
    )
    resultados_modelos[["principal_saida_isolamento"]] <- extrair_estimativa(
      modelo_saida_isolamento, saida, "participante_isolado_t_1TRUE", 1,
      "saida_participante_isolado", nome_regra
    )
    resultados_modelos[["principal_saida_borda"]] <- extrair_estimativa(
      modelo_saida_borda, saida, "participante_na_borda_t_1TRUE", 1,
      "saida_participante_na_borda", nome_regra
    )
  }

  primeiros_aparecimentos[[nome_regra]] <- riscos$eventos_primeiro_ano_cnpj |>
    mutate(regra_presenca = nome_regra, .before = 1)
  entradas_fora_risco[[nome_regra]] <- riscos$eventos_entrada_fora_risco |>
    mutate(regra_presenca = nome_regra, .before = 1)

  rm(riscos, entrada, saida)
  gc(verbose = FALSE)
}

resumo_universos <- bind_rows(resumos_universos)
taxas_faixas <- bind_rows(resultados_faixas)
modelos <- bind_rows(resultados_modelos)
eventos_primeiro_ano <- bind_rows(primeiros_aparecimentos)
eventos_fora_risco <- bind_rows(entradas_fora_risco)

write_csv(resumo_universos, file.path(out_dir, "modelos_resumo_universos.csv"), na = "")
write_csv(taxas_faixas, file.path(out_dir, "modelos_taxas_por_integracao.csv"), na = "")
write_csv(modelos, file.path(out_dir, "modelos_logisticos_resultados.csv"), na = "")
write_csv(
  eventos_primeiro_ano,
  file.path(out_dir, "eventos_primeiro_aparecimento_cnpj.csv"),
  na = ""
)
write_csv(
  eventos_fora_risco,
  file.path(out_dir, "eventos_entrada_fora_universo_modelo.csv"),
  na = ""
)

message("\nUniversos e modelos concluidos")
message("  Saida: ", out_dir)
