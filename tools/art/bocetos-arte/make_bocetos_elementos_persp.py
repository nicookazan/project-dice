"""Emblemas de elementos pintados sobre la cara de arriba del dado, en perspectiva (07/11/2026, tercera vuelta).

El autor eligió los emblemas (opción B de la vuelta anterior) pero los quiere apoyados sobre la cara de arriba, no de
frente como si fueran parte del número. Cada emblema se define «visto desde arriba», en un plano (ex a lo ancho, ez hacia
el fondo) y se proyecta sobre la cara de arriba real del dado: filas 4 a 10, que se angostan hacia el fondo. Así la
llama apunta hacia atrás, la gota hace ondas que se ven como elipses y el remolino gira acostado.
Cada píxel se muestrea 4×4 veces en el plano y se queda con el color que más cubre (sin mezclas: sigue siendo pixel art).
Uso: py -3.13 tools/art/bocetos-arte/make_bocetos_elementos_persp.py   (después de make_bocetos_elementos_tapa.py)
"""
from __future__ import annotations

import importlib.util
import math
import os
import sys
from collections import Counter

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "tools", "art"))
keep = sys.argv
sys.argv = ["x"]
spec = importlib.util.spec_from_file_location("tapa", os.path.join(HERE, "make_bocetos_elementos_tapa.py"))
tapa = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tapa)
sys.argv = keep

OUT, SIZE, OFF, TAU, FRAMES = tapa.OUT, tapa.SIZE, tapa.OFF, tapa.TAU, tapa.FRAMES
ORDER = tapa.ORDER
ROWS = range(4, 11)        # cara de arriba visible (la fila 3 es el filo y la 11 el canto de adelante)
SX, SZ = .46, .95          # tamaño del emblema: 46 % del ancho de la cara y casi toda su profundidad
SUB = 4


def plane(x, y, sx, sy):
    """Píxel (x, y) del dado + submuestra → coordenadas del emblema (ex, ez). ez = +1 es el fondo de la cara."""
    x0, x1 = tapa.TOP[y]
    cx, hw = (x0 + x1 + 1) / 2, (x1 - x0 + 1) / 2
    X = (x + sx - cx) / hw
    Z = (7.0 - (y + sy - .5)) / 3.5
    return X / SX, Z / SZ


def poly_in(px, py, pts):
    inside = False
    j = len(pts) - 1
    for i in range(len(pts)):
        xi, yi = pts[i]
        xj, yj = pts[j]
        if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi + 1e-9) + xi:
            inside = not inside
        j = i
    return inside


# ---------------------------------------------------------------- emblemas en el plano (devuelven un color o None)
def fire(ex, ez, t):
    h = (ez + .8) / 1.75  # 0 en la base, 1 en la punta
    if h < 0 or h > 1 + .08 * math.sin(TAU * t * 2):
        return None
    c = math.sin(h * 3 + TAU * t) * .22 * h + math.sin(TAU * t * 2) * .08 * h
    base = .62 * math.sqrt(max(0, 1 - ((.28 - h) / .28) ** 2)) if h < .28 else .62 * (max(0.0, 1 - h) / .72) ** .8
    half = base * (1 + .18 * math.sin(h * 6 - TAU * t * 2))
    if abs(ex - c) > half:
        return None
    q = abs(ex - c) / max(half, 1e-3)
    if q > .78 or h > .86:
        return "b8280c"
    if q < .34 and h < .55:
        return "fff0a0"
    if q < .62 and h < .78:
        return "ffc233"
    return "ee5a12"


def water(ex, ez, t):
    cy = -.25
    d = math.hypot(ex, ez - cy)
    ring_r = .55 + .55 * t
    if t < .85 and abs(d - ring_r) < .09:
        return "a8eefc" if t < .45 else "5cc7ee"
    in_drop = d <= .45 or (ez > cy and ez < .85 and abs(ex) <= (.85 - ez) / (.85 - cy) * .42)
    if not in_drop:
        return None
    if d > .36 and ez <= cy + .1 or (ez > cy and abs(ex) > (.85 - ez) / (.85 - cy) * .42 - .1):
        return "0b3d78"
    if math.hypot(ex + .17, ez - cy + .12) < .13:
        return "e8fdff"
    return "1a86cf"


BOLT = [(.3, 1), (-.42, .02), (.02, .02), (-.3, -1), (.45, .18), (.02, .18), (.4, 1)]


def electricity(ex, ez, t):
    step = int(t * 6) % 6
    pts = BOLT if step not in (2, 3) else [(x + (.08 if i in (1, 4) else 0), z) for i, (x, z) in enumerate(BOLT)]
    if poly_in(ex, ez, pts):
        core = poly_in(ex * 1.35, ez * 1.12, pts)
        if step == 0:
            return "fff6b0" if core else "ffc800"
        return "ffe23a" if core else "f0a800"
    for k, (sx, sz) in enumerate(((-.62, .55), (.6, -.5))):
        if (step + k * 3) % 6 in (0, 1) and (abs(ex - sx) < .09 and abs(ez - sz) < .3 or abs(ez - sz) < .14 and abs(ex - sx) < .2):
            return "fff56a"
    if poly_in(ex * .92, ez * .95, pts):
        return "a85a00"
    return None


def earth(ex, ez, t):
    if (ex / .7) ** 2 + ((ez + .72) / .22) ** 2 <= 1:  # mata de tierra en la base
        return "6b4524" if ez < -.74 else "9a6a36"
    sway = math.sin(TAU * t) * .22
    if abs(ex - sway * (ez + .6)) < .07 and -.62 < ez < .1:
        return "3f7a2c"
    for side in (-1, 1):  # dos hojas que salen del tallo, en V
        ang = math.radians(90 - side * 42) + sway * .6
        ox, oz = sway * .7, .1
        u = (ex - ox) * math.cos(ang) + (ez - oz) * math.sin(ang)
        v = -(ex - ox) * math.sin(ang) + (ez - oz) * math.cos(ang)
        if 0 < u < .82 and abs(v) < .26 * math.sin(math.pi * u / .82):
            return "a8dc6c" if v * side > .05 else "6cae44"
    return None


def wind(ex, ez, t):
    best = 9.0
    for i in range(120):
        u = i / 119
        r = .95 * (1 - .82 * u)
        a = TAU * 1.35 * u + TAU * t
        best = min(best, math.hypot(ex - math.cos(a) * r, ez - math.sin(a) * r))
    if best < .07:
        return "8ad8e6"
    if best < .15:
        return "3f9db0"
    return None


INK = {"fire": "7a1a08", "water": "0b2a58", "electricity": "7a4000", "earth": "2a1408", "wind": "1f5a6a"}
EMBLEMS = {"fire": fire, "water": water, "electricity": electricity, "earth": earth, "wind": wind}


def overlay(element, t):
    ov = tapa.Ov()
    fn = EMBLEMS[element]
    for y in ROWS:
        x0, x1 = tapa.TOP[y]
        for x in range(x0, x1 + 1):
            votes = Counter()
            for j in range(SUB):
                for i in range(SUB):
                    ex, ez = plane(x, y, (i + .5) / SUB, (j + .5) / SUB)
                    votes[fn(ex, ez, t)] += 1
            col, n = votes.most_common(1)[0]
            if col is None and n < SUB * SUB * .62:  # si el emblema cubre buena parte del píxel, gana el emblema
                col = next(c for c, _ in votes.most_common() if c is not None)
            if col:
                ov.put(x, y, col)
    # contorno de tinta: el emblema está pintado sobre el marfil y necesita borde para leerse
    from scipy import ndimage
    m = ov.a[..., 3] > 0
    ring = ndimage.binary_dilation(m, structure=[[0, 1, 0], [1, 1, 1], [0, 1, 0]]) & ~m
    ink = tapa.hexc(INK[element])
    for Y, X in zip(*np.nonzero(ring)):
        y, x = Y - OFF, X - OFF
        ext = tapa.TOP.get(min(max(y, 3), 10))
        if 3 <= y <= 11 and ext[0] <= x <= ext[1]:
            ov.a[Y, X] = ink
    return ov


def main():
    bg = tapa.vuelta1.felt(SIZE, SIZE)
    for element in ORDER:
        frames = []
        for i in range(FRAMES):
            fr = bg.copy()
            fr.alpha_composite(tapa.dados.base_die(6 if element != "earth" else 5))
            fr.alpha_composite(overlay(element, i / FRAMES).image())
            frames.append(fr)
        tapa.apng(frames, os.path.join(OUT, f"tapa-P-{element}.png"), 3)
        # detalle × 6 del cuadro 0, recortado a la cara de arriba
        frames[0].crop((OFF, OFF, OFF + 62, OFF + 16)).resize((62 * 6, 16 * 6), Image.NEAREST).convert("RGB").save(os.path.join(OUT, f"_persp-{element}.png"))
    values, phases = [5, 3, 6, 2, 4], [0, 5, 9, 2, 7]
    row_bg = tapa.vuelta1.felt(5 * 84 + 12, SIZE)
    frames = []
    for i in range(FRAMES):
        fr = row_bg.copy()
        for k, element in enumerate(ORDER):
            fr.alpha_composite(tapa.dados.base_die(values[k]), (k * 84 - 2, 0))
            fr.alpha_composite(overlay(element, ((i + phases[k]) % FRAMES) / FRAMES).image(), (k * 84 - 2, 0))
        frames.append(fr)
    tapa.apng(frames, os.path.join(OUT, "tapa-P-mesa.png"), 2)
    print("listo")


if __name__ == "__main__":
    main()
