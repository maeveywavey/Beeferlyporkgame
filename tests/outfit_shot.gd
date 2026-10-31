extends Node
## Lines up characters of several cultures and outfits in front of the camera,
## to judge garments and proportions: godot --path . res://tests/outfit_shot.tscn -- <out.png>
const CB = preload("res://scripts/actors/character_builder.gd")
const Actor = preload("res://scripts/actors/actor.gd")

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/outfit_shot.gd").new())
		return
	var p := GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.7)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	add_child(sun)
	var cams := Camera3D.new()
	add_child(cams)
	cams.position = Vector3(0, 1.2, 3.6)
	var specs := [["m", "peasant", "fire", "Hair_SimpleParted", "fn_armor"], ["f", "peasant", "fire", "Hair_Buns", ""], ["m", "ranger", "water", "Hair_Long", ""], ["f", "ranger", "earth", "Hair_Long", "ek_armor"], ["m", "peasant", "earth", "Hair_Buzzed", ""], ["m", "peasant", "omashu", "Hair_SimpleParted", "sash"]]
	var i := 0
	var tris := 0
	for sp in specs:
		var look := {"sex": sp[0], "outfit": sp[1], "culture": sp[2], "skin": 2, "hair": sp[3], "kit": sp[4], "beard": i == 4, "hair_color": Color(0.1, 0.07, 0.05), "height": 1.0}
		var a = Actor.new()
		add_child(a)
		a.setup(look)
		a.position = Vector3((i - 2.5) * 0.85, 0, 0)
		i += 1
	await get_tree().create_timer(0.8).timeout
	cams.look_at(Vector3(0, 0.95, 0))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	for mi in find_children("*", "MeshInstance3D", true, false):
		if mi.mesh != null and mi.name == "LowpolyOutfit":
			var t := 0
			for s in mi.mesh.get_surface_count():
				t += mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX].size() / 3
			tris = t
	print("outfit triangles (one): ", tris)
	get_tree().quit()
