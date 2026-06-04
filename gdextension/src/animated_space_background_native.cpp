#include "animated_space_background_native.h"

#include <godot_cpp/classes/canvas_item.hpp>
#include <godot_cpp/classes/shader.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void AnimatedSpaceBackgroundNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_drift_strength", "value"), &AnimatedSpaceBackgroundNative::set_drift_strength);
    ClassDB::bind_method(D_METHOD("get_drift_strength"), &AnimatedSpaceBackgroundNative::get_drift_strength);
    ClassDB::bind_method(D_METHOD("set_glow_strength", "value"), &AnimatedSpaceBackgroundNative::set_glow_strength);
    ClassDB::bind_method(D_METHOD("get_glow_strength"), &AnimatedSpaceBackgroundNative::get_glow_strength);
    ClassDB::bind_method(D_METHOD("set_dim_strength", "value"), &AnimatedSpaceBackgroundNative::set_dim_strength);
    ClassDB::bind_method(D_METHOD("get_dim_strength"), &AnimatedSpaceBackgroundNative::get_dim_strength);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "drift_strength"), "set_drift_strength", "get_drift_strength");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "glow_strength"), "set_glow_strength", "get_glow_strength");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "dim_strength"), "set_dim_strength", "get_dim_strength");
}

void AnimatedSpaceBackgroundNative::_ready() {
    Ref<Shader> shader;
    shader.instantiate();
    shader->set_code(R"(
shader_type canvas_item;

uniform float drift_strength = 0.024;
uniform float glow_strength = 0.46;
uniform float dim_strength = 0.34;

void fragment() {
    float t = TIME;
    vec2 slow_drift = vec2(sin(t * 0.055) * drift_strength + t * 0.0022, cos(t * 0.047) * drift_strength * 0.70);
    vec2 cross_drift = vec2(cos(t * 0.038) * drift_strength * 0.62, sin(t * 0.052) * drift_strength * 0.82);
    vec2 uv_a = fract(UV + slow_drift);
    vec2 uv_b = fract((UV - vec2(0.5)) * 1.045 + vec2(0.5) - cross_drift);
    vec4 base = texture(TEXTURE, uv_a);
    vec4 haze = texture(TEXTURE, uv_b);
    float wave = sin(UV.x * 8.0 + UV.y * 5.0 + t * 0.78) * 0.5 + 0.5;
    float pulse = sin(t * 0.58) * 0.5 + 0.5;
    float ember = sin(UV.x * 18.0 - UV.y * 11.0 + t * 0.45) * 0.5 + 0.5;
    float vignette = 1.0 - smoothstep(0.18, 0.86, distance(UV, vec2(0.5)));
    vec3 color = mix(base.rgb, haze.rgb, 0.24);
    color += vec3(0.02, 0.34, 0.42) * wave * glow_strength * vignette;
    color += vec3(0.24, 0.10, 0.03) * ember * glow_strength * 0.34;
    color *= 1.0 - dim_strength * (1.0 - wave) * (0.46 + pulse * 0.34);
    color += vec3(0.02, 0.08, 0.10) * pulse * glow_strength * 0.16;
    COLOR = vec4(color, base.a);
}
)");

    set_texture_filter(CanvasItem::TEXTURE_FILTER_LINEAR_WITH_MIPMAPS);
    Ref<ShaderMaterial> shader_material;
    shader_material.instantiate();
    shader_material->set_shader(shader);
    shader_material->set_shader_parameter("drift_strength", drift_strength);
    shader_material->set_shader_parameter("glow_strength", glow_strength);
    shader_material->set_shader_parameter("dim_strength", dim_strength);
    set_material(shader_material);
}

void AnimatedSpaceBackgroundNative::set_drift_strength(double value) {
    drift_strength = value;
}

double AnimatedSpaceBackgroundNative::get_drift_strength() const {
    return drift_strength;
}

void AnimatedSpaceBackgroundNative::set_glow_strength(double value) {
    glow_strength = value;
}

double AnimatedSpaceBackgroundNative::get_glow_strength() const {
    return glow_strength;
}

void AnimatedSpaceBackgroundNative::set_dim_strength(double value) {
    dim_strength = value;
}

double AnimatedSpaceBackgroundNative::get_dim_strength() const {
    return dim_strength;
}
