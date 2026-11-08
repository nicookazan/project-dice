"""Bocetos de la tienda (07/11/2026): de qué cuelgan o dónde se apoyan las ofertas del maletín, dónde se guardan tus dados
y tus monedas, y los paquetes de monedas.

Parte de tres capturas reales (capture_tienda.gd): la diferencia entre la tienda completa y la tienda sin ofertas (o sin
inventario) recorta cada objeto, para dibujar detrás ganchos, repisas o bandejas en px lógicos (2×2 de pantalla).
Uso: py -3.13 tools/art/bocetos-jefes/tienda.py
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as nd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit as K  # noqa: E402

D = os.path.join(K.ROOT, "test-results", "bocetos-arte-2")
FULL = Image.open(os.path.join(D, "tienda-completa.png")).convert("RGBA")
NO_OFFERS = Image.open(os.path.join(D, "tienda-sin-ofertas.png")).convert("RGBA")
NO_INV = Image.open(os.path.join(D, "tienda-sin-inventario.png")).convert("RGBA")
FONT = ImageFont.truetype("consolab.ttf", 17)
FONT_S = ImageFont.truetype("consolab.ttf", 13)

GOLD = ["#2e1508", "#5c300c", "#96601a", "#c98f24", "#ecbc42", "#ffe07a", "#fff8c8"]
WOOD = ["#1e0f08", "#3a1e0e", "#5a3418", "#7a4a24", "#9a6436"]
LEATHER = ["#10090a", "#241614", "#3a2620", "#54382c", "#74503c"]

# (sección, caja del objeto en pantalla, caja del precio o None, texto del precio)
OFFERS = [
    ("numbers", (593, 292, 86, 86), "$3"), ("numbers", (765, 292, 86, 86), "$3"),
    ("components", (990, 292, 85, 86), "$4"), ("components", (1172, 292, 85, 86), "$5"),
    ("coins", (622, 477, 90, 97), "$2"), ("coins", (712, 477, 90, 97), "$2"), ("coins", (802, 477, 95, 97), "$2"),
    ("stickers", (982, 477, 106, 97), "$4"), ("stickers", (1183, 478, 82, 94), "$7"),
]
SOLD = ("coins", (540, 482, 80, 90))
SECTIONS = {"numbers": (538, 252, 367, 179), "components": (929, 252, 388, 179), "coins": (525, 442, 380, 179), "stickers": (929, 442, 401, 179)}


def item_mask(full, clean, box, thr=12):
    x, y, w, h = box
    m = np.zeros((full.height, full.width), bool)
    diff = np.abs(np.array(full).astype(int)[..., :3] - np.array(clean).astype(int)[..., :3]).sum(-1) > thr
    m[y:y + h, x:x + w] = diff[y:y + h, x:x + w]
    m = nd.binary_closing(m, iterations=2)
    return nd.binary_fill_holes(m)


def logical():
    return K.Layer(720, 450)


def up(L):
    return L.im.resize((1440, 900), Image.NEAREST)


def shadow(img, mask, dx, dy, k=.45):
    a = np.array(img).astype(float)
    sh = np.zeros_like(mask)
    sh[dy:, dx:] = mask[:-dy, :-dx]
    sh &= ~mask
    a[sh, :3] *= (1 - k)
    return Image.fromarray(a.astype(np.uint8))


def paste_items(img, full, masks):
    a = np.array(img)
    f = np.array(full)
    for m in masks: a[m] = f[m]
    return Image.fromarray(a)


def text_center(img, s, cx, cy, color, font=FONT):
    d = ImageDraw.Draw(img)
    d.fontmode = "1"
    l, t, r, b = d.textbbox((0, 0), s, font=font)
    d.text((int(cx - (r - l) / 2 - l), int(cy - (b - t) / 2 - t)), s, fill=color, font=font)


def moved(full, m, dy):
    """Corre un objeto `dy` px hacia abajo: devuelve (imagen con el objeto movido, máscara movida)."""
    if not dy: return full, m
    f = np.array(full)
    out = f.copy()
    m2 = np.zeros_like(m)
    m2[dy:] = m[:-dy]
    out[m2] = f[np.roll(m2, -dy, axis=0)]
    return Image.fromarray(out), m2


def compose(base, full, entries, back, front=None, shadow_off=(4, 6), texts=()):
    masks = []
    for e in entries:
        if isinstance(e, tuple):
            img, m = moved(full, e[0], e[1])
            full = paste_items(full.copy(), img, [m]) if e[1] else full
            masks.append(m)
        else:
            masks.append(e)
    out = base.copy()
    out.alpha_composite(up(back))
    allm = np.zeros(masks[0].shape, bool)
    for m in masks: allm |= m
    if shadow_off: out = shadow(out, allm, *shadow_off)
    out = paste_items(out, full, masks)
    if front is not None: out.alpha_composite(up(front))
    for s, cx, cy, col, *font in texts: text_center(out, s, cx, cy, col, *(font or [FONT]))
    return out


# ------------------------------------------------------------------ maletín A: gancho y etiqueta
def hook(L, hx, hy):
    L.ellipse(hx - 2, hy - 2, hx + 2, hy + 2, GOLD[2]); L.ellipse(hx - 1, hy - 2, hx + 1, hy, GOLD[5]); L.px([(hx, hy)], GOLD[1])
    L.line([(hx, hy + 2), (hx, hy + 5)], GOLD[4]); L.px([(hx + 1, hy + 6), (hx + 2, hy + 5), (hx + 2, hy + 4)], GOLD[4])


def tag(L, cx, ty, w=22):
    x0 = cx - w // 2
    L.poly([(x0 + 3, ty), (x0 + w - 3, ty), (x0 + w, ty + 3), (x0 + w, ty + 11), (x0, ty + 11), (x0, ty + 3)], "#f2e6c0")
    L.rect(x0 + 1, ty + 10, x0 + w - 1, ty + 11, "#c9b48a"); L.rect(x0 + 1, ty + 3, x0 + 1, ty + 9, "#fff8e0")


def maletin_a():
    back = logical()
    texts = []
    masks = []
    for sec, (x, y, w, h), price in OFFERS:
        m = item_mask(FULL, NO_OFFERS, (x, y, w, h))
        masks.append(m)
        ys, xs = np.nonzero(m)
        cx = int(xs.mean()) // 2
        top, bot = ys.min() // 2, ys.max() // 2
        hy = top - 8
        hook(back, cx, hy)
        back.line([(cx, hy + 6), (cx - 7, top + 4)], "#e8dcc0"); back.line([(cx, hy + 6), (cx + 7, top + 4)], "#e8dcc0")
        back.line([(cx, bot - 2), (cx, bot + 4)], "#e8dcc0")
        tag(back, cx, bot + 4)
        texts.append((price, cx * 2, (bot + 10) * 2 + 1, "#3a2416"))
    sx, sy, sw, sh = SOLD[1]
    cx, top = (sx + sw // 2) // 2, (sy + 8) // 2
    hook(back, cx, top - 8)
    back.line([(cx, top - 2), (cx, top + 10)], "#e8dcc0")
    tag(back, cx, top + 10, 28)
    texts.append(("VENDIDO", cx * 2, (top + 16) * 2 + 1, "#7a2418", FONT_S))
    return compose(NO_OFFERS, FULL, masks, back, texts=texts)


# ------------------------------------------------------------------ maletín B: repisa de bronce con chapita
def shelf(L, x0, x1, y):
    L.rect(x0, y, x1, y + 2, GOLD[5]); L.rect(x0, y + 1, x1, y + 2, GOLD[4])
    L.rect(x0, y + 3, x1, y + 12, WOOD[2]); L.rect(x0, y + 3, x1, y + 3, WOOD[4]); L.rect(x0, y + 12, x1, y + 12, WOOD[0])
    L.rect(x0, y + 13, x1, y + 13, "#1c0610")
    for bx in (x0 + 4, x1 - 4):
        L.poly([(bx - 2, y + 13), (bx + 2, y + 13), (bx, y + 17)], GOLD[2])


def plate(L, cx, y, w=18):
    L.rect(cx - w // 2, y, cx + w // 2, y + 7, GOLD[3]); L.rect(cx - w // 2, y, cx + w // 2, y, GOLD[5])
    L.rect(cx - w // 2, y + 7, cx + w // 2, y + 7, GOLD[1]); L.px([(cx - w // 2 + 1, y + 3), (cx + w // 2 - 1, y + 3)], GOLD[1])


def maletin_b():
    back = logical()
    texts = []
    masks = []
    by_sec = {}
    for sec, box, price in OFFERS:
        m = item_mask(FULL, NO_OFFERS, box)
        masks.append(m)
        by_sec.setdefault(sec, []).append((m, price))
    for sec, items in by_sec.items():
        sx, sy, sw, sh = SECTIONS[sec]
        floor = max(int(np.nonzero(m)[0].max()) for m, _ in items) // 2 - 3
        shelf(back, sx // 2 + 8, (sx + sw) // 2 - 8, floor)
        for m, price in items:
            gap = (floor + 3) * 2 - int(np.nonzero(m)[0].max())
            if gap > 1:
                masks[[id(x) for x in masks].index(id(m))] = (m, gap - 1)
            cx = int(np.nonzero(m)[1].mean()) // 2
            plate(back, cx, floor + 4)
            texts.append((price, cx * 2, (floor + 8) * 2, "#2e1508"))
    sx, sy, sw, sh = SOLD[1]
    floor_c = None
    for sec, items in by_sec.items():
        if sec == "coins": floor_c = max(int(np.nonzero(m)[0].max()) for m, _ in items) // 2 - 3
    plate(back, (sx + sw // 2) // 2, floor_c + 4, 30)
    texts.append(("VENDIDO", sx + sw // 2, (floor_c + 8) * 2, "#2e1508", FONT_S))
    # los objetos se apoyan: se bajan hasta tocar la repisa
    return compose(NO_OFFERS, FULL, masks, back, shadow_off=(5, 3), texts=texts)


# ------------------------------------------------------------------ maletín C: presilla de cuero
def maletin_c():
    back = logical()
    front = logical()
    texts = []
    masks = []
    for sec, box, price in OFFERS:
        m = item_mask(FULL, NO_OFFERS, box)
        masks.append(m)
        ys, xs = np.nonzero(m)
        cx = int(xs.mean()) // 2
        x0, x1 = xs.min() // 2 - 5, xs.max() // 2 + 5
        y = ys.max() // 2 - 9
        front.rect(x0, y, x1, y + 9, LEATHER[2]); front.rect(x0, y, x1, y, LEATHER[4]); front.rect(x0, y + 9, x1, y + 9, LEATHER[0])
        for xx in range(x0 + 2, x1 - 1, 3): front.px([(xx, y + 2), (xx, y + 7)], GOLD[3])
        for rx in (x0 + 1, x1 - 1): front.px([(rx, y + 4), (rx, y + 5)], GOLD[5])
        back.rect(x0 - 1, y + 1, x0, y + 8, "#1c0610"); back.rect(x1, y + 1, x1 + 1, y + 8, "#1c0610")
        texts.append((price, cx * 2, (y + 5) * 2, "#ffe07a"))
    sx, sy, sw, sh = SOLD[1]
    cx, y = (sx + sw // 2) // 2, (sy + 50) // 2
    front.rect(cx - 18, y, cx + 18, y + 9, LEATHER[2]); front.rect(cx - 18, y, cx + 18, y, LEATHER[4])
    for xx in range(cx - 16, cx + 17, 3): front.px([(xx, y + 2), (xx, y + 7)], GOLD[3])
    texts.append(("VENDIDO", cx * 2, (y + 5) * 2, "#c9a46a", FONT_S))
    return compose(NO_OFFERS, FULL, masks, back, front, shadow_off=(4, 4), texts=texts)


# ------------------------------------------------------------------ dónde quedan tus dados y monedas
DICE = [(360, 804, 50, 50), (432, 804, 50, 50), (504, 804, 50, 50), (576, 804, 50, 50), (648, 804, 50, 50)]
COINS = [(794, 795, 44, 44), (872, 795, 44, 44), (950, 795, 44, 44)]
CAPACITY = 5
SLOT_X = [785 + i * 78 + 31 for i in range(CAPACITY)]
ONE_USE = (1269, 795, 44, 44)


def inv_masks():
    return [item_mask(FULL, NO_INV, b) for b in DICE + COINS + [ONE_USE]]


def tray(L, x0, y0, x1, y1, felt):
    """Bandeja con marco de madera biselado (luz arriba e izquierda), vivo dorado por dentro, esquineros de bronce con
    tornillo y tachas en el medio de los lados largos. `felt` = (sombra, cuerpo, luz) del paño."""
    L.rect(x0, y0, x1, y1, WOOD[0])
    L.rect(x0 + 1, y0 + 1, x1 - 1, y1 - 1, WOOD[2])
    L.rect(x0 + 1, y0 + 1, x1 - 1, y0 + 2, WOOD[4]); L.rect(x0 + 1, y0 + 1, x0 + 2, y1 - 1, WOOD[3])
    L.rect(x0 + 1, y1 - 2, x1 - 1, y1 - 1, WOOD[1]); L.rect(x1 - 2, y0 + 1, x1 - 1, y1 - 1, WOOD[1])
    for x in range(x0 + 6, x1 - 4, 7):   # veta
        L.px([(x, y0 + 3), (x + 3, y1 - 3)], WOOD[1])
    # vivo dorado y escalón hacia el paño
    L.rect(x0 + 4, y0 + 4, x1 - 4, y1 - 4, GOLD[2]); L.rect(x0 + 4, y0 + 4, x1 - 5, y0 + 4, GOLD[5]); L.rect(x0 + 4, y0 + 4, x0 + 4, y1 - 5, GOLD[4])
    L.rect(x0 + 5, y0 + 5, x1 - 5, y1 - 5, felt[1])
    L.rect(x0 + 5, y0 + 5, x1 - 5, y0 + 6, felt[0]); L.rect(x0 + 5, y0 + 5, x0 + 6, y1 - 5, felt[0])
    for y in range(y0 + 8, y1 - 5):      # pelusa del paño, salteada
        for x in range(x0 + 7, x1 - 5):
            if (x * 73 + y * 151) % 97 == 0: L.px([(x, y)], felt[2])
    # esquineros en L con tornillo
    for cx, sx in ((x0, 1), (x1, -1)):
        for cy, sy in ((y0, 1), (y1, -1)):
            L.rect(min(cx, cx + sx * 5), min(cy, cy + sy * 1), max(cx, cx + sx * 5), max(cy, cy + sy * 1), GOLD[4])
            L.rect(min(cx, cx + sx * 1), min(cy, cy + sy * 5), max(cx, cx + sx * 1), max(cy, cy + sy * 5), GOLD[4])
            L.px([(cx + sx * 2, cy + sy * 2)], GOLD[3]); L.px([(cx + sx, cy + sy)], GOLD[6])
            L.px([(cx + sx * 3, cy + sy), (cx + sx, cy + sy * 3)], GOLD[1])
    for mx in ((x0 + x1) // 2,):
        for y in (y0 + 1, y1 - 2):
            L.rect(mx - 1, y, mx + 1, y + 1, GOLD[4]); L.px([(mx - 1, y)], GOLD[6])


def bandeja_a():
    """Bandejas con marco de madera y bronce: paño verde de la mesa para los dados, terciopelo bordó liso para las
    monedas (sin huecos) y una bandejita aparte, con hueco y aro dorado, para la moneda de un uso."""
    L = logical()
    y0, y1 = 397, 431
    tray(L, 172, y0, 358, y1, ("#08261a", "#1c6a42", "#2f9058"))
    tray(L, SLOT_X[0] // 2 - 18, y0, SLOT_X[-1] // 2 + 18, y1, ("#2c0812", "#5a1024", "#8c1c2e"))
    cy = 414
    ux = (ONE_USE[0] + 22) // 2
    tray(L, ux - 19, y0, ux + 19, y1, ("#2c0812", "#5a1024", "#8c1c2e"))
    L.ellipse(ux - 13, cy - 13, ux + 13, cy + 13, GOLD[4]); L.ellipse(ux - 12, cy - 12, ux + 12, cy + 12, GOLD[1])
    L.ellipse(ux - 11, cy - 11, ux + 11, cy + 11, "#2c0812")
    shift = cy * 2 - 817
    masks = inv_masks()
    entries = masks[:5] + [(m, shift) for m in masks[5:]]
    return compose(NO_INV, FULL, entries, L, shadow_off=(4, 4))


def huecos_b():
    """Estuche: huecos hundidos en el mismo capitoné azul, con la forma de cada cosa; los vacíos se ven."""
    L = logical()
    def recess_sq(cx, cy, r):
        L.rect(cx - r, cy - r, cx + r, cy + r, "#0a1430"); L.rect(cx - r + 1, cy - r + 1, cx + r, cy + r, "#14245a")
        L.rect(cx - r + 1, cy + r, cx + r, cy + r, "#3a5cae"); L.rect(cx + r, cy - r + 1, cx + r, cy + r, "#3a5cae")
        L.rect(cx - r + 1, cy - r + 1, cx + r - 1, cy - r + 2, "#081028")

    def recess_round(cx, cy, r):
        L.ellipse(cx - r, cy - r, cx + r, cy + r, "#3a5cae"); L.ellipse(cx - r, cy - r, cx + r - 1, cy + r - 1, "#0a1430")
        L.ellipse(cx - r + 1, cy - r + 2, cx + r - 1, cy + r - 1, "#14245a")
    for x, y, w, h in DICE:
        recess_sq((x + w // 2) // 2, (y + h // 2) // 2, 15)
    for sx in SLOT_X: recess_round(sx // 2, 409, 13)
    ux = (ONE_USE[0] + 22) // 2
    L.ellipse(ux - 15, 394, ux + 15, 424, GOLD[4]); recess_round(ux, 409, 13)
    return compose(NO_INV, FULL, inv_masks(), L, shadow_off=None)


def repisa_c():
    """Repisa de madera con riel de bronce a lo largo de la barra, como la del maletín (opción B)."""
    L = logical()
    def strip(x0, x1, y):
        L.rect(x0, y, x1, y + 2, GOLD[5]); L.rect(x0, y + 1, x1, y + 2, GOLD[4])
        L.rect(x0, y + 3, x1, y + 6, WOOD[2]); L.rect(x0, y + 3, x1, y + 3, WOOD[4]); L.rect(x0, y + 6, x1, y + 6, WOOD[0])
        L.rect(x0, y + 7, x1, y + 7, "#081028")
    strip(172, 358, 426)
    strip(384, 578, 418)
    strip(620, 672, 418)
    return compose(NO_INV, FULL, inv_masks(), L, shadow_off=(5, 2))


def crop_zoom(img, box, k=1):
    c = img.crop(box)
    return c.resize((c.width * k, c.height * k), Image.NEAREST) if k != 1 else c


def main():
    for name, fn in (("maletin-A", maletin_a), ("maletin-B", maletin_b), ("maletin-C", maletin_c)):
        im = fn()
        im.save(os.path.join(D, f"tienda-{name}.png"))
        crop_zoom(im, (500, 230, 1360, 640), 2).save(os.path.join(D, f"tienda-{name}-zoom.png"))
        print(name)
    for name, fn in (("deposito-A", bandeja_a), ("deposito-B", huecos_b), ("deposito-C", repisa_c)):
        im = fn()
        im.save(os.path.join(D, f"tienda-{name}.png"))
        crop_zoom(im, (330, 770, 1340, 880), 2).save(os.path.join(D, f"tienda-{name}-zoom.png"))
        print(name)
    crop_zoom(FULL, (500, 230, 1360, 640), 2).save(os.path.join(D, "tienda-maletin-hoy-zoom.png"))
    crop_zoom(FULL, (330, 770, 1340, 880), 2).save(os.path.join(D, "tienda-deposito-hoy-zoom.png"))


if __name__ == "__main__":
    main()
