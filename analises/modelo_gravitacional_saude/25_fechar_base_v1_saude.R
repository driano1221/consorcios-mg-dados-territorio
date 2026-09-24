# Executar nesta pasta. Congela derivados de fontes existentes; nao coleta nem estima.
suppressPackageStartupMessages(library(dplyr))
if (.Platform$OS.type == "windows") Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8")
out <- "outputs"
dest <- file.path(out, "base_v1")
read_table <- function(path) read.csv(path, colClasses = "character",
  fileEncoding = "UTF-8-BOM", check.names = FALSE)
sha <- function(path) digest::digest(file = path, algo = "sha256")
inputs <- file.path(out, c("painel_anual_integrado_saude_mg_2014_2021.rds",
  "elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv",
  "candidatas_cnes_capacidade_unidades_2014_2021.csv",
  "conciliacao_lacunas_com_revisao_prioritaria_saude.csv",
  "diagnostico_necessidade_mensal_entidades_saude.csv",
  "universo_saude_mg_entidades.csv", "revisao_fora_84_resultado.csv",
  "matriz_suficiencia_recortes_saude.csv"))
input_manifest <- data.frame(papel = "entrada", arquivo = inputs,
  sha256 = vapply(inputs, sha, character(1)), bytes = file.info(inputs)$size,
  row.names = NULL)
manifest_path <- file.path(dest, "manifesto.csv")
if (file.exists(manifest_path)) {
  previous <- read_table(manifest_path)
  previous <- previous[previous$papel == "entrada", ]
  stopifnot(identical(previous$arquivo, input_manifest$arquivo),
            identical(previous$sha256, input_manifest$sha256))
}
# A mudanca de entradas exige nova versao: nao substituir silenciosamente a v1.
p <- readRDS(inputs[1])
stopifnot(nrow(p) == 661928L, ncol(p) == 60L,
          !anyDuplicated(p[c("id_municipio", "cnpj_raiz_8", "ano")]))
units <- bind_rows(lapply(inputs[2:3], read_table)) |>
  mutate(ano = as.integer(ano), across(c(leitos_sus,
    n_servicos_especializados_sus, n_profissionais_sus_distintos,
    carga_horaria_sus), as.numeric))
stopifnot(nrow(units) == 1942L,
  !anyDuplicated(units[c("cnpj_raiz_8", "ano", "cnes")]),
  all(units$competencia_referencia == paste0(units$ano, "12")),
  !anyNA(units[c("leitos_sus", "n_servicos_especializados_sus",
    "n_profissionais_sus_distintos", "carga_horaria_sus")]))
clinical <- units |> filter(funcao_assistencial == "destino_clinico_fixo")
capacity <- clinical |> group_by(cnpj_raiz_8, ano) |>
  summarise(n_unidades = n(), servicos = sum(n_servicos_especializados_sus),
    profissionais = sum(n_profissionais_sus_distintos), leitos = sum(leitos_sus),
    horas_sus_clinicas_soma_registros = sum(carga_horaria_sus), .groups = "drop")
check_capacity <- p |> filter(clinica_direta_dezembro) |>
  distinct(cnpj_raiz_8, ano, n_destinos_clinicos_dezembro,
    servicos_sus_clinicos_soma_unidades, profissionais_sus_clinicos_soma_unidades,
    leitos_sus_clinicos) |>
  left_join(capacity, by = c("cnpj_raiz_8", "ano"), relationship = "one-to-one")
stopifnot(nrow(check_capacity) == nrow(capacity),
  all(check_capacity$n_destinos_clinicos_dezembro == check_capacity$n_unidades),
  all(check_capacity$servicos_sus_clinicos_soma_unidades == check_capacity$servicos),
  all(check_capacity$profissionais_sus_clinicos_soma_unidades == check_capacity$profissionais),
  all(check_capacity$leitos_sus_clinicos == check_capacity$leitos))

original <- read_table(inputs[6])
external <- read_table(inputs[7])
labels <- bind_rows(original |> transmute(cnpj_raiz_8, nome = razao_social_canonica),
  external |> filter(cnpj_raiz_8 %in% p$cnpj_raiz_8) |>
    transmute(cnpj_raiz_8, nome = razao_social))
stopifnot(nrow(labels) == 97L, !anyDuplicated(labels$cnpj_raiz_8))
decisions <- read_table(inputs[4]) |> mutate(ano = as.integer(ano)) |>
  select(cnpj_raiz_8, ano, grupo_conciliacao, decisao_vigente)
temporal <- read_table(inputs[5]) |> mutate(ano = as.integer(ano)) |>
  select(cnpj_raiz_8, ano, classe_temporal)
metadata <- p |> distinct(cnpj_raiz_8, ano, sigla, origem_universo, grupo_escopo,
    ano_abertura, instituicao_aberta_no_ano, alternativa_cadastral_saude,
    clinica_direta_dezembro, alternativa_direta_com_tempo) |>
  left_join(labels, by = "cnpj_raiz_8", relationship = "many-to-one") |>
  left_join(decisions, by = c("cnpj_raiz_8", "ano"), relationship = "one-to-one") |>
  left_join(temporal, by = c("cnpj_raiz_8", "ano"), relationship = "one-to-one") |>
  mutate(entidade = if_else(!is.na(sigla) & nzchar(sigla), sigla, nome),
    destino_v1 = case_when(alternativa_direta_com_tempo ~ "financeira_e_gravitacional",
      alternativa_cadastral_saude ~ "somente_financeira_sem_polo_direto",
      !instituicao_aberta_no_ano ~ "fora_antes_abertura",
      TRUE ~ "fora_escopo_nucleo_saude"),
    classificacao_oferta = coalesce(decisao_vigente,
      if_else(clinica_direta_dezembro, "clinica_direta_cadastrada_dezembro",
        "sem_classificacao_documental_anual")),
    alerta_temporal = coalesce(classe_temporal == "priorizar_coleta_mensal", FALSE))
stopifnot(nrow(metadata) == 776L, !anyNA(metadata$entidade),
  all(nzchar(metadata$entidade)))
base <- p |>
  left_join(metadata |> select(cnpj_raiz_8, ano, entidade, classificacao_oferta,
    alerta_temporal), by = c("cnpj_raiz_8", "ano"), relationship = "many-to-one") |>
  left_join(capacity |> select(cnpj_raiz_8, ano, horas_sus_clinicas_soma_registros),
    by = c("cnpj_raiz_8", "ano"), relationship = "many-to-one") |>
  mutate(polo_direto_identificado = as.integer(clinica_direta_dezembro),
    elegivel_gravitacional_v1 = alternativa_direta_com_tempo) |>
  arrange(ano, cnpj_raiz_8, id_municipio)
common <- c("id_municipio", "municipio", "cnpj_raiz_8", "entidade", "ano",
  "origem_universo", "grupo_escopo", "ano_abertura", "populacao_ibge",
  "valor_total", "n_transacoes", "tem_registro_mides", "presente_mides",
  "valor_por_habitante", "evento_movimento", "polo_direto_identificado",
  "elegivel_gravitacional_v1", "classificacao_oferta", "alerta_temporal")
extra <- c("n_destinos_clinicos_dezembro", "n_municipios_clinicos_dezembro",
  "servicos_sus_clinicos_soma_unidades", "profissionais_sus_clinicos_soma_unidades",
  "horas_sus_clinicas_soma_registros", "leitos_sus_clinicos", "tempo_minimo_min",
  "tempo_mediano_min", "tempo_maximo_min", "distancia_minima_km",
  "destino_clinico_mais_proximo_id")
financial <- base |> filter(alternativa_cadastral_saude) |> select(all_of(common))
gravity <- base |> filter(alternativa_direta_com_tempo) |> select(all_of(c(common, extra)))
stopifnot(nrow(financial) == 491328L, nrow(gravity) == 323287L,
  sum(financial$presente_mides) == 10735L, sum(gravity$presente_mides) == 5612L,
  !anyNA(gravity[extra]), !anyNA(financial$populacao_ibge))

# Metadados/alcance de todas as 97 entidades, inclusive as fora do nucleo.
ledger <- metadata |> select(cnpj_raiz_8, entidade, ano, origem_universo,
  grupo_escopo, ano_abertura, destino_v1, classificacao_oferta,
  grupo_conciliacao, classe_temporal, alerta_temporal) |>
  left_join(p |> group_by(cnpj_raiz_8, ano) |>
    summarise(pares_pagos = sum(presente_mides), valor_mides = sum(valor_total),
      .groups = "drop"), by = c("cnpj_raiz_8", "ano"), relationship = "one-to-one") |>
  arrange(ano, destino_v1, cnpj_raiz_8)
cap <- gravity |> distinct(cnpj_raiz_8, entidade, ano, alerta_temporal,
  across(all_of(extra[1:6])))
stopifnot(nrow(cap) == 379L, !anyDuplicated(cap[c("cnpj_raiz_8", "ano")]))

# Estatisticas na entidade-ano, nao nas repeticoes por municipio.
variables <- extra[c(1, 3, 4, 5, 6)]
profile <- correlations <- list()
for (year in c("2014-2021", as.character(2014:2021))) {
  z <- cap[year == "2014-2021" | as.character(cap$ano) == year, ]
  for (variable in variables) {
    x <- z[[variable]]
    sorted <- sort(x[!is.na(x)], decreasing = TRUE)
    profile[[length(profile) + 1L]] <- data.frame(periodo = year, variavel = variable,
      entidades_ano = nrow(z), nulos = sum(is.na(x)), zeros = sum(x == 0, na.rm = TRUE),
      distintos = n_distinct(x, na.rm = TRUE), minimo = min(x),
      p25 = unname(quantile(x, .25)), mediana = median(x), media = mean(x),
      p75 = unname(quantile(x, .75)), p95 = unname(quantile(x, .95)), maximo = max(x),
      fracao_top5 = if (sum(sorted) > 0) sum(head(sorted, 5)) / sum(sorted) else NA_real_)
  }
  for (pair in combn(variables, 2, simplify = FALSE)) {
    valid <- complete.cases(z[pair]); a <- z[[pair[1]]][valid]; b <- z[[pair[2]]][valid]
    constant <- n_distinct(a) < 2 || n_distinct(b) < 2
    correlations[[length(correlations) + 1L]] <- data.frame(periodo = year,
      variavel_a = pair[1], variavel_b = pair[2], n_completos = sum(valid),
      spearman = if (constant) NA_real_ else cor(a, b, method = "spearman"),
      status = if (constant) "variavel_constante" else "descritiva_sem_teste_inferencial")
  }
}
# Perfis separados por funcao/tipo; nao somar movel/administrativo a clinicas.
modality <- units |> group_by(ano, funcao_assistencial, tipo_unidade_codigo) |>
  summarise(unidades_ano = n(), entidades = n_distinct(cnpj_raiz_8),
    mediana_profissionais_sus = median(n_profissionais_sus_distintos),
    mediana_servicos_sus = median(n_servicos_especializados_sus),
    mediana_horas_sus = median(carga_horaria_sus),
    unidades_sem_profissionais_sus = sum(n_profissionais_sus_distintos == 0),
    unidades_sem_servicos_sus = sum(n_servicos_especializados_sus == 0),
    .groups = "drop")
duplicate_cnes <- units |> count(ano, cnes, name = "n_entidades") |> filter(n_entidades > 1)
example <- gravity |> filter(id_municipio == "3130101", cnpj_raiz_8 == "05802877")
stopifnot(nrow(example) == 8L)

# Reutiliza a matriz auditada, sem criar uma segunda definicao dos recortes.
coverage <- read.csv(inputs[8]) |>
  filter(recorte %in% c("grade_97", "cadastral_saude", "clinica_direta_com_tempo",
    "saude_sem_clinica_direta"))
coverage_vars <- bind_rows(lapply(c("financeira", "gravitacional"), function(name) {
    z <- if (name == "financeira") financial else gravity
    data.frame(base = name, variavel = names(z), linhas = nrow(z),
      nulos = vapply(z, function(x) sum(is.na(x)), integer(1)),
      vazios = vapply(z, function(x) sum(!is.na(x) & as.character(x) == ""), integer(1)),
      row.names = NULL)
  }))
dictionary_text <- c(
  id_municipio = "Codigo IBGE de sete digitos; importar como texto.",
  municipio = "Nome do municipio de origem.",
  cnpj_raiz_8 = "Raiz CNPJ de oito digitos; matriz/filiais consolidadas; importar como texto.",
  entidade = "Sigla original ou razao social quando sigla ausente; nao cria identidade nova.",
  ano = "Ano de referencia: 2014 a 2021.",
  origem_universo = "original_84 ou candidata_externa_13; preserva a ampliacao documentada.",
  grupo_escopo = "Escopo cadastral ja definido; multiarea permanece fora do nucleo v1.",
  ano_abertura = "Ano cadastral de abertura; NA significa desconhecido, nao inatividade.",
  populacao_ibge = "Habitantes do municipio no ano; nao populacao exclusiva do consorcio.",
  valor_total = "Reais nominais MIDES no par-ano; zero significa sem pagamento positivo observado, nao servico ausente.",
  n_transacoes = "Quantidade de registros financeiros consolidados, inclusive registros de valor zero.",
  tem_registro_mides = "Ha registro no extrato; distingue registro de valor zero de ausencia de registro.",
  presente_mides = "Valor anual maior que zero; nao prova filiacao juridica.",
  valor_por_habitante = "Reais nominais por habitante; normalizacao descritiva, sem deflacao.",
  evento_movimento = "Trajetoria financeira calculada na grade completa antes do filtro; nao evento clinico.",
  polo_direto_identificado = "1: ao menos uma unidade clinica direta em dezembro; 0: nao identificada, nao ausencia de atendimento.",
  elegivel_gravitacional_v1 = "Regra existente: escopo/abertura do nucleo, clinica direta em dezembro e tempo; sem corte de minutos ou RCL.",
  classificacao_oferta = "Classificacao auditada das lacunas ou marcador cadastral; fonte auxiliar, sem imputar destinos.",
  alerta_temporal = "Ha presenca parcial/mudanca de tipo no diagnostico ST. FALSE nao comprova estabilidade de capacidade.",
  n_destinos_clinicos_dezembro = "Numero de unidades CNES clinicas fixas diretamente vinculadas em dezembro.",
  n_municipios_clinicos_dezembro = "Municipios distintos com essas unidades.",
  servicos_sus_clinicos_soma_unidades = "Soma de pares SERV_ESP:CLASS_SR SUS distintos em cada unidade; podem repetir entre unidades; nao procedimentos realizados.",
  profissionais_sus_clinicos_soma_unidades = "Soma de profissionais SUS distintos dentro de cada unidade; pessoas podem repetir entre unidades.",
  horas_sus_clinicas_soma_registros = "Soma HORAOUTR+HORAHOSP+HORA_AMB nos registros PF com PROF_SUS positivo e entre unidades; nao horas anuais realizadas ou exclusivas do consorcio.",
  leitos_sus_clinicos = "Soma de leitos SUS cadastrados nas clinicas; zero e valido para oferta ambulatorial.",
  tempo_minimo_min = "Minutos pela matriz estatica entre sede de origem e municipio clinico mais proximo; zero intramunicipal.",
  tempo_mediano_min = "Mediana entre municipios clinicos distintos, sem ponderar por capacidade/unidades.",
  tempo_maximo_min = "Maior tempo entre sede de origem e municipios clinicos.",
  distancia_minima_km = "Quilometros ate o destino de menor TEMPO; nome herdado, nao necessariamente menor distancia entre todos os destinos.",
  destino_clinico_mais_proximo_id = "IBGE do municipio de menor tempo; nao coordenada/endereco do estabelecimento.")
stopifnot(setequal(names(dictionary_text), names(gravity)))
dictionary <- data.frame(variavel = names(gravity),
  tabela = ifelse(names(gravity) %in% common, "ambas", "gravitacional"),
  tipo_r = vapply(gravity, function(x) class(x)[1], character(1)),
  definicao = unname(dictionary_text[names(gravity)]),
  fonte = ifelse(names(gravity) == "horas_sus_clinicas_soma_registros",
    "CNES PF; unidades historicas scripts 09/14; soma script 25",
    ifelse(names(gravity) %in% c("entidade", "classificacao_oferta", "alerta_temporal"),
      "Cadastros/conciliacao/diagnostico ST; entradas no manifesto",
      "Painel anual script 15; derivacao/rotulo script 25; METODOLOGIA_GERAL.md")))
dir.create(dest, recursive = TRUE, showWarnings = FALSE)
save_table <- function(x, name) write.csv(x, file.path(dest, paste0(name, ".csv")),
  row.names = FALSE, na = "", fileEncoding = "UTF-8")
save_table(financial, "base_financeira_v1")
save_table(gravity, "base_gravitacional_v1")
saveRDS(financial, file.path(dest, "base_financeira_v1.rds"), compress = "gzip")
saveRDS(gravity, file.path(dest, "base_gravitacional_v1.rds"), compress = "gzip")
save_table(ledger, "inclusao_entidade_ano")
save_table(cap, "capacidade_entidade_ano")
save_table(bind_rows(profile), "perfil_capacidade")
save_table(bind_rows(correlations), "correlacoes_capacidade")
save_table(modality, "perfil_modalidades_cnes")
save_table(duplicate_cnes, "cnes_multiplas_entidades")
save_table(coverage, "cobertura_recortes")
save_table(coverage_vars, "cobertura_variaveis")
save_table(dictionary, "dicionario_variaveis")
save_table(example, "exemplo_igarape_cismep")
files <- list.files(dest, pattern = "\\.(csv|rds)$", full.names = TRUE)
files <- files[basename(files) != "manifesto.csv"]
output_manifest <- data.frame(papel = "saida", arquivo = files,
  sha256 = vapply(files, sha, character(1)), bytes = file.info(files)$size, row.names = NULL)
stopifnot(identical(vapply(inputs, sha, character(1)),
  setNames(input_manifest$sha256, inputs)))
write.csv(bind_rows(input_manifest, output_manifest), manifest_path,
  row.names = FALSE, fileEncoding = "UTF-8")
cat("V1 financeira:", nrow(financial), "linhas;", ncol(financial), "colunas\n")
cat("V1 gravitacional:", nrow(gravity), "linhas;", ncol(gravity), "colunas\n")
print(bind_rows(profile) |> filter(periodo == "2019"), row.names = FALSE)
cat("CNES compartilhados por entidades no mesmo ano:", nrow(duplicate_cnes), "\n")
