"""Bocetos de La Semilla (24/11/2026): tres opciones para cada pieza, animadas, sobre capturas reales del nivel 7.

  A  Muerte de los guardianes (rayos blancos semitransparentes desde adentro):
       A1 grietas de luz que lo parten en pedazos · A2 implosión con onda expansiva · A3 se disuelve hacia arriba.
  B  El bar se rompe (polvo, bloques que caen del techo, grietas):
       B1 se cae el techo · B2 se quiebra como vidrio · B3 las paredes se hunden detrás de la mesa.
  C  La Semilla sobre la Matrix (la semilla chica viaja al centro y crece, después sube a su lugar):
       C1 placa dorada · C2 terminal verde · C3 alarma roja que se decodifica.

Todo se dibuja en la grilla lógica del juego (720×450, cada píxel lógico = 2×2 de pantalla) y se compone sobre las
capturas de `capture_base.gd`. Son bocetos: no se integran sin aprobación del autor.

Uso:  godot --path . --script res://tools/art/bocetos-semilla/capture_base.gd   (con GPU)
      py -3.13 tools/art/bocetos-semilla/bocetos.py
Salida: test-results/bocetos-semilla/*.webp (animados) y *-cuadros.png (cuadros clave).
"""
from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
BASE = os.path.join(ROOT, "test-results", "bocetos-semilla", "base")
OUT = os.path.join(ROOT, "test-results", "bocetos-semilla")
ART = os.path.join(ROOT, "assets", "art", "pixel-v3")
SEED = "2847193650"
H, W = 900, 1440
LH, LW = 450, 720
FRAME_MS = 90


# ---------------------------------------------------------------- utilidades

def load(name: str) -> np.ndarray:
    return np.asarray(Image.open(os.path.join(BASE, name + ".png")).convert("RGB")).astype(np.float32)


def up2(a: np.ndarray) -> np.ndarray:
    return a.repeat(2, 0).repeat(2, 1)


def hexc(s: str) -> np.ndarray:
    return np.array([int(s[i:i + 2], 16) for i in (0, 2, 4)], np.float32)


def blend(img: np.ndarray, color, alpha: np.ndarray) -> np.ndarray:
    a = alpha[..., None]
    return img * (1 - a) + np.asarray(color, np.float32) * a


def blend_rgba(img: np.ndarray, rgba: np.ndarray) -> np.ndarray:
    a = rgba[..., 3:4]
    return img * (1 - a) + rgba[..., :3] * a


def disc(h, w, cx, cy, r):
    yy, xx = np.ogrid[0:h, 0:w]
    return (xx + 0.5 - cx) ** 2 + (yy + 0.5 - cy) ** 2 <= r * r


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


def shift(img: np.ndarray, sx: int, sy: int) -> np.ndarray:
    """Corre la imagen sin dar la vuelta: los bordes se repiten."""
    h, w = img.shape[:2]
    yy = np.clip(np.arange(h) - sy, 0, h - 1)
    xx = np.clip(np.arange(w) - sx, 0, w - 1)
    return img[yy][:, xx]


def ease(t: float) -> float:
    t = min(max(t, 0.0), 1.0)
    return t * t * (3 - 2 * t)


def save_anim(frames: list[np.ndarray], name: str, keys: list[int]):
    ims = [Image.fromarray(np.clip(f, 0, 255).astype(np.uint8)) for f in frames]
    ims[0].save(os.path.join(OUT, name + ".webp"), save_all=True, append_images=ims[1:], duration=FRAME_MS,
                loop=0, quality=82, method=4)
    w, h = ims[0].size
    if w >= 1000 and h >= 600:  # pantalla completa: 2×2 a media escala
        sheet = Image.new("RGB", (w, h))
        for i, k in enumerate(keys[:4]):
            sheet.paste(ims[k].resize((w // 2, h // 2), Image.BOX), ((i % 2) * w // 2, (i // 2) * h // 2))
    else:  # recortes: uno debajo del otro
        sheet = Image.new("RGB", (w, h * len(keys)))
        for i, k in enumerate(keys):
            sheet.paste(ims[k], (0, i * h))
    sheet.save(os.path.join(OUT, name + "-cuadros.png"))
    print("listo", name, len(frames), "cuadros")


# ---------------------------------------------------------------- capturas y máscaras

bases = {k: load(k) for k in ("ojo", "figura", "dado", "triangulo")}
ui = load("interfaz")


def agree(a, b):
    return np.abs(a - b).max(-1) < 10


# Cielo sin guardián: la captura con el triángulo provisional, y debajo del triángulo el panel del cielo
# (exteriores-v3, celda 5) con los parteluces encima, igual que lo arma backdrop.gd.
clean = bases["triangulo"].copy()
ext = np.asarray(Image.open(os.path.join(ART, "exteriores-v3.png")).convert("RGB")).astype(np.float32)
mull = np.asarray(Image.open(os.path.join(ART, "parteluces-v3.png")).convert("RGBA")).astype(np.float32)
for sy in range(60, 150):
    for sx in range(600, 740):
        c = ext[222 + sy // 2, 402 + (sx - 470) // 2]
        a = mull[sy // 2, sx // 2, 3] / 255
        c = c * (1 - a) + mull[sy // 2, sx // 2, :3] * a
        if np.abs(clean[sy, sx] - c).max() > 10:
            clean[sy, sx] = c

GOD = (slice(0, 240), slice(440, 900))
gmask = {}
for k in ("ojo", "figura", "dado"):
    m = np.zeros((H, W), bool)
    m[GOD] = ~agree(bases[k], clean)[GOD]
    m = ndimage.binary_opening(m, iterations=1)
    gmask[k] = ndimage.binary_fill_holes(ndimage.binary_closing(m, iterations=2))

# Lo que queda en pie: mesa (sin el piso), termo, libreta y botones.
keep = np.zeros((H, W), bool)
mesa = np.asarray(Image.open(os.path.join(ART, "mesa-v3.png")).convert("RGBA"))[..., 3] > 0
keep[272:900] |= up2(mesa)
keep[836:] = False
termo = np.asarray(Image.open(os.path.join(ART, "termo-mesa-v3.png")).convert("RGBA"))[..., 3] > 0
keep[168:518, 1203:1347] |= up2(termo)
ui_full = np.abs(ui - np.array([255, 0, 255], np.float32)).max(-1) > 40  # libreta y botones enteros
uim = ui_full.copy()
uim[272:] = False
keep |= ui_full
keep_l = keep[::2, ::2]

CX, CY = 667, 105  # centro del guardián en pantalla


# ---------------------------------------------------------------- letra de 5×7 para la semilla

FONT5 = {
    "0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
    "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
    "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    "5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
    "6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
    "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
    "9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    "I": ["01110", "00100", "00100", "00100", "00100", "00100", "01110"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    " ": ["00000"] * 7,
}


def text_mask(text: str, scale: int = 1, gap: int = 1) -> np.ndarray:
    w = len(text) * (5 + gap) - gap
    m = np.zeros((7, w), bool)
    for i, ch in enumerate(text):
        g = np.array([[c == "1" for c in row] for row in FONT5[ch]])
        m[:, i * (5 + gap):i * (5 + gap) + 5] = g
    return m.repeat(scale, 0).repeat(scale, 1)


def paste_mask(layer: np.ndarray, mask: np.ndarray, x: int, y: int, color, alpha=1.0):
    """Pinta `mask` en un RGBA lógico, recortando bordes."""
    h, w = mask.shape
    x0, y0 = max(x, 0), max(y, 0)
    x1, y1 = min(x + w, layer.shape[1]), min(y + h, layer.shape[0])
    if x1 <= x0 or y1 <= y0:
        return
    sub = mask[y0 - y:y1 - y, x0 - x:x1 - x]
    region = layer[y0:y1, x0:x1]
    region[sub, :3] = color
    region[sub, 3] = alpha


SEED_SMALL_COLOR = hexc("cdbb8f")


def seed_small(img: np.ndarray) -> np.ndarray:
    """Semilla chica arriba a la izquierda, sobre la libreta: tenue pero legible (con sombra)."""
    layer = np.zeros((LH, LW, 4), np.float32)
    m = text_mask("SEMILLA " + SEED)
    paste_mask(layer, m, 16, 4, (20, 12, 8), 0.8)
    paste_mask(layer, m, 15, 3, SEED_SMALL_COLOR, 1.0)
    return blend_rgba(img, up2(layer))


# ---------------------------------------------------------------- rayos, grietas, polvo y bloques

def rays_alpha(h, w, cx, cy, angles, lengths, width, alpha):
    yy, xx = np.mgrid[0:h, 0:w]
    dx, dy = xx + 0.5 - cx, yy + 0.5 - cy
    d = np.hypot(dx, dy)
    ang = np.arctan2(dy, dx)
    out = np.zeros((h, w), np.float32)
    for a, L in zip(angles, lengths):
        diff = np.abs((ang - a + math.pi) % (2 * math.pi) - math.pi)
        m = (diff < width) & (d < L) & (d > 3)
        val = alpha * np.clip(1 - d / L, 0, 1) ** 0.6 * (1 - 0.5 * diff / width)
        out = np.maximum(out, np.where(m, val, 0))
    return np.round(out * 8) / 8  # pocas bandas, como pixel art


def gen_cracks(rng, starts, steps, w, h, branch=0.07, jitter=0.2, max_branches=120):
    pts = []
    pending = [(float(x), float(y), float(a), 0) for x, y, a in starts]
    count = 0
    while pending:
        x, y, a, t = pending.pop()
        for _ in range(steps):
            a += rng.normal(0, jitter)
            nx, ny = x + math.cos(a) * 2.5, y + math.sin(a) * 2.5
            for px, py in bresenham(int(round(x)), int(round(y)), int(round(nx)), int(round(ny))):
                if 0 <= px < w and 0 <= py < h:
                    pts.append((px, py, t))
            x, y, t = nx, ny, t + 1
            if not (0 <= x < w and 0 <= y < h):
                break
            if rng.random() < branch and count < max_branches:
                count += 1
                pending.append((x, y, a + rng.choice([-1, 1]) * rng.uniform(0.5, 1.1), t))
    return np.array(pts, np.int32) if pts else np.zeros((0, 3), np.int32)


def crack_layer(pts, upto, h, w, dark=(26, 13, 6), light=(255, 236, 200), light_alpha=0.55):
    layer = np.zeros((h, w, 4), np.float32)
    sel = pts[pts[:, 2] <= upto]
    if len(sel):
        ys, xs = sel[:, 1], sel[:, 0]
        ly, lx = np.clip(ys + 1, 0, h - 1), np.clip(xs + 1, 0, w - 1)
        layer[ly, lx, :3] = light
        layer[ly, lx, 3] = light_alpha
        layer[ys, xs, :3] = dark
        layer[ys, xs, 3] = 1
    return layer


DUST = [hexc("c9a27a"), hexc("a88660"), hexc("e3c9a0"), hexc("8a6a4c")]


class Dust:
    def __init__(self, rng):
        self.rng = rng
        self.p = []

    def puff(self, x, y, n=6, spread=10, size=(4, 9), up=-0.4):
        for _ in range(n):
            self.p.append({"x": x + self.rng.normal(0, spread / 2), "y": y + self.rng.normal(0, 2),
                           "r": self.rng.uniform(*size), "vx": self.rng.normal(0, 0.6),
                           "vy": up + self.rng.normal(0, 0.25), "life": self.rng.integers(10, 20), "age": 0,
                           "c": DUST[self.rng.integers(0, len(DUST))]})

    def step_draw(self, h, w):
        layer = np.zeros((h, w, 4), np.float32)
        alive = []
        for q in self.p:
            q["age"] += 1
            q["x"] += q["vx"]
            q["y"] += q["vy"]
            q["r"] += 0.35
            if q["age"] >= q["life"]:
                continue
            alive.append(q)
            a = 0.55 * (1 - q["age"] / q["life"])
            r = q["r"]
            x0, x1 = int(max(q["x"] - r - 1, 0)), int(min(q["x"] + r + 2, w))
            y0, y1 = int(max(q["y"] - r - 1, 0)), int(min(q["y"] + r + 2, h))
            if x1 <= x0 or y1 <= y0:
                continue
            m = disc(y1 - y0, x1 - x0, q["x"] - x0, q["y"] - y0, r)
            reg = layer[y0:y1, x0:x1]
            reg[m, :3] = reg[m, :3] * reg[m, 3:4] * 0.4 + q["c"] * (1 - reg[m, 3:4] * 0.4)
            reg[m, 3] = np.maximum(reg[m, 3], a)
        self.p = alive
        layer[..., 3] = np.round(layer[..., 3] * 6) / 6
        return layer


WOOD = [hexc("3a1e0e"), hexc("5a3218"), hexc("7a4520"), hexc("9a5a2a"), hexc("b87538")]
PLASTER = [hexc("4a4038"), hexc("6e6052"), hexc("948270"), hexc("b8a48c"), hexc("d8c4a8")]


def make_block(rng, size):
    w, h = size
    pts = [(rng.uniform(0, w), rng.uniform(0, h)) for _ in range(7)] + [(0, h * 0.3), (w, h * 0.6)]
    img = Image.new("L", (w, h), 0)
    from scipy.spatial import ConvexHull
    hull = ConvexHull(np.array(pts))
    ImageDraw.Draw(img).polygon([tuple(np.array(pts)[i]) for i in hull.vertices], fill=1)
    m = np.asarray(img) > 0
    pal = WOOD if rng.random() < 0.6 else PLASTER
    rgb = np.zeros((h, w, 3), np.float32)
    yy, xx = np.mgrid[0:h, 0:w]
    shade = ((xx + yy) / (w + h) * 3).astype(int)
    for i in range(4):
        rgb[shade == i] = pal[min(4 - i, 4)]
    if pal is WOOD:  # vetas
        rgb[(yy % 4 == 0)] = pal[1]
    edge = m & ~ndimage.binary_erosion(m)
    rgb[edge] = pal[0]
    return rgb, m


def paste_rgb(layer, rgb, m, x, y):
    h, w = m.shape
    x, y = int(round(x)), int(round(y))
    x0, y0, x1, y1 = max(x, 0), max(y, 0), min(x + w, layer.shape[1]), min(y + h, layer.shape[0])
    if x1 <= x0 or y1 <= y0:
        return
    sub = m[y0 - y:y1 - y, x0 - x:x1 - x]
    reg = layer[y0:y1, x0:x1]
    reg[sub, :3] = rgb[y0 - y:y1 - y, x0 - x:x1 - x][sub]
    reg[sub, 3] = 1


# ---------------------------------------------------------------- Matrix

def glyph_bank():
    sets = [
        ("0123456789", os.path.join(os.environ["WINDIR"], "Fonts", "lucon.ttf"), 0.36),
        ("ABCDEFGHIJKLMNOPQRSTUVWXYZ", os.path.join(os.environ["WINDIR"], "Fonts", "lucon.ttf"), 0.36),
        ("アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン",
         os.path.join(os.environ["WINDIR"], "Fonts", "msgothic.ttc"), 0.17),
        ("ԱԲԳԴԵԶԷԸԹԺԻԼԽԾԿՀՁՂՃՄՅՆՇՈՉՊՋՌՍՎՏՐՑՒՓՔՕՖ", os.path.join(os.environ["WINDIR"], "Fonts", "sylfaen.ttf"), 0.11),
    ]
    glyphs, weights = [], []
    for chars, path, weight in sets:
        font = ImageFont.truetype(path, 10)
        for ch in chars:
            img = Image.new("L", (8, 10), 0)
            d = ImageDraw.Draw(img)
            d.fontmode = "1"
            bbox = d.textbbox((0, 0), ch, font=font)
            d.text(((8 - (bbox[2] - bbox[0])) // 2 - bbox[0], (10 - (bbox[3] - bbox[1])) // 2 - bbox[1]), ch, font=font, fill=255)
            m = np.asarray(img) > 127
            if m.sum() > 2:
                glyphs.append(m)
                weights.append(weight / len(chars))
    w = np.array(weights)
    return glyphs, w / w.sum()


GLYPHS, GLYPH_P = glyph_bank()
HEAD = hexc("e4ffe6")
GREENS = [hexc("0a3412"), hexc("0f5a1c"), hexc("16862a"), hexc("2ebc44"), hexc("6cf47e")]


class Matrix:
    CW, CH = 8, 10

    def __init__(self, seed):
        self.rng = np.random.default_rng(seed)
        self.cols = LW // self.CW
        self.rows = LH // self.CH + 1
        self.streams = []
        for c in range(self.cols):
            for _ in range(1 if self.rng.random() < 0.65 else 2):
                self.streams.append({
                    "c": c, "dir": -1 if self.rng.random() < 0.4 else 1,
                    "speed": self.rng.uniform(0.25, 0.9), "len": int(self.rng.integers(6, 22)),
                    "pos": self.rng.uniform(0, self.rows + 22)})
        self.table = self.rng.choice(len(GLYPHS), size=(self.cols, self.rows, 64), p=GLYPH_P)

    def render(self, frame, fade=1.0):
        layer = np.zeros((LH, LW, 4), np.float32)
        period = self.rows + 24
        for s in self.streams:
            head = (s["pos"] + s["speed"] * frame) % period
            head = head if s["dir"] > 0 else period - head
            hr = int(head) - 1 if s["dir"] > 0 else int(head) - 12
            for k in range(s["len"]):
                row = hr - s["dir"] * k
                if not (0 <= row < self.rows):
                    continue
                t = k / s["len"]
                color = HEAD if k == 0 else GREENS[max(0, 4 - int(t * 5))]
                g = GLYPHS[self.table[s["c"], row, (frame // (3 + s["c"] % 4) + row) % 64]]
                a = fade * (1.0 if k < 2 else max(0.25, 1 - t))
                paste_mask(layer, g, s["c"] * self.CW, row * self.CH, color, a)
        return layer


# ---------------------------------------------------------------- A: muerte de los guardianes

AX0, AY0, AW, AH = 470, 0, 400, 230  # recorte en pantalla
ACX, ACY = (CX - AX0) / 2, (CY - AY0) / 2
NA = 30


def crop_l(a):
    return a[AY0:AY0 + AH:2, AX0:AX0 + AW:2]


def a_frames(kind: str, guardian: str, seed: int):
    rng = np.random.default_rng(seed)
    lh, lw = AH // 2, AW // 2
    sky = crop_l(clean).copy()
    base = crop_l(bases[guardian]).copy()
    gm = crop_l(gmask[guardian].astype(np.uint8)).astype(bool)
    ys, xs = np.nonzero(gm)
    gy0, gy1 = ys.min(), ys.max()
    sky_cracks = gen_cracks(rng, [(ACX, ACY, k * 1.05 + rng.uniform(0, 0.5)) for k in range(6)], 34, lw, lh, branch=0.1)
    frames = []
    # piezas para A1
    seeds = np.stack([xs, ys], 1)[rng.choice(len(xs), 28, replace=False)]
    lab = np.full(gm.shape, -1)
    dist = np.full(gm.shape, 1e9)
    for i, (sx, sy) in enumerate(seeds):
        d = (np.arange(lw)[None, :] - sx) ** 2 + (np.arange(lh)[:, None] - sy) ** 2
        better = d < dist
        lab[better] = i
        dist[better] = d[better]
    lab[~gm] = -1
    vel = []
    for i, (sx, sy) in enumerate(seeds):
        ang = math.atan2(sy - ACY, sx - ACX)
        sp = rng.uniform(1.2, 2.6)
        vel.append([math.cos(ang) * sp, math.sin(ang) * sp - 1.4])
    inner = gen_cracks(rng, [(ACX, ACY, k * 0.9) for k in range(7)], 22, lw, lh, branch=0.12)
    parts = []
    base_angles = rng.uniform(0, 6.28, 24)
    base_len = rng.uniform(0.7, 1.0, 24)
    for f in range(NA):
        img = sky.copy()
        dx = 0
        if kind == "A1":
            shake = 1 if f < 16 else 0
            dx = int(rng.integers(-shake, shake + 1))
            n = int(6 + min(f, 14) * 0.6)
            length = 40 + min(f, 15) * 5
            alpha = 0.3 + min(f, 15) / 15 * 0.25
            if f > 16:
                alpha *= max(0, 1 - (f - 16) / 9)
            if f <= 16:
                g = np.roll(base, dx, 1)
                m = np.roll(gm, dx, 1)
                img[m] = g[m] * (1 - f / 40) + 255 * f / 40
                cl = crack_layer(inner, (f - 3) * 3, lh, lw, dark=(255, 255, 255), light=(255, 250, 220), light_alpha=0.6)
                cl[~m] = 0
                img = blend_rgba(img, cl)
                if f == 16:
                    img[m] = 255
            else:
                t = f - 16
                fade = max(0, 1 - max(0, t - 6) / 7)
                for i in range(len(seeds)):
                    pm = lab == i
                    if not pm.any():
                        continue
                    ox = int(round(vel[i][0] * t))
                    oy = int(round(vel[i][1] * t + 0.18 * t * t))
                    sh = np.roll(np.roll(pm, oy, 0), ox, 1)
                    src = np.roll(np.roll(base, oy, 0), ox, 1)
                    keepm = sh & (rng.random(sh.shape) < fade)
                    img[keepm] = src[keepm] * 0.6 + 255 * 0.4
            if f >= 18:
                img = blend_rgba(img, crack_layer(sky_cracks, (f - 18) * 6, lh, lw))
            ra = rays_alpha(lh, lw, ACX, ACY, base_angles[:n] + f * 0.03, base_len[:n] * length, 0.07, alpha)
            img = blend(img, (255, 255, 255), ra)
        elif kind == "A2":
            if f < 18:
                amp = int(f / 6)
                dx = int(rng.integers(-amp, amp + 1))
                s = 1.0 if f < 10 else max(0.04, 1 - (f - 9) / 8)
                whiten = min(0.6, f / 15)
                ph, pw = gm.shape
                nh, nw = max(1, int(ph * s)), max(1, int(pw * s))
                yy = (np.arange(nh) / s).astype(int).clip(0, ph - 1)
                xx = (np.arange(nw) / s).astype(int).clip(0, pw - 1)
                sm = gm[yy][:, xx]
                sg = base[yy][:, xx]
                oy, ox = int(ACY - ACY * s), int(ACX - ACX * s) + dx
                reg = img[oy:oy + nh, ox:ox + nw]
                mm = sm[:reg.shape[0], :reg.shape[1]]
                reg[mm] = sg[:reg.shape[0], :reg.shape[1]][mm] * (1 - whiten) + 255 * whiten
                n = 10
                length = (50 + f * 4) if f < 10 else (90 - (f - 10) * 6)
                ra = rays_alpha(lh, lw, ACX, ACY, base_angles[:n] + f * 0.06, base_len[:n] * length, 0.08, 0.3 + min(f, 17) / 17 * 0.3)
                img = blend(img, (255, 255, 255), ra)
            elif f == 18:
                img = blend(img, (255, 255, 255), np.full((lh, lw), 0.45, np.float32))
                img[disc(lh, lw, ACX, ACY, 12)] = 255
            else:
                t = f - 18
                r = 6 + t * 11
                ring = disc(lh, lw, ACX, ACY, r + 2) & ~disc(lh, lw, ACX, ACY, r - 1)
                img = blend(img, (255, 255, 255), ring * max(0, 0.75 - t * 0.07))
                ra = rays_alpha(lh, lw, ACX, ACY, base_angles + t * 0.02, base_len * (60 + t * 14), 0.05, max(0, 0.55 - t * 0.05))
                img = blend(img, (255, 255, 255), ra)
                k = max(0, 7 - t)
                cx, cy = int(ACX), int(ACY)
                img[cy, max(cx - k, 0):cx + k + 1] = 255
                img[max(cy - k, 0):cy + k + 1, cx] = 255
                img = blend_rgba(img, crack_layer(sky_cracks, t * 6, lh, lw))
        else:  # A3
            prog = (f - 6) / 16
            yy = np.arange(lh)[:, None] * np.ones((1, lw))
            bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16
            thr = (gy1 - yy) / max(gy1 - gy0, 1) * 0.75 + np.tile(bayer, (lh // 4 + 1, lw // 4 + 1))[:lh, :lw] * 0.25
            alive = gm & (thr >= prog)
            newly = gm & (thr < prog) & (thr >= (f - 7) / 16)
            near = alive & (thr < prog + 0.12)
            img[alive] = base[alive]
            img[near] = base[near] * 0.35 + 255 * 0.65
            ny, nx = np.nonzero(newly)
            for j in rng.choice(len(ny), min(len(ny), 60), replace=False) if len(ny) else []:
                parts.append([float(nx[j]), float(ny[j]), rng.uniform(1, 2.5), 0])
            still = []
            for p in parts:
                p[1] -= p[2]
                p[3] += 1
                if p[3] < 9 and 0 <= int(p[1]) < lh:
                    still.append(p)
                    col = (255, 255, 255) if p[3] < 4 else (255, 230, 160)
                    img[int(p[1]), int(p[0])] = col
            parts = still
            col_a = 0.25 if f < 24 else max(0, 0.25 - (f - 23) * 0.05)
            column = np.zeros((lh, lw), np.float32)
            column[:int(gy1), max(int(ACX) - 22, 0):int(ACX) + 22] = col_a
            img = blend(img, (255, 255, 255), column)
            ups = -math.pi / 2 + np.linspace(-0.55, 0.55, 7) + np.sin(f * 0.4 + np.arange(7)) * 0.04
            ra = rays_alpha(lh, lw, ACX, gy1 - 8, ups, np.full(7, 30 + min(f, 10) * 9), 0.05, 0.5 if f < 24 else max(0, 0.5 - (f - 23) * 0.09))
            img = blend(img, (255, 255, 255), ra)
            if f >= 20:
                img = blend_rgba(img, crack_layer(sky_cracks, (f - 20) * 6, lh, lw))
        frames.append(up2(img))
    return frames


def build_a():
    for kind, seed in (("A1", 11), ("A2", 22), ("A3", 33)):
        per = [a_frames(kind, g, seed + i) for i, g in enumerate(("ojo", "figura", "dado"))]
        frames = [np.concatenate([per[0][f], per[1][f], per[2][f]], 1) for f in range(NA)]
        save_anim(frames, kind, [3, 12, 18, 24])


# ---------------------------------------------------------------- B: se rompe el bar

NB = 46


def b_frames(kind: str, seed: int):
    rng = np.random.default_rng(seed)
    dust = Dust(rng)
    matrix = Matrix(seed + 100)
    base = bases["figura"]
    gm = gmask["figura"]
    bg = base.copy()
    bg[gm] = clean[gm]
    # sin libreta ni botones en el fondo (si no, se mueven con las paredes)
    near = ndimage.distance_transform_edt(uim, return_distances=False, return_indices=True)
    bg = bg[near[0], near[1]]
    bg_l = bg[::2, ::2]
    gl = base[::2, ::2]
    gml = gm[::2, ::2]
    back_l = ~keep_l
    cracks = gen_cracks(rng, [(rng.uniform(0, LW), 0, math.pi / 2 + rng.normal(0, 0.3)) for _ in range(14)], 60, LW, LH, branch=0.05)
    blocks = []
    frames = []
    angles = rng.uniform(0, 6.28, 16)
    lens = rng.uniform(0.7, 1.0, 16)
    # B1: frente de derrumbe con borde irregular
    noise = ndimage.gaussian_filter1d(rng.normal(0, 1, LW), 6) * 10
    # B2: esquirlas de Voronoi alrededor del guardián
    pts = np.concatenate([rng.uniform([0, 0], [LW, 140], (46, 2)), np.array([[CX / 2, CY / 2]])])
    yy, xx = np.mgrid[0:LH, 0:LW]
    if kind == "B2":
        d = np.stack([(xx - px) ** 2 + (yy - py) ** 2 for px, py in pts])
        lab = d.argmin(0)
        sorted_d = np.sort(d, 0)
        border = (np.sqrt(sorted_d[1]) - np.sqrt(sorted_d[0])) < 1.2
        order = np.argsort(np.hypot(pts[:, 0] - CX / 2, pts[:, 1] - CY / 2)) if True else None
        start = {int(i): 10 + k * 0.55 + rng.uniform(0, 3) for k, i in enumerate(order)}
        dist_c = np.hypot(xx - CX / 2, yy - CY / 2)
    if kind == "B3":
        edges = [0]
        while edges[-1] < LW:
            edges.append(edges[-1] + int(rng.integers(36, 70)))
        slab_noise = ndimage.gaussian_filter1d(rng.normal(0, 1, LH), 3) * 5
        lab = np.zeros((LH, LW), int)
        for i in range(len(edges) - 1):
            left = edges[i] + slab_noise.astype(int)[:, None] * (i > 0)
            lab[xx >= left] = i
        slab_start = {i: 8 + rng.uniform(0, 12) for i in range(len(edges))}
        border = np.zeros((LH, LW), bool)
        border[:, 1:] |= lab[:, 1:] != lab[:, :-1]
    for f in range(NB):
        img = bg_l.copy()
        black = np.zeros((LH, LW), bool)
        ray_a = min(0.6, 0.3 + f * 0.012)
        gfade = 1.0
        if kind == "B1":
            if f >= 5:
                front = (f - 5) ** 1.35 * 2.6 + noise
                black = yy < front[None, :]
            cl = crack_layer(cracks, f * 4, LH, LW)
            img = blend_rgba(img, cl)
            if 4 <= f < 34 and rng.random() < 0.85:
                for _ in range(int(rng.integers(1, 4))):
                    size = (int(rng.integers(8, 22)), int(rng.integers(6, 16)))
                    rgb, m = make_block(rng, size)
                    blocks.append({"x": rng.uniform(-10, LW), "y": -20.0, "vy": rng.uniform(1, 3), "rgb": rgb, "m": m})
            gfade = 1 - ease((f - 22) / 10)
        elif kind == "B2":
            reach = f * 14
            cl = np.zeros((LH, LW, 4), np.float32)
            cm = border & (dist_c < reach) & back_l
            cl[cm, :3] = (22, 12, 6)
            cl[cm, 3] = 1
            glow = cm & (dist_c < reach * 0.6)
            cl[glow, :3] = (255, 255, 255)
            cl[glow, 3] = 0.85
            img = blend_rgba(img, cl)
            moved = np.zeros((LH, LW, 3), np.float32)
            movedm = np.zeros((LH, LW), bool)
            black = np.zeros((LH, LW), bool)
            for i in range(len(pts)):
                s0 = start[i]
                if f <= s0:
                    continue
                t = f - s0
                pm = (lab == i) & back_l
                black |= pm
                dy = int(round(0.5 * 0.9 * t * t))
                dxs = int(round((pts[i][0] - CX / 2) * 0.012 * t))
                if dy > LH:
                    continue
                sh = np.roll(np.roll(pm, dy, 0), dxs, 1)
                sh[:dy] = False
                src = np.roll(np.roll(img, dy, 0), dxs, 1)
                edge = sh & ~ndimage.binary_erosion(sh)
                movedm |= sh
                moved[sh] = src[sh] * 0.85
                moved[edge] = (22, 12, 6)
                if abs(t - 1) < 0.6:
                    dust.puff(pts[i][0], pts[i][1], n=4, spread=14, size=(3, 7))
            gfade = 1 - ease((f - 12) / 8)
        else:  # B3
            cl = crack_layer(cracks, f * 3, LH, LW)
            img = blend_rgba(img, cl)
            src = img.copy()
            img[:] = 0
            black = np.ones((LH, LW), bool)
            for i in range(len(edges) - 1):
                s0 = slab_start[i]
                t = max(0, f - s0)
                dy = int(round(0.35 * t * t))
                pm = lab == i
                sh = np.roll(pm, dy, 0)
                sh[:dy] = False
                moved_src = np.roll(src, dy, 0)
                img[sh] = moved_src[sh]
                black &= ~sh
                if t > 0:
                    edge = np.roll(border & pm, dy, 0)
                    edge[:dy] = False
                    img[edge] = (22, 12, 6)
                if 0 < t and rng.random() < 0.6:
                    x0, x1 = edges[i], min(edges[i + 1], LW)
                    dust.puff(rng.uniform(x0, x1), 134, n=3, spread=30, size=(5, 11), up=-0.7)
            if 4 <= f < 30 and rng.random() < 0.4:
                rgb, m = make_block(rng, (int(rng.integers(8, 16)), int(rng.integers(6, 12))))
                blocks.append({"x": rng.uniform(200, 700), "y": -16.0, "vy": 2.0, "rgb": rgb, "m": m})
            gfade = 1 - ease((f - 14) / 10)
        img[black] = 0
        if kind == "B2":
            img[movedm] = moved[movedm]
        # matrix al final, solo en el negro
        if f >= 34:
            ml = matrix.render(f, fade=ease((f - 34) / 10))
            ml[~black] = 0
            img = blend_rgba(img, ml)
        # guardián con rayos, desvaneciéndose
        if gfade > 0:
            gm_draw = gml & (rng.random(gml.shape) < gfade)
            img[gm_draw] = gl[gm_draw] * (1 - (1 - gfade) * 0.7) + 255 * (1 - gfade) * 0.7
            ra = rays_alpha(LH, LW, CX / 2, CY / 2, angles + f * 0.03, lens * (90 + f * 3), 0.06, ray_a * gfade)
            ra[keep_l] = 0
            img = blend(img, (255, 255, 255), ra)
        # bloques que caen (detrás de la mesa)
        blk = np.zeros((LH, LW, 4), np.float32)
        still = []
        for b in blocks:
            b["vy"] += 0.55
            b["y"] += b["vy"]
            if b["y"] + b["m"].shape[0] >= 138:
                dust.puff(b["x"] + b["m"].shape[1] / 2, 136, n=5, spread=b["m"].shape[1], size=(4, 9))
                continue
            still.append(b)
            paste_rgb(blk, b["rgb"], b["m"], b["x"], b["y"])
        blocks = still
        blk[keep_l] = 0
        img = blend_rgba(img, blk)
        full = up2(img)
        full[keep] = base[keep]
        full[836:][~keep[836:]] = np.where(f >= 26, 0, full[836:][~keep[836:]])
        dl = dust.step_draw(LH, LW)
        full = blend_rgba(full, up2(dl))
        if f < 30:
            amp = 3 if f < 20 else 1
            sx, sy = int(rng.integers(-amp, amp + 1)) * 2, int(rng.integers(-amp, amp + 1)) * 2
            full = shift(full, sx, sy)
        full[ui_full] = base[ui_full]  # la libreta y el menú no tiemblan ni se cubren de polvo
        full = seed_small(full)
        frames.append(full)
    return frames


def build_b():
    for kind, seed in (("B1", 101), ("B2", 202), ("B3", 303)):
        frames = b_frames(kind, seed)
        save_anim(frames, kind, [4, 16, 26, 44])


# ---------------------------------------------------------------- C: La Semilla sobre la Matrix

NC = 52
DIGIT_SCALE = 4


def c_frames(kind: str, seed: int):
    rng = np.random.default_rng(seed)
    matrix = Matrix(seed)
    base = bases["figura"]
    frames = []
    big = text_mask(SEED, DIGIT_SCALE, gap=1)
    bh, bw = big.shape
    pad = 10
    for f in range(NC):
        ml = matrix.render(f + 30)
        img = np.zeros((LH, LW, 3), np.float32)
        img = blend_rgba(img, ml)
        full = up2(img)
        full[keep] = base[keep]
        # viaje: arriba a la izquierda → centro (crece) → sube a su lugar
        t1 = ease(f / 14)
        t2 = ease((f - 26) / 10)
        sx, sy = 15 + 61, 3 + 3  # centro del número chico
        cx = sx + (LW / 2 - sx) * t1
        cy = sy + (LH / 2 - sy) * t1 + (62 - LH / 2) * t2
        scale = max(1, int(round(1 + (DIGIT_SCALE - 1) * t1)))
        m = text_mask(SEED, scale, gap=1)
        mh, mw = m.shape
        x, y = int(cx - mw / 2), int(cy - mh / 2)
        p = max(2, int(pad * scale / DIGIT_SCALE))
        layer = np.zeros((LH, LW, 4), np.float32)
        bx0, by0, bx1, by1 = x - p, y - p, x + mw + p, y + mh + p
        if kind == "C1":
            if f > 2:
                layer[by0 - 3:by1 + 3, bx0 - 3:bx1 + 3] = (*hexc("e8b030"), 1)
                layer[by0 - 1:by1 + 1, bx0 - 1:bx1 + 1] = (*hexc("8a5a14"), 1)
                layer[by0:by1, bx0:bx1] = (*hexc("0d1430"), 1)
                for ox, oy in ((bx0 - 3, by0 - 3), (bx1 - 2, by0 - 3), (bx0 - 3, by1 - 2), (bx1 - 2, by1 - 2)):
                    layer[oy - 1:oy + 6, ox - 1:ox + 6] = (*hexc("ffe08a"), 1)
                if scale == DIGIT_SCALE:
                    lab_m = text_mask("LA SEMILLA", 1)
                    paste_mask(layer, lab_m, int(cx - lab_m.shape[1] / 2), by0 - 14, hexc("e8b030"))
            paste_mask(layer, m, x + max(1, scale // 2), y + max(1, scale // 2), hexc("6a3c0a"))
            shine = hexc("fff1c0") if (f // 3) % 9 == 0 and f > 20 else hexc("ffe08a")
            paste_mask(layer, m, x, y, shine)
        elif kind in ("C2", "C4"):
            if kind == "C4":
                # C4 = terminal de C2 + decodificación de C3: los números giran hasta fijarse mientras viaja y,
                # ya fijos, de vez en cuando uno se «bugea» un cuadro.
                digits = "".join(SEED[i] if f >= 12 + i * 1.6 else str(int(rng.integers(0, 10))) for i in range(len(SEED)))
                if f >= 30 and f % 7 == 3:
                    j = int(rng.integers(0, len(SEED)))
                    digits = digits[:j] + str(int(rng.integers(0, 10))) + digits[j + 1:]
                m = text_mask(digits, scale, gap=1)
            if f > 2:
                layer[by0:by1, bx0:bx1] = (0, 0, 0, 0.88)
                g = hexc("5cff6a")
                layer[by0, bx0:bx1] = (*g, 1)
                layer[by1 - 1, bx0:bx1] = (*g, 1)
                layer[by0:by1, bx0] = (*g, 1)
                layer[by0:by1, bx1 - 1] = (*g, 1)
                k = max(3, 8 * scale // DIGIT_SCALE)
                for ox, oy, sx_, sy_ in ((bx0 - 2, by0 - 2, 1, 1), (bx1 + 1, by0 - 2, -1, 1), (bx0 - 2, by1 + 1, 1, -1), (bx1 + 1, by1 + 1, -1, -1)):
                    for i in range(k):
                        for th in range(2):
                            layer[oy + sy_ * th, ox + sx_ * i] = (*g, 1)
                            layer[oy + sy_ * i, ox + sx_ * th] = (*g, 1)
            glow = ndimage.binary_dilation(m, iterations=max(1, scale // 2))
            paste_mask(layer, glow, x, y, hexc("1e9a32"), 0.55)
            paste_mask(layer, m, x, y, hexc("dcffe0"))
            if f > 14 and (f // 4) % 2 == 0:
                cur = np.ones((7 * scale, 4 * scale), bool)
                paste_mask(layer, cur, x + mw + 2 * scale, y, hexc("5cff6a"))
            if f in (31, 32, 41, 47):
                region = layer[by0 - 3:by1 + 3, bx0 - 6:bx1 + 6]
                shift = int(rng.integers(3, 7))
                red = np.roll(region, shift, 1).copy()
                cyan = np.roll(region, -shift, 1).copy()
                red[..., :3] = red[..., :3] * [1, 0.15, 0.2]
                cyan[..., :3] = cyan[..., :3] * [0.1, 1, 1]
                red[..., 3] *= 0.6
                cyan[..., 3] *= 0.6
                region2 = blend_rgba(region[..., :3], cyan)
                region2 = blend_rgba(region2, red)
                region[..., :3] = region2
                band = slice(int(rng.integers(0, max(1, region.shape[0] - 6))), None)
                region[band] = np.roll(region[band], int(rng.integers(-8, 9)), 1)
        else:  # C3
            if f > 2:
                pulse = 0.5 + 0.5 * math.sin(f * 0.45)
                halo = np.zeros((LH, LW), bool)
                halo[by0 - 6:by1 + 6, bx0 - 6:bx1 + 6] = True
                layer[halo] = (*hexc("ff3048"), 0.12 + 0.12 * pulse)
                layer[by0 - 3:by1 + 3, bx0 - 3:bx1 + 3] = (*hexc("ff3048"), 1)
                layer[by0 - 2:by1 + 2, bx0 - 2:bx1 + 2] = (*hexc("ff8a96"), 1)
                layer[by0 - 1:by1 + 1, bx0 - 1:bx1 + 1] = (*hexc("6e0a18"), 1)
                layer[by0:by1, bx0:bx1] = (*hexc("1e0408"), 1)
            # decodificación: cada dígito gira hasta fijarse
            digits = "".join(SEED[i] if f >= 12 + i * 1.6 else str(int(rng.integers(0, 10))) for i in range(len(SEED)))
            dm = text_mask(digits, scale, gap=1)
            glow = ndimage.binary_dilation(dm, iterations=max(1, scale // 2))
            paste_mask(layer, glow, x, y, hexc("ff3048"), 0.35 + 0.2 * math.sin(f * 0.45))
            paste_mask(layer, dm, x, y, hexc("ffd0d6") if f < 12 + 10 * 1.6 else hexc("ff5a6e"))
        full = blend_rgba(full, up2(layer))
        frames.append(full)
    return frames


def build_c(kinds=()):
    for kind, seed in (("C1", 7), ("C2", 8), ("C3", 9), ("C4", 10)):
        if kinds and kind not in kinds:
            continue
        frames = c_frames(kind, seed)
        save_anim(frames, kind, [6, 20, 34, 50])


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    import sys
    which = sys.argv[1:] or ["A", "B", "C"]
    # captura de referencia con la semilla chica
    Image.fromarray(np.clip(seed_small(bases["figura"].copy()), 0, 255).astype(np.uint8)).save(os.path.join(OUT, "semilla-chica.png"))
    if "A" in which:
        build_a()
    if "B" in which:
        build_b()
    if "C" in which:
        build_c()
