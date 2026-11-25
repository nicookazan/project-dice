extends RefCounted
## Guion del tutorial como datos (docs/TUTORIAL.md). Nada de esto toca el azar de las jugadas normales:
## las tiradas guionadas, la semilla de la tienda y el jefe vendedor solo se usan con `Game.tutorial`.
const ENCOUNTERS := [
	{"id": "tutorial_r1", "kind": "normal", "target": 40},
	{"id": "tutorial_r2", "kind": "normal", "target": 70},
	{"id": "tutorial_vendedor", "kind": "boss", "target": 125}]
## Plata con la que se entra a la tienda guiada.
const SHOP_CASH := 20
## Semilla fija de la tienda del tutorial (se busca con tools/tutorial_shop_seeds.gd; el autor puede cambiarla).
const SHOP_SEED := 2
## Tiradas guionadas del primer encuentro: [mano][tirada] = valores que salen, para los dados que se tiran, en orden de id.
## Mano 1: 4 4 2 6 3 → se conservan los 4 y se tiran los otros tres → 4 1 5 → trío de cuatros.
## Mano 2: 6 6 3 3 2 → se tira el último dado → 3 → full.
const ROLLS := [[[4, 4, 2, 6, 3], [4, 1, 5]], [[6, 6, 3, 3, 2], [3]]]

## Zonas de la pantalla (coordenadas lógicas 1440 × 900) a las que apuntan los carteles.
const ZONES := {
	"roll": Rect2(1082, 681, 312, 47), "group": Rect2(375, 681, 210, 47), "to_cup": Rect2(597, 681, 157, 47),
	"score": Rect2(40, 681, 292, 47), "table": Rect2(712, 324, 350, 330), "cup": Rect2(1082, 324, 358, 330),
	"groups": Rect2(366, 324, 330, 330), "notebook": Rect2(22, 25, 310, 630), "boss_hand": Rect2(560, 20, 330, 160),
	"close": Rect2(375, 626, 236, 42), "next_hand": Rect2(725, 626, 262, 42), "choice_shop": Rect2(338, 565, 366, 56),
	"payout_continue": Rect2(782, 510, 232, 56), "lobby_shop": Rect2(762, 430, 272, 58), "lobby_play": Rect2(384, 430, 276, 58),
	"inventory": Rect2(40, 740, 700, 130), "thermos": Rect2(1180, 130, 220, 260), "advance": Rect2(1025, 25, 380, 93),
	"numbers": Rect2(538, 252, 367, 179), "components": Rect2(929, 252, 388, 179), "coins": Rect2(525, 442, 380, 179),
	"stickers": Rect2(929, 442, 401, 179), "cash": Rect2(518, 30, 193, 80), "seller": Rect2(60, 160, 440, 470)}

static func rolls_for(hand: int, roll_number: int, count: int) -> Array:
	## Valores guionados para la tirada `roll_number` (0 = primera) de la mano `hand` (1 = primera), o [] si no hay.
	if hand < 1 or hand > ROLLS.size() or roll_number < 0 or roll_number >= ROLLS[hand - 1].size(): return []
	var values: Array = ROLLS[hand - 1][roll_number]
	return values.duplicate() if values.size() == count else []

static func note(text: String, zone: String, side := "right") -> Dictionary:
	return {"text": text, "zone": zone, "side": side}

## Paso actual según el estado visible. `ctx`: phase, rival, hand, rolls_made, grouped (cantidad de grupos), cup (ids en el vaso),
## selected (ids elegidos), points, target, boss (el encuentro es el jefe), shop_visited.
## Devuelve {} si no hay guía. `allow` lista las acciones que el paso deja hacer; `select` la selección que espera.
static func step(ctx: Dictionary) -> Dictionary:
	var phase: String = ctx.get("phase", "")
	var rival: int = ctx.get("rival", 0)
	if phase == "level_intro":
		return {"id": "intro", "notes": [], "allow": ["begin"], "select": []}
	if rival == 0 and phase == "play":
		return _first_encounter(ctx)
	if rival == 0 and phase == "hand_result":
		if int(ctx.points) >= int(ctx.target):
			return {"id": "close_1", "notes": [note("Llegaste al objetivo. Cerrá el encuentro para cobrar.", "close", "above")], "allow": ["close"], "select": []}
		return {"id": "next_hand_1", "notes": [note("Todavía no llegaste al objetivo: jugá la segunda mano.", "next_hand", "above")], "allow": ["next_hand"], "select": []}
	if rival == 0 and phase == "reward":
		return {"id": "reward_1", "notes": [note("Ganaste y cobraste. Tocá Continuar.", "payout_continue", "above")], "allow": ["continue"], "select": []}
	if rival == 0 and phase == "lobby" and not ctx.get("shop_visited", false):
		return {"id": "lobby_shop_1", "notes": [note("Antes de seguir, pasá por la tienda: ahí se compran las mejoras.", "lobby_shop", "above")], "allow": ["open_shop"], "select": []}
	if rival == 0 and phase == "lobby":
		return {"id": "lobby_play_1", "notes": [note("Podés volver a la tienda las veces que quieras. Cuando estés listo, jugá contra el siguiente rival.", "lobby_play", "above")], "allow": ["play_next", "open_shop"], "select": []}
	if phase == "shop" and rival == 0: return _shop()
	if rival == 2 and phase == "play" and int(ctx.get("hand", 1)) == 1 and int(ctx.get("rolls_made", 0)) == 0:
		return {"id": "boss_intro", "notes": [
			note("Cada jefe tiene una mecánica propia. Esta es la del vendedor: al terminar te saca toda la plata.", "notebook"),
			note("Tocá la mano del jefe para ver su poder en cualquier momento.", "boss_hand", "below")], "blocking": true, "allow": ["all"], "select": []}
	return {}

static func _first_encounter(ctx: Dictionary) -> Dictionary:
	var hand: int = ctx.hand
	var rolls_made: int = ctx.rolls_made
	var cup: Array = ctx.cup
	var selected: Array = ctx.selected
	var grouped: int = ctx.grouped
	if rolls_made == 0:
		var intro := [note("Este es tu objetivo: sumar 40 puntos en dos manos.", "notebook"), note("Los cinco dados esperan en el vaso. Tirá.", "roll", "above")]
		return {"id": "h%d_roll_0" % hand, "notes": intro if hand == 1 else [note("Segunda mano: tirá de nuevo los cinco dados.", "roll", "above")], "allow": ["roll"], "select": []}
	if grouped > 0:
		return {"id": "h%d_score" % hand, "notes": [note("Con el grupo armado, anotá la mano: la previsión de la libreta es exactamente lo que vas a sumar.", "score", "above")], "allow": ["score"], "select": []}
	var keep_ids: Array = [0, 1] if hand == 1 else [0, 1, 2, 3]
	var throw_ids: Array = [2, 3, 4] if hand == 1 else [4]
	if rolls_made == 1:
		if cup.is_empty():
			var text := "Elegí los dados que querés volver a tirar. Los dos 4 se quedan: tocá los otros tres y mandalos al vaso." if hand == 1 else "Vamos por un full: tocá el dado suelto (el último) para tirarlo de nuevo y mandalo al vaso."
			if Array(selected).size() > 0 and selection_matches(throw_ids, selected):
				return {"id": "h%d_to_cup" % hand, "notes": [note("Listo. Apretá «Al vaso →» o arrastrá esos dados al vaso, a la derecha.", "to_cup", "above")], "allow": ["select", "to_cup"], "select": throw_ids, "to_cup_select": throw_ids, "highlight": throw_ids, "glow_zones": ["to_cup", "cup"]}
			return {"id": "h%d_select_throw" % hand, "notes": [note(text, "table", "above")], "allow": ["select", "to_cup"], "select": throw_ids, "to_cup_select": throw_ids, "highlight": throw_ids}
		return {"id": "h%d_roll_1" % hand, "notes": [note("Ya están en el vaso. Tirá otra vez: los dados que dejaste en la mesa se conservan.", "roll", "above")], "allow": ["roll"], "select": []}
	var group_ids: Array = [0, 1, 2] if hand == 1 else [0, 1, 2, 3, 4]
	var group_text := "Salió otro 4: tenés un trío. Armalo con esos tres dados." if hand == 1 else "¡Salió el 3! Tenés tres 3 y dos 6: un full. Armalo con los cinco dados."
	return {"id": "h%d_group" % hand, "notes": [note(group_text, "table", "above"), note("Se arma tocando la jugada posible de la izquierda (%s), o eligiendo los dados y apretando Armar grupo." % ("Trío" if hand == 1 else "Full"), "groups", "left")], "allow": ["select", "group"], "select": group_ids, "group_select": group_ids, "highlight": group_ids, "glow_zones": ["play_first", "group"]}

static func _shop() -> Dictionary:
	return {"id": "shop", "notes": [
		note("Acá comprás mejoras con la plata que cobraste. Tenés $%d." % SHOP_CASH, "cash", "below"),
		note("Stickers: potencian una categoría y se pegan en el termo.", "stickers", "below"),
		note("Números y caras: mejoran un número o cambian una cara de un dado.", "numbers", "left"),
		note("Componentes: gemas, elementos y materiales, para uno de tus cinco dados.", "components", "above"),
		note("Monedas: pasivas que cambian las reglas, o de un solo uso. Podés vender las tuyas arrastrándolas al maletín.", "coins", "left")], "blocking": true, "allow": ["all"], "select": []}

## ¿La acción está permitida en este paso? "all" deja todo; sin paso (o sin notas esperadas) no se bloquea nada.
static func allows(current: Dictionary, action: String) -> bool:
	if current.is_empty(): return true
	var allowed: Array = current.get("allow", [])
	return "all" in allowed or action in allowed

## ¿La selección actual coincide con la que espera el paso (sin importar el orden)?
static func selection_matches(expected: Array, selected: Array) -> bool:
	if expected.size() != selected.size(): return false
	var a := expected.duplicate()
	var b := selected.duplicate()
	a.sort()
	b.sort()
	return a == b
