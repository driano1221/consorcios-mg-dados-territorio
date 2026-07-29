# =============================================================================
# 06_validar_modelos_risco.R
# Testes dos universos de risco e dos modelos exploratorios.
# =============================================================================

library(dplyr)
library(readr)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(project_dir, "analises", "movimentos_espaciais", "outputs")

entrada <- readRDS(file.path(out_dir, "risco_entrada_completo_municipio_consorcio_ano.rds"))
saida <- readRDS(file.path(out_dir, "risco_saida_municipio_consorcio_ano.rds"))
movimentos <- readRDS(file.path(out_dir, "movimentos_municipio_consorcio_ano.rds"))
fora_risco <- read_csv(
  file.path(out_dir, "eventos_entrada_fora_universo_modelo.csv"),
  show_col_types = FALSE
) |>
  filter(regra_presenca == "principal_total_positivo")
modelos <- read_csv(
  file.path(out_dir, "modelos_logisticos_resultados.csv"),
  show_col_types = FALSE
)
vizinhos <- readRDS(file.path(out_dir, "vizinhos_municipais_mg.rds"))

stopifnot(
  nrow(entrada) == nrow(distinct(entrada, ano, cod_ibge_6, cnpj_consorcio)),
  nrow(saida) == nrow(distinct(saida, ano, cod_ibge_6, cnpj_consorcio)),
  all(entrada$ano > 2014L),
  all(saida$ano > 2014L),
  all(entrada$n_vizinhos_no_consorcio_t_1 <= entrada$n_vizinhos_total),
  all(saida$n_vizinhos_no_consorcio_t_1 <= saida$n_vizinhos_total),
  all(entrada$prop_vizinhos_no_consorcio_t_1 >= 0),
  all(entrada$prop_vizinhos_no_consorcio_t_1 <= 1),
  all(saida$prop_vizinhos_no_consorcio_t_1 >= 0),
  all(saida$prop_vizinhos_no_consorcio_t_1 <= 1),
  all(
    entrada$candidato_externo_adjacente_t_1 ==
      (entrada$n_vizinhos_no_consorcio_t_1 > 0)
  ),
  all(
    saida$participante_isolado_t_1 ==
      (saida$n_vizinhos_no_consorcio_t_1 == 0)
  ),
  all(
    saida$participante_na_borda_t_1 ==
      (saida$n_vizinhos_fora_consorcio_t_1 > 0)
  )
)

# Recalculo independente da exposicao espacial em uma amostra reprodutivel.
vizinhos_direcionados <- bind_rows(
  vizinhos |> transmute(cod_ibge_6 = municipio_a, vizinho_ibge_6 = municipio_b),
  vizinhos |> transmute(cod_ibge_6 = municipio_b, vizinho_ibge_6 = municipio_a)
)
ativos_t_1 <- movimentos |>
  filter(presente_mides) |>
  transmute(
    ano = ano + 1L,
    vizinho_ibge_6 = cod_ibge_6,
    cnpj_consorcio,
    vizinho_ativo = TRUE
  )

set.seed(20260728)
amostra_exposicao <- bind_rows(
  entrada |> slice_sample(n = 250L),
  saida |> slice_sample(n = 250L)
) |>
  select(ano, cod_ibge_6, cnpj_consorcio, n_vizinhos_no_consorcio_t_1) |>
  mutate(id_amostra = row_number())

recalculo_exposicao <- amostra_exposicao |>
  inner_join(vizinhos_direcionados, by = "cod_ibge_6", relationship = "many-to-many") |>
  left_join(
    ativos_t_1,
    by = c("ano", "vizinho_ibge_6", "cnpj_consorcio")
  ) |>
  summarise(
    observado = first(n_vizinhos_no_consorcio_t_1),
    recalculado = sum(coalesce(vizinho_ativo, FALSE)),
    .by = id_amostra
  )
stopifnot(all(recalculo_exposicao$observado == recalculo_exposicao$recalculado))

# Em cada consorcio-ano elegivel, os membros e nao membros particionam os 853
# municipios de Minas Gerais.
particao <- bind_rows(
  entrada |> count(ano, cnpj_consorcio, name = "n_entrada"),
  saida |> count(ano, cnpj_consorcio, name = "n_saida")
) |>
  summarise(n_municipios = sum(c(n_entrada, n_saida), na.rm = TRUE), .by = c(ano, cnpj_consorcio))
stopifnot(all(particao$n_municipios == 853L))

# Toda saida observada apos 2014 pertence necessariamente ao universo de risco.
saidas_movimentos <- movimentos |>
  filter(evento_movimento == "saida_observada") |>
  nrow()
stopifnot(sum(saida$saiu_observado) == saidas_movimentos)

# Entradas modeladas e eventos sem CNPJ ativo em t-1 recompõem todos os eventos
# de entrada/retorno da serie original.
entradas_movimentos <- movimentos |>
  filter(evento_movimento %in% c("entrada_observada", "retorno_observado")) |>
  nrow()
stopifnot(sum(entrada$entrou_observado) + nrow(fora_risco) == entradas_movimentos)
stopifnot(
  sum(entrada$entrou_observado) ==
    sum(entrada$entrada_nova_observada) + sum(entrada$retorno_observado)
)

# Os sinais principais devem ser estaveis nas quatro regras de presenca.
modelos_prop <- modelos |>
  filter(modelo %in% c("entrada_prop_vizinhos_10pp", "saida_prop_vizinhos_10pp"))
stopifnot(
  nrow(modelos_prop) == 8L,
  all(is.finite(modelos_prop$odds_ratio)),
  all(modelos_prop$ic95_inferior > 0),
  all(modelos_prop$ic95_superior > modelos_prop$ic95_inferior),
  all(modelos_prop$odds_ratio[modelos_prop$modelo == "entrada_prop_vizinhos_10pp"] > 1),
  all(modelos_prop$odds_ratio[modelos_prop$modelo == "saida_prop_vizinhos_10pp"] < 1)
)

message("Validacao dos modelos aprovada")
message("  Universo de entrada: ", nrow(entrada))
message("  Entradas/retornos modelados: ", sum(entrada$entrou_observado))
message("  Entradas fora do universo: ", nrow(fora_risco))
message("  Universo de saida: ", nrow(saida))
message("  Saidas modeladas: ", sum(saida$saiu_observado))
