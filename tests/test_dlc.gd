extends Node
## Element expansion tests: every technique can be learned from someone in the
## world; each mastery trial can be completed; each new companion's quest
## resolves; every bending job can be done somewhere and does what it says;
## learned techniques open their Forms movements; switching an expansion off
## hides its content.
const Story = preload("res://scripts/story/story.gd")
const Tech = preload("res://scripts/battle/techniques.gd")
const Forms = preload("res://scripts/battle/forms.gd")
const Work = preload("res://scripts/core/bending_work.gd")
const AvatarSys = preload("res://scripts/core/avatar.gd")
const DLC = preload("res://scripts/dlc/registry.gd")

var errors := 0

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_dlc.gd").new())
		return
	Story.no_scene_change = true
	_fire()
	_water()
	_earth()
	_air()
	_work()
	_toggle()
	print("DLC TEST DONE, errors: ", errors)
	get_tree().quit()

func _err(msg: String) -> void:
	errors += 1
	print("  ERROR: ", msg)

func _new(bg: String, bend: String) -> void:
	var p := GS.create_player("Tester", bg, bend, Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	GS.flags.dlg_queue = []
	GS.player.gold = 30000
	GS.player.skills.bending = 10
	GS.player.skills.healing = 4
	GS.player.skills.trade = 4
	GS.player.level = 30
	GS.player.renown = 400
	GS.player.standing = "gentry"
	GS.flags.duel_wins = 3

func _hire(cid: String) -> void:
	GS.player.companions.append(cid)
	GS.companion_state(cid).approval = 60
	Story.set_flag("joined_" + cid, GS.day() - 10)

## Walk a dialogue, preferring choices containing any of `prefer` (in order).
func _run(id: String, prefer: Array = [], max_steps: int = 60) -> String:
	var d: Dictionary = Story.dialogue(id)
	if d.is_empty():
		_err("missing dialogue " + id)
		return ""
	var nid: String = d.start
	var path := []
	var steps := 0
	while nid != "" and steps < max_steps:
		steps += 1
		var node: Dictionary = d.nodes[nid]
		path.append(nid)
		Story.apply(node.get("do", []))
		var choices: Array = node.get("choices", [])
		if choices.is_empty():
			nid = node.get("next", "")
			continue
		var pick = null
		for pref in prefer:
			for c in choices:
				if Story.ok(c.get("if", {})) and Story.fmt(c.text).findn(pref) >= 0:
					pick = c
					break
			if pick != null:
				break
		if pick == null:
			for c in choices:
				if Story.ok(c.get("if", {})):
					pick = c
					break
		if pick == null:
			_err("%s/%s: no enabled choice" % [id, nid])
			break
		Story.apply(pick.get("do", []))
		nid = pick.get("next", "")
	return ",".join(path)

## Learn everything a teacher's hub offers by choosing "Learn"/"Teach" until
## nothing new is offered.
func _learn_all(id: String, words: Array = ["Learn", "Teach"]) -> void:
	for i in 8:
		var before: int = GS.player.techniques.size()
		_run(id, words + ["Another time", "I'll go", "Let's keep moving", "Rest your knee", "Leave", "Carry on"], 12)
		if GS.player.techniques.size() == before:
			break

func _check_all_known(el: String) -> void:
	for id in Tech.for_element(el):
		if not Tech.known(id):
			_err("%s technique %s was never taught" % [el, id])
	var known: Array = GS.player.techniques
	var moves: Array = Forms.MOVES[el].filter(func(m): return m.has("req"))
	for m in moves:
		if not Forms.next_moves(el, "", known).has(m):
			_err("forms movement %s not unlocked by %s" % [m.id, m.req])
	print("%s: %d techniques learned, mastery %.1f%% — %s, title '%s'" % [el, known.size(), AvatarSys.mastery_percentile(), AvatarSys.mastery_text(), GS.player.get("master_title", "")])

func _drain() -> Array:
	var out := []
	while Story.has_pending():
		out.append(Story.pop_pending())
	return out

# ---------------------------------------------------------------------------
func _fire() -> void:
	_new("fn_noble", "fire")
	_hire("sayuri")
	_learn_all("talk_sayuri")
	_learn_all("fx_hall")
	_learn_all("fx_monastery")
	_check_all_known("fire")
	# Sayuri's quest: let her face Daisuke
	GS.hours += 24.0
	Story.fire("daily")
	if not _drain().has("fx_sayuri_start"):
		_err("Sayuri's quest did not start")
	_run("fx_sayuri_start")
	_run("fx_sayuri_daisuke", ["he's yours"])
	if not Story.flag("daisuke_humbled") or not Story.flag("sayuri_done"):
		_err("Sayuri's quest did not resolve")
	# The First Flame: carry it clean, then light the lamp with breath
	_run("fx_monastery", ["carry the ember"], 12)
	if not Story.flag("fx_ember"):
		_err("First Flame trial did not start")
	_run("fx_ember_arrive")
	_run("fx_trial_final", ["breathe"])
	if GS.player.get("master_title", "") != "Master Firebender":
		_err("fire mastery not granted")
	# A dirty ember goes out
	_new("fn_noble", "fire")
	for id in ["f_jets", "f_whip", "f_daggers"]:
		Tech.learn(id)
	_run("fx_monastery", ["carry the ember"], 12)
	AvatarSys.add_infamy(25, Vector2.ZERO, "test")
	var p := _run("fx_ember_arrive")
	if not p.contains("dark"):
		_err("the ember stayed lit after cruelty: " + p)
	# The comet forge needs a comet
	GS.flags.fx_kazan_met = true
	GS.flags.cosmic = [{"kind": "comet", "day": GS.day(), "from": 0.0, "to": 24.0, "days": 4}]
	Story.fire("daily")
	if not _drain().has("fx_comet"):
		_err("comet forge did not trigger")
	_run("fx_comet", ["forge"])
	if not GS.player.items.has("comet_dao"):
		_err("no comet dao forged")

func _water() -> void:
	_new("swt_warrior", "water")
	_hire("huan")
	_learn_all("talk_huan", ["Show me"])
	_learn_all("wx_yura")
	_learn_all("wx_north")
	_check_all_known("water")
	_run("wx_huan_start")
	_run("wx_banyan")
	_hire("hana")
	_run("wx_dam", ["ask the river"])
	if not Story.flag("huan_river"):
		_err("Huan's cooperative ending not reached")
	_run("wx_north", ["Moon's Road", "Another time"], 12)
	if not Story.flag("wx_moon_road"):
		_err("Moon's Road did not start")
	GS.flags.two_paths = true
	var path := _run("wx_moon_end")
	if not path.contains("kaya"):
		_err("Kaya missing from the Moon's Road after the law changed")
	if GS.player.get("master_title", "") != "Master Waterbender":
		_err("water mastery not granted")
	# The Red Moon
	GS.flags.cosmic = [{"kind": "lunar", "day": GS.day(), "from": 0.0, "to": 24.0}]
	GS.hours = float(GS.day()) * 24.0 + 22.0
	var sp: int = GS.player.skill_points
	Story.fire("daily")
	if _drain().has("wx_red_moon"):
		_run("wx_red_moon")
		if GS.player.skill_points != sp + 1:
			_err("Red Moon gave no skill point")
	else:
		_err("Red Moon did not trigger during a lunar eclipse")

func _earth() -> void:
	_new("lower_ring", "earth")
	_hire("gao_ming")
	GS.flags.hana_spared = true
	_learn_all("talk_gao_ming")
	_learn_all("ex_boulder")
	_learn_all("ex_bolai", ["promise"])
	_learn_all("ex_shan")
	_check_all_known("earth")
	_run("ex_gao_start")
	_run("ex_seam", ["shore up"])
	if not Story.flag("gao_deal"):
		_err("the jade seam deal was not reached")
	_run("ex_shan", ["Badgermole", "I'm in no hurry", "in no hurry"], 20)
	if GS.player.get("master_title", "") != "Master Earthbender":
		_err("earth mastery not granted")
	# Breaking the strike costs Gao Ming
	_new("lower_ring", "earth")
	_hire("gao_ming")
	_run("ex_gao_start")
	_run("ex_seam", ["Back to work"])
	if GS.player.companions.has("gao_ming") or AvatarSys.infamy() < 15:
		_err("breaking the strike kept Gao Ming or cost no infamy")

func _air() -> void:
	_new("air_nomad", "air")
	_hire("yangzom")
	_learn_all("talk_yangzom")
	_learn_all("ax_dorje")
	_learn_all("ax_lhakpa")
	_learn_all("ax_tsering")
	_learn_all("ax_yeshe")
	_check_all_known("air")
	for t in ["ax_dorje", "ax_lhakpa", "ax_tsering", "ax_yeshe"]:
		_run(t, ["test", "Spend the day", "Another time"], 14)
	for f in ["ax_t_dorje", "ax_t_lhakpa", "ax_t_tsering", "ax_t_yeshe"]:
		if not Story.flag(f):
			_err("air trial step %s not passed" % f)
	_run("ax_arrows")
	if GS.player.get("master_title", "") != "Airbending Master":
		_err("air mastery not granted")
	var look: Dictionary = load("res://scripts/actors/looks.gd").player_look()
	if look.get("accessory", "") != "air_arrow":
		_err("an Airbending Master has no arrows: %s" % look)
	_run("ax_yangzom_start")
	_run("ax_herd", ["Buy"])
	if not Story.flag("herd_freed") or not _drain().has("ax_herd_home"):
		_err("the herd was not freed")
	_run("ax_herd_home")
	if not Story.flag("yangzom_done"):
		_err("Yangzom's quest did not finish")

# ---------------------------------------------------------------------------
## Every job can be done somewhere, by the right bender, and changes the world.
func _work() -> void:
	var places := {"temper": "omashu", "kiln": "omashu", "warm": "", "cook": "", "clear": "senlin", "scorch": "shu_jing", "lanterns": "omashu",
		"heal_house": "omashu", "irrigate": "senlin", "fish": "wolf_cove", "purify": "misty_palms", "ice_bridge": "", "ice_carve": "wolf_cove",
		"mine": "fong_fortress", "masonry": "omashu", "terrace": "senlin", "road": "", "shelter": "southern_air_temple", "shore": "fong_fortress",
		"scout": "", "sails": "full_moon_bay", "windmill": "senlin", "firefight": "senlin", "meditate": "", "bison": "southern_air_temple"}
	var benders := {"fire": "fn_deserter", "water": "swt_warrior", "earth": "ek_refugee", "air": "air_nomad"}
	var done := 0
	for id in Work.WORK:
		var w: Dictionary = Work.WORK[id]
		_new(benders[w.element], w.element)
		var sid: String = places.get(id, "")
		GS.player.faction_rel.air_nomads = 40
		if sid != "":
			GS.player_party().pos = Data.settlements[sid].pos
		match id:
			"scorch":
				GS.player.wars = ["fire_nation"]
			"masonry":
				GS.settlements.omashu.owner = "player"
			"firefight":
				GS.settlements.senlin.looted_until = GS.hours + 100.0
			"lanterns":
				GS.hours = float(GS.day()) * 24.0 + 21.0
		var why := Work.blocker(id, sid)
		if why != "":
			_err("job %s blocked at '%s': %s" % [id, sid, why])
			continue
		var gold: int = GS.player.gold
		var line := Work.perform(id, sid, "eastern_air_temple" if id == "bison" else "")
		if line == "":
			_err("job %s produced no outcome" % id)
		done += 1
		match id:
			"kiln":
				if int(GS.player.goods.get("porcelain", 0)) <= 0:
					_err("kiln gave no porcelain")
			"temper":
				if GS.player.get("tempered", "") == "" or GS.player.gold >= gold:
					_err("temper did nothing")
			"scorch":
				if AvatarSys.infamy() < 30:
					_err("scorching cost no infamy")
			"masonry":
				if Data.walls("omashu") <= 1.6:
					_err("masonry did not raise the walls")
			"ice_bridge", "road", "scout":
				if Work.buff("swift") <= 1.0:
					_err("%s gave no travel buff" % id)
			"bison":
				if GS.player_party().pos.distance_to(Data.settlements.eastern_air_temple.pos) > 10.0:
					_err("the bison did not fly")
		# the job is now on cooldown where it has one
		if int(w.get("cd", 0)) > 0 and Work.blocker(id, sid) == "":
			_err("job %s has no cooldown after use" % id)
	print("bending work: %d of %d jobs done" % [done, Work.WORK.size()])
	# A non-bender's companion does the work
	_new("hamakaze", "")
	GS.player.companions = ["nima"]
	GS.player_party().pos = Data.settlements.omashu.pos
	if Work.blocker("heal_house", "omashu") != "":
		_err("Nima could not run a healing house: " + Work.blocker("heal_house", "omashu"))

func _toggle() -> void:
	_new("fn_noble", "fire")
	GS.settings.dlc_fire = false
	if not Tech.for_element("fire").is_empty():
		_err("fire techniques visible with the expansion off")
	for o in Story.settlement_options("fire_fountain"):
		if o.dlg == "fx_hall":
			_err("duelling hall offered with the expansion off")
	if Work.blocker("kiln", "omashu") != "expansion off":
		_err("fire work offered with the expansion off")
	GS.settings.dlc_fire = true
	var found := false
	for o in Story.settlement_options("fire_fountain"):
		if o.dlg == "fx_hall":
			found = true
	if not found:
		_err("duelling hall missing with the expansion on")
