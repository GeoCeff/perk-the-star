class_name GameOrbitMath
extends RefCounted

# Orbital board geometry helper.
# It keeps ring radius, slot angle, slot lookup, and readout text out of the
# gameplay controller.

const GameCatalog = preload("res://scripts/game/game_catalog.gd")

const RINGS: Array = GameCatalog.RINGS
const RING_RADIUS_SCALE: float = GameCatalog.RING_RADIUS_SCALE
const SLOT_ANGLE_OFFSET: float = GameCatalog.SLOT_ANGLE_OFFSET


static func nearest_ring_slot(pos: Vector2, sun_pos: Vector2, occupied_lookup: Callable) -> Dictionary:
	var best: Dictionary = {}
	var best_diff: float = INF
	for i in range(RINGS.size()):
		var ring: Dictionary = RINGS[i]
		var diff: float = abs(pos.distance_to(sun_pos) - ring_radius(i))
		if diff < 28.0 and diff < best_diff:
			var angle: float = (pos - sun_pos).angle()
			var slot_index: int = nearest_slot_index(i, angle)
			best = {
				"ring_index": i,
				"ring_name": ring["name"],
				"slot_index": slot_index,
				"angle": ring_slot_angle(i, slot_index),
				"occupied": bool(occupied_lookup.call(i, slot_index)),
			}
			best_diff = diff
	return best


static func nearest_slot_index(ring_index: int, angle: float) -> int:
	var slots: int = int(RINGS[ring_index]["slots"])
	var step: float = TAU / float(slots)
	var normalized: float = wrapf(angle - SLOT_ANGLE_OFFSET, 0.0, TAU)
	return int(round(normalized / step)) % slots


static func ring_slot_angle(ring_index: int, slot_index: int) -> float:
	var slots: int = int(RINGS[ring_index]["slots"])
	return wrapf(SLOT_ANGLE_OFFSET + TAU * float(slot_index) / float(slots), 0.0, TAU)


static func ring_slot_position(sun_pos: Vector2, ring_index: int, slot_index: int) -> Vector2:
	var angle: float = ring_slot_angle(ring_index, slot_index)
	return sun_pos + Vector2(cos(angle), sin(angle)) * ring_radius(ring_index)


static func ring_radius(ring_index: int) -> float:
	return float(RINGS[ring_index]["radius"]) * RING_RADIUS_SCALE


static func outer_ring_radius() -> float:
	return ring_radius(RINGS.size() - 1)


static func tower_position(sun_pos: Vector2, tower: Dictionary) -> Vector2:
	return sun_pos + Vector2(cos(float(tower["angle"])), sin(float(tower["angle"]))) * ring_radius(int(tower["ring"]))


static func burrower_position(sun_pos: Vector2, burrower: Dictionary, dig_radius: float) -> Vector2:
	return sun_pos + Vector2(cos(float(burrower["angle"])), sin(float(burrower["angle"]))) * dig_radius


static func ring_summary() -> String:
	var parts: Array = []
	for ring in RINGS:
		var short_name: String = str(ring["name"]).replace(" Belt", "").replace(" Band", "").replace(" Arc", "").replace("Outer ", "")
		parts.append("R%d %s %d slots" % [int(ring["id"]), short_name, int(ring["slots"])])
	return "RINGS: %s\n%s" % ["  |  ".join(parts.slice(0, 2)), "       %s" % "  |  ".join(parts.slice(2, 4))]
