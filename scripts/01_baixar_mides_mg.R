# =============================================================================
# 01_baixar_mides_mg.R
# Download dos dados MIDES filtrados para MG
#
# Fonte: BigQuery basedosdados.world_wb_mides.pagamento
# Filtros: sigla_uf == "MG" + documento_credor nos 1.194 CNPJs do Cadastro
# Output: ideiaMides/dados/bruto/mides_mg_atualizado.rds
#
# Investigação prévia (2026-05-05):
#   - Tabela tem 64M linhas em MG (todas despesas municipais)
#   - Com filtro CNPJs: 469.596 linhas, 161 consórcios, 2014–2021
#   - documento_credor: usar só 14 chars (CNPJ) — 16 chars são placeholders/folha
#   - fonte: 56 códigos distintos — incluir todos (rateio via múltiplas fontes)
#   - indicador_restos_pagar: baixar ambos (TRUE/FALSE), tratar depois
# =============================================================================

library(basedosdados)
library(readxl)
library(dplyr)

set_billing_id("ipea-consorcios")

# --- CNPJs dos 1.194 consórcios do Cadastro ----------------------------------
cnpjs <- read_excel(
  "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/base_consorcios_v10_2026-04-30.xlsx",
  sheet = "Cadastro"
) |>
  pull(cnpj) |>
  as.character()

message("CNPJs carregados: ", length(cnpjs))

# --- Download filtrado direto no BigQuery ------------------------------------
message("Conectando ao BigQuery...")

mides_mg <- bdplyr("world_wb_mides.pagamento") |>
  filter(
    sigla_uf         == "MG",
    documento_credor %in% cnpjs
  ) |>
  select(
    ano, data, id_municipio,
    nome_credor, documento_credor,
    indicador_restos_pagar, fonte,
    valor_final, valor_liquido_recebido
  ) |>
  bd_collect()

# --- Diagnóstico -------------------------------------------------------------
message("\n=== RESULTADO DO DOWNLOAD ===")
message("Linhas:       ", nrow(mides_mg))
message("Consórcios:   ", n_distinct(mides_mg$documento_credor))
message("Municípios:   ", n_distinct(mides_mg$id_municipio))
message("Período:      ", min(mides_mg$ano), "–", max(mides_mg$ano))
message("Restos pagar: ", sum(mides_mg$indicador_restos_pagar, na.rm = TRUE),
        " linhas TRUE")

# --- Salvar ------------------------------------------------------------------
output_path <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/dados/bruto/mides_mg_atualizado.rds"
saveRDS(mides_mg, output_path)
message("\nSalvo em: ", output_path)
