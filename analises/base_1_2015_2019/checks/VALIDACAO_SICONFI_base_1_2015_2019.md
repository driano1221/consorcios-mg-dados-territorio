# Validacao SICONFI - Base 1 2015/2019

## Regra

- Unidade: municipio x ano.
- Comparacao principal: `valor_mides_corrente_cadastro_1194` vs `valor_cons_real` do SICONFI.
- A Base 1 restrita aos 223 consorcios MG permanece no output como contexto de vinculos.
- SICONFI nao cria par municipio x consorcio.
- Tolerancia: ate R$ 10.000 ou ate 10% de diferenca relativa.

## Resumo Executivo

# A tibble: 2 × 11
    ano n_municipio_ano n_congruente n_divergente_valor n_mides_sem_siconfi
  <int>           <int>        <int>              <int>               <int>
1  2015             838           85                505                 217
2  2019             849           88                546                 206
# ℹ 6 more variables: n_siconfi_sem_mides <int>,
#   n_munic_sem_fluxo_financeiro <int>, taxa_congruencia_entre_ambos <dbl>,
#   valor_mides_corrente_cadastro_1194 <dbl>,
#   valor_mides_corrente_base1_223 <dbl>, valor_siconfi_consorcio <dbl>

## Resumo Por Classe

# A tibble: 10 × 9
     ano classe_validacao    n_municipio_ano n_municipios valor_mides_corrente…¹
   <int> <chr>                         <int>        <int>                  <dbl>
 1  2015 congruente                       85           85              24657348.
 2  2015 divergente_valor                505          505             224168890.
 3  2015 mides_sem_siconfi               217          217              75286615.
 4  2015 munic_sem_fluxo_fi…               6            6                     0 
 5  2015 siconfi_sem_mides                25           25                     0 
 6  2019 congruente                       88           88              72899260.
 7  2019 divergente_valor                546          546             290081233.
 8  2019 mides_sem_siconfi               206          206              71544267.
 9  2019 munic_sem_fluxo_fi…               4            4                     0 
10  2019 siconfi_sem_mides                 5            5                     0 
# ℹ abbreviated name: ¹​valor_mides_corrente_cadastro_1194
# ℹ 4 more variables: valor_mides_corrente_base1_223 <dbl>,
#   valor_siconfi_consorcio <dbl>, diferenca_abs_liquida <dbl>,
#   mediana_diferenca_abs_modulo <dbl>

## Observacoes

- `congruente`: MIDES e SICONFI positivos e dentro da tolerancia.
- `divergente_valor`: MIDES e SICONFI positivos, mas fora da tolerancia.
- `mides_sem_siconfi`: MIDES positivo e SICONFI zero/ausente.
- `siconfi_sem_mides`: SICONFI positivo e MIDES zero no universo dos 1.194 CNPJs do cadastro IPEA.
- `munic_sem_fluxo_financeiro`: MUNIC declarou vinculo, mas MIDES e SICONFI nao mostram fluxo financeiro no municipio-ano.

Output detalhado: `C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/analises/base_1_2015_2019/outputs/base_1_validacao_siconfi_2015_2019.csv`
Checks: `C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para análise/ideiaMides/analises/base_1_2015_2019/checks/base_1_checks_validacao_siconfi_2015_2019.xlsx`
