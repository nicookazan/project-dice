extends SubViewport
## TX2 (D16): fondos animados de las ventanas. Presentación pura: no usa el azar de la partida ni toca el guardado.
## Dibuja el panel del ambiente (402×111 px, igual que la hoja de exteriores) más capas animadas encima, y el
## Backdrop recorta las ventanas de esta textura. Con movimiento reducido el Backdrop no la usa y queda el cuadro fijo.
const EXTERIORS = preload("res://assets/art/pixel-v3/exteriores-v3.png")
const SWIRL = preload("res://scripts/window_swirl.gdshader")
const CELL := Vector2i(402, 111)
const W := 401
const H := 110
const PANELS := {"dia": 0, "tarde": 1, "noche": 2, "espacio": 3, "agujero_negro": 4, "cielo": 5}
## Ambientes con animación elegida (D16). «cierre» no se anima.
const ANIMATED := ["dia", "tarde", "noche", "espacio", "agujero_negro", "cielo"]
const GOTHIC_ID := "l3_gotico"

const BIRD := [["x.....x", ".x...x.", "..xxx.."], ["..xxx..", ".x...x.", "x.....x"]]
const DOVE := [["x.......x", ".xx...xx.", "..xxxxx..", "...xxx..."], ["..xxxxx..", "xxxxxxxxx", ".x.xxx.x.", "...xxx..."]]
const BAT := [[".x.....x.", "xxx.x.xxx", ".xxxxxxx.", "..x...x.."], ["x.......x", "xx.xxx.xx", ".xxxxxxx.", "..x...x.."]]
const MINI := ["x.x...x.x", "xxxxxxxxx", ".xxxxxxx.", "..x...x.."]
const ROCKS := [[".bba..", "bbaaab", "bbaabb", ".bbbcc", "..ccc."], [".ba.", "bbab", "bbbc", ".cc."], ["..bbaa..", ".bbaaab.", "bbbaabbb", "bbbbbbcc", ".bbbccc.", "..cccc.."]]
const ROCK_COLORS := {"a": Color("9a84d2"), "b": Color("62508f"), "c": Color("3a2e5c")}

var environment := ""
var gothic := false
var t := 0.0
var panel: Image
var base_rect: TextureRect
var layer: Control
var data: Dictionary = {}

class FxLayer extends Control:
	var fx
	func _draw() -> void:
		if fx != null: fx.draw_layer(self)

static func is_animated(environment_id: String) -> bool:
	return environment_id in ANIMATED

static func is_gothic(profile: Dictionary) -> bool:
	return profile.get("boss_id", "") == GOTHIC_ID and profile.get("actor", "common") not in ["common", "god"]

func _init() -> void:
	size = CELL
	transparent_bg = false
	disable_3d = true
	handle_input_locally = false
	canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	render_target_update_mode = SubViewport.UPDATE_DISABLED

## Prepara el panel y los datos de un ambiente. Se llama solo cuando cambia el ambiente o el jefe.
func setup(environment_id: String, gothic_boss: bool) -> void:
	environment = environment_id
	gothic = gothic_boss and environment_id == "noche"
	t = 0.0
	data = {}
	for child in get_children(): child.queue_free()
	if not PANELS.has(environment_id): return
	var source := EXTERIORS.get_image()
	if source.is_compressed(): source.decompress()
	var index: int = PANELS[environment_id]
	panel = source.get_region(Rect2i(Vector2i(index % 2, index / 2) * CELL, CELL))
	base_rect = TextureRect.new()
	base_rect.texture = ImageTexture.create_from_image(panel)
	base_rect.size = Vector2(CELL)
	base_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base_rect.stretch_mode = TextureRect.STRETCH_SCALE
	base_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	base_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base_rect)
	layer = FxLayer.new()
	layer.fx = self
	layer.size = Vector2(CELL)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(layer)
	_prepare(environment_id)
	update_time(0.0)

func update_time(seconds: float) -> void:
	t = seconds
	if base_rect != null and base_rect.material is ShaderMaterial: base_rect.material.set_shader_parameter("t", t)
	if layer != null: layer.queue_redraw()

# ------------------------------------------------------------------ detección sobre el dibujo aprobado
static func pixels_where(image: Image, test: Callable) -> Array:
	var out: Array = []
	for y in image.get_height():
		for x in image.get_width():
			if test.call(image.get_pixel(x, y), x, y): out.append(Vector2i(x, y))
	return out

static func components(points: Array) -> Array:
	var members := {}
	for p in points: members[p] = true
	var seen := {}
	var out: Array = []
	for p in points:
		if seen.has(p): continue
		seen[p] = true
		var stack: Array = [p]
		var comp: Array = []
		while not stack.is_empty():
			var q: Vector2i = stack.pop_back()
			comp.append(q)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = q + d
				if members.has(n) and not seen.has(n):
					seen[n] = true
					stack.append(n)
		out.append(comp)
	return out

static func centroid(points: Array) -> Vector2:
	var sum := Vector2.ZERO
	for p in points: sum += Vector2(p)
	return sum / maxf(1.0, points.size())

## Elige n puntos separados al menos «gap» entre sí, con un generador propio.
static func pick(points: Array, count: int, seed_value: int, gap: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: Array = []
	var guard := 0
	while out.size() < count and guard < 4000 and not points.is_empty():
		guard += 1
		var p: Vector2i = points[rng.randi() % points.size()]
		var ok := true
		for q in out:
			if Vector2(q).distance_to(Vector2(p)) < gap: ok = false
		if ok: out.append(p)
	return out

static func hash01(n: int) -> float:
	return fposmod(sin(float(n) * 12.9898 + 78.233) * 43758.5453, 1.0)

static func wrap_x(x0: float, speed: float, time: float, width: float) -> float:
	var span := W + width + 8.0
	return fposmod(x0 + speed * time, span) - width - 4.0

static func make_cloud(seed_value: int, width: int, height: int, palette: Array) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var count := 3 + int(rng.randf() * 3)
	var blobs: Array = []
	for i in count:
		var radius := height * (0.3 + rng.randf() * 0.3)
		blobs.append([width * (0.2 + 0.6 * i / float(maxi(count - 1, 1))), height - radius - 1.0 - rng.randf() * height * 0.1, radius])
	for y in height - 1:
		for x in width:
			for b in blobs:
				var dx: float = x - b[0]
				var dy: float = (y - b[1]) * 1.1
				if dx * dx + dy * dy < b[2] * b[2]:
					image.set_pixel(x, y, palette[2] if y >= height - 3 else (palette[1] if y > height * 0.58 else palette[0]))
					break
	return ImageTexture.create_from_image(image)

static func rotate_rows(rows: Array) -> Array:
	var out: Array = []
	for x in rows[0].length():
		var line := ""
		for y in range(rows.size() - 1, -1, -1): line += rows[y][x]
		out.append(line)
	return out

# ------------------------------------------------------------------ preparación por ambiente
func _prepare(id: String) -> void:
	match id:
		"dia":
			var clouds: Array = []
			var config := [[3, 20, 3.0, 4], [40, 36, 5.0, 13], [120, 50, 2.2, 24], [200, 26, 4.0, 34], [300, 40, 6.0, 8]]
			for i in config.size():
				var c: Array = config[i]
				clouds.append({"x": c[0] * 3.0, "w": c[1] + 8, "v": c[2], "y": c[3], "tex": make_cloud(40 + i, c[1] + 8, roundi(c[1] * 0.38) + 4, [Color("ffffff"), Color("d9eaff"), Color("b4cff0")])})
			data["clouds"] = clouds
		"tarde":
			var dark := pixels_where(panel, func(c, x, y): return y > 66 and y < 98 and (c.r + c.g + c.b) * 255.0 < 170.0)
			var ok: Array = []
			for p in dark:
				var below1 := panel.get_pixel(p.x, p.y + 1)
				var below2 := panel.get_pixel(p.x, p.y + 2)
				if (below1.r + below1.g + below1.b) * 255.0 < 170.0 and (below2.r + below2.g + below2.b) * 255.0 < 170.0: ok.append(p)
			var lights := pick(ok, 26, 9, 8.0)
			lights.sort_custom(func(a, b): return a.x < b.x)
			data["lights"] = lights
		"noche":
			var windows: Array = []
			var comps := components(pixels_where(panel, func(c, x, y): return c.r * 255.0 > 190.0 and c.g * 255.0 > 120.0 and c.b * 255.0 < 130.0))
			for comp in comps:
				if comp.size() >= 2: windows.append({"px": comp, "id": windows.size()})
			data["windows"] = windows
			# Estrellas: grupos chicos de píxeles claros. La luna es un grupo grande, así que queda fija.
			var stars: Array = []
			for comp in components(pixels_where(panel, func(c, x, y): return y < 62 and c.r * 255.0 > 175.0 and c.g * 255.0 > 175.0 and c.b * 255.0 > 200.0)):
				if comp.size() <= 6: stars.append({"px": comp, "at": Vector2i(centroid(comp).round())})
			data["stars"] = stars
		"espacio":
			var bright := pixels_where(panel, func(c, x, y): return c.r * 255.0 > 235.0 and c.g * 255.0 > 205.0 and c.b * 255.0 > 205.0 and x > 120 and x < 310 and y > 25 and y < 95)
			var galaxy := centroid(bright) if bright.size() > 8 else Vector2(216, 61)
			data["galaxy"] = galaxy
			var stars: Array = []
			for p in pixels_where(panel, func(c, x, y): return c.r * 255.0 > 200.0 and c.g * 255.0 > 200.0 and c.b * 255.0 > 200.0):
				if Vector2(p).distance_to(galaxy) > 110.0: stars.append(p)
			data["stars"] = stars
			var rng := RandomNumberGenerator.new()
			rng.seed = 77
			var rocks: Array = []
			for i in 9:
				var big: bool = i % 3 == 0
				rocks.append({"kind": rng.randi() % 3, "x": rng.randf() * 500.0, "y": rng.randf() * 90.0, "vx": (9.0 + rng.randf() * 4.0) if big else (3.0 + rng.randf() * 3.0), "vy": (rng.randf() - 0.3) * 2.2, "scale": 2 if big else 1, "rot": rng.randf() * 4.0, "spin": 0.12 + rng.randf() * 0.2})
			data["rocks"] = rocks
			_use_swirl(galaxy, -0.38, 0.36, 100.0, 1.3, 0.3, 0.09)
		"agujero_negro":
			var dark := components(pixels_where(panel, func(c, x, y): return (c.r + c.g + c.b) * 255.0 < 60.0 and x > 60 and x < 340))
			var hole := Vector2(209, 51)
			var best := 0
			for comp in dark:
				if comp.size() > best:
					best = comp.size()
					hole = centroid(comp)
			data["hole"] = hole
			_use_swirl(hole, -0.1, 0.4, 215.0, 1.1, 0.5, 0.05)
		"cielo":
			var clouds: Array = []
			var config := [[0, 60, 2.5, 76], [110, 46, 3.5, 86], [250, 70, 2.0, 92], [330, 52, 4.0, 80]]
			for i in config.size():
				var c: Array = config[i]
				clouds.append({"x": c[0] * 2.0, "w": c[1] + 8, "v": c[2], "y": c[3], "tex": make_cloud(90 + i, c[1] + 8, roundi(c[1] * 0.3) + 6, [Color("fffaf0"), Color("f8e8c0"), Color("e8cf93")])})
			data["clouds"] = clouds
	data["rock_textures"] = _rock_textures() if id == "espacio" else []

func _use_swirl(center: Vector2, tilt: float, ratio: float, rmax: float, omega: float, amp: float, k: float) -> void:
	var material := ShaderMaterial.new()
	material.shader = SWIRL
	material.set_shader_parameter("center", center)
	material.set_shader_parameter("tilt", tilt)
	material.set_shader_parameter("ratio", ratio)
	material.set_shader_parameter("rmax", rmax)
	material.set_shader_parameter("omega", omega)
	material.set_shader_parameter("amp", amp)
	material.set_shader_parameter("k", k)
	material.set_shader_parameter("t", 0.0)
	base_rect.material = material

func _rock_textures() -> Array:
	var out: Array = []
	for rows in ROCKS:
		var versions: Array = []
		var current: Array = rows
		for r in 4:
			var image := Image.create(current[0].length(), current.size(), false, Image.FORMAT_RGBA8)
			for y in current.size():
				for x in current[y].length():
					if current[y][x] != ".": image.set_pixel(x, y, ROCK_COLORS[current[y][x]])
			versions.append(ImageTexture.create_from_image(image))
			current = rotate_rows(current)
		out.append(versions)
	return out

# ------------------------------------------------------------------ dibujo (capa transparente sobre el panel)
func _px(c: CanvasItem, x: float, y: float, w: float, h: float, color: Color) -> void:
	c.draw_rect(Rect2(roundf(x), roundf(y), w, h), color)

func _plus(c: CanvasItem, x: float, y: float, color: Color) -> void:
	_px(c, x - 1, y, 3, 1, color)
	_px(c, x, y - 1, 1, 3, color)

func _sprite(c: CanvasItem, rows: Array, x: float, y: float, color: Color) -> void:
	var ox := roundf(x)
	var oy := roundf(y)
	for j in rows.size():
		for i in rows[j].length():
			if rows[j][i] != ".": c.draw_rect(Rect2(ox + i, oy + j, 1, 1), color)

func draw_layer(c: Control) -> void:
	match environment:
		"dia": _draw_day(c)
		"tarde": _draw_afternoon(c)
		"noche": _draw_night(c)
		"espacio": _draw_space(c)
		"cielo": _draw_sky(c)

func _draw_clouds(c: CanvasItem) -> void:
	for cloud in data.clouds:
		c.draw_texture(cloud.tex, Vector2(roundf(wrap_x(cloud.x, cloud.v, t, cloud.w)), cloud.y))

func _draw_day(c: CanvasItem) -> void:
	_draw_clouds(c)
	var birds := [[10, 16, 16], [120, 26, 20], [250, 12, 14], [330, 32, 22]]
	for k in birds.size():
		var b: Array = birds[k]
		_sprite(c, BIRD[int(t * 6.0 + k) % 2], wrap_x(b[0], b[2], t, 7), b[1] + sin(t * 1.7 + k) * 3.0, Color("22304a"))

func _draw_afternoon(c: CanvasItem) -> void:
	var u := fposmod(t / 26.0, 1.0)
	var lights: Array = data.lights
	for i in lights.size():
		if u > 0.05 + (float(i) / lights.size()) * 0.6 and u < 0.94: _px(c, lights[i].x, lights[i].y, 1, 2, Color("ffd466"))
	var bats := [[20, 40, 26], [160, 28, 32], [280, 50, 22]]
	for k in bats.size():
		var b: Array = bats[k]
		_sprite(c, BAT[int(t * 5.0 + k) % 2], wrap_x(b[0], b[2], t, 9), b[1] + sin(t * 1.3 + k) * 5.0, Color("1a0e2c"))

func _draw_night(c: CanvasItem) -> void:
	for w in data.windows:
		var period: float = (1.6 + hash01(w.id * 7) * 3.4) * 1.8
		var shifted: float = t / period + hash01(w.id * 13) * 10.0
		var cycle := floori(shifted)
		var q := hash01(cycle * 131 + w.id * 17)
		var level := 2
		if q < 0.07: level = 0
		elif q < 0.15: level = 1
		if shifted - cycle < 0.07 and level == 2 and q > 0.5: level = 1
		if level < 2:
			for p in w.px: _px(c, p.x, p.y, 1, 1, Color("241f3d") if level == 0 else Color("8a5a2c"))
	for k in data.stars.size():
		var s: Dictionary = data.stars[k]
		var wave := sin(t * (1.1 + (k % 5) * 0.45) + k * 2.1)
		if wave > 0.88: _plus(c, s.at.x, s.at.y, Color.WHITE)
		elif wave < -0.7:
			for p in s.px: _px(c, p.x, p.y, 1, 1, Color("1c2d66"))
	# Estrella fugaz cada nueve segundos.
	var run := fposmod(t, 9.0) / 1.3
	if run < 1.0:
		var hx := 40.0 + run * 190.0
		var hy := 6.0 + run * 34.0
		for i in 9: _px(c, hx - i * 2.2, hy - i * 1.1, 2, 1, Color(1, 1, 1, (1.0 - i / 9.0) * 0.8))
		_px(c, hx, hy, 2, 2, Color.WHITE)
	if gothic: _draw_signal(c)

func _draw_signal(c: CanvasItem) -> void:
	# Señal chica y lejana: se prende parpadeando, el haz barre apenas y un murciélago cruza por delante.
	var m := fposmod(t + 3.0, 12.0)
	if m < 1.6 or (m < 2.5 and int(t * 7.0) % 2 == 0): return
	# Dentro de la ventana grande (panel x 32–221), a la derecha de la mano del fondo.
	var cx := 178.0 + sin(t * 0.7) * 3.0
	var cy := 20.0
	c.draw_colored_polygon(PackedVector2Array([Vector2(205, 100), Vector2(211, 100), Vector2(cx + 11, cy + 3), Vector2(cx - 11, cy + 3)]), Color(1.0, 0.95, 0.69, 0.10))
	for g in range(3, -1, -1):
		var grow := g * 2
		var color := Color("fff5bd") if g == 0 else Color(1.0, 0.91, 0.54, 0.12 + 0.05 * (3 - g))
		for yy in range(-8 - grow, 9 + grow):
			var half := roundi((15 + grow) * sqrt(maxf(0.0, 1.0 - pow(float(yy) / (8 + grow), 2))))
			_px(c, cx - half, cy + yy, half * 2, 1, color)
	_sprite(c, MINI, cx - 4, cy - 2, Color("14101f"))
	var u := fposmod(t, 14.0) / 4.0
	if u < 1.0: _sprite(c, BAT[int(t * 6.0) % 2], cx - 40.0 + u * 80.0, cy - 6.0 + sin(u * 6.0) * 3.0, Color("0c0818"))

func _draw_space(c: CanvasItem) -> void:
	for k in data.stars.size():
		if sin(t * (1.2 + (k % 4) * 0.5) + k * 1.7) > 0.9: _plus(c, data.stars[k].x, data.stars[k].y, Color.WHITE)
	var textures: Array = data.rock_textures
	for r in data.rocks:
		var texture: ImageTexture = textures[r.kind][int(r.rot + t * r.spin) % 4]
		var wide: float = texture.get_width() * r.scale
		var x := wrap_x(r.x, r.vx, t, wide)
		var y := fposmod(r.y + r.vy * t, H + 10.0) - 5.0
		c.draw_texture_rect(texture, Rect2(roundf(x), roundf(y), wide, texture.get_height() * r.scale), false)

func _draw_sky(c: CanvasItem) -> void:
	for k in range(-4, 5):
		var angle := PI / 2.0 + k * 0.17 + sin(t * 0.35) * 0.05
		var alpha := (0.05 + 0.05 * (0.5 + 0.5 * sin(t * 0.8 + k))) * 0.8
		c.draw_colored_polygon(PackedVector2Array([Vector2(204, -8), Vector2(204 + cos(angle - 0.06) * 190.0, -8 + sin(angle - 0.06) * 190.0), Vector2(204 + cos(angle + 0.06) * 190.0, -8 + sin(angle + 0.06) * 190.0)]), Color(1.0, 0.91, 0.63, alpha))
	_draw_clouds(c)
