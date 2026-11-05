extends RefCounted
## Pure scoring functions: dice identity never changes when points are improved.
const NumberUpgrades = preload("res://scripts/number_upgrades.gd")
const Materials = preload("res://scripts/materials.gd")
const Elements = preload("res://scripts/elements.gd")
const Gems = preload("res://scripts/gems.gd")
const Stickers = preload("res://scripts/stickers.gd")

const BASES = {"Par": 5, "Doble par": 15, "Trío": 10, "Escalera": 20, "Full": 30, "Póker": 40, "Generala": 50, "Sin combinación": 0}
# Doble par has no extra served bonus until its value is defined by design.
const SERVED = {"Escalera": 25, "Full": 35, "Póker": 45, "Generala": 100}
const Coins = preload("res://scripts/coins.gd")
const CoinEffects = preload("res://scripts/coin_effects.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const COINS = Coins.DATA
const PASSIVES = Coins.PASSIVES
const CONSUMABLES = Coins.CONSUMABLES

const STRAIGHT4_SETS = [[1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6], [1, 4, 5, 6]]

static func category(values: Array, rules: Dictionary = {}) -> String:
	var counts: Dictionary = {}
	for value in values:
		counts[value] = counts.get(value, 0) + 1
	var sizes: Array = counts.values()
	sizes.sort()
	if values.size() == 2 and sizes == [2]: return "Par"
	if values.size() == 3 and sizes == [3]: return "Trío"
	if values.size() == 4 and sizes == [2, 2]: return "Doble par"
	if values.size() == 4 and sizes == [4]: return "Póker"
	if values.size() == 5:
		if sizes == [5]: return "Generala"
		if sizes == [2, 3]: return "Full"
		var sorted := values.duplicate()
		sorted.sort()
		if sorted in [[1, 2, 3, 4, 5], [2, 3, 4, 5, 6], [1, 3, 4, 5, 6]]: return "Escalera"
	if values.size() == 4 and rules.get("straight4", false):
		var sorted4 := values.duplicate()
		sorted4.sort()
		if sorted4 in STRAIGHT4_SETS: return "Escalera"
	return ""

## Number a die counts as inside a group: only the wildcard rule changes a result of 1.
static func effective_value(die: Dictionary, group: Dictionary, rules: Dictionary) -> int:
	if rules.get("wildcard", false) and die.get("value", 0) == 1:
		return group.get("assigned", {}).get(die.get("id", -1), 1)
	return die.get("value", 0)

## Deterministic wildcard assignment for a chosen set: best category base, then highest face sum,
## ties to the lowest numbers. The result is stored in the group so preview == score == save.
static func resolve_wildcards(dice: Array, ids: Array, rules: Dictionary) -> Dictionary:
	var wild: Array = []
	var fixed: Array = []
	for id in ids:
		if rules.get("wildcard", false) and dice[id].value == 1: wild.append(id)
		else: fixed.append(dice[id].value)
	if wild.is_empty(): return {"category": category(fixed, rules), "assigned": {}}
	var best := {"category": "", "assigned": {}, "key": -1}
	var picks: Array = []
	_assign(wild, 0, 1, fixed, picks, rules, best)
	return {"category": best.category, "assigned": best.assigned}

static func _assign(wild: Array, at: int, minimum: int, fixed: Array, picks: Array, rules: Dictionary, best: Dictionary) -> void:
	if at == wild.size():
		var values: Array = fixed + picks
		var cat := category(values, rules)
		if cat.is_empty(): return
		var total := 0
		for value in values: total += value
		var key: int = BASES[cat] * 100 + total
		if key > best.key:
			best.key = key
			best.category = cat
			best.assigned = {}
			for i in range(wild.size()): best.assigned[wild[i]] = picks[i]
		return
	for number in range(minimum, 7):
		picks.append(number)
		_assign(wild, at + 1, number, fixed, picks, rules, best)
		picks.pop_back()

static func validate_groups(dice: Array, groups: Array, rules: Dictionary = {}) -> Array:
	var used: Dictionary = {}
	for index in range(dice.size()):
		if not dice[index] is Dictionary:
			return ["Dado inválido."]
		var number = dice[index].get("value", 0)
		if not number is int or number < 1 or number > 6:
			return ["El dado no tiene un resultado válido."]
		if dice[index].get("id", index) != index:
			return ["La identidad del dado no coincide con su posición."]
	for group in groups:
		if not group is Dictionary or not group.get("ids", null) is Array or group.ids.is_empty():
			return ["Grupo vacío o inválido."]
		var values: Array = []
		for id in group.ids:
			if not id is int or id < 0 or id >= dice.size() or used.has(id):
				return ["Un dado está repetido o no existe."]
			used[id] = true
			values.append(effective_value(dice[id], group, rules))
		var assigned = group.get("assigned", {})
		if not assigned is Dictionary or (not assigned.is_empty() and not rules.get("wildcard", false)):
			return ["Asignación de comodín inválida."]
		for key in assigned:
			if not key is int or key not in group.ids or dice[key].value != 1 or not assigned[key] is int or assigned[key] < 1 or assigned[key] > 6:
				return ["Asignación de comodín inválida."]
		var detected := category(values, rules)
		if detected.is_empty() or detected != group.get("category", ""):
			return ["La categoría no coincide con la selección exacta."]
	return []

static func _sum(entries: Array) -> float:
	var result := 0.0
	for entry in entries:
		result += float(entry.amount)
	return result

static func _product(entries: Array) -> float:
	var result := 1.0
	for entry in entries:
		result *= float(entry.amount)
	return result

static func resolve_die(die: Dictionary, additions: Array = [], factors: Array = []) -> Dictionary:
	# Explicit, already-earned contributions. Reading a die never activates powers.
	var before_factors: float = float(die.value) + _sum(additions)
	return {
		"id": die.id, "number": die.value, "face_index": die.get("face_index", -1),
		"base_points": float(die.value),
		"point_additions": additions.duplicate(true),
		"point_factors": factors.duplicate(true),
		"before_factors": before_factors,
		"points": before_factors * _product(factors)
	}

static func resolve_group(base: float, dice_points: float, added_points: float,
		multiplier_base: float = 1.0, additions: Array = [], factors: Array = [], copies: Array = []) -> Dictionary:
	# Shared arithmetic for scoring and controlled fixtures. No catalog/dispatch system.
	var subtotal := base + dice_points + added_points
	var multiplier_sum := multiplier_base + _sum(additions)
	var multiplier := multiplier_sum * _product(factors)
	var original_total := subtotal * multiplier
	var copy_count := _sum(copies)
	return {
		"base": base, "dice": dice_points, "added": added_points, "subtotal": subtotal,
		"multiplier_base": multiplier_base, "multiplier_additions": additions.duplicate(true),
		"multiplier_sum": multiplier_sum, "multiplier_factors": factors.duplicate(true),
		"multiplier": multiplier, "original_total": original_total,
		"copies": copies.duplicate(true), "copy_count": copy_count,
		"total": original_total * (1.0 + copy_count)
	}

static func finish_score(rows: Array, served: bool, errors: Array = []) -> Dictionary:
	var raw_total := 0.0
	if errors.is_empty():
		for row in rows:
			raw_total += float(row.total)
	return {
		"total": int(floor(raw_total + 0.5)), "raw_total": raw_total,
		"rows": rows.duplicate(true) if errors.is_empty() else [],
		"served": served, "valid": errors.is_empty(), "errors": errors.duplicate()
	}

static func impulse_ids(boost: Variant) -> Array:
	# Compatibility: the old bool meant the single Impulso (U01).
	if boost is Array: return boost.duplicate()
	return ["boost"] if boost == true else []

static func score(dice: Array, groups: Array, passives: Array, boost: Variant, served: bool, global_points: Dictionary = {}, sticker_levels: Dictionary = {}, sticker_catalog: Dictionary = {}, boss_context: Dictionary = {}, coin_context: Dictionary = {}) -> Dictionary:
	var effective_passives: Array = passives.filter(func(id): return not BossRules.suspended(boss_context, "coin", id))
	var effective_impulses: Array = impulse_ids(boost).filter(func(id): return not BossRules.suspended(boss_context, "coin", id))
	var rules := CoinEffects.rules(effective_passives)
	var errors := validate_groups(dice, groups, rules)
	if not boss_context.is_empty() and not BossRules.valid_rule(boss_context): errors.append("Regla de jefe inválida.")
	for group in groups:
		if group is Dictionary and BossRules.forbidden(boss_context, group.get("category", "")): errors.append("El jefe prohíbe " + group.category + ".")
		if group is Dictionary and group.get("ids") is Array and BossRules.abducted(boss_context) in group.ids: errors.append("El dado abducido no puede agruparse.")
	if not Stickers.valid_levels(sticker_levels, sticker_catalog):
		errors.append("Sticker sin datos de nivel o balance válidos.")
	if not NumberUpgrades.valid_points(global_points):
		errors.append("Mejoras globales inválidas.")
	for coin in passives:
		if coin not in PASSIVES:
			errors.append("Moneda pasiva desconocida.")
	for id in impulse_ids(boost):
		if id not in CONSUMABLES: errors.append("Moneda de un uso desconocida.")
	if not errors.is_empty():
		return finish_score([], served, errors)
	# Same context builder for preview and scoring: state is read, never written, here.
	var rolls_made: int = coin_context.get("rolls_made", 1 if served else 2)
	var sticker_total := 0
	for level in sticker_levels.values(): sticker_total += int(level)
	var context := {"hand": 1, "level": 1, "rolls_made": rolls_made, "rolls_left": maxi(3 - rolls_made, 0), "cash": 0,
		"equipped_count": passives.size(), "sticker_total": sticker_total, "states": {}, "double_mult": false}
	context.merge(coin_context, true)
	var double_mult: bool = context.double_mult and not BossRules.suspended(boss_context, "coin", "double_mult")
	var rows: Array = []
	var used: Dictionary = {}
	var counts: Dictionary = {}
	var actual := groups.duplicate(true)
	for group in groups:
		for index in group.ids:
			used[index] = true
	if BossRules.abducted(boss_context) >= 0: used[BossRules.abducted(boss_context)] = true
	var leftovers: Array = []
	for index in range(dice.size()):
		if not used.has(index): leftovers.append(index)
	if not leftovers.is_empty():
		actual.append({"ids": leftovers, "category": "Sin combinación"})
	for group in actual:
		var cat: String = group.category
		var category_base: int = BASES[cat]
		var base: int = SERVED.get(cat, category_base) if served else category_base
		var face_points := 0.0
		var own_points := 0.0
		var die_rows: Array = []
		var numbers: Dictionary = {}
		for index in group.ids:
			var die: Dictionary = dice[index]
			var number: int = effective_value(die, group, rules)
			numbers[index] = number
			var shown: Dictionary = die
			if number != die.value:
				shown = die.duplicate()
				shown.value = number
			var additions: Array = []
			var global_bonus: int = global_points.get(str(number), 0)
			if global_bonus > 0:
				additions.append({"source": "number:global:" + str(number), "amount": global_bonus})
			var face_loss: float = number - number * BossRules.face_scale(boss_context, number)
			if face_loss > 0: additions.append({"source": "boss:face:" + str(number), "amount": -face_loss})
			var steel_bonus := 0.0 if BossRules.suspended(boss_context, "material", die.material) else Materials.steel_points(die)
			if steel_bonus > 0:
				additions.append({"source": "material:steel:" + str(die.id), "amount": steel_bonus})
			var element_effect := {} if BossRules.suspended(boss_context, "element", die.get("element", "")) else Elements.evaluate(die, dice, group.ids, cat)
			if not element_effect.is_empty() and element_effect.points > 0:
				additions.append({"source": element_effect.source, "amount": element_effect.points})
			additions.append_array(CoinEffects.die_points(effective_passives, effective_impulses, die, number))
			var shell_effect := Gems.evaluate(die, cat, BossRules.suspended(boss_context, "shell", die.shell))
			var own_factors: Array = []
			if not shell_effect.is_empty() and shell_effect.point_factor != 1.0:
				own_factors.append({"source": shell_effect.source, "amount": shell_effect.point_factor})
			var detail := resolve_die(shown, additions, own_factors)
			if not shell_effect.is_empty(): detail.shell_effect = shell_effect
			if not element_effect.is_empty():
				detail.element_effect = element_effect
			if number != die.value: detail.wildcard = true
			die_rows.append(detail)
			face_points += number
			own_points += detail.points
		var multiplier_additions: Array = []
		var multiplier_factors: Array = []
		var copies: Array = []
		var sticker_effect := {} if BossRules.stickers_suspended(boss_context) else Stickers.evaluate(cat, sticker_levels, sticker_catalog)
		var sticker_points := 0.0
		if not sticker_effect.is_empty():
			sticker_points = sticker_effect.points
			if sticker_effect.multiplier_addition > 0:
				multiplier_additions.append({"source": sticker_effect.source, "amount": sticker_effect.multiplier_addition})
		for detail in die_rows:
			if not detail.has("shell_effect"): continue
			var effect: Dictionary = detail.shell_effect
			if effect.multiplier_addition > 0:
				multiplier_additions.append({"source": effect.source, "amount": effect.multiplier_addition})
			if effect.multiplier_factor != 1.0:
				multiplier_factors.append({"source": effect.source, "amount": effect.multiplier_factor})
			if effect.copies > 0:
				copies.append({"source": effect.source, "amount": effect.copies})
		var coin_points: Array = []
		if cat != "Sin combinación":
			for index in group.ids:
				var copper_bonus := 0.0 if BossRules.suspended(boss_context, "material", dice[index].material) else Materials.copper_multiplier(dice[index])
				var wind_bonus := Elements.wind_multiplier(dice[index])
				if wind_bonus > 0:
					multiplier_additions.append({"source": "element:wind:" + str(dice[index].id), "amount": wind_bonus})
				if copper_bonus > 0:
					multiplier_additions.append({"source": "material:copper:" + str(dice[index].id), "amount": copper_bonus})
				multiplier_additions.append_array(CoinEffects.die_mult(effective_passives, dice[index], numbers[index]))
			multiplier_additions.append_array(CoinEffects.group_mult(effective_passives, cat, rules, context))
			coin_points = CoinEffects.group_points(effective_passives, cat, rules)
			if double_mult: multiplier_factors.append({"source": "consumable:double_mult", "amount": 2.0})
		var repeat_factor := BossRules.repeat_factor(boss_context, cat)
		if repeat_factor != 1.0: multiplier_factors.append({"source": "boss:repeat", "amount": repeat_factor})
		var hand_factor := BossRules.hand_factor(boss_context)
		if hand_factor != 1.0: multiplier_factors.append({"source": "boss:roulette", "amount": hand_factor})
		var row := resolve_group(base, face_points, own_points - face_points + sticker_points + _sum(coin_points), 1.0, multiplier_additions, multiplier_factors, copies)
		if not sticker_effect.is_empty(): row.sticker_effect = sticker_effect
		row.merge({
			"category": cat, "ids": group.ids.duplicate(), "die_rows": die_rows,
			"category_base": category_base, "served_bonus": base - category_base, "coin_points": coin_points
		})
		if not group.get("assigned", {}).is_empty(): row["assigned"] = group.assigned.duplicate()
		rows.append(row)
		if cat not in ["Par", "Doble par", "Sin combinación"]:
			counts[cat] = counts.get(cat, 0) + 1
	# Dados fuera de toda combinación (el abducido no cuenta); lo usa Sobrantes (C57).
	context["leftover_dice"] = leftovers.size()
	for item in CoinEffects.hand_rows(effective_passives, context):
		var flat := resolve_group(0, 0.0, item.points)
		flat.merge({"category": "Moneda · " + COINS[item.source.trim_prefix("coin:")].name, "category_base": 0,
			"served_bonus": 0, "ids": [], "die_rows": [], "source": item.source})
		rows.append(flat)
	# Historical pure-scoring fixtures only: a five-die game cannot repeat trios.
	for cat in counts:
		if counts[cat] > 1:
			var bonus: int = (counts[cat] - 1) * BASES[cat]
			var row := resolve_group(bonus, 0.0, 0.0)
			row.merge({"category": "Repetición · " + cat, "category_base": bonus,
				"served_bonus": 0, "ids": [], "die_rows": []})
			rows.append(row)
	return finish_score(rows, served)

static func reward(cash: int, points: int, target: int, hands_unused: int, base_reward := 8) -> Dictionary:
	# Repair debt never earns negative interest or creates an extra charge.
	var savings := maxi(cash, 0)
	var interest_raw: float = mini(savings, 10) * 0.2 + mini(maxi(savings - 10, 0), 20) * 0.1 + maxi(savings - 30, 0) * 0.05
	var result := {"base": base_reward, "hands": hands_unused * 2, "excess": mini(3, maxi(0, int((points - target) / 10.0))), "interest": int(floor(interest_raw))}
	result.total = result.base + result.hands + result.excess + result.interest
	return result
