#pragma once

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/input_event.hpp>

namespace godot {

class Button;
class Label;
class PanelContainer;
class RichTextLabel;
class ScrollContainer;

class CreditsOverlayNative : public Control {
    GDCLASS(CreditsOverlayNative, Control)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void _unhandled_input(const Ref<InputEvent>& event) override;

    void set_return_scene_path(const String& path);
    String get_return_scene_path() const;
    void close_overlay();

private:
    String return_scene_path = "res://scenes/main_menu.tscn";

    PanelContainer* credits_panel = nullptr;
    Label* credits_title = nullptr;
    Label* credits_subtitle = nullptr;
    ScrollContainer* credits_scroll = nullptr;
    RichTextLabel* credits_body = nullptr;
    Button* close_button = nullptr;

    void apply_style();
    Object* space_theme() const;
};

}
