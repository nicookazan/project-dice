"""Gestos nuevos de la mano (Fase 7, para revisar): abrirse, cerrarse, pulgar arriba y pulgar abajo.

Se arman con las piezas de la mano aprobada (assets/art/pixel-v3/mano-v3.png, cuadro 0): cada dedo y el pulgar se
recortan y se giran o acortan desde su nudillo, así que conservan la paleta, las uñas y el borde del original.
  abrir    los dedos se abren en abanico y el pulgar se separa
  cerrar   los dedos se acortan hacia la palma (puño visto desde arriba)
  arriba   puño con el pulgar levantado
  abajo    puño con el pulgar hacia abajo
Cada cuadro mide 76×64 (margen para el pulgar). Escribe test-results/gesto-*.png, un GIF y una hoja de revisión.

Ejecutar:  python tools/art/make_mano_gestos.py
"""
from __future__ import annotations

import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_lib import upscale

CW, CH = 76, 64
OX, OY = 8, 8            # dónde cae la esquina de la mano base dentro del cuadro
# piezas: nombre -> (columna desde, columna hasta, fila desde, pivote x, pivote y)
FINGERS = {
    "menique": (0, 10, 30, 5.0, 29.0),
    "anular": (10, 17, 36, 13.5, 35.0),
    "mayor": (17, 28, 40, 22.5, 39.0),
    "indice": (28, 37, 24, 32.0, 24.0),
}
THUMB = (46, 61, 0, 46.0, 22.0)
ORDER = ["menique", "anular", "mayor", "indice"]   # atrás → adelante


OVERLAP = 6   # filas/columnas de raíz que la pieza comparte con la palma, para que no se despegue al girar


def pieces(base: np.ndarray):
    """Devuelve (piezas con raíz superpuesta, cuerpo). El cuerpo conserva la raíz; la pieza solo la copia."""
    h, w = base.shape[:2]
    solid = base[..., 3] > 0
    rows = np.arange(h)[:, None]
    cols = np.arange(w)[None, :]
    taken = np.zeros_like(solid)
    cores, out = {}, {}
    thumb_core = solid & (cols >= THUMB[0]) & (rows >= 14)
    cores["pulgar"] = thumb_core
    out["pulgar"] = solid & (cols >= THUMB[0] - OVERLAP) & (rows >= 14 - 2)
    taken |= thumb_core
    for name in ORDER:
        x0, x1, y0, _, _ = FINGERS[name]
        core = solid & (cols >= x0) & (cols < x1) & (rows >= y0) & ~taken
        cores[name] = core
        out[name] = solid & (cols >= x0) & (cols < x1) & (rows >= y0 - OVERLAP)
        taken |= core
    out["cuerpo"] = solid & ~taken
    return out


def transform(base: np.ndarray, mask: np.ndarray, pivot, deg: float, sx: float, sy: float, dst: np.ndarray, shift=(0, 0)):
    """Dibuja `mask` de `base` en `dst`, girado `deg` (positivo = horario) y escalado desde el pivote."""
    h, w = base.shape[:2]
    th = math.radians(deg)
    c, s = math.cos(th), math.sin(th)
    px, py = pivot
    for y in range(dst.shape[0]):
        for x in range(dst.shape[1]):
            dx, dy = x - OX - shift[0] + 0.5 - px, y - OY - shift[1] + 0.5 - py
            # inversa: girar al revés y deshacer la escala
            ux, uy = c * dx + s * dy, -s * dx + c * dy
            ux, uy = ux / sx, uy / sy
            sxp, syp = int(math.floor(px + ux)), int(math.floor(py + uy))
            if 0 <= sxp < w and 0 <= syp < h and mask[syp, sxp] and base[syp, sxp, 3] > 0:
                dst[y, x] = base[syp, sxp]


def pose(base: np.ndarray, P: dict, thumb_deg: float, thumb_scale=(1.0, 1.0), thumb_shift=(0, 0), fingers_scale=1.0, order=None) -> np.ndarray:
    parts = pieces(base)
    dst = np.zeros((CH, CW, 4), np.uint8)
    h, w = base.shape[:2]
    body = parts["cuerpo"]
    yy, xx = np.mgrid[0:CH, 0:CW]
    by, bx = yy - OY, xx - OX
    ok = (by >= 0) & (by < h) & (bx >= 0) & (bx < w)
    sel = ok.copy()
    sel[ok] = body[by[ok], bx[ok]]
    dst[sel] = base[by[sel], bx[sel]]
    transform(base, parts["pulgar"], (THUMB[3], THUMB[4]), thumb_deg, thumb_scale[0], thumb_scale[1], dst, thumb_shift)
    for name in (order or ORDER):
        deg, sy, shift = P[name]
        transform(base, parts[name], (FINGERS[name][3], FINGERS[name][4]), deg, 1.0, sy * fingers_scale, dst, shift)
    return dst


def main() -> None:
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    base = np.array(Image.open("assets/art/pixel-v3/mano-v3.png").convert("RGBA"))[:, :61]
    gestos = {
        "reposo": pose(base, {n: (0, 1.0, (0, 0)) for n in ORDER}, 0),
        "abierta": pose(base, {"menique": (26, 1.0, (0, 0)), "anular": (12, 1.04, (0, 0)), "mayor": (0, 1.08, (0, 0)),
                               "indice": (-13, 1.0, (0, 0))}, -20, (1.0, 1.0), (0, 0)),
        "cerrada": pose(base, {"menique": (-6, 0.42, (0, 0)), "anular": (-3, 0.38, (0, 0)), "mayor": (0, 0.36, (0, 0)),
                               "indice": (3, 0.5, (0, 0))}, 18, (0.85, 0.85), (0, 0)),
        "pulgar_arriba": pose(base, {"menique": (-6, 0.42, (0, 0)), "anular": (-3, 0.38, (0, 0)), "mayor": (0, 0.36, (0, 0)),
                                     "indice": (3, 0.5, (0, 0))}, -118, (1.0, 1.05), (0, 0)),
        "pulgar_abajo": pose(base, {"menique": (-6, 0.42, (0, 0)), "anular": (-3, 0.38, (0, 0)), "mayor": (0, 0.36, (0, 0)),
                                    "indice": (3, 0.5, (0, 0))}, 42, (1.0, 1.1), (0, 0)),
    }
    for k, v in gestos.items():
        Image.fromarray(v).save(f"test-results/gesto-{k}.png")
    bg = (30, 60, 130, 255)
    names = list(gestos)
    sheet = Image.new("RGB", (len(names) * (CW * 4 + 6), CH * 4), (20, 30, 70))
    for i, n in enumerate(names):
        im = Image.new("RGBA", (CW, CH), bg)
        im.alpha_composite(Image.fromarray(gestos[n]))
        sheet.paste(upscale(im, 4).convert("RGB"), (i * (CW * 4 + 6), 0))
    sheet.save("test-results/gestos-hoja.png")
    # GIF: reposo → abrir → cerrar → abrir → reposo
    seq = ["reposo", "abierta", "abierta", "cerrada", "cerrada", "abierta", "reposo", "reposo"]
    seq2 = ["reposo", "pulgar_arriba", "pulgar_arriba", "pulgar_arriba", "reposo", "pulgar_abajo", "pulgar_abajo", "pulgar_abajo"]
    for tag, s_ in (("abrir-cerrar", seq), ("pulgares", seq2)):
        fr = []
        for n in s_:
            im = Image.new("RGBA", (CW, CH), bg)
            im.alpha_composite(Image.fromarray(gestos[n]))
            fr.append(upscale(im, 5).convert("P", palette=Image.ADAPTIVE))
        fr[0].save(f"test-results/gesto-{tag}.gif", save_all=True, append_images=fr[1:], duration=260, loop=0)
    print("ok")


if __name__ == "__main__":
    main()
