# =============================================================================
# 05_painel_universal_mg.R
# Painel universal de participação — MG
#
# Diferença central em relação ao script 04:
#   O universo de pares NÃO é ancorado no MIDES.
#   É construído pela UNIÃO de todas as fontes disponíveis,
#   restrito aos 223 consórcios do cadastro MG.
#
#   Isso permite que pares "só MUNIC" entrem no painel com 2 pts,
#   capturando municípios que declararam filiação mas sem evidência
#   fiscal no MIDES (ex: consórcios informais, inadimplência, pré-2014).
#
# Fontes e pontuação:
#   MIDES   → 4 pts  (pagamento corrente via TCE-MG, 2014–2021)
#   SICONFI → 3 pts  (confirmação indireta por ano)
#              Âncora MIDES: anos com pagamento corrente (pares com MIDES)
#              Âncora MUNIC: anos de declaração 2015/2019 (pares só MUNIC)
#   MUNIC   → 2 pts  (autodeclarado pelo município — 2015 e 2019)
#   CNM     → 1 pt   (placeholder — Etapa 9)
#
# Universo:
#   223 consórcios do cadastro MG (base_consorcios, uf = "MG")
#   × municípios que aparecem em QUALQUER fonte para esses consórcios
#   CNPJs do MUNIC fora do cadastro (134) são DESCARTADOS
#
# Inputs:
#   dados/processado/painel_mg_anual.rds
#   dados/processado/painel_mg_participacao.rds
#   base_consorcios_v10_2026-04-30.xlsx:
#     aba "Cadastro"            (1.194 × 25)
#     aba "SICONFI painel munic" (70.944 × 9)
#     aba "MUNIC participacao"   (18.276 × 10)
#
# Outputs:
#   outputs/csv_base/YYYY-MM-DD_painel_universal_mg_v1.csv/.xlsx
#
# Decisões metodológicas (2026-05-14):
#   - Restringir ao cadastro de 1.194 (CNPJs sem metadados descartados)
#   - SICONFI não define novos pares (sem CNPJ destino) — só confirma
#   - Pares só MUNIC recebem pontuacao_siconfi = 0 (sem âncora de ano)
#   - 134 CNPJs do MUNIC fora do cadastro → descartados; documentar para reunião
# =============================================================================

library(dplyr)
library(readxl)
library(writexl)
library(readr)

# --- Caminhos ----------------------------------------------------------------
base_path  <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/base_consorcios_v10_2026-04-30.xlsx"
ideas_path <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/"
data_hoje  <- format(Sys.Date(), "%Y-%m-%d")

# --- 1. Carregar bases -------------------------------------------------------
message("Carregando bases...")

anual  <- readRDS(paste0(ideas_path, "dados/processado/painel_mg_anual.rds"))
partic <- readRDS(paste0(ideas_path, "dados/processado/painel_mg_participacao.rds"))

# Cadastro MG — universo de consórcios válidos
cadastro_mg <- read_excel(base_path, sheet = "Cadastro") |>
  filter(uf == "MG") |>
  mutate(cnpj = as.character(cnpj)) |>
  select(cnpj, razao_social, sigla, setores, situacao, ano_fundacao,
         tem_rateio, tem_protocolo, tem_estatuto, tem_evidencia)

message("Cadastro MG: ", nrow(cadastro_mg), " consórcios")

# SICONFI MG — apenas anos confiáveis (ok = 2013–2024)
# cod_ibge no SICONFI é 7 dígitos → convertemos para 6 (cod_ibge_6)
# para usar a mesma chave universal do painel (consistente com MUNIC e MIDES)
siconfi_mg <- read_excel(base_path, sheet = "SICONFI painel munic") |>
  filter(uf == "MG", nota_cobertura == "ok") |>
  mutate(cod_ibge_6 = substr(as.character(cod_ibge), 1, 6)) |>
  select(cod_ibge_6, ano, paga_consorcio)

message("SICONFI MG (ok): ", nrow(siconfi_mg), " linhas | anos: ",
        min(siconfi_mg$ano), "–", max(siconfi_mg$ano))

# MUNIC MG — apenas CNPJs dentro do cadastro MG (descartar os 134 fora)
munic_raw <- read_excel(base_path, sheet = "MUNIC participacao") |>
  filter(uf_mun == "MG") |>
  mutate(
    cod_ibge       = as.character(cod_ibge),
    cnpj_consorcio = as.character(cnpj_consorcio)
  ) |>
  select(cod_ibge, cnpj_consorcio, ano, setor)

munic_mg <- munic_raw |>
  filter(cnpj_consorcio %in% cadastro_mg$cnpj)

n_fora_cadastro <- n_distinct(
  munic_raw$cnpj_consorcio[!munic_raw$cnpj_consorcio %in% cadastro_mg$cnpj]
)
message("MUNIC MG: ", nrow(munic_mg), " linhas | ",
        n_distinct(munic_mg$cnpj_consorcio), " consórcios no cadastro | ",
        n_fora_cadastro, " CNPJs descartados (fora do cadastro)")

# --- 2. Construir universo de pares ------------------------------------------
# União: MIDES ∪ MUNIC, restrito ao cadastro MG
message("\nConstruindo universo de pares...")

pares_mides <- partic |>
  transmute(
    cod_ibge_6       = substr(as.character(id_municipio), 1, 6),
    id_municipio     = as.character(id_municipio),
    cnpj_consorcio   = documento_credor,
    nome_credor_freq = nome_credor_freq,
    origem           = "mides"
  ) |>
  filter(cnpj_consorcio %in% cadastro_mg$cnpj)  # garantia: só cadastro MG

pares_munic <- munic_mg |>
  transmute(
    cod_ibge_6     = cod_ibge,
    id_municipio   = NA_character_,   # será preenchido abaixo
    cnpj_consorcio = cnpj_consorcio,
    nome_credor_freq = NA_character_,
    origem         = "munic"
  ) |>
  distinct(cod_ibge_6, cnpj_consorcio, .keep_all = TRUE)

# União: prioriza linha do MIDES quando par já existe lá
universo <- bind_rows(pares_mides, pares_munic) |>
  # Para cada par, manter id_municipio do MIDES se disponível
  summarise(
    id_municipio     = first(id_municipio[!is.na(id_municipio)]),
    nome_credor_freq = first(nome_credor_freq[!is.na(nome_credor_freq)]),
    tem_mides        = any(origem == "mides"),
    tem_munic_par    = any(origem == "munic"),
    .by = c(cod_ibge_6, cnpj_consorcio)
  )

message("Universo: ", nrow(universo), " pares únicos | ",
        n_distinct(universo$cnpj_consorcio), " consórcios | ",
        n_distinct(universo$cod_ibge_6), " municípios")
message("  Só MIDES: ", sum(universo$tem_mides & !universo$tem_munic_par))
message("  Só MUNIC: ", sum(!universo$tem_mides & universo$tem_munic_par))
message("  Ambos:    ", sum(universo$tem_mides & universo$tem_munic_par))

# --- 3. Pontuação MIDES (+4 pts) --------------------------------------------
message("\nCalculando pontuação MIDES...")

mides_score <- partic |>
  transmute(
    cod_ibge_6          = substr(as.character(id_municipio), 1, 6),
    cnpj_consorcio      = documento_credor,
    pontuacao_mides     = 4L,
    ano_entrada_proxy   = ano_entrada_proxy,
    ultimo_ano_corrente = ultimo_ano_corrente,
    ainda_ativo         = ainda_ativo,
    valor_total_periodo = valor_total_periodo,
    n_anos_pagamento    = n_anos_pagamento,
    valor_atipico       = valor_total_periodo < 1000 & !is.na(valor_total_periodo),
    confianca_mides     = confianca
  )

# --- 4. Pontuação SICONFI (+3 pts) ------------------------------------------
# Duas âncoras possíveis, em ordem de preferência:
#
#   Âncora MIDES (prioritária): anos com pagamento corrente registrado
#     → mesma lógica do script 04
#
#   Âncora MUNIC (para pares só MUNIC): anos de declaração (2015 e/ou 2019)
#     → município declarou filiação E pagou algum consórcio no SICONFI
#       no mesmo ano em que declarou → confirmação indireta válida
#
# Resultado: pares só MUNIC podem chegar a 5 pts (MUNIC 2 + SICONFI 3)
message("Calculando pontuação SICONFI...")

# 4a. SICONFI com âncora MIDES
siconfi_mides <- anual |>
  filter(tem_pagamento_corrente) |>
  mutate(cod_ibge_6 = substr(as.character(id_municipio), 1, 6)) |>
  select(cod_ibge_6, cnpj_consorcio = documento_credor, ano) |>
  left_join(siconfi_mg, by = join_by(cod_ibge_6, ano)) |>
  summarise(
    ancora               = "mides",
    n_anos_ancora        = n(),
    n_anos_siconfi_match = sum(paga_consorcio == TRUE, na.rm = TRUE),
    siconfi_confirma     = any(paga_consorcio == TRUE, na.rm = TRUE),
    anos_siconfi_match   = paste(
      sort(ano[paga_consorcio == TRUE & !is.na(paga_consorcio)]),
      collapse = ", "
    ),
    .by = c(cod_ibge_6, cnpj_consorcio)
  )

# 4b. SICONFI com âncora MUNIC (só para pares que NÃO têm âncora MIDES)
pares_so_munic <- universo |>
  filter(!tem_mides, tem_munic_par) |>
  select(cod_ibge_6, cnpj_consorcio)

siconfi_munic <- munic_mg |>
  rename(cod_ibge_6 = cod_ibge) |>
  select(cod_ibge_6, cnpj_consorcio, ano) |>
  # Deduplica: munic_mg tem 1 linha por setor → mesmo par × ano pode ter N linhas
  # (ex: consórcio multissetorial com 12 setores = 12 linhas)
  # Sem distinct, o left_join com SICONFI inflaria n_anos_siconfi_match
  distinct(cod_ibge_6, cnpj_consorcio, ano) |>
  # Restringir só aos pares que não têm MIDES
  inner_join(pares_so_munic, by = join_by(cod_ibge_6, cnpj_consorcio)) |>
  left_join(siconfi_mg, by = join_by(cod_ibge_6, ano)) |>
  summarise(
    ancora               = "munic",
    n_anos_ancora        = n(),
    n_anos_siconfi_match = sum(paga_consorcio == TRUE, na.rm = TRUE),
    siconfi_confirma     = any(paga_consorcio == TRUE, na.rm = TRUE),
    anos_siconfi_match   = paste(
      sort(ano[paga_consorcio == TRUE & !is.na(paga_consorcio)]),
      collapse = ", "
    ),
    .by = c(cod_ibge_6, cnpj_consorcio)
  )

# 4c. Unir os dois scores
siconfi_score <- bind_rows(siconfi_mides, siconfi_munic) |>
  mutate(
    anos_siconfi_match = if_else(anos_siconfi_match == "", NA_character_, anos_siconfi_match),
    pontuacao_siconfi  = if_else(siconfi_confirma, 3L, 0L)
  )

message("Pares com SICONFI confirmado (âncora MIDES):  ",
        sum(siconfi_mides$siconfi_confirma))
message("Pares com SICONFI confirmado (âncora MUNIC):  ",
        sum(siconfi_munic$siconfi_confirma),
        " de ", nrow(pares_so_munic), " pares só MUNIC elegíveis")

# --- 5. Pontuação MUNIC (+2 pts) --------------------------------------------
message("Calculando pontuação MUNIC...")

munic_score <- munic_mg |>
  summarise(
    munic_confirma = TRUE,
    anos_munic     = paste(sort(unique(ano)), collapse = ", "),
    setores_munic  = paste(sort(unique(setor)), collapse = ", "),
    .by = c(cod_ibge, cnpj_consorcio)
  ) |>
  rename(cod_ibge_6 = cod_ibge) |>
  mutate(pontuacao_munic = 2L)

message("Pares com MUNIC confirmado: ", nrow(munic_score))

# --- 6. Montar painel pontuado ----------------------------------------------
message("\nMontando painel pontuado...")

painel_universal <- universo |>
  # Metadados do cadastro
  left_join(
    cadastro_mg |> select(cnpj, razao_social, sigla, setores,
                           situacao, ano_fundacao, tem_evidencia),
    by = join_by(cnpj_consorcio == cnpj)
  ) |>

  # MIDES
  left_join(mides_score, by = join_by(cod_ibge_6, cnpj_consorcio)) |>
  mutate(
    pontuacao_mides     = if_else(tem_mides, 4L, 0L),
    valor_total_periodo = if_else(is.na(valor_total_periodo), 0, valor_total_periodo),
    n_anos_pagamento    = if_else(is.na(n_anos_pagamento), 0L, n_anos_pagamento),
    valor_atipico       = if_else(is.na(valor_atipico), FALSE, valor_atipico)
  ) |>

  # SICONFI — âncora MIDES para pares com MIDES, âncora MUNIC para pares só MUNIC
  # 19 sem_evidencia (só restos a pagar) não têm âncora → ancora = "sem_ancora"
  left_join(
    siconfi_score |> select(cod_ibge_6, cnpj_consorcio, ancora,
                             siconfi_confirma, anos_siconfi_match,
                             n_anos_siconfi_match, pontuacao_siconfi),
    by = join_by(cod_ibge_6, cnpj_consorcio)
  ) |>
  mutate(
    ancora               = if_else(is.na(ancora), "sem_ancora", ancora),
    siconfi_confirma     = if_else(is.na(siconfi_confirma), FALSE, siconfi_confirma),
    pontuacao_siconfi    = if_else(is.na(pontuacao_siconfi), 0L, pontuacao_siconfi),
    n_anos_siconfi_match = if_else(is.na(n_anos_siconfi_match), 0L, n_anos_siconfi_match)
  ) |>

  # MUNIC
  left_join(
    munic_score |> select(cod_ibge_6, cnpj_consorcio,
                           munic_confirma, anos_munic, setores_munic, pontuacao_munic),
    by = join_by(cod_ibge_6, cnpj_consorcio)
  ) |>
  mutate(
    munic_confirma  = if_else(is.na(munic_confirma), FALSE, munic_confirma),
    pontuacao_munic = if_else(is.na(pontuacao_munic), 0L, pontuacao_munic)
  ) |>

  # CNM — placeholder (Etapa 9)
  mutate(
    cnm_confirma  = NA,
    pontuacao_cnm = 0L
  ) |>

  # Setor consolidado: cadastro quando disponível, MUNIC como fallback
  # 79 de 166 consórcios não têm setor no cadastro (campo vazio na fonte)
  mutate(
    setores_consolidado = case_when(
      !is.na(setores)       ~ setores,
      !is.na(setores_munic) ~ paste0(setores_munic, " [via MUNIC]"),
      TRUE                  ~ NA_character_
    )
  ) |>

  # Total
  mutate(
    pontuacao_total = pontuacao_mides + pontuacao_siconfi +
                      pontuacao_munic + pontuacao_cnm,
    n_fontes        = (pontuacao_mides  > 0L) +
                      (pontuacao_siconfi > 0L) +
                      (pontuacao_munic   > 0L) +
                      (!is.na(cnm_confirma) & cnm_confirma)
  ) |>

  select(
    cod_ibge_6, id_municipio, cnpj_consorcio, nome_credor_freq,
    # Cadastro
    razao_social, sigla, setores, setores_consolidado, situacao, ano_fundacao, tem_evidencia,
    # MIDES
    pontuacao_mides, ano_entrada_proxy, ultimo_ano_corrente,
    ainda_ativo, valor_total_periodo, n_anos_pagamento, valor_atipico,
    confianca_mides,
    # SICONFI
    pontuacao_siconfi, siconfi_confirma, ancora,
    anos_siconfi_match, n_anos_siconfi_match,
    # MUNIC
    pontuacao_munic, munic_confirma, anos_munic, setores_munic,
    # CNM
    pontuacao_cnm, cnm_confirma,
    # Total
    pontuacao_total, n_fontes
  ) |>
  arrange(desc(pontuacao_total), cod_ibge_6)

# --- 7. Diagnóstico ----------------------------------------------------------
message("\n=== DIMENSÕES ===")
message("Pares: ", nrow(painel_universal),
        " | Consórcios: ", n_distinct(painel_universal$cnpj_consorcio),
        " | Municípios: ", n_distinct(painel_universal$cod_ibge_6))

message("\n=== DISTRIBUIÇÃO DE PONTUAÇÃO TOTAL ===")
painel_universal |>
  count(pontuacao_total, name = "n_pares") |>
  mutate(pct = round(n_pares / sum(n_pares) * 100, 1)) |>
  arrange(desc(pontuacao_total)) |>
  print()

message("\n=== COMBINAÇÕES DE FONTES ===")
painel_universal |>
  mutate(fontes_label = case_when(
    pontuacao_mides > 0 & siconfi_confirma &  munic_confirma ~ "MIDES+SICONFI+MUNIC (9pts)",
    pontuacao_mides > 0 & siconfi_confirma & !munic_confirma ~ "MIDES+SICONFI (7pts)",
    pontuacao_mides > 0 & !siconfi_confirma & munic_confirma ~ "MIDES+MUNIC (6pts)",
    pontuacao_mides > 0 & !siconfi_confirma & !munic_confirma ~ "Só MIDES (4pts)",
    pontuacao_mides == 0 & munic_confirma & siconfi_confirma  ~ "MUNIC+SICONFI (5pts)",
    pontuacao_mides == 0 & munic_confirma & !siconfi_confirma ~ "Só MUNIC (2pts)",
    TRUE                                                       ~ "Outro"
  )) |>
  count(fontes_label, name = "n_pares") |>
  mutate(pct = round(n_pares / sum(n_pares) * 100, 1)) |>
  arrange(desc(n_pares)) |>
  print()

message("\n=== CONSÓRCIOS SEM NENHUM PAR NO MIDES ===")
consorcios_so_munic <- painel_universal |>
  filter(pontuacao_mides == 0) |>
  count(cnpj_consorcio, nome_credor_freq, razao_social, name = "n_municipios") |>
  arrange(desc(n_municipios))
message("Consórcios com pares só MUNIC: ", nrow(consorcios_so_munic))
print(head(consorcios_so_munic, 10))

message("\n=== VALIDAÇÃO CODAP (08753385000170) ===")
painel_universal |>
  filter(cnpj_consorcio == "08753385000170") |>
  select(cod_ibge_6, nome_credor_freq, pontuacao_total,
         siconfi_confirma, munic_confirma, n_anos_pagamento) |>
  print(n = 25)

message("\n=== CONSÓRCIOS DO CADASTRO MG SEM NENHUM PAR ===")
cadastro_sem_pares <- cadastro_mg |>
  filter(!cnpj %in% painel_universal$cnpj_consorcio)
message("Consórcios no cadastro sem nenhum município em qualquer fonte: ",
        nrow(cadastro_sem_pares))
if (nrow(cadastro_sem_pares) > 0) {
  cadastro_sem_pares |>
    select(cnpj, razao_social, situacao, ano_fundacao) |>
    print(n = 20)
}

# --- 8. Exportar -------------------------------------------------------------
out_csv  <- paste0(ideas_path, "outputs/csv_base/", data_hoje,
                   "_painel_universal_mg_v1.csv")
out_xlsx <- paste0(ideas_path, "outputs/csv_base/", data_hoje,
                   "_painel_universal_mg_v1.xlsx")

write_csv(painel_universal, out_csv)
write_xlsx(painel_universal, out_xlsx)

message("\n✅ Exportado:")
message("  ", out_csv)
message("  ", out_xlsx)
message("  Linhas: ", nrow(painel_universal),
        " | Colunas: ", ncol(painel_universal))
