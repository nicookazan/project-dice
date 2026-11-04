extends RefCounted
## Definitions and pure context; selection happens once at level entry, never on load.
const Coins = preload("res://scripts/coins.gd")
const Catalog = preload("res://scripts/boss_catalog.gd")
const CATEGORIES := ["Par", "Doble par", "Trío", "Escalera", "Full", "Póker", "Generala"]
## Poderes que marcan un dado por mano (sorteo propio en cada mano).
const DIE_POWERS := ["scared_die", "loaded_die", "abduction"]
const NONE = {"id": "sin_generala", "name": "Generala prohibida", "kind": "forbid_category", "target": "Generala"}

static func default_encounters() -> Array:
	return [{"id": "rival_1", "kind": "normal", "target": 40}, {"id": "rival_2", "kind": "normal", "target": 70}, {"id": "jefe", "kind": "boss", "target": 110}]

static func valid_rule(rule: Variant) -> bool:
	if not rule is Dictionary or rule.size() != 4 or not rule.get("id") is String or rule.id == "" or not rule.get("name") is String or rule.name == "": return false
	match rule.get("kind"):
		"forbid_category": return rule.get("target") is String and not rule.target.is_empty() and Array(rule.target.split(",")).all(func(name): return name in CATEGORIES)
		"suspend_material": return rule.get("target") in ["steel", "copper", "all"]
		"suspend_shell": return rule.get("target") in ["emerald", "sapphire", "ruby", "diamond", "all"]
		"suspend_coin": return rule.get("target") == "all" or (rule.get("target") is String and not Coins.definition(rule.target).is_empty())
		"boss_power": return rule.get("target") in Catalog.POWERS
		# Contextos que traducen un poder propio; solo se ven en el contexto, no como regla elegida.
		"suspend_element": return rule.get("target") in ["fire", "water", "electricity", "earth", "wind", "all"]
		"suspend_stickers": return rule.get("target") == "all"
		"hand_factor": return rule.get("target") in ["0.5", "1.5"]
		"hide_forecast": return rule.get("target") == "all"
		"abduct": return rule.get("target") in ["0", "1", "2", "3", "4"]
		"face_scale": return rule.get("target") in ["6=0", "5,6=0.5"]
		"repeat_half": return rule.get("target") is String and not rule.target.is_empty() and Array(rule.target.split(",")).all(func(name): return name in CATEGORIES)
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

static func context(rule: Dictionary, active: bool, state: Dictionary = {}, hand: int = 1) -> Dictionary:
	## Todo poder entra por este contexto: previsión y anotación leen lo mismo.
	if not active or not valid_rule(rule): return {}
	if rule.kind == "boss_power":
		var translated := {"id": rule.id, "name": rule.name}
		match rule.target:
			"red_card":
				var coin: String = state.get("coin", "")
				if coin == "": return {}
				translated.merge({"kind": "suspend_coin", "target": coin})
			"thermos_theft": translated.merge({"kind": "suspend_stickers", "target": "all"})
			"fire_out": translated.merge({"kind": "suspend_element", "target": "fire"})
			"madness": translated.merge({"kind": "hide_forecast", "target": "all"})
			"board_lock":
				var locked: String = state.get("locked", "")
				if hand < 2 or locked == "": return {}
				translated.merge({"kind": "forbid_category", "target": locked})
			"abduction":
				if int(state.get("die", -1)) < 0: return {}
				translated.merge({"kind": "abduct", "target": str(int(state.die))})
			"closed_list": translated.merge({"kind": "forbid_category", "target": "Par,Doble par"})
			"seventh_son": translated.merge({"kind": "face_scale", "target": "6=0"})
			"gravity": translated.merge({"kind": "face_scale", "target": "5,6=0.5"})
			"no_repeat":
				var scored: Array = state.get("scored", [])
				if hand < 2 or scored.is_empty(): return {}
				translated.merge({"kind": "repeat_half", "target": ",".join(scored)})
			"time_stop":
				var roulette: Array = state.get("roulette", [])
				if roulette.size() != 2: return {}
				translated.merge({"kind": "hand_factor", "target": str(roulette[clampi(hand, 1, 2) - 1])})
			_: return rule.duplicate(true)
		return translated
	return rule.duplicate(true)

## Escala de la cara (Lobizón: 6=0; Horizonte: 5 y 6 a la mitad). 1.0 si la cara no está afectada.
static func face_scale(context_value: Dictionary, number: int) -> float:
	if context_value.get("kind") != "face_scale": return 1.0
	var parts: PackedStringArray = str(context_value.target).split("=")
	return float(parts[1]) if parts.size() == 2 and str(number) in parts[0].split(",") else 1.0

## 0.5 para una categoría ya anotada en la mano 1 (Chamuyero), 1.0 en cualquier otro caso.
static func repeat_factor(context_value: Dictionary, category: String) -> float:
	return 0.5 if context_value.get("kind") == "repeat_half" and category in str(context_value.target).split(",") else 1.0

## Memoria entre manos: lo que el jefe recuerda de la mano 1 para la mano 2.
static func after_hand(rule: Dictionary, state: Dictionary, score: Dictionary, hand: int) -> Dictionary:
	if is_power(rule, "no_repeat") and hand == 1:
		var scored: Array = []
		for row in score.get("rows", []):
			if not row.get("ids", []).is_empty() and row.category in CATEGORIES and row.category not in scored: scored.append(row.category)
		return {"scored": scored}
	if is_power(rule, "board_lock") and hand == 1:
		var best := ""
		var best_total := -1.0
		for row in score.get("rows", []):
			if row.get("ids", []).is_empty() or row.category not in CATEGORIES: continue
			if float(row.total) > best_total:
				best_total = float(row.total)
				best = row.category
		return {"locked": best}
	return state

## Dado abducido (Visitante): no cuenta ni forma grupos. -1 si no hay.
static func abducted(context_value: Dictionary) -> int:
	return int(context_value.get("target", "-1")) if context_value.get("kind") == "abduct" else -1

## Dado marcado de la mano para los poderes que lo sortean; el generador sale de semilla + nivel + encuentro + mano.
static func draw_hand_die(rule: Dictionary, run_seed: int, level: int, encounter: int, hand: int) -> int:
	if rule.get("kind") != "boss_power" or rule.get("target") not in DIE_POWERS: return -1
	var generator := RandomNumberGenerator.new()
	generator.seed = ("%d:%d:%d:%d:%s" % [run_seed, level, encounter, hand, rule.target]).hash()
	return generator.randi_range(0, 4)

## La previsión de puntos se oculta (Durmiente). La anotación no cambia.
static func forecast_hidden(context_value: Dictionary) -> bool:
	return context_value.get("kind") == "hide_forecast"

static func stickers_suspended(context_value: Dictionary) -> bool:
	return context_value.get("kind") == "suspend_stickers"

## Multiplicador de la mano actual (Ruleta). 1.0 si el jefe no lo usa.
static func hand_factor(context_value: Dictionary) -> float:
	return float(context_value.get("target", "1.0")) if context_value.get("kind") == "hand_factor" else 1.0

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
	if is_power(rule, "no_repeat"): return {"scored": []}
	if is_power(rule, "board_lock"): return {"locked": ""}
	if is_power(rule, "kiosk_tax"): return {"tax": 0}
	if rule.get("kind") == "boss_power" and rule.get("target") in DIE_POWERS: return {"die": -1}
	if is_power(rule, "time_stop"):
		var roulette: Array = []
		for hand in [1, 2]:
			var spin := RandomNumberGenerator.new()
			spin.seed = ("%d:%d:%d:%d:%s" % [run_seed, level, encounter, hand, rule.target]).hash()
			roulette.append(0.5 if spin.randi_range(0, 1) == 0 else 1.5)
		return {"roulette": roulette}
	return {}

static func valid_state(rule: Dictionary, state: Variant, boss_active: bool) -> bool:
	if not state is Dictionary: return false
	if boss_active and is_power(rule, "time_stop"):
		if state.size() != 1 or not state.get("roulette") is Array or state.roulette.size() != 2: return false
		return state.roulette.all(func(value): return (value is float or value is int) and float(value) in [0.5, 1.5])
	if boss_active and rule.get("kind") == "boss_power" and rule.get("target") in DIE_POWERS:
		return state.size() == 1 and state.get("die") is int and state.die >= -1 and state.die <= 4
	if boss_active and is_power(rule, "board_lock"):
		return state.size() == 1 and state.get("locked") is String and (state.locked == "" or state.locked in CATEGORIES)
	if boss_active and is_power(rule, "kiosk_tax"):
		return state.size() == 1 and state.get("tax") is int and state.tax >= 0 and state.tax <= 4
	if boss_active and is_power(rule, "no_repeat"):
		if state.size() != 1 or not state.get("scored") is Array: return false
		return state.scored.all(func(name): return name is String and name in CATEGORIES) and state.scored.size() == Array(state.scored).reduce(func(seen, name): return seen if name in seen else seen + [name], []).size()
	if not boss_active or not is_power(rule, "red_card"): return state.is_empty()
	if state.size() != 1 or not state.get("coin") is String: return false
	return state.coin == "" or Coins.definition(state.coin).get("type") == "passive"

static func forbidden(context_value: Dictionary, category: String) -> bool:
	return context_value.get("kind") == "forbid_category" and category in str(context_value.get("target", "")).split(",")

static func forbid_message(context_value: Dictionary, category: String) -> String:
	if category == "Generala": return "Este jefe prohíbe generala. Podés dividir los cinco dados en trío y par."
	return "Este jefe prohíbe " + category.to_lower() + "."

static func suspended(context_value: Dictionary, family: String, id: String) -> bool:
	return id != "" and context_value.get("kind") == "suspend_" + family and context_value.get("target") in [id, "all"]

static func description(rule: Dictionary, state: Dictionary = {}, hand: int = 1) -> String:
	match rule.get("kind"):
		"boss_power":
			var text: String = rule.name + ": " + Catalog.power_text(rule.get("id", ""))
			if rule.target in DIE_POWERS and int(state.get("die", -1)) >= 0: text += " Dado marcado: %d." % (int(state.die) + 1)
			if is_power(rule, "time_stop") and state.get("roulette") is Array and state.roulette.size() == 2:
				text += " Mano %d: ×%s." % [clampi(hand, 1, 2), str(state.roulette[clampi(hand, 1, 2) - 1]).replace(".", ",")]
			return text
		"forbid_category": return "Generala prohibida: no agrupes cinco iguales como generala. Podés formar trío + par."
		"suspend_material": return rule.name + ": sin poder ni acumulación nueva durante el jefe. Conserva la pieza y los reinicios normales."
		"suspend_shell": return rule.name + ": conserva la carcasa; sin poder ni sorteos de rotura durante el jefe."
		"suspend_coin": return rule.name + ": sigue equipada o guardada; no aporta poder ni puede usarse durante el jefe."
	return "Sin regla especial"

static func cooldown_can_advance(_context: Dictionary, _coin_id: String) -> bool:
	# Reserved contract for F01. Suspension never blocks normal recharge events.
	return true
