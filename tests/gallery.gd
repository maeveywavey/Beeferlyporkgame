extends Node3D
## Static model gallery for visual checks: godot res://tests/gallery.tscn -- out.png [set]
const UnitModel = preload("res://scripts/battle/unit_model.gd")
const MB = preload("res://scripts/world/map_builder.gd")

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp/claude-0/gallery.png"
	var set_name: String = args[1] if args.size() > 1 else "a"
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.7, 0.85)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)
	var ground := MB.box(Vector3(60, 0.1, 30), Color(0.4, 0.55, 0.3), Vector3(0, -0.05, 0))
	add_child(ground)
	var ids := []
	match set_name:
		"a": ids = ["fn_conscript", "fn_soldier", "fn_veteran", "fn_yuyan", "fn_firebender", "fn_imperial_fb", "fn_rhino_rider", "ek_peasant", "ek_soldier", "ek_veteran", "ek_ostrich_rider", "ek_royal_guard"]
		"b": ids = ["ek_earthbender", "ek_censor", "tw_warden", "tw_captain", "nwt_hunter", "nwt_guard", "nwt_waterbender", "nwt_healer", "swt_warrior", "swt_wolf", "swt_boomerang", "sw_swampbender"]
		"c": ids = ["sand_raider", "pirate", "pirate_captain", "fn_deserter", "red_lantern", "mountain_bandit", "rough_rhino", "an_master", "an_monk", "om_royal_guard", "nwt_moon_guard", "merc_swordsman"]
	for i in ids.size():
		var t: Dictionary = Data.troop(ids[i])
		var parts := UnitModel.build(t.look, t.weapon, t.ranged, t.shield, t.mount, Color(0.85, 0.68, 0.52), Color(0.1, 0.07, 0.05))
		var root: Node3D = parts.root
		add_child(root)
		var col := i % 6
		var row := int(i / 6)
		root.position = Vector3((col - 2.5) * 2.6, 0, row * -4.0)
		root.rotation.y = 0.35
		var poses := [Vector3(-30, 0, 0), Vector3(-160, 0, 0), Vector3(-90, 0, 0), Vector3(-80, 0, -90)]
		parts.arm_r.rotation_degrees = poses[i % 4]
		if t.shield:
			parts.arm_l.rotation_degrees = Vector3(-55, 0, -25)
		var lbl := Label3D.new()
		lbl.text = t.name
		lbl.font_size = 28
		lbl.pixel_size = 0.008
		lbl.position = root.position + Vector3(0, 2.6 + parts.seat, 0)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(lbl)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 3.2, 7.0)
	cam.look_at(Vector3(0, 1.0, -2.0))
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
