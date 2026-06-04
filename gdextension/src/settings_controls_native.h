#pragma once

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/check_button.hpp>
#include <godot_cpp/classes/h_slider.hpp>
#include <godot_cpp/variant/node_path.hpp>

namespace godot {

class MainMenuMusicToggleNative : public CheckButton {
    GDCLASS(MainMenuMusicToggleNative, CheckButton)

protected:
    static void _bind_methods();

public:
    void _ready() override;

private:
    void on_toggled(bool enabled);
    void on_music_settings_changed(bool enabled, double volume);
};

class MainMenuMusicVolumeSliderNative : public HSlider {
    GDCLASS(MainMenuMusicVolumeSliderNative, HSlider)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void set_value_label_path(const NodePath& path);
    NodePath get_value_label_path() const;

private:
    NodePath value_label_path;
    Object* value_label = nullptr;

    void on_value_changed(double new_value);
    void on_music_settings_changed(bool enabled, double volume);
    void update_value_label();
};

class SettingsOverlayCloseButtonNative : public Button {
    GDCLASS(SettingsOverlayCloseButtonNative, Button)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void set_settings_overlay_path(const NodePath& path);
    NodePath get_settings_overlay_path() const;

private:
    NodePath settings_overlay_path = NodePath("../../../..");
    Object* settings_overlay = nullptr;

    void on_pressed();
};

}
