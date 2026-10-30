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
	if mode.begins_with("walk:"):
		# walk:<sid>[:hour[:yaw[:pitch[:x,z]]]]
		var parts := mode.split(":")
		var pw := GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
		GS.new_game(pw)
		GS.flags.seen_help = true
		for cid in ["hana", "juro", "nima"]:
			GS.player.companions.append(cid)
		GS.flags.town_sid = parts[1]
		if parts.size() > 2:
			GS.hours = float(parts[2])
		load("res://scripts/town/town_scene.gd").autotest = true
		get_tree().change_scene_to_file.call_deferred("res://scenes/town.tscn")
		get_tree().create_timer(0.8).timeout.connect(func():
			var t = Engine.get_main_loop().current_scene
			if parts.size() > 3:
				t.cam_yaw = float(parts[3])
			if parts.size() > 4:
				t.cam_pitch = float(parts[4])
			if parts.size() > 5:
				var xz := parts[5].split(",")
				t.player.position = Vector3(float(xz[0]), 0, float(xz[1]))
			t.cam_dist = 7.0
			t._update_camera(1.0))
	if mode == "mounts":
		var pm := GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
		GS.new_game(pm)
		var sc := Node3D.new()
		var we := WorldEnvironment.new()
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.6, 0.72, 0.85)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.85, 0.85, 0.85)
		env.ambient_light_energy = 0.6
		we.environment = env
		sc.add_child(we)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-40, 40, 0)
		sc.add_child(sun)
		var cam := Camera3D.new()
		cam.fov = 40
		cam.transform = Transform3D(Basis(), Vector3(4.0, 3.0, 13.0)).looking_at(Vector3(1.0, 1.5, 0), Vector3.UP)
		sc.add_child(cam)
		var Mount = load("res://scripts/actors/mount.gd")
		var ActorS = load("res://scripts/actors/actor.gd")
		var Looks = load("res://scripts/actors/looks.gd")
		var UV = load("res://scripts/battle/unit_visual.gd")
		var x := -5.0
		for k in ["ostrich", "rhino", "bison"]:
			var m: Dictionary = Mount.build(k)
			m.root.position = Vector3(x, 0, 0)
			m.root.rotation.y = PI * 0.5
			sc.add_child(m.root)
			if k != "bison":
				var a = ActorS.new()
				m.root.add_child(a)
				a.setup(Looks.troop_look("ek_ostrich_rider" if k == "ostrich" else "fn_rhino_rider", RandomNumberGenerator.new()))
				a.set_stance("ride")
				a.position.y = m.seat - UV.RIDE_HIP
			x += 5.0 if k == "ostrich" else 6.5
		get_tree().root.add_child.call_deferred(sc)
	if mode.begins_with("weapons"):
		var pw2 := GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
		GS.new_game(pw2)
		var sc2 := Node3D.new()
		var we2 := WorldEnvironment.new()
		var env2 := Environment.new()
		env2.background_mode = Environment.BG_COLOR
		env2.background_color = Color(0.6, 0.72, 0.85)
		env2.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env2.ambient_light_color = Color(0.85, 0.85, 0.85)
		env2.ambient_light_energy = 0.6
		we2.environment = env2
		sc2.add_child(we2)
		var sun2 := DirectionalLight3D.new()
		sun2.rotation_degrees = Vector3(-40, 40, 0)
		sc2.add_child(sun2)
		var cam2 := Camera3D.new()
		cam2.fov = 35
		cam2.transform = Transform3D(Basis(), Vector3(1.0, 1.6, 9.5)).looking_at(Vector3(0, 1.1, 0), Vector3.UP)
		sc2.add_child(cam2)
		var UnitS = load("res://scripts/battle/unit.gd")
		var tids := ["ek_veteran", "fn_veteran", "ek_royal_guard", "tw_warden", "swt_veteran", "red_lantern_elder", "fn_archer", "an_monk"]
		var anim_name := mode.substr(8) if mode.length() > 8 else ""
		for i in tids.size():
			var u = UnitS.new()
			u.position = Vector3(-6.3 + i * 1.8, 0, 0)
			u.rotation.y = 0.35
			sc2.add_child(u)
			u.setup_troop(tids[i], 0, "x")
			u.set_physics_process(false)
			u.set_process(false)
			if anim_name != "":
				u.parts.actor.call_deferred("loop", anim_name)
		get_tree().root.add_child.call_deferred(sc2)
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
		"create", "era":
			get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
			var pg := "create" if mode == "create" else "world"
			get_tree().create_timer(0.5).timeout.connect(func():
				var mm = Engine.get_main_loop().current_scene
				mm.page = pg
				if pg == "create":
					mm.c_bend = "air"
					mm.c_background = "air_nomad"
				mm._build())
		"world", "town", "party", "encounter", "char", "factions", "people", "wars", "trade", "far", "inv", "quests", "society", "forms", "avatar", "techniques", "work", "settings", "talk":
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
			for t in ["fn_soldier", "fn_yuyan", "fn_rhino_rider", "fn_imperial_fb", "ek_soldier", "ek_ostrich_rider", "ek_royal_guard", "ek_censor", "tw_warden", "nwt_waterbender", "nwt_guard", "swt_wolf", "sand_raider", "pirate_captain", "an_master", "om_royal_guard"]:
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
			var sg := "kettle_rock" if mode == "siege" else ""
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
		"settings":
			map.open_window(load("res://scripts/ui/settings_window.gd").new())
		"talk":
			GS.player.companions = ["sayuri"]
			var dw = map.open_dialogue("talk_sayuri")
		"techniques":
			GS.player.bend = "water"
			var Tech = load("res://scripts/battle/techniques.gd")
			for id in ["w_octopus", "w_ice_lance", "w_vines", "w_chi_heal"]:
				Tech.learn(id)
			GS.player.master_title = ""
			map.open_window(load("res://scripts/ui/techniques_window.gd").new())
		"work":
			GS.player.bend = "fire"
			GS.player.companions = ["nima", "hana", "pemba"]
			var ww = load("res://scripts/ui/bending_work_window.gd").new()
			ww.sid = "senlin"
			map.open_window(ww)
		"avatar":
			var AvatarSys = load("res://scripts/core/avatar.gd")
			AvatarSys.init_era("prime")
			GS.settlements.omashu.owner = "player"
			AvatarSys.state().warned = true
			AvatarSys.state().seen = [{"sid": "gaoling", "day": -2}, {"sid": "eastern_air_temple", "day": -9}]
			AvatarSys.add_infamy(180, Vector2(900, 700))
			AvatarSys._schedule(AvatarSys.state(), "confront", 9)
			AvatarSys.state().state = "gathering"
			map.open_window(load("res://scripts/ui/avatar_window.gd").new())
		"town": map.open_settlement("omashu")
		"party": map._open_party()
		"char": map._open_character()
		"inv": map._open_inventory()
		"quests":
			var Story = load("res://scripts/story/story.gd")
			Story.apply([["journal", "ms_main", "The Drowned Testament", "Brother Norbu gave you a page of the drowned Avatar's logbook. Take it to Abbess Tsering at the Eastern Air Temple."], ["journal", "cq_hana", "Hana: The Settled Stones", "Go with Hana to the Wenlong district of Ba Sing Se's Lower Ring."]])
			map._open_quests()
		"forms":
			GS.player.bend = "water"
			GS.player.forms = [load("res://scripts/battle/forms.gd").starter("water")]
			GS.player.form_f = 0
			var fw2 = load("res://scripts/ui/forms_window.gd").new()
			map.open_window(fw2)
			fw2.draft = GS.player.forms[0].duplicate(true)
			fw2.editing = 0
			fw2.call_deferred("refresh")
		"factions", "people", "wars":
			# a few months of history first, so wars and tribute have moved
			for i in 24 * 90:
				GS.sim.advance(1.0)
			for lid in ["haoren", "hiyori", "cheng_mei", "oyama", "siqiniq", "feng_tao"]:
				GS.lords[lid].met = true
				GS.change_lord_rel(lid, randi_range(-20, 30))
			GS.player.companions = ["hana", "nima"]
			var ffw = load("res://scripts/ui/faction_window.gd").new()
			ffw.tab = mode
			ffw.selected = "earth_kingdom"
			map.open_window(ffw)
		"society":
			var fw = load("res://scripts/ui/faction_window.gd").new()
			fw.selected = "northern_water"
			fw.show_society = true
			map.open_window(fw)
		"far":
			map.cam_dist = 600.0
		"trade":
			var w = load("res://scripts/ui/trade_window.gd").new()
			w.sid = "omashu"
			map.open_window(w)
		"encounter":
			var lid: String = GS.lords["feng_tao"].party
			map._on_player_encounter(lid)
