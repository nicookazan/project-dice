extends RefCounted
## Plain data only. A die keeps its array slot/ID for the entire run.
const COUNT := 5

static func create_die(id: int) -> Dictionary:
	return {
		"id": id,
		"faces": [1, 2, 3, 4, 5, 6],
		"material": "basic",
		"shell": "",
		"shell_broken": false,
		"element": "",
		"encounter_effects": {},
		"hand_effects": {},
		"face_index": -1,
		"value": 0,
		"zone": "cup"
	}

static func create_dice() -> Array:
	var result: Array = []
	for id in range(COUNT):
		result.append(create_die(id))
	return result

static func number_on_face(die: Dictionary, face_index: int) -> int:
	return die.faces[face_index]

static func reset_hand(die: Dictionary) -> void:
	die.hand_effects = {}
	die.face_index = -1
	die.value = 0
	die.zone = "cup"

static func reset_encounter(die: Dictionary) -> void:
	die.encounter_effects = {}
