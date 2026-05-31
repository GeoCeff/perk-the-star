extends Control

const SpaceTheme = preload("res://scripts/ui/space_theme.gd")

const GAME_TITLE: String = "PERK THE STAR"
const SUBTITLE: String = "DEFEND THE SUN - SAVE THE SYSTEM"
const TAGLINE: String = "Defend me, defend me! - Oa ka Perk!"
const OVERVIEW: String = "Command the Sol Defense Corps in a real-time orbital tower defense game built in C++ with Godot Engine 4.x via GDExtension. Protect the Sun from Astrophage, photosynthetic microorganisms feeding on stellar energy."
const TECH_LABEL: String = "CMSC 21 | C++ / Godot Engine 4.x / GDExtension"
const AUTHOR_LABEL: String = "Geo Ceff Gabaisen & Dexter Juevesano"

@onready var btn_play: Button = $CenterContainer/menu_box/button_box/btn_play
@onready var btn_codex: Button = $CenterContainer/menu_box/button_box/btn_codex
@onready var btn_settings: Button = $CenterContainer/menu_box/button_box/btn_settings
@onready var btn_exit: Button = $CenterContainer/menu_box/button_box/btn_exit
@onready var menu_frame: PanelContainer = $menu_frame
@onready var title_label: Label = $CenterContainer/menu_box/title_label
@onready var sub_label: Label = $CenterContainer/menu_box/sub_label
@onready var tagline_label: Label = $CenterContainer/menu_box/tagline_label
@onready var description_label: Label = $CenterContainer/menu_box/description_label
@onready var version_label: Label = $version_label
@onready var author_label: Label = $author_label


func _ready() -> void:
	GameState.reset_state()
	GameState.load_audio_settings()
	MusicManager.play_menu_music()

	title_label.text = GAME_TITLE
	sub_label.text = SUBTITLE
	tagline_label.text = TAGLINE
	description_label.text = OVERVIEW
	version_label.text = TECH_LABEL
	author_label.text = AUTHOR_LABEL

	_apply_menu_style()

	title_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.5)
	btn_play.grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var focus_owner: Control = get_viewport().gui_get_focus_owner()
		if focus_owner == null:
			btn_play.pressed.emit()


func _apply_menu_style() -> void:
	var primary: Color = Color(1.0, 0.88, 0.36)
	var body: Color = Color(0.90, 0.94, 1.0)

	SpaceTheme.apply_cursor()
	SpaceTheme.apply_fonts(self)
	SpaceTheme.apply_deep_panel(menu_frame, SpaceTheme.COLOR_CYAN)

	title_label.add_theme_color_override("font_color", primary)
	sub_label.add_theme_color_override("font_color", body)
	tagline_label.add_theme_color_override("font_color", Color(0.55, 0.84, 0.92))
	description_label.add_theme_color_override("font_color", body)
	version_label.add_theme_color_override("font_color", Color(0.78, 0.90, 1.0, 1.0))
	author_label.add_theme_color_override("font_color", Color(0.68, 0.94, 1.0, 1.0))

	SpaceTheme.apply_primary_button(btn_play, SpaceTheme.ICON_PLAY_PATH)
	SpaceTheme.apply_secondary_button(btn_codex, SpaceTheme.ICON_CODEX_PATH)
	SpaceTheme.apply_secondary_button(btn_settings, SpaceTheme.ICON_SETTINGS_PATH)
	SpaceTheme.apply_danger_button(btn_exit, SpaceTheme.ICON_BACK_PATH)

	for button in get_tree().get_nodes_in_group("main_menu_buttons"):
		button.add_theme_font_size_override("font_size", 20)
