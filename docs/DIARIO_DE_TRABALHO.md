# Diario De Trabalho - ideiaMides

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
- Repositorio remoto privado criado em <https://github.com/driano1221/ideiaMides>.
- Regra operacional definida: ao concluir uma sessao relevante, atualizar este diario, criar commit e enviar para `origin`.
