class_name GameSfxBus
extends Node

# Lightweight procedural sound bus for the prototype.
# Final SFX can replace these generated streams later without changing the
# gameplay code that asks for "build", "hit", "wave_clear", and so on.

const SAMPLE_RATE: int = 22050
const POOL_SIZE: int = 12

var players: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var player_index: int = 0
var last_played: Dictionary = {}


func initialize() -> void:
	streams = {
		"button": _make_sfx(760.0, 1020.0, 0.070, 0.28),
		"build": _make_sfx(460.0, 760.0, 0.145, 0.34),
		"upgrade": _make_sfx(560.0, 1120.0, 0.190, 0.34),
		"sell": _make_sfx(820.0, 420.0, 0.130, 0.28),
		"wave_start": _make_sfx(320.0, 780.0, 0.260, 0.38),
		"clash_incoming": _make_sfx(180.0, 820.0, 0.360, 0.36, 0.18),
		"counter_attack": _make_sfx(900.0, 260.0, 0.320, 0.38, 0.16),
		"shot": _make_sfx(930.0, 620.0, 0.055, 0.16),
		"physics_fire": _make_sfx(520.0, 980.0, 0.150, 0.24, 0.08),
		"slingshot_fire": _make_sfx(380.0, 1320.0, 0.260, 0.30, 0.07),
		"hit": _make_sfx(280.0, 190.0, 0.075, 0.24, 0.28),
		"death": _make_sfx(240.0, 88.0, 0.170, 0.32, 0.18),
		"prime_phase_shift": _make_sfx(110.0, 620.0, 0.460, 0.42, 0.20),
		"prime_death": _make_sfx(180.0, 46.0, 0.420, 0.42, 0.22),
		"flare": _make_sfx(220.0, 1180.0, 0.360, 0.42, 0.10),
		"sun_hit": _make_sfx(135.0, 72.0, 0.210, 0.36, 0.25),
		"wave_clear": _make_sfx(520.0, 940.0, 0.300, 0.36),
		"victory": _make_sfx(440.0, 1060.0, 0.520, 0.38),
		"failure": _make_sfx(260.0, 64.0, 0.520, 0.42, 0.20),
	}

	players.clear()
	for i in range(POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % (i + 1)
		player.volume_db = -5.0
		player.max_polyphony = 1
		add_child(player)
		players.append(player)


func play(kind: String, min_interval: float = 0.0) -> void:
	if players.is_empty() or not streams.has(kind):
		return

	var now: float = float(Time.get_ticks_msec()) / 1000.0
	if min_interval > 0.0 and now - float(last_played.get(kind, -999.0)) < min_interval:
		return
	last_played[kind] = now

	var player: AudioStreamPlayer = players[player_index]
	player_index = (player_index + 1) % players.size()
	player.stop()
	player.stream = streams[kind]
	player.pitch_scale = randf_range(0.96, 1.04)
	player.play()


func _make_sfx(start_freq: float, end_freq: float, duration: float, volume: float, noise: float = 0.0) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false

	var data: PackedByteArray = PackedByteArray()
	var sample_count: int = max(1, int(float(SAMPLE_RATE) * duration))
	var phase: float = 0.0
	for i in range(sample_count):
		var t: float = float(i) / float(sample_count)
		var freq: float = lerpf(start_freq, end_freq, t)
		phase += TAU * freq / float(SAMPLE_RATE)
		var envelope: float = smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.62, 1.0, t))
		var tone: float = sin(phase)
		if noise > 0.0:
			tone = lerpf(tone, randf_range(-1.0, 1.0), noise)
		var sample_i: int = int(clampf(tone * volume * envelope, -1.0, 1.0) * 32767.0)
		data.append(sample_i & 0xff)
		data.append((sample_i >> 8) & 0xff)

	stream.data = data
	return stream
