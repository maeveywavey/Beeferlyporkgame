extends RefCounted
## Bending Forms (docs/design.md §7). The player
## composes movements learned from each art's martial basis into a named
## form: Tai Chi for water, Hung Gar for earth, Northern Shaolin for fire,
## Baguazhang for air. Stats are computed from the movements, never chosen,
## and stances must chain.
##
## Movement fields: name, in/out stance, anim (motion clip), pulse
## (procedural emphasis on bending_pose), dur (s), power, chi, breath
## (in | out | hold), tags (linear, circle, rooted, evasive, rising).

const STANCES := {
	"fire": {"front": "Bow stance (Gong Bu)", "horse": "Horse stance (Ma Bu)", "empty": "Empty stance (Xu Bu)", "drop": "Drop stance (Pu Bu)"},
	"earth": {"horse": "Four-level horse (Sei Ping Ma)", "bow": "Bow stance (Ding Ji Ma)", "cat": "Cat stance (Diu Ma)", "crane": "Crane stance (Hok Ma)"},
	"water": {"wuji": "Wuji (ready)", "bow": "Bow stance", "empty": "Empty stance", "whip": "Single Whip"},
	"air": {"circle": "Circle walk", "palm": "Palm change", "rooster": "Golden rooster", "twist": "Hook-and-swing step (Kou Bai)"},
}

const MOVES := {
	"fire": [
		{"id": "f_jab", "name": "Chambered Fist", "in": "front", "out": "front", "anim": "ual1/Punch_Jab", "pulse": "lunge", "dur": 0.45, "power": 5, "chi": 3, "breath": "out", "tags": ["linear"]},
		{"id": "f_cross", "name": "Reverse Punch", "in": "front", "out": "horse", "anim": "ual1/Punch_Cross", "pulse": "lunge", "dur": 0.55, "power": 6, "chi": 4, "breath": "out", "tags": ["linear"]},
		{"id": "f_breath", "name": "Gathering Breath", "in": "horse", "out": "horse", "anim": "ual1/Spell_Simple_Enter", "pulse": "", "dur": 0.5, "power": 2, "chi": 1, "breath": "in", "tags": ["breath"]},
		{"id": "f_hook", "name": "Sweeping Arc Kick", "in": "horse", "out": "drop", "anim": "ual2/Melee_Hook", "pulse": "sweep", "dur": 0.55, "power": 6, "chi": 5, "breath": "out", "tags": ["circle"]},
		{"id": "f_rise", "name": "Rising Dragon Palm", "in": "drop", "out": "front", "anim": "ual1/Spell_Simple_Shoot", "pulse": "lunge", "dur": 0.5, "power": 7, "chi": 6, "breath": "out", "tags": ["rising", "linear"]},
		{"id": "f_step", "name": "Empty Step Feint", "in": "front", "out": "empty", "anim": "ual2/Sword_Regular_A", "pulse": "", "dur": 0.4, "power": 2, "chi": 2, "breath": "in", "tags": ["evasive"]},
		{"id": "f_empty", "name": "Leaping Flame Kick", "in": "empty", "out": "front", "anim": "ual2/NinjaJump_Land", "pulse": "stomp", "dur": 0.7, "power": 8, "chi": 7, "breath": "out", "tags": ["rising"]},
		# Expansion movements (Embers of the First Flame); "req" is the technique that teaches them
		{"id": "f_whip_palm", "name": "Whipping Palm (Bian Zhang)", "in": "front", "out": "horse", "anim": "ual2/Sword_Regular_B", "pulse": "sweep", "dur": 0.5, "power": 8, "chi": 6, "breath": "out", "tags": ["linear", "circle"], "req": "f_whip"},
		{"id": "f_furnace", "name": "Furnace Breath (Lian Qi)", "in": "horse", "out": "horse", "anim": "ual1/Spell_Simple_Enter", "pulse": "", "dur": 0.6, "power": 3, "chi": 1, "breath": "hold", "tags": ["breath"], "req": "f_breath_fire"},
		{"id": "f_tornado", "name": "Tornado Kick (Xuanfeng Jiao)", "in": "empty", "out": "drop", "anim": "ual2/NinjaJump_Land", "pulse": "stomp", "dur": 0.75, "power": 9, "chi": 7, "breath": "out", "tags": ["rising", "circle"], "req": "f_jets"},
		{"id": "f_dragon_tail", "name": "Dragon Swings Its Tail", "in": "drop", "out": "front", "anim": "ual2/Melee_Hook", "pulse": "sweep", "dur": 0.6, "power": 8, "chi": 6, "breath": "out", "tags": ["circle"], "req": "f_ring"},
	],
	"earth": [
		{"id": "e_root", "name": "Rooting the Horse", "in": "horse", "out": "horse", "anim": "ual1/Jump_Land", "pulse": "stomp", "dur": 0.7, "power": 4, "chi": 3, "breath": "in", "tags": ["rooted"]},
		{"id": "e_tiger", "name": "Tiger Claw", "in": "horse", "out": "bow", "anim": "ual1/Punch_Cross", "pulse": "lunge", "dur": 0.55, "power": 7, "chi": 5, "breath": "out", "tags": ["linear", "rooted"]},
		{"id": "e_push", "name": "Mountain Push", "in": "bow", "out": "horse", "anim": "ual1/Push", "pulse": "push", "dur": 0.8, "power": 8, "chi": 6, "breath": "out", "tags": ["rooted"]},
		{"id": "e_lift", "name": "Lifting the Stone", "in": "horse", "out": "bow", "anim": "ual2/OverhandThrow", "pulse": "stomp", "dur": 0.75, "power": 9, "chi": 7, "breath": "out", "tags": ["rising"]},
		{"id": "e_cat", "name": "Cat Step Guard", "in": "bow", "out": "cat", "anim": "ual2/Sword_Block", "pulse": "", "dur": 0.45, "power": 2, "chi": 2, "breath": "in", "tags": ["evasive"]},
		{"id": "e_crane", "name": "Crane Beak Strike", "in": "cat", "out": "crane", "anim": "ual1/Punch_Jab", "pulse": "lunge", "dur": 0.45, "power": 5, "chi": 4, "breath": "out", "tags": ["linear"]},
		{"id": "e_drop", "name": "Crane Drops to Horse", "in": "crane", "out": "horse", "anim": "ual2/NinjaJump_Land", "pulse": "stomp", "dur": 0.7, "power": 7, "chi": 5, "breath": "out", "tags": ["rooted"]},
		# Expansion movements (Roots of the Mountain)
		{"id": "e_bridge", "name": "Iron Bridge (Tit Kiu)", "in": "horse", "out": "horse", "anim": "ual2/Sword_Block", "pulse": "push", "dur": 0.8, "power": 5, "chi": 3, "breath": "hold", "tags": ["rooted"], "req": "e_armor"},
		{"id": "e_double_tiger", "name": "Double Tiger Claws (Seung Fu Jaau)", "in": "bow", "out": "bow", "anim": "ual1/Push", "pulse": "push", "dur": 0.55, "power": 8, "chi": 5, "breath": "out", "tags": ["linear", "rooted"], "req": "e_gloves"},
		{"id": "e_butterfly", "name": "Butterfly Palms (Wu Dip Jeung)", "in": "bow", "out": "horse", "anim": "ual1/Push", "pulse": "push", "dur": 0.7, "power": 9, "chi": 7, "breath": "out", "tags": ["rooted", "rising"], "req": "e_boulder"},
		{"id": "e_listen", "name": "Listening Horse", "in": "horse", "out": "cat", "anim": "ual1/Spell_Simple_Enter", "pulse": "", "dur": 0.5, "power": 2, "chi": 1, "breath": "in", "tags": ["rooted", "evasive"], "req": "e_seismic"},
	],
	"water": [
		{"id": "w_open", "name": "Commencing Form", "in": "wuji", "out": "wuji", "anim": "ual1/Spell_Simple_Enter", "pulse": "", "dur": 0.6, "power": 2, "chi": 1, "breath": "in", "tags": ["circle"]},
		{"id": "w_cloud", "name": "Cloud Hands", "in": "wuji", "out": "bow", "anim": "ual2/Sword_Regular_C", "pulse": "sweep", "dur": 0.7, "power": 5, "chi": 4, "breath": "out", "tags": ["circle"]},
		{"id": "w_brush", "name": "Brush Knee, Twist Step", "in": "bow", "out": "bow", "anim": "ual2/Sword_Regular_A", "pulse": "sweep", "dur": 0.55, "power": 4, "chi": 3, "breath": "in", "tags": ["circle"]},
		{"id": "w_push", "name": "Push Hands", "in": "bow", "out": "bow", "anim": "ual1/Push", "pulse": "push", "dur": 0.7, "power": 6, "chi": 4, "breath": "out", "tags": ["linear"]},
		{"id": "w_whip", "name": "Single Whip", "in": "bow", "out": "whip", "anim": "ual1/Spell_Simple_Shoot", "pulse": "push", "dur": 0.5, "power": 7, "chi": 5, "breath": "out", "tags": ["linear"]},
		{"id": "w_part", "name": "Parting the Wild Horse's Mane", "in": "whip", "out": "empty", "anim": "ual2/Melee_Hook", "pulse": "sweep", "dur": 0.55, "power": 6, "chi": 5, "breath": "in", "tags": ["circle"]},
		{"id": "w_wave", "name": "Wave Hands Like Clouds", "in": "empty", "out": "wuji", "anim": "ual2/Sword_Regular_C", "pulse": "sweep", "dur": 0.7, "power": 6, "chi": 5, "breath": "out", "tags": ["circle"]},
		{"id": "w_return", "name": "Return to the Tide", "in": "empty", "out": "bow", "anim": "ual1/Interact", "pulse": "push", "dur": 0.6, "power": 4, "chi": 3, "breath": "hold", "tags": ["circle", "evasive"]},
		# Expansion movements (The Turning Tide)
		{"id": "w_sparrow", "name": "Grasp the Sparrow's Tail", "in": "wuji", "out": "bow", "anim": "ual2/Sword_Regular_C", "pulse": "sweep", "dur": 0.8, "power": 6, "chi": 4, "breath": "in", "tags": ["circle"], "req": "w_octopus"},
		{"id": "w_needle", "name": "Needle at the Sea Bottom", "in": "empty", "out": "empty", "anim": "ual2/Sword_Regular_A", "pulse": "push", "dur": 0.55, "power": 7, "chi": 5, "breath": "out", "tags": ["linear"], "req": "w_ice_prison"},
		{"id": "w_fan", "name": "Fan Through the Back", "in": "bow", "out": "whip", "anim": "ual1/Push", "pulse": "push", "dur": 0.6, "power": 8, "chi": 6, "breath": "out", "tags": ["linear", "circle"], "req": "w_surge"},
		{"id": "w_snake", "name": "Snake Creeps Down", "in": "whip", "out": "empty", "anim": "ual2/NinjaJump_Land", "pulse": "stomp", "dur": 0.65, "power": 5, "chi": 3, "breath": "in", "tags": ["circle", "evasive"], "req": "w_vines"},
	],
	"air": [
		{"id": "a_walk", "name": "Circle Walking", "in": "circle", "out": "circle", "anim": "ual1/Walk", "pulse": "", "dur": 0.5, "power": 2, "chi": 1, "breath": "in", "tags": ["evasive", "circle"]},
		{"id": "a_change", "name": "Single Palm Change", "in": "circle", "out": "palm", "anim": "ual1/Spell_Simple_Shoot", "pulse": "push", "dur": 0.45, "power": 5, "chi": 3, "breath": "out", "tags": ["circle"]},
		{"id": "a_rest", "name": "Palm Rests on the Wind", "in": "palm", "out": "palm", "anim": "ual1/Spell_Simple_Enter", "pulse": "", "dur": 0.4, "power": 2, "chi": 1, "breath": "in", "tags": ["evasive"]},
		{"id": "a_double", "name": "Double Palm Change", "in": "palm", "out": "twist", "anim": "ual2/Sword_Regular_C", "pulse": "sweep", "dur": 0.65, "power": 6, "chi": 5, "breath": "out", "tags": ["circle"]},
		{"id": "a_kou", "name": "Kou Bai Turn", "in": "twist", "out": "circle", "anim": "ual1/Roll", "pulse": "", "dur": 0.6, "power": 2, "chi": 2, "breath": "in", "tags": ["evasive"]},
		{"id": "a_push", "name": "Pushing the Mountain", "in": "palm", "out": "rooster", "anim": "ual1/Push", "pulse": "push", "dur": 0.7, "power": 7, "chi": 5, "breath": "out", "tags": ["linear"]},
		{"id": "a_rooster", "name": "Golden Rooster Stands", "in": "rooster", "out": "circle", "anim": "ual2/NinjaJump_Land", "pulse": "stomp", "dur": 0.7, "power": 7, "chi": 6, "breath": "out", "tags": ["rising"]},
		{"id": "a_slip", "name": "Slipping the Wind", "in": "twist", "out": "palm", "anim": "ual2/Melee_Hook", "pulse": "sweep", "dur": 0.4, "power": 4, "chi": 3, "breath": "hold", "tags": ["evasive", "circle"]},
		# Expansion movements (The Thirty-Six Winds)
		{"id": "a_swim", "name": "Swimming Body (You Shen)", "in": "circle", "out": "twist", "anim": "ual1/Roll", "pulse": "", "dur": 0.55, "power": 4, "chi": 2, "breath": "in", "tags": ["evasive", "circle"], "req": "a_glider"},
		{"id": "a_lion", "name": "Lion Opens Its Mouth", "in": "palm", "out": "circle", "anim": "ual1/Push", "pulse": "push", "dur": 0.6, "power": 8, "chi": 6, "breath": "out", "tags": ["circle"], "req": "a_vortex"},
		{"id": "a_dragon_turn", "name": "Yellow Dragon Turns Over", "in": "twist", "out": "rooster", "anim": "ual2/Sword_Regular_C", "pulse": "sweep", "dur": 0.65, "power": 6, "chi": 4, "breath": "out", "tags": ["circle", "rising"], "req": "a_shield"},
		{"id": "a_still", "name": "Standing Like a Post (Zhan Zhuang)", "in": "rooster", "out": "palm", "anim": "ual1/Spell_Simple_Enter", "pulse": "", "dur": 0.6, "power": 2, "chi": 1, "breath": "hold", "tags": ["evasive"], "req": "a_breath"},
	],
}

## How the element leaves the body at the end of the form.
const RELEASES := {
	"strike": {"name": "Strike (a single blast)", "kind": "projectile", "mult": 1.0},
	"wave": {"name": "Wave (a cone in front)", "kind": "cone", "mult": 0.85},
	"wall": {"name": "Wall (a barrier)", "kind": "wall", "mult": 0.0},
	"burst": {"name": "Burst (a ring around you)", "kind": "quake", "mult": 0.6},
	"volley": {"name": "Volley (a fan of shards)", "kind": "volley", "mult": 0.45},
	"pillar": {"name": "Pillar (a column under the target, left standing)", "kind": "pillar", "mult": 0.9},
}
const ART_RELEASES := {"fire": ["strike", "wave", "burst"], "earth": ["strike", "wall", "burst", "volley", "pillar"], "water": ["strike", "wave", "volley", "wall"], "air": ["strike", "wave", "burst"]}
const FX := {"fire": "fire", "earth": "rock", "water": "water", "air": "air"}
const MAX_MOVES := 6

static func art_of(bend: String) -> String:
	match bend:
		"blue_fire": return "fire"
		"sand": return "earth"
	return bend if MOVES.has(bend) else ""

static func move(art: String, id: String) -> Dictionary:
	for m in MOVES.get(art, []):
		if m.id == id:
			return m
	return {}

## Which movements can follow `last` (stance continuity). Expansion movements
## appear only once their technique is learned (`known`), and only while their
## expansion is switched on.
static func next_moves(art: String, last_id: String, known: Array = []) -> Array:
	var pool: Array = MOVES.get(art, []).filter(func(m): return not m.has("req") or (known.has(m.req) and DLC.enabled(art)))
	if last_id == "":
		return pool
	var last := move(art, last_id)
	return pool.filter(func(m): return m.in == last.out)

const DLC = preload("res://scripts/dlc/registry.gd")

## Compute a form's stats and properties from its movements.
## form: {"name", "art", "moves": [ids], "release", "uses"}
static func evaluate(form: Dictionary) -> Dictionary:
	var art: String = form.get("art", "")
	var ids: Array = form.get("moves", [])
	var out := {"valid": true, "errors": [], "notes": [], "power": 0.0, "windup": 0.0, "chi": 0.0, "props": []}
	if ids.size() < 2:
		out.valid = false
		out.errors.append("A form needs at least two movements.")
	if ids.size() > MAX_MOVES:
		out.valid = false
		out.errors.append("A form can hold at most %d movements." % MAX_MOVES)
	var seen := {}
	var tags := {}
	var prev: Dictionary = {}
	var breath_run := 0
	var power := 0.0
	var dur := 0.0
	var chi := 0.0
	var holds := 0
	for i in ids.size():
		var m := move(art, ids[i])
		if m.is_empty():
			out.valid = false
			out.errors.append("Unknown movement.")
			continue
		if not prev.is_empty() and prev.out != m.in:
			out.valid = false
			out.errors.append("%s ends in %s; %s starts in %s." % [prev.name, STANCES[art][prev.out], m.name, STANCES[art][m.in]])
		var contrib := float(m.power)
		if seen.has(m.id):
			contrib *= 0.5   # repetition dulls a movement
		seen[m.id] = true
		# breath: two exhales in a row lose force on the second
		if not prev.is_empty() and prev.breath == "out" and m.breath == "out":
			breath_run += 1
			contrib *= 0.8
		if m.breath == "hold":
			holds += 1
		power += contrib
		dur += m.dur
		chi += m.chi
		for t in m.tags:
			tags[t] = int(tags.get(t, 0)) + 1
		prev = m
	if breath_run > 0:
		out.notes.append("Exhaling twice in a row weakens %d movement%s. Breathe in between strikes." % [breath_run, "" if breath_run == 1 else "s"])
	# Each art rewards its own principle
	var flow := 1.0
	match art:
		"water":
			flow += 0.08 * int(tags.get("circle", 0))
			if int(tags.get("circle", 0)) >= 2:
				out.props.append("redirecting")
		"earth":
			flow += 0.1 * int(tags.get("rooted", 0))
			if int(tags.get("rooted", 0)) >= 2:
				out.props.append("staggering")
		"fire":
			flow += 0.06 * int(tags.get("linear", 0)) + 0.1 * int(tags.get("breath", 0))
			if int(tags.get("linear", 0)) >= 3:
				out.props.append("piercing")
		"air":
			flow += 0.08 * int(tags.get("evasive", 0))
			if int(tags.get("evasive", 0)) >= 1:
				out.props.append("evasive")
	if holds >= 1:
		flow += 0.15
		out.props.append("charged")
	if int(tags.get("rising", 0)) >= 1:
		out.props.append("launching")
	var rel: Dictionary = RELEASES.get(form.get("release", "strike"), RELEASES.strike)
	var polish := clampf(float(form.get("uses", 0)) / 40.0, 0.0, 0.25)
	out.power = power * flow
	out.windup = dur * (1.0 - polish)
	out.chi = 6.0 + chi + 2.0 * ids.size() * ids.size()
	out.ability = _ability(art, rel, out, form.get("release", "strike"))
	return out

## Translate a form into the battle's ability format.
static func _ability(art: String, rel: Dictionary, ev: Dictionary, rel_id: String) -> Dictionary:
	var p: float = ev.power
	var props: Array = ev.props
	var a := {"name": "Form", "kind": rel.kind, "cost": ev.chi, "cd": 1.0 + ev.windup * 1.2, "fx": FX.get(art, "fire"),
		"sfx": {"fire": "fire", "earth": "earth", "water": "water", "air": "air"}.get(art, "fire"), "effect": ""}
	match rel.kind:
		"projectile":
			a.merge({"dmg": p * 1.3 * rel.mult, "speed": 30.0, "radius": 0.5 if art != "air" else 1.0, "knock": 3.0 + p * 0.2,
				"gravity": 5.0 if art == "earth" else 0.0, "range": 30.0})
		"cone":
			a.merge({"dmg": p * 1.1 * rel.mult, "range": 6.0 + p * 0.08, "angle": 55.0, "knock": 4.0 + p * 0.2})
		"quake":
			a.merge({"dmg": p * 0.8 * rel.mult, "range": 6.0 + p * 0.1, "stun": 0.8 + p * 0.03, "knock": 3.0 + p * 0.25})
		"volley":
			a.merge({"dmg": p * 0.7 * rel.mult, "speed": 34.0, "radius": 0.3, "knock": 1.5, "gravity": 0.0, "range": 26.0, "count": 3 + int(p / 12.0), "spread": 24.0})
			if art == "water":
				a.fx = "ice"
		"pillar":
			a.merge({"dmg": p * 1.0 * rel.mult, "range": 14.0, "radius": 0.9, "height": 2.6 + p * 0.03, "knock": 2.0, "launch": 8.0 + p * 0.1})
		"wall":
			a.merge({"width": 4.0 + p * 0.06, "height": 2.2 + p * 0.03, "life": 8.0 + p * 0.2, "dist": 3.0})
			if art == "water":
				a.fx = "ice"
	if "piercing" in props:
		a.pierce = true
	if "redirecting" in props or (art == "water" and rel.kind != "wall"):
		a.effect = "slow"
	if art == "fire":
		a.effect = "burn"
	if "staggering" in props and a.has("knock"):
		a.knock = float(a.knock) * 1.5
	if "evasive" in props and a.has("knock"):
		a.knock = float(a.knock) + 6.0
	if "launching" in props and a.has("knock"):
		a.knock = float(a.knock) + 3.0
	if "charged" in props and a.has("dmg"):
		a.dmg = float(a.dmg) * 1.15
	return a

## A sensible starter form for each art, so the F key works from day one.
static func starter(art: String) -> Dictionary:
	match art:
		"fire": return {"name": "Breath of the Dragon", "art": "fire", "moves": ["f_jab", "f_step", "f_empty"], "release": "strike", "uses": 0}
		"earth": return {"name": "The Mountain Answers", "art": "earth", "moves": ["e_root", "e_tiger", "e_cat", "e_crane"], "release": "strike", "uses": 0}
		"water": return {"name": "Tide Turning", "art": "water", "moves": ["w_open", "w_cloud", "w_brush", "w_whip"], "release": "wave", "uses": 0}
		"air": return {"name": "Wind Around the Pine", "art": "air", "moves": ["a_walk", "a_change", "a_rest", "a_push"], "release": "wave", "uses": 0}
	return {}

## Suggest a name from the movements (players can type their own).
static func suggest_name(form: Dictionary) -> String:
	var art: String = form.get("art", "")
	var n: int = form.get("moves", []).size()
	var nums := ["", "", "Twin", "Three", "Four", "Five", "Six"]
	var nouns := {"fire": ["Embers", "Suns", "Dragons", "Sparks"], "earth": ["Mountains", "Stones", "Roots", "Tigers"], "water": ["Tides", "Clouds", "Rivers", "Moons"], "air": ["Winds", "Palms", "Feathers", "Circles"]}
	var verbs := {"fire": "Rising", "earth": "Standing", "water": "Turning", "air": "Turning"}
	var pool: Array = nouns.get(art, ["Forms"])
	return "%s %s %s" % [nums[clampi(n, 0, 6)], pool[hash(str(form.get("moves", []))) % pool.size()], verbs.get(art, "")]
