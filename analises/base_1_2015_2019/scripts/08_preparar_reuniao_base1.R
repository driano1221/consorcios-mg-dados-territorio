# =============================================================================
# 08_preparar_reuniao_base1.R
# Materiais de reuniao - Base 1 2015/2019
#
# Gera exemplos concretos e resumo executivo curto para apresentacao.
# =============================================================================

library(dplyr)
library(readr)
library(writexl)
library(stringr)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(project_dir, "analises/base_1_2015_2019/outputs")
check_dir <- file.path(project_dir, "analises/base_1_2015_2019/checks")

validacao_path <- file.path(out_dir, "base_1_validacao_siconfi_reconstruido_2015_2019.csv")
sens_path <- file.path(out_dir, "base_1_resumo_siconfi_reconstruido_sensibilidade_5_10.csv")
vinculos_path <- file.path(out_dir, "base_1_vinculos_2015_2019.csv")

if (!file.exists(validacao_path)) stop("Validacao reconstruida nao encontrada.")
if (!file.exists(sens_path)) stop("Resumo de sensibilidade nao encontrado.")
if (!file.exists(vinculos_path)) stop("Base de vinculos nao encontrada.")

validacao <- read_csv(validacao_path, show_col_types = FALSE)
sens <- read_csv(sens_path, show_col_types = FALSE)
vinculos <- read_csv(vinculos_path, show_col_types = FALSE)

fmt_reais <- function(x) {
  paste0("R$ ", format(round(x, 0), big.mark = ".", decimal.mark = ",", scientific = FALSE))
}

exemplos <- bind_rows(
  validacao |>
    filter(classe_validacao == "congruente", ano == 2019) |>
    arrange(desc(valor_mides_corrente_cadastro_1194)) |>
    slice_head(n = 3),
  validacao |>
    filter(classe_validacao == "divergente_valor", ano == 2019) |>
    arrange(desc(diferenca_abs_modulo)) |>
    slice_head(n = 3),
  validacao |>
    filter(classe_validacao == "mides_sem_siconfi") |>
    arrange(desc(valor_mides_corrente_cadastro_1194)) |>
    slice_head(n = 3),
  validacao |>
    filter(classe_validacao == "siconfi_sem_mides") |>
    arrange(desc(valor_siconfi_consorcio)) |>
    slice_head(n = 3)
) |>
  transmute(
    classe_validacao,
    ano,
    cod_ibge_6,
    municipio,
    valor_mides = valor_mides_corrente_cadastro_1194,
    valor_siconfi = valor_siconfi_consorcio,
    diferenca = diferenca_abs,
    diferenca_abs_modulo,
    diferenca_rel_pct = round(diferenca_rel * 100, 1),
    n_pares_total_base1,
    n_pares_mides,
    n_pares_munic,
    n_consorcios_base1,
    leitura = case_when(
      classe_validacao == "congruente" ~ "MIDES e SICONFI positivos e dentro da tolerancia.",
      classe_validacao == "divergente_valor" ~ "Ambos positivos, mas os valores ficam fora da tolerancia.",
      classe_validacao == "mides_sem_siconfi" ~ "MIDES mostra pagamento a CNPJ de consorcio, mas SICONFI reconstruido nao mostra valor no municipio-ano.",
      classe_validacao == "siconfi_sem_mides" ~ "SICONFI mostra despesa com consorcio, mas MIDES nao captura pagamento aos CNPJs do cadastro no municipio-ano.",
      TRUE ~ "Caso residual."
    )
  )

exemplos_slide <- exemplos |>
  mutate(
    valor_mides_fmt = fmt_reais(valor_mides),
    valor_siconfi_fmt = fmt_reais(valor_siconfi),
    diferenca_fmt = fmt_reais(diferenca)
  ) |>
  select(
    classe_validacao, ano, municipio, valor_mides_fmt, valor_siconfi_fmt,
    diferenca_fmt, diferenca_rel_pct, leitura
  )

resumo_curto <- sens |>
  transmute(
    tolerancia = tolerancia_rel_pct,
    ano,
    municipio_ano = n_municipio_ano,
    congruente = n_congruente,
    divergente = n_divergente_valor,
    mides_sem_siconfi = n_mides_sem_siconfi,
    siconfi_sem_mides = n_siconfi_sem_mides,
    taxa = paste0(format(taxa_congruencia_entre_ambos, decimal.mark = ","), "%")
  )

resumo_vinculos <- vinculos |>
  summarise(
    linhas = n(),
    municipios = n_distinct(cod_ibge_6),
    consorcios = n_distinct(cnpj_consorcio),
    valor_mides_corrente = sum(valor_mides_corrente, na.rm = TRUE),
    .by = c(ano, grupo_vinculo)
  ) |>
  arrange(ano, grupo_vinculo)

out_xlsx <- file.path(check_dir, "base_1_materiais_reuniao.xlsx")
out_md <- file.path(check_dir, "ROTEIRO_REUNIAO_BASE1.md")

write_xlsx(
  list(
    resumo_sensibilidade = resumo_curto,
    exemplos = exemplos,
    exemplos_slide = exemplos_slide,
    resumo_vinculos = resumo_vinculos
  ),
  out_xlsx
)

linhas_md <- c(
  "# Roteiro de reuniao - Base 1 2015/2019",
  "",
  "## Mensagem central",
  "",
  "> A Base 1 separa vinculo e validacao financeira. MIDES e MUNIC formam os pares municipio-consorcio nos anos comparaveis de 2015 e 2019. O SICONFI entra depois, apenas como validacao financeira agregada por municipio-ano, reprocessado com regra auditavel.",
  "",
  "## Fala de 1 minuto",
  "",
  "1. O painel principal integra evidencias de fontes com temporalidades diferentes; por isso criamos a Base 1 como recorte controlado.",
  "2. A Base 1 usa 2015 e 2019 porque sao os anos em que a MUNIC tem estrutura operacional para vinculo municipio-CNPJ de consorcio.",
  "3. MIDES entra como pagamento observado ao CNPJ do consorcio; MUNIC entra como declaracao de participacao; ambos formam a base de vinculos.",
  "4. SICONFI nao identifica CNPJ destino. Por isso, ele nao cria vinculo; ele valida coerencia financeira no municipio-ano.",
  "5. Reprocessamos o SICONFI via R/BigQuery com a regra `consorcio_pagas`, que e a mais comparavel ao MIDES porque mede despesas pagas em rubricas de consorcio.",
  "",
  "## Resultado para mostrar",
  "",
  "| Tolerancia | Ano | Congruente | Divergente | Taxa |",
  "|---:|---:|---:|---:|---:|",
  "| 5% | 2015 | 122 | 537 | 18,5% |",
  "| 5% | 2019 | 325 | 459 | 41,5% |",
  "| 10% | 2015 | 142 | 517 | 21,5% |",
  "| 10% | 2019 | 373 | 411 | 47,6% |",
  "",
  "## Leitura",
  "",
  "- A regra de 10% e boa para apresentacao executiva.",
  "- A regra de 5% funciona como teste conservador.",
  "- A conclusao qualitativa nao muda: 2019 e mais congruente que 2015, mas ainda ha muitas divergencias.",
  "- Essas divergencias viram agenda de auditoria, nao erro automatico.",
  "",
  "## Perguntas para decidir na reuniao",
  "",
  "1. A regra oficial da validacao financeira sera `consorcio_pagas`?",
  "2. A apresentacao deve usar 10% como principal e 5% como sensibilidade?",
  "3. A proxima etapa deve priorizar auditoria dos maiores divergentes ou expansao temporal/metodologica?",
  "4. Devemos separar consorcios de saude dos demais antes de interpretar divergencias financeiras?",
  "",
  "## Materiais",
  "",
  "- `checks/base_1_materiais_reuniao.xlsx`",
  "- `slides/2026-06-11_base1_reuniao_curta.html`"
)

writeLines(linhas_md, out_md, useBytes = TRUE)

message("Exportado:")
message("  ", out_xlsx)
message("  ", out_md)
