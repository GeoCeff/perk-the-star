class_name GameHud
extends CanvasLayer

# HUD controller for gameplay.
# It displays the state sent by game.gd and emits signals when the player
# presses buttons. It does not decide combat rules.

signal start_wave_requested
signal auto_start_toggled(enabled: bool)
signal menu_requested
signal tower_selected(tower_type: String)
signal tower_upgrade_requested(ring_index: int, slot_index: int)
signal tower_sell_requested(ring_index: int, slot_index: int)
signal tower_manage_closed()
signal recenter_requested
signal retry_requested
signal main_menu_requested

const SpaceTheme = preload("res://scripts/ui/space_theme.gd")

const TOWER_BUTTON_PATHS: Dictionary = {
	"photon_splitter": "Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll/TowerButtons/PhotonButton",
	"cryo_probe": "Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll/TowerButtons/CryoButton",
	"bio_lab": "Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll/TowerButtons/BioLabButton",
	"magnetic_net": "Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll/TowerButtons/MagneticNetButton",
	"helios_cannon": "Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll/TowerButtons/HeliosButton",
	"tardigrade_bomb": "Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll/TowerButtons/TardigradeButton",
}

# Kept in sync with GameCatalog colors so hover cards, buttons, and tower
# highlights all speak the same visual language.
const TOWER_ACCENTS: Dictionary = {
	"photon_splitter": Color(1.0, 0.86, 0.28),
	"cryo_probe": Color(0.34, 0.86, 1.0),
	"bio_lab": Color(0.46, 1.0, 0.52),
	"magnetic_net": Color(0.76, 0.62, 1.0),
	"helios_cannon": Color(1.0, 0.43, 0.22),
	"tardigrade_bomb": Color(1.0, 0.58, 0.76),
}

@onready var wave_kicker: Label = $Hud/TopPanel/WaveBlock/WaveKicker
@onready var wave_label: Label = $Hud/TopPanel/WaveBlock/WaveLabel
@onready var brief_label: Label = $Hud/TopPanel/WaveBlock/BriefLabel
@onready var credits_label: Label = $Hud/StatusPanel/StatusRow/StatsGrid/SolStat/CreditsLabel
@onready var score_label: Label = $Hud/StatusPanel/StatusRow/StatsGrid/ScoreStat/ScoreLabel
@onready var kills_label: Label = $Hud/StatusPanel/StatusRow/StatsGrid/KillsStat/KillsLabel
@onready var flare_label: Label = $Hud/StatusPanel/StatusRow/StatsGrid/FlareStat/FlareLabel
@onready var luminosity_bar: ProgressBar = $Hud/StatusPanel/StatusRow/LuminosityBox/LuminosityBar
@onready var start_button: Button = $Hud/ActionsPanel/ActionRow/StartButton
@onready var auto_start_button: Button = $Hud/ActionsPanel/ActionRow/AutoStartButton
@onready var menu_button: Button = $Hud/ActionsPanel/ActionRow/MenuButton
@onready var top_panel: PanelContainer = $Hud/TopPanel
@onready var status_panel: PanelContainer = $Hud/StatusPanel
@onready var actions_panel: PanelContainer = $Hud/ActionsPanel
@onready var wave_intel_panel: PanelContainer = $Hud/WaveIntel
@onready var tower_panel: PanelContainer = $Hud/BottomRow/TowerPanel
@onready var hud_root: Control = $Hud
@onready var tower_scroll: ScrollContainer = $Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll
@onready var center_view_button: Button = $Hud/BottomRow/TowerPanel/TowerBox/TowerRow/CenterViewButton
@onready var message_panel: PanelContainer = $Hud/BottomRow/MessagePanel
@onready var selected_tower_label: Label = $Hud/BottomRow/TowerPanel/TowerBox/TowerHeader/SelectedTowerLabel
@onready var enemy_preview: TextureRect = $Hud/WaveIntel/IntelBox/EnemyRow/EnemyPreview
@onready var intel_status_label: Label = $Hud/WaveIntel/IntelBox/IntelHeader/IntelStatus
@onready var enemy_label: Label = $Hud/WaveIntel/IntelBox/EnemyRow/EnemyText/EnemyLabel
@onready var threat_label: Label = $Hud/WaveIntel/IntelBox/EnemyRow/EnemyText/ThreatLabel
@onready var ring_label: Label = $Hud/WaveIntel/IntelBox/RingLabel
@onready var message_label: Label = $Hud/BottomRow/MessagePanel/MessageBox/MessageLabel

var tower_buttons: Dictionary = {}
var tower_info_states: Dictionary = {}
var hovered_tower_type: String = ""
var tower_info_card: PanelContainer
var tower_info_title_label: Label
var tower_info_role_label: Label
var tower_info_stats_label: Label
var tower_info_body_label: Label
var tower_info_note_label: Label
var tower_manage_card: PanelContainer
var tower_manage_title_label: Label
var tower_manage_meta_label: Label
var tower_manage_stats_label: Label
var tower_manage_economy_label: Label
var tower_manage_upgrade_button: Button
var tower_manage_sell_button: Button
var tower_manage_close_button: Button
var managed_tower_ring: int = -1
var managed_tower_slot: int = -1
var end_state_panel: PanelContainer
var end_state_title_label: Label
var end_state_subtitle_label: Label
var end_state_rank_label: Label
var end_state_stats_label: Label
var end_state_tip_label: Label
var end_state_retry_button: Button
var end_state_main_menu_button: Button


func _ready() -> void:
	_bind_buttons()
	_build_tower_info_card()
	_build_tower_manage_card()
	_build_end_state_card()
	_apply_styles()
	_fit_layout_to_viewport()
	if not get_viewport().size_changed.is_connected(_fit_layout_to_viewport):
		get_viewport().size_changed.connect(_fit_layout_to_viewport)


func update_view(state: Dictionary) -> void:
	# game.gd sends one compact state dictionary each refresh. This keeps the
	# HUD reusable and prevents UI code from reaching into gameplay arrays.
	_set_label_text(wave_label, str(state.get("wave_title", "")))
	_set_label_text(brief_label, str(state.get("brief", "")))
	_set_label_text(credits_label, str(state.get("credits", "0")))
	_set_label_text(score_label, str(state.get("score", "0")))
	_set_label_text(kills_label, str(state.get("kills", "0")))
	_set_label_text(flare_label, str(state.get("flare", "CHARGING")))
	_set_progress_value(luminosity_bar, float(state.get("luminosity", 100.0)))
	_set_texture(enemy_preview, state.get("enemy_texture", null))
	_set_label_text(intel_status_label, str(state.get("intel_status", "NEXT")))
	_set_label_text(enemy_label, str(state.get("enemy_summary", "")))
	_set_label_text(threat_label, str(state.get("threat", "")))
	_set_label_text(ring_label, str(state.get("rings", "")))
	_set_button_text(start_button, str(state.get("start_text", "START WAVE")))
	_set_button_disabled(start_button, bool(state.get("start_disabled", false)))
	_set_auto_start_button(bool(state.get("auto_start_enabled", false)))
	_set_label_text(message_label, str(state.get("message", "")))
	_set_label_text(selected_tower_label, str(state.get("selected_tower", "")))
	_update_tower_buttons(state.get("tower_buttons", {}))
	_update_tower_manage_card(state.get("managed_tower", {}))
	_update_end_state_card(state.get("end_state", {}))


func _bind_buttons() -> void:
	tower_buttons.clear()
	start_button.pressed.connect(_on_start_button_pressed)
	auto_start_button.toggled.connect(_on_auto_start_button_toggled)
	menu_button.pressed.connect(_on_menu_button_pressed)
	center_view_button.pressed.connect(_on_center_view_button_pressed)

	for tower_type in TOWER_BUTTON_PATHS.keys():
		var button: Button = get_node_or_null(str(TOWER_BUTTON_PATHS[tower_type])) as Button
		if button == null:
			push_error("GameHud: missing tower button at %s." % TOWER_BUTTON_PATHS[tower_type])
			continue
		tower_buttons[tower_type] = button
		button.pressed.connect(_on_tower_button_pressed.bind(str(tower_type)))
		button.mouse_entered.connect(_show_tower_info.bind(str(tower_type)))
		button.mouse_exited.connect(_hide_tower_info.bind(str(tower_type)))
		button.focus_entered.connect(_show_tower_info.bind(str(tower_type)))
		button.focus_exited.connect(_hide_tower_info.bind(str(tower_type)))


func _on_start_button_pressed() -> void:
	start_wave_requested.emit()


func _on_auto_start_button_toggled(enabled: bool) -> void:
	auto_start_toggled.emit(enabled)


func _on_menu_button_pressed() -> void:
	menu_requested.emit()


func _on_tower_button_pressed(tower_type: String) -> void:
	tower_selected.emit(tower_type)


func _on_tower_manage_upgrade_pressed() -> void:
	if managed_tower_ring < 0 or managed_tower_slot < 0:
		return
	tower_upgrade_requested.emit(managed_tower_ring, managed_tower_slot)


func _on_tower_manage_sell_pressed() -> void:
	if managed_tower_ring < 0 or managed_tower_slot < 0:
		return
	tower_sell_requested.emit(managed_tower_ring, managed_tower_slot)


func _on_tower_manage_close_pressed() -> void:
	tower_manage_closed.emit()


func _on_center_view_button_pressed() -> void:
	recenter_requested.emit()


func _on_end_retry_pressed() -> void:
	retry_requested.emit()


func _on_end_main_menu_pressed() -> void:
	main_menu_requested.emit()


func is_screen_position_over_hud(screen_position: Vector2) -> bool:
	for control in [top_panel, status_panel, actions_panel, wave_intel_panel, tower_panel, message_panel, tower_info_card, tower_manage_card, end_state_panel]:
		if control != null and control.visible and control.get_global_rect().has_point(screen_position):
			return true
	return false


func get_tutorial_targets() -> Dictionary:
	var photon_button: Button = tower_buttons.get("photon_splitter", null) as Button
	return {
		"mission": _control_target(top_panel),
		"status": _control_target(status_panel),
		"luminosity": _control_target(luminosity_bar),
		"start_wave": _control_target(start_button),
		"auto_start": _control_target(auto_start_button),
		"menu": _control_target(menu_button),
		"wave_intel": _control_target(wave_intel_panel),
		"tower_bay": _control_target(tower_panel),
		"tower_button": _control_target(photon_button),
		"center_sun": _control_target(center_view_button),
		"message": _control_target(message_panel),
	}


func _control_target(control: Control) -> Dictionary:
	if control == null:
		return {}
	return {
		"type": "rect",
		"rect": control.get_global_rect(),
	}


func _build_tower_info_card() -> void:
	# Built in script because it is a temporary hover card, not a main scene.
	tower_info_card = PanelContainer.new()
	tower_info_card.name = "TowerInfoCard"
	tower_info_card.custom_minimum_size = Vector2(382.0, 178.0)
	tower_info_card.size = tower_info_card.custom_minimum_size
	tower_info_card.visible = false
	tower_info_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tower_info_card.z_index = 60
	hud_root.add_child(tower_info_card)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "TowerInfoMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	tower_info_card.add_child(margin)

	var root_row: HBoxContainer = HBoxContainer.new()
	root_row.name = "TowerInfoRoot"
	root_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_row.add_theme_constant_override("separation", 10)
	margin.add_child(root_row)

	var accent_bar: ColorRect = ColorRect.new()
	accent_bar.name = "TowerInfoAccent"
	accent_bar.custom_minimum_size = Vector2(3.0, 0.0)
	accent_bar.color = SpaceTheme.COLOR_GOLD
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_row.add_child(accent_bar)

	var content_box: VBoxContainer = VBoxContainer.new()
	content_box.name = "TowerInfoContent"
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_box.add_theme_constant_override("separation", 5)
	root_row.add_child(content_box)

	tower_info_title_label = Label.new()
	tower_info_title_label.name = "TowerInfoTitle"
	tower_info_title_label.text = "TOWER"
	tower_info_title_label.clip_text = true
	content_box.add_child(tower_info_title_label)

	tower_info_role_label = Label.new()
	tower_info_role_label.name = "TowerInfoRole"
	tower_info_role_label.text = "ROLE"
	content_box.add_child(tower_info_role_label)

	tower_info_stats_label = Label.new()
	tower_info_stats_label.name = "TowerInfoStats"
	tower_info_stats_label.text = "DAMAGE 0  |  RATE 0/S  |  RANGE 0"
	tower_info_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(tower_info_stats_label)

	tower_info_body_label = Label.new()
	tower_info_body_label.name = "TowerInfoBody"
	tower_info_body_label.custom_minimum_size = Vector2(320.0, 42.0)
	tower_info_body_label.text = "Tower description."
	tower_info_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(tower_info_body_label)

	tower_info_note_label = Label.new()
	tower_info_note_label.name = "TowerInfoNote"
	tower_info_note_label.text = "NOTE"
	tower_info_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(tower_info_note_label)


func _build_tower_manage_card() -> void:
	# Also built in script so it can track the selected tower without adding
	# another permanent scene file.
	tower_manage_card = PanelContainer.new()
	tower_manage_card.name = "TowerManageCard"
	tower_manage_card.custom_minimum_size = Vector2(438.0, 174.0)
	tower_manage_card.size = tower_manage_card.custom_minimum_size
	tower_manage_card.visible = false
	tower_manage_card.mouse_filter = Control.MOUSE_FILTER_STOP
	tower_manage_card.z_index = 58
	hud_root.add_child(tower_manage_card)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "TowerManageMargin"
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	tower_manage_card.add_child(margin)

	var root_box: VBoxContainer = VBoxContainer.new()
	root_box.name = "TowerManageRoot"
	root_box.add_theme_constant_override("separation", 7)
	margin.add_child(root_box)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.name = "TowerManageHeader"
	header_row.add_theme_constant_override("separation", 8)
	root_box.add_child(header_row)

	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.name = "TowerManageTitleBox"
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 1)
	header_row.add_child(title_box)

	tower_manage_title_label = Label.new()
	tower_manage_title_label.name = "TowerManageTitle"
	tower_manage_title_label.clip_text = true
	title_box.add_child(tower_manage_title_label)

	tower_manage_meta_label = Label.new()
	tower_manage_meta_label.name = "TowerManageMeta"
	tower_manage_meta_label.clip_text = true
	title_box.add_child(tower_manage_meta_label)

	tower_manage_close_button = Button.new()
	tower_manage_close_button.name = "TowerManageCloseButton"
	tower_manage_close_button.custom_minimum_size = Vector2(40.0, 34.0)
	tower_manage_close_button.text = "X"
	tower_manage_close_button.pressed.connect(_on_tower_manage_close_pressed)
	header_row.add_child(tower_manage_close_button)

	tower_manage_stats_label = Label.new()
	tower_manage_stats_label.name = "TowerManageStats"
	tower_manage_stats_label.custom_minimum_size = Vector2(0.0, 34.0)
	tower_manage_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(tower_manage_stats_label)

	tower_manage_economy_label = Label.new()
	tower_manage_economy_label.name = "TowerManageEconomy"
	tower_manage_economy_label.clip_text = true
	root_box.add_child(tower_manage_economy_label)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.name = "TowerManageActions"
	action_row.add_theme_constant_override("separation", 8)
	root_box.add_child(action_row)

	tower_manage_upgrade_button = Button.new()
	tower_manage_upgrade_button.name = "TowerManageUpgradeButton"
	tower_manage_upgrade_button.custom_minimum_size = Vector2(148.0, 40.0)
	tower_manage_upgrade_button.text = "UPGRADE"
	tower_manage_upgrade_button.pressed.connect(_on_tower_manage_upgrade_pressed)
	action_row.add_child(tower_manage_upgrade_button)

	tower_manage_sell_button = Button.new()
	tower_manage_sell_button.name = "TowerManageSellButton"
	tower_manage_sell_button.custom_minimum_size = Vector2(120.0, 40.0)
	tower_manage_sell_button.text = "SELL"
	tower_manage_sell_button.pressed.connect(_on_tower_manage_sell_pressed)
	action_row.add_child(tower_manage_sell_button)


func _build_end_state_card() -> void:
	end_state_panel = PanelContainer.new()
	end_state_panel.name = "EndStateCard"
	end_state_panel.custom_minimum_size = Vector2(620.0, 304.0)
	end_state_panel.size = end_state_panel.custom_minimum_size
	end_state_panel.visible = false
	end_state_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	end_state_panel.z_index = 90
	hud_root.add_child(end_state_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "EndStateMargin"
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	end_state_panel.add_child(margin)

	var root_box: VBoxContainer = VBoxContainer.new()
	root_box.name = "EndStateRoot"
	root_box.add_theme_constant_override("separation", 10)
	margin.add_child(root_box)

	end_state_title_label = Label.new()
	end_state_title_label.name = "EndStateTitle"
	end_state_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_box.add_child(end_state_title_label)

	end_state_subtitle_label = Label.new()
	end_state_subtitle_label.name = "EndStateSubtitle"
	end_state_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_state_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(end_state_subtitle_label)

	end_state_rank_label = Label.new()
	end_state_rank_label.name = "EndStateRank"
	end_state_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_box.add_child(end_state_rank_label)

	end_state_stats_label = Label.new()
	end_state_stats_label.name = "EndStateStats"
	end_state_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_state_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(end_state_stats_label)

	end_state_tip_label = Label.new()
	end_state_tip_label.name = "EndStateTip"
	end_state_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_state_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(end_state_tip_label)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.name = "EndStateButtons"
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)
	root_box.add_child(button_row)

	end_state_retry_button = Button.new()
	end_state_retry_button.name = "EndStateRetryButton"
	end_state_retry_button.custom_minimum_size = Vector2(156.0, 44.0)
	end_state_retry_button.text = "RETRY RUN"
	end_state_retry_button.pressed.connect(_on_end_retry_pressed)
	button_row.add_child(end_state_retry_button)

	end_state_main_menu_button = Button.new()
	end_state_main_menu_button.name = "EndStateMainMenuButton"
	end_state_main_menu_button.custom_minimum_size = Vector2(156.0, 44.0)
	end_state_main_menu_button.text = "MAIN MENU"
	end_state_main_menu_button.pressed.connect(_on_end_main_menu_pressed)
	button_row.add_child(end_state_main_menu_button)


func _update_tower_buttons(button_states) -> void:
	if not (button_states is Dictionary):
		return

	for tower_type in tower_buttons.keys():
		var button: Button = tower_buttons[tower_type] as Button
		var state: Dictionary = button_states.get(tower_type, {})
		_set_button_text(button, str(state.get("text", button.text)))
		button.tooltip_text = ""
		tower_info_states[tower_type] = state.get("info", {})
		_set_button_disabled(button, bool(state.get("disabled", false)))
		_set_button_pressed(button, bool(state.get("pressed", false)))
		_set_button_icon(button, state.get("icon", null))
		_apply_tower_button_state(button, str(tower_type), button.button_pressed, button.disabled)
		if tower_info_card != null and tower_info_card.visible and hovered_tower_type == tower_type:
			_populate_tower_info_card(str(tower_type))


func _update_tower_manage_card(managed_state) -> void:
	if tower_manage_card == null:
		return
	if not (managed_state is Dictionary) or managed_state.is_empty():
		managed_tower_ring = -1
		managed_tower_slot = -1
		tower_manage_card.visible = false
		return

	var state: Dictionary = managed_state
	managed_tower_ring = int(state.get("ring_index", -1))
	managed_tower_slot = int(state.get("slot_index", -1))
	tower_manage_title_label.text = str(state.get("title", "TOWER")).to_upper()
	tower_manage_meta_label.text = str(state.get("meta", "ORBITAL NODE"))
	tower_manage_stats_label.text = str(state.get("stats", ""))
	tower_manage_economy_label.text = str(state.get("economy", ""))
	tower_manage_upgrade_button.text = str(state.get("upgrade_text", "UPGRADE"))
	tower_manage_sell_button.text = str(state.get("sell_text", "SELL"))
	tower_manage_upgrade_button.disabled = bool(state.get("upgrade_disabled", false))
	tower_manage_sell_button.disabled = bool(state.get("sell_disabled", false))

	var accent: Color = state.get("accent", SpaceTheme.COLOR_GOLD)
	tower_manage_card.add_theme_stylebox_override("panel", _hud_panel_style(accent, 14.0, 12.0))
	tower_manage_title_label.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 1.0))
	var upgrade_accent: Color = SpaceTheme.COLOR_CYAN if tower_manage_upgrade_button.disabled else SpaceTheme.COLOR_GOLD
	_apply_action_button(tower_manage_upgrade_button, upgrade_accent, "")
	_apply_action_button(tower_manage_sell_button, SpaceTheme.COLOR_CYAN, "")
	_apply_action_button(tower_manage_close_button, SpaceTheme.COLOR_CYAN, "")
	_position_tower_manage_card()
	if tower_info_card != null:
		tower_info_card.visible = false
	tower_manage_card.visible = true


func _update_end_state_card(end_state) -> void:
	if end_state_panel == null:
		return
	if not (end_state is Dictionary) or end_state.is_empty():
		end_state_panel.visible = false
		return

	var state: Dictionary = end_state
	var victory: bool = bool(state.get("victory", false))
	var accent: Color = SpaceTheme.COLOR_GOLD if victory else Color(1.0, 0.28, 0.18, 0.92)
	end_state_panel.add_theme_stylebox_override("panel", _hud_panel_style(accent, 16.0, 16.0))
	end_state_title_label.text = str(state.get("title", "MISSION COMPLETE")).to_upper()
	end_state_title_label.add_theme_color_override("font_color", accent)
	end_state_subtitle_label.text = str(state.get("subtitle", ""))
	end_state_rank_label.text = str(state.get("rank", ""))
	end_state_stats_label.text = str(state.get("stats", ""))
	end_state_tip_label.text = str(state.get("tip", ""))
	_position_end_state_card()
	end_state_panel.visible = true
	if not end_state_retry_button.has_focus() and not end_state_main_menu_button.has_focus():
		end_state_retry_button.grab_focus()


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


func _fit_layout_to_viewport() -> void:
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	var compact: bool = viewport_width < 1500.0
	if compact:
		top_panel.offset_right = maxf(460.0, minf(660.0, viewport_width - 436.0))
		status_panel.offset_left = -1060.0
		status_panel.offset_right = -426.0
		status_panel.offset_top = 140.0
		status_panel.offset_bottom = 246.0
		wave_intel_panel.offset_top = 264.0
		wave_intel_panel.offset_bottom = 512.0
	else:
		top_panel.offset_right = 820.0
		status_panel.offset_left = -1060.0
		status_panel.offset_right = -426.0
		status_panel.offset_top = 18.0
		status_panel.offset_bottom = 124.0
		wave_intel_panel.offset_top = 146.0
		wave_intel_panel.offset_bottom = 394.0
	if tower_info_card != null and tower_info_card.visible and hovered_tower_type != "":
		_position_tower_info_card(hovered_tower_type)
	if tower_manage_card != null and tower_manage_card.visible:
		_position_tower_manage_card()
	if end_state_panel != null and end_state_panel.visible:
		_position_end_state_card()


func _apply_styles() -> void:
	SpaceTheme.apply_fonts(self)
	top_panel.add_theme_stylebox_override("panel", _hud_panel_style(SpaceTheme.COLOR_CYAN, 15.0, 10.0))
	status_panel.add_theme_stylebox_override("panel", _hud_panel_style(SpaceTheme.COLOR_CYAN, 13.0, 10.0))
	actions_panel.add_theme_stylebox_override("panel", _hud_panel_style(SpaceTheme.COLOR_GOLD, 10.0, 12.0))
	wave_intel_panel.add_theme_stylebox_override("panel", _hud_panel_style(SpaceTheme.COLOR_CYAN, 14.0, 12.0))
	tower_panel.add_theme_stylebox_override("panel", _hud_panel_style(SpaceTheme.COLOR_CYAN, 13.0, 10.0))
	message_panel.add_theme_stylebox_override("panel", _hud_panel_style(SpaceTheme.COLOR_GOLD, 13.0, 12.0))
	SpaceTheme.apply_scroll_container(tower_scroll)
	_apply_readability_overrides()

	luminosity_bar.add_theme_stylebox_override("background", SpaceTheme.progress_background_style())
	luminosity_bar.add_theme_stylebox_override("fill", SpaceTheme.progress_fill_style())
	luminosity_bar.add_theme_font_size_override("font_size", 10)
	luminosity_bar.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0, 1.0))

	_apply_action_button(start_button, SpaceTheme.COLOR_GOLD, SpaceTheme.ICON_PLAY_PATH)
	_apply_action_button(auto_start_button, SpaceTheme.COLOR_CYAN, SpaceTheme.ICON_PLAY_PATH)
	_apply_action_button(menu_button, SpaceTheme.COLOR_CYAN, "")
	_apply_action_button(center_view_button, SpaceTheme.COLOR_CYAN, "")
	start_button.add_theme_font_size_override("font_size", 13)
	auto_start_button.add_theme_font_size_override("font_size", 9)
	menu_button.add_theme_font_size_override("font_size", 12)
	center_view_button.add_theme_font_size_override("font_size", 10)

	for tower_type in tower_buttons.keys():
		var button: Button = tower_buttons[tower_type] as Button
		_apply_tower_button_state(button, str(tower_type), button.button_pressed, button.disabled)


func _apply_readability_overrides() -> void:
	wave_kicker.add_theme_font_size_override("font_size", 10)
	wave_kicker.add_theme_color_override("font_color", Color(0.34, 0.90, 1.0, 0.85))
	wave_label.add_theme_font_size_override("font_size", 21)
	wave_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28, 1.0))
	brief_label.add_theme_font_size_override("font_size", 11)
	brief_label.add_theme_color_override("font_color", Color(0.78, 0.90, 0.98, 0.96))
	selected_tower_label.add_theme_font_size_override("font_size", 10)
	selected_tower_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 0.95))

	var stat_title_paths: Array = [
		"Hud/StatusPanel/StatusRow/StatsGrid/SolStat/SolTitle",
		"Hud/StatusPanel/StatusRow/StatsGrid/ScoreStat/ScoreTitle",
		"Hud/StatusPanel/StatusRow/StatsGrid/KillsStat/KillsTitle",
		"Hud/StatusPanel/StatusRow/StatsGrid/FlareStat/FlareTitle",
	]
	var stat_value_paths: Array = [
		"Hud/StatusPanel/StatusRow/StatsGrid/SolStat/CreditsLabel",
		"Hud/StatusPanel/StatusRow/StatsGrid/ScoreStat/ScoreLabel",
		"Hud/StatusPanel/StatusRow/StatsGrid/KillsStat/KillsLabel",
		"Hud/StatusPanel/StatusRow/StatsGrid/FlareStat/FlareLabel",
	]

	for path in stat_title_paths:
		var title: Label = get_node_or_null(str(path)) as Label
		if title != null:
			title.add_theme_font_size_override("font_size", 10)
			title.add_theme_color_override("font_color", Color(0.52, 0.78, 0.90, 0.92))

	for path in stat_value_paths:
		var value: Label = get_node_or_null(str(path)) as Label
		if value != null:
			value.add_theme_font_size_override("font_size", 18)
			value.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0, 1.0))
	if flare_label != null:
		flare_label.add_theme_font_size_override("font_size", 15)

	enemy_label.add_theme_font_size_override("font_size", 13)
	enemy_label.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0, 0.98))
	enemy_label.add_theme_constant_override("line_spacing", 1)
	intel_status_label.add_theme_font_size_override("font_size", 10)
	intel_status_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 0.95))
	threat_label.add_theme_font_size_override("font_size", 10)
	threat_label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.98, 0.94))
	threat_label.add_theme_constant_override("line_spacing", 2)
	ring_label.add_theme_font_size_override("font_size", 10)
	ring_label.add_theme_color_override("font_color", Color(0.58, 0.78, 0.92, 0.90))
	ring_label.add_theme_constant_override("line_spacing", 1)
	message_label.add_theme_font_size_override("font_size", 13)
	message_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.84, 0.96))

	if tower_info_card != null:
		tower_info_card.add_theme_stylebox_override("panel", _hud_panel_style(SpaceTheme.COLOR_CYAN, 14.0, 12.0))
		tower_info_title_label.add_theme_font_size_override("font_size", 15)
		tower_info_title_label.add_theme_color_override("font_color", SpaceTheme.COLOR_GOLD)
		tower_info_role_label.add_theme_font_size_override("font_size", 10)
		tower_info_role_label.add_theme_color_override("font_color", Color(0.42, 0.90, 1.0, 0.92))
		tower_info_stats_label.add_theme_font_size_override("font_size", 11)
		tower_info_stats_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 0.96))
		tower_info_body_label.add_theme_font_size_override("font_size", 12)
		tower_info_body_label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.98, 0.96))
		tower_info_note_label.add_theme_font_size_override("font_size", 10)
		tower_info_note_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 0.92))
	if tower_manage_card != null:
		tower_manage_card.add_theme_stylebox_override("panel", _hud_panel_style(SpaceTheme.COLOR_GOLD, 14.0, 12.0))
		tower_manage_title_label.add_theme_font_size_override("font_size", 15)
		tower_manage_title_label.add_theme_color_override("font_color", SpaceTheme.COLOR_GOLD)
		tower_manage_meta_label.add_theme_font_size_override("font_size", 10)
		tower_manage_meta_label.add_theme_color_override("font_color", Color(0.42, 0.90, 1.0, 0.92))
		tower_manage_stats_label.add_theme_font_size_override("font_size", 11)
		tower_manage_stats_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 0.96))
		tower_manage_economy_label.add_theme_font_size_override("font_size", 10)
		tower_manage_economy_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 0.92))
		_apply_action_button(tower_manage_upgrade_button, SpaceTheme.COLOR_GOLD, "")
		_apply_action_button(tower_manage_sell_button, SpaceTheme.COLOR_CYAN, "")
		_apply_action_button(tower_manage_close_button, SpaceTheme.COLOR_CYAN, "")
	if end_state_panel != null:
		end_state_panel.add_theme_stylebox_override("panel", _hud_panel_style(SpaceTheme.COLOR_GOLD, 16.0, 16.0))
		end_state_title_label.add_theme_font_size_override("font_size", 25)
		end_state_subtitle_label.add_theme_font_size_override("font_size", 14)
		end_state_rank_label.add_theme_font_size_override("font_size", 18)
		end_state_stats_label.add_theme_font_size_override("font_size", 14)
		end_state_tip_label.add_theme_font_size_override("font_size", 12)
		end_state_subtitle_label.add_theme_color_override("font_color", Color(0.82, 0.92, 0.98, 0.94))
		end_state_rank_label.add_theme_color_override("font_color", Color(0.42, 0.90, 1.0, 0.96))
		end_state_stats_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 0.96))
		end_state_tip_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 0.86))
		_apply_action_button(end_state_retry_button, SpaceTheme.COLOR_GOLD, SpaceTheme.ICON_PLAY_PATH)
		_apply_action_button(end_state_main_menu_button, SpaceTheme.COLOR_CYAN, SpaceTheme.ICON_BACK_PATH)


func _show_tower_info(tower_type: String) -> void:
	if tower_info_card == null:
		return
	hovered_tower_type = tower_type
	_populate_tower_info_card(tower_type)
	_position_tower_info_card(tower_type)
	tower_info_card.visible = true


func _hide_tower_info(tower_type: String = "") -> void:
	if tower_type != "" and hovered_tower_type != tower_type:
		return
	hovered_tower_type = ""
	if tower_info_card != null:
		tower_info_card.visible = false


func _populate_tower_info_card(tower_type: String) -> void:
	var info: Dictionary = tower_info_states.get(tower_type, {})
	var accent: Color = info.get("accent", TOWER_ACCENTS.get(tower_type, SpaceTheme.COLOR_CYAN))
	tower_info_card.add_theme_stylebox_override("panel", _hud_panel_style(accent, 14.0, 12.0))
	tower_info_title_label.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 1.0))
	tower_info_title_label.text = str(info.get("title", tower_type.replace("_", " ").to_upper()))
	tower_info_role_label.text = str(info.get("role", "ORBITAL DEFENSE"))
	tower_info_stats_label.text = str(info.get("stats", "DAMAGE --  |  RATE --  |  RANGE --"))
	tower_info_body_label.text = str(info.get("body", "Select this tower to place it on an open orbital slot."))
	tower_info_note_label.text = str(info.get("note", "Build before a wave begins."))

	var accent_bar: ColorRect = tower_info_card.get_node_or_null("TowerInfoMargin/TowerInfoRoot/TowerInfoAccent") as ColorRect
	if accent_bar != null:
		accent_bar.color = Color(accent.r, accent.g, accent.b, 0.92)


func _position_tower_info_card(tower_type: String) -> void:
	var button: Button = tower_buttons.get(tower_type, null) as Button
	if button == null:
		return

	tower_info_card.reset_size()
	var card_size: Vector2 = tower_info_card.get_combined_minimum_size()
	card_size.x = maxf(card_size.x, tower_info_card.custom_minimum_size.x)
	card_size.y = maxf(card_size.y, tower_info_card.custom_minimum_size.y)
	tower_info_card.size = card_size

	var tower_rect: Rect2 = tower_panel.get_global_rect()
	var hud_origin: Vector2 = hud_root.get_global_rect().position
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var x: float = tower_rect.position.x - hud_origin.x
	var y: float = tower_rect.position.y - hud_origin.y - card_size.y - 14.0
	if y < 18.0:
		y = tower_rect.position.y - hud_origin.y + 14.0

	tower_info_card.position = Vector2(
		clampf(x, 22.0, maxf(22.0, viewport_size.x - card_size.x - 22.0)),
		clampf(y, 18.0, maxf(18.0, viewport_size.y - card_size.y - 18.0))
	)


func _position_tower_manage_card() -> void:
	if tower_manage_card == null or tower_panel == null:
		return

	tower_manage_card.reset_size()
	var card_size: Vector2 = tower_manage_card.get_combined_minimum_size()
	card_size.x = maxf(card_size.x, tower_manage_card.custom_minimum_size.x)
	card_size.y = maxf(card_size.y, tower_manage_card.custom_minimum_size.y)
	tower_manage_card.size = card_size

	var tower_rect: Rect2 = tower_panel.get_global_rect()
	var hud_origin: Vector2 = hud_root.get_global_rect().position
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var x: float = tower_rect.position.x - hud_origin.x
	var y: float = tower_rect.position.y - hud_origin.y - card_size.y - 14.0
	if y < 18.0:
		y = tower_rect.position.y - hud_origin.y + 14.0

	tower_manage_card.position = Vector2(
		clampf(x, 22.0, maxf(22.0, viewport_size.x - card_size.x - 22.0)),
		clampf(y, 18.0, maxf(18.0, viewport_size.y - card_size.y - 18.0))
	)


func _position_end_state_card() -> void:
	if end_state_panel == null:
		return

	end_state_panel.reset_size()
	var card_size: Vector2 = end_state_panel.get_combined_minimum_size()
	card_size.x = maxf(card_size.x, end_state_panel.custom_minimum_size.x)
	card_size.y = maxf(card_size.y, end_state_panel.custom_minimum_size.y)
	end_state_panel.size = card_size

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	end_state_panel.position = (viewport_size - card_size) * 0.5


func _apply_action_button(button: Button, accent: Color, icon_path: String) -> void:
	if accent == SpaceTheme.COLOR_GOLD:
		SpaceTheme.apply_primary_button(button, icon_path)
	else:
		SpaceTheme.apply_secondary_button(button, icon_path)
	button.add_theme_stylebox_override("normal", _hud_button_style(SpaceTheme.COLOR_BUTTON_BG, accent, 1, 12.0, 8.0))
	button.add_theme_stylebox_override("hover", _hud_button_style(SpaceTheme.COLOR_BUTTON_HOVER, Color(accent.r, accent.g, accent.b, 1.0), 2, 12.0, 8.0))
	button.add_theme_stylebox_override("pressed", _hud_button_style(SpaceTheme.COLOR_BUTTON_PRESSED, SpaceTheme.COLOR_GOLD, 2, 12.0, 8.0))
	button.add_theme_stylebox_override("focus", _hud_button_style(Color(0.015, 0.072, 0.092, 1.0), SpaceTheme.COLOR_GOLD, 2, 12.0, 8.0))
	button.add_theme_stylebox_override("disabled", _hud_button_style(SpaceTheme.COLOR_BUTTON_DISABLED, Color(0.20, 0.28, 0.34, 0.70), 1, 12.0, 8.0))
	button.add_theme_color_override("font_color", Color(0.98, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.74, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.96, 0.74, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.46, 0.54, 0.62, 1.0))
	button.add_theme_constant_override("h_separation", 7)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _set_auto_start_button(enabled: bool) -> void:
	if auto_start_button == null:
		return
	auto_start_button.set_pressed_no_signal(enabled)
	auto_start_button.text = "AUTO\nARMED" if enabled else "AUTO\nSTART"
	auto_start_button.tooltip_text = "Automatically starts ready waves after a short countdown."
	var accent: Color = SpaceTheme.COLOR_GOLD if enabled else SpaceTheme.COLOR_CYAN
	_apply_action_button(auto_start_button, accent, SpaceTheme.ICON_PLAY_PATH)
	auto_start_button.add_theme_font_size_override("font_size", 9)


func _apply_tower_button_state(button: Button, tower_type: String, selected: bool, disabled: bool) -> void:
	var accent: Color = TOWER_ACCENTS.get(tower_type, SpaceTheme.COLOR_CYAN)
	var border: Color = SpaceTheme.COLOR_GOLD if selected else Color(accent.r, accent.g, accent.b, 0.78)
	var bg: Color = SpaceTheme.COLOR_BUTTON_BG
	var hover_bg: Color = SpaceTheme.COLOR_BUTTON_HOVER
	var pressed_bg: Color = SpaceTheme.COLOR_BUTTON_PRESSED
	if selected:
		bg = Color(0.046, 0.052, 0.042, 0.98)
		hover_bg = Color(0.060, 0.068, 0.052, 1.0)
		pressed_bg = Color(0.070, 0.076, 0.058, 1.0)

	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_stylebox_override("normal", _hud_button_style(bg, border, 1, 10.0, 6.0))
	button.add_theme_stylebox_override("hover", _hud_button_style(hover_bg, Color(border.r, border.g, border.b, 1.0), 2, 10.0, 6.0))
	button.add_theme_stylebox_override("pressed", _hud_button_style(pressed_bg, SpaceTheme.COLOR_GOLD, 2, 10.0, 6.0))
	button.add_theme_stylebox_override("focus", _hud_button_style(hover_bg, SpaceTheme.COLOR_GOLD, 2, 10.0, 6.0))
	button.add_theme_stylebox_override("disabled", _hud_button_style(Color(0.008, 0.014, 0.022, 0.74), Color(0.18, 0.25, 0.32, 0.72), 1, 10.0, 6.0))
	button.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.78, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.96, 0.70, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.42, 0.50, 0.58, 1.0))
	button.add_theme_constant_override("h_separation", 5)
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND


func _hud_panel_style(accent: Color, horizontal_margin: float, vertical_margin: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.006, 0.012, 0.024, 0.84)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = horizontal_margin
	style.content_margin_right = horizontal_margin
	style.content_margin_top = vertical_margin
	style.content_margin_bottom = vertical_margin
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


func _hud_button_style(bg_color: Color, border_color: Color, border_width: int, horizontal_margin: float = 12.0, vertical_margin: float = 7.0) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.content_margin_left = horizontal_margin
	style.content_margin_right = horizontal_margin
	style.content_margin_top = vertical_margin
	style.content_margin_bottom = vertical_margin
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 1.0)
	return style
