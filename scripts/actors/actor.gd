extends Node3D
## A visual character: rigged CC0 model + AnimationTree.
##  * locomotion blend (idle / walk / jog / sprint) driven by `speed`
##  * upper-body one-shot layer for attacks, casts and gestures while moving
##  * full-body one-shot layer for hits, rolls, jumps and stomps
##  * stance idles (unarmed, sword, bending, shield)
##  * facial expressions with smooth transitions and automatic blinking
##  * procedural bending stances layered on top (see bending_pose.gd)

const CB = preload("res://scripts/actors/character_builder.gd")
const FaceRig = preload("res://scripts/actors/face_rig.gd")
const BendingPose = preload("res://scripts/actors/bending_pose.gd")

const UPPER_BONES := ["spine_01", "spine_02", "spine_03", "neck_01", "Head",
	"clavicle_l", "upperarm_l", "lowerarm_l", "hand_l", "clavicle_r", "upperarm_r", "lowerarm_r", "hand_r"]
const FINGERS := ["index", "middle", "pinky", "ring", "thumb"]

const STANCES := {
	"unarmed": "ual1/Idle", "sword": "ual1/Sword_Idle", "bend": "ual1/Spell_Simple_Idle",
	"shield": "ual2/Idle_Shield", "talk": "ual1/Idle_Talking", "folded": "ual2/Idle_FoldArms",
	"sit": "ual1/Sitting_Idle", "torch": "ual1/Idle_Torch", "lantern": "ual2/Idle_Lantern",
	"crouch": "ual1/Crouch_Idle", "ride": "ual1/Sitting_Idle", "work": "ual2/Farm_Harvest",
	"chop": "ual2/TreeChopping", "dance": "ual1/Dance", "kneel": "ual1/Fixing_Kneeling",
	"sit_talk": "ual1/Sitting_Talking",
}

var parts := {}
var anim: AnimationPlayer
var tree: AnimationTree
var bend_pose
var speed := 0.0
var _speed_smooth := 0.0
var stance := "unarmed"
var _expr := "neutral"
var _expr_weights := {}
var _blink_t := 2.0
var _blink := 0.0
var dead := false
var look := {}

func setup(p_look: Dictionary) -> void:
	look = p_look
	parts = CB.build(p_look)
	add_child(parts.root)
	anim = parts.anim
	_build_tree()
	bend_pose = BendingPose.new()
	bend_pose.name = "BendingPose"
	parts.skeleton.add_child(bend_pose)
	bend_pose.setup(parts.skeleton)
	_blink_t = randf_range(1.0, 4.0)

func _build_tree() -> void:
	tree = AnimationTree.new()
	tree.name = "AnimationTree"
	parts.root.add_child(tree)
	tree.anim_player = tree.get_path_to(anim)
	var bt := AnimationNodeBlendTree.new()
	# Locomotion
	var loco := AnimationNodeBlendSpace1D.new()
	loco.min_space = 0.0
	loco.max_space = 7.0
	for pt in [[0.0, "ual1/Idle"], [1.4, "ual1/Walk"], [3.6, "ual1/Jog_Fwd"], [6.5, "ual1/Sprint"]]:
		var a := AnimationNodeAnimation.new()
		a.animation = pt[1]
		loco.add_blend_point(a, pt[0])
	# keep the walk, jog and sprint cycles in step, so feet do not skip as speed changes
	loco.sync = true
	bt.add_node("loco", loco, Vector2(0, 0))
	# Stance idle that replaces the locomotion idle when standing still. Two
	# slots crossfade, so changing stance (drawing a sword, sitting down)
	# blends instead of snapping.
	for slot in ["stance_a", "stance_b"]:
		var sa := AnimationNodeAnimation.new()
		sa.animation = "ual1/Idle"
		bt.add_node(slot, sa, Vector2(0, 200 if slot == "stance_a" else 280))
	var stance_x := AnimationNodeBlend2.new()
	bt.add_node("stance_x", stance_x, Vector2(120, 240))
	bt.connect_node("stance_x", 0, "stance_a")
	bt.connect_node("stance_x", 1, "stance_b")
	var stance_blend := AnimationNodeBlend2.new()
	bt.add_node("stance_blend", stance_blend, Vector2(250, 100))
	bt.connect_node("stance_blend", 0, "loco")
	bt.connect_node("stance_blend", 1, "stance_x")
	# Upper body one-shot
	var up_anim := AnimationNodeAnimation.new()
	up_anim.animation = "ual1/Punch_Jab"
	bt.add_node("up_anim", up_anim, Vector2(250, 300))
	var up_speed := AnimationNodeTimeScale.new()
	bt.add_node("up_speed", up_speed, Vector2(400, 300))
	bt.connect_node("up_speed", 0, "up_anim")
	var upper := AnimationNodeOneShot.new()
	upper.fadein_time = 0.12
	upper.fadeout_time = 0.26
	upper.filter_enabled = true
	for b in UPPER_BONES:
		upper.set_filter_path(NodePath("Armature/Skeleton3D:" + b), true)
	for side in ["l", "r"]:
		for f in FINGERS:
			for i in [1, 2, 3]:
				upper.set_filter_path(NodePath("Armature/Skeleton3D:%s_0%d_%s" % [f, i, side]), true)
	bt.add_node("upper", upper, Vector2(550, 100))
	bt.connect_node("upper", 0, "stance_blend")
	bt.connect_node("upper", 1, "up_speed")
	# Full body one-shot
	var full_anim := AnimationNodeAnimation.new()
	full_anim.animation = "ual1/Hit_Chest"
	bt.add_node("full_anim", full_anim, Vector2(550, 300))
	var full_speed := AnimationNodeTimeScale.new()
	bt.add_node("full_speed", full_speed, Vector2(700, 300))
	bt.connect_node("full_speed", 0, "full_anim")
	var full := AnimationNodeOneShot.new()
	full.fadein_time = 0.14
	full.fadeout_time = 0.3
	bt.add_node("full", full, Vector2(850, 100))
	bt.connect_node("full", 0, "upper")
	bt.connect_node("full", 1, "full_speed")
	bt.connect_node("output", 0, "full")
	tree.tree_root = bt
	tree.active = true
	tree.set("parameters/stance_blend/blend_amount", 0.0)

## Change the standing pose (idle loop used when not moving).
func set_stance(s: String) -> void:
	if s == stance or dead:
		return
	stance = s
	_crossfade_stance(STANCES.get(s, "ual1/Idle"))
	if bend_pose:
		bend_pose.set_form("ride" if s == "ride" else ("" if bend_pose.form == "ride" else bend_pose.form))

## Play an upper-body action (attacks, casts, gestures). Works while running.
func action(anim_name: String, time_scale: float = 1.0, full_body: bool = false) -> void:
	if dead or tree == null:
		return
	var key := "full" if full_body else "up"
	var node: AnimationNodeAnimation = tree.tree_root.get_node(key + "_anim")
	node.animation = anim_name
	tree.set("parameters/%s_speed/scale" % key, time_scale)
	tree.set("parameters/%s/request" % ("full" if full_body else "upper"), AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func stop_actions() -> void:
	if tree:
		tree.set("parameters/upper/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)

func action_length(anim_name: String) -> float:
	return anim.get_animation(anim_name).length if anim.has_animation(anim_name) else 0.5

func die(kind: String = "") -> void:
	if dead:
		return
	dead = true
	tree.active = false
	anim.play("ual1/Death01", 0.15)
	set_expression("pain")
	if bend_pose:
		bend_pose.set_form("")

var _stance_slot := 0
var _stance_x := 0.0
var _stance_x_target := 0.0

func _crossfade_stance(anim_name: String) -> void:
	_stance_slot = 1 - _stance_slot
	var node: AnimationNodeAnimation = tree.tree_root.get_node("stance_b" if _stance_slot == 1 else "stance_a")
	node.animation = anim_name
	_stance_x_target = float(_stance_slot)

## Play a looping full-body animation (sitting, working, dancing...),
## blended in through the stance slots rather than cutting the tree off.
func loop(anim_name: String) -> void:
	if dead or tree == null:
		return
	stance = "loop:" + anim_name
	_crossfade_stance(anim_name)

func resume_tree() -> void:
	if not dead:
		tree.active = true
		if stance.begins_with("loop:"):
			set_stance("unarmed")

func set_expression(expr: String) -> void:
	_expr = expr

func _process(delta: float) -> void:
	if tree == null:
		return
	_speed_smooth = lerpf(_speed_smooth, speed, minf(1.0, delta * 6.0))
	tree.set("parameters/loco/blend_position", _speed_smooth)
	_stance_x = move_toward(_stance_x, _stance_x_target, delta / 0.25)
	tree.set("parameters/stance_x/blend_amount", _stance_x)
	tree.set("parameters/stance_blend/blend_amount", clampf(1.0 - _speed_smooth / 0.6, 0.0, 1.0) if stance != "unarmed" else 0.0)
	_update_face(delta)

func _update_face(delta: float) -> void:
	if not parts.has("head"):
		return
	var target: Dictionary = FaceRig.EXPRESSIONS.get(_expr, {})
	# blinking
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink = 1.0
		_blink_t = randf_range(2.0, 5.5)
	_blink = maxf(0.0, _blink - delta * 7.0)
	var blink := sin(_blink * PI) if not dead else 1.0
	for mi in [parts.get("head"), parts.get("brows")]:
		if mi == null:
			continue
		var m: Mesh = mi.mesh
		for i in m.get_blend_shape_count():
			var n := String(m.get_blend_shape_name(i))
			var want := float(target.get(n, 0.0))
			if n.begins_with("blink"):
				want = maxf(want, blink)
			var cur: float = mi.get_blend_shape_value(i)
			mi.set_blend_shape_value(i, lerpf(cur, want, minf(1.0, delta * 10.0)) if not n.begins_with("blink") else want)
