# =============================================================================
# 02_baixar_mides_nacional.R
#
# Baixa todas as transacoes MIDES disponiveis no BigQuery cujo credor pertence
# aos 1.194 CNPJs originais do cadastro IPEA. A UF identifica o municipio
# pagador, nao necessariamente a sede do consorcio.
# =============================================================================

invisible(Sys.setlocale("LC_ALL", "Portuguese_Brazil.1252"))

library(basedosdados)
library(dplyr)
library(stringr)

project_dir <- "."
out_dir <- file.path(project_dir, "analises", "base_nacional", "outputs")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

crosswalk_path <- file.path(out_dir, "crosswalk_cnpj_matriz_filial_nacional.rds")
if (!file.exists(crosswalk_path)) stop("Execute primeiro 01_consolidar_identidade_cnpj.R")

crosswalk <- readRDS(crosswalk_path)
cnpjs <- sort(unique(crosswalk$cnpj_original))
if (length(cnpjs) != 1194L) stop("A consulta deveria receber 1.194 CNPJs originais.")

billing_id <- Sys.getenv("MIDES_BILLING_ID", unset = "ipea-consorcios")
set_billing_id(billing_id)

message("Consultando cobertura MIDES para os CNPJs IPEA...")

tabela <- bdplyr("world_wb_mides.pagamento")

cobertura <- tabela |>
  filter(documento_credor %in% cnpjs) |>
  group_by(sigla_uf) |>
  summarise(
    n_linhas = n(),
    n_cnpjs = n_distinct(documento_credor),
    n_municipios = n_distinct(id_municipio),
    ano_min = min(ano, na.rm = TRUE),
    ano_max = max(ano, na.rm = TRUE)
  ) |>
  arrange(sigla_uf) |>
  bd_collect()

message("Baixando transacoes MIDES das UFs com correspondencia no cadastro...")

mides <- tabela |>
  filter(documento_credor %in% cnpjs) |>
  select(
    sigla_uf, ano, data, id_municipio,
    nome_credor, documento_credor,
    indicador_restos_pagar, fonte,
    valor_final, valor_liquido_recebido
  ) |>
  bd_collect() |>
  mutate(
    sigla_uf = as.character(sigla_uf),
    ano = as.integer(ano),
    id_municipio = as.character(id_municipio),
    documento_credor = str_pad(as.character(documento_credor), 14, pad = "0"),
    nome_credor = as.character(nome_credor),
    valor_final = as.numeric(valor_final),
    valor_liquido_recebido = as.numeric(valor_liquido_recebido)
  )

if (nrow(mides) != sum(cobertura$n_linhas)) stop("Contagem baixada diverge do diagnostico BigQuery.")
if (!all(mides$documento_credor %in% cnpjs)) stop("Download contem CNPJ fora do cadastro IPEA.")
if (any(is.na(mides$sigla_uf))) stop("Download filtrado contem UF pagadora ausente.")

saveRDS(mides, file.path(out_dir, "mides_ipea_nacional_transacoes.rds"), compress = "xz")
write.csv(cobertura, file.path(out_dir, "mides_ipea_nacional_cobertura_download.csv"), row.names = FALSE, na = "")

message("Download MIDES nacional concluido.")
print(cobertura, n = Inf)
message("Linhas: ", nrow(mides))
message("CNPJs: ", n_distinct(mides$documento_credor))
message("Municipios: ", n_distinct(mides$id_municipio))
