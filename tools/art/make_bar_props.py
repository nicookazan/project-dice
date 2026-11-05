"""Sprites de los objetos del bar que reaccionan al clic (etapa de jugabilidad, M4).

Todo parte del arte que ya existe (salón, termo, mate, vaso); nada se redibuja:
  - bandera-v3.png        : la bandera exacta de texturas.bandera (filas 31..118, columnas 640..700 de la grilla lógica);
                            el juego la dibuja fila por fila para ondularla.
  - bandera-fondo-v3.png  : la pared sin bandera en la zona que ocupa (columnas 646..694), para tapar el dibujo fijo
                            mientras la bandera ondula.
  - aro-*.png             : borde dorado de 2 px que sigue la silueta del objeto, en píxeles de pantalla (1440×900).
                            Donde el objeto queda tapado por otro (el termo por el mate o el vaso) el aro no se dibuja.
Se corre con:  py tools/art/make_bar_props.py   (imprime la posición de cada aro para bar_props.gd).
"""
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as nd

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets" / "art" / "pixel-v3"
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / "tools" / "art"))
os.chdir(ROOT)
import make_salon  # noqa: E402
import texturas  # noqa: E402
from pixel_lib import Canvas  # noqa: E402

GOLD = (255, 224, 120, 255)
FLAG_ROWS = (31, 118)
FLAG_COLS = (640, 700)
PATCH_COLS = (646, 694)


def x2(a):
    return np.kron(a, np.ones((2, 2) + (1,) * (a.ndim - 2), a.dtype))


def screen_mask(path, origin):
    """Silueta (alfa > 0) de un sprite lógico, a 2× y puesta en un lienzo de pantalla."""
    a = np.array(Image.open(ART / path).convert("RGBA"))[..., 3] > 0
    a = x2(a)
    canvas = np.zeros((900, 1440), bool)
    h, w = a.shape
    canvas[origin[1]:origin[1] + h, origin[0]:origin[0] + w] = a[:900 - origin[1], :1440 - origin[0]]
    return canvas


def ring_of(mask, remove=None):
    ring = nd.binary_dilation(mask, iterations=2) & ~mask
    if remove is not None:
        ring &= ~remove
    return ring


def save_ring(name, ring):
    ys, xs = np.where(ring)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    out = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
    sub = ring[y0:y1, x0:x1]
    out[sub] = GOLD
    Image.fromarray(out).save(ART / name)
    print("%-22s x=%d y=%d w=%d h=%d" % (name, x0, y0, x1 - x0, y1 - y0))


def main():
    # La bandera exacta, y la pared sin ella.
    flag_canvas = Canvas(720, 150)
    original = texturas.bandera
    original(flag_canvas, 652, 30)
    flag = flag_canvas.a.copy()
    texturas.bandera = lambda *a, **k: None
    wall = np.array(Image.fromarray(make_salon.salon().a).convert("RGB"))
    texturas.bandera = original
    y0, y1 = FLAG_ROWS
    Image.fromarray(flag[y0:y1, FLAG_COLS[0]:FLAG_COLS[1]]).save(ART / "bandera-v3.png")
    Image.fromarray(wall[y0:y1, PATCH_COLS[0]:PATCH_COLS[1]]).save(ART / "bandera-fondo-v3.png")
    print("bandera-v3.png / bandera-fondo-v3.png: filas %d..%d" % (y0, y1))

    thermos = screen_mask("termo-mesa-v3.png", (1203, 168))
    mate = screen_mask("mate-v3.png", (1088, 310))
    cup = screen_mask("vaso-v3.png", (1280, 426))

    # Bandera: de la fila 31 para abajo, y por detrás del termo.
    flag_mask = flag[..., 3] > 0
    flag_mask[:31] = False
    screen_flag = np.zeros((900, 1440), bool)
    screen_flag[:300, :720 * 2] = x2(flag_mask)[:300]
    save_ring("aro-bandera-v3.png", ring_of(screen_flag, thermos))

    # Sifones: lo azulado dentro de su recuadro (el arte del salón a 2×).
    salon = x2(np.array(Image.fromarray(make_salon.salon().a).convert("RGB"))).astype(int)
    for name, bx in (("aro-sifon-izq-v3.png", 384), ("aro-sifon-der-v3.png", 816)):
        box = salon[220:262, bx:bx + 26]
        syphon = (box[..., 2] >= box[..., 0] * .95) & (box[..., 2] > 40)
        syphon[:, 22:] &= box[:, 22:, 1] < 200
        syphon = nd.binary_closing(syphon, iterations=2)
        mask = np.zeros((900, 1440), bool)
        mask[220:262, bx:bx + 26] = syphon
        save_ring(name, ring_of(mask))

    # Termo: por delante de la bandera, por detrás del mate y del vaso.
    save_ring("aro-termo-v3.png", ring_of(thermos, mate | cup))


if __name__ == "__main__":
    main()
