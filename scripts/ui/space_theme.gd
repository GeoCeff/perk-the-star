extends RefCounted

const FONT_BODY_PATH: String = "res://assets/fonts/Electrolize-Regular.ttf"
const FONT_DISPLAY_PATH: String = "res://assets/fonts/Kenney Future.ttf"
const FONT_BUTTON_PATH: String = "res://assets/fonts/Kenney Future Narrow.ttf"

const BAR_BLUE_PATH: String = "res://assets/ui/kenney/bar_blue_gloss_large.png"
const BAR_YELLOW_PATH: String = "res://assets/ui/kenney/bar_yellow_gloss_large.png"
const CURSOR_PATH: String = "res://assets/ui/kenney/crosshair_blue_a.png"

const ICON_BACK_PATH: String = "res://assets/ui/icons/icon_back.png"
const ICON_CODEX_PATH: String = "res://assets/ui/icons/icon_codex.png"
const ICON_PLAY_PATH: String = "res://assets/ui/icons/icon_play.png"
const ICON_SETTINGS_PATH: String = "res://assets/ui/icons/icon_settings.png"

const COLOR_PANEL: Color = Color(0.016, 0.024, 0.038, 0.92)
const COLOR_PANEL_DEEP: Color = Color(0.006, 0.012, 0.024, 0.94)
const COLOR_CYAN: Color = Color(0.22, 0.84, 0.94, 0.82)
const COLOR_GOLD: Color = Color(1.0, 0.78, 0.26, 0.88)
const COLOR_TEXT: Color = Color(0.90, 0.96, 1.0, 1.0)
const COLOR_MUTED: Color = Color(0.62, 0.74, 0.86, 0.92)
const COLOR_BUTTON_BG: Color = Color(0.020, 0.052, 0.078, 0.96)
const COLOR_BUTTON_HOVER: Color = Color(0.035, 0.085, 0.120, 1.0)
const COLOR_BUTTON_PRESSED: Color = Color(0.052, 0.112, 0.138, 1.0)
const COLOR_BUTTON_DISABLED: Color = Color(0.018, 0.026, 0.038, 0.78)
const COLOR_BUTTON_TEXT: Color = Color(0.96, 0.99, 1.0, 1.0)
const COLOR_BUTTON_TEXT_DISABLED: Color = Color(0.44, 0.52, 0.60, 1.0)

static var _body_font: Font
static var _display_font: Font
static var _button_font: Font
static var _slider_grabber: Texture2D
static var _slider_grabber_highlight: Texture2D


static func apply_cursor() -> void:
	var cursor: Texture2D = load(CURSOR_PATH) as Texture2D
	if cursor != null:
		Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(15.0, 15.0))


static func apply_fonts(root: Node) -> void:
	_apply_fonts_to_node(root)
	for child in root.get_children():
		apply_fonts(child)


static func apply_panel(panel: PanelContainer, accent: Color = COLOR_CYAN) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", panel_style(COLOR_PANEL, accent, 8.0, 18.0, 14.0))


static func apply_deep_panel(panel: PanelContainer, accent: Color = COLOR_CYAN) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", panel_style(COLOR_PANEL_DEEP, accent, 8.0, 22.0, 18.0))


static func apply_primary_button(button: Button, icon_path: String = "") -> void:
	_apply_button(button, icon_path, COLOR_GOLD)


static func apply_secondary_button(button: Button, icon_path: String = "") -> void:
	_apply_button(button, icon_path, COLOR_CYAN)


static func apply_danger_button(button: Button, icon_path: String = "") -> void:
	_apply_button(button, icon_path, COLOR_CYAN)


static func apply_compact_button(button: Button) -> void:
	_apply_button(button, "", COLOR_CYAN)
	button.add_theme_font_size_override("font_size", 13)


static func apply_scroll_container(scroll: ScrollContainer) -> void:
	if scroll == null:
		return

	scroll.add_theme_constant_override("scrollbar_margin_left", 14)
	scroll.add_theme_constant_override("scrollbar_margin_right", 4)
	scroll.add_theme_constant_override("scrollbar_margin_top", 2)
	scroll.add_theme_constant_override("scrollbar_margin_bottom", 2)
	_apply_scroll_bar(scroll.get_v_scroll_bar(), true)
	_apply_scroll_bar(scroll.get_h_scroll_bar(), false)


static func apply_slider(slider: Slider) -> void:
	if slider == null:
		return

	var minimum_size: Vector2 = slider.custom_minimum_size
	minimum_size.y = maxf(minimum_size.y, 26.0)
	slider.custom_minimum_size = minimum_size
	slider.add_theme_stylebox_override("slider", _slider_track_style())
	slider.add_theme_stylebox_override("grabber_area", _slider_fill_style(COLOR_CYAN, 0.70))
	slider.add_theme_stylebox_override("grabber_area_highlight", _slider_fill_style(COLOR_GOLD, 0.92))
	slider.add_theme_icon_override("grabber", _slider_grabber_texture(false))
	slider.add_theme_icon_override("grabber_highlight", _slider_grabber_texture(true))
	slider.add_theme_icon_override("grabber_disabled", _slider_grabber_texture(false))


static func apply_rich_text_body(rich_text: RichTextLabel, font_size: int = 16) -> void:
	if rich_text == null:
		return

	rich_text.bbcode_enabled = true
	rich_text.fit_content = true
	rich_text.scroll_active = false
	rich_text.add_theme_font_override("normal_font", _body_font_resource())
	rich_text.add_theme_font_override("bold_font", _display_font_resource())
	rich_text.add_theme_font_override("italics_font", _body_font_resource())
	rich_text.add_theme_font_size_override("normal_font_size", font_size)
	rich_text.add_theme_font_size_override("bold_font_size", font_size + 1)
	rich_text.add_theme_color_override("default_color", COLOR_TEXT)
	rich_text.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.80))
	rich_text.add_theme_constant_override("shadow_offset_x", 0)
	rich_text.add_theme_constant_override("shadow_offset_y", 1)


static func format_readout_text(raw_text: String) -> String:
	var result: Array[String] = []
	var previous_blank: bool = true
	for raw_line in raw_text.split("\n"):
		var line: String = str(raw_line).strip_edges()
		if line == "":
			result.append("")
			previous_blank = true
			continue

		var escaped: String = _escape_bbcode(line)
		if line.begins_with("- "):
			result.append("[color=#25dfff]>[/color] [color=#eaf6ff]%s[/color]" % _escape_bbcode(line.substr(2)))
		elif _numbered_prefix(line) != "":
			var prefix: String = _numbered_prefix(line)
			result.append("[color=#ffdc4a]%s[/color] [color=#eaf6ff]%s[/color]" % [prefix, _escape_bbcode(line.substr(prefix.length()).strip_edges())])
		elif _is_readout_heading(line, previous_blank):
			result.append("[font_size=18][color=#ffdc4a][b]%s[/b][/color][/font_size]" % escaped.to_upper())
		else:
			result.append("[color=#dce9f7]%s[/color]" % escaped)
		previous_blank = false
	return "\n".join(result)


static func panel_style(bg_color: Color, border_color: Color, radius: float, horizontal_margin: float, vertical_margin: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(radius))
	style.content_margin_left = horizontal_margin
	style.content_margin_right = horizontal_margin
	style.content_margin_top = vertical_margin
	style.content_margin_bottom = vertical_margin
	return style


static func bar_style(bg_color: Color, radius: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(int(radius))
	return style


static func progress_background_style() -> StyleBoxTexture:
	return _bar_texture_style(BAR_BLUE_PATH)


static func progress_fill_style() -> StyleBoxTexture:
	return _bar_texture_style(BAR_YELLOW_PATH)


static func _apply_fonts_to_node(node: Node) -> void:
	if node is Label:
		var label: Label = node as Label
		var node_name: String = str(label.name).to_lower()
		var use_display: bool = node_name.contains("title") or node_name.contains("wave") or label.get_theme_font_size("font_size") >= 24
		label.add_theme_font_override("font", _display_font_resource() if use_display else _body_font_resource())
		if not label.has_theme_color_override("font_color"):
			label.add_theme_color_override("font_color", COLOR_TEXT)
	elif node is Button:
		var button: Button = node as Button
		button.add_theme_font_override("font", _button_font_resource())
	elif node is CheckButton:
		var check_button: CheckButton = node as CheckButton
		check_button.add_theme_font_override("font", _body_font_resource())
	elif node is RichTextLabel:
		apply_rich_text_body(node as RichTextLabel)


static func _apply_button(button: Button, icon_path: String, accent: Color) -> void:
	if button == null:
		return

	button.add_theme_font_override("font", _button_font_resource())
	button.add_theme_stylebox_override("normal", _button_style(COLOR_BUTTON_BG, accent, 1))
	button.add_theme_stylebox_override("hover", _button_style(COLOR_BUTTON_HOVER, Color(accent.r, accent.g, accent.b, 1.0), 2))
	button.add_theme_stylebox_override("pressed", _button_style(COLOR_BUTTON_PRESSED, Color(accent.r, accent.g, accent.b, 1.0), 2))
	button.add_theme_stylebox_override("focus", _button_style(Color(0.015, 0.072, 0.092, 1.0), COLOR_GOLD, 2))
	button.add_theme_stylebox_override("disabled", _button_style(COLOR_BUTTON_DISABLED, Color(0.20, 0.28, 0.34, 0.70), 1))
	button.add_theme_color_override("font_color", COLOR_BUTTON_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_BUTTON_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_BUTTON_TEXT)
	button.add_theme_color_override("font_focus_color", COLOR_BUTTON_TEXT)
	button.add_theme_color_override("font_disabled_color", COLOR_BUTTON_TEXT_DISABLED)
	button.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.82))
	button.add_theme_constant_override("h_separation", 10)
	button.add_theme_constant_override("shadow_offset_x", 0)
	button.add_theme_constant_override("shadow_offset_y", 1)
	button.add_theme_constant_override("outline_size", 1)

	if icon_path != "":
		var icon: Texture2D = load(icon_path) as Texture2D
		if icon != null:
			button.icon = icon
			button.expand_icon = true


static func _button_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


static func _apply_scroll_bar(scroll_bar: ScrollBar, vertical: bool) -> void:
	if scroll_bar == null:
		return

	scroll_bar.custom_minimum_size = Vector2(22.0, 0.0) if vertical else Vector2(0.0, 22.0)
	scroll_bar.add_theme_stylebox_override("scroll", _scrollbar_track_style())
	scroll_bar.add_theme_stylebox_override("scroll_focus", _scrollbar_track_style())
	scroll_bar.add_theme_stylebox_override("grabber", _scrollbar_grabber_style(COLOR_CYAN, 0.78))
	scroll_bar.add_theme_stylebox_override("grabber_highlight", _scrollbar_grabber_style(COLOR_GOLD, 0.94))
	scroll_bar.add_theme_stylebox_override("grabber_pressed", _scrollbar_grabber_style(COLOR_GOLD, 1.0))


static func _scrollbar_track_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.006, 0.018, 0.030, 0.92)
	style.border_color = Color(0.18, 0.82, 0.96, 0.52)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 5.0
	style.content_margin_right = 5.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 4
	return style


static func _scrollbar_grabber_style(accent: Color, alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(accent.r * 0.78, accent.g * 0.90, accent.b, alpha)
	style.border_color = Color(0.98, 1.0, 1.0, minf(alpha + 0.08, 1.0))
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 7.0
	style.content_margin_right = 7.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 1.0)
	return style


static func _slider_track_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.010, 0.026, 0.040, 0.96)
	style.border_color = Color(0.18, 0.82, 0.96, 0.48)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 4
	return style


static func _slider_fill_style(accent: Color, alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, alpha)
	style.border_color = Color(1.0, 0.96, 0.70, minf(alpha + 0.05, 1.0))
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style


static func _slider_grabber_texture(highlight: bool) -> Texture2D:
	if highlight and _slider_grabber_highlight != null:
		return _slider_grabber_highlight
	if not highlight and _slider_grabber != null:
		return _slider_grabber

	var image: Image = Image.create(26, 26, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(12.5, 12.5)
	var fill: Color = COLOR_GOLD if highlight else COLOR_CYAN
	for y in range(26):
		for x in range(26):
			var d: float = abs(float(x) - center.x) + abs(float(y) - center.y)
			if d <= 11.0:
				var border: bool = d > 8.2
				var color: Color = Color(0.98, 1.0, 1.0, 0.98) if border else Color(fill.r, fill.g, fill.b, 0.95)
				image.set_pixel(x, y, color)
			elif d <= 12.4:
				image.set_pixel(x, y, Color(fill.r, fill.g, fill.b, 0.30))

	var texture: Texture2D = ImageTexture.create_from_image(image)
	if highlight:
		_slider_grabber_highlight = texture
	else:
		_slider_grabber = texture
	return texture


static func _is_readout_heading(line: String, previous_blank: bool) -> bool:
	if not previous_blank:
		return false
	if line.begins_with("- "):
		return false
	if _numbered_prefix(line) != "":
		return false
	if line.length() > 42:
		return false
	if line.find(".") >= 0:
		return false
	return true


static func _numbered_prefix(line: String) -> String:
	for i in range(1, 10):
		var prefix: String = "%d." % i
		if line.begins_with(prefix):
			return prefix
	return ""


static func _escape_bbcode(value: String) -> String:
	return value.replace("[", "[lb]").replace("]", "[rb]")


static func _bar_texture_style(path: String) -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = load(path) as Texture2D
	style.texture_margin_left = 16.0
	style.texture_margin_right = 16.0
	style.texture_margin_top = 8.0
	style.texture_margin_bottom = 8.0
	style.content_margin_left = 2.0
	style.content_margin_right = 2.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style


static func _body_font_resource() -> Font:
	if _body_font == null:
		_body_font = load(FONT_BODY_PATH) as Font
	return _body_font


static func _display_font_resource() -> Font:
	if _display_font == null:
		_display_font = load(FONT_DISPLAY_PATH) as Font
	return _display_font


static func _button_font_resource() -> Font:
	if _button_font == null:
		_button_font = load(FONT_BUTTON_PATH) as Font
	return _button_font
