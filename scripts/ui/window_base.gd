extends Control
## Base modal window: dims the screen and shows a parchment panel with a
## title and a content area. Subclasses override build().

const UI = preload("res://scripts/ui/ui.gd")

signal closed

var panel: PanelContainer
var content: VBoxContainer
var title_label: Label
var window_title := ""
var window_size := Vector2(720, 520)
var closable := true

func _ready() -> void:
	theme = UI.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size = window_size
	center.add_child(panel)
	var outer := UI.vbox(8)
	panel.add_child(outer)
	var head := UI.hbox()
	outer.add_child(head)
	title_label = UI.title(window_title)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title_label)
	if closable:
		head.add_child(UI.button("X", close, 36))
	outer.add_child(UI.sep())
	content = UI.vbox(6)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(content)
	refresh()

func set_title(t: String) -> void:
	window_title = t
	if title_label:
		title_label.text = t

func refresh() -> void:
	UI.clear(content)
	build()

## Override in subclasses.
func build() -> void:
	pass

func close() -> void:
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if closable and event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()
