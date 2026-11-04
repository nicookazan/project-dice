extends RefCounted
## Texto de inspección de la mano del fondo (plan de jefes, fase B). Puro: lee el estado y el catálogo, no muta nada.
const Catalog = preload("res://scripts/boss_catalog.gd")
const Campaign = preload("res://scripts/campaign.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const Coins = preload("res://scripts/coins.gd")

## Datos del jefe del nivel actual, aunque el encuentro actual sea un rival.
static func boss_entry(game) -> Dictionary:
	if not game.campaign.is_empty() and game.selected_bosses.has(str(game.level_index)):
		var chosen: Dictionary = Campaign.candidate(game.campaign[game.level_index], game.selected_bosses[str(game.level_index)])
		if not chosen.is_empty(): return {"name": chosen.name, "rule": chosen.rule, "target": chosen.target, "reward": chosen.base_reward}
	for encounter in game.level_encounters:
		if encounter.kind == "boss": return {"name": "Jefe", "rule": game.boss_rule, "target": encounter.target, "reward": Campaign.NORMAL_REWARD}
	return {}

static func power_text(rule: Dictionary) -> String:
	var row := Catalog.entry(rule.get("id", ""))
	return row.text if not row.is_empty() else BossRules.description(rule)

static func is_god(game) -> bool:
	return not game.campaign.is_empty() and game.level_index == game.campaign.size() - 1

static func draw_text(game, rule: Dictionary) -> String:
	## Resultado de los sorteos propios del jefe, solo cuando ya ocurrieron.
	if BossRules.is_power(rule, "red_card") and game.is_boss():
		var coin: String = game.boss_state.get("coin", "")
		if coin == "": return "Expulsada: ninguna (no tenés monedas equipadas)."
		return "Expulsada: " + str(Coins.definition(coin).get("name", coin))
	return ""

static func boss_lines(game, entry: Dictionary) -> Array[String]:
	var lines: Array[String] = ["Poder: " + str(entry.rule.get("name", "")), power_text(entry.rule)]
	lines.append("Objetivo: %d puntos · Recompensa base: $%d" % [entry.target, entry.reward])
	var drawn := draw_text(game, entry.rule)
	if drawn != "": lines.append(drawn)
	return lines

## {"title", "text", "alt"} del panel que abre la mano. Vacío si no hay nada que mostrar.
static func panel(game) -> Dictionary:
	var entry := boss_entry(game)
	if entry.is_empty(): return {}
	if game.is_boss():
		var lines := boss_lines(game, entry)
		var title: String = "Dios" if is_god(game) else entry.name
		var alt := "%s · %s. Tocá la mano para ver el poder." % [title, entry.rule.name]
		return {"title": title, "text": "\n".join(lines), "alt": alt}
	var rival_lines: Array[String] = ["Rival común: objetivo %d." % game.target(), "", "Próximo jefe: %s · %s" % [entry.name, entry.rule.get("name", "")]]
	rival_lines.append_array(boss_lines(game, entry))
	return {"title": "Rival común", "text": "\n".join(rival_lines), "alt": "Rival común: objetivo %d. Próximo jefe: %s. Tocá la mano para ver el poder." % [game.target(), entry.name]}
