#pragma once

#include <godot_cpp/classes/texture_rect.hpp>

namespace godot {

class AnimatedSpaceBackgroundNative : public TextureRect {
    GDCLASS(AnimatedSpaceBackgroundNative, TextureRect)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void set_drift_strength(double value);
    double get_drift_strength() const;
    void set_glow_strength(double value);
    double get_glow_strength() const;
    void set_dim_strength(double value);
    double get_dim_strength() const;

private:
    double drift_strength = 0.024;
    double glow_strength = 0.46;
    double dim_strength = 0.34;
};

}
