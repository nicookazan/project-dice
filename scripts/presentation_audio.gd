extends Node
## Original synthesized PCM. No recordings, external assets or gameplay random draws.
const FAMILIES = ["dice", "club", "ambient", "effects"]
var players: Dictionary = {}
var preferences: Dictionary = {}
var environment := "dia"
var last_cue := ""
static var cache: Dictionary = {}

func _ready() -> void:
	for family in FAMILIES:
		var player := AudioStreamPlayer.new()
		player.name = family.capitalize()
		add_child(player)
		players[family] = player

static func synth(cue: String, environment_id := "dia") -> AudioStreamWAV:
	var key := cue + ":" + environment_id
	if cache.has(key): return cache[key]
	var looped := cue in ["club", "ambient"]
	var duration := 2.0 if looped else 0.30
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var environment_index: int = ["dia", "tarde", "noche", "cierre", "espacio", "agujero_negro", "cielo"].find(environment_id)
	for i in range(count):
		var t := float(i) / rate
		var sample := 0.0
		var noise := fposmod(sin(i * 12.9898 + 78.233) * 43758.5453, 1.0) * 2.0 - 1.0
		if cue == "club": sample = 0.07 * sin(TAU * 60 * t) + 0.025 * sin(TAU * 180 * t)
		elif cue == "ambient":
			var frequency := 100.0 + maxi(0, environment_index) * 20.0
			sample = 0.08 * sin(TAU * frequency * t) + 0.03 * sin(TAU * (frequency * 1.5) * t)
		elif cue in ["roll", "move"]:
			var local := fposmod(t, 0.075 if cue == "roll" else 0.13)
			sample = (noise * 0.42 + sin(TAU * 180 * local) * 0.35) * exp(-local * 65) * maxf(0.0, 1.0 - t / duration)
		else:
			var frequency := 260.0 if cue == "score" else 420.0 if cue == "buy" else 520.0 if cue == "repair" else 180.0 if cue == "break" else 320.0
			sample = (sin(TAU * frequency * t) * 0.26 + sin(TAU * frequency * 1.5 * t) * 0.10) * exp(-t * 15)
			if cue == "break": sample += noise * 0.22 * exp(-t * 25)
		var encoded := int(clampf(sample, -1, 1) * 32767)
		bytes[i * 2] = encoded & 255
		bytes[i * 2 + 1] = (encoded >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = count
	cache[key] = stream
	return stream

func configure(values: Dictionary, environment_id: String) -> void:
	var changed: bool = environment != environment_id
	environment = environment_id
	preferences = values.duplicate()
	for family in players:
		var volume: float = preferences.get(family + "_volume", 0.5)
		players[family].volume_db = linear_to_db(maxf(0.00001, volume))
		if preferences.get("muted", false) or volume == 0: players[family].stop()
	for family in ["club", "ambient"]:
		if preferences.get("muted", false) or preferences.get(family + "_volume", 0.0) == 0 or DisplayServer.get_name() == "headless": continue
		if changed or not players[family].playing:
			players[family].stream = synth(family, environment)
			players[family].play()

func cue(name_value: String) -> void:
	last_cue = name_value
	var family := "dice" if name_value in ["roll", "move"] else "effects"
	if preferences.get("muted", false) or preferences.get(family + "_volume", 0.0) <= 0 or DisplayServer.get_name() == "headless": return
	players[family].stream = synth(name_value, environment)
	players[family].play()
