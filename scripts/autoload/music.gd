extends Node
## Generative background music: plucked-string (guzheng-like) pentatonic
## melodies over a drone for the map, and taiko-style drums for battles.
## Samples are synthesised once (Karplus-Strong) on a worker thread and then
## sequenced live, so the music never loops exactly.

const RATE := 22050
const SCALE := [0, 3, 5, 7, 10]        # minor pentatonic
const ROOT_HZ := 146.83                 # D3

var _notes: Array = []                  # AudioStreamWAV per scale degree
var _drum: AudioStreamWAV
var _drum_hi: AudioStreamWAV
var _player: AudioStreamPlayer
var _playback: AudioStreamPlaybackPolyphonic
var _ready_to_play := false
var mode := ""
var _t := 0.0
var _step := 0
var _melody := 5
var _phrase_rest := 0

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	var poly := AudioStreamPolyphonic.new()
	poly.polyphony = 24
	_player.stream = poly
	add_child(_player)
	apply_volume()
	if DisplayServer.get_name() == "headless":
		return
	WorkerThreadPool.add_task(_generate)

func play(m: String) -> void:
	mode = m

func apply_volume() -> void:
	if _player == null:
		return
	var v: float = GS.settings.get("music", 0.5) if GS != null else 0.5
	_player.volume_db = linear_to_db(maxf(0.0001, v)) - 6.0

func _generate() -> void:
	for d in SCALE:
		_notes.append(_pluck(ROOT_HZ * pow(2.0, d / 12.0) * 2.0, 1.6))
	_drum = _taiko(0.6, 70.0)
	_drum_hi = _taiko(0.25, 160.0)
	_on_generated.call_deferred()

func _on_generated() -> void:
	_ready_to_play = true
	_player.play()
	_playback = _player.get_stream_playback()

func _process(delta: float) -> void:
	if not _ready_to_play or mode == "" or _playback == null:
		return
	var bpm := 132.0 if mode == "battle" else 76.0
	var step_len := 60.0 / bpm / 2.0
	_t += delta
	while _t >= step_len:
		_t -= step_len
		_tick()

func _tick() -> void:
	_step += 1
	var pos := _step % 16
	if mode == "battle":
		if pos in [0, 8]:
			_playback.play_stream(_drum, 0, 0.0, 1.0)
		elif pos in [6, 11, 14]:
			_playback.play_stream(_drum, 0, -5.0, 1.15)
		if pos % 2 == 1 and randf() < 0.5:
			_playback.play_stream(_drum_hi, 0, -12.0, randf_range(0.95, 1.1))
		if randf() < 0.35:
			_melody_note(-8.0, 1.0)
		return
	# Calm map / menu music
	if pos == 0:
		_playback.play_stream(_notes[0], 0, -6.0, 0.25)
		_playback.play_stream(_notes[3], 0, -10.0, 0.25)
	if pos == 8 and randf() < 0.6:
		_playback.play_stream(_notes[[0, 2, 3].pick_random()], 0, -9.0, 0.25)
	if _phrase_rest > 0:
		_phrase_rest -= 1
		return
	var chance := 0.6 if pos % 2 == 0 else 0.18
	if randf() < chance:
		_melody_note(-7.0, 0.5 if randf() < 0.75 else 1.0)
	if pos == 15 and randf() < 0.35:
		_phrase_rest = 6

func _melody_note(vol: float, octave: float) -> void:
	_melody = clampi(_melody + [-2, -1, -1, 0, 1, 1, 2].pick_random(), 0, 11)
	var degree := _melody % 5
	var oct := octave * (2.0 if _melody >= 5 else 1.0) * (2.0 if _melody >= 10 else 1.0)
	_playback.play_stream(_notes[degree], 0, vol + randf_range(-2.0, 1.0), oct)

func _pluck(freq: float, dur: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var period := maxi(2, int(RATE / freq))
	var buf := PackedFloat32Array()
	buf.resize(period)
	for i in period:
		buf[i] = randf_range(-1.0, 1.0)
	var out := PackedFloat32Array()
	out.resize(n)
	var idx := 0
	for i in n:
		var nxt := (idx + 1) % period
		var v := buf[idx]
		buf[idx] = 0.4985 * (v + buf[nxt])
		var env := minf(1.0, i / 60.0)
		out[i] = v * env * 0.6
		idx = nxt
	return _wav(out)

func _taiko(dur: float, f0: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var noise := 0.0
	for i in n:
		var x := float(i) / n
		var f := f0 * (1.0 + 1.5 * exp(-x * 30.0))
		phase += TAU * f / RATE
		noise = lerpf(noise, randf_range(-1, 1), 0.08)
		out[i] = (sin(phase) * 0.9 + noise * 0.4 * exp(-x * 20.0)) * exp(-x * 6.0)
	return _wav(out)

func _wav(data: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.data = bytes
	return s
