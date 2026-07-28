# =============================================================================
# scripts_viz.R — Charts para slide de apresentação
# Projeto: Painel longitudinal de participação municipal em consórcios — Piloto MG
# Equipe:  IPEA
# Criado:  2026-05-14
#
# Gera 5 PNGs em slides/assets/ (fundo transparente, 300 dpi)
# Execução: source("slides/scripts_viz.R")
# =============================================================================

library(tidyverse)
library(geobr)
library(scales)
library(patchwork)

# -----------------------------------------------------------------------------
# 0. Configuração — paths, paleta, theme
# -----------------------------------------------------------------------------

caminho_csv  <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/outputs/csv_base/"
caminho_out  <- "C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/slides/assets/"

# Paleta oficial IPEA
ipea <- list(
  azul_inst   = "#4F758B",   # Azul IPEA institucional — MIDES
  azul_escuro = "#3B5F6E",   # Azul fosco — SICONFI
  azul_logo   = "#173a50",   # Azul do logo — destaque/total (alinhado ao tema do slide)
  preto       = "#1E1F1F",   # Preto IPEA — texto
  verde       = "#62B426",   # Verde principal — confirmado
  verde_limao = "#AED51A",   # Verde-limão — MUNIC
  amarelo     = "#EBED07",   # Amarelo — pendente/alerta
  cinza       = "#D9D9D9"    # Cinza claro — contexto/fundo
)

# Theme base — fundo transparente para encaixar no template Signal
theme_mides <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.background      = element_rect(fill = "transparent", colour = NA),
      panel.background     = element_rect(fill = "transparent", colour = NA),
      legend.background    = element_rect(fill = "transparent", colour = NA),
      legend.key           = element_rect(fill = "transparent", colour = NA),
      plot.title           = element_text(face = "bold", size = base_size + 2,
                                          colour = ipea$preto),
      plot.title.position  = "plot",
      plot.subtitle        = element_text(colour = ipea$azul_escuro,
                                          size = base_size - 1),
      plot.caption         = element_text(colour = ipea$azul_escuro,
                                          size = base_size - 4),
      plot.caption.position = "plot",
      panel.grid.minor     = element_blank(),
      panel.grid.major     = element_line(colour = ipea$cinza, linewidth = 0.3),
      axis.ticks           = element_blank(),
      legend.position      = "none",
      text                 = element_text(colour = ipea$preto)
    )
}

# Helper para salvar com padrões do projeto
carregar_municipios_mg <- function() {
  dir_cache <- file.path(caminho_out, "geobr_cache")
  if (!dir.exists(dir_cache)) dir.create(dir_cache, recursive = TRUE)

  arquivo_cache <- file.path(dir_cache, "31municipality_2020_simplified.gpkg")
  url_github <- paste0(
    "https://github.com/ipeaGIT/geobr/releases/download/v1.7.0/",
    basename(arquivo_cache)
  )

  if (file.exists(arquivo_cache) && file.info(arquivo_cache)$size > 0) {
    cat("  Usando cache local:", arquivo_cache, "\n")
    mg_cache <- tryCatch(
      sf::st_read(arquivo_cache, quiet = TRUE),
      error = function(e) {
        message("  Cache local invalido: ", conditionMessage(e))
        NULL
      }
    )
    if (!is.null(mg_cache)) return(mg_cache)
    unlink(arquivo_cache)
  }
  if (file.exists(arquivo_cache)) unlink(arquivo_cache)

  mg_munic <- tryCatch(
    read_municipality(code_muni = "MG", year = 2020, showProgress = FALSE),
    error = function(e) {
      message("  geobr falhou: ", conditionMessage(e))
      NULL
    }
  )

  if (!is.null(mg_munic)) {
    sf::st_write(mg_munic, arquivo_cache, quiet = TRUE, delete_dsn = TRUE)
    return(mg_munic)
  }

  cat("  Baixando geometria MG do espelho GitHub do geobr...\n")
  timeout_antigo <- getOption("timeout")
  options(timeout = max(300, timeout_antigo))
  on.exit(options(timeout = timeout_antigo), add = TRUE)

  ok <- tryCatch(
    {
      utils::download.file(url_github, arquivo_cache, mode = "wb", quiet = TRUE)
      TRUE
    },
    error = function(e) {
      message("  Download alternativo falhou: ", conditionMessage(e))
      FALSE
    }
  )

  if (!ok || !file.exists(arquivo_cache) || file.info(arquivo_cache)$size == 0) {
    if (file.exists(arquivo_cache)) unlink(arquivo_cache)
    stop("Nao foi possivel carregar a geometria dos municipios de MG.")
  }

  sf::st_read(arquivo_cache, quiet = TRUE)
}

salvar <- function(p, nome, w = 10, h = 5.5) {
  caminho <- paste0(caminho_out, nome)
  ggsave(caminho, plot = p, width = w, height = h, dpi = 300, bg = "transparent")
  cat("  ✓ Salvo:", caminho, "\n")
}

# -----------------------------------------------------------------------------
# 1. Carregar dados
# -----------------------------------------------------------------------------

cat("Carregando CSVs...\n")

# ⚠️ col_types explícito para colunas de código:
# CNPJs (14 dígitos) e códigos IBGE têm zeros à esquerda e excedem a precisão
# de double — sem col_character() o read_csv pode converter para notação
# científica e perder dígitos (ex: "05802877000110" → 5.802877e+12).
tipos_univ <- cols(
  cnpj_consorcio = col_character(),
  cod_ibge_6     = col_character(),
  id_municipio   = col_character()
)

univ <- read_csv(
  paste0(caminho_csv, "2026-05-21_painel_universal_mg_v2.csv"),
  col_types = tipos_univ
)

# flag_continuo só existe no v1 — enriquecer o universal via join
# TODO (dívida técnica): incluir flag_continuo no script 05 para evitar join externo
v1_flags <- read_csv(
  paste0(caminho_csv, "2026-05-13_csv_base_mides_mg_v1.csv"),
  col_types = cols(
    cnpj_consorcio = col_character(),
    cod_ibge       = col_character()
  )
) |>
  mutate(cod_ibge_6 = substr(cod_ibge, 1, 6)) |>
  select(cod_ibge_6, cnpj_consorcio, flag_continuo)

univ <- univ |>
  left_join(v1_flags, by = join_by(cod_ibge_6, cnpj_consorcio))

cat("  painel_universal_mg_v2:", nrow(univ), "pares ×", ncol(univ), "colunas\n")

# Subconjunto apenas pares com MIDES
mides_pares <- univ |> filter(pontuacao_mides > 0)
cat("  Pares com MIDES:", nrow(mides_pares), "\n\n")

# =============================================================================
# CHART 1 — cobertura_fontes.png
# "161 de 223 consórcios MG têm pagamento confirmado pelo MIDES"
# =============================================================================

cat("Chart 1: cobertura_fontes.png\n")

cobertura <- tibble(
  fonte  = factor(
    c("Cadastro MG\n(universo)", "MIDES\n(pagamento fiscal)", "SICONFI\n(rubrica federal)", "MUNIC\n(autodeclaração)", "CNM\n(plataforma)"),
    levels = c("CNM\n(plataforma)", "MUNIC\n(autodeclaração)", "SICONFI\n(rubrica federal)", "MIDES\n(pagamento fiscal)", "Cadastro MG\n(universo)")
  ),
  n      = c(223, 153, 163, 149, 135),
  status = c("total", "confirmado", "confirmado", "confirmado", "cnm"),
  label  = c("223", "153", "163", "149", "135")
)

p1 <- ggplot(cobertura, aes(x = n, y = fonte, fill = status)) +
  geom_col(width = 0.6, na.rm = TRUE) +
  geom_text(
    aes(label = label), hjust = -0.15,
    size = 13, size.unit = "pt", fontface = "bold",
    colour = ipea$preto
  ) +

  scale_fill_manual(values = c(
    "total"      = ipea$azul_logo,
    "confirmado" = ipea$azul_inst,
    "cnm"        = ipea$verde
  )) +
  scale_x_continuous(
    limits = c(0, 280),
    expand = expansion(mult = c(0, 0)),
    guide  = guide_axis(check.overlap = TRUE)
  ) +
  labs(
    title    = "135–163 dos 223 consórcios MG confirmados em pelo menos uma fonte",
    subtitle = "Cobertura por fonte | Piloto Minas Gerais",
    caption  = "MIDES: 2014–2021 · SICONFI: 2013–2024 · MUNIC: 2015 e 2019 · CNM: 1978–2025 · 3.380 pares · painel_v2",
    x = NULL, y = NULL
  ) +
  theme_mides()

salvar(p1, "cobertura_fontes.png", w = 10, h = 4.5)

# =============================================================================
# CHART 2 — eda_distribuicao.png  (patchwork: 2 painéis)
# "Saúde domina — os maiores consórcios reúnem 150+ municípios"
# =============================================================================

cat("Chart 2: eda_distribuicao.png\n")

# Painel A: top 10 consórcios por nº de municípios pagantes (MIDES)
top_cons <- mides_pares |>
  summarise(n_municipios = n(), .by = c(cnpj_consorcio, sigla, razao_social)) |>
  slice_max(n_municipios, n = 10) |>
  mutate(
    label_cons = coalesce(sigla, substr(razao_social, 1, 22)),
    label_cons = fct_reorder(label_cons, n_municipios)
  )

pA <- ggplot(top_cons, aes(x = n_municipios, y = label_cons)) +
  geom_col(fill = ipea$azul_inst, width = 0.7) +
  geom_text(aes(label = n_municipios), hjust = -0.2,
            size = 10, size.unit = "pt", colour = ipea$preto) +
  scale_x_continuous(
    expand = expansion(mult = c(0, 0.2)),
    guide  = guide_axis(check.overlap = TRUE)
  ) +
  labs(
    title    = "Top 10 consórcios\npor nº de municípios pagantes",
    subtitle = "Fonte: MIDES (2014–2021)",
    x = "Municípios", y = NULL
  ) +
  theme_mides(base_size = 11)

# Painel B: top 5 setores no MUNIC (dados confirmados no EDA da Etapa 7)
setores_munic <- tibble(
  setor = factor(
    c("Saúde", "Resíduos sólidos", "Des. urbano", "Saneamento", "Meio ambiente"),
    levels = c("Meio ambiente", "Saneamento", "Des. urbano", "Resíduos sólidos", "Saúde")
  ),
  n   = c(869L, 263L, 179L, 156L, 155L),
  pct = c(0.645, 0.195, 0.133, 0.116, 0.115)
)

pB <- ggplot(setores_munic, aes(x = n, y = setor)) +
  geom_col(fill = ipea$verde, width = 0.7) +
  geom_text(aes(label = paste0(n, "  (", round(pct * 100), "%)")), hjust = -0.1,
            size = 10, size.unit = "pt", colour = ipea$preto) +
  scale_x_continuous(
    limits = c(0, 1100),
    expand = expansion(mult = c(0, 0)),
    guide  = guide_axis(check.overlap = TRUE)
  ) +
  labs(
    title    = "Top 5 setores — pares\nconfirmados pelo MUNIC",
    subtitle = "1.348 pares declarados | 2015 e 2019",
    x = "Pares confirmados", y = NULL
  ) +
  theme_mides(base_size = 11)

# Painel C: macro-áreas temáticas CNM (OR entre sub-áreas, EDA 2026-05-21)
# Fonte: join painel_v2 (cnm_confirma=TRUE) × base_unificada_municipio_consorcio.csv
# Lógica OR: par conta no grupo se qualquer sub-área do grupo = 1
areas_cnm <- tibble(
  area = factor(c(
    "Saúde",
    "Saneamento",
    "Iluminação pública",
    "Meio ambiente",
    "Agricultura",
    "Infraestrutura",
    "Desenv. regional",
    "Licitação compartilhada"
  ), levels = rev(c(
    "Saúde",
    "Saneamento",
    "Iluminação pública",
    "Meio ambiente",
    "Agricultura",
    "Infraestrutura",
    "Desenv. regional",
    "Licitação compartilhada"
  ))),
  n = c(1707L, 880L, 704L, 702L, 700L, 546L, 516L, 499L),
  grupo = c("saude","saneamento","outro","meio_amb","outro","outro","outro","outro")
)

pC <- ggplot(areas_cnm, aes(x = n, y = area, fill = grupo)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = n), hjust = -0.2,
            size = 10, size.unit = "pt", colour = ipea$preto) +
  scale_fill_manual(values = c(
    "saude"      = ipea$azul_logo,
    "saneamento" = ipea$azul_inst,
    "meio_amb"   = ipea$verde,
    "outro"      = ipea$azul_escuro
  )) +
  scale_x_continuous(
    limits = c(0, 2100),
    expand = expansion(mult = c(0, 0)),
    guide  = guide_axis(check.overlap = TRUE)
  ) +
  labs(
    title    = "Macro-áreas temáticas — CNM",
    subtitle = "Pares por grupo (OR entre sub-áreas) · 2.657 pares CNM",
    x = "Pares confirmados", y = NULL
  ) +
  theme_mides(base_size = 11)

p2 <- pA + pB + pC +
  plot_annotation(
    title   = "Saúde domina — e os maiores consórcios reúnem 150+ municípios",
    caption = "MIDES: municípios com pagamento efetivo · MUNIC: declarantes por setor · CNM: pares com cnm_confirma=TRUE",
    theme   = theme_mides()
  )

salvar(p2, "eda_distribuicao.png", w = 18, h = 5.5)

# =============================================================================
# CHART 3 — eda_valor.png
# "Mediana R$219k — mas a dispersão vai de R$49 a R$264M"
# =============================================================================

cat("Chart 3: eda_valor.png\n")

# Identificar outlier dinamicamente
outlier <- mides_pares |>
  filter(!is.na(valor_total_periodo)) |>
  slice_max(valor_total_periodo, n = 1)

# Identificar top 5 para rotular
top5_valor <- mides_pares |>
  filter(!is.na(valor_total_periodo)) |>
  slice_max(valor_total_periodo, n = 5) |>
  mutate(label = paste0(coalesce(sigla, substr(razao_social, 1, 15)),
                        "\n", label_number(scale = 1e-6, suffix = "M", big.mark = ".",
                                           decimal.mark = ",")(valor_total_periodo)))

dados_valor <- mides_pares |>
  filter(!is.na(valor_total_periodo), valor_total_periodo > 0) |>
  mutate(destaque = cnpj_consorcio %in% top5_valor$cnpj_consorcio &
           cod_ibge_6 %in% top5_valor$cod_ibge_6)

p3 <- ggplot(dados_valor, aes(x = valor_total_periodo, y = 0)) +
  # Todos os pontos em cinza médio (D9D9D9 era claro demais — ficava invisível empilhado)
  geom_jitter(
    data   = filter(dados_valor, !destaque),
    height = 0.35, alpha = 0.15, size = 0.9,
    colour = "#888888"
  ) +
  # Top 5 em destaque
  geom_jitter(
    data   = filter(dados_valor, destaque),
    height = 0.1, size = 3,
    colour = ipea$azul_logo
  ) +
  # Rótulo do outlier máximo
  geom_text(
    data = outlier,
    aes(label = paste0(coalesce(sigla, ""), "\nR$",
                       label_number(scale = 1e-6, suffix = "M",
                                    decimal.mark = ",")(valor_total_periodo))),
    y = 0.55, hjust = 0.5,
    size = 10, size.unit = "pt", colour = ipea$azul_logo, fontface = "bold"
  ) +
  # Linha de mediana
  geom_vline(
    xintercept = median(dados_valor$valor_total_periodo, na.rm = TRUE),
    linetype = "dashed", colour = ipea$verde, linewidth = 0.8
  ) +
  annotate("text",
    x     = median(dados_valor$valor_total_periodo, na.rm = TRUE),
    y     = -0.55,
    label = paste0("mediana\nR$ ", label_number(
      scale = 1e-3, suffix = "k", big.mark = ".", decimal.mark = ","
    )(median(dados_valor$valor_total_periodo, na.rm = TRUE))),
    hjust = -0.1, vjust = 1,
    size = 9, size.unit = "pt", colour = ipea$verde
  ) +
  scale_x_log10(
    labels = label_number(scale = 1e-3, suffix = "k", big.mark = ".", decimal.mark = ","),
    guide  = guide_axis(check.overlap = TRUE)
  ) +
  scale_y_continuous(limits = c(-0.8, 0.8)) +
  labs(
    title    = "Mediana de R$219k — mas a dispersão vai de R$49 a R$264M",
    subtitle = "Valor total pago por par município × consórcio (R$ deflacionado jan/2018, escala log)",
    caption  = "Fonte: MIDES via BigQuery · IPCA base jan/2018 · 32 pares com valor < R$1.000 (adesão simbólica)",
    x = "Valor total no período (R$, escala log)", y = NULL
  ) +
  theme_mides() +
  theme(
    axis.text.y        = element_blank(),
    panel.grid.major.y = element_blank()
  )

salvar(p3, "eda_valor.png", w = 11, h = 4)

# =============================================================================
# CHART 4 — hist_pontuacao.png
# "85% dos pares confirmados por 2+ fontes — 69% sem interrupção"
# =============================================================================

cat("Chart 4: hist_pontuacao.png\n")

# painel_v2 já tem pontuacao_total na escala correta (MIDES=8, SICONFI=4, MUNIC=2, CNM=1)
univ_pts <- univ |>
  mutate(pontuacao_nova = pontuacao_total)

# Rótulo descritivo de cada combinação — escala geométrica (15 combinações)
label_combo <- c(
  "15" = "M+S+U+C",
  "14" = "M+S+U",
  "13" = "M+S+C",
  "12" = "M+S",
  "11" = "M+U+C",
  "10" = "M+U",
  "9"  = "M+C",
  "8"  = "só M",
  "7"  = "S+U+C",
  "6"  = "S+U",
  "5"  = "S+C",
  "4"  = "só S",
  "3"  = "U+C",
  "2"  = "só U",
  "1"  = "só C"
)

pontuacao_dist <- univ_pts |>
  count(pontuacao_nova) |>
  mutate(
    pct       = n / sum(n),
    pts_f     = factor(pontuacao_nova, levels = 15:1),
    combo     = label_combo[as.character(pontuacao_nova)],
    cor_faixa = case_when(
      pontuacao_nova == 15 ~ ipea$azul_logo,
      pontuacao_nova %in% c(13,14) ~ ipea$azul_inst,
      pontuacao_nova %in% c(11,12) ~ ipea$azul_escuro,
      pontuacao_nova %in% c(9,10)  ~ ipea$verde,
      pontuacao_nova ==  8 ~ ipea$verde_limao,
      TRUE                 ~ "#AAAAAA"   # cinza médio visível em fundo branco
    )
  )

# Legenda lateral: uma linha por nível de confiança
legend_df <- tibble(
  y_frac = c(0.97, 0.87, 0.77, 0.67, 0.57, 0.47),
  cor    = c(ipea$azul_logo, ipea$azul_inst, ipea$azul_escuro, ipea$verde, ipea$verde_limao, "#AAAAAA"),
  label  = c(
    "■ 15 pts  M+S+U+C  (8+4+2+1)  — padrão-ouro",
    "■ 13–14 pts  M+S+U / M+S+C",
    "■ 11–12 pts  M+U+C / M+S",
    "■  9–10 pts  M+C / M+U",
    "■   8 pts  só MIDES",
    "■  1–7 pts  sem MIDES  (só CNM, SICONFI, MUNIC)"
  )
)
ymax <- max(pontuacao_dist$n)
n_niveis <- nlevels(pontuacao_dist$pts_f)

p4 <- ggplot(pontuacao_dist, aes(x = pts_f, y = n, fill = cor_faixa)) +
  geom_col(width = 0.72, show.legend = FALSE) +
  # Rótulo n + % no topo de cada barra
  geom_text(
    aes(label = paste0(n, "\n(", percent(pct, accuracy = 0.1), ")")),
    vjust = -0.3,
    size = 9, size.unit = "pt", colour = ipea$preto
  ) +
  # Rótulo da combinação abaixo do eixo-x (como subtítulo por barra)
  geom_text(
    aes(label = combo, y = -ymax * 0.04),
    vjust = 1, size = 8, size.unit = "pt", colour = "#555555"
  ) +
  scale_fill_identity() +
  scale_y_continuous(expand = expansion(mult = c(0.12, 0.18))) +
  # Legenda lateral
  annotate("text",
    x     = rep(n_niveis + 0.6, nrow(legend_df)),
    y     = legend_df$y_frac * ymax,
    label = legend_df$label,
    hjust = 0, size = 8.5, size.unit = "pt",
    colour = legend_df$cor
  ) +
  labs(
    title    = "90% dos pares confirmados por 2 ou mais fontes independentes",
    subtitle = "Distribuição de pontuação geométrica (MIDES=8, SICONFI=4, MUNIC=2, CNM=1) · 3.380 pares",
    caption  = "Pesos em progressão geométrica (÷2): garantem que nenhuma fonte secundária compense a ausência de MIDES · Máx: 15 pts · painel_universal_mg_v2",
    x = "Pontuação total", y = "Nº de pares"
  ) +
  theme_mides() +
  theme(
    plot.margin    = margin(t = 5, r = 200, b = 20, l = 5),
    axis.text.x    = element_text(size = 10)
  ) +
  coord_cartesian(clip = "off")

salvar(p4, "hist_pontuacao.png", w = 13, h = 6)

# =============================================================================
# CHART 5 — codap_map.png
# "CODAP: 5 municípios com confiança máxima, 20 no total"
# =============================================================================

cat("Chart 5: codap_map.png (carregando geobr...)\n")

mg_munic <- carregar_municipios_mg()

# Pares do CODAP
cnpj_codap <- "08753385000170"

codap_pares <- univ |>
  filter(cnpj_consorcio == cnpj_codap) |>
  select(cod_ibge_6, pontuacao_total, pontuacao_mides, pontuacao_siconfi,
         pontuacao_munic, pontuacao_cnm) |>
  rowwise() |>
  mutate(
    fontes = paste(
      c("MIDES", "SICONFI", "MUNIC", "CNM")[
        c(pontuacao_mides > 0, pontuacao_siconfi > 0,
          pontuacao_munic > 0, pontuacao_cnm > 0)
      ],
      collapse = " + "
    ),
    pts_label = paste0(pontuacao_total, ifelse(pontuacao_total == 1, " pt · ", " pts · "), fontes)
  ) |>
  ungroup()

codap_legenda <- codap_pares |>
  distinct(pontuacao_total, pts_label) |>
  arrange(desc(pontuacao_total)) |>
  mutate(
    cor = case_when(
      pontuacao_total == 15 ~ ipea$azul_logo,
      pontuacao_total %in% c(13, 14) ~ ipea$azul_inst,
      pontuacao_total %in% c(11, 12) ~ ipea$azul_escuro,
      pontuacao_total %in% c(9, 10) ~ ipea$verde,
      pontuacao_total == 8 ~ ipea$verde_limao,
      TRUE ~ ipea$amarelo
    )
  )

# Join com geometria MG
mg_codap <- mg_munic |>
  mutate(cod_ibge_6 = substr(as.character(code_muni), 1, 6)) |>
  left_join(codap_pares, by = join_by(cod_ibge_6)) |>
  mutate(
    pts_label = ifelse(is.na(pts_label), "Não membro", pts_label),
    pts_label = factor(pts_label, levels = c(
      codap_legenda$pts_label,
      "Não membro"
    ))
  )

# Calcular centroide dinâmico do cluster CODAP para anotar no mapa
codap_centroide <- mg_codap |>
  filter(pts_label != "Não membro") |>
  sf::st_union() |>
  sf::st_centroid() |>
  sf::st_coordinates()

codap_municipios <- mg_codap |>
  sf::st_drop_geometry() |>
  filter(pts_label != "Não membro") |>
  transmute(
    pontuacao_total,
    pts_label = as.character(pts_label),
    municipio = stringr::str_to_title(name_muni)
  ) |>
  arrange(desc(pontuacao_total), municipio)

codap_tabela <- codap_municipios |>
  group_by(pontuacao_total, pts_label) |>
  summarise(
    n = n(),
    municipios = stringr::str_wrap(paste(municipio, collapse = ", "), width = 38),
    .groups = "drop"
  ) |>
  arrange(desc(pontuacao_total)) |>
  mutate(
    fontes = stringr::str_replace(pts_label, "^[0-9]+ pts? · ", ""),
    cor = codap_legenda$cor[match(pontuacao_total, codap_legenda$pontuacao_total)],
    n_linhas_municipios = stringr::str_count(municipios, "\n") + 1,
    altura = pmax(2.25, 1.45 + 0.38 * n_linhas_municipios),
    topo = cumsum(altura),
    ymin = max(topo) - topo + 0.15,
    ymax = ymin + altura - 0.22,
    y_score = ymax - 0.52,
    y_fontes = ymax - 1.02,
    y_municipios = ymax - 1.52,
    score_label = paste0(pontuacao_total, ifelse(pontuacao_total == 1, " ponto", " pontos"), "  |  ", n, " mun.")
  )

p5_mapa <- ggplot(mg_codap) +
  geom_sf(aes(fill = pts_label), colour = "white", linewidth = 0.08) +
  # Rótulo "CODAP" com seta apontando para o cluster
  annotate("text",
    x = codap_centroide[1], y = codap_centroide[2] + 1.2,
    label = "CODAP", fontface = "bold",
    size = 11, size.unit = "pt", colour = ipea$azul_logo
  ) +
  annotate("segment",
    x    = codap_centroide[1], xend = codap_centroide[1],
    y    = codap_centroide[2] + 1.05, yend = codap_centroide[2] + 0.2,
    colour = ipea$azul_logo, linewidth = 0.6,
    arrow = arrow(length = unit(0.2, "cm"), type = "closed")
  ) +
  scale_fill_manual(
    values = c(setNames(codap_legenda$cor, codap_legenda$pts_label),
               "Não membro" = ipea$cinza),
    breaks = codap_legenda$pts_label,
    name = "Legenda do mapa"
  ) +
  guides(fill = "none") +
  labs(
    title    = "CODAP — membros com pontuação triangulada (escala máx. 15 pts)",
    subtitle = "Minas Gerais | CNPJ 08.753.385/0001-70",
    caption  = "Fontes: MIDES · SICONFI · MUNIC · geobr (IBGE 2020)"
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.background     = element_rect(fill = "transparent", colour = NA),
    legend.background   = element_rect(fill = "transparent", colour = NA),
    legend.key          = element_rect(fill = "transparent", colour = NA),
    plot.title          = element_text(face = "bold", size = 18,
                                       colour = ipea$preto, hjust = 0),
    plot.title.position = "plot",
    plot.subtitle       = element_text(colour = ipea$azul_escuro,
                                       size = 15, hjust = 0),
    plot.caption        = element_text(colour = ipea$azul_escuro,
                                       size = 13, hjust = 0),
    plot.caption.position = "plot",
    legend.position     = "none",
    legend.justification = "left",
    legend.box.just     = "left",
    legend.direction    = "horizontal",
    legend.box          = "horizontal",
    legend.margin       = margin(t = 2, r = 0, b = 0, l = 0),
    legend.title        = element_text(size = 9, face = "bold", colour = ipea$preto),
    legend.text         = element_text(size = 8, colour = ipea$preto),
    legend.key.size     = unit(0.45, "cm")
  )

codap_legenda_plot <- codap_legenda |>
  mutate(
    x = rep(c(0.04, 0.52), length.out = n()),
    y = rep(c(0.58, 0.24), each = 2, length.out = n())
  )

p5_legenda <- ggplot(codap_legenda_plot) +
  annotate(
    "text", x = 0.04, y = 0.92,
    label = "Legenda do mapa",
    hjust = 0, fontface = "bold", size = 4.25,
    colour = ipea$preto
  ) +
  geom_rect(
    aes(xmin = x, xmax = x + 0.035, ymin = y - 0.07, ymax = y + 0.07, fill = cor),
    colour = NA
  ) +
  geom_text(
    aes(x = x + 0.05, y = y, label = pts_label),
    hjust = 0, size = 3.8, colour = ipea$preto
  ) +
  scale_fill_identity() +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), clip = "off") +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "transparent", colour = NA),
    plot.margin = margin(t = 0, r = 10, b = 0, l = 5)
  )

p5_tabela <- ggplot() +
  geom_rect(
    data = codap_tabela,
    aes(xmin = 0, xmax = 1, ymin = ymin, ymax = ymax),
    fill = "#FFFFFF", colour = "#E3E7E8", linewidth = 0.25
  ) +
  geom_rect(
    data = codap_tabela,
    aes(xmin = 0, xmax = 0.035, ymin = ymin, ymax = ymax, fill = cor),
    colour = NA
  ) +
  annotate(
    "text", x = 0, y = max(codap_tabela$ymax) + 0.55,
    label = "Legenda e municípios",
    hjust = 0, fontface = "bold", size = 4.4,
    colour = ipea$preto
  ) +
  geom_text(
    data = codap_tabela,
    aes(x = 0.065, y = y_score, label = score_label, colour = cor),
    hjust = 0, fontface = "bold", size = 4.05, lineheight = 0.95
  ) +
  geom_text(
    data = codap_tabela,
    aes(x = 0.065, y = y_fontes, label = paste0("Fontes: ", fontes)),
    hjust = 0, size = 3.35, colour = ipea$azul_escuro, lineheight = 0.95
  ) +
  geom_text(
    data = codap_tabela,
    aes(x = 0.065, y = y_municipios, label = municipios),
    hjust = 0, vjust = 1, size = 3.25, colour = ipea$preto, lineheight = 0.92
  ) +
  annotate(
    "text", x = 0, y = -0.12,
    label = "Escala: MIDES=8 · SICONFI=4 · MUNIC=2 · CNM=1\nNo CODAP não há casos só MIDES (8 pts) nem só MUNIC (2 pts).",
    hjust = 0, vjust = 1, size = 3.25, colour = ipea$azul_escuro, lineheight = 0.95
  ) +
  scale_fill_identity() +
  scale_colour_identity() +
  coord_cartesian(xlim = c(0, 1), ylim = c(-0.8, max(codap_tabela$ymax) + 0.85), clip = "off") +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "transparent", colour = NA),
    plot.margin = margin(t = 35, r = 10, b = 30, l = 5)
  )

# Zoom inset: calcular bbox dos municípios membros do CODAP
codap_bbox <- mg_codap |>
  filter(pts_label != "Não membro") |>
  sf::st_bbox()

pad <- 0.8   # graus de padding ao redor do cluster
zoom_xlim <- c(codap_bbox["xmin"] - pad, codap_bbox["xmax"] + pad)
zoom_ylim <- c(codap_bbox["ymin"] - pad, codap_bbox["ymax"] + pad)

# Zoom inset: mapa da região CODAP sem rótulos de município (cores falam por si)
p5_zoom <- ggplot(mg_codap) +
  geom_sf(aes(fill = pts_label), colour = "white", linewidth = 0.3) +
  coord_sf(xlim = zoom_xlim, ylim = zoom_ylim, expand = FALSE) +
  scale_fill_manual(
    values = c(setNames(codap_legenda$cor, codap_legenda$pts_label),
               "Não membro" = "#E8ECEE"),
    breaks = codap_legenda$pts_label
  ) +
  guides(fill = "none") +
  labs(title = "Detalhe — municípios membros") +
  theme_void(base_size = 9) +
  theme(
    plot.background = element_rect(fill = "white", colour = ipea$azul_logo,
                                   linewidth = 1.5),
    plot.margin     = margin(4, 4, 4, 4),
    plot.title      = element_text(face = "bold", size = 8, colour = ipea$preto,
                                   hjust = 0.5, margin = margin(t = 3, b = 2))
  )

# Adicionar retângulo de referência e seta no mapa principal apontando para o zoom
p5_mapa <- p5_mapa +
  # Retângulo dashed ao redor da área CODAP (mesmos limites do zoom)
  annotate("rect",
    xmin = zoom_xlim[1], xmax = zoom_xlim[2],
    ymin = zoom_ylim[1], ymax = zoom_ylim[2],
    colour = ipea$azul_logo, fill = NA, linewidth = 0.7,
    linetype = "dashed"
  ) +
  # Seta saindo do canto inferior-direito do retângulo apontando para o inset
  annotate("segment",
    x    = zoom_xlim[2],       y    = zoom_ylim[1],
    xend = zoom_xlim[2] + 0.8, yend = zoom_ylim[1] - 1.1,
    colour = ipea$azul_logo, linewidth = 0.7,
    arrow = arrow(length = unit(0.22, "cm"), type = "closed")
  )

# Mapa principal com inset sobreposto no canto inferior direito
p5_mapa_com_zoom <- p5_mapa +
  inset_element(p5_zoom, left = 0.56, bottom = 0.0, right = 1.0, top = 0.45,
                align_to = "plot")

p5 <- p5_mapa_com_zoom + p5_tabela + p5_legenda +
  plot_layout(
    design = "
    AB
    CB
    ",
    widths = c(2.2, 1),
    heights = c(6.8, 1.05),
    guides = "keep"
  ) +
  plot_annotation(
    theme = theme(
      plot.background  = element_rect(fill = "transparent", colour = NA),
      panel.background = element_rect(fill = "transparent", colour = NA)
    )
  )

salvar(p5, "codap_map.png", w = 18, h = 9)

# =============================================================================
# Fim
# =============================================================================

cat("\n✅ Todos os 5 charts gerados em:\n  ", caminho_out, "\n")
cat("\nArquivos:\n")
cat("  cobertura_fontes.png  — slide 5\n")
cat("  eda_distribuicao.png  — slide 5b\n")
cat("  eda_valor.png         — slide 5c\n")
cat("  hist_pontuacao.png    — slide 6\n")
cat("  codap_map.png         — slide 7\n")
