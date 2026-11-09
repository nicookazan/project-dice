"""Arma la página de bocetos de los guardianes de Dios (test-results/bocetos-dios/bocetos-dios.html) con lo que genera
guardianes.py. Uso: py -3.13 tools/art/bocetos-dios/pagina.py"""
import base64
import html
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
D = os.path.join(ROOT, "test-results", "bocetos-dios")
index = json.load(open(os.path.join(D, "index.json"), encoding="utf-8"))
e = html.escape


def uri(name, kind):
    return f"data:image/{kind};base64," + base64.b64encode(open(os.path.join(D, name), "rb").read()).decode()


POWER_TEXT = {
    "ojo": "Dios no juega a los dados: la Generala está prohibida.",
    "figura": "Lo terrenal no cuenta: hierro y cobre quedan suspendidos.",
    "dado": "Ojo que no ve: las carcasas de los puntos quedan suspendidas.",
}
ENCOUNTER = {"ojo": "Encuentro 1 de 3", "figura": "Encuentro 2 de 3", "dado": "Encuentro 3 de 3"}

out = ["""<title>Bocetos: guardianes de Dios</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Pixelify+Sans:wght@500;700&family=IBM+Plex+Sans:wght@400;600&display=swap">
<style>
/* Hoja de bocetos con la noche del juego: un guardián por bloque, hoy a la izquierda y las dos ideas animadas al lado. Un solo tema oscuro. */
:root{--bg:#0e0820;--panel:#1c1040;--line:#4a2f8c;--fg:#f3e6c7;--muted:#b8a8d8;--gold:#f0c850;
--display:"Pixelify Sans","Courier New",monospace;--body:"IBM Plex Sans","Segoe UI",system-ui,sans-serif;color-scheme:dark}
body{background:var(--bg);color:var(--fg);font-family:var(--body);font-size:15px;line-height:1.5}
main{max-width:1240px;margin:0 auto;padding-block:28px 56px;padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px));display:grid;gap:32px}
h1{font-family:var(--display);font-weight:700;font-size:clamp(28px,4vw,42px);margin:0;color:var(--gold);text-wrap:balance}
h2{font-family:var(--display);font-weight:700;font-size:26px;margin:0;color:var(--gold)}
h3{font-family:var(--display);font-weight:500;font-size:19px;margin:0}
.sub{color:var(--muted);margin:6px 0 0;max-width:70ch}
.block{background:var(--panel);border:2px solid var(--line);border-radius:6px;padding:18px;display:grid;gap:14px}
.head{display:flex;flex-wrap:wrap;gap:6px 16px;align-items:baseline}
.tag{font-size:13px;color:var(--muted);letter-spacing:.04em;text-transform:uppercase}
.power{margin:0;color:var(--fg)}
.row{display:grid;grid-template-columns:minmax(0,.8fr) minmax(0,1fr) minmax(0,1fr);gap:16px;align-items:start}
figure{margin:0;display:grid;gap:6px;min-width:0}
figure img{display:block;width:100%;height:auto;image-rendering:pixelated;border:2px solid #04020a;border-radius:3px}
.letter{display:inline-block;min-width:1.6em;text-align:center;font-family:var(--display);font-weight:700;background:var(--gold);color:#04020a;border-radius:3px;margin-right:8px}
.letter.today{background:var(--line);color:var(--fg)}
figcaption{color:var(--muted);font-size:14px}
details summary{cursor:pointer;color:var(--muted);font-size:13px}
details img{margin-top:6px}
.notes{color:var(--muted);max-width:75ch;display:grid;gap:4px;margin:0;padding-left:1.1em}
@media (max-width:820px){.row{grid-template-columns:1fr}}
</style>
<main>
<header><h1>Guardianes de Dios: animación al clic</h1>
<p class="sub">Boceto del 08/11/2026. Son los tres guardianes del nivel 7 (cielo), que todavía no tenían animación propia. Hay dos ideas por guardián, armadas con el mismo dibujo del juego: no se redibuja nada, solo se mueve, se tapa o se ilumina. Cada GIF se ve como en la ventana grande, a 110 ms por cuadro, y termina en la pose de reposo.</p>
<ul class="notes"><li>Hoy, al hacer clic en un guardián se abre su ficha. La idea es que primero haga su animación y la ficha se siga abriendo igual.</li>
<li>Elegí una letra por guardián y decime qué cambiarías.</li></ul></header>
"""]
for gid in ("ojo", "figura", "dado"):
    items = [i for i in index if i["id"] == gid]
    name = items[0]["name"]
    out.append(f'<section class="block"><div class="head"><h2>{e(name)}</h2><span class="tag">{ENCOUNTER[gid]} · {e(items[0]["power"])}</span></div>')
    out.append(f'<p class="power">{e(POWER_TEXT[gid])}</p><div class="row">')
    out.append(f'<figure><img src="{uri(gid + "-hoy.png", "png")}" alt="{e(name)} hoy, sin animación"><figcaption><span class="letter today">HOY</span>Quieto, solo sube y baja.</figcaption></figure>')
    for it in items:
        out.append(f'<figure><img src="{uri(it["gif"], "gif")}" alt="{e(name)}, idea {it["op"]}: {e(it["title"])}">'
                   f'<figcaption><h3><span class="letter">{it["op"]}</span>{e(it["title"])}</h3>{e(it["desc"])} {it["frames"]} cuadros.</figcaption>'
                   f'<details><summary>Ver cuatro cuadros</summary><img src="{uri(gid + "-" + it["op"] + "-cuadros.png", "png")}" alt="Cuatro cuadros de la idea {it["op"]}"></details></figure>')
    out.append("</div></section>")
out.append("</main>")
path = os.path.join(D, "bocetos-dios.html")
open(path, "w", encoding="utf-8").write("\n".join(out))
print(path, os.path.getsize(path) // 1024, "KB")
