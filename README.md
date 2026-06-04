# Perk the Star

Perk the Star is a Godot 4.6 orbital tower defense game. You defend the Sun by placing towers on rotating orbital rings, clearing JSON-authored Astrophage waves, and keeping luminosity above zero.

The project now keeps most reusable systems in C++ GDExtension and leaves `scripts/game/game.gd` as the main Godot gameplay coordinator. That makes the code easier to explain: C++ handles reusable data, math, HUD, audio, and helper systems; GDScript connects the scene, input, drawing, and wave flow.

## Run

1. Open this repository root in Godot, not the nested `game/` folder.
2. Run `project.godot`.
3. Press Play from the main menu.

The game targets a 1920x1080 canvas with expand stretching enabled.

## Controls

- Left click a tower, then left click an orbital slot to build.
- Click a placed tower to upgrade, sell, or inspect stats.
- Number keys `1` through `6` select towers.
- Mouse wheel zooms.
- Right mouse or middle mouse drag pans.
- `W`, `A`, `S`, and `D` pan.
- `Space` or `Enter` starts the next wave.
- `F` fires a charged solar flare during an active wave.
- `Home` or `0` recenters the Sun.
- `Esc` opens the pause menu.
- End screens support Retry and Main Menu.

## Clean File Map

- `project.godot` is the Godot project entry.
- `scenes/` contains playable scenes and UI scenes.
- `scripts/game/game.gd` is the only remaining gameplay GDScript controller.
- `gdextension/src/` contains native C++ gameplay, UI, audio, math, and helper classes.
- `data/waves/` contains editable campaign wave JSON.
- `assets/sprites/backgrounds/` contains active background art.
- `assets/sprites/clean/enemies/` and `assets/sprites/clean/enemies_optimized/` contain active enemy sprites.
- `assets/sprites/clean/towers/` contains active tower sprites.
- `assets/sprites/old/` contains old sprite references kept only for backup.
- `assets/audio/bgm/final/` contains active menu, wave, and boss music.
- `assets/audio/bgm/end.ogg` is the ending track.
- `assets/audio/sfx/` contains active WAV sound effects.
- `assets/audio/old/` contains old or source audio kept only for backup.
- `assets/fonts/` contains UI fonts.
- `assets/ui/` contains UI icons, bars, and cursor art.
- `assets/licenses/` contains asset credits and license text.
- `docs/` contains current explanation docs.
- `docs/presentation/` contains presentation PDFs and the generator script.
- `docs/archive/` contains old notes that are not part of the current code explanation.

## Native Extension

The GDExtension source lives in `gdextension/src`. Godot loads it from `game/bin/perk_the_star.gdextension`, which points to `game/bin/perk_the_star.dll`.

To rebuild on Windows:

```powershell
scons platform=windows target=template_debug arch=x86_64
```

`godot-cpp`, `.godot/`, build intermediates, and SCons cache files are ignored because they can be regenerated.

## Main Native Classes

- `GameCatalogNative` stores balance constants, enemy definitions, tower definitions, ring data, and active asset paths.
- `GameRuntimeNative` stores small runtime helpers such as easing, screen shake, BGM selection, and projectile hit tests.
- `GameOrbitMathNative` handles ring radius, slot angle, tower position, and nearest-slot math.
- `GameTowerLibraryNative` calculates tower stats, costs, refunds, and HUD button data.
- `GameWaveLibraryNative` loads wave JSON and formats Wave Intel text.
- `GameHudNative` owns the gameplay HUD controls, cards, signals, and layout.
- `GameSfxBusNative` loads SFX files and provides generated fallback sounds.
- `GameEffectStoreNative` stores temporary shots, floating text, and visual effects.
- `GameStateNative` stores global match state and saved settings.
- `MusicManagerNative` owns menu music playback.

## Active Assets

Active gameplay assets stay in direct, clearly named folders. Old audio and old sprite references are not deleted, but they are marked by folder:

- old sprites: `assets/sprites/old/`
- old audio: `assets/audio/old/`

Do not reference old folders from gameplay unless intentionally restoring an asset.
