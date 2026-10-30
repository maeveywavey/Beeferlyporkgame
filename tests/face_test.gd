extends Node3D
const CB = preload("res://scripts/actors/character_builder.gd")
const FR = preload("res://scripts/actors/face_rig.gd")
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp/claude-0/faces.png"
	var sex: String = args[1] if args.size() > 1 else "m"
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.85, 0.8, 0.7)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.9, 0.9, 0.9)
	e.ambient_light_energy = 0.55
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 25, 0)
	add_child(sun)
	var exprs := ["neutral", "happy", "laugh", "sad", "angry", "surprised", "afraid", "sleep"]
	for i in exprs.size():
		var look := CB.random_look("earth")
		look.sex = sex
		look.skin = i % 6
		look.hair = "Hair_Buzzed" if sex == "m" else "Hair_BuzzedFemale"
		look.outfit = "peasant"
		var parts := CB.build(look)
		add_child(parts.root)
		parts.root.position = Vector3((i % 4 - 1.5) * 0.36, (0.0 if i < 4 else -0.36), 0)
		parts.anim.play("ual1/A_TPose")
		parts.anim.seek(0.0, true)
		parts.anim.pause()
		FR.set_expression(parts, exprs[i])
		var l := Label3D.new()
		l.text = exprs[i]
		l.font_size = 20
		l.pixel_size = 0.0006
		l.position = parts.root.position + Vector3(0, (1.5 if sex == "m" else 1.46) + 0.02, 0.15)
		l.modulate = Color(0.1, 0.05, 0.02)
		add_child(l)
	var cam := Camera3D.new()
	add_child(cam)
	var hy := 1.68 if sex == "m" else 1.635
	cam.position = Vector3(0, hy - 0.2, 1.25)
	cam.fov = 45
	cam.look_at(Vector3(0, hy - 0.2, 0))
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
