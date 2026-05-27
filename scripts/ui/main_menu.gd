extends Control

const GAME_TITLE: String = "PERK THE STAR"
const SUBTITLE: String = "DEFEND THE SUN - SAVE THE SYSTEM"
const TAGLINE: String = "Defend me, defend me! - Oa ka Perk!"
const OVERVIEW: String = "Command the Sol Defense Corps in a real-time orbital tower defense game built in C++ with Godot Engine 4.x via GDExtension. Protect the Sun from Astrophage, photosynthetic microorganisms feeding on stellar energy."
const GAME_SCENE_PATH: String = "res://scenes/waves/wave_01.tscn"
const MAIN_MENU_BGM_PATH: String = "res://assets/audio/bgm/main_menu.ogg"

@onready var btn_play: Button = $CenterContainer/menu_box/button_box/btn_play
@onready var btn_codex: Button = $CenterContainer/menu_box/button_box/btn_codex
@onready var btn_settings: Button = $CenterContainer/menu_box/button_box/btn_settings
@onready var btn_exit: Button = $CenterContainer/menu_box/button_box/btn_exit
@onready var settings_overlay: ColorRect = $settings_overlay
@onready var settings_close: Button = $settings_overlay/settings_panel/settings_margin/settings_box/settings_close
@onready var title_label: Label = $CenterContainer/menu_box/title_label
@onready var sub_label: Label = $CenterContainer/menu_box/sub_label
@onready var tagline_label: Label = $CenterContainer/menu_box/tagline_label
@onready var description_label: Label = $CenterContainer/menu_box/description_label
@onready var version_label: Label = $version_label
@onready var bgm_player: AudioStreamPlayer = get_node_or_null("MainMenuMusic") as AudioStreamPlayer
@onready var music_toggle: CheckButton = $settings_overlay/settings_panel/settings_margin/settings_box/audio_panel/audio_margin/audio_box/music_toggle
@onready var music_volume_slider: HSlider = $settings_overlay/settings_panel/settings_margin/settings_box/audio_panel/audio_margin/audio_box/volume_row/music_volume_slider
@onready var music_volume_value: Label = $settings_overlay/settings_panel/settings_margin/settings_box/audio_panel/audio_margin/audio_box/volume_row/music_volume_value


func _ready() -> void:
	GameState.reset_state()
	GameState.load_audio_settings()
	_start_menu_music()
	_setup_audio_controls()

	title_label.text = GAME_TITLE
	sub_label.text = SUBTITLE
	tagline_label.text = TAGLINE
	description_label.text = OVERVIEW
	btn_play.text = "Start Defense"
	btn_codex.text = "Mission Codex"
	btn_settings.text = "Settings"
	btn_exit.text = "Exit"
	version_label.text = "CMSC 21 - Geo Ceff Gabaisen & Dexter Juevesano | C++ / Godot Engine 4.x / GDExtension"

	_apply_menu_style()

	btn_play.pressed.connect(_on_play)
	btn_codex.pressed.connect(_on_codex)
	btn_settings.pressed.connect(_on_settings)
	btn_exit.pressed.connect(_on_exit)
	settings_close.pressed.connect(_close_settings)
	music_toggle.toggled.connect(_on_music_toggled)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	GameState.music_settings_changed.connect(_on_music_settings_changed)

	title_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.5)
	btn_play.grab_focus()


func _on_play() -> void:
	btn_play.disabled = true
	call_deferred("_start_game")


func _start_game() -> void:
	var error: int = get_tree().change_scene_to_file(GAME_SCENE_PATH)
	if error != OK:
		btn_play.disabled = false
		push_error("MainMenu: could not start game scene at %s. Error code: %s" % [GAME_SCENE_PATH, error])


func _on_codex() -> void:
	var codex: Control = preload("res://scenes/ui/codex.tscn").instantiate()
	add_child(codex)
	codex.show_standalone_mode()


func _on_settings() -> void:
	settings_overlay.visible = true
	settings_close.grab_focus()


func _close_settings() -> void:
	settings_overlay.visible = false
	btn_settings.grab_focus()


func _on_exit() -> void:
	btn_exit.disabled = true
	call_deferred("_quit_game")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and settings_overlay.visible:
		_close_settings()
		return
	if event.is_action_pressed("ui_accept"):
		var focus_owner: Control = get_viewport().gui_get_focus_owner()
		if focus_owner == null:
			_on_play()


func _quit_game() -> void:
	get_tree().quit(0)


func _start_menu_music() -> void:
	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "MainMenuMusic"
		bgm_player.volume_db = -8.0
		add_child(bgm_player)

	if bgm_player.stream == null:
		bgm_player.stream = load(MAIN_MENU_BGM_PATH)
	_set_audio_stream_loop(bgm_player.stream, true)
	_apply_music_settings()
	if GameState.music_enabled and bgm_player.stream and not bgm_player.playing:
		bgm_player.play()


func _set_audio_stream_loop(stream, loop_enabled: bool) -> void:
	if stream == null:
		return
	for property in stream.get_property_list():
		if str(property.get("name", "")) == "loop":
			stream.set("loop", loop_enabled)
			return


func _setup_audio_controls() -> void:
	music_toggle.set_pressed_no_signal(GameState.music_enabled)
	music_volume_slider.set_value_no_signal(round(GameState.music_volume * 100.0))
	_update_music_volume_label()


func _on_music_toggled(enabled: bool) -> void:
	GameState.set_music_enabled(enabled)


func _on_music_volume_changed(value: float) -> void:
	GameState.set_music_volume(value / 100.0)


func _on_music_settings_changed(_enabled: bool, _volume: float) -> void:
	_setup_audio_controls()
	_apply_music_settings()


func _apply_music_settings() -> void:
	if bgm_player == null:
		return
	bgm_player.volume_db = GameState.get_music_volume_db()
	if GameState.music_enabled:
		if bgm_player.stream and not bgm_player.playing:
			bgm_player.play()
	else:
		bgm_player.stop()


func _update_music_volume_label() -> void:
	music_volume_value.text = "%d%%" % int(round(music_volume_slider.value))


func _apply_menu_style() -> void:
	var primary: Color = Color(1.0, 0.88, 0.36)
	var body: Color = Color(0.90, 0.94, 1.0)
	var muted: Color = Color(0.63, 0.72, 0.84)

	title_label.add_theme_color_override("font_color", primary)
	sub_label.add_theme_color_override("font_color", body)
	tagline_label.add_theme_color_override("font_color", Color(0.55, 0.84, 0.92))
	description_label.add_theme_color_override("font_color", body)
	version_label.add_theme_color_override("font_color", muted)

	for button in [btn_play, btn_codex, btn_settings, btn_exit]:
		button.add_theme_font_size_override("font_size", 20)
