#include "game_effect_store_native.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/object.hpp>
#include <godot_cpp/core/property_info.hpp>

using namespace godot;

namespace {

double number_from_dict(const Dictionary& dict, const String& key, double fallback) {
    Variant value = dict.get(key, fallback);
    if (value.get_type() == Variant::INT || value.get_type() == Variant::FLOAT) {
        return static_cast<double>(value);
    }
    return fallback;
}

String string_from_dict(const Dictionary& dict, const String& key, const String& fallback) {
    Variant value = dict.get(key, fallback);
    return String(value);
}

}

void GameEffectStoreNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("has_activity"), &GameEffectStoreNative::has_activity);
    ClassDB::bind_method(D_METHOD("process_shots", "delta"), &GameEffectStoreNative::process_shots);
    ClassDB::bind_method(D_METHOD("process_visual_effects", "delta"), &GameEffectStoreNative::process_visual_effects);
    ClassDB::bind_method(D_METHOD("add_visual", "kind", "pos", "color", "duration", "radius"), &GameEffectStoreNative::add_visual);
    ClassDB::bind_method(D_METHOD("add_enemy_death", "enemy", "texture", "draw_size", "rotates_sprite"), &GameEffectStoreNative::add_enemy_death);
    ClassDB::bind_method(D_METHOD("add_burrower_death", "pos", "color"), &GameEffectStoreNative::add_burrower_death);
    ClassDB::bind_method(D_METHOD("add_shot", "shot_start", "shot_end", "color", "duration", "width", "kind"), &GameEffectStoreNative::add_shot);
    ClassDB::bind_method(D_METHOD("add_text", "text", "pos", "color", "duration", "font_size"), &GameEffectStoreNative::add_text);
    ClassDB::bind_method(D_METHOD("get_shots"), &GameEffectStoreNative::get_shots);
    ClassDB::bind_method(D_METHOD("set_shots", "value"), &GameEffectStoreNative::set_shots);
    ClassDB::bind_method(D_METHOD("get_visual_effects"), &GameEffectStoreNative::get_visual_effects);
    ClassDB::bind_method(D_METHOD("set_visual_effects", "value"), &GameEffectStoreNative::set_visual_effects);

    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "shots"), "set_shots", "get_shots");
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "visual_effects"), "set_visual_effects", "get_visual_effects");
}

bool GameEffectStoreNative::has_activity() const {
    return !shots.is_empty() || !visual_effects.is_empty();
}

void GameEffectStoreNative::process_shots(double delta) {
    Array active_shots;
    for (int i = 0; i < shots.size(); ++i) {
        Variant value = shots[i];
        if (value.get_type() != Variant::DICTIONARY) {
            continue;
        }
        Dictionary shot = value;
        const double ttl = number_from_dict(shot, "ttl", 0.0) - delta;
        shot["ttl"] = ttl;
        if (ttl > 0.0) {
            active_shots.append(shot);
        }
    }
    shots = active_shots;
}

void GameEffectStoreNative::process_visual_effects(double delta) {
    Array active_effects;
    for (int i = 0; i < visual_effects.size(); ++i) {
        Variant value = visual_effects[i];
        if (value.get_type() != Variant::DICTIONARY) {
            continue;
        }
        Dictionary effect = value;
        const double ttl = number_from_dict(effect, "ttl", 0.0) - delta;
        effect["ttl"] = ttl;
        if (ttl > 0.0) {
            active_effects.append(effect);
        }
    }
    visual_effects = active_effects;
}

void GameEffectStoreNative::add_visual(const String& kind, const Vector2& pos, const Color& color, double duration, double radius) {
    Dictionary effect;
    effect["kind"] = kind;
    effect["pos"] = pos;
    effect["color"] = color;
    effect["ttl"] = duration;
    effect["duration"] = duration;
    effect["radius"] = radius;
    visual_effects.append(effect);
}

void GameEffectStoreNative::add_enemy_death(const Dictionary& enemy, const Variant& texture, double draw_size, bool rotates_sprite) {
    const String variant = string_from_dict(enemy, "variant", "drifter");
    const double radius = number_from_dict(enemy, "radius", 18.0);
    const double duration = variant == "prime" ? 0.88 : 0.58;
    Dictionary effect;
    effect["kind"] = variant == "prime" ? String("prime_death") : String("enemy_death");
    effect["variant"] = variant;
    effect["pos"] = enemy.get("pos", Vector2());
    effect["color"] = enemy.get("color", Color(1.0, 0.62, 0.36));
    effect["ttl"] = duration;
    effect["duration"] = duration;
    effect["radius"] = radius + 20.0;
    effect["texture"] = texture;
    effect["draw_size"] = draw_size;
    effect["sprite_angle"] = number_from_dict(enemy, "sprite_angle", number_from_dict(enemy, "move_angle", 0.0));
    effect["rotates_sprite"] = rotates_sprite;
    visual_effects.append(effect);
}

void GameEffectStoreNative::add_burrower_death(const Vector2& pos, const Color& color) {
    Dictionary effect;
    effect["kind"] = "burrower_death";
    effect["pos"] = pos;
    effect["color"] = color;
    effect["ttl"] = 0.56;
    effect["duration"] = 0.56;
    effect["radius"] = 28.0;
    visual_effects.append(effect);
}

void GameEffectStoreNative::add_shot(const Vector2& shot_start, const Vector2& shot_end, const Color& color, double duration, double width, const String& kind) {
    Dictionary shot;
    shot["from"] = shot_start;
    shot["to"] = shot_end;
    shot["color"] = color;
    shot["ttl"] = duration;
    shot["duration"] = duration;
    shot["width"] = width;
    shot["kind"] = kind;
    shots.append(shot);
}

void GameEffectStoreNative::add_text(const String& text, const Vector2& pos, const Color& color, double duration, int font_size) {
    Dictionary effect;
    effect["kind"] = "text";
    effect["text"] = text;
    effect["pos"] = pos;
    effect["color"] = color;
    effect["ttl"] = duration;
    effect["duration"] = duration;
    effect["radius"] = 0.0;
    effect["font_size"] = font_size;
    visual_effects.append(effect);
}
