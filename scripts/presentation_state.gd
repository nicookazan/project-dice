extends RefCounted
## Pure descriptions plus a presentation-only observer. No mutation of game data.
const LINES = {"dia": "¿Una mano más? El mate todavía está caliente.", "tarde": "La mesa es la misma. Las miradas, no tanto.", "noche": "Afuera ya cerraron. Acá todavía se juega.", "cierre": "Taparon las ventanas. Nadie se levantó.", "espacio": "El club sigue acá. El barrio quedó lejos.", "agujero_negro": "No mires afuera. Terminá de contar.", "cielo": "Llegaste. Ahora anotá sin bajar la mirada."}
var observed: Dictionary = {}

static func profile(game) -> Dictionary:
	var actor := "common"
	if game.is_boss(): actor = "god" if not game.campaign.is_empty() and game.level_index == 6 else game.boss_rule.kind
	var dialogue: String = LINES.get(game.environment_id(), LINES.dia)
	if game.is_boss() and actor != "god": dialogue = "El jefe marca la condición: " + game.boss_rule.name + "."
	return {"environment": game.environment_id(), "actor": actor, "rule_target": game.boss_rule.target, "level": game.level_index, "dialogue": dialogue, "beverage": "mate"}

func observe(game) -> Dictionary:
	var now := {"seed": game.run_seed, "level": game.level_index, "rival": game.rival, "phase": game.phase, "rolls": game.rolls_made, "event": game.event_sequence, "groups": game.groups.size(), "receipts": game.purchase_receipts.size(), "repair": game.repair_resolution.get("status", ""), "broken": game.dice.filter(func(die): return die.shell_broken).size()}
	var cue := {}
	if not observed.is_empty() and now.seed == observed.seed:
		if now.level != observed.level: cue = {"sound": "level", "text": "Nuevo nivel · jefe anunciado"}
		elif now.rival == observed.rival:
			if now.rolls > observed.rolls: cue = {"sound": "roll", "text": "Tirada resuelta · elegí tus grupos"}
			elif now.phase in ["hand_result", "lost"] and observed.phase == "play": cue = {"sound": "break" if now.broken > observed.broken else "score", "text": "Mano anotada" + (" · carcasa resquebrajada (R)" if now.broken > observed.broken else " · lapicera azul")}
			elif now.receipts > observed.receipts: cue = {"sound": "buy", "text": "Compra aplicada · pago único"}
			elif now.repair == "repaired" and observed.repair == "pending": cue = {"sound": "repair", "text": "Reparación aplicada"}
			elif now.groups > observed.groups: cue = {"sound": "move", "text": "Grupo formado · editable hasta relanzar"}
	observed = now
	return cue
