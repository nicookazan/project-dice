"""Genera el salón del club detrás de la mesa de juego (pixel-v3).

  assets/art/pixel-v3/salon-v3.png       720×150 px lógicos (se dibuja a 1440×300): pared de tablones como la tienda,
                                         jambas de ventana con filete dorado, dintel y alféizar, boiserie en penumbra,
                                         cuadros, lámparas, aplique, banderín, planta, sillas de café y mesitas de mármol
  assets/art/pixel-v3/parteluces-v3.png  720×150, transparente: parteluces y travesaños de madera sobre el vidrio
                                         (backdrop.gd los dibuja encima del exterior y debajo de la mano y la nube)

Aprobado por el autor como boceto A con parteluces (nov 2026). Las ventanas (panorama animado) no se dibujan acá
ni cambian de lugar: WIN repite los rectángulos de WINDOWS de scripts/backdrop.gd en px lógicos.
Ejecutar:  py -3.13 tools/art/make_salon.py   (trabaja en la raíz del proyecto). Requiere Pillow, numpy y scipy.
"""
from __future__ import annotations

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_lib import Canvas, GOLD, SILVER, COPPER, WALL, BEAM, SHADE, LEAF, IVORY, PANEL, ramp, hash2, upscale
import texturas

W, H = 720, 150
OUT = "assets/art/pixel-v3/"
PREVIEW = "test-results/"
# ventanas en px lógicos (x0, y0, x1, y1), redondeadas hacia afuera
WIN = [(235, 0, 259, 109), (267, 0, 456, 110), (476, 0, 522, 108), (599, 21, 636, 110)]
SILL_Y = 110
LAMPS = [(560, 44, 14), (210, 40, 12)]
BENT = ramp("2a1208", "6a3414", "9a5422", "c47a34")
MARBLE = ramp("6a6458", "9a9284", "c4bcac", "e2dccc", "f6f2e6")
GLASS = ramp("0e2a2a", "1a4a46", "2c6e66", "5aa094", "a8e0d0")
WINE = (150, 30, 50)


def halo(x: int, y: int) -> int:
    b = 0
    for lx, ly, s in LAMPS:
        d = ((x - lx) ** 2 + ((y - ly) * 1.25) ** 2) ** 0.5
        r = s * 2.6
        if d < r * 0.5:
            b = max(b, 2)
        elif d < r:
            b = max(b, 1)
        elif d < r * 1.3 and (x + y) % 2 == 0:
            b = max(b, 1)
    return b


def casing(cv: Canvas, x0: int, y0: int, x1: int, y1: int) -> None:
    """Jamba de madera de 5 px con bisel y filete dorado junto al vidrio; dintel con cornisa y alféizar profundo."""
    cw = 5
    for side in (0, 1):
        xs = x0 - cw if side == 0 else x1
        for y in range(y0 - (cw if y0 > 0 else 0), y1 + 1):
            for k in range(cw):
                i = k if side == 0 else cw - 1 - k  # 0 afuera, cw-1 junto al vidrio
                c = (BEAM[0], BEAM[3], BEAM[2], BEAM[1], GOLD[2])[i]
                if i == 4 and side == 1:
                    c = GOLD[1]
                if side == 1 and i == 1:
                    c = BEAM[1]
                if i in (2, 3) and hash2(xs + k, y // 5, 2) > 0.85:
                    c = BEAM[1]
                cv.put(xs + k, y, c)
    if y0 > 0:
        for x in range(x0 - cw, x1 + cw):
            for k, c in enumerate((BEAM[0], BEAM[3], BEAM[2], BEAM[1], GOLD[3])):
                cv.put(x, y0 - cw + k, c)
        for x in range(x0 - cw - 2, x1 + cw + 2):
            cv.put(x, y0 - cw - 2, WALL[4])
            cv.put(x, y0 - cw - 1, BEAM[0])
    for x in range(x0 - cw - 3, x1 + cw + 3):
        cv.put(x, y1, GOLD[3] if x0 <= x < x1 else WALL[4])
        cv.put(x, y1 + 1, PANEL[5])
        cv.put(x, y1 + 2, PANEL[4])
        cv.put(x, y1 + 3, PANEL[1])
        cv.put(x, y1 + 4, PANEL[0])
    for x in range(x0 - cw - 1, x1 + cw + 1):
        cv.put(x, y1 + 5, BEAM[0])


def lamp(cv: Canvas, cx: int, cy: int, s: int) -> None:
    """Lámpara colgante: cable doble, florón dorado y pantalla con luz arriba-izquierda."""
    cv.vline(cx, 0, cy - s // 2, BEAM[1])
    cv.vline(cx + 1, 0, cy - s // 2, BEAM[0])
    n = int(s * 0.9)
    for i in range(n):
        y = cy - int(s * 0.45) + i
        half = int(s * 0.35 + (s - s * 0.35) * i / (s * 0.9))
        for x in range(cx - half, cx + half + 1):
            u = (x - cx) / max(half, 1)
            idx = 3 if u < -0.35 else (4 if u < 0.1 else (3 if u < 0.5 else 2))
            if i >= n - 2:
                idx = 4
            cv.put(x, y, SHADE[idx])
        cv.put(cx - half - 1, y, SHADE[0])
        cv.put(cx + half + 1, y, SHADE[0])
    cv.hline(cx - s - 1, cx + s + 1, cy + int(s * 0.45), SHADE[0])
    cv.hline(cx - 3, cx + 3, cy + int(s * 0.45) + 1, SHADE[4])
    cv.rect(cx - 2, cy - s // 2 - 2, 5, 3, GOLD[2])
    cv.hline(cx - 2, cx + 2, cy - s // 2 - 2, GOLD[4])


def sconce(cv: Canvas, cx: int, cy: int) -> None:
    """Aplique de pared: brazo dorado y tulipa."""
    cv.rect(cx - 2, cy + 4, 5, 6, GOLD[1])
    cv.rect(cx - 1, cy + 5, 2, 4, GOLD[3])
    cv.vline(cx, cy, cy + 4, GOLD[2])
    for i in range(6):
        half = 1 + i // 2
        for x in range(cx - half, cx + half + 1):
            cv.put(x, cy - 6 + i, SHADE[3] if x < cx else SHADE[2])
    cv.hline(cx - 4, cx + 4, cy, SHADE[4])


def bentwood(cv: Canvas, cx: int, base: int) -> None:
    """Silla de café de madera curvada: respaldo en óvalo, asiento redondo, patas abiertas con aro."""
    D, M, L, HI = BENT
    ocy, orx, ory = base - 26, 6.5, 7.5
    for y in range(int(ocy - ory - 1), int(ocy + ory + 2)):
        for x in range(int(cx - orx - 1), int(cx + orx + 2)):
            e = ((x + 0.5 - cx) / orx) ** 2 + ((y + 0.5 - ocy) / ory) ** 2
            ei = ((x + 0.5 - cx) / (orx - 2.2)) ** 2 + ((y + 0.5 - ocy) / (ory - 2.2)) ** 2
            if e <= 1.0 and ei > 1.0:
                c = HI if (x < cx and y < ocy) else (L if x < cx else M)
                if e > 0.8 and x >= cx:
                    c = D
                cv.put(x, y, c)
    for x in range(int(cx - 3), int(cx + 4)):
        cv.put(x, int(ocy + 2 + abs(x - cx) * -0.3), L if x < cx else M)
    for y in range(int(ocy + ory - 1), base - 14):
        cv.put(cx - 5, y, L)
        cv.put(cx - 4, y, M)
        cv.put(cx + 4, y, M)
        cv.put(cx + 5, y, D)
    for y in range(base - 16, base - 11):
        for x in range(cx - 9, cx + 10):
            if ((x + 0.5 - cx) / 9) ** 2 + ((y + 0.5 - (base - 13.5)) / 2.6) ** 2 <= 1.0:
                cv.put(x, y, HI if y < base - 14 and x < cx + 3 else (L if y < base - 13 else D))
    for k, (x0, x1) in enumerate(((cx - 6, cx - 8), (cx - 2, cx - 3), (cx + 2, cx + 3), (cx + 6, cx + 8))):
        for y in range(base - 11, base):
            t = (y - (base - 11)) / 11
            cv.put(round(x0 + (x1 - x0) * t), y, M if k < 2 else D)
    for x in range(cx - 7, cx + 8):
        cv.put(x, base - 5, M)


def cafe_table(cv: Canvas, cx: int, top: int, items: str) -> None:
    """Mesa redonda de mármol con pie de hierro; encima un sifón con un vaso o dos copas de vino."""
    for y in range(top - 3, top + 3):
        for x in range(cx - 15, cx + 16):
            if ((x + 0.5 - cx) / 15) ** 2 + ((y + 0.5 - top) / 3.2) ** 2 <= 1.0:
                c = MARBLE[3] if y < top else (MARBLE[2] if y == top else MARBLE[1])
                if y < top - 1 and x < cx - 4:
                    c = MARBLE[4]
                if hash2(x // 3, y, 12) > 0.86 and y < top + 1:
                    c = MARBLE[2]
                cv.put(x, y, c)
    cv.hline(cx - 14, cx + 14, top + 3, MARBLE[0])
    cv.rect(cx - 1, top + 4, 3, 14, BEAM[1])
    cv.put(cx - 1, top + 4, BEAM[3])
    if items == "sifon":
        bx = cx - 6
        cv.rect(bx - 2, top - 14, 6, 11, GLASS[2])
        cv.vline(bx - 1, top - 13, top - 4, GLASS[4])
        cv.vline(bx + 3, top - 14, top - 4, GLASS[1])
        for y in range(top - 12, top - 4, 3):
            cv.hline(bx - 2, bx + 3, y, GLASS[3])
        cv.rect(bx - 1, top - 19, 4, 5, SILVER[3])
        cv.vline(bx - 1, top - 19, top - 15, SILVER[5])
        cv.hline(bx + 2, bx + 5, top - 18, SILVER[2])
        cv.put(bx + 5, top - 17, SILVER[2])
        cv.hline(bx - 2, bx + 3, top - 3, GLASS[0])
        cv.rect(cx + 4, top - 7, 4, 5, IVORY[2])
        cv.vline(cx + 4, top - 7, top - 3, IVORY[4])
        cv.rect(cx + 5, top - 5, 3, 2, SHADE[1])
    else:
        for gx in (cx - 6, cx + 3):
            cv.rect(gx, top - 10, 5, 3, IVORY[3])
            cv.rect(gx + 1, top - 9, 3, 2, WINE)
            cv.vline(gx + 2, top - 7, top - 3, IVORY[2])
            cv.hline(gx + 1, gx + 3, top - 3, IVORY[1])
            cv.put(gx, top - 10, IVORY[4])


def plant(cv: Canvas, x: int, base: int) -> None:
    cv.rect(x - 12, base - 14, 26, 14, COPPER[2])
    cv.rect(x - 12, base - 14, 26, 2, COPPER[3])
    cv.rect(x - 12, base - 2, 26, 2, COPPER[0])
    cv.rect(x - 14, base - 18, 30, 4, COPPER[1])
    for k in range(9):
        ang = -1.25 + 2.5 * k / 8
        ln = 30 + (k % 3) * 7
        for t in range(ln):
            px = x + math.sin(ang) * t * 0.9
            py = base - 18 - math.cos(ang) * t * 0.8 + t * t * 0.004 * abs(math.sin(ang))
            th = 2 if t < ln * 0.7 else 1
            for q in range(-th, th + 1):
                cv.put(round(px) + q, round(py), LEAF[3 if q < 0 else (2 if q == 0 else 1)])


def salon() -> Canvas:
    cv = Canvas(W, H, fill=WALL[2])
    # tablones como la tienda (texturas.planks) y boiserie en penumbra bajo los alféizares
    texturas.planks(cv, 0, SILL_Y + 4, W, halo)
    texturas.wainscot(cv, SILL_Y + 4, H + 6, W, lambda x, y: -1)
    for w in WIN:
        casing(cv, *w)
    texturas.cuadro(cv, 180, 18, 28, 36, "building")
    texturas.cuadro(cv, 547, 60, 26, 32, "portrait")
    texturas.cuadro(cv, 698, 16, 28, 40, "dancers")
    for lx, ly, s in LAMPS:
        lamp(cv, lx, ly, s)
    sconce(cv, 466, 46)
    texturas.bandera(cv, 652, 30)
    # sillas de café y mesitas de mármol al fondo (la mesa de juego tapa las patas)
    for x in (176, 224, 282, 330, 392, 440, 512, 560, 604, 690):
        bentwood(cv, x, 147)
    for x, items in ((200, "sifon"), (306, "copas"), (416, "sifon"), (536, "copas"), (650, "sifon")):
        cafe_table(cv, x, 131, items)
    plant(cv, 706, 144)
    return cv


def parteluces() -> Canvas:
    """Parteluces y travesaños de 3 px (luz a la izquierda y arriba): el ventanal en cuatro hojas con banderola."""
    cv = Canvas(W, H)

    def vbar(x: int, y0: int, y1: int) -> None:
        for y in range(y0, y1):
            cv.put(x, y, BEAM[3])
            cv.put(x + 1, y, BEAM[2])
            cv.put(x + 2, y, BEAM[0])

    def hbar(x0: int, x1: int, y: int) -> None:
        for x in range(x0, x1):
            cv.put(x, y, BEAM[3])
            cv.put(x, y + 1, BEAM[2])
            cv.put(x, y + 2, BEAM[0])

    for x in (313, 360, 407):
        vbar(x, 0, 110)
    hbar(267, 456, 22)
    hbar(476, 522, 22)
    vbar(498, 0, 108)
    hbar(235, 259, 22)
    hbar(599, 636, 46)
    return cv


def main() -> None:
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    os.makedirs(PREVIEW, exist_ok=True)
    room, bars = salon(), parteluces()
    room.save(OUT + "salon-v3.png")
    bars.save(OUT + "parteluces-v3.png")
    preview = room.image()
    preview.alpha_composite(bars.image())
    upscale(preview, 2).save(PREVIEW + "salon-v3-preview.png")
    print("ok salon", W, "x", H, "colores:", len(room.image().convert("RGB").getcolors(1 << 20)))


if __name__ == "__main__":
    main()
