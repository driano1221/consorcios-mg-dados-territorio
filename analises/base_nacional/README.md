# Base Nacional Consolidada

Esta frente amplia o cadastro IPEA para todas as UFs e aplica a decisao de
consolidar matriz e filiais pela raiz de oito digitos do CNPJ.

## Principios

- o CNPJ original nunca e apagado;
- a entidade analitica e a raiz de oito digitos;
- o CNPJ canonico e o estabelecimento matriz, identificado pela ordem `0001`;
- valores de estabelecimentos da mesma raiz sao somados apenas depois de manter
  uma trilha explicita `cnpj_original -> cnpj_canonico`;
- ausencia de MIDES em uma UF sem cobertura nao representa ausencia de consorcio.

## Ordem de execucao

```r
source("analises/base_nacional/scripts/01_consolidar_identidade_cnpj.R")
source("analises/base_nacional/tests/01_validar_identidade_cnpj.R")
source("analises/base_nacional/scripts/02_baixar_mides_nacional.R")
source("analises/base_nacional/scripts/03_processar_mides_nacional.R")
source("analises/base_nacional/tests/02_validar_mides_nacional.R")
source("analises/base_nacional/scripts/04_eda_validacao_mides_nacional.R")
source("analises/base_nacional/scripts/05_preparar_dashboard_nacional.R")
```

Os outputs pesados ficam em `analises/base_nacional/outputs/` e permanecem fora
do Git. O script 05 cria artefatos leves para a visao `MIDES completo > Brasil`.
Base 1, MUNIC, SICONFI, comparacao 2015/2019, classificacao v0.5 e modelos
espaciais permanecem no escopo MG e nao sao recalculados por esta frente.

## Cobertura no dashboard

- **universo cadastral:** 1.159 entidades consolidadas a partir de 1.194 CNPJs;
- **universo com MIDES localizado:** 505 raizes;
- **UFs pagadoras encontradas:** CE, DF, MG, PB, PR, RS, SC e SP;
- **unidade municipal:** municipio pagador x raiz CNPJ x ano;
- **movimentos:** somente entre anos consecutivos cobertos na mesma UF;
- **sem municipio:** 681 transacoes de SC entram no total financeiro sinalizado,
  mas nao formam pares, mapas ou movimentos municipais.
