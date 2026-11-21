"""Convierte a la grilla del juego los ocho pasos que el autor editó a mano (hoja de 4×2 pasos).

La hoja vuelve reducida (cada paso ~1,47× el tamaño lógico de 340×320). Cada paso se vuelve a 340×320 por promedio de
área, se compara con la escena sin nube ni mano y lo que cambia (nube, mano, volutas) se guarda como capa, con los colores
ajustados a una paleta corta sacada de las propias ediciones. Escribe en test-results/vendedor-nube9/.

Ejecutar:  py -3.13 tools/art/bocetos-vendedor/desde_edicion.py <hoja>
"""
from __future__ import annotations
import os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from base import scene_layers, W, H

FW, FH, CROP_Y = 340, 320, 67
THR = 70
NCOLORS = 24


def main(path):
    bg, mid, hands, band, M = scene_layers()
    base = mid.copy(); base.alpha_composite(band)
    B = np.array(base.convert("RGB")).astype(int)[CROP_Y:CROP_Y + FH, :FW]
    sheet = Image.open(path).convert("RGB")
    cw, ch = sheet.width / 4, sheet.height / 2
    print("hoja", sheet.size, "paso", cw, ch)
    frames, masks = [], []
    for i in range(8):
        c, r = i % 4, i // 4
        f = sheet.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch))).resize((FW, FH), Image.BOX)
        a = np.array(f).astype(int)
        masks.append(np.abs(a - B).sum(axis=2) > THR); frames.append(a)
    allpx = np.concatenate([fr[m] for fr, m in zip(frames, masks)]).astype(np.uint8)
    pal_img = Image.fromarray(allpx.reshape(-1, 1, 3)).quantize(colors=NCOLORS, method=Image.Quantize.MEDIANCUT)
    pal = np.array(pal_img.getpalette()[:NCOLORS * 3]).reshape(-1, 3)
    out = "test-results/vendedor-nube9"; os.makedirs(out, exist_ok=True)
    layers = []
    for i, (fr, m) in enumerate(zip(frames, masks)):
        idx = np.abs(fr[:, :, None, :] - pal[None, None]).sum(axis=3).argmin(axis=2)
        sn = pal[idx]
        lay = np.zeros((FH, FW, 4), np.uint8); lay[..., :3] = sn; lay[..., 3] = np.where(m, 255, 0)
        layers.append(lay)
        Image.fromarray(lay).save(f"{out}/capa{i}.png")
    comp = []
    for lay in layers:
        f = base.crop((0, CROP_Y, FW, CROP_Y + FH)).copy(); f.alpha_composite(Image.fromarray(lay)); comp.append(f)
    big = [f.resize((FW * 2, FH * 2), Image.NEAREST) for f in comp]
    big[0].save(f"{out}/bucle.gif", save_all=True, append_images=big[1:], duration=400, loop=0)
    sheet2 = Image.new("RGB", (FW * 4, FH * 2))
    for i, f in enumerate(comp): sheet2.paste(f.convert("RGB"), ((i % 4) * FW, (i // 4) * FH))
    sheet2.save(f"{out}/tira.png"); comp[0].resize((FW * 3, FH * 3), Image.NEAREST).save(f"{out}/cuadro0.png")
    comp[5].resize((FW * 3, FH * 3), Image.NEAREST).save(f"{out}/cuadro5.png")
    print("ok", len(pal), "colores")


if __name__ == "__main__":
    main(sys.argv[1])
