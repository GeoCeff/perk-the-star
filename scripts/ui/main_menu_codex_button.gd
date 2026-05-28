extends Button

@export_file("*.tscn") var codex_scene_path: String = "res://scenes/ui/mission_codex.tscn"


func _ready() -> void:
	add_to_group("main_menu_buttons")
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	disabled = true
	call_deferred("_open_codex_scene")


func _open_codex_scene() -> void:
	var error: int = get_tree().change_scene_to_file(codex_scene_path)
	if error != OK:
		disabled = false
		push_error("MainMenuCodexButton: could not open codex scene at %s. Error code: %s" % [codex_scene_path, error])
