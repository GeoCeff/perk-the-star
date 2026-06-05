#include "main_menu_native.h"

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/property_tweener.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/tween.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

namespace {

constexpr const char* GAME_TITLE = "PERK THE STAR";
constexpr const char* SUBTITLE = "DEFEND THE SUN - SAVE THE SYSTEM";
constexpr const char* TAGLINE = "Defend me, defend me! - Oa ka Perk!";
constexpr const char* OVERVIEW = "Command the Sol Defense Corps in a real-time orbital tower defense game. Protect the Sun from Astrophage, photosynthetic microorganisms feeding on stellar energy.";
constexpr const char* TECH_LABEL = "CMSC 21 | C++ / Godot Engine 4.x / GDExtension";
constexpr const char* AUTHOR_LABEL = "Geo Ceff Gabaisen & Dexter Juevesano";

Node* singleton(Node* owner, const String& name) {
    return owner->get_node_or_null(NodePath(String("/root/") + name));
}

void set_label_text(Label* label, const String& text) {
    if (label != nullptr) {
        label->set_text(text);
    }
}

}

void MainMenuNative::_bind_methods() {}

void MainMenuNative::_ready() {
    btn_play = Object::cast_to<Button>(get_node_or_null(NodePath("CenterContainer/menu_box/button_box/btn_play")));
    btn_codex = Object::cast_to<Button>(get_node_or_null(NodePath("CenterContainer/menu_box/button_box/btn_codex")));
    btn_settings = Object::cast_to<Button>(get_node_or_null(NodePath("CenterContainer/menu_box/button_box/btn_settings")));
    btn_exit = Object::cast_to<Button>(get_node_or_null(NodePath("CenterContainer/menu_box/button_box/btn_exit")));
    menu_frame = Object::cast_to<PanelContainer>(get_node_or_null(NodePath("menu_frame")));
    title_label = Object::cast_to<Label>(get_node_or_null(NodePath("CenterContainer/menu_box/title_label")));
    sub_label = Object::cast_to<Label>(get_node_or_null(NodePath("CenterContainer/menu_box/sub_label")));
    tagline_label = Object::cast_to<Label>(get_node_or_null(NodePath("CenterContainer/menu_box/tagline_label")));
    description_label = Object::cast_to<Label>(get_node_or_null(NodePath("CenterContainer/menu_box/description_label")));
    version_label = Object::cast_to<Label>(get_node_or_null(NodePath("version_label")));
    author_label = Object::cast_to<Label>(get_node_or_null(NodePath("author_label")));

    if (Node* state = singleton(this, "GameState")) {
        state->call("reset_state");
        state->call("load_audio_settings");
        state->call("ensure_music_audible");
    }
    if (Node* music = singleton(this, "MusicManager")) {
        music->call("play_menu_music");
    }

    set_label_text(title_label, GAME_TITLE);
    set_label_text(sub_label, SUBTITLE);
    set_label_text(tagline_label, TAGLINE);
    set_label_text(description_label, OVERVIEW);
    set_label_text(version_label, TECH_LABEL);
    set_label_text(author_label, AUTHOR_LABEL);

    apply_menu_style();

    if (title_label != nullptr) {
        Color modulate = title_label->get_modulate();
        modulate.a = 0.0f;
        title_label->set_modulate(modulate);
        Ref<Tween> tween = create_tween();
        tween->tween_property(title_label, "modulate:a", 1.0, 1.5);
    }
    if (btn_play != nullptr) {
        btn_play->grab_focus();
    }
}

void MainMenuNative::_input(const Ref<InputEvent>& event) {
    if (event.is_valid() && event->is_action_pressed("ui_accept")) {
        Control* focus_owner = get_viewport() != nullptr ? Object::cast_to<Control>(get_viewport()->gui_get_focus_owner()) : nullptr;
        if (focus_owner == nullptr && btn_play != nullptr) {
            btn_play->emit_signal("pressed");
        }
    }
}

void MainMenuNative::apply_menu_style() {
    Object* theme = space_theme();
    if (theme == nullptr) {
        return;
    }

    theme->call("apply_cursor");
    theme->call("apply_fonts", this);
    theme->call("apply_deep_panel", menu_frame, theme->get("COLOR_CYAN"));

    if (title_label != nullptr) title_label->add_theme_color_override("font_color", Color(1.0, 0.88, 0.36));
    if (sub_label != nullptr) sub_label->add_theme_color_override("font_color", Color(0.90, 0.94, 1.0));
    if (tagline_label != nullptr) tagline_label->add_theme_color_override("font_color", Color(0.55, 0.84, 0.92));
    if (description_label != nullptr) description_label->add_theme_color_override("font_color", Color(0.90, 0.94, 1.0));
    if (version_label != nullptr) version_label->add_theme_color_override("font_color", Color(0.78, 0.90, 1.0, 1.0));
    if (author_label != nullptr) author_label->add_theme_color_override("font_color", Color(0.68, 0.94, 1.0, 1.0));

    theme->call("apply_primary_button", btn_play, theme->get("ICON_PLAY_PATH"));
    theme->call("apply_secondary_button", btn_codex, theme->get("ICON_CODEX_PATH"));
    theme->call("apply_secondary_button", btn_settings, theme->get("ICON_SETTINGS_PATH"));
    theme->call("apply_danger_button", btn_exit, theme->get("ICON_BACK_PATH"));

    Array buttons = get_tree()->get_nodes_in_group("main_menu_buttons");
    for (int i = 0; i < buttons.size(); ++i) {
        if (Button* button = Object::cast_to<Button>(buttons[i])) {
            button->add_theme_font_size_override("font_size", 20);
        }
    }
}

Object* MainMenuNative::space_theme() const {
    static Ref<RefCounted> resource;
    if (resource.is_null()) {
        resource = Ref<RefCounted>(Object::cast_to<RefCounted>(ClassDB::instantiate("SpaceThemeNative")));
    }
    return resource.ptr();
}
