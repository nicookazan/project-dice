"""Boceto (08/11/2026): la tienda sobre la misma mesa de juego, sin vendedor ni maletín.

Parte de capturas reales: la mesa limpia (capture_mesa.gd) y la tienda con y sin ofertas / inventario
(tools/art/bocetos-jefes/capture_tienda.gd). Cada objeto se recorta por diferencia entre capturas y se apoya en el paño
con su sombra; etiquetas, flechas de renovar y textos se dibujan en px lógicos (2×2 de pantalla).
Uso: py -3.13 tools/art/bocetos-tienda-mesa/tienda_mesa.py
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as nd

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
ART = os.path.join(ROOT, "assets", "art", "pixel-v3")
SHOP = os.path.join(ROOT, "test-results", "bocetos-arte-2")
OUT = os.path.join(ROOT, "test-results", "bocetos-tienda-mesa")

MESA = Image.open(os.path.join(OUT, "mesa.png")).convert("RGBA")
CLEAN = Image.open(os.path.join(OUT, "mesa-limpia-vaso.png")).convert("RGBA")
FULL = Image.open(os.path.join(SHOP, "tienda-completa.png")).convert("RGBA")
NO_OFFERS = Image.open(os.path.join(SHOP, "tienda-sin-ofertas.png")).convert("RGBA")
NO_INV = Image.open(os.path.join(SHOP, "tienda-sin-inventario.png")).convert("RGBA")


def bahn(size, weight="Bold"):
    f = ImageFont.truetype("bahnschrift.ttf", size)
    f.set_variation_by_name(weight)
    return f


INK = "#423d38"
TAG_INK = "#3a2416"
GOLD = ["#2e1508", "#5c300c", "#96601a", "#c98f24", "#ecbc42", "#ffe07a", "#fff8c8"]


# ------------------------------------------------------------------ recortes
def cut(full, clean, box, thr=12):
    """Devuelve (sprite RGBA recortado al objeto, desplazamiento dentro de la caja)."""
    x, y, w, h = box
    a = np.array(full)[y:y + h, x:x + w]
    b = np.array(clean)[y:y + h, x:x + w]
    m = np.abs(a[..., :3].astype(int) - b[..., :3].astype(int)).sum(-1) > thr
    m = nd.binary_fill_holes(nd.binary_closing(m, iterations=2))
    lab, n = nd.label(m)
    if n > 1:
        sizes = nd.sum(m, lab, range(1, n + 1))
        m = lab == (int(np.argmax(sizes)) + 1)
    ys, xs = np.nonzero(m)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    out = a[y0:y1, x0:x1].copy()
    out[..., 3] = np.where(m[y0:y1, x0:x1], 255, 0)
    return Image.fromarray(out)


OFFERS = {
    "numero_a": (593, 292, 86, 86), "numero_b": (765, 292, 86, 86),
    "componente_a": (990, 292, 85, 86), "componente_b": (1172, 292, 85, 86),
    "moneda_a": (622, 477, 90, 97), "moneda_b": (712, 477, 90, 97), "moneda_c": (802, 477, 95, 97),
    "sticker": (982, 477, 106, 97), "paquete": (1183, 478, 82, 94),
}
SPR = {k: cut(FULL, NO_OFFERS, b) for k, b in OFFERS.items()}
DICE = [cut(FULL, NO_INV, (360 + 72 * i, 810, 50, 50)) for i in range(5)]
COINS = [cut(FULL, NO_INV, (787 + 78 * i, 808, 58, 58)) for i in range(3)]
CONSUMABLE = cut(FULL, NO_INV, (1265, 810, 52, 52))


# ------------------------------------------------------------------ dibujo
def even(v):
    return int(v) // 2 * 2


def shadow_of(spr, dx=4, dy=6, k=0.42):
    """Sombra del objeto sobre el paño (en bloques de 2 px)."""
    a = np.array(spr)[..., 3] > 0
    return a, dx, dy, k


def put(img, spr, cx, cy, shadow=True):
    """Apoya `spr` centrado en (cx, cy), con sombra corrida abajo a la derecha."""
    x, y = even(cx - spr.width / 2), even(cy - spr.height / 2)
    if shadow:
        arr = np.array(img).astype(float)
        m = np.array(spr)[..., 3] > 0
        sx, sy = x + 4, y + 6
        sub = arr[sy:sy + m.shape[0], sx:sx + m.shape[1]]
        sub[m[:sub.shape[0], :sub.shape[1]], :3] *= 0.58
        img.paste(Image.fromarray(arr.astype(np.uint8)))
    img.alpha_composite(spr, (x, y))
    return x, y


def tag(img, cx, ty, text, w=24, sold=False):
    """Etiqueta de papel de la tienda (misma forma que la del maletín), en px lógicos ×2."""
    L = Image.new("RGBA", (w + 2, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(L)
    paper, edge, light = ("#f2e6c0", "#c9b48a", "#fff8e0") if not sold else ("#e6d2b0", "#b49a72", "#f6ead0")
    d.polygon([(3, 0), (w - 3, 0), (w, 3), (w, 11), (0, 11), (0, 3)], fill=paper)
    d.rectangle((1, 10, w - 1, 11), fill=edge)
    d.rectangle((1, 3, 1, 9), fill=light)
    big = L.resize((L.width * 2, L.height * 2), Image.NEAREST)
    x = even(cx - w)
    # sombra
    sh = Image.new("RGBA", big.size, (0, 0, 0, 0))
    sh.putalpha(Image.fromarray((np.array(big)[..., 3] > 0).astype(np.uint8) * 90))
    img.alpha_composite(sh, (x + 2, ty + 4))
    img.alpha_composite(big, (x, ty))
    dr = ImageDraw.Draw(img)
    dr.fontmode = "1"
    f = ImageFont.truetype("consolab.ttf", 13 if sold else 17)
    color = "#8a2416" if sold else TAG_INK
    l, t, r, b = dr.textbbox((0, 0), text, font=f)
    dr.text((x + w - (r - l) / 2 - l, ty + 11 - (b - t) / 2 - t), text, fill=color, font=f)


def renew_arrow(img, cx, cy):
    """Flecha circular de renovar, dorada, en px lógicos (12×12)."""
    L = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(L)
    d.arc((1, 1, 12, 12), 40, 320, fill=GOLD[1], width=3)
    d.arc((1, 1, 12, 12), 40, 320, fill=GOLD[4], width=2)
    d.polygon([(9, 0), (13, 4), (8, 5)], fill=GOLD[5])
    d.point((9, 1), fill=GOLD[6])
    big = L.resize((28, 28), Image.NEAREST)
    sh = Image.new("RGBA", big.size, (0, 0, 0, 0))
    sh.putalpha(Image.fromarray((np.array(big)[..., 3] > 0).astype(np.uint8) * 80))
    x, y = even(cx - 14), even(cy - 14)
    img.alpha_composite(sh, (x + 2, y + 4))
    img.alpha_composite(big, (x, y))


def text(img, s, x, y, font, color=INK, anchor="la"):
    d = ImageDraw.Draw(img)
    d.text((x, y), s, fill=color, font=font, anchor=anchor)


def button(img, src_box, dst_box, label, font, color="#e6e2d8"):
    """Toma un botón real de la mesa, borra su texto y escribe otro."""
    sx, sy, sw, sh = src_box
    b = MESA.crop((sx, sy, sx + sw, sy + sh))
    a = np.array(b)
    fill = a[a.shape[0] // 2, 10].copy()
    a[7:-7, 7:-7] = fill
    b = Image.fromarray(a)
    w, h = dst_box[2], dst_box[3]
    if (w, h) != b.size:
        # estira solo el medio: conserva bordes y esquinas
        mid = b.crop((12, 0, 13, h)).resize((w - 24, h), Image.NEAREST)
        nb = Image.new("RGBA", (w, h))
        nb.paste(b.crop((0, 0, 12, h)), (0, 0)); nb.paste(mid, (12, 0)); nb.paste(b.crop((b.width - 12, 0, b.width, h)), (w - 12, 0))
        b = nb
    img.alpha_composite(b, dst_box[:2])
    arrow = label.endswith(" →")
    label = label.removesuffix(" →")
    aw = 22 if arrow else 0
    text(img, label, dst_box[0] + w / 2 - aw / 2, dst_box[1] + h / 2 + 1, font, color, "mm")
    if arrow:
        lw = ImageDraw.Draw(img).textlength(label, font=font)
        text(img, "→", dst_box[0] + w / 2 - aw / 2 + lw / 2 + 6, dst_box[1] + h / 2 + 1, ImageFont.truetype("seguisb.ttf", 17), color, "lm")


def restore_windows(img):
    """Quita la nube y la mano del rival: en la tienda no hay rival. Se redibuja salón, ventanas y parteluces."""
    salon = Image.open(os.path.join(ART, "salon-v3.png")).convert("RGBA").resize((1440, 300), Image.NEAREST)
    ext = Image.open(os.path.join(ART, "exteriores-v3.png")).convert("RGBA")
    mull = Image.open(os.path.join(ART, "parteluces-v3.png")).convert("RGBA").resize((1440, 300), Image.NEAREST)
    cw, ch = ext.width // 2, ext.height // 3
    pano = ext.crop((0, 0, cw, ch)).resize((cw * 2, ch * 2), Image.NEAREST)  # panel "dia"
    top = salon.copy()
    for wx, wy, ww, wh in [(470, 0, 47, 217), (534, 0, 378, 219), (952, 0, 92, 215), (1198, 43, 73, 177)]:
        top.paste(pano.crop((wx - 470, wy, wx - 470 + ww, wy + wh)), (wx, wy))
    top.alpha_composite(mull)
    region = (540, 0, 830, 150)
    img.paste(top.crop(region), region[:2])


# ------------------------------------------------------------------ escena
def tienda_en_mesa():
    img = CLEAN.copy()
    restore_windows(img)

    # Libreta de la tienda: plata, capacidad, recorrido y tus dados.
    text(img, "TIENDA", 50, 40, bahn(22))
    text(img, "PLATA", 50, 75, bahn(13, "SemiBold"))
    text(img, "$24", 50, 92, bahn(33))
    text(img, "Capacidad", 50, 141, bahn(17, "SemiBold"))
    text(img, "5", 246, 139, bahn(21))
    text(img, "Nivel 1 · Rival 1 / 3 superado", 50, 203, bahn(13, "SemiBold"))
    text(img, "Siguiente: Rival 2 / 3", 50, 226, bahn(15, "SemiBold"))
    text(img, "TUS DADOS", 50, 330, bahn(17))
    for i, d in enumerate(DICE):
        put(img, d, 70 + 54 * i, 390, shadow=False)

    # Paño 1: monedas (cuatro espacios; el primero ya vendido).
    row = [(450, 410), (600, 410), (450, 560), (600, 560)]
    tag(img, row[0][0], row[0][1] - 4, "VENDIDO", w=36, sold=True)
    for (cx, cy), key in zip(row[1:], ["moneda_a", "moneda_b", "moneda_c"]):
        put(img, SPR[key], cx, cy)
        tag(img, cx + 34, cy + 30, "$2")
    renew_arrow(img, 628, 352)

    # Paño 2: componentes arriba, números al medio, stickers abajo; cada fila con su flecha de renovar.
    rows = [(380, ["componente_a", "componente_b"], ["$4", "$5"]),
            (492, ["numero_a", "numero_b"], ["$3", "$3"]),
            (602, ["sticker", "paquete"], ["$4", "$7"])]
    for cy, keys, prices in rows:
        for cx, key, price in zip([800, 945], keys, prices):
            s = SPR[key]
            put(img, s, cx, cy)
            tag(img, cx + s.width // 2 - 6, cy + s.height // 2 - 22, price)
        renew_arrow(img, 1012 + (cy - 380) // 12, cy - 20)

    # Botonera: la de la mesa, con salir de la tienda en el lugar de TIRAR.
    button(img, (934, 681, 137, 47), (934, 681, 137, 47), "Inspeccionar", bahn(17, "SemiBold"), "#a8a49a")
    button(img, (1082, 681, 312, 47), (1082, 681, 312, 47), "Ir al siguiente rival →", bahn(17, "SemiBold"))
    img.alpha_composite(MESA.crop((1220, 23, 1405, 61)), (1220, 23))      # Menú
    img.alpha_composite(MESA.crop((1273, 748, 1393, 808)), (1273, 748))   # Ayuda
    img.alpha_composite(MESA.crop((918, 748, 972, 768)), (918, 748))      # UN USO

    # Barra: tus monedas como en la partida.
    text(img, "3/5", 42, 750, bahn(13, "SemiBold"), "#e8c060")
    for i, c in enumerate(COINS):
        put(img, c, 200 + 100 * i, 787, shadow=False)
    put(img, CONSUMABLE, 1030, 787, shadow=False)
    return img


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    im = tienda_en_mesa()
    im.save(os.path.join(OUT, "tienda-en-mesa.png"))
    print("ok", im.size)
