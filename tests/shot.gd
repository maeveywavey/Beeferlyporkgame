extends Node
## Screenshot harness: godot --path . res://tests/shot.tscn -- <mode> <out.png> [seconds]
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "menu"
	var out: String = args[1] if args.size() > 1 else "/tmp/claude-0/shot.png"
	var secs: float = float(args[2]) if args.size() > 2 else 2.0
	match mode:
		"menu":
			get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
		"world", "town", "party", "encounter", "char", "factions", "trade":
			var p := GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
			GS.new_game(p)
			var Roster = load("res://scripts/core/roster.gd")
			Roster.add(GS.player_party().roster, "ek_soldier", 6)
			GS.player_party().roster[0].xp = 500
			get_tree().change_scene_to_file.call_deferred("res://scenes/world_map.tscn")
			if mode != "world":
				var m := mode
				get_tree().create_timer(1.0).timeout.connect(func(): _open(m))
		"battle", "siege":
			var p2 := GS.create_player("Lee", "fn_deserter", "fire", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
			GS.new_game(p2)
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
		"trade":
			var w = load("res://scripts/ui/trade_window.gd").new()
			w.sid = "omashu"
			map.open_window(w)
		"encounter":
			var lid: String = GS.lords["bumi"].party
			map._on_player_encounter(lid)
