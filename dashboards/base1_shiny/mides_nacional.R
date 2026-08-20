# Camada nacional do MIDES. Este modulo nao altera a Base 1 nem os modelos MG.

rotulos_evento_nacional <- c(
  base_ou_reinicio_cobertura = "Base ou reinicio da cobertura",
  entrada_observada = "Entrada observada",
  retorno_observado = "Retorno observado",
  permaneceu = "Permaneceu",
  saida_observada = "Saida observada",
  ausente = "Ausente",
  sem_comparacao_temporal = "Sem comparacao temporal"
)

paleta_evento_nacional <- c(
  "Sem registro" = "#f1f3f4",
  "Base ou reinicio da cobertura" = "#9ecae1",
  "Entrada observada" = "#2b8cbe",
  "Retorno observado" = "#756bb1",
  "Permaneceu" = "#238b45",
  "Saida observada" = "#e07a2f",
  "Misto" = "#777777"
)

formatar_lista_html <- function(x, vazio = "Nenhum municipio.", limite = 120L) {
  x <- sort(unique(na.omit(as.character(x))))
  x <- x[nzchar(x)]
  if (length(x) == 0L) return(paste0("<span>", vazio, "</span>"))
  itens <- paste0("<li>", htmltools::htmlEscape(head(x, limite)), "</li>", collapse = "")
  complemento <- if (length(x) > limite) {
    paste0("<p>", length(x) - limite, " municipios adicionais omitidos.</p>")
  } else ""
  paste0("<ul>", itens, "</ul>", complemento)
}

html_timeline_cobertura_nacional <- function(cobertura) {
  anos_globais <- seq(min(cobertura$ano_min), max(cobertura$ano_max))
  cabecalho <- paste0("<span>", anos_globais, "</span>", collapse = "")
  linhas <- vapply(seq_len(nrow(cobertura)), function(i) {
    row <- cobertura[i, ]
    anos <- as.integer(strsplit(row$anos, ";", fixed = TRUE)[[1]])
    celulas <- paste0(
      "<i class='", ifelse(anos_globais %in% anos, "covered", "gap"),
      "' title='", row$uf_municipio_pagador, " | ", anos_globais,
      ifelse(anos_globais %in% anos, " | com registro na extracao", " | sem registro na extracao"),
      "'></i>", collapse = ""
    )
    paste0(
      "<div class='coverage-state'><strong>", row$uf_municipio_pagador, "</strong>",
      "<span>", row$n_anos, " anos</span></div>",
      "<div class='coverage-cells'>", celulas, "</div>"
    )
  }, character(1))
  paste0(
    "<div class='coverage-scroll'><div class='coverage-chart'>",
    "<div></div><div class='coverage-years'>", cabecalho, "</div>",
    paste0(linhas, collapse = ""),
    "</div></div>",
    "<div class='coverage-legend'><span><i class='covered'></i>Ano encontrado</span>",
    "<span><i class='gap'></i>Sem registro na extracao</span></div>"
  )
}

plot_mides_nacional <- function(mapa, estados, brasil, metrica, anos, interativo = TRUE) {
  nomes <- c(
    valor_total = "Valor total MIDES", valor_corrente = "Valor corrente",
    n_consorcios = "Numero de consorcios", n_transacoes = "Numero de transacoes"
  )
  niveis <- levels(mapa$mapa_classe)
  niveis_ativos <- setdiff(niveis, "Sem registro")
  cores_ativas <- grDevices::colorRampPalette(c("#edf6ee", "#a8d79b", "#4ca66a", "#17623a"))(max(1L, length(niveis_ativos)))
  cores <- c("Sem registro" = "#eef1f2", setNames(cores_ativas, niveis_ativos))
  anos_txt <- if (length(anos) > 8L) {
    paste0(min(as.integer(anos)), "-", max(as.integer(anos)), " (", length(anos), " anos selecionados)")
  } else {
    paste(anos, collapse = ", ")
  }
  p <- ggplot() +
    geom_sf(data = brasil, fill = "#ffffff", colour = "#8b989e", linewidth = 0.35) +
    {
      if (interativo) {
        ggiraph::geom_sf_interactive(
          data = mapa,
          aes(fill = mapa_classe, tooltip = tooltip, data_id = id_municipio),
          colour = "#ffffff", linewidth = 0.08
        )
      } else {
        geom_sf(
          data = mapa, aes(fill = mapa_classe),
          colour = "#ffffff", linewidth = 0.08
        )
      }
    } +
    geom_sf(data = estados, fill = NA, colour = "#425b67", linewidth = 0.42) +
    scale_fill_manual(values = cores, drop = FALSE, name = unname(nomes[metrica])) +
    coord_sf(datum = NA) +
    labs(
      title = "MIDES nacional: intensidade municipal",
      subtitle = paste0("UFs com correspondencia no cadastro IPEA | periodo: ", anos_txt),
      caption = "Fonte: MIDES/Base dos Dados; cadastro IPEA consolidado por raiz do CNPJ. A UF representa o municipio pagador."
    ) +
    theme_mapa_limpo() +
    theme(plot.title = element_text(size = 17), plot.subtitle = element_text(size = 9))
  p
}

plot_movimento_nacional <- function(mapa, estados, brasil, ano, interativo = TRUE) {
  p <- ggplot() +
    geom_sf(data = brasil, fill = "#ffffff", colour = "#8b989e", linewidth = 0.35) +
    {
      if (interativo) {
        ggiraph::geom_sf_interactive(
          data = mapa,
          aes(fill = movimento_mapa, tooltip = tooltip, data_id = id_municipio),
          colour = "#ffffff", linewidth = 0.08
        )
      } else {
        geom_sf(data = mapa, aes(fill = movimento_mapa), colour = "#ffffff", linewidth = 0.08)
      }
    } +
    geom_sf(data = estados, fill = NA, colour = "#425b67", linewidth = 0.42) +
    scale_fill_manual(values = paleta_evento_nacional, drop = FALSE, name = "Movimento predominante") +
    coord_sf(datum = NA) +
    labs(
      title = paste0("Movimentos financeiros observados em ", ano),
      subtitle = "Comparacao apenas quando a UF tambem possui cobertura no ano imediatamente anterior",
      caption = "Presenca significa valor total MIDES positivo para o municipio e a raiz CNPJ; nao representa adesao juridica."
    ) +
    theme_mapa_limpo() +
    theme(plot.title = element_text(size = 17), plot.subtitle = element_text(size = 9))
  p
}

html_trajetoria_nacional_compacta <- function(resumo) {
  resumo <- resumo |> arrange(ano)
  paste0(
    "<div class='national-trajectory-strip'>",
    paste0(
      "<div title='", resumo$ano, " | ", resumo$ativos, " ativos | ",
      resumo$entradas, " entradas | ", resumo$retornos, " retornos | ",
      resumo$saidas, " saidas'>",
      "<span>", resumo$ano, "</span><strong>", resumo$ativos, "</strong>",
      "<small>+", resumo$entradas, " / -", resumo$saidas, "</small></div>",
      collapse = ""
    ),
    "</div>"
  )
}

html_detalhe_trajetoria_nacional <- function(df) {
  anual <- df |>
    summarise(
      ativos = sum(presente_mides),
      entradas = sum(evento_movimento == "entrada_observada"),
      retornos = sum(evento_movimento == "retorno_observado"),
      saidas = sum(evento_movimento == "saida_observada"),
      permanencias = sum(evento_movimento == "permaneceu"),
      bases = sum(evento_movimento == "base_ou_reinicio_cobertura"),
      saldo = sum(delta_presenca),
      valor = sum(valor_total),
      .by = ano
    ) |>
    arrange(ano)

  linhas <- paste0(
    "<tr><td><strong>", anual$ano, "</strong></td><td>", anual$ativos,
    "</td><td>", anual$bases, "</td><td>+", anual$entradas,
    "</td><td>", anual$retornos, "</td><td>-", anual$saidas,
    "</td><td>", anual$permanencias, "</td><td>",
    ifelse(anual$saldo > 0, "+", ""), anual$saldo, "</td><td>",
    fmt_moeda(anual$valor), "</td></tr>", collapse = ""
  )

  anos <- sort(unique(df$ano))
  municipios <- split(df, paste(df$uf_municipio_pagador, df$id_municipio, sep = "|"))
  matriz <- vapply(municipios, function(mun) {
    celulas <- vapply(anos, function(a) {
      x <- mun[mun$ano == a, , drop = FALSE]
      if (nrow(x) == 0L) return("<td class='state-absent'></td>")
      evento <- x$evento_movimento[[1]]
      classe <- switch(
        evento,
        base_ou_reinicio_cobertura = "state-base",
        entrada_observada = "state-entry",
        retorno_observado = "state-return",
        saida_observada = "state-exit",
        permaneceu = "state-stay",
        "state-absent"
      )
      simbolo <- switch(
        evento,
        base_ou_reinicio_cobertura = "B",
        entrada_observada = "+",
        retorno_observado = "R",
        saida_observada = "-",
        permaneceu = "•",
        ""
      )
      paste0(
        "<td class='movement-state ", classe, "' title='",
        htmltools::htmlEscape(unname(rotulos_evento_nacional[evento])),
        " | ", fmt_moeda(x$valor_total[[1]]), "'>", simbolo, "</td>"
      )
    }, character(1))
    paste0(
      "<tr><th>", htmltools::htmlEscape(mun$municipio[[1]]),
      " <small>", mun$uf_municipio_pagador[[1]], "</small></th>",
      paste0(celulas, collapse = ""), "</tr>"
    )
  }, character(1))

  paste0(
    "<div class='longitudinal-detail'>",
    "<details class='long-detail-section' open><summary>Tabela anual completa</summary>",
    "<div class='long-table-scroll'><table class='long-annual-table'><thead><tr>",
    "<th>Ano</th><th>Ativos</th><th>Base/reinicio</th><th>Entradas</th><th>Retornos</th>",
    "<th>Saidas</th><th>Permanencias</th><th>Saldo</th><th>Valor MIDES</th>",
    "</tr></thead><tbody>", linhas, "</tbody></table></div></details>",
    "<details class='long-detail-section'><summary>Matriz municipio x ano</summary>",
    "<p class='detail-help'>B indica base ou reinicio de cobertura. Passe o mouse sobre cada celula para consultar evento e valor.</p>",
    "<div class='movement-matrix-scroll'><table class='movement-matrix'><thead><tr><th>Municipio</th>",
    paste0("<th>", anos, "</th>", collapse = ""), "</tr></thead><tbody>",
    paste0(matriz, collapse = ""), "</tbody></table></div></details></div>"
  )
}

mides_nacional_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(
      class = "hero national-hero",
      h2("MIDES Brasil: cadastro e pagamentos"),
      p("Camada nacional separada para validacao. Matriz e filiais foram reunidas pela raiz de oito digitos; o CNPJ original permanece rastreavel.")
    ),
    div(
      class = "national-universe-grid",
      div(class = "universe-kpi", span("Universo cadastral IPEA"), strong(textOutput(ns("universo_cadastral"), inline = TRUE)), tags$small("entidades consolidadas")),
      div(class = "universe-kpi financial", span("Com MIDES localizado"), strong(textOutput(ns("universo_financeiro"), inline = TRUE)), tags$small("raizes com algum registro")),
      div(class = "universe-kpi pending", span("Sem MIDES localizado"), strong(textOutput(ns("universo_sem_mides"), inline = TRUE)), tags$small("na extracao atual"))
    ),
    div(
      class = "panel-card",
      h3("Filtros MIDES Brasil"),
      div(
        class = "inline-filters",
        selectizeInput(ns("ano"), label_com_info("Ano", "Anos efetivamente encontrados na extracao nacional.", "Selecionar"), choices = NULL, multiple = TRUE, options = list(plugins = list("remove_button"), closeAfterSelect = FALSE)),
        selectizeInput(ns("uf_pagadora"), label_com_info("UF do municipio pagador", "Estado do municipio que realizou o pagamento; nao e necessariamente a sede do consorcio.", "Selecionar"), choices = NULL, multiple = TRUE, options = list(plugins = list("remove_button"))),
        selectizeInput(ns("uf_sede"), label_com_info("UF sede do consorcio", "Estado da matriz no cadastro IPEA consolidado.", "Selecionar"), choices = NULL, multiple = TRUE, options = list(plugins = list("remove_button")))
      ),
      div(
        class = "inline-filters",
        selectizeInput(ns("municipio"), label_com_info("Municipio pagador", "Localize pelo nome e UF.", "Selecionar"), choices = NULL, multiple = TRUE, options = list(placeholder = "Digite municipio ou UF", plugins = list("remove_button"))),
        selectizeInput(ns("consorcio"), label_com_info("Consorcio consolidado", "Pesquisa por sigla, raiz ou nome canonico.", "Selecionar"), choices = NULL, multiple = TRUE, options = list(placeholder = "Digite sigla, nome ou raiz", plugins = list("remove_button"))),
        textInput(ns("busca"), label_com_info("Busca livre", "Pesquisa municipio, UF, CNPJ original, matriz, raiz, sigla e razao social.", "Digitar"), placeholder = "Digite municipio, CNPJ, sigla ou razao social")
      ),
      div(
        class = "inline-filters",
        selectInput(ns("regra_valor"), label_com_info("Regra de valor", "Valor total e a regra comparavel entre todas as UFs. Corrente e restos so estao decompostos onde o indicador existe."), choices = c("Valor total positivo" = "total", "Valor corrente positivo" = "corrente", "Restos a pagar positivo" = "restos", "Todos os registros" = "todos"), selected = "total"),
        selectInput(ns("metrica"), "Metrica do mapa", choices = c("Valor total MIDES" = "valor_total", "Valor corrente" = "valor_corrente", "Numero de consorcios" = "n_consorcios", "Numero de transacoes" = "n_transacoes"), selected = "valor_total"),
        div(tags$label(" "), actionButton(ns("limpar"), "Limpar filtros Brasil", class = "btn-reset"))
      )
    ),
    div(
      class = "kpi-row national-kpis",
      div(class = "mini-kpi", div(class = "label", "Linhas anuais"), div(class = "value", textOutput(ns("kpi_linhas"), inline = TRUE))),
      div(class = "mini-kpi", div(class = "label", "Pares unicos"), div(class = "value", textOutput(ns("kpi_pares"), inline = TRUE))),
      div(class = "mini-kpi", div(class = "label", "Municipios pagadores"), div(class = "value", textOutput(ns("kpi_municipios"), inline = TRUE))),
      div(class = "mini-kpi", div(class = "label", "Consorcios no filtro positivo"), div(class = "value", textOutput(ns("kpi_consorcios"), inline = TRUE))),
      div(class = "mini-kpi", div(class = "label", "Valor municipal"), div(class = "value", textOutput(ns("kpi_valor"), inline = TRUE))),
      div(class = "mini-kpi warning", div(class = "label", "Sem municipio"), div(class = "value", textOutput(ns("kpi_sem_municipio"), inline = TRUE)))
    ),
    div(
      class = "panel-card coverage-panel",
      h3("Cobertura temporal da extracao"),
      div(class = "map-note", "A linha do tempo descreve os pagamentos encontrados para CNPJs do cadastro IPEA. Ausencia de ano nao significa ausencia de consorcio."),
      uiOutput(ns("cobertura_timeline"))
    ),
    navset_tab(
      nav_panel(
        "Mapa",
        div(
          class = "panel-card map-wrap",
          h3("Mapa municipal MIDES Brasil"),
          div(class = "map-note", "O mapa mostra apenas as oito UFs com pagamentos correspondentes ao cadastro IPEA. Municipios sem cor nao tiveram valor no filtro atual."),
          div(class = "map-actions", downloadButton(ns("mapa_png"), "PNG alta resolucao", icon = bsicons::bs_icon("image")), downloadButton(ns("mapa_pdf"), "PDF vetorial", icon = bsicons::bs_icon("file-earmark-pdf"))),
          girafeOutput(ns("mapa"), width = "100%", height = "720px"),
          h3("Municipios de maior intensidade"), DTOutput(ns("mapa_top"))
        )
      ),
      nav_panel(
        "Entradas/saidas",
        div(
          class = "panel-card map-wrap",
          h3("Movimento financeiro anual"),
          div(class = "map-note", tags$strong("Comparacao conservadora:"), " movimentos so existem quando a UF possui registro no ano atual e no ano imediatamente anterior."),
          selectInput(ns("mov_ano"), "Ano do movimento", choices = NULL),
          div(class = "map-actions", downloadButton(ns("mov_png"), "PNG alta resolucao", icon = bsicons::bs_icon("image")), downloadButton(ns("mov_pdf"), "PDF vetorial", icon = bsicons::bs_icon("file-earmark-pdf"))),
          girafeOutput(ns("mapa_movimento"), width = "100%", height = "720px"),
          DTOutput(ns("tabela_eventos"))
        )
      ),
      nav_panel("Movimentos por consorcio", div(class = "panel-card", h3("Tabela anual por consorcio"), div(class = "map-note", "Clique no + para ver municipios em entradas, retornos e saidas."), DTOutput(ns("movimentos_consorcio")))),
      nav_panel(
        "Trajetoria",
        div(
          class = "panel-card",
          h3("Trajetoria longitudinal por consorcio"),
          div(class = "map-note", "Cada linha acompanha uma raiz CNPJ. Clique no + para carregar tabela anual e matriz municipio x ano."),
          div(class = "map-actions", downloadButton(ns("trajetoria_csv"), "Baixar movimentos filtrados", icon = bsicons::bs_icon("download"))),
          DTOutput(ns("trajetoria")),
          div(style = "display:none;", textInput(ns("traj_req"), NULL, ""), uiOutput(ns("traj_buffer")))
        )
      ),
      nav_panel("Resumo anual", div(class = "panel-card", h3("Resumo por ano e cobertura"), DTOutput(ns("resumo_anual")))),
      nav_panel("Tabela detalhada", div(class = "panel-card", h3("Municipio pagador x raiz CNPJ x ano"), DTOutput(ns("tabela_detalhada"))))
    )
  )
}

auditoria_nacional_ui <- function(id) {
  ns <- NS(id)
  div(
    class = "panel-card",
    h3("Identidade nacional consolidada"),
    div(class = "map-note", "A raiz de oito digitos representa a entidade; a ordem 0001 identifica a matriz. Os estabelecimentos originais permanecem listados."),
    div(
      class = "inline-filters",
      selectizeInput(ns("audit_uf"), "UF sede", choices = NULL, multiple = TRUE, options = list(plugins = list("remove_button"))),
      selectInput(ns("audit_filial"), "Estrutura", choices = c("Todas" = "todos", "Com filial" = "com", "Sem filial" = "sem")),
      selectInput(ns("audit_mides"), "Cobertura MIDES", choices = c("Todas" = "todos", "Com MIDES" = "com", "Sem MIDES" = "sem")),
      textInput(ns("audit_busca"), "Busca", placeholder = "Raiz, matriz, sigla ou razao social")
    ),
    div(
      class = "kpi-row",
      div(class = "mini-kpi", div(class = "label", "Entidades"), div(class = "value", textOutput(ns("audit_entidades"), inline = TRUE))),
      div(class = "mini-kpi", div(class = "label", "Raizes com filial"), div(class = "value", textOutput(ns("audit_raizes_filial"), inline = TRUE))),
      div(class = "mini-kpi", div(class = "label", "Filiais incorporadas"), div(class = "value", textOutput(ns("audit_filiais"), inline = TRUE))),
      div(class = "mini-kpi", div(class = "label", "Com MIDES"), div(class = "value", textOutput(ns("audit_com_mides"), inline = TRUE)))
    ),
    DTOutput(ns("audit_tabela"))
  )
}

documentacao_nacional_ui <- function() {
  tagList(
    div(
      class = "doc-grid",
      div(class = "doc-card", h3("Universo cadastral"), p("1.194 estabelecimentos CNPJ foram consolidados em 1.159 entidades. A matriz 0001 e o identificador canonico.")),
      div(class = "doc-card", h3("Universo financeiro"), p("505 raizes possuem algum registro MIDES localizado em oito UFs pagadoras. Com a regra padrao de valor total positivo, 504 permanecem no filtro. Ausencia no MIDES nao significa inatividade.")),
      div(class = "doc-card", h3("Cobertura desigual"), p("Cada UF possui anos diferentes. Movimentos so sao calculados entre anos consecutivos cobertos."))
    ),
    tags$details(
      class = "doc-detail", open = NA, tags$summary("Pipeline nacional executado"),
      tags$ol(
        tags$li("Padronizar os 1.194 CNPJs do cadastro IPEA e extrair a raiz de oito digitos."),
        tags$li("Identificar a matriz pela ordem 0001 e preservar cada estabelecimento no crosswalk."),
        tags$li("Consultar a tabela de pagamentos MIDES para todos os CNPJs originais."),
        tags$li("Agregar primeiro por CNPJ original e depois somar estabelecimentos da mesma raiz."),
        tags$li("Separar registros sem municipio e materializar cobertura temporal por UF."),
        tags$li("Balancear movimentos apenas nos anos efetivamente cobertos por cada UF."))
    ),
    tags$details(
      class = "doc-detail", open = NA, tags$summary("Exemplo real de matriz e filial"),
      p("Em Cana Verde/MG, no ano de 2014, a matriz 00079634000181 recebeu R$ 4.779 e a filial 00079634000262 recebeu R$ 54.471. A camada consolidada registra uma unica entidade, total de R$ 59.250, e preserva os dois CNPJs de origem."),
      p("Isso evita interpretar uma troca de estabelecimento como saida de um consorcio e entrada em outro.")
    ),
    tags$details(
      class = "doc-detail", tags$summary("Registros de SC sem municipio"),
      p("Foram preservadas 681 transacoes de SC, no valor de R$ 11,15 milhoes, sem id_municipio na propria tabela MIDES. Elas entram no total financeiro sinalizado, mas nao criam pares, mapas ou movimentos municipais.")
    ),
    tags$details(
      class = "doc-detail", tags$summary("Limites atuais"),
      tags$ul(
        tags$li("A classificacao tematica v0.5 permanece validada apenas para MG."),
        tags$li("Base 1, MUNIC, SICONFI, comparacao 2015/2019 e modelos espaciais permanecem no escopo MG."),
        tags$li("O dashboard usa uma fotografia da extracao; atualizar a fonte exige reprocessar e republicar o app."),
        tags$li("Pagamento MIDES nao comprova adesao ou desligamento juridico."))
    )
  )
}

mides_nacional_server <- function(id, dados) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    painel <- dados$anual
    cadastro <- dados$cadastro
    movimentos <- dados$movimentos
    municipios_sf <- dados$municipios_sf
    estados_sf <- dados$estados_sf
    brasil_sf <- dados$brasil_sf
    cobertura <- dados$cobertura
    sem_municipio <- dados$sem_municipio |>
      left_join(
        cadastro |>
          select(cnpj_raiz_8, sigla_canonica, uf_sede_canonica, pesquisa),
        by = "cnpj_raiz_8"
      )

    anos_opts <- sort(unique(painel$ano))
    ufs_pagadoras <- sort(unique(painel$uf_municipio_pagador))
    ufs_sede <- sort(unique(cadastro$uf_sede_canonica))
    municipios_opts <- painel |>
      distinct(id_municipio, municipio, uf_municipio_pagador) |>
      arrange(uf_municipio_pagador, municipio) |>
      mutate(label = paste0(municipio, " (", uf_municipio_pagador, ")"))
    consorcios_opts <- cadastro |>
      filter(encontrado_mides) |>
      arrange(sigla_canonica, razao_social_canonica) |>
      mutate(label = paste0(sigla_canonica, " | ", cnpj_raiz_8, " | ", razao_social_canonica))

    updateSelectizeInput(session, "ano", choices = anos_opts, selected = anos_opts, server = TRUE)
    updateSelectizeInput(session, "uf_pagadora", choices = ufs_pagadoras, selected = ufs_pagadoras, server = TRUE)
    updateSelectizeInput(session, "uf_sede", choices = ufs_sede, selected = NULL, server = TRUE)
    updateSelectizeInput(session, "municipio", choices = setNames(municipios_opts$id_municipio, municipios_opts$label), server = TRUE)
    updateSelectizeInput(session, "consorcio", choices = setNames(consorcios_opts$cnpj_raiz_8, consorcios_opts$label), server = TRUE)
    updateSelectizeInput(session, "audit_uf", choices = ufs_sede, selected = NULL, server = TRUE)

    observeEvent(input$limpar, {
      updateSelectizeInput(session, "ano", selected = anos_opts)
      updateSelectizeInput(session, "uf_pagadora", selected = ufs_pagadoras)
      updateSelectizeInput(session, "uf_sede", selected = character())
      updateSelectizeInput(session, "municipio", selected = character())
      updateSelectizeInput(session, "consorcio", selected = character())
      updateTextInput(session, "busca", value = "")
      updateSelectInput(session, "regra_valor", selected = "total")
      updateSelectInput(session, "metrica", selected = "valor_total")
    })

    output$universo_cadastral <- renderText(fmt_int(nrow(cadastro)))
    output$universo_financeiro <- renderText(fmt_int(sum(cadastro$encontrado_mides)))
    output$universo_sem_mides <- renderText(fmt_int(sum(!cadastro$encontrado_mides)))

    dados_filtrados <- reactive({
      df <- painel
      if (length(input$ano) == 0L || length(input$uf_pagadora) == 0L) return(df[0, ])
      df <- df |> filter(ano %in% as.integer(input$ano), uf_municipio_pagador %in% input$uf_pagadora)
      if (length(input$uf_sede) > 0L) df <- df |> filter(uf_sede_canonica %in% input$uf_sede)
      if (length(input$municipio) > 0L) df <- df |> filter(id_municipio %in% input$municipio)
      if (length(input$consorcio) > 0L) df <- df |> filter(cnpj_raiz_8 %in% input$consorcio)
      if (!is.null(input$busca) && nzchar(str_squish(input$busca))) {
        df <- df |> filter(str_detect(pesquisa, fixed(str_to_lower(str_squish(input$busca)))))
      }
      regra <- input$regra_valor
      if (!is.null(regra)) {
        df <- df |> filter(case_when(
          regra == "total" ~ valor_total > 0,
          regra == "corrente" ~ valor_corrente > 0,
          regra == "restos" ~ valor_restos > 0,
          TRUE ~ TRUE
        ))
      }
      df
    })
    dados_filtrados_auto <- debounce(dados_filtrados, 350)

    movimentos_filtrados <- reactive({
      df <- movimentos
      if (length(input$ano) == 0L || length(input$uf_pagadora) == 0L) return(df[0, ])
      df <- df |> filter(ano %in% as.integer(input$ano), uf_municipio_pagador %in% input$uf_pagadora)
      if (length(input$uf_sede) > 0L) df <- df |> filter(uf_sede_canonica %in% input$uf_sede)
      if (length(input$municipio) > 0L) df <- df |> filter(id_municipio %in% input$municipio)
      if (length(input$consorcio) > 0L) df <- df |> filter(cnpj_raiz_8 %in% input$consorcio)
      if (!is.null(input$busca) && nzchar(str_squish(input$busca))) {
        termo <- str_to_lower(str_squish(input$busca))
        df <- df |> filter(str_detect(str_to_lower(paste(municipio, sigla_canonica, razao_social_canonica, cnpj_raiz_8, cnpj_canonico)), fixed(termo)))
      }
      df
    })

    sem_municipio_filtrado <- reactive({
      df <- sem_municipio
      if (length(input$ano) == 0L || length(input$uf_pagadora) == 0L) return(df[0, ])
      df <- df |> filter(ano %in% as.integer(input$ano), uf_municipio_pagador %in% input$uf_pagadora)
      if (length(input$uf_sede) > 0L) df <- df |> filter(uf_sede_canonica %in% input$uf_sede)
      if (length(input$consorcio) > 0L) df <- df |> filter(cnpj_raiz_8 %in% input$consorcio)
      if (!is.null(input$busca) && nzchar(str_squish(input$busca))) {
        df <- df |> filter(str_detect(pesquisa, fixed(str_to_lower(str_squish(input$busca)))))
      }
      df
    })

    output$kpi_linhas <- renderText(fmt_int(nrow(dados_filtrados())))
    output$kpi_pares <- renderText(fmt_int(n_distinct(paste(dados_filtrados()$id_municipio, dados_filtrados()$cnpj_raiz_8))))
    output$kpi_municipios <- renderText(fmt_int(n_distinct(dados_filtrados()$id_municipio)))
    output$kpi_consorcios <- renderText(fmt_int(n_distinct(dados_filtrados()$cnpj_raiz_8)))
    output$kpi_valor <- renderText(fmt_moeda(sum(dados_filtrados()$valor_total)))
    output$kpi_sem_municipio <- renderText(paste0(fmt_int(sum(sem_municipio_filtrado()$n_transacoes)), " | ", fmt_moeda_curto(sum(sem_municipio_filtrado()$valor_total))))

    output$cobertura_timeline <- renderUI(HTML(html_timeline_cobertura_nacional(cobertura)))

    dados_mapa <- reactive({
      metrica <- input$metrica
      if (is.null(metrica)) metrica <- "valor_total"
      resumo <- dados_filtrados_auto() |>
        summarise(
          valor_total = sum(valor_total), valor_corrente = sum(valor_corrente),
          n_consorcios = n_distinct(cnpj_raiz_8), n_transacoes = sum(n_transacoes),
          principais = paste(head(sort(unique(sigla_canonica)), 5), collapse = "; "),
          .by = id_municipio
        )
      municipios_sf |>
        left_join(resumo, by = "id_municipio") |>
        mutate(
          across(c(valor_total, valor_corrente, n_consorcios, n_transacoes), ~ coalesce(.x, 0)),
          mapa_valor = .data[[metrica]], mapa_valor_plot = if_else(mapa_valor > 0, mapa_valor, NA_real_),
          mapa_classe = classificar_mapa(mapa_valor, metrica, n = 5),
          tooltip = paste0("<strong>", municipio, " (", uf_municipio, ")</strong><br>Valor total: ", fmt_moeda(valor_total), "<br>Consorcios: ", fmt_int(n_consorcios), "<br>Transacoes: ", fmt_int(n_transacoes), "<br>", coalesce(principais, "Sem registro"))
        )
    })
    dados_mapa_auto <- debounce(dados_mapa, 500)

    output$mapa <- renderGirafe({
      p <- plot_mides_nacional(dados_mapa_auto(), estados_sf, brasil_sf, isolate(input$metrica), isolate(input$ano), TRUE)
      girafe(ggobj = p, width_svg = 12, height_svg = 7.2, options = list(opts_hover(css = "stroke:#173a50;stroke-width:0.8px;"), opts_zoom(max = 8), opts_toolbar(saveaspng = FALSE), opts_sizing(rescale = TRUE)))
    })

    output$mapa_top <- renderDT({
      df <- dados_mapa() |> st_drop_geometry() |> filter(mapa_valor > 0) |> arrange(desc(mapa_valor)) |> slice_head(n = 15) |>
        transmute(UF = uf_municipio, Municipio = municipio, `Valor total` = round(valor_total, 2), Consorcios = n_consorcios, Transacoes = n_transacoes, Principais = principais)
      datatable(df, rownames = FALSE, options = list(dom = "t", pageLength = 15, scrollX = TRUE, language = dt_pt)) |>
        formatCurrency("Valor total", "R$ ", mark = ".", dec.mark = ",", digits = 0)
    }, server = TRUE)

    observeEvent(input$ano, {
      anos <- sort(unique(as.integer(input$ano)))
      updateSelectInput(session, "mov_ano", choices = anos, selected = if (length(anos)) max(anos) else NULL)
    }, ignoreNULL = FALSE)

    dados_mov_mapa <- reactive({
      req(input$mov_ano)
      ano <- as.integer(input$mov_ano)
      resumo <- movimentos_filtrados() |>
        filter(ano == !!ano, evento_movimento != "sem_comparacao_temporal") |>
        summarise(
          n_entrada = sum(evento_movimento == "entrada_observada"),
          n_retorno = sum(evento_movimento == "retorno_observado"),
          n_saida = sum(evento_movimento == "saida_observada"),
          n_permaneceu = sum(evento_movimento == "permaneceu"),
          n_base = sum(evento_movimento == "base_ou_reinicio_cobertura"),
          eventos_ativos = sum(c(n_entrada, n_retorno, n_saida, n_permaneceu, n_base) > 0),
          max_evento = max(c(n_entrada, n_retorno, n_saida, n_permaneceu, n_base)),
          movimento_mapa = case_when(
            max_evento == 0 ~ "Sem registro",
            sum(c(n_entrada, n_retorno, n_saida, n_permaneceu, n_base) == max_evento) > 1 ~ "Misto",
            n_entrada == max_evento ~ "Entrada observada",
            n_retorno == max_evento ~ "Retorno observado",
            n_saida == max_evento ~ "Saida observada",
            n_permaneceu == max_evento ~ "Permaneceu",
            TRUE ~ "Base ou reinicio da cobertura"
          ),
          .by = id_municipio
        )
      municipios_sf |>
        left_join(resumo, by = "id_municipio") |>
        mutate(
          across(c(n_entrada, n_retorno, n_saida, n_permaneceu, n_base), ~ coalesce(.x, 0L)),
          movimento_mapa = factor(coalesce(movimento_mapa, "Sem registro"), levels = names(paleta_evento_nacional)),
          tooltip = paste0("<strong>", municipio, " (", uf_municipio, ")</strong><br>Entradas: ", n_entrada, "<br>Retornos: ", n_retorno, "<br>Saidas: ", n_saida, "<br>Permanencias: ", n_permaneceu, "<br>Base/reinicio: ", n_base)
        )
    })

    output$mapa_movimento <- renderGirafe({
      p <- plot_movimento_nacional(dados_mov_mapa(), estados_sf, brasil_sf, input$mov_ano, TRUE)
      girafe(ggobj = p, width_svg = 12, height_svg = 7.2, options = list(opts_hover(css = "stroke:#173a50;stroke-width:0.8px;"), opts_zoom(max = 8), opts_toolbar(saveaspng = FALSE), opts_sizing(rescale = TRUE)))
    })

    output$tabela_eventos <- renderDT({
      req(input$mov_ano)
      df <- movimentos_filtrados() |>
        filter(ano == as.integer(input$mov_ano), evento_movimento %in% c("entrada_observada", "retorno_observado", "saida_observada")) |>
        transmute(Ano = ano, UF = uf_municipio_pagador, Municipio = municipio, Consorcio = sigla_canonica, Raiz = cnpj_raiz_8, Evento = unname(rotulos_evento_nacional[evento_movimento]), `Valor MIDES` = round(valor_total, 2))
      datatable(df, rownames = FALSE, extensions = "Buttons", options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel"), pageLength = 15, scrollX = TRUE, language = dt_pt)) |>
        formatCurrency("Valor MIDES", "R$ ", mark = ".", dec.mark = ",", digits = 0)
    }, server = TRUE)

    resumo_movimentos <- reactive({
      movimentos_filtrados() |>
        summarise(
          ativos = sum(presente_mides),
          entradas = sum(evento_movimento == "entrada_observada"),
          retornos = sum(evento_movimento == "retorno_observado"),
          saidas = sum(evento_movimento == "saida_observada"),
          permanencias = sum(evento_movimento == "permaneceu"),
          bases = sum(evento_movimento == "base_ou_reinicio_cobertura"),
          saldo = sum(delta_presenca), valor = sum(valor_total),
          .by = c(ano, cnpj_raiz_8, cnpj_canonico, sigla_canonica, razao_social_canonica)
        ) |>
        arrange(cnpj_raiz_8, ano)
    })

    output$movimentos_consorcio <- renderDT({
      mov <- movimentos_filtrados()
      resumo <- resumo_movimentos()
      detalhes <- mov |>
        filter(evento_movimento %in% c("entrada_observada", "retorno_observado", "saida_observada")) |>
        summarise(lista = formatar_lista_html(paste0(municipio, " (", uf_municipio_pagador, ")")), .by = c(ano, cnpj_raiz_8, evento_movimento)) |>
        mutate(evento_movimento = factor(evento_movimento, levels = c("entrada_observada", "retorno_observado", "saida_observada"))) |>
        tidyr::pivot_wider(names_from = evento_movimento, values_from = lista, values_fill = "<span>Nenhum municipio.</span>", names_expand = TRUE)
      df <- resumo |>
        left_join(detalhes, by = c("ano", "cnpj_raiz_8")) |>
        mutate(across(any_of(c("entrada_observada", "retorno_observado", "saida_observada")), ~ coalesce(.x, "<span>Nenhum municipio.</span>"))) |>
        transmute(
          ` ` = "", Ano = ano,
          Consorcio = paste0("<div class='consorcio-cell'><strong>", htmltools::htmlEscape(sigla_canonica), "</strong><span>", cnpj_raiz_8, " | ", htmltools::htmlEscape(razao_social_canonica), "</span></div>"),
          Ativos = ativos, Entradas = entradas, Retornos = retornos, Saidas = saidas, Permanencias = permanencias, `Base/reinicio` = bases, Saldo = saldo, `Valor MIDES` = round(valor, 2),
          Detalhes = paste0("<div class='dt-detail-box movement-detail-grid'><div class='movement-detail-group entry'><strong>Entradas</strong>", coalesce(entrada_observada, "<span>Nenhum municipio.</span>"), "</div><div class='movement-detail-group return'><strong>Retornos</strong>", coalesce(retorno_observado, "<span>Nenhum municipio.</span>"), "</div><div class='movement-detail-group exit'><strong>Saidas</strong>", coalesce(saida_observada, "<span>Nenhum municipio.</span>"), "</div></div>")
        )
      hidden <- ncol(df) - 1L
      datatable(df, rownames = FALSE, escape = FALSE, selection = "none", options = list(dom = "ftip", pageLength = 10, scrollX = TRUE, columnDefs = list(list(className = "details-control", orderable = FALSE, targets = 0), list(visible = FALSE, targets = hidden)), language = dt_pt), callback = JS(sprintf("table.on('click','td.details-control',function(){var tr=$(this).closest('tr');var row=table.row(tr);if(row.child.isShown()){row.child.hide();tr.removeClass('shown');}else{row.child(row.data()[%d]).show();tr.addClass('shown');}});", hidden))) |>
        formatCurrency("Valor MIDES", "R$ ", mark = ".", dec.mark = ",", digits = 0)
    }, server = TRUE)

    output$trajetoria <- renderDT({
      resumo <- resumo_movimentos()
      recorrentes <- movimentos_filtrados() |> filter(movimento_recorrente) |> summarise(Recorrentes = n_distinct(id_municipio), .by = cnpj_raiz_8)
      df <- resumo |>
        summarise(
          sigla = first(sigla_canonica), razao = first(razao_social_canonica),
          trajetoria = html_trajetoria_nacional_compacta(pick(everything())),
          saldo = sum(saldo), valor = sum(valor), .by = cnpj_raiz_8
        ) |>
        left_join(recorrentes, by = "cnpj_raiz_8") |>
        mutate(Recorrentes = coalesce(Recorrentes, 0L)) |>
        transmute(
          ` ` = "", Consorcio = paste0("<div class='consorcio-cell'><strong>", htmltools::htmlEscape(sigla), "</strong><span>", cnpj_raiz_8, " | ", htmltools::htmlEscape(razao), "</span></div>"),
          Trajetoria = trajetoria, Saldo = saldo, Recorrentes, `Valor MIDES` = round(valor, 2), Raiz = cnpj_raiz_8
        )
      hidden <- ncol(df) - 1L
      callback <- JS(sprintf("table.on('click','td.details-control',function(){var tr=$(this).closest('tr');var row=table.row(tr);if(row.child.isShown()){row.child.hide();tr.removeClass('shown');}else{var raiz=row.data()[%d];row.child('<div id=\"nat-traj-'+raiz+'\" class=\"trajectory-loading\">Carregando...</div>').show();tr.addClass('shown');$('#%s').val(raiz+'|'+Date.now()).trigger('change');var n=0;var timer=setInterval(function(){n++;var src=document.querySelector('#%s [data-raiz=\"'+raiz+'\"]');var dst=document.getElementById('nat-traj-'+raiz);if(src&&dst){dst.outerHTML=src.innerHTML;clearInterval(timer);}else if(n>150||!dst){clearInterval(timer);}},100);}});", hidden, ns("traj_req"), ns("traj_buffer")))
      datatable(df, rownames = FALSE, escape = FALSE, selection = "none", options = list(dom = "ftip", pageLength = 8, scrollX = TRUE, columnDefs = list(list(className = "details-control", orderable = FALSE, targets = 0), list(visible = FALSE, targets = hidden), list(width = "600px", orderable = FALSE, targets = 2)), language = dt_pt), callback = callback) |>
        formatCurrency("Valor MIDES", "R$ ", mark = ".", dec.mark = ",", digits = 0)
    }, server = TRUE)

    output$traj_buffer <- renderUI({
      req(input$traj_req)
      raiz <- strsplit(input$traj_req, "|", fixed = TRUE)[[1]][[1]]
      df <- movimentos_filtrados() |> filter(cnpj_raiz_8 == raiz)
      tags$div(`data-raiz` = raiz, HTML(if (nrow(df)) html_detalhe_trajetoria_nacional(df) else "Sem dados no filtro."))
    })
    outputOptions(output, "traj_buffer", suspendWhenHidden = FALSE)

    output$resumo_anual <- renderDT({
      df <- dados_filtrados() |>
        summarise(Linhas = n(), Pares = n_distinct(paste(id_municipio, cnpj_raiz_8)), Municipios = n_distinct(id_municipio), Consorcios = n_distinct(cnpj_raiz_8), `Valor municipal` = sum(valor_total), .by = c(uf_municipio_pagador, ano)) |>
        left_join(sem_municipio_filtrado() |> summarise(`Transacoes sem municipio` = sum(n_transacoes), `Valor sem municipio` = sum(valor_total), .by = c(uf_municipio_pagador, ano)), by = c("uf_municipio_pagador", "ano")) |>
        mutate(across(c(`Transacoes sem municipio`, `Valor sem municipio`), ~ coalesce(.x, 0))) |>
        rename(UF = uf_municipio_pagador, Ano = ano)
      datatable(df, rownames = FALSE, extensions = "Buttons", options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel"), pageLength = 20, scrollX = TRUE, language = dt_pt)) |>
        formatCurrency(c("Valor municipal", "Valor sem municipio"), "R$ ", mark = ".", dec.mark = ",", digits = 0)
    }, server = TRUE)

    output$tabela_detalhada <- renderDT({
      df <- dados_filtrados() |>
        transmute(Ano = ano, `UF pagadora` = uf_municipio_pagador, Municipio = municipio, Raiz = cnpj_raiz_8, Matriz = cnpj_canonico, Sigla = sigla_canonica, `Razao social` = razao_social_canonica, `UF sede` = uf_sede_canonica, `CNPJs observados` = cnpjs_originais_observados, `Valor corrente` = round(valor_corrente, 2), Restos = round(valor_restos, 2), `Indicador ausente` = round(valor_indicador_restos_ausente, 2), `Valor total` = round(valor_total, 2), Transacoes = n_transacoes)
      datatable(df, rownames = FALSE, extensions = "Buttons", filter = "top", options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel"), pageLength = 20, scrollX = TRUE, deferRender = TRUE, searchDelay = 450, language = dt_pt)) |>
        formatCurrency(c("Valor corrente", "Restos", "Indicador ausente", "Valor total"), "R$ ", mark = ".", dec.mark = ",", digits = 0)
    }, server = TRUE)

    output$mapa_png <- downloadHandler(filename = function() paste0("mides_brasil_", Sys.Date(), ".png"), content = function(file) salvar_mapa_alta_resolucao(plot_mides_nacional(dados_mapa(), estados_sf, brasil_sf, input$metrica, input$ano, FALSE), file, "png"))
    output$mapa_pdf <- downloadHandler(filename = function() paste0("mides_brasil_", Sys.Date(), ".pdf"), content = function(file) salvar_mapa_alta_resolucao(plot_mides_nacional(dados_mapa(), estados_sf, brasil_sf, input$metrica, input$ano, FALSE), file, "pdf"))
    output$mov_png <- downloadHandler(filename = function() paste0("movimentos_mides_brasil_", input$mov_ano, ".png"), content = function(file) salvar_mapa_alta_resolucao(plot_movimento_nacional(dados_mov_mapa(), estados_sf, brasil_sf, input$mov_ano, FALSE), file, "png"))
    output$mov_pdf <- downloadHandler(filename = function() paste0("movimentos_mides_brasil_", input$mov_ano, ".pdf"), content = function(file) salvar_mapa_alta_resolucao(plot_movimento_nacional(dados_mov_mapa(), estados_sf, brasil_sf, input$mov_ano, FALSE), file, "pdf"))
    output$trajetoria_csv <- downloadHandler(filename = function() paste0("movimentos_mides_brasil_", Sys.Date(), ".csv"), content = function(file) movimentos_filtrados() |> write_csv(file, na = ""))

    auditoria_filtrada <- reactive({
      df <- cadastro
      if (length(input$audit_uf) > 0L) df <- df |> filter(uf_sede_canonica %in% input$audit_uf)
      if (!is.null(input$audit_filial) && input$audit_filial != "todos") df <- df |> filter(tem_filial == (input$audit_filial == "com"))
      if (!is.null(input$audit_mides) && input$audit_mides != "todos") df <- df |> filter(encontrado_mides == (input$audit_mides == "com"))
      if (!is.null(input$audit_busca) && nzchar(str_squish(input$audit_busca))) df <- df |> filter(str_detect(pesquisa, fixed(str_to_lower(str_squish(input$audit_busca)))))
      df
    })
    output$audit_entidades <- renderText(fmt_int(nrow(auditoria_filtrada())))
    output$audit_raizes_filial <- renderText(fmt_int(sum(auditoria_filtrada()$tem_filial)))
    output$audit_filiais <- renderText(fmt_int(sum(auditoria_filtrada()$n_filiais)))
    output$audit_com_mides <- renderText(fmt_int(sum(auditoria_filtrada()$encontrado_mides)))
    output$audit_tabela <- renderDT({
      df <- auditoria_filtrada() |>
        transmute(Raiz = cnpj_raiz_8, Matriz = cnpj_matriz, Sigla = sigla_canonica, `Razao social` = razao_social_canonica, `UF sede` = uf_sede_canonica, `Municipio sede` = municipio_sede_canonico, Estabelecimentos = n_estabelecimentos, Filiais = n_filiais, `CNPJs originais` = cnpjs_estabelecimentos, `CNPJs filiais` = cnpjs_filiais, Situacoes = situacoes_estabelecimentos, `Encontrado MIDES` = if_else(encontrado_mides, "Sim", "Nao"))
      datatable(df, rownames = FALSE, extensions = "Buttons", filter = "top", options = list(dom = "Bfrtip", buttons = c("copy", "csv", "excel"), pageLength = 20, scrollX = TRUE, language = dt_pt))
    }, server = TRUE)
  })
}
