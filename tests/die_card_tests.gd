extends RefCounted
## Paso J02: ficha del dado al pasar el mouse (mesa y tienda).
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const DieCard = preload("res://scripts/die_card.gd")
const Drop = preload("res://tests/felt_drop_tests.gd")

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.drag_groups = true
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [4, 4, 1, 2, 6])
	scene.game.global_points = {"4": 3}
	scene.game.dice[0].material = "steel"
	scene.game.dice[0].encounter_effects["steel_points"] = 2.0
	var group_ok: bool = scene.game.form_group([0, 1])
	var rows: Array = scene.game.preview().rows[0].die_rows
	var context: Dictionary = scene.game.boss_context()
	check.call(group_ok and rows.size() == 2 and DieCard.worth(scene.game.dice[0], scene.game.global_points, context) == int(round(rows[0].points)) and DieCard.worth(scene.game.dice[1], scene.game.global_points, context) == int(round(rows[1].points)), "Die card: 'Vale N' equals the die's own points in the real scoring (global upgrade and steel included)")
	scene.game.ungroup(0)
	# Contenido de los casos especiales.
	var plain := {"id": 9, "value": 3, "faces": [1, 2, 3, 4, 5, 6], "material": "", "shell": "", "element": "", "shell_broken": false, "encounter_effects": {}}
	var text := DieCard.bbcode(plain, {}, {})
	check.call(text.contains("Dado común") and text.contains("Vale 3 puntos") and text.contains("[color=#f0c850]3[/color]"), "Die card: a plain die shows 'Dado común', its faces with the current one in gold and what it is worth")
	var rich := plain.duplicate(true)
	rich.material = "copper"; rich.shell = "ruby"; rich.element = "water"
	text = DieCard.bbcode(rich, {"3": 2}, {})
	check.call(text.contains("[color=#e89a5c]Cobre[/color]") and text.contains("[color=#ff5f70]Rubí[/color]") and text.contains("[color=#52bcf2]Agua[/color]") and text.contains("Vale 5 puntos"), "Die card: material, gem and element each use their color and the global upgrade counts")
	var broken := rich.duplicate(true)
	broken.shell_broken = true
	check.call(DieCard.bbcode(broken, {}, {}).contains("[s]Rubí[/s] rota"), "Die card: a broken gem is struck through and marked as broken")
	check.call(DieCard.bbcode(rich, {}, {"kind": "suspend_material", "target": "copper"}).contains("[s]Cobre[/s] suspendido por el jefe"), "Die card: a material suspended by the boss is struck through")
	var changed := plain.duplicate(true)
	changed.faces = [1, 2, 3, 6, 6, 6]
	changed.value = 6
	check.call(DieCard.faces_line(changed).count("[color=#f0c850]6[/color]") == 3, "Die card: changed faces are listed and every face equal to the result is gold")
	var in_cup := plain.duplicate(true)
	in_cup.value = 0
	check.call(DieCard.bbcode(in_cup, {}, {}).contains("Todavía en el vaso") and not DieCard.bbcode(in_cup, {}, {}).contains("Vale"), "Die card: a die still in the cup says so instead of a value")
	var single := plain.duplicate(true)
	single.value = 1
	check.call(DieCard.bbcode(single, {}, {}).contains("Vale 1 punto") and not DieCard.bbcode(single, {}, {}).contains("Vale 1 puntos"), "Die card: one point is singular")
	# Al pasar el mouse sobre un dado de la mesa aparece la ficha, sin cambiar la partida; al arrastrar desaparece.
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [4, 4, 1, 2, 6])
	scene.selected.clear()
	scene.render()
	var before: Dictionary = scene.game.snapshot()
	check.call(not scene.die_card.visible, "Die card: nothing shows before hovering a die")
	var center: Vector2 = scene.table_dice[3].get_global_transform() * Vector2(31, 31)
	await Drop.motion(scene, center)
	scene.update_hover_description()
	check.call(scene.die_card.visible and scene.die_card.label.text.contains("Vale 2 puntos") and scene.game.snapshot() == before, "Die card: hovering a table die shows its card without changing the game")
	check.call(not scene.hover_description.visible, "Die card: the old text hover is gone for dice")
	await Drop.press(scene, center, true)
	await Drop.motion(scene, center + Vector2(24, 0))
	await Drop.motion(scene, center + Vector2(52, 8))
	scene.update_hover_description()
	check.call(scene.get_viewport().gui_is_dragging() and not scene.die_card.visible, "Die card: it disappears while a die is dragged")
	await Drop.motion(scene, Vector2(100, 120))
	await Drop.press(scene, Vector2(100, 120), false)
	await Drop.motion(scene, Vector2(20, 880))
	scene.update_hover_description()
	check.call(not scene.die_card.visible, "Die card: moving the mouse away hides it")
	scene.detail.hide()
	await scene.get_tree().process_frame
	# Tienda: la ficha aparece arriba del dado.
	scene.game.phase = "shop"
	scene.render()
	var shop_die: Control
	for child in scene.ui.get_children():
		if child.get_script() == scene.Die and child.die_index == 2: shop_die = child
	check.call(shop_die != null, "Die card: the shop shows the five dice")
	if shop_die != null:
		await Drop.motion(scene, shop_die.get_global_transform() * Vector2(31, 31))
		scene.update_hover_description()
		check.call(scene.die_card.visible and scene.die_card.shop_panel.visible and not scene.die_card.felt_panel.visible and scene.die_card.shop_panel.position.y + scene.die_card.shop_panel.size.y <= shop_die.global_position.y, "Die card: in the shop the card sits above the die")
	scene.game.phase = "play"
	scene.render()
