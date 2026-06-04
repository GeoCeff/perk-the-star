#pragma once

#include <godot_cpp/classes/audio_stream_wav.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/random_number_generator.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class GameSfxBusNative : public Node {
    GDCLASS(GameSfxBusNative, Node)

protected:
    static void _bind_methods();

private:
    static constexpr int SAMPLE_RATE = 22050;
    static constexpr int POOL_SIZE = 12;

    Array players;
    Dictionary streams;
    Dictionary last_played;
    int player_index = 0;
    Ref<RandomNumberGenerator> rng;

public:
    GameSfxBusNative();

    void initialize();
    void play(const String& kind, double min_interval = 0.0);

private:
    Ref<AudioStreamWAV> load_wav(const String& path) const;
    Ref<AudioStreamWAV> load_or_make(const String& file_name, double start_freq, double end_freq, double duration, double volume, double noise = 0.0);
    Ref<AudioStreamWAV> make_sfx(double start_freq, double end_freq, double duration, double volume, double noise = 0.0);
};

}
