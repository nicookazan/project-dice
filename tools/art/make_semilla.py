"""Arte de La Semilla (24/11/2026), a partir de los bocetos aprobados (A1, B1 y la terminal C2 + C3).

Escribe en assets/art/pixel-v3/semilla/ (píxeles lógicos; el juego los dibuja a 2×2):
  glifos-v1.png            Letras de la Matrix en blanco, celdas de 8×10. Fila 0: dígitos, 1: latinas, 2: katakana,
                           3: armenias. El juego las tiñe de verde. Imprime cuántas hay por fila (GLYPH_COUNTS).
  escombros-v1.png         Fila 0: 10 bloques de madera y revoque en celdas de 24×18. Fila 1 (y = 18): 4 nubes de
                           polvo en celdas de 24×24, con transparencia en tres escalones.
  guardianes-muerte-v1.png Una fila por guardián (ojo, figura, dado), cuadros de 124×100: 0–7 grietas blancas que
                           crecen, 8 silueta blanca (destello), 9–32 los 24 pedazos en que se parte.

Los guardianes salen de guardian-*-v3.png sin tocar su dibujo. Ejecutar: py -3.13 tools/art/make_semilla.py
"""
from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage
from scipy.spatial import ConvexHull

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ART = os.path.join(ROOT, "assets", "art", "pixel-v3")
OUT = os.path.join(ART, "semilla")
FONTS = os.path.join(os.environ.get("WINDIR", "C:/Windows"), "Fonts")


def hexc(s: str):
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


# ---------------------------------------------------------------- glifos

GLYPH_SETS = [
    ("0123456789", "lucon.ttf"),
    ("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "lucon.ttf"),
    ("アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン", "msgothic.ttc"),
    ("ԱԲԳԴԵԶԷԸԹԺԻԼԽԾԿՀՁՂՃՄՅՆՇՈՉՊՋՌՍՎՏՐՑՒՓՔՕՖ", "sylfaen.ttf"),
]


def glyphs():
    rows = []
    for chars, font_name in GLYPH_SETS:
        font = ImageFont.truetype(os.path.join(FONTS, font_name), 10)
        row = []
        for ch in chars:
            img = Image.new("L", (8, 10), 0)
            d = ImageDraw.Draw(img)
            d.fontmode = "1"
            box = d.textbbox((0, 0), ch, font=font)
            d.text(((8 - (box[2] - box[0])) // 2 - box[0], (10 - (box[3] - box[1])) // 2 - box[1]), ch, font=font, fill=255)
            m = np.asarray(img) > 127
            if m.sum() > 2:
                row.append(m)
        rows.append(row)
    width = max(len(r) for r in rows) * 8
    sheet = np.zeros((10 * len(rows), width, 4), np.uint8)
    for r, row in enumerate(rows):
        for i, m in enumerate(row):
            cell = sheet[r * 10:(r + 1) * 10, i * 8:(i + 1) * 8]
            cell[m] = (255, 255, 255, 255)
    Image.fromarray(sheet, "RGBA").save(os.path.join(OUT, "glifos-v1.png"))
    print("GLYPH_COUNTS :=", [len(r) for r in rows])


# ---------------------------------------------------------------- escombros y polvo

WOOD = [hexc(c) for c in ("3a1e0e", "5a3218", "7a4520", "9a5a2a", "b87538")]
PLASTER = [hexc(c) for c in ("4a4038", "6e6052", "948270", "b8a48c", "d8c4a8")]
DUST = [hexc(c) for c in ("c9a27a", "a88660", "e3c9a0", "8a6a4c")]


def block(rng, w, h, pal):
    # Pedazos llenos: las cuatro esquinas corridas hacia adentro y un par de puntos de quiebre en los bordes.
    jx, jy = w * 0.22, h * 0.22
    pts = np.array([(rng.uniform(0, jx), rng.uniform(0, jy)), (w - 1 - rng.uniform(0, jx), rng.uniform(0, jy)),
                    (w - 1 - rng.uniform(0, jx), h - 1 - rng.uniform(0, jy)), (rng.uniform(0, jx), h - 1 - rng.uniform(0, jy)),
                    (rng.uniform(w * 0.3, w * 0.7), 0), (w - 1, rng.uniform(h * 0.3, h * 0.7))])
    hull = ConvexHull(pts)
    img = Image.new("L", (w, h), 0)
    ImageDraw.Draw(img).polygon([tuple(pts[i]) for i in hull.vertices], fill=1)
    m = np.asarray(img) > 0
    rgb = np.zeros((h, w, 3), np.uint8)
    yy, xx = np.mgrid[0:h, 0:w]
    shade = ((xx + yy) / (w + h) * 3).astype(int)
    for i in range(4):
        rgb[shade == i] = pal[min(4 - i, 4)]
    if pal is WOOD:
        rgb[yy % 4 == 0] = pal[1]
    rgb[m & ~ndimage.binary_erosion(m)] = pal[0]
    return rgb, m


def debris():
    rng = np.random.default_rng(57)
    sheet = np.zeros((18 + 24, 240, 4), np.uint8)
    for i in range(10):
        w, h = int(rng.integers(10, 23)), int(rng.integers(7, 17))
        rgb, m = block(rng, w, h, WOOD if i < 6 else PLASTER)
        cell = sheet[0:18, i * 24:(i + 1) * 24]
        oy, ox = (18 - h) // 2, (24 - w) // 2
        sub = cell[oy:oy + h, ox:ox + w]
        sub[m, :3] = rgb[m]
        sub[m, 3] = 255
    bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16
    for i, r in enumerate((5, 7, 9, 11)):
        yy, xx = np.mgrid[0:24, 0:24]
        d = np.hypot(xx + 0.5 - 12, yy + 0.5 - 12) / r
        lumps = np.zeros((24, 24), bool)
        for k in range(5):
            a = rng.uniform(0, 6.28)
            cx, cy, rr = 12 + math.cos(a) * r * 0.45, 12 + math.sin(a) * r * 0.45, r * rng.uniform(0.5, 0.75)
            lumps |= np.hypot(xx + 0.5 - cx, yy + 0.5 - cy) < rr
        inside = (d < 0.8) | lumps
        alpha = np.where(d < 0.45, 0.62, np.where(d < 0.75, 0.42, 0.24))
        alpha = np.where(inside & (np.tile(bayer, (6, 6)) < alpha + 0.35), alpha, 0)
        col = np.array(DUST[i % len(DUST)], np.float32)
        shade = np.where(yy < 12 - r * 0.2, 1.12, 0.9)[..., None]
        cell = sheet[18:42, i * 24:(i + 1) * 24]
        cell[..., :3] = np.clip(col * shade, 0, 255).astype(np.uint8)
        cell[..., 3] = (alpha * 255).astype(np.uint8)
    Image.fromarray(sheet, "RGBA").save(os.path.join(OUT, "escombros-v1.png"))


# ---------------------------------------------------------------- muerte de los guardianes

PIECES = 24
CRACK_STAGES = 8


def bresenham(x0, y0, x1, y1):
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        yield x0, y0
        if x0 == x1 and y0 == y1:
            return
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def cracks(rng, cx, cy, w, h, n=7, steps=22):
    pts = []
    pending = [(cx, cy, k * 0.9 + rng.uniform(0, 0.4), 0) for k in range(n)]
    branches = 0
    while pending:
        x, y, a, t = pending.pop()
        for _ in range(steps):
            a += rng.normal(0, 0.25)
            nx, ny = x + math.cos(a) * 2.5, y + math.sin(a) * 2.5
            for px, py in bresenham(int(round(x)), int(round(y)), int(round(nx)), int(round(ny))):
                if 0 <= px < w and 0 <= py < h:
                    pts.append((px, py, t))
            x, y, t = nx, ny, t + 1
            if not (0 <= x < w and 0 <= y < h):
                break
            if rng.random() < 0.12 and branches < 60:
                branches += 1
                pending.append((x, y, a + rng.choice([-1, 1]) * rng.uniform(0.5, 1.1), t))
    return pts


def guardians():
    names = ("ojo", "figura", "dado")
    w, h = 124, 100
    frames = CRACK_STAGES + 1 + PIECES
    sheet = np.zeros((h * 3, w * frames, 4), np.uint8)
    for row, name in enumerate(names):
        rng = np.random.default_rng(11 + row)
        src = np.asarray(Image.open(os.path.join(ART, "guardianes", "guardian-%s-v3.png" % name)).convert("RGBA")).astype(np.float32)
        mask = src[..., 3] > 0
        pts = cracks(rng, w / 2, h / 2, w, h)
        for k in range(CRACK_STAGES):
            f = (k + 1) / CRACK_STAGES
            img = src.copy()
            img[..., :3] = img[..., :3] * (1 - f * 0.35) + 255 * f * 0.35
            for x, y, t in pts:
                if t <= f * 22 and mask[y, x]:
                    img[y, x, :3] = 255
            sheet[row * h:(row + 1) * h, k * w:(k + 1) * w] = np.clip(img, 0, 255).astype(np.uint8)
        white = np.zeros((h, w, 4), np.uint8)
        white[mask] = (255, 255, 255, 255)
        sheet[row * h:(row + 1) * h, CRACK_STAGES * w:(CRACK_STAGES + 1) * w] = white
        ys, xs = np.nonzero(mask)
        seeds = np.stack([xs, ys], 1)[rng.choice(len(xs), PIECES, replace=False)]
        yy, xx = np.mgrid[0:h, 0:w]
        dist = np.stack([(xx - sx) ** 2 + (yy - sy) ** 2 for sx, sy in seeds])
        lab = dist.argmin(0)
        for p in range(PIECES):
            pm = mask & (lab == p)
            piece = np.zeros((h, w, 4), np.float32)
            piece[pm, :3] = src[pm, :3] * 0.6 + 255 * 0.4
            piece[pm, 3] = 255
            edge = pm & ~ndimage.binary_erosion(pm)
            piece[edge, :3] = 255
            col = CRACK_STAGES + 1 + p
            sheet[row * h:(row + 1) * h, col * w:(col + 1) * w] = piece.astype(np.uint8)
    Image.fromarray(sheet, "RGBA").save(os.path.join(OUT, "guardianes-muerte-v1.png"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    glyphs()
    debris()
    guardians()
    print("listo:", OUT)
