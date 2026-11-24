extends RefCounted
## La Semilla (docs/LA-SEMILLA.md, ficha 21): encuentro 22 después del guardián, tienda de la mano con el maletín, semilla
## en pantalla, cinemática, créditos y jugadas con semilla elegida.
const Game = preload("res://scripts/game.gd")
const Campaign = preload("res://scripts/campaign.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const Validator = preload("res://scripts/save_validator.gd")
const Migrations = preload("res://scripts/save_migrations.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const ProfileStore = preload("res://scripts/profile_store.gd")
const Presentation = preload("res://scripts/presentation_state.gd")
const SeedDisplay = preload("res://scripts/seed_display.gd")
const SaveTests = preload("res://tests/save_tests.gd")
const UI = preload("res://tests/interface_tests.gd")

## Gana el encuentro en curso sin tocar el azar de la tienda: «daño infinito» solo para anotar.
static func beat(game) -> void:
	if game.phase == "level_intro": game.begin_level()
	var debug: bool = game.debug_mode
	game.debug_mode = true
	game.roll()
	game.score_hand()
	game.debug_mode = debug
	game.close_encounter()
	if game.phase == "repair": game.resolve_repairs([])

## Una jugada en el último nivel, con el guardián vencido y el cobro hecho (fase «reward»).
static func at_guardian_reward(seed_value: int):
	var game = Game.new(seed_value)
	game.begin_campaign(seed_value)
	# Las tablas de tienda y stickers de una jugada real (main.gd las aplica al empezar la campaña).
	preload("res://scripts/validation_profile.gd").apply(game)
	game.jump_to_level(6)
	beat(game)
	game.skip_shop()
	beat(game)
	game.skip_shop()
	beat(game)
	return game

static func offers(game) -> Array:
	var result: Array = []
	for section in ["coins", "components", "numbers", "stickers"]:
		for index in game.shop_state[section].slots.size():
			var offer: Dictionary = game.shop_state[section].slots[index]
			if not offer.is_empty(): result.append({"section": section, "index": index, "offer": offer})
	return result

static func run(scene, check: Callable) -> void:
	run_rules(check)
	run_saves(check)
	run_ui(scene, check)

static func run_rules(check: Callable) -> void:
	check.call(Campaign.seed_target(850) == 1275 and Campaign.seed_target(5) == 8 and Campaign.seed_target(1) == 2, "La Semilla: objetivo = guardián × 1,5, redondeado una vez (0,5 hacia arriba)")
	var fresh = Game.new(701)
	fresh.begin_campaign(701)
	check.call(fresh.campaign_route().size() == 22 and fresh.campaign_route()[21].name == Campaign.SEED_NAME, "La Semilla: la campaña tiene 22 encuentros y el último es La Semilla")
	fresh.jump_to_level(6)
	var plan: Array = fresh.level_encounters
	var guardian: Dictionary = Campaign.candidate(fresh.campaign[6], fresh.selected_bosses["6"])
	check.call(plan.size() == 4 and plan[3] == {"id": Campaign.SEED_ID, "kind": "seed", "target": Campaign.seed_target(guardian.target)} and plan[2].kind == "boss", "La Semilla: el nivel 7 suma La Semilla después del guardián")
	var earlier = Game.new(702)
	earlier.begin_campaign(702)
	check.call(earlier.level_encounters.size() == 3, "La Semilla: los niveles 1 a 6 siguen con tres encuentros")
	check.call(not BossRules.valid_encounters([plan[0], plan[1], plan[3], plan[2]]) and not BossRules.valid_encounters([plan[0], plan[1], plan[3]]) and BossRules.valid_encounters(plan), "La Semilla: solo puede ser el cuarto y último encuentro, después del jefe")

	var game = at_guardian_reward(703)
	check.call(game.phase == "reward" and game.rival == 2 and game.is_seed_shop_visit() and game.has_next_encounter(), "La Semilla: vencer al guardián ya no termina la jugada; sigue la mano con el maletín")
	check.call(Presentation.finale_stage(game) == "beaten", "La Semilla: tras el guardián el bar sigue intacto")
	check.call(game.open_shop(), "La Semilla: se abre la tienda de la mano")
	var stock := offers(game)
	var one_each := true
	for section in ["coins", "components", "numbers", "stickers"]:
		var filled: Array = stock.filter(func(item): return item.section == section)
		if filled.size() > 1 or (not filled.is_empty() and filled[0].index != 0): one_each = false
	check.call(one_each and stock.size() == 4 and game.shop_gifts.size() == 4, "La Semilla: la mano muestra un solo ítem por cada sección y los cuatro son regalo")
	check.call(stock.all(func(item): return game.charged_price(item.offer) == 0), "La Semilla: los regalos se cobran $0")
	check.call(not game.refresh_shop("coins") and not game.refresh_shop("numbers"), "La Semilla: no hay renovación por sección en la mano")
	game.cash = 0
	var gift: Dictionary = stock.filter(func(item): return item.offer.kind not in ["face", "material", "shell", "element"])[0] if not stock.filter(func(item): return item.offer.kind not in ["face", "material", "shell", "element"]).is_empty() else stock[0]
	var bought: Dictionary = game.begin_purchase(gift.section, gift.offer.offer_id)
	if bought.get("code", "") == "target_required":
		game.set_purchase_target({"die_id": 0, "face_index": 0} if gift.offer.kind == "face" else {"die_id": 0})
		bought = game.confirm_purchase()
	check.call(bought.get("ok", false) and game.cash == 0, "La Semilla: con $0 se puede llevar un regalo")
	var restored = SaveTests.roundtrip(game, check)
	check.call(restored != null and restored.shop_gifts == game.shop_gifts and restored.shop_state == game.shop_state, "La Semilla: guardar en la mano conserva qué regalos quedan")
	game.cash = 12
	var state_before: int = game.rng.state
	check.call(game.restock_seed_shop() and game.cash == 7 and game.shop_gifts.is_empty() and game.rng.state != state_before, "La Semilla: el restock cuesta $5 y saca otra tanda con el azar de la tienda")
	var paid := offers(game)
	check.call(not paid.is_empty() and paid.all(func(item): return game.charged_price(item.offer) == game.offer_price(item.offer.price, item.offer.kind == "coin") and game.charged_price(item.offer) > 0), "La Semilla: lo que trae el restock ya no es gratis")
	check.call(game.restock_seed_shop() and game.cash == 2, "La Semilla: el restock cuesta siempre lo mismo")
	check.call(not game.restock_seed_shop() and game.cash == 2, "La Semilla: sin plata no hay restock")
	check.call(Validator.validate(SaveTests.payload(game)) == "", "La Semilla: la tienda pagada se puede guardar")

	var rng_before: int = game.rng.state
	var expected := Campaign.seed_rule(game.campaign, game.selected_bosses, game.run_seed)
	check.call(game.rng.state == rng_before, "La Semilla: sortear su poder no toca el azar de la jugada")
	var pool: Array = []
	for index in 7: pool.append(Campaign.candidate(game.campaign[index], game.selected_bosses[str(index)]).rule.id)
	check.call(not expected.is_empty() and expected.id in pool, "La Semilla: su poder es el de uno de los jefes de la jugada")
	check.call(game.leave_shop() and game.rival == 3 and game.is_seed() and game.is_boss() and game.phase == "play" and game.boss_rule == expected, "La Semilla: al dejar la mano empieza el encuentro con ese poder")
	check.call(game.boss_name() == Campaign.SEED_NAME and game.target() == Campaign.seed_target(Campaign.candidate(game.campaign[6], game.selected_bosses["6"]).target), "La Semilla: se llama La Semilla y su objetivo es el del guardián × 1,5")
	check.call(Presentation.finale_stage(game) == "matrix" and game.shop_gifts.is_empty(), "La Semilla: su encuentro es sobre la Matrix")
	var again = at_guardian_reward(703)
	again.skip_shop()
	check.call(again.boss_rule == game.boss_rule, "La Semilla: misma semilla, mismo poder (aunque se saltee la tienda)")
	check.call(Validator.validate(SaveTests.payload(game)) == "", "La Semilla: su encuentro se puede guardar")
	game.roll()
	var forecast: Dictionary = game.preview()
	check.call(game.score_hand() and game.last_score.total == forecast.total, "La Semilla: la previsión coincide con la anotación")
	game.next_hand()
	game.roll()
	game.score_hand()
	check.call(game.phase == "lost", "La Semilla: perder contra La Semilla pierde la jugada")
	var winner = at_guardian_reward(704)
	winner.skip_shop()
	beat(winner)
	check.call(winner.phase == "won" and not winner.has_next_encounter() and winner.completed_encounters.size() == 22 and winner.completed_encounters[-1] == Campaign.SEED_ID, "La Semilla: vencerla gana la jugada con los 22 encuentros")
	check.call(Validator.validate(SaveTests.payload(winner)) == "", "La Semilla: el final ganado es un estado válido")

static func run_saves(check: Callable) -> void:
	var game = at_guardian_reward(705)
	game.skip_shop()
	var data := SaveTests.payload(game)
	data.game.boss_rule = Campaign.candidate(game.campaign[6], game.selected_bosses["6"]).rule
	if data.game.boss_rule == game.boss_rule: data.game.boss_rule = BossRules.NONE.duplicate(true)
	check.call(Validator.validate(data) != "", "La Semilla: el guardado rechaza un poder que no es el sorteado")
	var gifts := SaveTests.payload(game)
	gifts.game.shop_gifts = ["1"]
	check.call(Validator.validate(gifts) != "", "La Semilla: el guardado rechaza regalos fuera de la mano con el maletín")
	# Migración v9 -> v10: una jugada guardada en una tienda del nivel 7 recupera a La Semilla.
	var shop = Game.new(706)
	shop.begin_campaign(706)
	shop.jump_to_level(6)
	beat(shop)
	shop.open_shop()
	var old := SaveTests.payload(shop)
	old.game.level_encounters = old.game.level_encounters.slice(0, 3)
	old.game.erase("shop_gifts")
	old.game.erase("seeded")
	check.call(Validator.validate(old) != "", "La Semilla: un guardado v9 del nivel 7 no es válido tal cual")
	check.call(Migrations.seed_v10(old.game) == "" and Validator.validate(old) == "" and old.game.level_encounters == shop.level_encounters and old.game.seeded == false, "La Semilla: la migración v10 suma La Semilla y los campos nuevos")
	check.call(Migrations.seed_v10(old.game) == "" and old.game.level_encounters == shop.level_encounters, "La Semilla: la migración v10 es idempotente")
	# Marca de «ya visto» en la partida guardada: opcional, sin cambiar de versión.
	var data_ok := ProfileStore.empty_data()
	check.call(ProfileStore.valid_data(data_ok), "La Semilla: una partida guardada sin la marca sigue siendo válida")
	data_ok[ProfileStore.SEED_FINALE_KEY] = true
	check.call(ProfileStore.valid_data(data_ok), "La Semilla: la marca de final visto es válida")
	data_ok[ProfileStore.SEED_FINALE_KEY] = "sí"
	check.call(not ProfileStore.valid_data(data_ok), "La Semilla: una marca que no es sí/no se rechaza")
	var store := ProfileStore.new("user://test-results/la-semilla-partidas")
	store.delete(1)
	store.create(1)
	check.call(store.mark_seed_finale_seen(1).ok and store.read(1).data.get(ProfileStore.SEED_FINALE_KEY) == true and store.read(1).data.plays == 0, "La Semilla: se guarda que ya se vio el final, sin tocar las estadísticas")
	store.delete(1)

static func run_ui(scene, check: Callable) -> void:
	var saved_preferences: Dictionary = scene.preferences.duplicate()
	var saved_profiles: bool = scene.profiles_enabled
	scene.profiles_enabled = false
	scene.finale_seen_session = false
	# Semilla chica en la mesa.
	scene.preferences.reduced_motion = true
	scene.start_new_run(707)
	scene.game.begin_level()
	scene.render()
	var small: Node = scene.ui.get_node_or_null("SeedDisplay")
	check.call(small != null and small.mode == "small" and small.seed_text == str(scene.game.run_seed), "La Semilla: la semilla se ve chica arriba a la izquierda durante la jugada")
	scene.start_new_run(708, false, true)
	scene.game.begin_level()
	scene.render()
	check.call(scene.ui.get_node_or_null("SeedDisplay") == null, "La Semilla: el tutorial no muestra la semilla")
	# Con movimiento: al vencer al guardián no muere todavía; el bar cruje y sigue el cobro.
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	scene.game = at_guardian_reward(709)
	scene.session_started = true
	scene.finale_shown = ""
	scene.finale_anim = ""
	scene.render()
	check.call(scene.finale_anim == "" and scene.background.finale.anim == "" and scene.background.finale_stage == "beaten" and scene.background.guardian >= 0 and scene.ui.get_node_or_null("EncounterChoice") != null and UI.text_in(scene.ui, "GUARDIÁN VENCIDO"), "La Semilla: al ganarle, el guardián sigue vivo, sin grietas, y aparece el cobro")
	scene.act(scene.game.open_shop)
	check.call(UI.find_button(scene.ui, "Gratis") != null and scene.ui.find_child("SeedRestock", true, false) != null and scene.ui.find_child("Refresh", true, false) == null and UI.find_button(scene.ui, "Enfrentar a La Semilla →") != null, "La Semilla: la mano muestra regalos, la tanda nueva y el paso a La Semilla")
	scene.act(scene.game.leave_shop)
	check.call(scene.finale_anim == "death" and scene.background.finale.anim == "death" and scene.background.finale_guardian >= 0 and scene.ui.get_node_or_null("FinaleBlocker") != null, "La Semilla: al salir de la mano muere el guardián")
	check.call(scene.ui.find_child("SkipFinale", true, false) == null, "La Semilla: la primera vez no se puede omitir")
	scene.background.finale.stop()
	scene._on_finale_finished("death")
	check.call(scene.finale_anim == "collapse" and scene.background.finale.anim == "collapse" and scene.background.finale_stage == "matrix", "La Semilla: después de su muerte se derrumba el bar")
	scene.background.finale.stop()
	scene._on_finale_finished("collapse")
	var terminal: Node = scene.ui.get_node_or_null("SeedDisplay")
	check.call(scene.finale_anim == "travel" and terminal != null and terminal.mode == "terminal" and terminal.intro, "La Semilla: la semilla viaja al centro y crece en la terminal")
	scene._on_seed_intro_finished()
	check.call(scene.finale_anim == "" and scene.finale_seen_session and scene.ui.get_node_or_null("FinaleBlocker") == null and scene.ui.get_node("SeedDisplay").mode == "terminal", "La Semilla: termina la presentación y se juega contra la terminal")
	var boss_button: Node = scene.ui.get_node_or_null("InspectBoss")
	check.call(boss_button != null and boss_button.get_rect() == SeedDisplay.final_box(str(scene.game.run_seed).length()), "La Semilla: tocar la semilla muestra su poder")
	# La segunda vez se puede omitir.
	scene.game = at_guardian_reward(710)
	scene.finale_shown = ""
	scene.render()
	scene.act(scene.game.skip_shop)
	var skip: Button = scene.ui.find_child("SkipFinale", true, false)
	check.call(scene.finale_anim == "death" and skip != null, "La Semilla: ya visto el final, se puede omitir la animación")
	if skip != null: skip.pressed.emit()
	check.call(scene.finale_anim == "" and scene.background.finale.anim == "" and scene.ui.get_node("SeedDisplay").mode == "terminal", "La Semilla: omitir lleva directo a La Semilla")
	# Sin movimiento no hay animación.
	scene.preferences.reduced_motion = true
	scene.game = at_guardian_reward(711)
	scene.finale_shown = ""
	scene.render()
	scene.act(scene.game.skip_shop)
	check.call(scene.finale_anim == "" and scene.ui.get_node("SeedDisplay").mode == "terminal", "La Semilla: sin movimiento se pasa directo")
	# Derrota: reintentar con la misma semilla no suma nada.
	var lost = at_guardian_reward(712)
	lost.skip_shop()
	lost.roll()
	lost.score_hand()
	lost.next_hand()
	lost.roll()
	lost.score_hand()
	scene.game = lost
	scene.finale_shown = "matrix"
	scene.run_recorded = true
	scene.render()
	var retry: Button = UI.find_button(scene.ui, "Reintentar misma semilla")
	check.call(retry != null, "La Semilla: perder ofrece reintentar con la misma semilla")
	if retry != null: retry.pressed.emit()
	check.call(scene.game.run_seed == 712 and scene.game.seeded, "La Semilla: la jugada repetida queda marcada como semilla elegida")
	# Una jugada con semilla elegida no suma nada a la partida guardada (ni jugadas ni victorias ni desbloqueos).
	var store := ProfileStore.new("user://test-results/la-semilla-partidas")
	store.delete(1)
	store.create(1)
	var real_store = scene.profile_store
	var real_runs = scene.run_store
	scene.profile_store = store
	scene.run_store = SaveStore.new("user://test-results/la-semilla-partidas/jugada.json")
	scene.profiles_enabled = true
	scene.profile_slot = 1
	scene.game.phase = "lost"
	scene.record_finished_run()
	check.call(store.read(1).data.plays == 0, "La Semilla: la jugada con semilla elegida no suma a la partida guardada")
	scene.game.seeded = false
	scene.record_finished_run()
	check.call(store.read(1).data.plays == 1, "La Semilla: una jugada normal sí suma")
	scene.profiles_enabled = false
	scene.profile_store = real_store
	scene.run_store = real_runs
	scene.profile_slot = 0
	store.delete(1)
	scene.finale_seen_session = true
	# Victoria con movimiento: sin cartel; tiembla, cae la mesa, se apagan la semilla y la Matrix, y vienen los créditos solos.
	scene.preferences.reduced_motion = false
	var winner = at_guardian_reward(713)
	winner.skip_shop()
	scene.game = winner
	scene.finale_shown = "matrix"
	scene.render()
	beat(winner)
	scene.run_recorded = true
	scene.render()
	check.call(scene.finale_anim == "ending" and scene.background.finale.anim == "ending" and scene.background.finale_stage == "ending" and not UI.text_in(scene.ui, "LA SEMILLA DERROTADA"), "La Semilla: al ganarle no hay cartel; empieza el final")
	check.call(scene.ui.get_node_or_null("SeedDisplay") != null and scene.ui.get_node("SeedDisplay").top_level and scene.ui.get_node_or_null("FinaleBlocker") != null, "La Semilla: la semilla se apaga en su lugar y la mesa no se puede tocar")
	check.call(scene.ui.find_child("SkipFinale", true, false) == null, "La Semilla: la muerte de La Semilla no se puede omitir, aunque ya se haya visto")
	scene.background.finale.t = 3.0
	var finale = scene.background.finale
	var start: int = finale.ending_tick
	check.call(finale.strip_drop(0) > 0.0, "La Semilla: la mesa cae")
	check.call(finale.matrix_cells(start, 1.0, true, start).size() > 0 and finale.matrix_cells(start + 50, 1.0, true, start).is_empty() and finale.matrix_cells(start + 50).size() > 0, "La Semilla: la Matrix se queda sin líneas al final (sin el corte seguiría corriendo)")
	scene.background.finale.stop()
	scene._on_finale_finished("ending")
	check.call(scene.showing_credits and scene.ui.get_node_or_null("Credits") != null, "La Semilla: después aparecen solos los créditos")
	var next: Button = scene.ui.find_child("CreditsNext", true, false)
	if next != null: next.pressed.emit()
	check.call(scene.ui.get_node_or_null("Rewards") != null and UI.text_in(scene.ui, "RECOMPENSAS"), "La Semilla: después de los créditos vienen las recompensas")
	var back: Button = scene.ui.find_child("CreditsBack", true, false)
	if back != null: back.pressed.emit()
	check.call(scene.game.phase == "menu" and not scene.showing_credits and not scene.showing_rewards and scene.ui.get_node_or_null("MainMenu") != null, "La Semilla: de las recompensas se vuelve a la pantalla de inicio")
	# Sin movimiento: directo a los créditos.
	scene.preferences.reduced_motion = true
	var still = at_guardian_reward(714)
	still.skip_shop()
	scene.game = still
	scene.session_started = true
	scene.finale_shown = "matrix"
	scene.render()
	beat(still)
	scene.run_recorded = true
	scene.render()
	check.call(scene.finale_anim == "" and scene.ui.get_node_or_null("Credits") != null, "La Semilla: sin movimiento, ganar lleva directo a los créditos")
	scene.back_to_start()
	scene.preferences = saved_preferences
	scene.profiles_enabled = saved_profiles
	scene.finale_seen_session = false
	scene.finale_shown = ""
	scene.finale_anim = ""
	scene.background.finale.stop()
