extends SceneTree
const Tests = preload("res://tests/level_validation_tests.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const Flow = preload("res://tests/level_flow_tests.gd")
const UI = preload("res://tests/interface_tests.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
var scene
var prefix := ""
var failures := 0

func verify(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.campaign_mode = false
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-integral-"
	Tests.folder = "res://test-results/integral-review/" + str(Time.get_ticks_usec())
	Tests.isolate(scene, true)
	scene.game.return_to_menu()
	scene.refresh_save_status()
	scene.render()
	await capture("menu-perfil")
	scene.start_new_run(1)
	await capture("anuncio-perfil")
	Tests.controlled_shop(scene, verify)
	await capture("tienda-mixta")
	# A controlled offer/old shell makes before/after and risk visible for review.
	var offer := Tests.offer_from_profile("shell", "emerald")
	offer.erase("weight")
	offer.offer_id = "review-shell"
	scene.game.shop_state.components.slots[0] = offer
	scene.game.dice[0].shell = "ruby"
	scene.game.dice[0].shell_broken = true
	scene.game.begin_purchase("components", offer.offer_id)
	scene.game.set_purchase_target({"die_id": 0})
	scene.render()
	await capture("reemplazo-y-riesgo")
	Flow.click(scene, "Cancelar compra")
	Tests.buy_controlled(scene, "face", "", verify, 4)
	scene.inspect_die(4)
	await capture("cara-reanudada")
	scene.detail.hide()
	var pack := Tests.offer_from_profile("pack", "choose_one")
	pack.erase("weight")
	pack.effect.erase("pool")
	pack.effect.items = ["trio", "full", "pair_loose"]
	pack.offer_id = "review-pack"
	scene.game.shop_state.stickers.slots[1] = pack
	scene.game.purchase_offer("stickers", pack.offer_id)
	scene.render()
	Tests.reload_ui(scene, verify, "review paid pack")
	await capture("pack-reanudado")
	Flow.click(scene, "Trío · nivel 0 → 1")
	Flow.click(scene, "Ir al siguiente rival →")
	Flow.click(scene, "TIRAR (3)")
	scene.game.global_points = {"4": 10} # Explicit lab fixture to reach the second target.
	Fixture.set_results(scene.game, [4, 4, 4, 2, 2])
	scene.game.form_group([0, 1, 2])
	scene.game.form_group([3, 4])
	scene.render()
	Flow.click(scene, "ANOTAR MANO")
	Flow.click(scene, "Cerrar y cobrar")
	Tests.reload_ui(scene, verify, "review optional repair")
	await capture("reparacion-reanudada")
	Tests.natural_run(scene, 1, true, "won", verify)
	await capture("victoria-natural")
	Tests.natural_run(scene, 0, true, "lost", verify)
	await capture("derrota-natural")
	print("INTEGRAL REVIEW: 9 captures; failures=", failures)
	scene.persistence_enabled = false
	scene.campaign_mode = false
	quit(0 if failures == 0 else 1)

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
