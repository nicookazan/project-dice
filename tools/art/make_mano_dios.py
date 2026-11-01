"""Bocetos de la Fase 7: mano, nube y Dios en la grilla lógica (2×2 px de pantalla).

La mano y la nube son conversiones fieles de las figuras recuperadas de assets/art/club-table-v2.png (mismos
polígonos que scripts/backdrop.gd): se reducen a la grilla con promedio por celda, se suavizan respetando
bordes y se pintan con una paleta corta propia de cada figura. Dios conserva el diseño provisional actual
(triángulo dorado con un ojo crema y pupila oscura), llevado a la grilla con rampa corta y luz arriba-izquierda.
Escribe PNG de revisión en test-results/ (no integra nada en el juego).

Ejecutar:  python tools/art/make_mano_dios.py
"""
from __future__ import annotations

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_lib import Canvas, clean_labels, ramp, upscale
from vendedor import to_lab, bilateral, kmeans, lab_to_rgb

PLATE = "assets/art/club-table-v2.png"
S = 1440 / 1586.0   # de píxel de la lámina a píxel de pantalla
CLOUD = [(658, 0), (946, 0), (942, 13), (929, 24), (908, 29), (895, 27), (882, 36), (860, 38), (844, 30),
         (826, 34), (815, 25), (801, 29), (788, 35), (773, 37), (754, 44), (733, 43), (714, 34), (697, 30),
         (679, 28), (665, 20)]
HAND = [(788, 25), (810, 24), (828, 38), (834, 53), (849, 65), (860, 79), (870, 94), (871, 101), (863, 104),
        (853, 102), (842, 90), (841, 82), (832, 78), (817, 83), (815, 92), (810, 98), (800, 98), (794, 92),
        (793, 107), (796, 124), (792, 131), (779, 132), (776, 125), (774, 116), (773, 121), (764, 122), (759, 116),
        (756, 107), (753, 112), (746, 112), (741, 106), (737, 98), (736, 85), (740, 78), (745, 70), (755, 59),
        (763, 53), (770, 46), (782, 40)]
HAND_OFFSET = (-45, 12)    # como en backdrop.gd (la mano además sube y baja 3 px)
CLOUD_OFFSET = (-45, 0)


def convert(poly, k: int, rad: int = 2, sr: float = 7.0, min_size: int = 3):
    """Devuelve (rgba en la grilla lógica, origen en pantalla (x, y) alineado a pares)."""
    plate = Image.open(PLATE).convert("RGB")
    xs, ys = [p[0] for p in poly], [p[1] for p in poly]
    x0, y0, x1, y1 = math.floor(min(xs)), math.floor(min(ys)), math.ceil(max(xs)), math.ceil(max(ys))
    wl, hl = round((x1 - x0) * S / 2), round((y1 - y0) * S / 2)
    m = Image.new("L", (x1 - x0, y1 - y0), 0)
    ImageDraw.Draw(m).polygon([(x - x0, y - y0) for x, y in poly], fill=255)
    mf = np.array(m).astype(np.float32) / 255
    rgb = np.array(plate.crop((x0, y0, x1, y1))).astype(np.float32)

    def box(a):
        return np.array(Image.fromarray(a).resize((wl, hl), Image.BOX))

    mm = box(mf)
    chans = [box(rgb[..., c] * mf) for c in range(3)]
    alpha = mm > 0.5
    rgbs = np.stack([np.where(mm > 1e-3, ch / np.maximum(mm, 1e-3), 0) for ch in chans], -1)
    lab = to_lab(rgbs)
    sm = bilateral(lab, alpha, r=rad, ss=1.2 + 0.3 * rad, sr=sr, iters=2)
    cent = kmeans(sm[alpha], k)
    idx = np.zeros(alpha.shape, np.int32)
    idx[alpha] = np.argmin(((sm[alpha][:, None, :] - cent[None]) ** 2).sum(-1), 1)
    idx = clean_labels(idx, alpha, min_size=min_size, passes=2)
    pal = lab_to_rgb(cent)
    out = np.zeros(alpha.shape + (4,), np.uint8)
    out[alpha, :3] = pal[idx[alpha]]
    out[alpha, 3] = 255
    return out, (x0, y0)


def old_figure(poly, scale_to=(0, 0)):
    """La figura original recortada, a escala de pantalla (RGBA)."""
    plate = Image.open(PLATE).convert("RGB")
    xs, ys = [p[0] for p in poly], [p[1] for p in poly]
    x0, y0, x1, y1 = math.floor(min(xs)), math.floor(min(ys)), math.ceil(max(xs)), math.ceil(max(ys))
    m = Image.new("L", (x1 - x0, y1 - y0), 0)
    ImageDraw.Draw(m).polygon([(x - x0, y - y0) for x, y in poly], fill=255)
    size = (round((x1 - x0) * S), round((y1 - y0) * S))
    im = plate.crop((x0, y0, x1, y1)).resize(size, Image.LANCZOS).convert("RGBA")
    im.putalpha(m.resize(size, Image.LANCZOS))
    return im, (x0, y0)


def god() -> Canvas:
    """Triángulo dorado con ojo (diseño actual): 54×33 lógicos; el ojo queda a 21 px de la punta."""
    gold = ramp("a87a2c", "d2a248", "eac16c", "f6d98a", "fff0b8")
    cream = ramp("a89a7c", "d8cba6", "f6eed4", "fffaea")
    ink = ramp("1a121c", "302532", "4a3c4c")
    cv = Canvas(56, 38)
    # triángulo: punta arriba en x=27.5; luz por la izquierda
    for y in range(1, 36):
        half = (y - 1) * 26.5 / 32
        for x in range(56):
            u = x + 0.5 - 27.5
            if abs(u) <= half and y <= 33:
                edge_l = u + half            # distancia al borde izquierdo
                edge_r = half - u
                if edge_l < 1.6:
                    c = gold[4]
                elif edge_l < 3.6:
                    c = gold[3]
                elif edge_r < 1.6:
                    c = gold[0]
                elif edge_r < 4.0:
                    c = gold[1]
                else:
                    c = gold[2]
                if y >= 32:
                    c = gold[1] if c != gold[4] else gold[3]
                cv.put(x, y, c)
    # ojo
    cx, cy, r = 27.5, 22.0, 9.0
    for y in range(38):
        for x in range(56):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d = math.hypot(dx, dy)
            if d > r:
                continue
            lit = (dx * -0.7 + dy * -0.7) / max(d, 0.001)
            c = cream[2]
            if d > r - 1.2:
                c = cream[0] if lit < 0 else cream[1]
            elif lit > 0.55 and d > r - 3.2:
                c = cream[3]
            cv.put(x, y, c)
    for y in range(38):
        for x in range(56):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d = math.hypot(dx, dy)
            if d <= 4.6:
                cv.put(x, y, ink[1] if d > 3.6 else ink[0])
    cv.put(25, 20, cream[3])
    cv.put(26, 20, cream[3])
    cv.put(25, 21, cream[2])
    return cv


def panel(name: str) -> Image.Image:
    """Panel de exterior nuevo ×2 (802×220) tal como lo ve la ventana central."""
    atlas = Image.open("assets/art/pixel-v3/exteriores-v3.png").convert("RGB")
    order = ["dia", "tarde", "noche", "espacio", "agujero_negro", "cielo"]
    i = order.index(name)
    c, r = i % 2, i // 2
    cell = atlas.crop((c * 402, r * 111, c * 402 + 401, r * 111 + 110))
    return upscale(cell, 2)


def snap2(v: float) -> int:
    return int(round(v / 2.0)) * 2


def main() -> None:
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    os.makedirs("test-results", exist_ok=True)
    hand, (hx, hy) = convert(HAND, 12, rad=1, sr=5.0, min_size=2)
    cloud, (cx0, cy0) = convert(CLOUD, 8, rad=1, sr=6.0, min_size=3)
    g = god()
    Image.fromarray(hand).save("test-results/mano-v3.png")
    Image.fromarray(cloud).save("test-results/nube-v3.png")
    Image.fromarray(cloud).save("assets/art/pixel-v3/nube-v3.png")
    g.save("test-results/dios-v3.png")
    print("mano", hand.shape[1], "x", hand.shape[0], "colores", len({tuple(p) for p in hand[hand[..., 3] > 0][:, :3].tolist()}))
    print("nube", cloud.shape[1], "x", cloud.shape[0], "colores", len({tuple(p) for p in cloud[cloud[..., 3] > 0][:, :3].tolist()}))
    # composiciones sobre las ventanas (pantalla = 1440×900; ventana central desde x=470)
    ox = 470
    for name in ("dia", "noche", "cielo"):
        for tag in ("antes", "despues"):
            base = Image.open("assets/art/environment-v2/exteriores-v2.png").convert("RGB")
            if tag == "antes":
                order = ["dia", "tarde", "noche", "espacio", "agujero_negro", "cielo"]
                i = order.index(name)
                rows, cols = [0, 342, 671, 1024], [0, 768, 1536]
                canvas = base.crop((cols[i % 2], rows[i // 2], cols[i % 2 + 1], rows[i // 2 + 1])).resize((802, 220), Image.LANCZOS).convert("RGBA")
            else:
                canvas = panel(name).convert("RGBA")
            if name != "cielo":
                if tag == "antes":
                    oc, (px, py) = old_figure(CLOUD)
                    canvas.alpha_composite(oc, (round(px * S + CLOUD_OFFSET[0]) - ox, round(py * S + CLOUD_OFFSET[1])))
                    oh, (px, py) = old_figure(HAND)
                    canvas.alpha_composite(oh, (round(px * S + HAND_OFFSET[0]) - ox, round(py * S + HAND_OFFSET[1])))
                else:
                    cn = upscale(Image.fromarray(cloud), 2)
                    canvas.alpha_composite(cn, (snap2(cx0 * S + CLOUD_OFFSET[0]) - ox, snap2(cy0 * S + CLOUD_OFFSET[1])))
                    hn = upscale(Image.fromarray(hand), 2)
                    canvas.alpha_composite(hn, (snap2(hx * S + HAND_OFFSET[0]) - ox, snap2(hy * S + HAND_OFFSET[1])))
            else:
                # Dios: antes = polígono provisional; después = boceto en la grilla
                if tag == "antes":
                    d = ImageDraw.Draw(canvas)
                    c0 = (667 - ox, 105)
                    d.polygon([(c0[0], c0[1] - 35), (c0[0] - 53, c0[1] + 29), (c0[0] + 53, c0[1] + 29)], fill=(234, 193, 108))
                    d.ellipse([c0[0] - 18, c0[1] + 7 - 18, c0[0] + 18, c0[1] + 7 + 18], fill=(246, 238, 212))
                    d.ellipse([c0[0] - 9, c0[1] + 7 - 9, c0[0] + 9, c0[1] + 7 + 9], fill=(48, 37, 50))
                else:
                    gg = upscale(g.image(), 2)
                    canvas.alpha_composite(gg, (667 - ox - 55, 70))
            canvas.convert("RGB").save(f"test-results/f7-{name}-{tag}.png")
    print("ok")


if __name__ == "__main__":
    main()
