'use strict';
const D=JSON.parse(document.getElementById('data').textContent),$=id=>document.getElementById(id);
const blue='#2980B9',ink='#1A252F',grey='#7F8C8D',red='#C0392B';
const fmt=(n,d=0)=>n===null||n===undefined?'Não disponível':Number(n).toLocaleString('pt-BR',{minimumFractionDigits:d,maximumFractionDigits:d});
const cash=n=>'R$ '+fmt(n,2),million=n=>'R$ '+fmt(n/1e6,2)+' mi';
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const flabel={destino_clinico_fixo:'Clínica fixa',unidade_movel:'Unidade móvel',estrutura_fixa_nao_clinica:'Estrutura não clínica'};
const txt=(x,y,s,opts='')=>`<text x="${x}" y="${y}" ${opts}>${esc(s)}</text>`;
const svg=(w,h,s,title)=>`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" role="img" aria-label="${esc(title)}"><title>${esc(title)}</title>${s}</svg>`;
const table=(rows,cols)=>`<table><thead><tr>${cols.map(c=>`<th scope="col">${esc(c[1])}</th>`).join('')}</tr></thead><tbody>${rows.map(r=>`<tr>${cols.map(c=>`<td>${esc(c[2]?c[2](r[c[0]]):r[c[0]])}</td>`).join('')}</tr>`).join('')||`<tr><td colspan="${cols.length}">Nenhum registro neste recorte.</td></tr>`}</tbody></table>`;
function lineChart(rows,key,title,{money=true,selected=null,colour=blue}={}){
 const w=760,h=260,l=66,r=48,t=33,b=44,ys=Array.from({length:8},(_,i)=>2014+i),max=Math.max(1,...rows.map(x=>Number(x[key])||0))*1.22;
 const x=y=>l+(y-2014)*(w-l-r)/7,y=v=>h-b-v/max*(h-b-t),values=new Map(rows.map(r=>[+r.ano,r]));let body='';
 for(let i=0;i<=4;i++){const v=max*i/4;body+=`<line x1="${l}" y1="${y(v)}" x2="${w-r}" y2="${y(v)}" stroke="#E1E7EB"/>`+txt(l-10,y(v)+4,fmt(money?v/1e6:v,money?1:0),'text-anchor="end" font-size="13"');}
 let path='';ys.forEach(yr=>{body+=txt(x(yr),h-16,yr,'text-anchor="middle" font-size="13"');const row=values.get(yr);if(!row){path+=' ';return;}path+=(values.has(yr-1)&&yr!==2014?'L':'M')+x(yr)+','+y(row[key]);});
 body+=`<path d="${path}" fill="none" stroke="${colour}" stroke-width="2.6"/>`;
 rows.forEach(row=>{const v=Number(row[key]),yr=+row.ano;body+=`<circle cx="${x(yr)}" cy="${y(v)}" r="${yr===selected?6:3}" fill="${colour}"><title>${yr}: ${money?cash(v):fmt(v)}</title></circle>`;if(rows.length<2||yr===2014||yr===2021||yr===selected)body+=txt(x(yr),y(v)-14,money?fmt(v/1e6,1):fmt(v),'text-anchor="middle" font-size="13" font-weight="700"');});
 body+=txt(l,14,money?'R$ milhões nominais':'Municípios pagadores','font-size="12"');return svg(w,h,body,title);
}

document.querySelectorAll('[data-figure]').forEach(box=>{
 const c=D.catalog.find(x=>x.id===box.dataset.figure);box.classList.add('figure-block');
 box.innerHTML='<figure><a href="figuras/'+c.id+'.svg" target="_blank" aria-label="Ampliar: '+esc(c.titulo)+'"><img src="figuras/'+c.id+'.svg" alt="'+esc(c.titulo)+ '" loading="lazy"></a><figcaption>'+esc(c.leitura)+'</figcaption></figure>';
});
const fieldLabels={id_municipio:'Código do município',municipio:'Município',cnpj_raiz_8:'Raiz do CNPJ',entidade:'Consórcio',ano:'Ano',populacao_ibge:'População',valor_total:'Pagamento (R$)',n_transacoes:'Registros MIDES',ano_abertura:'Ano de abertura',origem_universo:'Origem no cadastro',grupo_escopo:'Escopo',tem_registro_mides:'Há registro MIDES',presente_mides:'Pagamento positivo',valor_por_habitante:'R$ por habitante',evento_movimento:'Movimento financeiro',polo_direto_identificado:'Polo direto (0/1)',elegivel_gravitacional_v1:'Entra na tabela direta',classificacao_oferta:'Classificação da oferta',alerta_temporal:'Alerta temporal',n_destinos_clinicos_dezembro:'Unidades clínicas',n_municipios_clinicos_dezembro:'Municípios com clínica',servicos_sus_clinicos_soma_unidades:'Serviços SUS',profissionais_sus_clinicos_soma_unidades:'Profissionais SUS',horas_sus_clinicas_soma_registros:'Horas SUS',leitos_sus_clinicos:'Leitos SUS',tempo_minimo_min:'Menor tempo (min)',tempo_mediano_min:'Tempo mediano (min)',tempo_maximo_min:'Maior tempo (min)',distancia_minima_km:'Km até o destino de menor tempo',destino_clinico_mais_proximo_id:'Código do destino de menor tempo'};
function valueText(v,key){if(v===null||v===undefined)return 'Não disponível';if(key==='ano'||key==='ano_abertura')return String(v);if(typeof v==='boolean')return v?'Sim':'Não';if(typeof v==='number')return fmt(v,['valor_total','valor_por_habitante','distancia_minima_km'].includes(key)?2:key.startsWith('tempo_')?1:0);return v;}
const dict=D.overview.variables.map(v=>'<div class="variable"><b>'+esc(fieldLabels[v.variavel]||v.variavel)+'</b><code>'+esc(v.variavel)+'</code><p>'+esc(v.definicao)+'</p><small>'+ (v.tabela==='ambas'?'Nas duas tabelas':'Somente na direta')+'</small></div>').join('');
$('variable-list').innerHTML=dict;$('query-dictionary').innerHTML=dict;
$('base-stats').innerHTML=D.overview.stats.map(s=>'<article><h3>'+ (s.base==='financeira'?'Financeira':'Direta, com CNES e tempo')+'</h3><strong class="base-size">'+fmt(s.linhas)+' <small>linhas</small></strong><p>'+s.colunas+' variáveis · '+s.consorcios+' consórcios · '+s.municipios+' municípios</p><dl><div><dt>Linhas com pagamento</dt><dd>'+fmt(s.pagas)+'</dd></div><div><dt>Sem pagamento positivo</dt><dd>'+fmt(s.zeros)+' ('+fmt(s.zeros/s.linhas*100,2)+'%)</dd></div><div><dt>Valor no período</dt><dd>'+cash(s.valor)+'</dd></div><div><dt>Combinações de consórcio e ano</dt><dd>'+fmt(s.entidades_ano)+'</dd></div></dl></article>').join('');
$('null-summary').textContent='As duas tabelas têm 0% de células nulas nos arquivos da v1. Isso descreve as colunas e os recortes escolhidos, não toda a oferta assistencial existente.';
function drawPreview(){
 const kind=$('preview-base').value,mode=$('preview-mode').value,rows=D.overview.previews[kind][mode];
 const keys=['municipio','entidade','ano','populacao_ibge','valor_total','n_transacoes',...(kind==='direta'?['n_destinos_clinicos_dezembro','profissionais_sus_clinicos_soma_unidades','tempo_minimo_min']:['polo_direto_identificado'])];
 $('base-preview').innerHTML=table(rows,keys.map(k=>[k,fieldLabels[k],v=>valueText(v,k)]));
 $('preview-reading').textContent=mode==='head'?'Estas são as cinco primeiras linhas, na ordem do arquivo. Elas pertencem à grade mesmo sem pagamento. Zero em pagamento não significa que o município realizou uma transação de valor zero.':'Igarapé–CISMEP/2019 é uma relação com pagamento. A linha seguinte mostra o mesmo consórcio e ano em outro município, sem pagamento positivo. Na tabela direta, a capacidade do consórcio se repete; o tempo varia com a origem.';
}
['preview-base','preview-mode'].forEach(id=>$(id).onchange=drawPreview);drawPreview();
const example=D.overview.case[0];
$('case-walkthrough').innerHTML=[['MIDES',cash(example.valor_total)+' em '+fmt(example.n_transacoes)+' registros, reunidos numa relação anual.'],['IBGE',fmt(example.populacao_ibge)+' habitantes em Igarapé; '+cash(example.valor_por_habitante)+' por habitante.'],['CNES',example.n_destinos_clinicos_dezembro+' clínicas do CISMEP; '+example.profissionais_sus_clinicos_soma_unidades+' profissionais e '+example.servicos_sus_clinicos_soma_unidades+' serviços/classificações SUS.'],['Rotas',fmt(example.tempo_minimo_min,1)+' minutos até o município clínico de menor tempo.']].map(([a,b])=>'<article><h3>'+a+'</h3><p>'+b+'</p></article>').join('');
const ts=D.times[0];$('time-numbers').innerHTML=[[fmt(ts.n),'relações pagas'],[fmt(ts.mediana,2)+' min','metade das relações até esse tempo'],[fmt(ts.p90,1)+' min','90% das relações até esse tempo'],[fmt(ts.intramunicipais),'origem e destino no mesmo município']].map(([n,l])=>'<div><strong>'+n+'</strong><span>'+l+'</span></div>').join('');
for(let yr=2014;yr<=2021;yr++)$('rank-year').insertAdjacentHTML('beforeend',`<option value="${yr}">${yr}</option>`);
const financialEntities=[...new Map(D.entity_year.map(r=>[r.cnpj_raiz_8,r.entidade])).entries()].sort((a,b)=>a[1].localeCompare(b[1],'pt-BR'));
$('pay-entity').innerHTML=financialEntities.map(([r,n])=>`<option value="${r}">${esc(n)} · ${r}</option>`).join('');$('pay-entity').value='05802877';
let rankingRows=[],payRows=[];
function drawPayments(){
 const period=$('rank-year').value;rankingRows=D.ranking.filter(r=>r.periodo===period);const top=rankingRows.filter(r=>r.valor>0).slice(0,15),w=760,h=top.length*35+64,l=225,r=115,max=Math.max(1,...top.map(r=>r.valor));let body='';
 top.forEach((row,i)=>{const y=i*35+22,width=(w-l-r)*row.valor/max,label=row.entidade.length>28?row.entidade.slice(0,26)+'…':row.entidade;body+=txt(l-12,y+5,label,'text-anchor="end" font-size="13"')+`<rect x="${l}" y="${y-9}" width="${width}" height="20" fill="${blue}"><title>${esc(row.entidade)}: ${cash(row.valor)}</title></rect>`+txt(l+width+9,y+5,fmt(row.valor/1e6,2)+' mi','font-size="13"');});
 body+=txt(l,h-6,'R$ milhões nominais; 15 maiores no período','font-size="12"');$('rank-chart').innerHTML=svg(w,h,body,'Os 15 maiores pagamentos em '+period);
 $('rank-title').textContent='Maiores pagamentos em '+period;$('rank-info').textContent=`Os 15 primeiros somam ${fmt(top.reduce((s,r)=>s+r.participacao,0)*100,1)}% do valor. ${rankingRows.filter(r=>r.valor>0).length} consórcios receberam no período.`;
 payRows=D.entity_year.filter(r=>r.cnpj_raiz_8===$('pay-entity').value);$('pay-title').textContent=payRows[0]?.entidade||'Consórcio';
 $('pay-chart').innerHTML=lineChart(payRows,'valor','Pagamentos anuais de '+$('pay-title').textContent);$('payer-chart').innerHTML=lineChart(payRows,'pagadores','Municípios pagadores de '+$('pay-title').textContent,{money:false,colour:grey});
}
['rank-year','pay-entity'].forEach(id=>$(id).addEventListener('change',drawPayments));


drawPayments();
let year='2019',root='05802877',extent='regional',selectedCode='',selectedUnits=[],atlasPaid=[],allUnits=[],currentEntity;
$('atlas-entity').innerHTML=D.entities.slice().sort((a,b)=>a.rotulo.localeCompare(b.rotulo,'pt-BR')).map(e=>'<option value="'+e.raiz+'">'+esc(e.rotulo)+' · '+e.raiz+'</option>').join('');$('atlas-entity').value=root;
const municipalityOptions=D.polys.slice().sort((a,b)=>a.name.localeCompare(b.name,'pt-BR')).map(p=>'<option value="'+p.code+'">'+esc(p.name)+'</option>').join('');
$('map-municipality').insertAdjacentHTML('beforeend',municipalityOptions);
function syncYears(){const selected=$('atlas-year').value||year;const ys=D.entity_year.filter(r=>r.cnpj_raiz_8===$('atlas-entity').value).map(r=>String(r.ano)).sort();$('atlas-year').innerHTML=ys.map(y=>'<option value="'+y+'">'+y+'</option>').join('');$('atlas-year').value=ys.includes(selected)?selected:ys[0];}
syncYears();
function getBounds(polys){if(!polys.length)return allBounds;let a=Infinity,b=Infinity,c=-Infinity,d=-Infinity;for(const p of polys)for(const ring of p.rings)for(const [x,y] of ring){a=Math.min(a,x);b=Math.min(b,y);c=Math.max(c,x);d=Math.max(d,y);}return[a,b,c,d];}
const allBounds=getBounds(D.polys);
function projection(bounds,w,h,pad=32){const[a,b,c,d]=bounds,scale=Math.min((w-2*pad)/Math.max(1,c-a),(h-2*pad)/Math.max(1,d-b));return{x:v=>(v-(a+c)/2)*scale+w/2,y:v=>h/2-(v-(b+d)/2)*scale,scale};}
function shape(p,pr){return p.rings.map(r=>r.map((q,i)=>(i?'L':'M')+pr.x(q[0]).toFixed(1)+','+pr.y(q[1]).toFixed(1)).join('')+'Z').join('');}
function mapMarkup(){
 const mobile=innerWidth<=720,w=mobile?Math.max(320,innerWidth-55):850,h=mobile?360:510;
 const payMap=new Map(atlasPaid.map(r=>[r.codigo_ibge_6,r]));
 const relevant=D.polys.filter(p=>(payMap.has(p.code)&&$('layer-paid').checked)||selectedUnits.some(u=>u.codigo_ibge_6===p.code));
 const pr=projection(extent==='state'||!relevant.length?allBounds:getBounds(relevant),w,h,mobile?18:35);
 let b=`<defs><clipPath id="map-clip"><rect width="${w}" height="${h}"/></clipPath></defs><g clip-path="url(#map-clip)">`;
 D.polys.forEach(p=>{const paid=payMap.get(p.code),selected=p.code===selectedCode;
 b+=`<path d="${shape(p,pr)}" fill="${paid&&$('layer-paid').checked?'#9FC8E0':'#F7F9FA'}" stroke="${selected?ink:'#CBD5DB'}" stroke-width="${selected?2:.45}" fill-rule="evenodd" data-code="${p.code}"><title>${esc(p.name)}: ${paid?cash(paid.valor):'sem pagamento positivo observado'}</title></path>`;});
 const groups=[...new Set(selectedUnits.filter(u=>u.x!==null&&u.y!==null).map(u=>u.codigo_ibge_6))].sort();
 if($('layer-units').checked)groups.forEach((code,i)=>{const group=selectedUnits.filter(u=>u.codigo_ibge_6===code),u=group[0],x=pr.x(u.x),y=pr.y(u.y),functions=[...new Set(group.map(u=>u.funcao))],func=functions.length===1?functions[0]:'mista',colour=func==='destino_clinico_fixo'?red:func==='unidade_movel'?blue:grey;
 const hint=esc(`${u.municipio}: ${group.length} unidade(s); ${functions.map(f=>flabel[f]).join(', ')}`);
 if(func==='unidade_movel')b+=`<path d="M${x},${y-10}l10,19h-20Z" fill="${colour}" stroke="white" stroke-width="1.5"><title>${hint}</title></path>`;
 else if(func==='estrutura_fixa_nao_clinica')b+=`<rect x="${x-8}" y="${y-8}" width="16" height="16" fill="${colour}" stroke="white" stroke-width="1.5"><title>${hint}</title></rect>`;
 else b+=`<circle cx="${x}" cy="${y}" r="${Math.min(13,7+Math.sqrt(group.length))}" fill="${colour}" stroke="white" stroke-width="1.7"><title>${hint}</title></circle>`;
 if(groups.length<=12)b+=txt(x,y+3,i+1,'text-anchor="middle" font-size="9" font-weight="700" style="fill:white;pointer-events:none"');
 if(groups.length<=3&&extent==='regional'){const dir=x>w*.6?-1:1,ty=y+(i%2===0?-25:27);b+=`<path d="M${x+8*dir},${y}L${x+24*dir},${ty}h${14*dir}" fill="none" stroke="${ink}"/>`+txt(x+43*dir,ty+4,u.municipio,`text-anchor="${dir<0?'end':'start'}" font-size="13" font-weight="700" style="paint-order:stroke;stroke:#F7F9FA;stroke-width:4;pointer-events:none"`);}
 });b+='</g>';
 if(extent==='regional'&&!mobile){const mini=projection(allBounds,142,105,6);b+='<g transform="translate(12,12)"><rect width="152" height="133" fill="white" fill-opacity=".95"/>';D.polys.forEach(p=>{b+=`<path d="${shape(p,mini)}" fill="${payMap.has(p.code)?blue:'#E1E7EB'}"/>`;});b+=txt(7,122,'Localização em Minas Gerais','font-size="9"')+'</g>';}
 const widthKm=w/pr.scale/1000,scaleKm=[1,2,5,10,25,50,100,200].filter(k=>k<widthKm*.23).pop()||1,scaleWidth=scaleKm*1000*pr.scale;
 b+=`<path d="M26,${h-27}v5h${scaleWidth}v-5" fill="none" stroke="${ink}"/>`+txt(26+scaleWidth/2,h-33,scaleKm+' km','font-size="10" text-anchor="middle"');
 return svg(w,h,b,`${currentEntity.rotulo}, ${year}: ${selectedUnits.length} unidades no filtro`);
}

function showMunicipality(){
 if(!selectedCode){$('map-selection').textContent='Selecione um município no mapa ou na lista para consultar o pagamento.';return;}
 const p=D.polys.find(p=>p.code===selectedCode),r=atlasPaid.find(r=>r.codigo_ibge_6===selectedCode);
 $('map-selection').innerHTML='<strong>'+esc(p.name)+' · '+year+'</strong>'+(r?cash(r.valor)+' em '+fmt(r.n_transacoes)+' registros financeiros.':'Sem pagamento positivo observado a este consórcio no ano.');
}
function drawAtlas(){
 root=$('atlas-entity').value;year=$('atlas-year').value;currentEntity=D.entities.find(e=>e.raiz===root);
 allUnits=D.units.filter(u=>u.cnpj_raiz_8===root&&u.ano===year);atlasPaid=D.payments.filter(p=>p.cnpj_raiz_8===root&&String(p.ano)===year);
 const type=$('atlas-type').value,types=[...new Set(allUnits.map(u=>u.tipo||'Tipo não informado'))].sort();
 $('atlas-type').innerHTML='<option value="all">Todos os tipos</option>'+types.map(t=>'<option value="'+esc(t)+'">'+esc(t)+'</option>').join('');$('atlas-type').value=types.includes(type)?type:'all';
 selectedUnits=allUnits.filter(u=>($('atlas-function').value==='all'||u.funcao===$('atlas-function').value)&&($('atlas-type').value==='all'||(u.tipo||'Tipo não informado')===$('atlas-type').value)).sort((a,b)=>String(a.codigo_ibge_6??'').localeCompare(String(b.codigo_ibge_6??''))||a.cnes.localeCompare(b.cnes));
 const clinical=D.cap_all.find(r=>r.cnpj_raiz_8===root&&r.ano===+year),unlocated=selectedUnits.filter(u=>u.x===null||u.y===null).length;
 const ledger=D.ledger.find(r=>r.cnpj_raiz_8===root&&r.ano===+year);
 $('atlas-name').textContent=currentEntity.rotulo;$('atlas-title-year').textContent=year;$('atlas-description').textContent=currentEntity.nome;
 $('atlas-scope').textContent=clinical?'Tabela financeira e direta':'Somente tabela financeira';
 $('atlas-notice').textContent='Pagamentos e unidades do consórcio no mesmo ano. CNES de dezembro.'+(!clinical?' Não há clínica direta identificada para compor a tabela direta.':'')+(ledger?.alerta_temporal==='TRUE'?' Há alerta de variação cadastral durante o ano.':'')+(unlocated?' '+unlocated+' unidade(s) sem localização.':'');
 $('side-period').textContent='Dados de '+year;
 $('atlas-numbers').innerHTML='<div class="wide"><strong>'+million(atlasPaid.reduce((s,r)=>s+r.valor,0))+'</strong><span>pagamento na v1, em reais nominais</span></div><div><strong>'+atlasPaid.length+'</strong><span>municípios pagadores</span></div><div><strong>'+selectedUnits.length+'</strong><span>unidades selecionadas</span></div>';
 $('capacity-rows').innerHTML=[['Unidades clínicas','unidades'],['Profissionais SUS','profissionais'],['Serviços/classificações SUS','servicos'],['Horas SUS cadastradas','horas']].map(([label,key])=>'<div class="profile-row"><span>'+label+'</span><strong>'+(clinical?fmt(clinical[key]):'Não disponível')+'</strong></div>').join('');
 $('capacity-note').textContent=clinical?'Soma de todas as clínicas diretas do consórcio nesse dezembro, independentemente do filtro do mapa. Pessoas e serviços podem repetir entre unidades.':'Sem clínica direta identificada para agregar capacidade. Isso não significa ausência de atendimento.';
 const codes=[...new Set(selectedUnits.filter(u=>u.x!==null).map(u=>u.codigo_ibge_6))].sort();
 $('unit-list').innerHTML=selectedUnits.map(u=>'<div class="unit"><span class="unit-index">'+(u.x===null?'?':codes.indexOf(u.codigo_ibge_6)+1)+'</span><div><b>'+esc(u.municipio||'Município não localizado')+'</b><small>CNES '+u.cnes+' · '+esc(u.tipo||'Tipo não informado')+'<br>'+esc(flabel[u.funcao]||u.funcao)+'</small></div></div>').join('')||'<p class="small">Nenhuma unidade identificada neste filtro.</p>';
 $('main-map').innerHTML=mapMarkup();$('map-key').textContent='Vermelho: clínica fixa. Triângulo azul: móvel. Quadrado cinza: não clínica. Círculo cinza: funções combinadas.';
 $('map-municipality').value=selectedCode;showMunicipality();$('tip').style.display='none';
 $('main-map').querySelectorAll('[data-code]').forEach(p=>{p.addEventListener('click',()=>{selectedCode=p.dataset.code;drawAtlas();});p.addEventListener('pointermove',e=>{
 const m=D.polys.find(x=>x.code===p.dataset.code),paid=atlasPaid.find(x=>x.codigo_ibge_6===p.dataset.code);
 $('tip').innerHTML='<b>'+esc(m.name)+'</b>'+(paid?cash(paid.valor):'Sem pagamento positivo observado');
 $('tip').style.cssText='display:block;left:'+Math.max(8,Math.min(e.clientX+12,innerWidth-260))+'px;top:'+Math.max(8,Math.min(e.clientY+12,innerHeight-85))+'px';
 });p.addEventListener('pointerleave',()=>{$('tip').style.display='none';});});
}
$('atlas-entity').onchange=()=>{syncYears();drawAtlas();};
['atlas-year','atlas-function','atlas-type','layer-paid','layer-units'].forEach(id=>$(id).onchange=drawAtlas);
['regional','state'].forEach(id=>$(id).onclick=()=>{extent=id;['regional','state'].forEach(i=>$(i).setAttribute('aria-pressed',String(i===id)));drawAtlas();});
$('map-municipality').onchange=()=>{selectedCode=$('map-municipality').value;drawAtlas();};
drawAtlas();

// Consulta completa: dados locais particionados por ano, sem biblioteca externa.
let queryCache=new Map(),pendingChunks=new Map(),queryRows=[],queryColumns=[],queryPage=0;
window.receiveBaseRows=(base,year,payload)=>{
 const key=base+'_'+year,request=pendingChunks.get(key);if(!request)return;
 if(!Array.isArray(payload.columns)||!Array.isArray(payload.rows)){request.reject(new Error('Formato de dados inválido'));return;}
 queryCache.set(key,payload);request.resolve(payload);pendingChunks.delete(key);
};
function loadChunk(base,year){
 const key=base+'_'+year;if(queryCache.has(key))return Promise.resolve(queryCache.get(key));
 return new Promise((resolve,reject)=>{pendingChunks.set(key,{resolve,reject});const script=document.createElement('script');script.src='dados/consulta/'+key+'.js';
 script.onload=()=>{script.remove();if(pendingChunks.has(key)){pendingChunks.delete(key);reject(new Error('Arquivo não retornou os dados'));}};
 script.onerror=()=>{script.remove();pendingChunks.delete(key);reject(new Error('Não foi possível abrir os dados. Mantenha a pasta dados junto do HTML.'));};document.body.append(script);});
}
$('query-year').insertAdjacentHTML('beforeend',Array.from({length:8},(_,i)=>'<option value="'+(2014+i)+'">'+(2014+i)+'</option>').join(''));$('query-year').value='2019';
$('query-entity').insertAdjacentHTML('beforeend',financialEntities.map(([r,n])=>'<option value="'+r+'">'+esc(n)+'</option>').join(''));
$('query-municipality').insertAdjacentHTML('beforeend',municipalityOptions);
function renderQuery(){
 const total=queryRows.length,start=queryPage*25,pageRows=queryRows.slice(start,start+25);
 $('query-table').innerHTML='<table><thead><tr>'+queryColumns.map(k=>'<th scope="col">'+esc(fieldLabels[k]||k)+'<small>'+esc(k)+'</small></th>').join('')+'</tr></thead><tbody>'+pageRows.map(r=>'<tr>'+r.map((v,i)=>'<td>'+esc(valueText(v,queryColumns[i]))+'</td>').join('')+'</tr>').join('')+'</tbody></table>';
 $('query-page').textContent=total?'Linhas '+fmt(start+1)+' a '+fmt(Math.min(start+25,total))+' de '+fmt(total):'Nenhuma linha atende aos filtros.';
 $('query-prev').disabled=queryPage===0;$('query-next').disabled=start+25>=total;$('query-table').scrollTop=0;
}
$('query-prev').onclick=()=>{queryPage--;renderQuery();};$('query-next').onclick=()=>{queryPage++;renderQuery();};
$('query-load').onclick=async()=>{
 const base=$('query-base').value,yr=$('query-year').value,entity=$('query-entity').value,mun=$('query-municipality').value,paid=$('query-paid').value;
 const controls=[...document.querySelectorAll('.query-controls select'),$('query-load')];controls.forEach(e=>e.disabled=true);$('query-status').textContent='Carregando as linhas da base…';
 queryRows=[];queryColumns=[];queryPage=0;renderQuery();
 // Liberar a outra tabela limita a memoria quando o leitor troca de base.
 for(const k of queryCache.keys())if(!k.startsWith(base+'_'))queryCache.delete(k);
 try{
  const years=yr==='all'?Array.from({length:8},(_,i)=>2014+i):[+yr];
  for(const y of years){
   const chunk=await loadChunk(base,y);queryColumns=chunk.columns;
   const ci=queryColumns.indexOf('cnpj_raiz_8'),mi=queryColumns.indexOf('id_municipio'),vi=queryColumns.indexOf('valor_total');
   for(const row of chunk.rows)if((!entity||row[ci]===entity)&&(!mun||String(row[mi]).slice(0,6)===mun)&&(!paid||(paid==='yes'?row[vi]>0:row[vi]===0)))queryRows.push(row);
  }
  renderQuery();$('query-status').textContent=fmt(queryRows.length)+(queryRows.length===1?' linha encontrada':' linhas encontradas')+' · '+queryColumns.length+' variáveis · '+(yr==='all'?'2014–2021':yr)+'. Os cabeçalhos mostram o significado e o nome original de cada coluna.';
 }catch(error){$('query-status').textContent=error.message;}finally{controls.forEach(e=>e.disabled=false);}
};
const pages=['panorama','construcao','pagamentos','capacidade','atlas','consulta'];
function switchPage(page){document.querySelectorAll('nav button').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.page===page)));pages.forEach(p=>$(p).hidden=p!==page);$('tip').style.display='none';if(page==='atlas')drawAtlas();window.scrollTo({top:0,behavior:'instant'});}
document.querySelectorAll('nav button').forEach(b=>b.onclick=()=>switchPage(b.dataset.page));
let resizeTimer;window.addEventListener('resize',()=>{clearTimeout(resizeTimer);resizeTimer=setTimeout(()=>{if(!$('atlas').hidden)drawAtlas();},120);});
