extends Node
## Canon checks (docs/canon.md). Every rule here is one the series states and
## the game once broke: names from Aang's era or later, the Avatar in the
## Spirit World, Fire Nation land on the mainland, cross-nation conquest,
## recurring solar eclipses, more than one Great Comet, the cycle's order.
const AvatarSys = preload("res://scripts/core/avatar.gd")
const Terrain = preload("res://scripts/core/terrain.gd")

## Names and things the series dates to Kyoshi's lifetime or later, or that it
## credits to someone else (docs/canon.md §2). Matched case-insensitively in
## every non-comment line of every script.
const FORBIDDEN := ["Kyoshi", "Dai Li", "Laogai", "Chin Village", "Chin the", "Taku", "Pohuai",
	"Boiling Rock", "Sozin", "Hundred Year War", "Iroh", "White Lotus", "Joo Dee", "Long Feng",
	"Earth Rumble", "Ember Island Players", "air scooter", "bloodbend", "metalbend", "Spirit World",
	"Healing Breath", "First Flame.\" (the mastery", "solar eclipse", "Day of Black Sun", "colonies"]

var errors := 0

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_canon.gd").new())
		return
	_names()
	_map()
	_sieges()
	_sky()
	_avatar()
	print("CANON TEST DONE, errors: ", errors)
	get_tree().quit()

func _err(msg: String) -> void:
	errors += 1
	print("  ERROR: ", msg)

func _scripts(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_scripts(dir.path_join(d), out)

func _names() -> void:
	var files := []
	_scripts("res://scripts", files)
	var hits := 0
	for path in files:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			var line: String = lines[i].strip_edges()
			if line.begins_with("#"):
				continue
			for word in FORBIDDEN:
				if line.findn(word) >= 0:
					_err("%s:%d uses '%s'" % [path, i + 1, word])
					hits += 1
	print("names: %d scripts scanned, %d forbidden uses" % [files.size(), hits])

## The Strait Isles, claimed by both crowns (docs/canon.md §9).
const DISPUTED := ["kettle_rock", "fire_navy_harbor", "tieshan", "navy_docks"]

## No Fire Islands faction starts with a holding on the mainland; the Strait
## Isles are islands; Hamakaze is still joined to the mainland.
func _map() -> void:
	Terrain.ensure()
	for sid in Data.settlements:
		var d: Dictionary = Data.settlements[sid]
		if Data.region_of(d.faction) == "fire" and not DISPUTED.has(sid) and d.pos.x > 500.0:
			_err("Fire Islands holding %s stands east of the Fire Islands" % sid)
	for sid in DISPUTED:
		var p: Vector2 = Data.settlements[sid].pos
		var gap := false
		for k in range(1, 40):
			if not Terrain.is_land(p + Vector2(k * 4.0, 0.0)):
				gap = true
				break
		if not gap:
			_err("disputed %s is joined to the mainland" % sid)
	var a: Vector2 = Data.settlements.hamakaze.pos
	var b := Vector2(850, 720)
	for k in 21:
		if not Terrain.is_land(a.lerp(b, k / 20.0)):
			_err("Hamakaze is cut off from the mainland at %s (Kyoshi has not separated it yet)" % a.lerp(b, k / 20.0))
			break
	print("map: checked Fire Nation holdings, the Strait Isles and the Hamakaze neck")

## The factions hang together: every settlement, lord and tribute names a
## faction that exists; every power has a head; the four temples are of the
## Air Nomads and never at war; the Sun Warriors are left alone by sane rulers.
func _sieges() -> void:
	var n := 0
	for sid in Data.settlements:
		n += 1
		if not Data.factions.has(Data.settlements[sid].faction):
			_err("%s belongs to unknown faction %s" % [sid, Data.settlements[sid].faction])
	for lid in Data.lords:
		if not Data.factions.has(Data.lords[lid].faction) or not Data.settlements.has(Data.lords[lid].home):
			_err("lord %s has an unknown faction or home" % lid)
	for f in Data.KINGDOMS:
		var king: String = Data.factions[f].get("king", "")
		if not Data.lords.has(king) or Data.lords[king].faction != f:
			_err("power %s has no head among its lords" % f)
	for f in Data.factions:
		var fe: String = Data.factions[f].get("fealty", "")
		if fe != "" and not fe in Data.KINGDOMS:
			_err("%s pays tribute to %s, which is not a power" % [f, fe])
	var temples := Data.settlement_ids_of_type("temple")
	if temples.size() != 4:
		_err("there should be four Air Temples, found %d" % temples.size())
	for sid in temples:
		var f: String = Data.settlements[sid].faction
		if not Data.is_peaceful(f) or Data.factions[f].get("people", "") != "air_nomads":
			_err("%s is not a peaceful Air Nomad temple" % sid)
	if not Data.factions.sun_warriors.get("protected", false):
		_err("the Sun Warriors are not protected")
	GS.new_game(GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1)))
	if GS.sim._reckless("fire_nation", "sun_warriors"):
		_err("the royal house would march on the Sun Warriors at the start")
	if not Data.settlements.sun_city.get("dragons", false) or Data.walls("sun_city") < 2.5:
		_err("the Sun Warriors' city is not defended by dragons")
	print("factions: %d settlements, %d powers, %d factions" % [n, Data.KINGDOMS.size(), Data.factions.size()])

## The Great Comet at most once a game and in about a third of games; no
## solar eclipses; a lunar eclipse never takes waterbending away.
func _sky() -> void:
	var with_comet := 0
	for i in 300:
		GS.schedule_cosmic_events()
		var comets := 0
		for e in GS.flags.cosmic:
			if e.kind == "solar":
				_err("a solar eclipse was scheduled")
				return
			if e.kind == "comet":
				comets += 1
		if comets > 1:
			_err("the Great Comet came twice in one game")
			return
		with_comet += comets
	if with_comet < 60 or with_comet > 140:
		_err("the Great Comet came in %d of 300 games (expected about 100)" % with_comet)
	print("sky: Great Comet in %d of 300 games, no solar eclipses" % with_comet)

## The Avatar is never placed in the Spirit World; the cycle and learning
## order hold in every era.
func _avatar() -> void:
	if AvatarSys.CYCLE != ["fire", "air", "water", "earth"]:
		_err("the Avatar cycle is out of order")
	for e in ["quiet", "young", "prime", "elder"]:
		var p := GS.create_player("Tester", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1), e)
		GS.new_game(p)
		GS.flags.seen_help = true
		GS.flags.dlg_queue = []
		var A: Dictionary = AvatarSys.state()
		var nation: String = A.nation
		var expect := []
		for k in range(1, 4):
			expect.append(AvatarSys.CYCLE[(AvatarSys.CYCLE.find(nation) + k) % 4])
		var learned_and_left: Array = A.mastered.duplicate() + A.order
		if e != "prime" and e != "elder" and A.order != expect:
			_err("era %s: learning order %s, cycle says %s" % [e, A.order, expect])
		if learned_and_left.size() != 4:
			_err("era %s: the Avatar's elements do not add up to four" % e)
		for i in 200:
			GS.hours += 24.0
			AvatarSys.daily()
			if String(AvatarSys.state().get("loc", "")) == "spirit":
				_err("era %s: the Avatar was placed in the Spirit World" % e)
				break
	print("avatar: cycle, learning order and whereabouts checked in four eras")
