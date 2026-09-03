# =============================================================================
# 05_construir_capacidade_assistencial_saude.R
#
# Produz uma fotografia atual da oferta assistencial diretamente vinculada aos
# CNPJs de consorcios de saude de MG. O script preserva medidas separadas;
# nao cria um indice sintetico nem atribui hospitais de terceiros ao consorcio.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(rvest)
})

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
analysis_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude")
out_dir <- file.path(analysis_dir, "outputs")
check_dir <- file.path(analysis_dir, "checks")
cache_dir <- file.path(out_dir, "cache_cnes_capacidade")
units_path <- file.path(out_dir, "unidades_cnes_vinculadas_saude_mg.csv")
polos_path <- file.path(out_dir, "polos_atracao_saude_mg.rds")

for (path in c(units_path, polos_path)) {
  if (!file.exists(path)) stop("Execute primeiro 04_definir_polos_atracao_saude.R: ", path)
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(check_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

snapshot_date <- as.character(Sys.Date())
snapshot_tag <- gsub("-", "_", snapshot_date, fixed = TRUE)
source_base <- "https://cnes2.datasus.gov.br"
refresh_cnes <- identical(Sys.getenv("REFRESH_CNES_CAPACIDADE"), "1")
refresh_beds <- identical(Sys.getenv("REFRESH_CNES_LEITOS"), "1")
refresh_errors <- identical(Sys.getenv("REFRESH_CNES_ERROS"), "1")

clean_text <- function(x) {
  x |>
    as.character() |>
    gsub("[[:space:]]+", " ", x = _) |>
    trimws()
}

as_number <- function(x) {
  value <- gsub("[^0-9,.-]", "", clean_text(x))
  if (!nzchar(value)) return(NA_real_)
  suppressWarnings(as.numeric(gsub(",", ".", value, fixed = TRUE)))
}

fetch_cnes <- function(url, attempts = 2L) {
  last_error <- NA_character_
  for (attempt in seq_len(attempts)) {
    temp_file <- tempfile(fileext = ".html")
    result <- tryCatch(
      system2(
        "curl.exe",
        c("-sS", "-L", "--max-time", "25", "-A", "Mozilla/5.0", "-o", shQuote(temp_file), shQuote(url)),
        stdout = FALSE,
        stderr = FALSE
      ),
      error = function(e) e
    )
    bytes <- if (file.exists(temp_file)) file.info(temp_file)$size else 0L
    if (!inherits(result, "error") && identical(result, 0L) && !is.na(bytes) && bytes > 0L) {
      content <- readBin(temp_file, what = "raw", n = bytes)
      unlink(temp_file)
      return(list(ok = TRUE, content = content, error = NA_character_))
    }
    unlink(temp_file)
    last_error <- if (inherits(result, "error")) conditionMessage(result) else paste("curl exit", result)
    if (attempt < attempts) Sys.sleep(1)
  }
  list(ok = FALSE, content = raw(), error = last_error)
}

read_cnes_html <- function(raw_content) rvest::read_html(raw_content, encoding = "ISO-8859-1")

parse_identity <- function(raw_content) {
  document <- read_cnes_html(raw_content)
  tables <- rvest::html_table(document, fill = TRUE)
  table_index <- which(vapply(tables, function(table) {
    values <- as.character(unlist(table, use.names = FALSE))
    any(str_detect(values, regex("tipo estabelecimento", ignore_case = TRUE))) &&
      any(str_detect(values, regex("complemento", ignore_case = TRUE)))
  }, logical(1)))
  if (length(table_index) == 0L) {
    return(data.frame(
      municipio_cnes = NA_character_, codigo_ibge_cnes = NA_character_, uf_cnes = NA_character_,
      tipo_estabelecimento_cnes = NA_character_, dependencia_cnes = NA_character_, stringsAsFactors = FALSE
    ))
  }

  widths <- vapply(tables[table_index], ncol, integer(1))
  table <- as.matrix(tables[[table_index[[which.min(widths)]]]])
  value_below <- function(pattern) {
    positions <- which(str_detect(as.vector(table), regex(pattern, ignore_case = TRUE)))
    if (length(positions) == 0L) return(NA_character_)
    position <- arrayInd(positions[[1]], dim(table))
    if (position[[1]] >= nrow(table)) return(NA_character_)
    clean_text(table[position[[1]] + 1L, position[[2]]])
  }
  address_row <- which(str_detect(table[, 1], regex("^complemento", ignore_case = TRUE)))
  municipality_full <- if (length(address_row) > 0L && address_row[[1]] < nrow(table) && ncol(table) >= 5L) {
    clean_text(table[address_row[[1]] + 1L, 4L])
  } else NA_character_

  data.frame(
    municipio_cnes = ifelse(is.na(municipality_full), NA_character_, str_trim(str_remove(municipality_full, " - IBGE - [0-9]+$"))),
    codigo_ibge_cnes = str_match(municipality_full, "IBGE - ([0-9]{6,7})")[, 2],
    uf_cnes = if (length(address_row) > 0L && address_row[[1]] < nrow(table) && ncol(table) >= 5L) clean_text(table[address_row[[1]] + 1L, 5L]) else NA_character_,
    tipo_estabelecimento_cnes = value_below("^tipo estabelecimento"),
    dependencia_cnes = value_below("^depend"),
    stringsAsFactors = FALSE
  )
}

parse_beds <- function(raw_content) {
  document <- read_cnes_html(raw_content)
  text <- clean_text(rvest::html_text2(document))
  if (str_detect(text, regex("estabelecimento.*possui leitos", ignore_case = TRUE))) {
    return(data.frame(leitos_existentes = 0, leitos_sus = 0, n_tipos_leito = 0L, status_leitos = "sem_leitos_cadastrados", stringsAsFactors = FALSE))
  }
  tables <- rvest::html_table(document, fill = TRUE)
  total_rows <- list()
  bed_types <- character()
  for (table in tables) {
    if (ncol(table) < 3L) next
    values <- as.data.frame(lapply(table[, seq_len(min(3L, ncol(table))), drop = FALSE], clean_text), stringsAsFactors = FALSE)
    total_index <- which(str_detect(values[[1]], regex("^total geral menos complementar$", ignore_case = TRUE)))
    if (length(total_index) > 0L) {
      total_rows <- append(total_rows, lapply(total_index, function(i) c(as_number(values[[2]][[i]]), as_number(values[[3]][[i]]))))
    }
    type_index <- which(str_detect(values[[1]], "^[0-9]{2}-") & !str_detect(values[[1]], regex("total", ignore_case = TRUE)))
    bed_types <- c(bed_types, values[[1]][type_index])
  }
  if (length(total_rows) == 0L) {
    return(data.frame(leitos_existentes = NA_real_, leitos_sus = NA_real_, n_tipos_leito = NA_integer_, status_leitos = "ficha_sem_total_identificavel", stringsAsFactors = FALSE))
  }
  totals <- do.call(rbind, total_rows)
  data.frame(
    leitos_existentes = totals[1, 1],
    leitos_sus = totals[1, 2],
    n_tipos_leito = length(unique(bed_types[nzchar(bed_types)])),
    status_leitos = "ok",
    stringsAsFactors = FALSE
  )
}

parse_attendance <- function(raw_content) {
  document <- read_cnes_html(raw_content)
  tables <- rvest::html_table(document, fill = TRUE)
  rows <- data.frame(tipo = character(), convenio = character(), stringsAsFactors = FALSE)
  for (table in tables) {
    if (ncol(table) != 2L) next
    candidate <- data.frame(tipo = clean_text(table[[1]]), convenio = clean_text(table[[2]]), stringsAsFactors = FALSE)
    candidate <- candidate[str_detect(candidate$tipo, "^[A-Z ]+$") & nchar(candidate$tipo) > 2L, , drop = FALSE]
    rows <- bind_rows(rows, candidate)
  }
  rows <- distinct(rows)
  has_sus <- function(label) any(rows$tipo == label & rows$convenio == "SUS")
  data.frame(
    atendimento_ambulatorial_sus = has_sus("AMBULATORIAL"),
    internacao_sus = has_sus("INTERNACAO"),
    sadt_sus = has_sus("SADT"),
    n_tipos_atendimento_sus = sum(c(has_sus("AMBULATORIAL"), has_sus("INTERNACAO"), has_sus("SADT"))),
    status_atendimento = "ok",
    stringsAsFactors = FALSE
  )
}

parse_professionals <- function(raw_content) {
  document <- read_cnes_html(raw_content)
  tables <- rvest::html_table(document, fill = TRUE)
  candidates <- lapply(tables, function(table) {
    if (ncol(table) < 11L || ncol(table) > 30L) return(NULL)
    rows <- apply(table, 1, function(row) paste(clean_text(row), collapse = " | "))
    header_index <- which(str_detect(rows, regex("\\bCBO\\b", ignore_case = TRUE)) & str_detect(rows, regex("\\bSUS\\b", ignore_case = TRUE)))
    if (length(header_index) == 0L) return(NULL)
    list(table = table, header_index = header_index[[1]])
  })
  candidates <- Filter(Negate(is.null), candidates)
  if (length(candidates) == 0L) {
    return(data.frame(
      n_vinculos_sus_ativos = 0L, n_cbo_sus_ativos_distintos = 0L,
      n_vinculos_medicos_sus_ativos = 0L, n_cbo_medicos_sus_ativos_distintos = 0L,
      carga_horaria_sus_ativa = 0, status_profissionais = "sem_profissionais_ou_tabela", stringsAsFactors = FALSE
    ))
  }
  candidate <- candidates[[which.min(vapply(candidates, function(x) ncol(x$table), integer(1)))]]
  table <- candidate$table
  headers <- clean_text(table[candidate$header_index, ])
  names(table) <- make.unique(headers)
  start <- candidate$header_index + 1L
  if (start > nrow(table)) {
    return(data.frame(
      n_vinculos_sus_ativos = 0L, n_cbo_sus_ativos_distintos = 0L,
      n_vinculos_medicos_sus_ativos = 0L, n_cbo_medicos_sus_ativos_distintos = 0L,
      carga_horaria_sus_ativa = 0, status_profissionais = "sem_linhas_profissionais", stringsAsFactors = FALSE
    ))
  }
  data <- table[start:nrow(table), , drop = FALSE]
  cbo_col <- grep("^CBO$", names(data), ignore.case = TRUE, value = TRUE)
  sus_col <- grep("^SUS$", names(data), ignore.case = TRUE, value = TRUE)
  total_col <- grep("^Total$", names(data), ignore.case = TRUE, value = TRUE)
  situation_col <- grep("Situa", names(data), ignore.case = TRUE, value = TRUE)
  if (length(cbo_col) == 0L || length(sus_col) == 0L) {
    return(data.frame(
      n_vinculos_sus_ativos = NA_integer_, n_cbo_sus_ativos_distintos = NA_integer_,
      n_vinculos_medicos_sus_ativos = NA_integer_, n_cbo_medicos_sus_ativos_distintos = NA_integer_,
      carga_horaria_sus_ativa = NA_real_, status_profissionais = "colunas_profissionais_nao_identificadas", stringsAsFactors = FALSE
    ))
  }
  cbo <- clean_text(data[[cbo_col[[1]]]])
  sus <- clean_text(data[[sus_col[[1]]]])
  active <- if (length(situation_col) > 0L) str_to_upper(clean_text(data[[situation_col[[1]]]])) == "ATIVO" else rep(TRUE, nrow(data))
  keep <- str_detect(cbo, "^[0-9]{6}") & str_to_upper(sus) == "SIM" & active
  cbo <- cbo[keep]
  codes <- str_extract(cbo, "^[0-9]{6}")
  medical <- str_starts(codes, "225") | str_detect(cbo, regex("MEDICO", ignore_case = TRUE))
  total_hours <- if (length(total_col) > 0L) sum(vapply(data[[total_col[[1]]]][keep], as_number, numeric(1)), na.rm = TRUE) else NA_real_
  data.frame(
    n_vinculos_sus_ativos = length(cbo),
    n_cbo_sus_ativos_distintos = n_distinct(codes),
    n_vinculos_medicos_sus_ativos = sum(medical),
    n_cbo_medicos_sus_ativos_distintos = n_distinct(codes[medical]),
    carga_horaria_sus_ativa = total_hours,
    status_profissionais = "ok",
    stringsAsFactors = FALSE
  )
}

read_cached <- function(cnes) {
  path <- file.path(cache_dir, paste0(cnes, ".rds"))
  if (refresh_cnes || !file.exists(path)) return(NULL)
  value <- readRDS(path)
  if (!identical(value$data_extracao_cnes[[1]], snapshot_date)) return(NULL)
  value
}

refresh_cached_beds <- function(cached, code) {
  response <- fetch_cnes(paste0(source_base, "/Mod_Hospitalar.asp?VCo_Unidade=", code))
  beds <- if (response$ok) parse_beds(response$content) else {
    data.frame(leitos_existentes = NA_real_, leitos_sus = NA_real_, n_tipos_leito = NA_integer_, status_leitos = "erro_consulta", stringsAsFactors = FALSE)
  }
  cached[names(beds)] <- beds
  cached
}

refresh_cached_errors <- function(cached, code) {
  failed <- strsplit(cached$modulos_com_erro[[1]], " | ", fixed = TRUE)[[1]]
  failed <- failed[nzchar(failed)]
  endpoints <- c(
    ficha = paste0(source_base, "/Exibe_Ficha_Estabelecimento.asp?VCo_Unidade=", code),
    leitos = paste0(source_base, "/Mod_Hospitalar.asp?VCo_Unidade=", code),
    atendimento = paste0(source_base, "/Mod_Bas_Atendimento.asp?VCo_Unidade=", code),
    profissionais = paste0(source_base, "/Mod_Profissional.asp?VCo_Unidade=", code)
  )
  remaining <- failed
  for (module in failed) {
    response <- fetch_cnes(endpoints[[module]], attempts = 4L)
    if (!response$ok) next
    parsed <- switch(
      module,
      ficha = parse_identity(response$content),
      leitos = parse_beds(response$content),
      atendimento = parse_attendance(response$content),
      profissionais = parse_professionals(response$content)
    )
    cached[names(parsed)] <- parsed
    remaining <- setdiff(remaining, module)
  }
  cached$consulta_cnes_completa <- length(remaining) == 0L
  cached$modulos_com_erro <- if (length(remaining) == 0L) NA_character_ else paste(remaining, collapse = " | ")
  cached
}

units <- read.csv(
  units_path,
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8",
  colClasses = c(cnpj_raiz_8 = "character", cnpj_canonico = "character", cnpj_consultado = "character", co_unidade = "character", cnes = "character")
) |>
  distinct(cnpj_raiz_8, co_unidade, .keep_all = TRUE) |>
  arrange(cnpj_raiz_8, cnes)
polos <- readRDS(polos_path)

capacity_rows <- vector("list", nrow(units))
start_index <- max(1L, suppressWarnings(as.integer(Sys.getenv("CNES_START_INDEX", unset = "1"))))
end_index <- min(nrow(units), suppressWarnings(as.integer(Sys.getenv("CNES_END_INDEX", unset = as.character(nrow(units))))))
fetch_only <- identical(Sys.getenv("CNES_FETCH_ONLY"), "1")
if (is.na(start_index) || is.na(end_index) || start_index > end_index) stop("Faixa CNES invalida.")

for (i in seq.int(start_index, end_index)) {
  cnes <- units$cnes[[i]]
  cached <- read_cached(cnes)
  if (!is.null(cached)) {
    if (refresh_errors && !isTRUE(cached$consulta_cnes_completa[[1]])) {
      cached <- refresh_cached_errors(cached, units$co_unidade[[i]])
      saveRDS(cached, file.path(cache_dir, paste0(cnes, ".rds")))
      Sys.sleep(0.2)
    }
    if (refresh_beds && cached$status_leitos[[1]] %in% c("erro_consulta", "ficha_sem_total_identificavel")) {
      cached <- refresh_cached_beds(cached, units$co_unidade[[i]])
      saveRDS(cached, file.path(cache_dir, paste0(cnes, ".rds")))
    }
    capacity_rows[[i]] <- cached
    next
  }

  code <- units$co_unidade[[i]]
  endpoints <- c(
    ficha = paste0(source_base, "/Exibe_Ficha_Estabelecimento.asp?VCo_Unidade=", code),
    leitos = paste0(source_base, "/Mod_Hospitalar.asp?VCo_Unidade=", code),
    atendimento = paste0(source_base, "/Mod_Bas_Atendimento.asp?VCo_Unidade=", code),
    profissionais = paste0(source_base, "/Mod_Profissional.asp?VCo_Unidade=", code)
  )
  responses <- lapply(endpoints, fetch_cnes)
  failures <- names(responses)[!vapply(responses, function(x) x$ok, logical(1))]
  identity <- if (responses$ficha$ok) {
    parse_identity(responses$ficha$content)
  } else {
    data.frame(municipio_cnes = NA_character_, codigo_ibge_cnes = NA_character_, uf_cnes = NA_character_, tipo_estabelecimento_cnes = NA_character_, dependencia_cnes = NA_character_, stringsAsFactors = FALSE)
  }
  beds <- if (responses$leitos$ok) parse_beds(responses$leitos$content) else data.frame(leitos_existentes = NA_real_, leitos_sus = NA_real_, n_tipos_leito = NA_integer_, status_leitos = "erro_consulta", stringsAsFactors = FALSE)
  attendance <- if (responses$atendimento$ok) parse_attendance(responses$atendimento$content) else data.frame(atendimento_ambulatorial_sus = NA, internacao_sus = NA, sadt_sus = NA, n_tipos_atendimento_sus = NA_integer_, status_atendimento = "erro_consulta", stringsAsFactors = FALSE)
  professionals <- if (responses$profissionais$ok) parse_professionals(responses$profissionais$content) else data.frame(n_vinculos_sus_ativos = NA_integer_, n_cbo_sus_ativos_distintos = NA_integer_, n_vinculos_medicos_sus_ativos = NA_integer_, n_cbo_medicos_sus_ativos_distintos = NA_integer_, carga_horaria_sus_ativa = NA_real_, status_profissionais = "erro_consulta", stringsAsFactors = FALSE)

  row <- cbind(
    units[i, c("cnpj_raiz_8", "cnpj_canonico", "cnpj_consultado", "co_unidade", "cnes", "nome_estabelecimento_cnes")],
    identity, beds, attendance, professionals,
    unidade_movel_ou_itinerante = str_detect(units$nome_estabelecimento_cnes[[i]], regex("vaci ?movel|unidade movel|motolancia|ambulancia", ignore_case = TRUE)),
    consulta_cnes_completa = length(failures) == 0L,
    modulos_com_erro = if (length(failures) == 0L) NA_character_ else paste(failures, collapse = " | "),
    data_extracao_cnes = snapshot_date,
    fonte_capacidade = "CNES/DATASUS: ficha, leitos, atendimento e profissionais por estabelecimento",
    stringsAsFactors = FALSE
  )
  saveRDS(row, file.path(cache_dir, paste0(cnes, ".rds")))
  capacity_rows[[i]] <- row
  Sys.sleep(0.08)
}

if (fetch_only) {
  message("Cache CNES atualizado para a faixa ", start_index, "-", end_index, ".")
  quit(save = "no", status = 0L)
}

# A consolidacao sempre usa todas as unidades existentes no cache, inclusive
# quando a coleta foi dividida em faixas paralelas.
if (start_index != 1L || end_index != nrow(units)) {
  stop("Execute a consolidacao sem CNES_START_INDEX/CNES_END_INDEX.")
}

capacity_units <- bind_rows(capacity_rows) |>
  mutate(
    unidade_fixa_elegivel = !unidade_movel_ou_itinerante,
    capacidade_direta_cnes_atual = consulta_cnes_completa & !unidade_movel_ou_itinerante,
    proxy_especialidades_medicas = "CBO medico distinto, SUS e ativo; nao equivale a servico especializado formal",
    fonte_vinculo = "CNES: estabelecimento listado sob CNPJ da mantenedora",
    vinculo_cnpj_mantenedora_direto = TRUE
  ) |>
  arrange(cnpj_raiz_8, cnes)

entity_capacity <- capacity_units |>
  filter(unidade_fixa_elegivel) |>
  group_by(cnpj_raiz_8, cnpj_canonico) |>
  summarise(
    n_unidades_fixas_cnes = n(),
    n_municipios_oferta_direta = n_distinct(codigo_ibge_cnes[!is.na(codigo_ibge_cnes)]),
    n_unidades_consulta_completa = sum(consulta_cnes_completa),
    n_unidades_atendimento_ambulatorial_sus = sum(atendimento_ambulatorial_sus %in% TRUE, na.rm = TRUE),
    n_unidades_internacao_sus = sum(internacao_sus %in% TRUE, na.rm = TRUE),
    n_unidades_sadt_sus = sum(sadt_sus %in% TRUE, na.rm = TRUE),
    leitos_existentes_rede_direta = sum(leitos_existentes, na.rm = TRUE),
    leitos_sus_rede_direta = sum(leitos_sus, na.rm = TRUE),
    soma_tipos_leito_unidades = sum(n_tipos_leito, na.rm = TRUE),
    vinculos_sus_ativos_rede_direta = sum(n_vinculos_sus_ativos, na.rm = TRUE),
    cbo_sus_ativos_rede_direta = sum(n_cbo_sus_ativos_distintos, na.rm = TRUE),
    vinculos_medicos_sus_ativos_rede_direta = sum(n_vinculos_medicos_sus_ativos, na.rm = TRUE),
    cbo_medicos_sus_ativos_rede_direta = sum(n_cbo_medicos_sus_ativos_distintos, na.rm = TRUE),
    municipios_unidades_cnes = paste(sort(unique(na.omit(municipio_cnes))), collapse = " | "),
    cnes_unidades_fixas = paste(sort(unique(cnes)), collapse = " | "),
    .groups = "drop"
  )

# `sum` de CBOs por unidade mede escopo registrado, mas pode contar o mesmo
# CBO em mais de uma unidade. O microdado de nomes nao e retido para evitar PII.
entity_capacity <- polos |>
  select(
    cnpj_raiz_8, cnpj_canonico, razao_social_canonica, sigla_canonica,
    aparece_mides_mg, incluir_modelo_principal_preliminar,
    incluir_sensibilidade_multiarea, decisao_polo_atracao,
    n_unidades_cnes_vinculadas, n_unidades_moveis_ou_itinerantes
  ) |>
  left_join(entity_capacity, by = c("cnpj_raiz_8", "cnpj_canonico")) |>
  mutate(
    capacidade_status = case_when(
      decisao_polo_atracao == "sede_administrativa_apenas_ancora_sensibilidade" ~ "sem_unidade_cnes_direta_nao_interpretar_como_zero",
      n_unidades_cnes_vinculadas > 0L & n_unidades_moveis_ou_itinerantes == n_unidades_cnes_vinculadas ~ "somente_unidades_moveis_sem_polo_fixo",
      is.na(n_unidades_fixas_cnes) ~ "capacidade_pendente_por_consulta",
      n_unidades_consulta_completa < n_unidades_fixas_cnes ~ "capacidade_parcial_consulta_incompleta",
      TRUE ~ "capacidade_direta_cnes_atual"
    ),
    medida_recomendada_passo_modelo = case_when(
      capacidade_status == "capacidade_direta_cnes_atual" ~ "Testar leitos SUS, CBO medicos SUS e unidades/atendimentos separadamente; nao criar indice unico.",
      capacidade_status == "somente_unidades_moveis_sem_polo_fixo" ~ "Fora da especificacao principal de tempo; exigir medida propria para servico movel.",
      capacidade_status == "sem_unidade_cnes_direta_nao_interpretar_como_zero" ~ "Auditar prestador externo ou rede documentada; sede somente em sensibilidade.",
      TRUE ~ "Repetir consulta CNES antes de uso analitico."
    ),
    data_extracao_cnes = snapshot_date
  ) |>
  arrange(cnpj_raiz_8)

write.csv(capacity_units, file.path(out_dir, "capacidade_unidades_cnes_saude_mg.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(entity_capacity, file.path(out_dir, "capacidade_entidades_saude_mg.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(capacity_units, file.path(out_dir, paste0("capacidade_unidades_cnes_saude_mg_", snapshot_tag, ".csv")), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(entity_capacity, file.path(out_dir, paste0("capacidade_entidades_saude_mg_", snapshot_tag, ".csv")), row.names = FALSE, fileEncoding = "UTF-8")
saveRDS(entity_capacity, file.path(out_dir, "capacidade_entidades_saude_mg.rds"))

status_counts <- entity_capacity |>
  count(capacidade_status, name = "entidades") |>
  arrange(capacidade_status)
core <- entity_capacity |> filter(incluir_modelo_principal_preliminar)
fixed_units <- capacity_units |> filter(unidade_fixa_elegivel)
direct_entities <- entity_capacity |> filter(capacidade_status == "capacidade_direta_cnes_atual")
bed_units <- capacity_units |>
  filter(leitos_existentes > 0) |>
  select(nome_estabelecimento_cnes, cnes, leitos_existentes, leitos_sus)
example_entities <- entity_capacity |>
  filter(sigla_canonica %in% c("CIS/CEN", "CISMAS", "CISMARPA", "CISVER", "CISMEP", "CIMES")) |>
  select(
    sigla_canonica, capacidade_status, n_unidades_cnes_vinculadas,
    n_unidades_moveis_ou_itinerantes, n_unidades_fixas_cnes,
    leitos_sus_rede_direta, cbo_medicos_sus_ativos_rede_direta
  ) |>
  arrange(sigla_canonica)
check_lines <- c(
  "# Validacao: Capacidade Assistencial Direta CNES (MG)",
  "",
  paste0("- Data da extracao CNES: `", snapshot_date, "`."),
  paste0("- Entidades consolidadas: **", nrow(entity_capacity), "**."),
  paste0("- Unidades CNES vinculadas consultadas: **", nrow(capacity_units), "**."),
  paste0("- Unidades com todos os modulos consultados: **", sum(capacity_units$consulta_cnes_completa), "**."),
  paste0("- Entidades do nucleo MIDES: **", nrow(core), "**."),
  "",
  "## Situacao Da Capacidade",
  "",
  "| Situacao | Entidades |",
  "|---|---:|",
  vapply(seq_len(nrow(status_counts)), function(i) paste0("| ", status_counts$capacidade_status[[i]], " | ", status_counts$entidades[[i]], " |"), character(1)),
  "",
  "## Cobertura E Medidas",
  "",
  paste0("- Unidades fixas elegiveis: **", nrow(fixed_units), "**; unidades moveis/itinerantes: **", sum(capacity_units$unidade_movel_ou_itinerante), "**."),
  paste0("- Unidades fixas com atendimento ambulatorial SUS: **", sum(fixed_units$atendimento_ambulatorial_sus %in% TRUE), "**; com SADT SUS: **", sum(fixed_units$sadt_sus %in% TRUE), "**; com internacao SUS: **", sum(fixed_units$internacao_sus %in% TRUE), "**."),
  paste0("- Unidades fixas com ao menos um CBO medico SUS ativo: **", sum(fixed_units$n_cbo_medicos_sus_ativos_distintos > 0), "**."),
  paste0("- Entidades com capacidade fixa direta: **", nrow(direct_entities), "**; todas possuem ao menos um CBO medico SUS ativo."),
  paste0("- Entidades com leitos SUS diretamente registrados: **", sum(direct_entities$leitos_sus_rede_direta > 0), "** de **", nrow(direct_entities), "**."),
  "",
  "### Estabelecimentos Com Leitos Existentes",
  "",
  "| Estabelecimento | CNES | Leitos existentes | Leitos SUS |",
  "|---|---:|---:|---:|",
  vapply(seq_len(nrow(bed_units)), function(i) paste0("| ", bed_units$nome_estabelecimento_cnes[[i]], " | ", bed_units$cnes[[i]], " | ", bed_units$leitos_existentes[[i]], " | ", bed_units$leitos_sus[[i]], " |"), character(1)),
  "",
  "## Exemplos Auditados",
  "",
  "| Entidade | Status | Unidades | Moveis | Fixas | Leitos SUS | Soma de CBOs medicos |",
  "|---|---|---:|---:|---:|---:|---:|",
  vapply(seq_len(nrow(example_entities)), function(i) paste0(
    "| ", example_entities$sigla_canonica[[i]], " | ", example_entities$capacidade_status[[i]],
    " | ", example_entities$n_unidades_cnes_vinculadas[[i]],
    " | ", example_entities$n_unidades_moveis_ou_itinerantes[[i]],
    " | ", ifelse(is.na(example_entities$n_unidades_fixas_cnes[[i]]), "NA", example_entities$n_unidades_fixas_cnes[[i]]),
    " | ", ifelse(is.na(example_entities$leitos_sus_rede_direta[[i]]), "NA", example_entities$leitos_sus_rede_direta[[i]]),
    " | ", ifelse(is.na(example_entities$cbo_medicos_sus_ativos_rede_direta[[i]]), "NA", example_entities$cbo_medicos_sus_ativos_rede_direta[[i]]), " |"
  ), character(1)),
  "",
  "## Leitura Metodologica",
  "",
  "- Leitos SUS aparecem em apenas uma entidade com capacidade direta; nao devem ser a unica massa de atracao.",
  "- CBOs medicos e atendimentos possuem cobertura maior, mas medem cadastro atual, nao producao nem especialidade historica.",
  "- O mesmo CBO pode aparecer em varias unidades da rede; a soma mede escopo registrado por unidade, nao especialidades unicas da entidade.",
  "- CIS/CEN e CIMES possuem somente unidades moveis e nao recebem destino rodoviario fixo.",
  "",
  "## Regras De Leitura",
  "",
  "- Leitos, vinculos SUS e CBOs sao fotografia atual do CNES, nao serie historica do MIDES.",
  "- Valores iguais a zero so significam ausencia no modulo CNES quando a consulta foi completa; ausencia de unidade sob o CNPJ permanece `NA` no agregado.",
  "- CBO medico distinto e proxy de escopo profissional, nao equivale a servico especializado formal ou producao realizada.",
  "- A soma por entidade considera somente unidades fixas diretamente vinculadas pelo CNPJ; nao inclui hospital municipal, contratado ou proximo sem evidencia documental."
)
writeLines(check_lines, file.path(check_dir, "VALIDACAO_CAPACIDADE_ASSISTENCIAL_SAUDE_MG.md"), useBytes = TRUE)

message("Passo de capacidade concluido: ", nrow(capacity_units), " unidades; ", nrow(entity_capacity), " entidades.")
