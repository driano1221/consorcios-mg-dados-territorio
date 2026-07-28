# =============================================================================
# 06_consolidar_classificacao_v0_4.R
# Incorpora decisoes do usuario sem sobrescrever a classificacao v0.3.
#
# v0.4:
# - valida os grupos provisoria_cadastro e provisoria_nome para uso analitico;
# - exclui da camada ativa seis matrizes inaptas ou baixadas;
# - faz filiais herdarem area/perfil da matriz pela raiz de oito digitos;
# - distingue multifinalitario de multissetorial pelo nome e so atribui area
#   quando nome juridico ou alias MIDES explicita setor.
# =============================================================================

library(dplyr)
library(readr)
library(stringr)

project_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
class_dir <- file.path(project_dir, "analises", "classificacao_politicas")
out_dir <- file.path(class_dir, "outputs")
input_dir <- file.path(class_dir, "inputs")

path_v03 <- file.path(out_dir, "classificacao_areas_politica_mg_v0_3_tecnica.csv")
path_decisoes <- file.path(input_dir, "decisoes_usuario_v0_4.csv")

for (path in c(path_v03, path_decisoes)) {
  if (!file.exists(path)) stop("Arquivo nao encontrado: ", path)
}

base_v03 <- read_csv(path_v03, show_col_types = FALSE)
decisoes <- read_csv(path_decisoes, show_col_types = FALSE)

stopifnot(nrow(base_v03) == 223L)
stopifnot(all(c("validar_cadastro", "validar_nome", "excluir_inativos", "filial_matriz", "multifinal_nome") %in% decisoes$regra))

inativos_esperados <- c(
  "02097453000103", "10423008000114", "12418785000104",
  "15550319000168", "12041914000180", "20149133000131"
)

resultado <- base_v03 |>
  mutate(
    raiz_cnpj_8_v04 = str_sub(cnpj_consorcio, 1, 8),
    ordem_cnpj_v04 = str_sub(cnpj_consorcio, 9, 12),
    tipo_estabelecimento_v04 = if_else(ordem_cnpj_v04 == "0001", "matriz", "filial"),
    status_validacao_v0_4 = status_validacao_v0_3,
    area_politica_final_v0_4 = area_politica_final_v0_3,
    fonte_principal_v0_4 = fonte_principal_v0_3,
    perfil_institucional_v0_4 = perfil_institucional_v0_3,
    decisao_usuario_v0_4 = NA_character_,
    justificativa_v0_4 = justificativa_v0_3,
    ativo_analise_v0_4 = TRUE
  ) |>
  mutate(
    status_validacao_v0_4 = case_when(
      status_validacao_v0_3 %in% c("provisoria_cadastro", "provisoria_nome") ~ "validada_usuario",
      TRUE ~ status_validacao_v0_4
    ),
    decisao_usuario_v0_4 = case_when(
      status_validacao_v0_3 == "provisoria_cadastro" ~ "validar_cadastro",
      status_validacao_v0_3 == "provisoria_nome" ~ "validar_nome",
      TRUE ~ decisao_usuario_v0_4
    ),
    justificativa_v0_4 = case_when(
      status_validacao_v0_3 == "provisoria_cadastro" ~ "Area validada pelo usuario para uso analitico; fonte original preservada como Cadastro IPEA arquivo.",
      status_validacao_v0_3 == "provisoria_nome" ~ "Area validada pelo usuario para uso analitico; fonte original preservada como nome juridico.",
      TRUE ~ justificativa_v0_4
    )
  )

# Excluir apenas da camada analitica ativa: os registros brutos continuam preservados.
resultado <- resultado |>
  mutate(
    excluir_inativo = status_validacao_v0_3 == "pendente_documento" & cnpj_consorcio %in% inativos_esperados,
    status_validacao_v0_4 = if_else(excluir_inativo, "excluido_inativo", status_validacao_v0_4),
    area_politica_final_v0_4 = if_else(excluir_inativo, NA_character_, area_politica_final_v0_4),
    fonte_principal_v0_4 = if_else(excluir_inativo, "situacao_cadastral", fonte_principal_v0_4),
    perfil_institucional_v0_4 = if_else(excluir_inativo, "excluido_inativo", perfil_institucional_v0_4),
    decisao_usuario_v0_4 = if_else(excluir_inativo, "excluir_inativos", decisao_usuario_v0_4),
    justificativa_v0_4 = if_else(excluir_inativo, "CNPJ matriz sem outra unidade da mesma raiz no recorte MG e com situacao cadastral inativa ou baixada; excluido somente da camada analitica ativa.", justificativa_v0_4),
    ativo_analise_v0_4 = !excluir_inativo
  )

stopifnot(sum(resultado$excluir_inativo) == 6L)
stopifnot(all(resultado$situacao[resultado$excluir_inativo] %in% c("Inapta", "Baixada")))

# Perfil por nome: nao transforma perfil em area de politica publica.
resultado <- resultado |>
  mutate(
    nome_juridico_v04 = str_to_upper(coalesce(razao_social, "")),
    nomes_mides_v04 = str_to_upper(coalesce(nomes_mides, "")),
    multi_por_nome_v04 = status_validacao_v0_3 == "provisoria_multifinalitario",
    perfil_nome_v04 = case_when(
      multi_por_nome_v04 & str_detect(nome_juridico_v04, "MULTISSETORIAL") ~ "multissetorial",
      multi_por_nome_v04 & str_detect(nome_juridico_v04, "MULTIFINALIT") ~ "multifinalitario",
      multi_por_nome_v04 & str_detect(nomes_mides_v04, "MULTISSETORIAL") ~ "multissetorial",
      multi_por_nome_v04 & str_detect(nomes_mides_v04, "MULTIFINALIT") ~ "multifinalitario",
      multi_por_nome_v04 ~ "perfil_sem_termo_explicito",
      TRUE ~ perfil_institucional_v0_4
    ),
    saude_explicita_no_nome_v04 = multi_por_nome_v04 & str_detect(paste(nome_juridico_v04, nomes_mides_v04), "SAUDE|SAÚDE")
  ) |>
  mutate(
    perfil_institucional_v0_4 = if_else(multi_por_nome_v04, perfil_nome_v04, perfil_institucional_v0_4),
    area_politica_final_v0_4 = case_when(
      multi_por_nome_v04 & saude_explicita_no_nome_v04 ~ "saude",
      multi_por_nome_v04 ~ NA_character_,
      TRUE ~ area_politica_final_v0_4
    ),
    fonte_principal_v0_4 = case_when(
      multi_por_nome_v04 & saude_explicita_no_nome_v04 ~ "nome_MIDES_explicito",
      multi_por_nome_v04 ~ "perfil_por_nome",
      TRUE ~ fonte_principal_v0_4
    ),
    status_validacao_v0_4 = case_when(
      multi_por_nome_v04 & saude_explicita_no_nome_v04 ~ "validada_usuario_nome_explicito",
      multi_por_nome_v04 ~ "validada_usuario_perfil_sem_area",
      TRUE ~ status_validacao_v0_4
    ),
    decisao_usuario_v0_4 = if_else(multi_por_nome_v04, "multifinal_nome", decisao_usuario_v0_4),
    justificativa_v0_4 = case_when(
      multi_por_nome_v04 & saude_explicita_no_nome_v04 ~ "Perfil identificado pelo nome; alias MIDES explicita saude. Area atribuida de forma rastreavel, sem usar a uniao bruta MUNIC.",
      multi_por_nome_v04 ~ "Perfil institucional validado pelo nome. Sem termo tematico explicito, nenhuma area de politica publica foi inventada.",
      TRUE ~ justificativa_v0_4
    )
  )

# Filiais herdam o resultado atualizado da matriz da mesma raiz de oito digitos.
matrizes <- resultado |>
  filter(tipo_estabelecimento_v04 == "matriz") |>
  select(
    raiz_cnpj_8_v04,
    area_matriz_v04 = area_politica_final_v0_4,
    fonte_matriz_v04 = fonte_principal_v0_4,
    status_matriz_v04 = status_validacao_v0_4,
    perfil_matriz_v04 = perfil_institucional_v0_4
  )

resultado <- resultado |>
  left_join(matrizes, by = "raiz_cnpj_8_v04") |>
  mutate(
    herdar_matriz = status_validacao_v0_3 == "aguardar_matriz_filial",
    area_politica_final_v0_4 = if_else(herdar_matriz, area_matriz_v04, area_politica_final_v0_4),
    fonte_principal_v0_4 = if_else(herdar_matriz, "matriz_raiz_cnpj_8", fonte_principal_v0_4),
    status_validacao_v0_4 = if_else(herdar_matriz, "herdada_matriz", status_validacao_v0_4),
    perfil_institucional_v0_4 = if_else(herdar_matriz, perfil_matriz_v04, perfil_institucional_v0_4),
    decisao_usuario_v0_4 = if_else(herdar_matriz, "filial_matriz", decisao_usuario_v0_4),
    justificativa_v0_4 = if_else(herdar_matriz, paste0("Filial segue matriz pela raiz de oito digitos. Status da matriz na v0.4: ", status_matriz_v04, "."), justificativa_v0_4)
  )

resultado <- resultado |>
  mutate(
    macroarea_final_v0_4 = case_when(
      is.na(area_politica_final_v0_4) ~ NA_character_,
      area_politica_final_v0_4 == "saude" ~ "saude",
      TRUE ~ macroarea_final_v0_3
    )
  )

stopifnot(sum(resultado$herdar_matriz) == 2L)
stopifnot(sum(resultado$saude_explicita_no_nome_v04) == 7L)
stopifnot(sum(resultado$multi_por_nome_v04 & resultado$perfil_nome_v04 == "multifinalitario", na.rm = TRUE) == 19L)
stopifnot(sum(resultado$multi_por_nome_v04 & resultado$perfil_nome_v04 == "multissetorial", na.rm = TRUE) == 4L)
stopifnot(sum(resultado$multi_por_nome_v04 & resultado$perfil_nome_v04 == "perfil_sem_termo_explicito", na.rm = TRUE) == 0L)

analitica_completa <- resultado |>
  transmute(
    cnpj_consorcio,
    sigla,
    razao_social,
    situacao,
    ano_fundacao,
    area_politica_final = area_politica_final_v0_4,
    macroarea_final = macroarea_final_v0_4,
    perfil_institucional = perfil_institucional_v0_4,
    fonte_principal = fonte_principal_v0_4,
    status_validacao = status_validacao_v0_4,
    ativo_analise = ativo_analise_v0_4,
    decisao_usuario = decisao_usuario_v0_4,
    precisa_revisao = status_validacao_v0_4 %in% c("provisoria_coerente", "validada_usuario_perfil_sem_area"),
    justificativa = justificativa_v0_4
  ) |>
  arrange(!ativo_analise, sigla, razao_social)

analitica_ativa <- analitica_completa |>
  filter(ativo_analise)

resumo <- analitica_completa |>
  count(ativo_analise, status_validacao, fonte_principal, name = "n_cnpjs") |>
  arrange(!ativo_analise, desc(n_cnpjs), status_validacao)

out_tecnica <- file.path(out_dir, "classificacao_areas_politica_mg_v0_4_tecnica.csv")
out_completa <- file.path(out_dir, "classificacao_areas_politica_mg_v0_4_completa.csv")
out_ativa <- file.path(out_dir, "classificacao_areas_politica_mg_v0_4_analitica_ativa.csv")
out_rds <- file.path(out_dir, "classificacao_areas_politica_mg_v0_4_analitica_ativa.rds")
out_resumo <- file.path(out_dir, "resumo_classificacao_areas_politica_mg_v0_4.csv")

write_csv(resultado, out_tecnica, na = "")
write_csv(analitica_completa, out_completa, na = "")
write_csv(analitica_ativa, out_ativa, na = "")
saveRDS(analitica_ativa, out_rds)
write_csv(resumo, out_resumo, na = "")

cat("Classificacao v0.4 concluida.\n")
cat("  Universo completo:", nrow(analitica_completa), "CNPJs\n")
cat("  Camada ativa:", nrow(analitica_ativa), "CNPJs\n")
cat("  Excluidos inativos:", sum(!analitica_completa$ativo_analise), "CNPJs\n")
