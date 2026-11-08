"""Hojas de los stickers por nivel (TX8, D17): calcomanía brillante (A) hasta el nivel 9 y medallón dorado (B) desde el 10.

Escribe en assets/art/pixel-v3/:
  stickers-grande-v4.png  6 stickers × 2 estilos, celdas de 52×52 (fila 0 = A, fila 1 = B). Tienda, álbum, sobre y revelado:
                          en pantalla se dibujan a 104 px (cada píxel de la hoja = 2×2).
  stickers-termo-v4.png   los mismos seis en la versión chica de 19×19, cada uno girado en su ángulo fijo del termo, celdas
                          de 25×25 (fila 0 = A, fila 1 = B). Mismo giro por «rotsprite» que stickers-termo-v3.png.
El dibujo vive en tools/art/bocetos-arte/make_bocetos_stickers_monedas.py (dado modelo del autor, escalera en barras).
Antes de guardar comprueba que ningún dado ni destello toque el aro. Uso: py -3.13 tools/art/make_stickers_v4.py
"""
from __future__ import annotations

import importlib.util
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
spec = importlib.util.spec_from_file_location("sm", os.path.join(HERE, "bocetos-arte", "make_bocetos_stickers_monedas.py"))
sm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sm)

OUT_DIR = os.path.join(ROOT, "assets", "art", "pixel-v3")
IDS = list(sm.STICKERS)  # pair_loose, trio, straight, full, poker, generala: el orden de sticker_art.gd
BIG, SMALL, RCELL = sm.BIG, 19, 25
# grados, antihorario; el mismo dato está en THERMOS_SPOTS de scripts/sticker_art.gd
ANGLES = {"pair_loose": -8, "trio": 15, "straight": 4, "full": -14, "poker": 18, "generala": -5}
STYLES = (sm.sticker_a, sm.sticker_b)


def main():
    for sid in IDS:
        big_r, small_r = sm.dice_reach(sid, BIG), sm.dice_reach(sid, SMALL)
        assert big_r <= BIG / 2 - 7 and small_r <= 9.5 - 2.2 - .8, f"{sid}: toca el aro (grande {big_r:.2f}, chico {small_r:.2f})"
    big = Image.new("RGBA", (BIG * len(IDS), BIG * 2), (0, 0, 0, 0))
    termo = Image.new("RGBA", (RCELL * len(IDS), RCELL * 2), (0, 0, 0, 0))
    pad = (RCELL - SMALL) // 2
    for row, style in enumerate(STYLES):
        for i, sid in enumerate(IDS):
            big.alpha_composite(style(sid, BIG).image(), (i * BIG, row * BIG))
            cell = Image.new("RGBA", (RCELL, RCELL), (0, 0, 0, 0))
            cell.alpha_composite(style(sid, SMALL).image(), (pad, pad))
            termo.alpha_composite(sm.rotsprite(cell, ANGLES[sid]), (i * RCELL, row * RCELL))
    big.save(os.path.join(OUT_DIR, "stickers-grande-v4.png"))
    termo.save(os.path.join(OUT_DIR, "stickers-termo-v4.png"))
    prev = os.path.join(ROOT, "test-results")
    os.makedirs(prev, exist_ok=True)
    big.resize((big.width * 3, big.height * 3), Image.NEAREST).save(os.path.join(prev, "stickers-grande-v4-x3.png"))
    termo.resize((termo.width * 6, termo.height * 6), Image.NEAREST).save(os.path.join(prev, "stickers-termo-v4-x6.png"))
    print("ok", big.size, termo.size)


if __name__ == "__main__":
    main()
