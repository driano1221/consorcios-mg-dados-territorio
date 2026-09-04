# Validacao: CNES Historico Dos Consorcios De Saude MG

- Competencias: janeiro de 2014 a dezembro de 2021 para estabelecimentos.
- Capacidade principal: dezembro de cada ano.
- Universo: 84 entidades consolidadas por raiz CNPJ.
- Fontes: 120 arquivos oficiais CNES/DATASUS com URL, tamanho e SHA-256.
- Produtos: 672 entidades-ano, 1.868 unidades-ano em dezembro e presenca
  mensal agregada por unidade.

## Cobertura Anual

| Ano | Fixa em dezembro | Fixa em algum mes | Dezembro sem fixa, mas outro mes com fixa | Unidades fixas | Unidades moveis |
|---:|---:|---:|---:|---:|---:|
| 2014 | 40 | 40 | 0 | 48 | 126 |
| 2015 | 41 | 42 | 1 | 48 | 134 |
| 2016 | 46 | 46 | 0 | 51 | 135 |
| 2017 | 52 | 54 | 2 | 60 | 169 |
| 2018 | 58 | 58 | 0 | 66 | 191 |
| 2019 | 58 | 58 | 0 | 66 | 207 |
| 2020 | 58 | 58 | 0 | 65 | 210 |
| 2021 | 60 | 60 | 0 | 68 | 224 |

## Cruzamento Com MIDES

| Pagamento MIDES no ano | Unidade fixa direta em dezembro | Entidades-ano |
|---|---|---:|
| nao | nao | 168 |
| nao | sim | 1 |
| sim | nao | 91 |
| sim | sim | 412 |

O cruzamento nao mede filiacao juridica. Pagamento sem unidade direta pode
indicar prestador contratado, rede indireta, oferta movel ou lacuna cadastral.
Unidade sem pagamento tambem e possivel: CONSONORTE tinha o CNES `0975397` em
dezembro de 2021, mas nenhum pagamento MIDES naquele ano.

## Casos Sentinela

- **CISMARG:** a unidade CNES `6214371` aparece de janeiro a novembro de 2016,
  mas nao em dezembro. A sensibilidade impede interpretar a ausencia isolada
  como fechamento comprovado.
- **CISMEP:** havia duas unidades fixas diretamente vinculadas em dezembro de
  2014-2020; em 2021 havia uma em dezembro e duas em algum mes. A fotografia de
  2026, com quatro fixas e 11 moveis, nao foi retroagida.
- **CIAS:** em 2015 a unidade fixa aparece somente em janeiro. O caso explica
  por que a regra principal e a sensibilidade precisam coexistir.
- **Raiz 64486822:** registra 26 leitos SUS diretos em 2014-2016 e nenhuma
  unidade direta depois. O dado nao prova perda de acesso assistencial, pois a
  oferta pode ter migrado para terceiros ou outra organizacao cadastral.

## Invariantes Verificados

- exatamente 84 entidades por oito anos;
- nenhuma chave entidade-ano ou entidade-ano-CNES duplicada;
- todos os codigos municipais observados pertencem a MG;
- nenhum leito SUS excede o total de leitos existentes;
- capacidade fica vazia quando nao ha unidade fixa em dezembro;
- toda unidade de dezembro aparece na sensibilidade mensal;
- nomes, CPF e CNS de profissionais nao foram retidos;
- os 120 arquivos-fonte possuem hash SHA-256.

## Limites

1. Dezembro nao e media anual nem producao realizada.
2. `ST` mensal mede cadastro; `LT`, `SR` e `PF` foram lidos apenas em dezembro.
3. A oferta indireta ou contratada continua fora desta camada.
4. O painel e o dashboard ainda nao foram modificados.
