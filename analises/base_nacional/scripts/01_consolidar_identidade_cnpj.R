# =============================================================================
# 01_consolidar_identidade_cnpj.R
#
# Cria a camada nacional de identidade de consorcios pela raiz de oito digitos
# do CNPJ. Os registros originais permanecem preservados e cada estabelecimento
# recebe uma chave canonica correspondente a matriz (ordem 0001).
# =============================================================================

invisible(Sys.setlocale("LC_ALL", "Portuguese_Brazil.1252"))

library(dplyr)
library(stringr)

project_dir <- "."
cadastro_path <- file.path(project_dir, "dados", "processado", "cadastro_base.rds")
if (!file.exists(cadastro_path)) {
  cadastro_path <- file.path(project_dir, "dashboards", "base1_shiny", "data", "cadastro_base.rds")
}
if (!file.exists(cadastro_path)) stop("Cadastro IPEA nao encontrado.")

out_dir <- file.path(project_dir, "analises", "base_nacional", "outputs")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

collapse_values <- function(x) {
  x <- sort(unique(na.omit(as.character(x))))
  x <- x[nzchar(x)]
  if (length(x) == 0L) NA_character_ else paste(x, collapse = " | ")
}

cadastro <- readRDS(cadastro_path) |>
  mutate(
    cnpj_original = str_pad(str_remove_all(as.character(cnpj), "[^0-9]"), 14, pad = "0"),
    cnpj_raiz_8 = str_sub(cnpj_original, 1, 8),
    ordem_estabelecimento = str_sub(cnpj_original, 9, 12),
    tipo_estabelecimento = if_else(ordem_estabelecimento == "0001", "matriz", "filial")
  )

if (nrow(cadastro) != 1194L) stop("O cadastro deveria conter 1.194 CNPJs.")
if (anyDuplicated(cadastro$cnpj_original)) stop("Ha CNPJ duplicado no cadastro original.")
if (any(str_length(cadastro$cnpj_original) != 14L)) stop("Ha CNPJ fora do padrao de 14 digitos.")

matrizes <- cadastro |>
  filter(tipo_estabelecimento == "matriz") |>
  transmute(
    cnpj_raiz_8,
    cnpj_matriz = cnpj_original,
    razao_social_canonica = razao_social,
    sigla_canonica = sigla,
    uf_sede_canonica = uf,
    municipio_sede_canonico = municipio_sede,
    situacao_matriz = situacao,
    ano_abertura_matriz = ano_fundacao,
    tipo_cadastro_matriz = tipo,
    setores_cadastro_matriz = setores,
    tipo_fonte_matriz = tipo_fonte
  )

if (anyDuplicated(matrizes$cnpj_raiz_8)) stop("Mais de uma matriz para a mesma raiz.")

resumo_raiz <- cadastro |>
  summarise(
    n_estabelecimentos = n_distinct(cnpj_original),
    n_matrizes = n_distinct(cnpj_original[tipo_estabelecimento == "matriz"]),
    n_filiais = n_distinct(cnpj_original[tipo_estabelecimento == "filial"]),
    cnpjs_estabelecimentos = collapse_values(cnpj_original),
    cnpjs_filiais = collapse_values(cnpj_original[tipo_estabelecimento == "filial"]),
    razoes_sociais_estabelecimentos = collapse_values(razao_social),
    siglas_estabelecimentos = collapse_values(sigla),
    situacoes_estabelecimentos = collapse_values(situacao),
    anos_abertura_estabelecimentos = collapse_values(ano_fundacao),
    ufs_estabelecimentos = collapse_values(uf),
    municipios_sede_estabelecimentos = collapse_values(municipio_sede),
    tipos_cadastro_estabelecimentos = collapse_values(tipo),
    setores_cadastro_estabelecimentos = collapse_values(setores),
    .by = cnpj_raiz_8
  ) |>
  left_join(matrizes, by = "cnpj_raiz_8") |>
  mutate(
    cnpj_canonico = cnpj_matriz,
    tem_filial = n_filiais > 0L,
    regra_consolidacao = if_else(
      tem_filial,
      "raiz_8_digitos_com_matriz_0001",
      "cnpj_unico_matriz_0001"
    )
  ) |>
  arrange(uf_sede_canonica, razao_social_canonica, cnpj_raiz_8)

if (any(resumo_raiz$n_matrizes != 1L)) {
  stop("Toda raiz deve possuir exatamente uma matriz no cadastro IPEA.")
}
if (any(str_count(coalesce(resumo_raiz$ufs_estabelecimentos, ""), fixed("|")) > 0L)) {
  stop("Uma raiz possui estabelecimentos em mais de uma UF; revisar antes de consolidar.")
}

crosswalk <- cadastro |>
  select(
    cnpj_original, cnpj_raiz_8, ordem_estabelecimento, tipo_estabelecimento,
    razao_social_original = razao_social,
    sigla_original = sigla,
    uf_sede_original = uf,
    municipio_sede_original = municipio_sede,
    situacao_estabelecimento = situacao,
    ano_abertura_estabelecimento = ano_fundacao
  ) |>
  left_join(
    resumo_raiz |>
      select(
        cnpj_raiz_8, cnpj_matriz, cnpj_canonico,
        razao_social_canonica, sigla_canonica,
        uf_sede_canonica, municipio_sede_canonico,
        situacao_matriz, ano_abertura_matriz,
        n_estabelecimentos, n_filiais, regra_consolidacao
      ),
    by = "cnpj_raiz_8"
  ) |>
  mutate(
    foi_consolidado = n_estabelecimentos > 1L,
    identidade_preservada = TRUE
  ) |>
  arrange(cnpj_raiz_8, desc(tipo_estabelecimento == "matriz"), cnpj_original)

cadastro_consolidado <- resumo_raiz |>
  select(
    cnpj_raiz_8, cnpj_canonico, cnpj_matriz,
    razao_social_canonica, sigla_canonica,
    uf_sede_canonica, municipio_sede_canonico,
    situacao_matriz, ano_abertura_matriz,
    tipo_cadastro_matriz, setores_cadastro_matriz, tipo_fonte_matriz,
    n_estabelecimentos, n_filiais, tem_filial, regra_consolidacao,
    cnpjs_estabelecimentos, cnpjs_filiais,
    razoes_sociais_estabelecimentos, siglas_estabelecimentos,
    situacoes_estabelecimentos, anos_abertura_estabelecimentos,
    municipios_sede_estabelecimentos,
    tipos_cadastro_estabelecimentos, setores_cadastro_estabelecimentos
  )

resumo_validacao <- tibble::tibble(
  indicador = c(
    "cnpjs_originais", "raizes_consolidadas", "reducao_cnpjs",
    "raizes_com_filial", "matrizes_em_raizes_multiplas", "filiais_incorporadas",
    "raizes_sem_matriz", "raizes_com_mais_de_uma_matriz", "raizes_multiplas_ufs"
  ),
  valor = c(
    nrow(crosswalk), nrow(cadastro_consolidado), nrow(crosswalk) - nrow(cadastro_consolidado),
    sum(cadastro_consolidado$tem_filial),
    sum(cadastro_consolidado$tem_filial & cadastro_consolidado$n_estabelecimentos >= 2L),
    sum(cadastro_consolidado$n_filiais),
    sum(resumo_raiz$n_matrizes == 0L), sum(resumo_raiz$n_matrizes > 1L),
    sum(str_count(coalesce(resumo_raiz$ufs_estabelecimentos, ""), fixed("|")) > 0L)
  )
)

saveRDS(crosswalk, file.path(out_dir, "crosswalk_cnpj_matriz_filial_nacional.rds"))
saveRDS(cadastro_consolidado, file.path(out_dir, "cadastro_consorcios_nacional_consolidado.rds"))
write.csv(crosswalk, file.path(out_dir, "crosswalk_cnpj_matriz_filial_nacional.csv"), row.names = FALSE, na = "")
write.csv(cadastro_consolidado, file.path(out_dir, "cadastro_consorcios_nacional_consolidado.csv"), row.names = FALSE, na = "")
write.csv(resumo_validacao, file.path(out_dir, "validacao_identidade_cnpj_resumo.csv"), row.names = FALSE, na = "")

message("Identidade nacional materializada.")
print(resumo_validacao)
