# Avatar: The Quiet Years (Mount & Bend)

A Mount & Blade–style sandbox set in the world of *Avatar: The Last Airbender*, built in **Godot 4.3**. It uses the original series' world and peoples but tells an original story at an unnamed time before Aang. You raise an army, trade, take quests, serve or betray kingdoms, besiege cities, walk their streets, and fight real-time 3D battles with swords, bows and bending, including bending forms you compose yourself.

**The Quiet Years.** Eleven years ago the Avatar drowned at sea on the way to a peace conference. Somewhere a child is the next Avatar and does not know it yet. Until they turn sixteen, the world must manage on its own:
- the Fire Nation and the Earth Kingdom fight over the Ember Coast;
- Omashu has seceded from Ba Sing Se;
- the Southern Water Tribe raids the Fire Navy;
- the Air Nomads shelter everyone.

There is no Day of Black Sun and no Sozin's Comet. Eclipses and comets happen as natural events, announced by astronomers a few days ahead.

## Running the game

1. Install **Godot 4.3 or newer**, the standard build rather than the .NET one: <https://godotengine.org/download>.
2. Clone this repository, or download it as a ZIP and unzip it.
3. Start Godot, click **Import**, select `project.godot`, then **Import & Edit**. The first import takes a few minutes while Godot imports the art assets.
4. Press **F5** to play.

The project uses the *Compatibility* (OpenGL) renderer, so it runs on modest hardware. Export through **Project → Export** after installing the export templates.

## Controls

### World map
| Input | Action |
|---|---|
| Left click | Travel to the ground, a settlement or a party |
| Mouse wheel / right-drag / middle-drag or WASD | Zoom / rotate / pan (F re-centres) |
| M | Whole-world overview |
| Space, Ctrl or `>>` | Stop, fast travel |
| T / Esc | Camp: wait, talk to companions, sit by the fire, read the Avatar's logbook, save/load, settings |
| P, C, I, J, N | Party, Character (and **Bending Forms**), Inventory, Quests, Nations |

A gold ★ on a settlement's label means a story beat is waiting there.

### Walking a settlement
Choose **Walk around** in any friendly settlement's menu.

| Input | Action |
|---|---|
| WASD, Shift | Walk (Shift walks slowly) |
| Mouse, wheel | Look, zoom |
| E | Talk to the person in front of you (merchant, smith, innkeeper, steward, elder, abbot, gatekeeper) |
| Tab, or leave through the gate | Back to the world map |
| Esc | Free or recapture the mouse |

### Battle
| Input | Action |
|---|---|
| WASD, Shift, Space | Move, walk, jump |
| Left mouse | Attack. Direction follows your last mouse movement: up gives an overhead strike, down a thrust, left or right a swing |
| Right mouse | Block. Blocking is automatic by default; turn it off in Settings |
| 1 / 2 | Melee / ranged weapon |
| Q / E / R | Bending abilities |
| **F** | Your **bending form**, designed under Character → Bending Forms |
| F1 / F2 / F3 | Hold / follow / charge |
| Tab, Esc | Leave when the battle is decided; pause menu |

## What's in the game

### The story: *The Drowned Testament*
On day 2 a wounded Air Nomad courier finds you with a page of the drowned Avatar's logbook. Six pages are scattered:
- with a pirate queen;
- in an Air Temple archive;
- in a Dai Li vault;
- in the Fire Navy's records;
- with the owl spirit Wan Shi Tong;
- and the first one is in your hands.

Every page has two or more ways to get it: money, a fight, standing, theft, a companion's help, or a painful trade. When you have read all six, you decide what the truth is for:
- tell it to a Council of Nations;
- give it to one ruler;
- sell it to the man it condemns;
- burn it;
- or keep it for the next Avatar.

Each ending changes the world and is followed by an epilogue for every companion.

### Companions
Eight companions wait in taverns. Each has a personal quest that changes them and the world, and approval that rises and falls with what you do.

| Companion | Who they are | Quest |
|---|---|---|
| **Hana** | An autistic Lower Ring earthbender mapping every tunnel under Ba Sing Se | Finds the Dai Li officer who sealed her teacher in |
| **Juro** | A Fire Nation engineer who lost his fire the night his designs burned a village | Goes back to the village |
| **Pemba** | A nonbinary Air Nomad who will not kill | Looks for their sister among the Red Lantern daofei |
| **Nima** | A Northern healer who taught herself combat waterbending | Can change her Tribe's law |
| **Ukiuk** | A Southern harpooner with a debt from a raid | Faces it |
| **Shen Mu** | An Omashu courier carrying a letter that could stop a war | Delivers it |
| **Reika** | A Fire Nation privateer starting to doubt her admiral | Decides about her letter of marque |
| **Kesi** | A Deaf sandbender exiled for refusing a raid | Helps her starving clan |

Campfire banter, five romances, and partings if approval collapses.

### Cultures and class
* **Standing** — Commoner, Citizen, Gentry, Noble — decides which gates open.
* **Ba Sing Se** has three rings with guarded gates; papers or a bribe get you into the Middle Ring; the Dai Li notice.
* **Fire Nation nobles** settle insults by **Agni Kai**; fight it yourself or name a firebending champion.
* **Northern Water Tribe** women may learn only healing until the **Law of the Two Paths** changes. Changing it opens the Moon Guard.
* **Southern Water Tribe**'s council can be swayed on war and peace.
* **Air Temples** cannot be attacked, heal you for free, and sell no meat; pilgrims on sky bison roam the map.
* The **Nations** window explains each people's order of precedence and what it means for you.

### Bending
Bending uses **chi** and scales with the Bending skill and Intelligence:

| Element | Q | E | R |
|---|---|---|---|
| Fire | Fire Blast | Fire Wave | Lightning (Bending 5) |
| Earth | Rock Throw | Earth Wall | Earthquake |
| Water | Water Whip | Healing Water | Ice Spikes |

**Time of day and sky matter:**
* Fire is stronger by day.
* Water is stronger by night and under a full moon.
* A solar eclipse takes firebending away; a lunar eclipse takes waterbending.
* A comet strengthens fire for a few days.

**Bending Forms** (Character → Bending Forms) is a prototype of the sequel's system:
* **Composing:** you build a form from movements of your art's martial basis (Tai Chi, Hung Gar, Northern Shaolin, Baguazhang). Stances must chain and breath should alternate.
* **Computed stats:** power, wind-up, chi and properties (piercing, redirecting, staggering, evasive, charged) follow from what you chose.
* **In battle:** put the form on **F**. Every bender starts with one form of their art.

### Sandbox
* Lords campaign, besiege, raid and make and break peace.
* Outlaws prey on travellers.
* Caravans trade.
* Prices vary by place.
* You can serve a nation as a mercenary or vassal, or hold your own realm.

## Documents

| | |
|---|---|
| `docs/01_team_review.md` | Simulated expert review of the first prototype, art bible, production plan |
| `docs/02_writers_room.md` | Setting bible; two simulated writing teams' drafts and edits; cultures, lords, companions |
| `docs/03_playtests.md` | Seven simulated playtesters, automated persona bots, fix log, known limits |
| `docs/04_launch_reception.md` | Simulated reception of a licensed commercial release |
| `docs/05_sequel_design.md` | Sequel design: doubled team, art studio, martial-arts capture, the Form Designer |

The teams, writers, playtesters and reception in these documents are **simulated by Claude**; the documents say so at the top.

## Art and licences

Characters, outfits, hair, animations, nature, props, horse, cow and triceratops are **CC0** assets by **Quaternius**; see `assets/LICENSES.md`.
- **Repainting:** everything is recoloured into culture palettes and drawn with a cel shader and ink outlines.
- **Faces:** facial expressions are morph targets generated in code from the head mesh.
- **Architecture:** generated in code by an architecture kit (`scripts/town/arch.gd`) as painted, inked meshes.
- **Sound and music:** synthesised at runtime.

## Project layout

```
project.godot           autoloads: Data, GS, Sfx, Music
assets/                 CC0 models, textures, animations (see assets/LICENSES.md)
shaders/                cel (toon), painted architecture (toon_paint), ink outline
scenes/                 main_menu, world_map, battle, town
scripts/autoload/       game_data (all content), game_state (state, calendar, standing, duels, save/load), sfx, music
scripts/core/           world simulation, economy, quests, terrain, rosters, auto-resolve
scripts/story/          story engine, main story, companion quests, camp talk, endings
scripts/actors/         character builder, actor (animation tree, faces), accessories, looks, mounts, bending stances
scripts/town/           architecture kit, settlement layouts, townspeople, walkable town scene
scripts/battle/         battle scene, units, bending, forms, projectiles, set dressing
scripts/world/          world map and its builders
scripts/ui/             windows: settlement, encounter, dialogue, forms, epilogue, party, character…
tools/prepare_assets.py how the CC0 packs were copied, downsized and recoloured
tests/                  headless tests (below)
```

## Tests

```
godot --headless --path . res://tests/check_scripts.tscn    # parse every script
godot --headless --path . res://tests/test_story.tscn       # validate all dialogue graphs, play every ending and companion quest
godot --headless --path . res://tests/test_personas.tscn    # chaos/story/warlord bots play 1,600+ days
godot --headless --path . res://tests/test_town.tscn        # build ten walkable settlements, open every interaction
godot --headless --path . res://tests/test_sim.tscn         # simulate 300 days of the world
godot --headless --path . res://tests/test_ui.tscn          # open every window, press its buttons
godot --headless --path . res://tests/test_flows.tscn       # siege defence, captivity, save/load
godot --headless --path . res://tests/test_battle.tscn -- field   # also: siege, arena, duel fire, big, bend <element>
```

## Notes

This is a non-commercial fan project. *Avatar: The Last Airbender* belongs to its creators, Nickelodeon and Paramount; the game cannot be sold without a licence. All characters and the story of *The Quiet Years* are original to this project.
