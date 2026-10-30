extends "res://scripts/ui/window_base.gd"
## Move troops between the player's party and a fief's garrison.

const Roster = preload("res://scripts/core/roster.gd")

var sid := ""
var map

func _init() -> void:
	window_size = Vector2(900, 600)

func build() -> void:
	set_title("Garrison of " + Data.settlements[sid].name)
	var pp: Dictionary = GS.player_party()
	var gar: Array = GS.settlements[sid].garrison
	content.add_child(UI.rich("Garrison troops cost half wages. Party: %d/%d" % [GS.party_size(), GS.party_limit()], 820))
	var cols := UI.hbox(20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)
	cols.add_child(_column("Your party", pp.roster, gar, false))
	cols.add_child(_column("Garrison", gar, pp.roster, true))
	var b := UI.hbox()
	content.add_child(b)
	b.add_child(UI.expand())
	b.add_child(UI.button("Done", close, 120))

func _column(title: String, from: Array, to: Array, to_party: bool) -> Control:
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.label("%s (%d)" % [title, Roster.total(from)], 19, UI.BROWN))
	var sc := UI.scroll(420)
	v.add_child(sc)
	var list := UI.vbox(3)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	for s in from:
		var row := UI.hbox()
		var l := UI.label("%s  x%d%s" % [Data.troop(s.id).name, s.n, (" (%d wounded)" % s.w) if s.w > 0 else ""], 15)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		row.add_child(UI.button("1 >" if not to_party else "< 1", _move.bind(from, to, s.id, 1, to_party), 54))
		row.add_child(UI.button("All >" if not to_party else "< All", _move.bind(from, to, s.id, s.n, to_party), 64))
		list.add_child(row)
	return v

func _move(from: Array, to: Array, id: String, n: int, to_party: bool) -> void:
	if to_party:
		n = mini(n, GS.party_limit() - GS.party_size())
		if n <= 0:
			return
	var st := Roster.find(from, id)
	if st.is_empty():
		return
	var wounded_ratio: float = float(st.w) / maxf(1.0, st.n)
	var moved := Roster.remove(from, id, n)
	var w := int(round(moved * wounded_ratio))
	Roster.add(to, id, moved, w)
	refresh()
