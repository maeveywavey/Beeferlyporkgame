# Sequel Design: *Avatar: The Sixteenth Year*

> **Simulated studio, real design.** The staff, budget and schedule are a plan written by Claude as if the sequel were greenlit after the reception in `docs/04_launch_reception.md`. Nobody has been hired. The design is meant to be buildable, and its central system has a playable prototype in this repository (§7.9).

## 1. The pitch

Five years after the Drowned Testament, the child who is the Avatar turns sixteen.

The sages of their nation will tell them in the spring. Every faction that survived the Quiet Years knows the clock is running, and every one of them wants something settled before a sixteen-year-old with the power of four elements walks onto the stage.

You are who you were in the first game, or someone new. You have one year. When the Avatar is revealed, they will inherit the world you leave them.

**Same setting, refined; same structure, deepened.** It is still a sandbox of armies, fiefs and politics, with a written story and companions threaded through it. The new headline is bending as a martial art the player authors themselves.

## 2. What the first game taught us

| Reception finding | Sequel response |
|---|---|
| Writing, companions and consequences were the reason people stayed | Double the writers' room; 12 companions; choices import from game 1 |
| Bending felt like spellcasting with a stance | Bending rebuilt on performance capture with martial-arts masters, plus a player **Form Designer** |
| Faces, creatures and bodies read as stock | A full art studio: bespoke characters, creatures and faces |
| Interiors were menus; Ba Sing Se was flat | Every settlement walkable, interiors included; Ba Sing Se's three rings as real districts |
| No navy in a story about admirals | Naval and aerial play |
| The endgame thinned out after the story | A year-long political clock, the Avatar's reveal as a world event, and a kingdom-management layer |
| "Why can't I have *my* firebending?" | The Form Designer: compose, train, name and share your own bending forms |

## 3. Studio: double the staff, plus a full art studio

| Discipline | Game 1 | Sequel | Notes |
|---|---|---|---|
| Direction (creative, game, art, narrative) | 3 | 5 | Adds an audio director and a choreography director |
| Design (systems, combat, economy, quests, levels, UX) | 3 | 7 | A combat design pod owns the Form Designer |
| Writing (two rooms: character and lore/systems) | 2 | 5 | Plus paid sensitivity readers: queer, autistic, ADHD, Deaf, disabled, and cultural consultants for Chinese, Inuit/Yupik, Tibetan and Japanese sources |
| Engineering (gameplay, AI, tools, rendering, network, platform) | 4 | 8 | |
| QA and accessibility | 1 | 3 | Includes an accessibility lead and in-house Deaf and neurodivergent testers |
| Production | 1 | 2 | |
| **Core team** | **14** | **28** | **Doubled** |
| **External art studio** (full service) | — | about 60 at peak | Characters, creatures, environments, animation, performance capture, VFX, cinematics, UI art |
| **Martial arts and capture** | — | 4 masters, 12 performers | See §6 |

**How the doubled team works together**
* **Pods, not departments.** Each pillar (Combat and Forms, World and Politics, Story and Companions, Places) is a pod of design, engineering, art, writing and QA that ships vertical slices.
* **The two-room writing process from game 1 stays.** Team Lantern (character) drafts, Team Compass (systems and lore) annotates, and every scene must change game state. Sensitivity readers get paid time in every pass, not a final "check".
* **A weekly "Show the Floor."** Every pod shows playable work, never slides. The art director and choreography director hold veto power over feel; the game director holds it over scope.
* **Ideas are cheap and public.** A shared idea board, voted on by the whole team every sprint. The best idea of game 1 (the Law of the Two Paths as a mechanic) came from QA.

## 4. Pillars

1. **Bending is a martial art.** Every motion has a real stance, footwork, breath and intent behind it, and the player can author their own.
2. **Every choice leaves a mark the Avatar will inherit.**
3. **Places you can stand in.** Every city, temple, ship and palace is walkable, with real interiors.
4. **People, not lessons.** Queer, neurodivergent and disabled characters are written as people, with consultants in the room.
5. **Painted, inked, alive.** The look of the series' background paintings, at 60 fps.

## 5. Art direction

* **Rendering:** a Forward+ non-photorealistic pipeline.
  * **Lighting:** a two-tone cel ramp per material, with cool-shifted shadows.
  * **Ink lines:** depth- and normal-based in post, with hand-tuned weight per asset class: thick silhouettes, fine interior lines.
  * **Painted environments:** world-space brush textures ("painted skies" and "inked rocks"), matched to colour scripts per culture.
  * **Grounding:** stylised ambient occlusion that pools like watercolour.
* **Characters:** every culture gets bespoke base meshes, costume kits by class and rank, and hair and headgear.
  * Faces use a 120-shape FACS-based rig, sculpted per ethnicity group with cultural consultants.
  * Expressions are performance-captured for story scenes and hand-keyed for barks.
  * **Dialogue stays text for the main game.** Voice acting is a stretch goal (§10).
* **Creatures, built properly:**
  * **Ridden:** ostrich horse, komodo rhino, sky bison (six legs, flat tail, flying locomotion), polar bear dog, eel hound.
  * **Wild and ambient:** badgermole, buzzard wasp, sand shark, turtle duck, platypus bear, catgator, dragon moose.
  * Each creature has quadruped or hexapod locomotion with procedural foot placement.
* **Places:** ten hero cities hand-built, including Ba Sing Se's three rings, the palace, Lake Laogai and the Dai Li vaults. Every other settlement is assembled from culture kits by a layout tool that level designers edit. Interiors include taverns, halls, homes, temples, ships and the Library.

## 6. Bending as martial art

The original series built each bending art on a real Chinese martial art, with a consultant shaping the choreography. We follow the same mapping, and we commit to it all the way down to footwork.

| Art | Martial basis | What that means on screen |
|---|---|---|
| **Waterbending** | **Tai Chi** (Chen and Yang styles) | Continuous circular motion, weight shifting between legs, push-hands redirection. Attacks are rarely linear; defence turns an opponent's force back on them |
| **Earthbending** | **Hung Gar** | Low, rooted horse and bow stances, power from the ground, short explosive strikes, "tiger" and "crane" forms |
| **Firebending** | **Northern Shaolin** (with Xingyi-flavoured breath work for masters) | Long extended stances, fast linear strikes and kicks, chambered fists, power from breath |
| **Airbending** | **Baguazhang** | Circle-walking, constant evasion, palm changes, turning the body to slip and redirect |
| **Seismic or blind earthbending** (a rare style) | **Southern Praying Mantis** | Rooted, short-range, sensing stance |
| **Non-bender fighters, chi-blocking** | Wing Chun and Xingyi influences | Close-range trapping, precise strikes to points |

**Capture plan**
* **Masters:** one master per primary art, one for weapons (dao, jian, spear, hook swords, war fans) and one stunt coordinator. Each designs and approves every capture.
* **Session length:** 6 weeks of performance capture per art. Each form is captured whole, then cut into **movement units** (§7.2) at its natural transitions.
* **Performers:** performers of the appropriate heritage where possible. The Deaf performer for storm-sign scenes is a native signer.
* **Retargeting:** motion is retargeted to all body types. Footwork is preserved by IK foot-locking, so stances never skate.
* **Element simulation:**
  * Water is a GPU particle and fluid ribbon that follows the hands.
  * Earth is voxel slabs torn from the actual terrain, leaving holes.
  * Fire is breath-timed bursts with heat distortion.
  * Air is volume displacement, visible in dust, grass and cloth.

## 7. The Form Designer (headline feature)

### 7.1 Inspiration

*Kengo 2* (Kengo: Master of Bushido) had a simple, powerful idea: you learn individual techniques from masters and dojos, train them, and assemble them into your own combinations, so two players' swordsmen fight differently. The Form Designer brings that idea to bending:
- You learn **movements** from masters, scrolls, companions and from watching opponents.
- You drill them.
- You compose them into named **forms**: your firebending, your waterbending.

### 7.2 Building blocks

A **movement unit** is one captured motion, from a real form, between two natural transitions:

| Field | Example (Fire: "Rising Dragon Fist") |
|---|---|
| Art | fire |
| Stance in → out | front stance → horse stance |
| Footwork | step-through, 0.9 m advance |
| Breath | exhale on strike (frame 14) |
| Motion | rising uppercut with rear hand, palm opens at apex |
| Element shape | column (vertical) |
| Base stats | power 7, speed 6, reach 2 m, chi 9, stability −1 |
| Learned from | Master Hotaru (Crescent Island) or the scroll *Flame Ascending* |

There are about **60 movements per art** at launch, about 300 in all.

### 7.3 Composing a form
* A **form** is a sequence of **2–8 movement units**, plus a **release**: what the element does at the end. The release can be a projectile, cone, wall, wave, whip, column, ring or hold.
* **Continuity rules** make forms physically real:
  * each unit's out-stance must chain into the next unit's in-stance, directly or through an authored transition;
  * footwork cannot cross itself;
  * breath must alternate.
  The editor shows valid next movements, the way a fighting-game move list shows cancels.
* **Stats are computed, not chosen** (simplified):
  * **Power:** the sum of the units' power × release multiplier × a flow bonus, which rewards sequences that keep weight moving in one direction.
  * **Wind-up time:** the sum of unit durations ÷ mastery.
  * **Chi cost:** a base + the square of the unit count. Long forms are strong but expensive.
  * **Reach, area and stability** come from the footwork and the release.
  * **Signature properties** emerge from the sequence: three linear strikes become *piercing*; a full circle becomes *redirecting*; a breath held across two units becomes *charged*.
* **The art's character is enforced.** Water forms gain power from circularity; Earth forms from rootedness (fewer steps, lower stances); Fire forms from breath rhythm; Air forms from evasion (forms that move the bender off-line get a free dodge window).

### 7.4 Training and mastery
* **Learning:** a movement is learned from a master after a sparring trial, from a scroll after study time, or by surviving it three times in combat (observing).
* **Drilling:** a rhythm-and-posture minigame in a dojo or camp. Hit the stance windows and breath beats. It raises the movement's **mastery** (0–5 ★), which speeds it, lowers its chi cost and unlocks its *refined* version.
* **Forms level from use.** A form used in real fights gains **polish**, which lowers its wind-up.
* **Companions spar with you,** and some teach movements you cannot learn anywhere else. Nima teaches the reversal from game 1; Pemba teaches evasive Bagua circles.

### 7.5 In combat
* **Equipping:** four form slots plus basic strikes. Forms queue like combos. Pressing a form's key begins its first movement; the remaining movements flow automatically, while the player steers direction and can **cancel at transitions** into a block or dodge.
* **Counterplay is readable.** Opponents' forms telegraph through the stance they start in. A trained player learns to read a horse stance (incoming earth column) or a deep inhale (fire burst), and to answer it.
* **NPC masters have their own signature forms.** Some of their movements can only be learned by beating them.

### 7.6 Naming and sharing
* **Naming:** forms get player names, with name suggestions generated from the movements ("Seven Tides Turning").
* **Sharing:** a form is a short code (art + movement IDs + release) that can be pasted into a friend's game. It works only if their character has learned those movements, which keeps learning meaningful.
* **Archive:** a "Form Archive" at the Eastern Air Temple displays signature forms of famous benders and of the player's own past characters.

### 7.7 Balance guardrails
* Every movement's stats are tuned from its *captured* duration and footwork. A fast movement is fast because it is fast in real life.
* **Diminishing returns:** repeating a movement within one form halves its contribution.
* **AI library:** AI benders use designer-built forms tuned per difficulty, and adapt by learning which of the player's openings they get punished for.

### 7.8 Accessibility
* The drill minigame has a **guided mode** with no timing windows; mastery is earned through repetition counts instead.
* An **auto-chain mode** lets players press one key and have the form steer itself.
* Forms can also be built from a **list view** instead of the 3D editor.

### 7.9 Prototype in this repository

A playable prototype of the Form Designer ships in this build: **Character → Bending Forms**. It uses the current motion clips and procedural stance layers as stand-ins for the captured movement units.

The prototype includes:
- per-art movement libraries;
- stance-continuity rules;
- computed power, wind-up, chi cost and properties;
- naming;
- assigning a form to the **F** key in battle, where it plays the movement sequence and fires its release.

It is the sequel's system at prototype fidelity: the rules are real; the animation is not yet captured.

## 8. Combat and war

* **Melee:** directional strikes, as in game 1, plus parries that become **redirections** for Water and Air.
* **Lightning:** redirectable by trained firebenders, through a timing-based counter form.
* **Sieges with bending:**
  * earthbenders breach walls and raise ramps;
  * firebenders serve as artillery;
  * waterbenders freeze moats;
  * defenders reinforce walls with earth.
* **Naval battles:** ships as moving battlefields. Boarding, ramming and bending against hulls; waterbenders steer currents; fog, storms and eclipses matter. The Fire Navy is a fleet, not a walking army.
* **Aerial play:** gliders for Air Nomads, sky bison as transport and as a battle platform, and war balloons late in the year as a historical novelty of the Fire Nation.
* **Scale:** 500 units on the field, via a crowd system with animation LOD and instanced costumes. Formations and lord AI that coordinates relief of sieges.

## 9. World, politics and the clock

* **The Year:** the campaign runs one in-world year to the Avatar's reveal.
  * Seasons change the map: frozen seas in the north, monsoon in the Earth Kingdom.
  * Factions race to secure what they want before the reveal.
  * **The reveal is a world event.** Who the Avatar is never changes, but how each nation receives them depends on the world the player built.
* **Kingdom management:**
  * holdings with buildings, laws and stewards;
  * councils (the South's and the North's councils are playable);
  * marriages and alliances;
  * trade agreements;
  * class mobility for the player's own subjects.
* **Culture systems carried over:** Ba Sing Se's rings, Agni Kai, the Law of the Two Paths (or its absence, if changed in game 1), Air Nomad refuge, and daofei brotherhoods. Each is expanded with interiors and questlines.
* **Endgame:** after the reveal, an epilogue sandbox. The player can serve the new Avatar, oppose them, or simply go home. The ending slides draw on both games.

## 10. Story

* **Import:** game 1's outcomes import from the save — the ending, the Accord, the Moon Guard, every companion's fate. There are sensible defaults for new players.
* **Twelve companions:** six returning, six new. Returning companions are changed by what happened. A Hana who spared Bo Lai is not the Hana who killed him.
* **New companions (draft):**
  * a Fire Nation conscript who is non-binary and the last of their unit;
  * an autistic Earth Kingdom archivist hunting the sages' records of the child;
  * an elderly Southern master losing her sight;
  * a young Dai Li defector;
  * a Foggy Swamp guide who has never seen a city;
  * a Sandbender who leads Kesi's clan (if it survived).
* **Main story, "The Sixteenth Year":** three factions try to find the Avatar before the sages reveal them — to protect them, to control them, or to make sure they never arrive. The player learns the child's identity only if they choose to. The game never shows it, as in game 1.
* **Voice:** the main game ships text-first, as in game 1, with fully performance-captured faces. Full voice acting is a stretch goal, budgeted separately. Deaf characters sign on screen, performed by Deaf actors.

## 11. Accessibility and representation

* **Everything from game 1, plus:**
  - full control remapping;
  - controller support;
  - a one-handed control scheme;
  - colour-blind palettes, with faction colours paired with patterns;
  - dyslexia-friendly fonts;
  - adjustable text speed and auto-advance;
  - toggles for screen shake and flashing;
  - a "low sensory" mode for crowds and audio density;
  - a combat-assist difficulty that never locks out story content.
* **Pronouns and body:** pronouns, voice pitch (if voice ships) and body are independent choices. Romance is gated only by each companion's own attractions, written into the character, never by the player's body.
* **Process:** consultants are credited and paid. Representation notes are part of every review pass, and players can read them in the in-game Codex.

## 12. Technology

* **Engine:** Godot 4.x with a Forward+ NPR renderer, Jolt physics, and a custom crowd and animation-LOD system.
* **Tools:** a settlement layout editor; a movement-unit editor for tagging stances, breath and contact frames on captured clips; a dialogue tool that validates every condition and effect against game state, extending `tests/test_story.gd`.
* **Saves:** compatibility with game 1 through a versioned importer.
* **Performance targets:** 60 fps at 1080p on a 2019 mid-range GPU with 300 units; 30 fps on Steam Deck with 150 units.
* **Ports:** consoles at launch, built on the same pipeline.

## 13. Two-year schedule

| Months | Phase | Exit criteria |
|---|---|---|
| 1–4 | Pre-production | Art bible 2.0, capture plan with masters, Form Designer paper and digital prototype, a vertical slice plan |
| 5–10 | Vertical slice | One region (the Ember Coast): one hero city with interiors, naval skirmish, 1 art fully captured (Fire), Form Designer in 3D, 2 companions with full quests. External playtests run with consultants |
| 11–16 | Production | All four arts captured (6 weeks each, overlapped); all hero cities; creatures; 12 companions written and implemented; politics clock |
| 17–20 | Alpha | Content complete; balance passes on forms; accessibility suite complete; localisation in 10 languages |
| 21–23 | Beta | Bug-fixing, performance, certification, a public demo (Ember Coast) |
| 24 | Launch | PC and consoles on the same day |

## 14. Budget (planning figure)

| Item | Estimate |
|---|---|
| Core team (28 × 24 months, fully loaded) | $10.1M |
| External art studio | $11.5M |
| Performance capture, masters, performers | $2.4M |
| Writers, sensitivity readers, cultural consultants | $1.1M |
| Licence minimum guarantee | $2.5M |
| Audio and music (live ensemble) | $1.2M |
| Localisation (10 languages) | $1.6M |
| QA (external), accessibility testing | $1.4M |
| Marketing | $6.0M |
| Contingency (15%) | $5.6M |
| **Total** | **about $43M** |

"Unlimited funding" does not mean unlimited time. Two years is the hard constraint, so money buys parallelism (the art studio, capture overlapped across arts), not features. The scope above fits 24 months only because the first game's systems, tools and test harnesses already exist.

## 15. Risks

| Risk | Likelihood | Response |
|---|---|---|
| Form Designer produces degenerate "best forms" | High | Stats derived from captured motion; diminishing returns; AI that adapts to the player's habits; live tuning |
| Capture schedule slips (master availability) | Medium | Overlap arts; capture the Fire vertical slice first; shoot pickups in production |
| Licence approvals slow (story, characters) | Medium | Monthly licensor reviews from pre-production; an original story that does not touch canon events |
| Scope creep from "unlimited" funding | High | Pillar veto; cut list maintained from month 1; voice acting kept as a separate stretch budget |
| Representation done badly despite good intent | Medium | Paid consultants in every pass; community advisory group from game 1's audience |
| 500-unit battles miss the performance target | Medium | Animation LOD, impostors past 80 m; target 300 on minimum spec |
