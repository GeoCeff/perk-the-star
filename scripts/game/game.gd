extends Node2D

const SpaceTheme = preload("res://scripts/ui/space_theme.gd")

const MAX_WAVES: int = 12
const SUN_RADIUS: float = 58.0
const SUN_DAMAGE_RADIUS: float = 62.0
const RING_RADIUS_SCALE: float = 1.5
const ENEMY_SPAWN_PADDING: float = 260.0
const SLOT_ANGLE_OFFSET: float = -PI / 2.0
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
const GAME_HUD_SCENE_PATH: String = "res://scenes/ui/game_hud.tscn"
const GAME_PAUSE_MENU_SCENE_PATH: String = "res://scenes/ui/game_pause_menu.tscn"
const BATTLE_BACKGROUND_PATH: String = "res://assets/sprites/backgrounds/battle_nebula_hq.png"
const WAVE_TRACK_SWAP_SECONDS: float = 55.0
const VIEW_ZOOM_MIN: float = 0.65
const VIEW_ZOOM_MAX: float = 1.85
const VIEW_ZOOM_STEP: float = 1.12
const VIEW_EDGE_PAN_MARGIN: float = 34.0
const VIEW_EDGE_PAN_BOTTOM_MARGIN: float = 92.0
const VIEW_EDGE_PAN_SPEED: float = 560.0

const ENEMY_ASSET_PATHS: Dictionary = {
	"drifter": "res://assets/sprites/enemies/Drifter.png",
	"bloom": "res://assets/sprites/enemies/Bloom.png",
	"burrower": "res://assets/sprites/enemies/Coronal Burrower.png",
	"mimic": "res://assets/sprites/enemies/Photon Mimic.png",
	"farmer": "res://assets/sprites/enemies/Solar Farmer.png",
	"prime": "res://assets/sprites/enemies/ASTROPHAGE PRIME.png",
}

const TOWER_ASSET_PATHS: Dictionary = {
	"photon_splitter": "res://assets/sprites/clean/towers/photon_splitter.png",
	"cryo_probe": "res://assets/sprites/clean/towers/cryo_probe.png",
	"bio_lab": "res://assets/sprites/clean/towers/bio_lab.png",
	"magnetic_net": "res://assets/sprites/clean/towers/magnetic_net.png",
	"helios_cannon": "res://assets/sprites/clean/towers/helios_cannon.png",
	"tardigrade_bomb": "res://assets/sprites/clean/towers/tardigrade_bomb.png",
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

const TOWER_INFO: Dictionary = {
	"photon_splitter": {
		"role": "STEADY BEAM  |  EARLY INTERCEPT",
		"body": "Fast, reliable single-target damage for thinning the first Astrophage lines.",
		"note": "Caution: Photon Mimics ignore it and Solar Farmers feed on photon fire.",
	},
	"cryo_probe": {
		"role": "CONTROL  |  SLOW FIELD",
		"body": "Low damage, but every hit chills targets and cuts their speed for a short window.",
		"note": "Can be forced offline by solar storm events.",
	},
	"bio_lab": {
		"role": "SUPPORT  |  EXCAVATION",
		"body": "Analyzes weak points, clears Coronal Burrowers, and can crack Prime's shell.",
		"note": "Research surge events can temporarily multiply Bio-Lab fire rate.",
	},
	"magnetic_net": {
		"role": "CONTROL  |  LONG RANGE",
		"body": "Wide reach and slow effects make it strong at keeping enemies inside kill zones.",
		"note": "Pair with high-damage towers to capitalize on slowed targets.",
	},
	"helios_cannon": {
		"role": "BURST  |  HEAVY ORDNANCE",
		"body": "Slow-firing cannon with high impact damage and excellent range.",
		"note": "Caution: Solar Farmers absorb Helios fire and accelerate.",
	},
	"tardigrade_bomb": {
		"role": "HEAVY SHOT  |  FINISHER",
		"body": "Delivers chunky damage at a measured pace for tougher enemies that survive the net.",
		"note": "Best after Cryo or Magnetic Net has slowed the lane.",
	},
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
var message_text: String = "Select an orbital slot, then start Wave 1."
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
var game_hud: GameHud
var textures: Dictionary = {
	"enemies": {},
	"towers": {},
}
var bgm_player: AudioStreamPlayer
var battle_background_texture: Texture2D
var wave_music_index: int = 0
var wave_music_timer: float = 0.0
var ending_music_started: bool = false
var last_viewport_size: Vector2 = Vector2.ZERO
var view_offset: Vector2 = Vector2.ZERO
var view_zoom: float = 1.0
var view_panning: bool = false


func _ready() -> void:
	randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	SpaceTheme.apply_cursor()
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
	var viewport_changed: bool = _refresh_viewport_cache()
	var view_changed: bool = _process_edge_pan(delta)
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message_text = "Build between waves. Towers orbit and fire automatically."
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
	if view_changed or _needs_frame_redraw(viewport_changed):
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and view_panning:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		view_offset += motion.relative
		_clamp_view_offset()
		queue_redraw()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		match mouse_button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if mouse_button.pressed:
					_set_view_zoom(view_zoom * VIEW_ZOOM_STEP, mouse_button.position)
					get_viewport().set_input_as_handled()
				return
			MOUSE_BUTTON_WHEEL_DOWN:
				if mouse_button.pressed:
					_set_view_zoom(view_zoom / VIEW_ZOOM_STEP, mouse_button.position)
					get_viewport().set_input_as_handled()
				return
			MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT:
				view_panning = mouse_button.pressed
				get_viewport().set_input_as_handled()
				return
			MOUSE_BUTTON_LEFT:
				if not mouse_button.pressed:
					return
				if GameState.game_phase != GameState.Phase.BETWEEN_WAVE:
					return
				_place_tower_from_screen_position(mouse_button.position)
				get_viewport().set_input_as_handled()
				return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and (key_event.keycode == KEY_HOME or key_event.keycode == KEY_0):
			_reset_view()
			get_viewport().set_input_as_handled()
		return


func _place_tower_from_screen_position(screen_position: Vector2) -> void:
	var click_pos: Vector2 = _screen_to_world(screen_position)
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
	queue_redraw()


func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var sun: Vector2 = _sun_pos()
	var time_seconds: float = Time.get_ticks_msec() / 1000.0

	_draw_battle_background(viewport_size)
	for star in stars:
		var star_color: Color = star["color"]
		var base_pos: Vector2 = star["pos"]
		var phase: float = float(star.get("phase", 0.0))
		var speed: float = float(star.get("speed", 1.0))
		var star_pos: Vector2 = Vector2(
			wrapf(base_pos.x + time_seconds * speed + sin(time_seconds * 0.35 + phase) * 3.0 + view_offset.x * 0.10, -8.0, viewport_size.x + 8.0),
			wrapf(base_pos.y + cos(time_seconds * 0.28 + phase) * 2.5 + view_offset.y * 0.10, -8.0, viewport_size.y + 8.0)
		)
		star_color.a = clamp(star_color.a * (0.80 + sin(time_seconds * 1.15 + phase) * 0.22), 0.04, 0.78)
		draw_circle(star_pos, float(star["radius"]), star_color)

	draw_set_transform(_view_translation(viewport_size), 0.0, Vector2(view_zoom, view_zoom))
	_draw_orbit_rings(sun)
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

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if GameState.game_phase == GameState.Phase.GAME_OVER:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.0, 0.0, 0.0, 0.58), true)
	elif GameState.game_phase == GameState.Phase.VICTORY:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(1.0, 0.78, 0.18, 0.12), true)


func _draw_battle_background(viewport_size: Vector2) -> void:
	if battle_background_texture == null:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.012, 0.018, 0.034), true)
		return

	var texture_size: Vector2 = battle_background_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.012, 0.018, 0.034), true)
		return

	var time_seconds: float = Time.get_ticks_msec() / 1000.0
	var breath: float = 1.0 + sin(time_seconds * 0.18) * 0.010
	var scale: float = max(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y) * 1.025 * breath
	var draw_size: Vector2 = texture_size * scale
	var drift: Vector2 = Vector2(sin(time_seconds * 0.08) * 14.0, cos(time_seconds * 0.06) * 11.0)
	var parallax: Vector2 = view_offset * 0.08
	var draw_origin: Vector2 = (viewport_size - draw_size) * 0.5 + drift + parallax
	draw_texture_rect(battle_background_texture, Rect2(draw_origin, draw_size), false)
	draw_texture_rect(
		battle_background_texture,
		Rect2((viewport_size - draw_size * 1.015) * 0.5 - drift * 0.38 + parallax * 0.55, draw_size * 1.015),
		false,
		Color(0.36, 0.86, 1.0, 0.21)
	)

	var pulse: float = 0.5 + sin(time_seconds * 0.60) * 0.5
	var slow_pulse: float = 0.5 + sin(time_seconds * 0.28 + 1.7) * 0.5
	var glow_a: Vector2 = Vector2(viewport_size.x * (0.30 + sin(time_seconds * 0.05) * 0.08), viewport_size.y * (0.34 + cos(time_seconds * 0.04) * 0.05))
	var glow_b: Vector2 = Vector2(viewport_size.x * (0.76 + cos(time_seconds * 0.04) * 0.07), viewport_size.y * (0.68 + sin(time_seconds * 0.03) * 0.05))
	var glow_c: Vector2 = Vector2(viewport_size.x * (0.50 + sin(time_seconds * 0.035) * 0.12), viewport_size.y * (0.50 + cos(time_seconds * 0.045) * 0.08))
	draw_circle(glow_a, min(viewport_size.x, viewport_size.y) * 0.42, Color(0.00, 0.62, 0.82, 0.042 + pulse * 0.032))
	draw_circle(glow_b, min(viewport_size.x, viewport_size.y) * 0.38, Color(1.00, 0.58, 0.16, 0.024 + (1.0 - pulse) * 0.022))
	draw_circle(glow_c, min(viewport_size.x, viewport_size.y) * 0.32, Color(0.24, 0.74, 1.0, 0.020 + slow_pulse * 0.026))
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.003, 0.008, 0.018, 0.34 + (1.0 - pulse) * 0.10), true)


func _draw_orbit_rings(sun: Vector2) -> void:
	var time_seconds: float = Time.get_ticks_msec() / 1000.0
	for i in range(RINGS.size()):
		var ring: Dictionary = RINGS[i]
		var ring_radius: float = _ring_radius(i)
		var ring_blinded: bool = _is_ring_blinded(i)
		var base_alpha: float = 0.22 - float(i) * 0.018
		var lane_color: Color = Color(0.34, 0.78, 1.0, base_alpha)
		var glow_color: Color = Color(0.12, 0.45, 0.72, 0.095)
		var tick_color: Color = Color(0.58, 0.88, 1.0, 0.24)
		var accent_color: Color = Color(1.0, 0.78, 0.26, 0.20)
		if ring_blinded:
			lane_color = Color(0.22, 0.26, 0.32, 0.24)
			glow_color = Color(0.10, 0.12, 0.16, 0.09)
			tick_color = Color(0.38, 0.44, 0.52, 0.18)
			accent_color = Color(0.50, 0.46, 0.34, 0.12)

		draw_arc(sun, ring_radius - 3.0, 0.0, TAU, 288, glow_color, 3.0, true)
		draw_arc(sun, ring_radius, 0.0, TAU, 288, lane_color, 1.15, true)
		draw_arc(sun, ring_radius + 4.0, 0.0, TAU, 288, Color(0.72, 0.92, 1.0, base_alpha * 0.22), 0.8, true)

		var sweep_offset: float = time_seconds * (0.04 + float(i) * 0.006) + float(i) * 0.37
		for segment in range(5):
			var start_angle: float = sweep_offset + TAU * float(segment) / 5.0
			draw_arc(sun, ring_radius + 1.8, start_angle, start_angle + 0.28, 20, accent_color, 1.8, true)

		var tick_count: int = int(ring["slots"]) * 2
		for tick_index in range(tick_count):
			var tick_angle: float = SLOT_ANGLE_OFFSET + TAU * float(tick_index) / float(tick_count)
			var direction: Vector2 = Vector2(cos(tick_angle), sin(tick_angle))
			var tick_length: float = 9.0 if tick_index % 2 == 0 else 5.0
			draw_line(
				sun + direction * (ring_radius - tick_length),
				sun + direction * (ring_radius + tick_length),
				tick_color,
				0.9
			)

		for slot_index in range(int(ring["slots"])):
			var slot_pos: Vector2 = _ring_slot_position(i, slot_index)
			var occupied: bool = _is_slot_taken(i, slot_index)
			var radial: Vector2 = (slot_pos - sun).normalized()
			var tangent: Vector2 = Vector2(-radial.y, radial.x)
			var fill_color: Color = Color(0.006, 0.016, 0.030, 0.72)
			var outline_color: Color = Color(0.44, 0.78, 1.0, 0.48)
			var core_color: Color = Color(0.60, 0.86, 1.0, 0.52)
			if occupied:
				outline_color = Color(1.0, 0.80, 0.25, 0.86)
				core_color = Color(1.0, 0.86, 0.34, 0.82)
			elif ring_blinded:
				outline_color = Color(0.36, 0.42, 0.50, 0.36)
				core_color = Color(0.34, 0.40, 0.48, 0.40)

			draw_circle(slot_pos, 7.2, fill_color)
			draw_arc(slot_pos, 7.8, 0.0, TAU, 36, outline_color, 1.05, true)
			draw_line(slot_pos - tangent * 10.0, slot_pos - tangent * 5.0, outline_color, 1.0)
			draw_line(slot_pos + tangent * 5.0, slot_pos + tangent * 10.0, outline_color, 1.0)
			draw_line(slot_pos - radial * 10.0, slot_pos - radial * 5.0, outline_color, 1.0)
			draw_line(slot_pos + radial * 5.0, slot_pos + radial * 10.0, outline_color, 1.0)
			draw_circle(slot_pos, 2.8 if occupied else 1.8, core_color)


func _load_assets() -> void:
	battle_background_texture = load(BATTLE_BACKGROUND_PATH) as Texture2D
	for key in ENEMY_ASSET_PATHS.keys():
		textures["enemies"][key] = load(str(ENEMY_ASSET_PATHS[key]))
	for key in TOWER_ASSET_PATHS.keys():
		textures["towers"][key] = load(str(TOWER_ASSET_PATHS[key]))

	bgm_player = get_node_or_null("Audio/GameMusic") as AudioStreamPlayer
	if bgm_player == null:
		bgm_player = get_node_or_null("GameMusic") as AudioStreamPlayer
	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "GameMusic"
		add_child(bgm_player)
	bgm_player.volume_db = GameState.get_music_volume_db()


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
	last_viewport_size = viewport_size
	for _i in range(120):
		stars.append({
			"pos": Vector2(randf() * viewport_size.x, randf() * viewport_size.y),
			"radius": randf_range(0.7, 2.0),
			"color": Color(0.62 + randf() * 0.32, 0.72 + randf() * 0.22, 1.0, 0.22 + randf() * 0.42),
			"phase": randf() * TAU,
			"speed": randf_range(-3.0, 4.5),
		})


func _refresh_viewport_cache() -> bool:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size == last_viewport_size:
		return false
	_generate_starfield()
	_clamp_view_offset()
	return true


func _needs_frame_redraw(viewport_changed: bool) -> bool:
	if viewport_changed:
		return true
	if GameState.game_phase == GameState.Phase.BETWEEN_WAVE:
		return true
	if GameState.game_phase == GameState.Phase.WAVE_ACTIVE:
		return true
	if GameState.game_phase == GameState.Phase.GAME_OVER or GameState.game_phase == GameState.Phase.VICTORY:
		return true
	if not towers.is_empty() or not enemies.is_empty() or not shots.is_empty() or not burrowers.is_empty():
		return true
	if cryo_disruption_timer > 0.0 or bio_lab_boost_timer > 0.0 or not ring_blind_timers.is_empty():
		return true
	return false


func _process_edge_pan(delta: float) -> bool:
	if view_panning:
		return false

	var viewport_rect: Rect2 = get_viewport_rect()
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	if not viewport_rect.has_point(mouse_position):
		return false

	var direction: Vector2 = Vector2.ZERO
	if mouse_position.x <= VIEW_EDGE_PAN_MARGIN:
		direction.x = 1.0
	elif mouse_position.x >= viewport_rect.size.x - VIEW_EDGE_PAN_MARGIN:
		direction.x = -1.0

	if mouse_position.y <= VIEW_EDGE_PAN_MARGIN:
		direction.y = 1.0
	elif mouse_position.y >= viewport_rect.size.y - VIEW_EDGE_PAN_BOTTOM_MARGIN:
		direction.y = -1.0

	if direction == Vector2.ZERO:
		return false
	if game_hud != null and game_hud.is_screen_position_over_hud(mouse_position):
		var in_edge_gutter: bool = (
			mouse_position.x <= VIEW_EDGE_PAN_MARGIN
			or mouse_position.x >= viewport_rect.size.x - VIEW_EDGE_PAN_MARGIN
			or mouse_position.y <= VIEW_EDGE_PAN_MARGIN
			or mouse_position.y >= viewport_rect.size.y - VIEW_EDGE_PAN_BOTTOM_MARGIN
		)
		if not in_edge_gutter:
			return false

	view_offset += direction.normalized() * VIEW_EDGE_PAN_SPEED * delta
	_clamp_view_offset()
	return true


func _build_ui() -> void:
	var layer: GameHud = get_node_or_null("GameHudLayer") as GameHud
	if layer == null:
		var hud_scene: PackedScene = load(GAME_HUD_SCENE_PATH) as PackedScene
		if hud_scene != null:
			layer = hud_scene.instantiate() as GameHud
			add_child(layer)

	if layer == null:
		push_error("Game: could not find or instantiate GameHudLayer.")
		return

	game_hud = layer
	if not game_hud.start_wave_requested.is_connected(_on_start_wave_pressed):
		game_hud.start_wave_requested.connect(_on_start_wave_pressed)
	if not game_hud.menu_requested.is_connected(_on_menu_pressed):
		game_hud.menu_requested.connect(_on_menu_pressed)
	if not game_hud.tower_selected.is_connected(_select_tower):
		game_hud.tower_selected.connect(_select_tower)
	if not game_hud.recenter_requested.is_connected(_reset_view):
		game_hud.recenter_requested.connect(_reset_view)


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


func _on_menu_pressed() -> void:
	if get_node_or_null("GamePauseMenu") != null:
		return

	var pause_scene: PackedScene = load(GAME_PAUSE_MENU_SCENE_PATH) as PackedScene
	if pause_scene == null:
		push_error("Game: could not load pause menu at %s." % GAME_PAUSE_MENU_SCENE_PATH)
		return

	var pause_menu: CanvasLayer = pause_scene.instantiate() as CanvasLayer
	if pause_menu == null:
		push_error("Game: pause menu scene root must be a CanvasLayer.")
		return
	add_child(pause_menu)


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
	var distance: float = _outer_ring_radius() + ENEMY_SPAWN_PADDING
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
	var range: float = float(cfg["range"])
	var range_squared: float = range * range
	var best_index: int = -1
	var best_sun_dist_squared: float = INF

	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		var tower_dist_squared: float = tower_pos.distance_squared_to(enemy["pos"])
		var sun_dist_squared: float = sun.distance_squared_to(enemy["pos"])
		if tower_dist_squared <= range_squared and sun_dist_squared < best_sun_dist_squared:
			best_index = i
			best_sun_dist_squared = sun_dist_squared

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
	var range: float = float(cfg["range"])
	var range_squared: float = range * range
	var best_index: int = -1
	var best_hp: float = INF
	for i in range(burrowers.size()):
		var burrower_pos: Vector2 = _burrower_position(burrowers[i])
		if tower_pos.distance_squared_to(burrower_pos) <= range_squared and float(burrowers[i]["hp"]) < best_hp:
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
		var diff: float = abs(pos.distance_to(sun) - _ring_radius(i))
		if diff < 28.0 and diff < best_diff:
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
	return _sun_pos() + Vector2(cos(angle), sin(angle)) * _ring_radius(ring_index)


func _ring_radius(ring_index: int) -> float:
	return float(RINGS[ring_index]["radius"]) * RING_RADIUS_SCALE


func _outer_ring_radius() -> float:
	return _ring_radius(RINGS.size() - 1)


func _is_slot_taken(ring_index: int, slot_index: int) -> bool:
	for tower in towers:
		if int(tower["ring"]) == ring_index and int(tower["slot"]) == slot_index:
			return true
	return false


func _tower_position(tower: Dictionary) -> Vector2:
	return _sun_pos() + Vector2(cos(float(tower["angle"])), sin(float(tower["angle"]))) * _ring_radius(int(tower["ring"]))


func _burrower_position(burrower: Dictionary) -> Vector2:
	return _sun_pos() + Vector2(cos(float(burrower["angle"])), sin(float(burrower["angle"]))) * BURROWER_DIG_RADIUS


func _draw_sun(pos: Vector2) -> void:
	var glow_strength: float = clamp(GameState.luminosity, 0.15, 1.0)
	var time_seconds: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.5 + sin(time_seconds * 1.35) * 0.5
	var edge_color: Color = Color(0.86, 0.24, 0.05)
	var surface_color: Color = Color(1.0, 0.55, 0.12)
	var core_color: Color = Color(1.0, 0.86, 0.36)
	var flare_color: Color = Color(1.0, 0.64, 0.18)

	match _sun_state_key():
		"concerned":
			edge_color = Color(0.82, 0.18, 0.05)
			surface_color = Color(1.0, 0.46, 0.10)
			core_color = Color(1.0, 0.72, 0.25)
		"distressed":
			edge_color = Color(0.66, 0.08, 0.04)
			surface_color = Color(0.98, 0.32, 0.08)
			core_color = Color(1.0, 0.56, 0.18)
			flare_color = Color(1.0, 0.38, 0.12)
		"critical":
			edge_color = Color(0.42, 0.03, 0.025)
			surface_color = Color(0.82, 0.14, 0.06)
			core_color = Color(1.0, 0.34, 0.12)
			flare_color = Color(1.0, 0.20, 0.08)

	for layer in range(7):
		var layer_t: float = float(layer) / 6.0
		var radius: float = SUN_RADIUS + 96.0 - layer_t * 64.0 + pulse * (6.0 - layer_t * 3.0)
		var alpha: float = (0.018 + (1.0 - layer_t) * 0.020) * glow_strength
		draw_circle(pos, radius, Color(flare_color.r, flare_color.g, flare_color.b, alpha))

	for i in range(18):
		var angle: float = TAU * float(i) / 18.0 + sin(time_seconds * 0.25 + float(i)) * 0.08
		var length: float = 12.0 + float(i % 5) * 4.0 + pulse * 5.0
		var inner: Vector2 = pos + Vector2(cos(angle), sin(angle)) * (SUN_RADIUS + 4.0)
		var outer: Vector2 = pos + Vector2(cos(angle), sin(angle)) * (SUN_RADIUS + length)
		draw_line(inner, outer, Color(flare_color.r, flare_color.g, flare_color.b, 0.075 * glow_strength), 1.0)

	draw_circle(pos, SUN_RADIUS + 7.0, Color(0.12, 0.035, 0.012, 0.62))
	for layer in range(9):
		var layer_t: float = float(layer) / 8.0
		var radius: float = SUN_RADIUS + 3.0 - layer_t * (SUN_RADIUS * 0.88)
		var color: Color = edge_color.lerp(surface_color, minf(layer_t * 1.18, 1.0)).lerp(core_color, maxf(layer_t - 0.42, 0.0) * 0.52)
		draw_circle(pos, radius, Color(color.r, color.g, color.b, 0.92))

	for i in range(24):
		var angle: float = float(i) * 2.399963 + time_seconds * 0.045
		var radial_mix: float = wrapf(float(i) * 0.381, 0.0, 1.0)
		var radius: float = SUN_RADIUS * (0.18 + radial_mix * 0.70)
		var granule_pos: Vector2 = pos + Vector2(cos(angle), sin(angle)) * radius
		var granule_size: float = 2.2 + float(i % 4) * 0.75
		var granule_alpha: float = (0.040 + sin(time_seconds * 0.80 + float(i)) * 0.012) * glow_strength
		draw_circle(granule_pos, granule_size, Color(1.0, 0.82, 0.32, granule_alpha))

	for band in range(5):
		var band_radius: float = SUN_RADIUS * (0.30 + float(band) * 0.13)
		var start_angle: float = time_seconds * (0.08 + float(band) * 0.015) + float(band) * 1.21
		draw_arc(pos, band_radius, start_angle, start_angle + 1.55, 52, Color(1.0, 0.92, 0.54, 0.060 * glow_strength), 1.1, true)
		draw_arc(pos, band_radius + 4.0, start_angle + 2.6, start_angle + 3.55, 42, Color(0.62, 0.10, 0.04, 0.075), 1.0, true)

	draw_arc(pos, SUN_RADIUS + 1.5, 0.0, TAU, 180, Color(1.0, 0.70, 0.22, 0.28 * glow_strength), 2.0, true)
	draw_arc(pos, SUN_RADIUS + 10.0 + pulse * 1.4, 0.0, TAU, 180, Color(flare_color.r, flare_color.g, flare_color.b, 0.10 * glow_strength), 1.0, true)


func _draw_tower(tower: Dictionary) -> void:
	var pos: Vector2 = _tower_position(tower)
	var cfg: Dictionary = _tower_config(str(tower["type"]))
	var tower_color: Color = cfg["color"]
	var texture = _tower_texture(str(tower["type"]))
	var disabled: bool = _is_tower_disabled(tower)

	if not disabled:
		draw_arc(pos, float(cfg["range"]), 0.0, TAU, 160, Color(tower_color.r, tower_color.g, tower_color.b, 0.030), 1.0, true)
		draw_arc(pos, float(cfg["range"]) + 2.0, 0.0, TAU, 160, Color(0.18, 0.55, 0.88, 0.018), 1.0, true)

	draw_circle(pos, 24.0, Color(0.0, 0.0, 0.0, 0.28))
	draw_circle(pos, 20.0, Color(0.018, 0.034, 0.052, 0.72))
	if texture:
		var size: Vector2 = Vector2(50.0, 50.0)
		draw_texture_rect(texture, Rect2(pos - size * 0.5, size), false)
	else:
		draw_circle(pos, 13.0, tower_color)
	if disabled:
		draw_circle(pos, 25.0, Color(0.02, 0.02, 0.03, 0.64))
		draw_line(pos + Vector2(-12.0, -12.0), pos + Vector2(12.0, 12.0), Color(0.78, 0.84, 0.92, 0.65), 2.0)
	draw_line(pos, _sun_pos(), Color(0.28, 0.52, 0.76, 0.14), 1.0)


func _draw_enemy(enemy: Dictionary) -> void:
	var pos: Vector2 = enemy["pos"]
	var radius: float = float(enemy["radius"])
	var hp_ratio: float = clamp(float(enemy["hp"]) / float(enemy["max_hp"]), 0.0, 1.0)
	var enemy_color: Color = enemy["color"]
	var texture = _enemy_texture(str(enemy["variant"]))

	draw_circle(pos, radius + 5.0, Color(0.0, 0.0, 0.0, 0.44))
	if texture:
		var size: Vector2 = Vector2(float(enemy["draw_size"]) + 8.0, float(enemy["draw_size"]) + 8.0)
		draw_texture_rect(texture, Rect2(pos - size * 0.5, size), false)
	else:
		draw_circle(pos, radius, enemy_color)
	if hp_ratio < 0.995:
		var bar_width: float = max(radius * 2.2, 30.0)
		var bar_y: float = pos.y - radius - 14.0
		draw_line(Vector2(pos.x - bar_width * 0.5, bar_y), Vector2(pos.x + bar_width * 0.5, bar_y), Color(0.20, 0.06, 0.08, 0.86), 3.0)
		draw_line(Vector2(pos.x - bar_width * 0.5, bar_y), Vector2(pos.x - bar_width * 0.5 + bar_width * hp_ratio, bar_y), Color(0.52, 1.0, 0.58, 0.95), 3.0)


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


func _view_translation(viewport_size: Vector2) -> Vector2:
	var center: Vector2 = viewport_size * 0.5
	return center + view_offset - center * view_zoom


func _screen_to_world(screen_position: Vector2) -> Vector2:
	var center: Vector2 = get_viewport_rect().size * 0.5
	return center + (screen_position - center - view_offset) / view_zoom


func _world_to_screen(world_position: Vector2) -> Vector2:
	var center: Vector2 = get_viewport_rect().size * 0.5
	return (world_position - center) * view_zoom + center + view_offset


func _set_view_zoom(next_zoom: float, focus_screen_position: Vector2) -> void:
	var focus_world_position: Vector2 = _screen_to_world(focus_screen_position)
	view_zoom = clampf(next_zoom, VIEW_ZOOM_MIN, VIEW_ZOOM_MAX)
	var center: Vector2 = get_viewport_rect().size * 0.5
	view_offset = focus_screen_position - center - (focus_world_position - center) * view_zoom
	_clamp_view_offset()
	queue_redraw()


func _reset_view() -> void:
	view_offset = Vector2.ZERO
	view_zoom = 1.0
	queue_redraw()


func _clamp_view_offset() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var outer_radius: float = _outer_ring_radius()
	var max_offset: Vector2 = Vector2(
		maxf(outer_radius * 1.38, viewport_size.x * 0.42),
		maxf(outer_radius * 1.10, viewport_size.y * 0.34)
	) * view_zoom
	view_offset.x = clampf(view_offset.x, -max_offset.x, max_offset.x)
	view_offset.y = clampf(view_offset.y, -max_offset.y, max_offset.y)


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


func _tower_info(tower_type: String) -> Dictionary:
	return TOWER_INFO.get(tower_type, TOWER_INFO["photon_splitter"])


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
	var parts: Array = []
	for ring in RINGS:
		var short_name: String = str(ring["name"]).replace(" Belt", "").replace(" Band", "").replace(" Arc", "").replace("Outer ", "")
		parts.append("R%d %s %d slots" % [int(ring["id"]), short_name, int(ring["slots"])])
	return "RINGS: %s\n%s" % ["  |  ".join(parts.slice(0, 2)), "       %s" % "  |  ".join(parts.slice(2, 4))]


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
		return "\n%s" % " / ".join(parts)
	return ""


func _clean_wave_hint(text: String, wave_name: String) -> String:
	var repeated_prefix: String = "%s: " % wave_name
	if text.begins_with(repeated_prefix):
		return text.substr(repeated_prefix.length())
	return text


func _tower_short_label(tower_type: String) -> String:
	match tower_type:
		"photon_splitter":
			return "PHOTON"
		"cryo_probe":
			return "CRYO"
		"bio_lab":
			return "BIO-LAB"
		"magnetic_net":
			return "MAG NET"
		"helios_cannon":
			return "HELIOS"
		"tardigrade_bomb":
			return "TARDI"
		_:
			return str(_tower_config(tower_type)["label"]).to_upper()


func _selected_tower_readout() -> String:
	var cfg: Dictionary = _tower_config(selected_tower)
	var cost: int = GameState.get_tower_cost(selected_tower)
	return "%s READY  |  %d SOL" % [str(cfg["label"]).to_upper(), cost]


func _set_message(text: String, duration: float = 0.0) -> void:
	message_text = text
	message_timer = duration
	_update_ui()


func _tower_button_view_data() -> Dictionary:
	var button_states: Dictionary = {}
	for tower_type in TOWER_ORDER:
		var cost: int = GameState.get_tower_cost(tower_type)
		var cfg: Dictionary = _tower_config(tower_type)
		var info: Dictionary = _tower_info(tower_type)
		button_states[tower_type] = {
			"text": "%s\n%d SOL" % [_tower_short_label(tower_type), cost],
			"info": {
				"title": str(cfg["label"]).to_upper(),
				"role": "%s  |  %d SOL" % [str(info["role"]), cost],
				"stats": "DAMAGE %.0f  |  RATE %.2f/S  |  RANGE %.0f" % [float(cfg["damage"]), float(cfg["rate"]), float(cfg["range"])],
				"body": str(info["body"]),
				"note": str(info["note"]),
				"accent": cfg["color"],
			},
			"pressed": tower_type == selected_tower,
			"disabled": GameState.game_phase != GameState.Phase.BETWEEN_WAVE or not GameState.can_afford(cost),
			"icon": _tower_texture(tower_type),
		}
	return button_states


func _update_ui() -> void:
	if game_hud == null:
		return

	var wave_data: Dictionary = current_wave_data if GameState.game_phase == GameState.Phase.WAVE_ACTIVE else next_wave_preview
	var wave_index: int = int(wave_data.get("index", min(GameState.current_wave + 1, MAX_WAVES)))
	var wave_name: String = str(wave_data.get("name", "First Contact"))
	var title_text: String = "WAVE %02d/%02d | %s" % [wave_index, MAX_WAVES, wave_name.to_upper()]
	if GameState.game_phase != GameState.Phase.WAVE_ACTIVE:
		title_text = "%s %02d/%02d" % [briefing_title.to_upper(), wave_index, MAX_WAVES]
		if briefing_title.strip_edges().to_lower() != wave_name.strip_edges().to_lower():
			title_text += " | %s" % wave_name.to_upper()

	var reward: int = int(wave_data.get("credit_reward", 0))
	var next_wave: int = min(GameState.current_wave + 1, MAX_WAVES)
	game_hud.update_view({
		"wave_title": title_text,
		"brief": _clean_wave_hint(str(wave_data.get("tutorial_hint", "Defend the Sun.")), wave_name),
		"credits": str(GameState.sol_credits),
		"score": str(GameState.performance_score),
		"kills": str(GameState.enemies_killed_total),
		"flare": "READY" if GameState.flare_charge > 0 else "CHARGING",
		"luminosity": float(GameState.get_luminosity_percent()),
		"enemy_texture": _enemy_texture(_primary_wave_variant(wave_data)),
		"enemy_summary": _wave_spawn_summary(wave_data).to_upper(),
		"threat": "ACTIVE %d  |  BURROWED %d  |  QUEUE %d\nREWARD +%d SOL%s" % [enemies.size(), burrowers.size(), spawn_queue.size(), reward, _active_modifier_summary().to_upper()],
		"rings": _ring_summary(),
		"start_text": "START WAVE %d" % next_wave,
		"start_disabled": GameState.game_phase != GameState.Phase.BETWEEN_WAVE or next_wave > playable_wave_limit,
		"message": message_text,
		"selected_tower": _selected_tower_readout(),
		"tower_buttons": _tower_button_view_data(),
	})
