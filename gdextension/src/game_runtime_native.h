#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class GameRuntimeNative : public RefCounted {
    GDCLASS(GameRuntimeNative, RefCounted)

protected:
    static void _bind_methods();

public:
    double ease_out_cubic(double value) const;
    double ease_in_out_sine(double value) const;
    Vector2 sun_pos(const Vector2& viewport_size) const;
    Vector2 screen_shake_offset(double timer, bool enabled, double strength) const;
    bool can_build_towers(int phase, int between_wave, int wave_active) const;
    String bgm_path_for_wave(int wave_number, const String& early, const String& mid, const String& late, const String& boss) const;
};

}
