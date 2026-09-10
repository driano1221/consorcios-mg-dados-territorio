# Validacao: Capacidade Assistencial Direta CNES (MG)

- Data da extracao CNES: `2026-09-03`.
- Entidades consolidadas: **84**.
- Unidades CNES vinculadas consultadas: **670**.
- Unidades com todos os modulos consultados: **670**.
- Entidades do nucleo MIDES: **64**.

## Situacao Da Capacidade

| Situacao | Entidades |
|---|---:|
| capacidade_direta_cnes_atual | 61 |
| sem_unidade_cnes_direta_nao_interpretar_como_zero | 21 |
| somente_unidades_moveis_sem_polo_fixo | 2 |

## Cobertura E Medidas

- Estruturas fixas elegiveis: **82**; excluidas da oferta fixa: **588** (586 moveis pelo tipo CNES e 2 com indicio no nome e tipo conflitante/ausente).
- Unidades fixas com atendimento ambulatorial SUS: **67**; com SADT SUS: **38**; com internacao SUS: **1**.
- Unidades fixas com ao menos um CBO medico SUS ativo: **72**.
- Entidades com estrutura fixa direta: **61**; **58** possuem ao menos um CBO medico SUS ativo no retrato CNES.
- Entidades com leitos SUS diretamente registrados: **1** de **61**.

### Estabelecimentos Com Leitos Existentes

| Estabelecimento | CNES | Leitos existentes | Leitos SUS |
|---|---:|---:|---:|
| ACISPES | 3154920 | 5 | 0 |
| HOSPITAL 272 JOIAS ICISMEP | 0979538 | 32 | 32 |
| CISMEP | 3476014 | 6 | 0 |

## Exemplos Auditados

| Entidade | Status | Unidades | Moveis | Fixas | Leitos SUS | Soma de CBOs medicos |
|---|---|---:|---:|---:|---:|---:|
| CIMES | somente_unidades_moveis_sem_polo_fixo | 1 | 1 | NA | NA | NA |
| CIS/CEN | somente_unidades_moveis_sem_polo_fixo | 3 | 3 | NA | NA | NA |
| CISMARPA | capacidade_direta_cnes_atual | 1 | 0 | 1 | 0 | 18 |
| CISMAS | capacidade_direta_cnes_atual | 1 | 0 | 1 | 0 | 10 |
| CISMEP | capacidade_direta_cnes_atual | 15 | 11 | 4 | 32 | 22 |
| CISVER | capacidade_direta_cnes_atual | 5 | 4 | 1 | 0 | 33 |

## Leitura Metodologica

- Leitos SUS aparecem em apenas uma entidade com capacidade direta; nao devem ser a unica massa de atracao.
- CBOs medicos e atendimentos possuem cobertura maior, mas medem cadastro atual, nao producao nem especialidade historica.
- O mesmo CBO pode aparecer em varias unidades da rede; a soma mede escopo registrado por unidade, nao especialidades unicas da entidade.
- CIS/CEN e CIMES nao recebem destino fixo neste snapshot: ha indicios de mobilidade e fichas com tipo ausente/conflitante. A serie historica deve ser lida separadamente.

## Regras De Leitura

- Reprocessamento de 10/09: tipos CNES moveis nao recebem tempo fixo, mesmo quando o nome diz apenas USB/USA. As 307 classificacoes incorretas foram removidas da oferta fixa.
- CIMES 3987981: nome VACIMOVEL e tipo clinica conflitam no snapshot atual. CISCEN 5563003: ficha sem tipo. Ambos permanecem excluidos conservadoramente da oferta fixa atual; isso nao retroage ao CNES historico.
- Estrutura nao movel pode ser central administrativa/regulatoria, farmacia ou telessaude. A elegibilidade cadastral nao autoriza trata-la como destino clinico; o filtro assistencial pertence ao fechamento do passo 3.
- Leitos, vinculos SUS e CBOs sao fotografia atual do CNES, nao serie historica do MIDES.
- Valores iguais a zero so significam ausencia no modulo CNES quando a consulta foi completa; ausencia de unidade sob o CNPJ permanece `NA` no agregado.
- CBO medico distinto e proxy de escopo profissional, nao equivale a servico especializado formal ou producao realizada.
- A soma por entidade considera somente unidades fixas diretamente vinculadas pelo CNPJ; nao inclui hospital municipal, contratado ou proximo sem evidencia documental.
