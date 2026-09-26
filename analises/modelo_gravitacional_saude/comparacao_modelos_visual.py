"""Apresenta os dois pilotos de 2019 usando resultados auditados já estimados."""
from html import escape
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd


HERE = Path(__file__).resolve().parent
ROOT = HERE / "outputs/atracao_relativa_paulo_2019"
SOURCES = [
    "auditoria_sicom_modelo_2019/amostras.csv",
    "atracao_relativa_paulo_2019/metricas_mesma_amostra.csv",
    "atracao_relativa_paulo_2019/metricas_por_fold.csv",
    "atracao_relativa_paulo_2019/previsoes.csv.gz",
    "atracao_relativa_paulo_2019/parametros_validacao.csv",
    "atracao_relativa_paulo_2019/fontes.csv",
]
NAMES = {"clinicas53": "S1 · Clínicas, 53", "sedes53": "S2 · Sedes, 53",
         "sedes62": "S2 · Sedes, 62", "misto62": "S3 · Misto, 62"}


def number(value, digits=0):
    return f"{float(value):,.{digits}f}".replace(",", "_").replace(".", ",").replace("_", ".")


def percent(value, digits=1):
    return number(100 * value, digits) + "%"


def render(dest):
    audited = pd.read_csv(HERE / "outputs" / SOURCES[0]).set_index("modelo")
    scores = pd.read_csv(HERE / "outputs" / SOURCES[1])
    folds = pd.read_csv(HERE / "outputs" / SOURCES[2])
    predictions = pd.read_csv(HERE / "outputs" / SOURCES[3],
        dtype={"id_municipio": str, "cnpj_raiz_8": str},
        usecols=["modelo", "validacao", "id_municipio", "municipio", "cnpj_raiz_8",
                 "entidade", "resposta", "valor_total", "horas_base", "distancia_min_km",
                 "atracao_relativa", "prob_auditada", "prob_paulo_binaria"], low_memory=False)
    params = pd.read_csv(HERE / "outputs" / SOURCES[4])
    assert len(scores) == 24 and len(folds) == 120 and len(params) == 80
    assert set(scores.modelo) == set(NAMES)
    for name, n, positives in (("clinicas53", 45208, 770), ("sedes53", 45208, 770),
                               ("sedes62", 52885, 1298), ("misto62", 52885, 1298)):
        assert audited.loc[name, "pares_auditado"] == n
        assert audited.loc[name, "positivos_auditado"] == positives
        subset = scores[scores.modelo == name]
        assert (subset.n == n).all() and (subset.positivos == positives).all()
    assert (folds.pivot(index=["modelo", "validacao", "fold"],
                        columns="especificacao", values="brier").atracao_relativa <
            folds.pivot(index=["modelo", "validacao", "fold"],
                        columns="especificacao", values="brier").atual).all()

    # EDA da resposta no mesmo recorte auditado usado na comparação.
    distributions = {}
    for name in ("clinicas53", "sedes62"):
        d = predictions[(predictions.modelo == name) & (predictions.validacao == "municipios")]
        counts = d.groupby("id_municipio").resposta.sum()
        distributions[name] = (int((counts == 0).sum()), int((counts == 1).sum()),
                               int((counts >= 2).sum()))
        assert len(counts) == 853
    assert distributions == {"clinicas53": (160, 619, 74), "sedes62": (75, 322, 456)}
    distance_s1 = predictions[(predictions.modelo == "clinicas53") &
                              (predictions.validacao == "municipios")]
    paid_km = float(distance_s1[distance_s1.resposta == 1].distancia_min_km.median())
    unpaid_km = float(distance_s1[distance_s1.resposta == 0].distancia_min_km.median())
    assert round(paid_km) == 52 and round(unpaid_km) == 491

    # Exemplos são previsões fora do treino; jamais usar valores ajustados na amostra.
    clinic = predictions[(predictions.modelo == "clinicas53") &
                         (predictions.validacao == "municipios")]
    cases = []
    for municipality, consortium, title, reading in [
        ("Igarapé", "CISMEP", "As duas formas captam o pagamento",
         "O CISMEP concentra 73,15% da atração calculada para Igarapé entre 53 candidatos. Isso não é a probabilidade de vínculo."),
        ("Centralina", "AMVAP SAUDE", "A comparação entre destinos ajudou",
         "O pagamento existiu, apesar da distância de 127 km até o ponto mais próximo. O piloto anterior atribuiu probabilidade baixa."),
        ("Jacinto", "CISRAL", "A comparação também pode errar mais",
         "A atração relativa é alta, mas não houve pagamento registrado. Oferta próxima não comprova acesso institucional."),
    ]:
        found = clinic[(clinic.municipio == municipality) &
                       (clinic.entidade == consortium)]
        assert len(found) == 1, (municipality, consortium)
        cases.append((found.iloc[0], title, reading))

    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 11,
        "text.color": "#1A252F", "axes.labelcolor": "#566570",
        "xtick.color": "#566570", "ytick.color": "#1A252F",
        "axes.spines.top": False, "axes.spines.right": False,
        "axes.spines.left": False, "axes.spines.bottom": False,
        "savefig.facecolor": "white", "axes.facecolor": "white"})
    figures = []
    panels = []
    for validation, label in (("municipios", "Municípios sorteados"),
                              ("espacial", "Blocos geográficos")):
        values = scores[scores.validacao == validation]
        fig, ax = plt.subplots(figsize=(11.5, 5.3))
        y_positions = [4.7, 3.55, 1.6, .45]
        rows = []
        for (name, description), y in zip(NAMES.items(), y_positions):
            m = values[values.modelo == name].set_index("especificacao")
            old = float(m.loc["atual", "brier"])
            new = float(m.loc["atracao_relativa", "brier"])
            own = float(m.loc["atracao_propria_unidades", "brier"])
            gain = 100 * (old - new) / old
            ax.hlines(y, new, old, color="#B7C5CE", linewidth=3, zorder=1)
            ax.scatter([old], [y], s=145, c="#2980B9", marker="o", zorder=3)
            ax.scatter([new], [y], s=145, c="#C0392B", marker="s", zorder=3)
            ax.text(.0181, y, f"−{number(gain, 1)}%", va="center", ha="right",
                    fontsize=12, color="#1D628F", fontweight="bold")
            rows.append((name, description, old, own, new, gain,
                         float(m.loc["atual", "precisao_media"]),
                         float(m.loc["atracao_relativa", "precisao_media"]),
                         float(m.loc["atual", "logloss"]),
                         float(m.loc["atracao_relativa", "logloss"])))
        ax.set_yticks(y_positions, list(NAMES.values()))
        ax.tick_params(axis="both", length=0, pad=11)
        ax.set_xlim(0, .0185)
        ax.set_ylim(-.15, 5.45)
        ax.set_xticks([0, .005, .01, .015], ["0", "0,005", "0,010", "0,015"])
        ax.grid(axis="x", color="#E8EEF2", linewidth=.8)
        ax.set_axisbelow(True)
        ax.text(0, 5.16, "MESMOS 53 CANDIDATOS", fontsize=9, color="#566570")
        ax.text(0, 2.25, "UNIVERSO AMPLIADO: 62", fontsize=9, color="#566570")
        ax.set_xlabel("Erro de Brier · menor é melhor", labelpad=16)
        fig.subplots_adjust(left=.24, right=.94, top=.93, bottom=.17)
        stem = f"modelo_comparacao_{validation}"
        for ext in ("svg", "png"):
            path = dest / "figuras" / f"{stem}.{ext}"
            fig.savefig(path, dpi=300, bbox_inches="tight", pad_inches=.12)
            figures.append(path)
        plt.close(fig)
        detailed = "".join("<tr><th scope='row'>" + escape(description) + "</th>" +
            "".join(f"<td>{number(v, d)}</td>" for v, d in
                ((old, 5), (own, 5), (new, 5), (ap_old, 3), (ap_new, 3),
                 (loss_old, 4), (loss_new, 4))) + "</tr>"
            for name, description, old, own, new, gain, ap_old, ap_new,
                loss_old, loss_new in rows)
        mobile = "".join(f"<div><strong>{escape(description)}</strong>"
            f"<span>{number(old, 5)} → <b>{number(new, 5)}</b> · −{number(gain, 1)}%</span></div>"
            for name, description, old, own, new, gain, *_ in rows)
        panels.append(f"""<div class="mc-panel mc-{validation}" id="mc-{validation}">
<div class="mc-mobile-scores" aria-label="Erro de Brier por recorte; valor anterior e valor da atração relativa">{mobile}</div>
<img src="figuras/{stem}.svg" alt="Comparação do erro de Brier nos quatro recortes: a atração relativa tem erro menor que o piloto auditado.">
<p class="mc-key"><span class="mc-dot mc-blue"></span> Piloto binário auditado <span class="mc-dot mc-red"></span> Atração relativa <span class="mc-gain-key">À direita: redução percentual do Brier</span></p>
<details class="trace"><summary>Ver Brier, precisão média e logloss por recorte</summary><div class="table-wrap"><table>
<thead><tr><th>Recorte</th><th>Brier: atual</th><th>Sem competição</th><th>Relativo</th><th>AP: atual</th><th>Relativo</th><th>Logloss: atual</th><th>Relativo</th></tr></thead>
<tbody>{detailed}</tbody></table></div><p>AP mede a ordenação dos pagamentos; logloss penaliza previsões confiantes e erradas. Os três modelos foram avaliados nas mesmas linhas deste recorte.</p></details>
</div>""")

    eda = ""
    for name, caption in (("clinicas53", "53 com clínica"), ("sedes62", "62 com sede")):
        empty, one, many = distributions[name]
        eda += f"""<div class="mc-distribution"><div class="mc-distribution-head"><strong>{caption}</strong>
<span>{empty} sem pagamento · {one} com um · {many} com dois ou mais</span></div>
<div class="mc-distribution-bar" role="img" aria-label="{caption}: {empty} municípios sem pagamento, {one} com um, {many} com dois ou mais">
<span style="width:{100*empty/853:.5f}%" class="mc-zero"></span><span style="width:{100*one/853:.5f}%" class="mc-one"></span><span style="width:{100*many/853:.5f}%" class="mc-many"></span></div></div>"""

    case_html = ""
    for row, title, reading in cases:
        outcome = "Pagou" if row.resposta == 1 else "Não pagou"
        value = "R$ " + number(row.valor_total, 2) if row.resposta == 1 else "R$ 0"
        case_html += f"""<article class="mc-case"><div class="mc-case-top"><span>{escape(outcome)} · {value}</span><span>S1 · 53</span></div>
<h3>{escape(row.municipio)} × {escape(row.entidade)}</h3><p class="mc-case-title">{escape(title)}</p>
<div class="mc-probs"><div><span>Piloto auditado</span><strong>{percent(row.prob_auditada, 2)}</strong></div>
<div><span>Atração relativa</span><strong>{percent(row.prob_paulo_binaria, 2)}</strong></div></div>
<p>{escape(reading)}</p></article>"""

    html = f"""<div class="model-compare">
<div class="section-intro"><div class="eyebrow">Modelo gravitacional · saúde/MG · 2019</div>
<h1>A atração relativa reduziu o erro nos quatro recortes de 2019</h1>
<p>Comparamos a probabilidade de pagamento estimada para cada município e consórcio. O piloto anterior usa a oferta e a distância do próprio consórcio; o teste de Paulo acrescenta a posição dele diante dos outros candidatos. Os resultados descrevem vínculos financeiros, não filiação ou uso de serviços.</p></div>
<div class="mc-summary"><div><strong>853</strong><span>municípios em todas as versões</span></div>
<div><strong>53 ou 62</strong><span>consórcios com horas e destino utilizáveis</span></div>
<div><strong>2019</strong><span>um ano; pagamentos e oferta observados</span></div></div>
<div class="mc-nav" role="navigation" aria-label="Percurso da aba Modelo"><a href="#mc-dados">Dados e recortes</a><a href="#mc-formulas">As duas ideias</a><a href="#mc-validacao">Teste e resultados</a><a href="#mc-exemplos">Exemplos</a><a href="#mc-limites">Limites</a></div>

<section class="mc-section" id="mc-dados"><div class="mc-section-label">01 / Dados e recortes</div>
<h2>De 73 consórcios financeiros aos recortes que podemos medir</h2>
<p class="mc-intro">O MIDES define se houve pagamento. IBGE, CNES e Distbrasil descrevem o porte do município, a capacidade cadastrada do consórcio e a distância até seus pontos. Nenhum pagamento zero foi removido por ser zero.</p>
<div class="mc-pipeline"><article><span>01 · MIDES</span><strong>73 consórcios de saúde</strong><p>Somamos pagamentos de 2019 por município e raiz do CNPJ. Valor positivo vira 1; valor zero vira 0.</p></article>
<article><span>02 · Oferta e origem</span><strong>IBGE + CNES</strong><p>População municipal de 2019; horas SUS de dezembro por unidade clínica ou outra modalidade admitida no cenário.</p></article>
<article><span>03 · Território</span><strong>Distbrasil</strong><p>Km rodoviários entre a sede do município de origem e o município da unidade ou sede cadastral do consórcio.</p></article>
<article><span>04 · Auditoria</span><strong>53 ou 62 candidatos</strong><p>Horas positivas e destino conhecido. Conselheiro Pena–CISVI fica sem resposta, não vira zero.</p></article></div>
<div class="mc-funnel"><div><strong>73</strong><span>no núcleo financeiro</span></div><div><strong>54</strong><span>com clínica e rota</span></div><div><strong>53</strong><span>com horas clínicas positivas</span></div><div><strong>62</strong><span>com sede e horas de outras modalidades</span></div></div>
<p class="mc-note">S1 e S2 usam os mesmos 53 quando comparamos clínicas e sedes. Na ampliação para 62, S2 usa a sede e S3 usa clínica quando existe, sede nos demais. A sede pode não representar o local de atendimento nem sua posição histórica.</p>
<div class="mc-eda"><div><h3>Vários vínculos são observados</h3><p>Contagem de municípios pelo número de consórcios com pagamento positivo em 2019, após a auditoria. A fração normalizada de Paulo não pode ser lida como uma escolha única.</p>
<p>No recorte clínico, {number(770/45208*100, 2)}% dos pares têm pagamento. A distância mínima mediana é {number(paid_km, 0)} km nos pagos e {number(unpaid_km, 0)} km nos não pagos. Muitos zeros são comparações distantes: parte do poder preditivo vem dessa separação, sem provar que todos eram alternativas viáveis.</p>
<div class="mc-legend"><span><i class="mc-zero"></i> Nenhum</span><span><i class="mc-one"></i> Um</span><span><i class="mc-many"></i> Dois ou mais</span></div></div>
<div>{eda}</div></div>
<details class="trace"><summary>O que entrou, o que foi transformado e o que ficou de fora</summary><div class="table-wrap"><table><thead><tr><th>Dado</th><th>Tratamento</th><th>Papel ou motivo da ausência</th></tr></thead><tbody>
<tr><th>MIDES</th><td>Valor anual por município × raiz CNPJ; positivo = 1</td><td>Resposta, não explicador do próprio pagamento. Um município pode ter mais de um 1.</td></tr>
<tr><th>IBGE</th><td>ln(população positiva de 2019)</td><td>Porte da origem; os 853 municípios têm valor.</td></tr>
<tr><th>CNES</th><td>Horas SUS positivas somadas por consórcio; peso da unidade = horas da unidade / total</td><td>Capacidade cadastrada. Profissionais e serviços ficaram na base, mas não entraram nesta especificação; leitos SUS não oferecem variação útil no recorte clínico.</td></tr>
<tr><th>Distbrasil</th><td>ln(1 + km) ou (1 + km)<sup>−γ</sup>; rota municipal até cada destino do cenário</td><td>Impedância. Zero quer dizer mesmo município, não deslocamento porta a porta.</td></tr>
<tr><th>Documentos/SICOM</th><td>Um credor de 2019 ficou indeterminado e saiu do treino e do teste</td><td>Conselheiro Pena–CISVI permanece apenas entre os candidatos da atração. São Francisco–CISMARG segue positivo.</td></tr>
<tr><th>RCL, bacia, população da sede</th><td>Não usadas</td><td>RCL incompleta; bacia adiada; população da sede mede porte urbano, não oferta clínica.</td></tr>
</tbody></table></div><p>Os recortes selecionados não têm horas, população ou rota ausentes. Isso resulta do filtro de capacidade e destino, não de preenchimento artificial. O núcleo financeiro completo conserva os consórcios que ficaram fora do teste.</p></details></section>

<section class="mc-section" id="mc-formulas"><div class="mc-section-label">02 / Duas especificações</div>
<h2>Os dois modelos partem da mesma linha município × consórcio</h2>
<p class="mc-intro">A resposta é sempre pagamento positivo em 2019. O que muda é o modo de representar a atração. Uma unidade não vira uma nova observação de pagamento: seus dados entram no cálculo do par.</p>
<div class="mc-models"><article><div class="mc-model-head"><span>MODELO A · PILOTO BINÁRIO</span><b>Oferta própria</b></div>
<h3>Horas e distância do consórcio</h3><p>Somamos as horas SUS. A distância de cada unidade entra numa média ponderada pelas horas. O modelo estima uma chance de pagamento para cada par.</p>
<div class="mc-equation">L<sub>ij</sub> = Σ<sub>u</sub> w<sub>ju</sub> ln(1 + d<sub>iu</sub>)</div>
<div class="mc-equation">logit(p<sub>ij</sub>) = α + β<sub>P</sub> ln(P<sub>i</sub>) + β<sub>H</sub> ln(H<sub>j</sub>) + β<sub>D</sub> L<sub>ij</sub></div>
<p class="mc-formula-reading">β<sub>D</sub> é estimado nos dados; o sinal observado foi negativo. O modelo não soma a oferta dos concorrentes na equação.</p></article>
<article><div class="mc-model-head"><span>MODELO B · TESTE DE PAULO</span><b>Atração relativa</b></div>
<h3>Oferta diante dos demais candidatos</h3><p>Calculamos uma atração por consórcio e a dividimos pela soma das atrações de todos os 53 ou 62 candidatos daquele município.</p>
<div class="mc-equation">A<sub>ij</sub> = H<sub>j</sub><sup>b</sup> Σ<sub>u</sub> w<sub>ju</sub> / (1 + d<sub>iu</sub>)<sup>γ</sup></div>
<div class="mc-equation">s<sub>ij</sub> = A<sub>ij</sub> / Σ<sub>k</sub> A<sub>ik</sub></div>
<div class="mc-equation">logit(p<sub>ij</sub>) = a + b<sub>P</sub>(ln P<sub>i</sub> − 10) + λ logit(s<sub>ij</sub>)</div>
<p class="mc-formula-reading">As frações s somam 100% por município. As chances binárias p não precisam somar 100% e permitem vários pagamentos.</p></article></div>
<p class="mc-definition">Aqui, <b>P</b> é população da origem; <b>H</b> são horas SUS do consórcio; <b>w</b> é a parte das horas na unidade; <b>d</b> é a distância rodoviária em km. <b>logit(p)</b> é ln[p/(1−p)]. Os expoentes e pesos foram aprendidos apenas nos dados de treino.</p>
<div class="mc-example-math"><div><span>Exemplo usado nas contas</span><h3>Igarapé × CISMEP</h3><p>Em 2019, Igarapé pagou <b>R$ 4.740.790,51</b> ao CISMEP. No cenário clínico, Betim tem 1.417 horas SUS e fica a 17,748 km; Brumadinho tem 234 horas e fica a 23,104 km. Total: 1.651 horas.</p></div>
<div><div class="mc-example-step"><b>Modelo A</b><span>L ≈ 2,9667; chance prevista fora do treino: <strong>96,72%</strong>.</span></div>
<div class="mc-example-step"><b>Modelo B</b><span>s = 73,15% da atração dos 53 candidatos; chance binária de pagamento: <strong>98,15%</strong>.</span></div>
<p>73,15% é comparação de oferta e distância. Não é a taxa observada de pacientes, dinheiro ou filiação.</p></div></div></section>

<section class="mc-section" id="mc-validacao"><div class="mc-section-label">03 / Estimação e teste</div>
<h2>A comparação usa os mesmos pares e separa municípios do treino</h2>
<div class="mc-validation-flow"><div><strong>45.208 pares</strong><span>53 candidatos · 770 pagamentos confirmados</span></div><div><strong>52.885 pares</strong><span>62 candidatos · 1.298 pagamentos confirmados</span></div><div><strong>5 + 5 grupos</strong><span>Municípios sorteados e blocos geográficos; quatro grupos treinam, o quinto testa.</span></div></div>
<p class="mc-intro">O piloto binário foi reestimado após a decisão documental. O teste relativo e um controle com atração própria foram treinados nas mesmas divisões. O controle ajuda a distinguir o efeito de somar unidades do efeito de comparar concorrentes. São previsões fora do treino, mas continuam no mesmo ano: não demonstram previsão para 2020 ou 2021.</p>
<fieldset class="mc-switch"><legend>Escolha a validação</legend><input type="radio" name="mc-validation" id="mc-radio-m" checked><label for="mc-radio-m">Municípios sorteados</label><input type="radio" name="mc-validation" id="mc-radio-e"><label for="mc-radio-e">Blocos geográficos</label>{''.join(panels)}</fieldset>
<p class="mc-reading"><strong>O erro caiu em todos os quatro recortes e nos 40 grupos testados.</strong> Na comparação clínico/53, Brier passou de 0,008886 para 0,007084 na validação municipal e de 0,009657 para 0,007206 na espacial. O controle sem competição ficou perto do piloto anterior. Isso sugere valor no contexto dos outros candidatos, sem provar que a lista de candidatos é a correta.</p>
<p class="mc-source">Brier é a média de (pagamento observado − chance prevista)². Menor é melhor; não é percentual de acerto. Não compare o número absoluto dos recortes 53 e 62 como se tivessem a mesma amostra.</p></section>

<section class="mc-section" id="mc-exemplos"><div class="mc-section-label">04 / Pares concretos</div>
<h2>O ganho médio convive com erros relevantes</h2><p class="mc-intro">Todos os números abaixo são de 2019, no recorte clínico com 53 candidatos, com previsões geradas sem o município no treino.</p>
<div class="mc-cases">{case_html}</div></section>

<section class="mc-section" id="mc-limites"><div class="mc-section-label">05 / Interpretação</div>
<h2>O que o teste sustenta e o que ainda precisa de evidência</h2>
<div class="mc-limits"><article><h3>Limites dos dados</h3><p>Pagamento no MIDES é vínculo financeiro, não filiação jurídica nem fluxo de pacientes. Horas SUS e unidades são cadastro de dezembro, não produção assistencial. A malha rodoviária é estática e liga sedes municipais, sem trajeto dentro do município. Sedes de consórcios não têm vigência anual comprovada.</p></article>
<article><h3>Limites dos modelos</h3><p>Os 53/62 candidatos são um conjunto exploratório; alguns podem não ter sido opções institucionais para cada município e outros ficaram fora por falta de capacidade identificada. O teste usa capacidade e pagamento de 2019, sem validação temporal ou interpretação causal. O modelo relativo ainda erra pares como Jacinto–CISRAL.</p></article></div>
<details class="trace"><summary>Fontes, scripts e reprodução</summary><div><p>Pagamentos: MIDES/Base dos Dados. População: IBGE. Unidades, funções e horas SUS: CNES/DATASUS. Distância entre municípios: Distbrasil. As decisões de credor usam objetos TCE/SICOM, documentados em <a href="https://github.com/driano1221/consorcios-mg-dados-territorio/tree/master/analises/modelo_gravitacional_saude/evidencias" target="_blank" rel="noreferrer">evidências do projeto</a>.</p>
<p>Scripts 31 e 32 preparam os cenários e o piloto; 40 aplica a decisão auditada; 43 testa a atração relativa. Testes 19, 20, 26 e 28 conferem dados, folds e resultados. As tabelas completas de previsões e métricas estão em <code>outputs/atracao_relativa_paulo_2019/</code>. A apresentação lê esses arquivos; abrir a aba não reestima nada.</p>
<p><a href="https://github.com/driano1221/consorcios-mg-dados-territorio/blob/master/analises/modelo_gravitacional_saude/METODOLOGIA_GERAL.md" target="_blank" rel="noreferrer">Metodologia e limites completos</a>.</p></div></details></section>
</div>"""
    assert "73,15%" in html and "45.208 pares" in html
    return html, figures
