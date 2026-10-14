"""Prepara o mini dash público sem a aba Modelo, preservando o HTML local."""
from html.parser import HTMLParser
from pathlib import Path
import json
import re
import shutil


HERE = Path(__file__).resolve().parent
SOURCE = HERE / "outputs/visuais_v1"
DEST = HERE / "outputs/visuais_publicos"
STABILITY = HERE / "outputs/estabilidade_mides_saude_mg/index.html"


class Assets(HTMLParser):
    def __init__(self):
        super().__init__()
        self.paths = set()

    def handle_starttag(self, tag, attrs):
        for key, value in attrs:
            if key in {"src", "href"} and value and not value.startswith(("#", "http:", "https:", "data:")):
                self.paths.add(value)


def build():
    html = (SOURCE / "index.html").read_text(encoding="utf-8")
    nav = re.compile(r'<button data-page="modelo"[^>]*>.*?</button>')
    html, count = nav.subn("", html)
    assert count == 1

    start = html.index('<section id="modelo" hidden>')
    end = html.index("</main>", start)
    html = html[:start] + html[end:]
    html = html.replace(" · Modelos: 2019", "")
    html = html.replace(
        "A aba Modelo gravitacional apresenta a ocorrência de pagamento em 2019, com vários vínculos possíveis e três cenários espaciais. O piloto anterior de participações está recolhido para consulta.",
        "Os exercícios de modelagem são analisados separadamente.",
    )

    model_js = (HERE / "modelo_v1.js").read_text(encoding="utf-8")
    assert html.count("\n" + model_js) == 1
    html = html.replace("\n" + model_js, "")
    old_pages = "const pages=['panorama','construcao','pagamentos','capacidade','atlas','consulta','modelo'];"
    assert html.count(old_pages) == 1
    html = html.replace(old_pages, old_pages.replace(",'modelo'", ""))
    nav_end = "</nav>"
    assert html.count(nav_end) == 1
    html = html.replace(nav_end,
        '<a class="report-link" href="estabilidade.html">Trajetórias MIDES</a></nav>')
    html = html.replace("</style>",
        "nav .report-link{display:flex;align-items:center;padding:19px 0 15px;"
        "border-bottom:3px solid transparent;font-size:14px;font-weight:700;"
        "text-decoration:none;color:var(--blue-dark)}"
        "@media(max-width:720px){nav .report-link{grid-column:1/-1;"
        "justify-content:flex-start;border-top:1px solid var(--line);"
        "padding:12px 5px;font-size:12px}}"
        "</style>", 1)

    prefix = '<script type="application/json" id="data">'
    start = html.index(prefix) + len(prefix)
    end = html.index("</script>", start)
    data = json.loads(html[start:end])
    assert "model" in data and len(data["catalog"]) == 5
    del data["model"]
    html = html[:start] + json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/") + html[end:]

    assert '<section id="modelo"' not in html
    assert 'data-page="modelo"' not in html
    assert 'id="mc-validacao"' not in html and 'id="modelo-validacao"' not in html
    assert "A atração relativa reduziu o erro" not in html
    assert "const M=D.model" not in html
    assert 'href="#modelo"' not in html

    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / "index.html").write_text(html, encoding="utf-8")
    report = STABILITY.read_text(encoding="utf-8")
    intro = re.compile(r'<p class="lead">.*?</p>')
    report, count = intro.subn(
        '<p class="lead">Contamos os municípios que pagaram ao menos uma vez '
        'entre 2014 e 2021. Dos 73 consórcios de saúde, só a raiz 02287790 '
        'teve até dois: recebeu de Serra dos Aimorés em sete anos. Os gráficos '
        'mostram também entradas, saídas e pagadores em relação ao valor recebido.</p>',
        report, count=1)
    assert count == 1
    report = report.replace('<a href="#modelos">Modelos A e B</a>', '')
    report = report.replace('<nav><a href="#corte">',
                            '<nav><a href="index.html">Base v1</a><a href="#corte">', 1)
    report = report.replace('grid-template-columns:repeat(4,1fr)',
                            'grid-template-columns:repeat(3,1fr)')
    report = report.replace('<div><strong>0</strong><span>deles entre os 53 ou 62 modelados em 2019</span></div>', '')
    report = report.replace('<article><b>0 nos modelos</b><p>O consórcio não é candidato nos cenários 53/62 de 2019.</p></article>', '')
    report = report.replace(
        'Excluir toda a raiz por causa de 2015 retiraria seus 19 vínculos de 2019 do teste.',
        'Um ano de poucos pagamentos não resume a trajetória de todo o consórcio.')
    start = report.index('<section id="modelos">')
    end = report.index('<section id="consulta">', start)
    report = report[:start] + report[end:]
    start = report.index('<section><div class="eyebrow">Método e limites</div>')
    end = report.index('</main>', start)
    report = report[:start] + (
        '<section><div class="eyebrow">Método e limites</div>'
        '<h2>O que os pagamentos mostram</h2>'
        '<p>Contamos cada município uma vez por consórcio quando houve valor MIDES '
        'positivo em pelo menos um ano de 2014 a 2021. A rotatividade compara '
        'os conjuntos de pagadores em anos consecutivos. Os valores são nominais.</p>'
        '<p>Pagamento observado indica vínculo financeiro, não filiação jurídica '
        'ou atendimento. Oscilações e correlações orientam a revisão dos casos; '
        'nenhum consórcio foi excluído automaticamente da base.</p>'
        '<p>Fonte: MIDES consolidado na base financeira v1 de saúde/MG. '
        'Reprodução: <code>python 45_auditar_estabilidade_mides.py</code> '
        'na pasta técnica do projeto.</p></section>') + report[end:]
    report = report.replace(
        'Dados: MIDES, CNES/DATASUS e Distbrasil. Período financeiro: 2014–2021. Modelos: exercício de 2019.',
        'Dados: MIDES, base financeira v1 de saúde/MG. Período: 2014–2021.')
    assert '<section id="modelos"' not in report
    assert all(term not in report for term in ('Modelo A', 'Modelo B', 'Brier', '53/62',
                                               'reestimado', 'previsões A/B'))
    assert 'CIS/UBA' in report and 'CIAS' in report and '73 raízes' in report
    (DEST / 'estabilidade.html').write_text(report, encoding='utf-8')
    (DEST / ".nojekyll").write_text("", encoding="utf-8")
    for item in (SOURCE / "dados/consulta").glob("*.js"):
        target = DEST / "dados/consulta" / item.name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(item, target)
    assert len(list((DEST / "dados/consulta").glob("*.js"))) == 16
    for figure in data["catalog"]:
        item = SOURCE / "figuras" / (figure["id"] + ".svg")
        target = DEST / "figuras" / item.name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(item, target)

    assets = Assets()
    assets.feed(html)
    assert all((DEST / path).is_file() for path in assets.paths), assets.paths
    assert set(p.stem for p in (DEST / "figuras").glob("*.svg")) == {r["id"] for r in data["catalog"]}
    expected = {Path("index.html"), Path("estabilidade.html"), Path(".nojekyll")}
    expected |= {Path("dados/consulta") / p.name for p in (SOURCE / "dados/consulta").glob("*.js")}
    expected |= {Path("figuras") / (r["id"] + ".svg") for r in data["catalog"]}
    assert {p.relative_to(DEST) for p in DEST.rglob("*") if p.is_file()} == expected
    print(f"Mini dash público pronto: {DEST / 'index.html'}")


if __name__ == "__main__":
    build()
