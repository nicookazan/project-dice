"""Poses de piedra, papel o tijera de las manos del fondo (etapa de jugabilidad, M7).

Cada pose parte del dibujo de la propia mano (cuadro 0 de su fila en `manos-jefes-v3.png`, y la mano común de
`mano-v3.png`): papel es el dibujo tal cual; piedra y tijera doblan y estiran los dedos con el mismo sombreado,
sin redibujar. La hoja `manos-poses-v3.png` tiene una fila por mano (18 de jefe + la común, en ese orden) y tres
columnas: piedra, papel, tijera. Cada celda es de 61x53 px lógicos.

  py tools/art/make_manos_poses.py            genera la hoja y una hoja de revisión en test-results/
Las funciones de pose son las aprobadas en los bocetos (tools/art/bocetos-jugabilidad/anim.py); el puño todavía
espera la aprobación explícita del autor, mano por mano.
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as nd

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets" / "art" / "pixel-v3"
HW, HH = 61, 53
POSES = ("piedra", "papel", "tijera")


def pose_base(cell, name):
    a = np.array(cell)
    if name == "papel": return Image.fromarray(a)
    Y0 = 25
    o = np.zeros_like(a)
    if name == "piedra":
        o[:Y0] = a[:Y0]
        # dedos curvados: filas de abajo comprimidas contra los nudillos; yemas conservadas
        for dy in range(Y0, HH):
            sy = Y0 + int((dy - Y0) / .42)
            if sy < HH: o[dy, :40] = a[sy, :40]
        o[:, 40:] = 0
        o[:Y0, 40:] = a[:Y0, 40:]
        # pulgar cerrado sobre los dedos
        th = a[14:38, 40:61].copy()
        tmp = np.zeros((HH, HW, 4), np.uint8)
        for y in range(th.shape[0]):
            ny = 16 + int(y * .6)
            row_ = th[y]
            for x in range(th.shape[1]):
                nx = 33 + int(x * .62)
                if row_[x, 3] > 0 and ny < HH and nx < HW: tmp[ny, nx] = row_[x]
        for y in range(HH):
            o[y, max(0, 47 - max(0, y - 6) // 2):] = 0
        mask = tmp[..., 3] > 0
        o[mask] = tmp[mask]
        return Image.fromarray(o)
    # tijera: mayor e índice estirados y abiertos; el resto doblado
    o[:Y0] = a[:Y0]
    for dy in range(Y0, HH):
        sy = Y0 + int((dy - Y0) / .42)
        if sy < HH:
            o[dy, :18] = a[sy, :18]
            o[dy, 38:] = 0
    o[:Y0, 40:] = a[:Y0, 40:]
    for y in range(Y0):
        o[y, max(0, 47 - max(0, y - 6) // 2):] = 0
    th = a[14:38, 40:61]
    for y in range(th.shape[0]):
        ny = 16 + int(y * .6)
        for x in range(th.shape[1]):
            nx = 36 + int(x * .55)
            if th[y, x, 3] > 0 and ny < HH and nx < HW: o[ny, nx] = th[y, x]
    # mayor (columnas 18–27) se abre a la izquierda
    for dy in range(Y0, HH):
        d = int((dy - Y0) * .28)
        for x in range(18, 28):
            if a[dy, x, 3] > 0 and x - d >= 0: o[dy, x - d] = a[dy, x]
    # índice (columnas 27–37) se estira y se abre a la derecha
    for dy in range(Y0, HH):
        sy = Y0 + int((dy - Y0) * .42) if dy < 48 else None
        if sy is None: continue
        d = int((dy - Y0) * .34)
        for x in range(27, 37):
            if a[sy, x, 3] > 0 and x + d < HW: o[dy, x + d] = a[sy, x]
    return Image.fromarray(o)


def _fist_body(cell):
    """Misma mano, mismo ángulo y mismo sombreado: los dedos se doblan y se juntan, y el pulgar del dibujo cruza por debajo."""
    a = np.array(cell)
    o = np.zeros_like(a)
    op = a[a[..., 3] > 0]
    order = op[np.argsort(op[:, :3].sum(axis=1))][:, :3]
    crease = order[int(.06 * (len(order) - 1))]
    Y0 = 22
    o[:Y0, :] = a[:Y0, :]
    # se saca el arranque del pulgar a la derecha, para que quede la masa del puño
    for y in range(HH):
        limit = 46 - max(0, y - 16) // 3
        o[y, limit:] = 0
    # cada columna de dedos se comprime hasta una línea curva de nudillos: no quedan huecos entre dedos
    def bottom(x): return int(round(39 - ((x - 20) / 24.0) ** 2 * 8))
    for x in range(0, 43):
        col = np.where(a[Y0:, x, 3] > 0)[0]
        if not len(col): continue
        end = Y0 + col.max()
        dest = bottom(x)
        if dest <= Y0: continue
        for y in range(Y0, dest + 1):
            sy = Y0 + int((y - Y0) / max(1, dest - Y0) * (end - Y0))
            if a[sy, x, 3] > 0:
                o[y, x] = a[sy, x]
            else:
                o[y, x, :3] = crease; o[y, x, 3] = 255
    # pulgar: el mismo dibujo, espejado y acostado, cruzando abajo de los dedos
    thumb = Image.fromarray(a[12:40, 38:61].copy())
    thumb = thumb.transpose(Image.FLIP_LEFT_RIGHT).rotate(-28, Image.NEAREST, expand=True)
    t_ = np.array(thumb)
    ty, tx = np.where(t_[..., 3] > 0)
    t_ = t_[ty.min():ty.max() + 1, tx.min():tx.max() + 1]
    th_h, th_w = t_.shape[:2]
    ox, oy = 15, 39 - th_h + 5
    mask = t_[..., 3] > 0
    edge = nd.binary_dilation(mask, iterations=1) & ~mask
    for y in range(th_h):
        for x in range(th_w):
            nx, ny = ox + x, oy + y
            if not (0 <= nx < HW and 0 <= ny < HH): continue
            if mask[y, x]: o[ny, nx] = t_[y, x]
            elif edge[y, x] and o[ny, nx, 3] > 0: o[ny, nx, :3] = crease
    return Image.fromarray(o)


def fist(cell):
    """Limpia las puntas del contorno: sin espolón abajo a la derecha ni esquina recta a la izquierda."""
    o = np.array(_fist_body(cell))
    for y in range(HH):
        if y >= 28: o[y, 44:] = 0
        if y >= 33: o[y, 42:] = 0
        if y >= 37: o[y, 39:] = 0
        if y >= 31: o[y, :1] = 0
        if y >= 34: o[y, :3] = 0
    return Image.fromarray(o)


def pose(cell, name):
    return fist(cell) if name == "piedra" else pose_base(cell, name)


def cells():
    hands = Image.open(ART / "manos-jefes-v3.png").convert("RGBA")
    rows = hands.height // HH
    out = [hands.crop((0, r * HH, HW, r * HH + HH)) for r in range(rows)]
    out.append(Image.open(ART / "mano-v3.png").convert("RGBA").crop((0, 0, HW, HH)))
    return out


def main():
    hands = cells()
    sheet = Image.new("RGBA", (HW * 3, HH * len(hands)), (0, 0, 0, 0))
    for row, cell in enumerate(hands):
        for col, name in enumerate(POSES):
            sheet.paste(pose(cell, name), (col * HW, row * HH))
    sheet.save(ART / "manos-poses-v3.png")
    print("manos-poses-v3.png", sheet.size, "filas:", len(hands))
    # Hoja de revisión: todas las manos con sus tres poses, a 2x sobre el azul del cielo.
    review = Image.new("RGB", (HW * 3 * 2 * 3 + 20, 0), (70, 96, 138))
    per_column = (len(hands) + 2) // 3
    review = Image.new("RGB", (3 * (HW * 3 * 2 + 12), per_column * (HH * 2 + 6)), (70, 96, 138))
    for row in range(len(hands)):
        strip = sheet.crop((0, row * HH, HW * 3, row * HH + HH)).resize((HW * 3 * 2, HH * 2), Image.NEAREST)
        review.paste(strip, ((row // per_column) * (HW * 3 * 2 + 12), (row % per_column) * (HH * 2 + 6)), strip)
    out = ROOT / "test-results"
    out.mkdir(exist_ok=True)
    review.save(out / "manos-poses-revision.png")
    print("hoja de revisión: test-results/manos-poses-revision.png")


if __name__ == "__main__":
    main()
