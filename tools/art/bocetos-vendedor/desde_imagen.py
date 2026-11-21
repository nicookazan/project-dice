"""Pasa a la grilla lógica (720×450) el diseño que dibujó el autor sobre la escena: nube + mano.

Entrada: la imagen de referencia (recorte ampliado ~3,04× de la escena, con origen (1, 67)). Se compara con la escena sin
nube ni mano; los píxeles que cambian son el arte nuevo. Cada celda lógica toma el color mediano de su bloque y se ajusta
a la paleta existente (nube blanca de la ventana + colores de la mano). Escribe en test-results/vendedor-nube7/.

Ejecutar:  py -3.13 tools/art/bocetos-vendedor/desde_imagen.py <imagen>
"""
from __future__ import annotations
import os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from base import scene_layers, W, H

SCALE, X0, Y0 = 3.04, 1, 67
COLS = [(255, 255, 255), (243, 247, 247), (193, 226, 251), (159, 212, 251), (131, 202, 250)]


def main(path, name="overlay"):
    bg, mid, hands, band, M = scene_layers()
    base = mid.copy(); base.alpha_composite(band)
    B = np.array(base.convert("RGB")).astype(int)
    ref = Image.open(path).convert("RGB")
    w, h = round(ref.width / SCALE), round(ref.height / SCALE)
    big = np.array(ref.resize((w * 4, h * 4), Image.BICUBIC)).astype(int)       # 4 muestras por celda lógica
    cell = big.reshape(h, 4, w, 4, 3)
    med = np.median(cell.transpose(0, 2, 1, 3, 4).reshape(h, w, 16, 3), axis=2).astype(int)
    b = B[Y0:Y0 + h, X0:X0 + w]
    diff = np.abs(med - b).sum(axis=2)
    new = diff > 80
    # paleta: nube + colores de las manos del original
    hand_cols = np.unique(np.array(hands)[(M["hand_b"] | M["hand_a"])][:, :3], axis=0)
    pal = np.vstack([np.array(COLS), hand_cols]).astype(int)
    idx = np.abs(med[:, :, None, :] - pal[None, None, :, :]).sum(axis=3).argmin(axis=2)
    snapped = pal[idx]
    # una mota blanca o celeste suelta sobre la madera cuenta como nube; un píxel naranja suelto no
    from scipy import ndimage
    yy, xx = np.mgrid[0:h, 0:w]
    ax, ay = xx + X0, yy + Y0
    cloudy = (idx < 5) & (med.sum(axis=2) > 480) & (med[:, :, 2] >= med[:, :, 0] - 6)
    hand_roi = (ax > 120) & (ax < 262) & (ay > 235) & (ay < 335)
    hand = (idx >= 5) & hand_roi & new
    hand = ndimage.binary_opening(hand, structure=np.ones((3, 3)))     # quita hilos finos (restos del maletín)
    lab, n = ndimage.label(hand)
    for i in range(1, n + 1):
        if (lab == i).sum() < 25: hand[lab == i] = False
    cloud = ndimage.binary_closing(cloudy & new, structure=np.ones((3, 3)), iterations=1) | (cloudy & new)
    cloud &= ~hand
    cloud = ndimage.binary_opening(cloud, structure=np.ones((2, 2))) | (cloud & ndimage.binary_dilation(hand, iterations=3))
    # huecos dentro de la nube: se rellenan de blanco o celeste, nunca de color de mano
    holes = ndimage.binary_fill_holes(cloud) & ~cloud & ~hand
    snapped = np.where(holes[:, :, None], np.array(COLS[1]), snapped)
    snapped = np.where((cloud & (idx >= 5))[:, :, None], np.array(COLS[1]), snapped)
    new = cloud | hand | holes
    over = np.zeros((H, W, 4), np.uint8)
    over[Y0:Y0 + h, X0:X0 + w, :3] = snapped
    over[Y0:Y0 + h, X0:X0 + w, 3] = np.where(new, 255, 0)
    out = "test-results/vendedor-nube7"; os.makedirs(out, exist_ok=True)
    Image.fromarray(over).save(f"{out}/{name}.png")
    comp = base.copy(); comp.alpha_composite(Image.fromarray(over))
    comp.alpha_composite(band)
    comp.resize((W * 2, H * 2), Image.NEAREST).save(f"{out}/escena.png")
    cr = comp.crop((0, 67, 340, 387)).resize((340 * 3, 320 * 3), Image.NEAREST)
    cr.save(f"{out}/detalle.png")
    # bucle: el conjunto sube y baja en saltos de 2 px, como la nube de los jefes
    frames = []
    for dy in [0, -2, -2, 0, 2, 2, 0, 0]:
        o = np.zeros_like(over); 
        if dy < 0: o[:dy] = over[-dy:]
        elif dy > 0: o[dy:] = over[:-dy]
        else: o = over.copy()
        f = base.copy(); f.alpha_composite(Image.fromarray(o)); f.alpha_composite(band)
        frames.append(f.crop((0, 67, 340, 387)).resize((340 * 2, 320 * 2), Image.NEAREST))
    frames[0].save(f"{out}/bucle.gif", save_all=True, append_images=frames[1:], duration=220, loop=0)
    print("ok", w, h, int(new.sum()), "celdas nuevas")


if __name__ == "__main__":
    # uso: desde_imagen.py <imagen> [nombre] [escala x0 y0]
    if len(sys.argv) > 5: SCALE, X0, Y0 = float(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "overlay")
