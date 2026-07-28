# EDA - Base 1 Vinculos 2015/2019

Arquivo analisado: `C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/analises/base_1_2015_2019/outputs/base_1_vinculos_2015_2019.csv`

## Dimensoes

# A tibble: 8 × 2
  indicador          valor     
  <chr>              <chr>     
1 linhas             4046      
2 colunas            23        
3 anos               2015, 2019
4 municipios         851       
5 consorcios         159       
6 duplicatas_chave   0         
7 cod_ibge_invalidos 0         
8 cnpj_invalidos     0         

## Grupos

# A tibble: 6 × 7
    ano grupo_vinculo n_linhas n_municipios n_consorcios valor_mides_corrente
  <dbl> <chr>            <int>        <int>        <int>                <dbl>
1  2015 MIDES+MUNIC        818          641          106           260342983.
2  2015 MIDES_only         908          626          110            63659123.
3  2015 MUNIC_only         166          154           77                   0 
4  2019 MIDES+MUNIC        993          707          121           301911062.
5  2019 MIDES_only        1065          671          123           132365428.
6  2019 MUNIC_only          96           92           52                   0 
# ℹ 1 more variable: valor_mides_total <dbl>

## NAs

# A tibble: 6 × 3
  coluna               n_na pct_na
  <chr>               <int>  <dbl>
1 setores              2095   51.8
2 setores_munic        1973   48.8
3 setores_consolidado  1124   27.8
4 id_municipio          262    6.5
5 nome_credor_freq      262    6.5
6 sigla                 119    2.9

## Testes De Consistencia

# A tibble: 8 × 2
  teste                                                    n
  <chr>                                                <int>
1 tem_mides_TRUE_com_valor_total_zero                      2
2 tem_mides_FALSE_com_valor_total_positivo                 0
3 tem_munic_TRUE_sem_setor_munic                           0
4 tem_munic_FALSE_com_setor_munic                          0
5 pagamento_corrente_FALSE_com_valor_corrente_positivo     0
6 valor_corrente_negativo                                  0
7 valor_restos_negativo                                    0
8 valor_total_negativo                                     0

## Valores MIDES

# A tibble: 2 × 9
    ano     n   min   p01   p05 mediana     p95      p99       max
  <dbl> <int> <dbl> <dbl> <dbl>   <dbl>   <dbl>    <dbl>     <dbl>
1  2015  1726  50    196. 1739.  42370. 481814. 2362436. 65775848.
2  2019  2056  21.6  837. 4038.  60337. 779379. 3183430. 12716894.

## Observacoes

- Nao ha duplicatas na chave ano + cod_ibge_6 + cnpj_consorcio.
- Nao ha codigos IBGE/CNPJ invalidos no recorte.
- Nao ha valores negativos.
- MUNIC_only tem valores MIDES zerados por definicao.
- IDs MIDES e nome_credor_freq ausentes em MUNIC_only sao esperados.
- Siglas ausentes decorrem de metadados incompletos no cadastro; razao_social esta preenchida.
- Valores muito baixos devem ser tratados como possiveis taxas, restos pequenos ou registros residuais; foram exportados para revisao.

Arquivo XLSX com detalhes: `C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/analises/base_1_2015_2019/checks/base_1_eda_vinculos_2015_2019.xlsx`
