#!/usr/bin/env python3
"""Bring the character glTFs down to a PS1 polygon budget.

The CC0 character kit ships at 13-15k triangles per body and 13-27k per outfit.
This script reads the originals kept in assets/source_hi/ and writes
decimated copies to assets/characters/, keeping what the game needs:
the skeleton and skin, UVs (decimation is texture-aware, so the painted
textures still fit), and joint weights (taken from the nearest original vertex).

Budgets (triangles):
  body incl. head ......... about 640 (the head gets 280 of it)
  eyes / eyebrows ......... 56 / 40
  hair and beards ......... 90-150
  outfit pieces ........... 4% of the original, 30-200 each

Needs: pip install pymeshlab (and libopengl0 on Linux).
Usage: python3 tools/lowpoly_assets.py
"""
import glob
import json
import os
import struct
import sys

import numpy as np
import pymeshlab

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "source_hi", "characters")
DST = os.path.join(ROOT, "assets", "characters")

COMP = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT2": 4, "MAT3": 9, "MAT4": 16}


def read_accessor(j, blob, idx):
    a = j["accessors"][idx]
    bv = j["bufferViews"][a["bufferView"]]
    dt = np.dtype(COMP[a["componentType"]])
    n = NCOMP[a["type"]]
    off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = bv.get("byteStride", 0)
    if stride and stride != dt.itemsize * n:
        raw = np.frombuffer(blob, np.uint8, count=stride * a["count"], offset=off).reshape(a["count"], stride)
        return raw[:, : dt.itemsize * n].copy().view(dt).reshape(a["count"], n)
    return np.frombuffer(blob, dt, count=a["count"] * n, offset=off).reshape(a["count"], n).copy()


class Packer:
    """Builds a fresh binary buffer with one bufferView per accessor."""

    def __init__(self):
        self.data = bytearray()
        self.views = []
        self.accessors = []

    def add(self, arr, ctype, atype, target=None, minmax=False):
        raw = np.ascontiguousarray(arr).tobytes()
        while len(self.data) % 4:
            self.data.append(0)
        view = {"buffer": 0, "byteOffset": len(self.data), "byteLength": len(raw)}
        if target:
            view["target"] = target
        self.views.append(view)
        self.data += raw
        acc = {"bufferView": len(self.views) - 1, "componentType": ctype, "count": int(arr.shape[0]), "type": atype}
        if minmax:
            acc["min"] = [float(x) for x in arr.min(axis=0)]
            acc["max"] = [float(x) for x in arr.max(axis=0)]
        self.accessors.append(acc)
        return len(self.accessors) - 1


def decimate(pos, uv, faces, target):
    """Quadric edge collapse with texture. Returns (pos, uv, faces) with
    vertices split per UV so the result is directly usable by glTF."""
    ms = pymeshlab.MeshSet()
    ms.add_mesh(pymeshlab.Mesh(vertex_matrix=pos.astype(np.float64), face_matrix=faces.astype(np.int32), v_tex_coords_matrix=uv.astype(np.float64)))
    ms.apply_filter("compute_texcoord_transfer_vertex_to_wedge")
    if target < faces.shape[0]:
        # UV seams are boundaries; keep them loosely so the budget can be met
        for attempt in range(4):
            ms.meshing_decimation_quadric_edge_collapse_with_texture(targetfacenum=max(8, int(target)), preserveboundary=attempt < 1, boundaryweight=1.0, extratcoordw=0.2 if attempt < 2 else 0.02, preservenormal=True, qualitythr=0.5, optimalplacement=True, planarquadric=True)
            if ms.current_mesh().face_number() <= target * 1.15:
                break
    ms.meshing_remove_unreferenced_vertices()
    m = ms.current_mesh()
    V = m.vertex_matrix()
    F = m.face_matrix()
    W = m.wedge_tex_coord_matrix().reshape(-1, 3, 2)
    out_pos, out_uv, out_f, seen = [], [], np.zeros_like(F), {}
    for fi in range(F.shape[0]):
        for k in range(3):
            key = (int(F[fi, k]), round(float(W[fi, k, 0]), 5), round(float(W[fi, k, 1]), 5))
            if key not in seen:
                seen[key] = len(out_pos)
                out_pos.append(V[key[0]])
                out_uv.append(W[fi, k])
            out_f[fi, k] = seen[key]
    return np.array(out_pos, np.float32), np.array(out_uv, np.float32), out_f.astype(np.uint32)


select_mask_threshold = [0.0]


def surface_error(orig, new_pos, new_faces):
    """95th percentile distance from the original vertices to the decimated
    surface (approximated by its vertices and face centres), in metres."""
    cen = new_pos[new_faces].mean(axis=1)
    e0 = new_pos[new_faces[:, 0]] * 0.5 + new_pos[new_faces[:, 1]] * 0.5
    pts = np.concatenate([new_pos, cen, e0])
    sample = orig[:: max(1, len(orig) // 1500)]
    d = np.empty(len(sample))
    for i in range(0, len(sample), 128):
        d[i:i + 128] = np.sqrt(((sample[i:i + 128, None, :] - pts[None, :, :]) ** 2).sum(axis=2).min(axis=1))
    return float(np.percentile(d, 95))


def smooth_normals(pos, faces):
    n = np.zeros_like(pos)
    p0, p1, p2 = pos[faces[:, 0]], pos[faces[:, 1]], pos[faces[:, 2]]
    fn = np.cross(p1 - p0, p2 - p0)
    for k in range(3):
        np.add.at(n, faces[:, k], fn)
    # vertices split by UV share positions: average normals over equal positions
    keys = {}
    for i, p in enumerate(map(tuple, np.round(pos, 5))):
        keys.setdefault(p, []).append(i)
    for idxs in keys.values():
        if len(idxs) > 1:
            n[idxs] = n[idxs].sum(axis=0)
    ln = np.linalg.norm(n, axis=1, keepdims=True)
    return (n / np.maximum(ln, 1e-9)).astype(np.float32)


def nearest(src, dst):
    out = np.empty(dst.shape[0], np.int64)
    for i in range(0, dst.shape[0], 256):
        d = ((dst[i:i + 256, None, :] - src[None, :, :]) ** 2).sum(axis=2)
        out[i:i + 256] = d.argmin(axis=1)
    return out


def budget(fname, mesh_name, src_tris):
    base = os.path.basename(fname)
    low = mesh_name.lower()
    if base.startswith("Superhero"):
        if "face" == low:
            return 40, 0
        if low.startswith("face.") or "eye" in low:
            return 56, 0
        return 640, 280
    if base.startswith("Eyebrows"):
        return 40, 0
    if base.startswith("Hair_Beard"):
        return 90, 0
    if base.startswith("Hair_"):
        return (150 if "Buns" in base or "Long" in base else 100), 0
    return int(min(260, max(48, src_tris * 0.045))), 0


def process(path):
    j = json.load(open(path))
    blob = open(path.replace(".gltf", ".bin"), "rb").read()
    pk = Packer()
    before = after = 0
    used = set()
    for m in j["meshes"]:
        for p in m["primitives"]:
            used.update(p["attributes"].values())
            if "indices" in p:
                used.add(p["indices"])
    new_meshes = []
    for m in j["meshes"]:
        prims = []
        for p in m["primitives"]:
            at = p["attributes"]
            pos = read_accessor(j, blob, at["POSITION"]).astype(np.float32)
            uv = read_accessor(j, blob, at["TEXCOORD_0"]).astype(np.float32)
            faces = read_accessor(j, blob, p["indices"]).reshape(-1, 3).astype(np.int64)
            before += len(faces)
            target, head = budget(path, m.get("name", ""), len(faces))
            if head:
                select_mask_threshold[0] = float(pos[:, 1].max()) - 0.25
            if head:
                npos, nuv, nf = decimate_head(pos, uv, faces, target, head, select_mask_threshold[0])
            else:
                npos, nuv, nf = decimate(pos, uv, faces, target)
                # outfit pieces: raise the budget until the shape holds (within 3.5 cm)
                if os.path.basename(path).startswith(("Male_", "Female_")):
                    mult = 1.0
                    while surface_error(pos, npos, nf.astype(np.int64)) > 0.035 and target * mult < len(faces) * 0.5:
                        mult *= 1.5
                        npos, nuv, nf = decimate(pos, uv, faces, int(target * mult))
            after += len(nf)
            nn = smooth_normals(npos, nf.astype(np.int64))
            attrs = {"POSITION": pk.add(npos, 5126, "VEC3", 34962, True), "NORMAL": pk.add(nn, 5126, "VEC3", 34962),
                     "TEXCOORD_0": pk.add(nuv, 5126, "VEC2", 34962)}
            if "JOINTS_0" in at:
                nid = nearest(pos, npos)
                jn = read_accessor(j, blob, at["JOINTS_0"])
                wt = read_accessor(j, blob, at["WEIGHTS_0"])
                attrs["JOINTS_0"] = pk.add(jn[nid], j["accessors"][at["JOINTS_0"]]["componentType"], "VEC4", 34962)
                attrs["WEIGHTS_0"] = pk.add(wt[nid], j["accessors"][at["WEIGHTS_0"]]["componentType"], "VEC4", 34962)
                if j["accessors"][at["WEIGHTS_0"]].get("normalized"):
                    pk.accessors[attrs["WEIGHTS_0"]]["normalized"] = True
            ip = pk.add(nf.reshape(-1, 1), 5125, "SCALAR", 34963)
            np_ = {"attributes": attrs, "indices": ip}
            if "material" in p:
                np_["material"] = p["material"]
            if "mode" in p:
                np_["mode"] = p["mode"]
            prims.append(np_)
        nm = dict(m)
        nm["primitives"] = prims
        new_meshes.append(nm)
    # keep the other accessors (inverse bind matrices, animations) as they were
    remap = {}
    def keep(idx):
        if idx is None:
            return None
        if idx not in remap:
            a = j["accessors"][idx]
            arr = read_accessor(j, blob, idx)
            new = pk.add(arr, a["componentType"], a["type"])
            for k in ("min", "max", "normalized"):
                if k in a:
                    pk.accessors[new][k] = a[k]
            remap[idx] = new
        return remap[idx]
    for s in j.get("skins", []):
        if "inverseBindMatrices" in s:
            s["inverseBindMatrices"] = keep(s["inverseBindMatrices"])
    for an in j.get("animations", []):
        for sm in an["samplers"]:
            sm["input"] = keep(sm["input"])
            sm["output"] = keep(sm["output"])
    j["meshes"] = new_meshes
    j["accessors"] = pk.accessors
    j["bufferViews"] = pk.views
    j["buffers"] = [{"uri": os.path.basename(path).replace(".gltf", ".bin"), "byteLength": len(pk.data)}]
    return j, bytes(pk.data), before, after


def decimate_head(pos, uv, faces, target, head_target, y_cut):
    """The head and the body get their own budgets, so the face keeps detail."""
    cen = pos[faces].mean(axis=1)[:, 1]
    is_head = cen > y_cut
    parts = []
    for mask, tgt in ((is_head, head_target), (~is_head, target - head_target)):
        f = faces[mask]
        used = np.unique(f)
        remap = -np.ones(len(pos), np.int64)
        remap[used] = np.arange(len(used))
        parts.append(decimate(pos[used], uv[used], remap[f], tgt))
    # weld the two halves back into one mesh
    p = np.concatenate([parts[0][0], parts[1][0]])
    u = np.concatenate([parts[0][1], parts[1][1]])
    f = np.concatenate([parts[0][2], parts[1][2] + len(parts[0][0])])
    return p, u, f.astype(np.uint32)


def main():
    files = sorted(glob.glob(os.path.join(SRC, "**", "*.gltf"), recursive=True))
    total_b = total_a = 0
    print("%-34s %8s %8s" % ("model", "before", "after"))
    for f in files:
        j, blob, b, a = process(f)
        rel = os.path.relpath(f, SRC)
        out = os.path.join(DST, rel)
        json.dump(j, open(out, "w"))
        open(out.replace(".gltf", ".bin"), "wb").write(blob)
        print("%-34s %8d %8d" % (rel, b, a))
        total_b += b
        total_a += a
    print("%-34s %8d %8d" % ("total", total_b, total_a))


if __name__ == "__main__":
    main()
