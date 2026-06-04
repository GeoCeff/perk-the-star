#include "game_pause_menu_native.h"

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/margin_container.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/rich_text_label.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/v_box_container.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

namespace {

constexpr const char* CODEX_SCENE_PATH = "res://scenes/ui/codex.tscn";
constexpr const char* SETTINGS_SCENE_PATH = "res://scenes/ui/settings_overlay.tscn";
constexpr const char* MAIN_MENU_SCENE_PATH = "res://scenes/main_menu.tscn";
constexpr const char* CONTROLS_TEXT =
    "Build\n"
    "Left click a tower in the Tower Bay, then click an open orbital slot.\n"
    "Click a placed tower to upgrade, sell, or inspect it.\n"
    "Number keys 1-6 select towers.\n\n"
    "Camera\n"
    "Mouse wheel zooms around the cursor.\n"
    "WASD, edge hover, or right/middle drag pans around the star.\n"
    "Home, 0, or Center Sun recenters the view.\n\n"
    "Wave Tools\n"
    "Space or Enter starts the next wave.\n"
    "Auto Start launches ready waves after a short countdown.\n"
    "F fires Solar Flare when charged.\n"
    "Esc opens or closes pause screens.";

template <typename T>
T* node_as(Node* owner, const char* path) {
    return Object::cast_to<T>(owner->get_node_or_null(NodePath(path)));
}

void add_margin_constants(MarginContainer* margin, int left, int top, int right, int bottom) {
    margin->add_theme_constant_override("margin_left", left);
    margin->add_theme_constant_override("margin_top", top);
    margin->add_theme_constant_override("margin_right", right);
    margin->add_theme_constant_override("margin_bottom", bottom);
}

}

void GamePauseMenuNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("_open_codex"), &GamePauseMenuNative::open_codex);
    ClassDB::bind_method(D_METHOD("_open_settings"), &GamePauseMenuNative::open_settings);
    ClassDB::bind_method(D_METHOD("_open_controls"), &GamePauseMenuNative::open_controls);
    ClassDB::bind_method(D_METHOD("_return_to_main_menu"), &GamePauseMenuNative::return_to_main_menu);
    ClassDB::bind_method(D_METHOD("_retry_run"), &GamePauseMenuNative::retry_run);
    ClassDB::bind_method(D_METHOD("_close_pause_menu"), &GamePauseMenuNative::close_pause_menu);
}

void GamePauseMenuNative::_ready() {
    overlay_root = node_as<Control>(this, "OverlayRoot");
    pause_panel = node_as<PanelContainer>(this, "OverlayRoot/PausePanel");
    title_label = node_as<Label>(this, "OverlayRoot/PausePanel/PauseMargin/PauseBox/TitleLabel");
    subtitle_label = node_as<Label>(this, "OverlayRoot/PausePanel/PauseMargin/PauseBox/SubtitleLabel");
    codex_button = node_as<Button>(this, "OverlayRoot/PausePanel/PauseMargin/PauseBox/ButtonBox/CodexButton");
    settings_button = node_as<Button>(this, "OverlayRoot/PausePanel/PauseMargin/PauseBox/ButtonBox/SettingsButton");
    controls_button = node_as<Button>(this, "OverlayRoot/PausePanel/PauseMargin/PauseBox/ButtonBox/ControlsButton");
    retry_button = node_as<Button>(this, "OverlayRoot/PausePanel/PauseMargin/PauseBox/ButtonBox/RetryButton");
    main_menu_button = node_as<Button>(this, "OverlayRoot/PausePanel/PauseMargin/PauseBox/ButtonBox/MainMenuButton");
    back_button = node_as<Button>(this, "OverlayRoot/PausePanel/PauseMargin/PauseBox/ButtonBox/BackButton");
    overlay_host = node_as<Control>(this, "OverlayHost");

    set_process_mode(Node::PROCESS_MODE_ALWAYS);
    if (get_tree() != nullptr) {
        get_tree()->set_pause(true);
    }
    bind_buttons();
    apply_style();
    if (back_button != nullptr) {
        back_button->grab_focus();
    }
}

void GamePauseMenuNative::_exit_tree() {
    if (get_tree() != nullptr && get_tree()->is_paused()) {
        get_tree()->set_pause(false);
    }
}

void GamePauseMenuNative::_unhandled_input(const Ref<InputEvent>& event) {
    if (event.is_valid() && event->is_action_pressed("ui_cancel") && overlay_host != nullptr && overlay_host->get_child_count() == 0) {
        close_pause_menu();
        if (get_viewport() != nullptr) {
            get_viewport()->set_input_as_handled();
        }
    }
}

void GamePauseMenuNative::bind_buttons() {
    if (codex_button != nullptr) codex_button->connect("pressed", Callable(this, "_open_codex"));
    if (settings_button != nullptr) settings_button->connect("pressed", Callable(this, "_open_settings"));
    if (controls_button != nullptr) controls_button->connect("pressed", Callable(this, "_open_controls"));
    if (retry_button != nullptr) retry_button->connect("pressed", Callable(this, "_retry_run"));
    if (main_menu_button != nullptr) main_menu_button->connect("pressed", Callable(this, "_return_to_main_menu"));
    if (back_button != nullptr) back_button->connect("pressed", Callable(this, "_close_pause_menu"));
}

void GamePauseMenuNative::apply_style() {
    Object* theme = space_theme();
    if (theme == nullptr) {
        return;
    }
    theme->call("apply_cursor");
    theme->call("apply_fonts", this);
    theme->call("apply_deep_panel", pause_panel, theme->get("COLOR_CYAN"));
    if (title_label != nullptr) title_label->add_theme_color_override("font_color", theme->get("COLOR_GOLD"));
    if (subtitle_label != nullptr) subtitle_label->add_theme_color_override("font_color", Color(0.62, 0.88, 0.98, 0.96));
    theme->call("apply_secondary_button", codex_button, theme->get("ICON_CODEX_PATH"));
    theme->call("apply_secondary_button", settings_button, theme->get("ICON_SETTINGS_PATH"));
    theme->call("apply_secondary_button", controls_button, theme->get("ICON_SETTINGS_PATH"));
    theme->call("apply_secondary_button", retry_button, theme->get("ICON_PLAY_PATH"));
    theme->call("apply_danger_button", main_menu_button, theme->get("ICON_BACK_PATH"));
    theme->call("apply_primary_button", back_button, theme->get("ICON_PLAY_PATH"));
    Button* buttons[] = {codex_button, settings_button, controls_button, retry_button, main_menu_button, back_button};
    for (Button* button : buttons) {
        if (button != nullptr) {
            button->add_theme_font_size_override("font_size", 20);
        }
    }
}

void GamePauseMenuNative::open_codex() {
    open_embedded_overlay(CODEX_SCENE_PATH);
}

void GamePauseMenuNative::open_settings() {
    open_embedded_overlay(SETTINGS_SCENE_PATH);
}

void GamePauseMenuNative::open_controls() {
    if (overlay_host == nullptr || overlay_host->get_child_count() > 0) {
        return;
    }

    Object* theme = space_theme();
    Control* overlay = memnew(Control);
    overlay->set_name("ControlsOverlay");
    overlay->set_anchors_preset(Control::PRESET_FULL_RECT);
    overlay->set_process_mode(Node::PROCESS_MODE_ALWAYS);
    overlay_host->add_child(overlay);

    PanelContainer* panel = memnew(PanelContainer);
    panel->set_name("ControlsPanel");
    panel->set_custom_minimum_size(Vector2(660.0, 430.0));
    panel->set_anchors_preset(Control::PRESET_CENTER);
    panel->set_offset(SIDE_LEFT, -330.0);
    panel->set_offset(SIDE_TOP, -215.0);
    panel->set_offset(SIDE_RIGHT, 330.0);
    panel->set_offset(SIDE_BOTTOM, 215.0);
    if (theme != nullptr) theme->call("apply_deep_panel", panel, theme->get("COLOR_CYAN"));
    overlay->add_child(panel);

    MarginContainer* margin = memnew(MarginContainer);
    add_margin_constants(margin, 24, 20, 24, 20);
    panel->add_child(margin);

    VBoxContainer* box = memnew(VBoxContainer);
    box->add_theme_constant_override("separation", 12);
    margin->add_child(box);

    Label* title = memnew(Label);
    title->set_text("FIELD CONTROLS");
    title->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER);
    title->add_theme_font_size_override("font_size", 26);
    if (theme != nullptr) title->add_theme_color_override("font_color", theme->get("COLOR_GOLD"));
    box->add_child(title);

    RichTextLabel* body = memnew(RichTextLabel);
    body->set_custom_minimum_size(Vector2(0.0, 280.0));
    if (theme != nullptr) {
        theme->call("apply_rich_text_body", body, 15);
        body->set_text(String(theme->call("format_readout_text", String(CONTROLS_TEXT))));
    } else {
        body->set_text(CONTROLS_TEXT);
    }
    box->add_child(body);

    Button* close_button = memnew(Button);
    close_button->set_text("BACK");
    close_button->set_custom_minimum_size(Vector2(180.0, 44.0));
    if (theme != nullptr) theme->call("apply_primary_button", close_button, theme->get("ICON_BACK_PATH"));
    close_button->connect("pressed", Callable(overlay, "queue_free"));
    box->add_child(close_button);
    close_button->grab_focus();
}

void GamePauseMenuNative::open_embedded_overlay(const String& scene_path) {
    if (overlay_host == nullptr || overlay_host->get_child_count() > 0) {
        return;
    }

    Ref<Resource> resource = ResourceLoader::get_singleton()->load(scene_path);
    Ref<PackedScene> packed_scene = resource;
    if (packed_scene.is_null()) {
        UtilityFunctions::push_error(vformat("GamePauseMenu: could not load overlay scene at %s.", scene_path));
        return;
    }

    Node* overlay = Object::cast_to<Node>(packed_scene->instantiate());
    if (overlay == nullptr) {
        return;
    }
    overlay->set_process_mode(Node::PROCESS_MODE_ALWAYS);
    overlay->set("close_returns_to_scene", false);
    overlay->set("play_menu_music_on_ready", false);
    overlay_host->add_child(overlay);
    Button* close_button = Object::cast_to<Button>(overlay->get_node_or_null(NodePath("panel/margin/root_box/content_box/nav_box/close_button")));
    if (close_button == nullptr) {
        close_button = Object::cast_to<Button>(overlay->get_node_or_null(NodePath("settings_panel/settings_margin/settings_box/settings_close")));
    }
    if (close_button != nullptr) {
        close_button->grab_focus();
    }
}

void GamePauseMenuNative::return_to_main_menu() {
    if (get_tree() != nullptr) {
        get_tree()->set_pause(false);
        get_tree()->change_scene_to_file(MAIN_MENU_SCENE_PATH);
    }
}

void GamePauseMenuNative::retry_run() {
    if (get_tree() != nullptr) {
        get_tree()->set_pause(false);
        get_tree()->reload_current_scene();
    }
}

void GamePauseMenuNative::close_pause_menu() {
    if (get_tree() != nullptr) {
        get_tree()->set_pause(false);
    }
    queue_free();
}

Object* GamePauseMenuNative::space_theme() const {
    static Ref<RefCounted> resource;
    if (resource.is_null()) {
        resource = Ref<RefCounted>(Object::cast_to<RefCounted>(ClassDB::instantiate("SpaceThemeNative")));
    }
    return resource.ptr();
}
