#pragma once

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class HudPanelFxNative : public Control {
    GDCLASS(HudPanelFxNative, Control)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void _process(double delta) override;
    void _draw() override;

private:
    Rect2 local_rect_for_target(Control* target) const;
    void draw_hud_frame(const Rect2& rect, double time_seconds);
    void draw_corner(const Vector2& origin, const Vector2& horizontal, const Vector2& vertical, double length, const Color& color, const Color& accent);
};

}
