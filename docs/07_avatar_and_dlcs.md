# The Avatar, and the Four Element Expansions

This document specifies two post-launch additions to *Avatar: The Quiet Years*, both implemented in this repository:

- **The Avatar** becomes a persistent non-player character.
- **Four element expansions**: *Embers of the First Flame*, *The Turning Tide*, *Roots of the Mountain* and *The Thirty-Six Winds*.

Where this document gives a number, the number is the one in the code. Code paths:

| Area | Files |
|---|---|
| Avatar | `scripts/core/avatar.gd`, `scripts/story/avatar_story.gd`, `scripts/ui/avatar_window.gd` |
| Expansions | `scripts/dlc/`, `scripts/battle/techniques.gd`, `scripts/core/bending_work.gd`, `scripts/ui/techniques_window.gd`, `scripts/ui/bending_work_window.gd` |

## 1. The player is never the Avatar

Character creation has two steps.

**Step one: choose an era.** This is described in §2.

**Step two: choose an element, then a background.**

The five elemental choices are: non-bender, firebender, waterbender, earthbender and airbender. Each background lists the elements it allows, and every background allows a non-bender.

Airbending is now open to players through two Air Nomad backgrounds:
- **Air Nomad Wanderer:** starts at the Southern Air Temple.
- **Temple Courier:** starts at the Eastern Air Temple, with Citizen standing.

An Air Nomad who commits cruelty also loses standing with the temples (one third of the infamy gained).

**The Avatar is never the player:**
- `GameState.create_player` asserts that the player's bend is one of the five.
- The bend `"avatar"` exists only on the Avatar's battle unit and on the young Avatar while they travel with the player as a student.

## 2. Eras and life stages

The design brief asks that the Avatar's involvement be governed mostly by their stage of life, with childhood and old age the least involved. The game therefore offers four eras. Each fixes the Avatar's age when the game begins, and the Avatar ages one year every 360 days.

| Era | Mode | The Avatar | Age at start | Home |
|---|---|---|---|---|
| The Quiet Years | Story (*The Drowned Testament*) | A child; name and nation hidden until 16 | 10 | Generated per game |
| The Young Avatar | Sandbox | Siku, Southern Water Tribe, she/her | 16 | Whaletail Island |
| The Avatar's Prime | Sandbox | Lei Shan, Earth Kingdom, he/him | 38 | Jade Terraces |
| The Elder Avatar | Sandbox | Akane, Fire Nation, she/her | 84 | Boiling Lake Hamlet |

**Stage of life follows age:**
- child: under 16, or not yet told;
- young: 16–20;
- prime: 21–69;
- elder: 70 and over.

**The Quiet Years child ages too.** If a story-campaign game reaches its sixth year, the child is told on their sixteenth birthday and the Quiet Years end. If the player gave the logbook to Abbess Tsering ("The Truth Kept"), the new Avatar is handed it.

**Lore reconciliation.** `docs/02_writers_room.md` §6.2 originally locked the Avatar as unknown. It now carries a revision:
- The story campaign keeps the child unknown and out of reach.
- The sandbox eras exist to show the Avatar's adult and elder involvement.
- **Era-aware text:** tavern rumours, abbots' answers, pilgrims' lines, and Fire Lord Haoren's and Admiral Kuro's biographies change by era, so that no sandbox era mentions a drowning that did not happen there.
- **The calendar** reads "Quiet Year 11" or "Year 23 of Avatar Lei Shan".

### 2.1 Involvement by stage

`INVOLVEMENT` sets, for each stage, a multiplier on the daily chance of acting on each motive, and the share of time spent beyond reach.

| Stage | Ruler | Tyrant | Teacher | Local | Time in the Spirit World |
|---|---|---|---|---|---|
| Child | 0 | 0 | 0 | 0 | always |
| Young | 0.6 | 0.7 | 1.0 | 0.8 | 45% |
| Prime | 1.0 | 1.0 | 0 | 1.0 | 35% |
| Elder | 0.35 | 0.6 | 0 | 0.25 | 70% |

Arrival delays also lengthen at the ends of life:
- a court visit takes 10 days for a young Avatar, 5 in prime and 18 in old age;
- gathering allies against a tyrant takes 18, 12 and 24 days.

### 2.2 Hard to find

The Avatar is not a map party.

**Whereabouts:**
- **Spirit World:** the Avatar is out of reach for 3–10 days at a time (6–20 when elderly).
- **Visits:** otherwise they visit one settlement for 2–5 days.
- **Choosing a visit:** sieges add 5 to a settlement's weight and war adds 1. Temples add 2 (5 when elderly) and home adds 2 (6 when elderly).

**Sightings:**
- Reports reach the player one or two days late, and 30% of them never reach the player at all. The Avatar has usually moved on by the time the player hears.
- The Avatar window lists the last four sightings.

**Audiences:**
- **Chance:** a player at a settlement where the Avatar is present may seek an audience once a day. The chance is 25%, plus renown/1000, plus 8% per standing rank, plus attitude/200, plus 30% for a ruler, clamped to 5–95%.
- **Refusal:** failure produces one of three refusals ("in meditation", "called away", "already left by a door nobody else knows about").

**While visiting, the Avatar acts on the world.** These rolls are made per visit:

| Act | Young | Prime | Elder |
|---|---|---|---|
| Lift an AI siege (never the player's) | 35% | 60% | 25% |
| Broker a truce between kingdoms at war | 3% | 7% | 4% |

A brokered truce needs a war that has already run 60 days, and the Avatar brokers at most one every 90 days. The first tuning (6%, 15% and 8% per visit, with no limits) ended every war on the map by day 220 in bot runs.

## 3. The four reasons the Avatar comes

Every rule is shown to the player as a bar in the Avatar window (Nations → The Avatar, or Camp). Nothing is a hidden roll except the daily chance to act.

| Motive | Condition | What happens |
|---|---|---|
| **Ruler** (power used well) | A ruler's title, or influence ≥ 12, with infamy below 150 | The Avatar comes to court once ("The Avatar Comes to Court") |
| **Tyrant** (power used cruelly) | Great power and infamy ≥ 150 | A warning first; if defied or broken, a reckoning with allies |
| **Teacher** | The Avatar is young, needs the player's element next in the cycle, and the player is in the top 1% | The young Avatar asks to be taught |
| **Local cruelty** | ≥ 60 infamy within 120 map units in 45 days, and the Avatar is visiting within 220 units | The Avatar blocks the road |

### 3.1 Ruler

**Titles.** The title comes from holding a kingdom's capital in your own name:

| Capital | Title |
|---|---|
| Caldera | Fire Lord |
| Ba Sing Se | Earth King, Earth Queen or Earth Monarch, by pronouns |
| Omashu | King, Queen or Monarch of Omashu |
| Agna Qel'a | Chief of the Northern Water Tribe |
| Wolf's Crown | Chief of the Southern Water Tribe |

**Influence** is fiefs (town 3, castle 2, village 1) + renown/100 + troops/60, plus 10 for a ruler's title and 1 for vassalage.

**The court scene** offers three answers:
- **Open roads and granaries to refugees:** attitude +30, +5 with every kingdom and +10 with the Air Nomads.
- **Ask for peace:** the Avatar brokers a truce.
- **Ask the Avatar to stay out:** attitude −5, and the Avatar promises to "come to you before I go around you".

Thereafter an Avatar who trusts you (attitude ≥ 20) brokers a truce on request at most once every 120 days.

### 3.2 Tyrant

**Infamy is the world's memory of cruelty.** It fades by 1 every two days, or 2 if the player has pledged to the Avatar.

| Act | Infamy |
|---|---|
| Raiding a village | +25 |
| Executing a captive lord (new; kings cannot be executed) | +60 |
| Scorching an enemy village's fields with firebending (new) | +30 |
| Selling the refugees' mountain road to Wan Shi Tong | +40 |
| Turning Dawa in | +10 |
| Breaking the jade strike | +15 |
| Breaking the Jade Terraces dam | +10 |
| Taking a hostage | +80 |
| Raiding the Avatar's home | +60 |
| Holding a hostage against the Avatar | +40 |
| Defeating the Avatar | +40 |

**The sequence:**
1. **Warning.** The Avatar arrives before dawn at the player's cold fire.
2. **The player answers.**
   - Pledging records the current infamy. The Avatar stays away unless infamy rises 40 above it.
   - Defying, or breaking the pledge, starts a gathering. The log announces it, a monk delivers a note, and the Avatar window counts down the days.
3. **Arrival.** The Avatar's company appears beside the player.
   - **Company:** the Avatar plus stage-specific allies (monks and warriors when young; masters, earthbenders, waterbenders and Kyoshi Warriors in prime; Kyoshi Warriors, masters and firebenders when elderly).
   - **Scaling:** the company scales with the defenders (party plus garrison at the seat, ÷35, clamped 0.6–5). It grows a further 30% for every previous defeat.

### 3.3 Countermeasures

The player may prepare against a hostile Avatar, through physical means or personal ones. Fortifications and traps count only when the confrontation happens within 20 map units of the seat where they were built; there it becomes a siege-defence battle with the walls and garrison.

| Measure | Cost | Effect |
|---|---|---|
| Fortify a seat (×3) | 1,200 + 600 per level | Each level: Avatar bending power −6% |
| Spirit-wards and chi-blocker nets (×3) | 900 + 450 per level | Each level: Avatar health −12%, bending blocked for 4 s at the start |
| Hire 6 chi-blockers | 900 | Their strikes stop a bender bending for 8 s (new troop) |
| Spies | 800 | Reveals whom the Avatar loves and where |
| Take a hostage | at the Avatar's home, after spies | +80 infamy; heavy companion disapproval; offers a hostage choice at the confrontation |
| Stage a diversion | 20 troops detached, 600 gold | When the Avatar comes, the detachment raids their home (+60 infamy). The Avatar turns back for 16–24 days and returns demoralised (health −15%) |
| Yield | — | Half the confiscation of a defeat; fiefs returned |

**Using the hostage** forces the Avatar to withdraw for 45 days ("You've made sure I will never, ever stop"). The hostage is rescued at 3% per day, after which the Avatar's attitude falls to −60 or lower.

### 3.4 Outcomes

The Avatar is never killed. In battle they rotate through every element they have mastered.

| Stage | Health | Bending power | Elements | Avatar State |
|---|---|---|---|---|
| Young | 380 | 2.2 | Their native element plus those learned | Only 50% of the time (not yet controlled) |
| Prime | 650 | 3.2 | All four | Yes |
| Elder | 480 | 2.9 | All four | Yes |

All three stages have armour 20.

**The Avatar State** triggers once, below 35% health, and lasts 10 seconds:
- the Avatar recovers 25% of their health and takes 40% damage;
- their bending power rises 1.5×, with no chi cost;
- a 7 m shockwave knocks back everyone nearby.

**If the player wins:**
- the Avatar is carried off and withdraws for 70, 90 or 140 days (young, prime, elder);
- the player gains +60 renown and +40 infamy, and loses 15 with every kingdom;
- the Avatar will return stronger.

**If the player loses, or yields:**
- every fief returns to its original kingdom with a fresh garrison;
- captive lords are freed;
- half the treasury goes to the villages (a quarter if the player yielded);
- infamy is wiped, and the player sits in a cell for three days;
- the Avatar keeps watching, with a pledge recorded.

### 3.5 Teacher

**Who qualifies.** A young Avatar learns the remaining elements in cycle order from their native one (Siku: earth, then fire, then air). Each takes 200–260 days with some other teacher. The player is asked only if they are in the top 1% of benders of the element the Avatar needs next.

**Mastery percentile** is `100·(1 − e^(−score/34))`, where score is the sum of:
- bending skill × 6;
- level, capped at 40;
- 1 per 20 form uses, capped at 15;
- duel wins × 3, capped at 15;
- 4 per expansion technique;
- 20 for a master title.

In practice the top 1% requires the expansion's master title on top of near-maximum skill. A test character with bending 10, level 30, six or seven techniques and three duel wins sits at 97.3–97.6% until they earn the title.

**Accepting.** The Avatar travels with the player as a student-companion for 40 days. They fight beside the player with every element they know and help with camp work. Then they master the element and leave:
- the player gains +80 renown, +8 with every kingdom and +15 with the Air Nomads;
- the flag `taught_avatar_<element>` is set: "When the next Avatar asks who taught me, I'm going to make sure they know."

## 4. The element expansions

### 4.1 Structure

The four expansions share one structure:
- **Registry.** `scripts/dlc/registry.gd` lists each expansion's story file and companion.
- **Tagging.** Techniques, Forms movements, jobs, story triggers and settlement options carry their element.
- **Switching off.** Each expansion can be switched off in Settings. Its techniques, movements, jobs, quests and companion then disappear from offers. Saved progress is kept and returns when the expansion is switched back on.

**Each expansion adds:**
- **Techniques:** a catalogue in three or four styles, each style grounded in a real martial basis. The catalogue is learned from teachers in the world and set on Q, E or R under Character → Techniques.
- **Forms movements:** four new movements per element for the Bending Forms designer, named for real techniques and unlocked by the matching technique.
- **Non-combat bending:** six or seven jobs ("Bending at work") in settlements and around camp. Any companion who bends the element can do them, so non-benders benefit too.
- **People and stories:** a companion with a talk hub, a personal quest, teachable techniques and (where written) a romance; two or three new people; a mastery trial that grants the element's master title.

**New battle kinds and effects:**
- **dash:** travel through the line, striking everyone on the path;
- **buff:** a timed stance: power, chi regeneration, armour, damage reduction, knockback immunity, sight;
- **nova:** a ring, optionally pulling enemies inward;
- **line:** a ground fissure that stuns and launches;
- **effects:** freeze (stunned in ice), root (held in place), and cure (on heals).

Companions arrive with signature techniques. Battle AI understands every new kind.

### 4.2 Embers of the First Flame (fire)

*"Fire is breath before it is anything else."*

| Style | Martial basis | Techniques |
|---|---|---|
| Sage Breath | Northern Shaolin qigong | Breath of Fire (cone, burns), Inner Flame (buff: power ×1.35, chi regen ×2, 10 s) |
| Duellist's Line | Long Fist | Fire Whip (10 m lash), Fire Daggers (three-blade volley) |
| Jet and Flare | Northern Shaolin kicks and leaps | Fire Jets (9 m dash), Ring of Fire (nova) |

**Forms movements:** Whipping Palm (Bian Zhang); Furnace Breath (Lian Qi, a held breath); Tornado Kick (Xuanfeng Jiao); Dragon Swings Its Tail.

**Work, "Hearth and Forge":**
- **Temper a weapon:** +12% damage on that weapon.
- **Fire the potters' kilns:** porcelain, a new trade good.
- **Warm the camp:** in the cold, morale +15.
- **Cook for the column:** halves food use for two days.
- **Controlled burn:** village prosperity +8.
- **Light the festival lanterns:** at night; relation, renown and morale.
- **Scorch an enemy village's fields:** the one deliberately cruel job, +30 infamy.

**People:**
- **Master Sayuri Ono** (companion), 54. A retired Agni Kai champion with chronic pain from a lightning wound, and a widow (her late wife Haruko was a Fire Sage archivist). Romance open to she/her and they/them players.
- **Kazan of the Cinder Monastery.** A former artillery commander from the siege of Gaipan who now rakes cinders on a dormant volcano. The Cinder Monastery is a new location.
- **Mistress Tomoe Ikari** of Fire Fountain City's duelling hall.

**Stories:**
- **"The Last Student."** Sayuri's former pupil, Commander Daisuke Ren, makes farmers' sons kneel in the surf after Agni Kai. There are four resolutions:
  - beat him without burning him (a real Agni Kai);
  - let Sayuri win without throwing a flame;
  - talk him down (renown 150);
  - report him to the Fire Lord (Gentry), which stops him but teaches him nothing.
- **"The First Flame"** (mastery trial; Bending 7, three fire techniques, two duels won):
  1. carry an ember of a 900-year-old flame to the Fire Sages within nine days, without using fire in anger (any infamy gained puts it out);
  2. light Kazan's lamp. A precise jab cracks it; waiting leaves it cold; only breath lights it.
- **"The Comet Forge."** During a natural comet, forge sky-iron into a Comet-Forged Dao, or let the monks make a bell.

**Writers' room constraint (§6.3).** The trial honours the original series' teaching that fire comes from breath, without copying the Sun Warrior scene. There are no dragons and no ancient city; the lesson comes from a monastery and a lamp.

### 4.3 The Turning Tide (water)

*"Water remembers every shape it has held."*

| Style | Martial basis | Techniques |
|---|---|---|
| Northern Ice School | Yang-style Tai Chi | Ice Lance (piercing), Ice Prison (freeze) |
| Southern Tide Style | Chen-style Tai Chi (fa jin) | Octopus Form (nova), Tidal Surge (wide cone, heavy knockback) |
| Swamp and Mist | Tai Chi walking and rooting | Vine Snare (root), Mist Veil (blinding cone) |
| Healer's Path | Push-hands sensitivity | Chi-Path Healing (heals 50% and cures) |

**Forms movements:** Grasp the Sparrow's Tail; Needle at the Sea Bottom; Fan Through the Back; Snake Creeps Down.

**Work, "Tide and Spring":**
- **Healing house:** gold and relation.
- **Irrigation:** prosperity.
- **Bend the shoals:** fish.
- **Draw clean water:** in dry or poor villages.
- **Ice roads:** +25% travel speed for two days.
- **Carve ice for the children:** in the cold.

**People:**
- **Huan of the Foggy Swamp** (companion). A large, gentle swampbender who finds crowds unbearable and trees easy; ace and aromantic, and says so plainly when asked. He has no romance by design.
- **Master Yura** of Wolf's Crown. Master Aklaq's rival and only real friend for sixty years.
- **Governor Lu** of the Jade Terraces.
- **Kaya**, Nima's daughter, who appears in the trial if the Law of the Two Paths has changed.

**Stories:**
- **"The Banyan's Fever."** The swamp's great banyan is thirsty because a new dam feeds a hundred families on the Jade Terraces. There are three resolutions:
  - break the dam: the swamp lives and the terraces fail;
  - share the water three days in seven: needs Trade 3 or 800 gold;
  - ask the river: an earthbender in the party opens a spring, and both places prosper.
- **"The Red Moon."** During a lunar eclipse a waterbender learns that the water was never theirs to command (+1 skill point).
- **"The Moon's Road"** (mastery trial; Bending 7, three water techniques, a duel won): walk the last stretch to the Moon Fishery on self-made ice on a full-moon night.

**The Law of the Two Paths and pronouns.** Teaching is never gated on pronouns: creation promises that pronouns open and close no doors except romance. Outsiders train on the outer ice with Aklaq, and healing is taught by Elder Pana.

### 4.4 Roots of the Mountain (earth)

*"Listen to the ground before you move it."*

| Style | Martial basis | Techniques |
|---|---|---|
| Badgermole Way | Hung Gar stance work | Seismic Sense (buff: power ×1.25, cannot be blinded), Fissure (line) |
| Stone Hand (the Dai Li's) | Southern Mantis short strikes | Stone Gloves (two-rock volley), Stone Cuffs (root) |
| Boulder Style (Omashu) | Hung Gar tiger forms | Boulder Toss (40 damage, huge knockback), Stone Armour (buff: armour +25, speed ×0.8, knockback immune) |

**Forms movements:** Iron Bridge (Tit Kiu); Double Tiger Claws (Seung Fu Jaau); Butterfly Palms (Wu Dip Jeung); Listening Horse.

**Work, "Stone and Root":**
- **Work a seam:** iron or jade.
- **Raise stone walls:** your own fiefs; +15% walls per raising, up to +60%, used by sieges.
- **Cut terraces:** prosperity.
- **Level the road:** +15% travel speed for three days.
- **Raise shelters for refugees.**
- **Shore up old mine tunnels.**

**People:**
- **Gao Ming** (companion), 40. A jade miner and union organiser from the Lower Ring, a bisexual widower raising twelve-year-old Lian. Romance open to every pronoun.
- **Madam Cheng Lu** of Gaoling. The Cheng family is the creditor named in the Wandering Merchant background.
- **Old Shan of Stonewatch Pass**, who learned from lying under a mountain for two days.
- **Master Bo Ren** of Omashu's boulder school.
- **Bo Lai**, from Hana's quest, teaches the Stone Hand only if Hana spared him: "Use it to hold people, never to bury them." Otherwise the Dai Li academy teaches it for 1,200 gold, at Gentry standing, unless the Dai Li are your enemy. Hana and Gao Ming disapprove.

**Stories:**
- **"The Jade Seam."** A strike after six deaths and a wage cut. There are four resolutions:
  - shore up the seam with earthbending, then negotiate;
  - pay the repairs;
  - stand with a six-week strike;
  - break the strike: +1,500 gold and +15 infamy, and Gao Ming leaves.
- **"Cave-in."** A random roadside rescue near Earth Kingdom land.
- **"The Badgermole's Patience"** (mastery trial; Bending 7, three earth techniques including Seismic Sense, a duel won): sit three days without bending, then say what the mountain said. "Move me" fails, because that was you talking.

### 4.5 The Thirty-Six Winds (air)

*"Freedom is a discipline."*

| Style | Martial basis | Techniques |
|---|---|---|
| Northern Glide | Baguazhang leaping palms | Glider Strike (12 m dash), Updraft (lift and stun) |
| Southern Play | Baguazhang circle walking | Air Ball (cheap, huge knockback), Air Shield (buff: −70% damage, knockback immune) |
| Eastern Stillness | Standing meditation | Healing Breath (small heal, cures) |
| Western Wind-Shaping | Baguazhang palm changes | Vortex (pulling nova), Wind Blade (fast piercing edge, "taught reluctantly") |

**Forms movements:** Swimming Body (You Shen); Lion Opens Its Mouth; Yellow Dragon Turns Over; Standing Like a Post (Zhan Zhuang).

**Work, "Wind and Wing":**
- **Glide ahead and scout:** reports hostile parties within a day's march; +20% speed.
- **Fill the merchants' sails:** at coastal settlements.
- **Turn the mill-stones:** prosperity and rice.
- **Smother the fires:** restores a raided village.
- **Meditate on the wind:** max chi +20% for three days; +5 uses to every form.
- **Fly by sky bison between temples:** needs Air Nomad relation 20.

**People:**
- **Yangzom** (companion), 23. A Western Temple nun charting the Thirty-Six Winds, the Nomads' unfinished map of the world's air. She keeps the vow and fights nonlethally. Romance open to every pronoun.
- **The abbots now speak:** Dorje, Lhakpa and Yeshe, alongside Tsering.
- **Captain Mako**, a bison smuggler.

**Stories:**
- **"The Lost Herd."** Six stolen bison calves at Full Moon Bay, bound to be beaten into Fire Navy war mounts. There are three resolutions:
  - buy them back;
  - let Reika call in a debt;
  - fight the smugglers, nonlethally by Yangzom's request.

  The calves remember how to fly, and Abbess Yeshe gives Yangzom the temple's map to finish.
- **"The Thirty-Six Winds"** (mastery trial; Bending 7). One test at each temple:
  - **Southern:** kindness;
  - **Northern:** a glide through three winds, which requires Glider Strike;
  - **Eastern:** two days of stillness, including a bowl of soup;
  - **Western:** hold water in a cup of air, which requires three air techniques.

  Then the four abbots tattoo the arrows. An Airbending Master's look now shows them.

## 5. Verification

| Test | Covers | Result |
|---|---|---|
| `tests/test_avatar.tscn` | All 19 background/element combinations; four eras (stage, sightings, Spirit World share, the prologue only in the Quiet Years); ruler court and brokered peace; tyrant warning → defiance → gathering → arrival → yield; diversion and hostage; judgement after a lost battle and withdrawal after a won one; local intervention near and far; the teacher path from top-1% check to taught element; the Quiet Years child revealed at 16 with the kept logbook | 0 errors |
| `tests/test_battle.tscn -- avatar young\|prime\|elder` | The Avatar's company against a fortified, trapped seat | Young: water only, Avatar State triggered, player won. Prime: all four elements, Avatar won. Elder: all four elements (air 16, earth 16, water 8, fire 2 casts), Avatar State, player won |
| `tests/test_dlc.tscn` | Every technique taught by someone (26 of 26); every Forms movement unlocks; each mastery trial; each companion quest (cooperative and cruel branches); the ember goes out after cruelty; the comet forge; the Red Moon; all 25 jobs done somewhere with their effects checked and cooldowns enforced; a companion doing a non-bender's work; switching an expansion off and on | 0 errors |
| `tests/test_battle.tscn -- tech <element>` | Every technique cast in a live battle, cycled through Q, E and R | All 26 cast; no script errors |
| `tests/test_story.tscn` | 138 dialogues, 576 nodes, 25 triggers, 49 options validated, including technique ids, items and call conditions | 0 errors |
| `tests/test_personas.tscn` | Eleven bots across all four eras (1,980 bot days) | 0 invariant issues. The run found that a young or prime Avatar ended every war on the map by day 220; truce-brokering was tuned (see `docs/08_sequel_release.md` §2.3) |

## 6. Known limits

- **Animations.** New techniques reuse the existing motion clips with procedural stance layers. The dash, nova and line kinds have particle and ring effects, not bespoke animation.
- **Abbots and new teachers** use the generated face rig and kit system, not authored faces.
- **The Avatar** has no map token, by design. They are found through rumour and the settlement menu, not seen walking.
- **Infamy** knows only the acts listed in §3.2. Sacking captured towns is not an action in this build.
