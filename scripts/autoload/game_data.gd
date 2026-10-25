extends Node
## Static game content: factions, cultures, troops, lords, companions,
## settlements, trade goods and equipment. Nothing here changes at runtime;
## mutable state lives in GameState (autoload "GS").

const MAP_W := 1600.0
const MAP_H := 1200.0

# ---------------------------------------------------------------------------
# Factions
# ---------------------------------------------------------------------------
var factions := {
	"fire_nation": {
		"name": "Fire Nation", "short": "Fire Nation", "color": Color(0.78, 0.16, 0.12),
		"trim": Color(0.95, 0.75, 0.2), "culture": "fire", "king": "haoren", "capital": "caldera",
		"desc": "An island nation of volcanoes and old noble houses. Three ruined harvests drove its Admiralty to seize the Earth Kingdom's Ember Coast. The Fire Lord wants peace; his admiral wants the coast.",
	},
	"earth_kingdom": {
		"name": "Earth Kingdom", "short": "Earth Kingdom", "color": Color(0.24, 0.55, 0.22),
		"trim": Color(0.85, 0.75, 0.35), "culture": "earth", "king": "hualing", "capital": "ba_sing_se",
		"desc": "The largest nation in the world, ruled from Ba Sing Se by a nineteen-year-old queen and the regent who rules for her. It is fighting the Fire Nation on the coast and its own rebels in the mountains.",
	},
	"omashu": {
		"name": "Kingdom of Omashu", "short": "Omashu", "color": Color(0.45, 0.6, 0.2),
		"trim": Color(0.75, 0.55, 0.85), "culture": "omashu", "king": "feng_tao", "capital": "omashu",
		"desc": "A mountain city that stopped sending grain to Ba Sing Se while its own people went hungry, and declared itself free. Its king is loud, its couriers are heroes, and its future depends on a letter.",
	},
	"northern_water": {
		"name": "Northern Water Tribe", "short": "North Water", "color": Color(0.2, 0.45, 0.8),
		"trim": Color(0.9, 0.95, 1.0), "culture": "north", "king": "tulok", "capital": "agna_qela",
		"desc": "A proud polar nation behind great walls of ice, neutral and divided over whether to help the South. By old law its women may learn waterbending only as healing.",
	},
	"southern_water": {
		"name": "Southern Water Tribe", "short": "South Water", "color": Color(0.15, 0.32, 0.62),
		"trim": Color(0.85, 0.85, 0.9), "culture": "south", "king": "siqiniq", "capital": "southern_tribe",
		"desc": "A great city of ice and canals, the North's equal in all but pride. Its council votes on war, and its raiders strike the Fire Navy's supply ships.",
	},
	"air_nomads": {
		"name": "Air Nomads", "short": "Air Nomads", "color": Color(0.95, 0.62, 0.15),
		"trim": Color(0.95, 0.88, 0.55), "culture": "air", "king": "", "capital": "",
		"desc": "Four temples of monks and nuns who will not fight. They shelter refugees from every side and are trusted by everyone, which is beginning to make them a target.",
	},
	"player": {
		"name": "Your Realm", "short": "Your Realm", "color": Color(0.6, 0.35, 0.75),
		"trim": Color(0.95, 0.9, 0.6), "culture": "earth", "king": "player", "capital": "",
		"desc": "The lands you hold in your own name.",
	},
	"bandits": {
		"name": "Outlaws", "short": "Outlaws", "color": Color(0.35, 0.3, 0.25),
		"trim": Color(0.6, 0.55, 0.45), "culture": "earth", "king": "", "capital": "",
		"desc": "Pirates, raiders and deserters who prey on everyone.",
	},
	"red_lanterns": {
		"name": "Red Lantern Brotherhood", "short": "Red Lanterns", "color": Color(0.7, 0.18, 0.15),
		"trim": Color(0.95, 0.7, 0.3), "culture": "earth", "king": "", "capital": "",
		"desc": "Sworn daofei who rob the Earth Kingdom's tax barges and feed Ba Sing Se's Lower Ring with the grain. Heroes to the hungry, murderers to the Dai Li.",
	},
	"neutral": {
		"name": "Neutral", "short": "Neutral", "color": Color(0.8, 0.8, 0.8),
		"trim": Color(1, 1, 1), "culture": "air", "king": "", "capital": "",
		"desc": "",
	},
}

# Factions that take part in diplomacy (wars, fiefs, lords). The Air Nomads
# never go to war and hold no fiefs that can be taken.
const KINGDOMS := ["fire_nation", "earth_kingdom", "omashu", "northern_water", "southern_water"]

# Wars already being fought when the game begins.
const STARTING_WARS := [["fire_nation", "earth_kingdom"], ["earth_kingdom", "omashu"], ["fire_nation", "southern_water"]]

# How each people orders itself: shown in the Nations window, and the source
# of the class rules the game enforces (see docs/02_writers_room.md, part 2).
var societies := {
	"fire_nation": {"ladder": ["The Fire Lord and the royal family", "The old noble houses", "Fire Sages (outside rank, inside every decision)", "Officers, merchants and civil servants", "Commoners: farmers, fishers, smiths — conscripted at sixteen", "Ember Coast settlers: neither wholly Fire nor Earth"],
		"text": "Rank is inherited, and the noble houses of Caldera terrace the crater walls in order of precedence. Disputes of honour between nobles are settled by Agni Kai, a firebending duel before witnesses. Commoners serve; three ruined harvests have made the service longer and the rations smaller. The Fire Sages chart the sky and announce eclipses, and nobody declares war without asking them first.",
		"rules": "Fire Nation nobles accept an Agni Kai only from someone of Gentry standing; a non-bender must name a firebending champion. Refusing a noble's challenge costs honour."},
	"earth_kingdom": {"ladder": ["The Earth Queen", "The Grand Secretariat, and the Dai Li who serve it", "Upper Ring nobility", "Middle Ring merchants and scholars, who rise by civil examination", "Lower Ring labourers and refugees", "Villagers beyond the walls"],
		"text": "The Kingdom is held together by walls, seals and paperwork. Ba Sing Se's three rings are three worlds, and the gates between them are guarded. The Dai Li were founded long ago to protect the city's culture; now they protect its silence. Most earthbenders are miners, builders and farmers, not soldiers.",
		"rules": "Ba Sing Se's Middle Ring needs Citizen standing or papers; the Upper Ring needs Gentry standing or an invitation. A trade permit improves prices in Earth Kingdom markets."},
	"omashu": {"ladder": ["The King and his Consort", "The Courier Guild and the old mountain families", "Valley farmers", "Refugees, who are granted 'stair rights' after a year"],
		"text": "Omashu promotes by deeds. Anyone who carries a message through a siege has their name carved on the palace stairs, and the stairs are long. The city loves spectacle, argument and its king, roughly in that order. Since the Secession every citizen has been a little bit of a soldier.",
		"rules": "Omashu troops are hardier and faster but less armoured than Ba Sing Se's. Omashu's walls are among the strongest in the world."},
	"northern_water": {"ladder": ["The Chief", "The council of elders and noble families", "Masters of waterbending and of healing", "Warriors and hunters (men) — healers (women)", "Fishers and families of the outer canals"],
		"text": "The North is old, proud and careful. Marriages are arranged between families to bind the council together. Under the Law of the Two Paths, men may learn waterbending as combat and women only as healing — a law written after a famine war nearly took every healer the Tribe had. Some women learn both anyway, at night.",
		"rules": "Northern women may train only as healers until the Law of the Two Paths changes. Changing it opens the Moon Guard."},
	"southern_water": {"ladder": ["The Chief, chosen by the council", "The council: every head of household", "Raider-captains and masters", "Everyone else, loudly"],
		"text": "The South has fewer laws than the North and more arguments. Its council is open to anyone with something to say, and benders of every gender fight. Its raiders defend the seas or commit piracy, depending on whose ship is burning.",
		"rules": "With Southern relation 15 or Gentry standing you may address the council and sway its votes on war and peace."},
	"air_nomads": {"ladder": ["Abbots and abbesses", "Masters, marked with blue arrows", "Monks and nuns", "Novices"],
		"text": "The Nomads have no ranks but age and mastery, and few possessions but their bison. They are vegetarian, will not fight, and shelter anyone who asks. Monks and nuns live in separate temples — a choice of community, not a rule enforced at the gate.",
		"rules": "Air Temples cannot be attacked. Rest there for free; temple markets sell no meat. Pilgrims on sky bison never fight and will heal your wounded."},
}

# Culture -> the tier 1 troop a village or town of that culture offers.
var culture_recruit := {
	"fire": "fn_conscript", "earth": "ek_peasant", "north": "nwt_hunter",
	"south": "swt_villager", "kyoshi": "ky_initiate", "swamp": "sw_swamper",
	"omashu": "om_militia", "air": "an_novice",
}

# ---------------------------------------------------------------------------
# Troops
# ---------------------------------------------------------------------------
# Fields:
#  name, culture, tier, hp, armor, skill (0-100), weapon (item id),
#  ranged (item id or ""), shield (bool), bend (element or ""), bend_power,
#  mount (item id or ""), upgrades (array), look (visual style dict),
#  healer (bool, heals allies in battle and improves party recovery)
var troops := {}

const TIER_WAGE := [0, 2, 4, 8, 14, 22]
const TIER_UPGRADE_COST := [0, 0, 15, 40, 90, 160]
const TIER_XP := [0, 80, 200, 420, 800, 99999]

func _t(id: String, name: String, culture: String, tier: int, o: Dictionary) -> void:
	var d := {
		"id": id, "name": name, "culture": culture, "tier": tier,
		"hp": 36 + tier * 8, "armor": 4 + tier * 6, "skill": 20 + tier * 14,
		"weapon": "spear", "ranged": "", "shield": false, "bend": "", "bend_power": 1.0,
		"mount": "", "upgrades": [], "healer": false, "hero": false,
		"look": {"body": Color(0.5, 0.5, 0.5), "trim": Color(0.3, 0.3, 0.3), "helmet": "none"},
	}
	for k in o:
		d[k] = o[k]
	troops[id] = d

func _init_troops() -> void:
	var fn_body := Color(0.55, 0.12, 0.1)
	var fn_trim := Color(0.15, 0.1, 0.1)
	var fn_elite := Color(0.35, 0.08, 0.06)
	# Fire Nation
	_t("fn_conscript", "Fire Nation Conscript", "fire", 1, {"weapon": "spear",
		"upgrades": ["fn_soldier", "fn_fb_recruit"],
		"look": {"body": Color(0.6, 0.25, 0.2), "trim": fn_trim, "helmet": "fn_cap"}})
	_t("fn_soldier", "Fire Nation Soldier", "fire", 2, {"weapon": "spear", "shield": true,
		"upgrades": ["fn_veteran", "fn_archer"],
		"look": {"body": fn_body, "trim": fn_trim, "helmet": "fn_helmet"}})
	_t("fn_veteran", "Fire Nation Veteran", "fire", 3, {"weapon": "dao", "shield": true,
		"upgrades": ["fn_rhino_rider"],
		"look": {"body": fn_elite, "trim": Color(0.2, 0.2, 0.2), "helmet": "fn_helmet"}})
	_t("fn_archer", "Fire Nation Archer", "fire", 3, {"weapon": "knife", "ranged": "short_bow",
		"upgrades": ["fn_yuyan"], "armor": 14,
		"look": {"body": fn_body, "trim": Color(0.1, 0.1, 0.1), "helmet": "fn_cap"}})
	_t("fn_yuyan", "Yuyan Archer", "fire", 4, {"weapon": "knife", "ranged": "yuyan_bow",
		"armor": 18, "skill": 85,
		"look": {"body": Color(0.2, 0.08, 0.08), "trim": Color(0.6, 0.1, 0.1), "helmet": "yuyan"}})
	_t("fn_rhino_rider", "Komodo Rhino Rider", "fire", 4, {"weapon": "spear", "shield": true,
		"mount": "komodo_rhino", "hp": 75,
		"look": {"body": fn_elite, "trim": Color(0.75, 0.6, 0.2), "helmet": "fn_helmet"}})
	_t("fn_fb_recruit", "Firebender Recruit", "fire", 2, {"weapon": "fists", "bend": "fire",
		"bend_power": 1.0, "armor": 10, "upgrades": ["fn_firebender"],
		"look": {"body": Color(0.65, 0.18, 0.12), "trim": fn_trim, "helmet": "fn_cap"}})
	_t("fn_firebender", "Firebender Soldier", "fire", 3, {"weapon": "fists", "bend": "fire",
		"bend_power": 1.3, "armor": 16, "upgrades": ["fn_imperial_fb"],
		"look": {"body": fn_body, "trim": Color(0.9, 0.6, 0.1), "helmet": "fn_helmet"}})
	_t("fn_imperial_fb", "Imperial Firebender", "fire", 4, {"weapon": "fists", "bend": "fire",
		"bend_power": 1.7, "armor": 24, "hp": 70,
		"look": {"body": fn_elite, "trim": Color(0.95, 0.75, 0.2), "helmet": "fn_officer"}})

	# Earth Kingdom
	var ek_body := Color(0.25, 0.45, 0.2)
	var ek_trim := Color(0.55, 0.45, 0.25)
	_t("ek_peasant", "Earth Kingdom Peasant", "earth", 1, {"weapon": "staff",
		"upgrades": ["ek_soldier", "ek_eb_recruit"],
		"look": {"body": Color(0.55, 0.5, 0.35), "trim": Color(0.35, 0.3, 0.2), "helmet": "straw_hat"}})
	_t("ek_soldier", "Earth Kingdom Soldier", "earth", 2, {"weapon": "spear", "shield": true,
		"upgrades": ["ek_veteran", "ek_archer"],
		"look": {"body": ek_body, "trim": ek_trim, "helmet": "ek_hat"}})
	_t("ek_veteran", "Earth Kingdom Veteran", "earth", 3, {"weapon": "dao", "shield": true,
		"upgrades": ["ek_ostrich_rider", "ek_royal_guard"],
		"look": {"body": Color(0.2, 0.38, 0.17), "trim": Color(0.65, 0.55, 0.3), "helmet": "ek_hat"}})
	_t("ek_archer", "Earth Kingdom Archer", "earth", 3, {"weapon": "knife", "ranged": "short_bow",
		"armor": 14, "look": {"body": ek_body, "trim": Color(0.4, 0.3, 0.2), "helmet": "ek_hat"}})
	_t("ek_ostrich_rider", "Ostrich Horse Cavalry", "earth", 4, {"weapon": "spear", "shield": true,
		"mount": "ostrich_horse", "hp": 70,
		"look": {"body": Color(0.2, 0.38, 0.17), "trim": Color(0.75, 0.65, 0.3), "helmet": "ek_hat"}})
	_t("ek_royal_guard", "Ba Sing Se Royal Guard", "earth", 4, {"weapon": "guan_dao",
		"armor": 34, "hp": 72,
		"look": {"body": Color(0.18, 0.32, 0.15), "trim": Color(0.85, 0.75, 0.35), "helmet": "ek_helm"}})
	_t("ek_eb_recruit", "Earthbender Recruit", "earth", 2, {"weapon": "fists", "bend": "earth",
		"bend_power": 1.0, "armor": 10, "upgrades": ["ek_earthbender"],
		"look": {"body": Color(0.4, 0.5, 0.3), "trim": ek_trim, "helmet": "none"}})
	_t("ek_earthbender", "Earthbender Soldier", "earth", 3, {"weapon": "fists", "bend": "earth",
		"bend_power": 1.3, "armor": 18, "upgrades": ["ek_dai_li"],
		"look": {"body": ek_body, "trim": Color(0.5, 0.4, 0.2), "helmet": "ek_hat"}})
	_t("ek_dai_li", "Dai Li Agent", "earth", 4, {"weapon": "fists", "bend": "earth",
		"bend_power": 1.7, "armor": 20, "skill": 85,
		"look": {"body": Color(0.15, 0.25, 0.12), "trim": Color(0.1, 0.1, 0.1), "helmet": "dai_li"}})

	# Kingdom of Omashu: hardier and faster than Ba Sing Se's levies, less armoured
	var om_body := Color(0.42, 0.5, 0.25)
	var om_trim := Color(0.55, 0.38, 0.6)
	_t("om_militia", "Omashu Militia", "omashu", 1, {"weapon": "staff", "hp": 46, "armor": 6,
		"upgrades": ["om_soldier", "om_stonebreaker"],
		"look": {"body": Color(0.55, 0.52, 0.35), "trim": om_trim, "helmet": "straw_hat"}})
	_t("om_soldier", "Omashu Soldier", "omashu", 2, {"weapon": "spear", "shield": true, "hp": 56, "armor": 12,
		"upgrades": ["om_chute_runner", "om_royal_guard"],
		"look": {"body": om_body, "trim": om_trim, "helmet": "ek_hat"}})
	_t("om_chute_runner", "Chute Runner", "omashu", 3, {"weapon": "staff", "ranged": "throwing_knives", "hp": 62, "armor": 14, "skill": 70,
		"look": {"body": Color(0.5, 0.45, 0.3), "trim": om_trim, "helmet": "bandana"}})
	_t("om_royal_guard", "Omashu Royal Guard", "omashu", 4, {"weapon": "guan_dao", "hp": 80, "armor": 28,
		"look": {"body": Color(0.35, 0.42, 0.2), "trim": Color(0.65, 0.45, 0.75), "helmet": "ek_helm"}})
	_t("om_stonebreaker", "Stonebreaker", "omashu", 2, {"weapon": "fists", "bend": "earth", "bend_power": 1.05,
		"hp": 54, "armor": 10, "upgrades": ["om_boulder"],
		"look": {"body": Color(0.48, 0.5, 0.3), "trim": om_trim, "helmet": "none"}})
	_t("om_boulder", "Mountain Earthbender", "omashu", 3, {"weapon": "fists", "bend": "earth", "bend_power": 1.4,
		"hp": 68, "armor": 16,
		"look": {"body": om_body, "trim": om_trim, "helmet": "none"}})

	# Kyoshi Island
	var ky_body := Color(0.2, 0.55, 0.3)
	var ky_trim := Color(0.85, 0.7, 0.2)
	_t("ky_initiate", "Kyoshi Initiate", "kyoshi", 1, {"weapon": "kyoshi_fans", "skill": 35,
		"upgrades": ["ky_warrior"], "look": {"body": ky_body, "trim": ky_trim, "helmet": "kyoshi"}})
	_t("ky_warrior", "Kyoshi Warrior", "kyoshi", 2, {"weapon": "kyoshi_fans", "skill": 60,
		"upgrades": ["ky_veteran"], "look": {"body": ky_body, "trim": ky_trim, "helmet": "kyoshi"}})
	_t("ky_veteran", "Kyoshi Veteran", "kyoshi", 3, {"weapon": "jian", "skill": 75, "shield": false,
		"upgrades": ["ky_elite"], "look": {"body": Color(0.15, 0.45, 0.25), "trim": ky_trim, "helmet": "kyoshi"}})
	_t("ky_elite", "Kyoshi Elite Guard", "kyoshi", 4, {"weapon": "jian", "skill": 90, "armor": 26,
		"look": {"body": Color(0.12, 0.4, 0.22), "trim": Color(0.95, 0.8, 0.25), "helmet": "kyoshi"}})

	# Northern Water Tribe
	var nwt_body := Color(0.2, 0.35, 0.65)
	var nwt_trim := Color(0.9, 0.9, 0.95)
	_t("nwt_hunter", "Northern Hunter", "north", 1, {"weapon": "spear",
		"upgrades": ["nwt_warrior", "nwt_wb_student"],
		"look": {"body": Color(0.35, 0.45, 0.65), "trim": nwt_trim, "helmet": "parka"}})
	_t("nwt_warrior", "Northern Warrior", "north", 2, {"weapon": "war_club", "shield": true,
		"upgrades": ["nwt_veteran"], "look": {"body": nwt_body, "trim": nwt_trim, "helmet": "parka"}})
	_t("nwt_veteran", "Northern Veteran", "north", 3, {"weapon": "spear", "shield": true,
		"upgrades": ["nwt_guard"], "look": {"body": Color(0.15, 0.28, 0.55), "trim": nwt_trim, "helmet": "parka"}})
	_t("nwt_guard", "Agna Qel'a Guard", "north", 4, {"weapon": "guan_dao", "armor": 30, "hp": 72,
		"look": {"body": Color(0.12, 0.22, 0.48), "trim": Color(1, 1, 1), "helmet": "wt_helm"}})
	_t("nwt_wb_student", "Waterbending Student", "north", 2, {"weapon": "fists", "bend": "water",
		"bend_power": 1.0, "armor": 8, "upgrades": ["nwt_waterbender", "nwt_healer", "nwt_moon_guard"],
		"look": {"body": Color(0.3, 0.5, 0.75), "trim": nwt_trim, "helmet": "topknot"}})
	_t("nwt_waterbender", "Northern Waterbender", "north", 3, {"weapon": "fists", "bend": "water",
		"bend_power": 1.35, "armor": 14, "upgrades": ["nwt_master"],
		"look": {"body": nwt_body, "trim": nwt_trim, "helmet": "topknot"}})
	_t("nwt_master", "Waterbending Master", "north", 4, {"weapon": "fists", "bend": "water",
		"bend_power": 1.75, "armor": 18, "hp": 68, "skill": 85,
		"look": {"body": Color(0.12, 0.22, 0.5), "trim": Color(1, 1, 1), "helmet": "topknot"}})
	_t("nwt_healer", "Water Tribe Healer", "north", 3, {"weapon": "fists", "bend": "water",
		"bend_power": 0.9, "armor": 8, "healer": true,
		"look": {"body": Color(0.45, 0.6, 0.85), "trim": nwt_trim, "helmet": "none"}})

	# Southern Water Tribe
	var swt_body := Color(0.25, 0.38, 0.6)
	var swt_trim := Color(0.85, 0.85, 0.85)
	_t("swt_villager", "Southern Villager", "south", 1, {"weapon": "war_club",
		"upgrades": ["swt_warrior", "swt_wb_student"], "look": {"body": Color(0.4, 0.48, 0.62), "trim": swt_trim, "helmet": "parka"}})
	_t("swt_warrior", "Southern Warrior", "south", 2, {"weapon": "spear", "shield": true,
		"upgrades": ["swt_veteran", "swt_boomerang"],
		"look": {"body": swt_body, "trim": swt_trim, "helmet": "warpaint"}})
	_t("swt_veteran", "Southern Veteran", "south", 3, {"weapon": "war_club", "shield": true,
		"upgrades": ["swt_wolf"], "look": {"body": Color(0.2, 0.3, 0.52), "trim": swt_trim, "helmet": "warpaint"}})
	_t("swt_boomerang", "Boomerang Thrower", "south", 3, {"weapon": "machete", "ranged": "boomerang",
		"skill": 70, "look": {"body": swt_body, "trim": swt_trim, "helmet": "warpaint"}})
	_t("swt_wolf", "Wolf Warrior", "south", 4, {"weapon": "machete", "ranged": "boomerang", "shield": true,
		"armor": 26, "hp": 74, "skill": 85,
		"look": {"body": Color(0.15, 0.22, 0.42), "trim": Color(0.95, 0.95, 0.95), "helmet": "wolf"}})

	_t("swt_wb_student", "Southern Waterbending Student", "south", 2, {"weapon": "fists", "bend": "water",
		"bend_power": 1.0, "armor": 8, "upgrades": ["swt_waterbender"],
		"look": {"body": Color(0.3, 0.45, 0.68), "trim": swt_trim, "helmet": "none"}})
	_t("swt_waterbender", "Southern Waterbender", "south", 3, {"weapon": "fists", "bend": "water",
		"bend_power": 1.35, "armor": 14, "upgrades": ["swt_tide_master"],
		"look": {"body": swt_body, "trim": swt_trim, "helmet": "warpaint"}})
	_t("swt_tide_master", "Tide Master", "south", 4, {"weapon": "fists", "bend": "water",
		"bend_power": 1.7, "armor": 18, "hp": 68, "skill": 85,
		"look": {"body": Color(0.15, 0.25, 0.48), "trim": Color(0.95, 0.95, 0.95), "helmet": "warpaint"}})
	# Moon Guard: Northern women warriors, only once the Law of the Two Paths changes
	_t("nwt_moon_guard", "Moon Guard", "north", 3, {"weapon": "fists", "bend": "water",
		"bend_power": 1.4, "armor": 16, "upgrades": ["nwt_moon_master"], "sex": "f", "locked": "two_paths",
		"look": {"body": Color(0.18, 0.3, 0.6), "trim": Color(0.85, 0.9, 1.0), "helmet": "topknot"}})
	_t("nwt_moon_master", "Moon Guard Master", "north", 4, {"weapon": "fists", "bend": "water",
		"bend_power": 1.8, "armor": 20, "hp": 70, "skill": 88, "sex": "f", "locked": "two_paths",
		"look": {"body": Color(0.1, 0.2, 0.48), "trim": Color(1, 1, 1), "helmet": "topknot"}})

	# Foggy Swamp
	_t("sw_swamper", "Swamp Dweller", "swamp", 1, {"weapon": "staff", "upgrades": ["sw_swampbender"],
		"look": {"body": Color(0.35, 0.4, 0.25), "trim": Color(0.25, 0.2, 0.15), "helmet": "none"}})
	_t("sw_swampbender", "Swampbender", "swamp", 2, {"weapon": "staff", "bend": "water",
		"bend_power": 1.1, "upgrades": ["sw_swamp_master"],
		"look": {"body": Color(0.3, 0.38, 0.22), "trim": Color(0.25, 0.2, 0.15), "helmet": "none"}})
	_t("sw_swamp_master", "Swamp Tribe Master", "swamp", 3, {"weapon": "staff", "bend": "water",
		"bend_power": 1.5, "hp": 70,
		"look": {"body": Color(0.25, 0.32, 0.18), "trim": Color(0.3, 0.25, 0.15), "helmet": "none"}})

	# Outlaws and others
	_t("mountain_bandit", "Mountain Bandit", "earth", 1, {"weapon": "axe", "skill": 30,
		"look": {"body": Color(0.45, 0.35, 0.25), "trim": Color(0.3, 0.2, 0.1), "helmet": "bandana"}})
	_t("pirate", "River Pirate", "earth", 2, {"weapon": "dao", "ranged": "throwing_knives",
		"look": {"body": Color(0.4, 0.2, 0.3), "trim": Color(0.15, 0.15, 0.15), "helmet": "bandana"}})
	_t("pirate_captain", "Pirate Captain", "earth", 3, {"weapon": "dao", "hp": 64,
		"look": {"body": Color(0.3, 0.12, 0.2), "trim": Color(0.8, 0.7, 0.2), "helmet": "pirate_hat"}})
	_t("fn_deserter", "Fire Nation Deserter", "fire", 2, {"weapon": "fists", "bend": "fire",
		"bend_power": 0.9, "armor": 8,
		"look": {"body": Color(0.45, 0.25, 0.2), "trim": Color(0.3, 0.2, 0.15), "helmet": "topknot"}})
	_t("sand_raider", "Sandbender Raider", "sand", 2, {"weapon": "staff", "bend": "sand",
		"bend_power": 1.0, "look": {"body": Color(0.75, 0.65, 0.45), "trim": Color(0.5, 0.35, 0.2), "helmet": "sand_wrap"}})
	_t("sand_chief", "Sandbender Chief", "sand", 3, {"weapon": "staff", "bend": "sand",
		"bend_power": 1.4, "hp": 65,
		"look": {"body": Color(0.6, 0.5, 0.35), "trim": Color(0.6, 0.2, 0.15), "helmet": "sand_wrap"}})
	_t("red_lantern", "Red Lantern Brother", "earth", 2, {"weapon": "jian", "ranged": "short_bow",
		"skill": 55, "upgrades": ["red_lantern_elder"],
		"look": {"body": Color(0.45, 0.25, 0.18), "trim": Color(0.75, 0.15, 0.1), "helmet": "bandana"}})
	_t("red_lantern_elder", "Red Lantern Elder Brother", "earth", 3, {"weapon": "hook_swords", "skill": 75,
		"look": {"body": Color(0.4, 0.2, 0.15), "trim": Color(0.85, 0.2, 0.12), "helmet": "none"}})
	_t("merc_swordsman", "Mercenary Swordsman", "earth", 3, {"weapon": "dao", "shield": true,
		"look": {"body": Color(0.45, 0.42, 0.38), "trim": Color(0.25, 0.25, 0.25), "helmet": "ek_hat"}})
	_t("merc_archer", "Mercenary Archer", "earth", 2, {"weapon": "knife", "ranged": "short_bow",
		"look": {"body": Color(0.5, 0.45, 0.35), "trim": Color(0.3, 0.25, 0.2), "helmet": "straw_hat"}})
	_t("rough_rhino", "Rhino Lancer (mercenary)", "fire", 4, {"weapon": "guan_dao", "mount": "komodo_rhino",
		"hp": 80, "armor": 28, "skill": 80,
		"look": {"body": Color(0.3, 0.25, 0.2), "trim": Color(0.6, 0.15, 0.1), "helmet": "fn_cap"}})

	# Air Nomads: travel as pilgrims, never start fights, defend themselves only
	_t("an_novice", "Air Nomad Novice", "air", 1, {"weapon": "staff", "bend": "air", "bend_power": 0.8,
		"armor": 2, "upgrades": ["an_monk"], "look": {"body": Color(0.95, 0.6, 0.15), "trim": Color(0.95, 0.85, 0.3), "helmet": "none"}})
	_t("an_monk", "Air Nomad Monk", "air", 2, {"weapon": "staff", "bend": "air", "bend_power": 1.2,
		"armor": 4, "healer": true, "upgrades": ["an_master"],
		"look": {"body": Color(0.95, 0.6, 0.15), "trim": Color(0.95, 0.85, 0.3), "helmet": "none"}})
	_t("an_master", "Airbending Master", "air", 4, {"weapon": "staff", "bend": "air", "bend_power": 2.0,
		"armor": 8, "hp": 70, "skill": 90, "healer": true,
		"look": {"body": Color(0.95, 0.55, 0.12), "trim": Color(0.95, 0.85, 0.3), "helmet": "arrow"}})

	# Generic lord stand-ins (stats are overwritten from the lord definition)
	_t("lord_unit", "Lord", "earth", 5, {"hero": true})

# ---------------------------------------------------------------------------
# Items
# ---------------------------------------------------------------------------
# slot: weapon | ranged | armor | helmet | mount
var items := {
	# melee weapons
	"fists": {"name": "Bare Hands", "slot": "weapon", "dmg": 9, "reach": 1.1, "speed": 1.4, "dtype": "blunt", "price": 0, "model": "none"},
	"knife": {"name": "Knife", "slot": "weapon", "dmg": 12, "reach": 1.1, "speed": 1.35, "dtype": "cut", "price": 40, "model": "knife"},
	"staff": {"name": "Wooden Staff", "slot": "weapon", "dmg": 13, "reach": 2.3, "speed": 1.05, "dtype": "blunt", "price": 60, "model": "staff"},
	"axe": {"name": "Woodcutter's Axe", "slot": "weapon", "dmg": 18, "reach": 1.3, "speed": 0.95, "dtype": "cut", "price": 90, "model": "axe"},
	"spear": {"name": "Spear", "slot": "weapon", "dmg": 17, "reach": 2.5, "speed": 0.95, "dtype": "pierce", "price": 120, "model": "spear"},
	"war_club": {"name": "Water Tribe Club", "slot": "weapon", "dmg": 18, "reach": 1.3, "speed": 1.05, "dtype": "blunt", "price": 110, "model": "club"},
	"machete": {"name": "Machete", "slot": "weapon", "dmg": 19, "reach": 1.35, "speed": 1.15, "dtype": "cut", "price": 180, "model": "machete"},
	"kyoshi_fans": {"name": "Kyoshi War Fans", "slot": "weapon", "dmg": 16, "reach": 1.25, "speed": 1.35, "dtype": "cut", "price": 260, "model": "fans"},
	"jian": {"name": "Jian", "slot": "weapon", "dmg": 21, "reach": 1.55, "speed": 1.2, "dtype": "cut", "price": 380, "model": "sword"},
	"dao": {"name": "Dao Broadsword", "slot": "weapon", "dmg": 23, "reach": 1.5, "speed": 1.05, "dtype": "cut", "price": 420, "model": "dao"},
	"hook_swords": {"name": "Hook Swords", "slot": "weapon", "dmg": 22, "reach": 1.6, "speed": 1.25, "dtype": "cut", "price": 650, "model": "hooks"},
	"dual_dao": {"name": "Dual Dao", "slot": "weapon", "dmg": 25, "reach": 1.45, "speed": 1.25, "dtype": "cut", "price": 900, "model": "dual_dao"},
	"guan_dao": {"name": "Guan Dao", "slot": "weapon", "dmg": 30, "reach": 2.5, "speed": 0.78, "dtype": "cut", "price": 750, "model": "guan_dao"},
	"space_sword": {"name": "Sky-Iron Sword", "slot": "weapon", "dmg": 34, "reach": 1.7, "speed": 1.15, "dtype": "cut", "price": 6000, "model": "space_sword"},
	# ranged
	"short_bow": {"name": "Short Bow", "slot": "ranged", "dmg": 21, "ammo": 24, "accuracy": 0.8, "proj_speed": 45.0, "price": 200, "model": "bow"},
	"yuyan_bow": {"name": "Yuyan Longbow", "slot": "ranged", "dmg": 31, "ammo": 24, "accuracy": 0.95, "proj_speed": 60.0, "price": 1100, "model": "bow"},
	"boomerang": {"name": "Boomerang", "slot": "ranged", "dmg": 18, "ammo": 99, "accuracy": 0.85, "proj_speed": 28.0, "price": 150, "model": "boomerang"},
	"throwing_knives": {"name": "Throwing Knives", "slot": "ranged", "dmg": 19, "ammo": 8, "accuracy": 0.75, "proj_speed": 32.0, "price": 120, "model": "knife"},
	# body armour
	"peasant_clothes": {"name": "Peasant Clothes", "slot": "armor", "armor": 3, "price": 20},
	"water_parka": {"name": "Water Tribe Parka", "slot": "armor", "armor": 8, "price": 120},
	"fur_armor": {"name": "Fur and Bone Armour", "slot": "armor", "armor": 15, "price": 420},
	"ek_armor": {"name": "Earth Kingdom Lamellar", "slot": "armor", "armor": 17, "price": 520},
	"kyoshi_armor": {"name": "Kyoshi Warrior Armour", "slot": "armor", "armor": 19, "price": 700},
	"fn_armor": {"name": "Fire Nation Plate", "slot": "armor", "armor": 21, "price": 760},
	"ek_royal": {"name": "Royal Guard Armour", "slot": "armor", "armor": 27, "price": 1500},
	"fn_officer_armor": {"name": "Fire Nation Officer's Plate", "slot": "armor", "armor": 30, "price": 2100},
	# helmets
	"straw_hat": {"name": "Straw Hat", "slot": "helmet", "armor": 1, "price": 10, "look": "straw_hat"},
	"parka_hood": {"name": "Fur Hood", "slot": "helmet", "armor": 3, "price": 40, "look": "parka"},
	"ek_hat": {"name": "Earth Kingdom Helmet", "slot": "helmet", "armor": 5, "price": 150, "look": "ek_hat"},
	"fn_helmet": {"name": "Fire Nation Helmet", "slot": "helmet", "armor": 7, "price": 220, "look": "fn_helmet"},
	"wolf_helm": {"name": "Wolf Helm", "slot": "helmet", "armor": 6, "price": 260, "look": "wolf"},
	"fn_officer_helm": {"name": "Officer's Helm", "slot": "helmet", "armor": 10, "price": 600, "look": "fn_officer"},
	# mounts
	"ostrich_horse": {"name": "Ostrich Horse", "slot": "mount", "speed": 13.0, "hp": 90, "armor": 6, "price": 700, "look": "ostrich"},
	"komodo_rhino": {"name": "Komodo Rhino", "slot": "mount", "speed": 10.0, "hp": 170, "armor": 22, "price": 2200, "look": "rhino"},
}

# Which equipment each culture's smiths sell.
var culture_shop := {
	"fire": ["knife", "spear", "dao", "dual_dao", "guan_dao", "short_bow", "yuyan_bow", "fn_armor", "fn_officer_armor", "fn_helmet", "fn_officer_helm", "komodo_rhino", "peasant_clothes"],
	"earth": ["staff", "axe", "spear", "jian", "dao", "hook_swords", "guan_dao", "short_bow", "throwing_knives", "peasant_clothes", "ek_armor", "ek_royal", "straw_hat", "ek_hat", "ostrich_horse"],
	"north": ["spear", "war_club", "machete", "boomerang", "water_parka", "fur_armor", "parka_hood", "wolf_helm"],
	"south": ["spear", "war_club", "machete", "boomerang", "water_parka", "fur_armor", "parka_hood", "wolf_helm"],
	"kyoshi": ["kyoshi_fans", "jian", "kyoshi_armor", "straw_hat"],
	"omashu": ["staff", "spear", "jian", "guan_dao", "throwing_knives", "short_bow", "peasant_clothes", "ek_armor", "straw_hat", "ek_hat", "ostrich_horse"],
}

# ---------------------------------------------------------------------------
# Trade goods
# ---------------------------------------------------------------------------
var goods := {
	"rice": {"name": "Rice", "price": 5, "food": true},
	"fish": {"name": "Smoked Fish", "price": 5, "food": true},
	"cabbages": {"name": "Cabbages", "price": 3, "food": true},
	"seal_jerky": {"name": "Seal Jerky", "price": 7, "food": true},
	"fire_flakes": {"name": "Fire Flakes", "price": 6, "food": true},
	"sea_prunes": {"name": "Stewed Sea Prunes", "price": 4, "food": true},
	"tea": {"name": "Jasmine Tea", "price": 70, "food": false},
	"jade": {"name": "Jade", "price": 280, "food": false},
	"iron": {"name": "Iron", "price": 110, "food": false},
	"silk": {"name": "Silk", "price": 190, "food": false},
	"furs": {"name": "Furs", "price": 140, "food": false},
	"spices": {"name": "Spices", "price": 95, "food": false},
	"herbs": {"name": "Medicinal Herbs", "price": 75, "food": false},
	"salt": {"name": "Salt", "price": 45, "food": false},
	"pottery": {"name": "Pottery", "price": 55, "food": false},
	"whale_oil": {"name": "Whale Oil", "price": 85, "food": false},
}

# ---------------------------------------------------------------------------
# Lords
# ---------------------------------------------------------------------------
# bend: element, power: bending multiplier, weapon: item, troops: starting size.
# bio: what they want, what they fear, and one human detail (see
# docs/02_writers_room.md). look: fixed appearance keys (sex, hair, ...).
# no_offense: never joins offensive campaigns.
const GREY := Color(0.62, 0.6, 0.58)
var lords := {
	# Fire Nation
	"haoren": {"name": "Fire Lord Haoren", "faction": "fire_nation", "bend": "fire", "power": 2.6, "weapon": "fists", "hp": 200, "troops": 120, "home": "caldera", "king": true, "aggression": 0.25,
		"look": {"sex": "m", "hair": "Hair_SimpleParted", "hair_color": GREY, "beard": true},
		"bio": "Wants peace; fears being remembered as the man who let the Avatar die. He was the Avatar's friend in boyhood and still keeps a chipped Pai Sho tile they played with.",
		"line": "Sit. Everyone who comes before me wants something, and most of them want a war. Which are you?"},
	"ryoko": {"name": "Crown Princess Ryoko", "faction": "fire_nation", "bend": "fire", "power": 2.5, "weapon": "fists", "hp": 180, "troops": 70, "home": "caldera", "aggression": 0.35,
		"look": {"sex": "f", "hair": "Hair_Buns"},
		"bio": "Wants to end the colonies; fears her father's disappointment more than any army. Her wife, Lady Satsuki, keeps the royal archives — and keeps Ryoko honest.",
		"line": "If you've come to tell me the Ember Coast is worth dying for, save your breath. If you've come with an idea, I have tea."},
	"kuro": {"name": "Admiral Tenzai Kuro", "faction": "fire_nation", "bend": "fire", "power": 2.0, "weapon": "dao", "hp": 170, "troops": 90, "home": "fire_navy_harbor", "aggression": 0.85,
		"look": {"sex": "m", "hair": "Hair_Buzzed", "beard": true},
		"bio": "Wants the colonies, and the fortune he has made in them; fears the truth about the night the Avatar drowned. Generous to his sailors and utterly self-justifying.",
		"line": "Every sailor in my fleet eats because I made hard choices. Remember that before you judge me."},
	"ito": {"name": "General Masaru Ito", "faction": "fire_nation", "bend": "", "power": 1.0, "weapon": "dao", "hp": 160, "troops": 90, "home": "pohuai", "aggression": 0.5,
		"look": {"sex": "m", "hair": "Hair_Buzzed", "hair_color": GREY},
		"bio": "Wants to bring his conscripts home alive; fears becoming irrelevant. A non-bender who rose through the ranks and remembers the name of every soldier he has lost.",
		"line": "I have three hundred and twelve names in this book. I would rather not add yours."},
	"hiyori": {"name": "Lady Aimi Hiyori", "faction": "fire_nation", "bend": "", "power": 1.0, "weapon": "knife", "hp": 110, "troops": 60, "home": "fire_fountain", "aggression": 0.4,
		"look": {"sex": "f", "hair": "Hair_Long"},
		"bio": "Wants information, which is power; fears being underestimated, though she encourages it. A spymaster who plays every side and is honest only with her cat.",
		"line": "You're the one everyone's been writing to me about. Oh, don't look so worried. Most of the letters were kind."},
	"daisuke": {"name": "Commander Daisuke Ren", "faction": "fire_nation", "bend": "fire", "power": 1.8, "weapon": "fists", "hp": 150, "troops": 70, "home": "ember_island", "aggression": 0.9,
		"look": {"sex": "m", "hair": "Hair_Long"},
		"bio": "Wants glory; fears being ordinary. A twenty-two-year-old firebending prodigy, insufferable and secretly terrified. Humbled kindly, he could become someone worth following.",
		"line": "You've heard of me, obviously. Everyone has. Go on — ask me about the Battle of Shu Jing Strait."},
	"oda": {"name": "Warden Sakura Oda", "faction": "fire_nation", "bend": "", "power": 1.0, "weapon": "guan_dao", "hp": 140, "troops": 60, "home": "boiling_rock", "aggression": 0.3, "no_offense": true,
		"look": {"sex": "f", "hair": "Hair_Buns", "hair_color": GREY},
		"bio": "Wants order; fears chaos. Runs the Boiling Rock and believes in rehabilitation far more than her guards do.",
		"line": "Every prisoner here is someone's child. I try to remember that. My guards try to forget it."},
	# Earth Kingdom
	"hualing": {"name": "Earth Queen Hualing", "faction": "earth_kingdom", "bend": "", "power": 1.0, "weapon": "staff", "hp": 100, "troops": 110, "home": "ba_sing_se", "king": true, "aggression": 0.3,
		"look": {"sex": "f", "hair": "Hair_Buns"},
		"bio": "Wants to be a real queen; fears being a figurehead. Nineteen, raised in the palace, she has never seen the Lower Ring — and notices far more than her regent thinks.",
		"line": "Secretary Wu says I shouldn't receive petitioners without him. Secretary Wu is not here. Speak."},
	"wu_jian": {"name": "Grand Secretary Wu Jian", "faction": "earth_kingdom", "bend": "earth", "power": 1.9, "weapon": "fists", "hp": 160, "troops": 80, "home": "ba_sing_se", "aggression": 0.4,
		"look": {"sex": "m", "hair": "Hair_SimpleParted", "hair_color": GREY, "beard": true},
		"bio": "Wants control; fears chaos. A careful, soft-spoken regent who believes order is the only real mercy. He has never once raised his voice.",
		"line": "There is a form for that. There is a form for everything. It is how a city of a million people does not burn."},
	"shu_fan": {"name": "Commander Shu Fan", "faction": "earth_kingdom", "bend": "earth", "power": 1.8, "weapon": "fists", "hp": 150, "troops": 70, "home": "ba_sing_se", "aggression": 0.55,
		"look": {"sex": "m", "accessory": "dai_li", "kit": "dai_li_robe"},
		"bio": "Commander of the Dai Li. Wants rank; fears Wu Jian. Loyal to the regent exactly as long as loyalty pays.",
		"line": "The Dai Li hear everything. Choose your next words as if I'm writing them down. I am."},
	"ba_tsai": {"name": "General Ba Tsai", "faction": "earth_kingdom", "bend": "", "power": 1.0, "weapon": "guan_dao", "hp": 160, "troops": 85, "home": "outer_wall", "aggression": 0.5,
		"look": {"sex": "m", "hair": "Hair_Buzzed", "hair_color": GREY, "beard": true},
		"bio": "Wants to hold the Outer Wall; fears pointless orders from the palace. Gruff, fair, and the author of truly bad poetry for his late wife.",
		"line": "The Wall has stood for a thousand years. It'll stand through this. Whether I do is another question."},
	"cheng_mei": {"name": "Lady Cheng Mei", "faction": "earth_kingdom", "bend": "", "power": 1.0, "weapon": "jian", "hp": 100, "troops": 60, "home": "gaoling", "aggression": 0.2,
		"look": {"sex": "f", "hair": "Hair_Buns", "hair_color": GREY},
		"bio": "Wants profit and peace, in that order; fears ruin. A merchant matriarch of Gaoling who quietly funds both sides of everything.",
		"line": "War is terrible for business, unless you sell rice. I sell rice. I would still prefer peace. Rice keeps."},
	"lu_kang": {"name": "General Lu Kang", "faction": "earth_kingdom", "bend": "earth", "power": 1.5, "weapon": "dao", "hp": 150, "troops": 90, "home": "fong_fortress", "aggression": 0.75,
		"look": {"sex": "m", "hair": "Hair_SimpleParted"},
		"bio": "Wants victory over Omashu; fears his brother's ghost. His brother died fighting for Omashu, on the other side.",
		"line": "Omashu is a rebellion with a crown on. I'll take the crown off. Are you here to help or to get in the way?"},
	"tan_yue": {"name": "General Tan Yue", "faction": "earth_kingdom", "bend": "earth", "power": 1.4, "weapon": "spear", "hp": 140, "troops": 75, "home": "serpent_fort", "aggression": 0.45,
		"look": {"sex": "f", "hair": "Hair_Buns"},
		"bio": "Wants to keep the Serpent's Pass open for refugees; fears that the capital has forgotten her fort exists. It has.",
		"line": "The pass is open to anyone who comes in peace. You'd be surprised how few do."},
	"oyama": {"name": "Captain Oyama", "faction": "earth_kingdom", "bend": "", "power": 1.0, "weapon": "kyoshi_fans", "hp": 150, "troops": 40, "home": "gaoling", "aggression": 0.5, "culture": "kyoshi", "no_offense": true,
		"look": {"sex": "f", "hair": "Hair_Buns"},
		"bio": "Leader of the Kyoshi Warriors. Wants to protect Kyoshi Island; fears being drawn into conquest. She has refused three royal orders to march, politely.",
		"line": "The Kyoshi Warriors defend. We don't conquer. If you've come to recruit us for a war, the answer is still no."},
	# Kingdom of Omashu
	"feng_tao": {"name": "King Feng Tao", "faction": "omashu", "bend": "earth", "power": 2.4, "weapon": "fists", "hp": 210, "troops": 110, "home": "omashu", "king": true, "aggression": 0.6,
		"look": {"sex": "m", "hair": "Hair_Long", "beard": true},
		"bio": "Wants Omashu fed and free; fears becoming the tyrant he rebelled against. Loud, theatrical and beloved, married to his consort Jiang Wei.",
		"line": "A visitor! Stand there — no, there, where the light is better. Now: friend of Omashu, or friend of Ba Sing Se?"},
	"jiang_wei": {"name": "Consort Jiang Wei", "faction": "omashu", "bend": "", "power": 1.0, "weapon": "staff", "hp": 100, "troops": 40, "home": "omashu", "aggression": 0.15, "no_offense": true,
		"look": {"sex": "m", "hair": "Hair_SimpleParted"},
		"bio": "A non-bender diplomat who wants a peace that keeps Omashu whole; fears losing Feng to the war. He corresponds secretly with the Fire Nation's crown princess.",
		"line": "My husband makes speeches. I make arrangements. Between us, Omashu survives. What arrangement brings you?"},
	"kuang": {"name": "General Kuang", "faction": "omashu", "bend": "earth", "power": 1.6, "weapon": "fists", "hp": 170, "troops": 90, "home": "stonewatch", "aggression": 0.8,
		"look": {"sex": "f", "hair": "Hair_BuzzedFemale"},
		"bio": "Wants one decisive battle; hates slow sieges. Blunt, loyal, and the only person who can make Feng Tao stop talking.",
		"line": "If you can fight, stay. If you can't, the chutes go down very fast."},
	"bai_shan": {"name": "Lady Bai Shan", "faction": "omashu", "bend": "", "power": 1.0, "weapon": "spear", "hp": 110, "troops": 50, "home": "omashu", "aggression": 0.25,
		"look": {"sex": "f", "hair": "Hair_Long"},
		"bio": "Governor of Omashu's farmland. Wants her farmers safe; fears Ba Sing Se's armies more than famine.",
		"line": "My farmers planted this spring knowing an army might trample it all. Tell me that isn't courage."},
	"doru": {"name": "Captain Doru", "faction": "omashu", "bend": "", "power": 1.0, "weapon": "staff", "hp": 120, "troops": 45, "home": "omashu", "aggression": 0.4,
		"look": {"sex": "m", "hair": "Hair_Buzzed", "beard": true},
		"bio": "Master of the chute-couriers. Wants every message delivered; fears silence. His son Lin is the fastest courier in the city.",
		"line": "If it can be written down, my couriers can deliver it. If it can't, try shouting."},
	# Northern Water Tribe
	"tulok": {"name": "Chief Tulok", "faction": "northern_water", "bend": "", "power": 1.0, "weapon": "spear", "hp": 150, "troops": 100, "home": "agna_qela", "king": true, "aggression": 0.3,
		"look": {"sex": "m", "hair": "Hair_Long", "hair_color": GREY},
		"bio": "Wants safety through distance; fears repeating his father's war. He has kept the North out of every conflict for twenty years and is not sure it was right.",
		"line": "The North has stayed out of other people's wars for a generation. Convince me this one is ours."},
	"aklaq": {"name": "Master Aklaq", "faction": "northern_water", "bend": "water", "power": 2.4, "weapon": "fists", "hp": 180, "troops": 70, "home": "agna_qela", "aggression": 0.45,
		"look": {"sex": "m", "hair": "Hair_Long", "hair_color": GREY, "beard": true},
		"bio": "Guardian of the Law of the Two Paths. Wants to preserve it; fears a world that no longer needs him. His argument is not malice: 'When everyone fights, no one mends.'",
		"line": "The law was written in a famine war, when we nearly lost every healer we had. Remember that before you call it cruelty."},
	"iluq": {"name": "Commander Iluq", "faction": "northern_water", "bend": "water", "power": 1.5, "weapon": "fists", "hp": 140, "troops": 60, "home": "frozen_harbor", "aggression": 0.7,
		"look": {"sex": "m", "hair": "Hair_Long"},
		"bio": "Chief Tulok's nephew. Wants the North to help the South; chafes at his uncle's caution.",
		"line": "Our cousins in the South are fighting for their seas and we're counting icebergs. Tell me you've come to change that."},
	"pana": {"name": "Elder Pana", "faction": "northern_water", "bend": "water", "power": 1.6, "weapon": "fists", "hp": 110, "troops": 30, "home": "agna_qela", "aggression": 0.1, "healer": true, "no_offense": true,
		"look": {"sex": "f", "hair": "Hair_Buns", "hair_color": GREY},
		"bio": "The Tribe's senior healer. Wants healing — and, quietly, change. Fears it will come too late. She taught Nima more than healing.",
		"line": "Sit down, you're bleeding on my floor. We'll talk once you've stopped."},
	"nauja": {"name": "Captain Nauja", "faction": "northern_water", "bend": "", "power": 1.0, "weapon": "spear", "hp": 130, "troops": 55, "home": "frozen_harbor", "aggression": 0.55,
		"look": {"sex": "f", "hair": "Hair_Long"},
		"bio": "Wants open seas; fears the Fire Navy's iron ships. The best sailor in the North, and she knows it.",
		"line": "The sea doesn't care whose flag you fly. I do, a little."},
	# Southern Water Tribe
	"siqiniq": {"name": "Chief Siqiniq", "faction": "southern_water", "bend": "water", "power": 2.0, "weapon": "fists", "hp": 170, "troops": 90, "home": "southern_tribe", "king": true, "aggression": 0.55,
		"look": {"sex": "f", "hair": "Hair_Long"},
		"bio": "Wants victory at sea without losing her people; fears the North's pity more than the Fire Navy.",
		"line": "The council votes on war, not me. But I can tell you which way I'm leaning, if you've earned it."},
	"aput": {"name": "Master Aput", "faction": "southern_water", "bend": "water", "power": 2.2, "weapon": "fists", "hp": 160, "troops": 60, "home": "southern_tribe", "aggression": 0.4,
		"look": {"sex": "m", "hair": "Hair_Long", "hair_color": GREY},
		"bio": "Wants to teach; fears losing students to the raids. He trains benders of every gender and has opinions about the North.",
		"line": "In the South, whoever wants to learn, learns. Do you want to learn?"},
	"qannik": {"name": "Raider-Captain Qannik", "faction": "southern_water", "bend": "", "power": 1.0, "weapon": "war_club", "hp": 170, "troops": 70, "home": "hakodas_watch", "aggression": 0.9,
		"look": {"sex": "m", "hair": "Hair_Long", "accessory": "warpaint", "beard": true},
		"bio": "Wants revenge on the Fire Navy; fears peace, because he does not know who he would be without the raids.",
		"line": "Every Fire Nation ship that sinks is one that won't come south. Want to help me sink some?"},
	"malik": {"name": "Elder Malik", "faction": "southern_water", "bend": "", "power": 1.0, "weapon": "staff", "hp": 90, "troops": 35, "home": "southern_tribe", "aggression": 0.15, "no_offense": true,
		"look": {"sex": "m", "hair": "Hair_Buzzed", "hair_color": GREY},
		"bio": "Wants a negotiated peace; fears Qannik will make one impossible. The council's oldest voice and its most patient.",
		"line": "I have outlived three wars. The trick is to stop them before they outlive you."},
}

# ---------------------------------------------------------------------------
# Companions (heroes met in taverns). See docs/02_writers_room.md section 5.
# ---------------------------------------------------------------------------
# bonus: party skill bonuses; perk: special ability; pronouns for text.
var companions := {
	"hana": {"name": "Hana of the Lower Ring", "short": "Hana", "pronouns": "she", "culture": "earth", "bend": "earth", "power": 1.7, "weapon": "fists", "hp": 130, "armor": 14, "skill": 75, "cost": 500,
		"bonus": {"tactics": 1}, "perk": "tunnels", "vlook": {"sex": "f", "hair": "Hair_BuzzedFemale"},
		"bio": "A Lower Ring earthbender and tunnel smuggler who has mapped every cellar and fault line under Ba Sing Se. Precise, literal, funny without trying. Hates surprises.",
		"pitch": "You're hiring. I have a map of every tunnel under Ba Sing Se, and I prefer to know where we're going before we go. Is that acceptable?"},
	"juro": {"name": "Juro Sato", "short": "Juro", "pronouns": "he", "culture": "fire", "bend": "", "power": 1.0, "weapon": "dao", "ranged": "throwing_knives", "hp": 120, "armor": 16, "skill": 70, "cost": 450,
		"bonus": {"trainer": 1}, "perk": "engineer", "vlook": {"sex": "m", "hair": "Hair_SimpleParted", "accessory": "topknot"},
		"bio": "A Fire Nation artillery engineer who deserted the night one of his designs burned an Ember Coast village. His fire left him that night. His father still writes every week.",
		"pitch": "I used to build siege engines. Now I fix wagon wheels for rice. If you have anything that needs building — or knocking down — I'm cheap and very good."},
	"pemba": {"name": "Pemba", "short": "Pemba", "pronouns": "they", "culture": "air", "bend": "air", "power": 1.5, "weapon": "staff", "hp": 105, "armor": 6, "skill": 80, "cost": 300, "healer": true, "nonlethal": true,
		"bonus": {"healing": 3}, "perk": "nonlethal", "vlook": {"sex": "f", "hair": ""},
		"bio": "An Air Nomad of the Southern Air Temple, looking for their younger sister, who ran away to join the daofei. Gentle, deadpan, brutal at Pai Sho. Will not take a life.",
		"pitch": "I'm looking for my sister. I won't fight for you, but I'll knock people over, mend whoever needs mending, and eat most of your fruit."},
	"nima": {"name": "Nima", "short": "Nima", "pronouns": "she", "culture": "north", "bend": "water", "power": 1.8, "weapon": "fists", "hp": 115, "armor": 8, "skill": 75, "cost": 550, "healer": true,
		"bonus": {"healing": 2}, "perk": "secret_forms", "vlook": {"sex": "f", "hair": "Hair_Long"},
		"bio": "A Northern Water Tribe healer and mother of seven-year-old Kaya, who taught herself combat waterbending at night by watching the men train. Warm, precise, impatient with nonsense.",
		"pitch": "I'm a healer. I'm also considerably more than that, but the North would rather I didn't mention it. Do you need a healer who can also hold a line?"},
	"ukiuk": {"name": "Ukiuk", "short": "Ukiuk", "pronouns": "he", "culture": "south", "bend": "", "power": 1.0, "weapon": "spear", "ranged": "boomerang", "hp": 135, "armor": 12, "skill": 75, "cost": 400,
		"bonus": {"pathfinding": 1}, "perk": "sailor", "vlook": {"sex": "m", "hair": "Hair_Long", "accessory": "warpaint"},
		"bio": "A Southern harpooner and boatbuilder who once built a canoe in two days and forgot to eat for both of them. Fast-talking, restless, and carrying a debt from a raid he cannot forget.",
		"pitch": "I build boats, I throw harpoons, I can tell a squall's coming two hours early. I also talk a lot. That's included. Free of charge."},
	"shen_mu": {"name": "Shen Mu", "short": "Shen Mu", "pronouns": "he", "culture": "earth", "bend": "", "power": 1.0, "weapon": "staff", "ranged": "throwing_knives", "hp": 100, "armor": 8, "skill": 70, "cost": 250,
		"bonus": {"pathfinding": 2}, "perk": "courier", "vlook": {"sex": "m", "hair": "Hair_Buzzed"},
		"bio": "A nineteen-year-old Omashu chute-courier who stutters, reads slowly, and can recite three hundred addresses from memory. He is carrying a letter that could stop a civil war.",
		"pitch": "I n-need to get somewhere, and the roads are full of soldiers. You have soldiers. I know every road. That seems f-fair?"},
	"reika": {"name": "Captain Reika Kuroda", "short": "Reika", "pronouns": "she", "culture": "fire", "bend": "fire", "power": 1.4, "weapon": "jian", "ranged": "throwing_knives", "hp": 135, "armor": 14, "skill": 85, "cost": 900,
		"bonus": {"trade": 2}, "perk": "smuggler", "vlook": {"sex": "f", "hair": "Hair_Long", "accessory": "pirate_hat"},
		"bio": "A Fire Nation privateer sailing under a letter of marque, beginning to suspect her employer, Admiral Kuro, is lying about everything. Charming, mercenary, and less cynical than she pretends.",
		"pitch": "I'm not a hero. I'm a woman with a ship and a very flexible definition of 'cargo'. Pay me and I'm yours until someone pays more. Probably."},
	"kesi": {"name": "Kesi", "short": "Kesi", "pronouns": "she", "culture": "sand", "bend": "sand", "power": 1.6, "weapon": "staff", "hp": 125, "armor": 10, "skill": 80, "cost": 600,
		"bonus": {"tactics": 1, "pathfinding": 1}, "perk": "storm_sign", "signs": true, "vlook": {"sex": "f", "accessory": "sand_wrap"},
		"bio": "A Deaf sandbender tracker, exiled from her clan for refusing to raid a caravan carrying children. She speaks storm-sign, the hand language of the Si Wong.",
		"pitch": "(signing, while a tavern girl translates) You track badly. I could hear you coming from the next dune — and I can't hear. Hire me."},
}

# ---------------------------------------------------------------------------
# Settlements
# ---------------------------------------------------------------------------
# type: town | castle | village | temple | ruin
var settlements := {
	# Fire Nation
	"caldera": {"name": "Caldera City", "type": "town", "faction": "fire_nation", "pos": Vector2(318, 560), "owner": "haoren", "walls": 1.4, "culture": "fire",
		"produces": ["iron", "silk", "pottery"], "desc": "The Fire Nation capital, built inside the crater of a dormant volcano. Noble houses terrace the crater walls by rank; the palace sits highest, and the harbour district lowest."},
	"fire_fountain": {"name": "Fire Fountain City", "type": "town", "faction": "fire_nation", "pos": Vector2(392, 618), "owner": "hiyori", "culture": "fire",
		"produces": ["spices", "pottery"], "desc": "A bustling port crowned by a fire-breathing statue of a Fire Lord nobody can agree on. Every rumour in the Nation passes through its tea houses — and through Lady Hiyori."},
	"ember_island": {"name": "Ember Island", "type": "town", "faction": "fire_nation", "pos": Vector2(452, 505), "owner": "daisuke", "culture": "fire",
		"produces": ["fish", "silk"], "desc": "A resort island for the Fire Nation elite, famous for its beaches, its summer houses and its terrible theatre."},
	"boiling_rock": {"name": "The Boiling Rock", "type": "castle", "faction": "fire_nation", "pos": Vector2(292, 405), "owner": "oda", "walls": 1.3, "culture": "fire",
		"produces": [], "desc": "The Fire Nation's highest-security prison, set on an island in a boiling lake. Its warden runs reading classes on Tuesdays."},
	"pohuai": {"name": "Pohuai Stronghold", "type": "castle", "faction": "fire_nation", "pos": Vector2(705, 455), "owner": "ito", "culture": "fire",
		"produces": [], "desc": "A Fire Nation fortress on the seized Ember Coast, home of the Yuyan archers. General Ito's conscripts call it 'the Kettle'."},
	"fire_navy_harbor": {"name": "Fire Navy Harbour", "type": "castle", "faction": "fire_nation", "pos": Vector2(618, 585), "owner": "kuro", "culture": "fire",
		"produces": [], "desc": "An Earth Kingdom port seized by the Admiralty three years ago and rebuilt in iron. Admiral Kuro's flagship rarely leaves it; his ledgers never do."},
	"shu_jing": {"name": "Shu Jing", "type": "village", "faction": "fire_nation", "pos": Vector2(262, 612), "bound": "caldera", "culture": "fire",
		"produces": ["rice", "fire_flakes"], "desc": "A quiet farming and fishing village in the Fire Nation heartland. Southern raiders struck its fleet two winters ago, and it has not forgotten."},
	"crescent_island": {"name": "Crescent Island", "type": "village", "faction": "fire_nation", "pos": Vector2(200, 470), "bound": "caldera", "culture": "fire",
		"produces": ["fish", "salt"], "desc": "A volcanic island home to an ancient Fire Temple, where the sages chart the sky and announce eclipses days before they come."},
	"jang_hui": {"name": "Jang Hui", "type": "village", "faction": "fire_nation", "pos": Vector2(398, 645), "bound": "fire_fountain", "culture": "fire",
		"produces": ["fish", "rice"], "desc": "A floating village of stilt houses on the delta. Its people trade with both nations and trust neither."},
	"ember_shore": {"name": "Ember Shore", "type": "village", "faction": "fire_nation", "pos": Vector2(470, 520), "bound": "ember_island", "culture": "fire",
		"produces": ["fire_flakes", "salt"], "desc": "Fishing huts and beach houses along the Ember Island shore."},
	"tieshan": {"name": "Tieshan", "type": "village", "faction": "fire_nation", "pos": Vector2(745, 520), "bound": "pohuai", "culture": "earth",
		"produces": ["iron", "rice"], "desc": "An Earth Kingdom mining village on the Ember Coast, under the Admiralty's 'protection'. Fire Nation settler families live in the new houses by the mine; the old families live everywhere else."},
	"navy_docks": {"name": "Ember Coast Docks", "type": "village", "faction": "fire_nation", "pos": Vector2(645, 640), "bound": "fire_navy_harbor", "culture": "earth",
		"produces": ["fish", "whale_oil"], "desc": "Earth Kingdom fishermen and Fire Nation settlers mend nets side by side and do not talk about the war."},
	"rocky_hamlet": {"name": "Boiling Lake Hamlet", "type": "village", "faction": "fire_nation", "pos": Vector2(330, 440), "bound": "boiling_rock", "culture": "fire",
		"produces": ["salt", "iron"], "desc": "Guards' families live here, close to the steaming waters of the Boiling Rock."},

	# Earth Kingdom
	"ba_sing_se": {"name": "Ba Sing Se", "type": "town", "faction": "earth_kingdom", "pos": Vector2(1290, 370), "owner": "hualing", "walls": 1.8, "culture": "earth",
		"produces": ["jade", "silk", "tea"], "desc": "The impenetrable city. Refugees and labourers crowd the Lower Ring, merchants and scholars the Middle, nobles the Upper. The Dai Li police the gates between them — and the thoughts within."},
	"gaoling": {"name": "Gaoling", "type": "town", "faction": "earth_kingdom", "pos": Vector2(1040, 745), "owner": "cheng_mei", "culture": "earth",
		"produces": ["silk", "tea", "herbs"], "desc": "A wealthy southern town of merchant houses, where the Cheng family's coin reaches every ledger and the Stone Pit draws crowds every night."},
	"outer_wall": {"name": "Outer Wall Gate", "type": "castle", "faction": "earth_kingdom", "pos": Vector2(1160, 395), "owner": "ba_tsai", "walls": 1.5, "culture": "earth",
		"produces": [], "desc": "A gate in the vast Outer Wall of Ba Sing Se, held by General Ba Tsai and a great many bad poems."},
	"fong_fortress": {"name": "Shanzhai Fortress", "type": "castle", "faction": "earth_kingdom", "pos": Vector2(980, 360), "owner": "lu_kang", "culture": "earth",
		"produces": [], "desc": "An Earth Kingdom fortress facing the rebel kingdom of Omashu, from which General Lu Kang plans his campaigns."},
	"serpent_fort": {"name": "Serpent's Pass Fort", "type": "castle", "faction": "earth_kingdom", "pos": Vector2(1205, 520), "owner": "tan_yue", "culture": "earth",
		"produces": [], "desc": "A watchpost above the narrow Serpent's Pass to Ba Sing Se. Refugees cross it daily; General Tan Yue counts every one."},
	"chin": {"name": "Chin Village", "type": "village", "faction": "earth_kingdom", "pos": Vector2(910, 720), "bound": "gaoling", "culture": "earth",
		"produces": ["cabbages", "rice"], "desc": "A village that still holds a yearly festival for the fall of Chin the Conqueror, centuries ago."},
	"gaipan": {"name": "Gaipan", "type": "village", "faction": "earth_kingdom", "pos": Vector2(1045, 430), "bound": "fong_fortress", "culture": "earth",
		"produces": ["rice", "iron"], "desc": "A small valley town below a great dam, quartering more of Lu Kang's soldiers than it can feed."},
	"full_moon_bay": {"name": "Full Moon Bay", "type": "village", "faction": "earth_kingdom", "pos": Vector2(1220, 455), "bound": "outer_wall", "culture": "earth",
		"produces": ["fish", "salt"], "desc": "A hidden harbour where refugees board ferries to Ba Sing Se. The pirate queen Old Mother Shiyo anchors offshore and takes a toll."},
	"misty_palms": {"name": "Misty Palms Oasis", "type": "village", "faction": "earth_kingdom", "pos": Vector2(1075, 560), "bound": "serpent_fort", "culture": "earth",
		"produces": ["spices", "salt"], "desc": "A fading oasis town at the edge of the Si Wong Desert. The Earth Kingdom closed its wells to the sandbender clans last summer."},
	"chameleon_bay": {"name": "Chameleon Bay", "type": "village", "faction": "earth_kingdom", "pos": Vector2(1470, 500), "bound": "ba_sing_se", "culture": "earth",
		"produces": ["fish", "whale_oil"], "desc": "A sheltered bay on the eastern coast, far from every war and grateful for it."},
	"kyoshi_island": {"name": "Kyoshi Island", "type": "village", "faction": "earth_kingdom", "pos": Vector2(770, 890), "bound": "gaoling", "culture": "kyoshi",
		"produces": ["fish", "silk"], "desc": "Avatar Kyoshi's homeland, defended by the Kyoshi Warriors. Neutral ground for every nation's envoys — and the only place a council of nations could meet. Watch out for the Unagi."},
	"foggy_swamp": {"name": "Foggy Swamp", "type": "village", "faction": "earth_kingdom", "pos": Vector2(965, 655), "bound": "gaoling", "culture": "swamp",
		"produces": ["herbs", "fish"], "desc": "A misty swamp where a forgotten tribe of waterbenders lives among the roots of a single great tree."},
	"agrarian_vale": {"name": "Jade Terraces", "type": "village", "faction": "earth_kingdom", "pos": Vector2(1340, 300), "bound": "ba_sing_se", "culture": "earth",
		"produces": ["tea", "rice"], "desc": "The farmland between Ba Sing Se's walls, terraced with tea. Its harvest goes to the Upper Ring first."},

	# Kingdom of Omashu
	"omashu": {"name": "Omashu", "type": "town", "faction": "omashu", "pos": Vector2(865, 470), "owner": "feng_tao", "walls": 1.6, "culture": "omashu",
		"produces": ["jade", "pottery"], "desc": "A mountain city of delivery chutes, giant stairways and loud public theatre. Since the Secession its banners are purple and its king gives a speech every morning."},
	"stonewatch": {"name": "Stonewatch Pass", "type": "castle", "faction": "omashu", "pos": Vector2(815, 430), "owner": "kuang", "walls": 1.4, "culture": "omashu",
		"produces": [], "desc": "A fortress cut into the mountain road to Omashu. General Kuang has turned it into the rebellion's anvil."},
	"senlin": {"name": "Senlin Village", "type": "village", "faction": "omashu", "pos": Vector2(800, 585), "bound": "omashu", "culture": "omashu",
		"produces": ["rice", "cabbages"], "desc": "A forest village that leaves offerings at the edge of the trees for a great black-and-white spirit. Nobody wants to find out what happens if they stop."},
	"makapu": {"name": "Makapu Village", "type": "village", "faction": "omashu", "pos": Vector2(925, 585), "bound": "omashu", "culture": "omashu",
		"produces": ["rice", "pottery"], "desc": "A village at the foot of a volcano, home to a long line of fortunetellers who read clouds and are right just often enough."},
	"bianfu": {"name": "Bianfu Hollow", "type": "village", "faction": "omashu", "pos": Vector2(870, 410), "bound": "stonewatch", "culture": "omashu",
		"produces": ["iron", "cabbages"], "desc": "Miners' terraces in a bat-haunted valley. Its people dug Omashu's first chutes and never let anyone forget it."},

	# Northern Water Tribe
	"agna_qela": {"name": "Agna Qel'a", "type": "town", "faction": "northern_water", "pos": Vector2(520, 100), "owner": "tulok", "walls": 1.5, "culture": "north",
		"produces": ["furs", "whale_oil", "seal_jerky"], "desc": "The capital of the Northern Water Tribe, carved from ice. At its heart lies the Spirit Oasis; in its healing huts, women learn the only bending the law allows them."},
	"frozen_harbor": {"name": "Frozen Harbour", "type": "castle", "faction": "northern_water", "pos": Vector2(410, 120), "owner": "iluq", "culture": "north",
		"produces": [], "desc": "An ice fortress guarding the western approaches to Agna Qel'a."},
	"ice_shelf": {"name": "Ice Shelf Camp", "type": "village", "faction": "northern_water", "pos": Vector2(455, 72), "bound": "frozen_harbor", "culture": "north",
		"produces": ["seal_jerky", "furs"], "desc": "Hunters' igloos on the edge of the northern ice."},
	"spirit_fishery": {"name": "Moon Fishery", "type": "village", "faction": "northern_water", "pos": Vector2(625, 95), "bound": "agna_qela", "culture": "north",
		"produces": ["fish", "sea_prunes"], "desc": "A fishing village whose people offer their first catch to the Moon Spirit."},

	# Southern Water Tribe
	"southern_tribe": {"name": "Wolf's Crown", "type": "town", "faction": "southern_water", "pos": Vector2(720, 1110), "owner": "siqiniq", "walls": 1.3, "culture": "south",
		"produces": ["furs", "seal_jerky", "sea_prunes"], "desc": "The great ice city of the South, ringed by canal-harbours. Its council hall is open to anyone who wants to argue, and most people do."},
	"hakodas_watch": {"name": "Whalebone Watch", "type": "castle", "faction": "southern_water", "pos": Vector2(860, 1095), "owner": "qannik", "culture": "south",
		"produces": [], "desc": "A raider harbour on the southern ice shelf, roofed with whale ribs. Qannik's canoes leave from here at night."},
	"wolf_cove": {"name": "Wolf Cove", "type": "village", "faction": "southern_water", "pos": Vector2(610, 1120), "bound": "southern_tribe", "culture": "south",
		"produces": ["fish", "furs"], "desc": "A sheltered cove where the tribe's canoes are hauled onto the ice."},
	"whaletail": {"name": "Whaletail Island", "type": "village", "faction": "southern_water", "pos": Vector2(930, 1050), "bound": "hakodas_watch", "culture": "south",
		"produces": ["whale_oil", "seal_jerky"], "desc": "A rocky island shaped like the tail of a whale."},

	# Air Temples (cannot be besieged; free healing and shelter)
	"southern_air_temple": {"name": "Southern Air Temple", "type": "temple", "faction": "air_nomads", "pos": Vector2(600, 990), "culture": "air", "abbot": "Abbot Dorje",
		"produces": ["tea"], "desc": "A temple of monks on the peaks of the Patola range. Sky bison graze its terraces, and refugees from three wars sleep in its courtyards."},
	"northern_air_temple": {"name": "Northern Air Temple", "type": "temple", "faction": "air_nomads", "pos": Vector2(915, 175), "culture": "air", "abbot": "Abbot Lhakpa",
		"produces": ["herbs"], "desc": "The highest of the temples, a monks' retreat of wind-chimes and cold stone. Its gliders can be seen for miles."},
	"eastern_air_temple": {"name": "Eastern Air Temple", "type": "temple", "faction": "air_nomads", "pos": Vector2(1470, 700), "culture": "air", "abbot": "Abbess Pema",
		"produces": ["tea", "herbs"], "desc": "A temple of nuns among mountain peaks, whose archives hold letters from every Avatar who ever visited."},
	"western_air_temple": {"name": "Western Air Temple", "type": "temple", "faction": "air_nomads", "pos": Vector2(520, 330), "culture": "air", "abbot": "Abbess Yeshe",
		"produces": ["herbs"], "desc": "A nuns' temple built upside-down beneath a cliff edge, hidden from anyone who does not already know where to look."},

	# Ruins and landmarks
	"wan_shi_tong": {"name": "Wan Shi Tong's Library", "type": "ruin", "faction": "neutral", "pos": Vector2(1145, 610), "culture": "air",
		"produces": [], "desc": "The tower of a great library peeks out from the desert sands. Its owl spirit trades knowledge for knowledge, and never at a loss."},
	"taku": {"name": "Ruins of Taku", "type": "ruin", "faction": "neutral", "pos": Vector2(790, 520), "culture": "earth",
		"produces": [], "desc": "A city emptied by an earthquake two centuries ago. Scavengers and pilgrims share the broken streets."},
	"red_lantern_den": {"name": "Red Lantern Den", "type": "ruin", "faction": "red_lanterns", "pos": Vector2(1010, 490), "culture": "earth",
		"produces": [], "desc": "Stilt houses hidden in a reed marsh by the river, lit by red paper lanterns. The Brotherhood watches every barge that passes."},
}

# Land shape: ellipses [cx, cy, rx, ry, angle_deg]. The terrain builder
# adds noise to the edges and polar ice caps.
var land_ellipses := [
	# Earth Kingdom mainland
	[1110, 470, 360, 230, 0], [1280, 350, 250, 190, -10], [930, 560, 220, 190, 15],
	[780, 520, 150, 120, 0], [1040, 740, 200, 115, 10], [1440, 600, 120, 170, 0],
	[960, 260, 190, 120, 0], [1160, 620, 160, 120, 0], [700, 600, 90, 80, 0],
	[1400, 260, 140, 110, 0],
	# Kyoshi Island
	[770, 890, 45, 35, 20],
	# Fire Nation
	[300, 520, 62, 125, 18], [370, 615, 110, 50, -18], [250, 612, 55, 38, 0],
	[452, 508, 38, 24, 10], [200, 470, 30, 22, 0], [300, 405, 34, 28, 0],
	[520, 330, 90, 65, -15], [330, 445, 30, 20, 0],
	# Patola mountains (Southern Air Temple)
	[600, 985, 65, 48, 0],
	# Whaletail
	[930, 1050, 40, 26, 0],
	# Northern ice shelf
	[520, 100, 190, 60, 0],
	# Southern ice shelf
	[760, 1110, 260, 70, 0],
]

# Regions that change the biome of land inside them [cx, cy, rx, ry, biome]
var biome_regions := [
	[1140, 590, 135, 85, "desert"],
	[965, 650, 55, 40, "swamp"],
	[330, 540, 200, 170, "volcanic"],
	[520, 330, 90, 65, "highland"],
	[600, 985, 70, 50, "mountain"],
]

# Bandit spawn points: [pos, troop pool, faction, label]
var bandit_spawns := [
	{"pos": Vector2(560, 720), "troops": ["pirate", "pirate", "pirate_captain"], "faction": "bandits", "name": "River Pirates"},
	{"pos": Vector2(1300, 640), "troops": ["pirate", "pirate", "pirate_captain"], "faction": "bandits", "name": "River Pirates"},
	{"pos": Vector2(720, 820), "troops": ["pirate", "pirate"], "faction": "bandits", "name": "Sea Raiders"},
	{"pos": Vector2(1000, 290), "troops": ["mountain_bandit"], "faction": "bandits", "name": "Mountain Bandits"},
	{"pos": Vector2(1380, 450), "troops": ["mountain_bandit"], "faction": "bandits", "name": "Mountain Bandits"},
	{"pos": Vector2(870, 640), "troops": ["mountain_bandit", "merc_archer"], "faction": "bandits", "name": "Highwaymen"},
	{"pos": Vector2(1150, 590), "troops": ["sand_raider", "sand_raider", "sand_chief"], "faction": "bandits", "name": "Sandbenders"},
	{"pos": Vector2(350, 480), "troops": ["fn_deserter", "mountain_bandit"], "faction": "bandits", "name": "Deserters"},
	{"pos": Vector2(420, 670), "troops": ["fn_deserter"], "faction": "bandits", "name": "Deserters"},
	{"pos": Vector2(1010, 490), "troops": ["red_lantern", "red_lantern", "red_lantern_elder"], "faction": "red_lanterns", "name": "Red Lantern Brothers"},
]

var rumors := [
	"Eleven years since the Avatar drowned, and still nobody will say whose fault it was. Everyone knows, of course. Everyone knows something different.",
	"Somewhere there's a child who's the new Avatar and doesn't know it. Five more years, the sages say. I hope there's a world left to hand them.",
	"The Fire Sages on Crescent Island say the sun will go dark again one of these years. Firebenders get very quiet around an eclipse.",
	"A tailed star was seen over the northern ice last winter. My grandmother says comets make fire burn hotter. My grandmother says a lot of things.",
	"Admiral Kuro feeds his sailors better than the Fire Lord feeds his own guards. Makes you wonder where the coin comes from.",
	"There's a chute-courier in Omashu carrying a letter everyone wants. Ba Sing Se has put a price on him. So has the Admiralty.",
	"The Red Lanterns robbed a tax barge on the river and the Lower Ring ate rice for a week. Depends who you ask whether that's a crime.",
	"Ba Sing Se's queen is nineteen. They say Secretary Wu signs everything she signs, and a few things she doesn't.",
	"The North won't help the South. Same as always. Chief Tulok's nephew is furious about it, I hear.",
	"In the Northern Tribe, a woman can heal a broken arm but not break one. Some of them have learned to do both anyway, quietly.",
	"The Air Nomads took in four hundred refugees at the Southern Temple this season. Monks don't fight, but they don't turn anyone away either.",
	"Old Mother Shiyo's pirates anchor off Full Moon Bay and charge every ferry a toll. She's been buying something from divers, too. Wreck salvage.",
	"Southern divers went down to the wreck of the Lantern last summer. They came up with something wrapped in oilcloth and wouldn't say what.",
	"A great library lies buried in the Si Wong Desert, guarded by an owl spirit who knows ten thousand things and wants to know ten thousand more.",
	"The sandbender clans are starving since Misty Palms closed its wells. Starving people raid. Then the garrison wonders why.",
	"Kyoshi Warriors paint their faces like the old Avatar and fight with steel fans. Captain Oyama refused the Earth Queen's summons three times. Politely.",
	"King Feng Tao gives a speech every morning from the palace steps. Omashu loves it. Ba Sing Se hates it. The pigeons are neutral.",
	"An old woman in green plays Pai Sho in the tea houses and never loses. She asks people about lotus tiles. Odd.",
	"Under a full moon, a waterbender can do things you would not believe. Under a lunar eclipse, they can't do anything at all.",
	"The Boiling Rock's warden teaches prisoners to read. Her guards call it soft. Fewer of her prisoners come back.",
]

# World events on a fixed schedule: political beats of the Quiet Years, not
# destiny. "campaign" makes a faction march on a target if still at war;
# "effect" triggers special handling in the world simulation.
var world_events := [
	{"day": 4, "text": "Admiral Kuro's fleet tightens its blockade of the Ember Coast. Earth Kingdom merchants are turned back at sea."},
	{"day": 18, "text": "General Lu Kang marches from Shanzhai Fortress to end the Omashu Secession by force.", "campaign": ["earth_kingdom", "stonewatch"], "leaders": ["lu_kang"]},
	{"day": 35, "text": "Southern raiders burn a Fire Navy supply convoy off Whaletail Island. Admiral Kuro swears revenge."},
	{"day": 55, "text": "In Caldera, Crown Princess Ryoko calls openly for peace talks. Admiral Kuro calls for more ships. The Fire Lord says nothing in public."},
	{"day": 80, "text": "The Admiralty lands an army on the southern coast and marches on Gaoling.", "campaign": ["fire_nation", "gaoling"], "leaders": ["kuro"]},
	{"day": 110, "text": "The Northern council debates sending warriors to aid the South. Commander Iluq argues for war; Chief Tulok listens.", "effect": "north_debate"},
	{"day": 140, "text": "Omashu's couriers carry rumours of a secret letter between Caldera and Omashu. Ba Sing Se doubles its patrols on every road."},
	{"day": 175, "text": "A hard winter is coming, the farmers say. Every army will be hungry before spring.", "effect": "hard_winter"},
]

# Fighters in Gaoling's Stone Pit, in the order you face them.
var arena_fighters := [
	{"name": "Pebble Wen", "bend": "earth", "power": 1.1, "hp": 90, "armor": 6, "skill": 45, "weapon": "fists", "prize": 120,
		"culture": "earth", "vlook": {"sex": "m", "accessory": "bandana"}},
	{"name": "The Ember Coast Kid", "bend": "fire", "power": 1.0, "hp": 100, "armor": 8, "skill": 55, "weapon": "fists", "prize": 200,
		"culture": "fire", "vlook": {"sex": "f", "hair": "Hair_BuzzedFemale"}},
	{"name": "The Granary", "bend": "earth", "power": 1.4, "hp": 200, "armor": 14, "skill": 40, "weapon": "fists", "prize": 350,
		"culture": "earth", "vlook": {"sex": "m", "hair": "Hair_Buzzed", "height": 1.08}},
	{"name": "Iron Lotus", "bend": "earth", "power": 1.8, "hp": 210, "armor": 18, "skill": 65, "weapon": "fists", "prize": 600,
		"culture": "earth", "vlook": {"sex": "f", "hair": "Hair_Buns"}},
	{"name": "The Quiet Mountain", "bend": "earth", "power": 2.6, "hp": 180, "armor": 20, "skill": 95, "weapon": "fists", "prize": 2000,
		"culture": "earth", "vlook": {"sex": "f", "hair": "Hair_Long", "hair_color": Color(0.62, 0.6, 0.58)}},
]

func _ready() -> void:
	_init_troops()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func troop(id: String) -> Dictionary:
	return troops.get(id, troops["ek_peasant"])

func item(id: String) -> Dictionary:
	return items.get(id, items["fists"])

## Upgrades available for a troop, hiding lines that story choices have not
## opened yet (e.g. the Moon Guard before the Law of the Two Paths changes).
func troop_upgrades(id: String) -> Array:
	return troop(id).upgrades.filter(func(u): return troop_unlocked(u))

func troop_unlocked(id: String) -> bool:
	var lk: String = troop(id).get("locked", "")
	return lk == "" or GS.flags.get(lk, false)

## Defensive multiplier for a settlement's walls (great cities hold longer).
func walls(sid: String) -> float:
	return float(settlements.get(sid, {}).get("walls", 1.0))

func troop_wage(id: String) -> int:
	var t := troop(id)
	var w: int = TIER_WAGE[clampi(t.tier, 0, 5)]
	if t.mount != "":
		w += 6
	if t.bend != "":
		w += 2 * t.tier
	return w

func troop_upgrade_cost(target_id: String) -> int:
	var t := troop(target_id)
	var c: int = TIER_UPGRADE_COST[clampi(t.tier, 0, 5)]
	if t.mount != "":
		c += 80
	return c

func troop_xp_needed(id: String) -> int:
	return TIER_XP[clampi(troop(id).tier, 0, 5)]

## Rough combat value used for auto-resolve and AI decisions.
func troop_power(id: String) -> float:
	var t := troop(id)
	var p := pow(float(t.tier) + 1.0, 1.4)
	if t.bend != "":
		p *= 1.15 + 0.2 * (t.bend_power - 1.0)
	if t.mount != "":
		p *= 1.3
	if t.ranged != "":
		p *= 1.1
	return p

func lord_power(lord_id: String) -> float:
	var l: Dictionary = lords[lord_id]
	return 6.0 + float(l.hp) / 25.0 + (l.power - 1.0) * 6.0

func settlement_ids_of_type(type: String) -> Array:
	var out := []
	for id in settlements:
		if settlements[id].type == type:
			out.append(id)
	return out

func element_color(element: String) -> Color:
	match element:
		"fire": return Color(1.0, 0.45, 0.1)
		"blue_fire": return Color(0.3, 0.55, 1.0)
		"earth": return Color(0.45, 0.35, 0.22)
		"water": return Color(0.35, 0.65, 1.0)
		"air": return Color(0.9, 0.95, 1.0)
		"sand": return Color(0.85, 0.75, 0.5)
	return Color.WHITE

func element_name(element: String) -> String:
	match element:
		"fire": return "Firebending"
		"blue_fire": return "Blue Firebending"
		"earth": return "Earthbending"
		"water": return "Waterbending"
		"air": return "Airbending"
		"sand": return "Sandbending"
	return "None"
