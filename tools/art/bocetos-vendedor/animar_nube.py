"""Animación del vendedor-nube inspirada en el video del autor: la mano sale de la nube y volutas de nube la rodean.

Parte del arte aprobado (nube + mano, test-results/vendedor-nube7/overlay-mano.png, hecho con desde_imagen.py) y le suma, a
saltos y sin interpolar: un balanceo de 2 px, volutas que crecen y se deshacen alrededor de la muñeca, los dedos y
arriba de la nube, y puffs chicos que flotan. 16 pasos a 5 por segundo.
Escribe en test-results/vendedor-nube8/ (no integra nada en el juego).

Ejecutar:  py -3.13 tools/art/bocetos-vendedor/animar_nube.py
"""
from __future__ import annotations
import math, os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from base import scene_layers, W, H

STEPS = 16
MS = 200
WHITE, PALE, BLUE = (255, 255, 255), (193, 226, 251), (159, 212, 251)
BOB = [0, 0, -2, -2, 0, 0, 2, 2, 0, 0, -2, -2, 0, 0, 2, 2]     # el conjunto sube y baja de a 2 px, con pausas


def spline(pts, n=60):
    p = [pts[0]] + list(pts) + [pts[-1]]
    out = []
    for i in range(1, len(p) - 2):
        p0, p1, p2, p3 = [np.array(q, float) for q in p[i - 1:i + 3]]
        for k in range(n):
            t = k / n
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3))
    out.append(np.array(pts[-1], float))
    return out


def spiral(cx, cy, r0, r1, a0, turns, n=40):
    return [(cx + (r0 + (r1 - r0) * k / n) * math.cos(a0 + turns * 2 * math.pi * k / n),
             cy + (r0 + (r1 - r0) * k / n) * math.sin(a0 + turns * 2 * math.pi * k / n)) for k in range(n + 1)]


def arc(cx, cy, rx, ry, a0, a1, n=30):
    return [(cx + rx * math.cos(a0 + (a1 - a0) * k / n), cy + ry * math.sin(a0 + (a1 - a0) * k / n)) for k in range(n + 1)]


# Cada voluta: camino (px lógicos del 720×450), paso en que nace, vida en pasos.
WISPS = [
    ("muñeca", arc(150, 300, 20, 26, -2.8, 1.9, 40), 1, 9),
    ("arriba", spline([(112, 262), (108, 240), (126, 226), (156, 230), (176, 224), (192, 212), (200, 218)]) + spiral(198, 222, 10, 2, 0.5, 1.4, 20), 4, 11),
    ("dedos", spiral(244, 268, 3, 18, -1.0, 1.6, 44), 7, 8),
    ("abajo-der", spiral(246, 328, 3, 14, 2.0, 1.4, 36), 10, 7),
    ("lejos", spline([(4, 252), (24, 244), (44, 250), (66, 242)]) + spiral(68, 238, 9, 2, 3.5, 1.3, 16), 12, 8),
    ("muñeca-2", arc(146, 306, 18, 22, -0.5, 3.6, 40), 14, 8),
]
PUFFS = [(40, 244, -1, -1, 3), (232, 238, 1, -1, 9), (96, 232, 1, -1, 13)]     # (x, y, dx, dy, paso de nacimiento)


def plot(img, x, y, c, size=2):
    x, y = int(x) // size * size, int(y) // size * size
    if 0 <= x < W - size and 0 <= y < H - size:
        img[y:y + size, x:x + size] = (*c, 255)


def draw_wisp(img, path, age, life):
    """Crece hasta 40 % de su vida, se mantiene y luego se deshace desde la cola. Todo en escalones de 1/5."""
    u = age / life
    head = min(1.0, u / 0.4)
    tail = max(0.0, (u - 0.6) / 0.4)
    head, tail = round(head * 5) / 5, round(tail * 5) / 5
    n = len(path)
    a, b = int(tail * n), int(head * n)
    seg = path[a:b]
    for p in seg:                                                      # sombra celeste abajo a la derecha
        for ox, oy in ((2, 2), (4, 2), (2, 4)): plot(img, p[0] + ox, p[1] + oy, PALE)
    for k, p in enumerate(seg):                                        # trazo grueso: tres bloques de 2×2
        w = 1.0 if (k > len(seg) * 0.25 or len(seg) < 8) else 0.0       # la cola es más fina
        plot(img, p[0], p[1], WHITE)
        if w: plot(img, p[0] + 2, p[1], WHITE); plot(img, p[0], p[1] + 2, WHITE)


def draw_puff(img, x, y, age, life=6):
    """Puff chico que flota: tres lóbulos blancos con la base celeste; nace y se apaga achicándose."""
    u = age / life
    if not 0 <= u < 1: return
    k = 1.0 if 0.2 <= u <= 0.75 else 0.6
    for dx, dy, rx, ry in [(0, 0, 9, 5), (-8, 3, 7, 4), (8, 3, 7, 4)]:
        rx, ry = rx * k, ry * k
        for yy in range(int(-ry), int(ry) + 1, 2):
            for xx in range(int(-rx), int(rx) + 1, 2):
                if (xx / rx) ** 2 + (yy / ry) ** 2 <= 1:
                    plot(img, x + dx + xx, y + dy + yy, WHITE if yy < ry / 3 else PALE)


def main():
    bg, mid, hands, band, M = scene_layers()
    base = mid.copy(); base.alpha_composite(band)
    over = np.array(Image.open("test-results/vendedor-nube7/overlay-mano.png").convert("RGBA"))
    out = "test-results/vendedor-nube8"; os.makedirs(out, exist_ok=True)
    frames = []
    for s in range(STEPS):
        dy = BOB[s]
        layer = np.zeros_like(over)
        if dy < 0: layer[:dy] = over[-dy:]
        elif dy > 0: layer[dy:] = over[:-dy]
        else: layer = over.copy()
        fx = np.zeros((H, W, 4), np.uint8)
        for name, path, start, life in WISPS:
            age = (s - start) % STEPS
            if age < life: draw_wisp(fx, path, age, life)
        for x, y, dx, dy2, start in PUFFS:
            age = (s - start) % STEPS
            draw_puff(fx, x + dx * age * 2, y + dy2 * age * 2, age)
        # las volutas se mueven con el conjunto
        if dy: fx = np.roll(fx, dy, axis=0)
        f = base.copy()
        f.alpha_composite(Image.fromarray(layer)); f.alpha_composite(Image.fromarray(fx)); f.alpha_composite(band)
        frames.append(f.crop((0, 67, 340, 387)))
    big = [f.resize((340 * 3, 320 * 3), Image.NEAREST) for f in frames]
    big[0].save(f"{out}/cuadro0.png"); big[6].save(f"{out}/cuadro6.png")
    small = [f.resize((340 * 2, 320 * 2), Image.NEAREST) for f in frames]
    small[0].save(f"{out}/bucle.gif", save_all=True, append_images=small[1:], duration=MS, loop=0)
    # tira de contacto con 8 pasos
    sheet = Image.new("RGB", (340 * 4, 320 * 2))
    for i, f in enumerate(frames[::2]): sheet.paste(f.convert("RGB"), ((i % 4) * 340, (i // 4) * 320))
    sheet.save(f"{out}/tira.png")
    print("ok")


if __name__ == "__main__":
    main()
