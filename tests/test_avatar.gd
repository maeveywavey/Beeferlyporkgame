extends Node
## Avatar system tests (scripts/core/avatar.gd): every era starts cleanly and
## the player is never the Avatar; each life stage behaves as designed; all
## four motives bring the Avatar; every countermeasure works; judgement takes
## the realm apart; teaching makes the Avatar master the player's element.
const Story = preload("res://scripts/story/story.gd")
const AvatarSys = preload("res://scripts/core/avatar.gd")
const Roster = preload("res://scripts/core/roster.gd")

var errors := 0

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_avatar.gd").new())
		return
	_creation()
	_eras()
	_ruler()
	_tyrant_yield()
	_tyrant_diversion_and_hostage()
	_tyrant_battle_loss()
	_local()
	_teacher()
	_quiet_reveal()
	print("AVATAR TEST DONE, errors: ", errors)
	get_tree().quit()

func _err(msg: String) -> void:
	errors += 1
	print("  ERROR: ", msg)

func _new(era: String, bg: String = "ek_refugee", bend: String = "earth") -> void:
	var p := GS.create_player("Tester", bg, bend, Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1), era)
	GS.new_game(p)
	GS.flags.seen_help = true
	GS.flags.dlg_queue = []

## Walk a dialogue choosing the first enabled choice containing `prefer`.
func _run(id: String, prefer: Array = []) -> String:
	var d: Dictionary = Story.dialogue(id)
	if d.is_empty():
		_err("run: missing " + id)
		return ""
	var nid: String = d.start
	var path := []
	var guard := 0
	while nid != "" and guard < 40:
		guard += 1
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
			return ",".join(path)
		Story.apply(pick.get("do", []))
		nid = pick.get("next", "")
	return ",".join(path)

func _days(n: int) -> void:
	for i in n:
		GS.hours += 24.0
		AvatarSys.daily()

## Run the Avatar's daily logic until a dialogue is queued (or give up).
func _until_queued(id: String, max_days: int = 400) -> bool:
	for i in max_days:
		GS.hours += 24.0
		AvatarSys.daily()
		if GS.flags.get("dlg_queue", []).has(id):
			GS.flags.dlg_queue.erase(id)
			return true
	return false

func _give(sid: String) -> void:
	GS.settlements[sid].owner = "player"
	GS.settlements[sid].faction = "player"

# ---------------------------------------------------------------------------
func _creation() -> void:
	var n := 0
	for bid in GS.BACKGROUNDS:
		for b in GS.BACKGROUNDS[bid].bends:
			var p := GS.create_player("T", bid, b, Color.WHITE, Color.BLACK)
			n += 1
			if p.bend != b or not b in ["", "fire", "water", "earth", "air"]:
				_err("background %s produced bend %s" % [bid, p.bend])
			if b != "" and p.forms.is_empty():
				_err("%s %s bender has no starter form" % [bid, b])
	for el in ["", "fire", "water", "earth", "air"]:
		var any := false
		for bid in GS.BACKGROUNDS:
			if GS.BACKGROUNDS[bid].bends.has(el) or el == "":
				any = true
		if not any:
			_err("no background for element '%s'" % el)
	print("creation: %d background/element combinations" % n)

func _eras() -> void:
	for e in ["quiet", "young", "prime", "elder"]:
		_new(e)
		var st := AvatarSys.stage()
		var want: String = {"quiet": "child", "young": "young", "prime": "prime", "elder": "elder"}[e]
		if st != want:
			_err("era %s starts at stage %s" % [e, st])
		if GS.player.bend == "avatar":
			_err("player is the Avatar")
		# a season of simulated days: no errors, sightings for adults only
		_days(120)
		var seen: int = AvatarSys.state().seen.size()
		var spirit := 0
		for i in 60:
			_days(1)
			if AvatarSys.state().loc == "spirit":
				spirit += 1
		print("era %s: stage %s, %d sightings in 120 days, %d/60 days in the Spirit World, date '%s'" % [e, st, seen, spirit, GS.day_name(GS.day())])
		if e == "quiet" and seen > 0:
			_err("an untold child Avatar was sighted")
		if e != "quiet" and seen == 0:
			_err("era %s: adult Avatar never sighted" % e)
		if e == "elder" and spirit < 25:
			_err("elder Avatar spends too little time in the Spirit World (%d/60)" % spirit)
		if e == "quiet" and Story.flag("trig_ms_prologue") == false:
			Story.fire("daily")
		if e != "quiet":
			GS.hours = 24.0 * 2 + 8.0
			Story.fire("daily")
			if GS.flags.get("dlg_queue", []).has("ms_prologue"):
				_err("sandbox era %s started the Drowned Testament" % e)

func _ruler() -> void:
	_new("prime")
	_give("caldera")
	if AvatarSys.ruler_title() != "Fire Lord":
		_err("holding Caldera gives title '%s'" % AvatarSys.ruler_title())
	if not _until_queued("av_court", 300):
		_err("the Avatar never came to the Fire Lord's court")
		return
	_run("av_court", ["granaries"])
	if not Story.flag("av_accord") or int(AvatarSys.state().attitude) < 20:
		_err("court accord not recorded")
	# A friend can now ask for help with peace
	GS.declare_war("player", "earth_kingdom")
	_run("av_audience", ["make peace", "back to it"])
	if GS.at_war("player", "earth_kingdom"):
		_err("Avatar did not broker peace for a friend")

func _tyrant_setup(era: String) -> void:
	_new(era)
	_give("caldera")
	_give("fire_fountain")
	Roster.add(GS.player_party().roster, "fn_veteran", 40)
	AvatarSys.add_infamy(220, GS.player_party().pos, "test")

func _tyrant_yield() -> void:
	_tyrant_setup("prime")
	if not AvatarSys.motives().tyrant.active:
		_err("tyrant motive inactive at infamy %d influence %.1f" % [AvatarSys.infamy(), AvatarSys.influence()])
	if not _until_queued("av_warning", 200):
		_err("no warning for a tyrant")
		return
	_run("av_warning", ["Get out"])
	if not AvatarSys.state().defied:
		_err("defiance not recorded")
	if not _until_queued("av_gathering", 200):
		_err("no gathering after defiance")
		return
	if not AvatarSys.hostile():
		_err("Avatar not hostile while gathering")
	if not _until_queued("av_confront", 60):
		_err("Avatar never arrived")
		return
	if not GS.parties.has(AvatarSys.company_id()):
		_err("no Avatar company on the map")
	_run("av_confront", ["yield"])
	if GS.settlements.caldera.owner == "player" or AvatarSys.infamy() != 0:
		_err("yielding did not return fiefs / clear infamy")
	if GS.parties.has(AvatarSys.company_id()):
		_err("company remained after yielding")

func _tyrant_diversion_and_hostage() -> void:
	_tyrant_setup("young")
	var A: Dictionary = AvatarSys.state()
	A.warned = true
	A.defied = true
	AvatarSys.buy_intel()
	GS.player.gold = 5000
	if not AvatarSys.can_stage_diversion():
		_err("cannot stage a diversion with 40 troops and gold")
	AvatarSys.stage_diversion()
	AvatarSys._schedule(A, "confront", 1)
	A.state = "gathering"
	_days(2)
	if not GS.flags.dlg_queue.has("av_diverted"):
		_err("diversion did not trigger")
	if not A.demoralized or A.due.get("kind", "") != "confront":
		_err("diversion did not delay and demoralise")
	_run("av_hostage_take", ["Take"])
	if not A.hostage:
		_err("hostage not taken")
	A.due.day = GS.day()
	A.hostage = true
	AvatarSys.daily()
	var path := _run("av_confront", ["never see them"])
	if not path.contains("hostage"):
		_err("hostage choice not offered: " + path)
	if GS.day() >= int(A.wounded_until):
		_err("hostage did not force a withdrawal")

func _tyrant_battle_loss() -> void:
	_tyrant_setup("elder")
	var A: Dictionary = AvatarSys.state()
	A.warned = true
	AvatarSys._schedule(A, "confront", 0)
	AvatarSys.daily()
	var pid := AvatarSys.company_id()
	if not GS.parties.has(pid):
		_err("elder Avatar company not spawned")
		return
	var has_avatar := Roster.find(GS.parties[pid].roster, "avatar")
	if has_avatar.is_empty():
		_err("company lacks the Avatar")
	# Simulate the player losing the battle
	GS.pending_battle = {"enemies": [pid], "allies": [], "siege": "", "player_attacking": false}
	GS._player_defeated(GS.pending_battle)
	if GS.settlements.caldera.owner == "player":
		_err("judgement left the player's fiefs")
	if not GS.flags.dlg_queue.has("av_judgement"):
		_err("judgement scene not queued")
	_run("av_judgement")
	# And winning: the Avatar withdraws, never dies
	_tyrant_setup("prime")
	A = AvatarSys.state()
	A.warned = true
	AvatarSys._schedule(A, "confront", 0)
	AvatarSys.daily()
	pid = AvatarSys.company_id()
	GS.sim.on_party_defeated(pid, "player")
	if int(A.defeats) != 1 or GS.day() >= int(A.wounded_until):
		_err("defeating the Avatar did not wound them")
	if not GS.flags.dlg_queue.has("av_withdraws"):
		_err("withdrawal scene not queued")

func _local() -> void:
	_new("prime")
	var A: Dictionary = AvatarSys.state()
	var here: Vector2 = Data.settlements.chin.pos
	GS.player_party().pos = here
	A.loc = "gaoling"
	A.pos = Data.settlements.gaoling.pos
	A.loc_until = GS.day() + 30
	for i in 3:
		AvatarSys.add_infamy(25, here, "raid")
	if not AvatarSys.motives().local.active:
		_err("local motive inactive with nearby cruelty: " + AvatarSys.motives().local.why)
	if not _until_queued("av_local", 60):
		_err("Avatar never intervened locally")
		return
	GS.player.gold = 3000
	_run("av_local", ["amends"])
	if AvatarSys.infamy() >= 75:
		_err("amends did not reduce infamy")
	# Far away, the same cruelty does not bring them
	_new("prime")
	A = AvatarSys.state()
	A.loc = "agna_qela"
	A.pos = Data.settlements.agna_qela.pos
	A.loc_until = GS.day() + 30
	GS.player_party().pos = here
	for i in 3:
		AvatarSys.add_infamy(25, here, "raid")
	if AvatarSys.motives().local.active:
		_err("a distant Avatar answered local cruelty")

func _teacher() -> void:
	_new("young", "ek_refugee", "earth")
	var A: Dictionary = AvatarSys.state()
	if A.order[0] != "earth":
		_err("young water Avatar should learn earth first, not %s" % A.order[0])
	GS.player.skills.bending = 10
	GS.player.level = 40
	GS.player.forms[0].uses = 400
	GS.flags.duel_wins = 6
	GS.player.techniques = ["a", "b", "c", "d", "e", "f"]
	GS.player.master_title = "Master Earthbender"
	print("teacher: mastery %.1f percentile — %s" % [AvatarSys.mastery_percentile(), AvatarSys.mastery_text()])
	if AvatarSys.mastery_percentile() < AvatarSys.TEACHER_PCT:
		_err("a maxed earthbender is not top 1%")
	if not _until_queued("av_teacher", 200):
		_err("young Avatar never sought the master")
		return
	_run("av_teacher", ["Yes"])
	if not GS.player.companions.has("avatar"):
		_err("Avatar did not join as a student")
	if not _until_queued("av_taught", 60):
		_err("training never finished")
		return
	_run("av_taught")
	if not A.mastered.has("earth") or GS.player.companions.has("avatar"):
		_err("Avatar did not master earth and leave")
	# An ordinary bender is not sought
	_new("young", "ek_refugee", "earth")
	if AvatarSys.motives().teacher.active:
		_err("an ordinary bender drew the teacher motive")

func _quiet_reveal() -> void:
	_new("quiet")
	GS.flags.ms_path = "kept"
	GS.hours = 24.0 * 360.0 * 6.0
	AvatarSys.daily()
	if AvatarSys.stage() != "young" or not GS.flags.dlg_queue.has("av_revealed"):
		_err("the Quiet Years child was not revealed at sixteen (stage %s)" % AvatarSys.stage())
	var path := _run("av_revealed")
	if not path.contains("kept"):
		_err("kept logbook not handed to the new Avatar")
	print("quiet reveal: %s, date '%s'" % [AvatarSys.display_name(), GS.day_name(GS.day())])
