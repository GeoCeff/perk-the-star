extends CheckButton


func _ready() -> void:
	set_pressed_no_signal(GameState.music_enabled)
	toggled.connect(_on_toggled)
	GameState.music_settings_changed.connect(_on_music_settings_changed)


func _on_toggled(enabled: bool) -> void:
	GameState.set_music_enabled(enabled)


func _on_music_settings_changed(enabled: bool, _volume: float) -> void:
	set_pressed_no_signal(enabled)
