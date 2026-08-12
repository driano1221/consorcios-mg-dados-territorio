library(dplyr)

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

stopifnot(nrow(auditoria) == 23L)
stopifnot(n_distinct(auditoria$cnpj_consorcio) == 23L)
stopifnot(all(auditoria$max_municipios_ano <= 2L))
stopifnot(sum(auditoria$max_municipios_ano == 1L) == 12L)
stopifnot(sum(auditoria$max_municipios_ano == 2L) == 11L)
stopifnot(sum(auditoria$tipo_estabelecimento == "Filial") == 6L)
stopifnot(sum(auditoria$padrao_temporal == "Continuo em baixa escala") == 11L)
stopifnot(sum(auditoria$padrao_temporal == "Intermitente") == 5L)
stopifnot(sum(auditoria$padrao_temporal == "Observado em um ano") == 7L)
stopifnot(all(!is.na(auditoria$hipotese_revisao) & auditoria$hipotese_revisao != ""))
stopifnot(all(!is.na(auditoria$evidencia_automatica) & auditoria$evidencia_automatica != ""))

cat("Auditoria de baixa escala validada: 23 CNPJs.\n")
