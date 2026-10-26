extends "res://scripts/ui/window_base.gd"
## Bending Forms designer (sequel prototype). Build a form from movements of
## your art's martial basis; stances must chain; the stats follow from what
## you chose. Save it, name it, and set it on the F key for battle.

const Forms = preload("res://scripts/battle/forms.gd")

var map
var art := ""
var draft := {}
var editing := -1

func _init() -> void:
	window_size = Vector2(1180, 720)

func _ready() -> void:
	art = Forms.art_of(GS.player.bend)
	if not GS.player.has("forms"):
		GS.player.forms = []
		GS.player.form_f = -1
	_new_draft()
	super._ready()

func _new_draft() -> void:
	draft = {"name": "", "art": art, "moves": [], "release": Forms.ART_RELEASES.get(art, ["strike"])[0], "uses": 0}
	editing = -1

func build() -> void:
	set_title("Bending Forms")
	if art == "":
		content.add_child(UI.rich("You are not a bender. (Non-benders' weapon forms are planned for the sequel.)", 1100))
		content.add_child(UI.button("Close", close, 120))
		return
	var basis = {"fire": "Northern Shaolin", "earth": "Hung Gar", "water": "Tai Chi", "air": "Baguazhang"}[art]
	content.add_child(UI.rich("[b]%s[/b] is built on [b]%s[/b]. Choose movements in order: each must begin in the stance the last one ended in. Breathe in between exhaled strikes. Your art rewards %s." % [
		Data.element_name(art), basis, {"fire": "straight lines and breath", "earth": "rooted stances", "water": "circles", "air": "evasion"}[art]], 1120))
	var cols := UI.hbox(16)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)
	# Left: saved forms
	var left := UI.vbox(4)
	left.custom_minimum_size.x = 250
	cols.add_child(left)
	left.add_child(UI.label("Your forms", 18, UI.BROWN))
	var forms: Array = GS.player.forms
	for i in forms.size():
		var f: Dictionary = forms[i]
		var row := UI.hbox(4)
		left.add_child(row)
		var tag := "  [F]" if int(GS.player.get("form_f", -1)) == i else ""
		row.add_child(UI.button(f.name + tag, func():
			draft = f.duplicate(true)
			editing = i
			refresh(), 200))
		row.add_child(UI.button("✕", func():
			forms.remove_at(i)
			if int(GS.player.form_f) == i:
				GS.player.form_f = -1
			elif int(GS.player.form_f) > i:
				GS.player.form_f = int(GS.player.form_f) - 1
			_new_draft()
			refresh(), 36))
	left.add_child(UI.spacer(6))
	left.add_child(UI.button("New form", func():
		_new_draft()
		refresh(), 200))
	# Middle: the sequence and the next movements
	var mid := UI.vbox(4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(mid)
	mid.add_child(UI.label("Sequence (%d / %d)" % [draft.moves.size(), Forms.MAX_MOVES], 18, UI.BROWN))
	for i in draft.moves.size():
		var m := Forms.move(art, draft.moves[i])
		var row2 := UI.hbox(4)
		mid.add_child(row2)
		var stance_txt := "%s → %s" % [Forms.STANCES[art][m.in].split(" (")[0], Forms.STANCES[art][m.out].split(" (")[0]]
		row2.add_child(UI.rich("%d. [b]%s[/b]   [i](%s, breath %s)[/i]" % [i + 1, m.name, stance_txt, m.breath], 420))
		if i == draft.moves.size() - 1:
			row2.add_child(UI.button("Remove", func():
				draft.moves.pop_back()
				refresh(), 90))
	mid.add_child(UI.sep())
	if draft.moves.size() < Forms.MAX_MOVES:
		var last: String = draft.moves[-1] if not draft.moves.is_empty() else ""
		mid.add_child(UI.label("Next movement" + ("" if last == "" else " (from %s)" % Forms.STANCES[art][Forms.move(art, last).out].split(" (")[0]), 16, UI.BROWN))
		var grid := UI.grid(2, 6, 4)
		mid.add_child(grid)
		for m2 in Forms.next_moves(art, last, GS.player.get("techniques", [])):
			var b := UI.button("%s  (P%d · %.2fs · chi %d)" % [m2.name, m2.power, m2.dur, m2.chi], func():
				draft.moves.append(m2.id)
				refresh(), 300)
			b.tooltip_text = "%s → %s · breath %s · %s" % [Forms.STANCES[art][m2.in], Forms.STANCES[art][m2.out], m2.breath, ", ".join(m2.tags)]
			grid.add_child(b)
	mid.add_child(UI.spacer(4))
	var rrow := UI.hbox(6)
	mid.add_child(rrow)
	rrow.add_child(UI.label("Release:", 16))
	for r in Forms.ART_RELEASES.get(art, ["strike"]):
		var rb := UI.button(Forms.RELEASES[r].name, func():
			draft.release = r
			refresh())
		if draft.release == r:
			UI.mark_selected(rb)
		rrow.add_child(rb)
	# Right: computed stats
	var right := UI.vbox(4)
	right.custom_minimum_size.x = 330
	cols.add_child(right)
	right.add_child(UI.label("The form", 18, UI.BROWN))
	var ev := Forms.evaluate(draft)
	var a: Dictionary = ev.ability
	var txt := "Power  [b]%.0f[/b]\nWind-up  [b]%.2f s[/b]\nChi cost  [b]%.0f[/b]  (you have %.0f)\nCooldown  [b]%.1f s[/b]\n" % [ev.power, ev.windup, ev.chi, GS.max_chi(), a.get("cd", 0.0) + ev.windup]
	if a.has("dmg"):
		txt += "Damage  [b]%.0f[/b]\n" % a.dmg
	if a.has("knock"):
		txt += "Knockback  [b]%.1f[/b]\n" % a.knock
	if not ev.props.is_empty():
		txt += "Properties  [b]%s[/b]\n" % ", ".join(ev.props)
	for n in ev.notes:
		txt += "\n[i]%s[/i]" % n
	for e in ev.errors:
		txt += "\n" + UI.color_text(e, UI.RED)
	if ev.chi > GS.max_chi():
		txt += "\n" + UI.color_text("This form costs more chi than you have. Train Bending or shorten it.", UI.RED)
	right.add_child(UI.rich(txt, 320))
	var name_row := UI.hbox(4)
	right.add_child(name_row)
	var le := LineEdit.new()
	le.placeholder_text = Forms.suggest_name(draft)
	le.text = draft.name
	le.custom_minimum_size.x = 230
	le.text_changed.connect(func(t): draft.name = t)
	name_row.add_child(le)
	right.add_child(UI.button("Save form", func():
		if draft.name.strip_edges() == "":
			draft.name = Forms.suggest_name(draft)
		if editing >= 0 and editing < GS.player.forms.size():
			GS.player.forms[editing] = draft.duplicate(true)
		else:
			GS.player.forms.append(draft.duplicate(true))
			editing = GS.player.forms.size() - 1
		refresh(), 230, ev.valid))
	right.add_child(UI.button("Save and set on F", func():
		if draft.name.strip_edges() == "":
			draft.name = Forms.suggest_name(draft)
		if editing >= 0 and editing < GS.player.forms.size():
			GS.player.forms[editing] = draft.duplicate(true)
		else:
			GS.player.forms.append(draft.duplicate(true))
			editing = GS.player.forms.size() - 1
		GS.player.form_f = editing
		refresh(), 230, ev.valid and ev.chi <= GS.max_chi()))
	right.add_child(UI.rich("[i]Forms grow smoother with use: wind-up shortens by up to a quarter as you fight with them.[/i]", 320))
	var b2 := UI.hbox()
	content.add_child(b2)
	b2.add_child(UI.expand())
	b2.add_child(UI.button("Done", close, 120))
