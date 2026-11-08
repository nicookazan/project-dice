"""Bocetos de stickers y monedas (07/11/2026). No toca assets/ ni el juego: escribe en test-results/bocetos-arte/.

Stickers: conservan el diseño aprobado (insignia redonda con dados por categoría) y suben de material.
  A calcomanía brillante · B medallón dorado · C calcomanía gastada.
Monedas: diseños nuevos, misma celda de 32×32 px lógicos. El borde sigue la rareza.
  A acuñada · B patacón antiguo · C ficha esmaltada (el campo sigue la familia).
Uso: py -3.13 tools/art/bocetos-arte/make_bocetos_stickers_monedas.py
"""
from __future__ import annotations

import math
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art"))
from pixel_lib import IVORY, OUTLINE, Canvas, hash2, hexc, poly_mask, ramp  # noqa: E402

OUT = os.path.join(ROOT, "test-results", "bocetos-arte")
PIP = hexc("2a1610")
PIP_LOW = hexc("54301e")
# Rampas largas con corrimiento de tono: sombras hacia el bordó o el azul noche, luces hacia el ocre o el blanco.
GOLD7 = ramp("2e1508", "5c300c", "96601a", "c98f24", "ecbc42", "ffe07a", "fff8c8")
SILVER7 = ramp("1c2038", "3a4058", "5e667e", "868fa6", "aeb8c8", "d8dfe8", "ffffff")
COPPER7 = ramp("2a0e10", "54200f", "86391a", "b25c2a", "d8854a", "f2ae74", "ffdcb0")
VIOLET7 = ramp("1a0c34", "381a66", "5a2c96", "8048c4", "a874e0", "d0a8f4", "f6e8ff")
RIMS = {"common": COPPER7, "rare": SILVER7, "epic": VIOLET7, "legendary": GOLD7}
# Campos de esmalte: colores que ya viven en el juego (paño, capitoné, fieltro del vaso, bordó del maletín).
ENAMEL = {
    "bordo": ramp("2c0812", "5a1024", "8c1c2e", "b23040", "d85a60"),
    "noche": ramp("081028", "10204c", "1c3a7c", "2f5cae", "5c8ad8"),
    "fieltro": ramp("08261a", "10442c", "1c6a42", "2f9058", "62bc7c"),
    "cuero": ramp("10090a", "241614", "3a2620", "54382c", "74503c"),
}
IV = ramp("7a5230", "c29a64", "ecd8ac", "fff2d2", "ffffff")


def shift(c, k=0.5, target=(0, 0, 0)):
    return tuple(int(c[i] + (target[i] - c[i]) * k) for i in range(3))


def category_ramp(base_hex: str):
    """Rampa de 5 tonos desde el color de la categoría: sombra al bordó, luz al marfil."""
    b = hexc(base_hex)
    return [shift(b, .62, (32, 8, 24)), shift(b, .34, (48, 14, 32)), b, shift(b, .28, (255, 232, 180)), shift(b, .58, (255, 244, 210))]


# ---------------------------------------------------------------- dados con el dibujo del dado real
# Posición de cada punto dentro del área útil de la cara (0 = un borde, 1 = el otro), como en un dado real.
PIPS = {
    0: [], 1: [(.5, .5)], 2: [(0, 0), (1, 1)], 3: [(0, 0), (.5, .5), (1, 1)],
    4: [(0, 0), (1, 0), (0, 1), (1, 1)], 5: [(0, 0), (1, 0), (.5, .5), (0, 1), (1, 1)],
    6: [(0, 0), (1, 0), (0, .5), (1, .5), (0, 1), (1, 1)]}
BIG = 52  # sticker grande (tienda y álbum): 104 px en pantalla
DIE = 12  # todos los dados de los stickers grandes son iguales: 12 px, puntos de 2×2
FIELD = {"c": 26.0, "r": 99.0}  # campo del sticker que se está dibujando: la sombra no se sale de ahí


def big_die(s: int, value: int, anti: bool = False) -> Canvas:
    """Dado según el modelo del autor (07/11): contorno, esquinas redondeadas, luz arriba y a la izquierda, sombra abajo y a
    la derecha, sin banda. Los puntos van en una grilla pareja (2, medio, s-2-punto) para que las diagonales sean limpias:
    en el dado de 12 caen en 2, 5 y 8. `anti` usa la otra diagonal (para el 2 y el 3 cuando otro dado tapa una esquina)."""
    pad = 3
    cv = Canvas(s + pad * 2, s + pad * 2)
    cut = 2 if s >= 12 else 1
    for y in range(s):
        for x in range(s):
            cx, cy = min(x, s - 1 - x), min(y, s - 1 - y)
            if cx + cy < cut:
                continue
            if cx == 0 or cy == 0 or cx + cy == cut:
                c = OUTLINE
            elif y == 1 or x == 1:
                c = IV[4]
            elif y == s - 2 or x == s - 2:
                c = IV[1]
            else:
                c = IV[3]
            cv.put(pad + x, pad + y, c)
    pip = 2 if s >= 12 else 1
    p0, p1 = 2, s - 2 - pip
    mid = (p0 + p1) // 2
    pos = {0: p0, .5: mid, 1: p1}
    for fx, fy in PIPS[value]:
        if anti:
            fx = 1 - fx
        px, py = pad + pos[fx], pad + pos[fy]
        for j in range(pip):
            for i in range(pip):
                cv.put(px + i, py + j, PIP_LOW if pip > 1 and j == pip - 1 else PIP)
    return cv


def bars(heights, w=4, step=5) -> Canvas:
    """Barras que suben, con el dibujo de la moneda «Acumulada» que eligió el autor para la escalera."""
    pad = 3
    H = max(heights)
    cv = Canvas(step * len(heights) + 1 + pad * 2, H + 1 + pad * 2)
    for i, h in enumerate(heights):
        x0, y0 = pad + i * step, pad + H - h
        for y in range(h + 1):
            for x in range(w + 2):
                if y == 0 and x in (0, w + 1):
                    continue
                if x in (0, w + 1) or y in (0, h):
                    c = OUTLINE
                elif x == 1 or y == 1:
                    c = IV[4]
                elif x == w:
                    c = IV[1]
                else:
                    c = IV[3]
                cv.put(x0 + x, y0 + y, c)
    return cv


def drop_die(cv: Canvas, die: Canvas, ox: int, oy: int, shadow) -> None:
    """Pega un dado con su sombra dura proyectada abajo a la derecha (la sombra queda dentro del campo)."""
    ys, xs = np.nonzero(die.mask_of())
    for x, y in zip(xs, ys):
        for k in (1, 2):
            px, py = ox + x + k, oy + y + k
            inside = math.hypot(px + .5 - FIELD["c"], py + .5 - FIELD["c"]) <= FIELD["r"]
            if 0 <= px < cv.w and 0 <= py < cv.h and cv.a[py, px, 3] > 0 and inside:
                cv.put(px, py, shadow)
    cv.blit(die, ox, oy)


def die_at(cv, s, value, cx, cy, shadow):
    """Dado de lado s centrado en (cx, cy), relativo al centro del sticker grande."""
    drop_die(cv, big_die(s, value), round(BIG / 2 + cx - s / 2) - 3, round(BIG / 2 + cy - s / 2) - 3, shadow)


# ---------------------------------------------------------------- contenido de cada sticker
STICKERS = {"pair_loose": "c7a25b", "trio": "c77849", "straight": "70a5c0", "full": "6da77e", "poker": "b578ac", "generala": "e0b445"}
STICKER_NAMES = {"pair_loose": "Par", "trio": "Trío", "straight": "Escalera", "full": "Full", "poker": "Póker", "generala": "Generala"}


def spark(cv, x, y, c, c2):
    for i in range(-1, 2):
        cv.put(x + i, y, c)
        cv.put(x, y + i, c)


def sticker_dice_big(cv: Canvas, sid: str, shadow) -> None:
    """Misma composición que el sticker aprobado. Todos los dados son el mismo dado de 12 px (el del par); el full los
    junta como una pila, compartiendo el contorno, para que entren cinco sin tocar el aro."""
    o = (BIG - 44) // 2  # la escalera se dibuja en coordenadas del sticker de 44
    if sid == "pair_loose":
        die_at(cv, DIE, 2, -7, 1, shadow)
        die_at(cv, DIE, 2, 7, -1, shadow)
    elif sid == "trio":
        die_at(cv, DIE, 3, -7, -6, shadow)
        die_at(cv, DIE, 3, 7, -6, shadow)
        die_at(cv, DIE, 3, 0, 7, shadow)
    elif sid == "straight":
        b = bars([7, 11, 15, 19, 23])
        drop_die(cv, b, BIG // 2 - 13 - 3, BIG // 2 + 10 - 23 - 3, shadow)
    elif sid == "full":
        for cx in (-11, 0, 11):
            die_at(cv, DIE, 3, cx, -5, shadow)
        for cx in (-5.5, 5.5):
            die_at(cv, DIE, 2, cx, 6, shadow)
    elif sid == "poker":
        for cx, cy in ((-7, -7), (7, -7), (-7, 7), (7, 7)):
            die_at(cv, DIE, 4, cx, cy, shadow)
    elif sid == "generala":
        die_at(cv, 14, 5, 0, 0, shadow)
        c = BIG // 2
        for x, y in ((c - 9, c - 9), (c + 8, c - 9), (c - 9, c + 8), (c + 8, c + 8)):
            spark(cv, x, y, IV[4], IV[3])


def dice_reach(sid: str, size: int = BIG) -> float:
    """Distancia máxima al centro de los píxeles de los dados (sin sombra): para comprobar que no tocan el aro."""
    probe = Canvas(size, size)
    keep = FIELD["r"]
    FIELD["r"] = -1  # sin sombra
    if size > 19:
        sticker_dice_big(probe, sid, (0, 0, 0))
    else:
        sticker_dice_small(probe, sid, (0, 0, 0))
    FIELD["r"] = keep
    ys, xs = np.nonzero(probe.mask_of() & (probe.a[..., :3].sum(axis=2) > 0))  # la sombra (negro) no cuenta
    return max(math.hypot(x + .5 - size / 2, y + .5 - size / 2) for x, y in zip(xs, ys))


def sticker_dice_small(cv: Canvas, sid: str, shadow) -> None:
    """Versión del termo (19 px): la composición de hoy, más compacta para dejar un píxel libre antes del aro."""

    def die(ox, oy, s, pips):
        for i in range(1, s + 1):
            px, py = ox + i, oy + s
            if math.hypot(px + .5 - 9.5, py + .5 - 9.5) <= 7.3:
                cv.put(px, py, shadow)
            px, py = ox + s, oy + i
            if math.hypot(px + .5 - 9.5, py + .5 - 9.5) <= 7.3:
                cv.put(px, py, shadow)
        for y in range(s):
            for x in range(s):
                c = IV[3]
                if x == 0 or y == 0:
                    c = IV[4]
                if x == s - 1 or y == s - 1:
                    c = IV[1]
                cv.put(ox + x, oy + y, c)
        for x, y in pips:
            cv.put(ox + x, oy + y, PIP)

    p2 = [(1, 1), (2, 2)]
    if sid == "pair_loose":
        die(4, 7, 5, [(1, 1), (2, 2), (3, 3)])
        die(10, 7, 5, [(1, 1), (2, 2), (3, 3)])
    elif sid == "trio":
        die(5, 5, 4, p2)
        die(10, 5, 4, p2)
        die(8, 10, 4, p2)
    elif sid == "straight":
        for i in range(4):
            h = 2 * i + 2
            for y in range(h):
                for x in range(2):
                    cv.put(4 + i * 3 + x, 14 - h + y, IV[4] if y == 0 else IV[1] if x == 1 else IV[3])
    elif sid == "full":
        for x in (4, 8, 12):
            die(x, 5, 3, [(1, 1)])
        for x in (6, 10):
            die(x, 10, 3, [(1, 1)])
    elif sid == "poker":
        for x, y in ((5, 5), (10, 5), (5, 10), (10, 10)):
            die(x, y, 4, p2)
    elif sid == "generala":
        die(6, 6, 7, [(1, 1), (5, 1), (3, 3), (1, 5), (5, 5)])
        for x, y in ((5, 5), (13, 5), (5, 13), (13, 13)):
            cv.put(x, y, IV[4])


def disc_pixels(size=19):
    c = size / 2
    for y in range(size):
        for x in range(size):
            dx, dy = x + .5 - c, y + .5 - c
            yield x, y, dx, dy, math.hypot(dx, dy)


def rays(fr, dx, dy, d, n, r):
    """Campo: rayos tono sobre tono desde el centro, más oscuro abajo a la derecha."""
    s = (dx + dy) / (r * 1.41)
    c = fr[2]
    if s > .34:
        c = fr[1]
    elif s < -.52:
        c = fr[3]
    a = math.atan2(dy, dx)
    if int((a + math.pi) / (math.tau / n)) % 2 == 0 and d > r * .15:
        c = shift(c, .22, fr[0])
    return c


def sticker_a(sid, size=BIG):
    """Calcomanía brillante: borde de vinilo marfil, campo con rayos, dados reales y reflejo curvo."""
    cv = Canvas(size, size)
    fr = category_ramp(STICKERS[sid])
    big = size > 19
    r = size / 2
    rim_out, rim_in, seam = (r - 1, r - 4.6, r - 5.8) if big else (r - .9, r - 2.2, r - 2.2)
    for x, y, dx, dy, d in disc_pixels(size):
        if d > r:
            continue
        t = -(dx + dy) / max(d, .01)
        if d > rim_out:
            c = OUTLINE
        elif d > rim_in:
            c = IV[4] if t > .72 else IV[3] if t > 0 else IV[2] if t > -.62 else IV[1]
        elif d > seam:
            c = fr[0]
        else:
            c = rays(fr, dx, dy, d, 16 if big else 8, seam)
            if big and d > seam - 1.2:
                c = fr[1] if t > 0 else fr[3]  # el campo está un poco hundido
        cv.put(x, y, c)
    if big:
        sticker_dice_big(cv, sid, fr[0])
        for i in range(10):  # reflejo curvo del vinilo, por encima de todo
            a = math.radians(196 + i * 6.5)
            px, py = int(r + math.cos(a) * (seam - 2.4)), int(r + math.sin(a) * (seam - 2.4))
            if cv.get(px, py) not in (OUTLINE, PIP, PIP_LOW) and sum(cv.get(px, py)) < 690:
                cv.put(px, py, fr[4])
    else:
        sticker_dice_small(cv, sid, fr[0])
    return cv


def sticker_b(sid, size=BIG):
    """Medallón dorado: el aro con perlas de los medallones de la tienda y esmalte de la categoría."""
    cv = Canvas(size, size)
    fr = category_ramp(STICKERS[sid])
    big = size > 19
    r = size / 2
    rim_out, rim_in, seam = (r - 1, r - 5, r - 6) if big else (r - .9, r - 2.2, r - 2.2)
    for x, y, dx, dy, d in disc_pixels(size):
        if d > r:
            continue
        t = -(dx + dy) / max(d, .01)
        if d > rim_out:
            c = OUTLINE
        elif d > rim_in:
            c = GOLD7[6] if t > .93 else GOLD7[5] if t > .6 else GOLD7[4] if t > .05 else GOLD7[3] if t > -.55 else GOLD7[2]
        elif d > seam:
            c = GOLD7[0]
        else:
            c = rays(fr, dx, dy, d, 8, seam)
        cv.put(x, y, c)
    if big:
        for i in range(32):
            a = i * math.tau / 32
            px, py = int(r + math.cos(a) * (r - 3)), int(r + math.sin(a) * (r - 3))
            tt = -(math.cos(a) + math.sin(a)) / 1.41
            cv.put(px, py, GOLD7[1])
            cv.put(px - 1, py - 1, GOLD7[6] if tt > 0 else GOLD7[4])
        FIELD.update(c=r, r=seam)
        sticker_dice_big(cv, sid, fr[0])
        FIELD.update(r=99.0)
    else:
        sticker_dice_small(cv, sid, fr[0])
    return cv


def sticker_c(sid, size=BIG):
    """Calcomanía gastada: la A con años de termo encima. Borde sucio, tinta ida en parches y punta levantada."""
    cv = sticker_a(sid, size)
    fr = category_ramp(STICKERS[sid])
    seed = list(STICKERS).index(sid) * 7 + 3
    big = size > 19
    r = size / 2
    block = 3 if big else 2
    for x, y, dx, dy, d in disc_pixels(size):
        if d > r - 1:
            continue
        v = cv.get(x, y)
        if d > r - (4.6 if big else 2.2):
            if hash2(x // block, y // block, seed) > .68:
                cv.put(x, y, shift(v, .4, IV[0]))
        elif v not in (OUTLINE, PIP, PIP_LOW) and sum(v) < 620 and hash2(x // block, y // block, seed + 5) > .9:
            cv.put(x, y, shift(fr[2], .5, IV[2]))
    # punta levantada abajo a la derecha: lo que queda más allá de la diagonal se dobla hacia adentro y muestra el dorso
    cut = int(size * 1.6) if big else 29
    flap = []
    for y in range(size):
        for x in range(size):
            if x + y >= cut and cv.a[y, x, 3] > 0:
                flap.append((x, y))
                cv.a[y, x, 3] = 0
    folded = {(cut - 1 - y, cut - 1 - x) for x, y in flap}
    for px, py in folded:
        if not (0 <= px < size and 0 <= py < size):
            continue
        near = (cut - 1) - (px + py)
        cv.put(px, py, hexc("f4ecd8") if near < 3 else hexc("d4c6a6") if near < 6 else hexc("b4a484"))
    for px, py in folded:
        for ax, ay in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = px + ax, py + ay
            if (nx, ny) not in folded and 0 <= nx < size and 0 <= ny < size and nx + ny < cut - 1:
                cv.put(nx, ny, OUTLINE)
    for i in range(size):  # línea del doblez
        x, y = i, cut - 1 - i
        if 0 <= y < size and cv.a[y, x, 3] > 0:
            cv.put(x, y, OUTLINE)
    return cv


def rotsprite(img: Image.Image, deg: float, k: int = 8) -> Image.Image:
    big = img.resize((img.width * k, img.height * k), Image.NEAREST).rotate(deg, resample=Image.NEAREST)
    return Image.fromarray(np.ascontiguousarray(np.array(big)[k // 2::k, k // 2::k]), "RGBA")


THERMOS_SPOTS = {"pair_loose": (70, 122, -8), "trio": (108, 134, 15), "straight": (62, 168, 4), "full": (102, 184, -14), "poker": (74, 214, 18), "generala": (108, 232, -5)}


def surface_x(x: float, axis=86.0, radius=46.0) -> float:
    return axis + math.sin((x - axis) / radius) * radius


def snap(v: float) -> int:
    return int(round(v / 2.0) * 2)


def on_thermos(art: dict[str, Canvas]) -> Image.Image:
    """Termo real con los stickers en su lugar fijo: mismo giro y compresión por columna que Sticker.draw_on_thermos."""
    termo = Image.open(os.path.join(ROOT, "assets/art/pixel-v3/termo-v3.png")).convert("RGBA")
    out = termo.resize((termo.width * 2, termo.height * 2), Image.NEAREST)
    for sid, (cx, cy, deg) in THERMOS_SPOTS.items():
        cell = Image.new("RGBA", (25, 25), (0, 0, 0, 0))
        cell.alpha_composite(art[sid].image(), (3, 3))
        rot = rotsprite(cell, deg)
        top = snap(cy - 25)
        left0 = cx - 25.0
        for col in range(25):
            left = left0 + col * 2.0
            x0, x1 = snap(surface_x(left)), snap(surface_x(left + 2.0))
            if x1 <= x0:
                continue
            ang = abs((left + 1.0 - 86.0) / 46.0)
            shade = .62 if ang > .95 else .8 if ang > .65 else 1.0
            strip = np.array(rot.crop((col, 0, col + 1, 25)).resize((x1 - x0, 50), Image.NEAREST)).astype(float)
            strip[..., :3] *= shade
            out.alpha_composite(Image.fromarray(strip.astype("uint8"), "RGBA"), (x0, top))
    return out


# ---------------------------------------------------------------- emblemas de las monedas
class M:
    """Máscara de emblema: '#' relieve, 'o' hundido, '.' vacío."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [["."] * w for _ in range(h)]

    def set(self, x, y, c="#"):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = c

    def rect(self, x, y, w, h, c="#"):
        for j in range(h):
            for i in range(w):
                self.set(x + i, y + j, c)

    def disc(self, cx, cy, r, c="#"):
        for y in range(self.h):
            for x in range(self.w):
                if math.hypot(x + .5 - cx, y + .5 - cy) <= r:
                    self.set(x, y, c)

    def poly(self, pts, c="#"):
        m = poly_mask(self.w, self.h, pts)
        for y in range(self.h):
            for x in range(self.w):
                if m[y, x]:
                    self.set(x, y, c)

    def rows(self):
        return ["".join(r) for r in self.g]


def from_rows(rows):
    m = M(len(rows[0]), len(rows))
    m.g = [list(r) for r in rows]
    return m


GL = {"$": ["..#..", ".####", "#.#..", ".###.", "..#.#", "####.", "..#.."],
      "5": ["####", "#...", "###.", "...#", "...#", "#..#", ".##."]}


def e_full():
    m = M(17, 13)
    for x in (0, 6, 12):
        m.rect(x, 0, 5, 5)
        m.set(x + 1, 1, "o")
        m.set(x + 3, 3, "o")
        m.set(x + 2, 2, "o")
    for x in (3, 9):
        m.rect(x, 8, 5, 5)
        m.set(x + 1, 9, "o")
        m.set(x + 3, 11, "o")
    return m


def e_crown():
    return from_rows([
        ".##.....##.....##.",
        ".##.....##.....##.",
        "..#....####....#..",
        "..##...####...##..",
        "..###..####..###..",
        "..####.####.####..",
        "..##############..",
        "..##############..",
        "..##############..",
        "...............  .".replace(" ", "."),
        "..##oo##oo##oo##..",
        "..##############..",
    ])


def e_cash():
    return from_rows([
        "...##.............",
        ".#######..#######.",
        "##.##.....##......",
        "##.##.....##......",
        ".######...######..",
        "...##.##......###.",
        "...##.##......###.",
        "...##.##..##..###.",
        "#######....#####..",
        "...##.............",
    ])


def e_cup():
    m = M(16, 17)
    m.poly([(1, 2), (15, 2), (13, 17), (3, 17)])
    m.rect(0, 0, 16, 3)
    m.rect(1, 3, 14, 1, "o")
    m.rect(7, 6, 2, 8, "o")
    m.rect(4, 9, 8, 2, "o")
    return m


def e_shield():
    m = M(17, 19)
    m.poly([(0, 1), (8.5, 0), (17, 1), (17, 10), (8.5, 19), (0, 10)])
    m.rect(7, 3, 3, 12, "o")
    m.rect(3, 6, 11, 3, "o")
    return m


def e_gems():
    gem = ["..#####..", ".#o###o#.", "#########", ".#######.", "..##o##..", "...###...", "....#...."]
    m = M(19, 16)
    for ox, oy in ((5, 0), (0, 9), (10, 9)):
        for y, r in enumerate(gem):
            for x, ch in enumerate(r):
                if ch != ".":
                    m.set(ox + x, oy + y, ch)
    return m


def e_two_rolls():
    m = M(19, 19)
    m.disc(9.5, 9.5, 9.0)
    m.disc(9.5, 9.5, 6.8, ".")
    for y in range(0, 7):
        for x in range(11, 19):
            m.set(x, y, ".")
    for hy, w in enumerate([2, 4, 5, 4, 2]):
        m.rect(11, hy, w, 1)
    for x in (4, 10):
        m.rect(x, 7, 5, 5)
        m.set(x + 1, 8, "o")
        m.set(x + 3, 10, "o")
    return m


def e_hand():
    return from_rows([
        ".......##.........",
        "....##.##.##......",
        "....##.##.##.##...",
        "....##.##.##.##...",
        "....##.##.##.##...",
        "....##.##.##.##...",
        "....##.##.##.##...",
        "....##.##.##.##...",
        ".##.###########...",
        ".##.###########...",
        ".###.##########...",
        "..###.#########...",
        "..#############...",
        "...############...",
        "....##########....",
        "....##########....",
        ".....########.....",
        ".....oooooooo.....",
    ])


SMALL = {
    "full": ["####.####.####", "#o##.#o##.#o##", "##o#.##o#.##o#", "####.####.####", "..............", "...####.####..", "...#o##.#o##..", "...##o#.##o#..", "...####.####.."],
    "generala": ["#.....##.....#", "#.....##.....#", "##...####...##", "###.######.###", "##############", "##############", "..............", "##oo##oo##oo##", "##############"],
    "quick_cash": ["..#...........", ".#####.######.", "#.#....#......", ".####..#####..", "..#.#......##.", "..#.#......##.", "#####..#...##.", "..#.....####.."],
    "reserve_roll": ["############", "############", ".oooooooooo.", ".####oo####.", ".####oo####.", ".#oooooooo#.", ".#oooooooo#.", "..###oo###..", "..###oo###..", "..########.."],
    "boss_shield": [".###########.", "#############", "#####ooo#####", "#####ooo#####", "##ooooooooo##", "##ooooooooo##", "#####ooo#####", "#####ooo#####", ".####ooo####.", "..###ooo###..", "...#######...", "....#####....", ".....###....."],
    "repair_all": ["....######....", "....#o##o#....", "....######....", ".....####.....", "......##......", "######..######", "#o##o#..#o##o#", "######..######", ".####....####.", "..##......##.."],
    "two_rolls": ["....######.#..", "...##....###..", "..##.....####.", "..............", "#####...#####.", "#o###...#o###.", "##o##...##o##.", "###o#...###o#.", "#####...#####."],
    "extra_hand": ["......##......", "...##.##.##...", "...##.##.##.##", "...##.##.##.##", "...##.##.##.##", "...##.##.##.##", "##.##########.", "###.#########.", ".############.", "..##########..", "...########...", "...########..."],
}


# id, nombre, rareza, familia (campo del esmalte), emblema
COINS = [
    ("full", "Full", "common", "bordo", e_full),
    ("generala", "Generala", "common", "bordo", e_crown),
    ("quick_cash", "Plata rápida", "common", "fieltro", e_cash),
    ("reserve_roll", "Tirada de reserva", "rare", "noche", e_cup),
    ("boss_shield", "Escudo de jefe", "rare", "cuero", e_shield),
    ("repair_all", "Reparar todas", "epic", "noche", e_gems),
    ("two_rolls", "Dos tiradas más", "epic", "fieltro", e_two_rolls),
    ("extra_hand", "Mano extra", "legendary", "bordo", e_hand),
]
RARITY_NAMES = {"common": "Común", "rare": "Rara", "epic": "Épica", "legendary": "Legendaria"}


def emboss(cv: Canvas, m: M, r, ox=None, oy=None, hi=5, mid=4, low=2, deep=1, cast=None, outline=None):
    """Relieve con luz arriba-izquierda: borde lit, cuerpo, borde en sombra, hundidos y sombra proyectada."""
    rows = m.rows()
    h, w = len(rows), len(rows[0])
    ox = (32 - w) // 2 if ox is None else ox
    oy = (32 - h) // 2 if oy is None else oy

    def solid(x, y):
        return 0 <= y < h and 0 <= x < w and rows[y][x] == "#"

    def any_ink(x, y):
        return 0 <= y < h and 0 <= x < w and rows[y][x] in "#o"

    if outline is not None:
        for y in range(-1, h + 1):
            for x in range(-1, w + 1):
                if not any_ink(x, y) and any(any_ink(x + a, y + b) for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    cv.put(ox + x, oy + y, outline)
    if cast is not None:
        for y in range(h):
            for x in range(w):
                if any_ink(x, y) and not any_ink(x + 1, y + 1):
                    cv.put(ox + x + 1, oy + y + 1, cast)
    for y in range(h):
        for x in range(w):
            ch = rows[y][x]
            if ch == ".":
                continue
            if ch == "o":
                cv.put(ox + x, oy + y, r[deep])
                continue
            c = r[mid]
            if not solid(x, y - 1) or not solid(x - 1, y):
                c = r[hi]
            if not solid(x, y + 1) or not solid(x + 1, y):
                c = r[low] if solid(x, y - 1) and solid(x - 1, y) else r[mid]
            cv.put(ox + x, oy + y, c)


def coin_a(rarity, family, emblem):
    """Acuñada: canto estriado, aro alto, cordón de perlas, campo hundido con pátina, emblema en relieve y destello."""
    cv = Canvas(32, 32)
    r = RIMS[rarity]
    for x, y, dx, dy, d in disc_pixels(32):
        if d > 16:
            continue
        t = -(dx + dy) / max(d, .01)
        a = math.atan2(dy, dx)
        if d > 15:
            c = OUTLINE
        elif d > 14:
            notch = int((a + math.pi) / (math.tau / 44)) % 2 == 0
            base = 4 if t > .3 else 3 if t > -.3 else 2
            c = r[base + 1] if notch else r[base - 1]
        elif d > 11.6:
            c = r[6] if t > .93 else r[5] if t > .6 else r[4] if t > .12 else r[3] if t > -.45 else r[2]
            if t < -.86:
                c = r[3]  # luz de rebote
        elif d > 10.6:
            c = r[1] if t > .1 else r[2]
        else:
            # campo hundido: la sombra del aro cae arriba a la izquierda
            s = (dx + dy) / 15
            c = r[2]
            if t > .25 and d > 8.5:
                c = r[1]
            elif s > .42:
                c = r[3] if d > 8.4 else r[2]
            if hash2(x // 3, y // 3, 7) > .8 and c == r[2]:
                c = shift(r[2], .35, r[3])
        cv.put(x, y, c)
    # cordón de perlas sobre el aro
    for i in range(28):
        a = i * math.tau / 28
        px, py = int(16 + math.cos(a) * 11.2), int(16 + math.sin(a) * 11.2)
        tt = -(math.cos(a) + math.sin(a)) / 1.41
        cv.put(px, py, r[5] if tt > 0 else r[4])
    emboss(cv, emblem(), r, hi=6, mid=4, low=3, deep=1, cast=r[0])
    # destello duro en el aro
    for x, y in ((8, 5), (7, 6), (6, 7), (9, 4)):
        cv.put(x, y, r[6])
    return cv


def coin_b(rarity, family, emblem, cid=None):
    """Patacón antiguo: canto apenas irregular de golpe a mano, corona de laurel limpia, sol arriba y pátina en los huecos."""
    cv = Canvas(32, 32)
    r = RIMS[rarity]
    patina = {"common": hexc("2f7562"), "rare": hexc("2a2640"), "epic": hexc("1c0c3a"), "legendary": hexc("6a3410")}[rarity]
    seed = list(RIMS).index(rarity) * 11 + len(emblem().rows()[0])
    for x, y, dx, dy, d in disc_pixels(32):
        a = math.atan2(dy, dx)
        wob = .38 * math.sin(a * 3 + seed) + .22 * math.sin(a * 5 + seed * 2)
        rr = 15.5 + wob
        if d > rr + .5:
            continue
        t = -(dx + dy) / max(d, .01)
        if d > rr - .5:
            c = OUTLINE
        elif d > 13.6 + wob * .6:
            c = r[5] if t > .72 else r[4] if t > .1 else r[3] if t > -.55 else r[2]
        else:
            s = (dx + dy) / 15
            c = r[3]
            if s > .28:
                c = r[2]
            elif s < -.52:
                c = r[4]
            if d > 12.6:  # surco bajo el canto, donde junta mugre
                c = patina if hash2(x // 2, y // 2, seed + 9) > .4 else r[1]
        cv.put(x, y, c)
    for side in (-1, 1):  # laureles: abiertos arriba, se juntan abajo
        for i in range(7):
            ang = math.radians(90 + side * (14 + i * 20))
            px, py = 16 + math.cos(ang) * 11.0, 16 + math.sin(ang) * 11.0
            lx, ly = int(px), int(py)
            lit = px + py < 31
            cv.put(lx, ly, r[6] if lit else r[5])
            cv.put(lx + side * -1, ly, r[5] if lit else r[4])
            cv.put(lx, ly + 1, r[1])
    for x, y, c in ((15, 3, 6), (16, 3, 6), (15, 4, 6), (16, 4, 5), (14, 3, 5), (17, 4, 4), (15, 2, 5), (16, 5, 4)):  # sol
        cv.put(x, y, r[c])
    m = from_rows(SMALL[cid])
    emboss(cv, m, r, hi=6, mid=5, low=3, deep=1, cast=r[1], oy=(32 - len(m.rows())) // 2 + 1)
    return cv


def shrink(m: M) -> M:
    """Reduce un emblema grande a ~3/4 tomando filas y columnas salteadas (mantiene el dibujo y los huecos)."""
    rows = m.rows()
    keep_y = [i for i in range(len(rows)) if i % 4 != 3]
    keep_x = [i for i in range(len(rows[0])) if i % 4 != 3]
    return from_rows(["".join(rows[y][x] for x in keep_x) for y in keep_y])


def coin_c(rarity, family, emblem):
    """Ficha esmaltada: aro de metal por rareza, campo de esmalte por familia con trama, emblema marfil y brillo curvo."""
    cv = Canvas(32, 32)
    r = RIMS[rarity]
    fr = ENAMEL[family]
    for x, y, dx, dy, d in disc_pixels(32):
        if d > 16:
            continue
        t = -(dx + dy) / max(d, .01)
        a = math.atan2(dy, dx)
        if d > 15:
            c = OUTLINE
        elif d > 12.2:
            c = r[6] if t > .92 else r[5] if t > .58 else r[4] if t > .08 else r[3] if t > -.5 else r[2]
            if int((a + math.pi) / (math.tau / 8)) % 8 == 0 and 13 < d < 14.4:
                c = r[1] if t > 0 else r[0]
        elif d > 11.2:
            c = r[1]
        else:
            s = (dx + dy) / 15
            c = fr[2]
            if s > .42:
                c = fr[1]
            elif s < -.5:
                c = fr[3]
            if (x + y) % 4 == 0 and (x - y) % 4 == 0:
                c = shift(c, .35, fr[3]) if s < .42 else shift(c, .3, fr[2])
        cv.put(x, y, c)
    m = emblem()
    em_ramp = GOLD7 if rarity == "legendary" else [IV[0], hexc("3a2418"), IV[1], IV[1], IV[3], IV[3], IV[4]]  # hundidos oscuros, como los puntos del dado
    emboss(cv, m, em_ramp, hi=6, mid=4, low=2, deep=2 if rarity == "legendary" else 1, outline=OUTLINE)
    # brillo curvo del esmalte, arriba a la izquierda
    for i in range(9):
        a = math.radians(205 + i * 6)
        px, py = int(16 + math.cos(a) * 9.6), int(16 + math.sin(a) * 9.6)
        v = cv.get(px, py)
        if v in (fr[1], fr[2], fr[3]):
            cv.put(px, py, fr[4])
    return cv


# ---------------------------------------------------------------- salidas
def sheet(cells, cols, gap, scale, bg=None):
    cw, ch = cells[0].w, cells[0].h
    rows = (len(cells) + cols - 1) // cols
    w, h = (cw + gap) * cols + gap, (ch + gap) * rows + gap
    img = Image.new("RGBA", (w, h), bg if bg else (0, 0, 0, 0))
    for i, c in enumerate(cells):
        img.alpha_composite(c.image(), (gap + (i % cols) * (cw + gap), gap + (i // cols) * (ch + gap)))
    return img.resize((w * scale, h * scale), Image.NEAREST)


def main():
    os.makedirs(OUT, exist_ok=True)
    bg_sticker = hexc("3a0d18") + (255,)
    for sid in STICKERS:  # el esmalte de la B llega hasta r - 6 (grande) y r - 2,2 (chico); exigimos un píxel libre
        big_r, small_r = dice_reach(sid, BIG), dice_reach(sid, 19)
        ok = big_r <= BIG / 2 - 7 and small_r <= 9.5 - 2.2 - .8
        print(f"{sid:11s} grande {big_r:5.2f}/{BIG / 2 - 7:.1f}  chico {small_r:5.2f}/6.5  {'ok' if ok else 'TOCA EL ARO'}")
    for name, fn in (("A", sticker_a), ("B", sticker_b), ("C", sticker_c)):
        big = {sid: fn(sid, BIG) for sid in STICKERS}
        small = {sid: fn(sid, 19) for sid in STICKERS}
        sheet([big[k] for k in STICKERS], 6, 3, 4, bg_sticker).save(os.path.join(OUT, f"sticker-{name}-x4.png"))
        sheet([small[k] for k in STICKERS], 6, 2, 4, bg_sticker).save(os.path.join(OUT, f"sticker-{name}-chico-x4.png"))
        for sid, c in big.items():
            c.image().save(os.path.join(OUT, f"_st-{name}-{sid}.png"))
        on_thermos(small).save(os.path.join(OUT, f"sticker-{name}-termo.png"))
    # hoy
    today = Image.open(os.path.join(ROOT, "assets/art/pixel-v3/stickers-v3.png")).convert("RGBA")
    cells = []
    art = {}
    for i, sid in enumerate(STICKERS):
        cv = Canvas(19, 19)
        cv.a = np.array(today.crop((i * 19, 0, (i + 1) * 19, 19)))
        cells.append(cv)
        art[sid] = cv
    sheet(cells, 6, 2, 4, bg_sticker).save(os.path.join(OUT, "sticker-hoy-x4.png"))
    on_thermos(art).save(os.path.join(OUT, "sticker-hoy-termo.png"))

    for name, fn in (("A", coin_a), ("B", coin_b), ("C", coin_c)):
        cells = [fn(rar, fam, em, cid) if fn is coin_b else fn(rar, fam, em) for cid, _, rar, fam, em in COINS]
        sheet(cells, 8, 2, 6, bg_sticker).save(os.path.join(OUT, f"moneda-{name}-x6.png"))
        for (cid, *_), c in zip(COINS, cells):
            c.image().save(os.path.join(OUT, f"_co-{name}-{cid}.png"))
    print("listo:", OUT)


if __name__ == "__main__":
    main()
