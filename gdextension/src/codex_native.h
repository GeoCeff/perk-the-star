#pragma once

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

class Button;
class Label;
class PanelContainer;
class RichTextLabel;
class ScrollContainer;

class CodexNative : public Control {
    GDCLASS(CodexNative, Control)

protected:
    static void _bind_methods();

public:
    void _ready() override;

    void set_return_scene_path(const String& path);
    String get_return_scene_path() const;
    void set_close_returns_to_scene(bool value);
    bool get_close_returns_to_scene() const;
    void set_play_menu_music_on_ready(bool value);
    bool get_play_menu_music_on_ready() const;
    void show_standalone_mode();

private:
    String return_scene_path = "res://scenes/main_menu.tscn";
    bool close_returns_to_scene = true;
    bool play_menu_music_on_ready = true;
    String current_section = "briefing";
    Dictionary nav_buttons;
    Dictionary sections;

    Button* close_button = nullptr;
    PanelContainer* panel = nullptr;
    Label* section_title_label = nullptr;
    ScrollContainer* body_scroll = nullptr;
    RichTextLabel* body_label = nullptr;

    void close_pressed();
    void show_section(const String& section_key);
    void update_nav_state();
    void apply_style();
    void build_sections();
    Object* space_theme() const;
};

}
