extends Node
## Runs battles headlessly. Args after "--": [field|siege|arena|duel|big|bend|avatar] [element|era]
const Roster = preload("res://scripts/core/roster.gd")
var B
var mode := "field"
var elem := "fire"

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_battle.gd").new())
		return
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = args[0]
	if args.size() > 1:
		elem = args[1]
	B = load("res://scripts/battle/battle.gd")
	B.autotest = mode != "bend"
	var bg := {"fire": "fn_deserter", "earth": "ek_refugee", "water": "swt_warrior", "": "kyoshi"}
	var bend_arg := "earth" if mode == "avatar" else elem
	var p := GS.create_player("Tester", bg.get(bend_arg, "ek_refugee"), bend_arg, Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.player.skills.bending = 6
	GS.player.equip.ranged = "short_bow"
	Roster.add(GS.player_party().roster, "ek_soldier", 15)
	Roster.add(GS.player_party().roster, "ek_archer", 8)
	Roster.add(GS.player_party().roster, "ek_earthbender", 6)
	Roster.add(GS.player_party().roster, "nwt_healer", 2)
	GS.player.companions = ["hana", "pemba"]
	var e := GS.make_party("", "Test", "lord", "fire_nation", Vector2.ZERO)
	e.lord = "kuro"
	Roster.add(e.roster, "fn_soldier", 15)
	Roster.add(e.roster, "fn_firebender", 8)
	Roster.add(e.roster, "fn_archer", 6)
	Roster.add(e.roster, "fn_rhino_rider", 4)
	var sg := "pohuai" if mode == "siege" else ""
	if mode == "siege":
		GS.settings.battle_size = 120
	if mode == "big":
		GS.settings.battle_size = 200
		Roster.add(GS.player_party().roster, "ek_soldier", 80)
		Roster.add(e.roster, "fn_soldier", 80)
	GS.pending_battle = {"enemies": [e.id], "allies": [], "siege": sg, "player_attacking": true, "biome": "forest",
		"hour": 21.0, "fire_mult": 0.85, "water_mult": 1.5, "enemy_garrison": mode == "siege", "ally_garrison": false}
	if mode == "arena":
		GS.start_arena(0)
		return
	if mode == "duel":
		GS.start_duel("daisuke")
		return
	if mode == "avatar":
		# The Avatar's company against a fortified, trapped seat (elem = era)
		var AvatarSys = load("res://scripts/core/avatar.gd")
		AvatarSys.init_era(elem if elem in ["young", "prime", "elder"] else "prime")
		GS.settlements.pohuai.owner = "player"
		GS.settlements.pohuai.avatar_fort = 1
		GS.settlements.pohuai.avatar_traps = 2
		GS.player_party().pos = Data.settlements.pohuai.pos
		Roster.add(GS.player_party().roster, "chi_blocker", 6)
		AvatarSys.spawn_company()
		AvatarSys.start_battle()
		return
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
	if mode == "bend":
		await get_tree().create_timer(0.5).timeout
		await _drive()

func _drive() -> void:
	var b = get_tree().current_scene
	var pu = b.player_unit
	Engine.time_scale = 2.0
	var casts := {}
	for i in 240:
		await get_tree().create_timer(0.25).timeout
		if not is_instance_valid(pu) or not pu.alive or b.battle_over:
			break
		# move towards the nearest enemy
		var t = b.find_target(pu)
		if t == null:
			break
		var d: Vector3 = t.position - pu.position
		b.cam_yaw = atan2(d.x, d.z)
		pu.facing = b.cam_yaw
		pu.target = t
		if d.length() > 12.0:
			pu.position += d.normalized() * 1.5
		for slot in ["q", "e", "r"]:
			if pu.cast(slot, t.chest()):
				casts[slot] = casts.get(slot, 0) + 1
		if i % 6 == 0 and not GS.player.get("forms", []).is_empty():
			if pu.cast_form(GS.player.forms[0]) == "":
				casts["form"] = casts.get("form", 0) + 1
		if d.length() < 2.5:
			pu.start_attack("overhead")
		if i % 20 == 0:
			b.player_ranged_mode = true
			pu.start_aim()
			await get_tree().create_timer(0.6).timeout
			if is_instance_valid(pu) and pu.alive:
				pu.release_aim(t.chest())
			b.player_ranged_mode = false
		if i == 10:
			b._order("hold")
		if i == 30:
			b._order("follow")
		if i == 50:
			b._order("charge")
	print("casts: ", casts, " kills: ", b.player_kills, " player alive: ", is_instance_valid(pu) and pu.alive, " hp ", pu.hp)
	Engine.time_scale = 6.0
	var guard := 0
	while not b.battle_over and guard < 400:
		await get_tree().create_timer(0.5).timeout
		guard += 1
	b._finish(false)
	await get_tree().process_frame
	print("result: ", GS.last_battle_result.get("lines", []))
	get_tree().quit()
