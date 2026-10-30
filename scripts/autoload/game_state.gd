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
const Story = preload("res://scripts/story/story.gd")
const AvatarSys = preload("res://scripts/core/avatar.gd")

const SAVE_PATH := "user://savegame.sav"
const AUTOSAVE_PATH := "user://autosave.sav"
const SETTINGS_PATH := "user://settings.cfg"

const SEASONS := ["Winter", "Spring", "Summer", "Autumn"]
const DAYS_PER_SEASON := 90

## Attributes, after Dark Souls 3's, with Spirit in place of Faith. Points
## come from levels (two per level) and a few deeds. Everything the game used
## to call a skill is now worked out from these (skill()).
const ATTRS := ["vig", "att", "end", "vit", "str", "dex", "int", "spi", "lck"]
const ATTR_NAME := {"vig": "Vigor", "att": "Attunement", "end": "Endurance", "vit": "Vitality", "str": "Strength",
	"dex": "Dexterity", "int": "Intelligence", "spi": "Spirit", "lck": "Luck"}
const ATTR_DESC := {
	"vig": "Health and the will to keep standing.",
	"att": "Bending and chi: the main root of every art. Means nothing to a non-bender's fists.",
	"end": "Running, marching and enduring. Earth's patience lives here.",
	"vit": "Toughness and presence; the confidence others follow. Fire draws on it.",
	"str": "Melee damage and drilling troops. Fire draws on it.",
	"dex": "Weapon skill, archery and riding. Air draws on it, and water's flow.",
	"int": "Tactics, command, trade and medicine. Water's adaptability lives here.",
	"spi": "How spiritual you are: attention to spirits, sacred places and stillness. Even a great deal of it does not make an ordinary person a bridge to the spirits; that is the Avatar's, and only the rarest old masters come near it. Air draws on its detachment.",
	"lck": "Bargains, finds and the odd escape.",
}
const BASE_ATTR := 8
## Each element's bending draws on Attunement (60%) and two other attributes.
const ELEMENT_ATTRS := {"earth": ["end", "vig"], "water": ["int", "dex"], "air": ["dex", "spi"], "fire": ["str", "vit"]}
## Old skills, now derived: the attributes they average.
const DERIVED := {
	"ironflesh": ["vig"], "power_strike": ["str"], "trainer": ["str", "int"],
	"weapon_mastery": ["dex"], "archery": ["dex"], "athletics": ["end"], "riding": ["dex", "end"],
	"leadership": ["vit", "int"], "trade": ["int", "lck"], "tactics": ["int"], "healing": ["int"],
	"pathfinding": ["end", "int"], "spotting": ["int", "lck"], "surgery": ["int"],
	"engineer": ["int"], "prisoner_management": ["vit"],
}
const SKILLS := ["ironflesh", "power_strike", "weapon_mastery", "archery", "athletics", "riding",
	"bending", "leadership", "trade", "tactics", "healing", "surgery", "pathfinding", "spotting",
	"trainer", "engineer", "prisoner_management"]
## Warband's party skills: the player raises them with party points (one a
## level), and a companion's knack adds to the party's.
const PARTY_SKILLS := ["leadership", "trainer", "healing", "surgery", "pathfinding", "spotting",
	"tactics", "trade", "engineer", "prisoner_management"]
## Most party points one skill can take: grows with level, as Warband ties
## skills to their attribute.
const PARTY_POINT_CAP := 10
const SKILL_DESC := {
	"ironflesh": "Extra hit points.",
	"power_strike": "Melee damage.",
	"weapon_mastery": "Faster attacks and better blocking.",
	"archery": "Ranged damage and accuracy.",
	"athletics": "Running speed on foot.",
	"riding": "Mount speed and handling.",
	"bending": "Bending damage, chi pool and chi regeneration. Benders only.",
	"leadership": "Party size, morale and lower wages.",
	"trade": "Better prices when trading.",
	"tactics": "Better auto-resolve results and a larger battle advantage.",
	"healing": "Wounded troops recover faster between battles.",
	"surgery": "Troops struck down in battle are more often only wounded, not killed.",
	"pathfinding": "Faster travel on the world map.",
	"spotting": "See parties on the world map from farther away.",
	"trainer": "Troops in your party gain experience every day.",
	"engineer": "Siege ladders and towers are ready sooner.",
	"prisoner_management": "More prisoners can be kept in your train.",
}

var hours: float = 8.0
var player: Dictionary = {}
var parties: Dictionary = {}
var settlements: Dictionary = {}
var lords: Dictionary = {}
var relations: Dictionary = {}      # "a|b" -> "war" | "peace"
var campaigns: Dictionary = {}      # faction -> {target, until}
var fealty: Dictionary = {}         # faction -> the faction it pays tribute to
var quests: Array = []
var log_lines: Array = []
var flags: Dictionary = {}
var next_id: int = 1
var pending_battle: Dictionary = {}
var last_battle_result: Dictionary = {}
var game_active := false

var settings := {
	"battle_size": 80, "difficulty": 1, "auto_block": true, "mouse_sens": 0.25,
	"invert_y": false, "volume": 0.7, "music": 0.5, "fullscreen": false,
	"ui_scale": 1.0, "plain_speech": false, "reduce_flashing": false, "reduce_motion": false, "readable_font": false,
	"dlc_fire": true, "dlc_water": true, "dlc_earth": true, "dlc_air": true,
	"retro": "heavy",
	"map_style": "painted",
	"gore": true,
}

## Pixel textures (shaders/ps1.gdshaderinc): texels per metre on every
## surface. Only textures are pixelated: vertices are not snapped to a screen
## grid and textures are not warped, so people and shapes stay clear.
const RETRO := {
	"off": {"snap": 0.0, "texel": 0.0, "affine": 0.0},
	"light": {"snap": 0.0, "texel": 80.0, "affine": 0.0},
	"heavy": {"snap": 0.0, "texel": 40.0, "affine": 0.0},
}

## The PS1 look (shaders/ps1.gdshaderinc): vertex grid across the screen,
## texels per metre on every surface, and how far UV-mapped textures go affine.

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
	var r: Dictionary = RETRO.get(String(settings.get("retro", "heavy")), RETRO.heavy)
	RenderingServer.global_shader_parameter_set("ps1_snap", r.snap)
	RenderingServer.global_shader_parameter_set("ps1_texel_m", r.texel)
	RenderingServer.global_shader_parameter_set("ps1_affine", r.affine)
	if is_inside_tree():
		get_tree().root.content_scale_factor = clampf(float(settings.get("ui_scale", 1.0)), 0.75, 1.6)
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(0.001, float(settings.volume))))
	var music := get_node_or_null("/root/Music")
	if music:
		music.apply_volume()
	if DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want and not (want == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED):
			DisplayServer.window_set_mode(want)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		settings.fullscreen = not settings.fullscreen
		save_settings()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and game_active and pending_battle.is_empty():
		save_game(AUTOSAVE_PATH)

# ---------------------------------------------------------------------------
# Character creation
# ---------------------------------------------------------------------------
const BACKGROUNDS := {
	"ek_refugee": {"name": "Strait Isles Refugee", "start": "omashu", "bends": ["earth", ""], "standing": "commoner",
		"attrs": {"end": 1, "vit": 2, "str": 2, "lck": 1}, "gold": 350,
		"equip": {"weapon": "staff", "armor": "peasant_clothes", "helmet": "straw_hat"},
		"troops": [["ek_peasant", 4]], "goods": {"rice": 6, "cabbages": 4}, "rel": {"fire_nation": -5},
		"desc": "The Admiralty came to 'protect' your village in the Strait Isles and stayed until there was nothing left to protect. You crossed the strait in a borrowed boat with a staff, four neighbours and a grudge, and Omashu let you in when Ba Sing Se would not."},
	"lower_ring": {"name": "Lower Ring Labourer", "start": "ba_sing_se", "bends": ["earth", ""], "standing": "commoner",
		"attrs": {"vig": 1, "str": 5}, "gold": 200,
		"equip": {"weapon": "axe", "armor": "peasant_clothes"},
		"troops": [["ek_peasant", 5]], "goods": {"rice": 8},
		"desc": "You hauled stone in Ba Sing Se's Lower Ring for eleven years and never once saw the Upper Ring's gates open for someone like you. You are done waiting for them to."},
	"fn_deserter": {"name": "Fire Nation Deserter", "start": "fire_fountain", "bends": ["fire", ""], "standing": "commoner",
		"attrs": {"str": 2, "dex": 3, "int": 1}, "gold": 300,
		"equip": {"weapon": "dao", "armor": "peasant_clothes"}, "rel": {"fire_nation": -5},
		"troops": [["fn_conscript", 2]], "goods": {"fire_flakes": 6, "rice": 4},
		"desc": "You were conscripted for the Strait Isles and served until the day you were ordered to burn a granary with a family still inside. You walked away that night, and two others walked with you."},
	"fn_noble": {"name": "Fire Nation Minor Noble", "start": "caldera", "bends": ["fire", ""], "standing": "gentry",
		"attrs": {"vit": 3, "dex": 1, "int": 2}, "gold": 900,
		"equip": {"weapon": "jian", "armor": "peasant_clothes"}, "rel": {"fire_nation": 5},
		"troops": [["fn_soldier", 3]], "goods": {"fire_flakes": 4, "rice": 4},
		"desc": "Your house is old, small and deeply in debt. Your mother wants you to marry well; your creditors want their money; you want to be more than a name on a terraced wall in Caldera."},
	"swt_warrior": {"name": "Southern Raider", "start": "southern_tribe", "bends": ["water", ""], "standing": "commoner",
		"attrs": {"end": 1, "str": 2, "dex": 3}, "gold": 450,
		"equip": {"weapon": "war_club", "ranged": "boomerang", "armor": "water_parka", "helmet": "parka_hood"},
		"troops": [["swt_villager", 5], ["swt_warrior", 2]], "goods": {"seal_jerky": 6, "sea_prunes": 4}, "rel": {"fire_nation": -5},
		"desc": "You crewed a raider canoe under Qannik for three winters. Then one night the ship you boarded was full of fishermen, not soldiers. You came home, and you have not gone back out."},
	"nwt_noble": {"name": "Northern Water Tribe Noble", "start": "agna_qela", "bends": ["water", ""], "standing": "gentry",
		"attrs": {"vit": 3, "int": 3}, "gold": 700,
		"equip": {"weapon": "spear", "armor": "water_parka"},
		"troops": [["nwt_hunter", 3]], "goods": {"seal_jerky": 5, "fish": 5},
		"desc": "Born behind the ice walls of Agna Qel'a to a family with a seat on the council, you leave the North to see for yourself the wars it pretends are not its business."},
	"merchant": {"name": "Wandering Merchant", "start": "gaoling", "bends": ["earth", ""], "standing": "citizen",
		"attrs": {"end": 1, "vit": 4, "lck": 2}, "gold": 1300,
		"equip": {"weapon": "jian", "armor": "peasant_clothes", "helmet": "straw_hat"},
		"troops": [["merc_archer", 2]], "goods": {"tea": 4, "rice": 6},
		"desc": "You have hauled goods from one end of the world to the other on credit from the Cheng family. Three wars are bad for most people. You are trying not to be the kind of person they are good for."},
	"air_nomad": {"name": "Air Nomad Wanderer", "start": "southern_air_temple", "bends": ["air", ""], "standing": "commoner",
		"attrs": {"end": 1, "dex": 2, "int": 3}, "gold": 250,
		"equip": {"weapon": "staff", "armor": "nomad_robes"}, "rel": {"air_nomads": 10},
		"troops": [["an_novice", 2]], "goods": {"rice": 4, "cabbages": 4},
		"desc": "The Southern Air Temple raised you to believe all people are one people. At sixteen you took a glider and went to find out whether the world agreed. It mostly does not. You have kept the vows so far. The temple will hear if you stop."},
	"temple_courier": {"name": "Temple Courier", "start": "eastern_air_temple", "bends": ["air", ""], "standing": "citizen",
		"attrs": {"end": 2, "vit": 2, "dex": 3}, "gold": 400,
		"equip": {"weapon": "staff", "armor": "nomad_robes"}, "rel": {"air_nomads": 5},
		"troops": [["an_novice", 1]], "goods": {"tea": 2, "rice": 6},
		"desc": "For six years you carried letters between the four temples and every court that would receive a monk: by bison, on foot, once on a very confused ostrich horse. Every gate opens for a temple courier. You have started to wonder what is in the letters."},
	"hamakaze": {"name": "Tide Warden Trainee", "start": "hamakaze", "bends": [""], "standing": "commoner",
		"attrs": {"end": 1, "dex": 6}, "gold": 250,
		"equip": {"weapon": "warden_glaive", "armor": "tide_armor"},
		"troops": [["tw_initiate", 3]], "goods": {"fish": 6, "rice": 4},
		"desc": "Trained on the beaches of Hamakaze, you leave with a glaive, a white headband and a fisherwoman's opinion of weather. Captain Oyama gave you one instruction: defend those who cannot defend themselves, and never confuse that with conquest."},
}

func create_player(pname: String, background: String, bend: String, skin: Color, hair: Color, era: String = "quiet") -> Dictionary:
	var bg: Dictionary = BACKGROUNDS[background]
	# Every player is a non-bender or a bender of exactly one element. The
	# Avatar is someone else (scripts/core/avatar.gd).
	assert(bend in ["", "fire", "water", "earth", "air"], "the player is never the Avatar")
	var p := {
		"name": pname, "background": background, "bend": bend, "era": era, "infamy": 0, "techniques": [],
		"attrs": {}, "skill_bonus": {}, "level": 1, "xp": 0, "attr_points": 2, "party_points": 2,
		"hp": 1, "gold": bg.gold, "renown": 0, "honor": 0, "morale": 70.0, "victory_morale": 0.0,
		"equip": {"weapon": "fists", "ranged": "", "armor": "", "helmet": "", "mount": ""},
		"items": [], "goods": bg.goods.duplicate(), "faction": "", "status": "",
		"faction_rel": {}, "wars": [], "companions": [], "companion_state": {},
		"start": bg.start, "captive_until": -1.0, "look": {"skin": skin, "hair": hair},
		"standing": bg.get("standing", "commoner"),
	}
	for a in ATTRS:
		p.attrs[a] = BASE_ATTR + int(bg.attrs.get(a, 0))
	if bend != "":
		# a bender has trained their art since childhood
		p.attrs.att += 6
		for a in ELEMENT_ATTRS[bend]:
			p.attrs[a] += 1
	if background in ["air_nomad", "temple_courier"]:
		p.attrs.spi += 3
	if bend != "":
		# every bender starts with one form of their art's martial basis
		var Forms = load("res://scripts/battle/forms.gd")
		var f: Dictionary = Forms.starter(Forms.art_of(bend))
		p.forms = [] if f.is_empty() else [f]
		p.form_f = 0 if not f.is_empty() else -1
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
	fealty = {}
	quests = []
	log_lines = []
	flags = {}
	next_id = 1
	pending_battle = {}
	player = p
	AvatarSys.init_era(String(p.get("era", "quiet")))
	# Kingdom relations: the three wars of the Quiet Years, everyone else at peace.
	for a in Data.KINGDOMS:
		for b in Data.KINGDOMS:
			if a < b:
				relations[_rel_key(a, b)] = "peace"
	for w in Data.STARTING_WARS:
		relations[_rel_key(w[0], w[1])] = "war"
	for f in Data.factions:
		if Data.factions[f].get("fealty", "") != "":
			fealty[f] = Data.factions[f].fealty
	schedule_cosmic_events()
	for id in Data.settlements:
		var d: Dictionary = Data.settlements[id]
		var s := {
			"id": id, "faction": d.faction, "owner": d.get("owner", ""),
			"prosperity": 50.0 + randf() * 20.0, "garrison": [], "prices": {},
			"volunteers": 0, "siege": {}, "looted_until": -1.0, "relation": 0,
			"explored": false, "last_visit": -1.0, "tavern": {},
		}
		var gc: String = d.get("troops_culture", d.culture)
		if d.type == "town":
			s.garrison = _make_garrison(gc, 200)
		elif d.type == "castle":
			s.garrison = _make_garrison(gc, 110)
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
	# Initial bandits, caravans, Air Nomad pilgrims
	for i in 3:
		for sp in Data.bandit_spawns.size():
			if randf() < 0.6:
				sim.spawn_bandit(sp)
	for id in Data.settlements:
		if Data.settlements[id].type == "town" and randf() < 0.7:
			sim.spawn_caravan(id)
	for i in 2:
		sim.spawn_pilgrims()
	for id in settlements:
		Economy.refresh_tavern(id)
	player.hp = max_hp()
	sim.reset_clock()
	game_active = true
	match AvatarSys.era():
		"quiet": log_msg("Winter of the eleventh Quiet Year. Eleven years since the Avatar was lost at sea; somewhere a child who will be the next one does not yet know it. Until then, the world must manage on its own.", Color(1, 0.85, 0.5))
		"young": log_msg("Winter. On Whaletail Island, a sixteen-year-old named Siku has been told she is the Avatar, and has three elements to learn. The world's masters are waiting to see who she comes to.", Color(1, 0.85, 0.5))
		"prime": log_msg("Winter of the twenty-third year of Avatar Lei Shan. The Avatar is everywhere at once: in council halls, in siege camps, in forests nobody else visits. Everywhere except where you are.", Color(1, 0.85, 0.5))
		"elder": log_msg("Winter. Avatar Akane is eighty-four and has not left the Boiling Lake Hamlet since autumn. She teaches, meditates and receives few visitors. The world has learned to manage, mostly.", Color(1, 0.85, 0.5))

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
		for u in Data.troop_upgrades(out[i]):
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

# The sky, held to canon (docs/canon.md §5). The Great Comet passes once a
# century, so it falls inside a playthrough only sometimes (about one game in
# three), and never twice. A total solar eclipse that silences firebending is
# known only twice in all recorded history, so none is scheduled. Lunar
# eclipses happen; canon gives them no effect beyond hiding the full moon,
# so they only cancel its strengthening. Scheduled per new game.
func schedule_cosmic_events() -> void:
	var ev := []
	# lunar eclipses fall on full-moon nights (see moon_phase)
	var d := randi_range(30, 150)
	while d < 720:
		var fm := int(round((d - 7) / 28.0)) * 28 + 7
		ev.append({"kind": "lunar", "day": fm, "from": 21.0, "to": 23.9})
		d += randi_range(140, 260)
	if randf() < 0.33:
		ev.append({"kind": "comet", "day": randi_range(100, 600), "from": 0.0, "to": 24.0, "days": 3})
	ev.sort_custom(func(a, b): return a.day < b.day)
	flags.cosmic = ev

func _cosmic_active(kind: String) -> bool:
	var d := day()
	var h := hour_of_day()
	for e in flags.get("cosmic", []):
		if e.kind != kind:
			continue
		if kind == "comet":
			if d >= e.day and d < e.day + int(e.get("days", 3)):
				return true
		elif d == e.day and h >= e.from and h < e.to:
			return true
	return false

## The next scheduled cosmic event (or an empty dictionary).
func next_cosmic(from_day: int = -1) -> Dictionary:
	var d := day() if from_day < 0 else from_day
	for e in flags.get("cosmic", []):
		if e.day >= d:
			return e
	return {}

func is_eclipse() -> bool:
	return _cosmic_active("solar")

func is_lunar_eclipse() -> bool:
	return _cosmic_active("lunar")

func is_comet() -> bool:
	return _cosmic_active("comet")

func day_name(d: int) -> String:
	var info: Dictionary = AvatarSys.era_info()
	var season_name: String = SEASONS[int(d / DAYS_PER_SEASON) % 4]
	var year: int = int(info.year0) + int(d / 360)
	if AvatarSys.era() == "quiet":
		if AvatarSys.known():
			return "%s, day %d, Year %d of Avatar %s" % [season_name, d % DAYS_PER_SEASON + 1, year - 16, flags.avatar.name]
		return "%s, day %d, Quiet Year %d" % [season_name, d % DAYS_PER_SEASON + 1, year]
	return "%s, day %d, Year %d of Avatar %s" % [season_name, d % DAYS_PER_SEASON + 1, year, flags.get("avatar", {}).get("name", "")]

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
				m *= 2.2
			return m
		"water":
			var m := 1.15 if not is_daytime() else 0.95
			if is_full_moon() and not is_daytime() and not is_lunar_eclipse():
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

## News of the wider world. Everything goes into the chronicle (shown in the
## Factions menu); only what concerns the player reaches the message log:
## events near them, or involving their own faction, their enemies, their
## tributaries, or factions that think strongly of them either way.
func world_msg(text: String, color: Color, factions: Array, pos = null) -> void:
	if not flags.has("chronicle"):
		flags.chronicle = []
	flags.chronicle.append({"t": text, "d": day()})
	if flags.chronicle.size() > 300:
		flags.chronicle.pop_front()
	if _concerns_player(factions, pos):
		log_msg(text, color)

func _concerns_player(factions: Array, pos) -> bool:
	if pos != null and parties.has("player") and (pos as Vector2).distance_to(parties.player.pos) < 260.0:
		return true
	var pf := player_faction()
	for f in factions:
		if f == "player" or f == pf or at_war(pf, f) or abs(faction_rel(f)) >= 15:
			return true
		if fealty.get(f, "") == "player" or fealty.get(f, "") == pf:
			return true
	return false

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
	if Data.is_peaceful(a) or Data.is_peaceful(b):
		return false
	if a == "bandits" or b == "bandits":
		return true
	if a == "red_lanterns" or b == "red_lanterns":
		# The Brotherhood robs the Earth Kingdom's tax barges and no one else,
		# unless you give it cause.
		var other := b if a == "red_lanterns" else a
		if other == "earth_kingdom":
			return true
		if other == "player":
			return int(player.get("faction_rel", {}).get("red_lanterns", 0)) < -10
		return false
	if a == "player" or b == "player":
		var other := b if a == "player" else a
		return int(player.get("faction_rel", {}).get(other, 0)) <= -10 or player.get("wars", []).has(other)
	return relations.get(_rel_key(a, b), "peace") == "war"

func parties_hostile(a: Dictionary, b: Dictionary) -> bool:
	# The Avatar's company quarrels with no one but the player it came for
	if a.get("faction", "") == "avatar" or b.get("faction", "") == "avatar":
		return a.id == "player" or b.id == "player"
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
		world_msg("%s has declared war on %s!" % [Data.factions[a].name, Data.factions[b].name], Color(1, 0.4, 0.3), [a, b])

func make_peace(a: String, b: String) -> void:
	if a == "player" or b == "player":
		var other := b if a == "player" else a
		if player.has("wars"):
			player.wars.erase(other)
		player.faction_rel[other] = maxi(0, int(player.faction_rel.get(other, 0)))
		return
	if relations.get(_rel_key(a, b), "") == "war":
		relations[_rel_key(a, b)] = "peace"
		world_msg("%s and %s have agreed to a truce." % [Data.factions[a].name, Data.factions[b].name], Color(0.6, 0.9, 1), [a, b])

## The player's standing with a faction. A temple's standing includes the
## standing with the Air Nomads as a people.
func faction_rel(faction: String) -> int:
	var fr: Dictionary = player.get("faction_rel", {})
	var r := int(fr.get(faction, 0))
	var people: String = Data.factions.get(faction, {}).get("people", "")
	if people != "":
		r += int(fr.get(people, 0))
	return clampi(r, -100, 100)

func change_faction_rel(faction: String, amount: int) -> void:
	if not Data.factions.has(faction) or faction == "player":
		return
	var fr: Dictionary = player.faction_rel
	fr[faction] = clampi(int(fr.get(faction, 0)) + amount, -100, 100)

func change_lord_rel(lord_id: String, amount: int) -> void:
	if lords.has(lord_id):
		lords[lord_id].relation = clampi(lords[lord_id].relation + amount, -100, 100)

# ---------------------------------------------------------------------------
# Social standing: who will let you through which gate
# ---------------------------------------------------------------------------
const STANDINGS := ["commoner", "citizen", "gentry", "noble"]
const STANDING_NAMES := {"commoner": "Commoner", "citizen": "Citizen", "gentry": "Gentry", "noble": "Noble"}
const STANDING_DESC := {
	"commoner": "Gates close in your face. Ba Sing Se's Lower Ring is open to you; the Middle Ring needs papers.",
	"citizen": "You hold papers, a trade or a name people know. Ba Sing Se's Middle Ring and the guild halls open to you.",
	"gentry": "You are received in halls and may duel Fire Nation nobles. Ba Sing Se's Upper Ring opens to you.",
	"noble": "You hold land in your own right. Kings receive you as a peer, more or less.",
}

## Effective standing: the higher of what you were born to or bought, and
## what your deeds have earned.
func standing_rank() -> int:
	var r := STANDINGS.find(player.get("standing", "commoner"))
	if player.renown >= 80:
		r = maxi(r, 1)
	if player.renown >= 260 or player.get("status", "") == "vassal":
		r = maxi(r, 2)
	for sid in settlements:
		if settlements[sid].owner == "player" and Data.settlements[sid].type in ["town", "castle"]:
			r = maxi(r, 3)
			break
	return maxi(r, 0)

func standing() -> String:
	return STANDINGS[standing_rank()]

func standing_name() -> String:
	return STANDING_NAMES[standing()]

func raise_standing(to: String) -> void:
	if STANDINGS.find(to) > STANDINGS.find(player.get("standing", "commoner")):
		player.standing = to

# ---------------------------------------------------------------------------
# Agni Kai: Fire Nation duels of honour
# ---------------------------------------------------------------------------
## A firebending companion who can stand as your champion, or "".
func agni_kai_champion() -> String:
	for cid in player.companions:
		var c: Dictionary = Data.companions.get(cid, {})
		var cs: Dictionary = player.get("companion_state", {}).get(cid, {})
		# Juro's regained fire lives in his companion state, not his base data
		if cs.get("bend", c.get("bend", "")) == "fire" and not cs.get("wounded", false):
			return cid
	return ""

func start_duel(lid: String) -> void:
	pending_battle = {"arena": -1, "duel": lid, "enemies": [], "allies": [], "siege": "", "player_attacking": true,
		"biome": "volcanic", "hour": 12.0, "fire_mult": bending_mult("fire"), "water_mult": bending_mult("water"),
		"enemy_garrison": false, "ally_garrison": false}
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

## A champion fights in your place; resolved by skill rather than played.
func champion_duel(lid: String, cid: String) -> bool:
	var c: Dictionary = Data.companions[cid]
	var l: Dictionary = Data.lords[lid]
	var pw := float(companion_state(cid).get("power", c.power))
	var mine := pw * (float(c.skill) / 100.0) * float(c.hp) / 130.0
	var theirs := float(l.power) * 0.85 * float(l.hp) / 160.0
	var chance := clampf(0.5 + (mine - theirs) * 0.45, 0.15, 0.85)
	var won := randf() < chance
	_duel_outcome(won, lid, Data.companions[cid].get("short", c.name))
	return won

func finish_duel(won: bool, lid: String, player_hp: float) -> void:
	player.hp = maxi(1, int(player_hp))
	_duel_outcome(won, lid, "")
	pending_battle = {}

func _duel_outcome(won: bool, lid: String, champion: String) -> void:
	var l: Dictionary = Data.lords[lid]
	flags["agni_kai_" + lid] = day()
	if won and champion == "":
		flags["agni_won_" + lid] = true
	if won:
		load("res://scripts/core/ambitions.gd").bump("duels_won")
	var who: String = player.name if champion == "" else champion
	var lines := []
	if won:
		add_renown(20)
		flags.duel_wins = int(flags.get("duel_wins", 0)) + (1 if champion == "" else 0)
		player.honor = int(player.get("honor", 0)) + 2
		change_lord_rel(lid, 10)
		change_faction_rel("fire_nation", 3)
		Story.react("agni_kai_won")
		lines.append("%s stands over %s in the ring. The witnesses bow; the matter is settled with honour. (+20 renown, +2 honour)" % [who, l.name])
		log_msg("%s won an Agni Kai against %s." % [who, l.name], Color(1, 0.75, 0.4))
	else:
		add_renown(-10)
		change_lord_rel(lid, 4)
		lines.append("%s yields to %s. There is no shame in losing an Agni Kai well, the witnesses say. There is some. (-10 renown)" % [who, l.name])
		log_msg("%s lost an Agni Kai against %s." % [who, l.name], Color(1, 0.6, 0.4))
	last_battle_result = {"won": won, "lines": lines, "prisoners": [], "goods": {}, "items": []}

func is_king(lid: String) -> bool:
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

func attr(a: String) -> int:
	return int(player.get("attrs", {}).get(a, BASE_ATTR))

## Level of a derived skill (0 at base attributes, +1 per two points above).
func skill(name: String) -> int:
	var avg := 0.0
	if name == "bending":
		var bend: String = player.get("bend", "")
		if bend == "" or not ELEMENT_ATTRS.has(bend):
			return int(player.get("skill_bonus", {}).get("bending", 0))
		avg = attr("att") * 0.6 + attr(ELEMENT_ATTRS[bend][0]) * 0.2 + attr(ELEMENT_ATTRS[bend][1]) * 0.2
	else:
		var src: Array = DERIVED.get(name, [])
		for a in src:
			avg += attr(a)
		avg = avg / maxf(1.0, src.size()) if not src.is_empty() else float(BASE_ATTR)
	var v: int = clampi(int((avg - BASE_ATTR) / 2.0), 0, 20) + int(player.get("skill_bonus", {}).get(name, 0))
	# Companion bonuses
	for c in player.companions:
		var cd: Dictionary = Data.companions.get(c, {})
		v += int(cd.get("bonus", {}).get(name, 0)) if name in PARTY_SKILLS else 0
	return v

func max_hp() -> int:
	return 20 + attr("vig") * 4 + attr("vit") + player.level * 2

func max_chi() -> float:
	var c: float = 30.0 + attr("att") * 4.0 + skill("bending") * 6.0
	var b: Dictionary = player.get("buffs", {}).get("chi", {})
	if not b.is_empty() and float(b.until) > hours:
		c *= float(b.mult)
	return c

func party_limit() -> int:
	var l: int = 18 + skill("leadership") * 5 + int(player.renown / 25)
	if player.get("status", "") == "vassal":
		l += 10
	return l

func prisoner_limit() -> int:
	return 6 + skill("prisoner_management") * 5 + skill("leadership")

## Party points already put into a skill.
func party_invested(name: String) -> int:
	return int(player.get("skill_bonus", {}).get(name, 0))

## How far party points may raise one skill at this level.
func party_cap() -> int:
	return mini(PARTY_POINT_CAP, 2 + int(player.level / 2))

func can_raise_party_skill(name: String) -> bool:
	return name in PARTY_SKILLS and int(player.get("party_points", 0)) > 0 and party_invested(name) < party_cap()

func raise_party_skill(name: String) -> bool:
	if not can_raise_party_skill(name):
		return false
	player.party_points = int(player.party_points) - 1
	if not player.has("skill_bonus"):
		player.skill_bonus = {}
	player.skill_bonus[name] = party_invested(name) + 1
	return true

func party_size() -> int:
	return Roster.total(player_party().roster) + player.companions.size() + 1

func xp_for_level(lvl: int) -> int:
	return int(250.0 * pow(float(lvl), 1.6))

func give_player_xp(amount: int) -> void:
	player.xp += amount
	while player.xp >= xp_for_level(player.level):
		player.xp -= xp_for_level(player.level)
		player.level += 1
		player.attr_points += 2
		player.party_points = int(player.get("party_points", 0)) + 1
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
	var per_day := maxf(1.0, ceil(party_size() / 10.0))
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
	if not ransomed:
		Story.react("release_lord")
	if ransomed:
		add_gold(lord_ransom(lid))
		log_msg("%s has been ransomed for %d gold." % [Data.lords[lid].name, lord_ransom(lid)], Color(0.9, 0.85, 0.4))
	else:
		change_lord_rel(lid, 15)
		player.honor = player.get("honor", 0) + 2
		log_msg("You released %s. They will remember your mercy." % Data.lords[lid].name, Color(0.6, 1, 0.6))

## Execute a captive lord. The world does not forget it (see the Avatar's
## tyrant motive in scripts/core/avatar.gd).
func execute_lord(lid: String) -> void:
	player.captive_lords.erase(lid)
	var lr: Dictionary = lords[lid]
	lr.held = false
	lr.party = ""
	lr.respawn_at = INF
	lr.retired = true
	for sid in settlements:
		if settlements[sid].owner == lid:
			var others: Array = faction_lords(settlements[sid].faction).filter(func(x): return x != lid and not lords[x].get("retired", false))
			settlements[sid].owner = others.pick_random() if not others.is_empty() else ""
	change_faction_rel(lr.faction, -30)
	for other in faction_lords(lr.faction):
		change_lord_rel(other, -25)
	player.honor = int(player.get("honor", 0)) - 10
	AvatarSys.add_infamy(60, player_party().pos, "executing " + Data.lords[lid].name)
	Story.react("execute")
	log_msg("You executed %s. The %s will never forgive it." % [Data.lords[lid].name, Data.factions[lr.faction].name], Color(1, 0.4, 0.3))

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
	save_game(AUTOSAVE_PATH)
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

## Stone Pit arena fight (round index into Data.arena_fighters).
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
		load("res://scripts/core/ambitions.gd").bump("arena_wins")
		add_gold(f.prize)
		add_renown(3 + round_i * 3)
		give_player_xp(100 + round_i * 150)
		flags.arena_round = round_i + 1
		lines.append("You defeated %s! The crowd roars. (+%d gold)" % [f.name, f.prize])
		if player.get("bend", "") != "":
			flags.duel_wins = int(flags.get("duel_wins", 0)) + 1
		if round_i == Data.arena_fighters.size() - 1:
			lines.append("You are the new champion of the Stone Pit! Madam Gu is already printing posters.")
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
	if won:
		load("res://scripts/core/ambitions.gd").bump("battles_won")
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
				var room := party_limit() - party_size()
				var n: int = mini(s.n, maxi(0, room))
				if n > 0:
					Roster.add(player_party().roster, s.id, n, mini(s.w, n))
					result.lines.append("%d freed %s joined you." % [n, Data.troop(s.id).name])
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
		Story.react("battle_won")
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
	var lost_gold := int(player.gold * 0.2)
	add_gold(-lost_gold)
	# Most healthy troops scatter; wounded are captured.
	var lost := 0
	for s in pp.roster.duplicate():
		var gone: int = s.w + int((s.n - s.w) * 0.3)
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
	if AvatarSys.on_player_defeated(b.get("enemies", [])):
		player.captive_until = hours + 72.0
	for pid in b.get("enemies", []):
		if parties.has(pid):
			parties[pid].target_party = ""
			parties[pid].ignore_player_until = player.captive_until + 12.0
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
## How far from a settlement's centre a resting party counts as inside it
## (its hall, barracks or caravanserai).
func shelter_radius(sid: String) -> float:
	return 8.0 if Data.settlements[sid].type == "village" else 13.0

func save_game(path: String = SAVE_PATH) -> bool:
	var data := {
		"version": 2, "hours": hours, "player": player, "parties": parties,
		"settlements": settlements, "lords": lords, "relations": relations,
		"campaigns": campaigns, "fealty": fealty, "quests": quests, "log": log_lines.slice(-60),
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

## Saves from before the clans, temples and communities: add the new places
## and people, and move the old ones that changed hands in the data to their
## new factions, unless the player has taken them.
const OLD_FACTIONS := ["fire_nation", "earth_kingdom", "omashu", "northern_water", "southern_water", "air_nomads"]

func _migrate_factions() -> void:
	for id in Data.settlements:
		var d: Dictionary = Data.settlements[id]
		if not settlements.has(id):
			settlements[id] = {"id": id, "faction": d.faction, "owner": d.get("owner", ""),
				"prosperity": 55.0, "garrison": [], "prices": {}, "volunteers": 0, "siege": {},
				"looted_until": -1.0, "relation": 0, "explored": false, "last_visit": -1.0, "tavern": {}}
			for g in Data.goods:
				settlements[id].prices[g] = 1.0
			var gc: String = d.get("troops_culture", d.culture)
			if d.type in ["town", "castle"]:
				settlements[id].garrison = _make_garrison(gc, 200 if d.type == "town" else 110)
			elif d.type == "village":
				settlements[id].volunteers = 5
				if d.has("bound"):
					settlements[id].owner = Data.settlements[d.bound].get("owner", "")
		elif settlements[id].owner != "player" and settlements[id].faction in OLD_FACTIONS and not d.faction in OLD_FACTIONS:
			# a place the old factions held that now belongs to a clan, a temple,
			# a tribe or itself
			settlements[id].faction = d.faction
			settlements[id].owner = d.get("owner", settlements[id].owner)
	for id in Data.lords:
		if not lords.has(id):
			lords[id] = {"id": id, "faction": Data.lords[id].faction, "party": "", "respawn_at": 0.0, "relation": 0, "renown": 100}
			sim.spawn_lord(id, 1.0)
		elif lords[id].faction != Data.lords[id].faction and not lords[id].get("retired", false):
			lords[id].faction = Data.lords[id].faction
			if lords[id].party != "" and parties.has(lords[id].party):
				parties[lords[id].party].faction = lords[id].faction
	for w in Data.STARTING_WARS:
		if not relations.has(_rel_key(w[0], w[1])):
			relations[_rel_key(w[0], w[1])] = "war"
	for f in Data.factions:
		if Data.factions[f].get("fealty", "") != "" and not fealty.has(f):
			fealty[f] = Data.factions[f].fealty

## Saves from before the nine attributes: map the old four attributes and
## the skill points onto the new ones.
func _migrate_attributes() -> void:
	var old: Dictionary = player.get("attrs", {})
	if not old.has("agi"):
		return
	var na := {}
	for a in ATTRS:
		na[a] = BASE_ATTR
	na.str += (int(old.get("str", 5)) - 5) * 2
	na.dex += (int(old.get("agi", 5)) - 5) * 2
	na.int += (int(old.get("int", 5)) - 5) * 2
	na.vit += (int(old.get("cha", 5)) - 5) * 2
	var sk: Dictionary = player.get("skills", {})
	na.att += int(sk.get("bending", 0)) * 2
	for s in DERIVED:
		na[DERIVED[s][0]] += int(sk.get(s, 0))
	player.attrs = na
	player.attr_points = int(player.get("attr_points", 0)) + int(player.get("skill_points", 0))
	player.erase("skills")
	player.erase("skill_points")
	player.skill_bonus = {}

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
	fealty = data.get("fealty", {})
	quests = data.quests
	log_lines = data.log
	flags = data.flags
	next_id = data.next_id
	pending_battle = {}
	_migrate_attributes()
	if int(data.get("version", 1)) < 2:
		_migrate_factions()
	AvatarSys.ensure()
	if player.get("companions", []).has("avatar"):
		AvatarSys.register_companion()
	sim.reset_clock()
	game_active = true
	state_loaded.emit()
	return true
