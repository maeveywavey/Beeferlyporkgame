extends RefCounted
## The main storyline, "The Drowned Testament" (docs/setting.md §3).
## Eleven years ago the Avatar died at sea on the way to a peace conference:
## poisoned days before (which blocked the Avatar State) and spent holding the
## sea off the crew's boats (docs/canon.md §9). The player is never told this
## outright; pages I, IV and V hint at it. Their
## logbook was torn apart by salvage, theft and fear. The player gathers six
## pages, learns what happened, and decides what the truth is for.

const NPCS := {
	"norbu": {"name": "Brother Norbu", "culture": "air", "vlook": {"sex": "m", "hair": "", "accessory": "air_arrow"}, "kit": "air_robes"},
	"tsering": {"name": "Abbess Tsering", "culture": "air", "vlook": {"sex": "f", "hair": "", "accessory": "air_arrow", "height": 0.96}, "kit": "air_robes"},
	"shiyo": {"name": "Old Mother Shiyo", "culture": "outlaw", "vlook": {"sex": "f", "hair": "Hair_Buns", "hair_color": Color(0.7, 0.68, 0.66), "accessory": "pirate_hat"}, "outfit": "ranger", "kit": "sash"},
	"clerk": {"name": "Records Clerk Fumio", "culture": "fire", "vlook": {"sex": "m", "hair": "Hair_SimpleParted", "accessory": "topknot"}, "kit": "sash"},
	"wan_shi_tong": {"name": "Wan Shi Tong", "portrait": false},
	"refugee": {"name": "Grandmother Ai", "culture": "earth", "vlook": {"sex": "f", "hair": "Hair_Buns", "hair_color": Color(0.75, 0.73, 0.7)}},
	"hamakaze_delegate": {"name": "Captain Oyama", "culture": "hamakaze", "vlook": {"sex": "f", "hair": "Hair_Long", "accessory": "hamakaze"}, "kit": "tide_armor", "outfit": "ranger"},
}

const SPAWNS := {
	"norbu_hunters": {"name": "Daofei Hunters", "scale": true, "troops": [["mountain_bandit", 6], ["pirate", 3]], "gold": 150,
		"on_defeat": [["flag", "ms_norbu_saved", true], ["queue", "ms_norbu_lives"]]},
	"shiyo_fleet": {"name": "Old Mother Shiyo's Crew", "troops": [["pirate", 18], ["pirate_captain", 4]], "gold": 900,
		"on_defeat": [["flag", "ms_got2", true], ["page", 2], ["journal_done", "ms_page2", "You took Page II from Old Mother Shiyo's sea chest. She will tell the story differently."]]},
	"kuro_agents": {"name": "Men Without Banners", "scale": true, "troops": [["fn_veteran", 8], ["fn_firebender", 5], ["fn_archer", 4]], "gold": 400,
		"on_defeat": [["flag", "kuro_implicated", true], ["queue", "ms_agents_beaten"]]},
	"kuro_rebels": {"name": "Kuro's Last Fleet", "faction": "bandits", "troops": [["fn_veteran", 30], ["fn_imperial_fb", 12], ["fn_yuyan", 10], ["fn_rhino_rider", 8]], "gold": 3000,
		"on_defeat": [["flag", "kuro_defeated", true], ["queue", "ms_kuro_falls"]]},
	"censor_agents": {"name": "Censorate Agents", "scale": true, "faction": "bandits", "troops": [["ek_censor", 6], ["ek_earthbender", 4]], "gold": 250,
		"on_defeat": [["queue", "ms_censor_beaten"]]},
	"wu_loyalists": {"name": "Wu Jian's Loyalists", "faction": "bandits", "troops": [["ek_censor", 14], ["ek_royal_guard", 16], ["ek_earthbender", 20]], "gold": 3000,
		"on_defeat": [["flag", "wu_defeated", true], ["queue", "ms_wu_falls"]]},
}

const TRIGGERS := [
	{"on": "daily", "dlg": "ms_prologue", "if": {"day": 2, "era": "quiet"}},
	{"on": "daily", "dlg": "ms_norbu_dies", "if": {"flag": "ms_norbu_fight", "not_flag": "ms_norbu_saved", "days_since": ["ms_norbu_fight_day", 2]}},
	{"on": "daily", "dlg": "ms_assassins", "if": {"pages": 3, "not_flag": "ms_truth_decided"}, "chance": 0.15, "do": [["spawn", "kuro_agents"]]},
	{"on": "daily", "dlg": "ms_refugees_raided", "if": {"flag": "refugees_betrayed", "days_since": ["refugees_betrayed", 10]}},
	{"on": "daily", "dlg": "ms_censor_hunt", "once": false, "if": {"flag": "censor_enemy", "not_flag": "wu_defeated", "near_faction": "earth_kingdom", "days_since": ["censor_hunt_day", 25]}, "chance": 0.1,
		"do": [["flag_day", "censor_hunt_day"], ["spawn", "censor_agents"]]},
	{"on": "daily", "dlg": "ms_told_epilogue", "if": {"flags": ["kuro_defeated", "wu_defeated", "ending_told"]}},
]

const OPTIONS := [
	{"sid": "eastern_air_temple", "text": "Bring Brother Norbu's packet to Abbess Tsering", "dlg": "ms_abbess", "if": {"flag": "ms_packet", "not_flag": "ms_act1"}},
	{"sid": "eastern_air_temple", "text": "Ask Abbess Tsering about the archive's page", "dlg": "ms_archive", "if": {"flag": "ms_act1", "not_flag": "ms_got3"}},
	{"sid": "eastern_air_temple", "text": "Bring Grandmother Ai's refugees into the temple", "dlg": "ms_refugees_deliver", "if": {"flag": "ms_refugees_gathered", "not_flag": "ms_got3"}},
	{"sid": "full_moon_bay", "text": "Seek out Old Mother Shiyo", "dlg": "ms_shiyo", "if": {"flag": "ms_act1", "not_flag": "ms_got2"}},
	{"sid": "full_moon_bay", "text": "Gather the refugees bound for the Eastern Air Temple", "dlg": "ms_refugees_gather", "if": {"flag": "ms_refugee_escort", "not_flag": "ms_refugees_gathered"}},
	{"sid": "ba_sing_se", "text": "Look into the Censorate vault", "dlg": "ms_vault", "if": {"flag": "ms_act1", "not_flag": "ms_got4"}},
	{"sid": "fire_navy_harbor", "text": "Find the Admiralty's records room", "dlg": "ms_admiralty", "if": {"flag": "ms_act1", "not_flag": "ms_got5"}},
	{"sid": "wan_shi_tong", "text": "Descend into the library and find the owl", "dlg": "ms_library", "if": {"flag": "ms_act1", "not_flag": "ms_got6"}},
	{"sid": "ba_sing_se", "text": "Accept the Grand Secretary's invitation to tea", "dlg": "ms_wu_tea", "if": {"pages": 4, "not_flag": "ms_truth_decided"}, "once": true},
	{"sid": "fire_navy_harbor", "text": "Dine aboard the Admiral's flagship", "dlg": "ms_kuro_dinner", "if": {"pages": 4, "not_flag": "ms_truth_decided"}, "once": true},
	{"sid": "ba_sing_se", "text": "Tell the Earth Queen what the pages say, as you promised", "dlg": "ms_queen_first", "if": {"flags": ["queen_ally", "ms_truth"], "not_flag": "ms_queen_told"}},
	{"sid": "hamakaze", "text": "Open the Council of Nations", "dlg": "ms_council", "if": {"eq": ["ms_path", "told"], "not_flag": "ending_told"}},
	{"sid": "caldera", "text": "Lay the logbook before the Fire Lord", "dlg": "ms_sold_fire", "if": {"eq": ["ms_path", "sold_fire"], "not_flag": "ms_ended"}},
	{"sid": "ba_sing_se", "text": "Lay the logbook before the Earth Queen", "dlg": "ms_sold_earth", "if": {"eq": ["ms_path", "sold_earth"], "not_flag": "ms_ended"}},
	{"sid": "omashu", "text": "Lay the logbook before King Feng Tao", "dlg": "ms_sold_omashu", "if": {"eq": ["ms_path", "sold_omashu"], "not_flag": "ms_ended"}},
	{"sid": "fire_navy_harbor", "text": "Send word to Admiral Kuro that you have something he wants", "dlg": "ms_sell_kuro", "if": {"eq": ["ms_path", "buried"], "not_flag": "ms_ended"}},
	{"sid": "eastern_air_temple", "text": "Give the logbook to Abbess Tsering, for the next Avatar", "dlg": "ms_kept", "if": {"eq": ["ms_path", "kept"], "not_flag": "ms_ended"}},
]

const DIALOGUES := {
	# -----------------------------------------------------------------------
	# Prologue: the courier
	# -----------------------------------------------------------------------
	"ms_prologue": {"title": "The Courier", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Dusk. A man in torn orange robes stumbles out of the brush and nearly falls into your cookfire. There is an arrow in his shoulder, and an oilcloth packet clutched to his chest as if it were the arrow that mattered.", "next": "b"},
		"b": {"who": "norbu", "expr": "pain", "text": "Forgive me. I'm told it's rude to bleed on strangers. I'm Norbu, of the Eastern Air Temple. There are men behind me — daofei, but not the usual kind. Someone is paying them very well.", "next": "c"},
		"c": {"who": "norbu", "expr": "afraid", "text": "Southern divers brought this up from the wreck of the Lantern. You know the ship. Everyone knows the ship. It's a page of the Avatar's logbook, and I was told to carry it to someone who wanted nothing from it.", "next": "d"},
		"d": {"who": "norbu", "expr": "sad", "text": "I couldn't find anyone like that. So I'm giving it to you, and hoping. Please — take it to Abbess Tsering at the Eastern Air Temple. Torches, there, on the ridge. They're close.", "choices": [
			{"text": "\"Get behind me. Nobody else is taking that packet tonight.\" (Fight the hunters)", "next": "fight"},
			{"text": "\"We run. Can you walk?\" (Carry him away)", "next": "run"},
			{"text": "\"Why would I risk my neck for a page of paper?\"", "next": "why"},
		]},
		"why": {"who": "norbu", "expr": "thoughtful", "text": "Because it's not paper. It's the last thing a person wrote who was trying very hard to stop all this. And because you haven't run yet, which tells me something about you.", "choices": [
			{"text": "\"…Get behind me.\" (Fight the hunters)", "next": "fight"},
			{"text": "\"Fine. We run.\" (Carry him away)", "next": "run"},
		]},
		"fight": {"who": "norbu", "expr": "determined", "text": "I won't fight. But I'll keep breathing, which is going to annoy them. Thank you.",
			"do": [["flag", "ms_packet", true], ["flag", "ms_norbu_fight", true], ["flag_day", "ms_norbu_fight_day"], ["page", 1],
				["journal", "ms_main", "The Drowned Testament", "Brother Norbu, a wounded Air Nomad courier, gave you a page from the drowned Avatar's logbook. Daofei hunters are close. Defeat them, then take the packet to Abbess Tsering at the Eastern Air Temple."],
				["spawn", "norbu_hunters"]]},
		"run": {"who": "narrator", "text": "You get his arm over your shoulder and go. He is lighter than he should be. The torches follow you for an hour, then lose you in a streambed, and by then he is very quiet.", "next": "run2"},
		"run2": {"who": "norbu", "expr": "tender", "text": "That's far enough. No — sit with me. I don't mind dying, I think. I mind not knowing whether it worked. Tell the Abbess I'm sorry about the bison. She'll know.", "next": "run3"},
		"run3": {"who": "narrator", "text": "He dies before moonrise. You bury him under a pine, because you don't know how the Nomads do it, and it seems better than nothing. The packet is dry. He made sure of that.",
			"do": [["flag", "ms_packet", true], ["flag", "ms_norbu_dead", true], ["page", 1],
				["journal", "ms_main", "The Drowned Testament", "Brother Norbu died carrying a page of the drowned Avatar's logbook. He asked you to take it to Abbess Tsering at the Eastern Air Temple, and to tell her he was sorry about the bison."]]},
	}},
	"ms_norbu_lives": {"title": "The Courier", "start": "a", "nodes": {
		"a": {"who": "norbu", "expr": "happy", "text": "They're gone? They're gone. I would hug you, but the arrow has opinions about that. I'll heal at the temple. Go ahead of me — the Abbess will want the page more than she wants me, and that's as it should be.", "next": "b"},
		"b": {"who": "norbu", "expr": "smirk", "text": "If anyone gives you trouble about the archive, tell them Norbu vouches for you. It carries a surprising amount of weight for a man who once got a bison stuck in a bell tower.",
			"do": [["journal", "ms_main", "The Drowned Testament", "You saved Brother Norbu from the daofei hunters. Take the Avatar's page to Abbess Tsering at the Eastern Air Temple. Norbu will vouch for you there."], ["renown", 10], ["rel", "air_nomads", 10]]},
	}},
	"ms_norbu_dies": {"title": "The Courier", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "You find Brother Norbu where the hunters left him, under a pine at the edge of the road. They took his sandals and left the arrow. Whatever they wanted, they did not find it on him — because it is in your pack.", "do": [["flag", "ms_norbu_dead", true],
			["journal", "ms_main", "The Drowned Testament", "The hunters caught Brother Norbu. Take the page he died for to Abbess Tsering at the Eastern Air Temple."]]},
	}},

	# -----------------------------------------------------------------------
	# Act I: the Abbess and the scattered pages
	# -----------------------------------------------------------------------
	"ms_abbess": {"title": "The Eastern Air Temple", "start": "a", "nodes": {
		"a": {"who": "tsering", "expr": "thoughtful", "text": "Norbu's knot. He ties it backwards; he always has. Sit down, {name}. You have been carrying something heavy, and I don't only mean the packet.", "next": "b"},
		"b": {"who": "tsering", "expr": "sad", "text": "This is their hand. I would know it anywhere — they wrote to me every winter for thirty years, mostly to complain about my tea. The logbook was in a waterproof case. The salvagers cut it apart and sold it by the page, like a fish.", "next": "c"},
		"c": {"who": "tsering", "expr": "neutral", "text": "Six pages survived that we know of. This is the first. One went to a pirate, Old Mother Shiyo, who anchors off Full Moon Bay. One came here, to our archive, before any of this. One vanished into the Censorate's vaults in Ba Sing Se. One sits in the Fire Navy's records at the Admiralty harbour. And one was carried into the desert and traded to Wan Shi Tong, who does not give things back.", "next": "d"},
		"d": {"who": "tsering", "expr": "determined", "text": "I will not tell you what to do with them. I will tell you that two very powerful men have spent eleven years making sure nobody asks what happened on that ship. If you gather these pages, you will become a question they cannot ignore.", "choices": [
			{"text": "\"Then I'll be a very loud question.\"", "next": "e"},
			{"text": "\"Which two men?\"", "next": "who"},
		]},
		"who": {"who": "tsering", "expr": "thoughtful", "text": "If I said their names, you would go looking for proof that I was right. Find the pages first. Then you will not need my opinion.", "next": "e"},
		"e": {"who": "tsering", "expr": "tender", "text": "Go gently. And if you are tempted to sell what you find — and you will be, the offers will be very large — remember that the person who wrote it died at sea trying to make the shouting stop.",
			"do": [["flag", "ms_act1", true], ["xp", 300],
				["journal", "ms_main", "The Drowned Testament", "Abbess Tsering told you where the other five pages went. Gather them, then decide what the truth is for."],
				["journal", "ms_page2", "Page II: Old Mother Shiyo", "The pirate queen Old Mother Shiyo bought a page from the salvagers. She anchors off Full Moon Bay."],
				["journal", "ms_page3", "Page III: The Temple Archive", "The Eastern Air Temple's archive holds a letter the Avatar left the winter before the talks. Ask Abbess Tsering."],
				["journal", "ms_page4", "Page IV: The Censorate Vault", "A page vanished into the Censorate's vaults beneath Ba Sing Se."],
				["journal", "ms_page5", "Page V: The Admiralty Records", "The Fire Navy filed a page in its records room at the Fire Navy Harbour."],
				["journal", "ms_page6", "Page VI: Wan Shi Tong", "A page was traded to the owl spirit Wan Shi Tong, whose library lies under the Si Wong Desert. He trades knowledge only for knowledge."]]},
	}},
	"ms_archive": {"title": "The Temple Archive", "start": "a", "nodes": {
		"a": {"who": "tsering", "expr": "neutral", "text": "The letter is ours, and the archive's rule is that nothing leaves it except in exchange for a kindness to the temple. I didn't write the rule. I've considered burning it many times.", "choices": [
			{"text": "\"Norbu said to tell you he vouches for me.\"", "next": "norbu", "if": {"flag": "ms_norbu_saved"}, "hint": "Norbu must be alive", "hide": true},
			{"text": "(Pemba) \"Abbess, this is my friend. Please.\"", "next": "pemba", "if": {"companion": "pemba"}, "hide": true},
			{"text": "\"Name the kindness.\"", "next": "task"},
		]},
		"norbu": {"who": "tsering", "expr": "laugh", "text": "Does he. The bell-tower man. Very well — his vouching has never once been wrong, which is more than I can say for his knots.", "next": "give"},
		"pemba": {"who": "tsering", "expr": "tender", "text": "Pemba of the Southern Temple. Dorje writes that you left to find Dawa. Have you? …No. Not yet. Well. A Nomad asking on behalf of a friend is a kindness already. Take it.", "do": [["approval", "pemba", 5]], "next": "give"},
		"task": {"who": "tsering", "expr": "thoughtful", "text": "There are families waiting at Full Moon Bay for a ferry to Ba Sing Se that will never take them; the Lower Ring is full. Bring them here instead. We have room, and soup, and far too many novices who need someone to look after.", "choices": [
			{"text": "\"I'll bring them.\"", "next": "accept"},
			{"text": "\"Not yet.\"", "next": ""},
		]},
		"accept": {"who": "tsering", "expr": "happy", "text": "Thank you. Ask for Grandmother Ai. She will already be organising everyone; let her.",
			"do": [["flag", "ms_refugee_escort", true], ["journal", "ms_page3", "Page III: The Temple Archive", "Abbess Tsering will trade the Avatar's letter for a kindness: bring the refugees stranded at Full Moon Bay to the Eastern Air Temple."]]},
		"give": {"who": "narrator", "text": "The Abbess returns with a folded letter in a cedar box. The handwriting is cramped, as if written in a cold room.",
			"do": [["flag", "ms_got3", true], ["page", 3], ["journal_done", "ms_page3", "Abbess Tsering gave you the Avatar's last letter to the temple."]]},
	}},
	"ms_refugees_gather": {"title": "Full Moon Bay", "start": "a", "nodes": {
		"a": {"who": "refugee", "expr": "smirk", "text": "The Abbess sent you? Good. I have forty-one people, nine goats and one man who insists he is a famous poet. He is not. We leave at dawn; I've already packed your things for you. Don't argue, dear, it's faster.", "next": "b"},
		"b": {"who": "narrator", "text": "Grandmother Ai's column falls in behind your own. Children ride on your supply carts and give your soldiers new names, most of them unflattering.",
			"do": [["flag", "ms_refugees_gathered", true], ["journal", "ms_page3", "Page III: The Temple Archive", "You have Grandmother Ai's refugees. Bring them to the Eastern Air Temple."]]},
	}},
	"ms_refugees_deliver": {"title": "The Eastern Air Temple", "start": "a", "nodes": {
		"a": {"who": "tsering", "expr": "happy", "text": "Forty-one, and nine goats, and — oh no, the poet. Well. We have survived worse. You've done a kindness, {name}, and the archive keeps its word.", "do": [["rel", "air_nomads", 15], ["renown", 15], ["honor", 2]], "next": "b"},
		"b": {"who": "narrator", "text": "The Abbess returns with a folded letter in a cedar box. The handwriting is cramped, as if written in a cold room.",
			"do": [["flag", "ms_got3", true], ["page", 3], ["journal_done", "ms_page3", "You brought the refugees to safety, and Abbess Tsering gave you the Avatar's last letter to the temple."]]},
	}},
	"ms_shiyo": {"title": "Old Mother Shiyo", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Shiyo's flagship is an old grain barge with three masts nailed onto it and a great many cannons. She receives you on deck in a wicker chair, eating lychees and spitting the stones at a gull.", "next": "b"},
		"b": {"who": "shiyo", "expr": "smirk", "text": "The Avatar's page. Of course. Everyone wants my page this year. An admiral's man offered me a ship for it. A Censorate man offered me my life, which was less generous, since I already have it.", "next": "c"},
		"c": {"who": "shiyo", "expr": "thoughtful", "text": "I bought it because I thought it would be worth more later. It is. Fifteen hundred gold, and it's yours, and I'll forget your face as a courtesy.", "choices": [
			{"text": "Pay her. (1,500 gold)", "next": "pay", "if": {"gold": 1500}, "hint": "need 1,500 gold"},
			{"text": "(Reika) \"Hello, Shiyo. You still owe me for the Cinder Strait.\"", "next": "reika", "if": {"companion": "reika"}, "hide": true},
			{"text": "\"I'd rather take it.\" (Fight her crew)", "next": "fight"},
			{"text": "\"Too rich for me.\"", "next": ""},
		]},
		"pay": {"who": "shiyo", "expr": "happy", "text": "A buyer who doesn't haggle. My heart. Here — careful, it's been in my hat.",
			"do": [["gold", -1500], ["flag", "ms_got2", true], ["page", 2], ["journal_done", "ms_page2", "You bought Page II from Old Mother Shiyo."]]},
		"reika": {"who": "reika", "expr": "smirk", "text": "Three ships, one typhoon, and you sailed off with my cargo while I bailed. I've decided the page settles it. Rin sends her love, by the way. She doesn't.", "next": "reika2"},
		"reika2": {"who": "shiyo", "expr": "embarrassed", "text": "…Kuroda. I'd hoped you'd drowned somewhere picturesque. Fine. Take it. And tell my daughter to write.",
			"do": [["flag", "ms_got2", true], ["page", 2], ["approval", "reika", 8], ["flag", "reika_debt_called", true], ["journal_done", "ms_page2", "Reika called in an old debt, and Old Mother Shiyo gave up Page II."]]},
		"fight": {"who": "shiyo", "expr": "angry", "text": "Pity. You had a nice face. BOYS!",
			"do": [["spawn", "shiyo_fleet"], ["close_windows"]]},
	}},
	"ms_vault": {"title": "Beneath Ba Sing Se", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The Censorate's vaults are said to lie under the Imperial Reservoir, under the Upper Ring, under the palace, under everything. What is certain is that nobody who asks about them asks twice.", "choices": [
			{"text": "(Hana) Ask Hana about the tunnels.", "next": "hana", "if": {"companion": "hana"}, "hide": true},
			{"text": "Petition the Earth Queen for it.", "next": "queen", "if": {"standing": 2}, "hint": "needs Gentry standing"},
			{"text": "Break into the vault yourself.", "next": "steal", "if": {"skill": ["tactics", 4]}, "hint": "needs Tactics 4"},
			{"text": "Break in anyway.", "next": "caught"},
			{"text": "Leave it for now.", "next": ""},
		]},
		"hana": {"who": "hana", "expr": "thoughtful", "text": "The vault is under the old Wenlong granary, not the Reservoir. That rumour is maintained on purpose. There is a drainage tunnel the Censorate sealed in the forty-third year of the old king. They sealed it badly. I have been meaning to tell someone about that for six years.", "next": "hana2"},
		"hana2": {"who": "narrator", "text": "Hana walks you through two hours of dripping darkness without once lighting a lamp, counting steps under her breath. The vault is a room of filing cabinets. The page is filed under 'Weather'.",
			"do": [["flag", "ms_got4", true], ["page", 4], ["approval", "hana", 6], ["journal_done", "ms_page4", "Hana led you through a forgotten drainage tunnel into the Censorate vault. The page was filed under 'Weather'."]]},
		"queen": {"who": "hualing", "expr": "thoughtful", "text": "A page of the Avatar's logbook in my own vaults, and nobody told me. That is the most interesting thing anyone has said to me in a year. Secretary Wu will be unhappy. I find that I don't mind.", "next": "queen2"},
		"queen2": {"who": "hualing", "expr": "determined", "text": "You may have it. In return, promise me this: whatever it says, you will tell me before you tell anyone else. I have spent nineteen years being the last to know things in my own palace.", "choices": [
			{"text": "\"You'll hear it first. I promise.\"", "next": "queen3", "do": [["flag", "queen_ally", true], ["lord_rel", "hualing", 15]]},
			{"text": "\"I can't promise that.\"", "next": "queen4", "do": [["lord_rel", "hualing", -5]]},
		]},
		"queen3": {"who": "hualing", "expr": "happy", "text": "Good. Then we are conspirators. I have always wanted to be one.",
			"do": [["flag", "ms_got4", true], ["page", 4], ["flag", "upper_invite", true], ["journal_done", "ms_page4", "Earth Queen Hualing gave you the page from her own vault — and asked to hear the truth first."]]},
		"queen4": {"who": "hualing", "expr": "sad", "text": "Honest, at least. Take it anyway. I would rather it be in the hands of someone who refuses me than someone who lies to me.",
			"do": [["flag", "ms_got4", true], ["page", 4], ["journal_done", "ms_page4", "Earth Queen Hualing gave you the page from her own vault."]]},
		"steal": {"who": "narrator", "text": "You watch the guard changes for three nights, bribe a laundress, and walk out of the Censorate's vault with the page folded into a sock. Nobody notices. Nobody notices for almost a week.",
			"do": [["flag", "ms_got4", true], ["page", 4], ["journal_done", "ms_page4", "You stole the page from the Censorate vault without being seen."]]},
		"caught": {"who": "narrator", "text": "You get the page. You also get a stone cuff around your ankle, two censors, and a very long chase through the Middle Ring. You escape. The Censorate will not forget you.",
			"do": [["flag", "ms_got4", true], ["page", 4], ["flag", "censor_enemy", true], ["rel", "earth_kingdom", -20], ["lord_rel", "shu_fan", -30], ["lord_rel", "wu_jian", -15],
				["journal_done", "ms_page4", "You stole the page from the Censorate vault and were seen doing it."]]},
	}},
	"ms_admiralty": {"title": "The Admiralty Records", "start": "a", "nodes": {
		"a": {"who": "clerk", "expr": "neutral", "text": "Records. Requisitions, manifests, court-martials, weather. If it happened to the Fire Navy, I filed it. If it didn't, I filed that too. What do you want?", "choices": [
			{"text": "(Juro) Let Juro handle it.", "next": "juro", "if": {"companion": "juro"}, "hide": true},
			{"text": "\"This harbour answers to my banner now. Open the files.\"", "next": "owner", "if": {"owns": "fire_navy_harbor"}, "hide": true},
			{"text": "Slide 800 gold across the desk.", "next": "bribe", "if": {"gold": 800}, "hint": "need 800 gold"},
			{"text": "\"Never mind.\"", "next": ""},
		]},
		"juro": {"who": "juro", "expr": "smirk", "text": "Fumio. You still use the Sato cross-index? I designed that. Under duress, but I designed it. Salvage from the Lantern would be under 'Recovered Materials, Diplomatic, Sensitive' — which is drawer nine, because nobody has ever been able to spell 'diplomatic' under pressure.", "next": "juro2"},
		"juro2": {"who": "clerk", "expr": "surprised", "text": "…Sato? You died. There was a memorial. I contributed to the flowers. — Drawer nine. I didn't see you. I'm keeping the flowers.",
			"do": [["flag", "ms_got5", true], ["page", 5], ["approval", "juro", 6], ["journal_done", "ms_page5", "Juro found the page in drawer nine of the system he designed. Also a rudder pin with a Fire Navy foundry mark."]]},
		"owner": {"who": "clerk", "expr": "afraid", "text": "Yes. Of course. Drawer nine. There's — there's a rudder pin in there as well. I always wondered why anyone would file a rudder pin.",
			"do": [["flag", "ms_got5", true], ["page", 5], ["journal_done", "ms_page5", "The records clerk gave you the page, and a rudder pin with a Fire Navy foundry mark."]]},
		"bribe": {"who": "clerk", "expr": "embarrassed", "text": "I have a daughter at the academy, and the academy has fees, and you have a face I will not remember. Drawer nine. There's a rudder pin with it. Don't ask me why.",
			"do": [["gold", -800], ["flag", "ms_got5", true], ["page", 5], ["journal_done", "ms_page5", "You bribed a clerk for the page, and a rudder pin with a Fire Navy foundry mark."]]},
	}},
	"ms_library": {"title": "Wan Shi Tong's Library", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Down a spiral of sand-choked stairs, through halls of shelves that go up into darkness, a great owl waits on a lectern. Its eyes do not blink. Its voice comes from everywhere at once.", "next": "b"},
		"b": {"who": "wan_shi_tong", "text": "You want the Avatar's page. Humans always want the things other humans wrote. Very well. I trade knowledge for knowledge, of equal worth. Give me something worth a dead Avatar's words — something you would rather I did not know.", "choices": [
			{"text": "Tell him Hana's secret: the tunnel where her teacher died, and the name of the man who sealed it.", "next": "secret", "if": {"companion": "hana"}, "hide": true, "do": [["approval", "hana", -30], ["flag", "secret_given", "hana"]]},
			{"text": "Tell him Juro's secret: the village his fire-pots burned.", "next": "secret", "if": {"companion": "juro"}, "hide": true, "do": [["approval", "juro", -30], ["flag", "secret_given", "juro"]]},
			{"text": "Tell him Pemba's secret: where their sister Dawa hides.", "next": "secret", "if": {"companion": "pemba"}, "hide": true, "do": [["approval", "pemba", -30], ["flag", "secret_given", "pemba"]]},
			{"text": "Tell him Nima's secret: that she learned the combat forms.", "next": "secret", "if": {"companion": "nima"}, "hide": true, "do": [["approval", "nima", -30], ["flag", "secret_given", "nima"]]},
			{"text": "Tell him Ukiuk's secret: the fisherman he drowned.", "next": "secret", "if": {"companion": "ukiuk"}, "hide": true, "do": [["approval", "ukiuk", -30], ["flag", "secret_given", "ukiuk"]]},
			{"text": "Tell him Shen Mu's secret: what the letter he carries says.", "next": "secret", "if": {"companion": "shen_mu"}, "hide": true, "do": [["approval", "shen_mu", -30], ["flag", "secret_given", "shen_mu"]]},
			{"text": "Tell him Reika's secret: who she sold this page to before she knew what it was.", "next": "secret", "if": {"companion": "reika"}, "hide": true, "do": [["approval", "reika", -30], ["flag", "secret_given", "reika"]]},
			{"text": "Tell him Kesi's secret: the clan's hidden water routes.", "next": "secret", "if": {"companion": "kesi"}, "hide": true, "do": [["approval", "kesi", -30], ["flag", "secret_given", "kesi"]]},
			{"text": "Tell him something of your own — the thing you have never told anyone. (Lose 1,500 experience)", "next": "own"},
			{"text": "Tell him the Air Nomads' secret route for refugees through the mountains.", "next": "route"},
			{"text": "Leave.", "next": ""},
		]},
		"secret": {"who": "wan_shi_tong", "text": "Ah. Yes. That will do nicely. They heard you say it, of course. Humans always think the walls of a library are thick. Take your page.",
			"do": [["flag", "ms_got6", true], ["page", 6], ["journal_done", "ms_page6", "You traded a companion's secret to Wan Shi Tong for the page. They heard you."]]},
		"own": {"who": "wan_shi_tong", "text": "Interesting. I will shelve it under 'Regrets, Minor, Human'. It is a large section. Take your page.",
			"do": [["call", "lose_xp", 1500], ["flag", "ms_got6", true], ["page", 6], ["journal_done", "ms_page6", "You traded a piece of yourself to Wan Shi Tong for the page."]]},
		"route": {"who": "wan_shi_tong", "text": "The monks' mountain road. Valuable. Many people would pay for it. Some already have. Take your page, and do not wonder too hard about who reads my shelves.",
			"do": [["call", "refugee_route_betrayed"], ["flag", "ms_got6", true], ["page", 6], ["journal_done", "ms_page6", "You traded the Air Nomads' refugee route to Wan Shi Tong for the page."]]},
	}},
	"ms_wu_tea": {"title": "The Grand Secretary", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The invitation is written on paper so fine it is nearly cloth. The Grand Secretary takes tea in a Middle Ring pavilion with no walls, which you understand is meant to tell you that he has nothing to hide, and also that his agents can see you from every roof.", "next": "b"},
		"b": {"who": "wu_jian", "expr": "neutral", "text": "You collect paper. I admire collectors; I am one. My collection is mostly of people who were going to cause trouble and then, on reflection, did not. Sit. The tea is from the Queen's own terraces. She doesn't know I have it.", "next": "c"},
		"c": {"who": "wu_jian", "expr": "thoughtful", "text": "Whatever is on those pages describes a storm. Storms are nobody's fault. Pages, however, are always somebody's. I would pay a great deal for the pages to remain about the weather.", "choices": [
			{"text": "\"You turned the boats back.\"", "next": "boats", "if": {"has_page": 4}, "hide": true},
			{"text": "\"How much is a great deal?\"", "next": "offer"},
			{"text": "\"No.\"", "next": "no"},
		]},
		"boats": {"who": "wu_jian", "expr": "neutral", "text": "I filed an order that lifeboats return before dark in a storm. Lifeboats returned. The sea did the rest. If you intend to make that a crime, you will have to make filing a crime, and then where would any of us be?", "next": "offer"},
		"offer": {"who": "wu_jian", "expr": "smirk", "text": "Three thousand gold today. A post in the Middle Ring, if you want one. And whatever the Censorate has written about you is lost in a fire that, regrettably, has not happened yet.", "choices": [
			{"text": "Take the money. (He thinks he has bought your silence.)", "next": "take"},
			{"text": "\"Keep your tea.\"", "next": "no"},
		]},
		"take": {"who": "wu_jian", "expr": "happy", "text": "Splendid. I find that people who take money are so much easier to understand than people who don't. Mind the stairs.",
			"do": [["gold", 3000], ["flag", "wu_paid", true], ["flag", "censor_enemy", false], ["lord_rel", "wu_jian", 30], ["approval", "hana", -8], ["approval", "shen_mu", -5], ["approval", "reika", 3]]},
		"no": {"who": "wu_jian", "expr": "neutral", "text": "Then we are both collectors, and you have made yourself a very interesting item. Mind the stairs. They are steeper going down.",
			"do": [["lord_rel", "wu_jian", -15], ["flag", "wu_refused", true], ["approval", "hana", 4]]},
	}},
	"ms_kuro_dinner": {"title": "The Admiral's Table", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "A lieutenant in dress whites finds you on the quay with an invitation to dine aboard the Admiral's flagship. It is not phrased as a question. Dinner is grilled eel and very old wine, served by sailors who all, you notice, look well fed.", "next": "b"},
		"b": {"who": "kuro", "expr": "neutral", "text": "Every sailor on this coast eats because of the war. I don't say that proudly. I say it because nobody else will. The last time someone tried peace, four thousand sailors stood on a beach with no pay and no ships, and their children learned to steal.", "next": "c"},
		"c": {"who": "kuro", "expr": "thoughtful", "text": "I don't ask you to stop. I ask you to remember, when you read those pages aloud, that it won't be you who starves. It won't even be me.", "choices": [
			{"text": "\"You sent men without banners after me.\"", "next": "agents", "if": {"flag": "kuro_implicated"}, "hide": true},
			{"text": "\"Then pay your sailors to build ships instead of burning them.\"", "next": "honest"},
			{"text": "\"What would you give me to stop?\"", "next": "price"},
		]},
		"agents": {"who": "kuro", "expr": "sad", "text": "I sent men to find out who you were. They found out. I am sorry about the men; I knew most of their mothers. Eat. The eel is the only honest thing on this ship.", "next": "honest"},
		"honest": {"who": "kuro", "expr": "surprised", "text": "…You would be surprised how few people say that to me. Most of them say it after I'm out of the room. Finish your wine. My lieutenant will see you ashore, which on this ship is a courtesy.",
			"do": [["lord_rel", "kuro", 5], ["flag", "kuro_dinner_honest", true], ["approval", "reika", 3]]},
		"price": {"who": "kuro", "expr": "smirk", "text": "A ship. A letter of marque. Five thousand gold when the last page is ash. Come back when you have all six, and send word from this harbour. I'm a patient man. The sea taught me that, too.",
			"do": [["flag", "kuro_offer", true], ["approval", "juro", -4], ["approval", "pemba", -4]]},
	}},
	"ms_queen_first": {"title": "As Promised", "start": "a", "nodes": {
		"a": {"who": "hualing", "expr": "thoughtful", "text": "You came back. People promise me things every day; almost none of them come back. Read it to me. All of it. Don't summarise. I have been summarised my whole life.", "next": "b"},
		"b": {"who": "narrator", "text": "You read the six pages aloud in a small room with the shutters closed. When you reach the rescue log, Hualing asks you to read the line about G.S. again, and then a third time.", "next": "c"},
		"c": {"who": "hualing", "expr": "determined", "text": "Thank you. I will not tell you what to do with it; you kept your promise, and I will keep mine. But whatever you choose, I won't be the last to know again. That was the gift. The rest is yours.",
			"do": [["flag", "ms_queen_told", true], ["lord_rel", "hualing", 20], ["rel", "earth_kingdom", 5]]},
	}},
	"ms_assassins": {"title": "Men Without Banners", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Your scouts report a column on the road behind you: well-armed, well-fed, and flying no banner at all. Men without banners are always somebody's men."},
	}},
	"ms_agents_beaten": {"title": "Men Without Banners", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Among the dead you find a lacquered pay-chit stamped with a private seal: a wave breaking over a flame. Half the sailors in the Fire Navy would recognise it. It belongs to Admiral Tenzai Kuro.", "do": [["journal", "ms_main", "The Drowned Testament", "Someone sent soldiers without banners after you. Their pay-chits carry Admiral Kuro's private seal. Keep gathering the pages."]]},
	}},
	"ms_censor_hunt": {"title": "Green Robes", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "A farmer at a well will not meet your eyes. Further on, a road you took yesterday has been rebuilt overnight, a little narrower. The Censorate remembers the vault, and it has come to discuss it."},
	}},
	"ms_censor_beaten": {"title": "Green Robes", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The agents leave no names and no seals, only stone gloves and a written description of you that is unflatteringly accurate. There will be others."},
	}},
	"ms_refugees_raided": {"title": "The Mountain Road", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "News comes on the wind, the way bad news does. Fire Navy marines were waiting on the monks' mountain road. Forty refugees and two monks did not reach the temple. Nobody knows how the Navy knew the route. You know.",
			"do": [["rel", "air_nomads", -30], ["approval", "pemba", -40], ["approval", "nima", -10], ["honor", -5], ["infamy", 40, "the mountain road"]]},
	}},

	# -----------------------------------------------------------------------
	# The pages
	# -----------------------------------------------------------------------
	"page_1": {"title": "The Avatar's Logbook — Page I", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Day one of the talks. The Fire Lord's envoys brought their own tea, which is an insult, and the Regent brought his own chairs, which is worse. I have decided to find all of this funny. If I don't, I'll be furious, and the Avatar is not supposed to be furious at breakfast.\n\nSomething at the Regent's welcome dinner disagreed with me: two days of fever, and my hands still shake. When I sit to meditate the quiet place has a door in it now, and the door is shut. Probably nothing. Probably I'm tired.\n\nThe Water Tribe captain says there's weather coming. She says it the way people say 'your uncle is visiting'. I like her."},
	}},
	"page_2": {"title": "The Avatar's Logbook — Page II", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "A deckhand asked me tonight if the Avatar is ever scared. She can't have been more than fifteen. I told her yes, all the time, and that being scared is just your body taking something seriously.\n\nShe looked so relieved I almost cried. I think everyone on this ship thinks I'm going to fix it. I think I'm going to sit in a room with frightened old men and try to make them slightly less frightened. That's the whole job. It always was."},
	}},
	"page_3": {"title": "The Avatar's Letter — Page III", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Tsering — your tea is still terrible, and I'll miss it. I'm writing because I can't sleep and you're the only person who won't make it into a prophecy.\n\nI'm so tired of being the reason other people stop trying. Every village I save is a village that waits for the next Avatar instead of building a wall. Every war I stop is a war nobody learned to stop themselves. If these talks work, I want to go somewhere small and be useless for a year. If they don't — well. Tell the novices the joke about the bison and the bell tower. Norbu will hate it."},
	}},
	"page_4": {"title": "The Avatar's Logbook — Page IV", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "[Stapled behind the page: a rescue log under Censorate seal. 'Lifeboats of the escort squadron recalled on the Regent's standing order. Lanterns extinguished. Report to G.S. only.']\n\nThe storm has us. I've put the crew in the boats and I'm holding the sea flat around them. That much I can still do. I can see lanterns — boats coming from the escort, six or seven, bobbing. Thank the spirits. Not long now.\n\n…They've turned back. All of them, at once, like someone gave an order. Why would anyone give that order?"},
	}},
	"page_5": {"title": "The Avatar's Logbook — Page V", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "[Folded into the page: a rudder pin, sawn three-quarters through. The foundry mark is a Fire Navy anchor.]\n\nThe helm's gone slack. The captain says the rudder isn't broken, it's been cut — clean, a saw, not the sea. Someone didn't want this ship to arrive on time. I don't think they wanted it to sink. I think they wanted a delay, and a storm made it something else.\n\nI keep thinking: two small cowardices, and the weather did the rest.\n\nThe boats with the crew have reached the rocks. All of them. I can let go of the water now. Usually, when I'm this far past the end of myself, something older stands up inside me and finishes the job. Tonight there's only me. That's all right. Tonight, me was enough for them."},
	}},
	"page_6": {"title": "The Avatar's Logbook — Page VI", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Notes for the speech, in case I'm allowed to give it:\n\nPeace isn't a treaty. A treaty is a piece of paper saying peace is allowed. Peace is a lot of ordinary people deciding to be a little less afraid at the same time — the fisherman who doesn't burn the other village's nets, the clerk who files the order and then 'loses' it, the soldier who aims high.\n\nI can't make anyone do that. Nobody can. That's the terrible thing about it, and the hopeful thing too."},
	}},

	# -----------------------------------------------------------------------
	# Act II: the truth
	# -----------------------------------------------------------------------
	"ms_truth": {"title": "The Drowned Testament", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Six pages. You lay them out on a camp table in order and read them through, start to finish, twice. The last entry is written in a hand so shaken it is barely a hand at all.", "next": "b"},
		"b": {"who": "narrator", "text": "\"The rudder is gone and the boats have turned back. I don't know whose hands did either. I know whose fault it will be called.\n\nWhoever finds this — I'm sorry I wasn't enough. I don't want my death to be a reason. Please let it be an ending.\"", "next": "c"},
		"c": {"who": "narrator", "text": "The rudder pin bears a Fire Navy anchor: Admiral Tenzai Kuro's men cut it, to delay a peace that would have cost him the Isles. The rescue log bears the Censorate's seal: Grand Secretary Wu Jian's order turned the boats back, so the Fire Nation would carry the blame. Neither man meant for the Avatar to die. Both of them let it happen, and have lived on it for eleven years.", "next": "d"},
		"d": {"who": "narrator", "text": "Neither man ordered the Avatar's death. That is the truth you can prove, and it is worse than a villain. What you do with it is yours to decide.",
			"do": [["flag", "ms_truth", true], ["xp", 1500], ["renown", 25],
				["journal", "ms_main", "The Drowned Testament", "You know what happened on the Lantern: Kuro's men cut the rudder, Wu Jian's order turned back the rescue. Decide what to do with the truth (open the logbook from the camp menu)."]]},
	}},
	"ms_decide": {"title": "What the Truth Is For", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The logbook sits in its oilcloth. Everyone who knows you have it wants something from it. The Avatar asked for one thing: let it be an ending.", "choices": [
			{"text": "Convene a Council of Nations on Hamakaze and read it aloud to everyone at once.", "next": "told", "if": {"renown": 160, "peace_with": 3}, "hint": "needs 160 renown and peace with at least three nations"},
			{"text": "Take it to Fire Lord Haoren. It clears his nation's name, and he will reward the one who brings it.", "next": "sold_fire"},
			{"text": "Take it to Earth Queen Hualing. It gives her the means to break her regent.", "next": "sold_earth"},
			{"text": "Take it to King Feng Tao. Proof of Ba Sing Se's guilt would make Omashu's freedom unanswerable.", "next": "sold_omashu"},
			{"text": "Bury it. Sell it to Admiral Kuro, who will pay anything to see it burn.", "next": "buried"},
			{"text": "Burn it yourself, here, tonight.", "next": "burn"},
			{"text": "Keep it for the next Avatar. Give it to Abbess Tsering, to be read when the child turns sixteen.", "next": "kept"},
			{"text": "Not yet.", "next": ""},
		]},
		"told": {"who": "narrator", "text": "You send riders to every capital. Captain Oyama agrees to host; the Tide Wardens will guarantee safe passage. Go to Hamakaze to open the council.",
			"do": [["flag", "ms_path", "told"], ["journal", "ms_main", "The Drowned Testament", "You have called a Council of Nations. Go to Hamakaze to open it and read the logbook aloud."]]},
		"sold_fire": {"who": "narrator", "text": "Caldera, then. The Fire Lord loved the Avatar once. Perhaps that is enough.",
			"do": [["flag", "ms_path", "sold_fire"], ["journal", "ms_main", "The Drowned Testament", "Bring the logbook to Fire Lord Haoren in Caldera City."]]},
		"sold_earth": {"who": "narrator", "text": "Ba Sing Se, then. A young queen, an old regent, and a page with his seal on it.",
			"do": [["flag", "ms_path", "sold_earth"], ["journal", "ms_main", "The Drowned Testament", "Bring the logbook to Earth Queen Hualing in Ba Sing Se's Upper Ring."]]},
		"sold_omashu": {"who": "narrator", "text": "Omashu, then. Feng Tao will make a speech about it. He will make several.",
			"do": [["flag", "ms_path", "sold_omashu"], ["journal", "ms_main", "The Drowned Testament", "Bring the logbook to King Feng Tao in Omashu."]]},
		"buried": {"who": "narrator", "text": "Kuro, then. It is a great deal of money. You tell yourself the war would have gone on anyway.",
			"do": [["flag", "ms_path", "buried"], ["journal", "ms_main", "The Drowned Testament", "Send word to Admiral Kuro from the Fire Navy Harbour. He will pay to see the logbook burn."]]},
		"burn": {"who": "narrator", "text": "The oilcloth catches slowly, then all at once. The Avatar's handwriting curls and goes brown and then goes. Nobody will ever know. You will.",
			"do": [["flag", "ms_path", "burned"], ["call", "ending", "burned"]]},
		"kept": {"who": "narrator", "text": "The Eastern Temple has kept the Avatar's letters for thirty years. It can keep one more. In five years, a frightened sixteen-year-old will be told what they are. Let them also be told this.",
			"do": [["flag", "ms_path", "kept"], ["journal", "ms_main", "The Drowned Testament", "Give the logbook to Abbess Tsering at the Eastern Air Temple, to be kept for the next Avatar."]]},
	}},

	# -----------------------------------------------------------------------
	# Act III: endings
	# -----------------------------------------------------------------------
	"ms_council": {"title": "The Council of Nations", "start": "a", "nodes": {
		"a": {"who": "hamakaze_delegate", "expr": "determined", "text": "Every nation sent someone. The Fire Lord sent his daughter. The Earth Queen came herself, which nearly gave her regent a stroke. The North sent Iluq, the South sent Siqiniq, and Omashu sent Jiang Wei and a great deal of luggage. The floor is yours.", "next": "b"},
		"b": {"who": "narrator", "text": "You read the logbook aloud, all six pages, start to finish. Nobody speaks. When you reach the last entry, Princess Ryoko puts her hand over her mouth. Queen Hualing does not move at all.", "choices": [
			{"text": "Lay out the evidence: the rudder pin, the rescue log, and the testimony you've gathered.", "next": "proof", "if": {"call": "has_evidence"}, "hint": "needs corroboration: Kuro's ledgers, the Censorate's testimony, or Kuro's seal", "hide": false},
			{"text": "Speak from the heart. Ask them to let it be an ending.", "next": "heart", "if": {"renown": 320}, "hint": "needs 320 renown to sway them without corroboration"},
			{"text": "There is not enough here to convince them yet. Adjourn.", "next": "adjourn"},
		]},
		"proof": {"who": "narrator", "text": "The evidence is laid on the table: the sawn pin, the sealed log, and everything your companions risked to find. Kuro's envoy calls it forgery and is ignored. Wu Jian's chair, it is noticed, is empty.", "next": "accord"},
		"heart": {"who": "narrator", "text": "You do not argue. You tell them about Norbu, and a deckhand of fifteen, and a letter complaining about tea. You ask them to be a little less afraid at the same time. It should not work. Somehow, in that room, on that day, it does.", "next": "accord"},
		"accord": {"who": "hualing", "expr": "determined", "text": "The Earth Kingdom will sign. I will sign it myself. And the Grand Secretary will answer for the boats — if anyone can find him.", "next": "accord2"},
		"accord2": {"who": "ryoko", "expr": "grief", "text": "My father wept when the Avatar died. He'll weep again tonight, I think, but differently. The Fire Nation signs. The Admiral is relieved of command, as of this moment, wherever he is hiding.", "next": "accord3"},
		"accord3": {"who": "narrator", "text": "The Hamakaze Accord is signed at sunset. By morning, word comes that Admiral Kuro has taken the flagship and his loyal crews, and Wu Jian has vanished from Ba Sing Se with two hundred censors. Peace has enemies. It always does.",
			"do": [["call", "ending", "told"]]},
		"adjourn": {"who": "hamakaze_delegate", "expr": "sad", "text": "They'll come back, if you send for them again. Bring them something they can't argue with."},
	}},
	"ms_kuro_falls": {"title": "The Last Fleet", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Tenzai Kuro surrenders on the deck of his own flagship, in his dress uniform, with his sword laid across his palms. \"Every sailor I had ate because of me,\" he says. \"Write that down too.\" Somebody does."},
	}},
	"ms_wu_falls": {"title": "The Grand Secretary", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "Wu Jian is found in a mountain shrine, sitting very straight, filling out a form. It is a confession. It is complete, correct, and in triplicate. He has never once raised his voice."},
	}},
	"ms_told_epilogue": {"title": "The Hamakaze Accord", "start": "a", "nodes": {
		"a": {"who": "narrator", "text": "The last enemies of the Accord are beaten. There will be other wars — there always are — but not this one, and not for the reason it was fought.", "do": [["flag", "pending_epilogue", "told"]]},
	}},
	"ms_sold_fire": {"title": "Caldera", "start": "a", "nodes": {
		"a": {"who": "haoren", "expr": "grief", "text": "Their hand. Thirty years and I'd know it in the dark. …Kuro. My own admiral. And the Earth Kingdom's regent turned the boats away and let my nation carry it for eleven years.", "next": "b"},
		"b": {"who": "haoren", "expr": "determined", "text": "I will hang Kuro for the rudder. And I will make Ba Sing Se pay for the boats, in every port it has. You've given the Fire Nation a just war, {name}. A just war is the most dangerous gift there is. Kneel. You will be a lord of my house.",
			"do": [["call", "ending", "sold_fire"]]},
	}},
	"ms_sold_earth": {"title": "The Upper Ring", "start": "a", "nodes": {
		"a": {"who": "hualing", "expr": "furious", "text": "His seal. On the order that turned back the boats. He's stood behind my chair every day for nine years and told me what to think.", "next": "b"},
		"b": {"who": "hualing", "expr": "determined", "text": "Wu Jian is arrested as of tonight. The Censorate answers to me now. And the Fire Navy cut the rudder — the Fire Nation started this. Let the coast see what a queen can do when she finally knows the truth. You'll have lands for this. Ba Sing Se remembers its friends.",
			"do": [["call", "ending", "sold_earth"]]},
	}},
	"ms_sold_omashu": {"title": "Omashu", "start": "a", "nodes": {
		"a": {"who": "feng_tao", "expr": "surprised", "text": "Ba Sing Se's own seal. On this. Do you understand what you've brought me? Not a reason to fight — a reason nobody can ever again call Omashu traitors. The queen's regent killed the Avatar. Let every city in the Kingdom hear it.", "next": "b"},
		"b": {"who": "jiang_wei", "expr": "thoughtful", "text": "Feng. Breathe. Every city will hear it, and some of them will rise, and Ba Sing Se will burn them for it. …But yes. Thank you, {name}. Omashu will not forget.",
			"do": [["call", "ending", "sold_omashu"]]},
	}},
	"ms_sell_kuro": {"title": "The Admiral", "start": "a", "nodes": {
		"a": {"who": "kuro", "expr": "smirk", "text": "All six. Remarkable. You know, I never wanted the Avatar dead. I wanted the talks to fail politely. The sea had other ideas. The sea usually does.", "next": "b"},
		"b": {"who": "kuro", "expr": "neutral", "text": "Five thousand gold, and a letter of marque, and my friendship, which is worth more than both. Hand it over.", "choices": [
			{"text": "Hand it over.", "next": "c"},
			{"text": "\"…No. I've changed my mind.\"", "next": "d"},
		]},
		"c": {"who": "narrator", "text": "Kuro feeds the pages to a brazier one at a time, reading each before it burns. He seems, for a moment, almost sorry.",
			"do": [["call", "ending", "buried"]]},
		"d": {"who": "kuro", "expr": "angry", "text": "A pity. Then you'll leave my harbour quickly, and you'll sleep with one eye open for the rest of your short life.",
			"do": [["flag", "ms_path", ""], ["lord_rel", "kuro", -40], ["journal", "ms_main", "The Drowned Testament", "You refused Kuro's offer. Decide again what to do with the truth (open the logbook from the camp menu)."]]},
	}},
	"ms_kept": {"title": "For the Next Avatar", "start": "a", "nodes": {
		"a": {"who": "tsering", "expr": "tender", "text": "You came all this way to give it to a child who doesn't know they need it. Ten years old, somewhere, learning to swim or to read or to stop biting their sister. That is the most Nomad thing I have ever seen a non-Nomad do.", "next": "b"},
		"b": {"who": "tsering", "expr": "thoughtful", "text": "It will be kept. In five years a frightened child will be told what they are, and then they will be given this, and told it was carried by people who wanted nothing from it. The world won't change today. That's all right. The world is very rarely changed today.",
			"do": [["call", "ending", "kept"]]},
	}},
}
