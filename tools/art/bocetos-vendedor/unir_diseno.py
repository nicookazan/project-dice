"""Arma el overlay final nube+mano a partir del diseño del autor.

- overlay15 (imagen ampliada 4,3×, desde_imagen.py): nube, tiras, volutas y muñeca, tal cual el diseño.
- A la derecha de XS la imagen está cortada, así que ahí van los dedos de la mano original (vendedor.py) y la nube del
  overlay anterior.
- Los hilos oscuros que dejó la madera de fondo dentro de la mano se rellenan con el color de la mano original.
Escribe test-results/vendedor-nube7/overlay-mano.png.

Ejecutar:  py -3.13 tools/art/bocetos-vendedor/unir_diseno.py
"""
from __future__ import annotations
import os, sys
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from base import scene_layers, W, H

XS = 232


def main():
    bg, mid, hands, band, M = scene_layers()
    d = "test-results/vendedor-nube7/"
    a15 = np.array(Image.open(d + "overlay15.png")); a10 = np.array(Image.open(d + "overlay.png"))
    hand = np.array(hands); hm = M["hand_b"]
    dx, dy = 0, -1                                     # encaje de la mano original en el diseño (fix_mano.py)
    sh_hand = np.roll(np.roll(hand, dy, axis=0), dx, axis=1); sh_mask = np.roll(np.roll(hm, dy, axis=0), dx, axis=1)

    def orange(o):
        r, g, b, a = [o[..., i].astype(int) for i in range(4)]
        return (a > 0) & (r - b > 50) & (r > 120)

    out = a15.copy()
    o15 = orange(a15)
    # hilos de fondo dentro de la mano: se cierran y se rellenan con la mano original
    closed = ndimage.binary_fill_holes(ndimage.binary_closing(o15, structure=np.ones((7, 7))))
    gap = closed & (a15[..., 3] == 0) | (closed & ~o15 & (a15[..., 0] < 140))
    fill = gap & sh_mask
    out[fill] = sh_hand[fill]
    out[gap & ~sh_mask & closed] = (200, 110, 50, 255)
    # a la derecha de XS: dedos originales y nube del overlay anterior
    out[:, XS:] = 0
    cloud10 = (a10[..., 3] > 0) & ~orange(a10)
    cloud10[:, :XS] = False
    out[cloud10] = a10[cloud10]
    right = sh_mask.copy(); right[:, :XS] = False
    out[right] = sh_hand[right]
    Image.fromarray(out).save(d + "overlay-mano.png")
    base = mid.copy(); base.alpha_composite(band)
    f = base.copy(); f.alpha_composite(Image.fromarray(out)); f.alpha_composite(band)
    f.crop((0, 236, 270, 340)).resize((270 * 4, 104 * 4), Image.NEAREST).save(d + "mano-detalle.png")
    print("ok")


if __name__ == "__main__":
    main()
