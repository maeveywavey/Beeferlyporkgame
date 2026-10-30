extends Node
## Stages the Avatar's wrath on a wooded coast: a conqueror's warband meets a
## furious Avatar, who enters the Avatar State. A slow camera circles the field
## and frames are saved along the way.
##   godot --path . --write-movie out.avi --fixed-fps 30 res://tests/avatar_wrath_shot.tscn -- <out_dir>
const Roster = preload("res://scripts/core/roster.gd")
const AvatarSys = preload("res://scripts/core/avatar.gd")

var b
var t := 0.0
var out := ""
var shots := [3.0, 4.6, 5.6, 6.6, 7.6, 9.0, 11.0, 14.0]

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/avatar_wrath_shot.gd").new())
		return
	process_priority = 1000
	out = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	seed(11)
	var p := GS.create_player("Kenji", "fn_noble", "fire", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	AvatarSys.init_era("prime")
	var pp: Dictionary = GS.player_party()
	pp.roster = []
	for id in ["fn_soldier", "fn_veteran", "fn_firebender", "fn_archer"]:
		Roster.add(pp.roster, id, 14)
	var e := GS.make_party("", "The Avatar", "bandit", "avatar", Vector2.ZERO)
	e.roster = []
	Roster.add(e.roster, "avatar", 1)
	GS.pending_battle = {"enemies": [e.id], "allies": [], "siege": "", "player_attacking": true, "biome": "forest",
		"hour": 16.5, "fire_mult": 1.0, "water_mult": 1.0, "enemy_garrison": false, "ally_garrison": false, "seed": 7,
		"coast": true, "avatar": {"wrath": true, "stage": "prime", "fort": 0, "traps": 0}}
	var B = load("res://scripts/battle/battle.gd")
	B.autotest = false
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
	await get_tree().create_timer(0.3).timeout
	b = get_tree().current_scene
	get_tree().paused = false
	b.player_controlled = false
	b.cinematic = true
	b.hud.visible = false
	# the Avatar waits near the shore; the warband stands inland of it
	for u in b.team_units[1]:
		if u.troop_id == "avatar":
			u.position = Vector3(10, 0, -14)
			u.position.y = b.ground_height(u.position.x, u.position.z)
			u.root_t = 3.0
	var i := 0
	for u in b.team_units[0]:
		u.position = Vector3(-24.0 + (i % 14) * 3.4, 0, -40.0 - int(i / 14) * 2.6)
		u.position.y = b.ground_height(u.position.x, u.position.z)
		i += 1

func _process(delta: float) -> void:
	if b == null or not is_instance_valid(b) or b.cam == null:
		return
	t += delta
	var av = null
	for u in b.team_units[1]:
		if u.troop_id == "avatar":
			av = u
	var focus: Vector3 = av.position if av != null else Vector3(10, 0, -14)
	# from inland, looking out to sea past the Avatar, circling slowly
	var ang := -2.0 + t * 0.05
	var dist := 30.0 - minf(t, 6.0) * 0.8
	var shake: Vector3 = b.cam.position - b.cam.get_meta("base", b.cam.position)
	var pos := focus + Vector3(cos(ang) * dist, 8.0, sin(ang) * dist)
	b.cam.position = pos
	b.cam.look_at(focus + Vector3(0, 3.0, 0), Vector3.UP)
	b.cam.position += shake * 0.0
	if not shots.is_empty() and t >= shots[0]:
		var at: float = shots.pop_front()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/wrath_%04.1f.png" % [out, at])
	if t > 16.0:
		print("wrath shot done")
		get_tree().quit()
