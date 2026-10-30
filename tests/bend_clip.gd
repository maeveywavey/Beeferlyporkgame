extends Node
## Drives a short bending clip for Godot's movie writer: a firebender performs
## a designed Form (F), then Q and E, against a Fire Navy line at dusk.
##   godot --path . --write-movie out/f.png --fixed-fps 15 --quit-after 75 \
##         res://tests/bend_clip.tscn
const Roster = preload("res://scripts/core/roster.gd")
const Forms = preload("res://scripts/battle/forms.gd")

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/bend_clip.gd").new())
		return
	var p := GS.create_player("Hotaru", "fn_deserter", "fire", Color(0.82, 0.62, 0.5), Color(0.08, 0.06, 0.05))
	GS.new_game(p)
	GS.flags.seen_help = true
	GS.player.skill_bonus.bending = 7
	GS.player.forms = [Forms.starter("fire")]
	var e := GS.make_party("", "Test", "bandit", "fire_nation", Vector2.ZERO)
	Roster.add(e.roster, "fn_soldier", 8)
	Roster.add(e.roster, "fn_archer", 3)
	GS.pending_battle = {"enemies": [e.id], "allies": [], "siege": "", "player_attacking": true, "biome": "desert",
		"hour": 16.5, "fire_mult": 1.15, "water_mult": 0.95, "enemy_garrison": false, "ally_garrison": false}
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
	await get_tree().create_timer(0.3).timeout
	var b = get_tree().current_scene
	var pu = b.player_unit
	pu.max_chi = 400.0
	pu.chi = 400.0
	var t = b.find_target(pu)
	if t == null:
		return
	# face the enemy line from the opening position, camera over the shoulder
	var d: Vector3 = t.position - pu.position
	pu.position += d.normalized() * (d.length() - 16.0)
	pu.position.y = b.ground_height(pu.position.x, pu.position.z)
	b.cam_yaw = atan2(d.x, d.z)
	b.cam_pitch = -0.12
	pu.facing = b.cam_yaw
	pu.target = t
	await get_tree().create_timer(0.1).timeout
	pu.cast_form(GS.player.forms[0])
	await get_tree().create_timer(1.6).timeout
	for slot in ["q", "r", "q"]:
		t = b.find_target(pu)
		if t != null:
			pu.cooldowns.clear()
			pu.cast(slot, t.chest())
		await get_tree().create_timer(0.55).timeout
