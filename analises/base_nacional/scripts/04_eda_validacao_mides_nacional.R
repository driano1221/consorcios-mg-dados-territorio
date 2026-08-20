# =============================================================================
# 04_eda_validacao_mides_nacional.R
#
# Produz checks, amostras e visualizacao de cobertura para validacao humana da
# primeira base MIDES nacional consolidada.
# =============================================================================

invisible(Sys.setlocale("LC_ALL", "Portuguese_Brazil.1252"))

library(dplyr)
library(ggplot2)
library(scales)
library(stringr)

project_dir <- "."
out_dir <- file.path(project_dir, "analises", "base_nacional", "outputs")
check_dir <- file.path(project_dir, "analises", "base_nacional", "checks")
dir.create(check_dir, recursive = TRUE, showWarnings = FALSE)

original <- readRDS(file.path(out_dir, "painel_mides_nacional_cnpj_original_ano.rds"))
consolidado <- readRDS(file.path(out_dir, "painel_mides_nacional_raiz_ano.rds"))
cadastro <- readRDS(file.path(out_dir, "cadastro_consorcios_nacional_consolidado.rds"))
sem_chave <- readRDS(file.path(out_dir, "mides_nacional_registros_sem_chave_municipal.rds"))
raw <- readRDS(file.path(out_dir, "mides_ipea_nacional_transacoes.rds"))

comparacao_uf <- original |>
  summarise(
    cnpjs_antes = n_distinct(cnpj_original),
    linhas_antes = n(),
    pares_antes = n_distinct(paste(id_municipio, cnpj_original)),
    valor_antes = sum(valor_total),
    .by = uf_municipio_pagador
  ) |>
  left_join(
    consolidado |>
      summarise(
        consorcios_depois = n_distinct(cnpj_raiz_8),
        linhas_depois = n(),
        pares_depois = n_distinct(paste(id_municipio, cnpj_raiz_8)),
        valor_depois = sum(valor_total),
        .by = uf_municipio_pagador
      ),
    by = "uf_municipio_pagador"
  ) |>
  mutate(
    reducao_cnpjs = cnpjs_antes - consorcios_depois,
    reducao_linhas = linhas_antes - linhas_depois,
    reducao_pares = pares_antes - pares_depois,
    diferenca_valor = valor_depois - valor_antes
  ) |>
  arrange(uf_municipio_pagador)

raizes_afetadas <- original |>
  summarise(
    cnpjs_observados = paste(sort(unique(cnpj_original)), collapse = "; "),
    n_cnpjs_observados = n_distinct(cnpj_original),
    ufs_pagadoras = paste(sort(unique(uf_municipio_pagador)), collapse = "; "),
    municipios = n_distinct(id_municipio),
    anos = paste(sort(unique(ano)), collapse = "; "),
    linhas_antes = n(),
    pares_antes = n_distinct(paste(uf_municipio_pagador, id_municipio, cnpj_original)),
    valor_total = sum(valor_total),
    .by = cnpj_raiz_8
  ) |>
  filter(n_cnpjs_observados > 1L) |>
  left_join(
    cadastro |>
      select(
        cnpj_raiz_8, cnpj_canonico, razao_social_canonica,
        uf_sede_canonica, n_estabelecimentos, n_filiais
      ),
    by = "cnpj_raiz_8"
  ) |>
  arrange(desc(valor_total))

colisoes_municipio_ano <- consolidado |>
  filter(consolidou_no_municipio_ano) |>
  select(
    uf_municipio_pagador, id_municipio, ano, cnpj_raiz_8,
    cnpj_canonico, razao_social_canonica,
    cnpjs_originais_observados, n_cnpjs_originais_observados,
    valor_corrente, valor_restos, valor_total, n_transacoes
  ) |>
  arrange(uf_municipio_pagador, cnpj_raiz_8, id_municipio, ano)

resumo_geral <- tibble::tibble(
  indicador = c(
    "ufs_com_mides", "cnpjs_observados", "raizes_observadas",
    "raizes_afetadas_por_consolidacao", "linhas_anuais_antes",
    "linhas_anuais_depois", "pares_antes", "pares_depois",
    "colisoes_municipio_ano", "registros_sem_chave_municipal",
    "valor_sem_chave_municipal", "valor_total_antes", "valor_total_depois"
  ),
  valor = c(
    n_distinct(original$uf_municipio_pagador),
    n_distinct(original$cnpj_original),
    n_distinct(consolidado$cnpj_raiz_8),
    nrow(raizes_afetadas),
    nrow(original), nrow(consolidado),
    n_distinct(paste(original$uf_municipio_pagador, original$id_municipio, original$cnpj_original)),
    n_distinct(paste(consolidado$uf_municipio_pagador, consolidado$id_municipio, consolidado$cnpj_raiz_8)),
    nrow(colisoes_municipio_ano), nrow(sem_chave), sum(sem_chave$valor_final, na.rm = TRUE),
    sum(original$valor_total), sum(consolidado$valor_total)
  )
)

qualidade_uf <- raw |>
  summarise(
    transacoes = n(),
    municipios_identificados = n_distinct(id_municipio, na.rm = TRUE),
    registros_sem_municipio = sum(is.na(id_municipio) | !nzchar(id_municipio)),
    registros_sem_indicador_restos = sum(is.na(indicador_restos_pagar)),
    registros_valor_zero = sum(coalesce(valor_final, 0) == 0),
    registros_valor_negativo = sum(valor_final < 0, na.rm = TRUE),
    valor_negativo = sum(valor_final[valor_final < 0], na.rm = TRUE),
    valor_total = sum(valor_final, na.rm = TRUE),
    .by = sigla_uf
  ) |>
  arrange(sigla_uf)

outliers <- consolidado |>
  arrange(desc(abs(valor_total))) |>
  select(
    uf_municipio_pagador, id_municipio, ano, cnpj_raiz_8,
    cnpj_canonico, razao_social_canonica, valor_corrente,
    valor_restos, valor_indicador_restos_ausente, valor_total, n_transacoes
  ) |>
  slice_head(n = 30)

set.seed(20260820)
amostra_validacao <- consolidado |>
  slice_sample(n = min(30L, nrow(consolidado))) |>
  arrange(uf_municipio_pagador, ano, cnpj_raiz_8)

write.csv(comparacao_uf, file.path(check_dir, "comparacao_antes_depois_por_uf.csv"), row.names = FALSE, na = "")
write.csv(raizes_afetadas, file.path(check_dir, "raizes_mides_afetadas_consolidacao.csv"), row.names = FALSE, na = "")
write.csv(colisoes_municipio_ano, file.path(check_dir, "colisoes_matriz_filial_municipio_ano.csv"), row.names = FALSE, na = "")
write.csv(resumo_geral, file.path(check_dir, "resumo_validacao_mides_nacional.csv"), row.names = FALSE, na = "")
write.csv(qualidade_uf, file.path(check_dir, "qualidade_transacoes_por_uf.csv"), row.names = FALSE, na = "")
write.csv(outliers, file.path(check_dir, "amostra_maiores_valores_anuais.csv"), row.names = FALSE, na = "")
write.csv(amostra_validacao, file.path(check_dir, "amostra_aleatoria_validacao.csv"), row.names = FALSE, na = "")

plot_data <- comparacao_uf |>
  select(uf_municipio_pagador, CNPJs = cnpjs_antes, Raizes = consorcios_depois) |>
  tidyr::pivot_longer(-uf_municipio_pagador, names_to = "unidade", values_to = "quantidade")

p <- ggplot(plot_data, aes(x = reorder(uf_municipio_pagador, quantidade), y = quantidade, fill = unidade)) +
  geom_col(position = position_dodge(width = 0.72), width = 0.64) +
  geom_text(
    aes(label = quantidade), position = position_dodge(width = 0.72),
    hjust = -0.15, size = 3.4, color = "#17324D"
  ) +
  coord_flip(clip = "off") +
  scale_fill_manual(values = c("CNPJs" = "#7AA6C2", "Raizes" = "#1F7A4D")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(
    title = "Cobertura MIDES nos CNPJs do cadastro IPEA",
    subtitle = "Comparacao entre estabelecimentos originais e consorcios consolidados por raiz",
    x = NULL, y = "Entidades observadas", fill = NULL,
    caption = "A UF representa o municipio pagador. Cobertura MIDES disponivel em oito UFs."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", color = "#17324D"),
    plot.subtitle = element_text(color = "#45657A"),
    legend.position = "top",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

tmp_png <- tempfile(fileext = ".png")
ggsave(tmp_png, p, width = 10, height = 5.8, dpi = 180, bg = "white")
png_destino <- file.path(check_dir, "cobertura_mides_nacional_validacao.png")
if (!file.copy(tmp_png, png_destino, overwrite = TRUE)) stop("Falha ao copiar grafico de validacao.")
unlink(tmp_png)

message("EDA nacional concluida.")
print(resumo_geral, n = Inf)
message("Raizes afetadas no MIDES: ", nrow(raizes_afetadas))
message("Colisoes municipio-ano consolidadas: ", nrow(colisoes_municipio_ano))
print(qualidade_uf, n = Inf)
