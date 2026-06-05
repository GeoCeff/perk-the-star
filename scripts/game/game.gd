extends Node2D


var SpaceTheme: RefCounted = ClassDB.instantiate("SpaceThemeNative") as RefCounted

var game_catalog: RefCounted = ClassDB.instantiate("GameCatalogNative") as RefCounted
var MAX_WAVES: int = int(game_catalog.get("max_waves"))
var SUN_RADIUS: float = float(game_catalog.get("sun_radius"))
var SUN_DAMAGE_RADIUS: float = float(game_catalog.get("sun_damage_radius"))
var ENEMY_SPAWN_PADDING: float = float(game_catalog.get("enemy_spawn_padding"))
var FLARE_DAMAGE: float = float(game_catalog.get("flare_damage"))
var BURROWER_DIG_RADIUS: float = float(game_catalog.get("burrower_dig_radius"))
var BURROWER_EXCAVATION_HP: float = float(game_catalog.get("burrower_excavation_hp"))
var BURROWER_DRAIN_INTERVAL: float = float(game_catalog.get("burrower_drain_interval"))
var BURROWER_DRAIN_DAMAGE: float = float(game_catalog.get("burrower_drain_damage"))

const WAVE_EARLY_BGM_PATH: String = "res://assets/audio/bgm/final/wave_01.ogg"
const WAVE_MID_BGM_PATH: String = "res://assets/audio/bgm/final/wave_02.ogg"
const WAVE_LATE_BGM_PATH: String = "res://assets/audio/bgm/final/wave_03.ogg"
const BOSS_BGM_PATH: String = "res://assets/audio/bgm/final/BOSS.ogg"
const END_BGM_PATH: String = "res://assets/audio/bgm/end.ogg"
const GAME_HUD_SCENE_PATH: String = "res://scenes/ui/game_hud.tscn"
const GAME_PAUSE_MENU_SCENE_PATH: String = "res://scenes/ui/game_pause_menu.tscn"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const BATTLE_BACKGROUND_PATH: String = "res://assets/sprites/backgrounds/battle_nebula_hq.png"
const END_TITLE_FONT_PATH: String = "res://assets/fonts/Kenney Future.ttf"
const END_BODY_FONT_PATH: String = "res://assets/fonts/Electrolize-Regular.ttf"
const SUN_HIT_EFFECT_SECONDS: float = 0.55
const ENEMY_STATUS_TAG_HEIGHT: float = 15.0
const ENEMY_STATUS_FONT_SIZE: int = 10
const ENEMY_HIT_FLASH_SECONDS: float = 0.24
const HEALTH_BAR_HEIGHT: float = 6.0
const AUTO_START_DELAY: float = 3.0

var ENEMY_ASSET_PATHS: Dictionary = game_catalog.call("enemy_asset_paths") as Dictionary
var ENEMY_ANIMATION_PATHS: Dictionary = game_catalog.call("enemy_animation_paths") as Dictionary
var ENEMY_ANIMATION_BASE_ANGLES: Dictionary = game_catalog.call("enemy_animation_base_angles") as Dictionary
var ENEMY_MASSES: Dictionary = game_catalog.call("enemy_masses") as Dictionary
var ENEMY_GRAVITY_CONST: float = float(game_catalog.get("enemy_gravity_const"))
var ENEMY_GRAVITY_ACCEL_CAP: float = float(game_catalog.get("enemy_gravity_accel_cap"))
var PHYSICS_PROJECTILE_GRAVITY_CONST: float = float(game_catalog.get("physics_projectile_gravity_const"))
var PHYSICS_PROJECTILE_DAMAGE_RING_MULT: float = float(game_catalog.get("physics_projectile_damage_ring_mult"))
var PHYSICS_PROJECTILE_OUTWARD_DEFLECT: float = float(game_catalog.get("physics_projectile_outward_deflect"))
var PHYSICS_PROJECTILE_MAX_LIFETIME: float = float(game_catalog.get("physics_projectile_max_lifetime"))
var PHYSICS_PROJECTILE_HIT_RADIUS: float = float(game_catalog.get("physics_projectile_hit_radius"))
var SLINGSHOT_COST: int = int(game_catalog.get("slingshot_cost"))
var TOWER_ASSET_PATHS: Dictionary = game_catalog.call("tower_asset_paths") as Dictionary
var RINGS: Array = game_catalog.call("rings") as Array
var ENEMY_CONFIGS: Dictionary = game_catalog.call("enemy_configs") as Dictionary
var SLOT_ANGLE_OFFSET: float = float(game_catalog.get("slot_angle_offset"))
const VIEW_ZOOM_STEP: float = 1.12

@export_range(1, 12, 1) var playable_wave_limit: int = 12
@export var briefing_title: String = "SOL DEFENSE CORPS"

var current_wave_data: Dictionary = {}
var next_wave_preview: Dictionary = {}
var spawn_queue: Array = []
var clash_schedule: Array = []
var wave_preview_points: Array = []
var physics_projectiles: Array = []
var ring_flash_timers: Dictionary = {}
var spawn_timer: float = 0.0
var spawned_wave_count: int = 0
var total_wave_spawn_count: int = 0
var next_enemy_uid: int = 1
var wave_active: bool = false
var wave_start_time: float = 0.0
var escalation_checked: bool = false
var counter_attack_active: bool = false
var auto_start_timer: float = 0.0
var auto_start_countdown_second: int = -1
var message_text: String = "Select an orbital slot, then start Wave 1."
var message_timer: float = 0.0
var wave_banner_text: String = ""
var wave_banner_subtitle: String = ""
var wave_banner_timer: float = 0.0
var wave_banner_accent: Color = Color(1.0, 0.82, 0.24)

var wave_event: Dictionary = {}
var wave_event_triggered: bool = false
var cryo_disruption_timer: float = 0.0
var bio_lab_boost_timer: float = 0.0
var bio_lab_boost_multiplier: float = 1.0
var ring_blind_timers: Dictionary = {}
var prime_frenzy_timer: float = 0.0
var prime_frenzy_interval: float = 0.0
var prime_frenzy_max_active: int = 18

var enemies: Array = []
var burrowers: Array = []
var towers: Array = []
var stars: Array = []
var effect_store: RefCounted
var tower_library: RefCounted
var wave_library: RefCounted
var selected_tower: String = "photon_splitter"
var managed_tower_ring: int = -1
var managed_tower_slot: int = -1
var pending_test_start_wave: int = 0
var prime_briefing_visible: bool = false
var prime_briefing_wave_data: Dictionary = {}

var game_hud: CanvasLayer
var tutorial_layer: CanvasLayer
var tutorial_overlay: Control
var textures: Dictionary = {
	"enemies": {},
	"enemy_animations": {},
	"towers": {},
}
var end_title_font: Font
var end_body_font: Font

var bgm_player: AudioStreamPlayer
var battle_background_texture: Texture2D
var current_bgm_path: String = ""
var ending_music_started: bool = false
var sfx_bus: Node
var gameplay_math: RefCounted
var orbit_math: RefCounted
var runtime_native: RefCounted

var view_controller: RefCounted
var sun_hit_timer: float = 0.0
var screen_shake_timer: float = 0.0
var screen_shake_strength: float = 0.0
var board_draw_translation: Vector2 = Vector2.ZERO
var board_draw_zoom: float = 1.0


func _ready() -> void:
	randomize()
	if ClassDB.class_exists("GameViewControllerNative"):
		view_controller = ClassDB.instantiate("GameViewControllerNative") as RefCounted
	else:
		push_error("GameViewControllerNative is missing. Rebuild the GDExtension before running gameplay.")
		set_process(false)
		return
	if ClassDB.class_exists("GameEffectStoreNative"):
		effect_store = ClassDB.instantiate("GameEffectStoreNative") as RefCounted
	else:
		push_error("GameEffectStoreNative is missing. Rebuild the GDExtension before running gameplay.")
		set_process(false)
		return
	if ClassDB.class_exists("GameTowerLibraryNative"):
		tower_library = ClassDB.instantiate("GameTowerLibraryNative") as RefCounted
	else:
		push_error("GameTowerLibraryNative is missing. Rebuild the GDExtension before running gameplay.")
		set_process(false)
		return
	if ClassDB.class_exists("GameWaveLibraryNative"):
		wave_library = ClassDB.instantiate("GameWaveLibraryNative") as RefCounted
	else:
		push_error("GameWaveLibraryNative is missing. Rebuild the GDExtension before running gameplay.")
		set_process(false)
		return
	if ClassDB.class_exists("V2GameplayMath"):
		gameplay_math = ClassDB.instantiate("V2GameplayMath") as RefCounted
	if ClassDB.class_exists("GameOrbitMathNative"):
		orbit_math = ClassDB.instantiate("GameOrbitMathNative") as RefCounted
	else:
		push_error("GameOrbitMathNative is missing. Rebuild the GDExtension before running gameplay.")
		set_process(false)
		return
	if ClassDB.class_exists("GameRuntimeNative"):
		runtime_native = ClassDB.instantiate("GameRuntimeNative") as RefCounted
	else:
		push_error("GameRuntimeNative is missing. Rebuild the GDExtension before running gameplay.")
		set_process(false)
		return
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	SpaceTheme.apply_cursor()
	GameState.reset_state()
	GameState.load_audio_settings()
	GameState.ensure_music_audible()
	if GameState.has_method("consume_test_start_wave"):
		pending_test_start_wave = int(GameState.call("consume_test_start_wave"))
		if pending_test_start_wave > 0:
			GameState.current_wave = clampi(pending_test_start_wave - 1, 0, MAX_WAVES - 1)
	MusicManager.stop_music()
	if not GameState.music_settings_changed.is_connected(_on_music_settings_changed):
		GameState.music_settings_changed.connect(_on_music_settings_changed)
	GameState.set_phase(GameState.BETWEEN_WAVE)
	_load_assets()
	_play_wave_music()
	_generate_starfield()
	_build_ui()
	_refresh_next_wave_preview()
	_update_ui()
	if pending_test_start_wave > 0:
		_set_message("Test mode armed: unlimited Sol Credits. Click Start Wave when ready.", 4.0)
		_update_ui()
	else:
		call_deferred("_maybe_show_tutorial")
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var viewport_changed: bool = _refresh_viewport_cache()
	var view_changed: bool = _process_edge_pan(delta)
	view_changed = _process_keyboard_pan(delta) or view_changed
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message_text = "Build anytime. Towers orbit and fire automatically."
			_update_ui()
	_process_wave_banner(delta)

	_process_music(delta)

	if GameState.game_phase == GameState.WAVE_ACTIVE:
		_process_spawning(delta)
		_process_wave_event(delta)
		_process_prime_frenzy(delta)

	_process_wave_modifiers(delta)
	_process_towers(delta)
	_process_enemies(delta)
	_process_burrowers(delta)
	_process_shots(delta)
	call("_process_physics_projectiles", delta)
	_process_visual_feedback(delta)
	_check_wave_clear()
	_process_auto_start(delta)
	if view_changed or _needs_frame_redraw(viewport_changed):
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if tutorial_overlay != null:
		return
	if prime_briefing_visible:
		if event is InputEventMouseButton:
			var briefing_mouse: InputEventMouseButton = event as InputEventMouseButton
			if briefing_mouse.pressed and briefing_mouse.button_index == MOUSE_BUTTON_LEFT:
				_confirm_prime_briefing()
				get_viewport().set_input_as_handled()
			return
		if event is InputEventKey:
			var briefing_key: InputEventKey = event as InputEventKey
			if briefing_key.pressed and not briefing_key.echo and (briefing_key.keycode == KEY_ENTER or briefing_key.keycode == KEY_KP_ENTER or briefing_key.keycode == KEY_SPACE):
				_confirm_prime_briefing()
				get_viewport().set_input_as_handled()
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
					_set_view_zoom(view_controller.zoom * VIEW_ZOOM_STEP, mouse_button.position)
					get_viewport().set_input_as_handled()
				return
			MOUSE_BUTTON_WHEEL_DOWN:
				if mouse_button.pressed:
					_set_view_zoom(view_controller.zoom / VIEW_ZOOM_STEP, mouse_button.position)
					get_viewport().set_input_as_handled()
				return
			MOUSE_BUTTON_RIGHT:
				if mouse_button.pressed and _try_slingshot_from_screen_position(mouse_button.position):
					get_viewport().set_input_as_handled()
					return
				view_controller.panning = mouse_button.pressed
				get_viewport().set_input_as_handled()
				return
			MOUSE_BUTTON_MIDDLE:
				view_controller.panning = mouse_button.pressed
				get_viewport().set_input_as_handled()
				return
			MOUSE_BUTTON_LEFT:
				if not mouse_button.pressed:
					return
				if not _can_build_towers():
					return
				if game_hud != null and bool(game_hud.call("is_screen_position_over_hud", mouse_button.position)):
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

	var click_pos: Vector2 = _screen_to_world(screen_position)
	var tower_index: int = _tower_index_at_world_position(click_pos)
	if tower_index != -1:
		_select_managed_tower_by_index(tower_index)
		return

	var slot: Dictionary = _nearest_ring_slot(click_pos)
	if slot.is_empty():
		_clear_managed_tower()
		_play_sfx("ui_intel_update", 0.12)
		_set_message("Select one of the visible orbital slots to build.", 2.0)
		return
	if bool(slot.get("occupied", false)):
		_select_managed_tower(int(slot["ring_index"]), int(slot["slot_index"]))
		return

	var cost: int = GameState.get_tower_cost(selected_tower)
	if not GameState.spend_credits(cost):
		_play_sfx("ui_insufficient_sol", 0.18)
		_show_insufficient_sol_feedback()
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


func _try_slingshot_from_screen_position(screen_position: Vector2) -> bool:
	if game_hud != null and bool(game_hud.call("is_screen_position_over_hud", screen_position)):
		return false
	var tower_index: int = _tower_index_at_world_position(_screen_to_world(screen_position))
	if tower_index == -1:
		return false
	var tower: Dictionary = towers[tower_index]
	if str(tower.get("type", "")) != "helios_cannon" or _tower_level(tower) < 2:
		return false
	if not GameState.spend_credits(SLINGSHOT_COST):
		_play_sfx("ui_insufficient_sol", 0.18)
		_show_insufficient_sol_feedback()
		_set_message("Need %d Sol Credits for Helios Slingshot Shot." % SLINGSHOT_COST, 2.0)
		_update_ui()
		return true

	var tower_pos: Vector2 = _tower_position(tower)
	_spawn_physics_projectile(tower, _sun_pos(), 160.0, "helios_cannon", true)
	_add_visual_effect("flare", tower_pos, Color(1.0, 0.58, 0.22), 0.42, 34.0)
	_add_text_effect("SLINGSHOT  -%d SOL" % SLINGSHOT_COST, tower_pos + Vector2(0.0, -42.0), Color(1.0, 0.84, 0.34, 0.98), 0.86)
	_play_sfx("slingshot_fire", 0.4)
	_set_message("Helios Slingshot fired. Gravity will bend it back inward.", 2.4)
	_update_ui()
	queue_redraw()
	return true


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
			if GameState.game_phase == GameState.GAME_OVER or GameState.game_phase == GameState.VICTORY:
				_on_retry_requested()
				return true
		KEY_M:
			if GameState.game_phase == GameState.GAME_OVER or GameState.game_phase == GameState.VICTORY:
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
	var tower_order: Array = tower_library.call("tower_order") as Array
	if index < 0 or index >= tower_order.size():
		return false
	var tower_type: String = str(tower_order[index])
	var cost: int = GameState.get_tower_cost(tower_type)
	if not _can_build_towers():
		return true
	if not GameState.can_afford(cost):
		_play_sfx("ui_insufficient_sol", 0.18)
		_show_insufficient_sol_feedback()
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

	board_draw_translation = _view_translation(viewport_size) + _screen_shake_offset()
	board_draw_zoom = view_controller.zoom
	draw_set_transform(board_draw_translation, 0.0, Vector2(board_draw_zoom, board_draw_zoom))
	_draw_orbit_rings(sun)
	_draw_wave_preview_paths(sun)
	_draw_build_preview()
	_draw_sun(sun)

	for shot in effect_store.shots:
		_draw_shot(shot)
	_draw_physics_projectiles()

	for tower in towers:
		_draw_tower(tower)

	for enemy in enemies:
		_draw_enemy(enemy)

	for burrower in burrowers:
		_draw_burrower(burrower)

	_draw_visual_effects()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_wave_banner(viewport_size)
	_draw_prime_briefing(viewport_size)
	if GameState.game_phase == GameState.GAME_OVER:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.0, 0.0, 0.0, 0.34), true)
	elif GameState.game_phase == GameState.VICTORY:
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
	var background_scale: float = max(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y) * 1.025 * breath
	var draw_size: Vector2 = texture_size * background_scale
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
		var flash: float = clampf(float(ring_flash_timers.get(i, 0.0)) / 0.42, 0.0, 1.0)
		if flash > 0.0:
			lane_color = lane_color.lerp(Color(1.0, 0.82, 0.24, 0.78), flash)
			glow_color = glow_color.lerp(Color(1.0, 0.72, 0.18, 0.28), flash)
			accent_color = accent_color.lerp(Color(1.0, 0.92, 0.44, 0.68), flash)

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


func _draw_wave_preview_paths(sun: Vector2) -> void:
	if wave_preview_points.is_empty() or GameState.game_phase != GameState.BETWEEN_WAVE:
		return

	var time_seconds: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.55 + sin(time_seconds * 2.2) * 0.18
	for i in range(wave_preview_points.size()):
		var spawn_pos: Vector2 = wave_preview_points[i]
		var alpha: float = clampf((0.16 + float(i % 4) * 0.018) * pulse, 0.08, 0.32)
		var color: Color = Color(1.0, 0.36, 0.16, alpha)
		draw_line(spawn_pos, sun, Color(0.0, 0.0, 0.0, alpha * 0.62), 3.4)
		draw_line(spawn_pos, sun, color, 1.4)
		draw_circle(spawn_pos, 5.4, Color(1.0, 0.52, 0.22, alpha * 1.25))
		var marker: Vector2 = spawn_pos.lerp(sun, 0.12 + fmod(time_seconds * 0.12 + float(i) * 0.07, 0.22))
		draw_circle(marker, 2.4, Color(1.0, 0.88, 0.42, alpha * 1.35))


func _draw_physics_projectiles() -> void:
	for projectile in physics_projectiles:
		var pos: Vector2 = projectile.get("pos", Vector2.ZERO)
		var velocity: Vector2 = projectile.get("velocity", Vector2.ZERO)
		var color: Color = projectile.get("color", Color(1.0, 0.58, 0.24))
		var trail: Array = projectile.get("trail", [])
		for i in range(max(0, trail.size() - 1)):
			var t: float = float(i + 1) / float(max(1, trail.size()))
			var a: float = 0.08 + t * 0.22
			draw_line(trail[i], trail[i + 1], Color(color.r, color.g, color.b, a), 2.0 + t * 1.8)
		var angle: float = velocity.angle() if velocity.length_squared() > 0.001 else 0.0
		var nose: Vector2 = pos + Vector2(cos(angle), sin(angle)) * 9.0
		var side_a: Vector2 = pos + Vector2(cos(angle + 2.45), sin(angle + 2.45)) * 7.0
		var side_b: Vector2 = pos + Vector2(cos(angle - 2.45), sin(angle - 2.45)) * 7.0
		draw_circle(pos, 10.5, Color(0.0, 0.0, 0.0, 0.42))
		draw_circle(pos, 7.4, Color(color.r, color.g, color.b, 0.28))
		draw_polygon(PackedVector2Array([nose, side_a, side_b]), PackedColorArray([
			Color(1.0, 0.94, 0.64, 0.96),
			Color(color.r, color.g, color.b, 0.78),
			Color(color.r, color.g, color.b, 0.72),
		]))


func _draw_wave_banner(viewport_size: Vector2) -> void:
	if wave_banner_timer <= 0.0 or wave_banner_text == "":
		return

	var appear: float = clampf(wave_banner_timer / 0.35, 0.0, 1.0)
	var alpha: float = clampf(appear, 0.0, 1.0)
	var width: float = minf(viewport_size.x - 48.0, 640.0)
	var height: float = 72.0
	var hud_clearance: float = 146.0 if viewport_size.x >= 1280.0 else 320.0
	var safe_bottom: float = maxf(72.0, viewport_size.y - 236.0)
	var banner_y: float = minf(maxf(hud_clearance, viewport_size.y * 0.16), safe_bottom)
	var rect: Rect2 = Rect2(Vector2((viewport_size.x - width) * 0.5, banner_y), Vector2(width, height))
	var accent: Color = wave_banner_accent

	draw_rect(rect.grow(4.0), Color(0.0, 0.0, 0.0, 0.38 * alpha), true)
	draw_rect(rect, Color(0.004, 0.012, 0.022, 0.88 * alpha), true)
	draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.78 * alpha), false, 2.0)
	draw_line(
		rect.position + Vector2(18.0, rect.size.y - 8.0),
		rect.position + Vector2(rect.size.x - 18.0, rect.size.y - 8.0),
		Color(accent.r, accent.g, accent.b, 0.34 * alpha),
		1.4
	)

	if end_title_font != null:
		draw_string(
			end_title_font,
			rect.position + Vector2(0.0, 30.0),
			wave_banner_text.to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			19,
			Color(accent.r, accent.g, accent.b, alpha)
		)
	if end_body_font != null and wave_banner_subtitle != "":
		draw_string(
			end_body_font,
			rect.position + Vector2(0.0, 52.0),
			wave_banner_subtitle,
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			13,
			Color(0.90, 0.96, 1.0, 0.90 * alpha)
		)


func _draw_prime_briefing(viewport_size: Vector2) -> void:
	if not prime_briefing_visible:
		return
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.0, 0.0, 0.0, 0.48), true)
	var width: float = minf(viewport_size.x - 48.0, 760.0)
	var height: float = 330.0
	var rect: Rect2 = Rect2((viewport_size - Vector2(width, height)) * 0.5, Vector2(width, height))
	var accent: Color = Color(1.0, 0.20, 0.10, 0.96)

	draw_rect(rect.grow(6.0), Color(0.0, 0.0, 0.0, 0.55), true)
	draw_rect(rect, Color(0.004, 0.012, 0.022, 0.96), true)
	draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.84), false, 2.0)
	draw_line(rect.position + Vector2(22.0, 58.0), rect.position + Vector2(rect.size.x - 22.0, 58.0), Color(1.0, 0.78, 0.24, 0.55), 1.5)
	if end_title_font != null:
		draw_string(end_title_font, rect.position + Vector2(0.0, 38.0), "ASTROPHAGE PRIME IS COMING", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 21, Color(1.0, 0.78, 0.24, 1.0))
	if end_body_font == null:
		return
	var lines: Array[String] = [
		"SHELL: Armored carapace ignores normal fire. Use Bio-Lab to crack it open.",
		"ACTIVE: Exposed Prime takes full damage. Stack Helios, Tardigrade, slows, and focused fire.",
		"FRENZY: At low health it accelerates, changes form, and spawns Drifters until destroyed.",
		"Build before you press Start. Click, Space, or Enter to begin Wave 12."
	]
	var y: float = rect.position.y + 96.0
	for i in range(lines.size()):
		var color: Color = Color(0.90, 0.96, 1.0, 0.94)
		if i == 0:
			color = Color(1.0, 0.54, 0.36, 0.96)
		elif i == 1:
			color = Color(0.56, 1.0, 0.62, 0.96)
		elif i == 2:
			color = Color(1.0, 0.22, 0.16, 0.96)
		draw_string(end_body_font, rect.position + Vector2(42.0, y), lines[i], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 84.0, 15, color)
		y += 48.0
	var button_rect: Rect2 = Rect2(Vector2(rect.position.x + rect.size.x * 0.5 - 110.0, rect.position.y + rect.size.y - 58.0), Vector2(220.0, 38.0))
	draw_rect(button_rect, Color(0.020, 0.052, 0.078, 0.96), true)
	draw_rect(button_rect, Color(1.0, 0.78, 0.24, 0.82), false, 1.5)
	draw_string(end_title_font, button_rect.position + Vector2(0.0, 25.0), "BEGIN PRIME WAVE", HORIZONTAL_ALIGNMENT_CENTER, button_rect.size.x, 12, Color(0.96, 0.99, 1.0, 1.0))


func _load_assets() -> void:
	battle_background_texture = load(BATTLE_BACKGROUND_PATH) as Texture2D
	end_title_font = load(END_TITLE_FONT_PATH) as Font
	end_body_font = load(END_BODY_FONT_PATH) as Font
	for key in ENEMY_ASSET_PATHS.keys():
		textures["enemies"][key] = _load_png_texture(str(ENEMY_ASSET_PATHS[key]))
	_load_enemy_animation_assets()
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


func _load_enemy_animation_assets() -> void:
	var animation_store: Dictionary = textures.get("enemy_animations", {})
	animation_store.clear()

	for variant_key in ENEMY_ANIMATION_PATHS.keys():
		var state_paths: Dictionary = ENEMY_ANIMATION_PATHS[variant_key]
		var state_frames: Dictionary = {}
		for state_key in state_paths.keys():
			var frames: Array = []
			for path in state_paths[state_key]:
				var frame_texture = _load_png_texture(str(path))
				if frame_texture:
					frames.append(frame_texture)
			if not frames.is_empty():
				state_frames[state_key] = frames
		if not state_frames.is_empty():
			animation_store[variant_key] = state_frames

	textures["enemy_animations"] = animation_store


func _load_png_texture(path: String):
	var resource = load(path)
	if resource is Texture2D:
		return resource

	var image := Image.new()
	var error: int = image.load(path)
	if error == OK and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null


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


func _process_wave_banner(delta: float) -> void:
	if wave_banner_timer <= 0.0:
		return
	wave_banner_timer = maxf(wave_banner_timer - delta, 0.0)


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

	if not ClassDB.class_exists("GameSfxBusNative"):
		push_error("GameSfxBusNative is missing. Rebuild the GDExtension before running gameplay.")
		return
	sfx_bus = ClassDB.instantiate("GameSfxBusNative") as Node
	if sfx_bus == null:
		return
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
	return str(runtime_native.call("bgm_path_for_wave", wave_number, WAVE_EARLY_BGM_PATH, WAVE_MID_BGM_PATH, WAVE_LATE_BGM_PATH, BOSS_BGM_PATH))


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
	if GameState.game_phase == GameState.BETWEEN_WAVE:
		return true
	if GameState.game_phase == GameState.WAVE_ACTIVE:
		return true
	if GameState.game_phase == GameState.GAME_OVER or GameState.game_phase == GameState.VICTORY:
		return true
	if not towers.is_empty() or not enemies.is_empty() or not effect_store.shots.is_empty() or not burrowers.is_empty():
		return true
	if not physics_projectiles.is_empty() or not wave_preview_points.is_empty() or not ring_flash_timers.is_empty():
		return true
	if wave_banner_timer > 0.0:
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
	var hud_blocks_mouse: bool = game_hud != null and bool(game_hud.call("is_screen_position_over_hud", mouse_position))
	return view_controller.process_edge_pan(delta, viewport_rect, mouse_position, hud_blocks_mouse, _outer_ring_radius())


func _process_keyboard_pan(delta: float) -> bool:
	if tutorial_overlay != null:
		return false
	return view_controller.process_keyboard_pan(delta, get_viewport_rect().size, _outer_ring_radius())


func _build_ui() -> void:
	var layer: CanvasLayer = get_node_or_null("GameHudLayer") as CanvasLayer
	if layer == null:
		var hud_scene: PackedScene = load(GAME_HUD_SCENE_PATH) as PackedScene
		if hud_scene != null:
			layer = hud_scene.instantiate() as CanvasLayer
			add_child(layer)

	if layer == null:
		push_error("Game: could not find or instantiate GameHudLayer.")
		return

	game_hud = layer
	var hud_connections: Dictionary = {
		"start_wave_requested": Callable(self, "_on_start_wave_pressed"),
		"auto_start_toggled": Callable(self, "_on_auto_start_toggled"),
		"menu_requested": Callable(self, "_on_menu_pressed"),
		"tower_selected": Callable(self, "_select_tower"),
		"tower_upgrade_requested": Callable(self, "_on_tower_upgrade_requested"),
		"tower_sell_requested": Callable(self, "_on_tower_sell_requested"),
		"tower_manage_closed": Callable(self, "_on_tower_manage_closed"),
		"recenter_requested": Callable(self, "_reset_view"),
		"retry_requested": Callable(self, "_on_retry_requested"),
		"main_menu_requested": Callable(self, "_on_end_main_menu_requested"),
		"ui_hovered": Callable(self, "_on_ui_hovered"),
	}
	for signal_name in hud_connections:
		var callback: Callable = hud_connections[signal_name]
		if game_hud.has_signal(signal_name) and not game_hud.is_connected(signal_name, callback):
			game_hud.connect(signal_name, callback)


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

	tutorial_overlay = ClassDB.instantiate("TutorialOverlayNative") as Control
	if tutorial_overlay == null:
		tutorial_layer.queue_free()
		tutorial_layer = null
		return
	tutorial_overlay.name = "TutorialOverlay"
	tutorial_overlay.call("set_target_provider", Callable(self, "_tutorial_targets"))
	tutorial_overlay.connect("tutorial_finished", Callable(self, "_on_tutorial_finished"))
	tutorial_overlay.connect("tutorial_skipped", Callable(self, "_on_tutorial_skipped"))
	tutorial_layer.add_child(tutorial_overlay)
	_set_message("Mission training overlay opened. Skip or finish to save it as complete.", 3.0)
	_play_sfx("ui_mission_text", 0.4)


func _on_tutorial_finished() -> void:
	GameState.set_tutorial_completed(true)
	_clear_tutorial_overlay()
	_set_message("Mission training complete. It will not replay automatically.", 3.0)
	_play_sfx("ui_mission_text", 0.4)


func _on_tutorial_skipped() -> void:
	GameState.set_tutorial_completed(true)
	_clear_tutorial_overlay()
	_set_message("Mission training skipped. It will not replay automatically.", 3.0)
	_play_sfx("ui_mission_text", 0.4)


func _clear_tutorial_overlay() -> void:
	if tutorial_layer != null:
		tutorial_layer.queue_free()
	tutorial_layer = null
	tutorial_overlay = null


func _tutorial_targets() -> Dictionary:
	var targets: Dictionary = {}
	if game_hud != null:
		var hud_targets: Dictionary = game_hud.call("get_tutorial_targets") as Dictionary
		targets.merge(hud_targets, true)

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
	if GameState.game_phase != GameState.BETWEEN_WAVE:
		return
	_clear_auto_start_timer(false)

	var wave_number: int = GameState.current_wave + 1
	if wave_number > playable_wave_limit:
		_set_message("Wave %d is locked for this scene." % wave_number, 3.0)
		return
	if wave_number > MAX_WAVES:
		return

	current_wave_data = _wave_load(wave_number)
	if current_wave_data.is_empty():
		_play_sfx("ui_insufficient_sol", 0.18)
		_set_message("Could not load wave_%02d.json." % wave_number, 3.0)
		return

	if wave_number == 12 and not prime_briefing_visible and prime_briefing_wave_data.is_empty():
		prime_briefing_visible = true
		prime_briefing_wave_data = current_wave_data
		_show_wave_banner("ASTROPHAGE PRIME IS COMING", "Read the phase briefing before committing.", Color(1.0, 0.14, 0.08), 4.0)
		_set_message("Prime briefing open. Click, Space, or Enter to begin Wave 12.", 4.0)
		_play_sfx("clash_incoming", 1.0)
		_update_ui()
		queue_redraw()
		return

	_begin_wave(wave_number, current_wave_data)


func _confirm_prime_briefing() -> void:
	if not prime_briefing_visible:
		return
	prime_briefing_visible = false
	var wave_data: Dictionary = prime_briefing_wave_data
	prime_briefing_wave_data = {}
	if wave_data.is_empty():
		wave_data = _wave_load(12)
	_begin_wave(12, wave_data)


func _begin_wave(wave_number: int, wave_data: Dictionary) -> void:
	if wave_data.is_empty():
		return
	current_wave_data = wave_data
	GameState.current_wave = wave_number
	GameState.set_phase(GameState.WAVE_ACTIVE)
	_clear_wave_preview()
	_start_wave_spawning(current_wave_data)
	wave_active = true
	wave_start_time = Time.get_ticks_msec() / 1000.0
	escalation_checked = false
	counter_attack_active = false
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


func _on_ui_hovered() -> void:
	_play_sfx("ui_hover", 0.05)


func _show_insufficient_sol_feedback() -> void:
	if game_hud != null and game_hud.has_method("play_insufficient_sol_feedback"):
		game_hud.call("play_insufficient_sol_feedback")


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
	if level >= int(tower_library.call("max_level")):
		_set_message("%s is already at maximum calibration." % _tower_config(str(tower["type"]))["label"], 1.8)
		return

	var upgrade_cost: int = _tower_upgrade_cost(tower)
	if not GameState.spend_credits(upgrade_cost):
		_play_sfx("ui_insufficient_sol", 0.18)
		_show_insufficient_sol_feedback()
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
	if prime_frenzy_interval <= 0.0:
		return
	if enemies.size() >= prime_frenzy_max_active:
		return

	var spawned: bool = false
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		if str(enemy.get("variant", "")) != "prime" or int(enemy.get("prime_phase", 0)) < 2:
			continue
		enemy["frenzy_timer"] = float(enemy.get("frenzy_timer", prime_frenzy_interval)) - delta
		if float(enemy["frenzy_timer"]) <= 0.0:
			enemy["frenzy_timer"] = prime_frenzy_interval
			var pos: Vector2 = enemy.get("pos", _sun_pos())
			for _offset_index in range(2):
				if enemies.size() >= prime_frenzy_max_active:
					break
				var offset: Vector2 = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(24.0, 48.0)
				_spawn_enemy("drifter", pos + offset)
			spawned = true
		enemies[i] = enemy
	if spawned:
		_update_ui()


func _wave_progress_ratio() -> float:
	if total_wave_spawn_count <= 0:
		return 1.0
	return clamp(float(spawned_wave_count) / float(total_wave_spawn_count), 0.0, 1.0)


func _try_manual_flare() -> void:
	if GameState.game_phase != GameState.WAVE_ACTIVE:
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


func _start_wave_spawning(wave_data: Dictionary) -> void:
	spawn_queue.clear()
	clash_schedule.clear()
	spawned_wave_count = 0
	total_wave_spawn_count = _wave_total_spawn_count(wave_data)
	spawn_timer = 0.35

	match str(wave_data.get("wave_type", "normal")):
		"clash", "boss":
			_schedule_clash_groups(wave_data.get("clash_groups", []))
			var accent: Color = Color(1.0, 0.30, 0.12) if str(wave_data.get("wave_type", "normal")) == "clash" else Color(1.0, 0.14, 0.12)
			_show_wave_banner(_wave_preview_label(wave_data), str(wave_data.get("name", "Wave incoming")), accent, 4.2)
			_play_sfx("clash_incoming", 1.0)
		"formation":
			spawn_queue = _wave_build_spawn_queue(wave_data)
			_schedule_formation_group(wave_data.get("formation", {}))
			_show_wave_banner(_wave_preview_label(wave_data), str(wave_data.get("name", "Wave incoming")), Color(0.42, 0.90, 1.0), 3.4)
		_:
			spawn_queue = _wave_build_spawn_queue(wave_data)


func _schedule_clash_groups(groups) -> void:
	for raw_group in _wave_array_value(groups):
		if not (raw_group is Dictionary):
			continue
		var variants: Array = _wave_array_value(raw_group.get("variants", []))
		if variants.is_empty():
			continue
		clash_schedule.append({
			"timer": maxf(float(raw_group.get("delay_before", 0.0)), 0.0),
			"variants": variants.duplicate(),
			"pattern": str(raw_group.get("spawn_pattern", "random")),
			"options": raw_group,
		})


func _schedule_formation_group(formation) -> void:
	if not (formation is Dictionary) or formation.is_empty():
		return
	var count: int = max(0, int(formation.get("count", 0)))
	var variants_source: Array = _wave_array_value(formation.get("variants", ["drifter"]))
	if count <= 0 or variants_source.is_empty():
		return
	var variants: Array = []
	for i in range(count):
		variants.append(str(variants_source[i % variants_source.size()]))
	clash_schedule.append({
		"timer": 2.0,
		"variants": variants,
		"pattern": str(formation.get("type", "ring")),
		"options": formation,
	})


func _process_spawning(delta: float) -> void:
	_process_clash_schedule(delta)

	spawn_timer -= delta
	while spawn_timer <= 0.0 and not spawn_queue.is_empty():
		var spawn_info: Dictionary = spawn_queue.pop_front()
		spawned_wave_count += 1
		_spawn_enemy(str(spawn_info.get("variant", "drifter")))
		spawn_timer += float(spawn_info.get("interval", 2.0))
		_update_ui()


func _process_clash_schedule(delta: float) -> void:
	if clash_schedule.is_empty():
		return

	var pending: Array = []
	for raw_group in clash_schedule:
		var group: Dictionary = raw_group
		group["timer"] = float(group.get("timer", 0.0)) - delta
		if float(group["timer"]) <= 0.0:
			_spawn_clash_group(
				_wave_array_value(group.get("variants", [])),
				str(group.get("pattern", "random")),
				group.get("options", {})
			)
		else:
			pending.append(group)
	clash_schedule = pending


func _spawn_clash_group(variants: Array, pattern: String, options = {}) -> void:
	if variants.is_empty():
		return
	var group_options: Dictionary = options if options is Dictionary else {}
	for i in range(variants.size()):
		var spawn_pos: Vector2 = _spawn_position_for_pattern(pattern, i, variants.size(), group_options)
		_spawn_enemy(str(variants[i]), spawn_pos)
	spawned_wave_count += variants.size()
	_play_sfx("clash_incoming", 0.8)
	_update_ui()


func _spawn_position_for_pattern(pattern: String, index: int, count: int, options: Dictionary = {}) -> Vector2:
	var sun: Vector2 = _sun_pos()
	var spawn_radius: float = _outer_ring_radius() + ENEMY_SPAWN_PADDING
	if gameplay_math != null:
		var cpp_pos = gameplay_math.call("spawn_position_for_pattern", pattern, index, count, sun, spawn_radius, options)
		if cpp_pos is Vector2:
			return cpp_pos
	var safe_count: int = max(1, count)
	var normalized_pattern: String = pattern.strip_edges().to_lower()

	match normalized_pattern:
		"ring":
			var angle: float = (float(index) / float(safe_count)) * TAU
			return sun + Vector2(cos(angle), sin(angle)) * spawn_radius
		"v_shape":
			var half: int = max(1, int(ceil(float(safe_count) * 0.5)))
			var side: float = 1.0 if index < half else -1.0
			var local_index: int = index if index < half else index - half
			var spread: float = deg_to_rad(float(options.get("spread_angle_deg", 60.0)))
			var angle: float = -PI * 0.5 + side * (float(local_index + 1) / float(half + 1)) * spread
			return sun + Vector2(cos(angle), sin(angle)) * spawn_radius
		"spiral":
			var arms: int = max(1, int(options.get("spiral_arms", 1)))
			var arm_offset: float = TAU * float(index % arms) / float(arms)
			var turns: float = 1.5 + float(arms) * 0.35
			var angle: float = arm_offset + (float(index) / float(safe_count)) * TAU * turns
			var radius: float = spawn_radius * (0.72 + 0.28 * float(index + 1) / float(safe_count))
			return sun + Vector2(cos(angle), sin(angle)) * radius
		"center_top":
			return sun + Vector2(0.0, -spawn_radius)
		_:
			var angle: float = randf() * TAU
			return sun + Vector2(cos(angle), sin(angle)) * spawn_radius


func _process_towers(delta: float) -> void:
	for i in range(towers.size()):
		var tower: Dictionary = towers[i]
		var ring: Dictionary = RINGS[int(tower["ring"])]
		tower["angle"] = wrapf(float(tower["angle"]) + TAU / float(ring["period"]) * delta, 0.0, TAU)
		tower["fire_timer"] = max(float(tower["fire_timer"]) - delta, 0.0)

		if _is_tower_disabled(tower):
			towers[i] = tower
			continue

		if GameState.game_phase == GameState.WAVE_ACTIVE and float(tower["fire_timer"]) <= 0.0:
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
			var move_direction: Vector2 = to_sun.normalized()
			var move_angle: float = move_direction.angle()
			var current_angle: float = float(enemy.get("sprite_angle", move_angle))
			var velocity: Vector2 = enemy.get("velocity", move_direction * float(enemy["speed"]))
			var mass: float = maxf(float(enemy.get("mass", ENEMY_MASSES.get(str(enemy["variant"]), 1.0))), 0.2)
			if gameplay_math != null:
				var step = gameplay_math.call(
					"integrate_enemy_gravity",
					pos,
					velocity,
					sun,
					float(enemy["speed"]),
					float(enemy.get("max_speed", float(enemy["speed"]) * 2.25)),
					mass,
					delta,
					speed_multiplier
				)
				if step is Dictionary:
					velocity = step.get("velocity", velocity)
					pos = step.get("pos", pos)
					move_angle = float(step.get("move_angle", move_angle))
			else:
				var accel_mag: float = minf(ENEMY_GRAVITY_CONST / maxf(dist * dist * mass, 1200.0), ENEMY_GRAVITY_ACCEL_CAP)
				velocity += move_direction * accel_mag * delta
				velocity += move_direction * float(enemy["speed"]) * 0.18 * delta
				var terminal_speed: float = float(enemy.get("max_speed", float(enemy["speed"]) * 2.25)) * speed_multiplier
				var velocity_speed: float = velocity.length()
				if velocity_speed > terminal_speed and velocity_speed > 0.001:
					velocity = velocity / velocity_speed * terminal_speed
				pos += velocity * delta
			enemy["move_angle"] = move_angle
			enemy["sprite_angle"] = lerp_angle(current_angle, move_angle, clampf(delta * 12.0, 0.0, 1.0))
			enemy["velocity"] = velocity
			enemy["pos"] = pos
		survivors.append(enemy)

	enemies = survivors
	if reached_sun and direct_breach:
		_register_sun_hit()
		_set_message("The corona was breached. Luminosity is falling.", 2.0)
		_update_ui()

	if GameState.game_phase == GameState.GAME_OVER:
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

	if GameState.game_phase == GameState.GAME_OVER:
		wave_active = false
		spawn_queue.clear()
		_play_sfx("failure", 6.0)
		_play_ending_music()
		_set_message("Game over. The Sun was hollowed out from within.", 999.0)
		_update_ui()


func _process_shots(delta: float) -> void:
	effect_store.process_shots(delta)


func _process_physics_projectiles(delta: float) -> void:
	if physics_projectiles.is_empty():
		return

	var active_projectiles: Array = []
	var ring_radii: Array = []
	for i in range(RINGS.size()):
		ring_radii.append(_ring_radius(i))

	for projectile in physics_projectiles:
		var p: Dictionary = projectile
		p["lifetime"] = float(p.get("lifetime", 0.0)) + delta
		if float(p["lifetime"]) > PHYSICS_PROJECTILE_MAX_LIFETIME:
			continue

		var pos: Vector2 = p.get("pos", Vector2.ZERO)
		var previous_pos: Vector2 = pos
		var velocity: Vector2 = p.get("velocity", Vector2.ZERO)
		var damage: float = float(p.get("damage", 0.0))
		var last_dist: float = float(p.get("last_dist", pos.distance_to(_sun_pos())))
		if gameplay_math != null:
			var step = gameplay_math.call("integrate_projectile", pos, velocity, _sun_pos(), damage, last_dist, ring_radii, delta)
			if step is Dictionary:
				pos = step.get("pos", pos)
				velocity = step.get("velocity", velocity)
				damage = float(step.get("damage", damage))
				last_dist = float(step.get("last_dist", pos.distance_to(_sun_pos())))
				var crossed_ring: int = int(step.get("crossed_ring", -1))
				if crossed_ring >= 0:
					ring_flash_timers[crossed_ring] = 0.42
		else:
			var to_sun: Vector2 = _sun_pos() - pos
			var dist: float = maxf(to_sun.length(), 0.001)
			var accel: float = minf(PHYSICS_PROJECTILE_GRAVITY_CONST / maxf(dist * dist, 100.0), 620.0)
			velocity += to_sun.normalized() * accel * delta
			for ring_index in range(ring_radii.size()):
				var radius: float = float(ring_radii[ring_index])
				if last_dist > radius and dist <= radius:
					damage *= PHYSICS_PROJECTILE_DAMAGE_RING_MULT
					ring_flash_timers[ring_index] = 0.42
				elif last_dist < radius and dist >= radius and velocity.length_squared() > 0.001:
					velocity += Vector2(-velocity.y, velocity.x).normalized() * velocity.length() * PHYSICS_PROJECTILE_OUTWARD_DEFLECT
			last_dist = dist
			pos += velocity * delta

		if pos.distance_to(_sun_pos()) <= SUN_DAMAGE_RADIUS * 0.7:
			_add_visual_effect("shield", pos, p.get("color", Color(1.0, 0.58, 0.24)), 0.24, 18.0)
			continue

		var hit_index: int = int(runtime_native.call("physics_projectile_hit_index", enemies, pos, previous_pos, PHYSICS_PROJECTILE_HIT_RADIUS))
		if hit_index == -1:
			var target_uid: int = int(p.get("target_uid", -1))
			var target_index: int = int(runtime_native.call("enemy_index_by_uid", enemies, target_uid))
			if target_index != -1:
				var target_enemy: Dictionary = enemies[target_index]
				var target_pos: Vector2 = target_enemy.get("pos", p.get("target_pos", pos))
				var target_radius: float = maxf(PHYSICS_PROJECTILE_HIT_RADIUS, float(target_enemy.get("radius", PHYSICS_PROJECTILE_HIT_RADIUS)) * 1.25)
				if bool(runtime_native.call("projectile_segment_hits_point", previous_pos, pos, target_pos, target_radius)):
					hit_index = target_index
		if hit_index != -1:
			_add_visual_effect("hit", pos, p.get("color", Color(1.0, 0.58, 0.24)), 0.22, 22.0)
			_damage_enemy(hit_index, damage, str(p.get("tower_type", "helios_cannon")))
			continue

		p["pos"] = pos
		p["velocity"] = velocity
		p["damage"] = damage
		p["last_dist"] = last_dist
		var trail: Array = p.get("trail", [])
		trail.append(pos)
		while trail.size() > 12:
			trail.pop_front()
		p["trail"] = trail
		active_projectiles.append(p)

	physics_projectiles = active_projectiles


func _process_visual_feedback(delta: float) -> void:
	sun_hit_timer = maxf(sun_hit_timer - delta, 0.0)
	screen_shake_timer = maxf(screen_shake_timer - delta, 0.0)
	if screen_shake_timer <= 0.0:
		screen_shake_strength = 0.0

	var expired_rings: Array = []
	for ring_index in ring_flash_timers.keys():
		var remaining: float = float(ring_flash_timers[ring_index]) - delta
		if remaining <= 0.0:
			expired_rings.append(ring_index)
		else:
			ring_flash_timers[ring_index] = remaining
	for ring_index in expired_rings:
		ring_flash_timers.erase(ring_index)

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
	if GameState.game_phase != GameState.BETWEEN_WAVE:
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
	if GameState.game_phase != GameState.WAVE_ACTIVE:
		return
	if not spawn_queue.is_empty() or not clash_schedule.is_empty() or not enemies.is_empty() or not burrowers.is_empty():
		return
	if _try_launch_counter_attack():
		return

	wave_active = false
	counter_attack_active = false
	_end_wave_event()
	var reward: int = int(current_wave_data.get("credit_reward", 0))
	GameState.add_credits(reward)
	GameState.on_wave_cleared()
	if reward > 0:
		_add_text_effect("+%d SOL WAVE CLEAR" % reward, _sun_pos() + Vector2(0.0, -_outer_ring_radius() - 52.0), Color(1.0, 0.86, 0.34, 0.98), 0.95)

	if GameState.current_wave >= playable_wave_limit and playable_wave_limit < MAX_WAVES:
		_play_sfx("wave_clear")
		GameState.set_phase(GameState.BETWEEN_WAVE)
		_refresh_next_wave_preview()
		_show_next_wave_banner()
		_set_message("Wave %d cleared. Additional waves are locked for this scene." % GameState.current_wave, 999.0)
	elif GameState.current_wave >= MAX_WAVES:
		GameState.trigger_victory()
		_play_sfx("victory")
		_play_ending_music()
		_set_message("Victory. Final rank: %s." % GameState.get_rank(), 999.0)
	else:
		_play_sfx("wave_clear")
		GameState.set_phase(GameState.BETWEEN_WAVE)
		_refresh_next_wave_preview()
		_show_next_wave_banner()
		_set_message("Wave %d cleared. Corps reward: %d Sol Credits." % [GameState.current_wave, reward], 4.0)
	_update_ui()


func _try_launch_counter_attack() -> bool:
	if counter_attack_active or escalation_checked:
		return false
	escalation_checked = true

	var threshold_value = current_wave_data.get("escalation_threshold_seconds", null)
	if threshold_value == null:
		return false
	var threshold: float = float(threshold_value)
	if threshold <= 0.0:
		return false

	var elapsed: float = Time.get_ticks_msec() / 1000.0 - wave_start_time
	if elapsed >= threshold:
		return false

	var retaliation_type: String = "drifter"
	var highest_count: int = 0
	for entry in current_wave_data.get("spawns", []):
		if not (entry is Dictionary):
			continue
		var variant: String = _wave_variant_key(entry.get("variant", "drifter"))
		var count: int = int(entry.get("count", 0))
		if variant != "drifter" and count > highest_count:
			retaliation_type = variant
			highest_count = count

	var counter_variants: Array = [
		"drifter", "drifter", "drifter", "drifter", "drifter", "drifter",
		retaliation_type, retaliation_type,
	]
	counter_attack_active = true
	wave_active = true
	total_wave_spawn_count += counter_variants.size()
	clash_schedule.append({
		"timer": 1.2,
		"variants": counter_variants,
		"pattern": "ring",
		"options": {},
	})
	_show_wave_banner("Counter-attack!", "Too fast - the swarm retaliates.", Color(1.0, 0.40, 0.05), 3.0)
	_play_sfx("counter_attack", 1.0)
	_set_message("Fast clear detected. Counter-attack incoming.", 3.0)
	_update_ui()
	return true


func _show_next_wave_banner() -> void:
	var next_wave: int = GameState.current_wave + 1
	if next_wave > MAX_WAVES or next_wave > playable_wave_limit:
		return
	var next_data: Dictionary = _wave_load(next_wave)
	if next_data.is_empty():
		return
	var accent: Color = Color(1.0, 0.86, 0.34)
	match str(next_data.get("wave_type", "normal")):
		"clash":
			accent = Color(1.0, 0.32, 0.12)
		"boss":
			accent = Color(1.0, 0.12, 0.12)
		"formation":
			accent = Color(0.42, 0.90, 1.0)
	_show_wave_banner(_wave_preview_label(next_data), str(next_data.get("name", "Next Wave")), accent, 4.0)


func _show_wave_banner(title: String, subtitle: String, accent: Color, duration: float = 4.0) -> void:
	wave_banner_text = title
	wave_banner_subtitle = subtitle
	wave_banner_accent = accent
	wave_banner_timer = duration
	queue_redraw()


func _spawn_enemy(variant: String, spawn_pos = null) -> void:
	var key: String = _wave_variant_key(variant)
	var cfg: Dictionary = _enemy_config(key)
	var sun: Vector2 = _sun_pos()
	var angle: float = randf() * TAU
	var distance: float = _outer_ring_radius() + ENEMY_SPAWN_PADDING
	var pos: Vector2 = sun + Vector2(cos(angle), sin(angle)) * distance
	if spawn_pos is Vector2:
		pos = spawn_pos
	var move_angle: float = (sun - pos).angle()
	var initial_direction: Vector2 = (sun - pos).normalized() if sun.distance_squared_to(pos) > 0.001 else Vector2.ZERO
	var mass: float = float(ENEMY_MASSES.get(key, 1.0))
	if gameplay_math != null:
		mass = float(gameplay_math.call("get_enemy_mass", key))
	var base_speed: float = float(cfg["speed"])

	var enemy_uid: int = next_enemy_uid
	next_enemy_uid += 1
	enemies.append({
		"uid": enemy_uid,
		"variant": key,
		"variant_id": cfg["variant_id"],
		"label": cfg["label"],
		"pos": pos,
		"hp": cfg["hp"],
		"max_hp": cfg["hp"],
		"speed": base_speed,
		"velocity": initial_direction * base_speed * 0.62,
		"mass": mass,
		"max_speed": base_speed * (2.25 if key != "prime" else 1.65),
		"damage": cfg["damage"],
		"reward": cfg["reward"],
		"radius": cfg["radius"],
		"draw_size": cfg["draw_size"],
		"color": cfg["color"],
		"slow_timer": 0.0,
		"hit_timer": 0.0,
		"heal_timer": 0.0,
		"anim_offset": randf() * 10.0,
		"move_angle": move_angle,
		"sprite_angle": move_angle,
		"frenzy_timer": 1.5,
		"prime_phase": 0,
	})
	if key == "prime":
		_show_wave_banner("ASTROPHAGE PRIME IS COMING", "Shell locked. Bio-Lab must crack the carapace.", Color(1.0, 0.12, 0.08), 5.0)
		_set_message("Astrophage Prime has entered the field. Break the shell with Bio-Lab.", 5.0)
		_play_sfx("clash_incoming", 1.0)
		_update_ui()


func _find_target_for_tower(tower: Dictionary) -> int:
	var tower_pos: Vector2 = _tower_position(tower)
	var sun: Vector2 = _sun_pos()
	var stats: Dictionary = _tower_runtime_stats(tower)
	var tower_range: float = float(stats["range"])
	var range_squared: float = tower_range * tower_range
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
	var stats: Dictionary = _tower_runtime_stats(tower)
	var tower_pos: Vector2 = _tower_position(tower)
	var enemy_pos: Vector2 = enemies[enemy_index]["pos"]
	if _should_use_physics_projectile(tower):
		_spawn_physics_projectile(tower, enemy_pos, float(stats["damage"]), str(tower["type"]), false, int(enemies[enemy_index].get("uid", -1)))
		_add_visual_effect("muzzle", tower_pos, cfg["color"], 0.20, 16.0)
		_play_sfx("physics_fire", 0.06)
		return

	_add_shot(tower_pos, enemy_pos, cfg["color"], 0.15, 3.0, str(tower["type"]))
	_add_visual_effect("muzzle", tower_pos, cfg["color"], 0.16, 14.0)
	_play_sfx("shot", 0.035)
	_damage_enemy(enemy_index, float(stats["damage"]), str(tower["type"]))


func _should_use_physics_projectile(tower: Dictionary) -> bool:
	var tower_type: String = str(tower.get("type", ""))
	if tower_type != "helios_cannon" and tower_type != "tardigrade_bomb":
		return false
	return _tower_level(tower) >= 2


func _spawn_physics_projectile(
	tower: Dictionary,
	target_pos: Vector2,
	damage: float,
	tower_type: String,
	slingshot: bool = false,
	target_uid: int = -1
) -> void:
	var tower_pos: Vector2 = _tower_position(tower)
	var velocity: Vector2 = _compute_physics_launch_velocity(tower, target_pos, 300.0)
	if slingshot:
		var inward: Vector2 = (_sun_pos() - tower_pos).normalized()
		var tangent: Vector2 = Vector2(-sin(float(tower["angle"])), cos(float(tower["angle"])))
		velocity = tangent * 420.0 + inward * 60.0

	var color: Color = _tower_config(tower_type)["color"]
	physics_projectiles.append({
		"pos": tower_pos,
		"velocity": velocity,
		"damage": damage,
		"tower_type": tower_type,
		"target_uid": target_uid,
		"target_pos": target_pos,
		"lifetime": 0.0,
		"last_dist": tower_pos.distance_to(_sun_pos()),
		"color": color,
		"trail": [tower_pos],
	})


func _compute_physics_launch_velocity(tower: Dictionary, target_pos: Vector2, base_speed: float) -> Vector2:
	var tower_pos: Vector2 = _tower_position(tower)
	var ring: Dictionary = RINGS[int(tower["ring"])]
	var ring_radius: float = _ring_radius(int(tower["ring"]))
	var ring_period: float = float(ring["period"])
	if gameplay_math != null:
		var cpp_velocity = gameplay_math.call("compute_physics_launch_velocity", tower_pos, target_pos, float(tower["angle"]), ring_radius, ring_period, base_speed)
		if cpp_velocity is Vector2:
			return cpp_velocity

	var to_target: Vector2 = target_pos - tower_pos
	if to_target.length_squared() <= 0.001:
		to_target = _sun_pos() - tower_pos
	var angular_velocity: float = TAU / ring_period
	var tangent: Vector2 = Vector2(-sin(float(tower["angle"])), cos(float(tower["angle"])))
	return to_target.normalized() * base_speed + tangent * angular_velocity * ring_radius * 0.6


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
	var tower_range: float = float(stats["range"])
	var range_squared: float = tower_range * tower_range
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

	if variant == "mimic" and source == "photon_splitter":
		_add_visual_effect("shield", enemy_pos, Color(0.70, 0.62, 0.98), 0.32, float(enemy["radius"]) + 16.0)
		_play_sfx("hit", 0.080)
		return

	if source == "cryo_probe" or source == "magnetic_net":
		enemy["slow_timer"] = 2.8

	if variant == "farmer" and (source == "photon_splitter" or source == "helios_cannon"):
		enemy["hp"] = min(float(enemy["hp"]) + amount * 0.4, float(enemy["max_hp"]) * 1.8)
		enemy["speed"] = min(float(enemy["speed"]) + 1.0, 150.0)
		enemy["max_speed"] = maxf(float(enemy.get("max_speed", 0.0)), float(enemy["speed"]) * 2.25)
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
		if variant == "prime" and int(enemy.get("prime_phase", 0)) == 1:
			_enter_prime_frenzy(enemy_index, enemy)
			return
		_defeat_enemy(enemy_index)


func _enter_prime_frenzy(enemy_index: int, enemy: Dictionary) -> void:
	enemy["prime_phase"] = 2
	enemy["hp"] = 300.0
	enemy["max_hp"] = 300.0
	enemy["speed"] = minf(float(enemy.get("speed", 23.0)) * 1.8, 80.0)
	enemy["max_speed"] = float(enemy["speed"]) * 1.85
	enemy["radius"] = maxf(float(enemy.get("radius", 34.0)), 42.0)
	enemy["draw_size"] = maxf(float(enemy.get("draw_size", 84.0)), 108.0)
	enemy["color"] = Color(1.0, 0.08, 0.06)
	enemy["frenzy_timer"] = 0.35
	enemy["hit_timer"] = ENEMY_HIT_FLASH_SECONDS
	enemies[enemy_index] = enemy
	prime_frenzy_interval = 1.5
	prime_frenzy_max_active = 36
	_add_visual_effect("burst", enemy.get("pos", _sun_pos()), Color(1.0, 0.18, 0.10), 0.72, float(enemy["radius"]) + 52.0)
	_show_wave_banner("Prime Frenzy", "Astrophage Prime is spawning Drifters.", Color(1.0, 0.12, 0.08), 3.2)
	_play_sfx("prime_phase_shift", 0.8)
	_set_message("Prime entered Frenzy. Drifters will keep spawning until it dies.", 3.4)
	_update_ui()


func _defeat_enemy(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return

	var enemy: Dictionary = enemies[enemy_index]
	var variant: String = str(enemy["variant"])
	var pos: Vector2 = enemy["pos"]

	GameState.add_credits(int(enemy["reward"]))
	GameState.on_enemy_killed(int(enemy["variant_id"]))
	_add_enemy_death_effect(enemy)
	_add_text_effect("+%d SOL" % int(enemy["reward"]), pos + Vector2(0.0, -float(enemy["radius"]) - 20.0), Color(1.0, 0.86, 0.34, 0.98))
	_play_sfx("prime_death" if variant == "prime" else "death", 0.050)

	enemies.remove_at(enemy_index)

	if variant == "bloom":
		for i in range(3):
			var offset: Vector2 = Vector2.RIGHT.rotated(TAU * float(i) / 3.0) * 24.0
			_spawn_enemy("drifter", pos + offset)
	elif variant == "prime":
		prime_frenzy_interval = 0.0
		prime_frenzy_timer = 0.0
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
	var slot = orbit_math.call("nearest_ring_slot", pos, _sun_pos(), towers)
	if slot is Dictionary:
		return slot
	return {}


func _ring_slot_position(ring_index: int, slot_index: int) -> Vector2:
	var pos = orbit_math.call("ring_slot_position", _sun_pos(), ring_index, slot_index)
	if pos is Vector2:
		return pos
	return _sun_pos()


func _ring_radius(ring_index: int) -> float:
	return float(orbit_math.call("ring_radius", ring_index))


func _outer_ring_radius() -> float:
	return float(orbit_math.call("outer_ring_radius"))


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
	_play_sfx("ui_intel_update", 0.12)
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
	var pos = orbit_math.call("tower_position", _sun_pos(), tower)
	if pos is Vector2:
		return pos
	return _sun_pos()


func _burrower_position(burrower: Dictionary) -> Vector2:
	var pos = orbit_math.call("burrower_position", _sun_pos(), burrower, BURROWER_DIG_RADIUS)
	if pos is Vector2:
		return pos
	return _sun_pos()


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
	var variant: String = str(enemy["variant"])
	var animation_state: String = _enemy_animation_state(enemy)
	var texture = _enemy_animation_texture(enemy)
	if texture == null:
		texture = _enemy_texture(variant)
	var hit_flash: float = clampf(float(enemy.get("hit_timer", 0.0)) / ENEMY_HIT_FLASH_SECONDS, 0.0, 1.0)
	var heal_flash: float = clampf(float(enemy.get("heal_timer", 0.0)) / ENEMY_HIT_FLASH_SECONDS, 0.0, 1.0)

	draw_circle(pos, radius + 5.0, Color(0.0, 0.0, 0.0, 0.44))
	if texture:
		var size: Vector2 = Vector2(float(enemy["draw_size"]) + 8.0, float(enemy["draw_size"]) + 8.0)
		if animation_state != "idle" and not _enemy_animation_frames(variant, animation_state).is_empty():
			_draw_rotated_enemy_texture(texture, pos, size, _enemy_sprite_draw_angle(enemy, variant))
		else:
			draw_texture_rect(texture, Rect2(pos - size * 0.5, size), false)
	else:
		draw_circle(pos, radius, enemy_color)
	_draw_enemy_circle_border(enemy, hit_flash, heal_flash)
	_draw_enemy_status_markers(enemy, pos, radius)
	var show_bar: bool = hp_ratio < 0.995 or hit_flash > 0.0 or heal_flash > 0.0 or variant == "prime"
	if show_bar:
		var bar_width: float = maxf(radius * 2.65, 40.0)
		if variant == "prime":
			bar_width = maxf(bar_width, 88.0)
		var bar_pos: Vector2 = Vector2(pos.x - bar_width * 0.5, pos.y - radius - 18.0)
		_draw_health_bar(bar_pos, bar_width, HEALTH_BAR_HEIGHT, hp_ratio, enemy_color, hit_flash, heal_flash)


func _draw_rotated_enemy_texture(texture, pos: Vector2, size: Vector2, angle: float) -> void:
	var screen_pos: Vector2 = board_draw_translation + pos * board_draw_zoom
	draw_set_transform(screen_pos, angle, Vector2(board_draw_zoom, board_draw_zoom))
	draw_texture_rect(texture, Rect2(size * -0.5, size), false)
	draw_set_transform(board_draw_translation, 0.0, Vector2(board_draw_zoom, board_draw_zoom))


func _draw_enemy_circle_border(enemy: Dictionary, hit_flash: float, heal_flash: float) -> void:
	var pos: Vector2 = enemy["pos"]
	var radius: float = float(enemy["radius"])
	var draw_size: float = float(enemy.get("draw_size", radius * 2.0))
	var border_radius: float = maxf(radius + 5.5, draw_size * 0.5 + 4.0)
	var enemy_color: Color = enemy.get("color", Color(0.78, 0.92, 1.0))
	var ring_color: Color = enemy_color.lerp(Color(0.92, 0.98, 1.0), 0.34)
	if heal_flash > 0.0:
		ring_color = ring_color.lerp(Color(0.66, 1.0, 0.54), heal_flash)
	elif hit_flash > 0.0:
		ring_color = ring_color.lerp(Color(1.0, 0.86, 0.30), hit_flash)

	draw_arc(pos, border_radius + 1.6, 0.0, TAU, 72, Color(0.0, 0.0, 0.0, 0.58), 3.0, true)
	draw_arc(pos, border_radius, 0.0, TAU, 72, Color(ring_color.r, ring_color.g, ring_color.b, 0.64), 1.7, true)
	draw_arc(pos, border_radius - 2.2, -PI * 0.5, -PI * 0.5 + TAU * 0.30, 24, Color(0.90, 1.0, 1.0, 0.34), 1.1, true)


func _draw_health_bar(pos: Vector2, width: float, height: float, ratio: float, accent: Color, hit_flash: float = 0.0, heal_flash: float = 0.0) -> void:
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
	if bool(game_hud.call("is_screen_position_over_hud", mouse_position)):
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
					var ghost_tint: Color = Color(1.0, 0.84, 0.74, 0.24 * alpha)
					if bool(effect.get("rotates_sprite", false)):
						var ghost_angle: float = float(effect.get("sprite_angle", 0.0)) - float(ENEMY_ANIMATION_BASE_ANGLES.get(str(effect.get("variant", "")), 0.0))
						var ghost_screen_pos: Vector2 = board_draw_translation + pos * board_draw_zoom
						draw_set_transform(ghost_screen_pos, ghost_angle, Vector2(board_draw_zoom, board_draw_zoom))
						draw_texture_rect(texture, Rect2(ghost_size * -0.5, ghost_size), false, ghost_tint)
						draw_set_transform(board_draw_translation, 0.0, Vector2(board_draw_zoom, board_draw_zoom))
					else:
						draw_texture_rect(texture, Rect2(pos - ghost_size * 0.5, ghost_size), false, ghost_tint)
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
					var prime_tint: Color = Color(1.0, 0.60, 0.46, 0.28 * alpha)
					if bool(effect.get("rotates_sprite", false)):
						var prime_angle: float = float(effect.get("sprite_angle", 0.0)) - float(ENEMY_ANIMATION_BASE_ANGLES.get(str(effect.get("variant", "")), 0.0))
						var prime_screen_pos: Vector2 = board_draw_translation + pos * board_draw_zoom
						draw_set_transform(prime_screen_pos, prime_angle, Vector2(board_draw_zoom, board_draw_zoom))
						draw_texture_rect(prime_texture, Rect2(prime_size * -0.5, prime_size), false, prime_tint)
						draw_set_transform(board_draw_translation, 0.0, Vector2(board_draw_zoom, board_draw_zoom))
					else:
						draw_texture_rect(prime_texture, Rect2(pos - prime_size * 0.5, prime_size), false, prime_tint)
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


func _ease_out_cubic(value: float) -> float:
	return float(runtime_native.call("ease_out_cubic", value))


func _ease_in_out_sine(value: float) -> float:
	return float(runtime_native.call("ease_in_out_sine", value))


func _sun_pos() -> Vector2:
	return runtime_native.call("sun_pos", get_viewport_rect().size) as Vector2


func _view_translation(viewport_size: Vector2) -> Vector2:
	return view_controller.translation(viewport_size)


func _screen_shake_offset() -> Vector2:
	return runtime_native.call("screen_shake_offset", screen_shake_timer, GameState.screen_shake_enabled, screen_shake_strength) as Vector2


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
	return bool(runtime_native.call("can_build_towers", GameState.game_phase, GameState.BETWEEN_WAVE, GameState.WAVE_ACTIVE))


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

	var texture = _enemy_animation_texture(enemy)
	if texture == null:
		texture = _enemy_texture(variant)
	var rotates_sprite: bool = not _enemy_animation_frames(variant, "move").is_empty()
	effect_store.add_enemy_death(enemy, texture, float(enemy.get("draw_size", radius * 2.0)), rotates_sprite)
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
	next_wave_preview = _wave_load(next_wave)
	if GameState.game_phase == GameState.BETWEEN_WAVE:
		_show_wave_preview(next_wave_preview)
	else:
		_clear_wave_preview()


func _show_wave_preview(wave_data: Dictionary) -> void:
	wave_preview_points.clear()
	if wave_data.is_empty():
		return

	var wave_type: String = str(wave_data.get("wave_type", "normal"))
	if wave_type == "clash" or wave_type == "boss":
		var groups: Array = _wave_array_value(wave_data.get("clash_groups", []))
		if groups.is_empty() or not (groups[0] is Dictionary):
			return
		var first_group: Dictionary = groups[0]
		var variants: Array = _wave_array_value(first_group.get("variants", []))
		var preview_count: int = min(variants.size(), 16)
		for i in range(preview_count):
			wave_preview_points.append(_spawn_position_for_pattern(str(first_group.get("spawn_pattern", "random")), i, preview_count, first_group))
	elif wave_type == "formation":
		var formation: Dictionary = wave_data.get("formation", {})
		var preview_count: int = min(max(8, int(formation.get("count", 8))), 16)
		for i in range(preview_count):
			wave_preview_points.append(_spawn_position_for_pattern(str(formation.get("type", "ring")), i, preview_count, formation))
	else:
		for i in range(8):
			wave_preview_points.append(_spawn_position_for_pattern("ring", i, 8))
	queue_redraw()


func _clear_wave_preview() -> void:
	if wave_preview_points.is_empty():
		return
	wave_preview_points.clear()
	queue_redraw()


func _is_prime_alive() -> bool:
	for enemy in enemies:
		if str(enemy["variant"]) == "prime":
			return true
	return false


func _tower_config(tower_type: String) -> Dictionary:
	return tower_library.call("config", tower_type) as Dictionary


func _tower_level(tower: Dictionary) -> int:
	return int(tower_library.call("level", tower))


func _tower_runtime_stats(tower: Dictionary) -> Dictionary:
	return tower_library.call("runtime_stats", tower) as Dictionary


func _tower_upgrade_cost(tower: Dictionary) -> int:
	return int(tower_library.call("upgrade_cost", tower))


func _tower_sell_refund(tower: Dictionary) -> int:
	return int(tower_library.call("sell_refund", tower))


func _managed_tower_view_data() -> Dictionary:
	var tower_index: int = _managed_tower_index()
	if tower_index == -1:
		managed_tower_ring = -1
		managed_tower_slot = -1
		return {}

	var tower: Dictionary = towers[tower_index]
	return tower_library.call("managed_view_data", tower, RINGS, GameState.sol_credits) as Dictionary


func _end_state_view_data() -> Dictionary:
	if GameState.game_phase != GameState.GAME_OVER and GameState.game_phase != GameState.VICTORY:
		return {}

	var victory: bool = GameState.game_phase == GameState.VICTORY
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


func _enemy_animation_texture(enemy: Dictionary):
	var variant: String = str(enemy.get("variant", "drifter"))
	var state: String = _enemy_animation_state(enemy)
	var frames: Array = _enemy_animation_frames(variant, state)
	if frames.is_empty() and state != "idle":
		state = "idle"
		frames = _enemy_animation_frames(variant, state)
	if frames.is_empty():
		return null

	var fps: float = _enemy_animation_fps(variant, state)
	var anim_time: float = Time.get_ticks_msec() / 1000.0 + float(enemy.get("anim_offset", 0.0))
	var frame_index: int = int(floor(anim_time * fps)) % frames.size()
	return frames[frame_index]


func _enemy_animation_state(enemy: Dictionary) -> String:
	if str(enemy.get("variant", "")) == "prime":
		var phase: int = int(enemy.get("prime_phase", 0))
		if phase >= 2:
			return "frenzy"
		if phase == 1:
			return "active"
	if GameState.game_phase == GameState.WAVE_ACTIVE and float(enemy.get("speed", 0.0)) > 0.0:
		return "move"
	return "idle"


func _enemy_animation_frames(variant: String, state: String) -> Array:
	var animation_store: Dictionary = textures.get("enemy_animations", {})
	var variant_frames: Dictionary = animation_store.get(variant, {})
	if variant_frames.is_empty():
		return []
	var frames = variant_frames.get(state, [])
	if frames is Array:
		return frames
	return []


func _enemy_animation_fps(variant: String, state: String) -> float:
	if variant == "prime":
		if state == "frenzy":
			return 9.0
		if state == "active":
			return 6.5
		if state == "move":
			return 5.5
	return 8.0 if state == "move" else 4.0


func _enemy_sprite_draw_angle(enemy: Dictionary, variant: String) -> float:
	var move_angle: float = float(enemy.get("sprite_angle", enemy.get("move_angle", 0.0)))
	var base_angle: float = float(ENEMY_ANIMATION_BASE_ANGLES.get(variant, 0.0))
	if variant == "prime":
		var state: String = _enemy_animation_state(enemy)
		if state == "active" or state == "frenzy":
			base_angle = PI * 0.5
	return move_angle - base_angle


func _enemy_preview_texture(variant: String):
	var idle_frames: Array = _enemy_animation_frames(variant, "idle")
	if not idle_frames.is_empty():
		return idle_frames[0]

	var move_frames: Array = _enemy_animation_frames(variant, "move")
	if not move_frames.is_empty():
		return move_frames[0]

	return _enemy_texture(variant)


func _ring_summary() -> String:
	return str(orbit_math.call("ring_summary"))


func _wave_load(wave_number: int) -> Dictionary:
	return wave_library.call("load_wave", wave_number) as Dictionary


func _wave_build_spawn_queue(wave_data: Dictionary) -> Array:
	return wave_library.call("build_spawn_queue", wave_data) as Array


func _wave_variant_key(raw) -> String:
	return str(wave_library.call("variant_key", raw))


func _wave_primary_variant(wave_data: Dictionary) -> String:
	return str(wave_library.call("primary_variant", wave_data))


func _wave_spawn_summary(wave_data: Dictionary) -> String:
	return str(wave_library.call("spawn_summary", wave_data))


func _wave_intel_detail(wave_data: Dictionary, reward: int, active_count: int, burrowed_count: int, queued_count: int, modifier_summary: String) -> String:
	return str(wave_library.call("intel_detail", wave_data, reward, active_count, burrowed_count, queued_count, modifier_summary))


func _wave_clean_hint(text: String, wave_name: String) -> String:
	return str(wave_library.call("clean_hint", text, wave_name))


func _wave_total_spawn_count(wave_data: Dictionary) -> int:
	return int(wave_library.call("total_spawn_count", wave_data))


func _wave_preview_label(wave_data: Dictionary) -> String:
	return str(wave_library.call("preview_label", wave_data))


func _wave_array_value(value) -> Array:
	return wave_library.call("array_value", value) as Array


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
	return str(tower_library.call("selected_readout", selected_tower, GameState.game_phase == GameState.WAVE_ACTIVE))


func _set_message(text: String, duration: float = 0.0) -> void:
	message_text = text
	message_timer = duration
	_update_ui()


func _tower_button_view_data() -> Dictionary:
	return tower_library.call("button_view_data", selected_tower, _can_build_towers(), textures["towers"], GameState.sol_credits) as Dictionary


func _update_ui() -> void:
	if game_hud == null:
		return

	var wave_data: Dictionary = current_wave_data if GameState.game_phase == GameState.WAVE_ACTIVE else next_wave_preview
	var wave_index: int = int(wave_data.get("index", min(GameState.current_wave + 1, MAX_WAVES)))
	var wave_name: String = str(wave_data.get("name", "First Contact"))
	var title_text: String = "WAVE %02d/%02d | %s" % [wave_index, MAX_WAVES, wave_name.to_upper()]
	if GameState.game_phase != GameState.WAVE_ACTIVE:
		title_text = "%s %02d/%02d" % [briefing_title.to_upper(), wave_index, MAX_WAVES]
		if briefing_title.strip_edges().to_lower() != wave_name.strip_edges().to_lower():
			title_text += " | %s" % wave_name.to_upper()

	var reward: int = int(wave_data.get("credit_reward", 0))
	var next_wave: int = min(GameState.current_wave + 1, MAX_WAVES)
	var start_disabled: bool = GameState.game_phase != GameState.BETWEEN_WAVE or next_wave > playable_wave_limit
	var start_text: String = "START WAVE %d" % next_wave
	var intel_status: String = "LIVE" if GameState.game_phase == GameState.WAVE_ACTIVE else "NEXT"
	if GameState.auto_start_waves_enabled and not start_disabled and auto_start_timer > 0.0:
		start_text = "AUTO IN %d" % max(1, int(ceil(auto_start_timer)))
		intel_status = "AUTO %d" % max(1, int(ceil(auto_start_timer)))
	elif GameState.auto_start_waves_enabled and not start_disabled:
		intel_status = "AUTO START"
	game_hud.call("update_view", {
		"wave_title": title_text,
		"brief": _wave_clean_hint(str(wave_data.get("tutorial_hint", "Defend the Sun.")), wave_name),
		"credits": str(GameState.sol_credits),
		"score": str(GameState.performance_score),
		"kills": str(GameState.enemies_killed_total),
		"flare": "F READY" if GameState.flare_charge > 0 else "CHARGING",
		"luminosity": float(GameState.get_luminosity_percent()),
		"enemy_texture": _enemy_preview_texture(_wave_primary_variant(wave_data)),
		"intel_status": intel_status,
		"enemy_summary": _wave_spawn_summary(wave_data).to_upper(),
		"threat": _wave_intel_detail(
			wave_data,
			reward,
			enemies.size() if GameState.game_phase == GameState.WAVE_ACTIVE else -1,
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
