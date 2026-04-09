# Steam Release Checklist — The Island

Status key: ✅ Done | 🔧 Code-ready, needs asset | ⬜ Not started | 👤 Needs Justin

---

## Core Game

- [x] Core idle loop (click, venues, staff, upgrades, VIPs)
- [x] Heat system + arrest countdown
- [x] Three endings (arrested, suicide, retired)
- [x] Ghost Mode prestige + Custom Run / identities
- [x] 25 achievements
- [x] 15 secrets mechanic
- [x] 14 narrative events
- [x] 4-act news ticker
- [x] Act 3 + Act 4 cinematic modals
- [x] Statistics panel
- [x] Settings (volume sliders, auto-save)
- [x] Tutorial system (5 hints)
- [x] Save/load + offline earnings
- [x] Balance pass (all venues, VIPs, upgrades tuned)
- [x] Achievement timing fix (endings_reached populated before signal fires)

---

## Assets Needed Before Ship

- [ ] **OGG audio files** — 3 music tracks (act1/act2/act3) + 9 SFX 🔧
  - AudioManager is fully wired; drop files into `audio/` and done
  - SFX slots: click, buy, upgrade, vip_recruited, secret_found, toast, game_over, arrest_warning, retire
- [ ] **Venue sprites** — 8 venue buildings + bonfire/yacht placeholder 🔧
  - Recommended: Recraft V4 Pro (island base + venue art), Spritesheets.ai for animations
  - Style: old money noir, dark palette, minimal detail
- [ ] **Capsule art** — Steam requires 460×215px header + 616×353px capsule 👤
  - Concept: luxury resort aesthetic with a subtle wrongness (news chyron, too many stars, off angle)
- [ ] **Screenshots** — minimum 5 required by Steam 👤
  - Suggested: main loop UI, Act 3 breaking news modal, game over screen, achievements panel, Custom Run identity select

---

## Steamworks Setup

- [ ] Create Steamworks app (store.steampowered.com/steamworks) 👤
- [ ] Set app ID in project (update `project.godot` and export presets once assigned)
- [ ] Install GodotSteam plugin (replaces raw Steamworks SDK) ⬜
  - Repo: godotsteam/GodotSteam — Godot 4.6 compatible
  - Enables: Steam achievements, cloud saves, overlay
- [ ] Map 25 in-game achievements to Steam achievement API keys ⬜
- [ ] Enable Steam Cloud for save files (`user://savegame.json`, `user://achievements.json`, `user://prestige.json`, `user://tutorial.json`) ⬜
- [ ] Test Steam overlay (Shift+Tab) doesn't conflict with game input ⬜

---

## Export & Build

- [x] Export presets configured (Windows, macOS, Linux/Steam Deck, Web)
- [x] Build guide written (`docs/build_guide.md`)
- [ ] Install Godot export templates (Editor → Manage Export Templates) 👤
- [ ] Test Windows build end-to-end 👤
- [ ] Test Linux/Steam Deck build (can use SteamOS VM or deck) 👤
- [ ] Windows code signing (optional but reduces SmartScreen warnings) ⬜
- [ ] macOS notarization (required for non-Steam Mac distribution) ⬜

---

## Store Page

- [x] Short description (≤300 chars)
- [x] Long description
- [x] Tags (20 suggested, priority ordered)
- [x] Content warnings / mature content description
- [x] Pricing strategy ($2.99 base, $1.99 launch discount)
- [x] Marketing angles (4 audiences)
- [ ] Capsule art uploaded 👤
- [ ] Screenshots uploaded (min 5) 👤
- [ ] Trailer (optional but strongly recommended for idle/clicker genre) 👤
  - 60–90s: show the reveal arc without spoiling Act 3 text; end on breaking news flash

---

## Legal / Compliance

- [x] No real names used anywhere in the game
- [x] Fictionalized scenario — all VIPs are satirical stand-ins
- [x] Content warning documentation (mature themes, implied criminal activity)
- [ ] Privacy policy URL (required by Steam if any data collection) ⬜
  - The game has no network calls, no telemetry — a simple "no data collected" page suffices
- [ ] EULA (optional; Steam provides a default if omitted) ⬜

---

## Pre-Launch

- [ ] Submit for Steam review (7–10 day window typical) 👤
- [ ] Set release date / coming soon page 👤
- [ ] Wishlist campaign — post to r/incremental_games, r/idlegames, itch.io devlogs ⬜
- [ ] Reach out to idle game YouTubers (key channels: Idling to Rule the Gods community, DerpiestVideosHD, incremental game subreddit mods) ⬜

---

## Estimated Remaining Work

| Category | Effort | Blocker |
|----------|--------|---------|
| OGG audio | 1–2 days | Asset sourcing (Justin) |
| Venue sprites | 2–3 days | Art generation (Justin / Recraft) |
| Capsule + screenshots | 1 day | Design (Justin) |
| GodotSteam integration | 2–3 days | Steamworks app ID (Justin) |
| Steam achievement mapping | 0.5 days | After GodotSteam integrated |
| QA pass (all 3 endings, Ghost Mode, Custom Run) | 1–2 days | Playtest (Justin) |
| Windows/Linux build test | 0.5 days | Export templates installed (Justin) |

**Minimum viable ship path (no trailer, no code signing):** ~8–12 days of focused work.
