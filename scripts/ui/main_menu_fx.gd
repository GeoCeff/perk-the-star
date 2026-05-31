extends Control

@export var draw_drift: bool = true
@export var draw_frame: bool = false
@export var frame_target_path: NodePath

const DRIFT_ASSETS: Array[String] = [
	"res://assets/sprites/enemies/Drifter.png",
	"res://assets/sprites/enemies/Bloom.png",
	"res://assets/sprites/enemies/Photon Mimic.png",
	"res://assets/sprites/enemies/Solar Farmer.png",
	"res://assets/sprites/enemies/Coronal Burrower.png",
]

var drift_textures: Array[Texture2D] = []
var drifters: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_textures()
	_build_drifters()
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if draw_drift:
		_draw_drift()
	if draw_frame:
		_draw_frame()


func _load_textures() -> void:
	drift_textures.clear()
	for path in DRIFT_ASSETS:
		var texture: Texture2D = load(path) as Texture2D
		if texture != null:
			drift_textures.append(texture)


func _build_drifters() -> void:
	drifters = [
		{"uv": Vector2(0.10, 0.18), "speed": Vector2(10.0, 3.0), "scale": 0.044, "alpha": 0.18, "phase": 0.2},
		{"uv": Vector2(0.86, 0.20), "speed": Vector2(-8.0, 4.0), "scale": 0.040, "alpha": 0.16, "phase": 1.4},
		{"uv": Vector2(0.22, 0.76), "speed": Vector2(6.0, -2.0), "scale": 0.036, "alpha": 0.14, "phase": 2.2},
		{"uv": Vector2(0.78, 0.72), "speed": Vector2(-7.0, -2.0), "scale": 0.042, "alpha": 0.16, "phase": 3.1},
		{"uv": Vector2(0.47, 0.14), "speed": Vector2(4.0, 2.0), "scale": 0.032, "alpha": 0.13, "phase": 4.0},
		{"uv": Vector2(0.56, 0.86), "speed": Vector2(-5.0, -3.0), "scale": 0.034, "alpha": 0.14, "phase": 5.2},
		{"uv": Vector2(0.04, 0.54), "speed": Vector2(8.0, 1.0), "scale": 0.032, "alpha": 0.12, "phase": 2.8},
		{"uv": Vector2(0.95, 0.52), "speed": Vector2(-9.0, 1.0), "scale": 0.032, "alpha": 0.12, "phase": 0.9},
	]


func _draw_drift() -> void:
	if drift_textures.is_empty():
		return

	var viewport_size: Vector2 = get_rect().size
	var time_seconds: float = Time.get_ticks_msec() / 1000.0
	_draw_star_motes(viewport_size, time_seconds)

	for i in range(drifters.size()):
		var item: Dictionary = drifters[i]
		var texture: Texture2D = drift_textures[i % drift_textures.size()]
		var uv: Vector2 = item["uv"]
		var speed: Vector2 = item["speed"]
		var phase: float = float(item["phase"])
		var alpha: float = float(item["alpha"]) * (0.72 + sin(time_seconds * 0.9 + phase) * 0.18)
		var pos: Vector2 = Vector2(
			wrapf(viewport_size.x * uv.x + time_seconds * speed.x, -96.0, viewport_size.x + 96.0),
			wrapf(viewport_size.y * uv.y + time_seconds * speed.y + sin(time_seconds * 0.8 + phase) * 18.0, -96.0, viewport_size.y + 96.0)
		)
		var sprite_size: Vector2 = texture.get_size() * float(item["scale"])
		var rotation: float = sin(time_seconds * 0.35 + phase) * 0.22
		draw_set_transform(pos, rotation, Vector2.ONE)
		draw_texture_rect(texture, Rect2(sprite_size * -0.5, sprite_size), false, Color(0.70, 0.92, 1.0, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_star_motes(viewport_size: Vector2, time_seconds: float) -> void:
	for i in range(28):
		var phase: float = float(i) * 1.713
		var drift: float = time_seconds * (7.0 + float(i % 5) * 1.6)
		var x: float = wrapf(sin(phase * 2.11) * viewport_size.x * 0.5 + viewport_size.x * 0.5 + drift, -32.0, viewport_size.x + 32.0)
		var y: float = wrapf(cos(phase * 1.37) * viewport_size.y * 0.5 + viewport_size.y * 0.5 + sin(time_seconds * 0.4 + phase) * 10.0, -32.0, viewport_size.y + 32.0)
		var pulse: float = 0.5 + sin(time_seconds * 1.4 + phase) * 0.5
		var alpha: float = 0.06 + pulse * 0.13
		var point: Vector2 = Vector2(x, y)
		draw_circle(point, 1.0 + float(i % 3) * 0.45, Color(0.50, 0.90, 1.0, alpha))
		if i % 4 == 0:
			draw_line(point - Vector2(10.0, 1.5), point + Vector2(10.0, -1.5), Color(0.50, 0.90, 1.0, alpha * 0.42), 0.8)


func _draw_frame() -> void:
	var target: Control = get_node_or_null(frame_target_path) as Control
	if target == null:
		return

	var rect: Rect2 = target.get_global_rect().grow(10.0)
	var inner_rect: Rect2 = rect.grow(-9.0)
	var cyan: Color = Color(0.18, 0.82, 0.96, 0.82)
	var cyan_soft: Color = Color(0.18, 0.82, 0.96, 0.20)
	var gold: Color = Color(1.0, 0.78, 0.26, 0.86)
	var panel_blue: Color = Color(0.08, 0.36, 0.52, 0.32)
	var corner: float = 72.0
	var notch: float = 18.0

	draw_rect(rect, cyan_soft, false, 1.0)
	draw_rect(inner_rect, panel_blue, false, 1.0)
	_draw_corner(rect.position, Vector2.RIGHT, Vector2.DOWN, corner, cyan, gold)
	_draw_corner(rect.position + Vector2(rect.size.x, 0.0), Vector2.LEFT, Vector2.DOWN, corner, cyan, gold)
	_draw_corner(rect.position + Vector2(0.0, rect.size.y), Vector2.RIGHT, Vector2.UP, corner, cyan, gold)
	_draw_corner(rect.position + rect.size, Vector2.LEFT, Vector2.UP, corner, cyan, gold)

	_draw_panel_rail(rect, Vector2.RIGHT, Vector2.DOWN, cyan, panel_blue)
	_draw_panel_rail(rect, Vector2.LEFT, Vector2.DOWN, cyan, panel_blue)

	draw_line(rect.position + Vector2(rect.size.x * 0.5 - 80.0, 0.0), rect.position + Vector2(rect.size.x * 0.5 + 80.0, 0.0), gold, 1.8)
	draw_line(rect.position + Vector2(rect.size.x * 0.5 - 80.0, rect.size.y), rect.position + Vector2(rect.size.x * 0.5 + 80.0, rect.size.y), gold, 1.8)
	draw_line(rect.position + Vector2(0.0, rect.size.y * 0.5 - 54.0), rect.position + Vector2(0.0, rect.size.y * 0.5 + 54.0), cyan, 1.4)
	draw_line(rect.position + Vector2(rect.size.x, rect.size.y * 0.5 - 54.0), rect.position + Vector2(rect.size.x, rect.size.y * 0.5 + 54.0), cyan, 1.4)

	for point in [
		rect.position + Vector2(rect.size.x * 0.5 - 112.0, 0.0),
		rect.position + Vector2(rect.size.x * 0.5 + 112.0, 0.0),
		rect.position + Vector2(rect.size.x * 0.5 - 112.0, rect.size.y),
		rect.position + Vector2(rect.size.x * 0.5 + 112.0, rect.size.y),
	]:
		draw_circle(point, notch * 0.18, gold)


func _draw_corner(origin: Vector2, horizontal: Vector2, vertical: Vector2, length: float, color: Color, accent: Color) -> void:
	draw_line(origin, origin + horizontal * length, color, 2.0)
	draw_line(origin, origin + vertical * length, color, 2.0)
	draw_line(origin + horizontal * 18.0 + vertical * 18.0, origin + horizontal * 44.0 + vertical * 18.0, accent, 1.8)
	draw_line(origin + horizontal * 18.0 + vertical * 18.0, origin + horizontal * 18.0 + vertical * 44.0, accent, 1.8)


func _draw_panel_rail(rect: Rect2, horizontal: Vector2, vertical: Vector2, color: Color, fill: Color) -> void:
	var x_side: float = rect.position.x
	if horizontal == Vector2.LEFT:
		x_side = rect.position.x + rect.size.x

	var y_top: float = rect.position.y + 96.0
	var y_bottom: float = rect.position.y + rect.size.y - 96.0
	var rail_width: float = 24.0 * horizontal.x
	var bevel: float = 14.0
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(x_side, y_top),
		Vector2(x_side + rail_width, y_top + bevel),
		Vector2(x_side + rail_width, y_bottom - bevel),
		Vector2(x_side, y_bottom),
	])
	draw_colored_polygon(points, fill)
	draw_polyline(points, color, 1.0)
	draw_line(Vector2(x_side, y_top + 70.0), Vector2(x_side + rail_width, y_top + 70.0 + bevel * vertical.y), color, 1.0)
	draw_line(Vector2(x_side, y_bottom - 70.0), Vector2(x_side + rail_width, y_bottom - 70.0 - bevel * vertical.y), color, 1.0)
