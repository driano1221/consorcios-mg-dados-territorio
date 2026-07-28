# Auditoria da Consolidacao de Setores MUNIC

**Data:** 2026-07-22  
**Unidade:** CNPJ de consorcio no recorte MG do cadastro IPEA.  
**Fonte MUNIC:** Base 1, anos 2015 e 2019; cada observacao e um par municipio-consorcio com setor(es) declarado(s).

## Objetivo

Verificar se e metodologicamente adequado unir todos os setores MUNIC observados para um CNPJ. Esta auditoria nao altera a classificacao de areas; ela gera uma recomendacao rastreavel para uma proxima versao.

## Regra recomendada

1. **Setor unico:** usar MUNIC como evidencia setorial.
2. **Multiplos setores na mesma macroarea:** usar MUNIC como evidencia multiarea, preservando os setores e a distribuicao de suporte.
3. **Multiplas macroareas:** nao unir automaticamente, exceto quando o cadastro IPEA cobrir todas as areas MUNIC; revisar antes de transformar a uniao em classificacao final.

## Resultados

- CNPJs com registro MUNIC: 149.
- Casos para nao unir automaticamente: 58.
- Casos de prioridade alta: 4.

Os arquivos CSV e XLSX registram, por CNPJ, os setores, anos, municipios de exemplo, suporte de cada setor, comparacao 2015/2019, relacao com o cadastro IPEA e recomendacao.

## Limite

MUNIC informa o setor declarado no vinculo municipio-consorcio. A coexistencia de setores em um CNPJ pode refletir atividade real multissetorial ou heterogeneidade de declaracao; esta auditoria identifica essa distincao como questao de revisao, mas nao presume erro.

## Decisao Metodologica Aprovada (2026-07-23)

A regra recomendada foi aprovada para uso na classificacao analitica:

- setor MUNIC e evidencia sobre o vinculo municipio-consorcio, nao prova isoladamente todo o escopo institucional do CNPJ;
- combinacoes heterogeneas entre macroareas nao ampliam automaticamente `area_politica_final`;
- a excecao de convergencia entre MUNIC e Cadastro IPEA foi aprovada: quando o Cadastro IPEA cobre integralmente as areas observadas na MUNIC, as areas podem ser mantidas;
- a validacao humana da regra usa a amostra reprodutivel de 19 CNPJs em `outputs/amostra_validacao_regra_MUNIC_v0_1.xlsx`.

Essa decisao encerra a definicao da regra. A pesquisa documental de consorcios multifinalitarios, pendentes e filiais e uma etapa posterior de classificacao, nao uma pendencia da consolidacao MUNIC.
