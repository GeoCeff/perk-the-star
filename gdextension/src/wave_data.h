#pragma once
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>
#include <vector>

namespace godot {

struct SpawnEntry {
    int variant;
    int count;
};

struct WaveEventData {
    String type;
    float  trigger_at_percent;
    float  duration;
    int    multiplier;
};

class WaveData : public RefCounted {
    GDCLASS(WaveData, RefCounted)

protected:
    static void _bind_methods();

public:
    int    wave_number;
    String wave_name;
    float  spawn_interval;
    int    reward_base;
    String tutorial_hint;

    std::vector<SpawnEntry> enemies;
    bool        has_event;
    WaveEventData event;

    WaveData();

    bool        load_from_file(const String& path);
    int         get_total_enemy_count() const;
    Dictionary  to_dict() const;

    int    get_wave_number()     const { return wave_number; }
    String get_wave_name()       const { return wave_name; }
    float  get_spawn_interval()  const { return spawn_interval; }
    int    get_reward_base()     const { return reward_base; }
    String get_tutorial_hint()   const { return tutorial_hint; }
    bool   get_has_event()       const { return has_event; }
    String get_event_type()      const { return has_event ? event.type : ""; }
};

}
