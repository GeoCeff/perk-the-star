extends Node2D

const SUN_POS := Vector2(960.0, 540.0)
const SUN_RADIUS := 72.0
const CORONA_RADIUS := 96.0
const MAX_WAVES := 12

const RINGS := [
	{"name": "Corona Belt", "radius": 170.0, "period": 10.0},
	{"name": "Chromosphere Band", "radius": 270.0, "period": 15.0},
	{"name": "Outer Veil", "radius": 390.0, "period": 22.0},
]

const TOWER_ORDER := [
	"photon_splitter",
	"cryo_probe",
	"bio_lab",
	"magnetic_net",
	"helios_cannon",
	"tardigrade_bomb",
]

const TOWER_CONFIGS := {
	"photon_splitter": {"label": "Photon", "damage": 14.0, "rate": 0.75, "range": 295.0, "color": Color(1.0, 0.84, 0.28)},
	"cryo_probe": {"label": "Cryo", "damage": 4.0, "rate": 0.45, "range": 255.0, "color": Color(0.34, 0.86, 1.0)},
	"bio_lab": {"label": "Bio-Lab", "damage": 9.0, "rate": 0.55, "range": 285.0, "color": Color(0.46, 1.0, 0.52)},
	"magnetic_net": {"label": "Net", "damage": 3.0, "rate": 0.35, "range": 330.0, "color": Color(0.76, 0.62, 1.0)},
	"helios_cannon": {"label": "Helios", "damage": 72.0, "rate": 0.12, "range": 360.0, "color": Color(1.0, 0.42, 0.22)},
	"tardigrade_bomb": {"label": "Bomb", "damage": 18.0, "rate": 0.38, "range": 245.0, "color": Color(1.0, 0.58, 0.76)},
}

const ENEMY_CONFIGS := {
	"drifter": {"label": "Drifter", "hp": 30.0, "speed": 64.0, "damage": 0.05, "reward": 5, "radius": 12.0, "score": 10, "color": Color(0.96, 0.42, 0.48)},
	"bloom": {"label": "Bloom", "hp": 62.0, "speed": 55.0, "damage": 0.05, "reward": 10, "radius": 16.0, "score": 20, "color": Color(1.0, 0.62, 0.36)},
	"burrower": {"label": "Burrower", "hp": 115.0, "speed": 38.0, "damage": 0.08, "reward": 20, "radius": 17.0, "score": 40, "color": Color(0.76, 0.50, 0.30)},
	"mimic": {"label": "Mimic", "hp": 52.0, "speed": 62.0, "damage": 0.05, "reward": 15, "radius": 13.0, "score": 30, "color": Color(0.70, 0.62, 0.98)},
	"farmer": {"label": "Farmer", "hp": 44.0, "speed": 58.0, "damage": 0.05, "reward": 12, "radius": 14.0, "score": 25, "color": Color(0.55, 0.92, 0.45)},
	"prime": {"label": "Prime", "hp": 520.0, "speed": 28.0, "damage": 0.12, "reward": 100, "radius": 28.0, "score": 200, "color": Color(1.0, 0.18, 0.15)},
}

var current_wave_data: Dictionary = {}
var spawn_queue: Array = []
var enemies: Array = []
var towers: Array = []
var shots: Array = []
var selected_tower := "photon_splitter"
var spawn_timer := 0.0
var wave_active := false
var message_text := "Click an orbital ring to place a tower, then start Wave 1."
var message_timer := 0.0
var ui: Dictionary = {}


func _ready() -> void:
	randomize()
	GameState.reset_state()
	GameState.set_phase(GameState.Phase.BETWEEN_WAVE)
	_build_ui()
	_update_ui()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message_text = "Click an orbital ring to place towers between waves."
			_update_ui()

	if GameState.game_phase == GameState.Phase.WAVE_ACTIVE:
		_process_spawning(delta)

	_process_towers(delta)
	_process_enemies(delta)
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

	var click_pos := get_global_mouse_position()
	var ring := _nearest_ring(click_pos)
	if ring.is_empty():
		_set_message("Place towers by clicking close to one of the orbital rings.", 2.0)
		return

	var cost := GameState.get_tower_cost(selected_tower)
	if not GameState.spend_credits(cost):
		_set_message("Need %d Sol Credits for %s." % [cost, _tower_config(selected_tower)["label"]], 2.0)
		return

	towers.append({
		"type": selected_tower,
		"ring": int(ring["index"]),
		"angle": (click_pos - SUN_POS).angle(),
		"fire_timer": 0.15,
		"level": 1,
	})
	_set_message("Placed %s on %s." % [_tower_config(selected_tower)["label"], ring["name"]], 2.0)
	_update_ui()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.018, 0.024, 0.044), true)

	for i in range(RINGS.size()):
		var ring := RINGS[i]
		var color := Color(0.30, 0.62, 1.0, 0.28 if i < 2 else 0.20)
		draw_arc(SUN_POS, float(ring["radius"]), 0.0, TAU, 192, color, 2.0, true)
		for slot in range(12):
			var angle := float(slot) / 12.0 * TAU
			var pos := SUN_POS + Vector2(cos(angle), sin(angle)) * float(ring["radius"])
			draw_circle(pos, 4.0, Color(0.58, 0.74, 1.0, 0.34))

	draw_circle(SUN_POS, 128.0, Color(1.0, 0.55, 0.12, 0.06))
	draw_circle(SUN_POS, 98.0, Color(1.0, 0.65, 0.16, 0.11))
	draw_circle(SUN_POS, SUN_RADIUS, Color(1.0, 0.72, 0.20))
	draw_circle(SUN_POS, SUN_RADIUS * max(GameState.luminosity, 0.08), Color(1.0, 0.93, 0.45))

	for shot in shots:
		draw_line(shot["from"], shot["to"], shot["color"], 3.0)

	for tower in towers:
		var pos := _tower_position(tower)
		var cfg := _tower_config(tower["type"])
		draw_circle(pos, 16.0, Color(0.04, 0.07, 0.12))
		draw_circle(pos, 11.0, cfg["color"])
		draw_line(pos, SUN_POS, Color(0.36, 0.50, 0.68, 0.24), 1.0)

	for enemy in enemies:
		var pos: Vector2 = enemy["pos"]
		var radius := float(enemy["radius"])
		var hp_ratio = clamp(float(enemy["hp"]) / float(enemy["max_hp"]), 0.0, 1.0)
		draw_circle(pos, radius + 3.0, Color(0.02, 0.02, 0.03, 0.85))
		draw_circle(pos, radius, enemy["color"])
		draw_line(pos + Vector2(-radius, -radius - 8.0), pos + Vector2(radius, -radius - 8.0), Color(0.22, 0.08, 0.08), 3.0)
		draw_line(pos + Vector2(-radius, -radius - 8.0), pos + Vector2(-radius + radius * 2.0 * hp_ratio, -radius - 8.0), Color(0.45, 1.0, 0.42), 3.0)

	if GameState.game_phase == GameState.Phase.GAME_OVER:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.0, 0.0, 0.0, 0.58), true)
	elif GameState.game_phase == GameState.Phase.VICTORY:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(1.0, 0.78, 0.18, 0.12), true)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var root := Control.new()
	root.name = "Hud"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	var top_panel := PanelContainer.new()
	top_panel.anchor_right = 1.0
	top_panel.offset_left = 18.0
	top_panel.offset_top = 18.0
	top_panel.offset_right = -18.0
	top_panel.offset_bottom = 78.0
	root.add_child(top_panel)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	top_panel.add_child(top_row)

	ui["wave_label"] = Label.new()
	ui["credits_label"] = Label.new()
	ui["sun_label"] = Label.new()
	ui["score_label"] = Label.new()
	top_row.add_child(ui["wave_label"])
	top_row.add_child(ui["credits_label"])
	top_row.add_child(ui["sun_label"])
	top_row.add_child(ui["score_label"])

	ui["start_button"] = Button.new()
	ui["start_button"].pressed.connect(_on_start_wave_pressed)
	top_row.add_child(ui["start_button"])

	var menu_button := Button.new()
	menu_button.text = "Menu"
	menu_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	top_row.add_child(menu_button)

	var tower_panel := PanelContainer.new()
	tower_panel.anchor_left = 0.0
	tower_panel.anchor_top = 1.0
	tower_panel.anchor_bottom = 1.0
	tower_panel.offset_left = 18.0
	tower_panel.offset_top = -98.0
	tower_panel.offset_right = 900.0
	tower_panel.offset_bottom = -18.0
	root.add_child(tower_panel)

	var tower_row := HBoxContainer.new()
	tower_row.add_theme_constant_override("separation", 10)
	tower_panel.add_child(tower_row)

	var tower_label := Label.new()
	tower_label.text = "Towers"
	tower_row.add_child(tower_label)

	ui["tower_buttons"] = {}
	for tower_type in TOWER_ORDER:
		var button := Button.new()
		button.pressed.connect(_select_tower.bind(tower_type))
		ui["tower_buttons"][tower_type] = button
		tower_row.add_child(button)

	var message_panel := PanelContainer.new()
	message_panel.anchor_left = 1.0
	message_panel.anchor_top = 1.0
	message_panel.anchor_right = 1.0
	message_panel.anchor_bottom = 1.0
	message_panel.offset_left = -680.0
	message_panel.offset_top = -98.0
	message_panel.offset_right = -18.0
	message_panel.offset_bottom = -18.0
	root.add_child(message_panel)

	ui["message_label"] = Label.new()
	ui["message_label"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_panel.add_child(ui["message_label"])


func _on_start_wave_pressed() -> void:
	if GameState.game_phase != GameState.Phase.BETWEEN_WAVE:
		return

	var wave_number := GameState.current_wave + 1
	if wave_number > MAX_WAVES:
		return

	current_wave_data = _load_wave(wave_number)
	if current_wave_data.is_empty():
		_set_message("Could not load wave_%02d.json." % wave_number, 3.0)
		return

	GameState.current_wave = wave_number
	GameState.set_phase(GameState.Phase.WAVE_ACTIVE)
	spawn_queue = _build_spawn_queue(current_wave_data)
	spawn_timer = 0.25
	wave_active = true
	_set_message(str(current_wave_data.get("tutorial_hint", "Wave incoming.")), 5.0)
	_update_ui()


func _select_tower(tower_type: String) -> void:
	selected_tower = tower_type
	_set_message("Selected %s." % _tower_config(tower_type)["label"], 1.2)
	_update_ui()


func _process_spawning(delta: float) -> void:
	if spawn_queue.is_empty():
		return

	spawn_timer -= delta
	while spawn_timer <= 0.0 and not spawn_queue.is_empty():
		_spawn_enemy(spawn_queue.pop_front())
		spawn_timer += float(current_wave_data.get("spawn_interval", 2.0))


func _process_towers(delta: float) -> void:
	for i in range(towers.size()):
		var tower: Dictionary = towers[i]
		var ring := RINGS[int(tower["ring"])]
		tower["angle"] = wrapf(float(tower["angle"]) + TAU / float(ring["period"]) * delta, 0.0, TAU)
		tower["fire_timer"] = max(float(tower["fire_timer"]) - delta, 0.0)

		if GameState.game_phase == GameState.Phase.WAVE_ACTIVE and float(tower["fire_timer"]) <= 0.0:
			var target_index := _find_target_for_tower(tower)
			if target_index != -1:
				_fire_tower(tower, target_index)
				var cfg := _tower_config(tower["type"])
				tower["fire_timer"] = 1.0 / float(cfg["rate"])

		towers[i] = tower


func _process_enemies(delta: float) -> void:
	if enemies.is_empty():
		return

	var survivors: Array = []
	var reached_sun := false
	for enemy in enemies:
		if float(enemy["hp"]) <= 0.0:
			continue

		var pos: Vector2 = enemy["pos"]
		var to_sun := SUN_POS - pos
		var dist := to_sun.length()
		if dist <= CORONA_RADIUS:
			GameState.damage_sun(float(enemy["damage"]))
			reached_sun = true
			continue

		var speed_multiplier := 0.5 if float(enemy["slow_timer"]) > 0.0 else 1.0
		enemy["slow_timer"] = max(float(enemy["slow_timer"]) - delta, 0.0)
		if dist > 0.0:
			enemy["pos"] = pos + to_sun.normalized() * float(enemy["speed"]) * speed_multiplier * delta
		survivors.append(enemy)

	enemies = survivors
	if reached_sun:
		_set_message("The corona was breached. Luminosity is falling.", 2.0)
		_update_ui()

	if GameState.game_phase == GameState.Phase.GAME_OVER:
		wave_active = false
		spawn_queue.clear()
		_set_message("Game over. The sun went dark.", 999.0)
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
	if not spawn_queue.is_empty() or not enemies.is_empty():
		return

	wave_active = false
	var reward := int(current_wave_data.get("reward_base", 0))
	GameState.add_credits(reward)
	GameState.on_wave_cleared()

	if GameState.current_wave >= MAX_WAVES:
		GameState.trigger_victory()
		_set_message("Victory. Final rank: %s." % GameState.get_rank(), 999.0)
	else:
		GameState.set_phase(GameState.Phase.BETWEEN_WAVE)
		_set_message("Wave %d cleared. Bonus: %d Sol Credits." % [GameState.current_wave, reward], 4.0)
	_update_ui()


func _load_wave(wave_number: int) -> Dictionary:
	var path := "res://data/waves/wave_%02d.json" % wave_number
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _build_spawn_queue(wave_data: Dictionary) -> Array:
	var queue: Array = []
	for entry in wave_data.get("enemies", []):
		var variant := str(entry.get("variant", "drifter"))
		var count := int(entry.get("count", 0))
		for _i in range(count):
			queue.append(variant)
	queue.shuffle()
	return queue


func _spawn_enemy(variant: String, spawn_pos := Vector2.INF) -> void:
	var cfg := _enemy_config(variant)
	var angle := randf() * TAU
	var distance := 780.0
	var pos := spawn_pos
	if pos == Vector2.INF:
		pos = SUN_POS + Vector2(cos(angle), sin(angle)) * distance

	enemies.append({
		"variant": variant,
		"label": cfg["label"],
		"pos": pos,
		"hp": cfg["hp"],
		"max_hp": cfg["hp"],
		"speed": cfg["speed"],
		"damage": cfg["damage"],
		"reward": cfg["reward"],
		"radius": cfg["radius"],
		"score": cfg["score"],
		"color": cfg["color"],
		"slow_timer": 0.0,
		"prime_phase": 0,
	})


func _find_target_for_tower(tower: Dictionary) -> int:
	var tower_pos := _tower_position(tower)
	var cfg := _tower_config(tower["type"])
	var best_index := -1
	var best_dist := INF

	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		var dist := tower_pos.distance_to(enemy["pos"])
		if dist <= float(cfg["range"]) and dist < best_dist:
			best_index = i
			best_dist = dist

	return best_index


func _fire_tower(tower: Dictionary, enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return

	var cfg := _tower_config(tower["type"])
	var tower_pos := _tower_position(tower)
	var enemy_pos: Vector2 = enemies[enemy_index]["pos"]
	shots.append({"from": tower_pos, "to": enemy_pos, "ttl": 0.14, "color": cfg["color"]})
	_damage_enemy(enemy_index, float(cfg["damage"]), str(tower["type"]))


func _damage_enemy(enemy_index: int, amount: float, source: String) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return

	var enemy: Dictionary = enemies[enemy_index]
	var variant := str(enemy["variant"])

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
	var variant := str(enemy["variant"])
	var pos: Vector2 = enemy["pos"]

	GameState.add_credits(int(enemy["reward"]))
	GameState.add_score(int(enemy["score"]))

	enemies.remove_at(enemy_index)

	if variant == "bloom":
		for i in range(3):
			var offset := Vector2.RIGHT.rotated(TAU * float(i) / 3.0) * 24.0
			_spawn_enemy("drifter", pos + offset)

	_update_ui()


func _nearest_ring(pos: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_diff := INF
	for i in range(RINGS.size()):
		var ring := RINGS[i]
		var diff = abs(pos.distance_to(SUN_POS) - float(ring["radius"]))
		if diff < 34.0 and diff < best_diff:
			best = {"index": i, "name": ring["name"]}
			best_diff = diff
	return best


func _tower_position(tower: Dictionary) -> Vector2:
	var ring := RINGS[int(tower["ring"])]
	return SUN_POS + Vector2(cos(float(tower["angle"])), sin(float(tower["angle"]))) * float(ring["radius"])


func _tower_config(tower_type: String) -> Dictionary:
	return TOWER_CONFIGS.get(tower_type, TOWER_CONFIGS["photon_splitter"])


func _enemy_config(variant: String) -> Dictionary:
	return ENEMY_CONFIGS.get(variant, ENEMY_CONFIGS["drifter"])


func _set_message(text: String, duration := 0.0) -> void:
	message_text = text
	message_timer = duration
	_update_ui()


func _update_ui() -> void:
	if ui.is_empty():
		return

	ui["wave_label"].text = "Wave %d/%d" % [GameState.current_wave, MAX_WAVES]
	ui["credits_label"].text = "Sol %d" % GameState.sol_credits
	ui["sun_label"].text = "Sun %d%%" % GameState.get_luminosity_percent()
	ui["score_label"].text = "Score %d" % GameState.performance_score

	var next_wave := min(GameState.current_wave + 1, MAX_WAVES)
	ui["start_button"].text = "Start Wave %d" % next_wave
	ui["start_button"].disabled = GameState.game_phase != GameState.Phase.BETWEEN_WAVE

	for tower_type in TOWER_ORDER:
		var button: Button = ui["tower_buttons"][tower_type]
		var cost := GameState.get_tower_cost(tower_type)
		var label := "%s (%d)" % [_tower_config(tower_type)["label"], cost]
		button.text = "[%s]" % label if tower_type == selected_tower else label
		button.disabled = GameState.game_phase != GameState.Phase.BETWEEN_WAVE or not GameState.can_afford(cost)

	ui["message_label"].text = message_text
