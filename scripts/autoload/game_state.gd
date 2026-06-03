extends Node

# GameState is an autoload, so any scene can read it as `GameState`.
# It holds the match stats and saved player settings; the actual combat logic
# still lives in `scripts/game/game.gd`.

const SETTINGS_PATH: String = "user://settings.cfg"


# Core match stats
var luminosity: float = 1.0
var sol_credits: int = 60
var current_wave: int = 0
var flare_charge: int = 0
var waves_since_last_flare: int = 0
var performance_score: int = 0
var enemies_killed_total: int = 0
var waves_cleared: int = 0
var burrowers_active: int = 0

# Saved settings
var music_enabled: bool = true
var music_volume: float = 0.72
var tutorial_completed: bool = false
var screen_shake_enabled: bool = true
var auto_start_waves_enabled: bool = false


# The phase is the simple state machine for the game.
enum Phase { MENU, BETWEEN_WAVE, WAVE_ACTIVE, PAUSED, GAME_OVER, VICTORY }
var game_phase: Phase = Phase.MENU


signal luminosity_changed(new_value: float)
signal credits_changed(new_value: int)
signal score_changed(new_value: int)
signal flare_charged
signal flare_used
signal game_over_triggered(final_luminosity: float, killing_wave: int)
signal victory_triggered(final_luminosity: float, rank: String)
signal burrower_count_changed(count: int)
signal phase_changed(new_phase: Phase)
signal music_settings_changed(enabled: bool, volume: float)
signal tutorial_settings_changed(completed: bool)
signal game_feel_settings_changed(screen_shake_enabled: bool)
signal auto_start_settings_changed(enabled: bool)


const TOWER_COSTS: Dictionary = {
	"photon_splitter": 25,
	"cryo_probe": 32,
	"bio_lab": 48,
	"magnetic_net": 44,
	"helios_cannon": 78,
	"tardigrade_bomb": 68,
}

const TOWER_UPGRADE_COSTS: Dictionary = {
	"photon_splitter": 35,
	"cryo_probe": 42,
	"bio_lab": 65,
	"magnetic_net": 58,
	"helios_cannon": 105,
	"tardigrade_bomb": 92,
}


func _ready() -> void:
	reset_state()
	load_audio_settings()


func reset_state() -> void:
	luminosity = 1.0
	sol_credits = 60
	current_wave = 0
	flare_charge = 0
	waves_since_last_flare = 0
	performance_score = 0
	enemies_killed_total = 0
	waves_cleared = 0
	burrowers_active = 0
	game_phase = Phase.MENU


# Settings are saved in user:// so they survive between play sessions without
# changing the project files.
func load_audio_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)
	if error != OK:
		return
	music_enabled = bool(config.get_value("audio", "music_enabled", music_enabled))
	music_volume = clamp(float(config.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	tutorial_completed = bool(config.get_value("tutorial", "completed", tutorial_completed))
	screen_shake_enabled = bool(config.get_value("gameplay", "screen_shake_enabled", screen_shake_enabled))
	auto_start_waves_enabled = bool(config.get_value("gameplay", "auto_start_waves_enabled", auto_start_waves_enabled))
	emit_signal("music_settings_changed", music_enabled, music_volume)
	emit_signal("tutorial_settings_changed", tutorial_completed)
	emit_signal("game_feel_settings_changed", screen_shake_enabled)
	emit_signal("auto_start_settings_changed", auto_start_waves_enabled)


func save_audio_settings() -> void:
	var config := _settings_config()
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "music_volume", music_volume)
	config.save(SETTINGS_PATH)


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	save_audio_settings()
	emit_signal("music_settings_changed", music_enabled, music_volume)


func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	save_audio_settings()
	emit_signal("music_settings_changed", music_enabled, music_volume)


func get_music_volume_db() -> float:
	if not music_enabled or music_volume <= 0.0:
		return -80.0
	return linear_to_db(music_volume)


func set_tutorial_completed(completed: bool = true) -> void:
	tutorial_completed = completed
	var config := _settings_config()
	config.set_value("tutorial", "completed", tutorial_completed)
	config.save(SETTINGS_PATH)
	emit_signal("tutorial_settings_changed", tutorial_completed)


func set_screen_shake_enabled(enabled: bool) -> void:
	screen_shake_enabled = enabled
	var config := _settings_config()
	config.set_value("gameplay", "screen_shake_enabled", screen_shake_enabled)
	config.save(SETTINGS_PATH)
	emit_signal("game_feel_settings_changed", screen_shake_enabled)


func set_auto_start_waves_enabled(enabled: bool) -> void:
	auto_start_waves_enabled = enabled
	var config := _settings_config()
	config.set_value("gameplay", "auto_start_waves_enabled", auto_start_waves_enabled)
	config.save(SETTINGS_PATH)
	emit_signal("auto_start_settings_changed", auto_start_waves_enabled)


func _settings_config() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	return config


func damage_sun(amount: float) -> void:
	if game_phase == Phase.GAME_OVER:
		return
	luminosity = clamp(luminosity - amount, 0.0, 1.0)
	emit_signal("luminosity_changed", luminosity)
	if luminosity <= 0.0:
		_trigger_game_over()


func _trigger_game_over() -> void:
	game_phase = Phase.GAME_OVER
	emit_signal("game_over_triggered", luminosity, current_wave)


func get_luminosity_percent() -> int:
	return int(luminosity * 100.0)


func add_credits(amount: int) -> void:
	sol_credits += amount
	emit_signal("credits_changed", sol_credits)


func spend_credits(amount: int) -> bool:
	if sol_credits < amount:
		return false
	sol_credits -= amount
	emit_signal("credits_changed", sol_credits)
	return true


func can_afford(amount: int) -> bool:
	return sol_credits >= amount


func get_tower_cost(tower_type: String) -> int:
	return TOWER_COSTS.get(tower_type, 30)


func get_upgrade_cost(tower_type: String) -> int:
	return TOWER_UPGRADE_COSTS.get(tower_type, 50)


func add_score(amount: int) -> void:
	performance_score += amount
	emit_signal("score_changed", performance_score)


func on_enemy_killed(variant_id: int) -> void:
	enemies_killed_total += 1
	var score_values := [10, 20, 40, 30, 25, 200]
	add_score(score_values[clamp(variant_id, 0, score_values.size() - 1)])


# The flare charges every few cleared waves, then game.gd decides when it is
# actually fired and how much damage it deals.
func on_wave_cleared() -> void:
	waves_cleared += 1
	waves_since_last_flare += 1
	if waves_since_last_flare >= 3 and flare_charge == 0:
		flare_charge = 1
		waves_since_last_flare = 0
		emit_signal("flare_charged")


func try_trigger_flare() -> bool:
	if flare_charge <= 0:
		return false
	flare_charge -= 1
	emit_signal("flare_used")
	return true


func add_burrower() -> void:
	burrowers_active += 1
	emit_signal("burrower_count_changed", burrowers_active)


func remove_burrower() -> void:
	burrowers_active = max(0, burrowers_active - 1)
	emit_signal("burrower_count_changed", burrowers_active)


func set_phase(new_phase: Phase) -> void:
	game_phase = new_phase
	emit_signal("phase_changed", new_phase)


func get_rank() -> String:
	if luminosity > 0.8:
		return "FULL SHINE"
	if luminosity > 0.6:
		return "BRIGHT"
	if luminosity > 0.2:
		return "DIM BUT ALIVE"
	return "LAST LIGHT"


func trigger_victory() -> void:
	game_phase = Phase.VICTORY
	emit_signal("victory_triggered", luminosity, get_rank())
