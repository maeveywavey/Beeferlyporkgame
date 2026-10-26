extends RefCounted
## Companion personal quests (docs/02_writers_room.md, part 5). Each begins
## once a companion has travelled with you for a while, resolves somewhere in
## the world, and changes both the companion and the world.

const NPCS := {
	"bo_lai": {"name": "Lieutenant Bo Lai", "culture": "earth", "vlook": {"sex": "m", "hair": "Hair_SimpleParted", "accessory": "dai_li", "hair_color": Color(0.4, 0.38, 0.36)}, "kit": "dai_li_robe", "outfit": "ranger"},
	"mi_sun": {"name": "Mi-sun", "culture": "earth", "vlook": {"sex": "f", "hair": "Hair_Buns"}},
	"sage": {"name": "Sage Hotaru", "culture": "fire", "vlook": {"sex": "f", "hair": "Hair_Buns", "hair_color": Color(0.7, 0.68, 0.66), "accessory": "fn_noble"}, "kit": "sash"},
	"dawa": {"name": "Dawa", "culture": "air", "vlook": {"sex": "f", "hair": "Hair_BuzzedFemale", "accessory": "bandana"}, "kit": "sash"},
	"kimi": {"name": "Kimi", "culture": "fire", "vlook": {"sex": "f", "hair": "Hair_Buns", "hair_color": Color(0.35, 0.3, 0.28)}},
	"lin": {"name": "Lin", "culture": "omashu", "vlook": {"sex": "m", "hair": "Hair_Buzzed", "accessory": "bandana"}},
	"garrison_captain": {"name": "Captain Heng", "culture": "earth", "vlook": {"sex": "m", "accessory": "ek_hat"}, "kit": "ek_armor", "outfit": "ranger"},
	"clan_elder": {"name": "Elder Rasa", "culture": "sand", "vlook": {"sex": "f", "accessory": "sand_wrap"}, "kit": "sash"},
}

const SPAWNS := {
	"letter_hunters": {"name": "Dai Li Interceptors", "troops": [["ek_dai_li", 5], ["ek_earthbender", 6], ["ek_soldier", 6]], "gold": 300,
		"on_defeat": [["queue", "cq_shenmu_ambush_beaten"]]},
}

const TRIGGERS := [
	{"on": "daily", "dlg": "cq_hana_start", "if": {"companion": "hana", "days_since": ["joined_hana", 6]}},
	{"on": "daily", "dlg": "cq_juro_start", "if": {"companion": "juro", "days_since": ["joined_juro", 6]}},
	{"on": "daily", "dlg": "cq_pemba_start", "if": {"companion": "pemba", "days_since": ["joined_pemba", 5]}},
	{"on": "daily", "dlg": "cq_nima_start", "if": {"companion": "nima", "days_since": ["joined_nima", 6]}},
	{"on": "daily", "dlg": "cq_ukiuk_start", "if": {"companion": "ukiuk", "days_since": ["joined_ukiuk", 7]}},
	{"on": "daily", "dlg": "cq_shenmu_start", "if": {"companion": "shen_mu", "days_since": ["joined_shen_mu", 1]}},
	{"on": "daily", "dlg": "cq_shenmu_ambush", "if": {"companion": "shen_mu", "flag": "shenmu_q", "not_flag": "shenmu_done", "days_since": ["joined_shen_mu", 4]}, "chance": 0.3, "do": [["spawn", "letter_hunters"]]},
	{"on": "daily", "dlg": "cq_reika_start", "if": {"companion": "reika", "days_since": ["joined_reika", 6]}},
	{"on": "daily", "dlg": "cq_kesi_start", "if": {"companion": "kesi", "days_since": ["joined_kesi", 6]}},
	{"on": "daily", "dlg": "cq_hana_return", "if": {"flag": "hana_killed", "days_since": ["hana_killed_day", 7]}},
]

const OPTIONS := [
	{"sid": "ba_sing_se", "text": "Go with Hana to the sealed tunnel in the Wenlong district", "dlg": "cq_hana_find", "if": {"companion": "hana", "flag": "hana_q", "not_flag": "hana_done"}},
	{"sid": "tieshan", "text": "Walk with Juro to the burned quarter", "dlg": "cq_juro_village", "if": {"companion": "juro", "flag": "juro_q", "not_flag": "juro_visited"}},
	{"sid": "crescent_island", "text": "Take Juro to the Fire Sages", "dlg": "cq_juro_temple", "if": {"companion": "juro", "flag": "juro_visited", "not_flag": "juro_done"}},
	{"sid": "tieshan", "text": "Attend the lantern festival with Juro", "dlg": "cq_juro_lantern", "if": {"companion": "juro", "flag": "juro_fire", "not_flag": "juro_lantern"}},
	{"sid": "red_lantern_den", "text": "Look for Pemba's sister among the Brotherhood", "dlg": "cq_pemba_dawa", "if": {"companion": "pemba", "flag": "pemba_q", "not_flag": "pemba_done"}},
	{"sid": "agna_qela", "text": "Go with Nima to the council hall", "dlg": "cq_nima_council", "if": {"companion": "nima", "flag": "nima_q", "not_flag": "nima_done"}},
	{"sid": "shu_jing", "text": "Find the widow Kimi's noodle stall with Ukiuk", "dlg": "cq_ukiuk_kimi", "if": {"companion": "ukiuk", "flag": "ukiuk_q", "not_flag": "ukiuk_done"}},
	{"sid": "omashu", "text": "Go with Shen Mu to deliver the letter", "dlg": "cq_shenmu_deliver", "if": {"companion": "shen_mu", "flag": "shenmu_q", "not_flag": "shenmu_done"}},
	{"sid": "fire_navy_harbor", "text": "Help Reika get into the Admiral's counting-house", "dlg": "cq_reika_ledgers", "if": {"companion": "reika", "flag": "reika_q", "not_flag": "reika_done"}},
	{"sid": "misty_palms", "text": "Go with Kesi to the closed wells", "dlg": "cq_kesi_wells", "if": {"companion": "kesi", "flag": "kesi_q", "not_flag": "kesi_done"}},
]

const DIALOGUES := {
	# -----------------------------------------------------------------------
	# Hana — The Settled Stones
	# -----------------------------------------------------------------------
	"cq_hana_start": {"title": "Hana", "start": "a", "nodes": {
		"a": {"who": "hana", "expr": "thoughtful", "text": "I need to tell you something. I've rehearsed it. Please don't interrupt; if you interrupt, I have to start again from the beginning, and it's long.", "next": "b"},
		"b": {"who": "hana", "expr": "neutral", "text": "Six years ago the Dai Li raided the smuggling tunnels in the Wenlong district. My teacher, Grandmother Zhu, was in the far gallery. A Dai Li officer sealed the entrance. He was not angry. He did it the way you close a cupboard.", "next": "c"},
		"c": {"who": "hana", "expr": "sad", "text": "I was on the other side of the wall. I heard the stones settle. I have not dug in Wenlong since. His name is Bo Lai. He is a lieutenant now, under Commander Shu Fan.", "next": "d"},
		"d": {"who": "hana", "expr": "determined", "text": "I would like to find him. I have not decided what I will do when I find him. I am telling you in advance because surprises are bad. You didn't say that. I said that. That's the end of what I rehearsed.", "choices": [
			{"text": "\"Then we'll find him together. You decide what happens.\"", "next": "e", "do": [["approval", "hana", 5]]},
			{"text": "\"Thank you for telling me first.\"", "next": "e", "do": [["approval", "hana", 8]]},
			{"text": "\"Are you sure this is a good idea?\"", "next": "f"},
		]},
		"e": {"who": "hana", "expr": "happy", "text": "Good. Ba Sing Se, then. The Wenlong district is in the Lower Ring, so we won't need papers. I've already checked. Twice.",
			"do": [["flag", "hana_q", true], ["journal", "cq_hana", "Hana: The Settled Stones", "Hana's teacher was sealed in a tunnel by the Dai Li officer Bo Lai. Go with Hana to the Wenlong district of Ba Sing Se's Lower Ring."]]},
		"f": {"who": "hana", "expr": "thoughtful", "text": "No. It is a necessary idea, which is different. Good ideas are optional.", "next": "e"},
	}},
	"cq_hana_find": {"title": "The Settled Stones", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Hana leads you through a cellar, a dry cistern and a crawlway you would never have found. She stops at a wall that looks like every other wall and lays both palms on it.", "next": "b"},
		"b": {"who": "hana", "expr": "sad", "text": "She's here. There's a hollow behind. Eleven paces deep. I can feel the shape of it.", "next": "c"},
		"c": {"who": "narrator", "text": "There is incense at the foot of the wall. Fresh. Then footsteps, and a grey-haired man in a Dai Li robe comes around the corner carrying more of it. He stops. He knows exactly who Hana is.", "next": "d"},
		"d": {"who": "bo_lai", "expr": "sad", "text": "I come every year, on this day. I didn't know anyone else remembered. I had orders. I know that isn't a reason. I've had six years to find a better one, and there isn't one.", "choices": [
			{"text": "\"Hana. This is your choice.\"", "next": "spare", "do": [["approval", "hana", 5]]},
			{"text": "\"He should answer to the Queen, in public.\"", "next": "expose", "if": {"standing": 2}, "hint": "needs Gentry standing for an audience"},
			{"text": "\"He sealed her in alive. Do what you came to do.\"", "next": "kill"},
		]},
		"spare": {"who": "hana", "expr": "determined", "text": "I wanted to bury you in here. I've wanted it for six years. I made a plan. It had diagrams.", "next": "spare2"},
		"spare2": {"who": "hana", "expr": "grief", "text": "I'm not going to. Not because you deserve it. Because I don't want to be a person who closes tunnels on people. She taught me to open them.", "next": "spare3"},
		"spare3": {"who": "narrator", "text": "Hana breathes once and the wall unfolds like a flower, stone sliding back into stone, until the far gallery stands open to the lamp. You bury Grandmother Zhu properly, the three of you, in the old way. Afterwards Bo Lai asks what he can do. Hana tells him: testify.",
			"do": [["flag", "hana_spared", true], ["flag", "dai_li_testify", true], ["call", "hana_mastery"], ["approval", "hana", 15], ["flag", "hana_done", true],
				["journal_done", "cq_hana", "Hana spared Bo Lai and opened the tunnel to bury her teacher. Bo Lai will testify about the Dai Li. Hana's earthbending has grown stronger."]]},
		"expose": {"who": "hana", "expr": "thoughtful", "text": "He should be judged by someone who isn't me. Yes. I would make a bad judge. I would want diagrams.", "next": "expose2"},
		"expose2": {"who": "narrator", "text": "Bo Lai does not resist. Three days later, in the Upper Ring, Queen Hualing hears his confession in open court — and asks, very quietly, on whose orders the Dai Li sealed tunnels with people inside. Secretary Wu Jian is not available for comment.",
			"do": [["flag", "hana_exposed", true], ["flag", "wu_weakened", true], ["lord_rel", "wu_jian", -20], ["lord_rel", "hualing", 10], ["approval", "hana", 10], ["flag", "hana_done", true],
				["journal_done", "cq_hana", "Bo Lai confessed before the Earth Queen. The Grand Secretary's grip on Ba Sing Se has slipped."]]},
		"kill": {"who": "narrator", "text": "Hana does it herself, without a word, the way he did: quickly, and like closing a cupboard. Then she sits down against the wall and does not get up for a long time.", "next": "kill2"},
		"kill2": {"who": "hana", "expr": "grief", "text": "It's done. I thought it would be quieter afterwards. It isn't. I need to go somewhere with no people for a while. A week. I'll come back. I'm telling you in advance.",
			"do": [["flag", "hana_killed", true], ["flag_day", "hana_killed_day"], ["away", "hana", 7], ["approval", "hana", 5], ["flag", "hana_done", true],
				["journal_done", "cq_hana", "Hana killed Bo Lai. She has gone somewhere quiet for a week."]]},
	}},
	"cq_hana_return": {"title": "Hana", "start": "a", "nodes": {
		"a": {"who": "hana", "expr": "neutral", "text": "I'm back. I counted things for seven days — birds, mostly. It helped a little. I don't want to talk about him. I want to know where we're going next, and exactly when."},
	}},

	# -----------------------------------------------------------------------
	# Juro — Breath Before Flame
	# -----------------------------------------------------------------------
	"cq_juro_start": {"title": "Juro", "start": "a", "nodes": {
		"a": {"who": "juro", "expr": "tender", "text": "My father wrote. 'The plum tree finally fruited.' That's the whole letter. It's the best letter I've ever read.", "next": "b"},
		"b": {"who": "juro", "expr": "sad", "text": "He doesn't ask when I'm coming home. He knows why I can't. Three years ago I designed a fire-pot for the catapults on the Ember Coast. It worked beautifully. We tested it on Tieshan.", "next": "c"},
		"c": {"who": "juro", "expr": "grief", "text": "There were people in the east quarter. The intelligence said there wouldn't be. I walked through it afterwards. That night I tried to light a candle and nothing came. Nothing's come since.", "next": "d"},
		"d": {"who": "juro", "expr": "thoughtful", "text": "I'd like to see it. Tieshan. I don't expect anything. I just think — a person should look at what they've done, at least once, with their eyes open.", "choices": [
			{"text": "\"We'll go to Tieshan.\"", "next": "e", "do": [["approval", "juro", 5]]},
			{"text": "\"You were following orders, Juro.\"", "next": "orders"},
		]},
		"orders": {"who": "juro", "expr": "neutral", "text": "I was following my own drawings. The orders just told me where to point them. Thank you, though. It's kind. It just isn't true.", "next": "e"},
		"e": {"who": "juro", "expr": "smirk", "text": "Thank you. I'll try not to be dramatic about it. I'll fail, but I'll try.",
			"do": [["flag", "juro_q", true], ["journal", "cq_juro", "Juro: Breath Before Flame", "Juro lost his firebending the night his fire-pots burned part of Tieshan, on the Ember Coast. He wants to see the village with his own eyes."]]},
	}},
	"cq_juro_village": {"title": "Breath Before Flame", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The east quarter is half rebuilt: new timber over old stone, scorch marks under the whitewash. A woman is stacking bricks at a kiln. She looks at Juro's hands — engineer's calluses, a burn scar in the shape of a fuse-ring — and goes very still.", "next": "b"},
		"b": {"who": "mi_sun", "expr": "angry", "text": "I know what you are. The man who drew the pots. They read your name at the inquiry nobody held. My husband was in the east quarter. What do you want?", "next": "c"},
		"c": {"who": "juro", "expr": "grief", "text": "Nothing. I wanted to see it. I'm not going to ask you for anything. I'm sorry. I know that's not useful to you.", "next": "d"},
		"d": {"who": "mi_sun", "expr": "sad", "text": "No. It isn't.", "choices": [
			{"text": "\"We could help rebuild. Coin, hands, whatever you need.\" (500 gold, three days)", "next": "help", "if": {"gold": 500}, "hint": "need 500 gold"},
			{"text": "\"We should go.\"", "next": "leave"},
		]},
		"help": {"who": "narrator", "text": "For three days your soldiers carry brick and timber. Juro rebuilds the kiln flue from memory, better than it was. Nobody thanks him. On the third evening, Mi-sun watches him set a roof beam.", "do": [["gold", -500], ["wait", 72.0], ["prosperity", "tieshan", 10], ["flag", "juro_helped", true]], "next": "help2"},
		"help2": {"who": "mi_sun", "expr": "neutral", "text": "You put the beam in straight. My husband never could. …That isn't forgiveness. Don't make it into forgiveness.", "next": "help3"},
		"help3": {"who": "juro", "expr": "tender", "text": "I won't. Thank you for saying it anyway.",
			"do": [["flag", "misun_spoke", true], ["flag", "juro_visited", true], ["approval", "juro", 12],
				["journal", "cq_juro", "Juro: Breath Before Flame", "You helped rebuild Tieshan's east quarter. Mi-sun spoke to Juro, once. Take Juro to the Fire Sages' temple on Crescent Island."]]},
		"leave": {"who": "juro", "expr": "sad", "text": "Yes. Of course. …Thank you for coming with me.",
			"do": [["flag", "juro_visited", true], ["journal", "cq_juro", "Juro: Breath Before Flame", "Juro saw what remained of Tieshan's east quarter. Take him to the Fire Sages' temple on Crescent Island."]]},
	}},
	"cq_juro_temple": {"title": "Breath Before Flame", "start": "a", "nodes": {
		"a": {"who": "sage", "expr": "thoughtful", "text": "Fire is breath before it is anything else, young man. Not anger, not will. Breath. Sit. In for four, hold for four, out for eight. Again. Again.", "next": "b"},
		"b": {"who": "narrator", "text": "Juro breathes for an hour while the sage corrects his posture with a cane. Then she holds out an unlit lantern.", "choices": [
			{"text": "Watch.", "next": "fire", "if": {"flags": ["juro_helped", "misun_spoke"]}, "hide": true},
			{"text": "Watch.", "next": "nofire", "if": {"not_flag": "misun_spoke"}, "hide": true},
		]},
		"fire": {"who": "narrator", "text": "Nothing. Then a spark. Then a small flame sits in his palm — orange at the edges and blue-white at its heart, the colour of a forge, not a battlefield. Juro laughs and then he is crying and then he is doing both.", "next": "fire2"},
		"fire2": {"who": "juro", "expr": "laugh", "text": "Look at it. It's tiny. It's ridiculous. I'm going to write to my father and it's going to be the worst letter, it's going to be all exclamation marks.",
			"do": [["call", "juro_fire"], ["flag", "juro_fire", true], ["flag", "juro_done", true], ["approval", "juro", 15], ["xp", 500],
				["journal", "cq_juro", "Juro: Breath Before Flame", "Juro's fire has returned. Tieshan holds a lantern festival in the autumn; perhaps he should go."]]},
		"nofire": {"who": "narrator", "text": "Nothing comes. The sage waits a long time, then sets the lantern down.", "next": "nofire2"},
		"nofire2": {"who": "juro", "expr": "thoughtful", "text": "Maybe it isn't coming back. Maybe that's — all right. I can still build things. I'd rather build things. Let's go.",
			"do": [["flag", "juro_no_fire", true], ["flag", "juro_done", true], ["approval", "juro", 5],
				["journal_done", "cq_juro", "Juro's fire did not return. He says he would rather build things. He may even mean it."]]},
	}},
	"cq_juro_lantern": {"title": "The Lantern Festival", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Tieshan floats paper lanterns on the river for its dead every autumn. Mi-sun stands at the bank with a lantern and no flame; the matches are damp. Juro stands a long way off. Then she holds the lantern out, without looking at him.", "next": "b"},
		"b": {"who": "narrator", "text": "He lights it from his palm. A small flame, blue-white at the heart. She sets it on the water and watches it go.", "next": "c"},
		"c": {"who": "mi_sun", "expr": "neutral", "text": "It's a good lantern.",
			"do": [["flag", "juro_lantern", true], ["approval", "juro", 10], ["honor", 2], ["journal_done", "cq_juro", "Juro lit Mi-sun's lantern at the Tieshan festival. 'It's a good lantern,' she said. That was all."]]},
	}},

	# -----------------------------------------------------------------------
	# Pemba — The Lantern and the Wind
	# -----------------------------------------------------------------------
	"cq_pemba_start": {"title": "Pemba", "start": "a", "nodes": {
		"a": {"who": "pemba", "expr": "thoughtful", "text": "I should tell you why I'm out here, instead of at the temple brushing bison. My sister, Dawa. She left the Southern Temple at fifteen. She said she couldn't watch refugees starve while we meditated. She was right, which made it worse.", "next": "b"},
		"b": {"who": "pemba", "expr": "neutral", "text": "She joined the Red Lantern Brotherhood. They rob the Earth Kingdom's tax barges and feed the Lower Ring. I hear she's very good at it. Their den is in the reeds by the river, west of Ba Sing Se.", "next": "c"},
		"c": {"who": "pemba", "expr": "smirk", "text": "I don't know what I'll say to her. Abbot Dorje gave me a speech to memorise. I've lost it. I suspect on purpose.", "choices": [
			{"text": "\"We'll find her.\"", "next": "d", "do": [["approval", "pemba", 5]]},
			{"text": "\"What do you want to happen?\"", "next": "want"},
		]},
		"want": {"who": "pemba", "expr": "tender", "text": "I want her to be alive and not hate me. Everything after that is a bonus. Possibly lunch.", "next": "d", "do": [["approval", "pemba", 3]]},
		"d": {"who": "pemba", "expr": "happy", "text": "Thank you. I'll try not to cry on the bison. It upsets him.",
			"do": [["flag", "pemba_q", true], ["journal", "cq_pemba", "Pemba: The Lantern and the Wind", "Pemba's younger sister Dawa ran away from the Southern Air Temple to join the Red Lantern Brotherhood. Look for her at the Red Lantern Den."]]},
	}},
	"cq_pemba_dawa": {"title": "The Lantern and the Wind", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The Brotherhood's elder sister keeps you waiting an hour. Then a young woman with a shaved-and-growing-out head and a red lantern tattooed on her wrist walks out of the reeds, sees Pemba, and stops.", "next": "b"},
		"b": {"who": "dawa", "expr": "angry", "text": "No. Absolutely not. Did Dorje send you? Go home, Pemba. Go home and meditate about how sad it is that people are hungry.", "next": "c"},
		"c": {"who": "pemba", "expr": "sad", "text": "I know. I'm sorry. I should have come with you, four years ago. I didn't, because I was scared, and because the temple was comfortable. I came now anyway.", "next": "d"},
		"d": {"who": "dawa", "expr": "grief", "text": "…You're not supposed to agree with me. That's not how this argument goes. — The Lower Ring ate for a month on the last barge. Do you know what that's like? Watching a child eat and knowing you did that?", "choices": [
			{"text": "\"The Earth Kingdom pays well for Red Lantern leaders.\" (Turn her in)", "next": "turn"},
			{"text": "\"Come home, Dawa. The temple needs someone who argues.\" (Bring her home)", "next": "home"},
			{"text": "\"It's her life. Let her choose.\"", "next": "choose"},
		]},
		"turn": {"who": "pemba", "expr": "furious", "text": "No. No — {name}, you can't. …You can. You are. Then I'm not coming with you. I'm sorry. I think I'll be sorry for a long time.",
			"do": [["flag", "dawa_turned_in", true], ["flag", "pemba_done", true], ["rel", "earth_kingdom", 10], ["gold", 400], ["call", "red_lanterns_enemies"], ["leave", "pemba"],
				["journal_done", "cq_pemba", "You turned Dawa in to the Earth Kingdom. Pemba left your company."]]},
		"home": {"who": "dawa", "expr": "angry", "text": "And do what? Sweep? …Argue. With Dorje. Every day. Spirits, that's a terrible idea. Fine. One year. If they still meditate at hungry people in a year, I'm leaving again and you're coming with me.",
			"do": [["flag", "dawa_home", true], ["flag", "pemba_done", true], ["approval", "pemba", 10],
				["journal_done", "cq_pemba", "Dawa agreed to go home to the Southern Air Temple for a year, mostly to argue with the abbot."]]},
		"choose": {"who": "dawa", "expr": "surprised", "text": "…Nobody's ever said that. Not the monks, not the Brotherhood. Everyone has a plan for me.", "next": "choose2"},
		"choose2": {"who": "dawa", "expr": "determined", "text": "I'm staying. This is where I'm useful. But — Pemba. Write to me. And next time you're in the Lower Ring, the rice is from us.", "next": "choose3"},
		"choose3": {"who": "pemba", "expr": "tender", "text": "Thank you for not deciding for her. Thank you for not deciding for me either, which you also didn't do. I noticed.",
			"do": [["flag", "dawa_free", true], ["flag", "pemba_done", true], ["approval", "pemba", 15], ["call", "red_lanterns_friends"],
				["journal_done", "cq_pemba", "Dawa chose to stay with the Red Lanterns. The Brotherhood counts you as a friend, and the Lower Ring eats a little better."]]},
	}},

	# -----------------------------------------------------------------------
	# Nima — The Two Paths
	# -----------------------------------------------------------------------
	"cq_nima_start": {"title": "Nima", "start": "a", "nodes": {
		"a": {"who": "nima", "expr": "angry", "text": "A letter from my sister. She keeps Kaya while I'm away, and Kaya was caught practising forms behind the healing huts. My forms. The ones I taught myself. Master Aklaq has forbidden her from the training ice. She's seven.", "next": "b"},
		"b": {"who": "nima", "expr": "thoughtful", "text": "I'm not angry at Aklaq. That's what's maddening. He isn't cruel. He believes the law keeps healers alive. He watched a famine war nearly kill every one of us when he was a boy. He has a good argument. It's just wrong.", "next": "c"},
		"c": {"who": "nima", "expr": "determined", "text": "I want to go home and change the law. Or fight him for it. Or take Kaya south, where nobody cares what a girl does with water. I haven't decided. I'd like you there when I do.", "choices": [
			{"text": "\"Then we're going north.\"", "next": "d", "do": [["approval", "nima", 5]]},
			{"text": "\"Tell me about Kaya.\"", "next": "kaya"},
		]},
		"kaya": {"who": "nima", "expr": "happy", "text": "She's loud. She names every seal she sees. She wants to be a healer and a warrior and a fish, in that order. Last winter she negotiated with me about boots for an hour and won.", "next": "d", "do": [["approval", "nima", 3]]},
		"d": {"who": "nima", "expr": "neutral", "text": "Agna Qel'a, then. Dress warmly. I won't nag. I will absolutely nag.",
			"do": [["flag", "nima_q", true], ["journal", "cq_nima", "Nima: The Two Paths", "Nima's daughter Kaya has been forbidden from learning combat waterbending under the Law of the Two Paths. Go with Nima to the council hall in Agna Qel'a."]]},
	}},
	"cq_nima_council": {"title": "The Two Paths", "start": "a", "nodes": {
		"a": {"who": "aklaq", "expr": "neutral", "text": "Nima. I know why you've come. I know what you've been doing at night in the healing huts — I'm old, not blind. The answer is still no.", "next": "b"},
		"b": {"who": "aklaq", "expr": "sad", "text": "When I was ten, the Tribe went to war over the fishing grounds. Everyone fought. By spring there were four healers left and we buried children who should have lived. The law was written so that never happens again. When everyone fights, no one mends.", "next": "c"},
		"c": {"who": "nima", "expr": "determined", "text": "Then let the ones who want to mend, mend, and the ones who want to fight, fight. Kaya wants both. So did I. So, I think, did a great many women you never asked.", "choices": [
			{"text": "Petition the council, with Elder Pana's support.", "next": "petition", "if": {"rel": ["northern_water", 20]}, "hint": "needs Northern Water Tribe relation 20"},
			{"text": "\"Nima — challenge him. Let the ice decide.\"", "next": "prep"},
			{"text": "\"Or take Kaya south, where the law doesn't reach.\"", "next": "south"},
		]},
		"petition": {"who": "pana", "expr": "determined", "text": "I have trained every healer in this city for forty years. Half of them have asked me to teach them more. I said no, because of the law. I am done saying no. I move that the Law of the Two Paths be ended.", "next": "petition2"},
		"petition2": {"who": "narrator", "text": "The council argues until the lamps burn down. Chief Tulok votes last. He looks at Aklaq for a long moment, and then he votes yes.", "next": "win"},
		"prep": {"who": "nima", "expr": "afraid", "text": "He's the best waterbender in the North. I've never fought anyone who wasn't a wall of ice. — Help me get ready. Anything.", "choices": [
			{"text": "Walk through Aklaq's style with her, move by move.", "next": "duel", "do": [["flag", "nima_prep", "study"]]},
			{"text": "\"Don't fight for the law. Fight for Kaya.\"", "next": "duel", "do": [["flag", "nima_prep", "kaya"]]},
			{"text": "\"I've watched you hold a line for months. I believe in you.\"", "next": "duel", "do": [["flag", "nima_prep", "believe"]]},
		]},
		"duel": {"who": "narrator", "text": "They face each other on the training ice at dawn, the whole Tribe watching from the walls. Aklaq bows. Nima bows. The water rises.", "choices": [
			{"text": "Watch.", "next": "duel_win", "if": {"call": "nima_wins"}, "hide": true},
			{"text": "Watch.", "next": "duel_lose", "if": {"call": "nima_loses"}, "hide": true},
		]},
		"duel_win": {"who": "narrator", "text": "It is long, and beautiful, and nearly over twice. In the end Nima turns his own wave back on him and pins the old master to the ice with a blade of it at his throat — and then lets it fall as water. Aklaq lies there, breathing, and laughs.", "next": "duel_win2"},
		"duel_win2": {"who": "aklaq", "expr": "smirk", "text": "Where did you learn the reversal? — No. I know where. From watching me. Well. I suppose I'm the one who's been teaching you all along.", "next": "win"},
		"duel_lose": {"who": "narrator", "text": "Nima is good. Aklaq is better, and has been for fifty years. She ends on her back on the ice. But it was close — closer than anyone on the walls expected, and every girl watching saw how close.", "next": "duel_lose2"},
		"duel_lose2": {"who": "aklaq", "expr": "thoughtful", "text": "…The law stands. For now. Bring the girl to me next winter, Nima. I'd like to see what she does with the reversal.",
			"do": [["flag", "nima_lost", true], ["flag", "nima_done", true], ["approval", "nima", 5], ["rel", "northern_water", 5],
				["journal_done", "cq_nima", "Nima lost her duel with Master Aklaq, narrowly. The law stands — but Aklaq has asked to see Kaya train."]]},
		"win": {"who": "nima", "expr": "laugh", "text": "Kaya is going to be unbearable. Wonderful. Unbearable.",
			"do": [["call", "two_paths"], ["flag", "nima_done", true], ["approval", "nima", 20], ["rel", "northern_water", 10], ["renown", 20],
				["journal_done", "cq_nima", "The Law of the Two Paths is ended. Northern women may learn to fight; the Moon Guard can be trained. Master Aklaq has resigned — and has asked to teach Kaya himself."]]},
		"south": {"who": "nima", "expr": "sad", "text": "…Yes. Maybe that's the answer. Not the brave one. The one where Kaya grows up without having to fight her own Tribe first. I'll write to the South.",
			"do": [["flag", "nima_south", true], ["flag", "nima_done", true], ["rel", "northern_water", -10], ["rel", "southern_water", 5], ["approval", "nima", 5],
				["journal_done", "cq_nima", "Nima chose to raise Kaya in the South. The North's law is unchanged."]]},
	}},

	# -----------------------------------------------------------------------
	# Ukiuk — Debts at Sea
	# -----------------------------------------------------------------------
	"cq_ukiuk_start": {"title": "Ukiuk", "start": "a", "nodes": {
		"a": {"who": "ukiuk", "expr": "embarrassed", "text": "Okay so — no, wait, let me fix this net while I say it, it's easier if my hands are busy — two winters ago I was on Qannik's raid at Shu Jing, you know Shu Jing, Fire Nation, fishing village, lovely harbour, terrible noodles — not terrible, I'm lying, the noodles were great —", "next": "b"},
		"b": {"who": "ukiuk", "expr": "sad", "text": "My harpoon line snagged a boat in the dark. Not a warship. A fishing boat. It went over. There was a man on it. I didn't — I couldn't find him in the water. I looked. I looked for a long time and Qannik dragged me back by my parka.", "next": "c"},
		"c": {"who": "ukiuk", "expr": "thoughtful", "text": "His widow's called Kimi. She has a noodle stall. I send her money every season, no name. She probably thinks it's a mistake. It's the opposite of a mistake. It's the only thing I've done on purpose in two years.", "choices": [
			{"text": "\"Do you want to see her?\"", "next": "d", "do": [["approval", "ukiuk", 5]]},
			{"text": "\"That's a lot to carry alone.\"", "next": "alone", "do": [["approval", "ukiuk", 3]]},
		]},
		"alone": {"who": "ukiuk", "expr": "embarrassed", "text": "I'm very strong. Emotionally, less so. But my shoulders are great.", "next": "d"},
		"d": {"who": "ukiuk", "expr": "afraid", "text": "…Yes. No. Yes. If you come. I'll talk the whole way there and then I won't be able to say anything, probably. Warning you in advance. Hana says that's polite.",
			"do": [["flag", "ukiuk_q", true], ["journal", "cq_ukiuk", "Ukiuk: Debts at Sea", "On a raid, Ukiuk accidentally drowned a fisherman of Shu Jing. He sends the widow, Kimi, money in secret. Go with him to Shu Jing."]]},
	}},
	"cq_ukiuk_kimi": {"title": "Debts at Sea", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Kimi's stall is four stools and a cauldron on the harbour wall. She is ladling broth for a fisherman and does not look up. Ukiuk, who has talked without pause for two days, says nothing at all.", "choices": [
			{"text": "Put a hand on his shoulder and wait.", "next": "confess", "do": [["approval", "ukiuk", 5]]},
			{"text": "\"We can leave. You don't owe this to anyone.\"", "next": "hide"},
		]},
		"confess": {"who": "ukiuk", "expr": "grief", "text": "Ma'am. The money. It's from me. I was on the boat that — the line was mine. Your husband. It was me. I'm sorry. That's all I've got. I'm sorry.", "next": "c2"},
		"c2": {"who": "narrator", "text": "Kimi sets down the ladle. She walks around the counter, looks up at him — he is a head taller — and hits him across the face, hard, once. Then she points at a stool.", "next": "c3"},
		"c3": {"who": "kimi", "expr": "angry", "text": "Sit. You'll eat. You look like a harpoon. — Two years of money and not one letter. Do you know what that's like? Thinking somebody out there pities you? — Eat. Then you'll tell me how it happened. All of it. Then we'll see.", "next": "c4"},
		"c4": {"who": "ukiuk", "expr": "tender", "text": "…These really are great noodles. Sorry. Sorry. Eating.",
			"do": [["flag", "ukiuk_confessed", true], ["flag", "ukiuk_done", true], ["approval", "ukiuk", 15], ["lord_rel", "qannik", -20], ["rel", "fire_nation", 3],
				["journal_done", "cq_ukiuk", "Ukiuk confessed to Kimi. She hit him, then fed him. He says he's done with raiding. Qannik calls him a traitor."]]},
		"hide": {"who": "ukiuk", "expr": "sad", "text": "…Yeah. Yeah, let's go. Next season. I'll send more next season. That's — that'll have to be enough.",
			"do": [["flag", "ukiuk_hid", true], ["flag", "ukiuk_done", true],
				["journal_done", "cq_ukiuk", "Ukiuk could not bring himself to speak to Kimi. The money will keep arriving, unsigned."]]},
	}},

	# -----------------------------------------------------------------------
	# Shen Mu — Signed, Sealed
	# -----------------------------------------------------------------------
	"cq_shenmu_start": {"title": "Shen Mu", "start": "a", "nodes": {
		"a": {"who": "shen_mu", "expr": "afraid", "text": "I sh-should tell you what I'm carrying. Because people will try to kill us for it. Not — not definitely. Probably.", "next": "b"},
		"b": {"who": "shen_mu", "expr": "neutral", "text": "It's a letter from Crown Princess Ryoko to Consort Jiang Wei. I was given it in Caldera by someone who said it was very important and then ran away, which is a bad sign. Ba Sing Se has a price on me. So does the Admiralty.", "next": "c"},
		"c": {"who": "shen_mu", "expr": "determined", "text": "I d-don't read the letters. Ever. A letter is a promise. You don't open someone's promise. I just get them there. This one has to get to Omashu.", "choices": [
			{"text": "\"Then we'll get it to Omashu.\"", "next": "d", "do": [["approval", "shen_mu", 5]]},
			{"text": "\"What does it say?\"", "next": "say"},
		]},
		"say": {"who": "shen_mu", "expr": "angry", "text": "I j-just told you. I don't know. I don't want to know. Please don't ask me again.", "next": "d", "do": [["approval", "shen_mu", -3]]},
		"d": {"who": "shen_mu", "expr": "happy", "text": "Thank you. I know four routes. I'll draw them. I can't write them, but I can draw them. They'll be very good drawings.",
			"do": [["flag", "shenmu_q", true], ["journal", "cq_shenmu", "Shen Mu: Signed, Sealed", "Shen Mu carries a secret letter from Crown Princess Ryoko to Consort Jiang Wei. Ba Sing Se and the Admiralty both want it. Escort him to Omashu."]]},
	}},
	"cq_shenmu_ambush": {"title": "Signed, Sealed", "start": "a", "nodes": {
		"a": {"who": "shen_mu", "expr": "afraid", "text": "Green robes on the ridge. Dai Li. They're not here for the scenery. — I'm not giving them the letter. I'm just saying that out loud so I hear myself say it."},
	}},
	"cq_shenmu_ambush_beaten": {"title": "Signed, Sealed", "start": "a", "nodes": {
		"a": {"who": "shen_mu", "expr": "happy", "text": "Still sealed. Still s-sealed! Sorry, I need to sit down. My legs have decided to be someone else's legs for a minute."},
	}},
	"cq_shenmu_deliver": {"title": "Signed, Sealed", "start": "a", "nodes": {
		"a": {"who": "jiang_wei", "expr": "thoughtful", "text": "Ryoko's seal. And not opened — you can tell, she uses a hair across the wax. You're a rare courier, young man.", "next": "b"},
		"b": {"who": "jiang_wei", "expr": "surprised", "text": "…She proposes the Fire Nation withdraw from two Ember Coast ports, in exchange for Omashu grain, and — spirits. Quiet recognition of Omashu as a kingdom. Feng is going to make a speech. Feng is going to make a very long speech.",
			"do": [["call", "omashu_talks"], ["flag", "letter_delivered", true], ["renown", 25], ["approval", "shen_mu", 10], ["lord_rel", "jiang_wei", 20], ["lord_rel", "ryoko", 10]], "next": "c"},
		"c": {"who": "narrator", "text": "On the way out of the palace, a courier with a bandana and a sprained wrist comes skidding down a chute and nearly lands on Shen Mu. They stare at each other. Shen Mu turns the colour of a fire-lily.", "next": "d"},
		"d": {"who": "lin", "expr": "embarrassed", "text": "Shen! You're back. You're — I heard there were Dai Li — I walked your route every day to see if — I mean. Hi.", "choices": [
			{"text": "Nudge Shen Mu forward.", "next": "e"},
			{"text": "Discreetly go and look at a very interesting wall.", "next": "e"},
		]},
		"e": {"who": "shen_mu", "expr": "embarrassed", "text": "L-Lin. I. You walked four miles out of your route. Nima said that w-wasn't for the exercise. Was it for the exercise?", "next": "f"},
		"f": {"who": "lin", "expr": "happy", "text": "It was not for the exercise.",
			"do": [["flag", "shenmu_lin", true], ["flag", "shenmu_done", true], ["approval", "shen_mu", 10],
				["journal_done", "cq_shenmu", "Shen Mu delivered Ryoko's letter, unopened. Omashu and the Fire Nation are talking. Also, Lin walked four miles out of his route, and it was not for the exercise."]]},
	}},

	# -----------------------------------------------------------------------
	# Reika — Letters of Marque
	# -----------------------------------------------------------------------
	"cq_reika_start": {"title": "Reika", "start": "a", "nodes": {
		"a": {"who": "reika", "expr": "thoughtful", "text": "Let me tell you about cargo. Last month the Admiral paid me to escort three 'grain ships' up the coast. Grain doesn't clink. I looked. Earth Kingdom tax silver, still in the Queen's chests, sailing to a Fire Navy harbour.", "next": "b"},
		"b": {"who": "reika", "expr": "angry", "text": "So either the Admiral's robbing the Earth Kingdom, which, fine, that's the war — or someone in Ba Sing Se is paying him. And if it's the second one, every sailor who died on that coast died for a business arrangement.", "next": "c"},
		"c": {"who": "reika", "expr": "smirk", "text": "He keeps his real ledgers in the counting-house at the Fire Navy Harbour. I'd like to read them. I'd like even more to keep sailing under his letter of marque and get rich. I haven't decided. Talk me out of one of them.", "choices": [
			{"text": "\"Read the ledgers. You already know what you'll find.\"", "next": "d", "do": [["approval", "reika", 3]]},
			{"text": "\"Get rich. Nobody pays you to be good.\"", "next": "d", "do": [["approval", "reika", 1]]},
		]},
		"d": {"who": "reika", "expr": "neutral", "text": "Either way, the harbour. I'll decide when I'm standing in his office with my hand on the drawer. That's how I make all my best decisions.",
			"do": [["flag", "reika_q", true], ["journal", "cq_reika", "Reika: Letters of Marque", "Reika suspects Admiral Kuro is being paid in Earth Kingdom tax silver. His ledgers are in the counting-house at the Fire Navy Harbour."]]},
	}},
	"cq_reika_ledgers": {"title": "Letters of Marque", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Midnight. Reika picks the counting-house lock with a hairpin she claims belonged to a duchess. The ledger is in the second drawer, bound in sharkskin. She reads by a shuttered lantern, turning the pages faster and faster.", "next": "b"},
		"b": {"who": "reika", "expr": "furious", "text": "Payments. From the Grand Secretariat in Ba Sing Se. Every quarter, for eleven years, starting the month after the Avatar drowned. They're paying each other to keep the war going. Both sides. The same war.", "choices": [
			{"text": "\"Take it. Burn your letter of marque.\"", "next": "take"},
			{"text": "\"Put it back. Blackmail him later — he'll pay more than the war does.\"", "next": "keep"},
		]},
		"take": {"who": "reika", "expr": "determined", "text": "You know what? Yes. I've been a lot of things. A woman who carries his silver isn't going to be one of them anymore.", "next": "take2"},
		"take2": {"who": "narrator", "text": "Reika holds her letter of marque over the lantern until the Admiral's seal blisters, then drops it in his inkwell. It is, she says, a statement.",
			"do": [["flag", "kuro_ledgers", true], ["flag", "reika_free", true], ["flag", "reika_done", true], ["approval", "reika", 15], ["lord_rel", "kuro", -30],
				["journal_done", "cq_reika", "Reika took Admiral Kuro's ledgers — proof that he and Ba Sing Se's Grand Secretariat have paid each other to prolong the war — and burned her letter of marque."]]},
		"keep": {"who": "reika", "expr": "smirk", "text": "Ha. That's cold. I like cold. — I'll copy the good pages and put the rest back. A thousand gold says he pays us to forget we ever saw it.", "next": "keep2"},
		"keep2": {"who": "narrator", "text": "He does. A thousand gold, delivered by a man who will not meet your eyes. Reika counts it twice and does not laugh as much as she usually does.",
			"do": [["gold", 1000], ["flag", "reika_kept", true], ["flag", "reika_done", true], ["approval", "reika", -5],
				["journal_done", "cq_reika", "You and Reika blackmailed Admiral Kuro instead of exposing him. It paid. Reika seems quieter."]]},
	}},

	# -----------------------------------------------------------------------
	# Kesi — The Quiet Sand
	# -----------------------------------------------------------------------
	"cq_kesi_start": {"title": "Kesi", "start": "a", "nodes": {
		"a": {"who": "kesi", "expr": "thoughtful", "text": "(signing, slowly, so you can follow) My clan — not mine anymore — still my clan. Starving. Misty Palms closed its wells to sandbenders last summer. The garrison says we steal. We do steal. Because the wells are closed.", "next": "b"},
		"b": {"who": "kesi", "expr": "sad", "text": "(signing) They exiled me for refusing a raid. A caravan with children. I was right. They're still my people. Elder Rasa still signs my name-sign when she thinks I can't see.", "next": "c"},
		"c": {"who": "kesi", "expr": "determined", "text": "(signing) I want to fix it. I don't know how. You talk to garrisons better than me. Garrisons don't learn sign.", "choices": [
			{"text": "(sign back, badly) \"We go. Together.\"", "next": "d", "do": [["approval", "kesi", 8]]},
			{"text": "\"We'll go to Misty Palms.\"", "next": "d", "do": [["approval", "kesi", 4]]},
		]},
		"d": {"who": "kesi", "expr": "smirk", "text": "(signing) You just signed 'we go, potato'. Close enough. Good.",
			"do": [["flag", "kesi_q", true], ["journal", "cq_kesi", "Kesi: The Quiet Sand", "Kesi's clan is starving since Misty Palms closed its wells to sandbenders. Go with her to Misty Palms Oasis."]]},
	}},
	"cq_kesi_wells": {"title": "The Quiet Sand", "start": "a", "nodes": {
		"a": {"who": "garrison_captain", "expr": "neutral", "text": "The wells are closed to the sand people by order of the Serpent's Pass command. They raid caravans. They steal water. If they want to drink they can stop thieving.", "next": "b"},
		"b": {"who": "kesi", "expr": "angry", "text": "(signing; you translate) They steal water because you closed the water. She would like to know which came first, the stealing or the order. She has a theory.", "choices": [
			{"text": "\"Let's negotiate. Water rights, paid by me, and the raids stop.\" (600 gold)", "next": "pay", "if": {"gold": 600}, "hint": "need 600 gold"},
			{"text": "Talk the captain into a water-sharing arrangement.", "next": "trade", "if": {"skill": ["trade", 3]}, "hint": "needs Trade 3"},
			{"text": "(Pemba or Nima) \"There's a swamp to the south with more water than anyone can drink. And people who'd welcome the clan.\"", "next": "swamp", "if": {"call": "pemba_or_nima"}, "hint": "needs Pemba or Nima to mediate"},
			{"text": "\"Open the wells, or we open them for you.\"", "next": "fight"},
		]},
		"pay": {"who": "garrison_captain", "expr": "thoughtful", "text": "…Paid water rights. In writing. I suppose the command can't object to a contract. Tell the elder she can send her people at dawn and dusk. And no raids.", "do": [["gold", -600]], "next": "wells"},
		"trade": {"who": "garrison_captain", "expr": "thoughtful", "text": "Hm. Sandbenders guiding caravans through the dunes, in exchange for water. Fewer lost caravans, fewer raids, and I look clever to the command. Fine. Dawn and dusk.", "next": "wells"},
		"wells": {"who": "clan_elder", "expr": "tender", "text": "(signing, to Kesi) You came back. You came back with water. — Your name-sign is still yours, child. It always was.",
			"do": [["flag", "kesi_wells", true], ["flag", "kesi_done", true], ["call", "kesi_swamp"], ["approval", "kesi", 15],
				["journal_done", "cq_kesi", "Kesi's clan can draw water at Misty Palms. The raids will stop. Elder Rasa says Kesi's name-sign is still hers."]]},
		"swamp": {"who": "narrator", "text": "It takes a week of talking — Kesi signing, your companion translating, the elder arguing — and a longer week of walking. The Foggy Swamp tribe looks at forty sandbenders arriving through the mist, shrugs, and starts building more huts.", "next": "swamp2"},
		"swamp2": {"who": "kesi", "expr": "laugh", "text": "(signing) Sand people in a swamp. Everyone will be wet forever. They're going to complain for a hundred years. It's perfect.",
			"do": [["flag", "kesi_swamp", true], ["flag", "kesi_done", true], ["call", "kesi_swamp"], ["approval", "kesi", 20], ["wait", 96.0], ["prosperity", "foggy_swamp", 10], ["renown", 15],
				["journal_done", "cq_kesi", "Kesi's clan has moved to the Foggy Swamp, where there is more water than anyone can drink. They will complain about it for a hundred years."]]},
		"fight": {"who": "garrison_captain", "expr": "angry", "text": "That's an attack on a royal garrison. You'll hang for this — after the wells, I suppose.", "next": "fight2"},
		"fight2": {"who": "narrator", "text": "The garrison is small and the clan is waiting in the dunes. It is over quickly. The wells are open. The Earth Kingdom will remember who opened them.",
			"do": [["flag", "kesi_fought", true], ["flag", "kesi_done", true], ["call", "kesi_swamp"], ["approval", "kesi", 8], ["rel", "earth_kingdom", -15], ["lord_rel", "tan_yue", -15],
				["journal_done", "cq_kesi", "You forced Misty Palms' wells open. Kesi's clan drinks. The Earth Kingdom is furious."]]},
	}},

	# -----------------------------------------------------------------------
	# Partings (approval too low)
	# -----------------------------------------------------------------------
	"leave_generic_hana": {"title": "Hana", "start": "a", "nodes": {"a": {"who": "hana", "expr": "neutral", "text": "I've made a list of the things you've done that I can't stand next to. It's long. I'm leaving. I'm telling you in advance, which is more than you did for anyone.", "do": [["leave", "hana"]]}}},
	"leave_generic_juro": {"title": "Juro", "start": "a", "nodes": {"a": {"who": "juro", "expr": "sad", "text": "I walked away from one army because of what it burned. I can't watch it happen again from closer up. Goodbye, {name}.", "do": [["leave", "juro"]]}}},
	"leave_generic_pemba": {"title": "Pemba", "start": "a", "nodes": {"a": {"who": "pemba", "expr": "sad", "text": "I said I wouldn't fight for you. I didn't say I'd stand by while you did this. I'm going home. I hope you find whatever you're looking for, and I hope it's kinder than this.", "do": [["leave", "pemba"]]}}},
	"leave_generic_nima": {"title": "Nima", "start": "a", "nodes": {"a": {"who": "nima", "expr": "angry", "text": "I have a daughter who thinks I'm a hero. I won't be one of your soldiers and then go home and lie to her. Goodbye.", "do": [["leave", "nima"]]}}},
	"leave_generic_ukiuk": {"title": "Ukiuk", "start": "a", "nodes": {"a": {"who": "ukiuk", "expr": "sad", "text": "I've been on a crew that did things like this. I left it. I'm leaving this one too. No speech. I'd mess it up.", "do": [["leave", "ukiuk"]]}}},
	"leave_generic_shen_mu": {"title": "Shen Mu", "start": "a", "nodes": {"a": {"who": "shen_mu", "expr": "sad", "text": "I c-carry promises. I don't think you keep them. I'm going to go now, before I say something mean. I'd regret it. You wouldn't.", "do": [["leave", "shen_mu"]]}}},
	"leave_generic_reika": {"title": "Reika", "start": "a", "nodes": {"a": {"who": "reika", "expr": "smirk", "text": "I've sailed with pirates, smugglers and one actual duke. You're the first person who's made me feel like the good one. That's not a compliment. Bye.", "do": [["leave", "reika"]]}}},
	"leave_generic_kesi": {"title": "Kesi", "start": "a", "nodes": {"a": {"who": "kesi", "expr": "angry", "text": "(signing, fast, then slowly so you understand it) I left my clan for less than this. I'm leaving you.", "do": [["leave", "kesi"]]}}},
}
