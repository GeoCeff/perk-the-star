# Project Walkthrough

This file is for explaining the project quickly during a demo or defense. It focuses on what each major folder, scene, and script is responsible for.

## Short Explanation

Perk the Star is a Godot 4.6 orbital tower defense game. The player protects the sun by placing towers on rotating orbital rings. Enemies move inward, towers fire automatically, and the player wins by clearing the wave set before the sun's luminosity reaches zero.

## Folder Map

- `scenes/` contains the Godot scenes that appear in the game.
- `scenes/ui/` contains reusable UI scenes such as the HUD, pause menu, settings, and codex.
- `scripts/game/` contains gameplay code and game balance data.
- `scripts/ui/` contains UI behavior, shared theme helpers, and visual frame/background effects.
- `scripts/autoload/` contains global systems loaded by Godot, mainly `GameState` and `MusicManager`.
- `data/waves/` contains the JSON wave files. Changing these changes what enemies spawn.
- `assets/` contains sprites, fonts, audio, icons, backgrounds, licenses, and some old assets kept for backup/reference.
- `docs/` contains project notes and explanation files.

We are not deleting old assets yet. Some unused or older files are intentionally kept so we can compare versions, recover older sprites, or replace art safely later.

## Scene Flow

1. `project.godot` starts at `scenes/main_menu.tscn`.
2. `scripts/ui/main_menu.gd` styles the menu and sends the player to the game.
3. `scenes/game.tscn` runs `scripts/game/game.gd`.
4. `game.gd` loads the HUD scene, wave data, textures, music, and gameplay state.
5. The HUD scene emits signals such as "start wave", "tower selected", and "menu".
6. `game.gd` receives those signals, updates gameplay, then sends a simple state dictionary back to the HUD for display.
7. Pause and end-state overlays keep menu, settings, controls, retry, and main-menu actions separate from combat rules.

## Main Scripts

- `scripts/game/game.gd`
  The main gameplay controller. It handles input routing, wave spawning, tower placement, targeting, enemy movement, combat, drawing calls, end states, and HUD updates.

- `scripts/game/game_catalog.gd`
  Static data for the game: tower stats, enemy stats, ring layout, active sprite paths, and constants like sun radius. This keeps balance numbers away from the runtime logic.

- `scripts/game/game_view_controller.gd`
  Camera helper. It owns pan, zoom, edge scroll, WASD movement, viewport size caching, and screen/world coordinate conversion.

- `scripts/game/game_orbit_math.gd`
  Orbital geometry helper. It calculates ring radius, slot angle, tower position, burrower position, nearest build slot, and the ring summary.

- `scripts/game/game_effect_store.gd`
  Effect storage helper. It stores short-lived shot/effect dictionaries and removes them when their timers expire.

- `scripts/game/game_wave_library.gd`
  Wave JSON helper. It loads wave files, normalizes event data, builds spawn queues, and formats Wave Intel text.

- `scripts/game/game_tower_library.gd`
  Tower math helper. It calculates upgrade stats, upgrade costs, sell refunds, tower button text, and management-card readouts.

- `scripts/game/game_sfx_bus.gd`
  Temporary sound helper. It creates small procedural feedback sounds once, then plays them from a reusable audio pool.

- `scripts/autoload/game_state.gd`
  Global match state and saved settings. It stores luminosity, Sol credits, score, current wave, music settings, tutorial completion, screen shake, and Auto Start.

- `scripts/ui/game_hud.gd`
  The gameplay HUD controller. It does not decide combat rules; it displays values and emits signals when buttons are clicked.

- `scripts/ui/space_theme.gd`
  Shared UI styling. Fonts, colors, button styles, panel styles, scrollbars, sliders, and icon setup live here so menus and gameplay use the same visual style.

- `scripts/ui/tutorial_overlay.gd`
  Optional first-run tutorial overlay. It asks the HUD and game for target rectangles, then draws highlights and arrows.

- `scripts/ui/main_menu_fx.gd` and `scripts/ui/hud_panel_fx.gd`
  Lightweight drawing scripts for animated sci-fi frame ornaments and screen polish.

## Gameplay Loop

The main loop in `game.gd` is:

1. Read input and camera movement, including drag, edge hover, mouse wheel zoom, and WASD panning.
2. If a wave is active, spawn enemies from the current wave JSON.
3. Move towers around their orbital rings.
4. Let towers find targets and fire.
5. Move enemies toward the sun.
6. Apply damage, rewards, health bars, death effects, and special enemy behavior.
7. Check whether the wave is cleared or whether the game is over.
8. Play small feedback sounds for important actions such as shots, hits, wave clears, breaches, victory, and failure.
9. Send updated values to the HUD.
10. Redraw only when something changed or an animation/effect is active.

## How Towers Work

Towers are stored as dictionaries in the `towers` array. Each tower remembers:

- its type, such as `photon_splitter`
- which ring and slot it occupies
- its current orbital angle
- its fire cooldown
- its level and total Sol spent

The tower's base stats come from `GameCatalog.TOWER_CONFIGS`. Runtime upgrades are calculated in `game_tower_library.gd` so we do not need separate copied data for every level.

## How Enemies Work

Enemies are stored as dictionaries in the `enemies` array. Each enemy remembers:

- its type, such as `drifter` or `prime`
- current position
- current and max HP
- speed, damage, reward, radius, sprite size, and color
- temporary timers such as slow, hit flash, and heal flash

Enemy base stats come from `GameCatalog.ENEMY_CONFIGS`. The wave JSON only needs to say which type spawns, how many, and how fast.

## Wave Data

The files in `data/waves/` are JSON so we can tune the campaign without editing gameplay logic. `game_wave_library.gd` loads them, normalizes missing/null events, and builds the spawn queue used by `game.gd`.

## UI Pattern

The UI mostly follows this pattern:

1. HUD buttons emit signals.
2. `game.gd` receives the signal and changes game state.
3. `game.gd` builds a dictionary of display values.
4. `game_hud.gd` reads that dictionary and updates labels, buttons, bars, and cards.

This keeps game decisions in the gameplay script and UI display work in the HUD script.

## Audio Pattern

The active background music lives in `assets/audio/bgm/final/`. `main_menu.wav` plays on menu screens, `wave_01.wav` covers waves 1-4, `wave_02.wav` covers waves 5-8, `wave_03.wav` covers waves 9-11, and `BOSS.wav` plays on wave 12. Short feedback sounds are still routed through `game_sfx_bus.gd`, so they can be replaced later without changing the gameplay functions that call them.

## Demo Script

1. Start from the main menu and point out the shared sci-fi theme: animated nebula, cyan/gold frames, and compact mission-terminal typography.
2. Open Settings to show saved music volume, screen shake, and optional tutorial replay.
3. Start the game and show the tutorial overlay if it is queued; otherwise explain that it only appears once unless replay is requested.
4. Show camera controls: mouse wheel zoom, WASD pan, edge hover pan, drag pan, and Center Sun.
5. Build towers during a wave to show that the Tower Bay stays usable while combat is active.
6. Click a placed tower to show upgrade cost, exact stat gains, final stats, and sell refund.
7. Point to Wave Intel before the next wave and explain warning tags and counter hints.
8. Use the pause menu to show Codex, Settings, Controls, Retry Run, Main Menu, and Back.
9. On victory or failure, show the end card with rank, stats, Retry Run, and Main Menu.

## What To Say If Asked About Optimization

- Balance numbers are centralized in `game_catalog.gd`.
- Camera movement, orbit math, effect storage, wave parsing, tower math, and prototype SFX each live in their own helper files instead of being buried in `game.gd`.
- The HUD gets one update dictionary instead of directly reading many gameplay variables.
- Effects are stored in small arrays with a time-to-live, then removed when finished.
- Short SFX are generated once into a small player pool, so combat does not create audio nodes every frame.
- The view only redraws when gameplay, camera, or animation state needs it.
- Shared theme code prevents repeating the same button and panel styling in every menu.
- Old assets are kept for now so art changes can be compared safely before final cleanup.
