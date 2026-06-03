extends Node2D

# Main gameplay controller.
# This scene keeps the runtime loop in one place: input, waves, towers, enemies,
# camera, effects, music, and HUD updates. Static balance, tower math, wave
# parsing, and temporary SFX live in small helper files so this file can focus
# on what happens during play.

const SpaceTheme = preload("res://scripts/ui/space_theme.gd")
const GameCatalog = preload("res://scripts/game/game_catalog.gd")
const GameEffectStoreScript = preload("res://scripts/game/game_effect_store.gd")
const GameOrbitMathScript = preload("res://scripts/game/game_orbit_math.gd")
const GameSfxBusScript = preload("res://scripts/game/game_sfx_bus.gd")
const GameTowerLibraryScript = preload("res://scripts/game/game_tower_library.gd")
const GameViewControllerScript = preload("res://scripts/game/game_view_controller.gd")
const GameWaveLibraryScript = preload("res://scripts/game/game_wave_library.gd")

const MAX_WAVES: int = GameCatalog.MAX_WAVES
const SUN_RADIUS: float = GameCatalog.SUN_RADIUS
const SUN_DAMAGE_RADIUS: float = GameCatalog.SUN_DAMAGE_RADIUS
const ENEMY_SPAWN_PADDING: float = GameCatalog.ENEMY_SPAWN_PADDING
const FLARE_DAMAGE: float = GameCatalog.FLARE_DAMAGE
const BURROWER_DIG_RADIUS: float = GameCatalog.BURROWER_DIG_RADIUS
const BURROWER_EXCAVATION_HP: float = GameCatalog.BURROWER_EXCAVATION_HP
const BURROWER_DRAIN_INTERVAL: float = GameCatalog.BURROWER_DRAIN_INTERVAL
const BURROWER_DRAIN_DAMAGE: float = GameCatalog.BURROWER_DRAIN_DAMAGE

const WAVE_EARLY_BGM_PATH: String = "res://assets/audio/bgm/final/wave_01.ogg"
const WAVE_MID_BGM_PATH: String = "res://assets/audio/bgm/final/wave_02.ogg"
const WAVE_LATE_BGM_PATH: String = "res://assets/audio/bgm/final/wave_03.ogg"
const BOSS_BGM_PATH: String = "res://assets/audio/bgm/final/BOSS.ogg"
const END_BGM_PATH: String = "res://assets/audio/bgm/end.ogg"
const GAME_HUD_SCENE_PATH: String = "res://scenes/ui/game_hud.tscn"
const GAME_PAUSE_MENU_SCENE_PATH: String = "res://scenes/ui/game_pause_menu.tscn"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const TUTORIAL_OVERLAY_SCRIPT = preload("res://scripts/ui/tutorial_overlay.gd")
const BATTLE_BACKGROUND_PATH: String = "res://assets/sprites/backgrounds/battle_nebula_hq.png"
const END_TITLE_FONT_PATH: String = "res://assets/fonts/Kenney Future.ttf"
const END_BODY_FONT_PATH: String = "res://assets/fonts/Electrolize-Regular.ttf"
const SUN_HIT_EFFECT_SECONDS: float = 0.55
const ENEMY_STATUS_TAG_HEIGHT: float = 15.0
const ENEMY_STATUS_FONT_SIZE: int = 10
const ENEMY_HIT_FLASH_SECONDS: float = 0.24
const HEALTH_BAR_HEIGHT: float = 6.0
const AUTO_START_DELAY: float = 3.0

const ENEMY_ASSET_PATHS: Dictionary = GameCatalog.ENEMY_ASSET_PATHS
const TOWER_ASSET_PATHS: Dictionary = GameCatalog.TOWER_ASSET_PATHS
const RINGS: Array = GameCatalog.RINGS
const ENEMY_CONFIGS: Dictionary = GameCatalog.ENEMY_CONFIGS

@export_range(1, 12, 1) var playable_wave_limit: int = 12
@export var briefing_title: String = "SOL DEFENSE CORPS"

# Wave state
var current_wave_data: Dictionary = {}
var next_wave_preview: Dictionary = {}
var spawn_queue: Array = []
var spawn_timer: float = 0.0
var spawned_wave_count: int = 0
var total_wave_spawn_count: int = 0
var wave_active: bool = false
var auto_start_timer: float = 0.0
var auto_start_countdown_second: int = -1
var message_text: String = "Select an orbital slot, then start Wave 1."
var message_timer: float = 0.0

# Wave modifier state
var wave_event: Dictionary = {}
var wave_event_triggered: bool = false
var cryo_disruption_timer: float = 0.0
var bio_lab_boost_timer: float = 0.0
var bio_lab_boost_multiplier: float = 1.0
var ring_blind_timers: Dictionary = {}
var prime_frenzy_timer: float = 0.0
var prime_frenzy_interval: float = 0.0
var prime_frenzy_max_active: int = 18

# Board state
var enemies: Array = []
var burrowers: Array = []
var towers: Array = []
var stars: Array = []
var effect_store: GameEffectStore
var selected_tower: String = "photon_splitter"
var managed_tower_ring: int = -1
var managed_tower_slot: int = -1

# UI and asset state
var game_hud: GameHud
var tutorial_layer: CanvasLayer
var tutorial_overlay: TutorialOverlay
var textures: Dictionary = {
	"enemies": {},
	"towers": {},
}
var end_title_font: Font
var end_body_font: Font

# Music state
var bgm_player: AudioStreamPlayer
var battle_background_texture: Texture2D
var current_bgm_path: String = ""
var ending_music_started: bool = false
var sfx_bus: GameSfxBus

# Camera/effect state
var view_controller: GameViewController
var sun_hit_timer: float = 0.0
var screen_shake_timer: float = 0.0
var screen_shake_strength: float = 0.0


func _ready() -> void:
	randomize()
	effect_store = GameEffectStoreScript.new() as GameEffectStore
	view_controller = GameViewControllerScript.new() as GameViewController
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	SpaceTheme.apply_cursor()
	GameState.reset_state()
	GameState.load_audio_settings()
	GameState.ensure_music_audible()
	MusicManager.stop_music()
	if not GameState.music_settings_changed.is_connected(_on_music_settings_changed):
		GameState.music_settings_changed.connect(_on_music_settings_changed)
	GameState.set_phase(GameState.Phase.BETWEEN_WAVE)
	_load_assets()
	_play_wave_music()
	_generate_starfield()
	_build_ui()
	_refresh_next_wave_preview()
	_update_ui()
	call_deferred("_maybe_show_tutorial")
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	# Core loop: spawn enemies, update towers, move enemies, clean up effects,
	# then refresh the HUD/redraw if something changed.
	var viewport_changed: bool = _refresh_viewport_cache()
	var view_changed: bool = _process_edge_pan(delta)
	view_changed = _process_keyboard_pan(delta) or view_changed
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message_text = "Build anytime. Towers orbit and fire automatically."
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
	_process_visual_feedback(delta)
	_check_wave_clear()
	_process_auto_start(delta)
	if view_changed or _needs_frame_redraw(viewport_changed):
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# The tutorial owns input while it is open so clicks do not place towers
	# behind the training overlay.
	if tutorial_overlay != null:
		return

	if event is InputEventMouseMotion and view_controller.panning:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		view_controller.pan_by(motion.relative, get_viewport_rect().size, _outer_ring_radius())
		queue_redraw()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		match mouse_button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if mouse_button.pressed:
					_set_view_zoom(view_controller.zoom * GameViewControllerScript.ZOOM_STEP, mouse_button.position)
					get_viewport().set_input_as_handled()
				return
			MOUSE_BUTTON_WHEEL_DOWN:
				if mouse_button.pressed:
					_set_view_zoom(view_controller.zoom / GameViewControllerScript.ZOOM_STEP, mouse_button.position)
					get_viewport().set_input_as_handled()
				return
			MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT:
				view_controller.panning = mouse_button.pressed
				get_viewport().set_input_as_handled()
				return
			MOUSE_BUTTON_LEFT:
				if not mouse_button.pressed:
					return
				if not _can_build_towers():
					return
				if game_hud != null and game_hud.is_screen_position_over_hud(mouse_button.position):
					return
				_place_tower_from_screen_position(mouse_button.position)
				get_viewport().set_input_as_handled()
				return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and _handle_keyboard_shortcut(key_event.keycode):
			get_viewport().set_input_as_handled()
		return


func _place_tower_from_screen_position(screen_position: Vector2) -> void:
	if not _can_build_towers():
		return

	# Board clicks are converted back into world space because the player can
	# pan and zoom around the star.
	var click_pos: Vector2 = _screen_to_world(screen_position)
	var tower_index: int = _tower_index_at_world_position(click_pos)
	if tower_index != -1:
		_select_managed_tower_by_index(tower_index)
		return

	var slot: Dictionary = _nearest_ring_slot(click_pos)
	if slot.is_empty():
		_clear_managed_tower()
		_set_message("Select one of the visible orbital slots to build.", 2.0)
		return
	if bool(slot.get("occupied", false)):
		_select_managed_tower(int(slot["ring_index"]), int(slot["slot_index"]))
		return

	var cost: int = GameState.get_tower_cost(selected_tower)
	if not GameState.spend_credits(cost):
		_set_message("Need %d Sol Credits for %s." % [cost, _tower_config(selected_tower)["label"]], 2.0)
		return

	var slot_pos: Vector2 = _ring_slot_position(int(slot["ring_index"]), int(slot["slot_index"]))
	towers.append({
		"type": selected_tower,
		"ring": int(slot["ring_index"]),
		"slot": int(slot["slot_index"]),
		"angle": float(slot["angle"]),
		"fire_timer": 0.15,
		"level": 1,
		"spent": cost,
	})
	_add_visual_effect("place", slot_pos, _tower_config(selected_tower)["color"], 0.55, 38.0)
	_add_text_effect("-%d SOL" % cost, slot_pos + Vector2(0.0, -34.0), Color(1.0, 0.72, 0.28, 0.96))
	_play_sfx("build")
	_set_message("Placed %s on %s slot %d." % [_tower_config(selected_tower)["label"], slot["ring_name"], int(slot["slot_index"]) + 1], 2.0)
	_update_ui()
	queue_redraw()


func _handle_keyboard_shortcut(keycode: int) -> bool:
	match keycode:
		KEY_HOME, KEY_0:
			_reset_view()
			return true
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			_on_start_wave_pressed()
			return true
		KEY_ESCAPE:
			_on_menu_pressed()
			return true
		KEY_R:
			if GameState.game_phase == GameState.Phase.GAME_OVER or GameState.game_phase == GameState.Phase.VICTORY:
				_on_retry_requested()
				return true
		KEY_M:
			if GameState.game_phase == GameState.Phase.GAME_OVER or GameState.game_phase == GameState.Phase.VICTORY:
				_on_end_main_menu_requested()
				return true
		KEY_F:
			_try_manual_flare()
			return true
		KEY_1:
			return _select_tower_by_hotkey(0)
		KEY_2:
			return _select_tower_by_hotkey(1)
		KEY_3:
			return _select_tower_by_hotkey(2)
		KEY_4:
			return _select_tower_by_hotkey(3)
		KEY_5:
			return _select_tower_by_hotkey(4)
		KEY_6:
			return _select_tower_by_hotkey(5)
	return false


func _select_tower_by_hotkey(index: int) -> bool:
	if index < 0 or index >= GameTowerLibraryScript.TOWER_ORDER.size():
		return false
	var tower_type: String = str(GameTowerLibraryScript.TOWER_ORDER[index])
	var cost: int = GameState.get_tower_cost(tower_type)
	if not _can_build_towers():
		return true
	if not GameState.can_afford(cost):
		_set_message("Need %d Sol Credits for %s." % [cost, _tower_config(tower_type)["label"]], 1.6)
		return true
	_select_tower(tower_type)
	return true


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
			wrapf(base_pos.x + time_seconds * speed + sin(time_seconds * 0.35 + phase) * 3.0 + view_controller.offset.x * 0.10, -8.0, viewport_size.x + 8.0),
			wrapf(base_pos.y + cos(time_seconds * 0.28 + phase) * 2.5 + view_controller.offset.y * 0.10, -8.0, viewport_size.y + 8.0)
		)
		star_color.a = clamp(star_color.a * (0.80 + sin(time_seconds * 1.15 + phase) * 0.22), 0.04, 0.78)
		draw_circle(star_pos, float(star["radius"]), star_color)

	# Everything below this transform is part of the zoomable board.
	draw_set_transform(_view_translation(viewport_size) + _screen_shake_offset(), 0.0, Vector2(view_controller.zoom, view_controller.zoom))
	_draw_orbit_rings(sun)
	_draw_build_preview()
	_draw_sun(sun)

	for shot in effect_store.shots:
		_draw_shot(shot)

	for tower in towers:
		_draw_tower(tower)

	for enemy in enemies:
		_draw_enemy(enemy)

	for burrower in burrowers:
		_draw_burrower(burrower)

	_draw_visual_effects()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if GameState.game_phase == GameState.Phase.GAME_OVER:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.0, 0.0, 0.0, 0.58), true)
		_draw_end_state_overlay(viewport_size)
	elif GameState.game_phase == GameState.Phase.VICTORY:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(1.0, 0.78, 0.18, 0.12), true)
		_draw_end_state_overlay(viewport_size)


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
	var parallax: Vector2 = view_controller.offset * 0.08
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
			var tick_angle: float = GameOrbitMathScript.SLOT_ANGLE_OFFSET + TAU * float(tick_index) / float(tick_count)
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
	end_title_font = load(END_TITLE_FONT_PATH) as Font
	end_body_font = load(END_BODY_FONT_PATH) as Font
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
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player.bus = "Master"
	bgm_player.volume_db = GameState.get_music_volume_db()
	_build_sfx_bus()


func _play_wave_music(wave_number: int = 0) -> void:
	if bgm_player == null:
		return

	ending_music_started = false
	var target_wave: int = wave_number
	if target_wave <= 0:
		target_wave = int(clamp(GameState.current_wave + 1, 1, MAX_WAVES))

	var track_path: String = _bgm_path_for_wave(target_wave)
	if current_bgm_path != track_path or bgm_player.stream == null:
		_set_music_stream(track_path, true)
	_apply_music_settings()
	if GameState.music_enabled and bgm_player.stream and not bgm_player.playing:
		bgm_player.play()


func _process_music(_delta: float) -> void:
	if bgm_player == null or ending_music_started:
		return
	if not GameState.music_enabled:
		if bgm_player.playing:
			bgm_player.stop()
		return
	if bgm_player.stream and not bgm_player.playing:
		bgm_player.play()


func _play_ending_music() -> void:
	if ending_music_started:
		return
	ending_music_started = true
	if current_bgm_path != END_BGM_PATH or bgm_player.stream == null:
		_set_music_stream(END_BGM_PATH, true)
	_apply_music_settings()
	if GameState.music_enabled and bgm_player.stream:
		bgm_player.play()


func _build_sfx_bus() -> void:
	var audio_parent: Node = get_node_or_null("Audio")
	if audio_parent == null:
		audio_parent = self

	sfx_bus = GameSfxBusScript.new() as GameSfxBus
	sfx_bus.name = "GameSfxBus"
	audio_parent.add_child(sfx_bus)
	sfx_bus.initialize()


func _play_sfx(kind: String, min_interval: float = 0.0) -> void:
	if sfx_bus != null:
		sfx_bus.play(kind, min_interval)


func _set_music_stream(path: String, loop_enabled: bool) -> void:
	if bgm_player == null:
		return
	var stream = MusicManager.load_music_stream(path, loop_enabled)
	if stream == null:
		push_warning("Game: missing music track at %s." % path)
		return
	bgm_player.stop()
	bgm_player.stream = stream
	current_bgm_path = path


func _bgm_path_for_wave(wave_number: int) -> String:
	if wave_number >= 12:
		return BOSS_BGM_PATH
	if wave_number >= 9:
		return WAVE_LATE_BGM_PATH
	if wave_number >= 5:
		return WAVE_MID_BGM_PATH
	return WAVE_EARLY_BGM_PATH


func _apply_music_settings() -> void:
	if bgm_player == null:
		return
	bgm_player.volume_db = GameState.get_music_volume_db()
	if not GameState.music_enabled:
		bgm_player.stop()
		return
	if bgm_player.stream and not bgm_player.playing:
		bgm_player.play()


func _on_music_settings_changed(_enabled: bool, _volume: float) -> void:
	_apply_music_settings()


func _set_audio_stream_loop(stream, loop_enabled: bool) -> void:
	if stream == null:
		return
	for property in stream.get_property_list():
		var property_name: String = str(property.get("name", ""))
		if property_name == "loop":
			stream.set("loop", loop_enabled)
			return
		if property_name == "loop_mode":
			stream.set("loop_mode", AudioStreamWAV.LOOP_FORWARD if loop_enabled else AudioStreamWAV.LOOP_DISABLED)
			return


func _generate_starfield() -> void:
	stars.clear()
	var viewport_size: Vector2 = get_viewport_rect().size
	view_controller.remember_viewport_size(viewport_size)
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
	if not view_controller.viewport_changed(viewport_size):
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
	if not towers.is_empty() or not enemies.is_empty() or not effect_store.shots.is_empty() or not burrowers.is_empty():
		return true
	if not effect_store.visual_effects.is_empty() or sun_hit_timer > 0.0 or screen_shake_timer > 0.0:
		return true
	if cryo_disruption_timer > 0.0 or bio_lab_boost_timer > 0.0 or not ring_blind_timers.is_empty():
		return true
	return false


func _process_edge_pan(delta: float) -> bool:
	if tutorial_overlay != null:
		return false

	var viewport_rect: Rect2 = get_viewport_rect()
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var hud_blocks_mouse: bool = game_hud != null and game_hud.is_screen_position_over_hud(mouse_position)
	return view_controller.process_edge_pan(delta, viewport_rect, mouse_position, hud_blocks_mouse, _outer_ring_radius())


func _process_keyboard_pan(delta: float) -> bool:
	if tutorial_overlay != null:
		return false
	return view_controller.process_keyboard_pan(delta, get_viewport_rect().size, _outer_ring_radius())


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
	# The HUD emits intent; game.gd decides whether an action is allowed.
	if not game_hud.start_wave_requested.is_connected(_on_start_wave_pressed):
		game_hud.start_wave_requested.connect(_on_start_wave_pressed)
	if not game_hud.auto_start_toggled.is_connected(_on_auto_start_toggled):
		game_hud.auto_start_toggled.connect(_on_auto_start_toggled)
	if not game_hud.menu_requested.is_connected(_on_menu_pressed):
		game_hud.menu_requested.connect(_on_menu_pressed)
	if not game_hud.tower_selected.is_connected(_select_tower):
		game_hud.tower_selected.connect(_select_tower)
	if not game_hud.tower_upgrade_requested.is_connected(_on_tower_upgrade_requested):
		game_hud.tower_upgrade_requested.connect(_on_tower_upgrade_requested)
	if not game_hud.tower_sell_requested.is_connected(_on_tower_sell_requested):
		game_hud.tower_sell_requested.connect(_on_tower_sell_requested)
	if not game_hud.tower_manage_closed.is_connected(_on_tower_manage_closed):
		game_hud.tower_manage_closed.connect(_on_tower_manage_closed)
	if not game_hud.recenter_requested.is_connected(_reset_view):
		game_hud.recenter_requested.connect(_reset_view)
	if not game_hud.retry_requested.is_connected(_on_retry_requested):
		game_hud.retry_requested.connect(_on_retry_requested)
	if not game_hud.main_menu_requested.is_connected(_on_end_main_menu_requested):
		game_hud.main_menu_requested.connect(_on_end_main_menu_requested)


func _maybe_show_tutorial() -> void:
	if GameState.tutorial_completed:
		return
	if tutorial_overlay != null:
		return
	if game_hud == null:
		return
	_show_tutorial()


func _show_tutorial() -> void:
	tutorial_layer = CanvasLayer.new()
	tutorial_layer.name = "TutorialLayer"
	tutorial_layer.layer = 80
	add_child(tutorial_layer)

	tutorial_overlay = TUTORIAL_OVERLAY_SCRIPT.new() as TutorialOverlay
	tutorial_overlay.name = "TutorialOverlay"
	tutorial_overlay.set_target_provider(Callable(self, "_tutorial_targets"))
	tutorial_overlay.tutorial_finished.connect(_on_tutorial_finished)
	tutorial_overlay.tutorial_skipped.connect(_on_tutorial_skipped)
	tutorial_layer.add_child(tutorial_overlay)
	_set_message("Mission training overlay opened. Skip or finish to save it as complete.", 3.0)


func _on_tutorial_finished() -> void:
	GameState.set_tutorial_completed(true)
	_clear_tutorial_overlay()
	_set_message("Mission training complete. It will not replay automatically.", 3.0)


func _on_tutorial_skipped() -> void:
	GameState.set_tutorial_completed(true)
	_clear_tutorial_overlay()
	_set_message("Mission training skipped. It will not replay automatically.", 3.0)


func _clear_tutorial_overlay() -> void:
	if tutorial_layer != null:
		tutorial_layer.queue_free()
	tutorial_layer = null
	tutorial_overlay = null


func _tutorial_targets() -> Dictionary:
	var targets: Dictionary = {}
	if game_hud != null:
		targets.merge(game_hud.get_tutorial_targets(), true)

	var sun_screen_pos: Vector2 = _world_to_screen(_sun_pos())
	targets["sun"] = {
		"type": "circle",
		"center": sun_screen_pos,
		"radius": maxf(SUN_RADIUS * view_controller.zoom, 42.0),
	}
	targets["rings"] = {
		"type": "circle",
		"center": sun_screen_pos,
		"radius": maxf(_outer_ring_radius() * view_controller.zoom, 90.0),
	}
	if not RINGS.is_empty():
		targets["slot"] = {
			"type": "circle",
			"center": _world_to_screen(_ring_slot_position(0, 0)),
			"radius": 28.0,
		}
	return targets


func _on_start_wave_pressed() -> void:
	if GameState.game_phase != GameState.Phase.BETWEEN_WAVE:
		return
	_clear_auto_start_timer(false)

	var wave_number: int = GameState.current_wave + 1
	if wave_number > playable_wave_limit:
		_set_message("Wave %d is locked for this scene." % wave_number, 3.0)
		return
	if wave_number > MAX_WAVES:
		return

	current_wave_data = GameWaveLibraryScript.load_wave(wave_number)
	if current_wave_data.is_empty():
		_set_message("Could not load wave_%02d.json." % wave_number, 3.0)
		return

	GameState.current_wave = wave_number
	GameState.set_phase(GameState.Phase.WAVE_ACTIVE)
	spawn_queue = GameWaveLibraryScript.build_spawn_queue(current_wave_data)
	total_wave_spawn_count = spawn_queue.size()
	spawned_wave_count = 0
	spawn_timer = 0.35
	wave_active = true
	_begin_wave_event(current_wave_data)
	_play_sfx("wave_start", 0.35)
	_play_wave_music(wave_number)
	_set_message(str(current_wave_data.get("tutorial_hint", "Wave incoming.")), 5.0)
	_update_ui()


func _on_auto_start_toggled(enabled: bool) -> void:
	GameState.set_auto_start_waves_enabled(enabled)
	_clear_auto_start_timer(false)
	_play_sfx("button")
	if enabled:
		_set_message("Auto Start armed. Ready waves launch after a short countdown.", 2.4)
	else:
		_set_message("Auto Start disabled.", 1.5)
	_update_ui()


func _on_menu_pressed() -> void:
	if get_node_or_null("GamePauseMenu") != null:
		return
	_play_sfx("button")

	var pause_scene: PackedScene = load(GAME_PAUSE_MENU_SCENE_PATH) as PackedScene
	if pause_scene == null:
		push_error("Game: could not load pause menu at %s." % GAME_PAUSE_MENU_SCENE_PATH)
		return

	var pause_menu: CanvasLayer = pause_scene.instantiate() as CanvasLayer
	if pause_menu == null:
		push_error("Game: pause menu scene root must be a CanvasLayer.")
		return
	add_child(pause_menu)


func _on_retry_requested() -> void:
	_play_sfx("button")
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_end_main_menu_requested() -> void:
	_play_sfx("button")
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _select_tower(tower_type: String) -> void:
	selected_tower = tower_type
	_play_sfx("button", 0.04)
	_set_message("Selected %s." % _tower_config(tower_type)["label"], 1.2)
	_update_ui()


func _on_tower_upgrade_requested(ring_index: int, slot_index: int) -> void:
	var tower_index: int = _tower_index_for_slot(ring_index, slot_index)
	if tower_index == -1:
		_clear_managed_tower()
		return

	var tower: Dictionary = towers[tower_index]
	var level: int = _tower_level(tower)
	if level >= GameTowerLibraryScript.MAX_LEVEL:
		_set_message("%s is already at maximum calibration." % _tower_config(str(tower["type"]))["label"], 1.8)
		return

	var upgrade_cost: int = _tower_upgrade_cost(tower)
	if not GameState.spend_credits(upgrade_cost):
		_set_message("Need %d Sol Credits to upgrade %s." % [upgrade_cost, _tower_config(str(tower["type"]))["label"]], 2.0)
		_update_ui()
		return

	level += 1
	tower["level"] = level
	tower["spent"] = int(tower.get("spent", GameState.get_tower_cost(str(tower["type"])))) + upgrade_cost
	tower["fire_timer"] = minf(float(tower.get("fire_timer", 0.0)), _tower_fire_interval(tower))
	towers[tower_index] = tower
	managed_tower_ring = ring_index
	managed_tower_slot = slot_index

	var tower_pos: Vector2 = _tower_position(tower)
	var color: Color = _tower_config(str(tower["type"]))["color"]
	_add_visual_effect("upgrade", tower_pos, color, 0.64, 46.0)
	_add_text_effect("LVL %d  -%d SOL" % [level, upgrade_cost], tower_pos + Vector2(0.0, -40.0), Color(1.0, 0.84, 0.34, 0.98), 0.90)
	_play_sfx("upgrade")
	_set_message("%s upgraded to Level %d." % [_tower_config(str(tower["type"]))["label"], level], 2.0)
	_update_ui()
	queue_redraw()


func _on_tower_sell_requested(ring_index: int, slot_index: int) -> void:
	var tower_index: int = _tower_index_for_slot(ring_index, slot_index)
	if tower_index == -1:
		_clear_managed_tower()
		return

	var tower: Dictionary = towers[tower_index]
	var refund: int = _tower_sell_refund(tower)
	var tower_pos: Vector2 = _tower_position(tower)
	var tower_label: String = str(_tower_config(str(tower["type"]))["label"])
	var color: Color = _tower_config(str(tower["type"]))["color"]
	towers.remove_at(tower_index)
	GameState.add_credits(refund)
	_clear_managed_tower(false)
	_add_visual_effect("sell", tower_pos, color, 0.50, 36.0)
	_add_text_effect("+%d SOL" % refund, tower_pos + Vector2(0.0, -36.0), Color(1.0, 0.86, 0.34, 0.98), 0.86)
	_play_sfx("sell")
	_set_message("Sold %s for %d Sol Credits." % [tower_label, refund], 2.0)
	_update_ui()
	queue_redraw()


func _on_tower_manage_closed() -> void:
	_clear_managed_tower()


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


func _try_manual_flare() -> void:
	if GameState.game_phase != GameState.Phase.WAVE_ACTIVE:
		_set_message("Solar flare can only fire during an active wave.", 1.6)
		return
	if enemies.is_empty():
		_set_message("No Astrophages are in flare range.", 1.6)
		return
	if not GameState.try_trigger_flare():
		_set_message("Solar flare is still charging.", 1.6)
		return
	_trigger_solar_flare()
	_set_message("Manual solar flare fired.", 2.0)
	_update_ui()


func _trigger_solar_flare() -> void:
	var sun: Vector2 = _sun_pos()
	_add_visual_effect("flare", sun, Color(1.0, 0.78, 0.24, 0.96), 0.74, SUN_RADIUS + 36.0)
	_play_sfx("flare", 0.45)
	for i in range(enemies.size() - 1, -1, -1):
		if i >= enemies.size():
			continue
		var enemy_pos: Vector2 = enemies[i]["pos"]
		_add_shot(sun, enemy_pos, Color(1.0, 0.78, 0.24, 0.96), 0.30, 5.0, "flare")
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
		enemy["hit_timer"] = maxf(float(enemy.get("hit_timer", 0.0)) - delta, 0.0)
		enemy["heal_timer"] = maxf(float(enemy.get("heal_timer", 0.0)) - delta, 0.0)
		if dist > 0.0:
			enemy["pos"] = pos + to_sun.normalized() * float(enemy["speed"]) * speed_multiplier * delta
		survivors.append(enemy)

	enemies = survivors
	if reached_sun and direct_breach:
		_register_sun_hit()
		_set_message("The corona was breached. Luminosity is falling.", 2.0)
		_update_ui()

	if GameState.game_phase == GameState.Phase.GAME_OVER:
		wave_active = false
		spawn_queue.clear()
		_play_sfx("failure", 6.0)
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
			_register_sun_hit(0.72)
			burrower["drain_timer"] = BURROWER_DRAIN_INTERVAL
			_update_ui()
		burrowers[i] = burrower

	if GameState.game_phase == GameState.Phase.GAME_OVER:
		wave_active = false
		spawn_queue.clear()
		_play_sfx("failure", 6.0)
		_play_ending_music()
		_set_message("Game over. The Sun was hollowed out from within.", 999.0)
		_update_ui()


func _process_shots(delta: float) -> void:
	effect_store.process_shots(delta)


func _process_visual_feedback(delta: float) -> void:
	sun_hit_timer = maxf(sun_hit_timer - delta, 0.0)
	screen_shake_timer = maxf(screen_shake_timer - delta, 0.0)
	if screen_shake_timer <= 0.0:
		screen_shake_strength = 0.0

	effect_store.process_visual_effects(delta)


func _process_auto_start(delta: float) -> void:
	if not _should_auto_start_wave():
		_clear_auto_start_timer()
		return

	if auto_start_timer <= 0.0:
		auto_start_timer = AUTO_START_DELAY
		auto_start_countdown_second = int(ceil(auto_start_timer))
		_update_ui()

	auto_start_timer = maxf(auto_start_timer - delta, 0.0)
	var countdown: int = int(ceil(auto_start_timer))
	if countdown != auto_start_countdown_second:
		auto_start_countdown_second = countdown
		_update_ui()

	if auto_start_timer <= 0.0:
		_clear_auto_start_timer(false)
		_on_start_wave_pressed()


func _should_auto_start_wave() -> bool:
	if not GameState.auto_start_waves_enabled:
		return false
	if tutorial_overlay != null:
		return false
	if GameState.game_phase != GameState.Phase.BETWEEN_WAVE:
		return false
	var wave_number: int = GameState.current_wave + 1
	if wave_number > MAX_WAVES or wave_number > playable_wave_limit:
		return false
	return not next_wave_preview.is_empty()


func _clear_auto_start_timer(refresh_ui: bool = true) -> void:
	if auto_start_timer <= 0.0 and auto_start_countdown_second == -1:
		return
	auto_start_timer = 0.0
	auto_start_countdown_second = -1
	if refresh_ui:
		_update_ui()


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
	if reward > 0:
		_add_text_effect("+%d SOL WAVE CLEAR" % reward, _sun_pos() + Vector2(0.0, -_outer_ring_radius() - 52.0), Color(1.0, 0.86, 0.34, 0.98), 0.95)

	if GameState.current_wave >= playable_wave_limit and playable_wave_limit < MAX_WAVES:
		_play_sfx("wave_clear")
		GameState.set_phase(GameState.Phase.BETWEEN_WAVE)
		_refresh_next_wave_preview()
		_set_message("Wave %d cleared. Additional waves are locked for this scene." % GameState.current_wave, 999.0)
	elif GameState.current_wave >= MAX_WAVES:
		GameState.trigger_victory()
		_play_sfx("victory")
		_play_ending_music()
		_set_message("Victory. Final rank: %s." % GameState.get_rank(), 999.0)
	else:
		_play_sfx("wave_clear")
		GameState.set_phase(GameState.Phase.BETWEEN_WAVE)
		_refresh_next_wave_preview()
		_set_message("Wave %d cleared. Corps reward: %d Sol Credits." % [GameState.current_wave, reward], 4.0)
	_update_ui()


func _spawn_enemy(variant: String, spawn_pos = null) -> void:
	var key: String = GameWaveLibraryScript.variant_key(variant)
	var cfg: Dictionary = _enemy_config(key)
	var sun: Vector2 = _sun_pos()
	var angle: float = randf() * TAU
	var distance: float = _outer_ring_radius() + ENEMY_SPAWN_PADDING
	var pos: Vector2 = sun + Vector2(cos(angle), sin(angle)) * distance
	if spawn_pos is Vector2:
		pos = spawn_pos

	# Runtime enemies are small dictionaries so wave files only need to choose
	# a variant; all stats still come from GameCatalog.
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
		"hit_timer": 0.0,
		"heal_timer": 0.0,
		"prime_phase": 0,
	})


func _find_target_for_tower(tower: Dictionary) -> int:
	var tower_pos: Vector2 = _tower_position(tower)
	var sun: Vector2 = _sun_pos()
	var stats: Dictionary = _tower_runtime_stats(tower)
	var range: float = float(stats["range"])
	var range_squared: float = range * range
	var best_index: int = -1
	var best_sun_dist_squared: float = INF

	# Towers prefer the enemy closest to the sun. It is simple to explain and
	# keeps targeting focused on the immediate threat.
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
	var stats: Dictionary = _tower_runtime_stats(tower)
	var tower_pos: Vector2 = _tower_position(tower)
	var enemy_pos: Vector2 = enemies[enemy_index]["pos"]
	_add_shot(tower_pos, enemy_pos, cfg["color"], 0.15, 3.0, str(tower["type"]))
	_add_visual_effect("muzzle", tower_pos, cfg["color"], 0.16, 14.0)
	_play_sfx("shot", 0.035)
	_damage_enemy(enemy_index, float(stats["damage"]), str(tower["type"]))


func _tower_fire_interval(tower: Dictionary) -> float:
	var stats: Dictionary = _tower_runtime_stats(tower)
	var rate: float = float(stats["rate"])
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
	var stats: Dictionary = _tower_runtime_stats(tower)
	var range: float = float(stats["range"])
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
	var stats: Dictionary = _tower_runtime_stats(tower)
	var tower_pos: Vector2 = _tower_position(tower)
	var burrower_pos: Vector2 = _burrower_position(burrowers[burrower_index])
	_add_shot(tower_pos, burrower_pos, cfg["color"], 0.15, 3.0, str(tower["type"]))
	_add_visual_effect("muzzle", tower_pos, cfg["color"], 0.16, 14.0)
	_play_sfx("shot", 0.035)
	_damage_burrower(burrower_index, float(stats["damage"]))


func _damage_burrower(burrower_index: int, amount: float) -> void:
	if burrower_index < 0 or burrower_index >= burrowers.size():
		return

	var burrower: Dictionary = burrowers[burrower_index]
	burrower["hp"] = float(burrower["hp"]) - amount
	_add_visual_effect("hit", _burrower_position(burrower), Color(0.88, 0.58, 0.34), 0.22, 20.0)
	_play_sfx("hit", 0.050)
	if float(burrower["hp"]) <= 0.0:
		_add_burrower_death_effect(burrower)
		_play_sfx("death", 0.050)
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
	var enemy_pos: Vector2 = enemy["pos"]

	# These special cases are the enemy rules players learn in the codex.
	if variant == "mimic" and source == "photon_splitter":
		_add_visual_effect("shield", enemy_pos, Color(0.70, 0.62, 0.98), 0.32, float(enemy["radius"]) + 16.0)
		_play_sfx("hit", 0.080)
		return

	if source == "cryo_probe" or source == "magnetic_net":
		enemy["slow_timer"] = 2.8

	if variant == "farmer" and (source == "photon_splitter" or source == "helios_cannon"):
		enemy["hp"] = min(float(enemy["hp"]) + amount * 0.4, float(enemy["max_hp"]) * 1.8)
		enemy["speed"] = min(float(enemy["speed"]) + 1.0, 150.0)
		enemy["heal_timer"] = ENEMY_HIT_FLASH_SECONDS
		enemies[enemy_index] = enemy
		_add_visual_effect("heal", enemy_pos, Color(0.70, 1.0, 0.46), 0.34, float(enemy["radius"]) + 18.0)
		_play_sfx("hit", 0.080)
		return

	if variant == "prime" and int(enemy["prime_phase"]) == 0 and source != "bio_lab":
		_add_visual_effect("shield", enemy_pos, Color(1.0, 0.22, 0.18), 0.34, float(enemy["radius"]) + 20.0)
		_play_sfx("hit", 0.080)
		return
	elif variant == "prime" and int(enemy["prime_phase"]) == 0 and source == "bio_lab":
		enemy["prime_phase"] = 1
		_add_visual_effect("burst", enemy_pos, Color(0.46, 1.0, 0.52), 0.48, float(enemy["radius"]) + 32.0)
		_set_message("Bio-Lab cracked Prime's shell.", 2.0)

	enemy["hp"] = float(enemy["hp"]) - amount
	enemy["hit_timer"] = ENEMY_HIT_FLASH_SECONDS
	enemies[enemy_index] = enemy
	_add_visual_effect("hit", enemy_pos, enemy.get("color", Color(1.0, 0.7, 0.4)), 0.20, float(enemy["radius"]) + 8.0)
	_play_sfx("hit", 0.035)

	if float(enemy["hp"]) <= 0.0:
		_defeat_enemy(enemy_index)


func _defeat_enemy(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return

	var enemy: Dictionary = enemies[enemy_index]
	var variant: String = str(enemy["variant"])
	var pos: Vector2 = enemy["pos"]
	var enemy_color: Color = enemy.get("color", Color(1.0, 0.62, 0.36))

	GameState.add_credits(int(enemy["reward"]))
	GameState.on_enemy_killed(int(enemy["variant_id"]))
	_add_enemy_death_effect(enemy)
	_add_text_effect("+%d SOL" % int(enemy["reward"]), pos + Vector2(0.0, -float(enemy["radius"]) - 20.0), Color(1.0, 0.86, 0.34, 0.98))
	_play_sfx("prime_death" if variant == "prime" else "death", 0.050)

	enemies.remove_at(enemy_index)

	# Bloom splitting and Prime collapse happen after removal so spawned enemies
	# do not interfere with the index that was just defeated.
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
	_register_sun_hit(0.60)
	_set_message("A Coronal Burrower is lodged in the Sun. Bio-Lab can excavate it.", 3.0)
	_update_ui()


func _nearest_ring_slot(pos: Vector2) -> Dictionary:
	return GameOrbitMathScript.nearest_ring_slot(pos, _sun_pos(), Callable(self, "_is_slot_taken"))


func _nearest_slot_index(ring_index: int, angle: float) -> int:
	return GameOrbitMathScript.nearest_slot_index(ring_index, angle)


func _ring_slot_angle(ring_index: int, slot_index: int) -> float:
	return GameOrbitMathScript.ring_slot_angle(ring_index, slot_index)


func _ring_slot_position(ring_index: int, slot_index: int) -> Vector2:
	return GameOrbitMathScript.ring_slot_position(_sun_pos(), ring_index, slot_index)


func _ring_radius(ring_index: int) -> float:
	return GameOrbitMathScript.ring_radius(ring_index)


func _outer_ring_radius() -> float:
	return GameOrbitMathScript.outer_ring_radius()


func _is_slot_taken(ring_index: int, slot_index: int) -> bool:
	for tower in towers:
		if int(tower["ring"]) == ring_index and int(tower["slot"]) == slot_index:
			return true
	return false


func _tower_index_for_slot(ring_index: int, slot_index: int) -> int:
	for i in range(towers.size()):
		var tower: Dictionary = towers[i]
		if int(tower["ring"]) == ring_index and int(tower["slot"]) == slot_index:
			return i
	return -1


func _tower_index_at_world_position(pos: Vector2) -> int:
	var best_index: int = -1
	var best_dist_squared: float = INF
	var hit_radius_squared: float = 34.0 * 34.0
	for i in range(towers.size()):
		var tower_pos: Vector2 = _tower_position(towers[i])
		var dist_squared: float = pos.distance_squared_to(tower_pos)
		if dist_squared <= hit_radius_squared and dist_squared < best_dist_squared:
			best_index = i
			best_dist_squared = dist_squared
	return best_index


func _select_managed_tower(ring_index: int, slot_index: int) -> void:
	var tower_index: int = _tower_index_for_slot(ring_index, slot_index)
	if tower_index == -1:
		_clear_managed_tower()
		return
	_select_managed_tower_by_index(tower_index)


func _select_managed_tower_by_index(tower_index: int) -> void:
	if tower_index < 0 or tower_index >= towers.size():
		_clear_managed_tower()
		return
	var tower: Dictionary = towers[tower_index]
	managed_tower_ring = int(tower["ring"])
	managed_tower_slot = int(tower["slot"])
	_set_message("Managing %s. Upgrade, sell, or close the panel." % _tower_config(str(tower["type"]))["label"], 1.8)
	_update_ui()
	queue_redraw()


func _clear_managed_tower(refresh_ui: bool = true) -> void:
	if managed_tower_ring == -1 and managed_tower_slot == -1:
		return
	managed_tower_ring = -1
	managed_tower_slot = -1
	if refresh_ui:
		_update_ui()
		queue_redraw()


func _managed_tower_index() -> int:
	if managed_tower_ring < 0 or managed_tower_slot < 0:
		return -1
	return _tower_index_for_slot(managed_tower_ring, managed_tower_slot)


func _is_managed_tower(tower: Dictionary) -> bool:
	return (
		managed_tower_ring >= 0
		and managed_tower_slot >= 0
		and int(tower["ring"]) == managed_tower_ring
		and int(tower["slot"]) == managed_tower_slot
	)


func _tower_position(tower: Dictionary) -> Vector2:
	return GameOrbitMathScript.tower_position(_sun_pos(), tower)


func _burrower_position(burrower: Dictionary) -> Vector2:
	return GameOrbitMathScript.burrower_position(_sun_pos(), burrower, BURROWER_DIG_RADIUS)


func _draw_shot(shot: Dictionary) -> void:
	var shot_start: Vector2 = shot.get("from", Vector2.ZERO)
	var shot_end: Vector2 = shot.get("to", Vector2.ZERO)
	var color: Color = shot.get("color", SpaceTheme.COLOR_CYAN)
	var duration: float = maxf(float(shot.get("duration", shot.get("ttl", 0.12))), 0.01)
	var ttl: float = clampf(float(shot.get("ttl", 0.0)), 0.0, duration)
	var raw_progress: float = 1.0 - ttl / duration
	var progress: float = _ease_out_cubic(raw_progress)
	var alpha: float = 1.0 - _ease_in_out_sine(raw_progress)
	var width: float = float(shot.get("width", 3.0))
	var kind: String = str(shot.get("kind", "beam"))

	if kind == "flare":
		draw_line(shot_start, shot_end, Color(1.0, 0.34, 0.08, 0.18 * alpha), width + 8.0)
		draw_line(shot_start, shot_end, Color(color.r, color.g, color.b, 0.78 * alpha), width + 2.0)
		draw_line(shot_start, shot_end, Color(1.0, 0.96, 0.70, 0.72 * alpha), maxf(width - 1.2, 1.0))
		var spark_pos: Vector2 = shot_start.lerp(shot_end, clampf(progress * 1.16, 0.0, 1.0))
		draw_circle(spark_pos, 5.0 + progress * 8.0, Color(1.0, 0.82, 0.28, 0.36 * alpha))
		draw_circle(shot_end, 7.0 + progress * 6.0, Color(1.0, 0.62, 0.20, 0.24 * alpha))
		return

	var impact_radius: float = 4.0 + progress * 5.0
	draw_line(shot_start, shot_end, Color(0.0, 0.0, 0.0, 0.36 * alpha), width + 3.0)
	draw_line(shot_start, shot_end, Color(color.r, color.g, color.b, 0.72 * alpha), width)
	draw_line(shot_start, shot_end, Color(0.88, 0.98, 1.0, 0.26 * alpha), maxf(width - 1.2, 1.0))
	draw_circle(shot_end, impact_radius, Color(color.r, color.g, color.b, 0.26 * alpha))
	if kind == "cryo_probe" or kind == "magnetic_net":
		draw_arc(shot_end, impact_radius + 5.0, -0.5, PI + 0.5, 24, Color(color.r, color.g, color.b, 0.44 * alpha), 1.1, true)


func _draw_sun(pos: Vector2) -> void:
	var glow_strength: float = clamp(GameState.luminosity, 0.15, 1.0)
	var time_seconds: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.5 + sin(time_seconds * 1.35) * 0.5
	var hit_pulse: float = clampf(sun_hit_timer / SUN_HIT_EFFECT_SECONDS, 0.0, 1.0)
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
	if GameState.flare_charge > 0:
		var ready_pulse: float = 0.5 + sin(time_seconds * 2.2) * 0.5
		draw_arc(pos, SUN_RADIUS + 21.0 + ready_pulse * 4.0, 0.0, TAU, 180, Color(1.0, 0.82, 0.28, 0.22 + ready_pulse * 0.18), 2.0, true)
		for i in range(4):
			var flare_angle: float = time_seconds * 0.42 + TAU * float(i) / 4.0
			draw_arc(pos, SUN_RADIUS + 28.0, flare_angle, flare_angle + 0.32, 18, Color(1.0, 0.92, 0.54, 0.58), 2.0, true)
	if hit_pulse > 0.0:
		draw_circle(pos, SUN_RADIUS + 28.0 * (1.0 - hit_pulse), Color(1.0, 0.16, 0.06, 0.16 * hit_pulse))
		draw_arc(pos, SUN_RADIUS + 15.0 + (1.0 - hit_pulse) * 42.0, 0.0, TAU, 180, Color(1.0, 0.22, 0.08, 0.46 * hit_pulse), 3.0, true)


func _draw_tower(tower: Dictionary) -> void:
	var pos: Vector2 = _tower_position(tower)
	var cfg: Dictionary = _tower_config(str(tower["type"]))
	var stats: Dictionary = _tower_runtime_stats(tower)
	var tower_color: Color = cfg["color"]
	var texture = _tower_texture(str(tower["type"]))
	var disabled: bool = _is_tower_disabled(tower)
	var managed: bool = _is_managed_tower(tower)
	var time_seconds: float = Time.get_ticks_msec() / 1000.0

	if not disabled:
		draw_arc(pos, float(stats["range"]), 0.0, TAU, 160, Color(tower_color.r, tower_color.g, tower_color.b, 0.030), 1.0, true)
		draw_arc(pos, float(stats["range"]) + 2.0, 0.0, TAU, 160, Color(0.18, 0.55, 0.88, 0.018), 1.0, true)
	if managed:
		var select_pulse: float = 0.5 + sin(time_seconds * 3.0) * 0.5
		draw_circle(pos, 26.0 + select_pulse * 5.0, Color(1.0, 0.82, 0.28, 0.07 + select_pulse * 0.05))
		draw_arc(pos, 31.0 + select_pulse * 2.0, 0.0, TAU, 72, Color(1.0, 0.82, 0.28, 0.72 + select_pulse * 0.20), 2.0, true)
		draw_arc(pos, float(stats["range"]), -0.35, 0.35, 24, Color(1.0, 0.82, 0.28, 0.40), 2.0, true)
		draw_arc(pos, float(stats["range"]), PI - 0.35, PI + 0.35, 24, Color(1.0, 0.82, 0.28, 0.40), 2.0, true)

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
	var level: int = _tower_level(tower)
	if level > 1:
		for i in range(level):
			var tick_angle: float = -PI * 0.5 + float(i - 1) * 0.34
			var tick_pos: Vector2 = pos + Vector2(cos(tick_angle), sin(tick_angle)) * 29.0
			draw_circle(tick_pos, 2.5, Color(1.0, 0.82, 0.28, 0.88))
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
	_draw_enemy_status_markers(enemy, pos, radius)
	var hit_flash: float = clampf(float(enemy.get("hit_timer", 0.0)) / ENEMY_HIT_FLASH_SECONDS, 0.0, 1.0)
	var heal_flash: float = clampf(float(enemy.get("heal_timer", 0.0)) / ENEMY_HIT_FLASH_SECONDS, 0.0, 1.0)
	var show_bar: bool = hp_ratio < 0.995 or hit_flash > 0.0 or heal_flash > 0.0 or str(enemy["variant"]) == "prime"
	if show_bar:
		var bar_width: float = maxf(radius * 2.65, 40.0)
		if str(enemy["variant"]) == "prime":
			bar_width = maxf(bar_width, 88.0)
		var bar_pos: Vector2 = Vector2(pos.x - bar_width * 0.5, pos.y - radius - 18.0)
		_draw_health_bar(bar_pos, bar_width, HEALTH_BAR_HEIGHT, hp_ratio, enemy_color, hit_flash, heal_flash)


func _draw_health_bar(pos: Vector2, width: float, height: float, ratio: float, accent: Color, hit_flash: float = 0.0, heal_flash: float = 0.0) -> void:
	# A tiny segmented bar reads better over the starfield than a plain line.
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	var rect: Rect2 = Rect2(pos, Vector2(width, height))
	var fill_width: float = maxf(0.0, (width - 4.0) * clamped_ratio)
	var fill_color: Color = Color(0.45, 1.0, 0.58, 0.96)
	if clamped_ratio <= 0.28:
		fill_color = Color(1.0, 0.28, 0.18, 0.98)
	elif clamped_ratio <= 0.58:
		fill_color = Color(1.0, 0.78, 0.26, 0.98)

	var border_alpha: float = 0.58 + hit_flash * 0.34 + heal_flash * 0.18
	draw_rect(rect.grow(2.0), Color(0.0, 0.0, 0.0, 0.44 + hit_flash * 0.12), true)
	draw_rect(rect, Color(0.008, 0.016, 0.026, 0.88), true)
	draw_rect(rect, Color(0.20, 0.82, 0.96, border_alpha), false, 1.0)
	if fill_width > 0.0:
		var fill_rect: Rect2 = Rect2(pos + Vector2(2.0, 2.0), Vector2(fill_width, maxf(1.0, height - 4.0)))
		draw_rect(fill_rect, fill_color, true)
		draw_line(fill_rect.position, fill_rect.position + Vector2(fill_rect.size.x, 0.0), Color(1.0, 1.0, 1.0, 0.26 + heal_flash * 0.18), 1.0)
		if hit_flash > 0.0:
			draw_rect(fill_rect.grow(1.0), Color(1.0, 0.92, 0.66, 0.14 * hit_flash), false, 1.0)
		if heal_flash > 0.0:
			draw_rect(fill_rect.grow(1.0), Color(0.55, 1.0, 0.42, 0.18 * heal_flash), false, 1.0)

	var segments: int = 4
	if width >= 70.0:
		segments = 6
	for i in range(1, segments):
		var x: float = pos.x + width * float(i) / float(segments)
		draw_line(Vector2(x, pos.y + 1.0), Vector2(x, pos.y + height - 1.0), Color(0.0, 0.0, 0.0, 0.44), 1.0)
		draw_line(Vector2(x + 1.0, pos.y + 1.0), Vector2(x + 1.0, pos.y + height - 1.0), Color(accent.r, accent.g, accent.b, 0.12), 1.0)

	if hit_flash > 0.0:
		draw_line(pos + Vector2(-3.0, height + 2.0), pos + Vector2(width + 3.0, height + 2.0), Color(1.0, 0.38, 0.20, 0.34 * hit_flash), 1.0)


func _draw_enemy_status_markers(enemy: Dictionary, pos: Vector2, radius: float) -> void:
	var variant: String = str(enemy.get("variant", "drifter"))
	var tag_y: float = pos.y + radius + 8.0

	if float(enemy.get("slow_timer", 0.0)) > 0.0:
		draw_arc(pos, radius + 9.0, 0.0, TAU, 56, Color(0.24, 0.88, 1.0, 0.56), 1.5, true)
		draw_arc(pos, radius + 14.0, -0.7, 0.7, 24, Color(0.78, 0.96, 1.0, 0.46), 1.2, true)
		_draw_enemy_status_tag(Vector2(pos.x, tag_y), "SLOW", Color(0.34, 0.92, 1.0, 0.95))
		tag_y += ENEMY_STATUS_TAG_HEIGHT + 2.0

	if variant == "prime":
		if int(enemy.get("prime_phase", 0)) == 0:
			draw_arc(pos, radius + 11.0, 0.0, TAU, 72, Color(1.0, 0.30, 0.18, 0.62), 2.0, true)
			draw_arc(pos, radius + 17.0, 0.0, TAU, 72, Color(1.0, 0.82, 0.28, 0.28), 1.2, true)
			_draw_enemy_status_tag(Vector2(pos.x, tag_y), "SHELL", Color(1.0, 0.42, 0.28, 0.96))
		else:
			draw_arc(pos, radius + 10.0, -0.4, 0.4, 20, Color(0.52, 1.0, 0.58, 0.48), 1.5, true)
			draw_arc(pos, radius + 10.0, PI - 0.4, PI + 0.4, 20, Color(0.52, 1.0, 0.58, 0.48), 1.5, true)
			_draw_enemy_status_tag(Vector2(pos.x, tag_y), "OPEN", Color(0.56, 1.0, 0.62, 0.94))
	elif variant == "mimic":
		draw_arc(pos, radius + 10.0, 0.0, TAU, 50, Color(0.72, 0.56, 1.0, 0.38), 1.4, true)
		_draw_enemy_status_tag(Vector2(pos.x, tag_y), "MIMIC", Color(0.78, 0.68, 1.0, 0.94))
	elif variant == "farmer":
		draw_arc(pos, radius + 10.0, 0.0, TAU, 50, Color(0.66, 1.0, 0.42, 0.35), 1.4, true)
		_draw_enemy_status_tag(Vector2(pos.x, tag_y), "ABSORB", Color(0.76, 1.0, 0.48, 0.94))


func _draw_enemy_status_tag(anchor: Vector2, text: String, color: Color) -> void:
	var text_width: float = maxf(42.0, float(text.length()) * 7.4)
	var rect: Rect2 = Rect2(anchor - Vector2(text_width * 0.5, 0.0), Vector2(text_width, ENEMY_STATUS_TAG_HEIGHT))
	draw_rect(rect, Color(0.002, 0.008, 0.016, 0.74), true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.62), false, 1.0)
	draw_line(rect.position + Vector2(3.0, 3.0), rect.position + Vector2(3.0, rect.size.y - 3.0), Color(color.r, color.g, color.b, 0.76), 1.0)
	if end_body_font != null:
		draw_string(
			end_body_font,
			rect.position + Vector2(0.0, rect.size.y - 3.0),
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			ENEMY_STATUS_FONT_SIZE,
			Color(color.r, color.g, color.b, 0.98)
		)


func _draw_burrower(burrower: Dictionary) -> void:
	var pos: Vector2 = _burrower_position(burrower)
	var hp_ratio: float = clamp(float(burrower["hp"]) / float(burrower["max_hp"]), 0.0, 1.0)
	var burrower_color: Color = burrower.get("color", Color(0.76, 0.50, 0.30))
	draw_circle(pos, 18.0, Color(0.02, 0.01, 0.01, 0.72))
	draw_circle(pos, 11.0, burrower_color)
	draw_circle(pos, 5.0, Color(0.18, 0.08, 0.04, 0.85))
	_draw_health_bar(pos + Vector2(-18.0, -25.0), 36.0, 5.0, hp_ratio, burrower_color)


func _draw_build_preview() -> void:
	if not _can_build_towers() or game_hud == null or tutorial_overlay != null:
		return

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	if not get_viewport_rect().has_point(mouse_position):
		return
	if game_hud.is_screen_position_over_hud(mouse_position):
		return

	var slot: Dictionary = _nearest_ring_slot(_screen_to_world(mouse_position))
	if slot.is_empty():
		return

	var cfg: Dictionary = _tower_config(selected_tower)
	var cost: int = GameState.get_tower_cost(selected_tower)
	var can_afford: bool = GameState.can_afford(cost)
	var occupied: bool = bool(slot.get("occupied", false))
	var slot_pos: Vector2 = _ring_slot_position(int(slot["ring_index"]), int(slot["slot_index"]))
	var accent: Color = cfg["color"]
	if occupied:
		accent = Color(1.0, 0.25, 0.16)
	elif not can_afford:
		accent = Color(0.50, 0.58, 0.66)

	draw_arc(slot_pos, 18.0, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.86), 2.0, true)
	draw_arc(slot_pos, 27.0, -0.45, 0.45, 18, Color(1.0, 0.82, 0.28, 0.86), 2.0, true)
	draw_arc(slot_pos, 27.0, PI - 0.45, PI + 0.45, 18, Color(1.0, 0.82, 0.28, 0.86), 2.0, true)
	if occupied:
		draw_line(slot_pos + Vector2(-13.0, -13.0), slot_pos + Vector2(13.0, 13.0), Color(1.0, 0.30, 0.18, 0.92), 2.0)
		draw_line(slot_pos + Vector2(-13.0, 13.0), slot_pos + Vector2(13.0, -13.0), Color(1.0, 0.30, 0.18, 0.92), 2.0)
		return

	if can_afford:
		draw_arc(slot_pos, float(cfg["range"]), 0.0, TAU, 160, Color(accent.r, accent.g, accent.b, 0.050), 1.2, true)
		draw_circle(slot_pos, 22.0, Color(accent.r, accent.g, accent.b, 0.13))
		var texture = _tower_texture(selected_tower)
		if texture:
			var size: Vector2 = Vector2(46.0, 46.0)
			draw_texture_rect(texture, Rect2(slot_pos - size * 0.5, size), false, Color(1.0, 1.0, 1.0, 0.52))
	else:
		draw_circle(slot_pos, 22.0, Color(0.16, 0.18, 0.22, 0.30))


func _draw_visual_effects() -> void:
	for effect in effect_store.visual_effects:
		var duration: float = maxf(float(effect.get("duration", 0.25)), 0.01)
		var ttl: float = clampf(float(effect.get("ttl", 0.0)), 0.0, duration)
		var raw_progress: float = 1.0 - ttl / duration
		var progress: float = _ease_out_cubic(raw_progress)
		var alpha: float = 1.0 - _ease_in_out_sine(raw_progress)
		var pos: Vector2 = effect.get("pos", Vector2.ZERO)
		var color: Color = effect.get("color", SpaceTheme.COLOR_GOLD)
		var radius: float = float(effect.get("radius", 24.0))

		# Visual effects are data-driven: each effect stores a kind, position,
		# color, radius, and time left. When ttl reaches zero it is removed.
		match str(effect.get("kind", "hit")):
			"text":
				var text: String = str(effect.get("text", ""))
				var offset: Vector2 = Vector2(0.0, -34.0 * progress)
				var font_size: int = int(effect.get("font_size", 16))
				var text_width: float = maxf(140.0, float(text.length()) * float(font_size) * 0.72)
				if end_body_font != null:
					draw_string(
						end_body_font,
						pos + offset - Vector2(text_width * 0.5, 0.0) + Vector2(0.0, 1.0),
						text,
						HORIZONTAL_ALIGNMENT_CENTER,
						text_width,
						font_size,
						Color(0.0, 0.0, 0.0, 0.55 * alpha)
					)
					draw_string(
						end_body_font,
						pos + offset - Vector2(text_width * 0.5, 0.0),
						text,
						HORIZONTAL_ALIGNMENT_CENTER,
						text_width,
						font_size,
						Color(color.r, color.g, color.b, 0.95 * alpha)
					)
			"place":
				draw_arc(pos, radius + progress * 42.0, 0.0, TAU, 72, Color(color.r, color.g, color.b, 0.62 * alpha), 2.0, true)
				draw_circle(pos, 4.0 + progress * 8.0, Color(color.r, color.g, color.b, 0.22 * alpha))
			"upgrade":
				draw_arc(pos, radius + progress * 46.0, 0.0, TAU, 84, Color(color.r, color.g, color.b, 0.68 * alpha), 2.0, true)
				draw_arc(pos, radius * 0.62 + progress * 26.0, -PI * 0.25, PI * 1.25, 64, Color(1.0, 0.84, 0.32, 0.62 * alpha), 2.0, true)
				draw_circle(pos, 7.0 + progress * 10.0, Color(color.r, color.g, color.b, 0.20 * alpha))
				for i in range(6):
					var angle: float = TAU * float(i) / 6.0 + progress * 0.45
					var direction: Vector2 = Vector2(cos(angle), sin(angle))
					draw_line(
						pos + direction * (radius * 0.30),
						pos + direction * (radius + progress * 32.0),
						Color(1.0, 0.84, 0.32, 0.54 * alpha),
						1.4
					)
			"sell":
				draw_arc(pos, radius + progress * 34.0, 0.0, TAU, 72, Color(color.r, color.g, color.b, 0.44 * alpha), 1.6, true)
				draw_circle(pos, radius * (0.30 + progress * 0.40), Color(color.r, color.g, color.b, 0.10 * alpha))
				for i in range(7):
					var angle: float = TAU * float(i) / 7.0 - progress * 0.30
					var direction: Vector2 = Vector2(cos(angle), sin(angle))
					var start: Vector2 = pos + direction * (radius * 0.18)
					var end: Vector2 = pos + direction * (radius * 0.72 + progress * 34.0)
					draw_line(start, end, Color(color.r, color.g, color.b, 0.44 * alpha), 1.2)
			"muzzle":
				draw_circle(pos, radius * (1.0 + progress * 0.6), Color(color.r, color.g, color.b, 0.34 * alpha))
				draw_circle(pos, 4.0 + progress * 4.0, Color(1.0, 0.96, 0.72, 0.62 * alpha))
			"hit":
				draw_circle(pos, radius * (0.42 + progress * 0.55), Color(1.0, 0.96, 0.74, 0.24 * alpha))
				draw_arc(pos, radius + progress * 10.0, 0.0, TAU, 36, Color(color.r, color.g, color.b, 0.58 * alpha), 1.6, true)
			"heal":
				draw_arc(pos, radius + progress * 16.0, -PI * 0.25, PI * 1.25, 54, Color(color.r, color.g, color.b, 0.70 * alpha), 2.0, true)
				draw_line(pos + Vector2(-7.0, 0.0), pos + Vector2(7.0, 0.0), Color(color.r, color.g, color.b, 0.66 * alpha), 2.0)
				draw_line(pos + Vector2(0.0, -7.0), pos + Vector2(0.0, 7.0), Color(color.r, color.g, color.b, 0.66 * alpha), 2.0)
			"shield":
				draw_arc(pos, radius + progress * 14.0, 0.0, TAU, 72, Color(color.r, color.g, color.b, 0.72 * alpha), 2.0, true)
				draw_circle(pos, radius * 0.64, Color(color.r, color.g, color.b, 0.10 * alpha))
			"sun_hit":
				draw_arc(pos, radius + progress * 58.0, 0.0, TAU, 112, Color(1.0, 0.35, 0.12, 0.52 * alpha), 2.8, true)
				draw_circle(pos, radius * 0.82 + progress * 20.0, Color(1.0, 0.20, 0.08, 0.10 * alpha))
			"flare":
				draw_circle(pos, radius * (0.55 + progress * 0.30), Color(1.0, 0.36, 0.08, 0.10 * alpha))
				draw_arc(pos, radius + progress * 92.0, 0.0, TAU, 144, Color(1.0, 0.72, 0.20, 0.62 * alpha), 3.2, true)
				draw_arc(pos, radius * 0.64 + progress * 46.0, 0.0, TAU, 112, Color(1.0, 0.94, 0.58, 0.32 * alpha), 1.8, true)
				for i in range(14):
					var angle: float = TAU * float(i) / 14.0 + progress * 0.22
					var direction: Vector2 = Vector2(cos(angle), sin(angle))
					draw_line(
						pos + direction * (radius * 0.70),
						pos + direction * (radius + 72.0 + progress * 74.0),
						Color(1.0, 0.64, 0.16, 0.30 * alpha),
						1.6
					)
			"enemy_death":
				var draw_size: float = float(effect.get("draw_size", radius * 2.0))
				var texture: Texture2D = effect.get("texture", null) as Texture2D
				if texture != null:
					var ghost_size: Vector2 = Vector2(draw_size, draw_size) * (0.92 + progress * 0.28)
					draw_texture_rect(texture, Rect2(pos - ghost_size * 0.5, ghost_size), false, Color(1.0, 0.84, 0.74, 0.24 * alpha))
				draw_circle(pos, radius * (0.34 + progress * 0.42), Color(color.r, color.g, color.b, 0.16 * alpha))
				draw_arc(pos, radius + progress * 30.0, 0.0, TAU, 80, Color(color.r, color.g, color.b, 0.66 * alpha), 1.8, true)
				draw_arc(pos, radius * 0.62 + progress * 18.0, -PI * 0.35, PI * 1.15, 54, Color(1.0, 0.84, 0.42, 0.36 * alpha), 1.2, true)
				for i in range(10):
					var angle: float = TAU * float(i) / 10.0 + progress * 0.28
					var direction: Vector2 = Vector2(cos(angle), sin(angle))
					var start: Vector2 = pos + direction * (radius * 0.34)
					var end: Vector2 = pos + direction * (radius + 20.0 + progress * 34.0)
					draw_line(start, end, Color(color.r, color.g, color.b, 0.48 * alpha), 1.3)
					if i % 3 == 0:
						draw_circle(end, 1.6 + progress * 1.4, Color(1.0, 0.92, 0.62, 0.36 * alpha))
			"burrower_death":
				draw_circle(pos, radius * (0.36 + progress * 0.48), Color(0.86, 0.50, 0.26, 0.18 * alpha))
				draw_arc(pos, radius + progress * 28.0, 0.0, TAU, 74, Color(0.92, 0.58, 0.34, 0.62 * alpha), 1.8, true)
				for i in range(12):
					var angle: float = TAU * float(i) / 12.0 - progress * 0.22
					var direction: Vector2 = Vector2(cos(angle), sin(angle))
					draw_line(
						pos + direction * (radius * 0.30),
						pos + direction * (radius + 18.0 + progress * 30.0),
						Color(0.92, 0.58, 0.34, 0.42 * alpha),
						1.3
					)
			"prime_death":
				var prime_texture: Texture2D = effect.get("texture", null) as Texture2D
				var prime_draw_size: float = float(effect.get("draw_size", radius * 2.0))
				if prime_texture != null:
					var prime_size: Vector2 = Vector2(prime_draw_size, prime_draw_size) * (1.0 + progress * 0.22)
					draw_texture_rect(prime_texture, Rect2(pos - prime_size * 0.5, prime_size), false, Color(1.0, 0.60, 0.46, 0.28 * alpha))
				draw_circle(pos, radius * (0.46 + progress * 0.34), Color(0.05, 0.0, 0.0, 0.32 * alpha))
				draw_arc(pos, radius + progress * 76.0, 0.0, TAU, 152, Color(1.0, 0.24, 0.14, 0.68 * alpha), 3.0, true)
				draw_arc(pos, radius * 0.72 + progress * 42.0, 0.0, TAU, 124, Color(1.0, 0.82, 0.28, 0.45 * alpha), 2.0, true)
				for i in range(20):
					var angle: float = TAU * float(i) / 20.0 + progress * 0.18
					var direction: Vector2 = Vector2(cos(angle), sin(angle))
					var length: float = radius + 36.0 + progress * (52.0 + float(i % 5) * 6.0)
					draw_line(
						pos + direction * (radius * 0.38),
						pos + direction * length,
						Color(1.0, 0.35, 0.14, 0.42 * alpha),
						1.7
					)
			"burst":
				draw_circle(pos, radius * (0.26 + progress * 0.42), Color(color.r, color.g, color.b, 0.18 * alpha))
				draw_arc(pos, radius + progress * 24.0, 0.0, TAU, 80, Color(color.r, color.g, color.b, 0.62 * alpha), 1.8, true)
				for i in range(8):
					var angle: float = TAU * float(i) / 8.0 + progress * 0.35
					var direction: Vector2 = Vector2(cos(angle), sin(angle))
					var start: Vector2 = pos + direction * (radius * 0.35)
					var end: Vector2 = pos + direction * (radius + progress * 34.0)
					draw_line(start, end, Color(color.r, color.g, color.b, 0.50 * alpha), 1.4)


func _draw_end_state_overlay(viewport_size: Vector2) -> void:
	var victory: bool = GameState.game_phase == GameState.Phase.VICTORY
	var accent: Color = SpaceTheme.COLOR_GOLD if victory else Color(1.0, 0.28, 0.18, 0.92)
	var title: String = "SOL SAVED" if victory else "LUMINOSITY COLLAPSE"
	var subtitle: String = "Mission complete. The defense grid held." if victory else "The defense grid failed. The sun went dark."
	var panel_size: Vector2 = Vector2(650.0, 318.0)
	var panel_rect: Rect2 = Rect2(viewport_size * 0.5 - panel_size * 0.5, panel_size)

	draw_rect(panel_rect, Color(0.004, 0.010, 0.022, 0.90), true)
	draw_rect(panel_rect, Color(accent.r, accent.g, accent.b, 0.82), false, 1.4)
	_draw_screen_corner(panel_rect.position, Vector2.RIGHT, Vector2.DOWN, 48.0, accent)
	_draw_screen_corner(panel_rect.position + Vector2(panel_rect.size.x, 0.0), Vector2.LEFT, Vector2.DOWN, 48.0, accent)
	_draw_screen_corner(panel_rect.position + Vector2(0.0, panel_rect.size.y), Vector2.RIGHT, Vector2.UP, 48.0, accent)
	_draw_screen_corner(panel_rect.position + panel_rect.size, Vector2.LEFT, Vector2.UP, 48.0, accent)

	var x: float = panel_rect.position.x
	var y: float = panel_rect.position.y + 48.0
	var width: float = panel_rect.size.x
	_draw_centered_text(end_title_font, title, x, y, width, 28, accent)
	_draw_centered_text(end_body_font, subtitle, x, y + 45.0, width, 17, SpaceTheme.COLOR_TEXT)

	var luminosity_text: String = "FINAL LUMINOSITY  %d%%" % GameState.get_luminosity_percent()
	var rank_text: String = "RANK  %s" % GameState.get_rank()
	var stats_text: String = "WAVES CLEARED  %d/%d     KILLS  %d     SCORE  %d" % [
		GameState.waves_cleared,
		MAX_WAVES,
		GameState.enemies_killed_total,
		GameState.performance_score,
	]
	_draw_centered_text(end_body_font, luminosity_text, x, y + 98.0, width, 18, Color(1.0, 0.88, 0.42, 0.96))
	_draw_centered_text(end_body_font, rank_text, x, y + 132.0, width, 18, Color(0.42, 0.90, 1.0, 0.96))
	_draw_centered_text(end_body_font, stats_text, x, y + 178.0, width, 15, Color(0.78, 0.88, 0.96, 0.92))
	_draw_centered_text(end_body_font, "Open Menu to return or inspect the Mission Codex.", x, y + 228.0, width, 14, Color(0.68, 0.78, 0.88, 0.88))


func _draw_screen_corner(origin: Vector2, horizontal: Vector2, vertical: Vector2, length: float, color: Color) -> void:
	draw_line(origin, origin + horizontal * length, Color(color.r, color.g, color.b, 0.92), 2.0)
	draw_line(origin, origin + vertical * length, Color(color.r, color.g, color.b, 0.92), 2.0)
	var notch: float = length * 0.35
	draw_line(origin + horizontal * 12.0 + vertical * 12.0, origin + horizontal * (12.0 + notch) + vertical * 12.0, SpaceTheme.COLOR_CYAN, 1.4)
	draw_line(origin + horizontal * 12.0 + vertical * 12.0, origin + horizontal * 12.0 + vertical * (12.0 + notch), SpaceTheme.COLOR_CYAN, 1.4)


func _draw_centered_text(font: Font, text: String, x: float, y: float, width: float, font_size: int, color: Color) -> void:
	if font == null:
		return
	draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)


func _ease_out_cubic(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)


func _ease_in_out_sine(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return 0.5 - cos(t * PI) * 0.5


func _sun_pos() -> Vector2:
	return get_viewport_rect().size * 0.5


func _view_translation(viewport_size: Vector2) -> Vector2:
	return view_controller.translation(viewport_size)


func _screen_shake_offset() -> Vector2:
	if screen_shake_timer <= 0.0 or not GameState.screen_shake_enabled:
		return Vector2.ZERO
	var fade: float = clampf(screen_shake_timer / 0.34, 0.0, 1.0)
	var time_seconds: float = Time.get_ticks_msec() / 1000.0
	return Vector2(
		sin(time_seconds * 73.0),
		cos(time_seconds * 61.0)
	) * screen_shake_strength * fade


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return view_controller.screen_to_world(screen_position, get_viewport_rect().size)


func _world_to_screen(world_position: Vector2) -> Vector2:
	return view_controller.world_to_screen(world_position, get_viewport_rect().size)


func _set_view_zoom(next_zoom: float, focus_screen_position: Vector2) -> void:
	view_controller.set_zoom(next_zoom, focus_screen_position, get_viewport_rect().size, _outer_ring_radius())
	queue_redraw()


func _reset_view() -> void:
	view_controller.reset()
	_play_sfx("button", 0.08)
	queue_redraw()


func _can_build_towers() -> bool:
	return (
		GameState.game_phase == GameState.Phase.BETWEEN_WAVE
		or GameState.game_phase == GameState.Phase.WAVE_ACTIVE
	)


func _clamp_view_offset() -> void:
	view_controller.clamp_to_board(get_viewport_rect().size, _outer_ring_radius())


func _add_visual_effect(kind: String, pos: Vector2, color: Color, duration: float, radius: float) -> void:
	effect_store.add_visual(kind, pos, color, duration, radius)
	queue_redraw()


func _add_enemy_death_effect(enemy: Dictionary) -> void:
	var variant: String = str(enemy.get("variant", "drifter"))
	var radius: float = float(enemy.get("radius", 18.0))
	if variant == "prime":
		if GameState.screen_shake_enabled:
			screen_shake_timer = maxf(screen_shake_timer, 0.38)
			screen_shake_strength = maxf(screen_shake_strength, 9.0)

	effect_store.add_enemy_death(enemy, _enemy_texture(variant), float(enemy.get("draw_size", radius * 2.0)))
	queue_redraw()


func _add_burrower_death_effect(burrower: Dictionary) -> void:
	var pos: Vector2 = _burrower_position(burrower)
	var color: Color = burrower.get("color", Color(0.76, 0.50, 0.30))
	effect_store.add_burrower_death(pos, color)
	queue_redraw()


func _add_shot(shot_start: Vector2, shot_end: Vector2, color: Color, duration: float, width: float = 3.0, kind: String = "beam") -> void:
	effect_store.add_shot(shot_start, shot_end, color, duration, width, kind)
	queue_redraw()


func _add_text_effect(text: String, pos: Vector2, color: Color, duration: float = 0.78, font_size: int = 16) -> void:
	effect_store.add_text(text, pos, color, duration, font_size)
	queue_redraw()


func _register_sun_hit(intensity: float = 1.0) -> void:
	sun_hit_timer = SUN_HIT_EFFECT_SECONDS
	if GameState.screen_shake_enabled:
		screen_shake_timer = maxf(screen_shake_timer, 0.32)
		screen_shake_strength = maxf(screen_shake_strength, 7.0 * intensity)
	_add_visual_effect("sun_hit", _sun_pos(), Color(1.0, 0.26, 0.10), 0.58, SUN_RADIUS + 18.0)
	_play_sfx("sun_hit", 0.18)


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
	next_wave_preview = GameWaveLibraryScript.load_wave(next_wave)


func _is_prime_alive() -> bool:
	for enemy in enemies:
		if str(enemy["variant"]) == "prime":
			return true
	return false


func _tower_config(tower_type: String) -> Dictionary:
	return GameTowerLibraryScript.config(tower_type)


func _tower_level(tower: Dictionary) -> int:
	return GameTowerLibraryScript.level(tower)


func _tower_runtime_stats(tower: Dictionary) -> Dictionary:
	return GameTowerLibraryScript.runtime_stats(tower)


func _tower_upgrade_cost(tower: Dictionary) -> int:
	return GameTowerLibraryScript.upgrade_cost(tower)


func _tower_sell_refund(tower: Dictionary) -> int:
	return GameTowerLibraryScript.sell_refund(tower)


func _managed_tower_view_data() -> Dictionary:
	var tower_index: int = _managed_tower_index()
	if tower_index == -1:
		managed_tower_ring = -1
		managed_tower_slot = -1
		return {}

	var tower: Dictionary = towers[tower_index]
	return GameTowerLibraryScript.managed_view_data(tower, RINGS)


func _end_state_view_data() -> Dictionary:
	if GameState.game_phase != GameState.Phase.GAME_OVER and GameState.game_phase != GameState.Phase.VICTORY:
		return {}

	var victory: bool = GameState.game_phase == GameState.Phase.VICTORY
	var title: String = "SOL SAVED" if victory else "LUMINOSITY COLLAPSE"
	var subtitle: String = "Mission complete. The defense grid held." if victory else "The defense grid failed. The sun went dark."
	var stats: String = "WAVES %d/%d  |  KILLS %d  |  SCORE %d  |  LUMINOSITY %d%%" % [
		GameState.waves_cleared,
		MAX_WAVES,
		GameState.enemies_killed_total,
		GameState.performance_score,
		GameState.get_luminosity_percent(),
	]
	var tip: String = "Retry the run, return to the main menu, or press R/M."
	if victory:
		tip = "Run secured. Retry for a stronger rank, return to menu, or press R/M."
	return {
		"victory": victory,
		"title": title,
		"subtitle": subtitle,
		"rank": "RANK  %s" % GameState.get_rank(),
		"stats": stats,
		"tip": tip,
	}


func _enemy_config(variant: String) -> Dictionary:
	return ENEMY_CONFIGS.get(variant, ENEMY_CONFIGS["drifter"])


func _tower_texture(tower_type: String):
	return textures["towers"].get(tower_type, null)


func _enemy_texture(variant: String):
	return textures["enemies"].get(variant, null)


func _ring_summary() -> String:
	return GameOrbitMathScript.ring_summary()


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


func _selected_tower_readout() -> String:
	return GameTowerLibraryScript.selected_readout(selected_tower, GameState.game_phase == GameState.Phase.WAVE_ACTIVE)


func _set_message(text: String, duration: float = 0.0) -> void:
	message_text = text
	message_timer = duration
	_update_ui()


func _tower_button_view_data() -> Dictionary:
	return GameTowerLibraryScript.button_view_data(selected_tower, _can_build_towers(), textures["towers"])


func _update_ui() -> void:
	if game_hud == null:
		return

	# The HUD receives one dictionary instead of reading gameplay variables
	# directly. That keeps display code separate from gameplay rules.
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
	var start_disabled: bool = GameState.game_phase != GameState.Phase.BETWEEN_WAVE or next_wave > playable_wave_limit
	var start_text: String = "START WAVE %d" % next_wave
	var intel_status: String = "LIVE" if GameState.game_phase == GameState.Phase.WAVE_ACTIVE else "NEXT"
	if GameState.auto_start_waves_enabled and not start_disabled and auto_start_timer > 0.0:
		start_text = "AUTO IN %d" % max(1, int(ceil(auto_start_timer)))
		intel_status = "AUTO %d" % max(1, int(ceil(auto_start_timer)))
	elif GameState.auto_start_waves_enabled and not start_disabled:
		intel_status = "AUTO START"
	game_hud.update_view({
		"wave_title": title_text,
		"brief": GameWaveLibraryScript.clean_hint(str(wave_data.get("tutorial_hint", "Defend the Sun.")), wave_name),
		"credits": str(GameState.sol_credits),
		"score": str(GameState.performance_score),
		"kills": str(GameState.enemies_killed_total),
		"flare": "F READY" if GameState.flare_charge > 0 else "CHARGING",
		"luminosity": float(GameState.get_luminosity_percent()),
		"enemy_texture": _enemy_texture(GameWaveLibraryScript.primary_variant(wave_data)),
		"intel_status": intel_status,
		"enemy_summary": GameWaveLibraryScript.spawn_summary(wave_data).to_upper(),
		"threat": GameWaveLibraryScript.intel_detail(
			wave_data,
			reward,
			enemies.size() if GameState.game_phase == GameState.Phase.WAVE_ACTIVE else -1,
			burrowers.size(),
			spawn_queue.size(),
			_active_modifier_summary()
		).to_upper(),
		"rings": _ring_summary(),
		"start_text": start_text,
		"start_disabled": start_disabled,
		"auto_start_enabled": GameState.auto_start_waves_enabled,
		"message": message_text,
		"selected_tower": _selected_tower_readout(),
		"tower_buttons": _tower_button_view_data(),
		"managed_tower": _managed_tower_view_data(),
		"end_state": _end_state_view_data(),
	})
