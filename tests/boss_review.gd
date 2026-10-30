extends SceneTree
const Tests = preload("res://tests/boss_tests.gd")
const Boss = preload("res://scripts/boss_rules.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
var scene
var prefix := ""

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.campaign_mode = false
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-jefe-"
	scene.game.begin_run(500)
	scene.render()
	await capture("anuncio-conocido")
	scene.game.begin_run(500, Boss.default_encounters(), [Tests.rule("suspend_material", "all")])
	scene.render()
	await capture("anuncio-suspension")
	scene.game = Tests.game_for(Tests.rule("suspend_coin", "even"), 1)
	scene.game.passives = ["even", "odd"]
	Fixture.set_values(scene.game, [4, 4, 1, 2, 3])
	scene.game.form_group([0, 1])
	scene.render()
	await capture("moneda-equipada")
	scene.inspect_coin("even")
	await capture("ficha-moneda")
	scene.detail.hide()
	scene.game = Tests.game_for(Tests.rule("suspend_shell", "all"))
	scene.game.dice[0].shell = "ruby"
	Fixture.set_values(scene.game, [4, 4, 4, 2, 2])
	scene.game.form_group([0, 1, 2])
	scene.game.form_group([3, 4])
	scene.render()
	scene.inspect_die(0)
	await capture("carcasa-sin-riesgo")
	scene.detail.hide()
	scene.show_route()
	await capture("recorrido-regla")
	scene.detail.hide()
	scene.show_detail(scene.game.preview().rows[0])
	await capture("desglose-suspendido")
	scene.detail.hide()
	scene.game = Tests.game_for(Tests.rule("suspend_coin", "roll"))
	scene.game.consumable = "roll"
	scene.render()
	await capture("consumible-bloqueado")
	print("BOSS REVIEW: 8 captures; test definitions, normal pool remains generala only")
	quit()

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
