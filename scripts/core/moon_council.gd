extends RefCounted
## The Moon Council: the Water Tribes as a loose confederation of many small
## tribes, after the Holy Roman Empire. Seven electors choose a High Chief of
## the Water Tribes from among the great tribes' chiefs. The High Chief rules
## nothing directly: every tribe governs itself. The office brings a tithe
## from the free tribes, the duty to protect them, and the right to call the
## tribes to war, which they may or may not answer.
##
## The council sits at the first full moon after its appointed day, every
## year, and at once if the High Chief's tribe loses its seat. Electors vote
## by self-interest: their own chief first, then the strong, the near, the
## friendly and the generous. The player can lobby electors with gifts, and
## can stand themselves once they rule a Water Tribes hall of their own.
##
## State lives in GS.flags.moon_council.

const Fealty = preload("res://scripts/core/fealty.gd")

const ELECTORS := ["northern_water", "southern_water", "aqsarniit", "whalebone", "kanguq", "pearl_isles", "foggy_swamp"]
const TERM_DAYS := 365
const TITLE := "High Chief of the Water Tribes"

static func state() -> Dictionary:
	if not GS.flags.has("moon_council"):
		GS.flags.moon_council = {"chief": "northern_water", "since": -12 * 365, "next": 90, "lobby": {}, "backing": "", "last_votes": {}}
	return GS.flags.moon_council

static func chief() -> String:
	return state().get("chief", "")

## The name of the person who holds the office.
static func chief_name() -> String:
	var c := chief()
	if c == "player":
		return GS.player.name
	var king: String = Data.factions.get(c, {}).get("king", "")
	return Data.lords[king].name if Data.lords.has(king) else Data.factions.get(c, {}).get("name", "nobody")

## Water-region factions that can be chosen: great tribes with a chief, still
## holding land, and the player if they hold a hall in the Water region.
static func candidates() -> Array:
	var out := []
	for f in ELECTORS:
		if f in Data.KINGDOMS and not GS.faction_settlements(f).is_empty():
			out.append(f)
	if player_eligible():
		out.append("player")
	return out

## The player may stand once they rule, in their own name, a Water Tribes
## town or castle, and are known (renown 250).
static func player_eligible() -> bool:
	if GS.player_faction() != "player" or int(GS.player.get("renown", 0)) < 250:
		return false
	for sid in GS.faction_settlements("player"):
		var d: Dictionary = Data.settlements[sid]
		if d.type in ["town", "castle"] and d.culture in ["north", "south", "swamp"]:
			return true
	return false

static func electors() -> Array:
	return ELECTORS.filter(func(e): return Data.factions.has(e) and not GS.faction_settlements(e).is_empty())

## How much elector e favours candidate c.
static func score(e: String, c: String) -> float:
	var s := 0.0
	# a chief favours themselves, but not above everything: the great tribes
	# usually rally behind whoever can actually protect them
	if e == c:
		s += 1.2
	if c == "player":
		s += GS.faction_rel(e) / 30.0 + float(GS.player.get("renown", 0)) / 600.0
	else:
		s += Fealty.strength(c) / 250.0
		if GS.at_war(e, c):
			s -= 10.0
		if Fealty.overlord(e) == c:
			s += 2.0
		# north votes north, south votes south
		var se := _seat_y(e)
		var sc := _seat_y(c)
		if (se < 600.0) == (sc < 600.0):
			s += 1.0
	if c == chief():
		s += 0.5
	s += float(state().lobby.get(e + "|" + c, 0.0))
	return s

static func _seat_y(f: String) -> float:
	var seat: String = Data.factions.get(f, {}).get("capital", "")
	if seat == "" and f == "player":
		var own := GS.faction_settlements("player")
		seat = own[0] if not own.is_empty() else ""
	return Data.settlements[seat].pos.y if Data.settlements.has(seat) else 600.0

## Whom each elector would vote for today.
static func leanings() -> Dictionary:
	var out := {}
	var cands := candidates()
	if cands.is_empty():
		return out
	for e in electors():
		var best: String = cands[0]
		for c in cands:
			if score(e, c) > score(e, best):
				best = c
		out[e] = best
	return out

static func tally() -> Dictionary:
	var t := {}
	var l := leanings()
	for e in l:
		t[l[e]] = int(t.get(l[e], 0)) + 1
	return t

static func daily() -> void:
	var st := state()
	var c := chief()
	var vacant: bool = c != "player" and (c == "" or GS.faction_settlements(c).is_empty())
	if c == "player" and GS.faction_settlements("player").is_empty():
		vacant = true
	if vacant or (GS.day() >= int(st.next) and GS.is_full_moon()):
		elect()

static func elect() -> void:
	var st := state()
	var t := tally()
	if t.is_empty():
		st.next = GS.day() + 30
		return
	var best := ""
	for c in t:
		if best == "" or int(t[c]) > int(t[best]) or (int(t[c]) == int(t[best]) and (c == chief() or (best != chief() and _weight(c) > _weight(best)))):
			best = c
	var old := chief()
	st.last_votes = leanings()
	st.chief = best
	st.since = GS.day()
	st.next = GS.day() + TERM_DAYS
	st.lobby = {}
	var who: String = "you" if best == "player" else "%s of the %s" % [chief_name(), Data.factions[best].name]
	if best == old:
		GS.log_msg("The Moon Council sits under the full moon and confirms %s as %s, %d votes of %d." % [who, TITLE, int(t[best]), st.last_votes.size()], Color(0.65, 0.8, 1))
	else:
		GS.log_msg("The Moon Council sits under the full moon and elects %s %s, %d votes of %d." % [who, TITLE, int(t[best]), st.last_votes.size()], Color(0.65, 0.8, 1))
		if best == "player":
			GS.add_renown(80)
	if old == "player" and best != "player":
		GS.log_msg("You are no longer %s." % TITLE, Color(1, 0.7, 0.4))

static func _weight(c: String) -> float:
	return float(GS.player.get("renown", 0)) if c == "player" else float(Fealty.strength(c))

## Free water tribes (paying no one) pay the High Chief a small tithe; the
## player receives theirs as gold.
static func tithe() -> int:
	var g := 0
	for f in Data.factions:
		if Data.factions[f].get("community", false) and Data.region_of(f) == "water" and Fealty.overlord(f) == "":
			g += int(Fealty.tribute_of(f) * 0.4)
	return g

## Weekly: the tithe, and the call to arms. When the High Chief's tribe is at
## war with anyone outside the Water Tribes, electors who voted for it may
## join that war.
static func weekly() -> void:
	var c := chief()
	if c == "player":
		var g := tithe()
		if g > 0:
			GS.add_gold(g)
			GS.log_msg("The free tribes send their High Chief a tithe of %d gold." % g, Color(0.65, 0.8, 1))
		return
	if c == "" or not c in Data.KINGDOMS:
		return
	var votes: Dictionary = state().get("last_votes", {})
	for enemy in Data.KINGDOMS:
		if Data.region_of(enemy) == "water" or not GS.at_war(c, enemy):
			continue
		for e in electors():
			if e == c or not e in Data.KINGDOMS or GS.at_war(e, enemy) or votes.get(e, "") != c:
				continue
			if randf() < 0.12:
				GS.declare_war(e, enemy)
				GS.log_msg("The %s answers the High Chief's call to arms against the %s." % [Data.factions[e].name, Data.factions[enemy].name], Color(0.65, 0.8, 1))

## The High Chief protects free water tribes as an overlord protects its
## tributaries.
static func protector_of(f: String) -> String:
	if Data.region_of(f) == "water" and Data.factions.get(f, {}).get("community", false) and Fealty.overlord(f) == "":
		return chief()
	return ""

## Gifts to an elector for the candidate the player backs.
static func lobby_cost(e: String) -> int:
	return 200 + int(Fealty.strength(e) * 1.5) + int(float(state().lobby.get(e + "|" + backing(), 0.0)) * 300)

static func backing() -> String:
	return state().get("backing", "")

static func set_backing(c: String) -> void:
	state().backing = c

static func lobby(e: String) -> String:
	var c := backing()
	if c == "":
		return "Choose a candidate to back first."
	var cost := lobby_cost(e)
	if GS.player.gold < cost:
		return "You cannot afford the gifts."
	GS.add_gold(-cost)
	var key := e + "|" + c
	state().lobby[key] = minf(4.0, float(state().lobby.get(key, 0.0)) + 1.5)
	GS.change_faction_rel(e, 3)
	var who: String = "you" if c == "player" else Data.factions[c].short
	return "Your gifts reach the %s with a letter about %s. The elders are polite about both." % [Data.factions[e].name, who]
