"""Paloma ladrona (jefe 1C): hoja de 3 cuadros de aleteo (arriba, medio, abajo), mirando a la derecha, 18×16 px lógicos cada uno.
Es la paloma de los bocetos de las manos (tools/art/bocetos-jefes/manos_1.py). Salida: assets/art/pixel-v3/paloma-ladrona-v4.png
Uso: py -3.13 tools/art/make_paloma_ladrona_v4.py"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "bocetos-jefes"))
import kit as K  # noqa: E402
import manos_1  # noqa: E402

sheet = Image.new("RGBA", (18 * 3, 16), (0, 0, 0, 0))
for i, kind in enumerate(("up", "mid", "down")):
    sheet.alpha_composite(manos_1.dove(kind), (i * 18, 0))
sheet.save(os.path.join(K.ART, "paloma-ladrona-v4.png"))
print("ok", sheet.size)
