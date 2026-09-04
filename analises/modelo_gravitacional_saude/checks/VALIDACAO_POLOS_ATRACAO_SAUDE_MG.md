# Validacao: Definicao Do Polo De Atracao Em Saude (MG)

- Data da extracao CNES: `2026-09-03`.
- Entidades consolidadas avaliadas: **84**.
- CNPJs de matriz/filial consultados: **100**.
- Consultas CNES com erro: **0**.
- Unidades CNES diretamente vinculadas ao CNPJ consultado: **670**.
- Unidades classificadas como hospitalares pelo tipo CNES entre fichas de polos unicos: **0**.

## Resultado Da Regra

| Decisao | Entidades |
|---|---:|
| estabelecimento_cnes_unico | 13 |
| rede_vinculada_sem_polo_unico | 49 |
| sede_administrativa_apenas_ancora_sensibilidade | 21 |
| unidade_movel_sem_polo_fixo | 1 |

## Regra De Interpretacao

- `estabelecimento_cnes_unico`: pode usar a localizacao desse estabelecimento como polo assistencial no proximo passo.
- `rede_vinculada_sem_polo_unico`: o CNES confirma vinculo, mas a rede nao pode ser comprimida em uma unica sede sem regra de agregacao.
- `unidade_movel_sem_polo_fixo`: uma unidade movel e vinculada, mas seu endereco nao e interpretado como destino assistencial fixo.
- `sede_administrativa_apenas_ancora_sensibilidade`: nao houve unidade CNES listada sob os CNPJs consultados; isso nao prova ausencia de servico conveniado. A sede entra apenas em analise de sensibilidade geografica.
- O relatorio nao infere hospital, especialidade, leitos ou unidade vinculada quando o CNES nao fornece esse vinculo cadastral direto.
