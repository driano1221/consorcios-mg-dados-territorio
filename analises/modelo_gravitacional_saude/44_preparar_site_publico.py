"""Prepara o mini dash público sem a aba Modelo, preservando o HTML local."""
from html.parser import HTMLParser
from pathlib import Path
import json
import re
import shutil


HERE = Path(__file__).resolve().parent
SOURCE = HERE / "outputs/visuais_v1"
DEST = HERE / "outputs/visuais_publicos"


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
    expected = {Path("index.html"), Path(".nojekyll")}
    expected |= {Path("dados/consulta") / p.name for p in (SOURCE / "dados/consulta").glob("*.js")}
    expected |= {Path("figuras") / (r["id"] + ".svg") for r in data["catalog"]}
    assert {p.relative_to(DEST) for p in DEST.rglob("*") if p.is_file()} == expected
    print(f"Mini dash público pronto: {DEST / 'index.html'}")


if __name__ == "__main__":
    build()
