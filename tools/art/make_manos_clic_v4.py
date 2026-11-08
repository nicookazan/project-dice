"""Manos de jefe v4 (niveles 1 a 6, sin El Gótico): reposo y animación del clic, con fondo transparente.

Reusa los bocetos aprobados de tools/art/bocetos-jefes/ (manos_1.py, manos_2.py). Cada diseño devuelve cuadros de la
escena de la ventana (189×110 px lógicos, mano en (45, 17)); acá se parten en la capa de atrás (antes de la nube) y la
de adelante (mano y objetos), sin el paisaje ni la nube, que el juego dibuja aparte.

Salidas (assets/art/pixel-v3/): manos-clic-v4.png (adelante), manos-clic-atras-v4.png (atrás) y manos-contorno-v4.png
(silueta para el aro dorado); scripts/boss_hand_clips.gd (tabla de recortes, generada).
Uso: py -3.13 tools/art/make_manos_clic_v4.py
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as nd

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "bocetos-jefes"))
import kit as K  # noqa: E402

ROOT = K.ROOT
OUT = os.path.join(ROOT, "assets", "art", "pixel-v3")

# Opción elegida por jefe (08/11).
CHOSEN = {"l1_kioskero": "B", "l1_payador": "A", "l1_palomas": "B", "l2_cebador": "B", "l2_chamuyero": "B", "l2_referi": "B",
          "l3_conde": "B", "l3_lobizon": "B", "l4_tahur": "B", "l4_patovica": "A", "l4_payaso": "B", "l5_visitante": "A",
          "l5_farolero": "A", "l5_computadora": "B", "l6_horizonte": "A", "l6_relojero": "A", "l6_durmiente": "B"}
RING_FRONT_ONLY = {"l4_tahur"}   # el paño de la mesa ocupa todo el ancho: el aro solo sigue a la mano
BLANK = Image.new("RGBA", (K.SW, K.SH), (0, 0, 0, 0))


def split_scene(env, layers):
    """Reemplaza a K.scene: devuelve la capa de adelante y le cuelga la de atrás (`.back`)."""
    back, front = BLANK.copy(), BLANK.copy()
    cur = back
    for item in layers:
        if item == "NUBE":
            cur = front
            continue
        im, (x, y) = item
        cur.alpha_composite(im, (x, y)) if x >= 0 and y >= 0 else cur.paste(im, (x, y), im)
    front.back = back
    return front


K.scene = split_scene
import manos_1  # noqa: E402
import manos_2  # noqa: E402


def bbox_union(images):
    box = None
    for im in images:
        b = im.getbbox()
        if b is None: continue
        box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    return box


def main():
    designs = [d for mod in (manos_1, manos_2) for d in mod.DESIGNS if CHOSEN.get(d[0]) == d[2]]
    assert len(designs) == len(CHOSEN), (len(designs), len(CHOSEN))
    clips = []
    for boss, name, op, title, desc, env, fn in designs:
        frames = fn()
        fronts = [f for f in frames]
        backs = [f.back for f in frames]
        box = bbox_union(fronts + backs)
        clips.append({"id": boss, "front": [f.crop(box) for f in fronts], "back": [b.crop(box) for b in backs],
                      "has_back": any(b.getbbox() for b in backs), "box": box})
        print(boss, op, len(frames), "frames", box)
    width = max(len(c["front"]) * (c["box"][2] - c["box"][0]) for c in clips)
    height = sum(c["box"][3] - c["box"][1] for c in clips)
    front_sheet = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    back_sheet = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    y = 0
    lines = []
    for c in clips:
        w, h = c["box"][2] - c["box"][0], c["box"][3] - c["box"][1]
        for i, (f, b) in enumerate(zip(c["front"], c["back"])):
            front_sheet.paste(f, (i * w, y))
            if c["has_back"]: back_sheet.paste(b, (i * w, y))
        lines.append('\t"%s": {"frames": %d, "size": Vector2i(%d, %d), "sheet_y": %d, "origin": Vector2i(%d, %d), "back": %s, "ring_y": RINGY},'
                     % (c["id"], len(c["front"]), w, h, y, c["box"][0], c["box"][1], "true" if c["has_back"] else "false"))
        c["y"] = y
        y += h
    front_sheet.save(os.path.join(OUT, "manos-clic-v4.png"))
    back_sheet.save(os.path.join(OUT, "manos-clic-atras-v4.png"))
    # Aro dorado: contorno de 2 px de pantalla de la mano en reposo (cuadro 0), a 2×, en filas de la misma altura que las del recorte.
    ring_w = max(2 * (c["box"][2] - c["box"][0]) + 4 for c in clips)
    ring_h = sum(2 * (c["box"][3] - c["box"][1]) + 4 for c in clips)
    ring = Image.new("RGBA", (ring_w, ring_h), (0, 0, 0, 0))
    ry = 0
    for c in clips:
        w, h = c["box"][2] - c["box"][0], c["box"][3] - c["box"][1]
        sil = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        if c["id"] not in RING_FRONT_ONLY: sil.alpha_composite(c["back"][0])
        sil.alpha_composite(c["front"][0])
        m = np.zeros((2 * h + 4, 2 * w + 4), bool)
        m[2:-2, 2:-2] = np.kron(np.array(sil)[:, :, 3] > 0, np.ones((2, 2), bool))
        edge = nd.binary_dilation(m, iterations=2) & ~m
        r = np.zeros(m.shape + (4,), np.uint8)
        r[edge] = (255, 224, 120, 255)
        ring.paste(Image.fromarray(r), (0, ry))
        c["ring_y"] = ry
        ry += 2 * h + 4
    ring.save(os.path.join(OUT, "manos-contorno-v4.png"))
    lines = [l.replace("RINGY", str(c["ring_y"])) for l, c in zip(lines, clips)]
    gd = ["extends RefCounted",
          "## Recortes de las manos de jefe v4 (manos-clic-v4.png / manos-clic-atras-v4.png / manos-contorno-v4.png).",
          "## GENERADO por tools/art/make_manos_clic_v4.py: no editar a mano.",
          "## Una fila por jefe: `frames` cuadros de `size` px lógicos desde `sheet_y`; `origin` es dónde cae el recorte en la ventana",
          "## grande (189×110; la mano en reposo en 45,17). El cuadro 0 es el reposo y el resto, la animación del clic.",
          "const CLIPS := {", *lines, "}", ""]
    with open(os.path.join(ROOT, "scripts", "boss_hand_clips.gd"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(gd))


if __name__ == "__main__":
    main()
