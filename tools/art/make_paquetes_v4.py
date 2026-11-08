"""Paquetes de monedas v4 (chico «2» y grande «5»): bolsita de terciopelo azul noche con cordón dorado y un medallón cosido con el
número (aro de cobre el chico, de oro el grande; del grande asoman dos fichas). Celdas de 32×32 como coins-v4.png.
Boceto aprobado el 08/11 (opción B de tools/art/bocetos-jefes/paquetes.py).
Uso: py -3.13 tools/art/make_paquetes_v4.py   (reemplaza las celdas 75 y 76 de coins-v4.png; make_coins_v4.py las usa al armar la hoja)
"""
from __future__ import annotations

import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "bocetos-jefes"))
import kit as K  # noqa: E402

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



def cells():
    """(chico, grande) como imágenes RGBA de 32×32."""
    return bolsita(False), bolsita(True)


def main():
    sheet_path = os.path.join(K.ART, "coins-v4.png")
    sheet = Image.open(sheet_path).convert("RGBA")
    for k, cell in zip((75, 76), cells()):
        x, y = (k % 11) * 32, (k // 11) * 32
        sheet.paste((0, 0, 0, 0), (x, y, x + 32, y + 32))
        sheet.alpha_composite(cell, (x, y))
    sheet.save(sheet_path)
    print("paquetes -> coins-v4.png celdas 75 y 76")


if __name__ == "__main__":
    main()
