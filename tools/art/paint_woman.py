"""Stage 2: paint the Earth Kingdom commoner woman's texture pages.

python3 tools/art/paint_woman.py <workdir>

Every texel is painted from its baked 3D position, normal and ambient
occlusion (see build_woman.py), so designs are drawn on the body in 3D and
cross UV seams cleanly. Light and shade are painted in, as on PlayStation
characters: a warm key light from the upper front, a cool fill, occlusion in
the folds, cloth creases and seams. Pages are painted at 512 and reduced to
256 (hair 128) with a 64-colour palette, point-sampled in game.

Design: Earth Kingdom commoner (docs/reference/earth_commoners_sheet.jpg):
olive robe crossed left over right with a light collar band, bell sleeves
with dark cuffs, a dark brown sash with a sand knot and tails, a lighter
apron panel, a dark banded hem just below the knee, cream trousers with
ankle wraps, dark cloth shoes; hair drawn back into a bun.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

work = sys.argv[1]
OUT = {"Body": 256, "Outfit": 256, "Hair_Bun": 128, "Hair_Long": 128}
J = json.load(open(os.path.join(work, "joints.json")))


def load(name):
    pos = np.load(os.path.join(work, f"{name}_pos.npy"))
    nrm = np.load(os.path.join(work, f"{name}_nrm.npy"))
    ln = np.linalg.norm(nrm, axis=-1, keepdims=True)
    nrm = nrm / np.maximum(ln, 1e-6)
    ao = np.load(os.path.join(work, f"{name}_ao.npy"))[..., 0]
    pid = np.round(np.load(os.path.join(work, f"{name}_id.npy"))[..., 0] * 10).astype(int)
    if name != "Outfit":
        # the head is enlarged about the jaw's underside (common.HEAD_SCALE);
        # the face is drawn in the source head's coordinates
        piv = np.array([0, -0.01, 1.53], np.float32)
        hd = pos[..., 2] > 1.53
        pos = pos.copy()
        pos[hd] = piv + (pos[hd] - piv) / 1.07
    return pos, nrm, ao, pid


def coverage(name, res):
    polys = json.load(open(os.path.join(work, f"{name}_uv.json")))
    im = Image.new("L", (res, res), 0)
    d = ImageDraw.Draw(im)
    for p in polys:
        d.polygon([(u * res, (1 - v) * res) for u, v in p], fill=255)
    return np.array(im.filter(ImageFilter.MaxFilter(5))) > 0


# --- tools -------------------------------------------------------------------
def col(*c):
    return np.array(c, np.float32)


def hash3(ix, iy, iz):
    h = (ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791)
    h = (h ^ (h >> 13)) * 1274126177
    return ((h ^ (h >> 16)) & 0xFFFF).astype(np.float32) / 65535.0


def vnoise(p, freq):
    q = p * freq
    i = np.floor(q).astype(np.int64)
    f = q - i
    f = f * f * (3 - 2 * f)
    out = 0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (f[..., 0] if dx else 1 - f[..., 0]) * (f[..., 1] if dy else 1 - f[..., 1]) * (f[..., 2] if dz else 1 - f[..., 2])
                out = out + w * hash3(i[..., 0] + dx, i[..., 1] + dy, i[..., 2] + dz)
    return out


def fbm(p, freq, oct=3):
    a, s, t = 1.0, 0.0, 0.0
    for _ in range(oct):
        s += a * vnoise(p, freq)
        t += a
        a *= 0.5
        freq *= 2.0
    return s / t


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def band(x, c, w, soft=0.002):
    """1 inside |x - c| < w, soft edge."""
    return 1 - smooth(w, w + soft, np.abs(x - c))


def mix(a, b, t):
    t = np.asarray(t, np.float32)[..., None]
    return a * (1 - t) + b * t


KEY = np.array([-0.40, -0.62, 0.68], np.float32)
KEY /= np.linalg.norm(KEY)
FILL = np.array([0.6, -0.3, 0.1], np.float32)
FILL /= np.linalg.norm(FILL)


def light(nrm, ao, warm=True):
    """Soft painted light (owner, v4 review: the hard cel bands made the robe
    jagged and cut into the face): a warm key from the upper front, a cool
    fill, a little sky from above, gentle occlusion."""
    d = np.clip((nrm * KEY).sum(-1), 0, 1)
    f = np.clip((nrm * FILL).sum(-1), 0, 1)
    top = np.clip(nrm[..., 2], 0, 1)
    lum = 0.66 + 0.36 * d + 0.10 * f + 0.06 * top
    occ = 0.7 + 0.3 * np.clip(ao, 0, 1)
    lum = lum * occ
    # shadows lean cool, lights lean warm
    tint = mix(col(0.86, 0.90, 1.04), col(1.06, 1.0, 0.92), smooth(0.55, 1.05, lum))
    return lum[..., None] * tint


def finish(name, rgb, res_out, cov):
    rgb = np.clip(rgb, 0, 1)
    im = Image.fromarray((rgb * 255).astype(np.uint8))
    im = im.resize((res_out, res_out), Image.LANCZOS)
    small_cov = np.array(Image.fromarray(cov.astype(np.uint8) * 255).resize((res_out, res_out), Image.NEAREST)) > 0
    q = im.quantize(colors=64, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    arr = np.array(q)
    arr[~small_cov] = (24, 24, 26)
    out = Image.fromarray(arr)
    out.save(os.path.join(work, f"{name}_tex.png"))
    return out


# --- body: skin, face, hands, under-wrappings --------------------------------
def paint_body():
    pos, nrm, ao, _ = load("Body")
    x, y, z = pos[..., 0], pos[..., 1], pos[..., 2]
    ax = np.abs(x)
    skin = col(0.86, 0.65, 0.49)
    c = np.broadcast_to(skin, pos.shape).copy()
    # skin is one clean tone; the face is drawn, not airbrushed
    head = z > 1.47
    front = (nrm[..., 1] < -0.35) & (y < -0.06) & head
    # warmth: cheeks, nose, ears, knuckles
    blush = np.exp(-(((ax - 0.05) / 0.018) ** 2 + ((z - 1.637) / 0.012) ** 2)) * front
    c = mix(c, col(0.90, 0.58, 0.50), 0.22 * blush)
    # eye sockets and the shadow under the brow
    for s in (1, -1):
        ex, ez = 0.034 * s, 1.675
        sock = np.exp(-(((x - ex) / 0.026) ** 2 + ((z - ez - 0.004) / 0.014) ** 2)) * front
        c = mix(c, col(0.74, 0.54, 0.44), 0.25 * sock)
    # nose: shade on the side away from the light, shadow and nostrils below
    nose_side = band(x, -0.012, 0.004, 0.004) * band(z, 1.656, 0.02, 0.006) * front
    c = mix(c, col(0.72, 0.52, 0.41), 0.4 * nose_side)
    under_nose = band(z, 1.632, 0.004, 0.003) * band(x, 0, 0.016, 0.004) * front
    c = mix(c, col(0.66, 0.46, 0.37), 0.5 * under_nose)
    for s in (1, -1):
        nos = np.exp(-(((x - 0.008 * s) / 0.004) ** 2 + ((z - 1.636) / 0.0022) ** 2)) * front
        c = mix(c, col(0.42, 0.26, 0.21), 0.6 * nos)
    # mouth
    mw = 0.018
    lips_u = band(z, 1.6105, 0.0035, 0.0015) * band(x, 0, mw * (1 - 0.25 * smooth(0, mw, ax)), 0.003) * front
    lips_l = band(z, 1.6025, 0.0045, 0.0018) * band(x, 0, mw * 0.85, 0.003) * front
    c = mix(c, col(0.66, 0.37, 0.33), 0.85 * lips_u)
    c = mix(c, col(0.76, 0.47, 0.42), 0.8 * lips_l)
    c = mix(c, col(0.90, 0.66, 0.60), 0.5 * lips_l * band(z, 1.601, 0.0012, 0.0012) * band(x, 0.003, 0.006, 0.003))
    c = mix(c, col(0.32, 0.16, 0.14), 0.95 * band(z, 1.607, 0.0011, 0.0009) * band(x, 0, mw, 0.002) * front)
    # (no chin or jaw shading: it read as stubble; the jaw is in the mesh)
    # eyes
    for s in (1, -1):
        ex, ez = 0.034 * s, 1.676
        dx = (x - ex) * s           # outward positive
        u = dx / 0.0165
        v = (z - ez - 0.0018 * u) / 0.0072
        eye = (u * u + v * v < 1) & front
        c[eye] = col(0.92, 0.89, 0.84)
        iris_r = np.hypot(x - ex + 0.001 * s, (z - ez) * 1.0)
        c[eye & (iris_r < 0.0072)] = col(0.36, 0.22, 0.12)
        c[eye & (iris_r < 0.0045)] = col(0.18, 0.11, 0.07)
        c[eye & (iris_r < 0.0026)] = col(0.04, 0.03, 0.03)
        hl = np.hypot(x - ex + 0.0028 * s - 0.001, z - ez - 0.0028) < 0.0016
        c[eye & hl] = col(0.98, 0.97, 0.95)
        # upper lid: a heavy dark line with a flick at the outer corner
        lid = (np.abs(np.hypot(u, v) - 1.0) < 0.22) & (v > -0.15) & front & (u > -1.15) & (u < 1.25)
        flick = band(z, ez + 0.0045 + 0.004 * smooth(0.9, 1.4, u), 0.0013, 0.001) * (u > 0.8) * (u < 1.45) * front
        c = mix(c, col(0.09, 0.06, 0.05), np.clip(lid.astype(np.float32) + flick, 0, 1))
        lower = (np.abs(np.hypot(u, v) - 1.0) < 0.12) & (v < -0.2) & front
        c = mix(c, col(0.50, 0.33, 0.27), 0.6 * lower)
        crease = band(np.hypot(u, (z - ez - 0.0035) / 0.0085), 1.0, 0.07, 0.05) * (z > ez + 0.004) * front
        c = mix(c, col(0.58, 0.40, 0.33), 0.55 * crease)
        # brow
        t = (dx + 0.017) / 0.04
        bz = 1.6935 + 0.006 * np.sin(np.clip(t, 0, 1) * np.pi * 0.9)
        brow = band(z, bz, 0.0022 * (1.2 - 0.6 * np.clip(t, 0, 1)), 0.0012) * (t > 0) * (t < 1.02) * front
        c = mix(c, col(0.15, 0.10, 0.08), 0.95 * brow)
    # jaw contour: the plane of the jaw turning away, shade along the line of
    # the mandible from the chin to below the ear, and a hollow under the
    # cheekbone
    # (the jaw contour is modelled now, not painted: painted jaw shade read
    # as a five o'clock shadow)
    # highlights where the key light catches: brow ridge and forehead, nose
    # bridge and tip, cheekbones, chin, the upper lip's edge
    hi = col(0.99, 0.84, 0.70)
    forehead = band(ax, 0, 0.035, 0.02) * band(z, 1.715, 0.014, 0.01) * front
    bridge = 0.65 * band(x, 0.002, 0.0045, 0.003) * band(z, 1.662, 0.017, 0.006) * front
    tip = np.exp(-((x / 0.006) ** 2 + ((z - 1.642) / 0.005) ** 2)) * front
    cheek = np.exp(-(((ax - 0.047) / 0.012) ** 2 + ((z - 1.647) / 0.007) ** 2)) * front
    chin_hi = np.exp(-((x / 0.01) ** 2 + ((z - 1.589) / 0.006) ** 2)) * front
    hi_amt = np.clip(0.2 * forehead + 0.35 * bridge + 0.3 * tip + 0.15 * cheek + 0.15 * chin_hi, 0, 0.5)

    # hairline painted on the skin, under the hair cap's edge
    hair_col = col(0.13, 0.09, 0.07)
    hl_front = smooth(1.728, 1.738, z + 0.003 * np.sin(x * 260)) * head
    temples = smooth(0.062, 0.07, ax) * smooth(1.66, 1.675, z) * head
    neck_back = smooth(0.0, 0.03, y) * smooth(1.6, 1.62, z) * head
    c = mix(c, hair_col, np.clip(hl_front + temples + neck_back, 0, 1))
    # no painted shadow under the jaw: the cel light shades the neck
    # hands: knuckle warmth and finger separations along the hand
    hand = (ax > 0.645) & (z > 0.95) & (z < 1.16)
    along = ax - 0.65
    fing = np.abs(np.sin(((y + 0.01) / 0.017) * np.pi)) < 0.18
    c = mix(c, col(0.58, 0.40, 0.31), 0.6 * (fing & hand & (along > 0.07)))
    c = mix(c, col(0.86, 0.55, 0.45), 0.25 * band(along, 0.07, 0.008, 0.006) * hand)
    # underclothes on the torso, for outfits that show it
    torso = (z > 0.84) & (z < 1.47) & (ax < 0.24)
    wrap_top = torso & (z > 1.18) & (z < 1.33)
    wrap_low = torso & (z > 0.83) & (z < 0.99)
    under = col(0.84, 0.80, 0.68)
    c[wrap_top | wrap_low] = under
    c *= light(nrm, ao)
    # highlights go on after the light, warm, so they read as light on skin
    c = mix(c, hi * 1.02, hi_amt)
    return c


# --- outfit -------------------------------------------------------------------
G_MID = col(0.42, 0.52, 0.25)
G_LIGHT = col(0.64, 0.68, 0.37)
G_DARK = col(0.22, 0.30, 0.14)
SAND = col(0.80, 0.68, 0.42)
CREAM = col(0.86, 0.82, 0.67)
BROWN = col(0.30, 0.20, 0.14)
SHOE = col(0.22, 0.17, 0.13)


def paint_outfit():
    pos, nrm, ao, pid = load("Outfit")
    x, y, z = pos[..., 0], pos[..., 1], pos[..., 2]
    ax = np.abs(x)
    c = np.zeros(pos.shape, np.float32)
    # cloth: clean colour blocks (Fear Effect) with a faint weave, no mottle
    cloth = 0.985 + 0.03 * fbm(pos, 55, 2)
    weave = 0.985 + 0.03 * (np.sin(x * 900) * np.sin(z * 900) > 0)
    front = y < 0

    torso = pid == 1
    c[torso] = G_MID
    # wrap: the left panel crosses to the right side; its edge runs from the
    # left of the neck down to under the right arm
    p0, p1 = np.array([0.03, 1.455]), np.array([-0.15, 1.10])
    dvec = (p1 - p0) / np.linalg.norm(p1 - p0)
    nvec = np.array([-dvec[1], dvec[0]])
    sd = (x - p0[0]) * nvec[0] + (z - p0[1]) * nvec[1]   # signed distance across the edge
    along = (x - p0[0]) * dvec[0] + (z - p0[1]) * dvec[1]
    in_front = torso & front & (along > -0.02) & (along < 0.40)
    collar = in_front & (sd > -0.024) & (sd < 0.0)
    c[collar] = G_LIGHT
    c = mix(c, G_DARK, (in_front & (np.abs(sd + 0.024) < 0.0035)).astype(np.float32))
    c = mix(c, G_DARK, (in_front & (np.abs(sd) < 0.003)).astype(np.float32))
    # the under-robe shows in the V at the neck, cream
    vee = torso & front & (sd > 0.0) & (z > 1.36) & (x > -0.07) & (x < 0.06)
    c[vee] = CREAM
    # collar band continues round the back of the neck
    back_collar = torso & (y > -0.02) & (z > 1.405)
    c[back_collar] = G_LIGHT
    c = mix(c, G_DARK, (back_collar & (np.abs(z - 1.405) < 0.004)).astype(np.float32))
    # sash
    sash = torso & (z > 0.995) & (z < 1.115)
    c[sash] = BROWN
    c = mix(c, col(0.46, 0.32, 0.22), (sash & ((np.abs(z - 1.0) < 0.006) | (np.abs(z - 1.11) < 0.006))).astype(np.float32))
    knot = sash & front & (ax < 0.032)
    c[knot] = SAND
    c = mix(c, col(0.55, 0.44, 0.26), (knot & (np.abs(x) > 0.024)).astype(np.float32))
    # creases from the bust to the sash, and under the arms
    crease = torso & (z > 1.12) & (z < 1.26) & front
    # a few drawn fold lines from under the bust toward the sash knot
    cr = np.zeros_like(x)
    for x0, k in ((0.05, -0.55), (0.10, -0.35), (-0.06, 0.5), (-0.11, 0.3)):
        cr = np.maximum(cr, band(x - (x0 + k * (1.24 - z)), 0.0, 0.0022, 0.0015) * band(z, 1.18, 0.05, 0.01))
    c = mix(c, G_DARK, 0.55 * cr * crease)

    # sleeves: upper arm in the robe green with a dark band at the elbow;
    # the bell sleeve below in light olive with a dark cuff
    upper = pid == 2
    c[upper] = G_MID
    def arm_t(seg_a, seg_b):
        sgn = np.sign(x)
        ax_ = np.stack([seg_a[0] * sgn, np.full_like(x, seg_a[1]), np.full_like(x, seg_a[2])], -1)
        bx_ = np.stack([seg_b[0] * sgn, np.full_like(x, seg_b[1]), np.full_like(x, seg_b[2])], -1)
        ab = bx_ - ax_
        return ((pos - ax_) * ab).sum(-1) / (ab * ab).sum(-1)
    tu = arm_t(J["shoulder"], J["elbow"])
    c[upper & (tu > 0.86)] = G_DARK
    c = mix(c, G_LIGHT, (upper & (np.abs(tu - 0.85) < 0.02)).astype(np.float32))
    lower = pid == 3
    tl = arm_t(J["elbow"], J["wrist"])
    c[lower] = G_LIGHT
    c[lower & (tl > 0.80)] = G_DARK
    c = mix(c, CREAM, (lower & (tl > 0.96)).astype(np.float32))
    c = mix(c, G_DARK, (lower & (tl < 0.06)).astype(np.float32))
    folds_s = 0.5 + 0.5 * np.sin(np.arctan2(nrm[..., 1], nrm[..., 2]) * 5 + tl * 6)
    c[lower] *= (0.86 + 0.16 * folds_s[lower])[..., None]
    elbow = upper & (tu > 0.6) & (tu < 0.86)
    c[elbow] *= (0.9 + 0.1 * np.abs(np.sin(tu[elbow] * 60)))[..., None]

    # trousers, ankle wraps, shoes
    legs = (pid == 4) | (pid == 5)
    c[legs] = CREAM
    wr = (pid == 5) & (z < 0.19)
    c[wr] = mix(np.broadcast_to(col(0.48, 0.52, 0.32), c[wr].shape), np.broadcast_to(col(0.38, 0.42, 0.25), c[wr].shape),
                (np.sin((z[wr] * 220) + x[wr] * 40) > 0).astype(np.float32))
    c = mix(c, col(0.66, 0.62, 0.50), ((pid == 5) & (z > 0.19) & (np.sin(z * 120 + np.sign(x) * y * 40) > 0.85)).astype(np.float32))
    foot = pid == 6
    c[foot] = SHOE
    c = mix(c, col(0.10, 0.08, 0.07), (foot & (z < 0.03)).astype(np.float32))
    c = mix(c, col(0.36, 0.28, 0.21), (foot & (nrm[..., 2] > 0.6) & (z > 0.03)).astype(np.float32) * 0.6)

    # skirt: robe green, apron panel, sash tails, banded hem, pleated folds
    sk = pid == 7
    c[sk] = G_MID
    ang = np.arctan2(x, -y)
    apron = sk & front & (ax < 0.105) & (z > 0.50)
    c[apron] = G_LIGHT
    c = mix(c, G_DARK, (apron & ((ax > 0.093) | (z < 0.515))).astype(np.float32))
    c = mix(c, SAND, (apron & band(ax, 0.082, 0.003, 0.001).astype(bool) & (z > 0.53)).astype(np.float32))
    top = sk & (z > 0.965)
    c[top] = BROWN
    tails = sk & front & (z > 0.70) & ((np.abs(x - 0.022) < 0.011) | (np.abs(x + 0.012) < 0.009))
    tail_len = np.where(x > 0, 0.70, 0.76)
    tails &= z > tail_len
    c[tails] = SAND
    c = mix(c, col(0.55, 0.44, 0.26), (tails & ((np.abs(np.abs(x - 0.005) - 0.025) < 0.002))).astype(np.float32))
    hem = sk & (z < 0.485)
    c[hem] = G_DARK
    c = mix(c, G_LIGHT, (sk & (np.abs(z - 0.49) < 0.004)).astype(np.float32))
    c = mix(c, G_LIGHT, (sk & (np.abs(z - 0.452) < 0.0025)).astype(np.float32))
    # pleats: clean drawn shadow bands that widen toward the hem
    pleat = np.cos(ang * 11)
    depth = smooth(0.95, 0.55, z)
    shade = (pleat < -0.55 + 0.35 * depth) & sk
    c[shade] *= 0.82

    c *= (cloth * weave)[..., None]
    c *= light(nrm, ao)
    return c


def paint_hair(name):
    pos, nrm, ao, _ = load(name)
    x, y, z = pos[..., 0], pos[..., 1], pos[..., 2]
    base = col(0.13, 0.09, 0.07)
    c = np.broadcast_to(base, pos.shape).copy()
    # strands: dark grooves and lighter locks that run down the head, keyed to
    # the angle round it, so they flow from the crown and hang straight below
    ang = np.arctan2(x, y + 0.01)
    # Fear Effect hair: a dark mass, shaded by the cel light only (owner:
    # no light streaks)
    lock = fbm(np.stack([ang * 9, z * 0.4, ang * 9], -1), 3, 3)
    fine = 0.5 + 0.5 * np.sin(ang * 70 + fbm(pos, 25) * 6)
    c *= (0.85 + 0.25 * (lock > 0.55))[..., None]
    # the middle part: a thin dark groove from the front hairline back over
    # the crown, with a sliver of scalp tone at its front
    part = band(x, 0, 0.0025, 0.0015) * smooth(1.70, 1.74, z) * (y < 0.04)
    c = mix(c, col(0.05, 0.035, 0.03), 0.9 * part)
    # tips of the curtain and bangs break into darker points
    if name == "Hair_Long":
        c *= (1 - 0.35 * smooth(1.50, 1.46, z) * (fine < 0.5))[..., None]
    else:
        bun = (z > 1.79) & (y > -0.04)
        sp = np.sin(np.arctan2(x, y - 0.03) * 3 + np.hypot(x, z - 1.835) * 140)
        c[bun] *= (0.75 + 0.35 * (sp[bun] > 0))[..., None]
        # the tie is the upright band round the base of the bun
        tie = band(z, 1.822, 0.012, 0.002) * (np.abs(nrm[..., 2]) < 0.5) * (np.hypot(x, y - 0.008) < 0.056)
        c = mix(c, SAND * 0.85, tie)
    c *= light(nrm, ao)
    return c


for name, painter in (("Body", paint_body), ("Outfit", paint_outfit),
                      ("Hair_Bun", lambda: paint_hair("Hair_Bun")), ("Hair_Long", lambda: paint_hair("Hair_Long"))):
    rgb = painter()
    cov = coverage(name, rgb.shape[0])
    finish(name, rgb, OUT[name], cov)
    print("painted", name)
