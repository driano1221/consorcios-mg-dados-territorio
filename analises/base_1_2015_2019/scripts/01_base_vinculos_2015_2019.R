# =============================================================================
# 01_base_vinculos_2015_2019.R
# Base 1 - vinculos MIDES/MUNIC em 2015 e 2019
#
# Unidade: municipio x consorcio x ano
#
# Esta analise e tangente ao painel principal v2. O objetivo e criar um recorte
# temporal comparavel entre MIDES e MUNIC. CNM fica fora; SICONFI entra apenas
# na proxima etapa, como validacao financeira no nivel municipio x ano.
# =============================================================================

library(dplyr)
library(readxl)
library(readr)
library(writexl)
library(stringr)

anos_base <- c(2015L, 2019L)

project_dir <- normalizePath(
  file.path(getwd()),
  winslash = "/",
  mustWork = TRUE
)

base_candidates <- Sys.glob(
  "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para an*lise/base_consorcios_v10_2026-04-30.xlsx"
)

if (length(base_candidates) == 0L) {
  stop("Planilha base_consorcios_v10_2026-04-30.xlsx nao encontrada em C:/IPEA.")
}

base_path <- base_candidates[[1]]
out_dir <- file.path(project_dir, "analises/base_1_2015_2019/outputs")
check_dir <- file.path(project_dir, "analises/base_1_2015_2019/checks")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(check_dir, recursive = TRUE, showWarnings = FALSE)

message("Carregando fontes...")
message("  Projeto: ", project_dir)
message("  Cadastro/MUNIC: ", base_path)

anual <- readRDS(file.path(project_dir, "dados/processado/painel_mg_anual.rds"))

cadastro_mg <- read_excel(base_path, sheet = "Cadastro") |>
  filter(uf == "MG") |>
  mutate(cnpj = str_pad(as.character(cnpj), width = 14, side = "left", pad = "0")) |>
  select(
    cnpj,
    razao_social,
    sigla,
    setores,
    situacao,
    ano_fundacao,
    tem_evidencia
  )

munic_mg <- read_excel(base_path, sheet = "MUNIC participacao") |>
  filter(uf_mun == "MG", ano %in% anos_base) |>
  mutate(
    cod_ibge_6 = str_sub(as.character(cod_ibge), 1, 6),
    cnpj_consorcio = str_pad(as.character(cnpj_consorcio), width = 14, side = "left", pad = "0"),
    ano = as.integer(ano),
    setor = as.character(setor)
  ) |>
  filter(cnpj_consorcio %in% cadastro_mg$cnpj)

nomes_municipios <- bind_rows(
  read_excel(base_path, sheet = "MUNIC participacao") |>
    filter(uf_mun == "MG") |>
    transmute(
      cod_ibge_6 = str_sub(as.character(cod_ibge), 1, 6),
      municipio = as.character(municipio)
    ),
  read_excel(base_path, sheet = "SICONFI painel munic") |>
    filter(uf == "MG") |>
    transmute(
      cod_ibge_6 = str_sub(as.character(cod_ibge), 1, 6),
      municipio = as.character(municipio)
    )
) |>
  filter(!is.na(cod_ibge_6), !is.na(municipio)) |>
  summarise(municipio = first(sort(unique(municipio))), .by = cod_ibge_6)

mides_2015_2019 <- anual |>
  filter(ano %in% anos_base) |>
  mutate(
    cod_ibge_6 = str_sub(as.character(id_municipio), 1, 6),
    id_municipio = as.character(id_municipio),
    cnpj_consorcio = str_pad(as.character(documento_credor), width = 14, side = "left", pad = "0"),
    ano = as.integer(ano)
  ) |>
  filter(cnpj_consorcio %in% cadastro_mg$cnpj) |>
  summarise(
    id_municipio = first(id_municipio),
    nome_credor_freq = first(nome_credor_freq),
    valor_mides_corrente = sum(valor_corrente, na.rm = TRUE),
    valor_mides_restos = sum(valor_restos, na.rm = TRUE),
    valor_mides_total = sum(valor_total, na.rm = TRUE),
    n_transacoes_mides = sum(n_transacoes, na.rm = TRUE),
    tem_pagamento_corrente = any(tem_pagamento_corrente, na.rm = TRUE),
    .by = c(cod_ibge_6, cnpj_consorcio, ano)
  ) |>
  mutate(tem_mides = TRUE)

munic_2015_2019 <- munic_mg |>
  summarise(
    tem_munic = TRUE,
    setores_munic = paste(sort(unique(na.omit(setor))), collapse = ", "),
    n_setores_munic = n_distinct(setor, na.rm = TRUE),
    .by = c(cod_ibge_6, cnpj_consorcio, ano)
  )

message("Montando uniao MIDES/MUNIC...")

base_vinculos <- full_join(
  mides_2015_2019,
  munic_2015_2019,
  by = join_by(cod_ibge_6, cnpj_consorcio, ano)
) |>
  mutate(
    tem_mides = if_else(is.na(tem_mides), FALSE, tem_mides),
    tem_munic = if_else(is.na(tem_munic), FALSE, tem_munic),
    valor_mides_corrente = if_else(is.na(valor_mides_corrente), 0, valor_mides_corrente),
    valor_mides_restos = if_else(is.na(valor_mides_restos), 0, valor_mides_restos),
    valor_mides_total = if_else(is.na(valor_mides_total), 0, valor_mides_total),
    n_transacoes_mides = if_else(is.na(n_transacoes_mides), 0, n_transacoes_mides),
    tem_pagamento_corrente = if_else(is.na(tem_pagamento_corrente), FALSE, tem_pagamento_corrente),
    n_setores_munic = if_else(is.na(n_setores_munic), 0L, n_setores_munic),
    grupo_vinculo = case_when(
      tem_mides & tem_munic ~ "MIDES+MUNIC",
      tem_mides & !tem_munic ~ "MIDES_only",
      !tem_mides & tem_munic ~ "MUNIC_only",
      TRUE ~ "sem_fonte"
    )
  ) |>
  left_join(
    cadastro_mg,
    by = join_by(cnpj_consorcio == cnpj)
  ) |>
  left_join(nomes_municipios, by = join_by(cod_ibge_6)) |>
  mutate(
    setores_consolidado = case_when(
      !is.na(setores) & setores != "" ~ setores,
      !is.na(setores_munic) & setores_munic != "" ~ paste0(setores_munic, " [via MUNIC]"),
      TRUE ~ NA_character_
    )
  ) |>
  select(
    ano,
    cod_ibge_6,
    municipio,
    id_municipio,
    cnpj_consorcio,
    sigla,
    razao_social,
    setores,
    setores_consolidado,
    situacao,
    ano_fundacao,
    tem_evidencia,
    tem_mides,
    valor_mides_corrente,
    valor_mides_restos,
    valor_mides_total,
    n_transacoes_mides,
    tem_pagamento_corrente,
    nome_credor_freq,
    tem_munic,
    setores_munic,
    n_setores_munic,
    grupo_vinculo
  ) |>
  arrange(ano, cod_ibge_6, sigla, cnpj_consorcio)

resumo_grupo <- base_vinculos |>
  summarise(
    n_linhas = n(),
    n_municipios = n_distinct(cod_ibge_6),
    n_consorcios = n_distinct(cnpj_consorcio),
    valor_mides_corrente = sum(valor_mides_corrente, na.rm = TRUE),
    valor_mides_total = sum(valor_mides_total, na.rm = TRUE),
    .by = c(ano, grupo_vinculo)
  ) |>
  arrange(ano, grupo_vinculo)

resumo_geral <- tibble::tibble(
  indicador = c(
    "linhas_base_1",
    "municipios",
    "consorcios",
    "linhas_mides_munic",
    "linhas_mides_only",
    "linhas_munic_only",
    "valor_mides_corrente",
    "valor_mides_total"
  ),
  valor = c(
    nrow(base_vinculos),
    n_distinct(base_vinculos$cod_ibge_6),
    n_distinct(base_vinculos$cnpj_consorcio),
    sum(base_vinculos$grupo_vinculo == "MIDES+MUNIC"),
    sum(base_vinculos$grupo_vinculo == "MIDES_only"),
    sum(base_vinculos$grupo_vinculo == "MUNIC_only"),
    sum(base_vinculos$valor_mides_corrente, na.rm = TRUE),
    sum(base_vinculos$valor_mides_total, na.rm = TRUE)
  )
)

out_csv <- file.path(out_dir, "base_1_vinculos_2015_2019.csv")
out_xlsx <- file.path(out_dir, "base_1_vinculos_2015_2019.xlsx")
check_csv <- file.path(check_dir, "base_1_resumo_vinculos_2015_2019.csv")
check_xlsx <- file.path(check_dir, "base_1_checks_vinculos_2015_2019.xlsx")

write_csv(base_vinculos, out_csv)
write_xlsx(base_vinculos, out_xlsx)
write_csv(resumo_grupo, check_csv)
write_xlsx(
  list(
    resumo_geral = resumo_geral,
    resumo_grupo = resumo_grupo
  ),
  check_xlsx
)

message("\nResumo por ano/grupo:")
print(resumo_grupo)

message("\nExportado:")
message("  ", out_csv)
message("  ", out_xlsx)
message("  ", check_csv)
message("  ", check_xlsx)
message("Linhas: ", nrow(base_vinculos), " | Colunas: ", ncol(base_vinculos))
