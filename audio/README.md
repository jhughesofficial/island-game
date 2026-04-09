# Audio Files

## Music (ambient loops) — NEEDED

Music must be **OGG Vorbis** (.ogg) for streaming + looping.
Source via [Suno Pro](https://suno.com) or [Beatoven.ai](https://www.beatoven.ai).

| File | Act | Mood | Status |
|------|-----|------|--------|
| `music/act1_ambient.ogg` | Act 1 (< $1M lifetime) | Calm, tropical, lounge/bossa | ❌ Missing |
| `music/act2_tension.ogg` | Act 2 ($1M – $50M lifetime) | Minor key, slightly unsettling | ❌ Missing |
| `music/act3_danger.ogg` | Act 3 (≥ $50M lifetime) | Tense, crime drama, ominous | ❌ Missing |

Loops crossfade over 1.5s between acts. Music plays at -6 dB.

## Sound Effects — DONE (Kenney CC0)

WAV format. All 7 files sourced from [kenney.nl](https://kenney.nl) interface sounds pack (CC0).

| File | Source | Trigger |
|------|--------|---------|
| `sfx/click.wav` | click_001.wav | Party button clicked |
| `sfx/purchase.wav` | confirmation_001.wav | Venue/upgrade/VIP/staff purchased |
| `sfx/secret.wav` | pluck_001.wav | Secret event spawns on island |
| `sfx/secret_collect.wav` | drop_001.wav | Secret event collected |
| `sfx/achievement.wav` | maximize_001.wav | Achievement unlocked |
| `sfx/narrative.wav` | open_001.wav | Narrative event popup |
| `sfx/breaking_news.wav` | glitch_001.wav | Act 3 breaking news reveal |

## Export Settings

In Godot's import panel, set music tracks to **Stream** mode (not Compressed in-memory) so they can loop properly without memory overhead. SFX can use the default import settings.

Recommended OGG export settings:
- Music: quality 4–5, stereo, loopable (set loop points in Audacity or similar)
- SFX: quality 5–6, stereo or mono depending on source
