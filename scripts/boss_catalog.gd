extends RefCounted
## Catálogo de jefes como dato (docs/PLAN-JEFES.md, fase A). Todo número es provisional (D01/D02/D04/D07/D11).
## Objetivo = P del nivel × k redondeado a 5; recompensa = 8 + round((k − 1) × 20), piso 6.
## Dios tiene objetivos fijos de la tabla de prueba y una sola recompensa base.
const PIVOT := [110, 160, 230, 320, 440, 600, 800]
const GOD_LEVEL := 6
const GOD_REWARD := 8
const REWARD_BASE := 8
const REWARD_FLOOR := 6
# kind/target definen la regla que entra a BossRules. "boss_power" apunta a un poder propio del jefe.
# implemented: el poder ya tiene efecto en el motor. Los demás solo se sortean en builds de desarrollo.
const ROWS := [
	{"id": "l1_kioskero", "level": 1, "slot": 1, "name": "El Kioskero", "hand": "Mitones de lana, un billete arrugado y un paquete de chicles", "power": "Impuesto al kiosco", "text": "Cada anotación te cobra $2.", "severity": 1, "k": 1.15, "kind": "boss_power", "target": "kiosk_tax", "implemented": true},
	{"id": "l1_payador", "level": 1, "slot": 2, "name": "El Payador Tramposo", "hand": "Cuero curtido con tientos, un as de espadas entre los dedos", "power": "Con truco no hay generala", "text": "Generala prohibida: no agrupes cinco iguales como generala. Podés formar trío + par.", "severity": 1, "k": 1.20, "kind": "forbid_category", "target": "Generala", "implemented": true},
	{"id": "l1_palomas", "level": 1, "slot": 3, "name": "El Rey de las Palomas", "hand": "Plumas grises, migas de pan y palomas posadas en los dedos", "power": "Dado asustado", "text": "Un dado al azar por mano no se puede conservar en las dos primeras tiradas.", "severity": 2, "k": 1.05, "kind": "boss_power", "target": "scared_die", "implemented": true},
	{"id": "l2_cebador", "level": 2, "slot": 1, "name": "Don Cebador", "hand": "Yerba mate pegada a la piel; sostiene tu termo flotando entre los dedos", "power": "Robo del termo", "text": "Te roba el termo, que flota hacia el cielo y queda suspendido mientras dura el jefe. Sin termo, los stickers no aportan.", "severity": 3, "k": 1.00, "kind": "boss_power", "target": "thermos_theft", "implemented": true},
	{"id": "l2_chamuyero", "level": 2, "slot": 2, "name": "El Chamuyero", "hand": "Anillos y cadenas doradas de bijouterie, un cartel de «oferta»", "power": "No te vendo dos veces lo mismo", "text": "Repetir en la mano 2 la categoría de la mano 1 vale 50 %.", "severity": 2, "k": 1.10, "kind": "boss_power", "target": "no_repeat", "implemented": true},
	{"id": "l2_referi", "level": 2, "slot": 3, "name": "El Referí del Domingo", "hand": "Césped en los nudillos, silbato y tarjeta roja", "power": "Tarjeta roja", "text": "Una moneda al azar (sorteada al entrar al jefe) queda expulsada: sigue en tu inventario pero no aporta ni se puede usar.", "severity": 2, "k": 1.05, "kind": "boss_power", "target": "red_card", "implemented": true},
	{"id": "l3_gotico", "level": 3, "slot": 1, "name": "El Gótico", "hand": "Guante de cuero negro; una luz potente proyectada sobre las nubes de fondo, sin ninguna figura dentro", "power": "Sombra", "text": "El dado más alto de la 1.ª tirada de cada mano queda valiendo 1 hasta relanzarlo.", "severity": 3, "k": 1.00, "kind": "boss_power", "target": "shadow", "implemented": true},
	{"id": "l3_conde", "level": 3, "slot": 2, "name": "El Conde Sed", "hand": "Piel pálida, uñas largas negras, anillo de sello y copa de líquido rojo", "power": "Fuego apagado", "text": "El elemento fuego queda suspendido.", "severity": 2, "k": 1.10, "kind": "boss_power", "target": "fire_out", "implemented": true},
	{"id": "l3_lobizon", "level": 3, "slot": 3, "name": "El Lobizón", "hand": "Pelaje gris y garras, luna llena enorme detrás", "power": "Maldición del séptimo hijo", "text": "Las caras 6 valen 0 de cara (las combinaciones no cambian).", "severity": 3, "k": 0.95, "kind": "boss_power", "target": "seventh_son", "implemented": true},
	{"id": "l4_tahur", "level": 4, "slot": 1, "name": "El Tahúr", "hand": "Fieltro verde de mesa, guante de crupier, fichas y dados cargados", "power": "Dado cargado", "text": "Un dado al azar por mano queda fijo en 1, sin relanzar.", "severity": 3, "k": 0.95, "kind": "boss_power", "target": "loaded_die", "implemented": true},
	{"id": "l4_patovica", "level": 4, "slot": 2, "name": "El Patovica", "hand": "Cuero negro, brazalete STAFF, auricular y soga de terciopelo rojo", "power": "Lista cerrada", "text": "Par y Doble par prohibidos.", "severity": 2, "k": 1.10, "kind": "boss_power", "target": "closed_list", "implemented": true},
	{"id": "l4_payaso", "level": 4, "slot": 3, "name": "El Payaso de la Risa Final", "hand": "Guante blanco con volados rayados, flor que echa agua, sonrisa pintada en la palma", "power": "Cara espejo", "text": "Tras cada tirada, un dado al azar pasa a su cara opuesta (7 − x).", "severity": 2, "k": 1.05, "kind": "boss_power", "target": "mirror_face", "implemented": true},
	{"id": "l5_visitante", "level": 5, "slot": 1, "name": "El Visitante", "hand": "Piel verde lisa y brillante, tres dedos largos con ventosas, luz de rayo tractor en la palma", "power": "Abducción", "text": "Un dado por mano es abducido y no cuenta (juegan cuatro).", "severity": 4, "k": 0.85, "kind": "boss_power", "target": "abduction", "implemented": true},
	{"id": "l5_farolero", "level": 5, "slot": 2, "name": "El Farolero Cósmico", "hand": "Anillo que brilla en verde y crea construcciones de luz sólida (un farol)", "power": "Carga del anillo", "text": "Solo se pueden conservar hasta 3 dados.", "severity": 3, "k": 0.95, "kind": "boss_power", "target": "ring_charge", "implemented": true},
	{"id": "l5_computadora", "level": 5, "slot": 3, "name": "La Computadora de Bordo", "hand": "Placas metálicas y cables; una lente roja en la palma que mira fijo", "power": "Lo siento, no puedo permitirlo", "text": "La categoría anotada en la mano 1 queda bloqueada en la mano 2.", "severity": 2, "k": 1.05, "kind": "boss_power", "target": "board_lock", "implemented": true},
	{"id": "l6_horizonte", "level": 6, "slot": 1, "name": "El Horizonte", "hand": "Materia estirada hacia el agujero negro, brillo naranja de disco de acreción", "power": "Gravedad", "text": "Las caras 5 y 6 valen la mitad de cara.", "severity": 3, "k": 0.95, "kind": "boss_power", "target": "gravity", "implemented": true},
	{"id": "l6_relojero", "level": 6, "slot": 2, "name": "El Relojero del Instante", "hand": "Engranajes y reloj derretido, arena cayendo entre los dedos", "power": "Ruleta del instante", "text": "Cada mano tiene un multiplicador sorteado ×0,5 o ×1,5, visible antes de tirar. Reemplazo de «Tiempo detenido» hasta que existan las monedas activas (F01).", "severity": 1, "k": 1.15, "kind": "boss_power", "target": "time_stop", "implemented": true},
	{"id": "l6_durmiente", "level": 6, "slot": 3, "name": "El Durmiente del Abismo", "hand": "Tentáculos con ventosas, escamas verdes viscosas y un ojo que se abre en la palma", "power": "Locura", "text": "La previsión de puntos se oculta; solo se ve al anotar.", "severity": 1, "k": 1.20, "kind": "boss_power", "target": "madness", "implemented": true},
	{"id": "l7_dios_dados", "level": 7, "slot": 1, "name": "Dios", "hand": "Triángulo con un ojo", "power": "Generala prohibida", "text": "Dios no juega a los dados: la Generala está prohibida.", "severity": 3, "k": 1.0, "fixed_target": 800, "kind": "forbid_category", "target": "Generala", "implemented": true},
	{"id": "l7_dios_metales", "level": 7, "slot": 2, "name": "Dios", "hand": "Triángulo con un ojo", "power": "Metales suspendidos", "text": "Lo terrenal no cuenta: acero y cobre quedan suspendidos.", "severity": 3, "k": 1.0, "fixed_target": 850, "kind": "suspend_material", "target": "all", "implemented": true},
	{"id": "l7_dios_carcasas", "level": 7, "slot": 3, "name": "Dios", "hand": "Triángulo con un ojo", "power": "Carcasas suspendidas", "text": "Ojo que no ve: las carcasas de los puntos quedan suspendidas.", "severity": 3, "k": 1.0, "fixed_target": 900, "kind": "suspend_shell", "target": "all", "implemented": true}
]
# Poderes propios (kind "boss_power") que BossRules acepta como objetivo válido.
const POWERS := ["kiosk_tax", "scared_die", "thermos_theft", "no_repeat", "red_card", "shadow", "fire_out", "seventh_son", "loaded_die", "closed_list", "mirror_face", "abduction", "ring_charge", "board_lock", "gravity", "time_stop", "madness"]

static func rows() -> Array:
	return ROWS.duplicate(true)

static func entry(id: String) -> Dictionary:
	for row in ROWS:
		if row.id == id: return row.duplicate(true)
	return {}

static func of_level(level: int) -> Array:
	return ROWS.filter(func(row): return row.level == level).map(func(row): return row.duplicate(true))

static func round5(value: float) -> int:
	return int(round(value / 5.0)) * 5

static func target_of(row: Dictionary) -> int:
	if row.has("fixed_target"): return row.fixed_target
	return round5(PIVOT[row.level - 1] * row.k)

static func reward_of(row: Dictionary) -> int:
	if row.level == GOD_LEVEL + 1: return GOD_REWARD
	return maxi(REWARD_FLOOR, REWARD_BASE + int(round((row.k - 1.0) * 20.0)))

static func rule_of(row: Dictionary) -> Dictionary:
	return {"id": row.id, "name": row.power, "kind": row.kind, "target": row.target}

static func candidate_of(row: Dictionary) -> Dictionary:
	return {"id": row.id, "name": row.name, "rule": rule_of(row), "target": target_of(row), "base_reward": reward_of(row)}

static func playable(id: String, development: bool) -> bool:
	## Ids fuera del catálogo (campañas de prueba a medida) siempre se pueden sortear.
	var row := entry(id)
	return row.is_empty() or development or row.implemented

static func power_text(id: String) -> String:
	var row := entry(id)
	return "" if row.is_empty() else row.text

static func ready_for_release() -> bool:
	return ROWS.all(func(row): return row.implemented)

static func map_legacy_id(id: String) -> String:
	## prueba_l{n}_{k} (guardado v7) -> id estable por nivel y posición.
	if not id.begins_with("prueba_l"): return id
	var parts := id.trim_prefix("prueba_l").split("_")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int(): return ""
	for row in ROWS:
		if row.level == int(parts[0]) and row.slot == int(parts[1]): return row.id
	return ""
