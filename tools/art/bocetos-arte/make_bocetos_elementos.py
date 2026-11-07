"""Bocetos de animación de los elementos (07/11/2026). No toca assets/ ni el juego: escribe en test-results/bocetos-arte/.

Parte de las marcas aprobadas (opción A de make_bocetos_dados.py, las de elementos-v3.png) y agrega movimiento leve:
  A «la marca se mueve»: la llama, el agua, el rayo, las piedras y el remolino laten en su lugar.
  B «la marca queda y suelta partículas»: la marca casi quieta y algo chiquito que sale de ella.
12 cuadros a 120 ms (1,44 s por vuelta). El lado derecho va a media vuelta del izquierdo para que no se vea espejado.
Uso: py -3.13 tools/art/bocetos-arte/make_bocetos_elementos.py
"""
from __future__ import annotations

import importlib.util
import math
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(ROOT, "test-results", "bocetos-arte")
os.makedirs(OUT, exist_ok=True)

_argv = sys.argv
sys.argv = ["make_bocetos_dados.py", os.path.join(OUT, "_dados")]
spec = importlib.util.spec_from_file_location("dados", os.path.join(ROOT, "tools/art/bocetos-texturas/make_bocetos_dados.py"))
dados = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dados)
sys.argv = _argv
os.rmdir(os.path.join(OUT, "_dados"))

L, T, B, SIZE = dados.L, dados.T, dados.B, dados.SIZE
hexc = dados.hexc
FRAMES = 12
MS = 120
FIRE = ["a31808", "ee5a12", "ffc233", "fff4a8"]
TAU = math.tau


def wave(t, a=1.0, b=2, ph=0.0):
    """Mezcla de dos senos enteros: vuelve al inicio y no se ve mecánica."""
    return a * (.65 * math.sin(TAU * (t + ph)) + .35 * math.sin(TAU * b * (t + ph) + 1.3))


def px(d, x, y, col, w=1, h=1):
    d.rectangle((round(x), round(y), round(x) + w - 1, round(y) + h - 1), fill=hexc(col))


def life(t):
    return t % 1.0


# ---------------------------------------------------------------- A: la marca se mueve
def side_a(element, t):
    ov = dados.new_overlay()
    d = ImageDraw.Draw(ov)
    if element == "fire":
        dados.flame(d, L, B + 1, 34 * (1 + wave(t, .11)), 12 * (1 - wave(t, .05, ph=.2)), FIRE, lean=.3 + wave(t, .16, ph=.1))
        dados.flame(d, L - 1, T + 33, 20 * (1 + wave(t, .14, ph=.37)), 9, FIRE, lean=-.3 + wave(t, .18, ph=.5))
        dados.flame(d, L, T + 14, 14 * (1 + wave(t, .16, ph=.68)), 8, FIRE, lean=.3 + wave(t, .2, ph=.75))
    elif element == "water":
        dk, md, lt = "0b3d78", "1a86cf", "9be8fb"
        for i, (dx_, dy_, r) in enumerate(((1, 16, 4.4), (0, 33, 5.0), (2, 49, 4.2))):
            bob = math.sin(TAU * (t + i * .3))
            dados.drop(d, L + dx_, T + dy_ + round(bob), r + bob * .25, dk, md, lt)
        pts = [(L - 2 + i, B + 3 + 2.4 * math.sin(i * .5 - TAU * t)) for i in range(0, 24)]
        d.line(pts, fill=hexc(dk), width=5)
        d.line(pts, fill=hexc(md), width=3)
        k = int(t * 24) % 24
        hi = [(x, y - 1) for x, y in (pts + pts)[k:k + 8]]
        hi = [p for p in hi if p[0] <= L + 21]
        if len(hi) > 1 and hi[0][0] < hi[-1][0]:
            d.line(hi, fill=hexc("e8fdff"), width=1)
    elif element == "electricity":
        step = int(t * 6) % 6  # el rayo salta de a pasos, no se desliza
        jit = [(0, 0, 0, 0), (1, -1, 1, 0), (-1, 1, 0, 1), (1, 0, -1, -1), (0, 1, 1, -1), (-1, -1, 0, 1)][step]
        core = "ffffff" if step in (1, 4) else "fff56a"
        widths = [(6, "7a3d00"), (4, "e08a00"), (2, core)]
        dados.bolt(d, [(L + 6, T - 2), (L + 1 + jit[0], T + 9), (L + 5 + jit[1], T + 16), (L - 1, T + 28)], widths)
        dados.bolt(d, [(L + 5, T + 34), (L + jit[2], T + 43), (L + 4 + jit[3], T + 49), (L - 2, T + 58)], widths)
        for k, (sx, sy) in enumerate(((L + 8, T + 24), (L + 7, T + 52))):
            if (step + k * 3) % 6 in (0, 1, 3):
                d.line([(sx - 2, sy), (sx + 2, sy)], fill=hexc("fff56a"), width=1)
                d.line([(sx, sy - 2), (sx, sy + 2)], fill=hexc("fff56a"), width=1)
    elif element == "earth":
        def lift(ph):  # un temblor corto que pasa de piedra en piedra
            return -1 if life(t + ph) < .17 else 0
        dados.rock(d, L - 4, B - 9 + lift(0), 13, 12)
        dados.rock(d, L + 6, B - 3 + lift(.25), 9, 7, mid="7d5228")
        dados.rock(d, L - 3, T + 31 + lift(.5), 8, 8, mid="86592c")
        dados.rock(d, L - 2, T + 10 + lift(.75), 7, 7, mid="86592c")
        sway = round(math.sin(TAU * t) * 1.4)
        for i, gx in enumerate((L + 11, L + 14)):
            d.line([(gx, B + 3), (gx - 1 + sway, B - 1 - i)], fill=hexc("5c8a3a"), width=2)
    elif element == "wind":
        dados.spiral(d, L, T + 13, 7, 1.4, [4, 2], ["3f9db0", "e6fcff"], 1.2 + TAU * t)
        dados.spiral(d, L, T + 43, 7, 1.4, [4, 2], ["3f9db0", "e6fcff"], .2 + TAU * t)
        off = round(math.sin(TAU * t) * 2)
        d.line([(L - 7 + off, T + 28), (L + 3 + off, T + 27), (L + 6 + off, T + 30)], fill=hexc("bdf2fa"), width=2)
    return ov


# ---------------------------------------------------------------- B: la marca queda y suelta partículas
def side_b(element, t):
    ov = dados.new_overlay()
    d = ImageDraw.Draw(ov)
    if element == "fire":
        dados.flame(d, L, B + 1, 34 * (1 + wave(t, .03)), 12, FIRE, lean=.3)
        dados.flame(d, L - 1, T + 33, 20 * (1 + wave(t, .04, ph=.37)), 9, FIRE, lean=-.3)
        dados.flame(d, L, T + 14, 14 * (1 + wave(t, .05, ph=.68)), 8, FIRE, lean=.3)
        for ph, x0, y0, rise in ((0, L + 2, T + 6, 20), (.33, L - 2, T + 24, 22), (.66, L + 1, T + 38, 26)):
            q = life(t + ph)
            x = x0 + math.sin(TAU * q * 1.5) * 2.2
            y = y0 - rise * q
            col = "fff4a8" if q < .25 else "ffc233" if q < .55 else "ee5a12" if q < .8 else "a31808"
            s = 2 if q < .6 else 1
            px(d, x, y, col, s, s)
    elif element == "water":
        dk, md, lt = "0b3d78", "1a86cf", "9be8fb"
        dados.drop(d, L + 1, T + 16, 4.4, dk, md, lt)
        dados.drop(d, L + 0, T + 33, 5.0, dk, md, lt)
        dados.drop(d, L + 2, T + 49, 4.2, dk, md, lt)
        pts = [(L - 2 + i, B + 3 + 2.4 * math.sin(i * .5 - TAU * t * 1)) for i in range(0, 24)]
        d.line(pts, fill=hexc(dk), width=5)
        d.line(pts, fill=hexc(md), width=3)
        for ph, x0, y0, y1 in ((0, L - 1, T + 21, T + 28), (.5, L + 1, T + 55, B + 1)):
            q = life(t + ph)
            if q < .7:
                g = (q / .7) ** 1.7
                y = y0 + (y1 - y0) * g
                px(d, x0, y, dk, 2, 3)
                px(d, x0, y + 1, lt, 1, 1)
            elif q < .9:  # salpica al llegar
                k = (q - .7) / .2
                px(d, x0 - 1 - 2 * k, y1 - 2 * math.sin(k * 3.14), "e8fdff")
                px(d, x0 + 2 + 2 * k, y1 - 2 * math.sin(k * 3.14), "9be8fb")
    elif element == "electricity":
        widths = [(6, "7a3d00"), (4, "e08a00"), (2, "fff56a")]
        top = [(L + 6, T - 2), (L + 1, T + 9), (L + 5, T + 16), (L - 1, T + 28)]
        low = [(L + 5, T + 34), (L, T + 43), (L + 4, T + 49), (L - 2, T + 58)]
        dados.bolt(d, top, widths)
        dados.bolt(d, low, widths)

        def along(poly, q):
            n = len(poly) - 1
            k = min(int(q * n), n - 1)
            f = q * n - k
            return poly[k][0] + (poly[k + 1][0] - poly[k][0]) * f, poly[k][1] + (poly[k + 1][1] - poly[k][1]) * f

        for poly, ph in ((top, 0), (low, .5)):  # una descarga corre por el rayo y salta al final
            q = life(t + ph)
            if q < .6:
                x, y = along(poly, q / .6)
                px(d, x - 1, y - 1, "ffffff", 3, 3)
                px(d, x - 2, y, "fff56a", 5, 1)
                px(d, x, y - 2, "fff56a", 1, 5)
            elif q < .72:
                x, y = poly[-1]
                for ax, ay in ((-3, 1), (2, 2), (-1, 3), (3, -1)):
                    px(d, x + ax, y + ay, "fff56a")
    elif element == "earth":
        base = dados.new_overlay()
        bd = ImageDraw.Draw(base)
        dados.rock(bd, L - 4, B - 9, 13, 12)
        dados.rock(bd, L + 6, B - 3, 9, 7, mid="7d5228")
        dados.rock(bd, L - 3, T + 31, 8, 8, mid="86592c")
        dados.rock(bd, L - 2, T + 10, 7, 7, mid="86592c")
        ov.alpha_composite(base)
        sway = round(math.sin(TAU * t) * 1.2)
        for i, gx in enumerate((L + 11, L + 14)):
            d.line([(gx, B + 3), (gx - 1 + sway, B - 1 - i)], fill=hexc("5c8a3a"), width=2)
        for ph, x0, y0, y1 in ((0, L - 2, T + 18, T + 31), (.4, L, T + 39, B - 10), (.75, L - 3, T + 41, B - 10)):
            q = life(t + ph)
            if q < .55:
                g = (q / .55) ** 2
                px(d, x0, y0 + (y1 - y0) * g, "d2a468" if q < .25 else "9a6a36", 2, 2)
            elif q < .75:  # polvito al caer
                k = (q - .55) / .2
                px(d, x0 - 2 * k, y1 - k * 2, "c8a878")
                px(d, x0 + 2 + 2 * k, y1 - k, "c8a878")
    elif element == "wind":
        rot = TAU * round(t * 4) / 16  # giro muy lento, a saltitos
        dados.spiral(d, L, T + 13, 7, 1.4, [4, 2], ["3f9db0", "e6fcff"], 1.2 + rot)
        dados.spiral(d, L, T + 43, 7, 1.4, [4, 2], ["3f9db0", "e6fcff"], .2 + rot)
        for ph, y, ln in ((0, T + 27, 8), (.35, T + 3, 6), (.7, T + 52, 7)):  # hilos de aire que cruzan por el costado
            q = life(t + ph)
            x = L - 16 + 24 * q
            col = "bdf2fa" if .2 < q < .75 else "5fb8c8"
            d.line([(x, y), (x + ln, y - 1)], fill=hexc(col), width=1)
    return ov


def overlay(fn, element, t):
    ov = dados.new_overlay()
    ov.alpha_composite(fn(element, t % 1))
    ov.alpha_composite(fn(element, (t + .5) % 1).transpose(Image.FLIP_LEFT_RIGHT))
    return ov


# ---------------------------------------------------------------- salidas
def felt(w, h):
    """Paño real de la mesa (mesa-v3.png, bordó con brocado), repetido en espejo y a escala de pantalla."""
    mesa = Image.open(os.path.join(ROOT, "assets/art/pixel-v3/mesa-v3.png")).convert("RGB")
    crop = mesa.crop((236, 58, 336, 158)).resize((200, 200), Image.NEAREST)
    out = Image.new("RGB", (w, h))
    for y in range(0, h, 200):
        for x in range(0, w, 200):
            t = crop
            if (x // 200) % 2:
                t = t.transpose(Image.FLIP_LEFT_RIGHT)
            if (y // 200) % 2:
                t = t.transpose(Image.FLIP_TOP_BOTTOM)
            out.paste(t, (x, y))
    return out.convert("RGBA")


def apng(frames, path, scale):
    big = [f.convert("RGB").resize((f.width * scale, f.height * scale), Image.NEAREST) for f in frames]
    big[0].save(path, save_all=True, append_images=big[1:], duration=MS, loop=0, format="PNG", optimize=True)


def main():
    die6 = dados.base_die(6)
    bg = felt(SIZE, SIZE)
    for name, fn in (("A", side_a), ("B", side_b)):
        strips = []
        for element in dados.ELEMENT_ORDER:
            frames = []
            for i in range(FRAMES):
                f = bg.copy()
                f.alpha_composite(die6)
                f.alpha_composite(overlay(fn, element, i / FRAMES))
                frames.append(f)
            apng(frames, os.path.join(OUT, f"elem-{name}-{element}.png"), 3)
            strip = Image.new("RGB", (SIZE * 6, SIZE))
            for k in range(6):
                strip.paste(frames[k * 2].convert("RGB"), (k * SIZE, 0))
            strips.append(strip)
        sheet = Image.new("RGB", (SIZE * 6, SIZE * 5))
        for j, strip in enumerate(strips):
            sheet.paste(strip, (0, j * SIZE))
        sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(os.path.join(OUT, f"_tira-{name}.png"))

        # cinco dados en la mesa, a tamaño real de pantalla y con la vuelta corrida en cada uno
        values = [5, 3, 6, 2, 4]
        phases = [0, .37, .71, .19, .53]
        wide = 5 * 84 + 12
        row_bg = felt(wide, SIZE + 8)
        frames = []
        for i in range(FRAMES):
            f = row_bg.copy()
            for k, element in enumerate(dados.ELEMENT_ORDER):
                x, y = k * 84 - 2, 4
                f.alpha_composite(dados.base_die(values[k]), (x, y))
                f.alpha_composite(overlay(fn, element, i / FRAMES + phases[k]), (x, y))
            frames.append(f)
        apng(frames, os.path.join(OUT, f"elem-{name}-mesa.png"), 1)
    # hoy: la marca fija, para comparar
    for element in dados.ELEMENT_ORDER:
        f = bg.copy()
        f.alpha_composite(die6)
        f.alpha_composite(dados.opcion_a(element))
        f.convert("RGB").resize((SIZE * 3, SIZE * 3), Image.NEAREST).save(os.path.join(OUT, f"elem-hoy-{element}.png"))
    print("listo:", OUT)


if __name__ == "__main__":
    main()
