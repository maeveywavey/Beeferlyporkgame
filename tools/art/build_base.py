"""Build the rigged base body with body-shape blend shapes.

blender -b assets/source/humanoid_base.blend --python tools/art/build_base.py -- <out.blend>

From the owner's base mesh (HumanoidBase_NotOverlapping, 402 triangles):
  - adds a few loops where knees, elbows and the waist need them to bend,
  - rigs it (Hips, Spine, Chest, Neck, Head, Clavicle/UpperArm/LowerArm/Hand,
    UpperLeg/LowerLeg/Foot, left and right) with automatic weights,
  - tags each face with its body region (head, torso, upperarm, forearm,
    hand, thigh, shin, foot), which outfits use to hide what they cover,
  - adds blend shapes, each a full-strength target mixed by a slider:
      Tall, Short, Heavy, Thin, Muscular, Curvy, Flat, Feminine,
      Child, Teen, Elder
    Height and age shapes also move the joints; their joint offsets are
    written next to the .blend as <out>_joints.json for the game to apply to
    the skeleton.
"""
import bpy
import bmesh
import json
import math
import sys
import os
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(__file__))
import common as C

out = sys.argv[sys.argv.index("--") + 1]

for o in list(bpy.data.objects):
    if o.name != "HumanoidBase_NotOverlapping":
        bpy.data.objects.remove(o)
body = bpy.data.objects["HumanoidBase_NotOverlapping"]
body.name = "Body"
body.data.name = "Body"
bpy.context.view_layer.objects.active = body
body.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# --- loops for bending -------------------------------------------------------
bm = bmesh.new()
bm.from_mesh(body.data)


def cut(z, pred):
    geom = [f for f in bm.faces if all(pred(v.co) for v in f.verts)]
    edges = list({e for f in geom for e in f.edges})
    verts = list({v for f in geom for v in f.verts})
    bmesh.ops.bisect_plane(bm, geom=verts + edges + geom, plane_co=(0, 0, z), plane_no=(0, 0, 1))


legs = lambda co: co.z < 0.90
cut(0.70, legs)      # mid-thigh
cut(0.28, legs)      # mid-shin
cut(0.43, legs)      # below the knee (hem line for robes)
cut(1.00, lambda co: abs(co.x) < 0.22 and 0.84 < co.z < 1.2)   # low waist
bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
bm.to_mesh(body.data)
bm.free()
body.data.update()

# --- base proportions (owner's review of v1) -------------------------------
#  - the arms sit 4 cm higher in the socket, so the shoulder is the top of the
#    arm, not a pad above it;
#  - everyone but the thin shape carries 1.2x girth, the shoulders less;
#  - the inner thighs are fuller, closing the gap between the legs.
for v in body.data.vertices:
    c = v.co
    ax = abs(c.x)
    if c.z > 0.98 and ax > 0.19:
        # the arm swings up about the shoulder; the blend over 0.19-0.25 m
        # keeps the armpit and the top of the shoulder joined to the torso
        v.co = C.raise_arm(c, C.smooth(0.19, 0.25, ax))
    c = v.co
    if 0.07 < ax < 0.235 and c.z > 1.36:     # let the shoulder line slope down
        c.z -= 0.03 * C.smooth(0.07, 0.21, ax) * C.smooth(1.40, 1.46, c.z)
raised = {v.index: v.co.copy() for v in body.data.vertices}
_SEG0 = {"upperarm": ("shoulder", "elbow"), "forearm": ("elbow", "wrist"),
         "thigh": ("thigh", "knee"), "shin": ("knee", "ankle")}
for v in body.data.vertices:
    c = v.co
    r = C.region_of(c)
    if r in _SEG0:
        sd = "L" if c.x >= 0 else "R"
        a_, b_ = _SEG0[r]
        axp = C.seg_point(c, C.side_joint(a_, sd), C.side_joint(b_, sd))
        v.co = axp + (c - axp) * 1.2
        if r == "thigh":
            sgn = 1 if c.x >= 0 else -1
            if (v.co.x - axp.x) * sgn < 0:            # inner side of the thigh
                v.co.x -= sgn * 0.022 * C.smooth(0.55, 0.88, c.z)
    elif r == "torso":
        kx = 1.0 + 0.2 * (1 - 0.6 * C.smooth(1.25, 1.42, c.z))
        v.co = Vector((c.x * kx, c.y * 1.2, c.z))
    elif r == "head" and c.z < 1.53:
        v.co = Vector((c.x * 1.1, c.y * 1.1, c.z))

# --- regions -----------------------------------------------------------------
regions = ["head", "torso", "upperarm", "forearm", "hand", "thigh", "shin", "foot"]
attr = body.data.attributes.new("region", "INT", "FACE")
for p in body.data.polygons:
    attr.data[p.index].value = regions.index(C.region_of(p.center))

# --- rig ---------------------------------------------------------------------
rig = C.build_armature()
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type="ARMATURE_AUTO")

# --- shape keys --------------------------------------------------------------
N = C.J["neck"]
SEGS = {
    "upperarm": ("shoulder", "elbow"), "forearm": ("elbow", "wrist"), "hand": ("wrist", "hand_end"),
    "thigh": ("thigh", "knee"), "shin": ("knee", "ankle"), "foot": ("ankle", "toe"),
}


def vregion(p):
    return C.region_of(p)


def limb_axis(p, reg):
    s = "L" if p.x >= 0 else "R"
    a, b = SEGS[reg]
    return C.seg_point(p, C.side_joint(a, s), C.side_joint(b, s))


def radial(p, reg, k_limb, k_torso_x, k_torso_y, k_head=1.0, k_neck=None):
    if reg in SEGS:
        c = limb_axis(p, reg)
        return c + (p - c) * k_limb
    if reg == "head":
        if p.z < 1.53:   # neck
            kn = k_neck if k_neck is not None else (k_torso_x + k_torso_y) / 2
            return Vector((p.x * kn, p.y * kn, p.z))
        c = Vector((0, -0.02, 1.65))
        return c + (p - c) * k_head
    return Vector((p.x * k_torso_x, p.y * k_torso_y, p.z))


def arm_shift(p, reg, dx):
    if reg in ("upperarm", "forearm", "hand"):
        return p + Vector((dx if p.x > 0 else -dx, 0, 0))
    return p


def k_tall(p, reg, f=1.10):
    if p.z < N.z:
        return Vector((p.x, p.y, p.z * f))
    return p + Vector((0, 0, N.z * (f - 1)))


def k_heavy(p, reg):
    q = radial(p, reg, 1.30 if reg not in ("hand", "foot") else 1.08, 1.24, 1.26, 1.05, 1.28)
    if reg == "torso":
        # the belly hangs low and soft rather than jutting like a drum
        belly = C.smooth(0.86, 0.98, p.z) * (1 - C.smooth(1.08, 1.24, p.z))
        if p.y < 0:
            q.y -= 0.04 * belly
            q.z -= 0.02 * belly
        else:
            q.y += 0.03 * C.smooth(0.84, 0.92, p.z) * (1 - C.smooth(1.0, 1.08, p.z))
    if reg == "thigh":
        # the upper thigh takes up the hip width, outside and inside
        q.x += (0.025 if p.x > 0 else -0.025) * C.smooth(0.6, 0.88, p.z)
    if reg == "head" and p.z < 1.66 and p.z > 1.53:
        q.x *= 1.06
    return arm_shift(q, reg, 0.035) if reg in ("upperarm", "forearm", "hand") else q


def k_thin(p, reg):
    q = radial(p, reg, 0.78 if reg not in ("hand", "foot") else 0.95, 0.86, 0.82, 1.0, 0.86)
    return arm_shift(q, reg, -0.02)


def k_muscular(p, reg):
    k = {"upperarm": 1.28, "forearm": 1.18, "thigh": 1.16, "shin": 1.16}.get(reg, 1.0)
    q = radial(p, reg, k, 1.0, 1.0, 1.0, 1.32)
    if reg == "torso":
        sh = C.smooth(1.22, 1.40, p.z)
        q.x *= 1.0 + 0.14 * sh
        if p.y < 0:
            q.y -= 0.035 * C.smooth(1.18, 1.28, p.z) * (1 - C.smooth(1.36, 1.44, p.z))
        if p.y > 0:
            q.y += 0.025 * sh
    return arm_shift(q, reg, 0.03)


def k_curvy(p, reg):
    q = p.copy()
    if reg == "torso":
        hips = 1 - C.smooth(1.0, 1.08, p.z)
        waist = C.smooth(1.0, 1.08, p.z) * (1 - C.smooth(1.14, 1.2, p.z))
        q.x *= 1.0 + 0.18 * hips - 0.10 * waist
        bust = C.smooth(1.18, 1.25, p.z) * (1 - C.smooth(1.34, 1.40, p.z))
        if p.y < -0.02:
            q.y -= 0.05 * bust * C.smooth(0.0, 0.05, abs(p.x)) * (1 - C.smooth(0.12, 0.17, abs(p.x)))
        if p.y > 0.0:
            q.y += 0.04 * hips
    if reg == "thigh":
        c = limb_axis(p, reg)
        q = c + (p - c) * (1.0 + 0.18 * C.smooth(0.5, 0.85, p.z))
        # the hip line runs on into the thigh: no ledge
        q.x += (0.035 if p.x > 0 else -0.035) * C.smooth(0.55, 0.88, p.z)
        if p.y > c.y:
            q.y += 0.02 * C.smooth(0.65, 0.88, p.z)
    return q


def k_flat(p, reg):
    q = p.copy()
    if reg == "torso":
        if p.y < -0.06:
            q.y = -0.06 + (p.y + 0.06) * 0.4
        hips = C.smooth(0.84, 0.92, p.z) * (1 - C.smooth(1.0, 1.08, p.z))
        q.x *= 1.0 - 0.08 * hips
    return q


def k_feminine(p, reg):
    q = p.copy()
    if reg == "torso":
        sh = C.smooth(1.25, 1.42, p.z)
        hips = 1 - C.smooth(1.0, 1.08, p.z)
        waist = C.smooth(1.0, 1.08, p.z) * (1 - C.smooth(1.14, 1.2, p.z))
        q.x *= 1.0 - 0.10 * sh + 0.07 * hips - 0.06 * waist
        bust = C.smooth(1.18, 1.25, p.z) * (1 - C.smooth(1.34, 1.40, p.z))
        if p.y < -0.02:
            q.y -= 0.025 * bust * C.smooth(0.0, 0.05, abs(p.x)) * (1 - C.smooth(0.12, 0.17, abs(p.x)))
    elif reg in ("upperarm", "forearm", "hand"):
        q = radial(p, reg, 0.88, 1, 1)
        q = arm_shift(q, reg, -0.022)
        if reg == "hand":
            w = C.side_joint("wrist", "L" if p.x > 0 else "R") + Vector((-0.022 if p.x > 0 else 0.022, 0, 0))
            q = w + (q - w) * 0.9
    elif reg in ("thigh", "shin"):
        q = radial(p, reg, 0.94, 1, 1)
        if reg == "thigh":
            q.x += (0.012 if p.x > 0 else -0.012) * C.smooth(0.6, 0.88, p.z)
    elif reg == "foot":
        a = C.side_joint("ankle", "L" if p.x > 0 else "R")
        q = Vector((a.x + (p.x - a.x) * 0.9, a.y + (p.y - a.y) * 0.9, p.z))
    elif reg == "head":
        if p.z < 1.53:
            q.x *= 0.86
            q.y *= 0.9
        elif p.z < 1.64:
            q.x *= 0.92
    return q


def k_child(p, reg):
    s = 0.58
    # children's shoulders are narrow: no football-player pads
    if reg in ("upperarm", "forearm", "hand"):
        p = p - Vector((0.04 if p.x > 0 else -0.04, 0, 0))
    elif reg == "torso":
        p = Vector((p.x * (1 - 0.18 * C.smooth(1.2, 1.42, p.z)), p.y, p.z))
    if reg == "head" and p.z >= 1.50:
        return N * s + (p - N) * 0.80
    q = Vector((p.x * s, p.y * s, p.z * s))
    if reg in SEGS:
        c = limb_axis(Vector((q.x / s, q.y / s, q.z / s)), reg) * s
        q = c + (q - c) * 0.95
    return q


def k_teen(p, reg):
    q = radial(p, reg, 0.90, 0.93, 0.92, 1.0, 0.9)
    if reg == "head" and p.z >= 1.50:
        q = N + (p - N) * 0.97
    return k_tall(q, reg, 0.93) if q.z < N.z else q + Vector((0, 0, N.z * -0.07))


def k_elder(p, reg):
    q = radial(p, reg, 0.92, 1.0, 1.04, 1.0, 0.95)
    pivot = Vector((0, 0.0, 1.05))
    t = C.smooth(1.05, 1.45, p.z)
    ang = math.radians(14) * t + (math.radians(10) if reg == "head" and p.z > 1.5 else 0)
    rot = Matrix.Rotation(ang, 4, "X")
    q = pivot + (rot @ (q - pivot))
    if reg in ("upperarm", "forearm", "hand", "torso") and p.z > 1.3:
        q.z -= 0.025 * C.smooth(1.3, 1.42, p.z)
    return Vector((q.x, q.y, q.z * 0.97))


KEYS = {
    "Tall": lambda p, r: k_tall(p, r, 1.10), "Short": lambda p, r: k_tall(p, r, 0.90),
    "Heavy": k_heavy, "Thin": k_thin, "Muscular": k_muscular, "Curvy": k_curvy, "Flat": k_flat,
    "Feminine": k_feminine, "Child": k_child, "Teen": k_teen, "Elder": k_elder,
}

body.shape_key_add(name="Basis", from_mix=False)
base = [v.co.copy() for v in body.data.vertices]
vreg = [vregion(c) for c in base]
for name, fn in KEYS.items():
    kb = body.shape_key_add(name=name, from_mix=False)
    for i, c in enumerate(base):
        if name == "Thin":
            # the thin shape keeps its old girth: built from the body before
            # the 1.2x
            kb.data[i].co = fn(raised[i], vreg[i])
        else:
            kb.data[i].co = fn(c, vreg[i])

# Second halves of Heavy, Feminine and Curvy: slider values 1..2 add these,
# doubling the change in hips, waist, buttocks, belly, breasts and legs only
# (arms, shoulders, neck and head stay at the first half). In game a slider s
# in 0..2 sets <Key> = min(s, 1) and <Key>More = max(s - 1, 0).
def more_mask(c, reg):
    if reg in ("thigh", "shin"):
        return 1.0
    if reg == "torso":
        return 1.0 - C.smooth(1.34, 1.42, c.z)
    return 0.0
for name in ("Heavy", "Feminine", "Curvy"):
    src = body.data.shape_keys.key_blocks[name]
    kb = body.shape_key_add(name=name + "More", from_mix=False)
    for i, c in enumerate(base):
        kb.data[i].co = c + (src.data[i].co - c) * more_mask(c, vreg[i])

# Joint offsets per key, for the skeleton in game (joints use the region of
# the limb they start).
JREG = {"hips": "torso", "spine": "torso", "chest": "torso", "neck": "head", "head": "head", "head_top": "head",
        "clavicle": "torso", "shoulder": "upperarm", "elbow": "forearm", "wrist": "hand", "hand_end": "hand",
        "thigh": "thigh", "knee": "shin", "ankle": "foot", "toe": "foot", "root": "foot"}
joints = {}
for name, fn in KEYS.items():
    joints[name] = {j: list(fn(C.J[j].copy(), JREG[j]) - C.J[j]) for j in C.J}
with open(os.path.splitext(out)[0] + "_joints.json", "w") as f:
    json.dump(joints, f, indent=1)

print("BODY verts", len(body.data.vertices), "tris", sum(len(p.vertices) - 2 for p in body.data.polygons))
bpy.ops.wm.save_as_mainfile(filepath=out)
