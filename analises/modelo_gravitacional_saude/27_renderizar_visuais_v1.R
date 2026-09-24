# Executar da raiz depois do script 26. Figuras estaticas da entrega aprovada.
invisible(Sys.setlocale('LC_ALL','Portuguese_Brazil.utf8'))
suppressPackageStartupMessages({library(dplyr);library(tidyr);library(ggplot2);library(sf);library(patchwork);library(scales)})
here <- file.path(getwd(),'analises/modelo_gravitacional_saude'); dest <- file.path(here,'outputs/visuais_v1')
dir.create(file.path(dest,'figuras'),recursive=TRUE,showWarnings=FALSE)
z <- readRDS(file.path(dest,'dados/preparacao.rds')); t <- z$tables
blue <- '#2980B9'; red <- '#C0392B'; grey <- '#7F8C8D'; ink <- '#1A252F'
num <- label_number(big.mark='.',decimal.mark=','); pct <- label_percent(accuracy=1,decimal.mark=',')
theme_set(theme_minimal(base_size=13,base_family='Noto Sans') + theme(
  text=element_text(colour=ink),plot.title=element_text(size=22,face='bold',margin=margin(b=12)),
  plot.subtitle=element_text(size=12,colour='#566570',lineheight=1.25,margin=margin(b=22)),
  plot.caption=element_text(size=10,colour='#566570',hjust=0,lineheight=1.2,margin=margin(t=20)),
  plot.title.position='plot',plot.caption.position='plot',plot.margin=margin(22,28,18,22),
  panel.grid.minor=element_blank(),panel.grid.major.x=element_blank(),
  axis.title=element_text(size=11),axis.text=element_text(colour='#45545F'),
  legend.position='bottom',legend.title=element_blank(),strip.text=element_text(face='bold',size=12),
  panel.spacing=grid::unit(1.4,'lines')))
source <- 'Fontes: MIDES e CNES/DATASUS. Período: 2014–2021.'
wrap <- function(x,w=112) stringr::str_wrap(x,width=w)
catalog <- list()
save_plot <- function(p,id,title,question,datafile,section,w=13.5,h=7.8){
  requested <- commandArgs(trailingOnly=TRUE)
  if(!length(requested)||id %in% requested) {
    for(ext in c('png','svg')) ggsave(file.path(dest,'figuras',paste0(id,'.',ext)),p,width=w,height=h,
      dpi=300,bg='white',device=if(ext=='png')ragg::agg_png else svglite::svglite)
    cat('Renderizada:',id,'\n')
  }
  catalog[[length(catalog)+1L]] <<- data.frame(id=id,titulo=title,leitura=question,dados=datafile,secao=section)
}
annotate_plot <- function(p,title,subtitle,limit='') p+labs(title=title,subtitle=wrap(subtitle),caption=paste0(wrap(limit),if(nzchar(limit))'\n' else '',source))
annual <- t$pagamentos_anuais
df <- annual |> select(ano,valor,valor_direto) |> pivot_longer(-ano,names_to='recorte',values_to='valor') |>
  mutate(recorte=recode(recorte,valor='Núcleo de saúde',valor_direto='Recorte direto'))
p <- ggplot(df,aes(ano,valor/1e6,colour=recorte,linetype=recorte))+geom_line(linewidth=1.2)+geom_point(size=2.3)+
  geom_text(data=df |> filter(ano %in% c(2014,2021),recorte=='Núcleo de saúde'),aes(label=num(round(valor/1e6,1))),vjust=-1,size=4,show.legend=FALSE)+
  scale_colour_manual(values=c('Núcleo de saúde'=blue,'Recorte direto'=grey))+scale_linetype_manual(values=c(1,2))+
  scale_x_continuous(breaks=2014:2021)+scale_y_continuous(labels=num,limits=c(0,700))+labs(x=NULL,y='R$ milhões nominais')
p <- annotate_plot(p,'Pagamentos anuais aos consórcios de saúde em MG','Município × consórcio × ano com pagamento positivo. O recorte direto tem clínica cadastrada em dezembro e tempo rodoviário.','Os valores não foram corrigidos pela inflação. As linhas não medem crescimento real.')
save_plot(p,'01_pagamentos_anuais','Pagamentos anuais','A série permite comparar a parcela com polo direto ao conjunto financeiro.','pagamentos_anuais.csv','pagamentos')
for(period in c('2019','2014-2021')){
 d <- t$ranking |> filter(periodo==period,valor>0) |> slice_head(n=15) |> mutate(label=stringr::str_wrap(entidade,30))
 p <- ggplot(d,aes(valor/1e6,reorder(label,valor)))+geom_col(fill=blue,width=.6)+
  geom_text(aes(label=paste0(num(round(valor/1e6,1)),' mi')),hjust=-.12,size=3.6)+
  scale_x_continuous(labels=num,expand=expansion(mult=c(0,.22)))+labs(x='R$ milhões nominais',y=NULL)
 p <- annotate_plot(p,paste('Consórcios com maiores pagamentos em',period),
  paste0('Os 15 primeiros representam ',pct(sum(d$participacao)),' do valor no período. O ranking completo está na tabela de dados.'),
  'Comparação financeira do núcleo v1; os pagamentos não medem produção assistencial.')
 save_plot(p,paste0('02_ranking_',period),paste('Ranking',period),'Identifica a concentração dos valores sem excluir os demais consórcios da tabela.','ranking.csv','pagamentos',h=9.4)
}
d <- t$ranking |> filter(periodo=='2014-2021',valor>0)
p <- ggplot(d,aes(posicao,acumulada))+geom_step(colour=blue,linewidth=1.1)+
 geom_hline(yintercept=c(.5,.8),colour='#BCC7CD',linetype=2)+scale_y_continuous(labels=pct,limits=c(0,1))+labs(x='Consórcios ordenados do maior para o menor pagamento',y='Participação acumulada no valor')
p <- annotate_plot(p,'Concentração dos pagamentos entre consórcios','Núcleo de saúde, 2014–2021. Cada passo acrescenta um consórcio ao valor acumulado.','A ordem usa valores nominais somados no período.')
save_plot(p,'03_concentracao','Concentração dos pagamentos','Mostra quantos consórcios concentram a maior parte do valor observado.','ranking.csv','pagamentos')
top <- head(d$cnpj_raiz_8,12)
d <- t$pagamentos_consorcio_ano |> filter(cnpj_raiz_8 %in% top) |> mutate(entidade=stringr::str_wrap(entidade,25))
p <- ggplot(d,aes(ano,valor/1e6))+geom_line(colour=blue,linewidth=.8)+geom_point(colour=blue,size=1.3)+
 facet_wrap(~entidade,ncol=3)+scale_y_continuous(labels=num,limits=c(0,NA))+scale_x_continuous(breaks=c(2014,2017,2021))+labs(x=NULL,y='R$ milhões nominais, mesma escala')
p <- annotate_plot(p,'Trajetórias dos 12 maiores recebedores no período','Seleção pelo total de 2014–2021. A mesma escala permite comparar magnitudes e variações.','Anos fora da elegibilidade da v1 não são preenchidos com zero.')
save_plot(p,'04_trajetorias','Trajetórias financeiras','Compara consórcios na mesma escala, preservando diferenças de magnitude.','pagamentos_consorcio_ano.csv','pagamentos',h=10)
d <- annual |> select(ano,municipios,consorcios) |> pivot_longer(-ano,names_to='medida',values_to='n') |>
 mutate(medida=recode(medida,municipios='Municípios com pagamento',consorcios='Consórcios que receberam'))
p <- ggplot(d,aes(ano,n))+geom_line(colour=blue,linewidth=1)+geom_point(colour=blue,size=2)+geom_text(aes(label=n),vjust=-.8,size=3.6)+
 facet_wrap(~medida,scales='free_y',ncol=2)+scale_y_continuous(labels=num,expand=expansion(mult=c(.1,.2)))+scale_x_continuous(breaks=c(2014,2016,2018,2021))+labs(x=NULL,y='Contagem de entidades distintas')
p <- annotate_plot(p,'Municípios pagadores e consórcios recebedores por ano','As contagens usam pagamentos positivos no núcleo de saúde. Um município é contado uma vez em cada ano.','Pagamento não comprova filiação jurídica. Os dois painéis têm escalas diferentes.')
save_plot(p,'05_pagadores','Participação financeira anual','Mostra mudanças no número de municípios e consórcios com pagamentos.','pagamentos_anuais.csv','pagamentos')
cov <- data.frame(medida=rep(c('Relações pagas','Valor dos pagamentos'),each=2),grupo=rep(c('Com polo direto','Sem polo direto'),2),
  fracao=c(z$summary$relacoes_diretas/z$summary$relacoes,1-z$summary$relacoes_diretas/z$summary$relacoes,
    z$summary$valor_direto/z$summary$valor,1-z$summary$valor_direto/z$summary$valor))
cov$grupo <- factor(cov$grupo,levels=c('Sem polo direto','Com polo direto'))
p <- ggplot(cov,aes(fracao,medida,fill=grupo))+geom_col(width=.48)+geom_text(aes(label=label_percent(accuracy=.1,decimal.mark=',')(fracao)),position=position_stack(vjust=.5),colour='white',size=6,fontface='bold')+
 scale_fill_manual(values=c('Com polo direto'=blue,'Sem polo direto'='#657884'))+scale_x_continuous(labels=pct,expand=c(0,0))+labs(x=NULL,y=NULL)
p <- annotate_plot(p,'O recorte direto reúne 86,4% dos pagamentos','Ele contém 5.612 das 10.735 relações pagas (52,3%) e R$ 2,865 dos R$ 3,316 bilhões nominais, em 2014–2021.',
 'As outras 5.123 relações permanecem na base financeira. Não localizar polo direto não comprova ausência de atendimento.')
save_plot(p,'06_cobertura','Cobertura das relações e dos valores','Separa quantidade de relações e peso financeiro com denominadores explícitos.','pagamentos_anuais.csv','cobertura',h=6.8)
d <- annual |> select(ano,fracao_relacoes,fracao_valor) |> pivot_longer(-ano,names_to='medida',values_to='fracao') |>
 mutate(medida=recode(medida,fracao_relacoes='Relações pagas',fracao_valor='Valor dos pagamentos'))
p <- ggplot(d,aes(ano,fracao,colour=medida,linetype=medida))+geom_line(linewidth=1.2)+geom_point(size=2.4)+
 scale_colour_manual(values=c('Relações pagas'=grey,'Valor dos pagamentos'=blue))+scale_linetype_manual(values=c(2,1))+
 scale_y_continuous(labels=pct,limits=c(0,1))+scale_x_continuous(breaks=2014:2021)+labs(x=NULL,y='Parcela com polo direto e tempo')
p <- annotate_plot(p,'Cobertura do recorte direto em cada ano','O denominador é o conjunto de pagamentos positivos do núcleo de saúde no respectivo ano.')
save_plot(p,'07_cobertura_anual','Cobertura anual','Mostra como a representatividade do recorte direto muda ao longo do período.','pagamentos_anuais.csv','cobertura')
absence_labels <- function(x) stringr::str_wrap(unname(c(
  movel_regulacao_ou_transporte='Oferta móvel, regulação ou transporte',
  fase_anterior_operacao_samu='Fase anterior à operação do SAMU',
  demais_sem_destino_clinico_suficientemente_documentado='Demais casos sem destino clínico suficientemente documentado',
  redes_indiretas_ou_programas='Redes indiretas ou programas',
  cadastro_intrano_ou_posterior='Cadastro em parte do ano ou posterior',
  historicas_sem_polo='Entidades históricas sem polo')[x]),34)
d <- t$ausencia_polo |> summarise(relacoes=sum(relacoes),valor=sum(valor),.by=grupo_conciliacao)
p <- ggplot(d,aes(relacoes,reorder(absence_labels(grupo_conciliacao),relacoes)))+geom_col(fill=grey,width=.6)+
 geom_text(aes(label=num(relacoes)),hjust=-.15,size=4)+scale_x_continuous(labels=num,expand=expansion(mult=c(0,.15)))+labs(x='Relações município × consórcio × ano pagas',y=NULL)
p <- annotate_plot(p,'Classificação dos pagamentos sem polo direto','Agrupamentos já auditados no projeto; núcleo v1, 2014–2021. Total: 5.123 relações pagas.',
 'As classes descrevem a evidência disponível. Nenhum destino clínico foi imputado a esses casos.')
save_plot(p,'08_ausencia_polo','Classificação da ausência de polo','Distingue situações cadastrais e documentais dentro das relações sem destino direto.','ausencia_polo.csv','cobertura',h=8.8)
flabels <- c(destino_clinico_fixo='Clínica fixa',unidade_movel='Unidade móvel',estrutura_fixa_nao_clinica='Estrutura não clínica')
d <- t$unidades_por_tipo |> filter(ano==2019) |> summarise(unidades=sum(unidades),.by=funcao) |> mutate(funcao=unname(flabels[funcao]))
p <- ggplot(d,aes(unidades,reorder(funcao,unidades)))+geom_col(fill=blue,width=.5)+geom_text(aes(label=unidades),hjust=-.2,size=5)+
 scale_x_continuous(labels=num,expand=expansion(mult=c(0,.15)))+labs(x='Unidades CNES diretamente vinculadas',y=NULL)
p <- annotate_plot(p,'Funções das unidades cadastradas em dezembro de 2019','Entidades elegíveis ao núcleo financeiro v1 em 2019. Inclui unidades móveis e estruturas não clínicas.','As categorias não são somadas para definir a capacidade clínica do recorte direto.')
save_plot(p,'09_funcoes_cnes','Funções das unidades','Permite comparar formas de organização da oferta cadastrada.','unidades_por_tipo.csv','capacidade',h=6.5)
d <- t$unidades_por_tipo |> filter(ano==2019) |> summarise(unidades=sum(unidades),.by=tipo)
p <- ggplot(d,aes(unidades,reorder(stringr::str_wrap(tipo,32),unidades)))+geom_col(fill=blue,width=.6)+geom_text(aes(label=unidades),hjust=-.2,size=4)+
 scale_x_continuous(labels=num,expand=expansion(mult=c(0,.15)))+labs(x='Unidades CNES diretamente vinculadas',y=NULL)
p <- annotate_plot(p,'Tipos de estabelecimento no CNES de dezembro de 2019','Mesmo universo do gráfico de funções: entidades elegíveis ao núcleo financeiro v1 nesse ano.')
save_plot(p,'10_tipos_cnes','Tipos de estabelecimento','Detalha a composição da estrutura cadastrada.','unidades_por_tipo.csv','capacidade',h=8)
metrics <- c(n_destinos_clinicos_dezembro='Unidades clínicas',profissionais_sus_clinicos_soma_unidades='Profissionais SUS',
 servicos_sus_clinicos_soma_unidades='Serviços/classificações SUS',horas_sus_clinicas_soma_registros='Horas SUS cadastradas')
d <- t$capacidade |> filter(ano==2019) |> select(cnpj_raiz_8,entidade,all_of(names(metrics))) |>
 pivot_longer(all_of(names(metrics)),names_to='medida',values_to='valor') |> mutate(medida=factor(unname(metrics[medida]),levels=unname(metrics)))
p <- ggplot(d,aes(valor,0))+geom_boxplot(width=.3,outlier.shape=NA,fill='#EAF3F8',colour=grey)+
 geom_point(position=position_jitter(height=.12,width=0,seed=42),colour=blue,alpha=.65,size=2)+
 facet_wrap(~medida,scales='free_x',ncol=2)+scale_x_continuous(labels=num,limits=c(0,NA),expand=expansion(mult=c(.03,.06)))+
 scale_y_continuous(breaks=NULL)+labs(x='Valor cadastrado por consórcio',y=NULL)+theme(panel.grid.major.y=element_blank())
p <- annotate_plot(p,'Capacidade clínica dos 54 consórcios diretos em 2019','Cada ponto representa um consórcio; a caixa mostra a mediana e a metade central da distribuição. Escalas próprias por medida.',
 'Profissionais e serviços podem repetir entre unidades. Horas cadastradas não são horas anuais realizadas. Leitos não compõem um índice.')
save_plot(p,'11_capacidade_2019','Distribuições da capacidade','Expõe diferenças de escala e concentração sem repetir capacidade por município.','capacidade.csv','capacidade',h=8.6)
d <- t$capacidade |> select(ano,all_of(names(metrics))) |> pivot_longer(-ano,names_to='medida',values_to='valor') |>
 summarise(mediana=median(valor),p25=quantile(valor,.25),p75=quantile(valor,.75),n=n(),.by=c(ano,medida)) |>
 mutate(medida=factor(unname(metrics[medida]),levels=unname(metrics)))
p <- ggplot(d,aes(ano,mediana))+geom_ribbon(aes(ymin=p25,ymax=p75),fill='#C6E0EF')+geom_line(colour=blue,linewidth=1)+geom_point(colour=blue,size=2)+
 facet_wrap(~medida,scales='free_y',ncol=2)+scale_y_continuous(labels=num,limits=c(0,NA))+scale_x_continuous(breaks=c(2014,2016,2018,2021))+labs(x=NULL,y='Mediana e intervalo entre percentis 25 e 75')
p <- annotate_plot(p,'Distribuição da capacidade clínica em cada dezembro','As faixas mostram a metade central dos consórcios em cada ano. O conjunto de entidades varia no período.',
 'São 379 entidades-ano no recorte direto. A mudança da mediana não é uma trajetória de um conjunto fixo de consórcios.')
save_plot(p,'12_capacidade_anual','Capacidade ao longo do período','Resume a distribuição anual sem supor estabilidade da composição.','capacidade.csv','capacidade',h=8.5)
d <- t$multiarea |> filter(ano==2019) |> mutate(entidade=ifelse(grepl('CONVALES',entidade,ignore.case=TRUE),'CONVALES',entidade)) |>
 select(entidade,unidades,profissionais,servicos,horas) |> pivot_longer(-entidade,names_to='medida',values_to='valor') |>
 mutate(medida=recode(medida,unidades='Unidades clínicas',profissionais='Profissionais SUS',servicos='Serviços/classificações SUS',horas='Horas SUS cadastradas'))
p <- ggplot(d,aes(valor,entidade))+geom_segment(aes(x=0,xend=valor,yend=entidade),colour='#C6D6DF',linewidth=2,na.rm=TRUE)+geom_point(colour=blue,size=3,na.rm=TRUE)+
 geom_text(data=d |> filter(!is.na(valor)),aes(label=num(valor)),hjust=-.25,nudge_y=.12,vjust=0,size=3.5)+
 geom_text(data=d |> filter(is.na(valor)),aes(x=0,label='Sem clínica direta em dezembro'),hjust=0,colour=grey,size=3.1)+
 facet_wrap(~medida,scales='free_x',ncol=2)+scale_x_continuous(labels=num,limits=c(0,NA),expand=expansion(mult=c(.02,.4)),
 breaks=function(lim){x<-pretty(lim,n=4);if(max(lim)<=4)x[x==floor(x)] else x})+labs(x='Capacidade clínica cadastrada',y=NULL)
p <- annotate_plot(p,'Comparação auxiliar de consórcios multiárea','CISREC, CONVALES e CIMBAJE, dezembro de 2019. Mesma escala entre entidades dentro de cada medida.',
 'Os três permanecem fora do núcleo financeiro v1. Sem clínica direta significa capacidade clínica não identificada neste recorte, não capacidade zero.')+
 labs(caption='Os três permanecem fora do núcleo v1. Sem clínica direta indica ausência de identificação neste recorte, não capacidade zero.\nFonte: CNES/DATASUS, dezembro/2019; classificação documental do projeto.')
save_plot(p,'13_multiarea','Comparação multiárea','Permite observar perfis sem incorporar essas entidades silenciosamente ao núcleo.','multiarea.csv','capacidade',h=8)
d <- bind_rows(t$tempos_distribuicao |> mutate(painel='Distribuição completa'),
  t$tempos_distribuicao |> filter(faixa>=240) |> mutate(painel='Detalhe dos tempos a partir de 240 min')) |>
  mutate(painel=factor(painel,levels=c('Distribuição completa','Detalhe dos tempos a partir de 240 min')))
p <- ggplot(d,aes(faixa,relacoes))+geom_col(fill=blue,width=28,just=0)+
 facet_wrap(~painel,scales='free',ncol=2)+scale_x_continuous(breaks=seq(0,900,120),expand=expansion(mult=c(0,.02)))+
 scale_y_continuous(labels=num)+labs(x='Menor tempo rodoviário (minutos); intervalos de 30 min',y='Relações pagas')
p <- annotate_plot(p,'Tempos até o município clínico mais próximo','5.612 relações pagas com polo direto e tempo, 2014–2021. Toda a distribuição está representada.',
 'O detalhe usa outra escala vertical e repete a cauda, sem somá-la ao total. Tempo zero indica o mesmo município, não deslocamento local nulo.')
save_plot(p,'14_tempos_distribuicao','Distribuição dos tempos','Mostra concentração e cauda da distribuição sem remover extremos.','tempos_distribuicao.csv','tempos')
d <- t$tempos_acumulada |> select(tempo_minimo_min,fracao_relacoes,fracao_valor) |> pivot_longer(-tempo_minimo_min,names_to='medida',values_to='fracao') |>
 mutate(medida=recode(medida,fracao_relacoes='Relações pagas',fracao_valor='Valor dos pagamentos'))
p <- ggplot(d,aes(tempo_minimo_min,fracao,colour=medida,linetype=medida))+geom_step(linewidth=1)+
 scale_colour_manual(values=c('Relações pagas'=blue,'Valor dos pagamentos'=grey))+scale_linetype_manual(values=c(1,2))+
 scale_y_continuous(labels=pct,limits=c(0,1))+scale_x_continuous(breaks=seq(0,900,120))+labs(x='Menor tempo rodoviário (minutos)',y='Parcela acumulada até esse tempo')
p <- annotate_plot(p,'Relações e pagamentos acumulados por tempo rodoviário','A curva indica quanto do recorte direto está até cada tempo. As duas medidas usam as mesmas 5.612 relações.',
 'Ponderar por valor financeiro não equivale a ponderar por pacientes ou viagens.')
save_plot(p,'15_tempos_acumulada','Tempos acumulados','Permite comparar a distribuição das relações à distribuição do dinheiro.','tempos_acumulada.csv','tempos')
d <- t$tempos_consorcio |> mutate(label=paste0(entidade,' (n=',n,')'),label=factor(label,levels=label))
p <- ggplot(d,aes(mediana,label))+geom_linerange(aes(xmin=p25,xmax=p75),colour='#B7CCD8',linewidth=2)+geom_point(colour=blue,size=2)+
 scale_x_continuous(labels=num,limits=c(0,NA))+labs(x='Minutos: ponto = mediana; faixa = percentis 25 a 75',y=NULL)
p <- annotate_plot(p,'Tempos rodoviários por consórcio','Relações pagas do recorte direto, 2014–2021. n é a quantidade de relações município × consórcio × ano.',
 'A comparação é descritiva; consórcios têm composições territoriais diferentes. Extremos completos disponíveis em CSV.')
save_plot(p,'16_tempos_consorcio','Comparação dos tempos','Mostra diferenças entre consórcios e a dispersão central dos tempos.','tempos_consorcio.csv','tempos',w=13.5,h=15)
# Mapa de exemplo com tabela lateral, ambas derivadas do mesmo recorte.
geom <- z$geom
d <- t$pagamentos_consorcio_ano |> filter(cnpj_raiz_8=='05802877',ano==2019)
a <- jsonlite::fromJSON(file.path(dest,'dados/visuais.json'))
codes <- a$payments |> filter(cnpj_raiz_8=='05802877',ano==2019) |> pull(codigo_ibge_6)
u <- z$units |> filter(cnpj_raiz_8=='05802877',ano=='2019',funcao=='destino_clinico_fixo') |> arrange(codigo_ibge_6)
mg <- geom |> mutate(pago=code %in% codes)
b <- st_bbox(mg |> filter(pago)); pad <- .1*max(b$xmax-b$xmin,b$ymax-b$ymin)
pm <- ggplot(mg)+geom_sf(aes(fill=pago),colour='#CDD7DD',linewidth=.15)+scale_fill_manual(values=c('FALSE'='#F7F9FA','TRUE'='#9FC8E0'))+
 geom_point(data=u,aes(x,y),colour=red,size=4)+geom_text(data=u,aes(x,y,label=municipio),nudge_y=10000,colour=ink,fontface='bold',size=4)+
 coord_sf(xlim=c(b$xmin-pad,b$xmax+pad),ylim=c(b$ymin-pad,b$ymax+pad),datum=NA)+theme_void()+theme(legend.position='none')
side <- paste0('CISMEP, 2019\n\n',num(d$pagadores),' municípios pagadores\nR$ ',label_number(accuracy=.01,big.mark='.',decimal.mark=',')(d$valor/1e6),' milhões nominais\n\nClínicas em dezembro\n',paste(paste0(u$municipio,' · CNES ',u$cnes),collapse='\n'),
 '\n\nProfissionais SUS: ',num(d$profissionais_sus_clinicos_soma_unidades),'\nServiços/classificações SUS: ',num(d$servicos_sus_clinicos_soma_unidades),'\nHoras SUS cadastradas: ',num(d$horas_sus_clinicas_soma_registros))
ps <- ggplot()+annotate('text',x=0,y=1,label=side,hjust=0,vjust=1,size=4.1,lineheight=1.5,family='Noto Sans')+xlim(0,1)+ylim(0,1)+theme_void()
pl <- ggplot()+annotate('rect',xmin=0,xmax=.025,ymin=.3,ymax=.7,fill='#9FC8E0')+annotate('text',x=.04,y=.5,label='Município pagador',hjust=0,size=3.4)+
 annotate('point',x=.5,y=.5,colour=red,size=3)+annotate('text',x=.53,y=.5,label='Município com clínica',hjust=0,size=3.4)+xlim(0,1)+ylim(0,1)+theme_void()
# Paineis de texto evitam o merge de temas incompativel de patchwork 1.3.0/ggplot2 4.
pt <- ggplot()+annotate('text',x=0,y=.75,label='Pagamentos ao CISMEP e clínicas cadastradas em 2019',hjust=0,size=6,fontface='bold',family='Noto Sans')+
 annotate('text',x=0,y=.20,label='O mapa aproxima relações financeiras e estrutura direta do mesmo ano.',hjust=0,size=3.8,colour='#566570',family='Noto Sans')+
 xlim(0,1)+ylim(0,1)+theme_void()
pc <- ggplot()+annotate('text',x=0,y=.9,hjust=0,vjust=1,size=3.1,family='Noto Sans',colour='#566570',
 label=paste('Pontos representativos municipais, sem indicar endereço ou fluxo de pacientes. Projeção EPSG:5880.\n',source))+
 xlim(0,1)+ylim(0,1)+theme_void()
p <- (pt+pm+ps+pl+pc)+plot_layout(design='AA\nBC\nDC\nEE',widths=c(2,1),heights=c(.8,5.5,.45,.7),guides='keep')
map_data <- st_drop_geometry(mg) |> select(code,name,pago) |>
 left_join(a$payments |> filter(cnpj_raiz_8=='05802877',ano==2019) |> select(codigo_ibge_6,valor),by=c('code'='codigo_ibge_6')) |>
 left_join(u |> summarise(cnes=paste(cnes,collapse=' | '),.by=codigo_ibge_6),by=c('code'='codigo_ibge_6'))
readr::write_excel_csv2(map_data,file.path(dest,'dados/mapa_cismep_2019.csv'),na='')
save_plot(p,'17_mapa_cismep_2019','CISMEP no território','Conecta um caso real à leitura financeira e cadastral.','mapa_cismep_2019.csv','atlas',w=15,h=8.5)
# Atualizacao dos dois mapas diagnosticos do universo original.
orig <- z$entities |> filter(grupo=='84 originais')
normal <- function(x) toupper(stringi::stri_trans_general(x,'Latin-ASCII'))
seat <- orig |> mutate(key=normal(sede)) |> left_join(st_drop_geometry(geom) |> mutate(key=normal(name)) |> select(key,x,y),by='key',relationship='many-to-one') |>
 mutate(com_mides=raiz %in% unique(jsonlite::fromJSON(file.path(here,'outputs/atlas_dados.json'))$payments$cnpj_raiz_8))
stopifnot(nrow(seat)==84,!anyNA(seat$x),sum(seat$com_mides)==66)
p <- ggplot(geom)+geom_sf(fill='#F7F9FA',colour='#D3DCE1',linewidth=.12)+geom_point(data=seat,aes(x,y,colour=com_mides,shape=com_mides),size=3,alpha=.85)+
 scale_colour_manual(values=c('FALSE'=grey,'TRUE'=blue),labels=c('18 sem pagamento observado','66 com pagamento observado'))+
 scale_shape_manual(values=c('FALSE'=1,'TRUE'=16),labels=c('18 sem pagamento observado','66 com pagamento observado'))+coord_sf(datum=NA)+theme(legend.position='bottom',axis.title=element_blank(),axis.text=element_blank(),panel.grid=element_blank())
p <- annotate_plot(p,'Presença no MIDES das 84 entidades originais','Sedes cadastrais do universo inicial, com pagamentos observados em 2014–2021. Este mapa não representa o universo ampliado da v1.')+
 labs(caption='Mais de uma entidade pode ter sede no mesmo município. Pontos representativos municipais.\nFontes: cadastro IPEA, MIDES 2014–2021 e malha IBGE/geobr.')
readr::write_excel_csv2(seat |> select(raiz,sigla,sede,com_mides,x,y),file.path(dest,'dados/mapa_universo_original.csv'))
save_plot(p,'18_mapa_universo_original','Universo original e MIDES','Situa a triagem inicial sem confundi-la com o universo financeiro v1.','mapa_universo_original.csv','atlas',h=9)
u <- z$units |> filter(ano=='atual',!is.na(x)) |> count(codigo_ibge_6,x,y,funcao,name='n') |> mutate(funcao=unname(flabels[funcao]))
p <- ggplot(geom)+geom_sf(fill='#F7F9FA',colour='#D3DCE1',linewidth=.08)+geom_point(data=u,aes(x,y,size=n),colour=blue,alpha=.65)+
 facet_wrap(~funcao,ncol=2)+scale_size_area(max_size=9,breaks=c(1,5,20,50),name='Unidades por município')+coord_sf(datum=NA)+
 theme(axis.title=element_blank(),axis.text=element_blank(),panel.grid=element_blank())
p <- annotate_plot(p,'Unidades CNES das 84 entidades originais em 2026','Coleta de 03/09/2026 e classificação de 16/09/2026. São 669 das 670 unidades localizadas no mapa.',
 'A unidade móvel CNES 5563003 não tem município no cache. Pontos são municipais; unidades móveis não representam destinos fixos.')+
 labs(caption='A unidade móvel CNES 5563003 não tem município no cache. Pontos municipais; móveis não são destinos fixos.\nFontes: CNES/DATASUS, coleta de 03/09/2026; malha IBGE/geobr.')
readr::write_excel_csv2(z$units |> filter(ano=='atual'),file.path(dest,'dados/mapa_cnes_atual.csv'),na='')
save_plot(p,'19_mapa_cnes_atual','CNES atual do universo original','Preserva a fotografia de 2026 separada do histórico usado na v1.','mapa_cnes_atual.csv','atlas',w=14,h=11)
# Mantem os caminhos historicos apontando para as versoes revistas.
file.copy(file.path(dest,'figuras/18_mapa_universo_original.png'),file.path(here,'outputs/figuras/mapa_entidades_saude_mg_presenca_mides.png'),overwrite=TRUE)
file.copy(file.path(dest,'figuras/19_mapa_cnes_atual.png'),file.path(here,'outputs/figuras/mapa_unidades_cnes_saude_mg_por_funcao.png'),overwrite=TRUE)
readr::write_excel_csv2(bind_rows(catalog),file.path(dest,'dados/catalogo_figuras.csv'))
jsonlite::write_json(bind_rows(catalog),file.path(dest,'dados/catalogo_figuras.json'),dataframe='rows',auto_unbox=TRUE)
cat('Total:',length(catalog),'figuras, em PNG 300 dpi e SVG.\n')
