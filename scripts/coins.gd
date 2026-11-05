extends RefCounted
## Data-driven coin catalog. Powers are declarative `effects` evaluated by coin_effects.gd;
## adding a coin means adding a row here, never a branch in rules.gd or game.gd.
const PASSIVES = [
	"full", "straight", "generala", "poker", "even", "odd",
	"pair_mult", "twopair_mult", "trio_mult",
	"pair_pts", "twopair_pts", "trio_pts", "straight_pts", "full_pts", "poker_pts", "generala_pts",
	"flat_mult", "spent", "gold", "extra_roll_perm", "free_renewal",
	"metal", "elemental", "gems", "straight4", "wildcard", "free_reroll", "pair_double",
	"num_1", "num_2", "num_3", "num_4", "num_5", "num_6", "sixes",
	"first_roll", "unused_rolls", "last_roll", "second_hand", "thermos", "collection", "interest",
	"pocket", "pocket_small", "discount", "tempered_gem", "jeweler",
	"veteran", "accumulated", "streak", "bosshunter",
	"reserve_roll", "collector", "level_veteran", "served", "leftovers", "extra_hand"]
const CONSUMABLES = ["boost", "roll", "boost_25", "boost_36", "double_mult", "free_renewal_use", "repair_gem", "free_reroll_use"]
const RARITIES = ["common", "rare", "epic", "legendary"]
const RARITY_NAMES = {"common": "Común", "rare": "Rara", "epic": "Épica", "legendary": "Legendaria"}
## [price, resale] by rarity.
const PASSIVE_PRICES = {"common": [4, 2], "rare": [6, 3], "epic": [9, 4], "legendary": [14, 7]}
const CONSUMABLE_PRICES = {"common": [2, 1], "rare": [3, 1], "epic": [5, 2]}
const EVENTS = ["hand_scored", "hand_combo", "hand_plain", "encounter_won", "boss_won"]
const BASE_SHARED := 5
const BASE_CONSUMABLE := 1
const SHORT = {
	"pair_mult": "P+", "twopair_mult": "DP+", "trio_mult": "T+",
	"pair_pts": "P", "twopair_pts": "DP", "trio_pts": "T", "straight_pts": "E", "full_pts": "F", "poker_pts": "PK", "generala_pts": "G",
	"flat_mult": "+1x", "spent": "40", "gold": "$", "extra_roll_perm": "+T", "free_renewal": "R0",
	"metal": "Me", "elemental": "El", "gems": "Ge", "straight4": "E4", "wildcard": "?1", "free_reroll": "R1", "pair_double": "P2",
	"num_1": "1", "num_2": "2", "num_3": "3", "num_4": "4", "num_5": "5", "num_6": "6", "sixes": "6x",
	"first_roll": "1T", "unused_rolls": "TS", "last_roll": "UT", "second_hand": "M2", "thermos": "Te", "collection": "Co", "interest": "In",
	"pocket": "B+", "pocket_small": "b+", "discount": "-%", "tempered_gem": "GT", "jeweler": "Jo",
	"veteran": "Ve", "accumulated": "Ac", "streak": "Ra", "bosshunter": "Cz",
	"reserve_roll": "TR", "collector": "Cb", "level_veteran": "VN", "served": "Sv", "leftovers": "So", "extra_hand": "M3",
	"boost_25": "25", "boost_36": "36", "double_mult": "x2", "free_renewal_use": "R0", "repair_gem": "Rp", "free_reroll_use": "R1"}

## Per coin: code, name, description, rarity, family, effects (+ optional overrides).
const DATA = {
	"full": {"code": "C01", "name": "Full", "description": "+1 al multiplicador de cada full.", "rarity": "common", "family": "category", "scope": "category", "effect": "category_multiplier", "amount": 1,
		"effects": [{"kind": "category_mult", "categories": ["Full"], "amount": 1}]},
	"straight": {"code": "C02", "name": "Escalera", "description": "+1 al multiplicador de cada escalera.", "rarity": "common", "family": "category", "scope": "category", "effect": "category_multiplier", "amount": 1,
		"effects": [{"kind": "category_mult", "categories": ["Escalera"], "amount": 1}]},
	"generala": {"code": "C03", "name": "Generala", "description": "+1 al multiplicador de cada generala. No evita la prohibición del jefe.", "rarity": "common", "family": "category", "scope": "category", "effect": "category_multiplier", "amount": 1,
		"effects": [{"kind": "category_mult", "categories": ["Generala"], "amount": 1}]},
	"poker": {"code": "C04", "name": "Póker", "description": "+1 al multiplicador de cada póker.", "rarity": "common", "family": "category", "scope": "category", "effect": "category_multiplier", "amount": 1,
		"effects": [{"kind": "category_mult", "categories": ["Póker"], "amount": 1}]},
	"even": {"code": "C05", "name": "Pares", "description": "+2 puntos por cada dado par, incluidos los sobrantes.", "rarity": "common", "family": "die", "scope": "own_points", "effect": "even_points", "amount": 2,
		"effects": [{"kind": "die_points_if", "filter": {"parity": "even"}, "amount": 2}]},
	"odd": {"code": "C06", "name": "Impares", "description": "+2 puntos por cada dado impar, incluidos los sobrantes.", "rarity": "common", "family": "die", "scope": "own_points", "effect": "odd_points", "amount": 2,
		"effects": [{"kind": "die_points_if", "filter": {"parity": "odd"}, "amount": 2}]},
	"pair_mult": {"code": "C07", "name": "Par +", "description": "+1 al multiplicador de cada par.", "rarity": "common", "family": "category",
		"effects": [{"kind": "category_mult", "categories": ["Par"], "amount": 1}]},
	"twopair_mult": {"code": "C08", "name": "Doble par +", "description": "+1 al multiplicador de cada doble par.", "rarity": "common", "family": "category",
		"effects": [{"kind": "category_mult", "categories": ["Doble par"], "amount": 1}]},
	"trio_mult": {"code": "C09", "name": "Trío +", "description": "+1 al multiplicador de cada trío.", "rarity": "common", "family": "category",
		"effects": [{"kind": "category_mult", "categories": ["Trío"], "amount": 1}]},
	"pair_pts": {"code": "C10", "name": "Puntos de par", "description": "+10 puntos al anotar un par.", "rarity": "common", "family": "points",
		"effects": [{"kind": "category_points", "categories": ["Par"], "amount": 10}]},
	"twopair_pts": {"code": "C11", "name": "Puntos de doble par", "description": "+14 puntos al anotar un doble par.", "rarity": "common", "family": "points",
		"effects": [{"kind": "category_points", "categories": ["Doble par"], "amount": 14}]},
	"trio_pts": {"code": "C12", "name": "Puntos de trío", "description": "+12 puntos al anotar un trío.", "rarity": "common", "family": "points",
		"effects": [{"kind": "category_points", "categories": ["Trío"], "amount": 12}]},
	"straight_pts": {"code": "C13", "name": "Puntos de escalera", "description": "+16 puntos al anotar una escalera.", "rarity": "common", "family": "points",
		"effects": [{"kind": "category_points", "categories": ["Escalera"], "amount": 16}]},
	"full_pts": {"code": "C14", "name": "Puntos de full", "description": "+18 puntos al anotar un full.", "rarity": "common", "family": "points",
		"effects": [{"kind": "category_points", "categories": ["Full"], "amount": 18}]},
	"poker_pts": {"code": "C15", "name": "Puntos de póker", "description": "+22 puntos al anotar un póker.", "rarity": "common", "family": "points",
		"effects": [{"kind": "category_points", "categories": ["Póker"], "amount": 22}]},
	"generala_pts": {"code": "C16", "name": "Puntos de generala", "description": "+30 puntos al anotar una generala.", "rarity": "common", "family": "points",
		"effects": [{"kind": "category_points", "categories": ["Generala"], "amount": 30}]},
	"flat_mult": {"code": "C17", "name": "+1 mult", "description": "+1 al multiplicador de cada combinación de la mano.", "rarity": "rare", "family": "general",
		"effects": [{"kind": "flat_group_mult", "amount": 1}]},
	"spent": {"code": "C18", "name": "Moneda gastada", "description": "Entra con +40 puntos de mano. Cada dado que tirás le resta 1; a 0 se rompe. La primera tirada tras comprarla es gratis.", "rarity": "rare", "family": "general",
		"state": {"strength": 40, "grace": true},
		"effects": [{"kind": "hand_points", "per": "state", "key": "strength", "amount": 1}, {"kind": "wear", "key": "strength"}]},
	"gold": {"code": "C19", "name": "Moneda de oro", "description": "Permite comprar hasta quedar en -$10. Se vende por $1.", "rarity": "rare", "family": "economy", "price": 10, "resale": 1,
		"effects": [{"kind": "credit", "amount": 10}]},
	"extra_roll_perm": {"code": "C20", "name": "Tirada permanente", "description": "+1 tirada por mano (4 en vez de 3).", "rarity": "legendary", "family": "general",
		"effects": [{"kind": "extra_rolls", "amount": 1}]},
	"free_renewal": {"code": "C21", "name": "Renovación gratis", "description": "La primera renovación de cada visita a la tienda es gratis.", "rarity": "rare", "family": "economy",
		"effects": [{"kind": "free_renewals", "amount": 1}]},
	"metal": {"code": "C22", "name": "Dados de metal", "description": "Por cada dado de acero o cobre: +1 punto y +0,5 mult si está en una combinación.", "rarity": "common", "family": "die_type",
		"effects": [{"kind": "die_points_if", "filter": {"material": ["steel", "copper"]}, "amount": 1}, {"kind": "die_mult_if", "filter": {"material": ["steel", "copper"]}, "amount": 0.5}]},
	"elemental": {"code": "C23", "name": "Dados elementales", "description": "Por cada dado con elemento: +1 punto y +0,5 mult si está en una combinación.", "rarity": "common", "family": "die_type",
		"effects": [{"kind": "die_points_if", "filter": {"element": "any"}, "amount": 1}, {"kind": "die_mult_if", "filter": {"element": "any"}, "amount": 0.5}]},
	"gems": {"code": "C24", "name": "Gemas", "description": "Por cada dado con gema: +1 punto y +0,5 mult si está en una combinación.", "rarity": "common", "family": "die_type",
		"effects": [{"kind": "die_points_if", "filter": {"shell": "any"}, "amount": 1}, {"kind": "die_mult_if", "filter": {"shell": "any"}, "amount": 0.5}]},
	"straight4": {"code": "C25", "name": "Escaleras de 4", "description": "La escalera se arma con 4 dados (1234, 2345, 3456, 4561); el quinto queda como sobrante.", "rarity": "epic", "family": "rule",
		"effects": [{"kind": "rule", "rule": "straight4"}]},
	"wildcard": {"code": "C26", "name": "Comodín", "description": "El dado que sale 1 funciona como comodín en un grupo y vale el número que imita.", "rarity": "epic", "family": "rule",
		"effects": [{"kind": "rule", "rule": "wildcard"}]},
	"free_reroll": {"code": "C27", "name": "Relanzo libre", "description": "Una vez por mano, relanzar un solo dado no gasta tirada.", "rarity": "epic", "family": "rule",
		"effects": [{"kind": "rule", "rule": "free_reroll"}]},
	"pair_double": {"code": "C28", "name": "Par doble", "description": "Experimental: un par también cuenta como doble par para las monedas.", "rarity": "rare", "family": "rule",
		"effects": [{"kind": "rule", "rule": "pair_double"}]},
	"num_1": {"code": "C29", "name": "Uno", "description": "+5 puntos por cada dado que salga 1.", "rarity": "common", "family": "number",
		"effects": [{"kind": "die_points_if", "filter": {"numbers": [1]}, "amount": 5}]},
	"num_2": {"code": "C30", "name": "Dos", "description": "+5 puntos por cada dado que salga 2.", "rarity": "common", "family": "number",
		"effects": [{"kind": "die_points_if", "filter": {"numbers": [2]}, "amount": 5}]},
	"num_3": {"code": "C31", "name": "Tres", "description": "+5 puntos por cada dado que salga 3.", "rarity": "common", "family": "number",
		"effects": [{"kind": "die_points_if", "filter": {"numbers": [3]}, "amount": 5}]},
	"num_4": {"code": "C32", "name": "Cuatro", "description": "+5 puntos por cada dado que salga 4.", "rarity": "common", "family": "number",
		"effects": [{"kind": "die_points_if", "filter": {"numbers": [4]}, "amount": 5}]},
	"num_5": {"code": "C33", "name": "Cinco", "description": "+5 puntos por cada dado que salga 5.", "rarity": "common", "family": "number",
		"effects": [{"kind": "die_points_if", "filter": {"numbers": [5]}, "amount": 5}]},
	"num_6": {"code": "C34", "name": "Seis", "description": "+5 puntos por cada dado que salga 6.", "rarity": "common", "family": "number",
		"effects": [{"kind": "die_points_if", "filter": {"numbers": [6]}, "amount": 5}]},
	"sixes": {"code": "C35", "name": "Seises", "description": "+1 mult por cada 6 que esté en una combinación.", "rarity": "common", "family": "number",
		"effects": [{"kind": "die_mult_if", "filter": {"numbers": [6]}, "amount": 1}]},
	"first_roll": {"code": "C36", "name": "Primera tirada", "description": "+1 mult si anotás en la primera tirada de la mano.", "rarity": "rare", "family": "rhythm",
		"effects": [{"kind": "cond_mult", "when": "first_roll", "amount": 1}]},
	"unused_rolls": {"code": "C37", "name": "Tiradas sin usar", "description": "+5 puntos de mano por cada tirada que no usaste.", "rarity": "rare", "family": "rhythm",
		"effects": [{"kind": "hand_points", "per": "unused_rolls", "amount": 5}]},
	"last_roll": {"code": "C38", "name": "Última tirada", "description": "+20 puntos de mano si anotás gastando la última tirada.", "rarity": "rare", "family": "rhythm",
		"effects": [{"kind": "hand_points", "per": "last_roll", "amount": 20}]},
	"second_hand": {"code": "C39", "name": "Segunda mano", "description": "+1 mult en la segunda mano del encuentro.", "rarity": "rare", "family": "position",
		"effects": [{"kind": "cond_mult", "when": "second_hand", "amount": 1}]},
	"thermos": {"code": "C40", "name": "Termo", "description": "+0,5 mult por cada nivel de sticker en el termo.", "rarity": "rare", "family": "position",
		"effects": [{"kind": "scaled_mult", "per": "sticker_levels", "amount": 0.5}]},
	"collection": {"code": "C41", "name": "Colección", "description": "+1 mult por cada moneda equipada, incluida esta.", "rarity": "rare", "family": "position",
		"effects": [{"kind": "scaled_mult", "per": "equipped", "amount": 1}]},
	"interest": {"code": "C42", "name": "Interés", "description": "+1 punto de mano por cada $5 de saldo.", "rarity": "rare", "family": "position",
		"effects": [{"kind": "hand_points", "per": "cash_fifth", "amount": 1}]},
	"pocket": {"code": "C43", "name": "Bolsillo", "description": "Capacidad de monedas pasivas +2 (ocupa una; neto +1).", "rarity": "rare", "family": "infra",
		"effects": [{"kind": "slots", "passive": 2, "consumable": 0}]},
	"pocket_small": {"code": "C44", "name": "Bolsillo chico", "description": "Capacidad de monedas de un uso +1 (ocupa una ranura de pasivas).", "rarity": "rare", "family": "infra",
		"effects": [{"kind": "slots", "passive": 0, "consumable": 1}]},
	"discount": {"code": "C45", "name": "Descuento", "description": "Ofertas y renovaciones de la tienda -20 %.", "rarity": "rare", "family": "infra",
		"effects": [{"kind": "discount", "amount": 0.2}]},
	"tempered_gem": {"code": "C46", "name": "Gema templada", "description": "La primera rotura de cada gema se ignora.", "rarity": "rare", "family": "gem",
		"effects": [{"kind": "gem", "rule": "save_first_break"}]},
	"jeweler": {"code": "C47", "name": "Joyero", "description": "Reparar gemas cuesta la mitad.", "rarity": "common", "family": "gem",
		"effects": [{"kind": "gem", "rule": "repair_half"}]},
	"veteran": {"code": "C48", "name": "Veterana", "description": "+0,5 mult permanente por cada encuentro ganado con ella equipada.", "rarity": "rare", "family": "growth",
		"state": {"wins": 0},
		"effects": [{"kind": "state_mult", "key": "wins", "amount": 0.5}, {"kind": "grow", "key": "wins", "on": "encounter_won", "amount": 1}]},
	"accumulated": {"code": "C49", "name": "Acumulada", "description": "+3 puntos de mano permanentes por cada mano anotada con ella equipada.", "rarity": "common", "family": "growth",
		"state": {"hands": 0},
		"effects": [{"kind": "hand_points", "per": "state", "key": "hands", "amount": 3}, {"kind": "grow", "key": "hands", "on": "hand_scored", "amount": 1}]},
	"streak": {"code": "C50", "name": "Racha", "description": "+0,5 mult por cada mano seguida con combinación; se pierde al anotar sin combinación.", "rarity": "rare", "family": "growth",
		"state": {"streak": 0},
		"effects": [{"kind": "state_mult", "key": "streak", "amount": 0.5}, {"kind": "grow", "key": "streak", "on": "hand_combo", "amount": 1}, {"kind": "grow", "key": "streak", "on": "hand_plain", "reset": true}]},
	"bosshunter": {"code": "C51", "name": "Cazajefes", "description": "+1 mult permanente por cada jefe vencido con ella equipada.", "rarity": "epic", "family": "growth",
		"state": {"bosses": 0},
		"effects": [{"kind": "state_mult", "key": "bosses", "amount": 1}, {"kind": "grow", "key": "bosses", "on": "boss_won", "amount": 1}]},
	"reserve_roll": {"code": "C53", "name": "Tirada de reserva", "description": "+1 tirada en la primera mano de cada encuentro.", "rarity": "rare", "family": "general",
		"effects": [{"kind": "extra_rolls_first", "amount": 1}]},
	"collector": {"code": "C54", "name": "Cobrador", "description": "+$1 al ganar cada encuentro.", "rarity": "rare", "family": "general",
		"effects": [{"kind": "encounter_cash", "amount": 1}]},
	"level_veteran": {"code": "C55", "name": "Veterano de nivel", "description": "+0,25 mult por cada nivel de campaña alcanzado.", "rarity": "rare", "family": "general",
		"effects": [{"kind": "scaled_mult", "per": "campaign_level", "amount": 0.25}]},
	"served": {"code": "C56", "name": "Servida", "description": "+2 mult si anotás en la primera tirada de la mano.", "rarity": "rare", "family": "general",
		"effects": [{"kind": "cond_mult", "when": "first_roll", "amount": 2}]},
	"leftovers": {"code": "C57", "name": "Sobrantes", "description": "+2 puntos de mano por cada dado que quede fuera de una combinación.", "rarity": "rare", "family": "general",
		"effects": [{"kind": "hand_points", "per": "leftover_dice", "amount": 2}]},
	"extra_hand": {"code": "C52", "name": "Mano extra", "description": "3 manos por encuentro en vez de 2.", "rarity": "legendary", "family": "general",
		"effects": [{"kind": "extra_hands", "amount": 1}]},
	"boost": {"code": "U01", "name": "Impulso 1 y 4", "description": "+3 puntos por cada 1 y 4 hasta terminar este encuentro. Se consume.", "rarity": "common", "family": "use", "scope": "own_points", "effect": "boost", "amount": 3, "duration": "encounter", "contexts": ["play"],
		"effects": [{"kind": "impulse", "numbers": [1, 4], "amount": 3}]},
	"roll": {"code": "U02", "name": "Una tirada más", "description": "+1 tirada disponible en la mano actual. Se consume.", "rarity": "common", "family": "use", "scope": "roll_budget", "effect": "extra_roll", "amount": 1, "duration": "hand", "contexts": ["play"],
		"effects": [{"kind": "use_extra_roll", "amount": 1}]},
	"boost_25": {"code": "U03", "name": "Impulso 2 y 5", "description": "+3 puntos por cada 2 y 5 hasta terminar este encuentro. Se consume.", "rarity": "common", "family": "use", "scope": "own_points", "effect": "impulse", "amount": 3, "duration": "encounter", "contexts": ["play"],
		"effects": [{"kind": "impulse", "numbers": [2, 5], "amount": 3}]},
	"boost_36": {"code": "U04", "name": "Impulso 3 y 6", "description": "+3 puntos por cada 3 y 6 hasta terminar este encuentro. Se consume.", "rarity": "common", "family": "use", "scope": "own_points", "effect": "impulse", "amount": 3, "duration": "encounter", "contexts": ["play"],
		"effects": [{"kind": "impulse", "numbers": [3, 6], "amount": 3}]},
	"double_mult": {"code": "U05", "name": "Doble mult", "description": "Duplica el multiplicador de cada combinación de la mano actual. Se consume.", "rarity": "rare", "family": "use", "scope": "multiplier", "effect": "double_mult", "amount": 2, "duration": "hand", "contexts": ["play"],
		"effects": [{"kind": "use_double_mult", "amount": 2}]},
	"free_renewal_use": {"code": "U06", "name": "Renovación gratis", "description": "Una renovación de la tienda sin costo. Se consume.", "rarity": "common", "family": "use", "scope": "economy", "effect": "free_renewal", "amount": 1, "duration": "encounter", "contexts": ["shop"],
		"effects": [{"kind": "use_free_renewal", "amount": 1}]},
	"repair_gem": {"code": "U07", "name": "Reparar gema", "description": "Repara gratis la gema de mayor costo que elijas en la fase de reparación. Se consume.", "rarity": "common", "family": "use", "scope": "gem", "effect": "repair_gem", "amount": 1, "duration": "encounter", "contexts": ["repair"],
		"effects": [{"kind": "use_repair_free", "amount": 1}]},
	"free_reroll_use": {"code": "U08", "name": "Relanzo libre", "description": "Relanzar un solo dado no gasta tirada (una vez). Se consume.", "rarity": "common", "family": "use", "scope": "roll_budget", "effect": "free_reroll", "amount": 1, "duration": "hand", "contexts": ["play"],
		"effects": [{"kind": "use_free_reroll", "amount": 1}]}
}

static func definition(id: String) -> Dictionary:
	if not DATA.has(id): return {}
	var source: Dictionary = DATA[id]
	var result: Dictionary = source.duplicate(true)
	var consumable: bool = source.code.begins_with("U")
	var prices: Array = (CONSUMABLE_PRICES if consumable else PASSIVE_PRICES)[source.rarity]
	result.type = "consumable" if consumable else "passive"
	result.scope = source.get("scope", "hand")
	result.trigger = "use" if consumable else "score"
	result.duration = source.get("duration", "equipped")
	result.effect = source.get("effect", source.effects[0].kind)
	result.amount = source.get("amount", source.effects[0].get("amount", 0))
	result.price = source.get("price", prices[0])
	result.resale = source.get("resale", prices[1])
	result.use_contexts = source.get("contexts", []).duplicate()
	result.id = id
	result.provisional_economy = true
	return result

static func catalog() -> Dictionary:
	var result: Dictionary = {}
	for id in DATA: result[id] = definition(id)
	return result

static func rarity_of(id: String) -> String:
	return DATA.get(id, {}).get("rarity", "common")

static func effects(id: String) -> Array:
	return DATA.get(id, {}).get("effects", [])

static func initial_state(id: String) -> Dictionary:
	return DATA.get(id, {}).get("state", {}).duplicate(true)

static func valid_state(id: String, state: Variant) -> bool:
	# Shape and ranges only: same keys as the definition's initial state.
	if not state is Dictionary: return false
	var base := initial_state(id)
	if state.size() != base.size(): return false
	for key in base:
		if not state.has(key) or typeof(state[key]) != typeof(base[key]): return false
		if base[key] is int and (state[key] < 0 or state[key] > 1000000): return false
	return true

static func empty_inventory() -> Dictionary:
	return {"equipped": [], "consumables": [], "shared_capacity": BASE_SHARED, "consumable_capacity": BASE_CONSUMABLE}

static func capacity(equipped_ids: Array) -> Dictionary:
	var shared := BASE_SHARED
	var stored := BASE_CONSUMABLE
	for id in equipped_ids:
		for effect in effects(id):
			if effect.kind == "slots":
				shared += int(effect.passive)
				stored += int(effect.consumable)
	return {"shared": shared, "consumable": stored}

static func refresh_capacity(inventory: Dictionary) -> void:
	var limits := capacity(ids(inventory.equipped))
	inventory.shared_capacity = limits.shared
	inventory.consumable_capacity = limits.consumable

static func instance(id: String, serial: int) -> Dictionary:
	return {"instance_id": serial, "coin_id": id, "state": initial_state(id)}

static func ids(instances: Array) -> Array:
	var result: Array = []
	for item in instances: result.append(item.coin_id)
	return result

static func can_store(inventory: Dictionary, id: String) -> bool:
	var data := definition(id)
	if data.is_empty(): return false
	if data.type in ["passive", "active"]:
		return inventory.equipped.size() < inventory.shared_capacity and id not in ids(inventory.equipped)
	return data.type == "consumable" and inventory.consumables.size() < inventory.consumable_capacity

static func can_remove(inventory: Dictionary, id: String) -> bool:
	# A slot coin cannot be sold while the remaining coins would overflow its capacity.
	var remaining := ids(inventory.equipped)
	if id in remaining: remaining.erase(id)
	var limits := capacity(remaining)
	var passives_after: int = remaining.size()
	return passives_after <= limits.shared and inventory.consumables.size() <= limits.consumable

static func can_use(id: String, context: String) -> bool:
	var data := definition(id)
	return not data.is_empty() and context in data.use_contexts

static func state_of(instances: Array) -> Dictionary:
	var result: Dictionary = {}
	for item in instances: result[item.coin_id] = item.state
	return result

static func advance(instances: Array, event: String) -> void:
	# Counters advance when the event closes and pay from the next one. Boss suspension never blocks them.
	for item in instances:
		for effect in effects(item.coin_id):
			if effect.kind != "grow" or effect.on != event: continue
			if effect.get("reset", false): item.state[effect.key] = 0
			else: item.state[effect.key] = int(item.state[effect.key]) + int(effect.amount)
