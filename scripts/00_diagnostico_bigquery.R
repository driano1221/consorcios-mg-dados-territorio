# =============================================================================
# 00_diagnostico_bigquery.R
# Re-verifica cobertura do MIDES no BigQuery
#
# Rodado em: 2026-05-05 (versão inicial: 11 estados, MG até 2021)
# Motivação: documentação oficial agora mostra 16 estados e cobertura até 2024
#
# O que verifica:
#   1. Quais estados estão disponíveis agora (esperamos BA, ES, GO, RN, RO, TO)
#   2. Range de anos MG (será que foi além de 2021?)
#   3. Quantas linhas bateriam com nossos CNPJs nos novos estados
# =============================================================================

library(basedosdados)
library(dplyr)
library(readxl)

set_billing_id("ipea-consorcios")

# CNPJs do cadastro
cnpjs <- read_excel(
  "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/base_consorcios_v10_2026-04-30.xlsx",
  sheet = "Cadastro"
) |> pull(cnpj) |> as.character()

message("CNPJs carregados: ", length(cnpjs))

# --- 1. Todos os estados disponíveis e range de anos -------------------------
message("\n[1] Contando linhas por estado e range de anos...")

estados_resumo <- bdplyr("world_wb_mides.pagamento") |>
  group_by(sigla_uf) |>
  summarise(
    n          = n(),
    ano_min    = min(ano, na.rm = TRUE),
    ano_max    = max(ano, na.rm = TRUE)
  ) |>
  arrange(sigla_uf) |>
  bd_collect()

message("\n=== ESTADOS DISPONÍVEIS NO BIGQUERY ===")
print(estados_resumo, n = Inf)

# --- 2. Range de anos de MG especificamente ----------------------------------
message("\n[2] MG — range exato de anos com os nossos CNPJs...")

mg_range <- bdplyr("world_wb_mides.pagamento") |>
  filter(
    sigla_uf         == "MG",
    documento_credor %in% cnpjs
  ) |>
  summarise(
    n       = n(),
    ano_min = min(ano, na.rm = TRUE),
    ano_max = max(ano, na.rm = TRUE)
  ) |>
  bd_collect()

message("\n=== MG COM NOSSOS CNPJs ===")
print(mg_range)

# --- 3. Novos estados — quantos CNPJs batem? ---------------------------------
novos_estados <- c("BA", "ES", "GO", "RN", "RO", "TO")

message("\n[3] Novos estados — matches com nossos CNPJs...")

novos_resumo <- bdplyr("world_wb_mides.pagamento") |>
  filter(
    sigla_uf         %in% novos_estados,
    documento_credor %in% cnpjs
  ) |>
  group_by(sigla_uf) |>
  summarise(
    n_linhas    = n(),
    n_consorcios = n_distinct(documento_credor),
    n_municipios = n_distinct(id_municipio),
    ano_min     = min(ano, na.rm = TRUE),
    ano_max     = max(ano, na.rm = TRUE)
  ) |>
  arrange(sigla_uf) |>
  bd_collect()

message("\n=== NOVOS ESTADOS COM NOSSOS CNPJs ===")
print(novos_resumo, n = Inf)

message("\nDiagnóstico concluído.")
