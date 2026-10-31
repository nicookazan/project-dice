extends SceneTree
## Recorta una referencia ampliada para estudiarla: godot --headless --script res://tools/art/crop_ref.gd -- ruta x y w h escala salida
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	var s := Vector2(img.get_size()) / Vector2(1440, 900)
	var r := Rect2i(int(float(a[1]) * s.x), int(float(a[2]) * s.y), int(float(a[3]) * s.x), int(float(a[4]) * s.y))
	var out := img.get_region(r)
	var k := float(a[5])
	out.resize(int(out.get_width() * k), int(out.get_height() * k), Image.INTERPOLATE_NEAREST)
	out.save_png(a[6])
	quit()
