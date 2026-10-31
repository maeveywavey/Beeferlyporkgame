"""Stage 1 of the Earth Kingdom commoner woman: geometry, rig and bakes.

blender -b <body.blend> --python tools/art/build_woman.py -- <workdir>

Writes <workdir>/woman.blend and baked maps (<part>_pos/nrm/ao/id.npy) that
paint_woman.py turns into textures.

Clothing model: an outfit replaces the body regions it covers. Its pieces
are copies of the covered body faces pushed out by a cloth thickness, with
the same skin weights and blend shapes as the body under them, so they bend
and reshape exactly with it; the covered body faces are not drawn. Nothing
sits on top of a hidden body, so nothing can poke through. The robe's lower
skirt is new geometry: each side is weighted to its own leg (thigh, and shin
at the hem), the middle shared between the legs and the waist to the hips,
so it opens and swings with the stride.
"""
import bpy
import bmesh
import math
import os
import sys
import numpy as np
from mathutils import Vector
from mathutils.kdtree import KDTree

sys.path.insert(0, os.path.dirname(__file__))
import common as C

work = sys.argv[sys.argv.index("--") + 1]
os.makedirs(work, exist_ok=True)
body = bpy.data.objects["Body"]
rig = bpy.data.objects["Rig"]
REGIONS = ["head", "torso", "upperarm", "forearm", "hand", "thigh", "shin", "foot"]
PRESET = {"Feminine": 1.0, "Curvy": 0.2}
for k in body.data.shape_keys.key_blocks:
    k.value = PRESET.get(k.name, 0.0)

COVER = {"torso", "upperarm", "forearm", "thigh", "shin", "foot"}
THICK = {"torso": 0.007, "upperarm": 0.007, "forearm": 0.007, "thigh": 0.006, "shin": 0.005, "foot": 0.009}
PART_ID = {"torso": 1, "upperarm": 2, "forearm": 3, "thigh": 4, "shin": 5, "foot": 6, "skirt": 7}

me = body.data
reg_attr = me.attributes["region"]
face_reg = [REGIONS[reg_attr.data[p.index].value] for p in me.polygons]
keys = me.shape_keys.key_blocks
groups = {g.index: g.name for g in body.vertex_groups}


def new_obj(name, mesh):
    ob = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(ob)
    ob.parent = rig
    mod = ob.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    return ob


# --- garment pieces from the covered body faces ------------------------------
vmap = {}
verts, faces, vpart, vsrc = [], [], [], []
for p in me.polygons:
    r = face_reg[p.index]
    if r not in COVER:
        continue
    idx = []
    for vi in p.vertices:
        key = vi
        if key not in vmap:
            v = me.vertices[vi]
            vmap[key] = len(verts)
            verts.append(v.co + v.normal * THICK[r])
            vpart.append(PART_ID[r])
            vsrc.append(vi)
        idx.append(vmap[key])
    faces.append(idx)

# bell sleeves: the forearm flares toward the wrist
for i, vi in enumerate(vsrc):
    c = me.vertices[vi].co
    if C.region_of(c) in ("forearm", "hand") and abs(c.x) > 0.43:
        s = "L" if c.x > 0 else "R"
        a, b = C.side_joint("elbow", s), C.side_joint("wrist", s)
        ax = C.seg_point(c, a, b)
        t = C.smooth(0.0, 1.0, (c - a).dot((b - a).normalized()) / (b - a).length)
        verts[i] = ax + (verts[i] - ax) * (1.0 + 0.85 * t)

gm = bpy.data.meshes.new("Outfit")
gm.from_pydata([tuple(v) for v in verts], [], faces)
gm.update()
outfit = new_obj("Outfit", gm)
for gi, gname in groups.items():
    outfit.vertex_groups.new(name=gname)
for i, vi in enumerate(vsrc):
    for g in me.vertices[vi].groups:
        outfit.vertex_groups[groups[g.group]].add([i], g.weight, "REPLACE")
outfit.shape_key_add(name="Basis", from_mix=False)
for kb in keys[1:]:
    nk = outfit.shape_key_add(name=kb.name, from_mix=False)
    for i, vi in enumerate(vsrc):
        nk.data[i].co = verts[i] + (kb.data[vi].co - keys[0].data[vi].co)

# --- skirt ---------------------------------------------------------------------
def body_section(z0, z1):
    pts = [keys[0].data[v.index].co for v in me.vertices if z0 <= v.co.z <= z1 and abs(v.co.x) < 0.3]
    return max(abs(p.x) for p in pts), min(p.y for p in pts), max(p.y for p in pts)

SEG = 20
RINGS = [  # z, extra half-width, extra depth, leg share, shin share at the hem
    (1.00, 0.008, 0.008, 0.0, 0.0),
    (0.90, 0.026, 0.026, 0.5, 0.0),
    (0.76, 0.050, 0.040, 1.0, 0.0),
    (0.60, 0.070, 0.050, 1.0, 0.0),
    (0.42, 0.090, 0.060, 1.0, 0.35),
]
wx, ymin, ymax = body_section(0.96, 1.04)
hx, hymin, hymax = body_section(0.86, 0.96)
sverts, sw = [], []
for ri, (z, ex, ey, legshare, shin) in enumerate(RINGS):
    bx = wx if ri == 0 else max(hx, wx)
    yc = (ymin + ymax) / 2
    by = (ymax - ymin) / 2 if ri == 0 else (hymax - hymin) / 2
    for s in range(SEG):
        a = 2 * math.pi * s / SEG
        x = math.sin(a) * (bx + ex)
        y = yc - math.cos(a) * (by + ey)
        sverts.append(Vector((x, y, z)))
        left = C.smooth(-0.08, 0.08, x)
        w = {}
        if legshare < 1.0:
            w["Hips"] = 1.0 - legshare
        for side, ws in (("L", left), ("R", 1.0 - left)):
            if ws <= 0:
                continue
            w["UpperLeg." + side] = w.get("UpperLeg." + side, 0) + legshare * ws * (1 - shin)
            if shin > 0:
                w["LowerLeg." + side] = shin * ws * legshare
        sw.append(w)
sfaces = []
for ri in range(len(RINGS) - 1):
    for s in range(SEG):
        a = ri * SEG + s
        b = ri * SEG + (s + 1) % SEG
        sfaces.append([a, b, b + SEG, a + SEG])
base_n = len(gm.vertices)
bm = bmesh.new()
bm.from_mesh(gm)
deform = bm.verts.layers.deform.verify()
skey_layers = {k.name: bm.verts.layers.shape.get(k.name) for k in outfit.data.shape_keys.key_blocks}
new_v = []
for i, co in enumerate(sverts):
    v = bm.verts.new(co)
    for gname, wv in sw[i].items():
        v[deform][outfit.vertex_groups[gname].index] = wv
    new_v.append(v)
bm.verts.ensure_lookup_table()
for f in sfaces:
    bm.faces.new([new_v[i] for i in f])
# skirt blend shapes follow the body nearby
kd = KDTree(len(me.vertices))
for v in me.vertices:
    if C.region_of(keys[0].data[v.index].co) in ("torso", "thigh", "shin"):
        kd.insert(keys[0].data[v.index].co, v.index)
kd.balance()
for name, layer in skey_layers.items():
    for i, v in enumerate(new_v):
        if name == "Basis":
            v[layer] = sverts[i]
            continue
        near = kd.find_n(sverts[i], 6)
        acc, wsum = Vector(), 0.0
        for co, idx, d in near:
            w = 1.0 / (d + 0.02)
            acc += (keys[name].data[idx].co - keys[0].data[idx].co) * w
            wsum += w
        v[layer] = sverts[i] + acc / wsum
bm.to_mesh(gm)
bm.free()
part = gm.attributes.new("part", "FLOAT_COLOR", "POINT")
for i in range(len(gm.vertices)):
    pid = vpart[i] if i < base_n else PART_ID["skirt"]
    part.data[i].color = (pid / 10.0, 0, 0, 1)
outfit.data.shape_keys.key_blocks["Basis"]
bpy.context.view_layer.objects.active = outfit
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0005)
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode="OBJECT")
for k in outfit.data.shape_keys.key_blocks:
    k.value = PRESET.get(k.name, 0.0)

# --- hair ------------------------------------------------------------------
# Owner's review of v2: the top of the hair is a sculpted cap piece with
# volume (never greased onto the scalp), a slight indent down the middle for a
# middle part, and the bangs and the long hair grow out of its edge so the
# three read as one mass, as in Fear Effect.
#
# The cap is a shell over the skull built on a polar grid round the head's
# centre: COLS_CAP columns of azimuth (0 = straight ahead) and rows from the
# hairline up to the crown. Each point sits on the head's surface (a ray from
# the centre) pushed out by the hair's thickness.
#   Hair_Bun:  the cap swept up into a high bun; its edge thins to the skin at
#              the hairline.
#   Hair_Long: shoulder-length hair worn down. Bangs hang from the cap's front
#              edge, parted in the middle, lengthening toward the temples to
#              frame the face. The hanging curtain shares the cap's edge
#              vertices round the sides and back; it is split into five
#              strips, each on a chain of three bones (Hair.<k>.<0..2>) so the
#              game can let it hang and swing limply, like a sheet of cloth.
#              Neighbouring strips share their edge vertices half-and-half, so
#              the curtain bends as one piece and never tears apart.
from mathutils.bvhtree import BVHTree
HEADC = Vector((0, -0.01, C.hz(1.66)))
_hv = [keys[0].data[v.index].co.copy() for v in me.vertices]
_hp = [list(p.vertices) for p in me.polygons if face_reg[p.index] == "head"]
HEAD_BVH = BVHTree.FromPolygons(_hv, _hp)
COLS_CAP = 16
CAP_T = (0.0, 0.3, 0.55, 0.8)       # rows from the hairline (0) toward the crown


def head_dir(theta, phi):
    return Vector((math.sin(theta) * math.sin(phi), -math.sin(theta) * math.cos(phi), math.cos(theta)))


def head_hit(theta, phi):
    d = head_dir(theta, phi)
    hit = HEAD_BVH.ray_cast(HEADC + d * 0.4, -d)
    return hit[0] if hit[0] is not None else HEADC + d * 0.1


def hairline_theta(phi, z):
    lo, hi = 0.05, 2.4
    for _ in range(30):
        mid = (lo + hi) / 2
        if head_hit(mid, phi).z > z:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def build_cap(hb, line_z, thick, edge_thick):
    """Returns the grid of BMVerts: rows[r][c], plus the crown vertex.
    line_z(phi) is the hairline's height, thick(t, phi) the hair's
    thickness."""
    rows = []
    for r, t in enumerate(CAP_T):
        row = []
        for c in range(COLS_CAP):
            phi = 2 * math.pi * c / COLS_CAP
            phi_s = phi if phi <= math.pi else phi - 2 * math.pi
            th0 = hairline_theta(phi_s, line_z(phi_s))
            theta = th0 * (1 - t)
            d = head_dir(theta, phi_s)
            w = edge_thick(phi_s) if r == 0 else thick(t, phi_s)
            row.append(hb.verts.new(head_hit(theta, phi_s) + d * w))
        rows.append(row)
    crown = hb.verts.new(head_hit(0.0, 0.0) + Vector((0, 0, 1)) * thick(1.0, 0.0))
    for r in range(len(rows) - 1):
        for c in range(COLS_CAP):
            c2 = (c + 1) % COLS_CAP
            hb.faces.new([rows[r][c], rows[r][c2], rows[r + 1][c2], rows[r + 1][c]])
    for c in range(COLS_CAP):
        hb.faces.new([rows[-1][c], rows[-1][(c + 1) % COLS_CAP], crown])
    return rows, crown


def part_thick(t, phi):
    """Full, rounded volume, fuller over the back of the crown; a shallow
    groove down the middle from the front hairline to the crown."""
    th = 0.030 + 0.008 * C.smooth(0.5, 2.6, abs(phi))
    groove = math.exp(-(phi / math.radians(14)) ** 2) * C.smooth(0.0, 0.3, t)
    return th - 0.016 * groove


def finish_hair(name, hm, weights):
    ob = new_obj(name, hm)
    for gname in {g for w in weights for g in w}:
        ob.vertex_groups.new(name=gname)
    for i, w in enumerate(weights):
        for gname, wv in w.items():
            ob.vertex_groups[gname].add([i], wv, "REPLACE")
    hp = hm.attributes.new("part", "FLOAT_COLOR", "POINT")
    for i in range(len(hm.vertices)):
        hp.data[i].color = (0.8, 0, 0, 1)
    return ob


# bun -------------------------------------------------------------------------
def bun_line(phi):
    # front hairline, temples, nape
    a = abs(phi)
    return C.hz(1.735) - (C.hz(1.735) - C.hz(1.70)) * C.smooth(0.3, 1.4, a) - 0.10 * C.smooth(1.6, 2.8, a)


hb = bmesh.new()
build_cap(hb, bun_line, lambda t, phi: 0.012 + 0.012 * t, lambda phi: 0.004)
bun = bmesh.ops.create_uvsphere(hb, u_segments=8, v_segments=6, radius=0.066)
for v in bun["verts"]:
    v.co = Vector((v.co.x, v.co.y * 0.95, v.co.z * 0.85)) + Vector((0, 0.012, C.hz(1.875)))
band = bmesh.ops.create_cone(hb, cap_ends=False, segments=8, radius1=0.044, radius2=0.05, depth=0.024)
for v in band["verts"]:
    v.co += Vector((0, 0.008, C.hz(1.822)))
hm = bpy.data.meshes.new("Hair_Bun")
bmesh.ops.recalc_face_normals(hb, faces=hb.faces)
hb.to_mesh(hm)
hb.free()
hair_bun = finish_hair("Hair_Bun", hm, [{"Head": 1.0}] * len(hm.vertices))


# long, with bangs and a five-strip curtain -----------------------------------
def long_line(phi):
    # the cap's edge: the hairline at the front, round the head at the
    # temples' height behind, where the curtain takes over
    return C.hz(1.735) - (C.hz(1.735) - C.hz(1.70)) * C.smooth(0.3, 1.2, abs(phi))


hb = bmesh.new()
cap_rows, crown = build_cap(hb, long_line, part_thick, lambda phi: 0.028)
ring = cap_rows[0]
# curtain columns: the cap's edge from 67.5 degrees round the back to -67.5
CUR_C = list(range(3, 14))
STRIPS = 5
COLS = len(CUR_C)
LOWER = [  # z, extra out, extra flare at the bottom
    (C.hz(1.63), 0.012),
    (1.545, 0.024),
    (1.46, 0.034),
]
cur_v = [[ring[c] for c in CUR_C]]
for z, out in LOWER:
    row = []
    for c in CUR_C:
        top = ring[c].co
        horiz = Vector((top.x, top.y - 0.01, 0))
        hl = horiz.length
        dirn = horiz.normalized()
        row.append(hb.verts.new(Vector((0, 0.01, 0)) + dirn * (hl + out) + Vector((0, 0, z))))
    cur_v.append(row)
for r in range(len(cur_v) - 1):
    for c in range(COLS - 1):
        hb.faces.new([cur_v[r][c], cur_v[r][c + 1], cur_v[r + 1][c + 1], cur_v[r + 1][c]])
# bangs: from the cap's front edge (columns -45..45 degrees, and down to the
# curtain's first row at 67.5), parted in the middle: short at the part,
# longer toward the temples so the fringe frames the face
front_c = [14, 15, 0, 1, 2]     # -45, -22.5, 0, 22.5, 45 degrees
bang_low = {}
for c in front_c:
    phi = 2 * math.pi * c / COLS_CAP
    phi = phi if phi <= math.pi else phi - 2 * math.pi
    top = ring[c].co
    drop = 0.008 + 0.05 * (abs(phi) / math.radians(45)) ** 1.3
    th = hairline_theta(phi, top.z - drop)
    bang_low[c] = hb.verts.new(head_hit(th, phi) + head_dir(th, phi) * 0.007)
bang_low[13] = cur_v[1][-1]   # +67.5 side meets the curtain
bang_low[3] = cur_v[1][0]
seq = [13, 14, 15, 0, 1, 2, 3]
for i in range(len(seq) - 1):
    a_, b_ = seq[i], seq[i + 1]
    hb.faces.new([ring[a_], ring[b_], bang_low[b_], bang_low[a_]])
hm = bpy.data.meshes.new("Hair_Long")
bmesh.ops.recalc_face_normals(hb, faces=hb.faces)
hb.verts.index_update()
curtain_pts = [v.co.copy() for row in cur_v for v in row]
# weights: everything on the head, the curtain below its top row on its strip
vw = {v.index: {"Head": 1.0} for v in hb.verts}
for r in range(1, len(cur_v)):
    for c in range(COLS):
        ks = [c // 2] if c % 2 == 1 else [k for k in (c // 2 - 1, c // 2) if 0 <= k < STRIPS]
        w = {}
        for k in ks:
            w[f"Hair.{k}.{r - 1}"] = w.get(f"Hair.{k}.{r - 1}", 0) + 1.0 / len(ks)
        vw[cur_v[r][c].index] = w
weights = [vw[i] for i in range(len(hb.verts))]
hb.to_mesh(hm)
hb.free()

bpy.ops.object.select_all(action="DESELECT")
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
for k in range(STRIPS):
    col = 2 * k + 1
    prev = rig.data.edit_bones["Head"]
    for b in range(3):
        eb = rig.data.edit_bones.new(f"Hair.{k}.{b}")
        eb.head = curtain_pts[b * COLS + col]
        eb.tail = curtain_pts[(b + 1) * COLS + col]
        eb.parent = prev
        eb.use_connect = b > 0
        prev = eb
bpy.ops.object.mode_set(mode="OBJECT")
hair_long = finish_hair("Hair_Long", hm, weights)
for ob in (hair_bun, hair_long):
    ob.data.materials.clear()
hair = hair_long

# --- the visible body: everything the outfit does not cover -----------------
vis = body.copy()
vis.data = body.data.copy()
vis.name = "BodyVisible"
bpy.context.scene.collection.objects.link(vis)
bmv = bmesh.new()
bmv.from_mesh(vis.data)
ra = bmv.faces.layers.int.get("region")
bmesh.ops.delete(bmv, geom=[f for f in bmv.faces if REGIONS[f[ra]] in COVER], context="FACES")
bmv.to_mesh(vis.data)
bmv.free()
body.hide_render = True
body.hide_set(True)

# --- UVs for outfit and hair ---------------------------------------------------
for ob in (outfit, hair_bun, hair_long):
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=0.012, scale_to_bounds=True)
    bpy.ops.object.mode_set(mode="OBJECT")

# --- bakes -----------------------------------------------------------------------
sc = bpy.context.scene
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = 64
sc.render.bake.margin = 4
sc.world = sc.world or bpy.data.worlds.new("W")
sc.world.use_nodes = True
sc.world.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)
RES = {"Body": 512, "Outfit": 512, "Hair_Bun": 256, "Hair_Long": 256}


def bake_maps(ob):
    res = RES[ob.name]
    mat = bpy.data.materials.new(ob.name + "_bake")
    mat.use_nodes = True
    nt = mat.node_tree
    ob.data.materials.clear()
    ob.data.materials.append(mat)
    tex = nt.nodes.new("ShaderNodeTexImage")
    nt.nodes.active = tex
    # Position, normal and part id are baked as emission, encoded into 0..1:
    # position (x/2+0.5, y/2+0.5, z/2), normal *0.5+0.5, id = part/10.
    attrn = nt.nodes.new("ShaderNodeAttribute")
    attrn.attribute_name = "part"
    tc = nt.nodes.new("ShaderNodeTexCoord")
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    enc_p = nt.nodes.new("ShaderNodeVectorMath")
    enc_p.operation = "MULTIPLY_ADD"
    enc_p.inputs[1].default_value = (0.5, 0.5, 0.5)
    enc_p.inputs[2].default_value = (0.5, 0.5, 0.0)
    nt.links.new(tc.outputs["Object"], enc_p.inputs[0])
    enc_n = nt.nodes.new("ShaderNodeVectorMath")
    enc_n.operation = "MULTIPLY_ADD"
    enc_n.inputs[1].default_value = (0.5, 0.5, 0.5)
    enc_n.inputs[2].default_value = (0.5, 0.5, 0.5)
    nt.links.new(geo.outputs["Normal"], enc_n.inputs[0])
    em = nt.nodes.new("ShaderNodeEmission")
    bsdf = nt.nodes["Principled BSDF"]
    outn = nt.nodes["Material Output"]
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    result = {}
    src = {"POSITION": enc_p.outputs[0], "NORMAL": enc_n.outputs[0], "EMIT": attrn.outputs["Color"]}
    for kind in ("POSITION", "NORMAL", "AO", "EMIT"):
        img = bpy.data.images.new(f"{ob.name}_{kind}", res, res, float_buffer=True, alpha=True)
        img.generated_color = (0, 0, 0, 0)
        tex.image = img
        if kind == "AO":
            nt.links.new(bsdf.outputs[0], outn.inputs["Surface"])
            bpy.ops.object.bake(type="AO", margin=4)
        else:
            nt.links.new(src[kind], em.inputs["Color"])
            nt.links.new(em.outputs[0], outn.inputs["Surface"])
            bpy.ops.object.bake(type="EMIT", margin=4)
        px = np.array(img.pixels[:], dtype=np.float32).reshape(res, res, 4)[::-1]
        result[kind] = px
    pos = result["POSITION"][..., :3] * np.array([2, 2, 2], np.float32) - np.array([1, 1, 0], np.float32)
    nrm = result["NORMAL"][..., :3] * 2 - 1
    cov = (result["POSITION"][..., 3] > 0.5).astype(np.uint8)
    np.save(os.path.join(work, f"{ob.name}_pos.npy"), pos)
    np.save(os.path.join(work, f"{ob.name}_nrm.npy"), nrm)
    np.save(os.path.join(work, f"{ob.name}_ao.npy"), result["AO"])
    # UV polygons (for coverage masks and UV-layout pictures)
    import json
    uvl = ob.data.uv_layers.active.data
    polys = [[list(uvl[li].uv) for li in p.loop_indices] for p in ob.data.polygons]
    with open(os.path.join(work, f"{ob.name}_uv.json"), "w") as f:
        json.dump(polys, f)
    np.save(os.path.join(work, f"{ob.name}_id.npy"), result["EMIT"])
    np.save(os.path.join(work, f"{ob.name}_cov.npy"), cov)


# The body texture covers the whole body (other outfits show other skin),
# baked with nothing hiding it.
body.hide_render = False
body.hide_set(False)
for ob in (body, outfit, hair_bun, hair_long):
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o is not ob and not (ob is body and False)
    bake_maps(ob)
for o in (vis, outfit, hair_bun, hair_long):
    o.hide_render = False
body.hide_render = True

tri = lambda o: sum(len(p.vertices) - 2 for p in o.data.polygons)
print("TRIS body_visible", tri(vis), "outfit", tri(outfit), "hair_bun", tri(hair_bun), "hair_long", tri(hair_long))
import json as _j
with open(os.path.join(work, "joints.json"), "w") as f:
    _j.dump({k: list(v) for k, v in C.J.items()}, f)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(work, "woman.blend"))
