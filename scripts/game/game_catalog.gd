extends RefCounted

# Static gameplay data lives here so game.gd can focus on runtime flow.
# If we need to tune balance, replace sprites, or explain tower/enemy stats,
# this is the first file to open.

const MAX_WAVES: int = 12
const SUN_RADIUS: float = 58.0
const SUN_DAMAGE_RADIUS: float = 62.0
const RING_RADIUS_SCALE: float = 1.5
const ENEMY_SPAWN_PADDING: float = 260.0
const SLOT_ANGLE_OFFSET: float = -PI / 2.0
const FLARE_DAMAGE: float = 95.0
const BURROWER_DIG_RADIUS: float = 74.0
const BURROWER_EXCAVATION_HP: float = 52.0
const BURROWER_DRAIN_INTERVAL: float = 1.0
const BURROWER_DRAIN_DAMAGE: float = 0.010

const ENEMY_ASSET_PATHS: Dictionary = {
	"drifter": "res://assets/sprites/enemies/Drifter.png",
	"bloom": "res://assets/sprites/enemies/Bloom.png",
	"burrower": "res://assets/sprites/enemies/Coronal Burrower.png",
	"mimic": "res://assets/sprites/enemies/Photon Mimic.png",
	"farmer": "res://assets/sprites/enemies/Solar Farmer.png",
	"prime": "res://assets/sprites/enemies/ASTROPHAGE PRIME.png",
}

# Clean enemy sprites are animation frames. Photon Mimic's pulled frames are
# transparent, so it keeps using ENEMY_ASSET_PATHS until usable frames arrive.
const ENEMY_ANIMATION_PATHS: Dictionary = {
	"drifter": {
		"idle": [
			"res://assets/sprites/clean/enemies_optimized/drifter_idle_1.png",
			"res://assets/sprites/clean/enemies_optimized/drifter_idle_2.png",
		],
		"move": [
			"res://assets/sprites/clean/enemies_optimized/drifter_move_1.png",
			"res://assets/sprites/clean/enemies_optimized/drifter_move_2.png",
			"res://assets/sprites/clean/enemies_optimized/drifter_move_3.png",
		],
	},
	"bloom": {
		"idle": [
			"res://assets/sprites/clean/enemies_optimized/bloom_idle_1.png",
			"res://assets/sprites/clean/enemies_optimized/bloom_idle_2.png",
		],
		"move": [
			"res://assets/sprites/clean/enemies_optimized/bloom_move_1.png",
			"res://assets/sprites/clean/enemies_optimized/bloom_move_2.png",
			"res://assets/sprites/clean/enemies_optimized/bloom_move_3.png",
		],
	},
	"burrower": {
		"idle": [
			"res://assets/sprites/clean/enemies_optimized/coronal_idle_1.png",
			"res://assets/sprites/clean/enemies_optimized/coronal_idle_2.png",
		],
		"move": [
			"res://assets/sprites/clean/enemies_optimized/coronal_move_1.png",
			"res://assets/sprites/clean/enemies_optimized/coronal_move_2.png",
			"res://assets/sprites/clean/enemies_optimized/coronal_move_3.png",
			"res://assets/sprites/clean/enemies_optimized/coronal_move_4.png",
		],
	},
	"farmer": {
		"idle": [
			"res://assets/sprites/clean/enemies_optimized/solar_idle_1.png",
			"res://assets/sprites/clean/enemies_optimized/solar_idle_2.png",
		],
		"move": [
			"res://assets/sprites/clean/enemies_optimized/solar_move_1.png",
			"res://assets/sprites/clean/enemies_optimized/solar_move_2.png",
			"res://assets/sprites/clean/enemies_optimized/solar_move_3.png",
		],
	},
	"prime": {
		"idle": [
			"res://assets/sprites/clean/enemies_optimized/astrophage-shell_idle_1.png",
			"res://assets/sprites/clean/enemies_optimized/astrophage-shell_idle_2.png",
		],
		"move": [
			"res://assets/sprites/clean/enemies_optimized/astrophage-shell_move_1.png",
			"res://assets/sprites/clean/enemies_optimized/astrophage-shell_move_2.png",
			"res://assets/sprites/clean/enemies_optimized/astrophage-shell_move_3.png",
			"res://assets/sprites/clean/enemies_optimized/astrophage-shell_move_4.png",
		],
	},
}

const ENEMY_ANIMATION_BASE_ANGLES: Dictionary = {
	"drifter": 0.0,
	"bloom": 0.0,
	"burrower": -PI * 0.5,
	"farmer": -PI * 0.25,
	"prime": 0.0,
}

const ENEMY_MASSES: Dictionary = {
	"drifter": 1.0,
	"bloom": 1.5,
	"burrower": 3.0,
	"mimic": 0.8,
	"farmer": 1.2,
	"prime": 8.0,
}

const ENEMY_GRAVITY_CONST: float = 5200000.0
const ENEMY_GRAVITY_ACCEL_CAP: float = 360.0
const PHYSICS_PROJECTILE_GRAVITY_CONST: float = 1450000.0
const PHYSICS_PROJECTILE_DAMAGE_RING_MULT: float = 1.15
const PHYSICS_PROJECTILE_OUTWARD_DEFLECT: float = 0.12
const PHYSICS_PROJECTILE_MAX_LIFETIME: float = 4.0
const PHYSICS_PROJECTILE_HIT_RADIUS: float = 18.0
const SLINGSHOT_COST: int = 50

# Active tower sprites use the clean generated set. Older sprite folders are
# still kept in assets for comparison and future cleanup.
const TOWER_ASSET_PATHS: Dictionary = {
	"photon_splitter": "res://assets/sprites/clean/towers/photon_splitter.png",
	"cryo_probe": "res://assets/sprites/clean/towers/cryo_probe.png",
	"bio_lab": "res://assets/sprites/clean/towers/bio_lab.png",
	"magnetic_net": "res://assets/sprites/clean/towers/magnetic_net.png",
	"helios_cannon": "res://assets/sprites/clean/towers/helios_cannon.png",
	"tardigrade_bomb": "res://assets/sprites/clean/towers/tardigrade_bomb.png",
}

# Rings are the orbit lanes. The final in-game radius is multiplied by
# RING_RADIUS_SCALE so the board can be widened without rewriting each entry.
const RINGS: Array = [
	{"id": 1, "name": "Corona Belt", "radius": 80.0, "period": 6.0, "slots": 4, "best": "Photon Splitter, Helios Cannon"},
	{"id": 2, "name": "Chromosphere Band", "radius": 140.0, "period": 11.0, "slots": 6, "best": "Cryo Probe, Tardigrade Bomb"},
	{"id": 3, "name": "Photosphere Arc", "radius": 210.0, "period": 17.0, "slots": 8, "best": "Bio-Lab Station, Magnetic Net"},
	{"id": 4, "name": "Outer Veil", "radius": 290.0, "period": 26.0, "slots": 10, "best": "Early intercept"},
]

const VARIANT_KEYS: Array = ["drifter", "bloom", "burrower", "mimic", "farmer", "prime"]

const TOWER_ORDER: Array = [
	"photon_splitter",
	"cryo_probe",
	"bio_lab",
	"magnetic_net",
	"helios_cannon",
	"tardigrade_bomb",
]

const TOWER_CONFIGS: Dictionary = {
	"photon_splitter": {"label": "Photon Splitter", "damage": 17.0, "rate": 0.95, "range": 235.0, "color": Color(1.0, 0.86, 0.28)},
	"cryo_probe": {"label": "Cryo Probe", "damage": 6.0, "rate": 0.62, "range": 245.0, "color": Color(0.34, 0.86, 1.0)},
	"bio_lab": {"label": "Bio-Lab Station", "damage": 12.0, "rate": 0.60, "range": 260.0, "color": Color(0.46, 1.0, 0.52)},
	"magnetic_net": {"label": "Magnetic Net", "damage": 5.0, "rate": 0.48, "range": 285.0, "color": Color(0.76, 0.62, 1.0)},
	"helios_cannon": {"label": "Helios Cannon", "damage": 84.0, "rate": 0.16, "range": 305.0, "color": Color(1.0, 0.43, 0.22)},
	"tardigrade_bomb": {"label": "Tardigrade Bomb", "damage": 24.0, "rate": 0.42, "range": 260.0, "color": Color(1.0, 0.58, 0.76)},
}

# Text shown by the tower hover cards. Keeping it beside the stats makes it
# easier to explain why each tower exists.
const TOWER_INFO: Dictionary = {
	"photon_splitter": {
		"role": "STEADY BEAM  |  EARLY INTERCEPT",
		"body": "Fast, reliable single-target damage for thinning the first Astrophage lines.",
		"note": "Caution: Photon Mimics ignore it and Solar Farmers feed on photon fire.",
	},
	"cryo_probe": {
		"role": "CONTROL  |  SLOW FIELD",
		"body": "Low damage, but every hit chills targets and cuts their speed for a short window.",
		"note": "Can be forced offline by solar storm events.",
	},
	"bio_lab": {
		"role": "SUPPORT  |  EXCAVATION",
		"body": "Analyzes weak points, clears Coronal Burrowers, and can crack Prime's shell.",
		"note": "Research surge events can temporarily multiply Bio-Lab fire rate.",
	},
	"magnetic_net": {
		"role": "CONTROL  |  LONG RANGE",
		"body": "Wide reach and slow effects make it strong at keeping enemies inside kill zones.",
		"note": "Pair with high-damage towers to capitalize on slowed targets.",
	},
	"helios_cannon": {
		"role": "BURST  |  HEAVY ORDNANCE",
		"body": "Slow-firing cannon with high impact damage and excellent range.",
		"note": "Caution: Solar Farmers absorb Helios fire and accelerate.",
	},
	"tardigrade_bomb": {
		"role": "HEAVY SHOT  |  FINISHER",
		"body": "Delivers chunky damage at a measured pace for tougher enemies that survive the net.",
		"note": "Best after Cryo or Magnetic Net has slowed the lane.",
	},
}

# Enemy stats are used when game.gd spawns enemies from JSON wave files.
const ENEMY_CONFIGS: Dictionary = {
	"drifter": {"variant_id": 0, "label": "Drifter", "hp": 32.0, "speed": 47.0, "damage": 0.05, "reward": 6, "radius": 15.0, "draw_size": 46.0, "color": Color(0.96, 0.42, 0.48)},
	"bloom": {"variant_id": 1, "label": "Bloom", "hp": 68.0, "speed": 42.0, "damage": 0.05, "reward": 12, "radius": 18.0, "draw_size": 54.0, "color": Color(1.0, 0.62, 0.36)},
	"burrower": {"variant_id": 2, "label": "Coronal Burrower", "hp": 120.0, "speed": 31.0, "damage": 0.08, "reward": 24, "radius": 19.0, "draw_size": 58.0, "color": Color(0.76, 0.50, 0.30)},
	"mimic": {"variant_id": 3, "label": "Photon Mimic", "hp": 58.0, "speed": 48.0, "damage": 0.05, "reward": 17, "radius": 16.0, "draw_size": 48.0, "color": Color(0.70, 0.62, 0.98)},
	"farmer": {"variant_id": 4, "label": "Solar Farmer", "hp": 50.0, "speed": 44.0, "damage": 0.05, "reward": 15, "radius": 17.0, "draw_size": 50.0, "color": Color(0.55, 0.92, 0.45)},
	"prime": {"variant_id": 5, "label": "Astrophage Prime", "hp": 560.0, "speed": 23.0, "damage": 0.12, "reward": 130, "radius": 34.0, "draw_size": 84.0, "color": Color(1.0, 0.18, 0.15)},
}
