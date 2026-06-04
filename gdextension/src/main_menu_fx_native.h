#pragma once

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/node_path.hpp>

namespace godot {

class MainMenuFxNative : public Control {
    GDCLASS(MainMenuFxNative, Control)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void _process(double delta) override;
    void _draw() override;

    void set_draw_drift(bool value);
    bool get_draw_drift() const;
    void set_draw_frame(bool value);
    bool get_draw_frame() const;
    void set_frame_target_path(const NodePath& value);
    NodePath get_frame_target_path() const;

private:
    bool draw_drift = true;
    bool draw_frame = false;
    NodePath frame_target_path;
    Array drift_animation_sets;
    Array drifters;

    void load_textures();
    void build_drifters();
    void draw_drift_layer(double time_seconds);
    void draw_star_motes(const Vector2& viewport_size, double time_seconds);
    void draw_frame_layer(double time_seconds);
    void draw_corner(const Vector2& origin, const Vector2& horizontal, const Vector2& vertical, double length, const Color& color, const Color& accent);
    void draw_panel_rail(const Rect2& rect, const Vector2& horizontal, const Vector2& vertical, const Color& color, const Color& fill);
};

}
