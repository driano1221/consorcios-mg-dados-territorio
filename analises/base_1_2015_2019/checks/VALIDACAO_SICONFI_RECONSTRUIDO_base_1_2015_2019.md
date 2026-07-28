# Validacao SICONFI Reconstruido - Base 1 2015/2019

## Regra

- Unidade: municipio x ano.
- Regra SICONFI: `consorcio_pagas`.
- Definicao: qualquer rubrica com `consorcio` + `Despesas Pagas`.
- Comparacao principal: `valor_mides_corrente_cadastro_1194` vs `valor_siconfi_reconstruido`.
- Tolerancia: ate R$ 10.000 ou ate 10% de diferenca relativa.

## Resumo Executivo

# A tibble: 2 × 12
    ano n_municipio_ano n_congruente n_divergente_valor n_mides_sem_siconfi
  <int>           <int>        <int>              <int>               <int>
1  2015             835          142                517                 148
2  2019             847          373                411                  56
# ℹ 7 more variables: n_siconfi_sem_mides <int>,
#   n_munic_sem_fluxo_financeiro <int>, taxa_congruencia_entre_ambos <dbl>,
#   valor_mides_corrente_cadastro_1194 <dbl>,
#   valor_mides_corrente_base1_223 <dbl>, valor_siconfi_consorcio <dbl>,
#   valor_siconfi_herdado <dbl>

## Resumo Por Classe

# A tibble: 10 × 8
     ano classe_validacao    n_municipio_ano n_municipios valor_mides_corrente…¹
   <int> <chr>                         <int>        <int>                  <dbl>
 1  2015 congruente                      142          142              20799520.
 2  2015 divergente_valor                517          517             273022674.
 3  2015 mides_sem_siconfi               148          148              30290659.
 4  2015 munic_sem_fluxo_fi…              11           11                     0 
 5  2015 siconfi_sem_mides                17           17                     0 
 6  2019 congruente                      373          373             179106378.
 7  2019 divergente_valor                411          411             239911056.
 8  2019 mides_sem_siconfi                56           56              15507326.
 9  2019 munic_sem_fluxo_fi…               3            3                     0 
10  2019 siconfi_sem_mides                 4            4                     0 
# ℹ abbreviated name: ¹​valor_mides_corrente_cadastro_1194
# ℹ 3 more variables: valor_siconfi_consorcio <dbl>,
#   diferenca_abs_liquida <dbl>, mediana_diferenca_abs_modulo <dbl>

## Leitura

- Esta e a validacao financeira recomendada para a Base 1.
- A aba herdada `valor_cons_real` fica preservada no output como referencia historica.
- O SICONFI continua sem identificar CNPJ destino; portanto, a validacao e agregada por municipio-ano.

Output detalhado: `C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/analises/base_1_2015_2019/outputs/base_1_validacao_siconfi_reconstruido_2015_2019.csv`
Checks: `C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/analises/base_1_2015_2019/checks/base_1_checks_validacao_siconfi_reconstruido_2015_2019.xlsx`
