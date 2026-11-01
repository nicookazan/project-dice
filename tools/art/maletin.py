"""El maletín de la tienda con la forma del original (shop-salesman-v1.png) y materiales pixel-v3.

La tapa queda casi de frente, el interior es un trapecio apenas más angosto arriba (las zonas de compra
de main.gd se diseñaron sobre esa forma) y la base se abre hacia abajo, como en la ilustración. Cuero
negro cálido (grano fino, ribete bordó entre filetes dorados, doble costura clara), herrajes dorados y terciopelo bordó con el mismo pelo corto que el paño de la mesa.
"""
from __future__ import annotations

import numpy as np

from pixel_lib import Canvas, OUTLINE, GOLD, WARMBLK as LEATHER, PANO, hash2, poly_mask, edge_of

W, H = 720, 450
IN_Y0, IN_Y1 = 123, 311          # interior de terciopelo
DIV_X = (456, 460)               # divisor vertical
DIV_Y = (216, 220)               # divisor horizontal
LID_P = [(262, 92), (663, 92), (668, 95), (670, 100), (684, 312), (241, 312), (255, 100), (257, 95)]
BASE_P = [(241, 311), (684, 311), (699, 330), (712, 352), (717, 374), (715, 382), (210, 382), (208, 374),
          (213, 352), (226, 330)]
LIP_Y = (312, 329)               # borde superior de la base (visto desde arriba), con tira de terciopelo
FRONT_Y = (330, 381)             # frente de la base


def in_left(y: float) -> float:
    return 272 - (y - IN_Y0) * 18 / (IN_Y1 - IN_Y0)


def in_right(y: float) -> float:
    return 653 + (y - IN_Y0) * 19 / (IN_Y1 - IN_Y0)


def side_x(poly, y: float, left: bool) -> float:
    """Borde izquierdo o derecho de un polígono convexo a la altura y."""
    xs = []
    for (x0, y0), (x1, y1) in zip(poly, poly[1:] + poly[:1]):
        if y0 == y1 or not (min(y0, y1) <= y <= max(y0, y1)):
            continue
        xs.append(x0 + (y - y0) * (x1 - x0) / (y1 - y0))
    return (min(xs) if left else max(xs)) if xs else 0


# ---------- herrajes
def latch(cv: Canvas, x: int, y: int) -> None:
    """Cierre dorado: placa con traba, 22×16."""
    rows = [
        "..000000000000000000..",
        ".06555555555555555520.",
        "0654444444444444443320",
        "0544333333333333332210",
        "0543300000000000032210",
        "0543301111111111032210",
        "0543301122222211032210",
        "0543301126555211032210",
        "0543301124333211032210",
        "0543301122222211032210",
        "0543301111111111032210",
        "0543300000000000032210",
        "0544333333333333332210",
        "0433222222222222221110",
        ".02222222222222222110.",
        "..000000000000000000..",
    ]
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch.isdigit():
                cv.put(x + i, y + j, GOLD[int(ch)])


def corner_cap(cv: Canvas, x: int, y: int, fx: bool, fy: bool) -> None:
    """Esquinero dorado de 14×14 con remache."""
    rows = [
        "....0000000000",
        "..005555555544",
        ".0554444444433",
        ".0544333333322",
        "054433..222211",
        "05433.",
        "0543..",
        "0543.",
        "0543",
        "0432",
        "0432",
        "0432",
        "0321",
        "0321",
    ]
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch.isdigit():
                v = int(ch)
                if v > 0 and (fx or fy):
                    v = max(1, v - (1 if fx else 0) - (1 if fy else 0))
                cv.put(x + (13 - i if fx else i), y + (13 - j if fy else j), GOLD[v])
    rx, ry = (x + 10 if fx else x + 3), (y + 10 if fy else y + 3)
    cv.put(rx, ry, GOLD[5])
    cv.put(rx + 1, ry, GOLD[3])
    cv.put(rx, ry + 1, GOLD[3])
    cv.put(rx + 1, ry + 1, GOLD[1])


CORNER = ["######", "#.....", "#.###.", "#.#...", "#.#...", "#....."]


def corner_bracket(cv: Canvas, x: int, y: int, fx: bool, fy: bool) -> None:
    for j in range(6):
        for i in range(6):
            if CORNER[j][i] != "#":
                continue
            lit = (not fx and not fy) or (j == 0 and not fy) or (i == 0 and not fx)
            cv.put(x + (5 - i if fx else i), y + (5 - j if fy else j), GOLD[4] if lit else GOLD[2])


def handle(cv: Canvas, cx: int, half: int, ytop: int, ybase: int) -> None:
    """Manija de cuero gruesa sobre la tapa, con argollas doradas."""
    x0, x1 = cx - half, cx + half
    thick = 11
    m = np.zeros((H, W), bool)
    for x in range(x0, x1 + 1):
        u = (x - cx) / half
        top = ytop + round(9 * u ** 6)
        m[top:top + thick, x] = True
    m[ytop + 8:ybase - 6, x0:x0 + 10] = True
    m[ytop + 8:ybase - 6, x1 - 9:x1 + 1] = True
    inner = m & ~edge_of(m)
    cv.fill(m, OUTLINE)
    cv.fill(inner, LEATHER[3])
    for y, x in zip(*np.where(inner)):
        if not inner[y - 1, x] or not inner[y, x - 1]:
            cv.put(x, y, LEATHER[6] if not inner[y - 1, x] and y < ytop + 6 else LEATHER[5])
        elif not inner[y + 1, x] or not inner[y, x + 1]:
            cv.put(x, y, LEATHER[1])
        elif not inner[y - 2, x]:
            cv.put(x, y, LEATHER[4])
    for x in range(x0 + 10, x1 - 9):
        if x % 4 < 2:
            cv.put(x, ytop + round(9 * ((x - cx) / half) ** 6) + 4, LEATHER[1])
    for fx in (x0 - 3, x1 - 12):
        cv.rect(fx, ybase - 12, 16, 12, GOLD[0])
        cv.rect(fx + 1, ybase - 11, 14, 10, GOLD[3])
        cv.hline(fx + 1, fx + 14, ybase - 11, GOLD[5])
        cv.vline(fx + 1, ybase - 11, ybase - 2, GOLD[5])
        cv.hline(fx + 2, fx + 14, ybase - 2, GOLD[1])
        cv.vline(fx + 14, ybase - 10, ybase - 2, GOLD[1])
        cv.rect(fx + 6, ybase - 8, 4, 4, GOLD[1])
        cv.rect(fx + 6, ybase - 8, 2, 2, GOLD[5])


def front_handle(cv: Canvas, cx: int, y: int, half: int) -> None:
    """Tirador grande del frente de la base, con herrajes en las puntas (como el original)."""
    cv.rect(cx - half + 8, y + 4, 2 * half - 15, 16, OUTLINE)
    cv.rect(cx - half + 9, y + 5, 2 * half - 17, 14, LEATHER[4])
    cv.hline(cx - half + 9, cx + half - 9, y + 5, LEATHER[6])
    cv.hline(cx - half + 9, cx + half - 9, y + 6, LEATHER[5])
    cv.hline(cx - half + 9, cx + half - 9, y + 17, LEATHER[2])
    cv.hline(cx - half + 9, cx + half - 9, y + 18, LEATHER[1])
    for x in range(cx - half + 12, cx + half - 11):
        if x % 4 < 2:
            cv.put(x, y + 9, LEATHER[2])
            cv.put(x, y + 15, LEATHER[2])
    for fx in (cx - half, cx + half - 12):
        cv.rect(fx, y, 13, 25, GOLD[0])
        cv.rect(fx + 1, y + 1, 11, 23, GOLD[3])
        cv.vline(fx + 1, y + 1, y + 23, GOLD[5])
        cv.hline(fx + 1, fx + 11, y + 1, GOLD[5])
        cv.vline(fx + 11, y + 2, y + 23, GOLD[1])
        cv.hline(fx + 2, fx + 11, y + 23, GOLD[1])
        cv.rect(fx + 5, y + 10, 3, 3, GOLD[1])
        cv.put(fx + 5, y + 10, GOLD[5])


HILO = (200, 160, 104)
HILO_SOMBRA = (138, 106, 64)


def grano(cv: Canvas, mask: np.ndarray) -> None:
    """Grano fino del cuero: casi liso, apenas puntos claros 2×2 y arrugas largas y suaves en diagonal."""
    for y, x in zip(*np.where(mask)):
        r, g, b = cv.get(int(x), int(y))
        base = min(range(7), key=lambda i: abs(LEATHER[i][0] - r) + abs(LEATHER[i][1] - g) + abs(LEATHER[i][2] - b))
        if hash2(int(x) // 2, int(y) // 2, 11) > 0.97:
            cv.put(int(x), int(y), LEATHER[min(6, base + 1)])
        elif (x * 2 + y * 7 + int(hash2(int(x) // 50, int(y) // 14, 3) * 30)) % 83 == 0:
            cv.put(int(x), int(y), LEATHER[max(0, base - 1)])


def costura(cv: Canvas, x0: int, x1: int, y: int, c=HILO, paso: int = 4) -> None:
    for x in range(x0, x1):
        if x % paso < 2:
            cv.put(x, y, c)


def ribete(cv: Canvas, x0: int, x1: int, y: int) -> None:
    """Ribete de terciopelo bordó de 4 filas entre dos filetes dorados."""
    for x in range(x0, x1):
        cv.put(x, y, GOLD[1])
        cv.put(x, y + 1, PANO[3] if x % 8 < 4 else PANO[2])
        cv.put(x, y + 2, PANO[1])
        cv.put(x, y + 3, GOLD[4])
        cv.put(x, y + 4, GOLD[2])


# ---------- cuerpo
def velvet_px(x: int, y: int, top: float, left: float) -> tuple:
    """Terciopelo con pelo corto; sombra de los bordes de arriba y de la izquierda (luz arriba-izquierda)."""
    r = hash2(x // 2, y, 21)
    c = PANO[1] if r < 0.045 else PANO[3] if r > 0.97 else PANO[2]
    dt, dl = y - top, x - left
    if dt < 0.5 or dl < 0.5:
        return PANO[0]
    if dt < 2.5 or dl < 1.5:
        return PANO[1]
    if dt < 3.5 or dl < 2.5:
        return PANO[1] if (x + y) % 2 == 0 else PANO[2]
    return c


def draw(cv: Canvas) -> None:
    lid = poly_mask(W, H, LID_P)
    base = poly_mask(W, H, BASE_P)
    body = lid | base
    yy, xx = np.mgrid[0:H, 0:W]
    # cuero: tapa en sombra suave, base un tono más clara, bordes con luz a la izquierda y sombra a la derecha
    cv.fill(lid, LEATHER[2])
    cv.fill(base, LEATHER[3])
    grano(cv, body)
    for y in range(92, 383):
        for side, lit in ((True, True), (False, False)):
            poly = LID_P if y < 312 else BASE_P
            x = side_x(poly, y + 0.5, side)
            xi = int(np.floor(x)) if side else int(np.ceil(x)) - 1
            step = 1 if side else -1
            for k, c in enumerate((LEATHER[6], LEATHER[5], LEATHER[4]) if lit else (LEATHER[0], LEATHER[1], LEATHER[1])):
                px = xi + step * (k + 1)
                if body[y, px]:
                    cv.put(px, y, c)
    # canto superior de la tapa
    for y, c in ((92, LEATHER[6]), (93, LEATHER[5]), (94, LEATHER[4]), (95, LEATHER[3]), (96, LEATHER[3])):
        for x in range(262, 664):
            if lid[y, x]:
                cv.put(x, y, c)
    for x in range(266, 660):
        if x % 4 < 2:
            cv.put(x, 99, LEATHER[1])
    # ribete bordó bajo el canto y doble costura clara
    ribete(cv, int(side_x(LID_P, 105.5, True)) + 6, int(side_x(LID_P, 105.5, False)) - 6, 103)
    costura(cv, int(side_x(LID_P, 111.5, True)) + 6, int(side_x(LID_P, 111.5, False)) - 6, 111)
    costura(cv, int(side_x(LID_P, 113.5, True)) + 6, int(side_x(LID_P, 113.5, False)) - 6, 113, HILO_SOMBRA)
    # costura a lo largo de los costados de la tapa
    for y in range(101, 310):
        if y % 4 < 2:
            cv.put(int(side_x(LID_P, y + 0.5, True)) + 5, y, LEATHER[1])
            cv.put(int(side_x(LID_P, y + 0.5, False)) - 5, y, LEATHER[1])
    # interior: moldura dorada en trapecio y cuatro compartimentos
    inner = np.zeros((H, W), bool)
    for y in range(IN_Y0 - 2, IN_Y1 + 3):
        l, r = in_left(y), in_right(y)
        for x in range(int(l) - 2, int(np.ceil(r)) + 3):
            inner[y, x] = True
    for y in range(IN_Y0 - 2, IN_Y1 + 3):
        l, r = int(in_left(y)), int(np.ceil(in_right(y)))
        for x in range(l - 2, r + 3):
            if y in (IN_Y0 - 2, IN_Y0 - 1) or x in (l - 2, l - 1):
                cv.put(x, y, GOLD[5] if (y == IN_Y0 - 2 or x == l - 2) else GOLD[3])
            elif y in (IN_Y1 + 1, IN_Y1 + 2) or x in (r + 1, r + 2):
                cv.put(x, y, GOLD[1] if (y == IN_Y1 + 2 or x == r + 2) else GOLD[2])
            else:
                if DIV_X[0] <= x <= DIV_X[1] or DIV_Y[0] <= y <= DIV_Y[1]:
                    continue
                top = IN_Y0 if y < DIV_Y[0] else DIV_Y[1] + 1
                left = l if x < DIV_X[0] else DIV_X[1] + 1
                cv.put(x, y, velvet_px(x, y, top, left))
    # divisores dorados
    for y in range(IN_Y0, IN_Y1 + 1):
        for x, c in zip(range(DIV_X[0], DIV_X[1] + 1), (GOLD[5], GOLD[4], GOLD[3], GOLD[2], GOLD[1])):
            cv.put(x, y, c)
    for y, c in zip(range(DIV_Y[0], DIV_Y[1] + 1), (GOLD[5], GOLD[4], GOLD[3], GOLD[2], GOLD[1])):
        for x in range(int(in_left(y)), int(np.ceil(in_right(y))) + 1):
            if not DIV_X[0] <= x <= DIV_X[1]:
                cv.put(x, y, c)
    cv.rect(DIV_X[0], DIV_Y[0], 5, 5, GOLD[4])
    cv.put(DIV_X[0], DIV_Y[0], GOLD[6])
    cv.put(DIV_X[0] + 1, DIV_Y[0] + 1, GOLD[5])
    # esquineros dentro de cada compartimento
    for (y0, y1) in ((IN_Y0, DIV_Y[0] - 1), (DIV_Y[1] + 1, IN_Y1)):
        corner_bracket(cv, int(in_left(y0)) + 3, y0 + 4, False, False)
        corner_bracket(cv, DIV_X[0] - 9, y0 + 4, True, False)
        corner_bracket(cv, DIV_X[1] + 4, y0 + 4, False, False)
        corner_bracket(cv, int(in_right(y0)) - 8, y0 + 4, True, False)
        corner_bracket(cv, int(in_left(y1)) + 3, y1 - 8, False, True)
        corner_bracket(cv, DIV_X[0] - 9, y1 - 8, True, True)
        corner_bracket(cv, DIV_X[1] + 4, y1 - 8, False, True)
        corner_bracket(cv, int(in_right(y1)) - 8, y1 - 8, True, True)
    # base: borde superior visto desde arriba, con tira de terciopelo entre dos filetes dorados
    for y in range(LIP_Y[0], LIP_Y[1] + 1):
        l, r = side_x(BASE_P, y + 0.5, True), side_x(BASE_P, y + 0.5, False)
        for x in range(int(l) + 4, int(np.ceil(r)) - 4):
            if y < 315:
                c = LEATHER[1] if y == LIP_Y[0] else LEATHER[2]
            elif y == 315:
                c = GOLD[1]
            elif y < 326:
                c = velvet_px(x, y, 316, -99) if y > 316 else PANO[0]
            elif y == 326:
                c = GOLD[4]
            elif y == 327:
                c = GOLD[2]
            else:
                c = LEATHER[2]
            cv.put(x, y, c)
    # frente de la base: filete claro arriba, costura, sombra abajo
    for y in range(FRONT_Y[0], FRONT_Y[1] + 1):
        l, r = side_x(BASE_P, y + 0.5, True), side_x(BASE_P, y + 0.5, False)
        for x in range(int(l) + 4, int(np.ceil(r)) - 4):
            c = None
            if y == FRONT_Y[0]:
                c = GOLD[3]
            elif y == FRONT_Y[0] + 1:
                c = LEATHER[6]
            elif y == FRONT_Y[0] + 2:
                c = LEATHER[5]
            elif y in (FRONT_Y[0] + 5, FRONT_Y[1] - 5) and x % 4 < 2:
                c = LEATHER[1]
            elif y >= FRONT_Y[1] - 2:
                c = LEATHER[1] if y < FRONT_Y[1] else LEATHER[0]
            if c is not None:
                cv.put(x, y, c)
    # ribete bordó y doble costura clara en el frente de la base
    ribete(cv, int(side_x(BASE_P, 336.5, True)) + 8, int(side_x(BASE_P, 336.5, False)) - 8, 333)
    costura(cv, int(side_x(BASE_P, 339.5, True)) + 8, int(side_x(BASE_P, 339.5, False)) - 8, 339)
    costura(cv, int(side_x(BASE_P, 341.5, True)) + 8, int(side_x(BASE_P, 341.5, False)) - 8, 341, HILO_SOMBRA)
    # remaches dorados del frente
    for x in range(250, 680, 38):
        for (dx, dy, c) in ((0, 0, GOLD[5]), (1, 0, GOLD[3]), (0, 1, GOLD[3]), (1, 1, GOLD[1])):
            cv.put(x + dx, FRONT_Y[1] - 9 + dy, c)
    # herrajes: manija y cierres de la tapa, cierres y tirador de la base, esquineros
    handle(cv, 450, 54, 57, 92)
    latch(cv, 303, 87)
    latch(cv, 596, 87)
    latch(cv, 295, 340)
    latch(cv, 601, 340)
    front_handle(cv, 449, 343, 58)
    corner_cap(cv, 255, 91, False, False)
    corner_cap(cv, 657, 91, True, False)
    corner_cap(cv, 208, 369, False, True)
    corner_cap(cv, 704, 369, True, True)
    # contorno de todo el maletín
    ring = np.zeros((H, W), bool)
    ring[1:-1, 1:-1] = ~body[1:-1, 1:-1] & (body[:-2, 1:-1] | body[2:, 1:-1] | body[1:-1, :-2] | body[1:-1, 2:])
    cv.fill(ring & (yy > 85), OUTLINE)
    # sombra del maletín sobre la pared, a la derecha
    for y in range(98, 384):
        x = int(np.ceil(side_x(LID_P if y < 312 else BASE_P, y + 0.5, False))) + 1
        for px in (x, x + 1, x + 2):
            if 0 <= px < W and not body[y, px]:
                r, g, b = cv.get(px, y)
                cv.put(px, y, (r * 6 // 10, g * 6 // 10, b * 6 // 10))
