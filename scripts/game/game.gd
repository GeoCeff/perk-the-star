extends Node2D

const MAX_WAVES: int = 12
const SUN_RADIUS: float = 58.0
const SUN_DAMAGE_RADIUS: float = 62.0
const ENEMY_SPAWN_PADDING: float = 260.0
const SLOT_ANGLE_OFFSET: float = -PI / 2.0
const HUD_MARGIN: float = 24.0
const HUD_TOP_HEIGHT: float = 88.0
const HUD_BOTTOM_HEIGHT: float = 96.0
const HUD_BOTTOM_MARGIN: float = 64.0
const FLARE_DAMAGE: float = 85.0
const BURROWER_DIG_RADIUS: float = 74.0
const BURROWER_EXCAVATION_HP: float = 52.0
const BURROWER_DRAIN_INTERVAL: float = 1.0
const BURROWER_DRAIN_DAMAGE: float = 0.012

const WAVE_BGM_PATHS: Array = [
	"res://assets/audio/bgm/waves_1.ogg",
	"res://assets/audio/bgm/waves_2.ogg",
]
const END_BGM_PATH: String = "res://assets/audio/bgm/end.ogg"
const WAVE_TRACK_SWAP_SECONDS: float = 55.0

const SUN_ASSET_PATHS: Dictionary = {
	"happy": "res://assets/sprites/sun/Sun_Happy_Placeholder.png",
	"concerned": "res://assets/sprites/sun/Sun_Concerned_Placeholder.png",
	"distressed": "res://assets/sprites/sun/Sun_Distressed_Placeholder.png",
	"critical": "res://assets/sprites/sun/Sun_Crit_Placeholder.png",
}

const ENEMY_ASSET_PATHS: Dictionary = {
	"drifter": "res://assets/sprites/enemies/Drifter.png",
	"bloom": "res://assets/sprites/enemies/Bloom.png",
	"burrower": "res://assets/sprites/enemies/Coronal Burrower.png",
	"mimic": "res://assets/sprites/enemies/Photon Mimic.png",
	"farmer": "res://assets/sprites/enemies/Solar Farmer.png",
	"prime": "res://assets/sprites/enemies/ASTROPHAGE PRIME.png",
}

const TOWER_ASSET_PATHS: Dictionary = {
	"photon_splitter": "res://assets/sprites/towers/Photon Splitter.png",
	"cryo_probe": "res://assets/sprites/towers/Cryo Probe.png",
	"bio_lab": "res://assets/sprites/towers/Bio-Lab.png",
	"magnetic_net": "res://assets/sprites/towers/Magnetic Net.png",
	"helios_cannon": "res://assets/sprites/towers/Helios Canon.png",
	"tardigrade_bomb": "res://assets/sprites/towers/Tardigrade Bomb.png",
}

const RINGS: Array = [
	{"id": 1, "name": "Corona Belt", "radius": 80.0, "period": 6.0, "slots": 4, "best": "Photon Splitter, Helios Cannon"},
	{"id": 2, "name": "Chromosphere Band", "radius": 140.0, "period": 11.0, "slots": 6, "best": "Cryo Probe, Tardigrade Bomb"},
	{"id": 3, "name": "Photosphere Arc", "radius": 210.0, "period": 17.0, "slots": 8, "best": "Bio-Lab Station, Magnetic Net"},
	{"id": 4, "name": "Outer Veil", "radius": 290.0, "period": 26.0, "slots": 10, "best": "Early intercept"},
]

const VARIANT_KEYS: Array = ["drifter", "bloom", "burrower", "mimic", "farmer", "prime"]

const TOWER_ORDER: Array = [
	"photon_splitter",
	"cryo_probe",
	"bio_lab",
	"magnetic_net",
	"helios_cannon",
	"tardigrade_bomb",
]

const TOWER_CONFIGS: Dictionary = {
	"photon_splitter": {"label": "Photon Splitter", "damage": 16.0, "rate": 0.9, "range": 225.0, "color": Color(1.0, 0.86, 0.28)},
	"cryo_probe": {"label": "Cryo Probe", "damage": 5.0, "rate": 0.55, "range": 230.0, "color": Color(0.34, 0.86, 1.0)},
	"bio_lab": {"label": "Bio-Lab Station", "damage": 10.0, "rate": 0.55, "range": 245.0, "color": Color(0.46, 1.0, 0.52)},
	"magnetic_net": {"label": "Magnetic Net", "damage": 4.0, "rate": 0.42, "range": 270.0, "color": Color(0.76, 0.62, 1.0)},
	"helios_cannon": {"label": "Helios Cannon", "damage": 76.0, "rate": 0.14, "range": 280.0, "color": Color(1.0, 0.43, 0.22)},
	"tardigrade_bomb": {"label": "Tardigrade Bomb", "damage": 20.0, "rate": 0.38, "range": 240.0, "color": Color(1.0, 0.58, 0.76)},
}

const ENEMY_CONFIGS: Dictionary = {
	"drifter": {"variant_id": 0, "label": "Drifter", "hp": 30.0, "speed": 48.0, "damage": 0.05, "reward": 5, "radius": 15.0, "draw_size": 46.0, "color": Color(0.96, 0.42, 0.48)},
	"bloom": {"variant_id": 1, "label": "Bloom", "hp": 62.0, "speed": 44.0, "damage": 0.05, "reward": 10, "radius": 18.0, "draw_size": 54.0, "color": Color(1.0, 0.62, 0.36)},
	"burrower": {"variant_id": 2, "label": "Coronal Burrower", "hp": 115.0, "speed": 32.0, "damage": 0.08, "reward": 20, "radius": 19.0, "draw_size": 58.0, "color": Color(0.76, 0.50, 0.30)},
	"mimic": {"variant_id": 3, "label": "Photon Mimic", "hp": 52.0, "speed": 50.0, "damage": 0.05, "reward": 15, "radius": 16.0, "draw_size": 48.0, "color": Color(0.70, 0.62, 0.98)},
	"farmer": {"variant_id": 4, "label": "Solar Farmer", "hp": 44.0, "speed": 46.0, "damage": 0.05, "reward": 12, "radius": 17.0, "draw_size": 50.0, "color": Color(0.55, 0.92, 0.45)},
	"prime": {"variant_id": 5, "label": "Astrophage Prime", "hp": 520.0, "speed": 24.0, "damage": 0.12, "reward": 100, "radius": 34.0, "draw_size": 84.0, "color": Color(1.0, 0.18, 0.15)},
}

@export_range(1, 12, 1) var playable_wave_limit: int = 12
@export var briefing_title: String = "SOL DEFENSE CORPS"

var current_wave_data: Dictionary = {}
var next_wave_preview: Dictionary = {}
var spawn_queue: Array = []
var enemies: Array = []
var burrowers: Array = []
var towers: Array = []
var shots: Array = []
var stars: Array = []
var selected_tower: String = "photon_splitter"
var spawn_timer: float = 0.0
var spawned_wave_count: int = 0
var total_wave_spawn_count: int = 0
var wave_active: bool = false
var message_text: String = "Click a guide slot on an orbital ring, then start Wave 1."
var message_timer: float = 0.0
var wave_event: Dictionary = {}
var wave_event_triggered: bool = false
var cryo_disruption_timer: float = 0.0
var bio_lab_boost_timer: float = 0.0
var bio_lab_boost_multiplier: float = 1.0
var ring_blind_timers: Dictionary = {}
var prime_frenzy_timer: float = 0.0
var prime_frenzy_interval: float = 0.0
var prime_frenzy_max_active: int = 18
var ui: Dictionary = {}
var textures: Dictionary = {
	"sun": {},
	"enemies": {},
	"towers": {},
}
var bgm_player: AudioStreamPlayer
var wave_music_index: int = 0
var wave_music_timer: float = 0.0
var ending_music_started: bool = false


func _ready() -> void:
	randomize()
	GameState.reset_state()
	GameState.load_audio_settings()
	GameState.set_phase(GameState.Phase.BETWEEN_WAVE)
	_load_assets()
	_play_wave_music()
	_generate_starfield()
	_build_ui()
	_refresh_next_wave_preview()
	_update_ui()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message_text = "Place towers between waves. Towers orbit and fire automatically."
			_update_ui()

	_process_music(delta)

	if GameState.game_phase == GameState.Phase.WAVE_ACTIVE:
		_process_spawning(delta)
		_process_wave_event(delta)
		_process_prime_frenzy(delta)

	_process_wave_modifiers(delta)
	_process_towers(delta)
	_process_enemies(delta)
	_process_burrowers(delta)
	_process_shots(delta)
	_check_wave_clear()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if GameState.game_phase != GameState.Phase.BETWEEN_WAVE:
		return

	var click_pos: Vector2 = get_global_mouse_position()
	var slot: Dictionary = _nearest_ring_slot(click_pos)
	if slot.is_empty():
		_set_message("Select one of the visible orbital slots before the wave starts.", 2.0)
		return
	if bool(slot.get("occupied", false)):
		_set_message("%s slot %d already has a tower." % [slot["ring_name"], int(slot["slot_index"]) + 1], 2.0)
		return

	var cost: int = GameState.get_tower_cost(selected_tower)
	if not GameState.spend_credits(cost):
		_set_message("Need %d Sol Credits for %s." % [cost, _tower_config(selected_tower)["label"]], 2.0)
		return

	towers.append({
		"type": selected_tower,
		"ring": int(slot["ring_index"]),
		"slot": int(slot["slot_index"]),
		"angle": float(slot["angle"]),
		"fire_timer": 0.15,
		"level": 1,
	})
	_set_message("Placed %s on %s slot %d." % [_tower_config(selected_tower)["label"], slot["ring_name"], int(slot["slot_index"]) + 1], 2.0)
	_update_ui()


func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var sun: Vector2 = _sun_pos()

	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.012, 0.018, 0.034), true)
	for star in stars:
		var star_color: Color = star["color"]
		draw_circle(star["pos"], float(star["radius"]), star_color)

	for i in range(RINGS.size()):
		var ring: Dictionary = RINGS[i]
		var ring_radius: float = float(ring["radius"])
		var ring_blinded: bool = _is_ring_blinded(i)
		var alpha: float = 0.34 if i < 2 else 0.24
		var ring_color: Color = Color(0.30, 0.62, 1.0, alpha)
		if ring_blinded:
			ring_color = Color(0.20, 0.22, 0.28, 0.30)
		draw_arc(sun, ring_radius, 0.0, TAU, 192, ring_color, 2.0, true)
		draw_arc(sun, ring_radius + 1.5, 0.0, TAU, 192, Color(1.0, 0.86, 0.30, 0.06), 1.0, true)
		for slot_index in range(int(ring["slots"])):
			var slot_pos: Vector2 = _ring_slot_position(i, slot_index)
			var occupied: bool = _is_slot_taken(i, slot_index)
			var slot_color: Color = Color(1.0, 0.86, 0.30, 0.86) if occupied else Color(0.58, 0.74, 1.0, 0.50)
			if ring_blinded:
				slot_color = Color(0.38, 0.42, 0.50, 0.45)
			draw_circle(slot_pos, 5.0 if occupied else 4.0, slot_color)
			draw_circle(slot_pos, 9.0, Color(slot_color.r, slot_color.g, slot_color.b, 0.09))

	draw_circle(sun, 135.0, Color(1.0, 0.56, 0.12, 0.05))
	draw_circle(sun, 96.0, Color(1.0, 0.66, 0.16, 0.09))
	_draw_sun(sun)

	for shot in shots:
		var shot_color: Color = shot["color"]
		draw_line(shot["from"], shot["to"], shot_color, 3.0)
		draw_circle(shot["to"], 5.0, Color(shot_color.r, shot_color.g, shot_color.b, 0.55))

	for tower in towers:
		_draw_tower(tower)

	for enemy in enemies:
		_draw_enemy(enemy)

	for burrower in burrowers:
		_draw_burrower(burrower)

	if GameState.game_phase == GameState.Phase.GAME_OVER:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.0, 0.0, 0.0, 0.58), true)
	elif GameState.game_phase == GameState.Phase.VICTORY:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(1.0, 0.78, 0.18, 0.12), true)


func _load_assets() -> void:
	for key in SUN_ASSET_PATHS.keys():
		textures["sun"][key] = load(str(SUN_ASSET_PATHS[key]))
	for key in ENEMY_ASSET_PATHS.keys():
		textures["enemies"][key] = load(str(ENEMY_ASSET_PATHS[key]))
	for key in TOWER_ASSET_PATHS.keys():
		textures["towers"][key] = load(str(TOWER_ASSET_PATHS[key]))

	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "GameMusic"
	bgm_player.volume_db = GameState.get_music_volume_db()
	add_child(bgm_player)


func _play_wave_music() -> void:
	ending_music_started = false
	wave_music_index = clamp(wave_music_index, 0, WAVE_BGM_PATHS.size() - 1)
	_set_music_stream(str(WAVE_BGM_PATHS[wave_music_index]), true)
	wave_music_timer = 0.0
	_apply_music_settings()
	if GameState.music_enabled and bgm_player.stream and not bgm_player.playing:
		bgm_player.play()


func _process_music(delta: float) -> void:
	if bgm_player == null or ending_music_started:
		return
	if not GameState.music_enabled:
		return
	if WAVE_BGM_PATHS.size() < 2:
		return

	wave_music_timer += delta
	if wave_music_timer < WAVE_TRACK_SWAP_SECONDS:
		return

	wave_music_index = (wave_music_index + 1) % WAVE_BGM_PATHS.size()
	_set_music_stream(str(WAVE_BGM_PATHS[wave_music_index]), true)
	bgm_player.play()
	wave_music_timer = 0.0


func _play_ending_music() -> void:
	if ending_music_started:
		return
	ending_music_started = true
	_set_music_stream(END_BGM_PATH, true)
	_apply_music_settings()
	if GameState.music_enabled and bgm_player.stream:
		bgm_player.play()


func _set_music_stream(path: String, loop_enabled: bool) -> void:
	var stream = load(path)
	_set_audio_stream_loop(stream, loop_enabled)
	bgm_player.stream = stream


func _apply_music_settings() -> void:
	if bgm_player == null:
		return
	bgm_player.volume_db = GameState.get_music_volume_db()
	if not GameState.music_enabled:
		bgm_player.stop()


func _set_audio_stream_loop(stream, loop_enabled: bool) -> void:
	if stream == null:
		return
	for property in stream.get_property_list():
		if str(property.get("name", "")) == "loop":
			stream.set("loop", loop_enabled)
			return


func _generate_starfield() -> void:
	stars.clear()
	var viewport_size: Vector2 = get_viewport_rect().size
	for _i in range(120):
		stars.append({
			"pos": Vector2(randf() * viewport_size.x, randf() * viewport_size.y),
			"radius": randf_range(0.7, 2.0),
			"color": Color(0.62 + randf() * 0.32, 0.72 + randf() * 0.22, 1.0, 0.22 + randf() * 0.42),
		})


func _build_ui() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "GameHudLayer"
	add_child(layer)

	var root: Control = Control.new()
	root.name = "Hud"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	var top_panel: PanelContainer = PanelContainer.new()
	top_panel.anchor_right = 1.0
	top_panel.offset_left = HUD_MARGIN
	top_panel.offset_top = 18.0
	top_panel.offset_right = -HUD_MARGIN
	top_panel.offset_bottom = 18.0 + HUD_TOP_HEIGHT
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.020, 0.027, 0.040, 0.94), Color(0.28, 0.47, 0.68, 0.52), 5.0, 12.0, 8.0))
	root.add_child(top_panel)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 16)
	top_panel.add_child(top_row)

	var wave_block: VBoxContainer = VBoxContainer.new()
	wave_block.custom_minimum_size = Vector2(520.0, 0.0)
	wave_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wave_block.add_theme_constant_override("separation", 3)
	top_row.add_child(wave_block)

	ui["wave_label"] = Label.new()
	ui["wave_label"].add_theme_font_size_override("font_size", 22)
	wave_block.add_child(ui["wave_label"])

	ui["brief_label"] = Label.new()
	ui["brief_label"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui["brief_label"].clip_text = true
	ui["brief_label"].add_theme_color_override("font_color", Color(0.82, 0.88, 0.96, 0.92))
	ui["brief_label"].add_theme_font_size_override("font_size", 14)
	wave_block.add_child(ui["brief_label"])

	var stats_grid: GridContainer = GridContainer.new()
	stats_grid.columns = 4
	stats_grid.custom_minimum_size = Vector2(398.0, 0.0)
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 0)
	top_row.add_child(stats_grid)

	_add_stat(stats_grid, "credits_label", "Sol", 88.0)
	_add_stat(stats_grid, "score_label", "Score", 88.0)
	_add_stat(stats_grid, "kills_label", "Kills", 76.0)
	_add_stat(stats_grid, "flare_label", "Flare", 104.0)

	var lum_box: VBoxContainer = VBoxContainer.new()
	lum_box.custom_minimum_size = Vector2(188.0, 0.0)
	lum_box.add_theme_constant_override("separation", 6)
	top_row.add_child(lum_box)

	var lum_title: Label = Label.new()
	lum_title.text = "Luminosity"
	lum_title.add_theme_font_size_override("font_size", 13)
	lum_title.add_theme_color_override("font_color", Color(0.72, 0.82, 0.94, 0.88))
	lum_box.add_child(lum_title)

	ui["luminosity_bar"] = ProgressBar.new()
	ui["luminosity_bar"].min_value = 0.0
	ui["luminosity_bar"].max_value = 100.0
	ui["luminosity_bar"].show_percentage = true
	ui["luminosity_bar"].custom_minimum_size = Vector2(176.0, 20.0)
	ui["luminosity_bar"].add_theme_stylebox_override("background", _bar_style(Color(0.12, 0.15, 0.19, 0.95), 4.0))
	ui["luminosity_bar"].add_theme_stylebox_override("fill", _bar_style(Color(0.94, 0.74, 0.32, 0.95), 4.0))
	lum_box.add_child(ui["luminosity_bar"])

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	top_row.add_child(action_row)

	ui["start_button"] = Button.new()
	ui["start_button"].custom_minimum_size = Vector2(142.0, 54.0)
	ui["start_button"].add_theme_stylebox_override("normal", _button_style(Color(0.93, 0.66, 0.22, 0.96), Color(1.0, 0.82, 0.42, 0.55), 5.0))
	ui["start_button"].add_theme_stylebox_override("hover", _button_style(Color(1.0, 0.74, 0.27, 1.0), Color(1.0, 0.88, 0.55, 0.75), 5.0))
	ui["start_button"].add_theme_stylebox_override("pressed", _button_style(Color(0.78, 0.48, 0.14, 1.0), Color(1.0, 0.75, 0.32, 0.70), 5.0))
	ui["start_button"].add_theme_color_override("font_color", Color(0.06, 0.07, 0.09))
	ui["start_button"].pressed.connect(_on_start_wave_pressed)
	action_row.add_child(ui["start_button"])

	var menu_button: Button = Button.new()
	menu_button.text = "Menu"
	menu_button.custom_minimum_size = Vector2(74.0, 54.0)
	menu_button.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.10, 0.14, 0.96), Color(0.32, 0.42, 0.54, 0.42), 5.0))
	menu_button.add_theme_stylebox_override("hover", _button_style(Color(0.12, 0.15, 0.20, 0.98), Color(0.48, 0.62, 0.76, 0.56), 5.0))
	menu_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	action_row.add_child(menu_button)

	var intel_panel: PanelContainer = PanelContainer.new()
	intel_panel.anchor_left = 1.0
	intel_panel.anchor_right = 1.0
	intel_panel.offset_left = -378.0
	intel_panel.offset_top = 124.0
	intel_panel.offset_right = -HUD_MARGIN
	intel_panel.offset_bottom = 336.0
	intel_panel.clip_contents = true
	intel_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.020, 0.025, 0.035, 0.92), Color(0.48, 0.34, 0.68, 0.45), 5.0, 12.0, 10.0))
	root.add_child(intel_panel)

	var intel_box: VBoxContainer = VBoxContainer.new()
	intel_box.add_theme_constant_override("separation", 7)
	intel_panel.add_child(intel_box)

	var intel_title: Label = Label.new()
	intel_title.text = "Wave Intel"
	intel_title.add_theme_font_size_override("font_size", 16)
	intel_box.add_child(intel_title)

	var enemy_row: HBoxContainer = HBoxContainer.new()
	enemy_row.add_theme_constant_override("separation", 10)
	intel_box.add_child(enemy_row)

	ui["enemy_preview"] = TextureRect.new()
	ui["enemy_preview"].custom_minimum_size = Vector2(44.0, 44.0)
	ui["enemy_preview"].size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ui["enemy_preview"].size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ui["enemy_preview"].expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ui["enemy_preview"].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui["enemy_preview"].clip_contents = true
	enemy_row.add_child(ui["enemy_preview"])

	var enemy_text: VBoxContainer = VBoxContainer.new()
	enemy_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_text.add_theme_constant_override("separation", 2)
	enemy_row.add_child(enemy_text)

	ui["enemy_label"] = Label.new()
	ui["enemy_label"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui["enemy_label"].add_theme_font_size_override("font_size", 15)
	ui["enemy_label"].clip_text = true
	enemy_text.add_child(ui["enemy_label"])

	ui["threat_label"] = Label.new()
	ui["threat_label"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui["threat_label"].add_theme_color_override("font_color", Color(0.82, 0.88, 0.96, 0.92))
	ui["threat_label"].add_theme_font_size_override("font_size", 13)
	enemy_text.add_child(ui["threat_label"])

	ui["ring_label"] = Label.new()
	ui["ring_label"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui["ring_label"].add_theme_color_override("font_color", Color(0.74, 0.82, 0.92, 0.86))
	ui["ring_label"].add_theme_font_size_override("font_size", 13)
	intel_box.add_child(ui["ring_label"])

	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.anchor_top = 1.0
	bottom_row.anchor_right = 1.0
	bottom_row.anchor_bottom = 1.0
	bottom_row.offset_left = HUD_MARGIN
	bottom_row.offset_top = -HUD_BOTTOM_HEIGHT - HUD_BOTTOM_MARGIN
	bottom_row.offset_right = -HUD_MARGIN
	bottom_row.offset_bottom = -HUD_BOTTOM_MARGIN
	bottom_row.add_theme_constant_override("separation", 16)
	root.add_child(bottom_row)

	var tower_panel: PanelContainer = PanelContainer.new()
	tower_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tower_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.020, 0.027, 0.038, 0.93), Color(0.30, 0.56, 0.70, 0.46), 5.0, 12.0, 7.0))
	bottom_row.add_child(tower_panel)

	var tower_row: HBoxContainer = HBoxContainer.new()
	tower_row.add_theme_constant_override("separation", 8)
	tower_panel.add_child(tower_row)

	var tower_label: Label = Label.new()
	tower_label.text = "Build"
	tower_label.custom_minimum_size = Vector2(52.0, 0.0)
	tower_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tower_label.add_theme_font_size_override("font_size", 15)
	tower_label.add_theme_color_override("font_color", Color(0.83, 0.90, 0.98, 0.94))
	tower_row.add_child(tower_label)

	var tower_scroll: ScrollContainer = ScrollContainer.new()
	tower_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tower_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	tower_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tower_row.add_child(tower_scroll)

	var tower_buttons_row: HBoxContainer = HBoxContainer.new()
	tower_buttons_row.add_theme_constant_override("separation", 8)
	tower_scroll.add_child(tower_buttons_row)

	ui["tower_buttons"] = {}
	for tower_type in TOWER_ORDER:
		var button: Button = Button.new()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.icon = _tower_texture(tower_type)
		button.expand_icon = true
		button.custom_minimum_size = Vector2(128.0, 62.0)
		button.add_theme_font_size_override("font_size", 12)
		button.add_theme_constant_override("h_separation", 4)
		button.add_theme_stylebox_override("normal", _button_style(Color(0.06, 0.075, 0.095, 0.94), Color(0.26, 0.38, 0.50, 0.35), 4.0))
		button.add_theme_stylebox_override("hover", _button_style(Color(0.09, 0.115, 0.145, 0.98), Color(0.40, 0.58, 0.72, 0.50), 4.0))
		button.add_theme_stylebox_override("pressed", _button_style(Color(0.12, 0.18, 0.20, 1.0), Color(0.94, 0.72, 0.28, 0.78), 4.0))
		button.pressed.connect(_select_tower.bind(tower_type))
		ui["tower_buttons"][tower_type] = button
		tower_buttons_row.add_child(button)

	var message_panel: PanelContainer = PanelContainer.new()
	message_panel.custom_minimum_size = Vector2(500.0, 0.0)
	message_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.032, 0.032, 0.038, 0.91), Color(0.72, 0.55, 0.20, 0.46), 5.0, 14.0, 8.0))
	bottom_row.add_child(message_panel)

	ui["message_label"] = Label.new()
	ui["message_label"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui["message_label"].vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui["message_label"].add_theme_font_size_override("font_size", 14)
	ui["message_label"].add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 0.96))
	message_panel.add_child(ui["message_label"])


func _add_stat(parent: Control, key: String, caption: String, width: float) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(width, 0.0)
	box.add_theme_constant_override("separation", 1)
	parent.add_child(box)

	var title: Label = Label.new()
	title.text = caption.to_upper()
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.68, 0.78, 0.90, 0.82))
	box.add_child(title)

	var value: Label = Label.new()
	value.add_theme_font_size_override("font_size", 20)
	value.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 0.98))
	box.add_child(value)
	ui[key] = value


func _panel_style(bg_color: Color, border_color: Color, radius: float = 6.0, horizontal_margin: float = 14.0, vertical_margin: float = 10.0) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(radius))
	style.content_margin_left = horizontal_margin
	style.content_margin_right = horizontal_margin
	style.content_margin_top = vertical_margin
	style.content_margin_bottom = vertical_margin
	return style


func _bar_style(bg_color: Color, radius: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(int(radius))
	return style


func _button_style(bg_color: Color, border_color: Color, radius: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(radius))
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


func _on_start_wave_pressed() -> void:
	if GameState.game_phase != GameState.Phase.BETWEEN_WAVE:
		return

	var wave_number: int = GameState.current_wave + 1
	if wave_number > playable_wave_limit:
		_set_message("Wave %d is locked for this scene." % wave_number, 3.0)
		return
	if wave_number > MAX_WAVES:
		return

	current_wave_data = _load_wave(wave_number)
	if current_wave_data.is_empty():
		_set_message("Could not load wave_%02d.json." % wave_number, 3.0)
		return

	GameState.current_wave = wave_number
	GameState.set_phase(GameState.Phase.WAVE_ACTIVE)
	spawn_queue = _build_spawn_queue(current_wave_data)
	total_wave_spawn_count = spawn_queue.size()
	spawned_wave_count = 0
	spawn_timer = 0.35
	wave_active = true
	_begin_wave_event(current_wave_data)
	if GameState.music_enabled and bgm_player and bgm_player.stream and not bgm_player.playing:
		bgm_player.play()
	_set_message(str(current_wave_data.get("tutorial_hint", "Wave incoming.")), 5.0)
	_update_ui()


func _select_tower(tower_type: String) -> void:
	selected_tower = tower_type
	_set_message("Selected %s." % _tower_config(tower_type)["label"], 1.2)
	_update_ui()


func _begin_wave_event(wave_data: Dictionary) -> void:
	wave_event = {}
	var event = wave_data.get("event", null)
	if event is Dictionary:
		wave_event = event
	wave_event_triggered = false
	cryo_disruption_timer = 0.0
	bio_lab_boost_timer = 0.0
	bio_lab_boost_multiplier = 1.0
	ring_blind_timers.clear()
	prime_frenzy_timer = 0.0
	prime_frenzy_interval = 0.0
	prime_frenzy_max_active = 18


func _end_wave_event() -> void:
	wave_event = {}
	wave_event_triggered = false
	cryo_disruption_timer = 0.0
	bio_lab_boost_timer = 0.0
	bio_lab_boost_multiplier = 1.0
	ring_blind_timers.clear()
	prime_frenzy_timer = 0.0
	prime_frenzy_interval = 0.0


func _process_wave_event(_delta: float) -> void:
	if wave_event.is_empty() or wave_event_triggered:
		return

	var trigger_at: float = float(wave_event.get("trigger_at_percent", 0.0))
	if _wave_progress_ratio() < trigger_at:
		return

	wave_event_triggered = true
	match str(wave_event.get("type", "")):
		"mid_wave_autoflare":
			_trigger_solar_flare()
			cryo_disruption_timer = float(wave_event.get("cryo_disruption_seconds", 0.0))
			_set_message("Solar storm flare fired. Cryo Probes offline for %.0fs." % cryo_disruption_timer, 4.0)
		"ring_blind":
			var duration: float = float(wave_event.get("duration", 0.0))
			for raw_ring in wave_event.get("rings", []):
				var ring_index: int = int(raw_ring)
				if ring_index >= 0 and ring_index < RINGS.size():
					ring_blind_timers[ring_index] = duration
			_set_message("Night-side blackout: inner rings offline for %.0fs." % duration, 4.0)
		"bio_lab_boost":
			bio_lab_boost_multiplier = max(float(wave_event.get("multiplier", 1.0)), 1.0)
			bio_lab_boost_timer = float(wave_event.get("duration", 0.0))
			_set_message("Research surge: Bio-Labs firing at %.0fx speed." % bio_lab_boost_multiplier, 4.0)
		"prime_frenzy":
			prime_frenzy_interval = max(float(wave_event.get("interval", 2.0)), 0.2)
			prime_frenzy_timer = prime_frenzy_interval
			prime_frenzy_max_active = max(int(wave_event.get("max_active", 18)), 1)
			_set_message("Prime frenzy armed. Drifters will keep arriving while Prime lives.", 4.0)


func _process_wave_modifiers(delta: float) -> void:
	cryo_disruption_timer = max(cryo_disruption_timer - delta, 0.0)
	bio_lab_boost_timer = max(bio_lab_boost_timer - delta, 0.0)
	if bio_lab_boost_timer <= 0.0:
		bio_lab_boost_multiplier = 1.0

	var expired_rings: Array = []
	for ring_index in ring_blind_timers.keys():
		var remaining: float = float(ring_blind_timers[ring_index]) - delta
		if remaining <= 0.0:
			expired_rings.append(ring_index)
		else:
			ring_blind_timers[ring_index] = remaining
	for ring_index in expired_rings:
		ring_blind_timers.erase(ring_index)


func _process_prime_frenzy(delta: float) -> void:
	if prime_frenzy_interval <= 0.0 or not _is_prime_alive():
		return
	if enemies.size() >= prime_frenzy_max_active:
		return

	prime_frenzy_timer -= delta
	if prime_frenzy_timer > 0.0:
		return

	_spawn_enemy("drifter")
	prime_frenzy_timer = prime_frenzy_interval
	_update_ui()


func _wave_progress_ratio() -> float:
	if total_wave_spawn_count <= 0:
		return 1.0
	return clamp(float(spawned_wave_count) / float(total_wave_spawn_count), 0.0, 1.0)


func _trigger_solar_flare() -> void:
	var sun: Vector2 = _sun_pos()
	for i in range(enemies.size() - 1, -1, -1):
		if i >= enemies.size():
			continue
		var enemy_pos: Vector2 = enemies[i]["pos"]
		shots.append({"from": sun, "to": enemy_pos, "ttl": 0.22, "color": Color(1.0, 0.78, 0.24, 0.90)})
		_damage_enemy(i, FLARE_DAMAGE, "solar_flare")


func _process_spawning(delta: float) -> void:
	if spawn_queue.is_empty():
		return

	spawn_timer -= delta
	while spawn_timer <= 0.0 and not spawn_queue.is_empty():
		var spawn_info: Dictionary = spawn_queue.pop_front()
		spawned_wave_count += 1
		_spawn_enemy(str(spawn_info.get("variant", "drifter")))
		spawn_timer += float(spawn_info.get("interval", 2.0))
		_update_ui()


func _process_towers(delta: float) -> void:
	for i in range(towers.size()):
		var tower: Dictionary = towers[i]
		var ring: Dictionary = RINGS[int(tower["ring"])]
		tower["angle"] = wrapf(float(tower["angle"]) + TAU / float(ring["period"]) * delta, 0.0, TAU)
		tower["fire_timer"] = max(float(tower["fire_timer"]) - delta, 0.0)

		if _is_tower_disabled(tower):
			towers[i] = tower
			continue

		if GameState.game_phase == GameState.Phase.WAVE_ACTIVE and float(tower["fire_timer"]) <= 0.0:
			if str(tower["type"]) == "bio_lab":
				var burrower_index: int = _find_burrower_target_for_tower(tower)
				if burrower_index != -1:
					_fire_tower_at_burrower(tower, burrower_index)
					tower["fire_timer"] = _tower_fire_interval(tower)
					towers[i] = tower
					continue

			var target_index: int = _find_target_for_tower(tower)
			if target_index != -1:
				_fire_tower(tower, target_index)
				tower["fire_timer"] = _tower_fire_interval(tower)

		towers[i] = tower


func _process_enemies(delta: float) -> void:
	if enemies.is_empty():
		return

	var sun: Vector2 = _sun_pos()
	var survivors: Array = []
	var reached_sun: bool = false
	var direct_breach: bool = false
	for enemy in enemies:
		if float(enemy["hp"]) <= 0.0:
			continue

		var pos: Vector2 = enemy["pos"]
		var to_sun: Vector2 = sun - pos
		var dist: float = to_sun.length()
		if dist <= SUN_DAMAGE_RADIUS:
			if str(enemy["variant"]) == "burrower":
				_lodge_burrower(enemy)
			else:
				GameState.damage_sun(float(enemy["damage"]))
				direct_breach = true
			reached_sun = true
			continue

		var speed_multiplier: float = 0.5 if float(enemy["slow_timer"]) > 0.0 else 1.0
		enemy["slow_timer"] = max(float(enemy["slow_timer"]) - delta, 0.0)
		if dist > 0.0:
			enemy["pos"] = pos + to_sun.normalized() * float(enemy["speed"]) * speed_multiplier * delta
		survivors.append(enemy)

	enemies = survivors
	if reached_sun and direct_breach:
		_set_message("The corona was breached. Luminosity is falling.", 2.0)
		_update_ui()

	if GameState.game_phase == GameState.Phase.GAME_OVER:
		wave_active = false
		spawn_queue.clear()
		_play_ending_music()
		_set_message("Game over. The Sun was extinguished.", 999.0)
		_update_ui()


func _process_burrowers(delta: float) -> void:
	if burrowers.is_empty():
		return

	for i in range(burrowers.size()):
		var burrower: Dictionary = burrowers[i]
		burrower["drain_timer"] = float(burrower["drain_timer"]) - delta
		if float(burrower["drain_timer"]) <= 0.0:
			GameState.damage_sun(BURROWER_DRAIN_DAMAGE)
			burrower["drain_timer"] = BURROWER_DRAIN_INTERVAL
			_update_ui()
		burrowers[i] = burrower

	if GameState.game_phase == GameState.Phase.GAME_OVER:
		wave_active = false
		spawn_queue.clear()
		_play_ending_music()
		_set_message("Game over. The Sun was hollowed out from within.", 999.0)
		_update_ui()


func _process_shots(delta: float) -> void:
	var active_shots: Array = []
	for shot in shots:
		shot["ttl"] = float(shot["ttl"]) - delta
		if float(shot["ttl"]) > 0.0:
			active_shots.append(shot)
	shots = active_shots


func _check_wave_clear() -> void:
	if not wave_active:
		return
	if GameState.game_phase != GameState.Phase.WAVE_ACTIVE:
		return
	if not spawn_queue.is_empty() or not enemies.is_empty() or not burrowers.is_empty():
		return

	wave_active = false
	_end_wave_event()
	var reward: int = int(current_wave_data.get("credit_reward", 0))
	GameState.add_credits(reward)
	GameState.on_wave_cleared()

	if GameState.current_wave >= playable_wave_limit and playable_wave_limit < MAX_WAVES:
		GameState.set_phase(GameState.Phase.BETWEEN_WAVE)
		_refresh_next_wave_preview()
		_set_message("Wave %d cleared. Additional waves are locked for this scene." % GameState.current_wave, 999.0)
	elif GameState.current_wave >= MAX_WAVES:
		GameState.trigger_victory()
		_play_ending_music()
		_set_message("Victory. Final rank: %s." % GameState.get_rank(), 999.0)
	else:
		GameState.set_phase(GameState.Phase.BETWEEN_WAVE)
		_refresh_next_wave_preview()
		_set_message("Wave %d cleared. Corps reward: %d Sol Credits." % [GameState.current_wave, reward], 4.0)
	_update_ui()


func _load_wave(wave_number: int) -> Dictionary:
	var path: String = "res://data/waves/wave_%02d.json" % wave_number
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return _normalize_wave_data(parsed, wave_number)


func _normalize_wave_data(data: Dictionary, wave_number: int) -> Dictionary:
	var default_interval: float = float(data.get("spawn_interval", 2.0))
	var spawns: Array = []

	if data.has("spawns"):
		for entry in data.get("spawns", []):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			spawns.append({
				"variant": _variant_key(entry.get("variant", 0)),
				"count": int(entry.get("count", 0)),
				"interval": float(entry.get("interval", default_interval)),
			})
	elif data.has("enemies"):
		for entry in data.get("enemies", []):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			spawns.append({
				"variant": _variant_key(entry.get("variant", "drifter")),
				"count": int(entry.get("count", 0)),
				"interval": default_interval,
			})

	return {
		"index": int(data.get("index", data.get("wave", wave_number))),
		"name": str(data.get("name", "Wave %02d" % wave_number)),
		"credit_reward": int(data.get("credit_reward", data.get("reward_base", 0))),
		"spawns": spawns,
		"event": data.get("event", null),
		"tutorial_hint": str(data.get("tutorial_hint", "Defend the Sun.")),
	}


func _build_spawn_queue(wave_data: Dictionary) -> Array:
	var queue: Array = []
	for entry in wave_data.get("spawns", []):
		var variant: String = _variant_key(entry.get("variant", 0))
		var count: int = int(entry.get("count", 0))
		var interval: float = float(entry.get("interval", 2.0))
		for _i in range(count):
			queue.append({"variant": variant, "interval": interval})
	return queue


func _spawn_enemy(variant: String, spawn_pos = null) -> void:
	var key: String = _variant_key(variant)
	var cfg: Dictionary = _enemy_config(key)
	var sun: Vector2 = _sun_pos()
	var angle: float = randf() * TAU
	var outer_ring: Dictionary = RINGS.back()
	var distance: float = float(outer_ring["radius"]) + ENEMY_SPAWN_PADDING
	var pos: Vector2 = sun + Vector2(cos(angle), sin(angle)) * distance
	if spawn_pos is Vector2:
		pos = spawn_pos

	enemies.append({
		"variant": key,
		"variant_id": cfg["variant_id"],
		"label": cfg["label"],
		"pos": pos,
		"hp": cfg["hp"],
		"max_hp": cfg["hp"],
		"speed": cfg["speed"],
		"damage": cfg["damage"],
		"reward": cfg["reward"],
		"radius": cfg["radius"],
		"draw_size": cfg["draw_size"],
		"color": cfg["color"],
		"slow_timer": 0.0,
		"prime_phase": 0,
	})


func _find_target_for_tower(tower: Dictionary) -> int:
	var tower_pos: Vector2 = _tower_position(tower)
	var sun: Vector2 = _sun_pos()
	var cfg: Dictionary = _tower_config(str(tower["type"]))
	var best_index: int = -1
	var best_sun_dist: float = INF

	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		var tower_dist: float = tower_pos.distance_to(enemy["pos"])
		var sun_dist: float = sun.distance_to(enemy["pos"])
		if tower_dist <= float(cfg["range"]) and sun_dist < best_sun_dist:
			best_index = i
			best_sun_dist = sun_dist

	return best_index


func _fire_tower(tower: Dictionary, enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return

	var cfg: Dictionary = _tower_config(str(tower["type"]))
	var tower_pos: Vector2 = _tower_position(tower)
	var enemy_pos: Vector2 = enemies[enemy_index]["pos"]
	shots.append({"from": tower_pos, "to": enemy_pos, "ttl": 0.14, "color": cfg["color"]})
	_damage_enemy(enemy_index, float(cfg["damage"]), str(tower["type"]))


func _tower_fire_interval(tower: Dictionary) -> float:
	var cfg: Dictionary = _tower_config(str(tower["type"]))
	var rate: float = float(cfg["rate"])
	if str(tower["type"]) == "bio_lab" and bio_lab_boost_timer > 0.0:
		rate *= bio_lab_boost_multiplier
	return 1.0 / max(rate, 0.01)


func _is_tower_disabled(tower: Dictionary) -> bool:
	if _is_ring_blinded(int(tower["ring"])):
		return true
	if str(tower["type"]) == "cryo_probe" and cryo_disruption_timer > 0.0:
		return true
	return false


func _is_ring_blinded(ring_index: int) -> bool:
	return ring_blind_timers.has(ring_index) and float(ring_blind_timers[ring_index]) > 0.0


func _find_burrower_target_for_tower(tower: Dictionary) -> int:
	if burrowers.is_empty():
		return -1

	var tower_pos: Vector2 = _tower_position(tower)
	var cfg: Dictionary = _tower_config(str(tower["type"]))
	var best_index: int = -1
	var best_hp: float = INF
	for i in range(burrowers.size()):
		var burrower_pos: Vector2 = _burrower_position(burrowers[i])
		if tower_pos.distance_to(burrower_pos) <= float(cfg["range"]) and float(burrowers[i]["hp"]) < best_hp:
			best_index = i
			best_hp = float(burrowers[i]["hp"])
	return best_index


func _fire_tower_at_burrower(tower: Dictionary, burrower_index: int) -> void:
	if burrower_index < 0 or burrower_index >= burrowers.size():
		return

	var cfg: Dictionary = _tower_config(str(tower["type"]))
	var tower_pos: Vector2 = _tower_position(tower)
	var burrower_pos: Vector2 = _burrower_position(burrowers[burrower_index])
	shots.append({"from": tower_pos, "to": burrower_pos, "ttl": 0.14, "color": cfg["color"]})
	_damage_burrower(burrower_index, float(cfg["damage"]))


func _damage_burrower(burrower_index: int, amount: float) -> void:
	if burrower_index < 0 or burrower_index >= burrowers.size():
		return

	var burrower: Dictionary = burrowers[burrower_index]
	burrower["hp"] = float(burrower["hp"]) - amount
	if float(burrower["hp"]) <= 0.0:
		burrowers.remove_at(burrower_index)
		GameState.remove_burrower()
		_set_message("Bio-Lab excavated a Coronal Burrower.", 1.6)
	else:
		burrowers[burrower_index] = burrower
	_update_ui()


func _damage_enemy(enemy_index: int, amount: float, source: String) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return

	var enemy: Dictionary = enemies[enemy_index]
	var variant: String = str(enemy["variant"])

	if variant == "mimic" and source == "photon_splitter":
		return

	if source == "cryo_probe" or source == "magnetic_net":
		enemy["slow_timer"] = 2.8

	if variant == "farmer" and (source == "photon_splitter" or source == "helios_cannon"):
		enemy["hp"] = min(float(enemy["hp"]) + amount * 0.4, float(enemy["max_hp"]) * 1.8)
		enemy["speed"] = min(float(enemy["speed"]) + 1.0, 150.0)
		enemies[enemy_index] = enemy
		return

	if variant == "prime" and int(enemy["prime_phase"]) == 0 and source != "bio_lab":
		return
	elif variant == "prime" and int(enemy["prime_phase"]) == 0 and source == "bio_lab":
		enemy["prime_phase"] = 1
		_set_message("Bio-Lab cracked Prime's shell.", 2.0)

	enemy["hp"] = float(enemy["hp"]) - amount
	enemies[enemy_index] = enemy

	if float(enemy["hp"]) <= 0.0:
		_defeat_enemy(enemy_index)


func _defeat_enemy(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return

	var enemy: Dictionary = enemies[enemy_index]
	var variant: String = str(enemy["variant"])
	var pos: Vector2 = enemy["pos"]

	GameState.add_credits(int(enemy["reward"]))
	GameState.on_enemy_killed(int(enemy["variant_id"]))

	enemies.remove_at(enemy_index)

	if variant == "bloom":
		for i in range(3):
			var offset: Vector2 = Vector2.RIGHT.rotated(TAU * float(i) / 3.0) * 24.0
			_spawn_enemy("drifter", pos + offset)
	elif variant == "prime":
		_set_message("Astrophage Prime has collapsed. Clear the remaining swarm.", 3.0)

	_update_ui()


func _lodge_burrower(enemy: Dictionary) -> void:
	var sun: Vector2 = _sun_pos()
	var enemy_pos: Vector2 = enemy["pos"]
	var angle: float = (enemy_pos - sun).angle()
	burrowers.append({
		"angle": angle,
		"hp": BURROWER_EXCAVATION_HP,
		"max_hp": BURROWER_EXCAVATION_HP,
		"drain_timer": BURROWER_DRAIN_INTERVAL,
		"color": enemy.get("color", Color(0.76, 0.50, 0.30)),
	})
	GameState.add_burrower()
	_set_message("A Coronal Burrower is lodged in the Sun. Bio-Lab can excavate it.", 3.0)
	_update_ui()


func _nearest_ring_slot(pos: Vector2) -> Dictionary:
	var sun: Vector2 = _sun_pos()
	var best: Dictionary = {}
	var best_diff: float = INF
	for i in range(RINGS.size()):
		var ring: Dictionary = RINGS[i]
		var diff: float = abs(pos.distance_to(sun) - float(ring["radius"]))
		if diff < 24.0 and diff < best_diff:
			var angle: float = (pos - sun).angle()
			var slot_index: int = _nearest_slot_index(i, angle)
			best = {
				"ring_index": i,
				"ring_name": ring["name"],
				"slot_index": slot_index,
				"angle": _ring_slot_angle(i, slot_index),
				"occupied": _is_slot_taken(i, slot_index),
			}
			best_diff = diff
	return best


func _nearest_slot_index(ring_index: int, angle: float) -> int:
	var slots: int = int(RINGS[ring_index]["slots"])
	var step: float = TAU / float(slots)
	var normalized: float = wrapf(angle - SLOT_ANGLE_OFFSET, 0.0, TAU)
	return int(round(normalized / step)) % slots


func _ring_slot_angle(ring_index: int, slot_index: int) -> float:
	var slots: int = int(RINGS[ring_index]["slots"])
	return wrapf(SLOT_ANGLE_OFFSET + TAU * float(slot_index) / float(slots), 0.0, TAU)


func _ring_slot_position(ring_index: int, slot_index: int) -> Vector2:
	var angle: float = _ring_slot_angle(ring_index, slot_index)
	return _sun_pos() + Vector2(cos(angle), sin(angle)) * float(RINGS[ring_index]["radius"])


func _is_slot_taken(ring_index: int, slot_index: int) -> bool:
	for tower in towers:
		if int(tower["ring"]) == ring_index and int(tower["slot"]) == slot_index:
			return true
	return false


func _tower_position(tower: Dictionary) -> Vector2:
	return _sun_pos() + Vector2(cos(float(tower["angle"])), sin(float(tower["angle"]))) * float(RINGS[int(tower["ring"])]["radius"])


func _burrower_position(burrower: Dictionary) -> Vector2:
	return _sun_pos() + Vector2(cos(float(burrower["angle"])), sin(float(burrower["angle"]))) * BURROWER_DIG_RADIUS


func _draw_sun(pos: Vector2) -> void:
	var glow_strength: float = clamp(GameState.luminosity, 0.15, 1.0)
	var rim_color: Color = Color(0.95, 0.43, 0.08)
	var core_color: Color = Color(1.0, 0.72, 0.18)
	var highlight_color: Color = Color(1.0, 0.93, 0.42, 0.72)

	match _sun_state_key():
		"concerned":
			rim_color = Color(0.92, 0.35, 0.08)
			core_color = Color(1.0, 0.62, 0.16)
		"distressed":
			rim_color = Color(0.78, 0.20, 0.08)
			core_color = Color(1.0, 0.48, 0.12)
			highlight_color = Color(1.0, 0.76, 0.24, 0.58)
		"critical":
			rim_color = Color(0.62, 0.08, 0.05)
			core_color = Color(0.92, 0.22, 0.09)
			highlight_color = Color(1.0, 0.46, 0.18, 0.45)

	draw_circle(pos, SUN_RADIUS + 34.0, Color(core_color.r, core_color.g, core_color.b, 0.08 * glow_strength))
	draw_circle(pos, SUN_RADIUS + 18.0, Color(core_color.r, core_color.g, core_color.b, 0.16 * glow_strength))
	draw_circle(pos, SUN_RADIUS + 6.0, Color(rim_color.r, rim_color.g, rim_color.b, 0.92))
	draw_circle(pos, SUN_RADIUS, core_color)
	draw_circle(pos + Vector2(-13.0, -12.0), SUN_RADIUS * 0.56, highlight_color)
	draw_circle(pos + Vector2(17.0, 15.0), SUN_RADIUS * 0.34, Color(rim_color.r, rim_color.g, rim_color.b, 0.28))


func _draw_tower(tower: Dictionary) -> void:
	var pos: Vector2 = _tower_position(tower)
	var cfg: Dictionary = _tower_config(str(tower["type"]))
	var tower_color: Color = cfg["color"]
	var texture = _tower_texture(str(tower["type"]))
	var disabled: bool = _is_tower_disabled(tower)
	draw_circle(pos, 24.0, Color(0.04, 0.07, 0.12, 0.74))
	if not disabled:
		draw_circle(pos, float(cfg["range"]), Color(tower_color.r, tower_color.g, tower_color.b, 0.025))
	if texture:
		var size: Vector2 = Vector2(42.0, 42.0)
		draw_texture_rect(texture, Rect2(pos - size * 0.5, size), false)
	else:
		draw_circle(pos, 13.0, tower_color)
	if disabled:
		draw_circle(pos, 26.0, Color(0.02, 0.02, 0.03, 0.56))
		draw_line(pos + Vector2(-12.0, -12.0), pos + Vector2(12.0, 12.0), Color(0.78, 0.84, 0.92, 0.65), 2.0)
	draw_line(pos, _sun_pos(), Color(0.36, 0.50, 0.68, 0.20), 1.0)


func _draw_enemy(enemy: Dictionary) -> void:
	var pos: Vector2 = enemy["pos"]
	var radius: float = float(enemy["radius"])
	var hp_ratio: float = clamp(float(enemy["hp"]) / float(enemy["max_hp"]), 0.0, 1.0)
	var enemy_color: Color = enemy["color"]
	var texture = _enemy_texture(str(enemy["variant"]))

	draw_circle(pos, radius + 4.0, Color(0.02, 0.02, 0.03, 0.78))
	if texture:
		var size: Vector2 = Vector2(float(enemy["draw_size"]), float(enemy["draw_size"]))
		draw_texture_rect(texture, Rect2(pos - size * 0.5, size), false)
	else:
		draw_circle(pos, radius, enemy_color)
	draw_line(pos + Vector2(-radius, -radius - 10.0), pos + Vector2(radius, -radius - 10.0), Color(0.22, 0.08, 0.08), 3.0)
	draw_line(pos + Vector2(-radius, -radius - 10.0), pos + Vector2(-radius + radius * 2.0 * hp_ratio, -radius - 10.0), Color(0.45, 1.0, 0.42), 3.0)


func _draw_burrower(burrower: Dictionary) -> void:
	var pos: Vector2 = _burrower_position(burrower)
	var hp_ratio: float = clamp(float(burrower["hp"]) / float(burrower["max_hp"]), 0.0, 1.0)
	var burrower_color: Color = burrower.get("color", Color(0.76, 0.50, 0.30))
	draw_circle(pos, 18.0, Color(0.02, 0.01, 0.01, 0.72))
	draw_circle(pos, 11.0, burrower_color)
	draw_circle(pos, 5.0, Color(0.18, 0.08, 0.04, 0.85))
	draw_line(pos + Vector2(-14.0, -20.0), pos + Vector2(14.0, -20.0), Color(0.20, 0.05, 0.04, 0.85), 3.0)
	draw_line(pos + Vector2(-14.0, -20.0), pos + Vector2(-14.0 + 28.0 * hp_ratio, -20.0), Color(0.50, 1.0, 0.48, 0.95), 3.0)


func _sun_pos() -> Vector2:
	return get_viewport_rect().size * 0.5


func _sun_state_key() -> String:
	if GameState.luminosity <= 0.2:
		return "critical"
	if GameState.luminosity <= 0.45:
		return "distressed"
	if GameState.luminosity <= 0.75:
		return "concerned"
	return "happy"


func _refresh_next_wave_preview() -> void:
	var next_wave: int = int(clamp(GameState.current_wave + 1, 1, playable_wave_limit))
	next_wave_preview = _load_wave(next_wave)


func _is_prime_alive() -> bool:
	for enemy in enemies:
		if str(enemy["variant"]) == "prime":
			return true
	return false


func _variant_key(raw) -> String:
	if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
		var idx: int = int(raw)
		if idx >= 0 and idx < VARIANT_KEYS.size():
			return VARIANT_KEYS[idx]
		return "drifter"

	var cleaned: String = str(raw).strip_edges().to_lower()
	if cleaned.is_valid_int():
		return _variant_key(cleaned.to_int())
	cleaned = cleaned.replace(" ", "_").replace("-", "_")
	match cleaned:
		"drifter":
			return "drifter"
		"bloom":
			return "bloom"
		"burrower", "coronal_burrower":
			return "burrower"
		"mimic", "photon_mimic":
			return "mimic"
		"farmer", "solar_farmer":
			return "farmer"
		"prime", "astrophage_prime":
			return "prime"
		_:
			return "drifter"


func _tower_config(tower_type: String) -> Dictionary:
	return TOWER_CONFIGS.get(tower_type, TOWER_CONFIGS["photon_splitter"])


func _enemy_config(variant: String) -> Dictionary:
	return ENEMY_CONFIGS.get(variant, ENEMY_CONFIGS["drifter"])


func _tower_texture(tower_type: String):
	return textures["towers"].get(tower_type, null)


func _enemy_texture(variant: String):
	return textures["enemies"].get(variant, null)


func _primary_wave_variant(wave_data: Dictionary) -> String:
	var spawns: Array = wave_data.get("spawns", [])
	if spawns.is_empty():
		return "drifter"
	return _variant_key(spawns[0].get("variant", "drifter"))


func _wave_spawn_summary(wave_data: Dictionary) -> String:
	var parts: Array = []
	for entry in wave_data.get("spawns", []):
		var variant: String = _variant_key(entry.get("variant", 0))
		parts.append("%d %s" % [int(entry.get("count", 0)), _enemy_short_label(variant)])
	return ", ".join(parts) if not parts.is_empty() else "No spawns loaded"


func _enemy_short_label(variant: String) -> String:
	match variant:
		"burrower":
			return "Burrower"
		"mimic":
			return "Mimic"
		"farmer":
			return "Farmer"
		"prime":
			return "Prime"
		_:
			return str(_enemy_config(variant)["label"])


func _ring_summary() -> String:
	var lines: Array = []
	for ring in RINGS:
		lines.append("R%d %s  r%d | %ds | %d slots" % [int(ring["id"]), ring["name"], int(ring["radius"]), int(ring["period"]), int(ring["slots"])])
	return "\n".join(lines)


func _active_modifier_summary() -> String:
	var parts: Array = []
	if cryo_disruption_timer > 0.0:
		parts.append("Cryo offline %.0fs" % cryo_disruption_timer)
	if bio_lab_boost_timer > 0.0:
		parts.append("Bio %.0fx" % bio_lab_boost_multiplier)
	if not ring_blind_timers.is_empty():
		var ring_parts: Array = []
		for ring_index in ring_blind_timers.keys():
			ring_parts.append("R%d %.0fs" % [int(ring_index) + 1, float(ring_blind_timers[ring_index])])
		parts.append("Dark %s" % ", ".join(ring_parts))
	if not parts.is_empty():
		return "\n%s" % " | ".join(parts)
	return ""


func _clean_wave_hint(text: String, wave_name: String) -> String:
	var repeated_prefix: String = "%s: " % wave_name
	if text.begins_with(repeated_prefix):
		return text.substr(repeated_prefix.length())
	return text


func _tower_short_label(tower_type: String) -> String:
	match tower_type:
		"photon_splitter":
			return "Photon"
		"cryo_probe":
			return "Cryo"
		"bio_lab":
			return "Bio-Lab"
		"magnetic_net":
			return "Mag Net"
		"helios_cannon":
			return "Helios"
		"tardigrade_bomb":
			return "Tardi"
		_:
			return str(_tower_config(tower_type)["label"])


func _set_message(text: String, duration: float = 0.0) -> void:
	message_text = text
	message_timer = duration
	_update_ui()


func _update_ui() -> void:
	if ui.is_empty():
		return

	var wave_data: Dictionary = current_wave_data if GameState.game_phase == GameState.Phase.WAVE_ACTIVE else next_wave_preview
	var wave_index: int = int(wave_data.get("index", min(GameState.current_wave + 1, MAX_WAVES)))
	var wave_name: String = str(wave_data.get("name", "First Contact"))
	var title_text: String = "WAVE %d/%d - %s" % [wave_index, MAX_WAVES, wave_name]
	if GameState.game_phase != GameState.Phase.WAVE_ACTIVE:
		title_text = "%s %d/%d" % [briefing_title, wave_index, MAX_WAVES]
		if briefing_title.strip_edges().to_lower() != wave_name.strip_edges().to_lower():
			title_text += " - %s" % wave_name

	ui["wave_label"].text = title_text
	ui["brief_label"].text = _clean_wave_hint(str(wave_data.get("tutorial_hint", "Defend the Sun.")), wave_name)
	ui["credits_label"].text = str(GameState.sol_credits)
	ui["score_label"].text = str(GameState.performance_score)
	ui["kills_label"].text = str(GameState.enemies_killed_total)
	ui["flare_label"].text = "Ready" if GameState.flare_charge > 0 else "Charging"
	ui["luminosity_bar"].value = GameState.get_luminosity_percent()

	var reward: int = int(wave_data.get("credit_reward", 0))
	ui["enemy_preview"].texture = _enemy_texture(_primary_wave_variant(wave_data))
	ui["enemy_label"].text = _wave_spawn_summary(wave_data)
	ui["threat_label"].text = "Active %d | Burrowed %d | Queue %d | Reward %d Sol%s" % [enemies.size(), burrowers.size(), spawn_queue.size(), reward, _active_modifier_summary()]
	ui["ring_label"].text = _ring_summary()

	var next_wave: int = min(GameState.current_wave + 1, MAX_WAVES)
	ui["start_button"].text = "Start Wave %d" % next_wave
	ui["start_button"].disabled = GameState.game_phase != GameState.Phase.BETWEEN_WAVE or next_wave > playable_wave_limit

	for tower_type in TOWER_ORDER:
		var button: Button = ui["tower_buttons"][tower_type]
		var cost: int = GameState.get_tower_cost(tower_type)
		var cfg: Dictionary = _tower_config(tower_type)
		button.text = "%s\n%d Sol" % [_tower_short_label(tower_type), cost]
		button.tooltip_text = "%s | Cost: %d Sol Credits" % [cfg["label"], cost]
		button.set_pressed_no_signal(tower_type == selected_tower)
		button.disabled = GameState.game_phase != GameState.Phase.BETWEEN_WAVE or not GameState.can_afford(cost)

	ui["message_label"].text = message_text
