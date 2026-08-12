library(dplyr)
library(readr)
library(stringr)

project_dir <- normalizePath(".", winslash = "/", mustWork = TRUE)
source(file.path(project_dir, "dashboards/base1_shiny/auditoria_baixa_escala.R"), encoding = "UTF-8")

movimentos <- readRDS(file.path(project_dir, "analises/movimentos_espaciais/outputs/movimentos_municipio_consorcio_ano.rds"))
cadastro <- readRDS(file.path(project_dir, "dashboards/base1_shiny/data/cadastro_base.rds")) |>
  transmute(
    cnpj_consorcio = cnpj,
    sigla_cadastro = coalesce(sigla, "(sem sigla)"),
    razao_social_cadastro = coalesce(razao_social, "(sem razao social)"),
    situacao_cadastro = coalesce(situacao, "(sem situacao)"),
    ano_fundacao,
    municipio_sede,
    natureza_juridica = nat_juridica
  )
classificacao <- readRDS(file.path(project_dir, "dashboards/base1_shiny/data/classificacao_areas_politica_mg_v0_5.rds")) |>
  transmute(
    cnpj_consorcio,
    area_politica = area_politica_final,
    macrogrupo_politica = macroarea_final,
    perfil_classificacao = perfil_institucional,
    status_classificacao = status_validacao,
    ativo_classificacao = ativo_analise
  )

auditoria <- construir_auditoria_baixa_escala(movimentos, cadastro, classificacao)
resumo <- auditoria |>
  count(max_municipios_ano, padrao_temporal, tipo_estabelecimento, situacao_cadastro, name = "n_cnpjs") |>
  arrange(max_municipios_ano, padrao_temporal, tipo_estabelecimento, situacao_cadastro)

out_dir <- file.path(project_dir, "analises/movimentos_espaciais/outputs")
write_csv(auditoria, file.path(out_dir, "auditoria_baixa_escala_cnpj.csv"), na = "")
saveRDS(auditoria, file.path(out_dir, "auditoria_baixa_escala_cnpj.rds"))
write_csv(resumo, file.path(out_dir, "auditoria_baixa_escala_resumo.csv"), na = "")

cat("CNPJs auditados:", nrow(auditoria), "\n")
print(resumo, n = Inf)
