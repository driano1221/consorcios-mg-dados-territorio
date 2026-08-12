construir_auditoria_baixa_escala <- function(movimentos, cadastro, classificacao, limite = 2L) {
  movimentos_base <- movimentos |>
    dplyr::mutate(
      ano = as.integer(ano),
      cod_ibge_6 = stringr::str_pad(as.character(cod_ibge_6), 6, side = "left", pad = "0"),
      cnpj_consorcio = stringr::str_pad(as.character(cnpj_consorcio), 14, side = "left", pad = "0"),
      municipio = stringr::str_to_title(municipio)
    )

  cadastro_base <- cadastro |>
    dplyr::mutate(
      cnpj_consorcio = stringr::str_pad(as.character(cnpj_consorcio), 14, side = "left", pad = "0")
    ) |>
    dplyr::distinct(cnpj_consorcio, .keep_all = TRUE)

  classificacao_base <- classificacao |>
    dplyr::mutate(
      cnpj_consorcio = stringr::str_pad(as.character(cnpj_consorcio), 14, side = "left", pad = "0")
    ) |>
    dplyr::distinct(cnpj_consorcio, .keep_all = TRUE)

  por_ano <- movimentos_base |>
    dplyr::filter(presente_mides) |>
    dplyr::summarise(
      n_municipios = dplyr::n_distinct(cod_ibge_6),
      valor_total_ano = sum(valor_total, na.rm = TRUE),
      .by = c(cnpj_consorcio, ano)
    )

  recorrencia <- movimentos_base |>
    dplyr::filter(movimento_recorrente) |>
    dplyr::summarise(
      pares_recorrentes = dplyr::n_distinct(cod_ibge_6),
      .by = cnpj_consorcio
    )

  movimentos_resumo <- movimentos_base |>
    dplyr::filter(presente_mides) |>
    dplyr::summarise(
      municipios_unicos = dplyr::n_distinct(cod_ibge_6),
      municipios = paste(sort(unique(municipio)), collapse = "; "),
      municipio_anos = paste(
        sort(unique(paste0(municipio, " (", ano, ")"))),
        collapse = "; "
      ),
      anos_ativos = dplyr::n_distinct(ano),
      anos = paste(sort(unique(ano)), collapse = "; "),
      primeiro_ano = min(ano),
      ultimo_ano = max(ano),
      valor_total_periodo = sum(valor_total, na.rm = TRUE),
      .by = cnpj_consorcio
    ) |>
    dplyr::left_join(
      por_ano |>
        dplyr::summarise(max_municipios_ano = max(n_municipios), .by = cnpj_consorcio),
      by = "cnpj_consorcio"
    ) |>
    dplyr::left_join(recorrencia, by = "cnpj_consorcio") |>
    dplyr::mutate(pares_recorrentes = dplyr::coalesce(pares_recorrentes, 0L)) |>
    dplyr::filter(max_municipios_ano <= limite)

  movimentos_resumo |>
    dplyr::left_join(cadastro_base, by = "cnpj_consorcio") |>
    dplyr::left_join(classificacao_base, by = "cnpj_consorcio") |>
    dplyr::mutate(
      cnpj_raiz_8 = stringr::str_sub(cnpj_consorcio, 1, 8),
      ordem_estabelecimento = stringr::str_sub(cnpj_consorcio, 9, 12),
      tipo_estabelecimento = dplyr::if_else(ordem_estabelecimento == "0001", "Matriz", "Filial"),
      anos_esperados = ultimo_ano - primeiro_ano + 1L,
      padrao_temporal = dplyr::case_when(
        anos_ativos == 1L ~ "Observado em um ano",
        anos_ativos < anos_esperados ~ "Intermitente",
        TRUE ~ "Continuo em baixa escala"
      ),
      hipotese_revisao = dplyr::case_when(
        tipo_estabelecimento == "Filial" ~ "Revisar relacao matriz/filial",
        situacao_cadastro %in% c("Baixada", "Inapta", "Suspensa") ~ "Possivel encerramento ou inatividade",
        padrao_temporal == "Observado em um ano" ~ "Possivel iniciativa pontual ou registro isolado",
        padrao_temporal == "Intermitente" ~ "Revisar lacuna e retorno",
        TRUE ~ "Baixa escala persistente"
      ),
      evidencia_automatica = paste0(
        max_municipios_ano, " municipio(s) no maximo por ano; ",
        anos_ativos, " ano(s) com pagamento; situacao ", dplyr::coalesce(situacao_cadastro, "nao informada"), "."
      )
    ) |>
    dplyr::arrange(max_municipios_ano, padrao_temporal, cnpj_consorcio)
}
