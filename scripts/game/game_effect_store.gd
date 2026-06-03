class_name GameEffectStore
extends RefCounted

# Stores short-lived shots and visual effects.
# game.gd draws them, but this file owns the repeated append/cleanup shapes.

var shots: Array = []
var visual_effects: Array = []


func has_activity() -> bool:
	return not shots.is_empty() or not visual_effects.is_empty()


func process_shots(delta: float) -> void:
	var active_shots: Array = []
	for shot in shots:
		shot["ttl"] = float(shot["ttl"]) - delta
		if float(shot["ttl"]) > 0.0:
			active_shots.append(shot)
	shots = active_shots


func process_visual_effects(delta: float) -> void:
	var active_effects: Array = []
	for effect in visual_effects:
		effect["ttl"] = float(effect["ttl"]) - delta
		if float(effect["ttl"]) > 0.0:
			active_effects.append(effect)
	visual_effects = active_effects


func add_visual(kind: String, pos: Vector2, color: Color, duration: float, radius: float) -> void:
	visual_effects.append({
		"kind": kind,
		"pos": pos,
		"color": color,
		"ttl": duration,
		"duration": duration,
		"radius": radius,
	})


func add_enemy_death(enemy: Dictionary, texture, draw_size: float, rotates_sprite: bool = false) -> void:
	var variant: String = str(enemy["variant"])
	var radius: float = float(enemy.get("radius", 18.0))
	var duration: float = 0.88 if variant == "prime" else 0.58
	visual_effects.append({
		"kind": "prime_death" if variant == "prime" else "enemy_death",
		"variant": variant,
		"pos": enemy.get("pos", Vector2.ZERO),
		"color": enemy.get("color", Color(1.0, 0.62, 0.36)),
		"ttl": duration,
		"duration": duration,
		"radius": radius + 20.0,
		"texture": texture,
		"draw_size": draw_size,
		"sprite_angle": float(enemy.get("sprite_angle", enemy.get("move_angle", 0.0))),
		"rotates_sprite": rotates_sprite,
	})


func add_burrower_death(pos: Vector2, color: Color) -> void:
	visual_effects.append({
		"kind": "burrower_death",
		"pos": pos,
		"color": color,
		"ttl": 0.56,
		"duration": 0.56,
		"radius": 28.0,
	})


func add_shot(shot_start: Vector2, shot_end: Vector2, color: Color, duration: float, width: float = 3.0, kind: String = "beam") -> void:
	shots.append({
		"from": shot_start,
		"to": shot_end,
		"color": color,
		"ttl": duration,
		"duration": duration,
		"width": width,
		"kind": kind,
	})


func add_text(text: String, pos: Vector2, color: Color, duration: float = 0.78, font_size: int = 16) -> void:
	visual_effects.append({
		"kind": "text",
		"text": text,
		"pos": pos,
		"color": color,
		"ttl": duration,
		"duration": duration,
		"radius": 0.0,
		"font_size": font_size,
	})
