# Contribuição

Este repositório combina código, decisões metodológicas e documentação de pesquisa. Mudanças devem preservar a rastreabilidade entre fonte, transformação e resultado.

## Fluxo recomendado

1. Crie uma branch curta e descritiva.
2. Restrinja a alteração à frente metodológica ou funcional em discussão.
3. Execute os testes relacionados.
4. Atualize a metodologia específica quando uma regra analítica mudar.
5. Registre a sessão em `docs/DIARIO_DE_TRABALHO.md`.
6. Atualize `docs/MEMORIA_ideiaMides.md` e `docs/PROXIMOS_PASSOS.md` quando o estado do projeto mudar.
7. Confirme que nenhum dado pesado ou sensível entrou no Git.

## Convenções

- R: seguir o estilo já usado no módulo alterado e preferir pipelines legíveis com `dplyr`.
- Arquivos: usar nomes descritivos e manter a numeração quando a pasta representar um pipeline sequencial.
- Commits: usar mensagens objetivas, preferencialmente no padrão `tipo: descrição`.
- Documentação: distinguir claramente regra executada, hipótese, decisão pendente e limitação.
- Dados financeiros: não consolidar matriz e filial sem decisão metodológica registrada.

Tipos de commit sugeridos:

| Tipo | Uso |
|---|---|
| `feat` | Nova funcionalidade ou produto analítico |
| `fix` | Correção de comportamento ou resultado |
| `docs` | Documentação sem alteração analítica |
| `refactor` | Reorganização sem mudança de resultado esperada |
| `test` | Inclusão ou ajuste de validações |
| `style` | Alteração visual sem mudança metodológica |

## Testes

Os testes do dashboard ficam em `dashboards/base1_shiny/tests/`. As análises espaciais também possuem testes próprios em `analises/movimentos_espaciais/tests/`.

Mudanças no dashboard devem verificar, no mínimo:

- abertura das seis páginas principais;
- resposta dos filtros e KPIs;
- atualização dos mapas;
- tabelas e detalhes expansíveis;
- ausência de erros no console;
- layout em resolução desktop e móvel quando houver alteração visual.

## Pull requests

Uma revisão deve informar:

- problema ou pergunta atendida;
- arquivos e regras alterados;
- testes executados;
- impacto sobre bases, pares, valores ou classificações;
- limitações e decisões ainda pendentes.
