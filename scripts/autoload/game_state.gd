extends Node
## Mutable game state, calendar, player helpers, save/load and the glue
## between the world map and battles. Autoloaded as "GS".

signal message(text: String, color: Color)
signal player_encounter(party_id: String)
signal player_arrived(settlement_id: String)
signal state_loaded

const Roster = preload("res://scripts/core/roster.gd")
const WorldSim = preload("res://scripts/core/world_sim.gd")
const Economy = preload("res://scripts/core/economy.gd")
const Quests = preload("res://scripts/core/quests.gd")
const AutoResolve = preload("res://scripts/core/auto_resolve.gd")

const SAVE_PATH := "user://savegame.sav"
const AUTOSAVE_PATH := "user://autosave.sav"
const SETTINGS_PATH := "user://settings.cfg"

const SEASONS := ["Winter", "Spring", "Summer", "Autumn"]
const DAYS_PER_SEASON := 90
const ECLIPSE_DAY := 251     # Day of Black Sun (summer, 100 AG)
const COMET_DAY := 268       # Sozin's Comet (end of summer, 100 AG)

const SKILLS := ["ironflesh", "power_strike", "weapon_mastery", "archery", "athletics", "riding",
	"bending", "leadership", "trade", "tactics", "healing", "pathfinding", "trainer"]
const SKILL_ATTR := {
	"ironflesh": "str", "power_strike": "str", "trainer": "str",
	"weapon_mastery": "agi", "archery": "agi", "athletics": "agi", "riding": "agi",
	"bending": "int", "tactics": "int", "healing": "int", "pathfinding": "int",
	"leadership": "cha", "trade": "cha",
}
const SKILL_DESC := {
	"ironflesh": "Each point adds 4 hit points.",
	"power_strike": "Each point adds 8% melee damage.",
	"weapon_mastery": "Faster attacks and better blocking.",
	"archery": "Ranged damage and accuracy.",
	"athletics": "Running speed on foot.",
	"riding": "Mount speed and handling.",
	"bending": "Bending damage, chi pool and chi regeneration. Benders only.",
	"leadership": "Party size, morale and lower wages.",
	"trade": "Better prices when trading.",
	"tactics": "Better auto-resolve results and a larger battle advantage.",
	"healing": "Wounded troops recover faster and fewer die in battle.",
	"pathfinding": "Faster travel on the world map.",
	"trainer": "Troops in your party gain experience every day.",
}

var hours: float = 8.0
var player: Dictionary = {}
var parties: Dictionary = {}
var settlements: Dictionary = {}
var lords: Dictionary = {}
var relations: Dictionary = {}      # "a|b" -> "war" | "peace"
var campaigns: Dictionary = {}      # faction -> {target, until}
var quests: Array = []
var log_lines: Array = []
var flags: Dictionary = {}
var next_id: int = 1
var pending_battle: Dictionary = {}
var last_battle_result: Dictionary = {}
var game_active := false

var settings := {
	"battle_size": 80, "difficulty": 1, "auto_block": true, "mouse_sens": 0.25,
	"invert_y": false, "volume": 0.7,
}

var sim

func _ready() -> void:
	randomize()
	sim = WorldSim.new()
	_register_inputs()
	load_settings()

# ---------------------------------------------------------------------------
# Input map (registered in code so the project needs no editor setup)
# ---------------------------------------------------------------------------
func _register_inputs() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE], "bend_primary": [KEY_Q], "bend_secondary": [KEY_E],
		"bend_special": [KEY_R], "weapon_melee": [KEY_1], "weapon_ranged": [KEY_2],
		"order_hold": [KEY_F1], "order_follow": [KEY_F2], "order_charge": [KEY_F3],
		"order_fire_at_will": [KEY_F4], "battle_end": [KEY_TAB], "camera_toggle": [KEY_V],
		"pause_menu": [KEY_ESCAPE], "map_party": [KEY_P], "map_character": [KEY_C],
		"map_inventory": [KEY_I], "map_quests": [KEY_J], "map_factions": [KEY_N],
		"map_camp": [KEY_T], "map_pause": [KEY_SPACE], "map_fast": [KEY_CTRL],
		"walk": [KEY_SHIFT],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	var mouse := {"attack": MOUSE_BUTTON_LEFT, "block": MOUSE_BUTTON_RIGHT}
	for action in mouse:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var mb := InputEventMouseButton.new()
		mb.button_index = mouse[action]
		InputMap.action_add_event(action, mb)

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		for k in settings:
			settings[k] = cf.get_value("game", k, settings[k])
	apply_settings()

func save_settings() -> void:
	var cf := ConfigFile.new()
	for k in settings:
		cf.set_value("game", k, settings[k])
	cf.save(SETTINGS_PATH)
	apply_settings()

func apply_settings() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(0.001, float(settings.volume))))

# ---------------------------------------------------------------------------
# Character creation
# ---------------------------------------------------------------------------
const BACKGROUNDS := {
	"ek_refugee": {"name": "Earth Kingdom Refugee", "start": "omashu", "bends": ["earth", ""],
		"attrs": {"str": 1, "cha": 1}, "skills": {"athletics": 1, "trade": 1}, "gold": 350,
		"equip": {"weapon": "staff", "armor": "peasant_clothes", "helmet": "straw_hat"},
		"troops": [["ek_peasant", 4]], "goods": {"rice": 6, "cabbages": 4},
		"desc": "Your village burned when the Fire Nation came. You walked to Omashu with nothing but a staff and a grudge."},
	"fn_deserter": {"name": "Fire Nation Deserter", "start": "fire_fountain", "bends": ["fire", ""],
		"attrs": {"str": 1, "agi": 1}, "skills": {"weapon_mastery": 1, "tactics": 1}, "gold": 300,
		"equip": {"weapon": "dao", "armor": "peasant_clothes"}, "rel": {"fire_nation": -5},
		"troops": [["fn_conscript", 2]], "goods": {"fire_flakes": 6, "rice": 4},
		"desc": "You served in the Fire Nation army until you could no longer stomach what it did. Now you wander, hoping no one recognises you."},
	"swt_warrior": {"name": "Southern Water Tribe Warrior", "start": "southern_tribe", "bends": ["water", ""],
		"attrs": {"str": 1, "agi": 1}, "skills": {"archery": 1, "pathfinding": 1}, "gold": 250,
		"equip": {"weapon": "war_club", "ranged": "boomerang", "armor": "water_parka", "helmet": "parka_hood"},
		"troops": [["swt_villager", 4]], "goods": {"seal_jerky": 6, "sea_prunes": 4},
		"desc": "The men of your tribe sailed to war years ago. You were left behind to guard the village — until now."},
	"nwt_noble": {"name": "Northern Water Tribe Noble", "start": "agna_qela", "bends": ["water", ""],
		"attrs": {"int": 1, "cha": 1}, "skills": {"leadership": 1, "healing": 1}, "gold": 700,
		"equip": {"weapon": "spear", "armor": "water_parka"},
		"troops": [["nwt_hunter", 3]], "goods": {"seal_jerky": 5, "fish": 5},
		"desc": "Born behind the ice walls of Agna Qel'a, you leave the safety of the North to see the war for yourself."},
	"merchant": {"name": "Wandering Merchant", "start": "ba_sing_se", "bends": ["earth", ""],
		"attrs": {"cha": 2}, "skills": {"trade": 2, "pathfinding": 1}, "gold": 1300,
		"equip": {"weapon": "jian", "armor": "peasant_clothes", "helmet": "straw_hat"},
		"troops": [["merc_archer", 2]], "goods": {"tea": 4, "rice": 6},
		"desc": "You have hauled goods from one end of the Earth Kingdom to the other. War is bad for most — but not for trade."},
	"kyoshi": {"name": "Kyoshi Island Trainee", "start": "kyoshi_island", "bends": [""],
		"attrs": {"agi": 2}, "skills": {"weapon_mastery": 2, "athletics": 1}, "gold": 250,
		"equip": {"weapon": "kyoshi_fans", "armor": "kyoshi_armor"},
		"troops": [["ky_initiate", 3]], "goods": {"fish": 6, "rice": 4},
		"desc": "Trained in the dojo of Kyoshi Island, you leave with your fans and face paint to defend those who cannot defend themselves."},
}

func create_player(pname: String, background: String, bend: String, skin: Color, hair: Color) -> Dictionary:
	var bg: Dictionary = BACKGROUNDS[background]
	var p := {
		"name": pname, "background": background, "bend": bend,
		"attrs": {"str": 5, "agi": 5, "int": 5, "cha": 5},
		"skills": {}, "level": 1, "xp": 0, "attr_points": 2, "skill_points": 4,
		"hp": 1, "gold": bg.gold, "renown": 0, "honor": 0, "morale": 70.0, "victory_morale": 0.0,
		"equip": {"weapon": "fists", "ranged": "", "armor": "", "helmet": "", "mount": ""},
		"items": [], "goods": bg.goods.duplicate(), "faction": "", "status": "",
		"faction_rel": {}, "wars": [], "companions": [], "companion_state": {},
		"start": bg.start, "captive_until": -1.0, "look": {"skin": skin, "hair": hair},
	}
	for s in SKILLS:
		p.skills[s] = 0
	for a in bg.attrs:
		p.attrs[a] += bg.attrs[a]
	for s in bg.skills:
		p.skills[s] += bg.skills[s]
	if bend != "":
		p.skills.bending = 2
	for slot in bg.equip:
		p.equip[slot] = bg.equip[slot]
	for f in bg.get("rel", {}):
		p.faction_rel[f] = bg.rel[f]
	var troops := []
	for t in bg.troops:
		Roster.add(troops, t[0], t[1])
	p.start_troops = troops
	return p

# ---------------------------------------------------------------------------
# New game
# ---------------------------------------------------------------------------
func new_game(p: Dictionary) -> void:
	hours = 8.0
	parties = {}
	settlements = {}
	lords = {}
	relations = {}
	campaigns = {}
	quests = []
	log_lines = []
	flags = {}
	next_id = 1
	pending_battle = {}
	player = p
	# Kingdom relations: the Fire Nation is at war with everyone.
	for a in Data.KINGDOMS:
		for b in Data.KINGDOMS:
			if a < b:
				relations[_rel_key(a, b)] = "war" if (a == "fire_nation" or b == "fire_nation") else "peace"
	for id in Data.settlements:
		var d: Dictionary = Data.settlements[id]
		var s := {
			"id": id, "faction": d.faction, "owner": d.get("owner", ""),
			"prosperity": 50.0 + randf() * 20.0, "garrison": [], "prices": {},
			"volunteers": 0, "siege": {}, "looted_until": -1.0, "relation": 0,
			"explored": false, "last_visit": -1.0, "tavern": {},
		}
		if d.type == "town":
			s.garrison = _make_garrison(d.culture, 200)
		elif d.type == "castle":
			s.garrison = _make_garrison(d.culture, 110)
		if d.type == "village":
			s.volunteers = 4 + randi() % 6
		for g in Data.goods:
			s.prices[g] = 1.0
		settlements[id] = s
	# Give lords their fiefs' ownership if not set explicitly
	for id in Data.settlements:
		var d: Dictionary = Data.settlements[id]
		if d.type == "village" and d.has("bound"):
			settlements[id].owner = settlements[d.bound].owner
	for id in Data.lords:
		var l: Dictionary = Data.lords[id]
		lords[id] = {"id": id, "faction": l.faction, "party": "", "respawn_at": 0.0, "relation": 0, "renown": 100}
	Economy.init_prices()
	# Player party
	var pp := make_party("player", player.name + "'s Party", "player", "player", Data.settlements[player.start].pos + Vector2(6, 6))
	pp.roster = p.get("start_troops", [])
	pp.erase("start_troops")
	player.erase("start_troops")
	# Lords' parties
	for id in lords:
		sim.spawn_lord(id, 1.0)
	# Initial bandits, caravans, Team Avatar
	for i in 3:
		for sp in Data.bandit_spawns.size():
			if randf() < 0.6:
				sim.spawn_bandit(sp)
	for id in Data.settlements:
		if Data.settlements[id].type == "town" and randf() < 0.7:
			sim.spawn_caravan(id)
	sim.spawn_team_avatar()
	for id in settlements:
		Economy.refresh_tavern(id)
	player.hp = max_hp()
	sim.reset_clock()
	game_active = true
	log_msg("Winter, 99 AG. The Hundred Year War rages on. Somewhere, the Avatar has returned.", Color(1, 0.85, 0.5))

func _make_garrison(culture: String, size: int) -> Array:
	var r := []
	var base: String = Data.culture_recruit.get(culture, "ek_peasant")
	var pool := _culture_tree(base)
	for i in size:
		var t: String = pool[mini(pool.size() - 1, int(pow(randf(), 2.0) * pool.size()))]
		Roster.add(r, t, 1)
	return r

## All troops reachable from a base troop via upgrades, ordered by tier.
func _culture_tree(base: String) -> Array:
	var out := [base]
	var i := 0
	while i < out.size():
		for u in Data.troop(out[i]).upgrades:
			if not out.has(u):
				out.append(u)
		i += 1
	out.sort_custom(func(a, b): return Data.troop(a).tier < Data.troop(b).tier)
	return out

func culture_tree(culture: String) -> Array:
	return _culture_tree(Data.culture_recruit.get(culture, "ek_peasant"))

func make_party(id: String, name: String, kind: String, faction: String, pos: Vector2) -> Dictionary:
	if id == "":
		id = "p%d" % next_id
		next_id += 1
	var p := {
		"id": id, "name": name, "kind": kind, "faction": faction, "lord": "",
		"pos": pos, "target": pos, "target_party": "", "target_settlement": "",
		"state": "idle", "roster": [], "prisoners": [], "gold": 0, "home": "",
		"next_think": 0.0, "wait_until": 0.0, "spawn": -1, "quest": "", "speed_mult": 1.0,
		"moving": false,
	}
	parties[id] = p
	return p

func new_id(prefix: String = "q") -> String:
	next_id += 1
	return "%s%d" % [prefix, next_id]

# ---------------------------------------------------------------------------
# Calendar
# ---------------------------------------------------------------------------
func day() -> int:
	return int(hours / 24.0)

func hour_of_day() -> float:
	return fmod(hours, 24.0)

func is_daytime() -> bool:
	var h := hour_of_day()
	return h >= 6.0 and h < 19.0

func moon_phase() -> float:
	## 0 = new moon, 0.5 = full moon
	return fmod(float(day() + 7) / 28.0, 1.0)

func is_full_moon() -> bool:
	return absf(moon_phase() - 0.5) < 0.04

func is_eclipse() -> bool:
	return day() == ECLIPSE_DAY and hour_of_day() >= 9.0 and hour_of_day() < 13.0

func is_comet() -> bool:
	return day() >= COMET_DAY and day() <= COMET_DAY + 2

func day_name(d: int) -> String:
	var year := 99 + int((d + 270) / 360)
	var season_name: String = SEASONS[int(d / DAYS_PER_SEASON) % 4]
	return "%s, day %d, %d AG" % [season_name, d % DAYS_PER_SEASON + 1, year]

func date_string() -> String:
	return "%s — %02d:00" % [day_name(day()), int(hour_of_day())]

func moon_string() -> String:
	var p := moon_phase()
	if is_full_moon():
		return "Full Moon"
	if p < 0.06 or p > 0.94:
		return "New Moon"
	return "Waxing Moon" if p < 0.5 else "Waning Moon"

## Multiplier for bending of an element at the current world time.
func bending_mult(element: String) -> float:
	match element:
		"fire", "blue_fire":
			if is_eclipse():
				return 0.0
			var m := 1.15 if is_daytime() else 0.85
			if is_comet():
				m *= 3.0
			return m
		"water":
			var m := 1.15 if not is_daytime() else 0.95
			if is_full_moon() and not is_daytime():
				m *= 1.5
			return m
	return 1.0

func season() -> String:
	return SEASONS[int(day() / DAYS_PER_SEASON) % 4]

# ---------------------------------------------------------------------------
# Messages
# ---------------------------------------------------------------------------
func log_msg(text: String, color: Color = Color(0.95, 0.92, 0.85)) -> void:
	log_lines.append({"t": text, "c": color, "d": day()})
	if log_lines.size() > 200:
		log_lines.pop_front()
	message.emit(text, color)

# ---------------------------------------------------------------------------
# Factions and hostility
# ---------------------------------------------------------------------------
func _rel_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a

func player_faction() -> String:
	if player.get("faction", "") != "":
		return player.faction
	return "player"

func party_faction(p: Dictionary) -> String:
	if p.id == "player":
		return player_faction()
	return p.faction

func at_war(a: String, b: String) -> bool:
	if a == b:
		return false
	if a == "team_avatar" or b == "team_avatar" or a == "neutral" or b == "neutral":
		return false
	if a == "bandits" or b == "bandits":
		return true
	if a == "freedom_fighters" or b == "freedom_fighters":
		var other := b if a == "freedom_fighters" else a
		if other == "fire_nation":
			return true
		if other == "player":
			return int(player.get("faction_rel", {}).get("freedom_fighters", 0)) < -10
		return false
	if a == "player" or b == "player":
		var other := b if a == "player" else a
		return int(player.get("faction_rel", {}).get(other, 0)) <= -10 or player.get("wars", []).has(other)
	return relations.get(_rel_key(a, b), "peace") == "war"

func parties_hostile(a: Dictionary, b: Dictionary) -> bool:
	return at_war(party_faction(a), party_faction(b))

func declare_war(a: String, b: String) -> void:
	if a == "player" or b == "player":
		var other := b if a == "player" else a
		if not player.has("wars"):
			player.wars = []
		if not player.wars.has(other):
			player.wars.append(other)
		return
	if relations.get(_rel_key(a, b), "") != "war":
		relations[_rel_key(a, b)] = "war"
		log_msg("%s has declared war on %s!" % [Data.factions[a].name, Data.factions[b].name], Color(1, 0.4, 0.3))

func make_peace(a: String, b: String) -> void:
	if a == "player" or b == "player":
		var other := b if a == "player" else a
		if player.has("wars"):
			player.wars.erase(other)
		player.faction_rel[other] = maxi(0, int(player.faction_rel.get(other, 0)))
		return
	if relations.get(_rel_key(a, b), "") == "war":
		relations[_rel_key(a, b)] = "peace"
		log_msg("%s and %s have agreed to a truce." % [Data.factions[a].name, Data.factions[b].name], Color(0.6, 0.9, 1))

func change_faction_rel(faction: String, amount: int) -> void:
	if not Data.factions.has(faction) or faction == "player":
		return
	var fr: Dictionary = player.faction_rel
	fr[faction] = clampi(int(fr.get(faction, 0)) + amount, -100, 100)

func change_lord_rel(lord_id: String, amount: int) -> void:
	if lords.has(lord_id):
		lords[lord_id].relation = clampi(lords[lord_id].relation + amount, -100, 100)

func is_king(lid: String) -> bool:
	if lid == "zuko" and flags.get("fn_king", "") == "zuko":
		return true
	if lid == "ozai" and flags.get("fn_king", "") == "zuko":
		return false
	return Data.lords.get(lid, {}).get("king", false)

func faction_settlements(faction: String) -> Array:
	var out := []
	for id in settlements:
		if settlements[id].faction == faction:
			out.append(id)
	return out

func faction_lords(faction: String) -> Array:
	var out := []
	for id in lords:
		if lords[id].faction == faction:
			out.append(id)
	return out

# ---------------------------------------------------------------------------
# Player helpers
# ---------------------------------------------------------------------------
func player_party() -> Dictionary:
	return parties.get("player", {})

func skill(name: String) -> int:
	var v: int = player.skills.get(name, 0)
	# Companion bonuses
	for c in player.companions:
		var cd: Dictionary = Data.companions.get(c, {})
		v += int(cd.get("bonus", {}).get(name, 0)) if name in ["healing", "pathfinding", "trainer", "tactics", "leadership"] else 0
	return v

func skill_cap(name: String) -> int:
	return int(player.attrs[SKILL_ATTR[name]] / 2)

func max_hp() -> int:
	return 35 + player.attrs.str * 2 + player.skills.ironflesh * 4 + player.level

func max_chi() -> float:
	return 60.0 + player.attrs.int * 3.0 + player.skills.bending * 8.0

func party_limit() -> int:
	var l: int = 12 + skill("leadership") * 5 + player.attrs.cha + int(player.renown / 25)
	if player.get("status", "") == "vassal":
		l += 10
	return l

func prisoner_limit() -> int:
	return 6 + skill("leadership") * 3

func party_size() -> int:
	return Roster.total(player_party().roster) + player.companions.size() + 1

func xp_for_level(lvl: int) -> int:
	return int(250.0 * pow(float(lvl), 1.6))

func give_player_xp(amount: int) -> void:
	player.xp += amount
	while player.xp >= xp_for_level(player.level):
		player.xp -= xp_for_level(player.level)
		player.level += 1
		player.attr_points += 1
		player.skill_points += 1 + int(player.attrs.int / 6)
		log_msg("You have reached level %d! (C to spend points)" % player.level, Color(1, 0.9, 0.4))

func add_gold(amount: int) -> void:
	player.gold = maxi(0, player.gold + amount)

func add_renown(amount: int) -> void:
	player.renown = maxi(0, player.renown + amount)

func add_good(id: String, n: int) -> void:
	player.goods[id] = maxi(0, int(player.goods.get(id, 0)) + n)
	if player.goods[id] == 0:
		player.goods.erase(id)

func goods_count() -> int:
	var c := 0
	for g in player.goods:
		c += player.goods[g]
	return c

func food_units() -> int:
	var c := 0
	for g in player.goods:
		if Data.goods[g].food:
			c += player.goods[g]
	return c

func food_days() -> float:
	var per_day := maxf(1.0, ceil(party_size() / 5.0))
	return food_units() / per_day

func player_strength() -> float:
	return Roster.power(player_party().roster) + 8.0 + player.level * 0.5 + player.companions.size() * 6.0

## Total armour of the player's equipment.
func player_armor() -> int:
	var a := 0
	for slot in ["armor", "helmet"]:
		var id: String = player.equip.get(slot, "")
		if id != "":
			a += int(Data.item(id).get("armor", 0))
	return a

## A defeated lord kept in your party until ransomed or released.
func capture_lord(lid: String) -> void:
	if not player.has("captive_lords"):
		player.captive_lords = []
	if not player.captive_lords.has(lid):
		player.captive_lords.append(lid)
	lords[lid].held = true

func release_lord(lid: String, ransomed: bool) -> void:
	player.captive_lords.erase(lid)
	lords[lid].held = false
	lords[lid].respawn_at = hours + 48.0
	if ransomed:
		add_gold(lord_ransom(lid))
		log_msg("%s has been ransomed for %d gold." % [Data.lords[lid].name, lord_ransom(lid)], Color(0.9, 0.85, 0.4))
	else:
		change_lord_rel(lid, 15)
		player.honor = player.get("honor", 0) + 2
		log_msg("You released %s. They will remember your mercy." % Data.lords[lid].name, Color(0.6, 1, 0.6))

func lord_ransom(lid: String) -> int:
	return 400 + int(Data.lords[lid].troops * 6)

func companion_state(id: String) -> Dictionary:
	if not player.companion_state.has(id):
		player.companion_state[id] = {"wounded": false}
	return player.companion_state[id]

# ---------------------------------------------------------------------------
# Battle handoff
# ---------------------------------------------------------------------------
## Start a player battle. `enemy_ids` are party ids on the enemy side,
## `ally_ids` additional friendly parties. `siege` is a settlement id when
## assaulting or defending walls.
func start_battle(enemy_ids: Array, ally_ids: Array = [], siege: String = "", player_attacking: bool = true) -> void:
	var pp := player_party()
	var biome: String = sim.biome_at(pp.pos)
	pending_battle = {
		"enemies": enemy_ids, "allies": ally_ids, "siege": siege,
		"player_attacking": player_attacking, "biome": biome,
		"hour": hour_of_day(), "fire_mult": bending_mult("fire"), "water_mult": bending_mult("water"),
		"enemy_garrison": siege != "" and player_attacking,
		"ally_garrison": siege != "" and not player_attacking,
	}
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

## Earth Rumble arena fight (round index into Data.arena_fighters).
func start_arena(round_i: int) -> void:
	pending_battle = {"arena": round_i, "enemies": [], "allies": [], "siege": "", "player_attacking": true,
		"biome": "highland", "hour": 20.0, "fire_mult": bending_mult("fire"), "water_mult": bending_mult("water"),
		"enemy_garrison": false, "ally_garrison": false}
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

func finish_arena(won: bool, round_i: int, player_hp: float) -> void:
	var f: Dictionary = Data.arena_fighters[round_i]
	player.hp = maxi(1, int(player_hp))
	var lines := []
	if won:
		add_gold(f.prize)
		add_renown(3 + round_i * 3)
		give_player_xp(100 + round_i * 150)
		flags.arena_round = round_i + 1
		lines.append("You defeated %s! The crowd roars. (+%d gold)" % [f.name, f.prize])
		if round_i == Data.arena_fighters.size() - 1:
			lines.append("You are the new Earth Rumble champion! Xin Fu can barely believe it.")
			add_renown(30)
			flags.arena_round = 0
			flags.arena_champion = true
	else:
		flags.arena_round = 0
		lines.append("%s threw you out of the ring. Better luck next time." % f.name)
	last_battle_result = {"won": won, "lines": lines, "prisoners": [], "goods": {}, "items": []}
	pending_battle = {}

## Called by the battle scene. `casualties` maps party id (or "garrison:<sid>")
## to {troop_id: {"killed": n, "wounded": n}}.
func finish_battle(won: bool, casualties: Dictionary, player_downed: bool, companions_downed: Array, power_lost_extra: float = 0.0) -> void:
	var b := pending_battle
	var result := {"won": won, "lines": [], "prisoners": [], "loot_gold": 0, "goods": {}, "items": []}
	# Apply casualties
	var enemy_power_lost := power_lost_extra
	for pid in casualties:
		var roster: Array = _roster_for_key(pid)
		var is_enemy: bool = b.enemies.has(pid) or (pid.begins_with("garrison:") and b.enemy_garrison)
		for tid in casualties[pid]:
			var c: Dictionary = casualties[pid][tid]
			var killed: int = c.get("killed", 0)
			var wounded: int = c.get("wounded", 0)
			if is_enemy:
				enemy_power_lost += Data.troop_power(tid) * (killed + wounded)
			if pid == "player":
				# Healing skill converts some deaths into wounds
				var saved := 0
				for i in killed:
					if randf() < 0.15 + skill("healing") * 0.04:
						saved += 1
				killed -= saved
				wounded += saved
			Roster.remove(roster, tid, killed)
			Roster.wound(roster, tid, wounded)
	for cid in companions_downed:
		companion_state(cid).wounded = true
	if player_downed:
		player.hp = maxi(1, int(max_hp() * 0.15))
	if won:
		# Take prisoners from wounded enemies, gather loot, defeat parties
		var xp_total := int(enemy_power_lost * 12.0) + 20
		var renown_gain := int(clampf(enemy_power_lost / 6.0, 1.0, 40.0))
		var defeated_lords := []
		for pid in b.enemies:
			if parties.has(pid) and parties[pid].lord != "":
				defeated_lords.append(parties[pid].lord)
		for pid in b.enemies:
			if not parties.has(pid):
				continue
			var ep: Dictionary = parties[pid]
			for s in ep.roster:
				if s.w > 0 and Roster.total(player_party().prisoners) < prisoner_limit():
					var take: int = mini(s.w, prisoner_limit() - Roster.total(player_party().prisoners))
					if take > 0 and not Data.troop(s.id).hero:
						Roster.add(player_party().prisoners, s.id, take, take)
						result.prisoners.append([s.id, take])
			# Free prisoners the enemy held (they join as captives you may recruit)
			for s in ep.prisoners:
				Roster.add(player_party().roster, s.id, s.n, s.w)
				result.lines.append("Freed %d %s held by the enemy." % [s.n, Data.troop(s.id).name])
			result.loot_gold += int(ep.gold * 0.5) + int(enemy_power_lost * 3.0 * randf_range(0.6, 1.2) / maxf(1.0, b.enemies.size()))
			if ep.kind == "caravan":
				for i in 3:
					var g: String = Data.goods.keys().pick_random()
					result.goods[g] = int(result.goods.get(g, 0)) + 1 + randi() % 3
			if randf() < 0.35:
				var tid := Roster.random_troop(ep.roster, false)
				if tid != "":
					var cand: Array = [Data.troop(tid).weapon, Data.troop(tid).ranged]
					cand = cand.filter(func(x): return x != "" and x != "fists")
					if not cand.is_empty():
						result.items.append(cand.pick_random())
			if ep.lord != "" and randf() < 0.6:
				capture_lord(ep.lord)
				result.lines.append("%s has been taken prisoner!" % Data.lords[ep.lord].name)
			sim.on_party_defeated(pid, "player")
		# Siege won
		if b.siege != "" and b.player_attacking:
			sim.capture_settlement(b.siege, player_faction(), "player")
			result.lines.append("%s is yours! Its walls stand empty — leave troops there with \"Manage the garrison\"." % Data.settlements[b.siege].name)
		elif b.siege != "" and not b.player_attacking:
			settlements[b.siege].siege = {}
			change_faction_rel(settlements[b.siege].faction, 5)
			result.lines.append("The siege of %s is broken!" % Data.settlements[b.siege].name)
		add_gold(result.loot_gold)
		for g in result.goods:
			add_good(g, result.goods[g])
		for it in result.items:
			player.items.append(it)
		give_player_xp(xp_total)
		add_renown(renown_gain)
		Roster.give_xp(player_party().roster, int(xp_total / 6))
		for aid in b.get("allies", []):
			if parties.has(aid) and parties[aid].lord != "":
				change_lord_rel(parties[aid].lord, 4)
				result.lines.append("%s is grateful for your help." % Data.lords[parties[aid].lord].name)
		result.lines.push_front("Victory! +%d gold, +%d renown, +%d experience." % [result.loot_gold, renown_gain, xp_total])
		Quests.on_battle_won(b.enemies, defeated_lords)
	else:
		result.lines.append("You have been defeated.")
		_player_defeated(b)
	last_battle_result = result
	pending_battle = {}

## The player left the field: casualties stand, but there is no capture.
func retreat_battle(casualties: Dictionary, companions_downed: Array) -> void:
	var b := pending_battle
	for pid in casualties:
		var roster: Array = _roster_for_key(pid)
		for tid in casualties[pid]:
			var c: Dictionary = casualties[pid][tid]
			Roster.remove(roster, tid, c.get("killed", 0))
			Roster.wound(roster, tid, c.get("wounded", 0))
	for cid in companions_downed:
		companion_state(cid).wounded = true
	for pid in b.get("enemies", []):
		if parties.has(pid):
			parties[pid].ignore_player_until = hours + 3.0
			parties[pid].target_party = ""
	player.morale = maxf(0.0, player.morale - 10.0)
	last_battle_result = {"won": false, "lines": ["You retreated from the battle. Your men are shaken."], "prisoners": [], "goods": {}, "items": []}
	log_msg("You retreated from the battle.", Color(1, 0.6, 0.4))
	pending_battle = {}

func _roster_for_key(key: String) -> Array:
	if key.begins_with("garrison:"):
		return settlements[key.substr(9)].garrison
	if parties.has(key):
		return parties[key].roster
	return []

func _player_defeated(b: Dictionary) -> void:
	var pp := player_party()
	var lost_gold := int(player.gold * 0.3)
	add_gold(-lost_gold)
	# Most healthy troops scatter; wounded are captured.
	var lost := 0
	for s in pp.roster.duplicate():
		var gone: int = s.w + int((s.n - s.w) * 0.5)
		lost += Roster.remove(pp.roster, s.id, gone, true)
	# Enemy takes back its prisoners
	pp.prisoners.clear()
	player.hp = maxi(1, int(max_hp() * 0.2))
	add_renown(-5)
	if b.get("siege", "") != "" and b.get("player_attacking", false):
		settlements[b.siege].siege = {}
	if b.get("siege", "") != "" and not b.get("player_attacking", false):
		var att: Array = b.enemies
		if not att.is_empty() and parties.has(att[0]):
			sim.capture_settlement(b.siege, parties[att[0]].faction, parties[att[0]].lord)
	player.captive_until = hours + 24.0 + randf() * 48.0
	log_msg("You were defeated and taken captive. You lost %d gold and %d troops." % [lost_gold, lost], Color(1, 0.4, 0.3))

## Auto-resolve from the encounter menu (player not fighting personally).
func auto_resolve_player(enemy_ids: Array, ally_ids: Array = [], siege: String = "", player_attacking: bool = true) -> Dictionary:
	var side_a := ["player"] + ally_ids
	var garrison_a := ""
	var garrison_b := ""
	if siege != "":
		if player_attacking:
			garrison_b = siege
		else:
			garrison_a = siege
	var res := AutoResolve.resolve(side_a, enemy_ids, garrison_a, garrison_b, skill("tactics"))
	var won: bool = res.winner == "a"
	pending_battle = {"enemies": enemy_ids, "allies": ally_ids, "siege": siege, "player_attacking": player_attacking,
		"enemy_garrison": siege != "" and player_attacking, "ally_garrison": siege != "" and not player_attacking}
	# AutoResolve already applied casualties; reuse finish_battle for rewards.
	finish_battle(won, {}, false, [], res.power_lost_b)
	last_battle_result.lines.append_array(res.lines)
	return last_battle_result

# ---------------------------------------------------------------------------
# Save / load
# ---------------------------------------------------------------------------
func save_game(path: String = SAVE_PATH) -> bool:
	var data := {
		"version": 1, "hours": hours, "player": player, "parties": parties,
		"settlements": settlements, "lords": lords, "relations": relations,
		"campaigns": campaigns, "quests": quests, "log": log_lines.slice(-60),
		"flags": flags, "next_id": next_id,
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(var_to_str(data))
	f.close()
	return true

func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

func load_game(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	var data = str_to_var(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	hours = data.hours
	player = data.player
	parties = data.parties
	settlements = data.settlements
	lords = data.lords
	relations = data.relations
	campaigns = data.campaigns
	quests = data.quests
	log_lines = data.log
	flags = data.flags
	next_id = data.next_id
	pending_battle = {}
	sim.reset_clock()
	game_active = true
	state_loaded.emit()
	return true
