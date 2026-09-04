# =============================================================================
# 04_definir_polos_atracao_saude.R
#
# Define, para cada entidade de saude consolidada em MG, a sede administrativa
# e o estado atual da evidencia de polo assistencial. A fonte primaria e a
# consulta publica CNES de estabelecimentos mantidos pelo CNPJ. Nenhuma sede
# administrativa e tratada automaticamente como hospital ou rede assistencial.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(stringr)
  library(rvest)
})

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
analysis_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude")
out_dir <- file.path(analysis_dir, "outputs")
check_dir <- file.path(analysis_dir, "checks")
universe_path <- file.path(out_dir, "universo_saude_mg_entidades.rds")

if (!file.exists(universe_path)) {
  stop("Execute primeiro 01_fechar_universo_saude_mg.R: ", universe_path)
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(check_dir, recursive = TRUE, showWarnings = FALSE)

snapshot_date <- as.character(Sys.Date())
snapshot_tag <- gsub("-", "_", snapshot_date, fixed = TRUE)
source_base <- "https://cnes2.datasus.gov.br"

clean_text <- function(x) {
  x |>
    gsub("[\\r\\n\\t]+", " ", x = _) |>
    gsub("\\s+", " ", x = _) |>
    trimws()
}

split_cnpjs <- function(x) {
  values <- unlist(strsplit(as.character(x), " | ", fixed = TRUE))
  values <- gsub("\\D", "", values)
  values[nchar(values) == 14L]
}

fetch_cnes <- function(url, attempts = 2L, referer = NULL) {
  last_error <- NA_character_
  for (attempt in seq_len(attempts)) {
    temp_file <- tempfile(fileext = ".html")
    result <- tryCatch({
      curl_args <- c("-sS", "-L", "--max-time", "20", "-A", "Mozilla/5.0")
      if (!is.null(referer)) curl_args <- c(curl_args, "-e", referer)
      system2(
        "curl.exe",
        c(curl_args, "-o", shQuote(temp_file), shQuote(url)),
        stdout = FALSE,
        stderr = FALSE
      )
    },
      error = function(e) e
    )

    bytes <- if (file.exists(temp_file)) file.info(temp_file)$size else 0L
    if (!inherits(result, "error") && identical(result, 0L) && !is.na(bytes) && bytes > 0L) {
      content <- readBin(temp_file, what = "raw", n = bytes)
      unlink(temp_file)
      return(list(ok = TRUE, status_code = 200L, content = content, error = NA_character_))
    }
    unlink(temp_file)

    last_error <- if (inherits(result, "error")) conditionMessage(result) else paste("curl exit", result)
    if (attempt < attempts) Sys.sleep(1)
  }

  list(ok = FALSE, status_code = NA_integer_, content = raw(), error = last_error)
}

read_cnes_html <- function(raw_content) {
  rvest::read_html(raw_content, encoding = "ISO-8859-1")
}

parse_listing <- function(raw_content) {
  document <- read_cnes_html(raw_content)
  links <- rvest::html_elements(document, "a")
  href <- rvest::html_attr(links, "href")
  matched <- str_match(href, "VCo_Unidade=([0-9]{13})")
  keep <- !is.na(matched[, 2])

  if (!any(keep)) {
    return(data.frame(
      co_unidade = character(),
      cnes = character(),
      nome_estabelecimento_cnes = character(),
      stringsAsFactors = FALSE
    ))
  }

  result <- data.frame(
    co_unidade = matched[keep, 2],
    nome_estabelecimento_cnes = clean_text(rvest::html_text2(links[keep])),
    stringsAsFactors = FALSE
  ) |>
    group_by(co_unidade) |>
    slice(1) |>
    ungroup() |>
    mutate(cnes = substr(co_unidade, nchar(co_unidade) - 6L, nchar(co_unidade))) |>
    select(co_unidade, cnes, nome_estabelecimento_cnes)

  result
}

parse_json_listing <- function(raw_content) {
  text <- rawToChar(raw_content)
  if (!str_detect(trimws(text), "^[\\[{]")) stop("Resposta CNES nao e JSON.")
  parsed <- jsonlite::fromJSON(text, simplifyDataFrame = TRUE)
  if (is.null(parsed) || length(parsed) == 0L) {
    return(data.frame(
      co_unidade = character(),
      cnes = character(),
      nome_estabelecimento_cnes = character(),
      stringsAsFactors = FALSE
    ))
  }

  data.frame(
    co_unidade = as.character(parsed$id),
    cnes = as.character(parsed$cnes),
    nome_estabelecimento_cnes = clean_text(parsed$noFantasia),
    stringsAsFactors = FALSE
  ) |>
    distinct(co_unidade, .keep_all = TRUE)
}

parse_detail <- function(raw_content) {
  document <- read_cnes_html(raw_content)
  tables <- rvest::html_table(document, fill = TRUE)
  table_index <- which(vapply(tables, function(table) {
    any(str_detect(as.character(unlist(table, use.names = FALSE)), regex("municip", ignore_case = TRUE))) &&
      any(str_detect(as.character(unlist(table, use.names = FALSE)), regex("tipo estabelecimento", ignore_case = TRUE)))
  }, logical(1)))

  if (length(table_index) == 0L) {
    return(data.frame(
      municipio_cnes = NA_character_, codigo_ibge_cnes = NA_character_, uf_cnes = NA_character_,
      tipo_estabelecimento_cnes = NA_character_, subtipo_estabelecimento_cnes = NA_character_,
      dependencia_cnes = NA_character_, stringsAsFactors = FALSE
    ))
  }

  # A pagina antiga do CNES possui uma tabela externa que repete o conteudo da
  # ficha. A tabela interna, com menos colunas, preserva a relacao cabecalho /
  # valor que precisamos para municipio e tipo de unidade.
  table_widths <- vapply(tables[table_index], ncol, integer(1))
  table <- as.matrix(tables[[table_index[[which.min(table_widths)]]]])
  value_below <- function(pattern) {
    positions <- which(str_detect(as.vector(table), regex(pattern, ignore_case = TRUE)))
    if (length(positions) == 0L) return(NA_character_)
    position <- arrayInd(positions[[1]], dim(table))
    if (position[[1]] >= nrow(table)) return(NA_character_)
    clean_text(table[position[[1]] + 1L, position[[2]]])
  }

  # O HTML legado pode corromper o acento de "municipio". A grade basica tem
  # uma linha ancorada em "Complemento" e, na linha seguinte, municipio/UF nas
  # colunas 4/5; esse layout e mais estavel que a codificacao do rotulo.
  address_row <- which(str_detect(table[, 1], regex("^complemento", ignore_case = TRUE)))
  municipality_full <- if (length(address_row) > 0L && address_row[[1]] < nrow(table) && ncol(table) >= 5L) {
    clean_text(table[address_row[[1]] + 1L, 4L])
  } else {
    NA_character_
  }
  municipality <- str_trim(str_remove(municipality_full, " - IBGE - [0-9]+$"))
  ibge_code <- str_match(municipality_full, "IBGE - ([0-9]{6,7})")[, 2]
  type <- value_below("^tipo estabelecimento")
  subtype <- value_below("^sub ?tipo estabelecimento")
  dependency <- value_below("^depend")

  data.frame(
    municipio_cnes = ifelse(is.na(municipality_full), NA_character_, municipality),
    codigo_ibge_cnes = ibge_code,
    uf_cnes = if (length(address_row) > 0L && address_row[[1]] < nrow(table) && ncol(table) >= 5L) clean_text(table[address_row[[1]] + 1L, 5L]) else NA_character_,
    tipo_estabelecimento_cnes = type,
    subtipo_estabelecimento_cnes = subtype,
    dependencia_cnes = dependency,
    stringsAsFactors = FALSE
  )
}

collapse_values <- function(x) {
  values <- sort(unique(trimws(na.omit(as.character(x)))))
  values <- values[nzchar(values)]
  if (length(values) == 0L) NA_character_ else paste(values, collapse = " | ")
}

universe <- readRDS(universe_path) |>
  arrange(cnpj_raiz_8) |>
  mutate(
    municipio_ancora_administrativa = municipio_sede_canonico,
    uf_ancora_administrativa = uf_sede_canonica
  )

query_map <- bind_rows(lapply(seq_len(nrow(universe)), function(i) {
  cnpjs <- split_cnpjs(universe$cnpjs_estabelecimentos[[i]])
  data.frame(
    cnpj_raiz_8 = universe$cnpj_raiz_8[[i]],
    cnpj_canonico = universe$cnpj_canonico[[i]],
    cnpj_consultado = cnpjs,
    stringsAsFactors = FALSE
  )
})) |>
  distinct()

stable_consultas <- file.path(out_dir, "consultas_cnes_polo_saude_mg.csv")
stable_consultas_cnpj_proprio <- file.path(out_dir, "consultas_cnes_cnpj_proprio_saude_mg.csv")
stable_units <- file.path(out_dir, "unidades_cnes_vinculadas_saude_mg.csv")
stable_polos <- file.path(out_dir, "polos_atracao_saude_mg.csv")
refresh_cnes <- identical(Sys.getenv("REFRESH_CNES"), "1")
use_cached_listings <- !refresh_cnes && file.exists(stable_consultas) && file.exists(stable_units)

if (use_cached_listings) {
  consultas <- read.csv(
    stable_consultas,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8",
    colClasses = c(cnpj_raiz_8 = "character", cnpj_canonico = "character", cnpj_consultado = "character")
  )
  cached_units <- read.csv(
    stable_units,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8",
    colClasses = c(cnpj_raiz_8 = "character", cnpj_canonico = "character", cnpj_consultado = "character", co_unidade = "character", cnes = "character")
  )
  cache_is_current <- nrow(consultas) == nrow(query_map) &&
    all(query_map$cnpj_consultado %in% consultas$cnpj_consultado) &&
    all(consultas$data_extracao == snapshot_date)

  if (cache_is_current) {
    if (!"fonte_listagem_cnes" %in% names(cached_units)) {
      cached_units$fonte_listagem_cnes <- "cnpj_mantenedora"
    }
    units_listed <- cached_units |>
      select(
        cnpj_raiz_8, cnpj_canonico, cnpj_consultado, co_unidade, cnes,
        nome_estabelecimento_cnes, url_ficha_cnes, fonte_listagem_cnes
      ) |>
      distinct(cnpj_raiz_8, co_unidade, .keep_all = TRUE)
  } else {
    use_cached_listings <- FALSE
  }
}

if (!use_cached_listings) {
  listing_rows <- vector("list", nrow(query_map))
  unit_rows <- list()
  unit_position <- 0L

  for (i in seq_len(nrow(query_map))) {
    cnpj <- query_map$cnpj_consultado[[i]]
    url <- paste0(source_base, "/Listar_Mantidas.asp?VCnpj=", cnpj, "&VEstado=31")
    response <- fetch_cnes(url)

    if (!response$ok) {
      listing_rows[[i]] <- data.frame(
      cnpj_raiz_8 = query_map$cnpj_raiz_8[[i]],
      cnpj_canonico = query_map$cnpj_canonico[[i]],
      cnpj_consultado = cnpj,
      status_consulta_cnes = "erro_consulta",
      n_unidades_listadas = NA_integer_,
      url_consulta_cnes = url,
      erro_consulta = response$error,
      data_extracao = snapshot_date,
      stringsAsFactors = FALSE
    )
    } else {
      listed <- parse_listing(response$content)
      listing_rows[[i]] <- data.frame(
      cnpj_raiz_8 = query_map$cnpj_raiz_8[[i]],
      cnpj_canonico = query_map$cnpj_canonico[[i]],
      cnpj_consultado = cnpj,
      status_consulta_cnes = if (nrow(listed) == 0L) "sem_unidade_listada" else "unidades_listadas",
      n_unidades_listadas = nrow(listed),
      url_consulta_cnes = url,
      erro_consulta = NA_character_,
      data_extracao = snapshot_date,
      stringsAsFactors = FALSE
    )

      if (nrow(listed) > 0L) {
        for (j in seq_len(nrow(listed))) {
          unit_position <- unit_position + 1L
          unit_rows[[unit_position]] <- cbind(
            query_map[i, ],
            listed[j, ],
            url_ficha_cnes = paste0(source_base, "/Exibe_Ficha_Estabelecimento.asp?VCo_Unidade=", listed$co_unidade[[j]]),
            stringsAsFactors = FALSE
          )
        }
      }
    }

    Sys.sleep(0.2)
  }

  consultas <- bind_rows(listing_rows)
  units_listed <- bind_rows(unit_rows) |>
    mutate(fonte_listagem_cnes = "cnpj_mantenedora") |>
    distinct(cnpj_raiz_8, co_unidade, .keep_all = TRUE)
}

# A listagem legada acima pesquisa unidades mantidas pelo CNPJ. O portal atual
# do CNES tambem permite pesquisar o CNPJ proprio do estabelecimento. As duas
# relacoes nao sao equivalentes; manter ambas evita falsos negativos sem
# inferir vinculos por nome ou proximidade geografica.
own_listing_rows <- vector("list", nrow(query_map))
own_unit_rows <- list()
own_unit_position <- 0L

for (i in seq_len(nrow(query_map))) {
  cnpj <- query_map$cnpj_consultado[[i]]
  url <- paste0(
    "https://cnes.datasus.gov.br/services/estabelecimentos?cnpj=",
    cnpj,
    "&estado=31"
  )
  response <- fetch_cnes(
    url,
    referer = "https://cnes.datasus.gov.br/pages/estabelecimentos/consulta.jsp"
  )

  if (!response$ok) {
    own_listing_rows[[i]] <- data.frame(
      cnpj_raiz_8 = query_map$cnpj_raiz_8[[i]],
      cnpj_canonico = query_map$cnpj_canonico[[i]],
      cnpj_consultado = cnpj,
      status_consulta_cnes = "erro_consulta",
      n_unidades_listadas = NA_integer_,
      url_consulta_cnes = url,
      erro_consulta = response$error,
      data_extracao = snapshot_date,
      stringsAsFactors = FALSE
    )
    next
  }

  parse_error <- NA_character_
  listed <- tryCatch(
    parse_json_listing(response$content),
    error = function(e) {
      parse_error <<- conditionMessage(e)
      data.frame(
        co_unidade = character(), cnes = character(),
        nome_estabelecimento_cnes = character(), stringsAsFactors = FALSE
      )
    }
  )
  own_listing_rows[[i]] <- data.frame(
    cnpj_raiz_8 = query_map$cnpj_raiz_8[[i]],
    cnpj_canonico = query_map$cnpj_canonico[[i]],
    cnpj_consultado = cnpj,
    status_consulta_cnes = if (!is.na(parse_error)) "erro_resposta" else if (nrow(listed) == 0L) "sem_unidade_listada" else "unidades_listadas",
    n_unidades_listadas = nrow(listed),
    url_consulta_cnes = url,
    erro_consulta = parse_error,
    data_extracao = snapshot_date,
    stringsAsFactors = FALSE
  )

  if (nrow(listed) > 0L) {
    for (j in seq_len(nrow(listed))) {
      own_unit_position <- own_unit_position + 1L
      own_unit_rows[[own_unit_position]] <- cbind(
        query_map[i, ],
        listed[j, ],
        url_ficha_cnes = paste0(source_base, "/Exibe_Ficha_Estabelecimento.asp?VCo_Unidade=", listed$co_unidade[[j]]),
        fonte_listagem_cnes = "cnpj_proprio",
        stringsAsFactors = FALSE
      )
    }
  }
  Sys.sleep(0.1)
}

consultas_cnpj_proprio <- bind_rows(own_listing_rows)
units_listed <- bind_rows(units_listed, bind_rows(own_unit_rows)) |>
  arrange(cnpj_raiz_8, co_unidade, desc(fonte_listagem_cnes == "cnpj_proprio")) |>
  distinct(cnpj_raiz_8, co_unidade, .keep_all = TRUE)

# A ficha detalhada e necessaria somente para entidades com uma unidade. Redes
# ficam preservadas como redes neste passo; abrir cada ficha delas nao melhora
# a decisao de polo unico e aumenta muito a coleta sem necessidade analitica.
single_unit_roots <- units_listed |>
  count(cnpj_raiz_8, name = "n_unidades") |>
  filter(n_unidades == 1L) |>
  pull(cnpj_raiz_8)

detail_rows <- vector("list", nrow(units_listed))
for (i in seq_len(nrow(units_listed))) {
  should_fetch_detail <- units_listed$cnpj_raiz_8[[i]] %in% single_unit_roots
  if (!should_fetch_detail) {
    detail_rows[[i]] <- cbind(
      units_listed[i, ],
      municipio_cnes = NA_character_, codigo_ibge_cnes = NA_character_, uf_cnes = NA_character_,
      tipo_estabelecimento_cnes = NA_character_, subtipo_estabelecimento_cnes = NA_character_,
      dependencia_cnes = NA_character_, status_ficha_cnes = "nao_consultada_rede",
      erro_ficha_cnes = NA_character_, data_extracao = snapshot_date,
      stringsAsFactors = FALSE
    )
    next
  }

  response <- fetch_cnes(units_listed$url_ficha_cnes[[i]])
  detail <- if (response$ok) {
    parse_detail(response$content)
  } else {
    data.frame(
      municipio_cnes = NA_character_, codigo_ibge_cnes = NA_character_, uf_cnes = NA_character_,
      tipo_estabelecimento_cnes = NA_character_, subtipo_estabelecimento_cnes = NA_character_,
      dependencia_cnes = NA_character_, stringsAsFactors = FALSE
    )
  }
  detail_status <- if (!response$ok) {
    "erro_consulta"
  } else if (!is.na(detail$municipio_cnes[[1]]) && nzchar(detail$municipio_cnes[[1]])) {
    "ok"
  } else {
    "ficha_sem_dados"
  }
  detail_rows[[i]] <- cbind(
    units_listed[i, ],
    detail,
    status_ficha_cnes = detail_status,
    erro_ficha_cnes = response$error,
    data_extracao = snapshot_date,
    stringsAsFactors = FALSE
  )
  Sys.sleep(0.2)
}

units <- bind_rows(detail_rows) |>
  mutate(
    fonte_vinculo = if_else(
      fonte_listagem_cnes == "cnpj_proprio",
      "CNES: CNPJ proprio do estabelecimento coincide com CNPJ do consorcio",
      "CNES: estabelecimento listado sob CNPJ da mantenedora"
    ),
    vinculo_cnpj_mantenedora_direto = fonte_listagem_cnes == "cnpj_mantenedora",
    vinculo_cnpj_proprio_direto = fonte_listagem_cnes == "cnpj_proprio",
    ficha_cnes_completa = status_ficha_cnes == "ok" & !is.na(municipio_cnes) & nzchar(municipio_cnes),
    unidade_movel_ou_itinerante = str_detect(
      nome_estabelecimento_cnes,
      regex("vaci ?movel|unidade movel|motolancia|ambulancia", ignore_case = TRUE)
    ),
    unidade_hospitalar = !is.na(tipo_estabelecimento_cnes) & str_detect(tipo_estabelecimento_cnes, regex("hospital", ignore_case = TRUE))
  )

entity_cnes <- consultas |>
  group_by(cnpj_raiz_8, cnpj_canonico) |>
  summarise(
    n_cnpjs_consultados_cnes = n(),
    n_consultas_cnes_ok = sum(status_consulta_cnes != "erro_consulta"),
    n_erros_consulta_cnes = sum(status_consulta_cnes == "erro_consulta"),
    .groups = "drop"
  ) |>
  left_join(
    units |>
      group_by(cnpj_raiz_8, cnpj_canonico) |>
      summarise(
        n_unidades_cnes_vinculadas = n(),
        n_municipios_unidades_com_ficha_cnes = n_distinct(municipio_cnes[!is.na(municipio_cnes)]),
        n_unidades_hospitalares_cnes = sum(unidade_hospitalar, na.rm = TRUE),
        n_unidades_moveis_ou_itinerantes = sum(unidade_movel_ou_itinerante, na.rm = TRUE),
        n_fichas_cnes_completas = sum(ficha_cnes_completa),
        cnes_unidades_vinculadas = collapse_values(cnes),
        nomes_unidades_cnes = collapse_values(nome_estabelecimento_cnes),
        municipios_unidades_com_ficha_cnes = collapse_values(municipio_cnes),
        tipos_unidades_com_ficha_cnes = collapse_values(tipo_estabelecimento_cnes),
        .groups = "drop"
      ),
    by = c("cnpj_raiz_8", "cnpj_canonico")
  ) |>
  mutate(
    n_cnpjs_consultados_cnes = coalesce(n_cnpjs_consultados_cnes, 0L),
    n_consultas_cnes_ok = coalesce(n_consultas_cnes_ok, 0L),
    n_erros_consulta_cnes = coalesce(n_erros_consulta_cnes, 0L),
    n_unidades_cnes_vinculadas = coalesce(n_unidades_cnes_vinculadas, 0L),
    n_municipios_unidades_com_ficha_cnes = coalesce(n_municipios_unidades_com_ficha_cnes, 0L),
    n_unidades_hospitalares_cnes = coalesce(n_unidades_hospitalares_cnes, 0L),
    n_unidades_moveis_ou_itinerantes = coalesce(n_unidades_moveis_ou_itinerantes, 0L),
    n_fichas_cnes_completas = coalesce(n_fichas_cnes_completas, 0L),
    classificacao_evidencia_polo = case_when(
      n_cnpjs_consultados_cnes == 0L ~ "sem_cnpj_consultavel",
      n_erros_consulta_cnes > 0L ~ "consulta_cnes_incompleta",
      n_unidades_cnes_vinculadas == 0L ~ "sem_unidade_cnes_vinculada_pelo_cnpj",
      n_unidades_cnes_vinculadas == 1L & n_fichas_cnes_completas == 1L & n_unidades_moveis_ou_itinerantes == 1L ~ "unidade_cnes_unica_movel",
      n_unidades_cnes_vinculadas == 1L & n_fichas_cnes_completas == 1L ~ "unidade_cnes_unica_vinculada",
      n_unidades_cnes_vinculadas == 1L ~ "unidade_cnes_unica_sem_ficha_detalhada",
      TRUE ~ "rede_cnes_vinculada"
    )
  )

single_unit <- units |>
  group_by(cnpj_raiz_8, cnpj_canonico) |>
  filter(n() == 1L, ficha_cnes_completa, !unidade_movel_ou_itinerante) |>
  ungroup() |>
  select(
    cnpj_raiz_8, cnpj_canonico,
    cnes_polo_assistencial = cnes,
    nome_polo_assistencial = nome_estabelecimento_cnes,
    municipio_polo_assistencial = municipio_cnes,
    codigo_ibge_polo_assistencial = codigo_ibge_cnes,
    uf_polo_assistencial = uf_cnes,
    tipo_polo_assistencial = tipo_estabelecimento_cnes,
    url_ficha_polo_assistencial = url_ficha_cnes
  )

polos <- universe |>
  select(
    cnpj_raiz_8, cnpj_canonico, razao_social_canonica, sigla_canonica,
    situacao_matriz, escopo_saude, aparece_mides_mg,
    incluir_modelo_principal_preliminar, incluir_sensibilidade_multiarea,
    municipio_ancora_administrativa, uf_ancora_administrativa
  ) |>
  left_join(entity_cnes, by = c("cnpj_raiz_8", "cnpj_canonico")) |>
  left_join(single_unit, by = c("cnpj_raiz_8", "cnpj_canonico")) |>
  mutate(
    decisao_polo_atracao = case_when(
      classificacao_evidencia_polo == "unidade_cnes_unica_vinculada" & !is.na(municipio_polo_assistencial) ~
        "estabelecimento_cnes_unico",
      classificacao_evidencia_polo == "rede_cnes_vinculada" ~
        "rede_vinculada_sem_polo_unico",
      classificacao_evidencia_polo == "sem_unidade_cnes_vinculada_pelo_cnpj" ~
        "sede_administrativa_apenas_ancora_sensibilidade",
      classificacao_evidencia_polo == "unidade_cnes_unica_sem_ficha_detalhada" ~
        "pendente_ficha_cnes",
      classificacao_evidencia_polo == "unidade_cnes_unica_movel" ~
        "unidade_movel_sem_polo_fixo",
      classificacao_evidencia_polo == "sem_cnpj_consultavel" ~
        "pendente_cnpj_consultavel",
      TRUE ~ "pendente_por_consulta_incompleta"
    ),
    ancora_sede_uso = "somente_sensibilidade_geografica; nao representa capacidade assistencial",
    elegivel_capacidade_direta_passo_5 = decisao_polo_atracao == "estabelecimento_cnes_unico",
    precisa_revisao_documental_polo = decisao_polo_atracao %in% c(
      "rede_vinculada_sem_polo_unico",
      "sede_administrativa_apenas_ancora_sensibilidade",
      "pendente_ficha_cnes",
      "unidade_movel_sem_polo_fixo",
      "pendente_cnpj_consultavel",
      "pendente_por_consulta_incompleta"
    ),
    proxima_acao = case_when(
      decisao_polo_atracao == "estabelecimento_cnes_unico" ~
        "Extrair capacidade CNES desta unidade no passo 4.",
      decisao_polo_atracao == "rede_vinculada_sem_polo_unico" ~
        "Manter unidades separadas; decidir agregacao da rede somente com vinculo e regra explicitos.",
      decisao_polo_atracao == "sede_administrativa_apenas_ancora_sensibilidade" ~
        "Buscar documento que vincule hospital, clinica ou rede ao consorcio; nao atribuir capacidade por proximidade.",
      decisao_polo_atracao == "pendente_ficha_cnes" ~
        "Repetir ou consultar manualmente a ficha CNES antes de adotar a unidade como polo.",
      decisao_polo_atracao == "unidade_movel_sem_polo_fixo" ~
        "Nao usar como destino rodoviario fixo; definir exposicao propria para servico movel ou manter fora do modelo principal.",
      decisao_polo_atracao == "pendente_cnpj_consultavel" ~
        "Revisar o CNPJ de matriz/filial no crosswalk antes da consulta CNES.",
      TRUE ~ "Reexecutar a consulta CNES e revisar o retorno antes de qualquer uso analitico."
    ),
    fonte_principal_polo = "CNES/DATASUS, consulta de estabelecimentos mantidos pelo CNPJ",
    data_extracao_cnes = snapshot_date
  ) |>
  arrange(cnpj_raiz_8)

write.csv(consultas, stable_consultas, row.names = FALSE, fileEncoding = "UTF-8")
write.csv(consultas_cnpj_proprio, stable_consultas_cnpj_proprio, row.names = FALSE, fileEncoding = "UTF-8")
write.csv(units, stable_units, row.names = FALSE, fileEncoding = "UTF-8")
write.csv(polos, stable_polos, row.names = FALSE, fileEncoding = "UTF-8")
write.csv(consultas, file.path(out_dir, paste0("consultas_cnes_polo_saude_mg_", snapshot_tag, ".csv")), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(consultas_cnpj_proprio, file.path(out_dir, paste0("consultas_cnes_cnpj_proprio_saude_mg_", snapshot_tag, ".csv")), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(units, file.path(out_dir, paste0("unidades_cnes_vinculadas_saude_mg_", snapshot_tag, ".csv")), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(polos, file.path(out_dir, paste0("polos_atracao_saude_mg_", snapshot_tag, ".csv")), row.names = FALSE, fileEncoding = "UTF-8")
saveRDS(polos, file.path(out_dir, "polos_atracao_saude_mg.rds"))

summary_counts <- polos |>
  count(decisao_polo_atracao, name = "entidades") |>
  arrange(decisao_polo_atracao)

check_lines <- c(
  "# Validacao: Definicao Do Polo De Atracao Em Saude (MG)",
  "",
  paste0("- Data da extracao CNES: `", snapshot_date, "`."),
  paste0("- Entidades consolidadas avaliadas: **", nrow(polos), "**."),
  paste0("- CNPJs de matriz/filial consultados: **", nrow(query_map), "**."),
  paste0("- Consultas CNES com erro: **", sum(consultas$status_consulta_cnes == "erro_consulta"), "**."),
  paste0("- Unidades CNES diretamente vinculadas ao CNPJ consultado: **", nrow(units), "**."),
  paste0("- Unidades classificadas como hospitalares pelo tipo CNES entre fichas de polos unicos: **", sum(units$unidade_hospitalar, na.rm = TRUE), "**."),
  "",
  "## Resultado Da Regra",
  "",
  "| Decisao | Entidades |",
  "|---|---:|",
  vapply(seq_len(nrow(summary_counts)), function(i) {
    paste0("| ", summary_counts$decisao_polo_atracao[[i]], " | ", summary_counts$entidades[[i]], " |")
  }, character(1)),
  "",
  "## Regra De Interpretacao",
  "",
  "- `estabelecimento_cnes_unico`: pode usar a localizacao desse estabelecimento como polo assistencial no proximo passo.",
  "- `rede_vinculada_sem_polo_unico`: o CNES confirma vinculo, mas a rede nao pode ser comprimida em uma unica sede sem regra de agregacao.",
  "- `unidade_movel_sem_polo_fixo`: uma unidade movel e vinculada, mas seu endereco nao e interpretado como destino assistencial fixo.",
  "- `sede_administrativa_apenas_ancora_sensibilidade`: nao houve unidade CNES listada sob os CNPJs consultados; isso nao prova ausencia de servico conveniado. A sede entra apenas em analise de sensibilidade geografica.",
  "- O relatorio nao infere hospital, especialidade, leitos ou unidade vinculada quando o CNES nao fornece esse vinculo cadastral direto."
)
writeLines(check_lines, file.path(check_dir, "VALIDACAO_POLOS_ATRACAO_SAUDE_MG.md"), useBytes = TRUE)

message("Passo 3 concluido: ", nrow(polos), " entidades; ", nrow(units), " unidades CNES diretamente vinculadas.")
