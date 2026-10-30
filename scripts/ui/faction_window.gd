extends "res://scripts/ui/window_base.gd"
## The Factions menu: every power, clan, tribe, temple and community in the
## world, grouped by region; the people you are connected to; and the wars and
## tribute that bind them. Opened from the world map (N).

const Roster = preload("res://scripts/core/roster.gd")
const Fealty = preload("res://scripts/core/fealty.gd")
const AvatarSys = preload("res://scripts/core/avatar.gd")
const Story = preload("res://scripts/story/story.gd")
const MoonCouncil = preload("res://scripts/core/moon_council.gd")

var map
var tab := "factions"
var selected := "fire_nation"
var show_society := false
var note := ""

func _init() -> void:
	window_size = Vector2(1200, 670)

func build() -> void:
	set_title("Factions")
	var tabs := UI.hbox()
	content.add_child(tabs)
	for t in [["factions", "Factions (%d)" % _listed().size()], ["people", "People"], ["wars", "Wars and Tribute"], ["council", "Moon Council"]]:
		var b := UI.button(t[1], func():
			tab = t[0]
			note = ""
			refresh(), 200)
		if tab == t[0]:
			UI.mark_selected(b)
		tabs.add_child(b)
	tabs.add_child(UI.expand())
	tabs.add_child(UI.button("The Avatar", _open_avatar, 160))
	tabs.add_child(UI.button("Done", close, 120))
	match tab:
		"factions": _build_factions()
		"people": _build_people()
		"wars": _build_wars()
		"council": _build_council()

func _open_avatar() -> void:
	var w = load("res://scripts/ui/avatar_window.gd").new()
	w.map = map
	if map != null and map.has_method("open_window"):
		map.open_window(w)
	else:
		get_parent().add_child(w)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
## Every faction the menu lists, in region order.
func _listed() -> Array:
	var out := []
	if not GS.faction_settlements("player").is_empty() or not Fealty.tributaries("player").is_empty():
		out.append("player")
	for r in Data.REGIONS:
		out.append_array(_in_region(r[0]))
	return out

func _in_region(region: String) -> Array:
	var powers := []
	var others := []
	for f in Data.factions:
		if Data.region_of(f) != region or f == "player":
			continue
		if f in Data.KINGDOMS:
			powers.append(f)
		else:
			others.append(f)
	# powers by strength, then temples and communities by name
	powers.sort_custom(func(a, b): return Fealty.strength(a) > Fealty.strength(b))
	others.sort_custom(func(a, b): return Data.factions[a].name < Data.factions[b].name)
	if region == "air":
		others.erase("air_nomads")
		others.push_front("air_nomads")
	return powers + others

static func standing_word(rel: int) -> String:
	if rel >= 40:
		return "devoted"
	if rel >= 15:
		return "friendly"
	if rel > -10:
		return "neutral"
	if rel > -40:
		return "hostile"
	return "hateful"

func _rel_text(rel: int) -> String:
	var c: Color = UI.GREEN if rel >= 15 else (UI.RED if rel <= -10 else UI.INK)
	return UI.color_text("%+d (%s)" % [rel, standing_word(rel)], c)

## Who leads a faction: a lord's name, or the head named in the data.
func _leader(f: String) -> String:
	var fd: Dictionary = Data.factions[f]
	if f == "player":
		return GS.player.name
	var king: String = fd.get("king", "")
	if Data.lords.has(king):
		return Data.lords[king].name
	return fd.get("head", "")

func _lord_where(lid: String) -> String:
	var lr: Dictionary = GS.lords[lid]
	if lr.get("retired", false):
		return "retired"
	if lr.get("held", false) or GS.player.get("captive_lords", []).has(lid):
		return "your prisoner"
	if lr.party != "" and GS.parties.has(lr.party):
		var p: Dictionary = GS.parties[lr.party]
		if p.get("besieging", "") != "":
			return "besieging " + Data.settlements[p.besieging].name
		return "near " + GS.sim._nearest_settlement_name(p.pos)
	return "recovering from defeat"

func _swatch(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.custom_minimum_size = Vector2(UI.px(12), UI.px(12))
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r

# ---------------------------------------------------------------------------
# Factions tab
# ---------------------------------------------------------------------------
func _build_factions() -> void:
	if not Data.factions.has(selected):
		selected = "fire_nation"
	var cols := UI.hbox(18)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)
	# The list
	var lsc := UI.scroll(640)
	lsc.custom_minimum_size.x = 600
	cols.add_child(lsc)
	var list := UI.vbox(2)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lsc.add_child(list)
	if _listed().has("player"):
		list.add_child(UI.label("Your realm", 18, UI.BROWN))
		list.add_child(_faction_row("player"))
	for r in Data.REGIONS:
		list.add_child(UI.spacer(4))
		list.add_child(UI.label(r[1], 18, UI.BROWN))
		for f in _in_region(r[0]):
			list.add_child(_faction_row(f))
	# The detail
	var dsc := UI.scroll(640)
	dsc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(dsc)
	var detail := UI.vbox(6)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dsc.add_child(detail)
	if show_society:
		_build_society(detail)
	else:
		_build_detail(detail)

func _faction_row(f: String) -> Control:
	var fd: Dictionary = Data.factions[f]
	var row := UI.hbox(8)
	row.add_child(_swatch(fd.color))
	var tags := []
	if f != "player" and GS.at_war(GS.player_faction(), f):
		tags.append("at war")
	if Fealty.overlord(f) == "player":
		tags.append("pays you")
	elif Fealty.overlord(f) != "":
		tags.append("→ " + Data.factions[Fealty.overlord(f)].short)
	if fd.get("community", false) and GS.faction_settlements(f).is_empty():
		tags.append("taken")
	var indent := "    " if fd.get("community", false) or fd.has("people") else ""
	var txt := "%s%s  ·  %s" % [indent, fd.short, fd.get("kind", "")]
	if not tags.is_empty():
		txt += "  [" + ", ".join(tags) + "]"
	var b := UI.option(txt, func():
		selected = f
		show_society = false
		note = ""
		refresh())
	if f == selected:
		UI.mark_selected(b)
	row.add_child(b)
	return row

func _build_detail(o: VBoxContainer) -> void:
	var f := selected
	var fd: Dictionary = Data.factions[f]
	var pf := GS.player_faction()
	var head := UI.hbox(10)
	head.add_child(_swatch(fd.color))
	head.add_child(UI.label(fd.name, 24, UI.BROWN))
	o.add_child(head)
	var lines := []
	var leader := _leader(f)
	var kind: String = fd.get("kind", "")
	if leader != "":
		lines.append("[b]%s[/b], led by %s" % [kind, leader])
	elif kind != "":
		lines.append("[b]%s[/b]" % kind)
	var seat: String = fd.get("capital", "")
	if seat != "" and GS.settlements.has(seat):
		var held: String = GS.settlements[seat].faction
		lines.append("Seat: %s%s" % [Data.settlements[seat].name, "" if held == f else UI.color_text("  (held by the %s)" % Data.factions.get(held, Data.factions.neutral).name, UI.RED)])
	o.add_child(UI.rich("\n".join(lines), 820))
	o.add_child(UI.rich("[i]%s[/i]" % fd.desc, 820))
	if note != "":
		o.add_child(UI.rich(note, 820))
	# Standing and ties
	var ties := []
	if f != "player":
		var rel := GS.faction_rel(f)
		var st := "Your standing: %s" % _rel_text(rel)
		if fd.has("people"):
			st += "  [i](includes your standing with the %s)[/i]" % Data.factions[fd.people].name
		if GS.at_war(pf, f):
			st += "  —  " + UI.color_text("at war with you", UI.RED)
		elif pf == f:
			st += "  —  " + UI.color_text("you serve it as %s" % GS.player.get("status", "a vassal"), UI.GREEN)
		ties.append(st)
	var ov := Fealty.overlord(f)
	if ov != "":
		ties.append("Pays tribute to %s (about %d gold a week)." % ["you" if ov == "player" else "the " + Data.factions[ov].name, Fealty.tribute_of(f)])
	var tribs := Fealty.tributaries(f)
	if not tribs.is_empty():
		var names := tribs.map(func(t): return Data.factions[t].name)
		ties.append("Receives tribute from %s." % ", ".join(names))
	var wars := []
	for o2 in Data.factions:
		if o2 != f and not o2 in ["player", "neutral", "bandits", "avatar"] and GS.relations.get(GS._rel_key(f, o2), "") == "war":
			wars.append(Data.factions[o2].name)
	if f != "player" and pf == "player" and GS.at_war("player", f):
		wars.append("you")
	if f in ["bandits", "red_lanterns"]:
		wars = ["everyone who carries coin" if f == "bandits" else "the Earth Kingdom's tax barges"]
	if Data.is_peaceful(f):
		ties.append("At war with nobody, ever.")
	else:
		ties.append("At war with: %s" % (", ".join(wars) if not wars.is_empty() else "nobody"))
	var camp: Dictionary = GS.campaigns.get(f, {})
	if not camp.is_empty():
		ties.append("Campaigning against %s." % Data.settlements[camp.target].name)
	if f in Data.KINGDOMS:
		ties.append("Strength: about %d fighters in the field and on the walls." % Fealty.strength(f))
	if fd.get("protected", false):
		ties.append(UI.color_text("Its city is defended by dragons. No sane ruler marches on it.", UI.GOLD))
	o.add_child(UI.rich("\n".join(ties), 820))
	_build_actions(o, f)
	# Lords
	var flords := GS.faction_lords(f).filter(func(l): return not GS.lords[l].get("retired", false))
	if not flords.is_empty():
		o.add_child(UI.spacer(4))
		o.add_child(UI.label("Lords", 19, UI.BROWN))
		for lid in flords:
			var lr: Dictionary = GS.lords[lid]
			var troops := 0
			if lr.party != "" and GS.parties.has(lr.party):
				troops = Roster.total(GS.parties[lr.party].roster)
			var crown := "  (head)" if GS.is_king(lid) else ""
			var known := "" if lr.get("met", false) else "  · not met"
			var l := UI.rich("[b]%s[/b]%s — %d troops, %s. Relation %s%s" % [Data.lords[lid].name, crown, troops, _lord_where(lid), _rel_text(int(lr.relation)), known], 820)
			l.tooltip_text = Data.lords[lid].get("bio", "")
			o.add_child(l)
	# Lands
	var lands := GS.faction_settlements(f)
	if not lands.is_empty():
		o.add_child(UI.spacer(4))
		o.add_child(UI.label("Lands", 19, UI.BROWN))
		var g := UI.grid(4, 18, 2)
		o.add_child(g)
		for sid in lands:
			var s: Dictionary = GS.settlements[sid]
			var d: Dictionary = Data.settlements[sid]
			var status := ""
			if not s.siege.is_empty():
				status = UI.color_text("besieged", UI.RED)
			elif s.looted_until > GS.hours:
				status = UI.color_text("burned", UI.RED)
			var holder: String = "you" if s.owner == "player" else (Data.lords[s.owner].name if Data.lords.has(s.owner) else "")
			g.add_child(UI.label(d.name, 15))
			g.add_child(UI.label(d.type.capitalize(), 15, UI.BROWN_LIGHT))
			g.add_child(UI.label(holder, 15, UI.BROWN_LIGHT))
			g.add_child(UI.rich(status if status != "" else "prosperity %d" % int(s.prosperity), 160))
	elif f != "player" and not f in ["bandits", "red_lanterns", "air_nomads"]:
		o.add_child(UI.rich(UI.color_text("It holds no land.", UI.RED), 600))
	# Society
	if _society_of(f) != "":
		o.add_child(UI.spacer(4))
		o.add_child(UI.button("How this people lives", func():
			show_society = true
			refresh(), 260))

## The society entry that describes a faction's people.
func _society_of(f: String) -> String:
	if Data.societies.has(f):
		return f
	var by_region := {"fire": "fire_nation", "earth": "earth_kingdom", "air": "air_nomads"}
	var r := Data.region_of(f)
	if r == "water":
		var c: String = Data.factions[f].culture
		return "northern_water" if c == "north" else "southern_water"
	return by_region.get(r, "")

func _build_society(o: VBoxContainer) -> void:
	var key := _society_of(selected)
	var soc: Dictionary = Data.societies.get(key, {})
	o.add_child(UI.label(Data.factions[selected].name, 24, UI.BROWN))
	if key != selected:
		o.add_child(UI.rich("[i]As among the %s:[/i]" % Data.factions[key].name, 820))
	var stxt := "[b]Society[/b]\n%s\n\n[b]Order of precedence[/b]\n" % soc.text
	for i in soc.ladder.size():
		stxt += "%d. %s\n" % [i + 1, soc.ladder[i]]
	stxt += "\n[b]What this means for you[/b]\n%s\n\nYour standing: [b]%s[/b] — %s" % [soc.rules, GS.standing_name(), GS.STANDING_DESC[GS.standing()]]
	o.add_child(UI.rich(stxt, 820))
	o.add_child(UI.button("Back to the faction", func():
		show_society = false
		refresh(), 260))

## War and peace, for a player who answers to no one.
func _build_actions(o: VBoxContainer, f: String) -> void:
	if f in ["player", "neutral", "avatar", "air_nomads"] or Data.is_peaceful(f):
		return
	if GS.player_faction() != "player":
		if GS.player_faction() != f:
			o.add_child(UI.rich("[i]You fight the wars of the %s; war and peace are its to declare.[/i]" % Data.factions[GS.player_faction()].name, 820))
		return
	var row := UI.hbox(8)
	o.add_child(row)
	if f in ["bandits", "red_lanterns"]:
		return
	if GS.at_war("player", f):
		var cost := _peace_cost(f)
		var willing := GS.faction_rel(f) > -60
		row.add_child(UI.button("Offer peace (%d gold)" % cost, func():
			GS.add_gold(-cost)
			GS.make_peace("player", f)
			GS.log_msg("You make peace with the %s." % Data.factions[f].name, Color(0.6, 0.9, 1))
			note = "Envoys exchange gifts and promises. Peace, for now."
			refresh(), 240, willing and GS.player.gold >= cost))
		if not willing:
			row.add_child(UI.label("They hate you too much to talk.", 15, UI.RED))
	else:
		row.add_child(UI.button("Declare war", func():
			GS.declare_war("player", f)
			GS.change_faction_rel(f, -20)
			if GS.faction_rel(f) > 0:
				GS.player.honor = int(GS.player.get("honor", 0)) - 2
			Fealty.protect(f, "player")
			GS.log_msg("You declare war on the %s." % Data.factions[f].name, Color(1, 0.45, 0.3))
			note = UI.color_text("You are at war with the %s." % Data.factions[f].name, UI.RED)
			refresh(), 200))
	if Fealty.overlord(f) == "player":
		row.add_child(UI.button("Release from tribute", func():
			Fealty.release(f)
			refresh(), 240))

func _peace_cost(f: String) -> int:
	return 100 + Fealty.strength(f) * 2 + maxi(0, -GS.faction_rel(f)) * 5

# ---------------------------------------------------------------------------
# People tab
# ---------------------------------------------------------------------------
func _build_people() -> void:
	var sc := UI.scroll(640)
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(sc)
	var o := UI.vbox(4)
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(o)
	# Companions
	o.add_child(UI.label("Your companions", 19, UI.BROWN))
	var comps: Array = GS.player.get("companions", [])
	if comps.is_empty():
		o.add_child(UI.rich("[i]Nobody travels with you yet. Taverns are where people looking for work drink.[/i]", 1200))
	for cid in comps:
		var cd: Dictionary = Data.companions.get(cid, {})
		var name: String = cd.get("name", AvatarSys.display_name().capitalize() if cid == "avatar" else String(cid).capitalize())
		var ap := Story.approval(cid)
		var wounded: bool = GS.companion_state(cid).get("wounded", false)
		var l := UI.rich("[b]%s[/b] — approval %s%s" % [name, _rel_text(ap), UI.color_text("  · wounded", UI.RED) if wounded else ""], 1200)
		l.tooltip_text = cd.get("bio", "")
		o.add_child(l)
	# The Avatar
	if AvatarSys.known():
		var A: Dictionary = AvatarSys.state()
		o.add_child(UI.spacer(6))
		o.add_child(UI.label("The Avatar", 19, UI.BROWN))
		o.add_child(UI.rich("[b]%s[/b] — %s; regards you %s" % [AvatarSys.display_name().capitalize(), AvatarSys.stage(), _rel_text(int(A.get("attitude", 0)))], 1200))
	# Lords you have met, or who have an opinion of you
	o.add_child(UI.spacer(6))
	o.add_child(UI.label("Lords you know", 19, UI.BROWN))
	var known := []
	for lid in GS.lords:
		var lr: Dictionary = GS.lords[lid]
		if lr.get("met", false) or int(lr.relation) != 0 or GS.player.get("captive_lords", []).has(lid):
			known.append(lid)
	known.sort_custom(func(a, b): return int(GS.lords[a].relation) > int(GS.lords[b].relation))
	if known.is_empty():
		o.add_child(UI.rich("[i]You have not yet spoken with any lord. Seek them in their halls, or meet their armies on the road.[/i]", 1200))
	var g := UI.grid(4, 22, 3)
	o.add_child(g)
	for lid in known:
		var lr: Dictionary = GS.lords[lid]
		var nl := UI.label(Data.lords[lid].name, 16)
		nl.tooltip_text = Data.lords[lid].get("bio", "")
		nl.mouse_filter = Control.MOUSE_FILTER_PASS
		g.add_child(nl)
		g.add_child(UI.label(Data.factions[lr.faction].short + (" (head)" if GS.is_king(lid) else ""), 15, Data.factions[lr.faction].color.lightened(0.35)))
		g.add_child(UI.rich(_rel_text(int(lr.relation)), 200))
		g.add_child(UI.label(_lord_where(lid), 15, UI.BROWN_LIGHT))
	# Heads you know only by name
	o.add_child(UI.spacer(6))
	o.add_child(UI.label("Rulers and elders you know only by name", 19, UI.BROWN))
	var names := []
	for f in Data.factions:
		var king: String = Data.factions[f].get("king", "")
		if Data.lords.has(king) and not GS.lords[king].get("met", false) and not known.has(king):
			names.append("%s (%s)" % [Data.lords[king].name, Data.factions[f].short])
		elif Data.factions[f].get("head", "") != "" and not Data.lords.has(king):
			names.append("%s (%s)" % [Data.factions[f].head.capitalize() if Data.factions[f].head.begins_with("the") else Data.factions[f].head, Data.factions[f].short])
	o.add_child(UI.rich(", ".join(names) + ".", 1200))

# ---------------------------------------------------------------------------
# Wars and tribute tab
# ---------------------------------------------------------------------------
func _build_wars() -> void:
	var cols := UI.hbox(24)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)
	var lsc := UI.scroll(640)
	lsc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(lsc)
	var left := UI.vbox(3)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lsc.add_child(left)
	left.add_child(UI.label("Wars being fought", 19, UI.BROWN))
	var wars := []
	for k in GS.relations:
		if GS.relations[k] != "war":
			continue
		var ab: PackedStringArray = k.split("|")
		if ab.size() == 2 and Data.factions.has(ab[0]) and Data.factions.has(ab[1]):
			var since: int = int(GS.flags.get("rel_since_" + k, GS.flags.get("rel_since_" + ab[1] + "|" + ab[0], 0)))
			wars.append([ab[0], ab[1], GS.day() - since])
	wars.sort_custom(func(a, b): return a[2] > b[2])
	for w in wars:
		left.add_child(UI.rich("%s  against  %s  [i](%d days)[/i]" % [_coloured(w[0]), _coloured(w[1]), w[2]], 700))
	if GS.player_faction() == "player":
		for f in GS.player.get("wars", []):
			if Data.factions.has(f):
				left.add_child(UI.rich("You  against  %s" % _coloured(f), 700))
	if wars.is_empty():
		left.add_child(UI.rich("[i]The world is at peace, for the moment.[/i]", 700))
	left.add_child(UI.spacer(6))
	left.add_child(UI.label("Campaigns under way", 19, UI.BROWN))
	if GS.campaigns.is_empty():
		left.add_child(UI.rich("[i]No army is marching on a city.[/i]", 700))
	for f in GS.campaigns:
		left.add_child(UI.rich("%s marches on %s" % [_coloured(f), Data.settlements[GS.campaigns[f].target].name], 700))
	# the chronicle: world news, including what the message log left out
	var chron: Array = GS.flags.get("chronicle", [])
	if not chron.is_empty():
		left.add_child(UI.spacer(6))
		left.add_child(UI.label("Chronicle", 19, UI.BROWN))
		var lines := []
		for i in range(chron.size() - 1, maxi(-1, chron.size() - 31), -1):
			lines.append("[i]Day %d.[/i] %s" % [int(chron[i].d), chron[i].t])
		left.add_child(UI.rich("\n".join(lines), 700))
	var rsc := UI.scroll(640)
	rsc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(rsc)
	var right := UI.vbox(3)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsc.add_child(right)
	right.add_child(UI.label("Tribute", 19, UI.BROWN))
	right.add_child(UI.rich("[i]Tributaries pay for the right to trade under an overlord's seal and to call on its armies. An overlord answers any attack on a tributary as an attack on itself.[/i]", 700))
	var overlords := {}
	for t in GS.fealty:
		var ov: String = GS.fealty[t]
		if not overlords.has(ov):
			overlords[ov] = []
		overlords[ov].append(t)
	for ov in overlords:
		var names: Array = overlords[ov].map(func(t): return Data.factions[t].name)
		var who := "You" if ov == "player" else _coloured(ov)
		right.add_child(UI.rich("[b]%s[/b] ← %s" % [who, ", ".join(names)], 700))
	var free := []
	for f in Data.factions:
		if Data.factions[f].get("community", false) and Fealty.overlord(f) == "" and not GS.faction_settlements(f).is_empty():
			free.append(Data.factions[f].name)
	right.add_child(UI.spacer(6))
	right.add_child(UI.label("Free communities", 19, UI.BROWN))
	right.add_child(UI.rich(", ".join(free) + "." if not free.is_empty() else "[i]None: every village pays someone.[/i]", 700))
	var taken := []
	for sid in Data.settlements:
		var d: Dictionary = Data.settlements[sid]
		if d.has("community") and GS.settlements[sid].faction != sid:
			taken.append("%s (held by %s)" % [d.name, "you" if GS.settlements[sid].faction == "player" else Data.factions.get(GS.settlements[sid].faction, Data.factions.neutral).short])
	if not taken.is_empty():
		right.add_child(UI.spacer(6))
		right.add_child(UI.label("Communities taken by force", 19, UI.BROWN))
		right.add_child(UI.rich(", ".join(taken) + ".", 700))

func _coloured(f: String) -> String:
	return UI.color_text(Data.factions[f].name, Data.factions[f].color.lightened(0.4))

# ---------------------------------------------------------------------------
# Moon Council tab
# ---------------------------------------------------------------------------
func _build_council() -> void:
	var st := MoonCouncil.state()
	var sc := UI.scroll(640)
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(sc)
	var o := UI.vbox(5)
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(o)
	var c := MoonCouncil.chief()
	var years := int((GS.day() - int(st.since)) / 365)
	var held := "for %d year%s" % [years, "" if years == 1 else "s"] if years > 0 else "since this year"
	var who := "You" if c == "player" else "%s of the %s" % [MoonCouncil.chief_name(), Data.factions.get(c, Data.factions.neutral).name]
	o.add_child(UI.label(MoonCouncil.TITLE, 24, UI.BROWN))
	o.add_child(UI.rich("[b]%s[/b], %s.\nThe council next sits at the first full moon after day %d (today is day %d)." % [who, held, int(st.next), GS.day()], 1400))
	o.add_child(UI.rich("[i]The Water Tribes are many small tribes on the ice, in the fens and on the islands, each governing itself. Seven electors choose a High Chief from among the great tribes' chiefs. The High Chief rules no one directly; the office brings a tithe from the free tribes, the duty to protect them, and the right to call the tribes to war, which they may or may not answer.[/i]", 1400))
	if note != "":
		o.add_child(UI.rich(note, 1400))
	# Candidates
	o.add_child(UI.spacer(4))
	o.add_child(UI.label("Candidates, and the votes they would win today", 19, UI.BROWN))
	var t := MoonCouncil.tally()
	var row := UI.hbox(10)
	o.add_child(row)
	for cand in MoonCouncil.candidates():
		var nm: String = "You" if cand == "player" else Data.factions[cand].short
		var b := UI.button("%s — %d" % [nm, int(t.get(cand, 0))], func():
			MoonCouncil.set_backing(cand)
			note = "You back %s at the next council." % ("yourself" if cand == "player" else Data.factions[cand].name)
			refresh(), 0)
		if MoonCouncil.backing() == cand:
			UI.mark_selected(b)
		b.tooltip_text = "Back this candidate: your gifts to electors will speak for them."
		row.add_child(b)
	if not MoonCouncil.player_eligible():
		o.add_child(UI.rich("[i](You may stand yourself once you rule a Water Tribes town or castle in your own name and have 250 renown.)[/i]", 1400))
	# Electors
	o.add_child(UI.spacer(4))
	o.add_child(UI.label("Electors", 19, UI.BROWN))
	if MoonCouncil.backing() == "":
		o.add_child(UI.rich("[i]Back a candidate above, then send electors gifts on their behalf. Gifts need a realm of your own: a vassal's lord does the lobbying.[/i]", 1400))
	var lean := MoonCouncil.leanings()
	var g := UI.grid(4, 24, 4)
	o.add_child(g)
	for e in MoonCouncil.electors():
		var fd: Dictionary = Data.factions[e]
		g.add_child(UI.label(fd.name, 16, fd.color.lightened(0.4)))
		var to: String = lean.get(e, "")
		g.add_child(UI.label("leans to " + ("you" if to == "player" else Data.factions.get(to, Data.factions.neutral).short), 15))
		g.add_child(UI.rich("standing " + _rel_text(GS.faction_rel(e)), 260))
		var back := MoonCouncil.backing()
		var can: bool = back != "" and GS.player_faction() == "player" and not GS.at_war("player", e)
		g.add_child(UI.button("Send gifts (%d gold)" % MoonCouncil.lobby_cost(e), func():
			note = MoonCouncil.lobby(e)
			refresh(), 0, can and GS.player.gold >= MoonCouncil.lobby_cost(e)))
	var last: Dictionary = st.get("last_votes", {})
	if not last.is_empty():
		o.add_child(UI.spacer(4))
		o.add_child(UI.label("How they voted last time", 19, UI.BROWN))
		var lines := []
		for e in last:
			if Data.factions.has(e):
				lines.append("%s for %s" % [Data.factions[e].short, "you" if last[e] == "player" else Data.factions.get(last[e], Data.factions.neutral).short])
		o.add_child(UI.rich(", ".join(lines) + ".", 1400))
	# The tribes
	o.add_child(UI.spacer(4))
	o.add_child(UI.label("The tribes of the confederation", 19, UI.BROWN))
	var free := []
	var bound := []
	for f in Data.factions:
		if Data.region_of(f) != "water" or GS.faction_settlements(f).is_empty():
			continue
		var ov := Fealty.overlord(f)
		if ov != "":
			bound.append("%s (pays %s)" % [Data.factions[f].short, "you" if ov == "player" else Data.factions[ov].short])
		elif Data.factions[f].get("community", false):
			free.append(Data.factions[f].short)
	o.add_child(UI.rich("[b]Free tribes under the High Chief's protection:[/b] %s.\n[b]Tribes paying a great tribe:[/b] %s." % [", ".join(free) if not free.is_empty() else "none", ", ".join(bound) if not bound.is_empty() else "none"], 1400))
