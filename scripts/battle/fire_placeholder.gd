extends RefCounted
## TASK 16: every fire in the game is a placeholder. Constructors for the three
## kinds of fire, all built on fire_emitter.gd (orange squares, no texture, no
## glow). Callers keep the returned node only if they need to stop it early.

const Emitter = preload("res://scripts/battle/fire_emitter.gd")

## A continuous source: ground fire, a burning body, a campfire. Squares rise
## from `at`. `duration` 0 runs until the returned node's stop() is called.
static func source(parent: Node, at: Vector3, rate: float, sz: float, lt: float, rs: float, sp: float, duration: float = 0.0) -> Node3D:
	var e: Node3D = Emitter.new()
	e.rate = rate
	e.size = sz
	e.life = lt
	e.rise = rs
	e.spread = sp
	e.duration = duration
	parent.add_child(e)
	e.position = at
	return e

## A one-off puff: `count` squares born at `at` in a small disc, rising.
static func burst(parent: Node, at: Vector3, sz: float, lt: float, count: int = 4, rs: float = 1.0, sp: float = 0.3) -> void:
	var e: Node3D = Emitter.new()
	e.size = sz
	e.life = lt
	e.rise = rs
	e.spread = sp
	parent.add_child(e)
	e.position = at
	for k in count:
		e._spawn()

## A jet: squares fired from `origin` along `yaw` (the horizontal direction),
## fanning out over `spread_deg`, slowing as they go, shrinking to nothing.
static func spray(parent: Node, origin: Vector3, yaw: float, reach: float, spread_deg: float, count: int, lt: float, sz: float = 0.4) -> void:
	var e: Node3D = Emitter.new()
	parent.add_child(e)
	e.position = origin
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	for k in count:
		var a := deg_to_rad(randf_range(-spread_deg, spread_deg) * 0.5)
		var d := fwd.rotated(Vector3.UP, a)
		var speed := reach / lt * randf_range(0.45, 1.1)
		var l := lt * randf_range(0.7, 1.1)
		e.add(Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.25), randf_range(-0.1, 0.1)), d * speed, sz * randf_range(0.8, 1.25), l)
