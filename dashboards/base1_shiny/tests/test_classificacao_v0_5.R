# Testes de integracao da classificacao v0.5 nos filtros do MIDES completo.

library(shiny)

project_dir <- normalizePath(".", winslash = "/", mustWork = TRUE)
setwd(file.path(project_dir, "dashboards", "base1_shiny"))
source("app.R", local = globalenv())

stopifnot(nrow(mides_anual) == 15135L)
stopifnot(n_distinct(mides_anual$cnpj_consorcio) == 161L)
stopifnot("Sem classificacao ativa" %in% mides_areas_opts)
stopifnot(any(mides_anual$area_politica != "Sem classificacao ativa"))

shiny::testServer(server, {
  session$setInputs(
    mides_ano = mides_anos_opts,
    mides_regra_valor = "total",
    mides_municipio = character(0),
    mides_consorcio = character(0),
    mides_area = character(0),
    mides_macrogrupo = character(0),
    mides_perfil = character(0),
    mides_busca = "",
    mides_mapa_metrica = "valor_total"
  )

  todos <- dados_mides_filtrados()
  stopifnot(nrow(todos) > 0L)

  area_teste <- setdiff(mides_areas_opts, "Sem classificacao ativa")[1]
  session$setInputs(mides_area = area_teste)
  por_area <- dados_mides_filtrados()
  stopifnot(nrow(por_area) > 0L, all(por_area$area_politica == area_teste))

  session$setInputs(mides_area = character(0), mides_macrogrupo = "saude")
  por_macrogrupo <- dados_mides_filtrados()
  stopifnot(nrow(por_macrogrupo) > 0L, all(por_macrogrupo$macrogrupo_politica == "saude"))

  session$setInputs(mides_macrogrupo = character(0), mides_perfil = "setorial")
  por_perfil <- dados_mides_filtrados()
  stopifnot(nrow(por_perfil) > 0L, all(por_perfil$perfil_classificacao == "setorial"))

  session$setInputs(mides_perfil = character(0), mides_area = "Sem classificacao ativa")
  sem_classificacao <- dados_mides_filtrados()
  stopifnot(nrow(sem_classificacao) > 0L, all(sem_classificacao$area_politica == "Sem classificacao ativa"))

  session$setInputs(mides_area = area_teste, mides_municipio = unique(por_area$municipio)[1])
  mapa <- dados_mides_mapa()
  stopifnot(sum(mapa$tem_registro) >= 1L)

  session$setInputs(mides_municipio = character(0), mides_ano = 2019L)
  movimento <- dados_mides_movimento_base()
  cnpjs_area <- unique(mides_anual$cnpj_consorcio[mides_anual$area_politica == area_teste])
  stopifnot(nrow(movimento) > 0L, all(movimento$cnpj_consorcio %in% cnpjs_area))
})

cat("Testes de classificacao v0.5 aprovados.\n")
