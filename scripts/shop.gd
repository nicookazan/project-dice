extends RefCounted
## Stored offers, weighted generation and atomic RNG staging. No rendering or purchases.
const Coins = preload("res://scripts/coins.gd")
const Stickers = preload("res://scripts/stickers.gd")
const Gems = preload("res://scripts/gems.gd")
const Elements = preload("res://scripts/elements.gd")
const Numbers = preload("res://scripts/number_upgrades.gd")
const SIZES = {"coins": 4, "components": 2, "numbers": 2, "stickers": 2, "cup": 0}

static func default_tables() -> Dictionary:
	var coins: Array = []
	for id in Coins.catalog():
		coins.append({"kind": "coin", "price": Coins.definition(id).price, "weight": 1.0, "effect": {"coin_id": id}})
	return {"coins": coins, "components": [], "numbers": [], "stickers": [], "numeric_rarity_weights": {}}

static func empty_state() -> Dictionary:
	var result: Dictionary = {}
	for section in SIZES:
		var slots: Array = []
		for index in range(SIZES[section]): slots.append({})
		result[section] = {"slots": slots, "configured": false}
	return result

static func positive(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value > 0

static func valid_candidate(section: String, data: Variant, stickers: Dictionary) -> bool:
	if not data is Dictionary or not positive(data.get("weight")) or not data.get("price") is int or data.price < 0 or not data.get("effect") is Dictionary: return false
	var effect: Dictionary = data.effect
	match section:
		"coins": return data.get("kind") == "coin" and not Coins.definition(effect.get("coin_id", "")).is_empty()
		"components":
			match data.get("kind"):
				"material": return effect.get("id") in ["steel", "copper"]
				"shell": return not Gems.definition(effect.get("id", "")).is_empty() and effect.get("intact") == true
				"element": return not Elements.definition(effect.get("id", "")).is_empty()
		"numbers":
			if not Numbers.GLOBAL_RANGES.has(data.get("rarity")) or not Numbers.valid_number(effect.get("number")): return false
			if data.get("kind") == "face": return true
			if data.get("kind") == "global": return Numbers.global_offer(effect.number, effect.get("amount"), data.rarity, data.price).valid
		"stickers":
			if data.get("kind") == "sticker": return not Stickers.offer("single", [effect.get("id")], data.price, stickers).is_empty()
			if data.get("kind") == "pack":
				var count: int = {"choose_one": 3, "receive_two": 2}.get(effect.get("pack_kind"), 0)
				if count == 0 or not effect.get("pool") is Array or effect.pool.size() < count: return false
				var seen: Dictionary = {}
				for id in effect.pool:
					if not id is String or seen.has(id) or not Stickers.defined(id, stickers): return false
					seen[id] = true
				return true
	return false

static func pick(pool: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total := 0.0
	for item in pool: total += float(item.weight)
	var draw := rng.randf() * total
	for item in pool:
		draw -= float(item.weight)
		if draw < 0: return item.duplicate(true)
	return pool[-1].duplicate(true)

static func generate(section: String, tables: Dictionary, stickers: Dictionary, owned: Array,
		rng_state: int, sequence: int) -> Dictionary:
	if section not in SIZES or section == "cup": return {"valid": false}
	var source = tables.get(section, [])
	if not source is Array: return {"valid": false}
	var pool: Array = []
	for data in source:
		if not valid_candidate(section, data, stickers): return {"valid": false}
		if section == "coins" and data.effect.coin_id in Coins.PASSIVES and data.effect.coin_id in owned: continue
		pool.append(data)
	var result: Dictionary = empty_state()[section]
	if pool.is_empty(): return {"valid": true, "section": result, "rng_state": rng_state, "sequence": sequence}
	var rarities: Array = []
	if section == "numbers":
		var weights = tables.get("numeric_rarity_weights", {})
		if not weights is Dictionary or weights.is_empty(): return {"valid": false}
		for rarity in weights:
			if not Numbers.GLOBAL_RANGES.has(rarity) or not positive(weights[rarity]): return {"valid": false}
			var matching: Array = pool.filter(func(item): return item.rarity == rarity)
			if matching.is_empty(): return {"valid": false}
			rarities.append({"rarity": rarity, "weight": weights[rarity]})
	if section == "stickers":
		for kind in ["sticker", "pack"]:
			if pool.filter(func(item): return item.kind == kind).is_empty(): return {"valid": false}
	var rng := RandomNumberGenerator.new()
	rng.state = rng_state
	for index in range(SIZES[section]):
		if pool.is_empty(): break
		var eligible: Array = pool
		if section == "numbers":
			var rarity: String = pick(rarities, rng).rarity
			eligible = pool.filter(func(item): return item.rarity == rarity)
		elif section == "stickers":
			var kind := "sticker" if index == 0 else "pack"
			eligible = pool.filter(func(item): return item.kind == kind)
		var offer := pick(eligible, rng)
		if section == "coins" and offer.effect.coin_id in Coins.PASSIVES:
			var chosen_id: String = offer.effect.coin_id
			pool = pool.filter(func(item): return item.effect.coin_id != chosen_id)
		offer.erase("weight")
		if offer.kind == "pack":
			var candidates: Array = offer.effect.pool.duplicate()
			var items: Array = []
			for count in range(3 if offer.effect.pack_kind == "choose_one" else 2):
				var selected := rng.randi_range(0, candidates.size() - 1)
				items.append(candidates.pop_at(selected))
			offer.effect.erase("pool")
			offer.effect["items"] = items
		sequence += 1
		offer["offer_id"] = str(sequence)
		result.slots[index] = offer
	result.configured = true
	return {"valid": true, "section": result, "rng_state": rng.state, "sequence": sequence}

static func clean_passive_offers(state: Dictionary, owned: Array) -> Dictionary:
	var cleaned := state.duplicate(true)
	if not cleaned.has("coins"): return cleaned
	var seen := owned.duplicate()
	for index in range(cleaned.coins.slots.size()):
		var offer: Dictionary = cleaned.coins.slots[index]
		var id: String = offer.get("effect", {}).get("coin_id", "")
		if id not in Coins.PASSIVES: continue
		if id in seen: cleaned.coins.slots[index] = {}
		else: seen.append(id)
	return cleaned
