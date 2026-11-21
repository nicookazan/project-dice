"""Base de los bocetos del vendedor-nube: la tienda sin el vendedor, dejando solo las manos y los puños."""
from __future__ import annotations
import os, sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..")
sys.path.insert(0, ART)
os.chdir(os.path.join(ART, "..", ".."))
import make_tienda, maletin, vendedor
from pixel_lib import Canvas, WALL

W, H = make_tienda.W, make_tienda.H

def scene_layers():
    """(fondo = salón, maletín = maletín, manos = capa de manos con alfa, máscaras)"""
    cv = Canvas(W, H, fill=WALL[2]); make_tienda.room(cv)
    bg = cv.image().convert("RGBA")
    cv2 = Canvas(W, H, fill=WALL[2]); make_tienda.room(cv2); maletin.draw(cv2)
    mid = cv2.image().convert("RGBA")
    handcv = Canvas(W, H)
    M = vendedor.draw(handcv, "front")
    hands = handcv.image().convert("RGBA")
    band = Canvas(W, H); make_tienda.bottom_band(band)
    return bg, mid, hands, band.image().convert("RGBA"), M

if __name__ == "__main__":
    bg, mid, hands, band, M = scene_layers()
    for k, m in M.items():
        ys, xs = np.nonzero(m)
        if len(xs): print(k, xs.min(), xs.max(), ys.min(), ys.max())
    out = mid.copy(); out.alpha_composite(hands); out.alpha_composite(band)
    out.resize((W*2, H*2), Image.NEAREST).save("test-results/vend_base.png")
