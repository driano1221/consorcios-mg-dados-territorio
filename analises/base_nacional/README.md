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
```

Os outputs pesados ficam em `analises/base_nacional/outputs/` e permanecem fora
do Git. O dashboard MG nao e alterado por esta frente.
