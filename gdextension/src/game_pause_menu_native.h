#pragma once

#include <godot_cpp/classes/canvas_layer.hpp>
#include <godot_cpp/classes/input_event.hpp>

namespace godot {

class Button;
class Control;
class Label;
class PanelContainer;

class GamePauseMenuNative : public CanvasLayer {
    GDCLASS(GamePauseMenuNative, CanvasLayer)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void _exit_tree() override;
    void _unhandled_input(const Ref<InputEvent>& event) override;

private:
    Control* overlay_root = nullptr;
    PanelContainer* pause_panel = nullptr;
    Label* title_label = nullptr;
    Label* subtitle_label = nullptr;
    Button* codex_button = nullptr;
    Button* settings_button = nullptr;
    Button* controls_button = nullptr;
    Button* retry_button = nullptr;
    Button* main_menu_button = nullptr;
    Button* back_button = nullptr;
    Control* overlay_host = nullptr;

    void bind_buttons();
    void apply_style();
    void open_codex();
    void open_settings();
    void open_controls();
    void open_embedded_overlay(const String& scene_path);
    void return_to_main_menu();
    void retry_run();
    void close_pause_menu();
    Object* space_theme() const;
};

}
