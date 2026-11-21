"""Bocetos de las tres estrellas clicables del cuadro de la copa (salón) y del confeti de victoria.

Estrellas: tres maneras de verse apagadas y encendidas (secuencia 0, 1, 2 y 3 encendidas) sobre el cuadro de make_salon.py.
Confeti: tres animaciones sobre una captura de la mesa (test-results/copa-mesa.png, de tests/copa_mesa_capture.gd).
Escribe en test-results/copa/ (no integra nada en el juego).

Ejecutar:  py -3.13 tools/art/bocetos-copa/estrellas.py
"""
from __future__ import annotations
import math, os, sys
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
os.chdir(os.path.join(HERE, "..", "..", ".."))
import make_salon, texturas
from pixel_lib import Canvas, GOLD, upscale

OUT = "test-results/copa"
FRAME = make_salon.COPA_FRAME            # (538, 56, 44, 52) en px lógicos del salón
CELESTE = (116, 172, 223)


def picture(stars_state):
    """El cuadro entero (marco + bandera + copa) con las estrellas pedidas. stars_state: 3 valores 0/1 (apagada/encendida)."""
    cv = Canvas(FRAME[2], FRAME[3], fill=(60, 40, 24))
    ix, iy, iw, ih = texturas.marco(cv, 0, 0, FRAME[2], FRAME[3])
    real_star = make_salon._star
    make_salon._star = lambda *a, **k: None          # la copa se dibuja sin estrellas; van aparte
    inner = make_salon.copa_cuadro(iw, ih)
    make_salon._star = real_star
    cv.blit(inner, ix, iy)
    return cv, (ix, iy, iw, ih)


def star_positions(iw):
    cx = iw / 2
    return [(cx - 9.5, 6.0), (cx, 4.5), (cx + 9.5, 6.0)]


def star_mask(cx, cy, R, w, h):
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        r = R if k % 2 == 0 else R * 0.45
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).polygon(pts, fill=255)
    return np.array(m) > 0


def draw_star(cv, ix, iy, iw, ih, cx, cy, variant, on, blink=0):
    R = 3.8
    mask = star_mask(cx, cy, R, iw, ih)
    from scipy import ndimage
    edge = mask & ~ndimage.binary_erosion(mask, border_value=0)
    ys, xs = np.nonzero(mask)
    if variant == "A":     # bronce opaco -> oro brillante con centelleo
        if not on:
            for y, x in zip(ys, xs): cv.put(ix + x, iy + y, GOLD[1] if x + 0.5 >= cx else GOLD[2])
        else:
            for y, x in zip(ys, xs): cv.put(ix + x, iy + y, GOLD[6] if x + 0.5 < cx else GOLD[5])
            for y, x in zip(*np.nonzero(edge)): cv.put(ix + x, iy + y, GOLD[3])
            if blink % 2 == 0:
                for d in (2, 3):
                    for dx, dy in ((d + 2, 0), (-d - 2, 0), (0, d + 2), (0, -d - 2)):
                        cv.put(ix + int(cx) + dx, iy + int(cy) + dy, (255, 250, 220))
            cv.put(ix + int(cx), iy + int(cy), (255, 255, 255))
    elif variant == "B":   # solo contorno -> relleno dorado con halo
        if not on:
            for y, x in zip(*np.nonzero(edge)): cv.put(ix + x, iy + y, GOLD[2])
        else:
            halo = ndimage.binary_dilation(mask, iterations=2) & ~mask
            for y, x in zip(*np.nonzero(halo)):
                if (x + y + blink) % 2 == 0:
                    c = cv.get(ix + x, iy + y); cv.put(ix + x, iy + y, tuple(min(255, int(v * 0.5 + 255 * 0.5)) for v in c))
            for y, x in zip(ys, xs): cv.put(ix + x, iy + y, GOLD[5] if x + 0.5 < cx else GOLD[3])
            for y, x in zip(*np.nonzero(edge)): cv.put(ix + x, iy + y, GOLD[6])
    else:                  # C: plomo -> oro con rayos que giran
        if not on:
            for y, x in zip(ys, xs): cv.put(ix + x, iy + y, (112, 124, 146) if x + 0.5 < cx else (88, 98, 120))
        else:
            for y, x in zip(ys, xs): cv.put(ix + x, iy + y, GOLD[6] if x + 0.5 < cx else GOLD[4])
            for y, x in zip(*np.nonzero(edge)): cv.put(ix + x, iy + y, GOLD[2])
            diag = blink % 2 == 0
            for k in (3, 4):
                for sx, sy in (((1, 1), (-1, -1), (1, -1), (-1, 1)) if diag else ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    cv.put(ix + int(cx) + sx * (k + 1), iy + int(cy) + sy * (k + 1), (255, 244, 190))


def estrellas():
    os.makedirs(OUT, exist_ok=True)
    rows = []
    for v in "ABC":
        panels = []
        for lit in range(4):
            cv, (ix, iy, iw, ih) = picture(None)
            for i, (cx, cy) in enumerate(star_positions(iw)):
                draw_star(cv, ix, iy, iw, ih, cx, cy, v, on=i < lit)
            panels.append(upscale(cv.image(), 8))
        row = Image.new("RGB", (sum(p.width for p in panels) + 16 * 3, panels[0].height), (30, 20, 14))
        x = 0
        for p in panels:
            row.paste(p.convert("RGB"), (x, 0)); x += p.width + 16
        row.save(f"{OUT}/estrellas-{v}.png")
        # animación: se prenden de a una (cada una con 4 cuadros de centelleo) y se repite
        frames = []
        for lit in range(4):
            for b in range(4):
                cv, (ix, iy, iw, ih) = picture(None)
                for i, (cx, cy) in enumerate(star_positions(iw)):
                    draw_star(cv, ix, iy, iw, ih, cx, cy, v, on=i < lit, blink=b)
                frames.append(upscale(cv.image(), 8).convert("RGB"))
        frames[0].save(f"{OUT}/estrellas-{v}.gif", save_all=True, append_images=frames[1:], duration=220, loop=0)
        print("estrellas", v, "ok")


if __name__ == "__main__":
    estrellas()
