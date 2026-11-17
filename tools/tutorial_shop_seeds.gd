extends SceneTree
## Recorre semillas de la tienda del tutorial y muestra qué ofrece cada una (sin tocar nada del juego).
## Uso: godot --headless --path . --script res://tools/tutorial_shop_seeds.gd -- 1 60
## Una buena tienda tiene: una moneda pasiva barata, una moneda de un uso, un sticker, un número y un componente.
## Elegí una y ponela en `TutorialScript.SHOP_SEED`.
const Game = preload("res://scripts/game.gd")
const Coins = preload("res://scripts/coins.gd")
const Shop = preload("res://scripts/shop.gd")
const ValidationProfile = preload("res://scripts/validation_profile.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var from := int(args[0]) if args.size() > 0 else 1
	var to := int(args[1]) if args.size() > 1 else 40
	for seed_value in range(from, to + 1):
		var game := Game.new(1)
		game.begin_tutorial(1)
		ValidationProfile.apply(game)
		var fixed := RandomNumberGenerator.new()
		fixed.seed = seed_value
		var state := Shop.empty_state()
		var staged: int = fixed.state
		var serial := 0
		var seen: Array = []
		var lines: Array = []
		var score := 0
		for section in ["coins", "components", "numbers", "stickers"]:
			var generated := Shop.generate(section, game.shop_tables, game.sticker_catalog, [], staged, serial, seen, [])
			state[section] = generated.section
			staged = generated.rng_state
			serial = generated.sequence
			seen = generated.once_seen
			var names: Array = []
			for slot in generated.section.slots:
				if slot.is_empty(): continue
				names.append(describe(slot))
				if section == "coins" and slot.kind == "coin" and slot.price <= 6: score += 1
			lines.append("%s: %s" % [section, ", ".join(names)])
		print("seed %d (%d) · %s" % [seed_value, score, " | ".join(lines)])
	quit()

func describe(slot: Dictionary) -> String:
	match slot.kind:
		"coin": return "%s $%d" % [Coins.definition(slot.effect.coin_id).name, slot.price]
		"coin_pack": return "paquete %s $%d" % [slot.effect.size, slot.price]
		"material", "shell", "element": return "%s %s $%d" % [slot.kind, slot.effect.id, slot.price]
		"global": return "+%d al %d $%d" % [slot.effect.amount, slot.effect.number, slot.price]
		"face": return "cara→%d $%d" % [slot.effect.number, slot.price]
		"sticker": return "sticker %s $%d" % [slot.effect.id, slot.price]
		"pack": return "paquete stickers $%d" % slot.price
	return slot.kind
