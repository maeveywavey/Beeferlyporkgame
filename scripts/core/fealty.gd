extends RefCounted
## Fealty: tribute paid for connection and protection.
##
## A faction that pays fealty (GS.fealty[f] = overlord) sends its overlord
## tribute every week. In return the overlord treats an attack on it as an
## attack on itself and declares war on the attacker. Fealty is not
## ownership: the tributary keeps its own lands, elders and lords, and stops
## paying when the overlord looks weak.
##
## Each week the powers also reach for the independent communities near their
## lands. A community asked for tribute may agree; one that refuses may be
## taken by force by a power whose ruler is aggressive enough. Communities that
## were taken rise again when their new masters are busy elsewhere.

const Roster = preload("res://scripts/core/roster.gd")

static func overlord(f: String) -> String:
	return GS.fealty.get(f, "")

static func tributaries(f: String) -> Array:
	var out := []
	for t in GS.fealty:
		if GS.fealty[t] == f:
			out.append(t)
	return out

## Gold a tributary sends its overlord each week.
static func tribute_of(f: String) -> int:
	var g := 0.0
	for sid in GS.faction_settlements(f):
		var p: float = GS.settlements[sid].prosperity
		match Data.settlements[sid].type:
			"town": g += 50.0 + p * 0.6
			"castle": g += 20.0
			"village": g += 10.0 + p * 0.15
	return int(g)

## Tribute the player receives each week from communities that pay them.
static func player_income() -> int:
	var g := 0
	for t in tributaries("player"):
		g += tribute_of(t)
	return g

## Rough military weight of a faction: its lords' armies and half its garrisons.
static func strength(f: String) -> int:
	var n := 0
	for lid in GS.faction_lords(f):
		var lr: Dictionary = GS.lords[lid]
		if lr.party != "" and GS.parties.has(lr.party):
			n += Roster.total(GS.parties[lr.party].roster)
	for sid in GS.faction_settlements(f):
		n += int(Roster.total(GS.settlements[sid].garrison) * 0.5)
	return n

static func is_community(f: String) -> bool:
	return Data.factions.get(f, {}).get("community", false)

## The aggression of a power's ruler (0..1), which decides how hard it reaches.
static func ruler_aggression(f: String) -> float:
	var king: String = Data.factions.get(f, {}).get("king", "")
	if Data.lords.has(king) and not GS.lords.get(king, {}).get("retired", false):
		return float(Data.lords[king].get("aggression", 0.4))
	return 0.4

## victim was attacked by attacker: the victim's overlord answers for it.
static func protect(victim: String, attacker: String) -> void:
	var ov := overlord(victim)
	if ov == "":
		# free water tribes are protected by the High Chief of the Water Tribes
		ov = load("res://scripts/core/moon_council.gd").protector_of(victim)
	if ov == "" or ov == attacker or attacker == "":
		return
	var vname: String = Data.factions[victim].name
	if ov == "player":
		if attacker in Data.KINGDOMS:
			GS.log_msg("The %s has attacked %s, which pays you tribute. Its elders are waiting to see what you will do." % [Data.factions[attacker].name, vname], Color(1, 0.6, 0.35))
			if GS.player_faction() == "player":
				GS.declare_war("player", attacker)
		return
	if attacker == "player" or attacker == GS.player_faction():
		if GS.player_faction() == "player":
			if not GS.at_war("player", ov):
				GS.declare_war("player", ov)
				GS.log_msg("The %s takes up arms for %s, which pays it tribute. It is now at war with you." % [Data.factions[ov].name, vname], Color(1, 0.45, 0.3))
		else:
			GS.change_faction_rel(ov, -20)
		return
	if ov in Data.KINGDOMS and attacker in Data.KINGDOMS and not GS.at_war(ov, attacker):
		GS.declare_war(ov, attacker)
		GS.world_msg("The %s takes up arms for %s, which pays it tribute." % [Data.factions[ov].name, vname], Color(1, 0.6, 0.35), [ov, attacker, victim])

## The player asks a community for tribute. Returns a line for the window.
static func player_demand(f: String) -> String:
	var ov := overlord(f)
	var sids := GS.faction_settlements(f)
	if sids.is_empty():
		return ""
	var s: Dictionary = GS.settlements[sids[0]]
	var my := float(GS.sim.party_power(GS.player_party()))
	var chance: float = 0.15 + GS.player.renown / 1500.0 + float(s.relation) / 150.0 + minf(0.3, my / 4000.0)
	if ov != "":
		chance -= 0.25
	chance = clampf(chance, 0.02, 0.9)
	GS.flags["demand_day_" + f] = GS.day()
	if randf() >= chance:
		s.relation = maxi(-100, int(s.relation) - 5)
		return "The elders hear you out and decline. \"We have managed without your protection so far.\""
	if ov != "":
		GS.fealty.erase(f)
		protect(f, GS.player_faction())
		GS.log_msg("%s stops paying tribute to the %s and pays it to you instead." % [Data.factions[f].name, Data.factions[ov].name], Color(1, 0.85, 0.4))
	else:
		GS.log_msg("%s agrees to pay you tribute." % Data.factions[f].name, Color(1, 0.85, 0.4))
	GS.fealty[f] = "player"
	GS.change_faction_rel(f, 5)
	return "The elders agree. A clerk writes your name in the village ledger, under a line of older names that have been crossed out."

## The player releases a tributary from its tribute.
static func release(f: String) -> void:
	if overlord(f) == "player":
		GS.fealty.erase(f)
		GS.change_faction_rel(f, 10)
		GS.log_msg("You release %s from its tribute." % Data.factions[f].name, Color(0.8, 0.9, 1))

static func weekly() -> void:
	_breakaways()
	_uprisings()
	_expansion()

## Tributaries stop paying an overlord that is gone or looks weak.
static func _breakaways() -> void:
	for f in GS.fealty.keys():
		var ov: String = GS.fealty[f]
		if GS.faction_settlements(f).is_empty():
			GS.fealty.erase(f)
			continue
		var gone: bool = ov != "player" and GS.faction_settlements(ov).is_empty()
		var p := 0.0
		if ov == "player":
			p = 0.006 + (0.03 if GS.player.renown < 100 else 0.0) + (0.04 if GS.faction_rel(f) < -10 else 0.0)
		else:
			p = 0.003 + 0.012 * GS.sim._wars_of(ov) + 0.1 * GS.sim._land_loss(ov)
		if gone or randf() < p:
			GS.fealty.erase(f)
			if ov == "player":
				GS.log_msg("%s has stopped paying you tribute." % Data.factions[f].name, Color(1, 0.6, 0.35))
			else:
				GS.world_msg("%s stops paying tribute to the %s." % [Data.factions[f].name, Data.factions[ov].name], Color(0.85, 0.85, 0.7), [f, ov])
				if not gone and ov in Data.KINGDOMS and randf() < ruler_aggression(ov) * 0.5:
					GS.declare_war(ov, f)

## Communities a power took by force rise when its armies are elsewhere.
static func _uprisings() -> void:
	for sid in Data.settlements:
		var d: Dictionary = Data.settlements[sid]
		if not d.has("community"):
			continue
		var s: Dictionary = GS.settlements[sid]
		if s.faction == sid or s.owner == "player" or s.faction == "player":
			continue
		var holder: String = s.faction
		var p: float = 0.006 + 0.01 * GS.sim._wars_of(holder) + (0.02 if s.looted_until > GS.hours else 0.0)
		if randf() < p:
			s.faction = sid
			s.owner = ""
			GS.world_msg("%s has driven out the %s and governs itself again." % [d.name, Data.factions.get(holder, Data.factions.neutral).name], Color(0.85, 0.9, 0.7), [sid, holder], d.pos)
			if holder in Data.KINGDOMS:
				GS.declare_war(holder, sid)

## Powers reach for independent communities near their lands.
static func _expansion() -> void:
	for f in Data.KINGDOMS:
		if Data.factions[f].get("protected", false) or GS.faction_settlements(f).is_empty():
			continue
		var a := ruler_aggression(f)
		if randf() >= 0.008 + a * 0.03:
			continue
		var target := _nearest_community(f, 260.0)
		if target == "":
			continue
		var tname: String = Data.factions[target].name
		var ov := overlord(target)
		if ov == "" and randf() < 0.35 + minf(0.35, strength(f) / 800.0):
			GS.fealty[target] = f
			GS.world_msg("%s agrees to pay tribute to the %s." % [tname, Data.factions[f].name], Color(0.85, 0.85, 0.7), [target, f])
		elif a >= 0.5 or ov != "":
			_seize(f, target)

## The nearest community within reach of f that f does not already hold or
## receive tribute from, and whose overlord (if any) is f's enemy.
static func _nearest_community(f: String, reach: float) -> String:
	var own := GS.faction_settlements(f)
	var best := ""
	var bd := reach
	for sid in Data.settlements:
		var c: String = sid
		if not Data.settlements[sid].has("community") or GS.settlements[sid].faction != c:
			continue
		var ov := overlord(c)
		if ov == f or ov == "player" or (ov != "" and not GS.at_war(f, ov)):
			continue
		for o in own:
			var d: float = Data.settlements[o].pos.distance_to(Data.settlements[sid].pos)
			if d < bd:
				bd = d
				best = c
	return best

static func _seize(f: String, c: String) -> void:
	var king: String = Data.factions[f].get("king", "")
	for sid in GS.faction_settlements(c):
		var s: Dictionary = GS.settlements[sid]
		s.faction = f
		s.owner = king if Data.lords.has(king) else ""
		s.prosperity = maxf(5.0, s.prosperity - 15.0)
		s.looted_until = GS.hours + 24.0 * 4.0
		GS.world_msg("Soldiers of the %s take %s by force. Its granary burns; its elders are marched to %s." % [Data.factions[f].name, Data.settlements[sid].name, Data.settlements.get(Data.factions[f].get("capital", ""), {"name": "the capital"}).name], Color(1, 0.55, 0.35), [f, c], Data.settlements[sid].pos)
	protect(c, f)
	GS.fealty.erase(c)
