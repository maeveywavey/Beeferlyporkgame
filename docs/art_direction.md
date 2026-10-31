# Art direction

The owner's standing instructions for how the game looks, and how art is
made and reviewed. Every art task reads this first. New feedback from the
owner is added under **Owner's rulings**, with the date; a later ruling
overrides an earlier one.

## Visual target

- **PlayStation 1 at its best**, not PS1 as an excuse. The references are
  *Metal Gear Solid* (1998) and the original *God of War* (2005, PS2, for
  its painted-texture craft). Detail lives in **hand-painted textures**, not
  in geometry: folds, seams, trim, wear, skin tone and baked light and shade
  are painted into a small texture page.
- **Avatar: The Last Airbender** supplies the design language: layered
  robes with cross-collars, sashes, aprons and banded hems; colour blocks in
  a few related tones per nation (Earth: olive, moss, jade, sand, umber,
  cream); clean silhouettes. The original series only.
- Reference sheets the owner has given are kept in `docs/reference/`.

## How art is made

- **Use real art tools.** Models are built, rigged, UV-mapped and baked in
  Blender (headless, scripted under `tools/art/`), starting from the
  owner's base mesh in `assets/source/`. Code places and animates art; it
  does not stand in for modelling or painting.
- **Characters are one continuous skinned mesh** (as in MGS): no separate
  primitives stuck together, no floating parts. Joints (neck to torso, upper
  arm to shoulder, hips to thighs) are welded geometry with weights that bend
  cleanly; nothing intersects at rest or in motion.
- **Markings are painted, not modelled**: tattoos (the Air Nomad arrow),
  face paint, embroidery and emblems are texture.
- **Budgets:** about 400-800 triangles for a whole clothed character; one
  256 x 256 texture page for the body and one per outfit (128 x 128 for small
  parts). Point-sampled textures; affine warping and vertex snapping are part
  of the look.
- **Body shapes come from one base mesh** through blend shapes (sliders):
  height, weight (thin to thick), muscle (soft to brawny), curves (flat to
  curvy), and age (child, teen, adult, elder), freely mixed.
- **Clothing changes without bulk.** An outfit replaces the body regions it
  covers with its own skin-tight or draped geometry (the covered body parts
  are not drawn), so there is no layer floating on top of a body and nothing
  can poke through. Only thick armour is allowed to add volume.
- **Skirts and robes move with the legs.** Lower garments are weighted to
  the legs (each side to its own thigh and shin, the middle shared) so they
  stretch and swing with the stride without clipping.
- **Effects sit in the world.** Fire, smoke and dust are anchored into what
  they come from (the bottom of a flame sprite is buried in the ground or the
  burning body), never floating with a visible base.

## How art is reviewed

- **Compare against the reference**, side by side, at the same camera. The
  question is "does it look like the reference at its best", not "is the
  defect gone".
- **Close-up turnarounds**: front, side, back and three-quarter, plus the
  joints in a bent pose (stride, raised arm, crouch), before anything is
  accepted.
- **One example first.** One character, one fire, one terrain patch is
  brought to the target and signed off by the owner before the method is
  applied to the rest.
- **Art tasks get the strongest model and high effort.** Mechanical work can
  go to a smaller model.

## Owner's rulings

- 2026-10-31: The previous pass looked like a cheap "AI vibe-coded" mess:
  floating tattoo geometry, characters assembled from primitives with
  flat-blocked colour, necks not attached to torsos, upper arms
  intersecting shoulders, fire sprites with visible bottoms. All of the
  rules above follow from this.
- 2026-10-31: Visual targets are Metal Gear Solid and the original God of
  War. Body shapes: thick, thin, child, teen, adult, elder, short, tall,
  flat, brawny, curvy and their mixes, via sliders or equivalent. Clothing is
  swappable and not a bulky extra layer. First deliverable: an Earth Kingdom
  adult woman in common garb (robe hem just below the knee, moving with the
  legs without clipping), showing the base model, her texture map and her
  clothing.
- 2026-10-31 (review of earth_woman_v1): Overall "pretty good". Changes:
  - **Shoulders:** arms sit too low in the socket, so shoulders look padded
    (the child reads as a tiny football player). Raise the arms in the
    socket; shoulders slope naturally.
  - **Face:** add jaw contour and highlights.
  - **Hair:** thicker; it must not read as a buzzcut. Judge two styles: a
    high bun, and shoulder-length hair worn down with bangs that keep the
    face clear.
  - **Hair physics:** simple. A few planes that hang and move limply, like a
    sheet of fabric (a short chain of bones per strip, damped, with gravity;
    never a full simulation).
  - **Body mass:** everyone except the thin shapes gets about 1.2x girth
    overall, with more on the inner thigh. No large thigh gaps.
  - **Slider range:** Heavy, Feminine and Curvy can reach up to 2x their
    current maximum in hips, waist, buttocks, abdomen, breasts and legs:
    genuinely curvaceous women and genuinely overweight people.
  - **Asset packs** the owner likes, to use (licences checked, anything
    out of setting dropped, such as cars, chain-link fences and modern red
    brick, with natural textures substituted):
    elegantcrow PSX retro tree pack; foxh3ad foxtexcom; elbolilloduro PSX
    low-poly model pack 2, vegetation and mine (re-texture the mine's rocks
    and beams with several varied textures, not one bland one); elegantcrow
    retro PSX nature pack; valsekamerplant PSX walls and fences;
    screamingbrainstudios Tiny Texture Pack 3 and Noise Texture Pack (the
    noise for blending textures and varying colour and contrast on ground,
    rock, buildings and everything else, so surfaces look natural and lived
    in, not clean drafts).
- 2026-10-31 (earth_woman_v2, built): arms swung up 8 degrees about the
  shoulder and the shoulder line sloped (no pads, child included); 1.2x girth
  with fuller inner thighs (Thin keeps the old girth); Heavy, Feminine and
  Curvy each have a second half (HeavyMore, FeminineMore, CurvyMore) for
  slider values 1..2, limited to hips, waist, buttocks, belly, breasts and
  legs. Hair: domed cap that tapers to the skin at the hairline; styles
  Hair_Bun (high bun) and Hair_Long (shoulder length, bangs).

### Hair physics (method)
Long hair is one curtain in five strips, each on a chain of three bones
(Hair.<strip>.<0..2>); neighbouring strips share their edge vertices, so the
curtain bends like one sheet and cannot tear. In game each chain is a damped
spring per bone: it is pulled toward its rest angle and by gravity, lags behind
the head's motion, and is clamped (about 35 degrees per bone, less sideways
toward the face) so it never crosses the face. The head, neck and shoulders are
spheres the chain tips are pushed out of, so the hair rests on the shoulders
rather than passing through them. No cloth simulation.
