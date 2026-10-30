extends RefCounted
## Definitions and pure context; selection happens once at level entry, never on load.
const Coins = preload("res://scripts/coins.gd")
const NONE = {"id": "sin_generala", "name": "Generala prohibida", "kind": "forbid_category", "target": "Generala"}

static func default_encounters() -> Array:
	return [{"id": "rival_1", "kind": "normal", "target": 40}, {"id": "rival_2", "kind": "normal", "target": 70}, {"id": "jefe", "kind": "boss", "target": 110}]

static func valid_rule(rule: Variant) -> bool:
	if not rule is Dictionary or rule.size() != 4 or not rule.get("id") is String or rule.id == "" or not rule.get("name") is String or rule.name == "": return false
	match rule.get("kind"):
		"forbid_category": return rule.get("target") == "Generala"
		"suspend_material": return rule.get("target") in ["steel", "copper", "all"]
		"suspend_shell": return rule.get("target") in ["emerald", "sapphire", "ruby", "diamond", "all"]
		"suspend_coin": return rule.get("target") == "all" or (rule.get("target") is String and not Coins.definition(rule.target).is_empty())
	return false

static func valid_encounters(encounters: Variant) -> bool:
	if not encounters is Array or encounters.is_empty() or encounters.size() > 3: return false
	var ids: Array = []
	var bosses := 0
	for encounter in encounters:
		if not encounter is Dictionary or encounter.size() != 3 or not encounter.get("id") is String or encounter.id == "" or encounter.id in ids or encounter.get("kind") not in ["normal", "boss"] or not encounter.get("target") is int or encounter.target < 1: return false
		ids.append(encounter.id)
		if encounter.kind == "boss": bosses += 1
	return bosses == 1

static func valid_pool(pool: Array) -> bool:
	if pool.is_empty(): return false
	var ids: Array = []
	for rule in pool:
		if not valid_rule(rule) or rule.id in ids: return false
		ids.append(rule.id)
	return true

static func choose(pool: Array, rng: RandomNumberGenerator) -> Dictionary:
	if not valid_pool(pool): return {}
	return pool[0 if pool.size() == 1 else rng.randi_range(0, pool.size() - 1)].duplicate(true)

static func context(rule: Dictionary, active: bool) -> Dictionary:
	return rule.duplicate(true) if active and valid_rule(rule) else {}

static func forbidden(context_value: Dictionary, category: String) -> bool:
	return context_value.get("kind") == "forbid_category" and context_value.get("target") == category

static func suspended(context_value: Dictionary, family: String, id: String) -> bool:
	return id != "" and context_value.get("kind") == "suspend_" + family and context_value.get("target") in [id, "all"]

static func description(rule: Dictionary) -> String:
	match rule.get("kind"):
		"forbid_category": return "Generala prohibida: no agrupes cinco iguales como generala. Podés formar trío + par."
		"suspend_material": return rule.name + ": sin poder ni acumulación nueva durante el jefe. Conserva la pieza y los reinicios normales."
		"suspend_shell": return rule.name + ": conserva la carcasa; sin poder ni sorteos de rotura durante el jefe."
		"suspend_coin": return rule.name + ": sigue equipada o guardada; no aporta poder ni puede usarse durante el jefe."
	return "Sin regla especial"

static func cooldown_can_advance(_context: Dictionary, _coin_id: String) -> bool:
	# Reserved contract for F01. Suspension never blocks normal recharge events.
	return true
