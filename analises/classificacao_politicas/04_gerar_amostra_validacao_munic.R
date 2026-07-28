# =============================================================================
# 04_gerar_amostra_validacao_munic.R
# Amostra reprodutivel para validacao humana da regra de consolidacao MUNIC.
# =============================================================================

library(dplyr)
library(readr)
library(writexl)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
class_dir <- file.path(project_dir, "analises", "classificacao_politicas")
out_dir <- file.path(class_dir, "outputs")

path_resumo <- file.path(out_dir, "auditoria_consolidacao_setores_munic_v0_1.csv")
path_detalhe <- file.path(out_dir, "auditoria_consolidacao_setores_munic_detalhe_v0_1.csv")
path_saida <- file.path(out_dir, "amostra_validacao_regra_MUNIC_v0_1.xlsx")

for (path in c(path_resumo, path_detalhe)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

resumo <- read_csv(path_resumo, show_col_types = FALSE)
detalhe <- read_csv(path_detalhe, show_col_types = FALSE)

# A semente torna a amostra permanente e reproduzivel.
set.seed(20260723)

prioritarios <- resumo %>%
  filter(prioridade_revisao_munic == "alta") %>%
  mutate(grupo_amostra = "A. Casos prioritarios heterogeneos")

homogeneos <- resumo %>%
  filter(regra_recomendada_munic == "usar_setor_MUNIC_como_evidencia_setorial") %>%
  slice_sample(n = 5) %>%
  mutate(grupo_amostra = "B. Setor MUNIC unico")

coerentes <- resumo %>%
  filter(regra_recomendada_munic %in% c(
    "usar_MUNIC_como_evidencia_multiarea_mesma_macroarea",
    "usar_areas_MUNIC_com_apoio_do_cadastro"
  )) %>%
  slice_sample(n = 5) %>%
  mutate(grupo_amostra = "C. Multiarea coerente")

heterogeneos <- resumo %>%
  filter(
    regra_recomendada_munic == "nao_unir_automaticamente_areas_MUNIC",
    !cnpj_consorcio %in% prioritarios$cnpj_consorcio
  ) %>%
  slice_sample(n = 5) %>%
  mutate(grupo_amostra = "D. Heterogeneo sem uniao automatica")

amostra <- bind_rows(prioritarios, homogeneos, coerentes, heterogeneos) %>%
  mutate(
    regra_esperada = case_when(
      grupo_amostra == "A. Casos prioritarios heterogeneos" ~
        "Nao unir setores MUNIC; conferir evidencia documental da area principal.",
      grupo_amostra == "B. Setor MUNIC unico" ~
        "Setor MUNIC pode ser usado como evidencia setorial.",
      grupo_amostra == "C. Multiarea coerente" ~
        "Manter mais de uma area, pois ha coerencia por macroarea ou apoio integral do Cadastro IPEA.",
      TRUE ~ "Nao unir setores MUNIC; usar outra fonte ou manter pendencia."
    ),
    conferir = "Conferir se os setores, anos e municipios justificam a regra esperada.",
    parecer = "",
    observacao_validacao = ""
  ) %>%
  select(
    grupo_amostra, cnpj_consorcio, sigla, razao_social,
    areas_munic_auditadas, macroareas_munic_auditadas,
    setores_munic_por_suporte, anos_munic_observados,
    n_pares_municipio_ano_munic, n_municipios_munic,
    areas_cadastro_ipea, areas_nome_razao_social,
    regra_recomendada_munic, regra_esperada, conferir,
    parecer, observacao_validacao
  ) %>%
  arrange(grupo_amostra, cnpj_consorcio)

evidencia <- detalhe %>%
  semi_join(amostra, by = "cnpj_consorcio") %>%
  left_join(amostra %>% select(grupo_amostra, cnpj_consorcio, sigla, razao_social), by = "cnpj_consorcio") %>%
  select(
    grupo_amostra, cnpj_consorcio, sigla, razao_social,
    area_munic, macroarea_munic, anos, n_pares_municipio_ano,
    n_municipios, pct_pares_municipio_ano, pct_municipios,
    municipios_exemplo
  ) %>%
  arrange(grupo_amostra, cnpj_consorcio, desc(n_pares_municipio_ano), area_munic)

instrucoes <- tibble(
  etapa = c("1", "2", "3", "4"),
  como_conferir = c(
    "Na aba Amostra, leia a regra esperada para o CNPJ.",
    "Na aba Evidencia MUNIC, verifique quantidade de registros, anos, municipios e setores observados.",
    "Compare a evidencia com o cadastro IPEA e, quando necessario, com estatuto ou portal institucional.",
    "Preencha parecer com APROVADO, AJUSTAR ou PESQUISAR e explique divergencias em observacao_validacao."
  )
)

writexl::write_xlsx(
  list(
    "Instrucoes" = instrucoes,
    "Amostra" = amostra,
    "Evidencia MUNIC" = evidencia
  ),
  path_saida
)

cat("Amostra de validacao criada:", path_saida, "\n")
cat("CNPJs na amostra:", nrow(amostra), "\n")
