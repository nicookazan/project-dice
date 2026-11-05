extends SceneTree
## Capturas del paso J07: cuadros del gesto de la mano en un rival. Requiere GPU (sin --headless).
const Campaign = preload("res://scripts/campaign.gd")
const BarProps = preload("res://scripts/bar_props.gd")
const CampaignTests = preload("res://tests/campaign_tests.gd")
var scene

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.speed = 1
	scene.preferences.reduced_motion = false
	root.add_child(scene)
	await process_frame
	scene.game = CampaignTests.advance_model(Campaign.prototype(), 0)
	scene.render()
	scene.background.set_process(false)
	scene.background.props.hand_result = "tijera"
	for f in [0, 3, 8, 14, 17, 19, 24]:
		scene.background.props.elapsed["hand"] = (f + 0.5) * BarProps.SPECS.hand.seconds
		scene.background.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/hand-%02d.png" % f)
	print("HAND REVIEW OK")
	quit(0)
