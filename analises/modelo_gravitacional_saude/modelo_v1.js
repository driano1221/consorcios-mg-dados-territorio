// Resultados precomputados pelo script 30; o navegador so consulta e explica.
const M=D.model;
const modelNumber=n=>n>0&&n<.0001?n.toExponential(3).replace('.',','):fmt(n,6);
const shareText=n=>n>0&&n<.0001?'<0,01%':fmt(n*100,2)+'%';
const modelNames={uniforme:'Parcelas iguais',frequencia_treino:'Participações médias no treino',
 tempo:'Somente tempo',profissionais_tempo:'Profissionais + tempo',horas_tempo:'Horas + tempo',
 profissionais_mediana:'Profissionais + tempo mediano'};
const entityMap=new Map(M.consorcios.map(r=>[r.cnpj_raiz_8,r]));
const selectionNames={financeira_e_gravitacional:'No piloto direto',
 somente_financeira_sem_polo_direto:'Somente na financeira',
 fora_escopo_nucleo_saude:'Fora do núcleo de saúde',fora_antes_abertura:'Antes da abertura'};
const scopeNames={saude_prioritaria:'Saúde prioritária',saude_candidata_documental:'Saúde, revisão externa',
 multiarea_sensibilidade:'Multiárea',fora_nucleo_preliminar:'Fora do núcleo preliminar'};
const coefMain=M.coeficientes.filter(r=>r.modelo==='profissionais_tempo');
const mainBeta=Object.fromEntries(coefMain.map(r=>[r.termo,r.coeficiente]));
const metric=(scheme,model)=>M.validacao.find(r=>r.validacao===scheme&&r.modelo===model);
const metricMain=metric('municipios','profissionais_tempo'),metricTime=metric('municipios','tempo');
$('model-numbers').innerHTML=[['703','municípios com total direto positivo'],['54','consórcios como alternativas'],
 ['37.962','linhas na base de estimação'],[fmt(M.resumo.valor_direto/M.resumo.valor_financeiro*100,2)+'%','do valor financeiro de 2019 no recorte direto']]
 .map(([v,l])=>'<div><strong>'+v+'</strong><span>'+l+'</span></div>').join('');
$('model-reading').innerHTML='<strong>O tempo explica boa parte do padrão espacial; a capacidade acrescenta um ganho pequeno neste teste.</strong><p>Fora da estimação, profissionais + tempo identificam o principal recebedor em '+fmt(metricMain.acerto_principal_pct,1)+'% dos municípios, contra '+fmt(metricTime.acerto_principal_pct,1)+'% com tempo sozinho. O erro médio da distribuição passa de '+fmt(metricTime.distancia_total_pct,1)+'% para '+fmt(metricMain.distancia_total_pct,1)+'%. Isso ainda deixa diferenças relevantes nas parcelas previstas.</p>';
const variables=[
 {dado:'Município, consórcio e ano',antes:'id_municipio · cnpj_raiz_8 · ano',depois:'Chave da linha; seleção de 2019',papel:'Identificação. Nomes e códigos não viram explicativas.'},
 {dado:'Pagamento anual',antes:'valor_total, em reais',depois:'Preservado; somado nos 54 destinos por município',papel:'Origina a resposta. Não entra como explicativa.'},
 {dado:'Total direto',antes:'Não era uma coluna da v1',depois:'total_direto = soma dos valores do município no recorte',papel:'Campo criado. Municípios com total zero ficam fora da estimação.'},
 {dado:'Participação observada',antes:'Valor em reais',depois:'participacao = valor_total / total_direto',papel:'Resposta criada, entre 0 e 1. Soma 1 por município.'},
 {dado:'Profissionais SUS',antes:'profissionais_sus_clinicos_soma_unidades',depois:'log_profissionais = ln(1 + profissionais)',papel:'Atração. O +1 permite tratar o zero cadastral; não o corrige.'},
 {dado:'Menor tempo',antes:'tempo_minimo_min, em minutos',depois:'tempo_horas = minutos / 60; sinal negativo na pontuação',papel:'Impedância. Tempo zero é mantido. Sem corte máximo.'},
 {dado:'Elegibilidade e alertas',antes:'elegivel_gravitacional_v1 · classificacao_oferta · alerta_temporal',depois:'Elegibilidade seleciona; modalidade e alertas são conservados',papel:'Definem e qualificam o recorte, sem coeficiente na fórmula.'},
 {dado:'Grupos de validação',antes:'Não existiam',depois:'fold e bloco_espacial, cinco grupos cada',papel:'Campos criados para separar estimação e teste. Semente fixa.'},
 {dado:'Pontuação e previsões',antes:'Não existiam',depois:'utilidade · previsto_ajuste · previsto_validacao · previsto_espacial',papel:'Resultados criados. Ajuste usa todos; validação exclui o grupo da origem.'}
];
$('model-variables').innerHTML=table(variables,[['dado','Informação'],['antes','Como chega'],['depois','O que fazemos'],['papel','Para que serve']]);
const unused=[
 ['Leitos SUS','Zero nos 54 consórcios em 2019. Não há variação para estimar atração. As unidades do recorte são predominantemente ambulatoriais.'],
 ['Serviços SUS','Onze consórcios têm zero cadastral. Contam tipos de oferta, não volume; especialidades diferentes não são automaticamente comparáveis. Permanecem na base para análise.'],
 ['Horas SUS','Entram em uma sensibilidade separada, substituindo profissionais. Usar as duas medidas juntas não é necessário neste piloto e dificultaria a interpretação.'],
 ['Número de clínicas e municípios de destino','Descrevem a rede, mas tratam unidades de portes distintos como equivalentes. Usados para contextualizar a capacidade, não como massa principal.'],
 ['Tempo mediano, máximo e distância em km','A mediana entra como sensibilidade. Não acumulamos medidas muito relacionadas na mesma fórmula. A distância disponível vai ao destino de menor tempo, não necessariamente ao de menor quilometragem.'],
 ['População da origem e valor por habitante','População é igual entre os 54 destinos de cada município: com coeficiente comum, cancela na normalização. Dividir todos os pagamentos pela mesma população também não muda suas participações.'],
 ['População da sede do consórcio','Mede porte urbano, não capacidade clínica. A sede cadastral atual foi pareada à população de 2019, mas sua localização histórica não foi comprovada.'],
 ['RCL, bacia e mandato','RCL é incompleta e seletiva; bacia foi reservada para depois. Não são exigências deste piloto. Variáveis apenas da origem exigiriam outro papel, como interação, para alterar a divisão entre destinos.'],
 ['Quantidade de transações e indicadores de pagamento','São úteis na auditoria. Usá-los para explicar a própria participação financeira traria informação do resultado para a fórmula. Transações não são pacientes nem tentativas independentes.'],
 ['Entrada, permanência e saída financeira','São variáveis longitudinais. Este exercício descreve a distribuição em um ano, sem estimar adesão ou sobrevivência.'],
 ['Contratos, MUNIC e CNM','Continuam como evidência documental. Não foram usados para montar automaticamente uma lista anual de alternativas acessíveis. Não equivalem ao desfecho financeiro.'],
 ['PCA ou índice composto','Não foi criado. Mantivemos uma medida interpretável e comparamos outra separadamente, sem combinar escalas e modalidades distintas.'],
 ['Efeitos fixos por consórcio','Em um único ano, absorveriam a capacidade, que é constante dentro do consórcio. Impediriam identificar separadamente o coeficiente da massa escolhido aqui.']
];
$('model-unused').innerHTML=unused.map(([name,reason])=>'<div class="variable"><b>'+name+'</b><p>'+reason+'</p></div>').join('');
function drawSelection(){
 const choice=$('model-selection').value,rows=M.selecao.filter(r=>choice==='all'||r.destino_v1===choice).sort((a,b)=>a.entidade.localeCompare(b.entidade,'pt-BR'));
 $('model-selection-count').textContent=rows.length+' entidades. O nome e a classificação são os mesmos do registro de inclusão da v1.';
 $('model-selection-table').innerHTML=table(rows,[['entidade','Entidade'],['cnpj_raiz_8','Raiz CNPJ'],['ano_abertura','Abertura'],
  ['grupo_escopo','Escopo',v=>scopeNames[v]||v],['destino_v1','Situação',v=>selectionNames[v]],['classificacao_oferta','Oferta registrada',v=>v.replaceAll('_',' ')]]);
}
$('model-selection').addEventListener('change',drawSelection);drawSelection();
function drawModelMetrics(){
 const scheme=$('model-validation').value,rows=M.validacao.filter(r=>r.validacao===scheme);
 const primary=rows.filter(r=>['uniforme','frequencia_treino','tempo','profissionais_tempo'].includes(r.modelo));
 let body='';const w=900,l=245,r=80,h=240,available=w-l-r;
 for(let t=0;t<=100;t+=25){const x=l+t/100*available;body+=`<line x1="${x}" x2="${x}" y1="20" y2="194" stroke="#DCE3E7"/>`+txt(x,217,t+'%','text-anchor="middle" font-size="12"');}
 primary.forEach((row,i)=>{const y=35+i*45,width=available*row.distancia_total_pct/100,col=row.modelo==='profissionais_tempo'?blue:row.modelo==='tempo'?ink:'#B8C5CC';
  body+=txt(l-16,y+6,modelNames[row.modelo],'text-anchor="end" font-size="14"')+`<rect x="${l}" y="${y-10}" width="${width}" height="23" fill="${col}"/>`+txt(l+width+9,y+6,fmt(row.distancia_total_pct,1)+'%','font-size="14" font-weight="700"');});
 $('model-metrics-chart').innerHTML=svg(w,h,body,'Erro médio da distribuição fora da estimação; menor é melhor');
 $('model-metrics-table').innerHTML=table(primary,[['modelo','Modelo',v=>modelNames[v]],['distancia_total_pct','Erro da distribuição',v=>fmt(v,2)+'%'],
  ['entropia','Perda logarítmica ↓',v=>fmt(v,4)],['acerto_principal_pct','Principal recebedor correto',v=>v===null?'Não define um principal':fmt(v,2)+'%']]);
 const p=metric(scheme,'profissionais_tempo'),t=metric(scheme,'tempo');
 $('model-spatial-note').textContent=(scheme==='espacial'?'Na validação geográfica, o município e seu grupo espacial inteiro ficam fora da estimação. ':'Na validação sorteada, o município fica fora da estimação, mas vizinhos podem permanecer no treino. ')+
  'Acrescentar profissionais reduz a perda logarítmica em '+fmt(100*(t.entropia-p.entropia)/t.entropia,2)+'% e o erro de distribuição em '+fmt(t.distancia_total_pct-p.distancia_total_pct,2)+' ponto percentual. A referência de participações médias usa apenas o treino, com suavização uniforme fixa.';
 $('model-sensitivity').innerHTML=table(rows.filter(r=>!['uniforme','frequencia_treino'].includes(r.modelo)),[['modelo','Sensibilidade nesta validação',v=>modelNames[v]],['entropia','Perda logarítmica ↓',v=>fmt(v,4)],['distancia_total_pct','Erro da distribuição',v=>fmt(v,2)+'%']]);
}
$('model-validation').addEventListener('change',drawModelMetrics);drawModelMetrics();
$('model-coefficients').innerHTML=table(M.coeficientes,[['modelo','Especificação',v=>modelNames[v]],['termo','Coeficiente',v=>v==='tempo'?'βT, tempo subtraído':'βA, atração'],['coeficiente','Estimativa',v=>fmt(v,4)]]);
const foldMain=M.coeficientes_validacao.filter(r=>r.modelo==='profissionais_tempo'&&r.validacao==='municipios');
$('model-coeff-range').textContent='Nos cinco treinos sorteados, βA variou de '+fmt(Math.min(...foldMain.filter(r=>r.termo==='capacidade').map(r=>r.coeficiente)),4)+' a '+fmt(Math.max(...foldMain.filter(r=>r.termo==='capacidade').map(r=>r.coeficiente)),4)+'. Os cinco grupos geográficos são formados por k-means das coordenadas, sem usar pagamentos.';
$('model-municipality').innerHTML=M.municipios.slice().sort((a,b)=>a.municipio.localeCompare(b.municipio,'pt-BR')).map(r=>'<option value="'+r.id_municipio+'">'+esc(r.municipio)+'</option>').join('');
$('model-municipality').value='3117603';
$('model-calc-entity').innerHTML=M.consorcios.slice().sort((a,b)=>a.entidade.localeCompare(b.entidade,'pt-BR')).map(r=>'<option value="'+r.cnpj_raiz_8+'">'+esc(r.entidade)+'</option>').join('');
$('model-calc-entity').value='05802877';
function currentModel(){
 const id=$('model-municipality').value,mode=$('model-prediction').value,mun=M.municipios.find(r=>r.id_municipio===id);
 const rows=M.linhas[id].map(values=>Object.fromEntries(M.colunas.map((k,i)=>[k,values[i]])));
 rows.forEach(r=>{r.entidade=entityMap.get(r.raiz).entidade;r.previsto=r[mode];r.valor_implicito=r.previsto*mun.total_direto;});
 const betas=mode==='ajuste'?mainBeta:Object.fromEntries(M.coeficientes_validacao.filter(r=>r.modelo==='profissionais_tempo'&&r.validacao===(mode==='validacao'?'municipios':'espacial')&&r.fold===(mode==='validacao'?mun.fold:mun.bloco_espacial)).map(r=>[r.termo,r.coeficiente]));
 return {mun,mode,rows,betas};
}
function drawExample(){
 const {mun,mode,rows}=currentModel();
 const sorted=rows.slice().sort((a,b)=>Math.max(b.observado,b.previsto)-Math.max(a.observado,a.previsto));
 const top=sorted.slice(0,7),rest=sorted.slice(7);
 top.push({entidade:'Outros '+rest.length+' consórcios',observado:rest.reduce((s,r)=>s+r.observado,0),previsto:rest.reduce((s,r)=>s+r.previsto,0)});
 const outside=mun.total_financeiro-mun.total_direto,error=50*rows.reduce((s,r)=>s+Math.abs(r.observado-r.previsto),0);
 $('model-example-summary').textContent=mun.municipio+' · 2019: '+cash(mun.total_direto)+' em '+mun.n_pagos+' consórcio'+(mun.n_pagos>1?'s':'')+' direto'+(mun.n_pagos>1?'s':'')+'. '+cash(outside)+' fora do recorte direto, preservados na financeira. '+(mode==='ajuste'?'O ajuste abaixo usou este município.':'Este município não participou da estimação que gerou a previsão abaixo.');
 const w=950,l=270,r=55,h=top.length*45+65,available=w-l-r;
 let body='';
 for(let t=0;t<=100;t+=25){const x=l+t/100*available;body+=`<line x1="${x}" x2="${x}" y1="20" y2="${h-35}" stroke="#E2E7EB"/>`+txt(x,h-12,t+'%','text-anchor="middle" font-size="12"');}
 top.forEach((row,i)=>{const y=35+i*45,a=l+available*row.observado,b=l+available*row.previsto,label=row.entidade.length>31?row.entidade.slice(0,29)+'…':row.entidade;
  body+=txt(l-15,y+5,label,'text-anchor="end" font-size="13"')+`<line x1="${a}" x2="${b}" y1="${y}" y2="${y}" stroke="#A9B6BF" stroke-width="2"/><circle cx="${a}" cy="${y}" r="5" fill="${blue}"><title>Observado: ${fmt(row.observado*100,2)}%</title></circle><rect x="${b-4}" y="${y-4}" width="8" height="8" fill="${red}"><title>Previsto: ${fmt(row.previsto*100,2)}%</title></rect>`;
  body+=txt(l,y+20,'Obs. '+fmt(row.observado*100,2)+'% · Prev. '+fmt(row.previsto*100,2)+'%','font-size="11"');
 });
 $('model-example-chart').innerHTML=svg(w,h,body,'Participações observadas e previstas em '+mun.municipio);
 const observed=rows.reduce((a,b)=>b.observado>a.observado?b:a),predicted=rows.reduce((a,b)=>b.previsto>a.previsto?b:a);
 $('model-example-reading').textContent='O maior observado é '+observed.entidade+' ('+fmt(observed.observado*100,2)+'%). A maior previsão é para '+predicted.entidade+' ('+fmt(predicted.previsto*100,2)+'%). O erro da distribuição neste município é '+fmt(error,2)+'%. O gráfico mostra sete destinos de maior parcela observada ou prevista e agrega o restante; a tabela abaixo preserva todos.';
 $('model-example-table').innerHTML=table(rows.slice().sort((a,b)=>b.observado-a.observado||b.previsto-a.previsto),[['entidade','Consórcio'],['valor','Pagamento observado',cash],['profissionais','Profissionais',v=>fmt(v)],['tempo','Minutos',v=>fmt(v,1)],['observado','Parcela observada',shareText],['previsto','Parcela prevista',shareText],['valor_implicito','Parcela × total observado',cash]]);
 drawCalculation();
}
function drawCalculation(){
 const {mun,mode,rows,betas}=currentModel(),row=rows.find(r=>r.raiz===$('model-calc-entity').value);
 const v=betas.capacidade*Math.log1p(row.profissionais)-betas.tempo*row.tempo/60;
 const denominator=rows.reduce((s,r)=>s+Math.exp(betas.capacidade*Math.log1p(r.profissionais)-betas.tempo*r.tempo/60),0);
 const steps=[['Dados de '+row.entidade,fmt(row.profissionais)+' profissionais SUS e '+fmt(row.tempo,1)+' min a partir de '+mun.municipio+'. Parcela observada: '+fmt(row.observado*100,2)+'%.'],
  ['Transformações','ln(1 + '+fmt(row.profissionais)+') = '+fmt(Math.log1p(row.profissionais),4)+'; '+fmt(row.tempo,1)+' / 60 = '+fmt(row.tempo/60,4)+' hora(s).'],
  ['Pontuação e peso',fmt(betas.capacidade,4)+' × '+fmt(Math.log1p(row.profissionais),4)+' − '+fmt(betas.tempo,4)+' × '+fmt(row.tempo/60,4)+' = '+fmt(v,4)+'. exp(V) = '+modelNumber(Math.exp(v))+'.'],
  ['Normalização','Soma dos 54 pesos = '+modelNumber(denominator)+'. Peso / soma = '+shareText(Math.exp(v)/denominator)+'. Essa parcela corresponde a '+cash(row.valor_implicito)+' do total direto observado.']];
 $('model-calculation').innerHTML=steps.map(([title,body])=>'<article><h3>'+esc(title)+'</h3><p>'+esc(body)+'</p></article>').join('');
 $('model-coefficient-reading').textContent='Esta conta usa os coeficientes da previsão selecionada ('+(mode==='ajuste'?'ajuste completo':mode==='validacao'?'treino sem o grupo municipal':'treino sem o grupo geográfico')+'). Se somente esse destino tivesse mais 30 minutos, seu peso relativo seria multiplicado por '+fmt(Math.exp(-betas.tempo*.5),3)+'. A participação precisaria ser renormalizada com os outros destinos; não cai na mesma proporção do peso. Valores exibidos são arredondados; o cálculo usa precisão completa.';
}
['model-municipality','model-prediction'].forEach(id=>$(id).addEventListener('change',drawExample));
$('model-calc-entity').addEventListener('change',drawCalculation);drawExample();
$('model-alert-note').textContent=M.resumo.alertas+' consórcios têm alerta temporal, envolvendo '+M.resumo.pares_pagos_alerta+' relações pagas. Esses alertas não são imputações nem prova de erro.';
$('model-next').textContent='O piloto sustenta continuar a investigação com tempo e capacidade, mas o ganho da capacidade é modesto e a disponibilidade institucional continua aberta. O próximo avanço deve testar uma regra documental de alternativas e a capacidade anterior ao pagamento. Horas e tempo mediano tiveram resultados próximos; não foram promovidos automaticamente a modelo final. Não é necessário refazer a coleta inteira para discutir estes resultados.';
// Links internos mantêm a nova aba aberta ao compartilhar/recarregar a consulta.
if(location.hash.startsWith('#modelo'))switchPage('modelo');
document.querySelector('nav button[data-page="modelo"]').addEventListener('click',()=>history.replaceState(null,'','#modelo'));
document.querySelectorAll('nav button:not([data-page="modelo"])').forEach(b=>b.addEventListener('click',()=>history.replaceState(null,'',location.pathname)));
