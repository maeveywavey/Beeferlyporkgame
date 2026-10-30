extends Node
## Stages each kind of gore in front of the camera and saves a frame.
##   godot --path . res://tests/gore_shot.tscn -- <out.png>
const Roster = preload("res://scripts/core/roster.gd")
const Gore = preload("res://scripts/battle/gore.gd")

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/gore_shot.gd").new())
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
	var foes: Array = b.team_units[1].duplicate()
	var hints := ["blade", "impale", "fire", "fall", "water_slice", "blade"]
	for i in mini(foes.size(), hints.size()):
		var f = foes[i]
		f.position = u.position + u.forward() * (3.2 + (i % 2) * 1.6) + u.forward().rotated(Vector3.UP, PI / 2) * (float(i) - 2.5) * 1.1
		f.position.y = b.ground_height(f.position.x, f.position.z)
		f.root_t = 999.0
		if hints[i] == "fire":
			f.burn_t = 6.0
			f.burn_dps = 2.0
			f.char_amt = 0.9
		f.gore_hint = hints[i]
		f.apply_damage(9999.0, u, "cut" if hints[i] in ["blade", "water_slice"] else "blunt", Vector3.ZERO, 0.0, true)
	b.cam_dist = 1.6
	b.cam_pitch = -0.32
	var d: Vector3 = u.forward()
	b.cam_yaw = atan2(d.x, d.z)
	await get_tree().create_timer(2.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	print("gore shot saved")
	get_tree().quit()
