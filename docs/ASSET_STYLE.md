# Asset Style Guide

Use this guide when generating or sourcing new assets for Perk the Star.

## Overall Theme

Dark sci-fi orbital defense around a living star. The presentation should feel like a clean space-operations console layered over a deep nebula field: precise, luminous, technical, and slightly tense.

## UI Direction

- Primary colors: deep near-black panels, electric cyan borders, warm solar gold accents, pale blue-white text.
- Shapes: thin sci-fi frames, corner notches, restrained glow, compact panels, and dense readable HUD layout.
- Typography: angular display labels for headings/buttons, readable sci-fi body text for descriptions.
- Avoid bulky cards, decorative gradients, soft rounded marketing UI, and large cartoon panels.

## Sprite Direction

- Towers should read as clean tactical modules or probes: sharp silhouettes, transparent backgrounds, centered pivots, readable at small HUD size, and accented with their tower color.
- Enemies should read as Astrophage organisms: alien, organic, asymmetrical, solar-parasite shapes, not cute or mascot-like.
- Sun/ring visuals should feel luminous and astronomical rather than cartoonish: layered glow, subtle atmosphere, clean orbital guides, and restrained outlines.
- New sprites should keep enough contrast to read over a dark blue/purple nebula background.
- Active sprites belong in `assets/sprites/clean/` or `assets/sprites/backgrounds/`.
- Backup-only old sprites should not be committed to git.

## Audio Direction

- Active BGM belongs in `assets/audio/bgm/final/` plus `assets/audio/bgm/end.ogg`.
- Active SFX belongs in `assets/audio/sfx/`.
- Backup-only old BGM and WAV source files should not be committed to git.

## Prompt Template

```text
Dark sci-fi orbital tower defense asset for Perk the Star, transparent background, centered game sprite, crisp silhouette, luminous cyan and warm solar gold accents, clean tactical space-operations style, readable at small size, high contrast over a deep nebula background, not cartoonish, not mascot-like, no text, no UI frame.
```

For Astrophage enemies, add:

```text
Alien solar parasite organism, organic asymmetrical body, threatening but readable silhouette, subtle red/orange bioluminescent energy, no cute facial features.
```

For towers, add the tower role and color:

```text
Compact orbital defense module, mechanical probe/cannon silhouette, accent color [tower color], designed to orbit a star.
```
