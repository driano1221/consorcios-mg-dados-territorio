# Classificacao De Areas De Politica Publica

## Objetivo

Criar uma classificacao auditavel dos consorcios de Minas Gerais por area de politica publica para apoiar a analise de entradas, saidas e permanencias no MIDES completo.

A unidade da classificacao e o **CNPJ de consorcio**. A rotina nao altera a base MIDES, a Base 1 ou os setores brutos das fontes.

## Fontes De Evidencia

| Fonte | Campo usado | Papel |
|---|---|---|
| Cadastro IPEA | `setores` | setor registrado no cadastro mestre |
| Cadastro IPEA | `tipo`, quando `tipo_fonte = arquivo` | classificacao previa proveniente de arquivo |
| MUNIC 2015/2019 | `setores_munic` | areas declaradas nos vinculos municipio-consorcio |
| Razao social e MIDES | `razao_social`, `nome_credor_freq` | fallback por regras textuais explicitas |

O campo `tipo` quando gerado por `regex` nao e tratado como evidencia direta. As regras desta pasta sao independentes e auditaveis.

## Logica

1. Traduzir os codigos de setor de Cadastro e MUNIC para areas detalhadas padronizadas.
2. Consolidar Cadastro e MUNIC como evidencias diretas, preservando a origem de cada uma.
3. Usar o nome juridico e o nome recorrente no MIDES apenas quando nao houver evidencia direta.
4. Mapear areas detalhadas em macroareas.
5. Marcar conflitos, ausencia de area e multifinalitarios sem area especifica para revisao humana.
6. Aplicar, quando existir, uma camada de revisao documental por CNPJ, sem alterar os campos automaticos.

## Multifinalitario

`multifinalitario` e um **perfil institucional**, identificado pelos termos `MULTIFINALITARIO` ou `MULTISSETORIAL` no nome. Ele nao substitui as areas especificas encontradas.

Exemplos:

- consorcio multifinalitario com areas de saneamento e meio ambiente: perfil `multifinalitario_explicito`, areas detalhadas `meio_ambiente; saneamento_basico`;
- consorcio multifinalitario sem setor declarado: perfil `multifinalitario_explicito`, classe analitica `multifinalitario` e revisao obrigatoria.

## Taxonomia Inicial

| Area detalhada | Macroarea |
|---|---|
| `saude`, `urgencia_emergencia` | `saude` |
| `saneamento_basico`, `residuos_solidos`, `meio_ambiente`, `recursos_hidricos` | `ambiente_saneamento` |
| `desenvolvimento_urbano`, `desenvolvimento_regional`, `transporte`, `infraestrutura`, `habitacao` | `desenvolvimento_territorial` |
| `assistencia_social`, `educacao`, `esporte` | `politicas_sociais` |
| `cultura`, `turismo` | `cultura_turismo` |
| `agricultura` | `desenvolvimento_rural` |
| `inspecao_produtos_origem_animal` | `desenvolvimento_rural` |
| `iluminacao_publica`, `licitacao_compras_compartilhadas`, `gestao_publica` | `gestao_publica` |
| `vigilancia_em_saude` | `saude` |
| `seguranca_publica` | `seguranca_cidadania` |

## Campos Principais Do Output

| Campo | Significado |
|---|---|
| `areas_politica_detalhadas` | uma ou mais areas identificadas, sem forcar area unica |
| `macroareas_politica` | macroareas correspondentes |
| `perfil_institucional` | `setorial`, `multiarea_documentada`, `multifinalitario_explicito` ou `sem_classificacao` |
| `classe_analitica_proposta` | classe resumida para analise, mantendo `multifinalitario` proprio |
| `origem_classificacao` | fonte efetivamente usada na classificacao proposta |
| `fontes_evidencia_disponiveis` | todas as fontes que trazem algum sinal, inclusive as divergentes |
| `regra_classificacao` | regra aplicada |
| `confianca_classificacao` | `alta`, `media`, `baixa`, `revisar` ou `sem_classificacao` |
| `necessita_revisao` | indica caso que nao deve ser tratado como classificacao definitiva |
| `motivo_revisao` | motivo objetivo da revisao |
| `areas_politica_final` | classificacao apos a revisao documental; preserva o valor automatico quando nao ha ajuste |
| `origem_classificacao_final` | informa se a classificacao final veio da revisao documental ou da rotina automatica |

## Auditoria da consolidacao MUNIC

A classificacao v0.2 preserva a uniao historica dos setores MUNIC por CNPJ. Essa uniao nao deve ser interpretada automaticamente como area substantiva do consorcio: MUNIC registra o setor declarado em cada par municipio-consorcio e pode haver heterogeneidade entre municipios ou anos.

O script `02_auditar_consolidacao_munic.R` cria uma camada independente de auditoria, sem alterar a v0.2:

1. setor unico no CNPJ: MUNIC pode ser usado como evidencia setorial;
2. varios setores dentro da mesma macroarea: MUNIC pode ser usado como evidencia multiarea, mantendo o suporte de cada setor;
3. setores em macroareas distintas: nao unir automaticamente, exceto quando o cadastro IPEA cobre todas as areas observadas na MUNIC.

Os resultados mostram, para cada CNPJ, os setores por ano, numero de municipios, suporte de cada setor, comparacao 2015/2019, apoio do cadastro IPEA e recomendacao metodologica. O relatorio e `AUDITORIA_CONSOLIDACAO_MUNIC.md`.

## Camada Analitica v0.3

A `v0.3` nao substitui a `v0.2`; ela fornece um arquivo curto para analise com tres campos principais: `area_politica_final`, `fonte_principal` e `status_validacao`. A nova rotina aplica a auditoria MUNIC e nao permite que uma uniao heterogenea de setores defina automaticamente a area final.

Ler `METODOLOGIA_CLASSIFICACAO_V0_3.md` antes de usar os outputs v0.3. Em especial, `tipo_fonte = regex` no cadastro IPEA nao conta como fonte independente: e inferencia textual a partir do nome.
| `revisao_documental_status` | `confirmado`, `ajustado`, `evidencia_insuficiente` ou `nao_revisado` |
| `necessita_revisao_final` | pendencia remanescente depois da revisao documental |

## Execucao

Na raiz do projeto:

```r
source("analises/classificacao_politicas/01_classificar_areas_politica.R")
```

## Revisao Documental V0.2

O arquivo `inputs/revisao_documental_39_cnpjs_v0_2.csv` registra a primeira rodada de verificacao individual dos 39 CNPJs sinalizados na versao automatica. Cada registro traz decisao, justificativa, confianca e URLs das evidencias consultadas.

Resultado da rodada:

- 19 CNPJs confirmados;
- 10 CNPJs ajustados;
- 10 permanecem como `evidencia_insuficiente` e continuam em revisao;
- a regra de matriz/filial **nao** foi aplicada nesta etapa.

`multifinalitario` continua sendo perfil institucional. Uma compra isolada nao basta para atribuir, por exemplo, educacao, esporte ou saude como area finalistica do consorcio.

## Outputs

- `outputs/classificacao_areas_politica_mg_v0_2.csv`
- `outputs/classificacao_areas_politica_mg_v0_2.rds`
- `outputs/revisao_classificacao_areas_politica_mg_v0_2.xlsx`
- `outputs/resumo_classificacao_areas_politica_mg_v0_2.csv`
- `outputs/auditoria_consolidacao_setores_munic_v0_1.csv`
- `outputs/auditoria_consolidacao_setores_munic_detalhe_v0_1.csv`
- `outputs/resumo_auditoria_consolidacao_setores_munic_v0_1.csv`
- `outputs/auditoria_consolidacao_setores_munic_v0_1.xlsx`
- `outputs/caderno_decisao_v0_3/caderno_decisao_classificacao_v0_3.xlsx`: caderno consultavel dos 188 casos nao confirmados, separados por tipo de evidencia e com campos de parecer.
- `outputs/classificacao_areas_politica_mg_v0_3_analitica.csv`
- `outputs/classificacao_areas_politica_mg_v0_3_analitica.xlsx`
- `outputs/classificacao_areas_politica_mg_v0_3_tecnica.csv`
- `outputs/revisao_pendente_classificacao_mg_v0_3.xlsx`
- `outputs/classificacao_areas_politica_mg_v0_4_analitica_ativa.csv/.rds`: camada analitica ativa apos as decisoes de 28/07; 217 CNPJs.
- `outputs/classificacao_areas_politica_mg_v0_4_completa.csv`: universo tecnico completo, incluindo seis inativos excluidos apenas da camada ativa.
- `METODOLOGIA_CLASSIFICACAO_V0_4.md` e `06_consolidar_classificacao_v0_4.R`: decisoes humanas incorporadas de forma reprocessavel.
