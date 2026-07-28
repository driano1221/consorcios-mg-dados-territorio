# =============================================================================
# 03_validar_movimentos_espaciais.R
# Verificacoes de consistencia das bases materializadas de movimentos e fronteira.
# =============================================================================

library(dplyr)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(project_dir, "analises", "movimentos_espaciais", "outputs")

movimentos <- readRDS(file.path(out_dir, "movimentos_municipio_consorcio_ano.rds"))
resumo_par <- readRDS(file.path(out_dir, "movimentos_resumo_par.rds"))
vizinhos <- readRDS(file.path(out_dir, "vizinhos_municipais_mg.rds"))
grau <- readRDS(file.path(out_dir, "grau_vizinhanca_municipal_mg.rds"))
candidatos_entrada <- readRDS(file.path(out_dir, "risco_entrada_fronteira_municipio_consorcio_ano.rds"))
features <- readRDS(file.path(out_dir, "features_espaciais_municipio_consorcio_ano.rds"))

anos <- sort(unique(movimentos$ano))
pares <- nrow(resumo_par)

stopifnot(
  nrow(movimentos) == pares * length(anos),
  nrow(distinct(movimentos, ano, cod_ibge_6, cnpj_consorcio)) == nrow(movimentos),
  all(movimentos$regra_presenca == "valor_total_positivo"),
  all(movimentos$presente_mides == (movimentos$valor_total > 0)),
  all(resumo_par$n_transicoes == resumo_par$n_entradas_observadas + resumo_par$n_saidas_observadas),
  nrow(grau) == 853L,
  all(grau$n_vizinhos_total > 0L),
  nrow(vizinhos) > 1000L,
  all(vizinhos$comprimento_divisa_km > 0),
  nrow(candidatos_entrada) > 0L,
  all(candidatos_entrada$n_vizinhos_no_consorcio_t_1 > 0L),
  all(candidatos_entrada$tipo_exposicao_t_1 == "candidato_vizinho_do_consorcio"),
  nrow(features) == nrow(movimentos),
  nrow(distinct(features, ano, cod_ibge_6, cnpj_consorcio)) == nrow(features)
)

# Em cada ano, pares presentes sao exatamente a soma das classes ativas.
checagem_eventos <- movimentos |>
  summarise(
    pares_presentes = sum(presente_mides),
    pares_classes_ativas = sum(evento_movimento %in% c(
      "base_inicial", "permaneceu", "entrada_observada", "retorno_observado"
    )),
    .by = ano
  )
stopifnot(all(checagem_eventos$pares_presentes == checagem_eventos$pares_classes_ativas))

# Toda saida tem exposicao espacial medida enquanto o par ainda estava ativo.
saidas <- features |>
  filter(evento_movimento == "saida_observada")
stopifnot(all(!is.na(saidas$prop_vizinhos_no_consorcio_t_1)))

message("Validacao aprovada")
message("  Pares: ", pares)
message("  Linhas anuais: ", nrow(movimentos))
message("  Fronteiras compartilhadas: ", nrow(vizinhos))
message("  Candidatos de entrada por borda: ", nrow(candidatos_entrada))
