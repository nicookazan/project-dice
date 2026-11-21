"""Nube animada y mano del vendedor de la tienda (TX7), a partir del video del autor (versión 2).

  assets/art/pixel-v3/vendedor-nube-v4.png   atlas RGBA: 40 cuadros de la nube, las volutas y los puffs, recortados a la
                                             caja común de todos (8 columnas × 5 filas). Se dibuja a 2× desde (X, Y) de
                                             pantalla; 4 cuadros por segundo, en bucle.
  assets/art/pixel-v3/vendedor-mano-v4.png   la mano original del juego, quieta y con el borde izquierdo cubierto por
                                             nube en tiras; va encima de la nube.
  assets/art/pixel-v3/tienda-v3.png          la tienda sin vendedor (make_tienda.py), con los puños bajo la nube.

El video (gemini_generated_video_76720c46.mp4) está dibujado en la grilla del juego (4 px de video = 1 px lógico), así
que se pasa sin reescalar; ver bocetos-vendedor/desde_video.py (--v2) y guardados/.

Ejecutar (desde cualquier carpeta; trabaja en la raíz del proyecto), con los fotogramas ya extraídos:
  powershell -STA -NoProfile -File tools/art/bocetos-vendedor/extraer_fotogramas.ps1 <video.mp4> <carpeta> 40
  python tools/art/make_vendedor_nube.py <carpeta>
Requiere Python 3.13 con Pillow, numpy y scipy. Imprime las constantes que usa scripts/backdrop.gd.
"""
from __future__ import annotations
import os, sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "bocetos-vendedor"))
os.chdir(os.path.join(HERE, "..", ".."))
import desde_video
import make_tienda

OUT = "assets/art/pixel-v3/"
COLS = 8


def bbox(arrs):
    a = np.any([x[..., 3] > 0 for x in arrs], axis=0)
    ys, xs = np.nonzero(a)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def main(folder: str) -> None:
    layers, still, _cuff = desde_video.main(folder, v2=True)
    x0, y0, x1, y1 = bbox(layers)
    w, h = x1 - x0, y1 - y0
    n = len(layers)
    rows = (n + COLS - 1) // COLS
    atlas = Image.new("RGBA", (w * COLS, h * rows), (0, 0, 0, 0))
    for i, l in enumerate(layers):
        atlas.paste(Image.fromarray(l[y0:y1, x0:x1]), ((i % COLS) * w, (i // COLS) * h))
    atlas.save(OUT + "vendedor-nube-v4.png")
    hx0, hy0, hx1, hy1 = bbox([still])
    Image.fromarray(still[hy0:hy1, hx0:hx1]).save(OUT + "vendedor-mano-v4.png")
    cv = make_tienda.scene()
    cv.save(OUT + "tienda-v3.png")
    print(f"nube: {n} cuadros de {w}x{h}, {COLS} columnas; origen lógico ({x0}, {y0})")
    print(f"mano: {hx1 - hx0}x{hy1 - hy0}; origen lógico ({hx0}, {hy0})")


if __name__ == "__main__":
    main(sys.argv[1])
