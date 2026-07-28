# Dashboard Base 1 2015/2019

Dashboard Shiny para consulta interativa da Base 1.

## Conteudo

- filtros multisselecao por ano, grupo de vinculo, classe SICONFI, municipio, consorcio e busca livre;
- filtros MIDES completo por area detalhada, macrogrupo e perfil institucional da classificacao v0.5;
- KPIs compactos no topo;
- tabela pesquisavel/exportavel da base final;
- tabela agregada de validacao SICONFI por municipio-ano;
- secao `Documentacao` com guia do painel, conceitos e classificacao de areas;
- valores MIDES e SICONFI reconstruido no mesmo painel.

## Dados usados

- `data/base_1_vinculos_2015_2019.csv`
- `data/base_1_validacao_siconfi_reconstruido_2015_2019.csv`
- `data/classificacao_areas_politica_mg_v0_5.rds`

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
+-- start_app.R
+-- README.md
+-- data/
|   +-- base_1_vinculos_2015_2019.csv
|   +-- base_1_validacao_siconfi_reconstruido_2015_2019.csv
+-- www/
    +-- IPEA-LOGO.png
```

## Leitura metodologica

MIDES e MUNIC formam a base de vinculos em `municipio x consorcio x ano`.

SICONFI entra como validacao financeira agregada em `municipio x ano`, usando a regra `consorcio_pagas`.

No MIDES completo, a classificacao v0.5 e anexada por CNPJ somente como atributo analitico. Ela nao altera valores, pares ou movimentos. CNPJs sem classificacao ativa permanecem acessiveis pelo filtro `Sem classificacao ativa`.

## Documentacao No App

A aba `Documentacao` fica separada das telas analiticas e contem:

- `Guia do painel`: escopo e leitura de cada tela;
- `Conceitos`: pares, fontes, classes SICONFI e regra de leitura;
- `Classificacao de areas`: pipeline v0.5, taxonomia, inferencias, multifinalitarios e regra classificatoria de matriz/filial.

A referencia completa fora do app e `../../docs/METODOLOGIA_CLASSIFICACAO_ATUAL.md`.
