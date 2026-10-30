extends RefCounted
## Preferences are independent of the run/save format and never use gameplay RNG.
const DEFAULTS = {"muted": false, "dice_volume": 0.65, "club_volume": 0.20, "ambient_volume": 0.25, "effects_volume": 0.50, "speed": 1, "reduced_motion": false, "reduced_flashes": true, "high_contrast": false, "drag_groups": false}
var path: String
var last_error := ""

func _init(file_path := "user://preferences.cfg") -> void:
	path = ProjectSettings.globalize_path(file_path)

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size() != DEFAULTS.size(): return false
	for key in DEFAULTS:
		if not data.has(key): return false
		if DEFAULTS[key] is bool and not data[key] is bool: return false
	for key in ["dice_volume", "club_volume", "ambient_volume", "effects_volume"]:
		if not (data[key] is float or data[key] is int) or not is_finite(float(data[key])) or data[key] < 0 or data[key] > 1: return false
	return data.speed is int and data.speed in [0, 1, 2]

func load_values() -> Dictionary:
	var config := ConfigFile.new()
	if not FileAccess.file_exists(path): return DEFAULTS.duplicate()
	if config.load(path) != OK or config.get_value("presentation", "version", 0) != 1:
		last_error = "No se pudieron leer las preferencias; se conservó el archivo y se usan valores iniciales."
		return DEFAULTS.duplicate()
	var data = config.get_value("presentation", "values", {})
	if data is Dictionary and not data.has("drag_groups"): data["drag_groups"] = false
	if not valid(data):
		last_error = "Preferencias inválidas; se conserva el archivo hasta elegir opciones nuevas."
		return DEFAULTS.duplicate()
	last_error = ""
	return data.duplicate()

func save_values(data: Dictionary) -> bool:
	if not valid(data): return false
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		last_error = "No se pudieron guardar las opciones; siguen aplicadas durante esta sesión."
		return false
	var config := ConfigFile.new()
	config.set_value("presentation", "version", 1)
	config.set_value("presentation", "values", data)
	if config.save(path + ".tmp") != OK or DirAccess.rename_absolute(path + ".tmp", path) != OK:
		last_error = "No se pudieron guardar las opciones; siguen aplicadas durante esta sesión."
		return false
	last_error = ""
	return true
