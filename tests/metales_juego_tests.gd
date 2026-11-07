extends RefCounted
## TX4: metales nuevos en el juego. Cada uno da lo mismo que su metal base; nada de reglas nuevas.
const Game = preload("res://scripts/game.gd")
const Materials = preload("res://scripts/materials.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const Validator = preload("res://scripts/save_validator.gd")
const SaveTests = preload("res://tests/save_tests.gd")
const Shop = preload("res://scripts/shop.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const BossRules = preload("res://scripts/boss_rules.gd")

static func _play(material: String) -> Dictionary:
	var game = Game.new(42)
	game.dice[0].material = material
	game.roll()
	Fixture.set_results(game, [4, 1, 2, 3, 5])
	game.move_die(1, "cup")
	game.roll()
	game.move_die(1, "cup")
	game.move_die(2, "cup")
	game.roll()
	return {"game": game, "preview": game.preview(), "points": Materials.steel_points(game.dice[0]), "mult": Materials.copper_multiplier(game.dice[0])}

static func run(check: Callable) -> void:
	for pair in [["rust_iron", "steel"], ["rust_copper", "copper"], ["gold", "steel"]]:
		var nuevo: Dictionary = _play(pair[0])
		var base: Dictionary = _play(pair[1])
		check.call(nuevo.points == base.points and nuevo.mult == base.mult, "TX4: %s acumula igual que %s (%s puntos, %s mult)" % [pair[0], pair[1], nuevo.points, nuevo.mult])
		check.call(nuevo.preview.rows.size() == base.preview.rows.size() and nuevo.preview.total == base.preview.total, "TX4: %s puntúa igual que %s en la previsión" % [pair[0], pair[1]])
		var info: Dictionary = Materials.inspect(nuevo.game.dice[0])
		check.call(info.id == pair[0] and info.name == Materials.display_name(pair[0]) and info.gain == Materials.inspect(base.game.dice[0]).gain, "TX4: %s se inspecciona con su nombre y la ganancia de su base" % pair[0])
	# Guardado: un metal nuevo se guarda y vuelve igual; partidas viejas y valores inválidos.
	for id in Materials.METALS:
		var game = Game.new(7)
		game.dice[0].material = id
		var payload: Dictionary = SaveTests.payload(game)
		check.call(Validator.validate(payload) == "", "TX4: el guardado acepta el material %s" % id)
		check.call(SaveTests.roundtrip(game, check).dice[0].material == id, "TX4: el material %s vuelve igual tras guardar" % id)
	var tampered: Dictionary = SaveTests.payload(Game.new(7))
	tampered.game.dice[0].material = "platino"
	check.call(Validator.validate(tampered) != "", "TX4: un material desconocido se rechaza")
	# Tienda: los tres entran con el mismo precio y peso que su base.
	var candidates: Array = Profile.tables().components
	var ids := {}
	for entry in candidates:
		if entry.kind == "material": ids[entry.effect.id] = entry
	check.call(ids.size() == 5, "TX4: la tienda de prueba ofrece los cinco metales")
	check.call(ids.has("gold") and ids.gold.price == ids.steel.price and ids.gold.weight == ids.steel.weight and ids.rust_copper.price == ids.copper.price, "TX4: precio y peso de cada metal nuevo igualan a su base")
	for id in Materials.METALS:
		check.call(Shop.valid_candidate("components", {"kind": "material", "price": 3, "weight": 1.0, "effect": {"id": id}}, {}), "TX4: la tienda acepta ofertas de %s" % id)
	# Jefes: suspender el metal base suspende también a sus variantes.
	var boss := {"kind": "suspend_material", "target": "steel"}
	check.call(BossRules.suspended(boss, "material", Materials.base_of("rust_iron")) and BossRules.suspended(boss, "material", Materials.base_of("gold")) and not BossRules.suspended(boss, "material", Materials.base_of("rust_copper")), "TX4: el jefe que suspende hierro alcanza al oxidado y al oro, no al cobre oxidado")
