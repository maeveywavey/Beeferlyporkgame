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
		"trim": Color(0.95, 0.75, 0.2), "culture": "fire", "king": "ozai", "capital": "caldera",
		"desc": "The aggressor of the Hundred Year War. Its armies are disciplined and numerous, and its firebenders draw their strength from the sun.",
	},
	"earth_kingdom": {
		"name": "Earth Kingdom", "short": "Earth Kingdom", "color": Color(0.24, 0.55, 0.22),
		"trim": Color(0.85, 0.75, 0.35), "culture": "earth", "king": "kuei", "capital": "ba_sing_se",
		"desc": "The largest nation in the world, ruled from the impenetrable city of Ba Sing Se. Its earthbenders are stubborn and strong.",
	},
	"northern_water": {
		"name": "Northern Water Tribe", "short": "North Water", "color": Color(0.2, 0.45, 0.8),
		"trim": Color(0.9, 0.95, 1.0), "culture": "north", "king": "arnook", "capital": "agna_qela",
		"desc": "A proud polar nation behind great walls of ice. Its waterbenders grow mighty under the moon.",
	},
	"southern_water": {
		"name": "Southern Water Tribe", "short": "South Water", "color": Color(0.15, 0.32, 0.62),
		"trim": Color(0.85, 0.85, 0.9), "culture": "south", "king": "hakoda", "capital": "southern_tribe",
		"desc": "Raided for decades by the Fire Nation, its benders are gone. Its warriors fight with club, spear and boomerang.",
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
	"freedom_fighters": {
		"name": "Freedom Fighters", "short": "Freedom Fighters", "color": Color(0.45, 0.35, 0.15),
		"trim": Color(0.75, 0.6, 0.3), "culture": "earth", "king": "", "capital": "",
		"desc": "Jet's band of orphans hiding in the forests. They hunt the Fire Nation without mercy.",
	},
	"neutral": {
		"name": "Neutral", "short": "Neutral", "color": Color(0.8, 0.8, 0.8),
		"trim": Color(1, 1, 1), "culture": "air", "king": "", "capital": "",
		"desc": "",
	},
	"team_avatar": {
		"name": "Team Avatar", "short": "Team Avatar", "color": Color(0.95, 0.6, 0.15),
		"trim": Color(0.4, 0.75, 0.95), "culture": "air", "king": "", "capital": "",
		"desc": "The Avatar and his friends.",
	},
}

# Factions that take part in diplomacy (wars, fiefs, lords).
const KINGDOMS := ["fire_nation", "earth_kingdom", "northern_water", "southern_water"]

# Culture -> the tier 1 troop a village or town of that culture offers.
var culture_recruit := {
	"fire": "fn_conscript", "earth": "ek_peasant", "north": "nwt_hunter",
	"south": "swt_villager", "kyoshi": "ky_initiate", "swamp": "sw_swamper",
	"air": "ek_peasant",
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
		"bend_power": 1.0, "armor": 8, "upgrades": ["nwt_waterbender", "nwt_healer"],
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
		"upgrades": ["swt_warrior"], "look": {"body": Color(0.4, 0.48, 0.62), "trim": swt_trim, "helmet": "parka"}})
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
	_t("freedom_fighter", "Freedom Fighter", "earth", 2, {"weapon": "jian", "ranged": "short_bow",
		"skill": 55, "upgrades": ["freedom_veteran"],
		"look": {"body": Color(0.45, 0.35, 0.2), "trim": Color(0.25, 0.3, 0.15), "helmet": "none"}})
	_t("freedom_veteran", "Freedom Fighter Veteran", "earth", 3, {"weapon": "hook_swords", "skill": 75,
		"look": {"body": Color(0.4, 0.3, 0.15), "trim": Color(0.6, 0.15, 0.1), "helmet": "none"}})
	_t("merc_swordsman", "Mercenary Swordsman", "earth", 3, {"weapon": "dao", "shield": true,
		"look": {"body": Color(0.45, 0.42, 0.38), "trim": Color(0.25, 0.25, 0.25), "helmet": "ek_hat"}})
	_t("merc_archer", "Mercenary Archer", "earth", 2, {"weapon": "knife", "ranged": "short_bow",
		"look": {"body": Color(0.5, 0.45, 0.35), "trim": Color(0.3, 0.25, 0.2), "helmet": "straw_hat"}})
	_t("rough_rhino", "Rough Rhino", "fire", 4, {"weapon": "guan_dao", "mount": "komodo_rhino",
		"hp": 80, "armor": 28, "skill": 80,
		"look": {"body": Color(0.3, 0.25, 0.2), "trim": Color(0.6, 0.15, 0.1), "helmet": "fn_cap"}})

	# Team Avatar (never recruitable, fight only when attacked)
	_t("aang", "Aang", "air", 5, {"weapon": "staff", "bend": "air", "bend_power": 2.6, "hp": 160,
		"armor": 16, "skill": 95, "hero": true,
		"look": {"body": Color(0.95, 0.6, 0.15), "trim": Color(0.95, 0.85, 0.3), "helmet": "arrow"}})
	_t("katara", "Katara", "south", 5, {"weapon": "fists", "bend": "water", "bend_power": 2.2, "hp": 130,
		"armor": 12, "skill": 90, "hero": true, "healer": true,
		"look": {"body": Color(0.25, 0.42, 0.72), "trim": Color(0.9, 0.9, 0.9), "helmet": "none"}})
	_t("sokka", "Sokka", "south", 5, {"weapon": "space_sword", "ranged": "boomerang", "hp": 130,
		"armor": 18, "skill": 85, "hero": true,
		"look": {"body": Color(0.22, 0.35, 0.62), "trim": Color(0.9, 0.9, 0.9), "helmet": "wolf"}})
	_t("toph", "Toph Beifong", "earth", 5, {"weapon": "fists", "bend": "earth", "bend_power": 2.5,
		"hp": 140, "armor": 22, "skill": 95, "hero": true,
		"look": {"body": Color(0.3, 0.55, 0.25), "trim": Color(0.85, 0.8, 0.5), "helmet": "none"}})

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
	"space_sword": {"name": "Meteorite Sword", "slot": "weapon", "dmg": 34, "reach": 1.7, "speed": 1.15, "dtype": "cut", "price": 6000, "model": "space_sword"},
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
}

# ---------------------------------------------------------------------------
# Trade goods
# ---------------------------------------------------------------------------
var goods := {
	"rice": {"name": "Rice", "price": 22, "food": true},
	"fish": {"name": "Smoked Fish", "price": 20, "food": true},
	"cabbages": {"name": "Cabbages", "price": 12, "food": true},
	"seal_jerky": {"name": "Seal Jerky", "price": 32, "food": true},
	"fire_flakes": {"name": "Fire Flakes", "price": 28, "food": true},
	"sea_prunes": {"name": "Stewed Sea Prunes", "price": 18, "food": true},
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
# bend: element, power: bending multiplier, weapon: item, troops: starting size
var lords := {
	# Fire Nation
	"ozai": {"name": "Fire Lord Ozai", "faction": "fire_nation", "bend": "fire", "power": 3.0, "weapon": "fists", "hp": 220, "troops": 120, "home": "caldera", "king": true, "aggression": 0.4,
		"line": "You stand before the Fire Lord. Speak quickly, or burn."},
	"azula": {"name": "Princess Azula", "faction": "fire_nation", "bend": "blue_fire", "power": 2.7, "weapon": "fists", "hp": 180, "troops": 70, "home": "caldera", "aggression": 0.9,
		"line": "Almost isn't good enough. What do you want?"},
	"zhao": {"name": "Commander Zhao", "faction": "fire_nation", "bend": "fire", "power": 1.8, "weapon": "fists", "hp": 160, "troops": 80, "home": "fire_navy_harbor", "aggression": 0.85,
		"line": "I will be remembered as the one who conquered the Water Tribes. And you are?"},
	"zuko": {"name": "Prince Zuko", "faction": "fire_nation", "bend": "fire", "power": 1.9, "weapon": "dual_dao", "hp": 170, "troops": 18, "home": "caldera", "aggression": 0.7, "special": "hunt_avatar",
		"line": "I must capture the Avatar to restore my honour! Have you seen him?"},
	"iroh": {"name": "General Iroh", "faction": "fire_nation", "bend": "fire", "power": 2.8, "weapon": "fists", "hp": 200, "troops": 30, "home": "caldera", "aggression": 0.2,
		"line": "Sometimes life is like this dark tunnel. Would you care for some tea?"},
	"qin": {"name": "War Minister Qin", "faction": "fire_nation", "bend": "", "power": 1.0, "weapon": "dao", "hp": 120, "troops": 90, "home": "pohuai", "aggression": 0.6,
		"line": "The war machine needs iron and men. Do you bring either?"},
	"bujing": {"name": "General Bujing", "faction": "fire_nation", "bend": "fire", "power": 1.5, "weapon": "dao", "hp": 150, "troops": 90, "home": "fire_fountain", "aggression": 0.75,
		"line": "Every soldier is a resource. Spend them wisely, I say. Or don't."},
	"chan": {"name": "Admiral Chan", "faction": "fire_nation", "bend": "fire", "power": 1.3, "weapon": "dao", "hp": 140, "troops": 70, "home": "ember_island", "aggression": 0.5,
		"line": "Make it quick. I have a beach house to tend to."},
	"warden": {"name": "The Warden", "faction": "fire_nation", "bend": "", "power": 1.0, "weapon": "dao", "hp": 130, "troops": 60, "home": "boiling_rock", "aggression": 0.3,
		"line": "Nobody has ever escaped the Boiling Rock. Remember that."},
	# Earth Kingdom
	"kuei": {"name": "Earth King Kuei", "faction": "earth_kingdom", "bend": "", "power": 1.0, "weapon": "staff", "hp": 90, "troops": 110, "home": "ba_sing_se", "king": true, "aggression": 0.3,
		"line": "Oh! A visitor! Bosco and I so rarely meet anyone from outside the palace."},
	"long_feng": {"name": "Long Feng", "faction": "earth_kingdom", "bend": "earth", "power": 2.0, "weapon": "fists", "hp": 160, "troops": 80, "home": "ba_sing_se", "aggression": 0.4,
		"line": "There is no war within the walls. Here we are safe. Here we are free."},
	"bumi": {"name": "King Bumi", "faction": "earth_kingdom", "bend": "earth", "power": 2.9, "weapon": "fists", "hp": 210, "troops": 90, "home": "omashu", "aggression": 0.6,
		"line": "Lettuce leaf? Ha! You should see your face. What brings you to Omashu?"},
	"fong": {"name": "General Fong", "faction": "earth_kingdom", "bend": "earth", "power": 1.5, "weapon": "dao", "hp": 150, "troops": 90, "home": "fong_fortress", "aggression": 0.7,
		"line": "We need a weapon that can end this war. Are you that weapon?"},
	"how": {"name": "General How", "faction": "earth_kingdom", "bend": "", "power": 1.0, "weapon": "guan_dao", "hp": 150, "troops": 80, "home": "outer_wall", "aggression": 0.5,
		"line": "The Council of Five has much to discuss. Be brief."},
	"sung": {"name": "General Sung", "faction": "earth_kingdom", "bend": "earth", "power": 1.4, "weapon": "dao", "hp": 140, "troops": 75, "home": "serpent_fort", "aggression": 0.55,
		"line": "The Serpent's Pass is under my watch. Speak your business."},
	"lao": {"name": "Lao Beifong", "faction": "earth_kingdom", "bend": "", "power": 1.0, "weapon": "jian", "hp": 100, "troops": 60, "home": "gaoling", "aggression": 0.2,
		"line": "The Beifong family is the most respected in Gaoling. Mind your manners."},
	"suki": {"name": "Suki", "faction": "earth_kingdom", "bend": "", "power": 1.0, "weapon": "kyoshi_fans", "hp": 150, "troops": 40, "home": "gaoling", "aggression": 0.6, "culture": "kyoshi",
		"line": "The Kyoshi Warriors protect those who cannot protect themselves."},
	# Northern Water Tribe
	"arnook": {"name": "Chief Arnook", "faction": "northern_water", "bend": "", "power": 1.0, "weapon": "spear", "hp": 150, "troops": 100, "home": "agna_qela", "king": true, "aggression": 0.4,
		"line": "Welcome to the Northern Water Tribe. Our walls have stood for centuries."},
	"pakku": {"name": "Master Pakku", "faction": "northern_water", "bend": "water", "power": 2.6, "weapon": "fists", "hp": 180, "troops": 70, "home": "agna_qela", "aggression": 0.5,
		"line": "Hmph. You are not here to ask me for lessons, I hope."},
	"hahn": {"name": "Hahn", "faction": "northern_water", "bend": "", "power": 1.0, "weapon": "spear", "hp": 120, "troops": 50, "home": "frozen_harbor", "aggression": 0.8,
		"line": "I'm going to be a hero. Did you hear about my engagement?"},
	"sangok": {"name": "Sangok", "faction": "northern_water", "bend": "water", "power": 1.4, "weapon": "fists", "hp": 130, "troops": 55, "home": "frozen_harbor", "aggression": 0.6,
		"line": "Master Pakku's students do not lose."},
	# Southern Water Tribe
	"hakoda": {"name": "Chief Hakoda", "faction": "southern_water", "bend": "", "power": 1.0, "weapon": "war_club", "hp": 170, "troops": 70, "home": "southern_tribe", "king": true, "aggression": 0.6,
		"line": "The warriors of the South fight with what they have. And they fight well."},
	"bato": {"name": "Bato", "faction": "southern_water", "bend": "", "power": 1.0, "weapon": "spear", "hp": 140, "troops": 50, "home": "hakodas_watch", "aggression": 0.5,
		"line": "Hakoda trusts me with his ships. Can I trust you?"},
	"kanna": {"name": "Kanna", "faction": "southern_water", "bend": "", "power": 1.0, "weapon": "staff", "hp": 80, "troops": 30, "home": "southern_tribe", "aggression": 0.1,
		"line": "Gran Gran has seen many winters. Sit, and have some stewed sea prunes."},
}

# ---------------------------------------------------------------------------
# Companions (heroes found in taverns)
# ---------------------------------------------------------------------------
var companions := {
	"haru": {"name": "Haru", "bend": "earth", "power": 1.4, "weapon": "fists", "hp": 110, "armor": 12, "skill": 70, "cost": 400,
		"bonus": {"trainer": 2}, "look": {"body": Color(0.35, 0.45, 0.25), "trim": Color(0.5, 0.4, 0.25), "helmet": "none"},
		"pitch": "My father was taken by the Fire Nation for earthbending. Let me fight beside you."},
	"jet": {"name": "Jet", "bend": "", "power": 1.0, "weapon": "hook_swords", "hp": 120, "armor": 12, "skill": 85, "cost": 700,
		"bonus": {"tactics": 2}, "look": {"body": Color(0.45, 0.3, 0.15), "trim": Color(0.6, 0.15, 0.1), "helmet": "none"},
		"pitch": "The Fire Nation took everything from me. I'll follow anyone who fights them."},
	"longshot": {"name": "Longshot", "bend": "", "power": 1.0, "weapon": "knife", "ranged": "yuyan_bow", "hp": 100, "armor": 8, "skill": 95, "cost": 600,
		"bonus": {"pathfinding": 1}, "look": {"body": Color(0.4, 0.35, 0.2), "trim": Color(0.3, 0.3, 0.2), "helmet": "straw_hat"},
		"pitch": "..."},
	"smellerbee": {"name": "Smellerbee", "bend": "", "power": 1.0, "weapon": "knife", "ranged": "throwing_knives", "hp": 95, "armor": 8, "skill": 80, "cost": 450,
		"bonus": {"pathfinding": 2}, "look": {"body": Color(0.45, 0.4, 0.25), "trim": Color(0.6, 0.2, 0.15), "helmet": "none"},
		"pitch": "I'm a girl, if you were wondering. I know the forest paths better than anyone."},
	"song": {"name": "Song", "bend": "", "power": 1.0, "weapon": "staff", "hp": 80, "armor": 4, "skill": 40, "cost": 350, "healer": true,
		"bonus": {"healing": 4}, "look": {"body": Color(0.75, 0.6, 0.5), "trim": Color(0.5, 0.3, 0.3), "helmet": "none"},
		"pitch": "My mother and I tend to the wounded. Your soldiers will need a healer."},
	"june": {"name": "June", "bend": "", "power": 1.0, "weapon": "jian", "mount": "komodo_rhino", "hp": 130, "armor": 14, "skill": 85, "cost": 1200,
		"bonus": {"tracking": 2, "pathfinding": 1}, "look": {"body": Color(0.25, 0.15, 0.2), "trim": Color(0.5, 0.1, 0.15), "helmet": "none"},
		"pitch": "I'm a bounty hunter. Pay me well and I'll find anyone, anywhere."},
	"pipsqueak": {"name": "Pipsqueak", "bend": "", "power": 1.0, "weapon": "war_club", "hp": 170, "armor": 14, "skill": 55, "cost": 500,
		"bonus": {"ironflesh": 2}, "look": {"body": Color(0.45, 0.35, 0.2), "trim": Color(0.25, 0.25, 0.2), "helmet": "none"},
		"pitch": "Smellerbee says I'm good at carrying things. And hitting things."},
	"chong": {"name": "Chong", "bend": "", "power": 1.0, "weapon": "staff", "hp": 85, "armor": 3, "skill": 30, "cost": 200,
		"bonus": {"leadership": 2}, "look": {"body": Color(0.7, 0.45, 0.6), "trim": Color(0.4, 0.6, 0.4), "helmet": "none"},
		"pitch": "Secret tunnel! Secret tunnel! Through the mountains... want me to sing for your troops?"},
	"ty_lee": {"name": "Ty Lee", "bend": "", "power": 1.0, "weapon": "fists", "hp": 100, "armor": 6, "skill": 95, "cost": 900, "chi_blocker": true,
		"bonus": {"athletics": 2}, "look": {"body": Color(0.9, 0.5, 0.55), "trim": Color(0.6, 0.3, 0.35), "helmet": "none"},
		"pitch": "Your aura is so pink! Can I join? I'm really good at blocking chi."},
}

# ---------------------------------------------------------------------------
# Settlements
# ---------------------------------------------------------------------------
# type: town | castle | village | ruin
var settlements := {
	# Fire Nation
	"caldera": {"name": "Caldera City", "type": "town", "faction": "fire_nation", "pos": Vector2(318, 560), "owner": "ozai", "culture": "fire",
		"produces": ["iron", "silk", "pottery"], "desc": "The Fire Nation capital, built inside the crater of a dormant volcano. The Royal Palace looms over the city."},
	"fire_fountain": {"name": "Fire Fountain City", "type": "town", "faction": "fire_nation", "pos": Vector2(392, 618), "owner": "bujing", "culture": "fire",
		"produces": ["spices", "pottery"], "desc": "A bustling port city crowned by a fire-breathing statue of the Fire Lord."},
	"ember_island": {"name": "Ember Island", "type": "town", "faction": "fire_nation", "pos": Vector2(452, 505), "owner": "chan", "culture": "fire",
		"produces": ["fish", "silk"], "desc": "A resort island for the Fire Nation elite, famous for its beaches and its terrible theatre."},
	"boiling_rock": {"name": "The Boiling Rock", "type": "castle", "faction": "fire_nation", "pos": Vector2(292, 405), "owner": "warden", "culture": "fire",
		"produces": [], "desc": "The Fire Nation's highest-security prison, set on an island in a boiling lake."},
	"pohuai": {"name": "Pohuai Stronghold", "type": "castle", "faction": "fire_nation", "pos": Vector2(705, 455), "owner": "qin", "culture": "fire",
		"produces": [], "desc": "A Fire Nation fortress in the occupied Earth Kingdom, home of the Yuyan archers."},
	"fire_navy_harbor": {"name": "Fire Navy Harbour", "type": "castle", "faction": "fire_nation", "pos": Vector2(618, 585), "owner": "zhao", "culture": "fire",
		"produces": [], "desc": "A Fire Nation naval base on the western Earth Kingdom coast, bristling with warships."},
	"shu_jing": {"name": "Shu Jing", "type": "village", "faction": "fire_nation", "pos": Vector2(262, 612), "bound": "caldera", "culture": "fire",
		"produces": ["rice", "fire_flakes"], "desc": "A quiet farming village in the Fire Nation heartland."},
	"crescent_island": {"name": "Crescent Island", "type": "village", "faction": "fire_nation", "pos": Vector2(200, 470), "bound": "caldera", "culture": "fire",
		"produces": ["fish", "salt"], "desc": "A volcanic island home to an ancient Fire Temple."},
	"jang_hui": {"name": "Jang Hui", "type": "village", "faction": "fire_nation", "pos": Vector2(398, 645), "bound": "fire_fountain", "culture": "fire",
		"produces": ["fish", "rice"], "desc": "A floating village on a river poisoned by a Fire Nation factory."},
	"ember_shore": {"name": "Ember Shore", "type": "village", "faction": "fire_nation", "pos": Vector2(470, 520), "bound": "ember_island", "culture": "fire",
		"produces": ["fire_flakes", "salt"], "desc": "Fishing huts and beach houses along the Ember Island shore."},
	"harus_village": {"name": "Haru's Village", "type": "village", "faction": "fire_nation", "pos": Vector2(745, 520), "bound": "pohuai", "culture": "earth",
		"produces": ["iron", "rice"], "desc": "An Earth Kingdom mining village under Fire Nation occupation."},
	"navy_docks": {"name": "Coastal Docks", "type": "village", "faction": "fire_nation", "pos": Vector2(645, 640), "bound": "fire_navy_harbor", "culture": "earth",
		"produces": ["fish", "whale_oil"], "desc": "Earth Kingdom fishermen forced to supply the Fire Navy."},
	"rocky_hamlet": {"name": "Boiling Lake Hamlet", "type": "village", "faction": "fire_nation", "pos": Vector2(330, 440), "bound": "boiling_rock", "culture": "fire",
		"produces": ["salt", "iron"], "desc": "Guards' families live here, close to the steaming waters of the Boiling Rock."},

	# Earth Kingdom
	"ba_sing_se": {"name": "Ba Sing Se", "type": "town", "faction": "earth_kingdom", "pos": Vector2(1290, 370), "owner": "kuei", "culture": "earth",
		"produces": ["jade", "silk", "tea"], "desc": "The impenetrable city. Its walls have never fallen, and the Dai Li make sure there is no war within them."},
	"omashu": {"name": "Omashu", "type": "town", "faction": "earth_kingdom", "pos": Vector2(865, 470), "owner": "bumi", "culture": "earth",
		"produces": ["jade", "pottery"], "desc": "A mountain city of chutes and ramps, ruled by its eccentric king Bumi."},
	"gaoling": {"name": "Gaoling", "type": "town", "faction": "earth_kingdom", "pos": Vector2(1040, 745), "owner": "lao", "culture": "earth",
		"produces": ["silk", "tea", "herbs"], "desc": "A wealthy southern town, home of the Beifong family and the Earth Rumble tournaments."},
	"outer_wall": {"name": "Outer Wall Gate", "type": "castle", "faction": "earth_kingdom", "pos": Vector2(1160, 395), "owner": "how", "culture": "earth",
		"produces": [], "desc": "A gate in the vast Outer Wall of Ba Sing Se."},
	"fong_fortress": {"name": "General Fong's Fortress", "type": "castle", "faction": "earth_kingdom", "pos": Vector2(980, 360), "owner": "fong", "culture": "earth",
		"produces": [], "desc": "An Earth Kingdom base on the frontlines, commanded by the ambitious General Fong."},
	"serpent_fort": {"name": "Serpent's Pass Fort", "type": "castle", "faction": "earth_kingdom", "pos": Vector2(1205, 520), "owner": "sung", "culture": "earth",
		"produces": [], "desc": "A watchpost above the narrow Serpent's Pass leading to Ba Sing Se."},
	"senlin": {"name": "Senlin Village", "type": "village", "faction": "earth_kingdom", "pos": Vector2(800, 585), "bound": "omashu", "culture": "earth",
		"produces": ["rice", "cabbages"], "desc": "A village haunted, they say, by the spirit Hei Bai."},
	"makapu": {"name": "Makapu Village", "type": "village", "faction": "earth_kingdom", "pos": Vector2(925, 585), "bound": "omashu", "culture": "earth",
		"produces": ["rice", "pottery"], "desc": "A village at the foot of a volcano, home of Aunt Wu the fortuneteller."},
	"chin": {"name": "Chin Village", "type": "village", "faction": "earth_kingdom", "pos": Vector2(910, 720), "bound": "gaoling", "culture": "earth",
		"produces": ["cabbages", "rice"], "desc": "A village that celebrates the death of Avatar Kyoshi's old enemy, Chin the Conqueror."},
	"gaipan": {"name": "Gaipan", "type": "village", "faction": "earth_kingdom", "pos": Vector2(1045, 430), "bound": "fong_fortress", "culture": "earth",
		"produces": ["rice", "iron"], "desc": "A small valley town below a great dam."},
	"full_moon_bay": {"name": "Full Moon Bay", "type": "village", "faction": "earth_kingdom", "pos": Vector2(1220, 455), "bound": "outer_wall", "culture": "earth",
		"produces": ["fish", "salt"], "desc": "A hidden harbour where refugees board ferries to Ba Sing Se."},
	"misty_palms": {"name": "Misty Palms Oasis", "type": "village", "faction": "earth_kingdom", "pos": Vector2(1075, 560), "bound": "serpent_fort", "culture": "earth",
		"produces": ["spices", "salt"], "desc": "A fading oasis town at the edge of the Si Wong Desert."},
	"chameleon_bay": {"name": "Chameleon Bay", "type": "village", "faction": "earth_kingdom", "pos": Vector2(1470, 500), "bound": "ba_sing_se", "culture": "earth",
		"produces": ["fish", "whale_oil"], "desc": "A sheltered bay on the eastern coast."},
	"kyoshi_island": {"name": "Kyoshi Island", "type": "village", "faction": "earth_kingdom", "pos": Vector2(770, 890), "bound": "gaoling", "culture": "kyoshi",
		"produces": ["fish", "silk"], "desc": "Avatar Kyoshi's homeland, defended by the Kyoshi Warriors. Watch out for the Unagi."},
	"foggy_swamp": {"name": "Foggy Swamp", "type": "village", "faction": "earth_kingdom", "pos": Vector2(965, 655), "bound": "gaoling", "culture": "swamp",
		"produces": ["herbs", "fish"], "desc": "A misty swamp where a forgotten tribe of waterbenders lives among the roots of a single great tree."},
	"agrarian_vale": {"name": "Jade Terraces", "type": "village", "faction": "earth_kingdom", "pos": Vector2(1340, 300), "bound": "ba_sing_se", "culture": "earth",
		"produces": ["tea", "rice"], "desc": "The agrarian zone between Ba Sing Se's walls, terraced with tea fields."},

	# Northern Water Tribe
	"agna_qela": {"name": "Agna Qel'a", "type": "town", "faction": "northern_water", "pos": Vector2(520, 100), "owner": "arnook", "culture": "north",
		"produces": ["furs", "whale_oil", "seal_jerky"], "desc": "The capital of the Northern Water Tribe, carved from ice. At its heart lies the Spirit Oasis."},
	"frozen_harbor": {"name": "Frozen Harbour", "type": "castle", "faction": "northern_water", "pos": Vector2(410, 120), "owner": "hahn", "culture": "north",
		"produces": [], "desc": "An ice fortress guarding the western approaches to Agna Qel'a."},
	"ice_shelf": {"name": "Ice Shelf Camp", "type": "village", "faction": "northern_water", "pos": Vector2(455, 72), "bound": "frozen_harbor", "culture": "north",
		"produces": ["seal_jerky", "furs"], "desc": "Hunters' igloos on the edge of the northern ice."},
	"spirit_fishery": {"name": "Moon Fishery", "type": "village", "faction": "northern_water", "pos": Vector2(625, 95), "bound": "agna_qela", "culture": "north",
		"produces": ["fish", "sea_prunes"], "desc": "A fishing village whose people offer their first catch to the Moon Spirit."},

	# Southern Water Tribe
	"southern_tribe": {"name": "Southern Water Tribe", "type": "town", "faction": "southern_water", "pos": Vector2(720, 1110), "owner": "hakoda", "culture": "south",
		"produces": ["furs", "seal_jerky", "sea_prunes"], "desc": "Once a great city of ice, now a small village behind a snow wall. Its warriors are away fighting the war."},
	"hakodas_watch": {"name": "Hakoda's Watch", "type": "castle", "faction": "southern_water", "pos": Vector2(860, 1095), "owner": "bato", "culture": "south",
		"produces": [], "desc": "A lookout and boat shelter on the southern ice shelf."},
	"wolf_cove": {"name": "Wolf Cove", "type": "village", "faction": "southern_water", "pos": Vector2(610, 1120), "bound": "southern_tribe", "culture": "south",
		"produces": ["fish", "furs"], "desc": "A sheltered cove where the tribe's canoes are hauled onto the ice."},
	"whaletail": {"name": "Whaletail Island", "type": "village", "faction": "southern_water", "pos": Vector2(930, 1050), "bound": "hakodas_watch", "culture": "south",
		"produces": ["whale_oil", "seal_jerky"], "desc": "A rocky island shaped like the tail of a whale."},

	# Ruins and landmarks
	"southern_air_temple": {"name": "Southern Air Temple", "type": "ruin", "faction": "neutral", "pos": Vector2(600, 990), "culture": "air",
		"produces": [], "desc": "Abandoned for a hundred years since the Fire Nation's attack. The statues of past Avatars still stand inside."},
	"northern_air_temple": {"name": "Northern Air Temple", "type": "ruin", "faction": "neutral", "pos": Vector2(915, 175), "culture": "air",
		"produces": [], "desc": "A mountain temple now home to refugees who fly gliders built by the Mechanist."},
	"eastern_air_temple": {"name": "Eastern Air Temple", "type": "ruin", "faction": "neutral", "pos": Vector2(1470, 700), "culture": "air",
		"produces": [], "desc": "Once home to the air nuns. A guru is said to meditate here still."},
	"western_air_temple": {"name": "Western Air Temple", "type": "ruin", "faction": "neutral", "pos": Vector2(520, 330), "culture": "air",
		"produces": [], "desc": "Built upside-down beneath a cliff edge, hidden from all who do not know where to look."},
	"wan_shi_tong": {"name": "Wan Shi Tong's Library", "type": "ruin", "faction": "neutral", "pos": Vector2(1145, 610), "culture": "air",
		"produces": [], "desc": "The tower of a sunken library peeks out from the desert sands. Its owl spirit does not take kindly to humans."},
	"taku": {"name": "Ruins of Taku", "type": "ruin", "faction": "neutral", "pos": Vector2(790, 520), "culture": "earth",
		"produces": [], "desc": "A city destroyed early in the war. Only broken walls remain."},
	"jets_hideout": {"name": "Jet's Hideout", "type": "ruin", "faction": "freedom_fighters", "pos": Vector2(1010, 490), "culture": "earth",
		"produces": [], "desc": "Treehouses hidden high in the forest canopy. The Freedom Fighters watch every road."},
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
	{"pos": Vector2(1010, 490), "troops": ["freedom_fighter", "freedom_fighter", "freedom_veteran"], "faction": "freedom_fighters", "name": "Freedom Fighters"},
]

var rumors := [
	"They say an airbender was found frozen in an iceberg near the South Pole. An airbender! After a hundred years!",
	"A Fire Nation prince sails the world hunting the Avatar. Banished, they say, with a scar to remember his father by.",
	"Sozin's Comet returns at the end of summer. When it comes, the Fire Nation's firebenders will be unstoppable.",
	"The cabbage merchant in Omashu lost his whole cart again. My cabbages!",
	"There is no war in Ba Sing Se. Or so the Dai Li keep telling everyone who asks.",
	"Under a full moon, a waterbender can do things you would not believe.",
	"Some say there was a tribe of waterbenders in a swamp to the south. Nobody comes back to confirm it.",
	"The Blue Spirit freed the Avatar from Pohuai Stronghold single-handed. Nobody knows who he is.",
	"A great library lies buried in the Si Wong Desert, guarded by an owl spirit who knows ten thousand things.",
	"Earthbenders are being hauled off to prison rigs at sea. The Fire Nation fears what they can do.",
	"In Gaoling, a tiny blind girl has been beating every champion of Earth Rumble.",
	"On the Day of Black Sun the sun goes dark, and firebenders lose their power. Remember that if you must fight them.",
	"Kyoshi Warriors paint their faces like the old Avatar and fight with steel fans. Don't laugh at them.",
	"An old man who plays Pai Sho is the finest tea-maker in the world, I hear. Retired general, or so they say.",
	"The Rough Rhinos ride for gold. Colonel Mongke would sell his own mother for the right price.",
]

# Story beats from the original series. "campaign" forces a faction to march
# on a target; "effect" triggers special handling in the world simulation.
var story_events := [
	{"day": 6, "text": "News spreads from the South Pole: the Avatar has returned — and he is an airbender!"},
	{"day": 25, "text": "The Avatar was seen on Kyoshi Island, where the Kyoshi Warriors helped him escape Prince Zuko."},
	{"day": 45, "text": "Admiral Zhao has assembled a great armada. The Fire Navy sails for the North Pole!", "campaign": ["fire_nation", "agna_qela"], "leaders": ["zhao", "chan"]},
	{"day": 75, "text": "The Ocean Spirit rose against the Fire Navy at the North Pole! Fire Nation armies in the north have been shattered.", "effect": "ocean_spirit"},
	{"day": 110, "text": "Rumours say the Avatar has found an earthbending teacher: a blind girl from Gaoling."},
	{"day": 150, "text": "General Fong tried to force the Avatar State. The Avatar left his base in ruins.", "effect": "fong_ruins"},
	{"day": 175, "text": "Princess Azula has slipped into Ba Sing Se in disguise. The Dai Li whisper of a coup...", "campaign": ["fire_nation", "ba_sing_se"], "leaders": ["azula"]},
	{"day": 205, "text": "Prince Zuko has returned to the Fire Nation as a hero. Iroh languishes in prison."},
	{"day": 249, "text": "The invasion begins! The Water Tribes and Earth Kingdom rebels sail for the Fire Nation capital to strike on the Day of Black Sun.", "campaign": ["southern_water", "caldera"], "also": ["earth_kingdom"]},
	{"day": 272, "text": "The Avatar has defeated Fire Lord Ozai! Zuko is crowned Fire Lord and declares an end to the Hundred Year War.", "effect": "end_war"},
]

# Earth Rumble fighters in Gaoling's arena, in the order you face them.
var arena_fighters := [
	{"name": "The Gopher", "bend": "earth", "power": 1.1, "hp": 90, "armor": 6, "skill": 45, "weapon": "fists", "prize": 120,
		"look": {"body": Color(0.5, 0.4, 0.25), "trim": Color(0.3, 0.2, 0.1), "helmet": "bandana"}},
	{"name": "Fire Nation Man", "bend": "fire", "power": 1.0, "hp": 100, "armor": 8, "skill": 50, "weapon": "fists", "prize": 200,
		"look": {"body": Color(0.6, 0.15, 0.1), "trim": Color(0.2, 0.1, 0.1), "helmet": "fn_cap"}},
	{"name": "The Hippo", "bend": "earth", "power": 1.4, "hp": 200, "armor": 14, "skill": 40, "weapon": "fists", "prize": 350,
		"look": {"body": Color(0.45, 0.4, 0.35), "trim": Color(0.25, 0.25, 0.25), "helmet": "none"}},
	{"name": "The Boulder", "bend": "earth", "power": 1.8, "hp": 220, "armor": 18, "skill": 60, "weapon": "fists", "prize": 600,
		"look": {"body": Color(0.35, 0.3, 0.25), "trim": Color(0.6, 0.15, 0.1), "helmet": "none"}},
	{"name": "The Blind Bandit", "bend": "earth", "power": 2.6, "hp": 170, "armor": 20, "skill": 98, "weapon": "fists", "prize": 2000,
		"look": {"body": Color(0.3, 0.55, 0.25), "trim": Color(0.85, 0.8, 0.5), "helmet": "none"}},
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
