extends RefCounted
const PASSIVES = ["full", "straight", "generala", "poker", "even", "odd"]
const CONSUMABLES = ["boost", "roll"]
# code, type, scope, trigger, duration, effect, amount, resale, use contexts
const METADATA = {
	"full": ["C01", "passive", "category", "score", "equipped", "category_multiplier", 1, 2, []],
	"straight": ["C02", "passive", "category", "score", "equipped", "category_multiplier", 1, 2, []],
	"generala": ["C03", "passive", "category", "score", "equipped", "category_multiplier", 1, 2, []],
	"poker": ["C04", "passive", "category", "score", "equipped", "category_multiplier", 1, 2, []],
	"even": ["C05", "passive", "own_points", "score", "equipped", "even_points", 2, 2, []],
	"odd": ["C06", "passive", "own_points", "score", "equipped", "odd_points", 2, 2, []],
	"boost": ["U01", "consumable", "own_points", "use", "encounter", "boost", 3, 1, ["play"]],
	"roll": ["U02", "consumable", "roll_budget", "use", "hand", "extra_roll", 1, 1, ["play"]]
}

static func definition(id: String) -> Dictionary:
	if not DATA.has(id): return {}
	var result: Dictionary = DATA[id].duplicate(true)
	var keys := ["code", "type", "scope", "trigger", "duration", "effect", "amount", "resale", "use_contexts"]
	for i in range(keys.size()): result[keys[i]] = METADATA[id][i]
	result = result.duplicate(true)
	result.merge({"id": id, "provisional_economy": true})
	return result

static func catalog() -> Dictionary:
	var result: Dictionary = {}
	for id in DATA: result[id] = definition(id)
	return result

static func empty_inventory() -> Dictionary:
	return {"equipped": [], "consumables": [], "shared_capacity": 5, "consumable_capacity": 1}

static func instance(id: String, serial: int) -> Dictionary:
	return {"instance_id": serial, "coin_id": id, "state": {}}

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

static func can_use(id: String, context: String) -> bool:
	var data := definition(id)
	return not data.is_empty() and context in data.use_contexts

static func point_additions(number: int, equipped: Array, boost: bool) -> Array:
	var result: Array = []
	for id in equipped:
		var data := definition(id)
		if (data.effect == "even_points" and number % 2 == 0) or (data.effect == "odd_points" and number % 2 == 1):
			result.append({"source": "coin:" + id, "amount": float(data.amount)})
	if boost and number in [1, 3]:
		result.append({"source": "consumable:boost", "amount": float(definition("boost").amount)})
	return result
## Initial catalog. Economy remains provisional; no future active powers.
const DATA = {
	"full": {"name": "Full", "description": "+1 al multiplicador de cada full.", "category": "Full", "price": 4},
	"straight": {"name": "Escalera", "description": "+1 al multiplicador de cada escalera.", "category": "Escalera", "price": 4},
	"generala": {"name": "Generala", "description": "+1 al multiplicador de cada generala. No evita la prohibición del jefe.", "category": "Generala", "price": 4},
	"poker": {"name": "Póker", "description": "+1 al multiplicador de cada póker.", "category": "Póker", "price": 4},
	"even": {"name": "Pares", "description": "+2 puntos por cada dado par, incluidos los sobrantes.", "price": 4},
	"odd": {"name": "Impares", "description": "+2 puntos por cada dado impar, incluidos los sobrantes.", "price": 4},
	"boost": {"name": "Impulso 1 y 3", "description": "+3 puntos por cada 1 y 3 hasta terminar este encuentro. Se consume.", "price": 2},
	"roll": {"name": "Una tirada más", "description": "+1 tirada disponible en la mano actual. Se consume.", "price": 2}
}
