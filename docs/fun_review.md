# Fun review

A focused review of whether the game is fun, held against what it is trying to be: a Mount & Blade sandbox in the world of the original series, where a nobody becomes somebody through fighting, trade, politics and bending. It draws on the 300-day simulation runs, the bot runs, the screenshots taken this session and a reading of the systems' code. Findings are ranked by how much they cost the player's fun. Each says what was changed in this pass, or what is proposed.

## What already works

**Bending is the best thing in the game.** Composed forms give each bender a fighting style the player built. Since this pass, bending also changes the field it is used on: stone walls and pillars stay up and become cover, fire runs through dry grass downwind, water leaves people wet so lightning runs through a soaked squad, and wind fans or snuffs flames. Fights now have terrain that the fighters themselves make.

**The political sandbox has depth.** Forty-seven factions are bound by tribute and protection. The Fire Islands drift toward unification, communities change hands and rise again, and the Water Tribes elect a High Chief. In 300-day runs the world produced its own stories: Beishan seizing Baiyun, Wolf's Crown swallowing the Whalebone Raiders, the Aqsarniit answering a call to arms. Nobody touched the Sun Warriors.

## Problems, ranked

### 1. A sandbox with no direction (fixed)
The campaign is gone by decision, and nothing replaced its job of telling a new player what to aim for. The first hour had no hook beyond wandering and fighting bandits.

**Done.** Ambitions (`scripts/core/ambitions.gd`) are eighteen goals in three tiers:
- tier one: first blood, ten swords, a merchant's purse, and the like;
- tier two: a hall of your own, protector of a community, ten battles won;
- tier three: Lord of Walls, five tributaries, elected High Chief, guest of the dragons.

The Quest Log shows the current tier and the next, with progress counts. Each completed ambition gives renown and gold, and the later ones give attribute points. The ambitions point at the systems that are most fun once found (forms, tribute, the Moon Council, the Sun Warriors).

### 2. The world drowned the player in news (fixed)
With forty-seven factions the message log filled with battles, sieges and treaties from the other side of the map. The events that mattered to the player scrolled past unread.

**Done.** World news now goes to a chronicle, listed under Wars and Tribute in the Factions menu. The message log only shows news that concerns the player:
- events within a few days' march;
- events involving the player's own faction or their enemies;
- events involving their tributaries, or factions that think strongly of them either way.

### 3. The world resolved itself too fast (tuned)
Every power could start a campaign almost daily, so the Royal House absorbed two clans within eight months, before a player could matter.

**Done.** The campaign rate is about halved, and armies rest twenty-five days after each campaign. Wars are still declared between neighbours by their rulers' temperament.

### 4. Too few levers on the politics (proposed)
The player can declare war, offer peace, demand tribute, release tributaries, lobby electors and stand for High Chief. They cannot make alliances, broker peace between two powers, marry into a house, sign a contract for one specific campaign, or incite a tributary to break away. These are the levers that turn watching the politics into playing them.

**Proposal.** Add contracts and envoys:
- a lord at war offers a paid contract for one campaign;
- envoys to a power can propose alliance, non-aggression or a marriage tie;
- envoys to a tributary can encourage it to stop paying.

### 5. The sea is walkable (proposed)
Parties cross open sea at 70% speed. That makes the new geography (island clans, the Strait Isles, island tribes, the polar shelves) strategically flat: an army walks from Caldera to the mainland.

**Proposal.** Parties may only cross water from a harbour, by hiring passage or owning boats. Raiders (Whalebone, Fire Navy) move faster at sea. Islands and coasts then matter.

### 6. Settlements look alike (partly addressed)
The 18 settlement screenshots show that region identity reads well: roofs, ice domes and stilt houses each distinguish a culture. But capitals use the same plan as ordinary towns (Ba Sing Se looks like Gaoling), and the Sun Warriors' city uses Fire Nation architecture.

**Done.** Wealth tiers: poor places have ruins, empty stalls, mud, grime, beggars and dark lanterns; rich places have taller houses, stocked stalls, gardens, more lanterns and crowds.

**Proposal.**
- Landmark plans for each capital: Ba Sing Se's rings, Omashu's chutes and stairs, Caldera's crater terraces, Agna Qel'a's canals.
- A stepped stone city for the Sun Warriors.
- Island villages on beaches rather than on swamp grass.

### 7. Commanding troops from 1.5 metres (proposed)
The close camera suits duels and bending. It hides the shape of a battle the player is meant to command, and orders are limited to F1–F3.

**Proposal.**
- A held key pulls the camera up to a tactical view, with orders to groups (archers, benders, infantry) and a formation choice.

### 8. Characters were hard to read (fixed)
Heavy PS1 vertex snapping turned characters into eight-pixel staircases at mid range, which made fights harder to follow.

**Done.**
- Characters now snap to a grid 2.5 times finer than the world's.
- They also use their normal maps and a top-down shading term.

### 9. The early game is generous and safe (measured; proposed)
A bot that hunts only weaker outlaws and takes guild work reached, by day 90:
- 3,763 gold;
- a party of 32;
- level 7 and 252 renown;
- 22 battles won and none lost;
- 11 quests done.

Its caution flatters the record, but the curve is too smooth for a game about rising from nothing. Gold piles up with nothing to spend it on, and the ambition rewards add renown on top of an already fast climb.

**Proposals.**
- Outlaw bands that grow with the player's renown and sometimes ambush.
- Upkeep that scales with party size and fiefs.
- Ambition rewards that tilt toward things (an attribute point, a unique item, a companion's interest) rather than renown.
- Gold sinks with a visible payoff: rebuilding a poor village's houses, bending work, bribing electors.

## Not yet measured

**Moment-to-moment combat.** Hit feedback, enemy variety and the bending duel's rhythm can only be judged by playing with a mouse in hand. They are the most important thing for a person to test next.
