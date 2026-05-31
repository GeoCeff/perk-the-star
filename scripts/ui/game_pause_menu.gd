class_name GamePauseMenu
extends CanvasLayer

const SpaceTheme = preload("res://scripts/ui/space_theme.gd")

const CODEX_SCENE_PATH: String = "res://scenes/ui/codex.tscn"
const SETTINGS_SCENE_PATH: String = "res://scenes/ui/settings_overlay.tscn"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"

@onready var overlay_root: Control = $OverlayRoot
@onready var pause_panel: PanelContainer = $OverlayRoot/PausePanel
@onready var title_label: Label = $OverlayRoot/PausePanel/PauseMargin/PauseBox/TitleLabel
@onready var subtitle_label: Label = $OverlayRoot/PausePanel/PauseMargin/PauseBox/SubtitleLabel
@onready var codex_button: Button = $OverlayRoot/PausePanel/PauseMargin/PauseBox/ButtonBox/CodexButton
@onready var settings_button: Button = $OverlayRoot/PausePanel/PauseMargin/PauseBox/ButtonBox/SettingsButton
@onready var main_menu_button: Button = $OverlayRoot/PausePanel/PauseMargin/PauseBox/ButtonBox/MainMenuButton
@onready var back_button: Button = $OverlayRoot/PausePanel/PauseMargin/PauseBox/ButtonBox/BackButton
@onready var overlay_host: Control = $OverlayHost


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_bind_buttons()
	_apply_style()
	back_button.grab_focus()


func _exit_tree() -> void:
	if get_tree() != null and get_tree().paused:
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and overlay_host.get_child_count() == 0:
		_close_pause_menu()
		get_viewport().set_input_as_handled()


func _bind_buttons() -> void:
	codex_button.pressed.connect(_open_codex)
	settings_button.pressed.connect(_open_settings)
	main_menu_button.pressed.connect(_return_to_main_menu)
	back_button.pressed.connect(_close_pause_menu)


func _apply_style() -> void:
	SpaceTheme.apply_cursor()
	SpaceTheme.apply_fonts(self)
	SpaceTheme.apply_deep_panel(pause_panel, SpaceTheme.COLOR_CYAN)
	title_label.add_theme_color_override("font_color", SpaceTheme.COLOR_GOLD)
	subtitle_label.add_theme_color_override("font_color", Color(0.62, 0.88, 0.98, 0.96))
	SpaceTheme.apply_secondary_button(codex_button, SpaceTheme.ICON_CODEX_PATH)
	SpaceTheme.apply_secondary_button(settings_button, SpaceTheme.ICON_SETTINGS_PATH)
	SpaceTheme.apply_danger_button(main_menu_button, SpaceTheme.ICON_BACK_PATH)
	SpaceTheme.apply_primary_button(back_button, SpaceTheme.ICON_PLAY_PATH)
	for button in [codex_button, settings_button, main_menu_button, back_button]:
		button.add_theme_font_size_override("font_size", 20)


func _open_codex() -> void:
	_open_embedded_overlay(CODEX_SCENE_PATH)


func _open_settings() -> void:
	_open_embedded_overlay(SETTINGS_SCENE_PATH)


func _open_embedded_overlay(scene_path: String) -> void:
	if overlay_host.get_child_count() > 0:
		return

	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("GamePauseMenu: could not load overlay scene at %s." % scene_path)
		return

	var overlay: Node = packed_scene.instantiate()
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.set("close_returns_to_scene", false)
	overlay.set("play_menu_music_on_ready", false)
	overlay_host.add_child(overlay)
	var close_button: Button = overlay.get_node_or_null("panel/margin/root_box/content_box/nav_box/close_button") as Button
	if close_button == null:
		close_button = overlay.get_node_or_null("settings_panel/settings_margin/settings_box/settings_close") as Button
	if close_button != null:
		close_button.grab_focus()


func _return_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _close_pause_menu() -> void:
	get_tree().paused = false
	queue_free()
