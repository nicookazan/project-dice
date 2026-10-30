extends RefCounted
## Domain operations only: no prices, RNG, rewards or UI transactions.
const DiceState = preload("res://scripts/dice_state.gd")
const GLOBAL_RANGES = {
	"common": [1, 3],
	"rare": [4, 5],
	"epic": [6, 8],
	"legendary": [9, 10]
}

static func valid_number(number: Variant) -> bool:
	return number is int and number >= 1 and number <= 6

static func valid_points(points: Variant) -> bool:
	if not points is Dictionary: return false
	for key in points:
		if not key is String or key not in ["1", "2", "3", "4", "5", "6"]:
			return false
		if not points[key] is int or points[key] < 0:
			return false
	return true

static func _increase(points: Dictionary, number: Variant, amount: Variant) -> bool:
	if not valid_number(number) or not amount is int or amount <= 0 or not valid_points(points):
		return false
	var key := str(number)
	var previous: int = points.get(key, 0)
	var increased: int = previous + amount
	if increased <= previous: return false # Reject overflow before mutating data.
	points[key] = increased
	return true

static func apply_global(points: Dictionary, number: Variant, amount: Variant) -> bool:
	return _increase(points, number, amount)

static func _target(dice: Array, id: Variant) -> Dictionary:
	if dice.size() != DiceState.COUNT or not id is int or id < 0 or id >= dice.size():
		return {}
	if not dice[id] is Dictionary or dice[id].get("id", -1) != id:
		return {}
	return dice[id]

static func change_face(dice: Array, id: Variant, face_index: Variant, number: Variant) -> bool:
	var die := _target(dice, id)
	if die.is_empty() or not valid_number(number) or not face_index is int or face_index < 0 or face_index >= 6:
		return false
	if not die.get("faces", null) is Array or die.faces.size() != 6:
		return false
	for face in die.faces:
		if not valid_number(face): return false
	if die.faces[face_index] == number: return false
	die.faces[face_index] = number
	# Keep the last observed result and every other attribute. The next throw
	# resolves the new face distribution; a past roll is never rewritten.
	return true

static func global_ranges() -> Dictionary:
	return GLOBAL_RANGES.duplicate(true)

static func global_offer(number: Variant, amount: Variant, rarity: String, price: Variant) -> Dictionary:
	# The caller supplies an exact price and magnitude. No defaults or rerolls.
	if not valid_number(number) or not amount is int or not GLOBAL_RANGES.has(rarity):
		return {"valid": false, "errors": ["Número, magnitud o rareza inválidos."]}
	var bounds: Array = GLOBAL_RANGES[rarity]
	if amount < bounds[0] or amount > bounds[1] or not price is int or price <= 0:
		return {"valid": false, "errors": ["La magnitud o el precio no son válidos."]}
	return {
		"valid": true, "errors": [], "kind": "number_upgrade", "scope": "global",
		"number": number, "amount": amount, "rarity": rarity, "price": price
	}
