extends Node
## Static game content: factions, cultures, troops, lords, companions,
## settlements, trade goods and equipment. Nothing here changes at runtime;
## mutable state lives in GameState (autoload "GS").

const MAP_W := 1600.0
const MAP_H := 1200.0

# ---------------------------------------------------------------------------
# Factions
# ---------------------------------------------------------------------------
# region: where the faction belongs (fire, earth, water, air, outlaw); groups
#   the Factions window. kind: what sort of polity it is, as shown to the player.
# fealty: the faction it pays tribute to when the game begins ("" = none).
# peaceful: never at war with anyone. protected: other powers' AI will not
#   attack it unless led by someone reckless or overwhelmingly strong.
# head: the leader's name, for factions without a lord in Data.lords.
# Independent communities are generated from settlements with a "community"
# entry (see _init_communities), one faction per village.
var factions := {
	# --- The Fire Islands -------------------------------------------------
	"fire_nation": {
		"name": "Royal House of the Fire Lord", "short": "Royal House", "color": Color(0.78, 0.16, 0.12),
		"trim": Color(0.95, 0.75, 0.2), "culture": "fire", "king": "haoren", "capital": "caldera", "region": "fire", "kind": "Royal house",
		"desc": "The Fire Lord's own house: Caldera, the Boiling Lake, Crescent Island and, through its Admiralty, the Strait Isles. Its lands, ships and levies roughly equal those of every other clan put together, which is why the clans bow at court and why none of them bows any further. The title of Fire Lord commands the clans in ceremony; on their own islands they rule themselves. The Admiralty occupied the Strait Isles after three ruined harvests, and the Fire Lord has not yet decided whether to thank it.",
	},
	"clan_hiyori": {
		"name": "Hiyori Clan", "short": "Hiyori", "color": Color(0.62, 0.22, 0.32),
		"trim": Color(0.9, 0.8, 0.6), "culture": "fire", "king": "hiyori", "capital": "fire_fountain", "region": "fire", "kind": "Clan",
		"desc": "A merchant clan of the delta ports. The Hiyori own the tea houses where every rumour in the islands is sold, and sell most of them twice. They support the throne in public, because the throne is the largest buyer of what they know.",
	},
	"clan_ren": {
		"name": "Ren Clan", "short": "Ren", "color": Color(0.85, 0.42, 0.12),
		"trim": Color(0.3, 0.12, 0.08), "culture": "fire", "king": "ren_chiyo", "capital": "ember_island", "region": "fire", "kind": "Clan",
		"desc": "An old firebending clan of Ember Island, proud of its masters and short of money. Lady Chiyo keeps the clan's debts quiet and its prodigy, her son Daisuke, loud.",
	},
	"clan_kagari": {
		"name": "Kagari Clan", "short": "Kagari", "color": Color(0.45, 0.12, 0.1),
		"trim": Color(0.75, 0.75, 0.72), "culture": "fire", "king": "kagari_sosuke", "capital": "kagari_keep", "region": "fire", "kind": "Clan",
		"desc": "Lords of the western isle, where the salt pans are and the ships are built. The Kagari have married into the royal house twice and been refused a third time, and they keep a list.",
	},
	"clan_tsurugi": {
		"name": "Tsurugi Clan", "short": "Tsurugi", "color": Color(0.55, 0.32, 0.18),
		"trim": Color(0.92, 0.62, 0.3), "culture": "fire", "king": "tsurugi_hana", "capital": "tsurugi", "region": "fire", "kind": "Clan",
		"desc": "A clan of sword-smiths and shipwrights on the southern islands, nearest of all to the Sun Warriors' coast. They trade with the Sun Warriors in iron and keep the trade's terms to themselves.",
	},
	"clan_kurozan": {
		"name": "Kurozan Clan", "short": "Kurozan", "color": Color(0.28, 0.2, 0.22),
		"trim": Color(0.85, 0.3, 0.18), "culture": "fire", "king": "kurozan_isamu", "capital": "kurozan_hold", "region": "fire", "kind": "Clan",
		"desc": "A hard clan on a black-sand island north of the Boiling Lake. Its lords have opposed every Fire Lord for four generations, on principle, and have been right about it often enough to stay alive.",
	},
	"sun_warriors": {
		"name": "Sun Warriors", "short": "Sun Warriors", "color": Color(0.88, 0.62, 0.12),
		"trim": Color(0.2, 0.45, 0.42), "culture": "sun", "king": "huallpa", "capital": "sun_city", "region": "fire", "kind": "Reclusive people", "protected": true,
		"desc": "The oldest firebenders, who learned from the dragons and still live beside them. Their stepped city in the southwestern jungle keeps the Eternal Flame. They trade a little, travel less and want nothing from the islands but to be left alone. The clans leave them alone, as does the royal house: an army that marches on the Sun Warriors will meet their masters, their walls and the dragons, and every Fire Lord so far has decided the city is better as a neighbour.",
	},
	# --- The Earth continent ----------------------------------------------
	"earth_kingdom": {
		"name": "Earth Kingdom", "short": "Earth Kingdom", "color": Color(0.24, 0.55, 0.22),
		"trim": Color(0.85, 0.75, 0.35), "culture": "earth", "king": "hualing", "capital": "ba_sing_se", "region": "earth", "kind": "Kingdom",
		"desc": "The crown at Ba Sing Se, ruled by a nineteen-year-old queen and the regent who rules for her. The kingdom keeps its title and its claim to the whole continent, but rules directly only the walled heartland around the capital. Beyond it, cities and villages send tribute for the right to trade under the crown's seal and to call on its armies; many send nothing at all. It is at war with the Royal House at sea, with Omashu in the mountains and with a warlord in the northeast.",
	},
	"omashu": {
		"name": "Kingdom of Omashu", "short": "Omashu", "color": Color(0.45, 0.6, 0.2),
		"trim": Color(0.75, 0.55, 0.85), "culture": "omashu", "king": "feng_tao", "capital": "omashu", "region": "earth", "kind": "Kingdom",
		"desc": "A mountain city that stopped sending grain to Ba Sing Se while its own people went hungry, and declared itself free. Its king is loud, its couriers are heroes, and the villages in its valleys now pay their tribute to Omashu instead.",
	},
	"house_cheng": {
		"name": "House Cheng of Gaoling", "short": "Gaoling", "color": Color(0.55, 0.62, 0.3),
		"trim": Color(0.95, 0.85, 0.5), "culture": "earth", "king": "cheng_mei", "capital": "gaoling", "region": "earth", "kind": "Merchant city", "fealty": "earth_kingdom",
		"desc": "Gaoling rules itself through its merchant houses, the Cheng above all, and pays the crown a tribute that buys the crown's seal on its goods and its silence about everything else.",
	},
	"tide_wardens": {
		"name": "Tide Wardens of Hamakaze", "short": "Tide Wardens", "color": Color(0.18, 0.24, 0.45),
		"trim": Color(0.65, 0.32, 0.2), "culture": "hamakaze", "king": "oyama", "capital": "hamakaze", "region": "earth", "kind": "Peninsula guard", "fealty": "earth_kingdom",
		"desc": "The order that guards the Hamakaze peninsula. It sends Ba Sing Se a token tribute and refuses every summons to march. Envoys of every nation meet on its shore because the Wardens are the one force nobody suspects of conquest.",
	},
	"beishan": {
		"name": "Beishan March", "short": "Beishan", "color": Color(0.42, 0.45, 0.28),
		"trim": Color(0.82, 0.8, 0.75), "culture": "earth", "king": "teng_yao", "capital": "beishan_hold", "region": "earth", "kind": "March lordship",
		"desc": "A border lordship in the northern hills whose marquis stopped paying tribute when the crown stopped sending soldiers. He calls himself loyal and acts free, and both Ba Sing Se and Omashu court him.",
	},
	"haiyan": {
		"name": "Duchy of Haiyan", "short": "Haiyan", "color": Color(0.3, 0.5, 0.45),
		"trim": Color(0.9, 0.9, 0.85), "culture": "earth", "king": "pao_ruyi", "capital": "haiyan", "region": "earth", "kind": "Duchy", "fealty": "earth_kingdom",
		"desc": "The eastern coast, rich in fish, salt and grievances. The Pao dukes pay Ba Sing Se its tribute on the last possible day, every year, in the smallest coins they can find.",
	},
	"lingtai": {
		"name": "Lingtai Warlord", "short": "Lingtai", "color": Color(0.5, 0.35, 0.2),
		"trim": Color(0.2, 0.18, 0.15), "culture": "earth", "king": "gu_bao", "capital": "lingtai", "region": "earth", "kind": "Warlord",
		"desc": "A former Earth Kingdom garrison commander who kept his fort, his men and the taxes when the crown fell behind on his pay. He raids the crown's tea terraces and calls it collecting arrears.",
	},
	# --- The Water Tribes ---------------------------------------------------
	"northern_water": {
		"name": "Northern Water Tribe", "short": "North Water", "color": Color(0.2, 0.45, 0.8),
		"trim": Color(0.9, 0.95, 1.0), "culture": "north", "king": "tulok", "capital": "agna_qela", "region": "water", "kind": "Tribe",
		"desc": "A proud polar city behind great walls of ice, neutral and divided over whether to help the South. By old law its women may learn waterbending only as healing. The clans of the far ice do not answer to its chief.",
	},
	"aqsarniit": {
		"name": "Aqsarniit Clans", "short": "Aqsarniit", "color": Color(0.35, 0.55, 0.7),
		"trim": Color(0.95, 0.9, 0.7), "culture": "north", "king": "ataneq", "capital": "aurora_hall", "region": "water", "kind": "Clan league",
		"desc": "Hunting clans of the eastern ice who left Agna Qel'a three generations ago over the Law of the Two Paths and never came back. Their women fight; their men heal if they are good at it. They trade furs with the North and insults with its council.",
	},
	"southern_water": {
		"name": "Southern Tribe of Wolf's Crown", "short": "Wolf's Crown", "color": Color(0.15, 0.32, 0.62),
		"trim": Color(0.85, 0.85, 0.9), "culture": "south", "king": "siqiniq", "capital": "southern_tribe", "region": "water", "kind": "Tribe",
		"desc": "The largest of the southern tribes: a city of ice and canals whose council votes on war. It speaks for the South when the South agrees, which is rarely.",
	},
	"whalebone": {
		"name": "Whalebone Raiders", "short": "Whalebone", "color": Color(0.32, 0.36, 0.42),
		"trim": Color(0.9, 0.88, 0.8), "culture": "south", "king": "qannik", "capital": "hakodas_watch", "region": "water", "kind": "Raider band",
		"desc": "Canoe crews of the southern ice shelf who answer to Raider-Captain Qannik and to no council. They sink Fire Navy supply ships, and sometimes ships that only look like them.",
	},
	"kanguq": {
		"name": "Kanguq Tribe", "short": "Kanguq", "color": Color(0.25, 0.42, 0.55),
		"trim": Color(0.95, 0.95, 0.95), "culture": "south", "king": "nuvuk", "capital": "kanguq_hall", "region": "water", "kind": "Tribe",
		"desc": "A small tribe of the western ice, named for the snow geese that nest on its shore. It stays out of Wolf's Crown's council and out of its wars, and keeps the best sled-dogs in the South.",
	},
	"pearl_isles": {
		"name": "Pearl Isles League", "short": "Pearl Isles", "color": Color(0.3, 0.62, 0.62),
		"trim": Color(0.95, 0.92, 0.85), "culture": "south", "king": "kallik", "capital": "tidehall", "region": "water", "kind": "Island league",
		"desc": "A league of waterbending island tribes in the southern sea, rich in pearls and poor in patience. Its captains want a High Chief who sails, not one who sits on ice, and have never yet had one.",
	},
	# --- The Air Temples ----------------------------------------------------
	"air_nomads": {
		"name": "Air Nomads", "short": "Air Nomads", "color": Color(0.95, 0.62, 0.15),
		"trim": Color(0.95, 0.88, 0.55), "culture": "air", "king": "", "capital": "", "region": "air", "kind": "People", "peaceful": true,
		"desc": "The monks and nuns of the four temples, and their pilgrims. Your standing with the Nomads as a people counts at every temple.",
	},
	"air_south": {
		"name": "Southern Air Temple", "short": "South Temple", "color": Color(0.95, 0.6, 0.18),
		"trim": Color(0.95, 0.88, 0.55), "culture": "air", "king": "", "capital": "southern_air_temple", "region": "air", "kind": "Temple", "peaceful": true, "people": "air_nomads", "head": "Abbot Dorje",
		"desc": "A temple of monks on the Patola peaks. It shelters refugees from three wars and has begun to run short of rice.",
	},
	"air_north": {
		"name": "Northern Air Temple", "short": "North Temple", "color": Color(0.92, 0.7, 0.25),
		"trim": Color(0.95, 0.88, 0.55), "culture": "air", "king": "", "capital": "northern_air_temple", "region": "air", "kind": "Temple", "peaceful": true, "people": "air_nomads", "head": "Abbot Lhakpa",
		"desc": "The highest and most austere temple, a monks' retreat that keeps the old disciplines and distrusts the others' politics.",
	},
	"air_east": {
		"name": "Eastern Air Temple", "short": "East Temple", "color": Color(0.98, 0.55, 0.2),
		"trim": Color(0.95, 0.88, 0.55), "culture": "air", "king": "", "capital": "eastern_air_temple", "region": "air", "kind": "Temple", "peaceful": true, "people": "air_nomads", "head": "Abbess Tsering",
		"desc": "A temple of nuns whose archive holds letters from every Avatar who visited. It is the temple that speaks to kings, and the other three let it.",
	},
	"air_west": {
		"name": "Western Air Temple", "short": "West Temple", "color": Color(0.9, 0.5, 0.25),
		"trim": Color(0.95, 0.88, 0.55), "culture": "air", "king": "", "capital": "western_air_temple", "region": "air", "kind": "Temple", "peaceful": true, "people": "air_nomads", "head": "Abbess Yeshe",
		"desc": "A nuns' temple hanging beneath a cliff edge near the Fire Islands. It hears the clans' quarrels first and repeats none of them.",
	},
	# --- Others -----------------------------------------------------------
	"player": {
		"name": "Your Realm", "short": "Your Realm", "color": Color(0.6, 0.35, 0.75),
		"trim": Color(0.95, 0.9, 0.6), "culture": "earth", "king": "player", "capital": "", "region": "", "kind": "Realm",
		"desc": "The lands you hold in your own name, and the communities that pay you tribute.",
	},
	"bandits": {
		"name": "Outlaws", "short": "Outlaws", "color": Color(0.35, 0.3, 0.25),
		"trim": Color(0.6, 0.55, 0.45), "culture": "earth", "king": "", "capital": "", "region": "outlaw", "kind": "Outlaws",
		"desc": "Pirates, raiders and deserters who prey on everyone.",
	},
	"red_lanterns": {
		"name": "Red Lantern Brotherhood", "short": "Red Lanterns", "color": Color(0.7, 0.18, 0.15),
		"trim": Color(0.95, 0.7, 0.3), "culture": "earth", "king": "", "capital": "", "region": "outlaw", "kind": "Sworn brotherhood", "head": "the Elder Brother",
		"desc": "Sworn daofei who rob the Earth Kingdom's tax barges and feed Ba Sing Se's Lower Ring with the grain. Heroes to the hungry, murderers to the Censorate.",
	},
	"avatar": {
		"name": "The Avatar's Company", "short": "The Avatar", "color": Color(0.92, 0.9, 0.75),
		"trim": Color(0.6, 0.85, 1.0), "culture": "air", "king": "", "capital": "", "region": "", "kind": "Company",
		"desc": "The Avatar and those who travel with them: friends, teachers and volunteers from every nation.",
	},
	"neutral": {
		"name": "Neutral", "short": "Neutral", "color": Color(0.8, 0.8, 0.8),
		"trim": Color(1, 1, 1), "culture": "air", "king": "", "capital": "", "region": "", "kind": "",
		"desc": "",
	},
}

## Display order and headings of the regions in the Factions window.
const REGIONS := [["fire", "The Fire Islands"], ["earth", "The Earth Continent"], ["water", "The Water Tribes (Moon Council)"], ["air", "The Air Temples"], ["outlaw", "Outlaws"]]

## Factions that take part in diplomacy: everyone with lords and armies.
## Filled in _ready from the lords table; communities and temples are not in it.
var KINGDOMS: Array = []

# Wars already being fought when the game begins.
const STARTING_WARS := [["fire_nation", "earth_kingdom"], ["earth_kingdom", "omashu"], ["fire_nation", "southern_water"],
	["fire_nation", "whalebone"], ["earth_kingdom", "lingtai"], ["clan_kurozan", "clan_kagari"]]

# How each people orders itself: shown in the Nations window, and the source
# of the class rules the game enforces (see docs/setting.md §2).
var societies := {
	"fire_nation": {"ladder": ["The Fire Lord and the royal house", "The heads of the great clans", "Fire Sages (outside rank, inside every decision)", "Officers, merchants and civil servants", "Commoners: farmers, fishers, smiths — conscripted at sixteen", "Strait Islanders: neither wholly Fire nor Earth"],
		"text": "Rank is inherited. The royal house rules Caldera and its own islands; the great clans rule theirs, owe the throne ceremony and ships, and give it as little of either as they can. In Caldera the clans' town houses terrace the crater walls in order of precedence. Disputes of honour between nobles are settled by Agni Kai, a firebending duel before witnesses. Commoners serve; three ruined harvests have made the service longer and the rations smaller. The Fire Sages chart the sky and keep the calendar, and nobody declares war without asking them first.",
		"rules": "Fire Nation nobles accept an Agni Kai only from someone of Gentry standing; a non-bender must name a firebending champion. Refusing a noble's challenge costs honour."},
	"earth_kingdom": {"ladder": ["The Earth Queen", "The Grand Secretariat, and the Censorate that serves it", "Upper Ring nobility", "Middle Ring merchants and scholars, who rise by civil examination", "Lower Ring labourers and refugees", "Villagers beyond the walls"],
		"text": "The Kingdom is held together by walls, seals and paperwork. Ba Sing Se's three rings are three worlds, and the gates between them are guarded. The Censorate was founded long ago to keep the city's records honest; now it protect its silence. Most earthbenders are miners, builders and farmers, not soldiers.",
		"rules": "Ba Sing Se's Middle Ring needs Citizen standing or papers; the Upper Ring needs Gentry standing or an invitation. A trade permit improves prices in Earth Kingdom markets."},
	"sun_warriors": {"ladder": ["The Chief, keeper of the Eternal Flame", "Masters, who have stood before the dragons", "Warriors and adepts", "Farmers and builders of the terraces"],
		"text": "The Sun Warriors learned firebending from the dragons and still teach it the old way: as the energy of life, not of rage. Their city is old, their customs older, and they keep the Eternal Flame that every other fire in the islands is said to come from. They are few, and they mean to stay few.",
		"rules": "The Sun Warriors will not join anyone's war. Their city is defended by its masters and by the dragons; every faction's AI leaves it alone unless led by someone reckless or overwhelmingly strong."},
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
	"south": "swt_villager", "hamakaze": "tw_initiate", "swamp": "sw_swamper",
	"omashu": "om_militia", "air": "an_novice", "sun": "sun_initiate",
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
		"bend_power": 1.3, "armor": 18, "upgrades": ["ek_censor"],
		"look": {"body": ek_body, "trim": Color(0.5, 0.4, 0.2), "helmet": "ek_hat"}})
	_t("ek_censor", "Censorate Agent", "earth", 4, {"weapon": "fists", "bend": "earth",
		"bend_power": 1.7, "armor": 20, "skill": 85,
		"look": {"body": Color(0.24, 0.26, 0.28), "trim": Color(0.08, 0.08, 0.09), "helmet": "censor"}})

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

	# Hamakaze
	var tw_body := Color(0.16, 0.2, 0.36)
	var tw_trim := Color(0.62, 0.3, 0.18)
	_t("tw_initiate", "Tide Warden Initiate", "hamakaze", 1, {"weapon": "warden_glaive", "skill": 35,
		"upgrades": ["tw_warden"], "look": {"body": tw_body, "trim": tw_trim, "helmet": "hamakaze"}})
	_t("tw_warden", "Tide Warden", "hamakaze", 2, {"weapon": "warden_glaive", "skill": 60,
		"upgrades": ["tw_veteran"], "look": {"body": tw_body, "trim": tw_trim, "helmet": "hamakaze"}})
	_t("tw_veteran", "Tide Warden Veteran", "hamakaze", 3, {"weapon": "jian", "skill": 75, "shield": false,
		"upgrades": ["tw_captain"], "look": {"body": Color(0.14, 0.17, 0.32), "trim": tw_trim, "helmet": "hamakaze"}})
	_t("tw_captain", "Tide Warden Captain", "hamakaze", 4, {"weapon": "jian", "skill": 90, "armor": 26,
		"look": {"body": Color(0.12, 0.15, 0.28), "trim": Color(0.9, 0.88, 0.82), "helmet": "hamakaze"}})

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

	# Sun Warriors: few, old in their art, and fighting beside dragons at home
	var sw_body := Color(0.72, 0.5, 0.18)
	var sw_trim := Color(0.18, 0.42, 0.4)
	_t("sun_initiate", "Sun Warrior Initiate", "sun", 1, {"weapon": "spear", "skill": 40,
		"upgrades": ["sun_warrior", "sun_fb_adept"], "look": {"body": sw_body, "trim": sw_trim, "helmet": "none"}})
	_t("sun_warrior", "Sun Warrior", "sun", 3, {"weapon": "war_club", "shield": true, "skill": 70,
		"upgrades": ["sun_guard"], "look": {"body": Color(0.6, 0.4, 0.15), "trim": sw_trim, "helmet": "none"}})
	_t("sun_fb_adept", "Sun Warrior Adept", "sun", 3, {"weapon": "fists", "bend": "fire", "bend_power": 1.5, "armor": 14,
		"upgrades": ["sun_master"], "look": {"body": sw_body, "trim": Color(0.85, 0.3, 0.1), "helmet": "none"}})
	_t("sun_guard", "Flame Guard", "sun", 4, {"weapon": "guan_dao", "shield": false, "skill": 88, "armor": 28, "hp": 80,
		"look": {"body": Color(0.5, 0.32, 0.1), "trim": Color(0.9, 0.75, 0.3), "helmet": "none"}})
	_t("sun_master", "Sun Warrior Master", "sun", 5, {"weapon": "fists", "bend": "fire", "bend_power": 2.2, "armor": 20, "hp": 85, "skill": 90,
		"look": {"body": Color(0.8, 0.6, 0.2), "trim": Color(0.12, 0.35, 0.33), "helmet": "none"}})

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
	# The Avatar (stats, name and look come from scripts/core/avatar.gd)
	_t("avatar", "The Avatar", "air", 6, {"hero": true, "bend": "avatar", "bend_power": 2.6, "weapon": "staff", "hp": 300, "armor": 14, "skill": 95,
		"look": {"body": Color(0.9, 0.85, 0.7), "trim": Color(0.95, 0.9, 0.6), "helmet": "none"}})
	# Chi-blockers: non-benders who strike pressure points; a bender they hit
	# cannot bend for a while. Hired as a precaution against the Avatar.
	_t("chi_blocker", "Chi-Blocker", "earth", 3, {"weapon": "fists", "chi_blocker": true, "hp": 60, "armor": 6, "skill": 70,
		"look": {"body": Color(0.35, 0.3, 0.38), "trim": Color(0.75, 0.2, 0.25), "helmet": "none"}})

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
	"warden_glaive": {"name": "Tide Warden Glaive", "slot": "weapon", "dmg": 20, "reach": 1.7, "speed": 1.1, "dtype": "cut", "price": 260, "model": "guan_dao"},
	"jian": {"name": "Jian", "slot": "weapon", "dmg": 21, "reach": 1.55, "speed": 1.2, "dtype": "cut", "price": 380, "model": "sword"},
	"dao": {"name": "Dao Broadsword", "slot": "weapon", "dmg": 23, "reach": 1.5, "speed": 1.05, "dtype": "cut", "price": 420, "model": "dao"},
	"hook_swords": {"name": "Hook Swords", "slot": "weapon", "dmg": 22, "reach": 1.6, "speed": 1.25, "dtype": "cut", "price": 650, "model": "hooks"},
	"dual_dao": {"name": "Dual Dao", "slot": "weapon", "dmg": 25, "reach": 1.45, "speed": 1.25, "dtype": "cut", "price": 900, "model": "dual_dao"},
	"guan_dao": {"name": "Guan Dao", "slot": "weapon", "dmg": 30, "reach": 2.5, "speed": 0.78, "dtype": "cut", "price": 750, "model": "guan_dao"},
	"comet_dao": {"name": "Comet-Forged Dao", "slot": "weapon", "dmg": 31, "reach": 1.55, "speed": 1.15, "dtype": "cut", "price": 5000, "model": "dao"},
	"space_sword": {"name": "Sky-Iron Sword", "slot": "weapon", "dmg": 34, "reach": 1.7, "speed": 1.15, "dtype": "cut", "price": 6000, "model": "space_sword"},
	# ranged
	"short_bow": {"name": "Short Bow", "slot": "ranged", "dmg": 21, "ammo": 24, "accuracy": 0.8, "proj_speed": 45.0, "price": 200, "model": "bow"},
	"yuyan_bow": {"name": "Yuyan Longbow", "slot": "ranged", "dmg": 31, "ammo": 24, "accuracy": 0.95, "proj_speed": 60.0, "price": 1100, "model": "bow"},
	"boomerang": {"name": "Boomerang", "slot": "ranged", "dmg": 18, "ammo": 99, "accuracy": 0.85, "proj_speed": 28.0, "price": 150, "model": "boomerang"},
	"throwing_knives": {"name": "Throwing Knives", "slot": "ranged", "dmg": 19, "ammo": 8, "accuracy": 0.75, "proj_speed": 32.0, "price": 120, "model": "knife"},
	# body armour
	"peasant_clothes": {"name": "Peasant Clothes", "slot": "armor", "armor": 3, "price": 20},
	"nomad_robes": {"name": "Air Nomad Robes", "slot": "armor", "armor": 4, "price": 60},
	"water_parka": {"name": "Water Tribe Parka", "slot": "armor", "armor": 8, "price": 120},
	"fur_armor": {"name": "Fur and Bone Armour", "slot": "armor", "armor": 15, "price": 420},
	"ek_armor": {"name": "Earth Kingdom Lamellar", "slot": "armor", "armor": 17, "price": 520},
	"tide_armor": {"name": "Tide Warden Lamellar", "slot": "armor", "armor": 19, "price": 700},
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
	"hamakaze": ["warden_glaive", "jian", "tide_armor", "straw_hat"],
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
	"porcelain": {"name": "Porcelain", "price": 95, "food": false},
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
# docs/setting.md §4). look: fixed appearance keys (sex, hair, ...).
# no_offense: never joins offensive campaigns.
const GREY := Color(0.62, 0.6, 0.58)
var lords := {
	# Fire Nation
	"haoren": {"name": "Fire Lord Haoren", "faction": "fire_nation", "bend": "fire", "power": 2.6, "weapon": "fists", "hp": 200, "troops": 120, "home": "caldera", "king": true, "aggression": 0.25,
		"look": {"sex": "m", "hair": "Hair_SimpleParted", "hair_color": GREY, "beard": true},
		"bio": "Wants peace; fears being remembered as the man who let the Avatar die. He was the Avatar's friend in boyhood and still keeps a chipped Pai Sho tile they played with.",
		"bio_sandbox": "Wants peace; fears being remembered as the Fire Lord who could not end a war the Avatar had to end for him. He keeps a chipped Pai Sho tile from a friend who died young.",
		"line": "Sit. Everyone who comes before me wants something, and most of them want a war. Which are you?"},
	"ryoko": {"name": "Crown Princess Ryoko", "faction": "fire_nation", "bend": "fire", "power": 2.5, "weapon": "fists", "hp": 180, "troops": 70, "home": "caldera", "aggression": 0.35,
		"look": {"sex": "f", "hair": "Hair_Buns"},
		"bio": "Wants the Admiralty out of the Strait Isles; fears her father's disappointment more than any army. Her wife, Lady Satsuki, keeps the royal archives — and keeps Ryoko honest.",
		"line": "If you've come to tell me the Strait Isles are worth dying for, save your breath. If you've come with an idea, I have tea."},
	"kuro": {"name": "Admiral Tenzai Kuro", "faction": "fire_nation", "bend": "fire", "power": 2.0, "weapon": "dao", "hp": 170, "troops": 90, "home": "fire_navy_harbor", "aggression": 0.85,
		"look": {"sex": "m", "hair": "Hair_Buzzed", "beard": true},
		"bio": "Wants the Strait Isles, and the fortune he has made in them; fears the truth about the night the Avatar was lost. Generous to his sailors and utterly self-justifying.",
		"bio_sandbox": "Wants the Strait Isles, and the fortune he has made in them; fears the day the Avatar takes an interest in his ledgers. Generous to his sailors and utterly self-justifying.",
		"line": "Every sailor in my fleet eats because I made hard choices. Remember that before you judge me."},
	"ito": {"name": "General Masaru Ito", "faction": "fire_nation", "bend": "", "power": 1.0, "weapon": "dao", "hp": 160, "troops": 90, "home": "kettle_rock", "aggression": 0.5,
		"look": {"sex": "m", "hair": "Hair_Buzzed", "hair_color": GREY},
		"bio": "Wants to bring his conscripts home alive; fears becoming irrelevant. A non-bender who rose through the ranks and remembers the name of every soldier he has lost.",
		"line": "I have three hundred and twelve names in this book. I would rather not add yours."},
	"hiyori": {"name": "Lady Aimi Hiyori", "faction": "clan_hiyori", "bend": "", "power": 1.0, "weapon": "knife", "hp": 110, "troops": 70, "home": "fire_fountain", "king": true, "aggression": 0.4,
		"look": {"sex": "f", "hair": "Hair_Long"},
		"bio": "Wants information, which is power; fears being underestimated, though she encourages it. A spymaster who plays every side and is honest only with her cat.",
		"line": "You're the one everyone's been writing to me about. Oh, don't look so worried. Most of the letters were kind."},
	"daisuke": {"name": "Commander Daisuke Ren", "faction": "clan_ren", "bend": "fire", "power": 1.8, "weapon": "fists", "hp": 150, "troops": 70, "home": "ember_island", "aggression": 0.9,
		"look": {"sex": "m", "hair": "Hair_Long"},
		"bio": "Wants glory; fears being ordinary. A twenty-two-year-old firebending prodigy, insufferable and secretly terrified. Humbled kindly, he could become someone worth following.",
		"line": "You've heard of me, obviously. Everyone has. Go on — ask me about the Battle of Shu Jing Strait."},
	# Fire Islands clans
	"hiyori_genji": {"name": "Lord Genji Hiyori", "faction": "clan_hiyori", "bend": "fire", "power": 1.4, "weapon": "jian", "hp": 140, "troops": 50, "home": "fire_fountain", "aggression": 0.5,
		"look": {"sex": "m", "hair": "Hair_SimpleParted"},
		"bio": "Lady Hiyori's younger brother and the clan's sword. Wants a seat on the royal council; fears his sister will trade it away for a secret. He writes poetry nobody is allowed to read.",
		"line": "My sister knows everything. I only know how to win. Between us, the clan does well."},
	"ren_chiyo": {"name": "Lady Chiyo Ren", "faction": "clan_ren", "bend": "fire", "power": 1.9, "weapon": "fists", "hp": 150, "troops": 60, "home": "ember_island", "king": true, "aggression": 0.35,
		"look": {"sex": "f", "hair": "Hair_Buns", "hair_color": GREY},
		"bio": "Head of the Ren Clan and Daisuke's mother. Wants the clan's debts paid before its creditors notice; fears that her son's glory is the only collateral she has left. A master who stopped duelling the day she lost one.",
		"line": "If you have come to admire my son, the queue is outside. If you have come to lend me money, sit down."},
	"kagari_sosuke": {"name": "Lord Sosuke Kagari", "faction": "clan_kagari", "bend": "fire", "power": 1.7, "weapon": "dao", "hp": 160, "troops": 90, "home": "kagari_keep", "king": true, "aggression": 0.6,
		"look": {"sex": "m", "hair": "Hair_Long", "beard": true},
		"bio": "Wants a Kagari on the throne, by marriage if possible and otherwise by other means; fears the Kurozan, who burned his grandfather's ships. Builds model ships for his daughters.",
		"line": "The royal house needs our ships more than we need its blessings. One day it will remember that, or be reminded."},
	"tsurugi_hana": {"name": "Lady Hana Tsurugi", "faction": "clan_tsurugi", "bend": "", "power": 1.0, "weapon": "dao", "hp": 140, "troops": 80, "home": "tsurugi", "king": true, "aggression": 0.4,
		"look": {"sex": "f", "hair": "Hair_Long"},
		"bio": "A smith before she was a clan head, and still one in the evenings. Wants her clan's iron trade with the Sun Warriors kept quiet; fears the day the royal house asks what is paid for it.",
		"line": "Everything on this island that cuts, I made or my mother did. Mind your hands."},
	"kurozan_isamu": {"name": "Lord Isamu Kurozan", "faction": "clan_kurozan", "bend": "fire", "power": 2.0, "weapon": "fists", "hp": 170, "troops": 70, "home": "kurozan_hold", "king": true, "aggression": 0.75,
		"look": {"sex": "m", "hair": "Hair_Buzzed", "beard": true},
		"bio": "Wants the clans to rule the throne rather than the other way round; fears dying before he sees it. Has fought eleven Agni Kai and keeps the scars of every one uncovered.",
		"line": "Every Fire Lord promises the clans their old rights. Every Fire Lord forgets. I have a long memory instead."},
	# Sun Warriors
	"huallpa": {"name": "Chief Huallpa", "faction": "sun_warriors", "bend": "fire", "power": 2.8, "weapon": "fists", "hp": 220, "troops": 150, "home": "sun_city", "king": true, "aggression": 0.05, "no_offense": true, "culture": "sun",
		"look": {"sex": "m", "hair": "Hair_Long", "hair_color": GREY, "accessory": "warpaint"},
		"bio": "Chief of the Sun Warriors and keeper of the Eternal Flame. Wants the city left alone; fears that the islands have forgotten why they leave it alone. He speaks to the dragons and says they mostly speak about the weather.",
		"line": "You came a long way through the jungle to be told no. Sit, drink something, and then be told no."},
	"oda": {"name": "Castellan Sakura Oda", "faction": "fire_nation", "bend": "", "power": 1.0, "weapon": "guan_dao", "hp": 140, "troops": 60, "home": "boiling_keep", "aggression": 0.3, "no_offense": true,
		"look": {"sex": "f", "hair": "Hair_Buns", "hair_color": GREY},
		"bio": "Wants order; fears chaos. Holds Boiling Lake Keep and believes in schooling far more than her officers do.",
		"line": "Every soldier here is someone's child. I try to remember that. My officers try to forget it."},
	# Earth Kingdom
	"hualing": {"name": "Earth Queen Hualing", "faction": "earth_kingdom", "bend": "", "power": 1.0, "weapon": "staff", "hp": 100, "troops": 110, "home": "ba_sing_se", "king": true, "aggression": 0.3,
		"look": {"sex": "f", "hair": "Hair_Buns"},
		"bio": "Wants to be a real queen; fears being a figurehead. Nineteen, raised in the palace, she has never seen the Lower Ring — and notices far more than her regent thinks.",
		"line": "Secretary Wu says I shouldn't receive petitioners without him. Secretary Wu is not here. Speak."},
	"wu_jian": {"name": "Grand Secretary Wu Jian", "faction": "earth_kingdom", "bend": "earth", "power": 1.9, "weapon": "fists", "hp": 160, "troops": 80, "home": "ba_sing_se", "aggression": 0.4,
		"look": {"sex": "m", "hair": "Hair_SimpleParted", "hair_color": GREY, "beard": true},
		"bio": "Wants control; fears chaos. A careful, soft-spoken regent who believes order is the only real mercy. He has never once raised his voice.",
		"line": "There is a form for that. There is a form for everything. It is how a city of a million people does not burn."},
	"shu_fan": {"name": "Chief Censor Shu Fan", "faction": "earth_kingdom", "bend": "earth", "power": 1.8, "weapon": "fists", "hp": 150, "troops": 70, "home": "ba_sing_se", "aggression": 0.55,
		"look": {"sex": "m", "accessory": "censor", "kit": "censor_robe"},
		"bio": "Chief Censor of Ba Sing Se. Wants rank; fears Wu Jian. Loyal to the regent exactly as long as loyalty pays.",
		"line": "The Censorate hears everything. Choose your next words as if I'm writing them down. I am."},
	"ba_tsai": {"name": "General Ba Tsai", "faction": "earth_kingdom", "bend": "", "power": 1.0, "weapon": "guan_dao", "hp": 160, "troops": 85, "home": "outer_wall", "aggression": 0.5,
		"look": {"sex": "m", "hair": "Hair_Buzzed", "hair_color": GREY, "beard": true},
		"bio": "Wants to hold the Outer Wall; fears pointless orders from the palace. Gruff, fair, and the author of truly bad poetry for his late wife.",
		"line": "The Wall has stood for a thousand years. It'll stand through this. Whether I do is another question."},
	"cheng_mei": {"name": "Lady Cheng Mei", "faction": "house_cheng", "king": true, "bend": "", "power": 1.0, "weapon": "jian", "hp": 100, "troops": 60, "home": "gaoling", "aggression": 0.2,
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
	"oyama": {"name": "Captain Oyama", "faction": "tide_wardens", "king": true, "bend": "", "power": 1.0, "weapon": "warden_glaive", "hp": 150, "troops": 60, "home": "hamakaze", "aggression": 0.5, "culture": "hamakaze", "no_offense": true,
		"look": {"sex": "f", "hair": "Hair_Buns"},
		"bio": "Leader of the Tide Wardens. Wants to protect Hamakaze; fears being drawn into conquest. She has refused three royal orders to march, politely.",
		"line": "The Tide Wardens defend. We don't conquer. If you've come to recruit us for a war, the answer is still no."},
	"lan_jie": {"name": "Captain Lan Jie", "faction": "house_cheng", "bend": "earth", "power": 1.3, "weapon": "spear", "hp": 140, "troops": 50, "home": "gaoling", "aggression": 0.35,
		"look": {"sex": "f", "hair": "Hair_Buzzed"},
		"bio": "Commands the hired guard of House Cheng. Wants a contract long enough to retire on; fears being paid to fight the crown. Gambles at the Stone Pit and wins too often to be liked.",
		"line": "House Cheng pays well and on time. That makes us the most loyal soldiers on the continent, as long as it lasts."},
	# Beishan, Haiyan, Lingtai
	"teng_yao": {"name": "Marquis Teng Yao", "faction": "beishan", "bend": "earth", "power": 1.8, "weapon": "guan_dao", "hp": 170, "troops": 90, "home": "beishan_hold", "king": true, "aggression": 0.6,
		"look": {"sex": "m", "hair": "Hair_SimpleParted", "beard": true},
		"bio": "Wants Beishan to be a kingdom in all but name, and maybe in name; fears being caught between Ba Sing Se and Omashu when they stop fighting each other. Keeps a garden of northern pines he has never let anyone prune.",
		"line": "Ba Sing Se wants my tribute, Omashu wants my soldiers, and my farmers want rain. Only the farmers will get what they want."},
	"pao_ruyi": {"name": "Duke Pao Ruyi", "faction": "haiyan", "bend": "", "power": 1.0, "weapon": "jian", "hp": 120, "troops": 90, "home": "haiyan", "king": true, "aggression": 0.3,
		"look": {"sex": "m", "hair": "Hair_Long", "hair_color": GREY},
		"bio": "Wants Haiyan's tribute lowered and its harbour dredged; fears his daughter is cleverer than he is, and is right. Counts the crown's coins twice before he sends them.",
		"line": "Every year I send the crown its tribute, and every year it sends me a letter of thanks. One of us is getting the better bargain."},
	"pao_lin": {"name": "Lady Pao Lin", "faction": "haiyan", "bend": "earth", "power": 1.6, "weapon": "fists", "hp": 140, "troops": 50, "home": "haiyan", "aggression": 0.55,
		"look": {"sex": "f", "hair": "Hair_Buns"},
		"bio": "The duke's daughter and the coast's best earthbender. Wants Haiyan to stop paying tribute altogether; fears her father will make her marry before she can make it happen.",
		"line": "My father thinks the crown protects us. I have read the crown's letters. It protects the tribute."},
	"gu_bao": {"name": "Warlord Gu Bao", "faction": "lingtai", "bend": "earth", "power": 1.7, "weapon": "dao", "hp": 180, "troops": 80, "home": "lingtai", "king": true, "aggression": 0.85,
		"look": {"sex": "m", "hair": "Hair_Buzzed", "accessory": "bandana"},
		"bio": "Once a crown garrison commander; now a warlord. Wants the arrears he is owed and then some; fears being hanged as an example. Pays his men before himself, which is why they stay.",
		"line": "The crown owed my men two years' pay. I collected it. Now everyone calls me a warlord and the crown calls me a debt."},
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
	# Aqsarniit Clans and the Kanguq Tribe
	"ataneq": {"name": "Chief Ataneq", "faction": "aqsarniit", "bend": "water", "power": 2.0, "weapon": "spear", "hp": 160, "troops": 80, "home": "aurora_hall", "king": true, "aggression": 0.35,
		"look": {"sex": "f", "hair": "Hair_Long"},
		"bio": "Chief of the Aqsarniit Clans, a waterbender who learned combat from her grandmother on the open ice. Wants Agna Qel'a to admit the clans were right; fears it never will.",
		"line": "Agna Qel'a sends us letters about tradition. We send back furs. They read the furs more carefully."},
	"kallik": {"name": "Chieftain Kallik", "faction": "pearl_isles", "bend": "water", "power": 2.1, "weapon": "spear", "hp": 160, "troops": 80, "home": "tidehall", "king": true, "aggression": 0.5,
		"look": {"sex": "f", "hair": "Hair_Long"},
		"bio": "Captain of the Pearl Isles League. Wants to be the first High Chief from the warm seas; fears the ice tribes will close ranks against her, as they always have. Dives for pearls herself before every council, for luck.",
		"line": "The ice tribes think the Moon only shines on snow. It shines on my lagoon too, and the view is better."},
	"tulimaq": {"name": "Navigator Tulimaq", "faction": "pearl_isles", "bend": "", "power": 1.0, "weapon": "spear", "hp": 130, "troops": 50, "home": "tidehall", "aggression": 0.4,
		"look": {"sex": "m", "hair": "Hair_Buzzed", "beard": true},
		"bio": "The League's best navigator. Wants a chart of every current in the southern sea; fears dying before it is finished. Talks to his compass.",
		"line": "Every island in this sea is somebody's. I just want to know where they all are before somebody else does."},
	"nuvuk": {"name": "Chief Nuvuk", "faction": "kanguq", "bend": "", "power": 1.0, "weapon": "spear", "hp": 150, "troops": 70, "home": "kanguq_hall", "king": true, "aggression": 0.3,
		"look": {"sex": "m", "hair": "Hair_Long", "beard": true},
		"bio": "Wants the Kanguq left out of Wolf's Crown's wars; fears Qannik's raiders will drag them in anyway. Breeds sled-dogs and names each one after a council member he dislikes.",
		"line": "Wolf's Crown votes for war, Qannik sails to it, and the geese still come back every spring. I side with the geese."},
	# Southern Water Tribe
	"siqiniq": {"name": "Chief Siqiniq", "faction": "southern_water", "bend": "water", "power": 2.0, "weapon": "fists", "hp": 170, "troops": 90, "home": "southern_tribe", "king": true, "aggression": 0.55,
		"look": {"sex": "f", "hair": "Hair_Long"},
		"bio": "Wants victory at sea without losing her people; fears the North's pity more than the Fire Navy.",
		"line": "The council votes on war, not me. But I can tell you which way I'm leaning, if you've earned it."},
	"aput": {"name": "Master Aput", "faction": "southern_water", "bend": "water", "power": 2.2, "weapon": "fists", "hp": 160, "troops": 60, "home": "southern_tribe", "aggression": 0.4,
		"look": {"sex": "m", "hair": "Hair_Long", "hair_color": GREY},
		"bio": "Wants to teach; fears losing students to the raids. He trains benders of every gender and has opinions about the North.",
		"line": "In the South, whoever wants to learn, learns. Do you want to learn?"},
	"qannik": {"name": "Raider-Captain Qannik", "faction": "whalebone", "king": true, "bend": "", "power": 1.0, "weapon": "war_club", "hp": 170, "troops": 70, "home": "hakodas_watch", "aggression": 0.9,
		"look": {"sex": "m", "hair": "Hair_Long", "accessory": "warpaint", "beard": true},
		"bio": "Wants revenge on the Fire Navy; fears peace, because he does not know who he would be without the raids.",
		"line": "Every Fire Nation ship that sinks is one that won't come south. Want to help me sink some?"},
	"malik": {"name": "Elder Malik", "faction": "southern_water", "bend": "", "power": 1.0, "weapon": "staff", "hp": 90, "troops": 35, "home": "southern_tribe", "aggression": 0.15, "no_offense": true,
		"look": {"sex": "m", "hair": "Hair_Buzzed", "hair_color": GREY},
		"bio": "Wants a negotiated peace; fears Qannik will make one impossible. The council's oldest voice and its most patient.",
		"line": "I have outlived three wars. The trick is to stop them before they outlive you."},
}

# ---------------------------------------------------------------------------
# Companions (heroes met in taverns). See docs/setting.md §5.
# ---------------------------------------------------------------------------
# bonus: party skill bonuses; perk: special ability; pronouns for text.
var companions := {
	"hana": {"name": "Hana of the Lower Ring", "short": "Hana", "pronouns": "she", "culture": "earth", "bend": "earth", "power": 1.7, "weapon": "fists", "hp": 130, "armor": 14, "skill": 75, "cost": 500,
		"bonus": {"tactics": 1}, "perk": "tunnels", "vlook": {"sex": "f", "hair": "Hair_BuzzedFemale"},
		"bio": "A Lower Ring earthbender and tunnel smuggler who has mapped every cellar and fault line under Ba Sing Se. Precise, literal, funny without trying. Hates surprises.",
		"pitch": "You're hiring. I have a map of every tunnel under Ba Sing Se, and I prefer to know where we're going before we go. Is that acceptable?"},
	"juro": {"name": "Juro Sato", "short": "Juro", "pronouns": "he", "culture": "fire", "bend": "", "power": 1.0, "weapon": "dao", "ranged": "throwing_knives", "hp": 120, "armor": 16, "skill": 70, "cost": 450,
		"bonus": {"trainer": 1}, "perk": "engineer", "vlook": {"sex": "m", "hair": "Hair_SimpleParted", "accessory": "topknot"},
		"bio": "A Fire Nation artillery engineer who deserted the night one of his designs burned a village in the Strait Isles. His fire left him that night. His father still writes every week.",
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
	# --- Element expansion companions (scripts/dlc/) ------------------------
	"sayuri": {"name": "Master Sayuri Ono", "short": "Sayuri", "pronouns": "she", "culture": "fire", "bend": "fire", "power": 1.7, "weapon": "jian", "hp": 115, "armor": 12, "skill": 92, "cost": 800,
		"bonus": {"trainer": 2}, "perk": "duellist", "dlc": "fire", "techs": {"q": "f_whip", "e": "f_breath_fire"},
		"vlook": {"sex": "f", "hair": "Hair_Buns", "hair_color": Color(0.62, 0.6, 0.58), "accessory": "fn_noble", "height": 0.97},
		"bio": "Fifty-four, a retired Agni Kai champion who never lost a duel she meant to win. An old lightning wound left her with pain that comes and goes like weather, and a cane she can kill a man with. Widow of a Fire Sage archivist named Haruko.",
		"pitch": "I used to be the most dangerous woman in Caldera. Now I'm the most dangerous woman in this tavern, which is a smaller title but easier to defend. I teach. I also fight, on good days. Today is a good day."},
	"huan": {"name": "Huan of the Foggy Swamp", "short": "Huan", "pronouns": "he", "culture": "swamp", "bend": "water", "power": 1.5, "weapon": "staff", "hp": 140, "armor": 8, "skill": 70, "cost": 350,
		"bonus": {"pathfinding": 1, "healing": 1}, "perk": "swampbender", "dlc": "water", "techs": {"q": "w_vines", "e": "w_mist"},
		"vlook": {"sex": "m", "hair": "Hair_Long", "beard": true, "hair_color": Color(0.2, 0.16, 0.1), "height": 1.08},
		"bio": "A large, gentle swampbender who finds crowds unbearable and trees easy. Believes the swamp remembers everyone who has ever been in it, and talks to it to keep it company. Ace and aromantic, and comfortable saying so.",
		"pitch": "The swamp said I should go and see things. I said the swamp should mind its own business. We argued. I lost. So. Here I am. I can bend water, and vines, and fog. I am not very good with doors."},
	"gao_ming": {"name": "Gao Ming", "short": "Gao Ming", "pronouns": "he", "culture": "earth", "bend": "earth", "power": 1.6, "weapon": "axe", "hp": 150, "armor": 14, "skill": 72, "cost": 500,
		"bonus": {"trainer": 1, "leadership": 1}, "perk": "miner", "dlc": "earth", "techs": {"e": "e_fissure", "r": "e_armor"},
		"vlook": {"sex": "m", "hair": "Hair_Buzzed", "beard": true, "accessory": "bandana", "height": 1.03},
		"bio": "Forty, a jade miner from the Lower Ring and the reason three mines in Gaoling now have shift limits. A widower raising a twelve-year-old daughter, Lian, who writes him letters correcting his spelling. Bisexual, tired, and stubborn in the way bedrock is stubborn.",
		"pitch": "I dig. I also talk people into things, which my mother says is worse. I can open a seam, hold up a roof, or put a wall where your enemy wanted to walk. I send half my wages home. That's not negotiable."},
	"yangzom": {"name": "Yangzom", "short": "Yangzom", "pronouns": "she", "culture": "air", "bend": "air", "power": 1.6, "weapon": "staff", "hp": 100, "armor": 6, "skill": 85, "cost": 300, "nonlethal": true,
		"bonus": {"pathfinding": 2}, "perk": "glider", "dlc": "air", "techs": {"q": "a_ball", "e": "a_glider"},
		"vlook": {"sex": "f", "hair": "Hair_BuzzedFemale", "accessory": "air_arrow"},
		"bio": "Twenty-three, a nun of the Western Air Temple who left to finish charting the Thirty-Six Winds, the Nomads' unfinished map of the world's air. Holds the temple's record for the longest glide, and three of its records for being late. Keeps the vow; knocks people into next week instead.",
		"pitch": "I'm making a map of the wind. All of it. It's going badly, which is exciting. You look like you're going somewhere. Can I come? I don't kill people. I'm extremely good at not killing people."},
}

# ---------------------------------------------------------------------------
# Settlements
# ---------------------------------------------------------------------------
# type: town | castle | village | temple | ruin
var settlements := {
	# Fire Nation
	"caldera": {"name": "Caldera City", "type": "town", "faction": "fire_nation", "pos": Vector2(322, 584), "owner": "haoren", "walls": 1.4, "culture": "fire",
		"produces": ["iron", "silk", "pottery"], "desc": "The Fire Nation capital, built inside the crater of a dormant volcano. Noble houses terrace the crater walls by rank; the palace sits highest, and the harbour district lowest."},
	"fire_fountain": {"name": "Fire Fountain City", "type": "town", "faction": "clan_hiyori", "pos": Vector2(492, 558), "owner": "hiyori", "culture": "fire",
		"produces": ["spices", "pottery"], "desc": "A bustling port crowned by a fire-breathing statue of a Fire Lord nobody can agree on. Every rumour in the Nation passes through its tea houses — and through Lady Hiyori."},
	"ember_island": {"name": "Ember Island", "type": "town", "faction": "clan_ren", "pos": Vector2(686, 528), "owner": "ren_chiyo", "culture": "fire",
		"produces": ["fish", "silk"], "desc": "A resort island for the Fire Nation elite, famous for its beaches, its summer houses and its sulking volcano."},
	"boiling_keep": {"name": "Boiling Lake Keep", "type": "castle", "faction": "fire_nation", "pos": Vector2(376, 466), "owner": "oda", "walls": 1.3, "culture": "fire",
		"produces": [], "desc": "An old keep on an island in a boiling lake, seat of the western garrison. Its castellan runs reading classes for the garrison's children on Tuesdays."},
	"kettle_rock": {"name": "Kettle Rock", "type": "castle", "faction": "fire_nation", "pos": Vector2(638, 568), "owner": "ito", "culture": "fire",
		"produces": [], "desc": "A fort the Admiralty raised three years ago on a rock both crowns claim, at the north end of the Strait Isles. General Ito's conscripts call it 'the Kettle'."},
	"fire_navy_harbor": {"name": "Fire Navy Harbour", "type": "castle", "faction": "fire_nation", "pos": Vector2(650, 580), "owner": "kuro", "culture": "fire",
		"produces": [], "desc": "The best harbour in the Strait Isles, occupied by the Admiralty three years ago and rebuilt in iron. Admiral Kuro's flagship rarely leaves it; his ledgers never do."},
	"shu_jing": {"name": "Shu Jing", "type": "village", "faction": "fire_nation", "pos": Vector2(698, 498), "bound": "caldera", "culture": "fire",
		"produces": ["rice", "fire_flakes"], "desc": "A quiet farming and fishing village in the Fire Nation heartland. Southern raiders struck its fleet two winters ago, and it has not forgotten."},
	"crescent_island": {"name": "Crescent Island", "type": "village", "faction": "fire_nation", "pos": Vector2(752, 514), "bound": "caldera", "culture": "fire",
		"produces": ["fish", "salt"], "desc": "A volcanic island home to an ancient Fire Temple, where the sages keep the calendar and watch for the Great Comet's return."},
	"jang_hui": {"name": "Jang Hui", "type": "village", "faction": "clan_hiyori", "pos": Vector2(750, 504), "bound": "fire_fountain", "culture": "fire",
		"produces": ["fish", "rice"], "desc": "A floating village of stilt houses on the delta. Its people trade with both nations and trust neither."},
	"ember_shore": {"name": "Ember Shore", "type": "village", "faction": "clan_ren", "pos": Vector2(692, 536), "bound": "ember_island", "culture": "fire",
		"produces": ["fire_flakes", "salt"], "desc": "Fishing huts and beach houses along the Ember Island shore."},
	"tieshan": {"name": "Tieshan", "type": "village", "faction": "fire_nation", "pos": Vector2(648, 570), "bound": "kettle_rock", "culture": "earth",
		"produces": ["iron", "rice"], "desc": "A mining village in the Strait Isles, under the Admiralty's 'protection'. The Fire Nation families who came for the mine live in the new houses; the old island families live everywhere else."},
	"navy_docks": {"name": "Saltreach Docks", "type": "village", "faction": "fire_nation", "pos": Vector2(658, 586), "bound": "fire_navy_harbor", "culture": "earth",
		"produces": ["fish", "whale_oil"], "desc": "Island fishers of both peoples mend nets side by side and do not talk about the war."},
	"rocky_hamlet": {"name": "Boiling Lake Hamlet", "type": "village", "faction": "fire_nation", "pos": Vector2(362, 530), "bound": "boiling_keep", "culture": "fire",
		"produces": ["salt", "iron"], "desc": "Soldiers' families live here, close to the steaming waters of the boiling lake."},

	# Earth Kingdom
	"ba_sing_se": {"name": "Ba Sing Se", "type": "town", "faction": "earth_kingdom", "pos": Vector2(1280, 364), "owner": "hualing", "walls": 1.8, "culture": "earth",
		"produces": ["jade", "silk", "tea"], "desc": "The impenetrable city. Refugees and labourers crowd the Lower Ring, merchants and scholars the Middle, nobles the Upper. The Censorate polices the gates between them — and the thoughts within."},
	"gaoling": {"name": "Gaoling", "type": "town", "faction": "house_cheng", "pos": Vector2(1082, 758), "owner": "cheng_mei", "culture": "earth",
		"produces": ["silk", "tea", "herbs"], "desc": "A wealthy southern town of merchant houses, where the Cheng family's coin reaches every ledger and the Stone Pit draws crowds every night."},
	"outer_wall": {"name": "Outer Wall Gate", "type": "castle", "faction": "earth_kingdom", "pos": Vector2(1190, 382), "owner": "ba_tsai", "walls": 1.5, "culture": "earth",
		"produces": [], "desc": "A gate in the vast Outer Wall of Ba Sing Se, held by General Ba Tsai and a great many bad poems."},
	"fong_fortress": {"name": "Shanzhai Fortress", "type": "castle", "faction": "earth_kingdom", "pos": Vector2(920, 488), "owner": "lu_kang", "culture": "earth",
		"produces": [], "desc": "An Earth Kingdom fortress facing the rebel kingdom of Omashu, from which General Lu Kang plans his campaigns."},
	"serpent_fort": {"name": "Serpent's Pass Fort", "type": "castle", "faction": "earth_kingdom", "pos": Vector2(1120, 404), "owner": "tan_yue", "culture": "earth",
		"produces": [], "desc": "A watchpost above the narrow Serpent's Pass to Ba Sing Se. Refugees cross it daily; General Tan Yue counts every one."},
	"tanshui": {"name": "Tanshui Village", "type": "village", "faction": "house_cheng", "pos": Vector2(950, 766), "bound": "gaoling", "culture": "earth",
		"produces": ["cabbages", "rice"], "desc": "A cliff-top village above the southwestern sea, famous for its masked spring festival and its arguments about it."},
	"gaipan": {"name": "Gaipan", "type": "village", "faction": "earth_kingdom", "pos": Vector2(972, 522), "bound": "fong_fortress", "culture": "earth",
		"produces": ["rice", "iron"], "desc": "A small valley town below a great dam, quartering more of Lu Kang's soldiers than it can feed."},
	"full_moon_bay": {"name": "Full Moon Bay", "type": "village", "faction": "earth_kingdom", "pos": Vector2(1130, 480), "bound": "outer_wall", "culture": "earth",
		"produces": ["fish", "salt"], "desc": "A hidden harbour where refugees board ferries to Ba Sing Se. The pirate queen Old Mother Shiyo anchors offshore and takes a toll."},
	"misty_palms": {"name": "Misty Palms Oasis", "type": "village", "faction": "misty_palms", "pos": Vector2(1094, 640), "community": {"fealty": "earth_kingdom", "head": "Well-keeper Su Ling", "kind": "Oasis town"}, "culture": "earth",
		"produces": ["spices", "salt"], "desc": "A fading oasis town at the edge of the Si Wong Desert. The Earth Kingdom closed its wells to the sandbender clans last summer."},
	"chameleon_bay": {"name": "Chameleon Bay", "type": "village", "faction": "chameleon_bay", "pos": Vector2(1388, 532), "community": {"fealty": "earth_kingdom", "head": "Harbourmaster Lo Wen", "kind": "Fishing village"}, "culture": "earth",
		"produces": ["fish", "whale_oil"], "desc": "A sheltered bay on the eastern coast, far from every war and grateful for it."},
	"hamakaze": {"name": "Hamakaze", "type": "village", "faction": "tide_wardens", "pos": Vector2(928, 802), "owner": "oyama", "culture": "hamakaze",
		"produces": ["fish", "silk"], "desc": "A pine-covered peninsula of fishing villages joined to the mainland by a narrow neck, defended by the Tide Wardens. It belongs to the Earth Kingdom on paper and to itself in practice, which makes it the one place every nation's envoys will agree to meet. Watch out for the unagi."},
	"foggy_swamp": {"name": "Foggy Swamp", "type": "village", "faction": "foggy_swamp", "pos": Vector2(992, 720), "community": {"fealty": "", "head": "the elders of the great tree", "kind": "Swamp tribe", "region": "water"}, "culture": "swamp",
		"produces": ["herbs", "fish"], "desc": "A misty swamp where a forgotten tribe of waterbenders lives among the roots of a single great tree."},
	"agrarian_vale": {"name": "Jade Terraces", "type": "village", "faction": "earth_kingdom", "pos": Vector2(1320, 404), "bound": "ba_sing_se", "culture": "earth",
		"produces": ["tea", "rice"], "desc": "The farmland between Ba Sing Se's walls, terraced with tea. Its harvest goes to the Upper Ring first."},

	# Kingdom of Omashu
	"omashu": {"name": "Omashu", "type": "town", "faction": "omashu", "pos": Vector2(996, 654), "owner": "feng_tao", "walls": 1.6, "culture": "omashu",
		"produces": ["jade", "pottery"], "desc": "A mountain city of delivery chutes, giant stairways and loud public theatre. Since the Secession its banners are purple and its king gives a speech every morning."},
	"stonewatch": {"name": "Stonewatch Pass", "type": "castle", "faction": "omashu", "pos": Vector2(948, 632), "owner": "kuang", "walls": 1.4, "culture": "omashu",
		"produces": [], "desc": "A fortress cut into the mountain road to Omashu. General Kuang has turned it into the rebellion's anvil."},
	"senlin": {"name": "Senlin Village", "type": "village", "faction": "senlin", "pos": Vector2(890, 552), "community": {"fealty": "omashu", "head": "Elder Mao", "kind": "Forest village"}, "culture": "omashu",
		"produces": ["rice", "cabbages"], "desc": "A forest village that leaves offerings at the edge of the trees for a great black-and-white spirit. Nobody wants to find out what happens if they stop."},
	"makapu": {"name": "Makapu Village", "type": "village", "faction": "makapu", "pos": Vector2(788, 374), "community": {"fealty": "omashu", "head": "Fortuneteller Ai", "kind": "Farming village"}, "culture": "omashu",
		"produces": ["rice", "pottery"], "desc": "A village at the foot of a volcano, home to a long line of fortunetellers who read clouds and are right just often enough."},
	"bianfu": {"name": "Bianfu Hollow", "type": "village", "faction": "omashu", "pos": Vector2(1034, 696), "bound": "stonewatch", "culture": "omashu",
		"produces": ["iron", "cabbages"], "desc": "Miners' terraces in a bat-haunted valley. Its people dug Omashu's first chutes and never let anyone forget it."},

	# Northern Water Tribe
	"agna_qela": {"name": "Agna Qel'a", "type": "town", "faction": "northern_water", "pos": Vector2(840, 128), "owner": "tulok", "walls": 1.5, "culture": "north",
		"produces": ["furs", "whale_oil", "seal_jerky"], "desc": "The capital of the Northern Water Tribe, carved from ice. At its heart lies the Spirit Oasis; in its healing huts, women learn the only bending the law allows them."},
	"frozen_harbor": {"name": "Frozen Harbour", "type": "castle", "faction": "northern_water", "pos": Vector2(758, 126), "owner": "iluq", "culture": "north",
		"produces": [], "desc": "An ice fortress guarding the western approaches to Agna Qel'a."},
	"ice_shelf": {"name": "Ice Shelf Camp", "type": "village", "faction": "northern_water", "pos": Vector2(788, 86), "bound": "frozen_harbor", "culture": "north",
		"produces": ["seal_jerky", "furs"], "desc": "Hunters' igloos on the edge of the northern ice."},
	"spirit_fishery": {"name": "Moon Fishery", "type": "village", "faction": "northern_water", "pos": Vector2(920, 138), "bound": "agna_qela", "culture": "north",
		"produces": ["fish", "sea_prunes"], "desc": "A fishing village whose people offer their first catch to the Moon Spirit."},

	# Southern Water Tribe
	"southern_tribe": {"name": "Wolf's Crown", "type": "town", "faction": "southern_water", "pos": Vector2(734, 1040), "owner": "siqiniq", "walls": 1.3, "culture": "south",
		"produces": ["furs", "seal_jerky", "sea_prunes"], "desc": "The great ice city of the South, ringed by canal-harbours. Its council hall is open to anyone who wants to argue, and most people do."},
	"hakodas_watch": {"name": "Whalebone Watch", "type": "castle", "faction": "whalebone", "pos": Vector2(966, 1044), "owner": "qannik", "culture": "south",
		"produces": [], "desc": "A raider harbour on the southern ice shelf, roofed with whale ribs. Qannik's canoes leave from here at night."},
	"wolf_cove": {"name": "Wolf Cove", "type": "village", "faction": "southern_water", "pos": Vector2(698, 1062), "bound": "southern_tribe", "culture": "south",
		"produces": ["fish", "furs"], "desc": "A sheltered cove where the tribe's canoes are hauled onto the ice."},
	"whaletail": {"name": "Whaletail Island", "type": "village", "faction": "whalebone", "pos": Vector2(836, 776), "bound": "hakodas_watch", "culture": "south",
		"produces": ["whale_oil", "seal_jerky"], "desc": "A rocky island shaped like the tail of a whale."},

	# Fire Islands clans and the Sun Warriors
	"kagari_keep": {"name": "Kagari Keep", "type": "castle", "faction": "clan_kagari", "pos": Vector2(226, 598), "owner": "kagari_sosuke", "walls": 1.3, "culture": "fire",
		"produces": [], "desc": "A shipyard keep on the western isle, its slipways guarded by a wall built from the stone of an older wall the Kurozan knocked down."},
	"shiohama": {"name": "Shiohama", "type": "village", "faction": "clan_kagari", "pos": Vector2(250, 644), "bound": "kagari_keep", "culture": "fire",
		"produces": ["salt", "fish"], "desc": "Salt pans and drying racks on a white beach. The Kagari's ships are paid for one sack at a time."},
	"tsurugi": {"name": "Tsurugi Harbour", "type": "town", "faction": "clan_tsurugi", "pos": Vector2(360, 676), "owner": "tsurugi_hana", "walls": 1.1, "culture": "fire",
		"produces": ["iron", "pottery"], "desc": "A harbour town of forges and slipways on the southern islands. Its smiths' hammers can be heard from the sea, and its best blades are sold to people who never come to collect them in person."},
	"akashima": {"name": "Akashima", "type": "village", "faction": "akashima", "pos": Vector2(464, 714), "culture": "fire", "community": {"fealty": "", "head": "Old Netmaker Sachi", "kind": "Fishing island"},
		"produces": ["fish", "salt"], "desc": "A red-cliffed fishing island that has refused every clan's protection for a century, on the grounds that nobody has ever wanted it badly enough to make the offer stick."},
	"kurozan_hold": {"name": "Kurozan Hold", "type": "castle", "faction": "clan_kurozan", "pos": Vector2(582, 610), "owner": "kurozan_isamu", "walls": 1.4, "culture": "fire",
		"produces": [], "desc": "A black basalt fortress on a black-sand island. Its walls are scorched on the inside from generations of Agni Kai in the courtyard."},
	"hinoura": {"name": "Hinoura", "type": "village", "faction": "clan_kurozan", "pos": Vector2(594, 622), "bound": "kurozan_hold", "culture": "fire",
		"produces": ["fire_flakes", "iron"], "desc": "A village of obsidian knappers and hot springs below the Hold."},
	"umibe": {"name": "Umibe", "type": "village", "faction": "umibe", "pos": Vector2(582, 566), "culture": "fire", "community": {"fealty": "fire_nation", "head": "Headman Goro", "kind": "Fishing village"},
		"produces": ["fish", "rice"], "desc": "A fishing village on a small island south of the delta. It pays the royal house for the right to fly its pennant, which keeps the clans' tax-boats away."},
	"sun_city": {"name": "City of the Sun Warriors", "type": "town", "faction": "sun_warriors", "pos": Vector2(320, 442), "owner": "huallpa", "walls": 2.0, "culture": "fire", "troops_culture": "sun", "dragons": true,
		"produces": ["herbs", "pottery"], "desc": "A stepped stone city in the jungle of the southwestern isle, where the Eternal Flame burns in the temple at the top of the stairs. Dragons sleep on the terraces at noon. Visitors are few and watched."},
	"sun_steps": {"name": "Ancestors' Steps", "type": "village", "faction": "sun_warriors", "pos": Vector2(338, 452), "bound": "sun_city", "culture": "fire", "troops_culture": "sun",
		"produces": ["herbs", "rice"], "desc": "Terraced fields on the jungle slopes below the city, worked by Sun Warrior families and tended, some say, by dragon-warmth in winter."},
	# The Earth continent: realms
	"beishan_hold": {"name": "Beishan Hold", "type": "castle", "faction": "beishan", "pos": Vector2(692, 242), "owner": "teng_yao", "walls": 1.3, "culture": "earth",
		"produces": [], "desc": "A hill fortress over the northern passes, built by the crown and kept by a marquis who no longer asks it for anything."},
	"lanshui": {"name": "Lanshui", "type": "village", "faction": "beishan", "pos": Vector2(708, 328), "bound": "beishan_hold", "culture": "earth",
		"produces": ["rice", "iron"], "desc": "A river village of mills and iron-workings. Its taxes go up the hill to Beishan and stop there."},
	"haiyan": {"name": "Haiyan", "type": "town", "faction": "haiyan", "pos": Vector2(1480, 472), "owner": "pao_ruyi", "walls": 1.2, "culture": "earth",
		"produces": ["fish", "salt", "silk"], "desc": "The eastern coast's largest harbour, silting slowly. The duke's palace faces the sea; the counting house faces the palace."},
	"yuwan": {"name": "Yuwan", "type": "village", "faction": "haiyan", "pos": Vector2(1504, 536), "bound": "haiyan", "culture": "earth",
		"produces": ["fish", "whale_oil"], "desc": "A fishing village whose boats bring the duke his fish and his news."},
	"lingtai": {"name": "Lingtai Fort", "type": "castle", "faction": "lingtai", "pos": Vector2(1400, 266), "owner": "gu_bao", "walls": 1.3, "culture": "earth",
		"produces": [], "desc": "A crown fort on the northeastern road, still flying the crown's colours upside down."},
	"shimen": {"name": "Shimen", "type": "village", "faction": "lingtai", "pos": Vector2(1366, 270), "bound": "lingtai", "culture": "earth",
		"produces": ["cabbages", "iron"], "desc": "A gate-village where the warlord's men take a toll from everyone, and pay for their own drinks, which the villagers find confusing."},
	# The Earth continent: independent communities
	"liuqiao": {"name": "Liuqiao", "type": "village", "faction": "liuqiao", "pos": Vector2(884, 308), "culture": "earth", "community": {"fealty": "earth_kingdom", "head": "Elder Fu", "kind": "Ferry village"},
		"produces": ["rice", "fish"], "desc": "Willow Bridge: a ferry crossing with no bridge, whose elders pay the crown for a seal that lets its boats carry royal freight."},
	"taolin": {"name": "Taolin", "type": "village", "faction": "taolin", "pos": Vector2(1216, 216), "culture": "earth", "community": {"fealty": "", "head": "Headwoman Xiao Rong", "kind": "Orchard village"},
		"produces": ["tea", "herbs"], "desc": "Peach orchards on a northern slope. It has paid tribute to nobody since the last tax collector married the headwoman's sister."},
	"huangtu": {"name": "Huangtu", "type": "village", "faction": "huangtu", "pos": Vector2(1216, 688), "culture": "earth", "community": {"fealty": "", "head": "Elder Mo Gan", "kind": "Desert-edge village"},
		"produces": ["salt", "pottery"], "desc": "Yellow Earth: rammed-earth houses on the eastern edge of the Si Wong, trading with the sandbender clans that the crown will not."},
	"baiyun": {"name": "Baiyun", "type": "village", "faction": "baiyun", "pos": Vector2(642, 370), "culture": "earth", "community": {"fealty": "", "head": "Headman Shan Bo", "kind": "Mountain village"},
		"produces": ["herbs", "cabbages"], "desc": "White Cloud: a village above the cloud line where Beishan and Omashu both send envoys, and both are given the same tea."},
	"qingshi": {"name": "Qingshi", "type": "village", "faction": "qingshi", "pos": Vector2(942, 664), "culture": "earth", "community": {"fealty": "omashu", "head": "Quarry-master Deng", "kind": "Quarry village"},
		"produces": ["jade", "iron"], "desc": "Bluestone: a quarry village that cut Omashu's stairways and now pays Omashu's king instead of Ba Sing Se's queen."},
	"yuhe": {"name": "Yuhe", "type": "village", "faction": "yuhe", "pos": Vector2(1156, 806), "culture": "earth", "community": {"fealty": "", "head": "Elder Tao Hua", "kind": "River village"},
		"produces": ["fish", "rice"], "desc": "A river-mouth village of stilt houses that has seen soldiers of three flags pass by and offered each of them the same thin soup."},
	"dongping": {"name": "Dongping", "type": "village", "faction": "dongping", "pos": Vector2(1212, 432), "culture": "earth", "community": {"fealty": "earth_kingdom", "head": "Magistrate Wei", "kind": "Market village"},
		"produces": ["rice", "tea"], "desc": "A market village outside the Outer Wall, near enough to the crown to pay it and far enough to complain."},
	"fenghe": {"name": "Fenghe", "type": "village", "faction": "fenghe", "pos": Vector2(1038, 766), "culture": "earth", "community": {"fealty": "house_cheng", "head": "Elder Kong Yi", "kind": "Farming village"},
		"produces": ["rice", "cabbages"], "desc": "Wind River: rice paddies whose harvest is bought by House Cheng before it is planted. The village pays Gaoling, not the crown, and is glad of the difference."},
	"lanwei": {"name": "Lanwei", "type": "village", "faction": "lanwei", "pos": Vector2(1408, 352), "culture": "earth", "community": {"fealty": "earth_kingdom", "head": "Headwoman Bai Qiao", "kind": "Coastal village"},
		"produces": ["fish", "salt"], "desc": "A coastal village that pays the crown and is raided by the warlord, and has begun to wonder what the first payment is for."},
	# The Water Tribes
	"aurora_hall": {"name": "Aurora Hall", "type": "castle", "faction": "aqsarniit", "pos": Vector2(978, 94), "owner": "ataneq", "walls": 1.2, "culture": "north",
		"produces": [], "desc": "The clans' meeting hall, a long ice house under the brightest skies of the north. Its doors face away from Agna Qel'a, deliberately."},
	"qilak": {"name": "Qilak Camp", "type": "village", "faction": "aqsarniit", "pos": Vector2(1010, 90), "bound": "aurora_hall", "culture": "north",
		"produces": ["furs", "seal_jerky"], "desc": "A hunting camp on the far ice where the women hunt with waterbending and the men argue about it."},
	"umiak_point": {"name": "Umiak Point", "type": "village", "faction": "umiak_point", "pos": Vector2(812, 44), "culture": "north", "community": {"fealty": "", "head": "Elder Pilu", "kind": "Whaling camp"},
		"produces": ["whale_oil", "furs"], "desc": "A whaling camp on the western ice, too far from Agna Qel'a to be ruled from it and too poor to be worth conquering."},
	"kanguq_hall": {"name": "Kanguq Hall", "type": "castle", "faction": "kanguq", "pos": Vector2(708, 1124), "owner": "nuvuk", "walls": 1.1, "culture": "south",
		"produces": [], "desc": "A walled ice hall on the western shelf, with kennels larger than the hall."},
	"seal_rocks": {"name": "Seal Rocks", "type": "village", "faction": "kanguq", "pos": Vector2(754, 1138), "bound": "kanguq_hall", "culture": "south",
		"produces": ["seal_jerky", "fish"], "desc": "Rocks crowded with seals and the families who hunt them."},
	"qamutik": {"name": "Qamutik Landing", "type": "village", "faction": "qamutik", "pos": Vector2(874, 1030), "culture": "south", "community": {"fealty": "", "head": "Elder Siku", "kind": "Sled-trading post"},
		"produces": ["furs", "sea_prunes"], "desc": "A sled-trading post on the eastern shelf where southern tribes trade without asking whose side anyone is on."},

	# The Water Tribes: small tribes of the ice, the fens and the islands
	"siku_narrows": {"name": "Siku Narrows", "type": "village", "faction": "siku_narrows", "pos": Vector2(738, 90), "culture": "north", "community": {"fealty": "northern_water", "head": "Elder Anuri", "kind": "Ice-fishing tribe"},
		"produces": ["fish", "furs"], "desc": "A tribe of ice-fishers on the narrows west of Agna Qel'a. They send the city fish and one vote's worth of opinions, through Agna Qel'a's mouth."},
	"tuktu_camp": {"name": "Tuktu Camp", "type": "village", "faction": "tuktu_camp", "pos": Vector2(892, 50), "culture": "north", "community": {"fealty": "northern_water", "head": "Hunter Qila", "kind": "Caribou-hunting tribe"},
		"produces": ["furs", "seal_jerky"], "desc": "Caribou hunters on a lone ice island between the North's two great shelves, courted by both."},
	"ukaliq": {"name": "Ukaliq Hollow", "type": "village", "faction": "ukaliq", "pos": Vector2(934, 48), "culture": "north", "community": {"fealty": "aqsarniit", "head": "Elder Paniuq", "kind": "Hare-trapping tribe"},
		"produces": ["furs", "sea_prunes"], "desc": "A sheltered hollow in the eastern ice where the Aqsarniit winter their sled-dogs and their grudges."},
	"qanik_point": {"name": "Qanik Point", "type": "village", "faction": "qanik_point", "pos": Vector2(970, 128), "culture": "north", "community": {"fealty": "", "head": "Elder Miki", "kind": "Snow-fishing tribe"},
		"produces": ["fish", "whale_oil"], "desc": "The last camp before open ocean, where a tribe of forty fishes through the ice and owes nobody."},
	"aqpik_shelf": {"name": "Aqpik Shelf", "type": "village", "faction": "aqpik_shelf", "pos": Vector2(674, 1090), "culture": "south", "community": {"fealty": "kanguq", "head": "Elder Saqpik", "kind": "Berry-gathering tribe"},
		"produces": ["sea_prunes", "furs"], "desc": "A tribe on the western shelf that gathers cloudberries in the short summer and pays the Kanguq in jam."},
	"puyuq_bay": {"name": "Puyuq Bay", "type": "village", "faction": "puyuq_bay", "pos": Vector2(800, 1040), "culture": "south", "community": {"fealty": "southern_water", "head": "Elder Nuka", "kind": "Seal-hunting tribe"},
		"produces": ["seal_jerky", "whale_oil"], "desc": "Smoke-houses around a bay full of seals. Its tribe votes with Wolf's Crown because Wolf's Crown buys its seal oil."},
	"natsiq_rocks": {"name": "Natsiq Rocks", "type": "village", "faction": "natsiq_rocks", "pos": Vector2(916, 1076), "culture": "south", "community": {"fealty": "whalebone", "head": "Elder Tiguak", "kind": "Raiding tribe"},
		"produces": ["seal_jerky", "fish"], "desc": "A rocky hold whose young people crew Qannik's canoes and whose elders wish they would not."},
	"amaruq_fold": {"name": "Amaruq Fold", "type": "village", "faction": "amaruq_fold", "pos": Vector2(848, 1122), "culture": "south", "community": {"fealty": "", "head": "Elder Amka", "kind": "Wolf-herding tribe"},
		"produces": ["furs", "seal_jerky"], "desc": "A tribe that keeps tame wolves on the eastern shelf and keeps out of everyone's council."},
	"tikaani": {"name": "Tikaani Camp", "type": "village", "faction": "tikaani", "pos": Vector2(966, 1136), "culture": "south", "community": {"fealty": "", "head": "Elder Sura", "kind": "Whaling tribe"},
		"produces": ["whale_oil", "furs"], "desc": "Whalers at the far end of the southern ice. They sell oil to the Earth coast and have opinions about every price."},
	"reedmere": {"name": "Reedmere", "type": "village", "faction": "reedmere", "pos": Vector2(1332, 624), "culture": "swamp", "community": {"fealty": "", "head": "Elder Moss-Hand", "kind": "Fen tribe"},
		"produces": ["herbs", "fish"], "desc": "Stilt houses in the Weeping Fen, a second marsh of waterbenders where the eastern river spreads before the sea. They and the Foggy Swamp's people know of each other and argue about whose swamp is older."},
	"lantern_fen": {"name": "Lantern Fen", "type": "village", "faction": "lantern_fen", "pos": Vector2(1360, 632), "culture": "swamp", "community": {"fealty": "", "head": "Elder Sloe", "kind": "Fen tribe"},
		"produces": ["herbs", "pottery"], "desc": "Marsh-lights drift over this fen village at night. Its people say they are only gas. They say it very firmly."},
	"tidehall": {"name": "Tidehall", "type": "castle", "faction": "pearl_isles", "pos": Vector2(1024, 912), "owner": "kallik", "walls": 1.1, "culture": "swamp", "troops_culture": "south",
		"produces": [], "desc": "The Pearl Isles' moot-hall on stilts over a lagoon, where the League's captains meet at low tide and stop when their feet get wet."},
	"shellbay": {"name": "Shellbay", "type": "village", "faction": "pearl_isles", "pos": Vector2(944, 902), "bound": "tidehall", "culture": "swamp", "troops_culture": "south",
		"produces": ["fish", "sea_prunes"], "desc": "Pearl-divers' houses on a white-sand isle. The pearls go north to Ba Sing Se; the divers' lungs stay here."},
	"kelp_rock": {"name": "Kelp Rock", "type": "village", "faction": "pearl_isles", "pos": Vector2(1072, 902), "bound": "tidehall", "culture": "swamp", "troops_culture": "south",
		"produces": ["fish", "salt"], "desc": "Kelp racks on a black rock. The kelp is eaten, burned, sold and, by the young, worn."},
	"gull_rock": {"name": "Gull Rock", "type": "village", "faction": "gull_rock", "pos": Vector2(564, 858), "culture": "swamp", "troops_culture": "south", "community": {"fealty": "", "head": "Elder Avik", "kind": "Island tribe"},
		"produces": ["fish", "salt"], "desc": "A rock in the open sea between the Fire Islands and the Patola peaks. Its tribe of waterbenders has refused the clans, the royal house and the Moon Council, in that order."},
	"oyster_isle": {"name": "Oyster Isle", "type": "village", "faction": "oyster_isle", "pos": Vector2(902, 832), "culture": "swamp", "troops_culture": "south", "community": {"fealty": "", "head": "Elder Kaya", "kind": "Island tribe"},
		"produces": ["fish", "sea_prunes"], "desc": "A low isle off Hamakaze where water-tribe families farm oysters and trade with the Tide Wardens."},
	"tern_isle": {"name": "Tern Isle", "type": "village", "faction": "tern_isle", "pos": Vector2(524, 888), "culture": "swamp", "troops_culture": "south", "community": {"fealty": "", "head": "Elder Ilu", "kind": "Island tribe"},
		"produces": ["fish", "salt"], "desc": "A wind-scoured isle south of the Sun Warriors' jungle. Terns, fishers and nothing else."},
	"driftwood_key": {"name": "Driftwood Key", "type": "village", "faction": "driftwood_key", "pos": Vector2(1398, 496), "culture": "swamp", "troops_culture": "south", "community": {"fealty": "", "head": "Elder Oki", "kind": "Island tribe"},
		"produces": ["fish", "whale_oil"], "desc": "A key off the eastern coast built entirely from what the sea brings, including, once, a whole ship."},
	"kelp_isle": {"name": "Kelp Isle", "type": "village", "faction": "kelp_isle", "pos": Vector2(1170, 860), "culture": "swamp", "troops_culture": "south", "community": {"fealty": "pearl_isles", "head": "Elder Nauk", "kind": "Island tribe"},
		"produces": ["fish", "sea_prunes"], "desc": "The Pearl Isles' easternmost friend, which pays the League in dried kelp and is protected in return."},

	# Air Temples (cannot be besieged; free healing and shelter)
	"southern_air_temple": {"name": "Southern Air Temple", "type": "temple", "faction": "air_south", "pos": Vector2(696, 870), "culture": "air", "abbot": "Abbot Dorje",
		"produces": ["tea"], "desc": "A temple of monks on the peaks of the Patola range. Sky bison graze its terraces, and refugees from three wars sleep in its courtyards."},
	"northern_air_temple": {"name": "Northern Air Temple", "type": "temple", "faction": "air_north", "pos": Vector2(972, 188), "culture": "air", "abbot": "Abbot Lhakpa",
		"produces": ["herbs"], "desc": "The highest of the temples, a monks' retreat of wind-chimes and cold stone. Its gliders can be seen for miles."},
	"eastern_air_temple": {"name": "Eastern Air Temple", "type": "temple", "faction": "air_east", "pos": Vector2(1490, 694), "culture": "air", "abbot": "Abbess Tsering",
		"produces": ["tea", "herbs"], "desc": "A temple of nuns among mountain peaks, whose archives hold letters from every Avatar who ever visited."},
	"western_air_temple": {"name": "Western Air Temple", "type": "temple", "faction": "air_west", "pos": Vector2(530, 268), "culture": "air", "abbot": "Abbess Yeshe",
		"produces": ["herbs"], "desc": "A nuns' temple built upside-down beneath a cliff edge, hidden from anyone who does not already know where to look."},

	# Ruins and landmarks
	"wan_shi_tong": {"name": "Wan Shi Tong's Library", "type": "ruin", "faction": "neutral", "pos": Vector2(1158, 594), "culture": "air",
		"produces": [], "desc": "The tower of a great library peeks out from the desert sands. Its owl spirit trades knowledge for knowledge, and never at a loss."},
	"cinder_monastery": {"name": "The Cinder Monastery", "type": "ruin", "faction": "neutral", "pos": Vector2(280, 528), "culture": "fire", "dlc": "fire",
		"produces": [], "desc": "A monastery of firebending monks high on a dormant volcano. They keep a flame that has not gone out in nine hundred years and argue about whether that is the point."},
	"two_lovers": {"name": "Cave of Two Lovers", "type": "ruin", "faction": "neutral", "pos": Vector2(974, 618), "culture": "earth",
		"produces": [], "desc": "The maze of tunnels under the Kolau Mountains where Oma and Shu, the first earthbenders, learned from the badgermoles. Bards sing about it; badgermoles still rearrange it."},
	"red_lantern_den": {"name": "Red Lantern Den", "type": "ruin", "faction": "red_lanterns", "pos": Vector2(1010, 512), "culture": "earth",
		"produces": [], "desc": "Stilt houses hidden in a reed marsh by the river, lit by red paper lanterns. The Brotherhood watches every barge that passes."},
}

# The land itself (coasts, mountains, rivers, biomes) is drawn in
# tools/make_world.py and baked into assets/world/; see scripts/core/terrain.gd.

# Bandit spawn points: [pos, troop pool, faction, label]
var bandit_spawns := [
	{"pos": Vector2(880, 320), "troops": ["pirate", "pirate", "pirate_captain"], "faction": "bandits", "name": "River Pirates"},
	{"pos": Vector2(1150, 780), "troops": ["pirate", "pirate", "pirate_captain"], "faction": "bandits", "name": "River Pirates"},
	{"pos": Vector2(760, 840), "troops": ["pirate", "pirate"], "faction": "bandits", "name": "Sea Raiders"},
	{"pos": Vector2(1040, 250), "troops": ["mountain_bandit"], "faction": "bandits", "name": "Mountain Bandits"},
	{"pos": Vector2(1250, 600), "troops": ["mountain_bandit"], "faction": "bandits", "name": "Mountain Bandits"},
	{"pos": Vector2(1000, 620), "troops": ["mountain_bandit", "merc_archer"], "faction": "bandits", "name": "Highwaymen"},
	{"pos": Vector2(1130, 600), "troops": ["sand_raider", "sand_raider", "sand_chief"], "faction": "bandits", "name": "Sandbenders"},
	{"pos": Vector2(360, 600), "troops": ["fn_deserter", "mountain_bandit"], "faction": "bandits", "name": "Deserters"},
	{"pos": Vector2(420, 680), "troops": ["fn_deserter"], "faction": "bandits", "name": "Deserters"},
	{"pos": Vector2(1010, 512), "troops": ["red_lantern", "red_lantern", "red_lantern_elder"], "faction": "red_lanterns", "name": "Red Lantern Brothers"},
]

## A tavern rumour suited to the era: the Drowned Testament's rumours belong
## to the Quiet Years; sandbox eras gossip about a living Avatar instead.
func rumor() -> String:
	var e: String = get_node("/root/GS").flags.get("era", "quiet")
	if e == "quiet":
		return rumors.pick_random()
	var pool: Array = rumors.filter(func(r): return not (r.contains("lost at sea") or r.contains("new Avatar") or r.contains("Lantern")))
	pool.append_array(era_rumors.get(e, []))
	return pool.pick_random()

const era_rumors := {
	"young": [
		"The new Avatar's a Southern girl. Sixteen. They say she threw up on the Fire Sages' boat and then apologised to the boat.",
		"Every earthbending master in the Kingdom is pretending not to hope the Avatar picks them. My cousin's teacher bought a new robe. Just in case.",
		"The Avatar was at a fishing village last week, arguing with a dead man. Out loud. The fishermen took sides.",
	],
	"prime": [
		"Avatar Lei Shan slept in a hayloft in Tanshui Village last month and paid for it by fixing every roof. People are hoping he comes back. Their roofs, I mean.",
		"They say the Avatar walked into a siege camp, sat down between the lines, and asked both generals what their mothers would think. It worked. That's the frightening part.",
		"The Avatar's husband makes pots in the Jade Terraces and won't move to a temple. Says the Avatar can come home for dinner like everyone else.",
		"You never find the Avatar. The Avatar finds you. Pray it's for the good reason.",
	],
	"elder": [
		"Avatar Akane hasn't left the Boiling Lake Hamlet since spring. She teaches three children to breathe before they burn, and argues with the lake about its temperature.",
		"The old Avatar only travels for real evil now. Last time she came out, a warlord's castle became a very nice orchard.",
		"My grandfather met Avatar Akane when she was young. He says she was terrifying. He says she's still terrifying, just slower.",
	],
}

var rumors := [
	"Eleven years since the Avatar was lost at sea, and still nobody will say whose fault it was. Everyone knows, of course. Everyone knows something different.",
	"Somewhere there's a child who's the new Avatar and doesn't know it. Five more years, the sages say. I hope there's a world left to hand them.",
	"The Fire Sages keep a record of a day, long ago, when the sun went black over the islands. They won't say what happened that day. Firebenders don't like to ask.",
	"My grandmother says the Great Comet comes back once in a hundred years, and every firebender alive goes half mad with it. My grandmother says a lot of things.",
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
	"The Tide Wardens of Hamakaze are fishers first and soldiers on the bad days. Captain Oyama refused the Earth Queen's summons three times. Politely.",
	"King Feng Tao gives a speech every morning from the palace steps. Omashu loves it. Ba Sing Se hates it. The pigeons are neutral.",
	"An old woman in green plays Pai Sho in the tea houses and never loses. She asks people about lotus tiles. Odd.",
	"Under a full moon, a waterbender can do things you would not believe. Under a lunar eclipse they're ordinary waterbenders again, and they sulk.",
	"The castellan of Boiling Lake Keep teaches the garrison's children to read. The officers call it soft. Her soldiers desert less than anyone's.",
]

# World events on a fixed schedule: political beats of the Quiet Years, not
# destiny. "campaign" makes a faction march on a target if still at war;
# "effect" triggers special handling in the world simulation.
var world_events := [
	{"day": 4, "text": "Admiral Kuro's fleet tightens its blockade of the Strait. Earth Kingdom merchants are turned back at sea."},
	{"day": 18, "text": "General Lu Kang marches from Shanzhai Fortress to end the Omashu Secession by force.", "campaign": ["earth_kingdom", "stonewatch"], "leaders": ["lu_kang"]},
	{"day": 35, "text": "Southern raiders burn a Fire Navy supply convoy off Whaletail Island. Admiral Kuro swears revenge."},
	{"day": 55, "text": "In Caldera, Crown Princess Ryoko calls openly for peace talks. Admiral Kuro calls for more ships. The Fire Lord says nothing in public."},
	{"day": 80, "text": "Earth Kingdom marines cross the strait in fishing boats to take back Kettle Rock.", "campaign": ["earth_kingdom", "kettle_rock"], "leaders": ["tan_yue"]},
	{"day": 110, "text": "The Northern council debates sending warriors to aid the South. Commander Iluq argues for war; Chief Tulok listens.", "effect": "north_debate"},
	{"day": 140, "text": "Omashu's couriers carry rumours of a secret letter between Caldera and Omashu. Ba Sing Se doubles its patrols on every road."},
	{"day": 175, "text": "A hard winter is coming, the farmers say. Every army will be hungry before spring.", "effect": "hard_winter"},
]

# Fighters in Gaoling's Stone Pit, in the order you face them.
var arena_fighters := [
	{"name": "Pebble Wen", "bend": "earth", "power": 1.1, "hp": 90, "armor": 6, "skill": 45, "weapon": "fists", "prize": 120,
		"culture": "earth", "vlook": {"sex": "m", "accessory": "bandana"}},
	{"name": "The Strait Isles Kid", "bend": "fire", "power": 1.0, "hp": 100, "armor": 8, "skill": 55, "weapon": "fists", "prize": 200,
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
	_init_communities()
	for lid in lords:
		var f: String = lords[lid].faction
		if not KINGDOMS.has(f):
			KINGDOMS.append(f)

## Each settlement with a "community" entry is a faction of its own: a village
## that answers to its elders, and pays tribute to an overlord or to no one.
func _init_communities() -> void:
	const REGION_OF := {"fire": "fire", "north": "water", "south": "water", "swamp": "water", "air": "air"}
	for sid in settlements:
		var d: Dictionary = settlements[sid]
		if not d.has("community"):
			continue
		var c: Dictionary = d.community
		var base: Color = {"fire": Color(0.62, 0.38, 0.3), "north": Color(0.42, 0.55, 0.68), "south": Color(0.4, 0.5, 0.6), "swamp": Color(0.35, 0.5, 0.45)}.get(d.culture, Color(0.5, 0.52, 0.36))
		# a stable per-village shade, so neighbours can be told apart on the map
		var h := float(absi(hash(sid)) % 1000) / 1000.0
		factions[sid] = {
			"name": d.name, "short": d.name, "color": base.lightened(h * 0.3 - 0.1),
			"trim": Color(0.9, 0.88, 0.8), "culture": d.culture, "king": "", "capital": sid,
			"region": c.get("region", REGION_OF.get(d.culture, "earth")), "kind": c.get("kind", "Community"),
			"fealty": c.get("fealty", ""), "head": c.get("head", "the elders"), "community": true,
			"desc": d.desc,
		}

## Region heading for a faction ("fire", "earth", "water", "air", "outlaw", "").
func region_of(f: String) -> String:
	return factions.get(f, {}).get("region", "")

## Factions at peace with everyone, always (the Air Nomads and their temples).
func is_peaceful(f: String) -> bool:
	return factions.get(f, {}).get("peaceful", false) or f == "neutral"

## The settlement a power's lords think of as home, or "".
func seat_of(f: String) -> String:
	return factions.get(f, {}).get("capital", "")

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
	# Earthbenders can thicken a fief's walls (Roots of the Mountain masonry)
	var bonus := 0.0
	var gs = get_node_or_null("/root/GS")
	if gs != null and gs.settlements.has(sid):
		bonus = float(gs.settlements[sid].get("wall_bonus", 0.0))
	# The Sun Warriors' dragons defend their city as long as it is theirs
	if settlements.get(sid, {}).get("dragons", false) and gs != null and gs.settlements.has(sid) and gs.settlements[sid].faction == settlements[sid].faction:
		bonus += 1.2
	return float(settlements.get(sid, {}).get("walls", 1.0)) + bonus

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
