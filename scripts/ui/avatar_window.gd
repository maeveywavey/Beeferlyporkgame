extends "res://scripts/ui/window_base.gd"
## The Avatar: who they are, where they were last seen, what they think of you,
## what would bring them to you, and (if they are coming to stop you) what you
## can do about it. Every rule is shown; nothing is a hidden roll.

const AvatarSys = preload("res://scripts/core/avatar.gd")
const Roster = preload("res://scripts/core/roster.gd")

var map
var note := ""

func _init() -> void:
	window_size = Vector2(1060, 700)

func build() -> void:
	AvatarSys.ensure()
	var A: Dictionary = AvatarSys.state()
	var st := AvatarSys.stage()
	set_title("The Avatar")
	var cols := UI.hbox(22)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)
	# Left: the person
	var left := UI.vbox(6)
	left.custom_minimum_size.x = 470
	cols.add_child(left)
	if AvatarSys.known():
		left.add_child(UI.label(AvatarSys.display_name(), 24, UI.BROWN))
		var els := []
		for e in AvatarSys.elements():
			els.append(Data.element_name(e))
		var txt := "[b]Age[/b] %d  ·  [b]%s[/b]\n[b]Born[/b] %s, %s\n[b]Mastered[/b] %s" % [int(AvatarSys.age()), AvatarSys.STAGE_NAMES[st],
			Data.settlements[A.home].name, Data.element_name(A.nation), ", ".join(els)]
		if not A.get("order", []).is_empty():
			txt += "\n[b]Still to learn[/b] %s" % ", ".join(A.order.map(func(e): return Data.element_name(e)))
		txt += "\n\n[i]%s[/i]" % A.get("bio", "")
		left.add_child(UI.rich(txt, 460))
	else:
		left.add_child(UI.label("The Avatar (unknown)", 24, UI.BROWN))
		left.add_child(UI.rich("A child of about %d, somewhere in the world, who has not been told. The sages of their nation are searching quietly. Nobody, including you, will meet them until they are sixteen." % int(AvatarSys.age()), 460))
	left.add_child(UI.rich("[b]%s[/b] — %s" % [AvatarSys.STAGE_NAMES[st], AvatarSys.STAGE_DESC[st]], 460))
	left.add_child(UI.sep())
	left.add_child(UI.label("Whereabouts", 18, UI.BROWN))
	var where := ""
	if st == "child":
		where = "Unknown."
	elif A.get("state", "") == "teaching":
		where = "Travelling with you, as your student."
	elif GS.day() < int(A.get("wounded_until", -1)):
		where = "Withdrawn to heal. Nobody knows where."
	elif A.get("seen", []).is_empty():
		where = "No sightings yet. The sages say the Avatar is in the Spirit World."
	else:
		for e in A.seen:
			where += "Seen at [b]%s[/b], %d days ago\n" % [Data.settlements[e.sid].name, GS.day() - int(e.day)]
		where += "[i]Rumours arrive a day or two late. The Avatar rarely stays anywhere more than a few days.[/i]"
	left.add_child(UI.rich(where, 460))
	left.add_child(UI.rich("[b]Towards you:[/b] %s" % AvatarSys.attitude_text(), 460))
	# Right: you, and what would bring the Avatar
	var right := UI.vbox(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	right.add_child(UI.label("What would bring the Avatar to you", 18, UI.BROWN))
	var m := AvatarSys.motives()
	var names := {"ruler": "Great power, used well", "tyrant": "Great power, used cruelly", "teacher": "Mastery (a young Avatar's teacher)", "local": "Cruelty nearby"}
	for k in ["ruler", "tyrant", "teacher", "local"]:
		var mk: Dictionary = m[k]
		var row := UI.vbox(1)
		right.add_child(row)
		var status := "  [color=#2a6a2a](met)[/color]" if mk.done else ("  [color=#a03020](active)[/color]" if mk.active else "")
		row.add_child(UI.rich("[b]%s[/b]%s\n%s" % [names[k], status, mk.why], 540))
		# jade for the good reason, cinnabar for the cruel ones, gold for mastery
		var col: Color = {"ruler": UI.GREEN, "tyrant": UI.RED, "teacher": UI.GOLD, "local": UI.RED}[k]
		row.add_child(UI.bar(mk.progress, 1.0, col, 520.0, 10.0))
	right.add_child(UI.rich("[i]The Avatar is least involved in childhood and old age. Your infamy: [b]%d[/b] (fades with time). Influence: [b]%.1f[/b]. %s[/i]" % [AvatarSys.infamy(), AvatarSys.influence(), AvatarSys.mastery_text()], 540))
	if AvatarSys.hostile() and st != "child":
		_build_preparations(right)
	if note != "":
		right.add_child(UI.rich(note, 540))
	var b := UI.hbox()
	content.add_child(b)
	b.add_child(UI.expand())
	b.add_child(UI.button("Done", close, 120))

## Counterplay when the Avatar is coming: walls, wards, chi-blockers, a raid
## on their home, intelligence on whom they love, or yielding in advance.
func _build_preparations(o: VBoxContainer) -> void:
	var A: Dictionary = AvatarSys.state()
	o.add_child(UI.sep())
	var due: Dictionary = A.get("due", {})
	var when := ""
	if due.get("kind", "") == "confront":
		when = " They will reach you in about %d days." % maxi(0, int(due.day) - GS.day())
	o.add_child(UI.label("Preparations", 18, UI.RED))
	o.add_child(UI.rich("[i]%s is coming to stop you.%s Defences count only if you meet them at the seat where you built them.[/i]" % [AvatarSys.display_name().capitalize(), when], 540))
	var seats := []
	for sid in GS.settlements:
		if GS.settlements[sid].owner == "player" and Data.settlements[sid].type in ["town", "castle"]:
			seats.append(sid)
	var sc := UI.scroll(170)
	o.add_child(sc)
	var list := UI.vbox(4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	for sid in seats:
		var def := AvatarSys.defences(sid)
		var nm: String = Data.settlements[sid].name
		list.add_child(UI.option("Fortify %s (walls %d/3, %d gold)" % [nm, def.fort, AvatarSys.fort_cost(sid)], func():
			AvatarSys.fortify(sid)
			note = "Masons work through the night at %s." % nm
			refresh(), def.fort < 3 and GS.player.gold >= AvatarSys.fort_cost(sid)))
		list.add_child(UI.option("Lay spirit-wards and chi-blocker nets at %s (traps %d/3, %d gold)" % [nm, def.traps, AvatarSys.trap_cost(sid)], func():
			AvatarSys.lay_traps(sid)
			note = "Paper wards on every lintel, weighted nets in every gatehouse. Each level costs the Avatar strength and holds their bending for a few seconds."
			refresh(), def.traps < 3 and GS.player.gold >= AvatarSys.trap_cost(sid)))
	if seats.is_empty():
		list.add_child(UI.rich("[i]You hold no town or castle to fortify. The Avatar will find you in the open.[/i]", 520))
	list.add_child(UI.option("Hire 6 chi-blockers (900 gold): their strikes stop a bender bending", func():
		GS.add_gold(-900)
		Roster.add(GS.player_party().roster, "chi_blocker", 6)
		note = "Six quiet people in grey join your column. They do not say where they trained."
		refresh(), GS.player.gold >= 900 and GS.party_size() + 6 <= GS.party_limit()))
	if not A.get("intel", false):
		list.add_child(UI.option("Pay spies to learn whom the Avatar loves (800 gold)", func():
			AvatarSys.buy_intel()
			note = "Your spies return with a name: %s, %s, at %s." % [A.loved.name, A.loved.role, Data.settlements[A.home].name]
			refresh(), GS.player.gold >= 800))
	else:
		list.add_child(UI.rich("[i]You know of %s, %s, at %s.%s[/i]" % [A.loved.name, A.loved.role, Data.settlements[A.home].name, " You hold them." if A.get("hostage", false) else ""], 520))
	if A.get("diversion", false):
		list.add_child(UI.rich("[i]A detachment waits within striking distance of %s.[/i]" % Data.settlements[A.home].name, 520))
	else:
		list.add_child(UI.option("Stage an army near %s to strike when the Avatar moves (detach 20 troops, 600 gold)" % Data.settlements[A.home].name, func():
			AvatarSys.stage_diversion()
			note = "Twenty of your soldiers ride for %s. When the Avatar comes for you, they will burn it, and the Avatar will have to choose." % Data.settlements[A.home].name
			refresh(), AvatarSys.can_stage_diversion()))
	list.add_child(UI.option("Send word that you yield", func():
		AvatarSys.judgement(true)
		var S = load("res://scripts/story/story.gd")
		AvatarSys.state().due = {}
		S.journal("av_main", "The Avatar", "You yielded before the Avatar arrived. Your fiefs were returned and your infamy forgiven.")
		note = "Your envoy returns with a single line in a careful hand: 'Thank you. Let's give it back together.'"
		refresh()))
