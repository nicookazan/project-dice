extends RefCounted
## Pure transaction preparation. Game commits a fully validated plan once.
const Shop = preload("res://scripts/shop.gd")
const Coins = preload("res://scripts/coins.gd")
const Stickers = preload("res://scripts/stickers.gd")
const Numbers = preload("res://scripts/number_upgrades.gd")
const Gems = preload("res://scripts/gems.gd")
const Elements = preload("res://scripts/elements.gd")
const TARGETED = ["material", "shell", "element", "face"]
const KINDS = {"coins": ["coin"], "components": ["material", "shell", "element"], "numbers": ["global", "face"], "stickers": ["sticker", "pack"]}

static func error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message, "cost": 0, "changes": {}}

static func valid_offer(section: String, offer: Dictionary, catalog: Dictionary) -> bool:
	if offer.is_empty() or offer.get("offer_id", "") == "" or offer.get("kind") not in KINDS.get(section, []): return false
	if offer.kind == "pack":
		if not offer.get("effect") is Dictionary: return false
		return not Stickers.offer(offer.effect.get("pack_kind", ""), offer.effect.get("items", []), offer.get("price"), catalog).is_empty()
	var candidate := offer.duplicate(true)
	candidate["weight"] = 1.0
	return Shop.valid_candidate(section, candidate, catalog)

static func prepare(section: String, offer: Dictionary, target: Dictionary, dice: Array,
		globals: Dictionary, levels: Dictionary, catalog: Dictionary, inventory: Dictionary, serial: int, cash: int, unlimited_funds := false) -> Dictionary:
	if not valid_offer(section, offer, catalog): return error("invalid_offer", "La oferta no está disponible o tiene datos inválidos.")
	if not unlimited_funds and (cash < 0 or cash < offer.price): return error("insufficient_funds", "No alcanza la plata para esta compra.")
	var effect: Dictionary = offer.effect
	var updates: Dictionary = {}
	var label: String = offer.kind
	if offer.kind in TARGETED:
		var id = target.get("die_id")
		if dice.size() != 5 or not id is int or id < 0 or id >= dice.size() or dice[id].id != id: return error("invalid_target", "Elegí uno de los cinco dados.")
		var staged: Array = dice.duplicate(true)
		match offer.kind:
			"face":
				if not Numbers.change_face(staged, id, target.get("face_index"), effect.number): return error("invalid_face", "Elegí una cara válida que cambie su número.")
				updates["faces"] = staged[id].faces
				label = "cara %d → %d" % [int(target.face_index) + 1, effect.number]
			"shell":
				updates = {"shell": effect.id, "shell_broken": false}
				label = "carcasa " + Gems.definition(effect.id).name
			"material":
				var counters: Dictionary = dice[id].encounter_effects.duplicate(true)
				counters.erase("steel_points")
				counters.erase("copper_multiplier")
				updates = {"material": effect.id, "encounter_effects": counters}
				label = "material " + ("Acero" if effect.id == "steel" else "Cobre")
			"element":
				var counters: Dictionary = dice[id].hand_effects.duplicate(true)
				counters.erase("earth_points")
				counters.erase("wind_multiplier")
				updates = {"element": effect.id, "hand_effects": counters}
				label = "elemento " + Elements.definition(effect.id).name
		return {"ok": true, "code": "purchased", "cost": offer.price, "changes": {"die_id": id, "die_fields": updates},
			"message": "Dado %d: %s. Pagaste $%d." % [id + 1, label, offer.price]}
	match offer.kind:
		"global":
			var updated: Dictionary = globals.duplicate(true)
			if not Numbers.apply_global(updated, effect.number, effect.amount): return error("invalid_upgrade", "No se pudo aplicar la mejora global.")
			updates["global_points"] = updated
			label = "mejora global +%d al %d" % [effect.amount, effect.number]
		"coin":
			if not Coins.can_store(inventory, effect.coin_id): return error("inventory_full", "No hay espacio o ya tenés esta moneda equipada.")
			var updated: Dictionary = inventory.duplicate(true)
			var data := Coins.definition(effect.coin_id)
			var item := Coins.instance(effect.coin_id, serial + 1)
			if data.type in ["passive", "active"]: updated.equipped.append(item)
			else: updated.consumables.append(item)
			updates = {"coin_inventory": updated, "coin_sequence": serial + 1}
			label = data.name
		"sticker", "pack":
			var ids: Array = [effect.id] if offer.kind == "sticker" else effect.items
			var updated := Stickers.increased(levels, ids, catalog)
			if not updated.valid: return error("invalid_sticker", "Faltan datos válidos para aplicar los stickers.")
			if offer.kind == "pack" and effect.pack_kind == "choose_one":
				updates["pending_pack"] = {"source": "shop", "offer_id": offer.offer_id, "kind": "choose_one", "items": ids.duplicate(), "paid": offer.price}
			else: updates["stickers"] = updated.levels
			label = "paquete de stickers" if offer.kind == "pack" else "sticker " + Stickers.NAMES[effect.id]
	return {"ok": true, "code": "purchased", "cost": offer.price, "changes": updates, "message": "Compraste %s por $%d." % [label, offer.price]}
