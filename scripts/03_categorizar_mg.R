# =============================================================================
# ⚠️  SCRIPT SUSPENSO — NÃO EXECUTAR
# Substituído pelos scripts 04_pontuacao_mg.R e 05_painel_universal_mg.R
# (decisão: 2026-05-14 — migração para sistema de pontuação acumulada por fonte)
# =============================================================================
# 03_categorizar_mg.R
# Aplica as 4 categorias de participação (metodologia Paulo) ao painel MG
#
# Adaptado de: Rotina/scripts_equipe/piloto_mg_categorias.R
#
# Diferenças em relação ao script original:
#   - MIDES: usa painel_mg_anual.rds (BigQuery atualizado, 15.135 linhas)
#     em vez da aba "MIDES participacao" do Excel (base antiga do Anderson)
#   - Nomes de colunas ajustados: id_municipio / documento_credor
#   - MUNIC e SICONFI: ainda lidos da base_consorcios (não mudaram)
#   - anos_alvo: restrito a 2014–2021 (cobertura real do MIDES MG)
#
# Inputs:
#   dados/processado/painel_mg_anual.rds  (município × consórcio × ano — MIDES)
#   base_consorcios_v10_2026-04-30.xlsx (abas: Cadastro, MUNIC participacao,
#                                              SICONFI painel munic)
#
# Outputs:
#   outputs/painel_mg_categorias.rds
#   outputs/painel_mg_categorias.xlsx
# =============================================================================

library(dplyr)
library(readxl)
library(writexl)

path_base <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/base_consorcios_v10_2026-04-30.xlsx"
path_anual <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/dados/processado/painel_mg_anual.rds"

# --- 1. Carregar dados -------------------------------------------------------
message("Carregando dados...")

# MIDES atualizado (BigQuery)
painel_anual <- readRDS(path_anual)

# Cadastro — flags documentais por consórcio
cadastro <- read_excel(path_base, sheet = "Cadastro") |>
  mutate(cnpj = as.character(cnpj))

# MUNIC — associação município × consórcio (cortes 2015 e 2019)
munic <- read_excel(path_base, sheet = "MUNIC participacao") |>
  mutate(
    cod_ibge       = as.character(cod_ibge),
    cnpj_consorcio = as.character(cnpj_consorcio),
    ano            = as.integer(ano)
  )

# SICONFI — pagou algum consórcio? (sem CNPJ destino — só diagnóstico)
siconfi <- read_excel(path_base, sheet = "SICONFI painel munic") |>
  mutate(
    cod_ibge = as.character(cod_ibge),
    ano      = as.integer(ano)
  )

message("Dados carregados.")

# --- 2. Preparar flags -------------------------------------------------------

# Flags documentais por consórcio (Cadastro)
docs_flag <- cadastro |>
  select(cnpj, tem_rateio, tem_protocolo, tem_estatuto) |>
  mutate(tem_doc_formal = tem_rateio | tem_protocolo | tem_estatuto)

# MIDES MG — flag de pagamento corrente por par × ano
# (painel_anual já está filtrado para MG e nossos CNPJs — script 01)
mides_mg <- painel_anual |>
  mutate(mides_paga = tem_pagamento_corrente) |>
  select(
    cod_ibge    = id_municipio,
    cnpj_cons   = documento_credor,
    ano,
    mides_paga,
    valor_pago  = valor_corrente   # valor corrente (não restos)
  )

# MUNIC MG — membros declarados por setor (só 2015 e 2019)
munic_mg <- munic |>
  filter(uf_mun == "MG") |>
  select(cod_ibge, cnpj_cons = cnpj_consorcio, ano, setor) |>
  mutate(munic_membro = TRUE)

# SICONFI MG
siconfi_mg <- siconfi |>
  filter(uf == "MG") |>
  select(cod_ibge, ano, paga_consorcio, valor_cons_real)

# --- 3. Universo de pares e expansão temporal --------------------------------
# Anos-alvo: cobertura real do MIDES MG (2014–2021)
# Nota: MUNIC 2015 e 2019 caem dentro dessa janela
anos_alvo <- 2014L:2021L

pares <- bind_rows(
  mides_mg |> distinct(cod_ibge, cnpj_cons) |> mutate(fonte_par = "mides"),
  munic_mg  |> distinct(cod_ibge, cnpj_cons) |> mutate(fonte_par = "munic")
) |>
  distinct(cod_ibge, cnpj_cons)

message("Universo MG: ", nrow(pares), " pares únicos (município × consórcio)")

universo <- pares |>
  cross_join(tibble(ano = anos_alvo))

message("Painel expandido: ", nrow(universo), " linhas (",
        nrow(pares), " pares × ", length(anos_alvo), " anos)")

# --- 4. Juntar evidências ----------------------------------------------------
painel <- universo |>
  left_join(mides_mg,   by = join_by(cod_ibge, cnpj_cons, ano)) |>
  left_join(munic_mg,   by = join_by(cod_ibge, cnpj_cons, ano)) |>
  left_join(docs_flag,  by = join_by(cnpj_cons == cnpj)) |>
  left_join(siconfi_mg, by = join_by(cod_ibge, ano)) |>
  replace_na(list(
    mides_paga     = FALSE,
    munic_membro   = FALSE,
    tem_doc_formal = FALSE
  ))

# --- 5. Atribuir categoria ---------------------------------------------------
painel_cat <- painel |>
  mutate(
    # Cortes MUNIC com dados de consórcio (município × consórcio × CNPJ):
    # APENAS 2015 e 2019.
    # Verificado em 2026-05-05: MUNIC 2021 e 2023 NÃO têm seção
    # "Articulação Intermunicipal" — a seção foi retirada após 2019.
    # 2021 tem Msau275/276 (consórcios saúde, mas todos sem preenchimento).
    # 2023 tem apenas MDHU6210 (uma variável em direitos humanos, sem CNPJ).
    ano_tem_munic = ano %in% c(2015L, 2019L),

    categoria = case_when(
      # Cat 1: evidência formal de membro E paga via MIDES
      (munic_membro | (tem_doc_formal & ano_tem_munic)) & mides_paga  ~ 1L,

      # Cat 2: evidência formal de membro MAS não paga (só anos MUNIC)
      munic_membro & !mides_paga                                       ~ 2L,

      # Cat 3: paga via MIDES mas sem evidência formal de membro
      mides_paga & !munic_membro                                       ~ 3L,

      # Cat 4: nenhuma evidência de participação neste ano
      TRUE                                                              ~ 4L
    ),

    categoria_label = case_when(
      categoria == 1L ~ "membro_paga",
      categoria == 2L ~ "membro_inadimplente",
      categoria == 3L ~ "compra_servico",
      categoria == 4L ~ "nao_participa"
    ),

    # Confiança da atribuição
    confianca_cat = case_when(
      munic_membro & mides_paga                          ~ "alta",
      munic_membro & !mides_paga                         ~ "media",
      !munic_membro & mides_paga & tem_doc_formal        ~ "media",
      !munic_membro & mides_paga                         ~ "baixa",
      TRUE                                               ~ "inferida"
    )
  )

# --- 6. Diagnóstico ----------------------------------------------------------
message("\n=== DISTRIBUIÇÃO DE CATEGORIAS (MG, 2014–2021) ===")

painel_cat |>
  count(categoria_label, confianca_cat, name = "n_obs") |>
  arrange(categoria_label, confianca_cat) |>
  print(n = Inf)

message("\n=== RESUMO GERAL ===")
painel_cat |>
  count(categoria_label, name = "n_obs") |>
  mutate(pct = scales::label_percent(accuracy = 0.1)(n_obs / sum(n_obs))) |>
  print()

message("\n=== COBERTURA ===")
painel_cat |>
  filter(categoria != 4L) |>
  summarise(
    n_pares_ativos = n_distinct(paste(cod_ibge, cnpj_cons)),
    n_municipios   = n_distinct(cod_ibge),
    n_consorcios   = n_distinct(cnpj_cons),
    periodo        = paste(range(ano[mides_paga | munic_membro]), collapse = "–"),
    obs_cat1       = sum(categoria == 1L),
    obs_cat2       = sum(categoria == 2L),
    obs_cat3       = sum(categoria == 3L)
  ) |>
  print()

# --- 7. Diagnóstico SICONFI vs MIDES (cobertura) ----------------------------
message("\n=== SICONFI vs MIDES (municípios pagantes MG, 2014–2021) ===")

siconfi_pagantes <- siconfi_mg |>
  filter(ano >= 2014L, paga_consorcio == TRUE) |>
  distinct(cod_ibge, ano)

mides_pagantes <- mides_mg |>
  filter(mides_paga, ano >= 2014L) |>
  distinct(cod_ibge, ano)

siconfi_pagantes |>
  left_join(mides_pagantes |> mutate(tem_mides = TRUE),
            by = join_by(cod_ibge, ano)) |>
  replace_na(list(tem_mides = FALSE)) |>
  summarise(
    siconfi_n = n(),
    mides_n   = sum(tem_mides),
    cobertura = scales::label_percent(accuracy = 0.1)(sum(tem_mides) / n())
  ) |>
  print()
# Se cobertura baixa → municípios pagando consórcios fora do nosso cadastro de CNPJs

# --- 8. Exportar -------------------------------------------------------------
painel_ativo <- painel_cat |>
  filter(categoria != 4L) |>
  select(
    cod_ibge, cnpj_cons, ano,
    categoria, categoria_label, confianca_cat,
    mides_paga, valor_pago,
    munic_membro, setor,
    tem_doc_formal, tem_rateio, tem_protocolo, tem_estatuto,
    paga_consorcio, valor_cons_real
  ) |>
  arrange(cod_ibge, cnpj_cons, ano)

out_rds  <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/outputs/csv_base/painel_mg_categorias.rds"
out_xlsx <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/outputs/csv_base/painel_mg_categorias.xlsx"

saveRDS(painel_ativo, out_rds)
write_xlsx(painel_ativo, out_xlsx)

message("\nSalvo:")
message("  ", out_rds)
message("  ", out_xlsx)
message("  Observações ativas (cat 1–3): ", nrow(painel_ativo))
