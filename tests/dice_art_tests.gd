extends RefCounted
const Art = preload("res://scripts/dice_art.gd")
const Game = preload("res://scripts/game.gd")
const UI = preload("res://tests/interface_tests.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const Purchase = preload("res://tests/purchase_tests.gd")

static func count_pips(source: Image, region: Rect2) -> int:
	var image := source.get_region(Rect2i(region))
	var width := int(image.get_width() / 2)
	var height := int(image.get_height() / 2)
	var mask := PackedByteArray()
	mask.resize(width * height)
	for y in range(int(height * 0.23), int(height * 0.86)):
		for x in range(int(width * 0.12), int(width * 0.88)):
			var color := image.get_pixel(x * 2, y * 2)
			if color.a > 0.75 and maxf(color.r, maxf(color.g, color.b)) < 0.50: mask[y * width + x] = 1
	var components := 0
	for index in range(mask.size()):
		if mask[index] == 0: continue
		mask[index] = 0
		var queue: Array[int] = [index]
		var cursor := 0
		while cursor < queue.size():
			var current: int = queue[cursor]
			cursor += 1
			for next in [current - width, current + width, current - 1, current + 1]:
				if next >= 0 and next < mask.size() and mask[next] == 1:
					mask[next] = 0
					queue.append(next)
		if queue.size() > 10: components += 1
	return components

static func run(scene, check: Callable) -> Dictionary:
	var counts := {}
	for material in Art.SHEETS:
		var sheet: Texture2D = Art.SHEETS[material]
		var image: Image = sheet.get_image()
		check.call(image.get_size() == Vector2i(1536, 1024) and image.get_pixel(0, 0).a == 0, "Dice art: source atlas size and transparent background " + material)
		var values: Array = []
		for value in range(1, 7):
			var texture := Art.face(material, value)
			var count := count_pips(image, texture.region)
			values.append(count)
			check.call(count == value, "Dice art: source pixels show exactly %d pips for %s, found %d" % [value, material, count])
			if material != "":
				var bounds: Array = Art.pip_bounds(material, value)
				var separate := true
				for a in range(bounds.size()):
					for b in range(a + 1, bounds.size()): separate = separate and not bounds[a].intersects(bounds[b])
				check.call(bounds.size() == value and separate, "Bright facets retain exact number of separate gem pips " + material + str(value))
			var filename: String = "negro" if material == "" else material
			var individual: AtlasTexture = load("res://assets/art/dice-faces-v1/individual/%s-%d.tres" % [filename, value])
			check.call(individual != null and individual.region == texture.region and individual.atlas == texture.atlas, "Dice art: individual face asset matches actual renderer " + filename + str(value))
		counts[material] = values
	check.call(Art.face("ruby", 0).atlas == Art.BLANK and Art.face("diamond", 0).region == Art.BLANK_REGION, "Dice art: unrolled state never displays a fabricated result")
	scene.detail.hide()
	scene.persistence_enabled = false
	scene.game = Game.new(901)
	Fixture.set_values(scene.game, [1, 2, 3, 4, 6])
	var materials := ["", "ruby", "sapphire", "emerald", "diamond"]
	for i in range(5): scene.game.dice[i].shell = materials[i]
	scene.game.dice[1].shell_broken = true
	var before: Dictionary = scene.game.snapshot()
	scene.render()
	var dice := UI.dice_in(scene.ui)
	check.call(dice.size() == 5 and dice.all(func(die): return die.pip_material == scene.game.dice[die.die_index].shell and die.value == scene.game.dice[die.die_index].value), "Dice art: actual tabletop uses persistent material and exact visible number for all five dice")
	check.call(dice.any(func(die): return die.pip_material == "ruby" and die.shell_broken) and scene.game.snapshot() == before, "Dice art: damage keeps gem identity and presentation never mutates snapshot or RNG")
	scene.show_dice_gallery()
	var gallery := UI.dice_in(scene.dice_gallery)
	check.call(scene.detail.visible and gallery.size() == 30 and scene.game.snapshot() == before, "Dice art: menu/options gallery has all 30 faces without equipping items or changing run")
	for material in materials:
		check.call(gallery.filter(func(die): return die.pip_material == material).map(func(die): return die.value) == [1, 2, 3, 4, 5, 6], "Dice art: gallery contains six distinct exact faces for " + material)
	scene.detail.hide()
	scene.game = Purchase.fixture("shell", {"id": "ruby", "intact": true}, 5)
	scene.render()
	var offers := UI.dice_in(scene.ui.get_node("Shop_components"))
	check.call(offers.size() == 1 and offers[0].pip_material == "ruby" and offers[0].value == 5, "Dice art: shop gem offer changes only pips on the same die body")
	scene.game.begin_purchase("components", "fixture:1")
	scene.game.set_purchase_target({"die_id": 2})
	scene.game.confirm_purchase()
	scene.render()
	check.call(UI.dice_in(scene.ui).any(func(die): return die.die_index == 2 and die.pip_material == "ruby") and scene.game.cash == 95, "Dice art: buying gem updates notebook die appearance and charges once")
	for kind in ["material", "element"]:
		var component: String = "steel" if kind == "material" else "electricity"
		scene.game = Purchase.fixture(kind, {"id": component}, 3)
		scene.game.dice[2].material = "copper"
		scene.game.dice[2].element = "wind"
		scene.game.dice[2].shell = "diamond"
		scene.render()
		var component_offers := UI.dice_in(scene.ui.get_node("Shop_components"))
		check.call(component_offers.size() == 1 and component_offers[0].value == 5 and (component_offers[0].body_material == component if kind == "material" else component_offers[0].element == component), "Components: shop represents " + kind + " as front-facing five")
		scene.game.begin_purchase("components", "fixture:1")
		scene.game.set_purchase_target({"die_id": 2})
		scene.game.confirm_purchase()
		scene.render()
		var updated = UI.dice_in(scene.ui).filter(func(die): return die.die_index == 2)[0]
		check.call(updated.pip_material == "diamond" and updated.body_material == scene.game.dice[2].material and updated.element == scene.game.dice[2].element and scene.game.cash == 97, "Components: purchase refreshes all three visual layers and charges once " + kind)
		var preview = preload("res://scripts/die.gd").new()
		preview.configure_appearance(scene.game.dice[2])
		check.call(preview.body_material == updated.body_material and preview.element == updated.element and preview.pip_material == updated.pip_material, "Components: shared appearance copies persistent layers " + kind)
		preview.free()
	var snapshot: Dictionary = scene.game.snapshot()
	scene.show_component_gallery()
	var components := UI.dice_in(scene.dice_gallery)
	check.call(components.size() == 48 and scene.game.snapshot() == snapshot, "Components: 48 reference faces without state/RNG mutation")
	check.call(components.filter(func(die): return die.body_material == "steel" and die.element == "electricity" and die.pip_material == "diamond").map(func(die): return die.value) == [1, 2, 3, 4, 5, 6], "Components: steel/electricity/diamond coexists across all six faces")
	scene.detail.hide()
	return {"source_pixel_counts": counts, "individual_faces": 30, "gallery_faces": 30, "pure_render": true}
