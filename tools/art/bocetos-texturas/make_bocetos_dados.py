"""Bocetos de dados (05/11/2026): elementos grandes y metales nuevos.

Genera PNG 1x (pixel art) para la página de bocetos de «4. Texturas». No toca assets/ ni el juego.
Uso: py -3 make_bocetos_dados.py <carpeta_salida>

- Elementos: «hoy» replica Die.draw_element_edges; A = marcas grandes dentro del dado; B = aura que sale del dado.
- Metales: replica el shader die_body.gdshader (acero/cobre) y agrega hierro oxidado, cobre oxidado y oro.
Las caras se leen de assets/art/dice-faces-v1/negro-v1.png (protegido, solo lectura).
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "test-results", "bocetos-texturas")
os.makedirs(OUT, exist_ok=True)

SHEET = Image.open(os.path.join(ROOT, "assets/art/dice-faces-v1/negro-v1.png")).convert("RGBA")
REGIONS = [(80, 56, 416, 424), (560, 56, 416, 424), (1040, 56, 416, 424),
           (80, 536, 416, 424), (560, 536, 416, 424), (1040, 536, 416, 424)]
DISPLAY = (3, 2, 56, 57)


def hexc(h, a=255):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def face(value):
    x, y, w, h = REGIONS[value - 1]
    crop = SHEET.crop((x, y, x + w, y + h)).convert("RGBa").resize((DISPLAY[2], DISPLAY[3]), Image.LANCZOS).convert("RGBA")
    canvas = Image.new("RGBA", (62, 62), (0, 0, 0, 0))
    canvas.paste(crop, (DISPLAY[0], DISPLAY[1]))
    return canvas


def pip_mask(img):
    """Cajas de los puntos (como Art.pip_bounds): oscuros dentro del área interior."""
    a = np.array(img).astype(float)
    mask = np.zeros((62, 62), bool)
    x0, y0 = DISPLAY[0], DISPLAY[1]
    w, h = DISPLAY[2], DISPLAY[3]
    ys, xs = np.mgrid[0:62, 0:62]
    inner = (xs >= x0 + w * 0.12) & (xs < x0 + w * 0.88) & (ys >= y0 + h * 0.23) & (ys < y0 + h * 0.86)
    dark = (a[..., 3] > 190) & (a[..., :3].max(axis=2) < 128) & inner
    lab, n = ndimage.label(dark)
    for i in range(1, n + 1):
        if (lab == i).sum() > 6:
            mask |= (lab == i)
    return ndimage.binary_dilation(mask, iterations=1)


# ---------------------------------------------------------------- metales
def shade_of(img):
    a = np.array(img).astype(float) / 255
    light = a[..., 0] * .299 + a[..., 1] * .587 + a[..., 2] * .114
    ys = np.arange(62)[:, None] * np.ones((1, 62))
    grain = ((np.floor((ys - 2) * 3) % 3) - 1) * 0.016
    return np.clip(light * 1.06 - 0.06 + grain, 0, 1)


def mix(c0, c1, t):
    c0 = np.array(c0, float)
    c1 = np.array(c1, float)
    return c0 + (c1 - c0) * t[..., None]


def steel_rgb(shade):
    return mix((.07, .09, .12), (.93, .96, 1.0), shade) * 255


def copper_rgb(shade):
    rgb = mix((.19, .055, .025), (1.0, .59, .23), shade)
    hi = np.clip((shade - .91) / .09, 0, 1)
    rgb = rgb + (np.array((1.0, .90, .69)) - rgb) * hi[..., None] * (shade > .91)[..., None]
    return rgb * 255


def ramp(colors, idx):
    pal = np.array([hexc(c)[:3] for c in colors], float)
    idx = np.clip(idx.astype(int), 0, len(pal) - 1)
    return pal[idx]


def noise(seed, blur, size=62):
    rng = np.random.default_rng(seed)
    img = Image.fromarray((rng.random((size, size)) * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(blur))
    n = np.array(img).astype(float)
    lo, hi = np.percentile(n, 2), np.percentile(n, 98)
    return np.clip((n - lo) / (hi - lo + 1e-6), 0, 1)


def streaks(seed, down=9, across=0.8):
    """Vetas verticales: ruido muy alargado hacia abajo (goteos)."""
    rng = np.random.default_rng(seed)
    n = rng.random((62, 62))
    n = ndimage.gaussian_filter(n, sigma=(down, across), mode="wrap")
    lo, hi = np.percentile(n, 2), np.percentile(n, 98)
    return np.clip((n - lo) / (hi - lo + 1e-6), 0, 1)


def edge_distance(img):
    alpha = np.array(img)[..., 3] > 128
    return ndimage.distance_transform_edt(alpha)


def finish(rgb, base_img, pips):
    out = np.array(base_img).astype(float)
    body = (out[..., 3] > 0) & ~pips
    out[..., :3][body] = np.clip(rgb[body], 0, 255)
    return Image.fromarray(out.astype("uint8"), "RGBA")


def metal(kind, variant, value):
    img = face(value)
    pips = pip_mask(img)
    shade = shade_of(img)
    dist = edge_distance(img)
    rows = np.arange(62)[:, None] * np.ones((1, 62))
    if kind == "steel":
        rgb = steel_rgb(shade)
    elif kind == "copper":
        rgb = copper_rgb(shade)
    elif kind == "rust_iron":
        base = steel_rgb(shade)
        rust = ["2c110a", "55220f", "82351a", "b04f22", "d97a2c", "f0a64a"]
        blot, fine = noise(11, 2.6), noise(12, .7)
        if variant == "A":
            cover = blot * .78 + fine * .22
            rustness = cover > .30
            tone = shade * .62 + (fine - .5) * .5 + (blot - .5) * .25
            pits = (noise(13, .9) > .86)
        else:
            drip = streaks(14, 11, .9)
            corner = np.clip(1 - dist / 9, 0, 1)
            cover = drip * .62 + corner * .55 + blot * .25
            rustness = cover > .5
            tone = shade * .55 + (drip - .5) * .55 + (fine - .5) * .3
            pits = (noise(15, .8) > .88)
        rr = ramp(rust, np.clip(tone * 5.2 + 1.0, 0, 5))
        rr[pits & rustness] = ramp(rust, np.zeros((62, 62)))[pits & rustness]
        rgb = np.where(rustness[..., None], rr, base * .92)
    elif kind == "rust_copper":
        base = copper_rgb(shade)
        green = ["0b2622", "14463c", "1f6b57", "30a07c", "66cba3", "b4f1d0"]
        blot, fine = noise(21, 2.4), noise(22, .7)
        if variant == "A":
            cover = blot * .8 + fine * .2 - np.clip(1 - dist / 5, 0, 1) * .38
            patina = cover > .40
            tone = shade * .6 + (fine - .5) * .5 + (blot - .5) * .3
        else:
            drip = streaks(23, 10, 1.0)
            top = np.clip(1 - rows / 30, 0, 1)
            cover = drip * .7 + top * .3 + blot * .2 - np.clip(1 - dist / 4, 0, 1) * .25
            patina = cover > .52
            tone = shade * .55 + (drip - .5) * .6 + (fine - .5) * .3
        gg = ramp(green, np.clip(tone * 5.4 + .8, 0, 5))
        rgb = np.where(patina[..., None], gg, base)
    elif kind == "gold":
        gold = ["3f2605", "7d4f0e", "bf8419", "efb62c", "ffdb58", "fff6b8"]
        if variant == "A":
            idx = np.clip(np.clip((shade - .5) / .42, 0, 1) ** 1.7 * 5.6, 0, 5)
            ys, xs = np.mgrid[0:62, 0:62]
            band = np.abs((xs + ys) - 52) < 3
            idx = np.where(band, np.minimum(idx + 1.6, 5), idx)
            rgb = ramp(gold, idx)
        else:
            dim = noise(31, 1.2)
            idx = np.clip(np.clip((shade - .5) / .42, 0, 1) ** 1.5 * 5.2 + (dim - .5) * 2.4, 0, 5)
            rgb = ramp(gold, idx)
    else:
        raise ValueError(kind)
    out = finish(rgb, img, pips)
    if kind == "gold" and variant == "B":
        d = ImageDraw.Draw(out)
        cx, cy = 53, 9  # monedita en la esquina: «da dinero si no se usa»
        d.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=hexc("3f2605"))
        d.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=hexc("ffdb58"))
        d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=hexc("bf8419"))
        d.point((cx - 3, cy - 3), fill=hexc("fff6b8"))
        d.point((cx - 2, cy - 3), fill=hexc("fff6b8"))
    return out


# ---------------------------------------------------------------- elementos
SIZE = 96
OFF = 17            # el dado (62×62) va en (17,17) dentro de 96×96
L, R, T, B = OFF + 3, OFF + 59, OFF + 2, OFF + 59  # cuerpo del dado


def base_die(value=6):
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(face(value), (OFF, OFF))
    return canvas


def new_overlay():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def mirror_add(ov):
    ov.alpha_composite(ov.transpose(Image.FLIP_LEFT_RIGHT))
    return ov


def flame(d, x, y, h, w, cols, lean=0.0):
    """Llama de píxeles: base centrada en (x,y), punta arriba. Tres capas anidadas."""
    for k, col in enumerate(cols):
        s = 1 - k * .27
        hh, ww = h * s, w * s
        pts_l, pts_r = [], []
        for i in range(0, 13):
            t = i / 12
            half = ww / 2 * (1 - t) ** .75 * (1 + .22 * math.sin(t * 6.5))
            cx = x + lean * t * ww + math.sin(t * 3.2) * ww * .22 * t
            yy = y - hh * t - k * 1.2 * (1 - t)
            pts_l.append((cx - half, yy))
            pts_r.append((cx + half, yy))
        d.polygon(pts_l + pts_r[::-1], fill=hexc(col))


def drop(d, x, y, r, dark, mid, light):
    d.polygon([(x, y - r * 1.9), (x - r * .85, y - r * .2), (x + r * .85, y - r * .2)], fill=hexc(dark))
    d.ellipse((x - r, y - r * .4, x + r, y + r * 1.4), fill=hexc(dark))
    d.polygon([(x, y - r * 1.5), (x - r * .6, y - r * .1), (x + r * .6, y - r * .1)], fill=hexc(mid))
    d.ellipse((x - r * .75, y - r * .1, x + r * .75, y + r * 1.15), fill=hexc(mid))
    d.ellipse((x - r * .45, y + r * .05, x - r * .05, y + r * .5), fill=hexc(light))


def bolt(d, pts, widths_cols):
    for w, col in widths_cols:
        d.line(pts, fill=hexc(col), width=w, joint="curve")


def rock(d, x, y, w, h, dark="3a2412", mid="9a6a36", light="d2a468"):
    pts = [(x, y + h * .55), (x + w * .15, y + h * .1), (x + w * .55, y), (x + w * .95, y + h * .25), (x + w, y + h * .8), (x + w * .6, y + h), (x + w * .1, y + h)]
    d.polygon(pts, fill=hexc(dark))
    inner = [(x + w * .12 + 1, y + h * .6), (x + w * .25, y + h * .22), (x + w * .55, y + h * .12), (x + w * .85, y + h * .3), (x + w * .9, y + h * .78), (x + w * .6, y + h * .9), (x + w * .15, y + h * .9)]
    d.polygon(inner, fill=hexc(mid))
    d.polygon([(x + w * .25, y + h * .25), (x + w * .55, y + h * .15), (x + w * .6, y + h * .35), (x + w * .3, y + h * .45)], fill=hexc(light))


def spiral(d, cx, cy, r0, turns, width, cols, start=0.0, sign=1):
    pts = []
    steps = int(turns * 30)
    for i in range(steps + 1):
        t = i / steps
        ang = start + sign * t * turns * math.tau
        r = r0 * (1 - .82 * t)
        pts.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
    for w, col in zip(width, cols):
        d.line(pts, fill=hexc(col), width=w, joint="curve")


# --- «hoy»: réplica de Die.draw_element_edges (coordenadas de 62×62 + OFF)
def hoy(element):
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    o = OFF

    def line(pts, col, w):
        d.line([(o + px, o + py) for px, py in pts], fill=hexc(col), width=max(1, round(w)), joint="curve")

    def rect(x, y, w, h, col):
        d.rectangle((o + x, o + y, o + x + max(w, 1) - 1, o + y + max(h, 1) - 1), fill=hexc(col))

    for s in (-1, 1):
        x = 31 + s * 27
        if element == "electricity":
            p = [(x - s * 6, 4), (x - s * 2, 10), (x - s * 4, 15), (x, 20), (x - s * 2, 25)]
            line(p, "d78205", 3)
            line(p, "ffe72c", 2)
            line([(x, 36), (x - s * 2, 42), (x, 46), (x - s * 3, 51), (x - s * 6, 56)], "ffdc22", 2)
        elif element == "fire":
            line([(x - s * 2, 49), (x - s * 3, 54), (x - s * 7, 57), (x - s * 11, 57)], "e6541a", 2)
            for y in (13, 34, 48, 54):
                ex = x - s * (3 if y == 54 else 0)
                rect(ex - 1, y, 3, 4, "e74612")
                rect(ex, y - 2, 2, 3, "ffd04a")
        elif element == "water":
            for y in (12, 31, 46, 54):
                ex = x - s * (4 if y == 54 else 0)
                rect(ex - 1, y, 3, 3, "168ad0")
                rect(ex, y, 1, 1, "a6f5ff")
            line([(x - s * 8, 57), (x - s * 3, 55)], "47d3ed", 2)
            line([(x - s * 13, 57), (x - s * 9, 57)], "168ad0", 2)
        elif element == "earth":
            for dist in (6, 11):
                rect(x - s * dist - 1, 55, 3, 3, "916136")
                rect(x - s * dist - 1, 55, 2, 1, "d6aa6e")
            for y in (15, 38, 49, 54):
                ex = x - s * (4 if y == 54 else 0)
                rect(ex - 1, y, 3, 3, "795131")
                rect(ex - 1, y, 2, 1, "c99558")
        elif element == "wind":
            line([(x - s * 5, 56), (x - s * 11, 57), (x - s * 13, 55)], "71d9e9", 2)
            for y in (10, 35, 51):
                line([(x - s * 3, y - 3), (x, y), (x - s * 1, y + 3), (x - s * 4, y + 3)], "71d9e9", 2)
    return ov


# --- Opción A: marcas grandes que se quedan sobre el borde del dado (máx. 3 px afuera)
def opcion_a(element):
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    if element == "fire":
        fc = ["a31808", "ee5a12", "ffc233", "fff4a8"]
        flame(d, L, B + 1, 34, 12, fc, lean=.3)
        flame(d, L - 1, T + 33, 20, 9, fc, lean=-.3)
        flame(d, L, T + 14, 14, 8, fc, lean=.3)
    elif element == "water":
        dk, md, lt = "0b3d78", "1a86cf", "9be8fb"
        drop(d, L + 1, T + 16, 4.4, dk, md, lt)
        drop(d, L + 0, T + 33, 5.0, dk, md, lt)
        drop(d, L + 2, T + 49, 4.2, dk, md, lt)
        pts = [(L - 2 + i, B + 3 + 2.4 * math.sin(i * .5)) for i in range(0, 24)]
        d.line(pts, fill=hexc(dk), width=5)
        d.line(pts, fill=hexc(md), width=3)
        d.line([(x, y - 1) for x, y in pts[2:14]], fill=hexc("e8fdff"), width=1)
    elif element == "electricity":
        bolt(d, [(L + 6, T - 2), (L + 1, T + 9), (L + 5, T + 16), (L - 1, T + 28)], [(6, "7a3d00"), (4, "e08a00"), (2, "fff56a")])
        bolt(d, [(L + 5, T + 34), (L + 0, T + 43), (L + 4, T + 49), (L - 2, T + 58)], [(6, "7a3d00"), (4, "e08a00"), (2, "fff56a")])
        for (sx, sy) in ((L + 8, T + 24), (L + 7, T + 52)):
            d.line([(sx - 2, sy), (sx + 2, sy)], fill=hexc("fff56a"), width=1)
            d.line([(sx, sy - 2), (sx, sy + 2)], fill=hexc("fff56a"), width=1)
    elif element == "earth":
        rock(d, L - 4, B - 9, 13, 12)
        rock(d, L + 6, B - 3, 9, 7, mid="7d5228")
        rock(d, L - 3, T + 31, 8, 8, mid="86592c")
        rock(d, L - 2, T + 10, 7, 7, mid="86592c")
        for gx in (L + 11, L + 14):
            d.line([(gx, B + 3), (gx - 1, B - 1)], fill=hexc("5c8a3a"), width=2)
    elif element == "wind":
        c1, c2 = ["3f9db0", "bdf2fa"], [2, 3]
        spiral(d, L, T + 13, 7, 1.4, [4, 2], ["3f9db0", "e6fcff"], 1.2)
        spiral(d, L, T + 43, 7, 1.4, [4, 2], ["3f9db0", "e6fcff"], .2)
        d.line([(L - 7, T + 28), (L + 3, T + 27), (L + 6, T + 30)], fill=hexc("bdf2fa"), width=2)
    return mirror_add(ov)


# --- Opción B: aura grande que sale del dado
def opcion_b(element):
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    cx = (L + R) // 2
    if element == "fire":
        fc = ["a31808", "ee5a12", "ffc233", "fff4a8"]
        flame(d, L + 10, T + 3, 22, 14, fc, lean=-.25)
        flame(d, cx, T + 3, 32, 18, fc, lean=.1)
        flame(d, R - 10, T + 3, 24, 14, fc, lean=.3)
        flame(d, L + 3, B - 2, 18, 11, fc, lean=-.3)
        flame(d, R - 3, B - 2, 18, 11, fc, lean=.3)
        for (ex, ey) in ((L - 6, T + 20), (R + 6, T + 30), (cx + 12, T - 28), (L + 20, T - 18)):
            d.rectangle((ex, ey, ex + 1, ey + 1), fill=hexc("ffd04a"))
    elif element == "water":
        dk, md, lt = "0b3d78", "1a86cf", "9be8fb"
        pts = [(L - 10 + i, B + 6 + 3.2 * math.sin(i * .38)) for i in range(0, R - L + 21)]
        d.line(pts, fill=hexc(dk), width=9)
        d.line(pts, fill=hexc(md), width=6)
        d.line([(x, y - 2) for x, y in pts], fill=hexc("5cc7ee"), width=2)
        for x, y in pts[::6]:
            d.rectangle((x, y - 4, x + 1, y - 3), fill=hexc("e8fdff"))
        for gx in (L + 10, cx, R - 10):
            drop(d, gx, B + 20, 3.6, dk, md, lt)
        drop(d, L - 8, T + 26, 4.2, dk, md, lt)
        drop(d, R + 8, T + 14, 4.2, dk, md, lt)
        for k in range(3):
            d.line([(L - 3 - k * 3, T + 40 + k * 4), (L - 8 - k * 3, T + 36 + k * 4)], fill=hexc("9be8fb"), width=1)
    elif element == "electricity":
        halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        hd = ImageDraw.Draw(halo)
        hd.rounded_rectangle((L - 5, T - 5, R + 5, B + 5), radius=12, outline=(255, 240, 120, 150), width=3)
        ov.alpha_composite(halo)
        d = ImageDraw.Draw(ov)
        bolt(d, [(L + 4, T + 2), (L - 3, T - 6), (L + 1, T - 11), (L - 9, T - 20), (L - 6, T - 14)], [(7, "7a3d00"), (5, "e08a00"), (3, "fff56a"), (1, "ffffff")])
        bolt(d, [(L + 3, B - 2), (L - 5, B + 6), (L - 1, B + 11), (L - 11, B + 19)], [(7, "7a3d00"), (5, "e08a00"), (3, "fff56a"), (1, "ffffff")])
        bolt(d, [(L - 4, T + 30), (L - 14, T + 27), (L - 11, T + 33), (L - 20, T + 31)], [(5, "7a3d00"), (3, "e08a00"), (1, "fff56a")])
    elif element == "earth":
        for (rx, ry, rw, rh, md) in ((L - 8, B - 1, 22, 16, "9a6a36"), (L + 14, B + 3, 24, 14, "86592c"), (R - 30, B - 1, 24, 17, "9a6a36"), (R - 14, B + 4, 18, 11, "7d5228"), (cx - 8, B + 8, 16, 9, "6b4524")):
            rock(d, rx, ry, rw, rh, mid=md)
        d.polygon([(L - 6, B + 12), (R + 6, B + 12), (R + 2, B + 16), (L - 2, B + 16)], fill=hexc("3a2412"))
        for side, x0 in ((-1, L - 3), (1, R + 3)):
            pts = [(x0, B - 2), (x0 + side * 4, B - 14), (x0 - side * 1, B - 26), (x0 + side * 4, B - 38), (x0, B - 50)]
            d.line(pts, fill=hexc("3d2a14"), width=3, joint="curve")
            for (lx, ly) in ((pts[1][0], pts[1][1]), (pts[3][0], pts[3][1])):
                d.polygon([(lx, ly), (lx + side * 9, ly - 4), (lx + side * 4, ly + 3)], fill=hexc("5c8a3a"))
                d.polygon([(lx, ly), (lx + side * 6, ly - 3), (lx + side * 3, ly + 1)], fill=hexc("8fc060"))
    elif element == "wind":
        for side, x0 in ((-1, L - 9), (1, R + 9)):
            spiral(d, x0, T + 20, 12, 1.5, [5, 3], ["3f9db0", "e6fcff"], 1.0, sign=side)
            spiral(d, x0, T + 48, 12, 1.5, [5, 3], ["3f9db0", "e6fcff"], .4, sign=side)
            d.line([(x0 + side * 4, T + 33), (x0 - side * 12, T + 32), (x0 - side * 16, T + 35)], fill=hexc("bdf2fa"), width=2)
        d.line([(L - 18, B + 8), (L + 14, B + 7), (L + 20, B + 11)], fill=hexc("9ae8f2"), width=2)
        d.line([(R + 18, T - 8), (R - 14, T - 7), (R - 20, T - 11)], fill=hexc("9ae8f2"), width=2)
        d.line([(L + 24, T - 12), (R - 24, T - 10)], fill=hexc("e0fbff"), width=1)
    return ov


ELEMENT_ORDER = ("fire", "water", "electricity", "earth", "wind")


def export_atlas(path):
    """Hoja de las marcas A (solo la capa del elemento, sin dado): 5 celdas de 96×96, en ELEMENT_ORDER.
    El dado (62×62) va en (17,17) de cada celda: se dibuja en (-17,-17) respecto del control del dado."""
    atlas = Image.new("RGBA", (SIZE * len(ELEMENT_ORDER), SIZE), (0, 0, 0, 0))
    for i, element in enumerate(ELEMENT_ORDER):
        atlas.alpha_composite(opcion_a(element), (i * SIZE, 0))
    atlas.save(path)
    print("hoja de elementos:", path)


def main():
    if len(sys.argv) > 2 and sys.argv[2] == "--atlas":
        export_atlas(sys.argv[3])
        return
    for element in ("fire", "water", "electricity", "earth", "wind"):
        for name, ov in (("hoy", hoy(element)), ("A", opcion_a(element)), ("B", opcion_b(element))):
            img = base_die(6)
            img.alpha_composite(ov)
            img.save(os.path.join(OUT, f"elem-{element}-{name}.png"))
    for value in (5, 6):
        metal("steel", "", value).save(os.path.join(OUT, f"met-steel-hoy-{value}.png"))
        metal("copper", "", value).save(os.path.join(OUT, f"met-copper-hoy-{value}.png"))
        for kind in ("rust_iron", "rust_copper", "gold"):
            for variant in ("A", "B"):
                metal(kind, variant, value).save(os.path.join(OUT, f"met-{kind}-{variant}-{value}.png"))
    print("listo:", OUT)


if __name__ == "__main__":
    main()
