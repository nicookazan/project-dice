extends RefCounted
## Pure evaluation of the declarative `effects` in coins.gd. No state, no randomness.
const Coins = preload("res://scripts/coins.gd")

static func _each(ids: Array, kinds: Array) -> Array:
	var result: Array = []
	for id in ids:
		for effect in Coins.effects(id):
			if effect.kind in kinds: result.append({"id": id, "effect": effect})
	return result

static func matches(filter: Dictionary, die: Dictionary, number: int) -> bool:
	if filter.has("parity") and number % 2 != (0 if filter.parity == "even" else 1): return false
	if filter.has("numbers") and number not in filter.numbers: return false
	if filter.has("material") and die.get("material", "") not in filter.material: return false
	if filter.get("element", "") == "any" and die.get("element", "") == "": return false
	if filter.get("shell", "") == "any" and die.get("shell", "") == "": return false
	return true

static func die_points(equipped: Array, impulses: Array, die: Dictionary, number: int) -> Array:
	var result: Array = []
	for item in _each(equipped, ["die_points_if"]):
		if matches(item.effect.filter, die, number):
			result.append({"source": "coin:" + item.id, "amount": float(item.effect.amount)})
	for item in _each(impulses, ["impulse"]):
		if number in item.effect.numbers:
			result.append({"source": "consumable:" + item.id, "amount": float(item.effect.amount)})
	return result

static func die_mult(equipped: Array, die: Dictionary, number: int) -> Array:
	# Dice-level multiplier additions only count for dice inside a combination.
	var result: Array = []
	for item in _each(equipped, ["die_mult_if"]):
		if matches(item.effect.filter, die, number):
			result.append({"source": "coin:" + item.id, "amount": float(item.effect.amount)})
	return result

static func categories_for(category: String, rules: Dictionary) -> Array:
	return [category, "Doble par"] if category == "Par" and rules.get("pair_double", false) else [category]

static func group_points(equipped: Array, category: String, rules: Dictionary) -> Array:
	var result: Array = []
	var names := categories_for(category, rules)
	for item in _each(equipped, ["category_points"]):
		for name in names:
			if name in item.effect.categories:
				result.append({"source": "coin:" + item.id, "amount": float(item.effect.amount)})
				break
	return result

static func scale(per: String, context: Dictionary) -> float:
	match per:
		"sticker_levels": return float(context.get("sticker_total", 0))
		"equipped": return float(context.get("equipped_count", 0))
	return 0.0

static func group_mult(equipped: Array, category: String, rules: Dictionary, context: Dictionary) -> Array:
	var result: Array = []
	var names := categories_for(category, rules)
	for item in _each(equipped, ["category_mult", "flat_group_mult", "cond_mult", "scaled_mult", "state_mult"]):
		var effect: Dictionary = item.effect
		var amount := 0.0
		match effect.kind:
			"category_mult":
				for name in names:
					if name in effect.categories:
						amount = float(effect.amount)
						break
			"flat_group_mult": amount = float(effect.amount)
			"cond_mult":
				var active: bool = (effect.when == "first_roll" and context.get("rolls_made", 0) == 1) or (effect.when == "second_hand" and context.get("hand", 1) == 2)
				if active: amount = float(effect.amount)
			"scaled_mult": amount = scale(effect.per, context) * float(effect.amount)
			"state_mult": amount = float(context.get("states", {}).get(item.id, {}).get(effect.key, 0)) * float(effect.amount)
		if amount > 0: result.append({"source": "coin:" + item.id, "amount": amount})
	return result

static func hand_rows(equipped: Array, context: Dictionary) -> Array:
	# Flat hand points: one row each, outside any multiplier.
	var result: Array = []
	for item in _each(equipped, ["hand_points"]):
		var effect: Dictionary = item.effect
		var points := 0.0
		match effect.per:
			"unused_rolls": points = float(context.get("rolls_left", 0)) * effect.amount
			"last_roll": points = float(effect.amount) if context.get("rolls_left", 1) == 0 and context.get("rolls_made", 0) > 0 else 0.0
			"cash_fifth": points = float(int(maxi(context.get("cash", 0), 0) / 5)) * effect.amount
			"state": points = float(context.get("states", {}).get(item.id, {}).get(effect.key, 0)) * effect.amount
		if points > 0: result.append({"source": "coin:" + item.id, "points": points})
	return result

static func rules(equipped: Array) -> Dictionary:
	var result: Dictionary = {}
	for item in _each(equipped, ["rule"]): result[item.effect.rule] = true
	return result

static func sum_of(equipped: Array, kind: String, key := "amount") -> float:
	var total := 0.0
	for item in _each(equipped, [kind]): total += float(item.effect.get(key, 0))
	return total

static func gem_rule(equipped: Array, rule: String) -> bool:
	for item in _each(equipped, ["gem"]):
		if item.effect.rule == rule: return true
	return false

static func discounted(price: int, equipped: Array) -> int:
	var rate := minf(sum_of(equipped, "discount"), 0.9)
	return price if rate <= 0 else int(floor(price * (1.0 - rate) + 0.5))
