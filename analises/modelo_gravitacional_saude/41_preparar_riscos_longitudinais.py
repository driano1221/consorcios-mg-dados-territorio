"""Prepara escolhas geográficas e riscos financeiros anuais sem alterar a v1.

Executar da pasta do modelo. Covariáveis de capacidade e viagem vêm de t-1.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
import pandas as pd

HERE = Path(__file__).resolve().parent
OUT = HERE / 'outputs/longitudinal_exploratorio'
OUT.mkdir(parents=True, exist_ok=True)
INPUTS = [
    'outputs/base_v1/base_financeira_v1.csv',
    'outputs/base_v1/base_gravitacional_v1.csv',
    'evidencias/decisoes_sicom_2026_09_25.csv',
    'outputs/adesao_financeira/grupos_validacao.csv',
]
DT = {'id_municipio': str, 'cnpj_raiz_8': str, 'cnpj': str}
KEY = ['id_municipio', 'cnpj_raiz_8']

def read(path):
    return pd.read_csv(HERE/path, dtype=DT, low_memory=False)

def sha(path):
    return hashlib.sha256((HERE/path).read_bytes()).hexdigest()

hashes = [sha(p) for p in INPUTS]
f = read(INPUTS[0]).sort_values(KEY+['ano']).reset_index(drop=True)
g = read(INPUTS[1])
dec = read(INPUTS[2])
folds = read(INPUTS[3])
assert len(f) == 491328 and len(g) == 323287
assert f.ano.between(2014,2021).all() and len(f.id_municipio.unique()) == 853
assert not f.duplicated(KEY+['ano']).any() and not g.duplicated(KEY+['ano']).any()
assert (f.valor_total >= 0).all() and (f.populacao_ibge > 0).all()
assert not folds.id_municipio.duplicated().any() and len(folds) == 853

f['pago_original'] = f.valor_total.gt(0).astype(float)
f['pago_auditado'] = f.pago_original.copy()
reject = dec[dec.status.eq('objetos_contradizem_atribuicao_consorcial')].copy()
reject['cnpj_raiz_8'] = reject.cnpj.str[:8]
assert set(zip(reject.id_municipio,reject.cnpj_raiz_8,reject.ano)) == {
    ('3154606','05802877',2014),('3118403','00639952',2019)}
for r in reject.itertuples():
    mask = f.id_municipio.eq(r.id_municipio) & f.cnpj_raiz_8.eq(r.cnpj_raiz_8) & f.ano.eq(r.ano)
    assert mask.sum() == 1 and abs(f.loc[mask,'valor_total'].iloc[0]-r.valor_mides) < .01
    assert f.loc[mask,'pago_original'].iloc[0] == 1 and pd.isna(r.y_auditado)
    f.loc[mask,'pago_auditado'] = np.nan
supported = dec[dec.status.eq('objetos_sustentam_vinculo_financeiro_com_nome_conflitante')]
assert len(supported) == 1
r = supported.iloc[0]
mask = f.id_municipio.eq(r.id_municipio) & f.cnpj_raiz_8.eq(r.cnpj[:8]) & f.ano.eq(r.ano)
assert mask.sum() == 1 and f.loc[mask,'pago_auditado'].iloc[0] == 1
assert abs(f.loc[mask,'valor_total'].iloc[0]-r.valor_mides) < .01
f['pago_estrito'] = f.pago_original.copy()
strict = f.conflito_credor_mides & ~mask
assert f.conflito_credor_mides.sum() == 17 and strict.sum() == 16
assert f.loc[strict,'pago_original'].eq(1).all()
f.loc[strict,'pago_estrito'] = np.nan

group = f.groupby(KEY,sort=False)
f['ano_anterior'] = group.ano.shift(1)
f['populacao_anterior'] = group.populacao_ibge.shift(1)
f['valor_anterior'] = group.valor_total.shift(1)
for version in ('original','auditado','estrito'):
    paid = f[f'pago_{version}']
    positive = paid.eq(1).astype(int)
    unknown = paid.isna().astype(int)
    f[f'pago_anterior_{version}'] = group[f'pago_{version}'].shift(1)
    f[f'positivos_antes_{version}'] = positive.groupby([f[k] for k in KEY]).cumsum()-positive
    f[f'indeterminados_antes_{version}'] = unknown.groupby([f[k] for k in KEY]).cumsum()-unknown
    prior_known = f.ano_anterior.eq(f.ano-1)
    f[f'risco_primeiro_{version}'] = (f.ano.gt(2014) & prior_known &
        f[f'positivos_antes_{version}'].eq(0) & f[f'indeterminados_antes_{version}'].eq(0) &
        paid.notna())
    f[f'risco_continuidade_{version}'] = (f.ano.gt(2014) & prior_known &
        f[f'pago_anterior_{version}'].eq(1) & paid.notna())
    f[f'risco_valor_{version}'] = f.ano.gt(2014) & prior_known & paid.eq(1)

# Desloca somente as características clínicas conhecidas em dezembro de t-1.
prior = g[KEY+['ano','horas_sus_clinicas_soma_registros','tempo_minimo_min']].copy()
prior['ano'] += 1
prior = prior.rename(columns={'horas_sus_clinicas_soma_registros':'horas_anteriores',
                              'tempo_minimo_min':'tempo_anterior_min'})
z = f.merge(prior,on=KEY+['ano'],how='left',validate='one_to_one')
base = z[z.ano.between(2015,2021) & z.ano_anterior.eq(z.ano-1) &
         z.horas_anteriores.gt(0) & z.tempo_anterior_min.notna()].copy()
assert len(base) == 260165 and base.tempo_anterior_min.ge(0).all()
assert base.populacao_anterior.gt(0).all() and not base.duplicated(KEY+['ano']).any()
base['ate180min'] = base.tempo_anterior_min.le(180)
base['ordem_tempo'] = base.groupby(['ano','id_municipio']).tempo_anterior_min.rank(method='min')
base['cinco_proximos'] = base.ordem_tempo.le(5)
base['estadual'] = True
base = base.merge(folds[['id_municipio','municipios','espacial']],on='id_municipio',validate='many_to_one')
assert not base[['municipios','espacial']].isna().any().any()

columns = KEY+['municipio','entidade','ano','valor_total','valor_anterior',
 'populacao_anterior','horas_anteriores','tempo_anterior_min','ordem_tempo',
 'estadual','ate180min','cinco_proximos','municipios','espacial']
for version in ('original','auditado','estrito'):
    columns += [f'pago_{version}',f'pago_anterior_{version}',
        f'positivos_antes_{version}',f'indeterminados_antes_{version}',
        f'risco_primeiro_{version}',f'risco_continuidade_{version}',f'risco_valor_{version}']
base[columns].sort_values(['ano']+KEY).to_csv(OUT/'pares_risco.csv.gz',index=False,compression='gzip')

coverage = []
for version in ('original','auditado','estrito'):
    for rule in ('estadual','ate180min','cinco_proximos'):
        d = base[base[rule]]
        entry = d[d[f'risco_primeiro_{version}']]
        cont = d[d[f'risco_continuidade_{version}']]
        value = d[d[f'risco_valor_{version}']]
        counts = d.groupby(['ano','id_municipio']).size()
        for ano in [0]+list(range(2015,2022)):
            a = d if ano == 0 else d[d.ano.eq(ano)]
            e = entry if ano == 0 else entry[entry.ano.eq(ano)]
            c = cont if ano == 0 else cont[cont.ano.eq(ano)]
            v = value if ano == 0 else value[value.ano.eq(ano)]
            years = 7 if ano == 0 else 1
            coverage.append(dict(versao=version,regra=rule,ano=ano,
                candidatos=len(a),origens_ano=a.groupby(['ano','id_municipio']).ngroups,
                origens_ano_sem_candidato=853*years-a.groupby(['ano','id_municipio']).ngroups,
                alternativas_min=int(counts.min()) if ano == 0 else int(a.groupby('id_municipio').size().min()) if len(a) else 0,
                pagamentos=int(a[f'pago_{version}'].eq(1).sum()),
                risco_primeiro=len(e),primeiros=int(e[f'pago_{version}'].eq(1).sum()),
                risco_continuidade=len(c),continuaram=int(c[f'pago_{version}'].eq(1).sum()),
                interromperam=int(c[f'pago_{version}'].eq(0).sum()),
                pagamentos_com_valor=len(v),valor_nominal=float(v.valor_total.sum())))
pd.DataFrame(coverage).to_csv(OUT/'cobertura_alternativas.csv',index=False)
assert [sha(p) for p in INPUTS] == hashes
pd.DataFrame({'arquivo':INPUTS,'sha256':hashes}).to_csv(OUT/'fontes.csv',index=False)
(OUT/'resumo_preparacao.json').write_text(json.dumps({
 'status':'EXPLORATORIO','anos_resposta':[2015,2021],
 'pares_com_clinica_horas_tempo_no_ano_anterior':len(base),
 'linhas_financeiras_preservadas':len(f),
 'decisoes_indeterminadas_auditado':len(reject),
 'conflitos_indeterminados_estrito':int(strict.sum()),
 'criterio':'Conjunto candidato e covariaveis definidos em t-1; sem reincluir positivos pelo y_t.',
 'limite':'Alternativas geográficas não comprovam elegibilidade jurídica; oferta indireta/móvel ausente.'
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(pd.DataFrame(coverage).query('ano==0').to_string(index=False))
