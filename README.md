# Perk the Star

Perk the Star is a Godot 4.6 orbital tower defense game about defending the Sun with satellites that rotate on concentric rings. Campaign mode is a 12-wave Prime mission; Endless mode keeps scaling enemy mix, HP, speed, and pressure; Tech XP turns finished runs into permanent tower-path unlocks.

The project now keeps most reusable systems in C++ GDExtension and leaves `scripts/game/game.gd` as the main Godot gameplay coordinator. That makes the code easier to explain: C++ handles reusable data, math, HUD, audio, and helper systems; GDScript connects the scene, input, drawing, and wave flow.

## Run

**Fresh clone:** build the native extension before running the project. The local `godot-cpp/` dependency and generated `game/bin/perk_the_star.dll` are not included in Git. See [Native Extension](#native-extension).

1. Open this repository root in Godot, not the nested `game/` folder.
2. Run `project.godot`.
3. Click Start Defense, then pick Campaign, Boss Rush, Daily Seed, Draft Defense, Endless, or No-Flare Challenge.

The game targets a 1920x1080 canvas with expand stretching enabled.

## Modes

- Campaign is the fixed 12-wave mission with the Prime boss finale.
- Boss Rush is a four-wave compressed Prime Echo mode with extra starting Sol and boss music from launch.
- Daily Seed is a six-wave date-based challenge with the same enemy mix for everyone on that day.
- Draft Defense is a six-wave contract run: pick one of three random perks before Wave 1, then clear five remixed waves and a Prime-style finale.
- Endless generates scaling waves forever: enemy mix, count, HP, speed, and breach damage rise over time, with clash, formation, and Prime Echo waves mixed in.
- No-Flare Challenge reuses the Prime campaign but disables Solar Flare and pays bonus Tech XP.
- Tech XP is earned at run end and spent on permanent tech tree unlocks that affect tower stats, rewards, flare cadence, and Helios Slingshot.
- The Tech Tree top-right Effects toggle can disable or re-enable unlocked upgrade effects without removing unlocks.
- Perfect Orbit bonuses pay extra Sol and score when a wave is cleared without losing luminosity.
- Fast kill combos add bonus score, and slowed Solar Farmers pay bonus Sol when defeated.
- Best records for each mode are saved in `user://settings.cfg`.

Good next addition: Solar Flare Overcharge.

## Export

Use the Windows Desktop preset in Godot. Generated `.exe`, `.pck`, video, PDF, and course-submission bundles are intentionally ignored; rebuild them from the project when needed.

## Controls

- Left click a tower, then left click an orbital slot to build.
- Click a placed tower to upgrade, sell, or inspect stats.
- Number keys `1` through `6` select towers.
- Mouse wheel zooms.
- Right mouse or middle mouse drag pans.
- `W`, `A`, `S`, and `D` pan.
- `Space` or `Enter` starts the next wave.
- `F` fires a charged solar flare during an active wave.
- `T` opens the tech tree overlay.
- `Home` or `0` recenters the Sun.
- `Esc` opens the pause menu.
- End screens support Retry, Tech Tree, and Main Menu.

## Clean File Map

- `project.godot` is the Godot project entry.
- `scenes/` contains playable scenes and UI scenes.
- `scenes/ui/tech_tree_overlay.tscn` is the current in-game tech tree overlay.
- `scripts/game/game.gd` is the only remaining gameplay GDScript controller.
- `gdextension/src/` contains native C++ gameplay, UI, audio, math, and helper classes.
- `data/waves/` contains editable campaign wave JSON.
- `assets/sprites/backgrounds/` contains active background art.
- `assets/sprites/clean/enemies/` and `assets/sprites/clean/enemies_optimized/` contain active enemy sprites.
- `assets/sprites/clean/towers/` contains active tower sprites.
- `assets/audio/bgm/final/` contains active menu, wave, and boss music.
- `assets/audio/bgm/end.ogg` is the ending track.
- `assets/audio/sfx/` contains active WAV sound effects.
- `assets/fonts/` contains UI fonts.
- `assets/ui/` contains UI icons, bars, and cursor art.
- `assets/licenses/` contains asset credits and license text.
- `docs/` contains current explanation and presentation source docs.
- `docs/presentation/` contains presentation notes and the generator script.

## Native Extension

The GDExtension source lives in `gdextension/src`. Godot loads it from `game/bin/perk_the_star.gdextension`, which points to `game/bin/perk_the_star.dll`.

The rebuild command expects the `godot-cpp` headers, generated headers, and matching Windows debug x86_64 binding library to exist already. `SConstruct` builds the game DLL; it does not build `godot-cpp`.

To rebuild on Windows:

```powershell
scons platform=windows target=template_debug arch=x86_64
```

`godot-cpp`, `.godot/`, build intermediates, generated DLLs, exported game bundles, generated media/PDFs, and SCons cache files are ignored because they can be regenerated.

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

## Repo Cleanup

Backup-only media, archived roadmap notes, generated PDFs, exported builds, and built DLLs are not kept in git. If a generated file is needed again, rebuild it from source instead of committing it.
