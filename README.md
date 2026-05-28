# Perk the Star

Godot 4.6 tower defense prototype. Defend the sun by placing orbiting towers, clearing JSON-authored waves, and keeping luminosity above zero.

## Current Development Flow

1. Open the repository root in Godot, not the nested `game/` folder.
2. Run the project from `project.godot`.
3. Press Play from the main menu to enter `scenes/game.tscn`.

## Current Scene Structure

- `scenes/main_menu.tscn` is the main menu and starts the defense scene.
- `scenes/game.tscn` is the canonical gameplay scene.
- `scenes/ui/game_hud.tscn` contains the editable gameplay HUD.
- `scenes/ui/settings_overlay.tscn` contains the full-screen settings scene.
- `scenes/ui/mission_codex.tscn` opens the full-screen mission codex scene.
- `scripts/game/game.gd` owns gameplay state, waves, combat, drawing, and music.
- `scripts/ui/game_hud.gd` owns HUD labels, buttons, and HUD signals.
- `data/waves/wave_01.json` through `wave_12.json` define the campaign waves.

## Audio Settings

Music can be toggled or adjusted from the settings screen. The setting is saved to `user://settings.cfg` and is shared by main menu, mission codex, settings, wave, and ending music.

## Native Extension

The GDExtension source lives in `gdextension/src`. To rebuild it on Windows, install SCons and place `godot-cpp` at the repository root, then run:

```powershell
scons platform=windows target=template_debug arch=x86_64
```

The build outputs to `game/bin/perk_the_star.dll`, which is loaded by `game/bin/perk_the_star.gdextension`.
