# Classificacao De Areas De Politica Publica - Estado Atual

**Versao em uso:** v0.5, 2026-07-28  
**Unidade:** CNPJ de consorcio no universo MG do cadastro IPEA.  
**Finalidade:** apoiar analises futuras de entradas, saidas e permanencia no MIDES completo.

## O Que Esta Sendo Classificado

Classificamos duas dimensoes diferentes:

1. **Area de politica publica:** o que o consorcio declara ou evidencia fazer, por exemplo `saude`, `saneamento_basico` ou `desenvolvimento_regional`.
2. **Perfil institucional:** como o consorcio se apresenta, por exemplo `setorial`, `multissetorial` ou `multifinalitario`.

Perfil nao substitui area. Um consorcio multifinalitario pode ter uma area explicita, varias areas ou nenhuma area especifica comprovada.

No dashboard, as tres dimensoes sao mantidas separadas:

| Campo | Pergunta respondida | Exemplo |
|---|---|---|
| Area detalhada | Em qual politica publica ha evidencia de atuacao? | `saude`, `saneamento_basico`, `agricultura` |
| Macrogrupo | Em qual familia ampla se encaixa a area? | `saude`, `ambiente_saneamento`, `desenvolvimento_territorial` |
| Perfil institucional | Como a entidade se organiza ou se apresenta? | `setorial`, `multiarea`, `multifinalitario`, `multissetorial` |

Os filtros de area e macrogrupo operam por componente. Assim, um CNPJ classificado em `meio_ambiente; residuos_solidos` pode ser localizado por qualquer uma das duas areas, sem que a combinacao inteira vire uma opcao de filtro.

## Pipeline Resumido

```text
Cadastro IPEA + MUNIC 2015/2019 + nome juridico/aliases MIDES
                 |
                 v
Padronizacao em areas detalhadas e macrogrupos
                 |
                 v
Auditoria: nao unir automaticamente setores MUNIC heterogeneos
                 |
                 v
Revisao documental e decisoes humanas versionadas
                 |
                 v
Camada analitica ativa v0.5
```

## Fontes E Tipo De Classificacao

| Caminho | Quando e usado | Como interpretar |
|---|---|---|
| Cadastro IPEA | O cadastro ja traz setor/tipo de arquivo sem conflito | Classificacao herdada do cadastro, com fonte preservada |
| MUNIC auditada | Setor unico, convergencia ou combinacao coerente | Evidencia declaratoria por municipio-consorcio; nao e uniao cega de todos os setores |
| Revisao documental | Estatuto, protocolo ou pagina institucional | Evidencia mais forte e rastreavel |
| Nome juridico / aliases MIDES | Nao ha evidencia direta suficiente, mas o texto explicita a area | Inferencia textual rastreavel; nao equivale a documento institucional |
| Matriz-filial | CNPJ filial identificado pela mesma raiz de 8 digitos | Filial herda apenas area e perfil da matriz; valores e pares continuam separados |

## Taxonomia

| Area detalhada | Macrogrupo | Escopo resumido |
|---|---|---|
| `saude`, `urgencia_emergencia`, `vigilancia_em_saude` | `saude` | Redes, atendimento, urgencia e vigilancia em saude |
| `saneamento_basico`, `residuos_solidos`, `meio_ambiente`, `recursos_hidricos` | `ambiente_saneamento` | Saneamento, residuos, ambiente e agua |
| `desenvolvimento_regional`, `desenvolvimento_urbano`, `transporte`, `infraestrutura`, `habitacao` | `desenvolvimento_territorial` | Cooperacao territorial ampla, planejamento e estruturacao regional |
| `assistencia_social`, `educacao`, `esporte` | `politicas_sociais` | Politicas sociais finalisticas |
| `agricultura`, `inspecao_produtos_origem_animal` | `desenvolvimento_rural` | Atividade rural e inspecao de produtos de origem animal |
| `iluminacao_publica`, `licitacao_compras_compartilhadas`, `gestao_publica` | `gestao_publica` | Funcoes administrativas e servicos compartilhados |

### Desenvolvimento Regional

`desenvolvimento_regional` e uma area territorial ampla. Em geral abrange cooperacao entre municipios, planejamento, estruturacao regional, apoio institucional e desenvolvimento municipal. Ela **nao prova**, por si so, que o consorcio atue em uma politica setorial unica como saude ou saneamento.

## Tratamento Dos Multifinalitarios

Os 23 casos foram classificados pelo nome juridico, usando aliases MIDES apenas quando o nome juridico nao trazia o termo.

- 19 receberam perfil `multifinalitario`;
- 4 receberam perfil `multissetorial`;
- 7 receberam tambem area `saude`, pois nome ou alias MIDES declara explicitamente saude;
- 16 ficaram sem area especifica: o perfil esta validado, mas nenhuma politica setorial foi inventada.

## Matriz E Filial

Foram identificadas duas filiais que aguardavam classificacao tematica. Ambas passaram a herdar area e perfil da matriz:

| Filial | Matriz | Classificacao herdada |
|---|---|---|
| Centro-CIS | CIS Caparao | `saude`; perfil `multissetorial` |
| ICISMEP LOG | CISMEP | `saude`; perfil `setorial` |

Essa regra e somente classificatoria. **Nao** soma pagamentos MIDES, nao altera SICONFI e nao muda a unidade de movimentos.

## Situacao v0.5

| Situacao | CNPJs |
|---|---:|
| Universo tecnico | 223 |
| Excluidos somente da camada analitica por inatividade/baixa | 6 |
| Camada analitica ativa | 217 |
| Confirmados por revisao/documentacao | 34 |
| Validados pelo usuario: coerentes | 94 |
| Validados pelo usuario: cadastro IPEA ou nome | 63 |
| Nome/alias com area explicita | 7 |
| Perfil validado sem area especifica | 16 |
| Filial com tipo herdado da matriz | 2 |
| Fora do escopo | 1 |

## Limites Mantidos

- A classificacao nao altera as bases brutas MIDES, MUNIC, SICONFI ou cadastro IPEA.
- Validacao para uso analitico nao substitui a documentacao institucional de cada consorcio.
- A regra de consolidacao financeira de matriz/filial continua pendente de decisao metodologica.
- Os 16 multifinalitarios/multissetoriais sem area devem permanecer sem area ate surgir evidencia setorial suficiente.
- No MIDES completo, registros fora do universo MG da classificacao, inativos/baixados ou com perfil sem area continuam preservados nos totais. Eles sao apresentados separadamente na cobertura da classificacao, e nao como uma categoria de area.

## Arquivos Relacionados

- `analises/classificacao_politicas/07_consolidar_classificacao_v0_5.R`
- `analises/classificacao_politicas/outputs/classificacao_areas_politica_mg_v0_5_analitica_ativa.csv`
- `analises/classificacao_politicas/METODOLOGIA_CLASSIFICACAO_V0_4.md` (trilha anterior)
- `analises/classificacao_politicas/AUDITORIA_CONSOLIDACAO_MUNIC.md`
