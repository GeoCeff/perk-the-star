#pragma once

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class MainMenuPlayButtonNative : public Button {
    GDCLASS(MainMenuPlayButtonNative, Button)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void set_game_scene_path(const String& path);
    String get_game_scene_path() const;

private:
    String game_scene_path = "res://scenes/game.tscn";
    void on_pressed();
    void start_game();
};

class MainMenuCodexButtonNative : public Button {
    GDCLASS(MainMenuCodexButtonNative, Button)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void set_codex_scene_path(const String& path);
    String get_codex_scene_path() const;

private:
    String codex_scene_path = "res://scenes/ui/mission_codex.tscn";
    void on_pressed();
    void open_codex_scene();
};

class MainMenuSettingsButtonNative : public Button {
    GDCLASS(MainMenuSettingsButtonNative, Button)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void set_settings_scene_path(const String& path);
    String get_settings_scene_path() const;

private:
    String settings_scene_path = "res://scenes/ui/settings_overlay.tscn";
    void on_pressed();
    void open_settings_scene();
};

class MainMenuExitButtonNative : public Button {
    GDCLASS(MainMenuExitButtonNative, Button)

protected:
    static void _bind_methods();

public:
    void _ready() override;

private:
    void on_pressed();
    void quit_game();
};

}
