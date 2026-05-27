# Perk the Star

Godot 4.6 tower defense prototype. Defend the sun by placing orbiting towers, clearing JSON-authored waves, and keeping luminosity above zero.

## Current Development Flow

1. Open the repository root in Godot, not the nested `game/` folder.
2. Run the project from `project.godot`.
3. Press Play from the main menu to enter `scenes/game.tscn`.

## Native Extension

The GDExtension source lives in `gdextension/src`. To rebuild it on Windows, install SCons and place `godot-cpp` at the repository root, then run:

```powershell
scons platform=windows target=template_debug arch=x86_64
```

The build outputs to `game/bin/perk_the_star.dll`, which is loaded by `game/bin/perk_the_star.gdextension`.
