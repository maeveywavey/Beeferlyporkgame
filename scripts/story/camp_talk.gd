extends RefCounted
## Conversations by the campfire: talking with companions one to one, banter
## between pairs of companions, romance, and rereading the Avatar's logbook.

const NPCS := {}
const SPAWNS := {}
const TRIGGERS := []
const OPTIONS := []

const DIALOGUES := {
	# -----------------------------------------------------------------------
	# One-to-one talks
	# -----------------------------------------------------------------------
	"talk_hana": {"title": "Hana", "start": "hub", "nodes": {
		"hub": {"who": "hana", "expr": "neutral", "text": "You want to talk. Is it a specific topic, or general? General is harder, but I'm practising.", "choices": [
			{"text": "\"Can I go over the plan for the next few days with you?\"", "next": "plan", "if": {"days_since": ["hana_plan", 5]}, "hint": "you did this recently", "do": [["approval", "hana", 3], ["flag_day", "hana_plan"]]},
			{"text": "\"Tell me about your map.\"", "next": "map"},
			{"text": "\"How do you handle the cities? All the noise?\"", "next": "noise"},
			{"text": "\"I think about you more than a commander should.\"", "next": "rom", "if": {"approval": ["hana", 50], "pronouns": ["she", "they"], "not_flag": "romance_hana"}, "hide": true},
			{"text": "\"Let's keep moving.\"", "next": ""},
		]},
		"plan": {"who": "hana", "expr": "happy", "text": "Yes. Please. Start with where we sleep tonight and work outward. — Thank you. Most people think plans are a cage. For me they're a floor. You can't dance without a floor.", "next": "hub"},
		"map": {"who": "hana", "expr": "happy", "text": "Every tunnel, cellar, cistern and fault line under Ba Sing Se. Eleven years. Three hundred and four sheets. When the city is too loud I unfold a sheet and the city becomes lines, and lines are quiet. Grandmother Zhu started it. I'm finishing it. That's the plan.", "next": "hub"},
		"noise": {"who": "hana", "expr": "thoughtful", "text": "Badly, sometimes. Crowds feel like being shouted at by the floor. If I ask to wait outside a town, it isn't rudeness — it's maintenance. You've never once asked me why. I noticed that.", "next": "hub"},
		"rom": {"who": "hana", "expr": "embarrassed", "text": "Oh. I had a whole plan for this conversation, and it was me saying it. You've ruined the plan. — I'm not upset. I'm recalculating.", "next": "rom2"},
		"rom2": {"who": "hana", "expr": "tender", "text": "I made you something. I was going to wait. It's a map — of the road we've travelled, every camp, with the dates. It's the only way I know how to say it. I'd like to keep adding to it. With you. If that's — yes?", "choices": [
			{"text": "\"Yes.\"", "next": "rom3", "do": [["flag", "romance_hana", true], ["approval", "hana", 10]]},
			{"text": "\"I care about you, but not like that.\"", "next": "rom_no"},
		]},
		"rom3": {"who": "hana", "expr": "happy", "text": "Good. Excellent. I'll need a bigger sheet.", "next": "hub"},
		"rom_no": {"who": "hana", "expr": "neutral", "text": "Understood. Thank you for being clear. Clear is the kindest thing. I'll still finish the map. It's a good map.", "next": "hub"},
	}},
	"talk_juro": {"title": "Juro", "start": "hub", "nodes": {
		"hub": {"who": "juro", "expr": "smirk", "text": "Commander. I was just redesigning your supply carts in my head. They're terrible. Don't take it personally. What's on your mind?", "choices": [
			{"text": "\"Tell me about your father.\"", "next": "father"},
			{"text": "\"What was it like, growing up in the Fire Nation?\"", "next": "growing"},
			{"text": "\"How are you, really?\"", "next": "really"},
			{"text": "\"You make everything you touch work better. Including me.\"", "next": "rom", "if": {"approval": ["juro", 50], "not_flag": "romance_juro"}, "hide": true},
			{"text": "\"Let's keep moving.\"", "next": ""},
		]},
		"rom": {"who": "juro", "expr": "embarrassed", "text": "That's — I'm going to need a moment. I had a whole engineering metaphor ready for if this ever happened and now it's all load-bearing walls and I can't remember the point.", "next": "rom1"},
		"rom1": {"who": "juro", "expr": "tender", "text": "The point is: I'd like that. Very much. I'll warn you, I write terrible letters. My father will write you separately to apologise for them.", "choices": [
			{"text": "\"Then write me terrible letters.\"", "next": "rom2", "do": [["flag", "romance_juro", true], ["approval", "juro", 10]]},
			{"text": "\"I meant it as a friend, Juro.\"", "next": "rom_no"},
		]},
		"rom2": {"who": "juro", "expr": "happy", "text": "'Dear {name}. The plum tree has fruited.' That's the whole letter. You'll understand later.", "next": "hub"},
		"rom_no": {"who": "juro", "expr": "smirk", "text": "Of course. Good. Excellent. I'll go and redesign a cart for an hour. Not because of this. Unrelated cart.", "next": "hub"},
		"father": {"who": "juro", "expr": "tender", "text": "A potter. Hands like shovels. When I told him I was his son, not his daughter, he went quiet for a whole day, and then he came back with a set of carving tools and said, 'A son should have his own.' That was it. That was the whole conversation. He writes every week about the plum tree.", "next": "hub"},
		"growing": {"who": "juro", "expr": "thoughtful", "text": "Hungry, the last few years. Three bad harvests. You stand in a ration line and someone in a nice uniform tells you the Ember Coast will fix it, and you want so badly to believe them. That's how a war gets built. I should know. I drew the parts.", "next": "hub"},
		"really": {"who": "juro", "expr": "neutral", "text": "Better than I was. Building things helps. Being useful helps. You asking helps, which is embarrassing, so please forget I said it.", "next": "hub"},
	}},
	"talk_pemba": {"title": "Pemba", "start": "hub", "nodes": {
		"hub": {"who": "pemba", "expr": "neutral", "text": "I'm meditating. Badly. Please interrupt me; I was about to start thinking about lunch anyway.", "choices": [
			{"text": "\"What's it like at the Southern Temple?\"", "next": "temple"},
			{"text": "\"How did you know you were neither a monk nor a nun?\"", "next": "nb"},
			{"text": "\"Do you ever want to fight back?\"", "next": "fight"},
			{"text": "\"Let's keep moving.\"", "next": ""},
		]},
		"temple": {"who": "pemba", "expr": "happy", "text": "Cold. Loud. Two hundred bison who all think they're the favourite. The novices race the calves off the terraces and I'm supposed to stop them, and I don't. Abbot Dorje pretends not to notice that I don't. It's a good place to be from.", "next": "hub"},
		"nb": {"who": "pemba", "expr": "thoughtful", "text": "I didn't know. I asked. The elders said, 'Where are you useful and at peace?' I said, 'With the bison.' They said, 'Then that's where you live.' Nobody made it a question I had to answer for them. I've since learned that's rare. I'm still a little angry on behalf of everyone else.", "next": "hub"},
		"fight": {"who": "pemba", "expr": "neutral", "text": "Every day. Violence is always a choice. So is lunch. I've chosen lunch. — That's a joke, mostly. I knock people over. I just don't want to be the reason someone's mother gets a letter.", "next": "hub"},
	}},
	"talk_nima": {"title": "Nima", "start": "hub", "nodes": {
		"hub": {"who": "nima", "expr": "neutral", "text": "If you've come to tell me to rest, I'm resting. This is resting. I'm mending your soldiers' boots, which is resting for me.", "choices": [
			{"text": "\"Tell me how you learned the combat forms.\"", "next": "forms"},
			{"text": "\"Do you miss Kaya?\"", "next": "kaya"},
			{"text": "\"Let's keep moving.\"", "next": ""},
		]},
		"forms": {"who": "nima", "expr": "smirk", "text": "From the healing hut windows. Twelve years of watching young men get it wrong and fixing their bruises afterwards. You learn a lot about a stance from the bruise it leaves. Then, at night, on the ice, I tried. Badly for a year. Then less badly.", "next": "hub"},
		"kaya": {"who": "nima", "expr": "sad", "text": "Every hour. I write her a letter every three days, and every one has a drawing of a seal in it, because she demanded it. My seals are getting very good. Don't tell anyone; they'll ask for portraits.", "next": "hub"},
	}},
	"talk_ukiuk": {"title": "Ukiuk", "start": "hub", "nodes": {
		"hub": {"who": "ukiuk", "expr": "happy", "text": "Hey! Hi. I was just — I started three things and finished none of them, which is a personal best actually. What's up?", "choices": [
			{"text": "\"What are you building?\"", "next": "build"},
			{"text": "\"How do you stay so cheerful?\"", "next": "cheer"},
			{"text": "\"You're very easy to be around, Ukiuk.\"", "next": "rom", "if": {"approval": ["ukiuk", 50], "not_flag": "romance_ukiuk"}, "hide": true},
			{"text": "\"Let's keep moving.\"", "next": ""},
		]},
		"build": {"who": "ukiuk", "expr": "smirk", "text": "A collapsible canoe. Also a better boomerang. Also a shelf, for Hana, she doesn't know yet. Also I took apart your lantern to see how it works, I'll put it back, probably. My brain is a harbour with no harbourmaster. Things just — come in.", "next": "hub"},
		"cheer": {"who": "ukiuk", "expr": "thoughtful", "text": "I'm not, always. But if I stop moving, I start thinking, and if I start thinking it's about one boat on one night. So I build things. It's not a fix. It's a raft. Rafts are good. Nobody laughs at a raft when they're drowning.", "next": "hub"},
		"rom": {"who": "ukiuk", "expr": "embarrassed", "text": "Oh! Oh. Okay. Hi. Sorry, my face is doing a thing. I've been building you a — no, I'll show you. It's a boat. A tiny one. With your name on the side. That's how my people — that's how I — would you —", "choices": [
			{"text": "\"Yes, Ukiuk.\"", "next": "rom2", "do": [["flag", "romance_ukiuk", true], ["approval", "ukiuk", 10]]},
			{"text": "\"I'm flattered, but no.\"", "next": "rom_no"},
		]},
		"rom2": {"who": "ukiuk", "expr": "laugh", "text": "YES. Okay. Great. I'm going to go stand in the sea for a minute. Happily. It's a happy sea-standing.", "next": "hub"},
		"rom_no": {"who": "ukiuk", "expr": "tender", "text": "That's okay! Really. Keep the boat anyway. It's a good boat. It floats, which is more than my last three.", "next": "hub"},
	}},
	"talk_shen_mu": {"title": "Shen Mu", "start": "hub", "nodes": {
		"hub": {"who": "shen_mu", "expr": "neutral", "text": "Oh — hello. I was memorising the road names around here. In case. Did you need something?", "choices": [
			{"text": "\"How did you become a courier?\"", "next": "courier"},
			{"text": "\"Does it bother you, when people rush you while you talk?\"", "next": "stutter"},
			{"text": "\"Let me read the letter. Just once.\"", "next": "read", "if": {"flag": "shenmu_q", "not_flag": "shenmu_done"}, "hide": true},
			{"text": "\"Let's keep moving.\"", "next": ""},
		]},
		"courier": {"who": "shen_mu", "expr": "happy", "text": "Reading's slow for me — the letters swim. Teachers said I'd n-never be a clerk. Fine. But I remember everything I hear, and I can run. Captain Doru gave me a route when I was twelve. I've never lost a letter. Not one.", "next": "hub"},
		"stutter": {"who": "shen_mu", "expr": "thoughtful", "text": "Yes. When people finish my words for me, it's like someone taking the letter out of my hand to deliver it themselves. I'll get there. I always get there. You wait. I noticed that you wait.", "do": [["approval", "shen_mu", 2]], "next": "hub"},
		"read": {"who": "shen_mu", "expr": "angry", "text": "No. A letter is a promise. You don't open someone's promise. If you take it from me while I'm asleep, I'll know. I'll always know.", "choices": [
			{"text": "\"You're right. I'm sorry I asked.\"", "next": "hub", "do": [["approval", "shen_mu", 3]]},
			{"text": "(That night, read it while he sleeps.)", "next": "readit"},
		]},
		"readit": {"who": "narrator", "text": "The seal lifts cleanly with a hot knife. Princess Ryoko offers to withdraw from two Ember Coast ports in exchange for Omashu's grain, and to recognise Omashu as a kingdom. You reseal it. In the morning Shen Mu looks at the wax for a long time, and then at you, and says nothing at all.",
			"do": [["flag", "letter_read", true], ["approval", "shen_mu", -25]]},
	}},
	"talk_reika": {"title": "Reika", "start": "hub", "nodes": {
		"hub": {"who": "reika", "expr": "smirk", "text": "Commander. Come to admire the hat? Everyone does eventually.", "choices": [
			{"text": "\"Tell me about Rin.\"", "next": "rin"},
			{"text": "\"Why privateering?\"", "next": "why"},
			{"text": "\"I'd follow that hat anywhere.\"", "next": "rom", "if": {"approval": ["reika", 50], "pronouns": ["she", "they"], "not_flag": "romance_reika"}, "hide": true},
			{"text": "\"Let's keep moving.\"", "next": ""},
		]},
		"rin": {"who": "reika", "expr": "sad", "text": "Shiyo's daughter. We had a ship together, once. Two captains, one deck — terrible idea, best year of my life. She wanted to stay pirates. I wanted a letter of marque and a pension. Turns out I wanted the wrong thing. Don't tell her. Actually, do. She'd love it.", "next": "hub"},
		"why": {"who": "reika", "expr": "neutral", "text": "My family had a ship and a debt. The Navy offered to pay the debt if I sank their enemies. It seemed simple. Most terrible things seem simple from the deck.", "next": "hub"},
		"rom": {"who": "reika", "expr": "surprised", "text": "Anywhere? That's a dangerous promise to make a pirate. — No, don't take it back. I'm keeping it. In the hat.", "choices": [
			{"text": "\"Keep it.\"", "next": "rom2", "do": [["flag", "romance_reika", true], ["approval", "reika", 10]]},
			{"text": "\"I meant as your commander.\"", "next": "rom_no"},
		]},
		"rom2": {"who": "reika", "expr": "tender", "text": "Well. That's me ruined for piracy. Come here.", "next": "hub"},
		"rom_no": {"who": "reika", "expr": "smirk", "text": "Of course you did. Pity. The hat's disappointed. I'm fine.", "next": "hub"},
	}},
	"talk_kesi": {"title": "Kesi", "start": "hub", "nodes": {
		"hub": {"who": "kesi", "expr": "neutral", "text": "(signing) You want to talk? Face me. Slower. Good.", "choices": [
			{"text": "\"Teach me more storm-sign.\"", "next": "sign", "do": [["flag", "learned_sign", true]]},
			{"text": "\"What do you feel through the sand?\"", "next": "feel"},
			{"text": "(sign, slowly) \"You. I want you. Near.\"", "next": "rom", "if": {"approval": ["kesi", 50], "flag": "learned_sign", "not_flag": "romance_kesi"}, "hint": "learn more storm-sign from Kesi first", "hide": true},
			{"text": "\"Let's keep moving.\"", "next": ""},
		]},
		"rom": {"who": "kesi", "expr": "surprised", "text": "(signing) You learned that? From who? — No. Don't tell me. Hana. It's very precise. Too precise.", "next": "rom1"},
		"rom1": {"who": "kesi", "expr": "tender", "text": "(signing, very slowly, so you can read every shape) Yes. Near. Stay near. In storms, you hold a hand so you don't lose each other. That's the whole sign for it.", "choices": [
			{"text": "Take her hand.", "next": "rom2", "do": [["flag", "romance_kesi", true], ["approval", "kesi", 10]]},
			{"text": "(sign) \"Friend. Near as a friend.\"", "next": "rom_no"},
		]},
		"rom2": {"who": "kesi", "expr": "happy", "text": "(signing one-handed, grinning) Now you have to learn to sign with one hand. Good luck.", "next": "hub"},
		"rom_no": {"who": "kesi", "expr": "smirk", "text": "(signing) Friend near. Also good. Still teaching you 'enemy is stupid'.", "next": "hub"},
		"sign": {"who": "kesi", "expr": "smirk", "text": "(signing, slowly) This is 'water'. This is 'enemy'. This is 'enemy is stupid'. That last one you will use often. — Good. Your hands are clumsy. Clumsy is fine. Clumsy still talks.", "next": "hub"},
		"feel": {"who": "kesi", "expr": "thoughtful", "text": "(signing) Everything. Horses, two dunes away. Your heartbeat when you lie. Hana's footsteps — she counts them, very even. The sand is never quiet. People think Deaf means quiet. It's the loudest thing I know.", "next": "hub"},
	}},

	# -----------------------------------------------------------------------
	# Banter between companions (written in the writers' room)
	# -----------------------------------------------------------------------
	"banter_hana_ukiuk": {"title": "By the Fire", "start": "a", "nodes": {
		"a": {"who": "ukiuk", "expr": "happy", "text": "I made you a rock shelf! For your rocks!", "next": "b"},
		"b": {"who": "hana", "expr": "neutral", "text": "These are survey samples.", "next": "c"},
		"c": {"who": "ukiuk", "expr": "happy", "text": "For your survey samples!", "next": "d"},
		"d": {"who": "hana", "expr": "surprised", "text": "…It's level. You used a level.", "next": "e"},
		"e": {"who": "ukiuk", "expr": "smirk", "text": "I used my eyes.", "next": "f"},
		"f": {"who": "hana", "expr": "happy", "text": "It's level by accident. I'm keeping it."},
	}},
	"banter_juro_reika": {"title": "By the Fire", "start": "a", "nodes": {
		"a": {"who": "reika", "expr": "smirk", "text": "You were in the artillery corps. You must have hated sailors.", "next": "b"},
		"b": {"who": "juro", "expr": "neutral", "text": "I designed things that set ships on fire. It wasn't personal.", "next": "c"},
		"c": {"who": "reika", "expr": "neutral", "text": "It's always personal when it's your ship.", "next": "d"},
		"d": {"who": "juro", "expr": "thoughtful", "text": "…Yes. I'm learning that."},
	}},
	"banter_kesi_pemba": {"title": "By the Fire", "start": "a", "nodes": {
		"a": {"who": "pemba", "expr": "thoughtful", "text": "(signing slowly) I have learned 'food', 'bison' and 'where'.", "next": "b"},
		"b": {"who": "kesi", "expr": "smirk", "text": "(signing) That's most of life.", "next": "c"},
		"c": {"who": "pemba", "expr": "happy", "text": "(signing) 'Where food?' 'Bison where?'", "next": "d"},
		"d": {"who": "kesi", "expr": "laugh", "text": "(laughing, signing) You're fluent."},
	}},
	"banter_nima_shen_mu": {"title": "By the Fire", "start": "a", "nodes": {
		"a": {"who": "shen_mu", "expr": "embarrassed", "text": "D-do you think he likes me? Lin. Not — hypothetically.", "next": "b"},
		"b": {"who": "nima", "expr": "smirk", "text": "I think a boy who walks four miles out of his route to deliver your mail personally is not doing it for the exercise.", "next": "c"},
		"c": {"who": "shen_mu", "expr": "afraid", "text": "…Oh no.", "next": "d"},
		"d": {"who": "nima", "expr": "laugh", "text": "Oh yes."},
	}},
	"banter_hana_pemba": {"title": "By the Fire", "start": "a", "nodes": {
		"a": {"who": "pemba", "expr": "neutral", "text": "Hana, may I sit here?", "next": "b"},
		"b": {"who": "hana", "expr": "neutral", "text": "Yes. Thank you for asking. Most people just sit.", "next": "c"},
		"c": {"who": "pemba", "expr": "smirk", "text": "At the temple, if you just sit, you might sit on a novice. We learn to ask early.", "next": "d"},
		"d": {"who": "hana", "expr": "happy", "text": "I would like to live at your temple. Only for the asking. Not the bison. The bison are too surprising."},
	}},
	"banter_juro_nima": {"title": "By the Fire", "start": "a", "nodes": {
		"a": {"who": "nima", "expr": "neutral", "text": "Your hands. The burn on the left one never healed properly. Let me see.", "next": "b"},
		"b": {"who": "juro", "expr": "embarrassed", "text": "It's fine. It's old. It's a reminder.", "next": "c"},
		"c": {"who": "nima", "expr": "smirk", "text": "You can keep the reminder and still be able to make a fist. Hold still. I've healed worse on seven-year-olds, and they bite.", "next": "d"},
		"d": {"who": "juro", "expr": "tender", "text": "…Thank you. Please don't tell my father a Water Tribe healer is nicer to me than our doctors were. He'd move north."},
	}},
	"banter_reika_ukiuk": {"title": "By the Fire", "start": "a", "nodes": {
		"a": {"who": "ukiuk", "expr": "thoughtful", "text": "So when you were a privateer, did you ever fight Southern raiders?", "next": "b"},
		"b": {"who": "reika", "expr": "neutral", "text": "Twice. You lot are insane. You attacked a frigate in a canoe.", "next": "c"},
		"c": {"who": "ukiuk", "expr": "embarrassed", "text": "…Was it a frigate with a crooked foremast and a captain in a very big hat?", "next": "d"},
		"d": {"who": "reika", "expr": "surprised", "text": "You put a harpoon through my hat.", "next": "e"},
		"e": {"who": "ukiuk", "expr": "laugh", "text": "I was AIMING for the hat! As a warning! It was a great hat!", "next": "f"},
		"f": {"who": "reika", "expr": "smirk", "text": "It was a great hat. You're buying me a new one."},
	}},
	"banter_kesi_shen_mu": {"title": "By the Fire", "start": "a", "nodes": {
		"a": {"who": "shen_mu", "expr": "neutral", "text": "Kesi — how do you say 'letter'?", "next": "b"},
		"b": {"who": "kesi", "expr": "thoughtful", "text": "(signing) Like this. Folding, then giving.", "next": "c"},
		"c": {"who": "shen_mu", "expr": "happy", "text": "Folding, then giving. That's — that's exactly right. That's what it is.", "next": "d"},
		"d": {"who": "kesi", "expr": "smirk", "text": "(signing) You don't stutter in sign.", "next": "e"},
		"e": {"who": "shen_mu", "expr": "surprised", "text": "…I don't. Huh. I'm going to need you to teach me everything."},
	}},
	"banter_fire_alone": {"title": "By the Fire", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The fire burns down. Somebody is mending a strap; somebody is asleep sitting up. Nobody says anything important, which is its own kind of important."},
	}},

	# -----------------------------------------------------------------------
	# The logbook
	# -----------------------------------------------------------------------
	"ms_logbook": {"title": "The Avatar's Logbook", "start": "hub", "nodes": {
		"hub": {"who": "narrator", "text": "The pages you have recovered are wrapped in Brother Norbu's oilcloth. The handwriting gets smaller toward the end, as if the writer were running out of room, or time.", "choices": [
			{"text": "Read Page I.", "next": "", "if": {"has_page": 1}, "hide": true, "goto": "page_1"},
			{"text": "Read Page II.", "next": "", "if": {"has_page": 2}, "hide": true, "goto": "page_2"},
			{"text": "Read Page III.", "next": "", "if": {"has_page": 3}, "hide": true, "goto": "page_3"},
			{"text": "Read Page IV.", "next": "", "if": {"has_page": 4}, "hide": true, "goto": "page_4"},
			{"text": "Read Page V.", "next": "", "if": {"has_page": 5}, "hide": true, "goto": "page_5"},
			{"text": "Read Page VI.", "next": "", "if": {"has_page": 6}, "hide": true, "goto": "page_6"},
			{"text": "Decide what the truth is for.", "next": "", "if": {"flag": "ms_truth", "not_flag": "ms_ended", "eq": ["ms_path", ""]}, "hide": true, "goto": "ms_decide"},
			{"text": "Put it away.", "next": ""},
		]},
	}},
}
