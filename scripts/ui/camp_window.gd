extends "res://scripts/ui/window_base.gd"
## Camp menu: rest, save/load, settings, leave service.

const SettingsWindow = preload("res://scripts/ui/settings_window.gd")

var map
var note := ""

func _init() -> void:
	window_size = Vector2(620, 520)

func _talk(id: String) -> void:
	var w = map.open_dialogue(id)
	if w != null:
		w.tree_exited.connect(func():
			if is_inside_tree() and not is_queued_for_deletion():
				refresh())

## Banter between two companions who are both present, each pair heard once.
func _fire() -> void:
	var Story = load("res://scripts/story/story.gd")
	var pairs := [["hana", "ukiuk"], ["juro", "reika"], ["kesi", "pemba"], ["nima", "shen_mu"], ["hana", "pemba"], ["juro", "nima"], ["reika", "ukiuk"], ["kesi", "shen_mu"]]
	pairs.shuffle()
	for pr in pairs:
		var id: String = "banter_%s_%s" % [pr[0], pr[1]]
		if Story.in_party(pr[0]) and Story.in_party(pr[1]) and not Story.flag("seen_" + id):
			Story.set_flag("seen_" + id, true)
			for c in pr:
				Story.change_approval(c, 1)
			_talk(id)
			return
	_talk("banter_fire_alone")

func build() -> void:
	set_title("Camp")
	if note != "":
		content.add_child(UI.rich(note, 560))
	content.add_child(UI.option("Make camp and wait (click the map to stop)", func():
		map.start_waiting(-1.0)
		close()))
	content.add_child(UI.option("Rest for 24 hours", func():
		map.start_waiting(24.0)
		close()))
	# Companions and the story
	var Story = load("res://scripts/story/story.gd")
	for cid in GS.player.companions:
		if Story.in_party(cid):
			var nm: String = Data.companions[cid].get("short", cid)
			content.add_child(UI.option("Talk with %s (approval %d)" % [nm, Story.approval(cid)], _talk.bind("talk_" + cid)))
	if GS.player.companions.size() >= 2:
		content.add_child(UI.option("Sit by the fire with everyone", _fire))
	if not Story.pages().is_empty():
		content.add_child(UI.option("Read the Avatar's logbook (%d of 6 pages)" % Story.pages().size(), _talk.bind("ms_logbook")))
	content.add_child(UI.option("Save game", func():
		note = "Game saved." if GS.save_game() else "Could not save!"
		refresh()))
	content.add_child(UI.option("Load saved game", func():
		if GS.load_game():
			get_tree().reload_current_scene()
		else:
			note = "No saved game found."
			refresh(), GS.has_save()))
	content.add_child(UI.option("How to play", func():
		map.open_window(load("res://scripts/ui/help_window.gd").new())))
	content.add_child(UI.option("Settings", func():
		var sw = SettingsWindow.new()
		map.open_window(sw)))
	var pl: Dictionary = GS.player
	if pl.status == "mercenary":
		content.add_child(UI.option("End your mercenary contract", func():
			GS.log_msg("You are no longer a mercenary of the %s." % Data.factions[pl.faction].name)
			pl.faction = ""
			pl.status = ""
			refresh()))
	elif pl.status == "vassal":
		content.add_child(UI.option("Renounce your oath of fealty (you keep your fiefs, but war follows)", func():
			var f: String = pl.faction
			pl.faction = ""
			pl.status = ""
			for sid in GS.settlements:
				if GS.settlements[sid].owner == "player":
					GS.settlements[sid].faction = "player"
			GS.change_faction_rel(f, -40)
			GS.declare_war("player", f)
			GS.log_msg("You renounced your oath to the %s. They now consider you a traitor." % Data.factions[f].name, Color(1, 0.4, 0.3))
			refresh()))
	content.add_child(UI.option("Save and return to the main menu", func():
		GS.save_game(GS.AUTOSAVE_PATH)
		GS.game_active = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")))
	content.add_child(UI.option("Back to the map", close))
