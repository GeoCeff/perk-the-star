#include "game_view_controller_native.h"

#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/object.hpp>
#include <godot_cpp/core/property_info.hpp>
#include <algorithm>

using namespace godot;

namespace {

bool is_zero(const Vector2& value) {
    return value.length_squared() <= 0.000001f;
}

}

void GameViewControllerNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("remember_viewport_size", "viewport_size"), &GameViewControllerNative::remember_viewport_size);
    ClassDB::bind_method(D_METHOD("viewport_changed", "viewport_size"), &GameViewControllerNative::viewport_changed);
    ClassDB::bind_method(D_METHOD("process_edge_pan", "delta", "viewport_rect", "mouse_position", "hud_blocks_mouse", "outer_radius"), &GameViewControllerNative::process_edge_pan);
    ClassDB::bind_method(D_METHOD("process_keyboard_pan", "delta", "viewport_size", "outer_radius"), &GameViewControllerNative::process_keyboard_pan);
    ClassDB::bind_method(D_METHOD("pan_by", "relative_motion", "viewport_size", "outer_radius"), &GameViewControllerNative::pan_by);
    ClassDB::bind_method(D_METHOD("set_zoom", "next_zoom", "focus_screen_position", "viewport_size", "outer_radius"), &GameViewControllerNative::set_zoom);
    ClassDB::bind_method(D_METHOD("reset"), &GameViewControllerNative::reset);
    ClassDB::bind_method(D_METHOD("translation", "viewport_size"), &GameViewControllerNative::translation);
    ClassDB::bind_method(D_METHOD("screen_to_world", "screen_position", "viewport_size"), &GameViewControllerNative::screen_to_world);
    ClassDB::bind_method(D_METHOD("world_to_screen", "world_position", "viewport_size"), &GameViewControllerNative::world_to_screen);
    ClassDB::bind_method(D_METHOD("clamp_to_board", "viewport_size", "outer_radius"), &GameViewControllerNative::clamp_to_board);
    ClassDB::bind_method(D_METHOD("get_last_viewport_size"), &GameViewControllerNative::get_last_viewport_size);
    ClassDB::bind_method(D_METHOD("set_last_viewport_size", "value"), &GameViewControllerNative::set_last_viewport_size);
    ClassDB::bind_method(D_METHOD("get_offset"), &GameViewControllerNative::get_offset);
    ClassDB::bind_method(D_METHOD("set_offset", "value"), &GameViewControllerNative::set_offset);
    ClassDB::bind_method(D_METHOD("get_zoom"), &GameViewControllerNative::get_zoom);
    ClassDB::bind_method(D_METHOD("set_zoom_value", "value"), &GameViewControllerNative::set_zoom_value);
    ClassDB::bind_method(D_METHOD("get_panning"), &GameViewControllerNative::get_panning);
    ClassDB::bind_method(D_METHOD("set_panning", "value"), &GameViewControllerNative::set_panning);

    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "last_viewport_size"), "set_last_viewport_size", "get_last_viewport_size");
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "offset"), "set_offset", "get_offset");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "zoom"), "set_zoom_value", "get_zoom");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "panning"), "set_panning", "get_panning");
}

void GameViewControllerNative::remember_viewport_size(const Vector2& viewport_size) {
    last_viewport_size = viewport_size;
}

bool GameViewControllerNative::viewport_changed(const Vector2& viewport_size) const {
    return viewport_size != last_viewport_size;
}

bool GameViewControllerNative::process_edge_pan(double delta, const Rect2& viewport_rect, const Vector2& mouse_position, bool hud_blocks_mouse, double outer_radius) {
    if (panning || !viewport_rect.has_point(mouse_position)) {
        return false;
    }

    Vector2 direction;
    if (mouse_position.x <= EDGE_PAN_MARGIN) {
        direction.x = 1.0f;
    } else if (mouse_position.x >= viewport_rect.size.x - EDGE_PAN_MARGIN) {
        direction.x = -1.0f;
    }

    if (mouse_position.y <= EDGE_PAN_MARGIN) {
        direction.y = 1.0f;
    } else if (mouse_position.y >= viewport_rect.size.y - EDGE_PAN_BOTTOM_MARGIN) {
        direction.y = -1.0f;
    }

    if (is_zero(direction)) {
        return false;
    }
    if (hud_blocks_mouse && !in_edge_gutter(mouse_position, viewport_rect.size)) {
        return false;
    }

    offset += direction.normalized() * static_cast<float>(EDGE_PAN_SPEED * delta);
    clamp_to_board(viewport_rect.size, outer_radius);
    return true;
}

bool GameViewControllerNative::process_keyboard_pan(double delta, const Vector2& viewport_size, double outer_radius) {
    Input* input = Input::get_singleton();
    if (input == nullptr) {
        return false;
    }

    Vector2 direction;
    if (input->is_key_pressed(KEY_A)) {
        direction.x += 1.0f;
    }
    if (input->is_key_pressed(KEY_D)) {
        direction.x -= 1.0f;
    }
    if (input->is_key_pressed(KEY_W)) {
        direction.y += 1.0f;
    }
    if (input->is_key_pressed(KEY_S)) {
        direction.y -= 1.0f;
    }

    if (is_zero(direction)) {
        return false;
    }

    offset += direction.normalized() * static_cast<float>(KEY_PAN_SPEED * delta);
    clamp_to_board(viewport_size, outer_radius);
    return true;
}

void GameViewControllerNative::pan_by(const Vector2& relative_motion, const Vector2& viewport_size, double outer_radius) {
    offset += relative_motion;
    clamp_to_board(viewport_size, outer_radius);
}

void GameViewControllerNative::set_zoom(double next_zoom, const Vector2& focus_screen_position, const Vector2& viewport_size, double outer_radius) {
    const Vector2 focus_world_position = screen_to_world(focus_screen_position, viewport_size);
    zoom = std::clamp(next_zoom, ZOOM_MIN, ZOOM_MAX);
    const Vector2 center = viewport_size * 0.5f;
    offset = focus_screen_position - center - (focus_world_position - center) * static_cast<float>(zoom);
    clamp_to_board(viewport_size, outer_radius);
}

void GameViewControllerNative::reset() {
    offset = Vector2();
    zoom = 1.0;
}

Vector2 GameViewControllerNative::translation(const Vector2& viewport_size) const {
    const Vector2 center = viewport_size * 0.5f;
    return center + offset - center * static_cast<float>(zoom);
}

Vector2 GameViewControllerNative::screen_to_world(const Vector2& screen_position, const Vector2& viewport_size) const {
    const Vector2 center = viewport_size * 0.5f;
    return center + (screen_position - center - offset) / static_cast<float>(zoom);
}

Vector2 GameViewControllerNative::world_to_screen(const Vector2& world_position, const Vector2& viewport_size) const {
    const Vector2 center = viewport_size * 0.5f;
    return (world_position - center) * static_cast<float>(zoom) + center + offset;
}

void GameViewControllerNative::clamp_to_board(const Vector2& viewport_size, double outer_radius) {
    const Vector2 max_offset(
        static_cast<float>(std::max(outer_radius * 1.38, static_cast<double>(viewport_size.x) * 0.42) * zoom),
        static_cast<float>(std::max(outer_radius * 1.10, static_cast<double>(viewport_size.y) * 0.34) * zoom)
    );
    offset.x = std::clamp(offset.x, -max_offset.x, max_offset.x);
    offset.y = std::clamp(offset.y, -max_offset.y, max_offset.y);
}

bool GameViewControllerNative::in_edge_gutter(const Vector2& mouse_position, const Vector2& viewport_size) const {
    return (
        mouse_position.x <= EDGE_PAN_MARGIN ||
        mouse_position.x >= viewport_size.x - EDGE_PAN_MARGIN ||
        mouse_position.y <= EDGE_PAN_MARGIN ||
        mouse_position.y >= viewport_size.y - EDGE_PAN_BOTTOM_MARGIN
    );
}
