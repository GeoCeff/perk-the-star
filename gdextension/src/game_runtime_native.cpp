#include "game_runtime_native.h"

#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <limits>

using namespace godot;

void GameRuntimeNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("ease_out_cubic", "value"), &GameRuntimeNative::ease_out_cubic);
    ClassDB::bind_method(D_METHOD("ease_in_out_sine", "value"), &GameRuntimeNative::ease_in_out_sine);
    ClassDB::bind_method(D_METHOD("sun_pos", "viewport_size"), &GameRuntimeNative::sun_pos);
    ClassDB::bind_method(D_METHOD("screen_shake_offset", "timer", "enabled", "strength"), &GameRuntimeNative::screen_shake_offset);
    ClassDB::bind_method(D_METHOD("can_build_towers", "phase", "between_wave", "wave_active"), &GameRuntimeNative::can_build_towers);
    ClassDB::bind_method(D_METHOD("bgm_path_for_wave", "wave_number", "early", "mid", "late", "boss"), &GameRuntimeNative::bgm_path_for_wave);
    ClassDB::bind_method(
        D_METHOD("physics_projectile_hit_index", "enemies", "pos", "previous_pos", "base_hit_radius"),
        &GameRuntimeNative::physics_projectile_hit_index);
    ClassDB::bind_method(D_METHOD("enemy_index_by_uid", "enemies", "enemy_uid"), &GameRuntimeNative::enemy_index_by_uid);
    ClassDB::bind_method(
        D_METHOD("projectile_segment_hits_point", "previous_pos", "pos", "target_pos", "hit_radius"),
        &GameRuntimeNative::projectile_segment_hits_point);
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

int GameRuntimeNative::physics_projectile_hit_index(const Array& enemies, const Vector2& pos, const Vector2& previous_pos, double base_hit_radius) const {
    int best_index = -1;
    double best_dist_squared = std::numeric_limits<double>::infinity();
    const Vector2 segment = pos - previous_pos;
    const bool has_segment = segment.length_squared() > 0.001f;

    for (int i = 0; i < enemies.size(); ++i) {
        if (enemies[i].get_type() != Variant::DICTIONARY) {
            continue;
        }
        const Dictionary enemy = enemies[i];
        const double radius = static_cast<double>(enemy.get("radius", base_hit_radius));
        const double hit_radius = MAX(base_hit_radius, radius * 0.95);
        const Vector2 enemy_pos = enemy.get("pos", Vector2());
        Vector2 closest_pos = pos;
        if (has_segment) {
            const double t = Math::clamp(
                static_cast<double>((enemy_pos - previous_pos).dot(segment)) /
                    static_cast<double>(segment.length_squared()),
                0.0,
                1.0);
            closest_pos = previous_pos + segment * static_cast<float>(t);
        }
        const double dist_squared = static_cast<double>(closest_pos.distance_squared_to(enemy_pos));
        if (dist_squared <= hit_radius * hit_radius && dist_squared < best_dist_squared) {
            best_dist_squared = dist_squared;
            best_index = i;
        }
    }
    return best_index;
}

int GameRuntimeNative::enemy_index_by_uid(const Array& enemies, int enemy_uid) const {
    if (enemy_uid < 0) {
        return -1;
    }
    for (int i = 0; i < enemies.size(); ++i) {
        if (enemies[i].get_type() != Variant::DICTIONARY) {
            continue;
        }
        const Dictionary enemy = enemies[i];
        if (static_cast<int>(enemy.get("uid", -1)) == enemy_uid) {
            return i;
        }
    }
    return -1;
}

bool GameRuntimeNative::projectile_segment_hits_point(const Vector2& previous_pos, const Vector2& pos, const Vector2& target_pos, double hit_radius) const {
    const Vector2 segment = pos - previous_pos;
    if (segment.length_squared() <= 0.001f) {
        return pos.distance_to(target_pos) <= hit_radius;
    }
    const double t = Math::clamp(
        static_cast<double>((target_pos - previous_pos).dot(segment)) /
            static_cast<double>(segment.length_squared()),
        0.0,
        1.0);
    const Vector2 closest_pos = previous_pos + segment * static_cast<float>(t);
    return closest_pos.distance_to(target_pos) <= hit_radius;
}
