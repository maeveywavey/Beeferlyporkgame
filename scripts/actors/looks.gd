extends RefCounted
## Appearance rules: who wears what, per culture, rank and role.

const CB = preload("res://scripts/actors/character_builder.gd")

const CULTURE_MAP := {"fire": "fire", "earth": "earth", "kyoshi": "kyoshi", "north": "water", "south": "south",
	"swamp": "swamp", "sand": "sand", "air": "air", "omashu": "omashu"}
const OUTLAW_TROOPS := ["mountain_bandit", "pirate", "pirate_captain", "fn_deserter", "red_lantern", "red_lantern_elder", "merc_swordsman", "merc_archer"]
const HELMET_MAP := {"arrow": "air_arrow", "none": "", "ek_helm": "ek_helm"}

## Appearance for a troop type (deterministic per unit seed).
static func troop_look(tid: String, rng: RandomNumberGenerator) -> Dictionary:
	var t: Dictionary = Data.troop(tid)
	var culture: String = CULTURE_MAP.get(t.culture, "earth")
	if OUTLAW_TROOPS.has(tid):
		culture = "outlaw" if tid != "fn_deserter" else "fire"
	var sex: String = t.get("sex", "")
	if t.culture == "kyoshi":
		sex = "f"
	elif t.culture == "north" and t.bend == "water" and sex == "":
		# The Law of the Two Paths: healers are women, combat benders men,
		# until the law changes.
		if t.healer:
			sex = "f"
		elif not GS.flags.get("two_paths", false):
			sex = "m"
	var look := CB.random_look(culture, rng, sex)
	if t.culture == "kyoshi":
		look.hair = "Hair_Buns"
	look.outfit = "peasant" if t.tier <= 1 or t.bend == "air" else "ranger"
	var helmet: String = t.look.get("helmet", "none")
	look.accessory = HELMET_MAP.get(helmet, helmet)
	look.kit = kit_for(tid, culture, t.tier)
	if look.accessory in ["fn_helmet", "fn_officer", "ek_hat", "ek_helm", "wolf", "parka", "wt_helm", "sand_wrap", "yuyan", "dai_li", "pirate_hat", "bandana"] and look.hair == "Hair_Long":
		look.hair = "Hair_Buns" if look.sex == "f" else "Hair_Buzzed"
	return look

static func kit_for(tid: String, culture: String, tier: int) -> String:
	if tid == "ek_dai_li":
		return "dai_li_robe"
	match culture:
		"fire":
			return "fn_armor" if tier >= 2 else "sash"
		"earth", "omashu":
			return "ek_armor" if tier >= 2 else ""
		"kyoshi":
			return "kyoshi_armor"
		"water", "south":
			return "water_fur"
		"air":
			return "air_robes"
		"sand", "swamp", "outlaw":
			return "sash"
	return ""

static func lord_look(lid: String) -> Dictionary:
	var l: Dictionary = Data.lords[lid]
	var culture: String = l.get("culture", Data.factions[l.faction].culture)
	culture = {"north": "water"}.get(culture, culture)
	var look: Dictionary = l.get("look", {}).duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(lid)
	look.merge(CB.random_look(culture, rng, look.get("sex", "")), false)
	look.merge({"culture": culture, "outfit": "ranger", "kit": kit_for("", culture, 4)}, false)
	if not look.has("accessory"):
		look.accessory = {"fire": "fn_noble", "earth": "ek_helm", "omashu": "ek_helm", "water": "", "south": "wolf", "kyoshi": "kyoshi", "air": "air_arrow"}.get(culture, "")
	return look

static func player_look() -> Dictionary:
	var pl: Dictionary = GS.player
	var pv: Dictionary = pl.get("look", {})
	var armor_id: String = pl.equip.get("armor", "")
	var culture := "earth"
	var kit := ""
	match armor_id:
		"fn_armor", "fn_officer_armor":
			culture = "fire"
			kit = "fn_armor"
		"ek_armor", "ek_royal":
			kit = "ek_armor"
		"kyoshi_armor":
			culture = "kyoshi"
			kit = "kyoshi_armor"
		"water_parka", "fur_armor":
			culture = "water"
			kit = "water_fur"
	var helm: String = pl.equip.get("helmet", "")
	var look := {"sex": pv.get("sex", "m"), "skin": pv.get("skin", Color(0.84, 0.64, 0.48)), "hair": pv.get("hair_style", "Hair_SimpleParted"),
		"hair_color": pv.get("hair", Color(0.1, 0.07, 0.05)), "eye_color": pv.get("eyes", Color(0.4, 0.28, 0.15)),
		"beard": pv.get("beard", false), "culture": culture, "kit": kit, "outfit": "ranger" if armor_id != "" and armor_id != "peasant_clothes" else "peasant",
		"accessory": Data.item(helm).get("look", "") if helm != "" else "", "height": pv.get("height", 1.0)}
	if look.accessory == "parka":
		look.culture = "water"
	return look

## Look for a world-map party figure.
static func party_look(p: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(p.id)
	match p.kind:
		"player":
			return player_look()
		"lord":
			if p.lord != "" and Data.lords.has(p.lord):
				return lord_look(p.lord)
	var tid := ""
	if not p.roster.is_empty():
		tid = p.roster[0].id
	if tid != "":
		return troop_look(tid, rng)
	return CB.random_look("earth", rng)

## Look for a companion (shared by battles, portraits and walkable scenes).
static func companion_look(cid: String) -> Dictionary:
	var c: Dictionary = Data.companions[cid]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cid)
	var culture: String = CULTURE_MAP.get(c.get("culture", "earth"), "earth")
	var vl: Dictionary = c.get("vlook", {})
	var look := CB.random_look(culture, rng, vl.get("sex", ""))
	look.merge(vl, true)
	look.merge({"outfit": "ranger", "kit": kit_for("", look.culture, 3)}, false)
	return look

## Look for a story character defined in a dialogue script's NPCS table.
static func npc_look(def: Dictionary, id: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var culture: String = CULTURE_MAP.get(def.get("culture", "earth"), def.get("culture", "earth"))
	var vl: Dictionary = def.get("vlook", {})
	var look := CB.random_look(culture, rng, vl.get("sex", ""))
	look.merge(vl, true)
	look.merge({"outfit": def.get("outfit", "peasant"), "kit": def.get("kit", kit_for("", culture, 1))}, false)
	return look
