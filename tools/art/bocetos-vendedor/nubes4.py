"""Cuarta tanda: nube blanca de las ventanas del salón (la que se ve en el juego).

Cúmulos apilados de lóbulos anchos y chatos: blanco arriba, celestes pálidos abajo de cada lóbulo, sin contorno y
con escalones de 2×2 px lógicos. Los lóbulos de abajo tapan la base de los de arriba, así se marcan los pliegues.
Escribe en test-results/vendedor-nube4/ (no integra nada en el juego).

Ejecutar:  py -3.13 tools/art/bocetos-vendedor/nubes4.py
"""
from __future__ import annotations
import math, os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from base import scene_layers, W, H

N = 16
COLS = [(255, 255, 255), (243, 247, 247), (193, 226, 251), (159, 212, 251), (131, 202, 250)]
CELL = 2
YY, XX = np.mgrid[0:H, 0:W].astype(np.float32)
XC = (XX // CELL) * CELL + CELL / 2
YC = (YY // CELL) * CELL + CELL / 2


def h2(x, y, s=0):
    n = (x.astype(np.int64) * 374761393 + y.astype(np.int64) * 668265263 + s * 2246822519) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return (n & 0xFFFF) / 65535.0


def render(lobes, t, base=None, shade_shift=0.06):
    """lobes: (cx, cy, rx, ry, ax, ay, fase). Se pintan de arriba hacia abajo."""
    ph = 2 * math.pi * t / N
    img = np.zeros((H, W, 4), np.uint8)
    mask = np.zeros((H, W), bool)
    items = []
    for cx, cy, rx, ry, ax, ay, f in lobes:
        items.append((cy, cx + ax * math.sin(ph + f), cy + ay * math.sin(ph + f + 1.3), rx, ry, f))
    for _, x, y, rx, ry, f in sorted(items, key=lambda z: z[0]):
        # borde un poco irregular: el radio horizontal varía con la fila (escalones suaves)
        wob = 1 + 0.05 * np.sin(YC * 0.35 + f)
        m = ((XC - x) / (rx * wob)) ** 2 + ((YC - y) / ry) ** 2 <= 1
        if base is not None: m &= YC < base
        rel = (YC - (y - ry)) / (2 * ry) + shade_shift * math.sin(ph + f)
        tone = np.where(rel < 0.34, 0, np.where(rel < 0.54, 1, np.where(rel < 0.74, 2, np.where(rel < 0.90, 3, 4))))
        for i, c in enumerate(COLS):
            img[m & (tone == i)] = (*c, 255)
        mask |= m
    return img, mask


def tidy_base(img, mask, base):
    """Base casi plana: se corta debajo de `base` con escalones de 6 px de ancho."""
    cut = base + (h2(XC // 6, np.zeros_like(XC), 9) * 6)
    keep = YC < cut
    img[~keep] = 0
    return img


# ---------- A: cúmulo grande apilado
A = [(90, 338, 96, 34, 3, 2, 0.0), (160, 326, 58, 28, 3, 2, 1.5), (56, 292, 66, 30, 3, 2, 3.0),
     (122, 284, 74, 30, 3, 2, 4.4), (86, 240, 60, 28, 3, 2, 5.5), (140, 244, 40, 20, 3, 2, 2.1),
     (102, 202, 40, 22, 3, 3, 0.8), (150, 358, 52, 22, 2, 1, 2.2), (50, 356, 60, 22, 2, 1, 3.7)]


def cloud_a(t):
    img, m = render(A, t, base=382)
    return img


# ---------- B: torre; en la copa se sueltan jirones que suben y se apagan
B = [(100, 340, 92, 32, 2, 2, 0.0), (86, 292, 64, 28, 3, 2, 1.0), (128, 278, 56, 26, 3, 2, 2.0),
     (96, 238, 52, 26, 4, 2, 3.0), (112, 192, 42, 24, 4, 3, 4.0), (90, 150, 34, 20, 4, 3, 5.0),
     (104, 112, 24, 14, 4, 3, 1.5), (162, 334, 38, 22, 2, 2, 3.5),
     (50, 300, 34, 22, 3, 2, 2.6), (140, 236, 30, 20, 3, 2, 4.2), (62, 214, 30, 18, 3, 2, 0.4),
     (136, 196, 26, 16, 4, 2, 5.4), (70, 172, 26, 16, 4, 3, 2.9), (120, 270, 30, 18, 3, 2, 3.3)]


def cloud_b(t):
    img, m = render(B, t, base=382)
    for i in range(4):
        ph = ((t / N) + i / 4.0) % 1.0
        x = 104 + 26 * math.sin(2 * math.pi * i / 4) + 14 * ph * (1 if i % 2 else -1)
        y = 100 - 80 * ph
        rx, ry = 16 * (1 - ph) + 3, 7 * (1 - ph) + 2
        mm = ((XC - x) / rx) ** 2 + ((YC - y) / ry) ** 2 <= 1
        rel = (YC - (y - ry)) / (2 * ry)
        img[mm & (rel < 0.5)] = (*COLS[0], 255)
        img[mm & (rel >= 0.5)] = (*COLS[2], 255)
    return img


# ---------- C: banco ancho; tiras finas de nube lo cruzan de izquierda a derecha
C = [(50, 352, 94, 34, 5, 2, 0.0), (120, 340, 64, 34, 5, 2, 1.6), (150, 316, 32, 26, 4, 2, 3.2),
     (66, 304, 70, 30, 5, 3, 4.5), (124, 292, 54, 28, 5, 3, 0.8), (18, 310, 44, 28, 3, 2, 2.4),
     (96, 268, 40, 18, 4, 2, 5.1)]


def cloud_c(t):
    img, m = render(C, t, base=384)
    for i, (y, w, ry) in enumerate([(282, 60, 4), (320, 80, 5), (356, 70, 4)]):
        x = (-60 + ((t / N + i / 3.0) % 1.0) * 260)
        mm = ((XC - x) / w) ** 2 + ((YC - y) / ry) ** 2 <= 1
        img[mm & m] = (*COLS[0], 255)
    return img


def puff(t):
    img, m = render([(246, 194, 24, 16, 1.5, 1, 0.0), (268, 200, 18, 14, 1.5, 1, 2.0), (254, 210, 24, 11, 1, 1, 4.0)], t)
    return img


VARIANTS = {"A": ("Cúmulo apilado", cloud_a), "B": ("Torre que suelta jirones", cloud_b), "C": ("Banco con tiras", cloud_c)}
CROP = (0, 70, 340, 400)


def front_hands(hands, M):
    a = np.array(hands); a[~(M["hand_b"] | M["hand_a"])] = 0
    return Image.fromarray(a)


def frame(layers, v, t):
    bg, mid, hands, band, M = layers
    out = mid.copy(); out.alpha_composite(hands)
    for layer in (puff(t), VARIANTS[v][1](t)):
        out.alpha_composite(Image.fromarray(layer))
    out.alpha_composite(front_hands(hands, M))
    out.alpha_composite(band)
    return out


def main():
    layers = scene_layers()
    outdir = "test-results/vendedor-nube4"; os.makedirs(outdir, exist_ok=True)
    sz = ((CROP[2] - CROP[0]) * 2, (CROP[3] - CROP[1]) * 2)
    for v in VARIANTS:
        fr = [frame(layers, v, t) for t in range(N)]
        fr[0].resize((W * 2, H * 2), Image.NEAREST).save(f"{outdir}/{v}-escena.png")
        cr = [f.crop(CROP).resize(sz, Image.NEAREST) for f in fr]
        cr[0].save(f"{outdir}/{v}-detalle.png")
        cr[0].save(f"{outdir}/{v}.gif", save_all=True, append_images=cr[1:], duration=130, loop=0)
        print(v, "ok")


if __name__ == "__main__":
    main()
