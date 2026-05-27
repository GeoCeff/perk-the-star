extends Control

const GAME_TITLE := "PERK THE STAR"
const SUBTITLE := "DEFEND THE SUN - SAVE THE SYSTEM"
const TAGLINE := "Defend me, defend me! - Oa ka Perk!"
const OVERVIEW := "Command the Sol Defense Corps in a real-time orbital tower defense game built in C++ with Godot Engine 4.x via GDExtension. Protect the Sun from Astrophage, photosynthetic microorganisms feeding on stellar energy."

@onready var btn_play = $CenterContainer/menu_box/button_box/btn_play
@onready var btn_codex = $CenterContainer/menu_box/button_box/btn_codex
@onready var btn_settings = $CenterContainer/menu_box/button_box/btn_settings
@onready var btn_exit = $CenterContainer/menu_box/button_box/btn_exit
@onready var settings_overlay = $settings_overlay
@onready var settings_close = $settings_overlay/settings_panel/settings_margin/settings_box/settings_close
@onready var title_label = $CenterContainer/menu_box/title_label
@onready var sub_label = $CenterContainer/menu_box/sub_label
@onready var tagline_label = $CenterContainer/menu_box/tagline_label
@onready var description_label = $CenterContainer/menu_box/description_label
@onready var version_label = $version_label


func _ready():
	GameState.reset_state()

	title_label.text = GAME_TITLE
	sub_label.text = SUBTITLE
	tagline_label.text = TAGLINE
	description_label.text = OVERVIEW
	btn_play.text = "Start Defense"
	btn_codex.text = "Mission Codex"
	btn_settings.text = "Settings"
	btn_exit.text = "Exit"
	version_label.text = "CMSC 21 - Geo Ceff Gabaisen & Dexter Juevesano | C++ / Godot Engine 4.x / GDExtension"

	_apply_menu_style()

	btn_play.pressed.connect(_on_play)
	btn_codex.pressed.connect(_on_codex)
	btn_settings.pressed.connect(_on_settings)
	btn_exit.pressed.connect(_on_exit)
	settings_close.pressed.connect(_close_settings)

	title_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.5)
	btn_play.grab_focus()


func _on_play():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/game.tscn"))


func _on_codex():
	var codex = preload("res://scenes/ui/codex.tscn").instantiate()
	add_child(codex)
	codex.show_standalone_mode()


func _on_settings():
	settings_overlay.visible = true
	settings_close.grab_focus()


func _close_settings() -> void:
	settings_overlay.visible = false
	btn_settings.grab_focus()


func _on_exit():
	btn_exit.disabled = true
	call_deferred("_quit_game")


func _input(event):
	if event.is_action_pressed("ui_cancel") and settings_overlay.visible:
		_close_settings()
		return
	if event.is_action_pressed("ui_accept"):
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner == null:
			_on_play()


func _quit_game() -> void:
	get_tree().quit(0)


func _apply_menu_style() -> void:
	var primary := Color(1.0, 0.88, 0.36)
	var body := Color(0.90, 0.94, 1.0)
	var muted := Color(0.63, 0.72, 0.84)

	title_label.add_theme_color_override("font_color", primary)
	sub_label.add_theme_color_override("font_color", body)
	tagline_label.add_theme_color_override("font_color", Color(0.55, 0.84, 0.92))
	description_label.add_theme_color_override("font_color", body)
	version_label.add_theme_color_override("font_color", muted)

	for button in [btn_play, btn_codex, btn_settings, btn_exit]:
		button.add_theme_font_size_override("font_size", 20)
