"""Hoja de elementos de los dados (TX1, D16 opción A): assets/art/pixel-v3/elementos-v3.png.

Cinco celdas de 96×96 (fuego, agua, electricidad, tierra, viento); el dado (62×62) va en (17,17) de cada celda.
El dibujo vive en tools/art/bocetos-texturas/make_bocetos_dados.py (opción A); este script solo exporta la hoja
al lugar que usa Die.draw_element_edges(). Uso: py -3 tools/art/make_elementos.py
"""
import os
import runpy
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "assets", "art", "pixel-v3", "elementos-v3.png")

if __name__ == "__main__":
    sys.argv = ["make_bocetos_dados.py", os.path.join(ROOT, "test-results", "bocetos-texturas"), "--atlas", OUT]
    runpy.run_path(os.path.join(HERE, "bocetos-texturas", "make_bocetos_dados.py"), run_name="__main__")
