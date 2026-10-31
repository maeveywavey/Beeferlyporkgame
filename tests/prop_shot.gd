extends Node
## A lineup of prop models: godot --path . res://tests/prop_shot.tscn -- <out.png> <glb dir> <first> <last>
func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/prop_shot.gd").new())
		return
	var a := OS.get_cmdline_user_args()
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.6, 0.7, 0.8)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.7)
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	add_child(sun)
	var names: PackedStringArray = a[1].split(",")
	var i := 0
	for n in names:
		var ps: PackedScene = load(n)
		var r: Node3D = ps.instantiate()
		r.position = Vector3(i * float(a[2]), 0, 0)
		add_child(r)
		i += 1
	var cam := Camera3D.new()
	add_child(cam)
	var mid := (names.size() - 1) * float(a[2]) * 0.5
	cam.position = Vector3(mid, float(a[3]), float(a[4]))
	cam.look_at(Vector3(mid, float(a[3]) * 0.6, 0))
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(a[0])
	get_tree().quit()
