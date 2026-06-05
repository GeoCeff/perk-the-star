#include "game_state_native.h"

#include <godot_cpp/classes/config_file.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void GameStateNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("reset_state"), &GameStateNative::reset_state);
    ClassDB::bind_method(D_METHOD("load_audio_settings"), &GameStateNative::load_audio_settings);
    ClassDB::bind_method(D_METHOD("save_audio_settings"), &GameStateNative::save_audio_settings);
    ClassDB::bind_method(D_METHOD("ensure_music_audible"), &GameStateNative::ensure_music_audible);
    ClassDB::bind_method(D_METHOD("set_music_enabled", "enabled"), &GameStateNative::set_music_enabled);
    ClassDB::bind_method(D_METHOD("set_music_volume", "volume"), &GameStateNative::set_music_volume);
    ClassDB::bind_method(D_METHOD("get_music_volume_db"), &GameStateNative::get_music_volume_db);
    ClassDB::bind_method(D_METHOD("set_tutorial_completed", "completed"), &GameStateNative::set_tutorial_completed, DEFVAL(true));
    ClassDB::bind_method(D_METHOD("set_screen_shake_enabled", "enabled"), &GameStateNative::set_screen_shake_enabled);
    ClassDB::bind_method(D_METHOD("set_auto_start_waves_enabled", "enabled"), &GameStateNative::set_auto_start_waves_enabled);
    ClassDB::bind_method(D_METHOD("enable_test_run", "start_wave"), &GameStateNative::enable_test_run);
    ClassDB::bind_method(D_METHOD("clear_test_run"), &GameStateNative::clear_test_run);
    ClassDB::bind_method(D_METHOD("consume_test_start_wave"), &GameStateNative::consume_test_start_wave);
    ClassDB::bind_method(D_METHOD("damage_sun", "amount"), &GameStateNative::damage_sun);
    ClassDB::bind_method(D_METHOD("get_luminosity_percent"), &GameStateNative::get_luminosity_percent);
    ClassDB::bind_method(D_METHOD("add_credits", "amount"), &GameStateNative::add_credits);
    ClassDB::bind_method(D_METHOD("spend_credits", "amount"), &GameStateNative::spend_credits);
    ClassDB::bind_method(D_METHOD("can_afford", "amount"), &GameStateNative::can_afford);
    ClassDB::bind_method(D_METHOD("get_tower_cost", "tower_type"), &GameStateNative::get_tower_cost);
    ClassDB::bind_method(D_METHOD("get_upgrade_cost", "tower_type"), &GameStateNative::get_upgrade_cost);
    ClassDB::bind_method(D_METHOD("add_score", "amount"), &GameStateNative::add_score);
    ClassDB::bind_method(D_METHOD("on_enemy_killed", "variant_id"), &GameStateNative::on_enemy_killed);
    ClassDB::bind_method(D_METHOD("on_wave_cleared"), &GameStateNative::on_wave_cleared);
    ClassDB::bind_method(D_METHOD("try_trigger_flare"), &GameStateNative::try_trigger_flare);
    ClassDB::bind_method(D_METHOD("add_burrower"), &GameStateNative::add_burrower);
    ClassDB::bind_method(D_METHOD("remove_burrower"), &GameStateNative::remove_burrower);
    ClassDB::bind_method(D_METHOD("set_phase", "new_phase"), &GameStateNative::set_phase);
    ClassDB::bind_method(D_METHOD("get_rank"), &GameStateNative::get_rank);
    ClassDB::bind_method(D_METHOD("trigger_victory"), &GameStateNative::trigger_victory);
    ClassDB::bind_method(D_METHOD("get_phase"), &GameStateNative::get_phase);
    ClassDB::bind_method(D_METHOD("get_menu_phase"), &GameStateNative::get_menu_phase);
    ClassDB::bind_method(D_METHOD("get_between_wave_phase"), &GameStateNative::get_between_wave_phase);
    ClassDB::bind_method(D_METHOD("get_wave_active_phase"), &GameStateNative::get_wave_active_phase);
    ClassDB::bind_method(D_METHOD("get_paused_phase"), &GameStateNative::get_paused_phase);
    ClassDB::bind_method(D_METHOD("get_game_over_phase"), &GameStateNative::get_game_over_phase);
    ClassDB::bind_method(D_METHOD("get_victory_phase"), &GameStateNative::get_victory_phase);

    ClassDB::bind_method(D_METHOD("set_luminosity", "value"), &GameStateNative::set_luminosity);
    ClassDB::bind_method(D_METHOD("get_luminosity"), &GameStateNative::get_luminosity);
    ClassDB::bind_method(D_METHOD("set_sol_credits", "value"), &GameStateNative::set_sol_credits);
    ClassDB::bind_method(D_METHOD("get_sol_credits"), &GameStateNative::get_sol_credits);
    ClassDB::bind_method(D_METHOD("set_current_wave", "value"), &GameStateNative::set_current_wave);
    ClassDB::bind_method(D_METHOD("get_current_wave"), &GameStateNative::get_current_wave);
    ClassDB::bind_method(D_METHOD("set_flare_charge", "value"), &GameStateNative::set_flare_charge);
    ClassDB::bind_method(D_METHOD("get_flare_charge"), &GameStateNative::get_flare_charge);
    ClassDB::bind_method(D_METHOD("set_waves_since_last_flare", "value"), &GameStateNative::set_waves_since_last_flare);
    ClassDB::bind_method(D_METHOD("get_waves_since_last_flare"), &GameStateNative::get_waves_since_last_flare);
    ClassDB::bind_method(D_METHOD("set_performance_score", "value"), &GameStateNative::set_performance_score);
    ClassDB::bind_method(D_METHOD("get_performance_score"), &GameStateNative::get_performance_score);
    ClassDB::bind_method(D_METHOD("set_enemies_killed_total", "value"), &GameStateNative::set_enemies_killed_total);
    ClassDB::bind_method(D_METHOD("get_enemies_killed_total"), &GameStateNative::get_enemies_killed_total);
    ClassDB::bind_method(D_METHOD("set_waves_cleared", "value"), &GameStateNative::set_waves_cleared);
    ClassDB::bind_method(D_METHOD("get_waves_cleared"), &GameStateNative::get_waves_cleared);
    ClassDB::bind_method(D_METHOD("set_burrowers_active", "value"), &GameStateNative::set_burrowers_active);
    ClassDB::bind_method(D_METHOD("get_burrowers_active"), &GameStateNative::get_burrowers_active);
    ClassDB::bind_method(D_METHOD("get_music_enabled"), &GameStateNative::get_music_enabled);
    ClassDB::bind_method(D_METHOD("get_music_volume"), &GameStateNative::get_music_volume);
    ClassDB::bind_method(D_METHOD("get_tutorial_completed"), &GameStateNative::get_tutorial_completed);
    ClassDB::bind_method(D_METHOD("get_screen_shake_enabled"), &GameStateNative::get_screen_shake_enabled);
    ClassDB::bind_method(D_METHOD("get_auto_start_waves_enabled"), &GameStateNative::get_auto_start_waves_enabled);
    ClassDB::bind_method(D_METHOD("get_test_unlimited_sol_enabled"), &GameStateNative::get_test_unlimited_sol_enabled);
    ClassDB::bind_method(D_METHOD("get_music_changed_by_user_this_session"), &GameStateNative::get_music_changed_by_user_this_session);
    ClassDB::bind_method(D_METHOD("set_game_phase", "value"), &GameStateNative::set_game_phase);
    ClassDB::bind_method(D_METHOD("get_game_phase"), &GameStateNative::get_game_phase);

    ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "Phase"), "", "get_phase");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "MENU"), "", "get_menu_phase");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "BETWEEN_WAVE"), "", "get_between_wave_phase");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "WAVE_ACTIVE"), "", "get_wave_active_phase");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "PAUSED"), "", "get_paused_phase");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "GAME_OVER"), "", "get_game_over_phase");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "VICTORY"), "", "get_victory_phase");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "luminosity"), "set_luminosity", "get_luminosity");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "sol_credits"), "set_sol_credits", "get_sol_credits");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "current_wave"), "set_current_wave", "get_current_wave");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "flare_charge"), "set_flare_charge", "get_flare_charge");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "waves_since_last_flare"), "set_waves_since_last_flare", "get_waves_since_last_flare");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "performance_score"), "set_performance_score", "get_performance_score");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "enemies_killed_total"), "set_enemies_killed_total", "get_enemies_killed_total");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "waves_cleared"), "set_waves_cleared", "get_waves_cleared");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "burrowers_active"), "set_burrowers_active", "get_burrowers_active");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "music_enabled"), "", "get_music_enabled");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "music_volume"), "", "get_music_volume");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "tutorial_completed"), "", "get_tutorial_completed");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "screen_shake_enabled"), "", "get_screen_shake_enabled");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "auto_start_waves_enabled"), "", "get_auto_start_waves_enabled");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "test_unlimited_sol_enabled"), "", "get_test_unlimited_sol_enabled");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "music_changed_by_user_this_session"), "", "get_music_changed_by_user_this_session");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "game_phase"), "set_game_phase", "get_game_phase");

    ADD_SIGNAL(MethodInfo("luminosity_changed", PropertyInfo(Variant::FLOAT, "new_value")));
    ADD_SIGNAL(MethodInfo("credits_changed", PropertyInfo(Variant::INT, "new_value")));
    ADD_SIGNAL(MethodInfo("score_changed", PropertyInfo(Variant::INT, "new_value")));
    ADD_SIGNAL(MethodInfo("flare_charged"));
    ADD_SIGNAL(MethodInfo("flare_used"));
    ADD_SIGNAL(MethodInfo("game_over_triggered", PropertyInfo(Variant::FLOAT, "final_luminosity"), PropertyInfo(Variant::INT, "killing_wave")));
    ADD_SIGNAL(MethodInfo("victory_triggered", PropertyInfo(Variant::FLOAT, "final_luminosity"), PropertyInfo(Variant::STRING, "rank")));
    ADD_SIGNAL(MethodInfo("burrower_count_changed", PropertyInfo(Variant::INT, "count")));
    ADD_SIGNAL(MethodInfo("phase_changed", PropertyInfo(Variant::INT, "new_phase")));
    ADD_SIGNAL(MethodInfo("music_settings_changed", PropertyInfo(Variant::BOOL, "enabled"), PropertyInfo(Variant::FLOAT, "volume")));
    ADD_SIGNAL(MethodInfo("tutorial_settings_changed", PropertyInfo(Variant::BOOL, "completed")));
    ADD_SIGNAL(MethodInfo("game_feel_settings_changed", PropertyInfo(Variant::BOOL, "screen_shake_enabled")));
    ADD_SIGNAL(MethodInfo("auto_start_settings_changed", PropertyInfo(Variant::BOOL, "enabled")));

    BIND_ENUM_CONSTANT(MENU);
    BIND_ENUM_CONSTANT(BETWEEN_WAVE);
    BIND_ENUM_CONSTANT(WAVE_ACTIVE);
    BIND_ENUM_CONSTANT(PAUSED);
    BIND_ENUM_CONSTANT(GAME_OVER);
    BIND_ENUM_CONSTANT(VICTORY);
}

void GameStateNative::_ready() {
    reset_state();
    load_audio_settings();
}

void GameStateNative::reset_state() {
    luminosity = 1.0;
    sol_credits = test_unlimited_sol_enabled ? 999999 : 60;
    current_wave = 0;
    flare_charge = 0;
    waves_since_last_flare = 0;
    performance_score = 0;
    enemies_killed_total = 0;
    waves_cleared = 0;
    burrowers_active = 0;
    game_phase = MENU;
}

void GameStateNative::load_audio_settings() {
    Ref<ConfigFile> config;
    config.instantiate();
    const Error error = config->load(SETTINGS_PATH);
    if (error == OK) {
        music_enabled = bool(config->get_value("audio", "music_enabled", music_enabled));
        music_volume = Math::clamp(double(config->get_value("audio", "music_volume", music_volume)), 0.0, 1.0);
        tutorial_completed = bool(config->get_value("tutorial", "completed", tutorial_completed));
        screen_shake_enabled = bool(config->get_value("gameplay", "screen_shake_enabled", screen_shake_enabled));
        auto_start_waves_enabled = bool(config->get_value("gameplay", "auto_start_waves_enabled", auto_start_waves_enabled));
    }
    emit_signal("music_settings_changed", music_enabled, music_volume);
    emit_signal("tutorial_settings_changed", tutorial_completed);
    emit_signal("game_feel_settings_changed", screen_shake_enabled);
    emit_signal("auto_start_settings_changed", auto_start_waves_enabled);
}

void GameStateNative::save_audio_settings() {
    Ref<ConfigFile> config = settings_config();
    config->set_value("audio", "music_enabled", music_enabled);
    config->set_value("audio", "music_volume", music_volume);
    config->save(SETTINGS_PATH);
}

void GameStateNative::ensure_music_audible() {
    if (music_changed_by_user_this_session) {
        return;
    }
    if (music_enabled && music_volume >= MIN_AUDIBLE_MUSIC_VOLUME) {
        return;
    }
    music_enabled = true;
    music_volume = MAX(music_volume, DEFAULT_MUSIC_VOLUME);
    save_audio_settings();
    emit_signal("music_settings_changed", music_enabled, music_volume);
}

void GameStateNative::set_music_enabled(bool enabled) {
    music_changed_by_user_this_session = true;
    music_enabled = enabled;
    save_audio_settings();
    emit_signal("music_settings_changed", music_enabled, music_volume);
}

void GameStateNative::set_music_volume(double volume) {
    music_changed_by_user_this_session = true;
    music_volume = Math::clamp(volume, 0.0, 1.0);
    save_audio_settings();
    emit_signal("music_settings_changed", music_enabled, music_volume);
}

double GameStateNative::get_music_volume_db() const {
    if (!music_enabled || music_volume <= 0.0) {
        return -80.0;
    }
    return UtilityFunctions::linear_to_db(music_volume);
}

void GameStateNative::set_tutorial_completed(bool completed) {
    tutorial_completed = completed;
    Ref<ConfigFile> config = settings_config();
    config->set_value("tutorial", "completed", tutorial_completed);
    config->save(SETTINGS_PATH);
    emit_signal("tutorial_settings_changed", tutorial_completed);
}

void GameStateNative::set_screen_shake_enabled(bool enabled) {
    screen_shake_enabled = enabled;
    Ref<ConfigFile> config = settings_config();
    config->set_value("gameplay", "screen_shake_enabled", screen_shake_enabled);
    config->save(SETTINGS_PATH);
    emit_signal("game_feel_settings_changed", screen_shake_enabled);
}

void GameStateNative::set_auto_start_waves_enabled(bool enabled) {
    auto_start_waves_enabled = enabled;
    Ref<ConfigFile> config = settings_config();
    config->set_value("gameplay", "auto_start_waves_enabled", auto_start_waves_enabled);
    config->save(SETTINGS_PATH);
    emit_signal("auto_start_settings_changed", auto_start_waves_enabled);
}

void GameStateNative::enable_test_run(int start_wave) {
    test_unlimited_sol_enabled = true;
    pending_test_start_wave = Math::clamp(start_wave, 1, 12);
}

void GameStateNative::clear_test_run() {
    test_unlimited_sol_enabled = false;
    pending_test_start_wave = 0;
}

int GameStateNative::consume_test_start_wave() {
    const int start_wave = pending_test_start_wave;
    pending_test_start_wave = 0;
    return start_wave;
}

void GameStateNative::damage_sun(double amount) {
    if (game_phase == GAME_OVER) {
        return;
    }
    luminosity = Math::clamp(luminosity - amount, 0.0, 1.0);
    emit_signal("luminosity_changed", luminosity);
    if (luminosity <= 0.0) {
        trigger_game_over();
    }
}

int GameStateNative::get_luminosity_percent() const {
    return int(luminosity * 100.0);
}

void GameStateNative::add_credits(int amount) {
    sol_credits += amount;
    emit_signal("credits_changed", sol_credits);
}

bool GameStateNative::spend_credits(int amount) {
    if (test_unlimited_sol_enabled) {
        emit_signal("credits_changed", sol_credits);
        return true;
    }
    if (sol_credits < amount) {
        return false;
    }
    sol_credits -= amount;
    emit_signal("credits_changed", sol_credits);
    return true;
}

bool GameStateNative::can_afford(int amount) const {
    if (test_unlimited_sol_enabled) {
        return true;
    }
    return sol_credits >= amount;
}

int GameStateNative::get_tower_cost(const String& tower_type) const {
    return int(tower_costs().get(tower_type, 30));
}

int GameStateNative::get_upgrade_cost(const String& tower_type) const {
    return int(tower_upgrade_costs().get(tower_type, 50));
}

void GameStateNative::add_score(int amount) {
    performance_score += amount;
    emit_signal("score_changed", performance_score);
}

void GameStateNative::on_enemy_killed(int variant_id) {
    enemies_killed_total += 1;
    const int values[] = {10, 20, 40, 30, 25, 200};
    const int index = Math::clamp(variant_id, 0, 5);
    add_score(values[index]);
}

void GameStateNative::on_wave_cleared() {
    waves_cleared += 1;
    waves_since_last_flare += 1;
    if (waves_since_last_flare >= 3 && flare_charge == 0) {
        flare_charge = 1;
        waves_since_last_flare = 0;
        emit_signal("flare_charged");
    }
}

bool GameStateNative::try_trigger_flare() {
    if (test_unlimited_sol_enabled) {
        emit_signal("flare_used");
        return true;
    }
    if (flare_charge <= 0) {
        return false;
    }
    flare_charge -= 1;
    emit_signal("flare_used");
    return true;
}

void GameStateNative::add_burrower() {
    burrowers_active += 1;
    emit_signal("burrower_count_changed", burrowers_active);
}

void GameStateNative::remove_burrower() {
    burrowers_active = MAX(0, burrowers_active - 1);
    emit_signal("burrower_count_changed", burrowers_active);
}

void GameStateNative::set_phase(int new_phase) {
    game_phase = new_phase;
    emit_signal("phase_changed", game_phase);
}

String GameStateNative::get_rank() const {
    if (luminosity > 0.8) return "FULL SHINE";
    if (luminosity > 0.6) return "BRIGHT";
    if (luminosity > 0.2) return "DIM BUT ALIVE";
    return "LAST LIGHT";
}

void GameStateNative::trigger_victory() {
    game_phase = VICTORY;
    emit_signal("victory_triggered", luminosity, get_rank());
}

Dictionary GameStateNative::get_phase() const {
    Dictionary phase;
    phase["MENU"] = MENU;
    phase["BETWEEN_WAVE"] = BETWEEN_WAVE;
    phase["WAVE_ACTIVE"] = WAVE_ACTIVE;
    phase["PAUSED"] = PAUSED;
    phase["GAME_OVER"] = GAME_OVER;
    phase["VICTORY"] = VICTORY;
    return phase;
}

int GameStateNative::get_menu_phase() const { return MENU; }
int GameStateNative::get_between_wave_phase() const { return BETWEEN_WAVE; }
int GameStateNative::get_wave_active_phase() const { return WAVE_ACTIVE; }
int GameStateNative::get_paused_phase() const { return PAUSED; }
int GameStateNative::get_game_over_phase() const { return GAME_OVER; }
int GameStateNative::get_victory_phase() const { return VICTORY; }

double GameStateNative::get_luminosity() const { return luminosity; }
void GameStateNative::set_luminosity(double value) { luminosity = value; }
int GameStateNative::get_sol_credits() const { return sol_credits; }
void GameStateNative::set_sol_credits(int value) { sol_credits = value; }
int GameStateNative::get_current_wave() const { return current_wave; }
void GameStateNative::set_current_wave(int value) { current_wave = value; }
int GameStateNative::get_flare_charge() const { return test_unlimited_sol_enabled ? 1 : flare_charge; }
void GameStateNative::set_flare_charge(int value) { flare_charge = value; }
int GameStateNative::get_waves_since_last_flare() const { return waves_since_last_flare; }
void GameStateNative::set_waves_since_last_flare(int value) { waves_since_last_flare = value; }
int GameStateNative::get_performance_score() const { return performance_score; }
void GameStateNative::set_performance_score(int value) { performance_score = value; }
int GameStateNative::get_enemies_killed_total() const { return enemies_killed_total; }
void GameStateNative::set_enemies_killed_total(int value) { enemies_killed_total = value; }
int GameStateNative::get_waves_cleared() const { return waves_cleared; }
void GameStateNative::set_waves_cleared(int value) { waves_cleared = value; }
int GameStateNative::get_burrowers_active() const { return burrowers_active; }
void GameStateNative::set_burrowers_active(int value) { burrowers_active = value; }
bool GameStateNative::get_music_enabled() const { return music_enabled; }
double GameStateNative::get_music_volume() const { return music_volume; }
bool GameStateNative::get_tutorial_completed() const { return tutorial_completed; }
bool GameStateNative::get_screen_shake_enabled() const { return screen_shake_enabled; }
bool GameStateNative::get_auto_start_waves_enabled() const { return auto_start_waves_enabled; }
bool GameStateNative::get_test_unlimited_sol_enabled() const { return test_unlimited_sol_enabled; }
bool GameStateNative::get_music_changed_by_user_this_session() const { return music_changed_by_user_this_session; }
int GameStateNative::get_game_phase() const { return game_phase; }
void GameStateNative::set_game_phase(int value) { game_phase = value; }

Ref<ConfigFile> GameStateNative::settings_config() const {
    Ref<ConfigFile> config;
    config.instantiate();
    config->load(SETTINGS_PATH);
    return config;
}

void GameStateNative::trigger_game_over() {
    game_phase = GAME_OVER;
    emit_signal("game_over_triggered", luminosity, current_wave);
}

Dictionary GameStateNative::tower_costs() const {
    Dictionary costs;
    costs["photon_splitter"] = 25;
    costs["cryo_probe"] = 32;
    costs["bio_lab"] = 48;
    costs["magnetic_net"] = 44;
    costs["helios_cannon"] = 78;
    costs["tardigrade_bomb"] = 68;
    return costs;
}

Dictionary GameStateNative::tower_upgrade_costs() const {
    Dictionary costs;
    costs["photon_splitter"] = 35;
    costs["cryo_probe"] = 42;
    costs["bio_lab"] = 65;
    costs["magnetic_net"] = 58;
    costs["helios_cannon"] = 105;
    costs["tardigrade_bomb"] = 92;
    return costs;
}
