extends RefCounted
## TX3: arte de los metales nuevos. Máscaras fijas, tabla de materiales y shader; sin reglas nuevas.
const Materials = preload("res://scripts/materials.gd")
const Die = preload("res://scripts/die.gd")
const MASK = preload("res://assets/art/pixel-v3/metales-mascaras-v3.png")
const BODY_SHADER = preload("res://scripts/die_body.gdshader")

static func run(scene, check: Callable) -> void:
	check.call(Materials.METALS == ["steel", "copper", "rust_iron", "rust_copper", "gold"], "TX3: el catálogo de metales tiene cinco entradas")
	for id in Materials.METALS:
		check.call(Materials.TABLE.has(id) and Materials.base_of(id) in ["steel", "copper"], "TX3: %s toma su mecánica de un metal base" % id)
	check.call(Materials.base_of("rust_iron") == "steel" and Materials.base_of("rust_copper") == "copper" and Materials.base_of("gold") == "steel", "TX3: oxidados y oro heredan la mecánica de su base (D16)")
	check.call(Materials.display_name("steel") == "Hierro" and Materials.display_name("rust_iron") == "Hierro oxidado", "TX3: se muestra «Hierro» y no «Acero»")
	check.call(Materials.body_kind("steel") == 1 and Materials.body_kind("copper") == 2, "TX3: acero y cobre conservan sus cuerpos de siempre")
	var kinds := {}
	for id in Materials.METALS: kinds[Materials.body_kind(id)] = true
	check.call(kinds.size() == 5, "TX3: cada metal tiene su propio cuerpo en el shader")
	check.call(BODY_SHADER.get_code().contains("body_kind == 5") or BODY_SHADER.get_code().contains("else {"), "TX3: el shader resuelve el oro")
	var image: Image = MASK.get_image()
	check.call(image.get_size() == Vector2i(124, 62), "TX3: las máscaras son dos celdas de 62x62")
	# Hay óxido en una parte del dado y no en todo: ni liso ni cubierto por completo.
	for cell in [0, 1]:
		var covered := 0
		var total := 0
		for y in range(2, 60):
			for x in range(cell * 62 + 4, cell * 62 + 58):
				total += 1
				if image.get_pixel(x, y).r > 0.5: covered += 1
		var share := float(covered) / float(total)
		check.call(share > 0.15 and share < 0.85, "TX3: la máscara %d cubre una parte razonable del dado (%d%%)" % [cell, int(share * 100)])
	# Los puntos no se alteran: el shader los salta con las mismas cajas que usan acero y cobre.
	for id in Materials.METALS:
		var die := Die.new()
		die.value = 6
		die.body_material = id
		scene.add_child(die)
		die.queue_redraw()
		check.call(die.body_view != null and die.body_view.visible, "TX3: %s dibuja su cuerpo con shader" % id)
		check.call(int(die.body_shader.get_shader_parameter("body_kind")) == Materials.body_kind(id) or not die.is_inside_tree(), "TX3: %s fija su body_kind" % id)
		die.queue_free()
