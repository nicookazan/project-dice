extends RefCounted
## Provisional D07 data for a technical 21-encounter campaign, not final content/balance.
const Boss = preload("res://scripts/boss_rules.gd")
const Catalog = preload("res://scripts/boss_catalog.gd")
const ID := "hasta-dios-jefes-v1"
const NORMAL_REWARD := 8

static func prototype() -> Array:
	var targets := [[40, 70], [70, 110], [110, 160], [160, 230], [230, 320], [320, 440], [440, 600]]
	var environments := ["dia", "tarde", "noche", "cierre", "espacio", "agujero_negro", "cielo"]
	var levels: Array = []
	for level in range(7):
		var candidates: Array = Catalog.of_level(level + 1).map(func(row): return Catalog.candidate_of(row))
		levels.append({"id": "nivel_" + str(level + 1), "name": "Dios" if level == 6 else "Nivel " + str(level + 1), "environment": environments[level], "targets": targets[level], "candidates": candidates})
	return levels

static func valid(levels: Variant) -> bool:
	if not levels is Array or levels.size() != 7: return false
	var ids: Array = []
	for level in levels:
		if not level is Dictionary or level.size() != 5 or not level.get("id") is String or level.id in ids or not level.get("name") is String or level.get("environment") not in ["dia", "tarde", "noche", "cierre", "espacio", "agujero_negro", "cielo"] or not level.get("targets") is Array or level.targets.size() != 2 or not level.get("candidates") is Array or level.candidates.size() != 3: return false
		ids.append(level.id)
		for target in level.targets:
			if not target is int or target < 1: return false
		for candidate in level.candidates:
			if not candidate is Dictionary or candidate.size() != 5 or not candidate.get("id") is String or candidate.id in ids or not candidate.get("name") is String or not candidate.get("target") is int or candidate.target < 1 or not candidate.get("base_reward") is int or candidate.base_reward < 1 or not Boss.valid_rule(candidate.get("rule")) or candidate.rule.id != candidate.id: return false
			ids.append(candidate.id)
	return true

static func candidate(level: Dictionary, id: String) -> Dictionary:
	for entry in level.candidates:
		if entry.id == id: return entry.duplicate(true)
	return {}

static func encounters(level: Dictionary, chosen: Dictionary) -> Array:
	return [{"id": level.id + "_r1", "kind": "normal", "target": level.targets[0]}, {"id": level.id + "_r2", "kind": "normal", "target": level.targets[1]}, {"id": chosen.id, "kind": "boss", "target": chosen.target}]

static func valid_progress(game: Dictionary) -> bool:
	if game.campaign.is_empty(): return game.level_index == 0 and game.selected_bosses.is_empty() and game.completed_encounters.is_empty()
	if not valid(game.campaign) or game.level_index < 0 or game.level_index > 6 or game.selected_bosses.size() != game.level_index + 1: return false
	var completed: Array = []
	for index in range(game.level_index + 1):
		var key := str(index)
		if not game.selected_bosses.get(key) is String: return false
		var chosen := candidate(game.campaign[index], game.selected_bosses[key])
		if chosen.is_empty(): return false
		var plan := encounters(game.campaign[index], chosen)
		if index < game.level_index:
			for encounter in plan: completed.append(encounter.id)
		else:
			if game.level_encounters != plan or game.boss_rule != chosen.rule: return false
			var count: int = game.rival + (1 if game.phase in ["reward", "repair", "shop", "purchase_target", "sticker_choice", "won"] else 0)
			for i in range(count): completed.append(plan[i].id)
	return completed == game.completed_encounters
