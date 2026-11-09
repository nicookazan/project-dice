"""Bocetos (08/11/2026): animación al clic de los tres guardianes de Dios (nivel 7, cielo), dos ideas por guardián.

Parte del arte del juego (assets/art/pixel-v3/guardianes/, 124×100 px lógicos) sin redibujarlo: cada idea mueve, tapa
o ilumina partes del dibujo original. Las escenas van sobre el panel «cielo» de la ventana grande (189×110 px
lógicos), con el guardián donde lo dibuja el juego.
Uso: py -3.13 tools/art/bocetos-dios/guardianes.py  ->  test-results/bocetos-dios/
"""
from __future__ import annotations

import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as nd

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "bocetos-jefes"))
import kit as K  # noqa: E402

GUARD = os.path.join(K.ART, "guardianes")
OUT = os.path.join(K.ROOT, "test-results", "bocetos-dios")
AT = (4, 2)  # dónde cae el guardián en la ventana grande (543, 5 en pantalla)


def load(name):
    return Image.open(os.path.join(GUARD, f"guardian-{name}-v3.png")).convert("RGBA")


def rgb(s):
    s = s.lstrip("#")
    return np.array([int(s[i:i + 2], 16) for i in (0, 2, 4)] + [255], np.uint8)


def is_color(a, *hexes):
    m = np.zeros(a.shape[:2], bool)
    for h in hexes: m |= np.all(a[..., :3] == rgb(h)[:3], -1) & (a[..., 3] > 0)
    return m


def ease(t):
    return t * t * (3 - 2 * t)


# Oro del dibujo, de oscuro a claro, y su versión encendida (un paso más clara).
GOLD = ["#a06a18", "#d09a28", "#f0c850", "#ffe488", "#fffcf0"]


def brighten_gold(a, mask=None, steps=1, top=3):
    """Sube el oro un paso; no pasa de GOLD[top] (el amarillo claro) para que los rayos no queden blancos."""
    out = a.copy()
    sel = np.ones(a.shape[:2], bool) if mask is None else mask
    for i in range(top):
        m = is_color(a, GOLD[i]) & sel
        out[m] = rgb(GOLD[min(top, i + steps)])
    return out


## Con SPRITE_ONLY los cuadros salen solos, del tamaño del guardián (124×100) y con fondo transparente: así los usa
## tools/art/make_guardianes_clic_v4.py para la hoja del juego. Sin él, sobre el cielo de la ventana (bocetos).
SPRITE_ONLY = False


def scene(img, dx=0, dy=0, over=None):
    """Guardián sobre el cielo de la ventana; `over` = capa extra en coordenadas de la ventana."""
    if SPRITE_ONLY:
        frame = Image.new("RGBA", img.size)
        frame.alpha_composite(img.crop((max(0, -dx), max(0, -dy), img.width, img.height)), (max(0, dx), max(0, dy)))
        if over is not None: frame.alpha_composite(over.crop((AT[0], AT[1], AT[0] + img.width, AT[1] + img.height)))
        return frame
    frame = K.scene("cielo", [(img, (AT[0] + dx, AT[1] + dy))])
    if over is not None: frame.alpha_composite(over)
    return frame


def sparks(layer, cx, cy, r, n, color="#fff6c8", phase=0.0):
    d = ImageDraw.Draw(layer)
    for k in range(n):
        ang = phase + k * 2 * math.pi / n
        x, y = round(cx + math.cos(ang) * r), round(cy + math.sin(ang) * r)
        d.point((x, y), fill=K.hexc(color))
        if r > 6: d.point((round(cx + math.cos(ang) * (r - 2)), round(cy + math.sin(ang) * (r - 2))), fill=K.hexc("#ffe488"))


def ring(layer, cx, cy, r, color, alpha=255):
    d = ImageDraw.Draw(layer)
    c = K.hexc(color)[:3] + (alpha,)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=c)


# ===================================================================== ojo solar (Generala prohibida)
OJO = load("ojo")
OJO_A = np.array(OJO)
EYE_C = (62, 50)
# El ojo (blanco, iris, pupila y su borde rojo) dentro del disco oscuro.
ALMOND = nd.binary_fill_holes(is_color(OJO_A, "#ece0c8", "#b0968c", "#b81c2c", "#6e1020", "#fffcf0")
                              | (is_color(OJO_A, "#d09a28", "#f0c850", "#ffe488", "#a06a18", "#04020a")
                                 & (np.hypot(*np.mgrid[0:100, 0:124][::-1] - np.array(EYE_C)[:, None, None]) < 11)))
AL_Y = np.nonzero(ALMOND.any(1))[0]
AL_TOP, AL_BOT = AL_Y.min(), AL_Y.max()
IRIS = ALMOND & ~is_color(OJO_A, "#ece0c8", "#b0968c")
_Y, _X = np.mgrid[0:100, 0:124]
# La pupila: la raya negra del centro del iris.
PUPIL = is_color(OJO_A, "#04020a") & IRIS & (np.abs(_X - 61.5) <= 2.5) & (_Y >= 44) & (_Y <= 58)
WHITE = rgb("#ece0c8")
LID, LID_EDGE = rgb("#1c1040"), rgb("#04020a")


def eye_closed(a, t):
    """Párpados que bajan y suben hasta encontrarse (t=1 cerrado)."""
    if t <= 0: return a
    out = a.copy()
    mid = (AL_TOP + AL_BOT) / 2
    top_to = AL_TOP + (mid - AL_TOP) * t
    bot_from = AL_BOT - (AL_BOT - mid) * t
    for y in range(AL_TOP, AL_BOT + 1):
        row = ALMOND[y]
        if y <= top_to or y >= bot_from: out[y, row] = LID
        if abs(y - round(top_to)) < 1 or (t >= 1 and abs(y - round(mid)) < 1): out[y, row] = LID_EDGE
    return out


def eye_look(a, dx):
    """Corre el iris y la pupila `dx` px dentro del ojo; lo que queda atrás es blanco."""
    if dx == 0: return a
    out = a.copy()
    out[IRIS] = WHITE
    src = np.roll(IRIS, dx, axis=1) & ALMOND
    out[src] = np.roll(a, dx, axis=1)[src]
    return out


def ojo_a():
    """Parpadeo y mirada: cierra el ojo, lo abre mirando a un lado y al otro, y la corona se enciende al volver al centro."""
    frames = []
    plan = [(0, 0, 0), (.4, 0, 0), (.8, 0, 0), (1, 0, 0), (1, 0, 0), (.5, 0, 0), (0, 0, 0), (0, -3, 0), (0, -4, 0), (0, -4, 0),
            (0, 3, 0), (0, 4, 0), (0, 4, 0), (0, 0, 1), (0, 0, 1), (0, 0, 0)]
    for t, dx, lit in plan:
        a = eye_closed(eye_look(OJO_A, dx), t)
        if lit: a = brighten_gold(a, ~ALMOND)
        frames.append(scene(Image.fromarray(a)))
    return frames


RAYS = (np.hypot(*np.mgrid[0:100, 0:124][::-1] - np.array(EYE_C)[:, None, None]) > 27) & (OJO_A[..., 3] > 0)
SLIT = is_color(OJO_A, "#04020a") & IRIS


def ojo_b():
    """Corona que gira: los rayos dan una vuelta entera (termina igual que empezó: el dibujo no es simétrico a un
    octavo), la pupila se cierra en una raya de un píxel y suelta dos anillos de luz."""
    frames = []
    rays = OJO_A.copy(); rays[~RAYS] = 0
    core = OJO_A.copy(); core[RAYS] = 0
    ys, xs = np.nonzero(PUPIL)
    cxs = (xs.min() + xs.max()) / 2
    n = 16
    for f in range(n):
        ang = -360 * ease(min(1, f / 12))
        r_img = Image.fromarray(rays).rotate(ang, Image.NEAREST, center=EYE_C) if 0 < f < 12 else Image.fromarray(rays)
        c = core.copy()
        narrow = 1.0 if f < 2 else (0.0 if f < 9 else (0.5 if f < 11 else 1.0))
        if narrow < 1:
            keep = np.abs(xs - cxs) <= (0.5 if narrow == 0 else 1.0)
            c[ys[~keep], xs[~keep]] = rgb("#f0c850")
        if 6 <= f <= 9: c = brighten_gold(c, IRIS)
        img = Image.new("RGBA", OJO.size); img.alpha_composite(r_img); img.alpha_composite(Image.fromarray(c))
        over = None
        if 8 <= f <= 13:
            over = Image.new("RGBA", (K.SW, K.SH))
            k = f - 8
            ring(over, AT[0] + EYE_C[0], AT[1] + EYE_C[1], 8 + k * 7, "#fff6c8", 255 - k * 35)
            if k < 3: ring(over, AT[0] + EYE_C[0], AT[1] + EYE_C[1], 5 + k * 7, "#ffe488", 200)
        frames.append(scene(img, over=over))
    return frames


# ===================================================================== figura de luz (Metales suspendidos)
FIG = load("figura")
FIG_A = np.array(FIG)
ORBS = [(5, 80), (118, 80)]
EYES = is_color(FIG_A, "#fffcf0") & (np.mgrid[0:100, 0:124][0] < 40)
STARS = is_color(FIG_A, "#ffe488", "#f0c850") & (np.mgrid[0:100, 0:124][0] > 55) & (np.abs(np.mgrid[0:100, 0:124][1] - 62) < 35)


def orb_glow(layer, cx, cy, r):
    d = ImageDraw.Draw(layer)
    for rr, c in ((r + 2, "#f0c850"), (r, "#ffe488"), (max(1, r - 3), "#fffcf0")):
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=K.hexc(c))


def fig_eyes(a, lit):
    out = a.copy()
    if lit:
        halo = nd.binary_dilation(EYES, iterations=1) & ~EYES & (a[..., 3] > 0)
        out[halo] = rgb("#ffe488")
    return out


def figura_a():
    """Luz en las manos: las dos esferas se inflan y sueltan chispas, los ojos se encienden y las estrellas del manto titilan."""
    frames = []
    star_pts = list(zip(*np.nonzero(STARS)))
    star_pts.sort(key=lambda p: (p[0], p[1]))
    for f in range(16):
        swell = [0, 1, 2, 3, 4, 4, 3, 2, 1, 1, 0, 0, 0, 0, 0, 0][f]
        a = fig_eyes(FIG_A, 3 <= f <= 9)
        img = Image.fromarray(a)
        layer = Image.new("RGBA", FIG.size)
        for cx, cy in ORBS:
            if swell: orb_glow(layer, cx, cy, 6 + swell)
            if 3 <= f <= 8: sparks(layer, cx, cy, 9 + (f - 3) * 3, 8, phase=f * 0.4)
        # Una estrella por cuadro hace una cruz de luz, de arriba abajo.
        if f >= 2 and star_pts:
            y, x = star_pts[(f - 2) % len(star_pts)]
            K.star(type("L", (), {"px": lambda s, pts, c: ImageDraw.Draw(layer).point(pts, fill=K.hexc(c))})(), x, y, 2)
        img.alpha_composite(layer)
        frames.append(scene(img))
    return frames


IDLE_FIG_FRAMES = 24


def figura_reposo():
    """Reposo de la figura de luz (pedido del autor, 08/11/2026): las esferas de las manos respiran despacio y dos
    estrellas del manto titilan por vez. Es un bucle sin pausa; el cuadro 0 es el dibujo de siempre. La flotación (subir
    y bajar) la hace el juego al dibujarla."""
    frames = []
    star_pts = sorted(zip(*np.nonzero(STARS)))
    for f in range(IDLE_FIG_FRAMES):
        s = round(1 - math.cos(2 * math.pi * f / IDLE_FIG_FRAMES))  # 0, 1, 2, 1, 0
        img = Image.fromarray(FIG_A)
        layer = Image.new("RGBA", FIG.size)
        if s:
            for cx, cy in ORBS: orb_glow(layer, cx, cy, 5 + s)
        if f % 3 == 1 and star_pts:
            for k in (0, len(star_pts) // 2):
                y, x = star_pts[(f // 3 * 3 + k) % len(star_pts)]
                d = ImageDraw.Draw(layer)
                d.point([(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)], fill=K.hexc("#ffe488"))
                d.point((x, y), fill=K.hexc("#fffcf0"))
        img.alpha_composite(layer)
        frames.append(scene(img))
    return frames


def metal_die(color_light, color, color_dark):
    s = Image.new("RGBA", (9, 9))
    d = ImageDraw.Draw(s)
    d.rectangle([0, 0, 8, 8], fill=K.hexc("#1c1040"))
    d.rectangle([1, 1, 7, 7], fill=K.hexc(color))
    d.line([(1, 1), (7, 1)], fill=K.hexc(color_light)); d.line([(1, 1), (1, 7)], fill=K.hexc(color_light))
    d.line([(2, 7), (7, 7)], fill=K.hexc(color_dark)); d.line([(7, 2), (7, 7)], fill=K.hexc(color_dark))
    for p in ((3, 3), (5, 5)): d.point(p, fill=K.hexc("#1c1040"))
    return s


IRON = metal_die("#d8dde4", "#9aa2ac", "#5e6670")
COPPER = metal_die("#f0b07a", "#c8763a", "#7e4220")


def figura_b():
    """Metales en el aire: de cada esfera sube un dado (hierro y cobre), queda flotando apagado y se deshace en luz."""
    frames = []
    for f in range(16):
        a = fig_eyes(FIG_A, 5 <= f <= 10)
        img = Image.fromarray(a)
        layer = Image.new("RGBA", FIG.size)
        for (cx, cy), die in zip(ORBS, (IRON, COPPER)):
            if 1 <= f <= 3: orb_glow(layer, cx, cy, 6 + f)  # el cuadro 0 es el reposo, sin brillo extra
            if 1 <= f <= 11:
                rise = ease(min(1, (f - 1) / 5))
                x = round(cx + (14 if cx < 62 else -14) * rise) - 4
                y = round(cy - 30 * rise) - 4 + (1 if f in (8, 10) else 0)
                d = die
                if f >= 7:  # suspendido: pierde el brillo
                    g = np.array(d).astype(float)
                    lum = g[..., :3].mean(-1, keepdims=True)
                    g[..., :3] = g[..., :3] * 0.35 + lum * 0.45
                    d = Image.fromarray(g.astype(np.uint8))
                if f <= 10: layer.alpha_composite(d, (x, y))
                if 7 <= f <= 10: ring(layer, x + 4, y + 4, 7, "#4a2f8c", 220)
                if f >= 10: sparks(layer, x + 4, y + 4, 2 + (f - 10) * 3, 6)
            if 12 <= f <= 13:
                sparks(layer, cx + (14 if cx < 62 else -14), cy - 30, 3 + (f - 12) * 4, 8, "#ffe488", phase=0.3)
        img.alpha_composite(layer)
        frames.append(scene(img))
    return frames


# ===================================================================== dado cósmico (Carcasas suspendidas)
DADO = load("dado")
DADO_A = np.array(DADO)
FACE = rgb("#efe0b8")
PIP = DADO_A[38:43, 51:56].copy()          # pip de 5×5 (borde bordó, centro negro)
PIP_MASK = PIP[..., 3] > 0
COLS, ROWS = (53, 62, 70), (40, 50, 59)
LAYOUT = {1: [(1, 1)], 2: [(0, 0), (2, 2)], 3: [(0, 0), (1, 1), (2, 2)], 4: [(0, 0), (2, 0), (0, 2), (2, 2)],
          5: [(0, 0), (2, 0), (1, 1), (0, 2), (2, 2)], 6: [(0, 0), (2, 0), (0, 1), (2, 1), (0, 2), (2, 2)]}
FACE_AREA = (slice(36, 63), slice(49, 75))
GEM = (slice(36, 45), slice(65, 76))


def face(a, value):
    out = a.copy()
    region = out[FACE_AREA]
    blot = is_color(region, "#04020a", "#6e1020", "#ff4a3a", "#ece0c8", "#ffffff") & (np.mgrid[0:27, 0:26][0] >= 0)
    region[blot] = FACE
    for cx, cy in LAYOUT[value]:
        x, y = COLS[cx] - 2, ROWS[cy] - 2
        sub = out[y:y + 5, x:x + 5]
        sub[PIP_MASK] = PIP[PIP_MASK]
    return out


# Dados satélite: la caja de cada uno (los ocho alrededor de los rayos).
SAT = [(41, 9), (77, 9), (13, 30), (104, 31), (13, 61), (104, 62), (39, 83), (77, 83)]
ORDER = [0, 1, 3, 5, 7, 6, 4, 2]  # sentido horario desde arriba a la izquierda


def lit_sat(a, i, steps=2):
    out = a.copy()
    x, y = SAT[i]
    box = (slice(y, y + 10), slice(x, x + 10))
    sub = out[box]
    m = is_color(sub, "#efe0b8", "#fff6dc", "#c9a36a")
    edge = is_color(sub, "#04020a") & nd.binary_dilation(m, iterations=1)
    sub[m & is_color(sub, "#c9a36a")] = rgb("#ffe488")
    sub[m & ~is_color(sub, "#c9a36a")] = rgb("#ffffff")
    sub[edge] = rgb("#f0c850")  # el contorno se enciende: la luz se ve también sobre el cielo
    return out


def dado_a():
    """Tirada cósmica: la cara grande pasa por todos los números y vuelve al seis; las luces corren por los ocho dados."""
    frames = []
    rolls = [6, 2, 5, 1, 4, 3, 5, 2, 6, 6, 6, 6, 6, 6, 6, 6]
    for f in range(16):
        a = DADO_A if rolls[f] == 6 and (f == 0 or f >= 9) else face(DADO_A, rolls[f])
        for k in range(2):
            if 1 <= f <= 12: a = lit_sat(a, ORDER[(f - 1 + k * 4) % 8])
        dx, dy = ((0, 0), (1, 0), (-1, 0), (0, -1), (1, 0), (0, 1), (-1, 0), (0, 0))[f % 8] if 1 <= f <= 8 else (0, 0)
        if f in (9, 10): a = brighten_gold(a)
        frames.append(scene(Image.fromarray(a), dx, dy))
    return frames


def dado_b():
    """Carcasa suelta: la gema roja salta del dado, sube, se apaga (queda suspendida) y vuelve a su lugar."""
    frames = []
    gem = DADO_A[GEM].copy()
    gem_mask = is_color(gem, "#ff4a3a", "#6e1020", "#ece0c8", "#ffffff", "#04020a")
    gem_img = gem.copy(); gem_img[~gem_mask] = 0
    plain = face(DADO_A, 6)
    for f in range(16):
        if f == 0 or f == 15:
            a = DADO_A.copy(); img = Image.fromarray(a); frames.append(scene(img)); continue
        a = plain.copy()
        img = Image.fromarray(a)
        lift = [0, 3, 9, 15, 19, 21, 22, 22, 23, 22, 21, 16, 9, 3, 0][f]
        g = gem_img.copy()
        if 6 <= f <= 11:  # suspendida: sin color
            gf = g.astype(float); lum = gf[..., :3].mean(-1, keepdims=True)
            gf[..., :3] = gf[..., :3] * 0.25 + lum * 0.55; g = gf.astype(np.uint8)
        layer = Image.new("RGBA", DADO.size)
        layer.alpha_composite(Image.fromarray(g), (GEM[1].start, GEM[0].start - lift))
        if 2 <= f <= 4: sparks(layer, GEM[1].start + 5, GEM[0].start + 4, 3 + f * 2, 6)
        if 6 <= f <= 11: ring(layer, GEM[1].start + 5, GEM[0].start + 4 - lift, 7, "#4a2f8c", 220)
        if f == 14: sparks(layer, GEM[1].start + 5, GEM[0].start + 4, 6, 8, "#ff8a7a")
        img.alpha_composite(layer)
        shake = (1, 0) if f in (1, 14) else ((-1, 0) if f in (2, 13) else (0, 0))
        frames.append(scene(img, *shake))
    return frames


DESIGNS = [
    ("ojo", "Ojo solar", "Generala prohibida", "A", "Parpadeo y mirada", "Cierra el ojo, lo abre mirando a un lado y al otro y, al volver al centro, la corona se enciende.", ojo_a),
    ("ojo", "Ojo solar", "Generala prohibida", "B", "Corona que gira", "Los rayos dan una vuelta entera, la pupila se cierra en una raya y suelta dos anillos de luz.", ojo_b),
    ("figura", "Figura de luz", "Metales suspendidos", "A", "Luz en las manos", "Las esferas de las manos se inflan y sueltan chispas, los ojos se encienden y las estrellas del manto titilan una por una.", figura_a),
    ("figura", "Figura de luz", "Metales suspendidos", "B", "Metales en el aire", "De cada mano sube un dado, hierro y cobre: flotan, pierden el color (suspendidos) y se deshacen en luz.", figura_b),
    ("dado", "Dado cósmico", "Carcasas suspendidas", "A", "Tirada cósmica", "La cara grande pasa por varios números con un temblor y vuelve al seis; las luces corren por los ocho dados chicos.", dado_a),
    ("dado", "Dado cósmico", "Carcasas suspendidas", "B", "Carcasa suelta", "La gema roja salta del dado, sube, se apaga (queda suspendida) y vuelve a su lugar con un golpe.", dado_b),
]

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    index = []
    for gid, name, power, op, title, desc, fn in DESIGNS:
        frames = fn()
        base = f"{gid}-{op}"
        K.save_gif(frames, os.path.join(OUT, base + ".gif"), 3, 110)
        strip = Image.new("RGBA", (K.SW * 4 + 6, K.SH), (0, 0, 0, 255))
        for i, k in enumerate(sorted({0, len(frames) // 4, len(frames) // 2, (3 * len(frames)) // 4})):
            strip.paste(frames[k], (i * (K.SW + 2), 0))
        K.save_x(strip, os.path.join(OUT, base + "-cuadros.png"), 2)
        index.append({"id": gid, "name": name, "power": power, "op": op, "title": title, "desc": desc, "gif": base + ".gif", "frames": len(frames)})
        print(base, len(frames))
    for gid in ("ojo", "figura", "dado"):
        K.save_x(scene(load(gid)), os.path.join(OUT, f"{gid}-hoy.png"), 3)
    json.dump(index, open(os.path.join(OUT, "index.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
