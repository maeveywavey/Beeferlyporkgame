extends Node
## Builds every walkable settlement type headlessly, walks the player around,
## opens each interaction, and reports build time and frame cost.
var results := []

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_town.gd").new())
		return
	var p := GS.create_player("Tester", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	GS.player.companions = ["hana", "juro"]
	load("res://scripts/town/town_scene.gd").autotest = true
	for sid in ["ba_sing_se", "caldera", "agna_qela", "eastern_air_temple", "senlin", "pohuai", "foggy_swamp", "kyoshi_island", "omashu", "southern_tribe"]:
		GS.flags.town_sid = sid
		var t0 := Time.get_ticks_msec()
		get_tree().change_scene_to_file("res://scenes/town.tscn")
		await get_tree().process_frame
		await get_tree().process_frame
		var t = get_tree().current_scene
		var built := Time.get_ticks_msec() - t0
		# walk forward for a bit
		var t1 := Time.get_ticks_usec()
		for i in 60:
			t._move(t.player, Vector3(0, 0, -0.25))
			await get_tree().process_frame
		var frame_ms := (Time.get_ticks_usec() - t1) / 60000.0
		var opened := 0
		for it in t.layout.interacts:
			t.player.position = it.pos + Vector3(0, 0, 0.5)
			t._update_prompt()
			t._interact()
			await get_tree().process_frame
			if t.is_modal_open():
				opened += 1
			t.close_all_windows()
			await get_tree().process_frame
		print("%s: built %d ms, %.1f ms/frame, %d npcs, %d obstacles, %d/%d interactions open, player at %s" % [sid, built, frame_ms, t.npcs.size(), t.layout.obstacles.size(), opened, t.layout.interacts.size(), t.player.position])
	print("TOWN TEST DONE")
	get_tree().quit()
