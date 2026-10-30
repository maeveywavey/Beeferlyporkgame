#!/usr/bin/env python3
"""Paint the world map in the style of a hand-drawn fantasy map.

From the baked world (assets/world/height.bin and info.bin, made by
make_world.py) this draws, at two pixels per map unit:
  * a slate sea with paper grain, a pale shallow halo hugging every coast and
    thin rings echoing the coastline out to sea;
  * land coloured by its country: dark forest, olive grassland, tan desert,
    white ice, ashen volcanic ground, mossy swamp;
  * forests as thousands of stamped tree crowns (some in autumn colours);
  * mountains as drawn peaks with a lit face, a shaded face and snow caps on
    the high ones, placed back to front;
  * dune strokes in the desert, crevasses in the ice, rivers inked in.

Writes assets/world/painted.png. Usage: python3 tools/paint_map.py
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GW, GH = 801, 601
PX = 2                       # pixels per map unit
IW, IH = 1600 * PX, 1200 * PX
RNG = np.random.default_rng(42)
B = {n: i for i, n in enumerate(["ocean", "grass", "forest", "mountain", "snow", "desert", "swamp", "volcanic", "highland", "beach"])}


def up(a, mode=Image.BILINEAR):
    """Grid (801 x 601) to image resolution."""
    return np.asarray(Image.fromarray(a.astype(np.float32), "F").resize((IW, IH), mode))


def noise(cells, seed, octaves=3):
    rng = np.random.default_rng(seed)
    out = np.zeros((IH, IW), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        c = int(cells * 2 ** o)
        g = rng.random((int(c * 0.75) + 2, c + 2)).astype(np.float32)
        out += np.asarray(Image.fromarray(g, "F").resize((IW, IH), Image.BICUBIC)) * amp
        tot += amp
        amp *= 0.5
    return out / tot


# The Fire Islands' volcanoes, in map units (x, y, size): Mount Vulcom and the
# ridge of the main island, the cones on the clan islands and the Strait Isles,
# and the lone volcano off the eastern coast.
VOLCANOES = [(285, 510, 16), (372, 532, 12), (412, 588, 13), (318, 566, 9), (578, 594, 10),
             (676, 522, 7), (1553, 478, 9)]


def main():
    h = np.fromfile(os.path.join(ROOT, "assets/world/height.bin"), "<f4").reshape(GH, GW)
    info = np.fromfile(os.path.join(ROOT, "assets/world/info.bin"), np.uint8).reshape(GH, GW, 4)
    biome = info[..., 0]
    coast = (info[..., 1].astype(np.float32) - 128.0) / 4.0       # map units, + inland
    forest = info[..., 2].astype(np.float32) / 255.0
    river = info[..., 3].astype(np.float32) / 255.0
    cst = up(coast)
    hh = up(h)
    land = cst > 0.0
    grain = noise(60, 1) * 0.6 + noise(400, 2, 1) * 0.4

    # --- sea ------------------------------------------------------------------
    img = np.zeros((IH, IW, 3), np.float32)
    sea = np.array([74, 101, 106], np.float32)
    deep = np.array([62, 86, 92], np.float32)
    off = np.maximum(-cst, 0)                                     # distance out to sea
    img[:] = sea * (0.94 + grain[..., None] * 0.1)
    img = img * 0.85 + deep * 0.15 * np.clip(off / 60.0, 0, 1)[..., None] * 1.2
    halo = np.array([150, 182, 186], np.float32)
    k = np.clip(1.0 - off / 7.0, 0, 1) ** 1.6
    img = img * (1 - k[..., None] * 0.75) + halo * (k[..., None] * 0.75)
    for ring, a in ((9.0, 0.28), (14.0, 0.18), (20.0, 0.1)):
        band = np.clip(1.0 - np.abs(off - ring) / 0.7, 0, 1) * (off > 0)
        img = img * (1 - band[..., None] * a) + halo * band[..., None] * a
    # map vignette
    yy, xx = np.mgrid[0:IH, 0:IW].astype(np.float32)
    vig = np.clip((((xx / IW) - 0.5) ** 2 + ((yy / IH) - 0.5) ** 2) * 2.2, 0, 1)
    img *= (1.0 - vig * 0.35)[..., None]

    # --- land -----------------------------------------------------------------
    bi = np.asarray(Image.fromarray(biome).resize((IW, IH), Image.NEAREST))
    pal = {
        B["grass"]: (150, 162, 82), B["forest"]: (62, 66, 26), B["mountain"]: (122, 108, 88), B["snow"]: (228, 232, 234),
        B["desert"]: (210, 180, 116), B["swamp"]: (96, 96, 44), B["volcanic"]: (92, 84, 78), B["highland"]: (124, 128, 74),
        B["beach"]: (150, 162, 82),
    }
    base = np.zeros_like(img)
    for k2, c in pal.items():
        base[bi == k2] = c
    # soften the borders between countries and add the painter's mottling
    base = np.asarray(Image.fromarray(base.astype(np.uint8)).filter(ImageFilter.GaussianBlur(3))).astype(np.float32)
    base *= (0.9 + grain * 0.2)[..., None]
    # relief: light from the north-west
    gx = np.gradient(hh, axis=1)
    gy = np.gradient(hh, axis=0)
    shade = np.clip(1.0 + (-gx - gy) * 0.9, 0.7, 1.25)
    base *= shade[..., None]
    img[land] = base[land]
    # a dark line along every coast
    edge = np.clip(1.0 - np.abs(cst) / 0.6, 0, 1)
    img = img * (1 - edge[..., None] * 0.6) + np.array([40, 46, 40]) * edge[..., None] * 0.6

    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(out)
    fo = up(forest)
    rv = up(river)
    autumn = noise(22, 7, 2)

    # --- desert dunes and ice crevasses ----------------------------------------
    for _ in range(9000):
        x, y = RNG.random() * IW, RNG.random() * IH
        b = bi[int(y), int(x)]
        if b == B["desert"] and RNG.random() < 0.6:
            w = RNG.uniform(5, 11)
            d.arc([x - w, y - w * 0.4, x + w, y + w * 0.4], 200, 340, fill=(232, 205, 150), width=1)
            d.arc([x - w, y - w * 0.4 + 1.5, x + w, y + w * 0.4 + 1.5], 200, 340, fill=(180, 148, 92), width=1)
        elif b == B["snow"] and RNG.random() < 0.25:
            w = RNG.uniform(4, 10)
            d.line([x - w, y, x + w * 0.4, y + w * 0.2], fill=(196, 206, 214), width=1)

    # --- rivers -----------------------------------------------------------------
    ys, xs = np.nonzero(rv > 0.45)
    for x, y in zip(xs[::2], ys[::2]):
        d.ellipse([x - 1.6, y - 1.6, x + 1.6, y + 1.6], fill=(92, 128, 136))

    # --- forests: stamped crowns, back to front ----------------------------------
    crowns = []
    step = 5.0
    for y in np.arange(0, IH, step):
        for x in np.arange(0, IW, step):
            jx, jy = x + RNG.uniform(-2.2, 2.2), y + RNG.uniform(-2.2, 2.2)
            ix, iy = int(min(IW - 1, max(0, jx))), int(min(IH - 1, max(0, jy)))
            if not land[iy, ix] or fo[iy, ix] < 0.45 or cst[iy, ix] < 2.0:
                continue
            if RNG.random() > fo[iy, ix] * 0.95:
                continue
            crowns.append((jy, jx))
    crowns.sort()
    for y, x in crowns:
        r = RNG.uniform(2.6, 3.8)
        warm = autumn[int(y), int(x)] > 0.66 and RNG.random() < 0.7 and 300 * PX < y < 1000 * PX
        if warm:
            dark, mid, lit = (88, 42, 16), (148, 80, 30), (192, 128, 56)
        else:
            dark, mid, lit = (28, 36, 12), (52, 64, 22), (92, 108, 40)
        d.ellipse([x - r, y - r + 1.2, x + r, y + r + 1.2], fill=dark)
        d.ellipse([x - r, y - r, x + r, y + r], fill=mid)
        d.ellipse([x - r * 0.75, y - r * 0.85, x + r * 0.1, y - r * 0.05], fill=lit)

    # --- mountains: drawn peaks, back to front -------------------------------------
    peaks = []
    cand = np.argwhere((hh > 8.5) & land)
    order = RNG.permutation(len(cand))
    taken = np.zeros((IH // 12 + 1, IW // 12 + 1), bool)
    for i in order:
        y, x = cand[i]
        if bi[y, x] == B["snow"] and RNG.random() < 0.7:
            continue
        cy, cx = y // 12, x // 12
        if taken[max(0, cy - 1):cy + 2, max(0, cx - 1):cx + 2].any():
            continue
        taken[cy, cx] = True
        peaks.append((y, x, hh[y, x]))
    peaks.sort()
    for y, x, ht in peaks:
        s = np.clip(8 + (ht - 8) * 1.6, 8, 30) * RNG.uniform(0.8, 1.15)
        top = (x + RNG.uniform(-2, 2), y - s * 1.1)
        left, right, foot = (x - s, y + s * 0.15), (x + s, y + s * 0.15), (x + s * 0.15, y + s * 0.15)
        polar = bi[int(y), int(x)] == B["snow"]
        rock_l = (178, 160, 136) if not polar else (236, 238, 240)
        rock_r = (104, 88, 72) if not polar else (170, 182, 192)
        d.polygon([left, top, foot], fill=rock_l)
        d.polygon([foot, top, right], fill=rock_r)
        if ht > 13 or polar:
            cap = 0.38
            cl = (left[0] + (top[0] - left[0]) * (1 - cap), left[1] + (top[1] - left[1]) * (1 - cap))
            cr = (right[0] + (top[0] - right[0]) * (1 - cap), right[1] + (top[1] - right[1]) * (1 - cap))
            cm = (top[0] + (foot[0] - top[0]) * cap * 0.9, top[1] + (foot[1] - top[1]) * cap * 1.1)
            d.polygon([cl, top, cm], fill=(244, 246, 248))
            d.polygon([cm, top, cr], fill=(196, 208, 220))
        d.line([left, top, right], fill=(54, 44, 36), width=2)
        d.line([top, (foot[0] - s * 0.1, foot[1] - s * 0.35)], fill=(70, 58, 48), width=1)

    # --- volcanoes: the Fire Islands' cones, smoking ---------------------------------
    for vx, vy, vs in VOLCANOES:
        x, y, s = vx * PX, vy * PX, vs * PX
        for k in range(7):
            r = s * (0.25 + k * 0.12)
            sx = x + k * s * 0.18 + RNG.uniform(-2, 2)
            sy = y - s * 1.2 - k * s * 0.35
            g = int(70 + k * 10)
            d.ellipse([sx - r, sy - r * 0.8, sx + r, sy + r * 0.8], fill=(g, g, g + 4))
        top_l, top_r = (x - s * 0.22, y - s), (x + s * 0.22, y - s)
        left, right, foot = (x - s * 1.2, y + s * 0.2), (x + s * 1.2, y + s * 0.2), (x + s * 0.2, y + s * 0.2)
        d.polygon([left, top_l, top_r, foot], fill=(96, 84, 78))
        d.polygon([foot, top_r, right], fill=(56, 48, 46))
        d.polygon([top_l, top_r, (x + s * 0.05, y - s * 0.75)], fill=(230, 110, 30))
        d.line([left, top_l, top_r, right], fill=(36, 30, 28), width=2)
        d.line([(x, y - s * 0.8), (x - s * 0.3, y - s * 0.1)], fill=(210, 90, 25), width=2)

    out = out.filter(ImageFilter.UnsharpMask(radius=1, percent=40, threshold=2))
    path = os.path.join(ROOT, "assets/world/painted.png")
    out.save(path, optimize=True)
    print("wrote", path, len(crowns), "crowns,", len(peaks), "peaks")


if __name__ == "__main__":
    main()
