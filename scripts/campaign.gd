extends RefCounted
## Provisional D07 data for a technical 21-encounter campaign, not final content/balance.
const Boss = preload("res://scripts/boss_rules.gd")
const Catalog = preload("res://scripts/boss_catalog.gd")
const ID := "hasta-dios-jefes-v1"
const NORMAL_REWARD := 8
## La Semilla (docs/LA-SEMILLA.md): encuentro 22, después del guardián del último nivel. Datos provisionales (D07/D11).
const SEED_ID := "la_semilla"
const SEED_NAME := "La Semilla"
## Objetivo = objetivo del guardián × 1,5, redondeado una sola vez (0,5 hacia arriba).
const SEED_TARGET_MULTIPLIER := 1.5
## La mano con el maletín (tienda antes del derrumbe): un ítem por sección gratis; cada tanda nueva cuesta esto, siempre igual.
const SEED_SHOP_RESTOCK_PRICE := 5

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

## `last`: el último nivel suma a La Semilla después de su jefe (el guardián).
static func encounters(level: Dictionary, chosen: Dictionary, last := false) -> Array:
	var plan := [{"id": level.id + "_r1", "kind": "normal", "target": level.targets[0]}, {"id": level.id + "_r2", "kind": "normal", "target": level.targets[1]}, {"id": chosen.id, "kind": "boss", "target": chosen.target}]
	if last: plan.append({"id": SEED_ID, "kind": "seed", "target": seed_target(chosen.target)})
	return plan

static func seed_target(guardian_target: int) -> int:
	return int(floor(guardian_target * SEED_TARGET_MULTIPLIER + 0.5))

## Poder de La Semilla: uno de los jefes que tocaron en la jugada, sorteado con un generador aparte (semilla + "la_semilla").
## No toca el azar principal y da siempre lo mismo para la misma semilla y los mismos jefes.
static func seed_rule(levels: Array, selected: Dictionary, run_seed: int) -> Dictionary:
	var pool: Array = []
	var ids: Array = []
	for index in range(levels.size()):
		if not selected.has(str(index)): continue
		var chosen := candidate(levels[index], selected[str(index)])
		if chosen.is_empty() or chosen.rule.id in ids: continue
		ids.append(chosen.rule.id)
		pool.append(chosen.rule)
	if pool.is_empty(): return {}
	var generator := RandomNumberGenerator.new()
	generator.seed = ("%d:%s" % [run_seed, SEED_ID]).hash()
	return pool[generator.randi_range(0, pool.size() - 1)].duplicate(true)

static func valid_progress(game: Dictionary) -> bool:
	if game.campaign.is_empty(): return game.level_index == 0 and game.selected_bosses.is_empty() and game.completed_encounters.is_empty()
	if not valid(game.campaign) or game.level_index < 0 or game.level_index > 6 or game.selected_bosses.size() != game.level_index + 1: return false
	var completed: Array = []
	for index in range(game.level_index + 1):
		var key := str(index)
		if not game.selected_bosses.get(key) is String: return false
		var chosen := candidate(game.campaign[index], game.selected_bosses[key])
		if chosen.is_empty(): return false
		var plan := encounters(game.campaign[index], chosen, index == game.campaign.size() - 1)
		if index < game.level_index:
			for encounter in plan: completed.append(encounter.id)
		else:
			if game.level_encounters != plan or game.rival >= plan.size(): return false
			# En La Semilla el poder es el sorteado entre los jefes de la jugada; en el resto, el del jefe del nivel.
			var rule: Dictionary = seed_rule(game.campaign, game.selected_bosses, game.run_seed) if plan[game.rival].kind == "seed" else chosen.rule
			if game.boss_rule != rule: return false
			var count: int = game.rival + (1 if game.phase in ["reward", "repair", "lobby", "shop", "purchase_target", "sticker_choice", "coin_choice", "won"] else 0)
			for i in range(count): completed.append(plan[i].id)
	return completed == game.completed_encounters
