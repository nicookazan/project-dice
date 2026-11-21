"""Tres animaciones de confeti de victoria sobre una captura de la mesa (test-results/copa-mesa.png).

A) cañón del cuadro: sale de la copa hacia arriba y afuera, y cae.  B) lluvia desde el borde de arriba, con vaivén.
C) dos cañones en las esquinas de abajo, con serpentinas.  Piezas de 8 px (4 px lógicos) que giran alternando forma;
cada cuadro dura 100 ms (a saltos). Escribe test-results/copa/confeti-A|B|C.gif.

Ejecutar:  py -3.13 tools/art/bocetos-copa/confeti.py
"""
from __future__ import annotations
import math, os
import numpy as np
from PIL import Image, ImageDraw

os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
OUT = "test-results/copa"
COLORS = [(116, 172, 223), (255, 255, 255), (252, 191, 73), (255, 226, 120), (86, 142, 200)]
W, H = 1440, 900
FRAMES = 40


def piece(d, x, y, i, f, c):
    shape = (i + f) % 3
    w, h = ((8, 8), (12, 4), (4, 12))[shape]
    x, y = int(x) // 4 * 4, int(y) // 4 * 4
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)


def render(name, make):
    rng = np.random.default_rng(7)
    bg = Image.open("test-results/copa-mesa.png").convert("RGB").resize((W, H), Image.LANCZOS)
    parts = make(rng)
    frames = []
    for f in range(FRAMES):
        im = bg.copy(); d = ImageDraw.Draw(im)
        for p in parts:
            pos = p["at"](f)
            if pos is None: continue
            if p.get("streamer"):
                for k, (x, y) in enumerate(pos): piece(d, x, y, k, f, p["c"])
            else:
                piece(d, pos[0], pos[1], p["i"], f, p["c"])
        frames.append(im.resize((960, 600), Image.NEAREST))
    frames[10].save(f"{OUT}/confeti-{name}-cuadro10.png")
    q = [f.quantize(colors=96, dither=Image.Dither.NONE) for f in frames]
    q[0].save(f"{OUT}/confeti-{name}.gif", save_all=True, append_images=q[1:], duration=100, loop=0)
    print("confeti", name)


def cannon(rng):
    out = []
    for i in range(240):
        a = math.radians(rng.uniform(-155, -25)); v = rng.uniform(9, 26)
        t0 = int(rng.integers(0, 3))
        vx, vy = math.cos(a) * v, math.sin(a) * v
        sway = rng.uniform(0, 6.28)
        def at(f, vx=vx, vy=vy, t0=t0, sway=sway):
            t = f - t0
            if t < 0: return None
            x = 1120 + vx * t * 0.8 + math.sin(t * 0.7 + sway) * 6
            y = 164 + vy * t + 0.9 * t * t
            return None if y > H + 20 else (x, y)
        out.append({"at": at, "i": i, "c": COLORS[i % len(COLORS)]})
    return out


def rain(rng):
    out = []
    for i in range(300):
        x0 = rng.uniform(0, W); t0 = int(rng.integers(0, 14)); v = rng.uniform(16, 30); sway = rng.uniform(0, 6.28)
        def at(f, x0=x0, t0=t0, v=v, sway=sway):
            t = f - t0
            if t < 0: return None
            y = -20 + v * t
            return None if y > H + 20 else (x0 + math.sin(t * 0.6 + sway) * 14, y)
        out.append({"at": at, "i": i, "c": COLORS[i % len(COLORS)]})
    return out


def corners(rng):
    out = []
    for i in range(220):
        side = 1 if i % 2 else -1
        ox = 20 if side == 1 else W - 20
        a = math.radians(rng.uniform(-80, -40)) if side == 1 else math.radians(rng.uniform(-140, -100))
        v = rng.uniform(14, 30); t0 = int(rng.integers(0, 3)); vx, vy = math.cos(a) * v, math.sin(a) * v
        sway = rng.uniform(0, 6.28)
        def at(f, ox=ox, vx=vx, vy=vy, t0=t0, sway=sway):
            t = f - t0
            if t < 0: return None
            x = ox + vx * t * 0.8 + math.sin(t * 0.8 + sway) * 5
            y = 780 + vy * t + 0.8 * t * t
            return None if y > H + 20 else (x, y)
        out.append({"at": at, "i": i, "c": COLORS[i % len(COLORS)]})
    for k in range(10):    # serpentinas: una fila de piezas que sigue una trayectoria ondulada y se desenrolla
        side = 1 if k % 2 else -1
        ox = 20 if side == 1 else W - 20
        a = math.radians(rng.uniform(-75, -50)) if side == 1 else math.radians(rng.uniform(-130, -105))
        v = rng.uniform(16, 28); vx, vy = math.cos(a) * v, math.sin(a) * v; ph = rng.uniform(0, 6.28)
        def at(f, ox=ox, vx=vx, vy=vy, ph=ph):
            pts = []
            for j in range(14):
                t = f - j * 0.7
                if t < 0: continue
                x = ox + vx * t * 0.8 + math.sin(t * 0.9 + ph) * 18
                y = 780 + vy * t + 0.8 * t * t
                if y < H + 20: pts.append((x, y))
            return pts
        out.append({"at": at, "streamer": True, "c": COLORS[(k + 1) % 3 + 0]})
    return out


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    render("A", cannon); render("B", rain); render("C", corners)
