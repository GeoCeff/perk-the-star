extends Node

# Simple global music player. Menus can ask for menu music, while gameplay uses
# its own wave/ending tracks in game.gd.

const MAIN_MENU_BGM_PATH: String = "res://assets/audio/bgm/main_menu.ogg"

var player: AudioStreamPlayer
var current_track_path: String = ""


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "MusicPlayer"
	add_child(player)
	GameState.music_settings_changed.connect(_on_music_settings_changed)
	GameState.load_audio_settings()


func play_menu_music() -> void:
	_play_music(MAIN_MENU_BGM_PATH)


func stop_music() -> void:
	if player != null:
		player.stop()
	current_track_path = ""


func _play_music(path: String) -> void:
	if player == null:
		return

	if current_track_path != path:
		var stream = load(path)
		_set_audio_stream_loop(stream, true)
		player.stream = stream
		current_track_path = path

	player.volume_db = GameState.get_music_volume_db()
	if GameState.music_enabled and player.stream and not player.playing:
		player.play()
	elif not GameState.music_enabled:
		player.stop()


func _set_audio_stream_loop(stream, loop_enabled: bool) -> void:
	if stream == null:
		return
	for property in stream.get_property_list():
		if str(property.get("name", "")) == "loop":
			stream.set("loop", loop_enabled)
			return


func _on_music_settings_changed(_enabled: bool, _volume: float) -> void:
	if player == null:
		return
	player.volume_db = GameState.get_music_volume_db()
	if GameState.music_enabled:
		if player.stream and not player.playing:
			player.play()
	else:
		player.stop()
