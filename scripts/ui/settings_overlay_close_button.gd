extends Button

@export_node_path("Node") var settings_overlay_path: NodePath = NodePath("../../../..")

@onready var settings_overlay: Node = get_node_or_null(settings_overlay_path)


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if settings_overlay != null and settings_overlay.has_method("close_overlay"):
		settings_overlay.call("close_overlay")
		return
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
