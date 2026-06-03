class_name GameViewController
extends RefCounted

# Camera/view helper for the gameplay scene.
# It owns pan/zoom state and coordinate conversion so game.gd can stay focused
# on gameplay decisions.

const ZOOM_MIN: float = 0.65
const ZOOM_MAX: float = 1.85
const ZOOM_STEP: float = 1.12
const EDGE_PAN_MARGIN: float = 34.0
const EDGE_PAN_BOTTOM_MARGIN: float = 92.0
const EDGE_PAN_SPEED: float = 560.0
const KEY_PAN_SPEED: float = 520.0

var last_viewport_size: Vector2 = Vector2.ZERO
var offset: Vector2 = Vector2.ZERO
var zoom: float = 1.0
var panning: bool = false


func remember_viewport_size(viewport_size: Vector2) -> void:
	last_viewport_size = viewport_size


func viewport_changed(viewport_size: Vector2) -> bool:
	return viewport_size != last_viewport_size


func process_edge_pan(delta: float, viewport_rect: Rect2, mouse_position: Vector2, hud_blocks_mouse: bool, outer_radius: float) -> bool:
	if panning:
		return false
	if not viewport_rect.has_point(mouse_position):
		return false

	var direction: Vector2 = Vector2.ZERO
	if mouse_position.x <= EDGE_PAN_MARGIN:
		direction.x = 1.0
	elif mouse_position.x >= viewport_rect.size.x - EDGE_PAN_MARGIN:
		direction.x = -1.0

	if mouse_position.y <= EDGE_PAN_MARGIN:
		direction.y = 1.0
	elif mouse_position.y >= viewport_rect.size.y - EDGE_PAN_BOTTOM_MARGIN:
		direction.y = -1.0

	if direction == Vector2.ZERO:
		return false
	if hud_blocks_mouse and not _in_edge_gutter(mouse_position, viewport_rect.size):
		return false

	offset += direction.normalized() * EDGE_PAN_SPEED * delta
	clamp_to_board(viewport_rect.size, outer_radius)
	return true


func process_keyboard_pan(delta: float, viewport_size: Vector2, outer_radius: float) -> bool:
	var direction: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y -= 1.0

	if direction == Vector2.ZERO:
		return false

	offset += direction.normalized() * KEY_PAN_SPEED * delta
	clamp_to_board(viewport_size, outer_radius)
	return true


func pan_by(relative_motion: Vector2, viewport_size: Vector2, outer_radius: float) -> void:
	offset += relative_motion
	clamp_to_board(viewport_size, outer_radius)


func set_zoom(next_zoom: float, focus_screen_position: Vector2, viewport_size: Vector2, outer_radius: float) -> void:
	var focus_world_position: Vector2 = screen_to_world(focus_screen_position, viewport_size)
	zoom = clampf(next_zoom, ZOOM_MIN, ZOOM_MAX)
	var center: Vector2 = viewport_size * 0.5
	offset = focus_screen_position - center - (focus_world_position - center) * zoom
	clamp_to_board(viewport_size, outer_radius)


func reset() -> void:
	offset = Vector2.ZERO
	zoom = 1.0


func translation(viewport_size: Vector2) -> Vector2:
	var center: Vector2 = viewport_size * 0.5
	return center + offset - center * zoom


func screen_to_world(screen_position: Vector2, viewport_size: Vector2) -> Vector2:
	var center: Vector2 = viewport_size * 0.5
	return center + (screen_position - center - offset) / zoom


func world_to_screen(world_position: Vector2, viewport_size: Vector2) -> Vector2:
	var center: Vector2 = viewport_size * 0.5
	return (world_position - center) * zoom + center + offset


func clamp_to_board(viewport_size: Vector2, outer_radius: float) -> void:
	var max_offset: Vector2 = Vector2(
		maxf(outer_radius * 1.38, viewport_size.x * 0.42),
		maxf(outer_radius * 1.10, viewport_size.y * 0.34)
	) * zoom
	offset.x = clampf(offset.x, -max_offset.x, max_offset.x)
	offset.y = clampf(offset.y, -max_offset.y, max_offset.y)


func _in_edge_gutter(mouse_position: Vector2, viewport_size: Vector2) -> bool:
	return (
		mouse_position.x <= EDGE_PAN_MARGIN
		or mouse_position.x >= viewport_size.x - EDGE_PAN_MARGIN
		or mouse_position.y <= EDGE_PAN_MARGIN
		or mouse_position.y >= viewport_size.y - EDGE_PAN_BOTTOM_MARGIN
	)
