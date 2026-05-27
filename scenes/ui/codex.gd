extends Control

@onready var close_button: Button = $panel/margin/root_box/content_box/nav_box/close_button
@onready var section_title_label: Label = $panel/margin/root_box/content_box/article_box/section_title_label
@onready var body_scroll: ScrollContainer = $panel/margin/root_box/content_box/article_box/body_scroll
@onready var body_label: Label = $panel/margin/root_box/content_box/article_box/body_scroll/body_label
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
- Survive through Astrophage Prime.

Command phrase
Defend me, defend me! - Oa ka Perk!"""
	},
	"systems": {
		"title": "Core Systems",
		"body": """GameState
Central runtime data: luminosity, Sol Credits, wave phase, score, signals, and flare charge.

Sun
Tracks luminosity, expression states, and death/victory state. The Sun changes expression as luminosity drops.

OrbitalTower
Orbiting defense satellites. Their value depends on orbital radius, period, firing cooldown, and engagement windows.

WaveManager
Loads wave JSON and manages the 12-wave spawn loop.

SolarFlare
Manual radial burst. The guide describes a flare every 3 waves, fired in a cone to relieve pressure.

UIManager
Loading screen, HUD, post-mortem, and briefing interface."""
	},
	"towers": {
		"title": "Tower Dossier",
		"body": """Photon Splitter
Baseline direct-damage tower. Best on the fast Corona Belt and paired with Helios Cannon coverage.

Cryo Probe
Control tower for slowing threats. Strong on the Chromosphere Band and useful before enemies reach inner rings.

Bio-Lab Station
Analysis and counter-biology platform. The guide calls it out for Photosphere Arc placement and boss-phase interactions.

Magnetic Net
Field-control support tower. Best paired with Bio-Lab Station on the Photosphere Arc.

Helios Cannon
High-impact solar weapon. Best on the Corona Belt when timing windows are tight.

Tardigrade Bomb
Area-pressure tool. Recommended for Chromosphere Band coverage in the ring table."""
	},
	"astrophage": {
		"title": "Astrophage Variants",
		"body": """0 - Drifter
Baseline Astrophage. Use it to verify tower timing, wave pacing, and credit rewards.

1 - Bloom
Splitting threat. The guide's workflow references Bloom split behavior as an implementation milestone.

2 - Burrower
Sun-pressure threat. Burrowers are intended to create luminosity drain pressure once they reach the Sun.

3 - Mimic
Detection/targeting challenge. Forces the defense plan to rely on more than one tower type.

4 - Farmer
Counterplay enemy. Designed to punish careless energy damage and reward correct tower sequencing.

5 - Astrophage Prime
Boss wave target. Wave 12 is the Prime encounter."""
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
- Wave 12: Astrophage Prime."""
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

Field Reminder
Every credit spent should buy time, coverage, or control. A beautiful orbit means nothing if the Sun goes dark."""
	},
}


func _ready() -> void:
	visible = true
	close_button.pressed.connect(queue_free)
	for key in nav_buttons.keys():
		var section_key: String = str(key)
		var button: Button = nav_buttons[section_key]
		button.toggle_mode = true
		button.pressed.connect(_show_section.bind(section_key))
		button.add_theme_font_size_override("font_size", 16)
	_show_section("briefing")


func show_standalone_mode() -> void:
	visible = true
	_show_section("briefing")


func _show_section(section_key: String) -> void:
	current_section = section_key
	var section: Dictionary = sections.get(section_key, sections["briefing"])
	section_title_label.text = section["title"]
	body_label.text = section["body"]
	body_scroll.scroll_vertical = 0
	_update_nav_state()


func _update_nav_state() -> void:
	for key in nav_buttons.keys():
		var section_key: String = str(key)
		var button: Button = nav_buttons[section_key]
		button.button_pressed = section_key == current_section
