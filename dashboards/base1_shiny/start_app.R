if (!l10n_info()[["UTF-8"]]) {
  try(Sys.setlocale("LC_CTYPE", "Portuguese_Brazil.utf8"), silent = TRUE)
}

app_dir <- normalizePath("dashboards/base1_shiny", winslash = "/", mustWork = TRUE)
shiny::runApp(app_dir, host = "127.0.0.1", port = 7788, launch.browser = FALSE)
