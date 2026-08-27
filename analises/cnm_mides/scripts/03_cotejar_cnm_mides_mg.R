suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
  library(sf)
  library(stringr)
  library(tidyr)
})

script_path <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
analysis_dir <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
project_dir <- normalizePath(file.path(analysis_dir, "..", ".."), winslash = "/", mustWork = TRUE)
output_dir <- file.path(analysis_dir, "outputs")
check_dir <- file.path(analysis_dir, "checks")
figure_dir <- file.path(check_dir, "figures")
export_root <- Sys.getenv("CNM_ANALYSIS_EXPORT_ROOT", unset = "")
if (nzchar(export_root)) {
  output_dir <- file.path(export_root, "outputs")
  check_dir <- file.path(export_root, "checks")
  figure_dir <- file.path(check_dir, "figures")
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

snapshot_dir <- "C:/IPEA/dados cnm/snapshots/2026-08-27/data"
base_nacional <- file.path(project_dir, "analises", "base_nacional", "outputs")
app_data <- file.path(project_dir, "dashboards", "base1_shiny", "data")

write_csv_semicolon <- function(x, path) {
  write.table(
    x, file = path, sep = ";", dec = ",", quote = TRUE,
    row.names = FALSE, col.names = TRUE, na = "", fileEncoding = "UTF-8"
  )
}

digits <- function(x) str_replace_all(coalesce(as.character(x), ""), "[^0-9]", "")
cod6 <- function(x) str_sub(digits(x), 1, 6)

crosswalk <- readRDS(file.path(output_dir, "crosswalk_cnm_ipea_cnpj.rds"))
links <- read_delim(file.path(snapshot_dir, "municipio_consorcio.csv"), delim = ";", show_col_types = FALSE)
mides <- readRDS(file.path(base_nacional, "painel_mides_nacional_raiz_ano.rds"))
lookup <- readRDS(file.path(app_data, "mides_municipios_lookup.rds"))

cnm_mg_raw <- links |>
  filter(municipio_uf == "MG") |>
  transmute(
    cnm_uuid = consorcio_uuid,
    cod_ibge_6 = cod6(municipio_ibge),
    municipio_cnm = municipio_nome,
    cnpj_cnm_ficha = NA_character_,
    nome_cnm_vinculo = consorcio_nome,
    sigla_cnm_vinculo = consorcio_sigla
  ) |>
  left_join(crosswalk, by = "cnm_uuid") |>
  mutate(
    cnpj_cnm_ficha = cnm_cnpj_original,
    nome_cnm = cnm_nome,
    sigla_cnm = cnm_sigla,
    identidade_valida = identidade_validada_automaticamente
  )

cnm_mg <- cnm_mg_raw |>
  distinct(cnm_uuid, cod_ibge_6, .keep_all = TRUE)

mides_mg <- mides |>
  filter(uf_municipio_pagador == "MG", valor_total > 0) |>
  mutate(cod_ibge_6 = cod6(id_municipio)) |>
  group_by(cod_ibge_6, cnpj_raiz_8, ano) |>
  summarise(
    cnpj_canonico_mides = first(cnpj_canonico),
    nome_ipea_mides = first(razao_social_canonica),
    sigla_ipea_mides = first(sigla_canonica),
    valor_total_mides = sum(valor_total, na.rm = TRUE),
    n_transacoes_mides = sum(n_transacoes, na.rm = TRUE),
    .groups = "drop"
  )

anos_mg <- sort(unique(mides_mg$ano))
cnm_matched <- cnm_mg |>
  filter(identidade_valida) |>
  transmute(
    cnm_uuid, cod_ibge_6, cnpj_raiz_8 = cnm_cnpj_raiz_8,
    cnpj_original_cnm = cnm_cnpj_original,
    cnpj_canonico_cnm = cnpj_canonico,
    nome_cnm, sigla_cnm,
    situacao_pareamento
  ) |>
  distinct(cod_ibge_6, cnpj_raiz_8, .keep_all = TRUE)

cnm_expanded <- crossing(cnm_matched, ano = anos_mg) |>
  mutate(presente_snapshot_cnm = TRUE)

annual_matched <- full_join(cnm_expanded, mides_mg, by = c("cod_ibge_6", "cnpj_raiz_8", "ano")) |>
  mutate(
    presente_snapshot_cnm = coalesce(presente_snapshot_cnm, FALSE),
    presente_mides = coalesce(valor_total_mides, 0) > 0,
    situacao_fonte = case_when(
      presente_snapshot_cnm & presente_mides ~ "CNM + MIDES",
      presente_snapshot_cnm & !presente_mides ~ "Somente CNM",
      !presente_snapshot_cnm & presente_mides ~ "Somente MIDES",
      TRUE ~ "Sem evidencia"
    ),
    consorcio_chave = cnpj_raiz_8,
    nome_consorcio = coalesce(nome_cnm, nome_ipea_mides),
    sigla_consorcio = coalesce(sigla_cnm, sigla_ipea_mides),
    valor_total_mides = coalesce(valor_total_mides, 0),
    n_transacoes_mides = coalesce(n_transacoes_mides, 0)
  )

annual_unmatched <- cnm_mg |>
  filter(!identidade_valida) |>
  transmute(
    cnm_uuid, cod_ibge_6,
    cnpj_raiz_8 = cnm_cnpj_raiz_8,
    cnpj_original_cnm = cnm_cnpj_original,
    cnpj_canonico_cnm = NA_character_,
    nome_cnm, sigla_cnm,
    situacao_pareamento,
    consorcio_chave = paste0("CNM:", cnm_uuid),
    nome_consorcio = nome_cnm,
    sigla_consorcio = sigla_cnm
  ) |>
  crossing(ano = anos_mg) |>
  mutate(
    presente_snapshot_cnm = TRUE,
    presente_mides = FALSE,
    situacao_fonte = "Nao pareado",
    valor_total_mides = 0,
    n_transacoes_mides = 0
  )

lookup6 <- lookup |>
  transmute(cod_ibge_6 = as.character(cod_ibge_6), municipio = municipio) |>
  distinct(cod_ibge_6, .keep_all = TRUE)

annual <- bind_rows(
  annual_matched |>
    select(cnm_uuid, cod_ibge_6, cnpj_raiz_8, cnpj_original_cnm, cnpj_canonico_cnm,
           nome_cnm, sigla_cnm, situacao_pareamento, consorcio_chave, nome_consorcio,
           sigla_consorcio, ano, presente_snapshot_cnm, presente_mides, situacao_fonte,
           valor_total_mides, n_transacoes_mides),
  annual_unmatched |>
    select(cnm_uuid, cod_ibge_6, cnpj_raiz_8, cnpj_original_cnm, cnpj_canonico_cnm,
           nome_cnm, sigla_cnm, situacao_pareamento, consorcio_chave, nome_consorcio,
           sigla_consorcio, ano, presente_snapshot_cnm, presente_mides, situacao_fonte,
           valor_total_mides, n_transacoes_mides)
) |>
  left_join(lookup6, by = "cod_ibge_6") |>
  mutate(snapshot_cnm_referencia = as.Date("2026-08-27")) |>
  arrange(ano, municipio, nome_consorcio)

pair_summary <- annual |>
  group_by(cod_ibge_6, municipio, consorcio_chave) |>
  summarise(
    cnm_uuid = first(na.omit(cnm_uuid), default = NA_character_),
    cnpj_raiz_8 = first(na.omit(cnpj_raiz_8), default = NA_character_),
    cnpj_original_cnm = first(na.omit(cnpj_original_cnm), default = NA_character_),
    cnpj_canonico = first(na.omit(cnpj_canonico_cnm), default = NA_character_),
    nome_consorcio = first(na.omit(nome_consorcio), default = NA_character_),
    sigla_consorcio = first(na.omit(sigla_consorcio), default = NA_character_),
    situacao_pareamento = first(na.omit(situacao_pareamento), default = "somente_mides"),
    presente_snapshot_cnm = any(presente_snapshot_cnm),
    teve_mides_periodo = any(presente_mides),
    anos_mides = paste(ano[presente_mides], collapse = ";"),
    valor_total_mides_periodo = sum(valor_total_mides),
    situacao_periodo = case_when(
      presente_snapshot_cnm & teve_mides_periodo & situacao_pareamento %in% c("exato_cnpj", "raiz_cnpj") ~ "CNM + MIDES",
      presente_snapshot_cnm & situacao_pareamento %in% c("provavel_nome_revisar", "nao_encontrado") ~ "Nao pareado",
      presente_snapshot_cnm & !teve_mides_periodo ~ "Somente CNM",
      !presente_snapshot_cnm & teve_mides_periodo ~ "Somente MIDES",
      TRUE ~ "Sem evidencia"
    ),
    .groups = "drop"
  )

consortium_summary <- pair_summary |>
  group_by(consorcio_chave) |>
  summarise(
    nome_consorcio = first(na.omit(nome_consorcio[presente_snapshot_cnm]), default = first(na.omit(nome_consorcio), default = NA_character_)),
    sigla_consorcio = first(na.omit(sigla_consorcio[presente_snapshot_cnm]), default = first(na.omit(sigla_consorcio), default = NA_character_)),
    municipios_cnm_atual = n_distinct(cod_ibge_6[presente_snapshot_cnm]),
    municipios_mides_periodo = n_distinct(cod_ibge_6[teve_mides_periodo]),
    pares_cnm_mides = sum(situacao_periodo == "CNM + MIDES"),
    pares_somente_cnm = sum(situacao_periodo == "Somente CNM"),
    pares_somente_mides = sum(situacao_periodo == "Somente MIDES"),
    pares_nao_pareados = sum(situacao_periodo == "Nao pareado"),
    valor_total_mides_periodo = sum(valor_total_mides_periodo),
    .groups = "drop"
  ) |>
  arrange(desc(pares_cnm_mides), desc(valor_total_mides_periodo))

timeline <- annual |>
  count(ano, situacao_fonte, name = "pares") |>
  arrange(ano, situacao_fonte)

municipality_map <- pair_summary |>
  count(cod_ibge_6, situacao_periodo, name = "pares") |>
  pivot_wider(names_from = situacao_periodo, values_from = pares, values_fill = 0) |>
  mutate(total_pares = `CNM + MIDES` + `Somente CNM` + `Somente MIDES` + `Nao pareado`) |>
  rowwise() |>
  mutate(
    maior_contagem = max(c(`CNM + MIDES`, `Somente CNM`, `Somente MIDES`, `Nao pareado`)),
    n_maximos = sum(c(`CNM + MIDES`, `Somente CNM`, `Somente MIDES`, `Nao pareado`) == maior_contagem),
    situacao_mapa = case_when(
      n_maximos > 1 ~ "Empate",
      `CNM + MIDES` == maior_contagem ~ "Predominio CNM + MIDES",
      `Somente CNM` == maior_contagem ~ "Predominio somente CNM",
      `Somente MIDES` == maior_contagem ~ "Predominio somente MIDES",
      TRUE ~ "Predominio nao pareado"
    )
  ) |>
  ungroup()

mg_sf <- readRDS(file.path(app_data, "mg_municipios_sf_web.rds")) |>
  left_join(municipality_map, by = "cod_ibge_6") |>
  mutate(situacao_mapa = coalesce(situacao_mapa, "Sem evidencia no recorte"))

palette <- c(
  "Predominio CNM + MIDES" = "#216E5B",
  "Predominio somente CNM" = "#E0A12E",
  "Predominio somente MIDES" = "#3C78A8",
  "Predominio nao pareado" = "#B45F5F",
  "Empate" = "#8A8F93",
  "Sem evidencia no recorte" = "#F2F3F2"
)

map_plot <- ggplot(mg_sf) +
  geom_sf(aes(fill = situacao_mapa), color = "#FFFFFF", linewidth = 0.08) +
  geom_sf(data = st_union(mg_sf), fill = NA, color = "#173B52", linewidth = 0.45) +
  scale_fill_manual(values = palette, breaks = names(palette), drop = FALSE) +
  coord_sf(datum = NA) +
  labs(
    title = "CNM atual e pagamentos MIDES em Minas Gerais",
    subtitle = paste0("CNM: fotografia de 27/08/2026 | MIDES: ", min(anos_mg), " - ", max(anos_mg)),
    fill = "Situacao predominante",
    caption = "CNM indica cadastro atual; MIDES indica pagamento anual observado. Nenhuma fonte prova, isoladamente, filiacao juridica historica."
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    plot.title = element_text(face = "bold", color = "#173B52", size = 18),
    plot.subtitle = element_text(color = "#48677A", size = 11),
    plot.caption = element_text(color = "#48677A", hjust = 0, size = 8.5),
    legend.position = "right",
    legend.title = element_text(face = "bold")
  )

timeline_plot <- timeline |>
  filter(situacao_fonte != "Sem evidencia") |>
  ggplot(aes(x = factor(ano), y = pares, fill = situacao_fonte)) +
  geom_col(position = "stack", width = 0.72) +
  scale_fill_manual(values = c("CNM + MIDES" = "#216E5B", "Somente CNM" = "#E0A12E", "Somente MIDES" = "#3C78A8", "Nao pareado" = "#B45F5F")) +
  scale_y_continuous(labels = label_number(big.mark = "."), expand = expansion(mult = c(0, .08))) +
  labs(
    title = "Cotejamento anual: fotografia CNM contra pagamentos MIDES",
    subtitle = "A marca CNM permanece fixa; o pagamento MIDES varia por ano",
    x = NULL, y = "Pares municipio–consorcio", fill = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
    plot.title = element_text(face = "bold", color = "#173B52"),
    legend.position = "bottom"
  )

write_csv_semicolon(annual, file.path(output_dir, "cnm_mides_mg_municipio_consorcio_ano.csv"))
write_csv_semicolon(pair_summary, file.path(output_dir, "cnm_mides_mg_pares_periodo.csv"))
write_csv_semicolon(consortium_summary, file.path(output_dir, "cnm_mides_mg_resumo_consorcio.csv"))
write_csv_semicolon(timeline, file.path(output_dir, "cnm_mides_mg_linha_tempo.csv"))
saveRDS(annual, file.path(output_dir, "cnm_mides_mg_municipio_consorcio_ano.rds"), compress = "xz")
ggsave(file.path(figure_dir, "mapa_concordancia_cnm_mides_mg.png"), map_plot, width = 13.5, height = 8.5, dpi = 220, bg = "white")
ggsave(file.path(figure_dir, "linha_tempo_cnm_mides_mg.png"), timeline_plot, width = 12, height = 6.5, dpi = 220, bg = "white")

stopifnot(!anyDuplicated(annual[c("cod_ibge_6", "consorcio_chave", "ano")]))
stopifnot(abs(sum(annual$valor_total_mides) - sum(mides_mg$valor_total_mides)) < 0.01)
stopifnot(all(annual$situacao_fonte[annual$presente_mides & annual$presente_snapshot_cnm] == "CNM + MIDES"))
stopifnot(all(annual$situacao_fonte[annual$presente_mides & !annual$presente_snapshot_cnm] == "Somente MIDES"))

example <- pair_summary |>
  filter(cod_ibge_6 == "310020", sigla_consorcio == "COMASF")

stopifnot(nrow(example) == 1L)

report <- c(
  "# Validacao do cotejamento CNM x MIDES - piloto MG",
  "",
  paste0("- Periodo MIDES: ", min(anos_mg), "–", max(anos_mg)),
  paste0("- Vinculos CNM MG brutos: ", nrow(cnm_mg_raw)),
  paste0("- Pares CNM MG unicos: ", nrow(cnm_mg)),
  paste0("- Pares CNM com identidade automatica: ", nrow(cnm_matched)),
  paste0("- Observacoes anuais no cotejamento: ", nrow(annual)),
  paste0("- Pares unicos no periodo: ", nrow(pair_summary)),
  paste0("- Consorcios/chaves no resumo: ", nrow(consortium_summary)),
  paste0("- Valor MIDES conservado: R$ ", format(sum(annual$valor_total_mides), big.mark = ".", decimal.mark = ",", scientific = FALSE)),
  "",
  "## Exemplo Abaete x COMASF",
  "",
  "| Campo | Valor |",
  "|---|---|",
  paste0("| Municipio | ", example$municipio, " (`", example$cod_ibge_6, "`) |"),
  paste0("| Consorcio | ", example$sigla_consorcio, " |"),
  paste0("| CNPJ canonico | `", example$cnpj_canonico, "` |"),
  paste0("| Anos MIDES | ", example$anos_mides, " |"),
  paste0("| Situacao | ", example$situacao_periodo, " |"),
  "",
  "## Limite interpretativo",
  "",
  "`presente_snapshot_cnm` e uma marca cadastral observada em 27/08/2026. Ela nao significa que o municipio pertenceu juridicamente ao consorcio em todos os anos MIDES."
)
writeLines(report, file.path(check_dir, "VALIDACAO_COTEJAMENTO_CNM_MIDES_MG.md"), useBytes = TRUE)

print(count(pair_summary, situacao_periodo, name = "pares"))
print(example, n = Inf, width = Inf)
