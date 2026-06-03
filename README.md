# Perk the Star

Perk the Star is a Godot 4.6.x orbital tower defense prototype. You defend the sun by placing towers on rotating orbital rings, clearing JSON-authored Astrophage waves, and keeping luminosity above zero.

The current look is a dark sci-fi operations interface: animated nebula backgrounds, cyan/gold framed panels, compact HUD controls, clean tower sprites, and restored organic Astrophage enemy sprites. See `docs/ASSET_STYLE.md` when generating or adding matching art, and `docs/PROJECT_WALKTHROUGH.md` for a quick explanation of the folders, scenes, scripts, and gameplay loop.

## Running the Project

1. Open this repository root in Godot, not the nested `game/` folder.
2. Run the project from `project.godot`.
3. Press Play from the main menu to enter `scenes/game.tscn`.

The game targets a 1920x1080 canvas with expand stretching enabled.

## Controls

- Left click a tower, then left click a visible orbital slot to build before or during waves.
- Click a placed tower to open its management panel for upgrade, sell, and live stat readouts.
- Number keys `1` through `6` select towers from the Tower Bay.
- Floating Sol readouts show tower spending, enemy rewards, and wave-clear payouts.
- Enemy HUD tags call out key combat states such as `SLOW`, `MIMIC`, `ABSORB`, `SHELL`, and `OPEN`.
- Mouse wheel zooms in and out around the cursor.
- Right mouse or middle mouse drag pans the view.
- `W`, `A`, `S`, and `D` pan the view around the star.
- Hover near screen edges to pan in that direction.
- Press `Space` or `Enter` to start the next wave when ready.
- Toggle `Auto Start` beside Start Wave to launch ready waves after a short countdown. This preference is saved.
- Press `F` during an active wave to fire a charged solar flare.
- Press `Home` or `0`, or use the `Center Sun` HUD button, to recenter the view.
- Press `Esc` to open the in-game pause overlay.
- The in-game `Menu` button opens a themed pause overlay with Mission Codex, Settings, Controls, Retry Run, Main Menu, and Back.
- Victory and game-over screens include Retry Run and Main Menu buttons. `R` retries and `M` returns to menu on those end screens.

The first gameplay launch shows an optional mission training overlay with diagram-style arrows pointing to the live HUD and board. Finishing or skipping it saves completion in `user://settings.cfg`, so it will not replay automatically. Settings can queue the tutorial again for the next gameplay launch.

## Project Map

- `scenes/main_menu.tscn` is the themed main menu.
- `scenes/game.tscn` is the canonical gameplay scene.
- `scenes/ui/game_hud.tscn` is the editable gameplay HUD.
- `scenes/ui/game_pause_menu.tscn` is the in-game pause overlay.
- `scenes/ui/settings_overlay.tscn` is the full-screen settings overlay.
- `scenes/ui/mission_codex.tscn` is the main-menu mission codex entry scene.
- `scenes/ui/codex.tscn` is the reusable mission codex content used by menu and pause flows.
- `scripts/game/game.gd` owns runtime gameplay flow, input routing, drawing calls, combat, and HUD updates.
- `scripts/game/game_catalog.gd` owns static balance data, ring layout, tower definitions, enemy definitions, and active sprite paths.
- `scripts/game/game_view_controller.gd` owns pan, zoom, viewport cache, and screen/world coordinate conversion.
- `scripts/game/game_orbit_math.gd` owns ring radius, slot angle, orbital position, and ring summary math.
- `scripts/game/game_effect_store.gd` owns short-lived shot/effect arrays and cleanup.
- `scripts/game/game_wave_library.gd` loads wave JSON and formats Wave Intel readouts.
- `scripts/game/game_tower_library.gd` calculates tower stats, upgrade costs, refunds, and Tower Bay text.
- `scripts/game/game_sfx_bus.gd` generates temporary prototype SFX and reuses a small audio-player pool.
- `scripts/ui/space_theme.gd` centralizes shared fonts, colors, cursor styling, and sci-fi panel/button helpers.
- `scripts/ui/game_hud.gd` owns HUD labels, buttons, tower hover cards, and HUD signals.
- `scripts/ui/tutorial_overlay.gd` owns the optional first-run mission training diagrams.
- `data/waves/wave_01.json` through `data/waves/wave_12.json` define the campaign waves.
- `docs/PROJECT_WALKTHROUGH.md` is the short presentation guide for explaining the project structure.

## Asset Layout

- `assets/sprites/backgrounds/menu_nebula.png` and `battle_nebula_hq.png` are the active menu and gameplay backgrounds.
- `assets/sprites/enemies/` contains the active Astrophage enemy sprites.
- `assets/sprites/clean/towers/` contains the active generated tower sprites.
- `assets/fonts/` contains the UI/display fonts.
- `assets/ui/` contains shared reticle, bar, and icon assets.
- `assets/audio/bgm/final/` contains the active main menu, wave-range, and boss music.
- `assets/licenses/` contains third-party asset credits and license files.

## Audio And Feedback

Music can be toggled or adjusted from Settings. The setting is saved to `user://settings.cfg` and is shared by main menu, mission codex, settings, wave, boss, and ending music.

The active BGM routing is `main_menu.wav` for menus, `wave_01.wav` for waves 1-4, `wave_02.wav` for waves 5-8, `wave_03.wav` for waves 9-11, and `BOSS.wav` for wave 12.

Gameplay feedback sounds are generated in `scripts/game/game_sfx_bus.gd` for the current prototype. These temporary SFX cover buttons, tower placement, upgrades, selling, shots, hits, solar flare, wave clear, victory, failure, and sun breach feedback until final SFX assets are added.

## Game Feel Settings

Settings can disable screen shake while keeping impact flashes, breach pulses, tower placement previews, and other visual feedback active. Tutorial completion, replay state, and the in-game auto-start wave toggle also live in `user://settings.cfg`.

## Native Extension

The GDExtension source lives in `gdextension/src`. The runtime extension is loaded from `game/bin/perk_the_star.gdextension`, which points to `game/bin/perk_the_star.dll`.

To rebuild on Windows, install SCons and place `godot-cpp` at the repository root, then run:

```powershell
scons platform=windows target=template_debug arch=x86_64
```

Build intermediates and editor cache files are intentionally ignored. Keep the root `project.godot` as the source of truth.
