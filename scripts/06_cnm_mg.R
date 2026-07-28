# =============================================================================
# 06_cnm_mg.R
# Incorporar fonte CNM (+1 pt) ao painel universal MG → painel_universal_mg_v2
#
# Metodologia:
#   Mesmo padrão de MIDES e MUNIC:
#     1. Pré-processar base CNM (corrigir anomalias do EDA)
#     2. Filtrar aos 223 CNPJs do cadastro MG
#     3. Construir cnm_score (pares confirmados) e pares_cnm (novos pares)
#     4. Atualizar colunas cnm_confirma / pontuacao_cnm no painel_v1
#     5. Adicionar pares exclusivos do CNM (não estavam no universo anterior)
#     6. Recalcular pontuacao_total e n_fontes → painel_v2
#
# Anomalias corrigidas (identificadas no EDA de 2026-05-21):
#   - 1 CNPJ com ponto no lugar do hífen: 09.237.626/0001.90 → 09.237.626/0001-90
#   - 24 pares duplicados (mesmo municipio_ibge × consorcio_cnpj) → distinct()
#   - municipio_ibge: 6 dígitos → join direto com cod_ibge_6, sem normalização
#
# Inputs:
#   outputs/csv_base/YYYY-MM-DD_painel_universal_mg_v1.csv
#   C:/IPEA/dados cnm/data/base_unificada_municipio_consorcio.csv
#   base_consorcios_v10_2026-04-30.xlsx aba "Cadastro" (universo 223)
#
# Outputs:
#   outputs/csv_base/YYYY-MM-DD_painel_universal_mg_v2.csv/.xlsx
#
# Escala geométrica: MIDES=8 | SICONFI=4 | MUNIC=2 | CNM=1 — máximo total: 15 pts
# Nota: painel_v1 usa escala original (4+3+2) — este script converte para (8+4+2+1)
# =============================================================================

library(dplyr)
library(readr)
library(readxl)
library(writexl)
library(stringr)

# --- Caminhos ----------------------------------------------------------------
base_path  <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/base_consorcios_v10_2026-04-30.xlsx"
ideas_path <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/"
cnm_path   <- "C:/IPEA/dados cnm/data/base_unificada_municipio_consorcio.csv"
data_hoje  <- format(Sys.Date(), "%Y-%m-%d")

# --- 1. Carregar bases -------------------------------------------------------
message("Carregando bases...")

# Painel v1 — pegar o arquivo mais recente
arq_v1 <- list.files(
  paste0(ideas_path, "outputs/csv_base/"),
  pattern = "painel_universal_mg_v1\\.csv$",
  full.names = TRUE
) |> sort() |> tail(1)

if (length(arq_v1) == 0) stop("Painel v1 não encontrado em outputs/csv_base/")

message("Lendo: ", basename(arq_v1))
painel_v1 <- read_csv(arq_v1, show_col_types = FALSE) |>
  mutate(
    cod_ibge_6     = as.character(cod_ibge_6),
    id_municipio   = as.character(id_municipio),
    cnpj_consorcio = as.character(cnpj_consorcio),
    pontuacao_cnm  = as.integer(pontuacao_cnm),
    # Converter escala CSV original (4+3+2) para escala geométrica (8+4+2)
    # SICONFI: 3 → 4  |  MIDES: 4 → 8  |  MUNIC: 2 → 2 (inalterado)
    pontuacao_mides   = if_else(pontuacao_mides   > 0L, 8L, 0L),
    pontuacao_siconfi = if_else(pontuacao_siconfi > 0L, 4L, 0L)
    # pontuacao_munic permanece 2L — mesmo nas duas escalas
    # pontuacao_cnm   permanece 1L — mesmo nas duas escalas
  )

message("Painel v1: ", nrow(painel_v1), " pares × ", ncol(painel_v1), " variáveis")

# Cadastro MG — universo fixo dos 223 consórcios
cadastro_mg <- read_excel(base_path, sheet = "Cadastro") |>
  filter(uf == "MG") |>
  mutate(cnpj = as.character(cnpj)) |>
  select(cnpj, razao_social, sigla, setores, situacao, ano_fundacao, tem_evidencia)

message("Cadastro MG: ", nrow(cadastro_mg), " consórcios")

# Base CNM — separador ";" (formato do scraping)
cnm_raw <- read_delim(
  cnm_path,
  delim     = ";",
  show_col_types = FALSE,
  locale    = locale(encoding = "UTF-8")
)

message("CNM raw: ", nrow(cnm_raw), " linhas × ", ncol(cnm_raw), " colunas")

# --- 2. Pré-processar base CNM (corrigir anomalias) --------------------------
message("\nPré-processando base CNM...")

cnm_proc <- cnm_raw |>
  # Corrigir CNPJ com ponto no lugar do hífen (1 caso identificado no EDA)
  mutate(
    consorcio_cnpj = str_replace(
      consorcio_cnpj,
      fixed("09.237.626/0001.90"),
      "09.237.626/0001-90"
    )
  ) |>
  # Remover pontuação do CNPJ para casar com cnpj_consorcio do painel (14 dígitos)
  mutate(
    cnpj_consorcio = str_remove_all(consorcio_cnpj, "[.\\-/]"),
    cod_ibge_6     = as.character(municipio_ibge)   # já é 6 dígitos — join direto
  ) |>
  # Eliminar 24 pares duplicados
  distinct(cod_ibge_6, cnpj_consorcio)

message("CNM processado: ", nrow(cnm_proc), " pares únicos (município × consórcio)")
message("  Consórcios únicos no CNM: ", n_distinct(cnm_proc$cnpj_consorcio))

# --- 3. Restringir aos 223 do cadastro MG ------------------------------------
message("\nFiltrando ao cadastro MG (223 consórcios)...")

cnm_mg <- cnm_proc |>
  filter(cnpj_consorcio %in% cadastro_mg$cnpj) |>
  filter(str_starts(cod_ibge_6, "31"))   # apenas municípios de MG (IBGE começa com 31)

n_consorcios_cnm       <- n_distinct(cnm_mg$cnpj_consorcio)
n_cadastro_sem_cnm     <- n_distinct(
  cadastro_mg$cnpj[!cadastro_mg$cnpj %in% cnm_mg$cnpj_consorcio]
)

message("CNM filtrado: ", nrow(cnm_mg), " pares | ",
        n_consorcios_cnm, " consórcios confirmados (de 223) | ",
        n_cadastro_sem_cnm, " consórcios do cadastro sem registro no CNM")

# --- 4. Construir cnm_score --------------------------------------------------
cnm_score <- cnm_mg |>
  mutate(
    cnm_confirma  = TRUE,
    pontuacao_cnm = 1L
  )

# --- 5. Identificar pares novos do CNM (não estavam no painel v1) ------------
pares_novos <- cnm_mg |>
  anti_join(painel_v1, by = join_by(cod_ibge_6, cnpj_consorcio))

n_ja_no_painel <- nrow(cnm_mg) - nrow(pares_novos)

message("\n=== PARES CNM × PAINEL V1 ===")
message("  Pares CNM já no painel v1 (confirmação): ", n_ja_no_painel)
message("  Pares CNM exclusivos (novos):             ", nrow(pares_novos))

# --- 6. Atualizar cnm_confirma / pontuacao_cnm no painel v1 ------------------
message("\nAtualizando painel v1 com score CNM...")

painel_atualizado <- painel_v1 |>
  # Remover placeholders (cnm_confirma = NA, pontuacao_cnm = 0) antes do join
  select(-cnm_confirma, -pontuacao_cnm) |>
  left_join(
    cnm_score |> select(cod_ibge_6, cnpj_consorcio, cnm_confirma, pontuacao_cnm),
    by = join_by(cod_ibge_6, cnpj_consorcio)
  ) |>
  mutate(
    cnm_confirma  = if_else(is.na(cnm_confirma), FALSE, cnm_confirma),
    pontuacao_cnm = if_else(is.na(pontuacao_cnm), 0L, pontuacao_cnm)
  )

# --- 7. Construir linhas para pares CNM-only ---------------------------------
if (nrow(pares_novos) > 0) {
  message("Construindo ", nrow(pares_novos), " linhas novas para pares CNM-only...")

  linhas_cnm_only <- pares_novos |>
    # Metadados do cadastro
    left_join(
      cadastro_mg |> select(cnpj, razao_social, sigla, setores,
                             situacao, ano_fundacao, tem_evidencia),
      by = join_by(cnpj_consorcio == cnpj)
    ) |>
    mutate(
      # Identificação
      id_municipio         = NA_character_,
      nome_credor_freq     = NA_character_,
      # Setor consolidado: do cadastro quando disponível
      setores_consolidado  = setores,
      # MIDES — sem evidência
      pontuacao_mides      = 0L,
      ano_entrada_proxy    = NA_integer_,
      ultimo_ano_corrente  = NA_integer_,
      ainda_ativo          = NA,
      valor_total_periodo  = NA_real_,
      n_anos_pagamento     = 0L,
      valor_atipico        = FALSE,
      confianca_mides      = NA_character_,
      # SICONFI — sem âncora
      pontuacao_siconfi    = 0L,
      siconfi_confirma     = FALSE,
      ancora               = "sem_ancora",
      anos_siconfi_match   = NA_character_,
      n_anos_siconfi_match = 0L,
      # MUNIC — sem declaração
      pontuacao_munic      = 0L,
      munic_confirma       = FALSE,
      anos_munic           = NA_character_,
      setores_munic        = NA_character_,
      # CNM — confirmado
      cnm_confirma         = TRUE,
      pontuacao_cnm        = 1L,
      # Totais provisórios — recalculados no passo 8
      pontuacao_total      = 1L,
      n_fontes             = 1L
    ) |>
    # Reordenar colunas para casar com painel_atualizado
    select(all_of(names(painel_atualizado)))

} else {
  message("Nenhum par novo — apenas confirmações no universo existente.")
  linhas_cnm_only <- painel_atualizado[0, ]
}

# --- 8. Montar painel v2 e recalcular totais ---------------------------------
message("\nMontando painel v2...")

painel_v2 <- bind_rows(painel_atualizado, linhas_cnm_only) |>
  mutate(
    pontuacao_total = pontuacao_mides + pontuacao_siconfi +
                      pontuacao_munic  + pontuacao_cnm,
    n_fontes        = (pontuacao_mides  > 0L) +
                      (pontuacao_siconfi > 0L) +
                      (pontuacao_munic   > 0L) +
                      (cnm_confirma == TRUE & !is.na(cnm_confirma))
  ) |>
  arrange(desc(pontuacao_total), cod_ibge_6)

# --- 9. Diagnóstico ----------------------------------------------------------
message("\n=== DIMENSÕES PAINEL V2 ===")
message("Pares: ",       nrow(painel_v2),
        " | Consórcios: ", n_distinct(painel_v2$cnpj_consorcio),
        " | Municípios: ", n_distinct(painel_v2$cod_ibge_6))
message("Variáveis: ", ncol(painel_v2))

message("\n=== IMPACTO DO CNM ===")
message("  Pares que receberam cnm_confirma = TRUE: ",
        sum(painel_v2$cnm_confirma == TRUE, na.rm = TRUE))
message("  Pares novos adicionados pelo CNM:        ", nrow(linhas_cnm_only))
message("  Consórcios confirmados pelo CNM:         ", n_consorcios_cnm,
        " de ", nrow(cadastro_mg))

message("\n=== DISTRIBUIÇÃO PONTUAÇÃO TOTAL (v2) ===")
painel_v2 |>
  count(pontuacao_total, name = "n_pares") |>
  mutate(pct = round(n_pares / sum(n_pares) * 100, 1)) |>
  arrange(desc(pontuacao_total)) |>
  print()

message("\n=== COMPARAÇÃO V1 × V2 (pares com mudança de score) ===")
painel_v2 |>
  inner_join(
    painel_v1 |> select(cod_ibge_6, cnpj_consorcio,
                         pontuacao_total_v1 = pontuacao_total),
    by = join_by(cod_ibge_6, cnpj_consorcio)
  ) |>
  filter(pontuacao_total != pontuacao_total_v1) |>
  count(pontuacao_total_v1, pontuacao_total, name = "n_pares") |>
  arrange(desc(n_pares)) |>
  print()

message("\n=== COMBINAÇÕES DE FONTES ===")
painel_v2 |>
  mutate(fontes_label = case_when(
    pontuacao_mides > 0 & siconfi_confirma & munic_confirma & cnm_confirma ~
      "MIDES+SICONFI+MUNIC+CNM (10pts)",
    pontuacao_mides > 0 & siconfi_confirma & munic_confirma & !cnm_confirma ~
      "MIDES+SICONFI+MUNIC (9pts)",
    pontuacao_mides > 0 & siconfi_confirma & !munic_confirma & cnm_confirma ~
      "MIDES+SICONFI+CNM (8pts)",
    pontuacao_mides > 0 & siconfi_confirma & !munic_confirma & !cnm_confirma ~
      "MIDES+SICONFI (7pts)",
    pontuacao_mides > 0 & !siconfi_confirma & munic_confirma & cnm_confirma ~
      "MIDES+MUNIC+CNM (7pts)",
    pontuacao_mides > 0 & !siconfi_confirma & munic_confirma & !cnm_confirma ~
      "MIDES+MUNIC (6pts)",
    pontuacao_mides > 0 & !siconfi_confirma & !munic_confirma & cnm_confirma ~
      "MIDES+CNM (5pts)",
    pontuacao_mides > 0 & !siconfi_confirma & !munic_confirma & !cnm_confirma ~
      "Só MIDES (4pts)",
    pontuacao_mides == 0 & munic_confirma & siconfi_confirma & cnm_confirma ~
      "MUNIC+SICONFI+CNM (6pts)",
    pontuacao_mides == 0 & munic_confirma & siconfi_confirma & !cnm_confirma ~
      "MUNIC+SICONFI (5pts)",
    pontuacao_mides == 0 & munic_confirma & !siconfi_confirma & cnm_confirma ~
      "MUNIC+CNM (3pts)",
    pontuacao_mides == 0 & munic_confirma & !siconfi_confirma & !cnm_confirma ~
      "Só MUNIC (2pts)",
    pontuacao_mides == 0 & !munic_confirma & cnm_confirma ~
      "Só CNM (1pt)",
    TRUE ~ "Outro"
  )) |>
  count(fontes_label, name = "n_pares") |>
  mutate(pct = round(n_pares / sum(n_pares) * 100, 1)) |>
  arrange(desc(n_pares)) |>
  print()

message("\n=== COBERTURA CNM × CADASTRO 223 ===")
message("Consórcios no cadastro MG com presença no CNM: ", n_consorcios_cnm, " / 223")
message("Consórcios no cadastro MG SEM registro no CNM: ", n_cadastro_sem_cnm, " / 223")

message("\n=== VALIDAÇÃO CODAP (08753385000170) ===")
painel_v2 |>
  filter(cnpj_consorcio == "08753385000170") |>
  select(cod_ibge_6, nome_credor_freq, pontuacao_total,
         siconfi_confirma, munic_confirma, cnm_confirma, n_anos_pagamento) |>
  print(n = 25)

# --- 10. Exportar -------------------------------------------------------------
out_csv  <- paste0(ideas_path, "outputs/csv_base/", data_hoje,
                   "_painel_universal_mg_v2.csv")
out_xlsx <- paste0(ideas_path, "outputs/csv_base/", data_hoje,
                   "_painel_universal_mg_v2.xlsx")

write_csv(painel_v2, out_csv)
write_xlsx(painel_v2, out_xlsx)

message("\n✅ Exportado:")
message("  ", out_csv)
message("  ", out_xlsx)
message("  Linhas: ",    nrow(painel_v2),
        " | Colunas: ", ncol(painel_v2))
