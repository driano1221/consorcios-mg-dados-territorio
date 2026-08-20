library(testthat)
library(dplyr)

find_project_dir <- function(path = getwd()) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  repeat {
    if (dir.exists(file.path(path, ".git"))) return(path)
    parent <- dirname(path)
    if (identical(parent, path)) stop("Raiz do projeto nao encontrada.")
    path <- parent
  }
}
project_dir <- find_project_dir()
app_dir <- file.path(project_dir, "dashboards", "base1_shiny")
data_dir <- file.path(app_dir, "data")

paths <- c(
  anual = "mides_nacional_anual_app.rds",
  cadastro = "cadastro_nacional_consolidado_app.rds",
  movimentos = "mides_nacional_movimentos_app.rds",
  municipios = "brasil_municipios_mides_sf_web.rds",
  estados = "brasil_estados_contorno_sf_web.rds",
  brasil = "brasil_contorno_sf_web.rds",
  cobertura = "mides_nacional_cobertura_app.rds",
  sem_municipio = "mides_nacional_sem_municipio_app.rds"
)
paths <- setNames(file.path(data_dir, unname(paths)), names(paths))

test_that("artefatos nacionais estao presentes e coerentes", {
  expect_true(all(file.exists(paths)))
  anual <- readRDS(paths[["anual"]])
  cadastro <- readRDS(paths[["cadastro"]])
  movimentos <- readRDS(paths[["movimentos"]])
  cobertura <- readRDS(paths[["cobertura"]])
  sem_municipio <- readRDS(paths[["sem_municipio"]])

  expect_equal(nrow(cadastro), 1159L)
  expect_equal(sum(cadastro$encontrado_mides), 505L)
  expect_equal(nrow(anual), 40486L)
  expect_equal(nrow(movimentos), 73783L)
  expect_equal(n_distinct(anual$cnpj_raiz_8), 505L)
  expect_equal(n_distinct(paste(anual$id_municipio, anual$cnpj_raiz_8)), 7560L)
  expect_equal(sort(unique(anual$uf_municipio_pagador)), c("CE", "DF", "MG", "PB", "PR", "RS", "SC", "SP"))
  expect_equal(nrow(cobertura), 8L)
  expect_equal(sum(sem_municipio$n_transacoes), 681)
  expect_equal(sum(sem_municipio$valor_total), 11145961.39, tolerance = 0.01)
})

test_that("consolidacao por raiz preserva chaves e valores", {
  anual <- readRDS(paths[["anual"]])
  cadastro <- readRDS(paths[["cadastro"]])

  expect_equal(nrow(anual), nrow(distinct(anual, uf_municipio_pagador, id_municipio, cnpj_raiz_8, ano)))
  expect_equal(nrow(cadastro), nrow(distinct(cadastro, cnpj_raiz_8)))
  expect_true(all(cadastro$cnpj_canonico == cadastro$cnpj_matriz))
  expect_true(all(substr(cadastro$cnpj_matriz, 9, 12) == "0001"))
  expect_equal(sum(cadastro$n_filiais), 35L)
  expect_equal(sum(cadastro$tem_filial), 23L)
  expect_equal(sum(anual$valor_total), 15168694503.38, tolerance = 0.01)
})

test_that("lacunas de cobertura nao viram entrada ou saida", {
  movimentos <- readRDS(paths[["movimentos"]])
  nao_comparaveis <- movimentos |> filter(!comparavel_ano_anterior)
  expect_false(any(nao_comparaveis$evento_movimento %in% c("entrada_observada", "retorno_observado", "saida_observada")))
  expect_true(all(nao_comparaveis$delta_presenca == 0L))

  comparaveis <- movimentos |> filter(comparavel_ano_anterior)
  expect_true(all(comparaveis$evento_movimento %in% c("entrada_observada", "retorno_observado", "permaneceu", "saida_observada", "ausente")))
})

test_that("funcoes nacionais e app principal carregam", {
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  if (!l10n_info()[["UTF-8"]]) try(Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8"), silent = TRUE)
  setwd(app_dir)
  env <- new.env(parent = globalenv())
  source("app.R", local = env, encoding = "UTF-8")
  expect_true(is.function(env$mides_nacional_ui))
  expect_true(is.function(env$mides_nacional_server))
  expect_s3_class(env$ui, "bslib_page")

  shiny::testServer(env$mides_nacional_server, args = list(dados = env$dados_mides_nacional), {
    session$setInputs(
      ano = sort(unique(env$dados_mides_nacional$anual$ano)),
      uf_pagadora = sort(unique(env$dados_mides_nacional$anual$uf_municipio_pagador)),
      uf_sede = character(), municipio = character(), consorcio = character(),
      busca = "", regra_valor = "total", metrica = "valor_total", mov_ano = 2021,
      audit_uf = character(), audit_filial = "todos", audit_mides = "todos", audit_busca = ""
    )
    expect_equal(output$universo_cadastral, "1.159")
    expect_equal(output$universo_financeiro, "505")
    expect_equal(output$universo_sem_mides, "654")
    expect_equal(output$kpi_linhas, "40.284")
    expect_equal(output$kpi_pares, "7.542")
    expect_equal(output$kpi_consorcios, "504")
    expect_match(output$kpi_sem_municipio, "681")
    expect_s3_class(output$mapa, "json")
  })
})
