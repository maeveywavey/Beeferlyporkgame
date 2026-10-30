extends RefCounted
## Expansion: Embers of the First Flame (fire). New people: Master Sayuri Ono
## (companion), Kazan of the Cinder Monastery, Mistress Tomoe Ikari of the Fire
## Fountain duelling hall. Stories: Sayuri's last student; the First Flame
## mastery trial (an ember of the Sun Warriors' Eternal Flame); the Great Comet
## forge. Techniques: scripts/battle/techniques.gd.

const NPCS := {
	"kazan": {"name": "Kazan of the Cinder Monastery", "culture": "fire", "vlook": {"sex": "m", "hair": "", "beard": true, "hair_color": Color(0.7, 0.68, 0.66), "height": 1.02}, "kit": "sash"},
	"tomoe": {"name": "Mistress Tomoe Ikari", "culture": "fire", "vlook": {"sex": "f", "hair": "Hair_Long", "accessory": "topknot"}, "kit": "fn_armor", "outfit": "ranger"},
}

const SPAWNS := {}

const TRIGGERS := [
	{"on": "daily", "dlg": "fx_sayuri_start", "if": {"companion": "sayuri", "days_since": ["joined_sayuri", 5]}},
	{"on": "daily", "dlg": "fx_sayuri_after_duel", "if": {"flags": ["sayuri_challenge", "agni_won_daisuke"], "not_flag": "sayuri_done"}},
	{"on": "daily", "dlg": "fx_ember_out", "if": {"flag": "fx_ember", "not_flag": "fx_ember_delivered", "days_since": ["fx_ember_day", 10]}, "once": false},
	{"on": "daily", "dlg": "fx_comet", "if": {"cosmic": "comet", "flag": "fx_kazan_met", "bends": "fire"}},
]

const OPTIONS := [
	{"sid": "fire_fountain", "text": "Visit Mistress Ikari's duelling hall", "dlg": "fx_hall", "service": true, "if": {"bend": "fire"}},
	{"sid": "cinder_monastery", "text": "Climb to the Cinder Monastery", "dlg": "fx_monastery", "service": true, "if": {}},
	{"sid": "crescent_island", "text": "Bring the First Flame's ember to the Fire Sages", "dlg": "fx_ember_arrive", "if": {"flag": "fx_ember", "not_flag": "fx_ember_delivered"}},
	{"sid": "cinder_monastery", "text": "Return to Kazan for the last part of the trial", "dlg": "fx_trial_final", "if": {"flag": "fx_ember_delivered", "not_flag": "fx_master"}},
	{"sid": "ember_island", "text": "Find Daisuke Ren, with Sayuri", "dlg": "fx_sayuri_daisuke", "if": {"companion": "sayuri", "flag": "sayuri_q", "not_flag": "sayuri_challenge"}},
	{"sid": "ember_island", "text": "Challenge Daisuke Ren to the Agni Kai again", "dlg": "fx_rematch", "if": {"flag": "sayuri_challenge", "not_flag": "sayuri_done"}},
]

const DIALOGUES := {
	# -----------------------------------------------------------------------
	# Sayuri: talk, teaching, romance
	# -----------------------------------------------------------------------
	"talk_sayuri": {"title": "Sayuri", "start": "hub", "nodes": {
		"hub": {"who": "sayuri", "expr": "smirk", "text": "You have the look of someone about to ask me a personal question. Go on. I'm sitting down; my knee is on your side today.", "choices": [
			{"text": "\"Tell me about Haruko.\"", "next": "haruko"},
			{"text": "\"The lightning scar. Does it still hurt?\"", "next": "scar"},
			{"text": "\"Why did you stop teaching?\"", "next": "teach"},
			{"text": "\"Teach me to breathe fire.\" (Breath of Fire)", "next": "learn_breath", "if": {"bend": "fire", "approval": ["sayuri", 20], "no_tech": "f_breath_fire"}, "hint": "firebenders only; Sayuri's approval 20"},
			{"text": "\"Teach me the whip.\" (Fire Whip)", "next": "learn_whip", "if": {"bend": "fire", "approval": ["sayuri", 40], "no_tech": "f_whip"}, "hint": "firebenders only; Sayuri's approval 40"},
			{"text": "\"You still fight like you're twenty. I can't stop watching.\"", "next": "rom", "if": {"approval": ["sayuri", 50], "pronouns": ["she", "they"], "not_flag": "romance_sayuri"}, "hide": true},
			{"text": "\"Rest your knee.\"", "next": ""},
		]},
		"haruko": {"who": "sayuri", "expr": "tender", "text": "An archivist. She catalogued the Fire Sages' scrolls for thirty years and corrected their spelling in the margins. When she died the Sages sent a very formal letter. Someone had corrected the spelling in it. I still don't know who.", "next": "hub"},
		"scar": {"who": "sayuri", "expr": "neutral", "text": "Some days. It comes in with the rain, like an old dog. I won't lie and say it makes me wise. It makes me plan my fights shorter. Which, as it happens, is wisdom.", "next": "hub"},
		"teach": {"who": "sayuri", "expr": "sad", "text": "My last student burned a sparring partner and then asked me if it counted as a win. I realised I'd taught him every form and never once told him why we have them. I couldn't think how to start, so I stopped.", "next": "hub"},
		"learn_breath": {"who": "sayuri", "expr": "determined", "text": "Not from the hands. From the belly. In for four; hold; and then let the fire be what the breath was always going to become. — Again. Again. There. Don't look so pleased; you singed my eyebrows.",
			"do": [["wait", 24.0], ["learn", "f_breath_fire"], ["approval", "sayuri", 3]], "next": "hub"},
		"learn_whip": {"who": "sayuri", "expr": "smirk", "text": "A whip is a punch that hasn't finished yet. Throw the jab, then don't stop throwing it. Keep your wrist loose and your conscience tight. That second part is the hard bit.",
			"do": [["wait", 48.0], ["learn", "f_whip"], ["approval", "sayuri", 3]], "next": "hub"},
		"rom": {"who": "sayuri", "expr": "surprised", "text": "…I'm fifty-four and I walk with a cane. You do understand that? — No, don't answer that, you clearly do, you've thought about it. Oh. That's worse. That's much worse.", "next": "rom2"},
		"rom2": {"who": "sayuri", "expr": "tender", "text": "Haruko used to say I fought as if I were writing my name in the air. Nobody's read it in a long time. — Yes. Carefully, and slowly, and yes.", "choices": [
			{"text": "Take her hand.", "next": "rom3", "do": [["flag", "romance_sayuri", true], ["approval", "sayuri", 10]]},
			{"text": "\"I'm sorry. I spoke too soon.\"", "next": "rom_no"},
		]},
		"rom3": {"who": "sayuri", "expr": "happy", "text": "Your hands are cold. Firebender, honestly. Give them here.", "next": "hub"},
		"rom_no": {"who": "sayuri", "expr": "smirk", "text": "Better too soon than never. I'll take it as a compliment and say no more about it.", "next": "hub"},
	}},
	"leave_generic_sayuri": {"title": "Sayuri", "start": "a", "nodes": {"a": {"who": "sayuri", "expr": "neutral", "text": "I've spent my whole life teaching people that fire is breath. You keep teaching the world that it's a weapon. I'm too old to unlearn your lessons, and too stubborn to watch. Goodbye.", "do": [["leave", "sayuri"]]}}},

	# -----------------------------------------------------------------------
	# Sayuri's quest: the last student
	# -----------------------------------------------------------------------
	"fx_sayuri_start": {"title": "Sayuri", "start": "a", "nodes": {
		"a": {"who": "sayuri", "expr": "thoughtful", "text": "There's a boy on Ember Island challenging farmers' sons to Agni Kai. He wins, of course; they've never held a flame. Then he makes them kneel on the beach until the tide comes in. He thinks it's tradition.", "next": "b"},
		"b": {"who": "sayuri", "expr": "sad", "text": "His name is Daisuke Ren. He commands a fleet now. I taught him everything except the only thing that mattered. I'd like to go and teach him that, before somebody teaches him something worse.", "choices": [
			{"text": "\"Then we go to Ember Island.\"", "next": "c", "do": [["approval", "sayuri", 5]]},
			{"text": "\"What's the thing that mattered?\"", "next": "what"},
		]},
		"what": {"who": "sayuri", "expr": "smirk", "text": "That an Agni Kai is the end of an argument, not the start of one. If you start fights to win them you've already lost the only fight worth having. — I'll say it better to him. I've been practising on you.", "next": "c"},
		"c": {"who": "sayuri", "expr": "determined", "text": "Ember Island, then. Bring tea. He'll keep us waiting; he thinks it makes him interesting.",
			"do": [["flag", "sayuri_q", true], ["journal", "fx_sayuri", "Sayuri: The Last Student", "Sayuri's last student, Commander Daisuke Ren, humiliates commoners in Agni Kai on Ember Island. Go there with her."]]},
	}},
	"fx_sayuri_daisuke": {"title": "The Last Student", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Daisuke Ren is on the beach below his villa, in a fresh silk robe, watching a farmer's son kneel in the surf. He sees Sayuri and his face does three things at once.", "next": "b"},
		"b": {"who": "daisuke", "expr": "smirk", "text": "Master Ono. You came to watch? I've improved. Everyone says so. — And you've brought someone. A student? Are they any good? I'd be happy to find out.", "choices": [
			{"text": "\"Find out, then.\" (Agni Kai with Daisuke yourself)", "next": "duel", "if": {"bend": "fire"}, "hint": "firebenders only"},
			{"text": "\"Sayuri, he's yours.\"", "next": "sayuri"},
			{"text": "Talk to him: about what an Agni Kai is for.", "next": "talk", "if": {"renown": 150}, "hint": "needs 150 renown for him to listen"},
			{"text": "\"The Fire Lord will hear about this beach.\"", "next": "report", "if": {"standing": 2}, "hint": "needs Gentry standing"},
		]},
		"duel": {"who": "sayuri", "expr": "determined", "text": "Don't burn him. Beat him. There's a difference, and he needs to see it from the sand.",
			"do": [["flag", "sayuri_challenge", true], ["journal", "fx_sayuri", "Sayuri: The Last Student", "You challenged Daisuke Ren to an Agni Kai. If you lose, challenge him again from Ember Island. Win it without burning him and Sayuri will finish the lesson."]], "next": "duel2"},
		"duel2": {"who": "daisuke", "expr": "happy", "text": "Wonderful. My hall, at noon. Don't be late; I hate it when people are late. It makes the crowd restless.", "do": [["lord_rel", "daisuke", -5], ["call", "duel", "daisuke"]]},
		"sayuri": {"who": "narrator", "text": "Sayuri hands you her cane and walks onto the sand. Daisuke laughs, bows, and attacks. She does not throw a single flame. She steps, and breathes, and steps, and every blast he throws goes past her by the width of a hand, until he is gasping and she is standing behind him with two fingers on the back of his neck.", "next": "sayuri2"},
		"sayuri2": {"who": "sayuri", "expr": "tender", "text": "That's the whole lesson. You can't win against someone who isn't fighting you. And you were never fighting them, Daisuke. You were fighting being ordinary. You are ordinary. So am I. It's all right.", "next": "humbled"},
		"talk": {"who": "narrator", "text": "You don't challenge him. You ask him what the boy in the surf did to him. He starts to answer, stops, and looks at the boy as if seeing him for the first time.", "next": "humbled"},
		"humbled": {"who": "daisuke", "expr": "embarrassed", "text": "…Get up. Go home. Tell your father — tell him nothing, I suppose. — Master Ono. Would you, possibly. Teach me the rest of it. I'll be terrible at it.",
			"do": [["flag", "daisuke_humbled", true], ["flag", "sayuri_done", true], ["lord_rel", "daisuke", 25], ["approval", "sayuri", 15], ["renown", 15], ["honor", 2],
				["journal_done", "fx_sayuri", "Daisuke Ren was humbled, kindly. He asked Sayuri to teach him the rest. She said yes, on the condition that he apologises to every farmer on Ember Island, in person."]]},
		"report": {"who": "sayuri", "expr": "sad", "text": "…Yes. That will stop him. It won't teach him anything. Well. Some lessons are for the people standing in the surf, not the one doing it.",
			"do": [["flag", "daisuke_reported", true], ["flag", "sayuri_done", true], ["lord_rel", "daisuke", -40], ["approval", "sayuri", 3], ["rel", "fire_nation", 3],
				["journal_done", "fx_sayuri", "You reported Daisuke Ren to the Fire Lord. He lost his command. The beaches are safer. Sayuri is quieter."]]},
	}},
	"fx_rematch": {"title": "The Last Student", "start": "a", "nodes": {
		"a": {"who": "daisuke", "expr": "smirk", "text": "Back again? I admire persistence. It's very ordinary of you.", "do": [["call", "duel", "daisuke"]]},
	}},
	"fx_sayuri_after_duel": {"title": "The Last Student", "start": "a", "nodes": {
		"a": {"who": "sayuri", "expr": "happy", "text": "You beat him and you didn't burn him. He's sitting on his own steps staring at his hands. I'm going to go and sit next to him and say nothing for an hour. That's the second half of the lesson.",
			"do": [["flag", "daisuke_humbled", true], ["flag", "sayuri_done", true], ["lord_rel", "daisuke", 15], ["approval", "sayuri", 15], ["renown", 15],
				["journal_done", "fx_sayuri", "You beat Daisuke Ren in an Agni Kai without burning him, and Sayuri taught him the rest of it from his own steps."]]},
	}},

	# -----------------------------------------------------------------------
	# The duelling hall (Fire Fountain City)
	# -----------------------------------------------------------------------
	"fx_hall": {"title": "The Duelling Hall", "start": "hub", "nodes": {
		"hub": {"who": "tomoe", "expr": "neutral", "text": "This hall has trained Agni Kai duellists for four hundred years. I teach anyone who pays and anyone who can stand still for an hour. You'd be amazed how few can do both.", "choices": [
			{"text": "Learn Fire Daggers (300 gold, two days; Bending 4)", "next": "daggers", "if": {"no_tech": "f_daggers", "gold": 300, "skill": ["bending", 4]}, "hint": "300 gold and Bending 4"},
			{"text": "Learn Fire Jets (500 gold, three days; Bending 6)", "next": "jets", "if": {"no_tech": "f_jets", "gold": 500, "skill": ["bending", 6]}, "hint": "500 gold and Bending 6"},
			{"text": "Learn the Fire Whip (600 gold, three days; Bending 5)", "next": "whip", "if": {"no_tech": "f_whip", "gold": 600, "skill": ["bending", 5]}, "hint": "600 gold and Bending 5"},
			{"text": "\"Do you know of a monastery on the volcano?\"", "next": "kazan", "if": {"not_flag": "fx_kazan_met"}},
			{"text": "\"Another time.\"", "next": ""},
		]},
		"daggers": {"who": "tomoe", "expr": "smirk", "text": "Fingertips, not fists. Small fires are fast fires. — Faster. You throw like a man feeding ducks.",
			"do": [["gold", -300], ["wait", 48.0], ["learn", "f_daggers"]], "next": "hub"},
		"jets": {"who": "tomoe", "expr": "determined", "text": "Fire from the feet is easy. Landing is the art. You'll fall a great deal. The floor here has been fallen on by better people than you.",
			"do": [["gold", -500], ["wait", 72.0], ["learn", "f_jets"]], "next": "hub"},
		"whip": {"who": "tomoe", "expr": "neutral", "text": "A long line is a promise you make with your shoulder and keep with your wrist. Don't break promises in my hall.",
			"do": [["gold", -600], ["wait", 72.0], ["learn", "f_whip"]], "next": "hub"},
		"kazan": {"who": "tomoe", "expr": "thoughtful", "text": "The Cinder Monastery. West, on the dead mountain. They keep a flame lit from the Sun Warriors' Eternal Flame and teach the breath before the fire. Kazan runs it now. He used to command artillery in the Strait Isles. People change, or they climb mountains to try.", "next": "hub"},
	}},

	# -----------------------------------------------------------------------
	# The Cinder Monastery and the First Flame (mastery trial)
	# -----------------------------------------------------------------------
	"fx_monastery": {"title": "The Cinder Monastery", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Four hundred steps cut into black rock. At the top, a courtyard of cinders raked into patterns, and in a shrine with no door, a flame the size of a fist, burning on nothing.", "next": "b"},
		"b": {"who": "kazan", "expr": "neutral", "text": "I commanded the guns at the siege of Saltreach. Now I rake cinders. Both jobs are mostly about patience. You've come to learn something, or to be told you can't. Which?",
			"do": [["flag", "fx_kazan_met", true]], "next": "hub"},
		"hub": {"who": "kazan", "expr": "thoughtful", "text": "Ask.", "choices": [
			{"text": "Learn the Inner Flame (three days of breathing; Bending 5)", "next": "inner", "if": {"bend": "fire", "no_tech": "f_inner_flame", "skill": ["bending", 5]}, "hint": "firebenders with Bending 5"},
			{"text": "Learn the Ring of Fire (two days; Bending 6, knows Fire Jets)", "next": "ring", "if": {"bend": "fire", "no_tech": "f_ring", "skill": ["bending", 6], "tech": "f_jets"}, "hint": "Bending 6 and Fire Jets"},
			{"text": "Learn Breath of Fire (two days; Bending 4)", "next": "breath", "if": {"bend": "fire", "no_tech": "f_breath_fire", "skill": ["bending", 4]}, "hint": "firebenders with Bending 4"},
			{"text": "\"I want to carry the ember.\" (the mastery trial)", "next": "trial", "if": {"bend": "fire", "not_flag": "fx_ember", "call": "not_master", "skill": ["bending", 7], "techs": ["fire", 3], "duel_wins": 2}, "hint": "Bending 7, three fire techniques and two duels won"},
			{"text": "\"What is the flame?\"", "next": "flame"},
			{"text": "\"Why did you leave the guns?\"", "next": "guns"},
			{"text": "\"I'll go.\"", "next": ""},
		]},
		"flame": {"who": "kazan", "expr": "neutral", "text": "A child of the first fire. The dragons gave the Sun Warriors the Eternal Flame, and the Sun Warriors still keep it in their city in the south of the islands. Nine hundred years ago one of them carried an ember of it up this mountain and taught the founders to breathe before they burn. Ours has never been fed. It is never allowed to go out.", "next": "hub"},
		"guns": {"who": "kazan", "expr": "sad", "text": "One morning at Saltreach I realised I could no longer tell the difference between the smell of our powder and the smell of their bread ovens. That is not a good thing to be unable to tell. I walked away at noon. Nobody stopped me. I think they were relieved.", "next": "hub"},
		"inner": {"who": "kazan", "expr": "determined", "text": "Breathe the fire in, not out. Hold it the way you'd hold a sleeping child: firmly, and without waking it. Three days. You will be bored. Boredom is the fire learning your name.",
			"do": [["wait", 72.0], ["learn", "f_inner_flame"]], "next": "hub"},
		"ring": {"who": "kazan", "expr": "smirk", "text": "Turn, and let the flame come round with you like a skirt. Yes, a skirt. The old masters had a sense of humour; you'll need one when you set the monastery's hedge alight.",
			"do": [["wait", 48.0], ["learn", "f_ring"]], "next": "hub"},
		"breath": {"who": "kazan", "expr": "neutral", "text": "From the belly. Not the chest; the chest lies. Again.",
			"do": [["wait", 48.0], ["learn", "f_breath_fire"]], "next": "hub"},
		"trial": {"who": "kazan", "expr": "determined", "text": "Then here is an ember of the Eternal Flame, in a clay lamp. Carry it to the Fire Sages on Crescent Island within nine days. It goes out if you use fire in anger on the way: raid, burn, execute, and it will know. Bring it there lit, then bring yourself back to me.",
			"do": [["flag", "fx_ember", true], ["flag_day", "fx_ember_day"], ["call", "fx_ember_infamy"],
				["journal", "fx_trial", "The First Flame", "Kazan gave you an ember of the Eternal Flame. Carry it to the Fire Sages on Crescent Island within nine days, without using fire in anger on the way."]]},
	}},
	"fx_ember_out": {"title": "The First Flame", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "You wake and the clay lamp is cold. You didn't see it go out. You never do. It will be waiting at the monastery, lit, as if nothing happened. Kazan will be waiting too.",
			"do": [["flag", "fx_ember", false], ["journal", "fx_trial", "The First Flame", "The ember went out before it reached Crescent Island. Return to the Cinder Monastery to try again."]]},
	}},
	"fx_ember_arrive": {"title": "The First Flame", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Sage Hotaru meets you on the temple steps and looks at the clay lamp for a long time before she looks at you.", "choices": [
			{"text": "Hand her the lamp.", "next": "lit", "if": {"call": "fx_ember_clean"}, "hide": true},
			{"text": "Hand her the lamp.", "next": "dark", "if": {"call": "fx_ember_dirty"}, "hide": true},
		]},
		"lit": {"who": "sage", "expr": "tender", "text": "Still burning. Nine hundred years and it still trusts people. Sit. In for four, hold for four, out for eight. — There. You feel it? That warmth in the belly is all firebending ever was. The rest is decoration.",
			"do": [["flag", "fx_ember_delivered", true], ["xp", 800], ["journal", "fx_trial", "The First Flame", "The ember reached Crescent Island still lit. Return to Kazan at the Cinder Monastery for the last part of the trial."]]},
		"dark": {"who": "sage", "expr": "sad", "text": "Cold. It knew, then, whatever you did on the road. Go back to the mountain. The flame forgives. It just doesn't hurry.",
			"do": [["flag", "fx_ember", false], ["journal", "fx_trial", "The First Flame", "The ember went out on the road; the flame knew what you had done. Return to the Cinder Monastery to try again."]]},
	}},
	"fx_trial_final": {"title": "The First Flame", "start": "a", "nodes": {
		"a": {"who": "kazan", "expr": "neutral", "text": "Last part. There is an unlit lamp on that stone. Light it.", "choices": [
			{"text": "Throw a precise jab of flame at the wick.", "next": "jab"},
			{"text": "Kneel, cup the lamp in both hands, and breathe on it.", "next": "breathe"},
			{"text": "Sit beside it and wait.", "next": "wait"},
		]},
		"jab": {"who": "kazan", "expr": "smirk", "text": "Lit, and the lamp is cracked. Correct, and wrong. Again.", "next": "a"},
		"wait": {"who": "kazan", "expr": "thoughtful", "text": "Patient, and cold. The fire doesn't come to people who won't ask it. Again.", "next": "a"},
		"breathe": {"who": "narrator", "text": "Nothing, for a long breath. Then the wick catches, small and orange-blue, from warmth rather than flame. Kazan lets out a breath he seems to have been holding for years.", "next": "end"},
		"end": {"who": "kazan", "expr": "happy", "text": "There. That's the whole of it: fire is breath that has decided to be seen. You are a master of it now, whatever that word means to you. Mean something kind by it.",
			"do": [["master", "fire"], ["flag", "fx_master", true], ["learn", "f_inner_flame"], ["renown", 40], ["journal_done", "fx_trial", "You lit the lamp with breath alone. Kazan named you a Master Firebender."]]},
	}},

	# -----------------------------------------------------------------------
	# The comet forge (a comet must be in the sky)
	# -----------------------------------------------------------------------
	"fx_comet": {"title": "The Comet Forge", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "A monk from the Cinder Monastery finds you with a message in Kazan's square hand: 'The Great Comet is up. We have a lump of sky-iron that fell when I was a boy and has never been hot enough to work. It will be, for three days. Come, or send me a firebender.'", "choices": [
			{"text": "Go and work the forge. (1,000 gold for the smiths and charcoal)", "next": "forge", "if": {"gold": 1000}, "hint": "need 1,000 gold"},
			{"text": "\"Let the monks keep the iron for something better than a sword.\"", "next": "keep"},
		]},
		"forge": {"who": "narrator", "text": "Three days and nights at the anvil, under a sky with two moons in it. The iron goes from black to red to a white that hurts to look at, and the firebenders work in shifts, breathing in time. What comes out is a dao with a grey, rippled blade that seems to drink the light.",
			"do": [["gold", -1000], ["wait", 72.0], ["item", "comet_dao"], ["log", "You forged a Comet-Forged Dao."]]},
		"keep": {"who": "kazan", "expr": "happy", "text": "(in a later letter) We made a bell. It rings slightly flat. Every monk agrees it is the most beautiful thing they have ever heard. Thank you.", "do": [["honor", 2], ["rel", "fire_nation", 3]]},
	}},
}
