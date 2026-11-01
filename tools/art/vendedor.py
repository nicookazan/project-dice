"""El vendedor de la tienda en pixel art, convertido desde la ilustración original (shop-salesman-v1.png).

Respeta el dibujo original (decisión del autor): se reduce a la grilla lógica (720×450) con la mediana
de cada celda, se aplana la textura de foto con un suavizado que conserva los bordes, y cada zona (cara,
pelo, manos, traje, camisa, corbata, gemelo) se pinta con su propia paleta corta sacada de los colores
del original. Después se quitan las manchas sueltas (fuera de ojos, cejas, nariz, boca y arrugas) y se
marca el contorno. No se redibujan rasgos: a mano solo se repone el brillo de las pupilas y el blanco
del ojo iluminado, que la reducción borra. Las siluetas se calcaron del original sobre grillas ampliadas.
"""
from __future__ import annotations

import numpy as np
from PIL import Image
from scipy import ndimage

from pixel_lib import poly_mask, edge_of, clean_labels

SRC = "assets/art/shop-salesman-v1.png"
W, H = 720, 450

# ---------- siluetas calcadas del original (coordenadas lógicas)
HEAD_P = [(102, 147), (100, 144), (97, 140), (93, 137), (90, 133), (87, 130), (85, 125), (84, 120), (84, 115),
          (86, 110), (89, 107), (92, 104), (96, 101), (99, 97), (102, 92), (104, 87), (106, 81), (110, 72),
          (115, 65), (120, 59), (125, 54), (130, 50), (135, 48), (140, 46), (145, 45), (150, 44), (160, 43),
          (170, 44), (180, 44), (190, 47), (195, 49), (200, 53), (205, 57), (210, 63), (213, 69), (216, 74),
          (218, 79), (221, 84), (223, 88), (224, 94), (223, 99), (221, 103), (218, 106), (217, 112), (215, 116),
          (212, 120), (211, 126), (210, 131), (205, 136), (201, 141), (199, 145), (197, 150), (194, 155),
          (191, 160), (187, 165), (183, 170), (179, 175), (174, 180), (169, 185), (163, 190), (150, 196),
          (138, 200), (120, 200), (104, 190), (100, 160)]
# piel de la cara (entradas, sienes, mandíbula y cuello) y oreja; el resto de la cabeza es pelo
FACE_P = [(122, 100), (125, 93), (130, 86), (135, 80), (140, 76), (147, 71), (155, 68), (165, 66), (178, 66),
          (190, 68), (200, 71), (208, 78), (213, 86), (216, 94), (217, 102), (217, 112), (215, 116), (212, 120),
          (211, 126), (210, 131), (205, 136), (201, 141), (199, 145), (197, 150), (194, 155), (191, 160),
          (187, 165), (183, 170), (179, 175), (174, 180), (169, 185), (163, 190), (150, 196), (138, 200),
          (120, 200), (104, 190), (102, 170), (106, 150), (110, 144), (116, 140), (121, 132)]
EAR_P = [(121, 101), (116, 97), (110, 96), (106, 99), (104, 106), (104, 116), (106, 125), (109, 131), (114, 135),
         (119, 135), (121, 128)]
SIDEBURN_P = [(121, 99), (127, 99), (129, 112), (131, 124), (131, 134), (127, 137), (123, 133), (122, 120)]
COLLAR_ROI = [(100, 140), (118, 150), (140, 178), (162, 186), (182, 192), (178, 210), (168, 226), (166, 268),
              (128, 268), (110, 230), (100, 190)]
TIE_ROI = [(138, 186), (164, 186), (168, 200), (162, 210), (166, 250), (166, 272), (148, 276), (130, 266),
           (134, 236), (140, 210), (134, 198)]
HAND_B_ROI = [(140, 280), (150, 266), (170, 258), (186, 248), (204, 247), (210, 262), (232, 274), (252, 280),
              (257, 288), (257, 300), (240, 310), (210, 318), (180, 324), (150, 322), (138, 300)]
CUFF_B_ROI = [(124, 276), (148, 272), (160, 300), (162, 334), (156, 346), (136, 350), (124, 336), (124, 300)]
HAND_A_P = [(252, 105), (256, 103), (259, 106), (260, 112), (259, 120), (258, 128), (257, 138), (256, 146),
            (256, 154), (257, 160), (255, 163), (252, 158), (250, 150), (248, 142), (246, 134), (245, 126),
            (245, 120), (247, 115), (249, 110)]
CUFF_A_P = [(250, 161), (255, 160), (256, 172), (255, 186), (251, 186), (250, 174)]
# zona del traje que en el original tapaba el maletín (abajo a la derecha): se completa con sombra
HIDDEN_P = [(200, 330), (262, 300), (264, 450), (196, 450)]

# zonas de rasgos: ahí no se borran píxeles sueltos
FEATURES = [(150, 96, 216, 118), (154, 108, 186, 132), (186, 114, 212, 138), (170, 106, 198, 162),
            (146, 152, 194, 178), (104, 96, 124, 138), (196, 247, 206, 262), (150, 80, 212, 98),
            (120, 98, 133, 138)]

OUT_DARK = (24, 14, 12)


def grid_median(img: Image.Image, gw: int, gh: int) -> np.ndarray:
    """Mediana por celda sobre la grilla lógica (versión vectorizada de spriteforge.gridsnap.snap)."""
    a = np.array(img.convert("RGB")).astype(np.int32)
    h, w = a.shape[:2]
    xs = np.minimum((np.arange(w) * gw) // w, gw - 1)
    ys = np.minimum((np.arange(h) * gh) // h, gh - 1)
    cid = (ys[:, None] * gw + xs[None, :]).ravel()
    counts = np.bincount(cid, minlength=gw * gh)
    mid = np.concatenate([[0], np.cumsum(counts)[:-1]]) + counts // 2
    out = np.zeros((gh * gw, 3), np.float64)
    for c in range(3):
        v = a[..., c].ravel()
        out[:, c] = v[np.lexsort((v, cid))][mid]
    return out.reshape(gh, gw, 3)


def to_lab(c: np.ndarray) -> np.ndarray:
    c = np.asarray(c, float) / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    x = c @ np.array([0.4124, 0.3576, 0.1805]) / 0.9505
    y = c @ np.array([0.2126, 0.7152, 0.0722])
    z = c @ np.array([0.0193, 0.1192, 0.9505]) / 1.089
    f = np.where(np.stack([x, y, z], -1) > 0.008856, np.cbrt(np.stack([x, y, z], -1)),
                 7.787 * np.stack([x, y, z], -1) + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def bilateral(lab: np.ndarray, mask: np.ndarray, r: int = 2, ss: float = 1.3, sr: float = 7.0, iters: int = 2):
    """Suavizado que respeta bordes (solo mezcla píxeles parecidos y de la misma zona)."""
    out = lab.copy()
    for _ in range(iters):
        acc = np.zeros_like(out)
        wsum = np.zeros(out.shape[:2])
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                sh = np.roll(np.roll(out, dy, 0), dx, 1)
                sm = np.roll(np.roll(mask, dy, 0), dx, 1)
                d2 = ((sh - out) ** 2).sum(-1)
                wgt = np.exp(-(dx * dx + dy * dy) / (2 * ss * ss)) * np.exp(-d2 / (2 * sr * sr)) * sm
                acc += sh * wgt[..., None]
                wsum += wgt
        out = np.where(mask[..., None], acc / np.maximum(wsum, 1e-9)[..., None], out)
    return out


def kmeans(lab: np.ndarray, k: int, seed: int = 3, iters: int = 30) -> np.ndarray:
    rng = np.random.default_rng(seed)
    cent = [lab[rng.integers(len(lab))]]
    for _ in range(1, k):
        d = np.min(((lab[:, None, :] - np.array(cent)[None]) ** 2).sum(-1), 1)
        cent.append(lab[rng.choice(len(lab), p=d / d.sum())])
    cent = np.array(cent)
    for _ in range(iters):
        lbl = np.argmin(((lab[:, None, :] - cent[None]) ** 2).sum(-1), 1)
        for j in range(k):
            if (lbl == j).any():
                cent[j] = lab[lbl == j].mean(0)
    return cent[np.argsort(cent[:, 0])]


def lab_to_rgb(lab: np.ndarray) -> np.ndarray:
    L, a, b = lab[..., 0], lab[..., 1], lab[..., 2]
    fy = (L + 16) / 116
    fx, fz = fy + a / 500, fy - b / 200
    f = np.stack([fx, fy, fz], -1)
    xyz = np.where(f ** 3 > 0.008856, f ** 3, (f - 16 / 116) / 7.787) * np.array([0.9505, 1.0, 1.089])
    m = np.array([[3.2406, -1.5372, -0.4986], [-0.9689, 1.8758, 0.0415], [0.0557, -0.2040, 1.0570]])
    rgb = xyz @ m.T
    rgb = np.where(rgb > 0.0031308, 1.055 * np.power(np.clip(rgb, 0, None), 1 / 2.4) - 0.055, 12.92 * rgb)
    return np.clip(np.round(rgb * 255), 0, 255).astype(np.uint8)


def feature_mask() -> np.ndarray:
    m = np.zeros((H, W), bool)
    for x0, y0, x1, y1 in FEATURES:
        m[y0:y1, x0:x1] = True
    return m


def regions(rgb: np.ndarray) -> dict[str, np.ndarray]:
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    v = np.max(rgb, -1) / 255
    s = (np.max(rgb, -1) - np.min(rgb, -1)) / np.maximum(np.max(rgb, -1), 1)
    navy = (b > r + 4) & (v < 0.6)
    light = (v > 0.55) & (s < 0.35)
    yy, xx = np.mgrid[0:H, 0:W]
    hand_a = poly_mask(W, H, HAND_A_P)
    cuff_a = poly_mask(W, H, CUFF_A_P) & ~hand_a
    collar = poly_mask(W, H, COLLAR_ROI) & light & (yy > 142)
    collar = ndimage.binary_fill_holes(ndimage.binary_closing(collar, iterations=1)) & poly_mask(W, H, COLLAR_ROI)
    # la cabeza incluye el cuello hasta la camisa; el cuello de la camisa y el traje tienen prioridad
    head = poly_mask(W, H, HEAD_P) & ~collar & ~(navy & (yy > 150))
    tie = poly_mask(W, H, TIE_ROI) & ~collar & ~head & ~light
    cuff_b = poly_mask(W, H, CUFF_B_ROI) & (light | (s < 0.3) & (v > 0.4))
    hand_b = poly_mask(W, H, HAND_B_ROI) & ~navy & ~cuff_b & (r > b + 18)
    # solo la mano: el componente principal (afuera quedan los filetes dorados del maletín viejo)
    lab_b, nb = ndimage.label(hand_b)
    if nb:
        sizes = ndimage.sum(hand_b, lab_b, range(1, nb + 1))
        hand_b = lab_b == (int(np.argmax(sizes)) + 1)
    hand_b = ndimage.binary_fill_holes(ndimage.binary_closing(hand_b, iterations=1))
    hand_b &= ~((xx > 244) & (yy > 300))
    # todo lo que está dentro del puño y no es azul ni mano es puño (incluye su reflejo cálido),
    # salvo el gemelo dorado, que tiene su propia zona
    cufflink = poly_mask(W, H, [(131, 328), (142, 328), (142, 340), (131, 340)]) & (r > b + 20) & ~navy
    cuff_b = (cuff_b | poly_mask(W, H, CUFF_B_ROI) & ~navy & ~hand_b) & ~cufflink
    # traje: azul del original desde los hombros hacia abajo, sin huecos
    suit = navy & (yy > 138) & (xx < 262)
    suit = ndimage.binary_closing(suit, iterations=2)
    lab, n = ndimage.label(suit)
    if n:
        sizes = ndimage.sum(suit, lab, range(1, n + 1))
        suit = lab == (int(np.argmax(sizes)) + 1)
    suit = ndimage.binary_fill_holes(suit | poly_mask(W, H, HIDDEN_P))
    taken = head | hand_a | cuff_a | collar | tie | cuff_b | hand_b | cufflink
    suit &= ~taken
    # el pecho entre solapas que quede dentro del traje y no sea camisa ni corbata es traje
    fill = ndimage.binary_fill_holes(suit | collar | tie | hand_b | cuff_b) & ~taken
    suit |= fill & (yy > 140) & (xx < 262)
    face = head & (poly_mask(W, H, FACE_P) | poly_mask(W, H, EAR_P)) & ~poly_mask(W, H, SIDEBURN_P)
    hair = head & ~face
    return {"suit": suit, "head": head, "face": face, "hair": hair, "collar": collar, "tie": tie,
            "hand_b": hand_b, "cuff_b": cuff_b, "cufflink": cufflink, "hand_a": hand_a, "cuff_a": cuff_a}


# paletas por zona: cantidad de tonos, suavizado (radio, sigma de color) y tamaño mínimo de mancha
ZONES = {
    "face": (10, 3, 6.5, 6),
    "hair": (6, 1, 7.0, 3),
    "hand_b": (8, 3, 6.5, 5),
    "hand_a": (6, 2, 6.5, 3),
    "suit": (6, 3, 9.0, 10),
    "collar": (5, 2, 6.0, 5),
    "cuff_b": (4, 2, 6.0, 9),
    "cuff_a": (3, 1, 6.0, 2),
    "cufflink": (3, 1, 8.0, 1),
    "tie": (4, 1, 8.0, 3),
}


def convert() -> tuple[np.ndarray, dict[str, np.ndarray], dict[str, np.ndarray]]:
    """Devuelve (rgba 720×450 solo con el vendedor, máscaras, paletas)."""
    rgb = grid_median(Image.open(SRC), W, H)
    M = regions(rgb)
    lab = to_lab(rgb)
    feats = feature_mask()
    out = np.zeros((H, W, 4), np.uint8)
    palettes = {}
    for name, (k, rad, sr, min_size) in ZONES.items():
        m = M[name]
        if not m.any():
            continue
        sm = bilateral(lab, m, r=rad, ss=1.2 + 0.3 * rad, sr=sr, iters=3 if rad >= 3 else 2)
        if (m & feats).any():
            # en los rasgos apenas se suaviza: ojos, cejas, boca y arrugas quedan como en el original
            fine = bilateral(lab, m, r=1, ss=1.0, sr=5.0, iters=1)
            sm = np.where(feats[..., None], fine, sm)
        sample = m
        if name == "suit":
            # la paleta del traje sale solo de píxeles azules (sin reflejos ni restos del maletín viejo)
            sample = m & (rgb[..., 2] > rgb[..., 0] + 4)
        cent = kmeans(sm[sample], k)
        idx = np.zeros((H, W), np.int32)
        idx[m] = np.argmin(((sm[m][:, None, :] - cent[None]) ** 2).sum(-1), 1)
        cleaned = clean_labels(idx, m & ~feats, min_size=min_size, passes=2)
        light_clean = clean_labels(idx, m & feats, min_size=2, passes=1)
        idx = np.where(feats, light_clean, cleaned)
        if name in ("cuff_b", "cuff_a", "collar"):
            # la tela blanca no lleva manchas de color: los tonos saturados pasan al neutro más parecido
            chroma = np.hypot(cent[:, 1], cent[:, 2])
            neutral = np.where(chroma < 22)[0]
            if len(neutral):
                for j in np.where(chroma >= 22)[0]:
                    nearest = neutral[np.argmin(np.abs(cent[neutral, 0] - cent[j, 0]))]
                    idx[idx == j] = nearest
        pal = lab_to_rgb(cent)
        palettes[name] = pal
        out[m, :3] = pal[idx[m]]
        out[m, 3] = 255
    # retoque a mano (planeado sobre el dump de sprite-forge): el brillo de cada pupila y el blanco del ojo
    # iluminado, que la reducción funde con el iris; posiciones tomadas del original
    for x, y in ((169, 119), (196, 127)):
        out[y, x, :3] = (242, 228, 212)
    box_lab = to_lab(out[116:124, 160:167, :3].astype(float))
    eye_white = (np.hypot(box_lab[..., 1], box_lab[..., 2]) < 26) & (box_lab[..., 0] > 30)
    out[116:124, 160:167][eye_white, :3] = (198, 162, 140)
    # contorno: borde exterior de la figura con un tono muy oscuro, salvo donde la piel está iluminada
    # (la mejilla contra la lámpara no lleva línea en el original); sin tocar el lado del maletín
    fig = out[..., 3] > 0
    edge = edge_of(fig)
    edge[:, 256:] = False
    edge[H - 1, :] = False
    lit_skin = (M["head"] | M["hand_b"] | M["hand_a"]) & (to_lab(out[..., :3].astype(float))[..., 0] > 42)
    out[edge & ~lit_skin, :3] = OUT_DARK
    return out, M, palettes


_CACHE: dict = {}


def draw(cv, layer: str = "all") -> dict[str, np.ndarray]:
    """'back': el vendedor entero (va antes del maletín); 'front': solo manos y puños, que en el original
    quedan delante del canto del maletín; 'all': todo junto."""
    if "out" not in _CACHE:
        _CACHE["out"], _CACHE["M"], _ = convert()
    out, M = _CACHE["out"], _CACHE["M"]
    m = out[..., 3] > 0
    if layer == "front":
        m &= M["hand_a"] | M["hand_b"] | M["cuff_a"] | M["cuff_b"] | M["cufflink"]
    cv.a[m] = out[m]
    return M
