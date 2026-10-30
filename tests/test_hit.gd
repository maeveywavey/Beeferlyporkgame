extends Node
const Roster = preload("res://scripts/core/roster.gd")
func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_hit.gd").new())
		return
	var p := GS.create_player("Tester", "fn_deserter", "fire", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.player.equip.ranged = "short_bow"
	var e := GS.make_party("", "Test", "bandit", "fire_nation", Vector2.ZERO)
	Roster.add(e.roster, "fn_soldier", 1)
	GS.pending_battle = {"enemies": [e.id], "allies": [], "siege": "", "player_attacking": true, "biome": "grass",
		"hour": 12.0, "fire_mult": 1.0, "water_mult": 1.0, "enemy_garrison": false, "ally_garrison": false}
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
	await get_tree().create_timer(0.3).timeout
	var b = get_tree().current_scene
	var pu = b.player_unit
	var en = b.team_units[1][0]
	en.set_physics_process(false)
	# freeze enemy AI by making it hold far away
	for trial in ["q", "arrow", "melee"]:
		en.position = pu.position + Vector3(0, 0, 10 if trial != "melee" else 1.2)
		en.position.y = b.ground_height(en.position.x, en.position.z)
		en.hp = en.max_hp
		en.order = "hold"
		en.hold_pos = en.position
		pu.facing = 0.0
		b.cam_yaw = 0.0
		pu.cooldowns.clear()
		pu.action = ""
		var before: float = en.hp
		match trial:
			"q": print("cast ok: ", pu.cast("q", en.chest()))
			"arrow":
				pu.start_aim()
				await get_tree().create_timer(0.6).timeout
				print("fired: ", pu.release_aim(en.chest()))
			"melee": print("attack ok: ", pu.start_attack("overhead"))
		await get_tree().create_timer(1.2).timeout
		print(trial, ": enemy hp ", before, " -> ", en.hp, " alive ", en.alive, " dist ", pu.dist_to(en))
	get_tree().quit()
