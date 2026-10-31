extends Node
## Stages the TASK 16 fire placeholder and saves frames.
##   godot --path . res://tests/fire_shot.tscn -- attack <out.png>
##   godot --path . res://tests/fire_shot.tscn -- campfire <out.png>
## attack:   a firebender's breath cone, a fire wave, fireballs and burning foes
##           among field fires.
## campfire: one standing campfire built here (the game has none; see the TASK 16
##           report), lit by the same placeholder source.
const Roster = preload("res://scripts/core/roster.gd")
const FirePlaceholder = preload("res://scripts/battle/fire_placeholder.gd")

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/fire_shot.gd").new())
		return
	seed(5)
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "attack"
	var out: String = args[1] if args.size() > 1 else "/tmp/claude-0/fire_%s.png" % mode
	var p := GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	var e := GS.make_party("", "Test", "bandit", "fire_nation", Vector2.ZERO)
	Roster.add(e.roster, "fn_soldier", 8)
	GS.pending_battle = {"enemies": [e.id], "allies": [], "siege": "", "player_attacking": true, "biome": "grass",
		"hour": 13.0, "fire_mult": 1.0, "water_mult": 1.0, "enemy_garrison": false, "ally_garrison": false, "seed": 3}
	var B = load("res://scripts/battle/battle.gd")
	B.autotest = false
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
	await get_tree().create_timer(0.6).timeout
	var b = get_tree().current_scene
	get_tree().paused = false
	b.player_controlled = false
	var u = b.player_unit
	u.root_t = 999.0
	for a in b.team_units[0]:
		if a != u:
			a.position += Vector3(30, 0, 30)
			a.root_t = 999.0
	var fwd: Vector3 = u.forward()
	var side: Vector3 = fwd.rotated(Vector3.UP, PI / 2)
	if mode == "campfire":
		# the camp is staged with nobody in shot but the fire
		u.parts.actor.visible = false
		b.field.rain = false
		_campfire(b, u.position + fwd * 4.0)
		b.cam_dist = 3.5
		b.cam_pitch = -0.1
		b.cam_yaw = atan2(fwd.x, fwd.z)
		b.field.fuel.fill(0.0)
	else:
		b.field.rain = false
		b.field.fuel.fill(0.9)
		for i in 14:
			b.field.ignite(u.position + fwd * (7.0 + randf() * 5.0) + side * randf_range(-5, 5), 1.0, 1.5)
		var foes: Array = b.team_units[1].duplicate()
		for i in mini(foes.size(), 3):
			foes[i].position = u.position + fwd * 5.0 + side * (float(i) - 1.0) * 2.5
			foes[i].root_t = 999.0
			foes[i].burn_t = 8.0
			foes[i].burn_dps = 0.3
		b._cone_fx(u, {"fx": "fire", "range": 9.0, "angle": 50.0, "breath": true})
		b.cam_dist = 3.0
		b.cam_pitch = -0.2
		b.cam_yaw = atan2(fwd.x, fwd.z)
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("fire shot saved: ", out)
	get_tree().quit()

## A standing campfire: a ring of stones, three logs and a placeholder source.
func _campfire(b: Node, at: Vector3) -> void:
	var root := Node3D.new()
	root.position = Vector3(at.x, b.ground_height(at.x, at.z), at.z)
	b.add_child(root)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.36, 0.34, 0.31)
	stone.roughness = 1.0
	for k in 9:
		var a := TAU * k / 9.0
		var m := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(0.28, 0.2, 0.22)
		m.mesh = bx
		m.material_override = stone
		m.position = Vector3(cos(a) * 0.62, 0.1, sin(a) * 0.62)
		m.rotation.y = -a
		root.add_child(m)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.22, 0.14, 0.08)
	wood.roughness = 1.0
	for k in 3:
		var m := MeshInstance3D.new()
		var cy := CylinderMesh.new()
		cy.top_radius = 0.07
		cy.bottom_radius = 0.07
		cy.height = 0.9
		m.mesh = cy
		m.material_override = wood
		m.position = Vector3(0, 0.1, 0)
		m.rotation = Vector3(0.12, TAU * k / 3.0 + 0.4, PI / 2.0 - 0.08)
		root.add_child(m)
	FirePlaceholder.source(root, Vector3(0, 0.15, 0), 12.0, 0.5, 0.9, 1.3, 0.3)
