extends Node
## End-to-end flows: battle -> world map with results, siege defence,
## mounted player, defeat and captivity, load from save.
const Roster = preload("res://scripts/core/roster.gd")

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_flows.gd").new())
		return
	var B = load("res://scripts/battle/battle.gd")
	B.autotest = true
	B.autotest_return = true
	var p := GS.create_player("Tester", "swt_warrior", "water", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	GS.player.equip.mount = "ostrich_horse"
	Roster.add(GS.player_party().roster, "swt_warrior", 25)
	Roster.add(GS.player_party().roster, "swt_boomerang", 10)
	# 1. Siege defence at the Southern Water Tribe
	var sid := "southern_tribe"
	GS.player_party().pos = Data.settlements[sid].pos
	var e := GS.make_party("", "Raiders", "lord", "fire_nation", Data.settlements[sid].pos + Vector2(3, 0))
	e.lord = "zhao"
	e.besieging = sid
	Roster.add(e.roster, "fn_soldier", 20)
	Roster.add(e.roster, "fn_firebender", 10)
	GS.settlements[sid].siege = {"faction": "fire_nation", "leader": e.id, "hours": 5.0}
	GS.start_battle([e.id], [], sid, false)
	await _wait_world()
	var map = get_tree().current_scene
	print("1. back on map: ", map.name, " windows: ", map.modal_layer.get_child_count(), " siege now: ", GS.settlements[sid].siege, " owner ", GS.settlements[sid].faction)
	if map.modal_layer.get_child_count() > 0:
		print("   result: ", map.modal_layer.get_child(0).result.get("lines", []))
	# 2. Defeat and captivity
	var e2 := GS.make_party("", "Overwhelming", "lord", "fire_nation", GS.player_party().pos)
	e2.lord = "ozai"
	Roster.add(e2.roster, "fn_imperial_fb", 60)
	GS.pending_battle = {"enemies": [e2.id], "allies": [], "siege": "", "player_attacking": false}
	GS.finish_battle(false, {}, true, [])
	print("2. captive until ", GS.player.captive_until, " now ", GS.hours, " troops left ", Roster.total(GS.player_party().roster))
	var guard := 0
	while GS.player.captive_until > 0.0 and guard < 200:
		GS.sim.advance(1.0)
		guard += 1
	print("   escaped after ", guard, " hours: ", GS.player.captive_until)
	# 3. Save / load through the main menu path
	GS.save_game()
	GS.game_active = false
	print("3. load: ", GS.load_game(), " active ", GS.game_active)
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")
	await get_tree().create_timer(0.5).timeout
	print("   map after load: ", get_tree().current_scene.name)
	print("FLOWS DONE")
	get_tree().quit()

func _wait_world() -> void:
	var t := 0.0
	while t < 120.0:
		await get_tree().process_frame
		t += get_process_delta_time() / maxf(0.01, Engine.time_scale)
		var cs = get_tree().current_scene
		if cs != null and cs.name == "world_map":
			await get_tree().create_timer(0.3).timeout
			return
