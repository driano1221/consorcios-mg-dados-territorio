# Diario De Trabalho - Consorcios MG

**Uso:** registro breve por data de trabalho. Complementa as atas e a memoria consolidada: documenta o que foi alterado, validado e deixado pendente.

## Como Registrar

Ao encerrar uma sessao relevante, adicionar uma entrada com:

1. decisoes recebidas;
2. entregas e arquivos alterados;
3. validacoes executadas;
4. pendencias que permanecem abertas.

---

## 2026-07-28 - Movimentos Anuais E Features Espaciais MIDES

### Decisoes Aplicadas

- A analise usa exclusivamente o MIDES completo de 2014 a 2021; MUNIC e SICONFI nao entram nesta frente.
- Presenca foi definida como `valor_total > 0` e recebe o nome metodologico de pagamento observado no MIDES.
- Matriz e filial continuam como CNPJs separados.
- Vizinhos municipais exigem fronteira compartilhada em linha; contato em um ponto nao conta.

### Entregas

- Criada a pasta `analises/movimentos_espaciais/`, com scripts reprocessaveis, README e teste automatizado.
- `01_materializar_movimentos_mides.R` gerou 22.680 linhas balanceadas: 2.835 pares municipio-CNPJ observados x 8 anos.
- Eventos materializados: `base_inicial`, `entrada_observada`, `retorno_observado`, `permaneceu`, `saida_observada` e `ausente`.
- Criadas tabelas por par, consorcio-ano e municipio-ano; 673 pares tiveram duas ou mais transicoes observadas.
- `02_features_espaciais_fronteira.R` usou a malha municipal completa geobr/IBGE 2020 e encontrou 2.375 fronteiras compartilhadas entre os 853 municipios de MG.
- Para cada participante, foram calculados vizinhos dentro/fora do consorcio, proporcoes, borda e isolamento.
- Foi criado o universo de 18.404 candidatos externos de borda para analisar entradas; 1.060 entradas/retornos observados ocorreram nesse universo.
- Nenhuma dessas bases foi integrada ou publicada no dashboard.

### Validacoes

- Regra de presenca reconciliada com `valor_total > 0`.
- Teste automatizado confirmou 2.835 pares, 22.680 linhas anuais, 853 municipios com vizinhanca e 2.375 divisas positivas.
- Todos os eventos de saida possuem exposicao espacial medida no ano anterior.
- O cache da vizinhanca evita recalcular intersecoes de geometria em reexecucoes: apos a primeira execucao, a etapa espacial passou de cerca de dois minutos para poucos segundos.

### Pendencia

- Validar resultados descritivos e decidir o desenho da analise estatistica antes de integrar qualquer tabela ou mapa ao dashboard.

### EDA De Validacao

- `04_eda_validacao_movimentos_espaciais.R` e `EDA_RESULTADOS.md` registraram a revisao reproduzivel das bases e amostras com semente fixa `20260728`.
- Integridade aprovada: nenhuma duplicata, valor negativo, perda financeira ou municipio sem vizinho.
- Resultado espacial preliminar: taxa de saida caiu de 24,4% entre isolados para 3,1% quando mais de 80% dos vizinhos estavam no mesmo consorcio; entre candidatos externos, a taxa de entrada subiu de 2,4% para 29,3% conforme aumentou a proporcao de vizinhos participantes.
- Alertas: 252 presencas apenas por restos a pagar, 62 entradas/retornos apenas por restos, 184 valores abaixo de R$ 1.000, 25 transicoes internas entre CNPJs da mesma raiz e forte ruido nos nomes declarados no MIDES.
- Antes do dashboard, separar semanticamente borda de participante e candidato externo, usar nome canonico do cadastro e decidir analises de sensibilidade.

---

## 2026-07-28 - Classificacao v0.5, Documentacao E Repositorio

### Decisoes Incorporadas

- Validar os 94 casos `provisoria_coerente` para uso analitico.
- Manter a regra matriz-filial apenas para classificacao de area e perfil; nao consolidar pagamentos, pares ou movimentos.
- Manter 16 multifinalitarios/multissetoriais apenas como perfil institucional quando nao houver area setorial explicita.
- Retirar da camada analitica ativa os seis CNPJs inaptos ou baixados, preservando-os na camada tecnica.

### Entregas

- Criada a camada analitica `v0.5` por `analises/classificacao_politicas/07_consolidar_classificacao_v0_5.R`.
- Resultado v0.5: 217 CNPJs ativos; 94 coerentes validados; 63 validados por cadastro/nome; 34 confirmados; 7 com area explicita por nome/alias; 16 perfis sem area; 2 filiais herdadas; 1 fora do escopo.
- Criada a referencia central `docs/METODOLOGIA_CLASSIFICACAO_ATUAL.md`.
- A aba `Definicoes` do dashboard foi substituida por `Documentacao`, com Guia do painel, Conceitos e Classificacao de areas.
- Adicionados 16 icones `i` com tooltip aos filtros das tres telas analiticas: Recorte 2015/2019, MIDES completo e 2015 vs 2019.
- Reescrito `README.md` como porta de entrada e criado `docs/ESTRUTURA_REPOSITORIO.md`.
- Repositorio Git local inicializado; dados pesados, outputs, logs, dependencias e artefatos gerados foram colocados no `.gitignore`.

### Validacoes

- Script v0.5 reexecutado: 217 CNPJs ativos, 94 coerentes validados e 16 perfis sem area.
- `dashboards/base1_shiny/app.R` carregado com sucesso por R.
- Verificacao no navegador local: aba Documentacao e suas tres subabas renderizaram; 16 tooltips encontrados com texto e descricao acessivel.
- Dashboard republicado e respondendo: <https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/>.

### Commits

- `ff19f0f chore: organizar base inicial do ideiaMides`
- `98c5a0d dashboard: adicionar ajuda contextual aos filtros`

---

## 2026-07-28 - Refinamento Dos Filtros De Classificacao

### Problema Corrigido

- Os filtros de classificacao exibiam codigos e combinacoes tecnicas, como `agricultura; desenvolvimento_regional`, inadequadas para consulta.
- O antigo rotulo `Sem classificacao ativa` misturava perfil sem area, CNPJ inativo/baixado e CNPJ fora do universo MG da classificacao.

### Entregas

- Campos de selecao passaram a indicar `Selecionar`; campos de texto, `Digitar`.
- Area detalhada, macrogrupo e perfil exibem rotulos legiveis e opcoes individuais.
- A selecao de area usa correspondencia por componente: selecionar `Saude` encontra CNPJs com essa area mesmo que tenham outras areas associadas.
- `Documentacao > Classificacao de areas` passou a explicar a diferenca entre area detalhada, macrogrupo e perfil institucional, inclusive os cinco perfis possiveis.
- Incluida tabela de cobertura da classificacao no MIDES completo, sem transformar ausencia de area em categoria substantiva de filtro.

### Situacao Observada No MIDES Completo

- 16 CNPJs ativos sem area especifica comprovada: 12 multifinalitarios, 3 multissetoriais e 1 associacao municipal fora de escopo.
- 8 CNPJs presentes no MIDES completo estao fora do universo de 223 CNPJs MG da classificacao.
- 1 CNPJ presente no MIDES completo esta inativo ou baixado na camada classificatoria.
- Esses registros continuam no MIDES e em seus totais; apenas nao aparecem como uma falsa area de politica publica.

### Validacoes

- `tests/test_classificacao_v0_5.R` aprovado: preservacao de 15.135 linhas e 161 CNPJs MIDES, filtros de area/macrogrupo/perfil, cobertura e dados de mapa.
- Servidor Shiny local respondeu HTTP 200 apos as alteracoes.
- Dashboard republicado e verificado por HTTP 200: <https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/>.

### Pendencias Mantidas

- Decidir se matriz/filial sera consolidada financeiramente e nos movimentos.
- Nao iniciar ainda a frente 3: base anual formal de movimentos municipio x consorcio x ano.

---

## 2026-07-28 - Simplificacao Da Classificacao E Da Documentacao

### Decisoes Aplicadas

- Os perfis `multifinalitario` e `multissetorial` foram unificados em `multifinalitario_ou_multissetorial`.
- A AMESP foi retirada da camada analitica de consorcios por ser associacao municipal; seu registro MIDES permaneceu preservado.
- A tabela de cobertura foi removida da aba `Documentacao`. A cobertura passou a ser explicada em texto breve, sem expor registros individuais nessa tela.

### Entregas

- A v0.5 foi regenerada com 223 CNPJs tecnicos e 216 CNPJs analiticos ativos.
- O filtro de perfil passou a ter tres opcoes: `Setorial`, `Multiarea documentada` e `Multifinalitario ou multissetorial`.
- O rotulo de cobertura foi corrigido para `Consorcio sediado fora de MG`.
- A documentacao do dashboard passou a descrever a classificacao como processo ja executado, com fontes, regras aplicadas, cobertura e limites atuais.

### Cobertura MIDES Mantida

- Dos 161 CNPJs observados no MIDES completo: 136 tem area classificada; 15 tem perfil amplo sem area comprovada; 8 sao sediados fora de MG; 1 esta inativo ou baixado; e 1 e entidade associativa fora do escopo.
- Nenhuma linha, valor, par ou movimento MIDES foi removido ou agregado.

### Validacoes

- `07_consolidar_classificacao_v0_5.R` e `preparar_classificacao_v0_5.R` executados com sucesso.
- `tests/test_classificacao_v0_5.R` aprovado com os novos perfis e as contagens de cobertura.
- `app.R` carregado com sucesso pelo R.
- Dashboard republicado e verificado por HTTP 200: <https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/>.

---

## 2026-07-28 - Integracao v0.5 ao MIDES completo

### Decisao e escopo

- A classificacao v0.5 passou a integrar a tela `MIDES completo` exclusivamente como atributo do CNPJ do consorcio.
- A integracao e feita por `left_join`: nenhum pagamento, par municipio-consorcio, ano ou movimento foi removido, agregado ou reclassificado.
- CNPJs sem classificacao ativa continuam no painel sob o rotulo `Sem classificacao ativa`; portanto, o filtro nao reduz silenciosamente o universo historico.

### Entregas

- Incluidos os filtros multiplos `Area de politica publica`, `Macrogrupo` e `Perfil institucional` na tela MIDES completo.
- Incluidas as tres colunas correspondentes na tabela detalhada MIDES.
- Criados `dashboards/base1_shiny/preparar_classificacao_v0_5.R` e `dashboards/base1_shiny/tests/test_classificacao_v0_5.R`.
- O script de deploy passou a usar caminho relativo ao repositorio, sem depender de diretorios locais alternativos.

### Validacoes

- Camada v0.5 preparada com 223 CNPJs tecnicos, 217 ativos e 94 casos coerentes validados.
- Teste automatizado aprovado: preservacao de 15.135 linhas MIDES e 161 CNPJs, filtros por area, macrogrupo, perfil e sem classificacao ativa, mapa e base de movimentos.
- Teste visual local aprovado: os filtros alteram KPIs e mapa; `Limpar MIDES` restaura o universo; o mapa de movimentos permanece renderizavel com os atributos aplicados.

### Publicacao e versionamento

- Dashboard republicado em <https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/>.
- Repositorio remoto criado inicialmente em <https://github.com/driano1221/ideiaMides>; em 29/07, ele foi tornado publico, profissionalizado e renomeado para `ideiamides-consorcios-mg`.
- Regra operacional definida: ao concluir uma sessao relevante, atualizar este diario, criar commit e enviar para `origin`.

---

## 2026-07-28 - Universos De Risco E Modelos Espaciais MIDES

### Revisao Metodologica

- A antiga base de entrada continha apenas 18.404 candidatos externos adjacentes. Ela foi preservada como subconjunto, mas deixou de ser o universo principal.
- O novo universo cruza cada CNPJ ativo em `t-1` com os 853 municipios de MG e exclui apenas quem ja participava em `t-1`.
- Entrada nova e retorno passaram a ter conjuntos de risco separados.
- Eventos sem nenhum municipio ativo no CNPJ em `t-1` foram retirados do modelo espacial e documentados separadamente.
- Os termos foram diferenciados: candidato externo adjacente, participante na borda e participante isolado.

### Entregas

- Criado `analises/movimentos_espaciais/05_modelar_riscos_entrada_saida.R`.
- Criados `tests/06_validar_modelos_risco.R` e `07_eda_modelos_risco.R`.
- Criados `METODOLOGIA_MODELOS_RISCO.md` e `RESULTADOS_MODELOS_RISCO.md`.
- Universo principal de entrada: 742.916 exposicoes e 1.395 entradas/retornos.
- Universo principal de saida: 12.842 exposicoes e 966 saidas.
- Fora do modelo espacial: 418 eventos, sendo 387 primeiros aparecimentos de CNPJ na janela e 31 reaparecimentos apos lacuna completa.

### Modelos E Resultados

- Regressao logistica com exposicao espacial em `t-1`, tamanho do consorcio, grau municipal e efeitos fixos de ano.
- Erros-padrao agrupados por municipio e CNPJ.
- Aumento de 10 pontos percentuais na proporcao de vizinhos participantes: OR 2,22 para entrada/retorno e OR 0,79 para saida.
- Entrada nova: OR 2,20; retorno: OR 1,26.
- Participante isolado: OR 3,98 para saida.
- Sensibilidades com pagamento corrente, minimo de R$ 100 e minimo de R$ 1.000 mantiveram os sinais e magnitudes principais.

### Validacoes

- Chaves unicas e particao exata dos 853 municipios em cada CNPJ-ano elegivel.
- Reproducao integral das 966 saidas e dos 1.813 eventos de entrada/retorno, considerando modelados e excluidos.
- Recalculo independente de 500 exposicoes espaciais sem divergencia.
- Scripts de validacao aprovados.
- Nada foi integrado ao dashboard nesta sessao.

### Limites Mantidos

- Movimento significa pagamento observado no MIDES, nao adesao ou desligamento juridico.
- Matriz e filial continuam separadas.
- Os resultados sao associativos e exploratorios; ainda faltam controles socioeconomicos, fiscais, politicos, setoriais e institucionais.

---

## 2026-07-28 - Documentacao Dos Movimentos Espaciais No Dashboard

### Objetivo

- Transformar os resultados tecnicos de movimentos e exposicao espacial em uma leitura didatica e auditavel para a equipe do IPEA.
- Explicar a passagem do pagamento anual MIDES aos indicadores territoriais e modelos sem confundir movimento financeiro com adesao juridica.

### Entregas

- Criado `dashboards/base1_shiny/documentacao_movimentos.R` como modulo independente da aba `Documentacao > Movimentos espaciais`.
- A documentacao foi organizada em seis partes: ideia e dados; pipeline e indicadores; universos de risco; exemplo real; modelo e resultados; limites e validacao.
- Incorporadas as figuras `pipeline_movimentos_mides.png` e `exposicao_espacial_mides.png` em `dashboards/base1_shiny/www/`.
- Incluido o exemplo real Pote x CISNORJE: ausencia de pagamento entre 2014 e 2020, pagamento de R$ 27.210,15 em 2021 e cinco de cinco vizinhos com pagamento ao mesmo CNPJ em 2020.
- Documentados os universos de entrada e saida, as exclusoes dos modelos, a especificacao estatistica, os odds ratios, as taxas observadas, as sensibilidades de valor e as limitacoes atuais.

### Validacoes

- Criado `dashboards/base1_shiny/tests/test_documentacao_movimentos.R` para conferir imagens, textos, numeros, serie anual e os cinco vizinhos do exemplo.
- `tests/test_documentacao_movimentos.R` e `tests/test_classificacao_v0_5.R` aprovados.
- Aplicacao carregada localmente e respondendo HTTP 200.
- Inspecao visual executada no navegador nas seis secoes; imagens carregadas em 1.672 x 941 pixels, sem overflow horizontal.
- Conferidos no DOM os resultados principais: OR 2,22 para entrada/retorno, OR 0,79 para saida e OR 3,98 para participante isolado.
- Dashboard republicado com 15 arquivos no pacote e verificado em <https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/>.

### Estado Ao Final

- A analise espacial continua exploratoria e associativa.
- Os resultados agora estao documentados no dashboard, mas ainda nao foram transformados em filtros ou visualizacoes analiticas proprias.
- A decisao sobre consolidacao de matriz e filial permanece pendente e nenhuma agregacao por raiz de CNPJ foi aplicada.

---

## 2026-07-28 - Revisao Didatica Da Documentacao Espacial

### Problemas Corrigidos

- A elegibilidade do exemplo Pote x CISNORJE nao estava suficientemente explicita, embora o caso ja pertencesse ao modelo de entrada nova.
- A figura conceitual podia dar a impressao de que existiam apenas quatro features.
- A secao de resultados apresentava odds ratios sem exemplos numericos de leitura.
- A linha zerada de 2020 precisava ser identificada como produto do balanceamento do painel, nao como pagamento original MIDES.

### Alteracoes

- Incluido icone informativo nas 2.375 fronteiras, definidas como pares unicos de municipios que compartilham uma linha de divisa; contato por ponto e excluido.
- As duas figuras foram reduzidas em aproximadamente 30% no desktop, mantendo largura integral em telas pequenas.
- Documentadas nove variaveis espaciais: seis medidas numericas e tres indicadores binarios; tamanho do consorcio foi separado como controle.
- Adicionados exemplos em todas as seis secoes da documentacao.
- O caso Pote x CISNORJE passou a percorrer dados, balanceamento, classificacao temporal, elegibilidade, vizinhanca, indicadores e linha final do modelo.
- Incluidos contrastes reais: Marilac como saida elegivel e Agua Comprida x CONECTAR como primeiro aparecimento fora do modelo espacial.
- Formulas de presenca, proporcao, regressao logistica, odds ratio e taxa foram renderizadas com MathJax/LaTeX.
- Adicionados exemplos numericos para OR 2,22 e OR 0,79, diferenciando odds, probabilidade e taxa bruta.

### Validacoes

- Teste da documentacao ampliado para conferir elegibilidade, exclusao, saida isolada, comprimento de divisa e novos textos.
- `tests/test_documentacao_movimentos.R` e `tests/test_classificacao_v0_5.R` aprovados.
- Inspecao visual local aprovada: formulas renderizadas, figuras com 767 pixels exibidos a partir de originais de 1.672 pixels e ausencia de overflow horizontal.
- Dashboard republicado e conferido no shinyapps.io: exemplo elegivel, figuras reduzidas, icone informativo e largura da pagina validados.

---

## 2026-07-28 - Correcao De Navegacao E Teste Funcional Completo

### Incidente

- Apos a inclusao das formulas, as paginas `MIDES completo` e `2015 vs 2019` deixaram de responder na versao publicada.
- O problema foi reproduzido: `withMathJax()` executava processamento global sobre o DOM completo do Shiny e bloqueava a troca de abas.

### Correcao

- Removido o MathJax global e qualquer dependencia JavaScript de formula.
- As formulas passaram a ser renderizadas estaticamente apenas na documentacao, com tipografia matematica, subscritos, sobrescritos e fracoes em HTML/CSS.
- O teste automatizado agora impede a reintroducao de MathJax no modulo.

### Testes Funcionais

- Paginas principais aprovadas: Visao geral, Recorte 2015/2019, MIDES completo, 2015 vs 2019, Auditoria e Documentacao.
- Recorte: Leitura, Tabela, Mapa fontes e SICONFI municipio-ano aprovados.
- MIDES: Mapa, Entradas/saidas, Resumo anual e Tabela detalhada aprovados.
- Comparacao: Mapa e Tabela aprovados.
- Auditoria: Raiz CNPJ, Nomes juridicos, Nomes parecidos e Mesmo nome no municipio-ano aprovados.
- Documentacao: quatro secoes externas e seis secoes de movimentos espaciais aprovadas.
- Nenhum erro de console foi observado.

### Testes Reativos

- Busca do recorte: 4.046 pares para 7 em Corrego Danta; limpeza restaurou 4.046.
- Busca MIDES: 15.131 linhas para 9 em Pote; mapa permaneceu renderizado; limpeza restaurou 15.131.
- Comparacao: 2.484 pares para 4 em Corrego Danta; mapa permaneceu renderizado; limpeza restaurou 2.484.
- Correcao republicada no shinyapps.io; as seis paginas principais abriram em aproximadamente 1,2 a 3,1 segundos, sem erros de console.
- Na versao online, o filtro MIDES repetiu 15.131 -> 9 -> 15.131 e a comparacao repetiu 2.484 -> 4 -> 2.484, com mapas preservados.

---

## 2026-07-29 - Tabela Anual, Rotulos E Exportacao Cartografica

### Entregas

- Integrada ao app a serie balanceada `movimentos_municipio_consorcio_ano.rds`, com 22.680 observacoes, 2.835 pares municipio-CNPJ e 161 CNPJs.
- Criada `MIDES completo > Movimentos por consorcio`: uma linha por CNPJ e ano, com ativos, entradas novas, retornos, saidas, permanencias, saldo, recorrentes e valor MIDES.
- O botao `+` abre listas separadas dos municipios de cada movimento, incluindo a base inicial de 2014.
- Formalizada a regra de rotulos: nomes aparecem quando o recorte tem ate 12 municipios destacados.
- Mapas com rotulos recebem zoom contextual e corte previo da geometria, preservando municipios vizinhos e reduzindo o custo de renderizacao.
- Adicionados botoes proprios de exportacao aos quatro mapas: PNG 450 dpi nos mapas individuais, PNG 300 dpi nos pequenos multiplos e PDF vetorial.

### Validacoes

- O caso CODAP em 2019 foi conferido: 10 ativos, 5 entradas novas, 1 retorno, 0 saidas, 4 permanencias, saldo +6 e 1 municipio recorrente.
- A tabela expansivel foi validada visualmente no navegador, inclusive a lista real de Silverania como saida observada.
- Os mapas MIDES e de fontes foram testados com filtros pequenos; nomes, zoom, contexto territorial e botoes de exportacao permaneceram legiveis.
- Criado `tests/test_movimentos_mapas_export.R`, cobrindo contagens, limite de rotulos, recorte espacial, quatro construtores de mapa e arquivos PNG/PDF.
- O PNG individual foi validado em 5.400 x 3.600 pixels; o PDF foi validado pelo cabecalho `%PDF`.
- As seis paginas principais foram reabertas no navegador sem erro; a tabela anual, os tres recortes cartograficos e o mapa anual responderam aos filtros reais.
- A versao foi republicada no shinyapps.io; tabela, mapa, links PNG/PDF e um download PNG real foram conferidos online, sem erros no console.

### Decisoes

- Saldo significa `entradas novas + retornos - saidas` e descreve movimento financeiro observado, nao mudanca juridica.
- Recorrente significa duas ou mais mudancas de presenca no periodo 2014-2021.
- A consolidacao matriz/filial permanece fora desta entrega e podera alterar contagens somente depois de decisao formal.

---

## 2026-07-29 - Trajetoria Longitudinal MIDES 2014-2021

### Objetivo

- Complementar a consulta anual por consorcio com uma leitura unica dos oito anos.
- Permitir identificar quando municipios entraram, retornaram, permaneceram ou deixaram de apresentar pagamento ao mesmo CNPJ.

### Entregas

- Criada a subaba `MIDES completo > Trajetoria 2014-2021`.
- A tabela principal apresenta uma linha por consorcio e oito blocos anuais com ativos, entradas novas, retornos e saidas, alem de saldo, recorrentes e valor MIDES.
- Em filtros de ate cinco consorcios, o botao `+` abre KPIs do periodo, linha do tempo anual, tabela analitica, matriz municipio x ano e listas nominais por evento.
- A matriz diferencia base inicial, permanencia, entrada nova, retorno, saida e ausencia; o tooltip informa municipio, ano, evento e valor.
- Adicionado download CSV dos movimentos filtrados.
- A geracao dos detalhes pesados foi limitada a cinco consorcios. A comparacao geral de 161 CNPJs permanece disponivel sem construir matrizes desnecessarias.

### Exemplo Validado

- CODAP: 2 municipios ativos em 2014 e 20 em 2021, saldo acumulado de +18.
- Em 2019: 10 ativos, 5 entradas novas, 1 retorno e nenhuma saida.
- Entre Rios de Minas aparece como entrada em 2016, saida em 2017 e retorno em 2019.

### Testes E Validacao Visual

- Criado `dashboards/base1_shiny/tests/test_trajetoria_longitudinal.R`.
- Aprovados os testes de classificacao v0.5, documentacao espacial, mapas/exportacao e trajetoria longitudinal.
- Revisadas visualmente a comparacao geral, a expansao CODAP, a matriz e a adaptacao para tela pequena.
- As seis paginas principais foram reabertas; nenhuma apresentou erro de console.

### Estado Ao Final

- A frente 5 do plano esta concluida em duas visoes complementares: consulta anual e trajetoria 2014-2021.
- Entrada, retorno e saida continuam significando mudanca na presenca de pagamento MIDES, nao ato juridico de adesao ou desligamento.
- Matriz e filiais continuam separadas ate decisao formal da equipe.

### Refinamento Visual E De Interacao

- Removida a secao redundante `Listas de municipios por evento`; a tabela anual e a matriz permanecem como detalhamento principal.
- O simbolo circular de retorno foi retirado dos resumos e da tabela anual. Os blocos usam os rotulos `Entr.`, `Ret.` e `Sai.`, explicados no cabecalho.
- Os oito blocos anuais receberam maior contraste, borda continua, numero de ativos mais visivel e espacamento mais regular.
- Eliminado o limite de cinco consorcios: o detalhe passou a ser calculado sob demanda pelo servidor quando o usuario clica no `+`.
- A abertura sem filtro foi testada no universo geral de 161 CNPJs; o detalhe carregou sem erro e sem reconstruir previamente todas as matrizes.
- Os blocos compactos foram redesenhados como pequenos multiplos de relatorio: faixa anual, numero principal de municipios ativos e tres linhas tabulares para entradas, retornos e saidas.
- A largura minima passou a 116 pixels, os textos de evento a 10 pixels e os valores a 11 pixels; a validacao automatizada no navegador confirmou ausencia de quebra de linha.

---

## 2026-07-29 - Profissionalizacao Do Repositorio Publico

### Objetivo

- Transformar o GitHub em uma porta de entrada clara para o projeto, sem confundir pesquisa em desenvolvimento com produto institucional oficial.
- Consolidar finalidade, fontes, arquitetura, produtos, limites e rotina de contribuicao.

### Entregas

- Reescrito o `README.md` com escopo, perguntas de pesquisa, fontes, estado atual, arquitetura, execucao, testes e limitacoes.
- Criados `CONTRIBUTING.md`, `CHANGELOG.md` e `.github/pull_request_template.md`.
- Atualizados `docs/ESTRUTURA_REPOSITORIO.md`, `docs/DICIONARIO_MEMORIAS.md` e os READMEs das analises e do dashboard.
- Adicionado aviso explicito de que o repositorio representa pesquisa em desenvolvimento e nao uma posicao institucional oficial do IPEA.
- Nome publico definido como `ideiaMides | Consorcios Intermunicipais de Minas Gerais` e slug como `ideiamides-consorcios-mg`.
- Mantida a separacao entre codigo/documentacao versionados e bases pesadas locais; o projeto ainda nao possui `renv.lock` nem licenca formal definida.

### Validacoes

- Referencias Markdown internas verificadas.
- Revisado o repositorio para remover descricoes obsoletas sobre movimentos espaciais, trajetoria longitudinal e visibilidade do remoto.
- Metadados do GitHub preparados com descricao, dashboard como homepage e topicos de R, Shiny, politicas publicas, analise espacial e Minas Gerais.

### Identidade Definitiva

- A identidade provisoria `ideiaMides` foi substituida por **Consorcios MG: Dados e Territorio**.
- O produto interativo passou a se chamar **Painel Consorcios MG**.
- O repositorio foi renomeado para <https://github.com/driano1221/consorcios-mg-dados-territorio>.
- Nomes historicos de arquivos, pastas locais e registros antigos foram preservados quando a troca poderia quebrar scripts ou apagar contexto.
- O `app.R` passou nos testes de classificacao v0.5 e trajetoria longitudinal.
- O dashboard foi republicado; a URL existente foi preservada e respondeu `HTTP 200` com o novo titulo.

---

## 2026-08-05 - Guia De Estudo Do Modelo Espacial

### Objetivo

- Reescrever as anotacoes preparadas para a reuniao em um material tecnicamente correto e didatico.
- Permitir explicar a origem dos dados, a construcao dos indicadores, os universos de risco, a regressao logistica, os resultados e os limites da analise.

### Entrega

- Criado `docs/GUIA_MODELO_ESPACIAL_REUNIAO.md`.
- O guia separa pagamentos observados de adesao juridica e esclarece que o modelo e logistico com indicadores espaciais, nao SAR/CAR nem um desenho causal.
- Incluidos formulas, quatro fluxogramas Mermaid, exemplo real Pote x CISNORJE, roteiro de cinco minutos e respostas para perguntas provaveis.
- Os numeros foram conferidos nos scripts e documentos tecnicos: 1.194 CNPJs consultados, 161 observados, 2.835 pares, 22.680 linhas balanceadas, 2.375 fronteiras, 742.916 exposicoes de entrada e 12.842 exposicoes de saida.
- Documentada a diferenca entre os 1.395 eventos de entrada/retorno modelados e os 418 movimentos sem territorio do CNPJ em `t-1`.
- Registrados resultados principais, robustez, alertas de matriz/filial e limitacoes do universo estadual de candidatos.

### Estado Ao Final

- Nenhum script, base ou estimativa foi alterado.
- O documento passa a ser a leitura recomendada antes de apresentar a analise espacial em reuniao.
- A proxima decisao metodologica continua sendo definir controles substantivos, universo territorial alternativo, tratamento matriz/filial e forma funcional da exposicao.
- Em 05/08, o guia recebeu uma bibliografia comentada com as fontes do MiDES, Base dos Dados, geobr/IBGE, `sf`, OGC/DE-9IM, `sandwich`, R e tres trabalhos substantivos sobre difusao e cooperacao intermunicipal.

---

## 2026-08-11 e 2026-08-12 - Esclarecimentos Do Modelo E Auditoria Da Recorrencia

### Objetivo

- Consolidar as explicacoes usadas na reuniao sobre pares, observacoes anuais, universos de risco, efeitos de ano e interpretacao dos modelos.
- Verificar exemplos reais do CIMVA e do indicador de recorrencia exibido no dashboard.

### Verificacoes

- `par municipio-consorcio` significa municipio x CNPJ, sem ano; municipio x CNPJ x ano e uma observacao anual ou par-ano.
- O CIMVA (CNPJ `21466841000169`) passou de 22 municipios pagantes em 2019 para 37 em 2020 e 48 em 2021.
- Exemplos CIMVA conferidos: Iapu entrou em 2021 com 7 de 8 vizinhos pagantes; Jaguaraçu retornou com 4 de 4; Dom Joaquim saiu estando isolado; Entre Folhas permaneceu com 3 de 3.
- Os 22 primeiros pagamentos do CIMVA em 2019 ficam fora do modelo espacial de entrada porque nao existia territorio pagante do CNPJ em 2018.
- Recorrencia foi confirmada como propriedade do par no periodo completo: duas ou mais transicoes de presenca.
- No SIMSAUDE, Silveirania e Visconde do Rio Branco sao os dois pares recorrentes.
- Na tabela anual longitudinal, a coluna `Recorrentes` nao conta recorrencias surgidas naquele ano; conta pares recorrentes do periodo que estavam ativos no ano. O indicador e calculado corretamente, mas o rotulo e ambiguo.

### Documentacao Atualizada

- O guia do modelo passou a explicar efeitos fixos de ano, exclusoes do modelo, exemplo CIMVA e a diferenca entre recorrencia longitudinal e recorrente ativo no ano.
- `docs/PROXIMOS_PASSOS.md` recebeu a pendencia de renomear ou retirar a coluna anual de recorrentes.

### Pendencia

- Corrigir a interface do dashboard. Recomendacao atual: retirar `Recorrentes` da tabela anual e manter apenas o total longitudinal no resumo do consorcio.
- Nenhuma base, modelo ou estimativa foi alterada nesta sessao.

---

## 2026-08-12 - Padrao Permanente De Reunioes E Ata De 06/08

### Entregas

- Criado `docs/reunioes/README.md` como indice e regra permanente.
- Criado `docs/reunioes/TEMPLATE_ATA.md` para novas reunioes semanais.
- Registrada a reuniao presumida de 06/08 em ata individual, com data marcada para confirmacao.
- Separadas decisoes, encaminhamentos, hipoteses e pontos nao decididos.
- Atualizado `docs/PROXIMOS_PASSOS.md` com a auditoria de CNPJs de baixa escala/persistencia e a pesquisa de distancia rodoviaria.

### Cuidados

- O resumo automatico foi confrontado com a transcricao.
- Nao foi registrada exclusao automatica de CNPJs com 0-2 municipios.
- SICONFI foi mantido como validacao municipal agregada, sem CNPJ destinatario.
- Informacoes pessoais e administrativas sem impacto no projeto foram removidas.

---

## 2026-08-12 - Interface Unica Da Memoria No Obsidian

### Entrega

- O vault pessoal do IPEA passou a ter uma unica entrada (`PAINEL_IPEA`) e uma unica memoria narrativa vigente (`MEMORIA_PROJETO`).
- Reunioes e diarios continuam como registros datados; documentos anteriores foram preservados como historico ou atalhos.
- O painel recebeu fluxos Mermaid para explicar atualizacao da memoria, linha do tempo e arquitetura das notas.
- Criada e validada a skill pessoal `ipea-vault`, que identifica pedidos naturais de briefing, atualizacao de memoria, registro de reuniao e auditoria do vault.
- Consolidado o registro duplicado de 12/08 em um unico diario da data.

### Validacao

- Todos os links internos adicionados ao painel e a memoria apontam para arquivos existentes.
- A skill passou no validador oficial de skills.
- O repositorio nao recebeu alteracao de codigo, base, dashboard ou metodologia nesta etapa.

---

## 2026-08-12 - Auditoria De Baixa Escala E Correcao Da Recorrencia

### Entregas

- Materializada auditoria reproduzivel de CNPJs com no maximo dois municipios pagantes em qualquer ano do MIDES 2014-2021.
- Identificados 23 CNPJs: 12 com maximo anual de um municipio, 11 com maximo de dois e 6 filiais.
- Classificados apenas padroes observaveis: 11 continuos em baixa escala, 5 intermitentes e 7 observados em um ano.
- Criada a aba `Auditoria > Baixa escala MIDES`, com filtros, KPIs e exportacao da tabela.
- Hipoteses de revisao foram explicitamente separadas de conclusoes; nenhum CNPJ foi excluido e nenhum modelo foi reestimado.
- A coluna anual `Recorrentes` foi retirada das tabelas anuais. O total de pares recorrentes foi preservado na trajetoria longitudinal do consorcio.

### Validacao

- Testes automatizados confirmaram os 23 CNPJs, a distribuicao 12/11, os 6 estabelecimentos filiais e os tres padroes temporais.
- Testes existentes de classificacao, documentacao, trajetoria, mapas e exportacao permaneceram aprovados.
- A interface foi inspecionada localmente; filtros, reset e responsividade foram conferidos sem rolagem horizontal da pagina.

### Pendencia

- Revisar documentalmente os 23 casos, com prioridade para filiais e observacoes pontuais.
- Decidir matriz/filial com os superiores antes de consolidar CNPJs ou recalcular valores.

---

## 2026-08-20 - Identidade CNPJ E Primeira Base MIDES Nacional

### Objetivo

- Consolidar matriz e filiais pela raiz de oito digitos sem perder a identidade original.
- Ampliar a extracao MIDES para todos os CNPJs do cadastro IPEA e todas as UFs com correspondencia.
- Executar a implementacao em camada separada, sem alterar o dashboard MG antes da validacao.

### Entregas

- Criados crosswalk nacional e cadastro consolidado para 1.194 CNPJs e 1.159 entidades.
- Identificadas 23 raizes com matriz e filial e incorporadas 35 filiais.
- Baixadas 1.300.862 transacoes MIDES de oito UFs pagadoras.
- Materializados paineis anuais por CNPJ original e por raiz consolidada.
- Preservados os CNPJs e nomes de origem em cada agregacao.
- Criadas EDA, amostras, comparacao por UF, lista de colisoes e grafico de cobertura.
- Documentada a metodologia e criado relatorio de validacao para revisao humana.

### Validacao

- 512 CNPJs MIDES foram consolidados em 505 raizes.
- 40.535 linhas anuais originais passaram a 40.486 linhas consolidadas.
- 7.587 pares originais passaram a 7.560 pares consolidados.
- Seis raizes e 49 chaves municipio-ano foram efetivamente afetadas.
- R$ 15.168.694.503,38 foram integralmente conservados no painel municipal.
- As 15.135 linhas do painel MG anterior foram reproduzidas exatamente antes da consolidacao.
- 681 registros catarinenses sem municipio foram preservados fora da camada municipal.

### Pendencias

- Validacao substantiva das seis raizes afetadas no MIDES.
- Definicao da janela temporal nacional comparavel.
- Decisao sobre os registros de SC sem chave municipal.
- Integracao futura ao dashboard, movimentos, classificacoes e modelos somente apos aprovacao.

---

## 2026-08-20 - Integracao MIDES Brasil Ao Dashboard

### Entregas

- Criada a visao separada `MIDES completo > Brasil`, sem substituir a consulta MG.
- Incorporados os dois universos: 1.159 entidades cadastrais e 505 raizes com algum registro MIDES.
- Adicionados filtros por periodo, UF pagadora, UF sede, municipio, entidade consolidada e busca livre.
- Adicionados mapa nacional, movimentos anuais, tabela por consorcio, trajetoria, resumo, tabela detalhada e exportacoes.
- Criada linha do tempo que preserva o periodo encontrado em cada UF e distingue lacuna de cobertura de valor zero.
- Adicionada `Auditoria > Identidade nacional`, com matriz, filiais e CNPJs originais rastreaveis.
- Adicionada documentacao interna da regra nacional, exemplo real e limites.

### Regras Aplicadas

- Matriz e filiais sao reunidas pela raiz de oito digitos; a ordem `0001` e canonica.
- As 681 transacoes de SC sem municipio entram no total financeiro sinalizado e nao formam pares, mapas ou movimentos.
- Movimentos so comparam anos consecutivos efetivamente cobertos pela mesma UF.
- Base 1, MUNIC, SICONFI, classificacao v0.5 e modelos espaciais permanecem MG.

### Validacao

- 40.486 linhas anuais, 7.560 pares consolidados e nenhuma chave duplicada.
- Os 1.194 CNPJs resultam em 1.159 entidades; 23 raizes incorporam 35 filiais.
- Testes antigos de classificacao, mapas, exportacao, documentacao e trajetoria permaneceram aprovados.
- Testes nacionais, filtros MG/CIMVA, todas as paginas, desktop e viewport movel foram verificados sem erros Shiny.
- A legenda do mapa nacional foi convertida em cinco classes para evitar sobreposicao.
- A versao foi publicada no shinyapps.io e as seis paginas principais, a visao Brasil, a auditoria nacional e a documentacao foram novamente verificadas na URL publica.
