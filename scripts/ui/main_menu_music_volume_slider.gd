extends HSlider

@export_node_path("Label") var value_label_path: NodePath

@onready var value_label: Label = get_node_or_null(value_label_path) as Label


func _ready() -> void:
	set_value_no_signal(round(GameState.music_volume * 100.0))
	_update_value_label()
	value_changed.connect(_on_value_changed)
	GameState.music_settings_changed.connect(_on_music_settings_changed)


func _on_value_changed(new_value: float) -> void:
	_update_value_label()
	GameState.set_music_volume(new_value / 100.0)


func _on_music_settings_changed(_enabled: bool, volume: float) -> void:
	set_value_no_signal(round(volume * 100.0))
	_update_value_label()


func _update_value_label() -> void:
	if value_label == null:
		return
	value_label.text = "%d%%" % int(round(value))
