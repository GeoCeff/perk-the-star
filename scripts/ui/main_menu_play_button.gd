extends Button

@export_file("*.tscn") var game_scene_path: String = "res://scenes/game.tscn"


func _ready() -> void:
	add_to_group("main_menu_buttons")
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	disabled = true
	call_deferred("_start_game")


func _start_game() -> void:
	MusicManager.stop_music()
	var error: int = get_tree().change_scene_to_file(game_scene_path)
	if error != OK:
		disabled = false
		MusicManager.play_menu_music()
		push_error("MainMenuPlayButton: could not start game scene at %s. Error code: %s" % [game_scene_path, error])
