"""Paleta y utilidades del pixel art pixel-v3 para los generadores en Python.

Espejo de pixel_lib.gd: luz fija arriba-izquierda, rampas de oscuro a claro, contorno cálido #2a1a14.
Todo se dibuja en la grilla lógica (1 px lógico = 2×2 px de la pantalla de 1440×900).
Requiere Python 3.13 con Pillow, numpy y scipy (los mismos que usa sprite-forge).
"""
from __future__ import annotations

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage


def hexc(s: str) -> tuple[int, int, int]:
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def ramp(*hexes: str) -> list[tuple[int, int, int]]:
    return [hexc(h) for h in hexes]


OUTLINE = hexc("2a1a14")
# metales y materiales ya aprobados (fases 1-4)
GOLD = ramp("3a2408", "6a420e", "a06a18", "d09a28", "f0c850", "ffe488", "fff8c0")
SILVER = ramp("262c3c", "444c60", "667088", "8c96ac", "b4bece", "dce2ec", "ffffff")
COPPER = ramp("3a1808", "6a3012", "9a4a1e", "c4703a", "e89a5c")
LEATHER = ramp("07070b", "101016", "191921", "24242e", "34343f", "4c4c5a", "7a7a8a")
BLUE = ramp("14285a", "204a9c", "3070d0", "6a9ae8", "b8d0f8")
IVORY = ramp("6b4a2a", "c9a36a", "efe0b8", "fff6dc", "ffffff")
# texturas (nov 2026): cuero cálido del maletín, blanco y celeste de la bandera, pared y zócalo del salón, piel de los retratos
WARMBLK = ramp("0b0807", "1a1210", "28201c", "3a2e28", "50423a", "6e5c4e", "94806c")
CELESTE = ramp("2a5a8a", "4f8cc4", "7cb8e0", "a8d4ee", "cde8f6")
WHITE = ramp("8a98b0", "bcc8d8", "e2e8f0", "f4f7fa", "ffffff")
PANEL = ramp("1c0d07", "33180c", "4d2812", "6a3a18", "8a5222", "a86a2e")
SKIN = ramp("5a2e1c", "8a5232", "b87a4e", "d89c6c", "f0c090")
# salón y mesa
WALL = ramp("2a160c", "43240f", "5e3414", "7c4a1c", "9a6228")
BEAM = ramp("1a0c06", "2e1810", "422212", "5c3318")
CHAIR = ramp("1c0d07", "33180c", "4d2812", "6a3a18")
SHADE = ramp("8a4a10", "c87a18", "f0a828", "ffd060", "fff0a0")
LEAF = ramp("0e2a14", "1a4a22", "2c6a30", "4a8c3c")
FRAME = hexc("c08a30")
FRAME_DK = hexc("6a3e12")
PAPER = hexc("d8c8a0")
WOOD = ramp("3b1608", "6e2f10", "9c4a16", "c4661f", "e08a32")
NAVY = ramp("0a1430", "0f2048", "163060")
PANO = ramp("2a0a12", "6e1424", "8c1c2e", "a62838")


def hash2(x: int, y: int, s: int = 0) -> float:
    """El mismo hash entero que los generadores de Godot (reproducible, sin azar global)."""
    n = (x * 374761393 + y * 668265263 + s * 1442695041) & 0x7FFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0x7FFFFFFF
    n = n ^ (n >> 16)
    return float(n & 0xFFFF) / 65535.0


class Canvas:
    """Lienzo RGBA en la grilla lógica, con las primitivas que usan los generadores."""

    def __init__(self, w: int, h: int, fill=None):
        self.w, self.h = w, h
        self.a = np.zeros((h, w, 4), np.uint8)
        if fill is not None:
            self.a[..., :3] = fill
            self.a[..., 3] = 255

    # ---------- píxeles y formas
    def put(self, x: int, y: int, c) -> None:
        if 0 <= x < self.w and 0 <= y < self.h:
            self.a[y, x, :3] = c[:3]
            self.a[y, x, 3] = 255

    def get(self, x: int, y: int):
        return tuple(int(v) for v in self.a[y, x, :3])

    def rect(self, x: int, y: int, w: int, h: int, c) -> None:
        x0, y0, x1, y1 = max(0, x), max(0, y), min(self.w, x + w), min(self.h, y + h)
        if x1 > x0 and y1 > y0:
            self.a[y0:y1, x0:x1, :3] = c[:3]
            self.a[y0:y1, x0:x1, 3] = 255

    def fill(self, mask: np.ndarray, c) -> None:
        self.a[mask, :3] = c[:3]
        self.a[mask, 3] = 255

    def hline(self, x0: int, x1: int, y: int, c) -> None:
        for x in range(min(x0, x1), max(x0, x1) + 1):
            self.put(x, y, c)

    def vline(self, x: int, y0: int, y1: int, c) -> None:
        for y in range(min(y0, y1), max(y0, y1) + 1):
            self.put(x, y, c)

    def line(self, x0: int, y0: int, x1: int, y1: int, c) -> None:
        for x, y in bresenham(x0, y0, x1, y1):
            self.put(x, y, c)

    def polyline(self, pts, c) -> None:
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            self.line(x0, y0, x1, y1, c)

    def blit(self, other: "Canvas", ox: int, oy: int) -> None:
        """Copia los píxeles opacos de otro lienzo (sin mezclas parciales)."""
        h, w = other.h, other.w
        x0, y0 = max(0, ox), max(0, oy)
        x1, y1 = min(self.w, ox + w), min(self.h, oy + h)
        if x1 <= x0 or y1 <= y0:
            return
        src = other.a[y0 - oy:y1 - oy, x0 - ox:x1 - ox]
        m = src[..., 3] > 0
        dst = self.a[y0:y1, x0:x1]
        dst[m] = src[m]

    def mask_of(self) -> np.ndarray:
        return self.a[..., 3] > 0

    def image(self) -> Image.Image:
        return Image.fromarray(self.a, "RGBA")

    def save(self, path: str, scale: int = 1) -> None:
        im = self.image()
        if scale > 1:
            im = im.resize((self.w * scale, self.h * scale), Image.NEAREST)
        im.save(path)


def bresenham(x0: int, y0: int, x1: int, y1: int):
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        yield x0, y0
        if x0 == x1 and y0 == y1:
            return
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def poly_mask(w: int, h: int, pts) -> np.ndarray:
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).polygon([tuple(p) for p in pts], fill=255)
    return np.array(m) > 0


def ellipse_mask(w: int, h: int, cx: float, cy: float, rx: float, ry: float) -> np.ndarray:
    yy, xx = np.mgrid[0:h, 0:w]
    return ((xx + 0.5 - cx) / rx) ** 2 + ((yy + 0.5 - cy) / ry) ** 2 <= 1.0


def edge_of(mask: np.ndarray) -> np.ndarray:
    """Píxeles del borde interior de una máscara (vecino-4 fuera)."""
    inner = ndimage.binary_erosion(mask, structure=[[0, 1, 0], [1, 1, 1], [0, 1, 0]], border_value=0)
    return mask & ~inner


def clean_labels(labels: np.ndarray, mask: np.ndarray, min_size: int = 4, passes: int = 2) -> np.ndarray:
    """Limpia un mapa de tonos: absorbe islas chicas en el tono vecino más común y suaviza
    los bordes con una mayoría 3×3 (sin ruido de 1 px, regla de la biblia de píxel)."""
    out = labels.copy()
    vals = np.unique(out[mask])
    for _ in range(passes):
        # islas chicas
        for v in vals:
            lab, n = ndimage.label((out == v) & mask)
            if n == 0:
                continue
            sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
            for i, s in enumerate(sizes, 1):
                if s >= min_size:
                    continue
                isl = lab == i
                ring = ndimage.binary_dilation(isl) & ~isl & mask
                if not ring.any():
                    continue
                neigh = out[ring]
                counts = np.bincount(neigh, minlength=int(vals.max()) + 1)
                counts[v] = 0
                if counts.sum():
                    out[isl] = int(np.argmax(counts))
        # mayoría 3×3 dentro de la máscara
        best = out.copy()
        best_count = np.zeros(out.shape, np.int32)
        for v in vals:
            c = ndimage.uniform_filter(((out == v) & mask).astype(np.float32), 3) * 9
            c = np.rint(c).astype(np.int32)
            take = c > best_count
            best[take] = v
            best_count[take] = c[take]
        keep = best_count >= 5
        out[mask & keep] = best[mask & keep]
    return out


def upscale(img: Image.Image, k: int) -> Image.Image:
    return img.resize((img.width * k, img.height * k), Image.NEAREST)
