extends Node
## One early-game battle, played by the AI on both sides: a fresh character
## (the Strait Isles refugee: four peasants) against an outlaw band of the
## same head count. Run it many times to measure the opening's fairness:
##   for i in $(seq 20); do godot --headless --path . res://tests/test_balance.tscn -- earth; done | grep -c "winner=0"
## Target (Warband's looters): the player's side wins at least 7 in 10.
## Args after "--": [element or "none"] [outlaw troop id]
const Roster = preload("res://scripts/core/roster.gd")

func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().root.add_child.call_deferred(load("res://tests/test_balance.gd").new())
		return
	var args := OS.get_cmdline_user_args()
	var bend: String = args[0] if args.size() > 0 else "earth"
	if bend == "none":
		bend = ""
	var outlaw: String = args[1] if args.size() > 1 else "mountain_bandit"
	var p := GS.create_player("Balance", "ek_refugee", bend, Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.player.companions = []
	var e := GS.make_party("", "Outlaws", "bandit", "bandits", GS.player_party().pos)
	Roster.add(e.roster, outlaw, GS.party_size())
	load("res://scripts/battle/battle.gd").autotest = true
	GS.start_battle([e.id])
