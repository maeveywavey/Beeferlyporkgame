extends "res://scripts/ui/window_base.gd"
## Character sheet: the nine attributes and what they make of you.

var map

func _init() -> void:
	window_size = Vector2(1000, 660)

func build() -> void:
	var pl: Dictionary = GS.player
	set_title(pl.name)
	var bg: Dictionary = GS.BACKGROUNDS.get(pl.background, {})
	var status := "Independent"
	if pl.faction != "":
		status = "%s of the %s" % [pl.status.capitalize(), Data.factions[pl.faction].name]
	var info := "[b]%s[/b] — Level %d  (XP %d / %d)\nBending: %s    Status: %s    Standing: %s\nHP %d    Chi %d    Renown %d    Honour %d\n[i]%s[/i]" % [
		bg.get("name", ""), pl.level, pl.xp, GS.xp_for_level(pl.level), Data.element_name(pl.bend), status, GS.standing_name(),
		GS.max_hp(), int(GS.max_chi()), pl.renown, pl.get("honor", 0), GS.STANDING_DESC[GS.standing()]]
	content.add_child(UI.rich(info, 940))
	var cols := UI.hbox(30)
	content.add_child(cols)
	# Attributes
	var left := UI.vbox(4)
	cols.add_child(left)
	left.add_child(UI.label("Attributes  (%d to spend)" % pl.attr_points, 19, UI.BROWN))
	var feeds := _feeds()
	for a in GS.ATTRS:
		var row := UI.hbox(8)
		var l := UI.label("%s" % GS.ATTR_NAME[a], 17)
		l.custom_minimum_size.x = UI.px(118)
		row.add_child(l)
		var v := UI.label(str(GS.attr(a)), 17)
		v.custom_minimum_size.x = UI.px(30)
		row.add_child(v)
		row.add_child(UI.button("+", _add_attr.bind(a), 34, pl.attr_points > 0))
		var d := UI.label(feeds.get(a, ""), 13, UI.BROWN)
		d.tooltip_text = GS.ATTR_DESC[a]
		d.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(d)
		l.tooltip_text = GS.ATTR_DESC[a]
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		left.add_child(row)
	# What the attributes add up to
	var right := UI.vbox(3)
	cols.add_child(right)
	right.add_child(UI.label("What they make of you", 19, UI.BROWN))
	if pl.bend != "":
		var ea: Array = GS.ELEMENT_ATTRS[pl.bend]
		right.add_child(UI.rich("[b]%s: %d[/b]  [i](Attunement, with %s and %s)[/i]" % [Data.element_name(pl.bend), GS.skill("bending"), GS.ATTR_NAME[ea[0]], GS.ATTR_NAME[ea[1]]], 520))
	else:
		right.add_child(UI.rich("[i]You do not bend. Attunement still deepens your chi.[/i]", 520))
	right.add_child(UI.rich("Health [b]%d[/b]   Chi [b]%d[/b]   Melee [b]+%d%%[/b]   Party up to [b]%d[/b]" % [GS.max_hp(), int(GS.max_chi()), int(GS.skill("power_strike") * 8 + GS.attr("str")), GS.party_limit()], 520))
	right.add_child(UI.spacer(8))
	right.add_child(UI.label("Faction standing", 19, UI.BROWN))
	for f in Data.KINGDOMS:
		var rel: int = pl.faction_rel.get(f, 0)
		var war := GS.at_war(GS.player_faction(), f)
		right.add_child(UI.label("%s: %d%s" % [Data.factions[f].name, rel, "  (at war)" if war else ""], 15, UI.RED if war else UI.INK))
	var b := UI.hbox()
	content.add_child(b)
	if GS.player.bend != "":
		b.add_child(UI.button("Bending Forms", func():
			map.open_window(load("res://scripts/ui/forms_window.gd").new()), 180))
		b.add_child(UI.button("Techniques", func():
			map.open_window(load("res://scripts/ui/techniques_window.gd").new()), 160))
	b.add_child(UI.rich("[i]%s%s[/i]" % [load("res://scripts/core/avatar.gd").mastery_text(), ("  ·  " + GS.player.master_title) if GS.player.get("master_title", "") != "" else ""], 520))
	b.add_child(UI.expand())
	b.add_child(UI.button("Done", close, 120))

## A short line on what each attribute feeds, for this character.
func _feeds() -> Dictionary:
	var out := {"vig": "health", "att": "bending, chi" if GS.player.bend != "" else "chi (no bending)", "end": "running, travel",
		"vit": "toughness, command", "str": "melee, drilling", "dex": "weapons, archery, riding", "int": "tactics, trade, medicine",
		"spi": "the spiritual", "lck": "bargains, finds"}
	if GS.player.bend != "":
		for a in GS.ELEMENT_ATTRS[GS.player.bend]:
			out[a] += ", %s" % Data.element_name(GS.player.bend).to_lower()
	return out

func _add_attr(a: String) -> void:
	if GS.player.attr_points <= 0:
		return
	GS.player.attr_points -= 1
	GS.player.attrs[a] = GS.attr(a) + 1
	if a == "vig":
		GS.player.hp += 4
	refresh()
