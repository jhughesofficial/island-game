# The Island — Idle Game Design Spec

**Date:** 2026-04-05
**Status:** Approved
**Working Title:** The Island

---

## Overview

A satirical idle/incremental game in the style of Cookie Clicker and Adventure Capitalist. The player is an anonymous "Host" who has acquired a private island and grows their wealth and influence by throwing increasingly lavish and exclusive parties.

The game has two layers:

1. **The idle loop** — throw parties, earn money, buy venues, recruit VIPs, accumulate Political Influence
2. **The survival game** — manage a rising Heat rating while maximizing Political Influence before it's too late to "retire"

Underneath it all is a hidden satirical narrative: a slow-burn reveal that the island is modeled on Jeffrey Epstein's private island. The reveal is never telegraphed upfront. Players who connect the dots early feel clever. Players who don't have a genuine "oh no" moment.

The game has three possible endings driven by the player's timing and Political Influence score. Getting the best ending requires playing optimally — not just grinding, but knowing when to walk away.

---

## Platform

**Engine:** Godot 4
**Primary target:** Steam (Windows/Mac/Linux) — $2.99–$4.99 one-time purchase
**Secondary target:** Web (HTML5 export) — free, drives Steam discovery
**Tertiary target:** Mobile (Android/iOS) — TBD pending app store review of satirical content
**Excluded:** Roblox (children's platform, content violates TOS)

---

## Core Loop

```
Click "Throw Party" → earn $
→ buy Venues (auto-earn $/sec)
→ recruit VIPs (earnings multiplier + Political Influence gain)
→ collect Secrets (Political Influence booster, reduces Heat)
→ buy Upgrades (boost output, suppress Heat)
→ watch Heat rise → decide when to "Retire"
→ reach an ending
```

A single run is designed to take roughly 2–4 hours. Early game (0–5 min) is fast and rewarding. Mid-game (5–30 min) is optimization. Late game shifts to tension: money is abundant but Heat is rising and the retirement window is closing.

---

## Resources

### Money ($)
Primary resource. Earned by clicking and from venue passive income. Spent on venues, VIPs, upgrades, and heat suppression.

### Political Influence (PI)
Secondary meta resource. **Never spent** — it only accumulates. It is the player's score and their insurance policy. PI is gained by:
- Recruiting VIPs (each VIP awards PI on recruitment)
- Collecting Secrets (see below)
- Owning certain venue milestones
- Specific events and upgrades

PI is displayed prominently as a badge/counter alongside $ in the status bar. At end-of-run, PI determines which ending the player receives and feeds into a future prestige system.

### Heat (🔥)
A rising danger meter displayed as a 5-star rating (like GTA's wanted level). Heat increases automatically over time, accelerating as your wealth and island grow. It represents investigative pressure, media scrutiny, and legal exposure.

**Heat effects by level:**

| Level | Visual | Effect |
|-------|--------|--------|
| 🔥 | Warm | No effect. Just vibes. |
| 🔥🔥 | Hot | News ticker appears. Journalists are watching. |
| 🔥🔥🔥 | Scorching | Venue income reduced 10%. Subpoenas start arriving. |
| 🔥🔥🔥🔥 | Inferno | Venue income reduced 25%. VIP recruitment costs ×3. |
| 🔥🔥🔥🔥🔥 | CRITICAL | Forced game over in 60 seconds unless Heat is suppressed or player retires immediately. |

Heat can be temporarily suppressed by spending money on legal fees, bribery, or certain VIP favors — but suppression gets exponentially more expensive. It cannot be permanently eliminated; only retirement ends it.

---

## Central Visual: The Island Map

The center of the screen is an overhead/isometric illustration of a tropical island. This is the primary visual payoff — not a background, but a living progress tracker.

- **Base state:** Empty tropical island. A dock, a bonfire, nothing else.
- **As venues are purchased:** Buildings physically appear on the island at fixed positions. A yacht in the harbor. A villa on the hilltop. A jet on a paved airstrip.
- **Tone shift across progression:**
  - Early: looks like a luxury resort
  - Mid-game: increasingly exclusive — walls appear, fewer public areas
  - Late-game: fortified — fences, security posts, blacked-out windows, submarines
- The island transformation *is* the reward. Watching it evolve is the core visual feedback loop.

**Island shape:** The base island silhouette must be recognizable as Little Saint James, USVI — Epstein's actual island. This is a silent meta-joke: players who recognize the shape get the punchline immediately; everyone else only realizes in retrospect. The shape is roughly a flattened oval with a small protruding peninsula on the northwest side and a dock/pier area on the south. Reference: search "Little Saint James island aerial" for the exact outline.

**MVP implementation:** Layered PNG sprites composited over a base island image. Each venue type adds a sprite at a fixed island position on first purchase. Godot `CanvasItem` layering handles depth ordering.

---

## Venues

8 venues, each roughly 10× more expensive and productive than the last. Each venue generates $/sec passively once purchased. Multiple copies can be owned; each copy adds its base rate. Higher-tier venues also contribute faster Heat accumulation.

| # | Venue | Base Cost | Base $/sec | Heat Rate | Flavor Text |
|---|-------|-----------|-----------|-----------|-------------|
| 1 | Beach Bonfire | $10 | 0.1 | +0.001/sec | "A modest gathering. BYOB." |
| 2 | Luxury Yacht | $150 | 0.5 | +0.005/sec | "The ocean hides many things." |
| 3 | Private Villa | $1,000 | 3 | +0.01/sec | "Rooms with no cameras." |
| 4 | Private Jet | $10,000 | 15 | +0.02/sec | "Travel discreetly." |
| 5 | Offshore Account | $75,000 | 80 | +0.03/sec | "Money that doesn't exist." |
| 6 | Shell Corporation | $400,000 | 300 | +0.05/sec | "Technically legal." |
| 7 | Political Connections | $2,000,000 | 1,200 | +0.08/sec | "Friends in high places." |
| 8 | Media Blackout | $15,000,000 | 5,000 | -0.05/sec | "Nothing happened here." |

*Media Blackout is the only venue that actively reduces Heat — making it a strategic priority in late game.*

Each venue has 4 quantity tiers (auto-applied at 10/25/50/100 owned) that double output.

---

## VIPs

VIPs apply a **global earnings multiplier**, award **Political Influence on recruitment**, and have secondary effects on Heat or Secrets. Each VIP becomes available at a lifetime earnings threshold; the player then spends current money to recruit them.

VIP names are satirical stand-ins for figures named in the actual Epstein flight logs, written to be recognizable without being legally actionable.

| VIP | Based On | Appears At | Cost | Earnings | PI Award | Secondary |
|-----|----------|-----------|------|----------|----------|-----------|
| The Guest | Generic | $1,000 | $500 | ×1.5 | +5 PI | — |
| The Litigator | Defense attorney type | $10,000 | $5,000 | ×2 | +15 PI | -1 Heat star temporarily |
| The Former President | Former head of state | $100,000 | $50,000 | ×3 | +40 PI | +Heat suppression |
| The Merchant Prince | Fashion/retail mogul | $500,000 | $250,000 | ×4 | +80 PI | Unlocks Secret mechanic |
| The Royal | Foreign royalty | $5,000,000 | $2,000,000 | ×6 | +150 PI | International immunity perk |
| The Economist | Academic/policy figure | $50,000,000 | $20,000,000 | ×10 | +300 PI | Offshore Account output ×2 |
| The Socialite | Co-conspirator/fixer | $200,000,000 | $100,000,000 | ×15 | +600 PI | Secrets trickle in automatically |
| The Handler | Orchestrator figure | $500,000,000 | $200,000,000 | ×20 | +1,000 PI | Unlocks "Retire" action |

*Note: "The Handler" must be recruited before the player can access the Retire action.*

---

## Secrets

Secrets are a collectible that boosts Political Influence and suppresses Heat. They represent the player's leverage over their VIPs.

- Secrets are "collected" via a clickable event that appears periodically (like a cookie-clicker golden cookie)
- After unlocking "The Merchant Prince" VIP, Secrets also trickle in passively
- After recruiting "The Socialite," Secrets generate automatically over time
- Each Secret collected: +10 PI, -0.5 Heat (one-time reduction)
- Secrets can also be "spent" in narrative events to make choices that affect outcomes

---

## Upgrades

Two distinct upgrade systems:

### Venue Quantity Tiers (automatic, no cost)
Each venue auto-applies output doublers when you own 10 / 25 / 50 / 100 of that venue type. No purchase required — they trigger automatically with a toast notification.

### Shop Upgrades (one-time purchases)
Visible in the Upgrades panel. Four categories:

**Party Upgrades** — boost click value multiplicatively
Examples: Champagne Toast (×2 click), Open Bar (×3 click), Live DJ (×5 click), Fireworks (×10 click)

**Venue Upgrades** — named one-time purchases that multiply a specific venue type's output; unlocked at total-earnings thresholds (2–3 per venue type)

**Heat Suppression** — spendable (not one-time); costs scale exponentially; temporarily knocks Heat down by one star
Examples: Legal Retainer ($50K), Hush Money ($500K), Media Settlement ($5M), Senator's Favor ($50M)

**Prestige Perks** — unlocked after first prestige (Roadmap, not MVP)

---

## Click Mechanic

- Base click value: $1
- Clicking "Throw Party" earns current click value in $
- Click upgrades multiply this value
- Visual feedback: money particle burst, brief confetti spray, subtle screen shake at high click values
- Holding button allows rapid clicking; satisfying tactile feedback is intentional

---

## Heat Management

Heat rises passively based on:
- Total venue count × venue heat rate
- Time elapsed in the run
- Milestone triggers (first arrest, first subpoena, etc.)

**Suppression options (all cost money, all temporary):**
- Buy Heat Suppression upgrades from shop
- Some VIPs reduce Heat on recruitment
- Collecting Secrets reduces Heat slightly
- "Media Blackout" venue is the only passive Heat reducer

The core tension: suppression gets more expensive as the run progresses. At some point, the player cannot afford to suppress fast enough. That is the signal to retire.

---

## Retire Mechanic — "Fake Your Death"

Available only after recruiting "The Handler."

At any moment, the player can click **[RETIRE]** — a prominent button that appears in the status bar once unlocked. This triggers a brief cutscene and ends the run, delivering one of the three endings based on the player's PI and current Heat level.

**The timing dilemma:**
- Retire too early → low PI score, you "left money on the table," unlock fewer post-game bonuses
- Retire too late → Heat reaches critical, forced game over before you can retire
- Optimal window → maximize PI while keeping Heat suppressed just long enough

The TV news channel (post-MVP) is the player's best signal for when the window is closing — as news coverage shifts from generic stories to pointed coverage of the island, the player knows Heat is about to spike.

---

## Win / Lose Conditions & Endings

### Ending 1: ARRESTED (Bad)
**Trigger:** Heat reaches 🔥🔥🔥🔥🔥 and 60-second grace period expires without retirement.
**PI required:** None (this ending ignores PI).
**Screen:** Your character (paper doll) is shown in an orange jumpsuit. Headline: *"Island Host Arrested. Prosecutors Confident."* Run ends. PI carries over to next run as a small starting bonus.

### Ending 2: "SUICIDE" (Dark Good)
**Trigger:** Heat reaches 🔥🔥🔥🔥🔥 AND grace period expires — but you have accumulated **≥500 PI**.
**Screen:** Your character is seated in a luxurious armchair on the terrace of a new island home, drink in hand, watching a wall-mounted TV. The broadcast: *"Island Host Found Dead in Cell. Medical Examiner Rules Suicide."* Your character takes a slow sip. No reaction. They've seen this before. Flavor text: *"You didn't commit suicide."* The implication: your PI bought you friends powerful enough to fake your death, kill the story, and get you out. You didn't escape cleanly — but you escaped.
**Unlocks:** Prestige run with PI converted to Influence multiplier.

### Ending 3: RETIRED (True Win)
**Trigger:** Player clicks [RETIRE] voluntarily while Heat is ≤ 🔥🔥🔥 AND has accumulated **≥2,000 PI**.
**Screen:** A private plane lifts off from the island airstrip. Cut to: your character on a different beach, drink in hand, watching the news on a tablet. The tablet shows: *"Island Host Declared Dead. Body Never Recovered."* Flavor text: *"You won."*
**Unlocks:** "Ghost Mode" — a new game mode (post-MVP roadmap) where you play as a ghost operator running the island from the shadows with new mechanics.

---

## Narrative: The Three-Act Slow Reveal

The Epstein connection is **never telegraphed upfront** — the player pieces it together themselves through flavor text, news stories, and VIP names.

### Act 1 — "Just a party host" (0 → ~$1M total earned)
- Generic wealth fantasy framing. Title screen: *The Island*.
- Venues have innocuous names and clean flavor text.
- Nothing feels off. Rich person throws parties on their island.

### Act 2 — "Wait a minute..." (~$1M → ~$1B total earned)
- Flavor text becomes pointed: *"This room has no cameras. By design."* / *"The guest list is... selective."*
- News ticker appears (🔥🔥 Heat triggers it). Headlines rotate:
  - *"Local billionaire hosts 'charity event' on private island"*
  - *"Senator denies attending retreat: 'I was there for the weather'"*
  - *"Flight logs sealed by court order"*
  - *"Spokesperson: 'The island does not exist'"*
- VIP unlock toasts get suggestive: *"A very important person has arrived. You don't ask their name."*
- Island visually shifts: security fencing, unmarked vessels, blacked-out windows.

### Act 3 — The Reveal (~$1T earned or Heat ≥ 🔥🔥🔥🔥)
- A full-screen **Breaking News** modal interrupts gameplay.
- Headline: *"Prosecutors unseal flight logs. 'The Island' identified."*
- Satirical summary of everything the player has been building.
- On dismissal: game subtitle updates to *"The Island: Elite Affairs"*. Achievements retroactively get sharper flavor text. The player now knows what they've been doing.

---

## Character Creation (Post-MVP)

A simple paper doll / avatar system. Kept intentionally minimal — this is not a deep RPG creator.

**Options:**
- Skin tone (6 options)
- Hair style (8 options)
- Clothing style (3 options: "Casual Wealth," "Business Formal," "Bond Villain")
- Optional accessory (monocle, cigar, champagne glass)

**Usage in-game:**
- Avatar portrait appears in the status bar as a profile picture
- Full paper doll shown in: retirement cutscene, arrest ending, "suicide" ending
- Occasionally appears in narrative event pop-ups (*"You are photographed boarding your jet."*)

Character creation accessible at game start and via settings. No gameplay impact — purely cosmetic.

---

## TV News Channel (Post-MVP)

A small TV icon sits in the corner of the game screen (visible from Act 2 onward). Clicking it opens a TV overlay showing the current "broadcast."

News stories cycle through three tiers based on current Heat and narrative act:

**Tier 1 (Heat 🔥–🔥🔥):** Completely unrelated news. Stock markets, celebrity gossip, sports scores. Flavor only.

**Tier 2 (Heat 🔥🔥🔥):** Peripheral stories. *"Hedge fund manager linked to offshore accounts."* / *"Private island communities raise zoning concerns."* Hints but no direct coverage.

**Tier 3 (Heat 🔥🔥🔥🔥+):** Direct. *"Flight logs subpoenaed in island probe."* / *"Three senators refuse to comment on island visit."* Clear signal that retirement window is closing.

The TV is the player's best tool for gauging when to retire. A player who ignores it risks missing the window.

---

## Save System

- Auto-save every 60 seconds to Godot's `user://save.json`
- Offline earnings calculated on load (capped at 8 hours of offline production)
- Manual save button in settings panel
- Save includes: money, lifetime earnings, venues, VIPs recruited, upgrades purchased, PI total, Heat level, narrative act state

---

## UI Layout (High Level)

```
┌──────────────────────────────────────────────────────────┐
│  [Avatar PFP]  THE ISLAND    $ 4.2M  🏛 120 PI  [⚙️]    │
│                              🔥🔥🔥 Heat  [RETIRE]        │
├───────────────────┬──────────────────────────────────────┤
│                   │                                       │
│   ISLAND MAP      │   VENUES  │ UPGRADES │ VIPS  (tabs)  │
│   (left/center)   │   (scrollable panel)                  │
│                   │                                       │
│  [THROW PARTY]    │                                       │
│   (big button)    │                                       │
├───────────────────┴──────────────────────────────────────┤
│  📺  NEWS TICKER ─── scrolling headlines ──────────── ── │
└──────────────────────────────────────────────────────────┘
```

- Avatar PFP is post-MVP placeholder (initials or silhouette for MVP)
- 📺 TV icon in ticker bar opens news overlay (post-MVP)
- [RETIRE] button only visible after recruiting The Handler
- Heat meter uses 5-star visual, color shifts warm→red as it fills

Detailed UI design to be done with ui-ux-pro skill during implementation.

---

## Art Direction

**Aesthetic:** Old money meets noir.
- Background: deep navy / near-black (#0d0d0d)
- Accents: gold (#c9a84c), ivory text
- Heat meter: gold → amber → red gradient as stars fill
- Typography: serif for titles (Playfair Display or similar), monospaced for numbers
- No cartoon style — visually dry and satirical, like a private members club crossed with a Bond villain's lair
- Island illustration: detailed but not photorealistic; painterly or vector-art style

Art complexity scales with timeline. MVP can use placeholder rectangles for buildings on the island.

---

## Number Formatting

All dollar values display in short notation:
- < $1,000: exact ($472)
- ≥ $1,000: K ($4.5K)
- ≥ $1,000,000: M ($2.1M)
- ≥ $1,000,000,000: B ($8.3B)
- ≥ $1,000,000,000,000: T ($1.2T)
- Beyond T: letter suffixes (Qa, Qi, Sx, Sp, Oc, No, Dc...)

---

## MVP Scope

The following defines done for the initial prototype:

- [ ] Click mechanic with particle/confetti feedback
- [ ] All 8 venues with Heat rate contributions
- [ ] First 4 VIPs (The Guest through The Merchant Prince)
- [ ] 10 one-time shop upgrades (mix of click and venue)
- [ ] Heat Suppression upgrades (Legal Retainer, Hush Money)
- [ ] Heat meter display (5-star, color-coded)
- [ ] Political Influence counter in status bar
- [ ] Island map with layered venue sprites (last 2 venues placeholder)
- [ ] Number formatting utility (K/M/B/T+)
- [ ] Auto-save / load (Godot `user://`)
- [ ] Offline earnings calculation (8hr cap)
- [ ] Act 1 flavor text only (no news ticker yet)
- [ ] Settings panel (volume, reset save)
- [ ] Ending 1 (Arrested) — basic game over screen
- [ ] Single game screen — no main menu for MVP

Post-MVP only: character creation, TV news channel, Secrets mechanic, Retire action (requires The Handler, which is VIP 8), Endings 2 & 3, Act 2/3 narrative, prestige system.

---

## Post-MVP Roadmap

1. Secrets mechanic (collectible events, passive generation)
2. VIPs 5–8 (The Royal through The Handler) + Retire button
3. Endings 2 & 3 (suicide / true retire cutscenes)
4. Act 2 news ticker + mid-game narrative escalation
5. Act 3 breaking news reveal event
6. Character creation (paper doll)
7. TV news channel overlay
8. Prestige system ("Make It Disappear" + Ghost Mode)
9. Full island art with all building sprites
10. Achievements panel
11. Statistics screen
12. Narrative events (random pop-ups with satirical choices, Secret spending)
13. Sound design / music
14. Steam release build + store page
15. Mobile port (pending app store review)

---

## Technical Notes

- **Engine:** Godot 4.x
- **Language:** GDScript
- **Save format:** JSON via `FileAccess` to `user://save.json`
- **Scene structure:** Single main scene with UI panels as child scenes
- **Island map:** `Node2D` with ordered `Sprite2D` children per venue tier
- **Game state:** Singleton `GameState` autoload manages money, PI, Heat, venues, VIPs, upgrades, narrative act
- **Tick system:** `_process(delta)` accumulates $/sec and Heat/sec; all rates derived from `GameState`
- **Heat:** Float 0.0–5.0 mapped to 5-star display; star thresholds at 1.0, 2.0, 3.0, 4.0, 5.0
- **Endings:** Triggered by `GameState` signals; rendered as full-screen scene overlays
