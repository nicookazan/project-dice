extends RefCounted
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/rules.gd")
const Coins = preload("res://scripts/coins.gd")
const Shop = preload("res://scripts/shop.gd")
const Stickers = preload("res://scripts/stickers.gd")
const Numbers = preload("res://scripts/number_upgrades.gd")
const Purchases = preload("res://scripts/purchases.gd")
const PHASES = ["level_intro", "play", "hand_result", "reward", "repair", "shop", "purchase_target", "sticker_choice", "won", "lost"]
const BossRules = preload("res://scripts/boss_rules.gd")
const Campaign = preload("res://scripts/campaign.gd")

static func plain(value: Variant, depth := 0) -> bool:
	if depth > 28: return false
	if value == null or value is bool or value is int: return true
	if value is float: return is_finite(value)
	if value is String or value is StringName: return str(value).length() <= 100000
	if value is Array:
		if value.size() > 10000: return false
		for item in value:
			if not plain(item, depth + 1): return false
		return true
	if value is Dictionary:
		if value.size() > 10000: return false
		for key in value:
			if not (key is String or key is StringName or key is int) or not plain(value[key], depth + 1): return false
		return true
	return false

static func ids(value: Variant) -> bool:
	if not value is Array or value.size() > 5: return false
	var seen: Array = []
	for id in value:
		if not id is int or id < 0 or id > 4 or id in seen: return false
		seen.append(id)
	return true

static func score(value: Dictionary) -> bool:
	if not value.get("total") is int or not value.get("rows") is Array or not value.get("served") is bool or not value.get("valid") is bool: return false
	for row in value.rows:
		if not row is Dictionary or not row.get("category") is String or not ids(row.get("ids")) or not row.get("die_rows") is Array: return false
		for key in ["base", "dice", "added", "subtotal", "multiplier", "original_total", "total", "copy_count", "multiplier_base", "multiplier_sum"]:
			if not (row.get(key) is int or row.get(key) is float): return false
		for key in ["multiplier_additions", "multiplier_factors", "copies"]:
			if not entries(row.get(key)): return false
		for die in row.die_rows:
			if not die is Dictionary or not die.get("id") is int or die.id < 0 or die.id > 4 or not die.get("number") is int or die.number < 1 or die.number > 6: return false
			for key in ["base_points", "points"]:
				if not (die.get(key) is int or die.get(key) is float): return false
			if not entries(die.get("point_additions")) or not entries(die.get("point_factors")): return false
			for key in ["element_effect", "shell_effect"]:
				if die.has(key):
					var effect = die[key]
					if not effect is Dictionary or not effect.get("name") is String or not effect.get("active") is bool or not effect.get("reason") is String: return false
		if row.has("sticker_effect"):
			var sticker = row.sticker_effect
			if not sticker is Dictionary or not sticker.get("name") is String or not sticker.get("level") is int or not (sticker.get("points") is int or sticker.get("points") is float): return false
	return true

static func entries(value: Variant) -> bool:
	if not value is Array: return false
	for entry in value:
		if not entry is Dictionary or not entry.get("source") is String or not (entry.get("amount") is int or entry.get("amount") is float): return false
	return true

static func validate(data: Variant) -> String:
	if not data is Dictionary or not plain(data) or not data.get("game") is Dictionary or not data.get("ui") is Dictionary: return "estructura incompleta"
	var g: Dictionary = data.game
	var template: Dictionary = Game.new(0).snapshot()
	if g.size() != template.size(): return "campos de partida incompletos"
	for key in template:
		if not g.has(key) or typeof(g[key]) != typeof(template[key]): return "tipo inválido: " + key
	if not BossRules.valid_encounters(g.level_encounters) or not BossRules.valid_rule(g.boss_rule): return "definición de jefe o recorrido inválida"
	if g.phase not in PHASES or g.rival < 0 or g.rival >= g.level_encounters.size() or g.hand not in [1, 2] or g.points < 0 or g.rolls_left < 0 or g.rolls_left > 100 or g.rolls_made < 0 or g.rolls_made > 100: return "fase o contadores fuera de rango"
	if not Campaign.valid_progress(g): return "progreso de campaña inconsistente"
	for key in ["event_sequence", "coin_instance_sequence", "shop_offer_sequence", "sticker_offer_sequence"]:
		if g[key] < 0: return "secuencia negativa"
	if g.reroll_prices.size() != 4: return "contadores de renovación incompletos"
	for section in ["coins", "components", "numbers", "stickers"]:
		if not g.reroll_prices.get(section) is int or g.reroll_prices[section] < 1: return "contador de renovación inválido"
	if g.dice.size() != 5 or not Numbers.valid_points(g.global_points): return "dados o mejoras inválidos"
	if g.cup.get("material") != "leather" or not g.cup.get("stickers") is Dictionary or not Stickers.valid_levels(g.cup.stickers, g.sticker_catalog): return "vaso inválido"
	for i in range(5):
		var die = g.dice[i]
		if not die is Dictionary: return "dado inválido"
		var base: Dictionary = preload("res://scripts/dice_state.gd").create_die(i)
		for key in base:
			if not die.has(key) or typeof(die[key]) != typeof(base[key]): return "campos de dado inválidos"
		if die.id != i or die.faces.size() != 6 or die.material not in ["basic", "steel", "copper"] or die.shell not in ["", "emerald", "sapphire", "ruby", "diamond"] or die.element not in ["", "fire", "water", "electricity", "earth", "wind"] or die.zone not in ["cup", "reserve"]: return "identidad o componente de dado inválido"
		for face in die.faces:
			if not face is int or face < 1 or face > 6: return "cara inválida"
		if die.has("local_points"): return "mecánica numérica anterior sin migrar"
		if g.rolls_made == 0:
			if die.face_index != -1 or die.value != 0: return "resultado antes de tirar"
		else:
			if die.face_index < 0 or die.face_index >= 6 or die.value < 1 or die.value > 6: return "resultado o índice de cara inválido"
			# In the shop, a purchased face can replace the last rolled position.
			# Keep its historic result/blue score; new faces apply to future rolls.
			if g.phase not in ["shop", "purchase_target", "sticker_choice"] and die.value != die.faces[die.face_index]: return "resultado y cara no coinciden"
		for effects in [die.encounter_effects, die.hand_effects]:
			for key in effects:
				if not key is String or not (effects[key] is int or effects[key] is float) or effects[key] < 0: return "efecto inválido"
	if g.rolls_made == 0 and not g.groups.is_empty(): return "grupos antes de tirar"
	for group in g.groups:
		if not group is Dictionary or not ids(group.get("ids")) or not group.get("category") is String or not group.get("locked") is bool: return "grupo inválido"
	if not g.groups.is_empty() and not Rules.validate_groups(g.dice, g.groups).is_empty(): return "agrupación inconsistente"
	if g.level_encounters[g.rival].kind == "boss":
		for group in g.groups:
			if BossRules.forbidden(g.boss_rule, group.category): return "categoría prohibida por jefe"
	var inventory: Dictionary = g.coin_inventory
	if inventory.get("shared_capacity") != 5 or inventory.get("consumable_capacity") != 1 or not inventory.get("equipped") is Array or not inventory.get("consumables") is Array or inventory.equipped.size() > 5 or inventory.consumables.size() > 1: return "inventario inválido"
	var instances: Array = []
	var equipped: Array = []
	for list in [inventory.equipped, inventory.consumables]:
		for coin in list:
			if not coin is Dictionary or not coin.get("instance_id") is int or not coin.get("coin_id") is String or not coin.get("state") is Dictionary: return "instancia de moneda inválida"
			var def: Dictionary = Coins.definition(coin.coin_id)
			if def.is_empty() or coin.instance_id < 1 or coin.instance_id > g.coin_instance_sequence or coin.instance_id in instances: return "identidad de moneda inválida"
			instances.append(coin.instance_id)
			if list == inventory.equipped:
				if def.type != "passive" or coin.coin_id in equipped: return "moneda equipada inválida"
				equipped.append(coin.coin_id)
			elif def.type != "consumable": return "moneda de un uso inválida"
	if g.passives != equipped or g.consumable != (inventory.consumables[0].coin_id if not inventory.consumables.is_empty() else ""): return "vistas de inventario inconsistentes"
	if not g.last_score.is_empty() and not score(g.last_score): return "resultado incompleto"
	if g.phase in ["hand_result", "reward", "repair", "won", "lost"] and g.last_score.is_empty(): return "falta resultado anotado"
	if g.phase in ["reward", "repair", "won", "shop", "purchase_target", "sticker_choice"] and g.points < g.level_encounters[g.rival].target: return "cobro sin objetivo cumplido"
	var has_next: bool = g.rival + 1 < g.level_encounters.size() or (not g.campaign.is_empty() and g.level_index + 1 < g.campaign.size())
	if (g.phase == "won" and has_next) or (g.phase == "reward" and not has_next) or (g.phase == "lost" and (g.hand != 2 or g.points >= g.level_encounters[g.rival].target)): return "final inconsistente"
	if g.phase in ["reward", "repair", "won", "shop", "purchase_target", "sticker_choice"]:
		for key in ["base", "hands", "excess", "interest", "total"]:
			if not g.payout.get(key) is int: return "cobro incompleto"
	if not g.shop_state.is_empty():
		var offer_ids: Array = []
		for section in Shop.SIZES:
			var stock = g.shop_state.get(section)
			if not stock is Dictionary or not stock.get("slots") is Array or not stock.get("configured") is bool or stock.slots.size() != Shop.SIZES[section]: return "stock incompleto"
			for offer in stock.slots:
				if not offer is Dictionary: return "oferta inválida"
				if offer.is_empty(): continue
				if not offer.get("offer_id") is String or offer.offer_id in offer_ids or not Purchases.valid_offer(section, offer, g.sticker_catalog): return "oferta inconsistente"
				offer_ids.append(offer.offer_id)
	if g.phase in ["shop", "purchase_target", "sticker_choice"] and g.shop_state.is_empty(): return "falta tienda"
	if g.phase == "purchase_target":
		var p: Dictionary = g.pending_purchase
		if not p.get("section") is String or not p.get("offer_id") is String or not p.get("offer") is Dictionary or not p.get("target") is Dictionary or not g.shop_state.has(p.section): return "compra pendiente incompleta"
		var found := false
		for offer in g.shop_state[p.section].slots:
			if offer == p.offer: found = true
		if not found or p.offer.get("offer_id") != p.offer_id: return "compra pendiente sin oferta"
		if p.target.has("die_id") and (not p.target.die_id is int or p.target.die_id < 0 or p.target.die_id > 4): return "dado objetivo inválido"
		if p.target.has("face_index") and (not p.target.face_index is int or p.target.face_index < 0 or p.target.face_index > 5): return "cara objetivo inválida"
	if g.phase == "sticker_choice":
		var p: Dictionary = g.pending_sticker_pack
		if not p.get("items") is Array or p.items.size() != 3 or not p.get("paid") is int or p.get("kind") != "choose_one" or not p.get("offer_id") is String: return "paquete pendiente inválido"
		if Stickers.offer("choose_one", p.items, p.paid, g.sticker_catalog).is_empty(): return "candidatos de paquete inválidos"
		var receipts: Dictionary = g.purchase_receipts if p.get("source") == "shop" else g.sticker_offers
		if not receipts.get(p.offer_id) is Dictionary: return "paquete sin recibo"
	if g.phase == "repair":
		var r: Dictionary = g.repair_resolution
		if r.get("status") != "pending" or not ids(r.get("available_ids")) or r.available_ids.is_empty() or r.get("next_phase") not in ["reward", "won"]: return "reparación pendiente inválida"
		if r.next_phase != ("reward" if has_next else "won"): return "destino de reparación inconsistente"
		for id in r.available_ids:
			if not g.dice[id].shell_broken or g.dice[id].shell == "": return "carcasa de reparación inválida"
	var ui: Dictionary = data.ui
	if not ids(ui.get("selected")) or not ids(ui.get("repair_selection")) or ui.get("shop_section") not in ["coins", "components", "numbers", "stickers"] or not ui.get("pack_panel_open") is bool: return "selección de interfaz inválida"
	for id in ui.repair_selection:
		if g.phase != "repair" or id not in g.repair_resolution.available_ids: return "selección de reparación inconsistente"
	return ""
