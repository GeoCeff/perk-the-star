#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/variant.hpp>

namespace godot {

class GameWaveLibraryNative : public RefCounted {
    GDCLASS(GameWaveLibraryNative, RefCounted)

protected:
    static void _bind_methods();

public:
    Dictionary load_wave(int wave_number) const;
    Dictionary normalize_wave_data(const Dictionary& data, int wave_number) const;
    Array build_spawn_queue(const Dictionary& wave_data) const;
    String variant_key(const Variant& raw) const;
    String primary_variant(const Dictionary& wave_data) const;
    String spawn_summary(const Dictionary& wave_data) const;
    String warning_tags(const Dictionary& wave_data) const;
    String counter_hint(const Dictionary& wave_data) const;
    String intel_detail(const Dictionary& wave_data, int reward, int active_count = -1, int burrowed_count = 0, int queued_count = 0, const String& modifier_summary = "") const;
    String clean_hint(const String& text, const String& wave_name) const;
    String enemy_short_label(const String& variant) const;
    int total_spawn_count(const Dictionary& wave_data) const;
    String preview_label(const Dictionary& wave_data) const;
    Array array_value(const Variant& value) const;

private:
    Array spawn_entries(const Dictionary& wave_data) const;
    Dictionary variant_counts(const Dictionary& wave_data) const;
    void add_variant_count(Dictionary& counts, const String& variant, int amount) const;
    String type_label(const Dictionary& wave_data) const;
};

}
