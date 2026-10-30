extends RefCounted
## Expansion: The Turning Tide (water). New people: Huan of the Foggy Swamp
## (companion), Master Yura of Wolf's Crown, Governor Lu of the Jade Terraces.
## Stories: the Banyan's fever (Huan); the Red Moon (a lunar eclipse); the
## Moon's Road mastery trial. Techniques: scripts/battle/techniques.gd.

const NPCS := {
	"yura": {"name": "Master Yura", "culture": "south", "vlook": {"sex": "f", "hair": "Hair_Long", "hair_color": Color(0.85, 0.85, 0.85), "height": 0.92}, "kit": "water_fur"},
	"governor_lu": {"name": "Governor Lu", "culture": "earth", "vlook": {"sex": "m", "hair": "Hair_SimpleParted", "accessory": "ek_hat"}, "kit": "civ_robe"},
	"kaya": {"name": "Kaya", "culture": "north", "vlook": {"sex": "f", "hair": "Hair_Long", "height": 0.62}, "kit": "water_fur"},
}

const SPAWNS := {}

const TRIGGERS := [
	{"on": "daily", "dlg": "wx_huan_start", "if": {"companion": "huan", "days_since": ["joined_huan", 5]}},
	{"on": "daily", "dlg": "wx_red_moon", "if": {"cosmic": "lunar", "bend": "water"}},
]

const OPTIONS := [
	{"sid": "southern_tribe", "text": "Train with Master Yura on the canals", "dlg": "wx_yura", "if": {"bend": "water"}},
	{"sid": "agna_qela", "text": "Train on the ice with Master Aklaq and Elder Pana", "dlg": "wx_north", "if": {"bend": "water"}},
	{"sid": "foggy_swamp", "text": "Go with Huan to the great banyan", "dlg": "wx_banyan", "if": {"companion": "huan", "flag": "huan_q", "not_flag": "huan_found"}},
	{"sid": "agrarian_vale", "text": "Find out who dammed the river", "dlg": "wx_dam", "if": {"flag": "huan_found", "not_flag": "huan_done"}},
	{"sid": "spirit_fishery", "text": "Walk the last of the Moon's Road", "dlg": "wx_moon_end", "if": {"flag": "wx_moon_road", "not_flag": "wx_master", "cosmic": "full_moon"}},
]

const DIALOGUES := {
	# -----------------------------------------------------------------------
	# Huan
	# -----------------------------------------------------------------------
	"talk_huan": {"title": "Huan", "start": "hub", "nodes": {
		"hub": {"who": "huan", "expr": "neutral", "text": "Oh. Hello. I was listening to that tree. It's not saying anything interesting. Trees mostly aren't. That's what I like about them.", "choices": [
			{"text": "\"Does the swamp really remember people?\"", "next": "remember"},
			{"text": "\"How are you doing, with all the crowds?\"", "next": "crowds"},
			{"text": "\"Have you ever been in love?\"", "next": "love", "if": {"approval": ["huan", 25]}, "hide": true},
			{"text": "\"Show me how to bend the water in a vine.\" (Vine Snare)", "next": "learn_vines", "if": {"bend": "water", "approval": ["huan", 15], "no_tech": "w_vines"}, "hint": "waterbenders only; Huan's approval 15"},
			{"text": "\"Show me the mist.\" (Mist Veil)", "next": "learn_mist", "if": {"bend": "water", "approval": ["huan", 30], "no_tech": "w_mist"}, "hint": "waterbenders only; Huan's approval 30"},
			{"text": "\"Let's keep moving.\"", "next": ""},
		]},
		"remember": {"who": "huan", "expr": "thoughtful", "text": "Water remembers every shape it's held. The swamp is mostly water. So, yes. My grandmother's in there somewhere, and a lot of frogs, and a very angry heron from about two hundred years ago. You'll be in there now too. Sorry. I should have asked.", "next": "hub"},
		"crowds": {"who": "huan", "expr": "embarrassed", "text": "Badly. Towns are too many people talking at once, and none of them are trees. I count the roof tiles. You've been letting me walk at the back. I noticed. Thank you.", "do": [["approval", "huan", 2]], "next": "hub"},
		"love": {"who": "huan", "expr": "happy", "text": "No. Not like that. Not ever, I think. I love the swamp, and my sister, and you lot, a bit. It's a good amount of love. It just doesn't come in the shape the songs want. I stopped thinking that was a problem when I was twenty. It's very restful.", "next": "hub"},
		"learn_vines": {"who": "huan", "expr": "happy", "text": "Every vine is a river standing up. Ask the water in it to sit down. Politely. — There, it's holding his ankle. Well, my ankle. It's fine. I'm fine. Let go now. Please let go.",
			"do": [["wait", 24.0], ["learn", "w_vines"], ["approval", "huan", 3]], "next": "hub"},
		"learn_mist": {"who": "huan", "expr": "thoughtful", "text": "The air is wet. Most people forget. You don't make fog; you just remind the water that it's there. Breathe out slowly and lift. Like a blanket. Now you've lost me. Good. That's the point.",
			"do": [["wait", 24.0], ["learn", "w_mist"], ["approval", "huan", 3]], "next": "hub"},
	}},
	"leave_generic_huan": {"title": "Huan", "start": "a", "nodes": {"a": {"who": "huan", "expr": "sad", "text": "The swamp remembers what people do. I don't want it to remember me next to this. I'm going home. I'll tell the trees you weren't always like this.", "do": [["leave", "huan"]]}}},
	"wx_huan_start": {"title": "Huan", "start": "a", "nodes": {
		"a": {"who": "huan", "expr": "afraid", "text": "The great banyan is sick. It's the oldest thing in the swamp. Its roots are the swamp, more or less. Its leaves are going brown at the edges. My sister wrote. She doesn't write. So it's bad.", "next": "b"},
		"b": {"who": "huan", "expr": "determined", "text": "I don't know how to fix a tree that big. I don't even know what's wrong with it. But I'd like to go and sit with it. And I'd like you to come. People notice things trees don't.",
			"do": [["flag", "huan_q", true], ["journal", "wx_huan", "Huan: The Banyan's Fever", "The great banyan of the Foggy Swamp is sick. Go there with Huan."]]},
	}},
	"wx_banyan": {"title": "The Banyan's Fever", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The great banyan stands in a lake of its own roots, wider than a town square. Huan puts both palms on a root and goes very still. Fireflies settle on his shoulders and he doesn't notice.", "next": "b"},
		"b": {"who": "huan", "expr": "sad", "text": "It's thirsty. In a swamp. That's — the water's lower. All of it. Something upstream is holding the river back. It's been going on for a year. The tree's been trying to tell us. We weren't listening; we thought it was just being old.", "next": "c"},
		"c": {"who": "narrator", "text": "You follow the river north for two days, Huan muttering to it the whole way, until you find the answer: a new stone dam above the Jade Terraces, holding a lake that waters terraces for a hundred families.",
			"do": [["flag", "huan_found", true], ["wait", 48.0], ["journal", "wx_huan", "Huan: The Banyan's Fever", "A new dam above the Jade Terraces is starving the Foggy Swamp of water. Find out who built it."]]},
	}},
	"wx_dam": {"title": "The Banyan's Fever", "start": "a", "nodes": {
		"a": {"who": "governor_lu", "expr": "neutral", "text": "The dam? Mine. Two dry years and the terraces failed. A hundred families. Now they eat. I'm sorry about your swamp, truly; I didn't know it was downstream. Nobody goes to the swamp. That's rather the point of a swamp.", "next": "b"},
		"b": {"who": "huan", "expr": "embarrassed", "text": "He's not wrong. Nobody does. — But the tree.", "choices": [
			{"text": "\"Open the dam. The swamp was here first.\" (Break it)", "next": "break"},
			{"text": "\"Share the water: the dam opens three days in seven.\" (Trade 3, or 800 gold for the sluice)", "next": "share", "if": {"call": "wx_can_share"}, "hint": "needs Trade 3 or 800 gold"},
			{"text": "\"Let's ask the river.\" (A waterbender and an earthbender reroute a spring)", "next": "river", "if": {"bends": "earth"}, "hint": "needs an earthbender in the party, as well as Huan"},
		]},
		"break": {"who": "narrator", "text": "Huan lifts the lake over the dam in one long, grieving wave. The terraces flood, then drain, then crack in the sun by summer. The banyan greens within a month. Governor Lu writes to Ba Sing Se about you.",
			"do": [["flag", "huan_done", true], ["flag", "huan_broke_dam", true], ["prosperity", "agrarian_vale", -15], ["prosperity", "foggy_swamp", 12], ["rel", "earth_kingdom", -15], ["approval", "huan", 5], ["infamy", 10, "breaking the Jade Terraces dam"],
				["journal_done", "wx_huan", "You broke the dam. The banyan recovered. The Jade Terraces did not."]]},
		"share": {"who": "governor_lu", "expr": "thoughtful", "text": "Three days in seven. The terraces can live with that if we plant later. And I suppose the swamp can live with it if it's patient. Is a swamp patient?", "next": "share2"},
		"share2": {"who": "huan", "expr": "happy", "text": "Very. Thank you. It'll remember you. I mean that as a compliment. Mostly.",
			"do": [["call", "wx_pay_share"], ["flag", "huan_done", true], ["flag", "huan_shared", true], ["prosperity", "foggy_swamp", 6], ["approval", "huan", 12], ["renown", 10],
				["journal_done", "wx_huan", "The dam opens three days in seven. The terraces and the swamp both drink."]]},
		"river": {"who": "narrator", "text": "It takes a week. Your earthbender opens a fault in the hill above the dam; Huan coaxes a buried spring up through it, into a new channel that feeds the terraces from above. The dam is lowered by half. The river runs to the swamp again.", "next": "river2"},
		"river2": {"who": "huan", "expr": "laugh", "text": "Two kinds of bending, one problem, nobody loses. The swamp's never seen that before. It's very confused. I think it's happy.",
			"do": [["wait", 168.0], ["flag", "huan_done", true], ["flag", "huan_river", true], ["prosperity", "foggy_swamp", 12], ["prosperity", "agrarian_vale", 8], ["approval", "huan", 20], ["renown", 25], ["rel", "earth_kingdom", 5],
				["journal_done", "wx_huan", "An earthbender and a swampbender rerouted a spring. The terraces and the swamp both prosper, and Huan has stopped worrying about the tree."]]},
	}},

	# -----------------------------------------------------------------------
	# Master Yura (Southern Tide Style)
	# -----------------------------------------------------------------------
	"wx_yura": {"title": "Master Yura", "start": "hub", "nodes": {
		"hub": {"who": "yura", "expr": "smirk", "text": "Northern waterbending is a beautiful poem about ice. Southern waterbending is a slap. Which one do you want to learn?", "choices": [
			{"text": "Learn the Octopus Form (two days; Bending 5)", "next": "octo", "if": {"no_tech": "w_octopus", "skill": ["bending", 5]}, "hint": "needs Bending 5"},
			{"text": "Learn the Tidal Surge (two days; Bending 4; 300 gold for the canal fees)", "next": "surge", "if": {"no_tech": "w_surge", "skill": ["bending", 4], "gold": 300}, "hint": "needs Bending 4 and 300 gold"},
			{"text": "\"Why don't you like the North's style?\"", "next": "north"},
			{"text": "\"Another time.\"", "next": ""},
		]},
		"octo": {"who": "yura", "expr": "determined", "text": "Eight arms. You have two. Stop counting your arms. The water doesn't care how many arms you have; it cares whether you're listening in every direction at once.",
			"do": [["wait", 48.0], ["learn", "w_octopus"]], "next": "hub"},
		"surge": {"who": "yura", "expr": "laugh", "text": "Get low. Lower. That's a wave, not a sneeze. — Better. You just knocked my nephew into the canal. He'll live. He usually does.",
			"do": [["gold", -300], ["wait", 48.0], ["learn", "w_surge"]], "next": "hub"},
		"north": {"who": "yura", "expr": "thoughtful", "text": "I like it fine. Aklaq and I trained together sixty years ago. He was better at stillness. I was better at everything else. We still write. Every letter starts with an insult. It's the closest thing either of us has to a brother.", "next": "hub"},
	}},

	# -----------------------------------------------------------------------
	# The North: ice and healing
	# -----------------------------------------------------------------------
	"wx_north": {"title": "The Training Ice", "start": "hub", "nodes": {
		"hub": {"who": "aklaq", "expr": "neutral", "text": "Outsiders train on the outer ice. Mind the cracks; they are there to teach humility. What do you want?", "choices": [
			{"text": "Learn the Ice Lance (two days; Bending 4)", "next": "lance", "if": {"no_tech": "w_ice_lance", "skill": ["bending", 4]}, "hint": "needs Bending 4"},
			{"text": "Learn the Ice Prison (three days; Bending 5)", "next": "prison", "if": {"no_tech": "w_ice_prison", "skill": ["bending", 5]}, "hint": "needs Bending 5"},
			{"text": "Ask Elder Pana to teach Chi-Path Healing (three days; Healing 3)", "next": "heal", "if": {"no_tech": "w_chi_heal", "skill": ["healing", 3]}, "hint": "needs Healing 3"},
			{"text": "\"I want to walk the Moon's Road.\" (the mastery trial)", "next": "moon", "if": {"not_flag": "wx_moon_road", "call": "not_master", "skill": ["bending", 7], "techs": ["water", 3], "duel_wins": 1}, "hint": "Bending 7, three water techniques and a duel won"},
			{"text": "\"Another time.\"", "next": ""},
		]},
		"lance": {"who": "aklaq", "expr": "determined", "text": "Freeze it at the last instant, not the first. Water in flight; ice on arrival. — Again. You froze your own sleeve. Again.",
			"do": [["wait", 48.0], ["learn", "w_ice_lance"]], "next": "hub"},
		"prison": {"who": "aklaq", "expr": "thoughtful", "text": "Wrap, then still. Most people try to still it first and only catch air. You'll do the same for a day. Then you won't.",
			"do": [["wait", 72.0], ["learn", "w_ice_prison"]], "next": "hub"},
		"heal": {"who": "pana", "expr": "tender", "text": "Close your eyes. Feel my wrist under the water. There: the chi moves like a river with rocks in it. Healing is moving the rocks. Gently. Rocks have feelings too, in their way.",
			"do": [["wait", 72.0], ["learn", "w_chi_heal"]], "next": "hub"},
		"moon": {"who": "aklaq", "expr": "neutral", "text": "The Moon's Road is the oldest test we have. Walk from here to the Moon Fishery on the sea, on ice you make yourself, by the light of a full moon, and finish the walk there. If you sink, swim. If you swim, start again.",
			"do": [["flag", "wx_moon_road", true], ["journal", "wx_trial", "The Moon's Road", "Master Aklaq set the Moon's Road: travel to the Moon Fishery and, on a full-moon night, walk the last of the road there on ice you make yourself."]], "next": "hub"},
	}},
	"wx_moon_end": {"title": "The Moon's Road", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The full moon lays a white road on the black sea. You step off the shore and make ice under your foot, and again, and again, a step at a time, the cold climbing your legs, the fishery lights very far away.", "choices": [
			{"text": "Keep walking.", "next": "kaya", "if": {"flag": "two_paths"}, "hide": true},
			{"text": "Keep walking.", "next": "b", "if": {"not_flag": "two_paths"}, "hide": true},
		]},
		"kaya": {"who": "kaya", "expr": "happy", "text": "(from a canoe, much too loudly) You're doing it wrong! Mama says breathe out on the step, not in! — Sorry. Hello. You're doing it a bit wrong.", "next": "b"},
		"b": {"who": "narrator", "text": "Halfway, the ice under you cracks, and you understand, all at once, that you have been fighting the sea. You stop. You let it hold you instead. The next step is easy. So is the one after. The fishery's lamps come up out of the dark like a held breath let go.", "next": "c"},
		"c": {"who": "narrator", "text": "Aklaq is waiting on the jetty, wrapped in three parkas, looking as if he has not worried at all.", "next": "d"},
		"d": {"who": "aklaq", "expr": "smirk", "text": "Late. Wet. Alive. That is a master's walk. Most of them are. — Go and get warm, Master.",
			"do": [["master", "water"], ["flag", "wx_master", true], ["learn", "w_ice_prison"], ["renown", 40], ["journal_done", "wx_trial", "You walked the Moon's Road on your own ice. Master Aklaq named you a Master Waterbender."]]},
	}},

	# -----------------------------------------------------------------------
	# The Red Moon (a lunar eclipse)
	# -----------------------------------------------------------------------
	"wx_red_moon": {"title": "The Red Moon", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The full moon turns the colour of rust. The swell of strength every waterbender feels on a full-moon night drains away at the same moment, as if a door had closed somewhere. Around your camp, people who have bent water since childhood sit very still and look up.", "next": "b"},
		"b": {"who": "narrator", "text": "You sit with it. The moon's gift is gone for an hour; the bending is not. The water is where it always was, in the cup by your knee, in the dew on the grass. It answers you as it always has, a little more quietly. You were never commanding it. You were only ever in conversation.", "next": "c"},
		"c": {"who": "narrator", "text": "When the moon comes back, the tide in you comes back slightly differently, as if it has heard something you said.",
			"do": [["attr_points", 1], ["log", "The Red Moon taught you something about water. (+1 attribute point)"]]},
	}},
}
