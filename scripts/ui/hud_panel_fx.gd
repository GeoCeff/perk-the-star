extends Control

const FRAME_TARGET_PATHS: Array[String] = [
	"../TopPanel",
	"../StatusPanel",
	"../ActionsPanel",
	"../WaveIntel",
	"../BottomRow/TowerPanel",
	"../BottomRow/MessagePanel",
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for path in FRAME_TARGET_PATHS:
		var target: Control = get_node_or_null(NodePath(path)) as Control
		if target == null or not target.visible:
			continue
		_draw_hud_frame(_local_rect_for_target(target).grow(4.0))


func _local_rect_for_target(target: Control) -> Rect2:
	var target_rect: Rect2 = target.get_global_rect()
	var inverse: Transform2D = get_global_transform().affine_inverse()
	return Rect2(inverse * target_rect.position, target_rect.size)


func _draw_hud_frame(rect: Rect2) -> void:
	if rect.size.x <= 8.0 or rect.size.y <= 8.0:
		return

	var cyan: Color = Color(0.18, 0.82, 0.96, 0.68)
	var cyan_soft: Color = Color(0.18, 0.82, 0.96, 0.16)
	var gold: Color = Color(1.0, 0.78, 0.26, 0.78)
	var corner: float = clampf(minf(rect.size.x, rect.size.y) * 0.32, 18.0, 42.0)

	draw_rect(rect, cyan_soft, false, 1.0)
	_draw_corner(rect.position, Vector2.RIGHT, Vector2.DOWN, corner, cyan, gold)
	_draw_corner(rect.position + Vector2(rect.size.x, 0.0), Vector2.LEFT, Vector2.DOWN, corner, cyan, gold)
	_draw_corner(rect.position + Vector2(0.0, rect.size.y), Vector2.RIGHT, Vector2.UP, corner, cyan, gold)
	_draw_corner(rect.position + rect.size, Vector2.LEFT, Vector2.UP, corner, cyan, gold)

	if rect.size.x > 190.0:
		var rail: float = minf(72.0, rect.size.x * 0.18)
		var center_x: float = rect.position.x + rect.size.x * 0.5
		draw_line(Vector2(center_x - rail, rect.position.y), Vector2(center_x + rail, rect.position.y), gold, 1.2)
		draw_line(Vector2(center_x - rail, rect.position.y + rect.size.y), Vector2(center_x + rail, rect.position.y + rect.size.y), gold, 1.2)

	if rect.size.y > 92.0:
		var rail_y: float = minf(38.0, rect.size.y * 0.22)
		var center_y: float = rect.position.y + rect.size.y * 0.5
		draw_line(Vector2(rect.position.x, center_y - rail_y), Vector2(rect.position.x, center_y + rail_y), cyan, 1.0)
		draw_line(Vector2(rect.position.x + rect.size.x, center_y - rail_y), Vector2(rect.position.x + rect.size.x, center_y + rail_y), cyan, 1.0)


func _draw_corner(origin: Vector2, horizontal: Vector2, vertical: Vector2, length: float, color: Color, accent: Color) -> void:
	var notch: float = minf(14.0, length * 0.42)
	draw_line(origin, origin + horizontal * length, color, 1.6)
	draw_line(origin, origin + vertical * length, color, 1.6)
	draw_line(origin + horizontal * notch + vertical * notch, origin + horizontal * (notch + length * 0.34) + vertical * notch, accent, 1.2)
	draw_line(origin + horizontal * notch + vertical * notch, origin + horizontal * notch + vertical * (notch + length * 0.34), accent, 1.2)
