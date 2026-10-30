extends Node
## Clicks on the map like a player would and checks travel, arrival and encounters.
func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_travel.gd").new())
		return
	var p := GS.create_player("Tester", "ek_refugee", "", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")
	await get_tree().create_timer(0.5).timeout
	var map = get_tree().current_scene
	# Click on Senlin's model
	var target: Vector3 = map.settlement_nodes["senlin"].position + Vector3(0, 2, 0)
	map.cam_dist = 300.0
	map.follow_player = false
	map.cam_target = target
	map._update_camera(0.0)
	await get_tree().process_frame
	var sp: Vector2 = map.camera.unproject_position(target)
	map._on_left_click(sp, false)
	print("target settlement: ", GS.player_party().target_settlement, " moving ", GS.player_party().moving)
	var arrived := [""]
	GS.player_arrived.connect(func(sid): arrived[0] = sid)
	var enc := [""]
	GS.player_encounter.connect(func(pid): enc[0] = pid)
	Engine.time_scale = 20.0
	var t := 0.0
	while arrived[0] == "" and enc[0] == "" and t < 60.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	Engine.time_scale = 1.0
	print("arrived: ", arrived[0], " encounter: ", enc[0], " date ", GS.date_string(), " windows open: ", map.modal_layer.get_child_count())
	# Ground click
	map.close_all_windows()
	await get_tree().process_frame
	var ground: Vector2 = map._ground_point(get_viewport().get_visible_rect().size / 2.0)
	print("ground point under screen centre: ", ground, " land ", load("res://scripts/core/terrain.gd").is_land(ground))
	get_tree().quit()
