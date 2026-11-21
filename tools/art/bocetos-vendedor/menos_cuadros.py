"""Bocetos con menos cuadros de animación para la nube del vendedor (versión 2 del video, ya integrada con 40 cuadros).

Se toman cuadros equiespaciados del bucle de 40 y se mantiene cada uno más tiempo, como el resto de las animaciones a
saltos del juego. Escribe en test-results/vendedor-nube14/ (no cambia el juego).

Ejecutar:  py -3.13 tools/art/bocetos-vendedor/menos_cuadros.py <carpeta con f00.png … f39.png>
"""
from __future__ import annotations
import os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import desde_video

# (nombre, paso entre cuadros del bucle de 40, milisegundos por cuadro)
OPCIONES = [("A", 2, 500), ("B", 4, 500), ("C", 5, 600)]


def main(folder):
    layers, still, _ = desde_video.main(folder, v2=True)
    base = Image.open("assets/art/pixel-v3/tienda-v3.png").convert("RGBA")
    hand = Image.fromarray(still)
    out = "test-results/vendedor-nube14"; os.makedirs(out, exist_ok=True)
    def frame(i):
        f = base.copy(); f.alpha_composite(Image.fromarray(layers[i])); f.alpha_composite(hand)
        return f.crop((0, 67, 340, 387)).resize((680, 640), Image.NEAREST)
    for nombre, paso, ms in OPCIONES:
        idx = list(range(0, len(layers), paso))
        frames = [frame(i) for i in idx]
        frames[0].save(f"{out}/{nombre}.gif", save_all=True, append_images=frames[1:], duration=ms, loop=0)
        print(nombre, len(idx), "cuadros de", ms, "ms =", len(idx) * ms / 1000, "s")


if __name__ == "__main__":
    main(sys.argv[1])
