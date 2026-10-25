extends Node3D
const Actor = preload("res://scripts/actors/actor.gd")
const CB = preload("res://scripts/actors/character_builder.gd")
var actors := []
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp/claude-0/actors.png"
	var t: float = float(args[1]) if args.size() > 1 else 1.0
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.78, 0.92)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.85, 0.9)
	e.ambient_light_energy = 0.5
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	add_child(sun)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	g.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.45, 0.6, 0.3)
	g.material_override = gm
	add_child(g)
	var setups := [["earth", "earth", "ek_hat", "ek_armor", "bend"], ["fire", "fire", "fn_helmet", "fn_armor", "bend"], ["water", "water", "", "water_fur", "bend"], ["air", "air", "air_arrow", "air_robes", "bend"], ["earth", "", "straw_hat", "", "sword"]]
	for i in setups.size():
		var S: Array = setups[i]
		var look := CB.random_look(S[0])
		look.outfit = "ranger" if S[0] != "air" else "peasant"
		look.accessory = S[2]
		look.kit = S[3]
		var a = Actor.new()
		add_child(a)
		a.setup(look)
		a.position = Vector3((i - 2) * 1.1, 0, 0)
		a.rotation.y = 0.35
		a.set_stance(S[4])
		a.bend_pose.set_form(S[1])
		a.set_expression(["determined", "angry", "thoughtful", "happy", "neutral"][i])
		actors.append(a)
	await get_tree().create_timer(0.5).timeout
	actors[0].action("ual2/OverhandThrow")
	actors[0].bend_pose.pulse("stomp")
	actors[1].action("ual1/Punch_Cross")
	actors[2].action("ual1/Spell_Simple_Shoot")
	actors[4].speed = 1.4
	await get_tree().create_timer(t).timeout
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 1.3, 4.6)
	cam.look_at(Vector3(0, 0.95, 0))
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
