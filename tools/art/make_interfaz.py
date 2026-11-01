"""Boceto del kit de interfaz pixel-v3 (Fase 8): botones, panel de diálogo, marco de título y libreta.

Mantiene el diseño actual de la interfaz (fondo azul noche, borde naranja con esquinas escalonadas, ornamento azul
en el marco del título, papel crema para la libreta), llevado a la grilla lógica (2×2 px) y con luz arriba-izquierda.
Los marcos se dibujan como texturas de 9 cortes que Godot puede estirar sin deformar el borde.
Escribe texturas en test-results/ui/ y composiciones de prueba sobre las capturas del juego. No integra nada.

Ejecutar:  python tools/art/make_interfaz.py
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_lib import Canvas, ramp, upscale

OUT_C = (10, 14, 24)
ORG = ramp("78380a", "ce6a0c", "ff9218", "ffbe46", "ffe28c")
BLUE = ramp("0c3c8c", "1478e6", "50a8ff")
STATES = {
    # fondo, fondo claro (filo superior), borde (oscuro, medio, claro)
    "normal": ((8, 20, 46), (16, 36, 76), (ORG[1], ORG[2], ORG[3])),
    "hover": ((18, 40, 84), (30, 62, 120), (ORG[2], ORG[3], ORG[4])),
    "pressed": ((4, 10, 26), (8, 20, 44), (ORG[0], ORG[1], ORG[2])),
    "disabled": ((26, 30, 40), (34, 38, 48), ((70, 62, 54), (96, 86, 72), (120, 108, 92))),
    "accent": ((16, 52, 108), (36, 88, 160), (ORG[2], ORG[3], ORG[4])),
    "accent_hover": ((28, 76, 140), (52, 110, 184), (ORG[3], ORG[4], (255, 240, 190))),
}


def draw_frame(w: int, h: int, state: str = "normal", cut=(2, 1), ornament: bool = False) -> np.ndarray:
    fill, fill_hi, (b_dk, b_md, b_lt) = STATES[state]
    mask = np.ones((h, w), bool)
    for j, n in enumerate(cut):
        mask[j, :n] = False; mask[j, w - n:] = False
        mask[h - 1 - j, :n] = False; mask[h - 1 - j, w - n:] = False
    d = ndimage.distance_transform_cdt(np.pad(mask, 1), metric="taxicab")[1:-1, 1:-1]
    yy, xx = np.mgrid[0:h, 0:w]
    dl, dr, dt, db = xx, w - 1 - xx, yy, h - 1 - yy
    lit = np.minimum(dl, dt) <= np.minimum(dr, db)          # más cerca de arriba/izquierda
    out = np.zeros((h, w, 4), np.uint8)

    def put(m, c):
        out[m, :3] = c
        out[m, 3] = 255
    put(mask & (d >= 1), fill)
    put(mask & (d == 5) & (dt <= np.minimum(dl, np.minimum(dr, db))), fill_hi)
    put(mask & (d == 4), tuple(int(v * 0.55) for v in fill))
    put(mask & (d == 3), np.array(b_md))
    put(mask & (d == 2), np.where(lit[..., None], np.array(b_lt), np.array(b_dk))[mask & (d == 2)])
    put(mask & (d == 1), OUT_C)
    # el filete exterior de la luz: arriba/izquierda más claro en la capa media
    put(mask & (d == 3) & lit & (np.minimum(dl, dt) <= 2), np.array(b_lt))
    if ornament:
        for sx, sy in ((7, 7), (w - 8, 7), (7, h - 8), (w - 8, h - 8)):
            fx = 1 if sx < w / 2 else -1
            fy = 1 if sy < h / 2 else -1
            for k in range(5):
                out[sy, sx + fx * k] = (*ORG[3], 255)
                out[sy + fy * k, sx] = (*ORG[3], 255)
            out[sy + fy, sx + fx] = (*ORG[1], 255)
    return out


def nine(tex: np.ndarray, m: int, w: int, h: int) -> np.ndarray:
    th, tw = tex.shape[:2]
    out = np.zeros((h, w, 4), np.uint8)
    xs = np.concatenate([np.arange(m), m + (np.arange(w - 2 * m) % (tw - 2 * m)), tw - m + np.arange(m)])
    ys = np.concatenate([np.arange(m), m + (np.arange(h - 2 * m) % (th - 2 * m)), th - m + np.arange(m)])
    return tex[ys[:, None], xs[None, :]]


def title_frame(w: int, h: int) -> np.ndarray:
    """Marco ornamental del cartel TIENDA: esquinas muy escalonadas y ornamentos azules arriba, abajo y a los lados."""
    f = draw_frame(w, h, "normal", cut=(6, 4, 3, 2, 1))
    cv = Canvas(w, h)
    cv.a = f
    cx, cy = w // 2, h // 2

    def diamond(px, py, rx, ry):
        for y in range(-ry, ry + 1):
            for x in range(-rx, rx + 1):
                r = abs(x) / rx + abs(y) / ry
                if r <= 1.0:
                    cv.put(px + x, py + y, BLUE[2] if (x < 0 and y <= 0 and r > 0.4) else BLUE[1] if r > 0.55 else BLUE[0])
                elif r <= 1.35:
                    cv.put(px + x, py + y, OUT_C)
    for y0 in (1, h - 2):
        diamond(cx, y0, 5, 4)
        for k in range(8, 22):
            cv.put(cx - k, y0, BLUE[1]); cv.put(cx + k, y0, BLUE[1])
            cv.put(cx - k, y0 + (1 if y0 < h / 2 else -1), BLUE[0]); cv.put(cx + k, y0 + (1 if y0 < h / 2 else -1), BLUE[0])
    for sx in (1, w - 2):
        diamond(sx, cy, 4, 5)
        for k in range(8, 16):
            cv.put(sx, cy - k, BLUE[1]); cv.put(sx, cy + k, BLUE[1])
    return cv.a


def paper(w: int, h: int) -> np.ndarray:
    """Libreta: papel crema con renglones, borde oscuro, sombra en el costado izquierdo."""
    cv = Canvas(w, h)
    cv.rect(0, 0, w, h, OUT_C)
    cv.rect(1, 1, w - 2, h - 2, (246, 238, 214))
    cv.rect(1, 1, w - 2, 1, (255, 250, 236))
    cv.rect(1, 1, 1, h - 2, (255, 250, 236))
    cv.rect(w - 2, 1, 1, h - 2, (214, 200, 168))
    cv.rect(1, h - 2, w - 2, 1, (214, 200, 168))
    for y in range(14, h - 4, 7):
        cv.rect(4, y, w - 8, 1, (212, 198, 170))
    cv.rect(6, 1, 1, h - 2, (214, 120, 110))     # margen rojo
    return cv.a


def font(size: int):
    for p in ("C:/Windows/Fonts/consolab.ttf", "C:/Windows/Fonts/consola.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def text_on(img: Image.Image, xy, s: str, size: int, color, center_w: int | None = None):
    d = ImageDraw.Draw(img)
    d.fontmode = "1"
    f = font(size)
    if center_w is not None:
        wd = d.textlength(s, font=f)
        xy = (xy[0] + (center_w - wd) / 2, xy[1])
    d.text(xy, s, font=f, fill=color)


def button(img: Image.Image, rect, label: str, state: str):
    """Dibuja un botón en pantalla de 1440×900 (los bordes caen en la grilla de 2×2)."""
    x0, y0, x1, y1 = [round(v / 2) for v in rect]
    w, h = x1 - x0, y1 - y0
    tex = draw_frame(24, 24, state)
    big = upscale(Image.fromarray(nine(tex, 8, w, h)), 2)
    img.alpha_composite(big, (x0 * 2, y0 * 2))
    col = {"disabled": (130, 124, 116), "accent": (255, 246, 220)}.get(state, (240, 232, 214))
    size = 16
    d = ImageDraw.Draw(img)
    while size > 12 and d.textlength(label, font=font(size)) > w * 2 - 20:
        size -= 1
    text_on(img, (x0 * 2, y0 * 2 + (h * 2 - size - 2) // 2 + 1), label, size, col, center_w=w * 2)


def main() -> None:
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    os.makedirs("test-results/ui", exist_ok=True)
    # texturas (9 cortes) para revisión
    for st in STATES:
        Image.fromarray(draw_frame(24, 24, st)).save(f"test-results/ui/boton-{st}.png")
    Image.fromarray(draw_frame(32, 32, "normal", cut=(3, 2, 1), ornament=True)).save("test-results/ui/panel.png")
    Image.fromarray(title_frame(231, 72)).save("test-results/ui/titulo.png")
    Image.fromarray(paper(24, 28)).save("test-results/ui/libreta.png")
    # texturas para el juego: ya ampliadas ×2, así cada píxel lógico es un bloque de 2×2 al estirar con nearest
    ui = "assets/art/pixel-v3/ui/"
    os.makedirs(ui, exist_ok=True)
    for st in STATES:
        upscale(Image.fromarray(draw_frame(24, 24, st)), 2).save(f"{ui}boton-{st}.png")
    upscale(Image.fromarray(draw_frame(32, 32, "normal", cut=(3, 2, 1), ornament=True)), 2).save(f"{ui}panel.png")
    upscale(Image.fromarray(title_frame(200, 38)), 2).save(f"{ui}titulo.png")
    # tablero del kit
    kit = Image.new("RGBA", (1440, 420), (46, 30, 22, 255))
    x = 40
    for st in STATES:
        button(kit, (x, 40, x + 220, 100), st.upper() if st != "disabled" else "DESACTIVADO", st)
        x += 260
    pan = upscale(Image.fromarray(nine(draw_frame(32, 32, "normal", cut=(3, 2, 1), ornament=True), 12, 150, 80)), 2)
    kit.alpha_composite(pan, (40, 140))
    kit.alpha_composite(upscale(Image.fromarray(title_frame(231, 72)), 2), (380, 150))
    kit.alpha_composite(upscale(Image.fromarray(nine(paper(24, 28), 8, 80, 110)), 2), (880, 130))
    text_on(kit, (60, 170), "Panel de dialogo", 22, (255, 240, 200))
    text_on(kit, (520, 220), "T I E N D A", 34, (255, 240, 200))
    kit.convert("RGB").save("test-results/ui/kit.png")
    # prueba sobre las capturas reales (1280×800 → 1440×900 de fondo; los elementos nuevos, nítidos)
    shot = Image.open("test-results/1280x800-mesa-estados.png").convert("RGBA").resize((1440, 900), Image.LANCZOS)
    s = 1.125
    rows = [("ANOTAR MANO", (36, 606, 294, 646), "accent"), ("Armar grupo", (333, 606, 519, 646), "disabled"), ("Al vaso →", (531, 606, 669, 646), "normal"),
            ("← Reservar", (681, 606, 819, 646), "normal"), ("Inspeccionar", (831, 606, 951, 646), "hover"), ("TIRAR (2)", (963, 606, 1238, 646), "accent"),
            ("Abandonar partida", (525, 20, 697, 54), "normal"), ("Opciones", (712, 20, 871, 54), "normal"), ("Recorrido · M", (890, 20, 1076, 54), "normal"), ("Menú", (1085, 20, 1248, 54), "normal")]
    for label, r, st in rows:
        button(shot, tuple(v * s for v in r), label, st)
    shot.convert("RGB").save("test-results/ui/botones-despues.png")
    before = Image.open("test-results/1280x800-mesa-estados.png").convert("RGB").resize((1440, 900), Image.LANCZOS)
    before.save("test-results/ui/botones-antes.png")
    # diálogo (ficha del dado)
    base = Image.open("test-results/1280x800-ficha-dado.png").convert("RGBA").resize((1440, 900), Image.LANCZOS)
    m = Image.open("test-results/1280x800-mesa-estados.png").convert("RGBA").resize((1440, 900), Image.LANCZOS)
    dlg = (268, 122, 1011, 655)
    box = tuple(round(v * s) for v in dlg)
    base.paste(m.crop(box), box[:2])                 # tapa el diálogo gris con la mesa de abajo
    px0, py0, px1, py1 = [round(v / 2) for v in box]
    panel = upscale(Image.fromarray(nine(draw_frame(32, 32, "normal", cut=(3, 2, 1), ornament=True), 12, px1 - px0, py1 - py0)), 2)
    base.alpha_composite(panel, (px0 * 2, py0 * 2))
    text_on(base, (px0 * 2, py0 * 2 + 18), "Dado 1 · ficha", 24, (255, 232, 170), center_w=(px1 - px0) * 2)
    ImageDraw.Draw(base).rectangle([px0 * 2 + 28, py0 * 2 + 54, px1 * 2 - 28, py0 * 2 + 55], fill=ORG[1])
    lines = ["Número visible: 4 · posición de cara: 2", "El número de la cara determina combinaciones y paridad;", "sus puntos se calculan aparte.", "",
             "Seis posiciones de cara:", "Cara 1: 1     Cara 2: 4     Cara 3: 3", "Cara 4: 4     Cara 5: 5     Cara 6: 6", "",
             "Mejoras globales por número: 4 → +15", "Material: Acero · Puntos: Rubí (resquebrajada)", "Elemento: Tierra"]
    for i, ln in enumerate(lines):
        text_on(base, (px0 * 2 + 40, py0 * 2 + 76 + i * 28), ln, 21, (240, 228, 204))
    button(base, (box[0] + (box[2] - box[0]) / 2 - 70, box[3] - 74, box[0] + (box[2] - box[0]) / 2 + 70, box[3] - 28), "OK", "accent")
    base.convert("RGB").save("test-results/ui/dialogo-despues.png")
    Image.open("test-results/1280x800-ficha-dado.png").convert("RGB").resize((1440, 900), Image.LANCZOS).save("test-results/ui/dialogo-antes.png")
    print("ok")


if __name__ == "__main__":
    main()
