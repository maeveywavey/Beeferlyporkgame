extends RefCounted
## Expansion: The Thirty-Six Winds (air). New people: Yangzom (companion),
## Abbot Dorje, Abbot Lhakpa and Abbess Yeshe (the abbots finally speak).
## Stories: the Lost Herd (Yangzom); the Thirty-Six Winds mastery trial, one
## test at each temple, which earns an airbender the arrows.

const NPCS := {
	"dorje": {"name": "Abbot Dorje", "culture": "air", "vlook": {"sex": "m", "hair": "", "accessory": "air_arrow", "beard": true, "height": 0.95}, "kit": "air_robes"},
	"lhakpa": {"name": "Abbot Lhakpa", "culture": "air", "vlook": {"sex": "m", "hair": "", "accessory": "air_arrow", "height": 1.04}, "kit": "air_robes"},
	"yeshe": {"name": "Abbess Yeshe", "culture": "air", "vlook": {"sex": "f", "hair": "", "accessory": "air_arrow"}, "kit": "air_robes"},
	"smuggler": {"name": "Captain Mako", "culture": "outlaw", "vlook": {"sex": "m", "hair": "Hair_SimpleParted", "accessory": "bandana"}, "kit": "sash", "outfit": "ranger"},
}

const SPAWNS := {
	"bison_smugglers": {"name": "Bison Smugglers", "scale": true, "troops": [["pirate", 10], ["pirate_captain", 2], ["merc_archer", 4]], "gold": 500,
		"on_defeat": [["flag", "herd_freed", true], ["queue", "ax_herd_home"]]},
}

const TRIGGERS := [
	{"on": "daily", "dlg": "ax_yangzom_start", "if": {"companion": "yangzom", "days_since": ["joined_yangzom", 5]}},
]

const OPTIONS := [
	{"sid": "southern_air_temple", "text": "Train with Abbot Dorje", "dlg": "ax_dorje", "if": {"bend": "air"}},
	{"sid": "northern_air_temple", "text": "Train with Abbot Lhakpa", "dlg": "ax_lhakpa", "if": {"bend": "air"}},
	{"sid": "eastern_air_temple", "text": "Sit with Abbess Tsering", "dlg": "ax_tsering", "if": {"bend": "air"}},
	{"sid": "western_air_temple", "text": "Train with Abbess Yeshe", "dlg": "ax_yeshe", "if": {"bend": "air"}},
	{"sid": "full_moon_bay", "text": "Look for the stolen bison calves with Yangzom", "dlg": "ax_herd", "if": {"companion": "yangzom", "flag": "yangzom_q", "not_flag": "yangzom_done"}},
	{"sid": "eastern_air_temple", "text": "Receive the arrows", "dlg": "ax_arrows", "if": {"flags": ["ax_t_dorje", "ax_t_lhakpa", "ax_t_tsering", "ax_t_yeshe"], "not_flag": "ax_master"}},
]

const DIALOGUES := {
	# -----------------------------------------------------------------------
	# Yangzom
	# -----------------------------------------------------------------------
	"talk_yangzom": {"title": "Yangzom", "start": "hub", "nodes": {
		"hub": {"who": "yangzom", "expr": "happy", "text": "Did you feel that? The wind turned. It's a western, coming round north. That's number nineteen. I've got nineteen of the thirty-six now! — Sorry. Hi. What?", "choices": [
			{"text": "\"What are the Thirty-Six Winds?\"", "next": "winds"},
			{"text": "\"Why did you leave the temple?\"", "next": "left"},
			{"text": "\"You don't kill. How does that work, in a war?\"", "next": "vow"},
			{"text": "\"Teach me the Air Ball.\"", "next": "learn_ball", "if": {"bend": "air", "approval": ["yangzom", 10], "no_tech": "a_ball"}, "hint": "airbenders only; Yangzom's approval 10"},
			{"text": "\"Teach me to strike from the air.\" (Glider Strike)", "next": "learn_glider", "if": {"bend": "air", "approval": ["yangzom", 25], "no_tech": "a_glider"}, "hint": "airbenders only; Yangzom's approval 25"},
			{"text": "\"Can I come with you, when you chart the last wind?\"", "next": "rom", "if": {"approval": ["yangzom", 50], "not_flag": "romance_yangzom"}, "hide": true},
			{"text": "\"Let's keep moving.\"", "next": ""},
		]},
		"winds": {"who": "yangzom", "expr": "thoughtful", "text": "The Nomads' old map of the air. Every wind in the world, where it starts, where it goes, who it's friends with. Thirty-six. Nobody's finished it in four hundred years. Most of the old monks charted from the temples. I'm charting from everywhere. It's going badly. It's the best thing I've ever done.", "next": "hub"},
		"left": {"who": "yangzom", "expr": "embarrassed", "text": "I didn't leave, exactly. I went for a long glide and kept going. Abbess Yeshe writes every month to ask when I'm coming back, and every month I write back 'soon'. We both know. It's a nice ritual.", "next": "hub"},
		"vow": {"who": "yangzom", "expr": "determined", "text": "Very carefully. Air is the best element for not killing people. I knock them over, I knock their weapons into the river, I knock them into next week. They wake up sore and alive. Being alive is a very good argument for doing something different tomorrow.", "next": "hub"},
		"learn_ball": {"who": "yangzom", "expr": "laugh", "text": "Spin it. Faster. Faster than that. Now let go — not at me — ow. Perfect. That's the Southern Temple's favourite. They play a game with it that is technically sacred and mostly about knocking each other off walls.",
			"do": [["wait", 24.0], ["learn", "a_ball"], ["approval", "yangzom", 3]], "next": "hub"},
		"learn_glider": {"who": "yangzom", "expr": "happy", "text": "Jump. Open. Lean. Fall on purpose and then change your mind halfway. Landing is a decision you make in the air. Make it early. — You'll bruise. Everyone bruises. I bruised for a year.",
			"do": [["wait", 48.0], ["learn", "a_glider"], ["approval", "yangzom", 3]], "next": "hub"},
		"rom": {"who": "yangzom", "expr": "surprised", "text": "You'd — the last wind's at the bottom of the world, it'll take a year, there's nothing there but ice and one very annoyed penguin colony. — You know that. You're still asking.", "next": "rom2"},
		"rom2": {"who": "yangzom", "expr": "tender", "text": "Nomads don't really do this. Or we do, we just don't write it down. I'd like to write this down. On the map. Wind thirty-six, and you. If that's —", "choices": [
			{"text": "\"Write it down.\"", "next": "rom3", "do": [["flag", "romance_yangzom", true], ["approval", "yangzom", 10]]},
			{"text": "\"I'll see you off. As a friend.\"", "next": "rom_no"},
		]},
		"rom3": {"who": "yangzom", "expr": "laugh", "text": "Okay. Okay! I need to go and glide in a circle for a while. A happy circle. Don't follow me, I'll show off and crash.", "next": "hub"},
		"rom_no": {"who": "yangzom", "expr": "smirk", "text": "That's all right. Friends see each other off. It's practically sacred. I'll name a breeze after you. A small one.", "next": "hub"},
	}},
	"leave_generic_yangzom": {"title": "Yangzom", "start": "a", "nodes": {"a": {"who": "yangzom", "expr": "sad", "text": "I left the temple because I wanted to see the world. I didn't leave it to watch this. I'm going home. I'll tell Abbess Yeshe I was wrong about soon.", "do": [["leave", "yangzom"]]}}},

	# -----------------------------------------------------------------------
	# Yangzom's quest: the Lost Herd
	# -----------------------------------------------------------------------
	"ax_yangzom_start": {"title": "Yangzom", "start": "a", "nodes": {
		"a": {"who": "yangzom", "expr": "angry", "text": "Abbess Yeshe's letter. Six bison calves taken from the Western Temple's high meadow in one night. Nobody can carry a bison calf. Unless you have a ship, and a crane, and no shame.", "next": "b"},
		"b": {"who": "yangzom", "expr": "determined", "text": "The calves were seen being loaded at Full Moon Bay. Someone wants sky bison as war mounts. A calf that's beaten into carrying soldiers forgets how to fly. I'm not letting that happen to six of them.",
			"do": [["flag", "yangzom_q", true], ["journal", "ax_yangzom", "Yangzom: The Lost Herd", "Six sky bison calves were stolen from the Western Air Temple and loaded at Full Moon Bay. Go there with Yangzom."]]},
	}},
	"ax_herd": {"title": "The Lost Herd", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The calves are in a fenced paddock behind a warehouse, huddled together, their fur matted with salt. A man with a ledger and a very good coat is counting them.", "next": "b"},
		"b": {"who": "smuggler", "expr": "smirk", "text": "Commissioned, paid for, collected Thursday. A Fire Navy captain wants mounts that can cross the strait. Not my business what he wants them for. What's your business?", "choices": [
			{"text": "\"Buy them back.\" (1,200 gold)", "next": "buy", "if": {"gold": 1200}, "hint": "need 1,200 gold"},
			{"text": "(Reika) \"Mako. You still owe me for the Cinder Strait.\"", "next": "reika", "if": {"companion": "reika"}, "hide": true},
			{"text": "\"Open the gate, or we open it.\" (Fight the smugglers)", "next": "fight"},
		]},
		"buy": {"who": "smuggler", "expr": "happy", "text": "A buyer who doesn't haggle. They're yours. I'll tell the captain they flew away. Ha. Which they will.",
			"do": [["gold", -1200], ["flag", "herd_freed", true], ["queue", "ax_herd_home"]]},
		"reika": {"who": "reika", "expr": "smirk", "text": "Everyone on this coast owes me for the Cinder Strait. It was a very good storm. — Open the gate, Mako, and I'll forget which captain you're selling to. I won't forget for free a second time.", "next": "reika2"},
		"reika2": {"who": "smuggler", "expr": "embarrassed", "text": "…Kuroda. Fine. FINE. Take your cows.",
			"do": [["approval", "reika", 5], ["flag", "herd_freed", true], ["queue", "ax_herd_home"]]},
		"fight": {"who": "yangzom", "expr": "determined", "text": "Nobody dies. Knock them into the bay; the bay will cope.", "do": [["spawn", "bison_smugglers"], ["close_windows"]]},
	}},
	"ax_herd_home": {"title": "The Lost Herd", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "It takes four days to walk six bison calves to the mountains, and one afternoon for them to remember they can fly. Yangzom flies with them the last stretch, whooping, and comes down at the Western Temple ahead of all of them.", "next": "b"},
		"b": {"who": "yangzom", "expr": "laugh", "text": "They remembered. They just — remembered. — Abbess Yeshe hugged me. She's never hugged anybody. And she gave me this: the old temple map of the winds, the real one, to finish. I'm going to finish it. With you, if you'll keep walking in interesting directions.",
			"do": [["flag", "yangzom_done", true], ["wait", 96.0], ["approval", "yangzom", 20], ["rel", "air_nomads", 15], ["renown", 15], ["companion_mod", "yangzom", "power_bonus", 0.3],
				["journal_done", "ax_yangzom", "The calves are home and flying. Abbess Yeshe gave Yangzom the temple's map of the Thirty-Six Winds to finish."]]},
	}},

	# -----------------------------------------------------------------------
	# The four schools, and the Thirty-Six Winds trial (one test per temple)
	# -----------------------------------------------------------------------
	"ax_dorje": {"title": "The Southern Air Temple", "start": "hub", "nodes": {
		"hub": {"who": "dorje", "expr": "happy", "text": "Southern airbending is a game, and anyone who tells you games aren't serious has never played one with a monk. What would you like?", "choices": [
			{"text": "Learn the Air Ball (a day)", "next": "ball", "if": {"no_tech": "a_ball"}},
			{"text": "Learn the Air Shield (two days; Bending 5)", "next": "shield", "if": {"no_tech": "a_shield", "skill": ["bending", 5]}, "hint": "needs Bending 5"},
			{"text": "Ask for the Southern test of the Thirty-Six Winds", "next": "test", "if": {"not_flag": "ax_t_dorje", "skill": ["bending", 7]}, "hint": "needs Bending 7"},
			{"text": "\"Another time.\"", "next": ""},
		]},
		"ball": {"who": "dorje", "expr": "laugh", "text": "Spin, release, run. Mostly run. — You'll play with the novices tonight. They will beat you. That is also a lesson.", "do": [["wait", 24.0], ["learn", "a_ball"]], "next": "hub"},
		"shield": {"who": "dorje", "expr": "thoughtful", "text": "Air that keeps turning cannot be pushed. Be the thing that keeps turning. — Wonderful. Now do it without looking so worried.", "do": [["wait", 48.0], ["learn", "a_shield"]], "next": "hub"},
		"test": {"who": "dorje", "expr": "neutral", "text": "The Southern test is kindness. Somewhere in this temple today is someone who needs something you have. Find them.", "choices": [
			{"text": "Give your coin to the refugees' kitchens. (300 gold)", "next": "pass", "if": {"gold": 300}, "do": [["gold", -300]], "hint": "need 300 gold"},
			{"text": "Spend the day in the kitchens, peeling and carrying.", "next": "pass", "do": [["wait", 24.0]]},
			{"text": "Look for the person who needs you.", "next": "look"},
		]},
		"look": {"who": "narrator", "text": "You find her by the bison stables: a refugee girl who has not spoken since she arrived. You don't make her talk. You show her how to make a leaf hang in the air. She laughs, once, and then can't stop.", "next": "pass"},
		"pass": {"who": "dorje", "expr": "tender", "text": "Good. That is the Southern wind: the one that brings things to the people who need them.",
			"do": [["flag", "ax_t_dorje", true], ["journal", "ax_trial", "The Thirty-Six Winds", "Pass a test at each of the four Air Temples (Southern: done), then receive the arrows at the Eastern Temple."]], "next": "hub"},
	}},
	"ax_lhakpa": {"title": "The Northern Air Temple", "start": "hub", "nodes": {
		"hub": {"who": "lhakpa", "expr": "smirk", "text": "In the North we fly. Everything else is just walking with ambition. Well?", "choices": [
			{"text": "Learn the Glider Strike (two days; Bending 5)", "next": "glider", "if": {"no_tech": "a_glider", "skill": ["bending", 5]}, "hint": "needs Bending 5"},
			{"text": "Learn the Updraft (two days; Bending 6)", "next": "updraft", "if": {"no_tech": "a_updraft", "skill": ["bending", 6]}, "hint": "needs Bending 6"},
			{"text": "Ask for the Northern test of the Thirty-Six Winds", "next": "test", "if": {"not_flag": "ax_t_lhakpa", "tech": "a_glider", "skill": ["bending", 7]}, "hint": "needs Bending 7 and the Glider Strike"},
			{"text": "\"Another time.\"", "next": ""},
		]},
		"glider": {"who": "lhakpa", "expr": "happy", "text": "Off the terrace. Yes, that one. Yes, it's high. That is rather the point of a terrace.", "do": [["wait", 48.0], ["learn", "a_glider"]], "next": "hub"},
		"updraft": {"who": "lhakpa", "expr": "neutral", "text": "Lift from below, everything at once, like a sudden good mood.", "do": [["wait", 48.0], ["learn", "a_updraft"]], "next": "hub"},
		"test": {"who": "narrator", "text": "The Northern test is a glide from the highest spire to the lowest bell, through the valley's three winds, touching nothing. You touch a cloud. Lhakpa decides clouds don't count.",
			"do": [["flag", "ax_t_lhakpa", true], ["wait", 6.0]], "next": "hub"},
	}},
	"ax_tsering": {"title": "The Eastern Air Temple", "start": "hub", "nodes": {
		"hub": {"who": "tsering", "expr": "tender", "text": "Here we breathe. It sounds easy. Most people have been doing it wrong their whole lives. Sit.", "choices": [
			{"text": "Learn Healing Breath (three days; Healing 2)", "next": "breath", "if": {"no_tech": "a_breath", "skill": ["healing", 2]}, "hint": "needs Healing 2"},
			{"text": "Ask for the Eastern test of the Thirty-Six Winds", "next": "test", "if": {"not_flag": "ax_t_tsering", "skill": ["bending", 7]}, "hint": "needs Bending 7"},
			{"text": "\"Another time.\"", "next": ""},
		]},
		"breath": {"who": "tsering", "expr": "thoughtful", "text": "You breathe for them, a little, until they remember how. Gently. A wound is a frightened place.", "do": [["wait", 72.0], ["learn", "a_breath"]], "next": "hub"},
		"test": {"who": "tsering", "expr": "neutral", "text": "The Eastern test is stillness. Two days on the meditation terrace. Not a word, not a gust. The novices will try to make you laugh. They are very good at it.", "next": "test2"},
		"test2": {"who": "narrator", "text": "Two days. On the second afternoon a novice balances a bowl of soup on your head and you do not move, and it is the proudest moment of your life.",
			"do": [["wait", 48.0], ["flag", "ax_t_tsering", true]], "next": "hub"},
	}},
	"ax_yeshe": {"title": "The Western Air Temple", "start": "hub", "nodes": {
		"hub": {"who": "yeshe", "expr": "neutral", "text": "The West shapes wind. It is the most dangerous of our schools, which is why we teach it upside down, under a cliff, where nobody can see us. What do you want?", "choices": [
			{"text": "Learn the Vortex (three days; Bending 6)", "next": "vortex", "if": {"no_tech": "a_vortex", "skill": ["bending", 6]}, "hint": "needs Bending 6"},
			{"text": "Learn the Wind Blade (two days; Bending 6)", "next": "blade", "if": {"no_tech": "a_blade", "skill": ["bending", 6]}, "hint": "needs Bending 6"},
			{"text": "Ask for the Western test of the Thirty-Six Winds", "next": "test", "if": {"not_flag": "ax_t_yeshe", "techs": ["air", 3], "skill": ["bending", 7]}, "hint": "needs Bending 7 and three air techniques"},
			{"text": "\"Yangzom sends her love. Probably.\"", "next": "yz", "if": {"companion": "yangzom"}, "hide": true},
			{"text": "\"Another time.\"", "next": ""},
		]},
		"vortex": {"who": "yeshe", "expr": "thoughtful", "text": "Turn the air until it wants to keep turning, then step out of the middle. The stepping out is the whole skill. Many forget.", "do": [["wait", 72.0], ["learn", "a_vortex"]], "next": "hub"},
		"blade": {"who": "yeshe", "expr": "sad", "text": "I will teach you the edge. Remember that every blade was a breath before someone sharpened it. The Nomads teach this reluctantly. Be reluctant.", "do": [["wait", 48.0], ["learn", "a_blade"]], "next": "hub"},
		"yz": {"who": "yeshe", "expr": "smirk", "text": "Soon, she says. Every month, soon. Tell her the bison miss her. That will bring her back faster than anything I could say.", "next": "hub"},
		"test": {"who": "narrator", "text": "The Western test: in the cave under the cliff, shape the air into a cup, and hold water in it while Yeshe counts to a hundred, slowly, with long pauses for tea.",
			"do": [["flag", "ax_t_yeshe", true], ["wait", 4.0]], "next": "hub"},
	}},
	"ax_arrows": {"title": "The Arrows", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Four abbots, which has not happened in this temple in thirty years, and Dorje has brought snacks. Lhakpa makes a speech; Yeshe interrupts it; Tsering lets them both finish and then says what they meant.", "next": "b"},
		"b": {"who": "tsering", "expr": "tender", "text": "The arrows are not a reward. They are a promise, worn where you cannot hide it: that your freedom will not be bought by anyone else's chains. Kneel. This will take most of the day, and you will be very bored, and then you will be a master.", "next": "c"},
		"c": {"who": "narrator", "text": "The blue ink goes on along the lines the air already takes over your skin: the crown, the spine, the backs of the hands. Afterwards you look at your hands for a long time.", "choices": [
			{"text": "For an airbender, receive the arrows.", "next": "air", "if": {"bend": "air"}, "hide": true},
			{"text": "Continue.", "next": "other", "if": {"call": "not_air"}, "hide": true},
		]},
		"air": {"who": "narrator", "text": "You are an Airbending Master.",
			"do": [["master", "air"], ["flag", "ax_master", true], ["renown", 40], ["rel", "air_nomads", 20], ["journal_done", "ax_trial", "You passed the four tests of the Thirty-Six Winds and received the arrows. You are an Airbending Master."]]},
		"other": {"who": "tsering", "expr": "smirk", "text": "You are not an airbender, and somehow you did all four tests anyway. No arrows. But you may visit any temple as one of us, forever.",
			"do": [["flag", "ax_master", true], ["rel", "air_nomads", 30], ["journal_done", "ax_trial", "You passed the four tests without being an airbender. The temples count you as one of their own."]]},
	}},
}
