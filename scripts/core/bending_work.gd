extends RefCounted
## Bending outside battle (the element expansions' "work"). Each element has
## six or seven uses in settlements or around camp: forging, kilns, healing
## houses, irrigation, mining, masonry, gliding, sails and more. A job can be
## done by the player or by any companion in the party who bends the element,
## so non-benders benefit too. One fire job is deliberately cruel (scorching
## fields), and the world remembers it (scripts/core/avatar.gd).
##
## where: settlement types, or "camp" (offered from the camp menu)
## cond:  friendly, hostile, owned, cold, night, coast, mine, dry, looted,
##        temple_rel (Air Nomad relation 20)
## cd:    days before the same job again (per settlement if "per_site")

const Roster = preload("res://scripts/core/roster.gd")
const DLC = preload("res://scripts/dlc/registry.gd")
const AvatarSys = preload("res://scripts/core/avatar.gd")

const WORK := {
	# --- Fire: Hearth and Forge --------------------------------------------
	"temper": {"element": "fire", "name": "Temper your weapon in bending-fire", "where": ["town", "castle"], "hours": 6, "gold": 150, "skill": 3, "cd": 0,
		"desc": "Bending-heat folds the steel evenly. Your current weapon strikes 12% harder for as long as you carry it."},
	"kiln": {"element": "fire", "name": "Fire the potters' kilns", "where": ["town", "village"], "hours": 8, "cd": 4,
		"desc": "Hold a kiln at an even, terrible heat for a night. You are paid in porcelain."},
	"warm": {"element": "fire", "name": "Warm the camp", "where": ["camp"], "cond": ["cold"], "hours": 1, "cd": 3,
		"desc": "Small fires in every tent, kept alive all night. Morale rises; the wounded mend a little."},
	"cook": {"element": "fire", "name": "Cook for the whole column", "where": ["camp"], "hours": 2, "cd": 2,
		"desc": "Hot rice stretches further than cold. For two days the party eats half as much."},
	"clear": {"element": "fire", "name": "Clear the fields with a controlled burn", "where": ["village"], "cond": ["friendly"], "hours": 10, "cd": 20, "per_site": true,
		"desc": "Burn the stubble and the weeds, not the barns. Next season's harvest is better for it."},
	"scorch": {"element": "fire", "name": "Scorch the fields", "where": ["village"], "cond": ["hostile"], "hours": 4, "cd": 0,
		"desc": "Burn an enemy village's crops in the ground. It works. People starve. The world remembers. (Infamy +30)"},
	"lanterns": {"element": "fire", "name": "Light the festival lanterns", "where": ["town"], "cond": ["night"], "hours": 3, "cd": 30, "per_site": true,
		"desc": "Five hundred paper lanterns lit at once, from the rooftops. People will talk about it for years."},
	# --- Water: Tide and Spring --------------------------------------------
	"heal_house": {"element": "water", "name": "Open a healing house", "where": ["town", "village"], "hours": 8, "cd": 7, "per_site": true,
		"desc": "A day of bone-setting, fevers and burns. The town pays what it can and remembers who came."},
	"irrigate": {"element": "water", "name": "Dig irrigation channels", "where": ["village"], "cond": ["friendly"], "hours": 10, "cd": 20, "per_site": true,
		"desc": "Bend a stream into the dry fields. Prosperity rises for good."},
	"fish": {"element": "water", "name": "Bend the shoals into the nets", "where": ["town", "village"], "cond": ["coast"], "hours": 4, "cd": 2,
		"desc": "Turn a current and a shoal turns with it. Fish for the party's stores."},
	"purify": {"element": "water", "name": "Draw clean water from the deep ground", "where": ["village", "town"], "cond": ["dry"], "hours": 6, "cd": 20, "per_site": true,
		"desc": "Find the water under the dust and bring it up clean. People here will not forget it."},
	"ice_bridge": {"element": "water", "name": "Freeze a road across the water", "where": ["camp"], "hours": 2, "cd": 5,
		"desc": "Ice causeways over rivers and marsh. The party travels a quarter faster for two days."},
	"ice_carve": {"element": "water", "name": "Carve ice for the children", "where": ["town", "village"], "cond": ["cold"], "hours": 3, "cd": 30, "per_site": true,
		"desc": "Slides, towers and one very large, slightly wrong turtle-seal. Relation and morale rise."},
	# --- Earth: Stone and Root ---------------------------------------------
	"mine": {"element": "earth", "name": "Work a seam", "where": ["village", "castle", "town"], "cond": ["mine"], "hours": 8, "cd": 3,
		"desc": "Open the rock along the vein. You keep what you bring up."},
	"masonry": {"element": "earth", "name": "Raise stone walls", "where": ["town", "castle"], "cond": ["owned"], "hours": 24, "gold": 400, "cd": 10, "per_site": true,
		"desc": "Thicken the walls of your own fief. Each raising makes it harder to take (up to four times)."},
	"terrace": {"element": "earth", "name": "Cut terraces into the hillside", "where": ["village"], "cond": ["friendly"], "hours": 12, "cd": 20, "per_site": true,
		"desc": "Level steps of soil where there was only slope. More land, more rice."},
	"road": {"element": "earth", "name": "Level the road ahead", "where": ["camp"], "hours": 4, "cd": 7,
		"desc": "Flatten ruts, bridge ditches. The party travels faster for three days."},
	"shelter": {"element": "earth", "name": "Raise shelters for refugees", "where": ["temple", "village"], "hours": 6, "cd": 15, "per_site": true,
		"desc": "Stone huts in an afternoon. The refugees will sleep dry tonight."},
	"shore": {"element": "earth", "name": "Shore up the old mine tunnels", "where": ["village", "castle", "town"], "cond": ["mine"], "hours": 6, "cd": 30, "per_site": true,
		"desc": "Seal the cracks before the next collapse instead of after it."},
	# --- Air: Wind and Wing ------------------------------------------------
	"scout": {"element": "air", "name": "Glide ahead and scout", "where": ["camp"], "hours": 1, "cd": 2,
		"desc": "See the road from above. You learn who is on it, and the party moves faster for a day."},
	"sails": {"element": "air", "name": "Fill the merchants' sails", "where": ["town", "village"], "cond": ["coast"], "hours": 6, "cd": 5, "per_site": true,
		"desc": "A steady wind for a becalmed fleet. The merchants pay well."},
	"windmill": {"element": "air", "name": "Turn the mill-stones", "where": ["village"], "cond": ["friendly"], "hours": 8, "cd": 20, "per_site": true,
		"desc": "A season's grain milled in a day. The village grows; you are given rice."},
	"firefight": {"element": "air", "name": "Smother the fires", "where": ["village"], "cond": ["looted"], "hours": 4, "cd": 0,
		"desc": "Take the air from a burning village. What is left can be rebuilt."},
	"meditate": {"element": "air", "name": "Meditate on the wind", "where": ["camp", "temple"], "hours": 4, "cd": 3,
		"desc": "Breath, and nothing else. Your chi runs deeper for three days, and your forms grow smoother."},
	"bison": {"element": "air", "name": "Fly by sky bison to another temple", "where": ["temple"], "cond": ["temple_rel"], "hours": 0, "cd": 0,
		"desc": "The Nomads lend a bison to friends. Cross the world in hours."},
}

# ---------------------------------------------------------------------------
## Who in the party can do this element's work: "player", a companion id, or "".
static func doer(el: String) -> String:
	if GS.player.get("bend", "") == el:
		return "player"
	for cid in GS.player.companions:
		var cs: Dictionary = GS.companion_state(cid)
		if cs.get("wounded", false) or float(cs.get("away_until", -1.0)) > GS.hours:
			continue
		var b: String = cs.get("bend", Data.companions.get(cid, {}).get("bend", ""))
		if b == el or (el == "earth" and b == "sand") or (el == "fire" and b == "blue_fire"):
			return cid
	return ""

static func doer_name(who: String) -> String:
	if who == "player":
		return "You"
	return Data.companions.get(who, {}).get("short", who)

## Skill of whoever does the work, on the player's 0-10 bending scale.
static func strength(who: String) -> int:
	if who == "player":
		return GS.skill("bending")
	var cs: Dictionary = GS.companion_state(who)
	return int(round(float(cs.get("power", Data.companions.get(who, {}).get("power", 1.0))) * 4.0))

static func _cold(sid: String) -> bool:
	var pos: Vector2 = Data.settlements[sid].pos if sid != "" else GS.player_party().pos
	var b: String = GS.sim.biome_at(pos)
	if b in ["snow", "mountain"] or GS.season() == "Winter":
		return true
	return sid != "" and Data.settlements[sid].culture in ["north", "south"]

## Why a job cannot be done here and now ("" when it can).
static func blocker(id: String, sid: String) -> String:
	var w: Dictionary = WORK[id]
	if not DLC.enabled(w.element):
		return "expansion off"
	var who := doer(w.element)
	if who == "":
		return "needs a %s in the party" % {"fire": "firebender", "water": "waterbender", "earth": "earthbender", "air": "airbender"}[w.element]
	var here: String = "camp" if sid == "" else Data.settlements[sid].type
	if not w.where.has(here):
		return "not here"
	if w.has("skill") and strength(who) < int(w.skill):
		return "needs bending %d" % int(w.skill)
	if int(w.get("gold", 0)) > GS.player.gold:
		return "needs %d gold" % int(w.gold)
	var s: Dictionary = GS.settlements.get(sid, {})
	for c in w.get("cond", []):
		match c:
			"friendly":
				if GS.at_war(s.faction, GS.player_faction()):
					return "not while at war with them"
			"hostile":
				if not GS.at_war(s.faction, GS.player_faction()):
					return "only against an enemy village"
			"owned":
				if s.owner != "player":
					return "only in your own fief"
			"cold":
				if not _cold(sid):
					return "only in the cold"
			"night":
				if GS.is_daytime():
					return "only at night"
			"coast":
				if not Data.settlements[sid].get("produces", []).has("fish"):
					return "only on the coast"
			"mine":
				var pr: Array = Data.settlements[sid].get("produces", [])
				if not (pr.has("iron") or pr.has("jade") or Data.settlements[sid].type == "castle"):
					return "no seam here"
			"dry":
				if not (Data.settlements[sid].culture == "sand" or sid in ["misty_palms", "foggy_swamp"] or s.prosperity < 40.0):
					return "the wells here are fine"
			"looted":
				if s.looted_until <= GS.hours:
					return "nothing is burning"
			"temple_rel":
				if int(GS.player.faction_rel.get("air_nomads", 0)) < 20:
					return "needs Air Nomad relation 20"
	if id == "masonry" and float(s.get("wall_bonus", 0.0)) >= 0.6:
		return "the walls are as thick as stone gets"
	if id == "temper" and GS.player.get("tempered", "") == GS.player.equip.get("weapon", "fists"):
		return "already tempered"
	var key := _cd_key(id, sid)
	var left := int(GS.flags.get(key, -9999)) + int(w.get("cd", 0)) - GS.day()
	if int(w.get("cd", 0)) > 0 and left > 0:
		return "again in %d day%s" % [left, "" if left == 1 else "s"]
	return ""

static func _cd_key(id: String, sid: String) -> String:
	return "work_" + id + ("_" + sid if WORK[id].get("per_site", false) else "")

static func available(sid: String) -> Array:
	var here: String = "camp" if sid == "" else Data.settlements[sid].type
	var out := []
	for id in WORK:
		if WORK[id].where.has(here) and DLC.enabled(WORK[id].element):
			out.append(id)
	return out

# ---------------------------------------------------------------------------
## Do the job. Returns a line describing what happened.
static func perform(id: String, sid: String, extra: String = "") -> String:
	var w: Dictionary = WORK[id]
	var who := doer(w.element)
	var b := strength(who)
	var nm := doer_name(who)
	GS.flags[_cd_key(id, sid)] = GS.day()
	if int(w.get("gold", 0)) > 0:
		GS.add_gold(-int(w.gold))
	if float(w.hours) > 0.0:
		GS.sim.advance(float(w.hours))
	var s: Dictionary = GS.settlements.get(sid, {})
	var sname: String = Data.settlements[sid].name if sid != "" else ""
	var line := ""
	match id:
		"temper":
			GS.player.tempered = GS.player.equip.get("weapon", "fists")
			line = "%s fold%s the heat into the steel until it rings. Your %s strikes harder." % [nm, "" if nm == "You" else "s", Data.item(GS.player.tempered).name]
		"kiln":
			var n := 2 + int(b / 3)
			GS.add_good("porcelain", n)
			line = "By dawn the kilns have given up %d crates of porcelain, and the potters have given up arguing with %s." % [n, nm.to_lower() if nm == "You" else nm]
		"warm":
			GS.player.morale = minf(100.0, GS.player.morale + 15.0)
			Roster.heal_fraction(GS.player_party().roster, 0.1)
			line = "Small fires in every tent, all night. Nobody shivers. Morale +15."
		"cook":
			_buff("fed", 48.0, 1.0)
			line = "%s cook%s rice for everyone at once over open hands. For two days, the stores last twice as long." % [nm, "" if nm == "You" else "s"]
		"clear":
			_settle(sid, 8.0, 6)
			line = "The fields of %s burn clean and controlled. Next season's harvest will be the better for it." % sname
		"scorch":
			s.prosperity = maxf(5.0, s.prosperity - 20.0)
			s.looted_until = GS.hours + 24.0 * 8.0
			s.relation = mini(int(s.relation), -40)
			GS.change_faction_rel(s.faction, -10)
			GS.player.honor = int(GS.player.get("honor", 0)) - 3
			AvatarSys.add_infamy(30, Data.settlements[sid].pos, "scorching the fields of " + sname)
			load("res://scripts/story/story.gd").react("raid")
			line = "The fields of %s go up in a single roar. Behind you, people stand at the edge of the ash and do not speak." % sname
		"lanterns":
			_settle(sid, 0.0, 8)
			GS.add_renown(4)
			GS.player.morale = minf(100.0, GS.player.morale + 6.0)
			line = "Five hundred lanterns light at once across the roofs of %s. Children will tell their children." % sname
		"heal_house":
			var pay := 40 + 15 * b
			GS.add_gold(pay)
			GS.add_renown(2)
			_settle(sid, 0.0, 6)
			line = "A day of fevers, burns and bones in %s. The town pays %d gold and remembers who came." % [sname, pay]
		"irrigate":
			_settle(sid, 8.0, 5)
			line = "%s bend%s a stream into the dry fields of %s. It will still be running next year." % [nm, "" if nm == "You" else "s", sname]
		"fish":
			var nf := 3 + int(b / 2)
			GS.add_good("fish", nf)
			line = "The shoal turns with the current and the nets fill. +%d smoked fish." % nf
		"purify":
			_settle(sid, 5.0, 10)
			GS.player.honor = int(GS.player.get("honor", 0)) + 1
			line = "Clean water rises in the wells of %s. An old woman fills a cup, drinks, and cries." % sname
		"ice_bridge":
			_buff("swift", 48.0, 1.25)
			line = "Ice roads over every river and marsh ahead. The party travels a quarter faster for two days."
		"ice_carve":
			_settle(sid, 0.0, 6)
			GS.player.morale = minf(100.0, GS.player.morale + 8.0)
			line = "Slides, towers and a turtle-seal of questionable anatomy. The children of %s approve loudly." % sname
		"mine":
			var pr: Array = Data.settlements[sid].get("produces", [])
			var good := "jade" if pr.has("jade") else "iron"
			var nm2 := 1 + int(b / 4)
			GS.add_good(good, nm2)
			line = "The rock opens along the vein. You bring up %d %s." % [nm2, Data.goods[good].name.to_lower()]
		"masonry":
			s.wall_bonus = minf(0.6, float(s.get("wall_bonus", 0.0)) + 0.15)
			line = "The walls of %s rise thicker by an arm's length all round. (Walls +%d%%)" % [sname, int(float(s.wall_bonus) * 100.0)]
		"terrace":
			_settle(sid, 10.0, 4)
			line = "Steps of level earth climb the hillside above %s. There will be rice on them by summer." % sname
		"road":
			_buff("swift", 72.0, 1.15)
			line = "The road ahead is flat and firm for days. The party travels faster."
		"shelter":
			_settle(sid, 2.0, 6)
			GS.change_faction_rel("air_nomads", 3)
			GS.player.honor = int(GS.player.get("honor", 0)) + 1
			line = "Stone huts rise in an afternoon at %s. The refugees will sleep dry tonight." % sname
		"shore":
			_settle(sid, 3.0, 10)
			GS.add_renown(5)
			line = "You seal three cracks in the old tunnels under %s. The miners say the mountain sounds quieter." % sname
		"scout":
			_buff("swift", 24.0, 1.2)
			var seen := []
			for p in GS.sim.parties_near(GS.player_party().pos, 90.0):
				if p.id != "player" and GS.parties_hostile(GS.player_party(), p):
					seen.append(GS.sim._display_name(p))
			line = "From the air the road is a map. %s" % ("Hostile on the roads: " + ", ".join(seen.slice(0, 5)) + "." if not seen.is_empty() else "Nothing hostile within a day's march.")
		"sails":
			var pay2 := 60 + 15 * b
			GS.add_gold(pay2)
			_settle(sid, 0.0, 3)
			line = "A becalmed fleet sails out of %s on your wind. The merchants pay %d gold." % [sname, pay2]
		"windmill":
			_settle(sid, 8.0, 5)
			GS.add_good("rice", 3)
			line = "A season's grain milled in a day at %s. They give you rice to carry." % sname
		"firefight":
			s.looted_until = GS.hours
			_settle(sid, 5.0, 12)
			GS.player.honor = int(GS.player.get("honor", 0)) + 1
			line = "You take the air from the fires of %s. What is left can be rebuilt, and they start at once." % sname
		"meditate":
			_buff("chi", 72.0, 1.2)
			for f in GS.player.get("forms", []):
				f.uses = int(f.get("uses", 0)) + 5
			line = "Four hours of breath and nothing else. Your chi runs deeper for three days, and your forms come smoother."
		"bison":
			if extra != "" and Data.settlements.has(extra):
				var pp: Dictionary = GS.player_party()
				var dist: float = pp.pos.distance_to(Data.settlements[extra].pos)
				GS.sim.advance(dist / 80.0)
				pp.pos = Data.settlements[extra].pos + Vector2(4, 4)
				pp.target = pp.pos
				pp.moving = false
				line = "The bison lands at %s in a storm of dust and dignity. The novices pretend not to be impressed." % Data.settlements[extra].name
	if who != "player" and who != "":
		load("res://scripts/story/story.gd").change_approval(who, 1 if id != "scorch" else -10)
	GS.log_msg(line, Color(0.95, 0.85, 0.6))
	return line

static func _settle(sid: String, prosperity: float, relation: int) -> void:
	var s: Dictionary = GS.settlements[sid]
	s.prosperity = clampf(s.prosperity + prosperity, 5.0, 100.0)
	s.relation = clampi(int(s.relation) + relation, -100, 100)

static func _buff(key: String, hours: float, mult: float) -> void:
	if not GS.player.has("buffs"):
		GS.player.buffs = {}
	GS.player.buffs[key] = {"until": GS.hours + hours, "mult": mult}

## An active travel/food/chi buff's multiplier, or 0 when inactive.
static func buff(key: String) -> float:
	var b: Dictionary = GS.player.get("buffs", {}).get(key, {})
	if b.is_empty() or float(b.until) <= GS.hours:
		return 0.0
	return float(b.mult)
