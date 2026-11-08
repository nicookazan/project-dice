"""Bocetos de manos de jefe, niveles 1 a 3 (sin El Gótico, que queda como está).

Cada opción devuelve la lista de cuadros de la escena: el cuadro 0 es la mano en reposo y los siguientes son la animación
del clic (reemplaza piedra, papel o tijera). Coordenadas en px lógicos de la ventana grande (189×110).
"""
from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image

import kit as K

RAMPS = {r[0]: r[1] for r in K.jm.ROWS}
HX, HY = K.HAND_AT


def frame(env, hand, dx=0, dy=0, behind=(), front=()):
    return K.scene(env, [*behind, "NUBE", (hand, (HX + dx, HY + dy)), *front])


def lay(fn):
    L = K.Layer()
    fn(L)
    return (L.done(), (0, 0))


def cuff(img, y0, y1, color, stripes=()):
    img = K.shade_overlay(img, K.area_rows(img, y0, y1), color)
    a = np.array(img)
    for row, c in stripes:
        m = a[row, :, 3] > 0
        a[row, m, :3] = K.hexc(c)[:3]
    return Image.fromarray(a)


def ring_band(img, x0, x1, y, c="#f2d24a", c2="#c9a227", stone=None):
    a = np.array(img)
    for x in range(x0, x1 + 1):
        if a[y, x, 3] > 0: a[y, x] = K.hexc(c)
        if a[y + 1, x, 3] > 0: a[y + 1, x] = K.hexc(c2)
    if stone:
        cx = (x0 + x1) // 2
        a[y, cx] = K.hexc(stone); a[y + 1, cx] = K.hexc(stone)
    return Image.fromarray(a)


def h_finger(img, x0, x1, y, ramp, thick=6):
    """Dedo índice estirado de costado (hacia la derecha), con la rampa de la mano y la uña en la punta."""
    im = K.grow(img, max(img.width, x1 + 3), img.height)
    L = K.Layer(im.width, im.height)
    L.rect(x0, y, x1 - 2, y + thick - 1, ramp[2])
    L.rect(x0, y, x1 - 2, y + 1, ramp[3])
    L.rect(x0, y + thick - 2, x1 - 2, y + thick - 1, ramp[1])
    L.rect(x1 - 1, y + 1, x1, y + thick - 2, ramp[2])
    L.rect(x1 - 4, y + 1, x1 - 1, y + 2, ramp[4])  # uña
    L.px([(x0 + 6, y + 2), (x0 + 6, y + 3)], ramp[1])  # pliegue del nudillo
    f = L.done()
    im.alpha_composite(f)
    return im


# ------------------------------------------------------------------ palomas
P_DOVE = {"h": "#8a91a0", "k": "#1c1424", "b": "#e8a43a", "d": "#5c6270", "g": "#9aa1b0", "i": "#6fa38a", "w": "#c9ced8", "l": "#e8a43a"}
DOVE_SIT = ["..........hhh...", ".........hhkhb..", ".........hhhhb..", "........iiih....", "...dd..ggiig....", "dddggggggggg....",
            ".ddwwwwwgggg....", "..gwwwwwwggg....", "...gwwwwgggg....", "....ggggggg.....", ".......l..l.....", "......ll.ll....."]
DOVE_UP = ["...ww...........", "...www..........", "....wwww........", ".....wwwg....hh.", "......wwgg..hhkb", "dddgggggggggghh.",
           ".ddggggggggggg..", "....gggggggg...."]
DOVE_DOWN = [".............hh.", "dddggggggggghhkb", ".ddgggggggggghh.", "....wwwwggggg...", ".....wwwwgg.....", "......wwww......",
             ".......ww......."]
SKIN_OLD = ["#5a3a30", "#8a5a48", "#b8806a", "#dca890", "#f4d0b8"]


def feathers(img, y1=11):
    """Manga de plumas grises: escamas suaves, luz arriba de cada pluma y un píxel de sombra abajo."""
    img = cuff(img, 0, y1, "#b9c0cc")
    a = np.array(img)
    for y in range(y1):
        for x in range(a.shape[1]):
            if not a[y, x, 3]: continue
            local = (x + (y // 3) * 2) % 4
            if y % 3 == 0 and local in (1, 2): a[y, x, :3] = K.hexc("#e4e8ee")[:3]
            elif y % 3 == 2 and local == 0: a[y, x, :3] = K.hexc("#7b8294")[:3]
        if y == y1 - 1: a[y, a[y, :, 3] > 0, :3] = K.hexc("#5c6270")[:3]
    return Image.fromarray(a)


def dove(kind, flip=False):
    if kind == "sit":
        return K.outline(K.sprite(DOVE_SIT, P_DOVE, flip))
    L = K.Layer(18, 16)
    oy = 4
    wing = {"up": [(6, oy + 4), (11, oy + 4), (5, oy - 4)], "mid": [(5, oy + 4), (12, oy + 4), (2, oy + 1)],
            "down": [(6, oy + 5), (11, oy + 5), (8, oy + 11)]}[kind]
    if kind == "down":
        L.ellipse(2, oy + 2, 13, oy + 7, "#9aa1b0")
    L.poly([(0, oy + 3), (4, oy + 3), (4, oy + 6), (0, oy + 6)], "#5c6270")          # cola
    L.ellipse(2, oy + 2, 13, oy + 7, "#9aa1b0"); L.rect(4, oy + 6, 11, oy + 7, "#7b8294")  # cuerpo
    L.ellipse(11, oy, 15, oy + 4, "#8a91a0"); L.rect(11, oy + 3, 12, oy + 4, "#6fa38a")  # cabeza y cuello
    L.px([(14, oy + 1)], "#1c1424"); L.px([(16, oy + 2)], "#e8a43a")
    L.poly(wing, "#c9ced8"); L.line([wing[0], wing[2]], "#e4e8ee")
    im = K.outline(L.im)
    return im.transpose(Image.FLIP_LEFT_RIGHT) if flip else im


def path(points, n):
    """Interpola n puntos a lo largo de una polilínea."""
    seg = [math.dist(points[i], points[i + 1]) for i in range(len(points) - 1)]
    total = sum(seg)
    out = []
    for k in range(n):
        t = total * k / (n - 1)
        i = 0
        while i < len(seg) - 1 and t > seg[i]:
            t -= seg[i]; i += 1
        u = t / seg[i] if seg[i] else 0
        out.append((points[i][0] + (points[i + 1][0] - points[i][0]) * u, points[i][1] + (points[i + 1][1] - points[i][1]) * u))
    return out


def palomas_a():
    hand = feathers(K.pose("indice_lado", SKIN_OLD))
    hand = K.specks(hand, ["#e8c98a", "#c9a46a"], 10, 16, 32, seed=4)  # migas en los nudillos
    perch = (HX + 45, HY + 9)   # esquina sup. izq. de la paloma posada
    frames = [frame("dia", hand, front=[(dove("sit"), perch)])]
    frames.append(frame("dia", hand, front=[(dove("up"), (perch[0], perch[1] + 3))]))
    route = path([(perch[0], perch[1] + 1), (130, 12), (160, 30), (150, 60), (110, 78), (60, 80), (16, 58), (12, 30), (40, 8), (75, 4), (perch[0] - 4, perch[1] - 2)], 14)
    for k, (x, y) in enumerate(route[1:]):
        nxt = route[min(len(route) - 1, k + 2)]
        going_left = nxt[0] < x - .5
        kind = ("up", "mid", "down", "mid")[k % 4]
        frames.append(frame("dia", hand, front=[(dove(kind, flip=going_left), (int(x), int(y)))]))
    frames.append(frame("dia", hand, front=[(dove("down"), (perch[0], perch[1] + 3))]))
    frames.append(frame("dia", hand, dy=1, front=[(dove("sit"), (perch[0], perch[1] + 1))]))
    frames.append(frame("dia", hand, front=[(dove("sit"), perch)]))
    return frames


def palomas_b():
    """Migas al viento: la paloma de la muñeca aletea y vuelve; la del pulgar da la vuelta a la ventana como en la A."""
    hand = feathers(K.pose("abierta", SKIN_OLD))
    hand = K.specks(hand, ["#e8c98a", "#c9a46a", "#f4dfa8"], 16, 12, 34, seed=7)
    p1, p2 = (HX + 11, HY - 2), (HX + 44, HY + 11)
    frames = [frame("dia", hand, front=[(dove("sit"), p1), (dove("sit", True), p2)])]
    crumbs0 = [(HX + 20 + (i * 7) % 26, HY + 36 + (i * 5) % 10) for i in range(9)]
    route = path([(p2[0], p2[1] - 2), (150, 14), (172, 40), (150, 70), (110, 82), (60, 82), (16, 60), (12, 32), (40, 10), (90, 6), (p2[0] + 6, p2[1] - 6)], 14)
    n = len(route) + 3
    for k in range(1, n + 1):
        dx = (1 if k % 2 else -1) if k <= 3 else 0
        lifts = [0, 0, 2, 5, 8, 10, 10, 9, 6, 3, 1, 0]
        lift = lifts[k] if k < len(lifts) else 0
        flap = ("up", "mid", "down", "mid")[k % 4]
        d1 = (dove("sit") if lift == 0 else dove(flap), (p1[0] - 1, p1[1] - lift))
        if k <= len(route):
            x, y = route[k - 1]
            nxt = route[min(len(route) - 1, k)]
            d2 = (dove(flap, flip=not (nxt[0] < x - .5)), (int(x), int(y)))
        elif k == len(route) + 1:
            d2 = (dove("down", True), (p2[0] + 1, p2[1] + 2))
        else:
            d2 = (dove("sit", True), p2)

        def crumbs(L, k=k):
            for i, (x, y) in enumerate(crumbs0):
                yy = y + (k - 1) * 4 + (i % 3) * 2
                if 2 <= k and yy < 108: L.px([(x, yy)], "#e8c98a")
        frames.append(frame("dia", hand, dx=dx, front=[lay(crumbs), d1, d2]))
    return frames


# ------------------------------------------------------------------ kioskero
def mitten(img, y_end=30):
    """Mitón de lana a rayas que deja las yemas afuera; puño acanalado."""
    a = np.array(img)
    m = a[..., 3] > 0
    out = K.shade_overlay(img, K.area_rows(img, 0, y_end), "#c8402e")
    b = np.array(out)
    for y in range(0, y_end):
        band = (y // 3) % 3
        for x in range(b.shape[1]):
            if not m[y, x]: continue
            if y < 8:
                if x % 2: b[y, x, :3] = (b[y, x, :3] * .7).astype(np.uint8)
            elif band == 1:
                b[y, x, :3] = np.clip(np.array(K.hexc("#ecd8ac")[:3]) * (.55 + .5 * a[y, x, :3].mean() / 255), 0, 255)
            if y == y_end - 1: b[y, x, :3] = K.hexc("#7a2418")[:3]
    return Image.fromarray(b)


def kioskero_a():
    ramp = RAMPS["l1_kioskero"]
    hand = mitten(K.pose("abierta", ramp))

    def pack(L, dy=0):
        x, y = HX + 34, HY + 32 + dy
        L.rect(x, y, x + 16, y + 6, "#f08aa8"); L.rect(x, y, x + 16, y, "#ffc0d4")
        L.rect(x + 5, y + 1, x + 11, y + 5, "#fff6e8"); L.rect(x, y + 6, x + 16, y + 6, "#c0587a")
        L.px([(x + 7, y + 3), (x + 9, y + 3)], "#3a6ae0")
    frames = [frame("dia", hand, front=[lay(pack)])]
    route = path([(HX + 40, HY + 31), (HX + 48, HY + 6), (HX + 56, HY - 6), (HX + 64, HY - 2), (HX + 66, HY + 18), (HX + 58, HY + 30)], 9)
    lift = [0, 2, 1, 0, 0, 0, 0, 0, 1, 0]
    for k, (x, y) in enumerate(route):
        def gum(L, x=x, y=y):
            L.rect(int(x), int(y), int(x) + 2, int(y) + 1, "#ff9ac0"); L.px([(int(x), int(y))], "#ffe0ec")
        dy = lift[k] if k < len(lift) else 0
        frames.append(frame("dia", hand, dy=dy, front=[lay(lambda L, dy=dy: pack(L, dy)), lay(gum)]))
    frames.append(frame("dia", hand, dy=1, front=[lay(lambda L: pack(L, 1))]))
    frames.append(frames[0])
    return frames


def bill_img(c="#8fd48a", edge="#5fae63"):
    L = K.Layer(11, 20)
    L.rect(0, 0, 9, 18, edge); L.rect(1, 1, 8, 17, c)
    L.ellipse(2, 6, 7, 12, edge); L.px([(4, 8), (5, 9), (4, 10)], "#d8f5d2"); L.px([(2, 2), (7, 16)], edge); L.rect(1, 1, 8, 1, "#d8f5d2")
    return L.done()


def kioskero_b():
    ramp = RAMPS["l1_kioskero"]
    hand = K.pose("puño", ramp)
    hand = cuff(hand, 0, 9, "#4a5a8a", stripes=[(8, "#2c3658")])   # buzo de algodón
    hand = ring_band(hand, 14, 34, 10, c="#d8a050", c2="#a8703a")  # gomita de los billetes
    base = bill_img()

    def fan(L_img, tilts):
        out = Image.new("RGBA", (K.SW, K.SH), (0, 0, 0, 0))
        for i, extra in enumerate(tilts):
            ang = (-28 + i * 28) + extra
            b = K.grow(base, 40, 40, 15, 4)
            b = K.rot(b, ang, (19, 5))
            out.alpha_composite(b, (HX + 2 + i * 5, HY + 28))
        return (out, (0, 0))
    frames = [frame("dia", hand, front=[fan(None, (0, 0, 0))])]
    seq = [(8, 0, 0), (0, 8, 0), (0, 0, -8), (8, 0, 0), (0, 8, 0), (0, 0, -8)]
    for t in seq:
        frames.append(frame("dia", hand, dy=1, front=[fan(None, t)]))
    for k in range(6):
        def money(L, k=k):
            K.text(L, "$2", HX + 20, HY + 56 - k * 3, "#f2d24a" if k < 5 else "#c9a227")
        frames.append(frame("dia", hand, front=[fan(None, (0, 0, 0)), lay(money)]))
    return frames


# ------------------------------------------------------------------ payador
def poncho(img):
    img = cuff(img, 0, 11, "#b0302a", stripes=[(4, "#241a14"), (5, "#241a14"), (8, "#f2ead8"), (10, "#241a14")])
    a = np.array(img)
    for x in range(a.shape[1]):   # tientos trenzados
        for y in (11, 12):
            if a[y, x, 3] > 0: a[y, x, :3] = K.hexc("#d29f62" if (x + y) % 2 else "#6e3e1a")[:3]
    return Image.fromarray(a)


SUIT = {"espada": ("#3a6ae0", [".#.", ".#.", ".#.", "###", ".#."]), "basto": ("#2f9a3a", [".#.", "###", ".#.", ".#.", ".#."]),
        "copa": ("#d63a30", ["###", "###", ".#.", ".#.", "###"]), "oro": ("#e0a020", [".#.", "###", "#.#", "###", ".#."])}


def card(suit, big=False):
    L = K.Layer(11, 15)
    L.rect(0, 0, 9, 13, "#f2ead8"); L.rect(1, 1, 8, 12, "#fbf6e8"); L.rect(0, 13, 9, 13, "#b8a888")
    c, g = SUIT[suit]
    if big and suit == "espada":
        L.rect(4, 2, 5, 9, "#9aa8c8"); L.rect(4, 2, 4, 9, "#e6edff"); L.rect(2, 9, 7, 9, "#c9a227"); L.rect(4, 10, 5, 11, "#6e3e1a")
    else:
        for gy, row in enumerate(g):
            for gx, v in enumerate(row):
                if v == "#": L.px([(3 + gx, 4 + gy)], c)
    L.px([(1, 1)], c); L.px([(8, 12)], c)
    return L.done()


def payador_a():
    ramp = RAMPS["l1_payador"]
    hand = poncho(K.pose("abierta", ramp))

    def cards(spread, front_suit="copa", big=False):
        out = Image.new("RGBA", (K.SW, K.SH), (0, 0, 0, 0))
        suits = ["basto", "oro", front_suit]
        for i, s in enumerate(suits):
            c = K.grow(card(s, big and i == 2), 30, 30, 10, 2)
            c = K.rot(c, (i - 1) * -spread, (15, 3))
            out.alpha_composite(c, (HX + 16 + i * 3, HY + 34))
        return (out, (0, 0))
    frames = [frame("dia", hand, front=[cards(18)])]
    for s in (12, 6, 0, 0, 0):
        frames.append(frame("dia", hand, front=[cards(s)]))
    for s in (6, 12, 18, 18, 18, 18):
        def truco(L):
            K.text(L, "¡TRUCO!", HX + 14, HY + 74, "#f2d24a")
        frames.append(frame("dia", hand, front=[cards(s, "espada", True), lay(truco)] if s == 18 else [cards(s, "espada", True)]))
    frames.append(frame("dia", hand, front=[cards(18, "espada", True)]))
    return frames


NOTE = ["..##", "..#.", "..#.", "###.", "##.."]


def payador_b():
    ramp = RAMPS["l1_payador"]
    hand = poncho(K.pose("puño", ramp))

    def pick(L, dy):
        x, y = HX + 30, HY + 37 + dy
        L.poly([(x, y), (x + 6, y), (x + 3, y + 6)], "#d63a30"); L.px([(x + 1, y + 1)], "#ff8a72")

    def guitar(L, wobble=0):
        L.ellipse(30, 86, 150, 150, "#3a2416"); L.ellipse(32, 88, 148, 148, "#c8823a"); L.ellipse(40, 90, 110, 120, "#e0a050")
        L.rect(140, 95, K.SW - 1, 106, "#6b3f1f"); L.rect(140, 96, K.SW - 1, 105, "#3a2416")
        for x in range(150, K.SW, 12): L.rect(x, 96, x, 105, "#c9ced6")
        L.ellipse(78, 92, 102, 116, "#e8d0a0"); L.ellipse(81, 95, 99, 113, "#1c1010")
        for j, y in enumerate((97, 99, 101, 103)):
            for x in range(60, K.SW):
                off = (1 if (x // 3 + j) % 2 else -1) if wobble and 60 < x < 140 else 0
                L.px([(x, y + off)], "#f4ecd8")
    neck = lay(lambda L: guitar(L))
    frames = [frame("tarde" if False else "dia", hand, behind=[neck], front=[lay(lambda L: pick(L, 0))])]
    dys = [10, 24, 40, 50, 30, 12, 0, 0, 0, 0, 0]
    for k, dy in enumerate(dys):
        wob = 3 <= k <= 9

        def notes(L, k=k):
            for j, (x0, s) in enumerate(((70, 0), (96, 2), (122, 4))):
                t = k - 3 - s
                if t >= 0:
                    for gy, row in enumerate(NOTE):
                        for gx, v in enumerate(row):
                            if v == "#": L.px([(x0 + gx + (t % 2) - 20, 86 - t * 6 + gy)], "#f2d24a" if j != 1 else "#fff2d2")
        frames.append(frame("dia", hand, dy=dy, behind=[lay(lambda L, w=wob: guitar(L, w))], front=[lay(lambda L, dy=dy: pick(L, dy)), lay(notes)]))
    return frames


# ------------------------------------------------------------------ cebador
def yerba(img):
    return K.specks(img, ["#4f7a1a", "#6fb02a", "#3f6a14"], 40, 6, 40, seed=11)


def mate_gourd(L, x, y, foam=False):
    L.ellipse(x, y + 3, x + 13, y + 16, "#8a5a2b"); L.ellipse(x + 2, y + 5, x + 6, y + 10, "#b07a3a")
    L.rect(x + 1, y + 1, x + 12, y + 3, "#c9ced6"); L.rect(x + 1, y + 1, x + 12, y + 1, "#ffffff")
    L.rect(x + 2, y + 2, x + 11, y + 2, "#3f7a1a" if not foam else "#d8e6a0")
    L.px([(x + 9, y + 12), (x + 10, y + 11)], "#5e3a1a")


def cebador_a():
    ramp = RAMPS["l2_cebador"]
    hand = yerba(K.pose("puño", ramp))
    hand = cuff(hand, 0, 8, "#e8e0c8", stripes=[(7, "#a89f8a")])   # camisa de campo

    def mate(L, dy=0):
        mate_gourd(L, HX + 17, HY + 33 + dy)
        L.line([(HX + 26, HY + 35 + dy), (HX + 33, HY + 26 + dy)], "#c9ced6"); L.px([(HX + 33, HY + 25 + dy)], "#ffffff")
    frames = [frame("tarde", hand, front=[lay(mate)])]
    dys = [2, 4, 6, 6, 6, 6, 5, 3, 1, 0]
    for k, dy in enumerate(dys):
        def steam(L, k=k, dy=dy):
            for j in range(3):
                t = k - j * 2
                if 0 <= t < 7:
                    x = HX + 21 + j * 3 + (1 if t % 2 else -1)
                    y = HY + 30 + dy - t * 3
                    L.rect(x, y, x + 2 - (t > 4), y + 1, "#f4f0fa" if t < 4 else "#c8c8d8")
        frames.append(frame("tarde", hand, dy=dy, front=[lay(lambda L, dy=dy: mate(L, dy)), (K.Layer().im if False else lay(steam)[0], (0, 0))]))
    return frames


def termo_img():
    L = K.Layer(12, 28)
    L.rect(1, 6, 9, 26, "#c9ced6"); L.rect(2, 6, 3, 26, "#ffffff"); L.rect(7, 6, 9, 26, "#8a929e")
    L.rect(1, 0, 9, 5, "#2a2a30"); L.rect(2, 1, 3, 4, "#4a4a58"); L.rect(4, 0, 6, 0, "#d63a30")
    L.rect(1, 25, 9, 26, "#2a2a30")
    return L.done()


TERMO = Image.open(os.path.join(K.ART, "termo-mesa-v3.png")).convert("RGBA").resize((30, 73), Image.NEAREST)


def cebador_b():
    """Ceba con tu termo: el mismo termo de la mesa, a la escala con la que queda robado (0,42), agarrado del cuerpo."""
    ramp = RAMPS["l2_cebador"]
    hand = yerba(K.pose("puño", ramp))
    hand = cuff(hand, 0, 8, "#e8e0c8", stripes=[(7, "#a89f8a")])
    R = 80
    pad = Image.new("RGBA", (2 * R, 2 * R), (0, 0, 0, 0))
    g = (8, 9)                        # agarre por arriba, junto a la tapa: el cuerpo cuelga hacia la derecha
    spout = (16, 2)
    pad.alpha_composite(TERMO, (R - g[0], R - g[1]))
    grip = (HX + 62, HY + 24)         # a la derecha del puño, con aire: ni el termo ni el chorro pasan por la mano
    fingers = hand.copy()
    fa = np.array(fingers)
    fa[:27] = 0                       # solo los dedos doblados, que cruzan por delante del termo
    fingers = Image.fromarray(fa)

    def termo(angle):
        im = K.rotsprite(pad, angle) if angle else pad
        off = ((im.width - 2 * R) // 2, (im.height - 2 * R) // 2)
        return (im, (grip[0] - R - off[0], grip[1] - R - off[1]))

    def spout_at(angle):
        a = math.radians(angle)
        dx, dy = spout[0] - g[0], spout[1] - g[1]
        return (grip[0] + dx * math.cos(a) + dy * math.sin(a), grip[1] - dx * math.sin(a) + dy * math.cos(a))
    angles = [30, 30, 55, 85, 110, 125, 125, 125, 125, 110, 85, 55, 30]   # reposo inclinado, como lo marcó el autor
    sx115, _ = spout_at(125)
    mx, my = int(sx115) - 7, HY + 63   # el mate, abajo del pico del termo (lugar marcado por el autor)
    frames = []
    for k, ang in enumerate(angles):
        pouring = 4 <= k <= 9
        sx, sy = spout_at(ang)

        def water(L, k=k, sx=sx, sy=sy):
            if not pouring: return
            x0, y0, x1, y1 = sx, sy, mx + 7, my + 2
            for i in range(0, 24):
                t = i / 23
                L.px([(int(x0 + (x1 - x0) * t), int(y0 + (y1 - y0) * t * t + 4 * t))], "#bfe6ff")

        def steam(L, k=k):
            for j in range(2):
                t = k - 6 - j * 2
                if 0 <= t < 6: L.rect(mx + 4 + j * 4, my - 3 - t * 3, mx + 5 + j * 4, my - 2 - t * 3, "#f4f0fa")
        # el termo va delante del puño y los dedos lo envuelven: se redibujan encima solo las filas de los dedos
        frames.append(frame("tarde", hand, behind=[termo(ang)], front=[lay(water), lay(lambda L, k=k: mate_gourd(L, mx, my, foam=k >= 7)), lay(steam)]))
    return frames


# ------------------------------------------------------------------ chamuyero
SKIN_TAN = ["#4a2a14", "#7a4a24", "#a8703a", "#d29a62", "#efc590"]


def bling(img):
    img = cuff(img, 0, 9, "#7a2a9a", stripes=[(0, "#b86ad8"), (3, "#b86ad8")])   # saco de raso
    a = np.array(img)
    for x in range(a.shape[1]):   # cadena dorada
        if a[10, x, 3] > 0: a[10, x, :3] = K.hexc("#f2d24a" if x % 2 else "#c9a227")[:3]
    img = Image.fromarray(a)
    img = ring_band(img, 2, 8, 30, stone="#3ad6c8")
    img = ring_band(img, 10, 17, 35)
    img = ring_band(img, 19, 26, 39, stone="#d6322a")
    img = ring_band(img, 28, 35, 27)
    return img


def chamuyero_a():
    hand = bling(K.pose("abierta", SKIN_TAN))
    watch = K.Layer()
    watch.rect(HX + 26, HY + 4, HX + 32, HY + 10, "#f2d24a"); watch.rect(HX + 27, HY + 5, HX + 31, HY + 9, "#fff6e0")
    watch.px([(HX + 29, HY + 6), (HX + 29, HY + 7), (HX + 30, HY + 7)], "#1c1424")
    w = (watch.done(), (0, 0))
    spots = [(HX + 5, HY + 30), (HX + 13, HY + 35), (HX + 22, HY + 39), (HX + 31, HY + 27), (HX + 29, HY + 4)]
    frames = [frame("tarde", hand, front=[w])]
    for k in range(12):
        def sp(L, k=k):
            i = k // 2
            if i < len(spots): K.star(L, *spots[i], 2 if k % 2 == 0 else 1)
        rotk = [0, 0, 0, 0, 0, 0, 0, 0, -4, -6, -4, 0][k]
        h = K.rot(K.grow(hand, 61, 53), rotk, (30, 0)) if rotk else hand
        frames.append(frame("tarde", h, front=[w if not rotk else (Image.new("RGBA", (1, 1)), (0, 0)), lay(sp)]))
    return frames


def chamuyero_b():
    hand = bling(K.pose("abierta", SKIN_TAN))
    tip = (HX + 22, HY + 48)

    def sign(scale, back=False):
        L = K.Layer()
        w = max(1, int(30 * scale))
        x0 = 82 - w // 2
        L.line([tip, (x0, 74)], "#c9a46a"); L.line([tip, (x0 + w, 74)], "#c9a46a")
        if w > 2:
            L.rect(x0, 74, x0 + w, 86, "#f2d24a" if not back else "#fff6e8")
            L.rect(x0, 86, x0 + w, 86, "#c9a227")
            if scale > .9:
                s = "OFERTA" if not back else "2X1"
                K.text(L, s, 82 - K.text_w(s) // 2, 78, "#d6322a")
        else:
            L.rect(x0, 74, x0 + 1, 86, "#c9a227")
        return (L.done(), (0, 0))
    frames = [frame("tarde", hand, front=[sign(1)])]
    for sc, back in ((.6, False), (.2, False), (0, False), (.2, True), (.6, True), (1, True), (1, True), (1, True), (.6, True), (.2, True), (0, False), (.6, False), (1, False)):
        frames.append(frame("tarde", hand, front=[sign(sc, back)]))
    return frames


# ------------------------------------------------------------------ referí
SKIN_REF = ["#3a2418", "#6a4228", "#9a6a40", "#c8955e", "#ebc08a"]


def grass(img):
    a = np.array(img)
    m = a[..., 3] > 0
    for x in range(4, 44, 3):
        col = np.nonzero(m[:, x])[0]
        if not len(col): continue
        y = 22
        if m[y, x]:
            a[y, x, :3] = K.hexc("#4fae3a")[:3]
            if y - 1 >= 0 and m[y - 1, x]: a[y - 1, x, :3] = K.hexc("#2f7a2a")[:3]
    img = Image.fromarray(a)
    img = K.specks(img, ["#4fae3a", "#2f7a2a"], 14, 18, 28, seed=5)
    return cuff(img, 0, 9, "#1e1e24", stripes=[(8, "#f2ead8")])


def referi_a():
    hand = grass(K.pose("puño", SKIN_REF))

    def whistle(L, dx=0):
        x, y = HX + 20 + dx, HY + 36
        L.line([(HX + 14, HY + 10), (x, y + 2)], "#d63a30")
        L.rect(x, y, x + 9, y + 5, "#c9ced6"); L.rect(x, y, x + 9, y, "#ffffff"); L.rect(x + 9, y + 1, x + 12, y + 3, "#9aa8c8")
        L.ellipse(x + 2, y + 1, x + 5, y + 4, "#8a929e")
    frames = [frame("tarde", hand, front=[lay(whistle)])]
    for k in range(11):
        dx = (1 if k % 2 else -1) if k < 8 else 0

        def waves(L, k=k):
            if k >= 8: return
            for j in range(3):
                r = 4 + ((k + j * 2) % 6) * 3
                cx, cy = HX + 34, HY + 39
                for a in range(-50, 51, 12):
                    L.px([(cx + int(r * math.cos(math.radians(a))), cy + int(r * math.sin(math.radians(a))))], "#ffffff")
            if 2 <= k < 8: K.text(L, "¡PRRT!", HX + 44, HY + 54, "#fff6e8")
        frames.append(frame("tarde", hand, dx=dx, front=[lay(lambda L, dx=dx: whistle(L, dx)), lay(waves)]))
    return frames


def referi_b():
    hand = grass(K.pose("abierta", SKIN_REF))

    def cardx(color, out, flash=False):
        L = K.Layer()
        x, y = HX + 36, HY + 22 + out
        L.rect(x, y, x + 9, y + 13, color); L.rect(x, y, x + 9, y, "#ffffff" if flash else "#ffd0c0")
        return (L.done(), (0, 0))
    frames = [frame("tarde", hand)]
    for out, col in ((4, "#f2c93a"), (9, "#f2c93a"), (13, "#f2c93a"), (13, "#f2c93a"), (9, "#f2c93a"), (4, "#d63a30"), (9, "#d63a30"), (13, "#d63a30"), (13, "#d63a30"), (13, "#d63a30"), (9, "#d63a30"), (4, "#d63a30")):
        frames.append(frame("tarde", hand, behind=[cardx(col, out)]))
    return frames


# ------------------------------------------------------------------ conde
def count_hand(name):
    ramp = RAMPS["l3_conde"]
    hand = K.pose(name, ramp)
    hand = cuff(hand, 0, 8, "#1a1424")
    a = np.array(hand)
    for x in range(a.shape[1]):   # gorguera de encaje
        for y in (8, 9):
            if a[y, x, 3] > 0: a[y, x, :3] = K.hexc("#f4f0fa" if (x + y) % 2 else "#b8b0c8")[:3]
    hand = Image.fromarray(a)
    hand = ring_band(hand, 19, 26, 34, stone="#b01226") if name == "abierta" else ring_band(hand, 26, 35, 30, stone="#b01226")
    return K.nails(hand, "#1a1424", 4, light="#5a4a6a")


def goblet(L, x, y, tilt=0, level=1.0):
    L.poly([(x, y), (x + 12, y), (x + 10, y + 7), (x + 2, y + 7)], "#e6edff")
    top = y + 2
    L.poly([(x + 1, top + tilt), (x + 11, top - tilt), (x + 10, y + 6), (x + 2, y + 6)], "#b01226")
    L.px([(x + 2, y + 1)], "#ffffff")
    L.rect(x + 5, y + 8, x + 7, y + 12, "#9aa8c8"); L.rect(x + 2, y + 13, x + 10, y + 14, "#9aa8c8")


def conde_a():
    hand = count_hand("abierta")
    gx, gy = HX + 14, HY + 46
    frames = [frame("noche", hand, behind=[lay(lambda L: goblet(L, gx, gy))])]
    tilts = [1, 2, 1, 0, -1, -2, -1, 0, 1, 0, 0]
    for k, t in enumerate(tilts):
        def drop(L, k=k):
            if 5 <= k <= 9:
                L.rect(gx + 11, gy + 8 + (k - 5) * 7, gx + 11, gy + 9 + (k - 5) * 7, "#d6203a")
        frames.append(frame("noche", hand, dx=t, behind=[lay(lambda L, t=t: goblet(L, gx + t, gy, t))], front=[lay(drop)]))
    return frames


P_BAT = {"b": "#3a2c4a", "m": "#7a6a92", "e": "#ff5a4a"}
BAT_HANG = ["..b.b..", "..bmb..", ".bmmmb.", "bmmmmmb", "bmmmmmb", "bmmmmmb", ".bmmmb.", ".bebeb.", "..bmb..", "..b.b.."]
BAT_UP = ["b...........b", "bb...b.b...bb", "bmb..bmb..bmb", "bmmbbmmmbbmmb", ".bmmmmemmmmb.", "..b..bmb..b.."]
BAT_DOWN = [".....b.b.....", "....bmmmb....", "bbbbmmemmbbbb", "bmmmmmmmmmmmb", "bmb..bmb..bmb", "b....b.b....b"]


def conde_b():
    hand = count_hand("indice")
    hang = K.outline(K.sprite(BAT_HANG, P_BAT))
    at = (HX + 28, HY + 52)
    frames = [frame("noche", hand, front=[(hang, at)])]
    route = path([(at[0] - 3, at[1] + 4), (50, 90), (20, 60), (40, 30), (12, 12), (60, 6), (150, 20), (165, 60), (125, 90), (at[0] - 3, at[1] + 2)], 13)
    for k, (x, y) in enumerate(route):
        spr = K.outline(K.sprite(BAT_UP if k % 2 == 0 else BAT_DOWN, P_BAT))
        frames.append(frame("noche", hand, front=[(spr, (int(x), int(y)))]))
    frames.append(frame("noche", hand, front=[(hang, at)]))
    return frames


# ------------------------------------------------------------------ lobizón
def wolf_hand(name, ramp=None, amount=1.0, claws=4):
    ramp = ramp or RAMPS["l3_lobizon"]
    hand = K.pose(name, ramp)
    if amount > 0:
        hand = K.fur(hand, ramp[0], ramp[3], seed=9, every=max(2, int(5 - 3 * amount)))
    if claws: hand = K.nails(hand, "#e8e0c8", claws, light="#ffffff")
    a = np.array(hand)
    for x in range(a.shape[1]):   # camisa rota
        for y in range(0, 7):
            if a[y, x, 3] > 0 and (y < 5 or (x % 5) in (1, 2)): a[y, x, :3] = K.hexc("#4a6a9a" if y % 2 else "#3a5480")[:3]
    return Image.fromarray(a)


def lobizon_a():
    hand = wolf_hand("abierta")
    frames = [frame("noche", hand)]
    swipe = [(-4, 0), (-8, 2), (2, 4), (10, 6), (6, 4), (2, 2), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)]
    for k, (dx, dy) in enumerate(swipe):
        def slash(L, k=k):
            if k < 3 or k > 10: return
            c = "#ffffff" if k < 6 else ("#c8ccd3" if k < 9 else "#6b707b")
            for j in range(3):
                x0, y0 = 40 + j * 10, 60 + j * 2
                L.line([(x0, y0), (x0 + 50, y0 + 26)], c, 1)
        frames.append(frame("noche", hand, dx=dx, dy=dy, front=[lay(slash)]))
    return frames


def lerp_ramp(a, b, t):
    out = []
    for ca, cb in zip(a, b):
        x, y = K.hexc(ca), K.hexc(cb)
        out.append("#%02x%02x%02x" % tuple(int(x[i] + (y[i] - x[i]) * t) for i in range(3)))
    return out


def lobizon_b():
    human = ["#5a2e1a", "#8a4a2a", "#b86e44", "#dc9a6a", "#f2c49a"]
    wolf = RAMPS["l3_lobizon"]
    steps = [0, 0, .2, .45, .7, 1, 1, 1, 1, .6, .3, 0, 0]
    frames = [frame("noche", wolf_hand("abierta", human, amount=0.15, claws=0))]
    for k, t in enumerate(steps):
        name = "abierta" if t < .7 else "tijera"
        hand = wolf_hand(name, lerp_ramp(human, wolf, t), amount=max(.15, t), claws=int(4 * t))
        dx = (1 if k % 2 else -1) if 5 <= k <= 8 else 0
        frames.append(frame("noche", hand, dx=dx))
    return frames


DESIGNS = [
    ("l1_kioskero", "El Kioskero", "A", "Mitón y chicle", "Mitón de lana a rayas que deja las yemas afuera y un paquete de chicles entre los dedos. Al clic tira un chicle al aire y lo ataja.", "dia", kioskero_a),
    ("l1_kioskero", "El Kioskero", "B", "Fajo de billetes", "Puño con buzo de algodón y una gomita en la muñeca; tres billetes en abanico. Al clic los cuenta uno por uno y sube «$2», su impuesto.", "dia", kioskero_b),
    ("l1_payador", "El Payador Tramposo", "A", "Mano de truco", "Poncho rojo con tientos trenzados y tres cartas españolas en abanico. Al clic cierra, mezcla y abre con el ancho de espadas: «¡TRUCO!».", "dia", payador_a),
    ("l1_payador", "El Payador Tramposo", "B", "Rasguido", "Puño con púa sobre el mástil de una guitarra que cruza la ventana. Al clic rasguea: vibran las cuerdas y suben tres notas.", "dia", payador_b),
    ("l1_palomas", "El Rey de las Palomas", "A", "Paloma en el índice", "Tu idea: mano cerrada, índice estirado y una paloma parada en él; migas en los nudillos. Al clic la paloma da una vuelta por la ventana y vuelve.", "dia", palomas_a),
    ("l1_palomas", "El Rey de las Palomas", "B", "Migas al viento", "Mano abierta llena de migas, una paloma en la muñeca y otra en el pulgar. Al clic sacude la mano, caen las migas y las dos aletean y vuelven.", "dia", palomas_b),
    ("l2_cebador", "Don Cebador", "A", "El mate", "Yerba pegada a la piel, camisa de campo y el mate con bombilla en el puño. Al clic te lo ofrece (baja hacia vos) y humea.", "tarde", cebador_a),
    ("l2_cebador", "Don Cebador", "B", "Ceba con tu termo", "Sostiene un termo como el tuyo. Al clic lo inclina y ceba un mate que flota abajo: chorro, espuma y vapor.", "tarde", cebador_b),
    ("l2_chamuyero", "El Chamuyero", "A", "Bijouterie", "Saco de raso violeta, cadena, reloj y un anillo en cada dedo. Al clic un brillo recorre los anillos y la mano se acomoda canchera.", "tarde", chamuyero_a),
    ("l2_chamuyero", "El Chamuyero", "B", "Cartel de oferta", "Cuelga un cartel «OFERTA» de un hilo. Al clic el cartel gira y del otro lado dice «2X1».", "tarde", chamuyero_b),
    ("l2_referi", "El Referí del Domingo", "A", "Silbato", "Manga negra de árbitro, pasto en los nudillos y silbato con cordón. Al clic pita: tiembla, salen ondas y «¡PRRT!».", "tarde", referi_a),
    ("l2_referi", "El Referí del Domingo", "B", "Amarilla y roja", "Mano abierta; al clic saca de atrás la amarilla, la guarda y saca la roja.", "tarde", referi_b),
    ("l3_conde", "El Conde Sed", "A", "La copa", "Piel pálida, uñas largas negras, anillo de sello, capa y gorguera. Al clic hace girar la copa y cae una gota roja.", "noche", conde_a),
    ("l3_conde", "El Conde Sed", "B", "Murciélago colgado", "Índice hacia abajo con un murciélago colgado de la uña. Al clic el murciélago sale volando en zigzag y vuelve a colgarse.", "noche", conde_b),
    ("l3_lobizon", "El Lobizón", "A", "Zarpazo", "Pelaje con mechones y garras, camisa rota. Al clic da un zarpazo y quedan tres marcas blancas en el cielo que se apagan.", "noche", lobizon_a),
    ("l3_lobizon", "El Lobizón", "B", "La transformación", "En reposo es una mano casi humana. Al clic le crece el pelo, salen las garras y vuelve a ser mano.", "noche", lobizon_b),
]
