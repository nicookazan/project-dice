extends RefCounted
## Panel de elección del paquete de monedas (MON8). Dibuja sobre la tienda con el estilo del panel de stickers y delega
## todas las reglas en Game (`coin_choice_options`, `choose_coin`). No guarda estado: el reemplazo en curso vive en el host.
const Coins = preload("res://scripts/coins.gd")
const ItemTooltip = preload("res://scripts/item_tooltip.gd")

const MODAL := Rect2(110, 120, 1220, 660)
const CARD_HEIGHT := 372.0

static func title_for(pack: Dictionary) -> String:
	return "ELEGÍ UNA MONEDA" if pack.picks == 1 else "ELEGÍ DOS MONEDAS"

## Texto de la carta cerrada de la tienda: no muestra el contenido.
static func closed_text(effect: Dictionary) -> String:
	return "Elegí %d entre %d" % [effect.picks, effect.items.size()]

static func status_text(option: Dictionary, received: bool) -> String:
	if received: return "ELEGIDA"
	if option.direct: return "Entra directo"
	if not option.replace.is_empty(): return "Reemplazá una de las tuyas"
	return "Sin lugar posible"

static func block_reason(instance: Dictionary, pack: Dictionary) -> String:
	if instance.instance_id in pack.received_instances: return "Recién recibida de este paquete."
	return "No se puede sacar: quedarían más monedas que ranuras."

static func build(host) -> Control:
	var game = host.game
	var pack: Dictionary = game.pending_coin_pack
	host.panel(host.ui, Rect2(0, 0, 1440, 900), Color(0.04, 0.06, 0.07, 0.84))
	var modal: Panel = host.panel(host.ui, MODAL, Color.TRANSPARENT)
	modal.name = "CoinChoice"
	modal.add_theme_stylebox_override("panel", ItemTooltip.skin())
	modal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	host.shop_caption(modal, title_for(pack), Rect2(32, 20, MODAL.size.x - 64, 44), 28, host.gold)
	var left: int = pack.picks_left
	host.shop_caption(modal, "Paquete pagado: $%d · Te %s %d %s · Saldo: %s" % [pack.paid, "falta" if left == 1 else "faltan", left, "elección" if left == 1 else "elecciones", host.money_text(game.cash)], Rect2(32, 68, MODAL.size.x - 64, 30), 17)
	var options: Array = game.coin_choice_options()
	var replacing: String = host.coin_pack_replacing
	var chosen_option := {}
	for option in options:
		if option.id == replacing: chosen_option = option
	if replacing != "" and (chosen_option.is_empty() or chosen_option.direct or chosen_option.replace.is_empty()):
		host.coin_pack_replacing = ""
		replacing = ""
	if replacing != "": _build_replacement(host, modal, pack, chosen_option)
	else: _build_cards(host, modal, pack, options)
	host.button(modal, "Cerrar panel", Rect2(64, MODAL.size.y - 66, MODAL.size.x - 128, 42), func():
		host.pack_panel_open = false
		host.coin_pack_replacing = ""
		host.render())
	return modal

static func _build_cards(host, modal: Control, pack: Dictionary, options: Array) -> void:
	var by_id := {}
	for option in options: by_id[option.id] = option
	var count: int = pack.items.size()
	var card_w := 232.0 if count <= 2 else 208.0
	var gap := 14.0
	var x0: float = (MODAL.size.x - (count * card_w + (count - 1) * gap)) / 2.0
	for index in range(count):
		var id: String = pack.items[index]
		var option: Dictionary = by_id.get(id, {"id": id, "direct": false, "replace": [], "blocked": []})
		var data := Coins.definition(id)
		var received: bool = id in pack.received
		var playable: bool = not received and (option.direct or not option.replace.is_empty())
		var card: Button = host.button(modal, "", Rect2(x0 + index * (card_w + gap), 112, card_w, CARD_HEIGHT), func():
			if option.direct: host.act(func(): host.game.choose_coin(id))
			else:
				host.coin_pack_replacing = id
				host.render(), not playable)
		card.name = "PackCoin_" + id
		for mode in ["normal", "hover", "pressed", "disabled"]:
			var border: Color = host.gold if mode in ["hover", "pressed"] else Color("785335")
			var fill: Color = Color("153c50") if mode in ["hover", "pressed"] else Color("091923")
			if mode == "disabled": fill = Color("141a20")
			card.add_theme_stylebox_override(mode, host.box(fill, border, 2))
		host.add_coin(card, id, Rect2(card_w / 2.0 - 44, 12, 88, 88))
		host.shop_caption(card, data.name, Rect2(6, 104, card_w - 12, 28), 18, host.gold)
		host.shop_caption(card, "%s · %s · %s" % [data.code, Coins.RARITY_NAMES[data.rarity], "Pasiva" if data.type == "passive" else "Un uso"], Rect2(6, 134, card_w - 12, 22), 13)
		var effect: Label = host.label(card, data.description, Vector2(12, 162), 13, host.cream, card_w - 24)
		effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect.size.y = 150
		effect.clip_text = true
		host.shop_caption(card, status_text(option, received), Rect2(6, CARD_HEIGHT - 50, card_w - 12, 24), 14, Color("8ae6f2") if playable else Color("c6ac88"))
		card.tooltip_text = "%s\n%s" % [data.name, data.description]

static func _build_replacement(host, modal: Control, pack: Dictionary, option: Dictionary) -> void:
	var game = host.game
	var incoming := Coins.definition(option.id)
	host.shop_caption(modal, "No tenés lugar para %s: elegí cuál de tus monedas %s reemplaza." % [incoming.name, "de un uso" if incoming.type == "consumable" else "pasivas"], Rect2(32, 104, MODAL.size.x - 64, 30), 18, host.gold)
	var owned: Array = game.coin_inventory.equipped if incoming.type == "passive" else game.coin_inventory.consumables
	var columns := 3
	var width := 372.0
	var height := 84.0
	var x0: float = (MODAL.size.x - (columns * width + (columns - 1) * 14)) / 2.0
	for index in range(owned.size()):
		var instance: Dictionary = owned[index]
		var coin: Dictionary = Coins.definition(instance.coin_id)
		var instance_id: int = instance.instance_id
		var legal: bool = instance_id in option.replace
		var pos := Vector2(x0 + (index % columns) * (width + 14), 146 + (index / columns) * (height + 10))
		var row: Button = host.button(modal, "", Rect2(pos, Vector2(width, height)), func():
			host.coin_pack_replacing = ""
			host.act(func(): host.game.choose_coin(option.id, instance_id)), not legal)
		row.name = "ReplaceCoin_%d" % instance_id
		for mode in ["normal", "hover", "pressed", "disabled"]:
			var border: Color = host.gold if mode in ["hover", "pressed"] else Color("785335")
			row.add_theme_stylebox_override(mode, host.box(Color("153c50") if mode in ["hover", "pressed"] else (Color("141a20") if mode == "disabled" else Color("091923")), border, 2))
		host.add_coin(row, instance.coin_id, Rect2(10, 12, 60, 60))
		host.shop_caption(row, coin.name, Rect2(80, 8, width - 90, 26), 17, host.gold if legal else Color("c6ac88"))
		if legal: host.shop_caption(row, "Sale por $%d de reventa" % coin.resale, Rect2(80, 38, width - 90, 36), 14)
		else:
			var reason: Label = host.label(row, block_reason(instance, pack), Vector2(80, 34), 12, Color("c6ac88"), width - 90)
			reason.size.y = 46
	var back: Button = host.button(modal, "Volver a las monedas del paquete", Rect2(64, MODAL.size.y - 118, MODAL.size.x - 128, 42), func():
		host.coin_pack_replacing = ""
		host.render())
	back.name = "ReplaceBack"
