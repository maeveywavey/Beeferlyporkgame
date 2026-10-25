extends "res://scripts/ui/window_base.gd"
## Game settings.

var map

func _init() -> void:
	window_size = Vector2(640, 480)

func build() -> void:
	set_title("Settings")
	var g := UI.grid(2, 20, 12)
	content.add_child(g)
	g.add_child(UI.label("Battle size (troops on the field)"))
	var bs := HSlider.new()
	bs.min_value = 30
	bs.max_value = 200
	bs.step = 10
	bs.value = GS.settings.battle_size
	bs.custom_minimum_size.x = 220
	var bsl := UI.label(str(GS.settings.battle_size))
	bs.value_changed.connect(func(v):
		GS.settings.battle_size = int(v)
		bsl.text = str(int(v)))
	var bsr := UI.hbox()
	bsr.add_child(bs)
	bsr.add_child(bsl)
	g.add_child(bsr)
	g.add_child(UI.label("Difficulty (damage you take)"))
	var diff := OptionButton.new()
	for t in ["Easy (50%)", "Normal (100%)", "Hard (150%)"]:
		diff.add_item(t)
	diff.selected = int(GS.settings.difficulty)
	diff.item_selected.connect(func(i): GS.settings.difficulty = i)
	g.add_child(diff)
	g.add_child(UI.label("Automatic blocking direction"))
	var ab := CheckBox.new()
	ab.button_pressed = GS.settings.auto_block
	ab.toggled.connect(func(v): GS.settings.auto_block = v)
	g.add_child(ab)
	g.add_child(UI.label("Mouse sensitivity"))
	var ms := HSlider.new()
	ms.min_value = 0.05
	ms.max_value = 1.0
	ms.step = 0.05
	ms.value = GS.settings.mouse_sens
	ms.custom_minimum_size.x = 220
	ms.value_changed.connect(func(v): GS.settings.mouse_sens = v)
	g.add_child(ms)
	g.add_child(UI.label("Invert mouse Y"))
	var iy := CheckBox.new()
	iy.button_pressed = GS.settings.invert_y
	iy.toggled.connect(func(v): GS.settings.invert_y = v)
	g.add_child(iy)
	g.add_child(UI.label("Volume"))
	var vol := HSlider.new()
	vol.min_value = 0.0
	vol.max_value = 1.0
	vol.step = 0.05
	vol.value = GS.settings.volume
	vol.custom_minimum_size.x = 220
	vol.value_changed.connect(func(v):
		GS.settings.volume = v
		GS.apply_settings())
	g.add_child(vol)
	content.add_child(UI.spacer(20))
	var b := UI.hbox()
	content.add_child(b)
	b.add_child(UI.expand())
	b.add_child(UI.button("Save & Close", func():
		GS.save_settings()
		close(), 160))

func close() -> void:
	GS.save_settings()
	super.close()
