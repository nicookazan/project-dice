extends RefCounted
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const UI = preload("res://tests/interface_tests.gd")
const Boss = preload("res://scripts/boss_rules.gd")

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.drag_groups = true
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	scene.game = Game.new(520)
	Fixture.set_values(scene.game, [2, 2, 2, 5, 5])
	scene.selected.clear()
	scene.render()
	var before: Dictionary = scene.game.snapshot()
	var combinations: Array = scene.possible_combinations(0)
	check.call(combinations.any(func(item): return item.category == "Par") and combinations.any(func(item): return item.category == "Trío") and combinations.any(func(item): return item.category == "Full") and scene.game.snapshot() == before, "Drag groups: hover finds real pair/trio/full possibilities without changing state or RNG")
	scene.toggle_die(0)
	check.call(scene.selected.is_empty(), "Drag groups: clicking a die cannot stage it in drag mode")
	scene.ui.get_node("GroupArea")._drop_data(Vector2(50, 50), {"die": 0})
	scene.ui.get_node("GroupArea")._drop_data(Vector2(60, 50), {"die": 1})
	check.call(scene.selected == [0, 1] and scene.game.snapshot() == before and UI.find_button(scene.ui, "Armar grupo").disabled == false, "Drag groups: dropping dice on left stages exact IDs and enables valid group without mutating gameplay")
	scene.handle_die_drop(1, "reserve")
	check.call(scene.selected == [0] and UI.find_button(scene.ui, "Armar grupo").disabled, "Drag groups: dragging a draft die back removes only that die and invalidates incomplete group")
	scene.handle_die_drop(1, "draft")
	UI.find_button(scene.ui, "Armar grupo").pressed.emit()
	check.call(scene.game.groups.size() == 1 and scene.game.groups[0].ids == [0, 1] and scene.selected.is_empty(), "Drag groups: forming group commits only dragged dice and clears draft")
	before = scene.game.snapshot()
	scene.handle_die_drop(0, "draft")
	scene.handle_die_drop(5, "draft")
	check.call(scene.selected.is_empty() and scene.game.snapshot() == before, "Drag groups: grouped and malformed dice cannot be restaged")
	scene.game.ungroup(0)
	scene.game.rival = 2
	Fixture.set_values(scene.game, [4, 4, 4, 4, 4])
	scene.game.boss_rule = Boss.NONE.duplicate(true)
	check.call(not scene.possible_combinations(0).any(func(item): return item.category == "Generala") and scene.possible_combinations(0).any(func(item): return item.category == "Trío"), "Drag groups: hover excludes forbidden generala while retaining legal subsets")
	before = scene.game.snapshot()
	scene.game.phase = "purchase_target"
	scene.handle_die_drop(2, "draft")
	check.call(scene.selected.is_empty(), "Drag groups: pending purchase blocks draft changes")
	scene.game.phase = "play"
	scene.game.passives = ["even", "odd"]
	scene.game.consumable = "roll"
	scene.render()
	check.call(scene.ui.get_node("EquippedCoin_0").text.is_empty() and scene.ui.get_node("EquippedCoin_0").get_theme_stylebox("normal") is StyleBoxEmpty and scene.ui.get_node("ConsumableCoin").get_theme_stylebox("normal") is StyleBoxEmpty, "Encounter coins: owned passive and consumable show only artwork with transparent controls")
	scene.game.passives = []
	scene.game.consumable = ""
	scene.render()
	check.call(scene.ui.get_node_or_null("EquippedCoin_0") == null and scene.ui.get_node_or_null("ConsumableCoin") == null and not UI.text_in(scene.ui, "Ranura vacía"), "Encounter coins: empty inventory creates no coin frames or empty-slot slabs")
	var sway = preload("res://scripts/drag_sway.gd").new()
	sway.step(0.04, Vector2(30, 0))
	var moving_angle: float = absf(sway.angle)
	for frame in range(150): sway.step(0.016, Vector2.ZERO)
	check.call(moving_angle > 0 and absf(sway.angle) < 0.001, "Drag sway: pointer motion excites spring and resting pointer lets it settle")
	sway.enabled = false
	sway.step(0.04, Vector2(500, 0))
	check.call(sway.angle == 0, "Drag sway: reduced motion produces a static preview")
	sway.free()
	scene.preferences.drag_groups = false
	scene.selected.clear()
