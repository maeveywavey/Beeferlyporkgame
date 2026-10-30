extends Node
## Renders the battlefield look at a chosen Retro level, for comparing the
## PS1 options. Same seed every run, so shots line up.
##   godot --path . res://tests/look_shot.tscn -- <off|light|heavy> <biome> <out.png> [movie]
## With "movie", the camera orbits slowly instead of saving one frame (use
## Godot's --write-movie to capture it).
const Roster = preload("res://scripts/core/roster.gd")

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/look_shot.gd").new())
		return
	var args := OS.get_cmdline_user_args()
	var retro: String = args[0] if args.size() > 0 else "light"
	var biome: String = args[1] if args.size() > 1 else "highland"
	var out: String = args[2] if args.size() > 2 else "user://look.png"
	var movie := args.size() > 3 and args[3] == "movie"
	seed(20261030)
	var p := GS.create_player("Hotaru", "fn_deserter", "fire", Color(0.82, 0.62, 0.5), Color(0.08, 0.06, 0.05))
	GS.new_game(p)
	GS.flags.seen_help = true
	GS.settings.retro = retro
	GS.apply_settings()
	Roster.add(GS.player_party().roster, "ek_soldier", 10)
	Roster.add(GS.player_party().roster, "ek_archer", 4)
	var e := GS.make_party("", "Test", "bandit", "fire_nation", Vector2.ZERO)
	Roster.add(e.roster, "fn_soldier", 10)
	Roster.add(e.roster, "fn_archer", 4)
	GS.pending_battle = {"enemies": [e.id], "allies": [], "siege": "", "player_attacking": true, "biome": biome,
		"hour": 15.0, "fire_mult": 1.15, "water_mult": 0.95, "enemy_garrison": false, "ally_garrison": false, "seed": 7}
	var B = load("res://scripts/battle/battle.gd")
	B.autotest = false
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
	await get_tree().create_timer(0.4).timeout
	var b = get_tree().current_scene
	b.cam_pitch = -0.18
	b.cam_dist = 6.0
	b.cam_yaw = float(args[4]) if args.size() > 4 else 1.15
	get_tree().paused = false
	# "grove" / "cliff": stand a few paces from the nearest tree or cliff
	var focus: String = args[5] if args.size() > 5 else ""
	if focus != "":
		var pu = b.player_unit
		var best = null
		for o in b.obstacles:
			var want: bool = (o.r < 0.6) if focus == "grove" else (o.r > 3.0)
			if want and (best == null or Vector2(pu.position.x, pu.position.z).distance_to(o.p) < Vector2(pu.position.x, pu.position.z).distance_to(best.p)):
				best = o
		if best != null:
			var from: Vector2 = best.p + Vector2(0, -1).rotated(0.5) * (14.0 if focus == "grove" else 20.0)
			pu.position = Vector3(from.x, b.ground_height(from.x, from.y), from.y)
			var d: Vector2 = best.p - from
			b.cam_yaw = atan2(d.x, d.y) + 0.25
	if movie:
		for i in 400:
			await get_tree().process_frame
			b.cam_yaw += 0.02
		return
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
