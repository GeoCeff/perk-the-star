#include "game_runtime_native.h"

#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void GameRuntimeNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("ease_out_cubic", "value"), &GameRuntimeNative::ease_out_cubic);
    ClassDB::bind_method(D_METHOD("ease_in_out_sine", "value"), &GameRuntimeNative::ease_in_out_sine);
    ClassDB::bind_method(D_METHOD("sun_pos", "viewport_size"), &GameRuntimeNative::sun_pos);
    ClassDB::bind_method(D_METHOD("screen_shake_offset", "timer", "enabled", "strength"), &GameRuntimeNative::screen_shake_offset);
    ClassDB::bind_method(D_METHOD("can_build_towers", "phase", "between_wave", "wave_active"), &GameRuntimeNative::can_build_towers);
    ClassDB::bind_method(D_METHOD("bgm_path_for_wave", "wave_number", "early", "mid", "late", "boss"), &GameRuntimeNative::bgm_path_for_wave);
}

double GameRuntimeNative::ease_out_cubic(double value) const {
    const double t = Math::clamp(value, 0.0, 1.0);
    return 1.0 - Math::pow(1.0 - t, 3.0);
}

double GameRuntimeNative::ease_in_out_sine(double value) const {
    const double t = Math::clamp(value, 0.0, 1.0);
    return 0.5 - Math::cos(t * Math_PI) * 0.5;
}

Vector2 GameRuntimeNative::sun_pos(const Vector2& viewport_size) const {
    return viewport_size * 0.5;
}

Vector2 GameRuntimeNative::screen_shake_offset(double timer, bool enabled, double strength) const {
    if (timer <= 0.0 || !enabled) {
        return Vector2();
    }
    const double fade = Math::clamp(timer / 0.34, 0.0, 1.0);
    const double time_seconds = double(Time::get_singleton()->get_ticks_msec()) / 1000.0;
    return Vector2(Math::sin(time_seconds * 73.0), Math::cos(time_seconds * 61.0)) * strength * fade;
}

bool GameRuntimeNative::can_build_towers(int phase, int between_wave, int wave_active) const {
    return phase == between_wave || phase == wave_active;
}

String GameRuntimeNative::bgm_path_for_wave(int wave_number, const String& early, const String& mid, const String& late, const String& boss) const {
    if (wave_number >= 12) return boss;
    if (wave_number >= 9) return late;
    if (wave_number >= 5) return mid;
    return early;
}
