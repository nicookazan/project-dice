"""Hoja de los elementos animados en la cara de arriba del dado (TX10, D17): assets/art/pixel-v3/elementos-v4.png.

5 elementos (fuego, agua, electricidad, tierra, viento; el orden de Die.ELEMENT_CELLS) × 12 cuadros, celdas de 62×16: la franja
de arriba del dado de 62 px (filas 0 a 15, los puntos empiezan en la fila 15 y el emblema ocupa las filas 3 a 11). Se dibuja en
(0, 0) del control del dado. Cada emblema se define visto desde arriba y se proyecta sobre la cara de arriba real del dado
(tools/art/bocetos-arte/make_bocetos_elementos_persp.py).
El cuadro 0 es un paso calmo del rayo; los pasos de destello caen en los cuadros 10 y 11, y Die los salta con «Reducir destellos».
Uso: py -3.13 tools/art/make_elementos_v4.py
"""
from __future__ import annotations

import importlib.util
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
spec = importlib.util.spec_from_file_location("persp", os.path.join(HERE, "bocetos-arte", "make_bocetos_elementos_persp.py"))
persp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(persp)

OUT = os.path.join(ROOT, "assets", "art", "pixel-v3", "elementos-v4.png")
ORDER = ("fire", "water", "electricity", "earth", "wind")
FRAMES, W, H = 12, 62, 16
OFF = persp.OFF


def main():
    assert tuple(persp.ORDER) == ORDER
    sheet = Image.new("RGBA", (W * FRAMES, H * len(ORDER)), (0, 0, 0, 0))
    for row, element in enumerate(ORDER):
        for i in range(FRAMES):
            t = ((i + 2) % FRAMES) / FRAMES
            cell = persp.overlay(element, t).image().crop((OFF, OFF, OFF + W, OFF + H))
            sheet.alpha_composite(cell, (i * W, row * H))
    sheet.save(OUT)
    prev = os.path.join(ROOT, "test-results")
    os.makedirs(prev, exist_ok=True)
    sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save(os.path.join(prev, "elementos-v4-x3.png"))
    print("ok", sheet.size, "->", OUT)


if __name__ == "__main__":
    main()
