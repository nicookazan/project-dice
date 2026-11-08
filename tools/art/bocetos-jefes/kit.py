"""Herramientas comunes de los bocetos de manos de jefe (07/11/2026).

Parte de la mano real del juego (mano-v3.png, cuadro 0) y de las poses ya aprobadas (make_manos_poses.py):
abierta, puño, tijera; agrega índice extendido. Escenas a escala del panel de la ventana (189×110 px lógicos),
con la nube y la mano en su lugar del juego.
"""
from __future__ import annotations

import importlib.util
import math
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as nd

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
ART = os.path.join(ROOT, "assets", "art", "pixel-v3")


def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


poses = _load("poses", os.path.join(ROOT, "tools", "art", "make_manos_poses.py"))
jm = _load("jm", os.path.join(ROOT, "tools", "art", "make_jefes_manos.py"))

HW, HH = 61, 53
OUTLINE = (28, 20, 36, 255)
BASE = Image.open(os.path.join(ART, "mano-v3.png")).convert("RGBA")
EXT = Image.open(os.path.join(ART, "exteriores-v3.png")).convert("RGBA")
CLOUD = Image.open(os.path.join(ART, "nube-v3.png")).convert("RGBA")
PANELS = {"dia": 0, "tarde": 1, "noche": 2, "espacio": 3, "agujero_negro": 4, "cielo": 5}
SW, SH = 189, 110          # ventana grande, en px lógicos
HAND_AT = (45, 17)         # dónde cae la mano (624, 34 en pantalla)
CLOUD_AT = (9, 0)


def hexc(s):
    return jm.hexc(s)


def base_frame(i=0):
    return BASE.crop((i * HW, 0, i * HW + HW, HH))


def recolor(img, ramp):
    return jm.recolor_sheet(img, ramp)


# ------------------------------------------------------------------ poses
def pose(name, ramp=None, frame=0):
    cell = base_frame(frame)
    if ramp: cell = recolor(cell, ramp)
    if name == "abierta": return cell
    if name == "puño": return poses.fist(cell)
    if name == "tijera": return poses.pose_base(cell, "tijera")
    if name == "indice":
        # puño con un dedo largo estirado al lado del pulgar: el dedo largo del dibujo (columnas 17–27) corrido 9 px
        f = np.array(poses.fist(cell))
        a = np.array(cell)
        for y in range(24, HH):
            for x in range(17, 28):
                if a[y, x, 3] > 0 and x + 9 < HW: f[y, x + 9] = a[y, x]
        return Image.fromarray(f)
    if name == "indice_lado":
        # puño con el dedo largo del dibujo girado hacia la derecha (rotsprite), como una percha
        f = poses.fist(cell)
        a = np.array(cell)
        strip = np.zeros((34, 13, 4), np.uint8)
        strip[:, :] = 0
        strip[0:27, 1:12] = a[22:49, 17:28]
        st = rotsprite(Image.fromarray(strip), 72)
        out = grow(f, HW + 14, HH)
        out.alpha_composite(st, (26, 12))
        out.alpha_composite(grow(f, HW + 14, HH).crop((0, 0, 40, HH)), (0, 0))
        return out
    raise KeyError(name)


def rotsprite(img, deg, k=8):
    big = img.resize((img.width * k, img.height * k), Image.NEAREST).rotate(deg, resample=Image.NEAREST, expand=True)
    return Image.fromarray(np.ascontiguousarray(np.array(big)[k // 2::k, k // 2::k]), "RGBA")


def mask_of(img):
    return np.array(img)[..., 3] > 0


def shade_overlay(img, area, color, alpha=1.0):
    """Pinta `color` sobre los píxeles de `area` conservando la luz: oscurece/aclara según la luminosidad original."""
    a = np.array(img).astype(float)
    c = np.array(hexc(color)[:3], float)
    lum = (0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]) / 255.0
    k = (0.45 + 0.85 * lum)[..., None]
    new = np.clip(c * k, 0, 255)
    m = area & (a[..., 3] > 0)
    a[m, :3] = a[m, :3] * (1 - alpha) + new[m] * alpha
    return Image.fromarray(a.astype(np.uint8))


def outline(img, color=OUTLINE):
    a = np.array(img)
    solid = a[..., 3] > 0
    edge = nd.binary_dilation(solid, structure=[[0, 1, 0], [1, 1, 1], [0, 1, 0]]) & ~solid
    a[edge] = color
    return Image.fromarray(a)


def shift(img, dx, dy, size=None):
    size = size or img.size
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.alpha_composite(img, (0, 0)) if False else out.paste(img, (dx, dy), img)
    return out


# ------------------------------------------------------------------ dibujo de objetos (con contorno automático)
class Layer:
    def __init__(self, w=SW, h=SH):
        self.im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def rect(self, x0, y0, x1, y1, c): self.d.rectangle([x0, y0, x1, y1], fill=hexc(c))
    def px(self, pts, c): self.d.point([(int(x), int(y)) for x, y in pts], fill=hexc(c))
    def ellipse(self, x0, y0, x1, y1, c): self.d.ellipse([x0, y0, x1, y1], fill=hexc(c))
    def poly(self, pts, c): self.d.polygon(pts, fill=hexc(c))
    def line(self, pts, c, w=1): self.d.line(pts, fill=hexc(c), width=w)

    def done(self, line=True):
        return outline(self.im) if line else self.im


# ------------------------------------------------------------------ escena
def backdrop(env):
    if env == "cierre":
        bg = Image.new("RGBA", (SW, SH), hexc("#261b19"))
        d = ImageDraw.Draw(bg)
        for y in range(0, SH, 12):
            d.rectangle([0, y, SW, y + 10], fill=hexc("#654936"))
            d.line([(0, y + 10), (SW, y + 10)], fill=hexc("#3e2c22"))
            for x in range(7 + (y * 5) % 40, SW, 46): d.point([(x, y + 3), (x, y + 7)], fill=hexc("#2a1d18"))
        return bg
    i = PANELS[env]
    cw, ch = EXT.width // 2, EXT.height // 3
    ox, oy = (i % 2) * cw, (i // 2) * ch
    return EXT.crop((ox + 32, oy, ox + 32 + SW, oy + SH))


def scene(env, layers):
    """layers: lista de (imagen, (x, y)) en coordenadas de la ventana; la nube va arriba de todo lo que esté antes de 'NUBE'."""
    out = backdrop(env).copy()
    for item in layers:
        if item == "NUBE":
            out.alpha_composite(CLOUD, CLOUD_AT)
            continue
        im, (x, y) = item
        out.paste(im, (x, y), im) if x < 0 or y < 0 else out.alpha_composite(im, (x, y))
    return out


def save_x(img, path, k=4):
    img.resize((img.width * k, img.height * k), Image.NEAREST).save(path)


def save_gif(frames, path, k=3, ms=110):
    big = [f.convert("RGB").resize((f.width * k, f.height * k), Image.NEAREST) for f in frames]
    big[0].save(path, save_all=True, append_images=big[1:], duration=ms, loop=0, optimize=False)


# ------------------------------------------------------------------ sprites, texto y piezas chicas
def sprite(rows, pal, flip=False):
    """Sprite desde filas de caracteres; '.' es vacío. Devuelve una imagen sin contorno."""
    w, h = max(len(r) for r in rows), len(rows)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != "." and ch != " ":
                im.putpixel((x, y), hexc(pal[ch]))
    return im.transpose(Image.FLIP_LEFT_RIGHT) if flip else im


FONT = {
    "A": ["###", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."], "C": ["###", "#..", "#..", "#..", "###"],
    "D": ["##.", "#.#", "#.#", "#.#", "##."], "E": ["###", "#..", "##.", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
    "I": ["###", ".#.", ".#.", ".#.", "###"], "L": ["#..", "#..", "#..", "#..", "###"], "M": ["#.#", "###", "###", "#.#", "#.#"],
    "N": ["##.", "#.#", "#.#", "#.#", "#.#"], "O": ["###", "#.#", "#.#", "#.#", "###"], "P": ["###", "#.#", "###", "#..", "#.."],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"], "S": ["###", "#..", "###", "..#", "###"], "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"], "Y": ["#.#", "#.#", ".#.", ".#.", ".#."], "X": ["#.#", "#.#", ".#.", "#.#", "#.#"], "G": ["###", "#..", "#.#", "#.#", "###"],
    "!": ["#", "#", "#", ".", "#"], "¡": ["#", ".", "#", "#", "#"], "$": [".#.", "###", "##.", ".##", "###"], ".": [".", ".", ".", ".", "#"],
    "2": ["###", "..#", "###", "#..", "###"], "1": [".#", "##", ".#", ".#", ".#"], "0": ["###", "#.#", "#.#", "#.#", "###"],
    " ": ["..", "..", "..", "..", ".."], "?": ["###", "..#", ".##", "...", ".#."],
}


def text_w(s):
    return sum(len(FONT[c][0]) + 1 for c in s) - 1


def text(L, s, x, y, c):
    for ch in s:
        g = FONT[ch]
        for gy, row in enumerate(g):
            for gx, v in enumerate(row):
                if v == "#": L.px([(x + gx, y + gy)], c)
        x += len(g[0]) + 1


PIPS = {1: [(1, 1)], 2: [(0, 0), (2, 2)], 3: [(0, 0), (1, 1), (2, 2)], 4: [(0, 0), (2, 0), (0, 2), (2, 2)],
        5: [(0, 0), (2, 0), (1, 1), (0, 2), (2, 2)], 6: [(0, 0), (2, 0), (0, 1), (2, 1), (0, 2), (2, 2)]}


def mini_die(L, x, y, v, red_one=False):
    """Dado de 7 px con la luz del dado modelo (arriba e izquierda claras, abajo y derecha en sombra)."""
    L.rect(x, y, x + 6, y + 6, "#ecd8ac")
    L.rect(x, y, x + 6, y, "#fff2d2"); L.rect(x, y, x, y + 6, "#fff2d2")
    L.rect(x, y + 6, x + 6, y + 6, "#c29a64"); L.rect(x + 6, y, x + 6, y + 6, "#c29a64")
    for gx, gy in PIPS[v]:
        L.px([(x + 1 + gx * 2, y + 1 + gy * 2)], "#d63a30" if (red_one and v == 1) else "#2a1a14")


def star(L, x, y, r, c="#fff6c8"):
    L.px([(x, y)], "#ffffff")
    for k in range(1, r + 1):
        L.px([(x - k, y), (x + k, y), (x, y - k), (x, y + k)], c)


def rot(im, deg, pivot=None):
    """Gira una imagen chica (NEAREST) alrededor de `pivot`; el resultado conserva el tamaño."""
    return im.rotate(deg, Image.NEAREST, expand=False, center=pivot)


def tint_edges(img, color, alpha=0.6):
    a = np.array(img).astype(float)
    solid = a[..., 3] > 0
    inner = nd.binary_erosion(solid)
    edge = solid & ~inner
    c = np.array(hexc(color)[:3], float)
    a[edge, :3] = a[edge, :3] * (1 - alpha) + c * alpha
    return Image.fromarray(a.astype(np.uint8))


def glow(L_im, cx, cy, r, color, a0=120):
    """Halo suave escalonado (2 anillos) en una capa aparte; sin destellos."""
    d = ImageDraw.Draw(L_im)
    c = hexc(color)
    for k, al in ((r, a0 // 3), (int(r * .65), a0 // 2)):
        d.ellipse([cx - k, cy - k, cx + k, cy + k], fill=c[:3] + (al,))


def hand_mask(img):
    return np.array(img)[..., 3] > 0


def area_rows(img, y0, y1):
    m = hand_mask(img)
    out = np.zeros_like(m)
    out[y0:y1] = m[y0:y1]
    return out


def specks(img, colors, n, y0, y1, seed=1):
    rng = np.random.default_rng(seed)
    a = np.array(img)
    m = a[..., 3] > 0
    ys, xs = np.nonzero(m[y0:y1])
    if not len(ys): return img
    for i in rng.choice(len(ys), size=min(n, len(ys)), replace=False):
        a[ys[i] + y0, xs[i]] = hexc(colors[i % len(colors)])
    return Image.fromarray(a)


def grow(img, w, h, ox=0, oy=0):
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(img, (ox, oy), img)
    return out


def tips(img, min_y=26):
    """Puntas de los dedos: columnas donde el borde de abajo hace un máximo local."""
    m = hand_mask(img)
    bottom = [int(np.nonzero(m[:, x])[0].max()) if m[:, x].any() else -1 for x in range(m.shape[1])]
    out = []
    x = 0
    while x < len(bottom):
        b = bottom[x]
        if b >= min_y and all(bottom[j] <= b for j in range(max(0, x - 3), min(len(bottom), x + 4))):
            run = [j for j in range(x, min(len(bottom), x + 6)) if bottom[j] == b]
            out.append(((run[0] + run[-1]) / 2.0, b))
            x = run[-1] + 3
        else:
            x += 1
    return out


def nails(img, color, length=3, min_y=26, light=None):
    """Uñas o garras: punta afinada que sale de cada dedo hacia abajo."""
    im = grow(img, img.width, img.height + length + 2)
    L = ImageDraw.Draw(im)
    for cx, b in tips(img, min_y):
        x = int(cx)
        for k in range(length):
            half = max(0, (length - k) // 2)
            L.rectangle([x - half, b + 1 + k, x + half, b + 1 + k], fill=hexc(color))
        if light: L.point([(x - max(0, length // 2), b + 1)], fill=hexc(light))
    return im


def fur(img, color_dark, color_light, seed=3, every=3):
    """Pelaje: mechones que salen del borde (izquierda, derecha y dedos) y trazos cortos en el dorso."""
    a = np.array(grow(img, img.width + 4, img.height + 3, 2, 0))
    m = a[..., 3] > 0
    rng = np.random.default_rng(seed)
    h, w = m.shape
    for y in range(4, h, every):
        xs = np.nonzero(m[y])[0]
        if not len(xs): continue
        for x, dx in ((xs.min(), -1), (xs.max(), 1)):
            for k in (1, 2):
                xx = x + dx * k
                if 0 <= xx < w and rng.random() < (0.9 if k == 1 else 0.5):
                    a[y - (k - 1), xx] = hexc(color_dark)
    ys, xs = np.nonzero(m)
    for i in rng.choice(len(ys), size=len(ys) // 16, replace=False):
        y, x = ys[i], xs[i]
        if y + 2 < h and m[y + 1, x] and m[y + 2, x]:   # trazos de pelo de 2 px, en el sentido de los dedos
            c = hexc(color_dark if rng.random() < .65 else color_light)
            a[y, x] = c; a[y + 1, x] = c
    return Image.fromarray(a)
