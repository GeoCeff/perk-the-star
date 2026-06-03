class_name TutorialOverlay
extends Control

# Optional first-run tutorial. game.gd provides live target rectangles, then
# this overlay draws highlights and arrows over the real HUD/board.

signal tutorial_finished
signal tutorial_skipped

const SpaceTheme = preload("res://scripts/ui/space_theme.gd")

const PANEL_MIN_SIZE: Vector2 = Vector2(470.0, 248.0)
const EDGE_MARGIN: float = 28.0
const TARGET_GROW: float = 8.0

const STEPS: Array = [
	{
		"target": "sun",
		"placement": "left_of_target",
		"title": "DEFEND THE SUN",
		"body": "This is the defense field. Astrophages push inward toward the sun; keep luminosity alive by building towers on the orbital rings.",
	},
	{
		"target": "tower_bay",
		"placement": "above_target",
		"title": "CHOOSE A TOWER",
		"body": "The Tower Bay is your build tray. Pick a tower before or during a wave. Hover a tower any time to read its role, damage, range, and cautions.",
	},
	{
		"target": "slot",
		"placement": "right_of_target",
		"title": "BUILD ON ORBITAL SLOTS",
		"body": "Click one of the small guide slots on a ring to place the selected tower. Click an existing tower later to upgrade it, sell it, or inspect its range.",
	},
	{
		"target": "start_wave",
		"placement": "below_target",
		"title": "START THE WAVE",
		"body": "Start the next wave here when ready, or enable Auto Start beside it to launch ready waves after a short countdown. You can still spend earned Sol while enemies are moving.",
	},
	{
		"target": "wave_intel",
		"placement": "left_of_target",
		"title": "READ WAVE INTEL",
		"body": "Wave Intel previews the next enemy group, reward, and ring notes. Use it to decide what to build before committing.",
	},
	{
		"target": "status",
		"placement": "below_target",
		"title": "WATCH STATUS AND CAMERA",
		"body": "Sol, score, kills, flare, and luminosity live here. Press F when flare reads ready. Use WASD, edge hover, or right/middle drag to pan; mouse wheel zooms and Center Sun snaps back.",
	},
]

var target_provider: Callable
var step_index: int = 0
var panel: PanelContainer
var step_label: Label
var title_label: Label
var body_label: Label
var save_note_label: Label
var back_button: Button
var next_button: Button
var skip_button: Button


func set_target_provider(provider: Callable) -> void:
	target_provider = provider


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_build_panel()
	_apply_step()
	grab_focus()
	set_process(true)


func _process(_delta: float) -> void:
	size = get_viewport_rect().size
	_position_panel()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_ESCAPE:
			_skip_tutorial()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
			_next_step()
			get_viewport().set_input_as_handled()


func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.0, 0.0, 0.0, 0.50), true)
	_draw_grid(viewport_size)

	var target_info: Dictionary = _current_target_info()
	_draw_target_highlight(target_info)
	_draw_arrow_to_target(target_info)


func _build_panel() -> void:
	panel = PanelContainer.new()
	panel.name = "TutorialPanel"
	panel.custom_minimum_size = PANEL_MIN_SIZE
	panel.size = PANEL_MIN_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "TutorialMargin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.name = "TutorialBox"
	box.add_theme_constant_override("separation", 9)
	margin.add_child(box)

	step_label = Label.new()
	step_label.name = "StepLabel"
	step_label.text = "TRAINING"
	box.add_child(step_label)

	title_label = Label.new()
	title_label.name = "TutorialTitle"
	title_label.text = "TUTORIAL"
	title_label.clip_text = true
	box.add_child(title_label)

	body_label = Label.new()
	body_label.name = "TutorialBody"
	body_label.custom_minimum_size = Vector2(400.0, 74.0)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.text = "Tutorial text."
	box.add_child(body_label)

	save_note_label = Label.new()
	save_note_label.name = "SaveNote"
	save_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_note_label.text = "Skip or Finish saves this tutorial as complete. It will not replay automatically."
	box.add_child(save_note_label)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 8)
	box.add_child(button_row)

	skip_button = Button.new()
	skip_button.text = "SKIP"
	skip_button.custom_minimum_size = Vector2(104.0, 38.0)
	skip_button.pressed.connect(_skip_tutorial)
	button_row.add_child(skip_button)

	back_button = Button.new()
	back_button.text = "BACK"
	back_button.custom_minimum_size = Vector2(104.0, 38.0)
	back_button.pressed.connect(_previous_step)
	button_row.add_child(back_button)

	next_button = Button.new()
	next_button.text = "NEXT"
	next_button.custom_minimum_size = Vector2(126.0, 38.0)
	next_button.pressed.connect(_next_step)
	button_row.add_child(next_button)

	_apply_style()


func _apply_style() -> void:
	SpaceTheme.apply_fonts(self)
	SpaceTheme.apply_deep_panel(panel, SpaceTheme.COLOR_CYAN)
	SpaceTheme.apply_secondary_button(skip_button)
	SpaceTheme.apply_secondary_button(back_button)
	SpaceTheme.apply_primary_button(next_button)

	step_label.add_theme_font_size_override("font_size", 10)
	step_label.add_theme_color_override("font_color", Color(0.34, 0.90, 1.0, 0.88))
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", SpaceTheme.COLOR_GOLD)
	body_label.add_theme_font_size_override("font_size", 15)
	body_label.add_theme_color_override("font_color", SpaceTheme.COLOR_TEXT)
	save_note_label.add_theme_font_size_override("font_size", 11)
	save_note_label.add_theme_color_override("font_color", Color(0.70, 0.84, 0.94, 0.82))
	for button in [skip_button, back_button, next_button]:
		button.add_theme_font_size_override("font_size", 14)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _apply_step() -> void:
	var step: Dictionary = _current_step()
	step_label.text = "MISSION TRAINING %d/%d" % [step_index + 1, STEPS.size()]
	title_label.text = str(step.get("title", "TUTORIAL"))
	body_label.text = str(step.get("body", ""))
	back_button.disabled = step_index == 0
	next_button.text = "FINISH" if step_index >= STEPS.size() - 1 else "NEXT"
	call_deferred("_position_panel")
	queue_redraw()


func _previous_step() -> void:
	if step_index <= 0:
		return
	step_index -= 1
	_apply_step()


func _next_step() -> void:
	if step_index >= STEPS.size() - 1:
		tutorial_finished.emit()
		queue_free()
		return
	step_index += 1
	_apply_step()


func _skip_tutorial() -> void:
	tutorial_skipped.emit()
	queue_free()


func _current_step() -> Dictionary:
	return STEPS[clamp(step_index, 0, STEPS.size() - 1)]


func _target_map() -> Dictionary:
	if target_provider.is_valid():
		var targets = target_provider.call()
		if targets is Dictionary:
			return targets
	return {}


func _current_target_info() -> Dictionary:
	var step: Dictionary = _current_step()
	var target_key: String = str(step.get("target", ""))
	var targets: Dictionary = _target_map()
	var target_info: Dictionary = targets.get(target_key, {})
	if target_info.is_empty():
		return {
			"type": "rect",
			"rect": Rect2(get_viewport_rect().size * 0.5 - Vector2(80.0, 80.0), Vector2(160.0, 160.0)),
		}
	return target_info


func _position_panel() -> void:
	if panel == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = panel.get_combined_minimum_size()
	panel_size.x = maxf(panel_size.x, PANEL_MIN_SIZE.x)
	panel_size.y = maxf(panel_size.y, PANEL_MIN_SIZE.y)
	panel.size = panel_size

	var step: Dictionary = _current_step()
	var target_rect: Rect2 = _target_rect(_current_target_info())
	var placement: String = str(step.get("placement", "bottom_left"))
	var pos: Vector2 = Vector2(EDGE_MARGIN, EDGE_MARGIN)

	match placement:
		"above_target":
			pos = Vector2(target_rect.position.x, target_rect.position.y - panel_size.y - 18.0)
		"below_target":
			pos = Vector2(target_rect.position.x, target_rect.position.y + target_rect.size.y + 18.0)
		"left_of_target":
			pos = Vector2(target_rect.position.x - panel_size.x - 22.0, target_rect.get_center().y - panel_size.y * 0.5)
		"right_of_target":
			pos = Vector2(target_rect.position.x + target_rect.size.x + 22.0, target_rect.get_center().y - panel_size.y * 0.5)
		"top_right":
			pos = Vector2(viewport_size.x - panel_size.x - EDGE_MARGIN, EDGE_MARGIN)
		"bottom_right":
			pos = Vector2(viewport_size.x - panel_size.x - EDGE_MARGIN, viewport_size.y - panel_size.y - EDGE_MARGIN)
		"bottom_left":
			pos = Vector2(EDGE_MARGIN, viewport_size.y - panel_size.y - EDGE_MARGIN)
		_:
			pos = Vector2(EDGE_MARGIN, EDGE_MARGIN)

	panel.position = Vector2(
		clampf(pos.x, EDGE_MARGIN, maxf(EDGE_MARGIN, viewport_size.x - panel_size.x - EDGE_MARGIN)),
		clampf(pos.y, EDGE_MARGIN, maxf(EDGE_MARGIN, viewport_size.y - panel_size.y - EDGE_MARGIN))
	)


func _draw_grid(viewport_size: Vector2) -> void:
	var grid_color: Color = Color(0.16, 0.80, 0.96, 0.055)
	for x in range(0, int(viewport_size.x) + 1, 72):
		draw_line(Vector2(float(x), 0.0), Vector2(float(x), viewport_size.y), grid_color, 1.0)
	for y in range(0, int(viewport_size.y) + 1, 72):
		draw_line(Vector2(0.0, float(y)), Vector2(viewport_size.x, float(y)), grid_color, 1.0)


func _draw_target_highlight(target_info: Dictionary) -> void:
	var accent: Color = SpaceTheme.COLOR_GOLD
	if str(target_info.get("type", "rect")) == "circle":
		var center: Vector2 = target_info.get("center", get_viewport_rect().size * 0.5)
		var radius: float = float(target_info.get("radius", 42.0)) + TARGET_GROW
		draw_circle(center, radius + 10.0, Color(0.22, 0.84, 0.94, 0.08))
		draw_arc(center, radius, 0.0, TAU, 96, accent, 2.4, true)
		draw_arc(center, radius + 8.0, -0.7, 0.7, 32, SpaceTheme.COLOR_CYAN, 2.0, true)
		draw_arc(center, radius + 8.0, PI - 0.7, PI + 0.7, 32, SpaceTheme.COLOR_CYAN, 2.0, true)
		return

	var rect: Rect2 = _target_rect(target_info).grow(TARGET_GROW)
	draw_rect(rect, Color(0.22, 0.84, 0.94, 0.08), true)
	draw_rect(rect, accent, false, 2.0)
	var corner: float = minf(34.0, minf(rect.size.x, rect.size.y) * 0.28)
	_draw_corner(rect.position, Vector2.RIGHT, Vector2.DOWN, corner)
	_draw_corner(rect.position + Vector2(rect.size.x, 0.0), Vector2.LEFT, Vector2.DOWN, corner)
	_draw_corner(rect.position + Vector2(0.0, rect.size.y), Vector2.RIGHT, Vector2.UP, corner)
	_draw_corner(rect.position + rect.size, Vector2.LEFT, Vector2.UP, corner)


func _draw_corner(origin: Vector2, horizontal: Vector2, vertical: Vector2, length: float) -> void:
	draw_line(origin, origin + horizontal * length, SpaceTheme.COLOR_CYAN, 2.0)
	draw_line(origin, origin + vertical * length, SpaceTheme.COLOR_CYAN, 2.0)


func _draw_arrow_to_target(target_info: Dictionary) -> void:
	if panel == null:
		return

	var panel_rect: Rect2 = Rect2(panel.position, panel.size).grow(4.0)
	var target_center: Vector2 = _target_rect(target_info).get_center()
	if str(target_info.get("type", "rect")) == "circle":
		target_center = target_info.get("center", target_center)

	var start: Vector2 = _nearest_panel_edge(panel_rect, target_center)
	var direction: Vector2 = target_center - start
	if direction.length() < 8.0:
		return

	direction = direction.normalized()
	var end: Vector2 = target_center - direction * 16.0
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	draw_line(start, end, Color(1.0, 0.82, 0.28, 0.92), 2.0)
	draw_line(end, end - direction * 15.0 + normal * 8.0, Color(1.0, 0.82, 0.28, 0.92), 2.0)
	draw_line(end, end - direction * 15.0 - normal * 8.0, Color(1.0, 0.82, 0.28, 0.92), 2.0)
	draw_circle(start, 3.0, SpaceTheme.COLOR_CYAN)


func _nearest_panel_edge(panel_rect: Rect2, target_center: Vector2) -> Vector2:
	var panel_center: Vector2 = panel_rect.get_center()
	var delta: Vector2 = target_center - panel_center
	if absf(delta.x / maxf(panel_rect.size.x, 1.0)) > absf(delta.y / maxf(panel_rect.size.y, 1.0)):
		var x: float = panel_rect.position.x + panel_rect.size.x if delta.x > 0.0 else panel_rect.position.x
		return Vector2(x, clampf(target_center.y, panel_rect.position.y, panel_rect.position.y + panel_rect.size.y))

	var y: float = panel_rect.position.y + panel_rect.size.y if delta.y > 0.0 else panel_rect.position.y
	return Vector2(clampf(target_center.x, panel_rect.position.x, panel_rect.position.x + panel_rect.size.x), y)


func _target_rect(target_info: Dictionary) -> Rect2:
	if str(target_info.get("type", "rect")) == "circle":
		var center: Vector2 = target_info.get("center", get_viewport_rect().size * 0.5)
		var radius: float = float(target_info.get("radius", 42.0))
		return Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))
	return target_info.get("rect", Rect2(get_viewport_rect().size * 0.5 - Vector2(80.0, 80.0), Vector2(160.0, 160.0)))
