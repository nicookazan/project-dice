extends TextureRect
## TX9 (D17): las 75 monedas del catálogo y los dos paquetes, en ficha esmaltada. Una sola hoja de 11 columnas de celdas de
## 32 × 32 px lógicos (tools/art/make_coins_v4.py). El orden de ALL_IDS es el de Coins.DATA más los dos paquetes; una prueba
## lo compara, así que una moneda nueva hace fallar la suite hasta que tenga celda.
const SHEET = preload("res://assets/art/pixel-v3/coins-v4.png")
const COLUMNS := 11
const ROWS := 7
const ALL_IDS = [
	"full", "straight", "generala", "poker", "even", "odd", "pair_mult", "twopair_mult", "trio_mult", "pair_pts",
	"twopair_pts", "trio_pts", "straight_pts", "full_pts", "poker_pts", "generala_pts", "flat_mult", "spent", "gold",
	"extra_roll_perm", "free_renewal", "metal", "elemental", "gems", "straight4", "wildcard", "free_reroll",
	"pair_double", "num_1", "num_2", "num_3", "num_4", "num_5", "num_6", "sixes", "first_roll", "unused_rolls",
	"last_roll", "second_hand", "thermos", "collection", "interest", "pocket", "pocket_small", "discount",
	"tempered_gem", "jeweler", "veteran", "accumulated", "streak", "bosshunter", "reserve_roll", "collector",
	"level_veteran", "served", "leftovers", "extra_hand", "boost", "roll", "boost_25", "boost_36", "double_mult",
	"free_renewal_use", "repair_gem", "free_reroll_use", "mult_plus2", "points_bag", "two_rolls", "quick_cash",
	"visit_discount", "repair_all", "even_boost", "reroll_all", "flip_die", "boss_shield", "pack_small", "pack_large"]
const Coins = preload("res://scripts/coins.gd")
const TINTS = {"common": Color("b9864a"), "rare": Color("6e9bd1"), "epic": Color("a76bd4"), "legendary": Color("e0b13c")}
var coin_id := "full"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var index: int = ALL_IDS.find(coin_id)
	if index < 0:
		_provisional()
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	var cell := Vector2(SHEET.get_width() / float(COLUMNS), SHEET.get_height() / float(ROWS))
	atlas.region = Rect2(Vector2(index % COLUMNS, int(index / float(COLUMNS))) * cell, cell)
	texture = atlas
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

## Solo para ids que no están en la hoja (no debería pasar con el catálogo actual): ficha lisa con la abreviatura.
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
