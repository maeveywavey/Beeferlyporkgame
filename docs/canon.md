# Canon reference

This file is the authority for every lore question in the project. Content that contradicts it is a bug, whatever the reason the content was written.

**Project rule.** The needs of story or gameplay never override a canon rule. When a design needs something canon forbids, the design changes and a workaround is found inside the rules. Section 9 records the workarounds currently in the game.

**Where it is enforced.** `tests/test_canon.gd` enforces the mechanical rules: forbidden names, eras, the cycle, the comet, eclipses and the Avatar's whereabouts. The rest relies on review against this file.

## 1. Sources

| Tier | What | Use |
|---|---|---|
| **1. Binding** | *Avatar: The Last Airbender*, the animated series (2005–2008), all 61 episodes | Always wins |
| **2. Supporting** | Official material in the original series' continuity that does not depend on *The Legend of Korra*: creators' DVD commentaries, *Avatar Extras*, *The Lost Scrolls*, the *Escape from the Spirit World* online comics | Only where tier 1 is silent; never against tier 1 |
| **Excluded** | *The Legend of Korra* and everything derived from it: Wan and Raava, Vaatu, Harmonic Convergence, spirit portals, physical travel into the Spirit World, Yakone and later bloodbenders, lavabending by ordinary benders, metalbending's later spread. Also excluded: the *Chronicles of the Avatar* novels (Kyoshi, Yangchen, Roku), which are written inside the post-Korra continuity; the *Avatar Legends* roleplaying game; the 2010 film; the 2024 live-action series | Never cited, never used |

Episode references use book and episode numbers; for example, "2×05 *Avatar Day*" is Book 2, episode 5. The research behind this file used the Avatar Wiki's episode citations, read through its API, and kept only claims that the wiki sources to a tier-1 or tier-2 work.

## 2. When the game is set

- The game is set at an **unnamed time long before Aang, and before Yangchen**. The series gives the order of Aang's four most recent past lives as Yangchen (Air), Kuruk (Water), Kyoshi (Earth) and Roku (Fire) (3×19 *Sozin's Comet, Part 2*). No invented Avatar may fall between Yangchen and Aang.
- All Avatars in the game are original and precede Yangchen. The Avatar immediately before Yangchen must be a firebender (section 3). No era in the game claims to be that Avatar, so no era is pinned to a date.
- **Nothing that the series dates later may appear.** The table below lists what is excluded and why.

| Excluded | Why |
|---|---|
| Kyoshi Island as an island | Kyoshi separated the Yokoya peninsula from the mainland to protect it from Chin the Conqueror: "I created Kyoshi Island so my people could be safe from invaders" (2×05 *Avatar Day*). Before Kyoshi it is a peninsula. The game uses its own name for it. |
| The Kyoshi Warriors | Founded by Kyoshi (2×16 *Appa's Lost Days*; 1×04 *The Warriors of Kyoshi*) |
| The Dai Li | Ba Sing Se's "cultural authority" (2×14 *City of Walls and Secrets*), founded by Kyoshi (tier 2, *Escape from the Spirit World*) |
| Chin Village, Avatar Day | Named after Chin the Conqueror, Kyoshi's enemy (2×05) |
| Roku's shrine on Crescent Island | Built for Roku (1×08). The Fire Temple itself is ancient and may appear. |
| Ruins of Taku | Taku was a trading city destroyed early in the Hundred Year War (1×13 *The Blue Spirit*). Before Aang it is a living city, not a ruin. |
| Pohuai Stronghold, Fire Nation colonies, Fire Nation forts on the Earth Kingdom mainland | Colonisation of the mainland begins with Sozin (3×06 *The Avatar and the Fire Lord*) |
| The Hundred Year War; "Sozin's Comet" by that name | Both begin with Sozin. The comet was formerly called the **Great Comet** (3×06). |
| The Boiling Rock as a prison | Shown only as the Fire Nation's war-era maximum-security prison (3×14). The boiling lake is natural and may appear; the prison may not. |
| Bloodbending | Invented by Hama in a Fire Nation prison during the war (3×08 *The Puppetmaster*) |
| Metalbending | "Long regarded an impossible feat" until Toph (2×09 *The Chase*; 2×19 *The Guru*) |
| The air scooter | Shown as Aang's own trick (1×12 *The Storm*) and credited to him in later official material. Excluded as a named technique. |
| Iroh, the White Lotus as Iroh's order, Joo Dee, Long Feng, Lake Laogai as the Dai Li's base, Earth Rumble, the Ember Island Players | All belong to Aang's lifetime |

## 3. The Avatar

- **The cycle.** The Avatar is reborn into the next nation of the cycle: fire, air, water, earth (series-wide; Roku, a firebender, is followed by Aang, an Air Nomad). The game enforces this in `scripts/core/avatar.gd` (`CYCLE`).
- **Order of learning.** The Avatar learns their birth element first, then the others in cycle order. Aang, an Air Nomad, learns water, then earth, then fire (series-wide). Roku learns air, then water, then earth (3×06).
- **When they are told.** The Avatar is normally told at sixteen; Aang was told early because "storm clouds were gathering" (1×12 *The Storm*). Roku was told on his sixteenth birthday (3×06).
- **Air Nomad identification.** Air Nomads test a child by having them choose the Avatar relics from thousands of toys (1×12).
- **Masters.** The Avatar travels to learn each element from masters of that element. Roku spent twelve years doing so (3×06).
- **The Avatar State** is a defence mechanism: "designed to empower you with the skills and knowledge of all the past Avatars" (2×01 *The Avatar State*).
  - **Mortal danger.** An untrained Avatar enters it involuntarily when in mortal danger or under extreme emotion (2×01). Aang entered it when drowning in a storm, which froze him in the iceberg (1×12), when he learned of Gyatso's death (1×03), and when Katara was in danger (2×01).
  - **Death in it ends the cycle.** "If you are killed in the Avatar State, the reincarnation cycle will be broken, and the Avatar will cease to exist" (2×01).
  - **It can be blocked.** Aang lost access after Azula's lightning blocked his seventh chakra (2×20, 3×01). He regained it when the scar was struck (3×21; creators' commentary, tier 2).
  - **It exhausts.** An Avatar leaving it involuntarily is spent (series-wide).
- **Death.** Avatars die. Roku died at Crescent Island when the volcano erupted (1×08, 3×06). An Avatar can die at sea only if both of the following hold:
  - the Avatar State was unavailable or exhausted;
  - the death happened outside the Avatar State, or the cycle would have ended.
- **The last Avatar in this game** died at sea. They were exhausted from holding the sea off the crew's boats, and their seventh chakra was blocked by poison taken days before. The player is never told this outright; the logbook only hints at it (section 9).
- **The Spirit World.** The Avatar is the bridge between the worlds (1×07). The Avatar's spirit may leave the body in meditation, leaving the body defenceless (1×07 *Winter Solstice, Part 1*). These visits are brief and infrequent, measured in hours.
  - **Physical crossing.** Physical crossing is excluded (Korra-only).
  - **Not modelled.** The game does not model or mention Spirit World visits. When the Avatar is out of reach, they are somewhere in the physical world: travelling, at a temple, attending to spirits at places in this world such as Senlin's forest (1×07) or the Spirit Oasis (1×19).
- **Past lives.** The Avatar can speak with past lives through meditation and at places tied to them (1×08, 2×19, 3×19).
- **Who the Avatar stops.** The Avatar opposes those who would conquer: Roku confronted Sozin over the colonies (3×06), and Kyoshi stopped Chin (2×05). The game's "tyrant" motive is built on these two precedents.

## 4. Bending

### General
- **Origins.** Each art was learned from a teacher in nature: airbending from the sky bison, earthbending from the badgermoles, firebending from the dragons, waterbending from the moon (3×13 *The Firebending Masters*; 1×19).
- **Chi-blocking.** Strikes to the chi paths can block a bender's bending and disable muscles temporarily (2×03 *Return to Omashu*, Ty Lee). It is older than Aang's era (tier 2: "practised in secret for centuries"). Rare.
- **Healing.** Only waterbenders heal with bending, by redirecting energy through the body's paths (1×16 *The Deserter*; 1×18 *The Waterbending Master*). Airbenders, earthbenders and firebenders do not heal with bending.

### Water
- **The moon.** Waterbending draws on the moon: stronger at night, strongest under a full moon (1×18, 1×19).
- **Tui and La.** The Moon Spirit Tui and the Ocean Spirit La live in the Spirit Oasis. If Tui is absent, waterbenders lose their bending (1×20).
- **Lunar eclipse.** No canon effect is stated. The game gives one only: the full-moon strengthening does not apply while the moon is eclipsed.
- **The Northern Water Tribe** keeps waterbending women to healing and forbids them combat bending, until Pakku teaches Katara (1×18). The game calls this tradition the Law of the Two Paths.
- **Other arts:**
  - Swampbending and plantbending: the Foggy Swamp tribe (2×04 *The Swamp*).
  - Mist and fog (3×03 *The Painted Lady*).
  - Ice prisons and the octopus form (1×18, 1×20).
  - Spirit water from the Spirit Oasis (1×20, 2×20).
- **Forbidden:** bloodbending (section 2).

### Earth
- **Origins.** The first earthbenders were Oma and Shu, taught by the badgermoles in the Cave of Two Lovers near Omashu. Omashu is named after them (2×02 *The Cave of Two Lovers*).
- **Neutral jing.** Earthbending's principle is neutral jing: waiting and listening, then acting decisively (2×03 *Return to Omashu*).
- **Seismic sense** is learned from badgermoles; it is shown only in Toph (2×06, 3×13). In the game, it can be learned only by listening to badgermoles, not from a human.
- **Sandbending:** the Si Wong sandbenders (2×11 *The Desert*).
- **Forbidden:** metalbending. Lavabending is shown only by an Avatar in the Avatar State (2×01) and is not available to ordinary benders.

### Fire
- **Source.** Firebending draws on the sun: stronger by day, gone during a total solar eclipse (2×10 *The Library*, 3×10, 3×11). It comes from breath and inner heat (1×16; 3×13).
- **Energy and life.** The true meaning of firebending is energy and life. The idea that it is fuelled by rage is a distortion of Sozin's era (3×13). Before Sozin, the game's firebenders are taught breath, not anger.
- **Dragons and the Eternal Flame.** Dragons are the original firebenders and are common before Sozin's hunts (3×13). The Sun Warriors keep the **Eternal Flame**, "the first fire" given by the dragons (3×13). No other place holds the first fire. In the game's era the Sun Warriors are a living, outward-facing culture, not ruins.
- **Lightning.** "Cold-blooded fire" is a rare master's art (2×09 *Bitter Work*; 3×21).
- **Lightning redirection** was "independently developed" by Iroh from studying waterbenders (2×09). The game has no redirection technique.
- **The Agni Kai** is an ancient firebending duel won when one duellist burns the other (1×12). Before Sozin it was rarely fought to the death (tier 2).
- **Combustion** (third-eye) bending exists but is very rare (Book 3, Combustion Man).

### Air
- **Origins and character.** Airbending was learned from the sky bison. It is the art of evasion, flowing around force rather than against it (3×13; series-wide).
- **The four temples.** The Air Nomads live in four temples. The Southern and Northern temples house men; the Eastern and Western temples house women (1×03, 1×17, 3×12).
- **Arrows.** Arrow tattoos mark mastery (1×12).
- **Ways of life.** Air Nomads are vegetarian and avoid killing (1×03; series-wide).
- **Gliders.** Gliders are standard (series-wide).
- **Forbidden:** airbender healing; the air scooter (section 2).

## 5. The calendar of the sky

- **The Great Comet.** It passes **once every hundred years** and multiplies firebending a hundredfold while it is overhead (3×06, 3×18, 3×20). It was named Sozin's Comet only after Sozin. In the game it is the Great Comet, and it can appear at most once in a playthrough.
- **Total solar eclipses** that remove firebending are "only known to have occurred twice in recorded history". The first was "the darkest day in Fire Nation history" (2×10). They are therefore not a recurring event in the game. They are absent from all eras except as history.
- **Solstices.** The winter solstice is the time the Spirit World is closest (1×07, 1×08).

## 6. Peoples and powers

- **Harmony between nations.** Before Sozin "the four nations lived together in harmony" (opening narration). Sozin's proposal to expand "the most successful empire in history" onto the mainland is new in 3×06.
- **Conflict the game may show:**
  - wars between lords inside a nation;
  - rebellions and secessions;
  - piracy and banditry;
  - disputes over islands and waters that neither crown has ever fully held.
- **Conflict the game must not show:** a nation conquering or colonising another nation's mainland, or taking another nation's capital.
- **The Earth Kingdom**:
  - an Earth King or Queen in Ba Sing Se, behind outer and inner walls with ringed districts (2×13 *The Drill*, 2×14);
  - Omashu, an old city (1×05, 2×02);
  - Gaoling (2×06);
  - the Si Wong Desert (2×10–2×11);
  - the Foggy Swamp (2×04).
- **The Fire Nation**:
  - an island nation ruled by a Fire Lord, with the Fire Sages keeping the temples and crowning the Fire Lord (1×08);
  - Caldera City (3×01);
  - Ember Island as a place (3×05);
  - the Agni Kai.
- **The Water Tribes**:
  - the Northern Tribe's city Agna Qel'a and the Spirit Oasis (1×18–1×20);
  - the Southern Tribe (1×01).
- **The Air Nomads**: see section 4.
- **Spirits**:
  - Hei Bai (1×07);
  - Koh the Face Stealer (1×20);
  - Tui and La (1×19);
  - Wan Shi Tong, whose library stands half-buried in the Si Wong Desert and who forbids its use for war (2×10).
  - Spirits act in the physical world, and their anger has physical causes (1×07).

## 7. Places the game uses, checked

| Place | Status |
|---|---|
| Ba Sing Se, Omashu, Gaoling, Full Moon Bay, Chameleon Bay, Serpent's Pass, Misty Palms Oasis, Senlin, Makapu, Gaipan, the Foggy Swamp, the Si Wong Desert, Wan Shi Tong's Library | Ancient or undated; allowed |
| The Cave of Two Lovers | Ancient (Oma and Shu); allowed. It replaces the Ruins of Taku. |
| Caldera City, Fire Fountain City, Shu Jing, Jang Hui, Ember Island, Crescent Island (the Fire Temple only) | Allowed |
| The boiling lake | Allowed as geography. The fortress on it is **Boiling Lake Keep**, an original holding, not the war prison. |
| Agna Qel'a, the Spirit Oasis; the Southern Tribe's settlements | Allowed |
| The four Air Temples | Allowed; gendered as in section 4 |
| Kyoshi Island, Chin Village, Pohuai Stronghold, the Ruins of Taku, the Boiling Rock | Replaced; see section 9 |

## 8. What the game invents, and the limits on it

Original characters, nobles, companions and the four era Avatars are inventions, and so are the game's own institutions:
- the Censorate (section 9);
- the Hamakaze Tide Wardens (section 9);
- the Strait Isles;
- the Cinder Monastery;
- the Thirty-Six Winds (a nun's map of winds, not a canon tier system);
- the companions' personal histories.

An invention is allowed only if it contradicts nothing in tiers 1–2 and does not claim the origin of anything the series credits to someone else.

## 9. Workarounds in the game

| Need | Canon problem | Workaround |
|---|---|---|
| A world without a working Avatar (the Quiet Years) | The Avatar State saves an endangered Avatar | The last Avatar was poisoned days before sailing, which blocked the seventh chakra (as Azula's lightning blocked Aang's). In the storm they held the sea off the crew's boats until they were spent, outside the Avatar State, so the cycle continued. The crew lived; the Avatar did not. Logbook pages I, IV and V hint at the fever, at "a door where the others used to be" and at no "something older" taking over. Nobody in the game explains it. |
| An Avatar who is hard to reach | Spirit World stays are brief, and the body stays behind | The Avatar is out of reach in the physical world: travelling, at temples, at spirit-touched places, with teachers or with family. The game never mentions Spirit World visits. |
| A Fire Nation–Earth Kingdom conflict to drive the sandbox | No mainland colonies before Sozin; the four nations live in harmony | The conflict is over the **Strait Isles**, an island chain between the Fire Islands and the Earth Kingdom coast that both crowns have claimed for centuries and neither has fully held. The Earth Kingdom calls them the Sunset Isles and the Fire Nation the Dawn Isles. The Admiralty has occupied them after three failed harvests. No Fire Nation holding stands on the mainland, and no AI nation lays siege to another nation's capital. A player who conquers across nations is the tyrant the Avatar comes for. |
| A peninsula of warrior fisherfolk (the old Kyoshi Island content) | Kyoshi Island and the Kyoshi Warriors begin with Kyoshi | **Hamakaze**, a peninsula on the southwest coast, joined to the mainland. It is defended by the **Tide Wardens**, a fisherfolk militia of men and women with glaives and indigo lamellar. They have no fans, no face paint and no green-and-gold. |
| Ba Sing Se's secret police | The Dai Li begin with Kyoshi | **The Censorate**, the Grand Secretariat's earthbending censors. Their agents fight with stone fists, not the Dai Li's rock gloves. |
| A town near Gaoling on the southwest cliffs | Chin Village is named for Chin | **Tanshui Village**, the same cliffs under an older name |
| An explorable ruin near Omashu | Taku is a living city before the war | **The Cave of Two Lovers**, ancient and full of badgermoles |
| A Fire Nation fortress facing the mainland | Pohuai is a war-era fortress on the mainland | **Kettle Rock**, a fort in the Strait Isles |
| A fire-power event | Sozin's Comet is a once-a-century comet; solar eclipses were nearly unknown | The **Great Comet** can appear at most once per playthrough (about one game in three). It is announced by the Fire Sages and named as the Great Comet. Solar eclipses do not occur. |
| An air healing technique | Airbenders do not heal | Replaced by **Clearing Wind**, which blows away smoke, mist and burning embers and ends freezing and rooting effects on allies; it restores no health |
| Learning seismic sense | Shown only as learned from badgermoles | Old Shan takes the player into the Cave of Two Lovers to listen to the badgermoles themselves |
| The First Flame trial | The Sun Warriors' Eternal Flame is the first fire | The Cinder Monastery keeps a flame *lit from* the Eternal Flame, carried up the mountain by a Sun Warrior nine hundred years ago. The trial is to carry an ember of it to the Fire Sages on Crescent Island, as Aang and Zuko carried theirs in 3×13. |
