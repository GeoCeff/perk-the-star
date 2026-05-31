class_name SettingsOverlay
extends Control

const SpaceTheme = preload("res://scripts/ui/space_theme.gd")

@export_file("*.tscn") var return_scene_path: String = "res://scenes/main_menu.tscn"
@export var close_returns_to_scene: bool = true
@export var play_menu_music_on_ready: bool = true

const SETTINGS_BODY: String = """Required Setup
- Open the repository root in Godot 4.6, not the nested game/ folder.
- Run project.godot from the repository root.
- The main menu launches res://scenes/game.tscn.
- Gameplay HUD lives in res://scenes/ui/game_hud.tscn.
- Wave data lives in res://data/waves/wave_01.json through wave_12.json.

Audio
- Use this settings panel to toggle music or change music volume.
- Main menu, wave, and ending music all read the same saved music setting.

Native Extension
- GDExtension source lives in gdextension/src.
- Debug rebuild: scons platform=windows target=template_debug arch=x86_64
- Output library: game/bin/perk_the_star.dll
- Entry symbol must stay perk_the_star_init.

Recommended Workflow
1. Edit scenes and scripts from the root project.
2. Validate wave JSON when changing data/waves.
3. Rebuild the native extension only after C++ changes.
4. Run the main menu, then Start Defense to enter the current game scene.

Common Fixes
- Failed to load GDExtension: rebuild and confirm game/bin/perk_the_star.gdextension points to the DLL.
- gdextension_interface.h missing: install or update godot-cpp before building.
- Wave JSON issue: validate the matching file in data/waves.
- Missing music: confirm assets/audio/bgm contains main_menu.ogg, waves_1.ogg, waves_2.ogg, and end.ogg."""

@onready var close_button: Button = $settings_panel/settings_margin/settings_box/settings_close
@onready var settings_panel: PanelContainer = $settings_panel
@onready var audio_panel: PanelContainer = $settings_panel/settings_margin/settings_box/audio_panel
@onready var settings_scroll: ScrollContainer = $settings_panel/settings_margin/settings_box/settings_scroll
@onready var settings_body: RichTextLabel = $settings_panel/settings_margin/settings_box/settings_scroll/settings_body
@onready var music_volume_slider: HSlider = $settings_panel/settings_margin/settings_box/audio_panel/audio_margin/audio_box/volume_row/music_volume_slider


func _ready() -> void:
	visible = true
	if play_menu_music_on_ready:
		MusicManager.play_menu_music()
	_apply_style()
	close_button.grab_focus()


func show_from_button(_button: Control) -> void:
	close_button.grab_focus()


func close_overlay() -> void:
	if close_returns_to_scene:
		get_tree().change_scene_to_file(return_scene_path)
	else:
		queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_overlay()


func _apply_style() -> void:
	SpaceTheme.apply_cursor()
	SpaceTheme.apply_fonts(self)
	SpaceTheme.apply_deep_panel(settings_panel, SpaceTheme.COLOR_CYAN)
	SpaceTheme.apply_panel(audio_panel, SpaceTheme.COLOR_GOLD)
	SpaceTheme.apply_scroll_container(settings_scroll)
	SpaceTheme.apply_rich_text_body(settings_body, 16)
	SpaceTheme.apply_slider(music_volume_slider)
	SpaceTheme.apply_secondary_button(close_button, SpaceTheme.ICON_BACK_PATH)
	settings_body.text = SpaceTheme.format_readout_text(SETTINGS_BODY)
