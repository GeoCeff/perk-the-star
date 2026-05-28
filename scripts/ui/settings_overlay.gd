class_name SettingsOverlay
extends Control

@export_file("*.tscn") var return_scene_path: String = "res://scenes/main_menu.tscn"

@onready var close_button: Button = $settings_panel/settings_margin/settings_box/settings_close


func _ready() -> void:
	visible = true
	MusicManager.play_menu_music()
	close_button.grab_focus()


func show_from_button(_button: Control) -> void:
	close_button.grab_focus()


func close_overlay() -> void:
	get_tree().change_scene_to_file(return_scene_path)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_overlay()
