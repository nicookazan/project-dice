"""Hoja de manos de los jefes (docs/PLAN-JEFES.md, fase C).

Parte de la mano real del juego (assets/art/pixel-v3/mano-v3.png: 8 cuadros de 61×53). No se redibuja:
se conserva silueta, sombreado y animación; solo se repinta con una rampa de 5 tonos y se agrega UN objeto
chico (8–14 px) en la muñeca o el dorso, que casi no se mueve entre cuadros. Sin fondos ni halos. Dios no
entra: conserva el triángulo con ojo. Una fila de 8 cuadros por jefe, en el orden del catálogo (18 filas).

Escribe assets/art/pixel-v3/manos-jefes-v3.png. Ejecutar:  py -3 tools/art/make_jefes_manos.py
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "assets", "art", "pixel-v3", "mano-v3.png")
OUT = os.path.join(ROOT, "assets", "art", "pixel-v3", "manos-jefes-v3.png")
FW, FH, FRAMES = 61, 53, 8
OUTLINE = "#1c1424"
MAX_OBJECT = 14


def hexc(s: str):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def recolor_sheet(sheet: Image.Image, ramp: list[str] | None) -> Image.Image:
    """Mapea los colores únicos de toda la hoja (ordenados por luminosidad) a la rampa nueva."""
    a = np.array(sheet.convert("RGBA"))
    if ramp is None:
        return Image.fromarray(a)
    opaque = a[..., 3] > 0
    cols = sorted({tuple(int(v) for v in p) for p in a[opaque][:, :3]}, key=lum)
    n, m = len(cols), len(ramp)
    table = {c: hexc(ramp[min(m - 1, int(i * m / n))])[:3] for i, c in enumerate(cols)}
    out = a.copy()
    for y, x in zip(*np.nonzero(opaque)):
        out[y, x, :3] = table[tuple(int(v) for v in a[y, x, :3])]
    return Image.fromarray(out)


class Obj:
    """Objeto dibujado en una capa de un cuadro; el contorno oscuro se agrega solo."""

    def __init__(self):
        self.layer = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.layer)

    def rect(self, x0, y0, x1, y1, c):
        self.d.rectangle([x0, y0, x1, y1], fill=hexc(c))

    def px(self, pts, c):
        self.d.point(pts, fill=hexc(c))

    def ellipse(self, x0, y0, x1, y1, c):
        self.d.ellipse([x0, y0, x1, y1], fill=hexc(c))

    def poly(self, pts, c):
        self.d.polygon(pts, fill=hexc(c))

    def line(self, pts, c):
        self.d.line(pts, fill=hexc(c))

    def bbox(self):
        return self.layer.getchannel("A").getbbox()

    def finish(self) -> Image.Image:
        a = np.array(self.layer)
        solid = a[..., 3] > 0
        pad = np.pad(solid, 1)
        near = pad[:-2, 1:-1] | pad[2:, 1:-1] | pad[1:-1, :-2] | pad[1:-1, 2:]
        edge = near & ~solid
        a[edge] = hexc(OUTLINE)
        return Image.fromarray(a)


# Cada objeto se dibuja en coordenadas del cuadro (61×53). Zona quieta: dorso y muñeca (y 1–24).

def kioskero(o: Obj):  # billete arrugado
    o.rect(25, 13, 37, 19, "#5fae63"); o.rect(26, 14, 36, 18, "#8fd48a")
    o.ellipse(29, 14, 33, 18, "#5fae63"); o.px([(31, 16)], "#d8f5d2")
    o.px([(27, 15), (35, 17), (28, 18), (34, 14)], "#4d9b55")


def payador(o: Obj):  # as de espadas entre los dedos
    o.rect(26, 9, 35, 21, "#f2ead8"); o.rect(27, 10, 34, 20, "#fbf6e8")
    o.poly([(30, 13), (27, 17), (29, 18), (31, 18), (33, 17)], "#241a14"); o.rect(30, 17, 30, 19, "#241a14")
    o.px([(28, 11), (33, 19)], "#241a14")


def palomas(o: Obj):  # paloma posada en la muñeca
    o.ellipse(22, 9, 31, 14, "#9aa1b0"); o.ellipse(28, 5, 33, 9, "#7b8294")
    o.px([(34, 7)], "#e8a43a"); o.px([(32, 6)], "#ffffff")
    o.px([(21, 12), (21, 13)], "#5c6270"); o.poly([(24, 10), (27, 10), (26, 13)], "#c4cad6")
    o.rect(25, 15, 25, 16, "#e8a43a"); o.rect(28, 15, 28, 16, "#e8a43a")


def cebador(o: Obj):  # mate con bombilla
    o.poly([(25, 12), (35, 12), (33, 20), (27, 20)], "#8a5a2b"); o.rect(26, 13, 34, 14, "#3f7a1a")
    o.px([(27, 16), (28, 18)], "#a8763a"); o.rect(31, 7, 31, 12, "#c9ced6"); o.px([(32, 7)], "#c9ced6")
    o.rect(28, 12, 32, 12, "#6fb02a")


def chamuyero(o: Obj):  # cadena dorada con medallón
    o.px([(29, 13), (28, 12), (27, 11), (26, 10), (25, 9), (33, 13), (34, 12), (35, 11), (36, 10), (37, 9)], "#f2d24a")
    o.px([(29, 12), (27, 10), (35, 10), (33, 12)], "#c9a227")
    o.ellipse(28, 14, 34, 20, "#f2d24a"); o.ellipse(30, 16, 32, 18, "#d6322a"); o.px([(29, 15)], "#fff2a8")


def referi(o: Obj):  # tarjeta roja
    o.rect(26, 9, 35, 21, "#d63a30"); o.rect(27, 10, 34, 20, "#ef5a46")
    o.rect(27, 10, 34, 10, "#ff8a72"); o.rect(26, 20, 35, 21, "#a82820")


def gotico(o: Obj):  # brazalete de tachas
    o.rect(24, 8, 37, 11, "#2b2f3d"); o.px([(26, 9), (30, 9), (34, 9)], "#aab2c8")
    o.px([(26, 10), (30, 10), (34, 10)], "#6f7890")


def conde(o: Obj):  # copa de líquido rojo
    o.poly([(24, 10), (36, 10), (34, 17), (26, 17)], "#e6edff"); o.poly([(25, 12), (35, 12), (34, 16), (26, 16)], "#b01226")
    o.rect(29, 18, 31, 22, "#9aa8c8"); o.rect(25, 22, 35, 23, "#9aa8c8"); o.px([(27, 11)], "#ffffff")


def lobizon(o: Obj):  # mechón de pelo erizado
    for i, x in enumerate(range(25, 37, 3)):
        o.poly([(x, 12), (x + 3, 12), (x + 1, 5 + (i % 2) * 2)], "#b9bfc9")
    o.rect(25, 11, 37, 13, "#8a909c"); o.px([(27, 8), (31, 7), (35, 8)], "#e1e5eb")


def tahur(o: Obj):  # pila de fichas
    for i, (c, d) in enumerate([("#d8453a", "#9a2a22"), ("#f2ead8", "#a89f8a"), ("#3a6ae0", "#2644a0"), ("#d8453a", "#9a2a22")]):
        y = 20 - i * 3
        o.ellipse(25, y - 2, 35, y + 2, c); o.rect(26, y, 34, y, d)
    o.px([(28, 11), (32, 11)], "#fff2a8")


def patovica(o: Obj):  # brazalete STAFF
    o.rect(24, 7, 37, 13, "#f2c93a"); o.rect(24, 7, 37, 8, "#ffe27a"); o.rect(24, 12, 37, 13, "#b8901a")
    for x in range(26, 36, 4):
        o.rect(x, 9, x + 1, 11, "#241a14")


def payaso(o: Obj):  # flor de la risa
    o.line([(30, 12), (30, 17)], "#2f9a3a")
    for ox, oy in [(-3, 0), (3, 0), (0, -3), (0, 3)]:
        o.ellipse(30 + ox - 2, 9 + oy - 2, 30 + ox + 2, 9 + oy + 2, "#f2c93a")
    o.ellipse(29, 8, 31, 10, "#d8453a"); o.px([(37, 6), (36, 9), (35, 4)], "#7fd0ff")


def visitante(o: Obj):  # lente del rayo tractor
    o.ellipse(25, 11, 37, 21, "#1d4a2a"); o.ellipse(27, 13, 35, 19, "#8ee06a")
    o.ellipse(29, 14, 33, 18, "#d9ffb0"); o.px([(30, 15)], "#ffffff")


def farolero(o: Obj):  # anillo verde
    o.rect(26, 12, 36, 21, "#1f6a3a"); o.rect(27, 13, 35, 20, "#3cd47a")
    o.rect(29, 14, 33, 18, "#c8ffdd"); o.px([(30, 15)], "#ffffff"); o.rect(26, 21, 36, 22, "#16502c")


def computadora(o: Obj):  # lente roja
    o.ellipse(25, 10, 37, 22, "#4a5666"); o.ellipse(27, 12, 35, 20, "#2a0a0a")
    o.ellipse(28, 13, 34, 19, "#d81a14"); o.ellipse(30, 14, 32, 18, "#ff7a4a"); o.px([(30, 15)], "#ffffff")


def horizonte(o: Obj):  # disco de acreción
    o.ellipse(24, 11, 37, 21, "#7a2b00"); o.ellipse(26, 12, 35, 20, "#c8581a")
    o.ellipse(28, 13, 33, 19, "#ffb347"); o.ellipse(29, 14, 32, 18, "#0a0408")


def relojero(o: Obj):  # reloj derretido
    o.ellipse(25, 8, 36, 16, "#f2e6c0"); o.px([(30, 12)], "#1c1424")
    o.line([(30, 12), (30, 9)], "#1c1424"); o.line([(30, 12), (34, 13)], "#1c1424")
    o.poly([(27, 14), (29, 20), (31, 15)], "#f2e6c0"); o.px([(28, 18)], "#d9b24a")


def durmiente(o: Obj):  # ojo que se abre en la palma
    o.ellipse(25, 10, 37, 20, "#f4f0b8"); o.rect(30, 10, 32, 20, "#10131c")
    o.px([(27, 13), (35, 13)], "#ffffff"); o.rect(25, 15, 37, 15, "#2f7d5a")


# (id del catálogo, rampa de 5 tonos o None para conservar la mano, objeto)
ROWS = [
    ("l1_kioskero", ["#5a1a1a", "#8a2a2a", "#b84040", "#d86a5a", "#f0a090"], kioskero),
    ("l1_payador", ["#2a160a", "#4e2c14", "#7a4a22", "#a8703a", "#d29f62"], payador),
    ("l1_palomas", ["#3a3f4a", "#586070", "#8a92a3", "#b9c0cc", "#e4e8ee"], palomas),
    ("l2_cebador", ["#4a2c0c", "#7a4a1a", "#a8702a", "#cf9650", "#e8bf80"], cebador),
    ("l2_chamuyero", ["#5a4208", "#8a6a12", "#c9a227", "#f0d060", "#fff2a8"], chamuyero),
    ("l2_referi", None, referi),
    ("l3_gotico", ["#1a1c26", "#2c3040", "#464d62", "#6a7391", "#98a2c0"], gotico),
    ("l3_conde", ["#3b3550", "#6d6488", "#a79fc0", "#d9d3e8", "#f4f0fa"], conde),
    ("l3_lobizon", ["#23252b", "#3e414a", "#6b707b", "#9a9fa9", "#c8ccd3"], lobizon),
    ("l4_tahur", ["#6b6b78", "#9a9aa8", "#c8c8d4", "#e8e8f0", "#ffffff"], tahur),
    ("l4_patovica", ["#1a1a20", "#2e2e38", "#4a4a58", "#6c6c80", "#9a9ab0"], patovica),
    ("l4_payaso", ["#7a7a8c", "#a8a8b8", "#d0d0dc", "#ececf4", "#ffffff"], payaso),
    ("l5_visitante", ["#17402a", "#2b7a3f", "#52b84e", "#8ee06a", "#d4ffa8"], visitante),
    ("l5_farolero", ["#1f3a2a", "#2f6a48", "#4f9a6a", "#8acb9a", "#cdeed4"], farolero),
    ("l5_computadora", ["#1c222b", "#38424f", "#5f6b7a", "#8d9aaa", "#c4ced9"], computadora),
    ("l6_horizonte", ["#2a0f00", "#7a2b00", "#c8581a", "#ffb347", "#fff0c0"], horizonte),
    ("l6_relojero", ["#3d2a08", "#6e4e12", "#a8801f", "#d9b24a", "#f6e08c"], relojero),
    ("l6_durmiente", ["#0a2a22", "#164a3b", "#2f7d5a", "#58b085", "#a8e6c1"], durmiente),
]


def build() -> Image.Image:
    base = Image.open(SRC).convert("RGBA")
    assert base.size == (FW * FRAMES, FH), base.size
    sheet = Image.new("RGBA", (FW * FRAMES, FH * len(ROWS)), (0, 0, 0, 0))
    too_big: list[str] = []
    for row, (boss, ramp, draw) in enumerate(ROWS):
        hand = recolor_sheet(base, ramp)
        obj = Obj()
        draw(obj)
        box = obj.bbox()
        w, h = box[2] - box[0], box[3] - box[1]
        if max(w, h) > MAX_OBJECT: too_big.append(f"{boss} {w}x{h}")
        layer = obj.finish()
        for frame in range(FRAMES):
            cell = hand.crop((frame * FW, 0, (frame + 1) * FW, FH))
            cell.alpha_composite(layer)
            sheet.paste(cell, (frame * FW, row * FH))
        print(f"{boss}: objeto {w}x{h}")
    assert not too_big, "objetos de más de %d px: %s" % (MAX_OBJECT, ", ".join(too_big))
    return sheet


if __name__ == "__main__":
    build().save(OUT)
    print("->", OUT)
