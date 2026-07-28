# =============================================================================
# 02_eda_base_vinculos_2015_2019.R
# EDA breve da Base 1 - vinculos MIDES/MUNIC 2015/2019
# =============================================================================

library(dplyr)
library(readr)
library(writexl)
library(stringr)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
base_path <- file.path(
  project_dir,
  "analises/base_1_2015_2019/outputs/base_1_vinculos_2015_2019.csv"
)
check_dir <- file.path(project_dir, "analises/base_1_2015_2019/checks")
dir.create(check_dir, recursive = TRUE, showWarnings = FALSE)

x <- read_csv(base_path, show_col_types = FALSE)

eda_dimensoes <- tibble(
  indicador = c(
    "linhas",
    "colunas",
    "anos",
    "municipios",
    "consorcios",
    "duplicatas_chave",
    "cod_ibge_invalidos",
    "cnpj_invalidos"
  ),
  valor = c(
    nrow(x),
    ncol(x),
    paste(sort(unique(x$ano)), collapse = ", "),
    n_distinct(x$cod_ibge_6),
    n_distinct(x$cnpj_consorcio),
    nrow(x) - n_distinct(paste(x$ano, x$cod_ibge_6, x$cnpj_consorcio)),
    sum(!str_detect(as.character(x$cod_ibge_6), "^31[0-9]{4}$")),
    sum(!str_detect(as.character(x$cnpj_consorcio), "^[0-9]{14}$"))
  )
)

eda_grupos <- x |>
  summarise(
    n_linhas = n(),
    n_municipios = n_distinct(cod_ibge_6),
    n_consorcios = n_distinct(cnpj_consorcio),
    valor_mides_corrente = sum(valor_mides_corrente, na.rm = TRUE),
    valor_mides_total = sum(valor_mides_total, na.rm = TRUE),
    .by = c(ano, grupo_vinculo)
  ) |>
  arrange(ano, grupo_vinculo)

eda_nas <- x |>
  summarise(across(everything(), ~sum(is.na(.x)))) |>
  tidyr::pivot_longer(everything(), names_to = "coluna", values_to = "n_na") |>
  filter(n_na > 0) |>
  mutate(pct_na = round(n_na / nrow(x) * 100, 1)) |>
  arrange(desc(n_na))

eda_flags <- tibble(
  teste = c(
    "tem_mides_TRUE_com_valor_total_zero",
    "tem_mides_FALSE_com_valor_total_positivo",
    "tem_munic_TRUE_sem_setor_munic",
    "tem_munic_FALSE_com_setor_munic",
    "pagamento_corrente_FALSE_com_valor_corrente_positivo",
    "valor_corrente_negativo",
    "valor_restos_negativo",
    "valor_total_negativo"
  ),
  n = c(
    sum(x$tem_mides & x$valor_mides_total <= 0, na.rm = TRUE),
    sum(!x$tem_mides & x$valor_mides_total > 0, na.rm = TRUE),
    sum(x$tem_munic & x$n_setores_munic <= 0, na.rm = TRUE),
    sum(!x$tem_munic & x$n_setores_munic > 0, na.rm = TRUE),
    sum(!x$tem_pagamento_corrente & x$valor_mides_corrente > 0, na.rm = TRUE),
    sum(x$valor_mides_corrente < 0, na.rm = TRUE),
    sum(x$valor_mides_restos < 0, na.rm = TRUE),
    sum(x$valor_mides_total < 0, na.rm = TRUE)
  )
)

eda_valores <- x |>
  filter(valor_mides_total > 0) |>
  summarise(
    n = n(),
    min = min(valor_mides_total),
    p01 = as.numeric(quantile(valor_mides_total, 0.01)),
    p05 = as.numeric(quantile(valor_mides_total, 0.05)),
    mediana = median(valor_mides_total),
    p95 = as.numeric(quantile(valor_mides_total, 0.95)),
    p99 = as.numeric(quantile(valor_mides_total, 0.99)),
    max = max(valor_mides_total),
    .by = ano
  ) |>
  arrange(ano)

top_valores <- x |>
  arrange(desc(valor_mides_total)) |>
  select(
    ano, cod_ibge_6, municipio, cnpj_consorcio, sigla, razao_social,
    grupo_vinculo, valor_mides_corrente, valor_mides_restos,
    valor_mides_total, n_transacoes_mides
  ) |>
  head(25)

valores_baixos <- x |>
  filter(valor_mides_total > 0, valor_mides_total <= 1000) |>
  arrange(valor_mides_total) |>
  select(
    ano, cod_ibge_6, municipio, cnpj_consorcio, sigla, razao_social,
    grupo_vinculo, valor_mides_corrente, valor_mides_restos,
    valor_mides_total, n_transacoes_mides
  )

mides_zero <- x |>
  filter(tem_mides, valor_mides_total <= 0) |>
  select(
    ano, cod_ibge_6, municipio, cnpj_consorcio, sigla, razao_social,
    grupo_vinculo, valor_mides_corrente, valor_mides_restos,
    valor_mides_total, n_transacoes_mides, tem_pagamento_corrente
  )

sigla_na <- x |>
  filter(is.na(sigla)) |>
  count(cnpj_consorcio, razao_social, sort = TRUE)

out_xlsx <- file.path(check_dir, "base_1_eda_vinculos_2015_2019.xlsx")
write_xlsx(
  list(
    dimensoes = eda_dimensoes,
    grupos = eda_grupos,
    nas = eda_nas,
    flags = eda_flags,
    valores = eda_valores,
    top_valores = top_valores,
    valores_baixos = valores_baixos,
    mides_zero = mides_zero,
    sigla_na = sigla_na
  ),
  out_xlsx
)

out_md <- file.path(check_dir, "EDA_base_1_vinculos_2015_2019.md")

linhas_md <- c(
  "# EDA - Base 1 Vinculos 2015/2019",
  "",
  paste0("Arquivo analisado: `", base_path, "`"),
  "",
  "## Dimensoes",
  "",
  paste(capture.output(print(eda_dimensoes, n = Inf)), collapse = "\n"),
  "",
  "## Grupos",
  "",
  paste(capture.output(print(eda_grupos, n = Inf)), collapse = "\n"),
  "",
  "## NAs",
  "",
  paste(capture.output(print(eda_nas, n = Inf)), collapse = "\n"),
  "",
  "## Testes De Consistencia",
  "",
  paste(capture.output(print(eda_flags, n = Inf)), collapse = "\n"),
  "",
  "## Valores MIDES",
  "",
  paste(capture.output(print(eda_valores, n = Inf)), collapse = "\n"),
  "",
  "## Observacoes",
  "",
  "- Nao ha duplicatas na chave ano + cod_ibge_6 + cnpj_consorcio.",
  "- Nao ha codigos IBGE/CNPJ invalidos no recorte.",
  "- Nao ha valores negativos.",
  "- MUNIC_only tem valores MIDES zerados por definicao.",
  "- IDs MIDES e nome_credor_freq ausentes em MUNIC_only sao esperados.",
  "- Siglas ausentes decorrem de metadados incompletos no cadastro; razao_social esta preenchida.",
  "- Valores muito baixos devem ser tratados como possiveis taxas, restos pequenos ou registros residuais; foram exportados para revisao.",
  "",
  paste0("Arquivo XLSX com detalhes: `", out_xlsx, "`")
)

writeLines(linhas_md, out_md, useBytes = TRUE)

message("EDA exportada:")
message("  ", out_md)
message("  ", out_xlsx)

