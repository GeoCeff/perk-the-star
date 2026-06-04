#include "main_menu_fx_native.h"

#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace {

double wrap_value(double value, double min_value, double max_value) {
    const double range = max_value - min_value;
    if (range == 0.0) {
        return min_value;
    }
    return value - range * std::floor((value - min_value) / range);
}

double posmod(double value, double mod) {
    return std::fmod(std::fmod(value, mod) + mod, mod);
}

Array texture_frames(const Array& paths) {
    Array frames;
    ResourceLoader* loader = ResourceLoader::get_singleton();
    for (int i = 0; i < paths.size(); ++i) {
        Ref<Resource> resource = loader->load(String(paths[i]));
        Ref<Texture2D> texture = resource;
        if (texture.is_valid()) {
            frames.append(texture);
        }
    }
    return frames;
}

Dictionary animation_set(const Array& paths, double base_angle, double fps) {
    Dictionary data;
    data["frames"] = texture_frames(paths);
    data["base_angle"] = base_angle;
    data["fps"] = fps;
    return data;
}

Dictionary drifter(const Vector2& uv, const Vector2& speed, double scale, double alpha, double phase) {
    Dictionary data;
    data["uv"] = uv;
    data["speed"] = speed;
    data["scale"] = scale;
    data["alpha"] = alpha;
    data["phase"] = phase;
    return data;
}

} // namespace

void MainMenuFxNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_draw_drift", "value"), &MainMenuFxNative::set_draw_drift);
    ClassDB::bind_method(D_METHOD("get_draw_drift"), &MainMenuFxNative::get_draw_drift);
    ClassDB::bind_method(D_METHOD("set_draw_frame", "value"), &MainMenuFxNative::set_draw_frame);
    ClassDB::bind_method(D_METHOD("get_draw_frame"), &MainMenuFxNative::get_draw_frame);
    ClassDB::bind_method(D_METHOD("set_frame_target_path", "value"), &MainMenuFxNative::set_frame_target_path);
    ClassDB::bind_method(D_METHOD("get_frame_target_path"), &MainMenuFxNative::get_frame_target_path);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "draw_drift"), "set_draw_drift", "get_draw_drift");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "draw_frame"), "set_draw_frame", "get_draw_frame");
    ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "frame_target_path"), "set_frame_target_path", "get_frame_target_path");
}

void MainMenuFxNative::_ready() {
    set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
    load_textures();
    build_drifters();
    set_process(true);
}

void MainMenuFxNative::_process(double) {
    queue_redraw();
}

void MainMenuFxNative::_draw() {
    const double time_seconds = static_cast<double>(Time::get_singleton()->get_ticks_msec()) / 1000.0;
    if (draw_drift) {
        draw_drift_layer(time_seconds);
    }
    if (draw_frame) {
        draw_frame_layer(time_seconds);
    }
}

void MainMenuFxNative::set_draw_drift(bool value) {
    draw_drift = value;
}

bool MainMenuFxNative::get_draw_drift() const {
    return draw_drift;
}

void MainMenuFxNative::set_draw_frame(bool value) {
    draw_frame = value;
}

bool MainMenuFxNative::get_draw_frame() const {
    return draw_frame;
}

void MainMenuFxNative::set_frame_target_path(const NodePath& value) {
    frame_target_path = value;
}

NodePath MainMenuFxNative::get_frame_target_path() const {
    return frame_target_path;
}

void MainMenuFxNative::load_textures() {
    drift_animation_sets.clear();
    drift_animation_sets.append(animation_set(Array::make(
        "res://assets/sprites/clean/enemies_optimized/drifter_move_1.png",
        "res://assets/sprites/clean/enemies_optimized/drifter_move_2.png",
        "res://assets/sprites/clean/enemies_optimized/drifter_move_3.png"), 0.0, 6.0));
    drift_animation_sets.append(animation_set(Array::make(
        "res://assets/sprites/clean/enemies_optimized/bloom_move_1.png",
        "res://assets/sprites/clean/enemies_optimized/bloom_move_2.png",
        "res://assets/sprites/clean/enemies_optimized/bloom_move_3.png"), 0.0, 6.0));
    drift_animation_sets.append(animation_set(Array::make(
        "res://assets/sprites/clean/enemies_optimized/solar_move_1.png",
        "res://assets/sprites/clean/enemies_optimized/solar_move_2.png",
        "res://assets/sprites/clean/enemies_optimized/solar_move_3.png"), -0.7853981633974483, 6.0));
    drift_animation_sets.append(animation_set(Array::make(
        "res://assets/sprites/clean/enemies_optimized/coronal_move_1.png",
        "res://assets/sprites/clean/enemies_optimized/coronal_move_2.png",
        "res://assets/sprites/clean/enemies_optimized/coronal_move_3.png",
        "res://assets/sprites/clean/enemies_optimized/coronal_move_4.png"), -1.5707963267948966, 7.0));
    drift_animation_sets.append(animation_set(Array::make(
        "res://assets/sprites/clean/enemies_optimized/astrophage-shell_move_1.png",
        "res://assets/sprites/clean/enemies_optimized/astrophage-shell_move_2.png",
        "res://assets/sprites/clean/enemies_optimized/astrophage-shell_move_3.png",
        "res://assets/sprites/clean/enemies_optimized/astrophage-shell_move_4.png"), 0.0, 5.0));

    Array valid_sets;
    for (int i = 0; i < drift_animation_sets.size(); ++i) {
        Dictionary set = drift_animation_sets[i];
        Array frames = set.get("frames", Array());
        if (!frames.is_empty()) {
            valid_sets.append(set);
        }
    }
    drift_animation_sets = valid_sets;
}

void MainMenuFxNative::build_drifters() {
    drifters.clear();
    drifters.append(drifter(Vector2(0.10, 0.18), Vector2(10.0, 3.0), 0.40, 0.18, 0.2));
    drifters.append(drifter(Vector2(0.86, 0.20), Vector2(-8.0, 4.0), 0.38, 0.16, 1.4));
    drifters.append(drifter(Vector2(0.22, 0.76), Vector2(6.0, -2.0), 0.34, 0.14, 2.2));
    drifters.append(drifter(Vector2(0.78, 0.72), Vector2(-7.0, -2.0), 0.40, 0.16, 3.1));
    drifters.append(drifter(Vector2(0.47, 0.14), Vector2(4.0, 2.0), 0.32, 0.13, 4.0));
    drifters.append(drifter(Vector2(0.56, 0.86), Vector2(-5.0, -3.0), 0.36, 0.14, 5.2));
    drifters.append(drifter(Vector2(0.04, 0.54), Vector2(8.0, 1.0), 0.32, 0.12, 2.8));
    drifters.append(drifter(Vector2(0.95, 0.52), Vector2(-9.0, 1.0), 0.34, 0.12, 0.9));
}

void MainMenuFxNative::draw_drift_layer(double time_seconds) {
    if (drift_animation_sets.is_empty()) {
        return;
    }

    const Vector2 viewport_size = get_rect().size;
    draw_star_motes(viewport_size, time_seconds);

    for (int i = 0; i < drifters.size(); ++i) {
        Dictionary item = drifters[i];
        Dictionary animation_set_data = drift_animation_sets[i % drift_animation_sets.size()];
        Array frames = animation_set_data.get("frames", Array());
        if (frames.is_empty()) {
            continue;
        }
        const Vector2 uv = item["uv"];
        const Vector2 speed = item["speed"];
        const double phase = static_cast<double>(item["phase"]);
        const double fps = static_cast<double>(animation_set_data.get("fps", 6.0));
        const int frame_index = static_cast<int>(std::floor((time_seconds + phase) * fps)) % frames.size();
        Ref<Texture2D> texture = frames[frame_index];
        if (texture.is_null()) {
            continue;
        }
        const double alpha = static_cast<double>(item["alpha"]) * (0.72 + std::sin(time_seconds * 0.9 + phase) * 0.18);
        const Vector2 pos(
            wrap_value(viewport_size.x * uv.x + time_seconds * speed.x, -140.0, viewport_size.x + 140.0),
            wrap_value(viewport_size.y * uv.y + time_seconds * speed.y + std::sin(time_seconds * 0.8 + phase) * 18.0, -140.0, viewport_size.y + 140.0));
        const Vector2 sprite_size = texture->get_size() * static_cast<double>(item["scale"]);
        const double travel_angle = speed.length_squared() > 0.001 ? speed.angle() : 0.0;
        const double drift_rotation = travel_angle - static_cast<double>(animation_set_data.get("base_angle", 0.0)) + std::sin(time_seconds * 0.35 + phase) * 0.12;
        draw_set_transform(pos, drift_rotation, Vector2(1.0, 1.0));
        draw_texture_rect(texture, Rect2(sprite_size * -0.5, sprite_size), false, Color(0.70, 0.92, 1.0, alpha));
        draw_set_transform(Vector2(), 0.0, Vector2(1.0, 1.0));
    }
}

void MainMenuFxNative::draw_star_motes(const Vector2& viewport_size, double time_seconds) {
    for (int i = 0; i < 28; ++i) {
        const double phase = static_cast<double>(i) * 1.713;
        const double drift = time_seconds * (7.0 + static_cast<double>(i % 5) * 1.6);
        const double x = wrap_value(std::sin(phase * 2.11) * viewport_size.x * 0.5 + viewport_size.x * 0.5 + drift, -32.0, viewport_size.x + 32.0);
        const double y = wrap_value(std::cos(phase * 1.37) * viewport_size.y * 0.5 + viewport_size.y * 0.5 + std::sin(time_seconds * 0.4 + phase) * 10.0, -32.0, viewport_size.y + 32.0);
        const double pulse = 0.5 + std::sin(time_seconds * 1.4 + phase) * 0.5;
        const double alpha = 0.06 + pulse * 0.13;
        const Vector2 point(x, y);
        draw_circle(point, 1.0 + static_cast<double>(i % 3) * 0.45, Color(0.50, 0.90, 1.0, alpha));
        if (i % 4 == 0) {
            draw_line(point - Vector2(10.0, 1.5), point + Vector2(10.0, -1.5), Color(0.50, 0.90, 1.0, alpha * 0.42), 0.8);
        }
    }
}

void MainMenuFxNative::draw_frame_layer(double time_seconds) {
    Control* target = Object::cast_to<Control>(get_node_or_null(frame_target_path));
    if (target == nullptr) {
        return;
    }

    const Rect2 rect = target->get_global_rect().grow(10.0);
    const Rect2 inner_rect = rect.grow(-9.0);
    const double pulse = 0.5 + std::sin(time_seconds * 1.0 + rect.position.y * 0.004) * 0.5;
    const Color cyan(0.18, 0.82, 0.96, 0.70 + pulse * 0.12);
    const Color cyan_soft(0.18, 0.82, 0.96, 0.14 + pulse * 0.04);
    const Color gold(1.0, 0.78, 0.26, 0.76 + pulse * 0.10);
    const Color panel_blue(0.08, 0.36, 0.52, 0.24 + pulse * 0.06);
    const double corner = 72.0;
    const double notch = 18.0;

    draw_rect(rect, cyan_soft, false, 1.0);
    draw_rect(inner_rect, panel_blue, false, 1.0);
    draw_corner(rect.position, Vector2(1.0, 0.0), Vector2(0.0, 1.0), corner, cyan, gold);
    draw_corner(rect.position + Vector2(rect.size.x, 0.0), Vector2(-1.0, 0.0), Vector2(0.0, 1.0), corner, cyan, gold);
    draw_corner(rect.position + Vector2(0.0, rect.size.y), Vector2(1.0, 0.0), Vector2(0.0, -1.0), corner, cyan, gold);
    draw_corner(rect.position + rect.size, Vector2(-1.0, 0.0), Vector2(0.0, -1.0), corner, cyan, gold);

    draw_panel_rail(rect, Vector2(1.0, 0.0), Vector2(0.0, 1.0), cyan, panel_blue);
    draw_panel_rail(rect, Vector2(-1.0, 0.0), Vector2(0.0, 1.0), cyan, panel_blue);

    draw_line(rect.position + Vector2(rect.size.x * 0.5 - 80.0, 0.0), rect.position + Vector2(rect.size.x * 0.5 + 80.0, 0.0), gold, 1.8);
    draw_line(rect.position + Vector2(rect.size.x * 0.5 - 80.0, rect.size.y), rect.position + Vector2(rect.size.x * 0.5 + 80.0, rect.size.y), gold, 1.8);
    draw_line(rect.position + Vector2(0.0, rect.size.y * 0.5 - 54.0), rect.position + Vector2(0.0, rect.size.y * 0.5 + 54.0), cyan, 1.4);
    draw_line(rect.position + Vector2(rect.size.x, rect.size.y * 0.5 - 54.0), rect.position + Vector2(rect.size.x, rect.size.y * 0.5 + 54.0), cyan, 1.4);
    const double sweep_t = posmod(time_seconds * 0.15 + rect.position.x * 0.0006, 1.0);
    const double sweep_x = rect.position.x + rect.size.x * 0.5 - 80.0 + sweep_t * 160.0;
    const Color sweep_color(1.0, 0.92, 0.56, 0.30 + pulse * 0.12);
    draw_line(Vector2(sweep_x - 20.0, rect.position.y), Vector2(sweep_x + 20.0, rect.position.y), sweep_color, 1.6);
    draw_line(Vector2(sweep_x - 20.0, rect.position.y + rect.size.y), Vector2(sweep_x + 20.0, rect.position.y + rect.size.y), sweep_color, 1.6);

    const Vector2 points[] = {
        rect.position + Vector2(rect.size.x * 0.5 - 112.0, 0.0),
        rect.position + Vector2(rect.size.x * 0.5 + 112.0, 0.0),
        rect.position + Vector2(rect.size.x * 0.5 - 112.0, rect.size.y),
        rect.position + Vector2(rect.size.x * 0.5 + 112.0, rect.size.y),
    };
    for (const Vector2& point : points) {
        draw_circle(point, notch * (0.14 + pulse * 0.05), gold);
    }
}

void MainMenuFxNative::draw_corner(const Vector2& origin, const Vector2& horizontal, const Vector2& vertical, double length, const Color& color, const Color& accent) {
    draw_line(origin, origin + horizontal * length, color, 2.0);
    draw_line(origin, origin + vertical * length, color, 2.0);
    draw_line(origin + horizontal * 18.0 + vertical * 18.0, origin + horizontal * 44.0 + vertical * 18.0, accent, 1.8);
    draw_line(origin + horizontal * 18.0 + vertical * 18.0, origin + horizontal * 18.0 + vertical * 44.0, accent, 1.8);
}

void MainMenuFxNative::draw_panel_rail(const Rect2& rect, const Vector2& horizontal, const Vector2& vertical, const Color& color, const Color& fill) {
    double x_side = rect.position.x;
    if (horizontal.x < 0.0) {
        x_side = rect.position.x + rect.size.x;
    }

    const double y_top = rect.position.y + 96.0;
    const double y_bottom = rect.position.y + rect.size.y - 96.0;
    const double rail_width = 24.0 * horizontal.x;
    const double bevel = 14.0;
    PackedVector2Array points;
    points.append(Vector2(x_side, y_top));
    points.append(Vector2(x_side + rail_width, y_top + bevel));
    points.append(Vector2(x_side + rail_width, y_bottom - bevel));
    points.append(Vector2(x_side, y_bottom));
    draw_colored_polygon(points, fill);
    draw_polyline(points, color, 1.0);
    draw_line(Vector2(x_side, y_top + 70.0), Vector2(x_side + rail_width, y_top + 70.0 + bevel * vertical.y), color, 1.0);
    draw_line(Vector2(x_side, y_bottom - 70.0), Vector2(x_side + rail_width, y_bottom - 70.0 - bevel * vertical.y), color, 1.0);
}
