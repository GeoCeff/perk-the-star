#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class GameViewControllerNative : public RefCounted {
    GDCLASS(GameViewControllerNative, RefCounted)

protected:
    static void _bind_methods();

private:
    Vector2 last_viewport_size;
    Vector2 offset;
    double zoom = 1.0;
    bool panning = false;

public:
    static constexpr double ZOOM_MIN = 0.65;
    static constexpr double ZOOM_MAX = 1.85;
    static constexpr double ZOOM_STEP = 1.12;
    static constexpr double EDGE_PAN_MARGIN = 34.0;
    static constexpr double EDGE_PAN_BOTTOM_MARGIN = 92.0;
    static constexpr double EDGE_PAN_SPEED = 560.0;
    static constexpr double KEY_PAN_SPEED = 520.0;

    void remember_viewport_size(const Vector2& viewport_size);
    bool viewport_changed(const Vector2& viewport_size) const;
    bool process_edge_pan(double delta, const Rect2& viewport_rect, const Vector2& mouse_position, bool hud_blocks_mouse, double outer_radius);
    bool process_keyboard_pan(double delta, const Vector2& viewport_size, double outer_radius);
    void pan_by(const Vector2& relative_motion, const Vector2& viewport_size, double outer_radius);
    void set_zoom(double next_zoom, const Vector2& focus_screen_position, const Vector2& viewport_size, double outer_radius);
    void reset();
    Vector2 translation(const Vector2& viewport_size) const;
    Vector2 screen_to_world(const Vector2& screen_position, const Vector2& viewport_size) const;
    Vector2 world_to_screen(const Vector2& world_position, const Vector2& viewport_size) const;
    void clamp_to_board(const Vector2& viewport_size, double outer_radius);

    Vector2 get_last_viewport_size() const { return last_viewport_size; }
    void set_last_viewport_size(const Vector2& value) { last_viewport_size = value; }
    Vector2 get_offset() const { return offset; }
    void set_offset(const Vector2& value) { offset = value; }
    double get_zoom() const { return zoom; }
    void set_zoom_value(double value) { zoom = value; }
    bool get_panning() const { return panning; }
    void set_panning(bool value) { panning = value; }

private:
    bool in_edge_gutter(const Vector2& mouse_position, const Vector2& viewport_size) const;
};

}
