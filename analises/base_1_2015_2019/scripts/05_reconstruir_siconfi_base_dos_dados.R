# =============================================================================
# 05_reconstruir_siconfi_base_dos_dados.R
# Base 1 - reconstrucao auditavel do SICONFI a partir da Base dos Dados
#
# Objetivo:
#   Refazer a base SICONFI em R, com regras explicitas, e comparar cada regra
#   com a aba herdada "SICONFI painel munic".
#
# Fonte principal:
#   br_me_siconfi.municipio_despesas_orcamentarias
#
# Fallback:
#   Se BigQuery/Base dos Dados nao estiver autenticado, usa o bruto local
#   Tabelas/Siconfi/Siconfi_municipios.xlsx para manter a auditoria executavel.
#
# Unidade:
#   municipio x ano, MG, anos 2015 e 2019.
# =============================================================================

library(dplyr)
library(readxl)
library(readr)
library(writexl)
library(stringr)
library(tidyr)
library(lubridate)

anos_base <- c(2015L, 2019L)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

base_candidates <- Sys.glob(
  "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para an*lise/base_consorcios_v10_2026-04-30.xlsx"
)
raw_candidates <- Sys.glob(
  "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para an*lise/Tabelas/Siconfi/Siconfi_munic*.xlsx"
)

if (length(base_candidates) == 0L) {
  stop("Planilha base_consorcios_v10_2026-04-30.xlsx nao encontrada.")
}

base_path <- base_candidates[[1]]
raw_path <- if (length(raw_candidates) > 0L) raw_candidates[[1]] else NA_character_

out_dir <- file.path(project_dir, "analises/base_1_2015_2019/outputs")
check_dir <- file.path(project_dir, "analises/base_1_2015_2019/checks")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(check_dir, recursive = TRUE, showWarnings = FALSE)

normaliza_txt <- function(x) {
  x |>
    as.character() |>
    stringi::stri_trans_general("Latin-ASCII") |>
    str_to_lower() |>
    str_squish()
}

fmt_num <- function(x) {
  format(round(x, 2), big.mark = ".", decimal.mark = ",", scientific = FALSE)
}

md_table <- function(df) {
  df_chr <- df |>
    mutate(across(where(is.numeric), fmt_num)) |>
    mutate(across(everything(), as.character))

  header <- paste0("| ", paste(names(df_chr), collapse = " | "), " |")
  sep <- paste0("|", paste(rep("---", ncol(df_chr)), collapse = "|"), "|")
  rows <- apply(df_chr, 1, function(x) paste0("| ", paste(x, collapse = " | "), " |"))
  c(header, sep, rows)
}

carregar_siconfi_atual <- function() {
  read_excel(base_path, sheet = "SICONFI painel munic") |>
    filter(uf == "MG", ano %in% anos_base, nota_cobertura == "ok") |>
    transmute(
      ano = as.integer(ano),
      cod_ibge_6 = str_sub(as.character(cod_ibge), 1, 6),
      municipio = as.character(municipio),
      valor_atual = as.numeric(valor_cons_real),
      paga_consorcio_atual = as.logical(paga_consorcio),
      nota_cobertura = as.character(nota_cobertura)
    )
}

carregar_base_dos_dados <- function() {
  if (!requireNamespace("basedosdados", quietly = TRUE)) {
    stop("Pacote basedosdados nao instalado.")
  }

  billing_id <- Sys.getenv("SICONFI_BILLING_ID", unset = "ipea-consorcios")
  basedosdados::set_billing_id(billing_id)

  message("Tentando baixar SICONFI via Base dos Dados/BigQuery...")
  message("Billing id: ", billing_id)

  bd_table <- basedosdados::bdplyr("br_me_siconfi.municipio_despesas_orcamentarias") |>
    filter(ano %in% anos_base, sigla_uf == "MG") |>
    select(
      ano,
      sigla_uf,
      id_municipio,
      estagio_bd,
      conta_bd,
      valor
    )

  basedosdados::bd_collect(bd_table) |>
    transmute(
      fonte_reconstrucao = "base_dos_dados_bigquery",
      ano = as.integer(ano),
      uf = as.character(sigla_uf),
      cod_ibge_6 = str_sub(as.character(id_municipio), 1, 6),
      municipio = NA_character_,
      despesa = as.character(estagio_bd),
      rubrica = as.character(conta_bd),
      valor_nominal = as.numeric(valor)
    )
}

carregar_bruto_local <- function() {
  if (is.na(raw_path) || !file.exists(raw_path)) {
    stop("Bruto local Siconfi_municipios.xlsx nao encontrado.")
  }

  message("Usando fallback local: ", raw_path)

  excel_sheets(raw_path) |>
    lapply(function(sheet) {
      read_excel(raw_path, sheet = sheet) |>
        mutate(sheet_origem = sheet)
    }) |>
    bind_rows() |>
    filter(uf == "MG", ano %in% anos_base) |>
    transmute(
      fonte_reconstrucao = "bruto_local_xlsx",
      ano = as.integer(ano),
      uf = as.character(uf),
      cod_ibge_6 = str_sub(as.character(cod_ibge), 1, 6),
      municipio = as.character(municipio),
      despesa = as.character(despesa),
      rubrica = as.character(rubrica),
      # O bruto local ja foi deflacionado pelo script historico siconfi.R.
      valor_nominal = as.numeric(valor)
    )
}

siconfi_atual <- carregar_siconfi_atual()

fonte_usada <- "base_dos_dados_bigquery"
erro_bq <- NA_character_

siconfi_raw <- tryCatch(
  carregar_base_dos_dados(),
  error = function(e) {
    erro_bq <<- conditionMessage(e)
    fonte_usada <<- "bruto_local_xlsx"
    carregar_bruto_local()
  }
)

message("Fonte efetivamente usada: ", fonte_usada)
if (!is.na(erro_bq)) {
  message("Falha BigQuery/Base dos Dados: ", erro_bq)
}

siconfi_preparado <- siconfi_raw |>
  mutate(
    rubrica_norm = normaliza_txt(rubrica),
    despesa_norm = normaliza_txt(despesa),
    is_consorcio = str_detect(rubrica_norm, "consorcio"),
    is_rateio = str_detect(rubrica_norm, "contrato de rateio"),
    is_sflu = str_detect(rubrica_norm, "sem fins lucrativos"),
    is_multigov = str_detect(rubrica_norm, "multigovernamentais"),
    is_empenhada = str_detect(despesa_norm, "despesas empenhadas"),
    is_liquidada = str_detect(despesa_norm, "despesas liquidadas"),
    is_paga = str_detect(despesa_norm, "despesas pagas"),
    is_rp = str_detect(despesa_norm, "rp|restos a pagar"),
    ano_data = ymd(paste0(ano, "-01-01")),
    valor_real = if (fonte_usada == "base_dos_dados_bigquery") {
      deflateBR::deflate(valor_nominal, ano_data, "01/2018", "ipca")
    } else {
      valor_nominal
    }
  )

variantes <- tibble::tribble(
  ~variante, ~descricao,
  "rateio_empenhadas", "Rubricas de consorcio + contrato de rateio; somente despesas empenhadas",
  "rateio_pagas", "Rubricas de consorcio + contrato de rateio; somente despesas pagas",
  "rateio_liquidadas", "Rubricas de consorcio + contrato de rateio; somente despesas liquidadas",
  "consorcio_empenhadas", "Qualquer rubrica com consorcio; somente despesas empenhadas",
  "consorcio_pagas", "Qualquer rubrica com consorcio; somente despesas pagas",
  "consorcio_liquidadas", "Qualquer rubrica com consorcio; somente despesas liquidadas",
  "consorcio_sem_rp", "Qualquer rubrica com consorcio; exclui restos a pagar",
  "consorcio_com_rp", "Qualquer rubrica com consorcio; inclui todos os estagios do bruto",
  "original_gabriel_empenhadas", "Consorcio ou multigovernamentais ou sem fins lucrativos; somente despesas empenhadas"
)

painel_variantes <- siconfi_preparado |>
  summarise(
    municipio_raw = first(na.omit(municipio)),
    rateio_empenhadas = sum(if_else(is_consorcio & is_rateio & is_empenhada, valor_real, 0), na.rm = TRUE),
    rateio_pagas = sum(if_else(is_consorcio & is_rateio & is_paga, valor_real, 0), na.rm = TRUE),
    rateio_liquidadas = sum(if_else(is_consorcio & is_rateio & is_liquidada, valor_real, 0), na.rm = TRUE),
    consorcio_empenhadas = sum(if_else(is_consorcio & is_empenhada, valor_real, 0), na.rm = TRUE),
    consorcio_pagas = sum(if_else(is_consorcio & is_paga, valor_real, 0), na.rm = TRUE),
    consorcio_liquidadas = sum(if_else(is_consorcio & is_liquidada, valor_real, 0), na.rm = TRUE),
    consorcio_sem_rp = sum(if_else(is_consorcio & !is_rp, valor_real, 0), na.rm = TRUE),
    consorcio_com_rp = sum(if_else(is_consorcio, valor_real, 0), na.rm = TRUE),
    original_gabriel_empenhadas = sum(
      if_else((is_consorcio | is_multigov | is_sflu) & is_empenhada, valor_real, 0),
      na.rm = TRUE
    ),
    n_linhas_raw = n(),
    n_rubricas_consorcio = n_distinct(rubrica[is_consorcio]),
    .by = c(ano, cod_ibge_6)
  )

comparacao_larga <- full_join(
  siconfi_atual,
  painel_variantes,
  by = join_by(ano, cod_ibge_6)
) |>
  mutate(
    municipio = coalesce(municipio, municipio_raw),
    across(
      all_of(variantes$variante),
      ~if_else(is.na(.x), 0, .x)
    ),
    valor_atual = if_else(is.na(valor_atual), 0, valor_atual),
    paga_consorcio_atual = if_else(is.na(paga_consorcio_atual), FALSE, paga_consorcio_atual)
  )

comparacao_longa <- comparacao_larga |>
  select(ano, cod_ibge_6, municipio, valor_atual, all_of(variantes$variante)) |>
  pivot_longer(
    cols = all_of(variantes$variante),
    names_to = "variante",
    values_to = "valor_reconstruido"
  ) |>
  left_join(variantes, by = "variante") |>
  mutate(
    diferenca = valor_atual - valor_reconstruido,
    diferenca_abs = abs(diferenca),
    ambos_zero = valor_atual == 0 & valor_reconstruido == 0,
    fecha_exato = diferenca_abs < 0.01,
    fecha_10k_ou_10pct = diferenca_abs <= 10000 |
      diferenca_abs / pmax(abs(valor_atual), abs(valor_reconstruido), 1) <= 0.10
  )

ranking_variantes <- comparacao_longa |>
  summarise(
    n_municipio_ano = n(),
    n_atual_positivo = sum(valor_atual > 0, na.rm = TRUE),
    n_reconstruido_positivo = sum(valor_reconstruido > 0, na.rm = TRUE),
    total_atual = sum(valor_atual, na.rm = TRUE),
    total_reconstruido = sum(valor_reconstruido, na.rm = TRUE),
    diferenca_total = total_atual - total_reconstruido,
    diferenca_total_abs = abs(diferenca_total),
    soma_diferenca_abs_municipal = sum(diferenca_abs, na.rm = TRUE),
    n_fecha_exato = sum(fecha_exato, na.rm = TRUE),
    n_fecha_10k_ou_10pct = sum(fecha_10k_ou_10pct, na.rm = TRUE),
    .by = c(variante, descricao)
  ) |>
  mutate(
    total_atual_mi = total_atual / 1e6,
    total_reconstruido_mi = total_reconstruido / 1e6,
    diferenca_total_mi = diferenca_total / 1e6
  ) |>
  arrange(soma_diferenca_abs_municipal, diferenca_total_abs)

ranking_por_ano <- comparacao_longa |>
  summarise(
    n_municipio_ano = n(),
    n_reconstruido_positivo = sum(valor_reconstruido > 0, na.rm = TRUE),
    total_atual = sum(valor_atual, na.rm = TRUE),
    total_reconstruido = sum(valor_reconstruido, na.rm = TRUE),
    diferenca_total = total_atual - total_reconstruido,
    soma_diferenca_abs_municipal = sum(diferenca_abs, na.rm = TRUE),
    n_fecha_exato = sum(fecha_exato, na.rm = TRUE),
    n_fecha_10k_ou_10pct = sum(fecha_10k_ou_10pct, na.rm = TRUE),
    .by = c(ano, variante)
  ) |>
  arrange(ano, soma_diferenca_abs_municipal)

melhor_variante <- ranking_variantes$variante[[1]]

painel_reconstruido_recomendado <- comparacao_larga |>
  transmute(
    ano,
    cod_ibge_6,
    municipio,
    valor_siconfi_atual = valor_atual,
    valor_siconfi_reconstruido = .data[[melhor_variante]],
    variante_recomendada = melhor_variante,
    diferenca = valor_siconfi_atual - valor_siconfi_reconstruido,
    diferenca_abs = abs(diferenca),
    paga_consorcio_reconstruido = valor_siconfi_reconstruido > 0,
    paga_consorcio_atual,
    nota_cobertura
  ) |>
  arrange(ano, desc(diferenca_abs), cod_ibge_6)

rubricas_reconstrucao <- siconfi_preparado |>
  filter(is_consorcio | is_multigov | is_sflu) |>
  summarise(
    n_linhas = n(),
    n_municipio_ano = n_distinct(paste(cod_ibge_6, ano)),
    valor_real = sum(valor_real, na.rm = TRUE),
    .by = c(despesa, rubrica)
  ) |>
  arrange(desc(valor_real))

out_csv_painel <- file.path(out_dir, "base_1_siconfi_reconstruido_2015_2019.csv")
out_csv_ranking <- file.path(check_dir, "base_1_siconfi_reconstruido_ranking_variantes.csv")
out_xlsx <- file.path(check_dir, "base_1_siconfi_reconstruido_2015_2019.xlsx")
out_md <- file.path(check_dir, "RECONSTRUCAO_SICONFI_BASE_DOS_DADOS_2015_2019.md")

write_csv(painel_reconstruido_recomendado, out_csv_painel)
write_csv(ranking_variantes, out_csv_ranking)
write_xlsx(
  list(
    ranking_variantes = ranking_variantes,
    ranking_por_ano = ranking_por_ano,
    painel_reconstruido = painel_reconstruido_recomendado,
    comparacao_todas_variantes = comparacao_longa,
    rubricas_reconstrucao = rubricas_reconstrucao
  ),
  out_xlsx
)

ranking_md <- ranking_variantes |>
  mutate(
    total_atual_mi = total_atual / 1e6,
    total_reconstruido_mi = total_reconstruido / 1e6,
    diferenca_total_mi = diferenca_total / 1e6,
    soma_diferenca_abs_municipal_mi = soma_diferenca_abs_municipal / 1e6
  ) |>
  select(
    variante,
    n_reconstruido_positivo,
    total_atual_mi,
    total_reconstruido_mi,
    diferenca_total_mi,
    soma_diferenca_abs_municipal_mi,
    n_fecha_exato,
    n_fecha_10k_ou_10pct
  )

ranking_ano_md <- ranking_por_ano |>
  mutate(
    ano = as.character(ano),
    total_atual_mi = total_atual / 1e6,
    total_reconstruido_mi = total_reconstruido / 1e6,
    diferenca_total_mi = diferenca_total / 1e6,
    soma_diferenca_abs_municipal_mi = soma_diferenca_abs_municipal / 1e6
  ) |>
  select(
    ano,
    variante,
    total_atual_mi,
    total_reconstruido_mi,
    diferenca_total_mi,
    soma_diferenca_abs_municipal_mi,
    n_fecha_10k_ou_10pct
  ) |>
  group_by(ano) |>
  slice_min(soma_diferenca_abs_municipal_mi, n = 3, with_ties = FALSE) |>
  ungroup()

linhas_md <- c(
  "# Reconstrucao SICONFI - Base dos Dados 2015/2019",
  "",
  "## Objetivo",
  "",
  "Refazer o SICONFI em R com regras explicitas e comparar cada regra contra a aba herdada `SICONFI painel munic`.",
  "",
  "## Fonte usada nesta execucao",
  "",
  paste0("- Fonte efetiva: `", fonte_usada, "`."),
  if (!is.na(erro_bq)) paste0("- BigQuery/Base dos Dados nao foi usado nesta execucao. Erro: `", erro_bq, "`.") else "- BigQuery/Base dos Dados executado com sucesso.",
  "- Tabela alvo: `br_me_siconfi.municipio_despesas_orcamentarias`.",
  "- Recorte: MG, anos 2015 e 2019.",
  "- Valores: deflacionados para jan/2018 quando a fonte efetiva e BigQuery; no bruto local, os valores ja estavam deflacionados pelo script historico.",
  "",
  "## Ranking das variantes",
  "",
  md_table(ranking_md),
  "",
  "## Tres melhores variantes por ano",
  "",
  md_table(ranking_ano_md),
  "",
  "## Melhor aproximacao",
  "",
  paste0("- Melhor variante por menor soma de diferencas absolutas municipais: `", melhor_variante, "`."),
  "",
  "## Leitura metodologica",
  "",
  "- Esta reconstrucao transforma a duvida em um teste reproduzivel.",
  "- Se a melhor variante ainda nao fechar bem com a aba atual, a conclusao e que a aba herdada nao deve ser tratada como regra oficial sem recuperar o SQL/script original.",
  "- Nesse caso, a recomendacao e escolher explicitamente uma regra nova e reprocessar a validacao MIDES x SICONFI com ela.",
  "",
  "## Outputs",
  "",
  "- `analises/base_1_2015_2019/outputs/base_1_siconfi_reconstruido_2015_2019.csv`",
  "- `analises/base_1_2015_2019/checks/base_1_siconfi_reconstruido_ranking_variantes.csv`",
  "- `analises/base_1_2015_2019/checks/base_1_siconfi_reconstruido_2015_2019.xlsx`"
)

writeLines(linhas_md, out_md, useBytes = TRUE)

message("\nRanking das variantes:")
print(ranking_variantes, n = Inf, width = Inf)

message("\nMelhor variante: ", melhor_variante)
message("\nExportado:")
message("  ", out_csv_painel)
message("  ", out_csv_ranking)
message("  ", out_xlsx)
message("  ", out_md)
