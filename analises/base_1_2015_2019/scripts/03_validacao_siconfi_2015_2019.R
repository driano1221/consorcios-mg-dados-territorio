# =============================================================================
# 03_validacao_siconfi_2015_2019.R
# Base 1 - validacao financeira MIDES x SICONFI
#
# Unidade: municipio x ano
#
# SICONFI nao identifica CNPJ destino. Por isso, a comparacao correta nesta
# etapa e entre:
#   - soma MIDES dos pagamentos correntes do municipio a consorcios no ano; e
#   - valor SICONFI declarado pelo municipio como transferencia a consorcios.
#
# A classificacao principal usa a soma MIDES dos 1.194 CNPJs do cadastro IPEA,
# pois o SICONFI nao informa o CNPJ/UF do consorcio destino. Os valores da Base
# 1 restrita aos 223 consorcios MG tambem ficam no output como contexto.
# =============================================================================

library(dplyr)
library(readxl)
library(readr)
library(writexl)
library(stringr)

anos_base <- c(2015L, 2019L)
tolerancia_abs <- 10000
tolerancia_rel <- 0.10

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

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

vinculos_path <- file.path(out_dir, "base_1_vinculos_2015_2019.csv")
if (!file.exists(vinculos_path)) {
  stop("Base de vinculos nao encontrada. Rode scripts/01_base_vinculos_2015_2019.R antes.")
}

message("Carregando Base 1 e SICONFI...")

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

siconfi <- read_excel(base_path, sheet = "SICONFI painel munic") |>
  filter(uf == "MG", ano %in% anos_base, nota_cobertura == "ok") |>
  transmute(
    ano = as.integer(ano),
    cod_ibge_6 = str_sub(as.character(cod_ibge), 1, 6),
    municipio_siconfi = as.character(municipio),
    siconfi_paga_consorcio = as.logical(paga_consorcio),
    valor_siconfi_consorcio = as.numeric(valor_cons_real),
    valor_siconfi_sflu = as.numeric(valor_sflu_real),
    valor_siconfi_total = as.numeric(valor_total_real),
    nota_cobertura = as.character(nota_cobertura)
  )

validacao <- full_join(
  mides_munic_mun_ano,
  siconfi,
  by = join_by(ano, cod_ibge_6)
) |>
  full_join(
    mides_cadastro_1194_mun_ano,
    by = join_by(ano, cod_ibge_6)
  ) |>
  mutate(
    municipio = coalesce(municipio, municipio_siconfi),
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
        n_consorcios_base1, valor_siconfi_consorcio,
        valor_siconfi_sflu, valor_siconfi_total
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
    ),
    passa_tolerancia = diferenca_abs_modulo <= tolerancia_abs | diferenca_rel <= tolerancia_rel,
    classe_validacao = case_when(
      tem_mides_valor & tem_siconfi_valor & passa_tolerancia ~ "congruente",
      tem_mides_valor & tem_siconfi_valor & !passa_tolerancia ~ "divergente_valor",
      tem_mides_valor & !tem_siconfi_valor ~ "mides_sem_siconfi",
      !tem_mides_valor & tem_siconfi_valor ~ "siconfi_sem_mides",
      !tem_mides_valor & !tem_siconfi_valor & n_pares_munic > 0 ~ "munic_sem_fluxo_financeiro",
      TRUE ~ "sem_movimento"
    )
  ) |>
  filter(classe_validacao != "sem_movimento") |>
  select(
    ano,
    cod_ibge_6,
    municipio,
    valor_mides_corrente_cadastro_1194,
    valor_mides_restos_cadastro_1194,
    valor_mides_total_cadastro_1194,
    valor_mides_corrente_base1_223,
    valor_mides_restos_base1_223,
    valor_mides_total_base1_223,
    valor_siconfi_consorcio,
    valor_siconfi_sflu,
    valor_siconfi_total,
    diferenca_abs,
    diferenca_abs_modulo,
    diferenca_rel,
    passa_tolerancia,
    classe_validacao,
    tem_mides_valor,
    tem_siconfi_valor,
    siconfi_paga_consorcio,
    tem_siconfi_linha,
    n_pares_total_base1,
    n_pares_mides,
    n_pares_munic,
    n_pares_mides_munic,
    n_pares_mides_only,
    n_pares_munic_only,
    n_consorcios_base1,
    n_pares_mides_cadastro_1194,
    nota_cobertura
  ) |>
  arrange(ano, classe_validacao, desc(diferenca_abs_modulo), cod_ibge_6)

resumo_classe <- validacao |>
  summarise(
    n_municipio_ano = n(),
    n_municipios = n_distinct(cod_ibge_6),
    valor_mides_corrente_cadastro_1194 = sum(valor_mides_corrente_cadastro_1194, na.rm = TRUE),
    valor_mides_corrente_base1_223 = sum(valor_mides_corrente_base1_223, na.rm = TRUE),
    valor_siconfi_consorcio = sum(valor_siconfi_consorcio, na.rm = TRUE),
    diferenca_abs_liquida = sum(diferenca_abs, na.rm = TRUE),
    mediana_diferenca_abs_modulo = median(diferenca_abs_modulo, na.rm = TRUE),
    .by = c(ano, classe_validacao)
  ) |>
  arrange(ano, classe_validacao)

resumo_executivo <- validacao |>
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
    valor_mides_corrente_base1_223 = sum(valor_mides_corrente_base1_223, na.rm = TRUE),
    valor_siconfi_consorcio = sum(valor_siconfi_consorcio, na.rm = TRUE),
    .by = ano
  ) |>
  arrange(ano)

top_divergencias <- validacao |>
  filter(classe_validacao == "divergente_valor") |>
  arrange(desc(diferenca_abs_modulo)) |>
  head(50)

siconfi_sem_mides_top <- validacao |>
  filter(classe_validacao == "siconfi_sem_mides") |>
  arrange(desc(valor_siconfi_consorcio)) |>
  head(50)

mides_sem_siconfi_top <- validacao |>
  filter(classe_validacao == "mides_sem_siconfi") |>
  arrange(desc(valor_mides_corrente_cadastro_1194)) |>
  head(50)

out_csv <- file.path(out_dir, "base_1_validacao_siconfi_2015_2019.csv")
out_xlsx <- file.path(out_dir, "base_1_validacao_siconfi_2015_2019.xlsx")
resumo_csv <- file.path(out_dir, "base_1_resumo_executivo.csv")
check_xlsx <- file.path(check_dir, "base_1_checks_validacao_siconfi_2015_2019.xlsx")

write_csv(validacao, out_csv)
write_xlsx(validacao, out_xlsx)
write_csv(resumo_executivo, resumo_csv)
write_xlsx(
  list(
    resumo_executivo = resumo_executivo,
    resumo_classe = resumo_classe,
    top_divergencias = top_divergencias,
    siconfi_sem_mides_top = siconfi_sem_mides_top,
    mides_sem_siconfi_top = mides_sem_siconfi_top
  ),
  check_xlsx
)

out_md <- file.path(check_dir, "VALIDACAO_SICONFI_base_1_2015_2019.md")
linhas_md <- c(
  "# Validacao SICONFI - Base 1 2015/2019",
  "",
  "## Regra",
  "",
  "- Unidade: municipio x ano.",
  "- Comparacao principal: `valor_mides_corrente_cadastro_1194` vs `valor_cons_real` do SICONFI.",
  "- A Base 1 restrita aos 223 consorcios MG permanece no output como contexto de vinculos.",
  "- SICONFI nao cria par municipio x consorcio.",
  paste0("- Tolerancia: ate R$ ", format(tolerancia_abs, big.mark = ".", decimal.mark = ","), " ou ate ", tolerancia_rel * 100, "% de diferenca relativa."),
  "",
  "## Resumo Executivo",
  "",
  paste(capture.output(print(resumo_executivo, n = Inf)), collapse = "\n"),
  "",
  "## Resumo Por Classe",
  "",
  paste(capture.output(print(resumo_classe, n = Inf)), collapse = "\n"),
  "",
  "## Observacoes",
  "",
  "- `congruente`: MIDES e SICONFI positivos e dentro da tolerancia.",
  "- `divergente_valor`: MIDES e SICONFI positivos, mas fora da tolerancia.",
  "- `mides_sem_siconfi`: MIDES positivo e SICONFI zero/ausente.",
  "- `siconfi_sem_mides`: SICONFI positivo e MIDES zero no universo dos 1.194 CNPJs do cadastro IPEA.",
  "- `munic_sem_fluxo_financeiro`: MUNIC declarou vinculo, mas MIDES e SICONFI nao mostram fluxo financeiro no municipio-ano.",
  "",
  paste0("Output detalhado: `", out_csv, "`"),
  paste0("Checks: `", check_xlsx, "`")
)

writeLines(linhas_md, out_md, useBytes = TRUE)

message("\nResumo executivo:")
print(resumo_executivo)

message("\nResumo por classe:")
print(resumo_classe)

message("\nExportado:")
message("  ", out_csv)
message("  ", out_xlsx)
message("  ", resumo_csv)
message("  ", check_xlsx)
message("  ", out_md)
