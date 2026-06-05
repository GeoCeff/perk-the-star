#pragma once

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/input_event.hpp>

namespace godot {

class Button;
class CheckButton;
class Label;
class LineEdit;
class PanelContainer;
class RichTextLabel;
class ScrollContainer;
class HSlider;
class SpinBox;
class VBoxContainer;

class SettingsOverlayNative : public Control {
    GDCLASS(SettingsOverlayNative, Control)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void _unhandled_input(const Ref<InputEvent>& event) override;

    void set_return_scene_path(const String& path);
    String get_return_scene_path() const;
    void set_close_returns_to_scene(bool value);
    bool get_close_returns_to_scene() const;
    void set_play_menu_music_on_ready(bool value);
    bool get_play_menu_music_on_ready() const;

    void show_from_button(Control* button);
    void close_overlay();

private:
    String return_scene_path = "res://scenes/main_menu.tscn";
    bool close_returns_to_scene = true;
    bool play_menu_music_on_ready = true;

    Button* close_button = nullptr;
    PanelContainer* settings_panel = nullptr;
    VBoxContainer* settings_box = nullptr;
    PanelContainer* audio_panel = nullptr;
    ScrollContainer* settings_scroll = nullptr;
    RichTextLabel* settings_body = nullptr;
    HSlider* music_volume_slider = nullptr;
    PanelContainer* tutorial_panel = nullptr;
    Label* tutorial_status_label = nullptr;
    Button* tutorial_replay_button = nullptr;
    PanelContainer* gameplay_panel = nullptr;
    CheckButton* screen_shake_toggle = nullptr;
    Button* test_wave_button = nullptr;
    PanelContainer* test_modal_panel = nullptr;
    Label* test_modal_title = nullptr;
    Label* test_modal_body = nullptr;
    Button* test_modal_confirm_button = nullptr;
    Button* test_modal_cancel_button = nullptr;
    LineEdit* test_code_input = nullptr;
    SpinBox* test_wave_input = nullptr;
    bool test_modal_wave_mode = false;

    void build_gameplay_controls();
    void build_tutorial_controls();
    void build_test_dialogs();
    void apply_style();
    void replay_tutorial_pressed();
    void screen_shake_toggled(bool enabled);
    void open_test_code_dialog();
    void confirm_test_modal();
    void close_test_modal();
    void update_gameplay_status();
    void update_tutorial_status();
    void apply_check_button(CheckButton* button);
    Object* space_theme() const;
    Node* game_state() const;
};

}
