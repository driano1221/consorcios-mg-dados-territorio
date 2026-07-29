doc_table <- function(headers, rows, class = "doc-table") {
  tags$table(
    class = class,
    tags$thead(tags$tr(lapply(headers, tags$th))),
    tags$tbody(lapply(rows, function(row) tags$tr(lapply(row, tags$td))))
  )
}

documentacao_movimentos_ui <- function() {
  div(
    class = "doc-article",

    div(
      class = "doc-lead",
      div(
        class = "doc-kicker",
        "ANÁLISE EXPLORATÓRIA | MIDES 2014–2021"
      ),
      h2("Movimentos financeiros e exposição espacial"),
      p(
        "Esta análise investiga se a configuração territorial observada no ano anterior está associada ao início, à continuidade ou à interrupção de pagamentos municipais a um mesmo CNPJ de consórcio. O objetivo é avançar da descrição dos movimentos para uma hipótese explicativa testável."
      ),
      div(
        class = "doc-alert",
        tags$strong("Regra de interpretação: "),
        "o MIDES observa pagamentos. Entrada, retorno e saída são movimentos financeiros observados e não comprovam adesão, desligamento, criação ou extinção jurídica."
      )
    ),

    div(
      class = "doc-stat-grid",
      div(class = "doc-stat", span("Período"), strong("2014–2021"), tags$small("Oito exercícios anuais")),
      div(class = "doc-stat", span("Unidade básica"), strong("Município × CNPJ × ano"), tags$small("Um pagamento observado por par e exercício")),
      div(class = "doc-stat", span("Território"), strong("853 municípios"), tags$small("Minas Gerais")),
      div(class = "doc-stat", span("Fronteiras"), strong("2.375"), tags$small("Divisas municipais compartilhadas"))
    ),

    navset_tab(
      id = "doc_movimentos_secao",

      nav_panel(
        "1. Ideia e dados",
        div(
          class = "doc-section",
          h3("Da pergunta descritiva à hipótese territorial"),
          p(
            "O painel anual já mostrava quais pares município–consórcio começavam, permaneciam ou deixavam de apresentar pagamento. A nova pergunta foi: a posição territorial do município no ano anterior ajuda a distinguir onde esses movimentos ocorrem?"
          ),
          div(
            class = "doc-question",
            span("HIPÓTESE CENTRAL"),
            strong("Municípios cercados por vizinhos que já pagam ao mesmo CNPJ apresentam mais entradas e menos saídas observadas?")
          ),
          p(
            "A hipótese não pressupõe que a vizinhança cause o movimento. Municípios próximos podem compartilhar serviços, infraestrutura, região de saúde, capacidade fiscal, decisões políticas ou outras características ainda não controladas."
          )
        ),
        div(
          class = "doc-section",
          h3("Dados utilizados"),
          doc_table(
            c("Componente", "Arquivo ou fonte", "Uso na análise", "O que não faz"),
            list(
              list(
                tags$strong("MIDES anual"),
                tags$code("painel_mg_anual.rds"),
                "Valores corrente, restos e total por município, CNPJ e ano.",
                "Não comprova filiação jurídica."
              ),
              list(
                tags$strong("Malha municipal"),
                "geobr/IBGE 2020, geometria completa",
                "Identifica municípios que compartilham uma linha de fronteira.",
                "Contato somente por um ponto não conta como vizinhança."
              ),
              list(
                tags$strong("Cadastro e classificação v0.5"),
                "Camada cadastral do projeto",
                "Fornece nome canônico e contexto institucional para leitura.",
                "Ainda não entra como controle do modelo estatístico."
              )
            )
          ),
          div(
            class = "doc-note",
            tags$strong("Fontes que não entram nesta análise: "),
            "MUNIC, SICONFI e CNM não são combinados ao MIDES completo. A análise espacial usa exclusivamente a série anual MIDES e a geometria municipal."
          )
        ),
        div(
          class = "doc-section",
          h3("Unidade e regra de presença"),
          div(
            class = "doc-two-col",
            div(
              h4("Unidade"),
              p("Cada linha representa um município, um CNPJ de consórcio e um ano."),
              div(class = "doc-code-line", "Poté × CISNORJE × 2021")
            ),
            div(
              h4("Presença principal"),
              p("O par é considerado presente quando o valor total MIDES é positivo."),
              div(class = "doc-code-line", "presente = valor_total > 0")
            )
          ),
          p(
            "Todos os pares observados ao menos uma vez recebem os oito anos da janela. Uma ausência de linha é preenchida com valor zero para permitir a comparação anual, sem convertê-la em prova de desligamento formal."
          )
        )
      ),

      nav_panel(
        "2. Pipeline e indicadores",
        div(
          class = "doc-section",
          h3("Pipeline completo"),
          p("O processamento foi executado em sete etapas. A figura resume a passagem do pagamento anual até os universos estatísticos de entrada e saída."),
          tags$figure(
            class = "doc-figure",
            tags$img(
              src = "pipeline_movimentos_mides.png",
              alt = "Pipeline da análise espacial dos movimentos MIDES",
              class = "doc-image"
            ),
            tags$figcaption(
              "Figura 1. Pipeline executado para construir eventos, indicadores espaciais e modelos."
            )
          )
        ),
        div(
          class = "doc-section",
          h3("Como os eventos anuais são classificados"),
          div(
            class = "doc-flow doc-flow-five",
            div(class = "doc-flow-step", strong("Entrada nova"), span("Primeiro pagamento positivo observado na janela.")),
            div(class = "doc-flow-step", strong("Permanência"), span("Pagamento positivo em t−1 e em t.")),
            div(class = "doc-flow-step", strong("Saída"), span("Pagamento positivo em t−1 e ausência em t.")),
            div(class = "doc-flow-step", strong("Retorno"), span("Novo pagamento depois de pelo menos uma ausência.")),
            div(class = "doc-flow-step", strong("Ausência"), span("Sem pagamento positivo no ano."))
          ),
          div(
            class = "doc-timeline",
            div(class = "doc-timeline-title", "Exemplo genérico"),
            div(class = "doc-year absent", strong("2014"), span("Ausente")),
            div(class = "doc-year enter", strong("2015"), span("Entrada")),
            div(class = "doc-year stay", strong("2016"), span("Permanece")),
            div(class = "doc-year exit", strong("2017"), span("Saída")),
            div(class = "doc-year absent", strong("2018"), span("Ausente")),
            div(class = "doc-year return", strong("2019"), span("Retorno")),
            div(class = "doc-year stay", strong("2020"), span("Permanece")),
            div(class = "doc-year exit", strong("2021"), span("Saída"))
          )
        ),
        div(
          class = "doc-section",
          h3("Como a vizinhança se transforma em indicadores"),
          p(
            "Para cada município e CNPJ, verifica-se quantos vizinhos já apresentavam pagamento ao mesmo CNPJ no ano anterior. A defasagem t−1 garante que a exposição territorial seja medida antes do movimento observado em t."
          ),
          tags$figure(
            class = "doc-figure",
            tags$img(
              src = "exposicao_espacial_mides.png",
              alt = "Mapa conceitual da exposição espacial no MIDES",
              class = "doc-image"
            ),
            tags$figcaption(
              "Figura 2. Leitura dos indicadores de integração, borda, isolamento e adjacência externa."
            )
          ),
          doc_table(
            c("Indicador", "Cálculo", "Interpretação"),
            list(
              list(
                tags$code("prop_vizinhos_no_consorcio_t_1"),
                "Vizinhos com pagamento ao mesmo CNPJ ÷ total de vizinhos.",
                "Integração territorial no ano anterior."
              ),
              list(
                tags$code("candidato_externo_adjacente_t_1"),
                "Não pagava ao CNPJ e tinha ao menos um vizinho que pagava.",
                "Município externo exposto à expansão territorial."
              ),
              list(
                tags$code("participante_isolado_t_1"),
                "Pagava ao CNPJ, mas nenhum vizinho pagava ao mesmo CNPJ.",
                "Participação financeira territorialmente isolada."
              ),
              list(
                tags$code("participante_na_borda_t_1"),
                "Pagava ao CNPJ e tinha ao menos um vizinho sem pagamento ao CNPJ.",
                "Posição de borda; o isolamento é seu caso extremo."
              )
            )
          )
        )
      ),

      nav_panel(
        "3. Quem entra na análise",
        div(
          class = "doc-section",
          h3("Do território aos dois conjuntos de risco"),
          p(
            "Entrada e saída exigem perguntas e denominadores diferentes. Por isso, não são calculadas sobre a mesma tabela."
          ),
          div(
            class = "risk-flow",
            div(
              class = "risk-start",
              span("PONTO DE PARTIDA"),
              strong("CNPJ com pelo menos um município com pagamento em t−1")
            ),
            div(class = "risk-arrow", "↓"),
            div(
              class = "risk-split",
              div(
                class = "risk-box entry",
                span("UNIVERSO DE ENTRADA"),
                h4("Não tinha pagamento em t−1"),
                p("Cruza o CNPJ ativo com todos os 853 municípios e retira quem já pagava."),
                strong("742.916 exposições"),
                tags$small("1.395 entradas ou retornos")
              ),
              div(
                class = "risk-box exit",
                span("UNIVERSO DE SAÍDA"),
                h4("Tinha pagamento em t−1"),
                p("Acompanha todos os pares ativos e verifica se o pagamento permanece em t."),
                strong("12.842 exposições"),
                tags$small("966 saídas")
              )
            )
          ),
          div(
            class = "doc-note",
            tags$strong("Por que ampliar a antiga base de fronteira? "),
            "A primeira tabela possuía somente 18.404 candidatos já adjacentes. O universo completo acrescenta os municípios com zero vizinhos participantes, criando um grupo de comparação necessário para testar a hipótese espacial."
          )
        ),
        div(
          class = "doc-section",
          h3("Eventos mantidos fora do modelo espacial"),
          p(
            "Quando nenhum município pagava ao CNPJ em t−1, não existe uma configuração territorial anterior do consórcio. Esses eventos permanecem documentados, mas não entram no modelo de difusão."
          ),
          doc_table(
            c("Motivo", "Eventos", "Tratamento"),
            list(
              list("Primeiro aparecimento do CNPJ na janela", "387", "Preservado na base; fora do modelo espacial."),
              list("Reaparecimento após um ano sem qualquer município ativo", "31", "Preservado na base; fora do modelo espacial."),
              list(tags$strong("Total"), tags$strong("418"), "Reconciliado com os eventos originais.")
            )
          )
        ),
        div(
          class = "doc-section",
          h3("Entrada nova e retorno também são separados"),
          div(
            class = "doc-two-col",
            div(
              h4("Entrada nova observada"),
              p("O par nunca havia apresentado pagamento positivo anteriormente na janela."),
              strong("741.040 exposições | 990 eventos")
            ),
            div(
              h4("Retorno observado"),
              p("O par já havia apresentado pagamento, ficou ausente e voltou a pagar."),
              strong("1.876 exposições | 405 eventos")
            )
          )
        )
      ),

      nav_panel(
        "4. Exemplo real",
        div(
          class = "doc-section example-head",
          div(
            div(class = "doc-kicker", "EXEMPLO AUDITADO"),
            h3("Poté × CISNORJE × 2021"),
            p("CNPJ 13.220.150/0001-52 — Consórcio Intermunicipal de Saúde da Rede de Urgência do Nordeste/Jequitinhonha."),
            div(class = "doc-badges", span("Saúde"), span("Urgência e emergência"), span("Entrada nova observada"))
          ),
          div(class = "example-value", span("Pagamento em 2021"), strong("R$ 27.210,15"), tags$small("Valor corrente; restos iguais a zero"))
        ),
        div(
          class = "doc-section",
          h3("Etapa 1 — construir a sequência anual"),
          div(
            class = "doc-timeline real",
            div(class = "doc-timeline-title", "Presença anual do par"),
            div(class = "doc-year absent", strong("2014"), span("R$ 0")),
            div(class = "doc-year absent", strong("2015"), span("R$ 0")),
            div(class = "doc-year absent", strong("2016"), span("R$ 0")),
            div(class = "doc-year absent", strong("2017"), span("R$ 0")),
            div(class = "doc-year absent", strong("2018"), span("R$ 0")),
            div(class = "doc-year absent", strong("2019"), span("R$ 0")),
            div(class = "doc-year absent", strong("2020"), span("R$ 0")),
            div(class = "doc-year enter", strong("2021"), span("R$ 27.210,15"))
          ),
          p("Como 2021 é o primeiro ano positivo do par, o evento é classificado como entrada nova observada.")
        ),
        div(
          class = "doc-section",
          h3("Etapa 2 — observar a vizinhança em 2020"),
          p("Poté possui cinco municípios vizinhos por fronteira compartilhada. Todos já apresentavam pagamento ao mesmo CNPJ em 2020."),
          doc_table(
            c("Vizinho de Poté", "Pagamento ao CISNORJE em 2020", "Valor MIDES"),
            list(
              list("Franciscópolis", "Sim", "R$ 10.440,00"),
              list("Itambacuri", "Sim", "R$ 41.056,20"),
              list("Ladainha", "Sim", "R$ 25.491,00"),
              list("Malacacheta", "Sim", "R$ 33.796,80"),
              list("Teófilo Otoni", "Sim", "R$ 581.758,08")
            )
          )
        ),
        div(
          class = "doc-section",
          h3("Etapas 3 e 4 — calcular indicadores e entrar no modelo"),
          div(
            class = "example-steps",
            div(span("1"), p("Poté não pagava ao CNPJ em 2020.")),
            div(span("2"), p("Os cinco vizinhos pagavam ao mesmo CNPJ.")),
            div(span("3"), p("Proporção em t−1 = 5 ÷ 5 = 100%.")),
            div(span("4"), p("Poté entra como candidato externo adjacente.")),
            div(span("5"), p("O pagamento em 2021 gera um evento positivo de entrada nova."))
          ),
          div(
            class = "doc-note",
            tags$strong("Leitura correta: "),
            "o caso é compatível com expansão territorial, mas não demonstra que os vizinhos causaram o pagamento. Ele representa uma observação entre centenas de milhares utilizadas pelo modelo."
          )
        )
      ),

      nav_panel(
        "5. Modelo e resultados",
        div(
          class = "doc-section",
          h3("Especificação estatística"),
          p("Foram estimadas regressões logísticas separadas para entrada, entrada nova, retorno e saída."),
          div(
            class = "model-formula",
            "evento em t ~ exposição espacial em t−1 + log(1 + tamanho do consórcio) + número de vizinhos + efeitos fixos de ano"
          ),
          doc_table(
            c("Componente", "Por que entra"),
            list(
              list("Exposição espacial em t−1", "Mede a configuração territorial anterior ao evento."),
              list("Tamanho do consórcio em t−1", "Consórcios maiores oferecem mais oportunidades de vizinhança e expansão."),
              list("Número total de vizinhos", "Controla diferenças básicas da posição geográfica municipal."),
              list("Efeitos fixos de ano", "Separam choques comuns de cada exercício."),
              list("Erros agrupados por município e CNPJ", "Reconhecem repetição de observações nas duas dimensões.")
            )
          ),
          div(
            class = "doc-note",
            tags$strong("Como ler o odds ratio: "),
            "OR acima de 1 indica odds maiores; OR abaixo de 1 indica odds menores. Odds não são iguais a probabilidade e os resultados não representam efeito causal."
          )
        ),
        div(
          class = "doc-section",
          h3("Resultados ajustados principais"),
          doc_table(
            c("Resultado", "Odds ratio", "Intervalo de 95%", "Interpretação"),
            list(
              list("Entrada ou retorno: +10 p.p. de vizinhos", tags$strong("2,22"), "2,11–2,34", "Odds de entrada ou retorno aproximadamente 2,2 vezes maiores."),
              list("Entrada nova: +10 p.p.", tags$strong("2,20"), "2,09–2,31", "Associação territorial mais forte no primeiro pagamento observado."),
              list("Retorno: +10 p.p.", tags$strong("1,26"), "1,17–1,35", "Associação positiva, porém menor."),
              list("Saída: +10 p.p.", tags$strong("0,79"), "0,76–0,83", "Redução aproximada de 21% nas odds de saída."),
              list("Participante isolado", tags$strong("3,98"), "2,90–5,46", "Odds de saída quase quatro vezes maiores.")
            )
          )
        ),
        div(
          class = "doc-section",
          h3("Gradiente observado nas taxas"),
          p("As taxas apresentam comportamento monotônico: a entrada cresce e a saída diminui conforme aumenta a proporção de vizinhos com pagamento ao mesmo CNPJ."),
          div(
            class = "result-pair",
            div(
              h4("Entrada ou retorno"),
              doc_table(
                c("Vizinhos em t−1", "Exposições", "Eventos", "Taxa"),
                list(
                  list("0%", "724.512", "335", "0,05%"),
                  list("0–20%", "8.347", "196", "2,35%"),
                  list("20–40%", "6.362", "310", "4,87%"),
                  list("40–60%", "2.365", "268", "11,33%"),
                  list("60–80%", "914", "164", "17,94%"),
                  list("Acima de 80%", "416", "122", "29,33%")
                )
              )
            ),
            div(
              h4("Saída"),
              doc_table(
                c("Vizinhos em t−1", "Exposições", "Eventos", "Taxa"),
                list(
                  list("0%", "734", "179", "24,39%"),
                  list("0–20%", "927", "127", "13,70%"),
                  list("20–40%", "2.364", "218", "9,22%"),
                  list("40–60%", "2.821", "209", "7,41%"),
                  list("60–80%", "2.685", "132", "4,92%"),
                  list("Acima de 80%", "3.311", "101", "3,05%")
                )
              )
            )
          )
        ),
        div(
          class = "doc-section",
          h3("Sensibilidades da regra de presença"),
          p("A análise foi repetida para verificar se restos a pagar ou pagamentos pequenos produziam artificialmente o resultado."),
          doc_table(
            c("Regra anual", "OR entrada por +10 p.p.", "OR saída por +10 p.p."),
            list(
              list("Valor total positivo — principal", "2,22", "0,79"),
              list("Somente valor corrente positivo", "2,23", "0,80"),
              list("Valor total mínimo de R$ 100", "2,22", "0,79"),
              list("Valor total mínimo de R$ 1.000", "2,24", "0,80")
            )
          ),
          div(class = "doc-conclusion", strong("Conclusão provisória"), p("A associação espacial é forte, monotônica e estável às regras alternativas de valor. Isso justifica avançar para modelos com características municipais e áreas de política pública."))
        )
      ),

      nav_panel(
        "6. Limites e validação",
        div(
          class = "doc-section",
          h3("O que os resultados mostram — e o que não mostram"),
          div(
            class = "interpret-grid",
            div(
              class = "interpret-box can",
              h4("Podemos afirmar"),
              tags$ul(
                tags$li("Há pagamentos observados por município, CNPJ e ano."),
                tags$li("Os movimentos podem ser classificados temporalmente."),
                tags$li("A integração territorial anterior está fortemente associada aos movimentos."),
                tags$li("O resultado é estável a regras alternativas de valor.")
              )
            ),
            div(
              class = "interpret-box cannot",
              h4("Ainda não podemos afirmar"),
              tags$ul(
                tags$li("Que houve adesão ou desligamento jurídico."),
                tags$li("Que o consórcio foi criado ou extinto."),
                tags$li("Que a vizinhança causou o movimento."),
                tags$li("Qual mecanismo político, fiscal ou institucional produziu o resultado.")
              )
            )
          )
        ),
        div(
          class = "doc-section",
          h3("Limitações atuais"),
          doc_table(
            c("Limitação", "Consequência", "Tratamento atual ou futuro"),
            list(
              list("MIDES observa pagamento, não vínculo legal", "Ausência pode significar falta de pagamento, não saída formal.", "Usar sempre a expressão movimento financeiro observado."),
              list("Matriz e filial separadas", "Trocas internas de CNPJ podem gerar movimentos artificiais.", "Manter alerta até decisão de consolidação por raiz."),
              list("Malha municipal fixa de 2020", "Supõe fronteiras constantes em 2014–2021.", "Aceitável para MG no período; registrar a referência cartográfica."),
              list("Poucos controles substantivos", "Características omitidas podem explicar parte da associação.", "Adicionar população, capacidade fiscal, mandato e área de política pública."),
              list("Eventos raros no universo de entrada", "Odds ratios podem parecer muito elevados em comparações binárias.", "Priorizar o gradiente por 10 pontos percentuais e as taxas observadas."),
              list("Primeiro ano da janela", "2014 é base inicial, não uma entrada identificável.", "Não inferir movimento anterior a 2014.")
            )
          )
        ),
        div(
          class = "doc-section",
          h3("Validações executadas"),
          div(
            class = "validation-list",
            div(strong("✓"), p("Chaves únicas nos universos de entrada e saída.")),
            div(strong("✓"), p("Partição exata dos 853 municípios em cada CNPJ-ano elegível.")),
            div(strong("✓"), p("Reprodução integral das 966 saídas observadas.")),
            div(strong("✓"), p("Reconciliação dos 1.813 eventos de entrada e retorno: 1.395 modelados e 418 documentados fora do risco espacial.")),
            div(strong("✓"), p("Recalculo independente de 500 exposições espaciais, sem divergências.")),
            div(strong("✓"), p("Convergência dos modelos e estabilidade nas quatro regras de presença."))
          )
        ),
        tags$details(
          class = "doc-detail",
          tags$summary("Arquivos técnicos e reprodutibilidade"),
          tags$ul(
            tags$li(tags$code("analises/movimentos_espaciais/01_materializar_movimentos_mides.R")),
            tags$li(tags$code("analises/movimentos_espaciais/02_features_espaciais_fronteira.R")),
            tags$li(tags$code("analises/movimentos_espaciais/05_modelar_riscos_entrada_saida.R")),
            tags$li(tags$code("analises/movimentos_espaciais/tests/06_validar_modelos_risco.R")),
            tags$li(tags$code("analises/movimentos_espaciais/07_eda_modelos_risco.R")),
            tags$li(tags$code("analises/movimentos_espaciais/METODOLOGIA_MODELOS_RISCO.md")),
            tags$li(tags$code("analises/movimentos_espaciais/RESULTADOS_MODELOS_RISCO.md"))
          )
        ),
        tags$details(
          class = "doc-detail",
          tags$summary("Referências metodológicas próximas"),
          tags$ul(
            tags$li(tags$a(href = "https://repositorio.ufpe.br/bitstream/123456789/56301/1/DISSERTA%C3%87%C3%83O%20Pedro%20Buril%20Saraiva%20Lins.pdf", target = "_blank", "Difusão dos consórcios públicos intermunicipais no Brasil: uma análise de sobrevivência.")),
            tags$li(tags$a(href = "https://www.ec.unipi.it/documents/Ricerca/papers/2015-202.pdf", target = "_blank", "Local government cooperation at work: a control function approach.")),
            tags$li(tags$a(href = "https://www.scielo.br/j/urbe/a/TrpyCsvmHJkx3N8rB4BjsSn/?format=html", target = "_blank", "Ação coletiva institucional e consórcios públicos intermunicipais no Brasil."))
          )
        )
      )
    )
  )
}
