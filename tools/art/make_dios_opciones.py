"""Tres propuestas épicas para Dios (Fase 7), en la grilla lógica (2×2 px de pantalla).

El triángulo anterior era un placeholder. Las tres opciones usan contraste fuerte (negro cósmico, oro, blanco
ardiente y carmesí) para chocar con el club cálido del resto del juego, y se leen sobre el cielo claro del nivel 7:
  A  Ojo solar: un ojo de pupila vertical dentro de un vacío oscuro, con anillos y 32 rayos.
  B  Figura de luz: silueta colosal con capucha, ojos blancos y los brazos abiertos, con corona de rayos.
  C  Dado cósmico: un dado dorado con un ojo en el lugar de un punto, dentro de una mandorla y dados en órbita.
Cada una mide 124×100 px lógicos. Escribe test-results/dios-{a,b,c}.png y composiciones sobre el cielo.

Ejecutar:  python tools/art/make_dios_opciones.py
"""
from __future__ import annotations

import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_lib import Canvas, GOLD, OUTLINE, IVORY, ramp, poly_mask, ellipse_mask, edge_of, upscale

W, H = 124, 100
CX, CY = 62, 50
NIGHT = ramp("04020a", "0e0820", "1c1040", "2e1c64", "4a2f8c")
CRIM = ramp("2a0610", "6e1020", "b81c2c", "ff4a3a", "ffa078")
HOT = (255, 252, 240)


def disc(r: float, cx=CX, cy=CY):
    return ellipse_mask(W, H, cx, cy, r, r)


def ring(r0: float, r1: float, cx=CX, cy=CY):
    return disc(r1, cx, cy) & ~disc(r0, cx, cy)


def lit_band(cv: Canvas, mask, cx, cy, ramp_):
    """Pinta una máscara con 4 bandas planas según el ángulo respecto de la luz (arriba-izquierda)."""
    yy, xx = np.mgrid[0:H, 0:W]
    t = ((xx + 0.5 - cx) * -0.7 + (yy + 0.5 - cy) * -0.7) / np.maximum(np.hypot(xx + 0.5 - cx, yy + 0.5 - cy), 1e-6)
    for lo, hi, c in ((0.55, 9, ramp_[5]), (0.1, 0.55, ramp_[4]), (-0.45, 0.1, ramp_[3]), (-9, -0.45, ramp_[2])):
        cv.fill(mask & (t >= lo) & (t < hi), c)


def rays(cv: Canvas, n: int, r0: float, rlong: float, rshort: float, width: float, cx=CX, cy=CY):
    for k in range(n):
        a = 2 * math.pi * k / n - math.pi / 2
        rr = rlong if k % 2 == 0 else rshort
        pts = [(cx + r0 * math.cos(a - width), cy + r0 * math.sin(a - width) * 0.92),
               (cx + rr * math.cos(a), cy + rr * math.sin(a) * 0.92),
               (cx + r0 * math.cos(a + width), cy + r0 * math.sin(a + width) * 0.92)]
        m = poly_mask(W, H, pts)
        # banda por distancia: blanco ardiente cerca del centro, oro, ámbar en la punta
        yy, xx = np.mgrid[0:H, 0:W]
        d = np.hypot(xx - cx, (yy - cy) / 0.92)
        f = (d - r0) / max(rr - r0, 1)
        cv.fill(m & (f < 0.34), GOLD[5])
        cv.fill(m & (f >= 0.34) & (f < 0.68), GOLD[4])
        cv.fill(m & (f >= 0.68), GOLD[3])


def outline_all(cv: Canvas):
    solid = cv.mask_of()
    ring_ = np.zeros_like(solid)
    ring_[1:-1, 1:-1] = ~solid[1:-1, 1:-1] & (solid[:-2, 1:-1] | solid[2:, 1:-1] | solid[1:-1, :-2] | solid[1:-1, 2:])
    cv.fill(ring_, NIGHT[0])


def option_a() -> Canvas:
    cv = Canvas(W, H)
    rays(cv, 32, 24, 49, 38, 0.075)
    # anillos dorados
    lit_band(cv, ring(30, 33), CX, CY, GOLD)
    for k in range(24):
        a = 2 * math.pi * k / 24
        cv.rect(round(CX + 36.5 * math.cos(a)) - 1, round(CY + 36.5 * math.sin(a) * 0.92) - 1, 3, 3, GOLD[5] if k % 2 == 0 else GOLD[3])
    # vacío oscuro con borde dorado
    cv.fill(disc(26), NIGHT[1])
    cv.fill(ring(23, 26), NIGHT[2])
    lit_band(cv, ring(26, 28), CX, CY, GOLD)
    cv.fill(disc(23) & ~disc(21), NIGHT[0])
    # ojo almendrado
    yy, xx = np.mgrid[0:H, 0:W]
    u = (xx + 0.5 - CX) / 21.0
    up = -12.0 * np.clip(1 - u ** 2, 0, 1) ** 0.9
    lo = 9.0 * np.clip(1 - u ** 2, 0, 1) ** 0.9
    v = yy + 0.5 - CY
    eye = (np.abs(u) <= 1) & (v >= up) & (v <= lo)
    cv.fill(eye, (236, 224, 200))
    cv.fill(eye & (v < up + 3.5), (176, 150, 140))       # sombra del párpado
    # iris: anillo carmesí, oro y centro ardiente
    ir = np.hypot(xx + 0.5 - CX, yy + 0.5 - CY - 0.5)
    cv.fill(eye & (ir < 9), CRIM[2])
    cv.fill(eye & (ir < 8), GOLD[3])
    cv.fill(eye & (ir < 6), GOLD[4])
    cv.fill(eye & (ir < 4), GOLD[5])
    for k in range(16):  # fibras radiales
        a = 2 * math.pi * k / 16
        for rr in (5, 6, 7):
            cv.put(round(CX + rr * math.cos(a)), round(CY + 0.5 + rr * math.sin(a)), GOLD[2])
    cv.fill(eye & (np.abs(xx + 0.5 - CX) < 1.7) & (np.abs(yy + 0.5 - CY - 0.5) < 6.2), NIGHT[0])
    cv.put(CX - 3, CY - 4, HOT)
    cv.put(CX - 2, CY - 4, HOT)
    # contorno de párpados
    edge = edge_of(eye)
    cv.fill(edge, NIGHT[0])
    top = edge & (v < 0)
    cv.fill(top & (np.abs(xx + 0.5 - CX) < 17), CRIM[1])
    # pestañas / rayos cortos sobre el párpado
    for k in range(-5, 6):
        x = CX + k * 3.6
        y = CY - 12.5 * max(0.0, 1 - (k * 3.6 / 21) ** 2) ** 0.9
        cv.line(round(x), round(y), round(x + k * 0.5), round(y - 4 - (5 - abs(k)) * 0.4), NIGHT[0])
    return cv


def option_b() -> Canvas:
    cv = Canvas(W, H)
    # halo detrás de la cabeza y corona de siete rayos
    hx, hy = CX, 30
    rays(cv, 28, 17, 38, 29, 0.09, cx=hx, cy=hy)
    lit_band(cv, ring(14, 17, hx, hy), hx, hy, GOLD)
    cv.fill(disc(14, hx, hy), HOT)
    cv.fill(disc(14, hx, hy) & ~disc(11, hx, hy), GOLD[5])
    # túnica: campana oscura con estrellas, brazos abiertos
    robe = poly_mask(W, H, [(CX - 9, 36), (CX + 9, 36), (CX + 19, 58), (CX + 52, 76), (CX + 58, 82), (CX + 36, 80),
                            (CX + 26, 99), (CX - 26, 99), (CX - 36, 80), (CX - 58, 82), (CX - 52, 76), (CX - 19, 58)])
    cv.fill(robe, NIGHT[2])
    inner = poly_mask(W, H, [(CX - 7, 38), (CX + 7, 38), (CX + 14, 60), (CX + 20, 99), (CX - 20, 99), (CX - 14, 60)])
    cv.fill(inner & robe, NIGHT[1])
    # pliegues con luz de la izquierda
    for x0, x1 in ((CX - 38, CX - 14), (CX - 22, CX - 10)):
        cv.line(x0, 80, x1, 56, NIGHT[4])
    cv.line(CX - 17, 62, CX - 24, 98, NIGHT[3])
    cv.line(CX + 17, 62, CX + 24, 98, NIGHT[0])
    cv.line(CX - 13, 64, CX - 16, 98, NIGHT[3])
    # borde de luz sobre la silueta (izquierda y hombros)
    edge = edge_of(robe)
    yy, xx = np.mgrid[0:H, 0:W]
    cv.fill(edge & (xx < CX), GOLD[4])
    cv.fill(edge & (xx >= CX), GOLD[2])
    # cabeza: capucha negra con dos ojos blancos
    hood = poly_mask(W, H, [(CX - 11, 38), (CX - 9, 22), (CX - 4, 17), (CX + 4, 17), (CX + 9, 22), (CX + 11, 38), (CX + 6, 42), (CX - 6, 42)])
    cv.fill(hood, NIGHT[0])
    cv.fill(edge_of(hood) & (xx < CX), NIGHT[3])
    cv.rect(CX - 6, 28, 4, 2, HOT)
    cv.rect(CX + 2, 28, 4, 2, HOT)
    cv.put(CX - 7, 29, GOLD[4]); cv.put(CX + 6, 29, GOLD[4])
    # manos de luz en las puntas de los brazos
    for sx in (-1, 1):
        px, py = CX + sx * 58, 80
        cv.fill(disc(7, px, py), HOT)
        cv.fill(ring(7, 10, px, py), GOLD[4])
        for k in range(9):
            a = 2 * math.pi * k / 9
            cv.line(px, py, round(px + 15 * math.cos(a)), round(py + 12 * math.sin(a)), GOLD[5] if k % 2 else GOLD[3])
        cv.fill(disc(5, px, py), HOT)
    # estrellas en la túnica
    for x, y in ((CX - 9, 70), (CX + 5, 76), (CX - 3, 88), (CX + 12, 90), (CX - 14, 84), (CX + 9, 62), (CX - 28, 78), (CX + 30, 82)):
        if robe[y, x]:
            cv.put(x, y, HOT)
            cv.put(x + 1, y, GOLD[4])
    cv.fill(edge_of(robe), NIGHT[0]) if False else None
    return cv


def die_pips(cv: Canvas, x0: int, y0: int, size: int, eye: bool):
    pad = size // 4
    cols = (x0 + pad, x0 + size - pad - 1)
    rows = (y0 + pad - 1, y0 + size // 2, y0 + size - pad)
    for ri, y in enumerate(rows):
        for ci, x in enumerate(cols):
            if eye and ri == 0 and ci == 1:
                continue
            cv.fill(ellipse_mask(W, H, x + 0.5, y + 0.5, 2.6, 2.6), CRIM[1])
            cv.fill(ellipse_mask(W, H, x + 0.5, y + 0.5, 1.8, 1.8), NIGHT[0])
    return rows, cols


def option_c() -> Canvas:
    cv = Canvas(W, H)
    rays(cv, 36, 28, 50, 40, 0.06)
    # mandorla (dos círculos que se cruzan), con borde dorado
    yy, xx = np.mgrid[0:H, 0:W]
    m = (np.hypot(xx + 0.5 - (CX - 22), yy + 0.5 - CY) < 40) & (np.hypot(xx + 0.5 - (CX + 22), yy + 0.5 - CY) < 40)
    m &= np.abs(yy + 0.5 - CY) < 44
    cv.fill(m, NIGHT[1])
    cv.fill(m & (np.hypot(xx + 0.5 - CX, yy + 0.5 - CY) < 30), NIGHT[2])
    cv.fill(edge_of(m), GOLD[5])
    cv.fill(edge_of(m & ~edge_of(m)), GOLD[3])
    # estrellas dentro
    for x, y in ((CX - 14, 24), (CX + 15, 30), (CX - 12, 76), (CX + 14, 70), (CX + 3, 14), (CX - 5, 86), (CX + 20, 50), (CX - 20, 52)):
        if m[y, x]:
            cv.put(x, y, HOT)
    # el dado: cuerpo marfil con borde dorado, 36×36
    s = 36
    x0, y0 = CX - s // 2, CY - s // 2
    body = np.zeros((H, W), bool)
    body[y0:y0 + s, x0:x0 + s] = True
    for dx, dy in ((0, 0), (s - 1, 0), (0, s - 1), (s - 1, s - 1)):
        for k in range(3):
            body[y0 + dy + (k if dy == 0 else -k), x0 + dx + (0 if dx == 0 else 0)] = body[y0 + dy + (k if dy == 0 else -k), x0 + dx]
    cv.fill(body, IVORY[2])
    cv.fill(body & (np.arange(W)[None, :] < x0 + 4), IVORY[3])
    cv.fill(body & (np.arange(H)[:, None] < y0 + 3), IVORY[4])
    cv.fill(body & (np.arange(W)[None, :] >= x0 + s - 4), IVORY[1])
    cv.fill(body & (np.arange(H)[:, None] >= y0 + s - 3), IVORY[1])
    cv.fill(edge_of(body), GOLD[3])
    cv.fill(edge_of(body & ~edge_of(body)), GOLD[5])
    rows, cols = die_pips(cv, x0, y0, s, eye=True)
    # ojo en el lugar del punto superior derecho
    ex, ey = cols[1] + 0.5, rows[0] + 0.5
    eye = ellipse_mask(W, H, ex, ey, 4.4, 3.0)
    cv.fill(eye, (236, 224, 200))
    cv.fill(ellipse_mask(W, H, ex, ey, 2.4, 2.4), CRIM[3])
    cv.fill(ellipse_mask(W, H, ex, ey, 1.2, 1.2), NIGHT[0])
    cv.fill(edge_of(eye), NIGHT[0])
    # dados en órbita
    for k in range(8):
        a = 2 * math.pi * k / 8 + 0.4
        ox, oy = round(CX + 49 * math.cos(a)), round(CY + 40 * math.sin(a))
        if 4 <= ox < W - 4 and 4 <= oy < H - 4:
            cv.rect(ox - 3, oy - 3, 7, 7, IVORY[2])
            cv.rect(ox - 3, oy - 3, 7, 1, IVORY[4])
            cv.rect(ox - 3, oy + 3, 7, 1, IVORY[1])
            cv.rect(ox - 3, oy - 3, 1, 7, IVORY[3])
            cv.put(ox - 1, oy - 1, NIGHT[0]); cv.put(ox + 1, oy + 1, NIGHT[0])
            if k % 2: cv.put(ox + 1, oy - 1, NIGHT[0]); cv.put(ox - 1, oy + 1, NIGHT[0])
            for ddx, ddy in ((-4, 0), (4, 0), (0, -4), (0, 4)):
                cv.put(ox + ddx, oy + ddy, NIGHT[0])
    outline_all(cv)
    return cv


def sky_panel() -> Image.Image:
    atlas = Image.open("assets/art/pixel-v3/exteriores-v3.png").convert("RGB")
    return upscale(atlas.crop((402, 222, 402 + 401, 222 + 110)), 2).convert("RGBA")


def main() -> None:
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    os.makedirs("test-results", exist_ok=True)
    for tag, fn in (("a", option_a), ("b", option_b), ("c", option_c)):
        cv = fn()
        cv.save(f"test-results/dios-{tag}.png")
        canvas = sky_panel()
        canvas.alpha_composite(upscale(cv.image(), 2), (197 - W, 220 - H * 2 + 8 if False else 0))
        canvas.convert("RGB").save(f"test-results/dios-{tag}-cielo.png")
    print("ok")


if __name__ == "__main__":
    main()
