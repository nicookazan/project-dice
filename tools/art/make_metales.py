"""Máscaras de los metales nuevos (TX3, D16): hierro oxidado B, cobre oxidado A y oro A.

Genera assets/art/pixel-v3/metales-mascaras-v3.png (124×62): dos celdas de 62×62 con la máscara fija de
cada metal oxidado (hierro oxidado a la izquierda, cobre oxidado a la derecha). El oro no necesita máscara.
Canales: R = hay óxido/pátina (0 o 255), G = parte de tono propia del manchado (centrada en 128),
B = picadura (solo hierro). Alfa siempre 255.
El shader die_body.gdshader suma el brillo de la cara (shade) y recorre la rampa de color, así las
máscaras no alteran los puntos y funcionan con cualquier gema y cualquier cara. Mismo azar de los bocetos
(semillas fijas): el resultado es siempre idéntico.
Uso: py -3 tools/art/make_metales.py
Las caras se leen de assets/art/dice-faces-v1/negro-v1.png (protegido, solo lectura).
"""
import os

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SHEET = Image.open(os.path.join(ROOT, "assets/art/dice-faces-v1/negro-v1.png")).convert("RGBA")
REGION6 = (1040, 536, 416, 424)
DISPLAY = (3, 2, 56, 57)
OUT = os.path.join(ROOT, "assets/art/pixel-v3/metales-mascaras-v3.png")


def silhouette():
    x, y, w, h = REGION6
    crop = SHEET.crop((x, y, x + w, y + h)).convert("RGBa").resize((DISPLAY[2], DISPLAY[3]), Image.LANCZOS).convert("RGBA")
    canvas = Image.new("RGBA", (62, 62), (0, 0, 0, 0))
    canvas.paste(crop, (DISPLAY[0], DISPLAY[1]))
    return np.array(canvas)[..., 3] > 128


def noise(seed, blur, size=62):
    rng = np.random.default_rng(seed)
    img = Image.fromarray((rng.random((size, size)) * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(blur))
    n = np.array(img).astype(float)
    lo, hi = np.percentile(n, 2), np.percentile(n, 98)
    return np.clip((n - lo) / (hi - lo + 1e-6), 0, 1)


def streaks(seed, down, across):
    rng = np.random.default_rng(seed)
    n = ndimage.gaussian_filter(rng.random((62, 62)), sigma=(down, across), mode="wrap")
    lo, hi = np.percentile(n, 2), np.percentile(n, 98)
    return np.clip((n - lo) / (hi - lo + 1e-6), 0, 1)


def encode(value):
    return np.clip((value + 0.5) * 255, 0, 255).astype("uint8")


def cell(cover_mask, tone_part, pits):
    out = np.zeros((62, 62, 4), "uint8")
    out[..., 0] = np.where(cover_mask, 255, 0)
    out[..., 1] = encode(tone_part)
    out[..., 2] = np.where(pits & cover_mask, 255, 0)
    out[..., 3] = 255
    return out


def main():
    alpha = silhouette()
    dist = ndimage.distance_transform_edt(alpha)
    rows = np.arange(62)[:, None] * np.ones((1, 62))
    # Hierro oxidado B: goteos desde arriba y costra en las esquinas.
    blot, fine = noise(11, 2.6), noise(12, .7)
    drip = streaks(14, 11, .9)
    corner = np.clip(1 - dist / 9, 0, 1)
    iron_cover = (drip * .62 + corner * .55 + blot * .25) > .5
    iron_tone = (drip - .5) * .55 + (fine - .5) * .3
    iron_pits = noise(15, .8) > .88
    # Cobre oxidado A: manchas con el cobre asomando en los bordes.
    blot2, fine2 = noise(21, 2.4), noise(22, .7)
    patina = (blot2 * .8 + fine2 * .2 - np.clip(1 - dist / 5, 0, 1) * .38) > .40
    patina_tone = (fine2 - .5) * .5 + (blot2 - .5) * .3
    atlas = np.concatenate([cell(iron_cover, iron_tone, iron_pits), cell(patina, patina_tone, np.zeros((62, 62), bool))], axis=1)
    Image.fromarray(atlas, "RGBA").save(OUT)
    print("máscaras:", OUT)


if __name__ == "__main__":
    main()
