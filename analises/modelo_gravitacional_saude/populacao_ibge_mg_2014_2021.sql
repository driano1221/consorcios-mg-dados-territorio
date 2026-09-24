-- BigQuery: usar projeto de faturamento ipea-consorcios.
-- Fonte original: estimativas populacionais municipais do IBGE,
-- disponibilizadas na tabela basedosdados.br_ibge_populacao.municipio.
SELECT ano, id_municipio, populacao
FROM `basedosdados.br_ibge_populacao.municipio`
WHERE sigla_uf = 'MG' AND ano BETWEEN 2014 AND 2021;
