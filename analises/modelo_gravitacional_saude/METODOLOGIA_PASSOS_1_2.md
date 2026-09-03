# Passos 1 E 2 - Preparacao Da Base De Saude

## Objetivo

Preparar e validar o universo de consorcios de saude em Minas Gerais antes de
construir as variaveis gravitacionais e estimar novos modelos.

## Passo 1 - Fechar O Universo De Saude

**Bases usadas**

- classificacao de areas de politica publica v0.5;
- crosswalk nacional de matriz e filiais;
- painel anual MIDES de Minas Gerais, 2014-2021.

**Pipeline**

```text
Classificacao v0.5
  -> selecionar saude, urgencia/emergencia e vigilancia em saude
  -> vincular cada CNPJ ao crosswalk matriz-filial
  -> consolidar estabelecimentos pela raiz de oito digitos
  -> preservar CNPJs originais e definir o CNPJ canonico da matriz
  -> verificar situacao cadastral e pagamentos positivos no MIDES
  -> separar nucleo setorial e sensibilidade multiarea
```

**Resultados**

- 100 estabelecimentos classificados em saude;
- 84 entidades depois da consolidacao;
- 16 filiais incorporadas em 11 raizes;
- 66 entidades com pagamento MIDES observado;
- 64 no nucleo setorial preliminar e duas na sensibilidade multiarea;
- cinco raizes com mais de um CNPJ no MIDES e 21 chaves municipio-ano que
  exigem soma entre estabelecimentos.

## Passo 2 - Cotejar MIDES E MUNIC Em 2019

**Bases usadas**

- Base 1 de vinculos MIDES-MUNIC de 2015 e 2019;
- universo consolidado produzido no passo 1;
- indicadores documentais do cadastro IPEA, usados apenas como contexto.

**Pipeline**

```text
Base 1 em 2019
  -> manter somente os CNPJs do universo de saude
  -> consolidar matriz e filiais por municipio e raiz de CNPJ
  -> marcar pagamento positivo no MIDES e declaracao na MUNIC
  -> classificar: MIDES+MUNIC, somente MIDES ou somente MUNIC
  -> resumir por entidade e selecionar divergencias para revisao
```

**Resultados**

- 1.311 pares municipio-entidade na uniao das fontes;
- 630 pares MIDES+MUNIC, 658 somente MIDES e 23 somente MUNIC;
- 96,5% dos pares MUNIC tambem aparecem no MIDES;
- a MUNIC cobre 48,9% dos pares MIDES;
- R$ 379,1 milhoes no MIDES, com 71,3% em pares presentes nas duas fontes;
- amostra prioritaria de 50 divergencias: os 23 pares somente MUNIC e os 27
  maiores pagamentos somente MIDES.

**Revisao documental da amostra**

As 50 divergencias prioritarias foram pesquisadas em fontes oficiais ou
institucionais e classificadas por cobertura temporal e forca da evidencia.
O resultado preserva uma diferenca essencial: documento posterior a 2019
corrobora a plausibilidade do vinculo, mas nao reconstitui automaticamente a
composicao naquele ano. Pagamento no MIDES tambem nao foi convertido em prova
de filiacao.

## Fontes E Limites

Os produtos principais dos dois passos foram executados com bases locais ja
processadas e auditadas no projeto. A qualificacao da amostra divergente usou
pesquisa documental na internet e preserva em catalogo a URL, o ano e a
interpretacao de cada fonte. MIDES significa pagamento observado, enquanto
MUNIC significa participacao declarada. Divergencia entre as fontes nao e
tratada automaticamente como erro. Documentos sem referencia temporal
compativel nao comprovam a composicao municipal de 2019.

Scripts, testes e relatorios auditaveis estao neste mesmo diretorio. Os
resultados reprocessaveis ficam em `outputs/`, fora do Git por tamanho e por
serem derivados das bases originais.
