#include "hud_panel_fx_native.h"

#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace {

const char* FRAME_TARGET_PATHS[] = {
    "../TopPanel",
    "../StatusPanel",
    "../ActionsPanel",
    "../WaveIntel",
    "../BottomRow/TowerPanel",
    "../BottomRow/MessagePanel",
};

double posmod(double value, double mod) {
    return std::fmod(std::fmod(value, mod) + mod, mod);
}

}

void HudPanelFxNative::_bind_methods() {}

void HudPanelFxNative::_ready() {
    set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
    set_process(true);
}

void HudPanelFxNative::_process(double) {
    queue_redraw();
}

void HudPanelFxNative::_draw() {
    const double time_seconds = static_cast<double>(Time::get_singleton()->get_ticks_msec()) / 1000.0;
    for (const char* path : FRAME_TARGET_PATHS) {
        Control* target = Object::cast_to<Control>(get_node_or_null(NodePath(path)));
        if (target == nullptr || !target->is_visible()) {
            continue;
        }
        draw_hud_frame(local_rect_for_target(target).grow(4.0), time_seconds);
    }
}

Rect2 HudPanelFxNative::local_rect_for_target(Control* target) const {
    const Rect2 target_rect = target->get_global_rect();
    const Transform2D inverse = get_global_transform().affine_inverse();
    return Rect2(inverse.xform(target_rect.position), target_rect.size);
}

void HudPanelFxNative::draw_hud_frame(const Rect2& rect, double time_seconds) {
    if (rect.size.x <= 8.0 || rect.size.y <= 8.0) {
        return;
    }

    const double pulse = 0.5 + std::sin(time_seconds * 1.1 + rect.position.x * 0.003) * 0.5;
    const Color cyan(0.18, 0.82, 0.96, 0.56 + pulse * 0.12);
    const Color cyan_soft(0.18, 0.82, 0.96, 0.10 + pulse * 0.035);
    const Color gold(1.0, 0.78, 0.26, 0.66 + pulse * 0.10);
    const double corner = std::clamp(std::min(rect.size.x, rect.size.y) * 0.32, 18.0, 42.0);

    draw_rect(rect, cyan_soft, false, 1.0);
    draw_corner(rect.position, Vector2(1.0, 0.0), Vector2(0.0, 1.0), corner, cyan, gold);
    draw_corner(rect.position + Vector2(rect.size.x, 0.0), Vector2(-1.0, 0.0), Vector2(0.0, 1.0), corner, cyan, gold);
    draw_corner(rect.position + Vector2(0.0, rect.size.y), Vector2(1.0, 0.0), Vector2(0.0, -1.0), corner, cyan, gold);
    draw_corner(rect.position + rect.size, Vector2(-1.0, 0.0), Vector2(0.0, -1.0), corner, cyan, gold);

    if (rect.size.x > 190.0) {
        const double rail = std::min(72.0, rect.size.x * 0.18);
        const double center_x = rect.position.x + rect.size.x * 0.5;
        draw_line(Vector2(center_x - rail, rect.position.y), Vector2(center_x + rail, rect.position.y), gold, 1.2);
        draw_line(Vector2(center_x - rail, rect.position.y + rect.size.y), Vector2(center_x + rail, rect.position.y + rect.size.y), gold, 1.2);
        const double sweep_t = posmod(time_seconds * 0.18 + rect.position.x * 0.0009, 1.0);
        const double sweep_x = center_x - rail + sweep_t * rail * 2.0;
        const Color sweep(1.0, 0.92, 0.56, 0.30 + pulse * 0.12);
        draw_line(Vector2(sweep_x - 14.0, rect.position.y), Vector2(sweep_x + 14.0, rect.position.y), sweep, 1.4);
        draw_line(Vector2(sweep_x - 14.0, rect.position.y + rect.size.y), Vector2(sweep_x + 14.0, rect.position.y + rect.size.y), sweep, 1.4);
    }

    if (rect.size.y > 92.0) {
        const double rail_y = std::min(38.0, rect.size.y * 0.22);
        const double center_y = rect.position.y + rect.size.y * 0.5;
        draw_line(Vector2(rect.position.x, center_y - rail_y), Vector2(rect.position.x, center_y + rail_y), cyan, 1.0);
        draw_line(Vector2(rect.position.x + rect.size.x, center_y - rail_y), Vector2(rect.position.x + rect.size.x, center_y + rail_y), cyan, 1.0);
    }
}

void HudPanelFxNative::draw_corner(const Vector2& origin, const Vector2& horizontal, const Vector2& vertical, double length, const Color& color, const Color& accent) {
    const double notch = std::min(14.0, length * 0.42);
    draw_line(origin, origin + horizontal * length, color, 1.6);
    draw_line(origin, origin + vertical * length, color, 1.6);
    draw_line(origin + horizontal * notch + vertical * notch, origin + horizontal * (notch + length * 0.34) + vertical * notch, accent, 1.2);
    draw_line(origin + horizontal * notch + vertical * notch, origin + horizontal * notch + vertical * (notch + length * 0.34), accent, 1.2);
}
