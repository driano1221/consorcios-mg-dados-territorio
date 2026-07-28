# =============================================================================
# 07_auditoria_fora_cadastro_mg.R
# Auditoria de candidatos fora do cadastro MG
#
# Objetivo:
#   Listar CNPJs que aparecem em fontes externas (MUNIC/CNM) com vinculos em MG,
#   mas nao fazem parte dos 223 consorcios MG do cadastro IPEA usado no painel v2.
#
# Este script NAO altera o painel principal. Ele gera uma base auxiliar para
# revisao metodologica do universo cadastral.
# =============================================================================

library(dplyr)
library(readr)
library(readxl)
library(stringr)

base_path  <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/base_consorcios_v10_2026-04-30.xlsx"
cnm_path   <- "C:/IPEA/dados cnm/data/base_unificada_municipio_consorcio.csv"
out_dir    <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/outputs/auditoria"
out_csv    <- file.path(out_dir, paste0(format(Sys.Date(), "%Y-%m-%d"), "_candidatos_fora_cadastro_mg.csv"))

if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

limpa_cnpj <- function(x) {
  x |>
    as.character() |>
    str_remove_all("[^0-9]") |>
    str_pad(width = 14, side = "left", pad = "0")
}

cadastro <- read_excel(base_path, sheet = "Cadastro") |>
  mutate(cnpj = limpa_cnpj(cnpj)) |>
  select(cnpj, uf_cadastro = uf, razao_social_cadastro = razao_social, sigla_cadastro = sigla, situacao_cadastro = situacao)

cadastro_mg <- cadastro |>
  filter(uf_cadastro == "MG")

munic_fora <- read_excel(base_path, sheet = "MUNIC participacao") |>
  filter(uf_mun == "MG") |>
  mutate(
    cnpj_consorcio = limpa_cnpj(cnpj_consorcio),
    cod_ibge_6 = as.character(cod_ibge)
  ) |>
  filter(!cnpj_consorcio %in% cadastro_mg$cnpj) |>
  summarise(
    aparece_munic = TRUE,
    n_pares_munic = n_distinct(paste(cod_ibge_6, cnpj_consorcio)),
    n_municipios_munic = n_distinct(cod_ibge_6),
    nome_munic = first(na.omit(sigla)),
    setores_munic = paste(sort(unique(na.omit(setor))), collapse = ", "),
    .by = c(cnpj_consorcio)
  )

pares_munic_fora <- read_excel(base_path, sheet = "MUNIC participacao") |>
  filter(uf_mun == "MG") |>
  mutate(
    cnpj_consorcio = limpa_cnpj(cnpj_consorcio),
    cod_ibge_6 = as.character(cod_ibge)
  ) |>
  filter(!cnpj_consorcio %in% cadastro_mg$cnpj) |>
  distinct(cod_ibge_6, cnpj_consorcio) |>
  mutate(fonte_par = "MUNIC")

cnm_fora <- read_delim(
  cnm_path,
  delim = ";",
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
) |>
  mutate(
    consorcio_cnpj = str_replace(
      consorcio_cnpj,
      fixed("09.237.626/0001.90"),
      "09.237.626/0001-90"
    ),
    cnpj_consorcio = limpa_cnpj(consorcio_cnpj),
    cod_ibge_6 = as.character(municipio_ibge)
  ) |>
  filter(str_starts(cod_ibge_6, "31")) |>
  distinct(cod_ibge_6, cnpj_consorcio, .keep_all = TRUE) |>
  filter(!cnpj_consorcio %in% cadastro_mg$cnpj) |>
  summarise(
    aparece_cnm = TRUE,
    n_pares_cnm = n_distinct(paste(cod_ibge_6, cnpj_consorcio)),
    n_municipios_cnm = n_distinct(cod_ibge_6),
    nome_cnm = first(na.omit(consorcio_nome)),
    sigla_cnm = first(na.omit(consorcio_sigla)),
    uf_sede_cnm = first(na.omit(sede_municipio_uf)),
    status_cnm = first(na.omit(consorcio_status)),
    .by = c(cnpj_consorcio)
  )

pares_cnm_fora <- read_delim(
  cnm_path,
  delim = ";",
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
) |>
  mutate(
    consorcio_cnpj = str_replace(
      consorcio_cnpj,
      fixed("09.237.626/0001.90"),
      "09.237.626/0001-90"
    ),
    cnpj_consorcio = limpa_cnpj(consorcio_cnpj),
    cod_ibge_6 = as.character(municipio_ibge)
  ) |>
  filter(str_starts(cod_ibge_6, "31")) |>
  distinct(cod_ibge_6, cnpj_consorcio) |>
  filter(!cnpj_consorcio %in% cadastro_mg$cnpj) |>
  mutate(fonte_par = "CNM")

pares_fora <- bind_rows(pares_munic_fora, pares_cnm_fora) |>
  distinct(cod_ibge_6, cnpj_consorcio) |>
  summarise(
    n_pares_mg = n(),
    n_municipios_mg = n_distinct(cod_ibge_6),
    .by = c(cnpj_consorcio)
  )

candidatos <- full_join(munic_fora, cnm_fora, by = "cnpj_consorcio") |>
  left_join(pares_fora, by = "cnpj_consorcio") |>
  left_join(cadastro, by = join_by(cnpj_consorcio == cnpj)) |>
  mutate(
    aparece_munic = if_else(is.na(aparece_munic), FALSE, aparece_munic),
    aparece_cnm = if_else(is.na(aparece_cnm), FALSE, aparece_cnm),
    aparece_mides = NA,
    fonte = case_when(
      aparece_munic & aparece_cnm ~ "MUNIC+CNM",
      aparece_munic ~ "MUNIC",
      aparece_cnm ~ "CNM"
    ),
    nome_consorcio = coalesce(nome_cnm, nome_munic, razao_social_cadastro),
    sigla = coalesce(sigla_cnm, nome_munic, sigla_cadastro),
    status_cadastro = case_when(
      is.na(uf_cadastro) ~ "fora_do_cadastro_ipea",
      uf_cadastro != "MG" ~ paste0("cadastro_ipea_outra_uf_", uf_cadastro),
      TRUE ~ "cadastro_mg"
    ),
    motivo_fora_painel = case_when(
      status_cadastro == "fora_do_cadastro_ipea" ~ "CNPJ ausente dos 223 consorcios MG do cadastro IPEA",
      str_starts(status_cadastro, "cadastro_ipea_outra_uf") ~ "CNPJ existe no cadastro IPEA, mas com sede fora de MG",
      TRUE ~ "verificar"
    ),
    prioridade_revisao = case_when(
      n_pares_mg >= 100 ~ "alta",
      n_pares_mg >= 20 ~ "media",
      TRUE ~ "baixa"
    )
  ) |>
  select(
    fonte, cnpj_consorcio, nome_consorcio, sigla, uf_sede_cnm,
    n_pares_mg, n_municipios_mg, n_pares_munic, n_pares_cnm,
    aparece_munic, aparece_cnm, aparece_mides,
    status_cadastro, situacao_cadastro, status_cnm,
    setores_munic, motivo_fora_painel, prioridade_revisao
  ) |>
  arrange(desc(n_pares_mg), cnpj_consorcio)

write_csv(candidatos, out_csv, na = "")

message("Exportado: ", out_csv)
message("CNPJs candidatos: ", nrow(candidatos))
message("Pares MG unicos fora do painel: ", sum(candidatos$n_pares_mg, na.rm = TRUE))
