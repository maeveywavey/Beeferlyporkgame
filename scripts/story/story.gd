extends RefCounted
## Story engine: dialogue graphs, companion approval, personal quests and the
## main storyline. Content lives in the dialogue scripts listed in SOURCES;
## this file only interprets it. All state is kept in GS.flags (saved).
##
## Dialogue format (see docs/02_writers_room.md for the writing):
##   "id": {"start": "a", "nodes": {"a": {"who": "hana", "expr": "thoughtful",
##       "text": "...", "do": [effects], "next": "b" | "choices": [
##       {"text": "...", "next": "c", "if": {conditions}, "hint": "...", "do": [effects]}]}}}
## A node with neither "next" nor "choices" ends the conversation.

const Roster = preload("res://scripts/core/roster.gd")
const SOURCES := [
	"res://scripts/story/main_story.gd",
	"res://scripts/story/companion_quests.gd",
	"res://scripts/story/camp_talk.gd",
]

static var _cache := {}
static var _triggers := []
static var _options := []
static var _spawns := {}
static var _npcs := {}

static func _load() -> void:
	if not _cache.is_empty():
		return
	for path in SOURCES:
		var src = load(path)
		_cache.merge(src.DIALOGUES)
		_triggers.append_array(src.TRIGGERS)
		_options.append_array(src.OPTIONS)
		_spawns.merge(src.SPAWNS)
		_npcs.merge(src.NPCS)

static func dialogue(id: String) -> Dictionary:
	_load()
	return _cache.get(id, {})

static func npc(id: String) -> Dictionary:
	_load()
	return _npcs.get(id, {})

static func has_dialogue(id: String) -> bool:
	_load()
	return _cache.has(id)

# ---------------------------------------------------------------------------
# State helpers
# ---------------------------------------------------------------------------
static func flag(key: String, default = false):
	return GS.flags.get(key, default)

static func set_flag(key: String, value) -> void:
	GS.flags[key] = value

static func approval(cid: String) -> int:
	return int(GS.companion_state(cid).get("approval", 0))

static func change_approval(cid: String, n: int) -> void:
	if not GS.player.companions.has(cid) or n == 0:
		return
	var cs: Dictionary = GS.companion_state(cid)
	cs.approval = clampi(int(cs.get("approval", 0)) + n, -100, 100)
	var nm: String = Data.companions[cid].get("short", cid)
	if absi(n) >= 5:
		GS.log_msg("%s %s." % [nm, "approves" if n > 0 else "disapproves"], Color(0.6, 0.9, 0.6) if n > 0 else Color(1, 0.6, 0.45))
	if cs.approval <= -60:
		queue("leave_" + cid if has_dialogue("leave_" + cid) else "leave_generic_" + cid)

static func in_party(cid: String) -> bool:
	return GS.player.companions.has(cid) and not _away(cid)

static func _away(cid: String) -> bool:
	return float(GS.companion_state(cid).get("away_until", -1.0)) > GS.hours

## Text substitution: {name}, {they}/{them}/{their} for the player's pronouns.
static func fmt(text: String) -> String:
	var g: String = GS.player.get("look", {}).get("pronouns", "they")
	var pr: Array = {"he": ["he", "him", "his"], "she": ["she", "her", "her"], "they": ["they", "them", "their"]}.get(g, ["they", "them", "their"])
	return text.replace("{name}", GS.player.get("name", "")).replace("{they}", pr[0]).replace("{them}", pr[1]).replace("{their}", pr[2])

# ---------------------------------------------------------------------------
# Queue: dialogues waiting to be shown on the map
# ---------------------------------------------------------------------------
static func queue(id: String) -> void:
	if not GS.flags.has("dlg_queue"):
		GS.flags.dlg_queue = []
	if not GS.flags.dlg_queue.has(id) and has_dialogue(id):
		GS.flags.dlg_queue.append(id)

static func has_pending() -> bool:
	return not GS.flags.get("dlg_queue", []).is_empty()

static func pop_pending() -> String:
	var q: Array = GS.flags.get("dlg_queue", [])
	return "" if q.is_empty() else q.pop_front()

# ---------------------------------------------------------------------------
# Conditions
# ---------------------------------------------------------------------------
static func ok(cond: Dictionary) -> bool:
	for k in cond:
		if not _ok1(k, cond[k]):
			return false
	return true

static func _ok1(k: String, v) -> bool:
	match k:
		"flag":
			return bool(flag(v))
		"not_flag":
			return not bool(flag(v))
		"flags":
			for f in v:
				if not flag(f):
					return false
			return true
		"eq":
			var cur = flag(v[0], null)
			if cur == null and typeof(v[1]) == TYPE_STRING:
				cur = ""
			return cur == v[1]
		"has_page":
			return pages().has(int(v))
		"companion":
			return in_party(v)
		"no_companion":
			return not GS.player.companions.has(v)
		"gold":
			return GS.player.gold >= int(v)
		"standing":
			return GS.standing_rank() >= int(v)
		"approval":
			return in_party(v[0]) and approval(v[0]) >= int(v[1])
		"rel":
			return int(GS.player.faction_rel.get(v[0], 0)) >= int(v[1])
		"bend":
			return GS.player.bend == v
		"renown":
			return GS.player.renown >= int(v)
		"skill":
			return GS.skill(v[0]) >= int(v[1])
		"day":
			return GS.day() >= int(v)
		"days_since":
			return GS.day() - int(flag(v[0], -9999)) >= int(v[1])
		"pages":
			return pages().size() >= int(v)
		"at":
			return GS.player.get("inside", "") == v or _nearest(v) <= 12.0
		"owns":
			return GS.settlements[v].faction == GS.player_faction() or GS.settlements[v].owner == "player"
		"peace_with":
			return _peace_count() >= int(v)
		"pronouns":
			return v.has(GS.player.get("look", {}).get("pronouns", "they"))
		"near_faction":
			for sid in Data.settlements:
				if GS.settlements[sid].faction == v and _nearest(sid) <= 140.0:
					return true
			return false
		"call":
			return callv_bool(v)
	return true

static func _nearest(sid: String) -> float:
	return GS.player_party().pos.distance_to(Data.settlements[sid].pos)

static func _peace_count() -> int:
	var n := 0
	for k in Data.KINGDOMS:
		if not GS.at_war(GS.player_faction(), k):
			n += 1
	return n

static func callv_bool(name: String) -> bool:
	match name:
		"has_wounded": return Roster.wounded(GS.player_party().roster) > 0
		"any_companion": return not GS.player.companions.is_empty()
		"has_evidence": return flag("dai_li_testify") or flag("kuro_ledgers") or flag("kuro_implicated")
		"pemba_or_nima": return in_party("pemba") or in_party("nima")
		"nima_wins": return _nima_wins()
		"nima_loses": return not _nima_wins()
	return false

## Nima's duel: decided by how the player prepared her and how much she
## trusts them, never by a hidden dice roll.
static func _nima_wins() -> bool:
	var a := approval("nima")
	match flag("nima_prep", ""):
		"study": return GS.player.bend == "water" or GS.skill("tactics") >= 3 or a >= 45
		"kaya": return a >= 25
		"believe": return a >= 40
	return false

# ---------------------------------------------------------------------------
# Effects
# ---------------------------------------------------------------------------
static func apply(effects: Array, map = null) -> void:
	for e in effects:
		var op: String = e[0]
		match op:
			"approval": change_approval(e[1], int(e[2]))
			"flag": set_flag(e[1], e[2])
			"flag_day": set_flag(e[1], GS.day())
			"gold": GS.add_gold(int(e[1]))
			"renown": GS.add_renown(int(e[1]))
			"honor": GS.player.honor = int(GS.player.get("honor", 0)) + int(e[1])
			"xp": GS.give_player_xp(int(e[1]))
			"rel": GS.change_faction_rel(e[1], int(e[2]))
			"lord_rel": GS.change_lord_rel(e[1], int(e[2]))
			"peace": GS.make_peace(e[1], e[2])
			"war": GS.declare_war(e[1], e[2])
			"journal": journal(e[1], e[2], e[3])
			"journal_done": journal_done(e[1], e[2] if e.size() > 2 else "")
			"join":
				if not GS.player.companions.has(e[1]):
					GS.player.companions.append(e[1])
			"leave":
				GS.player.companions.erase(e[1])
				GS.log_msg("%s has left your party." % Data.companions[e[1]].get("short", e[1]), Color(1, 0.7, 0.5))
			"away":
				GS.companion_state(e[1]).away_until = GS.hours + 24.0 * float(e[2])
			"companion_mod": GS.companion_state(e[1])[e[2]] = e[3]
			"spawn": spawn(e[1])
			"close_windows":
				if map != null:
					map.close_all_windows()
			"wait": GS.sim.advance(float(e[1]))
			"prosperity":
				var s: Dictionary = GS.settlements[e[1]]
				s.prosperity = clampf(s.prosperity + float(e[2]), 5.0, 100.0)
			"item": GS.player.items.append(e[1])
			"troops": Roster.add(GS.player_party().roster, e[1], int(e[2]))
			"heal": Roster.heal_fraction(GS.player_party().roster, float(e[1]))
			"queue": queue(e[1])
			"page": give_page(int(e[1]))
			"log": GS.log_msg(fmt(e[1]), Color(1, 0.85, 0.55))
			"skill_points": GS.player.skill_points += int(e[1])
			"standing": GS.raise_standing(e[1])
			"call": call_effect(e[1], e.slice(2))

## Story effects too specific for the generic list.
static func call_effect(name: String, args: Array) -> void:
	match name:
		"ending":
			Endings.apply(args[0])
		"lose_xp":
			GS.player.xp = maxi(0, int(GS.player.xp) - int(args[0]))
		"refugee_route_betrayed":
			set_flag("refugees_betrayed", GS.day())
		"two_paths":
			set_flag("two_paths", true)
			GS.log_msg("The Northern council changes the Law of the Two Paths. Women of the Water Tribe may now learn to fight. (Moon Guard troops unlocked)", Color(0.6, 0.85, 1))
		"juro_fire":
			GS.companion_state("juro").bend = "fire"
			GS.companion_state("juro").power = 1.3
		"hana_mastery":
			GS.companion_state("hana").power_bonus = 0.4
		"kesi_swamp":
			# The clan moves on; the Si Wong raiders thin out
			set_flag("sand_clan_safe", true)
		"red_lanterns_friends":
			GS.change_faction_rel("red_lanterns", 50)
			GS.settlements["ba_sing_se"].prosperity = minf(100.0, GS.settlements["ba_sing_se"].prosperity + 6.0)
		"red_lanterns_enemies":
			GS.change_faction_rel("red_lanterns", -60)
		"omashu_talks":
			if GS.at_war("fire_nation", "omashu"):
				GS.make_peace("fire_nation", "omashu")
			set_flag("omashu_fn_talks", true)
			if flag("queen_ally"):
				GS.make_peace("earth_kingdom", "omashu")
				GS.log_msg("With the Earth Queen's quiet blessing, Ba Sing Se and Omashu agree to talk instead of fight. The Secession is not over, but the war may be.", Color(0.7, 1, 0.7))

const Endings = preload("res://scripts/story/endings.gd")

# ---------------------------------------------------------------------------
# Journal
# ---------------------------------------------------------------------------
static func journal(qid: String, title: String, text: String) -> void:
	if not GS.flags.has("journal"):
		GS.flags.journal = {}
	var j: Dictionary = GS.flags.journal
	var order: int = j[qid].order if j.has(qid) else j.size()
	var is_new := not j.has(qid)
	j[qid] = {"title": title, "text": fmt(text), "done": false, "order": order}
	if is_new:
		GS.log_msg("New quest: %s" % title, Color(1, 0.9, 0.5))

static func journal_done(qid: String, text: String = "") -> void:
	var j: Dictionary = GS.flags.get("journal", {})
	if j.has(qid):
		j[qid].done = true
		if text != "":
			j[qid].text = fmt(text)

# ---------------------------------------------------------------------------
# The Avatar's logbook
# ---------------------------------------------------------------------------
static func pages() -> Array:
	return GS.flags.get("pages", [])

static func give_page(n: int) -> void:
	if not GS.flags.has("pages"):
		GS.flags.pages = []
	if GS.flags.pages.has(n):
		return
	GS.flags.pages.append(n)
	GS.flags.pages.sort()
	GS.add_renown(8)   # word gets around: someone is collecting the Avatar's pages
	GS.log_msg("You recovered page %s of the Avatar's logbook (%d of 6)." % [["", "I", "II", "III", "IV", "V", "VI"][n], GS.flags.pages.size()], Color(1, 0.85, 0.4))
	queue("page_%d" % n)
	if GS.flags.pages.size() >= 6 and not flag("ms_truth"):
		queue("ms_truth")

# ---------------------------------------------------------------------------
# Story enemies: parties that hunt the player and resolve a beat when beaten
# ---------------------------------------------------------------------------
static func spawn(sp_id: String) -> String:
	_load()
	var sp: Dictionary = _spawns.get(sp_id, {})
	if sp.is_empty():
		return ""
	var pp: Dictionary = GS.player_party()
	var pos: Vector2 = pp.pos + Vector2(randf_range(-4, 4), randf_range(3, 6))
	var p := GS.make_party("", sp.name, "bandit", sp.get("faction", "bandits"), pos)
	p.story = sp_id
	p.anchor = pos
	# Some ambushes scale to the party they ambush, so a fresh start isn't a wipe
	var scale := 1.0
	if sp.get("scale", false):
		scale = clampf(float(GS.party_size()) / 12.0, 0.45, 1.5)
	for t in sp.troops:
		Roster.add(p.roster, t[0], maxi(1, int(round(int(t[1]) * scale))))
	p.gold = int(sp.get("gold", 200))
	p.target_party = "player"
	p.moving = true
	p.state = "chase"
	p.chase_until = GS.hours + 48.0
	set_flag("spawn_" + sp_id, p.id)
	return p.id

## Called by the world simulation whenever a party is defeated.
static func on_party_defeated(p: Dictionary, victor_faction: String) -> void:
	if not p.has("story"):
		return
	if victor_faction != GS.player_faction() and victor_faction != "player":
		return
	_load()
	var sp: Dictionary = _spawns.get(p.story, {})
	set_flag("beaten_" + p.story, true)
	apply(sp.get("on_defeat", []))

# ---------------------------------------------------------------------------
# Triggers and settlement options
# ---------------------------------------------------------------------------
## event: "daily" | "arrive" | "camp" | "battle_won" | "raid"
static func fire(event: String, sid: String = "") -> void:
	_load()
	for t in _triggers:
		if t.on != event:
			continue
		if t.has("sid") and t.sid != sid:
			continue
		var key: String = "trig_" + t.dlg
		if t.get("once", true) and flag(key):
			continue
		if not ok(t.get("if", {})):
			continue
		if randf() > float(t.get("chance", 1.0)):
			continue
		set_flag(key, true)
		apply(t.get("do", []))
		queue(t.dlg)
	_reactions(event, sid)

## Story-driven choices offered in a settlement's menu.
static func settlement_options(sid: String) -> Array:
	_load()
	var out := []
	for o in _options:
		if o.sid != sid:
			continue
		if o.has("once") and flag("opt_" + o.dlg):
			continue
		if ok(o.get("if", {})):
			out.append(o)
	return out

# ---------------------------------------------------------------------------
# Companion reactions to what the player does
# ---------------------------------------------------------------------------
const REACTIONS := {
	"raid": {"pemba": -15, "nima": -10, "kesi": -12, "juro": -12, "hana": -6, "ukiuk": -6, "shen_mu": -8, "reika": 2},
	"donate": {"pemba": 5, "hana": 3, "nima": 2, "kesi": 2},
	"battle_won": {"ukiuk": 1, "reika": 1},
	"release_lord": {"pemba": 4, "nima": 2, "juro": 2},
	"agni_kai_won": {"reika": 3, "juro": 2},
	"refuse_duel": {"reika": -3},
}

static func _reactions(event: String, _sid: String) -> void:
	react(event)

static func react(event: String) -> void:
	var r: Dictionary = REACTIONS.get(event, {})
	for cid in r:
		change_approval(cid, int(r[cid]))
