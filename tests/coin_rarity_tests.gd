extends RefCounted
## MON2: rarezas nuevas de monedas y guardado v9 (migración desde v8, idempotente).
const Game = preload("res://scripts/game.gd")
const Coins = preload("res://scripts/coins.gd")
const Shop = preload("res://scripts/shop.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const SaveMigrations = preload("res://scripts/save_migrations.gd")
const Validator = preload("res://scripts/save_validator.gd")

## [id, rareza, precio, reventa]
const RARITY_TABLE = [
	["generala_pts", "common", 4, 2], ["metal", "common", 4, 2], ["elemental", "common", 4, 2], ["gems", "common", 4, 2], ["sixes", "common", 4, 2],
	["free_renewal", "rare", 6, 3], ["unused_rolls", "rare", 6, 3], ["last_roll", "rare", 6, 3], ["second_hand", "rare", 6, 3], ["interest", "rare", 6, 3],
]
const V9_KEYS = ["hand_mult_bonus", "hand_points_bonus", "visit_discount", "boss_shield_active", "once_coins_seen", "pending_coin_pack"]

static func _payload(game) -> Dictionary:
	return {"game": game.snapshot(), "ui": {"selected": [], "repair_selection": [], "shop_section": "coins", "pack_panel_open": false}}

static func _write_version(store, data: Dictionary, version: int) -> void:
	var bytes := var_to_bytes(data)
	DirAccess.make_dir_recursive_absolute(store.path.get_base_dir())
	store.write_text(store.path, JSON.stringify({"format": SaveStore.FORMAT, "version": version, "sha256": bytes.hex_encode().sha256_text(), "payload": Marshalls.raw_to_base64(bytes)}))

static func run(check: Callable) -> void:
	for row in RARITY_TABLE:
		var data := Coins.definition(row[0])
		check.call(data.rarity == row[1] and data.price == row[2] and data.resale == row[3], "MON2: %s es %s, cuesta $%d y se vende por $%d" % [row[0], row[1], row[2], row[3]])
	check.call(Coins.definition("pair_pts").rarity == "common" and Coins.definition("flat_mult").rarity == "rare", "MON2: las monedas que no cambian conservan su rareza")
	check.call(SaveStore.VERSION == 9, "MON2: el guardado está en la versión 9")

	var game = Game.new(91)
	game.passives = ["full"]
	game.cash = 7
	var snapshot: Dictionary = game.snapshot()
	check.call(V9_KEYS.all(func(key): return snapshot.has(key)), "MON2: la partida expone los campos nuevos del guardado")
	check.call(snapshot.hand_mult_bonus == 0 and snapshot.hand_points_bonus == 0 and snapshot.visit_discount == 0.0 and snapshot.boss_shield_active == false and snapshot.once_coins_seen == [] and snapshot.pending_coin_pack == {}, "MON2: los campos nuevos arrancan vacíos")
	check.call(Validator.validate(_payload(game)) == "", "MON2: una partida nueva valida")

	# Un guardado v8 no trae los campos nuevos y tiene la tabla de monedas con los precios viejos.
	var legacy: Dictionary = game.snapshot()
	for key in V9_KEYS: legacy.erase(key)
	var old_table: Array = []
	for id in Coins.catalog():
		old_table.append({"kind": "coin", "price": 4, "weight": 1.0, "effect": {"coin_id": id}})
	old_table.pop_back()
	legacy.shop_tables["coins"] = old_table
	var payload := {"game": legacy, "ui": _payload(game).ui}
	var store := SaveStore.new("user://saves/mon2-v8-test.json")
	_write_version(store, payload, 8)
	var loaded: Dictionary = store.read_file(store.path)
	check.call(loaded.ok, "MON2: un guardado v8 carga (%s)" % loaded.get("message", ""))
	if loaded.ok:
		var migrated: Dictionary = loaded.data.game
		check.call(V9_KEYS.all(func(key): return migrated.has(key)), "MON2: la migración completa los campos nuevos")
		check.call(migrated.cash == 7 and migrated.rng_state == legacy.rng_state and migrated.coin_inventory == legacy.coin_inventory and migrated.shop_state == legacy.shop_state, "MON2: la migración no toca plata, azar, inventario ni ofertas generadas")
		var rebuilt: Array = migrated.shop_tables.coins
		var expected: Array = Shop.default_tables().coins
		check.call(rebuilt == expected and rebuilt.size() == Coins.catalog().size(), "MON2: la tabla de monedas se reconstruye con el catálogo vigente")
		var restored = store.restore_game(loaded.data)
		check.call(restored != null and restored.passives == ["full"] and restored.hand_mult_bonus == 0, "MON2: el guardado migrado restaura una partida jugable")
		# Idempotencia: migrar dos veces da lo mismo.
		var again: Dictionary = migrated.duplicate(true)
		check.call(SaveMigrations.coins_v9(again) == "" and again == migrated, "MON2: migrar dos veces no cambia nada")

	# Tablas de laboratorio (pesos distintos) se respetan.
	var lab: Dictionary = game.snapshot()
	for key in V9_KEYS: lab.erase(key)
	lab.shop_tables["coins"] = [{"kind": "coin", "price": 1, "weight": 3.0, "effect": {"coin_id": "full"}}]
	var kept: Array = lab.shop_tables.coins.duplicate(true)
	check.call(SaveMigrations.coins_v9(lab) == "" and lab.shop_tables.coins == kept, "MON2: una tabla de laboratorio no se reconstruye")

	# Valores fuera de rango o con forma incorrecta se rechazan.
	for case in [["hand_mult_bonus", -1], ["hand_points_bonus", 2000000], ["visit_discount", 0.95], ["once_coins_seen", ["no_existe"]], ["pending_coin_pack", {"x": 1}]]:
		var bad := _payload(game)
		bad.game[case[0]] = case[1]
		check.call(Validator.validate(bad) != "", "MON2: se rechaza %s inválido" % case[0])
	var wrong_type := _payload(game)
	wrong_type.game["boss_shield_active"] = 1
	check.call(Validator.validate(wrong_type) != "", "MON2: se rechaza un tipo incorrecto en boss_shield_active")

	# Un guardado v9 nuevo viaja completo.
	game.visit_discount = 0.5
	game.hand_mult_bonus = 2
	var roundtrip_store := SaveStore.new("user://saves/mon2-v9-test.json")
	DirAccess.make_dir_recursive_absolute(roundtrip_store.path.get_base_dir())
	var written: Dictionary = roundtrip_store.start(_payload(game))
	var reread: Dictionary = roundtrip_store.read_file(roundtrip_store.path)
	check.call(written.ok and reread.ok and reread.data.game.visit_discount == 0.5 and reread.data.game.hand_mult_bonus == 2, "MON2: un guardado v9 conserva los campos nuevos")
	for target in [store, roundtrip_store]:
		for suffix in ["", ".bak", ".tmp", ".closed"]:
			if FileAccess.file_exists(target.path + suffix): DirAccess.remove_absolute(target.path + suffix)
