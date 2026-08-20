# Metodologia - Identidade CNPJ E MIDES Nacional

**Versao:** 0.1
**Data:** 20/08/2026
**Situacao:** primeira camada nacional materializada e validada; ainda nao
integrada ao dashboard.

## Objetivo

Consolidar matriz e filiais como uma unica entidade analitica e ampliar o
processamento MIDES para todas as UFs que possuem pagamentos correspondentes aos
CNPJs do cadastro IPEA.

## Unidade De Identidade

O cadastro original possui uma linha por estabelecimento CNPJ. A nova entidade
analitica usa a raiz de oito digitos:

```text
CNPJ original
-> primeiros 8 digitos: raiz da entidade
-> ordem 0001: estabelecimento matriz
-> demais ordens: filiais
-> CNPJ canonico: CNPJ da matriz
```

O CNPJ original permanece em todas as tabelas de correspondencia. A
consolidacao nao altera nem apaga o cadastro de origem.

## Validacao Cadastral

| Indicador | Resultado |
|---|---:|
| CNPJs originais | 1.194 |
| Entidades consolidadas | 1.159 |
| Raizes com matriz e filial | 23 |
| Filiais incorporadas | 35 |
| Raizes sem matriz | 0 |
| Raizes com mais de uma matriz | 0 |
| Raizes com estabelecimentos em UFs diferentes | 0 |

Todos os grupos possuem exatamente uma matriz `0001`. O nome, a situacao e os
demais atributos originais continuam disponiveis no crosswalk.

## MIDES Nacional

A fonte e `basedosdados.world_wb_mides.pagamento`. A consulta seleciona todos os
registros cujo `documento_credor` pertence aos 1.194 CNPJs do cadastro IPEA. A
`sigla_uf` da tabela representa a UF do municipio pagador, nao a sede do
consorcio.

A cobertura encontrada em 20/08/2026 foi:

| UF pagadora | Periodo | Transacoes | CNPJs | Municipios identificados |
|---|---:|---:|---:|---:|
| CE | 2009-2022 | 27.602 | 43 | 168 |
| DF | 2014-2022 | 104 | 2 | 1 |
| MG | 2014-2021 | 469.596 | 161 | 853 |
| PB | 2003-2020 | 21.589 | 24 | 169 |
| PR | 2013-2022 | 522.535 | 89 | 399 |
| RS | 2001-2021 | 117.590 | 27 | 291 |
| SC | 2021-2024 | 36.486 | 67 | 273 |
| SP | 2008-2021 | 105.360 | 118 | 560 |

O cadastro permanece nacional, com 27 UFs. O MIDES localizado cobre oito UFs;
ausencia nas demais UFs nao deve ser interpretada como ausencia de consorcio.

## Agregacao Financeira

Primeiro e criada uma linha por:

```text
UF pagadora x municipio x CNPJ original x ano
```

Depois os estabelecimentos da mesma raiz sao somados em:

```text
UF pagadora x municipio x raiz CNPJ x ano
```

As colunas `cnpjs_originais_observados` e
`n_cnpjs_originais_observados` preservam a composicao da soma.

## Corrente, Restos E Indicador Ausente

- `valor_corrente`: `indicador_restos_pagar == FALSE`;
- `valor_restos`: `indicador_restos_pagar == TRUE`;
- `valor_indicador_restos_ausente`: registros sem esse indicador;
- `valor_total`: soma integral de `valor_final`.

Somente MG e DF possuem o indicador preenchido na extracao encontrada. Nas
outras seis UFs, o valor total e preservado, mas nao e dividido artificialmente
entre corrente e restos.

## Registros Sem Municipio

Foram encontradas 681 transacoes de SC sem `id_municipio`, totalizando
R$ 11.145.961,39. Elas permanecem em
`mides_nacional_registros_sem_chave_municipal.rds`, mas nao entram no painel
municipal porque nao existe chave territorial auditavel.

## Resultados Da Consolidacao MIDES

| Indicador | CNPJ original | Raiz consolidada |
|---|---:|---:|
| Entidades observadas | 512 | 505 |
| Pares municipio-consorcio | 7.587 | 7.560 |
| Linhas anuais | 40.535 | 40.486 |
| Valor municipal analisavel | R$ 15.168.694.503,38 | R$ 15.168.694.503,38 |

Seis raizes apresentam mais de um estabelecimento no MIDES. Em 49 chaves
municipio-ano, dois ou mais estabelecimentos da mesma raiz apareciam
simultaneamente e foram somados.

## Limites

1. Os periodos diferem entre UFs; comparacoes nacionais exigem janela comum ou
   controles explicitos de cobertura.
2. O MIDES registra pagamentos, nao adesao juridica.
3. Registros sem municipio nao podem integrar analises municipais.
4. A decomposicao corrente/restos nao esta disponivel em seis das oito UFs.
5. A classificacao tematica v0.5 continua sendo uma camada validada para MG;
   ainda nao foi expandida nacionalmente.
6. Movimentos, mapas e modelos nacionais nao foram recalculados nesta etapa.

## Validacoes Automatizadas

- correspondencia integral dos 1.194 CNPJs;
- exatamente uma matriz por raiz;
- ausencia de chaves duplicadas nos paineis;
- conservacao de valor e numero de transacoes;
- decomposicao `corrente + restos + indicador ausente = total`;
- reproducao exata das 15.135 linhas e valores do painel MG anterior;
- separacao explicita dos 681 registros sem chave municipal.
