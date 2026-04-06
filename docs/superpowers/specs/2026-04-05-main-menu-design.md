# Main Menu Design Spec

**Goal:** Add a main menu as the game's startup screen so players can choose New Game, Continue, or Quit instead of always resuming mid-session.

**Architecture:** A new `MainMenu.tscn` becomes the project's startup scene. It reads `user://save.json` to determine whether a save exists. The existing `Main.tscn` and `GameState` are unchanged — GameState still auto-loads save on `_ready()`, so Continue just loads `Main.tscn` normally while New Game deletes the save file first.

---

## Scenes & Scripts

| File | Purpose |
|------|---------|
| `scenes/MainMenu.tscn` | New startup scene |
| `scripts/components/main_menu.gd` | Menu logic |
| `project.godot` | Change `run/main_scene` to `MainMenu.tscn` |
| `scenes/components/GameOver.tscn` | Add "Main Menu" button |
| `scripts/components/game_over.gd` | Wire "Main Menu" button → MainMenu.tscn |

---

## MainMenu Layout

Centered `VBoxContainer` on a dark background (`ColorRect` full-rect, color `#0d0d0d`):

1. **Title label** — "The Island" — large serif-style, gold color `#c9a84c`
2. **Subtitle label** — "A Private Resort Management Sim" — small, muted gray
3. **Spacer**
4. **New Game button** — always enabled; deletes save then loads Main.tscn
5. **Continue button** — enabled only if `user://save.json` exists; loads Main.tscn
6. **Quit button** — calls `get_tree().quit()`

---

## Logic

### Save detection
```gdscript
var has_save := FileAccess.file_exists("user://save.json")
continue_btn.disabled = not has_save
```

### New Game
```gdscript
DirAccess.remove_absolute(OS.get_user_data_dir() + "/save.json")
get_tree().change_scene_to_file("res://scenes/Main.tscn")
```

### Continue
```gdscript
get_tree().change_scene_to_file("res://scenes/Main.tscn")
```

### Quit
```gdscript
get_tree().quit()
```

---

## Game Over → Main Menu

`GameOver.tscn` adds a **Main Menu** button below the existing Restart button.
`game_over.gd` connects it:
```gdscript
get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
```

---

## Styling

- Background: `ColorRect` full-rect, `#0d0d0d`
- Title font size: 48, color `#c9a84c`
- Subtitle font size: 14, color `#888888`
- Buttons: `custom_minimum_size = Vector2(200, 48)`, centered
- Button separation: 12px
