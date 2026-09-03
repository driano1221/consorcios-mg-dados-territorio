# Validacao Documental Das Divergencias De 2019

## Escopo

Revisao dos 50 pares prioritarios do cotejamento MIDES x MUNIC: todos os pares somente MUNIC e os 27 maiores valores somente MIDES.

A pesquisa documental nao altera MIDES ou MUNIC. Ela qualifica a divergencia e separa filiacao formal, evidencia financeira e confirmacao fora do ano de referencia.

## Resultado

| Resultado documental | Cobertura temporal | Grau | Pares |
|---|---|---|---:|
| `corroborado_em_fonte_posterior` | `posterior_a_2019` | `moderado` | 33 |
| `evidencia_direta_ate_2019` | `anterior_ou_igual_a_2019` | `forte` | 14 |
| `historicamente_compativel` | `compativel_com_2019` | `moderado` |  1 |
| `nao_corroborado_com_indicio_alternativo` | `posterior_a_2019` | `fraco` |  1 |
| `relacao_financeira_sem_filiacao_comprovada` | `posterior_a_2019` | `forte` |  1 |

## Leitura Por Divergencia

| Fonte de divergencia | Resultado documental | Pares |
|---|---|---:|
| `somente_MIDES` | `corroborado_em_fonte_posterior` | 21 |
| `somente_MIDES` | `evidencia_direta_ate_2019` |  5 |
| `somente_MIDES` | `relacao_financeira_sem_filiacao_comprovada` |  1 |
| `somente_MUNIC` | `corroborado_em_fonte_posterior` | 12 |
| `somente_MUNIC` | `evidencia_direta_ate_2019` |  9 |
| `somente_MUNIC` | `historicamente_compativel` |  1 |
| `somente_MUNIC` | `nao_corroborado_com_indicio_alternativo` |  1 |

## Casos Criticos

- `Juiz de Fora x ACISPES`: pagamento MIDES e prestacao de servico nao comprovam filiacao municipal; a fonte institucional distingue consorciados de cidades apenas atendidas.
- `Sao Miguel do Anta x SIMSAUDE`: nao houve corroboracao documental; uma fonte municipal posterior registra parceria com outro consorcio, exigindo revisao humana.
- `Itabira x CIAS`: a MUNIC sem MIDES em 2019 e compativel com fonte oficial de 2016; a ausencia na lista atual sugere mudanca temporal e nao erro automatico.

## Decisao Metodologica

- Evidencia anterior ou igual a 2019 pode sustentar o vinculo historico, mas ainda nao garante contribuicao anual.
- Fonte posterior apenas corrobora plausibilidade institucional; esses pares permanecem em sensibilidade.
- Pagamento MIDES continua sendo evidencia financeira, nunca sinonimo automatico de adesao juridica.
- Ausencia documental nesta busca nao prova inexistencia do vinculo.

Catalogo versionado: `evidencias/catalogo_revisao_documental_2019.csv`.
Resultado detalhado local: `outputs/revisao_documental_divergencias_saude_mg_2019.csv`.
