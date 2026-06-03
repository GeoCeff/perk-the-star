class_name GameTowerLibrary
extends RefCounted

# Tower balance/readout helper.
# game.gd still decides when towers are placed, upgraded, sold, and fired; this
# file only calculates stats, costs, refunds, and HUD text from tower data.

const GameCatalog = preload("res://scripts/game/game_catalog.gd")

const MAX_LEVEL: int = 3
const DAMAGE_LEVEL_BONUS: float = 0.28
const RATE_LEVEL_BONUS: float = 0.16
const RANGE_LEVEL_BONUS: float = 0.07
const SELL_REFUND_RATIO: float = 0.60

const TOWER_ORDER: Array = GameCatalog.TOWER_ORDER
const TOWER_CONFIGS: Dictionary = GameCatalog.TOWER_CONFIGS
const TOWER_INFO: Dictionary = GameCatalog.TOWER_INFO


static func config(tower_type: String) -> Dictionary:
	return TOWER_CONFIGS.get(tower_type, TOWER_CONFIGS["photon_splitter"])


static func info(tower_type: String) -> Dictionary:
	return TOWER_INFO.get(tower_type, TOWER_INFO["photon_splitter"])


static func level(tower: Dictionary) -> int:
	return max(1, min(MAX_LEVEL, int(tower.get("level", 1))))


static func stats_for_level(tower_type: String, tower_level: int) -> Dictionary:
	var cfg: Dictionary = config(tower_type)
	var clamped_level: int = max(1, min(MAX_LEVEL, tower_level))
	var step: float = float(clamped_level - 1)
	return {
		"label": cfg["label"],
		"damage": float(cfg["damage"]) * (1.0 + DAMAGE_LEVEL_BONUS * step),
		"rate": float(cfg["rate"]) * (1.0 + RATE_LEVEL_BONUS * step),
		"range": float(cfg["range"]) * (1.0 + RANGE_LEVEL_BONUS * step),
		"color": cfg["color"],
	}


static func runtime_stats(tower: Dictionary) -> Dictionary:
	return stats_for_level(str(tower["type"]), level(tower))


static func upgrade_cost(tower: Dictionary) -> int:
	var tower_level: int = level(tower)
	if tower_level >= MAX_LEVEL:
		return 0
	var base_cost: int = GameState.get_upgrade_cost(str(tower["type"]))
	return int(round(float(base_cost) * pow(1.45, float(tower_level - 1))))


static func total_spent(tower: Dictionary) -> int:
	return int(tower.get("spent", GameState.get_tower_cost(str(tower["type"]))))


static func sell_refund(tower: Dictionary) -> int:
	return max(1, int(round(float(total_spent(tower)) * SELL_REFUND_RATIO)))


static func short_label(tower_type: String) -> String:
	match tower_type:
		"photon_splitter":
			return "PHOTON"
		"cryo_probe":
			return "CRYO"
		"bio_lab":
			return "BIO-LAB"
		"magnetic_net":
			return "MAG NET"
		"helios_cannon":
			return "HELIOS"
		"tardigrade_bomb":
			return "TARDI"
		_:
			return str(config(tower_type)["label"]).to_upper()


static func selected_readout(tower_type: String, live_build: bool) -> String:
	var cfg: Dictionary = config(tower_type)
	var cost: int = GameState.get_tower_cost(tower_type)
	if live_build:
		return "LIVE BUILD  |  %s  |  %d SOL" % [str(cfg["label"]).to_upper(), cost]
	return "%s READY  |  %d SOL" % [str(cfg["label"]).to_upper(), cost]


static func managed_view_data(tower: Dictionary, rings: Array) -> Dictionary:
	var tower_type: String = str(tower["type"])
	var cfg: Dictionary = config(tower_type)
	var tower_level: int = level(tower)
	var current_stats: Dictionary = stats_for_level(tower_type, tower_level)
	var next_stats: Dictionary = stats_for_level(tower_type, min(MAX_LEVEL, tower_level + 1))
	var next_cost: int = upgrade_cost(tower)
	var refund: int = sell_refund(tower)
	var can_upgrade: bool = tower_level < MAX_LEVEL
	var can_afford: bool = next_cost <= 0 or GameState.can_afford(next_cost)
	var upgrade_cost_text: String = "MAX"
	var upgrade_button_text: String = "MAX\nLEVEL"
	if can_upgrade:
		upgrade_cost_text = "%d SOL" % next_cost
		upgrade_button_text = "UPGRADE\n%d SOL" % next_cost
		if not can_afford:
			upgrade_button_text = "NEED\n%d SOL" % next_cost

	var stats_text: String = "DMG %.0f  |  RATE %.2f/S  |  RANGE %.0f" % [
		float(current_stats["damage"]),
		float(current_stats["rate"]),
		float(current_stats["range"]),
	]
	if can_upgrade:
		stats_text += "\nNEXT  DMG +%.0f  |  RATE +%.2f/S  |  RANGE +%.0f" % [
			float(next_stats["damage"]) - float(current_stats["damage"]),
			float(next_stats["rate"]) - float(current_stats["rate"]),
			float(next_stats["range"]) - float(current_stats["range"]),
		]
		stats_text += "\nAFTER %.0f  |  %.2f/S  |  %.0f" % [
			float(next_stats["damage"]),
			float(next_stats["rate"]),
			float(next_stats["range"]),
		]

	return {
		"title": str(cfg["label"]),
		"meta": "R%d %s  |  SLOT %d  |  LEVEL %d/%d" % [
			int(tower["ring"]) + 1,
			str(rings[int(tower["ring"])]["name"]).to_upper(),
			int(tower["slot"]) + 1,
			tower_level,
			MAX_LEVEL,
		],
		"stats": stats_text,
		"economy": "UPGRADE %s  |  SELL REFUND +%d SOL" % [upgrade_cost_text, refund],
		"upgrade_text": upgrade_button_text,
		"sell_text": "SELL\n+%d SOL" % refund,
		"upgrade_disabled": not can_upgrade or not can_afford,
		"sell_disabled": false,
		"ring_index": int(tower["ring"]),
		"slot_index": int(tower["slot"]),
		"accent": cfg["color"],
	}


static func button_view_data(selected_tower: String, can_build: bool, tower_textures: Dictionary) -> Dictionary:
	var button_states: Dictionary = {}
	for index in range(TOWER_ORDER.size()):
		var tower_type: String = str(TOWER_ORDER[index])
		var cost: int = GameState.get_tower_cost(tower_type)
		var cfg: Dictionary = config(tower_type)
		var tower_info: Dictionary = info(tower_type)
		button_states[tower_type] = {
			"text": "%d  %s\n%d SOL" % [index + 1, short_label(tower_type), cost],
			"info": {
				"title": str(cfg["label"]).to_upper(),
				"role": "KEY %d  |  %s  |  %d SOL" % [index + 1, str(tower_info["role"]), cost],
				"stats": "DAMAGE %.0f  |  RATE %.2f/S  |  RANGE %.0f" % [float(cfg["damage"]), float(cfg["rate"]), float(cfg["range"])],
				"body": str(tower_info["body"]),
				"note": str(tower_info["note"]),
				"accent": cfg["color"],
			},
			"pressed": tower_type == selected_tower,
			"disabled": not can_build or not GameState.can_afford(cost),
			"icon": tower_textures.get(tower_type, null),
		}
	return button_states
