extends RefCounted
## Pure shell powers and repair metadata. Game owns mutations and RNG.
const RISKS = {"emerald": 0.1, "ruby": 0.2, "sapphire": 0.3, "diamond": 0.5}
const REPAIR_COSTS = {"emerald": 2, "ruby": 3, "sapphire": 4, "diamond": 5}
const CATALOG = {
	"emerald": {"name": "Esmeralda", "description": "Duplica los puntos propios del dado.", "point_factor": 2.0},
	"sapphire": {"name": "Zafiro", "description": "Suma +2 al multiplicador del grupo.", "multiplier_addition": 2.0},
	"ruby": {"name": "Rubí", "description": "Multiplica ×1.5 el multiplicador después de las sumas.", "multiplier_factor": 1.5},
	"diamond": {"name": "Diamante", "description": "Añade una copia del resultado final del grupo.", "copies": 1.0}
}

static func definition(id: String) -> Dictionary:
	if not CATALOG.has(id): return {}
	var result: Dictionary = CATALOG[id].duplicate(true)
	result["id"] = id
	result["break_risk"] = RISKS[id]
	result["repair_cost"] = REPAIR_COSTS[id]
	return result

static func repair_quote(dice: Array, ids: Array) -> Dictionary:
	var seen: Dictionary = {}
	var cost := 0
	var items: Array = []
	for id in ids:
		if not id is int or id < 0 or id >= dice.size() or seen.has(id):
			return {"valid": false, "cost": 0, "items": [], "error": "Selección de carcasas inválida."}
		seen[id] = true
		var die: Dictionary = dice[id]
		var shell: String = die.get("shell", "")
		if not REPAIR_COSTS.has(shell) or not die.get("shell_broken", false):
			return {"valid": false, "cost": 0, "items": [], "error": "Solo se reparan carcasas resquebrajadas conocidas."}
		cost += REPAIR_COSTS[shell]
		items.append({"id": id, "shell": shell, "cost": REPAIR_COSTS[shell]})
	return {"valid": true, "cost": cost, "items": items, "error": ""}

static func evaluate(die: Dictionary, category: String, suspended := false) -> Dictionary:
	var effect := definition(die.get("shell", ""))
	if effect.is_empty(): return {}
	var active: bool = not suspended and not die.get("shell_broken", false) and category != "Sin combinación"
	var result := {
		"id": effect.id, "name": effect.name, "description": effect.description,
		"active": active, "source": "shell:" + effect.id + ":" + str(die.id),
		"point_factor": effect.get("point_factor", 1.0) if active else 1.0,
		"multiplier_addition": effect.get("multiplier_addition", 0.0) if active else 0.0,
		"multiplier_factor": effect.get("multiplier_factor", 1.0) if active else 1.0,
		"copies": effect.get("copies", 0.0) if active else 0.0,
		"reason": "Carcasa intacta en combinación."
	}
	if suspended: result.reason = "Carcasa suspendida por el jefe: sin poder ni riesgo de rotura."
	elif die.get("shell_broken", false): result.reason = "Carcasa resquebrajada: poder suspendido."
	elif category == "Sin combinación": result.reason = "Requiere una combinación desde par."
	return result
