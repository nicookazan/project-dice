"""Texturas más ricas del salón de la tienda, la bandera, los cuadros, el zócalo y el capitoné de la franja azul.

Aprobadas por el autor como bocetos (pared B: tablones con friso bordó). Todo en la grilla lógica
(1 px lógico = 2×2 px de la pantalla), luz arriba-izquierda, rampas de pocos tonos y sin ruido fino.
Las usan make_tienda.py (salón y franja) y, en Godot, make_mesa.gd (franja, portada aparte).
"""
from __future__ import annotations

import math

from pixel_lib import (Canvas, OUTLINE, GOLD, COPPER, LEAF, SHADE, IVORY, WALL, PANO, PANEL, CELESTE, WHITE, SKIN,
                       ramp, hexc, hash2)


def disc(cv: Canvas, cx: float, cy: float, r: float, c) -> None:
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                cv.put(x, y, c)


def ell(cv: Canvas, cx: float, cy: float, rx: float, ry: float, c) -> None:
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                cv.put(x, y, c)


# ---------------------------------------------------------------- pared
def planks(cv: Canvas, y0: int, y1: int, w: int, halo) -> None:
    """Tablones horizontales: tonos alternados por tramo, vetas cortas y algún nudo; la lámpara suma luz."""
    for y in range(y0, y1):
        plank = (y - y0) // 10
        for x in range(w):
            run = 30 + int(hash2(plank, 7) * 50)
            off = int(hash2(plank, 3) * 90)
            rid = (x + off) // run
            r = hash2(rid, plank, 5)
            idx = 2 + (1 if r > 0.7 else (-1 if r < 0.3 else 0))
            k = (y - y0) % 10
            if k == 0:
                idx = 0
            elif k == 1:
                idx = min(4, idx + 1)
            elif hash2(x // 6, y, 8) > 0.9:
                idx -= 1
            if hash2(rid, plank, 9) > 0.92 and abs((x + off) % run - run // 2) < 3 and k in (4, 5, 6):
                idx = 0
            cv.put(x, y, WALL[max(0, min(4, idx + halo(x, y)))])


def friso(cv: Canvas, y0: int, w: int) -> None:
    """Friso de terciopelo bordó (el mismo pelo corto del paño) entre filetes dorados, 12 px."""
    for k in range(12):
        y = y0 + k
        for x in range(w):
            r = hash2(x // 2, y, 21)
            c = PANO[1] if r < 0.05 else PANO[3] if r > 0.96 else PANO[2]
            if k == 0:
                c = GOLD[3]
            elif k == 11:
                c = GOLD[1]
            elif k in (1, 10):
                c = PANO[0]
            elif k in (4, 7) and x % 6 < 4:
                c = GOLD[2]
            elif k == 5 and x % 12 in (4, 5, 6, 7):
                c = GOLD[4]
            cv.put(x, y, c)


def rail(cv: Canvas, y: int, w: int) -> None:
    """Moldura dorada (picture rail) de 6 filas con perlas."""
    for i, c in enumerate((GOLD[5], GOLD[4], GOLD[3], GOLD[2], GOLD[1], GOLD[0])):
        cv.hline(0, w - 1, y + i, c)
    for x in range(0, w, 6):
        cv.put(x, y + 2, GOLD[6])
        cv.put(x + 1, y + 2, GOLD[5])


def wainscot(cv: Canvas, y0: int, y1: int, w: int, halo) -> None:
    """Boiserie: paneles hundidos con filete claro arriba-izquierda y oscuro abajo-derecha, veta vertical suave y zócalo."""
    hh = y1 - y0
    for y in range(y0, y1):
        v = y - y0
        for x in range(w):
            u = (x + 2) % 28
            streak = hash2(x // 3, 5, 3)
            idx = 2 + (1 if streak > 0.72 else 0) - (1 if streak < 0.2 else 0)
            if hash2(x, y // 6, 4) > 0.93:
                idx -= 1
            if 3 <= v < hh - 9 and 2 <= u < 26:
                if u in (2, 3) or v in (3, 4):
                    idx = 4
                elif u in (24, 25) or v in (hh - 11, hh - 10):
                    idx = 0
                elif 5 < u < 24 and 5 < v < hh - 12:
                    idx = max(1, idx - 1)
            if u in (0, 1):
                idx = 0
            cv.put(x, y, PANEL[max(0, min(5, idx + halo(x, y) - (1 if v > hh - 12 else 0)))])
    for y in range(y1 - 8, y1):
        c = PANEL[4] if y == y1 - 8 else PANEL[5] if y == y1 - 7 else PANEL[2] if y < y1 - 2 else PANEL[0]
        cv.hline(0, w - 1, y, c)


# ---------------------------------------------------------------- bandera
def sol_de_mayo(cv: Canvas, cx: float, cy: float, r: float) -> None:
    """32 rayos (rectos y ondulados alternados), disco dorado con luz arriba-izquierda y cara."""
    for k in range(32):
        a = k * math.tau / 32
        straight = k % 2 == 0
        L = r + (r * 0.95 if straight else r * 0.8)
        for t in range(int(r * 0.9), int(L) + 1):
            wob = 0 if straight else math.sin(t * 1.2) * 0.9
            px = cx + math.cos(a) * t - math.sin(a) * wob
            py = cy + math.sin(a) * t + math.cos(a) * wob
            cv.put(round(px), round(py), GOLD[3] if straight else GOLD[4])
    disc(cv, cx, cy, r, GOLD[4])
    disc(cv, cx - 0.6, cy - 0.6, r - 1.5, GOLD[5])
    for y in range(int(cy - r), int(cy + r) + 1):
        for x in range(int(cx - r), int(cx + r) + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r and (x - cx) + (y - cy) > r * 0.7:
                cv.put(x, y, GOLD[2])
    cv.put(round(cx - 2), round(cy - 1), COPPER[0])
    cv.put(round(cx + 2), round(cy - 1), COPPER[0])
    cv.put(round(cx), round(cy + 1), COPPER[2])
    cv.hline(round(cx - 1), round(cx + 1), round(cy + 3), COPPER[1])


def bandera(cv: Canvas, x0: int, top: int) -> None:
    """Banderín argentino 34×62 con punta en V: pliegues suaves, Sol de Mayo en el centro de la franja blanca,
    varilla con remates y una borla corta (no pisa el cuadro de abajo)."""
    bw, body, tip = 34, 62, 18
    for x in range(x0 - 1, x0 + bw + 1):
        cv.put(x, top - 3, GOLD[5])
        cv.put(x, top - 2, GOLD[4])
        cv.put(x, top - 1, GOLD[2])
    for ex in (x0 - 2, x0 + bw + 1):
        disc(cv, ex, top - 2, 2.0, GOLD[4])
        cv.put(ex - 1, top - 3, GOLD[6])
    for y in range(top, top + body + tip):
        k = max(0, y - (top + body))
        for x in range(x0 + k, x0 + bw - k):
            u = x - x0
            f = math.sin((u + y * 0.07) * 0.55) * 0.5 + 0.5
            if 11 <= u < 23:
                c = WHITE[3] if f > 0.5 else WHITE[2]
                if f > 0.9:
                    c = WHITE[4]
                if f < 0.12:
                    c = WHITE[1]
            else:
                c = CELESTE[2] if f > 0.5 else CELESTE[1]
                if f > 0.9:
                    c = CELESTE[3]
                if f < 0.12:
                    c = CELESTE[0]
            if u in (0, bw - 1):
                c = CELESTE[0]
            cv.put(x, y, c)
    for x in range(x0, x0 + bw):
        cv.put(x, top, CELESTE[0])
        cv.put(x, top + 1, CELESTE[1] if not 11 <= x - x0 < 23 else WHITE[1])
    for k in range(tip):
        cv.put(x0 + k, top + body + k, CELESTE[0])
        cv.put(x0 + bw - 1 - k, top + body + k, CELESTE[0])
    sol_de_mayo(cv, x0 + 17, top + 30, 6)
    cx = x0 + 16
    cv.put(cx, top + body + tip, GOLD[4])
    cv.put(cx + 1, top + body + tip, GOLD[5])
    cv.put(cx, top + body + tip + 1, GOLD[3])
    cv.put(cx + 1, top + body + tip + 1, GOLD[2])
    disc(cv, cx + 0.5, top + body + tip + 3, 1.6, GOLD[4])


# ---------------------------------------------------------------- cuadros
def marco(cv: Canvas, x: int, y: int, w: int, h: int) -> tuple[int, int, int, int]:
    """Moldura dorada de 3 px con bisel (claro arriba-izquierda, oscuro abajo-derecha) y esquineros; devuelve el interior."""
    cv.rect(x, y, w, h, OUTLINE)
    for j in range(1, h - 1):
        for i in range(1, w - 1):
            edge = min(i, j, w - 1 - i, h - 1 - j)
            if edge > 3:
                continue
            if edge == 1:
                c = GOLD[5] if (i == 1 or j == 1) else GOLD[2]
            elif edge == 2:
                c = GOLD[4] if (i + j) % 2 == 0 else GOLD[3]
            else:
                c = GOLD[1]
            cv.put(x + i, y + j, c)
    for cx, cy in ((x + 1, y + 1), (x + w - 3, y + 1), (x + 1, y + h - 3), (x + w - 3, y + h - 3)):
        cv.rect(cx, cy, 2, 2, GOLD[6])
        cv.put(cx + 1, cy + 1, GOLD[3])
    cv.rect(x + 4, y + 4, w - 8, h - 8, COPPER[0])
    return x + 5, y + 5, w - 10, h - 10


def degrade(cv: Canvas, x: int, y: int, w: int, h: int, rp) -> None:
    n = len(rp)
    for j in range(h):
        t = j / max(1, h - 1) * (n - 1)
        i = int(t)
        frac = t - i
        for k in range(w):
            up = 1 if (frac > 0.5 and (k + j) % 2 == 0) or frac > 0.75 else 0
            cv.put(x + k, y + j, rp[min(n - 1, i + up)])


def escena_obelisco(iw: int, ih: int) -> Canvas:
    cv = Canvas(iw, ih, hexc("1a1840"))
    degrade(cv, 0, 0, iw, ih, ramp("1a1840", "3a2a6a", "7a3a78", "c8607a", "f09a6a", "ffd28a"))
    for sx, sy in ((3, 3), (11, 6), (26, 4), (31, 9), (19, 2)):
        if sx < iw:
            cv.put(sx, sy, IVORY[4])
    base = ih - 8
    for k, (fx, bh) in enumerate(((0.0, 14), (0.14, 20), (0.31, 11), (0.74, 12), (0.86, 19), (0.96, 13))):
        bx = int(fx * iw)
        cv.rect(bx, base - bh, min(5, iw - bx), bh, hexc("1a1424") if k % 2 else hexc("241a34"))
        for wy in range(base - bh + 2, base - 2, 3):
            if hash2(bx, wy, 2) > 0.5:
                cv.put(bx + 1, wy, SHADE[3])
                cv.put(bx + 3, wy, SHADE[2])
    cv.rect(0, base, iw, 8, hexc("241a30"))
    for k in range(0, iw, 6):
        cv.rect(k, base + 4, 3, 1, SHADE[1])
    cx = iw // 2
    for yy in range(6, base):
        t = (yy - 14) / (base - 14)
        half = max(1.0, 1.5 + 4.0 * max(0.0, t))
        for xx in range(int(cx - half), int(cx + half) + 1):
            c = IVORY[3] if xx < cx - half * 0.2 else (IVORY[1] if xx > cx + half * 0.5 else IVORY[2])
            if yy < 14:
                c = IVORY[4] if xx <= cx else IVORY[2]
            cv.put(xx, yy, c)
    cv.put(cx, 4, SHADE[4])
    cv.put(cx, 5, IVORY[4])
    return cv


def escena_retrato(iw: int, ih: int) -> Canvas:
    cv = Canvas(iw, ih, hexc("12291f"))
    degrade(cv, 0, 0, iw, ih, ramp("12291f", "1a3a2c", "254c3a"))
    cx = iw // 2
    hy = int(ih * 0.38)
    for yy in range(ih - 8, ih):
        half = min(iw // 2, 3 + (yy - (ih - 8)) // 2)
        cv.hline(cx - half, cx + half - 1, yy, hexc("241a30") if yy % 2 else hexc("1a1424"))
    cv.vline(cx, ih - 7, ih - 1, IVORY[3])
    cv.hline(cx - 1, cx + 1, ih - 7, IVORY[3])
    cv.put(cx, ih - 5, hexc("a01828"))
    ell(cv, cx, hy, 3.8, 5.0, SKIN[2])
    for yy in range(hy - 4, hy + 4):
        cv.put(cx + 3, yy, SKIN[1])
    for yy in range(hy - 3, hy + 2):
        cv.put(cx - 3, yy, SKIN[3])
    pelo = hexc("2a1a14")
    cv.hline(cx - 3, cx + 3, hy - 5, pelo)
    cv.hline(cx - 2, cx + 2, hy - 6, pelo)
    cv.put(cx - 2, hy - 1, hexc("1a1420"))
    cv.put(cx + 2, hy - 1, hexc("1a1420"))
    cv.hline(cx - 2, cx + 2, hy + 2, pelo)
    ell(cv, cx, hy + 5, 2.4, 1.1, SKIN[1])
    return cv


def escena_tango(iw: int, ih: int) -> Canvas:
    cv = Canvas(iw, ih, hexc("3a1810"))
    degrade(cv, 0, 0, iw, ih, ramp("3a1810", "6a3012", "8c4a1c", "b86a28"))
    fy = ih - 6
    for j in range(6):
        for k in range(iw):
            cv.put(k, fy + j, hexc("2a1a14") if ((k // 4) + (j // 2)) % 2 else hexc("5a3a22"))
    disc(cv, iw - 5, 5, 3, SHADE[2])
    disc(cv, iw - 5, 5, 1.8, SHADE[3])
    cx = iw // 2
    traje, vestido = hexc("1a1420"), hexc("a01828")
    for yy in range(fy - 17, fy + 3):
        t = (yy - (fy - 17)) / 20
        cv.hline(cx - 5 + int(t * 1), cx - 2, yy, traje if yy > fy - 13 else hexc("2a2230"))
    ell(cv, cx - 4, fy - 20, 2, 2.2, SKIN[3])
    cv.hline(cx - 7, cx - 1, fy - 22, traje)
    for yy in range(fy - 16, fy + 3):
        t = (yy - (fy - 16)) / 19
        cv.hline(cx + 1 - int(t * 2), cx + 5 + int(t * 2), yy, vestido if yy % 4 else hexc("c8283a"))
    ell(cv, cx + 3, fy - 18, 2, 2.2, SKIN[2])
    cv.hline(cx - 2, cx + 2, fy - 11, SKIN[2])
    return cv


ESCENAS = {"building": escena_obelisco, "portrait": escena_retrato, "dancers": escena_tango}


def cuadro(cv: Canvas, x: int, y: int, w: int, h: int, kind: str) -> None:
    ix, iy, iw, ih = marco(cv, x, y, w, h)
    cv.blit(ESCENAS[kind](iw, ih), ix, iy)


# ---------------------------------------------------------------- franja azul (capitoné)
NV = ramp("060e24", "0a1636", "0f2048", "163060", "1f4280", "2a58a0")


def capitone(cv: Canvas, y0: int, y1: int, w: int) -> None:
    """Rombos acolchados con luz arriba-izquierda, costura hundida, trama de tela y botones de latón en los cruces."""
    HX, HY = 12.0, 7.0
    h = y1 - y0
    for y in range(y0, y1):
        for x in range(w):
            ly = y - y0
            p = (x / HX + ly / HY) / 2.0
            q = (x / HX - ly / HY) / 2.0
            fa, fb = p - math.floor(p), q - math.floor(q)
            t = min(fa, 1 - fa, fb, 1 - fb) * 2.0
            lit = (1 - fa) * 0.5 + (1 - fb) * 0.5 - 0.5
            idx = 2
            if t > 0.3 and lit > 0.1:
                idx = 4
            elif t > 0.18 and lit > -0.05:
                idx = 3
            elif lit < -0.2:
                idx = 1
            if t < 0.1:
                idx = 0
            elif t < 0.2:
                idx = min(idx, 1)
            if idx >= 2 and (x + ly) % 4 == 0 and hash2(x, ly, 6) > 0.5:
                idx -= 1
            if ly > h - 10:
                idx = max(0, idx - 1)
            cv.put(x, y, NV[idx])
    for i in range(-1, int(w / HX) + 2):
        for j in range(-1, int(h / HY) + 2):
            if (i + j) % 2:
                continue
            cx, cy = round(i * HX), y0 + round(j * HY)
            if 2 <= cx < w - 3 and y0 + 3 <= cy < y1 - 3:
                cv.put(cx, cy, GOLD[5])
                cv.put(cx + 1, cy, GOLD[3])
                cv.put(cx, cy + 1, GOLD[3])
                cv.put(cx + 1, cy + 1, GOLD[1])
                cv.put(cx + 2, cy + 1, NV[0])
                cv.put(cx + 1, cy + 2, NV[0])
