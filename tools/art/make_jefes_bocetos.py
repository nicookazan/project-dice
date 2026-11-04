"""Bocetos de concepto de jefes (manos de la nube) para docs/JEFES-TEMATICOS.md.

Parten de la mano y la nube reales del juego (assets/art/pixel-v3/mano-v3.png y nube-v3.png): se
conserva la silueta y el sombreado; solo se repinta la rampa de color y se agregan objetos. No integra
nada en el juego. Escribe PNG en test-results/jefes-bocetos/ (ignorado por Git).

Ejecutar:  python tools/art/make_jefes_bocetos.py
"""
from __future__ import annotations

import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "test-results", "jefes-bocetos")
W, H, SCALE = 160, 96, 5
CLOUD_AT, HAND_AT = (15, 0), (51, 12)

BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0


def hexc(s: str):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def recolor(img: Image.Image, ramp: list[str]) -> Image.Image:
    """Mapea los colores únicos de la figura (ordenados por luminosidad) a una rampa nueva."""
    a = np.array(img.convert("RGBA"))
    opaque = a[..., 3] > 0
    cols = sorted({tuple(p) for p in a[opaque][:, :3]}, key=lum)
    n, m = len(cols), len(ramp)
    table = {c: hexc(ramp[min(m - 1, int(i * m / n))])[:3] for i, c in enumerate(cols)}
    out = a.copy()
    ys, xs = np.nonzero(opaque)
    for y, x in zip(ys, xs):
        out[y, x, :3] = table[tuple(a[y, x, :3])]
    return Image.fromarray(out)


def glow(im: Image.Image, cx, cy, r, color, power=1.6):
    px = im.load()
    for y in range(max(0, int(cy - r)), min(im.height, int(cy + r) + 1)):
        for x in range(max(0, int(cx - r)), min(im.width, int(cx + r) + 1)):
            d = math.hypot(x - cx, y - cy) / r
            if d < 1 and (1 - d) ** power > BAYER[y % 4, x % 4]:
                px[x, y] = color


def tentacle(d: ImageDraw.ImageDraw, pts, r0, color, dark, sucker):
    """Polilínea suave con radio decreciente y ventosas."""
    steps = 40
    path = []
    for i in range(steps + 1):
        t = i / steps
        n = len(pts) - 1
        k = min(n - 1, int(t * n))
        u = t * n - k
        path.append((pts[k][0] * (1 - u) + pts[k + 1][0] * u, pts[k][1] * (1 - u) + pts[k + 1][1] * u))
    for i, (x, y) in enumerate(path):
        r = max(1, r0 * (1 - i / steps) + 0.5)
        d.ellipse([x - r, y - r, x + r, y + r], fill=color)
    for i, (x, y) in enumerate(path):
        r = max(1, r0 * (1 - i / steps) + 0.5)
        if i % 5 == 2 and r >= 2:
            d.point((round(x), round(y + r * 0.4)), fill=sucker)
        d.point((round(x - r * 0.5), round(y - r * 0.5)), fill=dark) if i % 3 == 0 and r >= 2 else None


def sky(top: str, bottom: str, stars: bool = False, seed: int = 1) -> Image.Image:
    im = Image.new("RGBA", (W, H))
    t, b = hexc(top), hexc(bottom)
    px = im.load()
    for y in range(H):
        f = y / (H - 1)
        for x in range(W):
            f2 = min(1, max(0, f + (BAYER[y % 4, x % 4] - 0.5) * 0.18))
            px[x, y] = tuple(round(t[i] * (1 - f2) + b[i] * f2) for i in range(3)) + (255,)
    if stars:
        rnd = random.Random(seed)
        for _ in range(55):
            px[rnd.randrange(W), rnd.randrange(H)] = hexc(rnd.choice(["#ffffff", "#c9d6ff", "#ffe9a8"]))
    return im


def put(base: Image.Image, fig: Image.Image, at):
    base.alpha_composite(fig, at)


def scene(name, bg, cloud_ramp, hand_ramp, props_back=None, props_front=None):
    im = bg.copy()
    if props_back:
        props_back(im)
    cloud = Image.open(os.path.join(ROOT, "assets/art/pixel-v3/nube-v3.png")).convert("RGBA")
    hand = Image.open(os.path.join(ROOT, "assets/art/pixel-v3/mano-v3.png")).convert("RGBA").crop((0, 0, 61, 53))
    put(im, recolor(cloud, cloud_ramp), CLOUD_AT)
    put(im, recolor(hand, hand_ramp) if hand_ramp else hand, HAND_AT)
    if props_front:
        props_front(im)
    return name, im


def hp(x, y):  # coordenada de la mano -> lienzo
    return HAND_AT[0] + x, HAND_AT[1] + y


# ---------------------------------------------------------------- escenas

def murcielago():
    def back(im):
        d = ImageDraw.Draw(im)
        glow(im, 35, 43, 24, hexc("#fff3a8"), 1.8)
        glow(im, 35, 43, 17, hexc("#fff9d2"), 1.0)
        d.ellipse([22, 36, 48, 50], fill=hexc("#fff7c4"))
        # solo la luz proyectada, sin figura dentro
    def front(im):
        d = ImageDraw.Draw(im)
        x, y = hp(30, 6)
        d.rectangle([x - 4, y, x + 14, y + 2], fill=hexc("#3b4150"))  # puño
        d.point([(x, y), (x + 4, y), (x + 8, y)], fill=hexc("#8a93a8"))
    return scene("3A · El Gótico", sky("#070a1a", "#1a2347", True, 3),
                 ["#10152e", "#1c2750", "#2c3a73", "#4a5b9b"],
                 ["#0a0b10", "#181a24", "#2a2e3d", "#434a5e", "#6a7391"], back, front)


def farolero():
    def back(im):
        glow(im, 74, 54, 40, hexc("#1d8a4f"), 2.4)
    def front(im):
        d = ImageDraw.Draw(im)
        rx, ry = hp(27, 41)
        glow(im, rx, ry, 9, hexc("#5dff9a"), 1.4)
        d.rectangle([rx - 3, ry - 2, rx + 3, ry + 2], fill=hexc("#0e3d22"))
        d.rectangle([rx - 2, ry - 1, rx + 2, ry + 1], fill=hexc("#7dffb0"))
        d.point([(rx - 1, ry - 1), (rx, ry - 1)], fill=hexc("#ffffff"))
        # farol de luz sólida creado por el anillo
        lx, ly = 112, 44
        d.rectangle([lx, ly, lx + 16, ly + 3], fill=hexc("#3cd47a"))
        d.rectangle([lx + 3, ly + 3, lx + 13, ly + 22], fill=hexc("#4af08e"))
        d.rectangle([lx + 5, ly + 5, lx + 11, ly + 20], fill=hexc("#c8ffdd"))
        d.rectangle([lx + 2, ly + 22, lx + 14, ly + 25], fill=hexc("#3cd47a"))
        d.rectangle([lx + 6, ly - 4, lx + 10, ly - 1], fill=hexc("#3cd47a"))
        glow(im, lx + 8, ly + 12, 16, hexc("#3cd47a"), 2.6)
        # los dados "conservados" atrapados en la luz (máximo 3)
        for i in range(3):
            x0 = 12 + i * 11
            d.rectangle([x0, 76, x0 + 8, 84], fill=hexc("#aaffcf"), outline=hexc("#2fbd68"))
            d.point([(x0 + 4, 80)], fill=hexc("#0e3d22"))
    return scene("5B · El Farolero Cósmico", sky("#03040c", "#0a1230", True, 5),
                 ["#0f1a3d", "#1d2f6a", "#3a56a3", "#6f8fd6"], None, back, front)


def durmiente():
    def back(im):
        d = ImageDraw.Draw(im)
        # disco de acreción detrás
        d.ellipse([20, 48, 140, 86], fill=hexc("#7a2b00"))
        d.ellipse([28, 52, 132, 82], fill=hexc("#c8581a"))
        d.ellipse([40, 56, 120, 78], fill=hexc("#ffb347"))
        d.ellipse([50, 59, 110, 75], fill=hexc("#02020a"))
    def front(im):
        d = ImageDraw.Draw(im)
        g, gd, su = hexc("#2f7d5a"), hexc("#1a4a37"), hexc("#a8e6c1")
        tentacle(d, [hp(22, 46), hp(14, 56), hp(24, 66), hp(18, 78)], 4, g, gd, su)
        tentacle(d, [hp(31, 36), hp(34, 50), hp(44, 60), hp(38, 74)], 4, g, gd, su)
        tentacle(d, [hp(14, 38), hp(2, 46), hp(6, 60), hp(-4, 68)], 3.5, g, gd, su)
        tentacle(d, [hp(52, 32), hp(62, 44), hp(54, 56), hp(62, 66)], 3.5, g, gd, su)
        # ojo en la palma
        ex, ey = hp(37, 22)
        d.ellipse([ex - 7, ey - 4, ex + 7, ey + 4], fill=hexc("#f4f0b8"), outline=hexc("#0e2a20"))
        d.rectangle([ex - 1, ey - 4, ex + 1, ey + 4], fill=hexc("#10131c"))
        d.point([(ex - 5, ey - 2), (ex + 5, ey - 2)], fill=hexc("#ffffff"))
        glow(im, ex, ey, 11, hexc("#9bffb0"), 3.0)
        d.ellipse([ex - 7, ey - 4, ex + 7, ey + 4], fill=hexc("#f4f0b8"), outline=hexc("#0e2a20"))
        d.rectangle([ex - 1, ey - 4, ex + 1, ey + 4], fill=hexc("#10131c"))
    return scene("6C · El Durmiente del Abismo", sky("#000000", "#0b0414", True, 8),
                 ["#12081f", "#251243", "#3d2468", "#5c3b94"],
                 ["#0a2a22", "#164a3b", "#2f7d5a", "#58b085", "#a8e6c1"], back, front)


def visitante():
    def back(im):
        d = ImageDraw.Draw(im)
        # rayo tractor
        for y in range(60, 96):
            half = 6 + (y - 60) * 0.9
            for x in range(int(80 - half), int(80 + half) + 1):
                if 0 <= x < W and BAYER[y % 4, x % 4] < 0.55 - (y - 60) / 90:
                    im.putpixel((x, y), hexc("#d9ffb0"))
    def front(im):
        d = ImageDraw.Draw(im)
        # dado levitando en el haz
        d.rectangle([73, 78, 85, 90], fill=hexc("#f6f1e2"), outline=hexc("#6b6455"))
        for dx, dy in [(76, 81), (82, 81), (79, 84), (76, 87), (82, 87)]:
            d.point((dx, dy), fill=hexc("#1a1a1a"))
        # lente del ojo en la palma
        ex, ey = hp(37, 22)
        d.ellipse([ex - 4, ey - 3, ex + 4, ey + 3], fill=hexc("#10131c"))
        d.ellipse([ex - 2, ey - 1, ex + 2, ey + 1], fill=hexc("#c9ff7a"))
        # antenas-dedo: ventosas
        for fx, fy in [(21, 47), (30, 34), (14, 40)]:
            x, y = hp(fx, fy)
            d.point([(x, y), (x + 1, y)], fill=hexc("#cfffa0"))
    return scene("5A · El Visitante", sky("#04030f", "#10153a", True, 11),
                 ["#10153a", "#1d2a63", "#35479a", "#6a85d6"],
                 ["#17402a", "#2b7a3f", "#52b84e", "#8ee06a", "#d4ffa8"], back, front)


def payador():
    def back(im):
        d = ImageDraw.Draw(im)
        d.polygon([(0, 70), (40, 56), (90, 64), (140, 54), (160, 60), (160, 96), (0, 96)], fill=hexc("#7fa84d"))
        d.polygon([(0, 84), (60, 74), (120, 80), (160, 72), (160, 96), (0, 96)], fill=hexc("#5f8a36"))
        # rancho
        d.rectangle([118, 62, 146, 76], fill=hexc("#cdb88a"))
        d.polygon([(114, 62), (132, 50), (150, 62)], fill=hexc("#8a5a2b"))
        d.rectangle([128, 68, 134, 76], fill=hexc("#5a3a1a"))
    def front(im):
        d = ImageDraw.Draw(im)
        # as de espadas
        cx, cy = hp(26, 44)
        d.rectangle([cx - 5, cy - 8, cx + 5, cy + 8], fill=hexc("#f6f1e2"), outline=hexc("#3a2f22"))
        d.polygon([(cx, cy - 4), (cx - 3, cy), (cx - 1, cy + 2), (cx + 1, cy + 2), (cx + 3, cy)], fill=hexc("#1a1a1a"))
        d.rectangle([cx, cy + 2, cx, cy + 5], fill=hexc("#1a1a1a"))
        d.point([(cx - 3, cy - 6), (cx + 3, cy + 6)], fill=hexc("#1a1a1a"))
        # tientos trenzados en la muñeca
        x, y = hp(34, 6)
        for i in range(8):
            d.point((x - 6 + i * 2, y + (i % 2)), fill=hexc("#3a2312"))
            d.point((x - 5 + i * 2, y + 2 - (i % 2)), fill=hexc("#c79a5a"))
    return scene("1B · El Payador Tramposo", sky("#7ec8f2", "#d6f0ff"),
                 ["#9fc6e8", "#c6defa", "#e7f0fb", "#ffffff"],
                 ["#2a160a", "#4e2c14", "#7a4a22", "#a8703a", "#d29f62"], back, front)


def cebador():
    def back(im):
        d = ImageDraw.Draw(im)
        d.ellipse([112, 56, 144, 88], fill=hexc("#ffcf5a"))  # sol bajo
        d.rectangle([0, 82, 160, 96], fill=hexc("#3d5a2a"))
    def front(im):
        d = ImageDraw.Draw(im)
        rnd = random.Random(4)
        # yerba pegada a la piel
        a = np.array(im)
        for _ in range(70):
            x, y = hp(rnd.randrange(8, 56), rnd.randrange(10, 48))
            if tuple(a[y, x, :3]) not in [(255, 207, 90), (61, 90, 42)] and abs(a[y, x, 0] - a[y, x, 2]) > 20:
                d.point((x, y), fill=hexc(rnd.choice(["#3f7a1a", "#6fb02a", "#1f4a0c"])))
        # termo boca abajo, vacío (gotas que no caen)
        tx, ty = 119, 14
        d.rectangle([tx, ty, tx + 12, ty + 36], fill=hexc("#aeb7c2"), outline=hexc("#4c5663"))
        d.rectangle([tx + 2, ty + 2, tx + 4, ty + 34], fill=hexc("#e6ecf2"))
        d.rectangle([tx - 1, ty + 36, tx + 13, ty + 42], fill=hexc("#c0392b"), outline=hexc("#6b1a12"))
        d.rectangle([tx + 3, ty + 42, tx + 9, ty + 45], fill=hexc("#8a1f14"))
        d.point([(tx + 6, ty + 49), (tx + 6, ty + 55)], fill=hexc("#7fd0ff"))
        d.rectangle([tx + 9, ty + 4, tx + 11, ty + 6], fill=hexc("#4c5663"))
    return scene("2A · Don Cebador", sky("#f08a3c", "#ffd08a"),
                 ["#e07a3a", "#f2a35c", "#ffcc88", "#fff0d2"],
                 ["#4a2c0c", "#7a4a1a", "#a8702a", "#cf9650", "#e8bf80"], back, front)


def ground(im, y0, c1, c2=None):
    d = ImageDraw.Draw(im)
    d.rectangle([0, y0, W, H], fill=hexc(c1))
    if c2:
        d.rectangle([0, y0 + (H - y0) // 2, W, H], fill=hexc(c2))


def moon(im, cx, cy, r, c="#fff3c4", shade="#e8d9a0"):
    d = ImageDraw.Draw(im)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=hexc(c))
    for dx, dy, rr in [(-r // 3, -r // 4, r // 5), (r // 4, r // 5, r // 4), (-r // 5, r // 2, r // 6)]:
        d.ellipse([cx + dx - rr, cy + dy - rr, cx + dx + rr, cy + dy + rr], fill=hexc(shade))


def kioskero():
    def back(im):
        ground(im, 78, "#8c8f99", "#767985")
        d = ImageDraw.Draw(im)
        d.rectangle([108, 44, 150, 78], fill=hexc("#d8c9a0"))
        d.rectangle([112, 52, 146, 68], fill=hexc("#2a2f45"))
        for i in range(0, 44, 8):
            d.rectangle([106 + i, 38, 113 + i, 46], fill=hexc("#d63a3a" if (i // 8) % 2 == 0 else "#f6f1e2"))
        for x, y, c in [(116, 58, "#f4c542"), (124, 60, "#e86a8a"), (132, 57, "#6ac1e8"), (139, 60, "#9be86a")]:
            d.rectangle([x, y, x + 3, y + 5], fill=hexc(c))
    def front(im):
        d = ImageDraw.Draw(im)
        x, y = hp(24, 50)
        d.rectangle([x - 6, y - 3, x + 6, y + 4], fill=hexc("#4d9b55"), outline=hexc("#235a2b"))
        d.ellipse([x - 2, y - 1, x + 2, y + 2], outline=hexc("#bfe8c4"))
        gx, gy = hp(6, 46)
        d.rectangle([gx, gy, gx + 7, gy + 10], fill=hexc("#f06fa0"), outline=hexc("#8a2a50"))
        d.rectangle([gx + 1, gy + 3, gx + 6, gy + 6], fill=hexc("#fff0f6"))
        for i in range(9):  # trama del tejido
            d.point((HAND_AT[0] + 10 + i * 5, HAND_AT[1] + 5), fill=hexc("#f0a090"))
    return scene("1A · El Kioskero", sky("#8cd0f5", "#dff3ff"), ["#9fc6e8", "#c6defa", "#e7f0fb", "#ffffff"],
                 ["#5a1a1a", "#8a2a2a", "#b84040", "#d86a5a", "#f0a090"], back, front)


def palomas():
    def pigeon(d, x, y, flip=1, fly=False):
        d.ellipse([x - 4, y - 2, x + 4, y + 3], fill=hexc("#8d94a3"))
        d.ellipse([x + 3 * flip - 2, y - 5, x + 3 * flip + 2, y - 1], fill=hexc("#6b7280"))
        d.point((x + 5 * flip, y - 3), fill=hexc("#f0a030"))
        d.point((x + 3 * flip, y - 4), fill=hexc("#ffffff"))
        d.polygon([(x - 4, y), (x - 8, y + 1), (x - 4, y + 2)], fill=hexc("#555b66"))
        if fly:
            d.polygon([(x - 1, y - 2), (x - 4, y - 8), (x + 2, y - 3)], fill=hexc("#b5bbc7"))
        else:
            d.polygon([(x - 2, y - 1), (x + 2, y), (x - 1, y + 3)], fill=hexc("#aab0bc"))
    def back(im):
        ground(im, 80, "#c9c2a8", "#b7ae92")
        d = ImageDraw.Draw(im)
        d.rectangle([128, 52, 142, 80], fill=hexc("#9a9a9f"))
        d.rectangle([125, 78, 145, 80], fill=hexc("#7e7e84"))
        d.ellipse([130, 40, 140, 52], fill=hexc("#b4b4ba"))
    def front(im):
        d = ImageDraw.Draw(im)
        for hx, hy, f in [(24, 46, 1), (30, 33, 1), (46, 22, -1)]:
            pigeon(d, *hp(hx, hy), flip=f)
        pigeon(d, 18, 40, 1, True); pigeon(d, 128, 30, -1, True); pigeon(d, 112, 16, -1, True)
        rnd = random.Random(2)
        for _ in range(14):
            d.point((rnd.randrange(60, 100), rnd.randrange(74, 92)), fill=hexc("#e9d29a"))
    return scene("1C · El Rey de las Palomas", sky("#8cd0f5", "#dff3ff"), ["#9fc6e8", "#c6defa", "#e7f0fb", "#ffffff"],
                 ["#3a3f4a", "#586070", "#8a92a3", "#b9c0cc", "#e4e8ee"], back, front)


def chamuyero():
    def back(im):
        ground(im, 84, "#7a4a2a")
        d = ImageDraw.Draw(im)
        d.rectangle([0, 56, 160, 84], fill=hexc("#c0622e"))  # vagón del tren
        for x in range(8, 160, 34):
            d.rectangle([x, 62, x + 22, 76], fill=hexc("#ffd98a"), outline=hexc("#5a2a14"))
        for x in range(0, 160, 6):
            d.point((x, 58), fill=hexc("#8f4420"))
    def front(im):
        d = ImageDraw.Draw(im)
        for k in range(3):  # cadenas doradas
            pts = [hp(8 + k * 4, 20 + k), hp(14 + k * 4, 38 + k * 2), hp(26 + k * 4, 44 + k)]
            for (a, b) in zip(pts, pts[1:]):
                d.line([a, b], fill=hexc("#f6d24a"), width=1)
        for fx, fy, c in [(22, 40, "#e04a4a"), (30, 31, "#4a8ae0"), (14, 36, "#9be86a")]:
            x, y = hp(fx, fy)
            d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=hexc("#f6d24a"))
            d.point((x, y), fill=hexc(c))
        cx, cy = 118, 22
        d.rectangle([cx, cy, cx + 28, cy + 24], fill=hexc("#d6322a"), outline=hexc("#6b1210"))
        d.rectangle([cx + 12, cy + 24, cx + 15, cy + 38], fill=hexc("#6b4a2a"))
        for yy in (cy + 4, cy + 17):
            d.rectangle([cx + 4, yy, cx + 24, yy + 1], fill=hexc("#ffffff"))
        d.rectangle([cx + 6, cy + 9, cx + 8, cy + 11], fill=hexc("#ffffff"))
        d.rectangle([cx + 14, cy + 9, cx + 16, cy + 11], fill=hexc("#ffffff"))
        d.line([(cx + 17, cy + 8), (cx + 5, cy + 12)], fill=hexc("#ffffff"))
    return scene("2B · El Chamuyero", sky("#f08a3c", "#ffd08a"), ["#e07a3a", "#f2a35c", "#ffcc88", "#fff0d2"],
                 ["#5a4208", "#8a6a12", "#c9a227", "#f0d060", "#fff2a8"], back, front)


def referi():
    def back(im):
        d = ImageDraw.Draw(im)
        d.rectangle([0, 50, 160, 66], fill=hexc("#5b5f73"))
        rnd = random.Random(7)
        for _ in range(180):
            d.point((rnd.randrange(160), rnd.randrange(50, 66)), fill=hexc(rnd.choice(["#e04a4a", "#4a8ae0", "#f6d24a", "#f6f1e2"])))
        ground(im, 66, "#3f8a3a", "#367a32")
        d.rectangle([0, 80, 160, 81], fill=hexc("#ffffff"))
        d.arc([50, 66, 110, 100], 180, 360, fill=hexc("#ffffff"))
    def front(im):
        d = ImageDraw.Draw(im)
        x, y = hp(36, 8)
        for i in range(3):
            d.rectangle([x - 8, y + i * 3, x + 14, y + i * 3 + 1], fill=hexc("#10131c"))
        rnd = random.Random(5)
        for _ in range(16):
            d.point(hp(rnd.randrange(8, 40), rnd.randrange(12, 36)), fill=hexc(rnd.choice(["#3f8a3a", "#6fc05a"])))
        cx, cy = hp(4, 46)
        d.rectangle([cx, cy, cx + 9, cy + 14], fill=hexc("#e03030"), outline=hexc("#6b1010"))
        wx, wy = 112, 28
        d.ellipse([wx, wy, wx + 12, wy + 9], fill=hexc("#c9ced6"), outline=hexc("#4c5663"))
        d.rectangle([wx + 10, wy + 2, wx + 20, wy + 5], fill=hexc("#c9ced6"), outline=hexc("#4c5663"))
        d.point((wx + 5, wy + 4), fill=hexc("#10131c"))
        d.line([(wx + 2, wy), (wx - 8, wy - 12)], fill=hexc("#10131c"))
    return scene("2C · El Referí del Domingo", sky("#f08a3c", "#ffd08a"), ["#e07a3a", "#f2a35c", "#ffcc88", "#fff0d2"],
                 None, back, front)


def conde():
    def back(im):
        moon(im, 124, 30, 15, "#f4eee0", "#d9d0bd")
        d = ImageDraw.Draw(im)
        d.polygon([(0, 96), (0, 70), (12, 70), (12, 56), (16, 50), (20, 56), (20, 66), (34, 66), (34, 48), (38, 40), (42, 48), (42, 66), (60, 66), (60, 96)], fill=hexc("#0c0a16"))
        for x, y in [(37, 54), (16, 62)]:
            d.rectangle([x, y, x + 1, y + 2], fill=hexc("#ffd98a"))
    def front(im):
        d = ImageDraw.Draw(im)
        for fx, fy in [(21, 49), (31, 35), (14, 42), (6, 46)]:
            x, y = hp(fx, fy)
            d.polygon([(x - 1, y), (x + 1, y), (x, y + 6)], fill=hexc("#0c0a16"))
        rx, ry = hp(27, 41)
        d.rectangle([rx, ry, rx + 2, ry + 2], fill=hexc("#c0192b"), outline=hexc("#f6d24a"))
        gx, gy = 112, 46
        d.polygon([(gx, gy), (gx + 14, gy), (gx + 12, gy + 10), (gx + 2, gy + 10)], fill=hexc("#d9e6ff"), outline=hexc("#6b7a9a"))
        d.polygon([(gx + 1, gy + 3), (gx + 13, gy + 3), (gx + 12, gy + 9), (gx + 2, gy + 9)], fill=hexc("#b01226"))
        d.rectangle([gx + 6, gy + 10, gx + 8, gy + 17], fill=hexc("#6b7a9a"))
        d.rectangle([gx + 2, gy + 17, gx + 12, gy + 18], fill=hexc("#6b7a9a"))
        for bx, by in [(96, 14), (140, 52), (70, 20)]:
            d.polygon([(bx, by), (bx + 3, by - 2), (bx + 6, by), (bx + 3, by + 1)], fill=hexc("#0c0a16"))
    return scene("3B · El Conde Sed", sky("#07071a", "#2a1238", True, 9), ["#14102a", "#241c4a", "#3a2e6e", "#5a4a9a"],
                 ["#3b3550", "#6d6488", "#a79fc0", "#d9d3e8", "#f4f0fa"], back, front)


def lobizon():
    def back(im):
        moon(im, 34, 36, 24, "#fff3c4", "#e8d9a0")
        d = ImageDraw.Draw(im)
        for x in range(0, 160, 14):
            h = 14 + (x * 7) % 12
            d.polygon([(x, 96), (x + 7, 96 - h - 14), (x + 14, 96)], fill=hexc("#0a1410"))
        d.rectangle([0, 90, 160, 96], fill=hexc("#05100b"))
    def front(im):
        d = ImageDraw.Draw(im)
        rnd = random.Random(3)
        for _ in range(60):
            x, y = hp(rnd.randrange(6, 58), rnd.randrange(8, 46))
            d.line([(x, y), (x + rnd.choice([-1, 0, 1]), y + 2)], fill=hexc(rnd.choice(["#15161a", "#c8ccd3"])))
        for fx, fy in [(21, 49), (30, 35), (13, 41), (56, 34)]:
            x, y = hp(fx, fy)
            d.polygon([(x - 1, y), (x + 2, y), (x + 1, y + 5)], fill=hexc("#f4f0e0"))
        for _ in range(3):
            d.point((rnd.randrange(60, 150), rnd.randrange(8, 30)), fill=hexc("#7ec8e0"))
    return scene("3C · El Lobizón", sky("#050b14", "#14243a", True, 6), ["#0e1a2c", "#1a2c46", "#2e4468", "#4a6590"],
                 ["#23252b", "#3e414a", "#6b707b", "#9a9fa9", "#c8ccd3"], back, front)


def tahur():
    def back(im):
        d = ImageDraw.Draw(im)
        for y in range(0, 50, 3):
            d.rectangle([0, y, 160, y], fill=hexc("#1a0a1e" if y % 6 else "#220c28"))
        d.rectangle([96, 8, 150, 30], outline=hexc("#ff3a8a"))
        d.rectangle([98, 10, 148, 28], outline=hexc("#3ae0ff"))
        for i in range(6):
            d.rectangle([102 + i * 7, 16, 105 + i * 7, 22], fill=hexc("#ffe14a"))
        glow(im, 123, 19, 22, hexc("#ff3a8a"), 2.6)
        ground(im, 70, "#1f6b3a", "#17542d")
        d.ellipse([0, 66, 160, 74], fill=hexc("#1f6b3a"))
    def front(im):
        d = ImageDraw.Draw(im)
        for i, (x, y) in enumerate([(82, 76), (96, 80)]):
            d.rectangle([x, y, x + 9, y + 9], fill=hexc("#e03030" if i else "#f6f1e2"), outline=hexc("#1a1a1a"))
        d.point([(86, 80)], fill=hexc("#1a1a1a" if True else "#fff"))
        d.rectangle([84, 78, 87, 81], outline=hexc("#ffe14a"))  # el dado fijo en 1
        for cx, cy, c in [(20, 82, "#e03030"), (20, 79, "#e03030"), (20, 76, "#f6f1e2"), (32, 83, "#3a6ae0"), (32, 80, "#3a6ae0"), (44, 82, "#1a1a1a")]:
            d.ellipse([cx - 6, cy - 2, cx + 6, cy + 2], fill=hexc(c), outline=hexc("#0a0a0a"))
        for p in [(98, 83), (101, 86), (95, 86), (98, 89)]:
            d.point(p, fill=hexc("#ffffff"))
        d.point(hp(30, 4), fill=hexc("#ffe14a"))
    return scene("4A · El Tahúr", sky("#1a0a1e", "#0a0510"), ["#2a1230", "#3e1c48", "#5a2c6a", "#7a4290"],
                 ["#6b6b78", "#9a9aa8", "#c8c8d4", "#e8e8f0", "#ffffff"], back, front)


def patovica():
    def back(im):
        glow(im, 20, 20, 28, hexc("#c21aa8"), 2.2)
        glow(im, 142, 28, 26, hexc("#18b8d8"), 2.2)
        ground(im, 82, "#14121c")
        d = ImageDraw.Draw(im)
        for x in (24, 134):
            d.rectangle([x, 56, x + 3, 84], fill=hexc("#d4a838"))
            d.ellipse([x - 2, 52, x + 5, 58], fill=hexc("#f0cc60"))
            d.rectangle([x - 4, 84, x + 7, 86], fill=hexc("#8a6a1a"))
        d.line([(27, 62), (60, 74), (100, 76), (134, 62)], fill=hexc("#c8283a"), width=3)
    def front(im):
        d = ImageDraw.Draw(im)
        x, y = hp(33, 8)
        d.rectangle([x - 9, y, x + 13, y + 5], fill=hexc("#f6d24a"), outline=hexc("#8a6a10"))
        for i in range(5):
            d.rectangle([x - 7 + i * 4, y + 2, x - 6 + i * 4, y + 3], fill=hexc("#10131c"))
        ax, ay = hp(52, 14)
        d.line([(ax, ay), (ax + 3, ay + 6), (ax + 1, ay + 12), (ax + 5, ay + 18)], fill=hexc("#10131c"))
        d.rectangle([ax - 1, ay - 2, ax + 1, ay], fill=hexc("#c0c0c8"))
    return scene("4B · El Patovica", sky("#0a0814", "#14101e"), ["#1c1030", "#2e1a50", "#46287a", "#6a40a8"],
                 ["#0a0a0a", "#1a1a20", "#2e2e38", "#4a4a58", "#6c6c80"], back, front)


def payaso():
    def back(im):
        d = ImageDraw.Draw(im)
        for x in range(0, 160, 10):
            d.rectangle([x, 0, x + 4, 76], fill=hexc("#9e1d2c"))
            d.rectangle([x + 5, 0, x + 9, 76], fill=hexc("#7a1220"))
        ground(im, 76, "#4a2c1a", "#3a2214")
        d.polygon([(0, 0), (30, 0), (14, 60), (0, 70)], fill=hexc("#5c0f1a"))
        d.polygon([(160, 0), (130, 0), (146, 60), (160, 70)], fill=hexc("#5c0f1a"))
    def front(im):
        d = ImageDraw.Draw(im)
        x, y = hp(34, 6)
        for i, c in enumerate(["#e03030", "#f6d24a", "#3a8ae0", "#e03030", "#f6d24a", "#3a8ae0", "#e03030"]):
            d.ellipse([x - 14 + i * 5, y - 3, x - 10 + i * 5, y + 2], fill=hexc(c), outline=hexc("#10131c"))
        sx, sy = hp(36, 24)
        d.arc([sx - 8, sy - 4, sx + 8, sy + 6], 20, 160, fill=hexc("#10131c"))
        d.point([(sx - 5, sy + 3), (sx + 5, sy + 3)], fill=hexc("#e03030"))
        fx, fy = 114, 40
        d.line([(fx, fy + 4), (fx, fy + 22)], fill=hexc("#2f9a3a"))
        for ox, oy in [(-3, 0), (3, 0), (0, -3), (0, 3)]:
            d.ellipse([fx + ox - 2, fy + oy - 2, fx + ox + 2, fy + oy + 2], fill=hexc("#f6d24a"))
        d.ellipse([fx - 1, fy - 1, fx + 1, fy + 1], fill=hexc("#10131c"))
        for p in [(fx - 9, fy - 2), (fx - 12, fy - 5), (fx - 7, fy - 6), (fx - 14, fy - 1)]:
            d.point(p, fill=hexc("#7fd0ff"))
    return scene("4C · El Payaso de la Risa Final", sky("#3a0a14", "#1a0508"), ["#5c0f1a", "#7a1a2a", "#a02a3c", "#c84a5a"],
                 ["#7a7a8c", "#a8a8b8", "#d0d0dc", "#ececf4", "#ffffff"], back, front)


def computadora():
    def back(im):
        d = ImageDraw.Draw(im)
        for y in (60, 74):
            d.rectangle([0, y, 160, y + 1], fill=hexc("#2a3340"))
        for x in range(8, 160, 16):
            d.rectangle([x, 62, x + 9, 72], fill=hexc("#1a212c"), outline=hexc("#38424f"))
        rnd = random.Random(12)
        for x in range(10, 160, 16):
            for y in (64, 68):
                d.point((x + rnd.randrange(8), y), fill=hexc(rnd.choice(["#3ae0ff", "#ffb347", "#e03030", "#52e06a"])))
        ground(im, 80, "#10151d")
    def front(im):
        d = ImageDraw.Draw(im)
        ex, ey = hp(37, 22)
        glow(im, ex, ey, 14, hexc("#e0201a"), 2.0)
        d.ellipse([ex - 6, ey - 6, ex + 6, ey + 6], fill=hexc("#2a0a0a"), outline=hexc("#8d9aaa"))
        d.ellipse([ex - 4, ey - 4, ex + 4, ey + 4], fill=hexc("#d81a14"))
        d.ellipse([ex - 2, ey - 2, ex + 2, ey + 2], fill=hexc("#ff7a4a"))
        d.point((ex - 1, ey - 1), fill=hexc("#ffffff"))
        for x0, c in [(8, "#52e06a"), (13, "#e03030"), (18, "#3ae0ff")]:
            d.line([HAND_AT[0] + x0, HAND_AT[1] + 4, HAND_AT[0] + x0 - 2, HAND_AT[1] + 22], fill=hexc(c))
        d.text((92, 88), "", fill=hexc("#ffffff"))
    return scene("5C · La Computadora de Bordo", sky("#05070c", "#0c1220", True, 14), ["#0f1a3d", "#1d2f6a", "#3a56a3", "#6f8fd6"],
                 ["#1c222b", "#38424f", "#5f6b7a", "#8d9aaa", "#c4ced9"], back, front)


def horizonte():
    def back(im):
        d = ImageDraw.Draw(im)
        d.ellipse([84, 52, 150, 90], fill=hexc("#7a2b00"))
        d.ellipse([90, 56, 144, 86], fill=hexc("#c8581a"))
        d.ellipse([98, 60, 136, 82], fill=hexc("#ffb347"))
        d.ellipse([105, 63, 129, 79], fill=hexc("#000000"))
        rnd = random.Random(21)
        for _ in range(16):  # estrellas estiradas hacia el centro
            x, y = rnd.randrange(0, 90), rnd.randrange(10, 90)
            d.line([(x, y), (x + 6, y + (117 - x) * 0 + (71 - y) // 14)], fill=hexc("#ffd9a0"))
    def front(im):
        d = ImageDraw.Draw(im)
        rnd = random.Random(8)
        for fx, fy in [(21, 49), (30, 35), (13, 41), (56, 34), (40, 30)]:
            x, y = hp(fx, fy)
            for k in range(1, 7):
                d.line([(x + k * 6, y + k * 2), (x + k * 6 + 4, y + k * 2 + 1)], fill=hexc(rnd.choice(["#ff9a3a", "#ffb347", "#c8581a"])))
    return scene("6A · El Horizonte", sky("#000000", "#0a0410", True, 17), ["#12081f", "#251243", "#3d2468", "#5c3b94"],
                 ["#2a0f00", "#7a2b00", "#c8581a", "#ffb347", "#fff0c0"], back, front)


def relojero():
    def gear(d, cx, cy, r, c, dark):
        for a in range(0, 360, 45):
            x, y = cx + math.cos(math.radians(a)) * (r + 2), cy + math.sin(math.radians(a)) * (r + 2)
            d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=hexc(c))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=hexc(c), outline=hexc(dark))
        d.ellipse([cx - r // 3, cy - r // 3, cx + r // 3, cy + r // 3], fill=hexc(dark))
    def back(im):
        d = ImageDraw.Draw(im)
        gear(d, 16, 62, 12, "#a8801f", "#3d2a08")
        gear(d, 142, 70, 15, "#8a6a12", "#3d2a08")
        gear(d, 128, 30, 8, "#c9a227", "#3d2a08")
    def front(im):
        d = ImageDraw.Draw(im)
        # reloj derretido colgando de la mano
        cx, cy = 108, 36
        d.ellipse([cx - 12, cy - 9, cx + 12, cy + 9], fill=hexc("#f0e6c0"), outline=hexc("#5a3a0a"))
        d.polygon([(cx - 10, cy + 6), (cx - 6, cy + 20), (cx - 2, cy + 8)], fill=hexc("#f0e6c0"), outline=hexc("#5a3a0a"))
        d.line([(cx, cy), (cx, cy - 6)], fill=hexc("#10131c"))
        d.line([(cx, cy), (cx + 5, cy + 1)], fill=hexc("#10131c"))
        for x in range(HAND_AT[0] + 20, HAND_AT[0] + 24):  # arena
            for y in range(HAND_AT[1] + 49, 92, 2):
                d.point((x - 3, y), fill=hexc("#f0d070"))
        d.polygon([(70, 86), (86, 86), (82, 92), (74, 92)], fill=hexc("#f0d070"))
    return scene("6B · El Relojero del Instante", sky("#150a24", "#2e1a40", True, 31), ["#1c1030", "#2e1a50", "#46287a", "#6a40a8"],
                 ["#3d2a08", "#6e4e12", "#a8801f", "#d9b24a", "#f6e08c"], back, front)


def cebador2():
    """Versión con el robo: el termo del jugador flota hacia el cielo y queda suspendido."""
    def termo(d, x, y, faint=False):
        body = hexc("#aeb7c2") if not faint else hexc("#6a7080")
        d.rectangle([x, y, x + 6, y + 16], fill=body, outline=hexc("#4c5663"))
        d.rectangle([x + 1, y + 1, x + 2, y + 15], fill=hexc("#e6ecf2") if not faint else hexc("#8a90a0"))
        d.rectangle([x - 1, y - 3, x + 7, y], fill=hexc("#c0392b") if not faint else hexc("#7a3a34"), outline=hexc("#6b1a12"))
    def back(im):
        d = ImageDraw.Draw(im)
        d.ellipse([112, 56, 144, 88], fill=hexc("#ffcf5a"))
        d.rectangle([0, 82, 160, 96], fill=hexc("#3d5a2a"))
        d.rectangle([14, 78, 52, 82], fill=hexc("#8a5a2b"))  # la mesa
    def front(im):
        d = ImageDraw.Draw(im)
        rnd = random.Random(4)
        a = np.array(im)
        for _ in range(60):
            x, y = hp(rnd.randrange(8, 56), rnd.randrange(10, 48))
            if abs(int(a[y, x, 0]) - int(a[y, x, 2])) > 20:
                d.point((x, y), fill=hexc(rnd.choice(["#3f7a1a", "#6fb02a", "#1f4a0c"])))
        # secuencia del termo: sobre la mesa, a mitad de camino, flotando arriba
        termo(d, 30, 62, faint=True)
        termo(d, 38, 46, faint=True)
        termo(d, 104, 14)
        for i, (x, y) in enumerate([(33, 58), (36, 52), (39, 46), (50, 40), (64, 34), (80, 26), (96, 20)]):
            d.point((x, y), fill=hexc("#fff4c0"))
            d.point((x + 1, y + 1), fill=hexc("#ffd98a"))
        glow(im, 107, 22, 12, hexc("#ffe9a8"), 1.6)
        termo(d, 104, 14)
        for sx, sy in [(98, 12), (116, 18), (110, 34), (96, 30)]:
            d.line([(sx - 1, sy), (sx + 1, sy)], fill=hexc("#ffffff"))
            d.line([(sx, sy - 1), (sx, sy + 1)], fill=hexc("#ffffff"))
    return scene("2A · Don Cebador", sky("#f08a3c", "#ffd08a"), ["#e07a3a", "#f2a35c", "#ffcc88", "#fff0d2"],
                 ["#4a2c0c", "#7a4a1a", "#a8702a", "#cf9650", "#e8bf80"], back, front)


ALL = [("1A", kioskero), ("1B", payador), ("1C", palomas), ("2A", cebador2), ("2B", chamuyero), ("2C", referi),
       ("3A", murcielago), ("3B", conde), ("3C", lobizon), ("4A", tahur), ("4B", patovica), ("4C", payaso),
       ("5A", visitante), ("5B", farolero), ("5C", computadora), ("6A", horizonte), ("6B", relojero), ("6C", durmiente)]


def main():
    os.makedirs(OUT, exist_ok=True)
    for key, fn in ALL:
        name, im = fn()
        path = os.path.join(OUT, f"jefe-{key}.png")
        im.resize((W * SCALE, H * SCALE), Image.NEAREST).save(path)
        print(key, "->", path)


if __name__ == "__main__":
    main()
