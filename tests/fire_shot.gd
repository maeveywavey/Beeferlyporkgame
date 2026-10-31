extends Node
## Stages each kind of gore in front of the camera and saves a frame.
##   godot --path . res://tests/fire_shot.tscn -- <out.png>
const Roster = preload("res://scripts/core/roster.gd")
const Gore = preload("res://scripts/battle/gore.gd")

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/fire_shot.gd").new())
		return
	seed(5)
	var p := GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	var e := GS.make_party("", "Test", "bandit", "fire_nation", Vector2.ZERO)
	Roster.add(e.roster, "fn_soldier", 8)
	GS.pending_battle = {"enemies": [e.id], "allies": [], "siege": "", "player_attacking": true, "biome": "grass",
		"hour": 13.0, "fire_mult": 1.0, "water_mult": 1.0, "enemy_garrison": false, "ally_garrison": false, "seed": 3}
	var B = load("res://scripts/battle/battle.gd")
	B.autotest = false
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
	await get_tree().create_timer(0.6).timeout
	var b = get_tree().current_scene
	get_tree().paused = false
	b.player_controlled = false
	var u = b.player_unit
	u.root_t = 999.0
	for a in b.team_units[0]:
		if a != u:
			a.position += Vector3(30, 0, 30)
			a.root_t = 999.0
	var FS = load("res://scripts/battle/flame_sprite.gd")
	var fwd: Vector3 = u.forward()
	var side: Vector3 = fwd.rotated(Vector3.UP, PI / 2)
	b.field.fuel.fill(0.9)
	for i in 14:
		b.field.ignite(u.position + fwd * (7.0 + randf() * 5.0) + side * randf_range(-5, 5), 1.0, 1.5)
	var foes: Array = b.team_units[1].duplicate()
	for i in mini(foes.size(), 3):
		foes[i].position = u.position + fwd * 5.0 + side * (float(i) - 1.0) * 2.5
		foes[i].root_t = 999.0
		foes[i].burn_t = 8.0
		foes[i].burn_dps = 0.3
	b._cone_fx(u, {"fx": "fire", "range": 9.0, "angle": 50.0, "breath": true})
	var fb = FS.make("fireball", Vector2(2.4, 2.4), false, 3)
	b.add_child(fb)
	fb.global_position = u.position + fwd * 3.0 + side * 2.0 + Vector3(0, 1.4, 0)
	fb.rotation.y = atan2(side.x, side.z) + PI
	var fb2 = FS.make("fireball", Vector2(2.4, 2.4), true, 3)
	b.add_child(fb2)
	fb2.global_position = u.position + fwd * 3.0 - side * 2.0 + Vector3(0, 1.4, 0)
	fb2.rotation.y = atan2(fwd.x, fwd.z)
	b.cam_dist = 3.0
	b.cam_pitch = -0.2
	b.cam_yaw = atan2(fwd.x, fwd.z)
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	print("fire shot saved")
	get_tree().quit()
