extends Node
## Lingering bending: fire catches and spreads on dry grass and leaves
## scorch; water puts it out and soaks people; stone walls and pillars stay.
##   godot --headless --path . res://tests/test_field.tscn
const Roster = preload("res://scripts/core/roster.gd")
const Bending = preload("res://scripts/battle/bending.gd")
const Tech = preload("res://scripts/battle/techniques.gd")
var errors := 0

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_field.gd").new())
		return
	seed(11)
	var p := GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	Roster.add(GS.player_party().roster, "ek_soldier", 4)
	var e := GS.make_party("", "Test", "bandit", "fire_nation", Vector2.ZERO)
	Roster.add(e.roster, "fn_soldier", 6)
	GS.pending_battle = {"enemies": [e.id], "allies": [], "siege": "", "player_attacking": true, "biome": "grass",
		"hour": 13.0, "fire_mult": 1.0, "water_mult": 1.0, "enemy_garrison": false, "ally_garrison": false, "seed": 3}
	var B = load("res://scripts/battle/battle.gd")
	B.autotest = false
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
	await get_tree().create_timer(0.5).timeout
	var b = get_tree().current_scene
	get_tree().paused = false
	b.player_controlled = false
	var f = b.field
	if f == null:
		_err("no field effects node")
		return _done()
	f.rain = false
	f.wet.fill(0.0)
	var u = b.player_unit
	var at: Vector3 = u.position + u.forward() * 6.0
	# fire on dry grass
	for k in 8:
		f.fuel[f._idx(at + Vector3(k, 0, 0))] = 1.0
	var lit: int = f.ignite(at, 2.0, 2.0)
	if lit == 0:
		_err("fire did not catch on dry grass")
	var start: int = f.burning_cells()
	await get_tree().create_timer(6.0).timeout
	print("fire: lit %d, burning %d after 6 s, scorched %d" % [start, f.burning_cells(), f._scorch_mm.visible_instance_count])
	# water puts it out
	f.soak(at, 4.0)
	await get_tree().process_frame
	var left := 0
	for i in f._fire_nodes:
		if f._center(i).distance_to(at) < 3.0:
			left += 1
	if left > 0:
		_err("soaking left %d fires burning" % left)
	if not f.is_wet(at):
		_err("soaked ground is not wet")
	# a stone pillar stays, a stone wall stays past its old lifetime
	var pillar: Dictionary = Tech.TECHNIQUES.e_pillar.ability
	b.execute_bending(u, pillar, u.position + u.forward() * 8.0)
	var wall: Dictionary = Bending.ability("earth", "e")
	b.execute_bending(u, wall, u.position + u.forward() * 4.0)
	var n_struct: int = f.structures.size()
	await get_tree().create_timer(14.0).timeout
	b._update_walls()
	var pillars: int = b.walls.filter(func(w): return w.get("pillar", false)).size()
	print("structures %d, walls standing %d (pillars %d)" % [n_struct, b.walls.size(), pillars])
	if pillars < 1:
		_err("the pillar did not stay")
	if b.walls.size() < 2:
		_err("the stone wall fell after its old lifetime")
	# lightning through water
	var foe = null
	for x in b.team_units[1]:
		if x.alive:
			foe = x
			break
	if foe != null:
		u.bend = "fire"
		foe.wet_t = 10.0
		var hp0: float = foe.hp
		b.execute_bending(u, Bending.ability("fire", "r"), foe.chest())
		print("lightning on a wet foe: %.0f -> %.0f" % [hp0, foe.hp])
	if OS.get_cmdline_user_args().size() > 0:
		# screenshot mode: frame the burning field, the pillar and the wall
		b.cam_dist = 9.0
		b.cam_pitch = -0.3
		f.ignite(u.position + u.forward() * 10.0 + u.forward().rotated(Vector3.UP, 1.4) * 3.0, 3.0, 2.0)
		f.soak(u.position + u.forward() * 5.0 + u.forward().rotated(Vector3.UP, -1.4) * 3.0, 2.5)
		await get_tree().create_timer(2.5).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	_done()

func _err(m: String) -> void:
	errors += 1
	print("ERROR: ", m)

func _done() -> void:
	print("FIELD TEST DONE, errors: ", errors)
	get_tree().quit()
