extends RefCounted
## The element expansions' catalogue of bending techniques (docs/07_avatar_and_dlcs.md).
## Each technique belongs to a style, is learned from a teacher or a trial,
## and can be set on Q, E or R in place of the art's basic ability
## (Character -> Techniques). Learned techniques also open new movements in the
## Bending Forms designer (scripts/battle/forms.gd, "req").
##
## Ability format is bending.gd's, plus four kinds the expansions add:
##   dash  - the bender travels `dist` metres, striking everyone on the way
##   buff  - a timed stance on the bender: power, armour, damage taken, speed
##   nova  - a ring around the bender (optionally pulling enemies inward)
##   line  - a fissure along the ground to `range` metres, `width` wide
## and three effects: freeze (stunned in ice), root (held in place), pull.

const STYLES := {
	"fire": {
		"sage": {"name": "Sage Breath", "basis": "Northern Shaolin breathing (qigong)", "desc": "Fire as breath. Efficient, sustained, patient. Taught by the Fire Sages and the Cinder Monastery."},
		"duel": {"name": "Duellist's Line", "basis": "Long Fist (Changquan)", "desc": "The Agni Kai tradition: long, straight, precise lines that end fights quickly."},
		"jet": {"name": "Jet and Flare", "basis": "Northern Shaolin kicks and leaps", "desc": "Fire as propulsion. Mobility, rings and leaps; dangerous to the user."},
	},
	"water": {
		"north": {"name": "Northern Ice School", "basis": "Yang-style Tai Chi", "desc": "Precise, cold and defensive. Water held still becomes ice."},
		"south": {"name": "Southern Tide Style", "basis": "Chen-style Tai Chi (fa jin)", "desc": "Spiralling, explosive release. The raider's waterbending."},
		"swamp": {"name": "Swamp and Mist", "basis": "Tai Chi walking and rooting", "desc": "Water in living things and in the air. The Foggy Swamp's way."},
		"healer": {"name": "Healer's Path", "basis": "Tai Chi push-hands sensitivity", "desc": "Feel the chi paths, then mend them."},
	},
	"earth": {
		"badger": {"name": "Badgermole Way", "basis": "Hung Gar stance work", "desc": "The first earthbending: listen to the ground before moving it."},
		"stone": {"name": "Stone Hand", "basis": "Southern Mantis short strikes", "desc": "The Dai Li's quick, controlling style. Effective, and not innocent."},
		"boulder": {"name": "Boulder Style", "basis": "Hung Gar tiger forms", "desc": "Omashu's style: big stones, big stances, big laughs."},
	},
	"air": {
		"north": {"name": "Northern Glide", "basis": "Baguazhang leaping palms", "desc": "The Northern Temple's flyers. Strike from the air, never land where expected."},
		"south": {"name": "Southern Play", "basis": "Baguazhang circle walking", "desc": "Air as a game: deflect, bounce, keep everyone off balance."},
		"east": {"name": "Eastern Stillness", "basis": "Baguazhang standing meditation", "desc": "Air as breath shared. Defence and healing."},
		"west": {"name": "Western Wind-Shaping", "basis": "Baguazhang palm changes", "desc": "Air given shape: blades, vortices, walls of wind."},
	},
}

const TECHNIQUES := {
	# --- Fire: Embers of the First Flame -----------------------------------
	"f_breath_fire": {"element": "fire", "style": "sage", "name": "Breath of Fire", "slot": "e",
		"desc": "Fire from the breath itself, no hands needed. A long cone that keeps burning.",
		"from": "Master Sayuri Ono (approval 20), or the Cinder Monastery",
		"ability": {"name": "Breath of Fire", "kind": "cone", "cost": 26.0, "cd": 4.0, "dmg": 30.0, "range": 7.5, "angle": 35.0, "knock": 4.0, "effect": "burn", "fx": "fire", "sfx": "fire"}},
	"f_inner_flame": {"element": "fire", "style": "sage", "name": "Inner Flame", "slot": "r",
		"desc": "Breathe the fire inward: for ten seconds your bending is stronger and your chi returns twice as fast.",
		"from": "Kazan of the Cinder Monastery",
		"ability": {"name": "Inner Flame", "kind": "buff", "cost": 20.0, "cd": 18.0, "dur": 10.0, "power": 1.35, "regen": 2.0, "fx": "fire", "sfx": "fire"}},
	"f_whip": {"element": "fire", "style": "duel", "name": "Fire Whip", "slot": "q",
		"desc": "A lash of flame drawn out of a straight punch. Long reach, narrow arc.",
		"from": "Master Sayuri Ono (approval 40), or the duelling hall in Fire Fountain City",
		"ability": {"name": "Fire Whip", "kind": "cone", "cost": 16.0, "cd": 1.6, "dmg": 24.0, "range": 10.0, "angle": 12.0, "knock": 6.0, "effect": "burn", "fx": "fire", "sfx": "fire"}},
	"f_daggers": {"element": "fire", "style": "duel", "name": "Fire Daggers", "slot": "q",
		"desc": "Three quick blades of flame from the fingertips.",
		"from": "The duelling hall in Fire Fountain City",
		"ability": {"name": "Fire Daggers", "kind": "volley", "cost": 14.0, "cd": 0.9, "dmg": 12.0, "speed": 36.0, "radius": 0.3, "knock": 1.5, "gravity": 0.0, "range": 22.0, "count": 3, "spread": 8.0, "effect": "burn", "fx": "fire", "sfx": "fire"}},
	"f_jets": {"element": "fire", "style": "jet", "name": "Fire Jets", "slot": "e",
		"desc": "Flame from the feet: a burst of speed that scorches anyone in the way.",
		"from": "The duelling hall in Fire Fountain City (Bending 6)",
		"ability": {"name": "Fire Jets", "kind": "dash", "cost": 22.0, "cd": 5.0, "dist": 9.0, "dmg": 14.0, "knock": 5.0, "effect": "burn", "fx": "fire", "sfx": "fire"}},
	"f_ring": {"element": "fire", "style": "jet", "name": "Ring of Fire", "slot": "r",
		"desc": "A spinning kick that throws a ring of flame around you.",
		"from": "Kazan of the Cinder Monastery",
		"ability": {"name": "Ring of Fire", "kind": "nova", "cost": 34.0, "cd": 7.0, "dmg": 22.0, "range": 5.5, "knock": 7.0, "effect": "burn", "fx": "fire", "sfx": "fire"}},
	# --- Water: The Turning Tide -------------------------------------------
	"w_ice_lance": {"element": "water", "style": "north", "name": "Ice Lance", "slot": "q",
		"desc": "Water frozen mid-throw into a spear of ice. Fast, piercing.",
		"from": "Elder Pana's training ice in Agna Qel'a",
		"ability": {"name": "Ice Lance", "kind": "projectile", "cost": 16.0, "cd": 1.2, "dmg": 26.0, "speed": 40.0, "radius": 0.35, "knock": 3.0, "gravity": 0.0, "range": 26.0, "effect": "slow", "pierce": true, "fx": "ice", "sfx": "water"}},
	"w_ice_prison": {"element": "water", "style": "north", "name": "Ice Prison", "slot": "e",
		"desc": "A wave that freezes around its target and holds them.",
		"from": "Elder Pana's training ice in Agna Qel'a (Bending 5)",
		"ability": {"name": "Ice Prison", "kind": "projectile", "cost": 24.0, "cd": 6.0, "dmg": 8.0, "speed": 30.0, "radius": 0.6, "knock": 0.0, "gravity": 0.0, "range": 22.0, "effect": "freeze", "fx": "ice", "sfx": "water"}},
	"w_octopus": {"element": "water", "style": "south", "name": "Octopus Form", "slot": "r",
		"desc": "Eight whips of water around the bender, striking every direction at once.",
		"from": "Master Yura of Wolf's Crown",
		"ability": {"name": "Octopus Form", "kind": "nova", "cost": 30.0, "cd": 6.0, "dmg": 18.0, "range": 5.0, "knock": 6.0, "effect": "slow", "fx": "water", "sfx": "water"}},
	"w_surge": {"element": "water", "style": "south", "name": "Tidal Surge", "slot": "e",
		"desc": "A wide, heavy wave that knocks a line of soldiers flat.",
		"from": "Master Yura of Wolf's Crown",
		"ability": {"name": "Tidal Surge", "kind": "cone", "cost": 32.0, "cd": 7.0, "dmg": 16.0, "range": 9.0, "angle": 50.0, "knock": 12.0, "effect": "slow", "fx": "water", "sfx": "water"}},
	"w_vines": {"element": "water", "style": "swamp", "name": "Vine Snare", "slot": "q",
		"desc": "Bend the water inside a vine and tie someone to the ground with it.",
		"from": "Huan of the Foggy Swamp",
		"ability": {"name": "Vine Snare", "kind": "projectile", "cost": 18.0, "cd": 4.0, "dmg": 10.0, "speed": 26.0, "radius": 0.5, "knock": 0.0, "gravity": 0.0, "range": 20.0, "effect": "root", "fx": "water", "sfx": "water"}},
	"w_mist": {"element": "water", "style": "swamp", "name": "Mist Veil", "slot": "e",
		"desc": "Lift the water out of the air in front of you into a blinding fog.",
		"from": "Huan of the Foggy Swamp",
		"ability": {"name": "Mist Veil", "kind": "cone", "cost": 22.0, "cd": 8.0, "dmg": 2.0, "range": 8.0, "angle": 70.0, "knock": 0.0, "effect": "blind", "fx": "water", "sfx": "water"}},
	"w_chi_heal": {"element": "water", "style": "healer", "name": "Chi-Path Healing", "slot": "e",
		"desc": "Healing that follows the body's chi paths: mends more, and cures burns, chills and snares.",
		"from": "Elder Pana's healing huts in Agna Qel'a (Healing 3)",
		"ability": {"name": "Chi-Path Healing", "kind": "heal", "cost": 40.0, "cd": 9.0, "amount": 0.5, "range": 6.0, "cure": true, "fx": "water", "sfx": "water"}},
	# --- Earth: Roots of the Mountain --------------------------------------
	"e_seismic": {"element": "earth", "style": "badger", "name": "Seismic Sense", "slot": "r",
		"desc": "Feel every footstep through the ground: for twelve seconds you cannot be blinded and you strike harder.",
		"from": "Old Shan of Stonewatch Pass",
		"ability": {"name": "Seismic Sense", "kind": "buff", "cost": 18.0, "cd": 20.0, "dur": 12.0, "power": 1.25, "sight": true, "fx": "rock", "sfx": "earth"}},
	"e_fissure": {"element": "earth", "style": "badger", "name": "Fissure", "slot": "e",
		"desc": "Split the ground in a straight line; everyone on it is thrown.",
		"from": "Gao Ming (approval 20), or Old Shan",
		"ability": {"name": "Fissure", "kind": "line", "cost": 26.0, "cd": 6.0, "dmg": 22.0, "range": 14.0, "width": 1.6, "stun": 1.0, "knock": 4.0, "fx": "rock", "sfx": "earth"}},
	"e_gloves": {"element": "earth", "style": "stone", "name": "Stone Gloves", "slot": "q",
		"desc": "Rock fists fired in quick succession. The Dai Li's signature.",
		"from": "Bo Lai, if Hana spared him; or the Dai Li's academy (Gentry standing)",
		"ability": {"name": "Stone Gloves", "kind": "volley", "cost": 18.0, "cd": 1.4, "dmg": 15.0, "speed": 30.0, "radius": 0.4, "knock": 3.0, "gravity": 0.0, "range": 24.0, "count": 2, "spread": 6.0, "effect": "", "fx": "rock", "sfx": "earth"}},
	"e_cuffs": {"element": "earth", "style": "stone", "name": "Stone Cuffs", "slot": "e",
		"desc": "Close stone around a target's feet and hold them in place.",
		"from": "Bo Lai, if Hana spared him; or the Dai Li's academy (Gentry standing)",
		"ability": {"name": "Stone Cuffs", "kind": "projectile", "cost": 20.0, "cd": 5.0, "dmg": 6.0, "speed": 26.0, "radius": 0.6, "knock": 0.0, "gravity": 2.0, "range": 20.0, "effect": "root", "fx": "rock", "sfx": "earth"}},
	"e_boulder": {"element": "earth", "style": "boulder", "name": "Boulder Toss", "slot": "q",
		"desc": "A boulder the size of a cart, thrown in an arc. Slow, and unanswerable.",
		"from": "The boulder masters of Omashu",
		"ability": {"name": "Boulder Toss", "kind": "projectile", "cost": 30.0, "cd": 4.0, "dmg": 40.0, "speed": 20.0, "radius": 1.0, "knock": 14.0, "gravity": 7.0, "range": 26.0, "effect": "", "fx": "rock", "sfx": "earth"}},
	"e_armor": {"element": "earth", "style": "boulder", "name": "Stone Armour", "slot": "r",
		"desc": "Wear the ground: much harder to hurt, much slower, for twelve seconds.",
		"from": "Gao Ming (approval 40), or the boulder masters of Omashu",
		"ability": {"name": "Stone Armour", "kind": "buff", "cost": 30.0, "cd": 20.0, "dur": 12.0, "armor": 25.0, "speed": 0.8, "knock_immune": true, "fx": "rock", "sfx": "earth"}},
	# --- Air: The Thirty-Six Winds ------------------------------------------
	"a_glider": {"element": "air", "style": "north", "name": "Glider Strike", "slot": "e",
		"desc": "Leap, glide, and land through the enemy line.",
		"from": "Yangzom (approval 20), or Abbot Lhakpa at the Northern Air Temple",
		"ability": {"name": "Glider Strike", "kind": "dash", "cost": 20.0, "cd": 4.5, "dist": 12.0, "dmg": 10.0, "knock": 12.0, "effect": "", "fx": "air", "sfx": "air"}},
	"a_updraft": {"element": "air", "style": "north", "name": "Updraft", "slot": "r",
		"desc": "Lift everyone around you off their feet.",
		"from": "Abbot Lhakpa at the Northern Air Temple",
		"ability": {"name": "Updraft", "kind": "quake", "cost": 32.0, "cd": 8.0, "dmg": 8.0, "range": 7.0, "stun": 1.8, "knock": 6.0, "fx": "air", "sfx": "air"}},
	"a_ball": {"element": "air", "style": "south", "name": "Air Ball", "slot": "q",
		"desc": "A dense, spinning ball of air that bowls people over. Cheap, fast, rude.",
		"from": "Yangzom, or Abbot Dorje at the Southern Air Temple",
		"ability": {"name": "Air Ball", "kind": "projectile", "cost": 8.0, "cd": 0.5, "dmg": 7.0, "speed": 28.0, "radius": 0.9, "knock": 15.0, "gravity": 0.0, "range": 22.0, "effect": "", "fx": "air", "sfx": "air"}},
	"a_shield": {"element": "air", "style": "south", "name": "Air Shield", "slot": "r",
		"desc": "A sphere of turning wind: arrows and blasts slide off for eight seconds.",
		"from": "Abbot Dorje at the Southern Air Temple",
		"ability": {"name": "Air Shield", "kind": "buff", "cost": 24.0, "cd": 16.0, "dur": 8.0, "reduce": 0.7, "knock_immune": true, "fx": "air", "sfx": "air"}},
	"a_breath": {"element": "air", "style": "east", "name": "Healing Breath", "slot": "e",
		"desc": "Air breathed into the lungs of the wounded. Mends a little, cures much.",
		"from": "Abbess Tsering at the Eastern Air Temple",
		"ability": {"name": "Healing Breath", "kind": "heal", "cost": 30.0, "cd": 8.0, "amount": 0.25, "range": 6.0, "cure": true, "fx": "air", "sfx": "air"}},
	"a_vortex": {"element": "air", "style": "west", "name": "Vortex", "slot": "r",
		"desc": "A turning column that drags everyone nearby toward you and spins them.",
		"from": "Abbess Yeshe at the Western Air Temple",
		"ability": {"name": "Vortex", "kind": "nova", "cost": 34.0, "cd": 8.0, "dmg": 10.0, "range": 8.0, "knock": 9.0, "pull": true, "effect": "slow", "fx": "air", "sfx": "air"}},
	"a_blade": {"element": "air", "style": "west", "name": "Wind Blade", "slot": "q",
		"desc": "A thin, fast edge of air. The Nomads teach it reluctantly.",
		"from": "Abbess Yeshe at the Western Air Temple (Bending 6)",
		"ability": {"name": "Wind Blade", "kind": "projectile", "cost": 14.0, "cd": 1.0, "dmg": 20.0, "speed": 44.0, "radius": 0.3, "knock": 2.0, "gravity": 0.0, "range": 26.0, "effect": "", "pierce": true, "fx": "air", "sfx": "air"}},
}

## Master titles earned in each expansion's mastery trial.
const MASTER_TITLES := {"fire": "Master Firebender", "water": "Master Waterbender", "earth": "Master Earthbender", "air": "Airbending Master"}

static func get_tech(id: String) -> Dictionary:
	return TECHNIQUES.get(id, {})

static func ability(id: String) -> Dictionary:
	return TECHNIQUES.get(id, {}).get("ability", {})

static func for_element(el: String) -> Array:
	var out := []
	for id in TECHNIQUES:
		if TECHNIQUES[id].element == el and DLC.enabled(el):
			out.append(id)
	return out

static func known(id: String) -> bool:
	return GS.player.get("techniques", []).has(id)

static func learn(id: String) -> void:
	if not GS.player.has("techniques"):
		GS.player.techniques = []
	if not GS.player.techniques.has(id) and TECHNIQUES.has(id):
		GS.player.techniques.append(id)
		var t: Dictionary = TECHNIQUES[id]
		GS.log_msg("You learned %s (%s). Set it on a key under Character → Techniques." % [t.name, STYLES[t.element][t.style].name], Color(1, 0.85, 0.5))
		# A newly learned technique goes straight onto an empty or default slot
		var lo: Dictionary = GS.player.get("loadout", {})
		if not lo.has(t.slot) or lo[t.slot] == "":
			lo[t.slot] = id
			GS.player.loadout = lo

## The ability the player (or a companion) has set on a slot, or {}.
static func loadout_ability(lo: Dictionary, slot: String) -> Dictionary:
	var id: String = lo.get(slot, "")
	if id == "" or not TECHNIQUES.has(id) or not DLC.enabled(TECHNIQUES[id].element):
		return {}
	return TECHNIQUES[id].ability

const DLC = preload("res://scripts/dlc/registry.gd")
