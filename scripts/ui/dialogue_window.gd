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
	var left := UI.vbox(4)
	row.add_child(left)
	if who != "narrator" and Story.npc(who).get("portrait", true):
		left.add_child(_portrait(who, node.get("expr", "neutral")))
		left.add_child(UI.label(_speaker_name(who), 19, UI.BROWN))
	else:
		_hide_portrait()
		if who != "narrator":
			left.add_child(UI.label(_speaker_name(who), 19, UI.BROWN))
	# Text and choices
	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var text := Story.fmt(node.get("text", ""))
	if who == "narrator":
		text = "[i]%s[/i]" % text
	elif not Story.npc(who).get("portrait", true):
		text = "[b]%s[/b]" % text
	elif Data.companions.get(who, {}).get("signs", false):
		text = "[i]%s[/i]" % text   # storm-sign is shown in italics
	var sc := UI.scroll(300)
	right.add_child(sc)
	sc.add_child(UI.rich(text, 660 if who != "narrator" else 980))
	right.add_child(UI.sep())
	var choices: Array = node.get("choices", [])
	if choices.is_empty():
		var nxt: String = node.get("next", "")
		right.add_child(UI.option("Continue" if nxt != "" else "End conversation", _go.bind(nxt, [])))
	else:
		for c in choices:
			var cond: Dictionary = c.get("if", {})
			if c.get("hide", false) and not Story.ok(cond):
				continue
			var okc := Story.ok(cond)
			var label := Story.fmt(c.text)
			if not okc and c.has("hint"):
				label += "  [%s]" % c.hint
			right.add_child(UI.option(label, _go.bind(c.get("next", ""), c.get("do", []), c.get("goto", "")), okc))

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
		env.background_color = Color(0.86, 0.78, 0.62)
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
