extends RefCounted
## Definitions and pure context; selection happens once at level entry, never on load.
const Coins = preload("res://scripts/coins.gd")
const Catalog = preload("res://scripts/boss_catalog.gd")
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
		"boss_power": return rule.get("target") in Catalog.POWERS
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

static func context(rule: Dictionary, active: bool, state: Dictionary = {}) -> Dictionary:
	## Todo poder entra por este contexto: previsión y anotación leen lo mismo.
	if not active or not valid_rule(rule): return {}
	if is_power(rule, "red_card"):
		var coin: String = state.get("coin", "")
		return {} if coin == "" else {"id": rule.id, "name": rule.name, "kind": "suspend_coin", "target": coin}
	return rule.duplicate(true)

static func is_power(rule: Dictionary, power: String) -> bool:
	return rule.get("kind") == "boss_power" and rule.get("target") == power

## Sorteos propios del jefe: generador aparte derivado de semilla + nivel + encuentro, sin tocar el azar principal.
static func draw_state(rule: Dictionary, run_seed: int, level: int, encounter: int, equipped: Array) -> Dictionary:
	if is_power(rule, "red_card"):
		var ids := equipped.duplicate()
		ids.sort()
		if ids.is_empty(): return {"coin": ""}
		var generator := RandomNumberGenerator.new()
		generator.seed = ("%d:%d:%d:%s" % [run_seed, level, encounter, rule.target]).hash()
		return {"coin": ids[generator.randi_range(0, ids.size() - 1)]}
	return {}

static func valid_state(rule: Dictionary, state: Variant, boss_active: bool) -> bool:
	if not state is Dictionary: return false
	if not boss_active or not is_power(rule, "red_card"): return state.is_empty()
	if state.size() != 1 or not state.get("coin") is String: return false
	return state.coin == "" or Coins.definition(state.coin).get("type") == "passive"

static func forbidden(context_value: Dictionary, category: String) -> bool:
	return context_value.get("kind") == "forbid_category" and context_value.get("target") == category

static func suspended(context_value: Dictionary, family: String, id: String) -> bool:
	return id != "" and context_value.get("kind") == "suspend_" + family and context_value.get("target") in [id, "all"]

static func description(rule: Dictionary) -> String:
	match rule.get("kind"):
		"boss_power": return rule.name + ": " + Catalog.power_text(rule.get("id", ""))
		"forbid_category": return "Generala prohibida: no agrupes cinco iguales como generala. Podés formar trío + par."
		"suspend_material": return rule.name + ": sin poder ni acumulación nueva durante el jefe. Conserva la pieza y los reinicios normales."
		"suspend_shell": return rule.name + ": conserva la carcasa; sin poder ni sorteos de rotura durante el jefe."
		"suspend_coin": return rule.name + ": sigue equipada o guardada; no aporta poder ni puede usarse durante el jefe."
	return "Sin regla especial"

static func cooldown_can_advance(_context: Dictionary, _coin_id: String) -> bool:
	# Reserved contract for F01. Suspension never blocks normal recharge events.
	return true
