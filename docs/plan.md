# Plan: the next rework

This plan is drawn from the twenty answers of 30 October and the follow-up answers after them. It is for review before any code changes. Each section states the decision, what changes, and where it pulls against canon. Where it does, the canon rule wins and the section gives the workaround.

## 1. Lore sources and setting

**Decisions**
- **Q1, sources.** The binding sources become the series, the comics and the novels (the *Chronicles of the Avatar*), with *The Legend of Korra* still excluded.
- **Q3, era.** The game is set centuries before Yangchen.
- **Q2, names.** Canon names are kept only for things clearly ancient.

**Effect on `docs/canon.md`.** Tier 2 widens to include the Kyoshi, Yangchen and Roku novels. Two consequences:
- **More constraints.** The novels set Yangchen's childhood after the Platinum Affair and the shang cities (Taku among them). Setting the game *centuries* earlier keeps us clear of both.
- **A citation change.** Kyoshi founding the Dai Li becomes a tier-2 fact cited from both the comic and the novels.

**Names to keep (ancient on screen or in the novels):**
- Ba Sing Se and its walls;
- Omashu, the Cave of Two Lovers, Oma and Shu;
- the four Air Temples;
- the Si Wong Desert and Wan Shi Tong's Library;
- the Foggy Swamp;
- Agna Qel'a and the Spirit Oasis;
- the Sun Warriors and their city;
- the Fire Sages and the Agni Kai.

**Names to replace with originals.** Any canon name not clearly ancient, which means current places such as:
- Gaoling, Full Moon Bay, Chameleon Bay, Misty Palms, Senlin, Makapu, Gaipan;
- Ember Island, Shu Jing, Jang Hui, Fire Fountain City, Caldera City, Crescent Island;
- the Yuyan archers, and the Southern settlement names.

**What the test does.** `tests/test_canon.gd` gains an allow-list: a canon name may appear only if it is on the list.

## 2. War and the four nations

**Decisions.** Q4: full sandbox conquest. Q5: the player may conquer anything, and the Avatar reacts. Q6: the Fire Islands start divided among rival houses. Q12: the series' tone, but war may be grimdark.

**Canon tension.** The series opens with "the four nations lived together in harmony", and Sozin calls expansion a new idea in 3×06. Canon also shows the remedy: Avatars stop conquerors (Roku and Sozin; Kyoshi and Chin).

**Confirmed.** Anyone who wants to conquer may try, anywhere and at any time: the player and every AI kingdom alike. The only answer the world gives is the Avatar's: a nation that takes another nation's land draws the Avatar to it, as the player does now.
- **For AI kingdoms:** the tyrant motive applies, scaled by the foreign land held.
- **Consequence:** in eras with an active Avatar, cross-nation empires are unstable by design; in the child era they can grow until the Avatar comes of age.
- **Code:** `Data.may_besiege` is removed (done). Still to do: a per-faction "foreign holdings" score that the Avatar system reads.

**The Fire Islands, not yet unified (built).**
- **One royal house:** the Royal House of the Fire Lord holds Caldera, the Boiling Lake, Crescent Island and the Strait Isles, with lands and levies roughly equal to all the other clans combined, as in pre-unification feudal Japan.
- **Five clans:** Hiyori, Ren, Kagari, Tsurugi and Kurozan rule their own islands, feud with each other and bow at court. The royal house absorbs clans that lose their wars, so unification is an outcome of play rather than a scripted event.
- **The Fire Lord title:** the royal house holds it. It commands the clans in ceremony only. Canon has a Fire Lord contested by clans (`docs/canon.md` §9).
- **The Sun Warriors:** a protected faction with dragons in their city (walls count for more while they hold it). AI powers attack them only under a ruler with aggression 0.8 or more who is at least as strong, or when three times as strong.

**Grimdark war.**
- Sacked towns, famine after raids, massacres the player can commit or witness, and refugees on the roads.
- War-weariness and atrocity carry lasting consequences (infamy, regional hatred, rebellion) rather than shock value.
- Companions react according to their own morals.

## 3. Eras

**Decisions.** Q9: the story campaign is dropped. Q10: each era has its own world state. Q19: a game can span decades.

**Dropping the campaign.**
- The Drowned Testament, its six pages, the endings and the two culpable men are removed entirely. The last Avatar gets no story: no logbook, no mystery, no rumours about the death.
- Characters who still fit return as sandbox lords and quest-givers.

**Four era sandboxes**, each with its own rulers, borders, wars and opening situation:

| Era | The Avatar | The world |
|---|---|---|
| The Quiet Years | An untold child | No Avatar acts; the cross-nation conquest window |
| The Young Avatar | Siku | The Avatar is looking for teachers |
| The Avatar's Prime | Lei Shan | The Avatar intervenes most |
| The Elder Avatar | Akane | The Avatar is roused rarely |

**Decades of play.**
- **Faster time:** time runs faster between seasons, through a season-skip option in camp, with events summarised.
- **Ageing:** the player ages. Past about 60, attributes decline; an heir (a child, a sworn sibling or an apprentice) can inherit holdings and some skills.
- **The Avatar's life:** the Avatar ages through life stages, dies, and is reborn into the next nation of the cycle. The Quiet Years then come round again within the same game.

## 4. Bending

**Decision, Q13: benders are mortal, and masters are very rare.**
- **Masters** are rarer than 1 in 10,000. They live their own lives and rarely enter anyone's war.
- **Novice and average benders** are common: rarer than non-benders and worth about two soldiers. A rock is as lethal as an arrow, and no more.

**Concrete changes.**
- **Troop rebalance:** bender troop damage, health and cost drop to roughly 1.5–2× a soldier of the same tier.
- **Companion power:** companion bending power is capped below master level, except for companions written as masters.
- **Lords:** lords who are benders are capable, not masters, unless the setting says they are masters.
- **Lightning:** generating lightning is restricted to the two royals who know it (built).

**Masters (Q17: sought out, rarely join, or hired at great cost).**
- **Where they live:** the world holds a handful of named masters per element (about 3–5 each). Each lives somewhere, has a want, and teaches for a price or a deed.
- **Ways to bring one along:**
  - a personal cause that matches the player's war, which makes them join;
  - a contract at very great cost, which they break if the cause turns cruel.
- **In battle:** a master on the field changes the fight.

**The player's path to mastery (Q18).** Mastery is reachable but arduous.
- **Two kinds of progress:** bending skill grows from training (slow and safe) and from real danger (fast).
- **How danger is weighed:** experience from a fight scales with the odds faced and the risk taken: outnumbered, wounded, against stronger benders, or under a master.
- **Two paths:** a cautious player takes years; a reckless one gets there faster, if they live.
- **The last step:** mastery trials stay, as the final step.

**Forms at the core (Q14).** Most bending comes from forms the player builds.
- **Hotkeys:** Q, E and R become form slots alongside F. The expansion techniques are recast as releases and signature movements that unlock new forms rather than fixed buttons.
- **More movements:** the movement library grows from 12–18 per element to about 40, drawn from the named martial arts.
- **New releases:** whip, column, shield, dash, ring and line join the existing ones.
- **Built-in forms:** benders controlled by the game use pre-built forms of their own.
- **Faster building:** the editor gains a list view and move suggestions so building a form stays quick.

**Non-combat bending as economy (Q15).** Bending work leaves lasting marks on settlements.
- **Earth:** terraces raise farm output for seasons; walls raise the defence value.
- **Water:** irrigation offsets drought.
- **Ice roads:** these speed winter travel along a route.
- **Air:** mills raise output in temple towns.
- **Fire:** forges and kilns raise the quality of local goods.
- **Upkeep:** effects wear off without upkeep, and other lords' benders can do the same work, or undo it in war.

## 5. World and look

**Spirits (Q8): minimal.** Spirits stay in lore and dialogue. There are no systemic spirit events. The Avatar's absences remain travel, temples and family.

**Dragons and the Sun Warriors (Q7): a living, visible culture.**
- **On the map:** the Sun Warrior city appears on the map, outward-facing in this era.
- **Dragons:** dragons are seen over the Fire Islands and appear rarely in battle near their territory.
- **The fire trial:** the firebending mastery trial moves to the dragons, in the manner of 3×13.
- **Dragon hunting:** hunting dragons is possible, and grimdark: it carries large infamy, angers the Sun Warriors and draws the Avatar.

**Look: realistic and PS1 (replaces Q16).** A prototype is already in the battle scene: `scripts/battle/landscape.gd`, `shaders/ps1.gdshaderinc`, `shaders/lit.gdshader`, `shaders/sprite.gdshader`, `shaders/backdrop.gdshader`. It gives:
- **Ground:** textured and desaturated, lit realistically instead of cel-shaded.
- **2D stand-ins, as PS1 games did:**
  - mountains are painted images on a ring of cards around the field, in three ranges that grow paler with distance;
  - broadleaf trees keep a modelled, bark-textured trunk and branches, with canopies of painted leaf-clump cards that face the camera;
  - pines, bushes and grass tufts are cards.
- **Natural layout:**
  - cliffs jut from flat land at the flanks, singly or in short ridges, with boulders and scrub at their feet;
  - trees grow in groves with thick edges of undergrowth, plus a few lone trees and tufts in the open;
  - the middle band where armies meet is kept mostly clear.
- **The PS1 layer, on every 3D shader:**
  - vertices snap to a screen grid, so edges wobble as the camera moves;
  - textures are point-sampled at a low texel count;
  - texture mapping can drift towards affine.
  - It is set in Settings → Retro look: Off, Light (grid 480, 128 texels) or **Heavy** (grid 200, 40 texels, 60% affine warp; the default).
  - The comparison is in `docs/screenshots/retro_compare.jpg` and `.gif`.

**Still to do for the look:**
- **The world map, towns and the title screen:** these still use the cel style, and the same treatment comes next.
- **Characters:**
  - outfits are flat-coloured, so they gain little from texture pixelation;
  - they need low-resolution painted textures, and less saturated culture palettes to match the ground.
- **Bending effects:** these need sprite-based fire, water, earth and air in the same idiom.
- **Detail clean-up:**
  - the cel rim light and ink outlines should be removed or reduced to suit the realistic direction;
  - the old CC0 rock and plant models are replaced only in battles so far.

**Companions (Q11):** kept as written. They are revised only where a decision above changes their facts:
- Juro's burned village and Kazan's siege stay in the Isles;
- companion power is capped (§4).

## 6. Order of work

| Phase | Content | Size |
|---|---|---|
| A | Canon file to the new source tiers and era; name allow-list; replace non-ancient names | Medium |
| B | Drop the campaign; four era world states; split the Fire Islands into houses | Large |
| C | Bender rebalance; named masters; mastery through danger | Medium |
| D | Forms at the core: Q, E and R as form slots, about 40 movements per element, techniques as unlocks | Large |
| E | Bending work as a lasting economy | Medium |
| F | Conquest with an Avatar response for AI kingdoms; grimdark war consequences | Medium |
| G | Decades: season skip, ageing, heirs, Avatar death and rebirth in one game | Large |
| H | Sun Warriors and dragons; realistic and PS1 look everywhere (map, towns, characters, effects) | Large |

**Order.** A comes first, because every later phase names things. B and C come next, because they change what the world contains. D through H can follow in any order.

## 7. Decided after review

1. **Conquest:** anyone may attempt it, anywhere and at any time. The Avatar's response is the only check.
2. **The last Avatar:** no story at all. The campaign and every trace of the lost-Avatar mystery go.
3. **Look:** realistic and PS1 as in §5, at the **Heavy** strength, which is now the default. Light and Off remain in Settings.
4. **Camera:** the battle camera sits at a quarter of the distance in the comparison shots (1.5 m, over the shoulder); the mouse wheel still zooms from 1 to 12 m.
6. **Factions (built):** the four Air Temples are separate factions; the Fire Islands are a royal house and five clans, plus the Sun Warriors; the Earth Kingdom keeps its title but rules only its heartland, with tributaries, Omashu, a march, a duchy and a warlord around it; the Water Tribes are split into five; and eighteen independent communities pay tribute or none. Fealty (tribute for connection and protection) is a system: overlords answer attacks on tributaries, tributaries leave weak overlords, powers ask communities for tribute or take them, and taken communities rise. The Factions menu lists every faction, the people the player is connected to, and the wars and tribute.
7. **Water Tribes (built):** a confederation of many small tribes after the Holy Roman Empire, with seven electors choosing a High Chief of the Water Tribes in the Moon Council each year (`scripts/core/moon_council.gd`); a second swamp, the Weeping Fen; island tribes in the warm seas.
8. **Map (built, then replaced):** the world's geography is now the series' own, traced from a reference map of the canon world (`tools/trace_reference.py` → `assets/world/geography.png`; the reference image itself is not in the repository): its continents, Fire Islands, Mo Ce islands, polar islands, southern island chain, inland bay, lakes, rivers, Si Wong Desert, forests and mountains. Every settlement sits on it within our political layout. The default map style is a hand-painted fantasy map after the reference's look (`tools/paint_map.py`: slate sea with shallow halo and coast rings, stamped forest crowns, drawn peaks, volcanoes, dunes, ice), with political borders drawn from who holds each settlement. Painted atlas, old chart and ink wash remain in Settings.
5. **Natural colour variation:** rocks show bedding strata, chunks of differently coloured stone and dark cracks, and each outcrop has its own cast. The ground has large lighter, darker, drier and lusher patches blending into one another, brown leaf litter and soil under trees, and stony soil at cliff feet. Foliage cards vary in shade.
