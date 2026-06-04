#pragma once

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/config_file.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

class GameStateNative : public Node {
    GDCLASS(GameStateNative, Node)

protected:
    static void _bind_methods();

public:
    enum Phase {
        MENU = 0,
        BETWEEN_WAVE = 1,
        WAVE_ACTIVE = 2,
        PAUSED = 3,
        GAME_OVER = 4,
        VICTORY = 5,
    };

    void _ready() override;

    void reset_state();
    void load_audio_settings();
    void save_audio_settings();
    void ensure_music_audible();
    void set_music_enabled(bool enabled);
    void set_music_volume(double volume);
    double get_music_volume_db() const;
    void set_tutorial_completed(bool completed = true);
    void set_screen_shake_enabled(bool enabled);
    void set_auto_start_waves_enabled(bool enabled);
    void damage_sun(double amount);
    int get_luminosity_percent() const;
    void add_credits(int amount);
    bool spend_credits(int amount);
    bool can_afford(int amount) const;
    int get_tower_cost(const String& tower_type) const;
    int get_upgrade_cost(const String& tower_type) const;
    void add_score(int amount);
    void on_enemy_killed(int variant_id);
    void on_wave_cleared();
    bool try_trigger_flare();
    void add_burrower();
    void remove_burrower();
    void set_phase(int new_phase);
    String get_rank() const;
    void trigger_victory();

    Dictionary get_phase() const;
    int get_menu_phase() const;
    int get_between_wave_phase() const;
    int get_wave_active_phase() const;
    int get_paused_phase() const;
    int get_game_over_phase() const;
    int get_victory_phase() const;

    double get_luminosity() const;
    void set_luminosity(double value);
    int get_sol_credits() const;
    void set_sol_credits(int value);
    int get_current_wave() const;
    void set_current_wave(int value);
    int get_flare_charge() const;
    void set_flare_charge(int value);
    int get_waves_since_last_flare() const;
    void set_waves_since_last_flare(int value);
    int get_performance_score() const;
    void set_performance_score(int value);
    int get_enemies_killed_total() const;
    void set_enemies_killed_total(int value);
    int get_waves_cleared() const;
    void set_waves_cleared(int value);
    int get_burrowers_active() const;
    void set_burrowers_active(int value);
    bool get_music_enabled() const;
    double get_music_volume() const;
    bool get_tutorial_completed() const;
    bool get_screen_shake_enabled() const;
    bool get_auto_start_waves_enabled() const;
    bool get_music_changed_by_user_this_session() const;
    int get_game_phase() const;
    void set_game_phase(int value);

private:
    static constexpr const char* SETTINGS_PATH = "user://settings.cfg";
    static constexpr double DEFAULT_MUSIC_VOLUME = 0.72;
    static constexpr double MIN_AUDIBLE_MUSIC_VOLUME = 0.08;

    double luminosity = 1.0;
    int sol_credits = 60;
    int current_wave = 0;
    int flare_charge = 0;
    int waves_since_last_flare = 0;
    int performance_score = 0;
    int enemies_killed_total = 0;
    int waves_cleared = 0;
    int burrowers_active = 0;
    bool music_enabled = true;
    double music_volume = 0.72;
    bool tutorial_completed = false;
    bool screen_shake_enabled = true;
    bool auto_start_waves_enabled = false;
    bool music_changed_by_user_this_session = false;
    int game_phase = MENU;

    Ref<ConfigFile> settings_config() const;
    void trigger_game_over();
    Dictionary tower_costs() const;
    Dictionary tower_upgrade_costs() const;
};

}

VARIANT_ENUM_CAST(godot::GameStateNative::Phase);
