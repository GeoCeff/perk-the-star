#include "game_hud_native.h"

#include <godot_cpp/classes/box_container.hpp>
#include <godot_cpp/classes/color_rect.hpp>
#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/h_box_container.hpp>
#include <godot_cpp/classes/margin_container.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/classes/v_box_container.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>

using namespace godot;

namespace {

Color cyan() { return Color(0.22, 0.84, 0.94, 0.82); }
Color gold() { return Color(1.0, 0.78, 0.26, 0.88); }
Color button_bg() { return Color(0.020, 0.052, 0.078, 0.96); }
Color button_hover() { return Color(0.035, 0.085, 0.120, 1.0); }
Color button_pressed() { return Color(0.052, 0.112, 0.138, 1.0); }
Color button_disabled() { return Color(0.018, 0.026, 0.038, 0.78); }
String icon_play() { return "res://assets/ui/icons/icon_play.png"; }
String icon_back() { return "res://assets/ui/icons/icon_back.png"; }

Dictionary tower_button_paths() {
    Dictionary paths;
    paths["photon_splitter"] = "Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll/TowerButtons/PhotonButton";
    paths["cryo_probe"] = "Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll/TowerButtons/CryoButton";
    paths["bio_lab"] = "Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll/TowerButtons/BioLabButton";
    paths["magnetic_net"] = "Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll/TowerButtons/MagneticNetButton";
    paths["helios_cannon"] = "Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll/TowerButtons/HeliosButton";
    paths["tardigrade_bomb"] = "Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll/TowerButtons/TardigradeButton";
    return paths;
}

void set_text(Label* label, const Variant& text) {
    if (label != nullptr) label->set_text(String(text));
}

void set_button_text(Button* button, const Variant& text) {
    if (button != nullptr) button->set_text(String(text));
}

Color color_from_variant(const Variant& value, const Color& fallback) {
    return value.get_type() == Variant::COLOR ? Color(value) : fallback;
}

} // namespace

void GameHudNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("update_view", "state"), &GameHudNative::update_view);
    ClassDB::bind_method(D_METHOD("is_screen_position_over_hud", "screen_position"), &GameHudNative::is_screen_position_over_hud);
    ClassDB::bind_method(D_METHOD("get_tutorial_targets"), &GameHudNative::get_tutorial_targets);
    ClassDB::bind_method(D_METHOD("_fit_layout_to_viewport"), &GameHudNative::fit_layout_to_viewport);
    ClassDB::bind_method(D_METHOD("_on_start_button_pressed"), &GameHudNative::on_start_button_pressed);
    ClassDB::bind_method(D_METHOD("_on_auto_start_button_toggled", "enabled"), &GameHudNative::on_auto_start_button_toggled);
    ClassDB::bind_method(D_METHOD("_on_menu_button_pressed"), &GameHudNative::on_menu_button_pressed);
    ClassDB::bind_method(D_METHOD("_on_tower_button_pressed", "tower_type"), &GameHudNative::on_tower_button_pressed);
    ClassDB::bind_method(D_METHOD("_show_tower_info", "tower_type"), &GameHudNative::show_tower_info);
    ClassDB::bind_method(D_METHOD("_hide_tower_info", "tower_type"), &GameHudNative::hide_tower_info, DEFVAL(""));
    ClassDB::bind_method(D_METHOD("_on_tower_manage_upgrade_pressed"), &GameHudNative::on_tower_manage_upgrade_pressed);
    ClassDB::bind_method(D_METHOD("_on_tower_manage_sell_pressed"), &GameHudNative::on_tower_manage_sell_pressed);
    ClassDB::bind_method(D_METHOD("_on_tower_manage_close_pressed"), &GameHudNative::on_tower_manage_close_pressed);
    ClassDB::bind_method(D_METHOD("_on_center_view_button_pressed"), &GameHudNative::on_center_view_button_pressed);
    ClassDB::bind_method(D_METHOD("_on_end_retry_pressed"), &GameHudNative::on_end_retry_pressed);
    ClassDB::bind_method(D_METHOD("_on_end_main_menu_pressed"), &GameHudNative::on_end_main_menu_pressed);

    ADD_SIGNAL(MethodInfo("start_wave_requested"));
    ADD_SIGNAL(MethodInfo("auto_start_toggled", PropertyInfo(Variant::BOOL, "enabled")));
    ADD_SIGNAL(MethodInfo("menu_requested"));
    ADD_SIGNAL(MethodInfo("tower_selected", PropertyInfo(Variant::STRING, "tower_type")));
    ADD_SIGNAL(MethodInfo("tower_upgrade_requested", PropertyInfo(Variant::INT, "ring_index"), PropertyInfo(Variant::INT, "slot_index")));
    ADD_SIGNAL(MethodInfo("tower_sell_requested", PropertyInfo(Variant::INT, "ring_index"), PropertyInfo(Variant::INT, "slot_index")));
    ADD_SIGNAL(MethodInfo("tower_manage_closed"));
    ADD_SIGNAL(MethodInfo("recenter_requested"));
    ADD_SIGNAL(MethodInfo("retry_requested"));
    ADD_SIGNAL(MethodInfo("main_menu_requested"));
}

void GameHudNative::_ready() {
    bind_nodes();
    bind_buttons();
    build_tower_info_card();
    build_tower_manage_card();
    build_end_state_card();
    apply_styles();
    fit_layout_to_viewport();
    if (Viewport* viewport = get_viewport()) {
        if (!viewport->is_connected("size_changed", Callable(this, "_fit_layout_to_viewport"))) {
            viewport->connect("size_changed", Callable(this, "_fit_layout_to_viewport"));
        }
    }
}

void GameHudNative::bind_nodes() {
    wave_kicker = node<Label>("Hud/TopPanel/WaveBlock/WaveKicker");
    wave_label = node<Label>("Hud/TopPanel/WaveBlock/WaveLabel");
    brief_label = node<Label>("Hud/TopPanel/WaveBlock/BriefLabel");
    credits_label = node<Label>("Hud/StatusPanel/StatusRow/StatsGrid/SolStat/CreditsLabel");
    score_label = node<Label>("Hud/StatusPanel/StatusRow/StatsGrid/ScoreStat/ScoreLabel");
    kills_label = node<Label>("Hud/StatusPanel/StatusRow/StatsGrid/KillsStat/KillsLabel");
    flare_label = node<Label>("Hud/StatusPanel/StatusRow/StatsGrid/FlareStat/FlareLabel");
    luminosity_bar = node<ProgressBar>("Hud/StatusPanel/StatusRow/LuminosityBox/LuminosityBar");
    start_button = node<Button>("Hud/ActionsPanel/ActionRow/StartButton");
    auto_start_button = node<Button>("Hud/ActionsPanel/ActionRow/AutoStartButton");
    menu_button = node<Button>("Hud/ActionsPanel/ActionRow/MenuButton");
    top_panel = node<PanelContainer>("Hud/TopPanel");
    status_panel = node<PanelContainer>("Hud/StatusPanel");
    actions_panel = node<PanelContainer>("Hud/ActionsPanel");
    wave_intel_panel = node<PanelContainer>("Hud/WaveIntel");
    tower_panel = node<PanelContainer>("Hud/BottomRow/TowerPanel");
    hud_root = node<Control>("Hud");
    tower_scroll = node<ScrollContainer>("Hud/BottomRow/TowerPanel/TowerBox/TowerRow/TowerScroll");
    center_view_button = node<Button>("Hud/BottomRow/TowerPanel/TowerBox/TowerRow/CenterViewButton");
    message_panel = node<PanelContainer>("Hud/BottomRow/MessagePanel");
    selected_tower_label = node<Label>("Hud/BottomRow/TowerPanel/TowerBox/TowerHeader/SelectedTowerLabel");
    enemy_preview = node<TextureRect>("Hud/WaveIntel/IntelBox/EnemyRow/EnemyPreview");
    intel_status_label = node<Label>("Hud/WaveIntel/IntelBox/IntelHeader/IntelStatus");
    enemy_label = node<Label>("Hud/WaveIntel/IntelBox/EnemyRow/EnemyText/EnemyLabel");
    threat_label = node<Label>("Hud/WaveIntel/IntelBox/EnemyRow/EnemyText/ThreatLabel");
    ring_label = node<Label>("Hud/WaveIntel/IntelBox/RingLabel");
    message_label = node<Label>("Hud/BottomRow/MessagePanel/MessageBox/MessageLabel");
}

void GameHudNative::bind_buttons() {
    tower_buttons.clear();
    if (start_button) start_button->connect("pressed", Callable(this, "_on_start_button_pressed"));
    if (auto_start_button) auto_start_button->connect("toggled", Callable(this, "_on_auto_start_button_toggled"));
    if (menu_button) menu_button->connect("pressed", Callable(this, "_on_menu_button_pressed"));
    if (center_view_button) center_view_button->connect("pressed", Callable(this, "_on_center_view_button_pressed"));

    Dictionary paths = tower_button_paths();
    Array keys = paths.keys();
    for (int i = 0; i < keys.size(); ++i) {
        String tower_type = keys[i];
        Button* button = Object::cast_to<Button>(get_node_or_null(NodePath(String(paths[tower_type]))));
        if (button == nullptr) {
            UtilityFunctions::push_error(String("GameHudNative: missing tower button at ") + String(paths[tower_type]));
            continue;
        }
        tower_buttons[tower_type] = button;
        button->connect("pressed", Callable(this, "_on_tower_button_pressed").bind(tower_type));
        button->connect("mouse_entered", Callable(this, "_show_tower_info").bind(tower_type));
        button->connect("mouse_exited", Callable(this, "_hide_tower_info").bind(tower_type));
        button->connect("focus_entered", Callable(this, "_show_tower_info").bind(tower_type));
        button->connect("focus_exited", Callable(this, "_hide_tower_info").bind(tower_type));
    }
}

void GameHudNative::update_view(const Dictionary& state) {
    set_text(wave_label, state.get("wave_title", ""));
    set_text(brief_label, state.get("brief", ""));
    set_text(credits_label, state.get("credits", "0"));
    set_text(score_label, state.get("score", "0"));
    set_text(kills_label, state.get("kills", "0"));
    set_text(flare_label, state.get("flare", "CHARGING"));
    if (luminosity_bar) luminosity_bar->set_value(double(state.get("luminosity", 100.0)));
    if (enemy_preview) enemy_preview->set_texture(Ref<Texture2D>(Object::cast_to<Texture2D>(state.get("enemy_texture", Variant()))));
    set_text(intel_status_label, state.get("intel_status", "NEXT"));
    set_text(enemy_label, state.get("enemy_summary", ""));
    set_text(threat_label, state.get("threat", ""));
    set_text(ring_label, state.get("rings", ""));
    set_button_text(start_button, state.get("start_text", "START WAVE"));
    if (start_button) start_button->set_disabled(bool(state.get("start_disabled", false)));
    set_auto_start_button(bool(state.get("auto_start_enabled", false)));
    set_text(message_label, state.get("message", ""));
    set_text(selected_tower_label, state.get("selected_tower", ""));
    update_tower_buttons(state.get("tower_buttons", Dictionary()));
    update_tower_manage_card(state.get("managed_tower", Dictionary()));
    update_end_state_card(state.get("end_state", Dictionary()));
}

bool GameHudNative::is_screen_position_over_hud(const Vector2& screen_position) const {
    Array controls;
    controls.append(top_panel);
    controls.append(status_panel);
    controls.append(actions_panel);
    controls.append(wave_intel_panel);
    controls.append(tower_panel);
    controls.append(message_panel);
    controls.append(tower_info_card);
    controls.append(tower_manage_card);
    controls.append(end_state_panel);
    for (int i = 0; i < controls.size(); ++i) {
        Control* control = Object::cast_to<Control>(controls[i]);
        if (control != nullptr && control->is_visible() && control->get_global_rect().has_point(screen_position)) {
            return true;
        }
    }
    return false;
}

Dictionary GameHudNative::get_tutorial_targets() const {
    Dictionary targets;
    targets["mission"] = control_target(top_panel);
    targets["status"] = control_target(status_panel);
    targets["luminosity"] = control_target(luminosity_bar);
    targets["start_wave"] = control_target(start_button);
    targets["auto_start"] = control_target(auto_start_button);
    targets["menu"] = control_target(menu_button);
    targets["wave_intel"] = control_target(wave_intel_panel);
    targets["tower_bay"] = control_target(tower_panel);
    targets["tower_button"] = control_target(Object::cast_to<Control>(tower_buttons.get("photon_splitter", Variant())));
    targets["center_sun"] = control_target(center_view_button);
    targets["message"] = control_target(message_panel);
    return targets;
}

Dictionary GameHudNative::control_target(Control* control) const {
    Dictionary target;
    if (control == nullptr) return target;
    target["type"] = "rect";
    target["rect"] = control->get_global_rect();
    return target;
}

void GameHudNative::build_tower_info_card() {
    if (hud_root == nullptr) return;
    tower_info_card = memnew(PanelContainer);
    tower_info_card->set_name("TowerInfoCard");
    tower_info_card->set_custom_minimum_size(Vector2(382, 178));
    tower_info_card->set_size(Vector2(382, 178));
    tower_info_card->set_visible(false);
    tower_info_card->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
    tower_info_card->set_z_index(60);
    hud_root->add_child(tower_info_card);

    MarginContainer* margin = memnew(MarginContainer);
    margin->set_name("TowerInfoMargin");
    margin->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
    margin->add_theme_constant_override("margin_left", 14);
    margin->add_theme_constant_override("margin_top", 12);
    margin->add_theme_constant_override("margin_right", 14);
    margin->add_theme_constant_override("margin_bottom", 12);
    tower_info_card->add_child(margin);

    HBoxContainer* row = memnew(HBoxContainer);
    row->set_name("TowerInfoRoot");
    row->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
    row->add_theme_constant_override("separation", 10);
    margin->add_child(row);
    ColorRect* accent = memnew(ColorRect);
    accent->set_name("TowerInfoAccent");
    accent->set_custom_minimum_size(Vector2(3, 0));
    accent->set_color(gold());
    accent->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
    row->add_child(accent);
    VBoxContainer* content = memnew(VBoxContainer);
    content->set_name("TowerInfoContent");
    content->set_h_size_flags(Control::SIZE_EXPAND_FILL);
    content->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
    content->add_theme_constant_override("separation", 5);
    row->add_child(content);
    tower_info_title_label = memnew(Label); tower_info_title_label->set_name("TowerInfoTitle"); tower_info_title_label->set_text("TOWER"); tower_info_title_label->set_clip_text(true); content->add_child(tower_info_title_label);
    tower_info_role_label = memnew(Label); tower_info_role_label->set_name("TowerInfoRole"); tower_info_role_label->set_text("ROLE"); content->add_child(tower_info_role_label);
    tower_info_stats_label = memnew(Label); tower_info_stats_label->set_name("TowerInfoStats"); tower_info_stats_label->set_text("DAMAGE 0  |  RATE 0/S  |  RANGE 0"); tower_info_stats_label->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); content->add_child(tower_info_stats_label);
    tower_info_body_label = memnew(Label); tower_info_body_label->set_name("TowerInfoBody"); tower_info_body_label->set_custom_minimum_size(Vector2(320, 42)); tower_info_body_label->set_text("Tower description."); tower_info_body_label->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); content->add_child(tower_info_body_label);
    tower_info_note_label = memnew(Label); tower_info_note_label->set_name("TowerInfoNote"); tower_info_note_label->set_text("NOTE"); tower_info_note_label->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); content->add_child(tower_info_note_label);
}

void GameHudNative::build_tower_manage_card() {
    if (hud_root == nullptr) return;
    tower_manage_card = memnew(PanelContainer);
    tower_manage_card->set_name("TowerManageCard");
    tower_manage_card->set_custom_minimum_size(Vector2(438, 174));
    tower_manage_card->set_size(Vector2(438, 174));
    tower_manage_card->set_visible(false);
    tower_manage_card->set_mouse_filter(Control::MOUSE_FILTER_STOP);
    tower_manage_card->set_z_index(58);
    hud_root->add_child(tower_manage_card);
    MarginContainer* margin = memnew(MarginContainer);
    margin->set_name("TowerManageMargin");
    margin->add_theme_constant_override("margin_left", 14);
    margin->add_theme_constant_override("margin_top", 12);
    margin->add_theme_constant_override("margin_right", 14);
    margin->add_theme_constant_override("margin_bottom", 12);
    tower_manage_card->add_child(margin);
    VBoxContainer* root = memnew(VBoxContainer); root->set_name("TowerManageRoot"); root->add_theme_constant_override("separation", 7); margin->add_child(root);
    HBoxContainer* header = memnew(HBoxContainer); header->set_name("TowerManageHeader"); header->add_theme_constant_override("separation", 8); root->add_child(header);
    VBoxContainer* title_box = memnew(VBoxContainer); title_box->set_name("TowerManageTitleBox"); title_box->set_h_size_flags(Control::SIZE_EXPAND_FILL); title_box->add_theme_constant_override("separation", 1); header->add_child(title_box);
    tower_manage_title_label = memnew(Label); tower_manage_title_label->set_name("TowerManageTitle"); tower_manage_title_label->set_clip_text(true); title_box->add_child(tower_manage_title_label);
    tower_manage_meta_label = memnew(Label); tower_manage_meta_label->set_name("TowerManageMeta"); tower_manage_meta_label->set_clip_text(true); title_box->add_child(tower_manage_meta_label);
    tower_manage_close_button = memnew(Button); tower_manage_close_button->set_name("TowerManageCloseButton"); tower_manage_close_button->set_custom_minimum_size(Vector2(40, 34)); tower_manage_close_button->set_text("X"); tower_manage_close_button->connect("pressed", Callable(this, "_on_tower_manage_close_pressed")); header->add_child(tower_manage_close_button);
    tower_manage_stats_label = memnew(Label); tower_manage_stats_label->set_name("TowerManageStats"); tower_manage_stats_label->set_custom_minimum_size(Vector2(0, 34)); tower_manage_stats_label->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); root->add_child(tower_manage_stats_label);
    tower_manage_economy_label = memnew(Label); tower_manage_economy_label->set_name("TowerManageEconomy"); tower_manage_economy_label->set_clip_text(true); root->add_child(tower_manage_economy_label);
    HBoxContainer* actions = memnew(HBoxContainer); actions->set_name("TowerManageActions"); actions->add_theme_constant_override("separation", 8); root->add_child(actions);
    tower_manage_upgrade_button = memnew(Button); tower_manage_upgrade_button->set_name("TowerManageUpgradeButton"); tower_manage_upgrade_button->set_custom_minimum_size(Vector2(148, 40)); tower_manage_upgrade_button->set_text("UPGRADE"); tower_manage_upgrade_button->connect("pressed", Callable(this, "_on_tower_manage_upgrade_pressed")); actions->add_child(tower_manage_upgrade_button);
    tower_manage_sell_button = memnew(Button); tower_manage_sell_button->set_name("TowerManageSellButton"); tower_manage_sell_button->set_custom_minimum_size(Vector2(120, 40)); tower_manage_sell_button->set_text("SELL"); tower_manage_sell_button->connect("pressed", Callable(this, "_on_tower_manage_sell_pressed")); actions->add_child(tower_manage_sell_button);
}

void GameHudNative::build_end_state_card() {
    if (hud_root == nullptr) return;
    end_state_panel = memnew(PanelContainer);
    end_state_panel->set_name("EndStateCard");
    end_state_panel->set_custom_minimum_size(Vector2(620, 304));
    end_state_panel->set_size(Vector2(620, 304));
    end_state_panel->set_visible(false);
    end_state_panel->set_mouse_filter(Control::MOUSE_FILTER_STOP);
    end_state_panel->set_z_index(90);
    hud_root->add_child(end_state_panel);
    MarginContainer* margin = memnew(MarginContainer);
    margin->set_name("EndStateMargin");
    margin->add_theme_constant_override("margin_left", 22);
    margin->add_theme_constant_override("margin_top", 18);
    margin->add_theme_constant_override("margin_right", 22);
    margin->add_theme_constant_override("margin_bottom", 18);
    end_state_panel->add_child(margin);
    VBoxContainer* root = memnew(VBoxContainer); root->set_name("EndStateRoot"); root->add_theme_constant_override("separation", 10); margin->add_child(root);
    end_state_title_label = memnew(Label); end_state_title_label->set_name("EndStateTitle"); end_state_title_label->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER); root->add_child(end_state_title_label);
    end_state_subtitle_label = memnew(Label); end_state_subtitle_label->set_name("EndStateSubtitle"); end_state_subtitle_label->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER); end_state_subtitle_label->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); root->add_child(end_state_subtitle_label);
    end_state_rank_label = memnew(Label); end_state_rank_label->set_name("EndStateRank"); end_state_rank_label->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER); root->add_child(end_state_rank_label);
    end_state_stats_label = memnew(Label); end_state_stats_label->set_name("EndStateStats"); end_state_stats_label->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER); end_state_stats_label->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); root->add_child(end_state_stats_label);
    end_state_tip_label = memnew(Label); end_state_tip_label->set_name("EndStateTip"); end_state_tip_label->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER); end_state_tip_label->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART); root->add_child(end_state_tip_label);
    HBoxContainer* buttons = memnew(HBoxContainer); buttons->set_name("EndStateButtons"); buttons->set_alignment(BoxContainer::ALIGNMENT_CENTER); buttons->add_theme_constant_override("separation", 12); root->add_child(buttons);
    end_state_retry_button = memnew(Button); end_state_retry_button->set_name("EndStateRetryButton"); end_state_retry_button->set_custom_minimum_size(Vector2(156, 44)); end_state_retry_button->set_text("RETRY RUN"); end_state_retry_button->connect("pressed", Callable(this, "_on_end_retry_pressed")); buttons->add_child(end_state_retry_button);
    end_state_main_menu_button = memnew(Button); end_state_main_menu_button->set_name("EndStateMainMenuButton"); end_state_main_menu_button->set_custom_minimum_size(Vector2(156, 44)); end_state_main_menu_button->set_text("MAIN MENU"); end_state_main_menu_button->connect("pressed", Callable(this, "_on_end_main_menu_pressed")); buttons->add_child(end_state_main_menu_button);
}

void GameHudNative::update_tower_buttons(const Variant& button_states) {
    if (button_states.get_type() != Variant::DICTIONARY) return;
    Dictionary states = button_states;
    Array keys = tower_buttons.keys();
    for (int i = 0; i < keys.size(); ++i) {
        String tower_type = keys[i];
        Button* button = Object::cast_to<Button>(tower_buttons[tower_type]);
        if (button == nullptr) continue;
        Dictionary state = states.get(tower_type, Dictionary());
        button->set_text(String(state.get("text", button->get_text())));
        button->set_tooltip_text("");
        tower_info_states[tower_type] = state.get("info", Dictionary());
        button->set_disabled(bool(state.get("disabled", false)));
        button->set_pressed_no_signal(bool(state.get("pressed", false)));
        button->set_button_icon(Ref<Texture2D>(Object::cast_to<Texture2D>(state.get("icon", Variant()))));
        apply_tower_button_state(button, tower_type, button->is_pressed(), button->is_disabled());
        if (tower_info_card && tower_info_card->is_visible() && hovered_tower_type == tower_type) populate_tower_info_card(tower_type);
    }
}

void GameHudNative::update_tower_manage_card(const Variant& managed_state) {
    if (tower_manage_card == nullptr) return;
    if (managed_state.get_type() != Variant::DICTIONARY || Dictionary(managed_state).is_empty()) {
        managed_tower_ring = -1;
        managed_tower_slot = -1;
        tower_manage_card->set_visible(false);
        return;
    }
    Dictionary state = managed_state;
    managed_tower_ring = int(state.get("ring_index", -1));
    managed_tower_slot = int(state.get("slot_index", -1));
    tower_manage_title_label->set_text(String(state.get("title", "TOWER")).to_upper());
    tower_manage_meta_label->set_text(String(state.get("meta", "ORBITAL NODE")));
    tower_manage_stats_label->set_text(String(state.get("stats", "")));
    tower_manage_economy_label->set_text(String(state.get("economy", "")));
    tower_manage_upgrade_button->set_text(String(state.get("upgrade_text", "UPGRADE")));
    tower_manage_sell_button->set_text(String(state.get("sell_text", "SELL")));
    tower_manage_upgrade_button->set_disabled(bool(state.get("upgrade_disabled", false)));
    tower_manage_sell_button->set_disabled(bool(state.get("sell_disabled", false)));
    Color accent = color_from_variant(state.get("accent", gold()), gold());
    tower_manage_card->add_theme_stylebox_override("panel", hud_panel_style(accent, 14, 12));
    tower_manage_title_label->add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 1.0));
    apply_action_button(tower_manage_upgrade_button, tower_manage_upgrade_button->is_disabled() ? cyan() : gold(), "");
    apply_action_button(tower_manage_sell_button, cyan(), "");
    apply_action_button(tower_manage_close_button, cyan(), "");
    position_tower_manage_card();
    if (tower_info_card) tower_info_card->set_visible(false);
    tower_manage_card->set_visible(true);
}

void GameHudNative::update_end_state_card(const Variant& end_state) {
    if (end_state_panel == nullptr) return;
    if (end_state.get_type() != Variant::DICTIONARY || Dictionary(end_state).is_empty()) {
        end_state_panel->set_visible(false);
        return;
    }
    Dictionary state = end_state;
    bool victory = bool(state.get("victory", false));
    Color accent = victory ? gold() : Color(1.0, 0.28, 0.18, 0.92);
    end_state_panel->add_theme_stylebox_override("panel", hud_panel_style(accent, 16, 16));
    end_state_title_label->set_text(String(state.get("title", "MISSION COMPLETE")).to_upper());
    end_state_title_label->add_theme_color_override("font_color", accent);
    end_state_subtitle_label->set_text(String(state.get("subtitle", "")));
    end_state_rank_label->set_text(String(state.get("rank", "")));
    end_state_stats_label->set_text(String(state.get("stats", "")));
    end_state_tip_label->set_text(String(state.get("tip", "")));
    position_end_state_card();
    end_state_panel->set_visible(true);
    if (!end_state_retry_button->has_focus() && !end_state_main_menu_button->has_focus()) end_state_retry_button->grab_focus();
}

void GameHudNative::apply_styles() {
    if (Object* theme = space_theme()) {
        theme->call("apply_fonts", this);
        theme->call("apply_scroll_container", tower_scroll);
        if (luminosity_bar) {
            luminosity_bar->add_theme_stylebox_override("background", theme->call("progress_background_style"));
            luminosity_bar->add_theme_stylebox_override("fill", theme->call("progress_fill_style"));
        }
    }
    if (top_panel) top_panel->add_theme_stylebox_override("panel", hud_panel_style(cyan(), 15, 10));
    if (status_panel) status_panel->add_theme_stylebox_override("panel", hud_panel_style(cyan(), 13, 10));
    if (actions_panel) actions_panel->add_theme_stylebox_override("panel", hud_panel_style(gold(), 10, 12));
    if (wave_intel_panel) wave_intel_panel->add_theme_stylebox_override("panel", hud_panel_style(cyan(), 14, 12));
    if (tower_panel) tower_panel->add_theme_stylebox_override("panel", hud_panel_style(cyan(), 13, 10));
    if (message_panel) message_panel->add_theme_stylebox_override("panel", hud_panel_style(gold(), 13, 12));
    apply_readability_overrides();
    apply_action_button(start_button, gold(), icon_play());
    apply_action_button(auto_start_button, cyan(), icon_play());
    apply_action_button(menu_button, cyan(), "");
    apply_action_button(center_view_button, cyan(), "");
    if (start_button) start_button->add_theme_font_size_override("font_size", 13);
    if (auto_start_button) auto_start_button->add_theme_font_size_override("font_size", 9);
    if (menu_button) menu_button->add_theme_font_size_override("font_size", 12);
    if (center_view_button) center_view_button->add_theme_font_size_override("font_size", 10);
    Array keys = tower_buttons.keys();
    for (int i = 0; i < keys.size(); ++i) {
        String tower_type = keys[i];
        if (Button* button = Object::cast_to<Button>(tower_buttons[tower_type])) {
            apply_tower_button_state(button, tower_type, button->is_pressed(), button->is_disabled());
        }
    }
}

void GameHudNative::apply_readability_overrides() {
    if (wave_kicker) { wave_kicker->add_theme_font_size_override("font_size", 10); wave_kicker->add_theme_color_override("font_color", Color(0.34, 0.90, 1.0, 0.85)); }
    if (wave_label) { wave_label->add_theme_font_size_override("font_size", 21); wave_label->add_theme_color_override("font_color", Color(1.0, 0.82, 0.28, 1.0)); }
    if (brief_label) { brief_label->add_theme_font_size_override("font_size", 11); brief_label->add_theme_color_override("font_color", Color(0.78, 0.90, 0.98, 0.96)); }
    if (selected_tower_label) { selected_tower_label->add_theme_font_size_override("font_size", 10); selected_tower_label->add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 0.95)); }
    const char* stat_titles[] = {"Hud/StatusPanel/StatusRow/StatsGrid/SolStat/SolTitle", "Hud/StatusPanel/StatusRow/StatsGrid/ScoreStat/ScoreTitle", "Hud/StatusPanel/StatusRow/StatsGrid/KillsStat/KillsTitle", "Hud/StatusPanel/StatusRow/StatsGrid/FlareStat/FlareTitle"};
    for (const char* path : stat_titles) if (Label* title = node<Label>(path)) { title->add_theme_font_size_override("font_size", 10); title->add_theme_color_override("font_color", Color(0.52, 0.78, 0.90, 0.92)); }
    Label* values[] = {credits_label, score_label, kills_label, flare_label};
    for (Label* value : values) if (value) { value->add_theme_font_size_override("font_size", 18); value->add_theme_color_override("font_color", Color(0.96, 0.99, 1.0, 1.0)); }
    if (flare_label) flare_label->add_theme_font_size_override("font_size", 15);
    if (enemy_label) { enemy_label->add_theme_font_size_override("font_size", 13); enemy_label->add_theme_color_override("font_color", Color(0.96, 0.99, 1.0, 0.98)); enemy_label->add_theme_constant_override("line_spacing", 1); }
    if (intel_status_label) { intel_status_label->add_theme_font_size_override("font_size", 10); intel_status_label->add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 0.95)); }
    if (threat_label) { threat_label->add_theme_font_size_override("font_size", 10); threat_label->add_theme_color_override("font_color", Color(0.82, 0.90, 0.98, 0.94)); threat_label->add_theme_constant_override("line_spacing", 2); }
    if (ring_label) { ring_label->add_theme_font_size_override("font_size", 10); ring_label->add_theme_color_override("font_color", Color(0.58, 0.78, 0.92, 0.90)); ring_label->add_theme_constant_override("line_spacing", 1); }
    if (message_label) { message_label->add_theme_font_size_override("font_size", 13); message_label->add_theme_color_override("font_color", Color(0.98, 0.95, 0.84, 0.96)); }
    if (tower_info_card) {
        tower_info_card->add_theme_stylebox_override("panel", hud_panel_style(cyan(), 14, 12));
        tower_info_title_label->add_theme_font_size_override("font_size", 15);
        tower_info_title_label->add_theme_color_override("font_color", gold());
        tower_info_role_label->add_theme_font_size_override("font_size", 10);
        tower_info_role_label->add_theme_color_override("font_color", Color(0.42, 0.90, 1.0, 0.92));
        tower_info_stats_label->add_theme_font_size_override("font_size", 11);
        tower_info_body_label->add_theme_font_size_override("font_size", 12);
        tower_info_note_label->add_theme_font_size_override("font_size", 10);
    }
    if (tower_manage_card) {
        tower_manage_card->add_theme_stylebox_override("panel", hud_panel_style(gold(), 14, 12));
        tower_manage_title_label->add_theme_font_size_override("font_size", 15);
        tower_manage_meta_label->add_theme_font_size_override("font_size", 10);
        tower_manage_stats_label->add_theme_font_size_override("font_size", 11);
        tower_manage_economy_label->add_theme_font_size_override("font_size", 10);
        apply_action_button(tower_manage_upgrade_button, gold(), "");
        apply_action_button(tower_manage_sell_button, cyan(), "");
        apply_action_button(tower_manage_close_button, cyan(), "");
    }
    if (end_state_panel) {
        end_state_panel->add_theme_stylebox_override("panel", hud_panel_style(gold(), 16, 16));
        end_state_title_label->add_theme_font_size_override("font_size", 25);
        end_state_subtitle_label->add_theme_font_size_override("font_size", 14);
        end_state_rank_label->add_theme_font_size_override("font_size", 18);
        end_state_stats_label->add_theme_font_size_override("font_size", 14);
        end_state_tip_label->add_theme_font_size_override("font_size", 12);
        apply_action_button(end_state_retry_button, gold(), icon_play());
        apply_action_button(end_state_main_menu_button, cyan(), icon_back());
    }
}

void GameHudNative::show_tower_info(const String& tower_type) {
    if (tower_info_card == nullptr) return;
    hovered_tower_type = tower_type;
    populate_tower_info_card(tower_type);
    position_tower_info_card(tower_type);
    tower_info_card->set_visible(true);
}

void GameHudNative::hide_tower_info(const String& tower_type) {
    if (!tower_type.is_empty() && hovered_tower_type != tower_type) return;
    hovered_tower_type = "";
    if (tower_info_card) tower_info_card->set_visible(false);
}

void GameHudNative::populate_tower_info_card(const String& tower_type) {
    Dictionary info = tower_info_states.get(tower_type, Dictionary());
    Color accent = color_from_variant(info.get("accent", tower_accent(tower_type)), tower_accent(tower_type));
    tower_info_card->add_theme_stylebox_override("panel", hud_panel_style(accent, 14, 12));
    tower_info_title_label->add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 1.0));
    tower_info_title_label->set_text(String(info.get("title", tower_type.replace("_", " ").to_upper())));
    tower_info_role_label->set_text(String(info.get("role", "ORBITAL DEFENSE")));
    tower_info_stats_label->set_text(String(info.get("stats", "DAMAGE --  |  RATE --  |  RANGE --")));
    tower_info_body_label->set_text(String(info.get("body", "Select this tower to place it on an open orbital slot.")));
    tower_info_note_label->set_text(String(info.get("note", "Build before a wave begins.")));
    if (ColorRect* accent_bar = Object::cast_to<ColorRect>(tower_info_card->get_node_or_null(NodePath("TowerInfoMargin/TowerInfoRoot/TowerInfoAccent")))) {
        accent_bar->set_color(Color(accent.r, accent.g, accent.b, 0.92));
    }
}

void GameHudNative::fit_layout_to_viewport() {
    if (!top_panel || !status_panel || !wave_intel_panel || !get_viewport()) return;
    double viewport_width = get_viewport()->get_visible_rect().size.x;
    bool compact = viewport_width < 1500.0;
    if (compact) {
        top_panel->set_offset(SIDE_RIGHT, std::max(460.0, std::min(660.0, viewport_width - 436.0)));
        status_panel->set_offset(SIDE_LEFT, -1060.0);
        status_panel->set_offset(SIDE_RIGHT, -426.0);
        status_panel->set_offset(SIDE_TOP, 140.0);
        status_panel->set_offset(SIDE_BOTTOM, 246.0);
        wave_intel_panel->set_offset(SIDE_TOP, 264.0);
        wave_intel_panel->set_offset(SIDE_BOTTOM, 512.0);
    } else {
        top_panel->set_offset(SIDE_RIGHT, 820.0);
        status_panel->set_offset(SIDE_LEFT, -1060.0);
        status_panel->set_offset(SIDE_RIGHT, -426.0);
        status_panel->set_offset(SIDE_TOP, 18.0);
        status_panel->set_offset(SIDE_BOTTOM, 124.0);
        wave_intel_panel->set_offset(SIDE_TOP, 146.0);
        wave_intel_panel->set_offset(SIDE_BOTTOM, 394.0);
    }
    if (tower_info_card && tower_info_card->is_visible() && !hovered_tower_type.is_empty()) position_tower_info_card(hovered_tower_type);
    if (tower_manage_card && tower_manage_card->is_visible()) position_tower_manage_card();
    if (end_state_panel && end_state_panel->is_visible()) position_end_state_card();
}

void GameHudNative::position_tower_info_card(const String& tower_type) {
    if (!tower_info_card || !tower_panel || !hud_root || !get_viewport()) return;
    if (Object::cast_to<Button>(tower_buttons.get(tower_type, Variant())) == nullptr) return;
    tower_info_card->reset_size();
    Vector2 card_size = tower_info_card->get_combined_minimum_size().max(tower_info_card->get_custom_minimum_size());
    tower_info_card->set_size(card_size);
    Rect2 tower_rect = tower_panel->get_global_rect();
    Vector2 hud_origin = hud_root->get_global_rect().position;
    Vector2 viewport_size = get_viewport()->get_visible_rect().size;
    double x = tower_rect.position.x - hud_origin.x;
    double y = tower_rect.position.y - hud_origin.y - card_size.y - 14.0;
    if (y < 18.0) y = tower_rect.position.y - hud_origin.y + 14.0;
    tower_info_card->set_position(Vector2(Math::clamp(x, 22.0, std::max(22.0, double(viewport_size.x - card_size.x - 22.0))), Math::clamp(y, 18.0, std::max(18.0, double(viewport_size.y - card_size.y - 18.0)))));
}

void GameHudNative::position_tower_manage_card() {
    if (!tower_manage_card || !tower_panel || !hud_root || !get_viewport()) return;
    tower_manage_card->reset_size();
    Vector2 card_size = tower_manage_card->get_combined_minimum_size().max(tower_manage_card->get_custom_minimum_size());
    tower_manage_card->set_size(card_size);
    Rect2 tower_rect = tower_panel->get_global_rect();
    Vector2 hud_origin = hud_root->get_global_rect().position;
    Vector2 viewport_size = get_viewport()->get_visible_rect().size;
    double x = tower_rect.position.x - hud_origin.x;
    double y = tower_rect.position.y - hud_origin.y - card_size.y - 14.0;
    if (y < 18.0) y = tower_rect.position.y - hud_origin.y + 14.0;
    tower_manage_card->set_position(Vector2(Math::clamp(x, 22.0, std::max(22.0, double(viewport_size.x - card_size.x - 22.0))), Math::clamp(y, 18.0, std::max(18.0, double(viewport_size.y - card_size.y - 18.0)))));
}

void GameHudNative::position_end_state_card() {
    if (!end_state_panel || !get_viewport()) return;
    end_state_panel->reset_size();
    Vector2 card_size = end_state_panel->get_combined_minimum_size().max(end_state_panel->get_custom_minimum_size());
    end_state_panel->set_size(card_size);
    Vector2 viewport_size = get_viewport()->get_visible_rect().size;
    end_state_panel->set_position((viewport_size - card_size) * 0.5);
}

void GameHudNative::apply_action_button(Button* button, const Color& accent, const String& icon_path) {
    if (button == nullptr) return;
    if (Object* theme = space_theme()) {
        theme->call(accent == gold() ? "apply_primary_button" : "apply_secondary_button", button, icon_path);
    }
    button->add_theme_stylebox_override("normal", hud_button_style(button_bg(), accent, 1, 12, 8));
    button->add_theme_stylebox_override("hover", hud_button_style(button_hover(), Color(accent.r, accent.g, accent.b, 1.0), 2, 12, 8));
    button->add_theme_stylebox_override("pressed", hud_button_style(button_pressed(), gold(), 2, 12, 8));
    button->add_theme_stylebox_override("focus", hud_button_style(Color(0.015, 0.072, 0.092, 1.0), gold(), 2, 12, 8));
    button->add_theme_stylebox_override("disabled", hud_button_style(button_disabled(), Color(0.20, 0.28, 0.34, 0.70), 1, 12, 8));
    button->add_theme_color_override("font_color", Color(0.98, 1.0, 1.0, 1.0));
    button->add_theme_color_override("font_disabled_color", Color(0.46, 0.54, 0.62, 1.0));
    button->add_theme_constant_override("h_separation", 7);
    button->set_default_cursor_shape(Control::CURSOR_POINTING_HAND);
}

void GameHudNative::set_auto_start_button(bool enabled) {
    if (auto_start_button == nullptr) return;
    auto_start_button->set_pressed_no_signal(enabled);
    auto_start_button->set_text(enabled ? "AUTO\nARMED" : "AUTO\nSTART");
    auto_start_button->set_tooltip_text("Automatically starts ready waves after a short countdown.");
    apply_action_button(auto_start_button, enabled ? gold() : cyan(), icon_play());
    auto_start_button->add_theme_font_size_override("font_size", 9);
}

void GameHudNative::apply_tower_button_state(Button* button, const String& tower_type, bool selected, bool disabled) {
    if (button == nullptr) return;
    Color accent = tower_accent(tower_type);
    Color border = selected ? gold() : Color(accent.r, accent.g, accent.b, 0.78);
    Color bg = selected ? Color(0.046, 0.052, 0.042, 0.98) : button_bg();
    Color hover_bg = selected ? Color(0.060, 0.068, 0.052, 1.0) : button_hover();
    Color pressed_bg = selected ? Color(0.070, 0.076, 0.058, 1.0) : button_pressed();
    button->add_theme_font_size_override("font_size", 11);
    button->add_theme_stylebox_override("normal", hud_button_style(bg, border, 1, 10, 6));
    button->add_theme_stylebox_override("hover", hud_button_style(hover_bg, Color(border.r, border.g, border.b, 1.0), 2, 10, 6));
    button->add_theme_stylebox_override("pressed", hud_button_style(pressed_bg, gold(), 2, 10, 6));
    button->add_theme_stylebox_override("focus", hud_button_style(hover_bg, gold(), 2, 10, 6));
    button->add_theme_stylebox_override("disabled", hud_button_style(Color(0.008, 0.014, 0.022, 0.74), Color(0.18, 0.25, 0.32, 0.72), 1, 10, 6));
    button->add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0));
    button->add_theme_color_override("font_disabled_color", Color(0.42, 0.50, 0.58, 1.0));
    button->add_theme_constant_override("h_separation", 5);
    button->set_default_cursor_shape(disabled ? Control::CURSOR_ARROW : Control::CURSOR_POINTING_HAND);
}

Ref<StyleBoxFlat> GameHudNative::hud_panel_style(const Color& accent, double horizontal_margin, double vertical_margin) const {
    Ref<StyleBoxFlat> style;
    style.instantiate();
    style->set_bg_color(Color(0.006, 0.012, 0.024, 0.84));
    style->set_border_color(Color(accent.r, accent.g, accent.b, 0.72));
    style->set_border_width_all(1);
    style->set_corner_radius_all(8);
    style->set_content_margin(SIDE_LEFT, horizontal_margin);
    style->set_content_margin(SIDE_RIGHT, horizontal_margin);
    style->set_content_margin(SIDE_TOP, vertical_margin);
    style->set_content_margin(SIDE_BOTTOM, vertical_margin);
    style->set_shadow_color(Color(0, 0, 0, 0.48));
    style->set_shadow_size(8);
    style->set_shadow_offset(Vector2(0, 2));
    return style;
}

Ref<StyleBoxFlat> GameHudNative::hud_button_style(const Color& bg_color, const Color& border_color, int border_width, double horizontal_margin, double vertical_margin) const {
    Ref<StyleBoxFlat> style = hud_panel_style(border_color, horizontal_margin, vertical_margin);
    style->set_bg_color(bg_color);
    style->set_border_color(border_color);
    style->set_border_width_all(border_width);
    style->set_shadow_color(Color(0, 0, 0, 0.35));
    style->set_shadow_size(4);
    style->set_shadow_offset(Vector2(0, 1));
    return style;
}

Color GameHudNative::tower_accent(const String& tower_type) const {
    if (tower_type == "photon_splitter") return Color(1.0, 0.86, 0.28);
    if (tower_type == "cryo_probe") return Color(0.34, 0.86, 1.0);
    if (tower_type == "bio_lab") return Color(0.46, 1.0, 0.52);
    if (tower_type == "magnetic_net") return Color(0.76, 0.62, 1.0);
    if (tower_type == "helios_cannon") return Color(1.0, 0.43, 0.22);
    if (tower_type == "tardigrade_bomb") return Color(1.0, 0.58, 0.76);
    return cyan();
}

Object* GameHudNative::space_theme() const {
    static Ref<RefCounted> resource;
    if (resource.is_null()) {
        resource = Ref<RefCounted>(Object::cast_to<RefCounted>(ClassDB::instantiate("SpaceThemeNative")));
    }
    return resource.ptr();
}

void GameHudNative::on_start_button_pressed() { emit_signal("start_wave_requested"); }
void GameHudNative::on_auto_start_button_toggled(bool enabled) { emit_signal("auto_start_toggled", enabled); }
void GameHudNative::on_menu_button_pressed() { emit_signal("menu_requested"); }
void GameHudNative::on_tower_button_pressed(const String& tower_type) { emit_signal("tower_selected", tower_type); }
void GameHudNative::on_tower_manage_upgrade_pressed() { if (managed_tower_ring >= 0 && managed_tower_slot >= 0) emit_signal("tower_upgrade_requested", managed_tower_ring, managed_tower_slot); }
void GameHudNative::on_tower_manage_sell_pressed() { if (managed_tower_ring >= 0 && managed_tower_slot >= 0) emit_signal("tower_sell_requested", managed_tower_ring, managed_tower_slot); }
void GameHudNative::on_tower_manage_close_pressed() { emit_signal("tower_manage_closed"); }
void GameHudNative::on_center_view_button_pressed() { emit_signal("recenter_requested"); }
void GameHudNative::on_end_retry_pressed() { emit_signal("retry_requested"); }
void GameHudNative::on_end_main_menu_pressed() { emit_signal("main_menu_requested"); }
