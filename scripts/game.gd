extends RefCounted
## Authoritative game state; UI and tests use the same transitions.
const Rules = preload("res://scripts/rules.gd")
const DiceState = preload("res://scripts/dice_state.gd")
const Materials = preload("res://scripts/materials.gd")
const Elements = preload("res://scripts/elements.gd")
const Gems = preload("res://scripts/gems.gd")
const Stickers = preload("res://scripts/stickers.gd")
const Coins = preload("res://scripts/coins.gd")
const CoinEffects = preload("res://scripts/coin_effects.gd")
const Shop = preload("res://scripts/shop.gd")
const Purchases = preload("res://scripts/purchases.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const Campaign = preload("res://scripts/campaign.gd")
const BossCatalog = preload("res://scripts/boss_catalog.gd")
const INITIAL_ROLL := "initial_roll"
const REROLL := "reroll"
const HAND_SCORED := "hand_scored"
const ENCOUNTER_CLOSED := "encounter_closed"
const COIN_BROKEN := "coin_broken"
const BASE_ROLLS := 3
const BASE_HANDS := 2
var rng := RandomNumberGenerator.new()
var run_seed: int
var phase := "play"
var rival := 0
var level_encounters: Array = BossRules.default_encounters()
var boss_rule: Dictionary = BossRules.NONE.duplicate(true)
## Estado propio del jefe (sorteos). Se reinicia al cambiar de encuentro y se guarda tal cual.
var boss_state: Dictionary = {}
## Los jefes sin poder implementado solo se sortean en builds de desarrollo.
var development_bosses: bool = OS.has_feature("debug")
## Solo desarrollo: ids de jefe a forzar al entrar a su nivel (no se guarda; ver Jugar-jefe.cmd).
var forced_boss_ids: Array = []
var campaign: Array = []
var level_index := 0
var selected_bosses: Dictionary = {}
var completed_encounters: Array = []
var cash := 0
var debug_mode := false
var hand := 1
var points := 0
var rolls_left := 3
var rolls_made := 0
var dice: Array = []
var global_points: Dictionary = {}
var cup: Dictionary = {}
var groups: Array = []
var coin_inventory: Dictionary = Coins.empty_inventory()
var coin_instance_sequence := 0
# Compatibility ID views; equipped/stored instances are authoritative.
var passives: Array:
	get: return Coins.ids(coin_inventory.equipped)
	set(value):
		coin_inventory.equipped = []
		for id in value:
			coin_instance_sequence += 1
			coin_inventory.equipped.append(Coins.instance(id, coin_instance_sequence))
		Coins.refresh_capacity(coin_inventory)
var consumable: String:
	get: return coin_inventory.consumables[0].coin_id if not coin_inventory.consumables.is_empty() else ""
	set(value):
		coin_inventory.consumables = []
		if value != "":
			coin_instance_sequence += 1
			coin_inventory.consumables.append(Coins.instance(value, coin_instance_sequence))
# Active impulse coin ids for this encounter; `boost` is the legacy view of the single U01.
var impulses: Array = []
var boost: bool:
	get: return "boost" in impulses
	set(value):
		if value and "boost" not in impulses: impulses.append("boost")
		elif not value: impulses.erase("boost")
var double_mult := false
var free_reroll_tokens := 0
var free_reroll_used := false
var free_renewals := 0
## Etapa de monedas (guardado v9). Bonos de la mano actual: se limpian al anotar y al empezar la mano.
var hand_mult_bonus := 0
var hand_points_bonus := 0
## Descuento de la visita a la tienda (0 = ninguno); se limpia al abrir una visita nueva.
var visit_discount := 0.0
## Escudo de jefe: suspende el poder del jefe durante la mano actual.
var boss_shield_active := false
## Monedas "una vez por partida" que ya aparecieron en una oferta.
var once_coins_seen: Array = []
## Paquete de monedas pagado y pendiente de elegir (vacío si no hay).
var pending_coin_pack: Dictionary = {}
var shop_tables: Dictionary = Shop.default_tables()
var shop_state: Dictionary = {}
var shop_offer_sequence := 0
# Legacy coin ID view for fixtures; canonical stock is shop_state.
var offers: Array:
	get:
		var result: Array = []
		for item in shop_state.get("coins", {}).get("slots", []):
			result.append(item.get("effect", {}).get("coin_id", ""))
		return result
	set(value):
		shop_state = Shop.empty_state()
		shop_state.coins.configured = true
		for i in range(mini(value.size(), 4)):
			if value[i] == "": continue
			shop_offer_sequence += 1
			shop_state.coins.slots[i] = {"offer_id": str(shop_offer_sequence), "kind": "coin", "price": Coins.definition(value[i]).get("price", 0), "effect": {"coin_id": value[i]}}
var reroll_prices: Dictionary = {"coins": 1, "components": 1, "numbers": 1, "stickers": 1}
var last_score: Dictionary = {}
var payout: Dictionary = {}
var history: Array = []
var message := ""
var events: Array = []
var event_sequence := 0
var breakage_by_hand: Dictionary = {}
var repair_resolution: Dictionary = {}
var sticker_catalog: Dictionary = {}
var sticker_offers: Dictionary = {}
var sticker_offer_sequence := 0
var pending_sticker_pack: Dictionary = {}
var pending_purchase: Dictionary = {}
var purchase_receipts: Dictionary = {}
var last_purchase_result: Dictionary = {}

func _init(seed_value: int = -1) -> void:
	restart(seed_value)

func restart(seed_value: int = -1) -> void:
	debug_mode = false
	if seed_value < 0:
		rng.randomize()
		run_seed = int(rng.randi())
	else: run_seed = seed_value
	rng.seed = run_seed
	phase = "play"
	rival = 0
	level_encounters = BossRules.default_encounters()
	boss_rule = BossRules.choose([BossRules.NONE], rng)
	campaign = []
	level_index = 0
	selected_bosses = {}
	completed_encounters = []
	cash = 0
	coin_inventory = Coins.empty_inventory()
	coin_instance_sequence = 0
	shop_tables = Shop.default_tables()
	shop_offer_sequence = 0
	dice = DiceState.create_dice()
	global_points = {}
	cup = {"material": "leather", "stickers": {}}
	sticker_catalog = Stickers.catalog()
	sticker_offers = {}
	sticker_offer_sequence = 0
	pending_sticker_pack = {}
	pending_coin_pack = {}
	once_coins_seen = []
	visit_discount = 0.0
	event_sequence = 0
	_start_encounter()

func _start_encounter() -> void:
	points = 0
	hand = 1
	impulses = []
	free_renewals = 0
	history = []
	payout = {}
	last_score = {}
	shop_state = {}
	reroll_prices = {"coins": 1, "components": 1, "numbers": 1, "stickers": 1}
	events = []
	breakage_by_hand = {}
	repair_resolution = {}
	sticker_offers = {}
	pending_purchase = {}
	purchase_receipts = {}
	last_purchase_result = {}
	for die in dice:
		DiceState.reset_encounter(die)
	_refresh_boss_state()
	start_hand()

func _refresh_boss_state() -> void:
	boss_state = BossRules.draw_state(boss_rule, run_seed, level_index, rival, passives) if is_boss() else {}

func start_hand() -> void:
	# Solo cuentan las monedas que el jefe no suspende (C20 también: una suspendida no da tiradas).
	var active := _active_passives()
	rolls_left = BASE_ROLLS + int(CoinEffects.sum_of(active, "extra_rolls"))
	if hand == 1: rolls_left += int(CoinEffects.sum_of(active, "extra_rolls_first"))
	rolls_made = 0
	double_mult = false
	hand_mult_bonus = 0
	hand_points_bonus = 0
	boss_shield_active = false
	free_reroll_tokens = 0
	free_reroll_used = false
	groups = []
	for die in dice:
		DiceState.reset_hand(die)
	if is_boss() and boss_state.has("die"): boss_state.die = BossRules.draw_hand_die(boss_rule, run_seed, level_index, rival, hand)
	message = "Primera tirada: los cinco dados están en el vaso."

func snapshot() -> Dictionary:
	# Detached plain state. SaveStore validates/encodes/restores it without replaying actions.
	# Keep RNG integers exact; never route them through JSON floating point.
	return {
		"run_seed": run_seed, "rng_state": rng.state,
		"phase": phase, "rival": rival, "cash": cash, "debug_mode": debug_mode,
		"level_encounters": level_encounters, "boss_rule": boss_rule, "boss_state": boss_state,
		"campaign": campaign, "level_index": level_index, "selected_bosses": selected_bosses, "completed_encounters": completed_encounters,
		"hand": hand, "points": points,
		"rolls_left": rolls_left, "rolls_made": rolls_made,
		"dice": dice, "global_points": global_points, "cup": cup,
		"groups": groups, "passives": passives, "consumable": consumable,
		"impulses": impulses, "double_mult": double_mult, "free_reroll_tokens": free_reroll_tokens,
		"free_reroll_used": free_reroll_used, "free_renewals": free_renewals,
		"hand_mult_bonus": hand_mult_bonus, "hand_points_bonus": hand_points_bonus, "visit_discount": visit_discount,
		"boss_shield_active": boss_shield_active, "once_coins_seen": once_coins_seen, "pending_coin_pack": pending_coin_pack,
		"offers": offers, "reroll_prices": reroll_prices,
		"last_score": last_score, "payout": payout, "history": history,
		"message": message, "events": events, "event_sequence": event_sequence,
		"breakage_by_hand": breakage_by_hand, "repair_resolution": repair_resolution,
		"sticker_catalog": sticker_catalog, "sticker_offers": sticker_offers,
		"sticker_offer_sequence": sticker_offer_sequence, "pending_sticker_pack": pending_sticker_pack,
		"coin_inventory": coin_inventory, "coin_instance_sequence": coin_instance_sequence,
		"shop_tables": shop_tables, "shop_state": shop_state, "shop_offer_sequence": shop_offer_sequence,
		"pending_purchase": pending_purchase, "purchase_receipts": purchase_receipts, "last_purchase_result": last_purchase_result
	}.duplicate(true)

func _record_event(type: String, payload: Dictionary) -> Dictionary:
	event_sequence += 1
	var event := {"sequence": event_sequence, "type": type,
		"rival": rival, "hand": hand, "payload": payload.duplicate(true)}
	events.append(event)
	return event.duplicate(true)

func _after_roll(event: Dictionary) -> void:
	if event.type == REROLL:
		var suspended_materials: Array = []
		for id in ["steel", "copper"]:
			if BossRules.suspended(boss_context(), "material", id): suspended_materials.append(id)
		Materials.after_reroll(dice, event.payload.rolled_ids, event.payload.kept_ids, suspended_materials)
		Elements.after_reroll(dice, event.payload.rolled_ids, event.payload.kept_ids)

func _breakage_roll() -> float:
	return rng.randf()

## Equipped passives whose power is not suspended by the current boss rule.
func _active_passives() -> Array:
	var context := boss_context()
	return passives.filter(func(id): return not BossRules.suspended(context, "coin", id))

func active_rules() -> Dictionary:
	return CoinEffects.rules(_active_passives())

## Manos del encuentro: 2 más las de Mano extra (C52) si el jefe no la suspende. No depende de la fase,
## así que vale también al perder y al validar un guardado.
static func hand_limit_of(passive_ids: Array, rule: Dictionary, boss_active: bool, state: Dictionary, current_hand: int) -> int:
	var context := BossRules.context(rule, boss_active, state, current_hand)
	var active: Array = passive_ids.filter(func(id): return not BossRules.suspended(context, "coin", id))
	return BASE_HANDS + int(CoinEffects.sum_of(active, "extra_hands"))

func hand_limit() -> int:
	return hand_limit_of(passives, boss_rule, boss_power_on(), boss_state, hand)

## One builder for preview and scoring, so both always agree. It only reads state.
func coin_context() -> Dictionary:
	var sticker_total := 0
	for level in cup.stickers.values(): sticker_total += int(level)
	return {"hand": hand, "level": level_index + 1, "rolls_made": rolls_made, "rolls_left": rolls_left, "cash": cash,
		"equipped_count": coin_inventory.equipped.size(), "sticker_total": sticker_total,
		"states": Coins.state_of(coin_inventory.equipped), "double_mult": double_mult,
		"hand_mult_bonus": hand_mult_bonus, "hand_points_bonus": hand_points_bonus}

func credit_limit() -> int:
	return int(CoinEffects.sum_of(passives, "credit"))

func offer_price(price: int) -> int:
	return CoinEffects.discounted(price, passives, visit_discount)

func free_reroll_ready() -> bool:
	if rolls_made == 0: return false
	return free_reroll_tokens > 0 or (active_rules().get("free_reroll", false) and not free_reroll_used)

func _wear_coins(dice_rolled: int) -> void:
	# C18-style coins lose strength per rolled die; a suspended coin neither pays nor wears.
	var context := boss_context()
	for item in coin_inventory.equipped.duplicate():
		var def_effects := Coins.effects(item.coin_id)
		for effect in def_effects:
			if effect.kind != "wear" or BossRules.suspended(context, "coin", item.coin_id): continue
			if item.state.get("grace", false): item.state.grace = false
			else: item.state[effect.key] = maxi(int(item.state[effect.key]) - dice_rolled, 0)
			if int(item.state[effect.key]) <= 0:
				coin_inventory.equipped.erase(item)
				Coins.refresh_capacity(coin_inventory)
				_record_event(COIN_BROKEN, {"coin_id": item.coin_id, "instance_id": item.instance_id})
				message = "%s se gastó del todo y se rompió." % Coins.definition(item.coin_id).name

func _after_hand_scored(event: Dictionary) -> void:
	# Commit the guard even for hands with zero eligible shells. Never check copies.
	var key := str(event.hand)
	if breakage_by_hand.has(key): return
	var checks: Array = []
	breakage_by_hand[key] = checks
	var seen: Dictionary = {}
	var tempered := CoinEffects.gem_rule(_active_passives(), "save_first_break")
	for row in event.payload.score.rows:
		if row.get("category", "Sin combinación") == "Sin combinación": continue
		for id in row.get("ids", []):
			if seen.has(id): continue
			seen[id] = true
			var die: Dictionary = dice[id]
			if BossRules.suspended(boss_context(), "shell", die.shell): continue
			if die.shell_broken or not Gems.RISKS.has(die.shell): continue
			var draw := _breakage_roll()
			var risk: float = Gems.RISKS[die.shell]
			die.shell_broken = draw < risk
			var saved := false
			# The draw is always consumed; C46 only turns the first break of each gem into a miss.
			if die.shell_broken and tempered and not die.shell_saved:
				die.shell_broken = false
				die.shell_saved = true
				saved = true
			checks.append({"id": id, "shell": die.shell, "draw": draw, "risk": risk, "broken": die.shell_broken, "saved": saved})

func target() -> int:
	return level_encounters[rival].target

func is_boss(index: int = -1) -> bool:
	return level_encounters[rival if index < 0 else index].kind == "boss"

## Don Cebador se lleva el termo mientras se juega su encuentro (presentación y botón del termo).
func thermos_stolen() -> bool:
	return boss_power_on() and BossRules.is_power(boss_rule, "thermos_theft") and phase in ["play", "hand_result", "lost"]

## El poder del jefe está en juego: hay jefe y el Escudo (U14) no lo apaga en esta mano.
## Toda consulta al poder (`boss_rule`) pasa por acá; la memoria del jefe entre manos no.
func boss_power_on() -> bool:
	return is_boss() and not boss_shield_active

func boss_context() -> Dictionary:
	return BossRules.context(boss_rule, boss_power_on() and phase in ["play", "hand_result"], boss_state, hand)

func has_next_encounter() -> bool:
	return rival + 1 < level_encounters.size() or (not campaign.is_empty() and level_index + 1 < campaign.size())

func begin_campaign(seed_value: int = -1, definitions: Array = []) -> bool:
	var levels := Campaign.prototype() if definitions.is_empty() else definitions
	if not Campaign.valid(levels): return false
	restart(seed_value)
	campaign = levels.duplicate(true)
	_enter_campaign_level()
	return true

func _enter_campaign_level() -> void:
	var level: Dictionary = campaign[level_index]
	var key := str(level_index)
	if not selected_bosses.has(key): selected_bosses[key] = _drawable_candidates(level)[rng.randi_range(0, _drawable_candidates(level).size() - 1)].id
	if development_bosses:
		for forced in forced_boss_ids:
			var forced_row := BossCatalog.entry(forced)
			if not forced_row.is_empty() and forced_row.level == level_index + 1 and Campaign.candidate(level, forced).size() > 0 and selected_bosses[key] != forced:
				selected_bosses[key] = forced
	var chosen := Campaign.candidate(level, selected_bosses[key])
	level_encounters = Campaign.encounters(level, chosen)
	boss_rule = chosen.rule.duplicate(true)
	rival = 0
	_start_encounter()
	phase = "level_intro"
	message = "Campaña de prueba · nivel %d / 7. %s" % [level_index + 1, BossRules.description(boss_rule)]

func _drawable_candidates(level: Dictionary) -> Array:
	## Sin jefes con poder en el nivel (hasta terminar la fase D) se usa el pool completo para no romper la campaña.
	var ready: Array = level.candidates.filter(func(entry): return BossCatalog.playable(entry.id, development_bosses))
	return level.candidates if ready.is_empty() else ready

func environment_id() -> String:
	return "dia" if campaign.is_empty() else campaign[level_index].environment

func boss_name() -> String:
	if campaign.is_empty(): return "Jefe"
	return Campaign.candidate(campaign[level_index], selected_bosses[str(level_index)]).name

func campaign_route() -> Array:
	if campaign.is_empty(): return route()
	var result: Array = []
	for level in range(campaign.size()):
		var key := str(level)
		var chosen: Dictionary = Campaign.candidate(campaign[level], selected_bosses[key]) if selected_bosses.has(key) else {}
		for stop in range(3):
			var id: String = campaign[level].id + "_r%d" % (stop + 1) if stop < 2 else chosen.get("id", campaign[level].id + "_boss")
			var status := "Pendiente"
			if id in completed_encounters: status = "Superado"
			elif level == level_index and stop == rival: status = "Derrota" if phase == "lost" else "Actual"
			result.append({"level": level + 1, "position": stop + 1, "status": status, "name": "Rival %d" % (stop + 1) if stop < 2 else (chosen.get("name", "Dios" if level == 6 else "Jefe sin sortear")), "target": campaign[level].targets[stop] if stop < 2 else chosen.get("target", 0), "rule": chosen.get("rule", {}).get("name", "Se anuncia al entrar al nivel") if stop == 2 else "Sin regla especial"})
	return result

func begin_run(seed_value: int = -1, encounters: Array = [], candidates: Array = []) -> bool:
	var plan := BossRules.default_encounters() if encounters.is_empty() else encounters
	var pool: Array = [BossRules.NONE] if candidates.is_empty() else candidates
	if not BossRules.valid_encounters(plan) or not BossRules.valid_pool(pool): return false
	restart(seed_value)
	level_encounters = plan.duplicate(true)
	boss_rule = BossRules.choose(pool, rng)
	_refresh_boss_state()
	phase = "level_intro"
	message = "Nivel de prueba: 40 → 70 → 110. " + BossRules.description(boss_rule)
	return true

func begin_level() -> bool:
	if phase != "level_intro": return false
	phase = "play"
	message = "Primera tirada: los cinco dados están en el vaso."
	return true

func return_to_menu() -> void:
	restart()
	phase = "menu"
	message = ""

func route() -> Array:
	# A detached read-only projection; it cannot select or skip encounters.
	var result: Array = []
	for i in range(level_encounters.size()):
		var status := "Pendiente"
		if i < rival or phase == "won": status = "Superado"
		elif i == rival:
			status = "Derrota" if phase == "lost" else "Actual"
			if phase in ["reward", "repair", "shop", "purchase_target", "sticker_choice"]: status = "Superado"
		result.append({"index": i, "name": "Jefe" if is_boss(i) else "Rival %d" % (i + 1), "target": level_encounters[i].target, "status": status, "rule": boss_rule.name if is_boss(i) else "Sin regla especial"})
	return result

func is_grouped(index: int) -> bool:
	for group in groups:
		if index in group.ids: return true
	return false

func lock_groups() -> void:
	for group in groups: group.locked = true

func move_die(index: int, zone: String) -> bool:
	if index < 0 or index >= dice.size(): return false
	if phase != "play" or rolls_made == 0 or is_grouped(index): return false
	if zone not in ["cup", "reserve"]: return false
	if _boss_blocks_move(index, zone): return false
	if zone == "cup":
		if rolls_left <= 0 and not free_reroll_ready():
			message = "No quedan tiradas; anotá la mano o usá una moneda de tirada extra."
			return false
		lock_groups()
	dice[index].zone = zone
	return true

## Poderes de dados que impiden mover un dado marcado.
func _boss_blocks_move(index: int, zone: String) -> bool:
	if not boss_power_on() or int(boss_state.get("die", -1)) != index: return false
	if BossRules.is_power(boss_rule, "abduction"):
		message = "Ese dado fue abducido y no se puede mover."
		return true
	if BossRules.is_power(boss_rule, "loaded_die") and zone == "cup":
		message = "El dado cargado queda fijo en 1: no se relanza."
		return true
	if BossRules.is_power(boss_rule, "scared_die") and zone == "reserve" and rolls_made in [1, 2]:
		message = "El dado asustado no se puede conservar en las dos primeras tiradas."
		return true
	return false

func _set_face(id: int, number: int, results: Array) -> bool:
	var die: Dictionary = dice[id]
	var index: int = die.faces.find(number)
	if index < 0: return false
	die.face_index = index
	die.value = number
	for entry in results:
		if entry.id == id:
			entry.face_index = index
			entry.number = number
	return true

## Efectos de dados de los jefes tras tirar. Los sorteos propios usan un generador aparte: el azar principal no cambia.
func _apply_boss_roll(rolled_ids: Array, results: Array) -> void:
	if not boss_power_on() or boss_rule.get("kind") != "boss_power": return
	var marked := int(boss_state.get("die", -1))
	match boss_rule.target:
		"loaded_die":
			if marked in rolled_ids: _set_face(marked, 1, results)
		"scared_die":
			if marked >= 0 and rolls_made in [1, 2]: dice[marked].zone = "cup"
		"shadow":
			if rolls_made == 1:
				var top := 0
				for die in dice:
					if die.value > dice[top].value: top = die.id
				_set_face(top, 1, results)
		"mirror_face":
			var candidates := rolled_ids.duplicate()
			candidates.sort()
			var generator := RandomNumberGenerator.new()
			generator.seed = ("%d:%d:%d:%d:%d:mirror" % [run_seed, level_index, rival, hand, rolls_made]).hash()
			var chosen: int = candidates[generator.randi_range(0, candidates.size() - 1)]
			_set_face(chosen, 7 - int(dice[chosen].value), results)

## Marcas visibles para la interfaz: dado -> clase de poder.
func boss_marks() -> Dictionary:
	var marked := int(boss_state.get("die", -1))
	if not boss_power_on() or marked < 0: return {}
	var kinds := {"scared_die": "scared", "loaded_die": "loaded", "abduction": "abducted"}
	return {marked: kinds.get(boss_rule.get("target", ""), "")} if kinds.has(boss_rule.get("target", "")) else {}

func roll() -> bool:
	if phase != "play": return false
	var rolled_ids: Array = []
	var kept_ids: Array = []
	for die in dice:
		if die.zone == "cup": rolled_ids.append(die.id)
		else: kept_ids.append(die.id)
	# A single-die reroll is free when a free-reroll source is available (C27 first, then U08).
	var free := rolled_ids.size() == 1 and free_reroll_ready()
	if rolls_left <= 0 and not free: return false
	if rolled_ids.is_empty():
		message = "Elegí al menos un dado para el vaso. No se gastó ninguna tirada."
		return false
	if rolls_made > 0 and boss_power_on() and BossRules.is_power(boss_rule, "ring_charge") and rolled_ids.size() < 2:
		message = "La carga del anillo solo deja conservar tres dados: mandá al menos dos al vaso."
		return false
	lock_groups()
	_throw(rolled_ids, kept_ids, "free" if free else "paid")
	return true

## Dado que un jefe deja fijo (abducido o cargado) y que ni Relanzo total ni Voltear dado tocan. -1 si no hay.
func fixed_die() -> int:
	if not boss_power_on() or not (BossRules.is_power(boss_rule, "abduction") or BossRules.is_power(boss_rule, "loaded_die")): return -1
	return int(boss_state.get("die", -1))

## Tira los dados de `rolled_ids`. `mode`: "paid" gasta una tirada, "free" es un relanzo libre y "total" es Relanzo total (U09).
func _throw(rolled_ids: Array, kept_ids: Array, mode: String) -> void:
	var free := mode == "free"
	var initial := rolls_made == 0
	var results: Array = []
	for die in dice:
		if die.zone == "cup":
			die.face_index = rng.randi_range(0, die.faces.size() - 1)
			die.value = DiceState.number_on_face(die, die.face_index)
			die.zone = "reserve"
			results.append({"id": die.id, "face_index": die.face_index, "number": die.value})
	rolls_made += 1
	_apply_boss_roll(rolled_ids, results)
	if free:
		# The roll still counts as made (the hand stops being served) but costs no budget.
		if active_rules().get("free_reroll", false) and not free_reroll_used: free_reroll_used = true
		else: free_reroll_tokens -= 1
		message = "Relanzo libre: no gastó tirada."
	elif mode == "total":
		message = "Relanzo total: los grupos se deshicieron y no se gastó tirada."
	else:
		rolls_left -= 1
		message = "Seleccioná dados para armar un grupo, reservarlos o enviarlos al vaso."
	var event := _record_event(INITIAL_ROLL if initial else REROLL,
		{"rolled_ids": rolled_ids, "kept_ids": kept_ids, "results": results, "roll_number": rolls_made, "free": free or mode == "total"})
	_after_roll(event)
	_wear_coins(rolled_ids.size())

func form_group(ids: Array) -> bool:
	if phase != "play" or rolls_made == 0 or ids.is_empty(): return false
	var unique: Dictionary = {}
	for index in ids:
		if not index is int or index < 0 or index >= dice.size() or unique.has(index) or is_grouped(index) or dice[index].zone != "reserve": return false
		unique[index] = true
	if BossRules.abducted(boss_context()) in ids:
		message = "Ese dado fue abducido y no cuenta esta mano."
		return false
	var rules := active_rules()
	var resolved := Rules.resolve_wildcards(dice, ids, rules)
	var cat: String = resolved.category
	if cat.is_empty():
		message = "La selección exacta no forma una combinación. Podés dejarla como sobrantes."
		return false
	if BossRules.forbidden(boss_context(), cat):
		message = BossRules.forbid_message(boss_context(), cat)
		return false
	var candidate := {"ids": ids.duplicate(), "category": cat, "locked": false}
	if not resolved.assigned.is_empty(): candidate["assigned"] = resolved.assigned
	if not Rules.validate_groups(dice, groups + [candidate], rules).is_empty(): return false
	groups.append(candidate)
	message = cat + " armado. Se bloquea cuando envíes otros dados al vaso."
	return true

func ungroup(index: int) -> bool:
	if phase != "play" or index < 0 or index >= groups.size() or groups[index].locked: return false
	groups.remove_at(index)
	message = "Grupo desarmado."
	return true

func preview() -> Dictionary:
	if rolls_made == 0: return Rules.finish_score([], false)
	var calculation := Rules.score(dice, groups, passives, impulses, rolls_made == 1, global_points, cup.stickers, sticker_catalog, boss_context(), coin_context())
	if debug_mode and calculation.valid:
		var bonus: int = maxi(0, target() - points - calculation.total)
		if bonus > 0:
			var row := Rules.resolve_group(0, 0, bonus)
			row.merge({"category": "DEBUG · Daño infinito", "ids": [], "die_rows": []})
			calculation.rows.append(row)
			calculation = Rules.finish_score(calculation.rows, calculation.served)
	return calculation

func can_afford(cost: int) -> bool:
	# C19 lets the balance fall to -credit; with no credit this is the old cash >= cost >= 0.
	return debug_mode or (cash - cost >= -credit_limit() and cost >= 0)

# Legacy explicit sticker operations for domain fixtures. Shop purchases use source=shop.
func register_sticker_offer(kind: String, ids: Array, price: Variant) -> String:
	if phase != "shop" or not pending_sticker_pack.is_empty(): return ""
	var data := Stickers.offer(kind, ids, price, sticker_catalog)
	if data.is_empty(): return ""
	sticker_offer_sequence += 1
	var id := str(sticker_offer_sequence)
	sticker_offers[id] = data
	return id

func inspect_sticker_offer(id: String) -> Dictionary:
	return sticker_offers.get(id, {}).duplicate(true)

func buy_sticker_offer(id: String) -> bool:
	if phase != "shop" or not pending_sticker_pack.is_empty() or not sticker_offers.has(id): return false
	var data: Dictionary = sticker_offers[id]
	if data.purchased or not can_afford(data.price) or Stickers.offer(data.kind, data.items, data.price, sticker_catalog).is_empty(): return false
	var upgraded := Stickers.increased(cup.stickers, data.items, sticker_catalog)
	if not upgraded.valid: return false
	if not debug_mode: cash -= data.price
	data.purchased = true
	if data.kind == "choose_one":
		pending_sticker_pack = {"offer_id": id, "kind": data.kind, "items": data.items.duplicate(), "paid": data.price}
		phase = "sticker_choice"
	else:
		cup.stickers = upgraded.levels
	return true

func choose_sticker(id: String) -> bool:
	if phase != "sticker_choice" or pending_sticker_pack.is_empty() or id not in pending_sticker_pack.items: return false
	var upgraded := Stickers.increased(cup.stickers, [id], sticker_catalog)
	if not upgraded.valid: return false
	cup.stickers = upgraded.levels
	if pending_sticker_pack.get("source", "") == "shop":
		purchase_receipts[pending_sticker_pack.offer_id]["selected"] = [id]
	else: sticker_offers[pending_sticker_pack.offer_id]["selected"] = [id]
	pending_sticker_pack = {}
	phase = "shop"
	return true

func score_hand() -> bool:
	if phase != "play" or rolls_made == 0: return false
	# Dice in the cup still have their last rolled results if the player ends early.
	var calculation := preview()
	if not calculation.valid:
		message = "La mano contiene un grupo inválido; revisá los dados seleccionados."
		return false
	last_score = calculation
	points += last_score.total
	history.append({"hand": hand, "score": last_score.duplicate(true), "accumulated": points})
	if is_boss(): boss_state = BossRules.after_hand(boss_rule, boss_state, last_score, hand)
	phase = "hand_result"
	message = "Mano anotada en azul."
	var event := _record_event(HAND_SCORED, {"score": last_score, "accumulated": points})
	_after_hand_scored(event)
	var combined := false
	for row in last_score.rows:
		if not row.get("ids", []).is_empty() and row.category != "Sin combinación": combined = true
	Coins.advance(coin_inventory.equipped, "hand_scored")
	Coins.advance(coin_inventory.equipped, "hand_combo" if combined else "hand_plain")
	double_mult = false
	hand_mult_bonus = 0
	hand_points_bonus = 0
	_collect_kiosk_tax()
	boss_shield_active = false # El Escudo (U14) vale una sola mano; la memoria del jefe ya se registró arriba.
	if points < target() and hand >= hand_limit():
		phase = "lost"
		impulses = []
		message = "Se terminaron las manos. El azar se queda con esta."
	return true

## Impuesto al kiosco: $2 por anotación, sin dejar saldo negativo por el cobro.
func _collect_kiosk_tax() -> void:
	if not boss_power_on() or not BossRules.is_power(boss_rule, "kiosk_tax"): return
	var charge := mini(2, maxi(cash, 0))
	cash -= charge
	boss_state.tax = int(boss_state.get("tax", 0)) + charge
	message = "Mano anotada en azul. Impuesto al kiosco: −$%d." % charge

func next_hand() -> bool:
	if phase != "hand_result" or hand >= hand_limit(): return false
	hand += 1
	phase = "play"
	start_hand()
	return true

func close_encounter() -> bool:
	if phase != "hand_result" or points < target(): return false
	var cash_before := cash
	var base_reward: int = Campaign.NORMAL_REWARD
	if not campaign.is_empty() and is_boss(): base_reward = Campaign.candidate(campaign[level_index], selected_bosses[str(level_index)]).base_reward
	payout = Rules.reward(cash, points, target(), hand_limit() - hand, base_reward)
	# Cobrador (C54): suma aparte del cobro base, solo si el jefe no la suspende (el cierre ocurre en hand_result).
	var collected := int(CoinEffects.sum_of(_active_passives(), "encounter_cash"))
	if collected > 0:
		payout["coins"] = collected
		payout.total += collected
	cash += payout.total
	impulses = []
	Coins.advance(coin_inventory.equipped, "encounter_won")
	if is_boss(): Coins.advance(coin_inventory.equipped, "boss_won")
	if not campaign.is_empty(): completed_encounters.append(level_encounters[rival].id)
	phase = "reward" if has_next_encounter() else "won"
	var broken_ids: Array = []
	for die in dice:
		if die.shell_broken and Gems.REPAIR_COSTS.has(die.shell): broken_ids.append(die.id)
	repair_resolution = {"status": "pending" if not broken_ids.is_empty() else "not_needed",
		"available_ids": broken_ids, "selected_ids": [], "cost": 0,
		"cash_after_reward": cash, "next_phase": phase}
	if not broken_ids.is_empty(): phase = "repair"
	message = "Nivel completado." if phase == "won" else "Encuentro ganado. Cobro acreditado una sola vez."
	_record_event(ENCOUNTER_CLOSED, {"points": points, "target": target(),
		"reward": payout, "cash_before": cash_before, "cash_after": cash})
	return true

func repair_quote(ids: Array) -> Dictionary:
	return Gems.repair_quote(dice, ids, {"half": CoinEffects.gem_rule(passives, "repair_half"), "free_one": repair_resolution.get("free_one", false)})

func resolve_repairs(ids: Array) -> bool:
	if phase != "repair" or repair_resolution.get("status", "") != "pending": return false
	for id in ids:
		if not id is int or id not in repair_resolution.available_ids: return false
	var quote := repair_quote(ids)
	if not quote.valid: return false
	for item in quote.items: dice[item.id].shell_broken = false
	if not debug_mode: cash -= quote.cost
	repair_resolution.status = "declined" if ids.is_empty() else "repaired"
	repair_resolution.selected_ids = ids.duplicate()
	repair_resolution.cost = quote.cost
	repair_resolution["cash_after"] = cash
	phase = repair_resolution.next_phase
	message = "Continuás sin reparar." if ids.is_empty() else "Carcasas reparadas por $%d." % quote.cost
	return true

func _generated_shop() -> Dictionary:
	var state := Shop.empty_state()
	var staged_rng: int = rng.state
	var serial: int = shop_offer_sequence
	var seen: Array = once_coins_seen.duplicate()
	for section in ["coins", "components", "numbers", "stickers"]:
		var generated := Shop.generate(section, shop_tables, sticker_catalog, passives, staged_rng, serial, seen)
		if not generated.valid: return {"valid": false}
		state[section] = generated.section
		staged_rng = generated.rng_state
		serial = generated.sequence
		seen = generated.once_seen
	return {"valid": true, "state": state, "rng_state": staged_rng, "sequence": serial, "once_seen": seen}

func open_shop() -> bool:
	if phase != "reward": return false
	var generated := _generated_shop()
	if not generated.valid: return false
	shop_state = generated.state
	rng.state = generated.rng_state
	shop_offer_sequence = generated.sequence
	once_coins_seen = generated.once_seen
	phase = "shop"
	impulses = []
	visit_discount = 0.0
	reroll_prices = {"coins": 1, "components": 1, "numbers": 1, "stickers": 1}
	free_renewals = int(CoinEffects.sum_of(passives, "free_renewals"))
	return true

func generate_offers() -> bool:
	# Initial generation only. Renewals must use the paid per-section operation.
	if phase != "shop" or not shop_state.is_empty(): return false
	var generated := _generated_shop()
	if not generated.valid: return false
	shop_state = generated.state
	rng.state = generated.rng_state
	shop_offer_sequence = generated.sequence
	once_coins_seen = generated.once_seen
	return true

func inspect_shop_offer(section: String, id: String) -> Dictionary:
	for offer in shop_state.get(section, {}).get("slots", []):
		if offer.get("offer_id", "") == id: return offer.duplicate(true)
	return {}

func renewal_price(section: String) -> int:
	# A free renewal (C21/U06) costs nothing; otherwise the section counter, with C45 discount.
	if free_renewals > 0: return 0
	return offer_price(reroll_prices.get(section, 1))

func refresh_shop(section: String = "coins") -> bool:
	var price := renewal_price(section)
	if phase != "shop" or not can_afford(price) or not shop_state.has(section) or not reroll_prices.has(section): return false
	var generated := Shop.generate(section, shop_tables, sticker_catalog, passives, rng.state, shop_offer_sequence, once_coins_seen)
	if not generated.valid or not generated.section.configured: return false
	if free_renewals > 0: free_renewals -= 1
	else:
		if not debug_mode: cash -= price
		reroll_prices[section] += 1
	shop_state[section] = generated.section
	rng.state = generated.rng_state
	shop_offer_sequence = generated.sequence
	once_coins_seen = generated.once_seen
	message = "Sección renovada."
	return true

func commit_shop_offer(section: String, id: String) -> bool:
	# Stock boundary used by an already validated purchase commit.
	if phase != "shop" or id == "": return false
	var slots: Array = shop_state.get(section, {}).get("slots", [])
	for i in range(slots.size()):
		if slots[i].get("offer_id", "") == id:
			slots[i] = {}
			return true
	return false

func _purchase_plan(section: String, offer: Dictionary, target: Dictionary) -> Dictionary:
	var price: int = offer_price(offer.get("price", 0)) if offer.get("price") is int else -1
	return Purchases.prepare(section, offer, target, dice, global_points, cup.stickers, sticker_catalog, coin_inventory, coin_instance_sequence, cash, debug_mode, credit_limit(), price)

func begin_purchase(section: String, id: String) -> Dictionary:
	if phase != "shop" or not pending_sticker_pack.is_empty(): return Purchases.error("invalid_context", "Terminá la acción pendiente antes de comprar.")
	var offer := inspect_shop_offer(section, id)
	if not Purchases.valid_offer(section, offer, sticker_catalog): return Purchases.error("invalid_offer", "La oferta ya no está disponible.")
	if offer.kind not in Purchases.TARGETED: return purchase_offer(section, id)
	if not can_afford(offer_price(offer.price)): return Purchases.error("insufficient_funds", "No alcanza la plata para esta compra.")
	pending_purchase = {"section": section, "offer_id": id, "offer": offer, "target": {}}
	phase = "purchase_target"
	return {"ok": true, "code": "target_required", "message": "Elegí el dado" + (" y la cara." if offer.kind == "face" else "."), "cost": offer_price(offer.price)}

func set_purchase_target(target: Dictionary) -> bool:
	if phase != "purchase_target": return false
	var id = target.get("die_id")
	if not id is int or id < 0 or id >= dice.size(): return false
	if target.has("face_index") and (not target.face_index is int or target.face_index < 0 or target.face_index >= 6): return false
	pending_purchase.target = target.duplicate(true)
	return true

func purchase_preview() -> Dictionary:
	if phase != "purchase_target" or pending_purchase.is_empty(): return Purchases.error("invalid_context", "No hay una compra pendiente.")
	var offer := inspect_shop_offer(pending_purchase.section, pending_purchase.offer_id)
	if offer != pending_purchase.offer: return Purchases.error("stale_offer", "La oferta cambió; cancelá y elegila de nuevo.")
	return _purchase_plan(pending_purchase.section, offer, pending_purchase.target)

func cancel_purchase() -> bool:
	if phase != "purchase_target": return false
	pending_purchase = {}
	phase = "shop"
	return true

func confirm_purchase() -> Dictionary:
	var plan := purchase_preview()
	if not plan.ok: return plan
	return _commit_purchase(pending_purchase.section, pending_purchase.offer, plan)

func purchase_offer(section: String, id: String) -> Dictionary:
	if phase != "shop" or not pending_sticker_pack.is_empty(): return Purchases.error("invalid_context", "Terminá la acción pendiente antes de comprar.")
	var offer := inspect_shop_offer(section, id)
	var plan := _purchase_plan(section, offer, {})
	if not plan.ok: return plan
	return _commit_purchase(section, offer, plan)

func _commit_purchase(section: String, offer: Dictionary, plan: Dictionary) -> Dictionary:
	# No awaits: validation, effect, payment and stock consumption form one commit.
	var updates: Dictionary = plan.changes
	if updates.has("die_fields"): dice[updates.die_id].merge(updates.die_fields.duplicate(true), true)
	if updates.has("global_points"): global_points = updates.global_points
	if updates.has("coin_inventory"):
		coin_inventory = updates.coin_inventory
		coin_instance_sequence = updates.coin_sequence
	if updates.has("stickers"): cup.stickers = updates.stickers
	if not debug_mode: cash -= plan.cost
	phase = "shop"
	commit_shop_offer(section, offer.offer_id)
	if section == "coins": shop_state = Shop.clean_passive_offers(shop_state, passives)
	purchase_receipts[offer.offer_id] = {"section": section, "offer": offer.duplicate(true), "target": pending_purchase.get("target", {}).duplicate(true), "paid": plan.cost}
	pending_purchase = {}
	if updates.has("pending_pack"):
		pending_sticker_pack = updates.pending_pack.duplicate(true)
		phase = "sticker_choice"
	message = plan.message
	last_purchase_result = plan.duplicate(true)
	return plan.duplicate(true)

func buy(slot: int, expected_offer_id: String = "") -> bool:
	if phase != "shop" or slot < 0 or slot >= offers.size(): return false
	var offer: Dictionary = shop_state.coins.slots[slot]
	if offer.is_empty() or offer.get("kind") != "coin": return false
	if expected_offer_id != "" and offer.offer_id != expected_offer_id: return false
	return purchase_offer("coins", offer.offer_id).ok

func sell(coin: String) -> bool:
	if phase != "shop": return false
	var data := Coins.definition(coin)
	if data.is_empty(): return false
	if coin in passives:
		if not Coins.can_remove(coin_inventory, coin):
			message = "No podés vender esta moneda: quedarían más monedas que ranuras."
			return false
		coin_inventory.equipped.remove_at(passives.find(coin))
		Coins.refresh_capacity(coin_inventory)
	elif coin in Coins.ids(coin_inventory.consumables):
		coin_inventory.consumables.remove_at(Coins.ids(coin_inventory.consumables).find(coin))
	else: return false
	cash += data.resale
	message = "Moneda vendida."
	return true

func leave_shop() -> bool:
	if phase != "shop" or not has_next_encounter(): return false
	return _advance_encounter()

func skip_shop() -> bool:
	if phase != "reward" or not has_next_encounter(): return false
	return _advance_encounter()

func _advance_encounter() -> bool:
	if rival == level_encounters.size() - 1:
		level_index += 1
		_enter_campaign_level()
		return true
	rival += 1
	phase = "play"
	_start_encounter()
	return true

## `target` es el dado elegido para las monedas que lo piden (Voltear dado); las demás lo ignoran.
func use_consumable(index: int = 0, target: int = -1) -> bool:
	if index < 0 or index >= coin_inventory.consumables.size(): return false
	var id: String = coin_inventory.consumables[index].coin_id
	if not Coins.can_use(id, phase): return false
	if BossRules.suspended(boss_context(), "coin", id): return false
	var data := Coins.definition(id)
	var effect: Dictionary = data.effects[0]
	match effect.kind:
		"use_reroll_all":
			if phase != "play" or rolls_made == 0: return false
			var fixed := fixed_die()
			var rolled_ids: Array = []
			var kept_ids: Array = []
			for die in dice:
				if die.id == fixed: kept_ids.append(die.id)
				else: rolled_ids.append(die.id)
			groups = []
			for die_id in rolled_ids: dice[die_id].zone = "cup"
			_throw(rolled_ids, kept_ids, "total")
		"use_flip_die":
			if target < 0 or target >= dice.size() or rolls_made == 0 or is_grouped(target) or target == fixed_die():
				message = "Ese dado no se puede voltear: tiene que estar suelto, ya tirado y no fijado por un jefe."
				return false
			var flipped: Dictionary = dice[target]
			flipped.face_index = flipped.faces.size() - 1 - int(flipped.face_index)
			flipped.value = DiceState.number_on_face(flipped, flipped.face_index)
			message = "Dado %d: pasó a la cara opuesta (%d)." % [target + 1, flipped.value]
		"use_boss_shield":
			if not is_boss() or boss_shield_active: return false
			boss_shield_active = true
			message = "Escudo de jefe: el poder de %s queda apagado esta mano." % boss_rule.get("name", "el jefe")
		"impulse":
			if id not in impulses: impulses.append(id)
			var shown: Array = effect.numbers.map(func(n): return str(n))
			var listed: String = shown[0] if shown.size() == 1 else ", ".join(shown.slice(0, shown.size() - 1)) + " y " + shown[shown.size() - 1]
			message = "Impulso activo: cada %s suma +%d hasta terminar este encuentro." % [listed, effect.amount]
		"use_extra_roll":
			rolls_left += int(effect.amount)
			message = "Una tirada adicional disponible en esta mano." if int(effect.amount) == 1 else "%d tiradas adicionales disponibles en esta mano." % int(effect.amount)
		"use_hand_mult":
			hand_mult_bonus += int(effect.amount)
			message = "Mult +%d activo: se suma al multiplicador de cada combinación de esta mano." % int(effect.amount)
		"use_hand_points":
			hand_points_bonus += int(effect.amount)
			message = "Bolsa de puntos: +%d puntos planos en esta mano." % int(effect.amount)
		"use_cash":
			cash += int(effect.amount)
			message = "Plata rápida: +$%d." % int(effect.amount)
		"use_visit_discount":
			if visit_discount > 0.0: return false
			visit_discount = float(effect.amount)
			message = "Descuento de visita activo: -%d %% hasta salir de la tienda." % int(round(float(effect.amount) * 100.0))
		"use_repair_all":
			if phase != "repair" or repair_resolution.get("status", "") != "pending": return false
			var fixed: Array = repair_resolution.available_ids.duplicate()
			for die_id in fixed: dice[die_id].shell_broken = false
			repair_resolution.status = "repaired"
			repair_resolution.selected_ids = fixed
			repair_resolution.cost = 0
			repair_resolution["cash_after"] = cash
			phase = repair_resolution.next_phase
			message = "Reparar todas: carcasas reparadas gratis."
		"use_double_mult":
			if double_mult: return false
			double_mult = true
			message = "Doble mult activo: el multiplicador de cada combinación de esta mano se duplica."
		"use_free_renewal":
			free_renewals += 1
			message = "Tenés una renovación gratis disponible en esta visita."
		"use_repair_free":
			if repair_resolution.get("free_one", false): return false
			repair_resolution["free_one"] = true
			message = "La gema más cara que repares sale gratis."
		"use_free_reroll":
			free_reroll_tokens += 1
			message = "Relanzo libre: tu próximo relanzo de un solo dado no gasta tirada."
		_: return false
	coin_inventory.consumables.remove_at(index)
	return true
