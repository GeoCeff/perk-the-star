#include "game_orbit_math_native.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <algorithm>
#include <cmath>

using namespace godot;

namespace {

constexpr double TAU_D = 6.28318530717958647692;

struct RingInfo {
    int id;
    const char* name;
    double radius;
    double period;
    int slots;
};

constexpr RingInfo RINGS[] = {
    {1, "Corona Belt", 80.0, 6.0, 4},
    {2, "Chromosphere Band", 140.0, 11.0, 6},
    {3, "Photosphere Arc", 210.0, 17.0, 8},
    {4, "Outer Veil", 290.0, 26.0, 10},
};

int clamp_ring_index(int ring_index) {
    return std::clamp(ring_index, 0, GameOrbitMathNative::RING_COUNT - 1);
}

double wrap_angle(double value) {
    double wrapped = std::fmod(value, TAU_D);
    if (wrapped < 0.0) {
        wrapped += TAU_D;
    }
    return wrapped;
}

int int_from_dict(const Dictionary& dict, const String& key, int fallback) {
    Variant value = dict.get(key, fallback);
    if (value.get_type() == Variant::INT || value.get_type() == Variant::FLOAT) {
        return static_cast<int>(static_cast<int64_t>(value));
    }
    return fallback;
}

double number_from_dict(const Dictionary& dict, const String& key, double fallback) {
    Variant value = dict.get(key, fallback);
    if (value.get_type() == Variant::INT || value.get_type() == Variant::FLOAT) {
        return static_cast<double>(value);
    }
    return fallback;
}

String short_ring_name(const char* name) {
    String value(name);
    value = value.replace(" Belt", "");
    value = value.replace(" Band", "");
    value = value.replace(" Arc", "");
    value = value.replace("Outer ", "");
    return value;
}

}

void GameOrbitMathNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("nearest_ring_slot", "pos", "sun_pos", "towers"), &GameOrbitMathNative::nearest_ring_slot);
    ClassDB::bind_method(D_METHOD("nearest_slot_index", "ring_index", "angle"), &GameOrbitMathNative::nearest_slot_index);
    ClassDB::bind_method(D_METHOD("ring_slot_angle", "ring_index", "slot_index"), &GameOrbitMathNative::ring_slot_angle);
    ClassDB::bind_method(D_METHOD("ring_slot_position", "sun_pos", "ring_index", "slot_index"), &GameOrbitMathNative::ring_slot_position);
    ClassDB::bind_method(D_METHOD("ring_radius", "ring_index"), &GameOrbitMathNative::ring_radius);
    ClassDB::bind_method(D_METHOD("outer_ring_radius"), &GameOrbitMathNative::outer_ring_radius);
    ClassDB::bind_method(D_METHOD("tower_position", "sun_pos", "tower"), &GameOrbitMathNative::tower_position);
    ClassDB::bind_method(D_METHOD("burrower_position", "sun_pos", "burrower", "dig_radius"), &GameOrbitMathNative::burrower_position);
    ClassDB::bind_method(D_METHOD("ring_summary"), &GameOrbitMathNative::ring_summary);
}

Dictionary GameOrbitMathNative::nearest_ring_slot(const Vector2& pos, const Vector2& sun_pos, const Array& towers) const {
    Dictionary best;
    double best_diff = 1.0e20;
    for (int i = 0; i < RING_COUNT; ++i) {
        const double diff = std::abs(static_cast<double>(pos.distance_to(sun_pos)) - ring_radius(i));
        if (diff < 28.0 && diff < best_diff) {
            const double angle = static_cast<double>((pos - sun_pos).angle());
            const int slot_index = nearest_slot_index(i, angle);
            best["ring_index"] = i;
            best["ring_name"] = String(RINGS[i].name);
            best["slot_index"] = slot_index;
            best["angle"] = ring_slot_angle(i, slot_index);
            best["occupied"] = is_slot_taken(towers, i, slot_index);
            best_diff = diff;
        }
    }
    return best;
}

int GameOrbitMathNative::nearest_slot_index(int ring_index, double angle) const {
    const RingInfo& ring = RINGS[clamp_ring_index(ring_index)];
    const double step = TAU_D / static_cast<double>(ring.slots);
    const double normalized = wrap_angle(angle - SLOT_ANGLE_OFFSET);
    return static_cast<int>(std::round(normalized / step)) % ring.slots;
}

double GameOrbitMathNative::ring_slot_angle(int ring_index, int slot_index) const {
    const RingInfo& ring = RINGS[clamp_ring_index(ring_index)];
    return wrap_angle(SLOT_ANGLE_OFFSET + TAU_D * static_cast<double>(slot_index) / static_cast<double>(ring.slots));
}

Vector2 GameOrbitMathNative::ring_slot_position(const Vector2& sun_pos, int ring_index, int slot_index) const {
    const double angle = ring_slot_angle(ring_index, slot_index);
    return sun_pos + Vector2(std::cos(angle), std::sin(angle)) * static_cast<float>(ring_radius(ring_index));
}

double GameOrbitMathNative::ring_radius(int ring_index) const {
    return RINGS[clamp_ring_index(ring_index)].radius * RING_RADIUS_SCALE;
}

double GameOrbitMathNative::outer_ring_radius() const {
    return ring_radius(RING_COUNT - 1);
}

Vector2 GameOrbitMathNative::tower_position(const Vector2& sun_pos, const Dictionary& tower) const {
    const double angle = number_from_dict(tower, "angle", 0.0);
    const int ring_index = int_from_dict(tower, "ring", 0);
    return sun_pos + Vector2(std::cos(angle), std::sin(angle)) * static_cast<float>(ring_radius(ring_index));
}

Vector2 GameOrbitMathNative::burrower_position(const Vector2& sun_pos, const Dictionary& burrower, double dig_radius) const {
    const double angle = number_from_dict(burrower, "angle", 0.0);
    return sun_pos + Vector2(std::cos(angle), std::sin(angle)) * static_cast<float>(dig_radius);
}

String GameOrbitMathNative::ring_summary() const {
    String first = "RINGS: ";
    first += String("R1 ") + short_ring_name(RINGS[0].name) + String(" 4 slots");
    first += String("  |  R2 ") + short_ring_name(RINGS[1].name) + String(" 6 slots");

    String second = "       ";
    second += String("R3 ") + short_ring_name(RINGS[2].name) + String(" 8 slots");
    second += String("  |  R4 ") + short_ring_name(RINGS[3].name) + String(" 10 slots");
    return first + String("\n") + second;
}

bool GameOrbitMathNative::is_slot_taken(const Array& towers, int ring_index, int slot_index) const {
    for (int i = 0; i < towers.size(); ++i) {
        Variant value = towers[i];
        if (value.get_type() != Variant::DICTIONARY) {
            continue;
        }
        Dictionary tower = value;
        if (int_from_dict(tower, "ring", -1) == ring_index && int_from_dict(tower, "slot", -1) == slot_index) {
            return true;
        }
    }
    return false;
}
