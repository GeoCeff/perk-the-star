#include "music_manager_native.h"

#include <godot_cpp/classes/audio_stream_ogg_vorbis.hpp>
#include <godot_cpp/classes/audio_stream_wav.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

namespace {
constexpr const char* MAIN_MENU_BGM_PATH = "res://assets/audio/bgm/final/main_menu.ogg";
}

void MusicManagerNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("play_menu_music"), &MusicManagerNative::play_menu_music);
    ClassDB::bind_method(D_METHOD("stop_music"), &MusicManagerNative::stop_music);
    ClassDB::bind_method(D_METHOD("load_music_stream", "path", "loop_enabled"), &MusicManagerNative::load_music_stream);
    ClassDB::bind_method(D_METHOD("_ensure_music_playing", "expected_track_path"), &MusicManagerNative::ensure_music_playing);
    ClassDB::bind_method(D_METHOD("_on_music_settings_changed", "enabled", "volume"), &MusicManagerNative::on_music_settings_changed);
}

void MusicManagerNative::_ready() {
    player = memnew(AudioStreamPlayer);
    player->set_name("MusicPlayer");
    player->set_process_mode(Node::PROCESS_MODE_ALWAYS);
    player->set_bus("Master");
    add_child(player);

    if (Node* state = game_state()) {
        state->connect("music_settings_changed", Callable(this, "_on_music_settings_changed"));
        state->call("load_audio_settings");
    }
}

void MusicManagerNative::play_menu_music() {
    play_music(MAIN_MENU_BGM_PATH);
}

void MusicManagerNative::stop_music() {
    if (player != nullptr) {
        player->stop();
        player->set_stream(Ref<AudioStream>());
    }
    current_track_path = "";
}

Ref<AudioStream> MusicManagerNative::load_music_stream(const String& path, bool loop_enabled) {
    const String extension = path.get_extension().to_lower();
    if (extension == "ogg") {
        Ref<AudioStreamOggVorbis> ogg_stream = AudioStreamOggVorbis::load_from_file(path);
        if (ogg_stream.is_valid()) {
            ogg_stream->set_loop(loop_enabled);
            return ogg_stream;
        }
    } else if (extension == "wav") {
        Ref<AudioStream> wav_stream = load_pcm_wav_stream(path, loop_enabled);
        if (wav_stream.is_valid()) {
            return wav_stream;
        }
    }

    Ref<Resource> resource = ResourceLoader::get_singleton()->load(path, "AudioStream", ResourceLoader::CACHE_MODE_REPLACE);
    Ref<AudioStream> stream = resource;
    if (stream.is_valid()) {
        set_audio_stream_loop(stream, loop_enabled);
    }
    return stream;
}

void MusicManagerNative::play_music(const String& path) {
    if (player == nullptr) {
        return;
    }

    if (current_track_path != path) {
        Ref<AudioStream> stream = load_music_stream(path, true);
        if (stream.is_null()) {
            UtilityFunctions::push_warning(vformat("MusicManager: missing music track at %s.", path));
            return;
        }
        player->stop();
        player->set_stream(stream);
        current_track_path = path;
    }

    if (Node* state = game_state()) {
        player->set_volume_db(float(state->call("get_music_volume_db")));
        if (bool(state->get("music_enabled")) && player->get_stream().is_valid()) {
            start_player();
        } else if (!bool(state->get("music_enabled"))) {
            player->stop();
        }
    }
}

void MusicManagerNative::start_player() {
    if (player == nullptr || player->get_stream().is_null()) {
        return;
    }
    if (!player->is_playing()) {
        player->play();
        call_deferred("_ensure_music_playing", current_track_path);
    }
}

void MusicManagerNative::ensure_music_playing(const String& expected_track_path) {
    if (player == nullptr || current_track_path != expected_track_path) {
        return;
    }
    Node* state = game_state();
    if (state == nullptr || !bool(state->get("music_enabled")) || player->get_stream().is_null()) {
        return;
    }
    if (!player->is_playing()) {
        player->play();
    }
}

Ref<AudioStream> MusicManagerNative::load_pcm_wav_stream(const String& path, bool loop_enabled) {
    PackedByteArray bytes = FileAccess::get_file_as_bytes(path);
    if (bytes.size() < 44 || wav_chunk_id(bytes, 0) != "RIFF" || wav_chunk_id(bytes, 8) != "WAVE") {
        return Ref<AudioStream>();
    }

    int fmt_offset = -1;
    int data_offset = -1;
    int data_size = 0;
    int offset = 12;
    while (offset + 8 <= bytes.size()) {
        const String chunk_id = wav_chunk_id(bytes, offset);
        const int chunk_size = read_u32_le(bytes, offset + 4);
        const int chunk_data_offset = offset + 8;
        if (chunk_id == "fmt ") {
            fmt_offset = chunk_data_offset;
        } else if (chunk_id == "data") {
            data_offset = chunk_data_offset;
            data_size = chunk_size;
            break;
        }
        offset = chunk_data_offset + chunk_size + (chunk_size % 2);
    }

    if (fmt_offset < 0 || data_offset < 0 || data_size <= 0) {
        return Ref<AudioStream>();
    }

    const int audio_format = read_u16_le(bytes, fmt_offset);
    const int channels = read_u16_le(bytes, fmt_offset + 2);
    const int sample_rate = read_u32_le(bytes, fmt_offset + 4);
    const int block_align = read_u16_le(bytes, fmt_offset + 12);
    const int bits_per_sample = read_u16_le(bytes, fmt_offset + 14);
    if (audio_format != 1 || channels < 1 || channels > 2 || sample_rate <= 0) {
        return Ref<AudioStream>();
    }
    if (bits_per_sample != 8 && bits_per_sample != 16) {
        return Ref<AudioStream>();
    }

    Ref<AudioStreamWAV> stream;
    stream.instantiate();
    stream->set_format(bits_per_sample == 8 ? AudioStreamWAV::FORMAT_8_BITS : AudioStreamWAV::FORMAT_16_BITS);
    stream->set_mix_rate(sample_rate);
    stream->set_stereo(channels == 2);
    stream->set_data(bytes.slice(data_offset, data_offset + data_size));
    set_audio_stream_loop(stream, loop_enabled);
    if (loop_enabled && block_align > 0) {
        stream->set_loop_begin(0);
        stream->set_loop_end(Math::floor(double(data_size) / double(block_align)));
    }
    return stream;
}

String MusicManagerNative::wav_chunk_id(const PackedByteArray& bytes, int offset) const {
    if (offset + 4 > bytes.size()) {
        return "";
    }
    return bytes.slice(offset, offset + 4).get_string_from_ascii();
}

int MusicManagerNative::read_u16_le(const PackedByteArray& bytes, int offset) const {
    if (offset + 2 > bytes.size()) {
        return 0;
    }
    return int(bytes[offset]) | (int(bytes[offset + 1]) << 8);
}

int MusicManagerNative::read_u32_le(const PackedByteArray& bytes, int offset) const {
    if (offset + 4 > bytes.size()) {
        return 0;
    }
    return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24);
}

void MusicManagerNative::set_audio_stream_loop(const Ref<AudioStream>& stream, bool loop_enabled) const {
    if (stream.is_null()) {
        return;
    }
    if (Ref<AudioStreamOggVorbis> ogg_stream = stream; ogg_stream.is_valid()) {
        ogg_stream->set_loop(loop_enabled);
    } else if (Ref<AudioStreamWAV> wav_stream = stream; wav_stream.is_valid()) {
        wav_stream->set_loop_mode(loop_enabled ? AudioStreamWAV::LOOP_FORWARD : AudioStreamWAV::LOOP_DISABLED);
    }
}

void MusicManagerNative::on_music_settings_changed(bool, double) {
    if (player == nullptr) {
        return;
    }
    if (Node* state = game_state()) {
        player->set_volume_db(float(state->call("get_music_volume_db")));
        if (current_track_path.is_empty() || player->get_stream().is_null()) {
            return;
        }
        if (bool(state->get("music_enabled"))) {
            start_player();
        } else {
            player->stop();
        }
    }
}

Node* MusicManagerNative::game_state() const {
    return get_node_or_null(NodePath("/root/GameState"));
}
