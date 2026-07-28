"""
_build_standalone.py
Transforma o slide em arquivo unico autocontido:
  1. Embute os 5 PNGs como base64
  2. Adiciona lightbox (clique para zoom) em todas as imagens
  3. Adiciona slide "Recursos" com downloads reais (scripts R) e links file:// (CSVs)
  4. Escreve saida em 2026-05-14_apresentacao_ipea.html (sobrescreve)
"""
import base64, re, os, sys
from urllib.parse import quote as urlquote

sys.stdout.reconfigure(encoding="utf-8")

BASE       = os.path.dirname(os.path.abspath(__file__))
ROOT       = os.path.normpath(os.path.join(BASE, ".."))   # ideiaMides/
html_path  = os.path.join(BASE, "2026-05-14_apresentacao_ipea.html")
assets_dir = os.path.join(BASE, "assets")
logo_path  = os.path.join(BASE, "IPEA-LOGO.png")

# ── helpers ──────────────────────────────────────────────────────────────────

def file_url(path):
    """Converte caminho Windows em URL file:/// para o browser."""
    return "file:///" + path.replace("\\", "/").replace(" ", "%20")

def r_download_uri(path):
    """Le script R e retorna data URI para download inline."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
        return "data:text/plain;charset=utf-8," + urlquote(content)
    except FileNotFoundError:
        return ""

def card(href, download, title, desc, accent=False, icon=""):
    """Gera um card clicavel."""
    title_color = "var(--c-accent)" if accent else "var(--c-fg)"
    link_open  = f'<a href="{href}" download="{download}" target="_blank" style="text-decoration:none;display:block;">' if href else "<div>"
    link_close = "</a>" if href else "</div>"
    cursor     = "cursor:pointer;" if href else ""
    return f"""
                    {link_open}
                    <div style="background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.13);border-radius:5px;padding:0.6vh 0.9vw;{cursor}transition:background .15s;" onmouseover="this.style.background='rgba(255,255,255,.12)'" onmouseout="this.style.background='rgba(255,255,255,.06)'">
                      <div style="font-family:var(--f-mono);font-size:0.7vw;color:{title_color};">{icon}{title}</div>
                      <div style="font-family:var(--f-sans);font-size:0.65vw;color:var(--c-fg-2);margin-top:0.2vh;">{desc}</div>
                    </div>
                    {link_close}"""

# ── caminhos reais ─────────────────────────────────────────────────────────

scripts_dir = os.path.join(ROOT, "scripts")
csv_dir     = os.path.join(ROOT, "outputs", "csv_base")

r_scripts = [
    ("04_pontuacao_mg.R",        "Join MIDES x SICONFI x MUNIC → pontuacao acumulada por fonte (max 9pts)"),
    ("05_painel_universal_mg.R", "Painel universal MIDES U MUNIC → 2.887 pares x 32 variaveis"),
]
viz_script = os.path.join(BASE, "scripts_viz.R")

csvs = [
    ("2026-05-14_painel_universal_mg_v1.csv", "painel_universal_mg_v1.csv", "2.887 pares x 32 variaveis — produto principal triangulado", True),
    ("2026-05-14_csv_base_mides_mg_v2.csv",   "csv_base_mides_mg_v2.csv",  "2.835 pares MIDES x 24 variaveis — com pontuacao", False),
    ("2026-05-13_csv_base_mides_mg_v1.csv",   "csv_base_mides_mg_v1.csv",  "2.835 pares x 15 variaveis — MIDES bruto + geobr + flags", False),
]

# ── monta cards ─────────────────────────────────────────────────────────────

csv_cards = ""
for fname, label, desc, accent in csvs:
    fpath = os.path.join(csv_dir, fname)
    uri   = r_download_uri(fpath)   # mesmo mecanismo dos scripts R
    csv_cards += card(uri, label, label, desc, accent=accent, icon="")

r_cards = ""
for rfile, desc in r_scripts:
    fpath = os.path.join(scripts_dir, rfile)
    uri   = r_download_uri(fpath)
    r_cards += card(uri, rfile, rfile, desc, icon="")

# viz script
viz_uri = r_download_uri(viz_script)
r_cards += card(viz_uri, "scripts_viz.R", "scripts_viz.R", "5 graficos ggplot2 + geobr para a apresentacao", icon="")

# ── slide Recursos ────────────────────────────────────────────────────────────

recursos_slide = f"""
        <!-- slide RECURSOS -->
        <section class="slide dark slide--stats">
          <header class="slide-chrome">
            <span class="label muted" data-anim="fade-in" data-delay="0">RECURSOS</span>
            <span class="label muted" data-anim="fade-in" data-delay="0">R</span>
          </header>
          <div class="slide-body" style="display:flex;flex-direction:column;justify-content:center;padding:2vh 3vw;gap:2vh;">
            <div data-anim="fade-up" data-delay="1">
              <div class="kicker" style="margin-bottom:1.4vh;">OUTPUTS GERADOS — PILOTO MG</div>
              <div style="display:grid;grid-template-columns:1fr 1fr;gap:1.4vh 3vw;">

                <div>
                  <div style="font-family:var(--f-sans);font-size:0.72vw;font-weight:700;color:var(--c-accent);text-transform:uppercase;letter-spacing:.06em;margin-bottom:0.7vh;">Bases de Dados <span style="font-size:0.6vw;opacity:.6;text-transform:none;letter-spacing:0;">(clique para abrir)</span></div>
                  <div style="display:flex;flex-direction:column;gap:0.55vh;">{csv_cards}
                  </div>
                </div>

                <div>
                  <div style="font-family:var(--f-sans);font-size:0.72vw;font-weight:700;color:var(--c-accent);text-transform:uppercase;letter-spacing:.06em;margin-bottom:0.7vh;">Scripts R <span style="font-size:0.6vw;opacity:.6;text-transform:none;letter-spacing:0;">(clique para baixar)</span></div>
                  <div style="display:flex;flex-direction:column;gap:0.55vh;">{r_cards}
                  </div>
                </div>

              </div>
            </div>
          </div>
          <footer class="slide-foot">
            <span class="label muted">Consorcios Publicos · IPEA · 2026</span>
            <span class="label muted">Recursos</span>
          </footer>
        </section>
"""

# ════════════════════════════════════════════════════════════════════════════
#  PIPELINE PRINCIPAL
# ════════════════════════════════════════════════════════════════════════════

with open(html_path, "r", encoding="utf-8") as f:
    html = f.read()

# Remove slide Recursos anterior (se existir) para nao duplicar
html = re.sub(r'<!-- slide RECURSOS -->.*?</section>', '', html, flags=re.DOTALL)

# ── 1. Marca imagens como zoomaveis ─────────────────────────────────────────
html = re.sub(
    r'<img(\s[^>]*src="assets/[^"]+\.png"[^>]*?)(/?>)',
    lambda m: '<img class="img-zoomable"' + m.group(1) + m.group(2)
              if "img-zoomable" not in m.group(0) else m.group(0),
    html
)

# ── 2. Embute PNGs como base64 ───────────────────────────────────────────────
def embed_png(match):
    fname = match.group(1).replace("assets/", "")
    fpath = os.path.join(assets_dir, fname)
    try:
        with open(fpath, "rb") as f:
            b64 = base64.b64encode(f.read()).decode("ascii")
        print(f"  OK {fname}  ({len(b64)//1024} KB base64)")
        return f'src="data:image/png;base64,{b64}"'
    except FileNotFoundError:
        print(f"  SKIP {fpath} nao encontrado")
        return match.group(0)

html = re.sub(r'src="(assets/[^"]+\.png)"', embed_png, html)

# ── 3. Insere slide Recursos ─────────────────────────────────────────────────
last_section_end = html.rfind("</section>")
if last_section_end != -1:
    pos  = last_section_end + len("</section>")
    html = html[:pos] + "\n" + recursos_slide + html[pos:]
    print("  OK Slide Recursos inserido")

# ── 4. Lightbox CSS ───────────────────────────────────────────────────────────
lightbox_css = """
    <!-- Lightbox -->
    <style>
      .lb-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.9);z-index:9999;cursor:zoom-out;align-items:center;justify-content:center;}
      .lb-overlay.open{display:flex!important;}
      .lb-overlay img{max-width:92vw;max-height:92vh;border-radius:6px;box-shadow:0 8px 48px rgba(0,0,0,.7);object-fit:contain;}
      .lb-close{position:fixed;top:2vh;right:2vw;color:#fff;font-size:2rem;cursor:pointer;line-height:1;z-index:10000;opacity:.7;transition:opacity .15s;}
      .lb-close:hover{opacity:1;}
      .img-zoomable{cursor:zoom-in!important;transition:opacity .2s;}
      .img-zoomable:hover{opacity:.88;}
    </style>
"""

# ── 5. Lightbox JS ────────────────────────────────────────────────────────────
lightbox_js = """
  <script>
    (function(){
      function init(){
        var ov=document.createElement('div');
        ov.className='lb-overlay';
        ov.innerHTML='<span class="lb-close">&#x2715;</span><img id="lb-img" src="" alt="zoom">';
        document.body.appendChild(ov);
        ov.addEventListener('click',function(){ov.classList.remove('open');});
        ov.querySelector('.lb-close').addEventListener('click',function(e){e.stopPropagation();ov.classList.remove('open');});
        document.addEventListener('keydown',function(e){if(e.key==='Escape')ov.classList.remove('open');});
        document.querySelectorAll('.img-zoomable').forEach(function(img){
          img.addEventListener('click',function(e){
            e.stopPropagation();
            document.getElementById('lb-img').src=img.src;
            ov.classList.add('open');
          });
        });
      }
      if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);
      else init();
    })();
  </script>
"""

# Evita duplicar se ja existir
if "lb-overlay" not in html:
    html = html.replace("</head>", lightbox_css + "\n  </head>", 1)
    html = html.replace("</body>", lightbox_js + "\n</body>", 1)

# ── 6. Embute IPEA-LOGO.png como base64 ──────────────────────────────────────
if os.path.exists(logo_path):
    with open(logo_path, "rb") as f:
        logo_b64 = base64.b64encode(f.read()).decode("ascii")
    logo_data_uri = f"data:image/png;base64,{logo_b64}"
    # substitui referencia no cover e em qualquer outro lugar
    html = html.replace('src="IPEA-LOGO.png"', f'src="{logo_data_uri}"')
    # normaliza filtro da capa para contorno uniforme fino
    OUTLINE = 'brightness(0) invert(1)'
    html = re.sub(r'(style="height:\d+\.?\d*vw; display:block; filter:)[^"]+(")',
                  r'\g<1>' + OUTLINE + r';\g<2>', html)
    print(f"  OK IPEA-LOGO.png embutida ({len(logo_b64)//1024} KB)")
else:
    logo_data_uri = ""
    print("  SKIP IPEA-LOGO.png nao encontrado")

# ── 7. Logo topo-direita em todos os slides nao-capa ─────────────────────────
# remove logos anteriores (ambos os formatos) antes de re-injetar
html = re.sub(r'<div class="slide-corner-logo"[^>]*>.*?</div>', '', html, flags=re.DOTALL)
html = re.sub(r'<img [^>]*class="slide-foot-logo"[^>]*/?>','', html)
if logo_data_uri:
    OUTLINE_WHITE = 'brightness(0) invert(1)'

    def make_logo_div(filt):
        img_style = f'height:2.2vw;opacity:.92;{("filter:" + filt + ";") if filt else ""}'
        return (
            '<div class="slide-corner-logo" '
            'style="position:absolute;top:1.4vh;right:1.6vw;z-index:20;line-height:0;">'
            f'<img src="{logo_data_uri}" style="{img_style}" alt="IPEA">'
            '</div>'
        )

    def inject_corner(m):
        tag = m.group(0)
        if 'slide--cover' in tag:
            return tag                             # pula capa
        if ' light' in tag:
            return tag + '\n          ' + make_logo_div('')           # sem contorno
        return tag + '\n          ' + make_logo_div(OUTLINE_WHITE)    # contorno branco

    html = re.sub(r'<section class="slide[^"]*"[^>]*>', inject_corner, html)
    print("  OK Logo topo-direita injetada em slides nao-capa")

# ── Salva ─────────────────────────────────────────────────────────────────────
with open(html_path, "w", encoding="utf-8") as f:
    f.write(html)

size_mb = os.path.getsize(html_path) / (1024 * 1024)
n_slides = html.count('class="slide ')
print(f"\nDONE  {html_path}")
print(f"   Tamanho: {size_mb:.1f} MB   Slides: {n_slides}")
