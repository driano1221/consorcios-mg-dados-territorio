source_dir <- normalizePath("dashboards/base1_shiny", winslash = "/", mustWork = TRUE)

app_files <- c(
  "app.R",
  "documentacao_movimentos.R",
  "README.md",
  "start_app.R",
  "www/IPEA-LOGO.png",
  "www/exposicao_espacial_mides.png",
  "www/pipeline_movimentos_mides.png",
  "data/base_1_validacao_siconfi_reconstruido_2015_2019.rds",
  "data/base_1_vinculos_2015_2019.rds",
  "data/cadastro_base.rds",
  "data/classificacao_areas_politica_mg_v0_5.rds",
  "data/mg_contorno_sf_web.rds",
  "data/mg_municipios_sf_web.rds",
  "data/mides_municipios_lookup.rds",
  "data/painel_mg_anual.rds"
)

app_dir <- "C:/_ideiaMides_deploy/base1_shiny"
if (dir.exists(app_dir)) unlink(app_dir, recursive = TRUE, force = TRUE)
dir.create(app_dir, recursive = TRUE, showWarnings = FALSE)

for (app_file in app_files) {
  src <- file.path(source_dir, app_file)
  dst <- file.path(app_dir, app_file)
  dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(src, dst, overwrite = TRUE, recursive = TRUE)
  if (!ok) stop("Falha ao preparar arquivo para deploy: ", app_file)
}

rsconnect::deployApp(
  appDir = app_dir,
  appFiles = app_files,
  appName = "base1-mides-munic-siconfi",
  account = "kl5ug0-adriano-pires",
  forceUpdate = TRUE
)
