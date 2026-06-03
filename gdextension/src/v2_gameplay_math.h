#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class V2GameplayMath : public RefCounted {
    GDCLASS(V2GameplayMath, RefCounted)

protected:
    static void _bind_methods();

public:
    static constexpr double ENEMY_GRAVITY_CONST = 5200000.0;
    static constexpr double ENEMY_GRAVITY_ACCEL_CAP = 360.0;
    static constexpr double PROJECTILE_GRAVITY_CONST = 1450000.0;
    static constexpr double PROJECTILE_RING_MULT = 1.15;
    static constexpr double PROJECTILE_OUTWARD_DEFLECT = 0.12;

    double get_enemy_mass(const String& variant) const;
    Vector2 spawn_position_for_pattern(const String& pattern, int index, int count, const Vector2& sun_pos, double spawn_radius, const Dictionary& options) const;
    Dictionary integrate_enemy_gravity(const Vector2& pos, const Vector2& velocity, const Vector2& sun_pos, double base_speed, double max_speed, double mass, double delta, double slow_multiplier) const;
    Vector2 compute_physics_launch_velocity(const Vector2& tower_pos, const Vector2& target_pos, double tower_angle, double ring_radius, double ring_period, double base_speed) const;
    Dictionary integrate_projectile(const Vector2& pos, const Vector2& velocity, const Vector2& sun_pos, double damage, double last_dist, const Array& ring_radii, double delta) const;
};

}
