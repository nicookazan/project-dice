"""Nube + mano completa, con la unión dibujada limpia (sin restos de la conversión de la imagen).

1. Del diseño del autor (overlay.png) solo se conserva lo que es nube (blanco y celestes); todo lo demás se descarta.
2. Se pone la mano original entera (vendedor.py, sin tocar) en el lugar que ocupa en el diseño.
3. El borde izquierdo de la mano se deshilacha en tiras de largos distintos que terminan en celeste, y la nube se
   extiende hasta tocarlas, con tiras celestes que siguen hacia la izquierda. Las volutas del diseño que pasan por encima
   de la mano se mantienen.
Escribe test-results/vendedor-nube7/overlay-mano.png.

Ejecutar:  py -3.13 tools/art/bocetos-vendedor/fix_mano.py
"""
from __future__ import annotations
import os, sys
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from base import scene_layers, W, H

WHITE, SOFT, PALE, BLUE = (255, 255, 255, 255), (243, 247, 247, 255), (193, 226, 251, 255), (159, 212, 251, 255)
STRANDS = [5, 8, 13, 17, 14, 10, 6, 9, 15, 20, 16, 11, 7, 4, 8]      # largo (px) de cada tira de 2 filas, de arriba abajo


def main():
    bg, mid, hands, band, M = scene_layers()
    ov = np.array(Image.open("test-results/vendedor-nube7/overlay.png").convert("RGBA"))
    hand = np.array(hands); hm = M["hand_b"]
    r, g, b, a = [ov[..., i].astype(int) for i in range(4)]
    orange = (a > 0) & (r - b > 50) & (r > 120)
    best = None
    for dy in range(-40, 41):
        for dx in range(-30, 31):
            sh = np.roll(np.roll(hm, dy, axis=0), dx, axis=1)
            sc = (sh & orange).sum() / max((sh | orange).sum(), 1)
            if best is None or sc > best[0]: best = (sc, dx, dy)
    _, dx, dy = best
    sh_hand = np.roll(np.roll(hand, dy, axis=0), dx, axis=1)
    sh_mask = np.roll(np.roll(hm, dy, axis=0), dx, axis=1)
    # 1. solo nube del diseño
    cloud = (a > 0) & (r > 140) & (b >= r - 10) & ~orange
    out = np.zeros_like(ov); out[cloud] = ov[cloud]
    ys, xs = np.nonzero(sh_mask)
    y0, y1, x0 = ys.min(), ys.max(), xs.min()
    ys, xs = np.nonzero(sh_mask)
    y0, y1, x0 = ys.min(), ys.max(), xs.min()
    # 2. el cuerpo de la nube no tiene huecos: se cierra y se rellena hasta tocar la mano
    solid = ndimage.binary_closing(out[..., 3] > 0, structure=np.ones((7, 7)))
    solid = ndimage.binary_fill_holes(solid)
    roi = np.zeros((H, W), bool); roi[y0 - 14:y1 + 16, :x0 + 60] = True
    for y in range(y0 - 14, y1 + 16):
        row = np.nonzero(out[y, :x0 + 60, 3])[0]
        if len(row) == 0: continue
        hx = np.nonzero(sh_mask[y])[0]
        right = (hx.min() if len(hx) else x0 + 8) + 6
        for x in range(row.min(), right):
            if out[y, x, 3] == 0:
                out[y, x] = WHITE if (x * 7 + y * 3) % 13 == 0 else SOFT
    # 3. mano original entera; el borde izquierdo la cubre la nube en tiras de largo distinto (cambio suave entre tiras)
    out[sh_mask] = sh_hand[sh_mask]
    for k, y in enumerate(range(y0, y1 + 1, 3)):
        L = STRANDS[k % len(STRANDS)]
        for yy in (y, y + 1, y + 2):
            if yy >= H: continue
            xs_row = np.nonzero(sh_mask[yy])[0]
            if len(xs_row) == 0: continue
            hx = xs_row.min()
            for x in range(hx, hx + L):
                if sh_mask[yy, x]: out[yy, x] = SOFT if (x + yy) % 5 else WHITE
            for x in range(hx + L, hx + L + 3):                           # punta celeste de la tira
                if x < W and sh_mask[yy, x]: out[yy, x] = PALE if x == hx + L else BLUE
        # tira fina celeste que sigue hacia la izquierda desde la punta
        tip = np.nonzero(sh_mask[y + 1])[0]
        if len(tip) and L > 9:
            for x in range(tip.min() - L // 2, tip.min() + 2):
                if x >= 0: out[y + 1, x] = PALE
    # 4. las volutas del diseño que pasaban sobre la mano
    wisp = cloud & sh_mask & (ov[..., 0] > 150)
    out[wisp] = ov[wisp]
    Image.fromarray(out).save("test-results/vendedor-nube7/overlay-mano.png")
    base = mid.copy(); base.alpha_composite(band)
    f = base.copy(); f.alpha_composite(Image.fromarray(out)); f.alpha_composite(band)
    f.crop((100, 230, 270, 340)).resize((170 * 6, 110 * 6), Image.NEAREST).save("test-results/vendedor-nube7/mano-detalle.png")
    print("ok", best)


if __name__ == "__main__":
    main()
