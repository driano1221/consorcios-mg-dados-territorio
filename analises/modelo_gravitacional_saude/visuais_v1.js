'use strict';
const D=JSON.parse(document.getElementById('data').textContent),$=id=>document.getElementById(id);
const blue='#2980B9',ink='#1A252F',grey='#7F8C8D',red='#C0392B';
const fmt=(n,d=0)=>n===null||n===undefined?'Não disponível':Number(n).toLocaleString('pt-BR',{minimumFractionDigits:d,maximumFractionDigits:d});
const cash=n=>'R$ '+fmt(n,2),million=n=>'R$ '+fmt(n/1e6,2)+' mi';
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const flabel={destino_clinico_fixo:'Clínica fixa',unidade_movel:'Unidade móvel',estrutura_fixa_nao_clinica:'Estrutura não clínica'};
const scopeLabels={financeira_e_gravitacional:'Núcleo v1: financeiro e direto',somente_financeira_sem_polo_direto:'Núcleo v1: somente financeiro',fora_antes_abertura:'Fora da v1: anterior à abertura',fora_escopo_nucleo_saude:'Fora do núcleo v1'};
const txt=(x,y,s,opts='')=>`<text x="${x}" y="${y}" ${opts}>${esc(s)}</text>`;
const svg=(w,h,s,title)=>`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" role="img" aria-label="${esc(title)}"><title>${esc(title)}</title>${s}</svg>`;
const table=(rows,cols)=>`<table><thead><tr>${cols.map(c=>`<th scope="col">${esc(c[1])}</th>`).join('')}</tr></thead><tbody>${rows.map(r=>`<tr>${cols.map(c=>`<td>${esc(c[2]?c[2](r[c[0]]):r[c[0]])}</td>`).join('')}</tr>`).join('')||`<tr><td colspan="${cols.length}">Nenhum registro neste recorte.</td></tr>`}</tbody></table>`;
function download(blob,name){const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}
function csv(rows,name){if(!rows.length)return;const cols=Object.keys(rows[0]),quote=v=>'"'+String(v??'').replaceAll('"','""')+'"';download(new Blob(['\ufeff'+[cols,...rows.map(r=>cols.map(c=>r[c]))].map(r=>r.map(quote).join(';')).join('\r\n')],{type:'text/csv;charset=utf-8'}),name+'.csv');}
function exportSVG(node,name,title,notes=[]){
 const source=node.querySelector('svg');if(!source)return null;
 const copy=source.cloneNode(true),vb=source.viewBox.baseVal,w=vb.width,h=vb.height,ns='http://www.w3.org/2000/svg',outer=document.createElementNS(ns,'svg');
 const wrap=(s,chars)=>{const rows=[''];for(const word of s.split(' ')){if((rows.at(-1)+' '+word).trim().length>chars)rows.push(word);else rows[rows.length-1]=(rows.at(-1)+' '+word).trim();}return rows;};
 const titleLines=wrap(title,Math.floor(w/10)),noteLines=notes.flatMap(n=>wrap(n,Math.floor(w/6.1)));
 const footerLines=wrap('Fontes: MIDES · CNES/DATASUS · IBGE/geobr. Elaboração: Adriano Pires Cunha.',Math.floor(w/5.5));
 const bottom=(noteLines.length+footerLines.length)*20+30,top=titleLines.length*23+45;outer.setAttribute('xmlns',ns);outer.setAttribute('viewBox',`0 0 ${w+40} ${h+top+bottom}`);outer.setAttribute('width',w+40);outer.setAttribute('height',h+top+bottom);
 const bg=document.createElementNS(ns,'rect');bg.setAttribute('width','100%');bg.setAttribute('height','100%');bg.setAttribute('fill','white');outer.append(bg);
 const style=document.createElementNS(ns,'style');style.textContent='text{font-family:"Noto Sans",Arial,sans-serif;fill:#1A252F}';outer.append(style);
 function line(y,text,size=12){const el=document.createElementNS(ns,'text');el.setAttribute('x',20);el.setAttribute('y',y);el.setAttribute('font-size',size);el.textContent=text;outer.append(el);}
 titleLines.forEach((s,i)=>line(27+i*23,s,17));line(top-16,'Consórcios de MG · dados de 24/09/2026',11);
 copy.setAttribute('x',20);copy.setAttribute('y',top);copy.setAttribute('width',w);copy.setAttribute('height',h);outer.append(copy);
 noteLines.forEach((n,i)=>line(h+top+23+i*20,n,11));footerLines.forEach((n,i)=>line(h+top+bottom-footerLines.length*20+i*20+10,n,10));
 return {blob:new Blob([new XMLSerializer().serializeToString(outer)],{type:'image/svg+xml;charset=utf-8'}),width:w+40,height:h+top+bottom};
}
function saveSVG(id,name,title,notes){const result=exportSVG($(id),name,title,notes);if(result)download(result.blob,name+'.svg');}
function lineChart(rows,key,title,{money=true,selected=null,colour=blue}={}){
 const w=760,h=260,l=66,r=48,t=33,b=44,ys=Array.from({length:8},(_,i)=>2014+i),max=Math.max(1,...rows.map(x=>Number(x[key])||0))*1.22;
 const x=y=>l+(y-2014)*(w-l-r)/7,y=v=>h-b-v/max*(h-b-t),values=new Map(rows.map(r=>[+r.ano,r]));let body='';
 for(let i=0;i<=4;i++){const v=max*i/4;body+=`<line x1="${l}" y1="${y(v)}" x2="${w-r}" y2="${y(v)}" stroke="#E1E7EB"/>`+txt(l-10,y(v)+4,fmt(money?v/1e6:v,money?1:0),'text-anchor="end" font-size="13"');}
 let path='';ys.forEach(yr=>{body+=txt(x(yr),h-16,yr,'text-anchor="middle" font-size="13"');const row=values.get(yr);if(!row){path+=' ';return;}path+=(values.has(yr-1)&&yr!==2014?'L':'M')+x(yr)+','+y(row[key]);});
 body+=`<path d="${path}" fill="none" stroke="${colour}" stroke-width="2.6"/>`;
 rows.forEach(row=>{const v=Number(row[key]),yr=+row.ano;body+=`<circle cx="${x(yr)}" cy="${y(v)}" r="${yr===selected?6:3}" fill="${colour}"><title>${yr}: ${money?cash(v):fmt(v)}</title></circle>`;if(rows.length<2||yr===2014||yr===2021||yr===selected)body+=txt(x(yr),y(v)-14,money?fmt(v/1e6,1):fmt(v),'text-anchor="middle" font-size="13" font-weight="700"');});
 body+=txt(l,14,money?'R$ milhões nominais':'Municípios pagadores','font-size="12"');return svg(w,h,body,title);
}
// As figuras e os dados locais sao gerados pelos scripts 26 e 27, sem fetch.
document.querySelectorAll('[data-figure]').forEach(box=>{const id=box.dataset.figure,c=D.catalog.find(x=>x.id===id);box.classList.add('figure-block');box.innerHTML=`<figure><a href="figuras/${id}.svg" target="_blank" aria-label="Ampliar: ${esc(c.titulo)}"><img src="figuras/${id}.svg" alt="${esc(c.titulo+'. '+c.leitura)}" loading="lazy"></a><figcaption>${esc(c.leitura)}</figcaption></figure><div class="figure-links"><a href="figuras/${id}.png" download>PNG 300 dpi</a><a href="figuras/${id}.svg" download>SVG</a>${c.dados.endsWith('.csv')&&!c.dados.startsWith('registro')?`<a href="dados/${c.dados}" download>Dados CSV</a>`:''}</div>`;});
$('headline-numbers').innerHTML=[[D.summary.consorcios,'consórcios no núcleo financeiro'],[D.summary.municipios,'municípios com pagamento'],[D.summary.relacoes,'relações pagas em oito anos'],[D.summary.capacidade_entidades_ano,'entidades-ano com capacidade direta']].map(([n,l])=>`<div><strong>${fmt(n)}</strong><span>${l}</span></div>`).join('');
const ts=D.times[0];$('time-numbers').innerHTML=[[fmt(ts.n),'relações pagas'],[fmt(ts.mediana,2)+' min','mediana'],[fmt(ts.p90,1)+' min','90% das relações até este tempo'],[fmt(ts.intramunicipais),'origem e destino no mesmo município']].map(([n,l])=>`<div><strong>${n}</strong><span>${l}</span></div>`).join('');
$('aux-table').innerHTML=table(D.aux.filter(r=>r.ano===2019),[['entidade','Consórcio'],['unidades','Clínicas',v=>fmt(v)],['profissionais','Profissionais SUS',v=>fmt(v)],['servicos','Serviços SUS',v=>fmt(v)],['horas','Horas SUS',v=>fmt(v)]]);
$('extreme-table').innerHTML=table(D.extremes,[['municipio','Município'],['entidade','Consórcio'],['ano','Ano'],['tempo_minimo_min','Minutos',v=>fmt(v,1)],['valor_total','Pagamento',cash],['destino_clinico_mais_proximo_id','IBGE do destino']]);
$('catalog-table').innerHTML='<table><thead><tr><th>Figura</th><th>Arquivos</th><th>O que permite observar</th></tr></thead><tbody>'+D.catalog.map(c=>`<tr><td>${esc(c.titulo)}</td><td><a href="figuras/${c.id}.png" download>PNG</a> · <a href="figuras/${c.id}.svg" download>SVG</a>${!c.dados.startsWith('registro')?` · <a href="dados/${c.dados}" download>CSV</a>`:''}</td><td>${esc(c.leitura)}</td></tr>`).join('')+'</tbody></table>';
for(let yr=2014;yr<=2021;yr++)$('rank-year').insertAdjacentHTML('beforeend',`<option value="${yr}">${yr}</option>`);
const financialEntities=[...new Map(D.entity_year.map(r=>[r.cnpj_raiz_8,r.entidade])).entries()].sort((a,b)=>a[1].localeCompare(b[1],'pt-BR'));
$('pay-entity').innerHTML=financialEntities.map(([r,n])=>`<option value="${r}">${esc(n)} · ${r}</option>`).join('');$('pay-entity').value='05802877';
let rankingRows=[],payRows=[];
function drawPayments(){
 const period=$('rank-year').value;rankingRows=D.ranking.filter(r=>r.periodo===period);const top=rankingRows.filter(r=>r.valor>0).slice(0,15),w=760,h=top.length*35+64,l=225,r=115,max=Math.max(1,...top.map(r=>r.valor));let body='';
 top.forEach((row,i)=>{const y=i*35+22,width=(w-l-r)*row.valor/max,label=row.entidade.length>28?row.entidade.slice(0,26)+'…':row.entidade;body+=txt(l-12,y+5,label,'text-anchor="end" font-size="13"')+`<rect x="${l}" y="${y-9}" width="${width}" height="20" fill="${blue}"><title>${esc(row.entidade)}: ${cash(row.valor)}</title></rect>`+txt(l+width+9,y+5,fmt(row.valor/1e6,2)+' mi','font-size="13"');});
 body+=txt(l,h-6,'R$ milhões nominais; ranking completo disponível na tabela','font-size="12"');$('rank-chart').innerHTML=svg(w,h,body,'Os 15 maiores pagamentos em '+period);
 $('rank-title').textContent='Maiores pagamentos em '+period;$('rank-info').textContent=`Os 15 primeiros somam ${fmt(top.reduce((s,r)=>s+r.participacao,0)*100,1)}% do valor. ${rankingRows.filter(r=>r.valor>0).length} consórcios receberam no período.`;
 $('rank-table').innerHTML=table(rankingRows,[['posicao','Posição'],['entidade','Consórcio'],['cnpj_raiz_8','Raiz CNPJ'],['valor','Valor nominal',cash],['participacao','Participação',v=>fmt(v*100,2)+'%'],['acumulada','Acumulada',v=>fmt(v*100,2)+'%']]);
 payRows=D.entity_year.filter(r=>r.cnpj_raiz_8===$('pay-entity').value);$('pay-title').textContent=payRows[0]?.entidade||'Consórcio';
 $('pay-chart').innerHTML=lineChart(payRows,'valor','Pagamentos anuais de '+$('pay-title').textContent);$('payer-chart').innerHTML=lineChart(payRows,'pagadores','Municípios pagadores de '+$('pay-title').textContent,{money:false,colour:grey});
 $('pay-table').innerHTML=table(payRows,[['ano','Ano'],['valor','Pagamento',cash],['pagadores','Municípios pagadores',fmt]]);
}
['rank-year','pay-entity'].forEach(id=>$(id).addEventListener('change',drawPayments));
$('rank-csv').onclick=()=>csv(rankingRows,'ranking_'+$('rank-year').value);$('pay-csv').onclick=()=>csv(payRows,'pagamentos_'+$('pay-entity').value);
$('rank-svg').onclick=()=>saveSVG('rank-chart','ranking_'+$('rank-year').value,$('rank-title').textContent,['Núcleo financeiro v1. Valores nominais. Os 15 maiores; tabela disponível para todos.']);
$('pay-svg').onclick=()=>saveSVG('pay-chart','pagamentos_'+$('pay-entity').value,$('pay-title').textContent,['Pagamentos no núcleo v1, 2014–2021. Valores nominais.']);
$('payer-svg').onclick=()=>saveSVG('payer-chart','pagadores_'+$('pay-entity').value,$('pay-title').textContent,['Municípios com pagamento positivo em cada ano, núcleo v1.']);
drawPayments();
// Atlas: mantem o inventario de 221 entidades e explicita o escopo da v1.
let year='2019',root='05802877',extent='regional',selectedCode='',selectedUnits=[],atlasPaid=[],allUnits=[],currentEntity;
const years=['2014','2015','2016','2017','2018','2019','2020','2021','atual'];
$('atlas-year').innerHTML=years.map(y=>`<option value="${y}">${y==='atual'?'Setembro/2026':y}</option>`).join('');$('atlas-year').value=year;
for(const group of [...new Set(D.entities.map(e=>e.grupo))])$('atlas-entity').insertAdjacentHTML('beforeend',`<optgroup label="${esc(group)}">${D.entities.filter(e=>e.grupo===group).sort((a,b)=>a.rotulo.localeCompare(b.rotulo,'pt-BR')).map(e=>`<option value="${e.raiz}">${esc(e.rotulo)} · ${esc(e.sede)} · ${e.raiz}</option>`).join('')}</optgroup>`);
$('atlas-entity').value=root;
$('map-municipality').insertAdjacentHTML('beforeend',D.polys.slice().sort((a,b)=>a.name.localeCompare(b.name,'pt-BR')).map(p=>`<option value="${p.code}">${esc(p.name)}</option>`).join(''));
function getBounds(polys){if(!polys.length)return allBounds;let a=Infinity,b=Infinity,c=-Infinity,d=-Infinity;for(const p of polys)for(const ring of p.rings)for(const [x,y] of ring){a=Math.min(a,x);b=Math.min(b,y);c=Math.max(c,x);d=Math.max(d,y);}return[a,b,c,d];}
const allBounds=getBounds(D.polys);
function projection(bounds,w,h,pad=32){const[a,b,c,d]=bounds,scale=Math.min((w-2*pad)/Math.max(1,c-a),(h-2*pad)/Math.max(1,d-b));return{x:v=>(v-(a+c)/2)*scale+w/2,y:v=>h/2-(v-(b+d)/2)*scale,scale};}
function shape(p,pr){return p.rings.map(r=>r.map((q,i)=>(i?'L':'M')+pr.x(q[0]).toFixed(1)+','+pr.y(q[1]).toFixed(1)).join('')+'Z').join('');}
function mapMarkup(){
 const mobile=innerWidth<=720,w=mobile?Math.max(320,innerWidth-55):850,h=mobile?360:510;
 const payMap=new Map(atlasPaid.map(r=>[r.codigo_ibge_6,r])),cnmCodes=new Set(D.cnm.filter(c=>c.raiz===root).flatMap(c=>String(c.municipios_ibge||'').split('|')));
 const relevant=D.polys.filter(p=>(payMap.has(p.code)&&$('layer-paid').checked)||selectedUnits.some(u=>u.codigo_ibge_6===p.code)||($('layer-cnm').checked&&cnmCodes.has(p.code)));
 const pr=projection(extent==='state'||!relevant.length?allBounds:getBounds(relevant),w,h,mobile?18:35);
 let b=`<defs><clipPath id="map-clip"><rect width="${w}" height="${h}"/></clipPath></defs><g clip-path="url(#map-clip)">`;
 D.polys.forEach(p=>{const paid=payMap.get(p.code),cnm=$('layer-cnm').checked&&cnmCodes.has(p.code),selected=p.code===selectedCode;
 b+=`<path d="${shape(p,pr)}" fill="${paid&&$('layer-paid').checked?'#9FC8E0':'#F7F9FA'}" stroke="${selected?ink:cnm?ink:'#CBD5DB'}" stroke-width="${selected?2:cnm?1.5:.45}" ${cnm?'stroke-dasharray="4 3"':''} fill-rule="evenodd" data-code="${p.code}"><title>${esc(p.name)}: ${year==='atual'?'MIDES 2026 não disponível':paid?cash(paid.valor):'sem pagamento positivo observado'}</title></path>`;});
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
function showMunicipality(){if(!selectedCode){$('map-selection').textContent='Selecione um município no mapa ou na lista para ver o pagamento observado.';return;}const p=D.polys.find(p=>p.code===selectedCode),r=atlasPaid.find(r=>r.codigo_ibge_6===selectedCode);$('map-selection').innerHTML=`<strong>${esc(p.name)} · ${year==='atual'?'2026':year}</strong>${year==='atual'?'A série MIDES disponível termina em 2021.':r?cash(r.valor)+' em '+fmt(r.n_transacoes)+' registros financeiros.':'Sem pagamento positivo observado a este consórcio no ano.'}`;}
function drawAtlas(){
 root=$('atlas-entity').value;year=$('atlas-year').value;currentEntity=D.entities.find(e=>e.raiz===root);const current=year==='atual';
 allUnits=D.units.filter(u=>u.cnpj_raiz_8===root&&u.ano===year);atlasPaid=D.payments.filter(p=>p.cnpj_raiz_8===root&&String(p.ano)===year);
 const type=$('atlas-type').value,types=[...new Set(allUnits.map(u=>u.tipo||'Tipo não informado'))].sort();$('atlas-type').innerHTML='<option value="all">Todos os tipos</option>'+types.map(t=>`<option value="${esc(t)}">${esc(t)}</option>`).join('');$('atlas-type').value=types.includes(type)?type:'all';
 selectedUnits=allUnits.filter(u=>($('atlas-function').value==='all'||u.funcao===$('atlas-function').value)&&($('atlas-type').value==='all'||(u.tipo||'Tipo não informado')===$('atlas-type').value)).sort((a,b)=>String(a.codigo_ibge_6??'').localeCompare(String(b.codigo_ibge_6??''))||a.cnes.localeCompare(b.cnes));
 const ledger=D.ledger.find(r=>r.cnpj_raiz_8===root&&r.ano===+year),clinical=D.cap_all.find(r=>r.cnpj_raiz_8===root&&r.ano===+year),unlocated=selectedUnits.filter(u=>u.x===null||u.y===null).length;
 $('atlas-name').textContent=currentEntity.rotulo;$('atlas-title-year').textContent=current?'2026':year;$('atlas-description').textContent=currentEntity.nome;
 $('atlas-scope').textContent=current?'Fotografia atual, fora da série v1':ledger?scopeLabels[ledger.destino_v1]:'Inventário de fronteira, fora da v1';
 $('atlas-notice').textContent=(current?(currentEntity.grupo==='84 originais'?'CNES coletado em 03/09/2026. Não há pagamentos MIDES de 2026 nesta entrega.':'CNES atual não coletado para esta entidade da revisão externa. O contador vazio não comprova ausência de estrutura.'):'CNES de dezembro. O atlas inclui entidades fora do núcleo v1; os pagamentos aqui abrangem as finalidades da entidade.')+(allUnits.length===0?' Não foi identificada unidade direta neste recorte.':'')+(unlocated?' '+unlocated+' unidade(s) no filtro sem localização no cache.':'');
 $('side-period').textContent=current?'RETRATO DE SETEMBRO/2026':'RETRATO DO ANO · '+year;
 $('atlas-numbers').innerHTML=`<div class="wide"><strong>${current?'Não disponível':million(atlasPaid.reduce((s,r)=>s+r.valor,0))}</strong><span>pagamentos nominais no inventário ampliado</span></div><div><strong>${current?'Não disponível':atlasPaid.length}</strong><span>municípios pagadores</span></div><div><strong>${selectedUnits.length}</strong><span>unidades no filtro${unlocated?' ('+unlocated+' sem localização)':''}</span></div>`;
 $('capacity-rows').innerHTML=[['Unidades clínicas','unidades'],['Profissionais SUS','profissionais'],['Serviços/classificações SUS','servicos'],['Horas SUS cadastradas','horas']].map(([label,key])=>`<div class="profile-row"><span>${label}</span><strong>${clinical?fmt(clinical[key]):'Não disponível'}</strong></div>`).join('');
 $('capacity-note').textContent=clinical?'Capacidade de todas as clínicas diretas do consórcio nesse dezembro, independentemente do filtro do mapa. Pessoas e serviços podem repetir entre unidades; horas não são anuais.':current?'A capacidade histórica da v1 não é retroagida nem projetada para 2026.':'Sem clínica direta identificada em dezembro para agregar capacidade. Isso não significa ausência de atendimento.';
 const codes=[...new Set(selectedUnits.filter(u=>u.x!==null).map(u=>u.codigo_ibge_6))].sort();
 $('unit-list').innerHTML=selectedUnits.slice(0,12).map(u=>`<div class="unit"><span class="unit-index">${u.x===null?'?':codes.indexOf(u.codigo_ibge_6)+1}</span><div><b>${esc(u.municipio||'Município não localizado')}</b><small>CNES ${u.cnes} · ${esc(u.tipo||'Tipo não informado')}<br>${esc(flabel[u.funcao]||u.funcao)}</small></div></div>`).join('')||'<p class="small">Nenhuma unidade no filtro. Consulte a informação sobre cobertura acima.</p>';
 if(selectedUnits.length>12)$('unit-list').insertAdjacentHTML('beforeend',`<p class="small">Mostradas 12 de ${selectedUnits.length}. A tabela abaixo e o CSV contêm todas.</p>`);
 $('main-map').innerHTML=mapMarkup();$('map-key').textContent='Círculo vermelho: clínica. Triângulo azul: móvel. Quadrado cinza: não clínica. Círculo cinza: funções combinadas.';
 const series=Array.from({length:8},(_,i)=>{const ano=2014+i,paid=D.payments.filter(p=>p.cnpj_raiz_8===root&&p.ano===ano);return{ano,valor:paid.reduce((s,p)=>s+p.valor,0)}});
 $('atlas-chart-title').textContent='Pagamentos a '+currentEntity.rotulo;$('atlas-chart').innerHTML=lineChart(series,'valor',$('atlas-chart-title').textContent,{selected:current?null:+year});
 $('atlas-reading').textContent=ledger?`Neste ano, a entidade está classificada como ${scopeLabels[ledger.destino_v1].toLowerCase()}. ${ledger.classificacao_oferta.replaceAll('_',' ')}. ${ledger.alerta_temporal==='TRUE'?'Há alerta de variação cadastral ao longo do ano; dezembro é apenas uma fotografia.':''}`:'O inventário permite consultar as evidências disponíveis, mas esta seleção não pertence ao recorte anual da v1.';
 $('atlas-evidence').innerHTML=`<p>CNPJ ${esc(currentEntity.cnpj)}. Sede cadastral: ${esc(currentEntity.sede)}. ${esc(currentEntity.grupo)}.</p><p>Revisão de fronteira: 16/09/2026. ${esc(currentEntity.decisao.replaceAll('_',' '))}</p>${currentEntity.evidencia?`<p>${esc(currentEntity.evidencia)}</p><p>${esc(currentEntity.limite)}</p>`:''}<p class="source">${esc(currentEntity.fonte||'Cadastro IPEA, registro de inclusão v1 e CNES/DATASUS.')}</p><p>CNM é a composição de agosto de 2026, mesmo ao lado de um ano histórico. Município pagador não equivale a município membro ou origem de paciente. Unidades móveis não definem um destino fixo de viagem.</p>`;
 $('atlas-table').innerHTML=table(selectedUnits,[['cnes','CNES'],['municipio','Município',v=>v||'Não localizado'],['tipo','Tipo',v=>v||'Não informado'],['funcao','Função',v=>flabel[v]||v],['fonte','Fonte']]);
 $('map-municipality').value=selectedCode;showMunicipality();$('tip').style.display='none';
 $('main-map').querySelectorAll('[data-code]').forEach(p=>{p.addEventListener('click',()=>{selectedCode=p.dataset.code;drawAtlas();});p.addEventListener('pointermove',e=>{const m=D.polys.find(x=>x.code===p.dataset.code),paid=atlasPaid.find(x=>x.codigo_ibge_6===p.dataset.code);$('tip').innerHTML=`<b>${esc(m.name)}</b>${current?'MIDES 2026 não disponível':paid?cash(paid.valor):'Sem pagamento positivo observado'}`;$('tip').style.cssText=`display:block;left:${Math.max(8,Math.min(e.clientX+12,innerWidth-260))}px;top:${Math.max(8,Math.min(e.clientY+12,innerHeight-85))}px`;});p.addEventListener('pointerleave',()=>{$('tip').style.display='none'});});
}
['atlas-entity','atlas-year','atlas-function','atlas-type','layer-paid','layer-units','layer-cnm'].forEach(id=>$(id).addEventListener('change',drawAtlas));
['regional','state'].forEach(id=>$(id).onclick=()=>{extent=id;['regional','state'].forEach(i=>$(i).setAttribute('aria-pressed',String(i===id)));drawAtlas();});
$('map-municipality').onchange=()=>{selectedCode=$('map-municipality').value;drawAtlas();};
const exportNotes=()=>[`${year==='atual'?'CNES setembro/2026':'CNES dezembro/'+year+'; MIDES anual nominal'}. ${$('atlas-scope').textContent}.`,
 `Filtro: ${flabel[$('atlas-function').value]||'todas as funções'}; ${$('atlas-type').value==='all'?'todos os tipos':$('atlas-type').value}.`,
 `${selectedUnits.length} unidades no filtro; ${selectedUnits.filter(u=>u.x===null).length} sem localização. ${year==='atual'?'MIDES 2026 não disponível.':atlasPaid.length+' municípios pagadores; '+cash(atlasPaid.reduce((s,p)=>s+p.valor,0))+'.'}`,
 'Azul claro: pagamento; vermelho: clínica; azul: móvel; cinza: não clínica ou funções combinadas.',
 $('layer-cnm').checked?'Contorno tracejado: composição CNM em agosto/2026, não histórica.':'Composição CNM desativada.',
 selectedCode?'Contorno sólido: '+D.polys.find(p=>p.code===selectedCode).name+'.':'Nenhum município selecionado.',
 'Pontos municipais. Sem endereço, fluxo de pacientes ou cobertura assistencial comprovada.'];
$('map-svg').onclick=()=>saveSVG('main-map','mapa_'+root+'_'+year,currentEntity.rotulo+' · '+year,exportNotes());
$('map-png').onclick=()=>{const result=exportSVG($('main-map'),'mapa',currentEntity.rotulo+' · '+year,exportNotes());if(!result)return;const image=new Image(),url=URL.createObjectURL(result.blob);image.onload=()=>{const canvas=document.createElement('canvas');canvas.width=result.width*3;canvas.height=result.height*3;canvas.getContext('2d').drawImage(image,0,0,canvas.width,canvas.height);canvas.toBlob(blob=>{if(blob)download(blob,'mapa_'+root+'_'+year+'.png');URL.revokeObjectURL(url);});};image.onerror=()=>{URL.revokeObjectURL(url);alert('Não foi possível exportar PNG neste navegador. A versão SVG continua disponível.');};image.src=url;};
$('atlas-csv').onclick=()=>csv(selectedUnits,'unidades_'+root+'_'+year);$('atlas-pay-csv').onclick=()=>csv(atlasPaid,'pagamentos_atlas_'+root+'_'+year);
const pages=['panorama','pagamentos','capacidade','tempos','atlas','fontes'];
function switchPage(page){document.querySelectorAll('nav button').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.page===page)));pages.forEach(p=>$(p).hidden=p!==page);$('tip').style.display='none';if(page==='atlas')drawAtlas();window.scrollTo({top:0,behavior:'instant'});}
document.querySelectorAll('nav button').forEach(b=>b.onclick=()=>switchPage(b.dataset.page));
$('go-atlas').onclick=()=>{$('atlas-entity').value='05802877';$('atlas-year').value='2019';$('atlas-function').value='destino_clinico_fixo';$('atlas-type').value='all';switchPage('atlas');};
let resizeTimer;window.addEventListener('resize',()=>{clearTimeout(resizeTimer);resizeTimer=setTimeout(()=>{if(!$('atlas').hidden)drawAtlas();},120);});
drawAtlas();
