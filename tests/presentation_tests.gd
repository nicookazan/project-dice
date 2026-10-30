extends RefCounted
const Preferences = preload("res://scripts/presentation_preferences.gd")
const Presentation = preload("res://scripts/presentation_state.gd")
const Audio = preload("res://scripts/presentation_audio.gd")
const Game = preload("res://scripts/game.gd")
const Campaign = preload("res://scripts/campaign.gd")
const CampaignTests = preload("res://tests/campaign_tests.gd")
const Flow = preload("res://tests/level_flow_tests.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const RepairTests = preload("res://tests/repair_tests.gd")
const PurchaseTests = preload("res://tests/purchase_tests.gd")
const BreakageGame = preload("res://tests/support/breakage_game.gd")

static func run(scene, check: Callable) -> Dictionary:
	scene.persistence_enabled = false
	scene.preferences_enabled = true
	scene.preference_store = Preferences.new("res://test-results/preferences/" + str(Time.get_ticks_usec()) + "/options.cfg")
	var service = scene.preference_store
	check.call(service.load_values() == Preferences.DEFAULTS, "Presentation: missing preferences uses defaults independently of run")
	var saved := Preferences.DEFAULTS.duplicate()
	saved.muted = true
	saved.dice_volume = 0.37
	saved.speed = 2
	saved.reduced_motion = true
	saved.drag_groups = true
	check.call(service.save_values(saved) and Preferences.new(service.path).load_values() == saved, "Presentation: preferences round-trip in separate versioned file")
	var legacy_values := saved.duplicate()
	legacy_values.erase("drag_groups")
	var legacy_config := ConfigFile.new()
	legacy_config.set_value("presentation", "version", 1)
	legacy_config.set_value("presentation", "values", legacy_values)
	legacy_config.save(service.path)
	check.call(not service.load_values().drag_groups and service.last_error.is_empty(), "Presentation: old options gain drag preference without discarding saved audio or display settings")
	service.save_values(saved)
	var original := FileAccess.get_file_as_string(service.path)
	for bad in [{}, {"muted": "yes"}, {"speed": 8}, {"dice_volume": -0.01}, {"effects_volume": 1.01}, {"club_volume": NAN}, {"reduced_motion": 1}]:
		var candidate := saved.duplicate()
		if bad.is_empty(): candidate.erase("muted")
		else: candidate.merge(bad, true)
		check.call(not service.save_values(candidate) and FileAccess.get_file_as_string(service.path) == original, "Presentation: invalid preferences rejected without replacing valid file " + str(bad))
	var config := ConfigFile.new()
	config.set_value("presentation", "version", 99)
	config.save(service.path)
	var future := FileAccess.get_file_as_string(service.path)
	check.call(service.load_values() == Preferences.DEFAULTS and service.last_error != "" and FileAccess.get_file_as_string(service.path) == future, "Presentation: future/corrupt preferences preserved with readable fallback")
	service.save_values(saved)
	scene.preferences = saved.duplicate()
	scene.game = Game.new(3)
	scene.render()
	var before: Dictionary = scene.game.snapshot()
	scene.show_options()
	scene.settings_panel.get_node("Mute").button_pressed = false
	scene.settings_panel.get_node("diceVolume").value = 42
	scene.settings_panel.get_node("ambientVolume").value = 0
	scene.settings_panel.get_node("AnimationSpeed").item_selected.emit(0)
	scene.settings_panel.get_node("reduced_motion").button_pressed = false
	scene.settings_panel.get_node("high_contrast").button_pressed = true
	check.call(not scene.preferences.muted and scene.preferences.dice_volume == 0.42 and scene.preferences.ambient_volume == 0 and scene.preferences.speed == 0 and scene.preferences.high_contrast, "Presentation UI: real controls apply mute, family volumes, speed and contrast")
	check.call(service.load_values() == scene.preferences and scene.game.snapshot() == before, "Presentation UI: options persist without touching snapshot or any gameplay RNG")
	check.call(not scene.background.motion and scene.detail.visible and "F11" in scene.detail_text, "Presentation UI: instant mode freezes presentation while modal retains keyboard help")
	scene.set_preference("muted", true)
	check.call(scene.audio.players.values().all(func(player): return not player.playing), "Presentation: global mute stops all four players")
	scene.detail.hide()
	scene.preferences_enabled = false
	var baseline: Dictionary = {}
	var traces: Array = []
	for mode in [1, 2, 0]:
		scene.preferences = Preferences.DEFAULTS.duplicate()
		scene.preferences.muted = true
		scene.preferences.speed = mode
		scene.preferences.reduced_motion = mode == 0
		scene.preferences.high_contrast = mode == 0
		scene.game = Game.new(3)
		scene.selected.clear()
		scene.render()
		var trace := Flow.play_run(scene.game, scene)
		traces.append(trace)
		check.call(scene.game.phase == "won", "Presentation: natural seeded UI route completes with speed " + str(mode))
		if baseline.is_empty(): baseline = scene.game.snapshot()
		else: check.call(scene.game.snapshot() == baseline and trace == traces[0], "Presentation: identical rolls, stock, receipts, score, reward and RNG at speed " + str(mode))
	var stages: Array = []
	for level in range(7):
		scene.game = CampaignTests.advance_model(Campaign.prototype(), level * 3 + 2)
		before = scene.game.snapshot()
		scene.render()
		scene.background._process(0.5)
		scene._process(0.5)
		var profile := Presentation.profile(scene.game)
		check.call(profile.environment == Campaign.prototype()[level].environment and profile.beverage == "mate", "Presentation: level environment and mate always " + str(level + 1))
		check.call(scene.game.snapshot() == before and scene.background.environment_id == profile.environment, "Presentation: stage render/animation never consumes gameplay RNG " + str(level + 1))
		check.call(profile.actor == ("god" if level == 6 else scene.game.boss_rule.kind), "Presentation: boss prop follows active rule, God uses triangle/eye")
		stages.append(profile)
	var observer = Presentation.new()
	var game = Game.new(501)
	check.call(observer.observe(game).is_empty(), "Presentation: initial/reloaded state emits no replayed transaction")
	game.roll()
	check.call(observer.observe(game).get("sound") == "roll" and observer.observe(game).is_empty(), "Presentation: roll cue once without repeating on redraw")
	Fixture.set_results(game, [2, 2, 3, 4, 6])
	game.form_group([0, 1])
	check.call(observer.observe(game).get("sound") == "move", "Presentation: grouping has text and sound")
	game.score_hand()
	check.call(observer.observe(game).get("sound") == "score", "Presentation: scoring cue follows committed result")
	game = PurchaseTests.fixture("coin", {"coin_id": "even"}, 4)
	observer.observe(game)
	game.begin_purchase("coins", "fixture:1")
	check.call(observer.observe(game).get("sound") == "buy" and observer.observe(game).is_empty(), "Presentation: actual paid purchase signals once")
	game = BreakageGame.new(507)
	game.dice[0].shell = "ruby"
	game.draws = [0.0]
	Fixture.set_values(game, [4, 4, 2, 2, 6])
	game.points = game.target()
	game.form_group([0, 1])
	observer.observe(game)
	game.score_hand()
	check.call(observer.observe(game).get("sound") == "break" and game.dice[0].shell_broken, "Presentation: break cue only after actual shell break, retaining score")
	game.close_encounter()
	observer.observe(game)
	game.resolve_repairs([0])
	check.call(observer.observe(game).get("sound") == "repair" and not game.dice[0].shell_broken, "Presentation: actual selected repair has text and sound")
	for cue in ["roll", "move", "club", "ambient", "score", "buy", "repair", "break", "level"]:
		var stream := Audio.synth(cue)
		check.call(stream.data.size() >= 13230 and stream.data.count(0) < stream.data.size() / 2 and stream.mix_rate == 22050 and not stream.stereo, "Presentation audio: original non-silent 16bit PCM " + cue)
	check.call(Audio.synth("ambient", "dia").data != Audio.synth("ambient", "cielo").data, "Presentation audio: environment changes its ambience")
	check.call(Audio.synth("club").loop_mode == AudioStreamWAV.LOOP_FORWARD and Audio.synth("roll").loop_mode == AudioStreamWAV.LOOP_DISABLED, "Presentation audio: continuous ambience and finite action cues")
	scene.preferences.muted = true
	scene.render()
	return {"stages": stages, "natural_traces": traces, "same_full_snapshot": true, "preferences_separate": true, "audio": "original synthesized PCM; auditory approval pending"}
