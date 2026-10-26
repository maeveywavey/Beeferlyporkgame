# Script and Story-Arc Review

> **Simulated editorial pass, real fixes.** The "story editors" below are the same simulated writers' room as `docs/02_writers_room.md`. Every finding was checked against the build and every fix exists in the repository. The review covered all story files and the code that applies their consequences.

## 1. Method

The review used four techniques.

**Read-through.** Every dialogue in `scripts/story/` (83 dialogues, 330 nodes after the fixes) was read in arc order, checking:
- continuity of names, ages and relationships;
- tone;
- whether every choice has a consequence the player can feel.

**Flag-flow lint.** A script (kept out of the repository) extracted every story flag that is set and every flag that is read, across all of `scripts/`.
- A flag that is set but never read is a consequence that does nothing.
- A flag that is read but never set is a dead branch.

**Code trace.** Each consequence was followed into the systems that should honour it: the settlement menus, the duels, the endings and the epilogue.

**Bots.** `tests/test_personas.gd` was re-run before and after the fixes: six chaos bots, a story bot and a warlord bot, 1,620 days in all, with 0 invariant violations both times. Its renown figures exposed a balance fault (finding C1).

## 2. Findings and fixes

### A. Continuity

| # | Finding | Fix |
|---|---|---|
| A1 | Nima's quest opened with "A letter from my sister. Kaya was caught…", which reads as if Kaya were her sister. Her bio, journal and parting line all make Kaya her daughter. | The line now says her sister keeps Kaya while Nima is away. |
| A2 | Abbess Tsering called the next Avatar someone who "isn't born yet… learning to walk". The setting fixes the child at about ten: born after the death eleven years ago, and told at sixteen "in five years". | The line now gives the age as ten. |
| A3 | The epilogue checked `shen_mu_done`, but the quest sets `shenmu_done`. A Shen Mu who finished his quest and then left the party was described as having left "before the end". | The epilogue maps each companion to its real completion flag. |

### B. Consequences that did nothing

| # | Flag | Problem | Fix |
|---|---|---|---|
| B1 | `dai_li_enemy` | Being caught in the Dai Li vault said "The Dai Li will not forget you". Nothing remembered. | While Wu Jian is at large, Dai Li agents (scaled to your party) hunt you near Earth Kingdom land about once a month. Middle Ring papers stop working and every bribe fails; only Gentry standing opens the gate. Paying off Wu Jian (new scene, D1) clears it. |
| B2 | `wu_weakened` | Hana's exposure of Bo Lai was said to loosen Wu's grip. It had no effect. | In the Accord ending, Wu Jian's loyalist army is half the size. |
| B3 | `secret_given` | Telling Wan Shi Tong a companion's secret cost approval, then was forgotten. | That companion's epilogue line now remembers it. |
| B4 | `letter_read` | Secretly reading Shen Mu's letter cost approval and was then forgotten. | His epilogue now carries a quiet echo of it. |
| B5 | `juro_fire` | Juro's regained firebending is stored in his companion state, but the Agni Kai champion check read only his base data. He could never stand as a champion, and the champion fight ignored his raised power. | Both checks now read the companion state first. |

### C. Balance

**C1. The Council ending stayed out of reach.** The earlier playtest fix set the Council of Nations at 220 renown and claimed story play would get near it. The bots disagree. Story-focused runs end at 25–80 renown by day 160–220, so the "best" ending was in practice reserved for players who grind battles. The fix has two parts:
- each recovered page now adds 8 renown, because word gets around;
- the gates drop to 160 renown for the Council and 320 to sway it without corroboration.

A story player who also completes three companion quests now reaches the Council without grinding. One who skips the companions still needs some fighting.

### D. Arc structure

**D1. The two antagonists had no faces.** Kuro and Wu Jian drive the plot, but before the endings neither ever spoke to the player. Wu appeared only in Hualing's dialogue; Kuro only on a pay-chit. The editors' note was that a mystery whose culprits are names on paper cannot make "Both of them let it happen" land. Two optional scenes now open once the player holds four pages:

- **"The Grand Secretary"** (Ba Sing Se): tea in a pavilion with no walls.
  - Wu offers 3,000 gold and to "lose" your Dai Li file.
  - If you hold Page IV, he defends the boats as a filing matter.
  - Taking the money sets `wu_paid`. The epilogue then notes whether his gold paid for the Council's lamp oil or still sits unspent.
- **"The Admiral's Table"** (Fire Navy Harbour): dinner aboard the flagship.
  - Kuro makes the one honest case for the war: four thousand sailors with no pay.
  - If his agents attacked you, he apologises for them.
  - He makes the offer that the "Truth Buried" ending later collects on.

Both scenes give the endings' moral weight a person to attach to without telling the player what to think.

**D2. The Queen's promise was free.** Hualing asks to hear the truth first in return for Page IV, and nothing checked whether you kept the promise.
- **Keeping it:** a new scene, "As Promised", lets you read her the pages before you decide (+20 with Hualing).
- **Breaking it:** giving the pages to anyone else without telling her first costs 25 relation and a log line saying she heard it from a rumour.

The Council ending counts as keeping the promise, since she hears it in the same room as everyone else.

## 3. Arcs reviewed and left as written

The editors read these and recommended no change:
- **Juro, Pemba, Ukiuk, Kesi:** each arc has two or three endings that differ in kind, not only in reward.
- **Nima:** the duel is still decided by preparation and approval, never dice.
- **Shen Mu's letter:** works as a moral test and as a world event, because it opens the Omashu–Fire Nation talks.
- **Prologue:** gives the player an early sense of ownership of the story. The Norbu-lives and Norbu-dies branches change two later scenes and the epilogue.

**Known thin spot (not fixed):** Ukiuk's and Reika's quests have no combat beat, and the Red Lantern den has no walkable scene. Both are noted for the element DLCs, which add story content in the same regions.

## 4. Verification

| Check | Result |
|---|---|
| `tests/test_story.tscn` | 83 dialogues, 330 nodes, 16 triggers, 27 options validated. All seven endings and all eight companion quests played. 0 errors. |
| `tests/test_personas.tscn` | 1,620 bot days, 0 issues. |
| `tests/check_scripts.tscn` | 0 failures. |
