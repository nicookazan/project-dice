"""Bocetos de las 51 monedas que hoy son una ficha con abreviatura, en el estilo elegido (C, ficha esmaltada).

El aro sigue la rareza (cobre común, plata rara, violeta épica, oro legendaria) y el esmalte sigue la familia de coins.gd.
Los datos (nombre, rareza, familia) se leen de scripts/coins.gd; los ids que ya tienen dibujo se saltean.
Escribe test-results/bocetos-arte/faltan/<id>.png (× 4) y una hoja de control. Uso:
  py -3.13 tools/art/bocetos-arte/make_bocetos_monedas_faltantes.py
"""
from __future__ import annotations

import importlib.util
import json
import math
import os
import re
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art"))
spec = importlib.util.spec_from_file_location("sm", os.path.join(HERE, "make_bocetos_stickers_monedas.py"))
sm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sm)
M, from_rows, ramp = sm.M, sm.from_rows, sm.ramp

OUT = os.path.join(ROOT, "test-results", "bocetos-arte", "faltan")

# esmaltes nuevos, sacados de colores que ya están en el juego (mostaza del oro viejo, turquesa de las gemas, etc.)
sm.ENAMEL.update({
    "mostaza": ramp("2e1c06", "5a3a0c", "8a6018", "b48a2a", "dcb85a"),
    "turquesa": ramp("062628", "0c4446", "146a68", "22908a", "5cbcb0"),
    "pizarra": ramp("12161e", "232a36", "374252", "505e70", "7e8c9c"),
    "ciruela": ramp("1e0a1c", "3a1236", "5a1e52", "7c3070", "a85a96"),
    "naranja": ramp("2a0e04", "561e08", "8a3610", "b4561c", "de8a44"),
})
FAMILY_ENAMEL = {
    "category": "bordo", "points": "noche", "number": "mostaza", "die": "mostaza", "die_type": "turquesa", "gem": "turquesa",
    "general": "fieltro", "rule": "fieltro", "rhythm": "pizarra", "position": "pizarra", "economy": "cuero", "infra": "cuero",
    "growth": "ciruela", "use": "naranja"}
FAMILY_NAMES = {
    "category": "Multiplicador por categoría", "points": "Puntos por categoría", "number": "Números", "die": "Pares e impares",
    "die_type": "Tipo de dado", "gem": "Gemas", "general": "Generales", "rule": "Reglas", "rhythm": "Ritmo", "position": "Posición",
    "economy": "Economía", "infra": "Infraestructura", "growth": "Crecimiento", "use": "Un uso"}

FONT = {
    "0": ["###", "#.#", "#.#", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"], "2": ["###", "..#", "###", "#..", "###"],
    "3": ["###", "..#", ".##", "..#", "###"], "4": ["#.#", "#.#", "###", "..#", "..#"], "5": ["###", "#..", "###", "..#", "###"],
    "6": ["###", "#..", "###", "#.#", "###"], "+": ["...", ".#.", "###", ".#.", "..."], "x": ["...", "#.#", ".#.", "#.#", "..."],
    "%": ["#.#", "..#", ".#.", "#..", "#.#"], "-": ["...", "...", "###", "...", "..."],
}


# ---------------------------------------------------------------- piezas
def line(m, x0, y0, x1, y1, c="#"):
    for x, y in sm.bresenham(x0, y0, x1, y1) if hasattr(sm, "bresenham") else []:
        m.set(x, y, c)


def text(m, s, x, y, k=1, c="#"):
    for ch in s:
        g = FONT[ch]
        for gy, row in enumerate(g):
            for gx, v in enumerate(row):
                if v == "#":
                    m.rect(x + gx * k, y + gy * k, k, k, c)
        x += (len(g[0]) + 1) * k
    return x


def text_w(s, k=1):
    return sum((len(FONT[ch][0]) + 1) * k for ch in s) - k


PIPS = sm.PIPS


def die(m, x, y, s, v, pip=1):
    m.rect(x, y, s, s)
    lo, hi = 1, s - 1 - pip
    for fx, fy in PIPS[v]:
        m.rect(x + round(lo + (hi - lo) * fx), y + round(lo + (hi - lo) * fy), pip, pip, "o")


def ring_arrow(m, cx=9.5, cy=9.5, r=9.0, inner=6.8):
    m.disc(cx, cy, r)
    m.disc(cx, cy, inner, ".")
    for y in range(0, 7):
        for x in range(11, 19):
            m.set(x, y, ".")
    for hy, w in enumerate([2, 4, 5, 4, 2]):
        m.rect(11, hy, w, 1)


def cycle(m):
    """Dos flechas curvas que se persiguen (renovar)."""
    m.disc(9.5, 9.5, 8.6)
    m.disc(9.5, 9.5, 6.2, ".")
    for y in range(0, 9):
        for x in range(10, 19):
            if x - 10 < 9 - y:
                m.set(x, y, ".")
    for y in range(10, 19):
        for x in range(0, 9):
            if 9 - x < y - 9:
                m.set(x, y, ".")
    m.poly([(9, 0), (15, 3), (9, 6)])
    m.poly([(10, 19), (4, 16), (10, 13)])


GEM = ["..#####..", ".#o###o#.", "#########", ".#######.", "..##o##..", "...###...", "....#...."]


def gem(m, x, y):
    for gy, r in enumerate(GEM):
        for gx, ch in enumerate(r):
            if ch != ".":
                m.set(x + gx, y + gy, ch)


def cup(m, x, y, w=14, h=15):
    m.poly([(x, y + 2), (x + w, y + 2), (x + w - 2, y + h), (x + 2, y + h)])
    m.rect(x - 1, y, w + 2, 3)
    m.rect(x, y + 3, w, 1, "o")


def flame(m, x, y, s=1.0):
    pts = [(x + 4 * s, y), (x + 7 * s, y + 5 * s), (x + 8 * s, y + 8 * s), (x + 4 * s, y + 11 * s), (x, y + 8 * s), (x + 1 * s, y + 4 * s), (x + 3 * s, y + 6 * s)]
    m.poly(pts)


def star(m, cx, cy, r, ri, c="#"):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else ri
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    m.poly(pts, c)


def coin_disc(m, cx, cy, r):
    m.disc(cx, cy, r)
    m.disc(cx, cy, r - 1.6, "o")
    m.disc(cx, cy, r - 2.6)


# ---------------------------------------------------------------- emblemas por moneda
def cat_pair():
    m = M(16, 8)
    die(m, 0, 0, 7, 2)
    die(m, 9, 1, 7, 2)
    return m


def cat_twopair():
    m = M(16, 16)
    for x, y, v in ((0, 0, 2), (9, 0, 2), (0, 9, 5), (9, 9, 5)):
        die(m, x, y, 7, v)
    return m


def cat_trio():
    m = M(16, 16)
    for x, y in ((0, 0), (9, 0), (4, 9)):
        die(m, x, y, 7, 3)
    return m


def cat_straight():
    """Escalera: cinco barras que suben, como «Acumulada» pero sin la flecha (la flecha queda para Acumulada)."""
    m = M(19, 16)
    for i, h in enumerate((4, 7, 10, 13, 16)):
        m.rect(i * 4, 16 - h, 3, h)
    return m


def cat_poker():
    m = M(16, 16)
    for x, y in ((0, 0), (9, 0), (0, 9), (9, 9)):
        die(m, x, y, 7, 4)
    return m


CAT = {"pair": cat_pair, "twopair": cat_twopair, "trio": cat_trio, "straight": cat_straight, "full": sm.e_full, "poker": cat_poker, "generala": sm.e_crown}


DICE = {}  # id → [(x, y, lado, valor, anti)], dados que se pintan encima del relieve con el dibujo del dado real


def die_slot(m, x, y, s):
    """Reserva el lugar del dado en la máscara (para que el relieve le dé contorno y sombra)."""
    cut = 2 if s >= 12 else 1
    for j in range(s):
        for i in range(s):
            if min(i, s - 1 - i) + min(j, s - 1 - j) >= cut:
                m.set(x + i, y + j)


def number_die(v):
    def f():
        m = M(16, 16)
        die_slot(m, 0, 0, 16)
        return m
    f.dice = [(0, 0, 16, v, False)]
    return f


def two_dice(a, b, w=18):
    """Dos dados de 12 en diagonal: el de adelante tapa la esquina de abajo a la derecha del de atrás, así que el de atrás
    usa la otra diagonal (sus puntos quedan a la vista)."""
    def f():
        m = M(w, 18)
        die_slot(m, 0, 0, 12)
        die_slot(m, 6, 6, 12)
        return m
    f.dice = [(0, 0, 12, a, a in (2, 3)), (6, 6, 12, b, False)]
    return f


def e_plus1():
    m = M(17, 10)
    text(m, "+1", 0, 0, 2)
    text(m, "x", 14, 0, 1)
    return m


def e_spent():
    m = M(17, 17)
    coin_disc(m, 8.5, 8.5, 8.4)
    for x, y in ((9, 1), (8, 2), (8, 3), (9, 4), (10, 5), (9, 6), (8, 7), (8, 8), (9, 9), (10, 10), (11, 11), (11, 12), (12, 13)):
        m.set(x, y, "o")
        m.set(x + 1, y, ".")
    m.poly([(13, 12), (17, 10), (17, 17), (12, 17)], ".")
    return m


def e_ingot():
    m = M(18, 14)
    m.poly([(4, 0), (14, 0), (17, 6), (1, 6)])
    m.poly([(3, 7), (15, 7), (18, 14), (0, 14)])
    m.rect(5, 2, 8, 1, "o")
    m.rect(4, 10, 10, 1, "o")
    return m


def e_cup_digit(d):
    def f():
        m = M(16, 17)
        cup(m, 1, 0)
        text(m, d, 6, 6, 1, "o")
        m.rect(5, 5, 6, 0, "o")
        return m
    return f


def e_cycle():
    m = M(19, 19)
    cycle(m)
    return m


def die_plus(extra):
    v = 3 if extra == "gem" else 1
    def f():
        m = M(19, 18)
        die_slot(m, 0, 0, 14)
        if extra == "nut":
            m.poly([(13, 9), (17, 9), (19, 13), (17, 17), (13, 17), (11, 13)])
            m.disc(15, 13, 1.6, "o")
        elif extra == "flame":
            flame(m, 11, 6)
        elif extra == "gem":
            gem(m, 10, 11)
        return m
    f.dice = [(0, 0, 14, v, False)]
    return f


def e_stairs4():
    m = M(18, 14)
    for i in range(4):
        m.rect(5 + i * 3 + (1 if i else 0), 14 - (i + 1) * 3, 4 if i else 4, (i + 1) * 3)
    text(m, "4", 0, 0, 1)
    m.rect(0, 6, 3, 0)
    return m


def e_star():
    m = M(19, 18)
    star(m, 9.5, 10, 9.5, 4.2)
    star(m, 9.5, 10, 3.4, 1.5, "o")
    return m


def e_reroll_one():
    m = M(19, 19)
    ring_arrow(m)
    die(m, 6, 6, 7, 1)
    m.rect(9, 9, 1, 1, "o")
    return m


def e_pair_double():
    m = M(17, 15)
    die(m, 0, 0, 7, 2)
    die(m, 9, 0, 7, 2)
    text(m, "x2", 4, 9, 1)
    m.rect(0, 0, 0, 0)
    return m


e_sixes = two_dice(6, 6)


def e_unused():
    m = M(19, 7)
    for i, cx in enumerate((3.5, 9.5, 15.5)):
        m.disc(cx, 3.5, 3.4)
        if i:
            m.disc(cx, 3.5, 1.8, "o")
    return m


def e_hourglass():
    m = M(13, 18)
    m.rect(0, 0, 13, 2)
    m.rect(0, 16, 13, 2)
    m.poly([(1, 2), (12, 2), (7, 9), (12, 16), (1, 16), (6, 9)])
    m.poly([(3, 15), (10, 15), (6.5, 11)], "o")
    return m


def e_second():
    m = M(14, 15)
    text(m, "2", 0, 0, 3)
    m.disc(12, 2.5, 2)
    m.set(12, 2, "o")
    m.rect(10, 6, 4, 1)
    return m


def e_thermos():
    m = M(13, 19)
    m.rect(3, 0, 7, 3)
    m.rect(2, 3, 9, 2, "o")
    m.rect(2, 3, 9, 1)
    m.rect(1, 5, 11, 14)
    m.rect(1, 9, 11, 1, "o")
    m.rect(0, 6, 1, 8)
    return m


def e_collection():
    m = M(19, 11)
    for cx in (5.5, 9.5, 13.5):  # tres monedas en fila, cada una tapando un poco a la anterior
        m.disc(cx, 5.5, 5.6, ".")
        coin_disc(m, cx, 5.5, 5.4)
    return m


def e_percent():
    m = M(15, 15)
    text(m, "%", 3, 0, 3)
    return m


def e_pocket(small=False):
    def f():
        w, h = (12, 11) if small else (17, 16)
        m = M(w + (6 if small else 0), h)
        m.poly([(0, 0), (w, 0), (w, h - 4), (w / 2, h), (0, h - 4)])
        for x in range(1, w - 1, 2):
            m.set(x, 2, "o")
        if small:
            text(m, "+", w + 2, 0, 1)
        return m
    return f


def e_discount():
    m = M(18, 15)
    m.rect(2, 0, 3, 9)
    m.poly([(0, 8), (7, 8), (3.5, 14)])
    text(m, "%", 9, 3, 2)
    return m


def e_tempered():
    m = M(17, 19)
    m.poly([(0, 1), (8.5, 0), (17, 1), (17, 10), (8.5, 19), (0, 10)])
    for gy, r in enumerate(GEM):
        for gx, ch in enumerate(r):
            if ch != ".":
                m.set(4 + gx, 5 + gy, "o")
    return m


def e_loupe():
    m = M(18, 18)
    m.disc(7, 7, 7)
    m.disc(7, 7, 5, ".")
    gem(m, 3, 4)
    for i in range(6):
        m.rect(11 + i, 11 + i, 2, 2)
    return m


def e_medal():
    """Veterana (diseño del autor, 07/11): cintas cruzadas en X y medalla grande con la estrella hundida."""
    m = M(16, 20)
    m.poly([(1, 0), (5, 0), (11, 8), (8, 9)])
    m.poly([(15, 0), (11, 0), (5, 8), (8, 9)])
    m.rect(7, 0, 2, 4, "o")  # el cruce de las cintas
    m.disc(8, 13, 6.8)
    star(m, 8, 13.6, 4.2, 1.8, "o")
    return m


def e_stack_up():
    """Acumulada (diseño del autor, 07/11): dos barras y una tercera que termina en flecha."""
    m = M(17, 17)
    m.rect(0, 11, 4, 6)
    m.rect(5, 7, 4, 10)
    m.rect(10, 5, 4, 12)
    m.poly([(12, 0), (16.6, 5.6), (7.6, 5.6)])
    return m


def e_streak():
    m = M(19, 11)
    for i in range(3):
        m.poly([(i * 6, 0), (i * 6 + 4, 0), (i * 6 + 9, 5.5), (i * 6 + 4, 11), (i * 6, 11), (i * 6 + 5, 5.5)])
    return m


def e_sword():
    m = M(13, 20)
    m.poly([(6.5, 0), (8.5, 3), (8.5, 13), (4.5, 13), (4.5, 3)])
    m.rect(6, 3, 1, 9, "o")
    m.rect(0, 13, 13, 2)
    m.rect(5, 15, 3, 3)
    m.disc(6.5, 19, 1.8)
    return m


def e_impulse(a, b):
    base = two_dice(a, b, 18)
    def f():
        m = base()
        m.poly([(14.5, 0), (18, 3.5), (16, 3.5), (16, 5.5), (13, 5.5), (13, 3.5), (11, 3.5)])  # flecha que sube
        return m
    f.dice = base.dice
    return f


def e_x2():
    m = M(15, 10)
    text(m, "x2", 0, 0, 2)
    return m


def e_gem_plus():
    m = M(17, 10)
    gem(m, 0, 2)
    text(m, "+", 11, 0, 2)
    return m


EMBLEMS = {
    "pair_mult": CAT["pair"], "twopair_mult": CAT["twopair"], "trio_mult": CAT["trio"],
    "pair_pts": CAT["pair"], "twopair_pts": CAT["twopair"], "trio_pts": CAT["trio"], "straight_pts": CAT["straight"],
    "full_pts": CAT["full"], "poker_pts": CAT["poker"], "generala_pts": CAT["generala"],
    "flat_mult": e_plus1, "spent": e_spent, "gold": e_ingot, "extra_roll_perm": e_cup_digit("4"), "free_renewal": e_cycle,
    "metal": die_plus("nut"), "elemental": die_plus("flame"), "gems": die_plus("gem"),
    "straight4": e_stairs4, "wildcard": e_star, "free_reroll": e_reroll_one, "pair_double": e_pair_double,
    "num_1": number_die(1), "num_2": number_die(2), "num_3": number_die(3), "num_4": number_die(4), "num_5": number_die(5), "num_6": number_die(6),
    "sixes": e_sixes, "first_roll": e_cup_digit("1"), "unused_rolls": e_unused, "last_roll": e_hourglass,
    "second_hand": e_second, "thermos": e_thermos, "collection": e_collection, "interest": e_percent,
    "pocket": e_pocket(), "pocket_small": e_pocket(True), "discount": e_discount,
    "tempered_gem": e_tempered, "jeweler": e_loupe, "veteran": e_medal, "accumulated": e_stack_up, "streak": e_streak, "bosshunter": e_sword,
    "boost_25": e_impulse(2, 5), "boost_36": e_impulse(3, 6), "double_mult": e_x2, "free_renewal_use": e_cycle, "repair_gem": e_gem_plus,
    "free_reroll_use": e_reroll_one,
}


def catalog():
    src = open(os.path.join(ROOT, "scripts", "coins.gd"), encoding="utf-8").read()
    art = open(os.path.join(ROOT, "scripts", "coin_art.gd"), encoding="utf-8").read()
    drawn = set(re.findall(r'"(\w+)"', art[art.index("NEW_IDS = ["):art.index("const Coins")]))
    drawn |= {"full", "straight", "generala", "poker", "even", "odd", "boost", "roll"}
    rows = re.findall(r'^\s*"(\w+)": \{"code": "([CU]\d+)", "name": "([^"]+)", "description": "([^"]+)", "rarity": "(\w+)", "family": "(\w+)"', src, re.M)
    return [dict(id=r[0], code=r[1], name=r[2], desc=r[3], rarity=r[4], family=r[5]) for r in rows if r[0] not in drawn]


def main():
    os.makedirs(OUT, exist_ok=True)
    coins = catalog()
    missing = [c["id"] for c in coins if c["id"] not in EMBLEMS]
    assert not missing, missing
    cells = []
    for c in coins:
        em = EMBLEMS[c["id"]]
        cv = sm.coin_c(c["rarity"], FAMILY_ENAMEL[c["family"]], em)
        rows = em().rows()
        ox, oy = (32 - len(rows[0])) // 2, (32 - len(rows)) // 2
        for x, y, side, v, anti in getattr(em, "dice", []):
            cv.blit(sm.big_die(side, v, anti), ox + x - 3, oy + y - 3)
        cv.save(os.path.join(OUT, f"{c['id']}.png"), 4)
        cells.append(cv)
    sm.sheet(cells, 9, 2, 3, (0x3a, 0x0d, 0x18, 255)).save(os.path.join(ROOT, "test-results", "bocetos-arte", "_faltan-hoja.png"))
    with open(os.path.join(OUT, "faltan.json"), "w", encoding="utf-8") as f:
        json.dump([dict(c, enamel=FAMILY_ENAMEL[c["family"]], family_name=FAMILY_NAMES[c["family"]]) for c in coins], f, ensure_ascii=False, indent=1)
    print(len(coins), "monedas")


if __name__ == "__main__":
    main()
