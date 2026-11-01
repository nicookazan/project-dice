"""Genera pixel-v3/exteriores-v3.png (Fase 6): los seis exteriores de las ventanas.

Conversión fiel de assets/art/environment-v2/exteriores-v2.png (decisión del autor: se limpia, no se
rediseña). Cada panel se reduce a la grilla lógica del juego (401×110 px lógicos = el panorama de 801×220
px de pantalla), se aplana la textura con un suavizado que respeta bordes y se pinta con una paleta corta
propia del ambiente (k-means en Lab), quitando las manchas de 1 px sin borrar las estrellas.
Atlas: 2 columnas × 3 filas (orden: día, tarde / noche, espacio / agujero negro, cielo). Cada celda mide
402×111: el panel de 401×110 más una columna y una fila repetidas, para que el medio píxel de las ventanas
impares no tome el borde del panel vecino.

Ejecutar:  python tools/art/make_exteriores.py   (escribe también test-results/exteriores-v3-preview.png)
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_lib import clean_labels, upscale
from vendedor import to_lab, bilateral, kmeans, lab_to_rgb

SRC = "assets/art/environment-v2/exteriores-v2.png"
OUT = "assets/art/pixel-v3/exteriores-v3.png"
CW, CH = 401, 110
# colores por ambiente (cantidad de tonos): el cielo del día pide pocos; la galaxia y el cielo, más
PALETTE_SIZE = {"dia": 20, "tarde": 20, "noche": 18, "espacio": 22, "agujero_negro": 22, "cielo": 22}
# límites reales de los paneles en la hoja original (no son tercios iguales)
ROWS = [0, 342, 671, 1024]
COLS = [0, 768, 1536]
ORDER = ["dia", "tarde", "noche", "espacio", "agujero_negro", "cielo"]


def convert_cell(cell: Image.Image, k: int) -> tuple[np.ndarray, np.ndarray]:
    small = cell.convert("RGB").resize((CW, CH), Image.BOX)
    rgb = np.array(small).astype(np.float64)
    lab = to_lab(rgb)
    full = np.ones((CH, CW), bool)
    sm = bilateral(lab, full, r=2, ss=1.4, sr=8.0, iters=2)
    cent = kmeans(sm.reshape(-1, 3), k)
    idx = np.argmin(((sm.reshape(-1, 1, 3) - cent[None]) ** 2).sum(-1), 1).reshape(CH, CW).astype(np.int32)
    idx = clean_labels(idx, full, min_size=3, passes=1)
    pal = lab_to_rgb(cent)
    out = pal[idx]
    # estrellas y destellos: píxeles claramente más brillantes que su entorno no se borran
    lum = rgb @ np.array([0.299, 0.587, 0.114])
    from scipy import ndimage
    local = ndimage.uniform_filter(lum, 7)
    stars = (lum > local + 70) & (lum > 170)
    # su color se ajusta a la paleta del panel más dos tonos de brillo (blanco y dorado), sin colores sueltos
    extra = np.array([[255, 246, 224], [255, 214, 120]], np.uint8)
    pal2 = np.concatenate([pal, extra])
    d = ((rgb[stars][:, None, :] - pal2[None].astype(float)) ** 2).sum(-1)
    out[stars] = pal2[np.argmin(d, 1)]
    return out, pal2


def main() -> None:
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    src = Image.open(SRC).convert("RGB")
    atlas = np.zeros(((CH + 1) * 3, (CW + 1) * 2, 3), np.uint8)
    for i, name in enumerate(ORDER):
        col, row = i % 2, i // 2
        cell = src.crop((COLS[col], ROWS[row], COLS[col + 1], ROWS[row + 1]))
        out, pal = convert_cell(cell, PALETTE_SIZE[name])
        padded = np.pad(out, ((0, 1), (0, 1), (0, 0)), mode="edge")
        atlas[row * (CH + 1):(row + 1) * (CH + 1), col * (CW + 1):(col + 1) * (CW + 1)] = padded
        print(name, "colores:", len({tuple(p) for p in out.reshape(-1, 3).tolist()}))
    img = Image.fromarray(atlas)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT)
    os.makedirs("test-results", exist_ok=True)
    upscale(img, 2).save("test-results/exteriores-v3-preview.png")
    print("ok", img.size)


if __name__ == "__main__":
    main()
