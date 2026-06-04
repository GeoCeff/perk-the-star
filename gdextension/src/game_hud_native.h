#pragma once

#include <godot_cpp/classes/canvas_layer.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/progress_bar.hpp>
#include <godot_cpp/classes/scroll_container.hpp>
#include <godot_cpp/classes/texture_rect.hpp>
#include <godot_cpp/classes/style_box_flat.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

class ColorRect;
class Control;

class GameHudNative : public CanvasLayer {
    GDCLASS(GameHudNative, CanvasLayer)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void update_view(const Dictionary& state);
    bool is_screen_position_over_hud(const Vector2& screen_position) const;
    Dictionary get_tutorial_targets() const;

private:
    Label* wave_kicker = nullptr;
    Label* wave_label = nullptr;
    Label* brief_label = nullptr;
    Label* credits_label = nullptr;
    Label* score_label = nullptr;
    Label* kills_label = nullptr;
    Label* flare_label = nullptr;
    Label* selected_tower_label = nullptr;
    Label* intel_status_label = nullptr;
    Label* enemy_label = nullptr;
    Label* threat_label = nullptr;
    Label* ring_label = nullptr;
    Label* message_label = nullptr;
    ProgressBar* luminosity_bar = nullptr;
    Button* start_button = nullptr;
    Button* auto_start_button = nullptr;
    Button* menu_button = nullptr;
    PanelContainer* top_panel = nullptr;
    PanelContainer* status_panel = nullptr;
    PanelContainer* actions_panel = nullptr;
    PanelContainer* wave_intel_panel = nullptr;
    PanelContainer* tower_panel = nullptr;
    Control* hud_root = nullptr;
    ScrollContainer* tower_scroll = nullptr;
    Button* center_view_button = nullptr;
    PanelContainer* message_panel = nullptr;
    TextureRect* enemy_preview = nullptr;
    Dictionary tower_buttons;
    Dictionary tower_info_states;
    String hovered_tower_type;
    PanelContainer* tower_info_card = nullptr;
    Label* tower_info_title_label = nullptr;
    Label* tower_info_role_label = nullptr;
    Label* tower_info_stats_label = nullptr;
    Label* tower_info_body_label = nullptr;
    Label* tower_info_note_label = nullptr;
    PanelContainer* tower_manage_card = nullptr;
    Label* tower_manage_title_label = nullptr;
    Label* tower_manage_meta_label = nullptr;
    Label* tower_manage_stats_label = nullptr;
    Label* tower_manage_economy_label = nullptr;
    Button* tower_manage_upgrade_button = nullptr;
    Button* tower_manage_sell_button = nullptr;
    Button* tower_manage_close_button = nullptr;
    int managed_tower_ring = -1;
    int managed_tower_slot = -1;
    PanelContainer* end_state_panel = nullptr;
    Label* end_state_title_label = nullptr;
    Label* end_state_subtitle_label = nullptr;
    Label* end_state_rank_label = nullptr;
    Label* end_state_stats_label = nullptr;
    Label* end_state_tip_label = nullptr;
    Button* end_state_retry_button = nullptr;
    Button* end_state_main_menu_button = nullptr;

    template <class T>
    T* node(const char* path) const { return Object::cast_to<T>(get_node_or_null(NodePath(path))); }

    void bind_nodes();
    void bind_buttons();
    void build_tower_info_card();
    void build_tower_manage_card();
    void build_end_state_card();
    void apply_styles();
    void apply_readability_overrides();
    void update_tower_buttons(const Variant& button_states);
    void update_tower_manage_card(const Variant& managed_state);
    void update_end_state_card(const Variant& end_state);
    void set_auto_start_button(bool enabled);
    void show_tower_info(const String& tower_type);
    void hide_tower_info(const String& tower_type = "");
    void populate_tower_info_card(const String& tower_type);
    void fit_layout_to_viewport();
    void position_tower_info_card(const String& tower_type);
    void position_tower_manage_card();
    void position_end_state_card();
    void apply_action_button(Button* button, const Color& accent, const String& icon_path = "");
    void apply_tower_button_state(Button* button, const String& tower_type, bool selected, bool disabled);
    Ref<StyleBoxFlat> hud_panel_style(const Color& accent, double horizontal_margin, double vertical_margin) const;
    Ref<StyleBoxFlat> hud_button_style(
        const Color& bg_color,
        const Color& border_color,
        int border_width,
        double horizontal_margin = 12.0,
        double vertical_margin = 7.0) const;
    Dictionary control_target(Control* control) const;
    Color tower_accent(const String& tower_type) const;
    Object* space_theme() const;

    void on_start_button_pressed();
    void on_auto_start_button_toggled(bool enabled);
    void on_menu_button_pressed();
    void on_tower_button_pressed(const String& tower_type);
    void on_tower_manage_upgrade_pressed();
    void on_tower_manage_sell_pressed();
    void on_tower_manage_close_pressed();
    void on_center_view_button_pressed();
    void on_end_retry_pressed();
    void on_end_main_menu_pressed();
    void on_ui_hovered();
};

}
