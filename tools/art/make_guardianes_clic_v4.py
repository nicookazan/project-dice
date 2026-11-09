"""Hoja de la animación al clic de los guardianes de Dios (elegida el 08/11/2026 sobre los bocetos de
tools/art/bocetos-dios/): ojo solar B (corona que gira), figura de luz B (metales en el aire) y dado cósmico A (tirada
cósmica). Una fila por guardián en el orden de BossCatalog.GUARDIANS (ojo, figura, dado), 16 cuadros de 124×100 px
lógicos; el cuadro 0 es el reposo (igual al dibujo de guardianes/) y el juego los dibuja a 2× como el reposo.
Uso: py -3.13 tools/art/make_guardianes_clic_v4.py  ->  assets/art/pixel-v3/guardianes/guardianes-clic-v4.png

También escribe guardian-ojo-reposo-v4.png (08/11/2026, pedido del autor): el parpadeo y mirada del ojo solar (idea A de
los bocetos), 16 cuadros que el juego repite cada tanto mientras el ojo está en reposo.
"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "bocetos-dios"))
import guardianes as G  # noqa: E402

G.SPRITE_ONLY = True
ROWS = [G.ojo_b, G.figura_b, G.dado_a]
FRAMES, W, H = 16, 124, 100

if __name__ == "__main__":
    sheet = Image.new("RGBA", (W * FRAMES, H * len(ROWS)))
    for row, fn in enumerate(ROWS):
        frames = fn()
        assert len(frames) == FRAMES, (fn.__name__, len(frames))
        for i, f in enumerate(frames):
            assert f.size == (W, H)
            sheet.alpha_composite(f, (i * W, row * H))
        rest = np.array(frames[0]); base = np.array(G.load(["ojo", "figura", "dado"][row]))
        assert (rest == base).all(), f"{fn.__name__}: el cuadro 0 no es el reposo"
        last = np.array(frames[-1])
        assert (last == base).all(), f"{fn.__name__}: el último cuadro no vuelve al reposo"
    out = os.path.join(G.K.ART, "guardianes", "guardianes-clic-v4.png")
    sheet.save(out)
    print(out, sheet.size)
    idle = G.ojo_a()
    base = np.array(G.load("ojo"))
    assert len(idle) == FRAMES and (np.array(idle[0]) == base).all() and (np.array(idle[-1]) == base).all(), "el parpadeo debe empezar y terminar en el reposo"
    strip = Image.new("RGBA", (W * FRAMES, H))
    for i, f in enumerate(idle): strip.alpha_composite(f, (i * W, 0))
    out = os.path.join(G.K.ART, "guardianes", "guardian-ojo-reposo-v4.png")
    strip.save(out)
    print(out, strip.size)
