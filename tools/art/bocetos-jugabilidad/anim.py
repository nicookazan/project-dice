"""Bocetos animados M/T sobre capturas reales. Solo lee arte del proyecto; escribe en test-results/bocetos/out. Versión consolidada: solo lo aprobado."""
import math, os, random, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as nd
ROOT = Path(__file__).resolve().parents[3]
S = str(ROOT / "test-results" / "bocetos") + "/"
A = str(ROOT / "assets" / "art" / "pixel-v3") + "/"
CAP, OUT = S + "cap/", S + "out/"
os.makedirs(OUT, exist_ok=True)
FONT = "C:/Windows/Fonts/consolab.ttf"


def cap(n): return Image.open(CAP + n + ".png").convert("RGB")


def art(n): return Image.open(A + n).convert("RGBA")


def x2(i, k=2): return i.resize((i.width * k, i.height * k), Image.NEAREST)


def save_gif(name, frames, ms=70, scale=1, hold=None):
    """Paleta común y sin tramado, para que el pixel art no parpadee."""
    if scale != 1: frames = [f.resize((f.width * scale, f.height * scale), Image.NEAREST) for f in frames]
    step = max(1, len(frames) // 8)
    sample = frames[::step][:9]
    w, h = sample[0].size
    sheet = Image.new("RGB", (w, h * len(sample)))
    for k, f in enumerate(sample): sheet.paste(f, (0, k * h))
    pal = sheet.quantize(colors=255, method=Image.MEDIANCUT, dither=Image.NONE)
    out = [f.quantize(palette=pal, dither=Image.NONE) for f in frames]
    dur = [ms] * len(out)
    if hold:
        for k, v in hold.items(): dur[k] = v
    out[0].save(OUT + name + ".gif", save_all=True, append_images=out[1:], duration=dur, loop=0, optimize=False, disposal=1)
    print(name, len(out), os.path.getsize(OUT + name + ".gif") // 1024, "KB", out[0].size)


def ease(t): t = max(0.0, min(1.0, t)); return t * t * (3 - 2 * t)


def lerp(a, b, t): return a + (b - a) * t


def rot(sprite_logical, deg):
    """Rota en la grilla lógica y recién después escala ×2: sigue siendo pixel art."""
    return x2(sprite_logical.rotate(deg, Image.NEAREST, expand=True))


def paste_center(canvas, spr, cx, cy):
    canvas.paste(spr, (int(cx - spr.width / 2), int(cy - spr.height / 2)), spr)


def text_img(txt, size=20, color=(255, 240, 199)):
    f = ImageFont.truetype(FONT, size)
    d = ImageDraw.Draw(Image.new("L", (1, 1)))
    box = d.textbbox((0, 0), txt, font=f)
    i = Image.new("RGBA", (box[2] + 4, box[3] + 4), (0, 0, 0, 0))
    dd = ImageDraw.Draw(i); dd.fontmode = "1"
    dd.text((2, 2), txt, font=f, fill=(25, 10, 16, 255))
    dd.text((1, 1), txt, font=f, fill=color + (255,))
    return i


base = cap("mesa_vacia")
sin_termo = cap("mesa_sin_termo")
mesa = x2(art("mesa-v3.png"))
termo, mate, vaso = art("termo-mesa-v3.png"), art("mate-v3.png"), art("vaso-v3.png")
TERMO_XY, MATE_XY, VASO_XY = (1203, 168), (1088, 310), (1280, 426)
ZONE_CUP = (1082, 324, 1394, 654)


def tinted_table():
    t = Image.new("RGB", (1440, 900))
    t.paste(mesa.convert("RGB"), (0, 272))
    arr = np.array(t).astype(float)
    x0, y0, x1, y1 = ZONE_CUP
    arr[y0:y1, x0:x1] = arr[y0:y1, x0:x1] * .92 + np.array([.12, .01, .035]) * 255 * .08
    return Image.fromarray(arr.astype(np.uint8))


table = tinted_table()


def erase(img, rect):
    img.paste(table.crop(rect), rect[:2])


bg_sin_vaso = base.copy()
erase(bg_sin_vaso, (1280, 426, 1424, 614))
t2 = x2(termo)
bg_sin_vaso.paste(t2, TERMO_XY, t2)
top = base.crop((1203, 168, 1347, 426))                 # lo de arriba del vaso (con stickers) sale de la captura
bg_sin_vaso.paste(top, (1203, 168))
bg_limpio = sin_termo.copy()
erase(bg_limpio, (1088, 324, 1224, 546))
above = sin_termo.crop((1088, 310, 1224, 324))
erase(bg_limpio, (1280, 426, 1424, 614))
bg_limpio.paste(table.crop((1088, 310, 1224, 324)), (1088, 310))
termo_st = termo.copy()
st_full = Image.fromarray(np.array(base.crop((1203, 168, 1347, 518)).convert("RGBA")))
mask_t = np.array(t2)[..., 3] > 0
mask_keep = mask_t.copy()
mask_keep[258:, :] = False                                # debajo de esto lo tapa el vaso
mask_keep[142:, :0] = False
tmp = np.array(t2).copy()
src = np.array(st_full)
yy, xx = np.where(mask_keep)
mate2 = x2(mate); mate_a = np.array(mate2)[..., 3] > 0
for y, x in zip(yy, xx):
    sx, sy = x + 1203 - 1088, y + 168 - 310
    if 0 <= sy < mate_a.shape[0] and 0 <= sx < mate_a.shape[1] and mate_a[sy, sx]: continue
    tmp[y, x, :3] = src[y, x, :3]
termo_full = Image.fromarray(tmp)
termo_logical = termo_full.resize((termo.width, termo.height), Image.NEAREST)
mag = cap("dados_magenta").convert("RGBA")
dice = {}
for v in range(1, 7):
    c = np.array(mag.crop((100 * v - 90, 10, 100 * v - 90 + 62, 72)))
    key = (c[..., 0] > 220) & (c[..., 1] < 60) & (c[..., 2] > 220)
    c[key, 3] = 0
    dice[v] = Image.fromarray(c)


def die_at(canvas, v, cx, cy, deg, k=1.0):
    d = dice[v]
    if k != 1.0: d = d.resize((int(62 * k), int(62 * k)), Image.NEAREST)
    d = d.rotate(deg, Image.NEAREST, expand=True)
    paste_center(canvas, d, cx, cy)


REGION = (350, 262, 1440, 672)
LANDINGS = [(760, 359), (950, 385), (858, 457), (791, 558), (967, 563)]
VALUES = [5, 3, 2, 6, 4]
exter = art("exteriores-v3.png"); parte = x2(art("parteluces-v3.png")); nube = x2(art("nube-v3.png"))
HANDS = art("manos-jefes-v3.png")
COMMON = art("mano-v3.png")
HW, HH = 61, 53


def window_bg():
    c = base.copy()
    cell = (exter.width // 2, exter.height // 3)
    src = exter.crop(((534 - 470) // 2, 0, (534 - 470) // 2 + 189, 110))
    c.paste(x2(src).convert("RGB"), (534, 0))
    c.paste(parte, (0, 0), parte)
    c.paste(nube, (552, 0), nube)
    return c


wbg = window_bg()


def hand_cell(row, frame=0):
    return HANDS.crop((frame * HW, row * HH, frame * HW + HW, row * HH + HH))


def _pose_prev(cell, name):
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


def draw_hand(c, spr, bob=0):
    h = x2(spr)
    c.paste(h, (624, 34 + bob), h)


def m7():
    row = 0
    crop = (540, 0, 830, 230)
    idle = [hand_cell(row, i) for i in range(8)]
    fist = pose(hand_cell(row), "piedra")
    frames = []
    for f in range(16):
        c = wbg.copy(); draw_hand(c, idle[f % 8]); frames.append(c.crop(crop))
    words = ["PIEDRA", "PAPEL", "TIJERA"]
    for result in ("tijera", "papel", "piedra"):
        for beat in range(3):
            for k, dy in enumerate((-4, -14, -18, -8, 4, 10)):
                c = wbg.copy(); draw_hand(c, fist, dy)
                t = text_img(words[beat] + "...", 18)
                c.paste(t, (685 - t.width // 2, 176), t)
                frames.append(c.crop(crop))
        res = pose(hand_cell(row), result)
        for k in range(10):
            c = wbg.copy(); draw_hand(c, res, 10 if k < 2 else 2)
            t = text_img(result.upper() + "!", 24, (240, 200, 80))
            c.paste(t, (685 - t.width // 2, 174), t)
            frames.append(c.crop(crop))
        for f in range(8):
            c = wbg.copy(); draw_hand(c, idle[f % 8]); frames.append(c.crop(crop))
    save_gif("m7_piedra_papel_tijera", frames, 75, scale=2)
    # hoja de poses con tres jefes
    rows = [0, 2, 16]
    sheet = Image.new("RGB", (3 * 250, 3 * 220), (70, 96, 138))
    for r, rr in enumerate(rows):
        for k, n in enumerate(("piedra", "papel", "tijera")):
            sheet.paste(x2(pose(hand_cell(rr), n), 4), (k * 250 + 3, r * 220 + 2), x2(pose(hand_cell(rr), n), 4))
    sheet.save(OUT + "m7_poses.png")
    # comparación: qué mano aparece
    names = ["Rival 1", "Rival 2", "Jefe"]
    cmp_ = Image.new("RGB", (3 * 300, 2 * 262 + 4), (24, 16, 20))
    for line, label in enumerate(("HOY", "PROPUESTA")):
        for k in range(3):
            c = wbg.copy()
            cell = hand_cell(row) if (line == 1 or k == 2) else COMMON.crop((0, 0, HW, HH))
            draw_hand(c, cell)
            part = c.crop((545, 0, 825, 220))
            t = text_img("%s · %s" % (label, names[k]), 18)
            part = part.convert("RGB")
            cmp_.paste(part, (k * 300 + 10, line * 262 + 34))
            cmp_.paste(t, (k * 300 + 12, line * 262 + 8), t)
    cmp_.save(OUT + "m7_que_mano.png")


def t1():
    sheet = art("stickers-v3.png")
    trio = sheet.crop((19, 0, 38, 19))
    before, after = cap("t1_nuevo_antes"), cap("t1_nuevo_despues")
    therm_rect = (60, 520, 215, 860)
    start = (1035, 530); slot = (65 + 108, 525 + 134)
    frames = []
    base_fly = after.copy()
    base_fly.paste(before.crop(therm_rect), therm_rect[:2])
    for f in range(6): frames.append(before.copy())
    N = 20
    random.seed(4)
    for f in range(N):
        t = ease(f / (N - 1))
        c = base_fly.copy()
        k = lerp(4.0, 2.0, t)
        x = lerp(start[0], slot[0], t)
        y = lerp(start[1], slot[1], t) - math.sin(t * math.pi) * 150
        s = trio.resize((int(19 * k), int(19 * k)), Image.NEAREST).rotate(math.sin(t * math.pi * 3) * 22 + t * 8, Image.NEAREST, expand=True)
        # estela
        for g in range(1, 4):
            tt = ease(max(0, (f - g * 1.4)) / (N - 1))
            gx = lerp(start[0], slot[0], tt); gy = lerp(start[1], slot[1], tt) - math.sin(tt * math.pi) * 150
            ImageDraw.Draw(c).rectangle((gx - 3, gy - 3, gx + 3, gy + 3), fill=(240, 200, 80))
        paste_center(c, s, x, y)
        frames.append(c)
    for f in range(12):
        c = after.copy()
        d = ImageDraw.Draw(c)
        if f < 8:
            r = 10 + f * 8
            for a in range(0, 360, 45):
                px = slot[0] + math.cos(math.radians(a)) * r; py = slot[1] + math.sin(math.radians(a)) * r
                d.rectangle((px - 2, py - 2, px + 2, py + 2), fill=(255, 232, 130))
        if f < 10:
            t_ = text_img("¡Nuevo! Trío · Nivel 1", 18)
            c.paste(t_, (slot[0] + 40, slot[1] - 40 - f), t_)
        frames.append(c)
    frames = [f.crop((0, 300, 1300, 900)) for f in frames]
    save_gif("t1_suelto_nuevo", frames, 55, hold={len(frames) - 1: 1100})
    # repetido: sin vuelo, solo marca de nivel sobre el termo
    b2, a2 = cap("t1_repetido_antes"), cap("t1_repetido_despues")
    fr = [b2.copy() for _ in range(6)]
    for f in range(18):
        c = a2.copy()
        t_ = text_img("Trío · Nivel 1 → 2", 18, (240, 200, 80))
        c.paste(t_, (slot[0] + 40, slot[1] - 30 - f), t_)
        fr.append(c)
    save_gif("t1_suelto_repetido", [f.crop((0, 300, 1300, 900)) for f in fr], 70, hold={23: 900})
    for name, prefix, last in (("t1_paquete_hoy", "seq_t1hoy", 34), ("t1_paquete_propuesta", "seq_t1prop", 33)):
        seq = []
        for k in range(last):
            p = CAP + "%s_%02d.png" % (prefix, k)
            if os.path.exists(p): seq.append(Image.open(p).convert("RGB").resize((720, 450), Image.NEAREST))
        save_gif(name, seq, 90, hold={len(seq) - 1: 900})


sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / "tools" / "art"))
_cwd = os.getcwd()
os.chdir(ROOT)
import texturas, make_salon
from pixel_lib import Canvas
_orig_bandera = texturas.bandera
_flag_cv = Canvas(720, 150); _orig_bandera(_flag_cv, 652, 30)
FLAG = _flag_cv.a.copy()
texturas.bandera = lambda *a, **k: None
WALL = np.array(Image.fromarray(make_salon.salon().a).convert("RGB"))
texturas.bandera = _orig_bandera
os.chdir(_cwd)
FLAG_MASK = FLAG[..., 3] > 0
cup_front = x2(Image.open(A + "vaso-frente-v3.png").convert("RGBA"))


def m1():
    frames = [Image.open(CAP + "seq_m1_%02d.png" % f).convert("RGB").crop((14, 0, 1120, 410)) for f in range(62)]
    save_gif("m1_arrastre", frames, 60, hold={61: 900})


def _mate_prev():
    crop = (760, 40, 1440, 640)
    rest = (1275, 343)
    keys = [(0, rest, 0), (7, (1275, 232), 0), (16, (1000, 232), 0), (24, (966, 426), -68), (48, (966, 426), -68), (56, (1000, 232), 0), (65, (1275, 232), 0), (72, rest, 0), (78, rest, 0)]
    def at(f):
        for (a, pa, ra), (b, pb, rb) in zip(keys, keys[1:]):
            if a <= f <= b:
                t = ease((f - a) / max(1, b - a))
                return (lerp(pa[0], pb[0], t), lerp(pa[1], pb[1], t)), lerp(ra, rb, t)
        return rest, 0
    random.seed(5)
    steam, frames = [], []
    m2_img, c2_img = x2(mate), x2(vaso)
    mouth = (1156, 432)
    for f in range(78):
        (cx, cy), r = at(f)
        c = bg_limpio.copy()
        spr = rot(termo_logical, r)
        over = 7 <= f <= 65
        if not over: paste_center(c, spr, cx, cy)
        c.paste(m2_img, MATE_XY, m2_img)
        c.paste(c2_img, VASO_XY, c2_img)
        d = ImageDraw.Draw(c)
        if 26 <= f <= 47:
            a = math.radians(r)
            sx, sy = int(cx - math.sin(a) * 175) // 2 * 2, int(cy - math.cos(a) * 175) // 2 * 2
            y = sy
            while y < mouth[1]:
                t = (y - sy) / max(1, mouth[1] - sy)
                x = int(lerp(sx, mouth[0], t ** .6)) // 2 * 2
                col = (214, 238, 248) if (y // 2 + f) % 3 else (150, 200, 226)
                d.rectangle((x, y, x + 3, y + 1), fill=col)
                if (y // 2 + f) % 5 == 0: d.rectangle((x + 4, y, x + 5, y + 1), fill=(240, 250, 255))
                y += 2
            for k in range(8):
                px = mouth[0] + random.randint(-22, 22); py = mouth[1] + random.randint(-4, 6)
                d.rectangle((px // 2 * 2, py // 2 * 2, px // 2 * 2 + 1, py // 2 * 2 + 1), fill=random.choice([(190, 220, 120), (230, 245, 180), (120, 170, 70)]))
            if f % 2 == 0: steam.append([mouth[0] + random.randint(-18, 18), mouth[1] - 8, random.randint(14, 24)])
        for s_ in steam:
            if s_[2] > 0:
                g = 230 - (24 - s_[2]) * 4
                d.rectangle((int(s_[0]) // 2 * 2, int(s_[1]) // 2 * 2, int(s_[0]) // 2 * 2 + 3, int(s_[1]) // 2 * 2 + 3), fill=(g, g, g))
                s_[1] -= 4; s_[0] += random.choice((-2, 0, 2)); s_[2] -= 1
        if over: paste_center(c, spr, cx, cy)
        frames.append(c.crop(crop))
    save_gif("m4_termo_ceba", frames, 70, hold={0: 800, 77: 800})


def m4_soda():
    crop = (360, 190, 560, 268)
    frames = []
    random.seed(9)
    nx, ny = 399, 229
    AMBER = (200, 124, 26); FOAM = (250, 246, 228)
    for f in range(52):
        c = base.copy()
        d = ImageDraw.Draw(c)
        pressing = 4 <= f <= 34
        if pressing:
            region = c.crop((386, 224, 406, 236))
            c.paste(region, (386, 226))
            d = ImageDraw.Draw(c)
            aim = ease((f - 9) / 5)
            power = 1 if f < 31 else max(0, (35 - f) / 4)
            dx, h, dr = lerp(110, 13, aim) * power, lerp(22, 12, aim) * power, lerp(34, 20, aim) * power
            for k in range(46):
                t = k / 46
                x = nx + dx * t
                y = ny - h * math.sin(min(1, t * 1.25) * math.pi) + dr * t * t
                if (k + f * 2) % 9 == 0: continue
                col = (214, 240, 250) if (k + f) % 3 else (150, 205, 232)
                d.rectangle((int(x) // 2 * 2, int(y) // 2 * 2, int(x) // 2 * 2 + 3, int(y) // 2 * 2 + 3), fill=col)
            for k in range(4):
                sx = nx + dx + random.randint(-8, 8)
                sy = min(264, ny + dr + random.randint(-6, 8))
                d.rectangle((int(sx) // 2 * 2, int(sy) // 2 * 2, int(sx) // 2 * 2 + 1, int(sy) // 2 * 2 + 1), fill=(226, 244, 252))
        # el vaso se va llenando desde que el chorro lo alcanza
        fill = ease((f - 13) / 20)
        if f >= 13:
            top = int(lerp(252, 248, fill)) // 2 * 2
            d.rectangle((410, top, 415, 255), fill=AMBER)
            if f > 16:
                foam_top = top - 2 if fill < 1 else 244
                d.rectangle((410, foam_top, 415, top - 1), fill=FOAM)
                for k in range(2):
                    bx = random.randrange(410, 415, 2); by = random.randrange(top, 255, 2)
                    if f <= 44: d.rectangle((bx, by, bx + 1, by + 1), fill=(236, 186, 92))
        frames.append(c.crop(crop))
    save_gif("m4_soda", frames, 60, scale=3, hold={0: 800, 51: 700})


def m4_bandera():
    frames = []
    keep = np.array(t2)[..., 3] > 0
    orig = np.array(base)
    ty, tx = np.where(keep)
    valid = (ty + 168 < 900) & (tx + 1203 < 1440)
    crop = (1240, 40, 1440, 280)
    X0, X1, Y0, Y1 = 646, 694, 31, 118
    for f in range(34):
        amp = 3.2 * math.exp(-f / 16) * (1 if f >= 2 else 0)
        lg = WALL.copy()
        for y in range(27, Y1):
            k = (max(0, y - 30) / 82) ** 1.3
            dx = int(round(amp * k * math.sin((y - 30) * .13 - f * .8)))
            shade = 1 + .09 * math.cos((y - 30) * .13 - f * .8) * min(1, amp / 2.5) * k
            for x in range(640, 700):
                if FLAG_MASK[y, x]:
                    lg[y, x + dx] = np.clip(FLAG[y, x, :3] * shade, 0, 255)
        big = Image.fromarray(lg).resize((1440, 300), Image.NEAREST)
        c = base.copy()
        rect = (X0 * 2, Y0 * 2, X1 * 2, Y1 * 2)
        c.paste(big.crop(rect), rect[:2])
        out = np.array(c)
        out[ty[valid] + 168, tx[valid] + 1203] = orig[ty[valid] + 168, tx[valid] + 1203]
        frames.append(Image.fromarray(out).crop(crop))
    save_gif("m4_bandera", frames, 70, scale=2, hold={0: 800, 33: 500})


def pose(cell, name):
    return fist(cell) if name == "piedra" else _pose_prev(cell, name)


def m4_afford():
    arr = np.array(base)
    gold = np.array([255, 224, 120])
    def ring(mask, ox, oy, exclude=None):
        d = nd.binary_dilation(mask, iterations=2) & ~mask
        ys, xs = np.where(d)
        ok = (ys + oy < 900) & (xs + ox < 1440) & (ys + oy >= 0) & (xs + ox >= 0)
        ys, xs = ys[ok], xs[ok]
        arr[ys + oy, xs + ox] = gold
    # mano
    ring(np.array(x2(COMMON.crop((0, 0, HW, HH))))[..., 3] > 0, 624, 34)
    # bandera, atrás del termo
    fm = np.kron(FLAG_MASK_RING, np.ones((2, 2), bool))
    ring(fm, 0, 0)
    # sifones: lo azulado dentro de su recuadro
    for bx in (384, 816):
        box = np.array(base.crop((bx, 220, bx + 26, 262))).astype(int)
        sm = (box[..., 2] >= box[..., 0] * .95) & (box[:, :, 2] > 40)
        sm[:, 22:] &= box[:, 22:, 1] < 200
        sm = nd.binary_closing(sm, iterations=2)
        ring(sm, bx, 220)
    # termo y vaso, adelante
    tm = np.array(t2)[..., 3] > 0
    orig = np.array(base)
    ring(tm, 1203, 168)
    y_, x_ = np.where(tm)
    arr[y_ + 168, x_ + 1203] = orig[y_ + 168, x_ + 1203]
    m2_ = np.array(mate2)[..., 3] > 0
    y_, x_ = np.where(m2_)
    arr[y_ + 310, x_ + 1088] = orig[y_ + 310, x_ + 1088]
    vm = np.array(x2(vaso))[..., 3] > 0
    vm_core = vm.copy()
    y_, x_ = np.where(vm)
    arr[y_ + 426, x_ + 1280] = orig[y_ + 426, x_ + 1280]
    ring(nd.binary_erosion(vm, iterations=1, border_value=1) if False else vm_core, 1280, 426)
    Image.fromarray(arr).crop((334, 0, 1440, 640)).save(OUT + "m4_senal.png")


def m4_mate():
    # el fondo sin termo trae el termo flotando en la ventana: esa parte sale de la captura normal
    bg_limpio.paste(base.crop((760, 0, 1000, 272)), (760, 0))
    _mate_prev()


_FM = FLAG_MASK.copy(); _FM[:31] = False
FLAG_MASK_RING = _FM


def cup_mouth(cx, cy, deg):
    """Centro de la boca del vaso rotado (la boca está 88 px arriba del centro del dibujo)."""
    a = math.radians(deg)
    return cx - math.sin(a) * 88, cy - math.cos(a) * 88


def m6_a():
    name = "m6_a_levanta"
    frames = []
    rest = (1352, 520)
    lift, tilt = (1230, 372), 118
    v2 = vaso
    for f in range(10):
        c = bg_sin_vaso.copy()
        dx = [0, -6, 6, -8, 8, -6, 6, -4, 4, 0][f]
        dy = [0, -2, 0, -4, 0, -2, 0, -2, 0, 0][f]
        paste_center(c, x2(v2), rest[0] + dx, rest[1] + dy)
        for k, off in enumerate((-32, 0, 30)):
            die_at(c, VALUES[k], rest[0] + dx + off, 446 + dy - (f + k) % 3 * 5, f * 37 + k * 50, .78)
        paste_center(c, cup_front, rest[0] + dx, rest[1] + dy)
        frames.append(c)
    for f in range(9):
        t = ease((f + 1) / 9)
        c = bg_sin_vaso.copy()
        paste_center(c, rot(v2, lerp(0, tilt, t)), lerp(rest[0], lift[0], t), lerp(rest[1], lift[1], t))
        frames.append(c)
    mx, my = cup_mouth(lift[0], lift[1], tilt)
    delays = [0, 2, 3, 5, 6]
    spin = [540, -480, 600, -520, 460]
    for f in range(22):
        c = bg_sin_vaso.copy()
        jolt = 3 if f < 8 and f % 2 else 0
        for i in range(5):
            t = (f - delays[i]) / 12
            if t <= 0: continue
            t = min(1, t)
            ex, ey = LANDINGS[i]
            # salen hacia abajo por la boca, caen y ruedan hasta su lugar
            x = lerp(mx + (i - 2) * 6, ex, 1 - (1 - t) ** 2)
            y = lerp(my + 6, ey, t) + math.sin(t * math.pi) * 28 * (1 - t)
            bounce = abs(math.sin((f - delays[i] - 12) * .9)) * 7 * max(0, 1 - (f - delays[i] - 12) / 5) if t >= 1 else 0
            die_at(c, VALUES[i], x, y - bounce, spin[i] * (1 - t) + (i * 13 - 20))
        # el vaso va adelante: los dados aparecen recién al asomar por la boca
        paste_center(c, rot(v2, tilt + (6 if jolt else 0)), lift[0], lift[1] + jolt)
        frames.append(c)
    for f in range(10):
        t = ease((f + 1) / 10)
        c = bg_sin_vaso.copy()
        for i in range(5): die_at(c, VALUES[i], LANDINGS[i][0], LANDINGS[i][1], i * 13 - 20)
        paste_center(c, rot(v2, lerp(tilt, 0, t)), lerp(lift[0], rest[0], t), lerp(lift[1], rest[1], t) - math.sin(t * math.pi) * 10)
        frames.append(c)
    for f in range(4):
        c = bg_sin_vaso.copy()
        for i in range(5): die_at(c, VALUES[i], LANDINGS[i][0], LANDINGS[i][1], i * 13 - 20)
        paste_center(c, x2(v2), rest[0], rest[1] - (4 if f == 1 else 0))
        frames.append(c)
    frames = [f.crop(REGION) for f in frames]
    save_gif(name, frames, 55, hold={len(frames) - 1: 1100})


def m6():
    m6_a()


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


TASKS = {"m1": m1, "m6": m6, "mate": m4_mate, "soda": m4_soda, "bandera": m4_bandera, "m7": m7, "senal": m4_afford, "t1": t1}
for t in (sys.argv[1:] or TASKS):
    TASKS[t]()
