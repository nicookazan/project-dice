extends RefCounted
## Earned material counters are changed only by effective rerolls.
const STEEL_POINTS := 3.0
const COPPER_MULTIPLIER := 0.5

static func after_reroll(dice: Array, rolled_ids: Array, kept_ids: Array, suspended_materials: Array = []) -> void:
	if rolled_ids.is_empty(): return
	for die in dice:
		if die.id in rolled_ids:
			if die.material == "steel":
				die.encounter_effects["steel_points"] = 0.0
			elif die.material == "copper" and die.material not in suspended_materials:
				die.encounter_effects["copper_multiplier"] = copper_multiplier(die) + COPPER_MULTIPLIER
		elif die.id in kept_ids and die.material == "steel" and die.material not in suspended_materials:
			die.encounter_effects["steel_points"] = steel_points(die) + STEEL_POINTS

static func steel_points(die: Dictionary) -> float:
	return float(die.encounter_effects.get("steel_points", 0.0)) if die.material == "steel" else 0.0

static func copper_multiplier(die: Dictionary) -> float:
	return float(die.encounter_effects.get("copper_multiplier", 0.0)) if die.material == "copper" else 0.0

static func inspect(die: Dictionary) -> Dictionary:
	var material: String = die.material
	var name := "Acero" if material == "steel" else ("Cobre" if material == "copper" else "Base")
	return {
		"id": material, "name": name, "duration": "encounter",
		"points": steel_points(die), "multiplier_addition": copper_multiplier(die),
		"gain": STEEL_POINTS if material == "steel" else (COPPER_MULTIPLIER if material == "copper" else 0.0),
		"trigger": "kept_on_reroll" if material == "steel" else ("own_reroll" if material == "copper" else ""),
		"applies_to_leftovers": material == "steel",
		"resets_on_own_reroll": material == "steel"
	}
