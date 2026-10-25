extends Node3D
## A townsperson: stands at a post (merchant, guard, monk), works at a loop
## animation (farming, drilling), or strolls between street waypoints,
## pausing to look around. Turns to face the player when spoken to.

const Actor = preload("res://scripts/actors/actor.gd")

var actor
var mode := "idle"            # idle | wander | work
var waypoints: Array = []
var target := Vector3.ZERO
var wait := 0.0
var walk_speed := 1.25
var home_rot := 0.0
var player: Node3D
var talk_radius := 0.0
var _turn := 0.0

func setup(look: Dictionary, stance: String, loop_anim: String, p_mode: String, p_waypoints: Array) -> void:
	actor = Actor.new()
	add_child(actor)
	actor.setup(look)
	mode = p_mode
	waypoints = p_waypoints
	home_rot = rotation.y
	if loop_anim != "":
		actor.call_deferred("loop", loop_anim)
	elif stance != "":
		actor.set_stance(stance)
		if stance in ["sit", "sit_talk"]:
			actor.call_deferred("loop", "ual1/Sitting_Idle" if stance == "sit" else "ual1/Sitting_Talking")
	wait = randf_range(0.0, 4.0)
	if mode == "wander" and not waypoints.is_empty():
		target = waypoints[randi() % waypoints.size()]
	actor.set_expression(["neutral", "neutral", "happy", "thoughtful"].pick_random())

func _process(delta: float) -> void:
	if mode == "wander":
		_wander(delta)
	elif talk_radius > 0.0 and player != null:
		# posted NPCs look at the player when close, then back to their post
		var to := player.global_position - global_position
		to.y = 0.0
		var want := home_rot
		if to.length() < talk_radius:
			want = atan2(to.x, to.z)
		rotation.y = lerp_angle(rotation.y, want, minf(1.0, delta * 4.0))

func _wander(delta: float) -> void:
	if wait > 0.0:
		wait -= delta
		actor.speed = 0.0
		return
	var to := target - position
	to.y = 0.0
	if to.length() < 0.4:
		wait = randf_range(1.5, 6.0)
		target = waypoints[randi() % waypoints.size()] + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
		return
	var dir := to.normalized()
	position += dir * walk_speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 6.0))
	actor.speed = walk_speed
