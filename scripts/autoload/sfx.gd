extends Node
## Procedurally generated sound effects so the project needs no audio files.

const RATE := 22050

var streams := {}
var _pool: Array = []

func _ready() -> void:
	streams.hit = _noise_burst(0.12, 0.9, 900.0)
	streams.block = _tone_burst(0.1, 1400.0, 0.6, true)
	streams.clank = _tone_burst(0.22, 1900.0, 0.9, true)
	streams.thud = _thump(0.16, 140.0, 0.95)
	streams.swing = _sweep_noise(0.22, 0.35)
	streams.fire = _crackle(0.45, 0.6)
	streams.earth = _thump(0.35, 70.0, 0.9)
	streams.water = _sweep_noise(0.35, 0.5, true)
	streams.air = _sweep_noise(0.3, 0.45)
	streams.bow = _tone_burst(0.15, 220.0, 0.5, false)
	streams.click = _tone_burst(0.04, 900.0, 0.3, false)
	streams.death = _thump(0.4, 110.0, 0.6)
	streams.horn = _horn(1.2)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)

func play(name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not streams.has(name):
		return
	for p in _pool:
		if not p.playing:
			p.stream = streams[name]
			p.volume_db = volume_db
			p.pitch_scale = pitch * randf_range(0.92, 1.08)
			p.play()
			return

## Positional sound inside the current 3D scene.
func play_at(name: String, pos: Vector3, volume_db: float = 0.0) -> void:
	if not streams.has(name):
		return
	var scene := get_tree().current_scene
	if scene == null or not (scene is Node3D):
		play(name, volume_db)
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = streams[name]
	p.volume_db = volume_db
	p.unit_size = 8.0
	p.max_distance = 80.0
	p.pitch_scale = randf_range(0.9, 1.1)
	scene.add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)

func _make(data: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		var v := int(clampf(data[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	return s

func _noise_burst(dur: float, vol: float, lp: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var d := PackedFloat32Array()
	d.resize(n)
	var prev := 0.0
	var a := clampf(lp / RATE * 6.0, 0.01, 1.0)
	for i in n:
		var env := pow(1.0 - float(i) / n, 3.0)
		prev = lerpf(prev, randf_range(-1, 1), a)
		d[i] = prev * env * vol * 2.0
	return _make(d)

func _tone_burst(dur: float, freq: float, vol: float, metallic: bool) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var d := PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := pow(1.0 - float(i) / n, 2.0)
		var v := sin(TAU * freq * t)
		if metallic:
			v += 0.6 * sin(TAU * freq * 2.76 * t) + 0.4 * sin(TAU * freq * 5.4 * t)
		d[i] = v * env * vol * 0.5
	return _make(d)

func _sweep_noise(dur: float, vol: float, wet: bool = false) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var d := PackedFloat32Array()
	d.resize(n)
	var prev := 0.0
	for i in n:
		var x := float(i) / n
		var env := sin(PI * x)
		var a := lerpf(0.05, 0.4, x) if not wet else 0.15 + 0.1 * sin(x * 40.0)
		prev = lerpf(prev, randf_range(-1, 1), a)
		d[i] = prev * env * vol * 2.0
	return _make(d)

func _crackle(dur: float, vol: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var d := PackedFloat32Array()
	d.resize(n)
	var prev := 0.0
	for i in n:
		var x := float(i) / n
		var env := (1.0 - x) * minf(1.0, x * 20.0)
		prev = lerpf(prev, randf_range(-1, 1), 0.3)
		var pop := randf_range(-1, 1) if randf() < 0.01 else 0.0
		d[i] = (prev * 0.8 + pop) * env * vol
	return _make(d)

func _thump(dur: float, freq: float, vol: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var d := PackedFloat32Array()
	d.resize(n)
	var prev := 0.0
	for i in n:
		var t := float(i) / RATE
		var x := float(i) / n
		var env := pow(1.0 - x, 2.5)
		var f := freq * (1.0 - 0.5 * x)
		prev = lerpf(prev, randf_range(-1, 1), 0.05)
		d[i] = (sin(TAU * f * t) * 0.8 + prev * 0.6) * env * vol
	return _make(d)

func _horn(dur: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var d := PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t := float(i) / RATE
		var x := float(i) / n
		var env := minf(1.0, x * 8.0) * minf(1.0, (1.0 - x) * 4.0)
		var f := 146.8
		var v := sin(TAU * f * t) + 0.5 * sin(TAU * f * 2.0 * t) + 0.3 * sin(TAU * f * 3.0 * t)
		d[i] = v * env * 0.25
	return _make(d)
