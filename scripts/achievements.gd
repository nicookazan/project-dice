extends RefCounted
## Logros como datos. Cada logro puede desbloquear monedas (Coins.LOCKED) para la partida guardada que lo consiguió.
const DATA := {
	"tutorial_completed": {"name": "Tutorial completado", "text": "Terminaste el tutorial con el vendedor.", "unlocks": ["vendor_gift"]}}

static func ids() -> Array:
	return DATA.keys()

static func defined(id: String) -> bool:
	return DATA.has(id)

static func name_of(id: String) -> String:
	return DATA.get(id, {}).get("name", id)

## Monedas desbloqueadas por una lista de logros, sin repetidos y solo de las que existen y están bloqueadas.
static func unlocked_coins(achievements: Array) -> Array:
	var result: Array = []
	for id in achievements:
		for coin in DATA.get(id, {}).get("unlocks", []):
			if coin not in result: result.append(coin)
	return result
