extends RefCounted
## Rerolls earn hand counters; scoring only reads them. No RNG or consumption.
const CATALOG = {
	"earth": {
		"name": "Tierra", "condition": "+2 puntos por cada otro dado conservado al relanzar otros dados.",
		"gain": 2.0, "applies_to_leftovers": true
	},
	"wind": {
		"name": "Viento", "condition": "+0.5 al multiplicador por relanzamiento propio; requiere combinación desde par.",
		"gain": 0.5, "applies_to_leftovers": false
	},
	"fire": {
		"name": "Fuego", "condition": "Cara 4, 5 o 6 en una combinación desde par.",
		"gain": 5.0, "applies_to_leftovers": false
	},
	"water": {
		"name": "Agua", "condition": "Cara 1, 2 o 3 en una combinación desde par.",
		"gain": 5.0, "applies_to_leftovers": false
	},
	"electricity": {
		"name": "Electricidad", "condition": "+3 puntos por cada otro dado de su grupo con igual número, incluidos sobrantes.",
		"gain": 3.0, "applies_to_leftovers": true
	}
}

static func catalog() -> Dictionary:
	return CATALOG.duplicate(true)

static func definition(id: String) -> Dictionary:
	if not CATALOG.has(id): return {}
	var result: Dictionary = CATALOG[id].duplicate(true)
	result.merge({"id": id, "passive": true, "duration": "run", "consumed": false})
	return result

static func evaluate(die: Dictionary, dice: Array, ids: Array, category: String) -> Dictionary:
	var effect := definition(die.get("element", ""))
	if effect.is_empty(): return {}
	effect.merge({"active": false, "points": 0.0, "multiplier_addition": 0.0, "matches": 0, "reason": "",
		"source": "element:" + effect.id + ":" + str(die.id)})
	if effect.id == "earth":
		effect.points = earth_points(die)
		effect.active = effect.points > 0
		effect.reason = "Acumulado de esta mano: +%s puntos; relanzarlo borra este bono." % effect.points
	elif effect.id == "wind":
		effect.multiplier_addition = wind_multiplier(die) if category != "Sin combinación" else 0.0
		effect.active = effect.multiplier_addition > 0
		effect.reason = "Acumulado de esta mano: +%s al multiplicador." % wind_multiplier(die) if category != "Sin combinación" else "Requiere una combinación desde par; conserva su acumulación de esta mano."
	elif effect.id in ["fire", "water"]:
		if category == "Sin combinación":
			effect.reason = "Requiere una combinación desde par."
			return effect
		var eligible: bool = die.value in ([4, 5, 6] if effect.id == "fire" else [1, 2, 3])
		if not eligible:
			effect.reason = "La cara debe mostrar 4, 5 o 6." if effect.id == "fire" else "La cara debe mostrar 1, 2 o 3."
			return effect
		effect.active = true
		effect.points = effect.gain
		effect.reason = "La cara y su combinación cumplen la condición."
	else:
		for id in ids:
			if id != die.id and dice[id].value == die.value:
				effect.matches += 1
		effect.active = effect.matches > 0
		effect.points = effect.gain * effect.matches
		effect.reason = ("Coincidencias en su grupo: %d." % effect.matches) if effect.active else "No hay otro dado con el mismo número en este grupo."
	return effect

static func earth_points(die: Dictionary) -> float:
	return float(die.get("hand_effects", {}).get("earth_points", 0.0)) if die.get("element", "") == "earth" else 0.0

static func wind_multiplier(die: Dictionary) -> float:
	return float(die.get("hand_effects", {}).get("wind_multiplier", 0.0)) if die.get("element", "") == "wind" else 0.0

static func after_reroll(dice: Array, rolled_ids: Array, kept_ids: Array) -> void:
	if rolled_ids.is_empty(): return
	for die in dice:
		if die.id in rolled_ids:
			if die.element == "earth":
				die.hand_effects["earth_points"] = 0.0
			elif die.element == "wind":
				die.hand_effects["wind_multiplier"] = wind_multiplier(die) + CATALOG.wind.gain
		elif die.id in kept_ids and die.element == "earth":
			die.hand_effects["earth_points"] = earth_points(die) + CATALOG.earth.gain * (kept_ids.size() - 1)
