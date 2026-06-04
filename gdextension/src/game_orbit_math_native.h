#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class GameOrbitMathNative : public RefCounted {
    GDCLASS(GameOrbitMathNative, RefCounted)

protected:
    static void _bind_methods();

public:
    static constexpr double RING_RADIUS_SCALE = 1.5;
    static constexpr double SLOT_ANGLE_OFFSET = -1.57079632679489661923;
    static constexpr int RING_COUNT = 4;

    Dictionary nearest_ring_slot(const Vector2& pos, const Vector2& sun_pos, const Array& towers) const;
    int nearest_slot_index(int ring_index, double angle) const;
    double ring_slot_angle(int ring_index, int slot_index) const;
    Vector2 ring_slot_position(const Vector2& sun_pos, int ring_index, int slot_index) const;
    double ring_radius(int ring_index) const;
    double outer_ring_radius() const;
    Vector2 tower_position(const Vector2& sun_pos, const Dictionary& tower) const;
    Vector2 burrower_position(const Vector2& sun_pos, const Dictionary& burrower, double dig_radius) const;
    String ring_summary() const;

private:
    bool is_slot_taken(const Array& towers, int ring_index, int slot_index) const;
};

}
