extends RefCounted
## El final de La Semilla dibujado sobre el fondo (docs/LA-SEMILLA.md, bocetos aprobados A1 y B1). Lo usa backdrop.gd:
##   «death» (A1): el guardián tiembla, se le abren grietas de luz, destella y se parte en pedazos; salen rayos blancos
##                 semitransparentes desde adentro y al final se agrieta el cielo.
##   «collapse» (B1): grietas desde el techo, caen bloques de madera y revoque que levantan polvo al llegar a la mesa y el
##                 negro baja de arriba hacia abajo; al final asoma la Matrix.
##   etapa «matrix»: negro con columnas de letras que suben y bajan; quedan la mesa, el termo, el mate y el vaso.
## Todo está en píxeles lógicos (2×2 de pantalla). El azar es visual: sale de la semilla, nunca del azar de la jugada.
const GLYPHS = preload("res://assets/art/pixel-v3/semilla/glifos-v1.png")
const DEBRIS = preload("res://assets/art/pixel-v3/semilla/escombros-v1.png")
const DEATH = preload("res://assets/art/pixel-v3/semilla/guardianes-muerte-v1.png")
## Glifos por fila de glifos-v1.png (dígitos, latinas, katakana, armenias) y cuánto sale cada fila.
const GLYPH_COUNTS := [10, 26, 45, 38]
const GLYPH_WEIGHTS := [0.36, 0.36, 0.17, 0.11]
const CELL := Vector2(8, 10)
const HEAD := Color("e4ffe6")
const GREENS := [Color("0a3412"), Color("0f5a1c"), Color("16862a"), Color("2ebc44"), Color("6cf47e")]
const CRACK_DARK := Color("1a0d06")
const CRACK_LIGHT := Color(1, 0.925, 0.784, 0.55)
## Cuadros de 90 ms, como los bocetos.
const FRAME := 0.09
const DEATH_FRAMES := 30
const COLLAPSE_FRAMES := 46
## Victoria contra La Semilla: tiembla todo, la mesa se parte en franjas que caen y la Matrix se apaga.
const ENDING_FRAMES := 50
const TABLE_STRIPS := 6
## Guardián: 124×100 lógicos, centrado donde backdrop.gd lo dibuja.
const GUARDIAN_SIZE := Vector2(124, 100)
const GUARDIAN_ORIGIN := Vector2(271.5, 2.5)
const GUARDIAN_CENTER := Vector2(333.5, 52.5)
const CRACK_STAGES := 8
const PIECES := 24
## Borde de la mesa (lógico): lo que cae se esconde detrás y levanta polvo ahí.
const TABLE_TOP := 137.0

var anim := ""
var t := 0.0
var run_seed := -1
var sky_cracks: Array = []      # [x, y, paso]
var ceiling_cracks: Array = []
var streams: Array = []
var front_noise: PackedFloat32Array = PackedFloat32Array()
var piece_centers: Array = []
var blocks: Array = []
var dust: Array = []
var sim_frame := -1
var rng := RandomNumberGenerator.new()

func setup(seed_value: int) -> void:
	if seed_value == run_seed: return
	run_seed = seed_value
	rng.seed = ("%d:la_semilla:visual" % seed_value).hash()
	sky_cracks = _cracks([GUARDIAN_CENTER], 6, 34, 0.1)
	var tops: Array = []
	for i in 14: tops.append(Vector2(rng.randf_range(0, 720), 0))
	ceiling_cracks = _cracks(tops, 1, 60, 0.05, PI / 2)
	front_noise.resize(720)
	var raw: Array = []
	for x in 720: raw.append(rng.randfn(0, 1))
	for x in 720:
		var sum := 0.0
		for k in range(-12, 13): sum += raw[clampi(x + k, 0, 719)]
		front_noise[x] = sum / 25.0 * 30.0
	streams = []
	for column in int(720 / CELL.x):
		for _i in (1 if rng.randf() < 0.65 else 2):
			streams.append({"c": column, "dir": -1 if rng.randf() < 0.4 else 1, "speed": rng.randf_range(0.25, 0.9),
				"len": rng.randi_range(6, 21), "pos": rng.randf_range(0, 70)})
	piece_centers = []
	var image: Image = DEATH.get_image()
	for row in 3:
		var centers: Array = []
		for p in PIECES:
			var region: Image = image.get_region(Rect2i(int((CRACK_STAGES + 1 + p) * GUARDIAN_SIZE.x), int(row * GUARDIAN_SIZE.y), int(GUARDIAN_SIZE.x), int(GUARDIAN_SIZE.y)))
			var used: Rect2i = region.get_used_rect()
			centers.append(Vector2(used.get_center()) if used.size != Vector2i.ZERO else GUARDIAN_SIZE / 2.0)
		piece_centers.append(centers)

func start(name: String) -> void:
	anim = name
	t = 0.0
	sim_frame = -1
	blocks = []
	dust = []

func stop() -> void:
	anim = ""

## Avanza la animación; devuelve true el cuadro en que termina.
func step(delta: float) -> bool:
	if anim == "": return false
	t += delta
	var frame := int(t / FRAME)
	while sim_frame < frame:
		sim_frame += 1
		if anim == "collapse": _simulate_collapse(sim_frame)
		elif anim == "ending": _simulate_ending(sim_frame)
	var total: int = {"death": DEATH_FRAMES, "collapse": COLLAPSE_FRAMES, "ending": ENDING_FRAMES}.get(anim, 0)
	if frame >= total:
		anim = ""
		return true
	return false

func frame() -> float:
	return t / FRAME

## Temblor de todo el fondo (en píxeles de pantalla, múltiplos de 2).
func shake() -> Vector2:
	var f := int(frame())
	if anim == "death" and f < 16: return Vector2((_hash(f, 1) % 3 - 1) * 2, 0)
	if anim == "ending" and f < 34:
		var amp_end := 3 if f < 22 else 1
		return Vector2((_hash(f, 4) % (amp_end * 2 + 1) - amp_end) * 2, (_hash(f, 5) % (amp_end * 2 + 1) - amp_end) * 2)
	if anim == "collapse" and f < 30:
		var amp := 3 if f < 20 else 1
		return Vector2((_hash(f, 2) % (amp * 2 + 1) - amp) * 2, (_hash(f, 3) % (amp * 2 + 1) - amp) * 2)
	return Vector2.ZERO

# ---------------------------------------------------------------- muerte del guardián (A1)

func draw_death(canvas: CanvasItem, guardian: int) -> void:
	var f := frame()
	var row := clampi(guardian, 0, 2)
	var at := Rect2(GUARDIAN_ORIGIN * 2.0 + shake(), GUARDIAN_SIZE * 2.0)
	if f <= 16:
		var source_col := CRACK_STAGES if f >= 16 else clampi(int((f - 3.0) / 13.0 * CRACK_STAGES), -1, CRACK_STAGES - 1)
		if source_col >= 0: canvas.draw_texture_rect_region(DEATH, at, Rect2(Vector2(source_col, row) * GUARDIAN_SIZE, GUARDIAN_SIZE))
	else:
		var k := f - 16.0
		var fade := clampf(1.0 - maxf(0.0, k - 6.0) / 7.0, 0.0, 1.0)
		for p in PIECES:
			var center: Vector2 = piece_centers[row][p] if row < piece_centers.size() else GUARDIAN_SIZE / 2.0
			var away := (center - GUARDIAN_SIZE / 2.0).normalized()
			var speed := 1.2 + float(_hash(p, row) % 14) / 10.0
			var offset := Vector2(away.x * speed * k, away.y * speed * k - 1.4 * k + 0.18 * k * k).round()
			canvas.draw_texture_rect_region(DEATH, Rect2((GUARDIAN_ORIGIN + offset) * 2.0, GUARDIAN_SIZE * 2.0), Rect2(Vector2(CRACK_STAGES + 1 + p, row) * GUARDIAN_SIZE, GUARDIAN_SIZE), Color(1, 1, 1, fade))
	if f >= 18: draw_cracks(canvas, sky_cracks, (f - 18.0) * 6.0)
	var count := int(6 + minf(f, 14.0) * 0.6)
	var length := 40.0 + minf(f, 15.0) * 5.0
	var alpha := 0.3 + minf(f, 15.0) / 15.0 * 0.25
	if f > 16: alpha *= maxf(0.0, 1.0 - (f - 16.0) / 9.0)
	draw_rays(canvas, GUARDIAN_CENTER, count, length, alpha, f * 0.03)

## Rayos blancos semitransparentes que salen del centro (más fuertes cerca, se apagan en la punta).
func draw_rays(canvas: CanvasItem, center: Vector2, count: int, length: float, alpha: float, turn: float) -> void:
	if alpha <= 0.0: return
	var origin := center * 2.0
	for i in count:
		var angle := turn + float(_hash(i, 11) % 628) / 100.0
		var reach := length * (0.7 + float(_hash(i, 12) % 30) / 100.0) * 2.0
		var half := 0.07
		var points := PackedVector2Array([origin, origin + Vector2.from_angle(angle - half) * reach, origin + Vector2.from_angle(angle + half) * reach])
		canvas.draw_polygon(points, PackedColorArray([Color(1, 1, 1, alpha), Color(1, 1, 1, 0), Color(1, 1, 1, 0)]))

# ---------------------------------------------------------------- grietas

func _cracks(starts: Array, per_start: int, steps: int, branch: float, angle := -1.0) -> Array:
	var points: Array = []
	var pending: Array = []
	for s in starts:
		for k in per_start:
			var a := angle + rng.randfn(0, 0.3) if angle >= 0.0 else k * TAU / per_start + rng.randf_range(0, 0.5)
			pending.append([s.x, s.y, a, 0])
	var branches := 0
	while not pending.is_empty():
		var item: Array = pending.pop_back()
		var x: float = item[0]
		var y: float = item[1]
		var a: float = item[2]
		var step_index: int = item[3]
		for _i in steps:
			a += rng.randfn(0, 0.2)
			var nx := x + cos(a) * 2.5
			var ny := y + sin(a) * 2.5
			for p in _line(Vector2i(roundi(x), roundi(y)), Vector2i(roundi(nx), roundi(ny))):
				if p.x >= 0 and p.x < 720 and p.y >= 0 and p.y < 450: points.append([p.x, p.y, step_index])
			x = nx
			y = ny
			step_index += 1
			if x < 0 or x >= 720 or y < 0 or y >= 450: break
			if rng.randf() < branch and branches < 120:
				branches += 1
				pending.append([x, y, a + (1 if rng.randf() < 0.5 else -1) * rng.randf_range(0.5, 1.1), step_index])
	return points

static func _line(a: Vector2i, b: Vector2i) -> Array:
	var result: Array = []
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	var p := a
	while true:
		result.append(p)
		if p == b: break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			p.x += sx
		if e2 <= dx:
			err += dx
			p.y += sy
	return result

## Grietas hasta el paso `upto` (oscuras, con un brillo corrido un píxel).
func draw_cracks(canvas: CanvasItem, points: Array, upto: float, max_y := TABLE_TOP) -> void:
	for point in points:
		if point[2] > upto or point[1] >= max_y: continue
		canvas.draw_rect(Rect2((Vector2(point[0], point[1]) + Vector2.ONE) * 2.0, Vector2(2, 2)), CRACK_LIGHT)
	for point in points:
		if point[2] > upto or point[1] >= max_y: continue
		canvas.draw_rect(Rect2(Vector2(point[0], point[1]) * 2.0, Vector2(2, 2)), CRACK_DARK)


# ---------------------------------------------------------------- derrumbe (B1)

func _simulate_collapse(f: int) -> void:
	if f >= 4 and f < 34 and _hash(f, 21) % 100 < 85:
		for i in 1 + _hash(f, 22) % 3:
			blocks.append({"x": float(_hash(f, 30 + i) % 730) - 10.0, "y": -20.0, "vy": 1.0 + float(_hash(f, 40 + i) % 20) / 10.0, "cell": _hash(f, 50 + i) % 10})
	var still: Array = []
	for b in blocks:
		b.vy += 0.55
		b.y += b.vy
		if b.y + 18.0 >= TABLE_TOP:
			_puff(b.x + 12.0, TABLE_TOP - 1.0, 5, 24.0)
			continue
		still.append(b)
	blocks = still
	_step_dust()

func _step_dust() -> void:
	var alive: Array = []
	for d in dust:
		d.age += 1
		d.x += d.vx
		d.y += d.vy
		d.size = minf(d.size + 0.12, 3.0)
		if d.age < d.life: alive.append(d)
	dust = alive

func _puff(x: float, y: float, count: int, spread: float) -> void:
	for i in count:
		dust.append({"x": x + rng.randfn(0, spread / 2.0), "y": y + rng.randfn(0, 2.0), "vx": rng.randfn(0, 0.6), "vy": -0.4 + rng.randfn(0, 0.25),
			"size": float(rng.randi_range(0, 2)), "life": rng.randi_range(10, 19), "age": 0})

## Detrás de la mesa: grietas del techo, el negro que baja y los bloques que caen.
func draw_collapse(canvas: CanvasItem) -> void:
	var f := frame()
	draw_cracks(canvas, ceiling_cracks, f * 4.0)
	if f >= 5.0:
		var base := pow(f - 5.0, 1.35) * 2.6
		var x := 0
		while x < 720:
			var depth := clampf(base + front_noise[x], 0.0, TABLE_TOP + 4.0)
			if depth > 0.0: canvas.draw_rect(Rect2(Vector2(x, 0) * 2.0, Vector2(2, depth) * 2.0), Color.BLACK)
			x += 1
	if f >= 34.0: draw_matrix(canvas, int(f) + 30, clampf((f - 34.0) / 10.0, 0.0, 1.0))
	# La luz de donde estaba el guardián se escapa por las grietas mientras se cae el techo.
	draw_rays(canvas, GUARDIAN_CENTER, 12, 90.0 + f * 3.0, 0.45 * clampf(1.0 - (f - 18.0) / 14.0, 0.0, 1.0), f * 0.03)
	for b in blocks:
		canvas.draw_texture_rect_region(DEBRIS, Rect2(Vector2(roundf(b.x), roundf(b.y)) * 2.0, Vector2(24, 18) * 2.0), Rect2(int(b.cell) * 24, 0, 24, 18))

# ---------------------------------------------------------------- victoria (la mesa cae)

## Cuánto bajó (lógicos) la franja `index` de la mesa: cada una se suelta en su momento y cae cada vez más rápido.
func strip_drop(index: int) -> float:
	var delay := 12.0 + float(_hash(index, 61) % 60) / 10.0
	var k := frame() - delay
	return 0.5 * 3.5 * k * k if k > 0.0 else 0.0

## Cuadro de la Matrix (en el reloj del fondo) en que empezó la victoria: desde ahí se acaban las líneas.
var ending_tick := -1

func _simulate_ending(f: int) -> void:
	for i in TABLE_STRIPS:
		var delay := 12.0 + float(_hash(i, 61) % 60) / 10.0
		if f == int(ceil(delay)): _puff(i * 120.0 + 60.0, TABLE_TOP, 6, 100.0)
	_step_dust()

## Delante de la mesa: el polvo que levantan los bloques al llegar.
func draw_dust(canvas: CanvasItem) -> void:
	for d in dust:
		var fade := 1.0 - float(d.age) / float(d.life)
		var cell := clampi(int(d.size), 0, 3)
		var half := 12.0
		canvas.draw_texture_rect_region(DEBRIS, Rect2((Vector2(roundf(d.x), roundf(d.y)) - Vector2(half, half)) * 2.0, Vector2(24, 24) * 2.0), Rect2(cell * 24, 18, 24, 24), Color(1, 1, 1, fade))

# ---------------------------------------------------------------- Matrix

## Columnas de letras: unas suben y otras bajan. `tick` en cuadros de 90 ms; `fade` aparece de a poco.
## `end_tick` (victoria): desde ahí cada columna deja de largar letras, como si se acabara la línea de código; las que
## ya salieron siguen corriendo hasta que la columna queda vacía. Cada columna se corta en su momento.
func draw_matrix(canvas: CanvasItem, tick: int, fade := 1.0, motion := true, end_tick := -1) -> void:
	for cell in matrix_cells(tick, fade, motion, end_tick):
		canvas.draw_texture_rect_region(GLYPHS, cell.rect, cell.source, cell.color)

## Las letras visibles de la Matrix en `tick`: [{rect, source, color}].
func matrix_cells(tick: int, fade := 1.0, motion := true, end_tick := -1) -> Array:
	var cells: Array = []
	var rows := int(450 / CELL.y) + 1
	var period := float(rows + 24)
	var moment := float(tick) if motion else 0.0
	for s in streams:
		var head: float = fmod(float(s.pos) + float(s.speed) * moment, period)
		if s.dir < 0: head = period - head
		var head_row := int(head) - 1 if s.dir > 0 else int(head) - 12
		var first := 0
		if end_tick >= 0:
			# La línea se termina: lo que habría salido después del corte ya no existe y la columna se vacía desde la punta.
			var cut_at := float(end_tick + 10 + _hash(int(s.c), 71) % 16)
			var drained := (moment - cut_at) * maxf(float(s.speed), float(s.len) / 12.0)
			if drained >= float(s.len): continue
			first = maxi(0, ceili(drained))
		for k in range(first, int(s.len)):
			var row: int = head_row - int(s.dir) * k
			if row < 0 or row >= rows: continue
			var share := float(k) / float(s.len)
			var color: Color = HEAD if k == first else GREENS[maxi(0, 4 - int(share * 5.0))]
			color.a = fade * (1.0 if k < first + 2 else maxf(0.25, 1.0 - share))
			var glyph := _glyph(int(s.c), row, int(moment) / (3 + int(s.c) % 4))
			cells.append({"rect": Rect2(Vector2(int(s.c) * CELL.x, row * CELL.y) * 2.0, CELL * 2.0), "source": Rect2(Vector2(glyph.x * CELL.x, glyph.y * CELL.y), CELL), "color": color})
	return cells

## Glifo de una celda: sobre todo números y letras latinas, algo de katakana y de armenias.
func _glyph(column: int, row: int, change: int) -> Vector2i:
	var h := _hash(column * 131 + row, change)
	var pick := float(h % 1000) / 1000.0
	var set_index := 0
	var acc := 0.0
	for i in GLYPH_WEIGHTS.size():
		acc += GLYPH_WEIGHTS[i]
		if pick < acc:
			set_index = i
			break
		set_index = i
	return Vector2i((h / 1000) % GLYPH_COUNTS[set_index], set_index)

func _hash(a: int, b: int) -> int:
	return absi(("%d:%d:%d" % [run_seed, a, b]).hash())
