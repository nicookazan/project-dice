"""Bocetos de elementos en la parte de arriba del dado (07/11/2026, segunda vuelta). No toca assets/ ni el juego.

El autor descartó las marcas laterales animadas salvo el viento B, y pidió algo propio de cada elemento en la cara de
arriba del dado (la franja clara de las filas 3 a 11 del dado de 62 px; los puntos empiezan en la fila 15).
  A «franja»: una tira con el material del elemento a lo ancho de la cara de arriba, donde marcó la línea roja.
  B «emblema»: un dibujo chico centrado en la cara de arriba (llama, gota, rayo, brote, remolino).
  C «sobre el filo»: el elemento apoyado arriba del dado (llamitas, agua quieta, arco eléctrico, pasto y piedras, ráfaga).
El viento B de la primera vuelta (aprobado) se muestra aparte.
12 cuadros a 120 ms. Mismo píxel que el dado (1 px de pantalla), igual que las marcas actuales.
Uso: py -3.13 tools/art/bocetos-arte/make_bocetos_elementos_tapa.py
"""
from __future__ import annotations

import importlib.util
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(ROOT, "test-results", "bocetos-arte")
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "tools", "art"))


def load(name, path, argv):
    keep = sys.argv
    sys.argv = argv
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    sys.argv = keep
    return mod


tmp = os.path.join(OUT, "_tmp")
dados = load("dados", os.path.join(ROOT, "tools/art/bocetos-texturas/make_bocetos_dados.py"), ["x", tmp])
vuelta1 = load("vuelta1", os.path.join(HERE, "make_bocetos_elementos.py"), ["x"])
if os.path.isdir(tmp):
    os.rmdir(tmp)

SIZE, OFF = dados.SIZE, dados.OFF
FRAMES, MS, TAU = 12, 120, math.tau
ORDER = ("fire", "water", "electricity", "earth", "wind")
NAMES = {"fire": "Fuego", "water": "Agua", "electricity": "Electricidad", "earth": "Tierra", "wind": "Viento"}


def hexc(h):
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)] + [255], np.uint8)


def h2(x, y, s=0):
    n = (x * 374761393 + y * 668265263 + s * 1442695041) & 0x7FFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0x7FFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


class Ov:
    """Capa de 96×96 en coordenadas del dado (0..61), ya corrida a (17,17) dentro de la celda."""

    def __init__(self):
        self.a = np.zeros((SIZE, SIZE, 4), np.uint8)

    def put(self, x, y, col):
        X, Y = int(round(x)) + OFF, int(round(y)) + OFF
        if 0 <= X < SIZE and 0 <= Y < SIZE:
            self.a[Y, X] = hexc(col) if isinstance(col, str) else col

    def mask(self, m, col):
        self.a[m] = hexc(col)

    def image(self):
        return Image.fromarray(self.a, "RGBA")


def die_grid():
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    return xx - OFF, yy - OFF


def solid(ov: Ov, m, ramp, outline="2a1408"):
    """Rellena una máscara por capas desde el borde (borde = ramp[0], centro = último) y le pone contorno."""
    if not m.any():
        return
    d = ndimage.distance_transform_cdt(m, metric="taxicab")
    for i, col in enumerate(ramp):
        layer = (d == i + 1) if i < len(ramp) - 1 else (d >= i + 1)
        ov.mask(layer & m, col)
    ring = ndimage.binary_dilation(m, structure=[[0, 1, 0], [1, 1, 1], [0, 1, 0]]) & ~m
    if outline:
        ov.mask(ring & (ov.a[..., 3] == 0), outline)


def flame_mask(cx, base, h, w, lean, t):
    X, Y = die_grid()
    m = np.zeros((SIZE, SIZE), bool)
    for r in range(int(h) + 1):
        f = r / max(h, 1)
        half = w / 2 * (1 - f) ** .8 * (1 + .22 * math.sin(f * 5 + TAU * t))
        c = cx + lean * f * h * .45 + math.sin(f * 3 + TAU * t) * .9 * f
        y = base - r
        m |= (Y == y) & (np.abs(X + .5 - c - .5) <= half + .25)
    return m


FIRE = ["e8480e", "ffa524", "fff0a0"]
WATER = ["1a6fc0", "3aa8e8", "a8eefc"]
BOLT = ["e08a00", "ffe23a", "fffbd0"]
STONE = ["6b4524", "9a6a36", "c89a5e"]
LEAF = ["3f7a2c", "6cae44", "a8dc6c"]
WIND = ["3f9db0", "8ad8e6", "e6fcff"]

# cara de arriba del dado (filas 4 a 10 y su ancho por fila, medidos del dado real)
TOP_Y0, TOP_Y1 = 3, 10
CX = 31


def top_extents():
    f = dados.face(6)
    a = np.array(f)
    ext = {}
    for y in range(TOP_Y0, TOP_Y1 + 1):
        xs = [x for x in range(62) if a[y, x, 3] > 150 and a[y, x, :3].max() > 150]
        ext[y] = (min(xs), max(xs))
    return ext


TOP = top_extents()


# ---------------------------------------------------------------- A: franja en la cara de arriba
def franja(element, t, f):
    ov = Ov()
    x0, x1, y0, y1 = CX - 14, CX + 14, 5, 8
    for y in range(y0 - 1, y1 + 2):  # contorno con puntas redondeadas
        for x in range(x0 - 1, x1 + 2):
            edge = y in (y0 - 1, y1 + 1) or x in (x0 - 1, x1 + 1)
            if edge and (x in (x0 - 1, x1 + 1)) and y in (y0 - 1, y1 + 1):
                continue
            if edge:
                ov.put(x, y, "2a1408")
    for x in range(x0, x1 + 1):
        u = x - x0
        for y in range(y0, y1 + 1):
            v = y - y0
            if element == "fire":
                heat = math.sin(u * .7 - TAU * t * 2) * .5 + h2(u, f // 2, 3) * .6 - v * .45
                col = "fff0a0" if heat > .55 else "ffc233" if heat > .1 else "ee5a12" if heat > -.5 else "a31808"
            elif element == "water":
                crest = math.sin(u * .55 - TAU * t) + math.sin(u * .23 + TAU * t) * .5
                col = "a8eefc" if v == 0 and crest > .6 else "3aa8e8" if v <= 1 + (crest > 0) else "1a6fc0" if v < 3 else "0b3d78"
                if abs(u - (t * 40 % 40 - 6)) < 1 and v == 1:
                    col = "ffffff"
            elif element == "electricity":
                path = 1 + int(h2(u // 2, f // 2, 7) * 2.2)
                col = "fffbd0" if v == path else "ffe23a" if abs(v - path) == 1 and h2(u, f, 2) > .5 else "1c1428"
                if f % 6 == 0 and v == path:
                    col = "ffffff"
            elif element == "earth":
                stone = h2(u // 3, v // 2 + (u // 3) % 2, 5)
                col = "c89a5e" if stone > .75 else "9a6a36" if stone > .35 else "6b4524"
                if v == 0:
                    col = "6cae44" if h2(u, 9) > .3 else "3f7a2c"
            elif element == "wind":
                lane = (u * 1 - int(t * 58)) % 29
                col = "e6fcff" if (v == 1 and lane < 7) or (v == 2 and 12 < lane < 18) else "8ad8e6" if v < 3 else "3f9db0"
            ov.put(x, y, col)
    # detalles que asoman por arriba de la franja
    for x in range(x0, x1 + 1):
        u = x - x0
        if element == "fire":
            tongue = int(max(0, math.sin(u * .9 + TAU * t * 2) * 1.6 + h2(u, f // 2, 4) * 1.4 - .6))
            for k in range(tongue):
                ov.put(x, y0 - 2 - k, "ffc233" if k == 0 else "fff0a0")
        elif element == "earth" and u % 5 == 2:
            sway = round(math.sin(TAU * t + u) * .9)
            ov.put(x, y0 - 2, "6cae44")
            ov.put(x + sway, y0 - 3, "a8dc6c")
    return ov


# ---------------------------------------------------------------- B: emblema chico en el centro de la cara de arriba
def emblema(element, t, f):
    ov = Ov()
    X, Y = die_grid()
    if element == "fire":
        m = flame_mask(CX, 10, 9 + round(math.sin(TAU * t) * 1.2), 9, math.sin(TAU * t * 2) * .35, t)
        solid(ov, m, FIRE, "6a1406")
    elif element == "water":
        bob = round(math.sin(TAU * t) * .8)
        cy = 7 + bob
        m = ((X - CX) ** 2 + (Y - cy) ** 2 <= 9.5) | ((Y < cy) & (Y >= cy - 6) & (np.abs(X - CX) <= (Y - (cy - 6)) * .55))
        solid(ov, m, WATER, "0b2a58")
        ov.put(CX - 1, cy - 1, "ffffff")
        q = t  # anillo que se abre en la base
        rw = 3 + q * 9
        for x in range(int(CX - rw), int(CX + rw) + 1):
            if abs(abs(x - CX) - rw) < 1.2 and q < .85:
                ov.put(x, 11, "a8eefc" if q < .5 else "3aa8e8")
    elif element == "electricity":
        shape = [(CX + 2, 0), (CX - 3, 6), (CX, 6), (CX - 2, 11), (CX + 4, 4), (CX + 1, 4), (CX + 3, 0)]
        step = f % 6
        if step in (2, 3):
            shape = [(x + (1 if i in (1, 3) else 0), y) for i, (x, y) in enumerate(shape)]
        from pixel_lib import poly_mask  # noqa: E402
        m = np.zeros((SIZE, SIZE), bool)
        pm = poly_mask(62, 62, [(x + .5, y + .5) for x, y in shape])
        m[OFF:OFF + 62, OFF:OFF + 62] = pm
        solid(ov, m, BOLT if step != 0 else ["ffe23a", "fffbd0", "ffffff"], "5a2a00")
        for k, (sx, sy) in enumerate(((CX - 7, 4), (CX + 7, 7))):
            if (step + k * 3) % 6 in (0, 1):
                for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
                    ov.put(sx + dx, sy + dy, "fff56a" if (dx, dy) != (0, 0) else "ffffff")
    elif element == "earth":
        mound = ((X - CX) ** 2 / 30 + (Y - 11) ** 2 / 6 <= 1) & (Y <= 10)
        solid(ov, mound, STONE, "2a1408")
        sway = math.sin(TAU * t) * 1.1
        stem = [(CX, 8), (CX, 6), (CX + round(sway * .5), 4)]
        for x, y in stem:
            ov.put(x, y, "3f7a2c")
        tipx = CX + round(sway * .5)
        leaf_l = ((X - (tipx - 3)) ** 2 / 6 + (Y - 3 - round(-sway * .3)) ** 2 / 1.6 <= 1)
        leaf_r = ((X - (tipx + 3)) ** 2 / 6 + (Y - 4 + round(-sway * .3)) ** 2 / 1.6 <= 1)
        solid(ov, leaf_l | leaf_r, LEAF, "1c3a12")
    elif element == "wind":
        sub = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        from PIL import ImageDraw
        d = ImageDraw.Draw(sub)
        dados.spiral(d, CX + OFF, 6 + OFF, 6, 1.3, [3, 1], ["3f9db0", "e6fcff"], TAU * t)
        a = np.array(sub)
        m = a[..., 3] > 0
        ring = ndimage.binary_dilation(m) & ~m
        ov.a[ring] = hexc("123a48")
        ov.a[m] = a[m]
        off = round(math.sin(TAU * t) * 2)
        for x in range(CX - 13 + off, CX - 9 + off):
            ov.put(x, 9, "8ad8e6")
        for x in range(CX + 9 - off, CX + 13 - off):
            ov.put(x, 5, "8ad8e6")
    return ov


# ---------------------------------------------------------------- C: sobre el filo de arriba
def filo(element, t, f):
    ov = Ov()
    X, Y = die_grid()
    edge_x = range(TOP[TOP_Y0][0] + 2, TOP[TOP_Y0][1] - 1)
    if element == "fire":
        m = np.zeros((SIZE, SIZE), bool)
        for i, cx in enumerate((15, 23, 31, 39, 47)):
            ph = i * .29
            h = 8 + (3 if i == 2 else 1 if i in (1, 3) else 0) + math.sin(TAU * (t + ph)) * 1.6
            m |= flame_mask(cx, 5, h, 7, math.sin(TAU * (t * 2 + ph)) * .3, t + ph)
        solid(ov, m, FIRE, "6a1406")
    elif element == "water":
        for y in range(0, 6):  # agua acumulada arriba del dado, con menisco y la superficie ondulando
            x0, x1 = TOP.get(max(y, 3))
            for x in range(x0 + 1, x1):
                surf = 1 + (1 if math.sin(x * .45 - TAU * t) > .3 else 0) + (1 if x in (x0 + 1, x1 - 1) else 0)
                if y < surf:
                    continue
                if y == surf - 1:
                    continue
                col = "e8fdff" if y == surf else "3aa8e8" if y < 4 else "1a6fc0"
                ov.put(x, y, col)
            if y >= 1:
                ov.put(x0, y, "0b2a58")
                ov.put(x1, y, "0b2a58")
        q = t  # una gota salta y vuelve a caer
        if q < .8:
            hx, hy = 38 + q * 8, 0 - math.sin(q / .8 * math.pi) * 9
            for dx, dy, col in ((0, -1, "a8eefc"), (0, 0, "3aa8e8"), (1, 0, "1a6fc0"), (0, 1, "1a6fc0"), (1, 1, "0b3d78")):
                ov.put(hx + dx, hy + dy, col)
        elif q < .95:
            for dx in (-2, 2):
                ov.put(46 + dx, -1, "a8eefc")
    elif element == "electricity":
        a, b = (12, 2), (50, 2)  # el arco salta entre las dos esquinas de arriba
        for post in (a, b):
            for dx, dy, col in ((0, 0, "fffbd0"), (-1, 0, "ffe23a"), (1, 0, "ffe23a"), (0, -1, "ffe23a"), (0, 1, "e08a00")):
                ov.put(post[0] + dx, post[1] + dy, col)
        n = 9
        pts = []
        for i in range(n + 1):
            x = a[0] + (b[0] - a[0]) * i / n
            bow = math.sin(i / n * math.pi) * 5
            jit = 0 if i in (0, n) else (h2(i, f // 2, 1) - .5) * 5
            pts.append((x, a[1] - bow + jit))
        from PIL import ImageDraw
        sub = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        d = ImageDraw.Draw(sub)
        P = [(x + OFF, y + OFF) for x, y in pts]
        d.line(P, fill=(224, 138, 0, 255), width=3)
        d.line(P, fill=(255, 245, 106, 255) if f % 6 else (255, 255, 255, 255), width=1)
        s = np.array(sub)
        m = s[..., 3] > 0
        ov.a[m] = s[m]
    elif element == "earth":
        for (cx, w, h, mid) in ((18, 8, 6, "9a6a36"), (40, 10, 7, "86592c"), (30, 6, 5, "7d5228")):
            m = ((X - cx) ** 2 / (w / 2) ** 2 + (Y - (4 - h / 2)) ** 2 / (h / 2) ** 2 <= 1) & (Y <= 4)
            solid(ov, m, [mid, "c89a5e"], "2a1408")
        for i, gx in enumerate((13, 22, 25, 34, 36, 47, 50)):
            sway = math.sin(TAU * (t + i * .17)) * 1.2
            hgt = 4 + (i % 3)
            for k in range(hgt):
                ov.put(gx + round(sway * k / hgt), 3 - k, "3f7a2c" if k < 2 else "6cae44" if k < hgt - 1 else "a8dc6c")
    elif element == "wind":
        for ph, y, ln in ((0, -1, 9), (.4, 1, 7), (.7, -3, 6)):  # ráfagas que pasan por arriba
            q = (t + ph) % 1
            x = 4 + 54 * q
            col = "e6fcff" if .15 < q < .8 else "8ad8e6"
            for k in range(ln):
                ov.put(x + k, y + (1 if k > ln - 3 else 0), col)
        sub = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        from PIL import ImageDraw
        d = ImageDraw.Draw(sub)
        dados.spiral(d, CX + OFF, 0 + OFF, 4, 1.2, [3, 1], ["3f9db0", "e6fcff"], TAU * t * .5)
        s = np.array(sub)
        m = s[..., 3] > 0
        ov.a[m] = s[m]
    return ov


# ---------------------------------------------------------------- salidas
def apng(frames, path, scale):
    big = [f.convert("RGB").resize((f.width * scale, f.height * scale), Image.NEAREST) for f in frames]
    big[0].save(path, save_all=True, append_images=big[1:], duration=MS, loop=0, format="PNG", optimize=True)


def main():
    bg = vuelta1.felt(SIZE, SIZE)
    for name, fn in (("A", franja), ("B", emblema), ("C", filo)):
        for element in ORDER:
            frames = []
            for i in range(FRAMES):
                fr = bg.copy()
                fr.alpha_composite(dados.base_die(6 if element != "earth" else 5))
                fr.alpha_composite(fn(element, i / FRAMES, i).image())
                frames.append(fr)
            apng(frames, os.path.join(OUT, f"tapa-{name}-{element}.png"), 3)
        values, phases = [5, 3, 6, 2, 4], [0, 5, 9, 2, 7]
        wide = 5 * 84 + 12
        row_bg = vuelta1.felt(wide, SIZE)
        frames = []
        for i in range(FRAMES):
            fr = row_bg.copy()
            for k, element in enumerate(ORDER):
                x = k * 84 - 2
                fr.alpha_composite(dados.base_die(values[k]), (x, 0))
                j = (i + phases[k]) % FRAMES
                fr.alpha_composite(fn(element, j / FRAMES, j).image(), (x, 0))
            frames.append(fr)
        apng(frames, os.path.join(OUT, f"tapa-{name}-mesa.png"), 2)
    print("cara de arriba (fila: x0..x1):", TOP)
    print("listo:", OUT)


if __name__ == "__main__":
    main()
