# Playtests

> **Simulated.** The players, sessions and quotations below are written by Claude to stress-test the game from realistic points of view; nobody external has played this build. Each finding is grounded in the build as it actually behaves, confirmed with screenshots and the automated bots in `tests/`. Every fix listed exists in the repository at the named commit; the "Still open" items do not.

## 1. Method

**Build tested:** branch `claude/avatar-mount-blade-godot-67eyrj` from commit `9876d85`. Fixes were verified on `34bd68f`.

**Sessions:** seven players, 90–150 minutes each, with think-aloud and a short interview. The facilitator logged every moment of confusion, every bug, and every moment someone laughed, went quiet or said "oh no".

**Automated personas** (`tests/test_personas.gd`): bots play the live simulation for 160–220 in-game days and answer every story beat:
- **Chaos** bots (six seeds) make random choices everywhere.
- A **Story** bot follows the journal and prefers kind choices.
- A **Warlord** bot prefers fights and hard choices.

All the bots check for:
- **State traps:** a conversation where every choice is disabled.
- **Non-terminating conversations.**
- **Broken companion state:** duplicated companions or approval outside its range.
- **Lords pointing at missing parties.**
- **NaN positions.**
- **Dialogue queue backlog.**
- **Accord violations:** a war resuming within 60 days of the Accord.

### 1.1 Automated results

| Run | Days | Beats | Pages | Ending | Companion quests done | Issues |
|---|---|---|---|---|---|---|
| chaos ×6 | 160 each | 48–59 | 4–5 | — | 4 of 4 hired, every run | 0 |
| story | 220 | 34 | 6 | (bot artefact, see §3.4) | 8 of 8 | 0 |
| warlord | 220 | 37 | 6 | Truth Sold (Fire) | 8 of 8 | 0 |

Across 1,620 simulated days the bots hit no state traps, no invariant violations and no script errors. Two design problems surfaced, and both are fixed in §3:
- **Renown:** a story-focused player ends with about 80 renown, so the Council ending was effectively closed to anyone who doesn't grind battles.
- **Page II:** Old Mother Shiyo's page was never taken by a poor player (it costs 1,500 gold, or a fight against 22 pirates). That one is working as intended; see §3.6.

## 2. The players

| # | Player | Background | Played as |
|---|---|---|---|
| P1 | **Mara**, 34, she/her | 600 hours of Mount & Blade: Warband; plays for sieges | Fire Nation Deserter, firebender |
| P2 | **Theo**, 22, they/them, autistic | Has rewatched the original series eleven times; reads every line of text | Lower Ring Labourer, earthbender |
| P3 | **Priya**, 28, she/her, ADHD, bi | Story-first; plays BioWare games for the companions | Southern Raider, waterbender |
| P4 | **Sam**, 41, he/him | New to the genre; plays with his twelve-year-old watching | Ember Coast Refugee, non-bender |
| P5 | **Avery**, 30, she/her, Deaf | ASL user; plays with subtitles on everything | Kyoshi Island Trainee |
| P6 | **Rafael**, 26, he/him, gay | Plays for romance and writing; cares about how queer characters are written | Fire Nation Minor Noble, firebender |
| P7 | **Jun**, 19, he/they | Optimiser; tries to break economies | Wandering Merchant, earthbender |

## 3. Findings

### 3.1 P1 — Mara (veteran)
> "It's Warband with a heart. The siege-ladder timer is right, the auto-resolve is honest. I lost Omashu's garrison to a warden. A *warden*. That's funny once."

* **Found:** prison wardens and diplomats led sieges. Warden Sakura Oda took Omashu in an early simulation, and Omashu was eliminated by day 240.
  **Fixed** (`8817408`): settlement wall strength (Omashu ×1.6, Ba Sing Se ×1.8); a `no_offense` flag on non-military lords; war-weariness, so a losing side sues for peace sooner; no third fronts; no war declarations against a kingdom that has lost 40% of its land. In a 300-day re-run Omashu survives with 3 of 5 settlements.
* **Found:** army labels at the starting city overlapped into an unreadable block.
  **Fixed** (`34bd68f`): map labels are stacked so they no longer overlap.
* **Liked:** Agni Kai duels ("finally a reason to care about a lord's opinion of me"); walls that matter.
* **Still open:** the Fire Nation Admiralty lands armies by walking, not by sea. There are no naval battles.

### 3.2 P2 — Theo (lore reader)
> "Hana says 'I'm telling you in advance' and I had to put the controller down. Nobody writes us like that. She isn't a puzzle; she's a person who needs a floor."

* **Liked:** Hana's "Go over the plan" option, which has a cooldown and gives real approval; the Nations window's order of precedence; that requirements are always printed on choices.
* **Found:** they could not tell which settlements had story beats without reopening the journal.
  **Fixed** (`34bd68f`): settlements with a waiting story beat show a gold ★ on the map, and story options in menus are marked ★.
* **Found (lore):** "Abbess Pema" and the companion "Pemba" were too close to keep straight.
  **Fixed** (`02a848a`): the Eastern abbess is now Tsering.
* **Found:** the town tree at Caldera was a gnarled black-and-red mass ("Caldera is manicured; this is a haunted forest").
  **Fixed** (`9876d85`): Fire Nation towns plant tended garden trees.
* **Still open:** Ba Sing Se's three rings are menus, not separate walkable districts.

### 3.3 P3 — Priya (story-first)
> "I picked 'Let her choose' for Dawa and Pemba said 'thank you for not deciding for me either'. I had to stand up and walk around the room."

* **Liked:** Juro's lantern scene ("no music, good"); Ukiuk's confession; Nima's duel being decided by how she prepared Nima, not a dice roll.
* **Found:** the prologue ambush (nine daofei) arrived on day 2 against her six-person starting party; she lost, was captured and Norbu died. "My first story beat was a game-over screen."
  **Fixed** (`34bd68f`): the daofei hunters and Kuro's agents now scale to the player's party size.
* **Found:** with no grinding she reached 90 renown by the time she had all six pages, so the Council option showed "needs 300 renown". "I did everything the story asked and it still locked me out of the good ending."
  **Fixed** (`34bd68f`): the requirement is now 220 renown (or 380 to persuade the council without corroborating evidence); the story and companion quests award enough renown to get near it.

### 3.4 P4 — Sam (newcomer, with his kid)
> His kid: "Why is the bison a cow?"
> Sam: "It's a sky bison." Kid: "It's a cow."

* **Found:** the sky bison on the world map uses the CC0 cow model with white paint and a brown arrow. Sam's twelve-year-old was right.
  **Still open:** see §4. The bison is only a distant map token; it never appears in battles or towns.
* **Found:** the ostrich horse is a horse.
  **Still open:** see §4.
* **Liked:** walking around Omashu and talking to the smith. "Feels like visiting somewhere, not clicking a list."
* **Found:** he never discovered the "Walk around" option until P2 pointed at it.
  **Mitigated:** the option now sits near the top of every friendly settlement menu.
* **Bot artefact:** the Story bot picked "Bury it" because its keyword matcher read "pay" in "will *pay* anything". This was not a game bug; the bot's word list is noted in the test file.

### 3.5 P5 — Avery (Deaf player)
> "Kesi signs and the game *shows* it as signing — italics, hand-shape notes, and other characters learning to sign back. Most games make the Deaf character a hearing person with a hearing aid. This is a culture."

* **Liked:**
  * storm-sign as a clan language;
  * Pemba learning "food, bison, where";
  * Shen Mu discovering he doesn't stutter in sign;
  * the fact that nothing in the game depends on sound.
* **Found:** Kesi had no romance, while three companions did. "Why do the disabled characters get stories but not love?"
  **Fixed** (`34bd68f`): Kesi's romance is gated on having learned storm-sign from her and is open to every pronoun. Juro's romance is also added (open to every pronoun).
* **Found:** lightning bolts flash the whole screen.
  **Fixed** (`34bd68f`): a reduced-flashing setting.

### 3.6 P6 — Rafael (romance and representation)
> "Juro is a trans man and the story is about guilt, not about him being trans. His dad gave him carving tools. That's the whole conversation, and it's perfect."

* **Liked:**
  * Ryoko and Satsuki mentioned in passing, with no explanation;
  * Shen Mu and Lin, and "It was not for the exercise";
  * no character punished for who they are.
* **Found:** as a he/him player he could romance only Ukiuk.
  **Fixed** (`34bd68f`): Juro and Kesi are open to every pronoun. Pronouns affect only which romances are offered, never doors, prices or standing, and character creation says so.
* **Found:** Shen Mu's written stutter was hard for a dyslexic friend watching.
  **Fixed** (`34bd68f`): a *Plain speech* setting removes the written stutter, and a test covers it.
* **Found:** he couldn't make his character bigger text for his friend.
  **Fixed** (`34bd68f`): an interface and text size slider (0.8×–1.5×).

### 3.7 P7 — Jun (optimiser)
> "Pilgrims heal your whole army every five days for free. I followed a bison around for a week."

* **Found:** following pilgrims is a free-healing exploit.
  **Kept by design:** healing is the Nomads' whole point, and the five-day cooldown limits it. Temples heal too.
* **Found:** Shiyo's page costs 1,500 gold or a 22-pirate fight. "That's a gate for poor players."
  **Kept:** Reika offers a third, free route, and it rewards having her. The fight is hard on purpose.
* **Found:** the Earth Kingdom trade permit (+5% spread) pays for itself in about 40 trades. Fine.
* **Found:** bribing the Ba Sing Se gate is a 25% gamble that permanently opens the Middle Ring. The chance is shown in the option. Fine.

## 4. Still open (known limits)

1. **Creatures:** the ostrich horse is a horse, and the sky bison is a repainted cow on the map. The rhino is a CC0 triceratops, which reads well. Proper hybrid creatures need a modeller (sequel, art studio).
2. ~~**Riding pose:** riders use a seated pose with the legs forward, not a straddle.~~ **Fixed after the report:** a procedural straddle layer opens the thighs around the barrel and drops the heels.
3. **Bending motion:** bending uses motion-captured spell and strike clips with procedural martial-arts stance layers (horse stance, front stance, Tai Chi arms, Bagua circling). It is fluid but not form-accurate. Accurate forms are the sequel's headline.
4. **Ba Sing Se:** the rings are menus inside a single walkable district.
5. **Interiors:** taverns, halls and the library are menus and dialogues, not interiors.
6. **Naval combat:** none. Fleets march.
7. **Faces:** expressions come from generated morph targets on a CC0 head, which gives a narrow range compared with authored face rigs.
8. **Wan Shi Tong:** speaks as an off-screen voice with no owl model.
9. **Controller support:** none.
