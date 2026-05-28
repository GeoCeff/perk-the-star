class_name GameHud
extends CanvasLayer

signal start_wave_requested
signal menu_requested
signal tower_selected(tower_type: String)

const TOWER_BUTTON_PATHS: Dictionary = {
	"photon_splitter": "Hud/BottomRow/TowerPanel/TowerRow/TowerScroll/TowerButtons/PhotonButton",
	"cryo_probe": "Hud/BottomRow/TowerPanel/TowerRow/TowerScroll/TowerButtons/CryoButton",
	"bio_lab": "Hud/BottomRow/TowerPanel/TowerRow/TowerScroll/TowerButtons/BioLabButton",
	"magnetic_net": "Hud/BottomRow/TowerPanel/TowerRow/TowerScroll/TowerButtons/MagneticNetButton",
	"helios_cannon": "Hud/BottomRow/TowerPanel/TowerRow/TowerScroll/TowerButtons/HeliosButton",
	"tardigrade_bomb": "Hud/BottomRow/TowerPanel/TowerRow/TowerScroll/TowerButtons/TardigradeButton",
}

@onready var wave_label: Label = $Hud/TopPanel/TopRow/WaveBlock/WaveLabel
@onready var brief_label: Label = $Hud/TopPanel/TopRow/WaveBlock/BriefLabel
@onready var credits_label: Label = $Hud/TopPanel/TopRow/StatsGrid/SolStat/CreditsLabel
@onready var score_label: Label = $Hud/TopPanel/TopRow/StatsGrid/ScoreStat/ScoreLabel
@onready var kills_label: Label = $Hud/TopPanel/TopRow/StatsGrid/KillsStat/KillsLabel
@onready var flare_label: Label = $Hud/TopPanel/TopRow/StatsGrid/FlareStat/FlareLabel
@onready var luminosity_bar: ProgressBar = $Hud/TopPanel/TopRow/LuminosityBox/LuminosityBar
@onready var start_button: Button = $Hud/TopPanel/TopRow/ActionRow/StartButton
@onready var menu_button: Button = $Hud/TopPanel/TopRow/ActionRow/MenuButton
@onready var enemy_preview: TextureRect = $Hud/WaveIntel/IntelBox/EnemyRow/EnemyPreview
@onready var enemy_label: Label = $Hud/WaveIntel/IntelBox/EnemyRow/EnemyText/EnemyLabel
@onready var threat_label: Label = $Hud/WaveIntel/IntelBox/EnemyRow/EnemyText/ThreatLabel
@onready var ring_label: Label = $Hud/WaveIntel/IntelBox/RingLabel
@onready var message_label: Label = $Hud/BottomRow/MessagePanel/MessageLabel

var tower_buttons: Dictionary = {}


func _ready() -> void:
	_bind_buttons()
	_apply_styles()


func update_view(state: Dictionary) -> void:
	_set_label_text(wave_label, str(state.get("wave_title", "")))
	_set_label_text(brief_label, str(state.get("brief", "")))
	_set_label_text(credits_label, str(state.get("credits", "0")))
	_set_label_text(score_label, str(state.get("score", "0")))
	_set_label_text(kills_label, str(state.get("kills", "0")))
	_set_label_text(flare_label, str(state.get("flare", "Charging")))
	_set_progress_value(luminosity_bar, float(state.get("luminosity", 100.0)))
	_set_texture(enemy_preview, state.get("enemy_texture", null))
	_set_label_text(enemy_label, str(state.get("enemy_summary", "")))
	_set_label_text(threat_label, str(state.get("threat", "")))
	_set_label_text(ring_label, str(state.get("rings", "")))
	_set_button_text(start_button, str(state.get("start_text", "Start Wave")))
	_set_button_disabled(start_button, bool(state.get("start_disabled", false)))
	_set_label_text(message_label, str(state.get("message", "")))
	_update_tower_buttons(state.get("tower_buttons", {}))


func _bind_buttons() -> void:
	tower_buttons.clear()
	start_button.pressed.connect(_on_start_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)

	for tower_type in TOWER_BUTTON_PATHS.keys():
		var button: Button = get_node_or_null(str(TOWER_BUTTON_PATHS[tower_type])) as Button
		if button == null:
			push_error("GameHud: missing tower button at %s." % TOWER_BUTTON_PATHS[tower_type])
			continue
		tower_buttons[tower_type] = button
		button.pressed.connect(_on_tower_button_pressed.bind(str(tower_type)))


func _on_start_button_pressed() -> void:
	start_wave_requested.emit()


func _on_menu_button_pressed() -> void:
	menu_requested.emit()


func _on_tower_button_pressed(tower_type: String) -> void:
	tower_selected.emit(tower_type)


func _update_tower_buttons(button_states) -> void:
	if not (button_states is Dictionary):
		return

	for tower_type in tower_buttons.keys():
		var button: Button = tower_buttons[tower_type]
		var state: Dictionary = button_states.get(tower_type, {})
		_set_button_text(button, str(state.get("text", button.text)))
		button.tooltip_text = str(state.get("tooltip", button.tooltip_text))
		_set_button_disabled(button, bool(state.get("disabled", false)))
		_set_button_pressed(button, bool(state.get("pressed", false)))
		_set_button_icon(button, state.get("icon", null))


func _set_label_text(label: Label, text: String) -> void:
	if label.text != text:
		label.text = text


func _set_button_text(button: Button, text: String) -> void:
	if button.text != text:
		button.text = text


func _set_button_disabled(button: Button, disabled: bool) -> void:
	if button.disabled != disabled:
		button.disabled = disabled


func _set_button_pressed(button: Button, pressed: bool) -> void:
	if button.button_pressed != pressed:
		button.set_pressed_no_signal(pressed)


func _set_button_icon(button: Button, icon) -> void:
	if button.icon != icon:
		button.icon = icon


func _set_progress_value(bar: ProgressBar, value: float) -> void:
	if not is_equal_approx(float(bar.value), value):
		bar.value = value


func _set_texture(preview: TextureRect, texture) -> void:
	if preview.texture != texture:
		preview.texture = texture


func _apply_styles() -> void:
	$Hud/TopPanel.add_theme_stylebox_override("panel", _panel_style(Color(0.020, 0.027, 0.040, 0.94), Color(0.28, 0.47, 0.68, 0.52), 5.0, 12.0, 8.0))
	$Hud/WaveIntel.add_theme_stylebox_override("panel", _panel_style(Color(0.020, 0.025, 0.035, 0.92), Color(0.48, 0.34, 0.68, 0.45), 5.0, 12.0, 10.0))
	$Hud/BottomRow/TowerPanel.add_theme_stylebox_override("panel", _panel_style(Color(0.020, 0.027, 0.038, 0.93), Color(0.30, 0.56, 0.70, 0.46), 5.0, 12.0, 7.0))
	$Hud/BottomRow/MessagePanel.add_theme_stylebox_override("panel", _panel_style(Color(0.032, 0.032, 0.038, 0.91), Color(0.72, 0.55, 0.20, 0.46), 5.0, 14.0, 8.0))

	luminosity_bar.add_theme_stylebox_override("background", _bar_style(Color(0.12, 0.15, 0.19, 0.95), 4.0))
	luminosity_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.94, 0.74, 0.32, 0.95), 4.0))

	start_button.add_theme_stylebox_override("normal", _button_style(Color(0.93, 0.66, 0.22, 0.96), Color(1.0, 0.82, 0.42, 0.55), 5.0))
	start_button.add_theme_stylebox_override("hover", _button_style(Color(1.0, 0.74, 0.27, 1.0), Color(1.0, 0.88, 0.55, 0.75), 5.0))
	start_button.add_theme_stylebox_override("pressed", _button_style(Color(0.78, 0.48, 0.14, 1.0), Color(1.0, 0.75, 0.32, 0.70), 5.0))
	start_button.add_theme_color_override("font_color", Color(0.06, 0.07, 0.09))

	menu_button.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.10, 0.14, 0.96), Color(0.32, 0.42, 0.54, 0.42), 5.0))
	menu_button.add_theme_stylebox_override("hover", _button_style(Color(0.12, 0.15, 0.20, 0.98), Color(0.48, 0.62, 0.76, 0.56), 5.0))

	for button in tower_buttons.values():
		button.add_theme_stylebox_override("normal", _button_style(Color(0.06, 0.075, 0.095, 0.94), Color(0.26, 0.38, 0.50, 0.35), 4.0))
		button.add_theme_stylebox_override("hover", _button_style(Color(0.09, 0.115, 0.145, 0.98), Color(0.40, 0.58, 0.72, 0.50), 4.0))
		button.add_theme_stylebox_override("pressed", _button_style(Color(0.12, 0.18, 0.20, 1.0), Color(0.94, 0.72, 0.28, 0.78), 4.0))


func _panel_style(bg_color: Color, border_color: Color, radius: float, horizontal_margin: float, vertical_margin: float) -> StyleBoxFlat:
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
