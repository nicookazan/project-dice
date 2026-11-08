"""Bocetos de los paquetes de monedas (chico «2» y grande «5»), en celdas de 32×32 como coins-v4.png.

Tres ideas que usan las piezas de las fichas esmaltadas (aros por rareza, esmaltes, contorno #2a1a14, luz arriba a la
izquierda): cartucho de banco, bolsita de terciopelo y pila con faja.
Uso: py -3.13 tools/art/bocetos-jefes/paquetes.py
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit as K  # noqa: E402
from tienda import FULL, NO_OFFERS, D, item_mask, text_center, FONT  # noqa: E402

OUTL = (42, 26, 20, 255)
COPPER = ["#2a0e10", "#54200f", "#86391a", "#b25c2a", "#d8854a", "#f2ae74", "#ffdcb0"]
GOLD = ["#2e1508", "#5c300c", "#96601a", "#c98f24", "#ecbc42", "#ffe07a", "#fff8c8"]
SILVER = ["#1c2038", "#3a4058", "#5e667e", "#868fa6", "#aeb8c8", "#d8dfe8", "#ffffff"]
VIOLET = ["#1a0c34", "#381a66", "#5a2c96", "#8048c4", "#a874e0", "#d0a8f4", "#f6e8ff"]
BORDO = ["#2c0812", "#5a1024", "#8c1c2e", "#b23040", "#d85a60"]
NOCHE = ["#081028", "#10204c", "#1c3a7c", "#2f5cae", "#5c8ad8"]
FIELTRO = ["#08261a", "#10442c", "#1c6a42", "#2f9058", "#62bc7c"]
KRAFT = ["#5a3a1c", "#8a6034", "#b88a52", "#dcb47a", "#f2d8a8"]
CREAM = ["#7a5230", "#c29a64", "#ecd8ac", "#fff2d2", "#ffffff"]
DIG = {"2": ["###", "..#", "###", "#..", "###"], "5": ["###", "#..", "###", "..#", "###"]}


def digit(L, d, x, y, c):
    for gy, row in enumerate(DIG[d]):
        for gx, v in enumerate(row):
            if v == "#": L.px([(x + gx, y + gy)], c)


def done(L):
    return K.outline(L.im, OUTL)


def coin_face(L, cx, cy, r, rim, enamel):
    """Ficha vista de frente, chica: aro, esmalte y brillo."""
    L.ellipse(cx - r, cy - r, cx + r, cy + r, rim[3]); L.ellipse(cx - r, cy - r, cx + r - 1, cy + r - 1, rim[5])
    L.ellipse(cx - r + 1, cy - r + 1, cx + r - 1, cy + r - 1, rim[4])
    L.ellipse(cx - r + 2, cy - r + 2, cx + r - 2, cy + r - 2, enamel[2]); L.px([(cx - r + 3, cy - r + 3)], enamel[4])


def coin_edge(L, x, y, w, rim, enamel, h=5):
    """Ficha vista de canto (en una pila): elipse de arriba y canto con estrías."""
    L.rect(x, y + 1, x + w, y + h, rim[2])
    for k in range(x + 1, x + w, 2): L.px([(k, y + h - 1)], rim[1])
    L.ellipse(x, y - 1, x + w, y + 2, rim[4]); L.ellipse(x + 2, y, x + w - 2, y + 1, enamel[2])


# ------------------------------------------------------------------ A: cartucho de banco
def cartucho(big):
    L = K.Layer(32, 32)
    rolls = [(4, 18, "2", COPPER, BORDO)] if not big else [(3, 20, "5", GOLD, BORDO), (7, 9, None, GOLD, NOCHE)]
    for i, (x, y, num, rim, paper) in enumerate(rolls[::-1]):
        w = 24 if not big else 24
        h = 10
        L.rect(x + 3, y, x + w, y + h, paper[2]); L.rect(x + 3, y, x + w, y + 1, paper[4]); L.rect(x + 3, y + h - 1, x + w, y + h, paper[1])
        for k in range(x + 4, x + w, 3): L.px([(k, y + 2)], paper[3])
        L.rect(x + w - 2, y + 1, x + w + 1, y + h - 1, paper[1])            # punta doblada
        L.px([(x + w + 1, y + 2), (x + w + 1, y + 4), (x + w + 1, y + 6)], paper[0])
        coin_face(L, x + 3, y + h // 2, 5, rim, FIELTRO)                     # la ficha que asoma
        if num:
            lx = x + 10
            L.rect(lx, y + 1, lx + 8, y + h - 1, CREAM[3]); L.rect(lx, y + h - 1, lx + 8, y + h - 1, CREAM[1])
            digit(L, num, lx + 3, y + 3, BORDO[1])
    return done(L)


# ------------------------------------------------------------------ B: bolsita de terciopelo
def bolsita(big):
    L = K.Layer(32, 32)
    s = 1.0 if big else .82
    cx = 16
    bw, top, bot = int(12 * s), int(32 - 26 * s), 30
    neck = top + int(7 * s)
    L.ellipse(cx - bw, neck - 2, cx + bw, bot, NOCHE[2])
    L.ellipse(cx - bw + 2, neck, cx + bw - 4, bot - 4, NOCHE[3]); L.ellipse(cx - bw + 3, neck + 1, cx - 2, neck + 8, NOCHE[4])
    L.ellipse(cx - bw + 1, bot - 7, cx + bw - 1, bot, NOCHE[1]) if False else L.rect(cx - bw + 3, bot - 2, cx + bw - 3, bot - 1, NOCHE[1])
    L.poly([(cx - 5, neck), (cx + 5, neck), (cx + 7, top), (cx - 7, top)], NOCHE[2]); L.rect(cx - 6, top, cx + 6, top, NOCHE[4])
    if big:   # fichas que asoman por la boca
        coin_face(L, cx - 4, top - 2, 3, GOLD, BORDO); coin_face(L, cx + 3, top - 3, 3, VIOLET, FIELTRO)
        L.poly([(cx - 5, neck), (cx + 5, neck), (cx + 7, top + 1), (cx - 7, top + 1)], NOCHE[2]); L.rect(cx - 6, top + 1, cx + 6, top + 1, NOCHE[4])
    L.rect(cx - 6, neck - 1, cx + 6, neck, GOLD[4]); L.px([(cx - 6, neck - 1), (cx + 6, neck)], GOLD[2])   # cordón
    L.line([(cx + 5, neck), (cx + 8, neck + 5)], GOLD[4]); L.px([(cx + 8, neck + 6)], GOLD[5])
    rim = GOLD if big else COPPER
    my = neck + int(9 * s)
    coin_face(L, cx - 1, my, 5 if big else 4, rim, CREAM)                 # medallón cosido con el número
    digit(L, "5" if big else "2", cx - 2, my - 2, BORDO[1])
    return done(L)


# ------------------------------------------------------------------ C: pila con faja
def pila(big):
    L = K.Layer(32, 32)
    n = 5 if big else 2
    rims = [COPPER, SILVER, GOLD, VIOLET, COPPER] if big else [COPPER, SILVER]
    enamels = [BORDO, NOCHE, FIELTRO, BORDO, NOCHE]
    x, w = 4, 24
    step = 5 if big else 6
    base = 25
    for i in range(n):
        coin_edge(L, x, base - i * step, w, rims[i], enamels[i], h=step)
    top = base - (n - 1) * step
    L.ellipse(x, top - 3, x + w, top + 3, rims[n - 1][4]); L.ellipse(x + 2, top - 2, x + w - 2, top + 2, enamels[n - 1][3])
    L.px([(x + 6, top - 1), (x + 7, top - 1)], enamels[n - 1][4])
    fy = (top + base + step) // 2 - 3 if big else base + 1
    band = GOLD if big else KRAFT
    L.rect(x - 1, fy, x + w + 1, fy + 6, band[3] if big else KRAFT[3]); L.rect(x - 1, fy, x + w + 1, fy, band[5] if big else KRAFT[4])
    L.rect(x - 1, fy + 6, x + w + 1, fy + 6, band[1] if big else KRAFT[1])
    digit(L, "5" if big else "2", x + w // 2 - 1, fy + 1, BORDO[1])
    if not big:   # una ficha más, apoyada al costado
        coin_face(L, x + w + 1, base - 2, 4, GOLD, FIELTRO) if False else None
    return done(L)


OPTIONS = [("A", "Cartucho de banco", cartucho), ("B", "Bolsita de terciopelo", bolsita), ("C", "Pila con faja", pila)]


def on_velvet(cells, k=4):
    bg = NO_OFFERS.crop((600, 470, 600 + 32 * k * len(cells) // 2 + 40, 470 + 32 * k // 2 + 20)).resize((32 * k * len(cells) + 80, 32 * k + 40), Image.NEAREST)
    for i, c in enumerate(cells):
        bg.alpha_composite(c.resize((32 * k, 32 * k), Image.NEAREST), (20 + i * (32 * k + 40), 20))
    return bg


def in_shop(cell_small, cell_big):
    """Los dos paquetes en el lugar de las monedas del maletín, al tamaño que tienen hoy las monedas (~2,8×)."""
    out = NO_OFFERS.copy()
    full = np.array(FULL)
    a = np.array(out)
    for box in ((622, 477, 90, 97),):
        m = item_mask(FULL, NO_OFFERS, box)
    size = 88
    for cell, cx in ((cell_small, 667), (cell_big, 757)):
        big = cell.resize((size, size), Image.NEAREST)
        out.alpha_composite(big, (cx - size // 2, 482))
    text_center(out, "$3", 667, 593, "#ecbc42"); text_center(out, "$6", 757, 593, "#ecbc42")
    return out.crop((520, 440, 905, 625)).resize((770, 370), Image.NEAREST)


def main():
    old = Image.open(os.path.join(K.ART, "coins-v4.png")).convert("RGBA")
    cur = [old.crop((((75 + k) % 11) * 32, ((75 + k) // 11) * 32, ((75 + k) % 11) * 32 + 32, ((75 + k) // 11) * 32 + 32)) for k in (0, 1)]
    on_velvet(cur).save(os.path.join(D, "paquetes-hoy.png"))
    in_shop(*cur).save(os.path.join(D, "paquetes-hoy-tienda.png"))
    for op, name, fn in OPTIONS:
        cells = [fn(False), fn(True)]
        on_velvet(cells).save(os.path.join(D, f"paquetes-{op}.png"))
        in_shop(*cells).save(os.path.join(D, f"paquetes-{op}-tienda.png"))
        print(op, name)


if __name__ == "__main__":
    main()
