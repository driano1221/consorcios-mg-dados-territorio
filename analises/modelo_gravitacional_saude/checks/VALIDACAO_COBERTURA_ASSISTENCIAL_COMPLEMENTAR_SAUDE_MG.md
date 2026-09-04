# Validacao: Cobertura Assistencial Complementar (MG)

- Data: `2026-09-03`.
- Entidades no universo: **84**.
- Casos originalmente pendentes: **38** (36 sem unidade direta e 2 somente moveis).
- Entidades recuperadas pela consulta de CNPJ proprio: **15**.
- Entidades com ao menos uma estrutura fixa CNES direta apos a correcao: **61** (antes: 46).
- Alertas de universo com decisao registrada: **7 de 7**.

## Resultado Por Classificacao

| classificacao | entidades |
|---|---:|
| unidade_fixa_cnes_direta | 38 |
| rede_fixa_cnes_direta | 23 |
| fora_universo_modelavel_atual | 15 |
| entidade_historica_inativa_sem_polo_atual | 2 |
| ativa_sem_mides_e_sem_evidencia_assistencial | 1 |
| oferta_assistencial_documentada_sem_prestador_unico | 1 |
| rede_movel_regional_samu_sem_polo_hospitalar_unico | 1 |
| rede_urgencia_historicamente_planejada_sem_polo_atual_confirmado | 1 |
| servico_movel_e_rede_credenciada_sem_polo_unico | 1 |
| servico_movel_e_rede_indireta_sem_polo_unico | 1 |

## Exemplos Auditados

- **CISARP:** a rota antiga retornava zero; a busca por CNPJ proprio identificou a clinica CNES 7918747 em Taiobeiras.
- **CONSONORTE:** a rota antiga nao encontrava unidade; a busca por CNPJ proprio identificou a clinica CNES 0975397 e dois vacimoveis.
- **CIMES/CISNES:** permanece sem destino fixo unico; ha unidade movel e oferta indireta documentada, mas nao um hospital atribuivel ao consorcio.
- **CIAS:** a oferta e uma rede regional de SAMU; a sede administrativa nao foi convertida em hospital.
- **CIS/UBA:** os pagamentos historicos foram preservados, mas a entidade inapta nao entra como alternativa atual.

## Invariantes

- Nenhum hospital foi atribuido por proximidade ou semelhanca de nome.
- Ausencia de unidade CNES nao foi convertida em capacidade zero.
- Evidencia atual nao foi retroagida automaticamente para 2014-2021.
- Redes moveis ou com prestadores multiplos nao foram reduzidas a um polo fixo ficticio.
