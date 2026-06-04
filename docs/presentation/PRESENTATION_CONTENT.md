# Perk the Star — Presentation Content
**Group H | CMSC 21-A | Geo Ceff Gabaisen & Dexter Juevesano**  
**Instructor:** Ryan Ciriaco Dulaca  
**Command phrase:** *Defend me, defend me! — Oa ka Perk!*

> Concise slide copy + speaker notes + Q&A reference.  
> Reflects the **current Godot 4.6 build**, not the original SFML proposal alone.  
> Generated PDFs are not committed; regenerate them from `docs/presentation/generate_presentation.py` when needed.

---

## Slide 1 — Title (15 sec)

**On slide**
- **Perk the Star**
- Single-player orbital tower defense
- *Defend me, defend me! — Oa ka Perk!*
- Godot 4.6 prototype · Sol Defense Corps

**Say**
- We built a real-time tower defense game where you protect the Sun from Astrophage — photosynthetic parasites inspired by *Project Hail Mary*.
- The twist: towers orbit the Sun on rotating rings, so placement and timing matter more than a static grid.

---

## Slide 2 — Background & Motivation (30 sec)

**On slide**
- Sun luminosity dropping: 0.3% → 2.1% → 4.8% (and rising)
- Cause: **Astrophage** — extraterrestrial microorganisms feeding on stellar energy
- You are the **Sol Commander** with **12 waves** and a **luminosity budget**
- Core innovation: **orbital placement** — towers sweep past enemies on timed engagement arcs

**Say**
- The narrative hook is simple: the Sun is dying slowly, and you have one mission — hold luminosity above zero through twelve escalating waves.
- Our design goal was to make tower defense feel like commanding an orbital defense network, not placing static turrets on a map.
- We moved from the original **C++ / SFML** proposal to **Godot 4.6** so we could ship a playable prototype faster, tune waves via JSON, and still keep performance-critical types in **C++ GDExtension**.

---

## Slide 3 — What It Is About (30 sec)

**On slide**
| Role | Description |
|------|-------------|
| **Player** | Sol Commander — build, upgrade, sell towers; trigger Solar Flare |
| **Objective** | Clear 12 waves; keep **luminosity > 0%** |
| **Economy** | **Sol Credits** from kills + wave rewards |
| **Setting** | Top-down orbital space around a living Sun |
| **Fail state** | Sun Extinguished (luminosity = 0%) |
| **Win state** | All 12 waves cleared → rank by remaining luminosity |

**Say**
- You are not just shooting enemies — you are managing a budget, ring coverage, and enemy-specific counters while combat is still running.
- The Sun is both your health bar and the emotional center of the game.

---

## Slide 4 — Characters & Enemies (40 sec)

**On slide — Astrophage variants**

| Enemy | Role | Key behavior |
|-------|------|----------------|
| **Drifter** | Baseline | Straight inward push; teaches pacing |
| **Bloom** | Splitter | Splits into Drifters on death — use slow/AoE first |
| **Coronal Burrower** | Sun pressure | Lodges in Sun; drains luminosity until Bio-Lab clears it |
| **Photon Mimic** | Counter | **Ignores Photon Splitter** — forces mixed towers |
| **Solar Farmer** | Counter | **Absorbs** photon/helios damage; gains HP/speed |
| **Astrophage Prime** | Boss (Wave 12) | **SHELL** (immune except Bio-Lab) → **OPEN** → **Frenzy** minion spawn |

**HUD tags:** `SLOW` · `MIMIC` · `ABSORB` · `SHELL` · `OPEN` · `SPLIT` · `BURROW`

**Say**
- Each enemy exists to break a lazy strategy. Mimics punish Photon-only builds; Farmers punish raw energy damage; Burrowers punish ignoring support towers.
- Prime is the exam: Bio-Lab opens the shell, then you finish it while Frenzy keeps spawning Drifters.

---

## Slide 5 — Towers & Orbital Rings (40 sec)

**On slide — Six towers**

| Tower | Role | Note |
|-------|------|------|
| Photon Splitter | Steady DPS | Great early; weak vs Mimic/Farmer |
| Cryo Probe | Slow/control | Disrupted by solar storm events |
| Bio-Lab Station | Excavation / Prime shell break | Required vs Burrowers & Prime |
| Magnetic Net | Long-range slow | Pairs with heavy damage |
| Helios Cannon | Burst damage | Farmers absorb it if unchecked |
| Tardigrade Bomb | Finisher | Best after slow fields |

**Four rings (28 slots total)**

| Ring | Period | Slots | Best use |
|------|--------|-------|----------|
| Corona Belt | 6 s | 4 | Fast sweep, early intercept |
| Chromosphere Band | 11 s | 6 | Control + finishers |
| Photosphere Arc | 17 s | 8 | Bio-Lab, Magnetic Net |
| Outer Veil | 26 s | 10 | Long engagement windows |

**Say**
- Inner rings orbit fast — short firing windows. Outer rings orbit slowly — longer windows but farther from the Sun.
- Tower position is updated each frame with polar math: `x = x_sun + r cos θ`, `y = y_sun + r sin θ`.
- Ring periods follow Kepler-inspired scaling (longer period at larger radius).

---

## Slide 6 — How to Play (30 sec)

**On slide**
- **Build:** Select tower (1–6 or Tower Bay) → click orbital slot — **works during active waves**
- **Manage:** Click placed tower → upgrade stats, cost, sell refund
- **Waves:** Space/Enter to start · **Auto Start** optional (saved)
- **Flare:** `F` during wave when charged (every 3 cleared waves)
- **Camera:** Mouse wheel zoom · drag / WASD / edge pan · Center Sun
- **Intel:** Wave Intel shows counts, warning tags, counter hints
- **Pause:** Esc → Codex, Settings, Retry, Main Menu

**Say**
- Unlike classic TD prep-only phases, we kept the Tower Bay live during combat so the player can react mid-wave.
- Wave Intel is the briefing screen — it tells you what tags to expect and which tower mix counters them.

---

## Slide 7 — Campaign & Wave Events (30 sec)

**On slide — 12-wave arc**

| Wave | Name | Highlight |
|------|------|-----------|
| 1 | First Contact | Drifters only |
| 3 | Splitting Point | Bloom introduced |
| 4 | Going Under | Burrower — Bio-Lab needed |
| 5 | Invisible Hand | Mimic — tower diversity |
| 6 | Solar Storm | Auto-flare + Cryo disruption |
| 7 | Night Side | Inner rings blind 20 s |
| 8 | The Harvest | Solar Farmer |
| 10 | Research Surge | Bio-Lab 4× speed |
| 12 | Astrophage Prime | Boss + Frenzy event |

**Wave data:** `data/waves/wave_01.json` … `wave_12.json` — editable without recompiling.

**Say**
- Waves are data-driven. Designers change JSON; gameplay code reads spawns and events.
- Special events (`mid_wave_autoflare`, `ring_blind`, `bio_lab_boost`, `prime_frenzy`) force the player to adapt mid-fight.

---

## Slide 8 — Endings & Core Stats (20 sec)

**On slide**

| Stat | Range | Meaning |
|------|-------|---------|
| Luminosity | 0–100% | Sun health; **not restorable** |
| Sol Credits | 0–∞ | Build / upgrade economy |
| Flare charge | Every 3 waves | Manual radial burst (`F`) |
| Performance score | Tracks run quality | Shown on end screen |

**Victory ranks (current build)**
- **FULL SHINE** — luminosity > 80%
- **BRIGHT** — 60–80%
- **DIM BUT ALIVE** — 20–60%
- **LAST LIGHT** — 1–20%
- **Sun Extinguished** — 0% at any time

---

## Slide 9 — Implementation (40 sec)

**On slide — Stack**
- **Engine:** Godot 4.6 · 1920×1080 · Forward Plus
- **Gameplay:** GDScript (`scripts/game/`)
- **Native types:** C++ GDExtension (`gdextension/src/`)
- **Data:** JSON waves + static catalog
- **Autoloads:** `GameState`, `MusicManager`
- **Settings:** `user://settings.cfg`

**Architecture pattern**
1. HUD emits signals (start wave, select tower, menu)
2. `game.gd` updates combat/state
3. `game.gd` sends one **state dictionary** back to HUD
4. Combat rules stay out of UI scripts

**Say**
- We split helpers so `game.gd` stays readable: catalog, orbit math, view/camera, wave parsing, tower math, effects, SFX.
- Balance numbers live in `GameCatalogNative` — one place to tune towers, enemies, rings, and active asset paths.

---

## Slide 10 — Classes & Structures (40 sec)

**On slide**

| Layer | Module | Responsibility |
|-------|--------|----------------|
| **C++** | `Astrophage` | Variant, HP, cloaking, burrowing, Prime phase |
| **C++** | `OrbitalTower` | Ring orbit, engagement arc, firing, upgrades |
| **C++** | `SunNode` | Luminosity, burrower drain, expression |
| **C++** | `WaveData` | Load/parse wave JSON |
| **GDScript** | `game.gd` | Main loop: input, spawn, combat, draw, end states |
| **C++** | `GameCatalogNative` | Towers, enemies, rings, sprite paths |
| **C++** | `GameWaveLibraryNative` | Spawn queue, Wave Intel text |
| **C++** | `GameTowerLibraryNative` | Upgrade cost, stats, refunds |
| **C++** | `GameOrbitMathNative` | Slot angles, tower positions |
| **C++** | `GameViewControllerNative` | Pan, zoom, coordinates |
| **C++** | `GameEffectStoreNative` | TTL shots/effects |
| **C++** | `GameSfxBusNative` | WAV SFX plus fallback tones |
| **Autoload** | `GameState` | Luminosity, credits, phase, saved settings |
| **UI/C++** | `GameHudNative`, `SpaceThemeNative`, `TutorialOverlayNative` | HUD, theme, first-run tutorial |

**Runtime structures (GDScript)**
- `towers[]` — dicts: type, ring, slot, angle, cooldown, level, Sol spent
- `enemies[]` — dicts: type, position, HP, speed, timers, flags
- `burrowers[]` — active Sun drains

---

## Slide 11 — Assets & Presentation (25 sec)

**On slide**
- **Visual style:** Dark sci-fi operations UI — nebula backgrounds, cyan/gold frames, organic Astrophage sprites, clean tower modules
- **Sprites:** `assets/sprites/clean/enemies/`, `assets/sprites/clean/enemies_optimized/`, `assets/sprites/clean/towers/`, `assets/sprites/backgrounds/`
- **UI/fonts:** Kenney Sci-fi UI, Electrolize, Kenney Future
- **Audio:** `assets/audio/bgm/final/`, `assets/audio/bgm/end.ogg`, and `assets/audio/sfx/`
- **Credits:** `assets/licenses/THIRD_PARTY_ASSETS.md`
- **Style guide:** `docs/ASSET_STYLE.md`

**Say**
- We shifted from the proposal’s cozy pixel-art look to a readable sci-fi operations aesthetic that works at 1080p with detailed enemy art.

---

## Slide 12 — Demo & Close (15 sec)

**On slide**
1. Main menu → Play  
2. Build on Corona Belt during Wave 1  
3. Show Wave Intel tags + counter hint  
4. Upgrade a tower mid-wave  
5. Trigger Solar Flare or show Prime on Wave 12  
6. Victory / game-over rank screen  

**Closing line**
- *Every credit should buy time, coverage, or control. A beautiful orbit means nothing if the Sun goes dark.*

---

# Q&A Quick Reference

## Project identity

**Q: What is Perk the Star?**  
A: A single-player orbital tower defense game. You defend the Sun from Astrophage using orbiting towers on four concentric rings across 12 JSON-authored waves.

**Q: What inspired it?**  
A: *Project Hail Mary* (Andy Weir, 2021) — Astrophage as photosynthetic stellar parasites. Gameplay inspiration includes tower defense and orbital mechanics.

**Q: Why “Perk the Star”?**  
A: From the in-universe command phrase *“Defend me, defend me! — Oa ka Perk!”* — “Perk” is the Sun / mission focus.

---

## Proposal vs current build

| Topic | Original Proposal (PDF) | Current Implementation |
|-------|-------------------------|------------------------|
| Engine | C++ / SFML | **Godot 4.6** + GDScript + **C++ GDExtension** |
| Art direction | 16×16 pixel art, cozy crisis | **Dark sci-fi ops UI**, nebula BG, detailed sprites |
| Tower placement | Between-wave emphasis | **Build/upgrade/sell during active waves** |
| Wave tuning | JSON (planned) | **Live JSON** in `data/waves/` |
| UI | Basic title/game flow | **Main menu, HUD, pause, Codex, settings, tutorial** |
| Camera | Not emphasized | **Zoom, pan, WASD, edge scroll** |
| Music | Not detailed | **MusicManager** + volume toggle, wave/boss routing |
| SFX | Not detailed | **Procedural SFX bus** (replaceable with WAV later) |
| End ranks | Full Shine / Dim / Last Light | Same idea + **BRIGHT** tier at 60–80% |
| Enemy count | 4 variants named, 6 in table | **6 variants + Prime** fully implemented |
| Helios cost | 30 SC per shot (proposal) | Standard tower build/upgrade economy in current build |

**How to say it in defense:**  
“We kept the core design from Proposal 4 — orbital rings, Astrophage variants, JSON waves, Sun luminosity — but migrated to Godot for faster iteration, richer UI, and data-driven balancing. Performance-sensitive types remain in C++ via GDExtension.”

---

## Gameplay mechanics

**Q: What makes this different from normal tower defense?**  
A: Towers **orbit** the Sun on rings with different periods and slot counts. Engagement is arc-based and time-limited, not permanent range coverage.

**Q: How do you win / lose?**  
A: **Win:** clear wave 12 with luminosity > 0. **Lose:** luminosity hits 0% at any time.

**Q: Can you place towers only between waves?**  
A: No — the Tower Bay stays active **during waves**, which is a deliberate design choice for reactive play.

**Q: How does the Solar Flare work?**  
A: Charges every **3 cleared waves**. Press **F** during an active wave for a radial burst from the Sun. Wave 6 can also trigger an automatic mid-wave flare event.

**Q: How does Prime work?**  
A: Starts in **SHELL** phase — immune to most damage until **Bio-Lab** breaks it (`OPEN`). Wave 12’s **prime_frenzy** event keeps spawning Drifters while Prime lives.

**Q: What do Mimics and Farmers do?**  
A: **Mimic:** ignores Photon Splitter shots — forces Bio-Lab/Cryo/Magnetic/Helios mix. **Farmer:** absorbs energy-type damage and gets stronger — slow first, then kill.

**Q: What do Burrowers do?**  
A: Reach the Sun and **drain luminosity** until excavated by Bio-Lab. Highest priority threat.

---

## Technical

**Q: Why Godot instead of SFML?**  
A: Faster scene/UI workflow, built-in signals, JSON tooling, and easier demo polish — while still using C++ where we defined core entity types.

**Q: Where is the main game loop?**  
A: `scripts/game/game.gd` — input, spawning, orbit update, targeting, damage, events, HUD sync, draw.

**Q: Where is balance data?**  
A: `GameCatalogNative` (towers, enemies, rings) + `data/waves/*.json` (campaign).

**Q: How do waves load?**  
A: `GameWaveLibraryNative` reads JSON, normalizes spawns/events, builds spawn queue and Wave Intel strings.

**Q: What are the C++ classes for?**  
A: `Astrophage`, `OrbitalTower`, `SunNode`, `WaveData` in `gdextension/src/` — registered via `register_types.cpp`, built to `game/bin/perk_the_star.dll`.

**Q: How does UI stay separate from logic?**  
A: HUD buttons emit signals -> `game.gd` decides -> returns a display dictionary -> `GameHudNative` renders. No combat rules live in the HUD.

**Q: What optimizations did you apply?**  
A: Helper module split; TTL effect arrays; SFX player pool (no per-frame audio node creation); conditional redraw; centralized theme/catalog; JSON-driven waves avoid recompilation for balance.

**Q: Where are settings saved?**  
A: `user://settings.cfg` — music volume, screen shake, tutorial completion, Auto Start.

---

## Content & assets

**Q: Where do sprites and audio live?**  
A: `assets/sprites/`, `assets/audio/bgm/final/`, `assets/ui/`, `assets/fonts/`. Credits in `assets/licenses/`.

**Q: What third-party assets are used?**  
A: Kenney Sci-fi UI (CC0), Electrolize (OFL), Kenney Future fonts (CC0), Screaming Brain Studios nebula backgrounds (CC0), sci-fi icon pack — see `THIRD_PARTY_ASSETS.md`.

---

## Planned features

Mention as **future work** if asked:

| Feature | Status |
|---------|--------|
| Clash waves (simultaneous burst spawns) | Planned |
| Formation spawning (ring, V, spiral) | Planned |
| Escalation counter-attack (clear too fast → bonus wave) | Planned |
| PvZ-style next-wave banner | Planned |
| Ghost spawn preview lines in prep | Planned |
| Stellar gravity enemy movement | Planned |
| Gravity-curved / slingshot projectiles | Planned |
| Larger late-wave enemy counts (100+ swarms) | Planned JSON rebalance |

**Q: Did you implement everything in the feature guide?**  
A: No — the feature guide is our **v2 upgrade spec**. The current playable build includes core orbital TD, all six enemy types, Prime phases, wave events, Wave Intel, tutorial, Codex, full UI flow, and JSON waves. Clash/formation/physics upgrades are documented next steps.

---

## Demo script (5 min live)

1. **Main menu** — nebula, cyan/gold theme, Play  
2. **Optional tutorial** — diagram arrows to HUD (first run only)  
3. **Wave 1** — place Photon Splitter on Ring 1 during combat  
4. **Tower management** — click tower → upgrade cost + stat preview  
5. **Wave Intel** — point to tags (`MIMIC`, `STORM`, etc.) and counter line  
6. **Event** — Wave 6 storm or Wave 7 ring dark if time allows  
7. **Pause → Codex** — Mission Briefing section  
8. **End state** — victory rank or game-over retry  

---

## One-paragraph elevator pitch

*Perk the Star is an orbital tower defense game built in Godot 4.6 where you command the Sol Defense Corps against Astrophage — alien parasites draining the Sun’s luminosity. Towers orbit on four concentric rings with Kepler-scaled periods, firing within engagement arcs while enemies push inward with unique counters: Mimics ignore photon fire, Farmers absorb energy, Burrowers drain the Sun, and Astrophage Prime breaks into shell, open, and frenzy phases. Twelve JSON-driven waves, live mid-combat building, Wave Intel briefings, Solar Flares, and a full sci-fi UI make it a complete prototype beyond our original SFML proposal — with C++ GDExtension for core entity types and a documented v2 roadmap for clash waves and physics-based shots.*

---

## File map (if panel asks “where is X?”)

| What | Where |
|------|-------|
| Run entry | `project.godot` → `scenes/main_menu.tscn` |
| Gameplay scene | `scenes/game.tscn` + `scripts/game/game.gd` |
| Balance | `GameCatalogNative` |
| Waves | `data/waves/wave_01.json` … `wave_12.json` |
| Mission lore | `scenes/ui/codex.gd` |
| C++ extension | `gdextension/src/`, `game/bin/perk_the_star.gdextension` |
| Walkthrough | `docs/PROJECT_WALKTHROUGH.md` |
| File map | `docs/FILE_SYSTEM.md` |

---

*Last updated for defense/demo use. Regenerate PDF slides from this doc if needed.*
