extends "res://scripts/ui/window_base.gd"
## Conversation window: a live portrait of whoever is speaking (rigged model
## with facial expressions), their line, and the player's choices. Dialogue is
## text only; faces carry the emotion. Content comes from scripts/story/.

const Story = preload("res://scripts/story/story.gd")
const Actor = preload("res://scripts/actors/actor.gd")
const Looks = preload("res://scripts/actors/looks.gd")
const Accessories = preload("res://scripts/actors/accessories.gd")

var map
var dlg_id := ""
var node_id := ""
var dlg: Dictionary = {}
var _viewport: SubViewport
var _pivot: Node3D
var _actors := {}        # speaker id -> Actor
var _speaker := ""
var _visited := {}
var _choice_buttons: Array = []

func _init() -> void:
	window_size = Vector2(1040, 600)
	closable = false

func _ready() -> void:
	dlg = Story.dialogue(dlg_id)
	node_id = dlg.get("start", "")
	super._ready()

func build() -> void:
	var node: Dictionary = dlg.get("nodes", {}).get(node_id, {})
	if node.is_empty():
		close()
		return
	set_title(dlg.get("title", "Conversation"))
	if not _visited.has(node_id):
		_visited[node_id] = true
		Story.apply(node.get("do", []), map)
	var who: String = node.get("who", "narrator")
	var row := UI.hbox(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(row)
	# Portrait
	var left := UI.vbox(0)
	row.add_child(left)
	if who != "narrator" and Story.npc(who).get("portrait", true):
		left.add_child(_framed(_portrait(who, node.get("expr", "neutral"))))
		left.add_child(_nameplate(_speaker_name(who)))
	else:
		_hide_portrait()
		if who != "narrator":
			left.add_child(_nameplate(_speaker_name(who)))
	# Text and choices
	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var text := Story.fmt(node.get("text", ""))
	if who == "shen_mu" and GS.settings.get("plain_speech", false):
		text = _plain(text)
	if who == "narrator":
		text = "[i]%s[/i]" % text
	elif not Story.npc(who).get("portrait", true):
		text = "[b]%s[/b]" % text
	elif Data.companions.get(who, {}).get("signs", false):
		text = "[i]%s[/i]" % text   # storm-sign is shown in italics
	var sc := UI.scroll(300)
	right.add_child(sc)
	var body := UI.rich(text, 640 if who != "narrator" else 960)
	body.add_theme_font_size_override("normal_font_size", 20)
	body.add_theme_font_size_override("bold_font_size", 20)
	body.add_theme_font_size_override("italics_font_size", 20)
	sc.add_child(body)
	right.add_child(UI.sep())
	var choices: Array = node.get("choices", [])
	_choice_buttons = []
	if choices.is_empty():
		var nxt: String = node.get("next", "")
		var cb := UI.option(("Continue" if nxt != "" else "End conversation") + "   (Enter)", _go.bind(nxt, []))
		right.add_child(cb)
		_choice_buttons.append(cb)
	else:
		for c in choices:
			var cond: Dictionary = c.get("if", {})
			if c.get("hide", false) and not Story.ok(cond):
				continue
			var okc := Story.ok(cond)
			var label := Story.fmt(c.text)
			if not okc and c.has("hint"):
				label += "  [%s]" % c.hint
			# numbered: press 1-9 to choose
			var ob := UI.option("%d.  %s" % [_choice_buttons.size() + 1, label], _go.bind(c.get("next", ""), c.get("do", []), c.get("goto", "")), okc)
			right.add_child(ob)
			_choice_buttons.append(ob)

## Number keys choose, Enter or Space continues.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: int = event.physical_keycode
	var idx := -1
	if k >= KEY_1 and k <= KEY_9:
		idx = k - KEY_1
	elif (k == KEY_ENTER or k == KEY_SPACE or k == KEY_KP_ENTER) and _choice_buttons.size() == 1:
		idx = 0
	if idx >= 0 and idx < _choice_buttons.size():
		var b: Button = _choice_buttons[idx]
		if is_instance_valid(b) and not b.disabled:
			get_viewport().set_input_as_handled()
			b.pressed.emit()

## The portrait in a gilt frame.
func _framed(c: Control) -> Control:
	var f := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.08, 0.05)
	sb.border_color = UISkin.GOLD
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(4)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 5
	f.add_theme_stylebox_override("panel", sb)
	f.add_child(c)
	return f

## A lacquer nameplate under the portrait.
func _nameplate(n: String) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UISkin.LACQUER
	sb.border_color = UISkin.GOLD
	sb.border_width_bottom = 2
	sb.border_width_top = 1
	sb.set_content_margin_all(6)
	p.add_theme_stylebox_override("panel", sb)
	var l := UI.label(n, 20, UISkin.GOLD_PALE)
	l.add_theme_font_override("font", UISkin.font("display"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

## Remove written stutter ("d-don't" -> "don't") for players who find it hard to read.
static func _plain(t: String) -> String:
	var re := RegEx.new()
	re.compile("(?i)\\b(\\w{1,2})-(?=\\1)")
	return re.sub(t, "", true)

func _go(next: String, effects: Array, goto: String = "") -> void:
	Story.apply(effects, map)
	if not is_inside_tree() or is_queued_for_deletion():
		return
	if goto != "":
		# continue in another conversation (e.g. a logbook page)
		dlg_id = goto
		dlg = Story.dialogue(goto)
		node_id = dlg.get("start", "")
		_visited = {}
		refresh()
		return
	if next == "":
		close()
		return
	node_id = next
	refresh()

# ---------------------------------------------------------------------------
# Portraits
# ---------------------------------------------------------------------------
func _speaker_name(who: String) -> String:
	if who == "player":
		return GS.player.name
	if Data.companions.has(who):
		return Data.companions[who].get("short", Data.companions[who].name)
	if Data.lords.has(who):
		return Data.lords[who].name
	return Story.npc(who).get("name", who.capitalize())

func _look_for(who: String) -> Dictionary:
	if who == "player":
		return Looks.player_look()
	if Data.companions.has(who):
		return Looks.companion_look(who)
	if Data.lords.has(who):
		return Looks.lord_look(who)
	return Looks.npc_look(Story.npc(who), who)

func _portrait(who: String, expr: String) -> Control:
	var box := SubViewportContainer.new()
	box.custom_minimum_size = Vector2(300, 360)
	box.stretch = true
	if _viewport == null:
		_viewport = SubViewport.new()
		_viewport.own_world_3d = true
		_viewport.size = Vector2i(300, 360)
		_viewport.msaa_3d = Viewport.MSAA_4X
		var we := WorldEnvironment.new()
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.78, 0.66, 0.5)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.9, 0.86, 0.8)
		env.ambient_light_energy = 0.55
		we.environment = env
		_viewport.add_child(we)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-30, 35, 0)
		sun.light_energy = 1.1
		_viewport.add_child(sun)
		var cam := Camera3D.new()
		cam.name = "Cam"
		cam.fov = 30.0
		_viewport.add_child(cam)
		_pivot = Node3D.new()
		_viewport.add_child(_pivot)
	elif _viewport.get_parent() != null:
		_viewport.get_parent().remove_child(_viewport)
	box.add_child(_viewport)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if who != _speaker:
		for k in _actors:
			_actors[k].visible = false
		if not _actors.has(who):
			var a = Actor.new()
			a.setup(_look_for(who))
			a.set_stance("talk")
			_pivot.add_child(a)
			_actors[who] = a
		_actors[who].visible = true
		_speaker = who
		var look: Dictionary = _actors[who].look
		var hy: float = Accessories.head_y(look.get("sex", "m")) * float(look.get("height", 1.0))
		var cam: Camera3D = _viewport.get_node("Cam")
		cam.transform = Transform3D(Basis(), Vector3(0.14, hy - 0.02, 1.02)).looking_at(Vector3(0, hy - 0.09, 0), Vector3.UP)
	_actors[who].set_expression(expr)
	return box

func close() -> void:
	super.close()
	# show whatever the conversation queued next (story beats chain)
	if map != null and Story.has_pending() and map.has_method("open_dialogue"):
		map.call_deferred("open_dialogue", Story.pop_pending())

func _hide_portrait() -> void:
	if _viewport != null and _viewport.get_parent() != null:
		_viewport.get_parent().remove_child(_viewport)
		# keep the viewport alive for the next speaker
		add_child(_viewport)
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
