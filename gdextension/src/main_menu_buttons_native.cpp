#include "main_menu_buttons_native.h"

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

namespace {

void stop_menu_music(Node* owner) {
    Node* music_manager = owner->get_node_or_null(NodePath("/root/MusicManager"));
    if (music_manager != nullptr) {
        music_manager->call("stop_music");
    }
}

void play_menu_music(Node* owner) {
    Node* music_manager = owner->get_node_or_null(NodePath("/root/MusicManager"));
    if (music_manager != nullptr) {
        music_manager->call("play_menu_music");
    }
}

}

void MainMenuPlayButtonNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_game_scene_path", "path"), &MainMenuPlayButtonNative::set_game_scene_path);
    ClassDB::bind_method(D_METHOD("get_game_scene_path"), &MainMenuPlayButtonNative::get_game_scene_path);
    ClassDB::bind_method(D_METHOD("_on_pressed"), &MainMenuPlayButtonNative::on_pressed);
    ClassDB::bind_method(D_METHOD("_start_game"), &MainMenuPlayButtonNative::start_game);
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "game_scene_path", PROPERTY_HINT_FILE, "*.tscn"), "set_game_scene_path", "get_game_scene_path");
}

void MainMenuPlayButtonNative::_ready() {
    add_to_group("main_menu_buttons");
    connect("pressed", Callable(this, "_on_pressed"));
}

void MainMenuPlayButtonNative::set_game_scene_path(const String& path) {
    game_scene_path = path;
}

String MainMenuPlayButtonNative::get_game_scene_path() const {
    return game_scene_path;
}

void MainMenuPlayButtonNative::on_pressed() {
    set_disabled(true);
    call_deferred("_start_game");
}

void MainMenuPlayButtonNative::start_game() {
    if (Node* state = get_node_or_null(NodePath("/root/GameState"))) {
        state->call("clear_test_run");
    }
    stop_menu_music(this);
    const Error error = get_tree()->change_scene_to_file(game_scene_path);
    if (error != OK) {
        set_disabled(false);
        play_menu_music(this);
        UtilityFunctions::push_error(vformat("MainMenuPlayButton: could not start game scene at %s. Error code: %s", game_scene_path, static_cast<int>(error)));
    }
}

void MainMenuCodexButtonNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_codex_scene_path", "path"), &MainMenuCodexButtonNative::set_codex_scene_path);
    ClassDB::bind_method(D_METHOD("get_codex_scene_path"), &MainMenuCodexButtonNative::get_codex_scene_path);
    ClassDB::bind_method(D_METHOD("_on_pressed"), &MainMenuCodexButtonNative::on_pressed);
    ClassDB::bind_method(D_METHOD("_open_codex_scene"), &MainMenuCodexButtonNative::open_codex_scene);
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "codex_scene_path", PROPERTY_HINT_FILE, "*.tscn"), "set_codex_scene_path", "get_codex_scene_path");
}

void MainMenuCodexButtonNative::_ready() {
    add_to_group("main_menu_buttons");
    connect("pressed", Callable(this, "_on_pressed"));
}

void MainMenuCodexButtonNative::set_codex_scene_path(const String& path) {
    codex_scene_path = path;
}

String MainMenuCodexButtonNative::get_codex_scene_path() const {
    return codex_scene_path;
}

void MainMenuCodexButtonNative::on_pressed() {
    set_disabled(true);
    call_deferred("_open_codex_scene");
}

void MainMenuCodexButtonNative::open_codex_scene() {
    const Error error = get_tree()->change_scene_to_file(codex_scene_path);
    if (error != OK) {
        set_disabled(false);
        UtilityFunctions::push_error(vformat("MainMenuCodexButton: could not open codex scene at %s. Error code: %s", codex_scene_path, static_cast<int>(error)));
    }
}

void MainMenuSettingsButtonNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_settings_scene_path", "path"), &MainMenuSettingsButtonNative::set_settings_scene_path);
    ClassDB::bind_method(D_METHOD("get_settings_scene_path"), &MainMenuSettingsButtonNative::get_settings_scene_path);
    ClassDB::bind_method(D_METHOD("_on_pressed"), &MainMenuSettingsButtonNative::on_pressed);
    ClassDB::bind_method(D_METHOD("_open_settings_scene"), &MainMenuSettingsButtonNative::open_settings_scene);
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "settings_scene_path", PROPERTY_HINT_FILE, "*.tscn"), "set_settings_scene_path", "get_settings_scene_path");
}

void MainMenuSettingsButtonNative::_ready() {
    add_to_group("main_menu_buttons");
    connect("pressed", Callable(this, "_on_pressed"));
}

void MainMenuSettingsButtonNative::set_settings_scene_path(const String& path) {
    settings_scene_path = path;
}

String MainMenuSettingsButtonNative::get_settings_scene_path() const {
    return settings_scene_path;
}

void MainMenuSettingsButtonNative::on_pressed() {
    set_disabled(true);
    call_deferred("_open_settings_scene");
}

void MainMenuSettingsButtonNative::open_settings_scene() {
    const Error error = get_tree()->change_scene_to_file(settings_scene_path);
    if (error != OK) {
        set_disabled(false);
        UtilityFunctions::push_error(vformat("MainMenuSettingsButton: could not open settings scene at %s. Error code: %s", settings_scene_path, static_cast<int>(error)));
    }
}

void MainMenuExitButtonNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("_on_pressed"), &MainMenuExitButtonNative::on_pressed);
    ClassDB::bind_method(D_METHOD("_quit_game"), &MainMenuExitButtonNative::quit_game);
}

void MainMenuExitButtonNative::_ready() {
    add_to_group("main_menu_buttons");
    connect("pressed", Callable(this, "_on_pressed"));
}

void MainMenuExitButtonNative::on_pressed() {
    set_disabled(true);
    call_deferred("_quit_game");
}

void MainMenuExitButtonNative::quit_game() {
    get_tree()->quit(0);
}
