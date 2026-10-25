# Prototype Review: Development and Art Direction

*The reviewers are simulated. Claude wrote both perspectives to stress-test the prototype from a production standpoint and from an art-direction standpoint. Neither is a real person.*

**Reviewed build:** commit `e206d20` ("Avatar: Mount & Bend" prototype).
**Reviewers:** a senior game developer (systems and production; open-world RPG and sandbox strategy background) and an art director/visionary designer (2D animation and stylised 3D; responsible for making the game look like the hand-painted world of the original series).

---

## 1. Development review

### 1.1 What the prototype gets right
* **The sandbox loop closes.** Travel, encounter, battle, aftermath, recruit and upgrade form a complete loop. The 90-day bot playthroughs show progress from level 1 to level 7–10 for every background. Few prototypes reach a closed loop this early.
* **Content is data-driven.** Factions, troops, items, settlements and lords are dictionaries in one file, so designers can rebalance without touching logic. This should be preserved.
* **The simulation is separate from presentation.** `world_sim.gd` runs headlessly, which made it possible to simulate 300 days in tests. Keep this separation for every new system: settlements, dialogue and companions.
* **The test harness is real.** It parses every script, opens every window and plays automated battles and campaigns. Every later change must keep it green.

### 1.2 Problems, ranked by severity
1. **Canon dependence (blocking).** The game retells the series: Team Avatar, Zuko, Ozai, the Day of Black Sun and Sozin's Comet. The design direction now requires an original story in an ambiguous era before Aang. Every named character, story event and canon reference must be replaced; this cannot be done by renaming alone, because the dramatic structure (the hunt for the Avatar, the comet deadline) is borrowed too.
2. **Characters are assembled from primitive shapes (blocking).** No player will accept box-limbed soldiers in a game about martial arts. Combat readability depends on silhouettes and anticipation poses, which the current rig cannot produce.
3. **Settlements are menus only.** In Mount & Blade, walking through a town is how the player feels the place. Here a town is a list of buttons, and cultures differ only in colour.
4. **Cultures are palette swaps.** Every nation runs on identical mechanics. The Northern Water Tribe's rules about who may learn combat waterbending, the Air Nomads' pacifism, the ring system of Ba Sing Se and the Fire Nation's noble houses are absent, although these are what make the setting itself.
5. **Characters are lines of text.** A lord has one greeting; a companion has a one-line pitch and a skill bonus. No one wants anything, remembers anything or changes.
6. **Combat lacks martial-arts identity.** All benders share one projectile/cone/area template. In the show each art has a distinct philosophy: waterbending redirects, earthbending holds ground then strikes, firebending attacks from the breath, airbending evades and circles. These should be different mechanics, not different colours.
7. **State is stored in untyped dictionaries.** This is acceptable for a prototype but fragile at scale: a typo in a key fails silently. Recommendation: typed accessors around the dictionaries, keeping `var_to_str` serialisation.
8. **AI has no formations or terrain awareness.** Battles become melee blobs. Acceptable for now; it is a sequel-level investment.
9. **Accessibility gaps.** There is no reduced-motion option, text size control, colourblind-safe faction markers, slower message log or option to pause on important events. The intended audience includes many neurodivergent players, so these settings are core features.

### 1.3 Technical decisions
* **Character art pipeline.** Use Quaternius's *Universal Base Characters*, *Modular Character Outfits* and *Universal Animation Library 1 & 2*. All are released under CC0 (public domain) and all are human-made: modelled, rigged and animated by an artist on a UE5-compatible 65-bone skeleton. About 80 motion clips cover locomotion, strikes, sword combos, throws, spellcasting, hits, deaths, idles and work animations. Bending forms are built as layered poses on top of these clips: stance offsets on the pelvis and legs, and arm paths for each art.
* **Facial expressions.** The base heads ship without blend shapes. Generate expression morph targets at load time (brow raise and furrow, eyelid close, mouth corners up and down, jaw open) by displacing face-region vertices, then drive them from dialogue tags. This is cheaper than a facial rig and enough for silent, text-driven dialogue.
* **Rendering.** Use a custom cel shader: two-band diffuse, soft terminator, painted rim light and an inverted-hull ink outline. It runs on the Compatibility renderer, so low-end machines stay supported.
* **Settlements.** Build them as a separate `settlement_scene` with a hand-designed layout template per culture and per settlement type, dressed with CC0 nature and prop kits. Architecture specific to the setting (pagoda roofs with upturned eaves, ice spires, Air Temple towers) is built from authored, parameterised modules rather than random primitives.

---

## 2. Art direction review

### 2.1 Target look
The reference is the original animated series: flat, saturated colour fields, crisp ink lines, soft hand-painted backgrounds and dramatic skies. The goal is a game that looks like a still from the show, not a realistic simulation of the setting. Anatomy and motion must be correct; surfaces must be painterly and simplified.

**Rendering rules**
1. Character shading has two tones plus a rim, never photoreal gradients. Shadows lean cool (blue-violet) on warm skin and warm on cool surfaces.
2. Ink outlines are 1.5–2.5 px at 1080p and fade with distance so crowds do not turn to noise.
3. Skies are painted gradients with large stylised clouds. Every time of day has a named palette (dawn rose, noon cyan, dusk amber, night indigo).
4. Bending effects carry the most saturation in any frame. Fire is orange-gold with a white core (blue for the rare prodigies), water is translucent cyan with white foam edges, earth is chunky ochre-grey slabs with dust, and air is pale swirling streaks rather than spheres.
5. Atmospheric perspective follows the painted-backdrop convention: distant layers desaturate towards the sky colour in bands, not with uniform fog.

### 2.2 Culture palettes and design language
| Culture | Primary | Secondary | Accent | Shapes and motifs |
|---|---|---|---|---|
| Earth Kingdom | jade and moss greens | ochre, tan | gold | Square, heavy, symmetrical forms; stepped walls; green-tiled hip roofs; round moon gates; the circle-in-square seal |
| Fire Nation | vermilion, crimson | black lacquer | gold | Upswept eaves shaped like flames; layered pagodas; the flame crest on helmets and banners; volcanic black stone |
| Northern Water Tribe | deep blue | ice white | silver-blue | Canals, ice spires, domed halls, crescent-moon motifs, fur trims |
| Southern Water Tribe | navy and sky blue | hide tan | white | Hide tents on whalebone frames, snow walls, wolf-head helmets, war paint, canoes |
| Air Nomads | saffron orange | golden yellow | sky blue tiles | Cylindrical towers, conical blue roofs, spirals and the air symbol, prayer flags, wind chimes, bison stables |
| Kyoshi Island | forest green | gold | white face paint | Thatched timber halls, fan motifs, the Unagi bay |
| Foggy Swamp | mangrove brown | moss | firefly yellow | One colossal banyan-grove tree, vines, mist layers |
| Si Wong sandbenders | sand and ochre | rust | indigo veils | Sand-sailers, wrapped faces, wind-carved rock |

The setting draws on real cultures: Imperial China for the Earth Kingdom, a blend of Japanese, Chinese and Southeast Asian sources for the Fire Nation, Inuit and Yupik peoples for the Water Tribes, and Tibetan Buddhist monasticism for the Air Nomads. Costume and architecture must cite those sources respectfully, without caricature. Before any of this ships, a cultural consultant pass is mandatory; it is listed as a production dependency in the sequel plan.

### 2.3 Locations the player must be able to walk through
Each location is a player-scale scene, not a menu:
* **Ba Sing Se:** the Outer Wall horizon, the Lower Ring's crowded alleys, Middle Ring tea houses and the Upper Ring's manicured gardens. Gates between rings are policed, and access depends on the player's standing.
* **Omashu:** terraced stone city on a mountain, with delivery chutes running down the tiers.
* **Gaoling:** walled estates of old money, a market square and an arena dug into the earth.
* **Fire Nation capital:** a caldera city with a palace above, a nobles' quarter and a harbour district below.
* **Ember Island:** beach houses and a theatre.
* **Agna Qel'a:** ice canals, gondolas and a moonlit oasis at its heart.
* **The Southern Water Tribe:** a great ice city in this era, not yet diminished by war.
* **The four Air Temples:** living monasteries in this era, with monks, nuns, bison, children and fruit-pie catapults.
* **Kyoshi Island:** village, dojo and a bay where the Unagi feeds.
* **The Foggy Swamp:** the great tree and its root-roads.
* **The Si Wong Desert:** an oasis town and a buried library tower.

### 2.4 Verdict on the current build
The world map is serviceable as a layout and must be repainted: biome colours are too saturated and the noise too visible. The characters must be replaced entirely. The UI's parchment look fits the show's scroll motif and should stay, with brush-stroke frames and nation seals added.

---

## 3. Agreed production plan (this iteration)
1. Write the setting and narrative bible, with two writing teams iterating on it (`docs/02_writers_room.md`).
2. Replace characters with the CC0 human-made rig, cel shading, culture outfits and facial expressions.
3. Add walkable settlement scenes for every settlement type and culture.
4. Add culture and class systems.
5. Add companion arcs and the main storyline, with choices that have consequences.
6. Run simulated playtests, then fix what they find (`docs/03_playtests.md`).
7. Simulate the launch reception (`docs/04_launch_reception.md`) and design the sequel (`docs/05_sequel_design.md`).
