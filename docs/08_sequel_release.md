# Sequel Release and the Player Insights Department (Simulation)

> **Simulated.** This document forecasts the release of the sequel designed in `docs/05_sequel_design.md`. It was written by Claude from comparable releases and the build's real strengths and weaknesses. No outlet, reviewer, creator, player handle or sales figure is real, and outlet names are invented.
>
> **What is real.** The persona-bot runs in §2.2 were made on this repository. Every design change in §5 that says "implemented" exists in the code.
>
> **Licence assumption.** The licensing precondition in `docs/04_launch_reception.md` §0 still applies: the simulation assumes a licensed commercial release.

## 0. What shipped

| | |
|---|---|
| **Title** | *Avatar: The Sixteenth Year* |
| **Platforms** | PC (Steam) and two consoles on the same day; Steam Deck verified at launch |
| **Price** | US$59.99 |
| **Team** | 28 core staff, about 60 external artists at peak, 4 martial-arts masters and 12 performers, and the new Player Insights department (§1) |
| **Built on** | Game 1 plus its four element expansions (`docs/07_avatar_and_dlcs.md`). The Avatar-as-NPC system and the expansion technique catalogues are folded into the sequel's base game. All four arts are playable from character creation. |
| **Headline features** | Form Designer on performance-captured movement units; the year-long clock to the Avatar's reveal; after the reveal, a young Avatar who seeks teachers and judges rulers; walkable interiors and Ba Sing Se's three rings as districts; naval and aerial play |

## 1. The Player Insights department

Game 1's reception arrived as noise:
- review scores;
- a few thousand Steam reviews;
- a Discord server moderated by two people in their evenings.

Design learned what players felt months late, and mostly from whoever shouted. For the sequel the studio founded a department whose only job is to turn player response into clear, evidenced, prioritised insight, and to deliver it to the designers who can act on it.

**Mandate.** Insights inform; pillars decide. The department never sets design. It owes the pods a clear account of what players are doing, feeling and saying, how confident it is, and who that affects.

**Structure.** 22 people in four cooperative teams under a head of player insight. The head sits in the weekly "Show the Floor" and in every pillar review.

| Team | Size | Expertise | Instruments | Produces |
|---|---|---|---|---|
| **Signal** (data) | 6 | Data science, game telemetry, experimentation, performance and crash analytics | Opt-in, aggregated telemetry: funnels, difficulty curves, choice distributions, build-health dashboards, crash and hitch reports by hardware | Quantitative evidence and the "what": how many, where, on what hardware |
| **Voices** (research) | 6 | Games user research, survey design, accessibility research, cultural and representation panels, support analytics | Moderated playtests, diary studies, quarterly surveys, paid panels (Deaf, autistic, ADHD, queer, disabled, and cultural communities), support-ticket mining | Qualitative evidence and the "why": what players meant, felt and expected |
| **Currents** (social media and trends) | 6 | Platform specialists, fandom culture, trend forecasting, creator relations, multilingual community management, sentiment analysis | Listening across short video, streaming, forums, chat servers, fandom archives and microblogs in eight languages; creator briefings; spoiler-safe community programmes | The pulse: what is spreading, why, among whom; early warning of discourse; the game's voice in community spaces |
| **Bridge** (synthesis) | 4 | Insight editing, design literacy, prioritisation, release communication | The insight backlog, the weekly brief, and one liaison embedded in each design pod | Insight cards, the weekly brief, decisions tracked to outcomes, and "You told us" notes back to players |

### 1.1 Currents, in more detail

The brief asked for one team with particular expertise in social media and trends. Currents is that team.

**Staffing:**
- **Two platform leads:** one for short-video and streaming culture, one for forums, chat servers and fandom archives. Long-form fan fiction and art communities are where this audience lives; they are not an afterthought.
- **A trend forecaster** who tracks how memes and discourse travel between platforms. Typically a clip starts on a streaming platform, becomes a short video, then becomes a forum thread with an argument attached.
- **A creator-relations lead** who briefs streamers before patches. Creators never learn of balance changes from their chat.
- **Two community managers** covering eight languages between them, with contracted moderators.

**Rules the team works by:**
1. **Listen widely, weigh carefully.** A post with 200,000 views is a signal about reach, not about prevalence. Nothing goes to design on virality alone.
2. **Never astroturf.** No undisclosed accounts, no seeded "organic" posts, no paid opinions.
3. **Protect people first.** Harassment of developers, creators or players triggers a safety protocol. Moderation and wellbeing come before any narrative response.
4. **Spoiler etiquette is policy.** The Avatar's reveal is never posted by official accounts before players have had two weeks.
5. **Small groups are not small concerns.** Feedback from accessibility and representation communities is weighted by impact on the people affected, not by volume.

### 1.2 How the four teams cooperate

**Three-source rule.** An insight reaches design only with evidence from at least two of Signal, Voices and Currents. Crashes, safety and harassment are exceptions and go straight through. Bridge checks the rule.

**Cadence:**
- **Daily:** a 15-minute triage with all four teams. New signals are assigned an owner and a second source.
- **Weekly:** Bridge publishes the Insight Brief, at most ten cards, ranked.
- **Monthly:** the "State of the Players" report goes to leadership.

**Insight card format:**
- the claim, in one sentence;
- the evidence from each source;
- confidence (low, medium or high);
- who is affected and how many;
- the recommended owner;
- a decision deadline.

Bridge then tracks the card until it is closed: "changed", "held, because…", or "carried to the next game".

**Prioritisation.** Severity × reach × confidence, divided by the cost to fix. Accessibility and safety issues carry a minimum severity floor, so they cannot be outvoted by volume.

**Closing the loop.** Every patch note has a "You told us" section written by Bridge. It credits the community's reports in aggregate; individuals are never named without permission.

**Privacy.** Telemetry is opt-in, aggregated and kept for no more than 18 months. The department never tracks named individuals, including creators.

## 2. Before launch

### 2.1 Public demo (the Ember Coast)

The demo was played by 410,000 players in two weeks (simulated).

- **Signal:** 31% of demo players opened the Form Designer. Of those, 64% saved a form, and 22% used only the starter form in combat. Median time to first saved form: 14 minutes.
- **Voices:** in playtests, the Form Designer's stance-chaining rule was understood only after a failure. When a movement was missing, players assumed the game was broken. *Changed before launch:* unavailable movements now show greyed out with the stance they need.
- **Currents:** the most shared demo clip was a waterbender's six-movement form that redirected an arrow volley into a ship's sail. It was reposted with the tag "my sifu would cry". The forecaster flagged the Form Designer as the shareable heart of the launch, and the marketing plan shifted toward form-sharing codes.

### 2.2 Internal automated play (real runs on this repository)

Signal adopted the persona bots from game 1 (`tests/test_personas.gd`). They were extended to three sandbox eras: a warlord under the prime Avatar, a kind bender under the young Avatar, and a chaos bot under the elder Avatar. These are the only figures in this document produced by running code; they are the actual output of the runs made for this commit. Results are in §2.3.

### 2.3 Bot results

The quiet-era bots behaved as in game 1:

| Bots | Days | Story beats | Pages recovered | Avatar |
|---|---|---|---|---|
| Six chaos | 160 each | 58–73 | 5–6 | Never sighted; no approach |
| Story | 220 | 248 | 6 | Never sighted; no approach |
| Warlord | 220 | 245 | 6 | Never sighted; no approach |

The beat counts rose from game 1's 34–59 because the expansions added talk hubs and teachers. Three endings were reached by chaos bots (sold to Ba Sing Se), plus one each by the story and warlord bots (buried; sold to the Fire Lord). The child Avatar was never sighted and never approached anyone, which is the quiet-era design.

The sandbox-era runs found one real problem:

| Run | Era | Days | Sightings | Approaches | Wars on the map at the end |
|---|---|---|---|---|---|
| warlord #303 | Prime (Lei Shan) | 220 | 4 | None (the bot never conquered or raided enough to draw the Avatar) | **none** |
| story #404 | Young (Siku) | 220 | 4 | None | **none** |
| chaos #505 | Elder (Akane) | 160 | 3 | None | 1 |

**Card SIG-0 ("The Avatar ends every war").** Under a young or prime Avatar the map was at peace by day 220.
- **Cause:** the Avatar brokered truces on 6% (young) or 15% (prime) of visits, and the kingdoms' own diplomacy could not restart wars fast enough.
- **Why it matters:** a sandbox about armies whose wars all stop is a sandbox with nothing to do. The brief's own line is "The Avatar cannot be everywhere".
- **Change (implemented in `scripts/core/avatar.gd`):**
  - truce chances lowered to 3% (young), 7% (prime) and 4% (elder) per visit;
  - at most one brokered truce every 90 days;
  - only for wars that have already run 60 days.

**Re-run after the change (same seeds):**

| Run | Wars at the end |
|---|---|
| Prime warlord | 1 (Fire Nation–Southern Water Tribe) |
| Elder chaos | 2 |
| Young story | 0 |

The young-era story bot argues for peace in the Southern council and delivers Shen Mu's letter, which is what ends its wars. That peace is the player's work, not the Avatar's, and was left alone.

The bots never drew the Avatar to them: none conquered enough or raided enough. The four approach paths are therefore covered by the deterministic tests in `tests/test_avatar.gd` (0 errors), not by the bots. Voices recorded this as a limit of automated play, not of the system.

All eleven runs reported **0 invariant issues** (state traps, duplicated companions, approval out of range, NaN positions, dialogue backlog, Accord violations).

## 3. Launch (simulated)

### 3.1 Critics

Simulated aggregate: **86 / 100** from 94 critic reviews (range 70–96). Game 1 scored 74.

| Outlet (fictional) | Score | Pull quote |
|---|---|---|
| *Long Read Games* | 96 | "The Form Designer is the first time a game has let me *author* martial movement rather than select it. Sayuri's duel against her old student is the best non-fight in years." |
| *Sandbox Monthly* | 92 | "The year-long clock turns a sandbox into a story with a deadline, and the Avatar's arrival judges what you built." |
| *The Polygon Herald* | 90 | "Huan is the best ace character in games, partly because nobody makes a speech about it." |
| *PC Frontline* | 84 | "Combat finally looks like the show. The menus still look like a tax return." |
| *Pixel & Ink* | 78 | "Gorgeous captured bending and sky bison that are finally bison, wrapped in an interface that feels assembled rather than designed." |
| *Console Critic* | 70 | "On a controller, the UI is a maze of identical brown buttons." |

**Consensus praise**
- Bending as authored martial art.
- The Avatar as a person who is hard to find and comes to you for reasons you can see.
- Companions old and new.
- Choices imported from game 1.
- The creatures (the art studio's work).
- Accessibility.

**Consensus criticism**
- The interface: flat, inconsistent, text-heavy, and unreadable at distance on a TV.
- Late-year pacing after the reveal.
- Naval camera discomfort.
- Performance in Ba Sing Se's Upper Ring on Steam Deck.

### 3.2 Players

| Window | Reviews | Positive | Label |
|---|---|---|---|
| Launch week (PC) | 21,400 | 88% | Very Positive |
| 3 months (PC) | 47,900 | 90% | Very Positive |
| 12 months (PC) | 83,000 | 91% | Very Positive (Overwhelmingly Positive recent, after the 1.3 patch) |

**Top review themes (Signal's topic model, confirmed by Voices' reading of 2,000 sampled reviews):**

| Rank | Positive | Negative |
|---|---|---|
| 1 | "I designed my own firebending and it *looks right*" | "The UI looks like a spreadsheet wearing a robe" |
| 2 | "The Avatar came to my court and I cried" | "I chased the Avatar for six hours and never found them" |
| 3 | "Huan / Sayuri / Gao Ming" | "Text too small on TV; controller navigation" |
| 4 | "Choices carried over from game 1" | "Post-reveal months feel thin" |

### 3.3 Sales and reach (simulated)

- **Sales:** 2.6 million units in 12 months across platforms; 1.1 million in the first month.
- **Concurrency:** Steam peak of 96,000 concurrent players at launch weekend.
- **Fandom:** 14,000 works of fan fiction on the main archive in the first year. The most-tagged characters are Huan, Sayuri and Gao Ming, then Hana.
- **Shared forms:** 3.2 million form codes shared through the in-game Codex. The most-copied form is a waterbending sequence called "Grandmother's Laundry".

## 4. The first ninety days, as the department saw it

Each card below was published in a weekly brief. Sources are marked: **S** Signal, **V** Voices, **C** Currents.

**IC-01 — The "Breath Ladder" meta** (high confidence)
- **Claim:** A form alternating hold and inhale movements stacked the "charged" property with negligible wind-up, and became the dominant form.
- **S:** 38% of the top 5% of players used one form archetype; average battle length fell 41% for them.
- **C:** a tutorial video ("unkillable breath form") had 1.9M views in 4 days.
- **V:** players called it "the right way to win", not "an exploit". They believed they had mastered breathing.
- **Recommendation:** Do not punish it; fix the maths. Charged applies once per form, and holds add wind-up.
- **Outcome:** Patch 1.02. Creators were briefed two days ahead. "You told us": "You found that breath matters. It does; now it matters once per form."

**IC-02 — #WhereIsTheAvatar** (high)
- **Claim:** Finding the Avatar is the most loved and most resented system at once.
- **S:** 61% of players sought an audience at least once. The median number of failed audiences before the first success was 4; 12% of players never succeeded in the first 20 hours.
- **C:** the meme format "the Avatar has left by a door nobody else knows about" reached 6M impressions. Its tone was affectionate until week three, then shifted to frustration in long-session communities.
- **V:** interviewees wanted the Avatar to stay hard to find, but wanted to feel they were getting warmer.
- **Recommendation:** Keep the difficulty. Add a direction of travel to sightings, and let a second consecutive day at the same town raise the audience chance.
- **Outcome:** Patch 1.1. Failed audiences fell to a median of 2. The meme became nostalgic.

**IC-03 — The hostage clip** (high)
- **Claim:** A streamer's clip of taking the prime Avatar's husband hostage became a discourse event.
- **C:** detected 40 minutes after the stream. Within a day it had 3M views and two camps, "this is dark storytelling" and "why is this in an Avatar game".
- **S:** 3.1% of players ever took a hostage. Of them, 88% saw the rescue and the Avatar's response.
- **V:** panels found the scene's framing clear and the consequences heavy. A minority of players wanted to be warned before such choices appeared.
- **Recommendation:** Hold the design (it is the brief's own example of countermeasures). Add a content preference, "Show the cruellest options", on by default with a clear description. Brief creators on intent.
- **Outcome:** Patch 1.1. Fewer than 2% of players turned the option off. The discourse ended within a week.

**IC-04 — "Spreadsheet wearing a robe"** (high, strategic)
- **Claim:** The interface is the largest negative theme and cannot be fixed by patching.
- **S:** controller players opened the Character and Party screens 40% less than mouse players and had 2.3× the menu backtracking.
- **V:** testers described the UI as "assembled", "amateur" and "AI-generated-looking". Players could not tell options from information. Text was illegible at TV distance.
- **C:** "brown button" memes on three platforms; localised UI overflow screenshots in German and Polish.
- **Recommendation:** Short term, patch readability: text scale, contrast and controller focus. Strategic: the next game needs a dedicated UI and visual-language effort, with the art department, from pre-production.
- **Outcome:** Patch 1.2 for readability; the strategic part was carried to game 3 (`docs/09_third_game.md`).

**IC-05 — Steam Deck hitching in the Upper Ring** (high)
- **S:** a 210 ms hitch on district entry, on Deck only.
- **C:** clips titled "Ba Sing Se loading in real time".
- **Outcome:** Patch 1.01 streams the Upper Ring in two parts.

**IC-06 — The teacher path is invisible** (medium)
- **S:** 0.9% of benders reached the top 1% (as designed), but 41% of surveyed players did not know the young Avatar seeks teachers at all.
- **V:** players who learned of it late felt cheated.
- **Recommendation:** Masters, abbots and sages mention it in conversation once the Avatar is revealed. Requirements are visible in the Avatar window, as in game 1.
- **Outcome:** Patch 1.1.

**IC-07 — Huan** (high, held)
- **V:** ace and aromantic panel members rated Huan's writing the most authentic in the game.
- **C:** a small but loud thread asked for a Huan romance.
- **Recommendation:** Hold. His romance option is his "no", and it is written as a kindness, not a lock.
- **Outcome:** Held, with a developer note explaining the decision. Community response was overwhelmingly supportive.

**IC-08 — Accessibility requests** (high)
- **V and C:**
  - a hyperlegible font option;
  - subtitles overlapping signing animations at 4K;
  - an infamy bar that relies on red alone.
- **Outcome:** Patch 1.2 added the font option and fixed the overlap; the bars gained patterns.

**IC-09 — Naval camera discomfort** (medium)
- **V:** 9% of playtesters reported motion discomfort at sea.
- **C:** comfort-mode requests.
- **Outcome:** Patch 1.1 added a horizon-lock and reduced camera roll.

**IC-10 — Porcelain arbitrage** (high)
- **S:** firing kilns and selling porcelain in Ba Sing Se returned 4× the median trade profit.
- **C:** a "kiln rich" guide.
- **Outcome:** Patch 1.02 made porcelain prices fall with supply, as other goods' do.

## 5. Patches (simulated summary)

| Patch | Week | Headline changes |
|---|---|---|
| 1.01 | 1 | Deck streaming fix; crash fixes on two GPU families |
| 1.02 | 3 | Breath Ladder rebalance; porcelain prices; creator pre-briefing introduced |
| 1.1 | 7 | Avatar sightings show direction; audience chance builds; teachers mentioned in dialogue; naval comfort mode; "Show the cruellest options" preference |
| 1.2 | 12 | Readability: text scale up to 1.8×, contrast mode, controller focus rings, hyperlegible font, pattern-coded bars |
| 1.3 | 26 | Post-reveal content: the young Avatar's festival tour and three new court scenes. Recent reviews reach Overwhelmingly Positive |

## 6. Twelve months

| Measure | Game 1 | Game 2 |
|---|---|---|
| Critic aggregate | 74 | 86 |
| Steam positive (12 months) | 81% | 91% |
| Units (12 months) | 0.9M | 2.6M |
| Median hours played | 21 | 46 |
| Players who used an accessibility option | 23% | 37% |
| Days from a signal appearing to a design decision | ~70 | 9 (median) |

The last row is the department's own measure of success, and it is the one leadership cited when approving its expansion for game 3.

## 7. What the department handed to game 3

Bridge's year-end brief carried six insights forward. They were ranked, and each had evidence from all three sources.

1. **The interface is the ceiling on everything else.** Players love the systems and resent reaching them. Readability patches helped; the visual language did not change. → Two dedicated UI teams.
2. **Players want to author more than forms:** banners, seals, form names, court ceremonies. → Expressive systems across the game.
3. **The Avatar works because the rules are visible.** Keep every rule shown. Make finding the Avatar a journey, not a timer.
4. **Fandom lives in the companions.** Fan works concentrate on characters with private lives the game respects (Huan, Sayuri, Gao Ming). → Writers' room budget kept ahead of feature count.
5. **Martial-arts authenticity is the brand.** The most-shared content was movement. → Masters for every art on staff, not on contract.
6. **Controller and TV play are now the majority on console** (58% of console hours on TVs over 50 inches). → Ten-foot UI from day one.
