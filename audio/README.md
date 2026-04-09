# Audio Files

All audio must be **OGG Vorbis** format (.ogg) — Godot 4's preferred streaming format for both music and sfx.

## Music (ambient loops)

| File | Act | Mood |
|------|-----|------|
| `music/act1_ambient.ogg` | Act 1 (< $1M lifetime) | Calm, tropical, innocent |
| `music/act2_tension.ogg` | Act 2 ($1M – $50M lifetime) | Slightly darker, minor key |
| `music/act3_danger.ogg` | Act 3 (≥ $50M lifetime) | Tense, ominous |

Loops are crossfaded over 1.5 seconds when transitioning between acts.
Music plays at -6 dB by default (not full blast).

## Sound Effects

| File | Trigger |
|------|---------|
| `sfx/click.ogg` | Party button clicked |
| `sfx/purchase.ogg` | Venue, upgrade, VIP, or staff purchased |
| `sfx/secret.ogg` | Secret event spawns on island |
| `sfx/secret_collect.ogg` | Secret event clicked/collected |
| `sfx/achievement.ogg` | Achievement unlocked (wired by AchievementManager) |
| `sfx/narrative.ogg` | Narrative event popup appears |
| `sfx/breaking_news.ogg` | Breaking news modal appears (Act 3 reveal) |

SFX play at 0 dB by default.

## Export Settings

In Godot's import panel, set music tracks to **Stream** mode (not Compressed in-memory) so they can loop properly without memory overhead. SFX can use the default import settings.

Recommended OGG export settings:
- Music: quality 4–5, stereo, loopable (set loop points in Audacity or similar)
- SFX: quality 5–6, stereo or mono depending on source
