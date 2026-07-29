# Testes da trajetoria longitudinal MIDES 2014-2021.

project_dir <- normalizePath(".", winslash = "/", mustWork = TRUE)
setwd(file.path(project_dir, "dashboards", "base1_shiny"))
source("app.R", local = globalenv())

codap <- movimentos_analiticos |>
  filter(cnpj_consorcio == "08753385000170")
codap_resumo <- resumir_movimentos_longitudinais(codap)

stopifnot(
  nrow(codap_resumo) == 8L,
  identical(codap_resumo$ano, 2014:2021),
  codap_resumo$pares_ativos[codap_resumo$ano == 2019L] == 10L,
  codap_resumo$entradas_novas[codap_resumo$ano == 2019L] == 5L,
  codap_resumo$retornos[codap_resumo$ano == 2019L] == 1L,
  codap_resumo$saldo_liquido[codap_resumo$ano == 2019L] == 6L,
  sum(codap_resumo$saldo_liquido) == 18L
)

compacto <- html_trajetoria_compacta(codap_resumo)
detalhe <- html_detalhe_longitudinal(codap, codap_resumo)

stopifnot(
  lengths(regmatches(compacto, gregexpr("trajectory-mini-year", compacto, fixed = TRUE))) == 8L,
  grepl("<dt>Entradas</dt><dd>5</dd>", compacto, fixed = TRUE),
  grepl("<dt>Retornos</dt><dd>1</dd>", compacto, fixed = TRUE),
  !grepl("&#8634;", compacto, fixed = TRUE),
  grepl("Matriz municipio x ano", detalhe, fixed = TRUE),
  !grepl("Listas de municipios por evento", detalhe, fixed = TRUE),
  grepl("Entre Rios De Minas", detalhe, fixed = TRUE),
  grepl("state-exit", detalhe, fixed = TRUE),
  grepl("2014", detalhe, fixed = TRUE),
  grepl("2021", detalhe, fixed = TRUE)
)

shiny::testServer(server, {
  session$setInputs(
    mides_ano = 2014:2021,
    mides_municipio = character(),
    mides_consorcio = "CODAP",
    mides_area = character(),
    mides_macrogrupo = character(),
    mides_perfil = character(),
    mides_busca = ""
  )
  session$flushReact()

  tabela <- output$tabela_trajetoria_consorcios
  stopifnot(length(tabela) > 0L)
})

cat("Testes da trajetoria longitudinal aprovados.\n")
