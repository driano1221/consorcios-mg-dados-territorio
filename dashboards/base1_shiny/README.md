# Painel de Consórcios IPEA

Dashboard Shiny para consulta da Base 1 de Minas Gerais e da camada nacional consolidada do MIDES.

## Conteudo

- filtros multisselecao por ano, grupo de vinculo, classe SICONFI, municipio, consorcio e busca livre;
- filtros MIDES completo por area detalhada, macrogrupo e perfil institucional da classificacao v0.5, com opcoes individuais e rotulos legiveis;
- visoes separadas `Minas Gerais` e `Brasil` no MIDES completo;
- consolidacao nacional de matriz e filiais pela raiz de oito digitos, preservando os CNPJs originais;
- linha do tempo da cobertura encontrada em CE, DF, MG, PB, PR, RS, SC e SP;
- KPIs compactos no topo;
- tabela pesquisavel/exportavel da base final;
- tabela agregada de validacao SICONFI por municipio-ano;
- tabela anual por consorcio com entradas novas, retornos, saidas, permanencias e saldo;
- trajetoria longitudinal 2014-2021 com pequenos multiplos, detalhe sob demanda e matriz municipio-ano;
- auditoria de 23 CNPJs com no maximo dois municipios pagantes em qualquer ano, sem exclusao automatica;
- nomes municipais automaticos somente em recortes com ate 12 municipios destacados;
- exportacao propria dos quatro mapas em PNG de alta resolucao e PDF vetorial;
- secao `Documentacao` com guia do painel, conceitos, classificacao de areas e analise espacial dos movimentos MIDES;
- valores MIDES e SICONFI reconstruido no mesmo painel.

## Dados usados

- `data/base_1_vinculos_2015_2019.csv`
- `data/base_1_validacao_siconfi_reconstruido_2015_2019.csv`
- `data/classificacao_areas_politica_mg_v0_5.rds`
- `data/movimentos_municipio_consorcio_ano.rds`
- `data/mides_nacional_anual_app.rds`
- `data/cadastro_nacional_consolidado_app.rds`
- `data/mides_nacional_movimentos_app.rds`

Esses arquivos foram copiados para dentro da pasta do app para facilitar publicacao.

## Rodar localmente

```r
source("dashboards/base1_shiny/start_app.R")
```

## Publicar no shinyapps.io

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(
  name = "SEU_USUARIO",
  token = "SEU_TOKEN",
  secret = "SEU_SECRET"
)
rsconnect::deployApp("dashboards/base1_shiny")
```

## Estrutura minima para publicar

```text
base1_shiny/
+-- app.R
+-- auditoria_baixa_escala.R
+-- documentacao_movimentos.R
+-- mides_nacional.R
+-- start_app.R
+-- README.md
+-- data/
|   +-- base_1_vinculos_2015_2019.csv
|   +-- base_1_validacao_siconfi_reconstruido_2015_2019.csv
|   +-- movimentos_municipio_consorcio_ano.rds
|   +-- mides_nacional_anual_app.rds
|   +-- cadastro_nacional_consolidado_app.rds
|   +-- mides_nacional_movimentos_app.rds
+-- www/
|   +-- IPEA-LOGO.png
|   +-- pipeline_movimentos_mides.png
|   +-- exposicao_espacial_mides.png
+-- tests/
    +-- test_documentacao_movimentos.R
    +-- test_movimentos_mapas_export.R
    +-- test_trajetoria_longitudinal.R
```

## Leitura metodologica

MIDES e MUNIC formam a base de vinculos em `municipio x consorcio x ano`.

SICONFI entra como validacao financeira agregada em `municipio x ano`, usando a regra `consorcio_pagas`.

No MIDES completo, a classificacao v0.5 e anexada por CNPJ somente como atributo analitico. Ela nao altera valores, pares ou movimentos. Os filtros mostram apenas categorias substantivas. Casos sem area comprovada, inativos/baixados, sediados fora de MG ou fora do escopo continuam preservados nos totais financeiros e sao explicados brevemente em `Documentacao`.

Na visao Brasil, a unidade e `municipio pagador x raiz CNPJ x ano`. Os 1.194 estabelecimentos do cadastro IPEA formam 1.159 entidades; 505 possuem MIDES localizado na extracao atual. Registros sem municipio entram apenas no total financeiro sinalizado e nao criam pares, mapas ou movimentos.

Recorrencia e uma propriedade longitudinal do par municipio-CNPJ: duas ou mais mudancas de presenca no periodo. Por isso, o total aparece na trajetoria 2014-2021 e nao nas tabelas anuais.

## Documentacao No App

A aba `Documentacao` fica separada das telas analiticas e contem:

- `Guia do painel`: escopo e leitura de cada tela;
- `Conceitos`: pares, fontes, classes SICONFI e regra de leitura;
- `Movimentos espaciais`: pergunta de pesquisa, dados, pipeline temporal e espacial, universos de risco, exemplo real, modelos, resultados, sensibilidades, limites e validacoes;
- `Classificacao de areas`: pipeline v0.5, diferenca entre area, macrogrupo e perfil institucional, taxonomia, inferencias, multifinalitarios, matriz/filial e cobertura no MIDES completo.

A referencia completa fora do app e `../../docs/METODOLOGIA_CLASSIFICACAO_ATUAL.md`.

O modulo de movimentos espaciais e validado por:

```powershell
Push-Location dashboards/base1_shiny
Rscript tests/test_documentacao_movimentos.R
Rscript tests/test_movimentos_mapas_export.R
Rscript tests/test_trajetoria_longitudinal.R
Pop-Location
```
