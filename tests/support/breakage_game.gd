extends "res://scripts/game.gd"
## Deterministic risk boundary injection; never used by the playable game.
var draws: Array = []
var draw_count := 0
var credited_before_draw := true

func _breakage_roll() -> float:
	credited_before_draw = credited_before_draw and phase == "hand_result" and not history.is_empty() and points == history[-1].accumulated
	draw_count += 1
	return draws.pop_front() if not draws.is_empty() else 0.999
