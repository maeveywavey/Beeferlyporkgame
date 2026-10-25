extends "res://scripts/ui/window_base.gd"
## Overview of the kingdoms, their lords and their lands.

const Roster = preload("res://scripts/core/roster.gd")

var map
var selected := "fire_nation"

func _init() -> void:
	window_size = Vector2(1100, 680)

func build() -> void:
	set_title("Nations of the World")
	var tabs := UI.hbox()
	content.add_child(tabs)
	for f in Data.KINGDOMS + ["player"]:
		if f == "player" and GS.faction_settlements("player").is_empty():
			continue
		var b := UI.button(Data.factions[f].short, func():
			selected = f
			refresh())
		if f == selected:
			b.add_theme_color_override("font_color", UI.GOLD)
		tabs.add_child(b)
	var fd: Dictionary = Data.factions[selected]
	var wars := []
	for o in Data.KINGDOMS:
		if o != selected and GS.at_war(selected, o):
			wars.append(Data.factions[o].name)
	if selected != "player" and GS.at_war(selected, GS.player_faction()) and GS.player_faction() == "player":
		wars.append("You")
	var txt := "[b]%s[/b]\n%s\nAt war with: %s" % [fd.name, fd.desc, ", ".join(wars) if not wars.is_empty() else "nobody"]
	var king: String = fd.king
	if king != "" and Data.lords.has(king):
		txt += "\nRuler: %s" % Data.lords[king].name
	var camp: Dictionary = GS.campaigns.get(selected, {})
	if not camp.is_empty():
		txt += "\nCurrently campaigning against: %s" % Data.settlements[camp.target].name
	content.add_child(UI.rich(txt, 1040))
	var cols := UI.hbox(20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)
	# Lords
	var left := UI.vbox(3)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	left.add_child(UI.label("Lords", 19, UI.BROWN))
	var sc := UI.scroll(380)
	left.add_child(sc)
	var ll := UI.vbox(3)
	ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(ll)
	for lid in GS.faction_lords(selected):
		var lr: Dictionary = GS.lords[lid]
		var where := "your prisoner" if lr.get("held", false) else "recovering from defeat"
		var troops := 0
		if lr.party != "" and GS.parties.has(lr.party):
			var p: Dictionary = GS.parties[lr.party]
			troops = Roster.total(p.roster)
			where = "near " + GS.sim._nearest_settlement_name(p.pos)
			if p.get("besieging", "") != "":
				where = "besieging " + Data.settlements[p.besieging].name
		ll.add_child(UI.label("%s — %d troops, %s (relation %d)" % [Data.lords[lid].name, troops, where, lr.relation], 15))
	# Lands
	var right := UI.vbox(3)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	right.add_child(UI.label("Lands", 19, UI.BROWN))
	var sc2 := UI.scroll(380)
	right.add_child(sc2)
	var sl := UI.vbox(3)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc2.add_child(sl)
	for sid in GS.faction_settlements(selected):
		var s: Dictionary = GS.settlements[sid]
		var d: Dictionary = Data.settlements[sid]
		var owner = "you" if s.owner == "player" else (Data.lords[s.owner].name if Data.lords.has(s.owner) else "-")
		var extra := ""
		if not s.siege.is_empty():
			extra = " [BESIEGED]"
		elif s.looted_until > GS.hours:
			extra = " [looted]"
		sl.add_child(UI.label("%s (%s) — %s%s" % [d.name, d.type, owner, extra], 15))
	var b := UI.hbox()
	content.add_child(b)
	b.add_child(UI.expand())
	b.add_child(UI.button("Done", close, 120))
