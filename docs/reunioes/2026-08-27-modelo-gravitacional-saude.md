# Reuniao De 27/08/2026 - Modelo Gravitacional De Saude

## Decisoes Confirmadas

1. Iniciar por Minas Gerais e pelo setor saude.
2. Usar o MIDES como fonte longitudinal principal.
3. Manter `municipio x consorcio x ano` como unidade, permitindo multiplos consorcios simultaneos.
4. Interpretar MIDES como pagamento observado, nao adesao juridica comprovada.
5. Adaptar a logica gravitacional: capacidade de atracao do polo e impedancia por tempo de viagem.
6. Validar o universo saude-MG com documentos e comparacao MIDES-MUNIC em 2019 antes da nova estimacao.
7. Estudar separadamente entrada/presenca financeira e continuidade do vinculo.

## Especificacao Ainda Aberta

- polo relevante: sede administrativa, hospital principal ou rede assistencial;
- massa de atracao: leitos SUS, especialidades, producao ou indice composto;
- intensidade: valor por habitante, proporcao da RCL ou outra forma;
- continuidade: logit de saida anual, sobrevivencia discreta ou modelo de eventos recorrentes;
- conjunto de consorcios disponiveis para cada municipio e ano;
- tratamento dos pares ja presentes em 2014, com duracao anterior nao observada.

## Leitura Estatistica Recomendada

O desenho discutido e compativel com tres componentes complementares:

1. logit de entrada/presenca por par e ano;
2. modelo de intensidade entre pagamentos positivos, ou modelo hurdle para zero e valor positivo;
3. risco anual de interrupcao em tempo discreto, condicionado a pagamento em `t-1`.

O modelo gravitacional nao foi estimado nesta reuniao. Os modelos exploratorios atuais permanecem inalterados.

## Proxima Entrega

1. validar a lista de consorcios de saude e sua identidade canonica em MG;
2. comparar MIDES 2019, MUNIC 2019 e evidencias documentais;
3. definir o polo assistencial;
4. integrar tempo rodoviario e capacidade CNES;
5. realizar EDA antes da especificacao final.

## Fonte

Sintese tecnica baseada na transcricao da reuniao. Resumos automaticos foram usados apenas como apoio e nao transformaram hipoteses em decisoes.
