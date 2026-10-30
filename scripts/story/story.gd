extends RefCounted
## Story engine: dialogue graphs, companion approval, personal quests and the
## main storyline. Content lives in the dialogue scripts listed in SOURCES;
## this file only interprets it. All state is kept in GS.flags (saved).
##
## Dialogue format (see docs/setting.md for the writing):
##   "id": {"start": "a", "nodes": {"a": {"who": "hana", "expr": "thoughtful",
##       "text": "...", "do": [effects], "next": "b" | "choices": [
##       {"text": "...", "next": "c", "if": {conditions}, "hint": "...", "do": [effects]}]}}}
## A node with neither "next" nor "choices" ends the conversation.

const Roster = preload("res://scripts/core/roster.gd")
const AvatarSys = preload("res://scripts/core/avatar.gd")
const DLC = preload("res://scripts/dlc/registry.gd")
const Tech = preload("res://scripts/battle/techniques.gd")
const SOURCES := [
	"res://scripts/story/main_story.gd",
	"res://scripts/story/companion_quests.gd",
	"res://scripts/story/camp_talk.gd",
	"res://scripts/story/avatar_story.gd",
]

static var _cache := {}
## Tests walk dialogues headlessly; effects that would change scene are skipped.
static var no_scene_change := false
static var _triggers := []
static var _options := []
static var _spawns := {}
static var _npcs := {}

static func _load() -> void:
	if not _cache.is_empty():
		return
	var paths: Array = SOURCES.duplicate()
	var tags := {}
	for el in DLC.EXPANSIONS:
		paths.append(DLC.EXPANSIONS[el].story)
		tags[DLC.EXPANSIONS[el].story] = el
	for path in paths:
		var src = load(path)
		_cache.merge(src.DIALOGUES)
		_spawns.merge(src.SPAWNS)
		_npcs.merge(src.NPCS)
		# Expansion triggers and options remember their element, so switching
		# an expansion off in Settings hides them
		for t in src.TRIGGERS:
			var t2: Dictionary = t.duplicate()
			if tags.has(path):
				t2.dlc = tags[path]
			_triggers.append(t2)
		for o in src.OPTIONS:
			var o2: Dictionary = o.duplicate()
			if tags.has(path):
				o2.dlc = tags[path]
			_options.append(o2)

static func dialogue(id: String) -> Dictionary:
	_load()
	return _cache.get(id, {})

static func npc(id: String) -> Dictionary:
	_load()
	# The Avatar and the person they love change with the era
	if id == "avatar":
		return AvatarSys.npc()
	if id == "av_loved":
		return AvatarSys.loved_npc()
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

## Text substitution: {name}, {they}/{them}/{their} for the player's pronouns;
## {avatar}, {av_name}, {av_they}/{av_them}/{av_their}, {loved}, {loved_role},
## {av_home}, {title} and {need} for the Avatar system.
static func fmt(text: String) -> String:
	var g: String = GS.player.get("look", {}).get("pronouns", "they")
	var pr: Array = {"he": ["he", "him", "his"], "she": ["she", "her", "her"], "they": ["they", "them", "their"]}.get(g, ["they", "them", "their"])
	text = text.replace("{name}", GS.player.get("name", "")).replace("{they}", pr[0]).replace("{them}", pr[1]).replace("{their}", pr[2])
	if text.contains("{"):
		var A: Dictionary = AvatarSys.state()
		var ap: Array = AvatarSys.pronouns()
		var L: Dictionary = A.get("loved", {})
		var need: String = A.get("order", [""])[0] if not A.get("order", []).is_empty() else ""
		text = text.replace("{avatar}", AvatarSys.display_name()).replace("{av_name}", String(A.get("name", "")))
		text = text.replace("{av_they}", ap[0]).replace("{av_them}", ap[1]).replace("{av_their}", ap[2])
		text = text.replace("{loved}", String(L.get("name", ""))).replace("{loved_role}", String(L.get("role", "")))
		text = text.replace("{av_home}", Data.settlements.get(A.get("home", ""), {}).get("name", "their home"))
		text = text.replace("{title}", AvatarSys.ruler_title() if AvatarSys.ruler_title() != "" else "warlord")
		text = text.replace("{need}", Data.element_name(need).to_lower() if need != "" else "the elements")
		text = text.replace("{element}", String(GS.player.get("bend", "")))
	return text

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
		"era":
			return String(GS.flags.get("era", "quiet")) == v
		"tech":
			return Tech.known(v)
		"no_tech":
			return not Tech.known(v)
		"bends":
			# the player, or a companion in the party, bends this element
			return load("res://scripts/core/bending_work.gd").doer(v) != ""
		"master":
			return GS.player.get("master_title", "") != "" and GS.player.bend == v
		"season":
			return GS.season() == v
		"cosmic":
			match v:
				"comet": return GS.is_comet()
				"lunar": return GS.is_lunar_eclipse()
				"solar": return GS.is_eclipse()
				"full_moon": return GS.is_full_moon() and not GS.is_daytime()
			return false
		"forms_uses":
			var u := 0
			for f in GS.player.get("forms", []):
				u += int(f.get("uses", 0))
			return u >= int(v)
		"duel_wins":
			return int(GS.flags.get("duel_wins", 0)) >= int(v)
		"techs":
			# at least v[1] techniques of element v[0]
			return GS.player.get("techniques", []).filter(func(x): return Tech.TECHNIQUES.has(x) and Tech.TECHNIQUES[x].element == v[0]).size() >= int(v[1])
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
		"has_evidence": return flag("censor_testify") or flag("kuro_ledgers") or flag("kuro_implicated")
		"pemba_or_nima": return in_party("pemba") or in_party("nima")
		"nima_wins": return _nima_wins()
		"nima_loses": return not _nima_wins()
		"av_hostage": return AvatarSys.state().get("hostage", false)
		"not_master": return GS.player.get("master_title", "") == ""
		"not_air": return GS.player.get("bend", "") != "air"
		"wx_can_share": return GS.skill("trade") >= 3 or GS.player.gold >= 800
		"ex_academy_ok": return not flag("hana_spared") and not flag("censor_enemy")
		"fx_ember_clean": return AvatarSys.infamy() <= int(flag("fx_ember_inf", 0))
		"fx_ember_dirty": return AvatarSys.infamy() > int(flag("fx_ember_inf", 0))
		"av_seat": return AvatarSys.seat_near() != ""
		"av_no_seat": return AvatarSys.seat_near() == ""
		"av_young": return AvatarSys.stage() == "young"
		"av_prime": return AvatarSys.stage() == "prime"
		"av_elder": return AvatarSys.stage() == "elder"
		"av_ruler": return AvatarSys.ruler_title() != ""
		"av_friend": return int(AvatarSys.state().get("attitude", 0)) >= 20
		"av_not_friend": return int(AvatarSys.state().get("attitude", 0)) < 20
		"av_kept": return flag("ms_path", "") == "kept"
		"av_not_kept": return flag("ms_path", "") != "kept"
		"av_wars": return _peace_count() < Data.KINGDOMS.size()
		"av_intel": return AvatarSys.state().get("intel", false) and not AvatarSys.state().get("hostage", false)
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
			# Spawn an ambush and fight it as soon as the conversation closes,
			# alone: nobody else on the road joins a story fight.
			"fight":
				var fid := spawn(e[1])
				if fid != "":
					GS.flags.story_fight = fid
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
			"skill_points", "attr_points": GS.player.attr_points += int(e[1])
			"standing": GS.raise_standing(e[1])
			"infamy": AvatarSys.add_infamy(int(e[1]), GS.player_party().pos, e[2] if e.size() > 2 else "")
			"learn": Tech.learn(e[1])
			"master":
				GS.player.master_title = Tech.MASTER_TITLES.get(e[1], "Master")
				GS.log_msg("You are now a %s." % GS.player.master_title, Color(1, 0.9, 0.5))
			"comp_tech":
				# a companion's signature technique on a slot
				var cs: Dictionary = GS.companion_state(e[1])
				if not cs.has("loadout"):
					cs.loadout = {}
				cs.loadout[e[2]] = e[3]
			"good": GS.add_good(e[1], int(e[2]))
			"av_attitude":
				var A: Dictionary = AvatarSys.state()
				A.attitude = clampi(int(A.get("attitude", 0)) + int(e[1]), -100, 100)
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
		"avatar_battle":
			if not no_scene_change:
				AvatarSys.start_battle()
		"fx_ember_infamy": set_flag("fx_ember_inf", AvatarSys.infamy())
		"wx_pay_share":
			if GS.skill("trade") < 3:
				GS.add_gold(-800)
		"duel":
			# A story Agni Kai, fought at once (GS.start_duel changes scene)
			if GS.is_inside_tree() and not no_scene_change:
				GS.start_duel(args[0])
		"avatar_defeated": AvatarSys.on_defeated()
		"avatar_yield":
			AvatarSys.judgement(true)
		"avatar_hostage": AvatarSys.use_hostage()
		"avatar_take_hostage": AvatarSys.take_hostage()
		"avatar_teach": AvatarSys.begin_teaching()
		"avatar_taught": AvatarSys.finish_teaching()
		"avatar_pledge":
			var A: Dictionary = AvatarSys.state()
			A.pledge = true
			A.pledge_infamy = AvatarSys.infamy()
			A.state = "free"
		"avatar_defy":
			var A2: Dictionary = AvatarSys.state()
			A2.defied = true
			A2.pledge = false
		"avatar_leave":
			AvatarSys.dismiss_company()
			AvatarSys.state().state = "free"
		"avatar_amends":
			var pay := maxi(500, int(GS.player.gold * 0.3))
			GS.add_gold(-pay)
			AvatarSys.add_infamy(-60, GS.player_party().pos)
			var center: Vector2 = AvatarSys.cruelty_center()
			for sid in GS.settlements:
				if center != Vector2.INF and Data.settlements[sid].pos.distance_to(center) <= AvatarSys.LOCAL_RADIUS:
					GS.settlements[sid].prosperity = minf(100.0, GS.settlements[sid].prosperity + 6.0)
			GS.flags.infamy_log = []
		"avatar_local_fight":
			AvatarSys.spawn_company()
			if not no_scene_change:
				AvatarSys.start_battle()
		"avatar_peace":
			# The Avatar brokers one truce for a friend who asks
			for k in Data.KINGDOMS:
				if GS.at_war(GS.player_faction(), k):
					GS.make_peace(GS.player_faction(), k)
					GS.log_msg("With %s at the table, the %s agrees to a truce." % [AvatarSys.display_name(), Data.factions[k].name], Color(0.8, 0.95, 1))
					break
			AvatarSys.state().peace_day = GS.day()
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
		if t.has("dlc") and not DLC.enabled(t.dlc):
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
		if o.has("dlc") and not DLC.enabled(o.dlc):
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
	"raid": {"pemba": -15, "nima": -10, "kesi": -12, "juro": -12, "hana": -6, "ukiuk": -6, "shen_mu": -8, "reika": 2,
		"sayuri": -6, "huan": -12, "gao_ming": -10, "yangzom": -15},
	"donate": {"pemba": 5, "hana": 3, "nima": 2, "kesi": 2, "huan": 3, "gao_ming": 4, "yangzom": 4},
	"battle_won": {"ukiuk": 1, "reika": 1, "sayuri": 1},
	"release_lord": {"pemba": 4, "nima": 2, "juro": 2, "yangzom": 3, "sayuri": 2},
	"agni_kai_won": {"reika": 3, "juro": 2, "sayuri": 5},
	"refuse_duel": {"reika": -3, "sayuri": -2},
	"execute": {"pemba": -30, "nima": -15, "juro": -15, "hana": -10, "kesi": -10, "shen_mu": -15, "ukiuk": -10, "reika": -5,
		"sayuri": -15, "huan": -20, "gao_ming": -15, "yangzom": -30},
}

static func _reactions(event: String, _sid: String) -> void:
	react(event)

static func react(event: String) -> void:
	var r: Dictionary = REACTIONS.get(event, {})
	for cid in r:
		change_approval(cid, int(r[cid]))
