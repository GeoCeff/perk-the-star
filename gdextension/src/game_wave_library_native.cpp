#include "game_wave_library_native.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>

using namespace godot;

namespace {

Array variant_keys() {
    Array keys;
    keys.append("drifter");
    keys.append("bloom");
    keys.append("burrower");
    keys.append("mimic");
    keys.append("farmer");
    keys.append("prime");
    return keys;
}

bool is_number(const Variant& value) {
    return value.get_type() == Variant::INT || value.get_type() == Variant::FLOAT;
}

int int_value(const Variant& value, int fallback = 0) {
    if (is_number(value)) {
        return static_cast<int>(static_cast<int64_t>(value));
    }
    return fallback;
}

double float_value(const Variant& value, double fallback = 0.0) {
    if (is_number(value)) {
        return static_cast<double>(value);
    }
    return fallback;
}

String enemy_label(const String& variant) {
    if (variant == "bloom") return "Bloom";
    if (variant == "burrower") return "Coronal Burrower";
    if (variant == "mimic") return "Photon Mimic";
    if (variant == "farmer") return "Solar Farmer";
    if (variant == "prime") return "Astrophage Prime";
    return "Drifter";
}

}

void GameWaveLibraryNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("load_wave", "wave_number"), &GameWaveLibraryNative::load_wave);
    ClassDB::bind_method(D_METHOD("normalize_wave_data", "data", "wave_number"), &GameWaveLibraryNative::normalize_wave_data);
    ClassDB::bind_method(D_METHOD("build_spawn_queue", "wave_data"), &GameWaveLibraryNative::build_spawn_queue);
    ClassDB::bind_method(D_METHOD("variant_key", "raw"), &GameWaveLibraryNative::variant_key);
    ClassDB::bind_method(D_METHOD("primary_variant", "wave_data"), &GameWaveLibraryNative::primary_variant);
    ClassDB::bind_method(D_METHOD("spawn_summary", "wave_data"), &GameWaveLibraryNative::spawn_summary);
    ClassDB::bind_method(D_METHOD("warning_tags", "wave_data"), &GameWaveLibraryNative::warning_tags);
    ClassDB::bind_method(D_METHOD("counter_hint", "wave_data"), &GameWaveLibraryNative::counter_hint);
    ClassDB::bind_method(D_METHOD("intel_detail", "wave_data", "reward", "active_count", "burrowed_count", "queued_count", "modifier_summary"), &GameWaveLibraryNative::intel_detail, DEFVAL(-1), DEFVAL(0), DEFVAL(0), DEFVAL(""));
    ClassDB::bind_method(D_METHOD("clean_hint", "text", "wave_name"), &GameWaveLibraryNative::clean_hint);
    ClassDB::bind_method(D_METHOD("enemy_short_label", "variant"), &GameWaveLibraryNative::enemy_short_label);
    ClassDB::bind_method(D_METHOD("total_spawn_count", "wave_data"), &GameWaveLibraryNative::total_spawn_count);
    ClassDB::bind_method(D_METHOD("preview_label", "wave_data"), &GameWaveLibraryNative::preview_label);
    ClassDB::bind_method(D_METHOD("array_value", "value"), &GameWaveLibraryNative::array_value);
}

Dictionary GameWaveLibraryNative::load_wave(int wave_number) const {
    const String path = vformat("res://data/waves/wave_%02d.json", wave_number);
    Ref<FileAccess> file = FileAccess::open(path, FileAccess::READ);
    if (file.is_null()) {
        return Dictionary();
    }

    Variant parsed = JSON::parse_string(file->get_as_text());
    if (parsed.get_type() != Variant::DICTIONARY) {
        return Dictionary();
    }
    return normalize_wave_data(parsed, wave_number);
}

Dictionary GameWaveLibraryNative::normalize_wave_data(const Dictionary& data, int wave_number) const {
    const double default_interval = std::max(float_value(data.get("spawn_interval", 2.0), 2.0), 0.05);
    Array spawns;
    Array clash_groups;
    String wave_type = String(data.get("wave_type", "normal")).strip_edges().to_lower();
    if (wave_type != "normal" && wave_type != "formation" && wave_type != "clash" && wave_type != "boss") {
        wave_type = "normal";
    }

    Variant event_value = data.get("event", Dictionary());
    Dictionary event_data = event_value.get_type() == Variant::DICTIONARY ? Dictionary(event_value) : Dictionary();
    Variant formation_value = data.get("formation", Dictionary());
    Dictionary formation_data = formation_value.get_type() == Variant::DICTIONARY ? Dictionary(formation_value) : Dictionary();

    if (data.has("spawns")) {
        const Array raw_spawns = array_value(data.get("spawns", Array()));
        for (int i = 0; i < raw_spawns.size(); ++i) {
            if (raw_spawns[i].get_type() != Variant::DICTIONARY) {
                continue;
            }
            Dictionary entry = raw_spawns[i];
            Dictionary spawn;
            spawn["variant"] = variant_key(entry.get("variant", 0));
            spawn["count"] = std::max(0, int_value(entry.get("count", 0)));
            spawn["interval"] = std::max(float_value(entry.get("interval", default_interval), default_interval), 0.05);
            spawns.append(spawn);
        }
    } else if (data.has("enemies")) {
        const Array enemies = array_value(data.get("enemies", Array()));
        for (int i = 0; i < enemies.size(); ++i) {
            if (enemies[i].get_type() != Variant::DICTIONARY) {
                continue;
            }
            Dictionary entry = enemies[i];
            Dictionary spawn;
            spawn["variant"] = variant_key(entry.get("variant", "drifter"));
            spawn["count"] = std::max(0, int_value(entry.get("count", 0)));
            spawn["interval"] = default_interval;
            spawns.append(spawn);
        }
    }

    const Array raw_groups = array_value(data.get("clash_groups", Array()));
    for (int i = 0; i < raw_groups.size(); ++i) {
        if (raw_groups[i].get_type() != Variant::DICTIONARY) {
            continue;
        }
        Dictionary raw_group = raw_groups[i];
        Array variants;
        const Array raw_variants = array_value(raw_group.get("variants", Array()));
        for (int j = 0; j < raw_variants.size(); ++j) {
            variants.append(variant_key(raw_variants[j]));
        }
        if (variants.is_empty()) {
            continue;
        }
        Dictionary group;
        group["variants"] = variants;
        group["spawn_pattern"] = String(raw_group.get("spawn_pattern", "random")).strip_edges().to_lower();
        group["delay_before"] = std::max(float_value(raw_group.get("delay_before", 0.0), 0.0), 0.0);
        if (raw_group.has("spread_angle_deg")) {
            group["spread_angle_deg"] = float_value(raw_group.get("spread_angle_deg", 60.0), 60.0);
        }
        if (raw_group.has("spiral_arms")) {
            group["spiral_arms"] = std::max(1, int_value(raw_group.get("spiral_arms", 1)));
        }
        clash_groups.append(group);
    }

    if (!formation_data.is_empty()) {
        Array formation_variants;
        const Array raw_variants = array_value(formation_data.get("variants", Array::make("drifter")));
        for (int i = 0; i < raw_variants.size(); ++i) {
            formation_variants.append(variant_key(raw_variants[i]));
        }
        if (formation_variants.is_empty()) {
            formation_variants.append("drifter");
        }
        Dictionary normalized;
        normalized["type"] = String(formation_data.get("type", "ring")).strip_edges().to_lower();
        normalized["variants"] = formation_variants;
        normalized["count"] = std::max(0, int_value(formation_data.get("count", 0)));
        normalized["spread_angle_deg"] = float_value(formation_data.get("spread_angle_deg", 60.0), 60.0);
        normalized["spiral_arms"] = std::max(1, int_value(formation_data.get("spiral_arms", 1)));
        formation_data = normalized;
    }

    Dictionary normalized;
    normalized["index"] = int_value(data.get("index", data.get("wave", wave_number)), wave_number);
    normalized["name"] = String(data.get("name", vformat("Wave %02d", wave_number)));
    normalized["wave_type"] = wave_type;
    normalized["spawn_interval"] = default_interval;
    normalized["credit_reward"] = int_value(data.get("credit_reward", data.get("reward_base", 0)));
    normalized["spawns"] = spawns;
    normalized["clash_groups"] = clash_groups;
    normalized["formation"] = formation_data;
    normalized["event"] = event_data;
    normalized["escalation_threshold_seconds"] = data.get("escalation_threshold_seconds", Variant());
    normalized["tutorial_hint"] = String(data.get("tutorial_hint", "Defend the Sun."));
    return normalized;
}

Array GameWaveLibraryNative::build_spawn_queue(const Dictionary& wave_data) const {
    Array queue;
    const String wave_type = String(wave_data.get("wave_type", "normal"));
    if (wave_type == "clash" || wave_type == "boss") {
        return queue;
    }
    const Array entries = spawn_entries(wave_data);
    for (int i = 0; i < entries.size(); ++i) {
        if (entries[i].get_type() != Variant::DICTIONARY) {
            continue;
        }
        Dictionary entry = entries[i];
        const String variant = variant_key(entry.get("variant", 0));
        const int count = std::max(0, int_value(entry.get("count", 0)));
        const double interval = std::max(float_value(entry.get("interval", 2.0), 2.0), 0.05);
        for (int j = 0; j < count; ++j) {
            Dictionary spawn;
            spawn["variant"] = variant;
            spawn["interval"] = interval;
            queue.append(spawn);
        }
    }
    return queue;
}

String GameWaveLibraryNative::variant_key(const Variant& raw) const {
    if (is_number(raw)) {
        const int idx = int_value(raw);
        const Array keys = variant_keys();
        if (idx >= 0 && idx < keys.size()) {
            return keys[idx];
        }
        return "drifter";
    }

    String cleaned = String(raw).strip_edges().to_lower();
    if (cleaned.is_valid_int()) {
        return variant_key(cleaned.to_int());
    }
    cleaned = cleaned.replace(" ", "_").replace("-", "_");
    if (cleaned == "drifter") return "drifter";
    if (cleaned == "bloom") return "bloom";
    if (cleaned == "burrower" || cleaned == "coronal_burrower") return "burrower";
    if (cleaned == "mimic" || cleaned == "photon_mimic") return "mimic";
    if (cleaned == "farmer" || cleaned == "solar_farmer") return "farmer";
    if (cleaned == "prime" || cleaned == "astrophage_prime") return "prime";
    return "drifter";
}

String GameWaveLibraryNative::primary_variant(const Dictionary& wave_data) const {
    Dictionary counts = variant_counts(wave_data);
    if (counts.is_empty()) {
        return "drifter";
    }
    return String(counts.keys()[0]);
}

String GameWaveLibraryNative::spawn_summary(const Dictionary& wave_data) const {
    Array parts;
    Dictionary counts = variant_counts(wave_data);
    const Array keys = counts.keys();
    for (int i = 0; i < keys.size(); ++i) {
        const String variant = String(keys[i]);
        parts.append(vformat("%d %s", int_value(counts[variant]), enemy_short_label(variant)));
    }
    return parts.is_empty() ? String("No spawns loaded") : String(", ").join(parts);
}

String GameWaveLibraryNative::warning_tags(const Dictionary& wave_data) const {
    Array tags;
    Dictionary seen;
    const String wave_type = String(wave_data.get("wave_type", "normal"));
    if (wave_type == "clash") tags.append("CLASH");
    else if (wave_type == "formation") tags.append("FORMATION");
    else if (wave_type == "boss") tags.append("BOSS");

    Dictionary counts = variant_counts(wave_data);
    const Array keys = counts.keys();
    for (int i = 0; i < keys.size(); ++i) {
        const String variant = variant_key(keys[i]);
        if (seen.has(variant)) {
            continue;
        }
        seen[variant] = true;
        if (variant == "bloom") tags.append("SPLIT");
        else if (variant == "burrower") tags.append("BURROW");
        else if (variant == "mimic") tags.append("MIMIC");
        else if (variant == "farmer") tags.append("ABSORB");
        else if (variant == "prime") tags.append("PRIME");
    }

    Variant event_value = wave_data.get("event", Dictionary());
    String event_type;
    if (event_value.get_type() == Variant::DICTIONARY) {
        Dictionary event_data = event_value;
        event_type = String(event_data.get("type", ""));
    }
    if (event_type == "mid_wave_autoflare") tags.append("STORM");
    else if (event_type == "ring_blind") tags.append("RING DARK");
    else if (event_type == "bio_lab_boost") tags.append("BIO BOOST");
    else if (event_type == "prime_frenzy") tags.append("FRENZY");

    return tags.is_empty() ? String("TAGS: BASIC SWARM") : vformat("TAGS: %s", String("  |  ").join(tags));
}

String GameWaveLibraryNative::counter_hint(const Dictionary& wave_data) const {
    Dictionary variants = variant_counts(wave_data);
    if (variants.has("prime")) return "COUNTER: Bio-Lab opens shell, then Helios/Tardigrade finish.";
    if (variants.has("farmer")) return "COUNTER: Cryo or Magnetic first; avoid feeding Farmers with energy.";
    if (variants.has("mimic")) return "COUNTER: Mix Bio-Lab, Cryo, Magnetic, or Helios with Photon.";
    if (variants.has("burrower")) return "COUNTER: Build Bio-Lab before Burrowers reach the Sun.";
    if (variants.has("bloom")) return "COUNTER: Slow Blooms before they split into Drifters.";
    return "COUNTER: Photon Splitters handle the first swarm cleanly.";
}

String GameWaveLibraryNative::intel_detail(const Dictionary& wave_data, int reward, int active_count, int burrowed_count, int queued_count, const String& modifier_summary) const {
    Array lines;
    lines.append(vformat("%s | CONTACTS %d | REWARD +%d SOL", type_label(wave_data), total_spawn_count(wave_data), reward));
    lines.append(warning_tags(wave_data));
    lines.append(counter_hint(wave_data));
    if (active_count >= 0) {
        lines.insert(0, vformat("LIVE: %d ACTIVE | %d BURROWED | %d QUEUED", active_count, burrowed_count, queued_count));
    }
    if (modifier_summary.strip_edges() != "") {
        lines.append(modifier_summary.strip_edges());
    }
    return String("\n").join(lines);
}

String GameWaveLibraryNative::clean_hint(const String& text, const String& wave_name) const {
    const String repeated_prefix = vformat("%s: ", wave_name);
    if (text.begins_with(repeated_prefix)) {
        return text.substr(repeated_prefix.length());
    }
    return text;
}

String GameWaveLibraryNative::enemy_short_label(const String& variant) const {
    if (variant == "burrower") return "Burrower";
    if (variant == "mimic") return "Mimic";
    if (variant == "farmer") return "Farmer";
    if (variant == "prime") return "Prime";
    return enemy_label(variant);
}

int GameWaveLibraryNative::total_spawn_count(const Dictionary& wave_data) const {
    int count = 0;
    const Array values = variant_counts(wave_data).values();
    for (int i = 0; i < values.size(); ++i) {
        count += std::max(0, int_value(values[i]));
    }
    return count;
}

String GameWaveLibraryNative::preview_label(const Dictionary& wave_data) const {
    const int count = total_spawn_count(wave_data);
    const String wave_type = String(wave_data.get("wave_type", "normal"));
    if (wave_type == "clash") return vformat("Massive wave approaching - %d enemies", count);
    if (wave_type == "boss") return vformat("Astrophage Prime detected - %d contacts", count);
    if (wave_type == "formation") return vformat("Formation wave incoming - %d enemies", count);
    return vformat("Wave incoming - %d enemies", count);
}

Array GameWaveLibraryNative::array_value(const Variant& value) const {
    if (value.get_type() == Variant::ARRAY) {
        return value;
    }
    return Array();
}

Array GameWaveLibraryNative::spawn_entries(const Dictionary& wave_data) const {
    return array_value(wave_data.get("spawns", Array()));
}

Dictionary GameWaveLibraryNative::variant_counts(const Dictionary& wave_data) const {
    Dictionary counts;
    const String wave_type = String(wave_data.get("wave_type", "normal"));
    if (wave_type == "clash" || wave_type == "boss") {
        const Array groups = array_value(wave_data.get("clash_groups", Array()));
        for (int i = 0; i < groups.size(); ++i) {
            if (groups[i].get_type() != Variant::DICTIONARY) {
                continue;
            }
            Dictionary group = groups[i];
            const Array variants = array_value(group.get("variants", Array()));
            for (int j = 0; j < variants.size(); ++j) {
                add_variant_count(counts, variant_key(variants[j]), 1);
            }
        }
        if (!counts.is_empty()) {
            return counts;
        }
    }

    const Array entries = spawn_entries(wave_data);
    for (int i = 0; i < entries.size(); ++i) {
        if (entries[i].get_type() != Variant::DICTIONARY) {
            continue;
        }
        Dictionary entry = entries[i];
        add_variant_count(counts, variant_key(entry.get("variant", 0)), std::max(0, int_value(entry.get("count", 0))));
    }

    if (wave_type == "formation") {
        Variant formation_value = wave_data.get("formation", Dictionary());
        if (formation_value.get_type() == Variant::DICTIONARY) {
            Dictionary formation = formation_value;
            const Array formation_variants = array_value(formation.get("variants", Array::make("drifter")));
            const int formation_count = std::max(0, int_value(formation.get("count", 0)));
            if (!formation_variants.is_empty() && formation_count > 0) {
                for (int i = 0; i < formation_count; ++i) {
                    add_variant_count(counts, variant_key(formation_variants[i % formation_variants.size()]), 1);
                }
            }
        }
    }
    return counts;
}

void GameWaveLibraryNative::add_variant_count(Dictionary& counts, const String& variant, int amount) const {
    if (amount <= 0) {
        return;
    }
    counts[variant] = int_value(counts.get(variant, 0)) + amount;
}

String GameWaveLibraryNative::type_label(const Dictionary& wave_data) const {
    const String wave_type = String(wave_data.get("wave_type", "normal"));
    if (wave_type == "clash") return "CLASH";
    if (wave_type == "boss") return "BOSS";
    if (wave_type == "formation") return "FORMATION";
    return "STANDARD";
}
