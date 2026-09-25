-- Auditoria pontual do par com pagamento positivo e baixa previsao.
-- O municipio pode pagar varios consorcios; nao deduplicar por valor/data.
SELECT ano, data, id_municipio, nome_credor, documento_credor,
       indicador_restos_pagar, fonte, valor_final, valor_liquido_recebido
FROM `basedosdados.world_wb_mides.pagamento`
WHERE sigla_uf = 'MG'
  AND ano = 2019
  AND id_municipio = '3118403'
  AND SUBSTR(documento_credor, 1, 8) = '00639952'
ORDER BY data, documento_credor, valor_final
