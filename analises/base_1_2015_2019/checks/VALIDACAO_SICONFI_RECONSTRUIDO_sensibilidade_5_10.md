# Sensibilidade da Validacao SICONFI Reconstruido - 5% e 10%

## Regra fixa

- SICONFI: `consorcio_pagas`.
- Tolerancia absoluta: R$ 10.000.
- Tolerancias relativas testadas: 5% e 10%.

## Resumo Executivo

# A tibble: 4 × 12
  tolerancia_rel_pct tolerancia_rel   ano n_municipio_ano n_congruente
  <chr>                       <dbl> <int>           <int>        <int>
1 5%                           0.05  2015             835          122
2 5%                           0.05  2019             847          325
3 10%                          0.1   2015             835          142
4 10%                          0.1   2019             847          373
# ℹ 7 more variables: n_divergente_valor <int>, n_mides_sem_siconfi <int>,
#   n_siconfi_sem_mides <int>, n_munic_sem_fluxo_financeiro <int>,
#   taxa_congruencia_entre_ambos <dbl>,
#   valor_mides_corrente_cadastro_1194 <dbl>, valor_siconfi_consorcio <dbl>

## Resumo Por Classe

# A tibble: 20 × 9
   tolerancia_rel_pct tolerancia_rel   ano classe_validacao      n_municipio_ano
   <chr>                       <dbl> <int> <chr>                           <int>
 1 5%                           0.05  2015 congruente                        122
 2 5%                           0.05  2015 divergente_valor                  537
 3 5%                           0.05  2015 mides_sem_siconfi                 148
 4 5%                           0.05  2015 munic_sem_fluxo_fina…              11
 5 5%                           0.05  2015 siconfi_sem_mides                  17
 6 5%                           0.05  2019 congruente                        325
 7 5%                           0.05  2019 divergente_valor                  459
 8 5%                           0.05  2019 mides_sem_siconfi                  56
 9 5%                           0.05  2019 munic_sem_fluxo_fina…               3
10 5%                           0.05  2019 siconfi_sem_mides                   4
11 10%                          0.1   2015 congruente                        142
12 10%                          0.1   2015 divergente_valor                  517
13 10%                          0.1   2015 mides_sem_siconfi                 148
14 10%                          0.1   2015 munic_sem_fluxo_fina…              11
15 10%                          0.1   2015 siconfi_sem_mides                  17
16 10%                          0.1   2019 congruente                        373
17 10%                          0.1   2019 divergente_valor                  411
18 10%                          0.1   2019 mides_sem_siconfi                  56
19 10%                          0.1   2019 munic_sem_fluxo_fina…               3
20 10%                          0.1   2019 siconfi_sem_mides                   4
# ℹ 4 more variables: n_municipios <int>,
#   valor_mides_corrente_cadastro_1194 <dbl>, valor_siconfi_consorcio <dbl>,
#   mediana_diferenca_abs_modulo <dbl>

CSV detalhado: `C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/analises/base_1_2015_2019/outputs/base_1_validacao_siconfi_reconstruido_sensibilidade_5_10.csv`
XLSX checks: `C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/analises/base_1_2015_2019/checks/base_1_validacao_siconfi_reconstruido_sensibilidade_5_10.xlsx`
