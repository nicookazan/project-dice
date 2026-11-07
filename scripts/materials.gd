extends RefCounted
## Earned material counters are changed only by effective rerolls.
const STEEL_POINTS := 3.0
const COPPER_MULTIPLIER := 0.5

## Tabla única de materiales del cuerpo (D16). `base` es el metal del que toma la mecánica: los oxidados y el oro
## funcionan por ahora igual que su base (decisión del autor, 06/11/2026); sus reglas propias se definen más adelante.
## `name` es lo que se muestra en el juego («Hierro» para el id interno `steel`, para no migrar partidas).
## `body_kind` es el cuerpo que dibuja die_body.gdshader; `color` es el tono de las fichas y recibos.
const TABLE := {
	"basic": {"name": "Base", "base": "basic", "body_kind": 0, "color": "fff0c7"},
	"steel": {"name": "Hierro", "base": "steel", "body_kind": 1, "color": "b8c4d4"},
	"copper": {"name": "Cobre", "base": "copper", "body_kind": 2, "color": "e89a5c"},
	"rust_iron": {"name": "Hierro oxidado", "base": "steel", "body_kind": 3, "color": "c0703c"},
	"rust_copper": {"name": "Cobre oxidado", "base": "copper", "body_kind": 4, "color": "5fb88c"},
	"gold": {"name": "Oro", "base": "steel", "body_kind": 5, "color": "f0c850"}}
## Metales: todos los materiales del cuerpo salvo el básico, en orden de catálogo.
const METALS := ["steel", "copper", "rust_iron", "rust_copper", "gold"]

static func is_metal(id: String) -> bool:
	return id in METALS

static func base_of(id: String) -> String:
	return String(TABLE.get(id, TABLE.basic).base)

static func display_name(id: String) -> String:
	return String(TABLE.get(id, TABLE.basic).name)

static func body_kind(id: String) -> int:
	return int(TABLE.get(id, TABLE.basic).body_kind)

static func color_hex(id: String) -> String:
	return String(TABLE.get(id, TABLE.basic).color)

static func after_reroll(dice: Array, rolled_ids: Array, kept_ids: Array, suspended_materials: Array = []) -> void:
	if rolled_ids.is_empty(): return
	for die in dice:
		if die.id in rolled_ids:
			if base_of(die.material) == "steel":
				die.encounter_effects["steel_points"] = 0.0
			elif base_of(die.material) == "copper" and base_of(die.material) not in suspended_materials:
				die.encounter_effects["copper_multiplier"] = copper_multiplier(die) + COPPER_MULTIPLIER
		elif die.id in kept_ids and base_of(die.material) == "steel" and base_of(die.material) not in suspended_materials:
			die.encounter_effects["steel_points"] = steel_points(die) + STEEL_POINTS

static func steel_points(die: Dictionary) -> float:
	return float(die.encounter_effects.get("steel_points", 0.0)) if base_of(die.material) == "steel" else 0.0

static func copper_multiplier(die: Dictionary) -> float:
	return float(die.encounter_effects.get("copper_multiplier", 0.0)) if base_of(die.material) == "copper" else 0.0

static func inspect(die: Dictionary) -> Dictionary:
	var material: String = die.material
	var base := base_of(material)
	return {
		"id": material, "name": display_name(material), "duration": "encounter",
		"points": steel_points(die), "multiplier_addition": copper_multiplier(die),
		"gain": STEEL_POINTS if base == "steel" else (COPPER_MULTIPLIER if base == "copper" else 0.0),
		"trigger": "kept_on_reroll" if base == "steel" else ("own_reroll" if base == "copper" else ""),
		"applies_to_leftovers": base == "steel",
		"resets_on_own_reroll": base == "steel"
	}
