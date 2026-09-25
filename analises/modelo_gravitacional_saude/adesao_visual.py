"""Apresentação dos resultados já estimados; não altera dados nem ajusta modelos."""
from html import escape
from pathlib import Path
import csv
import math

HERE = Path(__file__).resolve().parent
MODELS = {'clinicas53': 'S1 · Clínicas, 53', 'sedes53': 'S2 · Sedes, mesmos 53',
          'sedes62': 'S2 · Sedes, 62', 'misto62': 'S3 · Misto, 62'}
SOURCES = ['adesao_financeira/' + n + '.csv' for n in
           ['amostras', 'validacao', 'coeficientes', 'exemplos', 'maiores_erros',
            'calibracao', 'diagnostico_intramunicipal']]
SOURCES += ['auditoria_alternativas/cobertura_regras.csv']


def read(name):
    with (HERE / 'outputs' / name).open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def fmt(value, digits=0):
    return f'{float(value):,.{digits}f}'.replace(',', '_').replace('.', ',').replace('_', '.')


def table(headers, rows):
    return '<div class="table-wrap"><table><thead><tr>' + ''.join(
        '<th scope="col">'+escape(h)+'</th>' for h in headers) + '</tr></thead><tbody>' + ''.join(
        '<tr>'+''.join('<td>'+escape(str(v))+'</td>' for v in row)+'</tr>' for row in rows)+'</tbody></table></div>'


def render(dest):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.ticker import FuncFormatter
    try:
        import scienceplots
        plt.style.use(['science', 'no-latex', 'notebook'])
    except ImportError:
        pass
    plt.rcParams.update({'font.family':'DejaVu Sans', 'font.size':11, 'text.color':'#1A252F',
        'axes.labelcolor':'#566570', 'xtick.color':'#566570', 'ytick.color':'#1A252F',
        'axes.spines.top':False, 'axes.spines.right':False, 'axes.spines.left':False,
        'axes.spines.bottom':False, 'savefig.facecolor':'white', 'axes.facecolor':'white',
        'xtick.top':False, 'ytick.right':False, 'xtick.minor.visible':False,
        'ytick.minor.visible':False})
    samples, metrics, coefs, examples, errors, calibration, intra, territory = [read(p) for p in SOURCES]
    examples += errors
    def metric(model, scheme, ref='modelo'):
        return next(r for r in metrics if r['modelo']==model and r['validacao']==scheme
                    and r['fold']=='0' and r['referencia']==ref)
    products=[]
    def save(fig, stem):
        for ext in ['svg','png']:
            path=dest/'figuras'/f'{stem}.{ext}'
            fig.savefig(path,dpi=300,bbox_inches='tight',pad_inches=.18)
            products.append(path)
        plt.close(fig)
    panels=[]
    for scheme, title in [('municipios','Municípios sorteados'),('espacial','Blocos geográficos')]:
        fig, ax=plt.subplots(figsize=(10.5,4.6))
        ys=[4.3,3.3,1.3,.3]
        for (key,label),y in zip(MODELS.items(),ys):
            v=float(metric(key,scheme)['brier']); ref=float(metric(key,scheme,'prevalencia')['brier'])
            ax.hlines(y,0,ref,color='#DCE3E7',linewidth=12,zorder=1)
            ax.hlines(y,0,v,color='#2980B9',linewidth=12,zorder=2)
            ax.plot(ref,y,'|',color='#1A252F',markersize=21,markeredgewidth=2)
            ax.text(v+.00065,y+.20,fmt(v,5),color='#1D628F',weight='bold',fontsize=11)
            ax.text(ref+.00065,y,fmt(ref,5),va='center',fontsize=10,color='#566570')
        ax.set_yticks(ys,list(MODELS.values())); ax.tick_params(axis='both',length=0,pad=10)
        ax.set_xlim(0,.031); ax.set_ylim(-.35,5.2); ax.set_xticks([0,.01,.02,.03])
        ax.xaxis.set_major_formatter(FuncFormatter(lambda x,pos:fmt(x,2)))
        ax.xaxis.grid(True,color='#EDF1F3',linewidth=.8); ax.set_axisbelow(True)
        ax.text(0,4.95,'MESMOS 53 CONSÓRCIOS',fontsize=9,color='#566570')
        ax.text(0,1.95,'UNIVERSO AMPLIADO: 62',fontsize=9,color='#566570')
        ax.set_xlabel('Erro de Brier · menor é melhor',labelpad=14)
        fig.tight_layout()
        save(fig,'modelo_brier_'+scheme)
        rows=[]
        for key,label in MODELS.items():
            s=next(r for r in samples if r['modelo']==key); m=metric(key,scheme)
            rows.append([label,fmt(s['linhas']),fmt(s['positivos']),fmt(m['brier'],5),fmt(m['average_precision'],3)])
        panels.append(f'<div class="binary-panel binary-{scheme}" id="bin-{scheme}"><h3>{title}</h3>'
            f'<img class="binary-figure" src="figuras/modelo_brier_{scheme}.svg" alt="Erro de Brier dos quatro ajustes; valores completos na tabela seguinte.">'
            '<p class="source">Azul: modelo. Traço escuro: prever apenas a frequência média do treino. Cada ajuste tem sua própria referência.</p>'
            '<details class="trace"><summary>Consultar números e precisão média (AP)</summary><div>'
            +table(['Cenário','Pares','Pagos','Brier ↓','AP ↑'],rows)
            +'<p>AP resume a capacidade de colocar relações pagas no início de uma ordenação por probabilidade. Não é percentual de acerto. Brier avalia probabilidades; também depende da proporção de pagamentos na amostra.</p></div></details></div>')
    # Calibração: não confundir probabilidade individual com proporção em grupos.
    cal=sorted([r for r in calibration if r['modelo']=='clinicas53' and r['validacao']=='municipios'],key=lambda r:float(r['prob_media']))
    fig,ax=plt.subplots(figsize=(7,5.3))
    ax.plot([0,100],[0,100],color='#7F8C8D',linestyle='--',linewidth=1)
    ax.plot([100*float(r['prob_media']) for r in cal],[100*float(r['fracao_observada']) for r in cal],color='#2980B9',marker='o',linewidth=2)
    high=cal[-1]; hx=100*float(high['prob_media']); hy=100*float(high['fracao_observada'])
    ax.annotate(f"{fmt(hx,1)}% previstos\n{fmt(hy,1)}% pagos\n{fmt(high['n'])} pares",xy=(hx,hy),xytext=(51,72),fontsize=11,
                arrowprops={'arrowstyle':'-','color':'#C0392B'},color='#C0392B')
    ax.set(xlim=(0,103),ylim=(0,103),xlabel='Probabilidade média prevista (%)',ylabel='Relações com pagamento observado (%)')
    ax.set_xticks([0,25,50,75,100]); ax.set_yticks([0,25,50,75,100]); ax.grid(color='#EDF1F3'); ax.set_axisbelow(True)
    fig.tight_layout(); save(fig,'modelo_calibracao')
    head='''<div class="binary-model"><div class="section-intro"><div class="eyebrow">Adesão financeira · 2019</div>
<h1>O modelo identifica um padrão espacial, mas ainda erra vínculos importantes</h1>
<p>Estimamos a probabilidade de um município pagar a um consórcio, usando população, horas SUS e distância rodoviária. Um município pode ter vários vínculos. O resultado descreve pagamentos, sem comprovar filiação jurídica ou atendimento.</p></div>
<div class="binary-summary"><div><strong>853</strong><span>municípios em todos os cenários</span></div><div><strong>53 → 62</strong><span>consórcios, conforme o recorte</span></div><div><strong>2019</strong><span>pagamentos do ano e CNES de dezembro</span></div></div>
<div class="model-jumps" aria-label="Leitura dos modelos"><a href="#bin-amostra">Amostra e cenários</a><a href="#bin-resultados">Desempenho</a><a href="#bin-casos">Exemplos reais</a><a href="#bin-conta">A conta</a><a href="#bin-auditoria">O que falta</a></div>
<h2 class="subsection" id="bin-amostra">Por que não entram todos os consórcios?</h2>
<ol class="flow binary-flow"><li><b>73 no núcleo financeiro</b><span>62.269 pares: 853 municípios × 73 consórcios. Há 1.376 relações pagas.</span></li><li><b>54 com clínica e rota</b><span>19 não têm destino clínico direto elegível. As 54 somam 62 clínicas.</span></li><li><b>53 com horas positivas</b><span>CISVAS tem zero horas cadastradas. ln(horas) exige um valor positivo.</span></li><li><b>62 na ampliação</b><span>Nove entidades acrescentam horas de outras modalidades. Dez continuam sem massa positiva utilizável; CISVAS fica fora.</span></li></ol>
<p class="note">Não excluímos pares porque têm pagamento zero. O S1 conserva 44.438 zeros e 771 relações pagas. A lista estadual é um conjunto exploratório de candidatos; não garante que todo município possa contratar todo consórcio.</p>
<div class="binary-scenarios"><article><span>S1</span><h3>Municípios das clínicas</h3><p>As horas de cada unidade ponderam sua distância até a origem. Usa 53 consórcios.</p><small>45.209 pares · 771 pagos</small></article><article><span>S2</span><h3>Município da sede</h3><p>Concentramos a massa na sede cadastral. Primeiro com os mesmos 53; depois com 62.</p><small>45.209 ou 52.886 pares</small></article><article><span>S3</span><h3>Clínicas e sede</h3><p>Usa a clínica onde disponível e a sede nos demais casos, no universo de 62.</p><small>52.886 pares · 1.299 pagos</small></article></div>
<p class="source">A sede disponível não tem vigência histórica comprovada. Nos três cenários, Distbrasil liga sedes municipais; não é rota até a porta da clínica.</p>
<h2 class="subsection" id="bin-resultados">O ganho aparece fora do treino, com limites</h2>
<p class="lead">Todos os pares de um município ficam no mesmo grupo. Estimamos em quatro grupos e prevemos o quinto. A divisão geográfica também afasta áreas inteiras do treino. As duas avaliações usam 2019, sem prever outro ano.</p>
<fieldset class="binary-switch"><legend>Comparar a validação</legend><input type="radio" id="bin-radio-m" name="bin-validation" checked><label for="bin-radio-m">Municípios sorteados</label><input type="radio" id="bin-radio-e" name="bin-validation"><label for="bin-radio-e">Blocos geográficos</label>'''
    body=head+''.join(panels)+'</fieldset>'
    m=metric('clinicas53','municipios'); base=metric('clinicas53','municipios','prevalencia')
    gain=100*(1-float(m['brier'])/float(base['brier']))
    body+=f'<p class="model-reading"><strong>No S1, o Brier cai {fmt(gain,1)}% frente à frequência média.</strong>É redução de erro nessa referência, não {fmt(gain,1)}% de acerto. Compare clínicas e sedes nos mesmos 53; passar para 62 altera a amostra e a proporção de pagamentos. Não há vantagem relevante da sede na amostra comum.</p>'
    body+='''<div class="binary-calibration"><div><h3>Previsões altas ainda podem exagerar</h3><p>Na diagonal, a probabilidade média coincide com a frequência observada do grupo. Pontos abaixo dela indicam previsão maior que a proporção de pagamentos.</p>'''
    body+=f'<p>No grupo acima de 80%, a previsão média é {fmt(hx,1)}%, mas {fmt(hy,1)}% pagaram: {high["positivos"]} de {high["n"]} pares.</p>'
    body+='''<p class="source">S1 · validação por municípios. Grupos têm tamanhos diferentes; os pontos não representam municípios individuais nem intervalos de confiança.</p></div><img class="binary-figure" src="figuras/modelo_calibracao.svg" alt="Calibração do S1: no grupo com previsões acima de 80%, 92,5% previstos contra 85,4% pagos."></div>
<h2 class="subsection" id="bin-casos">Quatro exemplos reais</h2><p class="lead">S1, previsão sem o município no treino. O valor observado e a probabilidade respondem a perguntas diferentes.</p><div class="binary-cases">'''
    keys=[('3130101','05802877'),('3170107','09310999'),('3137205','05802877'),('3118403','00639952')]
    notes=['A previsão é compatível com o pagamento observado. Não prova que todos os serviços foram usados nas duas clínicas.',
           'O relatório municipal de contas confirma o zero no rateio. A localização no mesmo município leva a uma previsão excessiva.',
           'Há pagamento além de 120 minutos. Uma regra de duas horas excluiria este vínculo financeiro real.',
           'Os 14 objetos de 2019 foram lidos: R$ 11.468,66 em DCTF, ITR e radiodifusão, com multas e juros. Atribuição ao CISVI rejeitada na decisão auditada. Valor e previsão abaixo são do ajuste original, conservado para comparação; este caso não é um positivo validado.']
    for key,note in zip(keys,notes):
        r=next(r for r in examples if (r['id_municipio'],r['cnpj_raiz_8'])==key and r['modelo']=='clinicas53' and r['validacao']=='municipios')
        p=float(r['prob_validacao'])*100; label='>99,99%' if p>99.99 else fmt(p,2)+'%'
        value_label = 'Valor MIDES com atribuição rejeitada' if key[0]=='3118403' else 'Pagamento em 2019'
        body+=f'<article><h3>{escape(r["municipio"])} × {escape(r["entidade"])}</h3><dl><div><dt>{value_label}</dt><dd>R$ {fmt(r["valor_total"],2)}</dd></div><div><dt>Probabilidade prevista</dt><dd>{escape(label)}</dd></div></dl><div class="prob-track" aria-hidden="true"><span style="width:{p:.6f}%"></span></div><p>{escape(note)}</p></article>'
    body+='</div><h2 class="subsection" id="bin-conta">Dos dados à probabilidade</h2>'
    body+=table(['Informação','Origem e transformação','Papel no modelo'],[
        ['Pagamento anual','MIDES: soma por município, raiz CNPJ e ano; y=1 se valor > 0','Resultado que queremos explicar. Reais não são número de pacientes.'],
        ['População da origem','IBGE/2019; logaritmo natural de população positiva','Porte do município pagador.'],
        ['Horas SUS','CNES de dezembro/2019; soma e ln(horas positivas)','Oferta cadastrada, não consultas realizadas ou profissionais únicos.'],
        ['Distância em km','Distbrasil estática; ln(1+km), ponderado pelas horas das unidades','Impedância espacial. Zero significa mesmo município.']])
    c={r['termo']:float(r['coeficiente']) for r in coefs if r['modelo']=='clinicas53'}
    eta=c['(Intercept)']+c['log_populacao']*math.log(43045)+c['log_horas']*math.log(1651)+c['impedancia']*2.9667
    body+='''<ol class="pipeline compact"><li><h2>Observamos o vínculo financeiro</h2><p>Igarapé pagou R$ 4.740.790,51 ao CISMEP em 2019. Portanto, y = 1. A população de Igarapé é 43.045.</p></li><li><h2>Localizamos a capacidade</h2><p>Betim: 1.417 horas SUS. Brumadinho: 234. Total do CISMEP: 1.651 horas. No S1, as distâncias recebem pesos de 85,8% e 14,2%, respectivamente.</p></li><li><h2>Aplicamos a equação estimada</h2><p>L = Σᵤ (Hⱼᵤ / Hⱼ) × ln(1 + kmᵢᵤ). Para esse par, L ≈ 2,9667. A população e a capacidade entram em logaritmo, com coeficientes estimados nos dados.</p></li><li><h2>Distinguimos ajuste e validação</h2><p>O ajuste completo dá cerca de 95,94%. A previsão fora do treino é 96,67%, mostrada acima. São probabilidades de pagamento; não são percentuais do orçamento.</p></li></ol>'''
    body+=f'<details class="trace"><summary>Ver fórmula, coeficientes e variáveis que ficaram de fora</summary><div><div class="model-equations"><div><span>Pontuação do ajuste completo S1</span><p>η = {fmt(c["(Intercept)"],4)} − {fmt(-c["log_populacao"],4)} ln(P) + {fmt(c["log_horas"],4)} ln(H) − {fmt(-c["impedancia"],4)} L</p></div><div><span>Transformação logística</span><p>p = 1 / (1 + exp(−η))</p></div></div>'
    body+=table(['Variável','Coeficiente','IC 95% inferior','IC 95% superior'],[
        [label,*[fmt(r[k],4) for k in ['coeficiente','ic95_inf','ic95_sup']]]
        for term,label in [('log_populacao','ln(população)'),('log_horas','ln(horas SUS)'),('impedancia','Impedância L')]
        for r in coefs if r['modelo']=='clinicas53' and r['termo']==term])
    body+='''<p>Intervalos com erros agrupados por município e consórcio. As horas têm intervalo que inclui zero. O sinal negativo da população é condicional às demais variáveis; não estabelece causa. Probabilidades de vários consórcios não precisam somar 100%.</p>
<p>Leitos SUS são zero no recorte clínico de 2019. Serviços e profissionais permanecem na base, mas horas são a medida escolhida para este exercício. RCL é incompleta; bacia foi adiada. População da sede não é capacidade médica. Transações e valores não entram como explicadores do próprio pagamento. Não criamos PCA nem índice composto.</p></div></details>
<h2 class="subsection" id="bin-auditoria">O que já foi conferido e o que segue aberto</h2>
<div class="data-layers"><article><h3>CNES corrigido</h3><p>Dois consultórios de pessoa física foram retirados do CISMARG. As quatro estimativas principais ficaram iguais: as unidades tinham zero horas SUS. Rotas e mapas da v1 foram atualizados.</p></article><article><h3>Credores sob verificação</h3><p>17 pares-ano, R$ 1,35 milhão, têm nomes conflitantes. Dois pertencem a 2019. Todos os 14 objetos de Conselheiro Pena/2019 contradizem a atribuição ao CISVI. A decisão auditada exclui o par como positivo validado, sem transformá-lo em zero. As métricas acima são do ajuste original; a sensibilidade sem os pares conflitantes já foi estimada.</p></article><article><h3>Mesmo município não garante pagamento</h3><p>Nos 57 pares intramunicipais do S1, 52 pagaram (91,23%), mas a previsão média é 99,07%. Esse excesso de confiança continua aberto.</p></article><article><h3>Diferença de Ipatinga explicada</h3><p>Em 2018, o MIDES soma R$ 567.152,67 sem indicador de restos e R$ 137.077,88 com esse indicador: R$ 704.230,55. A primeira parcela confere com o portal. Falta conferir externamente os restos; isso não explica o zero de 2019. Piedade/2021 também confere, sem resolver 2019.</p></article></div>
<p class="note">A coleta posterior no TCE recuperou os 55 pagamentos de São Francisco de Paula/2019: R$ 188.969,82, com datas e valores iguais ao MIDES. Trinta objetos citam o CISMARG; os outros descrevem transporte ou atendimento em saúde. O vínculo financeiro tem suporte nos objetos, embora o nome SOMETAL continue conflitante. Em Neves/2014, os dois objetos descrevem monitoramento do prédio da Câmara: os R$ 321,16 deixam de ser evidência válida de pagamento ao CISMEP na decisão auditada, sem inventar um zero anual. Ipatinga e Piedade/2019 não têm o credor procurado nos arquivos SICOM dos 12 meses; a causa permanece aberta. Os arquivos podem compartilhar origem com MIDES e não substituem comprovantes bancários. As estimativas acima permanecem as originais.</p>
<details class="trace"><summary>O que perdemos ao restringir as alternativas?</summary><div><p>Denominador: 771 relações pagas do S1, R$ 360,34 milhões. Nenhuma regra territorial foi adotada como definitiva.</p>'''
    names={'ate120min':'Até 120 minutos','ate180min':'Até 180 minutos','mesma_micro':'Mesma microrregião de saúde','cinco_proximos':'Cinco mais próximos (com empates)'}
    body+=table(['Regra','Pagos excluídos','Valor excluído','Municípios sem opção'],[[names[r['regra']],fmt(r['positivos_excluidos']),'R$ '+fmt(r['valor_excluido'],2),fmt(r['sem_candidato'])] for r in territory if r['modelo']=='clinicas53' and r['regra'] in names])
    body+='''</div></details><p class="scope-note">Este é um exercício exploratório de MG em 2019. Horas cadastradas em dezembro podem diferir da oferta durante o ano. Destinos não comprovam acesso institucional; cadastro não mede produção. As métricas não demonstram efeito causal nem validam cada vínculo individual.</p>
<details class="trace"><summary>Fontes, documentos e reprodução</summary><div><p>MIDES/Base dos Dados, população IBGE, CNES/DATASUS e Distbrasil. Scripts 31/32 estimam; 33–36 auditam. Esta apresentação lê os resultados já salvos, sem reestimar.</p><p><a href="https://www.uberaba.mg.gov.br/portal/acervo/portal_transparencia/arquivos/2019/prestacao%20contas/Relatorio%20do%20Controle%20Interno.pdf" target="_blank" rel="noreferrer">Uberaba: relatório de controle interno, p. 80</a>. O zero documentado se refere ao rateio; não demonstra saída de todos os instrumentos.</p><p><a href="https://github.com/driano1221/consorcios-mg-dados-territorio/tree/master/analises/modelo_gravitacional_saude/evidencias" target="_blank" rel="noreferrer">Catálogo de evidências, fontes e limites</a>. O piloto de participações, abaixo, responde a outra pergunta e conserva sua documentação própria.</p></div></details></div>'''
    assert abs(1/(1+math.exp(-eta))-.9594)<.001
    return body, products
