# Histórico de mudanças

As sessões detalhadas estão em `docs/DIARIO_DE_TRABALHO.md`. Este arquivo registra apenas marcos do produto.

## 2026-09-03

- fechado o universo saúde–MG: 100 CNPJs em 84 entidades consolidadas, com MIDES, MUNIC e revisão documental preparados para o novo modelo;
- definido o polo assistencial por consulta CNES para matriz e filiais, distinguindo estabelecimento fixo, rede, serviço móvel e sede administrativa de sensibilidade;
- documentada a regra de não reduzir redes a uma sede antes da capacidade e da agregação explícita;
- construída e reprocessada a capacidade assistencial direta para 670 unidades CNES, separando 389 fixas e 281 móveis, com consulta por CNPJ mantenedor e CNPJ próprio e sem reter microdados nominais de profissionais;
- identificadas 61 entidades com oferta fixa direta, 21 sem unidade direta e duas compostas somente por unidades móveis; leitos SUS foram descartados como medida única por cobertura insuficiente;
- adicionados scripts reprocessáveis, testes automatizados e documentação dos passos 3 e 4, sem alterar o dashboard nem estimar um novo modelo.
- ampliado o README como dicionário único de arquivos, fontes, extrações e produtos dos passos 1 a 4, com exemplos do viés produzido por uma massa baseada somente em leitos SUS.
- integrada a matriz rodoviária OSRM/Zenodo para os 853 municípios de MG e 389 unidades fixas, preservando camadas por destino, unidade e entidade;
- documentadas as limitações de sede municipal, simetria e ausência de trânsito por horário, mantendo 21 casos sem unidade e dois somente móveis como tempo não observado;
- adicionados script reprocessável, teste de cobertura/simetria e relatório EDA do passo 5, sem alterar o dashboard ou estimar modelos.
- materializado o painel de saude com 573.216 linhas (`853 x 84 x 8`), consolidando matriz/filiais e preservando integralmente R$ 3,102 bilhoes do MIDES;
- separados estoque inicial, primeiro pagamento, retorno, permanencia e interrupcao, com universos preliminares de entrada, continuidade e intensidade;
- adicionados teste, dicionario, relatorio EDA e metodologia do passo 6; dashboard e modelos existentes continuam inalterados.
- reorganizada a pasta do modelo de saude com dicionario tecnico de arquivos/fontes/extracoes e linha do tempo dos passos 1 a 6, ilustrada pelo caso real Igarape x CISMEP.
- consolidadas as cinco notas metodologicas em `METODOLOGIA_GERAL.md`, deixando uma unica fonte para os passos 1 a 6 e a cobertura complementar.
- completada a auditoria assistencial dos 38 casos originalmente pendentes: 15 falsos negativos foram recuperados pela busca oficial do CNES por CNPJ próprio, redes móveis/indiretas e entidades históricas foram separadas e nenhum prestador foi inferido sem evidência;
- resolvidos os sete alertas de escopo, situação cadastral ou macrogrupo, com decisão explícita para modelo principal, sensibilidade ou exclusão do conjunto atual de alternativas;
- adicionados catálogo documental, script reprocessável e oitavo teste automatizado para a cobertura assistencial complementar, sem alterar o dashboard nem estimar modelos.

## 2026-08-20

- criada a camada nacional de identidade para os 1.194 CNPJs do cadastro IPEA;
- consolidadas 35 filiais em 23 raízes, resultando em 1.159 entidades;
- baixadas e processadas 1.300.862 transações MIDES correspondentes em oito UFs;
- materializados painéis anuais por CNPJ original e por raiz consolidada;
- comprovada a conservação financeira e a reprodução exata do painel MG anterior;
- documentadas cobertura, exceções territoriais, amostras e pontos de validação.

## 2026-07-29

- adotada a identidade `Consórcios MG: Dados e Território`, com o dashboard denominado `Painel Consórcios MG`;
- repositório renomeado para `consorcios-mg-dados-territorio`;
- adicionada a trajetória longitudinal MIDES 2014–2021 por consórcio;
- implementado carregamento sob demanda da tabela anual e matriz município–ano;
- concluídas tabela analítica anual, rotulagem condicional e exportação cartográfica em alta resolução;
- redesenhados os pequenos múltiplos anuais com estilo editorial;
- revisada e testada a documentação dos movimentos e modelos espaciais.

## 2026-07-28

- classificação de políticas públicas consolidada na v0.5 e integrada ao MIDES completo;
- documentação metodológica incorporada ao dashboard;
- materializadas as bases anuais de movimento, features de fronteira e modelos exploratórios;
- criado o diário técnico versionado.

## 2026-06

- construída a Base 1 de 2015/2019 com MIDES, MUNIC e validação SICONFI;
- reconstruída e auditada a regra financeira do SICONFI;
- publicado o primeiro dashboard Shiny do projeto.

## 2026-05

- integrado o painel universal de Minas Gerais com MIDES, MUNIC, SICONFI e CNM;
- construída a apresentação HTML metodológica;
- documentadas as primeiras auditorias cadastrais e de cobertura.
