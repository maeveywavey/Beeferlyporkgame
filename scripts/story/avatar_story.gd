extends RefCounted
## The Avatar's scenes (scripts/core/avatar.gd decides when they happen).
## Speakers "avatar" and "av_loved" are resolved per era by Story.npc().
## Lines that differ by the Avatar's age branch through hidden choices on the
## av_young / av_prime / av_elder conditions.

const NPCS := {}

const SPAWNS := {
	"avatar_company": {"name": "The Avatar's Company", "faction": "avatar", "troops": [["avatar", 1]], "gold": 0,
		"on_defeat": [["call", "avatar_defeated"]]},
}

const TRIGGERS := []
const OPTIONS := []

const DIALOGUES := {
	# -----------------------------------------------------------------------
	# Finding the Avatar (offered from a settlement menu while they are there)
	# -----------------------------------------------------------------------
	"av_audience": {"title": "The Avatar", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "You are let into a small courtyard where {avatar} is sitting on the edge of a fountain, eating a pear, with three people waiting to speak to {av_them} and a fourth asleep against the wall.", "choices": [
			{"text": "Wait to be noticed.", "next": "y", "if": {"call": "av_young"}, "hide": true},
			{"text": "Wait to be noticed.", "next": "p", "if": {"call": "av_prime"}, "hide": true},
			{"text": "Wait to be noticed.", "next": "e", "if": {"call": "av_elder"}, "hide": true},
		]},
		"y": {"who": "avatar", "expr": "surprised", "text": "You found me? Nobody finds me. My teachers have been looking for two days. They're going to be furious. — Hi. Sorry. Hello. Is this an official thing? Do I need to stand up?", "next": "hub"},
		"p": {"who": "avatar", "expr": "smirk", "text": "{name}, isn't it? People talk about you. Some of it's even flattering. Sit. I have until this pear is finished, and then I'm due somewhere I've already forgotten the name of.", "next": "hub"},
		"e": {"who": "avatar", "expr": "thoughtful", "text": "A visitor. Sit where the sun is. I was meditating, which at my age looks exactly like napping. Nobody can tell the difference, including me.", "next": "hub"},
		"hub": {"who": "avatar", "expr": "neutral", "text": "What can I do for you?", "choices": [
			{"text": "\"What is it like, being the Avatar?\"", "next": "like_y", "if": {"call": "av_young"}, "hide": true},
			{"text": "\"What is it like, being the Avatar?\"", "next": "like_p", "if": {"call": "av_prime"}, "hide": true},
			{"text": "\"What is it like, being the Avatar?\"", "next": "like_e", "if": {"call": "av_elder"}, "hide": true},
			{"text": "\"Where do you go, when no one can find you?\"", "next": "where"},
			{"text": "\"What do you make of me?\"", "next": "me_good", "if": {"call": "av_friend"}, "hide": true},
			{"text": "\"What do you make of me?\"", "next": "me_bad", "if": {"call": "av_not_friend"}, "hide": true},
			{"text": "\"Will you help me make peace?\"", "next": "peace", "if": {"call": "av_friend", "days_since": ["av_peace_asked", 120]}, "hint": "the Avatar must trust you, and not have helped recently"},
			{"text": "\"Do you remember your past lives?\"", "next": "past"},
			{"text": "\"I'll let you get back to it.\"", "next": "bye"},
		]},
		"like_y": {"who": "avatar", "expr": "embarrassed", "text": "Like being handed a boat the size of a city and told to sail it while everyone shouts directions. Also the boat is on fire. Also I get seasick. Everyone thinks the Avatar is calm. I've been calm twice. Both times I was asleep.", "next": "hub"},
		"like_p": {"who": "avatar", "expr": "thoughtful", "text": "Like being everyone's last resort. People wait for me instead of acting, and then they're angry I took so long. I don't blame them. I'd rather be blamed for being late than thanked for being the only one who came.", "next": "hub"},
		"like_e": {"who": "avatar", "expr": "smirk", "text": "Like being a very old tree that everyone has carved their initials into. I don't mind the initials. I mind when they forget that trees were here first, and will be after.", "next": "hub"},
		"where": {"who": "avatar", "expr": "thoughtful", "text": "Wherever nobody is looking. A forest whose spirit is angry about a dam three hundred years old. A temple where I can sit still for a week. A teacher's kitchen. My family, when I can. Somebody has to listen to the places nobody else listens to, and they are rarely near a road.", "next": "hub"},
		"me_good": {"who": "avatar", "expr": "happy", "text": "That you're someone people could follow without being ashamed of it. Don't let it go to your head. Power makes everybody stupid eventually. I'm counting on you to take longer than most.", "next": "hub"},
		"me_bad": {"who": "avatar", "expr": "neutral", "text": "I don't know yet. That's not a polite way of saying I don't like you. It's a polite way of saying I'm watching. I watch everyone. You're just closer than most.", "next": "hub"},
		"peace": {"who": "avatar", "expr": "determined", "text": "I'll talk to them. Not because you asked; because it's my job. But I'll remember that you asked, and that you didn't ask me to win your war for you.",
			"do": [["flag_day", "av_peace_asked"], ["call", "avatar_peace"], ["av_attitude", 5]], "next": "hub"},
		"past": {"who": "avatar", "expr": "thoughtful", "text": "Not like memories. Like the smell of a house you lived in as a baby. Sometimes I know a road I've never walked. Sometimes I'm angry at a person who's been dead for a century. I try not to take it out on their grandchildren.", "next": "hub"},
		"bye": {"who": "avatar", "expr": "happy", "text": "Go well. And if you need me, don't wait for me. I'm very bad at being found.", "do": [["av_attitude", 3]]},
	}},

	# -----------------------------------------------------------------------
	# Ruler: the Avatar comes to court
	# -----------------------------------------------------------------------
	"av_court": {"title": "The Avatar Comes to Court", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "{avatar} arrives without an escort, which is either humility or a statement about how little an escort would matter. Your guards bow before they have decided to.", "choices": [
			{"text": "Receive them.", "next": "y", "if": {"call": "av_young"}, "hide": true},
			{"text": "Receive them.", "next": "p", "if": {"call": "av_prime"}, "hide": true},
			{"text": "Receive them.", "next": "e", "if": {"call": "av_elder"}, "hide": true},
		]},
		"y": {"who": "avatar", "expr": "embarrassed", "text": "Okay. I'm supposed to say something formal. My teachers wrote it down. I lost it on the boat. — You're the {title}, and I'm the Avatar, and apparently that means we should talk before things go wrong instead of after. So. Talking.", "next": "b"},
		"p": {"who": "avatar", "expr": "neutral", "text": "{title}. I came as soon as I could, which in my life is slower than I'd like. I'm not here to tell you how to rule. I'm here to ask what you need from me, and to tell you what the world needs from you.", "next": "b"},
		"e": {"who": "avatar", "expr": "smirk", "text": "Sit, please; my knees have opinions. I have outlived two Fire Lords, three Chiefs and an Earth King who tried to have me arrested. You are new. New is the most dangerous thing a ruler can be, and the most hopeful.", "next": "b"},
		"b": {"who": "avatar", "expr": "thoughtful", "text": "Whatever you hold, people will eat or starve by it. I'd like us to work together. So tell me: what does working together look like to you?", "choices": [
			{"text": "\"Open roads and granaries to anyone fleeing a war. You'll have my help with the rest.\"", "next": "ally"},
			{"text": "\"Help me make peace with my enemies.\"", "next": "peace", "if": {"call": "av_wars"}, "hint": "you must be at war with someone"},
			{"text": "\"You stay out of my wars, and I'll stay out of your spirits.\"", "next": "cool"},
		]},
		"ally": {"who": "avatar", "expr": "happy", "text": "Then I'll make sure everyone knows the {title} said it first. It costs you grain. It buys you the one thing grain can't: people who'd rather you stayed.",
			"do": [["av_attitude", 30], ["flag", "av_accord", true], ["honor", 3], ["rel", "air_nomads", 10], ["rel", "earth_kingdom", 5], ["rel", "fire_nation", 5], ["rel", "northern_water", 5], ["rel", "southern_water", 5], ["rel", "omashu", 5]], "next": "end"},
		"peace": {"who": "avatar", "expr": "determined", "text": "That I can do. Not because you asked, but because it's my job. But I'll remember that you asked.",
			"do": [["av_attitude", 15], ["call", "avatar_peace"], ["flag_day", "av_peace_asked"]], "next": "end"},
		"cool": {"who": "avatar", "expr": "neutral", "text": "I can't promise that, and I'd rather not lie to you on our first day. Here's what I can promise: I'll come to you before I go around you.",
			"do": [["av_attitude", -5], ["flag", "av_cool", true]], "next": "end"},
		"end": {"who": "narrator", "text": "{avatar} stays for dinner, eats far too much, and is gone before breakfast. The cook swears {av_they} washed {av_their} own bowl.",
			"do": [["journal", "av_main", "The Avatar", "{avatar} came to your court as you became {title}. You can seek {av_them} out when rumours place {av_them} nearby (The Avatar window, from the Nations screen, shows where {av_they} was last seen)."]]},
	}},

	# -----------------------------------------------------------------------
	# Tyrant: a warning, then a reckoning
	# -----------------------------------------------------------------------
	"av_warning": {"title": "A Visitor Before Dawn", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "You wake before dawn because the wind has stopped. {avatar} is sitting by your cold fire. None of your sentries saw {av_them} arrive. Several of your sentries are asleep, gently, under blankets that aren't theirs.", "choices": [
			{"text": "Sit up.", "next": "y", "if": {"call": "av_young"}, "hide": true},
			{"text": "Sit up.", "next": "p", "if": {"call": "av_prime"}, "hide": true},
			{"text": "Sit up.", "next": "e", "if": {"call": "av_elder"}, "hide": true},
		]},
		"y": {"who": "avatar", "expr": "angry", "text": "Everyone keeps telling me about you. The villages. The fields. I came to see if you were a monster. You're not. That's worse. Monsters can't stop.", "next": "b"},
		"p": {"who": "avatar", "expr": "sad", "text": "I spent two weeks walking the roads you've walked. I counted chimneys with no smoke. I'm not here to fight. I'm here so that you can never say nobody asked you to stop.", "next": "b"},
		"e": {"who": "avatar", "expr": "neutral", "text": "I am too old to chase you, so I came to you instead. You will notice that is not the same as being too old to stop you.", "next": "b"},
		"b": {"who": "avatar", "expr": "determined", "text": "Stop. Pay back what you can. Do that, and I'll stand between you and everyone who wants your head, and there are a great many. Don't, and I'll come back, and I won't come alone.", "choices": [
			{"text": "\"I'll stop. You have my word.\"", "next": "pledge"},
			{"text": "\"Who are you to judge me?\"", "next": "who"},
			{"text": "\"Get out of my camp.\"", "next": "defy"},
		]},
		"who": {"who": "avatar", "expr": "thoughtful", "text": "Nobody, on my own. But I'm also everyone who came before me, and they've all seen how this ends. That isn't an answer, I know. It's the only one I have. — So?", "choices": [
			{"text": "\"…I'll stop.\"", "next": "pledge"},
			{"text": "\"Get out.\"", "next": "defy"},
		]},
		"pledge": {"who": "avatar", "expr": "neutral", "text": "Words are cheap. I've been given a great many of them. I'll be watching how you spend this one.",
			"do": [["call", "avatar_pledge"], ["av_attitude", 10], ["journal", "av_main", "The Avatar", "You gave {avatar} your word to stop. Your infamy now fades faster. If it rises again, {av_they} will come back, and not alone."]]},
		"defy": {"who": "avatar", "expr": "sad", "text": "As you like. You'll see me again. Neither of us will enjoy it.",
			"do": [["call", "avatar_defy"], ["av_attitude", -20], ["journal", "av_main", "The Avatar", "You sent {avatar} away. {av_they} will return with allies. The Avatar window (Nations screen) lists what you can do to prepare, if preparing is what you choose."]]},
	}},
	"av_gathering": {"title": "They Are Coming", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "A monk at a waystation presses a folded paper into your hand and hurries off without looking back. It says only: 'They are coming. Make your peace or make your preparations.' Under it someone has drawn a very small, very bad sky bison.",
			"do": [["journal", "av_main", "The Avatar", "{avatar} is gathering allies against you. Open the Avatar window from the Nations screen to fortify your seat, deny the ground and hang nets, hire chi-blockers, or stage a diversion. Or send word that you yield."]]},
	}},
	"av_confront": {"title": "The Avatar", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "{avatar} is waiting with a few dozen people at {av_their} back: monks, Tide Wardens, farmers with spears, an old woman holding a frying pan like a mace. Nobody moves.", "choices": [
			{"text": "Meet them at your gates.", "next": "gates", "if": {"call": "av_seat"}, "hide": true},
			{"text": "Ride out to meet them.", "next": "b", "if": {"call": "av_no_seat"}, "hide": true},
		]},
		"gates": {"who": "narrator", "text": "They have come to your walls. Your garrison lines the ramparts. Whatever you prepared here, you are about to find out what it was worth.", "next": "b"},
		"b": {"who": "avatar", "expr": "determined", "text": "I asked. You said no. I'm sorry it came to this; I mean that. Lay down your arms, give back what you took, and nobody has to be hurt today.", "choices": [
			{"text": "\"Then come and take it.\" (Fight the Avatar)", "next": "fight"},
			{"text": "\"I have {loved}. Take one more step and you will never see them again.\"", "next": "hostage", "if": {"call": "av_hostage"}, "hide": true},
			{"text": "\"…I yield.\"", "next": "yield"},
		]},
		"fight": {"who": "avatar", "expr": "sad", "text": "All right.", "do": [["call", "avatar_battle"]]},
		"hostage": {"who": "avatar", "expr": "grief", "text": "…You'd do that. Of course you would. — Fine. We're leaving. But understand what you've done, {name}. You've made sure I will never, ever stop.",
			"do": [["call", "avatar_hostage"], ["av_attitude", -40], ["approval", "pemba", -40], ["approval", "nima", -25], ["approval", "hana", -20], ["approval", "juro", -20], ["approval", "kesi", -20], ["approval", "shen_mu", -20], ["approval", "ukiuk", -15], ["approval", "reika", -5]]},
		"yield": {"who": "avatar", "expr": "tender", "text": "Thank you. That was the hardest thing you've done all year, and the bravest. Come on. Let's go and give it back.",
			"do": [["call", "avatar_yield"], ["av_attitude", 20]], "next": "yield2"},
		"yield2": {"who": "narrator", "text": "It takes a month. Village by village, you return what you took, with {avatar} standing beside you so that nobody throws anything heavier than vegetables. Most of them throw vegetables.",
			"do": [["wait", 72.0], ["journal", "av_main", "The Avatar", "You yielded to {avatar}. Your fiefs were returned to the people you took them from, and your infamy is forgiven, if not forgotten."]]},
	}},
	"av_withdraws": {"title": "The Avatar Falls", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "{avatar} goes down on one knee in the mud. For a moment the light in {av_their} eyes flickers, as if someone a long way off were deciding something. Then {av_their} companions are around {av_them}, a sky bison drops out of the cloud, and they are gone.", "next": "b"},
		"b": {"who": "narrator", "text": "You won. By nightfall every capital on the map has heard, and none of them are pleased. The Avatar will heal. The Avatar always comes back.",
			"do": [["journal", "av_main", "The Avatar", "You defeated {avatar} in battle. The kingdoms fear you now. {av_they} has withdrawn to heal, and will return stronger, with more allies."]]},
	}},
	"av_judgement": {"title": "The Avatar's Judgement", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "You wake in a cell cut from clean stone. {avatar} is sitting outside it on an upturned bucket, looking more tired than you have ever seen anyone look.", "next": "b"},
		"b": {"who": "avatar", "expr": "sad", "text": "I'm not going to kill you. I don't do that. I'm going to give back everything you took, and then I'm going to let you go, and you're going to have to live as someone who lost. People manage it every day. The people you took it from managed it.", "next": "c"},
		"c": {"who": "narrator", "text": "Three days later the door is opened by a novice who will not look at you. Your fiefs have been returned to the nations and villages that held them. Your prisoners are free. Half your treasury is with the villages you burned. Your name, for now, is clean, because the Avatar has decided to treat it that way.",
			"do": [["journal", "av_main", "The Avatar", "{avatar} defeated you and took apart what you had built. Your infamy is wiped clean. {av_they} will be watching."]]},
	}},

	# -----------------------------------------------------------------------
	# Local cruelty, and the Avatar happened to be near
	# -----------------------------------------------------------------------
	"av_local": {"title": "On the Road", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "On the road ahead someone is waiting, alone: {avatar}, holding a child's sandal {av_they} found in the ashes behind you.", "next": "b"},
		"b": {"who": "avatar", "expr": "angry", "text": "I was two valleys over. I heard the bells. These people have nothing you need. You're done here.", "choices": [
			{"text": "\"I'll make amends.\" (Pay the villages a third of your gold, at least 500)", "next": "amends"},
			{"text": "\"We're leaving this region.\"", "next": "leave"},
			{"text": "\"Stand aside, or I'll go through you.\"", "next": "fight"},
		]},
		"amends": {"who": "avatar", "expr": "neutral", "text": "Good. Money won't unburn anything. It will rebuild some of it. I'll make sure it gets where it's going.",
			"do": [["call", "avatar_amends"], ["av_attitude", 10]]},
		"leave": {"who": "avatar", "expr": "neutral", "text": "Then go. Don't come back like this.", "do": [["infamy", -20], ["av_attitude", -5]]},
		"fight": {"who": "avatar", "expr": "determined", "text": "I was hoping you'd say something else.", "do": [["av_attitude", -30], ["call", "avatar_local_fight"]]},
	}},

	# -----------------------------------------------------------------------
	# Teacher: a young Avatar needs a master of the player's element
	# -----------------------------------------------------------------------
	"av_teacher": {"title": "A Student", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "A young traveller walks into your camp at dusk, sets down a pack that is mostly scrolls, and bows too deeply, the way people do when they have practised it. It is {avatar}.", "next": "b"},
		"b": {"who": "avatar", "expr": "embarrassed", "text": "My teachers made a list of every living master of {need}. Then they crossed out the cruel ones, and the dead ones, and the ones who wouldn't teach someone like me. You were at the top. You were also nearly crossed out for being hard to find, which is funny, coming from me.", "next": "c"},
		"c": {"who": "avatar", "expr": "determined", "text": "I can read forms. I need someone to show me how it's supposed to feel. Will you teach me? It'll take most of a season. I'll do the dishes. I'm very bad at dishes, but I'll do them.", "choices": [
			{"text": "\"Yes. We start at dawn.\"", "next": "yes"},
			{"text": "\"I'm not a teacher.\"", "next": "no"},
		]},
		"yes": {"who": "avatar", "expr": "happy", "text": "Dawn. Right. Great. …How early is dawn, exactly?",
			"do": [["call", "avatar_teach"], ["journal", "av_teach", "Teaching the Avatar", "{avatar} travels with you to learn {need}. In forty days the training will be done. {av_they} fights beside you in the meantime."]]},
		"no": {"who": "avatar", "expr": "sad", "text": "Everyone's a teacher to somebody. But all right. Thank you for hearing me out.", "do": [["av_attitude", -5]]},
	}},
	"av_taught": {"title": "The Lesson", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Forty mornings. Forty failures, give or take. Then, one grey dawn, {avatar} stops trying to copy you and simply moves, and the {element} answers like it has been waiting for {av_them} to ask properly.", "next": "b"},
		"b": {"who": "avatar", "expr": "laugh", "text": "I felt it. Not the move: the reason for the move. — Thank you, {name}. When the next Avatar asks who taught me, I'm going to make sure they know. Every one of them, forever. That's the deal. Sorry.",
			"do": [["call", "avatar_taught"], ["journal_done", "av_teach", "You taught {avatar}. Every Avatar after {av_them} will know your name."]]},
	}},
	"talk_avatar": {"title": "Your Student", "start": "hub", "nodes": {
		"hub": {"who": "avatar", "expr": "neutral", "text": "I'm practising. Or I was. I'm now holding still and calling it practising. What is it?", "choices": [
			{"text": "\"How is the training going?\"", "next": "train"},
			{"text": "\"Do your past lives ever give advice?\"", "next": "lives"},
			{"text": "\"Do you miss home?\"", "next": "home"},
			{"text": "\"Carry on.\"", "next": ""},
		]},
		"train": {"who": "avatar", "expr": "embarrassed", "text": "Badly. Then less badly. You do this thing where you say nothing and look at my feet, and I fix my feet. I'm going to start doing that to people.", "next": "hub"},
		"lives": {"who": "avatar", "expr": "thoughtful", "text": "Constantly. They disagree with each other. One of them thinks I should eat more. One of them thinks you're showing off. I'm not saying which.", "next": "hub"},
		"home": {"who": "avatar", "expr": "sad", "text": "{av_home}. Every day. I used to think the Avatar didn't get a home. I think the Avatar gets every home, and has to leave all of them. — Sorry. That got heavy. Ask me about dishes.", "next": "hub"},
	}},

	# -----------------------------------------------------------------------
	# Countermeasures: a raid on the Avatar's home, a hostage
	# -----------------------------------------------------------------------
	"av_diverted": {"title": "Two Steps Ahead", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Your detachment reached {av_home} three days ahead of {avatar}. You don't ask what they did there. When the Avatar arrived there was nothing left to save but people, and {av_they} stayed to save them.", "next": "b"},
		"b": {"who": "narrator", "text": "Word comes: the Avatar has turned back, for now. Those who saw {av_them} at {av_home} say {av_they} did not speak for a day. You have bought time. Your companions are very quiet tonight.",
			"do": [["av_attitude", -40], ["approval", "pemba", -25], ["approval", "nima", -15], ["approval", "hana", -15], ["approval", "juro", -15], ["approval", "kesi", -15], ["approval", "shen_mu", -15], ["approval", "ukiuk", -10]]},
	}},
	"av_hostage_take": {"title": "The Avatar's Home", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "{loved}, {loved_role}, lives at the edge of {av_home}, in a house with a crooked gate. Your spies were right: no guards. Nobody guards the people the Avatar loves. Nobody has ever needed to.", "choices": [
			{"text": "Take {loved}.", "next": "take"},
			{"text": "Leave. Not this.", "next": "leave"},
		]},
		"take": {"who": "av_loved", "expr": "afraid", "text": "You know who I am. Then you know what's coming for you. I'm not threatening you. I'm sorry for you.",
			"do": [["call", "avatar_take_hostage"], ["approval", "pemba", -40], ["approval", "nima", -25], ["approval", "hana", -20], ["approval", "juro", -20], ["approval", "kesi", -20], ["approval", "shen_mu", -20], ["approval", "ukiuk", -15], ["approval", "reika", -5],
				["journal", "av_main", "The Avatar", "You hold {loved}, whom {avatar} loves. If the Avatar comes for you, you can use them to force a retreat."]]},
		"leave": {"who": "narrator", "text": "You walk back out through the crooked gate. Some lines, it turns out, you will not cross. It is good to know where they are.", "do": [["honor", 2]]},
	}},
	"av_hostage_rescued": {"title": "An Empty Cell", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "In the morning the cell where you kept {loved} is open from the inside. The lock has been turned to sand. {loved} is gone, and so, for a long time, is any chance that {avatar} will forgive you.",
			"do": [["journal", "av_main", "The Avatar", "{loved} was rescued. {avatar} will not forgive you."]]},
	}},

	# -----------------------------------------------------------------------
	# The Quiet Years end: the child is told
	# -----------------------------------------------------------------------
	"av_revealed": {"title": "The Quiet Years End", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "News travels faster than any rider: the sages have told a sixteen-year-old named {av_name} what {av_they} is. The world exhales. Some of it is relieved. Some of it starts counting its sins.", "choices": [
			{"text": "Continue.", "next": "kept", "if": {"call": "av_kept"}, "hide": true},
			{"text": "Continue.", "next": "end", "if": {"call": "av_not_kept"}, "hide": true},
		]},
		"kept": {"who": "narrator", "text": "In a cold temple, Abbess Tsering hands {av_them} six pages wrapped in oilcloth, and tells {av_them} they were carried by people who wanted nothing from them. {av_name} reads the last page aloud.", "next": "end"},
		"end": {"who": "narrator", "text": "{avatar} has three elements to learn. Somewhere, the masters of those elements are being looked for.",
			"do": [["journal", "av_main", "The Avatar", "The Quiet Years are over: {avatar} has been told. {av_they} will be hard to find, and will come to you only for good reason."]]},
	}},
}
