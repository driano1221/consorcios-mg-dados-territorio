# Testes de integracao da classificacao v0.5 nos filtros do MIDES completo.

library(shiny)

project_dir <- normalizePath(".", winslash = "/", mustWork = TRUE)
setwd(file.path(project_dir, "dashboards", "base1_shiny"))
source("app.R", local = globalenv())

stopifnot(nrow(mides_anual) == 15135L)
stopifnot(n_distinct(mides_anual$cnpj_consorcio) == 161L)
stopifnot(!("Sem classificacao ativa" %in% c(names(mides_areas_opts), unname(mides_areas_opts))))
stopifnot("saude" %in% unname(mides_areas_opts))
stopifnot(!any(unname(mides_perfis_opts) %in% c("multifinalitario", "multissetorial", "associacao_municipal")))
stopifnot("multifinalitario_ou_multissetorial" %in% unname(mides_perfis_opts))
stopifnot(any(mides_anual$cobertura_classificacao == "Consorcio sediado fora de MG"))

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

  area_teste <- "saude"
  session$setInputs(mides_area = area_teste)
  por_area <- dados_mides_filtrados()
  stopifnot(nrow(por_area) > 0L, all(tem_categoria(por_area$area_politica, area_teste)))

  session$setInputs(mides_area = character(0), mides_macrogrupo = "saude")
  por_macrogrupo <- dados_mides_filtrados()
  stopifnot(nrow(por_macrogrupo) > 0L, all(tem_categoria(por_macrogrupo$macrogrupo_politica, "saude")))

  session$setInputs(mides_macrogrupo = character(0), mides_perfil = "setorial")
  por_perfil <- dados_mides_filtrados()
  stopifnot(nrow(por_perfil) > 0L, all(por_perfil$perfil_classificacao == "setorial"))

  session$setInputs(mides_perfil = character(0), mides_area = character(0))
  cobertura <- mides_anual |> distinct(cnpj_consorcio, cobertura_classificacao)
  stopifnot(sum(cobertura$cobertura_classificacao == "Area classificada") == 136L)
  stopifnot(sum(cobertura$cobertura_classificacao == "Perfil institucional sem area especifica") == 15L)
  stopifnot(sum(cobertura$cobertura_classificacao == "Consorcio sediado fora de MG") == 8L)
  stopifnot(sum(cobertura$cobertura_classificacao == "Entidade associativa fora do escopo") == 1L)

  session$setInputs(mides_area = area_teste, mides_municipio = unique(por_area$municipio)[1])
  mapa <- dados_mides_mapa()
  stopifnot(sum(mapa$tem_registro) >= 1L)

  session$setInputs(mides_municipio = character(0), mides_ano = 2019L)
  movimento <- dados_mides_movimento_base()
  cnpjs_area <- unique(mides_anual$cnpj_consorcio[tem_categoria(mides_anual$area_politica, area_teste)])
  stopifnot(nrow(movimento) > 0L, all(movimento$cnpj_consorcio %in% cnpjs_area))
})

cat("Testes de classificacao v0.5 aprovados.\n")
