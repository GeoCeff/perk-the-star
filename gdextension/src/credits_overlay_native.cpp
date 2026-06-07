#include "credits_overlay_native.h"

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/rich_text_label.hpp>
#include <godot_cpp/classes/scroll_container.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

namespace {

constexpr const char* CREDITS_BODY =
    "Creators\n"
    "- Geo Ceff Vinzr Gabaisen: project creator and developer.\n"
    "- Dexter Juevesano: project creator and developer.\n\n"
    "Made For\n"
    "- Professor Ryan Ciriaco Dulaca.\n"
    "- Created as a CMSC 21 course project.\n\n"
    "Project\n"
    "- Perk the Star: a real-time orbital tower defense game about protecting the Sun from Astrophage.\n"
    "- Built with Godot Engine 4.x, C++, GDExtension, native UI scenes, JSON wave data, and project scripts.\n\n"
    "Original Project Work\n"
    "- Game design, wave tuning, tower behavior, enemy behavior, HUD flow, menu flow, settings, codex, and credits integration by the project creators.\n"
    "- Local project art assets are used for towers, enemy sprites, optimized enemy animation frames, and gameplay visual elements.\n"
    "- Local project audio assets are used for main menu music, wave music, boss music, ending music, and gameplay sound effects.\n\n"
    "Assets And Resources\n"
    "- Godot Engine, MIT License. Used as the game engine and editor runtime.\n"
    "- Godot C++ bindings and GDExtension resources. Used for native C++ gameplay and UI classes.\n"
    "- Kenney UI Pack: Sci-fi 2.0, CC0. Used for sci-fi bars, reticle UI pieces, interface accents, and visual UI styling references.\n"
    "- Kenney Future and Kenney Future Narrow, CC0. Used for display headings and button typography.\n"
    "- Electrolize by Cyreal, SIL Open Font License 1.1. Used as the readable body and interface font.\n"
    "- Screaming Brain Studios seamless space backgrounds, CC0. Used for menu and battle space backgrounds.\n"
    "- Sci-Fi Game Icons, local user-provided pack. Used for menu and HUD button icons.\n"
    "- Credits icon created for this project and stored with the UI icon assets.\n\n"
    "License Files\n"
    "- Asset license files are stored in res://assets/licenses/.\n"
    "- Third-party asset summary is stored in res://assets/licenses/THIRD_PARTY_ASSETS.md.\n"
    "- Original license text files are included where available.";

template <typename T>
T* node_as(Node* owner, const char* path) {
    return Object::cast_to<T>(owner->get_node_or_null(NodePath(path)));
}

}

void CreditsOverlayNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_return_scene_path", "path"), &CreditsOverlayNative::set_return_scene_path);
    ClassDB::bind_method(D_METHOD("get_return_scene_path"), &CreditsOverlayNative::get_return_scene_path);
    ClassDB::bind_method(D_METHOD("close_overlay"), &CreditsOverlayNative::close_overlay);
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "return_scene_path", PROPERTY_HINT_FILE, "*.tscn"), "set_return_scene_path", "get_return_scene_path");
}

void CreditsOverlayNative::_ready() {
    credits_panel = node_as<PanelContainer>(this, "credits_panel");
    credits_title = node_as<Label>(this, "credits_panel/credits_margin/credits_box/credits_title");
    credits_subtitle = node_as<Label>(this, "credits_panel/credits_margin/credits_box/credits_subtitle");
    credits_scroll = node_as<ScrollContainer>(this, "credits_panel/credits_margin/credits_box/credits_scroll");
    credits_body = node_as<RichTextLabel>(this, "credits_panel/credits_margin/credits_box/credits_scroll/credits_body");
    close_button = node_as<Button>(this, "credits_panel/credits_margin/credits_box/credits_close");

    if (Node* music = get_node_or_null(NodePath("/root/MusicManager"))) {
        music->call("play_menu_music");
    }
    apply_style();
    if (close_button != nullptr) {
        close_button->grab_focus();
    }
}

void CreditsOverlayNative::_unhandled_input(const Ref<InputEvent>& event) {
    if (event.is_valid() && event->is_action_pressed("ui_cancel")) {
        close_overlay();
    }
}

void CreditsOverlayNative::set_return_scene_path(const String& path) { return_scene_path = path; }
String CreditsOverlayNative::get_return_scene_path() const { return return_scene_path; }

void CreditsOverlayNative::close_overlay() {
    get_tree()->change_scene_to_file(return_scene_path);
}

void CreditsOverlayNative::apply_style() {
    Object* theme = space_theme();
    if (theme == nullptr) {
        return;
    }
    theme->call("apply_cursor");
    theme->call("apply_fonts", this);
    theme->call("apply_deep_panel", credits_panel, theme->get("COLOR_CYAN"));
    theme->call("apply_scroll_container", credits_scroll);
    theme->call("apply_rich_text_body", credits_body, 24);
    theme->call("apply_secondary_button", close_button, theme->get("ICON_BACK_PATH"));
    if (credits_title != nullptr) {
        credits_title->set_text("Credits");
        credits_title->add_theme_font_size_override("font_size", 52);
        credits_title->add_theme_color_override("font_color", theme->get("COLOR_GOLD"));
    }
    if (credits_subtitle != nullptr) {
        credits_subtitle->set_text("Project creators, class dedication, and asset attributions.");
        credits_subtitle->add_theme_font_size_override("font_size", 24);
        credits_subtitle->add_theme_color_override("font_color", Color(0.55, 0.84, 0.92, 1.0));
    }
    if (credits_body != nullptr) {
        credits_body->set_text(String(theme->call("format_readout_text", String(CREDITS_BODY))));
    }
}

Object* CreditsOverlayNative::space_theme() const {
    static Ref<RefCounted> resource;
    if (resource.is_null()) {
        resource = Ref<RefCounted>(Object::cast_to<RefCounted>(ClassDB::instantiate("SpaceThemeNative")));
    }
    return resource.ptr();
}
