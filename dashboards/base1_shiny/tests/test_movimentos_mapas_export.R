# Testes da tabela anual, rotulos condicionais e exportacao cartografica.

project_dir <- normalizePath(".", winslash = "/", mustWork = TRUE)
setwd(file.path(project_dir, "dashboards", "base1_shiny"))
source("app.R", local = globalenv())

stopifnot(nrow(movimentos_analiticos) == 22680L)
stopifnot(n_distinct(paste(movimentos_analiticos$cod_ibge_6, movimentos_analiticos$cnpj_consorcio)) == 2835L)
stopifnot(n_distinct(movimentos_analiticos$cnpj_consorcio) == 161L)

codap_2019 <- movimentos_analiticos |>
  filter(cnpj_consorcio == "08753385000170", ano == 2019L)

stopifnot(
  sum(codap_2019$presente_mides) == 10L,
  sum(codap_2019$evento_movimento == "entrada_observada") == 5L,
  sum(codap_2019$evento_movimento == "retorno_observado") == 1L,
  sum(codap_2019$evento_movimento == "saida_observada") == 0L,
  sum(codap_2019$evento_movimento == "permaneceu") == 4L,
  sum(codap_2019$delta_presenca) == 6L,
  sum(codap_2019$presente_mides & codap_2019$movimento_recorrente) == 1L
)

mapa_teste <- mg_municipios_sf |>
  mutate(
    municipio = str_to_title(municipio_geo),
    mapa_valor = if_else(row_number() <= 12L, as.numeric(row_number()) * 1000, 0),
    tem_registro = mapa_valor > 0,
    tooltip_mides = municipio
  )

rotulos_12 <- selecionar_rotulos_mapa(mapa_teste, "tem_registro", limite = 12L)
stopifnot(nrow(rotulos_12) == 12L)

mapa_13 <- mapa_teste |>
  mutate(
    mapa_valor = if_else(row_number() <= 13L, as.numeric(row_number()) * 1000, 0),
    tem_registro = mapa_valor > 0
  )
stopifnot(nrow(selecionar_rotulos_mapa(mapa_13, "tem_registro", limite = 12L)) == 0L)

rotulo_explicito <- selecionar_rotulos_mapa(
  mapa_13, "tem_registro", municipios_selecionados = mapa_13$municipio[1], limite = 12L
)
stopifnot(nrow(rotulo_explicito) == 1L)
contexto_explicito <- recortar_contexto_mapa(mapa_13, rotulo_explicito)
stopifnot(nrow(contexto_explicito) > 1L, nrow(contexto_explicito) < nrow(mapa_13))

plot_teste <- criar_plot_mides(
  mapa_teste, "valor_total", 2019L, rotulos = rotulos_12, interativo = FALSE
)
invisible(suppressWarnings(ggplot_build(plot_teste)))

mapa_categorico <- mapa_teste |>
  mutate(
    classe_fontes = factor(
      if_else(tem_registro, "Predominio MIDES+MUNIC", "Sem par no filtro"),
      levels = names(paleta_fontes)
    ),
    tooltip_fontes = municipio,
    classe_transicao = factor(
      if_else(tem_registro, "Permaneceu", "Sem par no filtro"),
      levels = names(paleta_transicao)
    ),
    tooltip_transicao = municipio
  )
invisible(suppressWarnings(ggplot_build(
  criar_plot_categorico(mapa_categorico, "fontes", rotulos_12, interativo = FALSE)
)))
invisible(suppressWarnings(ggplot_build(
  criar_plot_categorico(mapa_categorico, "transicao", rotulos_12, interativo = FALSE)
)))

mapa_movimento <- bind_rows(
  mapa_teste |> mutate(ano = 2019L, classe_movimento = factor(if_else(tem_registro, "Entrou", "Sem dado"), levels = names(paleta_mov_mides))),
  mapa_teste |> mutate(ano = 2020L, classe_movimento = factor(if_else(tem_registro, "Permaneceu", "Sem dado"), levels = names(paleta_mov_mides)))
)
invisible(suppressWarnings(ggplot_build(criar_plot_movimento(mapa_movimento, rotulos_12))))

png_teste <- tempfile(fileext = ".png")
pdf_teste <- tempfile(fileext = ".pdf")
salvar_mapa_alta_resolucao(plot_teste, png_teste, "png")
salvar_mapa_alta_resolucao(plot_teste, pdf_teste, "pdf")

stopifnot(
  file.exists(png_teste), file.info(png_teste)$size > 100000,
  file.exists(pdf_teste), file.info(pdf_teste)$size > 10000,
  readChar(pdf_teste, nchars = 4L, useBytes = TRUE) == "%PDF"
)
if (requireNamespace("png", quietly = TRUE)) {
  dimensoes_png <- dim(png::readPNG(png_teste, native = TRUE, info = TRUE))
  stopifnot(identical(as.integer(dimensoes_png[1:2]), c(3600L, 5400L)))
}

unlink(c(png_teste, pdf_teste))
cat("Testes da tabela anual, mapas e exportacao aprovados.\n")
