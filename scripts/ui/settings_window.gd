extends "res://scripts/ui/window_base.gd"
## Game settings.

var map

func _init() -> void:
	window_size = Vector2(840, 700)

func build() -> void:
	set_title("Settings")
	var sc := UI.scroll(520)
	content.add_child(sc)
	var g := UI.grid(2, 20, 12)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(g)
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
	g.add_child(UI.label("Fullscreen (F11)"))
	var fs := CheckBox.new()
	fs.button_pressed = GS.settings.fullscreen
	fs.toggled.connect(func(v):
		GS.settings.fullscreen = v
		GS.apply_settings())
	g.add_child(fs)
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
	g.add_child(UI.label("Music volume"))
	var mv := HSlider.new()
	mv.min_value = 0.0
	mv.max_value = 1.0
	mv.step = 0.05
	mv.value = GS.settings.get("music", 0.5)
	mv.custom_minimum_size.x = 220
	mv.value_changed.connect(func(v):
		GS.settings.music = v
		GS.apply_settings())
	g.add_child(mv)
	# Accessibility
	g.add_child(UI.label("Text and interface size"))
	var us := HSlider.new()
	us.min_value = 0.8
	us.max_value = 1.5
	us.step = 0.05
	us.value = float(GS.settings.get("ui_scale", 1.0))
	us.custom_minimum_size.x = 220
	us.value_changed.connect(func(v): GS.settings.ui_scale = v)
	g.add_child(us)
	g.add_child(UI.label("Plain speech (show Shen Mu's lines without the stutter)"))
	var ps := CheckBox.new()
	ps.button_pressed = GS.settings.get("plain_speech", false)
	ps.toggled.connect(func(v): GS.settings.plain_speech = v)
	g.add_child(ps)
	g.add_child(UI.label("Reduce flashing (lightning, bright bursts)"))
	var rf := CheckBox.new()
	rf.button_pressed = GS.settings.get("reduce_flashing", false)
	rf.toggled.connect(func(v): GS.settings.reduce_flashing = v)
	g.add_child(rf)
	g.add_child(UI.label("Pixel textures"))
	var rl := OptionButton.new()
	for k in ["off", "light", "heavy"]:
		rl.add_item(k.capitalize())
	rl.selected = ["off", "light", "heavy"].find(String(GS.settings.get("retro", "light")))
	rl.item_selected.connect(func(i):
		GS.settings.retro = ["off", "light", "heavy"][i]
		GS.apply_settings())
	g.add_child(rl)
	g.add_child(UI.label("Map style"))
	var mst := OptionButton.new()
	for k in ["Painted map", "Painted atlas", "Old chart", "Ink wash"]:
		mst.add_item(k)
	mst.selected = maxi(0, ["painted", "atlas", "chart", "ink"].find(String(GS.settings.get("map_style", "painted"))))
	mst.item_selected.connect(func(i):
		GS.settings.map_style = ["painted", "atlas", "chart", "ink"][i]
		load("res://scripts/world/map_builder.gd").apply_style())
	g.add_child(mst)
	g.add_child(UI.label("Gore and dismemberment"))
	var gr := CheckBox.new()
	gr.button_pressed = GS.settings.get("gore", true)
	gr.toggled.connect(func(v): GS.settings.gore = v)
	g.add_child(gr)
	g.add_child(UI.label("Show political borders on the map"))
	var bd := CheckBox.new()
	bd.button_pressed = GS.settings.get("map_borders", true)
	bd.toggled.connect(func(v):
		GS.settings.map_borders = v
		load("res://scripts/world/map_builder.gd").update_borders())
	g.add_child(bd)
	g.add_child(UI.label("Reduce motion (no window animations)"))
	var rm := CheckBox.new()
	rm.button_pressed = GS.settings.get("reduce_motion", false)
	rm.toggled.connect(func(v): GS.settings.reduce_motion = v)
	g.add_child(rm)
	g.add_child(UI.label("Readable font (Atkinson Hyperlegible; applies to new windows)"))
	var rdf := CheckBox.new()
	rdf.button_pressed = GS.settings.get("readable_font", false)
	rdf.toggled.connect(func(v):
		GS.settings.readable_font = v
		UI.reset_theme())
	g.add_child(rdf)
	# The element expansions can be switched off individually
	var DLC = load("res://scripts/dlc/registry.gd")
	for el in DLC.EXPANSIONS:
		g.add_child(UI.label("Expansion: %s (%s)" % [DLC.EXPANSIONS[el].name, Data.element_name(el)]))
		var cb := CheckBox.new()
		cb.button_pressed = GS.settings.get("dlc_" + el, true)
		cb.toggled.connect(func(v): GS.settings["dlc_" + el] = v)
		g.add_child(cb)
	content.add_child(UI.rich("[i]Size applies when you press Save & Close. Story choices always show their requirements; nothing in this game is timed except battles.[/i]", 580))
	content.add_child(UI.spacer(10))
	var b := UI.hbox()
	content.add_child(b)
	b.add_child(UI.expand())
	b.add_child(UI.button("Save & Close", func():
		GS.save_settings()
		close(), 160))

func close() -> void:
	GS.save_settings()
	super.close()
