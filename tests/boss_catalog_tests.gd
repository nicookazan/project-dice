extends RefCounted
## Fase A de docs/PLAN-JEFES.md: catálogo de 21 entradas, campaña desde datos, estado del jefe y guardado v8.
const Catalog = preload("res://scripts/boss_catalog.gd")
const Campaign = preload("res://scripts/campaign.gd")
const Boss = preload("res://scripts/boss_rules.gd")
const Game = preload("res://scripts/game.gd")
const Store = preload("res://scripts/save_store.gd")
const Validator = preload("res://scripts/save_validator.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const SaveTests = preload("res://tests/save_tests.gd")
const CampaignTests = preload("res://tests/campaign_tests.gd")
# Tabla del PRD de jefes (Notion, 4 de noviembre de 2026): id -> [objetivo, recompensa].
const PRD_TABLE := {
	"l1_kioskero": [125, 11], "l1_payador": [130, 12], "l1_palomas": [115, 9],
	"l2_cebador": [160, 8], "l2_chamuyero": [175, 10], "l2_referi": [170, 9],
	"l3_gotico": [230, 8], "l3_conde": [255, 10], "l3_lobizon": [220, 7],
	"l4_tahur": [305, 7], "l4_patovica": [350, 10], "l4_payaso": [335, 9],
	"l5_visitante": [375, 6], "l5_farolero": [420, 7], "l5_computadora": [460, 9],
	"l6_horizonte": [570, 7], "l6_relojero": [690, 11], "l6_durmiente": [720, 12],
	"l7_dios_dados": [800, 8], "l7_dios_metales": [850, 8], "l7_dios_carcasas": [900, 8]
}
const SEVERITY_K := {1: [1.15, 1.20], 2: [1.05, 1.10], 3: [0.95, 1.00], 4: [0.85, 0.90]}

static func legacy_id(id: String) -> String:
	var row := Catalog.entry(id)
	return id if row.is_empty() else "prueba_l%d_%d" % [row.level, row.slot]

## Reescribe una partida actual con el formato de guardado v7 (ids de prueba, sin boss_state).
static func v7_payload(game) -> Dictionary:
	var data := SaveTests.payload(game)
	var g: Dictionary = data.game
	g.erase("boss_state")
	for level in g.campaign:
		for candidate in level.candidates:
			candidate.id = legacy_id(candidate.id)
			candidate.rule.id = candidate.id
	for key in g.selected_bosses: g.selected_bosses[key] = legacy_id(g.selected_bosses[key])
	g.completed_encounters = g.completed_encounters.map(func(id): return legacy_id(id))
	for encounter in g.level_encounters: encounter.id = legacy_id(encounter.id)
	g.boss_rule.id = legacy_id(g.boss_rule.id)
	return data

static func write_version(service, data: Dictionary, version: int) -> void:
	var bytes := var_to_bytes(data)
	DirAccess.make_dir_recursive_absolute(service.path.get_base_dir())
	service.write_text(service.path, JSON.stringify({"format": Store.FORMAT, "version": version, "payload": Marshalls.raw_to_base64(bytes), "sha256": bytes.hex_encode().sha256_text()}))

static func forced_boss(id: String, at_boss: bool, seed_value: int = -1):
	## Campaña consistente (guardable) parada en el jefe pedido, en desarrollo para poder forzar cualquiera.
	var row := Catalog.entry(id)
	if seed_value < 0: seed_value = 900 + row.level * 10 + row.slot
	var game = Game.new(seed_value)
	game.development_bosses = true
	game.begin_campaign(seed_value)
	var level: int = row.level - 1
	var completed: Array = []
	var selected := {}
	for earlier in range(level):
		selected[str(earlier)] = game.campaign[earlier].candidates[0].id
		completed.append_array([game.campaign[earlier].id + "_r1", game.campaign[earlier].id + "_r2", game.campaign[earlier].candidates[0].id])
	selected[str(level)] = id
	game.level_index = level
	game.selected_bosses = selected
	game.completed_encounters = completed
	game._enter_campaign_level()
	game.begin_level()
	if at_boss:
		game.rival = 2
		game.completed_encounters.append_array([game.campaign[level].id + "_r1", game.campaign[level].id + "_r2"])
		game._start_encounter()
	return game

static func red_card_game(seed_value: int, coins: Array):
	var game = forced_boss("l2_referi", true, seed_value)
	game.passives = coins
	game._refresh_boss_state()
	return game

static func run(check: Callable) -> Dictionary:
	_catalog(check)
	_campaign(check)
	_release_filter(check)
	_red_card(check)
	_migration(check)
	_art(check)
	return {"catalog": Catalog.ROWS.size(), "implemented": Catalog.ROWS.filter(func(row): return row.implemented).size(), "save_version": Store.VERSION}

static func _catalog(check: Callable) -> void:
	var ids: Array = []
	check.call(Catalog.ROWS.size() == 21 and PRD_TABLE.size() == 21, "Boss catalog: 18 bosses plus the three God rules")
	for level in range(1, 8):
		check.call(Catalog.of_level(level).size() == 3, "Boss catalog: three entries in level %d" % level)
	for row in Catalog.ROWS:
		check.call(row.id not in ids and row.id.begins_with("l%d_" % row.level), "Boss catalog: stable unique id " + row.id)
		ids.append(row.id)
		check.call(row.name != "" and row.hand != "" and row.power != "" and row.text != "", "Boss catalog: texts present for " + row.id)
		check.call(Boss.valid_rule(Catalog.rule_of(row)), "Boss catalog: rule accepted by BossRules for " + row.id)
		check.call(Catalog.target_of(row) == PRD_TABLE[row.id][0] and Catalog.reward_of(row) == PRD_TABLE[row.id][1], "Boss catalog: target and reward match the PRD table for " + row.id)
		if row.level < 7:
			var bounds: Array = SEVERITY_K[row.severity]
			check.call(row.k >= bounds[0] and row.k <= bounds[1], "Boss catalog: k inside severity band for " + row.id)
			check.call(Catalog.target_of(row) == int(round(Catalog.PIVOT[row.level - 1] * row.k / 5.0)) * 5, "Boss catalog: target is P x k rounded to 5 for " + row.id)
			check.call(Catalog.reward_of(row) == maxi(6, 8 + int(round((row.k - 1.0) * 20.0))), "Boss catalog: reward formula for " + row.id)
	check.call(Catalog.PIVOT == [110, 160, 230, 320, 440, 600, 800], "Boss catalog: provisional P per level")
	check.call(Catalog.ROWS.all(func(row): return row.implemented), "Boss catalog: all 21 entries have a power with engine hooks")
	for power in Catalog.POWERS:
		check.call(Catalog.ROWS.any(func(row): return row.target == power), "Boss catalog: power listed has a boss " + power)
	check.call(Catalog.map_legacy_id("prueba_l3_2") == "l3_conde" and Catalog.map_legacy_id("prueba_l7_3") == "l7_dios_carcasas" and Catalog.map_legacy_id("l2_cebador") == "l2_cebador" and Catalog.map_legacy_id("prueba_l9_1") == "", "Boss catalog: legacy ids map by level and position")

static func _campaign(check: Callable) -> void:
	var levels: Array = Campaign.prototype()
	check.call(Campaign.valid(levels) and levels.size() == 7, "Boss campaign: built from the catalog and valid")
	var names: Array = []
	for level in levels:
		check.call(level.candidates.size() == 3 and level.candidates.all(func(c): return not "prueba" in c.name.to_lower() and not "prueba" in c.id), "Boss campaign: no test labels in level " + level.id)
		for candidate in level.candidates: names.append(candidate.name)
	check.call("El Kioskero" in names and "Dios" in names, "Boss campaign: catalog names reach the campaign")
	check.call(levels[0].targets == [40, 70] and levels[6].targets == [440, 600], "Boss campaign: rival targets unchanged")
	check.call(Campaign.candidate(levels[6], "l7_dios_metales").target == 850 and Campaign.candidate(levels[1], "l2_cebador").base_reward == 8, "Boss campaign: boss target and reward come from the catalog")

static func _release_filter(check: Callable) -> void:
	var release = Game.new(610)
	release.development_bosses = false
	release.begin_campaign(610)
	check.call(release.selected_bosses["0"] in ["l1_payador", "l1_palomas"], "Boss filter: release build only draws bosses with a working power")
	var fallback = Game.new(611)
	fallback.development_bosses = false
	fallback.begin_campaign(611)
	fallback.level_index = 2
	fallback._enter_campaign_level()
	check.call(not Catalog.entry(fallback.selected_bosses["2"]).is_empty(), "Boss filter: a level without working powers falls back to its full pool instead of breaking")
	check.call(Catalog.ready_for_release(), "Boss filter: every catalog boss has its working power, so the release gate is open")
	var seen := {}
	for seed_value in range(620, 640):
		var development = Game.new(seed_value)
		development.development_bosses = true
		development.begin_campaign(seed_value)
		seen[development.selected_bosses["0"]] = true
	check.call(seen.size() == 3, "Boss filter: development build can draw all three bosses")

static func _red_card(check: Callable) -> void:
	var game = red_card_game(700, ["even", "odd"])
	check.call(game.boss_rule.id == "l2_referi" and game.is_boss() and game.phase == "play", "Red card: scenario reaches the boss")
	check.call(game.boss_state.get("coin") in ["even", "odd"], "Red card: a coin was expelled on entry")
	var rng_before: int = game.rng.state
	var state_before: Dictionary = game.boss_state.duplicate(true)
	game._refresh_boss_state()
	check.call(game.boss_state == state_before and game.rng.state == rng_before, "Red card: draw is reproducible and never touches the main RNG")
	var other = red_card_game(700, ["odd", "even"])
	check.call(other.boss_state == state_before, "Red card: draw does not depend on the order coins were bought")
	var outcomes := {}
	for seed_value in range(701, 731):
		outcomes[red_card_game(seed_value, ["even", "odd", "poker"]).boss_state.coin] = true
	check.call(outcomes.size() >= 2, "Red card: the expelled coin varies with the seed")
	var expelled: String = game.boss_state.coin
	var kept: String = "odd" if expelled == "even" else "even"
	check.call(Boss.suspended(game.boss_context(), "coin", expelled) and not Boss.suspended(game.boss_context(), "coin", kept), "Red card: only the expelled coin is suspended")
	check.call(expelled in game.passives and game._active_passives().has(kept) and not game._active_passives().has(expelled), "Red card: expelled coin stays equipped but gives no power")
	var solo = red_card_game(702, ["even"])
	Fixture.set_values(solo, [2, 2, 2, 4, 4])
	solo.form_group([0, 1, 2])
	solo.form_group([3, 4])
	var preview: int = solo.preview().total
	var plain = red_card_game(702, ["even"])
	plain.boss_state = {"coin": ""}
	Fixture.set_values(plain, [2, 2, 2, 4, 4])
	plain.form_group([0, 1, 2])
	plain.form_group([3, 4])
	check.call(preview < plain.preview().total, "Red card: expelled coin lowers the forecast")
	solo.score_hand()
	check.call(solo.last_score.total == preview, "Red card: forecast equals the final score")
	var empty = red_card_game(703, [])
	check.call(empty.boss_state == {"coin": ""} and empty.boss_context().is_empty(), "Red card: with no coins nothing is expelled")
	var restored = SaveTests.roundtrip(game, check)
	check.call(restored != null and restored.boss_state == game.boss_state and restored.snapshot().boss_state == state_before, "Red card: saved state restores without redrawing")
	var tampered := SaveTests.payload(game)
	tampered.game.boss_state = {"coin": "no_existe"}
	check.call(Validator.validate(tampered) != "", "Red card: unknown expelled coin is rejected")
	tampered = SaveTests.payload(game)
	tampered.game.boss_state = {"coin": "even", "extra": 1}
	check.call(Validator.validate(tampered) != "", "Red card: extra fields in the boss state are rejected")
	var normal := Game.new(704)
	normal.begin_campaign(704)
	check.call(normal.boss_state.is_empty(), "Boss state: empty outside a boss with its own draw")
	var leaked := SaveTests.payload(normal)
	leaked.game.boss_state = {"coin": "even"}
	check.call(Validator.validate(leaked) != "", "Boss state: a rival cannot carry a boss draw")

static func _migration(check: Callable) -> void:
	for stop in [0, 2, 3, 8]:
		var game = CampaignTests.advance_model(Campaign.prototype(), stop)
		var service = SaveTests.store()
		write_version(service, v7_payload(game), 7)
		var loaded: Dictionary = service.read_file(service.path)
		check.call(loaded.ok, "Boss migration v7 -> v8: loads at stop %d (%s)" % [stop, loaded.get("message", "")])
		if not loaded.ok: continue
		var migrated = service.restore_game(loaded.data)
		check.call(migrated != null and migrated.snapshot() == game.snapshot(), "Boss migration v7 -> v8: ids, rule and progress equal the current format at stop %d" % stop)
		var before = game.rng.state
		check.call(migrated.rng.state == before and migrated.run_seed == game.run_seed, "Boss migration v7 -> v8: exact RNG state kept at stop %d" % stop)
		migrated.begin_level() if migrated.phase == "level_intro" else null
		game.begin_level() if game.phase == "level_intro" else null
		check.call(migrated.roll() and game.roll() and migrated.dice == game.dice, "Boss migration v7 -> v8: next roll is identical at stop %d" % stop)
	var original = CampaignTests.advance_model(Campaign.prototype(), 2)
	var legacy := v7_payload(original)
	var service = SaveTests.store()
	write_version(service, legacy, 7)
	var content := FileAccess.get_file_as_string(service.path)
	service.read_file(service.path)
	check.call(FileAccess.get_file_as_string(service.path) == content, "Boss migration v7 -> v8: reading never rewrites the original file")
	var saved: Dictionary = service.save(SaveTests.payload(original))
	check.call(saved.ok and FileAccess.get_file_as_string(service.path + ".bak") == content and JSON.parse_string(FileAccess.get_file_as_string(service.path)).version == 8, "Boss migration v7 -> v8: first checkpoint publishes v8 and backs up the v7 file")
	var unknown := v7_payload(original)
	unknown.game.selected_bosses["0"] = "prueba_l9_9"
	var broken = SaveTests.store()
	write_version(broken, unknown, 7)
	check.call(not broken.read_file(broken.path).ok and FileAccess.get_file_as_string(broken.path) != "", "Boss migration v7 -> v8: unknown boss ids are rejected and the file is kept")
	var future = SaveTests.store()
	write_version(future, SaveTests.payload(original), 9)
	check.call(future.read_file(future.path).code == "version", "Boss migration: a newer version is refused and kept")

static func _art(check: Callable) -> void:
	## Fase C: hoja de manos (18 filas de 8 cuadros de 61×53) y guardianes de Dios.
	var sheet: Texture2D = load("res://assets/art/pixel-v3/manos-jefes-v3.png")
	var rivals := Catalog.ROWS.filter(func(row): return row.level <= Catalog.GOD_LEVEL)
	check.call(sheet != null and sheet.get_size() == Vector2(61 * 8, 53 * 18) and rivals.size() == 18, "Boss hands: 18 rows of 8 frames of 61x53")
	var rows := {}
	for row in rivals: rows[Catalog.hand_row(row.id)] = true
	check.call(rows.size() == 18 and not rows.has(-1) and rows.keys().all(func(r): return r >= 0 and r < 18), "Boss hands: every rival and boss has its own row")
	check.call(Catalog.hand_row("l7_dios_dados") == -1 and Catalog.hand_row("fuera_del_catalogo") == -1, "Boss hands: God and unknown ids keep the common hand")
	var guardians := {}
	for id in ["l7_dios_dados", "l7_dios_metales", "l7_dios_carcasas"]: guardians[Catalog.guardian(id)] = true
	check.call(guardians.size() == 3 and guardians.keys().all(func(g): return g >= 0 and g < 3) and Catalog.guardian("l1_kioskero") == -1, "Boss guardians: each God encounter has a distinct guardian")
	# Como en los otros niveles, la semilla sortea cuál de los tres candidatos toca y el guardián lo sigue.
	var seen := {}
	var follows := true
	for seed_value in range(1, 41):
		var game = Game.new(seed_value)
		game.begin_campaign(seed_value)
		game.level_index = 6
		game._enter_campaign_level()
		var picked: String = game.selected_bosses["6"]
		var again = Game.new(seed_value)
		again.begin_campaign(seed_value)
		again.level_index = 6
		again._enter_campaign_level()
		follows = follows and again.selected_bosses["6"] == picked and Catalog.guardian(picked) >= 0 and game.boss_rule.id == picked
		seen[Catalog.guardian(picked)] = true
	check.call(follows and seen.size() == 3, "Boss guardians: the seed picks the God encounter (reproducible) and all three guardians come up")
	var backdrop = load("res://scripts/backdrop.gd").new()
	var profile := {"environment": "cielo", "actor": "god", "level": 6, "boss_id": "l7_dios_metales"}
	var preferences := {"reduced_motion": true, "speed": 1}
	backdrop.configure(profile, preferences)
	var guardian_ok: bool = backdrop.guardian == 1 and backdrop.hand_row == -1
	profile.actor = "kind"; profile.boss_id = "l3_conde"
	backdrop.configure(profile, preferences)
	check.call(guardian_ok and backdrop.guardian == -1 and backdrop.hand_row == Catalog.hand_row("l3_conde"), "Backdrop: God shows its guardian, bosses their hand, rivals the common hand")
	backdrop.free()
