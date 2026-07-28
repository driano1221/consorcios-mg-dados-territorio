# =============================================================================
# 02_painel_participacao.R
# Constrói painel resumido de participação municipal em consórcios — MG
#
# Input:  dados/bruto/mides_mg_atualizado.rds  (469.596 linhas transacionais)
# Output: dados/processado/painel_mg_anual.rds          (1 linha por município × consórcio × ano)
#         dados/processado/painel_mg_participacao.rds   (1 linha por município × consórcio)
#
# Lógica:
#   - Separar pagamentos correntes (indicador_restos_pagar = FALSE) dos restos
#   - ano_entrada_proxy = primeiro ano com pagamento CORRENTE
#   - ano_saida_proxy   = último ano com pagamento corrente + 1 (se < 2021)
#   - ainda_ativo       = TRUE se pagamento corrente aparece em 2021
#   - Restos a pagar não definem entrada/saída mas são somados ao valor total
#   - 19 pares têm APENAS restos a pagar → confianca = "sem_evidencia"
#
# Correções aplicadas (2026-05-05):
#   - nome_credor removido do .by do painel_anual (causava linhas duplicadas
#     por variações de grafia do mesmo CNPJ em municípios diferentes)
#   - nome_credor_freq calculado dentro do summarise do painel_anual
#   - is.infinite() tratado para pares sem pagamento corrente (min de vetor vazio)
# =============================================================================

library(dplyr)
library(readxl)

# --- 1. Carregar dados -------------------------------------------------------
path_rds <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/dados/bruto/mides_mg_atualizado.rds"
mides <- readRDS(path_rds)

message("Carregado: ", nrow(mides), " linhas")

# --- 2. Agregar por município × consórcio × ano ------------------------------
# ATENÇÃO: nome_credor NÃO entra no .by — mesmo CNPJ tem dezenas de grafias
# diferentes digitadas por municípios distintos. nome_credor_freq captura
# a grafia mais frequente dentro do grupo.

painel_anual <- mides |>
  mutate(corrente = !indicador_restos_pagar) |>
  summarise(
    valor_corrente         = sum(valor_final[corrente],  na.rm = TRUE),
    valor_restos           = sum(valor_final[!corrente], na.rm = TRUE),
    valor_total            = sum(valor_final,            na.rm = TRUE),
    n_transacoes           = n(),
    tem_pagamento_corrente = any(corrente, na.rm = TRUE),
    nome_credor_freq       = names(sort(table(nome_credor), decreasing = TRUE))[1],
    .by = c(id_municipio, documento_credor, ano)
  ) |>
  arrange(id_municipio, documento_credor, ano)

message("Painel anual: ", nrow(painel_anual), " linhas | ",
        n_distinct(painel_anual$id_municipio), " municípios | ",
        n_distinct(painel_anual$documento_credor), " consórcios")

# Esperado: ~15.135 linhas (sem duplicatas de nome_credor)

# --- 3. Derivar entrada / saída por par município × consórcio ----------------
ultimo_ano_serie <- max(painel_anual$ano)  # 2021

painel_participacao <- painel_anual |>
  summarise(
    # Entrada: primeiro ano com pagamento corrente
    ano_entrada_proxy   = min(ano[tem_pagamento_corrente], na.rm = TRUE),

    # Último ano corrente
    ultimo_ano_corrente = max(ano[tem_pagamento_corrente], na.rm = TRUE),

    # Ativo: aparece pagando no último ano da série
    ainda_ativo = ultimo_ano_serie %in% ano[tem_pagamento_corrente],

    # Valores e contagens
    valor_total_periodo = sum(valor_total, na.rm = TRUE),
    n_anos_pagamento    = sum(tem_pagamento_corrente, na.rm = TRUE),

    # Nome mais frequente (já calculado no painel_anual)
    nome_credor_freq    = first(nome_credor_freq),

    .by = c(id_municipio, documento_credor)
  ) |>
  mutate(
    # Saída proxy: ano após o último pagamento corrente (se não ativo)
    ano_saida_proxy = if_else(!ainda_ativo, ultimo_ano_corrente + 1L, NA_integer_),

    # Confiança inicial (só MIDES — será enriquecida no script 03)
    confianca = "baixa",
    fonte     = "MIDES"
  ) |>
  mutate(
    # Tratar 19 pares com APENAS restos a pagar: min/max de vetor vazio → Inf/-Inf
    ano_entrada_proxy   = if_else(is.infinite(ano_entrada_proxy),   NA_real_, ano_entrada_proxy),
    ultimo_ano_corrente = if_else(is.infinite(ultimo_ano_corrente), NA_real_, ultimo_ano_corrente),
    ano_saida_proxy     = if_else(is.na(ano_entrada_proxy), NA_integer_, ano_saida_proxy),
    confianca           = if_else(is.na(ano_entrada_proxy), "sem_evidencia", confianca)
  ) |>
  dplyr::select(
    id_municipio, documento_credor, nome_credor_freq,
    ano_entrada_proxy, ultimo_ano_corrente, ano_saida_proxy, ainda_ativo,
    valor_total_periodo, n_anos_pagamento,
    confianca, fonte
  ) |>
  arrange(id_municipio, documento_credor)

# --- 4. Diagnóstico ----------------------------------------------------------
message("\n=== PAINEL DE PARTICIPAÇÃO ===")
message("Pares únicos (município × consórcio): ", nrow(painel_participacao))
message("Municípios: ", n_distinct(painel_participacao$id_municipio))
message("Consórcios: ", n_distinct(painel_participacao$documento_credor))

message("\n--- Distribuição de entrada ---")
painel_participacao |>
  count(ano_entrada_proxy) |>
  arrange(ano_entrada_proxy) |>
  print(n = Inf)

message("\n--- Ativos vs. possível saída ---")
painel_participacao |>
  count(ainda_ativo) |>
  print()

message("\n--- Anos de pagamento por par (máx esperado: 8) ---")
painel_participacao |>
  count(n_anos_pagamento) |>
  arrange(n_anos_pagamento) |>
  print(n = Inf)

message("\n--- Confiança ---")
painel_participacao |>
  count(confianca) |>
  print()

# --- 5. Salvar ---------------------------------------------------------------
out_anual <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/dados/processado/painel_mg_anual.rds"
out_part  <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/dados/processado/painel_mg_participacao.rds"

saveRDS(painel_anual,        out_anual)
saveRDS(painel_participacao, out_part)

message("\nSalvo:")
message("  ", out_anual)
message("  ", out_part)
