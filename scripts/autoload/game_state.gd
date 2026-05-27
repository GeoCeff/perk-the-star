extends Node
# ─────────────────────────────────────────
#  CORE GAME STATS
# ─────────────────────────────────────────
var luminosity: float = 1.0          # 0.0 (dead) to 1.0 (full health)
var sol_credits: int = 50            # starting economy
var current_wave: int = 0            # 0 = not started, 1–12 = active
var flare_charge: int = 0            # 0 or 1
var waves_since_last_flare: int = 0
var performance_score: int = 0
var enemies_killed_total: int = 0
var waves_cleared: int = 0
var burrowers_active: int = 0        # track active burrowers for UI
var music_enabled: bool = true
var music_volume: float = 0.72

# ─────────────────────────────────────────
#  GAME PHASE
# ─────────────────────────────────────────
enum Phase { MENU, BETWEEN_WAVE, WAVE_ACTIVE, PAUSED, GAME_OVER, VICTORY }
var game_phase: Phase = Phase.MENU

# ─────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────
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

# ─────────────────────────────────────────
#  INITIALIZATION
# ─────────────────────────────────────────
func _ready():
	reset_state()
	load_audio_settings()

func reset_state():
	luminosity = 1.0
	sol_credits = 50
	current_wave = 0
	flare_charge = 0
	waves_since_last_flare = 0
	performance_score = 0
	enemies_killed_total = 0
	waves_cleared = 0
	burrowers_active = 0
	game_phase = Phase.MENU

func load_audio_settings():
	var config := ConfigFile.new()
	var error := config.load("user://settings.cfg")
	if error != OK:
		return
	music_enabled = bool(config.get_value("audio", "music_enabled", music_enabled))
	music_volume = clamp(float(config.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	emit_signal("music_settings_changed", music_enabled, music_volume)

func save_audio_settings():
	var config := ConfigFile.new()
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "music_volume", music_volume)
	config.save("user://settings.cfg")

func set_music_enabled(enabled: bool):
	music_enabled = enabled
	save_audio_settings()
	emit_signal("music_settings_changed", music_enabled, music_volume)

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	save_audio_settings()
	emit_signal("music_settings_changed", music_enabled, music_volume)

func get_music_volume_db() -> float:
	if not music_enabled or music_volume <= 0.0:
		return -80.0
	return linear_to_db(music_volume)

# ─────────────────────────────────────────
#  LUMINOSITY SYSTEM
# ─────────────────────────────────────────
func damage_sun(amount: float):
	if game_phase == Phase.GAME_OVER:
		return
	luminosity = clamp(luminosity - amount, 0.0, 1.0)
	emit_signal("luminosity_changed", luminosity)
	if luminosity <= 0.0:
		_trigger_game_over()

func _trigger_game_over():
	game_phase = Phase.GAME_OVER
	emit_signal("game_over_triggered", luminosity, current_wave)

func get_luminosity_percent() -> int:
	return int(luminosity * 100.0)

# ─────────────────────────────────────────
#  SOL CREDITS SYSTEM
# ─────────────────────────────────────────
func add_credits(amount: int):
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

# ─────────────────────────────────────────
#  TOWER COST LOOKUP
# ─────────────────────────────────────────
const TOWER_COSTS: Dictionary = {
	"photon_splitter":  25,
	"cryo_probe":       30,
	"bio_lab":          50,
	"magnetic_net":     45,
	"helios_cannon":    80,
	"tardigrade_bomb":  70,
}

const TOWER_UPGRADE_COSTS: Dictionary = {
	"photon_splitter":  40,
	"cryo_probe":       45,
	"bio_lab":          75,
	"magnetic_net":     60,
	"helios_cannon":    120,
	"tardigrade_bomb":  100,
}

func get_tower_cost(tower_type: String) -> int:
	return TOWER_COSTS.get(tower_type, 30)

func get_upgrade_cost(tower_type: String) -> int:
	return TOWER_UPGRADE_COSTS.get(tower_type, 50)

# ─────────────────────────────────────────
#  SCORE SYSTEM
# ─────────────────────────────────────────
func add_score(amount: int):
	performance_score += amount
	emit_signal("score_changed", performance_score)

func on_enemy_killed(variant_id: int):
	enemies_killed_total += 1
	var score_values = [10, 20, 40, 30, 25, 200]  # per Astrophage.Variant order
	add_score(score_values[clamp(variant_id, 0, score_values.size()-1)])

# ─────────────────────────────────────────
#  FLARE SYSTEM
# ─────────────────────────────────────────
func on_wave_cleared():
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

# ─────────────────────────────────────────
#  BURROWER TRACKING
# ─────────────────────────────────────────
func add_burrower():
	burrowers_active += 1
	emit_signal("burrower_count_changed", burrowers_active)

func remove_burrower():
	burrowers_active = max(0, burrowers_active - 1)
	emit_signal("burrower_count_changed", burrowers_active)

# ─────────────────────────────────────────
#  PHASE MANAGEMENT
# ─────────────────────────────────────────
func set_phase(new_phase: Phase):
	game_phase = new_phase
	emit_signal("phase_changed", new_phase)

# ─────────────────────────────────────────
#  END GAME
# ─────────────────────────────────────────
func get_rank() -> String:
	if luminosity > 0.8:  return "FULL SHINE"
	if luminosity > 0.6:  return "BRIGHT"
	if luminosity > 0.2:  return "DIM BUT ALIVE"
	return "LAST LIGHT"

func trigger_victory():
	game_phase = Phase.VICTORY
	emit_signal("victory_triggered", luminosity, get_rank())
