extends Node
## Persona bots: play the live simulation for many days, answering every
## story beat the way a type of player would, and check invariants.
##   chaos    — random choices everywhere, random travel, random hires
##   story    — follows the journal, prefers kind choices, hires companions
##   warlord  — prefers fights and hard choices, raids, joins a kingdom
const Story = preload("res://scripts/story/story.gd")
const Roster = preload("res://scripts/core/roster.gd")

var issues := []
var stats := {}

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_personas.gd").new())
		return
	Story.no_scene_change = true
	var only_sandbox := OS.get_cmdline_user_args().has("sandbox")
	if not only_sandbox:
		for seed in 6:
			_play("chaos", seed, 160)
		_play("story", 101, 220)
		_play("warlord", 202, 220)
	# Sandbox eras: a cruel warlord under a prime Avatar, a kind bender under a young one
	_play("warlord", 303, 220, "prime")
	_play("story", 404, 220, "young")
	_play("chaos", 505, 160, "elder")
	print("---- ISSUES (%d) ----" % issues.size())
	var seen := {}
	for i in issues:
		if not seen.has(i):
			print("  ", i)
			seen[i] = true
	print("PERSONAS DONE")
	get_tree().quit()

func _issue(s: String) -> void:
	issues.append(s)

# ---------------------------------------------------------------------------
func _play(persona: String, seed: int, days: int, era: String = "quiet") -> void:
	seed(seed)
	var bgs := GS.BACKGROUNDS.keys()
	var bg: String = bgs[seed % bgs.size()]
	var bends: Array = GS.BACKGROUNDS[bg].bends
	var p := GS.create_player("Bot", bg, bends[0], Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1), era)
	p.look.pronouns = ["he", "she", "they"][seed % 3]
	GS.new_game(p)
	GS.flags.seen_help = true
	GS.player.gold += 3000 if persona != "chaos" else 1000
	var beats := 0
	var choices_made := 0
	var t0 := Time.get_ticks_msec()
	for d in days:
		for h in 24:
			GS.sim.advance(1.0)
			_handle_encounters(persona)
		# companions: hire whoever is in a tavern nearby now and then
		if d % 6 == 0 and GS.player.companions.size() < (8 if persona != "chaos" else 4):
			for cid in Data.companions:
				if Data.companions[cid].get("story_only", false):
					continue
				if not GS.player.companions.has(cid) and randf() < 0.35:
					GS.player.companions.append(cid)
					GS.companion_state(cid).approval = 10
					Story.set_flag("joined_" + cid, GS.day())
					break
		# travel: visit a settlement with story options (story persona follows them)
		var sid := _pick_destination(persona)
		if sid != "":
			GS.player_party().pos = Data.settlements[sid].pos + Vector2(2, 2)
			GS.player.inside = sid
			Story.fire("arrive", sid)
			for o in Story.settlement_options(sid):
				if persona == "chaos" and randf() < 0.5:
					continue
				Story.queue(o.dlg)
			if persona == "warlord" and Data.settlements[sid].type == "village" and randf() < 0.15:
				Story.react("raid")
		# answer everything that was queued
		var guard := 0
		while Story.has_pending() and guard < 30:
			guard += 1
			beats += 1
			choices_made += _answer(Story.pop_pending(), persona)
		# camp: logbook decisions and banter
		if Story.flag("ms_truth") and not Story.flag("ms_ended") and String(Story.flag("ms_path", "")) == "":
			choices_made += _answer("ms_decide", persona)
		GS.player.inside = ""
		_check_invariants(persona, seed)
	var pages := Story.pages().size()
	var done := []
	for cid in Data.companions:
		if Story.flag(cid + "_done") or Story.flag(cid.replace("_", "") + "_done"):
			done.append(cid)
	var j: Dictionary = GS.flags.get("journal", {})
	var open_q := j.keys().filter(func(k): return not j[k].done)
	print("%s#%d (%s, %s): %d days in %d ms — beats %d, choices %d, pages %d, ending '%s', companions %d, quests done %s, open journal %s, gold %d, renown %d, wars %s" % [
		persona, seed, bg, GS.player.look.pronouns, days, Time.get_ticks_msec() - t0, beats, choices_made, pages, Story.flag("ending", ""),
		GS.player.companions.size(), done, open_q, GS.player.gold, GS.player.renown, _wars()])
	var A: Dictionary = GS.flags.get("avatar", {})
	print("    era %s, Avatar %s (%s): attitude %d, warned %s, court %s, defeats %d, sightings %d; infamy %d, influence %.1f, techniques %d" % [era,
		A.get("name", "?"), load("res://scripts/core/avatar.gd").stage(), int(A.get("attitude", 0)), A.get("warned", false), A.get("court_done", false),
		int(A.get("defeats", 0)), A.get("seen", []).size(), int(GS.player.get("infamy", 0)), load("res://scripts/core/avatar.gd").influence(), GS.player.get("techniques", []).size()])

func _wars() -> String:
	var out := []
	for a in Data.KINGDOMS:
		for b in Data.KINGDOMS:
			if a < b and GS.at_war(a, b):
				out.append("%s-%s" % [a.left(4), b.left(4)])
	return ",".join(out)

## Story parties that hunt the player: fight them (or not) like a player would.
func _handle_encounters(persona: String) -> void:
	for id in GS.parties.keys():
		if not GS.parties.has(id):
			continue
		var pt: Dictionary = GS.parties[id]
		if not pt.has("story"):
			continue
		if pt.pos.distance_to(GS.player_party().pos) > 12.0:
			continue
		var ratio: float = GS.sim.party_power(pt) / maxf(1.0, GS.sim.party_power(GS.player_party()))
		if persona == "chaos" and randf() < 0.3:
			continue
		if ratio < 1.6 or persona == "warlord":
			GS.sim.on_party_defeated(id, "player")
			GS.add_renown(5)

## Where would this persona go today?
func _pick_destination(persona: String) -> String:
	var cands := []
	for o in Story._options:
		if Story.ok(o.get("if", {}).duplicate()) or _ok_ignoring_location(o):
			cands.append(o.sid)
	if persona == "chaos":
		if randf() < 0.5 or cands.is_empty():
			var all := Data.settlements.keys()
			return all[randi() % all.size()]
		return cands[randi() % cands.size()]
	if cands.is_empty():
		return ""
	return cands[randi() % cands.size()]

func _ok_ignoring_location(o: Dictionary) -> bool:
	return Story.ok(o.get("if", {}))

## Walk one dialogue. Returns the number of choices made.
func _answer(id: String, persona: String) -> int:
	var d: Dictionary = Story.dialogue(id)
	if d.is_empty():
		_issue("queued missing dialogue " + id)
		return 0
	var nid: String = d.start
	var n := 0
	var guard := 0
	var visited := {}
	while nid != "" and guard < 80:
		guard += 1
		var node: Dictionary = d.nodes.get(nid, {})
		if node.is_empty():
			_issue("%s: missing node %s" % [id, nid])
			return n
		var key: String = id + "/" + nid
		if not visited.has(key):
			visited[key] = true
			Story.apply(node.get("do", []))
		var choices: Array = node.get("choices", [])
		if choices.is_empty():
			nid = node.get("next", "")
			continue
		var enabled := choices.filter(func(c): return Story.ok(c.get("if", {})))
		if enabled.is_empty():
			_issue("%s/%s: every choice disabled (state trap)" % [id, nid])
			return n
		var pick: Dictionary
		match persona:
			"chaos": pick = enabled[randi() % enabled.size()]
			"story": pick = _prefer(enabled, ["Hana", "Juro", "Pemba", "Nima", "Ukiuk", "Shen Mu", "Reika", "Kesi", "together", "choice", "Council", "rebuild", "Petition", "Let her", "promise", "shoulder", "Nudge", "Burn your letter", "swamp", "Pay", "vouches", "Fight"])
			"warlord": pick = _prefer(enabled, ["Fight", "take it", "Kill", "Do what you came", "Turn her in", "Kuro", "Fire Lord", "Break in", "challenge", "open them for you", "Get rich", "Put it back"])
		n += 1
		Story.apply(pick.get("do", []))
		if pick.has("goto"):
			return n + _answer(pick.goto, persona)
		nid = pick.get("next", "")
		if visited.has(id + "/" + nid) and persona != "chaos" and nid != "":
			# loops back to a hub; leave politely
			return n
	if guard >= 80:
		_issue("%s: conversation did not terminate" % id)
	return n

func _prefer(enabled: Array, words: Array) -> Dictionary:
	for w in words:
		for c in enabled:
			if String(c.text).findn(w) >= 0:
				return c
	return enabled[0]

func _check_invariants(persona: String, seed: int) -> void:
	var tag := "%s#%d day %d" % [persona, seed, GS.day()]
	var seen := {}
	for cid in GS.player.companions:
		if seen.has(cid):
			_issue(tag + ": duplicate companion " + cid)
		seen[cid] = true
		var a := Story.approval(cid)
		if a < -100 or a > 100:
			_issue(tag + ": approval out of range " + cid)
	if GS.player.gold < 0:
		_issue(tag + ": negative gold %d" % GS.player.gold)
	for lid in GS.lords:
		var lr: Dictionary = GS.lords[lid]
		if lr.party != "" and not GS.parties.has(lr.party):
			_issue(tag + ": lord %s points at a missing party" % lid)
	for id in GS.parties:
		var p: Dictionary = GS.parties[id]
		if p.kind != "player" and Roster.total(p.roster) <= 0 and not p.has("story"):
			pass
		if is_nan(p.pos.x) or is_nan(p.pos.y):
			_issue(tag + ": NaN position for " + id)
	if Story.flag("ending_told") and GS.at_war("fire_nation", "earth_kingdom") and GS.day() - int(Story.flag("accord_day", 0)) < 60:
		_issue(tag + ": war resumed within 60 days of the Kyoshi Accord")
	var q: Array = GS.flags.get("dlg_queue", [])
	if q.size() > 8:
		_issue(tag + ": dialogue queue backing up (%d)" % q.size())
