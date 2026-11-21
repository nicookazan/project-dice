"""Tres bocetos de nube para reemplazar al vendedor de la tienda (la mano queda como está).

Paleta y construcción de la nube de los jefes (pixel-v3/nube-v3.png): azules de 8 tonos, lóbulos redondos
con el borde claro hacia abajo y blanco en el rastro. Cada boceto es una forma distinta con su animación
(bucle de N cuadros). Escribe PNG y GIF en test-results/vendedor-nube/ (no integra nada en el juego).

Ejecutar:  py -3.13 tools/art/bocetos-vendedor/nubes.py
"""
from __future__ import annotations
import math, os
import numpy as np
from PIL import Image
from scipy import ndimage
import sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from base import scene_layers, W, H

N = 12
TONES = [(7, 66, 163), (12, 78, 202), (28, 103, 240), (43, 130, 251), (71, 154, 249), (109, 183, 250),
         (164, 217, 251), (217, 241, 251)]
YY, XX = np.mgrid[0:H, 0:W]


def h2(x, y, s=0):
    n = (x * 374761393 + y * 668265263 + s * 2246822519) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return (n & 0xFFFF) / 65535.0


def lobe(img, a, cx, cy, r, bands=4, cell=1):
    """Un lóbulo: cuerpo azul medio, más oscuro arriba, con medialuna clara abajo (como la nube de los jefes)."""
    m = (XX - cx) ** 2 + (YY - cy) ** 2 <= r * r
    rel = np.clip((YY - (cy - r)) / (2.0 * r), 0, 1)
    tone = np.where(rel < 0.3, 2, np.where(rel < 0.7, 3, 4))
    s = max(2, int(round(r * 0.2)))
    up = lambda k: (XX - cx) ** 2 + (YY + k - cy) ** 2 <= r * r          # el mismo disco, subido k px
    cres1 = m & ~up(s)
    cres2 = m & ~up(2 * s) & ~cres1
    tone = np.where(cres2, 5, tone)
    tone = np.where(cres1, 6, tone)
    if bands >= 4:
        tone = np.where(m & ~up(max(1, s // 2)), 7, tone)
    ring = m & ~((XX - cx) ** 2 + (YY - cy) ** 2 <= (r - 1.6) ** 2)
    tone = np.where(ring & (YY < cy + 0.35 * r), 1, tone)               # contorno oscuro arriba: separa un lóbulo del otro
    tone = np.where(ring & (YY >= cy + 0.35 * r), 7, tone)              # borde blanco abajo
    for i, c in enumerate(TONES):
        sel = m & (tone == i)
        img[sel] = (*c, 255)
    a[m] = True


def render(lobes, t, cell=1, bands=4, order="y"):
    """lobes: (cx, cy, r, ax, ay, ar, fase). Se pintan de arriba hacia abajo: los de abajo tapan el borde de los de arriba."""
    img = np.zeros((H, W, 4), np.uint8)
    a = np.zeros((H, W), bool)
    ph = 2 * math.pi * t / N
    items = []
    for cx, cy, r, ax, ay, ar, f in lobes:
        items.append((cy, cx + ax * math.sin(ph + f), cy + ay * math.sin(ph + f + 1.1), r + ar * math.sin(ph + f + 2.0)))
    for _, x, y, r in sorted(items, key=lambda z: z[0]):
        lobe(img, a, x, y, r, bands, cell)
    return img, a


def chunky(img, a, cell):
    """Baja la resolución a celdas de `cell` px lógicos (píxeles gruesos, menos densidad)."""
    if cell == 1: return img, a
    h, w = H // cell, W // cell
    small = img[: h * cell : cell, : w * cell : cell]
    sa = a[: h * cell : cell, : w * cell : cell]
    big = np.kron(small, np.ones((cell, cell, 1), np.uint8))
    ba = np.kron(sa, np.ones((cell, cell), bool))
    out = np.zeros_like(img); out[: h * cell, : w * cell] = big
    oa = np.zeros_like(a); oa[: h * cell, : w * cell] = ba
    return out, oa


def outline(img, a, dark=(12, 78, 202)):
    """Contorno de un tono oscuro del mismo azul (como la nube de los jefes)."""
    edge = ndimage.binary_dilation(a, iterations=1) & ~a
    img[edge] = (*dark, 255)
    return img


# ---------- A: cúmulo grande que respira
A_LOBES = [
    (52, 322, 60, 2, 2, 3, 0.0), (122, 320, 50, 2, 1, 3, 1.3), (150, 305, 34, 2, 2, 2, 2.4),
    (38, 252, 48, 2, 2, 3, 3.1), (100, 256, 46, 2, 2, 3, 4.0), (70, 196, 42, 2, 2, 3, 5.0),
    (126, 214, 33, 2, 2, 3, 0.7), (84, 368, 44, 1, 1, 2, 1.9), (150, 352, 34, 1, 1, 2, 2.8)]


def cloud_a(t):
    img, a = render(A_LOBES, t, bands=4)
    img, a = chunky(img, a, 2)
    return outline(img, a), a


# ---------- B: columna que se deshilacha y suelta puffs
B_LOBES = [
    (92, 334, 56, 1, 1, 2, 0.0), (58, 284, 44, 2, 1, 2, 1.0), (124, 292, 42, 2, 1, 2, 2.0),
    (88, 238, 40, 2, 2, 2, 3.0), (112, 190, 32, 3, 2, 2, 4.0), (72, 154, 30, 3, 2, 2, 5.0),
    (98, 118, 20, 3, 3, 2, 1.5), (30, 350, 36, 1, 1, 2, 2.6), (150, 340, 30, 1, 1, 2, 3.6)]


def cloud_b(t):
    img, a = render(B_LOBES, t, bands=4)
    # puffs que suben desde la copa, se achican y desaparecen; el borde superior se deshilacha
    for i in range(4):
        ph = ((t / N) + i / 4.0) % 1.0
        x = 100 + 30 * math.sin(2 * math.pi * (i / 4.0)) + 18 * ph * (1 if i % 2 else -1)
        y = 110 - 90 * ph
        r = 11 * (1 - ph) + 2
        lobe(img, a, x, y, r, 3)
    # deshilachado: sin píxeles sueltos densos; el contorno exterior pierde celdas al azar y varía por cuadro
    edge = a & ~ndimage.binary_erosion(a, iterations=3)
    drop = edge & (np.vectorize(lambda x, y: h2(x // 2, y // 2, t // 2))(XX, YY) < 0.45)
    img[drop] = 0; a = a & ~drop
    img, a = chunky(img, a, 2) if False else (img, a)
    return outline(img, a), a


# ---------- C: banco ancho con corrientes claras que lo recorren
C_LOBES = [
    (38, 346, 52, 2, 1, 2, 0.0), (104, 356, 54, 2, 1, 2, 1.0), (158, 326, 42, 2, 1, 2, 2.0),
    (62, 294, 38, 3, 2, 2, 3.0), (118, 292, 38, 3, 2, 2, 4.0), (162, 286, 24, 2, 2, 2, 5.0),
    (18, 304, 32, 2, 2, 2, 1.7), (84, 262, 24, 3, 2, 2, 2.2)]


def cloud_c(t):
    img, a = render(C_LOBES, t, bands=3)
    # corrientes: bandas diagonales claras que avanzan hacia la derecha (como el rastro de nube-v3)
    shift = (t / N) * 48
    band = ((XX + 0.9 * YY - shift) % 48) < 8
    inner = ndimage.binary_erosion(a, iterations=3)
    img[band & inner & (YY > 280)] = (*TONES[5], 255)
    img, a = chunky(img, a, 1)
    return outline(img, a), a


# ---------- puff chico que recibe la mano que sostiene la tapa
def puff(t, variant):
    img = np.zeros((H, W, 4), np.uint8); a = np.zeros((H, W), bool)
    ph = 2 * math.pi * t / N
    for i, (dx, dy, r) in enumerate([(-8, 8, 13), (8, 10, 12), (0, 20, 14)]):
        lobe(img, a, 253 + dx + 1.5 * math.sin(ph + i), 176 + dy + 1.5 * math.sin(ph + i + 1.1), r + math.sin(ph + i * 2), 3)
    if variant == "A": img, a = chunky(img, a, 2)
    return outline(img, a), a


VARIANTS = {"A": ("Cúmulo que respira", cloud_a), "B": ("Columna que se deshilacha", cloud_b), "C": ("Banco con corrientes", cloud_c)}
CROP = (0, 70, 340, 400)     # x0, y0, x1, y1 en px lógicos


def frame(layers, variant, t):
    bg, mid, hands, band, M = layers
    out = mid.copy(); out.alpha_composite(hands)
    big, _ = VARIANTS[variant][1](t)
    p, _ = puff(t, variant)
    for layer in (p, big):
        # la nube de abajo no pasa del zócalo azul (y>=385): lo tapa la banda
        out.alpha_composite(Image.fromarray(layer))
    out.alpha_composite(band)
    return out


def main():
    layers = scene_layers()
    outdir = "test-results/vendedor-nube"; os.makedirs(outdir, exist_ok=True)
    for v in VARIANTS:
        frames = [frame(layers, v, t) for t in range(N)]
        frames[0].resize((W * 2, H * 2), Image.NEAREST).save(f"{outdir}/{v}-escena.png")
        crops = [f.crop(CROP).resize(((CROP[2] - CROP[0]) * 2, (CROP[3] - CROP[1]) * 2), Image.NEAREST) for f in frames]
        crops[0].save(f"{outdir}/{v}-detalle.png")
        crops[0].save(f"{outdir}/{v}.gif", save_all=True, append_images=crops[1:], duration=150, loop=0, optimize=False)
        print(v, "ok")
    base = layers[1].copy(); base.alpha_composite(layers[2]); base.alpha_composite(layers[3])
    base.crop(CROP).resize(((CROP[2] - CROP[0]) * 2, (CROP[3] - CROP[1]) * 2), Image.NEAREST).save(f"{outdir}/sin-vendedor.png")


if __name__ == "__main__":
    main()
