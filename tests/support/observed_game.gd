extends "res://scripts/game.gd"
## Observer for event ordering tests; never loaded by the playable game.
var roll_hooks := 0
var score_hooks := 0
var observations: Array = []
var fixture_rows: Array = []

func preview() -> Dictionary:
	if not fixture_rows.is_empty():
		return Rules.finish_score(fixture_rows, false)
	return super.preview()

func _after_roll(event: Dictionary) -> void:
	super._after_roll(event)
	roll_hooks += 1
	observations.append({"type": event.type, "rolls_made": rolls_made})

func _after_hand_scored(event: Dictionary) -> void:
	super._after_hand_scored(event)
	score_hooks += 1
	observations.append({"type": event.type, "points": points, "phase": phase,
		"history_size": history.size(), "total": event.payload.score.total})
	# A future hook cannot accidentally overwrite the credited result via its event.
	event.payload.score.total = -999
	event.payload.score.rows.clear()
