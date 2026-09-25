function(el, x, data) {
  const map = this;
  const rows = value => Array.isArray(value) ? value : HTMLWidgets.dataframeToD3(value);
  const entities = rows(data.entities), units = rows(data.units), payments = rows(data.payments), cnm = rows(data.cnm);
  const esc = value => String(value ?? '').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const money = value => Number(value).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
  const labels = {destino_clinico_fixo:'Clínica fixa',estrutura_fixa_nao_clinica:'Estrutura não clínica',unidade_movel:'Unidade móvel'};
  const colors = {destino_clinico_fixo:'#C0392B',estrutura_fixa_nao_clinica:'#7F8C8D',unidade_movel:'#2980B9',misto:'#1A252F'};
  const style = document.createElement('style');
  style.textContent = `body{margin:0;background:#f4f6f8;color:#203246;font:15px system-ui,sans-serif}#atlas-controls,#atlas-detail{max-width:1280px;margin:auto;padding:22px 28px}h1{font-size:27px;margin:3px 0 8px}p{line-height:1.5;margin:7px 0}.eyebrow{font-size:12px;letter-spacing:.12em;color:#087f8c;font-weight:700}.controls{display:flex;gap:14px;flex-wrap:wrap;margin:17px 0}.controls label{display:flex;flex-direction:column;gap:5px;font-size:13px;font-weight:600}select,button{font:inherit;padding:9px;border:1px solid #b5c4cf;border-radius:6px;background:white;color:#203246}#entity{max-width:540px}button{cursor:pointer}.stats{display:flex;gap:12px;flex-wrap:wrap}.stat{background:white;padding:10px 18px;border-radius:7px;border:1px solid #dce3e9}.stat b{display:block;font-size:21px}.stat span{font-size:12px;color:#536777}.legend{display:flex;gap:18px;flex-wrap:wrap;font-size:13px;padding:12px 0}.legend i{display:inline-block;width:11px;height:11px;border-radius:50%;margin-right:5px}.check{margin-right:20px}#atlas-notice{color:#755313;background:#fff5dc;padding:10px 14px;border-radius:6px;margin-top:12px}.leaflet-container{max-width:1280px;margin:0 auto;background:#edf1f5;border:1px solid #d4dfe5}#atlas-detail h2{font-size:20px}table{border-collapse:collapse;width:100%;background:white;font-size:13px}td,th{padding:9px;text-align:left;border-bottom:1px solid #e3e8ed}th{background:#e8eef3}.table-wrap{max-height:370px;overflow:auto}thead{position:sticky;top:0}.source{font-size:12px;color:#536777;overflow-wrap:anywhere}.leaflet-popup-content{max-height:280px;overflow:auto}.muted{color:#536777}.actions{display:flex;gap:8px;margin:12px 0}@media(max-width:700px){#atlas-controls,#atlas-detail{padding:16px}h1{font-size:23px}#entity{width:100%;max-width:100%}.controls label:first-child{width:100%}.stat{padding:8px 12px}.leaflet-container{height:480px!important}}`;
  style.textContent += '.leaflet-container{box-sizing:border-box}body{background:white;color:#1A252F;font-family:"Noto Sans",Arial,sans-serif}.stat,select,button,#atlas-notice{border-radius:0}.eyebrow{color:#2980B9}.stat{border:0;border-top:2px solid #1A252F}a{color:#1D628F}#atlas-notice{background:#F6F8F9;color:#566570;border-left:3px solid #7F8C8D}';
  document.head.appendChild(style);
  document.getElementById('atlas-controls').innerHTML = `
    <div class="eyebrow">IPEA · MINAS GERAIS · INVENTÁRIO DE FRONTEIRA DE ${esc(data.date)}</div>
    <h1>Onde estão as unidades de cada consórcio?</h1>
    <p class="muted">Compare o CNES de dezembro de cada ano com os municípios que pagaram ao consórcio. A fotografia atual está disponível para as 84 entidades originais.</p>
    <p class="source">Este inventário tem 221 entidades e inclui casos fora do núcleo v1. Pagamentos: 2014–2021, todas as finalidades da entidade. <a href="visuais_v1/index.html">Abrir os gráficos e o atlas integrado da base v1</a>.</p>
    <div class="controls"><label>Consórcio<select id="entity"></select></label>
      <label>Período do CNES<select id="period">${[2014,2015,2016,2017,2018,2019,2020,2021].map(y=>`<option>${y}</option>`).join('')}<option value="atual">Atual · setembro/2026</option></select></label>
      <label>Função da unidade<select id="function"><option value="all">Todas as funções</option>${Object.entries(labels).map(([v,l])=>`<option value="${v}">${l}</option>`).join('')}</select></label>
      <label>Tipo de estabelecimento<select id="type"><option value="all">Todos os tipos</option></select></label>
      <label>&nbsp;<button id="fit">Enquadrar unidades e pagadores</button></label></div>
    <label class="check"><input type="checkbox" id="payments" checked> Municípios com pagamento MIDES no ano</label>
    <label class="check"><input type="checkbox" id="cnm"> Composição CNM de agosto/2026 (atual)</label>
    <div class="legend">${Object.entries({...labels,misto:'Mais de uma função no município'}).map(([k,l])=>`<span><i style="background:${colors[k]}"></i>${l}</span>`).join('')}<span>Azul claro: pagamento</span><span style="color:#a16a00">Contorno dourado: CNM atual</span></div>
    <div class="stats" id="stats"></div><p id="atlas-notice"></p>`;
  const selector = document.getElementById('entity');
  for(const group of [...new Set(entities.map(e=>e.grupo))]) {
    const optgroup = document.createElement('optgroup'); optgroup.label=group;
    entities.filter(e=>e.grupo===group).forEach(e=>{const o=document.createElement('option');o.value=e.raiz;o.textContent=`${e.sigla} · ${e.sede} · ${e.raiz}`;optgroup.appendChild(o);});
    selector.appendChild(optgroup);
  }
  selector.value='05802877'; document.getElementById('period').value='2019';
  const shapes=L.geoJSON(data.municipalities,{style:{color:'#b6c6d2',weight:.45,fillColor:'#fff',fillOpacity:1}}).addTo(map);
  const points=L.layerGroup().addTo(map), outlines=L.layerGroup().addTo(map);
  const polygons={};shapes.eachLayer(layer=>{polygons[layer.feature.properties.codigo_ibge_6]=layer;});
  let selectedUnits=[], activeCodes=[];
  function draw(){
    const root=selector.value, period=document.getElementById('period').value, func=document.getElementById('function').value;
    const entity=entities.find(e=>e.raiz===root), current=period==='atual';
    const allUnits=units.filter(u=>u.cnpj_raiz_8===root&&String(u.ano)===period);
    const typeSelect=document.getElementById('type'), previousType=typeSelect.value;
    const availableTypes=[...new Set(allUnits.map(u=>u.tipo))].sort();
    typeSelect.innerHTML='<option value="all">Todos os tipos</option>'+availableTypes.map(t=>`<option value="${esc(t)}">${esc(t)}</option>`).join('');
    typeSelect.value=availableTypes.includes(previousType)?previousType:'all';
    selectedUnits=allUnits.filter(u=>(func==='all'||u.funcao===func)&&(typeSelect.value==='all'||u.tipo===typeSelect.value));
    const paid=payments.filter(p=>p.cnpj_raiz_8===root&&String(p.ano)===period);
    const payByCode=Object.fromEntries(paid.map(p=>[p.codigo_ibge_6,p.valor]));
    const cnmRecord=cnm.find(c=>c.raiz===root);
    const cnmCodes=cnmRecord ? String(cnmRecord.municipios_ibge||'').split('|') : [];
    activeCodes=[...new Set([...selectedUnits.filter(u=>u.lat!==null).map(u=>u.codigo_ibge_6),...paid.map(p=>p.codigo_ibge_6)])];
    points.clearLayers();outlines.clearLayers();
    shapes.eachLayer(layer=>{
      const p=layer.feature.properties, value=payByCode[p.codigo_ibge_6];
      layer.setStyle({color:'#b6c6d2',weight:.45,fillColor:document.getElementById('payments').checked&&value>0?'#afd8ec':'#fff',fillOpacity:1});
      layer.bindTooltip(esc(p.municipio));
      const conflict=paid.find(r=>r.codigo_ibge_6===p.codigo_ibge_6)?.conflito_credor_mides;
      layer.bindPopup(`<b>${esc(p.municipio)}</b><br>${current?'MIDES: sem série 2026 neste atlas.':value>0?`Pagamento em ${period}: ${money(value)}`:`Sem pagamento positivo observado em ${period}.`}${conflict?'<br><b>Alerta: nome e documento do credor conflitantes. Valor mantido sob verificação.</b>':''}<br><small>Pagamento não comprova filiação jurídica ou uso de serviços.</small>`);
      if(document.getElementById('cnm').checked&&cnmCodes.includes(p.codigo_ibge_6)) {
        L.geoJSON(layer.feature,{interactive:false,style:{color:'#c4850d',weight:2,fillOpacity:0,dashArray:'4 3'}}).addTo(outlines);
      }
    });
    const grouped={};selectedUnits.filter(u=>u.lat!==null&&u.lon!==null).forEach(u=>(grouped[u.codigo_ibge_6]??=[]).push(u));
    for(const group of Object.values(grouped)){
      const u=group[0],functions=[...new Set(group.map(r=>r.funcao))],color=colors[functions.length===1?functions[0]:'misto'];
      const marker=L.circleMarker([u.lat,u.lon],{radius:Math.min(18,5+Math.sqrt(group.length)*2),color:'#fff',weight:1.5,fillColor:color,fillOpacity:.94}).addTo(points);
      marker.bindTooltip(`${esc(u.municipio)} · ${group.length} unidade(s)`);
      marker.bindPopup(`<b>${esc(u.municipio)} · ${group.length} unidade(s)</b><br>${group.map(r=>`${esc(r.cnes)} — ${esc(r.tipo)}<br><small>${esc(labels[r.funcao])}</small>`).join('<hr>')}<hr><small>Ponto representativo do município; não é o endereço da unidade.</small>`);
    }
    const located=selectedUnits.filter(u=>u.lat!==null&&u.lon!==null).length;
    const total=paid.reduce((s,p)=>s+Number(p.valor),0);
    document.getElementById('stats').innerHTML=[
      [selectedUnits.length,'unidades no filtro'],[Object.keys(grouped).length,'municípios com unidade'],
      [selectedUnits.length-located,'unidades sem localização'],[current?'—':paid.length,'municípios pagadores'],
      [current?'—':money(total),'MIDES no ano · todas as finalidades']
    ].map(([n,l])=>`<div class="stat"><b>${n}</b><span>${l}</span></div>`).join('');
    const unavailable=current&&entity.grupo!=='84 originais';
    document.getElementById('atlas-notice').textContent=unavailable ?
      'CNES atual não coletado para esta entidade da revisão externa. Selecione 2014–2021 para ver a triagem histórica. O contador vazio não significa ausência de atendimento.' :
      `${current?'Retrato CNES atual; sem pagamento de 2026 neste atlas.':'CNES de dezembro; unidades presentes somente em outros meses não aparecem aqui.'} ${allUnits.length===0?'Não foi localizada unidade diretamente vinculada neste recorte; isso não demonstra capacidade zero. ':''}Pontos são municipais. Unidades móveis não definem destinos fixos nem área de atendimento.`;
    const counts=Object.entries(labels).map(([k,l])=>`${l}: ${allUnits.filter(u=>u.funcao===k).length}`).join(' · ');
    const flagged=paid.filter(p=>p.conflito_credor_mides);
    if(flagged.length)document.getElementById('atlas-notice').textContent+=` Há ${flagged.length} pagamento(s) municipal(is) com conflito entre nome e documento do credor. Valores mantidos; o vínculo precisa de verificação documental.`;
    document.getElementById('atlas-detail').innerHTML=`<h2>${esc(entity.sigla)} · ${esc(period)}</h2>
      <p>${esc(entity.nome)}<br><span class="muted">CNPJ ${esc(entity.cnpj)} · sede cadastral: ${esc(entity.sede)} · ${esc(entity.grupo)}</span></p>
      <p>${esc(counts)}</p><p><b>Tratamento da revisão:</b> ${esc(entity.decisao.replaceAll('_',' '))}</p>
      ${entity.evidencia?`<p>${esc(entity.evidencia)}</p><p class="muted">${esc(entity.limite)}</p>`:''}
      <p class="source">${entity.fonte?`Evidência: ${entity.fonte.split(' | ').map(s=>/^https?:\/\//.test(s)?`<a href="${esc(s)}" target="_blank" rel="noopener">${esc(s)}</a>`:esc(s)).join(' · ')}`:''}</p>
      <div class="actions"><button id="csv">Baixar unidades exibidas (CSV)</button><button id="print">Imprimir visão</button></div>
      <div class="table-wrap"><table><thead><tr><th>CNES</th><th>Município</th><th>Estabelecimento / identificador</th><th>Tipo CNES</th><th>Função</th></tr></thead><tbody>${selectedUnits.map(u=>`<tr><td>${esc(u.cnes)}</td><td>${esc(u.municipio||'Não informado')}</td><td>${esc(u.nome)}</td><td>${esc(u.tipo)}</td><td>${esc(labels[u.funcao])}</td></tr>`).join('')||'<tr><td colspan="5">Nenhuma unidade disponível neste filtro. Leia a ressalva acima.</td></tr>'}</tbody></table></div>
      <p class="source">Fontes: cadastro IPEA; CNM 27/08/2026; MIDES 2014–2021; CNES atual e arquivos ST de dezembro; malha municipal IBGE/geobr já usada no projeto. Nomes históricos são apresentados por código CNES para não atribuir nomes atuais ao passado. A composição CNM é atual, mesmo ao lado de um mapa histórico. O atlas não mostra fluxo de pacientes, rota rodoviária ou cobertura assistencial comprovada.</p>`;
    document.getElementById('csv').onclick=()=>{
      const cols=['cnpj_raiz_8','ano','cnes','municipio','nome','tipo','funcao','fonte'];
      const quote=v=>'"'+String(v??'').replaceAll('"','""')+'"';
      const csv='\ufeff'+[cols,...selectedUnits.map(u=>cols.map(c=>u[c]))].map(r=>r.map(quote).join(';')).join('\r\n');
      const url=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8'})),a=document.createElement('a');a.href=url;a.download=`cnes_${root}_${period}.csv`;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
    };
    document.getElementById('print').onclick=()=>window.print();
  }
  document.getElementById('fit').onclick=()=>{
    const bounds=L.latLngBounds([]);activeCodes.forEach(c=>{if(polygons[c])bounds.extend(polygons[c].getBounds());});
    if(bounds.isValid())map.fitBounds(bounds.pad(.12),{maxZoom:10});else map.fitBounds([[-23.1,-51.2],[-14.2,-39.6]]);
  };
  ['entity','period','function','type','payments','cnm'].forEach(id=>document.getElementById(id).addEventListener('change',draw));
  draw();document.getElementById('fit').click();
}
