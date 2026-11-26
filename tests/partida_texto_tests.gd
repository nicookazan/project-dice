extends RefCounted
## PS1 (D20): en la interfaz se dice «partida», no «jugada». «Jugada» solo queda cuando significa una combinación de
## dados (jugadas posibles, «toda jugada de Trío»). El metaprogreso se llama «progreso», no «partida guardada».
## Barre las cadenas entre comillas de los scripts del juego (no los comentarios).

## Cadenas que pueden decir «jugada» porque hablan de combinaciones de dados.
const ALLOWED := ["Mostrar jugadas posibles", "toda jugada de", "jugada posible", "jugadas posibles"]

static func run(check: Callable) -> void:
	var offenders: Array = []
	var old_names: Array = []
	var dir := DirAccess.open("res://scripts")
	for file_name in dir.get_files():
		if not file_name.ends_with(".gd") or file_name in ["save_store.gd", "save_validator.gd", "save_migrations.gd"]: continue
		var lines := FileAccess.get_file_as_string("res://scripts/" + file_name).split("\n")
		for index in lines.size():
			var line: String = lines[index].strip_edges()
			if line.begins_with("#"): continue
			for text in _strings(line):
				var lower: String = text.to_lower()
				if "jugada" in lower and not ALLOWED.any(func(ok): return ok.to_lower() in lower):
					offenders.append("%s:%d «%s»" % [file_name, index + 1, text])
				if "partida guardada" in lower or "partidas guardadas" in lower:
					old_names.append("%s:%d «%s»" % [file_name, index + 1, text])
	check.call(offenders.is_empty(), "Partida: ningún texto visible dice «jugada» por partida %s" % [offenders])
	# El formato y la carpeta del archivo conservan el nombre viejo para no perder progresos ya guardados.
	old_names = old_names.filter(func(entry): return not ("dios-no-juega-partida-guardada" in entry or "partida-guardada-%d" in entry))
	check.call(old_names.is_empty(), "Partida: el metaprogreso se llama «progreso», no «partida guardada» %s" % [old_names])

static func _strings(line: String) -> Array:
	var found: Array = []
	var regex := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	for match in regex.search_all(line): found.append(match.get_string(1))
	return found
