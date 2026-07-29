library(shiny)
library(bslib)
library(dplyr)
library(readr)

app_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
project_dir <- normalizePath(file.path(app_dir, "..", ".."), winslash = "/", mustWork = TRUE)
out_dir <- file.path(project_dir, "analises", "movimentos_espaciais", "outputs")

source(file.path(app_dir, "documentacao_movimentos.R"), encoding = "UTF-8")

stopifnot(
  file.exists(file.path(app_dir, "www", "pipeline_movimentos_mides.png")),
  file.exists(file.path(app_dir, "www", "exposicao_espacial_mides.png"))
)

html_doc <- as.character(documentacao_movimentos_ui())
conteudos_obrigatorios <- c(
  "Movimentos financeiros e exposição espacial",
  "pipeline_movimentos_mides.png",
  "exposicao_espacial_mides.png",
  "Poté × CISNORJE × 2021",
  "742.916 exposições",
  "12.842 exposições",
  "R$ 27.210,15",
  "2,22",
  "0,79",
  "MIDES observa pagamentos"
)
stopifnot(all(vapply(conteudos_obrigatorios, grepl, logical(1), x = html_doc, fixed = TRUE)))

movimentos <- readRDS(file.path(out_dir, "movimentos_municipio_consorcio_ano.rds"))
entrada <- readRDS(file.path(out_dir, "risco_entrada_completo_municipio_consorcio_ano.rds"))
vizinhos <- readRDS(file.path(out_dir, "vizinhos_municipais_mg.rds"))
modelos <- read_csv(file.path(out_dir, "modelos_logisticos_resultados.csv"), show_col_types = FALSE)

cnpj_exemplo <- "13220150000152"
municipio_exemplo <- "315240"

serie_exemplo <- movimentos |>
  filter(cod_ibge_6 == municipio_exemplo, cnpj_consorcio == cnpj_exemplo) |>
  arrange(ano)

stopifnot(
  nrow(serie_exemplo) == 8L,
  identical(serie_exemplo$ano, 2014:2021),
  all(serie_exemplo$valor_total[serie_exemplo$ano < 2021] == 0),
  isTRUE(all.equal(serie_exemplo$valor_total[serie_exemplo$ano == 2021], 27210.15)),
  serie_exemplo$evento_movimento[serie_exemplo$ano == 2021] == "entrada_observada"
)

risco_exemplo <- entrada |>
  filter(
    ano == 2021,
    cod_ibge_6 == municipio_exemplo,
    cnpj_consorcio == cnpj_exemplo
  )

stopifnot(
  nrow(risco_exemplo) == 1L,
  risco_exemplo$n_vizinhos_total == 5L,
  risco_exemplo$n_vizinhos_no_consorcio_t_1 == 5L,
  risco_exemplo$prop_vizinhos_no_consorcio_t_1 == 1,
  risco_exemplo$membros_consorcio_t_1 == 60L,
  risco_exemplo$candidato_externo_adjacente_t_1,
  risco_exemplo$entrada_nova_observada
)

vizinhos_exemplo <- bind_rows(
  vizinhos |>
    filter(municipio_a == municipio_exemplo) |>
    transmute(cod_ibge_6 = municipio_b, municipio = nome_municipio_b),
  vizinhos |>
    filter(municipio_b == municipio_exemplo) |>
    transmute(cod_ibge_6 = municipio_a, municipio = nome_municipio_a)
)

presenca_vizinhos <- vizinhos_exemplo |>
  left_join(
    movimentos |>
      filter(ano == 2020, cnpj_consorcio == cnpj_exemplo) |>
      select(cod_ibge_6, presente_mides, valor_total),
    by = "cod_ibge_6"
  )

valores_esperados <- c(
  "Franciscópolis" = 10440,
  "Itambacuri" = 41056.2,
  "Ladainha" = 25491,
  "Malacacheta" = 33796.8,
  "Teófilo Otoni" = 581758.08
)
stopifnot(
  nrow(presenca_vizinhos) == 5L,
  all(presenca_vizinhos$presente_mides),
  all.equal(
    sort(setNames(presenca_vizinhos$valor_total, presenca_vizinhos$municipio)),
    sort(valores_esperados),
    check.attributes = FALSE
  ) == TRUE
)

modelo_entrada <- modelos |>
  filter(
    regra_presenca == "principal_total_positivo",
    modelo == "entrada_prop_vizinhos_10pp"
  )
modelo_saida <- modelos |>
  filter(
    regra_presenca == "principal_total_positivo",
    modelo == "saida_prop_vizinhos_10pp"
  )

stopifnot(
  round(modelo_entrada$odds_ratio, 2) == 2.22,
  round(modelo_saida$odds_ratio, 2) == 0.79
)

message("Documentacao de movimentos validada")
message("  Exemplo: Pote x CISNORJE x 2021")
message("  Vizinhos conferidos: 5 de 5")
message("  Numeros e imagens: aprovados")
