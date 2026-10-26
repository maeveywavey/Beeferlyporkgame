extends RefCounted
## The Avatar as a persistent figure in the world (docs/07_avatar_and_dlc.md).
##
## The player is never the Avatar. The Avatar is an NPC who ages with the
## calendar, spends much of their life out of reach (in the Spirit World, in
## meditation, at the far edges of the map), and comes to the player for four
## reasons only:
##   ruler   - the player holds great power; the Avatar seeks cooperation
##   tyrant  - great power used cruelly; the Avatar must restore balance
##   teacher - a young Avatar needs a master of the player's element (top 1%)
##   local   - local cruelty, and only if the Avatar is already nearby
## Childhood and old age are when the Avatar is least involved.
## All state lives in GS.flags.avatar and is saved with the game.

const Roster = preload("res://scripts/core/roster.gd")

const DAYS_PER_YEAR := 360.0
const CYCLE := ["fire", "air", "water", "earth"]
const GREAT_POWER := 12.0         # influence at which rulers take notice
const TYRANT_INFAMY := 150        # infamy that, with great power, demands the Avatar
const LOCAL_INFAMY := 60          # infamy in one region within 45 days
const LOCAL_RADIUS := 120.0       # what counts as one region (map units)
const AVATAR_NEAR := 220.0        # how far the Avatar will come for local cruelty
const TEACHER_PCT := 99.0         # top 1% of benders of an element

const ERAS := {
	"quiet": {"name": "The Quiet Years", "story": true, "year0": 11, "label": "Quiet Year",
		"pitch": "Story campaign. Eleven years ago the Avatar drowned. The next Avatar is a ten-year-old child somewhere in the world who has not been told. They are not yet part of events, and the world must manage on its own. Includes The Drowned Testament.",
		"short": "The Avatar is a child, untold and out of reach."},
	"young": {"name": "The Young Avatar", "story": false, "year0": 1, "label": "Year of Avatar",
		"pitch": "Sandbox. Avatar Siku of the Southern Water Tribe was told she is the Avatar this winter. At sixteen she must learn three more elements, and she is looking for masters. She is also still sixteen.",
		"short": "A teenage Avatar, learning the elements and looking for teachers."},
	"prime": {"name": "The Avatar's Prime", "story": false, "year0": 23, "label": "Year of Avatar",
		"pitch": "Sandbox. Avatar Lei Shan, born in the Earth Kingdom's Jade Terraces, is thirty-eight and a master of all four elements. He is the busiest person in the world, and the hardest to pin down.",
		"short": "An Avatar at full strength, involved everywhere."},
	"elder": {"name": "The Elder Avatar", "story": false, "year0": 69, "label": "Year of Avatar",
		"pitch": "Sandbox. Avatar Akane of the Fire Nation is eighty-four. She spends most of her days in meditation and the Spirit World, and leaves her lake hamlet only for what truly threatens the balance.",
		"short": "An old Avatar, mostly in the Spirit World, roused only by great evil."},
}

## The Avatar of each sandbox era. The Quiet Years child is generated per game.
const FIGURES := {
	"young": {"name": "Siku", "pronouns": "she", "nation": "water", "culture": "south", "age": 16.0, "home": "whaletail",
		"vlook": {"sex": "f", "hair": "Hair_Long", "accessory": "warpaint", "height": 0.94},
		"kit": "water_fur",
		"bio": "Sixteen, Southern Water Tribe, from Whaletail Island. Told she was the Avatar this winter. Gets seasick, which she regards as a personal insult from the ocean. Argues with her own past lives in her sleep.",
		"loved": {"name": "Ilik", "role": "her first waterbending teacher, a fisherman with one good knee", "vlook": {"sex": "m", "hair": "Hair_Long", "hair_color": Color(0.6, 0.6, 0.6)}, "culture": "south"}},
	"prime": {"name": "Lei Shan", "pronouns": "he", "nation": "earth", "culture": "earth", "age": 38.0, "home": "agrarian_vale",
		"vlook": {"sex": "m", "hair": "Hair_Buzzed", "beard": true, "accessory": "", "height": 1.04},
		"kit": "ek_armor",
		"bio": "Thirty-eight, born in the Earth Kingdom's Jade Terraces. Master of all four elements. Married to Wen, a potter who refuses to move to a temple. Laughs easily and remembers everyone's name, which is a kind of power.",
		"loved": {"name": "Wen", "role": "his husband, a potter in the Jade Terraces", "vlook": {"sex": "m", "hair": "Hair_SimpleParted"}, "culture": "earth"}},
	"elder": {"name": "Akane", "pronouns": "she", "nation": "fire", "culture": "fire", "age": 84.0, "home": "rocky_hamlet",
		"vlook": {"sex": "f", "hair": "Hair_Buns", "hair_color": Color(0.85, 0.85, 0.85), "accessory": "fn_noble", "height": 0.92},
		"kit": "sash",
		"bio": "Eighty-four, Fire Nation, from the Boiling Lake Hamlet. Has ended four wars and failed to prevent two more. Moves slowly in this world and quickly in the other one.",
		"loved": {"name": "Jinhua", "role": "her sworn sister, an old earthbender who keeps her house", "vlook": {"sex": "f", "hair": "Hair_Buns", "hair_color": Color(0.8, 0.8, 0.78)}, "culture": "earth"}},
}

## A Quiet Years child, by the nation they were born into (revealed at sixteen).
const CHILDREN := {
	"water": {"name": "Aput", "pronouns": "she", "culture": "north", "home": "spirit_fishery", "vlook": {"sex": "f", "hair": "Hair_Long"}, "kit": "water_fur"},
	"earth": {"name": "Shaoyu", "pronouns": "they", "culture": "earth", "home": "agrarian_vale", "vlook": {"sex": "m", "hair": "Hair_SimpleParted"}, "kit": "civ_robe"},
	"fire": {"name": "Natsu", "pronouns": "she", "culture": "fire", "home": "jang_hui", "vlook": {"sex": "f", "hair": "Hair_Buns", "accessory": "topknot"}, "kit": "sash"},
	"air": {"name": "Chodak", "pronouns": "he", "culture": "air", "home": "northern_air_temple", "vlook": {"sex": "m", "hair": "", "accessory": "air_arrow"}, "kit": "air_robes"},
}

## How readily the Avatar acts on each motive at each stage of life, and how
## much of their time they spend beyond reach.
const INVOLVEMENT := {
	"child": {"ruler": 0.0, "tyrant": 0.0, "teacher": 0.0, "local": 0.0, "spirit": 1.0},
	"young": {"ruler": 0.6, "tyrant": 0.7, "teacher": 1.0, "local": 0.8, "spirit": 0.45},
	"prime": {"ruler": 1.0, "tyrant": 1.0, "teacher": 0.0, "local": 1.0, "spirit": 0.35},
	"elder": {"ruler": 0.35, "tyrant": 0.6, "teacher": 0.0, "local": 0.25, "spirit": 0.7},
}

const STAGE_NAMES := {"child": "Childhood", "young": "Youth", "prime": "Prime of life", "elder": "Old age"}
const STAGE_DESC := {
	"child": "A child who does not yet know what they are. The sages are searching. They take no part in the world's affairs.",
	"young": "Newly told, still learning. Often with a teacher or in the Spirit World. Comes readily to masters of the element they need, less readily to kings.",
	"prime": "At full strength and everywhere at once: brokering truces, lifting sieges, sitting with rulers. Still spends a third of their life where you cannot follow.",
	"elder": "Spends most days in meditation and the Spirit World. Travels only for what truly threatens the balance, and sends word before coming.",
}

static func _story():
	return load("res://scripts/story/story.gd")

static func state() -> Dictionary:
	return GS.flags.get("avatar", {})

static func era() -> String:
	return String(GS.flags.get("era", "quiet"))

static func era_info() -> Dictionary:
	return ERAS.get(era(), ERAS.quiet)

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
static func init_era(e: String) -> void:
	if not ERAS.has(e):
		e = "quiet"
	GS.flags.era = e
	var A := {"era": e, "revealed": e != "quiet", "loc": "spirit", "loc_until": randi_range(3, 12), "pos": Vector2(800, 600),
		"attitude": 0, "state": "free", "due": {}, "court_done": false, "warned": false, "pledge": false, "pledge_infamy": 0,
		"defied": false, "defeats": 0, "wounded_until": -1, "hostage": false, "diversion": false, "demoralized": false,
		"intel": false, "teach_offered": [], "taught": [], "seen": [], "rumour": {}, "teach_until": -1, "local_cd": -1,
		"audience_day": -99}
	if e == "quiet":
		var nation: String = CYCLE.pick_random()
		var c: Dictionary = CHILDREN[nation]
		A.merge({"name": c.name, "pronouns": c.pronouns, "nation": nation, "culture": c.culture, "age0": 10.0,
			"home": c.home, "vlook": c.vlook, "kit": c.kit, "mastered": [nation], "order": _order_from(nation),
			"bio": "The next Avatar. Ten years old, somewhere in the world, and not yet told.",
			"loved": {"name": "", "role": "", "vlook": {}, "culture": c.culture}}, true)
	else:
		var f: Dictionary = FIGURES[e]
		A.merge({"name": f.name, "pronouns": f.pronouns, "nation": f.nation, "culture": f.culture, "age0": f.age,
			"home": f.home, "vlook": f.vlook, "kit": f.kit, "bio": f.bio, "loved": f.loved}, true)
		if e == "young":
			A.mastered = [f.nation]
			A.order = _order_from(f.nation)
			A.learn_until = randi_range(200, 260)
		else:
			A.mastered = ["water", "earth", "fire", "air"]
			A.order = []
	A.pos = Data.settlements[A.home].pos
	GS.flags.avatar = A

## Elements still to learn, in the order of the cycle after the native one.
static func _order_from(nation: String) -> Array:
	var i := CYCLE.find(nation)
	var out := []
	for k in range(1, 4):
		out.append(CYCLE[(i + k) % 4])
	return out

## Old saves predate the Avatar; give them the Quiet Years child.
static func ensure() -> void:
	if not GS.flags.has("era"):
		GS.flags.era = "quiet"
	if not GS.flags.has("avatar"):
		init_era(String(GS.flags.era))

# ---------------------------------------------------------------------------
# Age, stage, identity
# ---------------------------------------------------------------------------
static func age() -> float:
	return float(state().get("age0", 10.0)) + GS.day() / DAYS_PER_YEAR

static func stage() -> String:
	var A := state()
	if A.is_empty() or not A.get("revealed", false):
		return "child"
	var a := age()
	if a < 16.0:
		return "child"
	if a < 21.0:
		return "young"
	if a < 70.0:
		return "prime"
	return "elder"

static func known() -> bool:
	return bool(state().get("revealed", false))

static func display_name() -> String:
	return ("Avatar " + String(state().get("name", ""))) if known() else "the Avatar"

static func pronouns() -> Array:
	var g := String(state().get("pronouns", "they"))
	return {"he": ["he", "him", "his"], "she": ["she", "her", "her"]}.get(g, ["they", "them", "their"])

static func elements() -> Array:
	return state().get("mastered", [])

static func involvement(motive: String) -> float:
	return float(INVOLVEMENT[stage()].get(motive, 0.0))

## A speaker entry for the dialogue window.
static func npc() -> Dictionary:
	var A := state()
	var look: Dictionary = A.get("vlook", {}).duplicate()
	return {"name": display_name(), "culture": A.get("culture", "air"), "vlook": look, "kit": A.get("kit", "sash")}

static func loved_npc() -> Dictionary:
	var L: Dictionary = state().get("loved", {})
	return {"name": L.get("name", "the hostage"), "culture": L.get("culture", "earth"), "vlook": L.get("vlook", {})}

## Look for the Avatar's battle unit.
static func look() -> Dictionary:
	var A := state()
	var lk := {"sex": "m", "culture": A.get("culture", "air"), "kit": A.get("kit", "sash"), "outfit": "ranger"}
	lk.merge(A.get("vlook", {}), true)
	# Only an Air Nomad Avatar carries the arrows; other Avatars learn air without them
	if A.get("nation", "") == "air":
		lk.accessory = "air_arrow"
	return lk

# ---------------------------------------------------------------------------
# What the player has made of themselves
# ---------------------------------------------------------------------------
const TITLES := {"caldera": "Fire Lord", "omashu": "%s of Omashu", "agna_qela": "Chief of the Northern Water Tribe",
	"southern_tribe": "Chief of the Southern Water Tribe", "ba_sing_se": "Earth %s"}

## A ruler's title the player holds in their own name, or "".
static func ruler_title() -> String:
	if GS.player_faction() != "player":
		return ""
	var g: String = GS.player.get("look", {}).get("pronouns", "they")
	for sid in TITLES:
		if GS.settlements.has(sid) and GS.settlements[sid].owner == "player":
			var t: String = TITLES[sid]
			if t.contains("%s"):
				var word: String = {"he": "King", "she": "Queen"}.get(g, "Monarch")
				t = t % word
			return t
	return ""

static func influence() -> float:
	var v := 0.0
	for sid in GS.settlements:
		if GS.settlements[sid].owner == "player":
			v += float({"town": 3, "castle": 2, "village": 1}.get(Data.settlements[sid].type, 0))
	v += float(GS.player.renown) / 100.0
	v += float(Roster.total(GS.player_party().get("roster", []))) / 60.0
	if ruler_title() != "":
		v += 10.0
	if GS.player.get("status", "") == "vassal":
		v += 1.0
	return v

static func great_power() -> bool:
	return ruler_title() != "" or influence() >= GREAT_POWER

static func infamy() -> int:
	return int(GS.player.get("infamy", 0))

## Cruelty the world remembers. `pos` places it, so the Avatar can hear of it
## when they are near.
static func add_infamy(n: int, pos: Vector2, why: String = "") -> void:
	if n == 0:
		return
	# An Air Nomad who breaks the vows is remembered twice over
	if n > 0 and GS.player.get("background", "") in ["air_nomad", "temple_courier"]:
		GS.change_faction_rel("air_nomads", -int(n / 3))
	GS.player.infamy = maxi(0, infamy() + n)
	if n > 0:
		if not GS.flags.has("infamy_log"):
			GS.flags.infamy_log = []
		GS.flags.infamy_log.append({"x": pos.x, "y": pos.y, "n": n, "day": GS.day(), "why": why})
		if GS.flags.infamy_log.size() > 120:
			GS.flags.infamy_log.pop_front()

static func regional_infamy(pos: Vector2, days: int = 45) -> int:
	var n := 0
	for e in GS.flags.get("infamy_log", []):
		if GS.day() - int(e.day) <= days and Vector2(e.x, e.y).distance_to(pos) <= LOCAL_RADIUS:
			n += int(e.n)
	return n

## Where the player's recent cruelty is concentrated, or Vector2.INF.
static func cruelty_center() -> Vector2:
	var best := Vector2.INF
	var best_n := 0
	for e in GS.flags.get("infamy_log", []):
		if GS.day() - int(e.day) > 45:
			continue
		var p := Vector2(e.x, e.y)
		var n := regional_infamy(p)
		if n > best_n:
			best_n = n
			best = p
	return best

## How a bender ranks among all benders of their element.
static func mastery_score() -> float:
	var pl: Dictionary = GS.player
	if pl.get("bend", "") == "":
		return 0.0
	var s := float(pl.skills.get("bending", 0)) * 6.0 + minf(float(pl.level), 40.0)
	var uses := 0
	for f in pl.get("forms", []):
		uses += int(f.get("uses", 0))
	s += minf(15.0, uses / 20.0)
	s += minf(15.0, float(GS.flags.get("duel_wins", 0)) * 3.0)
	s += float(pl.get("techniques", []).size()) * 4.0
	if pl.get("master_title", "") != "":
		s += 20.0
	return s

static func mastery_percentile() -> float:
	return 100.0 * (1.0 - exp(-mastery_score() / 34.0))

## "Among the top 3% of firebenders" and similar.
static func mastery_text() -> String:
	var pl: Dictionary = GS.player
	if pl.get("bend", "") == "":
		return "You are not a bender."
	var top := maxf(0.1, 100.0 - mastery_percentile())
	var who: String = {"fire": "firebenders", "water": "waterbenders", "earth": "earthbenders", "air": "airbenders"}.get(pl.bend, "benders")
	if top >= 50.0:
		return "An ordinary %s, still learning." % who.trim_suffix("s")
	return "Among the top %s%% of %s." % [("%.1f" % top) if top < 10.0 else str(int(top)), who]

## The four motives, with whether each is active and why, for the UI and the
## daily simulation.
static func motives() -> Dictionary:
	var A := state()
	var st := stage()
	var out := {}
	var title := ruler_title()
	var inf := influence()
	var cruel := infamy()
	out.ruler = {"active": great_power() and cruel < TYRANT_INFAMY and st != "child",
		"why": ("You hold the title %s." % title) if title != "" else "Influence %.0f of %.0f (fiefs, renown, army)." % [inf, GREAT_POWER],
		"progress": 1.0 if title != "" else clampf(inf / GREAT_POWER, 0.0, 1.0), "done": A.get("court_done", false)}
	out.tyrant = {"active": great_power() and cruel >= TYRANT_INFAMY and st != "child",
		"why": "Infamy %d of %d, while holding great power." % [cruel, TYRANT_INFAMY],
		"progress": clampf(float(cruel) / TYRANT_INFAMY, 0.0, 1.0) * (1.0 if great_power() else 0.5), "done": false}
	var need: String = A.get("order", [""])[0] if not A.get("order", []).is_empty() else ""
	var pct := mastery_percentile()
	out.teacher = {"active": st == "young" and need != "" and need == GS.player.get("bend", "") and pct >= TEACHER_PCT and not A.get("teach_offered", []).has(need),
		"why": ("%s needs to learn %s next. You: %s" % [display_name(), Data.element_name(need), mastery_text()]) if need != "" and st == "young" else "Only a young Avatar seeks teachers, and only the very best (top 1%).",
		"progress": clampf(pct / TEACHER_PCT, 0.0, 1.0) if need == GS.player.get("bend", "") else 0.0, "done": A.get("taught", []).has(GS.player.get("bend", ""))}
	var center := cruelty_center()
	var reg := 0 if center == Vector2.INF else regional_infamy(center)
	var near: bool = center != Vector2.INF and Vector2(A.get("pos", Vector2.ZERO)).distance_to(center) <= AVATAR_NEAR and A.get("loc", "spirit") != "spirit"
	out.local = {"active": reg >= LOCAL_INFAMY and near and st != "child",
		"why": "Cruelty in one region: %d of %d in 45 days%s." % [reg, LOCAL_INFAMY, ", and the Avatar is near" if near else ""],
		"progress": clampf(float(reg) / LOCAL_INFAMY, 0.0, 1.0), "done": false}
	return out

# ---------------------------------------------------------------------------
# Daily simulation
# ---------------------------------------------------------------------------
static func daily() -> void:
	ensure()
	var A := state()
	var S = _story()
	# The Quiet Years end on the child's sixteenth birthday
	if not A.revealed and age() >= 16.0:
		A.revealed = true
		GS.log_msg("The sages have told a sixteen-year-old named %s what they are. The Quiet Years are over." % A.name, Color(1, 0.9, 0.55))
		S.queue("av_revealed")
	var st := stage()
	if st == "child":
		return
	_learn(A, st)
	_move(A, st)
	_rumours(A)
	if A.hostage and randf() < 0.03:
		A.hostage = false
		A.attitude = mini(int(A.attitude), -60)
		S.queue("av_hostage_rescued")
	if A.get("due", {}).is_empty():
		_consider(A, st)
	elif GS.day() >= int(A.due.day):
		_execute_due(A)
	# Infamy fades, faster for someone keeping a pledge to the Avatar
	if infamy() > 0 and GS.day() % 2 == 0:
		GS.player.infamy = maxi(0, infamy() - (2 if A.pledge else 1))

## A young Avatar learns the elements in order, from someone, eventually.
static func _learn(A: Dictionary, st: String) -> void:
	if st != "young" or A.order.is_empty():
		return
	if A.get("teach_until", -1) > 0:
		if GS.day() >= int(A.teach_until):
			A.teach_until = -1
			_story().queue("av_taught")
		return
	if GS.day() >= int(A.get("learn_until", 999999)):
		var el: String = A.order.pop_front()
		A.mastered.append(el)
		A.learn_until = GS.day() + randi_range(200, 260)
		GS.log_msg("Word travels: %s has mastered %s under another teacher." % [display_name(), Data.element_name(el)], Color(0.85, 0.85, 1))

static func _move(A: Dictionary, st: String) -> void:
	if GS.day() < int(A.get("wounded_until", -1)):
		A.loc = "spirit"
		return
	if A.get("state", "free") == "teaching":
		A.loc = "party"
		A.pos = GS.player_party().pos
		return
	if GS.day() < int(A.get("loc_until", 0)):
		return
	if randf() < involvement("spirit"):
		A.loc = "spirit"
		var span := Vector2i(6, 20) if st == "elder" else Vector2i(3, 10)
		A.loc_until = GS.day() + randi_range(span.x, span.y)
		return
	var sid := _pick_visit(A, st)
	A.loc = sid
	A.pos = Data.settlements[sid].pos
	A.loc_until = GS.day() + randi_range(2, 5)
	A.rumour = {"sid": sid, "day": GS.day() + randi_range(1, 2)}
	_world_acts(A, st, sid)

## Where the Avatar goes: sieges and wars draw them; temples and home rest them.
static func _pick_visit(A: Dictionary, st: String) -> String:
	var pool := []
	var weights := []
	for sid in Data.settlements:
		var d: Dictionary = Data.settlements[sid]
		if d.type == "ruin":
			continue
		var s: Dictionary = GS.settlements[sid]
		var w := 1.0
		if not s.siege.is_empty():
			w += 5.0
		for k in Data.KINGDOMS:
			if GS.at_war(s.faction, k):
				w += 1.0
				break
		if d.type == "temple":
			w += 5.0 if st == "elder" else 2.0
		if sid == A.home:
			w += 6.0 if st == "elder" else 2.0
		pool.append(sid)
		weights.append(w)
	var total := 0.0
	for w in weights:
		total += w
	var r := randf() * total
	for i in pool.size():
		r -= weights[i]
		if r <= 0.0:
			return pool[i]
	return A.home

## While visiting, the Avatar is part of the world: sieges lift, truces happen.
static func _world_acts(A: Dictionary, st: String, sid: String) -> void:
	var s: Dictionary = GS.settlements[sid]
	var name: String = Data.settlements[sid].name
	var lift: float = {"young": 0.35, "prime": 0.6, "elder": 0.25}.get(st, 0.0)
	if not s.siege.is_empty() and randf() < lift:
		var leader: Dictionary = GS.parties.get(s.siege.get("leader", ""), {})
		if not leader.is_empty() and leader.id != "player" and leader.get("faction", "") != GS.player_faction():
			GS.sim._end_siege(sid, false)
			GS.log_msg("%s walks into the siege camp at %s and sits down between the lines. By evening the besiegers have gone home." % [display_name().capitalize(), name], Color(0.85, 0.9, 1))
			return
	var broker: float = {"young": 0.06, "prime": 0.15, "elder": 0.08}.get(st, 0.0)
	if randf() < broker:
		for k in Data.KINGDOMS:
			if k != s.faction and GS.at_war(s.faction, k) and s.faction in Data.KINGDOMS:
				GS.make_peace(s.faction, k)
				GS.log_msg("At %s, %s brings envoys of the %s and the %s to the same table. They sign a truce before anyone can think better of it." % [name, display_name(), Data.factions[s.faction].name, Data.factions[k].name], Color(0.85, 0.9, 1))
				break

## Sightings reach the player a day or two late, so the Avatar is usually gone.
static func _rumours(A: Dictionary) -> void:
	var r: Dictionary = A.get("rumour", {})
	if r.is_empty() or GS.day() < int(r.day):
		return
	A.rumour = {}
	A.seen.push_front({"sid": r.sid, "day": GS.day() - 1})
	if A.seen.size() > 4:
		A.seen.pop_back()
	if randf() < 0.7:
		GS.log_msg("Travellers say %s was seen at %s." % [display_name(), Data.settlements[r.sid].name], Color(0.82, 0.86, 1))

## Decide whether anything about the player calls for the Avatar.
static func _consider(A: Dictionary, st: String) -> void:
	if GS.day() < int(A.get("wounded_until", -1)) or A.get("state", "free") == "teaching":
		return
	var m := motives()
	var d := GS.day()
	if m.tyrant.active and randf() < 0.3 * involvement("tyrant"):
		if not A.warned:
			_schedule(A, "warning", {"young": 6, "prime": 3, "elder": 10}.get(st, 5))
			GS.log_msg("A traveller on the road asks a great many questions about you, and leaves without buying anything.", Color(0.85, 0.75, 1))
		elif A.pledge and infamy() <= int(A.pledge_infamy) + 40:
			return
		else:
			var gather: int = {"young": 18, "prime": 12, "elder": 24}.get(st, 15)
			_schedule(A, "confront", gather)
			A.state = "gathering"
			GS.log_msg("Word spreads from temple to temple: %s is gathering allies, and they are coming for you. You have perhaps %d days." % [display_name(), gather], Color(1, 0.6, 0.5))
			_story().queue("av_gathering")
		return
	if m.local.active and d >= int(A.get("local_cd", -1)) and randf() < 0.5 * involvement("local"):
		_schedule(A, "local", randi_range(1, 3))
		return
	if m.teacher.active and randf() < 0.25 * involvement("teacher"):
		A.teach_offered.append(GS.player.bend)
		_schedule(A, "teach", randi_range(3, 8))
		return
	if m.ruler.active and not A.court_done and randf() < 0.2 * involvement("ruler"):
		_schedule(A, "court", {"young": 10, "prime": 5, "elder": 18}.get(st, 8))

static func _schedule(A: Dictionary, kind: String, days: int) -> void:
	A.due = {"kind": kind, "day": GS.day() + days}

static func _execute_due(A: Dictionary) -> void:
	var kind: String = A.due.kind
	var S = _story()
	A.due = {}
	A.pos = GS.player_party().pos
	match kind:
		"court":
			A.court_done = true
			S.queue("av_court")
		"warning":
			A.warned = true
			S.queue("av_warning")
		"local":
			A.local_cd = GS.day() + 30
			S.queue("av_local")
		"teach":
			S.queue("av_teacher")
		"confront":
			if A.diversion:
				A.diversion = false
				A.demoralized = true
				_schedule(A, "confront", randi_range(16, 24))
				var home: Dictionary = GS.settlements[A.home]
				home.prosperity = maxf(5.0, home.prosperity - 25.0)
				home.looted_until = GS.hours + 24.0 * 10.0
				add_infamy(60, Data.settlements[A.home].pos, "the raid on the Avatar's home")
				S.queue("av_diverted")
			else:
				spawn_company()
				S.queue("av_confront")

# ---------------------------------------------------------------------------
# The Avatar's company, and confrontation
# ---------------------------------------------------------------------------
static func company_id() -> String:
	return String(state().get("company", ""))

static func spawn_company() -> String:
	var A := state()
	var S = _story()
	var pid: String = S.spawn("avatar_company")
	if pid == "" or not GS.parties.has(pid):
		return ""
	var p: Dictionary = GS.parties[pid]
	p.name = "%s's Company" % display_name()
	p.faction = "avatar"
	p.roster = []
	var st := stage()
	Roster.add(p.roster, "avatar", 1)
	var allies: Array = {"young": [["an_monk", 4], ["swt_waterbender", 4], ["swt_warrior", 6]],
		"prime": [["an_master", 4], ["ek_earthbender", 8], ["swt_waterbender", 6], ["ky_warrior", 6]],
		"elder": [["an_master", 3], ["ky_warrior", 8], ["fn_firebender", 4]]}.get(st, [])
	# A tyrant with a great army (and garrison) brings the nations down on them too
	var defenders := float(GS.party_size())
	var seat := seat_near()
	if seat != "":
		defenders += float(Roster.total(GS.settlements[seat].garrison))
	var scale := clampf(defenders / 35.0, 0.6, 5.0) * (1.0 + 0.3 * int(A.get("defeats", 0)))
	for a in allies:
		Roster.add(p.roster, a[0], maxi(1, int(round(float(a[1]) * scale))))
	p.pos = GS.player_party().pos + Vector2(2.5, 2.5)
	p.anchor = p.pos
	p.target_party = ""
	p.moving = false
	p.state = "idle"
	p.ignore_player_until = INF
	A.company = pid
	A.state = "confronting"
	return pid

## The player's seat: an owned town or castle the player is at or near.
static func seat_near() -> String:
	var pp: Dictionary = GS.player_party()
	for sid in GS.settlements:
		if GS.settlements[sid].owner == "player" and Data.settlements[sid].type in ["town", "castle"]:
			if Data.settlements[sid].pos.distance_to(pp.pos) <= 20.0:
				return sid
	return ""

## Defences prepared at a seat against the Avatar: fortification and traps.
static func defences(sid: String) -> Dictionary:
	if sid == "" or not GS.settlements.has(sid):
		return {"fort": 0, "traps": 0}
	return {"fort": int(GS.settlements[sid].get("avatar_fort", 0)), "traps": int(GS.settlements[sid].get("avatar_traps", 0))}

static func start_battle() -> void:
	var pid := company_id()
	if not GS.parties.has(pid):
		return
	var seat := seat_near()
	var def := defences(seat)
	if seat != "":
		GS.start_battle([pid], [], seat, false)
	else:
		GS.start_battle([pid])
	GS.pending_battle.avatar = {"fort": def.fort, "traps": def.traps, "demoralized": state().get("demoralized", false), "stage": stage()}

static func dismiss_company() -> void:
	var pid := company_id()
	if GS.parties.has(pid):
		GS.sim.remove_party(pid)
	state().company = ""

## The player beat the Avatar in battle. The Avatar is never killed: they
## withdraw to heal, and they will return.
static func on_defeated() -> void:
	var A := state()
	A.defeats = int(A.get("defeats", 0)) + 1
	A.state = "free"
	A.company = ""
	A.demoralized = false
	A.wounded_until = GS.day() + {"young": 70, "prime": 90, "elder": 140}.get(stage(), 90)
	A.attitude = mini(int(A.attitude), -40)
	A.warned = true
	A.pledge = false
	GS.add_renown(60)
	add_infamy(40, GS.player_party().pos, "defeating the Avatar")
	for k in Data.KINGDOMS:
		GS.change_faction_rel(k, -15)
	_story().queue("av_withdraws")

## The Avatar beat the player. Balance is restored: the realm built on
## cruelty is taken apart and returned.
static func judgement(yielded: bool = false) -> void:
	var A := state()
	dismiss_company()
	A.state = "free"
	A.demoralized = false
	A.warned = true
	A.pledge = true
	A.pledge_infamy = 0
	A.attitude = clampi(int(A.attitude) + 10, -100, 100)
	var freed := []
	for sid in GS.settlements:
		var s: Dictionary = GS.settlements[sid]
		if s.owner == "player":
			var f: String = Data.settlements[sid].faction
			if not f in Data.KINGDOMS:
				f = "earth_kingdom"
			s.owner = ""
			s.faction = f
			s.garrison = GS._make_garrison(Data.settlements[sid].culture, 60)
			freed.append(Data.settlements[sid].name)
	for lid in GS.player.get("captive_lords", []).duplicate():
		GS.release_lord(lid, false)
	GS.add_gold(-int(GS.player.gold * (0.25 if yielded else 0.5)))
	GS.player.infamy = 0
	GS.flags.infamy_log = []
	GS.flags.av_freed = freed
	GS.log_msg("%s has taken apart what you built. %s" % [display_name().capitalize(), ("Freed: " + ", ".join(freed) + ".") if not freed.is_empty() else ""], Color(1, 0.7, 0.5))

## Player defeated in a battle that included the Avatar's company.
static func on_player_defeated(enemy_ids: Array) -> bool:
	if not enemy_ids.has(company_id()) or company_id() == "":
		return false
	judgement(false)
	_story().queue("av_judgement")
	return true

# ---------------------------------------------------------------------------
# Meeting the Avatar
# ---------------------------------------------------------------------------
static func present_at(sid: String) -> bool:
	var A := state()
	return stage() != "child" and A.get("loc", "spirit") == sid and GS.day() >= int(A.get("wounded_until", -1))

## Chance that the Avatar's companions let you through today.
static func audience_chance() -> float:
	var A := state()
	var c := 0.25 + float(GS.player.renown) / 1000.0 + GS.standing_rank() * 0.08 + float(A.get("attitude", 0)) / 200.0
	if ruler_title() != "":
		c += 0.3
	return clampf(c, 0.05, 0.95)

# ---------------------------------------------------------------------------
# Teaching: the young Avatar travels with the player for a season
# ---------------------------------------------------------------------------
static func register_companion() -> void:
	var A := state()
	if A.is_empty():
		return
	var g := String(A.get("pronouns", "they"))
	Data.companions["avatar"] = {"name": display_name(), "short": String(A.get("name", "Avatar")), "pronouns": g,
		"culture": A.get("culture", "air"), "bend": "avatar", "power": 2.2, "weapon": "staff", "hp": 220, "armor": 12, "skill": 80,
		"cost": 0, "vlook": A.get("vlook", {}), "kit": A.get("kit", "sash"), "bio": A.get("bio", ""), "pitch": "", "story_only": true}

static func begin_teaching() -> void:
	var A := state()
	register_companion()
	A.state = "teaching"
	A.teach_until = GS.day() + 40
	A.attitude = clampi(int(A.attitude) + 15, -100, 100)
	if not GS.player.companions.has("avatar"):
		GS.player.companions.append("avatar")

static func finish_teaching() -> void:
	var A := state()
	var el: String = GS.player.get("bend", "")
	A.state = "free"
	A.teach_until = -1
	if A.order.has(el):
		A.order.erase(el)
		A.mastered.append(el)
	A.taught.append(el)
	A.learn_until = GS.day() + randi_range(200, 260)
	A.attitude = clampi(int(A.attitude) + 40, -100, 100)
	A.loc = "spirit"
	A.loc_until = GS.day() + 5
	GS.player.companions.erase("avatar")
	GS.add_renown(80)
	for k in Data.KINGDOMS:
		GS.change_faction_rel(k, 8)
	GS.change_faction_rel("air_nomads", 15)
	_story().set_flag("taught_avatar_" + el, true)

# ---------------------------------------------------------------------------
# Preparations against the Avatar
# ---------------------------------------------------------------------------
static func hostile() -> bool:
	var A := state()
	return A.get("state", "") in ["gathering", "confronting"] or (A.get("warned", false) and not A.get("pledge", false) and infamy() >= TYRANT_INFAMY / 2)

static func fortify(sid: String) -> void:
	var s: Dictionary = GS.settlements[sid]
	s.avatar_fort = mini(3, int(s.get("avatar_fort", 0)) + 1)
	GS.add_gold(-fort_cost(sid))

static func fort_cost(sid: String) -> int:
	return 1200 + 600 * int(GS.settlements[sid].get("avatar_fort", 0))

static func lay_traps(sid: String) -> void:
	var s: Dictionary = GS.settlements[sid]
	s.avatar_traps = mini(3, int(s.get("avatar_traps", 0)) + 1)
	GS.add_gold(-trap_cost(sid))

static func trap_cost(sid: String) -> int:
	return 900 + 450 * int(GS.settlements[sid].get("avatar_traps", 0))

static func buy_intel() -> void:
	state().intel = true
	GS.add_gold(-800)

static func stage_diversion() -> void:
	var A := state()
	var pp: Dictionary = GS.player_party()
	var need := 20
	var taken := 0
	for st in pp.roster.duplicate():
		if taken >= need:
			break
		taken += Roster.remove(pp.roster, st.id, mini(need - taken, st.n - st.w))
	GS.add_gold(-600)
	A.diversion = true

static func can_stage_diversion() -> bool:
	var pp: Dictionary = GS.player_party()
	return Roster.total(pp.roster) - Roster.wounded(pp.roster) >= 30 and GS.player.gold >= 600 and not state().get("diversion", false)

static func take_hostage() -> void:
	var A := state()
	A.hostage = true
	A.attitude = mini(int(A.attitude), -50)
	add_infamy(80, Data.settlements[A.home].pos, "taking a hostage")

static func use_hostage() -> void:
	var A := state()
	dismiss_company()
	A.state = "free"
	A.wounded_until = GS.day() + 45
	add_infamy(40, GS.player_party().pos, "holding a hostage against the Avatar")

## The attitude the Avatar holds toward the player, in words.
static func attitude_text() -> String:
	var a := int(state().get("attitude", 0))
	if state().get("state", "") in ["gathering", "confronting"]:
		return "Coming to stop you"
	if a >= 50:
		return "A friend"
	if a >= 15:
		return "Well disposed"
	if a <= -50:
		return "Your enemy"
	if a <= -15:
		return "Wary of you"
	return "Unaware of you" if not state().get("court_done", false) and not state().get("warned", false) else "Watching"
