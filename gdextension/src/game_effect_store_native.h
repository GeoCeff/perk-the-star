#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/variant.hpp>

namespace godot {

class GameEffectStoreNative : public RefCounted {
    GDCLASS(GameEffectStoreNative, RefCounted)

protected:
    static void _bind_methods();

private:
    Array shots;
    Array visual_effects;

public:
    bool has_activity() const;
    void process_shots(double delta);
    void process_visual_effects(double delta);
    void add_visual(const String& kind, const Vector2& pos, const Color& color, double duration, double radius);
    void add_enemy_death(const Dictionary& enemy, const Variant& texture, double draw_size, bool rotates_sprite = false);
    void add_burrower_death(const Vector2& pos, const Color& color);
    void add_shot(const Vector2& shot_start, const Vector2& shot_end, const Color& color, double duration, double width = 3.0, const String& kind = "beam");
    void add_text(const String& text, const Vector2& pos, const Color& color, double duration = 0.78, int font_size = 16);

    Array get_shots() const { return shots; }
    void set_shots(const Array& value) { shots = value; }
    Array get_visual_effects() const { return visual_effects; }
    void set_visual_effects(const Array& value) { visual_effects = value; }
};

}
