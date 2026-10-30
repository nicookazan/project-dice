extends SceneTree
const Tests = preload("res://tests/campaign_tests.gd")
const Campaign = preload("res://scripts/campaign.gd")
const Preferences = preload("res://scripts/presentation_preferences.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
var scene
var prefix := ""
var failures: Array = []

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-presentacion-"
	for level in range(7):
		scene.game = Tests.advance_model(Campaign.prototype(), level * 3 + 2)
		scene.render()
		await capture(scene.game.environment_id())
	# Common opponent, not just bosses.
	scene.game = Tests.advance_model(Campaign.prototype(), 0)
	scene.render()
	await capture("rival-comun")
	scene.act(scene.game.roll)
	await capture("tirada")
	var before: Dictionary = scene.game.snapshot()
	scene.show_options()
	scene.settings_panel.get_node("reduced_motion").button_pressed = true
	scene.settings_panel.get_node("high_contrast").button_pressed = true
	scene.settings_panel.get_node("AnimationSpeed").select(0)
	scene.settings_panel.get_node("AnimationSpeed").item_selected.emit(0)
	await capture("opciones")
	if scene.game.snapshot() != before or scene.background.motion: failures.append("Options changed gameplay or instant mode still moves")
	scene.detail.hide()
	await capture("contraste")
	scene.show_help()
	await capture("ayuda-larga")
	scene.detail.hide()
	# Verify actual playback routing with a silent output on the player itself.
	# Synthesis and routing are checked; this does not assert human auditory approval.
	scene.preferences.muted = false
	scene.preferences.club_volume = 0
	scene.preferences.ambient_volume = 0
	scene.audio.configure(scene.preferences, "dia")
	scene.audio.players.dice.volume_db = -80
	scene.audio.cue("roll")
	if not scene.audio.players.dice.playing: failures.append("Dice player did not start")
	scene.preferences.muted = true
	scene.audio.configure(scene.preferences, "dia")
	if scene.audio.players.values().any(func(player): return player.playing): failures.append("Mute did not stop audio")
	preload("res://scripts/presentation_audio.gd").synth("roll").save_to_wav("res://test-results/presentacion-dados.wav")
	print("PRESENTATION REVIEW: 12 captures; routing/mute/instant invariants; failures=" + str(failures))
	quit(0 if failures.is_empty() else 1)

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
