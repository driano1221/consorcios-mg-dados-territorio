# =============================================================================
# 02_cotejar_mides_munic_saude_2019.R
#
# Compara MIDES e MUNIC no ano de 2019 para o universo consolidado de
# consorcios de saude em MG. A unidade e municipio x raiz de CNPJ.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
})

project_dir <- utils::shortPathName(normalizePath(getwd(), winslash = "\\", mustWork = TRUE))
model_dir <- file.path(project_dir, "analises/modelo_gravitacional_saude")
out_dir <- file.path(model_dir, "outputs")
check_dir <- file.path(model_dir, "checks")

base1_path <- file.path(
  project_dir,
  "dashboards/base1_shiny/data/base_1_vinculos_2015_2019.rds"
)
establishments_path <- file.path(out_dir, "universo_saude_mg_estabelecimentos.rds")
entities_path <- file.path(out_dir, "universo_saude_mg_entidades.rds")
cadastro_path <- file.path(project_dir, "dashboards/base1_shiny/data/cadastro_base.rds")

for (path in c(base1_path, establishments_path, entities_path, cadastro_path)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

collapse_values <- function(x, separator = " | ") {
  values <- sort(unique(trimws(na.omit(as.character(x)))))
  values <- values[nzchar(values)]
  if (length(values) == 0L) NA_character_ else paste(values, collapse = separator)
}

first_value <- function(x) {
  values <- sort(unique(na.omit(as.character(x))))
  values <- values[nzchar(values)]
  if (length(values) == 0L) NA_character_ else values[[1]]
}

base1 <- readRDS(base1_path)
health_establishments <- readRDS(establishments_path)
health_entities <- readRDS(entities_path)
cadastro <- readRDS(cadastro_path) |>
  mutate(
    cnpj_consorcio = str_pad(
      str_remove_all(as.character(cnpj), "[^0-9]"),
      width = 14,
      side = "left",
      pad = "0"
    )
  )

health_identity <- health_establishments |>
  select(cnpj_consorcio, cnpj_raiz_8, cnpj_canonico) |>
  distinct()

base_health_2019 <- base1 |>
  filter(
    ano == 2019L,
    cnpj_consorcio %in% health_identity$cnpj_consorcio
  ) |>
  left_join(health_identity, by = "cnpj_consorcio") |>
  mutate(
    tem_mides_positivo = tem_mides & valor_mides_total > 0,
    tem_munic_declarado = tem_munic
  )

pair_comparison <- base_health_2019 |>
  summarise(
    municipio = first_value(municipio),
    tem_mides_2019 = any(tem_mides_positivo),
    tem_munic_2019 = any(tem_munic_declarado),
    valor_mides_corrente_2019 = sum(valor_mides_corrente, na.rm = TRUE),
    valor_mides_restos_2019 = sum(valor_mides_restos, na.rm = TRUE),
    valor_mides_total_2019 = sum(valor_mides_total, na.rm = TRUE),
    n_transacoes_mides_2019 = sum(n_transacoes_mides, na.rm = TRUE),
    setores_munic_2019 = collapse_values(setores_munic, "; "),
    n_cnpjs_originais = n_distinct(cnpj_consorcio),
    cnpjs_originais = collapse_values(cnpj_consorcio, ";"),
    cnpjs_mides_2019 = collapse_values(cnpj_consorcio[tem_mides_positivo], ";"),
    cnpjs_munic_2019 = collapse_values(cnpj_consorcio[tem_munic_declarado], ";"),
    .by = c(cod_ibge_6, cnpj_raiz_8, cnpj_canonico)
  ) |>
  mutate(
    grupo_concordancia = case_when(
      tem_mides_2019 & tem_munic_2019 ~ "MIDES+MUNIC",
      tem_mides_2019 ~ "somente_MIDES",
      tem_munic_2019 ~ "somente_MUNIC",
      TRUE ~ "sem_fonte"
    ),
    consolidou_multiplos_cnpjs = n_cnpjs_originais > 1L
  ) |>
  left_join(
    health_entities |>
      select(
        cnpj_raiz_8, razao_social_canonica, sigla_canonica,
        situacao_matriz, escopo_saude, camada_analitica
      ),
    by = "cnpj_raiz_8"
  ) |>
  select(
    cod_ibge_6, municipio, cnpj_raiz_8, cnpj_canonico,
    sigla_canonica, razao_social_canonica, situacao_matriz,
    escopo_saude, camada_analitica,
    tem_mides_2019, tem_munic_2019, grupo_concordancia,
    valor_mides_corrente_2019, valor_mides_restos_2019,
    valor_mides_total_2019, n_transacoes_mides_2019,
    setores_munic_2019, n_cnpjs_originais, consolidou_multiplos_cnpjs,
    cnpjs_originais, cnpjs_mides_2019, cnpjs_munic_2019
  ) |>
  arrange(cnpj_raiz_8, cod_ibge_6)

if (any(pair_comparison$grupo_concordancia == "sem_fonte")) {
  stop("A uniao MIDES/MUNIC nao deveria conter pares sem fonte.")
}
if (anyDuplicated(pair_comparison[c("cod_ibge_6", "cnpj_raiz_8")])) {
  stop("Ha duplicidade na chave municipio x entidade consolidada.")
}

documentary_by_root <- health_establishments |>
  select(cnpj_consorcio, cnpj_raiz_8) |>
  left_join(
    cadastro |>
      select(
        cnpj_consorcio, n_docs, url_site, observacoes,
        tem_doc_municipios, tem_rateio, tem_protocolo,
        tem_estatuto, tem_evidencia
      ),
    by = "cnpj_consorcio"
  ) |>
  summarise(
    n_docs_cadastro = sum(n_docs, na.rm = TRUE),
    tem_doc_municipios = any(tem_doc_municipios %in% TRUE, na.rm = TRUE),
    tem_rateio = any(tem_rateio %in% TRUE, na.rm = TRUE),
    tem_protocolo = any(tem_protocolo %in% TRUE, na.rm = TRUE),
    tem_estatuto = any(tem_estatuto %in% TRUE, na.rm = TRUE),
    tem_evidencia_cadastro = any(tem_evidencia %in% TRUE, na.rm = TRUE),
    urls_documentais = collapse_values(url_site),
    observacoes_documentais = collapse_values(observacoes),
    .by = cnpj_raiz_8
  ) |>
  mutate(
    tem_evidencia_documental_nao_temporal = tem_doc_municipios |
      tem_rateio | tem_protocolo | tem_estatuto | tem_evidencia_cadastro
  )

entity_counts <- pair_comparison |>
  summarise(
    pares_mides_munic = sum(grupo_concordancia == "MIDES+MUNIC"),
    pares_somente_mides = sum(grupo_concordancia == "somente_MIDES"),
    pares_somente_munic = sum(grupo_concordancia == "somente_MUNIC"),
    pares_uniao_2019 = n(),
    pares_mides_2019 = sum(tem_mides_2019),
    pares_munic_2019 = sum(tem_munic_2019),
    municipios_uniao_2019 = n_distinct(cod_ibge_6),
    valor_mides_total_2019 = sum(valor_mides_total_2019),
    n_chaves_com_multiplos_cnpjs = sum(consolidou_multiplos_cnpjs),
    .by = cnpj_raiz_8
  )

entity_summary <- health_entities |>
  left_join(entity_counts, by = "cnpj_raiz_8") |>
  left_join(documentary_by_root, by = "cnpj_raiz_8") |>
  mutate(
    across(
      c(
        pares_mides_munic, pares_somente_mides, pares_somente_munic,
        pares_uniao_2019, pares_mides_2019, pares_munic_2019,
        municipios_uniao_2019, n_chaves_com_multiplos_cnpjs
      ),
      ~ coalesce(.x, 0L)
    ),
    valor_mides_total_2019 = coalesce(valor_mides_total_2019, 0),
    categoria_evidencia_2019 = case_when(
      pares_mides_munic > 0L ~ "fontes_com_municipio_em_comum",
      pares_mides_2019 > 0L & pares_munic_2019 > 0L ~ "duas_fontes_sem_municipio_em_comum",
      pares_mides_2019 > 0L ~ "somente_MIDES",
      pares_munic_2019 > 0L ~ "somente_MUNIC",
      TRUE ~ "sem_evidencia_2019"
    ),
    taxa_uniao_jaccard = if_else(
      pares_uniao_2019 > 0L,
      pares_mides_munic / pares_uniao_2019,
      NA_real_
    ),
    pct_pares_mides_confirmados_munic = if_else(
      pares_mides_2019 > 0L,
      pares_mides_munic / pares_mides_2019,
      NA_real_
    ),
    pct_pares_munic_com_mides = if_else(
      pares_munic_2019 > 0L,
      pares_mides_munic / pares_munic_2019,
      NA_real_
    ),
    pares_divergentes = pares_somente_mides + pares_somente_munic,
    saldo_pares_mides_menos_munic = pares_mides_2019 - pares_munic_2019
  ) |>
  arrange(desc(pares_divergentes), taxa_uniao_jaccard, razao_social_canonica)

pair_disagreements <- pair_comparison |>
  filter(grupo_concordancia != "MIDES+MUNIC") |>
  arrange(
    desc(grupo_concordancia == "somente_MUNIC"),
    desc(valor_mides_total_2019),
    cnpj_raiz_8,
    cod_ibge_6
  )

priority_sample <- bind_rows(
  pair_disagreements |>
    filter(grupo_concordancia == "somente_MUNIC") |>
    mutate(criterio_amostra = "todos_os_pares_somente_MUNIC"),
  pair_disagreements |>
    filter(grupo_concordancia == "somente_MIDES") |>
    slice_max(valor_mides_total_2019, n = 27L, with_ties = FALSE) |>
    mutate(criterio_amostra = "27_maiores_valores_somente_MIDES")
) |>
  arrange(desc(grupo_concordancia == "somente_MUNIC"), desc(valor_mides_total_2019))

overall <- pair_comparison |>
  summarise(
    pares_uniao_2019 = n(),
    pares_mides_munic = sum(grupo_concordancia == "MIDES+MUNIC"),
    pares_somente_mides = sum(grupo_concordancia == "somente_MIDES"),
    pares_somente_munic = sum(grupo_concordancia == "somente_MUNIC"),
    pares_mides_2019 = sum(tem_mides_2019),
    pares_munic_2019 = sum(tem_munic_2019),
    municipios = n_distinct(cod_ibge_6),
    entidades_com_alguma_evidencia = n_distinct(cnpj_raiz_8),
    valor_mides_munic = sum(
      if_else(grupo_concordancia == "MIDES+MUNIC", valor_mides_total_2019, 0),
      na.rm = TRUE
    ),
    valor_somente_mides = sum(
      if_else(grupo_concordancia == "somente_MIDES", valor_mides_total_2019, 0),
      na.rm = TRUE
    ),
    valor_mides_total_2019 = sum(valor_mides_total_2019, na.rm = TRUE)
  ) |>
  mutate(
    jaccard_global = pares_mides_munic / pares_uniao_2019,
    pct_mides_confirmado_munic = pares_mides_munic / pares_mides_2019,
    pct_munic_com_mides = pares_mides_munic / pares_munic_2019,
    pct_valor_mides_munic = valor_mides_munic / valor_mides_total_2019
  )

entity_category_summary <- entity_summary |>
  count(categoria_evidencia_2019, name = "n_entidades") |>
  arrange(desc(n_entidades), categoria_evidencia_2019)

documentary_summary <- entity_summary |>
  summarise(
    entidades = n(),
    com_documento_municipios = sum(tem_doc_municipios),
    com_rateio = sum(tem_rateio),
    com_protocolo = sum(tem_protocolo),
    com_estatuto = sum(tem_estatuto),
    com_evidencia_cadastro = sum(tem_evidencia_cadastro),
    com_alguma_evidencia_documental = sum(tem_evidencia_documental_nao_temporal)
  )

write.csv(
  pair_comparison,
  file.path(out_dir, "cotejamento_mides_munic_saude_mg_2019.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
write.csv(
  entity_summary,
  file.path(out_dir, "resumo_entidades_mides_munic_saude_mg_2019.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
write.csv(
  pair_disagreements,
  file.path(out_dir, "divergencias_mides_munic_saude_mg_2019.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
write.csv(
  priority_sample,
  file.path(out_dir, "amostra_revisao_mides_munic_saude_mg_2019.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
write.csv(
  overall,
  file.path(out_dir, "resumo_geral_mides_munic_saude_mg_2019.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
saveRDS(pair_comparison, file.path(out_dir, "cotejamento_mides_munic_saude_mg_2019.rds"))
saveRDS(entity_summary, file.path(out_dir, "resumo_entidades_mides_munic_saude_mg_2019.rds"))

top_divergences <- entity_summary |>
  filter(pares_uniao_2019 > 0L) |>
  slice_max(pares_divergentes, n = 12L, with_ties = FALSE)

top_rows <- apply(top_divergences, 1, function(row) {
  sigla <- if (is.na(row[["sigla_canonica"]]) || !nzchar(row[["sigla_canonica"]])) {
    "(sem sigla)"
  } else {
    row[["sigla_canonica"]]
  }
  paste0(
    "| `", row[["cnpj_canonico"]], "` | ", sigla,
    " | ", row[["pares_mides_munic"]],
    " | ", row[["pares_somente_mides"]],
    " | ", row[["pares_somente_munic"]],
    " | ", sprintf("%.1f%%", 100 * as.numeric(row[["taxa_uniao_jaccard"]])),
    " | ", ifelse(row[["tem_doc_municipios"]] == "TRUE", "Sim", "Nao"), " |"
  )
})

report <- c(
  "# Cotejamento MIDES X MUNIC - Consorcios De Saude Em MG, 2019",
  "",
  "## Objetivo E Unidade",
  "",
  "A comparacao usa a unidade `municipio x entidade consolidada` em 2019. Matriz e filiais foram reunidas pela raiz de oito digitos antes de comparar as fontes.",
  "",
  "## Resultado Geral",
  "",
  "| Indicador | Resultado |",
  "|---|---:|",
  paste0("| Pares na uniao das fontes | ", overall$pares_uniao_2019, " |"),
  paste0("| MIDES + MUNIC | ", overall$pares_mides_munic, " |"),
  paste0("| Somente MIDES | ", overall$pares_somente_mides, " |"),
  paste0("| Somente MUNIC | ", overall$pares_somente_munic, " |"),
  paste0("| Municipios | ", overall$municipios, " |"),
  paste0("| Entidades com alguma evidencia em 2019 | ", overall$entidades_com_alguma_evidencia, " |"),
  paste0("| Jaccard global | ", sprintf("%.1f%%", 100 * overall$jaccard_global), " |"),
  paste0("| Pares MIDES tambem declarados na MUNIC | ", sprintf("%.1f%%", 100 * overall$pct_mides_confirmado_munic), " |"),
  paste0("| Pares MUNIC com pagamento MIDES | ", sprintf("%.1f%%", 100 * overall$pct_munic_com_mides), " |"),
  paste0("| Valor MIDES em pares presentes nas duas fontes | ", sprintf("%.1f%%", 100 * overall$pct_valor_mides_munic), " |"),
  "",
  "## Leitura Por Entidade",
  "",
  "| Categoria | Entidades |",
  "|---|---:|",
  paste0("| ", entity_category_summary$categoria_evidencia_2019, " | ", entity_category_summary$n_entidades, " |"),
  "",
  "## Cobertura Documental Do Cadastro",
  "",
  "Os indicadores abaixo mostram documentos existentes no cadastro. Eles nao comprovam que a composicao municipal documentada corresponde especificamente a 2019.",
  "",
  "| Evidencia | Entidades |",
  "|---|---:|",
  paste0("| Documento de municipios | ", documentary_summary$com_documento_municipios, " |"),
  paste0("| Documento de rateio | ", documentary_summary$com_rateio, " |"),
  paste0("| Protocolo | ", documentary_summary$com_protocolo, " |"),
  paste0("| Estatuto | ", documentary_summary$com_estatuto, " |"),
  paste0("| Alguma evidencia documental | ", documentary_summary$com_alguma_evidencia_documental, " |"),
  "",
  "## Maiores Divergencias Em Numero De Municipios",
  "",
  "| CNPJ canonico | Sigla | Ambas | So MIDES | So MUNIC | Jaccard | Doc. municipios |",
  "|---|---|---:|---:|---:|---:|---|",
  top_rows,
  "",
  "## Interpretacao",
  "",
  "- `MIDES+MUNIC`: pagamento positivo e participacao declarada para o mesmo municipio e entidade em 2019.",
  "- `somente_MIDES`: pagamento observado sem declaracao MUNIC correspondente; nao e erro automatico.",
  "- `somente_MUNIC`: participacao declarada sem pagamento MIDES observado naquele ano; nao prova inatividade.",
  "- A MUNIC confirma quase todos os seus pares no MIDES, mas cobre somente parte dos pares financeiros.",
  "- Documentos cadastrais ajudam a revisar divergencias, mas nao devem ser retroagidos para 2019 sem data explicita.",
  "- Nenhum resultado desta etapa altera o dashboard ou estima o modelo gravitacional."
)
writeLines(report, file.path(check_dir, "VALIDACAO_COTEJAMENTO_MIDES_MUNIC_SAUDE_2019.md"), useBytes = TRUE)

message("Cotejamento MIDES x MUNIC 2019 concluido.")
print(overall)
print(entity_category_summary)
