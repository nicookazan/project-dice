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
const BossRules = preload("res://scripts/boss_rules.gd")
const COINS = Coins.DATA
const PASSIVES = Coins.PASSIVES
const CONSUMABLES = Coins.CONSUMABLES

static func category(values: Array) -> String:
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
	return ""

static func validate_groups(dice: Array, groups: Array) -> Array:
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
			values.append(dice[id].value)
		var detected := category(values)
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

static func score(dice: Array, groups: Array, passives: Array, boost: bool, served: bool, global_points: Dictionary = {}, sticker_levels: Dictionary = {}, sticker_catalog: Dictionary = {}, boss_context: Dictionary = {}) -> Dictionary:
	var errors := validate_groups(dice, groups)
	if not boss_context.is_empty() and not BossRules.valid_rule(boss_context): errors.append("Regla de jefe inválida.")
	for group in groups:
		if group is Dictionary and BossRules.forbidden(boss_context, group.get("category", "")): errors.append("El jefe prohíbe " + group.category + ".")
	if not Stickers.valid_levels(sticker_levels, sticker_catalog):
		errors.append("Sticker sin datos de nivel o balance válidos.")
	if not NumberUpgrades.valid_points(global_points):
		errors.append("Mejoras globales inválidas.")
	for coin in passives:
		if coin not in PASSIVES:
			errors.append("Moneda pasiva desconocida.")
	if not errors.is_empty():
		return finish_score([], served, errors)
	var effective_passives: Array = passives.filter(func(id): return not BossRules.suspended(boss_context, "coin", id))
	var effective_boost: bool = boost and not BossRules.suspended(boss_context, "coin", "boost")
	var rows: Array = []
	var used: Dictionary = {}
	var counts: Dictionary = {}
	var actual := groups.duplicate(true)
	for group in groups:
		for index in group.ids:
			used[index] = true
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
		for index in group.ids:
			var die: Dictionary = dice[index]
			var number: int = die.value
			var additions: Array = []
			var global_bonus: int = global_points.get(str(number), 0)
			if global_bonus > 0:
				additions.append({"source": "number:global:" + str(number), "amount": global_bonus})
			var steel_bonus := 0.0 if BossRules.suspended(boss_context, "material", die.material) else Materials.steel_points(die)
			if steel_bonus > 0:
				additions.append({"source": "material:steel:" + str(die.id), "amount": steel_bonus})
			var element_effect := Elements.evaluate(die, dice, group.ids, cat)
			if not element_effect.is_empty() and element_effect.points > 0:
				additions.append({"source": element_effect.source, "amount": element_effect.points})
			additions.append_array(Coins.point_additions(number, effective_passives, effective_boost))
			var shell_effect := Gems.evaluate(die, cat, BossRules.suspended(boss_context, "shell", die.shell))
			var own_factors: Array = []
			if not shell_effect.is_empty() and shell_effect.point_factor != 1.0:
				own_factors.append({"source": shell_effect.source, "amount": shell_effect.point_factor})
			var detail := resolve_die(die, additions, own_factors)
			if not shell_effect.is_empty(): detail.shell_effect = shell_effect
			if not element_effect.is_empty():
				detail.element_effect = element_effect
			die_rows.append(detail)
			face_points += number
			own_points += detail.points
		var multiplier_additions: Array = []
		var multiplier_factors: Array = []
		var copies: Array = []
		var sticker_effect := Stickers.evaluate(cat, sticker_levels, sticker_catalog)
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
		if cat != "Sin combinación":
			for index in group.ids:
				var copper_bonus := 0.0 if BossRules.suspended(boss_context, "material", dice[index].material) else Materials.copper_multiplier(dice[index])
				var wind_bonus := Elements.wind_multiplier(dice[index])
				if wind_bonus > 0:
					multiplier_additions.append({"source": "element:wind:" + str(dice[index].id), "amount": wind_bonus})
				if copper_bonus > 0:
					multiplier_additions.append({"source": "material:copper:" + str(dice[index].id), "amount": copper_bonus})
		for coin in effective_passives:
			if COINS[coin].get("category", "") == cat:
				multiplier_additions.append({"source": "coin:" + coin, "amount": float(Coins.definition(coin).amount)})
		var row := resolve_group(base, face_points, own_points - face_points + sticker_points, 1.0, multiplier_additions, multiplier_factors, copies)
		if not sticker_effect.is_empty(): row.sticker_effect = sticker_effect
		row.merge({
			"category": cat, "ids": group.ids.duplicate(), "die_rows": die_rows,
			"category_base": category_base, "served_bonus": base - category_base
		})
		rows.append(row)
		if cat not in ["Par", "Doble par", "Sin combinación"]:
			counts[cat] = counts.get(cat, 0) + 1
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
