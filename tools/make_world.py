#!/usr/bin/env python3
"""Generate the world map's terrain: land, height, biome, forest and rivers.

The geography is the series' world as traced from a reference map by
tools/trace_reference.py (assets/world/geography.png): its coasts, lakes,
rivers, deserts, forests, ice and mountains. This script adds the few islands
the tracing loses and the canon needs, joins Hamakaze to the mainland, gives
every settlement in scripts/autoload/game_data.gd dry level ground, and builds
heights from the traced mountains.

Writes, at 2 map units per sample (801 x 601):
  assets/world/height.bin  float32 heights (sea floor negative)
  assets/world/info.bin    RGBA8: biome id, coast distance (128 = coast,
                           +4 per unit inland), forest density, river

Usage: python3 tools/make_world.py [preview.png]
"""
import math
import os
import re
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAP_W, MAP_H = 1600, 1200
STEP = 2.0
W, H = int(MAP_W / STEP) + 1, int(MAP_H / STEP) + 1
BIOMES = ["ocean", "grass", "forest", "mountain", "snow", "desert", "swamp", "volcanic", "highland", "beach"]

ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)
X = xs * STEP
Y = ys * STEP


# --- noise ------------------------------------------------------------------
def value_noise(cells, seed):
    """Smooth noise in [-1, 1] with about `cells` features across the map width."""
    rng = np.random.default_rng(seed)
    gw = max(2, int(cells))
    gh = max(2, int(cells * MAP_H / MAP_W))
    g = rng.random((gh + 3, gw + 3)).astype(np.float32)
    img = Image.fromarray(g, "F").resize((int((gw + 3) * W / gw), int((gh + 3) * H / gh)), Image.BICUBIC)
    a = np.asarray(img)[:H, :W]
    return (a - 0.5) * 2.0


def fbm(cells, octaves, seed, gain=0.5):
    out = np.zeros((H, W), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        out += value_noise(cells * (2 ** o), seed + o * 101) * amp
        tot += amp
        amp *= gain
    return out / tot


def blur(a, r):
    """Approximate gaussian blur: three separable box blurs of radius r samples."""
    out = a.astype(np.float32)
    for _ in range(3):
        for axis in (0, 1):
            p = np.pad(out, [((r + 1, r) if ax == axis else (0, 0)) for ax in (0, 1)], mode="edge")
            c = np.cumsum(p, axis=axis)
            if axis == 0:
                out = (c[2 * r + 1:] - c[:-2 * r - 1]) / (2 * r + 1)
            else:
                out = (c[:, 2 * r + 1:] - c[:, :-2 * r - 1]) / (2 * r + 1)
    return out


# --- shapes (signed distance in map units, positive inside) -----------------
def sd_polygon(px, py, pts):
    pts = np.asarray(pts, np.float32)
    d = np.full(px.shape, 1e9, np.float32)
    inside = np.zeros(px.shape, bool)
    n = len(pts)
    for i in range(n):
        ax, ay = pts[i]
        bx, by = pts[(i + 1) % n]
        ex, ey = bx - ax, by - ay
        wx, wy = px - ax, py - ay
        t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
        dx, dy = wx - ex * t, wy - ey * t
        d = np.minimum(d, np.sqrt(dx * dx + dy * dy))
        cond = ((ay <= py) & (py < by)) | ((by <= py) & (py < ay))
        xint = ax + (py - ay) * ex / np.where(ey == 0, 1e-6, ey)
        inside ^= cond & (px < xint)
    return np.where(inside, d, -d)


def sd_ellipse(px, py, cx, cy, rx, ry, ang=0.0):
    a = math.radians(ang)
    dx, dy = px - cx, py - cy
    u = dx * math.cos(a) + dy * math.sin(a)
    v = -dx * math.sin(a) + dy * math.cos(a)
    r = np.sqrt((u / rx) ** 2 + (v / ry) ** 2)
    return (1.0 - r) * min(rx, ry)


def sd_capsule(px, py, a, b, r):
    ax, ay = a
    bx, by = b
    ex, ey = bx - ax, by - ay
    wx, wy = px - ax, py - ay
    t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
    return r - np.sqrt((wx - ex * t) ** 2 + (wy - ey * t) ** 2)


def dist_polyline(px, py, pts):
    d = np.full(px.shape, 1e9, np.float32)
    for i in range(len(pts) - 1):
        d = np.minimum(d, -sd_capsule(px, py, pts[i], pts[i + 1], 0.0))
    return d


# --- the world ---------------------------------------------------------------
# The geography is traced from a reference map of the series' world by
# tools/trace_reference.py into assets/world/geography.png. This script adds
# what the reference does not show or the canon needs, then builds heights,
# biomes, forests and rivers from it.

# islands the tracing loses (too small on the reference) or the game needs:
# cx, cy, rx, ry in map units
ISLETS = [
    (322, 442, 26, 19),     # the Island of the Sun Warriors
    (376, 466, 11, 9),      # the Boiling Rock
    (902, 832, 9, 7),       # Oyster Isle, off Hamakaze
]
# Hamakaze is still joined to the mainland in this era (docs/canon.md §9)
NECKS = [((928, 802), (950, 764), 7)]
# hand-placed ranges are not needed: mountains come from the reference


def settlements():
    src = open(os.path.join(ROOT, "scripts", "autoload", "game_data.gd")).read()
    start = src.index("var settlements := {")
    out = {}
    for m in re.finditer(r'\n\t"([a-z_]+)": \{"name": "[^"]*", "type": "[a-z]+", "faction": "[a-z_]+", "pos": Vector2\(([\d.]+), ([\d.]+)\)', src[start:]):
        out[m.group(1)] = (float(m.group(2)), float(m.group(3)))
    return out


def depth_of(mask, steps):
    """Distance into a mask in samples (alternating 4- and 8-neighbour erosion)."""
    d = np.zeros(mask.shape, np.float32)
    cur = mask.copy()
    for k in range(steps):
        d += cur
        nxt = cur.copy()
        nxt[1:] &= cur[:-1]
        nxt[:-1] &= cur[1:]
        nxt[:, 1:] &= cur[:, :-1]
        nxt[:, :-1] &= cur[:, 1:]
        if k % 2 == 1:
            nxt[1:, 1:] &= cur[:-1, :-1]
            nxt[:-1, :-1] &= cur[1:, 1:]
            nxt[1:, :-1] &= cur[:-1, 1:]
            nxt[:-1, 1:] &= cur[1:, :-1]
        cur = nxt
        if not cur.any():
            break
    return d


def main():
    geo = np.asarray(Image.open(os.path.join(ROOT, "assets", "world", "geography.png"))).astype(np.int32)
    land = geo[..., 0] > 0
    biome = geo[..., 1].astype(np.uint8).copy()
    mtn = geo[..., 2].astype(np.float32) / 255.0
    river = (geo[..., 3] > 0).astype(np.float32)
    for cx, cy, rx, ry in ISLETS:
        isl = ((X - cx) / rx) ** 2 + ((Y - cy) / ry) ** 2 < 1.0 + fbm(80, 2, 5) * 0.3
        biome[isl & ~land] = BIOMES.index("forest")
        land |= isl
    for a, b, r in NECKS:
        neck = sd_capsule(X, Y, a, b, r) > 0
        biome[neck & ~land] = BIOMES.index("forest")
        land |= neck
    sites = settlements()
    for (sx, sy) in sites.values():
        disc = (X - sx) ** 2 + (Y - sy) ** 2 < 36.0
        biome[disc & ~land] = BIOMES.index("grass")
        land |= disc
    # signed distance to the coast in map units, softened a little
    sd = (depth_of(land, 40) - depth_of(~land, 40)) * STEP
    sd = np.where(land, np.maximum(sd - STEP * 0.5, 0.3), np.minimum(sd + STEP * 0.5, -0.3))
    sd = blur(sd, 1)
    sd = np.where(land, np.maximum(sd, 0.2), np.minimum(sd, -0.2))

    # heights: a gentle rise inland, rolling hills, and the reference's mountains
    sd_soft = blur(np.where(land, sd, np.minimum(sd, 0)), 6)
    sea = -0.5 - np.clip(-np.minimum(sd_soft, sd), 0, 70) / 70.0 * 6.0
    h = np.where(land, 0.6 + np.clip(sd, 0, 40) / 40.0 * 2.0, sea)
    hills = fbm(24, 4, 51) * 0.5 + 0.5
    h += np.where(land, hills * 1.6 * np.clip(sd / 10.0, 0, 1), 0)
    ridged = 1.0 - np.abs(fbm(36, 4, 61))
    m = np.clip(blur(mtn, 3) * 2.2, 0, 1)
    h += np.where(land, m * (9.0 + 12.0 * ridged ** 2) * np.clip(sd / 6.0, 0, 1), 0)
    # Caldera: a ring crater around the capital
    if "caldera" in sites:
        cx, cy = sites["caldera"]
        d = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
        h += np.where(land, 7.0 * np.exp(-((d - 18) / 6.0) ** 2), 0)
    h = np.where(land, np.maximum(0.3, h - river * 1.0), h)
    for (sx, sy) in sites.values():
        d = np.sqrt((X - sx) ** 2 + (Y - sy) ** 2)
        k = np.clip(1.0 - (d - 5.0) / 12.0, 0, 1) ** 2
        ring = land & (d > 14) & (d < 26)
        base = float(np.median(h[ring])) if ring.any() else 0.8
        base = max(0.6, min(base, 7.0))
        h = np.where(land, h * (1 - k) + base * k, h)

    # biomes: as traced, with mountains where the land is high, beaches at the edge
    biome[land & (h > 9.0) & ~np.isin(biome, [BIOMES.index("snow"), BIOMES.index("desert")])] = BIOMES.index("mountain")
    biome[land & (biome == BIOMES.index("ocean"))] = BIOMES.index("grass")
    polar = (Y < 175) | (Y > 930)
    biome[land & (sd < 1.4) & ~polar & ~np.isin(biome, [BIOMES.index("swamp"), BIOMES.index("snow")])] = BIOMES.index("beach")
    biome[~land] = BIOMES.index("ocean")
    forest = blur((biome == BIOMES.index("forest")).astype(np.float32), 2)
    forest = np.clip(forest * 1.2, 0, 1)
    forest[~land] = 0

    coast = np.clip(128 + sd * 4.0, 0, 255).astype(np.uint8)
    info = np.stack([biome, coast, (forest * 255).astype(np.uint8), (np.clip(river, 0, 1) * 255).astype(np.uint8)], axis=-1)
    out = os.path.join(ROOT, "assets", "world")
    h.astype("<f4").tofile(os.path.join(out, "height.bin"))
    info.astype(np.uint8).tofile(os.path.join(out, "info.bin"))
    print("land %.1f%%, height %.1f..%.1f" % (land.mean() * 100, h.min(), h.max()))
    if len(sys.argv) > 1:
        col = np.array([[40, 80, 130], [110, 150, 80], [60, 110, 60], [130, 120, 105], [235, 240, 245],
                        [220, 195, 135], [80, 100, 70], [100, 80, 70], [130, 140, 100], [215, 205, 160]], np.uint8)
        img = col[biome].astype(np.float32)
        shade = np.clip(1.0 + np.gradient(h, axis=1) * 0.25 - np.gradient(h, axis=0) * 0.25, 0.6, 1.3)
        img = img * shade[..., None]
        img[river > 0.3] = [60, 110, 170]
        for (sx, sy) in sites.values():
            img[int(sy / STEP) - 1:int(sy / STEP) + 2, int(sx / STEP) - 1:int(sx / STEP) + 2] = [220, 30, 30]
        Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save(sys.argv[1])


if __name__ == "__main__":
    main()
