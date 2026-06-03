extends Control

# Reusable Mission Codex screen. The main menu and pause menu both use this
# content, so gameplay explanations stay in one place.

const SpaceTheme = preload("res://scripts/ui/space_theme.gd")

@export_file("*.tscn") var return_scene_path: String = "res://scenes/main_menu.tscn"
@export var close_returns_to_scene: bool = true
@export var play_menu_music_on_ready: bool = true

@onready var close_button: Button = $panel/margin/root_box/content_box/nav_box/close_button
@onready var panel: PanelContainer = $panel
@onready var section_title_label: Label = $panel/margin/root_box/content_box/article_box/section_title_label
@onready var body_scroll: ScrollContainer = $panel/margin/root_box/content_box/article_box/body_scroll
@onready var body_label: RichTextLabel = $panel/margin/root_box/content_box/article_box/body_scroll/body_label
@onready var nav_buttons: Dictionary = {
	"briefing": $panel/margin/root_box/content_box/nav_box/btn_briefing,
	"systems": $panel/margin/root_box/content_box/nav_box/btn_systems,
	"towers": $panel/margin/root_box/content_box/nav_box/btn_towers,
	"astrophage": $panel/margin/root_box/content_box/nav_box/btn_astrophage,
	"rings": $panel/margin/root_box/content_box/nav_box/btn_rings,
	"endings": $panel/margin/root_box/content_box/nav_box/btn_endings,
}

var current_section: String = "briefing"

var sections: Dictionary = {
	"briefing": {
		"title": "Mission Briefing",
		"body": """Perk the Star is a single-player, real-time orbital tower defense game. You command the Sol Defense Corps and protect the Sun from Astrophage: photosynthetic microorganisms feeding on stellar energy.

Objective
- Keep luminosity above zero.
- Clear all 12 JSON-authored waves.
- Spend Sol Credits on orbiting defense satellites.
- Build, upgrade, or sell towers even while a wave is active.
- Survive through Astrophage Prime.

Command phrase
Defend me, defend me! - Oa ka Perk!"""
	},
	"systems": {
		"title": "Core Systems",
		"body": """GameState
Central runtime data: luminosity, Sol Credits, wave phase, score, signals, flare charge, tutorial completion, screen shake, and Auto Start.

Sun
Tracks luminosity, expression states, and death/victory state. The Sun changes expression as luminosity drops.

OrbitalTower
Orbiting defense satellites. Their value depends on orbital radius, period, firing cooldown, tower level, and engagement windows.

WaveManager
Loads wave JSON and manages the 12-wave spawn loop.

SolarFlare
Manual radial burst. The flare charges every 3 cleared waves and can be fired during an active wave to relieve pressure.

UIManager
HUD, tower hover cards, tower management, wave intel, tutorial overlay, pause menu, settings, codex, and end-state buttons.

Camera
Mouse wheel zooms around the cursor. Right/middle drag, screen-edge hover, and WASD pan around the star. Center Sun snaps back."""
	},
	"towers": {
		"title": "Tower Dossier",
		"body": """Photon Splitter
Baseline direct-damage tower. Best on the fast Corona Belt for early intercept, but Photon Mimics ignore it and Solar Farmers can absorb it.

Cryo Probe
Control tower for slowing threats. Strong on the Chromosphere Band and useful before enemies reach inner rings. It can be disrupted by solar storm events.

Bio-Lab Station
Analysis and counter-biology platform. It clears lodged Burrowers, benefits from Research Surge, and opens Astrophage Prime's shell.

Magnetic Net
Long-range field-control support tower. It slows enemies so heavy towers get more time to fire.

Helios Cannon
High-impact solar weapon. Strong finisher, but Solar Farmers absorb it and accelerate if they are not controlled first.

Tardigrade Bomb
Heavy finisher. Best after Cryo Probe or Magnetic Net has slowed the target.

Upgrades + Selling
Click a placed tower to open its management panel. Upgrades show current stats, exact stat gains, final upgraded stats, and cost. Selling refunds part of the Sol spent."""
	},
	"astrophage": {
		"title": "Astrophage Variants",
		"body": """0 - Drifter
Baseline Astrophage. Use it to verify tower timing, wave pacing, and credit rewards.

1 - Bloom
Splitting threat. Defeated Blooms split into three Drifters, so slowing them before they break is safer.

2 - Burrower
Sun-pressure threat. If it reaches the Sun, it lodges inside and drains luminosity until Bio-Lab excavates it.

3 - Mimic
Detection/targeting challenge. Carries the MIMIC tag and ignores Photon Splitters, forcing mixed tower plans.

4 - Farmer
Counterplay enemy. Carries the ABSORB tag and feeds from Photon/Helios damage, gaining HP and speed.

5 - Astrophage Prime
Boss wave target. Wave 12 is the Prime encounter. SHELL blocks most damage until Bio-Lab opens it; OPEN means the boss is vulnerable."""
	},
	"rings": {
		"title": "Rings + Waves",
		"body": """Orbital Rings
Ring 1 - Corona Belt: radius 80 px, period 6 s, 4 slots. Best: Photon Splitter, Helios Cannon.
Ring 2 - Chromosphere Band: radius 140 px, period 11 s, 6 slots. Best: Cryo Probe, Tardigrade Bomb.
Ring 3 - Photosphere Arc: radius 210 px, period 17 s, 8 slots. Best: Bio-Lab Station, Magnetic Net.
Ring 4 - Outer Veil: radius 290 px, period 26 s, 10 slots. Best: early intercept and scout role.

Strategic Rule
Inner rings orbit fast, giving short engagement windows. Outer rings orbit slowly, giving longer intercept windows.

Wave Plan
- 12 waves are loaded from JSON.
- Wave 6: mid-wave auto flare / Cryo disruption.
- Wave 7: night-side ring pressure.
- Wave 10: Bio-Lab boost.
- Wave 12: Astrophage Prime.

Wave Intel
The HUD previews enemy counts, warning tags, reward, and a quick counter hint before each wave. Auto Start can launch ready waves after a short countdown."""
	},
	"endings": {
		"title": "Victory + Failure",
		"body": """Full Shine
Clear 12 waves with luminosity above 80%.

Dim but Alive
Clear 12 waves with luminosity from 20% to 80%.

Last Light
Clear 12 waves with luminosity from 1% to 20%.

Sun Extinguished
Luminosity hits 0%. The guide routes this into a post-mortem screen.

End Screen Tools
Retry Run restarts the mission, Main Menu leaves the run, R retries, and M returns to menu.

Field Reminder
Every credit spent should buy time, coverage, or control. A beautiful orbit means nothing if the Sun goes dark."""
	},
}


func _ready() -> void:
	visible = true
	if play_menu_music_on_ready:
		MusicManager.play_menu_music()
	_apply_style()
	close_button.pressed.connect(_on_close_pressed)
	for key in nav_buttons.keys():
		var section_key: String = str(key)
		var button: Button = nav_buttons[section_key]
		button.toggle_mode = true
		button.pressed.connect(_show_section.bind(section_key))
		SpaceTheme.apply_secondary_button(button)
		button.add_theme_font_size_override("font_size", 16)
	SpaceTheme.apply_secondary_button(close_button, SpaceTheme.ICON_BACK_PATH)
	_show_section("briefing")


func show_standalone_mode() -> void:
	close_returns_to_scene = false
	visible = true
	_show_section("briefing")


func _on_close_pressed() -> void:
	if close_returns_to_scene:
		get_tree().change_scene_to_file(return_scene_path)
	else:
		queue_free()


func _show_section(section_key: String) -> void:
	current_section = section_key
	var section: Dictionary = sections.get(section_key, sections["briefing"])
	section_title_label.text = section["title"]
	body_label.text = SpaceTheme.format_readout_text(section["body"])
	body_scroll.scroll_vertical = 0
	_update_nav_state()


func _update_nav_state() -> void:
	for key in nav_buttons.keys():
		var section_key: String = str(key)
		var button: Button = nav_buttons[section_key]
		button.button_pressed = section_key == current_section
		if button.button_pressed:
			SpaceTheme.apply_primary_button(button)
		else:
			SpaceTheme.apply_secondary_button(button)
		button.add_theme_font_size_override("font_size", 16)


func _apply_style() -> void:
	SpaceTheme.apply_cursor()
	SpaceTheme.apply_fonts(self)
	SpaceTheme.apply_deep_panel(panel, SpaceTheme.COLOR_CYAN)
	SpaceTheme.apply_scroll_container(body_scroll)
	SpaceTheme.apply_rich_text_body(body_label, 17)
