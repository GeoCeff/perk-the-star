#include "codex_native.h"

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/rich_text_label.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/scroll_container.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable.hpp>

using namespace godot;

namespace {

template <typename T>
T* node_as(Node* owner, const char* path) {
    return Object::cast_to<T>(owner->get_node_or_null(NodePath(path)));
}

Dictionary section(const String& title, const String& body) {
    Dictionary data;
    data["title"] = title;
    data["body"] = body;
    return data;
}

}

void CodexNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_return_scene_path", "path"), &CodexNative::set_return_scene_path);
    ClassDB::bind_method(D_METHOD("get_return_scene_path"), &CodexNative::get_return_scene_path);
    ClassDB::bind_method(D_METHOD("set_close_returns_to_scene", "value"), &CodexNative::set_close_returns_to_scene);
    ClassDB::bind_method(D_METHOD("get_close_returns_to_scene"), &CodexNative::get_close_returns_to_scene);
    ClassDB::bind_method(D_METHOD("set_play_menu_music_on_ready", "value"), &CodexNative::set_play_menu_music_on_ready);
    ClassDB::bind_method(D_METHOD("get_play_menu_music_on_ready"), &CodexNative::get_play_menu_music_on_ready);
    ClassDB::bind_method(D_METHOD("show_standalone_mode"), &CodexNative::show_standalone_mode);
    ClassDB::bind_method(D_METHOD("_on_close_pressed"), &CodexNative::close_pressed);
    ClassDB::bind_method(D_METHOD("_show_section", "section_key"), &CodexNative::show_section);
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "return_scene_path", PROPERTY_HINT_FILE, "*.tscn"), "set_return_scene_path", "get_return_scene_path");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "close_returns_to_scene"), "set_close_returns_to_scene", "get_close_returns_to_scene");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "play_menu_music_on_ready"), "set_play_menu_music_on_ready", "get_play_menu_music_on_ready");
}

void CodexNative::_ready() {
    close_button = node_as<Button>(this, "panel/margin/root_box/content_box/nav_box/close_button");
    panel = node_as<PanelContainer>(this, "panel");
    section_title_label = node_as<Label>(this, "panel/margin/root_box/content_box/article_box/section_title_label");
    body_scroll = node_as<ScrollContainer>(this, "panel/margin/root_box/content_box/article_box/body_scroll");
    body_label = node_as<RichTextLabel>(this, "panel/margin/root_box/content_box/article_box/body_scroll/body_label");

    nav_buttons["briefing"] = node_as<Button>(this, "panel/margin/root_box/content_box/nav_box/btn_briefing");
    nav_buttons["systems"] = node_as<Button>(this, "panel/margin/root_box/content_box/nav_box/btn_systems");
    nav_buttons["towers"] = node_as<Button>(this, "panel/margin/root_box/content_box/nav_box/btn_towers");
    nav_buttons["astrophage"] = node_as<Button>(this, "panel/margin/root_box/content_box/nav_box/btn_astrophage");
    nav_buttons["rings"] = node_as<Button>(this, "panel/margin/root_box/content_box/nav_box/btn_rings");
    nav_buttons["endings"] = node_as<Button>(this, "panel/margin/root_box/content_box/nav_box/btn_endings");
    build_sections();

    set_visible(true);
    if (play_menu_music_on_ready) {
        if (Node* music = get_node_or_null(NodePath("/root/MusicManager"))) {
            music->call("play_menu_music");
        }
    }
    apply_style();
    if (close_button != nullptr) {
        close_button->connect("pressed", Callable(this, "_on_close_pressed"));
    }
    const Array keys = nav_buttons.keys();
    for (int i = 0; i < keys.size(); ++i) {
        const String section_key = keys[i];
        Button* button = Object::cast_to<Button>(nav_buttons[section_key]);
        if (button == nullptr) {
            continue;
        }
        button->set_toggle_mode(true);
        button->connect("pressed", Callable(this, "_show_section").bind(section_key));
        if (Object* theme = space_theme()) {
            theme->call("apply_secondary_button", button);
        }
        button->add_theme_font_size_override("font_size", 16);
    }
    if (Object* theme = space_theme()) {
        theme->call("apply_secondary_button", close_button, theme->get("ICON_BACK_PATH"));
    }
    show_section("briefing");
}

void CodexNative::set_return_scene_path(const String& path) { return_scene_path = path; }
String CodexNative::get_return_scene_path() const { return return_scene_path; }
void CodexNative::set_close_returns_to_scene(bool value) { close_returns_to_scene = value; }
bool CodexNative::get_close_returns_to_scene() const { return close_returns_to_scene; }
void CodexNative::set_play_menu_music_on_ready(bool value) { play_menu_music_on_ready = value; }
bool CodexNative::get_play_menu_music_on_ready() const { return play_menu_music_on_ready; }

void CodexNative::show_standalone_mode() {
    close_returns_to_scene = false;
    set_visible(true);
    show_section("briefing");
}

void CodexNative::close_pressed() {
    if (close_returns_to_scene) {
        get_tree()->change_scene_to_file(return_scene_path);
    } else {
        queue_free();
    }
}

void CodexNative::show_section(const String& section_key) {
    current_section = section_key;
    Dictionary data = sections.get(section_key, sections["briefing"]);
    if (section_title_label != nullptr) {
        section_title_label->set_text(String(data["title"]));
    }
    if (body_label != nullptr) {
        String body = data["body"];
        if (Object* theme = space_theme()) {
            body_label->set_text(String(theme->call("format_readout_text", body)));
        } else {
            body_label->set_text(body);
        }
    }
    if (body_scroll != nullptr) {
        body_scroll->set_v_scroll(0);
    }
    update_nav_state();
}

void CodexNative::update_nav_state() {
    Object* theme = space_theme();
    const Array keys = nav_buttons.keys();
    for (int i = 0; i < keys.size(); ++i) {
        const String section_key = keys[i];
        Button* button = Object::cast_to<Button>(nav_buttons[section_key]);
        if (button == nullptr) {
            continue;
        }
        const bool pressed = section_key == current_section;
        button->set_pressed_no_signal(pressed);
        if (theme != nullptr) {
            if (pressed) {
                theme->call("apply_primary_button", button);
            } else {
                theme->call("apply_secondary_button", button);
            }
        }
        button->add_theme_font_size_override("font_size", 16);
    }
}

void CodexNative::apply_style() {
    Object* theme = space_theme();
    if (theme == nullptr) {
        return;
    }
    theme->call("apply_cursor");
    theme->call("apply_fonts", this);
    theme->call("apply_deep_panel", panel, theme->get("COLOR_CYAN"));
    theme->call("apply_scroll_container", body_scroll);
    theme->call("apply_rich_text_body", body_label, 17);
}

void CodexNative::build_sections() {
    sections["briefing"] = section("Mission Briefing", R"(Perk the Star is a single-player, real-time orbital tower defense game. You command the Sol Defense Corps and protect the Sun from Astrophage: photosynthetic microorganisms feeding on stellar energy.

Objective
- Keep luminosity above zero.
- Clear all 12 JSON-authored waves.
- Spend Sol Credits on orbiting defense satellites.
- Build, upgrade, or sell towers even while a wave is active.
- Survive through Astrophage Prime.

Command phrase
Defend me, defend me! - Oa ka Perk!)");

    sections["systems"] = section("Core Systems", R"(GameState
Central runtime data: luminosity, Sol Credits, wave phase, score, signals, flare charge, tutorial completion, screen shake, and Auto Start.

Sun
Tracks luminosity, expression states, and death/victory state. The Sun changes expression as luminosity drops.

OrbitalTower
Orbiting defense satellites. Their value depends on orbital radius, period, firing cooldown, tower level, and engagement windows.

WaveManager
Loads wave JSON and manages the 12-wave spawn loop.

SolarFlare
Manual radial burst. The flare charges every 3 cleared waves and can be fired during an active wave to relieve pressure.

UIManager
HUD, tower hover cards, tower management, wave intel, tutorial overlay, pause menu, settings, codex, and end-state buttons.

Camera
Mouse wheel zooms around the cursor. Right/middle drag, screen-edge hover, and WASD pan around the star. Center Sun snaps back.)");

    sections["towers"] = section("Tower Dossier", R"(Photon Splitter
Baseline direct-damage tower. Best on the fast Corona Belt for early intercept, but Photon Mimics ignore it and Solar Farmers can absorb it.

Cryo Probe
Control tower for slowing threats. Strong on the Chromosphere Band and useful before enemies reach inner rings. It can be disrupted by solar storm events.

Bio-Lab Station
Analysis and counter-biology platform. It clears lodged Burrowers, benefits from Research Surge, and opens Astrophage Prime's shell.

Magnetic Net
Long-range field-control support tower. It slows enemies so heavy towers get more time to fire.

Helios Cannon
High-impact solar weapon. Strong finisher, but Solar Farmers absorb it and accelerate if they are not controlled first.

Tardigrade Bomb
Heavy finisher. Best after Cryo Probe or Magnetic Net has slowed the target.

Upgrades + Selling
Click a placed tower to open its management panel. Upgrades show current stats, exact stat gains, final upgraded stats, and cost. Selling refunds part of the Sol spent.)");

    sections["astrophage"] = section("Astrophage Variants", R"(0 - Drifter
Baseline Astrophage. Use it to verify tower timing, wave pacing, and credit rewards.

1 - Bloom
Splitting threat. Defeated Blooms split into three Drifters, so slowing them before they break is safer.

2 - Burrower
Sun-pressure threat. If it reaches the Sun, it lodges inside and drains luminosity until Bio-Lab excavates it.

3 - Mimic
Detection/targeting challenge. Carries the MIMIC tag and ignores Photon Splitters, forcing mixed tower plans.

4 - Farmer
Counterplay enemy. Carries the ABSORB tag and feeds from Photon/Helios damage, gaining HP and speed.

5 - Astrophage Prime
Boss wave target. Wave 12 is the Prime encounter. SHELL blocks most damage until Bio-Lab opens it; OPEN means the boss is vulnerable.)");

    sections["rings"] = section("Rings + Waves", R"(Orbital Rings
Ring 1 - Corona Belt: radius 80 px, period 6 s, 4 slots. Best: Photon Splitter, Helios Cannon.
Ring 2 - Chromosphere Band: radius 140 px, period 11 s, 6 slots. Best: Cryo Probe, Tardigrade Bomb.
Ring 3 - Photosphere Arc: radius 210 px, period 17 s, 8 slots. Best: Bio-Lab Station, Magnetic Net.
Ring 4 - Outer Veil: radius 290 px, period 26 s, 10 slots. Best: early intercept and scout role.

Strategic Rule
Inner rings orbit fast, giving short engagement windows. Outer rings orbit slowly, giving longer intercept windows.

Wave Plan
- 12 waves are loaded from JSON.
- Wave 6: mid-wave auto flare / Cryo disruption.
- Wave 7: night-side ring pressure.
- Wave 10: Bio-Lab boost.
- Wave 12: Astrophage Prime.

Wave Intel
The HUD previews enemy counts, warning tags, reward, and a quick counter hint before each wave. Auto Start can launch ready waves after a short countdown.)");

    sections["endings"] = section("Victory + Failure", R"(Full Shine
Clear 12 waves with luminosity above 80%.

Dim but Alive
Clear 12 waves with luminosity from 20% to 80%.

Last Light
Clear 12 waves with luminosity from 1% to 20%.

Sun Extinguished
Luminosity hits 0%. The guide routes this into a post-mortem screen.

End Screen Tools
Retry Run restarts the mission, Main Menu leaves the run, R retries, and M returns to menu.

Field Reminder
Every credit spent should buy time, coverage, or control. A beautiful orbit means nothing if the Sun goes dark.)");
}

Object* CodexNative::space_theme() const {
    static Ref<RefCounted> resource;
    if (resource.is_null()) {
        resource = Ref<RefCounted>(Object::cast_to<RefCounted>(ClassDB::instantiate("SpaceThemeNative")));
    }
    return resource.ptr();
}
