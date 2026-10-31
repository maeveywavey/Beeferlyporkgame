extends Node
## Stages each kind of gore in front of the camera and saves a frame.
##   godot --path . res://tests/gore_shot.tscn -- <out.png>
const Roster = preload("res://scripts/core/roster.gd")
const Gore = preload("res://scripts/battle/gore.gd")

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/hud_shot.gd").new())
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
	b.feed_msg("Lee killed Fire Nation Soldier.", Color(0.8, 1, 0.8))
	b.feed_msg("Lee knocked out Fire Nation Soldier.", Color(0.8, 1, 0.8))
	b.hud_note("Blocked!")
	b._dir_t = 99.0
	b._dir_show = "right"
	b._marker_t = 99.0
	b._flash.color = Color(0.8, 0.05, 0.03, 0.2)
	b.big_label.text = "Fight!"
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	print("hud shot saved")
	get_tree().quit()
