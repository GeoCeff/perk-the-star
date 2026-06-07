#pragma once

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/input_event.hpp>

namespace godot {

class Button;
class Label;
class PanelContainer;

class MainMenuNative : public Control {
    GDCLASS(MainMenuNative, Control)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void _input(const Ref<InputEvent>& event) override;

private:
    Button* btn_play = nullptr;
    Button* btn_codex = nullptr;
    Button* btn_settings = nullptr;
    Button* btn_credits = nullptr;
    Button* btn_exit = nullptr;
    PanelContainer* menu_frame = nullptr;
    Label* title_label = nullptr;
    Label* sub_label = nullptr;
    Label* tagline_label = nullptr;
    Label* description_label = nullptr;
    Label* version_label = nullptr;
    Label* author_label = nullptr;

    void apply_menu_style();
    Object* space_theme() const;
};

}
