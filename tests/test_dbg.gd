extends Node
const Roster = preload("res://scripts/core/roster.gd")
func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_dbg.gd").new())
		return
	var p := GS.create_player("Lee", "fn_deserter", "fire", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	Roster.add(GS.player_party().roster, "ek_soldier", 12)
	var e := GS.make_party("", "Test", "bandit", "fire_nation", Vector2.ZERO)
	Roster.add(e.roster, "fn_soldier", 12)
	GS.pending_battle = {"enemies": [e.id], "allies": [], "siege": "pohuai", "player_attacking": true, "biome": "grass",
		"hour": 15.0, "fire_mult": 1.15, "water_mult": 0.95, "enemy_garrison": true, "ally_garrison": false}
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
	await get_tree().create_timer(0.5).timeout
	var b = get_tree().current_scene
	var pu = b.player_unit
	print("start hp ", pu.hp, "/", pu.max_hp, " pos ", pu.position)
	pu.position = Vector3(8, b.ground_height(8, 5), 5)
	for i in 30:
		await get_tree().create_timer(0.1).timeout
		if not pu.alive or pu.hp < pu.max_hp:
			print("t=", i * 0.1, " hp ", pu.hp, " attacker ", pu.last_attacker.display_name if pu.last_attacker else "none", " burn ", pu.burn_t)
			if not pu.alive:
				break
	get_tree().quit()
