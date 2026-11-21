"""Tercera tanda (nubes blancas de la ventana del salón). Segunda tanda de bocetos del vendedor-nube: con el dibujo de la nube de la mesa (pixel-v3/nube-v3.png).

Esa nube no son burbujas: es una masa con borde ondulado, contorno azul oscuro, borde interior claro más grueso
abajo y bandas azules que fluyen en diagonal con un rastro blanco fino. Acá se reproduce ese dibujo en
una silueta grande y se anima moviendo las bandas y la silueta.
Escribe en test-results/vendedor-nube3/ (no integra nada en el juego).

Ejecutar:  py -3.13 tools/art/bocetos-vendedor/nubes2.py
"""
from __future__ import annotations
import math, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from base import scene_layers, W, H

N = 16
TONES = [(7, 66, 163), (12, 78, 202), (28, 103, 240), (43, 130, 251), (71, 154, 249), (109, 183, 250),
         (164, 217, 251), (217, 241, 251)]
YY, XX = np.mgrid[0:H, 0:W].astype(np.float32)


def h2(x, y, s=0):
    n = (x.astype(np.int64) * 374761393 + y.astype(np.int64) * 668265263 + s * 2246822519) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return (n & 0xFFFF) / 65535.0


def flat(mask, base):
    """Base casi plana como las nubes de la ventana: se corta debajo de `base` con un escalón irregular."""
    cut = base + (h2(XX // 6, np.zeros_like(XX), 9) * 6).astype(np.float32)
    return mask & (YY < cut)


def silhouette(blobs, t, scallop=0.10, sc_freq=0.11):
    """Campo suave de elipses fundidas + ondulación del borde (los festones de la nube original)."""
    ph = 2 * math.pi * t / N
    s = np.zeros((H, W), np.float32)
    for cx, cy, rx, ry, ax, ay, f in blobs:
        x = cx + ax * math.sin(ph + f); y = cy + ay * math.sin(ph + f + 1.3)
        q = ((XX - x) / rx) ** 2 + ((YY - y) / ry) ** 2
        s += np.exp(-1.9 * q)
    s += scallop * np.sin(XX * sc_freq + 1.7 * np.sin(YY * 0.05) + ph) * np.sin(YY * sc_freq * 0.8 + 0.5)
    global FIELD
    FIELD = s
    return ndimage.binary_fill_holes(s > 0.62)


def paint(mask, t, speed=1, cell=2, patchy=0.16):
    """Nube de las ventanas del salón: blanca arriba, celestes pálidos abajo, sin contorno, con manchas de bloques."""
    ph = 2 * math.pi * t / N
    ys = np.where(mask.any(axis=1))[0]
    img = np.zeros((H, W, 4), np.uint8)
    if len(ys) == 0: return img
    # arriba y abajo de cada columna: el sombreado sigue la silueta, no el cuadro entero
    top = np.where(mask.any(axis=0), mask.argmax(axis=0), 0).astype(np.float32)
    bot = np.where(mask.any(axis=0), H - 1 - mask[::-1].argmax(axis=0), 0).astype(np.float32)
    rel = (YY - top[None, :]) / np.maximum(bot - top, 1)[None, :]
    cx, cy = XX // cell, YY // cell
    noise = np.sin(cx * 0.9 + ph * speed) * np.sin(cy * 1.3 - ph) * 0.5 + (h2(cx.astype(int), cy.astype(int), 5) - 0.5)
    r = rel + patchy * noise
    # vetas horizontales claras dentro del cuerpo (los listones de las nubes del salón)
    streak = (np.sin(YY * 0.55 + XX * 0.05 + ph * speed) > 0.86) & (rel > 0.3)
    cols = [(255, 255, 255), (243, 247, 247), (193, 226, 251), (159, 212, 251), (131, 202, 250)]
    tone = np.where(r < 0.22, 0, np.where(r < 0.46, 1, np.where(r < 0.72, 2, np.where(r < 0.90, 3, 4))))
    tone = np.where(streak & (tone >= 2), tone - 1, tone)
    for i, c in enumerate(cols):
        img[mask & (tone == i)] = (*c, 255)
    return img


# ---------- A: masa grande y baja, con bandas diagonales (la más fiel a la original)
A = [(80, 330, 110, 62, 4, 2, 0.0), (150, 312, 70, 50, 4, 2, 1.5), (50, 255, 70, 50, 4, 2, 3.0),
     (120, 240, 72, 46, 4, 2, 4.4), (80, 190, 52, 36, 4, 3, 5.5), (160, 360, 66, 36, 3, 2, 2.2)]


def cloud_a(t):
    return paint(flat(silhouette(A, t), 372), t)


# ---------- B: columna alta; bandas que suben y borde que se deshilacha (menos densa)
B = [(100, 336, 100, 58, 3, 2, 0.0), (80, 270, 66, 46, 4, 3, 1.0), (130, 262, 58, 44, 4, 3, 2.0),
     (96, 205, 52, 40, 5, 3, 3.0), (112, 152, 40, 34, 5, 4, 4.0), (84, 112, 30, 28, 5, 5, 5.0),
     (160, 330, 40, 40, 3, 2, 3.5)]


def cloud_b(t):
    mask = silhouette(B, t, scallop=0.12)
    img = paint(flat(mask, 376), t, speed=-1, patchy=0.1)
    # deshilachado: del borde exterior se caen celdas de 2x2, distintas en cada cuadro; arriba cae más
    d = ndimage.distance_transform_edt(mask)
    r = h2((XX // 2), (YY // 2), t // 2 * 7 + 1)
    thresh = np.clip((300 - YY) / 260, 0, 1) * 0.55 + 0.1
    drop = (d <= 5) & (r < thresh)
    img[drop] = 0
    return img


# ---------- C: banco ancho; los festones del borde ruedan hacia la derecha
C = [(50, 352, 90, 46, 6, 2, 0.0), (130, 336, 80, 48, 6, 2, 1.6), (165, 312, 40, 40, 5, 2, 3.2),
     (70, 292, 72, 38, 6, 3, 4.5), (140, 282, 62, 36, 6, 3, 0.8), (14, 300, 44, 40, 4, 2, 2.4)]


def cloud_c(t):
    return paint(flat(silhouette(C, t, scallop=0.12, sc_freq=0.13), 380), t)


def puff(t):
    ph = 2 * math.pi * t / N
    m = silhouette([(244, 192, 24, 20, 1.5, 1, 0.0), (266, 196, 18, 17, 1.5, 1, 2.0), (252, 208, 22, 14, 1, 1, 4.0)], t, scallop=0.08, sc_freq=0.3)
    return paint(flat(m, 214), t, patchy=0.12)


VARIANTS = {"A": ("Masa con bandas", cloud_a), "B": ("Columna que se deshilacha", cloud_b), "C": ("Banco rodante", cloud_c)}
CROP = (0, 70, 340, 400)


def front_hands(hands, M):
    """La mano (sin el puño) y los dedos de la tapa quedan delante de la nube: salen de ella."""
    a = np.array(hands); keep = M["hand_b"] | M["hand_a"]
    a[~keep] = 0
    return Image.fromarray(a)


def frame(layers, v, t):
    bg, mid, hands, band, M = layers
    out = mid.copy(); out.alpha_composite(hands)
    for layer in (puff(t), VARIANTS[v][1](t)):
        out.alpha_composite(Image.fromarray(layer))
    out.alpha_composite(front_hands(hands, M))
    out.alpha_composite(band)
    return out


def main():
    layers = scene_layers()
    outdir = "test-results/vendedor-nube3"; os.makedirs(outdir, exist_ok=True)
    sz = ((CROP[2] - CROP[0]) * 2, (CROP[3] - CROP[1]) * 2)
    for v in VARIANTS:
        fr = [frame(layers, v, t) for t in range(N)]
        fr[0].resize((W * 2, H * 2), Image.NEAREST).save(f"{outdir}/{v}-escena.png")
        cr = [f.crop(CROP).resize(sz, Image.NEAREST) for f in fr]
        cr[0].save(f"{outdir}/{v}-detalle.png")
        cr[0].save(f"{outdir}/{v}.gif", save_all=True, append_images=cr[1:], duration=130, loop=0)
        print(v, "ok")


if __name__ == "__main__":
    main()
