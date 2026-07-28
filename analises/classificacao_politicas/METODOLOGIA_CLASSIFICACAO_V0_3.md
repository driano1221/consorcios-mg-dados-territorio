# Classificacao De Politicas Publicas v0.3

**Unidade:** CNPJ no recorte MG do cadastro IPEA.  
**Cobertura:** 223 CNPJs.  
**Objetivo:** disponibilizar uma classificacao curta para analise, sem transformar toda declaracao MUNIC em area substantiva do consorcio.

## Os Tres Campos Para Analise

| Campo | Pergunta que responde |
|---|---|
| `area_politica_final` | Em qual area ou areas ha evidencia para classificar o consorcio? |
| `fonte_principal` | Qual evidencia definiu o resultado? |
| `status_validacao` | O resultado esta confirmado, provisório ou pendente? |

`macroarea_final` e `perfil_institucional` sao campos auxiliares: o primeiro agrupa areas para tabulacao; o segundo descreve se o consorcio e setorial, multiarea ou multifinalitario. Eles nao substituem `area_politica_final`.

## Fontes E O Que Cada Uma Significa

| Fonte | Uso na v0.3 |
|---|---|
| Documentacao institucional | Maior precedencia: estatuto, protocolo, portal institucional, contrato de rateio ou pagina oficial. |
| Cadastro IPEA, `tipo_fonte = arquivo` | Classificacao legada explicitamente registrada no cadastro. E usada de modo provisório quando nao conflita com o nome juridico. |
| Cadastro IPEA, `tipo_fonte = regex` | Inferencia a partir do nome. Nao e uma segunda evidencia independente. |
| MUNIC 2015/2019 | Setor declarado no par municipio-consorcio. So entra automaticamente quando e consistente; a uniao bruta e preservada apenas para auditoria. |
| Nome juridico/MIDES | Evidencia textual. Quando coincide com MUNIC, sustenta classificacao provisoria coerente; isoladamente, permanece provisoria. |

## Regra De Precedencia

```text
decisao documental v0.3
        ↓
revisao documental confirmada/ajustada v0.2
        ↓
nome juridico + MUNIC coerentes
        ↓
MUNIC segura (setor unico ou mesma macroarea)
        ↓
cadastro IPEA arquivo sem conflito textual
        ↓
nome juridico isolado (provisorio)
        ↓
pendente de documento
```

Para consorcio explicitamente multifinalitario, a v0.3 nao infere uma lista completa de areas apenas da uniao MUNIC. O perfil fica como `multifinalitario` e a classificacao setorial detalhada exige documento ou decisao posterior.

## Regra MUNIC

1. **Um setor no CNPJ:** pode ser evidencia setorial.
2. **Varios setores na mesma macroarea:** pode ser evidencia multiarea, mantendo os setores observados.
3. **Setores em macroareas distintas:** nao sao unidos automaticamente. O nome juridico ou a documentacao pode definir a area principal; os demais setores permanecem na auditoria.

Exemplo: CIS/AMAPI tinha `saude; residuos_solidos` na uniao bruta. A auditoria mostrou saude em todos os 39 pares municipio-ano e residuos em apenas 2 pares de 2015. O estatuto confirma saude; portanto, a v0.3 registra `area_politica_final = saude` e conserva o registro de residuos na auditoria, sem apaga-lo.

## Resultado Atual

| Status | CNPJs | Leitura |
|---|---:|---|
| `confirmada` | 34 | Documentacao institucional ou revisao documental. |
| `provisoria_coerente` | 94 | Fontes textuais/MUNIC coerentes ou MUNIC auditada sem heterogeneidade problematica. |
| `provisoria_cadastro` | 15 | Cadastro IPEA arquivo sem conflito textual detectado. |
| `provisoria_nome` | 48 | Nome juridico indicativo, sem segunda fonte suficiente. |
| `provisoria_multifinalitario` | 23 | Perfil multifinalitario identificado, sem inferencia automatica das areas. |
| `pendente_documento` | 6 | Sem evidencia finalistica suficiente. |
| `aguardar_matriz_filial` | 2 | Filial: depende da decisao de consolidacao por raiz de CNPJ. |
| `fora_escopo` | 1 | Associacao municipal, nao consorcio tematico. |

## Arquivos

| Arquivo | Uso |
|---|---|
| `03_consolidar_classificacao_v0_3.R` | Rotina reprocessavel da versao analitica. |
| `inputs/decisoes_documentais_v0_3.csv` | Oito decisoes documentais adicionadas na v0.3. |
| `outputs/classificacao_areas_politica_mg_v0_3_analitica.csv` | Arquivo curto para analise e futura integracao ao dashboard. |
| `outputs/classificacao_areas_politica_mg_v0_3_analitica.xlsx` | Versao para leitura humana, com CNPJ preservado como texto. |
| `outputs/classificacao_areas_politica_mg_v0_3_tecnica.csv` | Trilha completa: v0.2, auditoria MUNIC e regra aplicada. |
| `outputs/revisao_pendente_classificacao_mg_v0_3.xlsx` | Pendencias e multifinalitarios que ainda exigem decisao ou documento. |

## Limite

A v0.3 classifica areas com base nas evidencias disponiveis; ela nao afirma que um consorcio exerce exclusivamente essas areas nem substitui a futura consolidacao de matriz e filiais.
