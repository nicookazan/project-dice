"""Sprites del vaso para la etapa de jugabilidad (M1/M6): brillo dorado y pared delantera.

Parten del dibujo existente `vaso-v3.png` sin modificarlo. Se trabaja en la grilla lógica (720x450);
el juego los dibuja a x2 con filtro NEAREST.
  - vaso-brillo-v3.png : contorno dorado en tres anillos (#fff0a0 90%, #ffc850 50%, #f09628 25%) alrededor de la silueta.
  - vaso-frente-v3.png : solo la pared delantera (lo que queda por debajo del interior verde), para que el dado
                         que entra o sale se vea detrás de ella.
"""
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage as nd

ART = Path(__file__).resolve().parents[2] / "assets" / "art" / "pixel-v3"
RINGS = [((255, 240, 160), 230), ((255, 200, 80), 130), ((240, 150, 40), 60)]
MARGIN = 8


def glow(cup: Image.Image) -> Image.Image:
    a = np.zeros((cup.height + 2 * MARGIN, cup.width + 2 * MARGIN), bool)
    a[MARGIN:MARGIN + cup.height, MARGIN:MARGIN + cup.width] = np.array(cup)[..., 3] > 0
    out = np.zeros(a.shape + (4,), np.uint8)
    prev = a
    for r, (col, alpha) in enumerate(RINGS):
        grown = nd.binary_dilation(prev, iterations=1 if r == 0 else 2)
        out[grown & ~prev] = col + (alpha,)
        prev = grown
    return Image.fromarray(out)


def front(cup: Image.Image) -> Image.Image:
    v = np.array(cup)
    green = (v[..., 1].astype(int) > v[..., 0].astype(int) + 12) & (v[..., 3] > 0)
    out = v.copy()
    for x in range(v.shape[1]):
        ys = np.where(green[:, x])[0]
        if len(ys):
            out[:ys.max() + 1, x, 3] = 0   # se quita todo hasta el piso del interior
        else:
            out[:9, x, 3] = 0              # bordes del aro, sin verde: arranca a la altura del lateral
    return Image.fromarray(out)


if __name__ == "__main__":
    cup = Image.open(ART / "vaso-v3.png").convert("RGBA")
    glow(cup).save(ART / "vaso-brillo-v3.png")
    front(cup).save(ART / "vaso-frente-v3.png")
    print("ok", cup.size)
