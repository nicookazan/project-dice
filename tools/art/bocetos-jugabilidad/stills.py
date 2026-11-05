"""Recortes de los bocetos fijos y esquema de la zona de soltado del vaso."""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
S = str(Path(__file__).resolve().parents[3] / "test-results" / "bocetos") + "/"
MESA = (334, 260, 1440, 680)
CROPS = {
    "m2_a": MESA, "m2m3": MESA, "m3_lista": MESA, "m3_hover": MESA, "m3_armado": MESA, "m5_hover": MESA,
    "m2_estados": None, "m2_glosario": (300, 240, 1140, 720), "m3_opciones": (300, 100, 1150, 860),
    "t2_hover": (250, 620, 1050, 900), "t3_hover": (0, 500, 800, 900),
}
for name, box in CROPS.items():
    i = Image.open(S + "cap/" + name + ".png").convert("RGB")
    (i.crop(box) if box else i).save(S + "out/" + name + ".png")

font = ImageFont.truetype("C:/Windows/Fonts/consolab.ttf", 20)
base = Image.open(S + "cap/mesa_base.png").convert("RGBA")
sheet = Image.new("RGB", (1106, 420 * 2 + 12), (20, 14, 18))
BLOCK = (1260, 400, 1405, 580)      # CUP_RECT: el botón invisible para inspeccionar el vaso
ZONE = (1082, 324, 1394, 654)       # zona "cup" que sí acepta el dado
for row, label in enumerate(("HOY", "PROPUESTA")):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    if row == 0:
        d.rectangle(ZONE, fill=(70, 210, 120, 80), outline=(120, 240, 160, 255), width=3)
        d.rectangle(BLOCK, fill=(230, 40, 50, 170), outline=(255, 150, 150, 255), width=3)
    else:
        d.rectangle(ZONE, fill=(70, 210, 120, 80), outline=(120, 240, 160, 255), width=3)
        d.rectangle((1394, 400, 1440, 620), fill=(70, 210, 120, 80))
    img = Image.alpha_composite(base, layer).convert("RGB")
    d2 = ImageDraw.Draw(img)
    d2.rectangle((350, 270, 1010, 304), fill=(20, 14, 18))
    text = "HOY: soltar sobre el vaso (rojo) no hace nada" if row == 0 else "PROPUESTA: toda la zona verde, vaso incluido, recibe el dado"
    d2.text((360, 276), text, font=font, fill=(255, 240, 199))
    sheet.paste(img.crop(MESA), (0, row * 432))
sheet.save(S + "out/m1_zona.png")
print("ok")
