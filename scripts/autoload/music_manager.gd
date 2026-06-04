extends Node

# Simple global music player. Menus can ask for menu music, while gameplay uses
# its own wave/ending tracks in game.gd.

const MAIN_MENU_BGM_PATH: String = "res://assets/audio/bgm/final/main_menu.ogg"

var player: AudioStreamPlayer
var current_track_path: String = ""


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "MusicPlayer"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = "Master"
	add_child(player)
	GameState.music_settings_changed.connect(_on_music_settings_changed)
	GameState.load_audio_settings()


func play_menu_music() -> void:
	_play_music(MAIN_MENU_BGM_PATH)


func stop_music() -> void:
	if player != null:
		player.stop()
		player.stream = null
	current_track_path = ""


func _play_music(path: String) -> void:
	if player == null:
		return

	if current_track_path != path:
		var stream = load_music_stream(path, true)
		if stream == null:
			push_warning("MusicManager: missing music track at %s." % path)
			return
		player.stop()
		player.stream = stream
		current_track_path = path

	player.volume_db = GameState.get_music_volume_db()
	if GameState.music_enabled and player.stream:
		_start_player()
	elif not GameState.music_enabled:
		player.stop()


func _start_player() -> void:
	if player == null or player.stream == null:
		return
	if not player.playing:
		player.play()
		call_deferred("_ensure_music_playing", current_track_path)


func _ensure_music_playing(expected_track_path: String) -> void:
	if player == null:
		return
	if current_track_path != expected_track_path:
		return
	if not GameState.music_enabled or player.stream == null:
		return
	if not player.playing:
		player.play()


func load_music_stream(path: String, loop_enabled: bool):
	var extension: String = path.get_extension().to_lower()
	if extension == "ogg":
		var ogg_stream = AudioStreamOggVorbis.load_from_file(path)
		if ogg_stream != null:
			_set_audio_stream_loop(ogg_stream, loop_enabled)
			return ogg_stream
	elif extension == "wav":
		var wav_stream = _load_pcm_wav_stream(path, loop_enabled)
		if wav_stream != null:
			return wav_stream

	var stream = ResourceLoader.load(path, "AudioStream", ResourceLoader.CACHE_MODE_REPLACE)
	if stream != null:
		_set_audio_stream_loop(stream, loop_enabled)
	return stream


func _load_pcm_wav_stream(path: String, loop_enabled: bool):
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if bytes.size() < 44:
		return null
	if _wav_chunk_id(bytes, 0) != "RIFF" or _wav_chunk_id(bytes, 8) != "WAVE":
		return null

	var fmt_offset: int = -1
	var data_offset: int = -1
	var data_size: int = 0
	var offset: int = 12
	while offset + 8 <= bytes.size():
		var chunk_id: String = _wav_chunk_id(bytes, offset)
		var chunk_size: int = _read_u32_le(bytes, offset + 4)
		var chunk_data_offset: int = offset + 8
		if chunk_id == "fmt ":
			fmt_offset = chunk_data_offset
		elif chunk_id == "data":
			data_offset = chunk_data_offset
			data_size = chunk_size
			break
		offset = chunk_data_offset + chunk_size + (chunk_size % 2)

	if fmt_offset < 0 or data_offset < 0 or data_size <= 0:
		return null

	var audio_format: int = _read_u16_le(bytes, fmt_offset)
	var channels: int = _read_u16_le(bytes, fmt_offset + 2)
	var sample_rate: int = _read_u32_le(bytes, fmt_offset + 4)
	var block_align: int = _read_u16_le(bytes, fmt_offset + 12)
	var bits_per_sample: int = _read_u16_le(bytes, fmt_offset + 14)
	if audio_format != 1 or channels < 1 or channels > 2 or sample_rate <= 0:
		return null
	if bits_per_sample != 8 and bits_per_sample != 16:
		return null

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS if bits_per_sample == 8 else AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = channels == 2
	stream.data = bytes.slice(data_offset, data_offset + data_size)
	_set_audio_stream_loop(stream, loop_enabled)
	if loop_enabled and block_align > 0:
		stream.loop_begin = 0
		stream.loop_end = floori(float(data_size) / float(block_align))
	return stream


func _wav_chunk_id(bytes: PackedByteArray, offset: int) -> String:
	if offset + 4 > bytes.size():
		return ""
	return bytes.slice(offset, offset + 4).get_string_from_ascii()


func _read_u16_le(bytes: PackedByteArray, offset: int) -> int:
	if offset + 2 > bytes.size():
		return 0
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _read_u32_le(bytes: PackedByteArray, offset: int) -> int:
	if offset + 4 > bytes.size():
		return 0
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)


func _set_audio_stream_loop(stream, loop_enabled: bool) -> void:
	if stream == null:
		return
	for property in stream.get_property_list():
		var property_name: String = str(property.get("name", ""))
		if property_name == "loop":
			stream.set("loop", loop_enabled)
			return
		if property_name == "loop_mode":
			stream.set("loop_mode", AudioStreamWAV.LOOP_FORWARD if loop_enabled else AudioStreamWAV.LOOP_DISABLED)
			return


func _on_music_settings_changed(_enabled: bool, _volume: float) -> void:
	if player == null:
		return
	player.volume_db = GameState.get_music_volume_db()
	if current_track_path == "" or player.stream == null:
		return
	if GameState.music_enabled:
		_start_player()
	else:
		player.stop()
