suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
})

script_path <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
analysis_dir <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
project_dir <- normalizePath(file.path(analysis_dir, "..", ".."), winslash = "/", mustWork = TRUE)
output_dir <- file.path(analysis_dir, "outputs")
check_dir <- file.path(analysis_dir, "checks")
export_root <- Sys.getenv("CNM_ANALYSIS_EXPORT_ROOT", unset = "")
if (nzchar(export_root)) {
  output_dir <- file.path(export_root, "outputs")
  check_dir <- file.path(export_root, "checks")
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(check_dir, recursive = TRUE, showWarnings = FALSE)

snapshot_dir <- "C:/IPEA/dados cnm/snapshots/2026-08-27/data"
base_nacional <- file.path(project_dir, "analises", "base_nacional", "outputs")

write_csv_semicolon <- function(x, path) {
  write.table(
    x, file = path, sep = ";", dec = ",", quote = TRUE,
    row.names = FALSE, col.names = TRUE, na = "", fileEncoding = "UTF-8"
  )
}

digits <- function(x) str_replace_all(coalesce(as.character(x), ""), "[^0-9]", "")
norm_text <- function(x) {
  x |>
    coalesce("") |>
    iconv(from = "UTF-8", to = "ASCII//TRANSLIT") |>
    str_to_upper() |>
    str_replace_all("[^A-Z0-9]+", " ") |>
    str_squish()
}
similarity <- function(a, b) {
  if (!nzchar(a) || !nzchar(b)) return(0)
  1 - as.numeric(adist(a, b)) / max(nchar(a), nchar(b), 1)
}

cnm <- read_delim(file.path(snapshot_dir, "base_unificada_consorcios_macroareas.csv"), delim = ";", show_col_types = FALSE) |>
  transmute(
    cnm_uuid = consorcio_uuid,
    cnm_cnpj_original = digits(consorcio_cnpj),
    cnm_cnpj_raiz_8 = if_else(str_length(cnm_cnpj_original) == 14L, str_sub(cnm_cnpj_original, 1, 8), NA_character_),
    cnm_nome = consorcio_nome,
    cnm_sigla = consorcio_sigla,
    cnm_sede_uf = sede_municipio_uf,
    cnm_sede_ibge = digits(sede_municipio_ibge),
    cnm_sede_nome = sede_municipio_nome,
    cnm_situacao = consorcio_situacao_cnpj,
    cnm_status = consorcio_status,
    cnm_data_constituicao = consorcio_data_constituicao,
    cnm_nome_norm = norm_text(cnm_nome),
    cnm_sigla_norm = norm_text(cnm_sigla)
  )

ipea_cross <- readRDS(file.path(base_nacional, "crosswalk_cnpj_matriz_filial_nacional.rds"))
ipea_root <- readRDS(file.path(base_nacional, "cadastro_consorcios_nacional_consolidado.rds"))

exact <- ipea_cross |>
  transmute(
    cnm_cnpj_original = cnpj_original,
    cnpj_canonico_exato = cnpj_canonico,
    cnpj_raiz_exata = cnpj_raiz_8,
    nome_ipea_exato = razao_social_canonica,
    sigla_ipea_exata = sigla_canonica,
    uf_ipea_exata = uf_sede_canonica,
    municipio_ipea_exato = municipio_sede_canonico
  )

root <- ipea_root |>
  transmute(
    cnm_cnpj_raiz_8 = cnpj_raiz_8,
    cnpj_canonico_raiz = cnpj_canonico,
    nome_ipea_raiz = razao_social_canonica,
    sigla_ipea_raiz = sigla_canonica,
    uf_ipea_raiz = uf_sede_canonica,
    municipio_ipea_raiz = municipio_sede_canonico
  )

base <- cnm |>
  left_join(exact, by = "cnm_cnpj_original") |>
  left_join(root, by = "cnm_cnpj_raiz_8") |>
  mutate(
    situacao_pareamento = case_when(
      !is.na(cnpj_canonico_exato) ~ "exato_cnpj",
      is.na(cnpj_canonico_exato) & !is.na(cnpj_canonico_raiz) ~ "raiz_cnpj",
      TRUE ~ "nao_encontrado"
    ),
    cnpj_canonico = coalesce(cnpj_canonico_exato, cnpj_canonico_raiz),
    nome_cadastro_ipea = coalesce(nome_ipea_exato, nome_ipea_raiz),
    sigla_cadastro_ipea = coalesce(sigla_ipea_exata, sigla_ipea_raiz),
    uf_cadastro_ipea = coalesce(uf_ipea_exata, uf_ipea_raiz),
    municipio_sede_ipea = coalesce(municipio_ipea_exato, municipio_ipea_raiz),
    identidade_validada_automaticamente = situacao_pareamento %in% c("exato_cnpj", "raiz_cnpj")
  )

candidate_pool <- ipea_root |>
  transmute(
    candidato_cnpj = cnpj_canonico,
    candidato_nome = razao_social_canonica,
    candidato_sigla = sigla_canonica,
    candidato_uf = uf_sede_canonica,
    candidato_nome_norm = norm_text(razao_social_canonica),
    candidato_sigla_norm = norm_text(sigla_canonica)
  )

find_candidate <- function(nome, sigla, uf) {
  pool <- candidate_pool
  if (!is.na(uf) && nzchar(uf) && any(pool$candidato_uf == uf, na.rm = TRUE)) pool <- filter(pool, candidato_uf == uf)
  scores_nome <- vapply(pool$candidato_nome_norm, function(x) similarity(nome, x), numeric(1))
  scores_sigla <- if (nzchar(sigla)) if_else(pool$candidato_sigla_norm == sigla, 1, 0) else rep(0, nrow(pool))
  scores <- pmax(scores_nome, scores_sigla)
  ord <- order(scores, decreasing = TRUE)
  best <- ord[1]
  second <- if (length(ord) > 1) scores[ord[2]] else 0
  tibble(
    candidato_cnpj = pool$candidato_cnpj[best],
    candidato_nome = pool$candidato_nome[best],
    candidato_sigla = pool$candidato_sigla[best],
    candidato_uf = pool$candidato_uf[best],
    similaridade_nome = scores[best],
    margem_segundo_candidato = scores[best] - second
  )
}

unmatched <- base |>
  filter(situacao_pareamento == "nao_encontrado")

if (nrow(unmatched) > 0) {
  suggestions <- bind_rows(lapply(seq_len(nrow(unmatched)), function(i) {
    bind_cols(tibble(cnm_uuid = unmatched$cnm_uuid[i]), find_candidate(unmatched$cnm_nome_norm[i], unmatched$cnm_sigla_norm[i], unmatched$cnm_sede_uf[i]))
  }))
  base <- base |>
    left_join(suggestions, by = "cnm_uuid") |>
    mutate(
      situacao_pareamento = if_else(
        situacao_pareamento == "nao_encontrado" & similaridade_nome >= 0.90 & margem_segundo_candidato >= 0.03,
        "provavel_nome_revisar",
        situacao_pareamento
      )
    )
} else {
  base <- base |>
    mutate(
      candidato_cnpj = NA_character_, candidato_nome = NA_character_, candidato_sigla = NA_character_,
      candidato_uf = NA_character_, similaridade_nome = NA_real_, margem_segundo_candidato = NA_real_
    )
}

crosswalk <- base |>
  select(
    cnm_uuid, cnm_cnpj_original, cnm_cnpj_raiz_8, cnpj_canonico,
    cnm_nome, cnm_sigla, cnm_sede_uf, cnm_sede_ibge, cnm_sede_nome,
    cnm_situacao, cnm_status, cnm_data_constituicao,
    nome_cadastro_ipea, sigla_cadastro_ipea, uf_cadastro_ipea, municipio_sede_ipea,
    situacao_pareamento, identidade_validada_automaticamente,
    candidato_cnpj, candidato_nome, candidato_sigla, candidato_uf,
    similaridade_nome, margem_segundo_candidato
  )

resumo <- crosswalk |>
  count(situacao_pareamento, name = "consorcios") |>
  mutate(pct = consorcios / sum(consorcios))

stopifnot(nrow(crosswalk) == nrow(cnm))
stopifnot(!anyDuplicated(crosswalk$cnm_uuid))
stopifnot(all(!is.na(crosswalk$cnpj_canonico[crosswalk$identidade_validada_automaticamente])))
stopifnot(all(is.na(crosswalk$cnpj_canonico[!crosswalk$identidade_validada_automaticamente])))

saveRDS(crosswalk, file.path(output_dir, "crosswalk_cnm_ipea_cnpj.rds"))
write_csv_semicolon(crosswalk, file.path(output_dir, "crosswalk_cnm_ipea_cnpj.csv"))
write_csv_semicolon(resumo, file.path(output_dir, "crosswalk_cnm_ipea_resumo.csv"))

report <- c(
  "# Crosswalk CNM x Cadastro IPEA",
  "",
  "Somente `exato_cnpj` e `raiz_cnpj` recebem identidade canonica automaticamente. Sugestoes por nome permanecem para revisao humana e nao entram no cotejamento.",
  "",
  paste0("- Consorcios CNM: ", nrow(crosswalk)),
  paste0("- Identidades automaticas: ", sum(crosswalk$identidade_validada_automaticamente)),
  paste0("- Sugestoes por nome: ", sum(crosswalk$situacao_pareamento == "provavel_nome_revisar")),
  paste0("- Nao encontrados: ", sum(crosswalk$situacao_pareamento == "nao_encontrado")),
  "",
  "## Distribuicao",
  "",
  "| Situacao | Consorcios | Percentual |",
  "|---|---:|---:|",
  paste0("| ", resumo$situacao_pareamento, " | ", resumo$consorcios, " | ", sprintf("%.1f%%", 100 * resumo$pct), " |")
)
writeLines(report, file.path(check_dir, "VALIDACAO_CROSSWALK_CNM_IPEA.md"), useBytes = TRUE)
print(resumo, n = Inf)
