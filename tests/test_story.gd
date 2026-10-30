extends Node
## Story tests: validates every dialogue graph (links, speakers, effects,
## conditions), then plays the main storyline and each companion quest through
## headlessly, and opens a dialogue window with live portraits.
const Story = preload("res://scripts/story/story.gd")
const Endings = preload("res://scripts/story/endings.gd")
const Roster = preload("res://scripts/core/roster.gd")

const OPS := ["approval", "flag", "flag_day", "gold", "renown", "honor", "xp", "rel", "lord_rel", "peace", "war", "journal",
	"journal_done", "join", "leave", "away", "companion_mod", "spawn", "close_windows", "wait", "prosperity", "item", "troops",
	"heal", "queue", "page", "log", "skill_points", "attr_points", "standing", "call", "infamy", "av_attitude", "learn", "master", "comp_tech", "good"]
const CONDS := ["flag", "not_flag", "flags", "eq", "has_page", "companion", "no_companion", "gold", "standing", "approval", "rel",
	"bend", "renown", "skill", "day", "days_since", "pages", "at", "owns", "peace_with", "pronouns", "call", "near_faction", "era", "tech", "no_tech", "bends", "master", "season", "cosmic", "forms_uses", "duel_wins", "techs"]
const EXPRS := ["neutral", "happy", "laugh", "smirk", "sad", "grief", "angry", "furious", "surprised", "afraid", "determined",
	"thoughtful", "tender", "embarrassed", "pain", "sleep"]

const CALLS := ["has_wounded", "any_companion", "has_evidence", "pemba_or_nima", "nima_wins", "nima_loses", "av_hostage", "av_seat", "av_no_seat",
	"av_young", "av_prime", "av_elder", "av_ruler", "av_friend", "av_not_friend", "av_kept", "av_not_kept", "av_wars", "av_intel",
	"not_master", "not_air", "wx_can_share", "ex_academy_ok", "fx_ember_clean", "fx_ember_dirty"]

var errors := 0

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_story.gd").new())
		return
	var p := GS.create_player("Tester", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	_validate()
	_play_main("told")
	for k in ["kept", "sold_fire", "sold_earth", "sold_omashu", "buried", "burned"]:
		_play_main(k)
	_play_companions()
	# Bending forms: starters are valid and model good breathing; rules bite
	var Forms = load("res://scripts/battle/forms.gd")
	for art in ["fire", "earth", "water", "air"]:
		var ev: Dictionary = Forms.evaluate(Forms.starter(art))
		if not ev.valid or not ev.notes.is_empty():
			_err("starter form %s: %s %s" % [art, ev.errors, ev.notes])
		print("form %s: power %.0f windup %.2f chi %.0f props %s" % [art, ev.power, ev.windup, ev.chi, ev.props])
	var bad: Dictionary = Forms.evaluate({"art": "earth", "moves": ["e_tiger", "e_root"], "release": "strike"})
	if bad.valid:
		_err("broken stance chain accepted")
	var plain: String = load("res://scripts/ui/dialogue_window.gd")._plain("I d-don't k-know. I-I mean, sh-she's fine. Re-entry is a word.")
	if plain != "I don't know. I mean, she's fine. Re-entry is a word.":
		_err("plain speech filter: " + plain)
	await _window_test()
	print("STORY TEST DONE, errors: ", errors)
	get_tree().quit()

func _err(msg: String) -> void:
	errors += 1
	print("  ERROR: ", msg)

# ---------------------------------------------------------------------------
func _validate() -> void:
	Story._load()
	var n := 0
	for id in Story._cache:
		var d: Dictionary = Story._cache[id]
		var nodes: Dictionary = d.get("nodes", {})
		if not nodes.has(d.get("start", "")):
			_err("%s: missing start node" % id)
		for nid in nodes:
			n += 1
			var node: Dictionary = nodes[nid]
			_check_speaker(id, node)
			if node.has("expr") and not EXPRS.has(node.expr):
				_err("%s/%s: unknown expression %s" % [id, nid, node.expr])
			_check_effects(id + "/" + nid, node.get("do", []))
			var nx: String = node.get("next", "")
			if nx != "" and not nodes.has(nx):
				_err("%s/%s: next -> missing %s" % [id, nid, nx])
			for c in node.get("choices", []):
				var cn: String = c.get("next", "")
				if cn != "" and not nodes.has(cn):
					_err("%s/%s: choice -> missing %s" % [id, nid, cn])
				if c.has("goto") and not Story.has_dialogue(c.goto):
					_err("%s/%s: goto missing %s" % [id, nid, c.goto])
				_check_effects(id + "/" + nid, c.get("do", []))
				_check_cond(id + "/" + nid, c.get("if", {}))
	for t in Story._triggers:
		if not Story.has_dialogue(t.dlg):
			_err("trigger for missing dialogue " + t.dlg)
		_check_cond("trigger " + t.dlg, t.get("if", {}))
		_check_effects("trigger " + t.dlg, t.get("do", []))
	for o in Story._options:
		if not Story.has_dialogue(o.dlg):
			_err("option for missing dialogue " + o.dlg)
		if not Data.settlements.has(o.sid):
			_err("option at missing settlement " + o.sid)
		_check_cond("option " + o.dlg, o.get("if", {}))
	print("validated %d dialogues, %d nodes, %d triggers, %d options" % [Story._cache.size(), n, Story._triggers.size(), Story._options.size()])

func _check_speaker(id: String, node: Dictionary) -> void:
	var who: String = node.get("who", "narrator")
	if who in ["narrator", "player"] or Data.companions.has(who) or Data.lords.has(who) or not Story.npc(who).is_empty():
		return
	_err("%s: unknown speaker %s" % [id, who])

func _check_effects(where: String, effects: Array) -> void:
	for e in effects:
		if not OPS.has(e[0]):
			_err("%s: unknown effect %s" % [where, e[0]])
		if e[0] in ["approval", "join", "leave", "away"] and not Data.companions.has(e[1]):
			_err("%s: unknown companion %s" % [where, e[1]])
		if e[0] == "lord_rel" and not Data.lords.has(e[1]):
			_err("%s: unknown lord %s" % [where, e[1]])
		if e[0] in ["rel"] and not Data.factions.has(e[1]):
			_err("%s: unknown faction %s" % [where, e[1]])
		if e[0] == "prosperity" and not Data.settlements.has(e[1]):
			_err("%s: unknown settlement %s" % [where, e[1]])
		if e[0] == "spawn" and not Story._spawns.has(e[1]):
			_err("%s: unknown spawn %s" % [where, e[1]])
		if e[0] == "queue" and not Story.has_dialogue(e[1]):
			_err("%s: queue missing %s" % [where, e[1]])
		if e[0] == "learn" and not load("res://scripts/battle/techniques.gd").TECHNIQUES.has(e[1]):
			_err("%s: unknown technique %s" % [where, e[1]])
		if e[0] == "item" and not Data.items.has(e[1]):
			_err("%s: unknown item %s" % [where, e[1]])

func _check_cond(where: String, cond: Dictionary) -> void:
	for k in cond:
		if not CONDS.has(k):
			_err("%s: unknown condition %s" % [where, k])
		if k in ["companion", "no_companion"] and cond[k] != "" and not Data.companions.has(cond[k]):
			_err("%s: unknown companion %s" % [where, cond[k]])
		if k in ["tech", "no_tech"] and not load("res://scripts/battle/techniques.gd").TECHNIQUES.has(cond[k]):
			_err("%s: unknown technique %s" % [where, cond[k]])
		if k == "call" and not cond[k] in CALLS:
			_err("%s: unknown call condition %s" % [where, cond[k]])

# ---------------------------------------------------------------------------
## Walk a dialogue, choosing the first enabled choice whose text contains
## `prefer` (or the first enabled one), applying effects as the window would.
func _run(id: String, prefer: Array = []) -> String:
	var d: Dictionary = Story.dialogue(id)
	if d.is_empty():
		_err("run: missing " + id)
		return ""
	var nid: String = d.start
	var guard := 0
	var path := []
	while nid != "" and guard < 60:
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
			return ""
		Story.apply(pick.get("do", []))
		if pick.has("goto"):
			return _run(pick.goto, prefer)
		nid = pick.get("next", "")
	return ",".join(path)

func _drain() -> void:
	while Story.has_pending():
		_run(Story.pop_pending())

func _beat(sp: String) -> void:
	var pid: String = Story.flag("spawn_" + sp, "")
	if pid != "" and GS.parties.has(pid):
		GS.sim.on_party_defeated(pid, "player")
	_drain()

func _play_main(ending: String) -> void:
	var p := GS.create_player("Tester", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	GS.player.gold = 20000
	GS.player.renown = 500
	GS.player.standing = "gentry"
	GS.hours = 24.0 * 2 + 8.0
	Story.fire("daily")
	if not Story.has_pending():
		_err("prologue did not queue")
	_run(Story.pop_pending(), ["Fight"])
	_beat("norbu_hunters")
	if not Story.flag("ms_norbu_saved"):
		_err("Norbu not saved after beating hunters")
	_drain()
	GS.player.inside = "eastern_air_temple"
	var opts := Story.settlement_options("eastern_air_temple")
	if opts.is_empty():
		_err("no option at Eastern Temple")
		return
	_run(opts[0].dlg)
	_run("ms_archive", ["vouches"])
	_run("ms_shiyo", ["Pay"])
	_run("ms_vault", ["Petition", "promise"])
	_run("ms_admiralty", ["800"])
	_run("ms_library", ["own"])
	_drain()
	if Story.pages().size() != 6:
		_err("expected 6 pages, got %d" % Story.pages().size())
	if not Story.flag("ms_truth"):
		_err("truth not revealed")
	var pick = {"told": "Council", "kept": "Abbess", "sold_fire": "Fire Lord", "sold_earth": "Earth Queen", "sold_omashu": "Feng Tao", "buried": "Kuro", "burned": "yourself"}[ending]
	_run("ms_decide", [pick])
	match ending:
		"told":
			GS.flags.kuro_implicated = true
			for k in Data.KINGDOMS:
				GS.make_peace("player", k)
			_run("ms_council", ["evidence"])
			if not Story.flag("ending_told"):
				_err("council did not end in the Accord")
			_beat("kuro_rebels")
			_beat("wu_loyalists")
			Story.fire("daily")
			_drain()
		"kept": _run("ms_kept")
		"sold_fire": _run("ms_sold_fire")
		"sold_earth": _run("ms_sold_earth")
		"sold_omashu": _run("ms_sold_omashu")
		"buried": _run("ms_sell_kuro", ["Hand it over"])
	var ep: String = GS.flags.get("pending_epilogue", "")
	if ep != ending:
		_err("ending %s: pending_epilogue is '%s'" % [ending, ep])
	var txt := Endings.epilogue_text(ending)
	if txt.length() < 100:
		_err("epilogue too short for " + ending)
	print("ending %s ok — %d pages, epilogue %d chars, wars: %s" % [ending, Story.pages().size(), txt.length(), _wars()])

func _wars() -> String:
	var out := []
	for a in Data.KINGDOMS:
		for b in Data.KINGDOMS:
			if a < b and GS.at_war(a, b):
				out.append("%s-%s" % [a.left(4), b.left(4)])
	return ",".join(out)

func _play_companions() -> void:
	var p := GS.create_player("Tester", "nwt_noble", "water", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	GS.player.gold = 20000
	GS.player.standing = "gentry"
	GS.player.faction_rel["northern_water"] = 30
	for cid in Data.companions:
		GS.player.companions.append(cid)
		GS.companion_state(cid).approval = 50
		Story.set_flag("joined_" + cid, 0)
	GS.hours = 24.0 * 10 + 8.0
	Story.fire("daily")
	var started := 0
	while Story.has_pending():
		var id := Story.pop_pending()
		if id.begins_with("cq_") and id.ends_with("_start"):
			started += 1
		_run(id)
	if started != 8:
		_err("expected 8 companion quests to start, got %d" % started)
	var plan := {"ba_sing_se": ["choice"], "tieshan": ["rebuild"], "red_lantern_den": ["choose"], "agna_qela": ["Petition"],
		"shu_jing": ["shoulder"], "omashu": ["Nudge"], "fire_navy_harbor": ["Burn your letter"], "misty_palms": ["swamp"]}
	for sid in plan:
		GS.player.inside = sid
		for o in Story.settlement_options(sid):
			if o.dlg.begins_with("cq_"):
				_run(o.dlg, plan[sid])
	GS.player.inside = "crescent_island"
	for o in Story.settlement_options("crescent_island"):
		_run(o.dlg)
	GS.player.inside = "tieshan"
	for o in Story.settlement_options("tieshan"):
		_run(o.dlg)
	_drain()
	var outcomes := []
	for f in ["hana_spared", "juro_fire", "juro_lantern", "dawa_free", "two_paths", "ukiuk_confessed", "letter_delivered", "shenmu_lin", "kuro_ledgers", "kesi_swamp"]:
		if not Story.flag(f):
			_err("companion outcome missing: " + f)
		else:
			outcomes.append(f)
	if not Data.troop_unlocked("nwt_moon_guard"):
		_err("Moon Guard still locked after the Two Paths")
	print("companion quests ok: ", outcomes)
	print("juro bends: ", GS.companion_state("juro").get("bend", ""), "  hana power bonus: ", GS.companion_state("hana").get("power_bonus", 0.0))
	print("journal entries: ", GS.flags.journal.size())

func _window_test() -> void:
	var DW = load("res://scripts/ui/dialogue_window.gd")
	var w = DW.new()
	w.dlg_id = "banter_hana_ukiuk"
	add_child(w)
	for i in 6:
		await get_tree().process_frame
		if not is_instance_valid(w) or not w.is_inside_tree():
			break
		w._go(w.dlg.nodes[w.node_id].get("next", ""), [])
	print("dialogue window ok, actors built: ", w._actors.keys() if is_instance_valid(w) else "closed")
