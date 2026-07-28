app_dir <- normalizePath("dashboards/base1_shiny", winslash = "/", mustWork = TRUE)
shiny::runApp(app_dir, host = "127.0.0.1", port = 7788, launch.browser = FALSE)
