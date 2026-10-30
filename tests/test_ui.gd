extends Node
## Opens every window and exercises the main actions to catch runtime errors.
const Roster = preload("res://scripts/core/roster.gd")
const Quests = preload("res://scripts/core/quests.gd")
const Economy = preload("res://scripts/core/economy.gd")

var map

func _ready() -> void:
	if get_tree().current_scene == self:
		# Re-launch under the root so the runner survives scene changes.
		get_tree().root.add_child.call_deferred(load("res://tests/test_ui.gd").new())
		return
	var p := GS.create_player("Tester", "merchant", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	GS.player.gold = 50000
	Roster.add(GS.player_party().roster, "ek_soldier", 20)
	Roster.add(GS.player_party().roster, "ek_veteran", 10)
	GS.player_party().roster[0].xp = 9999
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")
	await get_tree().create_timer(0.5).timeout
	map = get_tree().current_scene
	await _run()
	print("UI TEST DONE")
	get_tree().quit()

func _press_all(w: Node, skip: Array = []) -> int:
	var n := 0
	for b in w.find_children("*", "Button", true, false):
		if not is_instance_valid(b) or b.disabled:
			continue
		var t: String = b.text
		var bad := false
		for s in skip:
			if t.findn(s) >= 0:
				bad = true
		if bad:
			continue
		b.pressed.emit()
		n += 1
		await get_tree().process_frame
	return n

func _close_all() -> void:
	for c in map.modal_layer.get_children():
		c.queue_free()
	await get_tree().process_frame

func _run() -> void:
	var skip := ["Charge", "Fight", "Assault the walls!", "Break the siege", "main menu", "Load", "Back to the map", "Leave", "Done", "X", "×", "Never mind", "Farewell", "Lift", "Wait", "Rest", "Make camp", "Rest for", "Walk around"]
	# Every window type
	for wname in ["_open_party", "_open_character", "_open_inventory", "_open_quests", "_open_factions", "_open_camp"]:
		map.call(wname)
		await get_tree().process_frame
		var n = await _press_all(map.modal_layer, skip)
		print(wname, " pressed ", n)
		await _close_all()
	# The Factions menu: every faction's page, every tab
	var fw = load("res://scripts/ui/faction_window.gd").new()
	map.open_window(fw)
	await get_tree().process_frame
	for f in Data.factions:
		fw.selected = f
		fw.tab = "factions"
		fw.refresh()
		await get_tree().process_frame
	for t in ["people", "wars"]:
		fw.tab = t
		fw.refresh()
		await get_tree().process_frame
	fw.tab = "factions"
	fw.selected = "taolin"
	fw.refresh()
	await get_tree().process_frame
	print("factions menu: %d factions listed" % fw._listed().size())
	await _close_all()
	# A free community: ask for tribute, then take another by force
	var Fealty = load("res://scripts/core/fealty.gd")
	GS.player.renown = 1500
	GS.fealty.erase("taolin")
	var tries := 0
	while Fealty.overlord("taolin") != "player" and tries < 40:
		GS.flags.erase("demand_day_taolin")
		Fealty.player_demand("taolin")
		tries += 1
	print("taolin pays: ", Fealty.overlord("taolin"), " after ", tries, " asks; tribute ", Fealty.player_income())
	GS.declare_war("player", "yuhe")
	GS.player_party().pos = Data.settlements.yuhe.pos
	map.open_settlement("yuhe")
	await get_tree().process_frame
	var yw = map.modal_layer.get_child(0)
	yw._take_village()
	print("yuhe held by: ", GS.settlements.yuhe.faction, " owner ", GS.settlements.yuhe.owner)
	await _close_all()
	# Settlements of every type
	for sid in ["omashu", "fong_fortress", "senlin", "hamakaze", "taolin", "sun_city", "southern_air_temple", "red_lantern_den", "wan_shi_tong", "stonewatch", "caldera", "agna_qela"]:
		GS.player_party().pos = Data.settlements[sid].pos
		map.open_settlement(sid)
		await get_tree().process_frame
		var w = map.modal_layer.get_child(0)
		for page in ["main", "tavern", "hall", "recruit"]:
			w.page = page
			w.refresh()
			await get_tree().process_frame
			var n2 = await _press_all(w, skip)
			print(sid, "/", page, " pressed ", n2)
			if not is_instance_valid(w):
				break
		await _close_all()
	# Trade, shop, garrison
	for path in ["res://scripts/ui/trade_window.gd", "res://scripts/ui/shop_window.gd", "res://scripts/ui/garrison_window.gd"]:
		var tw = load(path).new()
		tw.sid = "omashu"
		map.open_window(tw)
		await get_tree().process_frame
		var n3 = await _press_all(tw, skip)
		print(path.get_file(), " pressed ", n3)
		await _close_all()
	# The Avatar window: calm, then with the Avatar coming (prime era)
	var AvatarSys = load("res://scripts/core/avatar.gd")
	AvatarSys.init_era("prime")
	for hostile in [false, true]:
		if hostile:
			GS.settlements.omashu.owner = "player"
			AvatarSys.state().warned = true
			AvatarSys.add_infamy(300, Vector2.ZERO)
			AvatarSys._schedule(AvatarSys.state(), "confront", 10)
			AvatarSys.state().state = "gathering"
		var aw = load("res://scripts/ui/avatar_window.gd").new()
		map.open_window(aw)
		await get_tree().process_frame
		var na = await _press_all(aw, skip)
		print("avatar window (hostile=%s) pressed %d" % [hostile, na])
		await _close_all()
	# Element expansions: techniques and bending work (a firebender with a waterbending companion)
	GS.player.bend = "fire"
	GS.player.companions = ["nima"]
	load("res://scripts/battle/techniques.gd").learn("f_whip")
	for wp in [["res://scripts/ui/techniques_window.gd", ""], ["res://scripts/ui/bending_work_window.gd", "senlin"], ["res://scripts/ui/bending_work_window.gd", ""]]:
		var xw = load(wp[0]).new()
		if wp[1] != "" or wp[0].contains("work"):
			xw.sid = wp[1]
		map.open_window(xw)
		await get_tree().process_frame
		var nx = await _press_all(xw, skip)
		print(wp[0].get_file(), " (", wp[1], ") pressed ", nx)
		await _close_all()
	GS.player.bend = "earth"
	GS.player.companions = []
	# Seek the Avatar where they are
	AvatarSys.state().state = "free"
	AvatarSys.state().warned = false
	AvatarSys.state().due = {}
	GS.player.infamy = 0
	AvatarSys.state().loc = "gaoling"
	GS.player_party().pos = Data.settlements.gaoling.pos
	map.open_settlement("gaoling")
	await get_tree().process_frame
	var gw = map.modal_layer.get_child(0)
	for b in gw.find_children("*", "Button", true, false):
		if b.text.findn("audience") >= 0:
			b.pressed.emit()
			print("sought an audience with the Avatar")
			break
	await get_tree().process_frame
	await _close_all()
	# Encounters with each kind of party
	var kinds_done := {}
	for id in GS.parties.keys():
		if not GS.parties.has(id) or id == "player":
			continue
		var k: String = GS.parties[id].kind
		if kinds_done.has(k):
			continue
		kinds_done[k] = true
		map._on_player_encounter(id)
		await get_tree().process_frame
		var ew = map.modal_layer.get_child(0)
		var n4 = await _press_all(ew, skip + ["Send your troops", "Order your troops", "Attack them"])
		print("encounter ", k, " pressed ", n4)
		await _close_all()
	# Auto-resolve against bandits
	for id in GS.parties.keys():
		if GS.parties.has(id) and GS.parties[id].kind == "bandit":
			var r := GS.auto_resolve_player([id])
			print("auto-resolve vs bandits: ", r.won, " ", r.lines)
			break
	# Quests
	for sid in ["senlin", "omashu", "fong_fortress"]:
		var q := Quests.generate(sid)
		if not q.is_empty():
			Quests.accept(q)
			print("quest ", q.type, ": ", q.title)
			if q.type == "deliver_goods":
				GS.add_good(q.good, q.n)
			Quests.try_deliver(sid)
			if q.type == "deliver_letter":
				Quests.on_arrive(q.target)
	print("quests: ", GS.quests.map(func(x): return x.status))
	# Vassalage via the king
	var kuei_party: String = GS.lords["hualing"].party
	GS.player.renown = 500
	if kuei_party != "":
		var ew2 = load("res://scripts/ui/encounter_window.gd").new()
		ew2.pid = kuei_party
		ew2.page = "talk"
		map.open_window(ew2)
		await get_tree().process_frame
		for b in ew2.find_children("*", "Button", true, false):
			if b.text.findn("vassal") >= 0:
				b.pressed.emit()
				break
		await get_tree().process_frame
		print("status after pledge: ", GS.player.status, " ", GS.player.faction)
		await _close_all()
	# Player siege flow (auto)
	var target := "kettle_rock"
	GS.player_party().pos = Data.settlements[target].pos
	map.open_settlement(target)
	await get_tree().process_frame
	var sw = map.modal_layer.get_child(0)
	sw._begin_siege()
	GS.player.siege_start = GS.hours - 20.0
	sw.refresh()
	await get_tree().process_frame
	sw._assault_auto()
	await get_tree().process_frame
	print("kettle_rock faction after auto assault: ", GS.settlements[target].faction, " owner ", GS.settlements[target].owner)
	await _close_all()
	# Time passes with the map running
	GS.sim.advance(24.0 * 10)
	print("after 10 days: ", GS.date_string(), " gold ", GS.player.gold)
	print("save: ", GS.save_game("user://ui_test.sav"), " load: ", GS.load_game("user://ui_test.sav"))
