# Validacao Do Universo De Consorcios De Saude Em MG

**Periodo MIDES:** 2014-2021

## Resultado

- 100 estabelecimentos CNPJ classificados em saude foram consolidados em **84 entidades**.
- **66 entidades** aparecem no MIDES MG; 18 nao possuem pagamento observado no periodo.
- O nucleo setorial preliminar possui **64 entidades**.
- Duas entidades multiarea observadas ficam em camada de sensibilidade, sem exclusao dos arquivos.
- A consolidacao incorporou **16 filiais** em 11 raizes com mais de um estabelecimento.
- Foram encontradas 21 chaves municipio-ano com pagamentos simultaneos a mais de um CNPJ da mesma raiz.

## Camadas

| Camada | Entidades | Uso |
|---|---:|---|
| Universo cadastral amplo | 84 | Toda entidade com area explicita de saude, urgencia ou vigilancia. |
| Universo MIDES observado | 66 | Entidades com pagamento positivo em MG. |
| Nucleo setorial preliminar | 64 | Analise principal antes das validacoes documentais. |
| Sensibilidade multiarea | 2 | Saude explicita junto com outras areas. |

## Casos Para Revisao Do Universo

Esses casos nao sao erros automaticos. Eles exigem decisao de escopo, leitura temporal ou correcao de metadado.

| CNPJ canonico | Sigla | Situacao atual | MIDES 2014-2021 | Motivo |
|---|---|---|---|---|
| `01272081000141` | CISREC | Ativa | 2014-2021 | escopo_saude_multiarea |
| `06070075000125` | CONSORCIO | Ativa | 2014-2021 | escopo_saude_multiarea |
| `00840724000143` | CIS/UBA | Inapta | 2014-2020 | matriz_inativa_com_pagamento_mides |
| `02287790000163` | (sem sigla) | Inapta | 2014-2021 | matriz_inativa_com_pagamento_mides |
| `43863467000178` | CIMESMI | Ativa | Nao observado | escopo_saude_multiarea; matriz_ativa_sem_mides_na_janela |
| `11976772000180` | CODERI | Inapta | Nao observado | escopo_saude_multiarea |
| `12740578000163` | CONSORCIO CINCOZ | Inapta | Nao observado | macroarea_saude_ausente |

## Regras

1. Saude inclui as areas `saude`, `urgencia_emergencia` e `vigilancia_em_saude` da classificacao v0.5.
2. Matriz e filiais usam a raiz de oito digitos; o CNPJ canonico e a matriz `0001`.
3. A situacao cadastral da entidade e a situacao atual da matriz. Ela nao reconstrui a situacao historica de 2014-2021.
4. Presenca MIDES significa pagamento positivo observado, nao adesao juridica.
5. Consorcios multiarea com saude explicita sao preservados e separados para sensibilidade.
6. A inclusao definitiva no conjunto de risco depende das proximas validacoes documental, MUNIC e CNES.
