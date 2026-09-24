# Executar da raiz do repositorio apos o script 25. Valida os artefatos gravados.
suppressPackageStartupMessages(library(dplyr))
if (.Platform$OS.type == "windows") Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8")
model <- "analises/modelo_gravitacional_saude"
out <- file.path(model, "outputs")
dest <- file.path(out, "base_v1")
read_table <- function(path) read.csv(path, colClasses = "character",
  fileEncoding = "UTF-8-BOM", check.names = FALSE)
p <- readRDS(file.path(out, "painel_anual_integrado_saude_mg_2014_2021.rds"))
f <- readRDS(file.path(dest, "base_financeira_v1.rds"))
g <- readRDS(file.path(dest, "base_gravitacional_v1.rds"))
keys <- c("id_municipio", "cnpj_raiz_8", "ano")
key <- function(x) do.call(paste, c(x[keys], sep = "_"))
stopifnot(nrow(f) == 491328L, ncol(f) == 19L,
  nrow(g) == 323287L, ncol(g) == 30L,
  !anyDuplicated(f[keys]), !anyDuplicated(g[keys]),
  setequal(key(f), key(p[p$alternativa_cadastral_saude, ])),
  setequal(key(g), key(p[p$alternativa_direta_com_tempo, ])),
  all(key(g) %in% key(f)), sum(!g$presente_mides) == 317675L,
  sum(f$presente_mides) == 10735L, sum(g$presente_mides) == 5612L,
  n_distinct(f$cnpj_raiz_8) == 73L, n_distinct(g$cnpj_raiz_8) == 58L,
  n_distinct(g$id_municipio) == 853L,
  !"rcl_municipal" %in% names(f), !"rcl_municipal" %in% names(g))
# Nenhuma alteracao de valores ou identificadores herdados, nao apenas totais.
for (z in list(f, g)) {
  original <- p[match(key(z), key(p)), ]
  for (v in intersect(names(z), names(p))) stopifnot(identical(z[[v]], original[[v]]))
  stopifnot(all(nchar(z$cnpj_raiz_8) == 8), all(nchar(z$id_municipio) == 7),
    all(nzchar(z$entidade)), !anyNA(z$populacao_ibge))
}
# Registro financeiro efetivo de valor zero, sem converte-lo em ausencia.
# Identificar pela chave da origem, evitando depender de apelido/sigla.
raw_zero <- p |> filter(tem_registro_mides, !presente_mides, alternativa_cadastral_saude)
stopifnot(nrow(raw_zero) == 1L)
zero <- f[match(key(raw_zero), key(f)), ]
stopifnot(zero$tem_registro_mides, zero$valor_total == 0, zero$n_transacoes == 4)
# As horas derivam somente de clinicas do proprio ano; nenhum modulo movel entra.
units <- bind_rows(lapply(c("elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv",
  "candidatas_cnes_capacidade_unidades_2014_2021.csv"), function(x) read_table(file.path(out, x))))
hours <- units |> filter(funcao_assistencial == "destino_clinico_fixo") |>
  mutate(ano = as.integer(ano), carga_horaria_sus = as.numeric(carga_horaria_sus)) |>
  group_by(cnpj_raiz_8, ano) |> summarise(horas = sum(carga_horaria_sus), .groups = "drop")
checked <- g |> distinct(cnpj_raiz_8, ano, horas_sus_clinicas_soma_registros) |>
  left_join(hours, by = c("cnpj_raiz_8", "ano"), relationship = "one-to-one")
stopifnot(nrow(checked) == 379L, !anyNA(checked$horas),
  all(checked$horas == checked$horas_sus_clinicas_soma_registros),
  all(g$polo_direto_identificado == 1L), all(g$elegivel_gravitacional_v1),
  all(g$tempo_minimo_min <= g$tempo_mediano_min),
  all(g$tempo_mediano_min <= g$tempo_maximo_min), all(g$tempo_minimo_min >= 0))
igarape <- g |> filter(id_municipio == "3130101", cnpj_raiz_8 == "05802877", ano == 2019)
stopifnot(nrow(igarape) == 1L, abs(igarape$valor_total - 4740790.51) < .01,
  igarape$n_transacoes == 81L, igarape$populacao_ibge == 43045,
  igarape$n_destinos_clinicos_dezembro == 2,
  igarape$servicos_sus_clinicos_soma_unidades == 17,
  igarape$profissionais_sus_clinicos_soma_unidades == 105,
  igarape$leitos_sus_clinicos == 0, abs(igarape$tempo_minimo_min - 15.1) < 1e-8)
ledger <- read_table(file.path(dest, "inclusao_entidade_ano.csv"))
stopifnot(nrow(ledger) == 776L,
  !anyDuplicated(ledger[c("cnpj_raiz_8", "ano")]),
  abs(sum(as.numeric(ledger$valor_mides)) - sum(p$valor_total)) < .01,
  sum(as.numeric(ledger$pares_pagos)) == sum(p$presente_mides))
for (status in c("financeira_e_gravitacional", "somente_financeira_sem_polo_direto")) {
  z <- ledger[ledger$destino_v1 == status, ]
  expected <- if (status == "financeira_e_gravitacional") g else
    f[!f$elegivel_gravitacional_v1, ]
  stopifnot(abs(sum(as.numeric(z$valor_mides)) - sum(expected$valor_total)) < .01,
    sum(as.numeric(z$pares_pagos)) == sum(expected$presente_mides))
}
dictionary <- read_table(file.path(dest, "dicionario_variaveis.csv"))
stopifnot(setequal(dictionary$variavel, names(g)), !anyDuplicated(dictionary$variavel),
  all(nzchar(dictionary$definicao)), all(nzchar(dictionary$fonte)))
profile <- read_table(file.path(dest, "perfil_capacidade.csv"))
corr <- read_table(file.path(dest, "correlacoes_capacidade.csv"))
stopifnot(nrow(profile) == 45L, nrow(corr) == 90L,
  all(profile$entidades_ano[profile$periodo == "2019"] == "54"),
  all(profile$nulos == "0"),
  all(corr$spearman[corr$status == "variavel_constante"] == ""),
  !anyDuplicated(profile[c("periodo", "variavel")]))
cap2019 <- g |> filter(ano == 2019) |>
  distinct(cnpj_raiz_8, profissionais_sus_clinicos_soma_unidades,
    horas_sus_clinicas_soma_registros)
rho <- cor(cap2019$profissionais_sus_clinicos_soma_unidades,
  cap2019$horas_sus_clinicas_soma_registros, method = "spearman")
reported <- corr |> filter(periodo == "2019",
  variavel_a == "profissionais_sus_clinicos_soma_unidades",
  variavel_b == "horas_sus_clinicas_soma_registros")
stopifnot(nrow(reported) == 1L, abs(as.numeric(reported$spearman) - rho) < 1e-12)
# CSV pode perder zeros a esquerda em programas que inferem tipos; leitor explicito.
for (name in c("financeira", "gravitacional")) {
  csv <- read_table(file.path(dest, paste0("base_", name, "_v1.csv")))
  rds <- if (name == "financeira") f else g
  stopifnot(nrow(csv) == nrow(rds), identical(names(csv), names(rds)),
    identical(csv$cnpj_raiz_8, rds$cnpj_raiz_8),
    identical(csv$id_municipio, rds$id_municipio),
    all(abs(as.numeric(csv$valor_total) - rds$valor_total) < .0001))
}
manifest <- read_table(file.path(dest, "manifesto.csv"))
for (i in seq_len(nrow(manifest))) {
  path <- file.path(model, manifest$arquivo[i])
  stopifnot(file.exists(path), digest::digest(file = path, algo = "sha256") == manifest$sha256[i])
}
# As fontes financeiras e o painel continuam iguais ao manifesto anterior a v1.
prior <- read_table(file.path(out, "manifesto_entradas_conciliacao_saude.csv"))
for (i in which(grepl("mides_mg_atualizado.rds|painel_anual_integrado_saude_mg_2014_2021.rds$", prior$arquivo))) {
  stopifnot(digest::digest(file = prior$arquivo[i], algo = "sha256") == prior$sha256[i])
}
cat("OK: v1 conserva chaves, zeros, pagamentos, capacidade anual, exclusoes e fontes; CSV/RDS e manifestos conferem.\n")
