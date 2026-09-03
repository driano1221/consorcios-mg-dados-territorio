# =============================================================================
# Passo 6 cientifico: painel municipio x entidade de saude x ano (MG)
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
})

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
model_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude")
out_dir <- file.path(model_dir, "outputs")
check_dir <- file.path(model_dir, "checks")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(check_dir, recursive = TRUE, showWarnings = FALSE)

paths <- c(
  painel_mides = file.path(project_dir, "dados/processado/painel_mg_anual.rds"),
  estabelecimentos = file.path(out_dir, "universo_saude_mg_estabelecimentos.rds"),
  entidades = file.path(out_dir, "universo_saude_mg_entidades.rds"),
  capacidade = file.path(out_dir, "capacidade_entidades_saude_mg.rds"),
  tempo = file.path(out_dir, "tempo_rodoviario_municipio_entidade_saude_mg.rds")
)
for (path in paths) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

normalizar_cnpj <- function(x) {
  digits <- gsub("[^0-9]", "", as.character(x))
  vapply(digits, function(value) {
    if (is.na(value) || !nzchar(value)) return(NA_character_)
    if (nchar(value) > 14L) return(substr(value, nchar(value) - 13L, nchar(value)))
    paste0(strrep("0", 14L - nchar(value)), value)
  }, character(1))
}

painel_mides <- readRDS(paths[["painel_mides"]])
estabelecimentos <- readRDS(paths[["estabelecimentos"]])
entidades <- readRDS(paths[["entidades"]])
capacidade <- readRDS(paths[["capacidade"]])
tempo <- readRDS(paths[["tempo"]])

mapa_cnpj <- estabelecimentos |>
  transmute(
    cnpj_consorcio = normalizar_cnpj(cnpj_consorcio),
    cnpj_raiz_8
  ) |>
  distinct()

if (anyNA(mapa_cnpj$cnpj_consorcio) || anyDuplicated(mapa_cnpj$cnpj_consorcio)) {
  stop("O crosswalk de CNPJ original para raiz nao e univoco.")
}

# Consolida matriz e filiais antes de classificar movimentos. Valores e
# transacoes sao somados; os CNPJs originais permanecem listados para auditoria.
mides_saude_linhas <- painel_mides |>
  mutate(cnpj_consorcio = normalizar_cnpj(documento_credor)) |>
  inner_join(mapa_cnpj, by = "cnpj_consorcio", relationship = "many-to-one")

mides_saude <- mides_saude_linhas |>
  group_by(id_municipio, cnpj_raiz_8, ano) |>
  summarise(
    tem_registro_mides = TRUE,
    valor_corrente = sum(valor_corrente, na.rm = TRUE),
    valor_restos = sum(valor_restos, na.rm = TRUE),
    valor_total = sum(valor_total, na.rm = TRUE),
    n_transacoes = sum(n_transacoes, na.rm = TRUE),
    n_cnpjs_originais_no_ano = n_distinct(cnpj_consorcio),
    cnpjs_originais_no_ano = paste(sort(unique(cnpj_consorcio)), collapse = "; "),
    .groups = "drop"
  ) |>
  arrange(cnpj_raiz_8, id_municipio, ano)

valor_fonte <- sum(mides_saude_linhas$valor_total, na.rm = TRUE)
if (!isTRUE(all.equal(valor_fonte, sum(mides_saude$valor_total), tolerance = 0.01))) {
  stop("A consolidacao matriz/filial nao conservou o valor MIDES.")
}

municipios <- tempo |>
  distinct(
    id_municipio = id_municipio_origem,
    cod_ibge_6 = cod_ibge_6_origem,
    municipio = municipio_origem
  ) |>
  arrange(id_municipio)

entidades_base <- entidades |>
  select(
    cnpj_raiz_8, cnpj_canonico, razao_social_canonica, sigla_canonica,
    situacao_matriz, ano_abertura_matriz, n_estabelecimentos, n_filiais,
    escopo_saude, aparece_mides_mg,
    incluir_modelo_principal_preliminar,
    incluir_sensibilidade_multiarea,
    camada_analitica, precisa_revisao_universo
  ) |>
  arrange(cnpj_raiz_8)

if (nrow(municipios) != 853L || nrow(entidades_base) != 84L) {
  stop("Universo inesperado: o painel exige 853 municipios e 84 entidades.")
}

anos <- data.frame(ano = 2014:2021)
grade <- merge(merge(municipios, entidades_base, by = NULL), anos, by = NULL) |>
  as_tibble()

tempo_vars <- tempo |>
  select(
    id_municipio = id_municipio_origem,
    cnpj_raiz_8,
    n_municipios_oferta_fixa, n_unidades_fixas,
    tempo_minimo_min, tempo_mediano_min, tempo_medio_min, tempo_maximo_min,
    distancia_minima_km, distancia_mediana_km, distancia_maxima_km,
    id_municipio_destino_mais_proximo,
    municipio_destino_mais_proximo,
    mesmo_municipio_de_alguma_oferta,
    tempo_status
  )

capacidade_vars <- capacidade |>
  select(
    cnpj_raiz_8, decisao_polo_atracao, capacidade_status,
    n_unidades_cnes_vinculadas, n_unidades_moveis_ou_itinerantes,
    n_unidades_fixas_cnes, n_municipios_oferta_direta,
    n_unidades_atendimento_ambulatorial_sus,
    n_unidades_internacao_sus, n_unidades_sadt_sus,
    leitos_existentes_rede_direta, leitos_sus_rede_direta,
    vinculos_medicos_sus_ativos_rede_direta,
    cbo_medicos_sus_ativos_rede_direta,
    data_extracao_cnes
  )

painel <- grade |>
  left_join(tempo_vars, by = c("id_municipio", "cnpj_raiz_8"), relationship = "many-to-one") |>
  left_join(capacidade_vars, by = "cnpj_raiz_8", relationship = "many-to-one") |>
  left_join(
    mides_saude,
    by = c("id_municipio", "cnpj_raiz_8", "ano"),
    relationship = "one-to-one"
  ) |>
  mutate(
    tem_registro_mides = coalesce(tem_registro_mides, FALSE),
    across(
      c(valor_corrente, valor_restos, valor_total, n_transacoes,
        n_cnpjs_originais_no_ano),
      ~ coalesce(.x, 0)
    ),
    presente_mides = valor_total > 0,
    log_valor_total_mais_1 = log1p(valor_total)
  ) |>
  group_by(id_municipio, cnpj_raiz_8) |>
  arrange(ano, .by_group = TRUE) |>
  mutate(
    presente_t_1 = lag(presente_mides),
    valor_total_t_1 = lag(valor_total),
    teve_presenca_antes_t = lag(cumany(presente_mides), default = FALSE),
    evento_movimento = case_when(
      ano == 2014L & presente_mides ~ "estoque_inicial_2014",
      ano == 2014L ~ "ausencia_inicial_2014",
      presente_mides & coalesce(presente_t_1, FALSE) ~ "permanencia",
      presente_mides & !coalesce(presente_t_1, FALSE) & teve_presenca_antes_t ~ "retorno_observado",
      presente_mides & !coalesce(presente_t_1, FALSE) ~ "primeiro_pagamento_observado",
      !presente_mides & coalesce(presente_t_1, FALSE) ~ "interrupcao_observada",
      TRUE ~ "ausencia"
    ),
    evento_primeiro_pagamento = evento_movimento == "primeiro_pagamento_observado",
    evento_retorno = evento_movimento == "retorno_observado",
    evento_entrada_ou_retorno = evento_primeiro_pagamento | evento_retorno,
    evento_permanencia = evento_movimento == "permanencia",
    evento_interrupcao = evento_movimento == "interrupcao_observada",
    variacao_valor_abs = if_else(ano > 2014L, valor_total - valor_total_t_1, NA_real_),
    taxa_variacao_valor = if_else(
      ano > 2014L & valor_total_t_1 > 0,
      (valor_total - valor_total_t_1) / valor_total_t_1,
      NA_real_
    )
  ) |>
  ungroup()

atividade_entidade_ano <- painel |>
  group_by(cnpj_raiz_8, ano) |>
  summarise(
    entidade_ativa_t = any(presente_mides),
    n_municipios_pagantes_t = sum(presente_mides),
    valor_total_entidade_t = sum(valor_total),
    .groups = "drop"
  ) |>
  group_by(cnpj_raiz_8) |>
  arrange(ano, .by_group = TRUE) |>
  mutate(
    entidade_ativa_t_1 = lag(entidade_ativa_t),
    n_municipios_pagantes_t_1 = lag(n_municipios_pagantes_t),
    valor_total_entidade_t_1 = lag(valor_total_entidade_t)
  ) |>
  ungroup()

painel <- painel |>
  left_join(
    atividade_entidade_ano,
    by = c("cnpj_raiz_8", "ano"),
    relationship = "many-to-one"
  ) |>
  mutate(
    tempo_capacidade_disponivel =
      tempo_status == "tempo_disponivel_unidades_fixas" &
      capacidade_status == "capacidade_direta_cnes_atual",
    elegivel_nucleo_com_tempo =
      incluir_modelo_principal_preliminar & tempo_capacidade_disponivel,
    universo_preliminar_primeiro_pagamento =
      ano > 2014L &
      !coalesce(presente_t_1, FALSE) &
      !teve_presenca_antes_t &
      coalesce(entidade_ativa_t_1, FALSE) &
      elegivel_nucleo_com_tempo,
    universo_preliminar_entrada_ou_retorno =
      ano > 2014L &
      !coalesce(presente_t_1, FALSE) &
      coalesce(entidade_ativa_t_1, FALSE) &
      elegivel_nucleo_com_tempo,
    universo_preliminar_retorno =
      universo_preliminar_entrada_ou_retorno & teve_presenca_antes_t,
    universo_preliminar_interrupcao =
      ano > 2014L &
      coalesce(presente_t_1, FALSE) &
      incluir_modelo_principal_preliminar,
    universo_preliminar_interrupcao_com_tempo =
      universo_preliminar_interrupcao & tempo_capacidade_disponivel,
    universo_intensidade_observada =
      presente_mides & incluir_modelo_principal_preliminar,
    universo_intensidade_observada_com_tempo =
      universo_intensidade_observada & tempo_capacidade_disponivel,
    regra_universo_preliminar = paste(
      "Grade estadual exploratoria; exige entidade ativa em t-1,",
      "nucleo setorial e tempo/capacidade direta. Nao e o conjunto",
      "final de alternativas plausiveis."
    ),
    interpretacao_presenca =
      "valor_total_mides_positivo; evidencia financeira, nao filiacao juridica"
  ) |>
  arrange(cnpj_raiz_8, id_municipio, ano)

resumo_par <- painel |>
  group_by(
    id_municipio, cod_ibge_6, municipio,
    cnpj_raiz_8, cnpj_canonico, razao_social_canonica, sigla_canonica
  ) |>
  summarise(
    n_anos_com_pagamento = sum(presente_mides),
    primeiro_ano_pagamento = {
      anos_presentes <- ano[presente_mides]
      if (length(anos_presentes)) min(anos_presentes) else NA_integer_
    },
    ultimo_ano_pagamento = {
      anos_presentes <- ano[presente_mides]
      if (length(anos_presentes)) max(anos_presentes) else NA_integer_
    },
    n_primeiros_pagamentos_observados = sum(evento_primeiro_pagamento),
    n_retornos_observados = sum(evento_retorno),
    n_interrupcoes_observadas = sum(evento_interrupcao),
    n_transicoes_presenca = sum(evento_entrada_ou_retorno | evento_interrupcao),
    movimento_recorrente = n_transicoes_presenca > 1L,
    valor_total_2014_2021 = sum(valor_total),
    .groups = "drop"
  ) |>
  arrange(cnpj_raiz_8, id_municipio)

resumo_ano <- painel |>
  group_by(ano) |>
  summarise(
    linhas_painel = n(),
    entidades_ativas = n_distinct(cnpj_raiz_8[presente_mides]),
    pares_com_pagamento = sum(presente_mides),
    estoque_inicial = sum(evento_movimento == "estoque_inicial_2014"),
    primeiros_pagamentos = sum(evento_primeiro_pagamento),
    retornos = sum(evento_retorno),
    permanencias = sum(evento_permanencia),
    interrupcoes = sum(evento_interrupcao),
    candidatos_primeiro_pagamento = sum(universo_preliminar_primeiro_pagamento),
    candidatos_entrada_ou_retorno = sum(universo_preliminar_entrada_ou_retorno),
    risco_interrupcao = sum(universo_preliminar_interrupcao),
    valor_total_mides = sum(valor_total),
    .groups = "drop"
  )

resumo_entidade <- painel |>
  group_by(cnpj_raiz_8, cnpj_canonico, razao_social_canonica, sigla_canonica) |>
  summarise(
    aparece_mides_mg = first(aparece_mides_mg),
    incluir_modelo_principal_preliminar = first(incluir_modelo_principal_preliminar),
    incluir_sensibilidade_multiarea = first(incluir_sensibilidade_multiarea),
    capacidade_status = first(capacidade_status),
    tempo_status = first(tempo_status),
    n_municipios_com_pagamento = n_distinct(id_municipio[presente_mides]),
    n_pares_ano_com_pagamento = sum(presente_mides),
    n_primeiros_pagamentos = sum(evento_primeiro_pagamento),
    n_retornos = sum(evento_retorno),
    n_interrupcoes = sum(evento_interrupcao),
    valor_total_2014_2021 = sum(valor_total),
    .groups = "drop"
  ) |>
  arrange(desc(valor_total_2014_2021), cnpj_raiz_8)

eventos <- painel |>
  filter(
    evento_movimento %in% c(
      "estoque_inicial_2014", "primeiro_pagamento_observado",
      "retorno_observado", "permanencia", "interrupcao_observada"
    )
  )

dicionario <- data.frame(
  variavel = c(
    "id_municipio", "cnpj_raiz_8", "ano", "valor_total", "presente_mides",
    "evento_movimento", "presente_t_1", "teve_presenca_antes_t",
    "tempo_minimo_min", "tempo_mediano_min", "capacidade_status",
    "universo_preliminar_primeiro_pagamento",
    "universo_preliminar_entrada_ou_retorno",
    "universo_preliminar_interrupcao",
    "universo_preliminar_interrupcao_com_tempo",
    "universo_intensidade_observada",
    "universo_intensidade_observada_com_tempo"
  ),
  definicao = c(
    "Codigo IBGE de sete digitos do municipio.",
    "Identidade consolidada de matriz e filiais pela raiz do CNPJ.",
    "Ano da observacao, de 2014 a 2021.",
    "Soma de valor corrente e restos MIDES dos CNPJs da mesma raiz.",
    "TRUE quando valor_total e positivo; nao equivale a filiacao juridica.",
    "Estoque inicial, ausencia, primeiro pagamento, retorno, permanencia ou interrupcao.",
    "Presenca financeira no ano anterior; NA em 2014.",
    "Indica pagamento em algum ano anterior a t.",
    "Menor tempo rodoviario ate unidade fixa diretamente vinculada.",
    "Mediana dos tempos ate os municipios da rede fixa diretamente vinculada.",
    "Cobertura atual da capacidade diretamente registrada no CNES.",
    "Grade exploratoria para primeiro pagamento; ainda nao define alternativas plausiveis.",
    "Grade exploratoria para entrada ou retorno; ainda nao define alternativas plausiveis.",
    "Par pagante em t-1, elegivel para observar continuidade ou interrupcao.",
    "Subconjunto de interrupcao com tempo e capacidade direta disponiveis.",
    "Par com pagamento positivo em t, para modelar intensidade financeira.",
    "Subconjunto de intensidade com tempo e capacidade direta disponiveis."
  ),
  stringsAsFactors = FALSE
)

saveRDS(mides_saude, file.path(out_dir, "mides_saude_mg_consolidado_entidade_ano.rds"), compress = "xz")
write.csv(mides_saude, file.path(out_dir, "mides_saude_mg_consolidado_entidade_ano.csv"), row.names = FALSE, fileEncoding = "UTF-8", na = "")
saveRDS(painel, file.path(out_dir, "painel_analitico_saude_mg.rds"), compress = "gzip")
saveRDS(resumo_par, file.path(out_dir, "painel_analitico_saude_mg_resumo_par.rds"), compress = "gzip")
write.csv(resumo_par, file.path(out_dir, "painel_analitico_saude_mg_resumo_par.csv"), row.names = FALSE, fileEncoding = "UTF-8", na = "")
write.csv(eventos, file.path(out_dir, "painel_analitico_saude_mg_eventos.csv"), row.names = FALSE, fileEncoding = "UTF-8", na = "")
write.csv(resumo_ano, file.path(out_dir, "painel_analitico_saude_mg_resumo_ano.csv"), row.names = FALSE, fileEncoding = "UTF-8", na = "")
write.csv(resumo_entidade, file.path(out_dir, "painel_analitico_saude_mg_resumo_entidade.csv"), row.names = FALSE, fileEncoding = "UTF-8", na = "")
write.csv(dicionario, file.path(out_dir, "DICIONARIO_PAINEL_ANALITICO_SAUDE_MG.csv"), row.names = FALSE, fileEncoding = "UTF-8", na = "")

contagens_eventos <- painel |>
  count(evento_movimento, name = "linhas") |>
  arrange(desc(linhas))
contagens_universos <- data.frame(
  universo = c(
    "primeiro_pagamento",
    "entrada_ou_retorno",
    "retorno",
    "interrupcao",
    "interrupcao_com_tempo",
    "intensidade_observada",
    "intensidade_com_tempo"
  ),
  linhas = c(
    sum(painel$universo_preliminar_primeiro_pagamento),
    sum(painel$universo_preliminar_entrada_ou_retorno),
    sum(painel$universo_preliminar_retorno),
    sum(painel$universo_preliminar_interrupcao),
    sum(painel$universo_preliminar_interrupcao_com_tempo),
    sum(painel$universo_intensidade_observada),
    sum(painel$universo_intensidade_observada_com_tempo)
  ),
  eventos_positivos = c(
    sum(painel$evento_primeiro_pagamento & painel$universo_preliminar_primeiro_pagamento),
    sum(painel$evento_entrada_ou_retorno & painel$universo_preliminar_entrada_ou_retorno),
    sum(painel$evento_retorno & painel$universo_preliminar_retorno),
    sum(painel$evento_interrupcao & painel$universo_preliminar_interrupcao),
    sum(painel$evento_interrupcao & painel$universo_preliminar_interrupcao_com_tempo),
    NA_integer_,
    NA_integer_
  )
)
formatar_inteiro <- function(x) {
  format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE)
}
formatar_brl <- function(x) {
  format(x, big.mark = ".", decimal.mark = ",", nsmall = 2, scientific = FALSE)
}
check_lines <- c(
  "# Validacao: Painel Analitico De Saude (MG)",
  "",
  paste0("- Grade completa: **", formatar_inteiro(nrow(painel)), "** linhas."),
  paste0("- Municipios: **", n_distinct(painel$id_municipio), "**; entidades: **", n_distinct(painel$cnpj_raiz_8), "**; anos: **", n_distinct(painel$ano), "**."),
  paste0("- Linhas MIDES de saude antes da consolidacao: **", formatar_inteiro(nrow(mides_saude_linhas)), "**; linhas municipio-entidade-ano consolidadas: **", formatar_inteiro(nrow(mides_saude)), "**."),
  paste0("- Valor MIDES conservado: **R$ ", formatar_brl(sum(painel$valor_total)), "**."),
  "",
  "## Eventos",
  "",
  "| Evento | Linhas |",
  "|---|---:|",
  vapply(seq_len(nrow(contagens_eventos)), function(i) paste0(
    "| ", contagens_eventos$evento_movimento[[i]], " | ",
    formatar_inteiro(contagens_eventos$linhas[[i]]), " |"
  ), character(1)),
  "",
  "## Universos Preliminares",
  "",
  "| Universo | Linhas | Eventos positivos |",
  "|---|---:|---:|",
  vapply(seq_len(nrow(contagens_universos)), function(i) paste0(
    "| ", contagens_universos$universo[[i]], " | ",
    formatar_inteiro(contagens_universos$linhas[[i]]), " | ",
    ifelse(
      is.na(contagens_universos$eventos_positivos[[i]]),
      "NA",
      formatar_inteiro(contagens_universos$eventos_positivos[[i]])
    ), " |"
  ), character(1)),
  "",
  "## Regras Protegidas",
  "",
  "- `estoque_inicial_2014` nao e tratado como entrada: o inicio real pode ser anterior a janela.",
  "- `presente_mides` significa pagamento positivo, nao filiacao juridica.",
  "- matriz e filiais sao consolidadas antes de calcular movimentos; o valor financeiro e conservado.",
  "- entidades sem unidade fixa permanecem no painel, com tempo e capacidade nao observados.",
  "- os universos de risco sao exploratorios; o conjunto final de alternativas ainda depende de regra territorial ou de tempo.",
  "- populacao, RCL, regiao de saude, bacia e mandato ainda nao foram integrados porque nao ha fonte anual validada nesta trilha.",
  "",
  "## Leitura Do Produto",
  "",
  "O RDS completo preserva inclusive os zeros. Os CSVs sao recortes auditaveis de eventos, pares e resumos, evitando um CSV integral muito grande e redundante."
)
writeLines(check_lines, file.path(check_dir, "VALIDACAO_PAINEL_ANALITICO_SAUDE_MG.md"), useBytes = TRUE)

message(
  "Passo 6 concluido: ", nrow(painel), " linhas; ",
  nrow(mides_saude), " observacoes MIDES consolidadas; R$ ",
  format(sum(painel$valor_total), scientific = FALSE, nsmall = 2), " conservados."
)
