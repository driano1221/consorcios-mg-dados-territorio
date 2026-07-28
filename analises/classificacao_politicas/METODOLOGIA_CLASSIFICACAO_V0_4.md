# Metodologia Da Classificacao v0.4

**Data:** 2026-07-28  
**Base de entrada:** classificacao tecnica v0.3, preservada sem alteracao.  
**Objetivo:** incorporar decisoes humanas sem alterar MIDES, MUNIC, SICONFI ou cadastro bruto.

## Decisoes Incorporadas

1. Os 15 casos `provisoria_cadastro` foram validados para uso analitico. A fonte permanece `cadastro_ipea_arquivo`; o novo status e `validada_usuario`.
2. Os 48 casos `provisoria_nome` foram validados para uso analitico. A fonte permanece `nome_juridico`; o novo status e `validada_usuario`.
3. Os seis casos `pendente_documento` foram retirados somente da camada analitica ativa, pois sao matrizes sem outra unidade da mesma raiz no recorte MG e tem situacao `Inapta` ou `Baixada`. Eles continuam no arquivo completo como `excluido_inativo`.
4. As duas filiais antes pendentes passaram a seguir a classificacao atualizada da matriz pela raiz de oito digitos. Esta regra afeta apenas classificacao tematica; nao agrega valores MIDES e nao altera pares ou movimentos.
5. Os 23 perfis multifinalitarios foram classificados pelo nome juridico, com aliases MIDES apenas como fallback. Perfil institucional nao e area de politica publica. Area especifica so entrou quando o nome ou alias explicitou setor.

## Resultado Dos Multifinalitarios

| Perfil | Area final | CNPJs |
|---|---|---:|
| multifinalitario | sem area especifica | 13 |
| multifinalitario | saude explicita no nome/alias MIDES | 6 |
| multissetorial | sem area especifica | 3 |
| multissetorial | saude explicita no nome/alias MIDES | 1 |

Os sete casos com `saude` explicita sao: CIMBAJE, CIMES, CIMMESF, CIS Caparao, CIS-Verde, CISAMSF e CISPORTAL.

## Regra Matriz-Filial Aplicada

| Filial | Matriz | Resultado v0.4 |
|---|---|---|
| Centro-CIS (`01999898000205`) | CIS Caparao (`01999898000116`) | `saude`; perfil `multissetorial`; fonte `matriz_raiz_cnpj_8` |
| ICISMEP LOG (`05802877000462`) | CISMEP (`05802877000110`) | `saude`; perfil `setorial`; fonte `matriz_raiz_cnpj_8` |

## Universo v0.4

| Situacao | CNPJs |
|---|---:|
| Universo tecnico completo | 223 |
| Excluidos somente da camada ativa por inatividade | 6 |
| Camada analitica ativa | 217 |

Na camada ativa: 34 confirmados, 94 provisorios coerentes, 63 validados pelo usuario, 7 validados por nome/alias setorial explicito, 16 perfis validados sem area especifica, 2 filiais herdadas e 1 fora do escopo.

## Outputs

```text
outputs/classificacao_areas_politica_mg_v0_4_tecnica.csv
outputs/classificacao_areas_politica_mg_v0_4_completa.csv
outputs/classificacao_areas_politica_mg_v0_4_analitica_ativa.csv
outputs/classificacao_areas_politica_mg_v0_4_analitica_ativa.rds
outputs/resumo_classificacao_areas_politica_mg_v0_4.csv
```

## Limite Mantido

Validar uma area para uso analitico nao equivale a confirmar documentalmente o estatuto de todos os consorcios. Fontes e status anteriores continuam rastreaveis no arquivo tecnico. A proxima decisao estrutural e se a mesma regra matriz-filial deve ser aplicada tambem a valores financeiros e movimentos anuais.
