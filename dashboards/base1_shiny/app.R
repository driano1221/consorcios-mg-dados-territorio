library(shiny)
library(bslib)
library(DT)
library(dplyr)
library(readr)
library(stringr)
library(scales)
library(ggplot2)
library(ggiraph)
library(sf)
library(classInt)

app_dir <- gsub("\\\\", "/", getwd())
project_dir <- file.path(app_dir, "..", "..")
out_dir <- file.path(project_dir, "analises/base_1_2015_2019/outputs")

local_data_dir <- file.path(app_dir, "data")
path_vinculos_local <- file.path(local_data_dir, "base_1_vinculos_2015_2019.csv")
path_validacao_local <- file.path(local_data_dir, "base_1_validacao_siconfi_reconstruido_2015_2019.csv")
path_vinculos_rds_local <- file.path(local_data_dir, "base_1_vinculos_2015_2019.rds")
path_validacao_rds_local <- file.path(local_data_dir, "base_1_validacao_siconfi_reconstruido_2015_2019.rds")
path_mides_anual_local <- file.path(local_data_dir, "painel_mg_anual.rds")
path_mides_municipios_local <- file.path(local_data_dir, "mides_municipios_lookup.csv")
path_mides_municipios_rds_local <- file.path(local_data_dir, "mides_municipios_lookup.rds")
path_cadastro_local <- file.path(local_data_dir, "cadastro_base.rds")
path_classificacao_local <- file.path(local_data_dir, "classificacao_areas_politica_mg_v0_5.rds")
path_mg_sf_local <- file.path(local_data_dir, "mg_municipios_sf_web.rds")
path_mg_contorno_local <- file.path(local_data_dir, "mg_contorno_sf_web.rds")
path_vinculos_repo <- file.path(out_dir, "base_1_vinculos_2015_2019.csv")
path_validacao_repo <- file.path(out_dir, "base_1_validacao_siconfi_reconstruido_2015_2019.csv")
path_mides_anual_repo <- file.path(project_dir, "dados/processado/painel_mg_anual.rds")
path_mides_municipios_repo <- file.path(project_dir, "dashboards/base1_shiny/data/mides_municipios_lookup.csv")
path_cadastro_repo <- file.path(project_dir, "dados/processado/cadastro_base.rds")
path_classificacao_repo <- file.path(project_dir, "analises/classificacao_politicas/outputs/classificacao_areas_politica_mg_v0_5_completa.csv")
path_mg_sf_repo <- file.path(project_dir, "dashboards/base1_shiny/data/mg_municipios_sf_web.rds")
path_mg_contorno_repo <- file.path(project_dir, "dashboards/base1_shiny/data/mg_contorno_sf_web.rds")

path_vinculos <- if (file.exists(path_vinculos_rds_local)) path_vinculos_rds_local else if (file.exists(path_vinculos_local)) path_vinculos_local else path_vinculos_repo
path_validacao <- if (file.exists(path_validacao_rds_local)) path_validacao_rds_local else if (file.exists(path_validacao_local)) path_validacao_local else path_validacao_repo
path_mides_anual <- if (file.exists(path_mides_anual_local)) path_mides_anual_local else path_mides_anual_repo
path_mides_municipios <- if (file.exists(path_mides_municipios_rds_local)) path_mides_municipios_rds_local else if (file.exists(path_mides_municipios_local)) path_mides_municipios_local else path_mides_municipios_repo
path_cadastro <- if (file.exists(path_cadastro_local)) path_cadastro_local else path_cadastro_repo
path_classificacao <- if (file.exists(path_classificacao_local)) path_classificacao_local else path_classificacao_repo
path_mg_sf <- if (file.exists(path_mg_sf_local)) path_mg_sf_local else path_mg_sf_repo
path_mg_contorno <- if (file.exists(path_mg_contorno_local)) path_mg_contorno_local else path_mg_contorno_repo

if (!file.exists(path_vinculos)) stop("Arquivo nao encontrado: ", path_vinculos)
if (!file.exists(path_validacao)) stop("Arquivo nao encontrado: ", path_validacao)
if (!file.exists(path_mides_anual)) stop("Arquivo nao encontrado: ", path_mides_anual)
if (!file.exists(path_mides_municipios)) stop("Arquivo nao encontrado: ", path_mides_municipios)
if (!file.exists(path_cadastro)) stop("Arquivo nao encontrado: ", path_cadastro)
if (!file.exists(path_classificacao)) stop("Arquivo nao encontrado: ", path_classificacao)
if (!file.exists(path_mg_sf)) stop("Arquivo nao encontrado: ", path_mg_sf)
if (!file.exists(path_mg_contorno)) stop("Arquivo nao encontrado: ", path_mg_contorno)

read_table_app <- function(path) {
  if (tolower(tools::file_ext(path)) == "rds") {
    readRDS(path)
  } else {
    read_csv(path, show_col_types = FALSE)
  }
}

fmt_moeda <- function(x) label_number(big.mark = ".", decimal.mark = ",", prefix = "R$ ", accuracy = 1)(x)
fmt_moeda_curto <- function(x) label_number(big.mark = ".", decimal.mark = ",", prefix = "R$ ", accuracy = 0.1, scale_cut = cut_short_scale())(x)
fmt_int <- function(x) label_number(big.mark = ".", decimal.mark = ",", accuracy = 1)(x)
pad_ibge <- function(x) str_pad(str_sub(as.character(x), 1, 6), 6, side = "left", pad = "0")
fmt_flag <- function(x) if_else(isTRUE(x), "Sim", "Nao")
rotulos_area <- c(
  agricultura = "Agricultura", assistencia_social = "Assistencia social",
  cultura = "Cultura", defesa_consumidor = "Defesa do consumidor",
  desenvolvimento_regional = "Desenvolvimento regional", desenvolvimento_urbano = "Desenvolvimento urbano",
  educacao = "Educacao", esporte = "Esporte", gestao_publica = "Gestao publica",
  habitacao = "Habitacao", iluminacao_publica = "Iluminacao publica",
  infraestrutura = "Infraestrutura", inspecao_produtos_origem_animal = "Inspecao de produtos de origem animal",
  licitacao_compras_compartilhadas = "Licitacao e compras compartilhadas",
  meio_ambiente = "Meio ambiente", recursos_hidricos = "Recursos hidricos",
  residuos_solidos = "Residuos solidos", saneamento_basico = "Saneamento basico",
  saude = "Saude", seguranca_publica = "Seguranca publica", transporte = "Transporte",
  turismo = "Turismo", urgencia_emergencia = "Urgencia e emergencia",
  vigilancia_em_saude = "Vigilancia em saude"
)
rotulos_macrogrupo <- c(
  ambiente_saneamento = "Ambiente e saneamento", cultura_turismo = "Cultura e turismo",
  desenvolvimento_rural = "Desenvolvimento rural", desenvolvimento_territorial = "Desenvolvimento territorial",
  gestao_publica = "Gestao publica", politicas_sociais = "Politicas sociais",
  saude = "Saude", seguranca_cidadania = "Seguranca e cidadania"
)
rotulos_perfil <- c(
  setorial = "Setorial", multiarea = "Multiarea documentada",
  multifinalitario_ou_multissetorial = "Multifinalitario ou multissetorial"
)
extrair_categorias <- function(x) {
  x <- x[!is.na(x) & x != ""]
  sort(unique(str_squish(unlist(str_split(x, ";")))))
}
rotular_opcoes <- function(codigos, rotulos) {
  # Em inputs Shiny, o nome e o rotulo exibido e o valor e o codigo filtrado.
  setNames(codigos, unname(rotulos[codigos]))
}
formatar_categorias <- function(x, rotulos) {
  vapply(x, function(valor) {
    if (is.na(valor) || valor == "") return("Nao informado")
    codigos <- str_squish(unlist(str_split(valor, ";")))
    paste(unname(rotulos[codigos]), collapse = " | ")
  }, character(1))
}
tem_categoria <- function(x, escolhas) {
  if (length(escolhas) == 0) return(rep(TRUE, length(x)))
  vapply(x, function(valor) {
    !is.na(valor) && any(str_squish(unlist(str_split(valor, ";"))) %in% escolhas)
  }, logical(1))
}
max0 <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(0)
  max(x)
}
tokens_nome <- function(x) {
  x |>
    str_to_upper() |>
    str_replace_all("[^A-Z0-9 ]", " ") |>
    str_split("\\s+") |>
    lapply(function(tok) {
      tok <- tok[nchar(tok) >= 3]
      setdiff(
        tok,
        c(
          "CONSORCIO", "INTERMUNICIPAL", "MUNICIPIOS", "MUNICIPIO",
          "SAUDE", "REGIAO", "REGIONAL", "AMPLIADA", "SERVICOS",
          "SERVICO", "GERENCIAMENTO", "EMERGENCIA", "URGENCIA",
          "MULTIFINALITARIO", "MINEIRO", "MINAS", "GERAIS",
          "PARA", "COM", "DAS", "DOS", "DO", "DA", "DE"
        )
      )
    })
}
overlap_tokens <- function(a, b) {
  a <- unique(unlist(tokens_nome(a)))
  b <- unique(unlist(tokens_nome(b)))
  paste(intersect(a, b), collapse = " ")
}
fmt_mapa_valor <- function(x, metrica) {
  if (metrica %in% c("valor_total", "valor_corrente")) {
    fmt_moeda_curto(x)
  } else {
    fmt_int(x)
  }
}
classificar_mapa <- function(x, metrica, n = 5) {
  active <- x[is.finite(x) & !is.na(x) & x > 0]
  sem_label <- "Sem registro"
  if (length(active) == 0) {
    return(factor(rep(sem_label, length(x)), levels = sem_label))
  }

  if (length(unique(active)) <= n) {
    breaks <- sort(unique(c(0, active)))
    if (length(breaks) == 1) breaks <- c(0, breaks)
  } else {
    breaks <- classInt::classIntervals(active, n = n, style = "quantile")$brks
    breaks[1] <- 0
    breaks <- unique(breaks)
  }

  if (length(breaks) < 3) {
    breaks <- unique(pretty(c(0, active), n = n))
    breaks <- breaks[breaks >= 0]
  }
  breaks <- unique(sort(breaks))
  if (tail(breaks, 1) < max(active, na.rm = TRUE)) breaks <- c(breaks, max(active, na.rm = TRUE))
  if (length(breaks) < 2) breaks <- c(0, max(active, na.rm = TRUE))

  labels <- paste0(
    fmt_mapa_valor(head(breaks, -1), metrica),
    " - ",
    fmt_mapa_valor(tail(breaks, -1), metrica)
  )
  bins <- cut(x, breaks = breaks, include.lowest = TRUE, labels = labels)
  bins <- as.character(bins)
  bins[is.na(bins) | x <= 0] <- sem_label
  factor(bins, levels = c(sem_label, labels))
}
theme_mapa_limpo <- function() {
  theme_void(base_size = 12) +
    theme(
      plot.background = element_rect(fill = "#ffffff", colour = NA),
      panel.background = element_rect(fill = "#ffffff", colour = NA),
      plot.title = element_text(
        family = "sans", face = "bold", size = 18,
        colour = "#303030", margin = margin(b = 2)
      ),
      plot.subtitle = element_text(
        size = 9.5, colour = "#4f5d63",
        margin = margin(b = 10), lineheight = 1.15
      ),
      plot.caption = element_text(
        size = 7.5, colour = "#4f5d63", hjust = 0,
        margin = margin(t = 8)
      ),
      legend.position = "right",
      legend.title = element_text(size = 9, colour = "#303030", face = "bold"),
      legend.text = element_text(size = 8, colour = "#303030"),
      legend.key.height = unit(14, "pt"),
      legend.key.width = unit(14, "pt"),
      legend.background = element_rect(fill = "#ffffff", colour = NA),
      legend.margin = margin(0, 0, 0, 4),
      plot.margin = margin(12, 12, 10, 12)
    )
}

vinculos <- read_table_app(path_vinculos) |>
  mutate(
    ano = as.integer(ano),
    cod_ibge_6 = pad_ibge(cod_ibge_6),
    cnpj_consorcio = str_pad(as.character(cnpj_consorcio), 14, side = "left", pad = "0"),
    grupo_vinculo = factor(grupo_vinculo, levels = c("MIDES+MUNIC", "MIDES_only", "MUNIC_only")),
    tem_mides_txt = if_else(tem_mides, "Sim", "Nao"),
    tem_munic_txt = if_else(tem_munic, "Sim", "Nao"),
    municipio = str_to_title(municipio),
    sigla = if_else(is.na(sigla) | sigla == "", "(sem sigla)", sigla),
    razao_social = if_else(is.na(razao_social) | razao_social == "", "(sem razao social)", razao_social),
    setores_consolidado = if_else(is.na(setores_consolidado) | setores_consolidado == "", "(sem setor)", setores_consolidado)
  )

validacao <- read_table_app(path_validacao) |>
  mutate(
    ano = as.integer(ano),
    cod_ibge_6 = pad_ibge(cod_ibge_6),
    classe_validacao = factor(
      classe_validacao,
      levels = c(
        "congruente",
        "divergente_valor",
        "mides_sem_siconfi",
        "siconfi_sem_mides",
        "munic_sem_fluxo_financeiro"
      )
    ),
    diferenca_rel_pct = round(diferenca_rel * 100, 1)
  ) |>
  select(
    ano, cod_ibge_6, classe_validacao, valor_siconfi_consorcio,
    valor_siconfi_herdado, valor_mides_corrente_cadastro_1194,
    valor_mides_total_cadastro_1194, diferenca_abs, diferenca_abs_modulo,
    diferenca_rel_pct, passa_tolerancia, regra_siconfi
  )

base_final <- vinculos |>
  left_join(validacao, by = c("ano", "cod_ibge_6")) |>
  mutate(
    classe_validacao = if_else(is.na(as.character(classe_validacao)), "sem_validacao_siconfi", as.character(classe_validacao)),
    classe_validacao = factor(
      classe_validacao,
      levels = c(
        "congruente",
        "divergente_valor",
        "mides_sem_siconfi",
        "siconfi_sem_mides",
        "munic_sem_fluxo_financeiro",
        "sem_validacao_siconfi"
      )
    ),
    valor_siconfi_consorcio = coalesce(valor_siconfi_consorcio, 0),
    valor_siconfi_herdado = coalesce(valor_siconfi_herdado, 0),
    diferenca_abs = coalesce(diferenca_abs, 0),
    diferenca_abs_modulo = coalesce(diferenca_abs_modulo, 0),
    diferenca_rel_pct = coalesce(diferenca_rel_pct, 0),
    regra_siconfi = coalesce(regra_siconfi, "consorcio_pagas"),
    grupo_rotulo = case_when(
      grupo_vinculo == "MIDES+MUNIC" ~ "Aparece nas duas fontes",
      grupo_vinculo == "MIDES_only" ~ "So MIDES: pagamento sem MUNIC",
      grupo_vinculo == "MUNIC_only" ~ "So MUNIC: declaracao sem MIDES",
      TRUE ~ as.character(grupo_vinculo)
    ),
    classe_rotulo = case_when(
      classe_validacao == "congruente" ~ "Congruente",
      classe_validacao == "divergente_valor" ~ "Divergente de valor",
      classe_validacao == "mides_sem_siconfi" ~ "MIDES sem SICONFI",
      classe_validacao == "siconfi_sem_mides" ~ "SICONFI sem MIDES",
      classe_validacao == "munic_sem_fluxo_financeiro" ~ "MUNIC sem fluxo financeiro",
      classe_validacao == "sem_validacao_siconfi" ~ "Sem validacao SICONFI",
      TRUE ~ as.character(classe_validacao)
    ),
    pesquisa = str_to_lower(paste(municipio, sigla, razao_social, cnpj_consorcio, setores_consolidado))
  )

mides_municipios <- read_table_app(path_mides_municipios) |>
  mutate(
    cod_ibge_6 = pad_ibge(cod_ibge_6),
    municipio = str_to_title(municipio)
  ) |>
  distinct(cod_ibge_6, municipio)

cadastro_base <- readRDS(path_cadastro) |>
  mutate(
    cnpj_consorcio = str_pad(as.character(cnpj), 14, side = "left", pad = "0"),
    sigla_cadastro = if_else(is.na(sigla) | sigla == "", "(sem sigla)", sigla),
    razao_social_cadastro = if_else(is.na(razao_social) | razao_social == "", "(sem razao social)", razao_social),
    setores_cadastro = if_else(is.na(setores) | setores == "", "(sem setor)", setores),
    situacao_cadastro = if_else(is.na(situacao) | situacao == "", "(sem situacao)", situacao)
  ) |>
  select(
    cnpj_consorcio, sigla_cadastro, razao_social_cadastro,
    setores_cadastro, situacao_cadastro, ano_fundacao
  )

# A classificacao v0.5 qualifica o consorcio sem alterar a observacao MIDES.
classificacao_v05 <- read_table_app(path_classificacao) |>
  mutate(
    cnpj_consorcio = str_pad(as.character(cnpj_consorcio), 14, side = "left", pad = "0"),
    ativo_analise = coalesce(ativo_analise, FALSE),
    area_filtro = if_else(ativo_analise & !is.na(area_politica_final) & area_politica_final != "", area_politica_final, NA_character_),
    macrogrupo_filtro = if_else(ativo_analise & !is.na(macroarea_final) & macroarea_final != "", macroarea_final, NA_character_),
    perfil_filtro = if_else(ativo_analise & !is.na(perfil_institucional) & perfil_institucional != "", perfil_institucional, NA_character_),
    status_classificacao = coalesce(status_validacao, "Sem classificacao"),
    fonte_classificacao = coalesce(fonte_principal, "Sem classificacao")
  ) |>
  select(
    cnpj_consorcio,
    area_politica = area_filtro,
    macrogrupo_politica = macrogrupo_filtro,
    perfil_classificacao = perfil_filtro,
    status_classificacao,
    fonte_classificacao,
    ativo_classificacao = ativo_analise
  ) |>
  distinct(cnpj_consorcio, .keep_all = TRUE)

mides_anual <- readRDS(path_mides_anual) |>
  mutate(
    ano = as.integer(ano),
    cod_ibge_6 = pad_ibge(id_municipio),
    cnpj_consorcio = str_pad(as.character(documento_credor), 14, side = "left", pad = "0"),
    nome_credor_freq = if_else(is.na(nome_credor_freq) | nome_credor_freq == "", "(sem nome)", nome_credor_freq)
  ) |>
  left_join(mides_municipios, by = "cod_ibge_6") |>
  left_join(cadastro_base, by = "cnpj_consorcio") |>
  left_join(classificacao_v05, by = "cnpj_consorcio") |>
  mutate(
    municipio = if_else(is.na(municipio) | municipio == "", paste0("IBGE ", cod_ibge_6), municipio),
    sigla = coalesce(sigla_cadastro, "(sem sigla)"),
    razao_social = coalesce(razao_social_cadastro, nome_credor_freq),
    setores = coalesce(setores_cadastro, "(sem setor)"),
    situacao = coalesce(situacao_cadastro, "(sem situacao)"),
    cobertura_classificacao = case_when(
      is.na(ativo_classificacao) ~ "Consorcio sediado fora de MG",
      status_classificacao == "excluida_associacao_municipal" ~ "Entidade associativa fora do escopo",
      !ativo_classificacao ~ "CNPJ inativo ou baixado",
      is.na(area_politica) ~ "Perfil institucional sem area especifica",
      TRUE ~ "Area classificada"
    ),
    status_classificacao = coalesce(status_classificacao, "Fora do universo da classificacao"),
    fonte_classificacao = coalesce(fonte_classificacao, "Fora do universo da classificacao"),
    tipo_valor = case_when(
      valor_corrente > 0 & valor_restos > 0 ~ "corrente + restos",
      valor_corrente > 0 ~ "corrente",
      valor_restos > 0 ~ "restos a pagar",
      valor_total > 0 ~ "valor total positivo",
      TRUE ~ "sem valor positivo"
    ),
    pesquisa_mides = str_to_lower(paste(municipio, sigla, razao_social, cnpj_consorcio, nome_credor_freq, setores))
  )

mg_municipios_sf <- readRDS(path_mg_sf) |>
  mutate(cod_ibge_6 = pad_ibge(cod_ibge_6))
mg_contorno_sf <- readRDS(path_mg_contorno)
paleta_transicao <- c(
  "Sem par no filtro" = "#f5f5f5",
  "Permaneceu" = "#117733",
  "Entrou em 2019" = "#2c7fb8",
  "Saiu apos 2015" = "#d95f02",
  "Misto/empate" = "#9e9e9e"
)
paleta_fontes <- c(
  "Sem par no filtro" = "#f5f5f5",
  "Predominio MIDES+MUNIC" = "#117733",
  "Predominio so MIDES" = "#332288",
  "Predominio so MUNIC" = "#ddcc77",
  "Misto/empate" = "#9e9e9e"
)
paleta_mov_mides <- c(
  "Sem dado" = "#f7f7f7",
  "Inicio" = "#9ecae1",
  "Permaneceu" = "#147d3f",
  "Entrou" = "#2b8cbe",
  "Saiu" = "#e07a2f",
  "Misto" = "#8f8f8f"
)
dt_pt <- list(
  search = "Buscar:",
  lengthMenu = "Mostrar _MENU_ registros",
  info = "Mostrando _START_ a _END_ de _TOTAL_ registros",
  infoEmpty = "Sem registros",
  infoFiltered = "(filtrado de _MAX_ registros)",
  zeroRecords = "Nenhum registro encontrado",
  processing = "Processando...",
  paginate = list(previous = "Anterior", `next` = "Proximo")
)

anos_opts <- sort(unique(base_final$ano))
grupos_opts <- levels(droplevels(base_final$grupo_vinculo))
classes_opts <- levels(droplevels(base_final$classe_validacao))
mides_anos_opts <- sort(unique(mides_anual$ano))
mides_municipios_opts <- sort(unique(mides_anual$municipio))
mides_consorcios_opts <- sort(unique(mides_anual$sigla))
mides_areas_opts <- rotular_opcoes(extrair_categorias(mides_anual$area_politica), rotulos_area)
mides_macrogrupos_opts <- rotular_opcoes(extrair_categorias(mides_anual$macrogrupo_politica), rotulos_macrogrupo)
mides_perfis_opts <- rotular_opcoes(sort(unique(na.omit(mides_anual$perfil_classificacao))), rotulos_perfil)
mides_regra_valor_opts <- c(
  "Todos os registros" = "todos",
  "Valor corrente positivo" = "corrente",
  "Restos a pagar positivo" = "restos",
  "Valor total positivo" = "total"
)
mides_mapa_metrica_opts <- c(
  "Valor total MIDES" = "valor_total",
  "Valor corrente" = "valor_corrente",
  "Numero de consorcios" = "n_consorcios",
  "Numero de transacoes" = "n_transacoes"
)
grupos_labels <- c(
  "Aparece nas duas fontes" = "MIDES+MUNIC",
  "So MIDES: pagamento sem MUNIC" = "MIDES_only",
  "So MUNIC: declaracao sem MIDES" = "MUNIC_only"
)
classes_labels <- c(
  "Congruente" = "congruente",
  "Divergente de valor" = "divergente_valor",
  "MIDES sem SICONFI" = "mides_sem_siconfi",
  "SICONFI sem MIDES" = "siconfi_sem_mides",
  "MUNIC sem fluxo financeiro" = "munic_sem_fluxo_financeiro",
  "Sem validacao SICONFI" = "sem_validacao_siconfi"
)
municipios_opts <- sort(unique(base_final$municipio))
consorcios_opts <- sort(unique(base_final$sigla))

transicao_pares <- base_final |>
  group_by(cod_ibge_6, municipio, cnpj_consorcio, sigla, razao_social) |>
  summarise(
    apareceu_2015 = any(ano == 2015),
    apareceu_2019 = any(ano == 2019),
    grupo_2015 = paste(sort(unique(grupo_rotulo[ano == 2015])), collapse = " | "),
    grupo_2019 = paste(sort(unique(grupo_rotulo[ano == 2019])), collapse = " | "),
    mides_2015 = sum(valor_mides_corrente[ano == 2015], na.rm = TRUE),
    mides_2019 = sum(valor_mides_corrente[ano == 2019], na.rm = TRUE),
    siconfi_2015 = max0(valor_siconfi_consorcio[ano == 2015]),
    siconfi_2019 = max0(valor_siconfi_consorcio[ano == 2019]),
    classe_2015 = paste(sort(unique(classe_rotulo[ano == 2015])), collapse = " | "),
    classe_2019 = paste(sort(unique(classe_rotulo[ano == 2019])), collapse = " | "),
    .groups = "drop"
  ) |>
  mutate(
    grupo_2015 = if_else(grupo_2015 == "", "Nao aparece", grupo_2015),
    grupo_2019 = if_else(grupo_2019 == "", "Nao aparece", grupo_2019),
    classe_2015 = if_else(classe_2015 == "", "Nao aparece", classe_2015),
    classe_2019 = if_else(classe_2019 == "", "Nao aparece", classe_2019),
    status_temporal = case_when(
      apareceu_2015 & apareceu_2019 ~ "Permaneceu em 2015 e 2019",
      apareceu_2015 & !apareceu_2019 ~ "Saiu: aparece em 2015, nao em 2019",
      !apareceu_2015 & apareceu_2019 ~ "Entrou: aparece em 2019, nao em 2015",
      TRUE ~ "Sem classificacao"
    ),
    pesquisa_transicao = str_to_lower(paste(municipio, sigla, razao_social, cnpj_consorcio, status_temporal))
  ) |>
  arrange(sigla, municipio)

auditoria_nome <- base_final |>
  distinct(cnpj_consorcio, sigla, razao_social, situacao, ano_fundacao) |>
  mutate(
    nome_norm = str_squish(str_to_upper(razao_social)),
    sigla_txt = if_else(is.na(sigla) | sigla == "", "(sem sigla)", sigla),
    situacao_txt = if_else(is.na(situacao) | situacao == "", "(sem situacao)", situacao)
  ) |>
  summarise(
    cnpjs = paste(sort(unique(cnpj_consorcio)), collapse = "; "),
    n_cnpjs = n_distinct(cnpj_consorcio),
    siglas = paste(sort(unique(sigla_txt)), collapse = "; "),
    situacoes = paste(sort(unique(situacao_txt)), collapse = "; "),
    anos_fundacao = paste(sort(unique(na.omit(ano_fundacao))), collapse = "; "),
    .by = nome_norm
  ) |>
  filter(n_cnpjs > 1) |>
  arrange(desc(n_cnpjs), nome_norm)

base1_por_raiz_cnpj <- base_final |>
  mutate(cnpj_raiz_8 = str_sub(cnpj_consorcio, 1, 8)) |>
  summarise(
    presente_base1 = TRUE,
    linhas_base1 = n(),
    pares_base1 = n_distinct(paste(cod_ibge_6, cnpj_consorcio, ano)),
    municipios_base1 = n_distinct(cod_ibge_6),
    valor_mides_base1 = sum(valor_mides_corrente, na.rm = TRUE),
    anos_base1 = paste(sort(unique(ano)), collapse = "; "),
    .by = cnpj_raiz_8
  )

auditoria_cnpj_raiz <- cadastro_base |>
  distinct(cnpj_consorcio, sigla_cadastro, razao_social_cadastro, situacao_cadastro, ano_fundacao) |>
  mutate(
    cnpj_raiz_8 = str_sub(cnpj_consorcio, 1, 8),
    cnpj_prefixo_10 = str_sub(cnpj_consorcio, 1, 10),
    ordem_cnpj = str_sub(cnpj_consorcio, 9, 12),
    tipo_estabelecimento = if_else(ordem_cnpj == "0001", "matriz", "filial"),
    nome_norm = str_squish(str_to_upper(razao_social_cadastro)),
    sigla_txt = if_else(is.na(sigla_cadastro) | sigla_cadastro == "", "(sem sigla)", sigla_cadastro),
    situacao_txt = if_else(is.na(situacao_cadastro) | situacao_cadastro == "", "(sem situacao)", situacao_cadastro)
  ) |>
  summarise(
    n_cnpjs = n_distinct(cnpj_consorcio),
    n_matrizes = n_distinct(cnpj_consorcio[tipo_estabelecimento == "matriz"]),
    n_filiais = n_distinct(cnpj_consorcio[tipo_estabelecimento == "filial"]),
    cnpj_matriz = paste(sort(unique(cnpj_consorcio[tipo_estabelecimento == "matriz"])), collapse = "; "),
    cnpjs_filiais = paste(sort(unique(cnpj_consorcio[tipo_estabelecimento == "filial"])), collapse = "; "),
    cnpjs = paste(sort(unique(cnpj_consorcio)), collapse = "; "),
    prefixos_10 = paste(sort(unique(cnpj_prefixo_10)), collapse = "; "),
    nomes_juridicos = paste(sort(unique(nome_norm)), collapse = " | "),
    siglas = paste(sort(unique(sigla_txt)), collapse = "; "),
    situacoes = paste(sort(unique(situacao_txt)), collapse = "; "),
    anos_fundacao = paste(sort(unique(na.omit(ano_fundacao))), collapse = "; "),
    regra_sugerida = case_when(
      n_matrizes >= 1 & n_filiais >= 1 ~ "agrupar matriz e filiais pela raiz de 8 digitos",
      n_matrizes == 0 & n_filiais > 1 ~ "sem matriz na base; revisar filiais da mesma raiz",
      n_matrizes > 1 ~ "revisar: mais de uma matriz na mesma raiz",
      TRUE ~ "revisar"
    ),
    .by = cnpj_raiz_8
  ) |>
  left_join(base1_por_raiz_cnpj, by = "cnpj_raiz_8") |>
  mutate(
    presente_base1 = coalesce(presente_base1, FALSE),
    linhas_base1 = coalesce(linhas_base1, 0L),
    pares_base1 = coalesce(pares_base1, 0L),
    municipios_base1 = coalesce(municipios_base1, 0L),
    valor_mides_base1 = coalesce(valor_mides_base1, 0),
    anos_base1 = if_else(is.na(anos_base1) | anos_base1 == "", "(fora da Base 1)", anos_base1)
  ) |>
  filter(n_cnpjs > 1) |>
  arrange(desc(presente_base1), desc(n_cnpjs), cnpj_raiz_8)

auditoria_mun_ano <- base_final |>
  mutate(nome_norm = str_squish(str_to_upper(razao_social))) |>
  summarise(
    cnpjs = paste(sort(unique(cnpj_consorcio)), collapse = "; "),
    n_cnpjs = n_distinct(cnpj_consorcio),
    siglas = paste(sort(unique(sigla)), collapse = "; "),
    grupos = paste(sort(unique(as.character(grupo_vinculo))), collapse = "; "),
    valor_mides = sum(valor_mides_corrente, na.rm = TRUE),
    .by = c(ano, cod_ibge_6, municipio, nome_norm)
  ) |>
  filter(n_cnpjs > 1) |>
  arrange(desc(n_cnpjs), municipio, nome_norm)

auditoria_municipio <- base_final |>
  summarise(
    n_cnpjs = n_distinct(cnpj_consorcio),
    n_siglas = n_distinct(sigla),
    cnpjs = paste(sort(unique(cnpj_consorcio)), collapse = "; "),
    siglas = paste(sort(unique(sigla)), collapse = "; "),
    razoes = paste(sort(unique(razao_social)), collapse = " | "),
    setores = paste(sort(unique(setores_consolidado)), collapse = "; "),
    anos = paste(sort(unique(ano)), collapse = "; "),
    .by = c(cod_ibge_6, municipio)
  ) |>
  filter(n_cnpjs > 1) |>
  arrange(desc(n_cnpjs), municipio)

auditoria_pares_parecidos <- base_final |>
  distinct(
    ano, cod_ibge_6, municipio, cnpj_consorcio, sigla, razao_social,
    grupo_rotulo, classe_rotulo, valor_mides_corrente, valor_mides_total,
    valor_siconfi_consorcio, setores_consolidado
  ) |>
  inner_join(
    base_final |>
      distinct(
        ano, cod_ibge_6, municipio, cnpj_consorcio, sigla, razao_social,
        grupo_rotulo, classe_rotulo, valor_mides_corrente, valor_mides_total,
        valor_siconfi_consorcio, setores_consolidado
      ),
    by = c("ano", "cod_ibge_6", "municipio"),
    suffix = c("_a", "_b"),
    relationship = "many-to-many"
  ) |>
  filter(cnpj_consorcio_a < cnpj_consorcio_b) |>
  rowwise() |>
  mutate(
    termos_comuns = overlap_tokens(razao_social_a, razao_social_b),
    n_termos_comuns = if_else(termos_comuns == "", 0L, length(str_split(termos_comuns, "\\s+")[[1]])),
    envolve_sem_sigla = sigla_a == "(sem sigla)" | sigla_b == "(sem sigla)",
    tipo_alerta = case_when(
      envolve_sem_sigla & n_termos_comuns >= 2 ~ "sem sigla + nome territorial parecido",
      n_termos_comuns >= 3 ~ "nomes territoriais parecidos",
      TRUE ~ NA_character_
    )
  ) |>
  ungroup() |>
  filter(!is.na(tipo_alerta)) |>
  arrange(desc(envolve_sem_sigla), desc(n_termos_comuns), municipio, ano)

status_opts <- sort(unique(transicao_pares$status_temporal))

tema <- bs_theme(
  version = 5,
  bg = "#f7f9fb",
  fg = "#202426",
  primary = "#173a50",
  secondary = "#55798e",
  success = "#62b426",
  base_font = font_collection("Segoe UI", "Arial", "sans-serif"),
  heading_font = font_collection("Georgia", "serif"),
  code_font = font_collection("Consolas", "Lucida Console", "monospace")
)

definicoes <- tibble::tribble(
  ~item, ~definicao,
  "Par municipio-consorcio", "Uma observacao que liga um municipio a um CNPJ de consorcio em um ano. Exemplo: Abaete x COMASF x 2015 e um par; o mesmo municipio em outro consorcio e outro par.",
  "MIDES", "Fonte de pagamento observado. Na Base 1, indica que o municipio pagou um CNPJ de consorcio em determinado ano.",
  "MIDES completo", "Consulta anual separada, com todo o painel MIDES processado no projeto entre 2014 e 2021. Nao usa MUNIC nem SICONFI.",
  "valor_corrente", "No MIDES, pagamentos do proprio exercicio.",
  "valor_restos", "No MIDES, pagamentos de restos a pagar. Sao valores associados a obrigacoes de anos anteriores.",
  "valor_total", "No MIDES, soma de valor_corrente e valor_restos para a linha municipio-consorcio-ano.",
  "MUNIC", "Fonte declaratoria do IBGE. Na Base 1, indica que o municipio declarou participacao em consorcio em 2015 ou 2019.",
  "SICONFI", "Fonte contabil/fiscal agregada por municipio e ano. Nao identifica o CNPJ de destino; por isso nao cria vinculo municipio-consorcio.",
  "Cadastro IPEA", "Cadastro de CNPJs de consorcios usado para filtrar MIDES/MUNIC e anexar metadados como sigla, razao social e setor.",
  "Aparece nas duas fontes", "O mesmo par municipio-consorcio aparece no MIDES e na MUNIC no mesmo ano.",
  "So MIDES", "O par aparece no MIDES como pagamento observado, mas nao aparece na MUNIC naquele ano.",
  "So MUNIC", "O par aparece na MUNIC como participacao declarada, mas nao aparece no MIDES naquele ano.",
  "congruente", "MIDES e SICONFI sao positivos e a diferenca fica dentro da tolerancia.",
  "divergente_valor", "MIDES e SICONFI sao positivos, mas a diferenca fica fora da tolerancia.",
  "mides_sem_siconfi", "MIDES mostra pagamento, mas o SICONFI reconstruido nao mostra despesa com consorcios no municipio-ano.",
  "siconfi_sem_mides", "SICONFI mostra despesa com consorcios, mas o MIDES nao mostra pagamento aos CNPJs do cadastro no municipio-ano.",
  "munic_sem_fluxo_financeiro", "MUNIC declara vinculo, mas MIDES e SICONFI nao mostram fluxo financeiro no municipio-ano.",
  "consorcio_pagas", "Regra SICONFI usada: rubricas com 'consorcio' e estagio 'Despesas Pagas'.",
  "2015 vs 2019", "Comparacao temporal feita por par municipio-consorcio. Classifica se o par permaneceu, entrou em 2019 ou saiu depois de 2015.",
  "Raiz do CNPJ", "Os oito primeiros digitos do CNPJ. E usada apenas para auditar relacoes de matriz e filial; a consolidacao financeira por raiz ainda nao foi aplicada.",
  "Auditoria", "Painel de suspeitas cadastrais e territoriais para revisar CNPJs com mesmo nome, sigla ausente ou repeticoes em um mesmo municipio-ano."
)

label_com_info <- function(rotulo, explicacao, modo = NULL) {
  tags$span(
    class = "filter-label",
    rotulo,
    if (!is.null(modo)) tags$span(class = "filter-mode", modo),
    tags$span(
      class = "filter-info",
      title = explicacao,
      `aria-label` = paste0(rotulo, ". ", explicacao),
      tabindex = "0",
      "i"
    )
  )
}

ui <- page_navbar(
  title = div(
    class = "brand-wrap",
    div(
      class = "brand-text",
      span(class = "brand-title", "Painel ideiaMides"),
      span(class = "brand-subtitle", "MIDES, MUNIC, SICONFI e auditoria")
    )
  ),
  window_title = "ideiaMides | Dashboard",
  theme = tema,
  header = tags$head(
    tags$title("ideiaMides | Dashboard"),
    tags$style(HTML("
      :root {
        --ipea-ink: #173a50;
        --ipea-muted: #55798e;
        --ipea-line: #c7d8e3;
        --ipea-green: #62b426;
        --ipea-bg: #f4f7f9;
      }
      body { background: var(--ipea-bg); }
      .navbar {
        background: var(--ipea-ink) !important;
        border-bottom: 3px solid var(--ipea-green);
        box-shadow: 0 8px 24px rgba(23, 58, 80, .14);
      }
      .navbar .nav-link, .navbar .navbar-brand { color: #edf5f8 !important; }
      .navbar .nav-link.active {
        color: #ffffff !important;
        background: rgba(255, 255, 255, .10);
      }
      .navbar-nav {
        margin-left: 36px;
        gap: 6px;
      }
      .brand-wrap {
        display: flex;
        align-items: center;
        gap: 12px;
        min-width: 220px;
      }
      .nav-logo {
        height: 36px;
        width: auto;
        margin-left: 18px;
        filter: brightness(0) invert(1);
        opacity: .96;
      }
      .brand-text {
        display: flex;
        flex-direction: column;
        line-height: 1.05;
      }
      .brand-title {
        font-family: Georgia, serif;
        font-size: 20px;
        font-weight: 700;
      }
      .brand-subtitle {
        color: #b8ccd6;
        font-size: 11px;
        margin-top: 3px;
      }
      .page-band {
        max-width: 1500px;
        margin: 0 auto;
        padding: 18px 20px 28px 20px;
      }
      .hero {
        background: #ffffff;
        border: 1px solid var(--ipea-line);
        border-left: 5px solid var(--ipea-green);
        padding: 18px 20px;
        margin-bottom: 14px;
      }
      .hero h2 {
        margin: 0;
        color: var(--ipea-ink);
        font-family: Georgia, serif;
        font-size: 26px;
      }
      .hero p {
        color: var(--ipea-muted);
        margin: 6px 0 0 0;
        font-size: 13px;
        max-width: 980px;
      }
      .filter-card, .panel-card, .bslib-card {
        border: 1px solid var(--ipea-line);
        border-radius: 4px;
        background: #ffffff;
        box-shadow: none;
      }
      .filter-card, .panel-card { padding: 14px; }
      .filter-card h3, .panel-card h3, .section-label {
        font-family: Consolas, 'Lucida Console', monospace;
        text-transform: uppercase;
        letter-spacing: .08em;
        font-size: 11px;
        color: var(--ipea-muted);
        margin: 0 0 10px 0;
      }
      .kpi-row {
        display: grid;
        grid-template-columns: repeat(5, minmax(0, 1fr));
        gap: 10px;
        margin-bottom: 12px;
      }
      .mini-kpi {
        background: #ffffff;
        border: 1px solid var(--ipea-line);
        border-top: 4px solid var(--ipea-green);
        padding: 10px 12px;
        min-height: 66px;
      }
      .mini-kpi .label {
        font-family: Consolas, 'Lucida Console', monospace;
        font-size: 10px;
        letter-spacing: .07em;
        text-transform: uppercase;
        color: var(--ipea-muted);
      }
      .mini-kpi .value {
        font-family: Georgia, serif;
        font-size: 24px;
        line-height: 1.08;
        color: var(--ipea-ink);
      }
      .concept-grid {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 12px;
        margin-bottom: 12px;
      }
      .concept-card, .audit-card {
        border: 1px solid var(--ipea-line);
        border-top: 4px solid var(--ipea-green);
        background: #ffffff;
        padding: 13px;
        min-height: 112px;
      }
      .audit-card { border-top-color: var(--ipea-ink); }
      .concept-card strong, .audit-card strong {
        display: block;
        color: var(--ipea-ink);
        font-family: Consolas, 'Lucida Console', monospace;
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: .06em;
        margin-bottom: 7px;
      }
      .concept-card p, .audit-card p, .small-note {
        color: #202426;
        font-size: 12px;
        line-height: 1.38;
        margin: 0;
      }
      .small-note { color: var(--ipea-muted); margin-bottom: 10px; }
      .inline-filters, .audit-grid {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 10px;
        margin-bottom: 12px;
      }
      .audit-grid { grid-template-columns: repeat(4, minmax(0, 1fr)); }
      .audit-lead {
        border-left: 4px solid var(--ipea-green);
        padding: 10px 12px;
        background: #f5faf2;
        color: #202426;
        font-size: 12px;
        line-height: 1.4;
        margin-bottom: 12px;
      }
      .map-wrap {
        min-height: 660px;
      }
      .girafe_container_std {
        width: 100% !important;
      }
      .girafe_container_std svg path {
        stroke-dasharray: none !important;
        stroke-linecap: butt !important;
        stroke-linejoin: round !important;
        vector-effect: non-scaling-stroke;
        shape-rendering: geometricPrecision;
      }
      .map-note {
        background: #ffffff;
        border: 1px solid var(--ipea-line);
        padding: 10px 12px;
        font-size: 12px;
        color: var(--ipea-muted);
        margin-bottom: 10px;
      }
      .doc-grid {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 12px;
        margin: 12px 0;
      }
      .doc-card {
        border: 1px solid var(--ipea-line);
        border-top: 4px solid var(--ipea-green);
        background: #ffffff;
        padding: 14px;
      }
      .doc-card h3 {
        color: var(--ipea-ink);
        font-size: 16px;
        margin: 0 0 8px 0;
      }
      .doc-card p, .doc-card li, .doc-detail p, .doc-detail li {
        color: #3c4a50;
        font-size: 13px;
        line-height: 1.5;
      }
      .doc-detail {
        border: 1px solid var(--ipea-line);
        background: #ffffff;
        padding: 14px 16px;
        margin-bottom: 10px;
      }
      .doc-detail summary {
        cursor: pointer;
        color: var(--ipea-ink);
        font-weight: 700;
      }
      .doc-detail table { width: 100%; margin-top: 10px; font-size: 12px; }
      .doc-detail th { background: #edf4f7; color: var(--ipea-ink); }
      .doc-detail th, .doc-detail td { border: 1px solid var(--ipea-line); padding: 7px; vertical-align: top; }
      td.details-control {
        cursor: pointer;
        text-align: center;
        color: var(--ipea-ink);
        font-weight: 700;
      }
      td.details-control::before {
        content: '+';
        display: inline-block;
        width: 18px;
        height: 18px;
        line-height: 16px;
        border: 1px solid var(--ipea-line);
        background: #ffffff;
      }
      tr.shown td.details-control::before {
        content: '-';
        background: var(--ipea-ink);
        color: #ffffff;
      }
      .dt-detail-box {
        padding: 10px 12px;
        background: #fbfcfd;
        border-left: 3px solid var(--ipea-green);
        font-size: 12px;
        line-height: 1.4;
      }
      .dt-detail-box strong {
        display: block;
        margin: 8px 0 4px;
        color: var(--ipea-ink);
      }
      .dt-detail-box ul {
        margin: 0 0 6px 18px;
        padding: 0;
      }
      .selectize-input, .form-control, .form-select, .btn { border-radius: 3px !important; }
      .filter-mode {
        color: var(--ipea-muted);
        font-family: Consolas, 'Lucida Console', monospace;
        font-size: 9px;
        letter-spacing: .05em;
        text-transform: uppercase;
        border: 1px solid var(--ipea-line);
        border-radius: 2px;
        padding: 1px 4px;
      }
      .selectize-control.multi .selectize-input::after, .selectize-control.single .selectize-input::after {
        border-color: var(--ipea-ink) transparent transparent transparent;
        opacity: 1;
      }
      .selectize-control.multi .selectize-input {
        min-height: 41px;
        padding: 9px 32px 7px 11px;
        background: #ffffff;
      }
      .selectize-dropdown { border-color: var(--ipea-line); }
      .btn-reset {
        width: 100%;
        border: 1px solid var(--ipea-ink);
        background: #ffffff;
        color: var(--ipea-ink);
        font-family: Consolas, 'Lucida Console', monospace;
        text-transform: uppercase;
        letter-spacing: .06em;
        font-size: 11px;
      }
      .btn-map {
        width: auto;
        min-width: 180px;
        margin-bottom: 10px;
      }
      .filter-label { display: inline-flex; align-items: center; gap: 5px; }
      .filter-info {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 15px;
        height: 15px;
        border: 1px solid var(--ipea-muted);
        border-radius: 50%;
        color: var(--ipea-muted);
        font-family: Georgia, serif;
        font-size: 10px;
        font-style: italic;
        font-weight: 700;
        line-height: 1;
        cursor: help;
      }
      .filter-info:focus { outline: 2px solid var(--ipea-green); outline-offset: 2px; }
      .nav-tabs .nav-link { border-radius: 3px 3px 0 0; }
      .dataTables_wrapper { font-size: 12px; }
      table.dataTable thead th {
        font-family: Consolas, 'Lucida Console', monospace;
        text-transform: uppercase;
        font-size: 10px;
        color: var(--ipea-muted);
      }
      @media (max-width: 980px) {
        .kpi-row, .concept-grid, .inline-filters, .audit-grid, .doc-grid {
          grid-template-columns: 1fr;
        }
        .brand-subtitle { display: none; }
        .navbar-nav { margin-left: 0; gap: 0; }
        .nav-logo { height: 30px; margin-left: 0; }
      }
    "))
  ),
  nav_panel(
    "Visao geral",
    div(
      class = "page-band",
      div(class = "hero", h2("Consulta executiva das bases do projeto"), p("O painel separa o recorte 2015/2019, o MIDES completo 2014-2021 e a auditoria cadastral. Cada area tem escopo, filtros e interpretacao proprios.")),
      div(
        class = "concept-grid",
        div(class = "concept-card", tags$strong("Recorte 2015/2019"), p("Recorte comparavel de 2015 e 2019. Junta MIDES e MUNIC por par municipio-consorcio-ano e usa SICONFI como validacao financeira agregada.")),
        div(class = "concept-card", tags$strong("MIDES completo"), p("Consulta anual separada de pagamentos observados no MIDES entre 2014 e 2021. Nao mistura MUNIC nem SICONFI.")),
        div(class = "concept-card", tags$strong("Auditoria"), p("Listas de suspeitas para revisao humana: nomes/CNPJs duplicados e nomes territoriais parecidos no mesmo municipio-ano."))
      ),
      div(
        class = "concept-grid",
        div(class = "concept-card", tags$strong("Filtros locais"), p("Os filtros do recorte 2015/2019 ficam na propria pagina; os filtros do MIDES ficam na pagina MIDES. Isso evita leitura cruzada indevida.")),
        div(class = "concept-card", tags$strong("Tabelas exportaveis"), p("As tabelas mantem busca, filtro por coluna e exportacao CSV/Excel para apoiar revisoes e reunioes.")),
        div(class = "concept-card", tags$strong("Mapas"), p("Mapas sintetizam intensidade, fontes e movimentos territoriais, sempre acompanhando os filtros da pagina."))
      )
    )
  ),
  nav_panel(
    "Recorte 2015/2019",
    div(
      class = "page-band",
      div(class = "hero", h2("Recorte 2015/2019: MIDES, MUNIC e SICONFI"), p("Cada linha representa municipio x consorcio x ano; SICONFI valida o municipio-ano e nao cria vinculo.")),
      layout_sidebar(
        sidebar = sidebar(
          width = 320,
          div(
            class = "filter-card",
            h3("Filtros do recorte"),
            checkboxGroupInput("ano", label_com_info("Ano", "Seleciona 2015, 2019 ou ambos no recorte comparavel."), choices = anos_opts, selected = anos_opts, inline = TRUE),
            checkboxGroupInput("grupo", label_com_info("Conjuntos MIDES/MUNIC", "Filtra se o par aparece nas duas fontes, so no MIDES ou so na MUNIC."), choices = grupos_labels, selected = grupos_opts),
            checkboxGroupInput("classe", label_com_info("Validacao SICONFI opcional", "Filtra a classe municipio-ano da comparacao financeira. SICONFI nao identifica o CNPJ de destino."), choices = classes_labels, selected = classes_opts),
            selectizeInput("municipio", label_com_info("Municipio", "Clique no campo para abrir opcoes. Tambem e possivel digitar parte do nome para localizar e selecionar um ou mais municipios.", "Selecionar"), choices = NULL, selected = NULL, multiple = TRUE, options = list(placeholder = "Clique para selecionar ou digite para localizar", plugins = list("remove_button"), closeAfterSelect = FALSE)),
            selectizeInput("consorcio", label_com_info("Consorcio/sigla", "Clique no campo para abrir opcoes. Tambem e possivel digitar parte do nome ou sigla para localizar e selecionar.", "Selecionar"), choices = NULL, selected = NULL, multiple = TRUE, options = list(placeholder = "Clique para selecionar ou digite para localizar", plugins = list("remove_button"), closeAfterSelect = FALSE)),
            textInput("busca", label_com_info("Busca livre", "Digite um trecho de municipio, sigla, CNPJ ou razao social dentro do recorte atual.", "Digitar"), placeholder = "Digite municipio, sigla, CNPJ ou razao social"),
            actionButton("limpar", "Limpar filtros", class = "btn-reset")
          )
        ),
        div(
          class = "kpi-row",
          div(class = "mini-kpi", div(class = "label", "Pares"), div(class = "value", textOutput("kpi_pares", inline = TRUE))),
          div(class = "mini-kpi", div(class = "label", "Municipios"), div(class = "value", textOutput("kpi_municipios", inline = TRUE))),
          div(class = "mini-kpi", div(class = "label", "Consorcios"), div(class = "value", textOutput("kpi_consorcios", inline = TRUE))),
          div(class = "mini-kpi", div(class = "label", "Valor MIDES"), div(class = "value", textOutput("kpi_valor", inline = TRUE))),
          div(class = "mini-kpi", div(class = "label", "SICONFI"), div(class = "value", textOutput("kpi_siconfi", inline = TRUE)))
        ),
        navset_tab(
          nav_panel(
            "Leitura",
            div(
              class = "panel-card",
              h3("Como interpretar"),
              div(
                class = "concept-grid",
                div(class = "concept-card", tags$strong("Aparece nas duas fontes"), p("O par aparece no MIDES e na MUNIC no mesmo ano.")),
                div(class = "concept-card", tags$strong("So MIDES"), p("Pagamento observado no MIDES, sem declaracao correspondente na MUNIC naquele ano.")),
                div(class = "concept-card", tags$strong("So MUNIC"), p("Declaracao MUNIC sem pagamento MIDES observado para o par no ano."))
              ),
              div(
                class = "concept-grid",
                div(class = "concept-card", tags$strong("SICONFI"), p("Validacao financeira agregada por municipio-ano. O valor pode aparecer repetido em varios pares do mesmo municipio-ano.")),
                div(class = "concept-card", tags$strong("Congruencia"), p("MIDES e SICONFI positivos e diferenca dentro da tolerancia metodologica.")),
                div(class = "concept-card", tags$strong("Unidade"), p("A tabela final e municipio x consorcio x ano."))
              ),
              h3("Resumo dos conjuntos nos filtros atuais"),
              DTOutput("tabela_conjuntos")
            )
          ),
          nav_panel(
            "Tabela",
            div(class = "panel-card", h3("Base final pesquisavel"), p(class = "small-note", "Use os filtros laterais ou os filtros por coluna. A tabela pode ser exportada."), DTOutput("tabela"))
          ),
          nav_panel(
            "Mapa fontes",
            div(
              class = "panel-card map-wrap",
              h3("Composicao territorial das fontes"),
              div(class = "map-note", "Mapa categorico por municipio. A visualizacao acompanha os filtros; passe o mouse para ver contagens MIDES/MUNIC e classes SICONFI."),
              girafeOutput("mapa_fontes", width = "100%", height = "620px")
            )
          ),
          nav_panel(
            "SICONFI municipio-ano",
            div(class = "panel-card", h3("Camada agregada de validacao"), p(class = "small-note", "Esta tabela mostra a camada municipio-ano usada para comparar MIDES e SICONFI."), DTOutput("tabela_mun_ano"))
          )
        )
      )
    )
  ),
  nav_panel(
    "MIDES completo",
    div(
      class = "page-band",
      div(class = "hero", h2("MIDES completo 2014-2021"), p("Consulta separada do painel anual MIDES. A unidade e municipio x consorcio x ano, sem MUNIC e sem SICONFI.")),
      div(
        class = "panel-card",
        h3("Filtros MIDES"),
        div(
          class = "inline-filters",
          checkboxGroupInput("mides_ano", label_com_info("Ano MIDES", "Seleciona anos observados no MIDES entre 2014 e 2021."), choices = mides_anos_opts, selected = mides_anos_opts, inline = TRUE),
          selectizeInput("mides_municipio", label_com_info("Municipio", "Clique no campo para abrir opcoes. Tambem e possivel digitar parte do nome para localizar e selecionar municipios.", "Selecionar"), choices = NULL, selected = NULL, multiple = TRUE, options = list(placeholder = "Clique para selecionar ou digite para localizar", plugins = list("remove_button"), closeAfterSelect = FALSE)),
          selectizeInput("mides_consorcio", label_com_info("Consorcio/sigla", "Clique no campo para abrir opcoes. Tambem e possivel digitar parte do nome ou sigla para localizar e selecionar.", "Selecionar"), choices = NULL, selected = NULL, multiple = TRUE, options = list(placeholder = "Clique para selecionar ou digite para localizar", plugins = list("remove_button"), closeAfterSelect = FALSE))
        ),
        div(
          class = "inline-filters",
          selectInput("mides_regra_valor", label_com_info("Regra de valor", "Define quais linhas MIDES entram no recorte: todos os registros, valor corrente, restos a pagar ou valor total positivo."), choices = mides_regra_valor_opts, selected = "total"),
          selectInput("mides_mapa_metrica", label_com_info("Metrica do mapa", "Define a cor do mapa: valor MIDES, numero de consorcios ou numero de transacoes."), choices = mides_mapa_metrica_opts, selected = "valor_total"),
          textInput("mides_busca", label_com_info("Busca livre no MIDES", "Digite um trecho de municipio, sigla, CNPJ, razao social ou nome do credor no MIDES.", "Digitar"), placeholder = "Digite municipio, sigla, CNPJ ou razao social"),
          div(tags$label("&nbsp;"), actionButton("limpar_mides", "Limpar MIDES", class = "btn-reset"))
        ),
        div(
          class = "inline-filters",
          selectizeInput("mides_area", label_com_info("Area de politica publica", "Seleciona politicas especificas, como Saude, Agricultura ou Saneamento basico. Um consorcio com mais de uma area e encontrado em qualquer uma delas.", "Selecionar"), choices = NULL, selected = NULL, multiple = TRUE, options = list(placeholder = "Clique para selecionar areas", plugins = list("remove_button"), closeAfterSelect = FALSE)),
          selectizeInput("mides_macrogrupo", label_com_info("Macrogrupo", "Seleciona blocos amplos que reagrupam as areas detalhadas, como Saude ou Ambiente e saneamento.", "Selecionar"), choices = NULL, selected = NULL, multiple = TRUE, options = list(placeholder = "Clique para selecionar macrogrupos", plugins = list("remove_button"), closeAfterSelect = FALSE)),
          selectizeInput("mides_perfil", label_com_info("Perfil institucional", "Seleciona como o consorcio se organiza: setorial, multiarea documentada ou multifinalitario ou multissetorial. Perfil nao e uma area de politica publica.", "Selecionar"), choices = NULL, selected = NULL, multiple = TRUE, options = list(placeholder = "Clique para selecionar perfis", plugins = list("remove_button"), closeAfterSelect = FALSE))
        )
      ),
      div(
        class = "kpi-row",
        div(class = "mini-kpi", div(class = "label", "Linhas anuais"), div(class = "value", textOutput("kpi_mides_linhas", inline = TRUE))),
        div(class = "mini-kpi", div(class = "label", "Pares unicos"), div(class = "value", textOutput("kpi_mides_pares", inline = TRUE))),
        div(class = "mini-kpi", div(class = "label", "Municipios"), div(class = "value", textOutput("kpi_mides_municipios", inline = TRUE))),
        div(class = "mini-kpi", div(class = "label", "Consorcios"), div(class = "value", textOutput("kpi_mides_consorcios", inline = TRUE))),
        div(class = "mini-kpi", div(class = "label", "Valor total"), div(class = "value", textOutput("kpi_mides_valor", inline = TRUE)))
      ),
      div(
        class = "concept-grid",
        div(class = "concept-card", tags$strong("Valor corrente"), p("Pagamentos do proprio exercicio.")),
        div(class = "concept-card", tags$strong("Restos a pagar"), p("Pagamentos associados a obrigacoes de anos anteriores.")),
        div(class = "concept-card", tags$strong("Valor total"), p("Soma de corrente e restos. Use com cuidado para leitura temporal."))
      ),
      navset_tab(
        nav_panel(
          "Mapa",
          div(
            class = "panel-card map-wrap",
            h3("Mapa municipal MIDES"),
            div(class = "map-note", "Mapa coropletico dinamico em escala logaritmica. A visualizacao acompanha os filtros; passe o mouse para ver municipio, valores, consorcios e transacoes."),
            girafeOutput("mapa_mides", width = "100%", height = "620px"),
            br(),
            h3("Municipios de maior intensidade no filtro atual"),
            DTOutput("tabela_mides_mapa_top")
          )
        ),
        nav_panel(
          "Entradas/saidas",
          div(
            class = "panel-card map-wrap",
            h3("Entradas e saidas no MIDES completo"),
            div(class = "map-note", "Leitura: azul indica entrada de pares municipio-consorcio, laranja indica saida, verde indica permanencia. Em 2014, o mapa mostra apenas o inicio da serie observada."),
            girafeOutput("mapa_mides_movimento", width = "100%", height = "860px"),
            br(),
            uiOutput("bloco_mides_movimento")
          )
        ),
        nav_panel("Resumo anual", div(class = "panel-card", h3("Resumo por ano"), DTOutput("tabela_mides_ano"))),
        nav_panel("Tabela detalhada", div(class = "panel-card", h3("MIDES municipio x consorcio x ano"), DTOutput("tabela_mides")))
      )
    )
  ),
  nav_panel(
    "2015 vs 2019",
    div(
      class = "page-band",
      div(class = "hero", h2("Entradas, saidas e permanencias"), p("Compara cada par municipio-consorcio entre 2015 e 2019.")),
      div(
        class = "panel-card",
        h3("Filtros da comparacao"),
        div(
          class = "inline-filters",
          selectizeInput("cmp_municipio", label_com_info("Municipio", "Clique no campo para abrir opcoes. Tambem e possivel digitar parte do nome para localizar e selecionar municipios.", "Selecionar"), choices = NULL, selected = NULL, multiple = TRUE, options = list(placeholder = "Clique para selecionar ou digite para localizar", plugins = list("remove_button"), closeAfterSelect = FALSE)),
          selectizeInput("cmp_consorcio", label_com_info("Consorcio/sigla", "Clique no campo para abrir opcoes. Tambem e possivel digitar parte do nome ou sigla para localizar e selecionar.", "Selecionar"), choices = NULL, selected = NULL, multiple = TRUE, options = list(placeholder = "Clique para selecionar ou digite para localizar", plugins = list("remove_button"), closeAfterSelect = FALSE)),
          checkboxGroupInput("cmp_status", label_com_info("Status 2015 -> 2019", "Filtra pares que permaneceram, entraram em 2019 ou sairam depois de 2015."), choices = status_opts, selected = status_opts)
        ),
        textInput("cmp_busca", label_com_info("Busca livre na comparacao", "Digite um trecho de municipio, sigla, CNPJ ou razao social dentro da comparacao temporal.", "Digitar"), placeholder = "Digite municipio, sigla, CNPJ ou razao social"),
        actionButton("limpar_cmp", "Limpar comparacao", class = "btn-reset")
      ),
      div(
        class = "kpi-row",
        div(class = "mini-kpi", div(class = "label", "Pares comparados"), div(class = "value", textOutput("kpi_cmp_pares", inline = TRUE))),
        div(class = "mini-kpi", div(class = "label", "Permaneceram"), div(class = "value", textOutput("kpi_cmp_perm", inline = TRUE))),
        div(class = "mini-kpi", div(class = "label", "Entraram em 2019"), div(class = "value", textOutput("kpi_cmp_entrou", inline = TRUE))),
        div(class = "mini-kpi", div(class = "label", "Sairam apos 2015"), div(class = "value", textOutput("kpi_cmp_saiu", inline = TRUE))),
        div(class = "mini-kpi", div(class = "label", "Consorcios"), div(class = "value", textOutput("kpi_cmp_cons", inline = TRUE)))
      ),
      navset_tab(
        nav_panel(
          "Mapa",
          div(
            class = "panel-card map-wrap",
            h3("Mapa de transicao 2015-2019"),
            div(class = "map-note", "Mapa categorico por municipio. A visualizacao acompanha os filtros; a cor mostra se predominou permanencia, entrada em 2019 ou saida apos 2015."),
            girafeOutput("mapa_transicao", width = "100%", height = "620px")
          )
        ),
        nav_panel(
          "Tabela",
          div(class = "panel-card", h3("Tabela de transicao"), DTOutput("tabela_transicao"))
        )
      )
    )
  ),
  nav_panel(
    "Auditoria",
    div(
      class = "page-band",
      div(class = "hero", h2("Auditoria cadastral"), p("Alertas para revisao humana. A auditoria nao corrige nem unifica CNPJs automaticamente.")),
      div(
        class = "audit-grid",
        div(class = "audit-card", tags$strong("Raiz CNPJ"), p("Matriz e filiais pela raiz de 8 digitos do CNPJ.")),
        div(class = "audit-card", tags$strong("Nomes duplicados"), p("Mesmo nome juridico com mais de um CNPJ.")),
        div(class = "audit-card", tags$strong("Nomes parecidos"), p("CNPJs diferentes no mesmo municipio-ano compartilham termos territoriais relevantes.")),
        div(class = "audit-card", tags$strong("Revisao humana"), p("O alerta indica suspeita; nao e evidencia conclusiva de erro."))
      ),
      navset_tab(
        nav_panel("Raiz CNPJ", div(class = "panel-card", h3("Raizes de CNPJ com matriz/filiais ou multiplos CNPJs"), DTOutput("tabela_auditoria_cnpj_raiz"))),
        nav_panel("Nomes juridicos", div(class = "panel-card", h3("Nomes juridicos com mais de um CNPJ"), DTOutput("tabela_auditoria_nome"))),
        nav_panel("Nomes parecidos", div(class = "panel-card", h3("Pares com nomes territoriais parecidos"), DTOutput("tabela_auditoria_pares_parecidos"))),
        nav_panel("Mesmo nome no municipio-ano", div(class = "panel-card", h3("Municipio-ano com mesmo nome e mais de um CNPJ"), DTOutput("tabela_auditoria_mun_ano")))
      )
    )
  ),
  nav_panel(
    "Documentacao",
    div(
      class = "page-band",
      div(class = "hero", h2("Documentacao metodologica"), p("Leitura orientada do painel, das fontes, dos conceitos e da classificacao por area de politica publica.")),
      navset_tab(
        nav_panel(
          "Guia do painel",
          div(
            class = "doc-grid",
            div(class = "doc-card", h3("Base 1"), p("Recorte comparavel de 2015 e 2019. MIDES observa pagamento; MUNIC registra participacao declarada; SICONFI valida o gasto agregado do municipio-ano.")),
            div(class = "doc-card", h3("MIDES completo"), p("Serie anual de 2014 a 2021. Permite acompanhar intensidade e movimentos de pares municipio-consorcio, sem combinar MUNIC ou SICONFI.")),
            div(class = "doc-card", h3("Auditoria"), p("Identifica sinais cadastrais para revisao humana. Nao corrige CNPJ, nao soma valores e nao unifica matriz e filial automaticamente."))
          ),
          tags$details(class = "doc-detail", open = NA, tags$summary("Como ler as telas"),
            tags$ul(
              tags$li(tags$strong("Visao geral:"), " panorama do recorte e seus indicadores."),
              tags$li(tags$strong("Base 1:"), " consulta de pares em 2015 e 2019 e sua classe de validacao SICONFI."),
              tags$li(tags$strong("MIDES completo:"), " pagamentos e movimentos anuais no MIDES entre 2014 e 2021."),
              tags$li(tags$strong("2015 vs 2019:"), " compara presenca, entrada e saida entre os dois anos."),
              tags$li(tags$strong("Auditoria:"), " apresenta alertas que exigem verificacao, sem alterar os dados de origem."))
          )
        ),
        nav_panel(
          "Conceitos",
          div(class = "panel-card", h3("Termos principais"), DTOutput("tabela_definicoes")),
          tags$details(class = "doc-detail", tags$summary("Regra de leitura do SICONFI"),
            p("O SICONFI e uma fonte contabil por municipio e ano. Ele nao informa o CNPJ do consorcio que recebeu o recurso. Por isso, ele nao cria pares e nao confirma isoladamente um vinculo especifico."),
            p("A regra usada, ", tags$code("consorcio_pagas"), ", soma despesas pagas em rubricas de consorcio. A comparacao com o MIDES usa tolerancia de 10% ou R$ 10 mil."))
        ),
        nav_panel(
          "Classificacao de areas",
          div(
            class = "doc-grid",
            div(class = "doc-card", h3("Area detalhada"), p("Tema de politica publica com evidencia registrada, como Saude, Agricultura ou Saneamento basico. Um CNPJ pode ter mais de uma area.")),
            div(class = "doc-card", h3("Macrogrupo"), p("Familia analitica das areas detalhadas. Residuos solidos, Meio ambiente e Recursos hidricos foram reunidos em Ambiente e saneamento.")),
            div(class = "doc-card", h3("Perfil institucional"), p("Forma de organizacao do consorcio. Perfil nao substitui nem cria uma area de politica publica."))
          ),
          tags$details(class = "doc-detail", open = NA, tags$summary("Diferenca entre area, macrogrupo e perfil"),
            tags$table(tags$thead(tags$tr(tags$th("Campo"), tags$th("Pergunta respondida"), tags$th("Exemplo"))), tags$tbody(
              tags$tr(tags$td("Area detalhada"), tags$td("Em qual politica publica o consorcio atua?"), tags$td("Saude; Saneamento basico; Agricultura.")),
              tags$tr(tags$td("Macrogrupo"), tags$td("A qual familia ampla pertencem essas areas?"), tags$td("Saude; Ambiente e saneamento; Desenvolvimento territorial.")),
              tags$tr(tags$td("Perfil institucional"), tags$td("Como o consorcio se organiza ou se apresenta?"), tags$td("Setorial; Multiarea documentada; Multifinalitario ou multissetorial."))
            )),
            p("Exemplo: um consorcio com Meio ambiente e Residuos solidos recebe o macrogrupo Ambiente e saneamento e o perfil Multiarea documentada. Um consorcio denominado multifinalitario ou multissetorial pode permanecer sem area especifica quando o nome nao prova uma politica concreta.")
          ),
          tags$details(class = "doc-detail", tags$summary("Perfis institucionais"),
            tags$ul(
              tags$li(tags$strong("Setorial:"), " uma area de politica publica foi identificada."),
              tags$li(tags$strong("Multiarea documentada:"), " duas ou mais areas detalhadas foram identificadas por evidencia."),
              tags$li(tags$strong("Multifinalitario ou multissetorial:"), " perfil amplo identificado pelo nome ou pela documentacao, sem atribuir area quando nao ha evidencia setorial suficiente."))
          ),
          tags$details(class = "doc-detail", open = NA, tags$summary("Como a classificacao v0.5 foi produzida"),
            tags$ol(
              tags$li("Os setores do Cadastro IPEA e da MUNIC foram padronizados em areas detalhadas e macrogrupos."),
              tags$li("Combinacoes MUNIC entre macroareas heterogeneas nao foram unidas automaticamente."),
              tags$li("Nome juridico e aliases MIDES foram usados somente como inferencia textual rastreavel quando nao havia evidencia setorial direta."),
              tags$li("Area, macrogrupo, perfil institucional, fonte, status e justificativa foram registrados em campos separados."),
              tags$li("As decisoes foram gravadas em camada versionada, sem alterar MIDES, MUNIC, SICONFI ou o cadastro bruto."))
          ),
          tags$details(class = "doc-detail", tags$summary("Taxonomia aplicada"),
            tags$table(tags$thead(tags$tr(tags$th("Area detalhada"), tags$th("Macrogrupo"), tags$th("Leitura"))), tags$tbody(
              tags$tr(tags$td("saude; urgencia_emergencia; vigilancia_em_saude"), tags$td("saude"), tags$td("Atencao, redes, urgencia e vigilancia em saude.")),
              tags$tr(tags$td("saneamento_basico; residuos_solidos; meio_ambiente; recursos_hidricos"), tags$td("ambiente_saneamento"), tags$td("Servicos ambientais, saneamento e gestao hidrica.")),
              tags$tr(tags$td("desenvolvimento_regional; desenvolvimento_urbano; transporte; infraestrutura; habitacao"), tags$td("desenvolvimento_territorial"), tags$td("Cooperacao territorial ampla, estruturacao regional e funcoes urbanas. Desenvolvimento regional nao pressupoe um setor final unico.")),
              tags$tr(tags$td("assistencia_social; educacao; esporte"), tags$td("politicas_sociais"), tags$td("Politicas sociais finalisticas.")),
              tags$tr(tags$td("agricultura; inspecao_produtos_origem_animal"), tags$td("desenvolvimento_rural"), tags$td("Apoio produtivo e inspecao de origem animal.")),
              tags$tr(tags$td("iluminacao_publica; licitacao_compras_compartilhadas; gestao_publica"), tags$td("gestao_publica"), tags$td("Funcoes administrativas e servicos compartilhados."))
            ))
          ),
          tags$details(class = "doc-detail", tags$summary("Fontes e limites aplicados"),
            tags$ul(
              tags$li(tags$strong("Fontes usadas:"), " Cadastro IPEA, MUNIC auditada, revisao documental e, quando necessario, nome juridico ou alias MIDES."),
              tags$li(tags$strong("Matriz/filial:"), " filiais herdaram apenas area e perfil da matriz pela raiz de oito digitos. Valores, pares e movimentos nao foram consolidados."),
              tags$li(tags$strong("Multifinalitario ou multissetorial:"), " recebeu area apenas quando havia evidencia setorial explicita."),
              tags$li(tags$strong("Cobertura no MIDES:"), " dos 161 CNPJs observados, 136 tem area classificada; 15 tem perfil amplo sem area comprovada; 8 sao sediados fora de MG; 1 esta inativo ou baixado; e uma associacao municipal foi retirada da camada analitica."),
              tags$li(tags$strong("Limite atual:"), " a classificacao de consorcios sediados fora de MG e a consolidacao financeira de matriz/filial nao foram realizadas."))
          )
        )
      )
    )
  ),
    nav_spacer(),
  nav_item(tags$img(src = "IPEA-LOGO.png", alt = "IPEA", class = "nav-logo"))
)

server <- function(input, output, session) {
  updateSelectizeInput(session, "municipio", choices = municipios_opts, server = TRUE)
  updateSelectizeInput(session, "consorcio", choices = consorcios_opts, server = TRUE)
  updateSelectizeInput(session, "cmp_municipio", choices = municipios_opts, server = TRUE)
  updateSelectizeInput(session, "cmp_consorcio", choices = consorcios_opts, server = TRUE)
  updateSelectizeInput(session, "mides_municipio", choices = mides_municipios_opts, server = TRUE)
  updateSelectizeInput(session, "mides_consorcio", choices = mides_consorcios_opts, server = TRUE)
  # Sao listas pequenas; carregar no cliente preserva rotulos legiveis e resposta imediata.
  updateSelectizeInput(session, "mides_area", choices = mides_areas_opts, server = FALSE)
  updateSelectizeInput(session, "mides_macrogrupo", choices = mides_macrogrupos_opts, server = FALSE)
  updateSelectizeInput(session, "mides_perfil", choices = mides_perfis_opts, server = FALSE)

  observeEvent(input$limpar, {
    updateCheckboxGroupInput(session, "ano", selected = anos_opts)
    updateCheckboxGroupInput(session, "grupo", selected = grupos_opts)
    updateCheckboxGroupInput(session, "classe", selected = classes_opts)
    updateSelectizeInput(session, "municipio", selected = character(0))
    updateSelectizeInput(session, "consorcio", selected = character(0))
    updateTextInput(session, "busca", value = "")
  })

  observeEvent(input$limpar_cmp, {
    updateSelectizeInput(session, "cmp_municipio", selected = character(0))
    updateSelectizeInput(session, "cmp_consorcio", selected = character(0))
    updateCheckboxGroupInput(session, "cmp_status", selected = status_opts)
    updateTextInput(session, "cmp_busca", value = "")
  })

  observeEvent(input$limpar_mides, {
    updateCheckboxGroupInput(session, "mides_ano", selected = mides_anos_opts)
    updateSelectizeInput(session, "mides_municipio", selected = character(0))
    updateSelectizeInput(session, "mides_consorcio", selected = character(0))
    updateSelectizeInput(session, "mides_area", selected = character(0))
    updateSelectizeInput(session, "mides_macrogrupo", selected = character(0))
    updateSelectizeInput(session, "mides_perfil", selected = character(0))
    updateSelectInput(session, "mides_regra_valor", selected = "total")
    updateSelectInput(session, "mides_mapa_metrica", selected = "valor_total")
    updateTextInput(session, "mides_busca", value = "")
  })

  dados_filtrados <- reactive({
    if (length(input$ano) == 0 || length(input$grupo) == 0 || length(input$classe) == 0) {
      return(base_final[0, ])
    }

    df <- base_final |>
      filter(
        ano %in% as.integer(input$ano),
        grupo_vinculo %in% input$grupo,
        classe_validacao %in% input$classe
      )

    if (length(input$municipio) > 0) df <- df |> filter(municipio %in% input$municipio)
    if (length(input$consorcio) > 0) df <- df |> filter(sigla %in% input$consorcio)
    if (!is.null(input$busca) && str_squish(input$busca) != "") {
      termos <- str_to_lower(str_squish(input$busca))
      df <- df |> filter(str_detect(pesquisa, fixed(termos)))
    }
    df
  }) |>
    bindCache(input$ano, input$grupo, input$classe, input$municipio, input$consorcio, input$busca)

  dados_transicao <- reactive({
    if (length(input$cmp_status) == 0) return(transicao_pares[0, ])

    df <- transicao_pares |>
      filter(status_temporal %in% input$cmp_status)

    if (length(input$cmp_municipio) > 0) df <- df |> filter(municipio %in% input$cmp_municipio)
    if (length(input$cmp_consorcio) > 0) df <- df |> filter(sigla %in% input$cmp_consorcio)
    if (!is.null(input$cmp_busca) && str_squish(input$cmp_busca) != "") {
      termos <- str_to_lower(str_squish(input$cmp_busca))
      df <- df |> filter(str_detect(pesquisa_transicao, fixed(termos)))
    }
    df
  })

  dados_mides_filtrados <- reactive({
    if (length(input$mides_ano) == 0) {
      return(mides_anual[0, ])
    }

    df <- mides_anual |>
      filter(ano %in% as.integer(input$mides_ano))

    if (!is.null(input$mides_regra_valor)) {
      df <- df |>
        filter(
          case_when(
            input$mides_regra_valor == "corrente" ~ valor_corrente > 0,
            input$mides_regra_valor == "restos" ~ valor_restos > 0,
            input$mides_regra_valor == "total" ~ valor_total > 0,
            TRUE ~ TRUE
          )
        )
    }

    if (length(input$mides_municipio) > 0) df <- df |> filter(municipio %in% input$mides_municipio)
    if (length(input$mides_consorcio) > 0) df <- df |> filter(sigla %in% input$mides_consorcio)
    if (length(input$mides_area) > 0) df <- df |> filter(tem_categoria(area_politica, input$mides_area))
    if (length(input$mides_macrogrupo) > 0) df <- df |> filter(tem_categoria(macrogrupo_politica, input$mides_macrogrupo))
    if (length(input$mides_perfil) > 0) df <- df |> filter(perfil_classificacao %in% input$mides_perfil)
    if (!is.null(input$mides_busca) && str_squish(input$mides_busca) != "") {
      termos <- str_to_lower(str_squish(input$mides_busca))
      df <- df |> filter(str_detect(pesquisa_mides, fixed(termos)))
    }
    df
  }) |>
    bindCache(
      input$mides_ano,
      input$mides_regra_valor,
      input$mides_municipio,
      input$mides_consorcio,
      input$mides_area,
      input$mides_macrogrupo,
      input$mides_perfil,
      input$mides_busca
    )

  dados_mides_mapa <- reactive({
    metrica_mides <- input$mides_mapa_metrica
    if (is.null(metrica_mides) || !metrica_mides %in% mides_mapa_metrica_opts) {
      metrica_mides <- "valor_total"
    }

    resumo <- dados_mides_filtrados() |>
      summarise(
        valor_total = sum(valor_total, na.rm = TRUE),
        valor_corrente = sum(valor_corrente, na.rm = TRUE),
        valor_restos = sum(valor_restos, na.rm = TRUE),
        n_consorcios = n_distinct(cnpj_consorcio),
        n_transacoes = sum(n_transacoes, na.rm = TRUE),
        n_linhas = n(),
        principais_consorcios = paste(head(sort(unique(sigla)), 5), collapse = ", "),
        .by = c(cod_ibge_6, municipio)
      )

    mg_municipios_sf |>
      left_join(resumo, by = "cod_ibge_6") |>
      mutate(
        municipio = coalesce(municipio, str_to_title(municipio_geo)),
        valor_total = coalesce(valor_total, 0),
        valor_corrente = coalesce(valor_corrente, 0),
        valor_restos = coalesce(valor_restos, 0),
        n_consorcios = coalesce(n_consorcios, 0L),
        n_transacoes = coalesce(n_transacoes, 0L),
        n_linhas = coalesce(n_linhas, 0L),
        principais_consorcios = if_else(is.na(principais_consorcios) | principais_consorcios == "", "sem registro no filtro", principais_consorcios),
        mapa_valor = case_when(
          metrica_mides == "valor_corrente" ~ valor_corrente,
          metrica_mides == "n_consorcios" ~ as.numeric(n_consorcios),
          metrica_mides == "n_transacoes" ~ as.numeric(n_transacoes),
          TRUE ~ valor_total
        ),
        mapa_classe = classificar_mapa(mapa_valor, metrica_mides),
        tem_registro = mapa_valor > 0,
        tooltip_mides = paste0(
          "<strong>", municipio, "</strong>",
          "<br>Valor total MIDES: ", fmt_moeda(valor_total),
          "<br>Valor corrente: ", fmt_moeda(valor_corrente),
          "<br>Restos a pagar: ", fmt_moeda(valor_restos),
          "<br>Consorcios: ", fmt_int(n_consorcios),
          "<br>Transacoes: ", fmt_int(n_transacoes),
          "<br>Principais siglas: ", principais_consorcios
        )
      )
  }) |>
    bindCache(
      input$mides_ano,
      input$mides_regra_valor,
      input$mides_mapa_metrica,
      input$mides_municipio,
      input$mides_consorcio,
      input$mides_area,
      input$mides_macrogrupo,
      input$mides_perfil,
      input$mides_busca
    )

  dados_mides_movimento_base <- reactive({
    df <- mides_anual

    if (!is.null(input$mides_regra_valor)) {
      df <- df |>
        filter(
          case_when(
            input$mides_regra_valor == "corrente" ~ valor_corrente > 0,
            input$mides_regra_valor == "restos" ~ valor_restos > 0,
            input$mides_regra_valor == "total" ~ valor_total > 0,
            TRUE ~ TRUE
          )
        )
    }

    if (length(input$mides_municipio) > 0) df <- df |> filter(municipio %in% input$mides_municipio)
    if (length(input$mides_consorcio) > 0) df <- df |> filter(sigla %in% input$mides_consorcio)
    if (length(input$mides_area) > 0) df <- df |> filter(tem_categoria(area_politica, input$mides_area))
    if (length(input$mides_macrogrupo) > 0) df <- df |> filter(tem_categoria(macrogrupo_politica, input$mides_macrogrupo))
    if (length(input$mides_perfil) > 0) df <- df |> filter(perfil_classificacao %in% input$mides_perfil)
    if (!is.null(input$mides_busca) && str_squish(input$mides_busca) != "") {
      termos <- str_to_lower(str_squish(input$mides_busca))
      df <- df |> filter(str_detect(pesquisa_mides, fixed(termos)))
    }

    df |>
      distinct(ano, cod_ibge_6, municipio, cnpj_consorcio, sigla, razao_social)
  }) |>
    bindCache(
      input$mides_regra_valor,
      input$mides_municipio,
      input$mides_consorcio,
      input$mides_area,
      input$mides_macrogrupo,
      input$mides_perfil,
      input$mides_busca
    )

  dados_mides_movimento_mapa <- reactive({
    anos_sel <- sort(unique(as.integer(input$mides_ano)))
    if (length(anos_sel) == 0) {
      return(
        mg_municipios_sf[0, ] |>
          mutate(
            ano = integer(),
            municipio = character(),
            n_entraram = integer(),
            n_sairam = integer(),
            n_permaneceram = integer(),
            n_pares_ativos = integer(),
            classe_movimento = factor(character(), levels = names(paleta_mov_mides)),
            tooltip_movimento = character()
          )
      )
    }

    anos_mides <- sort(unique(mides_anual$ano))
    anos_sel <- intersect(anos_mides, anos_sel)
    pares <- dados_mides_movimento_base()

    atual <- pares |>
      mutate(presente = TRUE)

    anterior <- pares |>
      transmute(
        ano = ano + 1L,
        cod_ibge_6,
        municipio,
        cnpj_consorcio,
        sigla_anterior = sigla,
        razao_social_anterior = razao_social,
        presente_anterior = TRUE
      )

    comparacao <- full_join(
      atual,
      anterior,
      by = c("ano", "cod_ibge_6", "municipio", "cnpj_consorcio")
    ) |>
      filter(ano %in% anos_sel) |>
      mutate(
        sigla = coalesce(sigla, sigla_anterior),
        razao_social = coalesce(razao_social, razao_social_anterior),
        presente = coalesce(presente, FALSE),
        presente_anterior = coalesce(presente_anterior, FALSE),
        entrou = presente & !presente_anterior,
        saiu = !presente & presente_anterior,
        permaneceu = presente & presente_anterior
      )

    resumo <- comparacao |>
      summarise(
        n_entraram = sum(entrou, na.rm = TRUE),
        n_sairam = sum(saiu, na.rm = TRUE),
        n_permaneceram = sum(permaneceu, na.rm = TRUE),
        n_pares_ativos = sum(presente, na.rm = TRUE),
        .by = c(ano, cod_ibge_6, municipio)
      ) |>
      mutate(
        classe_movimento = case_when(
          ano == min(anos_mides) & n_pares_ativos > 0 ~ "Inicio",
          n_entraram == 0 & n_sairam == 0 & n_permaneceram == 0 ~ "Sem dado",
          n_entraram > n_sairam & n_entraram > n_permaneceram ~ "Entrou",
          n_sairam > n_entraram & n_sairam > n_permaneceram ~ "Saiu",
          n_permaneceram > 0 & n_permaneceram >= n_entraram & n_permaneceram >= n_sairam ~ "Permaneceu",
          TRUE ~ "Misto"
        )
      )

    bind_rows(lapply(anos_sel, function(ano_atual) {
      mg_municipios_sf |>
        mutate(ano = ano_atual) |>
        left_join(
          resumo |>
            filter(ano == ano_atual) |>
            select(-ano),
          by = "cod_ibge_6"
        ) |>
        mutate(
          municipio = coalesce(municipio, str_to_title(municipio_geo)),
          n_entraram = coalesce(n_entraram, 0L),
          n_sairam = coalesce(n_sairam, 0L),
          n_permaneceram = coalesce(n_permaneceram, 0L),
          n_pares_ativos = coalesce(n_pares_ativos, 0L),
          classe_movimento = coalesce(classe_movimento, "Sem dado"),
          classe_movimento = factor(classe_movimento, levels = names(paleta_mov_mides)),
          tooltip_movimento = paste0(
            municipio,
            " | ano ", ano,
            " | entraram: ", fmt_int(n_entraram),
            " | sairam: ", fmt_int(n_sairam),
            " | permaneceram: ", fmt_int(n_permaneceram)
          )
        )
    }))
  }) |>
    bindCache(
      input$mides_ano,
      input$mides_regra_valor,
      input$mides_municipio,
      input$mides_consorcio,
      input$mides_area,
      input$mides_macrogrupo,
      input$mides_perfil,
      input$mides_busca
    )

  dados_mides_movimento_resumo <- reactive({
    ano_inicial <- min(mides_anual$ano, na.rm = TRUE)

    dados_mides_movimento_mapa() |>
      st_drop_geometry() |>
      summarise(
        municipios_base_inicial = sum(ano == ano_inicial & n_pares_ativos > 0, na.rm = TRUE),
        municipios_com_entrada = sum(ano != ano_inicial & n_entraram > 0, na.rm = TRUE),
        municipios_com_saida = sum(n_sairam > 0, na.rm = TRUE),
        municipios_com_permanencia = sum(n_permaneceram > 0, na.rm = TRUE),
        pares_base_inicial = sum(if_else(ano == ano_inicial, n_pares_ativos, 0L), na.rm = TRUE),
        pares_entraram = sum(if_else(ano != ano_inicial, n_entraram, 0L), na.rm = TRUE),
        pares_sairam = sum(n_sairam, na.rm = TRUE),
        pares_permaneceram = sum(n_permaneceram, na.rm = TRUE),
        municipios_sem_registro = sum(classe_movimento == "Sem dado", na.rm = TRUE),
        .by = ano
      ) |>
      arrange(ano)
  })

  dados_mides_movimento_eventos <- reactive({
    anos_sel <- sort(unique(as.integer(input$mides_ano)))
    if (length(anos_sel) == 0) {
      return(data.frame(
        ano = integer(),
        evento = character(),
        municipio = character(),
        sigla = character(),
        cnpj_consorcio = character(),
        razao_social = character(),
        stringsAsFactors = FALSE
      ))
    }

    anos_mides <- sort(unique(mides_anual$ano))
    anos_sel <- intersect(anos_mides, anos_sel)
    pares <- dados_mides_movimento_base()

    atual <- pares |>
      mutate(presente = TRUE)

    anterior <- pares |>
      transmute(
        ano = ano + 1L,
        cod_ibge_6,
        municipio,
        cnpj_consorcio,
        sigla_anterior = sigla,
        razao_social_anterior = razao_social,
        presente_anterior = TRUE
      )

    full_join(
      atual,
      anterior,
      by = c("ano", "cod_ibge_6", "municipio", "cnpj_consorcio")
    ) |>
      filter(ano %in% anos_sel) |>
      mutate(
        sigla = coalesce(sigla, sigla_anterior),
        razao_social = coalesce(razao_social, razao_social_anterior),
        presente = coalesce(presente, FALSE),
        presente_anterior = coalesce(presente_anterior, FALSE),
        evento = case_when(
          ano == min(anos_mides) & presente ~ "Base inicial",
          presente & !presente_anterior ~ "Entrou",
          !presente & presente_anterior ~ "Saiu",
          TRUE ~ NA_character_
        )
      ) |>
      filter(!is.na(evento)) |>
      transmute(
        ano,
        evento,
        municipio,
        sigla,
        cnpj_consorcio,
        razao_social
      ) |>
      arrange(ano, evento, municipio, sigla)
  }) |>
    bindCache(
      input$mides_ano,
      input$mides_regra_valor,
      input$mides_municipio,
      input$mides_consorcio,
      input$mides_area,
      input$mides_macrogrupo,
      input$mides_perfil,
      input$mides_busca
    )

  dados_fontes_mapa <- reactive({
    resumo <- dados_filtrados() |>
      summarise(
        n_pares = n(),
        n_mides_munic = sum(grupo_vinculo == "MIDES+MUNIC", na.rm = TRUE),
        n_mides_only = sum(grupo_vinculo == "MIDES_only", na.rm = TRUE),
        n_munic_only = sum(grupo_vinculo == "MUNIC_only", na.rm = TRUE),
        n_congruente = sum(classe_validacao == "congruente", na.rm = TRUE),
        n_divergente = sum(classe_validacao == "divergente_valor", na.rm = TRUE),
        n_mides_sem_siconfi = sum(classe_validacao == "mides_sem_siconfi", na.rm = TRUE),
        n_siconfi_sem_mides = sum(classe_validacao == "siconfi_sem_mides", na.rm = TRUE),
        valor_mides = sum(valor_mides_corrente, na.rm = TRUE),
        .by = c(cod_ibge_6, municipio)
      ) |>
      rowwise() |>
      mutate(
        max_grupo = max(c(n_mides_munic, n_mides_only, n_munic_only, 0), na.rm = TRUE),
        n_empates = sum(c(n_mides_munic, n_mides_only, n_munic_only) == max_grupo),
        classe_fontes = case_when(
          n_pares == 0 ~ "Sem par no filtro",
          n_empates > 1 ~ "Misto/empate",
          n_mides_munic == max_grupo ~ "Predominio MIDES+MUNIC",
          n_mides_only == max_grupo ~ "Predominio so MIDES",
          n_munic_only == max_grupo ~ "Predominio so MUNIC",
          TRUE ~ "Misto/empate"
        )
      ) |>
      ungroup()

    mg_municipios_sf |>
      left_join(resumo, by = "cod_ibge_6") |>
      mutate(
        municipio = coalesce(municipio, str_to_title(municipio_geo)),
        n_pares = coalesce(n_pares, 0L),
        n_mides_munic = coalesce(n_mides_munic, 0L),
        n_mides_only = coalesce(n_mides_only, 0L),
        n_munic_only = coalesce(n_munic_only, 0L),
        n_congruente = coalesce(n_congruente, 0L),
        n_divergente = coalesce(n_divergente, 0L),
        n_mides_sem_siconfi = coalesce(n_mides_sem_siconfi, 0L),
        n_siconfi_sem_mides = coalesce(n_siconfi_sem_mides, 0L),
        valor_mides = coalesce(valor_mides, 0),
        classe_fontes = factor(coalesce(classe_fontes, "Sem par no filtro"), levels = names(paleta_fontes)),
        tooltip_fontes = paste0(
          "<strong>", municipio, "</strong>",
          "<br>Pares no filtro: ", fmt_int(n_pares),
          "<br>MIDES+MUNIC: ", fmt_int(n_mides_munic),
          "<br>So MIDES: ", fmt_int(n_mides_only),
          "<br>So MUNIC: ", fmt_int(n_munic_only),
          "<br>SICONFI congruente: ", fmt_int(n_congruente),
          "<br>SICONFI divergente: ", fmt_int(n_divergente),
          "<br>MIDES sem SICONFI: ", fmt_int(n_mides_sem_siconfi),
          "<br>SICONFI sem MIDES: ", fmt_int(n_siconfi_sem_mides),
          "<br>Valor MIDES: ", fmt_moeda(valor_mides)
        )
      )
  }) |>
    bindCache(input$ano, input$grupo, input$classe, input$municipio, input$consorcio, input$busca)

  dados_transicao_mapa <- reactive({
    resumo <- dados_transicao() |>
      summarise(
        n_pares = n(),
        n_permaneceu = sum(status_temporal == "Permaneceu em 2015 e 2019", na.rm = TRUE),
        n_entrou = sum(status_temporal == "Entrou: aparece em 2019, nao em 2015", na.rm = TRUE),
        n_saiu = sum(status_temporal == "Saiu: aparece em 2015, nao em 2019", na.rm = TRUE),
        valor_mides_2015 = sum(mides_2015, na.rm = TRUE),
        valor_mides_2019 = sum(mides_2019, na.rm = TRUE),
        .by = c(cod_ibge_6, municipio)
      ) |>
      rowwise() |>
      mutate(
        max_status = max(c(n_permaneceu, n_entrou, n_saiu, 0), na.rm = TRUE),
        n_empates = sum(c(n_permaneceu, n_entrou, n_saiu) == max_status),
        classe_transicao = case_when(
          n_pares == 0 ~ "Sem par no filtro",
          n_empates > 1 ~ "Misto/empate",
          n_permaneceu == max_status ~ "Permaneceu",
          n_entrou == max_status ~ "Entrou em 2019",
          n_saiu == max_status ~ "Saiu apos 2015",
          TRUE ~ "Misto/empate"
        )
      ) |>
      ungroup()

    mg_municipios_sf |>
      left_join(resumo, by = "cod_ibge_6") |>
      mutate(
        municipio = coalesce(municipio, str_to_title(municipio_geo)),
        n_pares = coalesce(n_pares, 0L),
        n_permaneceu = coalesce(n_permaneceu, 0L),
        n_entrou = coalesce(n_entrou, 0L),
        n_saiu = coalesce(n_saiu, 0L),
        valor_mides_2015 = coalesce(valor_mides_2015, 0),
        valor_mides_2019 = coalesce(valor_mides_2019, 0),
        classe_transicao = factor(coalesce(classe_transicao, "Sem par no filtro"), levels = names(paleta_transicao)),
        tooltip_transicao = paste0(
          "<strong>", municipio, "</strong>",
          "<br>Pares comparados: ", fmt_int(n_pares),
          "<br>Permaneceram: ", fmt_int(n_permaneceu),
          "<br>Entraram em 2019: ", fmt_int(n_entrou),
          "<br>Sairam apos 2015: ", fmt_int(n_saiu),
          "<br>Valor MIDES 2015: ", fmt_moeda(valor_mides_2015),
          "<br>Valor MIDES 2019: ", fmt_moeda(valor_mides_2019)
        )
      )
  }) |>
    bindCache(input$cmp_status, input$cmp_municipio, input$cmp_consorcio, input$cmp_busca)

  dados_mides_mapa_auto <- debounce(dados_mides_mapa, 500)
  dados_fontes_mapa_auto <- debounce(dados_fontes_mapa, 500)
  dados_transicao_mapa_auto <- debounce(dados_transicao_mapa, 500)

  dados_mun_ano <- reactive({
    dados_filtrados() |>
      distinct(
        ano, cod_ibge_6, municipio, classe_validacao,
        valor_mides_corrente_cadastro_1194,
        valor_siconfi_consorcio, diferenca_abs,
        diferenca_abs_modulo, diferenca_rel_pct, passa_tolerancia,
        regra_siconfi
      ) |>
      arrange(ano, municipio)
  })

  output$kpi_pares <- renderText(fmt_int(nrow(dados_filtrados())))
  output$kpi_municipios <- renderText(fmt_int(n_distinct(dados_filtrados()$cod_ibge_6)))
  output$kpi_consorcios <- renderText(fmt_int(n_distinct(dados_filtrados()$cnpj_consorcio)))
  output$kpi_valor <- renderText(fmt_moeda(sum(dados_filtrados()$valor_mides_corrente, na.rm = TRUE)))
  output$kpi_siconfi <- renderText(fmt_moeda(sum(dados_mun_ano()$valor_siconfi_consorcio, na.rm = TRUE)))

  output$kpi_cmp_pares <- renderText(fmt_int(nrow(dados_transicao())))
  output$kpi_cmp_perm <- renderText(fmt_int(sum(dados_transicao()$status_temporal == "Permaneceu em 2015 e 2019", na.rm = TRUE)))
  output$kpi_cmp_entrou <- renderText(fmt_int(sum(dados_transicao()$status_temporal == "Entrou: aparece em 2019, nao em 2015", na.rm = TRUE)))
  output$kpi_cmp_saiu <- renderText(fmt_int(sum(dados_transicao()$status_temporal == "Saiu: aparece em 2015, nao em 2019", na.rm = TRUE)))
  output$kpi_cmp_cons <- renderText(fmt_int(n_distinct(dados_transicao()$cnpj_consorcio)))

  output$kpi_mides_linhas <- renderText(fmt_int(nrow(dados_mides_filtrados())))
  output$kpi_mides_pares <- renderText(fmt_int(n_distinct(paste(dados_mides_filtrados()$cod_ibge_6, dados_mides_filtrados()$cnpj_consorcio))))
  output$kpi_mides_municipios <- renderText(fmt_int(n_distinct(dados_mides_filtrados()$cod_ibge_6)))
  output$kpi_mides_consorcios <- renderText(fmt_int(n_distinct(dados_mides_filtrados()$cnpj_consorcio)))
  output$kpi_mides_valor <- renderText(fmt_moeda(sum(dados_mides_filtrados()$valor_total, na.rm = TRUE)))

  output$mapa_mides <- renderGirafe({
    df <- dados_mides_mapa_auto() |>
      mutate(mapa_valor_plot = if_else(mapa_valor > 0, mapa_valor, NA_real_))
    metrica_atual <- isolate(input$mides_mapa_metrica)
    if (is.null(metrica_atual) || !metrica_atual %in% mides_mapa_metrica_opts) {
      metrica_atual <- "valor_total"
    }
    anos_atual <- isolate(input$mides_ano)
    metrica_nome <- names(mides_mapa_metrica_opts)[match(metrica_atual, mides_mapa_metrica_opts)]
    anos_txt <- paste(sort(unique(anos_atual)), collapse = ", ")
    if (anos_txt == "") anos_txt <- "sem anos selecionados"

    p <- ggplot(df) +
      geom_sf(
        aes(fill = mapa_valor_plot),
        colour = "#4c554b",
        linewidth = 0.12,
        lineend = "butt",
        linejoin = "round"
      ) +
      geom_sf_interactive(
        aes(
          tooltip = tooltip_mides,
          data_id = cod_ibge_6
        ),
        fill = "#ffffff",
        alpha = 0.001,
        colour = NA,
        linewidth = 0
      ) +
      geom_sf(
        data = mg_contorno_sf,
        inherit.aes = FALSE,
        fill = NA,
        colour = "#2f2f2f",
        linewidth = 0.30,
        lineend = "round",
        linejoin = "round"
      ) +
      scale_fill_gradientn(
        colours = c("#f7fcf5", "#c7e9c0", "#74c476", "#238b45", "#00441b"),
        trans = "log10",
        na.value = "#ffffff",
        labels = function(x) fmt_mapa_valor(x, metrica_atual),
        name = metrica_nome
      ) +
      labs(
        title = "MIDES: intensidade municipal",
        subtitle = paste0("Escala logaritmica | anos: ", anos_txt),
        caption = "Fonte: MIDES processado no projeto ideiaMides | geometria municipal geobr/IBGE 2020"
      ) +
      coord_sf(datum = NA) +
      theme_mapa_limpo()

    girafe(
      ggobj = p,
      width_svg = 10.8,
      height_svg = 6.6,
      options = list(
        opts_hover(css = "stroke:#1b1b1b;stroke-width:0.30px;"),
        opts_selection(type = "single", css = "stroke:#1b1b1b;stroke-width:0.42px;"),
        opts_tooltip(css = "background:#222;color:#fff;padding:8px 10px;border-radius:3px;font-family:Arial;font-size:12px;line-height:1.35;"),
        opts_sizing(rescale = TRUE)
      )
    )
  })

  output$mapa_mides_movimento <- renderGirafe({
    df <- dados_mides_movimento_mapa()
    validate(need(nrow(df) > 0, "Selecione ao menos um ano MIDES."))

    p <- ggplot(df) +
      geom_sf(
        aes(fill = classe_movimento),
        colour = "#4d4d4d",
        linewidth = 0.075,
        lineend = "round",
        linejoin = "round"
      ) +
      geom_sf(
        data = mg_contorno_sf,
        inherit.aes = FALSE,
        fill = NA,
        colour = "#202020",
        linewidth = 0.28,
        lineend = "round",
        linejoin = "round"
      ) +
      scale_fill_manual(values = paleta_mov_mides, drop = TRUE, name = NULL) +
      facet_wrap(~ano, ncol = 4) +
      labs(
        title = "MIDES: entradas e saidas anuais",
        subtitle = "Cada painel compara pares municipio-consorcio contra o ano anterior",
        caption = "Fonte: MIDES processado no projeto ideiaMides | unidade de movimento: par municipio-consorcio"
      ) +
      coord_sf(datum = NA, expand = FALSE) +
      theme_mapa_limpo() +
      theme(
        legend.position = "bottom",
        legend.box = "horizontal",
        legend.key.width = unit(22, "pt"),
        legend.key.height = unit(14, "pt"),
        legend.text = element_text(size = 9, colour = "#303030"),
        strip.background = element_rect(fill = "#ffffff", colour = "#c8c8c8", linewidth = 0.35),
        strip.text = element_text(face = "bold", size = 11, colour = "#303030"),
        panel.spacing = unit(6, "pt")
      ) +
      guides(fill = guide_legend(nrow = 1, byrow = TRUE))

    girafe(
      ggobj = p,
      width_svg = 13.8,
      height_svg = 8.6,
      options = list(
        opts_toolbar(position = "topright", saveaspng = TRUE, pngname = "mides_movimento_anual"),
        opts_zoom(min = 1, max = 5, duration = 250, default_on = FALSE),
        opts_sizing(rescale = TRUE)
      )
    )
  })

  output$mapa_fontes <- renderGirafe({
    df <- dados_fontes_mapa_auto()

    p <- ggplot(df) +
      geom_sf(
        aes(fill = classe_fontes),
        colour = "#3f3f3f",
        linewidth = 0.16,
        lineend = "butt",
        linejoin = "round"
      ) +
      geom_sf_interactive(
        aes(
          tooltip = tooltip_fontes,
          data_id = cod_ibge_6
        ),
        fill = "#ffffff",
        alpha = 0.001,
        colour = NA,
        linewidth = 0
      ) +
      geom_sf(
        data = mg_contorno_sf,
        inherit.aes = FALSE,
        fill = NA,
        colour = "#1f1f1f",
        linewidth = 0.35,
        lineend = "round",
        linejoin = "round"
      ) +
      scale_fill_manual(values = paleta_fontes, drop = FALSE, name = "Predominio") +
      labs(
        title = "Recorte 2015/2019: composicao territorial das fontes",
        subtitle = "Cor por predominio de MIDES+MUNIC, so MIDES ou so MUNIC nos pares filtrados",
        caption = "Fonte: Base 1 2015/2019 | SICONFI entra apenas como validacao municipio-ano"
      ) +
      coord_sf(datum = NA) +
      theme_mapa_limpo()

    girafe(
      ggobj = p,
      width_svg = 10.8,
      height_svg = 6.6,
      options = list(
        opts_hover(css = "stroke:#1b1b1b;stroke-width:0.30px;"),
        opts_selection(type = "single", css = "stroke:#1b1b1b;stroke-width:0.42px;"),
        opts_tooltip(css = "background:#222;color:#fff;padding:8px 10px;border-radius:3px;font-family:Arial;font-size:12px;line-height:1.35;"),
        opts_sizing(rescale = TRUE)
      )
    )
  })

  output$mapa_transicao <- renderGirafe({
    df <- dados_transicao_mapa_auto()

    p <- ggplot(df) +
      geom_sf(
        aes(fill = classe_transicao),
        colour = "#3f3f3f",
        linewidth = 0.16,
        lineend = "butt",
        linejoin = "round"
      ) +
      geom_sf_interactive(
        aes(
          tooltip = tooltip_transicao,
          data_id = cod_ibge_6
        ),
        fill = "#ffffff",
        alpha = 0.001,
        colour = NA,
        linewidth = 0
      ) +
      geom_sf(
        data = mg_contorno_sf,
        inherit.aes = FALSE,
        fill = NA,
        colour = "#1f1f1f",
        linewidth = 0.35,
        lineend = "round",
        linejoin = "round"
      ) +
      scale_fill_manual(values = paleta_transicao, drop = FALSE, name = "Movimento") +
      labs(
        title = "Transicao territorial dos pares entre 2015 e 2019",
        subtitle = "Cor por movimento predominante no municipio, considerando os pares filtrados",
        caption = "Fonte: Base 1 2015/2019"
      ) +
      coord_sf(datum = NA) +
      theme_mapa_limpo()

    girafe(
      ggobj = p,
      width_svg = 10.8,
      height_svg = 6.6,
      options = list(
        opts_hover(css = "stroke:#1b1b1b;stroke-width:0.30px;"),
        opts_selection(type = "single", css = "stroke:#1b1b1b;stroke-width:0.42px;"),
        opts_tooltip(css = "background:#222;color:#fff;padding:8px 10px;border-radius:3px;font-family:Arial;font-size:12px;line-height:1.35;"),
        opts_sizing(rescale = TRUE)
      )
    )
  })
  output$tabela_conjuntos <- renderDT({
    df <- dados_filtrados() |>
      summarise(
        pares = n(),
        municipios = n_distinct(cod_ibge_6),
        consorcios = n_distinct(cnpj_consorcio),
        valor_mides_corrente = sum(valor_mides_corrente, na.rm = TRUE),
        .by = grupo_rotulo
      ) |>
      arrange(match(grupo_rotulo, unname(names(grupos_labels)))) |>
      rename(conjunto = grupo_rotulo)

    datatable(
      df,
      rownames = FALSE,
      options = list(
        dom = "t",
        pageLength = nrow(df),
        ordering = FALSE
      )
    ) |>
      formatCurrency(
        columns = "valor_mides_corrente",
        currency = "R$ ",
        mark = ".",
        dec.mark = ",",
        digits = 0
      )
  })

  output$tabela <- renderDT({
    df <- dados_filtrados() |>
      transmute(
        ano,
        cod_ibge_6,
        municipio,
        sigla,
        cnpj_consorcio,
        razao_social,
        conjunto_mides_munic = grupo_rotulo,
        tem_mides = tem_mides_txt,
        tem_munic = tem_munic_txt,
        validacao_siconfi = classe_rotulo,
        valor_mides_corrente = round(valor_mides_corrente, 2),
        valor_mides_total = round(valor_mides_total, 2),
        valor_siconfi_mun_ano = round(valor_siconfi_consorcio, 2),
        diferenca_mun_ano = round(diferenca_abs, 2),
        diferenca_rel_pct,
        setores = setores_consolidado
      )

    datatable(
      df,
      rownames = FALSE,
      extensions = "Buttons",
      filter = "top",
      options = list(
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel"),
        pageLength = 20,
        scrollX = TRUE,
        deferRender = TRUE,
        searchDelay = 450,
        language = dt_pt
      )
    ) |>
      formatCurrency(
        columns = c("valor_mides_corrente", "valor_mides_total", "valor_siconfi_mun_ano", "diferenca_mun_ano"),
        currency = "R$ ",
        mark = ".",
        dec.mark = ",",
        digits = 0
      )
  }, server = TRUE)

  output$tabela_transicao <- renderDT({
    df <- dados_transicao() |>
      transmute(
        status_2015_2019 = status_temporal,
        municipio,
        cod_ibge_6,
        sigla,
        cnpj_consorcio,
        razao_social,
        aparece_2015 = if_else(apareceu_2015, "Sim", "Nao"),
        aparece_2019 = if_else(apareceu_2019, "Sim", "Nao"),
        conjunto_2015 = grupo_2015,
        conjunto_2019 = grupo_2019,
        valor_mides_2015 = round(mides_2015, 2),
        valor_mides_2019 = round(mides_2019, 2),
        siconfi_mun_ano_2015 = round(siconfi_2015, 2),
        siconfi_mun_ano_2019 = round(siconfi_2019, 2),
        validacao_2015 = classe_2015,
        validacao_2019 = classe_2019
      )

    datatable(
      df,
      rownames = FALSE,
      extensions = "Buttons",
      filter = "top",
      options = list(
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel"),
        pageLength = 20,
        scrollX = TRUE,
        deferRender = TRUE,
        searchDelay = 450,
        language = dt_pt
      )
    ) |>
      formatCurrency(
        columns = c("valor_mides_2015", "valor_mides_2019", "siconfi_mun_ano_2015", "siconfi_mun_ano_2019"),
        currency = "R$ ",
        mark = ".",
        dec.mark = ",",
        digits = 0
      )
  }, server = TRUE)

  output$tabela_mides_ano <- renderDT({
    df <- dados_mides_filtrados() |>
      summarise(
        linhas_anuais = n(),
        pares_unicos = n_distinct(paste(cod_ibge_6, cnpj_consorcio)),
        municipios = n_distinct(cod_ibge_6),
        consorcios = n_distinct(cnpj_consorcio),
        valor_corrente = sum(valor_corrente, na.rm = TRUE),
        valor_restos = sum(valor_restos, na.rm = TRUE),
        valor_total = sum(valor_total, na.rm = TRUE),
        transacoes = sum(n_transacoes, na.rm = TRUE),
        .by = ano
      ) |>
      arrange(ano)

    datatable(
      df,
      rownames = FALSE,
      extensions = "Buttons",
      options = list(
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel"),
        pageLength = 10,
        scrollX = TRUE,
        deferRender = TRUE,
        searchDelay = 450,
        language = dt_pt
      )
    ) |>
      formatCurrency(
        columns = c("valor_corrente", "valor_restos", "valor_total"),
        currency = "R$ ",
        mark = ".",
        dec.mark = ",",
        digits = 0
      )
  }, server = TRUE)

  output$tabela_mides_mapa_top <- renderDT({
    df <- dados_mides_mapa() |>
      st_drop_geometry() |>
      filter(tem_registro) |>
      arrange(desc(mapa_valor)) |>
      slice_head(n = 15) |>
      transmute(
        municipio,
        cod_ibge_6,
        valor_total = round(valor_total, 2),
        valor_corrente = round(valor_corrente, 2),
        valor_restos = round(valor_restos, 2),
        n_consorcios,
        n_transacoes,
        principais_consorcios
      )

    datatable(
      df,
      rownames = FALSE,
      options = list(
        dom = "t",
        pageLength = 15,
        scrollX = TRUE,
        ordering = FALSE,
        deferRender = TRUE,
        searchDelay = 450,
        language = dt_pt
      )
    ) |>
      formatCurrency(
        columns = c("valor_total", "valor_corrente", "valor_restos"),
        currency = "R$ ",
        mark = ".",
        dec.mark = ",",
        digits = 0
      )
  }, server = TRUE)

  output$bloco_mides_movimento <- renderUI({
    n_consorcios <- length(input$mides_consorcio)

    if (n_consorcios >= 1 && n_consorcios < 5) {
      tagList(
        h3("Detalhe anual do movimento"),
        div(class = "map-note", "Tabela habilitada porque ha menos de 5 consorcios selecionados. Clique no + para ver municipios que entraram ou sairam em cada ano."),
        DTOutput("tabela_mides_movimento")
      )
    } else {
      div(
        class = "map-note",
        tags$strong("Detalhe por municipio oculto."),
        " Selecione de 1 a 4 consorcios no filtro MIDES para abrir a tabela com os municipios que entraram ou sairam."
      )
    }
  })

  output$tabela_mides_movimento <- renderDT({
    eventos <- dados_mides_movimento_eventos()
    html_eventos <- function(ano_atual) {
      eventos_ano <- eventos |> filter(ano == ano_atual)

      montar_lista <- function(tipo) {
        itens <- eventos_ano |>
          filter(evento == tipo) |>
          transmute(txt = paste0(municipio, " - ", sigla, " (", cnpj_consorcio, ")")) |>
          distinct(txt) |>
          arrange(txt) |>
          pull(txt)

        if (length(itens) == 0) {
          return("<span>Nenhum registro.</span>")
        }

        limite <- 80
        itens_html <- paste0("<li>", htmltools::htmlEscape(head(itens, limite)), "</li>", collapse = "")
        complemento <- if (length(itens) > limite) {
          paste0("<div>", fmt_int(length(itens) - limite), " registros adicionais omitidos.</div>")
        } else {
          ""
        }
        paste0("<ul>", itens_html, "</ul>", complemento)
      }

      paste0(
        "<div class='dt-detail-box'>",
        "<strong>Base inicial</strong>", montar_lista("Base inicial"),
        "<strong>Entraram</strong>", montar_lista("Entrou"),
        "<strong>Sairam</strong>", montar_lista("Saiu"),
        "</div>"
      )
    }

    df <- dados_mides_movimento_resumo() |>
      transmute(
        ` ` = "",
        ano,
        mun_inicio = municipios_base_inicial,
        mun_entraram = municipios_com_entrada,
        mun_sairam = municipios_com_saida,
        mun_permaneceram = municipios_com_permanencia,
        pares_inicio = pares_base_inicial,
        pares_entraram,
        pares_sairam,
        pares_permaneceram,
        detalhes = vapply(ano, html_eventos, character(1))
      )

    coluna_detalhes <- ncol(df) - 1

    datatable(
      df,
      rownames = FALSE,
      escape = FALSE,
      options = list(
        dom = "t",
        pageLength = nrow(df),
        ordering = FALSE,
        deferRender = TRUE,
        columnDefs = list(
          list(className = "details-control", orderable = FALSE, targets = 0),
          list(visible = FALSE, targets = coluna_detalhes)
        ),
        language = dt_pt
      ),
      callback = JS(sprintf(
        "table.on('click', 'td.details-control', function() {
          var tr = $(this).closest('tr');
          var row = table.row(tr);
          if (row.child.isShown()) {
            row.child.hide();
            tr.removeClass('shown');
          } else {
            row.child(row.data()[%d]).show();
            tr.addClass('shown');
          }
        });",
        coluna_detalhes
      ))
    )
  }, server = TRUE)

  output$tabela_mides <- renderDT({
    df <- dados_mides_filtrados() |>
      transmute(
        ano,
        cod_ibge_6,
        municipio,
        sigla,
        cnpj_consorcio,
        razao_social,
        area_politica = formatar_categorias(area_politica, rotulos_area),
        macrogrupo_politica = formatar_categorias(macrogrupo_politica, rotulos_macrogrupo),
        perfil_institucional = coalesce(unname(rotulos_perfil[perfil_classificacao]), "Nao informado"),
        cobertura_classificacao,
        valor_corrente = round(valor_corrente, 2),
        valor_restos = round(valor_restos, 2),
        valor_total = round(valor_total, 2),
        n_transacoes,
        tem_pagamento_corrente = if_else(tem_pagamento_corrente, "Sim", "Nao"),
        tipo_valor,
        setores,
        situacao,
        nome_mides = nome_credor_freq
      ) |>
      arrange(desc(ano), municipio, sigla)

    datatable(
      df,
      rownames = FALSE,
      extensions = "Buttons",
      filter = "top",
      options = list(
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel"),
        pageLength = 20,
        scrollX = TRUE,
        deferRender = TRUE,
        searchDelay = 450,
        language = dt_pt
      )
    ) |>
      formatCurrency(
        columns = c("valor_corrente", "valor_restos", "valor_total"),
        currency = "R$ ",
        mark = ".",
        dec.mark = ",",
        digits = 0
      )
  }, server = TRUE)

  output$tabela_auditoria_nome <- renderDT({
    df <- auditoria_nome |>
      transmute(
        nome_juridico = nome_norm,
        n_cnpjs,
        cnpjs,
        siglas,
        situacoes,
        anos_fundacao
      )

    datatable(
      df,
      rownames = FALSE,
      extensions = "Buttons",
      filter = "top",
      options = list(
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel"),
        pageLength = 10,
        scrollX = TRUE,
        deferRender = TRUE,
        searchDelay = 450,
        language = dt_pt
      )
    )
  }, server = TRUE)

  output$tabela_auditoria_cnpj_raiz <- renderDT({
    df <- auditoria_cnpj_raiz |>
      transmute(
        cnpj_raiz_8,
        n_cnpjs,
        n_matrizes,
        n_filiais,
        cnpj_matriz,
        cnpjs_filiais,
        cnpjs,
        prefixos_10,
        nomes_juridicos,
        siglas,
        situacoes,
        anos_fundacao,
        presente_base1 = if_else(presente_base1, "Sim", "Nao"),
        anos_base1,
        linhas_base1,
        pares_base1,
        municipios_base1,
        valor_mides_base1 = round(valor_mides_base1, 2),
        regra_sugerida
      )

    datatable(
      df,
      rownames = FALSE,
      extensions = "Buttons",
      filter = "top",
      options = list(
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel"),
        pageLength = 10,
        scrollX = TRUE,
        deferRender = TRUE,
        searchDelay = 450,
        language = dt_pt
      )
    ) |>
      formatCurrency(
        columns = "valor_mides_base1",
        currency = "R$ ",
        mark = ".",
        dec.mark = ",",
        digits = 0
      )
  }, server = TRUE)

  output$tabela_auditoria_mun_ano <- renderDT({
    df <- auditoria_mun_ano |>
      transmute(
        ano,
        municipio,
        cod_ibge_6,
        nome_juridico = nome_norm,
        n_cnpjs,
        cnpjs,
        siglas,
        grupos,
        valor_mides = round(valor_mides, 2)
      )

    datatable(
      df,
      rownames = FALSE,
      extensions = "Buttons",
      filter = "top",
      options = list(
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel"),
        pageLength = 10,
        scrollX = TRUE,
        deferRender = TRUE,
        searchDelay = 450,
        language = dt_pt
      )
    ) |>
      formatCurrency(
        columns = "valor_mides",
        currency = "R$ ",
        mark = ".",
        dec.mark = ",",
      digits = 0
      )
  }, server = TRUE)

  output$tabela_auditoria_municipio <- renderDT({
    df <- auditoria_municipio |>
      transmute(
        municipio,
        cod_ibge_6,
        n_cnpjs,
        n_siglas,
        cnpjs,
        siglas,
        anos,
        setores,
        razoes
      )

    datatable(
      df,
      rownames = FALSE,
      extensions = "Buttons",
      filter = "top",
      options = list(
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel"),
        pageLength = 10,
        scrollX = TRUE,
        deferRender = TRUE,
        searchDelay = 450,
        language = dt_pt
      )
    )
  }, server = TRUE)

  output$tabela_auditoria_pares_parecidos <- renderDT({
    df <- auditoria_pares_parecidos |>
      transmute(
        ano,
        municipio,
        cod_ibge_6,
        tipo_alerta,
        termos_comuns,
        sigla_a,
        cnpj_a = cnpj_consorcio_a,
        razao_social_a,
        conjunto_a = grupo_rotulo_a,
        valor_mides_a = round(valor_mides_corrente_a, 2),
        sigla_b,
        cnpj_b = cnpj_consorcio_b,
        razao_social_b,
        conjunto_b = grupo_rotulo_b,
        valor_mides_b = round(valor_mides_corrente_b, 2)
      )

    datatable(
      df,
      rownames = FALSE,
      extensions = "Buttons",
      filter = "top",
      options = list(
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel"),
        pageLength = 15,
        scrollX = TRUE,
        deferRender = TRUE,
        searchDelay = 450,
        language = dt_pt
      )
    ) |>
      formatCurrency(
        columns = c("valor_mides_a", "valor_mides_b"),
        currency = "R$ ",
        mark = ".",
        dec.mark = ",",
        digits = 0
      )
  }, server = TRUE)

  output$tabela_mun_ano <- renderDT({
    df <- dados_mun_ano() |>
      transmute(
        ano,
        cod_ibge_6,
        municipio,
        classe_siconfi = as.character(classe_validacao),
        valor_mides_mun_ano = round(valor_mides_corrente_cadastro_1194, 2),
        valor_siconfi_mun_ano = round(valor_siconfi_consorcio, 2),
        diferenca = round(diferenca_abs, 2),
        diferenca_abs = round(diferenca_abs_modulo, 2),
        diferenca_rel_pct,
        passa_tolerancia,
        regra_siconfi
      )

    datatable(
      df,
      rownames = FALSE,
      extensions = "Buttons",
      filter = "top",
      options = list(
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel"),
        pageLength = 20,
        scrollX = TRUE,
        deferRender = TRUE,
        searchDelay = 450,
        language = dt_pt
      )
    ) |>
      formatCurrency(
        columns = c("valor_mides_mun_ano", "valor_siconfi_mun_ano", "diferenca", "diferenca_abs"),
        currency = "R$ ",
        mark = ".",
        dec.mark = ",",
        digits = 0
      )
  }, server = TRUE)

  output$tabela_definicoes <- renderDT({
    datatable(
      definicoes,
      rownames = FALSE,
      options = list(
        dom = "t",
        pageLength = nrow(definicoes),
        ordering = FALSE
      ),
      colnames = c("Item", "Definicao")
    )
  })
}

shinyApp(ui, server)



