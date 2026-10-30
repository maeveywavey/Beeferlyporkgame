extends Node
## Loads every script so parse errors are reported (used by headless CI checks).
func _ready() -> void:
	var bad := 0
	for f in _list("res://scripts") + _list("res://tests"):
		var s = load(f)
		if s == null or (s is GDScript and not s.can_instantiate()):
			print("FAILED: ", f)
			bad += 1
	print("checked scripts, failures: ", bad)
	get_tree().quit(1 if bad > 0 else 0)

func _list(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		out.append_array(_list(dir + "/" + sub))
	return out
