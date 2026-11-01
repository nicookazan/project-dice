"""Genera el arte pixel-v3 de la tienda (Fase 5).

  assets/art/pixel-v3/tienda-v3.png         escena completa 720×450 px lógicos (se dibuja a 1440×900):
                                            salón del club, vendedor (vendedor.py) y maletín (maletin.py)
  assets/art/pixel-v3/tienda-iconos-v3.png  íconos de ofertas que no son dados ni monedas (medallón, sobre)
  assets/art/pixel-v3/terciopelo-v3.png     baldosa del terciopelo del maletín para descripciones y paneles

Ejecutar:  python tools/art/make_tienda.py   (desde cualquier carpeta; trabaja en la raíz del proyecto)
Requiere Python 3.13 con Pillow, numpy y scipy. Las vistas ampliadas para revisar caen en test-results/.
El vendedor y el maletín respetan el dibujo de assets/art/shop-salesman-v1.png; las zonas de ofertas
de main.gd (render_shop) calzan en los compartimentos.
"""
from __future__ import annotations

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_lib import (Canvas, OUTLINE, GOLD, WALL, BEAM, CHAIR, SHADE, LEAF, FRAME, FRAME_DK, PAPER, COPPER, NAVY,
                       PANO, hash2, upscale)
import maletin
import texturas
import vendedor

W, H = 720, 450
OUT = "assets/art/pixel-v3/"
PREVIEW = "test-results/"

LAMPS = [(74, 84, 17, True), (350, 66, 14, True), (16, 150, 7, False)]


# ---------- salón
def halo(x: int, y: int) -> int:
    boost = 0
    for lx, ly, s, _ in LAMPS:
        d = ((x - lx) ** 2 + ((y - ly) * 1.25) ** 2) ** 0.5
        r = s * 2.4
        if d < r * 0.5:
            boost = max(boost, 2)
        elif d < r:
            boost = max(boost, 1)
        elif d < r * 1.3 and (x + y) % 2 == 0:
            boost = max(boost, 1)
    return boost


def wall(cv: Canvas) -> None:
    # tablones con friso bordó, picture rail dorado y zócalo de boiserie (ver texturas.py)
    texturas.planks(cv, 44, 238, W, halo)
    texturas.friso(cv, 238, W)
    texturas.rail(cv, 250, W)
    texturas.wainscot(cv, 256, 386, W, halo)
    # banda superior: viga azul oscura con moldura (zona tranquila para la interfaz)
    for y in range(0, 44):
        for x in range(W):
            if y < 37:
                c = NAVY[0] if (y % 12 != 6 or hash2(x // 40, y, 3) < 0.5) else NAVY[1]
            else:
                c = (BEAM[3], BEAM[2], BEAM[1], BEAM[1], BEAM[2], BEAM[0], BEAM[0])[y - 37]
            cv.put(x, y, c)


def lamp(cv: Canvas, cx: int, cy: int, s: int, hanging: bool) -> None:
    if hanging:
        cv.vline(cx, 37, cy - s // 2, BEAM[1])
        hw = s
        n = int(s * 0.9)
        for i in range(n):
            y = cy - int(s * 0.45) + i
            half = int(s * 0.35 + (hw - s * 0.35) * i / (s * 0.9))
            for x in range(cx - half, cx + half + 1):
                u = (x - cx) / max(half, 1)
                idx = 3 if u < -0.35 else (4 if u < 0.1 else (3 if u < 0.5 else 2))
                if i >= n - 2:
                    idx = 4
                cv.put(x, y, SHADE[idx])
            cv.put(cx - half - 1, y, SHADE[0])
            cv.put(cx + half + 1, y, SHADE[0])
        cv.hline(cx - hw - 1, cx + hw + 1, cy + int(s * 0.45), SHADE[0])
        cv.rect(cx - 2, cy - s // 2 - 2, 5, 3, BEAM[2])
    else:
        cv.rect(cx - 1, cy + 3, 2, 22, BEAM[1])
        cv.rect(cx - 4, cy + 24, 9, 2, BEAM[2])
        for i in range(7):
            half = 2 + i // 2
            for x in range(cx - half, cx + half + 1):
                cv.put(x, cy - 3 + i, SHADE[3] if x < cx else SHADE[2])
            cv.put(cx - half - 1, cy - 3 + i, SHADE[0])
            cv.put(cx + half + 1, cy - 3 + i, SHADE[0])
        cv.hline(cx - 6, cx + 6, cy + 4, SHADE[4])


def picture(cv: Canvas, x: int, y: int, w: int, h: int, kind: str) -> None:
    texturas.cuadro(cv, x, y, w, h, kind)


def pennant(cv: Canvas, x: int, y: int) -> None:
    texturas.bandera(cv, x, y)


def plant(cv: Canvas, x: int, base: int) -> None:
    import math
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


def chair(cv: Canvas, x: int, base: int, scale: int) -> None:
    w, h = 14 * scale, 17 * scale
    top = base - h
    for j in range(h):
        for i in range(w):
            c = None
            post = i < 4 or i >= w - 4
            if post:
                c = CHAIR[3] if i == 1 else (CHAIR[2] if 1 < i < 4 else (CHAIR[1] if i in (w - 4, w - 3) else CHAIR[0]))
            elif j < 4:
                c = CHAIR[3] if j == 0 else (CHAIR[2] if j < 3 else CHAIR[0])
            elif j >= h - 5:
                c = CHAIR[2] if j < h - 2 else CHAIR[0]
            elif (i - 4) % 6 < 3:
                c = CHAIR[2] if (i - 4) % 6 == 0 else CHAIR[1]
            if c is not None:
                cv.put(x + i, top + j, c)


def room(cv: Canvas) -> None:
    wall(cv)
    picture(cv, 6, 58, 48, 64, "building")
    picture(cv, 226, 54, 20, 30, "portrait")
    picture(cv, 682, 192, 30, 40, "dancers")
    for lx, ly, s, hanging in LAMPS:
        lamp(cv, lx, ly, s, hanging)
    # mesita de la lámpara chica
    cv.rect(4, 176, 26, 3, WALL[4])
    cv.rect(4, 179, 26, 2, WALL[0])
    pennant(cv, 683, 102)
    plant(cv, 704, 300)
    chair(cv, 684, 384, 3)


# ---------- banda inferior (franja azul de los controles)
def bottom_band(cv: Canvas) -> None:
    for y in range(384, H):
        for x in range(W):
            if y == 384:
                c = OUTLINE
            elif y == 385:
                c = GOLD[3]
            elif y == 386:
                c = GOLD[1]
            elif y < 442:
                continue
            elif y == 442:
                c = GOLD[2]
            else:
                c = (BEAM[2], BEAM[1], BEAM[1], BEAM[0], BEAM[0], BEAM[0], BEAM[0], BEAM[0])[y - 443]
            cv.put(x, y, c)
    # capitoné de rombos entre los dos filetes dorados
    texturas.capitone(cv, 387, 442, W)
    # ménsulas doradas en los extremos (como la mesa)
    for x0, flip in ((3, False), (W - 13, True)):
        for j, row in enumerate(["##########", "#.........", "#.######..", "#.#.......", "#.#.####..",
                                 "#.#.#.....", "#.#.#.....", "#.#.......", "#.#.......", "#.#......."]):
            for i, ch in enumerate(row):
                if ch == "#":
                    cv.put(x0 + (9 - i if flip else i), 390 + j, GOLD[4] if (j == 0 or i == 0) and not flip else GOLD[2])


# ---------- íconos de ofertas (celdas de 44×44 px lógicos; Godot los dibuja a escala entera)
ICON = 44
BLUE_ENAMEL = [(10, 20, 52), (18, 36, 84), (28, 54, 116), (44, 78, 150)]
PAPER_RAMP = [(107, 74, 42), (176, 140, 92), (222, 196, 150), (240, 222, 186), (252, 244, 222)]


def medallion(cv: Canvas, ox: int, oy: int) -> None:
    """Medallón de mejora numérica: esmalte azul con aro dorado (el número lo escribe Godot encima)."""
    r = 20.0
    cx, cy = ox + 22.0, oy + 22.0
    for y in range(oy, oy + ICON):
        for x in range(ox, ox + ICON):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d = (dx * dx + dy * dy) ** 0.5
            if d > r:
                continue
            t = (dx * -0.7 + dy * -0.7) / max(d, 0.001)
            if d > r - 1:
                c = OUTLINE
            elif d > r - 4:
                c = GOLD[5] if t > 0.6 else GOLD[4] if t > 0.1 else GOLD[3] if t > -0.45 else GOLD[2]
            elif d > r - 5:
                c = GOLD[1]
            elif d > r - 6:
                c = BLUE_ENAMEL[0]
            else:
                # esmalte: medialuna clara arriba-izquierda, resto plano
                c = BLUE_ENAMEL[2] if (t > 0.55 and d > r - 10) else BLUE_ENAMEL[1]
                if abs(d - (r - 9.5)) < 0.5:
                    c = GOLD[2] if t > -0.2 else GOLD[1]
            cv.put(x, y, c)


def sticker_pack(cv: Canvas, ox: int, oy: int, angle: float = 13.0) -> None:
    """Sobre de stickers en diagonal (como el original, girado ~13° antihorario): papel crema con bordes
    sellados en zigzag, sello azul al centro. Cada píxel se calcula en el marco del sobre."""
    import math
    from scipy import ndimage
    th = math.radians(angle)
    cs, sn = math.cos(th), math.sin(th)
    cx, cy = ox + 22.0, oy + 22.0
    hw, hh = 14.5, 18.5                      # medio ancho y medio alto del sobre
    star_c = (0.0, 0.5)
    for y in range(oy, oy + ICON):
        for x in range(ox, ox + ICON):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            # de pantalla al marco del sobre (deshace el giro antihorario)
            u = dx * cs - dy * sn
            v = dx * sn + dy * cs
            if abs(u) > hw or abs(v) > hh:
                continue
            edge = hh - abs(v)
            # dientes de sierra en los bordes sellados
            tooth = (u + hw) % 3.0
            if edge < 1.0 and tooth < 1.2:
                continue
            band = edge < 5.0
            t = (u + hw) / (2 * hw)
            c = PAPER_RAMP[3] if t < 0.18 else PAPER_RAMP[2] if t < 0.76 else PAPER_RAMP[1]
            if band:
                c = PAPER_RAMP[2] if tooth >= 1.5 else PAPER_RAMP[1]
                if tooth < 0.75 and t < 0.5:
                    c = PAPER_RAMP[3]
            elif 5.0 <= edge < 6.0:
                c = PAPER_RAMP[1]
            # brillo diagonal del plástico arriba a la izquierda
            if not band and -11.5 < u + (v + 6) * 0.9 < -10.5 and v < -2:
                c = PAPER_RAMP[4]
            # sello: estrella de 12 puntas con borde dorado
            su, sv = u - star_c[0], v - star_c[1]
            d = math.hypot(su, sv)
            rr = 9.5 + 1.6 * math.cos(math.atan2(sv, su) * 12)
            if d <= rr:
                lit = (su * -0.7 + sv * -0.7) / max(d, 0.001)
                c = BLUE_ENAMEL[1] if d < rr - 1.1 else GOLD[3]
                if d < rr - 1.1 and lit > 0.5 and d > 4.5:
                    c = BLUE_ENAMEL[2]
            cv.put(x, y, c)
    # contorno
    solid = cv.a[..., 3] > 0
    box = np.zeros_like(solid)
    box[oy:oy + ICON, ox:ox + ICON] = True
    ring = ndimage.binary_dilation(solid, structure=[[0, 1, 0], [1, 1, 1], [0, 1, 0]]) & ~solid
    cv.fill(ring & box, OUTLINE)


def velvet_tile() -> Canvas:
    """Baldosa de 64×64 del terciopelo del maletín para los recuadros de descripción (se repite sin costuras)."""
    cv = Canvas(64, 64)
    for y in range(64):
        for x in range(64):
            r = hash2(x // 2, y, 21)
            cv.put(x, y, PANO[1] if r < 0.045 else PANO[3] if r > 0.97 else PANO[2])
    return cv


def icons() -> Canvas:
    cv = Canvas(ICON * 2, ICON)
    medallion(cv, 0, 0)
    sticker_pack(cv, ICON, 0)
    return cv


def scene() -> Canvas:
    cv = Canvas(W, H, fill=WALL[2])
    room(cv)
    vendedor.draw(cv, "back")
    maletin.draw(cv)
    vendedor.draw(cv, "front")
    bottom_band(cv)
    return cv


def main() -> None:
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREVIEW, exist_ok=True)
    cv = scene()
    cv.save(OUT + "tienda-v3.png")
    upscale(cv.image(), 2).save(PREVIEW + "tienda-v3-preview.png")
    colors = len(cv.image().convert("RGB").getcolors(1 << 20))
    print("ok tienda", cv.w, "x", cv.h, "colores:", colors)
    ic = icons()
    ic.save(OUT + "tienda-iconos-v3.png")
    upscale(ic.image(), 6).save(PREVIEW + "tienda-iconos-v3-preview.png")
    print("ok iconos", ic.w, "x", ic.h)
    # ya ampliada ×2: Godot la repite 1:1 y cada píxel lógico queda en 2×2
    upscale(velvet_tile().image(), 2).save(OUT + "terciopelo-v3.png")
    print("ok terciopelo 128 x 128")


if __name__ == "__main__":
    main()
