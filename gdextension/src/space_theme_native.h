#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/style_box_flat.hpp>
#include <godot_cpp/classes/style_box_texture.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/classes/font.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/scroll_container.hpp>
#include <godot_cpp/classes/slider.hpp>
#include <godot_cpp/classes/rich_text_label.hpp>
#include <godot_cpp/variant/color.hpp>

namespace godot {

class ScrollBar;

class SpaceThemeNative : public RefCounted {
    GDCLASS(SpaceThemeNative, RefCounted)

protected:
    static void _bind_methods();

public:
    String get_font_body_path() const;
    String get_font_display_path() const;
    String get_font_button_path() const;
    String get_icon_back_path() const;
    String get_icon_codex_path() const;
    String get_icon_play_path() const;
    String get_icon_settings_path() const;
    Color get_color_panel() const;
    Color get_color_panel_deep() const;
    Color get_color_cyan() const;
    Color get_color_gold() const;
    Color get_color_text() const;
    Color get_color_muted() const;
    Color get_color_button_bg() const;
    Color get_color_button_hover() const;
    Color get_color_button_pressed() const;
    Color get_color_button_disabled() const;
    Color get_color_button_text() const;
    Color get_color_button_text_disabled() const;

    void apply_cursor();
    void apply_fonts(Node* root);
    void apply_panel(PanelContainer* panel, const Color& accent = Color(0.22, 0.84, 0.94, 0.82));
    void apply_deep_panel(PanelContainer* panel, const Color& accent = Color(0.22, 0.84, 0.94, 0.82));
    void apply_primary_button(Button* button, const String& icon_path = "");
    void apply_secondary_button(Button* button, const String& icon_path = "");
    void apply_danger_button(Button* button, const String& icon_path = "");
    void apply_compact_button(Button* button);
    void apply_scroll_container(ScrollContainer* scroll);
    void apply_slider(Slider* slider);
    void apply_rich_text_body(RichTextLabel* rich_text, int font_size = 16);
    String format_readout_text(const String& raw_text) const;
    Ref<StyleBoxFlat> panel_style(const Color& bg_color, const Color& border_color, double radius, double horizontal_margin, double vertical_margin) const;
    Ref<StyleBoxFlat> bar_style(const Color& bg_color, double radius) const;
    Ref<StyleBoxTexture> progress_background_style() const;
    Ref<StyleBoxTexture> progress_fill_style() const;

private:
    Ref<Font> body_font_resource() const;
    Ref<Font> display_font_resource() const;
    Ref<Font> button_font_resource() const;
    void apply_fonts_to_node(Node* node);
    void apply_button(Button* button, const String& icon_path, const Color& accent);
    Ref<StyleBoxFlat> button_style(const Color& bg_color, const Color& border_color, int border_width) const;
    void apply_scroll_bar(ScrollBar* scroll_bar, bool vertical);
    Ref<StyleBoxFlat> scrollbar_track_style() const;
    Ref<StyleBoxFlat> scrollbar_grabber_style(const Color& accent, double alpha) const;
    Ref<StyleBoxFlat> slider_track_style() const;
    Ref<StyleBoxFlat> slider_fill_style(const Color& accent, double alpha) const;
    Ref<Texture2D> slider_grabber_texture(bool highlight);
    bool is_readout_heading(const String& line, bool previous_blank) const;
    String numbered_prefix(const String& line) const;
    String escape_bbcode(const String& value) const;
    Ref<StyleBoxTexture> bar_texture_style(const String& path) const;

    mutable Ref<Font> body_font;
    mutable Ref<Font> display_font;
    mutable Ref<Font> button_font;
    Ref<Texture2D> slider_grabber;
    Ref<Texture2D> slider_grabber_highlight;
};

}
