extends RefCounted
## Explicit category growth. Missing balance is not an implicit zero or x2.
const CATEGORIES = {
	"pair_loose": ["Par", "Sin combinación"], "trio": ["Trío"],
	"straight": ["Escalera"], "full": ["Full"], "poker": ["Póker"], "generala": ["Generala"]
}
const NAMES = {"pair_loose": "Par y sobrantes", "trio": "Trío", "straight": "Escalera", "full": "Full", "poker": "Póker", "generala": "Generala"}

static func catalog() -> Dictionary:
	var result: Dictionary = {}
	for id in CATEGORIES:
		result[id] = {"points_per_level": null, "multiplier_per_level": null, "price": null}
	return result

static func nonnegative(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0

static func defined(id: String, definitions: Dictionary) -> bool:
	if not CATEGORIES.has(id) or not definitions.get(id) is Dictionary: return false
	var data: Dictionary = definitions[id]
	return nonnegative(data.get("points_per_level")) and nonnegative(data.get("multiplier_per_level"))

static func missing(definitions: Dictionary) -> Array:
	var result: Array = []
	for id in CATEGORIES:
		if not defined(id, definitions): result.append(id)
	return result

static func valid_levels(levels: Dictionary, definitions: Dictionary) -> bool:
	for id in levels:
		if not id is String or not levels[id] is int or levels[id] <= 0 or not defined(id, definitions): return false
	return true

static func increased(levels: Dictionary, ids: Array, definitions: Dictionary) -> Dictionary:
	if not valid_levels(levels, definitions): return {"valid": false}
	var updated: Dictionary = levels.duplicate(true)
	var seen: Dictionary = {}
	for id in ids:
		if not id is String or seen.has(id) or not defined(id, definitions): return {"valid": false}
		seen[id] = true
		var old: int = updated.get(id, 0)
		var next: int = old + 1
		if next <= old: return {"valid": false}
		updated[id] = next
	return {"valid": true, "levels": updated}

static func evaluate(category: String, levels: Dictionary, definitions: Dictionary) -> Dictionary:
	for id in levels:
		if category in CATEGORIES[id]:
			var level: int = levels[id]
			return {"id": id, "name": NAMES[id], "level": level, "source": "sticker:" + id,
				"points": definitions[id].points_per_level * level,
				"multiplier_addition": definitions[id].multiplier_per_level * level}
	return {}

static func offer(kind: String, ids: Array, price: Variant, definitions: Dictionary) -> Dictionary:
	var count: int = {"single": 1, "choose_one": 3, "receive_two": 2}.get(kind, 0)
	if count == 0 or ids.size() != count or not price is int or price < 0: return {}
	var seen: Dictionary = {}
	for id in ids:
		if not id is String or seen.has(id) or not defined(id, definitions): return {}
		seen[id] = true
	if kind == "single":
		var fixed_price = definitions[ids[0]].get("price")
		if not fixed_price is int or fixed_price < 0 or price != fixed_price: return {}
	return {"kind": kind, "items": ids.duplicate(), "price": price, "purchased": false}
