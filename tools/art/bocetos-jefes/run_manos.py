"""Genera los bocetos de manos: test-results/bocetos-arte-2/mano-<id>-<op>.png (reposo ×4) y .gif (clic ×3),
y una hoja de contacto para revisar. Uso: py -3.13 tools/art/bocetos-jefes/run_manos.py [filtro]"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit as K  # noqa: E402
from PIL import Image  # noqa: E402

OUT = os.path.join(K.ROOT, "test-results", "bocetos-arte-2")
os.makedirs(OUT, exist_ok=True)
mods = []
for name in ("manos_1", "manos_2"):
    try:
        mods.append(__import__(name))
    except ModuleNotFoundError:
        pass
flt = sys.argv[1] if len(sys.argv) > 1 else ""
index = []
contact = []
for mod in mods:
    for boss, bname, op, title, desc, env, fn in mod.DESIGNS:
        if flt and flt not in boss: continue
        frames = fn()
        base = f"mano-{boss}-{op}"
        K.save_x(frames[0], os.path.join(OUT, base + ".png"), 4)
        K.save_gif(frames, os.path.join(OUT, base + ".gif"), 3, 110)
        index.append({"boss": boss, "name": bname, "op": op, "title": title, "desc": desc, "png": base + ".png", "gif": base + ".gif", "frames": len(frames)})
        picks = [frames[i] for i in sorted({0, len(frames) // 4, len(frames) // 2, (3 * len(frames)) // 4})]
        row = Image.new("RGBA", (K.SW * 4 + 6, K.SH), (0, 0, 0, 255))
        for i, f in enumerate(picks): row.paste(f, (i * (K.SW + 2), 0))
        contact.append(row)
        print(base, len(frames))
if contact:
    for start in range(0, len(contact), 6):
        chunk = contact[start:start + 6]
        sheet = Image.new("RGBA", (chunk[0].width, len(chunk) * (K.SH + 3)), (0, 0, 0, 255))
        for i, r in enumerate(chunk): sheet.paste(r, (0, i * (K.SH + 3)))
        sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(os.path.join(OUT, f"_contacto-{flt or 'todo'}-{start // 6}.png"))
if not flt:
    json.dump(index, open(os.path.join(OUT, "manos.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
