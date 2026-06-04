#pragma once

#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/classes/audio_stream_player.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>

namespace godot {

class MusicManagerNative : public Node {
    GDCLASS(MusicManagerNative, Node)

protected:
    static void _bind_methods();

public:
    void _ready() override;

    void play_menu_music();
    void stop_music();
    Ref<AudioStream> load_music_stream(const String& path, bool loop_enabled);

private:
    AudioStreamPlayer* player = nullptr;
    String current_track_path;

    void play_music(const String& path);
    void start_player();
    void ensure_music_playing(const String& expected_track_path);
    Ref<AudioStream> load_pcm_wav_stream(const String& path, bool loop_enabled);
    String wav_chunk_id(const PackedByteArray& bytes, int offset) const;
    int read_u16_le(const PackedByteArray& bytes, int offset) const;
    int read_u32_le(const PackedByteArray& bytes, int offset) const;
    void set_audio_stream_loop(const Ref<AudioStream>& stream, bool loop_enabled) const;
    void on_music_settings_changed(bool enabled, double volume);
    Node* game_state() const;
};

}
