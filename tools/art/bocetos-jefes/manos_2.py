"""Bocetos de manos de jefe, niveles 4 a 6. Mismo formato que manos_1.py."""
from __future__ import annotations

import math

import numpy as np
from PIL import Image

import kit as K
from manos_1 import RAMPS, HX, HY, frame, lay, cuff, ring_band, path

SKIN = ["#4a2c1c", "#7a4a2e", "#a8704a", "#d29a72", "#f0c4a0"]


# ------------------------------------------------------------------ tahúr
def dealer(img):
    """Guante blanco de crupier, puño de camisa y liga de manga roja y negra."""
    img = cuff(img, 0, 11, "#f4f0e8", stripes=[(3, "#d63a30"), (4, "#1c1424"), (5, "#d63a30"), (10, "#b8b0a0")])
    a = np.array(img)
    if a[8, 30, 3]: a[8, 30:32, :3] = K.hexc("#f2d24a")[:3]   # gemelo
    return Image.fromarray(a)


def felt(L):
    L.rect(0, 96, K.SW - 1, K.SH - 1, "#2f6a3a"); L.rect(0, 96, K.SW - 1, 96, "#c9a227")
    for x in range(0, K.SW, 4): L.px([(x + (x // 4) % 2, 100), (x + 2, 105)], "#3a7a46")


def tahur_a():
    hand = dealer(K.pose("abierta", RAMPS["l4_tahur"]))
    table = lay(felt)
    rest = [(HX + 12, HY + 43), (HX + 23, HY + 46)]

    def dice(pos, vals):
        def f(L):
            for (x, y), v in zip(pos, vals): K.mini_die(L, int(x), int(y), v, red_one=True)
        return lay(f)
    frames = [frame("cierre", hand, behind=[table], front=[dice(rest, (1, 1))])]
    land = [(78, 89), (96, 89)]
    tumble = [3, 5, 2, 6, 4, 2, 5, 3]
    for k in range(14):
        if k < 6:
            t = (k + 1) / 6
            pos = [(rx + (lx - rx) * t, ry + (ly - ry) * t - math.sin(t * math.pi) * 10 + (2 if k == 5 else 0)) for (rx, ry), (lx, ly) in zip(rest, land)]
            vals = (tumble[k], tumble[k + 2])
        elif k < 10:
            pos, vals = land, (1, 1)
        else:
            t = (k - 9) / 4
            pos = [(lx + (rx - lx) * t, ly + (ry - ly) * t - math.sin(t * math.pi) * 8) for (rx, ry), (lx, ly) in zip(rest, land)]
            vals = (1, 1)
        def tag(L, k=k):
            if 6 <= k < 10: K.text(L, "1 Y 1", 77, 80, "#f2d24a")
        frames.append(frame("cierre", hand, behind=[table], front=[dice(pos, vals), lay(tag)]))
    return frames


CHIPS = [("#d8453a", "#9a2a22"), ("#f2ead8", "#a89f8a"), ("#3a6ae0", "#2644a0"), ("#2f9a3a", "#1f6a2a")]


def chip_stack(L, x, y, n, start=0):
    for i in range(n):
        c, d = CHIPS[(i + start) % 4]
        yy = y - i * 2
        L.ellipse(x, yy - 2, x + 11, yy + 2, c); L.rect(x + 1, yy + 1, x + 10, yy + 1, d)
        L.px([(x + 3, yy), (x + 8, yy)], "#fff6e8")


def tahur_b():
    hand = dealer(K.pose("puño", RAMPS["l4_tahur"]))
    table = lay(felt)
    frames = [frame("cierre", hand, behind=[table], front=[lay(lambda L: chip_stack(L, 70, 96, 8))])]
    offs = [3, 6, 9, 9, 6, 3, 0, 0, 0, 0, 0, 0]
    for k, o in enumerate(offs):
        def chips(L, k=k, o=o):
            if o:
                chip_stack(L, 70 - o, 96, 4, 0); chip_stack(L, 70 + o, 96, 4, 1)
            else:
                chip_stack(L, 70, 96, 8, (k // 2) % 4)
            if 6 <= k <= 10:   # una ficha sube girando
                y = 76 - [0, 8, 12, 8, 0][k - 6]
                w = [5, 2, 5, 2, 5][k - 6]
                L.ellipse(76 - w, y - 2, 76 + w, y + 2, "#d8453a")
        dy = 6 if 1 <= k <= 5 else 0
        frames.append(frame("cierre", hand, dy=dy, behind=[table], front=[lay(chips)]))
    return frames


# ------------------------------------------------------------------ patovica
def bouncer(name):
    hand = K.pose(name, RAMPS["l4_patovica"])
    hand = cuff(hand, 0, 6, "#141418")
    a = np.array(hand)
    for y in range(6, 13):   # brazalete STAFF
        for x in range(a.shape[1]):
            if a[y, x, 3]: a[y, x, :3] = K.hexc("#ffe27a" if y == 6 else ("#b8901a" if y == 12 else "#f2c93a"))[:3]
    hand = Image.fromarray(a)
    L = K.Layer(hand.width, hand.height)
    K.text(L, "STAFF", 21, 7, "#1c1424")
    hand.alpha_composite(L.im)
    return hand


def earpiece(L, dx=0, dy=0):
    for y in range(HY - 2, HY + 20, 1):   # cable rulo del auricular
        x = HX + 14 + int(2 * math.sin(y * 1.3)) + dx
        L.px([(x, y + dy)], "#c9ced6")


def patovica_a():
    base = bouncer("indice")
    canvas = K.grow(base, 61, 60)
    frames = [frame("cierre", canvas, behind=[lay(earpiece)])]
    for k, ang in enumerate([0, -9, -12, -9, 0, 9, 12, 9, 0, -9, 0, 0]):
        h = K.rot(canvas, ang, (30, 2))
        def no(L, k=k):
            if 2 <= k <= 9:
                L.rect(HX + 22, HY + 60, HX + 37, HY + 68, "#d63a30"); K.text(L, "NO.", HX + 24, HY + 62, "#fff6e8")
        frames.append(frame("cierre", h, behind=[lay(earpiece)], front=[lay(no)]))
    return frames


def rope(L, x0, y0, x1, y1, sag):
    pts = []
    for i in range(41):
        t = i / 40
        pts.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t + sag * 4 * t * (1 - t)))
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        L.line([(ax, ay), (bx, by)], "#b01226", 3)
    for (ax, ay), (bx, by) in zip(pts[::2], pts[1::2]):
        L.line([(ax, ay - 1), (bx, by - 1)], "#e24a5a", 1)


def post(L):
    L.rect(160, 66, 165, 108, "#c9a227"); L.rect(160, 66, 161, 108, "#ffe27a"); L.ellipse(157, 62, 168, 69, "#f2d24a")
    L.rect(155, 104, 170, 109, "#8a6a12")


def patovica_b():
    hand = bouncer("puño")
    grip = (HX + 24, HY + 40)
    frames = [frame("cierre", hand, behind=[lay(post)], front=[lay(lambda L: rope(L, grip[0], grip[1], 162, 70, 22))])]
    steps = [(0, 18), (-4, 12), (-8, 8), (-8, None), (-8, None), (-8, None), (-8, None), (-6, 10), (-3, 16), (0, 20), (0, 22), (0, 22)]
    for k, (dy, sag) in enumerate(steps):
        def r(L, dy=dy, sag=sag):
            if sag is None:   # soga desenganchada: cuelga del poste
                for i in range(30):
                    L.line([(162, 70 + i), (162 + int(2 * math.sin(i / 4)), 71 + i)], "#b01226", 3)
                L.rect(158, 99, 164, 102, "#c9a227")
            else:
                rope(L, grip[0], grip[1] + dy, 162, 70, sag)
        frames.append(frame("cierre", hand, dy=dy, behind=[lay(post)], front=[lay(r)]))
    return frames


# ------------------------------------------------------------------ payaso
def clown(name):
    hand = K.pose(name, RAMPS["l4_payaso"])
    a = np.array(hand)
    for y in range(0, 13):   # volado a rayas
        for x in range(a.shape[1]):
            if a[y, x, 3]:
                c = "#d63a30" if (x // 3) % 2 else "#fff6e8"
                if y >= 10 and (x + y) % 3 == 0: c = "#1c1424"
                a[y, x, :3] = K.hexc(c)[:3]
    # tres costuras de guante en el dorso
    for x in (20, 26, 32):
        for y in range(14, 22):
            if a[y, x, 3]: a[y, x, :3] = K.hexc("#8a8a9c")[:3]
    hand = Image.fromarray(a)
    # el volado sobresale
    out = K.grow(hand, 65, 53, 2, 0)
    L = K.Layer(65, 53)
    for i, x in enumerate(range(18, 50, 4)):
        L.poly([(x, 11), (x + 4, 11), (x + 2, 14)], "#d63a30" if i % 2 else "#fff6e8")
    out.alpha_composite(L.done())
    out.alpha_composite(K.grow(hand, 65, 53, 2, 0).crop((0, 0, 65, 11)), (0, 0))
    return out


def flower(L, x, y):
    L.line([(x + 4, y - 8), (x + 4, y)], "#2f9a3a")
    for ox, oy in ((-3, 0), (3, 0), (0, -3), (0, 3)):
        L.ellipse(x + 4 + ox - 2, y + 3 + oy - 2, x + 4 + ox + 2, y + 3 + oy + 2, "#f2c93a")
    L.ellipse(x + 2, y + 1, x + 6, y + 5, "#d8453a"); L.px([(x + 3, y + 2)], "#ff9a8a")


def payaso_a():
    hand = clown("puño")
    fx, fy = HX + 20, HY + 42
    frames = [frame("cierre", hand, front=[lay(lambda L: flower(L, fx, fy))])]
    for k in range(12):
        def water(L, k=k):
            if k < 1 or k > 9: return
            n = min(k, 6) * 4
            for i in range(0, n, 2):
                t = i / 24
                x = fx + 8 + t * 60
                y = fy + 4 - 18 * t + 40 * t * t
                if k > 6 and i < (k - 6) * 8: continue
                L.px([(int(x), int(y)), (int(x) + 1, int(y))], "#7fd0ff")
            if k >= 6:
                for j in range(4): L.px([(fx + 64 + j * 3 - 4, 96 - (j % 2) * 2 - (k - 6))], "#bfe6ff")
        frames.append(frame("cierre", hand, dx=(1 if k == 1 else 0), front=[lay(lambda L: flower(L, fx, fy)), lay(water)]))
    return frames


def payaso_b():
    hand = clown("indice")
    tip = (HX + 33, HY + 50)
    frames = [frame("cierre", hand)]
    ext = [3, 7, 11, 11, 11, 11, 11, 11, 11, 7, 3, 0]
    for k, e in enumerate(ext):
        def bang(L, k=k, e=e):
            if not e: return
            L.line([tip, (tip[0], tip[1] + e)], "#8a6a3a")
            if e == 11:
                x, y = tip[0] - 2, tip[1] + 11
                L.rect(x, y, x + 24, y + 9, "#fff6e8"); L.rect(x, y + 9, x + 24, y + 9, "#c8c8d8")
                K.text(L, "¡PUM!", x + 3, y + 2, "#d63a30")
                for j in range(6):
                    L.px([(x - 6 + j * 7, y - 4 + (j * 5 + k) % 9)], ("#f2c93a", "#3a6ae0", "#d63a30", "#2f9a3a")[j % 4])
        frames.append(frame("cierre", hand, dy=(-1 if k == 3 else 0), front=[lay(bang)]))
    return frames


# ------------------------------------------------------------------ visitante
def alien_hand():
    """Tres dedos largos: se borran el meñique y el dedo corto, y los dedos se estiran un 30 %."""
    ramp = RAMPS["l5_visitante"]
    a = np.array(K.pose("abierta", ramp))
    a[24:, :9] = 0          # meñique
    a[24:, 27:39] = 0       # dedo corto junto al pulgar
    out = np.zeros((66, 61, 4), np.uint8)
    out[:24] = a[:24]
    for y in range(24, 66):
        sy = 24 + int((y - 24) / 1.32)
        if sy < 53: out[y] = a[sy]
    img = Image.fromarray(out)
    img = K.specks(img, ["#d4ffa8"], 8, 6, 30, seed=2)   # brillo de piel lisa
    L = K.Layer(61, 66)
    for cx, b in K.tips(img, 30):
        L.ellipse(cx - 2, b - 4, cx + 2, b, "#d4ffa8"); L.px([(int(cx), b - 2)], "#2b7a3f")
    img.alpha_composite(L.done())
    return img


def visitante_a():
    hand = alien_hand()

    def beam(level):
        im = Image.new("RGBA", (K.SW, K.SH), (0, 0, 0, 0))
        if level <= 0: return (im, (0, 0))
        L = K.Layer()
        top = (HX + 24, HY + 62)
        L.poly([(top[0] - 6, top[1]), (top[0] + 6, top[1]), (top[0] + 26, K.SH), (top[0] - 26, K.SH)], "#8ee06a")
        arr = np.array(L.im)
        arr[..., 3] = (arr[..., 3] > 0) * int(70 * level)
        for y in range(top[1], K.SH, 4): arr[y, :, 3] = np.where(arr[y, :, 3] > 0, int(120 * level), 0)
        return (Image.fromarray(arr), (0, 0))
    frames = [frame("espacio", hand)]
    ys = [None, None, 104, 98, 92, 86, 82, 80, 80, 86, 96, 104, None]
    for k, y in enumerate(ys):
        lvl = 0 if k == 0 or k == 12 else (0.5 if k in (1, 11) else 1)

        def die(L, y=y, k=k):
            if y is not None: K.mini_die(L, HX + 21, y, (3, 5, 2, 6, 4, 1)[k % 6])
        frames.append(frame("espacio", hand, behind=[lay(die)], front=[beam(lvl)]))
    return frames


def visitante_b():
    hand = alien_hand()
    c = (HX + 28, HY + 40)

    def dice(phase, glow):
        def f(L):
            for i in range(3):
                ang = phase + i * 2 * math.pi / 3
                K.mini_die(L, int(c[0] + 42 * math.cos(ang)) - 3, int(c[1] + 14 * math.sin(ang)) - 3, (2, 4, 6)[i])
        im = K.Layer()
        if glow:
            for cx, b in K.tips(hand, 30): K.glow(im.im, HX + cx, HY + b - 2, 4, "#d4ffa8", 160)
        return [lay(f), (im.im, (0, 0))]
    frames = [frame("espacio", hand, front=dice(0.3, False))]
    for k in range(12):
        frames.append(frame("espacio", hand, front=dice(0.3 + (k + 1) * 2 * math.pi / 12, True)))
    return frames


# ------------------------------------------------------------------ farolero
def ringed(name):
    hand = K.pose(name, SKIN)
    hand = cuff(hand, 0, 9, "#1a1d22", stripes=[(4, "#3cd47a"), (5, "#3cd47a")])
    L = K.Layer(hand.width, hand.height)
    x, y = (26, 27) if name == "puño" else (19, 36)
    L.rect(x, y, x + 6, y + 5, "#1f6a3a"); L.rect(x + 1, y + 1, x + 5, y + 4, "#3cd47a"); L.rect(x + 2, y + 2, x + 4, y + 3, "#c8ffdd")
    hand.alpha_composite(L.done())
    return hand


def lantern_lines(L, x, y, c="#5cff9a", part=1.0):
    """Farol hecho de luz: solo el contorno, que se va completando con `part`."""
    segs = [((x + 6, y), (x + 6, y + 4)), ((x, y + 4), (x + 12, y + 4)), ((x + 1, y + 5), (x + 1, y + 18)), ((x + 11, y + 5), (x + 11, y + 18)),
            ((x, y + 19), (x + 12, y + 19)), ((x + 3, y + 8), (x + 9, y + 8)), ((x + 6, y + 9), (x + 6, y + 15)), ((x + 2, y + 20), (x + 10, y + 20))]
    for s in segs[:max(1, int(len(segs) * part))]: L.line(list(s), c)


def farolero_a():
    hand = ringed("puño")
    ring = (HX + 29, HY + 30)
    frames = [frame("espacio", hand)]
    parts = [0, .2, .45, .7, 1, 1, 1, 1, .7, .4, .15, 0]
    for k, p in enumerate(parts):
        g = K.Layer()
        if 1 <= k <= 9: K.glow(g.im, ring[0], ring[1], 6, "#3cd47a", 150)

        def lamp(L, p=p, k=k):
            if p <= 0: return
            sway = [0, 0, 0, 0, -2, 0, 2, 0, 0, 0, 0, 0][k]
            L.line([ring, (HX + 30 + sway, HY + 50)], "#5cff9a")
            lantern_lines(L, HX + 24 + sway, HY + 50, "#5cff9a" if k < 9 else "#2f9a5a", p)
        frames.append(frame("espacio", hand, front=[(g.im, (0, 0)), (K.Layer().im, (0, 0)), lay(lamp) if False else (_noline(lamp), (0, 0))]))
    return frames


def _noline(fn):
    L = K.Layer()
    fn(L)
    return L.im


def farol(angle, glow_r):
    W = 40
    L = K.Layer(W, 44)
    x, y = 14, 8
    L.ellipse(x + 4, y - 6, x + 8, y - 2, "#2a2a30")                  # argolla
    L.poly([(x - 1, y + 4), (x + 6, y - 1), (x + 13, y + 4)], "#2a2a30")    # techo
    L.rect(x, y + 4, x + 12, y + 20, "#2a2a30")
    L.rect(x + 2, y + 6, x + 10, y + 18, "#8effb8"); L.rect(x + 2, y + 6, x + 3, y + 18, "#d8ffe6"); L.rect(x + 6, y + 6, x + 6, y + 18, "#2a2a30")
    L.rect(x + 1, y + 20, x + 11, y + 22, "#2a2a30")
    im = L.done()
    g = Image.new("RGBA", (W, 44), (0, 0, 0, 0))
    K.glow(g, x + 6, y + 12, glow_r, "#3cd47a", 140)
    g.alpha_composite(im)
    return K.rot(g, angle, (x + 6, y - 4))


def farolero_b():
    hand = ringed("puño")
    at = (HX + 6, HY + 38)
    frames = [frame("espacio", hand, front=[(farol(0, 10), at)])]
    for k, ang in enumerate([8, 15, 18, 12, 0, -12, -18, -12, 0, 6, 0, 0]):
        frames.append(frame("espacio", hand, front=[(farol(ang, 10 + (k % 3) * 3), at)]))
    return frames


# ------------------------------------------------------------------ computadora
def metal(name):
    hand = K.pose(name, RAMPS["l5_computadora"])
    a = np.array(hand)
    m = a[..., 3] > 0
    for y in (14, 25):
        a[y, m[y], :3] = K.hexc("#1c222b")[:3]
    for x in range(a.shape[1]):
        if x % 9 == 4:
            for y in range(14, 25):
                if m[y, x]: a[y, x, :3] = K.hexc("#38424f")[:3]
    for x, y in ((12, 16), (40, 16), (12, 23), (40, 23)):
        if m[y, x]: a[y, x, :3] = K.hexc("#e4ecf4")[:3]
    return Image.fromarray(a)


def cables(L):
    for i, c in enumerate(("#d63a30", "#1c1424", "#f2c93a")):
        x0 = HX + 22 + i * 5
        for y in range(0, HY + 6):
            L.px([(x0 + int(1.5 * math.sin(y / 3 + i)), y)], c)


def lens(L, x, y, on=1.0):
    L.ellipse(x - 5, y - 5, x + 5, y + 5, "#4a5666"); L.ellipse(x - 4, y - 4, x + 4, y + 4, "#2a0a0a")
    L.ellipse(x - 3, y - 3, x + 3, y + 3, "#d81a14" if on > .5 else "#7a0a0a")
    if on > .5: L.ellipse(x - 1, y - 1, x + 1, y + 1, "#ff7a4a"); L.px([(x - 1, y - 2)], "#ffffff")


def computadora_a():
    hand = metal("abierta")
    lx, ly = HX + 28, HY + 18
    frames = [frame("espacio", hand, behind=[lay(cables)], front=[lay(lambda L: lens(L, lx, ly))])]
    sweep = [None, 30, 50, 70, 90, 104, 90, 70, 50, 30, None, None]
    for k, y in enumerate(sweep):
        def scan(L, y=y, k=k):
            lens(L, lx, ly, 1 if k % 2 == 0 else .3)
            if y is not None:
                L.line([(lx, ly + 4), (8, y), (K.SW - 8, y), (lx, ly + 4)], "#ff3a2a")
            if 3 <= k <= 9: K.text(L, "LO SIENTO", 70, 100, "#ff5a4a")
        sc = K.Layer()
        if y is not None:
            arr = np.zeros((K.SH, K.SW, 4), np.uint8)
            arr[y - 1:y + 2, 8:K.SW - 8] = (255, 40, 30, 110)
            sc.im = Image.fromarray(arr)
        frames.append(frame("espacio", hand, behind=[lay(cables)], front=[(sc.im, (0, 0)), (_noline(scan), (0, 0))]))
    return frames


M = ["#141a22", "#2a323e", "#4a5464", "#6e7a8c", "#98a4b4", "#c8d2de", "#eef4fa"]


def claw(open_amount, led, t=0):
    """Garra de tres pinzas con más textura: brazo de placas con remaches, franja de peligro, rejilla de ventilación,
    pistones hidráulicos a los costados, rótula con tornillos, ojo rojo y pinzas en segmentos con filo claro."""
    L = K.Layer(61, 66)
    # brazo: cilindro de placas
    L.rect(21, 0, 39, 20, M[3]); L.rect(21, 0, 23, 20, M[4]); L.rect(24, 0, 25, 20, M[5]); L.rect(36, 0, 39, 20, M[2])
    for y in (5, 13): L.rect(21, y, 39, y, M[1]); L.rect(21, y + 1, 39, y + 1, M[4])
    for x, y in ((23, 3), (37, 3), (23, 11), (37, 11), (23, 18), (37, 18)): L.px([(x, y)], M[6])
    for i, x in enumerate(range(26, 35, 2)):          # rejilla
        L.rect(x, 7, x, 11, M[0])
    for x in range(21, 40):                          # franja de peligro
        L.px([(x, 15), (x, 16)], "#f2c93a" if ((x + 1) // 2) % 2 else "#1c1424")
    # pistones a los costados
    ext = int(3 * open_amount)
    for side in (-1, 1):
        x = 30 + side * 13
        L.rect(x - 1, 4, x + 1, 22, M[2]); L.rect(x - 1, 4, x - 1, 22, M[4])
        L.rect(x - 1, 22, x + 1, 26 + ext, M[5]); L.px([(x, 23)], M[6])
        L.line([(30 + side * 9, 2), (x, 4)], M[1])
    # mangueras
    for y in range(0, 22):
        L.px([(19 + int(1.5 * math.sin(y / 2.5 + t)), y)], "#b01226" if y % 4 else "#d63a30")
        L.px([(41 + int(1.5 * math.sin(y / 2.5 + 2 + t)), y)], "#2a6ae0" if y % 4 else "#5c8ad8")
    # rótula
    L.ellipse(18, 18, 42, 36, M[2]); L.ellipse(19, 18, 40, 34, M[3]); L.ellipse(20, 19, 32, 27, M[4]); L.px([(23, 21), (24, 21)], M[6])
    for a in range(0, 360, 60):
        L.px([(30 + round(10 * math.cos(math.radians(a))), 27 + round(7 * math.sin(math.radians(a))))], M[1])
    L.ellipse(25, 22, 35, 32, M[0]); L.ellipse(26, 23, 34, 31, "#3a0a0a")
    L.ellipse(27, 24, 33, 30, "#d81a14" if led else "#5a0a0a")
    if led: L.ellipse(29, 26, 31, 28, "#ff7a4a"); L.px([(28, 25)], "#ffffff")
    # pinzas: dos segmentos cada una
    for side in (-1, 1):
        ang = math.radians(16 + 32 * open_amount) * side
        bx, by = 30 + side * 7, 33
        mid = (bx + math.sin(ang) * 11, by + math.cos(ang) * 11)
        tip_ang = ang - side * math.radians(28)
        tip = (mid[0] + math.sin(tip_ang) * 12, mid[1] + math.cos(tip_ang) * 12)
        n1 = (math.cos(ang) * 3, -math.sin(ang) * 3)
        L.poly([(bx - n1[0], by - n1[1]), (bx + n1[0], by + n1[1]), (mid[0] + n1[0], mid[1] + n1[1]), (mid[0] - n1[0], mid[1] - n1[1])], M[3])
        L.line([(bx - side * 2, by), (mid[0] - side * 2, mid[1])], M[5])
        n2 = (math.cos(tip_ang) * 2.4, -math.sin(tip_ang) * 2.4)
        L.poly([(mid[0] - n2[0], mid[1] - n2[1]), (mid[0] + n2[0], mid[1] + n2[1]), tip], M[4])
        L.line([mid, tip], M[6])
        L.ellipse(mid[0] - 2, mid[1] - 2, mid[0] + 2, mid[1] + 2, M[2]); L.px([(int(mid[0]), int(mid[1]))], M[6])
    # pinza del medio, de frente
    L.poly([(27, 34), (33, 34), (32, 46), (30, 52), (28, 46)], M[3]); L.line([(29, 35), (29, 46)], M[5]); L.px([(30, 51)], M[6])
    return L.done()


def computadora_b():
    frames = [frame("espacio", claw(0, True), behind=[lay(cables)])]
    for k, o in enumerate([.3, .7, 1, 1, .5, 0, .5, 1, 1, .5, 0, 0]):
        frames.append(frame("espacio", claw(o, k % 2 == 0, k * .6), dy=(2 if o == 0 and k in (5, 10) else 0), behind=[lay(cables)]))
    return frames


# ------------------------------------------------------------------ horizonte
def stretched(scale, glow=True):
    ramp = RAMPS["l6_horizonte"]
    base = K.pose("abierta", ramp)
    if glow: base = K.tint_edges(base, "#ffb347", .7)
    h = int(53 * scale)
    a = np.array(base)
    out = np.zeros((h + 20, 61, 4), np.uint8)
    for y in range(h):
        sy = min(52, int(y / scale) if y > 20 else y)
        if y > 20: sy = 20 + int((y - 20) / ((h - 20) / 32.0))
        out[y] = a[min(52, sy)]
    img = Image.fromarray(out)
    L = K.Layer(61, h + 20)
    rng = np.random.default_rng(int(scale * 100))
    for cx, b in K.tips(img, 20):   # estelas hacia el agujero
        n = int(4 + 10 * (scale - 1))
        for k in range(n):
            L.px([(int(cx) + int(rng.integers(-1, 2)), b + 2 + k * 2)], "#ffb347" if k < n // 2 else "#c8581a")
    img.alpha_composite(L.im)
    return K.outline(img, (40, 8, 30, 255))


def horizonte_a():
    frames = [frame("agujero_negro", stretched(1.15))]
    for s in (1.25, 1.4, 1.6, 1.75, 1.75, 1.6, 0.9, 1.05, 0.97, 1.12, 1.15, 1.15):
        frames.append(frame("agujero_negro", stretched(s)))
    return frames


def accretion(L, cx, cy, phase, fast=False):
    """Agujero negro chico: disco de acreción de 22×7 que gira (los puntos de atrás quedan detrás del agujero)."""
    def ring(front):
        for i in range(60):
            a = phase + i * 2 * math.pi / 60
            for rr, k in ((20, 0), (17, 1), (14, 2)):
                x, y = cx + rr * math.cos(a), cy + rr * .32 * math.sin(a)
                if (math.sin(a) >= 0) == front:
                    c = ("#fff0c0", "#ffb347", "#c8581a", "#7a2b00")[(i // (2 if fast else 4) + k) % 4]
                    L.px([(int(x), int(y))], c)
    ring(False)
    L.ellipse(cx - 7, cy - 7, cx + 7, cy + 7, "#2a0a20"); L.ellipse(cx - 6, cy - 6, cx + 6, cy + 6, "#000000")
    ring(True)


def horizonte_b():
    hand = K.outline(K.tint_edges(K.pose("abierta", RAMPS["l6_horizonte"]), "#ffb347", .5), (40, 8, 30, 255))
    cx, cy = HX + 26, HY + 62
    parts = [(cx - 40, cy - 10), (cx + 36, cy + 12), (cx - 22, cy + 22), (cx + 30, cy - 18)]
    frames = []
    for k in range(13):
        def bh(L, k=k):
            fast = 1 <= k <= 10
            accretion(L, cx, cy, k * (0.9 if fast else 0.15), fast)
            for j, (px, py) in enumerate(parts):
                t = min(1.0, max(0.0, (k - 1 - j) / 6)) if fast else 0
                ang = t * 3.5 + j
                r = (1 - t) * math.dist((px, py), (cx, cy))
                if r > 3: L.px([(int(cx + r * math.cos(ang + math.atan2(py - cy, px - cx))), int(cy + r * .5 * math.sin(ang + math.atan2(py - cy, px - cx))))], "#fff0c0")
        frames.append(frame("agujero_negro", hand, front=[(_noline(bh), (0, 0))]))
    return frames


# ------------------------------------------------------------------ relojero
def watchmaker(name):
    hand = K.pose(name, SKIN)
    hand = cuff(hand, 0, 10, "#5a3a1a", stripes=[(9, "#2a1a0a")])
    a = np.array(hand)
    for x, y in ((24, 3), (34, 5), (29, 7)):    # engranajes bordados
        for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 0), (0, -1)):
            if a[y + dy, x + dx, 3]: a[y + dy, x + dx, :3] = K.hexc("#d9b24a" if (dx, dy) != (0, 0) else "#6e4e12")[:3]
    return Image.fromarray(a)


def pocket_watch(L, x, y, hand_angle):
    L.ellipse(x - 6, y - 6, x + 6, y + 6, "#d9b24a"); L.ellipse(x - 5, y - 5, x + 5, y + 5, "#f6e08c")
    L.ellipse(x - 4, y - 4, x + 4, y + 4, "#fff6e0"); L.rect(x - 1, y - 9, x + 1, y - 7, "#d9b24a")
    for i in range(12):
        a = i * math.pi / 6
        L.px([(x + round(3.6 * math.cos(a)), y + round(3.6 * math.sin(a)))], "#a8801f") if i % 3 == 0 else None
    L.line([(x, y), (x + round(3 * math.cos(hand_angle)), y + round(3 * math.sin(hand_angle)))], "#1c1424")
    L.line([(x, y), (x, y - 2)], "#1c1424")


def relojero_a():
    hand = watchmaker("puño")
    pivot = (HX + 22, HY + 38)
    L0 = 26

    def watch(deg, k):
        def f(L):
            a = math.radians(deg)
            x, y = pivot[0] + L0 * math.sin(a), pivot[1] + L0 * math.cos(a)
            for i in range(0, L0 - 8, 2):
                t = i / L0
                L.px([(int(pivot[0] + (x - pivot[0]) * t), int(pivot[1] + (y - pivot[1]) * t))], "#d9b24a")
            pocket_watch(L, int(x), int(y), k * 0.9)
        return lay(f)
    frames = [frame("agujero_negro", hand, front=[watch(0, 0)])]
    for k, d in enumerate([12, 22, 26, 22, 12, 0, -12, -22, -26, -22, -12, 0]):
        frames.append(frame("agujero_negro", hand, front=[watch(d, k + 1)]))
    return frames


def melted_clock(L, x, y, hand_angle):
    L.poly([(x, y), (x + 16, y - 2), (x + 18, y + 4), (x + 12, y + 6), (x + 10, y + 14), (x + 7, y + 7), (x + 1, y + 6)], "#f2e6c0")
    L.poly([(x + 7, y + 7), (x + 10, y + 14), (x + 9, y + 18), (x + 8, y + 12)], "#f2e6c0")
    L.line([(x + 1, y + 1), (x + 16, y - 1)], "#d9b24a")
    cx, cy = x + 8, y + 3
    L.line([(cx, cy), (cx + round(4 * math.cos(hand_angle)), cy + round(2 * math.sin(hand_angle)))], "#1c1424")
    L.line([(cx, cy), (cx - 2, cy - 1)], "#1c1424")


def relojero_b():
    hand = watchmaker("abierta")
    clock_at = (HX + 18, HY + 33)
    sand_x = HX + 12
    frames = []
    for k in range(13):
        rev = 1 <= k <= 4
        frozen = 5 <= k <= 8

        def scene_(L, k=k):
            ang = (-k * 1.6) if rev else (k * 0.2)
            melted_clock(L, clock_at[0], clock_at[1], ang)
            for i in range(10):
                if frozen: y = HY + 46 + i * 6
                elif rev: y = HY + 46 + ((i * 6 - k * 5) % 60)
                else: y = HY + 46 + ((i * 6 + k * 3) % 60)
                L.px([(sand_x + (i % 2), y), (sand_x + (i % 2), y + 1)], "#e8c98a")
        frames.append(frame("agujero_negro", hand, front=[lay(scene_)]))
    return frames


# ------------------------------------------------------------------ durmiente
def tentacle_hand(curl=0.0, eye=0.0, look=0):
    ramp = RAMPS["l6_durmiente"]
    a = np.array(K.pose("abierta", ramp))
    a[26:, :40] = 0                 # se sacan los dedos (queda el dorso y el pulgar)
    img = K.grow(Image.fromarray(a), 61, 70)
    L = K.Layer(61, 70)
    for i, x0 in enumerate((5, 13, 21, 29, 36)):
        length = 26 + (i % 2) * 6
        prev = None
        for s in range(length):
            t = s / length
            x = x0 + 4 + math.sin(t * 4 + i + curl * 3) * (2 + 5 * t) * (1 + curl)
            y = 22 + s
            r = 3.4 * (1 - t) + 0.8
            L.ellipse(x - r, y - r, x + r, y + r, ramp[2] if s % 5 else ramp[1])
            if s % 4 == 2 and r > 1.5: L.px([(int(x - r + 1), int(y))], ramp[4])
            prev = (x, y)
    t_img = L.done()
    out = Image.new("RGBA", (61, 70), (0, 0, 0, 0))
    out.alpha_composite(t_img)
    out.alpha_composite(img)
    out = K.specks(out, [ramp[1], ramp[3]], 30, 4, 26, seed=6)   # escamas
    E = K.Layer(61, 70)
    ex, ey = 26, 15
    if eye <= 0.05:
        E.line([(ex - 5, ey), (ex + 5, ey)], "#0a2a22")
    else:
        h = max(1, int(4 * eye))
        E.ellipse(ex - 6, ey - h, ex + 6, ey + h, "#f4f0b8")
        E.rect(ex - 1 + look, ey - h + 1, ex + look, ey + h - 1, "#10131c")
    out.alpha_composite(E.done())
    return out


def durmiente_a():
    frames = [frame("agujero_negro", tentacle_hand())]
    seq = [(0.1, .3, 0), (0.2, .7, 0), (0.3, 1, 0), (0.3, 1, -3), (0.3, 1, -3), (0.3, 1, 3), (0.3, 1, 3), (0.2, 1, 0), (0.1, .6, 0), (0, .2, 0), (0, 0, 0), (0, 0, 0)]
    for curl, eye, look in seq:
        frames.append(frame("agujero_negro", tentacle_hand(curl, eye, look)))
    return frames


def webbed(name):
    ramp = RAMPS["l6_durmiente"]
    hand = K.pose(name, ramp)
    a = np.array(hand)
    m = a[..., 3] > 0
    for y in range(26, 44):    # membrana entre dedos
        xs = np.nonzero(m[y, :40])[0]
        if len(xs) > 1:
            for x in range(xs.min(), xs.max()):
                if not m[y, x]: a[y, x] = K.hexc("#164a3b")
    for y in range(4, 40, 3):  # escamas en arco
        for x in range((y // 3) % 2 * 2, 61, 4):
            if m[y, x]: a[y, x, :3] = K.hexc(ramp[1])[:3]
    hand = Image.fromarray(a)
    return K.nails(hand, "#0a2a22", 3, light="#58b085")


def durmiente_b():
    hand = webbed("abierta")
    frames = [frame("agujero_negro", hand)]
    rise = [6, 14, 24, 32, 36, 36, 36, 30, 20, 10, 2, 0]
    for k, r in enumerate(rise):
        def tents(L, k=k, r=r):
            ramp = RAMPS["l6_durmiente"]
            for i, x0 in enumerate((30, 100, 160)):
                for s in range(r):
                    y = K.SH - s
                    x = x0 + math.sin(s / 5 + k * .8 + i) * (3 + s / 8)
                    rr = 4.5 * (1 - s / 40) + 1
                    L.ellipse(x - rr, y - rr, x + rr, y + rr, ramp[2] if s % 6 else ramp[1])
                    if s % 5 == 3 and rr > 2: L.px([(int(x + rr - 1), y)], ramp[4])
        name = "puño" if 2 <= k <= 8 else "abierta"
        frames.append(frame("agujero_negro", webbed(name), behind=[lay(tents)]))
    return frames


DESIGNS = [
    ("l4_tahur", "El Tahúr", "A", "Dados cargados", "Guante de crupier, liga de manga y dos dados entre los dedos. Al clic los tira sobre un paño verde: siempre caen 1 y 1, y vuelven a la mano.", "cierre", tahur_a),
    ("l4_tahur", "El Tahúr", "B", "Pila de fichas", "Puño sobre una pila de fichas de colores. Al clic las corta en dos, las mezcla y una ficha sube girando.", "cierre", tahur_b),
    ("l4_patovica", "El Patovica", "A", "Vos no pasás", "Guante de cuero negro, brazalete STAFF y cable de auricular. Al clic mueve el índice de lado a lado: «NO.».", "cierre", patovica_a),
    ("l4_patovica", "El Patovica", "B", "Soga de terciopelo", "Sostiene la soga roja que va hasta un poste de bronce. Al clic la desengancha (cuelga del poste) y la vuelve a enganchar.", "cierre", patovica_b),
    ("l4_payaso", "El Payaso de la Risa Final", "A", "Flor que moja", "Guante blanco con volado a rayas y una flor en el puño. Al clic la flor tira un chorro de agua.", "cierre", payaso_a),
    ("l4_payaso", "El Payaso de la Risa Final", "B", "Pistola de dedo", "Índice apuntando como pistola. Al clic sale un palito con la banderita «¡PUM!» y papelitos.", "cierre", payaso_b),
    ("l5_visitante", "El Visitante", "A", "Rayo tractor", "Tres dedos largos con ventosas y piel brillante. Al clic prende un rayo verde que levanta un dado, lo hace girar y lo suelta.", "espacio", visitante_a),
    ("l5_visitante", "El Visitante", "B", "Telequinesis", "La misma mano con tres dados flotando. Al clic las ventosas brillan y los dados dan una vuelta alrededor de la mano.", "espacio", visitante_b),
    ("l5_farolero", "El Farolero Cósmico", "A", "Farol de luz", "Puño con un anillo verde y manga negra con vivo verde. Al clic el anillo dibuja un farol de luz que se balancea y se deshace.", "espacio", farolero_a),
    ("l5_farolero", "El Farolero Cósmico", "B", "Farol porteño", "Sostiene un farol de hierro con luz verde. Al clic el farol se hamaca y la luz late.", "espacio", farolero_b),
    ("l5_computadora", "La Computadora de Bordo", "A", "Lente que escanea", "Mano de placas y remaches con cables que suben a la nube y una lente roja en el dorso. Al clic escanea la ventana: «LO SIENTO».", "espacio", computadora_a),
    ("l5_computadora", "La Computadora de Bordo", "B", "Garra", "En vez de mano, una garra de tres pinzas con luz roja. Al clic abre y cierra dos veces.", "espacio", computadora_b),
    ("l6_horizonte", "El Horizonte", "A", "Espaguetización", "Mano estirada hacia el agujero, con borde naranja y estelas. Al clic se estira mucho más y vuelve de golpe.", "agujero_negro", horizonte_a),
    ("l6_horizonte", "El Horizonte", "B", "Agujero en la mano", "Debajo de la mano gira un agujero negro chico con su disco. Al clic el disco se acelera y se traga las partículas cercanas.", "agujero_negro", horizonte_b),
    ("l6_relojero", "El Relojero del Instante", "A", "Péndulo", "Manga de relojero con engranajes bordados y un reloj de bolsillo colgando. Al clic el reloj se hamaca como un péndulo.", "agujero_negro", relojero_a),
    ("l6_relojero", "El Relojero del Instante", "B", "Reloj derretido", "Un reloj blando sobre los dedos y arena que cae. Al clic las agujas van hacia atrás, la arena sube y después queda quieta en el aire.", "agujero_negro", relojero_b),
    ("l6_durmiente", "El Durmiente del Abismo", "A", "Tentáculos", "Los dedos son tentáculos con ventosas; en el dorso, un ojo cerrado. Al clic el ojo se abre, mira a los costados y se cierra.", "agujero_negro", durmiente_a),
    ("l6_durmiente", "El Durmiente del Abismo", "B", "Lo que sube del abismo", "Mano escamosa con membranas y garras. Al clic se cierra y desde abajo suben tres tentáculos que vuelven a hundirse.", "agujero_negro", durmiente_b),
]
