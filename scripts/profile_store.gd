extends RefCounted
## Partidas guardadas: tres ranuras de metaprogreso (docs/PARTIDAS-GUARDADAS.md). Guardan estadísticas, logros y monedas
## desbloqueadas; nunca una jugada en curso. Mismo criterio que antes: un archivo inválido jamás se sobrescribe.
const Achievements = preload("res://scripts/achievements.gd")
const Coins = preload("res://scripts/coins.gd")
const FORMAT := "dios-no-juega-partida-guardada"
const VERSION := 1
const SLOTS := 3
const KEYS := ["plays", "wins", "best_level", "achievements", "unlocked_coins"]
## Opcional (no cambia la versión): ya se vio entero el final de La Semilla, así que se puede omitir la animación.
const SEED_FINALE_KEY := "seed_finale_seen"
var directory: String
var fail_at := "" # Inyección de fallos, solo para pruebas.

func _init(dir: String = "user://partidas") -> void:
	directory = ProjectSettings.globalize_path(dir)

static func empty_data() -> Dictionary:
	return {"plays": 0, "wins": 0, "best_level": 0, "achievements": [], "unlocked_coins": []}

static func valid_data(data: Variant) -> bool:
	if not data is Dictionary: return false
	var optional := 1 if data.has(SEED_FINALE_KEY) else 0
	if data.size() != KEYS.size() + optional or (optional == 1 and not data[SEED_FINALE_KEY] is bool): return false
	for key in KEYS:
		if not data.has(key): return false
	for key in ["plays", "wins", "best_level"]:
		if not data[key] is int or data[key] < 0 or data[key] > 1000000: return false
	if data.wins > data.plays or data.best_level > 7: return false
	for key in ["achievements", "unlocked_coins"]:
		if not data[key] is Array: return false
		var seen: Array = []
		for id in data[key]:
			if not id is String or id in seen: return false
			seen.append(id)
	if not data.achievements.all(func(id): return Achievements.defined(id)): return false
	return data.unlocked_coins.all(func(id): return Coins.locked(id))

func path_of(slot: int) -> String:
	return directory.path_join("partida-guardada-%d.json" % slot)

static func valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOTS

func error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}

func encode(data: Dictionary) -> String:
	var body := JSON.stringify(data, "", true)
	return JSON.stringify({"format": FORMAT, "version": VERSION, "sha256": body.sha256_text(), "data": body})

## Lee una ranura: {"ok": true, "exists": false} si no hay archivo; {"ok": true, "exists": true, "data"} si es válido;
## {"ok": false, "code"} si está dañado (el archivo se conserva sin cambios).
func read(slot: int) -> Dictionary:
	if not valid_slot(slot): return error("slot", "Ranura inexistente.")
	var file_path := path_of(slot)
	if not FileAccess.file_exists(file_path): return {"ok": true, "exists": false, "data": empty_data()}
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null or file.get_length() > 100000: return error("read", "No se pudo leer la partida guardada.")
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary: return error("invalid", "La partida guardada está dañada. Se conserva el archivo.")
	var envelope: Dictionary = parser.data
	if envelope.get("format") != FORMAT: return error("invalid", "Formato desconocido. Se conserva el archivo.")
	if envelope.get("version") != VERSION: return error("version", "La partida guardada es de otra versión. Se conserva el archivo.")
	if not envelope.get("data") is String or not envelope.get("sha256") is String or envelope.data.sha256_text() != envelope.sha256: return error("checksum", "La partida guardada está dañada. Se conserva el archivo.")
	var body := JSON.new()
	if body.parse(envelope.data) != OK or not body.data is Dictionary: return error("invalid", "La partida guardada está dañada. Se conserva el archivo.")
	var data: Dictionary = {}
	for key in body.data:
		var value = body.data[key]
		# JSON devuelve números como float: los contadores vuelven a ser enteros.
		data[key] = int(value) if value is float and key in ["plays", "wins", "best_level"] and value == floor(value) else value
	if not valid_data(data): return error("state", "La partida guardada tiene datos inválidos. Se conserva el archivo.")
	return {"ok": true, "exists": true, "data": data}

func slots() -> Array:
	var result: Array = []
	for slot in range(1, SLOTS + 1):
		var found := read(slot)
		found["slot"] = slot
		result.append(found)
	return result

func _write(slot: int, data: Dictionary) -> Dictionary:
	if not valid_data(data): return error("state", "Datos de partida inválidos.")
	if fail_at == "before_write": return error("write", "No se pudo escribir la partida guardada.")
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return error("write", "No se pudo crear la carpeta de partidas.")
	var file_path := path_of(slot)
	var temp := file_path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return error("write", "No se pudo escribir la partida guardada.")
	file.store_string(encode(data))
	file.flush()
	file.close()
	if fail_at == "after_temp": return error("write", "Escritura interrumpida; la partida anterior se conserva.")
	if DirAccess.rename_absolute(temp, file_path) != OK: return error("publish", "No se pudo publicar la partida guardada.")
	return {"ok": true, "data": data}

## Crea una partida vacía. No pisa un archivo existente: si hay uno (válido o no), falla.
func create(slot: int) -> Dictionary:
	if not valid_slot(slot): return error("slot", "Ranura inexistente.")
	if FileAccess.file_exists(path_of(slot)): return error("exists", "Esa ranura ya tiene una partida guardada.")
	return _write(slot, empty_data())

## Primera ranura libre (1–3) o 0 si están todas ocupadas.
func first_free() -> int:
	for slot in range(1, SLOTS + 1):
		if not FileAccess.file_exists(path_of(slot)): return slot
	return 0

## Borra una ranura (la interfaz pide dos confirmaciones antes).
func delete(slot: int) -> Dictionary:
	if not valid_slot(slot): return error("slot", "Ranura inexistente.")
	var file_path := path_of(slot)
	if not FileAccess.file_exists(file_path): return {"ok": true}
	if DirAccess.remove_absolute(file_path) != OK: return error("delete", "No se pudo borrar la partida guardada.")
	return {"ok": true}

## Registra una jugada terminada. `run`: {"won": bool, "level": int (1–7, nivel alcanzado), "tutorial": bool, "debug": bool}.
## La jugada debug no escribe nada; el tutorial terminado no suma jugadas: da el logro (y sus monedas).
## Si la ranura no existe se crea; si está dañada, no se toca.
func record_run(slot: int, run: Dictionary) -> Dictionary:
	if not valid_slot(slot): return error("slot", "Ranura inexistente.")
	if run.get("debug", false): return {"ok": true, "skipped": true}
	var found := read(slot)
	if not found.ok: return found
	var data: Dictionary = found.data.duplicate(true)
	if run.get("tutorial", false):
		if "tutorial_completed" not in data.achievements: data.achievements.append("tutorial_completed")
	else:
		data.plays += 1
		if run.get("won", false): data.wins += 1
		data.best_level = maxi(data.best_level, clampi(int(run.get("level", 0)), 0, 7))
	data.unlocked_coins = Achievements.unlocked_coins(data.achievements)
	return _write(slot, data)

## Marca que ya se vio entero el final de La Semilla. Si la ranura está dañada no se toca.
func mark_seed_finale_seen(slot: int) -> Dictionary:
	if not valid_slot(slot): return error("slot", "Ranura inexistente.")
	var found := read(slot)
	if not found.ok: return found
	var data: Dictionary = found.data.duplicate(true)
	if data.get(SEED_FINALE_KEY, false): return {"ok": true, "data": data}
	data[SEED_FINALE_KEY] = true
	return _write(slot, data)

## Resumen en texto de una ranura para la interfaz.
static func summary(data: Dictionary) -> String:
	var names: Array = data.achievements.map(func(id): return Achievements.name_of(id))
	return "Jugadas: %d · Ganadas: %d · Nivel más alto: %s\nLogros: %s\nMonedas totales: %d · Desbloqueadas: %d" % [
		data.plays, data.wins, str(data.best_level) if data.best_level > 0 else "—", ", ".join(names) if not names.is_empty() else "ninguno", Coins.catalog().size(), Coins.catalog().size() - Coins.LOCKED.size() + data.unlocked_coins.size()]
