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
PRESET = {"Feminine": 1.0, "Curvy": 0.35}
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

# --- hair: a cap over the crown and a bun at the back ---------------------
hb = bmesh.new()
hv = {}
for p in me.polygons:
    if face_reg[p.index] != "head":
        continue
    cs = [keys[0].data[i].co for i in p.vertices]
    cen = sum(cs, Vector()) / len(cs)
    # crown, back and sides of the skull, leaving the face and ears clear
    # crown and back of the skull only: nothing in front of the ears
    if cen.z < 1.63 or (cen.y < -0.04 and cen.z < 1.735) or (cen.y < 0.02 and cen.z < 1.69):
        continue
    vs = []
    for i in p.vertices:
        if i not in hv:
            v = me.vertices[i]
            hv[i] = hb.verts.new(keys[0].data[i].co + v.normal * 0.008)
        vs.append(hv[i])
    hb.faces.new(vs)
bun = bmesh.ops.create_uvsphere(hb, u_segments=8, v_segments=5, radius=0.06)
for v in bun["verts"]:
    v.co = Vector((v.co.x * 1.0, v.co.y * 0.85, v.co.z * 0.8)) + Vector((0, 0.095, 1.70))
hm = bpy.data.meshes.new("Hair")
hb.to_mesh(hm)
hb.free()
hair = new_obj("Hair", hm)
hg = hair.vertex_groups.new(name="Head")
hg.add(list(range(len(hm.vertices))), 1.0, "REPLACE")
hp = hm.attributes.new("part", "FLOAT_COLOR", "POINT")
for i in range(len(hm.vertices)):
    hp.data[i].color = (0.8, 0, 0, 1)

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
for ob in (outfit, hair):
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
RES = {"Body": 512, "Outfit": 512, "Hair": 256}


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
for ob in (body, outfit, hair):
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o is not ob and not (ob is body and False)
    bake_maps(ob)
for o in (vis, outfit, hair):
    o.hide_render = False
body.hide_render = True

tri = lambda o: sum(len(p.vertices) - 2 for p in o.data.polygons)
print("TRIS body_visible", tri(vis), "outfit", tri(outfit), "hair", tri(hair))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(work, "woman.blend"))
