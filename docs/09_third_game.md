# Third Game: *Avatar: The Four Masters*

> **Simulated studio and simulated executives.** Everything about the studio in this document is written by Claude as a production plan, and nobody has been hired.
>
> The executive team named in the brief is made of real people:
> - Michael Dante DiMartino
> - Bryan Konietzko
> - Hidetaka Miyazaki
> - Hideo Kojima
> - Henry Selick
> - Hayao Miyazaki
>
> **None of them has seen, endorsed or commented on this project.** Their part here is a simulation: each is represented by a review lens built from the design values evident in their public body of work. Their annotations are paraphrased design notes written by Claude. They are not quotations, and they should not be read as anyone's opinions. This document contains no quotation attributed to any of them.
>
> **What is real.** The interface overhaul in §6 exists in this repository. Its second-round fixes were found by taking screenshots of the build.

## 1. Pitch

**Setting.** The young Avatar has been told. Over three in-world years they must learn three elements. Every master, ruler and warlord in the world is part of the answer to the question the game asks: what kind of Avatar does the world make?

**Who you are.**
- You are still never the Avatar. You are one of the people they meet: a non-bender or a bender of one element.
- You might be the master they come to, the ruler they sit with, or the tyrant they have to stop.

**The Avatar system grows out of games 1 and 2:**
- the four reasons the Avatar comes to the player;
- countermeasures against a hostile Avatar;
- the teacher path.

**New in game 3:**
- **The Spirit World as a second map layer.** It is reached through meditation at places where the world is thin: the Foggy Swamp's banyan, the Northern oasis, the temples.
- **Forms authored and shared at scale.** Forms are built from captured movement for every art the series draws on.

## 2. The studio

### 2.1 Who stayed, who joined, what changed

**Who stayed.** Game 2's strongest people are all still here: its designers, engineers and artists, chosen for skill and for wanting to be here.

**What changed:**
- **Player Insights** (`docs/08_sequel_release.md` §1) is now a permanent department, with seats on the executive review.
- **Pay rises** across every department:
  - 12% base for everyone;
  - 18% for QA, support and community, the roles game 2 relied on most and paid least.
- **More hires:** every department hires.

| Department | Game 2 | Game 3 | Notes |
|---|---|---|---|
| Executive team | — | 6 | The simulated review body in §3 |
| Direction | 5 | 6 | Adds a UI and visual-language director who reports to the art director |
| Design | 7 | 14 | Adds the two partner design teams below |
| Writing | 5 | 8 | The two-room process continues; sensitivity readers stay paid in every pass |
| Engineering | 8 | 14 | |
| In-house art studio | (60 external) | 45 in-house, 30 external | Characters, creatures, environments, VFX, cinematics |
| Animation and capture | 4 masters, 12 performers | 11 masters, 16 performers | One master for every martial art the series draws on (§2.3) |
| **UI Team Lacquer** (systems and interaction) | — | 7 | §4 |
| **UI Team Ink** (visual and material) | — | 7 | §4 |
| Player Insights (Signal, Voices, Currents, Bridge) | 22 | 28 | Currents adds a short-video producer and a third language community manager |
| Culture and Philosophy department | (consultants) | 9 | §2.4 |
| QA and accessibility | 3 | 8 | Includes Deaf, blind and low-vision, and neurodivergent testers on staff |
| Production | 2 | 4 | |

### 2.2 Partner design teams

Both partner teams are simulated by the strengths their games are known for.

**The design team behind *Fallout: New Vegas*** owns reputation and consequence.

They bring what that game is known for:
- faction reputation that is tracked separately as fame and infamy;
- quests with several real solutions, including talking, stealth, trade and violence;
- skill and stat checks shown in dialogue;
- companions with perks and opinions;
- endings assembled from many small outcomes.

Their first task was to rebuild infamy as a set of separate reputations:
- the Avatar's regard;
- each nation's fame and infamy;
- the temples' trust.

The Avatar can then judge cruelty in the Earth Kingdom without forgetting kindness in the North.

**The design team behind *Mount & Blade*** owns the sandbox's spine. They bring:
- directional melee and cavalry;
- sieges;
- lord AI and the feudal economy;
- the open-ended army-raising loop that games 1 and 2 were built on.

Their first task was to make lords remember the player across all three years, and to let a besieged lord negotiate rather than only fight or flee.

### 2.3 Martial-arts masters

There is one master on staff for each art the series and these games draw on. They choreograph, capture and veto. The arts covered:

| Area | Art | Uses in the games |
|---|---|---|
| Firebending | Northern Shaolin | Firebending generally |
| | Long Fist (Changquan) | The Agni Kai duellists |
| | Qigong breath | The Sage Breath style |
| Earthbending | Hung Gar | Earthbending generally |
| | Southern Praying Mantis | The Dai Li's Stone Hand |
| Waterbending | Yang-style Tai Chi | Northern waterbending |
| | Chen-style Tai Chi | Southern waterbending |
| Airbending | Baguazhang | Airbending |
| Non-bending | Fan and short-weapon forms | The Kyoshi Warriors |
| | Acupressure-based striking | Chi-blocking (the series' chi-blockers) |
| | Chinese sword arts: jian, dao, double broadswords, hook swords | Swordsmanship |
| | Traditional Arctic hunting and throwing weapons | The Water Tribes' clubs, spears and boomerangs, advised with the Inuit and Yupik cultural consultants from game 2 |

**Veto.** No bending form ships unless the master of its art signs it off as being their art: the stance, the breath and the intent.

### 2.4 The Culture and Philosophy department

A new department of nine people, with standing review rights over writing, art, UI and design. Its specialisms:

| Specialism | Covers | Advises on |
|---|---|---|
| Chinese history and material culture | Dress, architecture, ritual, everyday objects | The Earth Kingdom, and the Fire Nation's Chinese layers |
| Japanese history and material culture | The Fire Nation's Japanese layers: court, duel and naval culture | |
| Tibetan and Himalayan culture | | The Air Nomads, in partnership with Tibetan consultants |
| Philosophy | Daoism, Buddhism and Confucianism | How the four nations think, not only how they dress |
| Traditional martial arts history | Lineages, ethics, teacher–student custom | Distinct from the capture masters, who own movement |
| Yoga | Practice and its philosophical traditions | Meditation, chi and the chakra lore the series uses |
| Anime and animation craft | Limited animation, timing, impact frames, smears | Character acting; how 2D animation conveys weight |
| Hong Kong action cinema | Fight choreography, wire work, prop-based comedy fighting, camera grammar for martial arts | How battles are framed |

**First recommendation, adopted.** The UI's seal glyphs (§6) use characters that read identically in Simplified and Traditional Chinese, because the series' signage uses Traditional script. Each glyph's meaning matches its window. The department supplied the list.

## 3. The executive team and its review policy

### 3.1 Review lenses

Each member is represented by a lens: the questions their public work suggests they would ask. These are Claude's characterisations of well-known work, not statements by the people named.

| Member | Public work the lens is drawn from | The lens asks |
|---|---|---|
| **DiMartino and Konietzko** (one seat, as co-creators) | Co-created *Avatar: The Last Airbender*. Its bending was grounded in Chinese martial arts with a martial-arts consultant, and its cultures drew on Asian and Arctic peoples. | Is this true to the world's rules, cultures and martial arts? Do characters earn their changes? Does humour sit beside seriousness without undercutting it? |
| **Hidetaka Miyazaki** | Directed games known for interconnected worlds, story told through places and item text, and difficult but fair combat that explains little | Does the world reveal itself through what the player finds rather than through what they are told? Is challenge fair and learnable? |
| **Hideo Kojima** | Directed games known for cinematic presentation, systems that interlock, close attention to detail, and themes of connection between people | Do the systems talk to each other? Does the interface have a voice consistent with the fiction? Is every detail deliberate? |
| **Henry Selick** | Directed stop-motion films known for handmade, tactile craft | Does it look made by hands: texture, weight, slight imperfection? Or does it look generated? |
| **Hayao Miyazaki** | Co-founded Studio Ghibli. Hand-drawn films known for nature and spirits, moral complexity without simple villains, flight, everyday work, and quiet pauses. Widely reported, in a 2016 documentary, to have reacted with strong distaste to an AI-generated animation demonstration. | Is there room to breathe? Do nature and the spirits have weight? Is anything here made without care? |

### 3.2 The review policy

**Every team submits to the executive team: design, writing, art, UI, engineering, capture, insights and culture.**

1. **First submission: always returned.** Annotations come back within 72 hours, however strong the work. The policy exists because the brief requires that the executive team always find a way to make it better. In practice it also removes the incentive to hold work back until it feels finished.
2. **Second submission:** approved, or returned again with fewer, narrower annotations.
3. **Disagreements** between lenses are written down, not averaged. The submitting team's director chooses and records why.

## 4. The two UI teams

The brief: remove every trace of a cheap, flat, boring, amateur, vibe-coded look, and build an entirely new interface with the art departments, worthy of critical acclaim.

**Team Lacquer (systems and interaction), seven people:**
- a UX lead;
- two interaction designers;
- an information architect;
- an accessibility specialist;
- two front-end engineers.

**Team Ink (visual and material), seven people:**
- a UI art lead;
- two UI artists;
- a typographer;
- a motion designer;
- an iconographer and calligraphy liaison working with the Culture department;
- a technical artist for shaders and procedural textures.

**Shared principles, written in week one:**
1. **Materials, not colours.** Every surface is something that could exist in this world: paper, lacquer, ink, gold leaf, stone. No flat colour blocks.
2. **Choices and actions look different.** Menu choices are rows on paper; actions are lacquered tablets; the selected option is gold leaf.
3. **Type carries hierarchy.** Small capitals for titles and headings, a humanist serif for reading, and lining figures for numbers. A hyperlegible alternative is one switch away.
4. **The world's own script.** Each screen carries a seal with a single meaningful character.
5. **Breath.** Windows settle in rather than snap, unless motion is reduced. The title screen moves slowly.
6. **Ten feet away.** Every screen must be legible on a television and reachable without a mouse: number keys in dialogue, Enter to continue.

## 5. Review log (selected)

Rounds marked **(this build)** describe changes made in this repository.

### 5.1 UI, first submission (returned, as policy requires)

**Submission.** A modern flat interface: dark rounded rectangles, a sans-serif typeface, accent colours per faction, and icons from a standard set.

**Annotations by lens:**
- **Selick:** nothing has a surface; it could be any game. Make it out of something.
- **Hayao Miyazaki:** it is efficient and lifeless. Windows appear like slammed doors. Let the eye rest.
- **DiMartino and Konietzko:** the world of the series is full of scrolls, seals, calligraphy and painted backgrounds. None of that is here.
- **Hidetaka Miyazaki:** every menu is a list of equal-weight buttons, and nothing invites the player to look closer.
- **Kojima:** choosing, acting and reading are three different acts and should feel different. Here they are all the same button.

### 5.2 UI, second submission (this build)

The materials system, implemented in `scripts/ui/skin.gd` and `scripts/ui/ui.gd`:

| Element | Implementation |
|---|---|
| Paper | Generated paper with fibre and mottling, burnt edges, an ink rule and a gold hairline, plus a seamless paper tile behind every window's content |
| Action tablets | Lacquered wood: a vertical gradient, grain, a lit top edge, and a gold inlay line, in four states |
| Menu choices | Rows on paper with a dotted ink rule; hovering lays a cinnabar mark in the margin |
| Selected options | Gold-leaf tablets with ink lettering |
| Rules | A dry brush stroke, thick in the middle and dry at the ends |
| Window chrome | Gold corner brackets with cinnabar beads; a lamp-lit vignette instead of a grey veil |
| Seals | One per window type, for example 城 *city* for settlements, 言 *speech* for conversations, 神 *spirit* for the Avatar, 法 *method* for techniques |
| Typography | Alegreya SC for titles, Alegreya for text, Ma Shan Zheng for seals, and Atkinson Hyperlegible as the readable option (all SIL Open Font Licence) |

**Further changes:**
- **Title screen:** an animated ink-wash landscape painted by a shader (`shaders/ink_wash.gdshader`), with a hanging-scroll menu and the four element seals.
- **World-map HUD:** a lacquer banner with the season's seal (冬 春 夏 秋), the date in small capitals, labelled stat chips that turn red when low, and key-hinted tablets. Log lines sit on ink strips with a colour mark.
- **Map labels:** small capitals.
- **Dialogue window:** a gilt-framed portrait and a lacquer nameplate. Choices are numbered and chosen with the 1–9 keys, and Enter continues.
- **Settings:** reduced motion; readable font; the expansion switches.

**Annotations (round 2), each confirmed in this build's screenshots and fixed:**
1. **Kojima:** stat numbers in the HUD and character sheet read as letters. Alegreya's default old-style numerals make 0 look like o. *Fixed:* lining figures throughout.
2. **Selick:** the selected option is only a change of text colour on red lacquer, easy to miss. *Fixed:* selection is a different material, gold leaf.
3. **Hidetaka Miyazaki:** the HUD's last tablet ("Nations") runs off the screen at 1600 pixels. Information that cannot be reached cannot be discovered. *Fixed:* compact tablets.
4. **DiMartino and Konietzko:** the title screen's brush texture streaks vertically. Ink-wash brushwork follows the ridge, not the fall line. *Fixed:* in the shader.
5. **Hayao Miyazaki:** the settings window grew past the screen once the new options were added; the save button was cut off. *Fixed:* the options scroll inside a fixed frame.

**Status:** approved on round 2, with one standing note carried into production. The battle HUD still uses the round-1 bars and should get the same material treatment.

### 5.3 Avatar systems, first submission (returned)

**Submission.** The four motives, countermeasures and teacher path from `docs/07_avatar_and_dlcs.md`.

**Annotations:**
- **Hayao Miyazaki:** the Avatar acts on the world (lifting sieges, brokering truces) but is never shown resting, eating or failing. *Response (planned for game 3):* the Avatar's visits will include ordinary scenes found by chance, such as a meal or an argument with a past life, which teach nothing and grant nothing.
- **Kojima:** infamy is one number, so all cruelty is the same. *Response (planned):* split into reputations (§2.2).
- **Hidetaka Miyazaki:** the teacher path is invisible until reached. Game 2's insight card IC-06 found the same. *Response:* masters and sages will speak of it (planned). The Avatar window already shows the requirements, as in this build.

### 5.4 Combat and Forms, first submission (returned)

**Annotations:**
- **DiMartino and Konietzko:** forms are composed from captured movements but the release, the moment the element leaves the body, is still a projectile effect. *Response (planned):* releases will be captured too, with the masters.
- **Hidetaka Miyazaki:** the Breath Ladder lesson from game 2 (IC-01) is that players find the dominant form in days. *Response (planned):* enemies will read and adapt to the player's most-used form, as a sparring partner would.

### 5.5 Writing, first submission (returned)

**Annotation, Hayao Miyazaki lens:** the antagonists of game 2's story (Kuro, Wu Jian) were improved by `docs/06_script_review.md`, which gave them scenes. Game 3's antagonists still lack them. *Response (planned):* every faction leader in the first act will get a scene in which they are right about something.

## 6. What changed in this repository

The "apply its improvements" part of the brief is the interface overhaul:

| File | Change |
|---|---|
| `scripts/ui/skin.gd` | New. Generated paper, lacquer, gold-leaf, row, brush and check textures; fonts with lining figures; seals |
| `scripts/ui/ui.gd` | Theme rebuilt on the skin; menu rows separated from action tablets; gold-leaf selection (`UI.mark_selected`); small-capital headings |
| `scripts/ui/window_base.gd` | Framed paper windows with corner ornaments, seals, small-capital titles, a brush rule, a lamp-lit backdrop and a settle-in animation (off with Reduce motion) |
| `shaders/ui_vignette.gdshader`, `shaders/ink_wash.gdshader` | New: the modal backdrop and the title-screen landscape |
| `scripts/ui/main_menu.gd` | Hanging-scroll title menu over the ink-wash; element seals |
| `scripts/world/world_map.gd` | Lacquer HUD banner, season seal, stat chips, inked log lines, small-capital map labels |
| `scripts/ui/dialogue_window.gd` | Gilt portrait frame, nameplate, numbered choices and keyboard selection |
| `scripts/ui/settings_window.gd` | Readable font, reduced motion, expansion switches, a scrolling options list |
| `assets/fonts/` | Alegreya, Alegreya SC, Atkinson Hyperlegible and Ma Shan Zheng, with their Open Font Licence texts |

Screenshots of the result are in `docs/screenshots/`.

## 7. Schedule and budget (planning figures)

**Schedule: 30 months.**

| Months | Phase |
|---|---|
| 1–5 | Pre-production; first executive round for every discipline |
| 6–12 | Vertical slice: the Northern Temple, one master's full art captured, the Spirit World layer prototype |
| 13–22 | Production |
| 23–27 | Alpha and beta |
| 28–30 | Launch window |

**Budget:** about US$78M.
- Staff at the new pay rates: US$31M.
- Art (mostly in-house now): US$16M.
- Capture with eleven masters: US$4.6M.
- Licence: US$4M.
- Marketing: US$10M.
- Localisation and QA: US$4.4M.
- Contingency: US$8M.

**What the money buys.** As in game 2, unlimited funding buys parallelism and craft, not features. The executive policy of always returning the first submission costs about one extra iteration per discipline per milestone. The schedule carries it explicitly: three weeks per milestone.

## 8. Risks

| Risk | Response |
|---|---|
| The always-return policy becomes a ritual that teams game by holding work back | Insights tracks the change between first and second submissions. If first submissions get worse, the policy is discussed openly at the next executive round |
| Lens annotations conflict (craft versus legibility, breath versus pace) | Conflicts are written down and decided by the owning director, never averaged |
| The materials-first UI hurts legibility or performance | Lacquer owns legibility vetoes. Textures are generated once and cached (as in this build); every screen is checked at TV distance and with the readable font |
| Cultural detail becomes decoration | The Culture department reviews meaning, not only appearance. Every seal glyph and pattern has a documented meaning |
