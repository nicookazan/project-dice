extends RefCounted
## Versioned local checkpoints. Variant bytes preserve int64 RNG; objects are disabled.
const FORMAT := "dios-no-juega-save"
const VERSION := 6
const BossRules = preload("res://scripts/boss_rules.gd")
const Game = preload("res://scripts/game.gd")
const Validator = preload("res://scripts/save_validator.gd")
const ACTIVE = ["level_intro", "play", "hand_result", "reward", "repair", "shop", "purchase_target", "sticker_choice"]
var path: String
var fail_at := "" # Fault injection for filesystem tests only.

func _init(file_path: String = "user://saves/partida-v1.json") -> void:
	path = ProjectSettings.globalize_path(file_path)

func error(code: String, message: String) -> Dictionary:
	return {"ok": false, "active": false, "code": code, "message": message}

func encode(data: Dictionary) -> String:
	var bytes := var_to_bytes(data)
	return JSON.stringify({"format": FORMAT, "version": VERSION, "sha256": bytes.hex_encode().sha256_text(), "payload": Marshalls.raw_to_base64(bytes)})

func read_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path): return error("missing", "No hay partida guardada.")
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null or file.get_length() > 8000000: return error("read", "No se pudo leer el guardado.")
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary: return error("invalid", "El archivo de guardado está dañado. Se conserva sin cambios.")
	var envelope: Dictionary = parser.data
	if envelope.get("format") != FORMAT: return error("invalid", "Formato de guardado desconocido. Se conserva el archivo.")
	if envelope.get("version") != 1 and envelope.get("version") != 2 and envelope.get("version") != 3 and envelope.get("version") != 4 and envelope.get("version") != 5 and envelope.get("version") != VERSION: return error("version", "El guardado pertenece a otra versión. Se conserva el archivo.")
	if not envelope.get("payload") is String or not envelope.get("sha256") is String: return error("invalid", "Guardado incompleto. Se conserva el archivo.")
	var bytes := Marshalls.base64_to_raw(envelope.payload)
	if bytes.is_empty() or bytes.hex_encode().sha256_text() != envelope.sha256: return error("checksum", "El guardado está dañado. Se conserva el archivo.")
	var data = bytes_to_var(bytes) # Object decoding requires a separate API, never used here.
	if envelope.version == 1:
		if not data is Dictionary or not data.get("game") is Dictionary or data.game.has("boss_rule") or data.game.has("level_encounters"): return error("state", "Guardado v1 inconsistente. Se conserva sin cambios.")
		data = data.duplicate(true)
		data.game["level_encounters"] = BossRules.default_encounters()
		data.game["boss_rule"] = BossRules.NONE.duplicate(true)
	if envelope.version == 1 or envelope.version == 2:
		if not data is Dictionary or not data.get("game") is Dictionary: return error("state", "Guardado anterior incompleto.")
		for key in ["campaign", "level_index", "selected_bosses", "completed_encounters"]:
			if data.game.has(key): return error("state", "Guardado anterior inconsistente; se conserva el archivo.")
		data = data.duplicate(true)
		data.game["campaign"] = []
		data.game["level_index"] = 0
		data.game["selected_bosses"] = {}
		data.game["completed_encounters"] = []
	if envelope.version < 4 and data is Dictionary and data.get("game") is Dictionary and data.game.has("reroll_price"):
		if not data.game.reroll_price is int or data.game.reroll_price < 1: return error("state", "Contador de renovación anterior inválido.")
		data = data.duplicate(true)
		data.game.erase("reroll_price")
		# Historical saves never recorded which zone was renewed. Start the new
		# independent counters at one, preserving wallet, inventory, stock and RNG.
		data.game["reroll_prices"] = {"coins": 1, "components": 1, "numbers": 1, "stickers": 1}
	if envelope.version < 5 and data is Dictionary and data.get("game") is Dictionary and not data.game.has("debug_mode"):
		data = data.duplicate(true)
		data.game["debug_mode"] = false
	if envelope.version < 6 and data is Dictionary and data.get("game") is Dictionary:
		data = data.duplicate(true)
		var migration_error: String = preload("res://scripts/save_migrations.gd").global_numbers(data.game)
		if migration_error != "": return error("state", migration_error)
	var reason: String = Validator.validate(data)
	if reason != "": return error("state", "El guardado contiene un estado inválido: " + reason)
	return {"ok": true, "active": data.game.phase in ACTIVE, "code": "valid", "message": "", "data": data, "source": file_path}

func inspect() -> Dictionary:
	if FileAccess.file_exists(path + ".closed"):
		return {"ok": true, "active": false, "code": "closed", "message": "La partida anterior terminó o fue abandonada."}
	var primary := read_file(path)
	if primary.ok or primary.code == "version": return primary
	var backup := read_file(path + ".bak")
	if backup.ok:
		backup.code = "backup"
		backup.message = "Se puede recuperar el respaldo anterior. El archivo original se conservará."
		return backup
	if primary.code == "missing" and backup.code != "missing": return backup
	return primary

func write_text(file_path: String, content: String) -> bool:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(content)
	file.flush()
	var success := file.get_error() == OK
	file.close()
	return success

func preserve(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path): return true
	return DirAccess.copy_absolute(file_path, file_path + ".preserved-" + str(Time.get_unix_time_from_system()).replace(".", "-") + "-" + str(Time.get_ticks_usec())) == OK

func save(data: Dictionary) -> Dictionary:
	var reason: String = Validator.validate(data)
	if reason != "": return error("state", "No se pudo guardar: " + reason)
	if data.game.phase not in ACTIVE: return error("closed", "La partida no está activa.")
	var existing := inspect()
	if existing.code == "closed": return error("closed", "La partida terminó. Iniciá una nueva partida para volver a guardar.")
	if existing.code in ["backup", "version"] or (not existing.ok and existing.code != "missing"):
		return error("protected", "El guardado requiere recuperación o una nueva partida explícita. Se conserva sin cambios.")
	if fail_at == "before_write": return error("write", "No se pudo escribir el guardado. El último guardado sigue disponible.")
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK: return error("write", "No se pudo crear la carpeta del guardado.")
	if not write_text(path + ".tmp", encode(data)) or not read_file(path + ".tmp").ok:
		return error("write", "No se pudo verificar el archivo temporal. El último guardado se conserva.")
	if fail_at == "after_temp": return error("write", "Escritura interrumpida antes de reemplazar el guardado.")
	if FileAccess.file_exists(path):
		if DirAccess.copy_absolute(path, path + ".bak.tmp") != OK or not read_file(path + ".bak.tmp").ok:
			return error("backup_write", "No se pudo crear el respaldo. El guardado original se conserva.")
		if DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak") != OK: return error("backup_write", "No se pudo publicar el respaldo.")
	if fail_at == "after_backup": return error("write", "Escritura interrumpida; el guardado anterior y su respaldo se conservan.")
	if DirAccess.rename_absolute(path + ".tmp", path) != OK: return error("publish", "No se pudo publicar el guardado; se conserva el anterior.")
	return {"ok": true, "active": true, "code": "saved", "message": "Partida guardada."}

func recover() -> Dictionary:
	var found := inspect()
	if found.code != "backup": return found
	if not preserve(path): return error("preserve", "No se pudo conservar el archivo original; no se modificó.")
	if not write_text(path + ".tmp", encode(found.data)) or not read_file(path + ".tmp").ok: return error("write", "No se pudo preparar la recuperación.")
	if DirAccess.rename_absolute(path + ".tmp", path) != OK: return error("publish", "No se pudo recuperar el respaldo.")
	return read_file(path)

func start(data: Dictionary) -> Dictionary:
	# Explicit New Game: preserve previous files before replacing any of them.
	if Validator.validate(data) != "": return error("state", "La nueva partida no es válida.")
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK: return error("write", "No se pudo crear la carpeta del guardado.")
	for suffix in ["", ".bak", ".closed"]:
		if not preserve(path + suffix): return error("preserve", "No se pudo conservar el guardado anterior.")
	if fail_at != "" or not write_text(path + ".tmp", encode(data)) or not read_file(path + ".tmp").ok:
		return error("write", "No se pudo guardar la nueva partida. Los archivos anteriores se conservan.")
	if DirAccess.rename_absolute(path + ".tmp", path) != OK: return error("publish", "No se pudo publicar la nueva partida.")
	# The first fallback of a new run must never belong to the previous run.
	if DirAccess.copy_absolute(path, path + ".bak") != OK: return error("backup_write", "No se pudo preparar el respaldo de la nueva partida.")
	if FileAccess.file_exists(path + ".closed") and DirAccess.remove_absolute(path + ".closed") != OK: return error("closed", "No se pudo habilitar la nueva partida.")
	return {"ok": true, "active": true, "code": "saved", "message": "Nueva partida guardada."}

func close_session() -> Dictionary:
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK or fail_at != "": return error("write", "No se pudo registrar el fin de la partida.")
	if not write_text(path + ".closed.tmp", "closed-v1") or DirAccess.rename_absolute(path + ".closed.tmp", path + ".closed") != OK:
		return error("write", "No se pudo registrar el fin de la partida.")
	return {"ok": true, "active": false, "code": "closed", "message": "Partida cerrada."}

func restore_game(data: Dictionary):
	if Validator.validate(data) != "": return null
	var game = Game.new(0)
	for key in data.game:
		if key in ["rng_state", "passives", "consumable", "offers", "run_seed"]: continue
		game.set(key, data.game[key].duplicate(true) if data.game[key] is Array or data.game[key] is Dictionary else data.game[key])
	game.run_seed = data.game.run_seed
	game.rng.seed = game.run_seed
	game.rng.state = data.game.rng_state
	# Older stock may contain repeated or already-equipped passive offers.
	# Remove only those slots; do not reroll, charge or touch gameplay RNG.
	game.shop_state = preload("res://scripts/shop.gd").clean_passive_offers(game.shop_state, game.passives)
	return game
