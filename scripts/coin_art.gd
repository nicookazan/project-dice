extends TextureRect
## The atlas holds the eight original coins. Every other coin is provisional: a blank coin
## with its abbreviation, until the author approves sketches per family.
const SHEET = preload("res://assets/art/pixel-v3/coins-v3.png")
## Etapa de monedas (MON1): 16 monedas nuevas y 2 paquetes, hoja de 6 × 3 celdas (tools/art/make_coins_nuevas.gd).
## Los ids se usan cuando MON3-MON8 sumen cada moneda al catálogo; hasta entonces solo se dibujan si se piden.
const SHEET_NEW = preload("res://assets/art/pixel-v3/coins-nuevas-v3.png")
const NEW_COLUMNS := 6
const NEW_ROWS := 3
const NEW_IDS = [
	"extra_hand", "reserve_roll", "collector", "level_veteran", "served", "leftovers",
	"reroll_all", "mult_plus2", "points_bag", "flip_die", "two_rolls", "boss_shield",
	"quick_cash", "visit_discount", "repair_all", "even_boost", "pack_small", "pack_large"]
const Coins = preload("res://scripts/coins.gd")
const IDS = ["full", "straight", "generala", "poker", "even", "odd", "boost", "roll"]
const TINTS = {"common": Color("b9864a"), "rare": Color("6e9bd1"), "epic": Color("a76bd4"), "legendary": Color("e0b13c")}
var coin_id := "full"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var index: int = IDS.find(coin_id)
	var sheet: Texture2D = SHEET
	var columns := 4
	var rows := 2
	if index < 0:
		index = NEW_IDS.find(coin_id)
		if index < 0:
			_provisional()
			return
		sheet = SHEET_NEW
		columns = NEW_COLUMNS
		rows = NEW_ROWS
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var cell := Vector2(sheet.get_width() / float(columns), sheet.get_height() / float(rows))
	atlas.region = Rect2(Vector2(index % columns, int(index / float(columns))) * cell, cell)
	texture = atlas
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _provisional() -> void:
	if Coins.DATA.has(coin_id) and not has_node("Provisional"):
		var badge := Control.new()
		badge.name = "Provisional"
		badge.set_anchors_preset(Control.PRESET_FULL_RECT)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.draw.connect(func():
			var center: Vector2 = badge.size / 2.0
			var radius: float = minf(badge.size.x, badge.size.y) * 0.46
			badge.draw_circle(center, radius, TINTS[Coins.rarity_of(coin_id)].darkened(0.45))
			badge.draw_circle(center, radius * 0.86, TINTS[Coins.rarity_of(coin_id)])
			var text: String = Coins.SHORT.get(coin_id, "?")
			var size := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
			badge.draw_string(ThemeDB.fallback_font, center + Vector2(-size.x / 2.0, 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("2a1a0a")))
		add_child(badge)
