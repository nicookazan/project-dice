"""Boceto de la animación de la mano (Fase 7): los dedos tamborilean por turnos.

Cada cuadro se arma desde la mano base (test-results/mano-v3.png, de make_mano_dios.py): la yema de cada
dedo (uña y borde incluidos) baja 1 o 2 px y el dedo se estira para no abrir huecos. El dedo mayor se
mueve más que los otros. Ciclo de 8 cuadros: meñique, anular, mayor, índice; el pulgar queda quieto.
Escribe test-results/mano-anim-*.png (cuadros) y GIF de revisión. No integra nada.

Ejecutar:  python tools/art/make_mano_dios.py && python tools/art/make_mano_anim.py
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_lib import upscale

# yemas (x0, x1, y0): todo lo que está debajo de y0 en esa franja de columnas se mueve junto
TIPS = {"menique": (0, 10, 30), "anular": (10, 17, 37), "mayor": (17, 28, 41), "indice": (28, 37, 27)}
ORDER = ["menique", "anular", "mayor", "indice"]
# desplazamiento (px) a lo largo de los 8 cuadros, con 1 cuadro de retraso entre dedos
CURVE = [0, 1, 2, 3, 2, 1, 0, 0]
AMOUNT = {"menique": 2, "anular": 2, "mayor": 3, "indice": 2}


def pose(base: np.ndarray, frame: int) -> np.ndarray:
    out = base.copy()
    for i, name in enumerate(ORDER):
        x0, x1, y0 = TIPS[name]
        d = CURVE[(frame - i) % 8]
        d = min(d, AMOUNT[name])
        if d == 0:
            continue
        h = base.shape[0]
        seg = base[y0:, x0:x1].copy()
        solid = seg[..., 3] > 0
        out[y0:, x0:x1][solid] = 0
        moved = np.zeros_like(seg)
        moved[d:] = seg[:-d]
        # el dedo se estira: las filas que quedaron libres arriba repiten la fila de encima
        for y in range(y0, min(h, y0 + d + 1)):
            pass
        region = out[y0:, x0:x1]
        m = moved[..., 3] > 0
        region[m] = moved[m]
        for j in range(d):
            row_y = y0 + j
            for x in range(x0, x1):
                if out[row_y, x, 3] == 0 and row_y > 0 and out[row_y - 1, x, 3] > 0 and base[row_y, x, 3] > 0:
                    out[row_y, x] = out[row_y - 1, x]
    return out


def main() -> None:
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    base = np.array(Image.open("test-results/mano-v3.png").convert("RGBA"))
    pad = np.zeros((base.shape[0] + 4, base.shape[1], 4), np.uint8)
    pad[:base.shape[0]] = base
    frames = [pose(pad, f) for f in range(8)]
    bg = (30, 60, 130, 255)
    gif = []
    for f in frames:
        im = Image.new("RGBA", (f.shape[1], f.shape[0]), bg)
        im.alpha_composite(Image.fromarray(f))
        gif.append(upscale(im, 6).convert("P", palette=Image.ADAPTIVE))
    gif[0].save("test-results/mano-anim.gif", save_all=True, append_images=gif[1:], duration=110, loop=0)
    sheet = Image.new("RGB", (frames[0].shape[1] * 3 * 4 + 5 * 4, frames[0].shape[0] * 3 * 2 + 5), (20, 30, 70))
    for i, f in enumerate(frames):
        im = Image.new("RGBA", (f.shape[1], f.shape[0]), bg)
        im.alpha_composite(Image.fromarray(f))
        sheet.paste(upscale(im, 3).convert("RGB"), ((i % 4) * (im.width * 3 + 5), (i // 4) * (im.height * 3 + 5)))
        Image.fromarray(f).save(f"test-results/mano-anim-{i}.png")
    sheet.save("test-results/mano-anim-hoja.png")
    strip = np.concatenate(frames, axis=1)
    Image.fromarray(strip).save("assets/art/pixel-v3/mano-v3.png")   # 8 cuadros de 61×53 en fila
    print("ok", len(frames), "cuadros")


if __name__ == "__main__":
    main()
