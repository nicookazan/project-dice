"""Quinta tanda: opción C (banco con tiras), con el conjunto nube+mano más alto y la mano fundida con la nube.

La mano se desvanece hacia la nube con un patrón ordenado de píxeles (sin corte recto) y todo el conjunto sube DY px lógicos.
Escribe en test-results/vendedor-nube5/ (no integra nada en el juego).

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


def hands_layer(hands, M, cloud):
    """Manos delante de la nube; el borde izquierdo de la mano que señala se deshace en píxeles de nube."""
    a = shift_up(np.array(hands), DY)
    mb = shift_up(M["hand_b"].astype(np.uint8), DY).astype(bool)
    ma = shift_up(M["hand_a"].astype(np.uint8), DY).astype(bool)
    keep = mb | ma
    a[~keep] = 0
    ys, xs = np.nonzero(mb)
    for y in np.unique(ys):
        row = xs[ys == y]; x0 = row.min()
        for x in row:
            dx = x - x0
            if dx >= FADE: continue
            p = 1.0 - dx / FADE
            if BAYER[y % 4, x % 4] < p * 1.1:
                c = cloud[y, x]
                a[y, x] = c if c[3] > 0 else (*n4.COLS[2], 255)
    return a


def frame(layers, t):
    bg, mid, hands, band, M = layers
    out = mid.copy()
    cloud = cloud_layer(t)
    # la capa de manos entera (con el puño) va debajo de la nube; la mano que señala va delante, ya fundida
    under = Image.fromarray(shift_up(np.array(hands), DY))
    out.alpha_composite(under)
    out.alpha_composite(Image.fromarray(cloud))
    out.alpha_composite(Image.fromarray(hands_layer(hands, M, cloud)))
    out.alpha_composite(band)
    return out


def main():
    layers = scene_layers()
    outdir = "test-results/vendedor-nube5"; os.makedirs(outdir, exist_ok=True)
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
