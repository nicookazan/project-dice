extends RefCounted
## Stored offers, weighted generation and atomic RNG staging. No rendering or purchases.
const Coins = preload("res://scripts/coins.gd")
const Stickers = preload("res://scripts/stickers.gd")
const Gems = preload("res://scripts/gems.gd")
const Elements = preload("res://scripts/elements.gd")
const Numbers = preload("res://scripts/number_upgrades.gd")
const SIZES = {"coins": 4, "components": 2, "numbers": 2, "stickers": 2, "cup": 0}
## Tamaños del paquete de monedas (D15): se muestran `shown`, se eligen `picks` y el grande trae al menos 2 pasivas.
const COIN_PACK_SIZES = {"small": {"shown": 2, "picks": 1, "min_passives": 0}, "large": {"shown": 5, "picks": 2, "min_passives": 2}}

static func default_tables() -> Dictionary:
	var coins: Array = []
	for id in Coins.catalog():
		coins.append({"kind": "coin", "price": Coins.definition(id).price, "weight": 1.0, "effect": {"coin_id": id}})
	return {"coins": coins, "components": [], "numbers": [], "stickers": [], "numeric_rarity_weights": {},
		"coin_type_weights": {"passive": 75.0, "consumable": 25.0},
		"coin_packs": coin_pack_table(),
		"coin_rarity_weights": {"passive": {"common": 60.0, "rare": 28.0, "epic": 9.0, "legendary": 3.0}, "consumable": {"common": 70.0, "rare": 25.0, "epic": 5.0}}}

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

static func valid_weights(weights: Variant) -> bool:
	if not weights is Dictionary or weights.is_empty(): return false
	for key in weights:
		if not positive(weights[key]): return false
	return true

## Stage one: coin type (passive / single use). Stage two: rarity. Stage three: uniform coin.
## Empty stages are dropped (renormalized); a stage with one option consumes no randomness.
static func staged_coin_pool(pool: Array, tables: Dictionary, rng: RandomNumberGenerator) -> Array:
	var type_weights: Dictionary = tables.coin_type_weights
	var types: Array = []
	for type in type_weights:
		if not pool.filter(func(item): return Coins.definition(item.effect.coin_id).type == type).is_empty():
			types.append({"type": type, "weight": type_weights[type]})
	if types.is_empty(): return pool
	var chosen_type: String = types[0].type if types.size() == 1 else pick(types, rng).type
	var of_type: Array = pool.filter(func(item): return Coins.definition(item.effect.coin_id).type == chosen_type)
	var rarity_weights: Dictionary = tables.get("coin_rarity_weights", {}).get(chosen_type, {})
	var rarities: Array = []
	for rarity in rarity_weights:
		if not of_type.filter(func(item): return Coins.rarity_of(item.effect.coin_id) == rarity).is_empty():
			rarities.append({"rarity": rarity, "weight": rarity_weights[rarity]})
	if rarities.is_empty(): return of_type
	var chosen_rarity: String = rarities[0].rarity if rarities.size() == 1 else pick(rarities, rng).rarity
	return of_type.filter(func(item): return Coins.rarity_of(item.effect.coin_id) == chosen_rarity)

static func generate(section: String, tables: Dictionary, stickers: Dictionary, owned: Array,
		rng_state: int, sequence: int, once_seen: Array = []) -> Dictionary:
	if section not in SIZES or section == "cup": return {"valid": false}
	var source = tables.get(section, [])
	if not source is Array: return {"valid": false}
	# Monedas de una vez por partida: las ya generadas antes no vuelven; las de esta tanda se suman a `once_seen`.
	var seen: Array = once_seen.duplicate()
	var pool: Array = []
	for data in source:
		if not valid_candidate(section, data, stickers): return {"valid": false}
		if section == "coins" and data.effect.coin_id in Coins.PASSIVES and data.effect.coin_id in owned: continue
		if section == "coins" and Coins.once_per_run(data.effect.coin_id) and data.effect.coin_id in seen: continue
		pool.append(data)
	var result: Dictionary = empty_state()[section]
	if pool.is_empty(): return {"valid": true, "section": result, "rng_state": rng_state, "sequence": sequence, "once_seen": seen}
	var staged: bool = section == "coins" and tables.get("coin_type_weights") is Dictionary and not tables.coin_type_weights.is_empty()
	if staged and (not valid_weights(tables.coin_type_weights) or not tables.get("coin_rarity_weights") is Dictionary): return {"valid": false}
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
	# El cuarto espacio de monedas es un paquete cuando existe la tabla `coin_packs`; sin ella son cuatro monedas sueltas.
	var pack_table = tables.get("coin_packs", [])
	if section == "coins" and (not pack_table is Array or not pack_table.all(func(entry): return valid_coin_pack_entry(entry))): return {"valid": false}
	var with_pack: bool = section == "coins" and not pack_table.is_empty()
	var rng := RandomNumberGenerator.new()
	rng.state = rng_state
	for index in range(SIZES[section] - (1 if with_pack else 0)):
		if pool.is_empty(): break
		var eligible: Array = pool
		if section == "numbers":
			var rarity: String = pick(rarities, rng).rarity
			eligible = pool.filter(func(item): return item.rarity == rarity)
		elif staged:
			eligible = staged_coin_pool(pool, tables, rng)
		elif section == "stickers":
			var kind := "sticker" if index == 0 else "pack"
			eligible = pool.filter(func(item): return item.kind == kind)
		var offer := pick(eligible, rng)
		if section == "coins" and (offer.effect.coin_id in Coins.PASSIVES or Coins.once_per_run(offer.effect.coin_id)):
			var chosen_id: String = offer.effect.coin_id
			pool = pool.filter(func(item): return item.effect.coin_id != chosen_id)
			if Coins.once_per_run(chosen_id) and chosen_id not in seen: seen.append(chosen_id)
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
	if with_pack:
		var pack := _draw_coin_pack(pool, pack_table, tables, staged, rng, seen)
		if not pack.is_empty():
			sequence += 1
			pack["offer_id"] = str(sequence)
			result.slots[SIZES[section] - 1] = pack
	result.configured = true
	return {"valid": true, "section": result, "rng_state": rng.state, "sequence": sequence, "once_seen": seen}

## Una fila de `coin_packs`: tamaño, cuántas monedas se muestran, cuántas se eligen y precio.
static func valid_coin_pack_entry(entry: Variant) -> bool:
	if not entry is Dictionary or entry.get("kind") != "coin_pack" or not positive(entry.get("weight")) or not entry.get("price") is int or entry.price < 0: return false
	var effect = entry.get("effect")
	if not effect is Dictionary or effect.get("size") not in COIN_PACK_SIZES: return false
	return effect.get("shown") == COIN_PACK_SIZES[effect.size].shown and effect.get("picks") == COIN_PACK_SIZES[effect.size].picks

static func coin_pack_table() -> Array:
	return [
		{"kind": "coin_pack", "price": 7, "weight": 65.0, "effect": {"size": "small", "shown": 2, "picks": 1}},
		{"kind": "coin_pack", "price": 14, "weight": 35.0, "effect": {"size": "large", "shown": 5, "picks": 2}}]

## Oferta ya generada: contenido guardado, sin repetidos y con el mínimo de pasivas del tamaño.
static func valid_coin_pack_offer(offer: Variant) -> bool:
	if not offer is Dictionary or offer.get("kind") != "coin_pack" or not offer.get("price") is int or offer.price < 0 or not offer.get("effect") is Dictionary: return false
	var effect: Dictionary = offer.effect
	if effect.get("size") not in COIN_PACK_SIZES or effect.get("picks") != COIN_PACK_SIZES[effect.size].picks or not effect.get("items") is Array: return false
	var items: Array = effect.items
	if items.size() != COIN_PACK_SIZES[effect.size].shown: return false
	var seen: Array = []
	var passives := 0
	for id in items:
		if not id is String or id in seen or Coins.definition(id).is_empty(): return false
		seen.append(id)
		if Coins.definition(id).type == "passive": passives += 1
	return passives >= COIN_PACK_SIZES[effect.size].min_passives

## Sortea el paquete con las mismas etapas (tipo, rareza, moneda) que las sueltas. `pool` ya no trae las pasivas propias
## ni las sueltas de esta visita. Vacío si no alcanzan las monedas para cumplir el tamaño.
static func _draw_coin_pack(pool: Array, pack_table: Array, tables: Dictionary, staged: bool, rng: RandomNumberGenerator, seen: Array) -> Dictionary:
	var entry := pick(pack_table, rng)
	var rules: Dictionary = COIN_PACK_SIZES[entry.effect.size]
	var available := pool.duplicate()
	var items: Array = []
	for n in range(rules.shown):
		var source: Array = available
		if n < rules.min_passives: source = available.filter(func(item): return item.effect.coin_id in Coins.PASSIVES)
		if source.is_empty(): return {}
		var eligible: Array = staged_coin_pool(source, tables, rng) if staged else source
		var chosen: String = pick(eligible, rng).effect.coin_id
		available = available.filter(func(item): return item.effect.coin_id != chosen)
		items.append(chosen)
		if Coins.once_per_run(chosen) and chosen not in seen: seen.append(chosen)
	# Mezcla para que las pasivas obligatorias no queden siempre primero.
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = items[i]
		items[i] = items[j]
		items[j] = swap
	return {"kind": "coin_pack", "price": entry.price, "effect": {"size": entry.effect.size, "picks": rules.picks, "items": items}}

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
