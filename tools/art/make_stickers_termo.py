"""Genera assets/art/pixel-v3/stickers-termo-v3.png: los seis stickers girados cada uno en su ángulo fijo del termo.

Cada sticker tiene un lugar propio en el termo (como pegado a mano): la posición vive en scripts/sticker_art.gd
(THERMOS_SPOTS) y el giro se hornea acá, en celdas de 25×25 px lógicos, en el mismo orden que stickers-v3.png.
Si cambia un ángulo en ANGLES, cambiarlo también en THERMOS_SPOTS (lo usa la animación de pegado).
El giro respeta la grilla (rotsprite simple): se amplía ×8, se gira por vecino más cercano y se vuelve a reducir
tomando el centro de cada bloque, así no aparecen colores nuevos ni medios píxeles.
Ejecutar:  py -3.13 tools/art/make_stickers_termo.py   (trabaja en la raíz del proyecto). Requiere Pillow y numpy.
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image

SRC = "assets/art/pixel-v3/stickers-v3.png"
OUT = "assets/art/pixel-v3/stickers-termo-v3.png"
PREVIEW = "test-results/stickers-termo-v3-x6.png"
IDS = ["pair_loose", "trio", "straight", "full", "poker", "generala"]
CELL = 19
RCELL = 25
# grados, antihorario (como Image.rotate); el mismo dato está en THERMOS_SPOTS de sticker_art.gd
ANGLES = {"pair_loose": -8, "trio": 15, "straight": 4, "full": -14, "poker": 18, "generala": -5}


def rotsprite(img: Image.Image, deg: float, k: int = 8) -> Image.Image:
    big = img.resize((img.width * k, img.height * k), Image.NEAREST).rotate(deg, resample=Image.NEAREST)
    arr = np.array(big)[k // 2::k, k // 2::k]
    return Image.fromarray(np.ascontiguousarray(arr), "RGBA")


def main() -> None:
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    src = Image.open(SRC).convert("RGBA")
    sheet = Image.new("RGBA", (RCELL * len(IDS), RCELL), (0, 0, 0, 0))
    pad = (RCELL - CELL) // 2
    for i, sid in enumerate(IDS):
        cell = Image.new("RGBA", (RCELL, RCELL), (0, 0, 0, 0))
        cell.alpha_composite(src.crop((i * CELL, 0, (i + 1) * CELL, CELL)), (pad, pad))
        sheet.alpha_composite(rotsprite(cell, ANGLES[sid]), (i * RCELL, 0))
    sheet.save(OUT)
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    sheet.resize((sheet.width * 6, sheet.height * 6), Image.NEAREST).save(PREVIEW)
    print("ok stickers termo", sheet.size)


if __name__ == "__main__":
    main()
