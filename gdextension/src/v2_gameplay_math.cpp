#include "v2_gameplay_math.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <algorithm>
#include <cmath>

using namespace godot;

namespace {

constexpr double TAU_D = 6.28318530717958647692;
constexpr double PI_D = 3.14159265358979323846;

double number_from_dict(const Dictionary& dict, const String& key, double fallback) {
    Variant value = dict.get(key, fallback);
    if (value.get_type() == Variant::INT || value.get_type() == Variant::FLOAT) {
        return static_cast<double>(value);
    }
    return fallback;
}

int int_from_dict(const Dictionary& dict, const String& key, int fallback) {
    Variant value = dict.get(key, fallback);
    if (value.get_type() == Variant::INT || value.get_type() == Variant::FLOAT) {
        return static_cast<int>(static_cast<int64_t>(value));
    }
    return fallback;
}

Vector2 safe_normalized(const Vector2& value, const Vector2& fallback = Vector2(1.0f, 0.0f)) {
    if (value.length_squared() <= 0.0001f) {
        return fallback;
    }
    return value.normalized();
}

}

void V2GameplayMath::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_enemy_mass", "variant"), &V2GameplayMath::get_enemy_mass);
    ClassDB::bind_method(D_METHOD("spawn_position_for_pattern", "pattern", "index", "count", "sun_pos", "spawn_radius", "options"), &V2GameplayMath::spawn_position_for_pattern);
    ClassDB::bind_method(D_METHOD("integrate_enemy_gravity", "pos", "velocity", "sun_pos", "base_speed", "max_speed", "mass", "delta", "slow_multiplier"), &V2GameplayMath::integrate_enemy_gravity);
    ClassDB::bind_method(D_METHOD("compute_physics_launch_velocity", "tower_pos", "target_pos", "tower_angle", "ring_radius", "ring_period", "base_speed"), &V2GameplayMath::compute_physics_launch_velocity);
    ClassDB::bind_method(D_METHOD("integrate_projectile", "pos", "velocity", "sun_pos", "damage", "last_dist", "ring_radii", "delta"), &V2GameplayMath::integrate_projectile);
}

double V2GameplayMath::get_enemy_mass(const String& variant) const {
    if (variant == "bloom") return 1.5;
    if (variant == "burrower") return 3.0;
    if (variant == "mimic") return 0.8;
    if (variant == "farmer") return 1.2;
    if (variant == "prime") return 8.0;
    return 1.0;
}

Vector2 V2GameplayMath::spawn_position_for_pattern(const String& pattern, int index, int count, const Vector2& sun_pos, double spawn_radius, const Dictionary& options) const {
    const int safe_count = std::max(1, count);
    const double i = static_cast<double>(std::max(0, index));
    const String normalized = pattern.strip_edges().to_lower();

    if (normalized == "ring") {
        const double angle = (i / static_cast<double>(safe_count)) * TAU_D;
        return sun_pos + Vector2(std::cos(angle), std::sin(angle)) * static_cast<float>(spawn_radius);
    }
    if (normalized == "v_shape") {
        const int half = std::max(1, static_cast<int>(std::ceil(static_cast<double>(safe_count) * 0.5)));
        const double side = index < half ? 1.0 : -1.0;
        const int local_index = index < half ? index : index - half;
        const double spread = number_from_dict(options, "spread_angle_deg", 60.0) * (PI_D / 180.0);
        const double angle = -PI_D * 0.5 + side * ((static_cast<double>(local_index + 1) / static_cast<double>(half + 1)) * spread);
        return sun_pos + Vector2(std::cos(angle), std::sin(angle)) * static_cast<float>(spawn_radius);
    }
    if (normalized == "spiral") {
        const int arms = std::max(1, int_from_dict(options, "spiral_arms", 1));
        const double arm_offset = TAU_D * static_cast<double>(index % arms) / static_cast<double>(arms);
        const double turns = 1.5 + static_cast<double>(arms) * 0.35;
        const double angle = arm_offset + (i / static_cast<double>(safe_count)) * TAU_D * turns;
        const double radius = spawn_radius * (0.72 + 0.28 * static_cast<double>(index + 1) / static_cast<double>(safe_count));
        return sun_pos + Vector2(std::cos(angle), std::sin(angle)) * static_cast<float>(radius);
    }
    if (normalized == "center_top") {
        return sun_pos + Vector2(0.0f, -static_cast<float>(spawn_radius));
    }

    const double angle = UtilityFunctions::randf() * TAU_D;
    return sun_pos + Vector2(std::cos(angle), std::sin(angle)) * static_cast<float>(spawn_radius);
}

Dictionary V2GameplayMath::integrate_enemy_gravity(const Vector2& pos, const Vector2& velocity, const Vector2& sun_pos, double base_speed, double max_speed, double mass, double delta, double slow_multiplier) const {
    Dictionary result;
    Vector2 to_sun = sun_pos - pos;
    const double dist = std::max(0.001, static_cast<double>(to_sun.length()));
    Vector2 dir = safe_normalized(to_sun);
    double safe_mass = std::max(0.2, mass);
    double accel = ENEMY_GRAVITY_CONST / std::max(dist * dist * safe_mass, 1200.0);
    accel = std::min(accel, ENEMY_GRAVITY_ACCEL_CAP);

    Vector2 next_velocity = velocity + dir * static_cast<float>((accel + base_speed * 0.18) * delta);
    const double terminal = std::max(1.0, max_speed * std::max(0.0, slow_multiplier));
    const double velocity_speed = next_velocity.length();
    if (velocity_speed > terminal && velocity_speed > 0.001) {
        next_velocity = next_velocity / static_cast<float>(velocity_speed) * static_cast<float>(terminal);
    }

    result["pos"] = pos + next_velocity * static_cast<float>(delta);
    result["velocity"] = next_velocity;
    result["move_angle"] = std::atan2(dir.y, dir.x);
    return result;
}

Vector2 V2GameplayMath::compute_physics_launch_velocity(const Vector2& tower_pos, const Vector2& target_pos, double tower_angle, double ring_radius, double ring_period, double base_speed) const {
    Vector2 to_target = safe_normalized(target_pos - tower_pos);
    Vector2 tangent(-std::sin(tower_angle), std::cos(tower_angle));
    const double angular_velocity = TAU_D / std::max(ring_period, 0.001);
    const double orbital_contribution = angular_velocity * ring_radius * 0.6;
    return to_target * static_cast<float>(base_speed) + tangent * static_cast<float>(orbital_contribution);
}

Dictionary V2GameplayMath::integrate_projectile(const Vector2& pos, const Vector2& velocity, const Vector2& sun_pos, double damage, double last_dist, const Array& ring_radii, double delta) const {
    Dictionary result;
    Vector2 to_sun = sun_pos - pos;
    const double dist = std::max(0.001, static_cast<double>(to_sun.length()));
    Vector2 dir = safe_normalized(to_sun);
    double accel = PROJECTILE_GRAVITY_CONST / std::max(dist * dist, 100.0);
    accel = std::min(accel, 620.0);

    Vector2 next_velocity = velocity + dir * static_cast<float>(accel * delta);
    double next_damage = damage;
    int crossed_ring = -1;

    for (int i = 0; i < ring_radii.size(); ++i) {
        Variant raw_radius = ring_radii[i];
        if (raw_radius.get_type() != Variant::INT && raw_radius.get_type() != Variant::FLOAT) {
            continue;
        }
        const double radius = static_cast<double>(raw_radius);
        if (last_dist > radius && dist <= radius) {
            next_damage *= PROJECTILE_RING_MULT;
            crossed_ring = i;
        } else if (last_dist < radius && dist >= radius) {
            Vector2 deflect(-next_velocity.y, next_velocity.x);
            if (deflect.length_squared() > 0.0001f) {
                next_velocity += deflect.normalized() * next_velocity.length() * static_cast<float>(PROJECTILE_OUTWARD_DEFLECT);
            }
        }
    }

    result["pos"] = pos + next_velocity * static_cast<float>(delta);
    result["velocity"] = next_velocity;
    result["damage"] = next_damage;
    result["last_dist"] = dist;
    result["crossed_ring"] = crossed_ring;
    return result;
}
