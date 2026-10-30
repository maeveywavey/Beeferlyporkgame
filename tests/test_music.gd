extends Node
## Checks the procedural music samples are audible and not clipping.
func _ready() -> void:
	var m = load("res://scripts/autoload/music.gd").new()
	var t0 := Time.get_ticks_msec()
	var p: AudioStreamWAV = m._pluck(293.66, 1.6)
	var d: AudioStreamWAV = m._taiko(0.6, 70.0)
	print("generated in ", Time.get_ticks_msec() - t0, " ms")
	for s in [p, d]:
		var peak := 0
		var sum := 0.0
		var n: int = s.data.size() / 2
		for i in n:
			var v: int = absi(s.data.decode_s16(i * 2))
			peak = maxi(peak, v)
			sum += v
		print("samples ", n, " peak ", peak, " mean ", int(sum / n))
	m.free()
	get_tree().quit()
