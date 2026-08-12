---
data: 2026-08-06
status: data_a_confirmar
participantes: [Adriano, Paulo, Pedro]
fonte: transcricao automatica revisada
---

# Reuniao - Validacao MIDES E Universo Do Modelo

> A data de 06/08/2026 foi inferida pelo contexto: reuniao semanal de quinta-feira posterior ao guia publicado em 05/08. Confirmar a data antes de tratar a ata como definitiva.

## Resumo Executivo

A equipe aprovou a logica exploratoria da analise espacial, mas identificou uma etapa anterior indispensavel: distinguir trajetorias financeiras que representam consorcios continuados, iniciativas pontuais e possiveis erros ou lacunas de registro. O objetivo substantivo nao e explicar qualquer pagamento isolado, mas entender por que municipios com atributos favoraveis deixam de pagar ou nao passam a pagar consorcios de atividade continuada.

Nao foi aprovada exclusao automatica por tamanho. O filtro de consorcios com somente 0, 1 ou 2 municipios deve produzir um universo de auditoria, seguido de validacao cadastral, documental e territorial.

## Problema Central

Trajetorias curtas ou esparsas podem representar fenomenos diferentes:

1. consorcio real criado para uma necessidade pontual;
2. consorcio descontinuado apos cumprir sua funcao;
3. municipio que interrompe e depois retoma pagamentos;
4. falha, atraso ou desatualizacao do registro;
5. CNPJ incorreto ou confusao entre entidades semelhantes.

Misturar todos esses casos no mesmo universo pode criar ruido e alterar a interpretacao do modelo.

## Exemplos Discutidos

### Consorcio Pontual

Foi usado o exemplo hipotetico de municipios que criam uma estrutura para uma compra especifica de medicamento. Uma trajetoria curta nao significa necessariamente fracasso: a finalidade pode ter sido cumprida.

### CIMVA

O CIMVA foi tratado como exemplo de expansao continuada:

| Ano | Municipios pagantes MIDES |
|---|---:|
| 2018 | 0 |
| 2019 | 22 |
| 2020 | 37 |
| 2021 | 48 |

Esse e o tipo de empreendimento em que faz sentido investigar por que municipios territorialmente proximos ainda nao aparecem como pagantes.

### Pote X CISNORJE

O caso foi usado para validar a logica das variaveis em `t-1`:

- Pote nao pagava ao CNPJ em 2020;
- os cinco vizinhos pagavam;
- proporcao de vizinhos pagantes: 100%;
- em 2021 ocorreu o primeiro pagamento observado do par.

A equipe considerou a logica compreensivel, mantendo o cuidado de que pagamento nao equivale a adesao formal.

### Adesao Prevista Com Prazo

Foi relatado um caso institucional em que o protocolo de intencoes previa varios municipios, mas cada um tinha prazo para formalizar sua adesao por lei municipal. Isso mostra que previsao documental, adesao juridica e pagamento podem ocorrer em momentos diferentes.

## Decisoes Confirmadas

1. Manter MIDES como melhor referencia financeira disponivel, explicitando suas limitacoes.
2. Nao interpretar automaticamente ausencia de pagamento como nao participacao juridica.
3. Separar casos esparsos para auditoria antes de definir exclusao ou linha de corte.
4. Preservar consorcios pontuais como objeto potencial de estudo, em vez de chama-los automaticamente de erro ou fracasso.
5. Manter o modelo espacial atual como experimental e associativo.

## Encaminhamentos

| Responsavel | Acao | Estado |
|---|---|---|
| Adriano | Gerar diagnostico dos CNPJs com baixa escala/persistencia, iniciando por series com no maximo 1 ou 2 municipios pagantes. | Pendente |
| Equipe | Inspecionar os casos limiares antes de definir exclusao da analise principal. | Pendente |
| Equipe | Comparar trajetorias anomalas com cadastro, nomes/CNPJs e documentos institucionais. | Pendente |
| Equipe | Avaliar distancia rodoviaria ou tempo de viagem, alem da fronteira municipal. | Pesquisa metodologica pendente |
| Equipe | Discutir modelagem de topicos para os normativos dos consorcios. | Frente separada |

## Validacoes Sugeridas

### Cadastral

- nomes iguais ou muito parecidos com CNPJs diferentes;
- matriz e filiais;
- situacao cadastral e ano de fundacao;
- sede e area de atuacao.

### Documental

- protocolo de intencoes;
- contrato de rateio;
- leis municipais de adesao;
- relacao de municipios prevista e efetivamente formalizada.

### Territorial

- fronteira municipal;
- distancia em linha reta como diagnostico inicial;
- distancia ou tempo por malha rodoviaria;
- distancia ate a sede ou nucleo territorial do consorcio.

### Financeira

- MIDES confirma pagamento ao CNPJ;
- SICONFI pode validar despesa municipal agregada com consorcios, mas **nao identifica o CNPJ de destino** e nao confirma diretamente o par.

## Hipoteses A Testar

- Consorcios de atividade continuada apresentam escala e persistencia maiores que iniciativas pontuais.
- Distancia rodoviaria explica melhor a plausibilidade territorial que distancia em linha reta.
- Entradas isoladas e distantes tem maior probabilidade de representar registro atipico.
- Municipios previstos em protocolos podem demorar a formalizar adesao e pagamento.
- A associacao de vizinhanca permanece depois de remover ou estratificar CNPJs de baixa persistencia.

## Pontos Nao Decididos

- Qual linha de corte usar: maximo anual, numero de anos ativos, municipio-anos, valor ou combinacao dessas medidas?
- Casos auditados devem ser excluidos, estratificados ou analisados em modelo separado?
- Qual fonte de malha rodoviaria e qual metrica usar: quilometros ou tempo de viagem?
- Qual sera o universo substantivo: todos os CNPJs ou apenas consorcios de atividade continuada?
- Como separar erro de registro, falta de pagamento, iniciativa pontual e encerramento real?

## Correcao Do Resumo Automatico

O resumo automatico recebido continha afirmacoes mais fortes que a transcricao:

- nao houve decisao final de excluir automaticamente consorcios com 0-2 municipios;
- SICONFI nao valida diretamente um pagamento ao CNPJ;
- consorcio curto nao foi definido automaticamente como erro;
- a atribuicao principal e preparar o diagnostico para posterior decisao humana.

## Impacto No Projeto

Antes de aprofundar os modelos, o projeto precisa caracterizar o universo de CNPJs por escala, persistencia e plausibilidade institucional. Os modelos atuais continuam validos como exploracao do universo existente, mas a proxima estimacao deve incluir sensibilidades com recortes de qualidade e atividade continuada.

## Fonte Do Registro

Ata sintetizada a partir de transcricao automatica extensa e de resumo gerado por IA. Repeticoes, conversas pessoais e problemas administrativos sem impacto metodologico foram removidos.
