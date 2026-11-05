extends RefCounted
## Paso J03: lista de jugadas posibles (cálculo, clic, jefes, preferencia).
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const PlaysPanel = preload("res://scripts/plays_panel.gd")
const Prefs = preload("res://scripts/presentation_preferences.gd")
const Drop = preload("res://tests/felt_drop_tests.gd")

static func fresh(scene, values: Array, drag := false) -> void:
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, values)
	scene.selected.clear()
	scene.preferences.drag_groups = drag
	scene.preferences.plays_list = true
	scene.render()

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 0
	fresh(scene, [2, 2, 2, 5, 5])
	var plays: Array = PlaysPanel.best_plays(scene.game)
	var categories: Array = plays.map(func(p): return p.category)
	var unique: Dictionary = {}
	for category in categories: unique[category] = true
	check.call(categories.has("Par") and categories.has("Trío") and categories.has("Doble par") and categories.has("Full") and unique.size() == categories.size() and not categories.has("Generala"), "Plays list: one entry per possible category for [2,2,2,5,5]")
	var sorted := true
	for i in range(plays.size() - 1): sorted = sorted and plays[i].total >= plays[i + 1].total
	check.call(sorted and plays[0].category == "Full", "Plays list: ordered from most to least points")
	# Cada fila da el mismo total que anotar esa jugada.
	var all_match := true
	for play in plays:
		fresh(scene, [2, 2, 2, 5, 5])
		var ok: bool = scene.game.form_group(play.ids)
		var total: float = scene.game.preview().rows[0].total if ok else -1.0
		all_match = all_match and ok and is_equal_approx(total, play.total)
	check.call(all_match, "Plays list: every row equals the preview of forming that group")
	fresh(scene, [2, 2, 2, 5, 5])
	var snapshot: Dictionary = scene.game.snapshot()
	var pair: Dictionary = plays.filter(func(p): return p.category == "Par")[0]
	check.call(pair.values == [5, 5] and scene.game.snapshot() == snapshot, "Plays list: the best pair is picked per category and reading it changes nothing")
	check.call(scene.plays_panel != null and scene.plays_panel.rows.size() == plays.size(), "Plays list: the panel shows one row per play after rolling")
	var unrolled := Game.new(521)
	check.call(PlaysPanel.best_plays(unrolled).is_empty(), "Plays list: nothing before the first roll")
	scene.game = unrolled
	scene.render()
	check.call(scene.plays_panel == null, "Plays list: no panel before rolling")
	# Clic arma el mismo grupo que hacerlo a mano.
	fresh(scene, [2, 2, 2, 5, 5])
	var trio: Dictionary = plays.filter(func(p): return p.category == "Trío")[0]
	scene.plays_panel.play_chosen.emit(trio.ids)
	check.call(scene.game.groups.size() == 1 and scene.game.groups[0].ids == trio.ids and scene.game.groups[0].category == "Trío" and scene.selected.is_empty(), "Plays list: clicking a row forms exactly that group")
	var by_hand := Game.new(521)
	Fixture.set_values(by_hand, [2, 2, 2, 5, 5])
	by_hand.form_group(trio.ids)
	check.call(scene.game.groups == by_hand.groups and is_equal_approx(scene.game.preview().total, by_hand.preview().total), "Plays list: the clicked group equals the one built by hand")
	# Lo que sigue posible, debajo de los grupos armados.
	var rest: Array = PlaysPanel.best_plays(scene.game)
	check.call(rest.size() >= 1 and rest.all(func(p): return not p.ids.any(func(id): return id in trio.ids)), "Plays list: after a group only the remaining dice are offered")
	check.call(scene.plays_panel != null and scene.plays_panel.get_child(0).text == "SIGUEN POSIBLES" and PlaysPanel.top_for(1) == 474.0, "Plays list: the title says what is still possible and sits under the group")
	# Peor caso: varios grupos, lista y ficha sin pisarse.
	fresh(scene, [3, 3, 4, 4, 4])
	scene.game.form_group([0, 1])
	scene.game.form_group([2, 3, 4])
	scene.render()
	check.call(scene.plays_panel == null or scene.plays_panel.rows.is_empty() or scene.plays_panel.rows.back().position.y + scene.plays_panel.rows.back().size.y <= PlaysPanel.LIMIT, "Plays list: with several groups the list never reaches the die card area")
	fresh(scene, [1, 2, 3, 4, 5])
	var rows_bottom := 0.0
	for row in scene.plays_panel.rows: rows_bottom = maxf(rows_bottom, row.position.y + row.size.y)
	check.call(rows_bottom <= PlaysPanel.LIMIT, "Plays list: with no groups the rows end above the die card area")
	# Con la lista visible, la ficha del dado baja.
	var center: Vector2 = scene.table_dice[1].get_global_transform() * Vector2(31, 31)
	await Drop.motion(scene, center)
	scene.update_hover_description()
	check.call(scene.die_card.visible and scene.die_card.label.position.y >= PlaysPanel.CARD_TOP, "Plays list: the die card moves below the list while the mouse is on a die")
	await Drop.motion(scene, Vector2(20, 880))
	# El mouse sobre una fila marca los dados de la jugada.
	fresh(scene, [2, 2, 2, 5, 5])
	var first_row = scene.plays_panel.rows[0]
	first_row.entered.emit()
	scene.update_hover_description()
	var marked: Array = scene.table_dice.keys().filter(func(id): return scene.table_dice[id].combo_hint)
	marked.sort()
	var expected: Array = first_row.play.ids.duplicate()
	expected.sort()
	check.call(marked == expected, "Plays list: hovering a row marks exactly that play's dice")
	first_row.exited.emit()
	scene.update_hover_description()
	check.call(scene.table_dice.keys().all(func(id): return not scene.table_dice[id].combo_hint), "Plays list: leaving the row clears the marks")
	# Jefes: categorías prohibidas y previsión oculta.
	fresh(scene, [4, 4, 4, 4, 4])
	scene.game.rival = 2
	scene.game.boss_rule = {"id": "sin_generala", "name": "Generala prohibida", "kind": "forbid_category", "target": "Generala"}
	scene.render()
	check.call(not PlaysPanel.best_plays(scene.game).any(func(p): return p.category == "Generala") and PlaysPanel.best_plays(scene.game).any(func(p): return p.category == "Póker"), "Plays list: a forbidden category is not listed")
	scene.game.boss_rule = {"id": "locura", "name": "Locura", "kind": "boss_power", "target": "madness"}
	scene.render()
	var hidden_points: bool = scene.plays_panel != null and scene.plays_panel.rows.all(func(r): return r.texts[2] == "?")
	var order_ok := true
	var hidden_plays: Array = PlaysPanel.best_plays(scene.game)
	for i in range(hidden_plays.size() - 1): order_ok = order_ok and PlaysPanel.ORDER.find(hidden_plays[i].category) < PlaysPanel.ORDER.find(hidden_plays[i + 1].category)
	check.call(hidden_points and order_ok, "Plays list: when the boss hides the forecast the points show a question mark and the order does not leak them")
	# Preferencia: apagada no hay panel; migración y persistencia.
	fresh(scene, [2, 2, 2, 5, 5])
	scene.set_preference("plays_list", false)
	check.call(scene.plays_panel == null and Prefs.DEFAULTS.plays_list == true, "Plays list: turned off by the option and on by default")
	scene.set_preference("plays_list", true)
	var old_keys: Dictionary = Prefs.DEFAULTS.duplicate()
	old_keys.erase("plays_list")
	var store = Prefs.new("user://prefs_plays_test.cfg")
	var config := ConfigFile.new()
	config.set_value("presentation", "version", 1)
	config.set_value("presentation", "values", old_keys)
	config.save(store.path)
	var loaded: Dictionary = store.load_values()
	check.call(Prefs.valid(loaded) and loaded.plays_list == true and store.last_error == "", "Plays list: old saved preferences without the key still load")
	DirAccess.remove_absolute(store.path)
	var saved = Prefs.new("user://prefs_plays_test2.cfg")
	var edited: Dictionary = Prefs.DEFAULTS.duplicate()
	edited.plays_list = false
	check.call(saved.save_values(edited) and saved.load_values().plays_list == false, "Plays list: the option persists")
	DirAccess.remove_absolute(saved.path)
	# Opciones: el interruptor existe y no pisa el texto de abajo.
	scene.show_options()
	var toggle: Control = scene.settings_panel.get_node("plays_list")
	var footer: Label
	for child in scene.settings_panel.get_children():
		if child is Label and child.text.begins_with("Las señales"): footer = child
	check.call(toggle != null and footer != null and toggle.position.y + toggle.get_combined_minimum_size().y <= footer.position.y, "Plays list: the Options switch exists and ends above the footer text")
	scene.detail.hide()
