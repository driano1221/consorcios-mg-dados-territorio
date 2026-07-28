# Auditoria Documental Dos 39 CNPJs Sinalizados

**Data:** 2026-07-20  
**Escopo:** 39 CNPJs MG marcados para revisao pela classificacao automatica v0.1.  
**Regra:** consultar evidencias publicas relevantes por CNPJ; confirmar ou ajustar somente quando a evidencia identificou a finalidade institucional. Compra, licitacao ou unidade operacional isolada nao define sozinha a area finalistica.

## Resultado

| Resultado | CNPJs | Tratamento |
|---|---:|---|
| Confirmado | 19 | classificacao mantida ou consolidada com evidencia documental |
| Ajustado | 10 | classificacao automatica substituida por classificacao documentada |
| Evidencia insuficiente | 10 | permanece pendente; nenhuma inferencia forte foi aplicada |

## Confirmados Ou Ajustados

| CNPJ | Sigla | Decisao final | Confianca |
|---|---|---|---|
| 20.321.585/0001-59 | CIDRUS | agricultura; desenvolvimento regional | media |
| 18.303.697/0001-35 | CIMVALES | desenvolvimento regional | media |
| 10.331.797/0001-63 | CISAB Zona da Mata | saneamento basico | alta |
| 46.125.774/0001-40 | CIMBASP | infraestrutura; iluminacao publica; compras compartilhadas | media |
| 53.255.914/0001-60 | CIMGEP | saude; perfil multifinalitario preservado | alta |
| 45.847.892/0001-07 | CIMGRAS | perfil multifinalitario, sem setor unico | media |
| 50.387.580/0001-90 | CIMLAGO | compras compartilhadas; perfil multifinalitario preservado | media |
| 02.034.350/0002-85 | CISVERDE | saude | alta |
| 19.193.527/0001-08 | CODANORTE | perfil multifinalitario; areas diretas preservadas | media |
| 18.253.417/0001-21 | CONSERVAR MUCURI | meio ambiente; desenvolvimento regional | media |
| 53.249.431/0001-52 | COMGRANBEL | compras compartilhadas; perfil multifinalitario preservado | media |
| 29.367.897/0001-78 | Casa Lar Vale | assistencia social | alta |
| 28.720.927/0001-15 | CIALAR | assistencia social | alta |
| 50.337.678/0001-32 | CIAMI | assistencia social | alta |
| 09.097.006/0001-01 | CISEP | seguranca publica | alta |
| 45.758.212/0001-70 | CISICOM | inspecao de produtos de origem animal | media |
| 05.802.877/0003-81 | CISMEP | saude | alta |
| 05.802.877/0002-09 | CISMEP | saude | alta |
| 14.424.753/0001-39 | CONCRIADE | assistencia social | alta |
| 12.740.578/0001-63 | CICONZ | vigilancia em saude | alta |
| 02.870.480/0001-77 | Consorcio Zona da Mata e Campos das Vertentes | desenvolvimento regional | alta |
| 45.421.031/0001-54 | CORIDOCE | meio ambiente; saneamento basico; desenvolvimento regional | alta |
| 20.957.637/0001-88 | CASIP | iluminacao publica | alta |
| 21.213.865/0001-06 | CIDASSP | meio ambiente; residuos solidos | media |
| 21.512.443/0001-31 | CIMASP | infraestrutura; compras compartilhadas; perfil multifinalitario preservado | media |
| 43.863.467/0001-78 | CIMESMI | saude; desenvolvimento regional; infraestrutura; perfil multifinalitario preservado | media |
| 35.617.360/0001-11 | AMEG | gestao publica; funcao administrativa, nao politica setorial | media |
| 14.100.905/0001-48 | CER Serra do Papagaio | meio ambiente; recursos hidricos; saneamento; desenvolvimento regional | media |
| 11.976.772/0001-80 | CODERI | multiarea documentada em protocolo municipal | alta |

## Pendencias Mantidas

Os CNPJs abaixo foram efetivamente revisados, mas a evidencia publica localizada nao justificou uma classificacao definitiva. Eles permanecem sinalizados em `necessita_revisao_final = TRUE`.

| CNPJ | Sigla | Motivo para manter pendente |
|---|---|---|
| 01.999.898/0002-05 | CENTRO-CIS | filial de consorcio multissetorial; depende da decisao matriz/filial |
| 36.027.665/0001-36 | CIMERP | perfil multifinalitario sem setor comprovado |
| 20.362.307/0001-40 | AMESP | associacao regional; compras isoladas nao definem politica publica |
| 02.097.453/0001-03 | CIE SUL | nenhuma evidencia publica conclusiva localizada |
| 10.423.008/0001-14 | CIMEG | cadastro baixado sem setor comprovado |
| 12.418.785/0001-04 | COBANDEIRA | nenhuma evidencia publica conclusiva localizada |
| 15.550.319/0001-68 | Consorcio Abaete/Martinho Campos/Pompeu | denominacao sem area finalistica comprovada |
| 12.041.914/0001-80 | Consorcio Intermunicipal Sul de Minas | denominacao sem area finalistica comprovada |
| 05.802.877/0004-62 | ICISMEP LOG | filial logistica; depende da decisao matriz/filial |
| 20.149.133/0001-31 | COREMESP | conflito entre evidencia interna e denominacao juridica |

## Uso Dos Arquivos

- As decisoes e URLs estao em `inputs/revisao_documental_39_cnpjs_v0_2.csv`.
- A classificacao final esta em `outputs/classificacao_areas_politica_mg_v0_2.csv`.
- A planilha `revisao_classificacao_areas_politica_mg_v0_2.xlsx` lista somente as 10 pendencias restantes na aba `revisao_manual`.
- A consolidacao por raiz de CNPJ nao foi executada e nao deve ser inferida a partir desta classificacao.
