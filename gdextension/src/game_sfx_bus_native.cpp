#include "game_sfx_bus_native.h"

#include <godot_cpp/classes/audio_stream_player.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <algorithm>
#include <cmath>

using namespace godot;

namespace {

constexpr double TAU_D = 6.28318530717958647692;

double smoothstep(double edge0, double edge1, double x) {
    const double t = std::clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

}

GameSfxBusNative::GameSfxBusNative() {
    rng.instantiate();
}

void GameSfxBusNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize"), &GameSfxBusNative::initialize);
    ClassDB::bind_method(D_METHOD("play", "kind", "min_interval"), &GameSfxBusNative::play);
}

void GameSfxBusNative::initialize() {
    if (rng.is_valid()) {
        rng->randomize();
    }

    streams.clear();
    streams["button"] = make_sfx(760.0, 1020.0, 0.070, 0.28);
    streams["build"] = make_sfx(460.0, 760.0, 0.145, 0.34);
    streams["upgrade"] = make_sfx(560.0, 1120.0, 0.190, 0.34);
    streams["sell"] = make_sfx(820.0, 420.0, 0.130, 0.28);
    streams["wave_start"] = make_sfx(320.0, 780.0, 0.260, 0.38);
    streams["clash_incoming"] = make_sfx(180.0, 820.0, 0.360, 0.36, 0.18);
    streams["counter_attack"] = make_sfx(900.0, 260.0, 0.320, 0.38, 0.16);
    streams["shot"] = make_sfx(930.0, 620.0, 0.055, 0.16);
    streams["physics_fire"] = make_sfx(520.0, 980.0, 0.150, 0.24, 0.08);
    streams["slingshot_fire"] = make_sfx(380.0, 1320.0, 0.260, 0.30, 0.07);
    streams["hit"] = make_sfx(280.0, 190.0, 0.075, 0.24, 0.28);
    streams["death"] = make_sfx(240.0, 88.0, 0.170, 0.32, 0.18);
    streams["prime_phase_shift"] = make_sfx(110.0, 620.0, 0.460, 0.42, 0.20);
    streams["prime_death"] = make_sfx(180.0, 46.0, 0.420, 0.42, 0.22);
    streams["flare"] = make_sfx(220.0, 1180.0, 0.360, 0.42, 0.10);
    streams["sun_hit"] = make_sfx(135.0, 72.0, 0.210, 0.36, 0.25);
    streams["wave_clear"] = make_sfx(520.0, 940.0, 0.300, 0.36);
    streams["victory"] = make_sfx(440.0, 1060.0, 0.520, 0.38);
    streams["failure"] = make_sfx(260.0, 64.0, 0.520, 0.42, 0.20);

    for (int i = 0; i < players.size(); ++i) {
        Object* object = Object::cast_to<Object>(players[i]);
        if (object != nullptr) {
            Node* node = Object::cast_to<Node>(object);
            if (node != nullptr && node->get_parent() == this) {
                remove_child(node);
                node->queue_free();
            }
        }
    }

    players.clear();
    player_index = 0;
    for (int i = 0; i < POOL_SIZE; ++i) {
        AudioStreamPlayer* player = memnew(AudioStreamPlayer);
        player->set_name(String("SfxPlayer") + String::num_int64(i + 1));
        player->set_volume_db(-5.0f);
        player->set_max_polyphony(1);
        add_child(player);
        players.append(player);
    }
}

void GameSfxBusNative::play(const String& kind, double min_interval) {
    if (players.is_empty() || !streams.has(kind)) {
        return;
    }

    double now = 0.0;
    Time* time = Time::get_singleton();
    if (time != nullptr) {
        now = static_cast<double>(time->get_ticks_msec()) / 1000.0;
    }
    if (min_interval > 0.0 && now - static_cast<double>(last_played.get(kind, -999.0)) < min_interval) {
        return;
    }
    last_played[kind] = now;

    AudioStreamPlayer* player = Object::cast_to<AudioStreamPlayer>(players[player_index]);
    player_index = (player_index + 1) % players.size();
    if (player == nullptr) {
        return;
    }

    Ref<AudioStreamWAV> stream = streams[kind];
    player->stop();
    player->set_stream(stream);
    const float pitch = rng.is_valid() ? rng->randf_range(0.96f, 1.04f) : 1.0f;
    player->set_pitch_scale(pitch);
    player->play();
}

Ref<AudioStreamWAV> GameSfxBusNative::make_sfx(double start_freq, double end_freq, double duration, double volume, double noise) {
    Ref<AudioStreamWAV> stream;
    stream.instantiate();
    stream->set_format(AudioStreamWAV::FORMAT_16_BITS);
    stream->set_mix_rate(SAMPLE_RATE);
    stream->set_stereo(false);

    PackedByteArray data;
    const int sample_count = std::max(1, static_cast<int>(static_cast<double>(SAMPLE_RATE) * duration));
    double phase = 0.0;
    for (int i = 0; i < sample_count; ++i) {
        const double t = static_cast<double>(i) / static_cast<double>(sample_count);
        const double freq = start_freq + (end_freq - start_freq) * t;
        phase += TAU_D * freq / static_cast<double>(SAMPLE_RATE);
        const double envelope = smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.62, 1.0, t));
        double tone = std::sin(phase);
        if (noise > 0.0 && rng.is_valid()) {
            tone = tone + (rng->randf_range(-1.0f, 1.0f) - tone) * noise;
        }
        const int sample = static_cast<int>(std::clamp(tone * volume * envelope, -1.0, 1.0) * 32767.0);
        data.append(static_cast<uint8_t>(sample & 0xff));
        data.append(static_cast<uint8_t>((sample >> 8) & 0xff));
    }

    stream->set_data(data);
    return stream;
}
