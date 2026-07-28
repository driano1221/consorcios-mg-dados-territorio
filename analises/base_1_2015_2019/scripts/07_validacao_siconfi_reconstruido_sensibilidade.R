# =============================================================================
# 07_validacao_siconfi_reconstruido_sensibilidade.R
# Base 1 - sensibilidade da validacao SICONFI reconstruido
#
# Compara a classificacao usando:
#   - tolerancia absoluta fixa: R$ 10.000
#   - tolerancia relativa: 5% e 10%
#
# SICONFI usado:
#   consorcio_pagas = qualquer rubrica com "consorcio" + Despesas Pagas.
# =============================================================================

library(dplyr)
library(readr)
library(readxl)
library(writexl)
library(stringr)

anos_base <- c(2015L, 2019L)
tolerancia_abs <- 10000
tolerancias_rel <- c(0.05, 0.10)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

base_candidates <- Sys.glob(
  "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para an*lise/base_consorcios_v10_2026-04-30.xlsx"
)

if (length(base_candidates) == 0L) {
  stop("Planilha base_consorcios_v10_2026-04-30.xlsx nao encontrada.")
}

base_path <- base_candidates[[1]]
out_dir <- file.path(project_dir, "analises/base_1_2015_2019/outputs")
check_dir <- file.path(project_dir, "analises/base_1_2015_2019/checks")

vinculos_path <- file.path(out_dir, "base_1_vinculos_2015_2019.csv")
siconfi_rec_path <- file.path(out_dir, "base_1_siconfi_reconstruido_2015_2019.csv")

if (!file.exists(vinculos_path)) {
  stop("Base de vinculos nao encontrada. Rode 01_base_vinculos_2015_2019.R.")
}
if (!file.exists(siconfi_rec_path)) {
  stop("SICONFI reconstruido nao encontrado. Rode 05_reconstruir_siconfi_base_dos_dados.R.")
}

vinculos <- read_csv(vinculos_path, show_col_types = FALSE) |>
  mutate(
    ano = as.integer(ano),
    cod_ibge_6 = str_sub(as.character(cod_ibge_6), 1, 6),
    cnpj_consorcio = str_pad(as.character(cnpj_consorcio), width = 14, side = "left", pad = "0")
  )

cadastro <- read_excel(base_path, sheet = "Cadastro") |>
  transmute(cnpj = str_pad(as.character(cnpj), width = 14, side = "left", pad = "0"))

anual <- readRDS(file.path(project_dir, "dados/processado/painel_mg_anual.rds")) |>
  mutate(
    ano = as.integer(ano),
    cod_ibge_6 = str_sub(as.character(id_municipio), 1, 6),
    cnpj_consorcio = str_pad(as.character(documento_credor), width = 14, side = "left", pad = "0")
  ) |>
  filter(ano %in% anos_base, cnpj_consorcio %in% cadastro$cnpj)

mides_cadastro_1194_mun_ano <- anual |>
  summarise(
    valor_mides_corrente_cadastro_1194 = sum(valor_corrente, na.rm = TRUE),
    valor_mides_restos_cadastro_1194 = sum(valor_restos, na.rm = TRUE),
    valor_mides_total_cadastro_1194 = sum(valor_total, na.rm = TRUE),
    n_pares_mides_cadastro_1194 = n_distinct(cnpj_consorcio),
    .by = c(ano, cod_ibge_6)
  )

mides_munic_mun_ano <- vinculos |>
  summarise(
    municipio = first(na.omit(municipio)),
    valor_mides_corrente_base1_223 = sum(valor_mides_corrente, na.rm = TRUE),
    valor_mides_restos_base1_223 = sum(valor_mides_restos, na.rm = TRUE),
    valor_mides_total_base1_223 = sum(valor_mides_total, na.rm = TRUE),
    n_pares_total_base1 = n(),
    n_pares_mides = sum(tem_mides, na.rm = TRUE),
    n_pares_munic = sum(tem_munic, na.rm = TRUE),
    n_pares_mides_munic = sum(grupo_vinculo == "MIDES+MUNIC", na.rm = TRUE),
    n_pares_mides_only = sum(grupo_vinculo == "MIDES_only", na.rm = TRUE),
    n_pares_munic_only = sum(grupo_vinculo == "MUNIC_only", na.rm = TRUE),
    n_consorcios_base1 = n_distinct(cnpj_consorcio),
    .by = c(ano, cod_ibge_6)
  )

siconfi_reconstruido <- read_csv(siconfi_rec_path, show_col_types = FALSE) |>
  filter(ano %in% anos_base, variante_recomendada == "consorcio_pagas") |>
  transmute(
    ano = as.integer(ano),
    cod_ibge_6 = str_sub(as.character(cod_ibge_6), 1, 6),
    municipio_siconfi = as.character(municipio),
    valor_siconfi_consorcio = as.numeric(valor_siconfi_reconstruido),
    valor_siconfi_herdado = as.numeric(valor_siconfi_atual),
    siconfi_paga_consorcio = valor_siconfi_reconstruido > 0,
    regra_siconfi = as.character(variante_recomendada)
  )

base_validacao <- full_join(
  mides_munic_mun_ano,
  siconfi_reconstruido,
  by = join_by(ano, cod_ibge_6)
) |>
  full_join(
    mides_cadastro_1194_mun_ano,
    by = join_by(ano, cod_ibge_6)
  ) |>
  mutate(
    municipio = coalesce(municipio, municipio_siconfi),
    regra_siconfi = if_else(is.na(regra_siconfi), "consorcio_pagas", regra_siconfi),
    tem_base1 = !is.na(n_pares_total_base1),
    tem_siconfi_linha = !is.na(valor_siconfi_consorcio),
    across(
      c(
        valor_mides_corrente_base1_223,
        valor_mides_restos_base1_223,
        valor_mides_total_base1_223,
        valor_mides_corrente_cadastro_1194,
        valor_mides_restos_cadastro_1194,
        valor_mides_total_cadastro_1194,
        n_pares_total_base1, n_pares_mides, n_pares_munic,
        n_pares_mides_munic, n_pares_mides_only, n_pares_munic_only,
        n_pares_mides_cadastro_1194,
        n_consorcios_base1, valor_siconfi_consorcio, valor_siconfi_herdado
      ),
      ~if_else(is.na(.x), 0, .x)
    ),
    siconfi_paga_consorcio = if_else(is.na(siconfi_paga_consorcio), FALSE, siconfi_paga_consorcio),
    tem_mides_valor = valor_mides_corrente_cadastro_1194 > 0,
    tem_siconfi_valor = valor_siconfi_consorcio > 0,
    diferenca_abs = valor_siconfi_consorcio - valor_mides_corrente_cadastro_1194,
    diferenca_abs_modulo = abs(diferenca_abs),
    diferenca_rel = if_else(
      pmax(abs(valor_siconfi_consorcio), abs(valor_mides_corrente_cadastro_1194)) > 0,
      diferenca_abs_modulo / pmax(abs(valor_siconfi_consorcio), abs(valor_mides_corrente_cadastro_1194)),
      0
    )
  )

validacao_sensibilidade <- lapply(tolerancias_rel, function(tol_rel) {
  base_validacao |>
    mutate(
      tolerancia_rel = tol_rel,
      tolerancia_rel_pct = paste0(tol_rel * 100, "%"),
      tolerancia_abs = tolerancia_abs,
      passa_tolerancia = diferenca_abs_modulo <= tolerancia_abs | diferenca_rel <= tol_rel,
      classe_validacao = case_when(
        tem_mides_valor & tem_siconfi_valor & passa_tolerancia ~ "congruente",
        tem_mides_valor & tem_siconfi_valor & !passa_tolerancia ~ "divergente_valor",
        tem_mides_valor & !tem_siconfi_valor ~ "mides_sem_siconfi",
        !tem_mides_valor & tem_siconfi_valor ~ "siconfi_sem_mides",
        !tem_mides_valor & !tem_siconfi_valor & n_pares_munic > 0 ~ "munic_sem_fluxo_financeiro",
        TRUE ~ "sem_movimento"
      )
    )
}) |>
  bind_rows() |>
  filter(classe_validacao != "sem_movimento") |>
  arrange(tolerancia_rel, ano, classe_validacao, desc(diferenca_abs_modulo), cod_ibge_6)

resumo_executivo <- validacao_sensibilidade |>
  summarise(
    n_municipio_ano = n(),
    n_congruente = sum(classe_validacao == "congruente"),
    n_divergente_valor = sum(classe_validacao == "divergente_valor"),
    n_mides_sem_siconfi = sum(classe_validacao == "mides_sem_siconfi"),
    n_siconfi_sem_mides = sum(classe_validacao == "siconfi_sem_mides"),
    n_munic_sem_fluxo_financeiro = sum(classe_validacao == "munic_sem_fluxo_financeiro"),
    taxa_congruencia_entre_ambos = round(
      n_congruente / pmax(n_congruente + n_divergente_valor, 1) * 100,
      1
    ),
    valor_mides_corrente_cadastro_1194 = sum(valor_mides_corrente_cadastro_1194, na.rm = TRUE),
    valor_siconfi_consorcio = sum(valor_siconfi_consorcio, na.rm = TRUE),
    .by = c(tolerancia_rel_pct, tolerancia_rel, ano)
  ) |>
  arrange(tolerancia_rel, ano)

resumo_classe <- validacao_sensibilidade |>
  summarise(
    n_municipio_ano = n(),
    n_municipios = n_distinct(cod_ibge_6),
    valor_mides_corrente_cadastro_1194 = sum(valor_mides_corrente_cadastro_1194, na.rm = TRUE),
    valor_siconfi_consorcio = sum(valor_siconfi_consorcio, na.rm = TRUE),
    mediana_diferenca_abs_modulo = median(diferenca_abs_modulo, na.rm = TRUE),
    .by = c(tolerancia_rel_pct, tolerancia_rel, ano, classe_validacao)
  ) |>
  arrange(tolerancia_rel, ano, classe_validacao)

out_csv <- file.path(out_dir, "base_1_validacao_siconfi_reconstruido_sensibilidade_5_10.csv")
resumo_csv <- file.path(out_dir, "base_1_resumo_siconfi_reconstruido_sensibilidade_5_10.csv")
out_xlsx <- file.path(check_dir, "base_1_validacao_siconfi_reconstruido_sensibilidade_5_10.xlsx")
out_md <- file.path(check_dir, "VALIDACAO_SICONFI_RECONSTRUIDO_sensibilidade_5_10.md")

write_csv(validacao_sensibilidade, out_csv)
write_csv(resumo_executivo, resumo_csv)
write_xlsx(
  list(
    resumo_executivo = resumo_executivo,
    resumo_classe = resumo_classe,
    validacao_sensibilidade = validacao_sensibilidade
  ),
  out_xlsx
)

linhas_md <- c(
  "# Sensibilidade da Validacao SICONFI Reconstruido - 5% e 10%",
  "",
  "## Regra fixa",
  "",
  "- SICONFI: `consorcio_pagas`.",
  "- Tolerancia absoluta: R$ 10.000.",
  "- Tolerancias relativas testadas: 5% e 10%.",
  "",
  "## Resumo Executivo",
  "",
  paste(capture.output(print(resumo_executivo, n = Inf)), collapse = "\n"),
  "",
  "## Resumo Por Classe",
  "",
  paste(capture.output(print(resumo_classe, n = Inf)), collapse = "\n"),
  "",
  paste0("CSV detalhado: `", out_csv, "`"),
  paste0("XLSX checks: `", out_xlsx, "`")
)

writeLines(linhas_md, out_md, useBytes = TRUE)

message("\nResumo executivo:")
print(resumo_executivo, n = Inf)

message("\nExportado:")
message("  ", out_csv)
message("  ", resumo_csv)
message("  ", out_xlsx)
message("  ", out_md)
