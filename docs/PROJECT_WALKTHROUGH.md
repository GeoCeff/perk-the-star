# Project Walkthrough

This is the short explanation file for a demo or professor defense.

## Short Explanation

Perk the Star is a Godot 4.6 orbital tower defense game. The player protects the Sun by placing towers on rotating rings. Enemies move inward, towers fire automatically, and the player wins by clearing all waves before luminosity reaches zero.

## Folder Map

- `scenes/` contains Godot scenes.
- `scenes/ui/` contains the HUD, pause menu, settings, and codex scenes.
- `scripts/game/game.gd` is the main GDScript gameplay coordinator.
- `gdextension/src/` contains the C++ systems used by Godot through GDExtension.
- `data/waves/` contains JSON wave files.
- `assets/` contains active sprites, audio, UI, fonts, backgrounds, and licenses.
- `docs/presentation/` contains presentation files.

## Scene Flow

1. `project.godot` starts at `scenes/main_menu.tscn`.
2. Native main-menu button classes open the game, codex, settings, or quit.
3. `scenes/game.tscn` runs `scripts/game/game.gd`.
4. `game.gd` creates native helpers, loads assets, loads wave data, and builds the HUD.
5. `GameHudNative` emits signals such as start wave, tower selected, upgrade, sell, retry, and menu.
6. `game.gd` receives those signals, updates gameplay, then sends one state dictionary back to the HUD.

## Main GDScript

- `scripts/game/game.gd`
  Coordinates runtime gameplay. It handles input, wave spawning, tower placement, enemy updates, drawing, music calls, SFX calls, and HUD updates.

This file is intentionally still GDScript because it is close to Godot scene flow: input events, drawing calls, scene loading, and signal wiring are simpler to explain and maintain in Godot's own script language.

## Main C++ Classes

- `GameCatalogNative`
  Stores constants, enemy stats, tower stats, ring data, and active asset paths.

- `GameRuntimeNative`
  Stores small reusable helpers: easing, screen shake, BGM selection, projectile hit tests, and enemy lookup by UID.

- `GameOrbitMathNative`
  Handles orbital geometry: ring radius, slot angle, slot position, tower position, burrower position, and nearest build slot.

- `GameTowerLibraryNative`
  Calculates tower runtime stats, upgrade cost, sell refund, tower button text, and tower management-card data.

- `GameWaveLibraryNative`
  Loads JSON waves, builds spawn queues, and formats Wave Intel text.

- `GameHudNative`
  Owns HUD labels, buttons, tower cards, end-state cards, hover signals, and responsive layout.

- `GameSfxBusNative`
  Loads WAV sound effects from `assets/audio/sfx/` and generates fallback tones when a file is missing.

- `GameEffectStoreNative`
  Stores short-lived shot lines, floating text, and visual effects, then removes them when their timers expire.

- `GameStateNative`
  Stores global match state, luminosity, score, credits, phase, tutorial settings, music settings, and auto-start settings.

- `MusicManagerNative`
  Keeps menu music playing across menu, settings, and codex screens.

## Gameplay Loop

The main loop in `game.gd` is:

1. Read camera and input state.
2. Spawn enemies from the active wave JSON.
3. Move towers around their rings.
4. Let towers find targets and fire.
5. Move enemies toward the Sun.
6. Update physics projectiles.
7. Apply damage, rewards, effects, and special enemy behavior.
8. Check wave clear, victory, or game over.
9. Update the HUD state dictionary.
10. Redraw only when gameplay, camera, or effects need it.

## Why Some Code Stayed In GDScript

Godot scene orchestration is easiest in GDScript. Input events, `draw_*` calls, scene loading, signal wiring, and dictionaries from the editor are direct and readable there.

C++ is used where it helps most: shared logic, math helpers, catalogs, wave formatting, HUD code, audio helpers, and state systems.

## How Towers Work

Towers are dictionaries in the `towers` array. Each tower stores type, ring, slot, angle, fire timer, level, and Sol spent. Base stats come from `GameCatalogNative`; upgrade math comes from `GameTowerLibraryNative`.

## How Enemies Work

Enemies are dictionaries in the `enemies` array. Each enemy stores UID, variant, position, HP, speed, damage, reward, radius, sprite data, and temporary timers. The UID lets physics projectiles keep tracking a target even after enemies move.

## Wave Data

The files in `data/waves/` are JSON. Designers can tune waves without recompiling C++. `GameWaveLibraryNative` reads them and gives `game.gd` a normalized spawn queue.

## UI Pattern

1. HUD buttons emit signals.
2. `game.gd` changes gameplay state.
3. `game.gd` builds one display dictionary.
4. `GameHudNative` updates labels, bars, buttons, and cards.

This keeps combat rules out of the HUD.

## Audio Pattern

Active BGM lives in `assets/audio/bgm/final/`:

- `main_menu.ogg` for menus.
- `wave_01.ogg` for waves 1-4.
- `wave_02.ogg` for waves 5-8.
- `wave_03.ogg` for waves 9-11.
- `BOSS.ogg` for wave 12.
- `assets/audio/bgm/end.ogg` for endings.

Active SFX lives in `assets/audio/sfx/`. Old backup audio is not kept in git.

## What To Say If Asked About Optimization

- Most reusable systems were moved to C++ GDExtension.
- `game.gd` now focuses on scene flow instead of storing every helper function.
- Balance and active asset paths are centralized in `GameCatalogNative`.
- Orbit math is centralized in `GameOrbitMathNative`.
- Tower stat calculations are centralized in `GameTowerLibraryNative`.
- Wave loading and Wave Intel text are centralized in `GameWaveLibraryNative`.
- HUD behavior is native and receives one state dictionary.
- Temporary effects expire automatically through `GameEffectStoreNative`.
- SFX players are pooled instead of creating audio nodes during combat.
- Old assets are separated into old folders so active files are easy to find.
