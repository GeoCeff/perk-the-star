#include "wave_data.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <cstdint>

using namespace godot;

namespace {

int variant_id_from_name(const String& name) {
    if (name == "bloom") return 1;
    if (name == "burrower") return 2;
    if (name == "mimic") return 3;
    if (name == "farmer") return 4;
    if (name == "prime") return 5;
    return 0;
}

String variant_name_from_id(int variant) {
    switch (variant) {
        case 1: return "bloom";
        case 2: return "burrower";
        case 3: return "mimic";
        case 4: return "farmer";
        case 5: return "prime";
        default: return "drifter";
    }
}

float number_from_dict(const Dictionary& dict, const String& key, float fallback) {
    Variant value = dict.get(key, fallback);
    if (value.get_type() == Variant::INT || value.get_type() == Variant::FLOAT) {
        return static_cast<float>(static_cast<double>(value));
    }
    return fallback;
}

}

void WaveData::_bind_methods() {
    ClassDB::bind_method(D_METHOD("load_from_file", "path"), &WaveData::load_from_file);
    ClassDB::bind_method(D_METHOD("get_total_enemy_count"), &WaveData::get_total_enemy_count);
    ClassDB::bind_method(D_METHOD("to_dict"), &WaveData::to_dict);

    ClassDB::bind_method(D_METHOD("get_wave_number"), &WaveData::get_wave_number);
    ClassDB::bind_method(D_METHOD("get_wave_name"), &WaveData::get_wave_name);
    ClassDB::bind_method(D_METHOD("get_spawn_interval"), &WaveData::get_spawn_interval);
    ClassDB::bind_method(D_METHOD("get_reward_base"), &WaveData::get_reward_base);
    ClassDB::bind_method(D_METHOD("get_tutorial_hint"), &WaveData::get_tutorial_hint);
    ClassDB::bind_method(D_METHOD("get_has_event"), &WaveData::get_has_event);
    ClassDB::bind_method(D_METHOD("get_event_type"), &WaveData::get_event_type);
}

WaveData::WaveData()
    : wave_number(0),
      wave_name(""),
      spawn_interval(2.0f),
      reward_base(0),
      tutorial_hint(""),
      has_event(false)
{
    event = WaveEventData{"", 0.0f, 0.0f, 1};
}

bool WaveData::load_from_file(const String& path) {
    Ref<FileAccess> file = FileAccess::open(path, FileAccess::READ);
    if (file.is_null()) {
        UtilityFunctions::push_warning("WaveData could not open: ", path);
        return false;
    }

    Ref<JSON> parser;
    parser.instantiate();
    Error error = parser->parse(file->get_as_text());
    if (error != OK) {
        UtilityFunctions::push_warning("WaveData could not parse JSON: ", path);
        return false;
    }

    Variant parsed = parser->get_data();
    if (parsed.get_type() != Variant::DICTIONARY) {
        UtilityFunctions::push_warning("WaveData expected a JSON object: ", path);
        return false;
    }

    Dictionary root = parsed;
    wave_number = static_cast<int>(static_cast<int64_t>(root.get("wave", 0)));
    wave_name = String(root.get("name", ""));
    spawn_interval = number_from_dict(root, "spawn_interval", 2.0f);
    reward_base = static_cast<int>(static_cast<int64_t>(root.get("reward_base", 0)));
    tutorial_hint = String(root.get("tutorial_hint", ""));

    enemies.clear();
    Variant enemy_value = root.get("enemies", Array());
    if (enemy_value.get_type() == Variant::ARRAY) {
        Array enemy_array = enemy_value;
        for (int i = 0; i < enemy_array.size(); ++i) {
            Variant item = enemy_array[i];
            if (item.get_type() != Variant::DICTIONARY) {
                continue;
            }

            Dictionary enemy_dict = item;
            String variant_name = String(enemy_dict.get("variant", "drifter"));
            int count = static_cast<int>(static_cast<int64_t>(enemy_dict.get("count", 0)));
            if (count > 0) {
                enemies.push_back(SpawnEntry{variant_id_from_name(variant_name), count});
            }
        }
    }

    has_event = false;
    event = WaveEventData{"", 0.0f, 0.0f, 1};
    Variant event_value = root.get("event", Variant());
    if (event_value.get_type() == Variant::DICTIONARY) {
        Dictionary event_dict = event_value;
        has_event = true;
        event.type = String(event_dict.get("type", ""));
        event.trigger_at_percent = number_from_dict(event_dict, "trigger_at_percent", 0.0f);
        event.duration = number_from_dict(event_dict, "duration", number_from_dict(event_dict, "cryo_disruption_seconds", 0.0f));
        event.multiplier = static_cast<int>(static_cast<int64_t>(event_dict.get("multiplier", 1)));
    }

    return true;
}

int WaveData::get_total_enemy_count() const {
    int total = 0;
    for (const SpawnEntry& entry : enemies) {
        total += entry.count;
    }
    return total;
}

Dictionary WaveData::to_dict() const {
    Dictionary root;
    root["wave"] = wave_number;
    root["name"] = wave_name;
    root["spawn_interval"] = spawn_interval;
    root["reward_base"] = reward_base;
    root["tutorial_hint"] = tutorial_hint;

    Array enemy_array;
    for (const SpawnEntry& entry : enemies) {
        Dictionary enemy;
        enemy["variant"] = variant_name_from_id(entry.variant);
        enemy["count"] = entry.count;
        enemy_array.append(enemy);
    }
    root["enemies"] = enemy_array;

    if (has_event) {
        Dictionary event_dict;
        event_dict["type"] = event.type;
        event_dict["trigger_at_percent"] = event.trigger_at_percent;
        event_dict["duration"] = event.duration;
        event_dict["multiplier"] = event.multiplier;
        root["event"] = event_dict;
    } else {
        root["event"] = Variant();
    }

    return root;
}
