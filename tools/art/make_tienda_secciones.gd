extends SceneTree
## Maletín de la tienda con las secciones de la opción B (aprobada el 25/11/2026, ver `tools/art/bocetos-tienda/`):
##   arriba dos secciones (componentes | stickers; desde el 25/11 los números son recompensa), abajo dos (monedas, ancha |
##   moneda de un uso, angosta).
## Parte de `tienda-v3.png` sin redibujar nada: el acolchado se repite cada 24 × 16 píxeles de arte, así que la división
## vertical original se borra copiando el acolchado de 48 px a la izquierda y la franja de la división (con sus
## esquineros) se copia corrida en múltiplos de 24 px. Se corre sin GPU:
##   godot --headless --path . --script res://tools/art/make_tienda_secciones.gd
const SOURCE := "res://assets/art/pixel-v3/tienda-v3.png"
const OUT := "res://assets/art/pixel-v3/tienda-secciones-v4.png"
## Filas del interior del maletín (píxeles de arte) y franja de la división vertical original.
const TOP := 98
const BOTTOM := 328
const STRIP_X := 440
const STRIP_W := 36
const MID_Y := 217
## Corrimientos de las divisiones: arriba una en su lugar original (componentes | stickers), abajo una (+96).
const TOP_SHIFTS := [0]
const BOTTOM_SHIFTS := [96]

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	source.convert(Image.FORMAT_RGBA8)
	var art: Image = source.duplicate()
	for y in range(TOP, BOTTOM):
		for x in range(STRIP_X, STRIP_X + STRIP_W):
			art.set_pixel(x, y, source.get_pixel(x - 48, y))
	for y in range(TOP, BOTTOM):
		var shifts: Array = TOP_SHIFTS if y < MID_Y else BOTTOM_SHIFTS
		if y in [MID_Y, MID_Y + 1]: shifts = TOP_SHIFTS + BOTTOM_SHIFTS
		for shift in shifts:
			for x in range(STRIP_X, STRIP_X + STRIP_W):
				art.set_pixel(x + shift, y, source.get_pixel(x, y))
	art.save_png(ProjectSettings.globalize_path(OUT))
	print("TIENDA SECCIONES: ", OUT)
	quit()
