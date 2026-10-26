extends RefCounted
## Expansion: Roots of the Mountain (earth). New people: Gao Ming (companion),
## Madam Cheng Lu of Gaoling, Old Shan of Stonewatch Pass, Master Bo Ren of
## Omashu's boulder school. Stories: the Jade Seam strike (Gao Ming); a
## cave-in; the Badgermole's Patience mastery trial. Bo Lai (from Hana's
## quest) can teach the Dai Li's Stone Hand if Hana spared him.

const NPCS := {
	"cheng_lu": {"name": "Madam Cheng Lu", "culture": "earth", "vlook": {"sex": "f", "hair": "Hair_Buns", "hair_color": Color(0.3, 0.28, 0.27)}, "kit": "civ_robe"},
	"old_shan": {"name": "Old Shan", "culture": "earth", "vlook": {"sex": "m", "hair": "Hair_Long", "beard": true, "hair_color": Color(0.88, 0.88, 0.86), "height": 0.9}, "kit": "sash"},
	"bo_ren": {"name": "Master Bo Ren", "culture": "omashu", "vlook": {"sex": "m", "hair": "Hair_Buzzed", "beard": true, "height": 1.08}, "kit": "ek_armor", "outfit": "ranger"},
	"miner": {"name": "Foreman Xiu", "culture": "earth", "vlook": {"sex": "f", "hair": "Hair_BuzzedFemale", "accessory": "bandana"}},
}

const SPAWNS := {}

const TRIGGERS := [
	{"on": "daily", "dlg": "ex_gao_start", "if": {"companion": "gao_ming", "days_since": ["joined_gao_ming", 5]}},
	{"on": "daily", "dlg": "ex_cavein", "if": {"bends": "earth", "near_faction": "earth_kingdom", "day": 20}, "chance": 0.04},
]

const OPTIONS := [
	{"sid": "omashu", "text": "Train with the boulder masters", "dlg": "ex_boulder", "if": {"bend": "earth"}},
	{"sid": "ba_sing_se", "text": "Find Bo Lai, who sealed the tunnel", "dlg": "ex_bolai", "if": {"bend": "earth", "flag": "hana_spared"}},
	{"sid": "ba_sing_se", "text": "Petition to study at the Dai Li academy", "dlg": "ex_academy", "if": {"bend": "earth", "standing": 2, "call": "ex_academy_ok"}},
	{"sid": "stonewatch", "text": "Climb to Old Shan's cave", "dlg": "ex_shan", "if": {}},
	{"sid": "gaoling", "text": "Go with Gao Ming to the Cheng family's jade seam", "dlg": "ex_seam", "if": {"companion": "gao_ming", "flag": "gao_q", "not_flag": "gao_done"}},
]

const DIALOGUES := {
	# -----------------------------------------------------------------------
	# Gao Ming
	# -----------------------------------------------------------------------
	"talk_gao_ming": {"title": "Gao Ming", "start": "hub", "nodes": {
		"hub": {"who": "gao_ming", "expr": "neutral", "text": "If this is about the tent pegs: yes, I bent them in deeper. You can thank me when the wind comes. What is it?", "choices": [
			{"text": "\"Tell me about Lian.\"", "next": "lian"},
			{"text": "\"How did you end up organising miners?\"", "next": "union"},
			{"text": "\"What's it like underground?\"", "next": "under"},
			{"text": "\"Teach me to split the ground.\" (Fissure)", "next": "learn_fissure", "if": {"bend": "earth", "approval": ["gao_ming", 20], "no_tech": "e_fissure"}, "hint": "earthbenders only; Gao Ming's approval 20"},
			{"text": "\"Teach me to wear the mountain.\" (Stone Armour)", "next": "learn_armor", "if": {"bend": "earth", "approval": ["gao_ming", 40], "no_tech": "e_armor"}, "hint": "earthbenders only; Gao Ming's approval 40"},
			{"text": "\"You're the steadiest thing I've ever leaned on.\"", "next": "rom", "if": {"approval": ["gao_ming", 50], "not_flag": "romance_gao_ming"}, "hide": true},
			{"text": "\"Let's keep moving.\"", "next": ""},
		]},
		"lian": {"who": "gao_ming", "expr": "happy", "text": "Twelve. She writes me letters and corrects my spelling in the replies. She wants to be an engineer and build a mine nobody dies in. I said that's a fine idea. She said it's not an idea, it's a plan, and I should keep up.", "next": "hub"},
		"union": {"who": "gao_ming", "expr": "thoughtful", "text": "A roof came down on my shift when I was twenty. Eleven of us. I held it up for an hour while they crawled out, and then I couldn't stand for a week. The owner docked my wages for the week. That was a very educational week.", "next": "hub"},
		"under": {"who": "gao_ming", "expr": "tender", "text": "Quiet. The kind of quiet that has weight. You feel every footstep above you like rain. My wife used to say I came up from shift like a man coming out of a temple. She wasn't wrong. It's a temple that kills people sometimes.", "next": "hub"},
		"learn_fissure": {"who": "gao_ming", "expr": "determined", "text": "Rock has grain, like wood. Find the grain and the rock wants to split along it. You're not breaking the ground; you're agreeing with it. — Feel that? That's the ground saying yes.",
			"do": [["wait", 24.0], ["learn", "e_fissure"], ["approval", "gao_ming", 3]], "next": "hub"},
		"learn_armor": {"who": "gao_ming", "expr": "smirk", "text": "Pull the stone up your legs like trousers. Then a coat. Don't do the helmet first; you'll be blind and very stupid-looking. Ask me how I know.",
			"do": [["wait", 48.0], ["learn", "e_armor"], ["approval", "gao_ming", 3]], "next": "hub"},
		"rom": {"who": "gao_ming", "expr": "surprised", "text": "Steady. Huh. Most people say stubborn. — I'm out of practice at this. I was married twelve years and widowed four, and I've spent all four of them being somebody's dad and somebody's foreman.", "next": "rom2"},
		"rom2": {"who": "gao_ming", "expr": "tender", "text": "But I'd like to be somebody's something else. If that's you. Lian will want to meet you. She'll interview you. Bring references.", "choices": [
			{"text": "\"I'll bring references.\"", "next": "rom3", "do": [["flag", "romance_gao_ming", true], ["approval", "gao_ming", 10]]},
			{"text": "\"I meant as a friend.\"", "next": "rom_no"},
		]},
		"rom3": {"who": "gao_ming", "expr": "laugh", "text": "Good. Good. I'm going to go and bend a very large rock now, for no reason. Happily.", "next": "hub"},
		"rom_no": {"who": "gao_ming", "expr": "smirk", "text": "That's all right. Friend's a good word. Load-bearing.", "next": "hub"},
	}},
	"leave_generic_gao_ming": {"title": "Gao Ming", "start": "a", "nodes": {"a": {"who": "gao_ming", "expr": "angry", "text": "I've worked for owners who treated people like ore. I didn't expect to find one at the head of a column. I'm going home to my daughter. I'll tell her I found out in time.", "do": [["leave", "gao_ming"]]}}},
	"ex_gao_start": {"title": "Gao Ming", "start": "a", "nodes": {
		"a": {"who": "gao_ming", "expr": "angry", "text": "Letter from Gaoling. The Cheng family's jade seam came down last month: six dead. Madam Cheng cut everyone's wages to pay for the repairs. The miners are going to strike. They've asked me to come and speak for them.", "next": "b"},
		"b": {"who": "gao_ming", "expr": "thoughtful", "text": "If they strike without a plan, the Chengs hire scabs from the Lower Ring, and then it's poor people breaking each other's heads for the owner's benefit. I've seen it. I'd rather not see it again. Will you come?", "choices": [
			{"text": "\"We'll go to Gaoling.\"", "next": "c", "do": [["approval", "gao_ming", 5]]},
			{"text": "\"What's the plan?\"", "next": "plan"},
		]},
		"plan": {"who": "gao_ming", "expr": "smirk", "text": "Step one: make the roof safe so nobody can say the strike's about danger they made up. Step two: be more stubborn than a merchant. I'm good at both. — So?", "next": "c"},
		"c": {"who": "gao_ming", "expr": "determined", "text": "Gaoling. The seam's in the hills behind the Cheng house. Madam Cheng will offer you tea. Don't drink it; she'll consider it a contract.",
			"do": [["flag", "gao_q", true], ["journal", "ex_gao", "Gao Ming: The Jade Seam", "Miners at the Cheng family's jade seam near Gaoling are about to strike after a collapse killed six and wages were cut. Go there with Gao Ming."]]},
	}},
	"ex_seam": {"title": "The Jade Seam", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Forty miners sit on the spoil heap outside the seam with their arms folded. Madam Cheng Lu sits under an awning opposite them, with a ledger and a pot of tea, looking like someone who has outwaited worse.", "next": "b"},
		"b": {"who": "cheng_lu", "expr": "neutral", "text": "Gao Ming. Of course. And a commander with an army. How flattering. The repairs cost what they cost. If they won't work for less, there are a hundred families in the Lower Ring who will.", "next": "c"},
		"c": {"who": "miner", "expr": "angry", "text": "Six of us are under that hill. We'll dig for less when she sleeps in the tunnel for a week.", "choices": [
			{"text": "\"Gao Ming and I will shore up the seam ourselves, today. Then we talk wages.\"", "next": "shore", "if": {"bends": "earth"}, "hint": "needs an earthbender"},
			{"text": "\"Madam Cheng, I'll pay the repairs. Restore the wages.\" (800 gold)", "next": "pay", "if": {"gold": 800}, "hint": "need 800 gold"},
			{"text": "Stand with the strike, whatever it costs.", "next": "strike"},
			{"text": "\"Madam Cheng is right. Back to work.\" (She'll pay you 1,500 gold)", "next": "break"},
		]},
		"shore": {"who": "narrator", "text": "You go in together. Gao Ming finds every crack by feel and you seal them, a day and a night underground, until the hill stops creaking. When you come out, the miners stand up. Madam Cheng puts down her tea.", "next": "deal"},
		"pay": {"who": "cheng_lu", "expr": "surprised", "text": "…Paid in full. Well. A ledger doesn't care where the money comes from, and neither do I. The wages are restored. You'll forgive me if I find you inexplicable.", "next": "deal2"},
		"deal": {"who": "cheng_lu", "expr": "thoughtful", "text": "A safe seam is cheaper than a strike. I can count. Wages restored, a shift limit, and the widows paid from the jade, not the wages. Don't make me say it twice; I'll regret it.", "next": "deal2"},
		"deal2": {"who": "gao_ming", "expr": "happy", "text": "That's a contract. Write it down, Xiu. In big letters. — Thank you. I didn't have to hold up a roof this time. That's progress.",
			"do": [["flag", "gao_done", true], ["flag", "gao_deal", true], ["approval", "gao_ming", 20], ["renown", 20], ["prosperity", "gaoling", 5], ["honor", 2],
				["journal_done", "ex_gao", "The Jade Seam is shored up, wages restored and a shift limit agreed. Gao Ming has stopped grinding his teeth."]]},
		"strike": {"who": "narrator", "text": "The strike lasts six weeks. Your soldiers carry rice to the spoil heap. Madam Cheng hires no scabs, because the Lower Ring heard who was standing with the miners. In the end she signs, and hates you for it, politely, in every letter.",
			"do": [["wait", 48.0], ["flag", "gao_done", true], ["flag", "gao_strike", true], ["approval", "gao_ming", 15], ["gold", -300], ["prosperity", "gaoling", -5], ["rel", "earth_kingdom", -5],
				["journal_done", "ex_gao", "The strike held and Madam Cheng signed. Gaoling's merchants resent you; the miners name a tunnel after you."]]},
		"break": {"who": "gao_ming", "expr": "furious", "text": "Six of them are under that hill. — No. I'm done. I hope the jade keeps you warm.",
			"do": [["flag", "gao_done", true], ["flag", "gao_broken", true], ["gold", 1500], ["infamy", 15, "breaking the jade strike"], ["leave", "gao_ming"],
				["journal_done", "ex_gao", "You broke the strike for Madam Cheng. Gao Ming left your company."]]},
	}},

	# -----------------------------------------------------------------------
	# Teachers: Omashu's boulder school, Bo Lai, the Dai Li academy
	# -----------------------------------------------------------------------
	"ex_boulder": {"title": "The Boulder School", "start": "hub", "nodes": {
		"hub": {"who": "bo_ren", "expr": "laugh", "text": "Ha! Another one! Omashu's earthbending is very simple: pick up the biggest rock you can, and then a slightly bigger one. What do you want?", "choices": [
			{"text": "Learn the Boulder Toss (two days; Bending 5; 300 gold for broken roofs)", "next": "boulder", "if": {"no_tech": "e_boulder", "skill": ["bending", 5], "gold": 300}, "hint": "Bending 5 and 300 gold"},
			{"text": "Learn Stone Armour (three days; Bending 6)", "next": "armor", "if": {"no_tech": "e_armor", "skill": ["bending", 6]}, "hint": "needs Bending 6"},
			{"text": "\"Another time.\"", "next": ""},
		]},
		"boulder": {"who": "bo_ren", "expr": "happy", "text": "From the hips! The hips! Your arms are just there to look decorative. — THERE. Through the bakery. Wonderful. We'll pay for the bakery.",
			"do": [["gold", -300], ["wait", 48.0], ["learn", "e_boulder"]], "next": "hub"},
		"armor": {"who": "bo_ren", "expr": "smirk", "text": "Wear the mountain! Not like a hat! Like a hug! A very heavy hug!",
			"do": [["wait", 72.0], ["learn", "e_armor"]], "next": "hub"},
	}},
	"ex_bolai": {"title": "Bo Lai", "start": "a", "nodes": {
		"a": {"who": "bo_lai", "expr": "sad", "text": "You. Hana's friend. I testify every month, now, at the hearings. It is the least I can do, and I do it. — You want to learn what the Dai Li taught me. I understand. It is efficient. It is not innocent. I will teach it to you on one condition: you use it to hold people, never to bury them.", "choices": [
			{"text": "\"I promise.\" (Learn Stone Gloves and Stone Cuffs; four days)", "next": "learn", "if": {"no_tech": "e_gloves"}},
			{"text": "\"Not from you.\"", "next": "no"},
		]},
		"learn": {"who": "bo_lai", "expr": "neutral", "text": "Short. Quick. Close. The hand closes and the stone closes with it. — Good. Now forget how good that felt. That is the part they never taught us.",
			"do": [["wait", 96.0], ["learn", "e_gloves"], ["learn", "e_cuffs"], ["approval", "hana", 3]]},
		"no": {"who": "bo_lai", "expr": "sad", "text": "That is fair. More than fair."},
	}},
	"ex_academy": {"title": "The Dai Li Academy", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The academy sits under Lake Laogai, which you are told is a rumour, in rooms you are told do not exist. An instructor with no name teaches you for a week. Nobody asks what you will do with it. That is the lesson, if you are paying attention.", "choices": [
			{"text": "Learn Stone Gloves and Stone Cuffs (one week; 1,200 gold)", "next": "learn", "if": {"gold": 1200, "no_tech": "e_gloves"}, "hint": "need 1,200 gold"},
			{"text": "Leave.", "next": ""},
		]},
		"learn": {"who": "narrator", "text": "You leave knowing two new things with your hands and a third with your stomach.",
			"do": [["gold", -1200], ["wait", 168.0], ["learn", "e_gloves"], ["learn", "e_cuffs"], ["approval", "hana", -8], ["approval", "gao_ming", -5]]},
	}},

	# -----------------------------------------------------------------------
	# Old Shan and the Badgermole's Patience (mastery trial)
	# -----------------------------------------------------------------------
	"ex_shan": {"title": "Old Shan", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The cave is warm and smells of moss. An old man sits cross-legged in the dark with his palms flat on the floor, and does not look up. He speaks so quietly you have to kneel to hear.", "next": "hub"},
		"hub": {"who": "old_shan", "expr": "neutral", "text": "The first earthbenders learned from the badgermoles, who are blind and hear everything. Most people have forgotten. I have not. What do you want to remember?", "choices": [
			{"text": "Learn Seismic Sense (a week of listening; Bending 5)", "next": "seismic", "if": {"bend": "earth", "no_tech": "e_seismic", "skill": ["bending", 5]}, "hint": "earthbenders with Bending 5"},
			{"text": "Learn the Fissure (two days; Bending 4)", "next": "fissure", "if": {"bend": "earth", "no_tech": "e_fissure", "skill": ["bending", 4]}, "hint": "earthbenders with Bending 4"},
			{"text": "\"I'm ready for the Badgermole's Patience.\" (the mastery trial)", "next": "trial", "if": {"bend": "earth", "call": "not_master", "skill": ["bending", 7], "techs": ["earth", 3], "tech": "e_seismic", "duel_wins": 1}, "hint": "Bending 7, three earth techniques including Seismic Sense, and a duel won"},
			{"text": "\"Who are you?\"", "next": "who"},
			{"text": "\"I'll go.\"", "next": ""},
		]},
		"who": {"who": "old_shan", "expr": "smirk", "text": "A miner who stopped. I was very loud once. Then a mountain fell on me and I lay under it for two days, listening, and it turned out the mountain had been talking the whole time. I stayed to hear the rest.", "next": "hub"},
		"seismic": {"who": "old_shan", "expr": "thoughtful", "text": "Close your eyes. Bare feet. — No, you're listening with your ears. Stop that. Listen with your heels. There: a beetle, two paces left. A mouse, under the moss. Me. You. Everyone, always, all the time.",
			"do": [["wait", 168.0], ["learn", "e_seismic"]], "next": "hub"},
		"fissure": {"who": "old_shan", "expr": "neutral", "text": "Find the line the stone already wants to break along. Ask it. Don't tell it.",
			"do": [["wait", 48.0], ["learn", "e_fissure"]], "next": "hub"},
		"trial": {"who": "old_shan", "expr": "neutral", "text": "Sit. Three days. Don't bend. Don't speak. Don't leave. When you have heard the mountain say something, tell me what it said.", "next": "sit"},
		"sit": {"who": "narrator", "text": "Three days. Hunger, then boredom, then something under the boredom. On the third night you feel it through the floor: very far down, very slow, the mountain turning over in its sleep.",
			"do": [["wait", 72.0]], "choices": [
			{"text": "\"It said: 'I am in no hurry.'\"", "next": "pass"},
			{"text": "\"It said: 'Move me.'\"", "next": "fail"},
			{"text": "\"It didn't say anything. It just was.\"", "next": "pass"},
		]},
		"fail": {"who": "old_shan", "expr": "smirk", "text": "That was you talking. Very common. Sit again some other year.", "next": "hub"},
		"pass": {"who": "old_shan", "expr": "happy", "text": "Yes. That is the whole of earthbending: the patience to move something that is in no hurry. You can call yourself a master now. Try not to shout about it. The mountain will hear.",
			"do": [["master", "earth"], ["flag", "ex_master", true], ["renown", 40], ["journal", "ex_trial", "The Badgermole's Patience", "Old Shan named you a Master Earthbender after three days of listening to the mountain."], ["journal_done", "ex_trial"]]},
	}},

	# -----------------------------------------------------------------------
	# A cave-in (an earthbender in the party)
	# -----------------------------------------------------------------------
	"ex_cavein": {"title": "Cave-in", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "A boy on an ostrich horse catches you on the road, half falling off it. A copper mine in the hills behind him has come down with nine people inside. The village has shovels. It doesn't have an earthbender.", "choices": [
			{"text": "\"Show us.\"", "next": "go"},
			{"text": "\"We can't stop.\"", "next": "no"},
		]},
		"go": {"who": "narrator", "text": "It takes all night. Stone has to be held up before it can be moved, and moved before it can be held. At dawn the ninth miner comes out on a door used as a stretcher, cursing fluently, which the village takes as a very good sign.",
			"do": [["wait", 12.0], ["renown", 15], ["honor", 2], ["approval", "gao_ming", 8], ["approval", "hana", 5]]},
		"no": {"who": "narrator", "text": "The boy turns his bird around without a word. You hear, later, that they got six out with shovels.", "do": [["honor", -2], ["approval", "gao_ming", -10]]},
	}},
}
