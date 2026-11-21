"""Sexta tanda: opción C (banco con tiras), con el conjunto nube+mano más alto y la mano fundida con la nube.

La mano se desvanece hacia la nube con un patrón ordenado de píxeles (sin corte recto) y todo el conjunto sube DY px lógicos.
Escribe en test-results/vendedor-nube6/ (no integra nada en el juego).

Ejecutar:  py -3.13 tools/art/bocetos-vendedor/nubes5.py
"""
from __future__ import annotations
import os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nubes4 as n4
from base import scene_layers, W, H

DY = 28          # cuánto sube el conjunto
FADE = 16        # ancho (px lógicos) del desvanecido de la mano
BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0


def shift_up(img, dy):
    out = np.zeros_like(img); out[: H - dy] = img[dy:]; return out


def cloud_layer(t):
    lobes = [(x, y - DY, *rest) for x, y, *rest in n4.C]
    img, m = n4.render(lobes, t, base=384 - DY)
    for i, (y, w, ry) in enumerate([(282, 60, 4), (320, 80, 5), (356, 70, 4)]):
        x = (-60 + ((t / n4.N + i / 3.0) % 1.0) * 260)
        mm = ((n4.XC - x) / w) ** 2 + ((n4.YC - (y - DY)) / ry) ** 2 <= 1
        img[mm & m] = (*n4.COLS[0], 255)
    pf, _ = n4.render([(246, 194 - DY, 24, 16, 1.5, 1, 0.0), (268, 200 - DY, 18, 14, 1.5, 1, 2.0), (254, 210 - DY, 24, 11, 1, 1, 4.0)], t)
    out = pf.copy(); out[img[..., 3] > 0] = img[img[..., 3] > 0]
    return out


def block(a, x, y, c, size=2):
    """Bloque de size×size px lógicos (los trazos y motas van en la grilla de 2×2 de la nube)."""
    x, y = int(x) // size * size, int(y) // size * size
    a[max(y, 0): y + size, max(x, 0): x + size] = (*c, 255)


def arc(a, cx, cy, rx, ry, t0, t1, c, thick=1, size=2):
    for k in range(int(max(rx, ry) * abs(t1 - t0) / 1.2) + 2):
        th = t0 + (t1 - t0) * k / max(int(max(rx, ry) * abs(t1 - t0) / 1.2) + 1, 1)
        for w in range(thick):
            block(a, cx + (rx + w * size) * np.cos(th), cy + (ry + w * size) * np.sin(th), c, size)


# volutas de nube que envuelven la mano: (cx, cy, rx, ry, ángulo inicial, final, color, grosor) respecto del puño
CURLS = [(34, 18, 22, 18, 3.3, 5.0, 0, 3), (52, 38, 18, 13, 3.6, 5.3, 2, 3), (76, 12, 18, 13, 0.1, 1.8, 0, 3),
         (48, 54, 26, 15, 0.3, 2.0, 2, 3), (96, 36, 15, 15, 4.2, 5.9, 0, 3), (22, 40, 16, 18, 4.5, 6.2, 2, 3)]


def hands_layer(hands, M, cloud, t):
    """Manos delante de la nube; la mano que señala sale de ella: borde deshilachado en tiras de nube, volutas
    blancas y celestes que la envuelven y motas que titilan."""
    a = shift_up(np.array(hands), DY)
    mb = shift_up(M["hand_b"].astype(np.uint8), DY).astype(bool)
    ma = shift_up(M["hand_a"].astype(np.uint8), DY).astype(bool)
    a[~(mb | ma)] = 0
    ys, xs = np.nonzero(mb)
    x0, y0 = xs.min(), ys.min()
    ph = 2 * np.pi * t / n4.N
    rows_done = set()
    for y in np.unique(ys):
        row = xs[ys == y]; rx0 = row.min()
        # tiras: cada banda de 2 filas se come un largo distinto de la mano, y el largo respira con el cuadro
        strip = n4.h2(np.array([y // 2]), np.array([3]), 4)[0]
        length = 4 + 22 * strip + 3 * np.sin(ph + y * 0.4)
        for x in row:
            if x - x0 < length:
                c = cloud[y, x]
                lit = n4.h2(np.array([x // 2]), np.array([y // 2]), 6)[0]
                a[y, x] = c if c[3] > 0 else (*n4.COLS[0 if lit < 0.65 else 2], 255)
    # volutas
    for cx, cy, rx, ry, t0, t1, col, th in CURLS:
        sweep = 0.35 * np.sin(ph + cx * 0.1)
        arc(a, x0 + cx, y0 + cy, rx, ry, t0 + sweep, t1 + sweep, n4.COLS[col], th)
    # tiras que salen del cuerpo de la nube y se pierden en la mano
    for k in range(5):
        yy = y0 + 4 + k * 13 + int(3 * np.sin(ph + k))
        xx0 = x0 - 20 + int(4 * np.sin(ph * 1 + k * 2.0))
        for xx in range(xx0, xx0 + 34 + 4 * (k % 2), 2):
            block(a, xx, yy, n4.COLS[2 if k % 2 else 3])
            if k % 2 == 0: block(a, xx, yy - 2, n4.COLS[0])
    # motas
    for i in range(9):
        r1 = n4.h2(np.array([i]), np.array([t // 2]), 11)[0]; r2 = n4.h2(np.array([i]), np.array([t // 2]), 12)[0]
        block(a, x0 + 6 + r1 * 118, y0 - 6 + r2 * 56, n4.COLS[0 if i % 3 else 2])
    return a


def frame(layers, t):
    bg, mid, hands, band, M = layers
    out = mid.copy()
    cloud = cloud_layer(t)
    # la capa de manos entera (con el puño) va debajo de la nube; la mano que señala va delante, ya fundida
    under = Image.fromarray(shift_up(np.array(hands), DY))
    out.alpha_composite(under)
    out.alpha_composite(Image.fromarray(cloud))
    out.alpha_composite(Image.fromarray(hands_layer(hands, M, cloud, t)))
    out.alpha_composite(band)
    return out


def main():
    layers = scene_layers()
    outdir = "test-results/vendedor-nube6"; os.makedirs(outdir, exist_ok=True)
    crop = (0, 40, 340, 400)
    sz = ((crop[2] - crop[0]) * 2, (crop[3] - crop[1]) * 2)
    fr = [frame(layers, t) for t in range(n4.N)]
    fr[0].resize((W * 2, H * 2), Image.NEAREST).save(f"{outdir}/C-escena.png")
    cr = [f.crop(crop).resize(sz, Image.NEAREST) for f in fr]
    cr[0].save(f"{outdir}/C-detalle.png")
    cr[0].save(f"{outdir}/C.gif", save_all=True, append_images=cr[1:], duration=130, loop=0)
    print("ok")


if __name__ == "__main__":
    main()
