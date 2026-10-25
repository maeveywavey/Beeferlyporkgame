extends SkeletonModifier3D
## Procedural layer on top of the motion-captured style clips: bending stances
## and flowing gestures, applied as rotations in character space after the
## animation has been sampled. Each art follows the martial style the original
## series built it on:
##   earth — Hung Gar: deep, wide horse stance; rooted, heavy upper body
##   fire  — Northern Shaolin: long front stance, chambered fist, torso coiled
##   water — Tai Chi: soft knees, slow circular arm flow, weight shifting
##   air   — Baguazhang: light, bouncing, torso twisting in circles, open palms
##   strike pulses (`pulse()`) add a short emphasis: a stomp, a lunge, a push.

var skel: Skeleton3D
var form := ""
var weight := 0.0
var aim_yaw := 0.0        # extra torso twist towards an aim target (radians)
var _t := 0.0
var _pulse := 0.0
var _pulse_kind := ""
var _ids := {}

func setup(s: Skeleton3D) -> void:
	skel = s
	for b in ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head", "thigh_l", "thigh_r", "calf_l", "calf_r",
			"foot_l", "foot_r", "upperarm_l", "upperarm_r", "lowerarm_l", "lowerarm_r", "hand_l", "hand_r", "clavicle_l", "clavicle_r"]:
		_ids[b] = s.find_bone(b)

func set_form(f: String) -> void:
	form = f

func pulse(kind: String) -> void:
	_pulse = 1.0
	_pulse_kind = kind

func _process(delta: float) -> void:
	_t += delta
	weight = move_toward(weight, 1.0 if form != "" else 0.0, delta * 3.0)
	_pulse = maxf(0.0, _pulse - delta * 2.5)

## Rotate a bone around a character-space axis (after animation).
func _rot(bone: String, axis: Vector3, angle: float) -> void:
	var i: int = _ids.get(bone, -1)
	if i < 0 or absf(angle) < 0.0001:
		return
	var g := skel.get_bone_global_pose(i)
	var nb := Basis(axis.normalized(), angle) * g.basis
	var p := skel.get_bone_parent(i)
	var pb := skel.get_bone_global_pose(p).basis if p >= 0 else Basis()
	skel.set_bone_pose_rotation(i, (pb.inverse() * nb).get_rotation_quaternion())

func _drop_pelvis(dy: float) -> void:
	var i: int = _ids.get("pelvis", -1)
	if i < 0:
		return
	var p := skel.get_bone_parent(i)
	var pb := skel.get_bone_global_pose(p).basis if p >= 0 else Basis()
	skel.set_bone_pose_position(i, skel.get_bone_pose_position(i) + pb.inverse() * Vector3(0, dy, 0))

func _process_modification() -> void:
	if skel == null:
		return
	if absf(aim_yaw) > 0.001:
		_rot("spine_02", Vector3.UP, aim_yaw * 0.5)
		_rot("spine_03", Vector3.UP, aim_yaw * 0.5)
	var w := weight
	if w <= 0.001 and _pulse <= 0.0:
		return
	var X := Vector3.RIGHT   # character's left (bones *_l live on +X)
	var Y := Vector3.UP
	var Z := Vector3.BACK    # character's forward is +Z
	var s := sin(_t * 1.6)
	var c := cos(_t * 1.6)
	match form:
		"earth":
			# horse stance: hips drop, thighs open and flex, knees bend, feet flat
			_drop_pelvis(-0.13 * w)
			_rot("thigh_l", Z, 0.28 * w)
			_rot("thigh_r", Z, -0.28 * w)
			_rot("thigh_l", X, -0.55 * w)
			_rot("thigh_r", X, -0.55 * w)
			_rot("calf_l", X, 0.95 * w)
			_rot("calf_r", X, 0.95 * w)
			_rot("foot_l", X, -0.4 * w)
			_rot("foot_r", X, -0.4 * w)
			_rot("spine_01", X, 0.08 * w)
		"fire":
			# front stance with coiled torso and the rear fist chambered
			_drop_pelvis(-0.06 * w)
			_rot("thigh_l", X, -0.45 * w)
			_rot("calf_l", X, 0.55 * w)
			_rot("thigh_r", X, 0.25 * w)
			_rot("calf_r", X, 0.25 * w)
			_rot("spine_02", Y, -0.25 * w)
			_rot("upperarm_r", X, 0.25 * w)
			_rot("lowerarm_r", Y, -0.4 * w)
		"water":
			# soft knees and slow circling arms, weight shifting side to side
			_drop_pelvis((-0.06 + 0.015 * s) * w)
			_rot("pelvis", Z, 0.05 * s * w)
			_rot("thigh_l", X, -0.25 * w)
			_rot("thigh_r", X, -0.25 * w)
			_rot("calf_l", X, 0.4 * w)
			_rot("calf_r", X, 0.4 * w)
			_rot("upperarm_l", X, (-0.25 + 0.3 * s) * w)
			_rot("upperarm_r", X, (-0.25 - 0.3 * s) * w)
			_rot("upperarm_l", Y, 0.25 * c * w)
			_rot("upperarm_r", Y, -0.25 * c * w)
			_rot("hand_l", Z, 0.3 * s * w)
			_rot("hand_r", Z, -0.3 * s * w)
		"air":
			# light bounce and circular torso twist with open palms
			var bounce := absf(sin(_t * 4.0))
			_drop_pelvis((-0.03 + 0.025 * bounce) * w)
			_rot("spine_02", Y, 0.3 * s * w)
			_rot("thigh_l", X, -0.2 * w)
			_rot("calf_l", X, 0.3 * w)
			_rot("hand_l", X, -0.5 * w)
			_rot("hand_r", X, -0.5 * w)
	# Strike emphasis
	var p := _pulse * _pulse
	if p > 0.0:
		match _pulse_kind:
			"stomp":
				_drop_pelvis(-0.08 * p)
				_rot("thigh_l", X, -0.6 * p)
				_rot("calf_l", X, 0.6 * p)
			"lunge":
				_rot("spine_01", X, 0.25 * p)
				_rot("thigh_l", X, -0.5 * p)
				_rot("calf_l", X, 0.5 * p)
			"push":
				_rot("spine_02", X, 0.15 * p)
				_rot("upperarm_l", Y, 0.4 * p)
				_rot("upperarm_r", Y, -0.4 * p)
			"sweep":
				_rot("spine_02", Y, 0.6 * p)
				_rot("pelvis", Y, 0.3 * p)
