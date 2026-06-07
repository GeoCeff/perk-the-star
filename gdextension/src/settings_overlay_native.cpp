#include "settings_overlay_native.h"

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/check_button.hpp>
#include <godot_cpp/classes/font.hpp>
#include <godot_cpp/classes/h_box_container.hpp>
#include <godot_cpp/classes/h_slider.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/line_edit.hpp>
#include <godot_cpp/classes/margin_container.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/rich_text_label.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/scroll_container.hpp>
#include <godot_cpp/classes/spin_box.hpp>
#include <godot_cpp/classes/style_box_flat.hpp>
#include <godot_cpp/classes/v_box_container.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable.hpp>

using namespace godot;

namespace {

constexpr const char* SETTINGS_BODY =
    "Required Setup\n"
    "- Open the repository root in Godot 4.6, not the nested game/ folder.\n"
    "- Run project.godot from the repository root.\n"
    "- The main menu launches res://scenes/game.tscn.\n"
    "- Gameplay HUD lives in res://scenes/ui/game_hud.tscn.\n"
    "- Wave data lives in res://data/waves/wave_01.json through wave_12.json.\n\n"
    "Audio\n"
    "- Use this settings panel to toggle music or change music volume.\n"
    "- Main menu, wave, boss, and ending music all read the same saved music setting.\n"
    "- Gameplay feedback sounds are loaded by the native SFX bus when WAV assets exist, with generated fallbacks for remaining cues.\n\n"
    "Game Feel\n"
    "- Screen shake can be disabled while keeping impact flashes and sun breach pulses visible.\n\n"
    "Controls\n"
    "- Towers can be built, upgraded, or sold before and during active waves.\n"
    "- Mouse wheel zooms, right/middle drag pans, WASD pans, and edge hover pans the camera.\n"
    "- Center Sun, Home, or 0 returns the camera to the default view.\n"
    "- End screens support Retry Run and Main Menu, with R and M shortcuts.\n\n"
    "Mission Training\n"
    "- The first gameplay launch shows a guided diagram overlay with arrows for the HUD, tower bay, slots, wave intel, and camera controls.\n"
    "- Finishing or skipping training saves it as complete in user://settings.cfg so it will not replay automatically.\n\n"
    "Native Extension\n"
    "- GDExtension source lives in gdextension/src.\n"
    "- Debug rebuild: scons platform=windows target=template_debug arch=x86_64\n"
    "- Output library: game/bin/perk_the_star.dll\n"
    "- Entry symbol must stay perk_the_star_init.\n\n"
    "Recommended Workflow\n"
    "1. Edit scenes and scripts from the root project.\n"
    "2. Validate wave JSON when changing data/waves.\n"
    "3. Rebuild the native extension only after C++ changes.\n"
    "4. Run the main menu, then Start Defense to enter the current game scene.\n\n"
    "Common Fixes\n"
    "- Failed to load GDExtension: rebuild and confirm game/bin/perk_the_star.gdextension points to the DLL.\n"
    "- gdextension_interface.h missing: install or update godot-cpp before building.\n"
    "- Wave JSON issue: validate the matching file in data/waves.\n"
    "- Missing music: confirm assets/audio/bgm/final contains main_menu.ogg, wave_01.ogg, wave_02.ogg, wave_03.ogg, and BOSS.ogg.";

template <typename T>
T* node_as(Node* owner, const char* path) {
    return Object::cast_to<T>(owner->get_node_or_null(NodePath(path)));
}

void add_margin(MarginContainer* margin, int left, int top, int right, int bottom) {
    margin->add_theme_constant_override("margin_left", left);
    margin->add_theme_constant_override("margin_top", top);
    margin->add_theme_constant_override("margin_right", right);
    margin->add_theme_constant_override("margin_bottom", bottom);
}

}

void SettingsOverlayNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_return_scene_path", "path"), &SettingsOverlayNative::set_return_scene_path);
    ClassDB::bind_method(D_METHOD("get_return_scene_path"), &SettingsOverlayNative::get_return_scene_path);
    ClassDB::bind_method(D_METHOD("set_close_returns_to_scene", "value"), &SettingsOverlayNative::set_close_returns_to_scene);
    ClassDB::bind_method(D_METHOD("get_close_returns_to_scene"), &SettingsOverlayNative::get_close_returns_to_scene);
    ClassDB::bind_method(D_METHOD("set_play_menu_music_on_ready", "value"), &SettingsOverlayNative::set_play_menu_music_on_ready);
    ClassDB::bind_method(D_METHOD("get_play_menu_music_on_ready"), &SettingsOverlayNative::get_play_menu_music_on_ready);
    ClassDB::bind_method(D_METHOD("show_from_button", "button"), &SettingsOverlayNative::show_from_button);
    ClassDB::bind_method(D_METHOD("close_overlay"), &SettingsOverlayNative::close_overlay);
    ClassDB::bind_method(D_METHOD("_on_replay_tutorial_pressed"), &SettingsOverlayNative::replay_tutorial_pressed);
    ClassDB::bind_method(D_METHOD("_on_screen_shake_toggled", "enabled"), &SettingsOverlayNative::screen_shake_toggled);
    ClassDB::bind_method(D_METHOD("_open_test_code_dialog"), &SettingsOverlayNative::open_test_code_dialog);
    ClassDB::bind_method(D_METHOD("_confirm_test_modal"), &SettingsOverlayNative::confirm_test_modal);
    ClassDB::bind_method(D_METHOD("_close_test_modal"), &SettingsOverlayNative::close_test_modal);
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "return_scene_path", PROPERTY_HINT_FILE, "*.tscn"), "set_return_scene_path", "get_return_scene_path");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "close_returns_to_scene"), "set_close_returns_to_scene", "get_close_returns_to_scene");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "play_menu_music_on_ready"), "set_play_menu_music_on_ready", "get_play_menu_music_on_ready");
}

void SettingsOverlayNative::_ready() {
    close_button = node_as<Button>(this, "settings_panel/settings_margin/settings_box/settings_close");
    settings_panel = node_as<PanelContainer>(this, "settings_panel");
    settings_box = node_as<VBoxContainer>(this, "settings_panel/settings_margin/settings_box");
    audio_panel = node_as<PanelContainer>(this, "settings_panel/settings_margin/settings_box/audio_panel");
    settings_scroll = node_as<ScrollContainer>(this, "settings_panel/settings_margin/settings_box/settings_scroll");
    settings_body = node_as<RichTextLabel>(this, "settings_panel/settings_margin/settings_box/settings_scroll/settings_body");
    music_volume_slider = node_as<HSlider>(this, "settings_panel/settings_margin/settings_box/audio_panel/audio_margin/audio_box/volume_row/music_volume_slider");
    credits_button = node_as<Button>(this, "settings_panel/settings_margin/settings_box/credits_button");

    set_visible(true);
    if (play_menu_music_on_ready) {
        if (Node* music = get_node_or_null(NodePath("/root/MusicManager"))) {
            music->call("play_menu_music");
        }
    }
    build_gameplay_controls();
    build_tutorial_controls();
    build_test_dialogs();
    apply_style();
    if (close_button != nullptr) {
        close_button->grab_focus();
    }
}

void SettingsOverlayNative::_unhandled_input(const Ref<InputEvent>& event) {
    if (event.is_valid() && event->is_action_pressed("ui_cancel")) {
        close_overlay();
    }
}

void SettingsOverlayNative::set_return_scene_path(const String& path) { return_scene_path = path; }
String SettingsOverlayNative::get_return_scene_path() const { return return_scene_path; }
void SettingsOverlayNative::set_close_returns_to_scene(bool value) { close_returns_to_scene = value; }
bool SettingsOverlayNative::get_close_returns_to_scene() const { return close_returns_to_scene; }
void SettingsOverlayNative::set_play_menu_music_on_ready(bool value) { play_menu_music_on_ready = value; }
bool SettingsOverlayNative::get_play_menu_music_on_ready() const { return play_menu_music_on_ready; }

void SettingsOverlayNative::show_from_button(Control*) {
    if (close_button != nullptr) {
        close_button->grab_focus();
    }
}

void SettingsOverlayNative::close_overlay() {
    if (close_returns_to_scene) {
        get_tree()->change_scene_to_file(return_scene_path);
    } else {
        queue_free();
    }
}

void SettingsOverlayNative::build_gameplay_controls() {
    if (gameplay_panel != nullptr || settings_box == nullptr || audio_panel == nullptr) {
        return;
    }
    gameplay_panel = memnew(PanelContainer);
    gameplay_panel->set_name("gameplay_panel");
    settings_box->add_child(gameplay_panel);
    settings_box->move_child(gameplay_panel, audio_panel->get_index() + 1);

    MarginContainer* margin = memnew(MarginContainer);
    margin->set_name("gameplay_margin");
    add_margin(margin, 18, 12, 18, 12);
    gameplay_panel->add_child(margin);

    HBoxContainer* row = memnew(HBoxContainer);
    row->set_name("gameplay_row");
    row->add_theme_constant_override("separation", 14);
    margin->add_child(row);

    VBoxContainer* text_box = memnew(VBoxContainer);
    text_box->set_name("gameplay_text");
    text_box->set_h_size_flags(Control::SIZE_EXPAND_FILL);
    text_box->add_theme_constant_override("separation", 3);
    row->add_child(text_box);

    Label* title = memnew(Label);
    title->set_name("gameplay_title");
    title->set_text("Game Feel");
    title->add_theme_font_size_override("font_size", 17);
    if (Object* theme = space_theme()) title->add_theme_color_override("font_color", theme->get("COLOR_GOLD"));
    text_box->add_child(title);

    Label* body = memnew(Label);
    body->set_name("gameplay_body");
    body->set_text("Keep impact flashes on, but choose whether sun breaches shake the camera.");
    body->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
    body->add_theme_font_size_override("font_size", 13);
    body->add_theme_color_override("font_color", Color(0.76, 0.88, 0.96, 0.92));
    text_box->add_child(body);

    VBoxContainer* action_box = memnew(VBoxContainer);
    action_box->set_name("gameplay_actions");
    action_box->set_custom_minimum_size(Vector2(206.0, 0.0));
    action_box->add_theme_constant_override("separation", 8);
    row->add_child(action_box);

    screen_shake_toggle = memnew(CheckButton);
    screen_shake_toggle->set_name("screen_shake_toggle");
    screen_shake_toggle->set_text("Screen Shake");
    screen_shake_toggle->set_custom_minimum_size(Vector2(206.0, 38.0));
    screen_shake_toggle->connect("toggled", Callable(this, "_on_screen_shake_toggled"));
    action_box->add_child(screen_shake_toggle);

    test_wave_button = memnew(Button);
    test_wave_button->set_name("test_wave_button");
    test_wave_button->set_text("TEST WAVE");
    test_wave_button->set_custom_minimum_size(Vector2(206.0, 38.0));
    test_wave_button->connect("pressed", Callable(this, "_open_test_code_dialog"));
    action_box->add_child(test_wave_button);
}

void SettingsOverlayNative::build_tutorial_controls() {
    if (tutorial_panel != nullptr || settings_box == nullptr || gameplay_panel == nullptr) {
        return;
    }
    tutorial_panel = memnew(PanelContainer);
    tutorial_panel->set_name("tutorial_panel");
    settings_box->add_child(tutorial_panel);
    settings_box->move_child(tutorial_panel, gameplay_panel->get_index() + 1);

    MarginContainer* margin = memnew(MarginContainer);
    margin->set_name("tutorial_margin");
    add_margin(margin, 18, 12, 18, 12);
    tutorial_panel->add_child(margin);

    HBoxContainer* row = memnew(HBoxContainer);
    row->set_name("tutorial_row");
    row->add_theme_constant_override("separation", 14);
    margin->add_child(row);

    VBoxContainer* text_box = memnew(VBoxContainer);
    text_box->set_name("tutorial_text");
    text_box->set_h_size_flags(Control::SIZE_EXPAND_FILL);
    text_box->add_theme_constant_override("separation", 3);
    row->add_child(text_box);

    Label* title = memnew(Label);
    title->set_name("tutorial_title");
    title->set_text("Mission Training");
    title->add_theme_font_size_override("font_size", 17);
    if (Object* theme = space_theme()) title->add_theme_color_override("font_color", theme->get("COLOR_GOLD"));
    text_box->add_child(title);

    tutorial_status_label = memnew(Label);
    tutorial_status_label->set_name("tutorial_status");
    tutorial_status_label->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
    text_box->add_child(tutorial_status_label);

    tutorial_replay_button = memnew(Button);
    tutorial_replay_button->set_name("tutorial_replay_button");
    tutorial_replay_button->set_text("REPLAY NEXT LAUNCH");
    tutorial_replay_button->set_custom_minimum_size(Vector2(206.0, 38.0));
    tutorial_replay_button->connect("pressed", Callable(this, "_on_replay_tutorial_pressed"));
    row->add_child(tutorial_replay_button);
}

void SettingsOverlayNative::build_test_dialogs() {
    if (test_modal_panel != nullptr) {
        return;
    }

    test_modal_panel = memnew(PanelContainer);
    test_modal_panel->set_name("test_modal_panel");
    test_modal_panel->set_visible(false);
    test_modal_panel->set_z_index(80);
    test_modal_panel->set_mouse_filter(Control::MOUSE_FILTER_STOP);
    test_modal_panel->set_anchors_preset(Control::PRESET_CENTER);
    test_modal_panel->set_offset(SIDE_LEFT, -230.0);
    test_modal_panel->set_offset(SIDE_TOP, -138.0);
    test_modal_panel->set_offset(SIDE_RIGHT, 230.0);
    test_modal_panel->set_offset(SIDE_BOTTOM, 138.0);
    add_child(test_modal_panel);

    MarginContainer* margin = memnew(MarginContainer);
    margin->set_name("test_modal_margin");
    add_margin(margin, 18, 16, 18, 16);
    test_modal_panel->add_child(margin);

    VBoxContainer* box = memnew(VBoxContainer);
    box->set_name("test_modal_box");
    box->add_theme_constant_override("separation", 10);
    margin->add_child(box);

    test_modal_title = memnew(Label);
    test_modal_title->set_name("test_modal_title");
    test_modal_title->set_text("Tester Access");
    test_modal_title->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER);
    test_modal_title->add_theme_font_size_override("font_size", 18);
    box->add_child(test_modal_title);

    test_modal_body = memnew(Label);
    test_modal_body->set_name("test_modal_body");
    test_modal_body->set_text("Enter secret code:");
    test_modal_body->add_theme_font_size_override("font_size", 13);
    test_modal_body->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
    box->add_child(test_modal_body);

    test_code_input = memnew(LineEdit);
    test_code_input->set_name("test_code_input");
    test_code_input->set_secret(true);
    test_code_input->set_placeholder("Secret code");
    test_code_input->set_custom_minimum_size(Vector2(320.0, 36.0));
    test_code_input->connect("text_submitted", Callable(this, "_confirm_test_modal").unbind(1));
    box->add_child(test_code_input);

    test_wave_input = memnew(SpinBox);
    test_wave_input->set_name("test_wave_input");
    test_wave_input->set_min(1.0);
    test_wave_input->set_max(12.0);
    test_wave_input->set_step(1.0);
    test_wave_input->set_value(1.0);
    test_wave_input->set_custom_minimum_size(Vector2(180.0, 36.0));
    test_wave_input->set_visible(false);
    box->add_child(test_wave_input);

    HBoxContainer* buttons = memnew(HBoxContainer);
    buttons->set_name("test_modal_buttons");
    buttons->add_theme_constant_override("separation", 10);
    buttons->set_alignment(BoxContainer::ALIGNMENT_CENTER);
    box->add_child(buttons);

    test_modal_cancel_button = memnew(Button);
    test_modal_cancel_button->set_name("test_modal_cancel_button");
    test_modal_cancel_button->set_text("CANCEL");
    test_modal_cancel_button->set_custom_minimum_size(Vector2(118.0, 38.0));
    test_modal_cancel_button->connect("pressed", Callable(this, "_close_test_modal"));
    buttons->add_child(test_modal_cancel_button);

    test_modal_confirm_button = memnew(Button);
    test_modal_confirm_button->set_name("test_modal_confirm_button");
    test_modal_confirm_button->set_text("NEXT");
    test_modal_confirm_button->set_custom_minimum_size(Vector2(118.0, 38.0));
    test_modal_confirm_button->connect("pressed", Callable(this, "_confirm_test_modal"));
    buttons->add_child(test_modal_confirm_button);
}

void SettingsOverlayNative::apply_style() {
    Object* theme = space_theme();
    if (theme == nullptr) {
        return;
    }
    theme->call("apply_cursor");
    theme->call("apply_fonts", this);
    theme->call("apply_deep_panel", settings_panel, theme->get("COLOR_CYAN"));
    theme->call("apply_panel", audio_panel, theme->get("COLOR_GOLD"));
    theme->call("apply_panel", gameplay_panel, theme->get("COLOR_CYAN"));
    theme->call("apply_panel", tutorial_panel, theme->get("COLOR_CYAN"));
    theme->call("apply_deep_panel", test_modal_panel, theme->get("COLOR_CYAN"));
    theme->call("apply_scroll_container", settings_scroll);
    theme->call("apply_rich_text_body", settings_body, 16);
    theme->call("apply_slider", music_volume_slider);
    apply_check_button(screen_shake_toggle);
    theme->call("apply_secondary_button", test_wave_button);
    theme->call("apply_secondary_button", tutorial_replay_button);
    theme->call("apply_secondary_button", credits_button, theme->get("ICON_CREDITS_PATH"));
    theme->call("apply_secondary_button", test_modal_cancel_button);
    theme->call("apply_primary_button", test_modal_confirm_button);
    theme->call("apply_secondary_button", close_button, theme->get("ICON_BACK_PATH"));
    if (settings_scroll != nullptr) {
        settings_scroll->set_custom_minimum_size(Vector2(settings_scroll->get_custom_minimum_size().x, 170.0));
    }
    if (tutorial_status_label != nullptr) {
        tutorial_status_label->add_theme_font_size_override("font_size", 13);
        tutorial_status_label->add_theme_color_override("font_color", Color(0.76, 0.88, 0.96, 0.92));
    }
    if (tutorial_replay_button != nullptr) {
        tutorial_replay_button->add_theme_font_size_override("font_size", 13);
    }
    if (test_wave_button != nullptr) {
        test_wave_button->add_theme_font_size_override("font_size", 13);
    }
    if (credits_button != nullptr) {
        credits_button->add_theme_font_size_override("font_size", 13);
    }
    if (test_modal_title != nullptr) {
        test_modal_title->add_theme_color_override("font_color", theme->get("COLOR_GOLD"));
    }
    if (test_modal_body != nullptr) {
        test_modal_body->add_theme_color_override("font_color", Color(0.76, 0.88, 0.96, 0.94));
    }
    Ref<StyleBoxFlat> input_style = theme->call("panel_style", Color(0.006, 0.018, 0.030, 0.96), theme->get("COLOR_CYAN"), 6.0, 10.0, 8.0);
    Ref<Resource> input_font_resource = ResourceLoader::get_singleton()->load(String(theme->get("FONT_BODY_PATH")));
    Ref<Font> input_font = input_font_resource;
    if (test_code_input != nullptr) {
        if (input_font.is_valid()) test_code_input->add_theme_font_override("font", input_font);
        test_code_input->add_theme_color_override("font_color", theme->get("COLOR_TEXT"));
        test_code_input->add_theme_color_override("font_placeholder_color", Color(0.52, 0.66, 0.76, 0.82));
        test_code_input->add_theme_stylebox_override("normal", input_style);
        test_code_input->add_theme_stylebox_override("focus", input_style);
    }
    if (test_wave_input != nullptr && test_wave_input->get_line_edit() != nullptr) {
        if (input_font.is_valid()) test_wave_input->get_line_edit()->add_theme_font_override("font", input_font);
        test_wave_input->get_line_edit()->add_theme_color_override("font_color", theme->get("COLOR_TEXT"));
        test_wave_input->get_line_edit()->add_theme_stylebox_override("normal", input_style);
        test_wave_input->get_line_edit()->add_theme_stylebox_override("focus", input_style);
    }
    if (settings_body != nullptr) {
        settings_body->set_text(String(theme->call("format_readout_text", String(SETTINGS_BODY))));
    }
    update_gameplay_status();
    update_tutorial_status();
}

void SettingsOverlayNative::replay_tutorial_pressed() {
    if (Node* state = game_state()) {
        state->call("set_tutorial_completed", false);
    }
    update_tutorial_status();
}

void SettingsOverlayNative::screen_shake_toggled(bool enabled) {
    if (Node* state = game_state()) {
        state->call("set_screen_shake_enabled", enabled);
    }
    update_gameplay_status();
}

void SettingsOverlayNative::open_test_code_dialog() {
    if (test_modal_panel == nullptr || test_modal_title == nullptr || test_modal_body == nullptr || test_code_input == nullptr || test_wave_input == nullptr || test_modal_confirm_button == nullptr) {
        return;
    }
    test_modal_wave_mode = false;
    test_modal_title->set_text("Tester Access");
    test_modal_body->set_text("Enter secret code:");
    test_modal_confirm_button->set_text("NEXT");
    test_code_input->clear();
    test_code_input->set_visible(true);
    test_wave_input->set_visible(false);
    test_modal_panel->set_visible(true);
    test_code_input->grab_focus();
}

void SettingsOverlayNative::confirm_test_modal() {
    if (test_modal_panel == nullptr || test_modal_title == nullptr || test_modal_body == nullptr || test_code_input == nullptr || test_wave_input == nullptr || test_modal_confirm_button == nullptr) {
        return;
    }
    if (test_modal_wave_mode) {
        if (Node* state = game_state()) {
            state->call("enable_test_run", int(test_wave_input->get_value()));
        }
        if (Node* music = get_node_or_null(NodePath("/root/MusicManager"))) {
            music->call("stop_music");
        }
        get_tree()->change_scene_to_file("res://scenes/game.tscn");
        return;
    }
    if (test_code_input->get_text().strip_edges().to_lower() != "dexterbayot") {
        test_code_input->clear();
        test_modal_body->set_text("Wrong code. Enter secret code:");
        test_code_input->grab_focus();
        return;
    }
    test_modal_wave_mode = true;
    test_modal_title->set_text("Start Test Wave");
    test_modal_body->set_text("Choose wave to start:");
    test_modal_confirm_button->set_text("START");
    test_code_input->set_visible(false);
    test_wave_input->set_value(1.0);
    test_wave_input->set_visible(true);
    test_wave_input->grab_focus();
}

void SettingsOverlayNative::close_test_modal() {
    if (test_modal_panel != nullptr) {
        test_modal_panel->set_visible(false);
    }
}

void SettingsOverlayNative::update_gameplay_status() {
    if (screen_shake_toggle == nullptr) {
        return;
    }
    if (Node* state = game_state()) {
        screen_shake_toggle->set_pressed_no_signal(bool(state->get("screen_shake_enabled")));
    }
}

void SettingsOverlayNative::update_tutorial_status() {
    if (tutorial_status_label == nullptr || tutorial_replay_button == nullptr) {
        return;
    }
    bool completed = false;
    if (Node* state = game_state()) {
        completed = bool(state->get("tutorial_completed"));
    }
    if (completed) {
        tutorial_status_label->set_text("Completed. Queue it again only when you want the first-run diagram overlay to appear.");
        tutorial_replay_button->set_disabled(false);
    } else {
        tutorial_status_label->set_text("Queued. The diagram overlay will appear on the next gameplay launch, then save when skipped or finished.");
        tutorial_replay_button->set_disabled(true);
    }
}

void SettingsOverlayNative::apply_check_button(CheckButton* button) {
    if (button == nullptr) {
        return;
    }
    Object* theme = space_theme();
    if (theme != nullptr) {
        Ref<Resource> font_resource = ResourceLoader::get_singleton()->load(String(theme->get("FONT_BUTTON_PATH")));
        Ref<Font> font = font_resource;
        if (font.is_valid()) {
            button->add_theme_font_override("font", font);
        }
        button->add_theme_color_override("font_color", theme->get("COLOR_TEXT"));
    }
    button->add_theme_font_size_override("font_size", 13);
    button->add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.74, 1.0));
    button->add_theme_color_override("font_pressed_color", Color(1.0, 0.96, 0.74, 1.0));
    button->set_default_cursor_shape(Control::CURSOR_POINTING_HAND);
}

Object* SettingsOverlayNative::space_theme() const {
    static Ref<RefCounted> resource;
    if (resource.is_null()) {
        resource = Ref<RefCounted>(Object::cast_to<RefCounted>(ClassDB::instantiate("SpaceThemeNative")));
    }
    return resource.ptr();
}

Node* SettingsOverlayNative::game_state() const {
    return get_node_or_null(NodePath("/root/GameState"));
}
