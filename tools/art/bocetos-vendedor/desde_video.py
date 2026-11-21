"""Boceto del vendedor-nube a partir del video del autor (gemini_generated_video_76720c46.mp4).

El video ya está en la grilla del juego: cada celda mide 4 px, así que 1 celda = 1 px lógico de la escena (720×450). Se
toman fotogramas cada 0,25 s, se separa lo que no es fondo negro (nube, mano y volutas), se pasa a la grilla muestreando el
centro de cada celda y se coloca sobre la tienda sin vendedor, con la punta de la mano en el borde de la tapa.
Escribe en test-results/vendedor-nube10/ (no integra nada en el juego).

Ejecutar:  py -3.13 tools/art/bocetos-vendedor/desde_video.py <carpeta con f00.png … fNN.png> [--v2 | --v3 | --v4]

Versión 4 (--v4): cuerpo estático de la v3 con todas las volutas y puffs de la v2.
Versión 3 (--v3): igual que la 2, pero el cuerpo de la nube queda estático; solo se mueven volutas y puffs.

Versión 2 (--v2): la nube y las volutas del video, pero con la mano original del juego, estática y en su posición
(punta en el borde de la tapa). La mano del video se quita y se rellena de nube; los puños quedan tapados por la nube.
"""
from __future__ import annotations
import glob, os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from base import scene_layers, W, H
from scipy import ndimage

CELL = 4
OX, OY = 10, 165          # dónde cae la esquina superior izquierda del video en la escena (px lógicos)
BG_DIST = 45


def to_grid(path, phase=2):
    a = np.array(Image.open(path).convert("RGB")).astype(int)
    g = a[phase::CELL, phase::CELL]                                   # una muestra por celda
    bg = np.array([16, 14, 20])
    mask = np.abs(g - bg).sum(axis=2) > BG_DIST
    return g, mask


OX2, OY2 = 19, 171       # versión 2: la punta de la mano del video cae en la punta de la mano original
SOFT = np.array([243, 247, 247])


def orange(g):
    r, gg, b = g[..., 0], g[..., 1], g[..., 2]
    return (r > 110) & (r - b > 40) & (gg < r - 10)


def estaticas(layers, viento=False):
    """Versión 3: el cuerpo de la nube queda fijo (lo que está presente en más de la mitad de los cuadros) y solo se
    mueven las volutas y los puffs sueltos. Los bordes del cuerpo que cambiaban de un cuadro a otro se descartan."""
    A = np.stack([l[..., 3] > 0 for l in layers])
    body = ndimage.binary_opening(A.mean(axis=0) > 0.5, structure=np.ones((3, 3)))
    rgb = np.stack([l[..., :3] for l in layers]).astype(float)
    body_rgb = np.zeros((H, W, 3), np.uint8)
    for c in range(3):
        v = np.where(A, rgb[..., c], np.nan)
        body_rgb[..., c] = np.nan_to_num(np.nanmedian(v, axis=0), nan=0).astype(np.uint8)
    near = ndimage.binary_dilation(body, iterations=2)
    out = []
    for l, a in zip(layers, A):
        cand = a & ~near
        lab, n = ndimage.label(cand, structure=np.ones((3, 3)))
        keep = np.zeros_like(cand)
        touch = ndimage.binary_dilation(body, iterations=4)
        for i in range(1, n + 1):
            comp = lab == i
            if comp.sum() < 5: continue                          # motas sueltas del borde: ruido
            if viento and (comp & touch).any() and l[comp, :3].astype(int).sum(axis=1).mean() < 600: continue   # contorno oscuro del borde del cuerpo
            fat = ndimage.binary_opening(comp, structure=np.ones((3, 3))).sum() / comp.sum()
            if viento:
                if fat > 0.7 and comp.sum() > 20 and (comp & touch).any(): continue    # relleno gordo del cuerpo: fuera; volutas y puffs se quedan
            elif fat > 0 and (comp & touch).any(): continue      # relleno del cuerpo que se mueve: se descarta
            keep |= comp
        # volutas finas apoyadas sobre el cuerpo (más claras que él)
        if viento:
            # volutas finas que cruzan por encima del cuerpo: la diferencia fina contra el color fijo del cuerpo
            diff = a & body & (np.abs(l[..., :3].astype(int) - body_rgb.astype(int)).sum(axis=2) > 70)
            lab2, n2 = ndimage.label(diff, structure=np.ones((3, 3)))
            for i in range(1, n2 + 1):
                comp = lab2 == i
                if comp.sum() >= 3 and not ndimage.binary_opening(comp, structure=np.ones((3, 3))).any(): keep |= comp
        lay = np.zeros_like(l)
        lay[body, :3] = body_rgb[body]; lay[body, 3] = 255
        lay[keep, :3] = l[keep, :3]; lay[keep, 3] = 255
        out.append(lay)
    return out


def main(folder, v2=False, v3=False, v4=False):
    v2 = v2 or v3 or v4
    if v2:
        global OX, OY
        OX, OY = OX2, OY2
    bg, mid, hands, band, M = scene_layers()
    base = mid.copy(); base.alpha_composite(band)
    files = sorted(glob.glob(os.path.join(folder, "f*.png")))
    out = "test-results/vendedor-nube13" if v4 else "test-results/vendedor-nube12" if v3 else ("test-results/vendedor-nube11" if v2 else "test-results/vendedor-nube10"); os.makedirs(out, exist_ok=True)
    frames, layers = [], []
    ha = np.array(hands)
    hand_only = M["hand_b"] | M["hand_a"] * 0
    still = np.zeros_like(ha); still[M["hand_b"]] = ha[M["hand_b"]]
    cuff = np.zeros_like(ha); cm = M["cuff_b"] | M["cufflink"]; cuff[cm] = ha[cm]
    # el borde izquierdo de la mano (donde estaba el puño) lo cubre la nube en tiras de largo distinto, con la punta celeste
    ys, xs = np.nonzero(M["hand_b"]); y0, y1 = ys.min(), ys.max()
    for k, y in enumerate(range(y0, y1 + 1, 3)):
        L = [6, 10, 15, 19, 16, 11, 7, 9, 14, 20, 17, 12, 8, 5, 9][k % 15]
        for yy in (y, y + 1, y + 2):
            row = np.nonzero(M["hand_b"][yy])[0]
            if len(row) == 0: continue
            hx = xs.min()                      # borde izquierdo de toda la mano: el pulgar no se toca
            for x in range(hx, hx + L):
                if M["hand_b"][yy, x]: still[yy, x] = (243, 247, 247, 255)
            for x in range(hx + L, hx + L + 2):
                if M["hand_b"][yy, x]: still[yy, x] = (193, 226, 251, 255)
    still_hand, cuffs = Image.fromarray(still), Image.fromarray(cuff)
    for p in files:
        g, m = to_grid(p)
        if v2:
            hand_v = m & orange(g)
            cloud = m & ~hand_v
            closed = ndimage.binary_fill_holes(ndimage.binary_closing(cloud, structure=np.ones((9, 9))))
            near = ndimage.uniform_filter(cloud.astype(float), size=13) > 0.55      # solo donde la mano estaba rodeada de nube
            fill = hand_v & closed & near
            g = g.copy(); g[fill] = SOFT
            m = cloud | fill
        h, w = m.shape
        layer = np.zeros((H, W, 4), np.uint8)
        gx, gy = OX, OY
        # el video corta la nube a la izquierda: se repite la primera columna para cubrir el hueco hasta x = 0
        full = np.zeros((h, w + OX, 3), np.uint8); fm = np.zeros((h, w + OX), bool)
        full[:, OX:] = g; fm[:, OX:] = m
        full[:, :OX] = g[:, :1]; fm[:, :OX] = m[:, :1]
        y1, x1 = min(H, gy + h), min(W, w + OX)
        layer[gy:y1, 0:x1, :3] = full[: y1 - gy, :x1]
        layer[gy:y1, 0:x1, 3] = np.where(fm[: y1 - gy, :x1], 255, 0)
        layers.append(layer)
    if v3 or v4:
        layers = estaticas(layers, viento=v4)
    for layer in layers:
        f = base.copy()
        if v2:
            f.alpha_composite(cuffs)                                   # los puños quedan bajo la nube
        f.alpha_composite(Image.fromarray(layer))
        if v2:
            f.alpha_composite(still_hand)                              # la mano original, estática, sobre la nube
        f.alpha_composite(band)
        frames.append(f.crop((0, 67, 340, 387)))
    big = [f.resize((340 * 2, 320 * 2), Image.NEAREST) for f in frames]
    big[0].save(f"{out}/bucle.gif", save_all=True, append_images=big[1:], duration=250, loop=0)
    for i in (0, 10, 21, 30): frames[i].resize((340 * 3, 320 * 3), Image.NEAREST).save(f"{out}/cuadro{i}.png")
    sheet = Image.new("RGB", (340 * 4, 320 * 2))
    for k, i in enumerate((0, 5, 10, 14, 18, 22, 27, 33)): sheet.paste(frames[i].convert("RGB"), ((k % 4) * 340, (k // 4) * 320))
    sheet.save(f"{out}/tira.png")
    print("ok", len(frames), "cuadros")
    return layers, still, cuff


if __name__ == "__main__":
    main(sys.argv[1], "--v2" in sys.argv, "--v3" in sys.argv, "--v4" in sys.argv)
