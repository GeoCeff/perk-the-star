# File System Guide

Use this as the quick map when explaining the repository.

## Root

- `project.godot` is the Godot project file.
- `README.md` is the main setup and structure guide.
- `SConstruct` builds the C++ GDExtension.
- `game/bin/` contains the built GDExtension files loaded by Godot.
- `godot-cpp/` is a local build dependency and is ignored by git.

## Game Content

- `scenes/` contains Godot scenes.
- `scripts/game/game.gd` contains the remaining gameplay GDScript.
- `gdextension/src/` contains the native C++ game systems.
- `data/waves/` contains the JSON campaign waves.

## Assets

- `assets/sprites/backgrounds/` active background images.
- `assets/sprites/clean/enemies/` active enemy sprites.
- `assets/sprites/clean/enemies_optimized/` active optimized enemy animation frames.
- `assets/sprites/clean/towers/` active tower sprites.
- `assets/audio/bgm/final/` active menu, wave, and boss music.
- `assets/audio/bgm/end.ogg` active ending music.
- `assets/audio/sfx/` active sound effects.
- `assets/fonts/` fonts used by the UI.
- `assets/ui/` active icons, bars, and cursor assets.
- `assets/licenses/` third-party credits.

## Docs

- `docs/PROJECT_WALKTHROUGH.md` is the professor-friendly explanation.
- `docs/ASSET_STYLE.md` explains visual style.
- `docs/presentation/` contains presentation notes and the generator script.

## Generated Or Ignored

- `.godot/` is Godot editor cache.
- `.sconsign.dblite` is SCons cache.
- `*.obj`, `*.lib`, and `*.exp` are build intermediates.
- `game/bin/*.dll` is the generated native extension binary.
- presentation PDFs are generated from `docs/presentation/generate_presentation.py`.

These can be regenerated and should not be explained as project source.
