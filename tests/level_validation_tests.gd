extends RefCounted
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/rules.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const Shop = preload("res://scripts/shop.gd")
const Coins = preload("res://scripts/coins.gd")
const Store = preload("res://scripts/save_store.gd")
const Validator = preload("res://scripts/save_validator.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const UI = preload("res://tests/interface_tests.gd")
const Flow = preload("res://tests/level_flow_tests.gd")
static var comparisons: Array = []
static var folder := ""
static var serial := 0

static func isolate(scene, profile: bool) -> void:
	serial += 1
	scene.detail.hide()
	scene.cancel_navigation()
	scene.validation_profile = profile
	scene.persistence_enabled = true
	scene.save_store = Store.new(folder + "/case-" + str(serial) + ".json")
	scene.session_started = false
	scene.last_checkpoint = {}
	scene.save_error = ""

static func reload_ui(scene, check: Callable, context: String) -> bool:
	var before: Dictionary = scene.checkpoint_data()
	var valid: bool = scene.save_error == "" and scene.save_store.inspect().get("active", false)
	check.call(valid, "Integral: checkpoint valid before reload " + context + " / " + scene.save_error)
	if not valid: return false
	Flow.click(scene, "Menú")
	var resumed := Flow.click(scene, "Continuar")
	check.call(resumed and scene.checkpoint_data() == before, "Integral: UI reload preserves exact game/RNG/choices " + context)
	return resumed

static func annotate(scene, check: Callable, context: String) -> void:
	var expected: Dictionary = scene.game.preview()
	var before_points: int = scene.game.points
	var control = UI.find_button(scene.ui, "ANOTAR MANO")
	control.pressed.emit()
	var same: bool = scene.game.last_score == expected and scene.game.points - before_points == expected.total
	comparisons.append({"context": context, "predicted": expected.total, "credited": scene.game.points - before_points, "matches": same, "rows": expected.rows})
	check.call(same, "Integral: exact preview/credit and breakdown " + context)
	var snapshot: Dictionary = scene.game.snapshot()
	control.pressed.emit() # A queued second click on the original control.
	check.call(scene.game.snapshot() == snapshot, "Integral: second annotation click cannot repeat points/risk " + context)

static func play_hand(scene, check: Callable, context: String) -> void:
	Flow.click(scene, "TIRAR (%d)" % scene.game.rolls_left)
	var best := Flow.best_groups(scene.game)
	while best.total < scene.game.target() - scene.game.points and best.total < 45 and scene.game.rolls_left > 0:
		var counts: Dictionary = {}
		for die in scene.game.dice: counts[die.value] = counts.get(die.value, 0) + 1
		var keep := 0
		for value in counts:
			if counts[value] > counts.get(keep, 1): keep = value
		for die in scene.game.dice:
			if die.value != keep: scene.toggle_die(die.id)
		Flow.click(scene, "Al vaso →")
		Flow.click(scene, "TIRAR (%d)" % scene.game.rolls_left)
		best = Flow.best_groups(scene.game)
	for group in best.groups:
		for id in group.ids: scene.toggle_die(id)
		Flow.click(scene, "Armar grupo")
	reload_ui(scene, check, context + " / grouped hand")
	annotate(scene, check, context)

static func natural_run(scene, seed_value: int, profile: bool, ending: String, check: Callable) -> Dictionary:
	isolate(scene, profile)
	scene.game.return_to_menu()
	scene.refresh_save_status()
	scene.render()
	Flow.click(scene, "Nueva partida")
	# Fixed regression seed is input; dice, stock, cash and outcomes are never injected.
	scene.start_new_run(seed_value)
	Flow.click(scene, "Empezar primer encuentro")
	var trace: Array = []
	var steps := 0
	while scene.game.phase not in ["won", "lost"] and steps < 40:
		steps += 1
		var game = scene.game
		match game.phase:
			"play":
				play_hand(scene, check, "%s seed %d rival %d hand %d" % ["profile" if profile else "normal", seed_value, game.rival, game.hand])
				trace.append({"rival": scene.game.rival, "hand": scene.game.hand, "score": scene.game.last_score.total, "accumulated": scene.game.points})
			"hand_result":
				reload_ui(scene, check, "natural hand result")
				if scene.game.points >= scene.game.target(): Flow.click(scene, "Cerrar y cobrar")
				else: Flow.click(scene, "Jugar segunda mano")
			"reward":
				reload_ui(scene, check, "natural credited reward")
				var before: Dictionary = scene.game.snapshot()
				check.call(not scene.game.close_encounter() and scene.game.snapshot() == before, "Integral: natural resumed reward cannot pay again")
				Flow.click(scene, "Ir a la tienda →")
			"shop":
				reload_ui(scene, check, "natural generated shop")
				for offer in scene.game.shop_state.coins.slots:
					if not offer.is_empty() and offer.price == 4 and scene.game.cash >= 4:
						UI.find_button(scene.ui.get_node("Shop_coins"), "$4").pressed.emit()
						break
				Flow.click(scene, "Ir al %s →" % ("jefe" if scene.game.rival == 1 else "siguiente rival"))
			_: break
	check.call(scene.game.phase == ending and scene.save_error == "", "Integral: natural route ends " + ending + " with reloads, no injected outcomes")
	if ending == "lost": check.call(UI.text_in(scene.ui, "se agotaron las manos") and scene.game.payout.is_empty(), "Integral: loss explains exhausted hands/target and grants no final reward")
	check.call(not scene.save_store.inspect().active, "Integral: natural terminal state cannot resume")
	return {"seed": seed_value, "profile": Profile.ID if profile else "normal", "ending": scene.game.phase, "hands": trace, "cash": scene.game.cash, "rival": scene.game.rival}

static func controlled_shop(scene, check: Callable) -> void:
	isolate(scene, true)
	scene.start_new_run(400)
	Flow.click(scene, "Empezar primer encuentro")
	Fixture.set_values(scene.game, [4, 4, 4, 4, 4])
	scene.game.form_group([0, 1, 2, 3, 4])
	scene.render()
	annotate(scene, check, "controlled opening to laboratory shop")
	Flow.click(scene, "Cerrar y cobrar")
	Flow.click(scene, "Ir a la tienda →")
	scene.game.cash = 200 # Explicit laboratory wallet, never used in natural routes.
	scene.render()
	check.call(scene.save_error == "", "Integral: generated mixed profile shop is persistable")

static func offer_from_profile(kind: String, id: String) -> Dictionary:
	for section in Profile.tables():
		if not Profile.tables()[section] is Array: continue
		for candidate in Profile.tables()[section]:
			if candidate.kind != kind: continue
			var effect: Dictionary = candidate.effect
			if (kind == "coin" and effect.coin_id == id) or (kind in ["material", "element", "shell", "sticker"] and effect.id == id) or kind in ["global", "face"] or (kind == "pack" and effect.pack_kind == id): return candidate.duplicate(true)
	return {}

static func buy_controlled(scene, kind: String, id: String, check: Callable, die_id := 0, face_index := 3) -> void:
	var section: String = {"coin": "coins", "global": "numbers", "local": "numbers", "face": "numbers", "sticker": "stickers", "pack": "stickers"}.get(kind, "components")
	var candidate := offer_from_profile(kind, id)
	if kind in ["global"]: candidate.effect.number = 4
	if kind == "face": candidate.effect.number = 6
	if kind == "pack":
		candidate.effect.erase("pool")
		candidate.effect.items = ["trio", "full", "pair_loose"] if id == "choose_one" else ["trio", "full"]
	scene.game.shop_offer_sequence += 1
	var offer_id := "integral:" + str(scene.game.shop_offer_sequence)
	candidate.offer_id = offer_id
	candidate.erase("weight")
	scene.game.shop_state[section].slots[0] = candidate
	scene.game.shop_state[section].configured = true
	scene.render()
	var cards: Array = scene.ui.get_node("Shop_" + section).get_children().filter(func(node): return node is Panel)
	var purchase = UI.find_button(cards[0], "$%d" % candidate.price)
	var before_cash: int = scene.game.cash
	purchase.pressed.emit()
	if kind in ["material", "element", "shell", "face"]:
		scene.ui.get_node("PurchaseTarget/Die_%d" % die_id).pressed.emit()
		if kind == "face": scene.ui.get_node("PurchaseTarget/Face_%d" % face_index).pressed.emit()
		reload_ui(scene, check, "pending target " + kind + ":" + id)
		check.call(scene.game.cash == before_cash, "Integral: selecting/reloading target does not charge " + kind)
		Flow.click(scene, "Confirmar · $%d" % candidate.price)
	check.call(scene.game.cash == before_cash - candidate.price and scene.game.purchase_receipts.has(offer_id), "Integral: actual UI purchase applies once " + kind + ":" + id)
	if scene.detail.visible: scene.detail.hide()
	if kind == "pack" and id == "choose_one":
		reload_ui(scene, check, "paid choose pack")
		var choice = UI.find_button(scene.ui, "Trío · nivel %d → %d" % [scene.game.cup.stickers.get("trio", 0), scene.game.cup.stickers.get("trio", 0) + 1])
		check.call("+3 puntos" in choice.tooltip_text and "+0.5" in choice.tooltip_text, "Integral: paid pack exposes candidate growth before choosing")
		Flow.click(scene, "Trío · nivel %d → %d" % [scene.game.cup.stickers.get("trio", 0), scene.game.cup.stickers.get("trio", 0) + 1])
	var snapshot: Dictionary = scene.game.snapshot()
	purchase.pressed.emit()
	if scene.detail.visible: scene.detail.hide()
	check.call(scene.game.snapshot() == snapshot, "Integral: queued second purchase click cannot duplicate " + kind + ":" + id)
	reload_ui(scene, check, "purchased " + kind + ":" + id)

static func run(scene, check: Callable) -> Dictionary:
	folder = "res://test-results/integral/" + str(Time.get_ticks_usec())
	comparisons = []
	var tables: Dictionary = Profile.tables()
	for section in ["coins", "components", "numbers", "stickers"]:
		check.call(tables[section].all(func(candidate): return Shop.valid_candidate(section, candidate, Profile.stickers())), "Integral: explicit profile candidates valid in " + section)
	check.call(Game.new(1).shop_tables.components.is_empty() and Store.new().path != Store.new(Profile.SAVE_PATH).path, "Integral: profile opt-in and saved separately from normal player")
	var routes: Array = []
	for profile in [false, true]:
		routes.append(natural_run(scene, 1 if profile else 3, profile, "won", check))
		routes.append(natural_run(scene, 0, profile, "lost", check))
	controlled_shop(scene, check)
	var historic_score: Dictionary = scene.game.last_score.duplicate(true)
	for kind in ["global"]: buy_controlled(scene, kind, "", check)
	buy_controlled(scene, "face", "", check, 4)
	check.call(scene.game.dice[4].value == 4 and scene.game.dice[4].faces[3] == 6 and scene.game.last_score == historic_score and scene.save_error == "", "Integral: purchased last-rolled face preserves historic result/blue score and saves new face")
	scene.inspect_die(4)
	check.call("Resultado anterior al cambio de cara" in scene.detail_text, "Integral: inspection explains historic result after face purchase")
	scene.detail.hide()
	var invalid: Dictionary = scene.checkpoint_data()
	invalid.game.phase = "play"
	check.call(Validator.validate(invalid) != "", "Integral: face/result mismatch remains rejected in active play")
	for id in ["steel", "copper"]: buy_controlled(scene, "material", id, check, 0 if id == "steel" else 1)
	for index in range(5): buy_controlled(scene, "element", ["fire", "water", "electricity", "earth", "wind"][index], check, index)
	for index in range(4): buy_controlled(scene, "shell", ["emerald", "sapphire", "ruby", "diamond"][index], check, index)
	buy_controlled(scene, "coin", "even", check)
	buy_controlled(scene, "coin", "boost", check)
	buy_controlled(scene, "sticker", "trio", check)
	var text: Array = scene.shop_offer_text({"kind": "sticker", "effect": {"id": "trio"}})
	check.call("Nivel 1 → 2" in text[1] and "+3 puntos/nivel" in text[1] and "+0.5" in text[1], "Integral: sticker offer explains exact level growth before paying")
	text = scene.shop_offer_text({"kind": "shell", "effect": {"id": "ruby"}})
	check.call("20%" in text[1] and "$3" in text[1], "Integral: shell offer exposes breakage risk and repair cost before paying")
	buy_controlled(scene, "pack", "choose_one", check)
	buy_controlled(scene, "pack", "receive_two", check)
	Flow.click(scene, "Ir al siguiente rival →")
	Flow.click(scene, "TIRAR (3)")
	Flow.click(scene, "Impulso 1 y 3")
	Fixture.set_results(scene.game, [4, 4, 4, 2, 2])
	scene.game.form_group([0, 1, 2])
	scene.game.form_group([3, 4])
	scene.render()
	reload_ui(scene, check, "combined purchased equipment before score")
	annotate(scene, check, "combined purchased equipment")
	if scene.game.points >= scene.game.target():
		Flow.click(scene, "Cerrar y cobrar")
		if scene.game.phase == "repair":
			reload_ui(scene, check, "mixed equipment optional repairs")
			Flow.click(scene, "Continuar sin reparar")
	_test_score_matrix(scene, check)
	var mismatches: Array = comparisons.filter(func(row): return not row.matches)
	check.call(mismatches.is_empty(), "Integral: zero preview/credited mismatches across catalog scenarios")
	scene.persistence_enabled = false
	scene.campaign_mode = false
	scene.validation_profile = false
	scene.save_error = ""
	scene.session_started = false
	return {"date": "2026-10-26", "profile": Profile.ID, "routes": routes, "comparisons": comparisons, "mismatches": mismatches, "human_playtest": "pending", "balance_approved": false}

static func _test_score_matrix(scene, check: Callable) -> void:
	var cases: Array = []
	for id in Coins.catalog(): cases.append({"kind": "coin", "id": id})
	for id in ["steel", "copper"]: cases.append({"kind": "material", "id": id})
	for id in ["fire", "water", "electricity", "earth", "wind"]: cases.append({"kind": "element", "id": id})
	for id in ["emerald", "sapphire", "ruby", "diamond"]: cases.append({"kind": "shell", "id": id})
	for id in Profile.stickers(): cases.append({"kind": "sticker", "id": id})
	for entry in cases:
		for face in [2, 4]:
			isolate(scene, true)
			scene.start_new_run(410)
			Flow.click(scene, "Empezar primer encuentro")
			match entry.kind:
				"coin":
					if Coins.definition(entry.id).type == "passive": scene.game.passives = [entry.id]
					else:
						scene.game.consumable = entry.id
						scene.game.use_consumable()
				"material": scene.game.dice[0].material = entry.id
				"element": scene.game.dice[0].element = entry.id
				"shell": scene.game.dice[0].shell = entry.id
				"sticker": scene.game.cup.stickers = {entry.id: 2}
			scene.game.roll()
			if entry.kind == "material" or (entry.kind == "element" and entry.id in ["earth", "wind"]):
				scene.game.move_die(1 if entry.id in ["steel", "earth"] else 0, "cup")
				scene.game.roll()
			var values := [face, face, face, 6 - face, 6 - face]
			var groups := [[0, 1, 2], [3, 4]]
			if entry.kind in ["coin", "sticker"]:
				match entry.id:
					"full": groups = [[0, 1, 2, 3, 4]]
					"straight":
						values = [1, 2, 3, 4, 5]
						groups = [[0, 1, 2, 3, 4]]
					"poker":
						values = [face, face, face, face, 1]
						groups = [[0, 1, 2, 3]]
					"generala":
						values = [face, face, face, face, face]
						groups = [[0, 1, 2, 3, 4]]
					"pair_loose":
						values = [face, face, 1, 3, 5]
						groups = [[0, 1]]
			Fixture.set_results(scene.game, values)
			for ids in groups: scene.game.form_group(ids)
			scene.render()
			reload_ui(scene, check, "catalog " + entry.id)
			annotate(scene, check, "%s %s face %d" % [entry.kind, entry.id, face])
