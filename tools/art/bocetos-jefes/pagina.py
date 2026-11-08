"""Arma la página de bocetos (test-results/bocetos-arte-2/bocetos-arte-2.html) con lo que generan run_manos.py,
paquetes.py y tienda.py. Uso: py -3.13 tools/art/bocetos-jefes/pagina.py"""
import html
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
D = os.path.join(ROOT, "test-results", "bocetos-arte-2")
manos = json.load(open(os.path.join(D, "manos.json"), encoding="utf-8"))
POWER = {
    "l1_kioskero": ("Nivel 1 · Día", "Impuesto al kiosco: cada anotación te cobra $2."),
    "l1_payador": ("Nivel 1 · Día", "Con truco no hay generala: Generala prohibida."),
    "l1_palomas": ("Nivel 1 · Día", "Dado asustado: un dado por mano no se puede conservar en las dos primeras tiradas."),
    "l2_cebador": ("Nivel 2 · Tarde", "Robo del termo: sin termo, los stickers no aportan."),
    "l2_chamuyero": ("Nivel 2 · Tarde", "No te vendo dos veces lo mismo: repetir categoría vale 50 %."),
    "l2_referi": ("Nivel 2 · Tarde", "Tarjeta roja: una moneda queda expulsada."),
    "l3_conde": ("Nivel 3 · Noche", "Fuego apagado: el elemento fuego queda suspendido."),
    "l3_lobizon": ("Nivel 3 · Noche", "Maldición del séptimo hijo: las caras 6 valen 0."),
    "l4_tahur": ("Nivel 4 · Cierre", "Dado cargado: un dado por mano queda fijo en 1."),
    "l4_patovica": ("Nivel 4 · Cierre", "Lista cerrada: Par y Doble par prohibidos."),
    "l4_payaso": ("Nivel 4 · Cierre", "Cara espejo: tras cada tirada un dado pasa a su cara opuesta."),
    "l5_visitante": ("Nivel 5 · Espacio", "Abducción: un dado por mano no cuenta."),
    "l5_farolero": ("Nivel 5 · Espacio", "Carga del anillo: solo se conservan hasta 3 dados."),
    "l5_computadora": ("Nivel 5 · Espacio", "Lo siento, no puedo permitirlo: la categoría de la mano 1 se bloquea en la mano 2."),
    "l6_horizonte": ("Nivel 6 · Agujero negro", "Gravedad: las caras 5 y 6 valen la mitad."),
    "l6_relojero": ("Nivel 6 · Agujero negro", "Tiempo detenido: la ranura de un uso queda inutilizable."),
    "l6_durmiente": ("Nivel 6 · Agujero negro", "Locura: la previsión de puntos se oculta."),
}
CHOSEN = {"l1_kioskero": "B", "l1_payador": "A", "l1_palomas": "B", "l2_cebador": "B", "l2_chamuyero": "B", "l2_referi": "B",
          "l3_conde": "B", "l3_lobizon": "B", "l4_tahur": "B", "l4_patovica": "A", "l4_payaso": "B", "l5_visitante": "A",
          "l5_farolero": "A", "l5_computadora": "B", "l6_horizonte": "A", "l6_relojero": "A", "l6_durmiente": "B"}
RENAME = {"l2_chamuyero": "El Vendedor Ambulante", "l4_tahur": "El Timbero", "l4_payaso": "El Payaso",
          "l5_computadora": "Nombre a elegir (antes La Computadora de Bordo)"}
CHANGED = {
    "l1_palomas": "Cambio pedido: la paloma del pulgar ahora da la vuelta a la ventana como en la opción A; la de la muñeca aletea y vuelve.",
    "l2_cebador": "Cambio pedido: ahora ceba con tu termo. La mano queda entera en todos los cuadros: el termo y el mate están a la derecha, separados del puño, con el termo flotando inclinado como lo marcaste. Al cebar gira hacia afuera y el chorro cae en el mate sin cruzar la mano, el mismo de la mesa y a la escala con la que queda robado. En el juego llevaría tus stickers.",
    "l5_computadora": "Cambio pedido: más textura. Brazo de placas con remaches, rejilla, franja de peligro, pistones, mangueras, rótula con tornillos y pinzas en dos segmentos.",
}
NAME_IDEAS = "Propuestas de nombre: «La Sonda», «El Brazo de la Estación» o «El Androide de Bordo»."
e = html.escape
bosses = []
for m in manos:
    if CHOSEN.get(m["boss"]) != m["op"]:
        continue
    bosses.append((m["boss"], RENAME.get(m["boss"], m["name"]), [m]))

files = set()
out = []
w = out.append


def letra(op):
    return '<span class="letra hoy">HOY</span>' if op == "hoy" else f'<span class="letra">{op}</span>'


w("""<title>Bocetos: jefes y tienda</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Pixelify+Sans:wght@500;700&family=IBM+Plex+Sans:wght@400;600&family=IBM+Plex+Mono:wght@500&display=swap">
<style>
/* Libreta de bocetos sobre el paño, igual que la página anterior: un jefe o un objeto por bloque, la versión de hoy primero y las opciones al lado. Un solo tema oscuro, el del juego. */
:root {
  --noche: #0d1630;
  --panel: #2a0a14;
  --oro: #e8bb4a;
  --marfil: #f4e6c4;
  --apagado: #b9a68c;
  --linea: #6a3e12;
  --display: "Pixelify Sans", "Consolas", monospace;
  --texto: "IBM Plex Sans", "Segoe UI", system-ui, sans-serif;
  --dato: "IBM Plex Mono", "Consolas", monospace;
  color-scheme: dark;
}
body { background: var(--noche); color: var(--marfil); font-family: var(--texto); font-size: 16px; line-height: 1.5; }
main { max-width: 1240px; margin: 0 auto; padding-block: 32px 72px; padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px)); display: grid; grid-template-columns: minmax(0, 1fr); gap: 56px; }
h1, h2, h3 { font-family: var(--display); color: var(--oro); line-height: 1.1; text-wrap: balance; font-weight: 700; margin: 0; }
h1 { font-size: clamp(32px, 6vw, 52px); }
h2 { font-size: 32px; }
h3 { font-size: 22px; font-weight: 500; }
p { margin: 0; max-width: 70ch; }
.intro, .sec { display: grid; gap: 16px; min-width: 0; }
.nota { color: var(--apagado); font-size: 14px; }
.aviso { background: var(--panel); border: 2px solid var(--linea); padding: 14px 18px; display: grid; gap: 6px; }
.toc { display: flex; flex-wrap: wrap; gap: 6px 16px; font-family: var(--dato); font-size: 13px; }
.toc a { color: var(--oro); }
.jefe { display: grid; gap: 12px; padding-top: 20px; border-top: 2px solid var(--linea); min-width: 0; }
.cab { display: flex; flex-wrap: wrap; gap: 4px 14px; align-items: baseline; }
.cab .nivel { font-family: var(--dato); font-size: 13px; color: var(--apagado); }
.poder { color: var(--apagado); font-size: 14px; }
.ops { display: grid; grid-template-columns: minmax(0, 2fr) minmax(0, 3fr); gap: 18px; }
@media (max-width: 700px) { .ops { grid-template-columns: minmax(0, 1fr); } }
figure { margin: 0; display: grid; gap: 8px; align-content: start; min-width: 0; }
figcaption { display: grid; gap: 4px; font-size: 14px; min-width: 0; }
.tit { display: flex; gap: 10px; align-items: baseline; }
.letra { font-family: var(--display); font-size: 20px; color: var(--noche); background: var(--oro); padding: 0 8px; line-height: 1.25; }
.letra.hoy { background: var(--apagado); font-size: 15px; }
.tit b { font-weight: 600; color: var(--marfil); }
img { image-rendering: pixelated; display: block; width: 100%; height: auto; max-width: 100%; }
.ancho { display: grid; gap: 22px; }
.par { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 340px), 1fr)); gap: 18px; }
strong { color: var(--oro); font-weight: 600; }
a:focus-visible { outline: 2px solid var(--oro); outline-offset: 2px; }
</style>
<main>
  <header class="intro">
    <h1>Bocetos: manos de jefe y tienda</h1>
    <p>Segunda tanda, actualizada el 08/11/2026 con tus elecciones. Nada de esto está en el juego. Cada bloque muestra la versión de hoy y la opción elegida; las que pediste cambiar ya vienen corregidas.</p>
    <p><strong>Elegido:</strong> la opción de mano marcada en cada jefe, la bolsita de terciopelo (B) para los paquetes, gancho y etiqueta (A) en el maletín, sin el + de las etiquetas, y bandejas (A) para tus dados y monedas, con la bandeja de monedas rehecha. Nombres nuevos: El Vendedor Ambulante, El Timbero y El Payaso. Falta elegir el nombre de la garra.</p>
    <nav class="toc" aria-label="Secciones"><a href="#manos">Manos de jefe</a><a href="#paquetes">Paquetes de monedas</a><a href="#maletin">Maletín</a><a href="#deposito">Tus dados y monedas</a></nav>
  </header>
  <section class="sec" id="manos" aria-labelledby="h-manos">
    <h2 id="h-manos">1. Manos de jefe</h2>
    <p>Diecisiete jefes; el Gótico y los guardianes de Dios no se tocan. Cada mano parte de la mano original del juego (sus poses de abierta, puño e índice) y suma ropa, textura y un objeto propio. Al hacer clic deja de jugar piedra, papel o tijera y hace algo suyo, como la paloma de tu ejemplo.</p>
    <div class="aviso">
      <p><strong>Cómo leer las animaciones.</strong> Cada GIF muestra la ventana grande del bar a 3× de los píxeles del juego. El primer cuadro es la mano en reposo, que queda así. Lo que sigue es lo que pasa al hacer clic, en bucle, a 110 ms por cuadro. Con «Reducir movimiento» quedaría solo el reposo.</p>
      <p class="nota">Varios objetos salen del recuadro de 61×53 de la mano: la paloma volando, la guitarra, la soga, los tentáculos. En el juego se dibujarían sobre la ventana, delante del cielo y detrás de la mesa.</p>
    </div>
""")
for boss, name, ops in bosses:
    lvl, power = POWER[boss]
    hoy = f"mano-{boss}-hoy.png"
    files.add(hoy)
    w(f"""    <article class="jefe" id="{boss}">
      <div class="cab"><h3>{e(name)}</h3><span class="nivel">{e(lvl)}</span></div>
      <p class="poder">Poder: {e(power)}</p>{('<p><strong>' + e(CHANGED[boss]) + '</strong></p>') if boss in CHANGED else ''}{('<p>' + e(NAME_IDEAS) + '</p>') if boss == 'l5_computadora' else ''}
      <div class="ops">
        <figure><img src="{hoy}" alt="{e(name)}: la mano de hoy" loading="lazy"><figcaption><span class="tit">{letra('hoy')}<b>Mano repintada con un objeto chico</b></span></figcaption></figure>
""")
    for m in ops:
        files.add(m["gif"])
        w(f"""        <figure><img src="{m['gif']}" alt="{e(name)}, opción {m['op']}: {e(m['title'])}" loading="lazy"><figcaption><span class="tit">{letra(m['op'])}<b>{e(m['title'])}</b></span><span>{e(m['desc'])}</span></figcaption></figure>
""")
    w("      </div>\n    </article>\n")
w("  </section>\n")

PACKS = [("hoy", "Hoy", "La bolsa de tela con el número en una etiqueta."),
         ("A", "Cartucho de banco", "Un rollo de papel bordó, como los de las monedas del banco, con la ficha esmaltada asomando en la punta y una etiqueta con el número. El grande son dos rollos."),
         ("B", "Bolsita de terciopelo", "Bolsita azul noche con cordón dorado y un medallón cosido: aro de cobre para el de 2, de oro para el de 5. Del grande asoman dos fichas."),
         ("C", "Pila con faja", "Fichas apiladas de canto, cada una con su aro de rareza, atadas con una faja. El de 2 lleva faja de papel madera y el de 5, faja dorada.")]
w("""  <section class="sec" id="paquetes" aria-labelledby="h-paq">
    <h2 id="h-paq">2. Paquetes de monedas</h2>
    <p>Elegida: bolsita de terciopelo. Chico (2) y grande (5), en la misma celda de 32×32 de las fichas esmaltadas, con el mismo contorno, la misma luz y los aros de rareza. Arriba, a 4× sobre el bordó del maletín. Abajo, en el maletín al tamaño que tienen hoy las monedas (los precios son de ejemplo).</p>
    <div class="par">
""")
for op, title, desc in [x for x in PACKS if x[0] in ("hoy", "B")]:
    files.update({f"paquetes-{op}.png", f"paquetes-{op}-tienda.png"})
    w(f"""      <figure><img src="paquetes-{op}.png" alt="Paquetes de monedas, {e(title)}"><img src="paquetes-{op}-tienda.png" alt="Paquetes de monedas, {e(title)}, en el maletín" loading="lazy"><figcaption><span class="tit">{letra(op)}<b>{e(title)}</b></span><span>{e(desc)}</span></figcaption></figure>
""")
w("    </div>\n  </section>\n")

MAL = [("hoy", "Hoy", "Los objetos y los precios flotan sobre el capitoné."),
       ("A", "Gancho y etiqueta", "Cada oferta cuelga de un ganchito de bronce atornillado al capitoné, con un hilo. El precio va en una etiqueta de cartón que cuelga debajo. Lo vendido deja el gancho con su etiqueta «VENDIDO». Sin el + de arriba: el hilo se ata directo al borde de la etiqueta."),
       ("B", "Repisa de bronce", "Una repisa de madera con borde de bronce por zona. Los objetos se apoyan arriba (el sobre de stickers baja hasta tocarla) y el precio va grabado en una chapita al frente."),
       ("C", "Presilla de cuero", "Como el interior de un portafolios: cada objeto queda sujeto por una presilla de cuero con costura dorada, y el precio va estampado en oro sobre la presilla.")]
w("""  <section class="sec" id="maletin" aria-labelledby="h-mal">
    <h2 id="h-mal">3. Ofertas del maletín</h2>
    <p>Sobre una captura real de la tienda: se recortó cada oferta y se dibujó detrás o delante, en píxeles de 2×2. Imagen a 2× de la pantalla.</p>
    <div class="ancho">
""")
for op, title, desc in [x for x in MAL if x[0] in ("hoy", "A")]:
    f = "tienda-maletin-hoy-zoom.png" if op == "hoy" else f"tienda-maletin-{op}-zoom.png"
    files.add(f)
    w(f"""      <figure><img src="{f}" alt="Maletín, {e(title)}" loading="lazy"><figcaption><span class="tit">{letra(op)}<b>{e(title)}</b></span><span>{e(desc)}</span></figcaption></figure>
""")
w("    </div>\n  </section>\n")

DEP = [("hoy", "Hoy", "Los dados y las monedas compradas flotan sobre el azul."),
       ("A", "Bandejas", "Una bandeja de madera con el paño verde de la mesa para los cinco dados y otra con terciopelo bordó para las monedas, con un hueco por lugar. Rehecha: las monedas van sobre terciopelo liso, sin huecos. Solo la moneda de un uso tiene su hueco con aro dorado, en una bandejita aparte. Los tres marcos son de madera biselada con vivo dorado, esquineros de bronce con tornillo y una tacha en el medio de cada lado largo."),
       ("B", "Huecos en el estuche", "El mismo capitoné azul con huecos hundidos que tienen la forma de cada cosa: cuadrados para los dados, redondos para las monedas. Los vacíos muestran cuánto lugar queda. Es la que menos cambia la barra."),
       ("C", "Repisa", "Un riel de madera y bronce como la repisa del maletín (opción B), donde se apoyan los dados y las monedas.")]
w("""  <section class="sec" id="deposito" aria-labelledby="h-dep">
    <h2 id="h-dep">4. Tus dados y tus monedas</h2>
    <p>La barra azul de abajo de la tienda, a 2× de la pantalla.</p>
    <div class="ancho">
""")
for op, title, desc in [x for x in DEP if x[0] in ("hoy", "A")]:
    f = "tienda-deposito-hoy-zoom.png" if op == "hoy" else f"tienda-deposito-{op}-zoom.png"
    files.add(f)
    w(f"""      <figure><img src="{f}" alt="Tus dados y monedas, {e(title)}" loading="lazy"><figcaption><span class="tit">{letra(op)}<b>{e(title)}</b></span><span>{e(desc)}</span></figcaption></figure>
""")
w("""    </div>
  </section>
</main>
""")
open(os.path.join(D, "bocetos-arte-2.html"), "w", encoding="utf-8").write("".join(out))
json.dump(sorted(files), open(os.path.join(D, "_files.json"), "w"), indent=0)
print(len(files), "archivos")
