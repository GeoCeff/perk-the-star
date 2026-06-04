class_name GameWaveLibrary
extends RefCounted

# Wave files are plain JSON. This helper turns those files into the compact
# dictionaries used by game.gd and builds the readable Wave Intel text.

const GameCatalog = preload("res://scripts/game/game_catalog.gd")

const VARIANT_KEYS: Array = GameCatalog.VARIANT_KEYS
const ENEMY_CONFIGS: Dictionary = GameCatalog.ENEMY_CONFIGS


static func load_wave(wave_number: int) -> Dictionary:
	var path: String = "res://data/waves/wave_%02d.json" % wave_number
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return normalize_wave_data(parsed, wave_number)


static func normalize_wave_data(data: Dictionary, wave_number: int) -> Dictionary:
	var default_interval: float = maxf(float(data.get("spawn_interval", 2.0)), 0.05)
	var spawns: Array = []
	var clash_groups: Array = []
	var wave_type: String = str(data.get("wave_type", "normal")).strip_edges().to_lower()
	if not ["normal", "formation", "clash", "boss"].has(wave_type):
		wave_type = "normal"
	var event_data = data.get("event", {})
	if not (event_data is Dictionary):
		event_data = {}
	var formation_data = data.get("formation", {})
	if not (formation_data is Dictionary):
		formation_data = {}

	if data.has("spawns"):
		for entry in _array_value(data.get("spawns", [])):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			spawns.append({
				"variant": variant_key(entry.get("variant", 0)),
				"count": max(0, int(entry.get("count", 0))),
				"interval": maxf(float(entry.get("interval", default_interval)), 0.05),
			})
	elif data.has("enemies"):
		for entry in _array_value(data.get("enemies", [])):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			spawns.append({
				"variant": variant_key(entry.get("variant", "drifter")),
				"count": max(0, int(entry.get("count", 0))),
				"interval": default_interval,
			})

	for raw_group in _array_value(data.get("clash_groups", [])):
		if typeof(raw_group) != TYPE_DICTIONARY:
			continue
		var variants: Array = []
		for raw_variant in _array_value(raw_group.get("variants", [])):
			variants.append(variant_key(raw_variant))
		if variants.is_empty():
			continue
		var normalized_group: Dictionary = {
			"variants": variants,
			"spawn_pattern": str(raw_group.get("spawn_pattern", "random")).strip_edges().to_lower(),
			"delay_before": maxf(float(raw_group.get("delay_before", 0.0)), 0.0),
		}
		if raw_group.has("spread_angle_deg"):
			normalized_group["spread_angle_deg"] = float(raw_group.get("spread_angle_deg", 60.0))
		if raw_group.has("spiral_arms"):
			normalized_group["spiral_arms"] = max(1, int(raw_group.get("spiral_arms", 1)))
		clash_groups.append(normalized_group)

	if not formation_data.is_empty():
		var formation_variants: Array = []
		for raw_variant in _array_value(formation_data.get("variants", ["drifter"])):
			formation_variants.append(variant_key(raw_variant))
		if formation_variants.is_empty():
			formation_variants.append("drifter")
		formation_data = {
			"type": str(formation_data.get("type", "ring")).strip_edges().to_lower(),
			"variants": formation_variants,
			"count": max(0, int(formation_data.get("count", 0))),
			"spread_angle_deg": float(formation_data.get("spread_angle_deg", 60.0)),
			"spiral_arms": max(1, int(formation_data.get("spiral_arms", 1))),
		}

	return {
		"index": int(data.get("index", data.get("wave", wave_number))),
		"name": str(data.get("name", "Wave %02d" % wave_number)),
		"wave_type": wave_type,
		"spawn_interval": default_interval,
		"credit_reward": int(data.get("credit_reward", data.get("reward_base", 0))),
		"spawns": spawns,
		"clash_groups": clash_groups,
		"formation": formation_data,
		"event": event_data,
		"escalation_threshold_seconds": data.get("escalation_threshold_seconds", null),
		"tutorial_hint": str(data.get("tutorial_hint", "Defend the Sun.")),
	}


static func build_spawn_queue(wave_data: Dictionary) -> Array:
	var queue: Array = []
	var wave_type: String = str(wave_data.get("wave_type", "normal"))
	if wave_type == "clash" or wave_type == "boss":
		return queue
	for entry in _spawn_entries(wave_data):
		var variant: String = variant_key(entry.get("variant", 0))
		var count: int = max(0, int(entry.get("count", 0)))
		var interval: float = maxf(float(entry.get("interval", 2.0)), 0.05)
		for _i in range(count):
			queue.append({"variant": variant, "interval": interval})
	return queue


static func variant_key(raw) -> String:
	if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
		var idx: int = int(raw)
		if idx >= 0 and idx < VARIANT_KEYS.size():
			return VARIANT_KEYS[idx]
		return "drifter"

	var cleaned: String = str(raw).strip_edges().to_lower()
	if cleaned.is_valid_int():
		return variant_key(cleaned.to_int())
	cleaned = cleaned.replace(" ", "_").replace("-", "_")
	match cleaned:
		"drifter":
			return "drifter"
		"bloom":
			return "bloom"
		"burrower", "coronal_burrower":
			return "burrower"
		"mimic", "photon_mimic":
			return "mimic"
		"farmer", "solar_farmer":
			return "farmer"
		"prime", "astrophage_prime":
			return "prime"
		_:
			return "drifter"


static func primary_variant(wave_data: Dictionary) -> String:
	var spawns: Array = _spawn_entries(wave_data)
	if spawns.is_empty():
		return "drifter"
	return variant_key(spawns[0].get("variant", "drifter"))


static func spawn_summary(wave_data: Dictionary) -> String:
	var parts: Array = []
	for entry in _spawn_entries(wave_data):
		var variant: String = variant_key(entry.get("variant", 0))
		parts.append("%d %s" % [int(entry.get("count", 0)), enemy_short_label(variant)])
	return ", ".join(parts) if not parts.is_empty() else "No spawns loaded"


static func warning_tags(wave_data: Dictionary) -> String:
	var tags: Array = []
	var seen: Dictionary = {}
	var wave_type: String = str(wave_data.get("wave_type", "normal"))
	match wave_type:
		"clash":
			tags.append("CLASH")
		"formation":
			tags.append("FORMATION")
		"boss":
			tags.append("BOSS")

	for entry in _spawn_entries(wave_data):
		var variant: String = variant_key(entry.get("variant", 0))
		if seen.has(variant):
			continue
		seen[variant] = true
		match variant:
			"bloom":
				tags.append("SPLIT")
			"burrower":
				tags.append("BURROW")
			"mimic":
				tags.append("MIMIC")
			"farmer":
				tags.append("ABSORB")
			"prime":
				tags.append("PRIME")

	var event_data = wave_data.get("event", {})
	var event_type: String = ""
	if event_data is Dictionary:
		event_type = str(event_data.get("type", ""))
	match event_type:
		"mid_wave_autoflare":
			tags.append("STORM")
		"ring_blind":
			tags.append("RING DARK")
		"bio_lab_boost":
			tags.append("BIO BOOST")
		"prime_frenzy":
			tags.append("FRENZY")

	return "TAGS: %s" % "  |  ".join(tags) if not tags.is_empty() else "TAGS: BASIC SWARM"


static func counter_hint(wave_data: Dictionary) -> String:
	var variants: Dictionary = {}
	for entry in _spawn_entries(wave_data):
		variants[variant_key(entry.get("variant", 0))] = true
	if variants.has("prime"):
		return "COUNTER: Bio-Lab opens shell, then Helios/Tardigrade finish."
	if variants.has("farmer"):
		return "COUNTER: Cryo or Magnetic first; avoid feeding Farmers with energy."
	if variants.has("mimic"):
		return "COUNTER: Mix Bio-Lab, Cryo, Magnetic, or Helios with Photon."
	if variants.has("burrower"):
		return "COUNTER: Build Bio-Lab before Burrowers reach the Sun."
	if variants.has("bloom"):
		return "COUNTER: Slow Blooms before they split into Drifters."
	return "COUNTER: Photon Splitters handle the first swarm cleanly."


static func intel_detail(wave_data: Dictionary, reward: int, active_count: int = -1, burrowed_count: int = 0, queued_count: int = 0, modifier_summary: String = "") -> String:
	var detail: String = "REWARD +%d SOL\n%s\n%s" % [reward, warning_tags(wave_data), counter_hint(wave_data)]
	var type_line: String = preview_label(wave_data).to_upper()
	if type_line != "":
		detail = "%s\n%s" % [type_line, detail]
	if active_count >= 0:
		detail = "ACTIVE %d  |  BURROWED %d  |  QUEUE %d\n%s%s" % [
			active_count,
			burrowed_count,
			queued_count,
			detail,
			modifier_summary.to_upper(),
		]
	return detail


static func clean_hint(text: String, wave_name: String) -> String:
	var repeated_prefix: String = "%s: " % wave_name
	if text.begins_with(repeated_prefix):
		return text.substr(repeated_prefix.length())
	return text


static func enemy_short_label(variant: String) -> String:
	match variant:
		"burrower":
			return "Burrower"
		"mimic":
			return "Mimic"
		"farmer":
			return "Farmer"
		"prime":
			return "Prime"
		_:
			return str(ENEMY_CONFIGS.get(variant, ENEMY_CONFIGS["drifter"])["label"])


static func total_spawn_count(wave_data: Dictionary) -> int:
	var wave_type: String = str(wave_data.get("wave_type", "normal"))
	if wave_type == "clash" or wave_type == "boss":
		var total: int = 0
		for group in _array_value(wave_data.get("clash_groups", [])):
			if group is Dictionary:
				total += _array_value(group.get("variants", [])).size()
		return total

	var count: int = 0
	for entry in _spawn_entries(wave_data):
		count += max(0, int(entry.get("count", 0)))
	if wave_type == "formation":
		var formation = wave_data.get("formation", {})
		if formation is Dictionary:
			count += max(0, int(formation.get("count", 0)))
	return count


static func preview_label(wave_data: Dictionary) -> String:
	var count: int = total_spawn_count(wave_data)
	match str(wave_data.get("wave_type", "normal")):
		"clash":
			return "Massive wave approaching - %d enemies" % count
		"boss":
			return "Astrophage Prime detected - %d contacts" % count
		"formation":
			return "Formation wave incoming - %d enemies" % count
		_:
			return "Wave incoming - %d enemies" % count


static func _spawn_entries(wave_data: Dictionary) -> Array:
	return _array_value(wave_data.get("spawns", []))


static func _array_value(value) -> Array:
	if value is Array:
		return value
	return []
