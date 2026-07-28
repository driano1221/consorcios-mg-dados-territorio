# =============================================================================
# 04_auditoria_siconfi_origem.R
# Base 1 - auditoria da origem/metodo SICONFI
#
# Objetivo:
#   Comparar a aba SICONFI usada na base mestre com reconstrucoes possiveis a
#   partir do arquivo bruto local Siconfi_municipios.xlsx.
#
# Unidade da auditoria:
#   municipio x ano, para MG em 2015 e 2019.
#
# Definicoes comparadas:
#   1) atual: valor_cons_real da aba "SICONFI painel munic".
#   2) restrita_rateio: Despesas Empenhadas em rubricas de contrato de rateio.
#   3) ampla_consorcio: Despesas Empenhadas em qualquer rubrica com Consorcio.
#
# Observacao:
#   O SICONFI nao identifica o CNPJ de destino. Esta auditoria trata apenas do
#   valor municipal agregado declarado no ano.
# =============================================================================

library(dplyr)
library(readxl)
library(readr)
library(writexl)
library(stringr)
library(tidyr)

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
if (length(raw_candidates) == 0L) {
  stop("Arquivo bruto Siconfi_municipios.xlsx nao encontrado.")
}

base_path <- base_candidates[[1]]
raw_path <- raw_candidates[[1]]

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

message("Carregando SICONFI atual da base mestre...")

siconfi_atual <- read_excel(base_path, sheet = "SICONFI painel munic") |>
  filter(uf == "MG", ano %in% anos_base, nota_cobertura == "ok") |>
  transmute(
    ano = as.integer(ano),
    cod_ibge_6 = str_sub(as.character(cod_ibge), 1, 6),
    municipio = as.character(municipio),
    valor_siconfi_atual = as.numeric(valor_cons_real),
    valor_sflu_atual = as.numeric(valor_sflu_real),
    valor_total_atual = as.numeric(valor_total_real),
    paga_consorcio_atual = as.logical(paga_consorcio),
    nota_cobertura = as.character(nota_cobertura)
  )

message("Carregando arquivo bruto SICONFI local...")

raw_sheets <- excel_sheets(raw_path)

siconfi_raw <- lapply(raw_sheets, function(sheet) {
  read_excel(raw_path, sheet = sheet) |>
    mutate(sheet_origem = sheet)
}) |>
  bind_rows() |>
  filter(uf == "MG", ano %in% anos_base) |>
  mutate(
    ano = as.integer(ano),
    cod_ibge_6 = str_sub(as.character(cod_ibge), 1, 6),
    municipio_raw = as.character(municipio),
    valor = as.numeric(valor),
    rubrica_norm = normaliza_txt(rubrica),
    despesa_norm = normaliza_txt(despesa),
    sheet_norm = normaliza_txt(sheet_origem),
    is_despesa_empenhada = sheet_norm == "despesas empenhadas",
    is_consorcio = str_detect(rubrica_norm, "consorcio"),
    is_rateio = str_detect(rubrica_norm, "contrato de rateio"),
    is_sflu = str_detect(rubrica_norm, "sem fins lucrativos"),
    is_multigovernamental = str_detect(rubrica_norm, "multigovernamentais")
  )

message("Reconstruindo definicoes alternativas...")

reconstruida <- siconfi_raw |>
  filter(is_despesa_empenhada) |>
  summarise(
    municipio_raw = first(na.omit(municipio_raw)),
    valor_restrito_rateio = sum(if_else(is_consorcio & is_rateio, valor, 0), na.rm = TRUE),
    valor_amplo_consorcio = sum(if_else(is_consorcio, valor, 0), na.rm = TRUE),
    valor_sflu_bruto = sum(if_else(is_sflu, valor, 0), na.rm = TRUE),
    valor_multigov_bruto = sum(if_else(is_multigovernamental, valor, 0), na.rm = TRUE),
    n_linhas_raw_empenhadas = n(),
    n_rubricas_consorcio = n_distinct(rubrica[is_consorcio]),
    rubricas_consorcio = paste(sort(unique(rubrica[is_consorcio])), collapse = " | "),
    .by = c(ano, cod_ibge_6)
  )

comparacao <- full_join(
  siconfi_atual,
  reconstruida,
  by = join_by(ano, cod_ibge_6)
) |>
  mutate(
    municipio = coalesce(municipio, municipio_raw),
    across(
      c(
        valor_siconfi_atual, valor_sflu_atual, valor_total_atual,
        valor_restrito_rateio, valor_amplo_consorcio, valor_sflu_bruto,
        valor_multigov_bruto, n_linhas_raw_empenhadas, n_rubricas_consorcio
      ),
      ~if_else(is.na(.x), 0, .x)
    ),
    paga_consorcio_atual = if_else(is.na(paga_consorcio_atual), FALSE, paga_consorcio_atual),
    diferenca_atual_menos_restrito = valor_siconfi_atual - valor_restrito_rateio,
    diferenca_atual_menos_amplo = valor_siconfi_atual - valor_amplo_consorcio,
    razao_atual_restrito = if_else(valor_restrito_rateio > 0, valor_siconfi_atual / valor_restrito_rateio, NA_real_),
    razao_atual_amplo = if_else(valor_amplo_consorcio > 0, valor_siconfi_atual / valor_amplo_consorcio, NA_real_),
    classe_auditoria = case_when(
      valor_siconfi_atual == 0 & valor_restrito_rateio == 0 & valor_amplo_consorcio == 0 ~ "zero_nas_tres",
      valor_siconfi_atual > 0 & valor_restrito_rateio == 0 & valor_amplo_consorcio == 0 ~ "atual_sem_raw_consorcio",
      valor_siconfi_atual == valor_restrito_rateio & valor_siconfi_atual == valor_amplo_consorcio ~ "fecha_nas_tres",
      valor_siconfi_atual == valor_restrito_rateio & valor_amplo_consorcio != valor_siconfi_atual ~ "fecha_restrito",
      valor_siconfi_atual == valor_amplo_consorcio & valor_restrito_rateio != valor_siconfi_atual ~ "fecha_amplo",
      TRUE ~ "nao_fecha"
    )
  ) |>
  select(
    ano, cod_ibge_6, municipio,
    valor_siconfi_atual, valor_restrito_rateio, valor_amplo_consorcio,
    valor_sflu_atual, valor_sflu_bruto, valor_multigov_bruto,
    diferenca_atual_menos_restrito, diferenca_atual_menos_amplo,
    razao_atual_restrito, razao_atual_amplo,
    paga_consorcio_atual, nota_cobertura,
    n_linhas_raw_empenhadas, n_rubricas_consorcio, rubricas_consorcio,
    classe_auditoria
  ) |>
  arrange(ano, classe_auditoria, desc(abs(diferenca_atual_menos_amplo)), cod_ibge_6)

resumo_ano <- comparacao |>
  summarise(
    n_municipio_ano = n(),
    n_atual_positivo = sum(valor_siconfi_atual > 0, na.rm = TRUE),
    n_restrito_positivo = sum(valor_restrito_rateio > 0, na.rm = TRUE),
    n_amplo_positivo = sum(valor_amplo_consorcio > 0, na.rm = TRUE),
    total_atual = sum(valor_siconfi_atual, na.rm = TRUE),
    total_restrito_rateio = sum(valor_restrito_rateio, na.rm = TRUE),
    total_amplo_consorcio = sum(valor_amplo_consorcio, na.rm = TRUE),
    dif_total_atual_restrito = total_atual - total_restrito_rateio,
    dif_total_atual_amplo = total_atual - total_amplo_consorcio,
    razao_total_atual_restrito = total_atual / total_restrito_rateio,
    razao_total_atual_amplo = total_atual / total_amplo_consorcio,
    .by = ano
  ) |>
  arrange(ano)

resumo_classe <- comparacao |>
  summarise(
    n_municipio_ano = n(),
    total_atual = sum(valor_siconfi_atual, na.rm = TRUE),
    total_restrito_rateio = sum(valor_restrito_rateio, na.rm = TRUE),
    total_amplo_consorcio = sum(valor_amplo_consorcio, na.rm = TRUE),
    .by = c(ano, classe_auditoria)
  ) |>
  arrange(ano, classe_auditoria)

rubricas_raw <- siconfi_raw |>
  filter(is_despesa_empenhada, is_consorcio | is_sflu | is_multigovernamental) |>
  summarise(
    n_linhas = n(),
    n_municipio_ano = n_distinct(paste(cod_ibge_6, ano)),
    valor = sum(valor, na.rm = TRUE),
    .by = c(sheet_origem, despesa, rubrica)
  ) |>
  arrange(desc(valor))

top_diferencas <- comparacao |>
  filter(classe_auditoria != "zero_nas_tres") |>
  arrange(desc(abs(diferenca_atual_menos_amplo))) |>
  head(80)

out_csv <- file.path(out_dir, "base_1_auditoria_siconfi_origem_2015_2019.csv")
out_xlsx <- file.path(check_dir, "base_1_auditoria_siconfi_origem_2015_2019.xlsx")
out_md <- file.path(check_dir, "AUDITORIA_SICONFI_ORIGEM_2015_2019.md")

write_csv(comparacao, out_csv)
write_xlsx(
  list(
    resumo_ano = resumo_ano,
    resumo_classe = resumo_classe,
    comparacao_municipio_ano = comparacao,
    top_diferencas = top_diferencas,
    rubricas_raw = rubricas_raw
  ),
  out_xlsx
)

fmt_num <- function(x) format(round(x, 2), big.mark = ".", decimal.mark = ",", scientific = FALSE)

md_table <- function(df) {
  df_chr <- df |>
    mutate(across(where(is.numeric), fmt_num)) |>
    mutate(across(everything(), as.character))

  header <- paste0("| ", paste(names(df_chr), collapse = " | "), " |")
  sep <- paste0("|", paste(rep("---", ncol(df_chr)), collapse = "|"), "|")
  rows <- apply(df_chr, 1, function(x) paste0("| ", paste(x, collapse = " | "), " |"))
  c(header, sep, rows)
}

resumo_ano_md <- resumo_ano |>
  mutate(
    ano = as.character(ano),
    total_atual_mi = total_atual / 1e6,
    total_restrito_rateio_mi = total_restrito_rateio / 1e6,
    total_amplo_consorcio_mi = total_amplo_consorcio / 1e6,
    atual_vs_restrito_pct = (total_atual / total_restrito_rateio - 1) * 100,
    atual_vs_amplo_pct = (total_atual / total_amplo_consorcio - 1) * 100
  ) |>
  select(
    ano,
    n_municipio_ano,
    n_atual_positivo,
    n_restrito_positivo,
    n_amplo_positivo,
    total_atual_mi,
    total_restrito_rateio_mi,
    total_amplo_consorcio_mi,
    atual_vs_restrito_pct,
    atual_vs_amplo_pct
  )

resumo_classe_md <- resumo_classe |>
  mutate(
    ano = as.character(ano),
    total_atual_mi = total_atual / 1e6,
    total_restrito_rateio_mi = total_restrito_rateio / 1e6,
    total_amplo_consorcio_mi = total_amplo_consorcio / 1e6
  ) |>
  select(
    ano,
    classe_auditoria,
    n_municipio_ano,
    total_atual_mi,
    total_restrito_rateio_mi,
    total_amplo_consorcio_mi
  )

linhas_md <- c(
  "# Auditoria SICONFI - origem e definicoes 2015/2019",
  "",
  "## Pergunta",
  "",
  "A base `SICONFI painel munic` usada na Base 1 e reproduzivel a partir dos arquivos brutos locais? E qual definicao de valor de consorcio ela parece representar?",
  "",
  "## Arquivos usados",
  "",
  "- Base mestre: `base_consorcios_v10_2026-04-30.xlsx` / aba `SICONFI painel munic`.",
  "- Bruto local: `Tabelas/Siconfi/Siconfi_municipios.xlsx`.",
  "- Recorte: MG, anos 2015 e 2019.",
  "- Unidade: municipio x ano.",
  "",
  "## Definicoes comparadas",
  "",
  "| Definicao | Como foi calculada | Interpretacao |",
  "|---|---|---|",
  "| Atual | `valor_cons_real` da aba `SICONFI painel munic` | Valor usado hoje no projeto |",
  "| Restrita/rateio | `Despesas Empenhadas` + rubricas com `consorcio` e `contrato de rateio` | Leitura conservadora |",
  "| Ampla/consorcio | `Despesas Empenhadas` + qualquer rubrica com `consorcio` | Leitura abrangente de consorcios |",
  "",
  "## Resumo por ano",
  "",
  md_table(resumo_ano_md),
  "",
  "## Resumo por classe",
  "",
  md_table(resumo_classe_md),
  "",
  "## Leitura tecnica",
  "",
  "- A aba atual esta mecanicamente consistente como painel municipal anual, mas nao foi reproduzida exatamente pelas duas reconstrucoes simples feitas a partir do bruto local.",
  "- Em 2015, a base atual fica 119,3% acima da definicao restrita e 10,8% abaixo da definicao ampla.",
  "- Em 2019, a base atual fica 54,8% acima da definicao restrita e 28,7% abaixo da definicao ampla.",
  "- Portanto, a base atual provavelmente deriva de uma regra intermediaria ou de uma etapa BigQuery/documentada que nao esta integralmente preservada como script local.",
  "",
  "## Implicacao para a Base 1",
  "",
  "A comparacao MIDES x SICONFI pode continuar como auditoria financeira exploratoria, mas nao deve ser apresentada como validacao definitiva ate que a regra exata de `valor_cons_real` seja reconstruida ou escolhida explicitamente.",
  "",
  "## Recomendacao",
  "",
  "Para a proxima versao metodologica, escolher uma definicao oficial e reprocessar a Base 1 com ela:",
  "",
  "1. conservadora: apenas contrato de rateio;",
  "2. abrangente: todas as rubricas de consorcio;",
  "3. ou recuperar o SQL/script original que gerou `valor_cons_publico`.",
  "",
  "CSV detalhado: `analises/base_1_2015_2019/outputs/base_1_auditoria_siconfi_origem_2015_2019.csv`",
  "XLSX de checks: `analises/base_1_2015_2019/checks/base_1_auditoria_siconfi_origem_2015_2019.xlsx`"
)

writeLines(linhas_md, out_md, useBytes = TRUE)

message("\nResumo por ano:")
print(resumo_ano)

message("\nResumo por classe:")
print(resumo_classe)

message("\nExportado:")
message("  ", out_csv)
message("  ", out_xlsx)
message("  ", out_md)
