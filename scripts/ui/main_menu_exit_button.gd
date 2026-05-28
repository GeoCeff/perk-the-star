extends Button


func _ready() -> void:
	add_to_group("main_menu_buttons")
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	disabled = true
	call_deferred("_quit_game")


func _quit_game() -> void:
	get_tree().quit(0)
