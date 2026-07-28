# =============================================================================
# 04_pontuacao_mg.R
# Sistema de pontuação acumulada por fonte — MG
#
# Metodologia definida na reunião de 07/05/2026 (Paulo, Pedro, Mauro, Adriano):
#   MIDES   → 4 pts  (pagamento efetivo via TCE — mais confiável)
#   SICONFI → 3 pts  (confirmação indireta: município pagou ALGUM consórcio
#                     no mesmo ano que o MIDES registra pagamento ao consórcio X)
#   MUNIC   → 2 pts  (autodeclarado — só cortes 2015 e 2019)
#   CNM     → 1 pt   (lista de referência — Etapa 9, ainda não implementado)
#
# Par com 4 fontes = 10 pts (máxima confiança)
#
# Inputs:
#   dados/processado/painel_mg_participacao.rds   (2.835 pares)
#   dados/processado/painel_mg_anual.rds           (15.135 linhas)
#   base_consorcios_v10_2026-04-30.xlsx:
#     aba "SICONFI painel munic"  (70.944 × 9, cobertura 2010–2025)
#     aba "MUNIC participacao"    (18.276 × 10, só 2015 e 2019)
#
# Outputs:
#   outputs/csv_base/YYYY-MM-DD_csv_base_mides_mg_v2.csv/.xlsx
#
# Descobertas que afetam este script (2026-05-13):
#   - SICONFI vai até 2024 com nota_cobertura = "ok" (antes achávamos 2022)
#   - Anos 2010–2012 têm nota_cobertura = "pre_rubrica_71" → EXCLUIR
#   - 2025 é "ano_incompleto" → EXCLUIR
#   - valor_cons_real está deflacionado para jan/2018 (IPCA) — não é nominal
#   - SICONFI NÃO identifica qual consórcio foi pago (sem CNPJ destino)
#     → confirmação é INDIRETA: município pagou algum consórcio no mesmo ano
#   - ~47-53% dos municípios do MUNIC não aparecem no SICONFI → consórcios
#     informais (não regidos pela Lei 11.107/2005) não geram rubrica .71.
#     → ausência no SICONFI NÃO é inadimplência automática
#   - MG no MIDES: ainda 2014–2021 (BigQuery não atualizado)
# =============================================================================

library(dplyr)
library(readxl)
library(writexl)
library(readr)
library(stringr)

# --- Caminhos ----------------------------------------------------------------
base_path  <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/base_consorcios_v10_2026-04-30.xlsx"
ideas_path <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/"

data_hoje  <- format(Sys.Date(), "%Y-%m-%d")

# --- 1. Carregar bases -------------------------------------------------------
message("Carregando bases...")

partic <- readRDS(paste0(ideas_path, "dados/processado/painel_mg_participacao.rds"))
anual  <- readRDS(paste0(ideas_path, "dados/processado/painel_mg_anual.rds"))

# SICONFI — filtrar apenas anos com rubrica .71. bem definida (ok)
# Exclui: pre_rubrica_71 (2010–2012) e ano_incompleto (2025)
siconfi_mg <- read_excel(base_path, sheet = "SICONFI painel munic") |>
  filter(
    uf             == "MG",
    nota_cobertura == "ok"        # apenas 2013–2024 confiáveis
  ) |>
  select(cod_ibge, ano, paga_consorcio)

message("SICONFI MG (ok): ", nrow(siconfi_mg), " linhas | anos: ",
        min(siconfi_mg$ano), "–", max(siconfi_mg$ano))

# MUNIC — apenas MG, ambos os cortes disponíveis (2015 e 2019)
munic_mg <- read_excel(base_path, sheet = "MUNIC participacao") |>
  filter(uf_mun == "MG") |>
  select(cod_ibge, cnpj_consorcio, ano, setor)

message("MUNIC MG: ", nrow(munic_mg), " linhas | municípios: ",
        n_distinct(munic_mg$cod_ibge), " | consórcios: ",
        n_distinct(munic_mg$cnpj_consorcio))

# --- 2. Pontuação SICONFI (+3 pts) ------------------------------------------
# Lógica: para cada par (município × consórcio), pegar os anos em que o MIDES
# registra pagamento corrente. Se o SICONFI confirmar pagamento a ALGUM
# consórcio em ao menos 1 desses mesmos anos → siconfi_confirma = TRUE.
#
# Nota: confirmação é INDIRETA — SICONFI não sabe para qual consórcio foi.
# Chance de coincidência é baixa quando MIDES e SICONFI batem no mesmo ano.

message("\nCalculando pontuação SICONFI...")

siconfi_score <- anual |>
  filter(tem_pagamento_corrente) |>
  select(id_municipio, documento_credor, ano) |>
  left_join(
    siconfi_mg |> rename(id_municipio = cod_ibge),
    by = join_by(id_municipio, ano)
  ) |>
  summarise(
    n_anos_mides         = n(),
    n_anos_siconfi_match = sum(paga_consorcio == TRUE, na.rm = TRUE),
    siconfi_confirma     = any(paga_consorcio == TRUE, na.rm = TRUE),
    anos_siconfi_match   = paste(sort(ano[paga_consorcio == TRUE & !is.na(paga_consorcio)]),
                                 collapse = ", "),
    .by = c(id_municipio, documento_credor)
  ) |>
  mutate(
    anos_siconfi_match = if_else(anos_siconfi_match == "", NA_character_, anos_siconfi_match),
    pontuacao_siconfi  = if_else(siconfi_confirma, 3L, 0L)
  )

message("Pares com SICONFI confirmado: ",
        sum(siconfi_score$siconfi_confirma, na.rm = TRUE),
        " de ", nrow(siconfi_score))

# --- 3. Pontuação MUNIC (+2 pts) --------------------------------------------
# Lógica: se o município declarou participação no consórcio em QUALQUER
# dos cortes disponíveis (2015 ou 2019) → munic_confirma = TRUE.

message("\nCalculando pontuação MUNIC...")

munic_score <- munic_mg |>
  summarise(
    munic_confirma  = TRUE,
    anos_munic      = paste(sort(unique(ano)), collapse = ", "),
    setores_munic   = paste(sort(unique(setor)), collapse = ", "),
    .by = c(cod_ibge, cnpj_consorcio)
  ) |>
  rename(id_municipio = cod_ibge, documento_credor = cnpj_consorcio) |>
  mutate(pontuacao_munic = 2L)

message("Pares com MUNIC confirmado (MG): ", nrow(munic_score))

# --- 4. Montar painel pontuado -----------------------------------------------
message("\nMontando painel pontuado...")

painel_pontuado <- partic |>
  # MIDES: todos têm pontuacao_mides = 4 (já estão na base por definição)
  mutate(
    pontuacao_mides = 4L,
    # Chave de 6 dígitos para join com MUNIC (cod_ibge MUNIC = 6 dígitos; id_municipio = 7)
    id_municipio_6  = substr(as.character(id_municipio), 1, 6)
  ) |>

  # SICONFI
  left_join(
    siconfi_score |> select(id_municipio, documento_credor,
                             siconfi_confirma, anos_siconfi_match,
                             n_anos_siconfi_match, pontuacao_siconfi),
    by = join_by(id_municipio, documento_credor)
  ) |>
  mutate(
    siconfi_confirma     = if_else(is.na(siconfi_confirma), FALSE, siconfi_confirma),
    pontuacao_siconfi    = if_else(is.na(pontuacao_siconfi), 0L, pontuacao_siconfi),
    # 19 pares sem_evidencia não entraram no siconfi_score (sem pagamento corrente) → 0, não NA
    n_anos_siconfi_match = if_else(is.na(n_anos_siconfi_match), 0L, n_anos_siconfi_match)
  ) |>

  # MUNIC — join via id_municipio_6 (6 dígitos) pois cod_ibge do MUNIC não tem dígito verificador
  left_join(
    munic_score |> select(id_municipio, documento_credor,
                           munic_confirma, anos_munic, setores_munic,
                           pontuacao_munic),
    by = join_by(id_municipio_6 == id_municipio, documento_credor)
  ) |>
  mutate(
    munic_confirma  = if_else(is.na(munic_confirma), FALSE, munic_confirma),
    pontuacao_munic = if_else(is.na(pontuacao_munic), 0L, pontuacao_munic)
  ) |>

  # CNM — ainda não implementado (Etapa 9)
  mutate(
    cnm_confirma    = NA,
    pontuacao_cnm   = 0L
  ) |>

  # Total
  mutate(
    pontuacao_total = pontuacao_mides + pontuacao_siconfi +
                      pontuacao_munic + pontuacao_cnm,
    n_fontes        = (pontuacao_mides  > 0L) +
                      (pontuacao_siconfi > 0L) +
                      (pontuacao_munic   > 0L) +
                      (!is.na(cnm_confirma) & cnm_confirma),
    # Flag: valor total muito baixo — provável taxa/anuidade simbólica, não rateio de serviço
    # Threshold: < R$ 1.000 deflacionados (jan/2018). Não é erro, mas merece atenção analítica.
    valor_atipico   = valor_total_periodo < 1000 & !is.na(valor_total_periodo)
  ) |>

  select(
    -id_municipio_6  # remover coluna auxiliar do join MUNIC
  ) |>
  select(
    id_municipio, documento_credor, nome_credor_freq,
    # MIDES
    pontuacao_mides, ano_entrada_proxy, ultimo_ano_corrente,
    ainda_ativo, valor_total_periodo, n_anos_pagamento, valor_atipico,
    # SICONFI
    pontuacao_siconfi, siconfi_confirma,
    anos_siconfi_match, n_anos_siconfi_match,
    # MUNIC
    pontuacao_munic, munic_confirma, anos_munic, setores_munic,
    # CNM (placeholder)
    pontuacao_cnm, cnm_confirma,
    # Total
    pontuacao_total, n_fontes,
    # Metadados
    confianca, fonte
  ) |>
  arrange(desc(pontuacao_total), id_municipio)

# --- 5. Diagnóstico ----------------------------------------------------------
message("\n=== DISTRIBUIÇÃO DE PONTUAÇÃO TOTAL ===")
painel_pontuado |>
  count(pontuacao_total, name = "n_pares") |>
  mutate(pct = round(n_pares / sum(n_pares) * 100, 1)) |>
  arrange(desc(pontuacao_total)) |>
  print()

message("\n=== PARES POR Nº DE FONTES ===")
painel_pontuado |>
  count(n_fontes, name = "n_pares") |>
  mutate(pct = round(n_pares / sum(n_pares) * 100, 1)) |>
  arrange(desc(n_fontes)) |>
  print()

message("\n=== COMBINAÇÕES DE FONTES ===")
painel_pontuado |>
  mutate(
    fontes_label = case_when(
      siconfi_confirma &  munic_confirma ~ "MIDES + SICONFI + MUNIC",
      siconfi_confirma & !munic_confirma ~ "MIDES + SICONFI",
     !siconfi_confirma &  munic_confirma ~ "MIDES + MUNIC",
      TRUE                               ~ "Só MIDES"
    )
  ) |>
  count(fontes_label, name = "n_pares") |>
  mutate(pct = round(n_pares / sum(n_pares) * 100, 1)) |>
  arrange(desc(n_pares)) |>
  print()

message("\n=== PARES COM VALOR ATÍPICO (< R$1.000) ===")
painel_pontuado |>
  filter(valor_atipico) |>
  select(id_municipio, nome_credor_freq, valor_total_periodo,
         n_anos_pagamento, confianca, pontuacao_total) |>
  arrange(valor_total_periodo) |>
  print(n = Inf)

message("\n=== VALIDAÇÃO CODAP (08753385000170) ===")
painel_pontuado |>
  filter(documento_credor == "08753385000170") |>
  select(id_municipio, nome_credor_freq, pontuacao_total,
         siconfi_confirma, munic_confirma, anos_siconfi_match) |>
  print(n = 25)

# --- 6. Exportar -------------------------------------------------------------
out_csv  <- paste0(ideas_path, "outputs/csv_base/", data_hoje,
                   "_csv_base_mides_mg_v2.csv")
out_xlsx <- paste0(ideas_path, "outputs/csv_base/", data_hoje,
                   "_csv_base_mides_mg_v2.xlsx")

write_csv(painel_pontuado, out_csv)
write_xlsx(painel_pontuado, out_xlsx)

message("\n✅ Exportado:")
message("  ", out_csv)
message("  ", out_xlsx)
message("  Linhas: ", nrow(painel_pontuado),
        " | Colunas: ", ncol(painel_pontuado))
