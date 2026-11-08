extends SceneTree
## TX8: capturas de los stickers en calcomanía (nivel 2) y medallón (nivel 10) en la mesa, el álbum y la tienda.
const Tests = preload("res://tests/encounter_choice_tests.gd")
const Stickers = preload("res://scripts/stickers.gd")
var scene
var prefix := ""

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	root.add_child(scene)
	await process_frame
	await create_timer(0.2).timeout
	prefix = "%dx%d-sticker-" % [root.size.x, root.size.y]
	scene.game = Tests.reward_game()
	var index := 0
	for id in Stickers.NAMES:
		scene.game.cup.stickers[id] = 10 if index % 2 == 1 else 2
		index += 1
	scene.game.skip_shop()
	scene.render()
	await capture("mesa")
	scene.open_sticker_book("trio")
	await capture("album")
	scene.sticker_book.hide()
	print("STICKER STYLE REVIEW done")
	quit(0)

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
