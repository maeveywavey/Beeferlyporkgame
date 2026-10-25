# Avatar: Mount & Bend

A Mount & Blade–style sandbox set in the world of *Avatar: The Last Airbender* (original series), built in **Godot 4.3**. You raise an army, trade, take quests, serve or betray kingdoms, besiege cities and fight real-time 3D battles with swords, bows and bending, all during the last year of the Hundred Year War.

Everything is generated in code from primitives: there are no art or audio files to import, and the sound effects are synthesised at startup.

## Running the game

1. Install **Godot 4.3 or newer**, the standard build rather than the .NET/C# one: <https://godotengine.org/download>.
2. Clone this repository, or download it as a ZIP and unzip it.
3. Start Godot, click **Import**, select `project.godot` in this folder, then **Import & Edit**.
4. Press **F5** (or the ▶ button) to play.

The project uses the *Compatibility* (OpenGL) renderer, so it runs on modest laptops and integrated graphics. To build a standalone executable, use **Project → Export** after installing the export templates Godot offers to download.

## Controls

### World map
| Input | Action |
|---|---|
| Left click on ground | Travel there (time runs while you move) |
| Left click on a town or party | Travel to it; arriving opens its menu or an encounter |
| Mouse wheel | Zoom |
| Right-drag | Rotate the camera |
| Middle-drag / WASD | Pan the camera (F re-centres on your party) |
| Space | Stop |
| Hold Ctrl or press `>>` | Fast travel (×4) |
| T / Esc | Camp menu (wait, save, load, settings) |
| P, C, I, J, N | Party, Character, Inventory, Quests, Nations |

### Battle
| Input | Action |
|---|---|
| WASD, Shift | Move; hold Shift to walk |
| Mouse | Look and aim |
| Left mouse | Attack. Direction follows your last mouse movement: up gives an overhead strike, down a thrust, left or right a swing |
| Right mouse | Block. Blocking is automatic by default; turn it off in Settings for Mount & Blade–style directional blocking |
| 1 / 2 | Melee weapon / ranged weapon (hold left mouse to draw, release to shoot) |
| Q / E / R | Bending abilities (benders only) |
| Space | Jump |
| F1 / F2 / F3 | Order your troops: hold position, follow me, charge |
| V, mouse wheel | Camera distance |
| Tab | Leave once the battle is won or lost; while you are knocked out, fast-forward |
| Esc | Pause menu (controls, settings, retreat) |

## How to play

### Character creation
You pick a name, appearance and one of six backgrounds. Each background sets your starting town, equipment, troops and skills. Benders choose their nation's element: the Earth Kingdom refugee and the merchant can earthbend, the Fire Nation deserter can firebend, and both Water Tribe backgrounds can waterbend. A Kyoshi trainee is always a non-bender. Non-benders keep more of their skill points for weapons. There is no airbending option, because Aang is the last airbender.

### Bending
Bending draws on **chi** (the blue bar) and improves with the **Bending** skill and Intelligence.

| Element | Q | E | R |
|---|---|---|---|
| Fire | Fire Blast | Fire Wave (cone) | Lightning (needs Bending skill 5) |
| Earth | Rock Throw | Earth Wall (blocks arrows and troops) | Earthquake (stuns nearby enemies) |
| Water | Water Whip (slows) | Healing Water (you and nearby allies) | Ice Spikes (volley) |

The world clock changes bending strength:
* **Firebending** is stronger by day and weaker at night. It disappears entirely on the **Day of Black Sun** (Summer, day 72, 100 AG, 09:00–13:00) and is tripled during **Sozin's Comet** (Summer, day 89 to Autumn, day 1, 100 AG).
* **Waterbending** is stronger at night and much stronger under a **full moon**.

The top bar shows the date and moon phase, so you can time your attacks.

### Your party
* **Recruit** volunteers in villages; recruits match the local culture (Fire Nation, Earth Kingdom, Northern or Southern Water Tribe, Kyoshi Island or Foggy Swamp). Taverns in towns sell **mercenaries**, such as Earth Kingdom swordsmen, archers and the Rough Rhinos.
* Troops gain experience in battle and can be **upgraded** in the Party screen (P), for example Peasant → Earthbender Recruit → Earthbender Soldier → Dai Li Agent, or Hunter → Waterbending Student → Waterbender → Waterbending Master or Healer.
* **Companions** wait in taverns: Haru, Jet, Longshot, Smellerbee, Song, June, Pipsqueak, Chong and Ty Lee. Each adds a skill bonus to the party. Ty Lee's strikes also block an enemy bender's chi.
* You pay wages every week. Food is consumed every day; one unit feeds ten men for a day, and eating several kinds raises morale. Low morale causes desertion.
* Prisoners taken in battle can be sold to tavern ransom brokers or recruited into your party.

### Leveling
Each level gives an attribute point and skill points (C). A skill's maximum is its governing attribute ÷ 2. Leadership raises party size, Trainer gives your troops daily experience, Healing saves wounded soldiers, and Pathfinding speeds up travel.

### The world
* **Nations:** the Fire Nation (Ozai, Azula, Zhao, Zuko, Iroh and others) is at war with the Earth Kingdom (Kuei, Bumi, Long Feng, Fong, Suki and others), the Northern Water Tribe (Arnook, Pakku, Hahn and Sangok) and the Southern Water Tribe (Hakoda, Bato and Kanna).
* Lords lead armies, chase weaker enemies, raid villages, recruit, and join their nation's **campaigns** to besiege towns and castles. Captured fiefs change hands, along with their villages.
* **Outlaws:** river pirates, mountain bandits, Fire Nation deserters and sandbenders prey on travellers. Jet's Freedom Fighters attack only the Fire Nation.
* **Team Avatar** flies around on Appa. Talk to them: Katara can heal your wounded once a week. Prince Zuko chases them across the map.
* **Economy:** every settlement has its own prices. Goods are cheap where they are produced (marked \*) and expensive elsewhere, so buying low and selling high is a valid way to fund an army.
* **Quests** come from village elders, guild masters and castle stewards: clear out bandits, deliver goods, carry letters, or bring trained troops.
* **Ruins:** explore the four Air Temples, Wan Shi Tong's Library and the Ruins of Taku once each for rewards.
* **Earth Rumble:** Gaoling's arena runs five one-on-one rounds that end with the Blind Bandit.
* **Pai Sho** in taverns, if you feel lucky.

### Serving a nation
Talk to a lord and offer your sword as a **mercenary**, which is paid weekly. With 150 renown you can pledge to a king as a **vassal**, which grants you a village; ask the king for more fiefs as your renown grows. Castles and towns you capture become yours. If you renounce your oath, you keep your lands and fight on as your own realm.

### Sieges
At an enemy town or castle, choose **Lay siege**. After 12 hours your ladders are ready and you can assault the walls yourself in a 3D battle (attack through the breach) or send your troops. If a friendly settlement is besieged, ride there and choose **Break the siege**.

### The story
The sandbox follows the show's timeline. Starting in Winter 99 AG, messages report the Avatar's return and Kyoshi Island. Admiral Zhao then sails on the North Pole, Azula plots against Ba Sing Se, and the allies invade the Fire Nation on the Day of Black Sun. Sozin's Comet follows, and finally Zuko becomes Fire Lord and declares peace. These events start real campaigns, but they do not fix the outcome: you can change the war's course before it happens. After the war ends, kingdoms make and break peace on their own.

## Project layout

```
project.godot               engine configuration (autoloads: Data, GS, Sfx)
scenes/                     main_menu, world_map, battle (thin scene files)
scripts/autoload/
  game_data.gd              all content: factions, troops, items, lords, companions,
                            settlements, map shape, story events, arena fighters
  game_state.gd             runtime state, calendar, player helpers, battle handoff, save/load
  sfx.gd                    procedural sound effects
scripts/core/
  world_sim.gd              world AI: movement, lords, bandits, caravans, sieges,
                            campaigns, story events, diplomacy, daily/weekly upkeep
  roster.gd                 troop stack helpers
  auto_resolve.gd           abstract battles
  economy.gd                prices, shops, taverns, fief income
  quests.gd                 quest generation and completion
  terrain.gd                world heightmap and biomes
scripts/world/              3D world map scene and model builders
scripts/battle/             battle scene, units, bending, projectiles, unit models
scripts/ui/                 menus and windows
tests/                      headless test scenes (see below)
```

**Modding:** most content lives in `scripts/autoload/game_data.gd`. Adding a troop, lord, settlement or item is a dictionary entry, and the map shape is a list of ellipses in `land_ellipses`.

## Tests

The `tests/` folder contains headless scenes used during development:

```
godot --headless --path . res://tests/check_scripts.tscn     # parse every script
godot --headless --path . res://tests/test_sim.tscn          # simulate 300 days of the world
godot --headless --path . res://tests/test_ui.tscn           # open every window, press its buttons
godot --headless --path . res://tests/test_flows.tscn        # siege defence, captivity, save/load
godot --headless --path . res://tests/test_travel.tscn       # click-to-travel on the map
godot --headless --path . res://tests/test_battle.tscn -- field   # AI-vs-AI battle (also: siege, arena, big, bend fire)
```

## Notes

This is a non-commercial fan project. *Avatar: The Last Airbender* and its characters belong to their creators and Nickelodeon. The show never names some locations, so a few settlement names were invented to fill the map (for example Frozen Harbour, Hakoda's Watch, Moon Fishery and Jade Terraces).
