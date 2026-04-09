# Build Guide — The Island

Three export targets are configured: Windows Desktop (Steam), macOS, and Web (itch.io).
Export templates must be installed in the Godot editor before any export will work.

---

## Prerequisites

### Install Export Templates

1. Open the project in Godot 4.6
2. Editor menu → Export → Manage Export Templates
3. Click "Download and Install" for the current Godot version
4. Wait for the download to complete

Templates are installed once per Godot version and shared across all projects.

---

## Building from the Godot Editor

1. Open the project in Godot 4.6
2. Project menu → Export
3. Select the desired preset from the left panel
4. Click "Export Project" (release) or "Export Debug" (debug)
5. Output lands in the configured path (see below)

| Preset | Output |
|--------|--------|
| Windows Desktop | `builds/windows/TheIsland.exe` |
| macOS | `builds/mac/TheIsland.dmg` |
| Web | `builds/web/index.html` |

---

## Building from the CLI (Headless)

Use the Godot binary with `--headless --export-release` for CI/CD or scripted builds.
Replace `<godot>` with the path to your Godot 4.6 executable.

### Windows

```bash
<godot> --headless --export-release "Windows Desktop" builds/windows/TheIsland.exe
```

### macOS

```bash
<godot> --headless --export-release "macOS" builds/mac/TheIsland.dmg
```

### Web

```bash
<godot> --headless --export-release "Web" builds/web/index.html
```

On Windows the Godot binary is typically:
`C:/Users/<user>/AppData/Local/Programs/Godot/Godot_v4.6-stable_win64.exe`

---

## Uploading to itch.io

After building the Web target:

```bash
butler push builds/web theisland/the-island:html5
```

Install Butler: https://itch.io/docs/butler/

---

## Notes

- `builds/` is git-tracked (via `.gitkeep`) but the actual export output is gitignored.
- Code signing for Windows and macOS is disabled (`codesign/enable=false`). Enable and configure when preparing a Steam or App Store release.
- macOS notarization is also disabled. Required for distribution outside Steam on macOS 10.15+.
- The Web build uses `canvas_resize_policy=2` (Expand) — the canvas fills the browser window.
