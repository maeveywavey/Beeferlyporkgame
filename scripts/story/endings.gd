extends RefCounted
## The four endings of The Drowned Testament (plus burning it), their effects on
## the world, and the epilogue text assembled from everything the player did.

const Roster = preload("res://scripts/core/roster.gd")
const Terrain = preload("res://scripts/core/terrain.gd")

static func _story():
	return load("res://scripts/story/story.gd")

static func apply(kind: String) -> void:
	var S = _story()
	S.set_flag("ms_ended", true)
	S.set_flag("ending", kind)
	S.set_flag("ms_truth_decided", true)
	match kind:
		"told":
			S.set_flag("ending_told", true)
			S.set_flag("accord_day", GS.day())
			for a in Data.KINGDOMS:
				for b in Data.KINGDOMS:
					if a < b:
						GS.make_peace(a, b)
			GS.campaigns.clear()
			for f in Data.KINGDOMS:
				GS.change_faction_rel(f, 20)
			GS.add_renown(100)
			GS.player.honor = int(GS.player.get("honor", 0)) + 10
			_retire_lord("kuro")
			_retire_lord("wu_jian")
			_rebel_army("kuro_rebels", "fire_navy_harbor")
			_rebel_army("wu_loyalists", "ba_sing_se")
			S.journal("ms_main", "The Drowned Testament", "The Kyoshi Accord is signed. Admiral Kuro and Grand Secretary Wu Jian have fled to raise rebel armies. Defeat Kuro's Last Fleet and Wu Jian's Loyalists to secure the peace.")
			GS.log_msg("The Kyoshi Accord is signed. Every nation lays down its arms — except two men who have the most to lose.", Color(1, 0.9, 0.5))
			for cid in ["pemba", "nima", "hana", "juro", "kesi", "shen_mu", "ukiuk"]:
				S.change_approval(cid, 15)
			S.change_approval("reika", 10 if S.flag("reika_free") else 0)
		"sold_fire":
			_retire_lord("kuro")
			_join_as_lord("fire_nation")
			if not GS.at_war("fire_nation", "earth_kingdom"):
				GS.declare_war("fire_nation", "earth_kingdom")
			GS.sim._start_campaign("fire_nation", true)
			GS.change_faction_rel("earth_kingdom", -40)
			GS.add_gold(2000)
			_approvals({"juro": 5, "reika": 5, "pemba": -20, "nima": -10, "hana": -10, "kesi": -10, "shen_mu": -10})
			S.journal_done("ms_main", "You gave the logbook to Fire Lord Haoren. Kuro was hanged; the Fire Nation has a just war against Ba Sing Se, and you are a lord of the Fire Lord's house.")
			S.set_flag("pending_epilogue", kind)
		"sold_earth":
			_retire_lord("wu_jian")
			_join_as_lord("earth_kingdom")
			if not GS.at_war("fire_nation", "earth_kingdom"):
				GS.declare_war("fire_nation", "earth_kingdom")
			GS.sim._start_campaign("earth_kingdom", true)
			GS.change_faction_rel("fire_nation", -40)
			GS.add_gold(2000)
			_approvals({"hana": 10, "pemba": -15, "nima": -10, "juro": -15, "kesi": -10, "shen_mu": -5})
			S.journal_done("ms_main", "You gave the logbook to Earth Queen Hualing. Wu Jian is in a cell, the Dai Li answer to the Queen, and the Earth Kingdom carries the war to the Fire Nation with a clear conscience. You hold lands in her name.")
			S.set_flag("pending_epilogue", kind)
		"sold_omashu":
			_join_as_lord("omashu")
			if not GS.at_war("earth_kingdom", "omashu"):
				GS.declare_war("earth_kingdom", "omashu")
			GS.sim._start_campaign("omashu", true)
			GS.change_faction_rel("earth_kingdom", -40)
			GS.add_gold(1500)
			_approvals({"shen_mu": 10, "hana": -5, "pemba": -15, "nima": -10, "kesi": -5})
			S.journal_done("ms_main", "You gave the logbook to King Feng Tao. Omashu has the proof that Ba Sing Se's regent let the Avatar drown, and every rebel city in the Kingdom has heard it.")
			S.set_flag("pending_epilogue", kind)
		"buried":
			GS.add_gold(5000)
			GS.player.honor = int(GS.player.get("honor", 0)) - 10
			GS.change_lord_rel("kuro", 40)
			_approvals({"pemba": -50, "nima": -25, "hana": -20, "juro": -25, "kesi": -20, "shen_mu": -30, "ukiuk": -15, "reika": 5})
			S.journal_done("ms_main", "You sold the logbook to Admiral Kuro, and watched him burn it page by page. The war goes on. You are rich.")
			S.set_flag("pending_epilogue", kind)
		"burned":
			GS.player.honor = int(GS.player.get("honor", 0)) - 3
			_approvals({"pemba": -20, "nima": -10, "hana": -10, "juro": -10, "kesi": -10, "shen_mu": -15})
			S.journal_done("ms_main", "You burned the logbook. Nobody will ever know what happened on the Lantern. You will.")
			S.set_flag("pending_epilogue", kind)
		"kept":
			GS.change_faction_rel("air_nomads", 40)
			GS.player.honor = int(GS.player.get("honor", 0)) + 5
			_approvals({"pemba": 30, "nima": 10, "hana": 10, "juro": 10, "kesi": 10, "shen_mu": 15, "ukiuk": 10, "reika": -5})
			S.journal_done("ms_main", "You gave the logbook to Abbess Tsering, to be kept for the next Avatar. The world did not change today.")
			S.set_flag("pending_epilogue", kind)

static func _approvals(d: Dictionary) -> void:
	var S = _story()
	for cid in d:
		S.change_approval(cid, int(d[cid]))

## A lord removed from play (disgraced, executed or fled).
static func _retire_lord(lid: String) -> void:
	var lr: Dictionary = GS.lords[lid]
	if lr.party != "" and GS.parties.has(lr.party):
		GS.sim.remove_party(lr.party)
	lr.party = ""
	lr.respawn_at = INF
	lr.retired = true
	for sid in GS.settlements:
		if GS.settlements[sid].owner == lid:
			var others: Array = GS.faction_lords(GS.settlements[sid].faction).filter(func(x): return x != lid and not GS.lords[x].get("retired", false))
			GS.settlements[sid].owner = others.pick_random() if not others.is_empty() else ""

static func _rebel_army(sp_id: String, near: String) -> void:
	var S = _story()
	var pid: String = S.spawn(sp_id)
	if pid == "" or not GS.parties.has(pid):
		return
	var p: Dictionary = GS.parties[pid]
	p.pos = Terrain.random_land_near(Data.settlements[near].pos, 40.0)
	p.anchor = p.pos
	p.target_party = ""
	p.moving = false
	p.state = "idle"
	p.speed_mult = 0.8

## The player becomes a landed lord of a kingdom as a reward.
static func _join_as_lord(f: String) -> void:
	GS.player.faction = f
	GS.player.status = "vassal"
	GS.player.wars = []
	GS.change_faction_rel(f, 40)
	GS.raise_standing("noble")
	var opts := []
	for sid in GS.settlements:
		var d: Dictionary = Data.settlements[sid]
		if GS.settlements[sid].faction == f and d.type == "castle" and GS.settlements[sid].owner != "player":
			opts.append(sid)
	if opts.is_empty():
		for sid in GS.settlements:
			if GS.settlements[sid].faction == f and Data.settlements[sid].type == "village":
				opts.append(sid)
	if not opts.is_empty():
		var sid: String = opts.pick_random()
		GS.settlements[sid].owner = "player"
		GS.log_msg("You have been granted %s." % Data.settlements[sid].name, Color(1, 0.9, 0.4))

# ---------------------------------------------------------------------------
# Epilogue text
# ---------------------------------------------------------------------------
const WORLD := {
	"told": "The Kyoshi Accord holds. Not perfectly — treaties never do — but the Ember Coast ports are shared, the Fire Nation eats from Omashu's granaries, and Ba Sing Se's gates open a little wider every year. In the tea houses they still argue about who killed the Avatar. Now they argue with the facts.",
	"sold_fire": "The Fire Nation wins its just war. The coast is Fire Nation for a generation, and Ba Sing Se's walls hold, barely. Historians will call it the War of the Boats. Very few of them will mention that both sides were guilty, because the winners kept the pages that said so.",
	"sold_earth": "Queen Hualing rules in her own name at last, and rules well. The Dai Li are disbanded and refounded, smaller. The war on the coast drags on for six more years, fought with the clearest conscience in the world, which is the most dangerous kind.",
	"sold_omashu": "Omashu's proof spreads through the Kingdom like a crack through ice. Three cities rise; two are burned. Omashu stands. Feng Tao makes the longest speech in its history. In Ba Sing Se, they will call you the one who broke the Kingdom. In Omashu, your name is carved on the stairs.",
	"buried": "The war goes on. It will go on for a long time — long enough that the child who is the Avatar will inherit it whole, and spend their life trying to end what you were paid to let continue. You live comfortably. People who knew you before do not visit.",
	"burned": "Nobody will ever know what happened on the Lantern. Every few years someone claims to have found the logbook, and it is always a forgery. You never correct them. Some nights you dream of handwriting curling brown in a fire.",
	"kept": "The world does not change, not that year. The wars run their course; some end, some don't. Five years later, in a cold temple, a frightened sixteen-year-old is told what they are — and then handed six pages wrapped in oilcloth, and told they were carried by people who wanted nothing from them. They read the last page aloud.",
}

static func epilogue_text(kind: String) -> String:
	var S = _story()
	var out := "[b]The World[/b]\n%s\n" % WORLD.get(kind, "")
	var lines := []
	var seen := []
	for cid in Data.companions:
		if GS.player.companions.has(cid) or S.flag("joined_" + cid, false):
			seen.append(cid)
	for cid in seen:
		var t := _companion_line(cid, GS.player.companions.has(cid))
		if t != "":
			lines.append("[b]%s[/b] — %s" % [Data.companions[cid].get("short", cid), t])
	if not lines.is_empty():
		out += "\n[b]The People You Travelled With[/b]\n" + "\n\n".join(lines) + "\n"
	if S.flag("refugees_betrayed"):
		out += "\nThe monks rebuilt their mountain road, further east. They never learned who sold it. They prayed for that person anyway.\n"
	if S.flag("ms_norbu_saved"):
		out += "\nBrother Norbu lived to be very old, and told the story of the night a stranger stood between him and the daofei so often that it grew to include a dragon. You did not correct him.\n"
	elif S.flag("ms_norbu_dead"):
		out += "\nUnder a pine by the road, there is a small cairn. Novices from the Eastern Temple leave fruit there every spring. One of them, every year, tells the joke about the bison and the bell tower.\n"
	return S.fmt(out)

static func _companion_line(cid: String, stayed: bool) -> String:
	var S = _story()
	var f = func(k): return S.flag(k)
	if not stayed and not S.flag(cid + "_done"):
		return "left your company before the end. You heard of them sometimes, in rumours, always somewhere far away."
	match cid:
		"hana":
			if f.call("hana_spared"):
				return "finished the map: three hundred and twelve sheets. The last one is the tunnel in Wenlong, drawn open. %s" % ("She drew you on every sheet after that, very small, in the corner." if f.call("romance_hana") else "She keeps it on the wall where she can see it from bed.")
			if f.call("hana_exposed"):
				return "testified at Bo Lai's trial in a voice that never once rose. The Dai Li never sealed another tunnel with someone inside. She checks."
			if f.call("hana_killed"):
				return "never went back to the Wenlong district. She still counts birds when the world is too loud. It helps a little."
			return "went back to the Lower Ring and her map. She never found Bo Lai. She stopped looking, eventually, and was surprised how much lighter it felt."
		"juro":
			if f.call("juro_lantern"):
				return "goes back to Tieshan every autumn for the lantern festival. Mi-sun never forgives him. Every year, she hands him her lantern to light."
			if f.call("juro_fire"):
				return "builds bridges now, the kind that hold. His fire is small and blue at the heart, and he mostly uses it to light his father's kiln."
			return "never got his fire back. He built the Accord's first shared harbour on the Ember Coast instead, and it's still standing."
		"pemba":
			if f.call("dawa_free"):
				return "writes to Dawa every month. The Lower Ring eats a little better every year, and a Red Lantern sometimes leaves rice at the temple gate with no note."
			if f.call("dawa_home"):
				return "and Dawa argue with Abbot Dorje every day. The Southern Temple now runs the largest soup kitchen in the world. Dawa calls it 'a start'."
			if f.call("dawa_turned_in"):
				return "returned to the Southern Temple alone. They visit Dawa in prison twice a year. They do not visit you."
			return "went home to the bison, and never found Dawa. They still set an extra bowl out at dinner."
		"nima":
			if f.call("two_paths"):
				return "trained the first Moon Guard. Kaya joined it at sixteen, loudly. Master Aklaq taught her the reversal himself, and was heard to say she was better than her mother. Nima agrees, smugly."
			if f.call("nima_south"):
				return "raised Kaya in the South, where she learned to fight and heal and argue in council. The North changed its law twenty years later. Kaya went back to see it happen."
			if f.call("nima_lost"):
				return "lost the duel but won the argument, slowly. Aklaq took Kaya as a student the next winter. The law fell nine years later, without a fight."
			return "went home to Kaya, and never stopped training at night."
		"ukiuk":
			if f.call("ukiuk_confessed"):
				return "eats at Kimi's noodle stall every time he passes Shu Jing. She still calls him 'harpoon'. He built her a new roof. %s" % ("He built you a boat with both your names on it." if f.call("romance_ukiuk") else "He builds boats now. Only boats.")
			return "kept sending money to Shu Jing, unsigned, for the rest of his life."
		"shen_mu":
			if f.call("shenmu_lin"):
				return "and Lin opened a courier post in Omashu. It has never lost a letter. The sign over the door is in storm-sign as well as script, because Kesi insisted."
			if f.call("letter_delivered"):
				return "became master of the chute-couriers. He still doesn't read the letters."
			return "kept running routes. Somewhere, in a drawer, a letter he could not deliver is still sealed."
		"reika":
			if f.call("reika_free"):
				return "found Rin again, eventually. Two captains, one deck. %s" % ("Three captains, actually, after a while. It was crowded. Nobody minded." if f.call("romance_reika") else "Terrible idea. Best years of their lives.")
			if f.call("reika_kept"):
				return "got rich. She bought a bigger ship and a bigger hat and never seemed to enjoy either."
			return "sailed off with a new letter of marque from someone. She sends postcards. They are mostly insults."
		"kesi":
			if f.call("kesi_swamp"):
				return "and her clan live in the Foggy Swamp now. They complain about the damp every day. Their children learn storm-sign and swampbending both."
			if f.call("kesi_wells"):
				return "guides caravans through the Si Wong. The raids stopped. Her clan signs her name-sign at every meeting."
			if f.call("kesi_fought"):
				return "is a legend among the sand clans and a wanted woman in the Earth Kingdom. She finds both very funny."
			return "went back to the dunes. Her clan took her back, quietly, without ever saying so."
	return ""
