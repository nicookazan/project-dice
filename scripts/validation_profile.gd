extends RefCounted
## Explicit provisional data for step 16, opt-in only. Not approved commercial balance.
const ID := "nivel-corto-prueba-v1"
const SAVE_PATH := "user://saves/validacion-nivel-v1.json"
const Coins = preload("res://scripts/coins.gd")

static func stickers() -> Dictionary:
	return {
		"pair_loose": {"points_per_level": 2, "multiplier_per_level": 0.25, "price": 3},
		"trio": {"points_per_level": 3, "multiplier_per_level": 0.5, "price": 4},
		"straight": {"points_per_level": 0, "multiplier_per_level": 1.0, "price": 5},
		"full": {"points_per_level": 4, "multiplier_per_level": 0.75, "price": 6},
		"poker": {"points_per_level": 5, "multiplier_per_level": 1.25, "price": 7},
		"generala": {"points_per_level": 7, "multiplier_per_level": 1.5, "price": 8}
	}

static func tables() -> Dictionary:
	var result := {"coins": [], "components": [], "numbers": [], "stickers": [], "numeric_rarity_weights": {"common": 4.0, "rare": 2.0, "epic": 1.0, "legendary": 0.5}}
	for id in Coins.catalog(): result.coins.append({"kind": "coin", "price": Coins.definition(id).price, "weight": 1.0, "effect": {"coin_id": id}})
	for id in ["steel", "copper"]: result.components.append({"kind": "material", "price": 3, "weight": 1.0, "effect": {"id": id}})
	for id in ["fire", "water", "electricity", "earth", "wind"]: result.components.append({"kind": "element", "price": 3, "weight": 1.0, "effect": {"id": id}})
	for id in ["emerald", "sapphire", "ruby", "diamond"]: result.components.append({"kind": "shell", "price": 4, "weight": 1.0, "effect": {"id": id, "intact": true}})
	var rarities := ["common", "rare", "epic", "legendary"]
	var globals := [1, 4, 6, 9]
	for n in range(1, 7):
		for r in range(4):
			result.numbers.append({"kind": "global", "price": 2 + r, "weight": 1.0, "rarity": rarities[r], "effect": {"number": n, "amount": globals[r]}})
		result.numbers.append({"kind": "face", "price": 2, "weight": 1.0, "rarity": "common", "effect": {"number": n}})
	var pool: Array = []
	for id in stickers():
		pool.append(id)
		result.stickers.append({"kind": "sticker", "price": stickers()[id].price, "weight": 1.0, "effect": {"id": id}})
	for kind in ["choose_one", "receive_two"]:
		result.stickers.append({"kind": "pack", "price": 5, "weight": 1.0, "effect": {"pack_kind": kind, "pool": pool.duplicate()}})
	return result

static func apply(game) -> void:
	game.sticker_catalog = stickers()
	game.shop_tables = tables()
