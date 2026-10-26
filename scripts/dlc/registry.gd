extends RefCounted
## The four element expansions. Each is self-contained: a story file (new
## characters, quests and a mastery trial), techniques in
## scripts/battle/techniques.gd, movements in scripts/battle/forms.gd, and
## non-combat bending work in scripts/core/bending_work.gd, all tagged with the
## element. Each can be switched off in Settings; content then disappears
## cleanly (saved progress is kept and returns when it is switched back on).

const EXPANSIONS := {
	"fire": {"name": "Embers of the First Flame", "tagline": "Fire is breath before it is anything else.",
		"story": "res://scripts/dlc/fire_story.gd", "companion": "sayuri"},
	"water": {"name": "The Turning Tide", "tagline": "Water remembers every shape it has held.",
		"story": "res://scripts/dlc/water_story.gd", "companion": "huan"},
	"earth": {"name": "Roots of the Mountain", "tagline": "Listen to the ground before you move it.",
		"story": "res://scripts/dlc/earth_story.gd", "companion": "gao_ming"},
	"air": {"name": "The Thirty-Six Winds", "tagline": "Freedom is a discipline.",
		"story": "res://scripts/dlc/air_story.gd", "companion": "yangzom"},
}

static func enabled(el: String) -> bool:
	if not EXPANSIONS.has(el):
		return true
	return bool(GS.settings.get("dlc_" + el, true))

static func story_sources() -> Array:
	var out := []
	for el in EXPANSIONS:
		out.append(EXPANSIONS[el].story)
	return out

## Is this companion's expansion switched on?
static func companion_enabled(cid: String) -> bool:
	for el in EXPANSIONS:
		if EXPANSIONS[el].companion == cid:
			return enabled(el)
	return true
