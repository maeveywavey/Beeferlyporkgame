extends Node
## Screenshot harness: godot --path . res://tests/shot.tscn -- <mode> <out.png> [seconds]
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "menu"
	var out: String = args[1] if args.size() > 1 else "/tmp/claude-0/shot.png"
	var secs: float = float(args[2]) if args.size() > 2 else 2.0
	if mode.begins_with("look:"):
		var sid := mode.substr(5)
		var pl := GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
		GS.new_game(pl)
		GS.flags.seen_help = true
		GS.player_party().pos = Data.settlements[sid].pos + Vector2(10, 14)
		get_tree().change_scene_to_file.call_deferred("res://scenes/world_map.tscn")
		get_tree().create_timer(0.8).timeout.connect(func():
			var m = Engine.get_main_loop().current_scene
			m.cam_dist = 55.0
			m.cam_yaw = 0.5)
	if mode.begins_with("dlg:"):
		var did := mode.substr(4)
		var pd := GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
		GS.new_game(pd)
		GS.flags.seen_help = true
		for cid in Data.companions:
			GS.player.companions.append(cid)
		get_tree().change_scene_to_file.call_deferred("res://scenes/world_map.tscn")
		get_tree().create_timer(1.0).timeout.connect(func():
			var m = Engine.get_main_loop().current_scene
			var w = m.open_dialogue(did)
			var steps := int(args[3]) if args.size() > 3 else 0
			for i in steps:
				var node: Dictionary = w.dlg.nodes[w.node_id]
				w._go(node.get("next", "") if not node.has("choices") else node.choices[0].get("next", ""), []))
	match mode:
		"menu":
			get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
		"create":
			get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
			get_tree().create_timer(0.5).timeout.connect(func():
				var mm = Engine.get_main_loop().current_scene
				mm.page = "create"
				mm._build())
		"world", "town", "party", "encounter", "char", "factions", "trade", "far", "inv":
			var p := GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
			GS.new_game(p)
			GS.flags.seen_help = true
			var Roster = load("res://scripts/core/roster.gd")
			Roster.add(GS.player_party().roster, "ek_soldier", 6)
			GS.player_party().roster[0].xp = 500
			get_tree().change_scene_to_file.call_deferred("res://scenes/world_map.tscn")
			if mode != "world":
				var m := mode
				get_tree().create_timer(1.0).timeout.connect(func(): _open(m))
		"gallery":
			var pg := GS.create_player("Lee", "fn_deserter", "fire", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
			GS.new_game(pg)
			GS.flags.seen_help = true
			GS.player.equip.mount = "komodo_rhino"
			var Roster2 = load("res://scripts/core/roster.gd")
			var eg := GS.make_party("", "Gallery", "bandit", "fire_nation", Vector2.ZERO)
			for t in ["fn_soldier", "fn_yuyan", "fn_rhino_rider", "fn_imperial_fb", "ek_soldier", "ek_ostrich_rider", "ek_royal_guard", "ek_dai_li", "ky_warrior", "nwt_waterbender", "nwt_guard", "swt_wolf", "sand_raider", "pirate_captain", "an_master", "om_royal_guard"]:
				Roster2.add(eg.roster, t, 1)
			GS.pending_battle = {"enemies": [eg.id], "allies": [], "siege": "", "player_attacking": true, "biome": "grass",
				"hour": 13.0, "fire_mult": 1.15, "water_mult": 0.95, "enemy_garrison": false, "ally_garrison": false}
			get_tree().change_scene_to_file.call_deferred("res://scenes/battle.tscn")
			get_tree().create_timer(0.6).timeout.connect(func():
				var b = Engine.get_main_loop().current_scene
				b.paused = true
				var i := 0
				var en: Array = b.team_units[1].duplicate()
				for u in en:
					var col := i % 8
					var row := int(i / 8)
					u.position = Vector3((col - 3.5) * 2.4, 0, -40.0 + row * 4.0)
					u.position.y = b.ground_height(u.position.x, u.position.z)
					u.facing = PI
					u.rotation.y = PI
					i += 1
				var pu = b.player_unit
				pu.position = Vector3(0, b.ground_height(0, -52), -52)
				b.cam_yaw = 0.0
				b.cam_pitch = -0.12
				b.cam_dist = 6.0
				# a few bending effects in flight
				en[3].cast("q", pu.chest())
				en[7].cast("e", pu.position)
				en[9].cast("q", pu.chest())
				en[14].cast("q", pu.chest())
				b.paused = false
				Engine.time_scale = 0.05)
		"arena":
			var pa := GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
			GS.new_game(pa)
			GS.flags.seen_help = true
			GS.start_arena.call_deferred(3)
		"battle", "siege":
			var p2 := GS.create_player("Lee", "fn_deserter", "fire", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
			GS.new_game(p2)
			GS.flags.seen_help = true
			var Roster = load("res://scripts/core/roster.gd")
			Roster.add(GS.player_party().roster, "ek_soldier", 12)
			Roster.add(GS.player_party().roster, "ek_archer", 6)
			Roster.add(GS.player_party().roster, "ek_ostrich_rider", 4)
			var e := GS.make_party("", "Test", "bandit", "fire_nation", Vector2.ZERO)
			Roster.add(e.roster, "fn_soldier", 12)
			Roster.add(e.roster, "fn_firebender", 8)
			Roster.add(e.roster, "fn_rhino_rider", 3)
			var sg := "pohuai" if mode == "siege" else ""
			GS.pending_battle = {"enemies": [e.id], "allies": [], "siege": sg, "player_attacking": true, "biome": "grass",
				"hour": 15.0, "fire_mult": 1.15, "water_mult": 0.95, "enemy_garrison": mode == "siege", "ally_garrison": false}
			get_tree().change_scene_to_file.call_deferred("res://scenes/battle.tscn")
			if mode == "siege":
				get_tree().create_timer(1.0).timeout.connect(func():
					var b = Engine.get_main_loop().current_scene
					b.cam_pitch = -0.45
					b.cam_dist = 12.0
					b.player_unit.position = Vector3(8, b.ground_height(8, 5), 5))
	var sn = load("res://tests/snapper.gd").new()
	sn.out = out
	sn.secs = secs
	get_tree().root.add_child.call_deferred(sn)

static func _open(mode: String) -> void:
	var map = Engine.get_main_loop().current_scene
	match mode:
		"town": map.open_settlement("omashu")
		"party": map._open_party()
		"char": map._open_character()
		"factions": map._open_factions()
		"inv": map._open_inventory()
		"far":
			map.cam_dist = 600.0
		"trade":
			var w = load("res://scripts/ui/trade_window.gd").new()
			w.sid = "omashu"
			map.open_window(w)
		"encounter":
			var lid: String = GS.lords["feng_tao"].party
			map._on_player_encounter(lid)
