extends RefCounted
## Ambitions: goals for a sandbox without a campaign. Three tiers, from a
## first fight to ruling towns or being elected High Chief, each checked once
## a day against the world as it is. Completing one gives renown and gold, and
## the later ones an attribute point; the Quest Log (J) lists what is open and
## how far along it is.
##
## Counters the checks read live in GS.player.stats (battles_won, raids,
## arena_wins, duels_won), kept by GameState when those things happen.

const Fealty = preload("res://scripts/core/fealty.gd")
const MoonCouncil = preload("res://scripts/core/moon_council.gd")

const LIST := [
	# tier 1: the first weeks
	{"id": "first_blood", "tier": 1, "title": "First Blood", "desc": "Win a battle.", "renown": 10, "gold": 100},
	{"id": "ten_swords", "tier": 1, "title": "A Company of Ten", "desc": "Lead a party of ten or more.", "renown": 10, "gold": 100},
	{"id": "purse", "tier": 1, "title": "A Merchant's Purse", "desc": "Hold 1,500 gold at once.", "renown": 10, "gold": 0},
	{"id": "tavern_name", "tier": 1, "title": "Known in the Taverns", "desc": "Reach 60 renown.", "renown": 0, "gold": 200},
	{"id": "patron", "tier": 1, "title": "A Friend in a High Hall", "desc": "Win the friendship (relation 20) of a lord.", "renown": 15, "gold": 150},
	{"id": "own_form", "tier": 1, "title": "Your Own Form", "desc": "Compose a bending form of your own (benders only).", "renown": 10, "gold": 0, "bender": true},
	# tier 2: making a name
	{"id": "captain", "tier": 2, "title": "Captain", "desc": "Lead a party of thirty.", "renown": 25, "gold": 300},
	{"id": "veteran", "tier": 2, "title": "Veteran of Ten Fields", "desc": "Win ten battles.", "renown": 30, "gold": 300},
	{"id": "three_regions", "tier": 2, "title": "Welcome in Three Lands", "desc": "Be liked (standing 15) by factions of three regions.", "renown": 30, "gold": 300},
	{"id": "landed", "tier": 2, "title": "A Hall of Your Own", "desc": "Hold any settlement as your fief.", "renown": 30, "gold": 0, "point": true},
	{"id": "protector", "tier": 2, "title": "Protector", "desc": "Have a community pay you tribute.", "renown": 25, "gold": 0},
	{"id": "arena", "tier": 2, "title": "Crowd's Favourite", "desc": "Win three bouts in an arena or Agni Kai.", "renown": 25, "gold": 250},
	{"id": "techniques", "tier": 2, "title": "Student of the Masters", "desc": "Learn three techniques (benders only).", "renown": 25, "gold": 0, "bender": true, "point": true},
	# tier 3: a power in the world
	{"id": "lord_of_walls", "tier": 3, "title": "Lord of Walls", "desc": "Hold a town or castle.", "renown": 60, "gold": 0, "point": true},
	{"id": "tributaries", "tier": 3, "title": "Five Who Pay", "desc": "Have five communities pay you tribute.", "renown": 60, "gold": 0, "point": true},
	{"id": "high_chief", "tier": 3, "title": "Chosen Under the Moon", "desc": "Be elected High Chief of the Water Tribes.", "renown": 100, "gold": 0, "point": true},
	{"id": "dragon_guest", "tier": 3, "title": "Guest of the Dragons", "desc": "Win the trust (standing 25) of the Sun Warriors.", "renown": 60, "gold": 0, "point": true},
	{"id": "army", "tier": 3, "title": "A Host of Your Own", "desc": "Lead a party of eighty.", "renown": 60, "gold": 500},
]

static func done() -> Dictionary:
	if not GS.player.has("ambitions"):
		GS.player.ambitions = {}
	return GS.player.ambitions

static func stat(k: String) -> int:
	return int(GS.player.get("stats", {}).get(k, 0))

static func bump(k: String, n: int = 1) -> void:
	if not GS.player.has("stats"):
		GS.player.stats = {}
	GS.player.stats[k] = stat(k) + n

static func applies(a: Dictionary) -> bool:
	return not a.get("bender", false) or GS.player.get("bend", "") != ""

## Open ambitions the player can see: everything in the lowest unfinished
## tier and the next one up.
static func open() -> Array:
	var tier := 3
	for a in LIST:
		if applies(a) and not done().has(a.id):
			tier = mini(tier, int(a.tier))
	return LIST.filter(func(a): return applies(a) and not done().has(a.id) and int(a.tier) <= tier + 1)

## [current, target] towards an ambition, for the progress line.
static func progress(id: String) -> Array:
	match id:
		"first_blood": return [stat("battles_won"), 1]
		"veteran": return [stat("battles_won"), 10]
		"ten_swords": return [GS.party_size(), 10]
		"captain": return [GS.party_size(), 30]
		"army": return [GS.party_size(), 80]
		"purse": return [int(GS.player.gold), 1500]
		"tavern_name": return [int(GS.player.renown), 60]
		"patron":
			var best := 0
			for lid in GS.lords:
				best = maxi(best, int(GS.lords[lid].relation))
			return [best, 20]
		"own_form":
			# any form beyond the starter form, or the starter renamed or rebuilt
			var forms: Array = GS.player.get("forms", [])
			var starter: Dictionary = load("res://scripts/battle/forms.gd").starter(load("res://scripts/battle/forms.gd").art_of(GS.player.get("bend", "")))
			var own: bool = forms.size() > 1 or (forms.size() == 1 and (forms[0].get("name", "") != starter.get("name", "") or forms[0].get("moves", []) != starter.get("moves", [])))
			return [1 if own else 0, 1]
		"three_regions":
			var regions := {}
			for f in Data.factions:
				if GS.faction_rel(f) >= 15 and Data.region_of(f) in ["fire", "earth", "water", "air"]:
					regions[Data.region_of(f)] = true
			return [regions.size(), 3]
		"landed":
			return [mini(1, _owned(["village", "town", "castle"])), 1]
		"lord_of_walls":
			return [mini(1, _owned(["town", "castle"])), 1]
		"protector": return [mini(1, Fealty.tributaries("player").size()), 1]
		"tributaries": return [Fealty.tributaries("player").size(), 5]
		"arena": return [stat("arena_wins") + stat("duels_won"), 3]
		"techniques": return [GS.player.get("techniques", []).size(), 3]
		"high_chief": return [1 if MoonCouncil.chief() == "player" else 0, 1]
		"dragon_guest": return [GS.faction_rel("sun_warriors"), 25]
	return [0, 1]

static func _owned(types: Array) -> int:
	var n := 0
	for sid in GS.settlements:
		if GS.settlements[sid].owner == "player" and Data.settlements[sid].type in types:
			n += 1
	return n

## Check every open ambition; reward the ones achieved.
static func daily() -> void:
	for a in LIST:
		if not applies(a) or done().has(a.id):
			continue
		var p := progress(a.id)
		if int(p[0]) >= int(p[1]):
			done()[a.id] = GS.day()
			GS.add_renown(int(a.renown))
			if int(a.gold) > 0:
				GS.add_gold(int(a.gold))
			var extra := ""
			if a.get("point", false):
				GS.player.attr_points = int(GS.player.get("attr_points", 0)) + 1
				extra = " You gain an attribute point."
			GS.log_msg("Ambition achieved: %s. (+%d renown%s)%s" % [a.title, int(a.renown), (", +%d gold" % int(a.gold)) if int(a.gold) > 0 else "", extra], Color(1, 0.85, 0.35))
			Sfx.play("horn", -10.0)
