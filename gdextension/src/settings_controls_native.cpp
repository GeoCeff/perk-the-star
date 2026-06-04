#include "settings_controls_native.h"

#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <cmath>

using namespace godot;

namespace {

Node* game_state(Node* owner) {
    return owner->get_node_or_null(NodePath("/root/GameState"));
}

} // namespace

void MainMenuMusicToggleNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("_on_toggled", "enabled"), &MainMenuMusicToggleNative::on_toggled);
    ClassDB::bind_method(D_METHOD("_on_music_settings_changed", "enabled", "volume"), &MainMenuMusicToggleNative::on_music_settings_changed);
}

void MainMenuMusicToggleNative::_ready() {
    Node* state = game_state(this);
    if (state == nullptr) {
        return;
    }
    set_pressed_no_signal(bool(state->get("music_enabled")));
    connect("toggled", Callable(this, "_on_toggled"));
    state->connect("music_settings_changed", Callable(this, "_on_music_settings_changed"));
}

void MainMenuMusicToggleNative::on_toggled(bool enabled) {
    Node* state = game_state(this);
    if (state != nullptr) {
        state->call("set_music_enabled", enabled);
    }
}

void MainMenuMusicToggleNative::on_music_settings_changed(bool enabled, double) {
    set_pressed_no_signal(enabled);
}

void MainMenuMusicVolumeSliderNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_value_label_path", "path"), &MainMenuMusicVolumeSliderNative::set_value_label_path);
    ClassDB::bind_method(D_METHOD("get_value_label_path"), &MainMenuMusicVolumeSliderNative::get_value_label_path);
    ClassDB::bind_method(D_METHOD("_on_value_changed", "new_value"), &MainMenuMusicVolumeSliderNative::on_value_changed);
    ClassDB::bind_method(D_METHOD("_on_music_settings_changed", "enabled", "volume"), &MainMenuMusicVolumeSliderNative::on_music_settings_changed);
    ClassDB::bind_method(D_METHOD("_update_value_label"), &MainMenuMusicVolumeSliderNative::update_value_label);
    ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "value_label_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "Label"), "set_value_label_path", "get_value_label_path");
}

void MainMenuMusicVolumeSliderNative::_ready() {
    value_label = get_node_or_null(value_label_path);
    Node* state = game_state(this);
    if (state != nullptr) {
        set_value_no_signal(std::round(double(state->get("music_volume")) * 100.0));
        state->connect("music_settings_changed", Callable(this, "_on_music_settings_changed"));
    }
    update_value_label();
    connect("value_changed", Callable(this, "_on_value_changed"));
}

void MainMenuMusicVolumeSliderNative::set_value_label_path(const NodePath& path) {
    value_label_path = path;
}

NodePath MainMenuMusicVolumeSliderNative::get_value_label_path() const {
    return value_label_path;
}

void MainMenuMusicVolumeSliderNative::on_value_changed(double new_value) {
    update_value_label();
    Node* state = game_state(this);
    if (state != nullptr) {
        state->call("set_music_volume", new_value / 100.0);
    }
}

void MainMenuMusicVolumeSliderNative::on_music_settings_changed(bool, double volume) {
    set_value_no_signal(std::round(volume * 100.0));
    update_value_label();
}

void MainMenuMusicVolumeSliderNative::update_value_label() {
    Label* label = Object::cast_to<Label>(value_label);
    if (label == nullptr) {
        return;
    }
    label->set_text(vformat("%d%%", static_cast<int>(std::round(get_value()))));
}

void SettingsOverlayCloseButtonNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_settings_overlay_path", "path"), &SettingsOverlayCloseButtonNative::set_settings_overlay_path);
    ClassDB::bind_method(D_METHOD("get_settings_overlay_path"), &SettingsOverlayCloseButtonNative::get_settings_overlay_path);
    ClassDB::bind_method(D_METHOD("_on_pressed"), &SettingsOverlayCloseButtonNative::on_pressed);
    ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "settings_overlay_path", PROPERTY_HINT_NODE_PATH_VALID_TYPES, "Node"), "set_settings_overlay_path", "get_settings_overlay_path");
}

void SettingsOverlayCloseButtonNative::_ready() {
    settings_overlay = get_node_or_null(settings_overlay_path);
    connect("pressed", Callable(this, "_on_pressed"));
}

void SettingsOverlayCloseButtonNative::set_settings_overlay_path(const NodePath& path) {
    settings_overlay_path = path;
}

NodePath SettingsOverlayCloseButtonNative::get_settings_overlay_path() const {
    return settings_overlay_path;
}

void SettingsOverlayCloseButtonNative::on_pressed() {
    Object* overlay = settings_overlay;
    if (overlay != nullptr && overlay->has_method("close_overlay")) {
        overlay->call("close_overlay");
        return;
    }
    get_tree()->change_scene_to_file("res://scenes/main_menu.tscn");
}
