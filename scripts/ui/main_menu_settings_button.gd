extends Button

@export_file("*.tscn") var settings_scene_path: String = "res://scenes/ui/settings_overlay.tscn"


func _ready() -> void:
	add_to_group("main_menu_buttons")
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	disabled = true
	call_deferred("_open_settings_scene")


func _open_settings_scene() -> void:
	var error: int = get_tree().change_scene_to_file(settings_scene_path)
	if error != OK:
		disabled = false
		push_error("MainMenuSettingsButton: could not open settings scene at %s. Error code: %s" % [settings_scene_path, error])
