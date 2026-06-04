#include "space_theme_native.h"

#include <godot_cpp/classes/check_button.hpp>
#include <godot_cpp/classes/h_scroll_bar.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/scroll_bar.hpp>
#include <godot_cpp/classes/v_scroll_bar.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

namespace {

constexpr const char* FONT_BODY_PATH = "res://assets/fonts/Electrolize-Regular.ttf";
constexpr const char* FONT_DISPLAY_PATH = "res://assets/fonts/Kenney Future.ttf";
constexpr const char* FONT_BUTTON_PATH = "res://assets/fonts/Kenney Future Narrow.ttf";
constexpr const char* BAR_BLUE_PATH = "res://assets/ui/kenney/bar_blue_gloss_large.png";
constexpr const char* BAR_YELLOW_PATH = "res://assets/ui/kenney/bar_yellow_gloss_large.png";
constexpr const char* CURSOR_PATH = "res://assets/ui/kenney/crosshair_blue_a.png";
constexpr const char* ICON_BACK_PATH = "res://assets/ui/icons/icon_back.png";
constexpr const char* ICON_CODEX_PATH = "res://assets/ui/icons/icon_codex.png";
constexpr const char* ICON_PLAY_PATH = "res://assets/ui/icons/icon_play.png";
constexpr const char* ICON_SETTINGS_PATH = "res://assets/ui/icons/icon_settings.png";

Color panel_color() { return Color(0.016, 0.024, 0.038, 0.92); }
Color deep_panel_color() { return Color(0.006, 0.012, 0.024, 0.94); }
Color cyan() { return Color(0.22, 0.84, 0.94, 0.82); }
Color gold() { return Color(1.0, 0.78, 0.26, 0.88); }
Color text_color() { return Color(0.90, 0.96, 1.0, 1.0); }
Color button_bg() { return Color(0.020, 0.052, 0.078, 0.96); }
Color button_hover() { return Color(0.035, 0.085, 0.120, 1.0); }
Color button_pressed() { return Color(0.052, 0.112, 0.138, 1.0); }
Color button_disabled() { return Color(0.018, 0.026, 0.038, 0.78); }
Color button_text() { return Color(0.96, 0.99, 1.0, 1.0); }
Color button_text_disabled() { return Color(0.44, 0.52, 0.60, 1.0); }

} // namespace

void SpaceThemeNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_FONT_BODY_PATH"), &SpaceThemeNative::get_font_body_path);
    ClassDB::bind_method(D_METHOD("get_FONT_DISPLAY_PATH"), &SpaceThemeNative::get_font_display_path);
    ClassDB::bind_method(D_METHOD("get_FONT_BUTTON_PATH"), &SpaceThemeNative::get_font_button_path);
    ClassDB::bind_method(D_METHOD("get_ICON_BACK_PATH"), &SpaceThemeNative::get_icon_back_path);
    ClassDB::bind_method(D_METHOD("get_ICON_CODEX_PATH"), &SpaceThemeNative::get_icon_codex_path);
    ClassDB::bind_method(D_METHOD("get_ICON_PLAY_PATH"), &SpaceThemeNative::get_icon_play_path);
    ClassDB::bind_method(D_METHOD("get_ICON_SETTINGS_PATH"), &SpaceThemeNative::get_icon_settings_path);
    ClassDB::bind_method(D_METHOD("get_COLOR_PANEL"), &SpaceThemeNative::get_color_panel);
    ClassDB::bind_method(D_METHOD("get_COLOR_PANEL_DEEP"), &SpaceThemeNative::get_color_panel_deep);
    ClassDB::bind_method(D_METHOD("get_COLOR_CYAN"), &SpaceThemeNative::get_color_cyan);
    ClassDB::bind_method(D_METHOD("get_COLOR_GOLD"), &SpaceThemeNative::get_color_gold);
    ClassDB::bind_method(D_METHOD("get_COLOR_TEXT"), &SpaceThemeNative::get_color_text);
    ClassDB::bind_method(D_METHOD("get_COLOR_MUTED"), &SpaceThemeNative::get_color_muted);
    ClassDB::bind_method(D_METHOD("get_COLOR_BUTTON_BG"), &SpaceThemeNative::get_color_button_bg);
    ClassDB::bind_method(D_METHOD("get_COLOR_BUTTON_HOVER"), &SpaceThemeNative::get_color_button_hover);
    ClassDB::bind_method(D_METHOD("get_COLOR_BUTTON_PRESSED"), &SpaceThemeNative::get_color_button_pressed);
    ClassDB::bind_method(D_METHOD("get_COLOR_BUTTON_DISABLED"), &SpaceThemeNative::get_color_button_disabled);
    ClassDB::bind_method(D_METHOD("get_COLOR_BUTTON_TEXT"), &SpaceThemeNative::get_color_button_text);
    ClassDB::bind_method(D_METHOD("get_COLOR_BUTTON_TEXT_DISABLED"), &SpaceThemeNative::get_color_button_text_disabled);
    ClassDB::bind_method(D_METHOD("apply_cursor"), &SpaceThemeNative::apply_cursor);
    ClassDB::bind_method(D_METHOD("apply_fonts", "root"), &SpaceThemeNative::apply_fonts);
    ClassDB::bind_method(D_METHOD("apply_panel", "panel", "accent"), &SpaceThemeNative::apply_panel, DEFVAL(cyan()));
    ClassDB::bind_method(D_METHOD("apply_deep_panel", "panel", "accent"), &SpaceThemeNative::apply_deep_panel, DEFVAL(cyan()));
    ClassDB::bind_method(D_METHOD("apply_primary_button", "button", "icon_path"), &SpaceThemeNative::apply_primary_button, DEFVAL(""));
    ClassDB::bind_method(D_METHOD("apply_secondary_button", "button", "icon_path"), &SpaceThemeNative::apply_secondary_button, DEFVAL(""));
    ClassDB::bind_method(D_METHOD("apply_danger_button", "button", "icon_path"), &SpaceThemeNative::apply_danger_button, DEFVAL(""));
    ClassDB::bind_method(D_METHOD("apply_compact_button", "button"), &SpaceThemeNative::apply_compact_button);
    ClassDB::bind_method(D_METHOD("apply_scroll_container", "scroll"), &SpaceThemeNative::apply_scroll_container);
    ClassDB::bind_method(D_METHOD("apply_slider", "slider"), &SpaceThemeNative::apply_slider);
    ClassDB::bind_method(D_METHOD("apply_rich_text_body", "rich_text", "font_size"), &SpaceThemeNative::apply_rich_text_body, DEFVAL(16));
    ClassDB::bind_method(D_METHOD("format_readout_text", "raw_text"), &SpaceThemeNative::format_readout_text);
    ClassDB::bind_method(D_METHOD("panel_style", "bg_color", "border_color", "radius", "horizontal_margin", "vertical_margin"), &SpaceThemeNative::panel_style);
    ClassDB::bind_method(D_METHOD("bar_style", "bg_color", "radius"), &SpaceThemeNative::bar_style);
    ClassDB::bind_method(D_METHOD("progress_background_style"), &SpaceThemeNative::progress_background_style);
    ClassDB::bind_method(D_METHOD("progress_fill_style"), &SpaceThemeNative::progress_fill_style);

    ADD_PROPERTY(PropertyInfo(Variant::STRING, "FONT_BODY_PATH"), "", "get_FONT_BODY_PATH");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "FONT_DISPLAY_PATH"), "", "get_FONT_DISPLAY_PATH");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "FONT_BUTTON_PATH"), "", "get_FONT_BUTTON_PATH");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "ICON_BACK_PATH"), "", "get_ICON_BACK_PATH");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "ICON_CODEX_PATH"), "", "get_ICON_CODEX_PATH");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "ICON_PLAY_PATH"), "", "get_ICON_PLAY_PATH");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "ICON_SETTINGS_PATH"), "", "get_ICON_SETTINGS_PATH");
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "COLOR_PANEL"), "", "get_COLOR_PANEL");
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "COLOR_PANEL_DEEP"), "", "get_COLOR_PANEL_DEEP");
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "COLOR_CYAN"), "", "get_COLOR_CYAN");
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "COLOR_GOLD"), "", "get_COLOR_GOLD");
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "COLOR_TEXT"), "", "get_COLOR_TEXT");
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "COLOR_MUTED"), "", "get_COLOR_MUTED");
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "COLOR_BUTTON_BG"), "", "get_COLOR_BUTTON_BG");
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "COLOR_BUTTON_HOVER"), "", "get_COLOR_BUTTON_HOVER");
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "COLOR_BUTTON_PRESSED"), "", "get_COLOR_BUTTON_PRESSED");
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "COLOR_BUTTON_DISABLED"), "", "get_COLOR_BUTTON_DISABLED");
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "COLOR_BUTTON_TEXT"), "", "get_COLOR_BUTTON_TEXT");
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "COLOR_BUTTON_TEXT_DISABLED"), "", "get_COLOR_BUTTON_TEXT_DISABLED");
}

String SpaceThemeNative::get_font_body_path() const { return FONT_BODY_PATH; }
String SpaceThemeNative::get_font_display_path() const { return FONT_DISPLAY_PATH; }
String SpaceThemeNative::get_font_button_path() const { return FONT_BUTTON_PATH; }
String SpaceThemeNative::get_icon_back_path() const { return ICON_BACK_PATH; }
String SpaceThemeNative::get_icon_codex_path() const { return ICON_CODEX_PATH; }
String SpaceThemeNative::get_icon_play_path() const { return ICON_PLAY_PATH; }
String SpaceThemeNative::get_icon_settings_path() const { return ICON_SETTINGS_PATH; }
Color SpaceThemeNative::get_color_panel() const { return panel_color(); }
Color SpaceThemeNative::get_color_panel_deep() const { return deep_panel_color(); }
Color SpaceThemeNative::get_color_cyan() const { return cyan(); }
Color SpaceThemeNative::get_color_gold() const { return gold(); }
Color SpaceThemeNative::get_color_text() const { return text_color(); }
Color SpaceThemeNative::get_color_muted() const { return Color(0.62, 0.74, 0.86, 0.92); }
Color SpaceThemeNative::get_color_button_bg() const { return button_bg(); }
Color SpaceThemeNative::get_color_button_hover() const { return button_hover(); }
Color SpaceThemeNative::get_color_button_pressed() const { return button_pressed(); }
Color SpaceThemeNative::get_color_button_disabled() const { return button_disabled(); }
Color SpaceThemeNative::get_color_button_text() const { return button_text(); }
Color SpaceThemeNative::get_color_button_text_disabled() const { return button_text_disabled(); }

void SpaceThemeNative::apply_cursor() {
    Ref<Texture2D> cursor = ResourceLoader::get_singleton()->load(CURSOR_PATH);
    if (cursor.is_valid()) {
        Input::get_singleton()->set_custom_mouse_cursor(cursor, Input::CURSOR_ARROW, Vector2(15.0, 15.0));
    }
}

void SpaceThemeNative::apply_fonts(Node* root) {
    if (root == nullptr) {
        return;
    }
    apply_fonts_to_node(root);
    Array children = root->get_children();
    for (int i = 0; i < children.size(); ++i) {
        if (Node* child = Object::cast_to<Node>(children[i])) {
            apply_fonts(child);
        }
    }
}

void SpaceThemeNative::apply_panel(PanelContainer* panel, const Color& accent) {
    if (panel != nullptr) {
        panel->add_theme_stylebox_override("panel", panel_style(panel_color(), accent, 8.0, 18.0, 14.0));
    }
}

void SpaceThemeNative::apply_deep_panel(PanelContainer* panel, const Color& accent) {
    if (panel != nullptr) {
        panel->add_theme_stylebox_override("panel", panel_style(deep_panel_color(), accent, 8.0, 22.0, 18.0));
    }
}

void SpaceThemeNative::apply_primary_button(Button* button, const String& icon_path) { apply_button(button, icon_path, gold()); }
void SpaceThemeNative::apply_secondary_button(Button* button, const String& icon_path) { apply_button(button, icon_path, cyan()); }
void SpaceThemeNative::apply_danger_button(Button* button, const String& icon_path) { apply_button(button, icon_path, cyan()); }

void SpaceThemeNative::apply_compact_button(Button* button) {
    apply_button(button, "", cyan());
    if (button != nullptr) {
        button->add_theme_font_size_override("font_size", 13);
    }
}

void SpaceThemeNative::apply_scroll_container(ScrollContainer* scroll) {
    if (scroll == nullptr) {
        return;
    }
    scroll->add_theme_constant_override("scrollbar_margin_left", 14);
    scroll->add_theme_constant_override("scrollbar_margin_right", 4);
    scroll->add_theme_constant_override("scrollbar_margin_top", 2);
    scroll->add_theme_constant_override("scrollbar_margin_bottom", 2);
    apply_scroll_bar(scroll->get_v_scroll_bar(), true);
    apply_scroll_bar(scroll->get_h_scroll_bar(), false);
}

void SpaceThemeNative::apply_slider(Slider* slider) {
    if (slider == nullptr) {
        return;
    }
    Vector2 minimum_size = slider->get_custom_minimum_size();
    minimum_size.y = MAX(minimum_size.y, 26.0);
    slider->set_custom_minimum_size(minimum_size);
    slider->add_theme_stylebox_override("slider", slider_track_style());
    slider->add_theme_stylebox_override("grabber_area", slider_fill_style(cyan(), 0.70));
    slider->add_theme_stylebox_override("grabber_area_highlight", slider_fill_style(gold(), 0.92));
    slider->add_theme_icon_override("grabber", slider_grabber_texture(false));
    slider->add_theme_icon_override("grabber_highlight", slider_grabber_texture(true));
    slider->add_theme_icon_override("grabber_disabled", slider_grabber_texture(false));
}

void SpaceThemeNative::apply_rich_text_body(RichTextLabel* rich_text, int font_size) {
    if (rich_text == nullptr) {
        return;
    }
    rich_text->set_use_bbcode(true);
    rich_text->set_fit_content(true);
    rich_text->set_scroll_active(false);
    rich_text->add_theme_font_override("normal_font", body_font_resource());
    rich_text->add_theme_font_override("bold_font", display_font_resource());
    rich_text->add_theme_font_override("italics_font", body_font_resource());
    rich_text->add_theme_font_size_override("normal_font_size", font_size);
    rich_text->add_theme_font_size_override("bold_font_size", font_size + 1);
    rich_text->add_theme_color_override("default_color", text_color());
    rich_text->add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.80));
    rich_text->add_theme_constant_override("shadow_offset_x", 0);
    rich_text->add_theme_constant_override("shadow_offset_y", 1);
}

String SpaceThemeNative::format_readout_text(const String& raw_text) const {
    PackedStringArray result;
    bool previous_blank = true;
    PackedStringArray lines = raw_text.split("\n");
    for (int i = 0; i < lines.size(); ++i) {
        const String line = String(lines[i]).strip_edges();
        if (line.is_empty()) {
            result.append("");
            previous_blank = true;
            continue;
        }
        const String escaped = escape_bbcode(line);
        if (line.begins_with("- ")) {
            result.append(String("[color=#25dfff]>[/color] [color=#eaf6ff]") + escape_bbcode(line.substr(2)) + "[/color]");
        } else if (!numbered_prefix(line).is_empty()) {
            const String prefix = numbered_prefix(line);
            result.append(String("[color=#ffdc4a]") + prefix + "[/color] [color=#eaf6ff]" + escape_bbcode(line.substr(prefix.length()).strip_edges()) + "[/color]");
        } else if (is_readout_heading(line, previous_blank)) {
            result.append(String("[font_size=18][color=#ffdc4a][b]") + escaped.to_upper() + "[/b][/color][/font_size]");
        } else {
            result.append(String("[color=#dce9f7]") + escaped + "[/color]");
        }
        previous_blank = false;
    }
    return String("\n").join(result);
}

Ref<StyleBoxFlat> SpaceThemeNative::panel_style(const Color& bg_color, const Color& border_color, double radius, double horizontal_margin, double vertical_margin) const {
    Ref<StyleBoxFlat> style;
    style.instantiate();
    style->set_bg_color(bg_color);
    style->set_border_color(border_color);
    style->set_border_width_all(1);
    style->set_corner_radius_all(int(radius));
    style->set_content_margin(SIDE_LEFT, horizontal_margin);
    style->set_content_margin(SIDE_RIGHT, horizontal_margin);
    style->set_content_margin(SIDE_TOP, vertical_margin);
    style->set_content_margin(SIDE_BOTTOM, vertical_margin);
    return style;
}

Ref<StyleBoxFlat> SpaceThemeNative::bar_style(const Color& bg_color, double radius) const {
    Ref<StyleBoxFlat> style;
    style.instantiate();
    style->set_bg_color(bg_color);
    style->set_corner_radius_all(int(radius));
    return style;
}

Ref<StyleBoxTexture> SpaceThemeNative::progress_background_style() const { return bar_texture_style(BAR_BLUE_PATH); }
Ref<StyleBoxTexture> SpaceThemeNative::progress_fill_style() const { return bar_texture_style(BAR_YELLOW_PATH); }

Ref<Font> SpaceThemeNative::body_font_resource() const {
    if (body_font.is_null()) body_font = ResourceLoader::get_singleton()->load(FONT_BODY_PATH);
    return body_font;
}

Ref<Font> SpaceThemeNative::display_font_resource() const {
    if (display_font.is_null()) display_font = ResourceLoader::get_singleton()->load(FONT_DISPLAY_PATH);
    return display_font;
}

Ref<Font> SpaceThemeNative::button_font_resource() const {
    if (button_font.is_null()) button_font = ResourceLoader::get_singleton()->load(FONT_BUTTON_PATH);
    return button_font;
}

void SpaceThemeNative::apply_fonts_to_node(Node* node) {
    if (Label* label = Object::cast_to<Label>(node)) {
        const String node_name = String(label->get_name()).to_lower();
        const bool use_display = node_name.contains("title") || node_name.contains("wave") || label->get_theme_font_size("font_size") >= 24;
        label->add_theme_font_override("font", use_display ? display_font_resource() : body_font_resource());
        if (!label->has_theme_color_override("font_color")) {
            label->add_theme_color_override("font_color", text_color());
        }
    } else if (Button* button = Object::cast_to<Button>(node)) {
        button->add_theme_font_override("font", button_font_resource());
    } else if (CheckButton* check_button = Object::cast_to<CheckButton>(node)) {
        check_button->add_theme_font_override("font", body_font_resource());
    } else if (RichTextLabel* rich_text = Object::cast_to<RichTextLabel>(node)) {
        apply_rich_text_body(rich_text);
    }
}

void SpaceThemeNative::apply_button(Button* button, const String& icon_path, const Color& accent) {
    if (button == nullptr) {
        return;
    }
    button->add_theme_font_override("font", button_font_resource());
    button->add_theme_stylebox_override("normal", button_style(button_bg(), accent, 1));
    button->add_theme_stylebox_override("hover", button_style(button_hover(), Color(accent.r, accent.g, accent.b, 1.0), 2));
    button->add_theme_stylebox_override("pressed", button_style(button_pressed(), Color(accent.r, accent.g, accent.b, 1.0), 2));
    button->add_theme_stylebox_override("focus", button_style(Color(0.015, 0.072, 0.092, 1.0), gold(), 2));
    button->add_theme_stylebox_override("disabled", button_style(button_disabled(), Color(0.20, 0.28, 0.34, 0.70), 1));
    button->add_theme_color_override("font_color", button_text());
    button->add_theme_color_override("font_hover_color", button_text());
    button->add_theme_color_override("font_pressed_color", button_text());
    button->add_theme_color_override("font_focus_color", button_text());
    button->add_theme_color_override("font_disabled_color", button_text_disabled());
    button->add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.82));
    button->add_theme_constant_override("h_separation", 10);
    button->add_theme_constant_override("shadow_offset_x", 0);
    button->add_theme_constant_override("shadow_offset_y", 1);
    button->add_theme_constant_override("outline_size", 1);
    if (!icon_path.is_empty()) {
        Ref<Texture2D> icon = ResourceLoader::get_singleton()->load(icon_path);
        if (icon.is_valid()) {
            button->set_button_icon(icon);
            button->set_expand_icon(true);
        }
    }
}

Ref<StyleBoxFlat> SpaceThemeNative::button_style(const Color& bg_color, const Color& border_color, int border_width) const {
    Ref<StyleBoxFlat> style = panel_style(bg_color, border_color, 8.0, 16.0, 9.0);
    style->set_border_width_all(border_width);
    style->set_shadow_color(Color(0.0, 0.0, 0.0, 0.38));
    style->set_shadow_size(6);
    style->set_shadow_offset(Vector2(0.0, 2.0));
    return style;
}

void SpaceThemeNative::apply_scroll_bar(ScrollBar* scroll_bar, bool vertical) {
    if (scroll_bar == nullptr) {
        return;
    }
    scroll_bar->set_custom_minimum_size(vertical ? Vector2(22.0, 0.0) : Vector2(0.0, 22.0));
    scroll_bar->add_theme_stylebox_override("scroll", scrollbar_track_style());
    scroll_bar->add_theme_stylebox_override("scroll_focus", scrollbar_track_style());
    scroll_bar->add_theme_stylebox_override("grabber", scrollbar_grabber_style(cyan(), 0.78));
    scroll_bar->add_theme_stylebox_override("grabber_highlight", scrollbar_grabber_style(gold(), 0.94));
    scroll_bar->add_theme_stylebox_override("grabber_pressed", scrollbar_grabber_style(gold(), 1.0));
}

Ref<StyleBoxFlat> SpaceThemeNative::scrollbar_track_style() const {
    Ref<StyleBoxFlat> style = panel_style(Color(0.006, 0.018, 0.030, 0.92), Color(0.18, 0.82, 0.96, 0.52), 9.0, 5.0, 5.0);
    style->set_shadow_color(Color(0.0, 0.0, 0.0, 0.48));
    style->set_shadow_size(4);
    return style;
}

Ref<StyleBoxFlat> SpaceThemeNative::scrollbar_grabber_style(const Color& accent, double alpha) const {
    Ref<StyleBoxFlat> style = panel_style(Color(accent.r * 0.78, accent.g * 0.90, accent.b, alpha), Color(0.98, 1.0, 1.0, MIN(alpha + 0.08, 1.0)), 8.0, 7.0, 12.0);
    style->set_shadow_color(Color(0.0, 0.0, 0.0, 0.45));
    style->set_shadow_size(7);
    style->set_shadow_offset(Vector2(0.0, 1.0));
    return style;
}

Ref<StyleBoxFlat> SpaceThemeNative::slider_track_style() const {
    Ref<StyleBoxFlat> style = panel_style(Color(0.010, 0.026, 0.040, 0.96), Color(0.18, 0.82, 0.96, 0.48), 8.0, 10.0, 5.0);
    style->set_shadow_color(Color(0.0, 0.0, 0.0, 0.45));
    style->set_shadow_size(4);
    return style;
}

Ref<StyleBoxFlat> SpaceThemeNative::slider_fill_style(const Color& accent, double alpha) const {
    return panel_style(Color(accent.r, accent.g, accent.b, alpha), Color(1.0, 0.96, 0.70, MIN(alpha + 0.05, 1.0)), 8.0, 10.0, 5.0);
}

Ref<Texture2D> SpaceThemeNative::slider_grabber_texture(bool highlight) {
    if (highlight && slider_grabber_highlight.is_valid()) return slider_grabber_highlight;
    if (!highlight && slider_grabber.is_valid()) return slider_grabber;
    Ref<Image> image = Image::create(26, 26, false, Image::FORMAT_RGBA8);
    const Vector2 center(12.5, 12.5);
    const Color fill = highlight ? gold() : cyan();
    for (int y = 0; y < 26; ++y) {
        for (int x = 0; x < 26; ++x) {
            const double d = Math::abs(double(x) - center.x) + Math::abs(double(y) - center.y);
            if (d <= 11.0) {
                const bool border = d > 8.2;
                image->set_pixel(x, y, border ? Color(0.98, 1.0, 1.0, 0.98) : Color(fill.r, fill.g, fill.b, 0.95));
            } else if (d <= 12.4) {
                image->set_pixel(x, y, Color(fill.r, fill.g, fill.b, 0.30));
            }
        }
    }
    Ref<ImageTexture> texture = ImageTexture::create_from_image(image);
    if (highlight) slider_grabber_highlight = texture;
    else slider_grabber = texture;
    return texture;
}

bool SpaceThemeNative::is_readout_heading(const String& line, bool previous_blank) const {
    return previous_blank && !line.begins_with("- ") && numbered_prefix(line).is_empty() && line.length() <= 42 && line.find(".") < 0;
}

String SpaceThemeNative::numbered_prefix(const String& line) const {
    for (int i = 1; i < 10; ++i) {
        const String prefix = vformat("%d.", i);
        if (line.begins_with(prefix)) {
            return prefix;
        }
    }
    return "";
}

String SpaceThemeNative::escape_bbcode(const String& value) const {
    return value.replace("[", "[lb]").replace("]", "[rb]");
}

Ref<StyleBoxTexture> SpaceThemeNative::bar_texture_style(const String& path) const {
    Ref<StyleBoxTexture> style;
    style.instantiate();
    style->set_texture(ResourceLoader::get_singleton()->load(path));
    style->set_texture_margin(SIDE_LEFT, 16.0);
    style->set_texture_margin(SIDE_RIGHT, 16.0);
    style->set_texture_margin(SIDE_TOP, 8.0);
    style->set_texture_margin(SIDE_BOTTOM, 8.0);
    style->set_content_margin(SIDE_LEFT, 2.0);
    style->set_content_margin(SIDE_RIGHT, 2.0);
    style->set_content_margin(SIDE_TOP, 2.0);
    style->set_content_margin(SIDE_BOTTOM, 2.0);
    return style;
}
