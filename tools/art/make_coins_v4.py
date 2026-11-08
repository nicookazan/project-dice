"""Hoja de las monedas en ficha esmaltada (TX9, D17): assets/art/pixel-v3/coins-v4.png.

75 monedas del catálogo (en el orden de `Coins.DATA`) más los dos paquetes, celdas de 32×32 px lógicos, 11 columnas.
El aro marca la rareza y el esmalte la familia; los dos se leen de scripts/coins.gd. Los dos paquetes se copian sin cambios
de coins-nuevas-v3.png. El dibujo base (ficha, relieve, dado modelo) vive en tools/art/bocetos-arte/ y se reutiliza acá.
Uso: py -3.13 tools/art/make_coins_v4.py        (escribe también test-results/coins-v4-x4.png y la lista de ids)
"""
from __future__ import annotations

import importlib.util
import math
import os
import re
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
BOC = os.path.join(HERE, "bocetos-arte")


def load(name, file):
    spec = importlib.util.spec_from_file_location(name, os.path.join(BOC, file))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


mf = load("mf", "make_bocetos_monedas_faltantes.py")
sm = mf.sm  # el mismo módulo, con los esmaltes nuevos ya cargados
from pixel_lib import bresenham  # noqa: E402

M, from_rows = sm.M, sm.from_rows
OUT = os.path.join(ROOT, "assets", "art", "pixel-v3", "coins-v4.png")
OLD_NEW = os.path.join(ROOT, "assets", "art", "pixel-v3", "coins-nuevas-v3.png")
COLUMNS = 11
S = 32


# ---------------------------------------------------------------- emblemas de las monedas que ya tenían dibujo
def line(m, x0, y0, x1, y1, c="#"):
    for x, y in bresenham(x0, y0, x1, y1):
        m.set(x, y, c)


def erase_disc(m, cx, cy, r):
    m.disc(cx, cy, r, ".")


def e_sun():  # Pares
    m = M(19, 19)
    m.disc(9.5, 9.5, 4.6)
    for a in range(8):
        dx, dy = math.cos(a * math.pi / 4), math.sin(a * math.pi / 4)
        line(m, round(9 + dx * 6.2), round(9 + dy * 6.2), round(9 + dx * 8.6), round(9 + dy * 8.6))
    m.set(7, 8, "o")
    m.set(11, 8, "o")
    line(m, 8, 11, 10, 11, "o")
    return m


def e_moon():  # Impares
    m = M(19, 17)
    m.disc(7.5, 8.5, 7.6)
    erase_disc(m, 11.0, 6.5, 6.4)
    m.rect(15, 2, 1, 5)
    m.rect(13, 4, 5, 1)
    m.rect(14, 3, 3, 3)
    return m


def e_two_dice_boost():  # Impulso 1 y 4
    m = M(19, 19)
    m.rect(0, 0, 9, 9)
    m.set(2, 2, "o")
    m.set(6, 6, "o")
    m.rect(10, 10, 9, 9)
    for k in (2, 4, 6):
        m.set(10 + k, 10 + k, "o")
    return m


def e_roll():  # Una tirada más
    m = M(19, 19)
    mf.ring_arrow(m)
    m.rect(6, 6, 7, 7)
    m.set(8, 8, "o")
    m.set(10, 10, "o")
    return m


def e_stack():  # Cobrador
    m = M(17, 17)
    for k, xo in enumerate((1, 0, 2)):
        y = 2 + k * 5
        m.rect(xo + 2, y, 11, 1)
        m.rect(xo, y + 1, 15, 3)
        m.rect(xo + 1, y + 4, 13, 1)
        m.rect(xo + 1, y + 3, 13, 1, "o")
    return m


def e_chevrons():  # Veterano de nivel
    m = M(19, 18)
    for k in range(3):
        y = k * 5.0
        m.poly([(0, 5 + y), (9.5, y), (19, 5 + y), (19, 8 + y), (9.5, 3 + y), (0, 8 + y)])
    return m


def e_served():  # Servida
    m = M(20, 18)
    m.rect(0, 6, 12, 12)
    m.rect(5, 11, 2, 2, "o")
    m.rect(16, 0, 1, 9)
    m.rect(12, 4, 9, 1)
    for x, y in ((14, 2), (18, 2), (14, 6), (18, 6)):
        m.set(x, y)
    return m


def e_leftovers():  # Sobrantes
    m = M(19, 17)
    for x, y in ((0, 0), (6, 0), (0, 6), (6, 6)):
        m.rect(x, y, 5, 5)
    m.rect(13, 11, 6, 6)
    m.rect(14, 12, 4, 4, ".")
    m.rect(15, 13, 2, 2, "o")
    return m


def e_reroll_all():  # Relanzo total
    m = M(19, 19)
    mf.ring_arrow(m)
    for x, y in ((5, 6), (11, 6), (8, 9), (5, 12), (11, 12)):
        m.rect(x, y, 2, 2)
    return m


def e_mult2():  # Mult +2
    m = M(20, 15)
    mf.text(m, "+", 0, 5, 2)
    mf.text(m, "2", 7, 0, 3)
    mf.text(m, "x", 17, 0, 1, "o")
    return m


def e_points_bag():  # Bolsa de puntos
    m = M(22, 10)
    mf.text(m, "+30", 0, 0, 2)
    return m


def e_flip():  # Voltear dado
    m = M(20, 17)
    m.rect(0, 9, 8, 8)
    m.rect(3, 12, 2, 2, "o")
    m.rect(12, 9, 8, 8)
    for x, y in ((13, 10), (17, 10), (13, 12), (17, 12), (13, 14), (17, 14)):
        m.rect(x, y, 2, 1, "o")
    m.rect(3, 2, 14, 2)
    m.poly([(0, 3), (5, 0), (5, 6)])
    m.poly([(20, 3), (15, 0), (15, 6)])
    return m


def e_discount_tag():  # Descuento de visita
    m = M(19, 17)
    m.poly([(0, 8.5), (6, 1), (19, 1), (19, 16), (6, 16)])
    m.rect(3, 7, 2, 2, "o")
    m.rect(8, 3, 3, 3, "o")
    m.rect(14, 11, 3, 3, "o")
    line(m, 16, 3, 8, 13, "o")
    line(m, 15, 3, 7, 13, "o")
    line(m, 17, 4, 9, 14, "o")
    return m


def e_even_boost():  # Impulso par
    m = M(22, 10)
    mf.text(m, "246", 0, 0, 2)
    return m


EXISTING = {
    "full": sm.e_full, "straight": mf.cat_straight, "generala": sm.e_crown, "poker": mf.cat_poker, "even": e_sun, "odd": e_moon,
    "boost": e_two_dice_boost, "roll": e_roll, "extra_hand": sm.e_hand, "reserve_roll": sm.e_cup, "collector": e_stack,
    "level_veteran": e_chevrons, "served": e_served, "leftovers": e_leftovers, "reroll_all": e_reroll_all, "mult_plus2": e_mult2,
    "points_bag": e_points_bag, "flip_die": e_flip, "two_rolls": sm.e_two_rolls, "boss_shield": sm.e_shield,
    "quick_cash": sm.e_cash, "visit_discount": e_discount_tag, "repair_all": sm.e_gems, "even_boost": e_even_boost,
}
EMBLEMS = dict(mf.EMBLEMS)
EMBLEMS.update(EXISTING)


# ---------------------------------------------------------------- catálogo
def catalog():
    """Todas las monedas de Coins.DATA, en su orden: (id, rareza, familia)."""
    src = open(os.path.join(ROOT, "scripts", "coins.gd"), encoding="utf-8").read()
    rows = re.findall(r'^\s*"(\w+)": \{"code": "[CU]\d+", "name": "[^"]+", "description": "[^"]+", "rarity": "(\w+)", "family": "(\w+)"', src, re.M)
    return rows


def render(rarity, family, em):
    cv = sm.coin_c(rarity, mf.FAMILY_ENAMEL[family], em)
    rows = em().rows()
    ox, oy = (S - len(rows[0])) // 2, (S - len(rows)) // 2
    for x, y, side, v, anti in getattr(em, "dice", []):
        cv.blit(sm.big_die(side, v, anti), ox + x - 3, oy + y - 3)
    return cv


def main():
    rows = catalog()
    missing = [r[0] for r in rows if r[0] not in EMBLEMS]
    assert not missing, f"faltan emblemas: {missing}"
    cells = [render(r[1], r[2], EMBLEMS[r[0]]).image() for r in rows]
    old = Image.open(OLD_NEW).convert("RGBA")
    for k in (16, 17):  # paquetes chico y grande, sin cambios
        cells.append(old.crop(((k % 6) * S, (k // 6) * S, (k % 6) * S + S, (k // 6) * S + S)))
    ids = [r[0] for r in rows] + ["pack_small", "pack_large"]
    n_rows = (len(cells) + COLUMNS - 1) // COLUMNS
    sheet = Image.new("RGBA", (COLUMNS * S, n_rows * S), (0, 0, 0, 0))
    for i, c in enumerate(cells):
        sheet.alpha_composite(c, ((i % COLUMNS) * S, (i // COLUMNS) * S))
    sheet.save(OUT)
    os.makedirs(os.path.join(ROOT, "test-results"), exist_ok=True)
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(os.path.join(ROOT, "test-results", "coins-v4-x4.png"))
    print(len(rows), "monedas +", 2, "paquetes ->", OUT, sheet.size)
    print("IDS:", ", ".join(f'"{i}"' for i in ids))


if __name__ == "__main__":
    main()
