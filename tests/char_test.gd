extends Node3D
const CB = preload("res://scripts/actors/character_builder.gd")
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp/claude-0/chars.png"
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
	sun.light_energy = 1.2
	add_child(sun)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	g.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.45, 0.6, 0.3)
	g.material_override = gm
	add_child(g)
	var set := OS.get_cmdline_user_args()[1] if OS.get_cmdline_user_args().size() > 1 else "a"
	var lineup := [
		["fire", "ranger", "m", "fn_helmet", "fn_armor", "ual1/Punch_Cross"],
		["earth", "ranger", "f", "ek_hat", "ek_armor", "ual2/Sword_Regular_A"],
		["air", "peasant", "f", "air_arrow", "air_robes", "ual1/Spell_Simple_Shoot"],
		["water", "ranger", "m", "parka", "water_fur", "ual1/Idle"],
		["hamakaze", "ranger", "f", "hamakaze", "tide_armor", "ual2/Sword_Block"],
		["earth", "ranger", "m", "censor", "censor_robe", "ual1/Spell_Simple_Idle"],
		["south", "ranger", "m", "wolf", "water_fur", "ual2/OverhandThrow"],
		["sand", "peasant", "f", "sand_wrap", "sash", "ual1/Walk"],
	]
	if set == "b":
		lineup = [
			["fire", "peasant", "f", "fn_noble", "sash", "ual1/Idle_Talking"],
			["earth", "peasant", "m", "straw_hat", "", "ual2/Farm_Harvest"],
			["air", "peasant", "m", "air_arrow", "air_robes", "ual1/Idle"],
			["water", "peasant", "f", "", "water_fur", "ual1/Idle"],
			["fire", "ranger", "m", "fn_officer", "fn_armor", "ual1/Idle"],
			["outlaw", "ranger", "m", "bandana", "", "ual2/Melee_Hook"],
			["earth", "ranger", "f", "ek_helm", "ek_armor", "ual1/Idle"],
			["fire", "ranger", "f", "yuyan", "fn_armor", "ual1/Idle"],
		]
	for i in lineup.size():
		var L: Array = lineup[i]
		var look := CB.random_look(L[0])
		look.outfit = L[1]
		look.sex = L[2]
		look.accessory = L[3]
		look.kit = L[4]
		if look.sex == "f" and look.hair == "Hair_Long" and L[3] != "":
			look.hair = "Hair_Buns"
		var parts := CB.build(look)
		var r: Node3D = parts.root
		add_child(r)
		r.position = Vector3((i - 3.5) * 0.95, 0, 0)
		parts.anim.play(L[5])
		parts.anim.seek(0.35, true)
		r.rotation.y = 0.3
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 1.3, 4.2)
	cam.fov = 55.0
	cam.look_at(Vector3(0, 1.05, 0))
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
