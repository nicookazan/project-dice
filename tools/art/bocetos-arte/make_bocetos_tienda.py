"""Maquetas de los bocetos sobre el maletín real (tienda-v3.png) y fila de las monedas de hoy. Escribe en test-results/bocetos-arte/.
Correr después de make_bocetos_stickers_monedas.py. Uso: py -3.13 tools/art/bocetos-arte/make_bocetos_tienda.py
"""
from __future__ import annotations

import os
import re

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(ROOT, "test-results", "bocetos-arte")
ART = os.path.join(ROOT, "assets", "art", "pixel-v3")
COINS = ["full", "reserve_roll", "two_rolls", "extra_hand"]
COIN_X = [580, 670, 760, 850]
Y = 525
CROP = (505, 445, 1345, 625)
BG = (0x3a, 0x0d, 0x18, 255)


def paste_center(base, art, cx, cy, scale=2):
    big = art.resize((art.width * scale, art.height * scale), Image.NEAREST)
    base.alpha_composite(big, (cx - big.width // 2, cy - big.height // 2))


def main():
    shop = Image.open(os.path.join(ART, "tienda-v3.png")).convert("RGBA")
    icons = Image.open(os.path.join(ART, "tienda-iconos-v3.png")).convert("RGBA")
    pack = icons.crop((44, 0, 88, 44))
    for name in "ABC":
        base = shop.resize((shop.width * 2, shop.height * 2), Image.NEAREST)
        for cid, x in zip(COINS, COIN_X):
            paste_center(base, Image.open(os.path.join(OUT, f"_co-{name}-{cid}.png")), x, Y)
        paste_center(base, Image.open(os.path.join(OUT, f"_st-{name}-trio.png")), 1035, Y)
        paste_center(base, pack, 1222, Y)
        base.crop(CROP).save(os.path.join(OUT, f"tienda-{name}.png"))
    # hoy: captura real del juego
    real = Image.open(os.path.join(ROOT, "test-results", "aj2-tienda.png")).convert("RGBA")
    real.crop(CROP).save(os.path.join(OUT, "tienda-hoy.png"))

    # monedas de hoy, con el mismo orden que los bocetos
    old = Image.open(os.path.join(ART, "coins-v3.png")).convert("RGBA")
    new = Image.open(os.path.join(ART, "coins-nuevas-v3.png")).convert("RGBA")
    src = open(os.path.join(ROOT, "scripts", "coin_art.gd"), encoding="utf-8").read()
    new_ids = re.findall(r'"(\w+)"', src[src.index("NEW_IDS = ["):src.index("const Coins")])
    old_ids = ["full", "straight", "generala", "poker", "even", "odd", "boost", "roll"]
    order = ["full", "generala", "quick_cash", "reserve_roll", "boss_shield", "repair_all", "two_rolls", "extra_hand"]
    w = (32 + 2) * 8 + 2
    sheet = Image.new("RGBA", (w, 36), BG)
    for i, cid in enumerate(order):
        if cid in old_ids:
            k = old_ids.index(cid)
            cell = old.crop((k % 4 * 32, k // 4 * 32, k % 4 * 32 + 32, k // 4 * 32 + 32))
        else:
            k = new_ids.index(cid)
            cell = new.crop((k % 6 * 32, k // 6 * 32, k % 6 * 32 + 32, k // 6 * 32 + 32))
        sheet.alpha_composite(cell, (2 + i * 34, 2))
    sheet.resize((w * 6, 36 * 6), Image.NEAREST).save(os.path.join(OUT, "moneda-hoy-x6.png"))

    # cuántas monedas del catálogo tienen arte
    data = open(os.path.join(ROOT, "scripts", "coins.gd"), encoding="utf-8").read()
    catalog = re.findall(r'^\s*"(\w+)": \{"code": "([CU]\d+)"', data, re.M)
    drawn = [c for c, _ in catalog if c in old_ids or c in new_ids]
    print("catálogo", len(catalog), "con arte", len(drawn), "sin arte", len(catalog) - len(drawn))
    print("en la hoja y no en el catálogo:", sorted((set(old_ids) | set(new_ids)) - {c for c, _ in catalog}))


if __name__ == "__main__":
    main()
