# Perk the Star

Perk the Star is a Godot 4.6.x orbital tower defense prototype. You defend the sun by placing towers on rotating orbital rings, clearing JSON-authored Astrophage waves, and keeping luminosity above zero.

The current look is a dark sci-fi operations interface: animated nebula backgrounds, cyan/gold framed panels, compact HUD controls, clean tower sprites, and restored organic Astrophage enemy sprites. See `docs/ASSET_STYLE.md` when generating or adding matching art.

## Running the Project

1. Open this repository root in Godot, not the nested `game/` folder.
2. Run the project from `project.godot`.
3. Press Play from the main menu to enter `scenes/game.tscn`.

The game targets a 1920x1080 canvas with expand stretching enabled.

## Controls

- Left click a tower, then left click a visible orbital slot to build between waves.
- Mouse wheel zooms in and out around the cursor.
- Right mouse or middle mouse drag pans the view.
- Hover near screen edges to pan in that direction.
- Press `Home` or `0`, or use the `Center Sun` HUD button, to recenter the view.
- The in-game `Menu` button opens a themed pause overlay with Mission Codex, Settings, Main Menu, and Back.

## Project Map

- `scenes/main_menu.tscn` is the themed main menu.
- `scenes/game.tscn` is the canonical gameplay scene.
- `scenes/ui/game_hud.tscn` is the editable gameplay HUD.
- `scenes/ui/game_pause_menu.tscn` is the in-game pause overlay.
- `scenes/ui/settings_overlay.tscn` is the full-screen settings overlay.
- `scenes/ui/mission_codex.tscn` is the main-menu mission codex entry scene.
- `scenes/ui/codex.tscn` is the reusable mission codex content used by menu and pause flows.
- `scripts/game/game.gd` owns runtime gameplay flow, input, drawing, waves, combat, and music.
- `scripts/game/game_catalog.gd` owns static balance data, ring layout, tower definitions, enemy definitions, and active sprite paths.
- `scripts/ui/space_theme.gd` centralizes shared fonts, colors, cursor styling, and sci-fi panel/button helpers.
- `scripts/ui/game_hud.gd` owns HUD labels, buttons, tower hover cards, and HUD signals.
- `data/waves/wave_01.json` through `data/waves/wave_12.json` define the campaign waves.

## Asset Layout

- `assets/sprites/backgrounds/menu_nebula.png` and `battle_nebula_hq.png` are the active menu and gameplay backgrounds.
- `assets/sprites/enemies/` contains the active Astrophage enemy sprites.
- `assets/sprites/clean/towers/` contains the active generated tower sprites.
- `assets/fonts/` contains the UI/display fonts.
- `assets/ui/` contains shared reticle, bar, and icon assets.
- `assets/audio/bgm/` contains menu, wave, and ending music.
- `assets/licenses/` contains third-party asset credits and license files.

## Audio Settings

Music can be toggled or adjusted from Settings. The setting is saved to `user://settings.cfg` and is shared by main menu, mission codex, settings, wave, and ending music.

## Native Extension

The GDExtension source lives in `gdextension/src`. The runtime extension is loaded from `game/bin/perk_the_star.gdextension`, which points to `game/bin/perk_the_star.dll`.

To rebuild on Windows, install SCons and place `godot-cpp` at the repository root, then run:

```powershell
scons platform=windows target=template_debug arch=x86_64
```

Build intermediates and editor cache files are intentionally ignored. Keep the root `project.godot` as the source of truth.
