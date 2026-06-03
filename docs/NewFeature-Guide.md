# PERK THE STAR — V2 FEATURE UPGRADE GUIDE
### New Mechanics, Physics, Waves & Systems
**Group H | CMSC 21 | Geo Ceff Gabaisen & Dexter Juevesano**

> *This guide assumes the base game (v1) is already implemented and working.*
> *All code here is additive — it extends or replaces specific functions in your existing scripts.*
> *Do not delete your working v1 GDScript. Extend it.*

---

## TABLE OF CONTENTS

| # | Section |
|---|---------|
| 1 | [What Changed & Files to Touch](#1-what-changed--files-to-touch) |
| 2 | [Wave Banner v2 — PvZ-Style "Next Wave" Popup](#2-wave-banner-v2--pvz-style-next-wave-popup) |
| 3 | [Wave Design Philosophy — Slow Buildup, Massive Late Swarms](#3-wave-design-philosophy--slow-buildup-massive-late-swarms) |
| 4 | [All 12 Wave JSON Files (v2)](#4-all-12-wave-json-files-v2) |
| 5 | [Clash Waves & Formation Spawning](#5-clash-waves--formation-spawning) |
| 6 | [Boss Wave — Astrophage Prime Overhaul](#6-boss-wave--astrophage-prime-overhaul) |
| 7 | [Escalation Counter-Attack System](#7-escalation-counter-attack-system) |
| 8 | [Wave Preview During Prep Phase](#8-wave-preview-during-prep-phase) |
| 9 | [Physics — Stellar Gravity on Enemies](#9-physics--stellar-gravity-on-enemies) |
| 10 | [Physics — Gravity-Curved Projectiles](#10-physics--gravity-curved-projectiles) |
| 11 | [Physics — Slingshot Orbital Shots](#11-physics--slingshot-orbital-shots) |
| 12 | [Physics — Ring Collision Damage Boost](#12-physics--ring-collision-damage-boost) |
| 13 | [C++ Extensions for Physics](#13-c-extensions-for-physics) |
| 14 | [Updated Wave Manager (Full Reference)](#14-updated-wave-manager-full-reference) |
| 15 | [Testing Checklist v2](#15-testing-checklist-v2) |
| 16 | [Glossary Additions](#16-glossary-additions) |
| 17 | [Asset Revision Guide](#17-asset-revision-guide) |
| 18 | [Using Cursor + Codex Together](#18-using-cursor--codex-together) |

---

## 1. What Changed & Files to Touch

Here is every file that needs to be modified or created. Nothing else needs to change.

| File | Change Type | What Changes |
|------|-------------|-------------|
| `data/waves/wave_01.json` → `wave_12.json` | Replace | More enemies, slower early intervals, new `wave_type`/`clash_groups` fields |
| `scripts/managers/wave_manager.gd` | Extend | Clash spawning, formation patterns, escalation counter-attack, next-wave preview wiring |
| `scripts/managers/spawn_manager.gd` | Extend | Ghost path preview lines during prep phase |
| `scripts/entities/bullet.gd` | Extend | Physics projectile mode (gravity curve, slingshot arc) |
| `scripts/entities/astrophage.gd` | Extend | Gravity-based movement, Prime frenzy minion spawning |
| `scenes/ui/wave_banner.tscn` + `wave_banner.gd` | Extend | Add `NextWavePanel`, counter-attack banner text |
| `gdextension/src/astrophage.cpp/.h` | Extend | `m_mass`, `m_velocity_x/y`, gravity step in `_process()` |
| `gdextension/src/orbital_tower.cpp/.h` | Extend | `compute_physics_launch_velocity()`, slingshot mode flag |
| `scripts/entities/physics_projectile.gd` | **New file** | Gravity-curved projectile script |
| `scenes/entities/physics_projectile.tscn` | **New file** | Scene for the physics projectile |

### Recommended Implementation Order

```
1. Wave JSONs (Section 4)      → biggest gameplay impact, no code changes needed
2. Wave Banner v2 (Section 2)  → PvZ-style popup, quick to add
3. Clash Spawning (Section 5)  → replaces spawn loop for clash waves
4. Stellar Gravity (Section 9) → enemy movement overhaul in C++
5. Physics Projectiles (10–12) → new projectile scene + tower branch
6. Slingshot (Section 11)      → right-click Helios upgrade
7. Prime Overhaul (Section 6)  → frenzy minion spawning
8. Wave Preview (Section 8)    → ghost lines during prep phase
9. Escalation (Section 7)      → counter-attack on fast clears
```

---

## 2. Wave Banner v2 — PvZ-Style "Next Wave" Popup

After each wave clears, before the prep timer starts, a banner announces the next incoming wave — enemy types, count, and threat level — just like PvZ's "A huge wave of zombies is approaching!"

### Scene: `scenes/ui/wave_banner.tscn`

Add these nodes inside your existing `WaveBanner` Control node:

```
WaveBanner (existing Control)
├── AnimationPlayer      [existing]
├── WaveTitle            [existing Label]
├── WaveSubtitle         [existing Label]
└── NextWavePanel        [NEW — VBoxContainer, visible: false]
    ├── NextWaveLabel    [Label — shows threat text]
    └── EnemyListBox     [HBoxContainer — enemy icons + counts filled at runtime]
```

### `scripts/ui/wave_banner.gd`

```gdscript
# Call this from wave_manager after wave_complete, BEFORE prep phase starts.
func show_next_wave_preview(next_wave_num: int, next_wave_data: Dictionary):
    if next_wave_num > 12:
        return

    var panel = $NextWavePanel
    var box   = $NextWavePanel/EnemyListBox

    # Clear old icons from previous wave
    for child in box.get_children():
        child.queue_free()

    # Icon map — one per enemy type
    var enemy_icons = {
        "drifter":  "res://assets/sprites/enemies/Drifter_idle_1.png",
        "bloom":    "res://assets/sprites/enemies/Bloom_idle_1.png",
        "burrower": "res://assets/sprites/enemies/Coronal Burrower_idle_1.png",
        "mimic":    "res://assets/sprites/enemies/Photon Mimic_idle_1.png",
        "farmer":   "res://assets/sprites/enemies/Solar Farmer_idle_1.png",
        "prime":    "res://assets/sprites/enemies/ASTROPHAGE PRIME_shell_idle_1.png",
    }

    var enemies    = next_wave_data.get("enemies", [])
    var total_count = 0

    for entry in enemies:
        total_count += entry.get("count", 0)
        var hbox = HBoxContainer.new()

        var icon = TextureRect.new()
        icon.custom_minimum_size = Vector2(24, 24)
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        var key = entry.get("variant", "drifter")
        if enemy_icons.has(key):
            icon.texture = load(enemy_icons[key])

        var count_label = Label.new()
        count_label.text = "×%d" % entry.get("count", 0)
        count_label.add_theme_font_size_override("font_size", 13)

        hbox.add_child(icon)
        hbox.add_child(count_label)
        box.add_child(hbox)

    # Title text depends on wave type
    var wave_type  = next_wave_data.get("wave_type", "normal")
    var next_label = $NextWavePanel/NextWaveLabel

    match wave_type:
        "clash":
            next_label.text    = "⚠  MASSIVE WAVE APPROACHING — %d ENEMIES!" % total_count
            next_label.modulate = Color(1.0, 0.3, 0.1)
        "boss":
            next_label.text    = "☠  ASTROPHAGE PRIME DETECTED"
            next_label.modulate = Color(1.0, 0.1, 0.1)
        _:
            next_label.text    = "WAVE %d INCOMING — %d ENEMIES" % [next_wave_num, total_count]
            next_label.modulate = Color(1.0, 0.9, 0.4)

    panel.visible = true

    # Auto-hide after 4 seconds
    await get_tree().create_timer(4.0).timeout
    var tween = create_tween()
    tween.tween_property(panel, "modulate:a", 0.0, 0.6)
    await tween.finished
    panel.visible   = false
    panel.modulate.a = 1.0

func show_counter_attack_warning():
    $WaveTitle.text    = "⚠  COUNTER-ATTACK!"
    $WaveSubtitle.text = "Too fast — they retaliated!"
    $WaveTitle.modulate = Color(1.0, 0.4, 0.0)
    visible = true
    await get_tree().create_timer(2.5).timeout
    visible = false
```

### Wiring in `wave_manager.gd`

In `_check_wave_clear()`, after the `wave_complete` signal, load the next wave JSON and pass it to the banner:

```gdscript
func _check_wave_clear():
    if active_enemies <= 0 and spawn_queue.is_empty() and wave_active:
        wave_active = false
        _check_escalation_counter_attack()

        var reward = wave_data.get("reward_base", 20)
        GameState.on_wave_cleared()
        emit_signal("wave_complete", current_wave, reward)
        GameState.set_phase(GameState.Phase.BETWEEN_WAVE)

        # Show next wave preview
        var next_num = current_wave + 1
        if next_num <= WAVE_COUNT:
            var next_path = "res://data/waves/wave_%02d.json" % next_num
            if FileAccess.file_exists(next_path):
                var f = FileAccess.open(next_path, FileAccess.READ)
                var next_data = JSON.parse_string(f.get_as_text())
                f.close()
                var banner = get_tree().get_first_node_in_group("wave_banner")
                if banner:
                    banner.show_next_wave_preview(next_num, next_data)
```

> Add `wave_banner` to the Godot group of your WaveBanner node in the scene editor so the above `get_first_node_in_group` call finds it.

---

## 3. Wave Design Philosophy — Slow Buildup, Massive Late Swarms

### The Problem with v1

Wave 1 had 5 enemies. Wave 12 had ~38. That's only a 7× increase, and the spawn interval barely changed. Late waves felt fast but not *epic*. There was no moment where the screen filled with enemies.

### The v2 Curve

v2 scales two levers independently:

- **Enemy count** grows aggressively: Wave 1 = 6, Wave 12 = **107 enemies + 1 boss**
- **Spawn interval** stays slow-to-medium early, only dropping fast at waves 9–12
- **`wave_type`** (`normal`, `clash`, `formation`, `boss`) controls whether the normal interval queue is used or enemies burst all at once
- **Clash waves** ignore `spawn_interval` entirely — enemies arrive in simultaneous geometric bursts

### Spawn Interval Reference

| Phase | Waves | Interval | Feel |
|-------|-------|----------|------|
| Tutorial | 1–2 | 3.5–3.0s | Breathing room — learn the game |
| Early | 3–5 | 2.8–2.2s | Steady pressure |
| Mid | 6–8 | 2.0–1.6s | Dense — need multiple towers |
| Late | 9–11 | 1.3–1.0s | Fast and punishing |
| Boss | 12 | 0.5s | Relentless until Prime spawns |

> For **Clash Waves**, `spawn_interval` is ignored. All enemies in each `clash_group` spawn simultaneously. See Section 5.

---

## 4. All 12 Wave JSON Files (v2)

Replace every file in `data/waves/`. New fields:

- `"wave_type"`: `"normal"` | `"clash"` | `"formation"` | `"boss"`
- `"clash_groups"`: array of burst groups — each has `variants[]` and `delay_before` seconds
- `"formation"`: geometric spawn pattern applied on top of the normal queue
- `"escalation_threshold_seconds"`: if wave clears faster than this, trigger counter-attack (null = no threshold)

---

**wave_01.json** — Tutorial. 6 Drifters. Very slow.
```json
{
    "wave": 1,
    "name": "First Contact",
    "wave_type": "normal",
    "spawn_interval": 3.5,
    "enemies": [
        { "variant": "drifter", "count": 6 }
    ],
    "event": null,
    "reward_base": 20,
    "escalation_threshold_seconds": null,
    "tutorial_hint": "Click ring slots to place towers. Towers orbit and fire automatically."
}
```

**wave_02.json** — More Drifters, still gentle.
```json
{
    "wave": 2,
    "name": "The Vanguard",
    "wave_type": "normal",
    "spawn_interval": 3.0,
    "enemies": [
        { "variant": "drifter", "count": 14 }
    ],
    "event": null,
    "reward_base": 28,
    "escalation_threshold_seconds": null,
    "tutorial_hint": "Earn Sol Credits by defeating enemies. Spend them between waves."
}
```

**wave_03.json** — First Blooms. V-shape formation.
```json
{
    "wave": 3,
    "name": "Splitting Point",
    "wave_type": "formation",
    "spawn_interval": 2.8,
    "enemies": [
        { "variant": "drifter", "count": 14 },
        { "variant": "bloom",   "count": 6 }
    ],
    "formation": {
        "type": "v_shape",
        "variants": ["drifter"],
        "count": 9,
        "spread_angle_deg": 60
    },
    "event": null,
    "reward_base": 38,
    "escalation_threshold_seconds": null,
    "tutorial_hint": "Blooms split into 3 Drifters on direct damage. Use AoE or Cryo first!"
}
```

**wave_04.json** — First Burrowers. Slow enough to respond.
```json
{
    "wave": 4,
    "name": "Going Under",
    "wave_type": "normal",
    "spawn_interval": 2.5,
    "enemies": [
        { "variant": "drifter",  "count": 18 },
        { "variant": "bloom",    "count": 6 },
        { "variant": "burrower", "count": 4 }
    ],
    "event": null,
    "reward_base": 50,
    "escalation_threshold_seconds": null,
    "tutorial_hint": "Burrowers drain luminosity at the corona. Bio-Lab excavates them."
}
```

**wave_05.json** — Mimics introduced. Medium density.
```json
{
    "wave": 5,
    "name": "Invisible Hand",
    "wave_type": "normal",
    "spawn_interval": 2.2,
    "enemies": [
        { "variant": "drifter",  "count": 20 },
        { "variant": "mimic",    "count": 6 },
        { "variant": "burrower", "count": 3 }
    ],
    "event": null,
    "reward_base": 58,
    "escalation_threshold_seconds": null,
    "tutorial_hint": "Photon Mimics are invisible to Photon Splitters. Bio-Lab and Cryo reveal them."
}
```

**wave_06.json** — First CLASH wave. Ring formation. Mid-wave solar flare.
```json
{
    "wave": 6,
    "name": "Solar Storm",
    "wave_type": "clash",
    "spawn_interval": 2.0,
    "enemies": [
        { "variant": "drifter", "count": 20 },
        { "variant": "bloom",   "count": 8 },
        { "variant": "mimic",   "count": 5 }
    ],
    "clash_groups": [
        {
            "variants": [
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter"
            ],
            "spawn_pattern": "ring",
            "delay_before": 0.0
        },
        {
            "variants": [
                "bloom","bloom","bloom","bloom",
                "mimic","mimic","mimic"
            ],
            "spawn_pattern": "random",
            "delay_before": 5.0
        },
        {
            "variants": [
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "bloom","bloom","bloom","bloom",
                "mimic","mimic"
            ],
            "spawn_pattern": "ring",
            "delay_before": 14.0
        }
    ],
    "event": {
        "type": "mid_wave_autoflare",
        "trigger_at_percent": 0.5,
        "cryo_disruption_seconds": 8
    },
    "reward_base": 75,
    "escalation_threshold_seconds": 35,
    "tutorial_hint": "MASSIVE WAVE — enemies arrive in rings! A mid-wave solar storm fires automatically."
}
```

**wave_07.json** — V-formation Burrowers. Inner rings go dark.
```json
{
    "wave": 7,
    "name": "Night Side",
    "wave_type": "formation",
    "spawn_interval": 1.8,
    "enemies": [
        { "variant": "drifter",  "count": 24 },
        { "variant": "bloom",    "count": 8 },
        { "variant": "burrower", "count": 7 },
        { "variant": "mimic",    "count": 5 }
    ],
    "formation": {
        "type": "v_shape",
        "variants": ["burrower"],
        "count": 7,
        "spread_angle_deg": 45
    },
    "event": {
        "type": "ring_blind",
        "rings": [0, 1],
        "duration": 20,
        "trigger_at_percent": 0.1
    },
    "reward_base": 88,
    "escalation_threshold_seconds": 40,
    "tutorial_hint": "Burrowers arrive in formation! Inner rings go dark — rely on outer towers."
}
```

**wave_08.json** — Farmers + big Drifter swarm.
```json
{
    "wave": 8,
    "name": "The Harvest",
    "wave_type": "normal",
    "spawn_interval": 1.6,
    "enemies": [
        { "variant": "drifter", "count": 30 },
        { "variant": "bloom",   "count": 10 },
        { "variant": "farmer",  "count": 8 }
    ],
    "event": null,
    "reward_base": 100,
    "escalation_threshold_seconds": 45,
    "tutorial_hint": "Solar Farmers gain HP from energy tower hits. Cryo-debuff them before attacking!"
}
```

**wave_09.json** — All 5 enemy types at once. CLASH mid-wave.
```json
{
    "wave": 9,
    "name": "Feeding Frenzy",
    "wave_type": "clash",
    "spawn_interval": 1.3,
    "enemies": [
        { "variant": "drifter",  "count": 32 },
        { "variant": "bloom",    "count": 10 },
        { "variant": "burrower", "count": 7 },
        { "variant": "mimic",    "count": 7 },
        { "variant": "farmer",   "count": 7 }
    ],
    "clash_groups": [
        {
            "variants": [
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "bloom","bloom","bloom","bloom","bloom"
            ],
            "spawn_pattern": "ring",
            "delay_before": 0.0
        },
        {
            "variants": [
                "burrower","burrower","burrower","burrower","burrower","burrower","burrower",
                "mimic","mimic","mimic","mimic",
                "farmer","farmer","farmer"
            ],
            "spawn_pattern": "v_shape",
            "delay_before": 10.0
        },
        {
            "variants": [
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter",
                "bloom","bloom","bloom","bloom","bloom",
                "mimic","mimic","mimic",
                "farmer","farmer","farmer"
            ],
            "spawn_pattern": "ring",
            "delay_before": 22.0
        }
    ],
    "event": null,
    "reward_base": 120,
    "escalation_threshold_seconds": 50,
    "tutorial_hint": "All enemy types at once. Prepare your whole defense before this one."
}
```

**wave_10.json** — Massive spiral formation. Bio-Lab boost active.
```json
{
    "wave": 10,
    "name": "Research Surge",
    "wave_type": "formation",
    "spawn_interval": 1.2,
    "enemies": [
        { "variant": "drifter",  "count": 38 },
        { "variant": "bloom",    "count": 12 },
        { "variant": "burrower", "count": 8 },
        { "variant": "mimic",    "count": 8 },
        { "variant": "farmer",   "count": 10 }
    ],
    "formation": {
        "type": "spiral",
        "variants": ["burrower", "mimic"],
        "count": 10,
        "spiral_arms": 2
    },
    "event": {
        "type": "bio_lab_boost",
        "multiplier": 4,
        "duration": 999,
        "trigger_at_percent": 0.0
    },
    "reward_base": 140,
    "escalation_threshold_seconds": 55,
    "tutorial_hint": "Bio-Lab is at 4× power this wave. Build more if you haven't."
}
```

**wave_11.json** — Penultimate. Biggest CLASH yet.
```json
{
    "wave": 11,
    "name": "Penultimate",
    "wave_type": "clash",
    "spawn_interval": 1.0,
    "enemies": [
        { "variant": "drifter",  "count": 48 },
        { "variant": "bloom",    "count": 14 },
        { "variant": "burrower", "count": 10 },
        { "variant": "mimic",    "count": 10 },
        { "variant": "farmer",   "count": 12 }
    ],
    "clash_groups": [
        {
            "variants": [
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "bloom","bloom","bloom","bloom","bloom",
                "bloom","bloom","bloom","bloom","bloom"
            ],
            "spawn_pattern": "ring",
            "delay_before": 0.0
        },
        {
            "variants": [
                "burrower","burrower","burrower","burrower","burrower",
                "burrower","burrower","burrower","burrower","burrower",
                "farmer","farmer","farmer","farmer","farmer",
                "farmer","farmer","farmer","farmer","farmer"
            ],
            "spawn_pattern": "v_shape",
            "delay_before": 8.0
        },
        {
            "variants": [
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter",
                "mimic","mimic","mimic","mimic","mimic",
                "mimic","mimic","mimic","mimic","mimic",
                "bloom","bloom","bloom","bloom",
                "burrower","burrower","burrower","burrower"
            ],
            "spawn_pattern": "ring",
            "delay_before": 18.0
        }
    ],
    "event": null,
    "reward_base": 160,
    "escalation_threshold_seconds": 60,
    "tutorial_hint": "The biggest wave before the boss. Max out your towers now."
}
```

**wave_12.json** — Astrophage Prime + final CLASH. 107 enemies + 1 boss.
```json
{
    "wave": 12,
    "name": "Astrophage Prime",
    "wave_type": "boss",
    "spawn_interval": 0.5,
    "enemies": [
        { "variant": "drifter",  "count": 40 },
        { "variant": "bloom",    "count": 15 },
        { "variant": "burrower", "count": 10 },
        { "variant": "mimic",    "count": 10 },
        { "variant": "farmer",   "count": 10 },
        { "variant": "farmer",   "count": 10 },
        { "variant": "prime",    "count": 1  }
    ],
    "clash_groups": [
        {
            "variants": [
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "bloom","bloom","bloom","bloom","bloom",
                "bloom","bloom","bloom","bloom","bloom"
            ],
            "spawn_pattern": "ring",
            "delay_before": 0.0
        },
        {
            "variants": [
                "burrower","burrower","burrower","burrower","burrower",
                "burrower","burrower","burrower","burrower","burrower",
                "mimic","mimic","mimic","mimic","mimic",
                "mimic","mimic","mimic","mimic","mimic"
            ],
            "spawn_pattern": "v_shape",
            "delay_before": 10.0
        },
        {
            "variants": [
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "drifter","drifter","drifter","drifter","drifter",
                "farmer","farmer","farmer","farmer","farmer",
                "farmer","farmer","farmer","farmer","farmer",
                "bloom","bloom","bloom","bloom","bloom",
                "mimic","mimic","mimic","mimic","mimic"
            ],
            "spawn_pattern": "ring",
            "delay_before": 20.0
        },
        {
            "variants": ["prime"],
            "spawn_pattern": "center_top",
            "delay_before": 35.0
        }
    ],
    "event": null,
    "reward_base": 250,
    "escalation_threshold_seconds": null,
    "tutorial_hint": "Astrophage Prime arrives after its horde. Shell → Active → Frenzy. Bio-Lab breaks the shell!"
}
```

---

## 5. Clash Waves & Formation Spawning

### What Is a Clash Wave?

When `wave_type` is `"clash"` or `"boss"`, the WaveManager ignores the standard `spawn_interval` queue and instead reads `clash_groups`. Each group is a simultaneous burst of enemies with a `delay_before` stagger. The result is walls of enemies arriving all at once — the PvZ "huge wave" feeling.

### Formation Types

| Type | Description | Best For |
|------|-------------|----------|
| `"ring"` | Enemies spread evenly around the full spawn circle | Overwhelming from all directions |
| `"v_shape"` | Enemies spawn in a V pointing at the Sun | Focused attack corridor |
| `"spiral"` | Enemies spawn along a spiral arm | Mixed angular approach |
| `"random"` | Original random behavior | Chaotic filler waves |
| `"center_top"` | Single spawn at top of screen | Boss dramatic entrance |

### Changes to `scripts/managers/wave_manager.gd`

```gdscript
const WAVE_COUNT: int = 12
const VARIANT_MAP: Dictionary = {
    "drifter":  0,
    "bloom":    1,
    "burrower": 2,
    "mimic":    3,
    "farmer":   4,
    "prime":    5,
}

func start_wave(wave_num: int):
    # ... keep existing JSON load code ...
    var wave_type = wave_data.get("wave_type", "normal")

    match wave_type:
        "clash", "boss": _start_clash_wave()
        "formation":     _start_formation_wave()
        _:               _start_normal_wave()

func _start_normal_wave():
    spawn_queue.clear()
    for entry in wave_data.get("enemies", []):
        var v_id = VARIANT_MAP.get(entry.get("variant", "drifter"), 0)
        for _i in entry.get("count", 1):
            spawn_queue.append({"variant": v_id, "pattern": "random"})
    spawn_queue.shuffle()
    active_enemies = spawn_queue.size()
    spawn_timer    = wave_data.get("spawn_interval", 2.0)
    wave_active    = true

func _start_clash_wave():
    wave_active = true
    var groups  = wave_data.get("clash_groups", [])
    active_enemies = 0
    for g in groups:
        active_enemies += g.get("variants", []).size()

    for group in groups:
        var delay   = group.get("delay_before", 0.0)
        var pattern = group.get("spawn_pattern", "random")
        var variants = group.get("variants", [])
        get_tree().create_timer(delay).timeout.connect(
            func(): _spawn_clash_group(variants, pattern)
        )

func _spawn_clash_group(variants: Array, pattern: String):
    var sun_center   = Vector2(640, 360)
    var spawn_radius = 390.0
    var count        = variants.size()

    for i in count:
        var v_id = VARIANT_MAP.get(variants[i], 0)
        var spawn_pos: Vector2

        match pattern:
            "ring":
                var angle  = (float(i) / float(count)) * TAU
                spawn_pos  = sun_center + Vector2(cos(angle), sin(angle)) * spawn_radius
            "v_shape":
                var half   = count / 2
                var side   = 1 if i < half else -1
                var idx    = i if i < half else i - half
                var angle  = -PI / 2.0 + side * (float(idx + 1) / float(half + 1)) * (PI / 3.0)
                spawn_pos  = sun_center + Vector2(cos(angle), sin(angle)) * spawn_radius
            "spiral":
                var angle  = (float(i) / float(count)) * PI * 3.0
                var r      = spawn_radius * (0.8 + 0.2 * float(i) / float(count))
                spawn_pos  = sun_center + Vector2(cos(angle), sin(angle)) * r
            "center_top":
                spawn_pos  = sun_center + Vector2(0, -spawn_radius)
            _:  # random
                var angle  = randf() * TAU
                spawn_pos  = sun_center + Vector2(cos(angle), sin(angle)) * spawn_radius

        _spawn_enemy_at(v_id, spawn_pos)

func _start_formation_wave():
    # Run the normal queue first, then burst the formation group on top
    _start_normal_wave()

    var formation = wave_data.get("formation", null)
    if formation == null:
        return

    var f_type     = formation.get("type", "ring")
    var f_variants = formation.get("variants", ["drifter"])
    var f_count    = formation.get("count", 8)

    var variants = []
    for i in f_count:
        variants.append(f_variants[i % f_variants.size()])

    # Formation spawns 2 seconds after the normal queue starts
    get_tree().create_timer(2.0).timeout.connect(
        func(): _spawn_clash_group(variants, f_type)
    )
    active_enemies += f_count

func _spawn_enemy_at(variant: int, spawn_pos: Vector2):
    if astrophage_scene == null:
        return
    var enemy = astrophage_scene.instantiate()
    get_tree().current_scene.add_child(enemy)
    enemy.setup(variant, spawn_pos, Vector2(640, 360))
    enemy.defeated.connect(_on_enemy_defeated)
    enemy.reached_corona.connect(_on_enemy_breached)
```

---

## 6. Boss Wave — Astrophage Prime Overhaul

The existing Prime already has Shell → Active → Frenzy phases. v2 adds **Frenzy phase minion spawning** — when Prime enters Frenzy it continuously spawns Drifters every 1.5 seconds until it dies.

### Changes to `scripts/entities/astrophage.gd`

Add state variables near the top of the script:

```gdscript
# Prime frenzy state
var frenzy_timer:      float = 0.0
var is_spawning_frenzy: bool  = false
```

Replace the Frenzy entry in `_on_defeated()` for Prime:

```gdscript
if variant == Variant.PRIME:
    match prime_phase:
        PrimePhase.ACTIVE:
            # Transition to Frenzy
            prime_phase = PrimePhase.FRENZY
            hp          = 300
            max_hp      = 300
            speed      *= 1.8
            scale       = Vector2(2.5, 2.5)
            modulate    = Color(1.5, 0.2, 0.2)
            _start_frenzy_spawning()
            return
        PrimePhase.FRENZY:
            _stop_frenzy_spawning()
            # fall through — Prime actually dies

func _start_frenzy_spawning():
    frenzy_timer       = 0.0
    is_spawning_frenzy = true

func _stop_frenzy_spawning():
    is_spawning_frenzy = false
```

In `_process()`, add this inside the Prime variant block:

```gdscript
if variant == Variant.PRIME and prime_phase == PrimePhase.FRENZY and is_spawning_frenzy:
    frenzy_timer -= delta
    if frenzy_timer <= 0.0:
        frenzy_timer = 1.5
        _spawn_frenzy_drifters()

func _spawn_frenzy_drifters():
    var base_scene = load("res://scenes/entities/astrophage_base.tscn")  # adjust to your path
    for i in 2:
        var d = base_scene.instantiate()
        get_tree().current_scene.add_child(d)
        var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
        d.setup(Variant.DRIFTER, global_position + offset, sun_position)
        d.defeated.connect(func(r): GameState.add_credits(r))
```

### Phase Summary

| Phase | Scale | Modulate | HP | Speed | Special |
|-------|-------|----------|----|-------|---------|
| Shell | 2.0× | Normal | 500 | 25 px/s | Immune to all except Bio-Lab |
| Active | 2.0× | Orange tint | 500 | 35 px/s | Takes full damage |
| Frenzy | 2.5× | Deep red | 300 | 45 px/s | Spawns 2 Drifters every 1.5s |

---

## 7. Escalation Counter-Attack System

If the player clears a wave faster than its `escalation_threshold_seconds`, a small bonus wave immediately retaliates. This punishes over-investment and rewards balanced play.

### `scripts/managers/wave_manager.gd`

```gdscript
# Add at top:
var _wave_start_time: float = 0.0

# In start_wave(), set the timer after wave_active = true:
_wave_start_time = Time.get_ticks_msec() / 1000.0

func _check_escalation_counter_attack():
    var threshold = wave_data.get("escalation_threshold_seconds", null)
    if threshold == null:
        return

    var elapsed = (Time.get_ticks_msec() / 1000.0) - _wave_start_time
    if elapsed < threshold:
        _launch_counter_attack()

func _launch_counter_attack():
    # 6 Drifters + 2 of the most prominent non-drifter enemy from the wave
    var counter_variants = ["drifter","drifter","drifter","drifter","drifter","drifter"]

    var enemies_in_wave   = wave_data.get("enemies", [])
    var retaliation_type  = "drifter"
    var highest_count     = 0
    for entry in enemies_in_wave:
        if entry.get("variant", "drifter") != "drifter" and entry.get("count", 0) > highest_count:
            highest_count    = entry.get("count", 0)
            retaliation_type = entry.get("variant", "drifter")

    counter_variants.append(retaliation_type)
    counter_variants.append(retaliation_type)

    active_enemies += counter_variants.size()
    wave_active = true  # re-enable so _check_wave_clear works

    # Brief pause so the player sees the "wave clear" moment
    await get_tree().create_timer(1.2).timeout

    var banner = get_tree().get_first_node_in_group("wave_banner")
    if banner:
        banner.show_counter_attack_warning()

    _spawn_clash_group(counter_variants, "ring")
```

---

## 8. Wave Preview During Prep Phase

During the prep countdown, faint ghost path lines are drawn from each spawn point to the Sun so the player can see where the next wave is coming from.

### `scripts/managers/spawn_manager.gd`

```gdscript
var _preview_lines: Array = []

func show_wave_preview(next_wave_data: Dictionary):
    _clear_preview()

    var wave_type    = next_wave_data.get("wave_type", "normal")
    var sun_center   = Vector2(640, 360)
    var spawn_radius = 390.0
    var spawn_positions = []

    if wave_type == "clash" or wave_type == "boss":
        var groups = next_wave_data.get("clash_groups", [])
        if groups.size() > 0:
            var first_group = groups[0]
            var count   = first_group.get("variants", []).size()
            var pattern = first_group.get("spawn_pattern", "random")
            for i in min(count, 16):   # cap at 16 preview lines for clarity
                var angle = (float(i) / float(count)) * TAU
                match pattern:
                    "ring":
                        spawn_positions.append(sun_center + Vector2(cos(angle), sin(angle)) * spawn_radius)
                    "v_shape":
                        var half = count / 2
                        var side = 1 if i < half else -1
                        var idx  = i if i < half else i - half
                        var a2   = -PI/2.0 + side * (float(idx+1)/float(half+1)) * (PI/3.0)
                        spawn_positions.append(sun_center + Vector2(cos(a2), sin(a2)) * spawn_radius)
                    _:
                        spawn_positions.append(sun_center + Vector2(cos(angle), sin(angle)) * spawn_radius)
    else:
        # Normal/formation: show 8 spread ghost paths
        for i in 8:
            var angle = (float(i) / 8.0) * TAU + randf() * 0.3
            spawn_positions.append(sun_center + Vector2(cos(angle), sin(angle)) * spawn_radius)

    for sp in spawn_positions:
        var line = Line2D.new()
        line.add_point(sp)
        line.add_point(sun_center)
        line.width          = 1.5
        line.default_color  = Color(1.0, 0.3, 0.1, 0.25)
        line.z_index        = -1
        get_tree().current_scene.add_child(line)
        _preview_lines.append(line)

        line.modulate.a = 0.0
        var tw = line.create_tween()
        tw.tween_property(line, "modulate:a", 1.0, 0.4)

func _clear_preview():
    for line in _preview_lines:
        if is_instance_valid(line):
            line.queue_free()
    _preview_lines.clear()
```

Wire into the prep phase start:

```gdscript
func _on_prep_started(next_wave_num: int):
    if next_wave_num <= 12:
        var path = "res://data/waves/wave_%02d.json" % next_wave_num
        if FileAccess.file_exists(path):
            var f    = FileAccess.open(path, FileAccess.READ)
            var data = JSON.parse_string(f.get_as_text())
            f.close()
            show_wave_preview(data)

    # Auto-clear when the wave actually starts
    wave_manager.wave_started.connect(func(_n, _name, _hint): _clear_preview(), CONNECT_ONE_SHOT)
```

---

## 9. Physics — Stellar Gravity on Enemies

Instead of constant-speed movement, enemies now experience **real gravitational acceleration** toward the Sun. Lighter enemies fall fast. Heavy enemies (Burrowers, Prime) resist. Enemies accelerate naturally as they approach the Sun — which makes large swarms in late waves feel genuinely terrifying.

### The Physics Model

```
F = GRAVITY_CONST / r²
acceleration = F / mass
new_velocity += acceleration * direction_to_sun * delta
```

Velocity is capped at `max_speed` to prevent enemies teleporting at close range.

### Mass Table

| Variant | Mass | Effect |
|---------|------|--------|
| Drifter | 1.0 | Clear gravity pull, accelerates noticeably |
| Bloom | 1.5 | Moderate pull |
| Burrower | 3.0 | Heavy — slow and steady, resists gravity |
| Mimic | 0.8 | Lightest — accelerates most dramatically |
| Farmer | 1.2 | Average |
| Prime | 8.0 | Nearly immune — moves on its own schedule |

### Changes to `gdextension/src/astrophage.h`

Add to the `private:` section:

```cpp
double  m_mass;
double  m_velocity_x;
double  m_velocity_y;
double  m_max_speed;
bool    m_use_gravity;
```

### Changes to `gdextension/src/astrophage.cpp`

In `setup()`, after the variant stats table:

```cpp
// Mass table — indexed by Variant enum order (0=DRIFTER, 1=BLOOM, ... 5=PRIME)
double mass_table[] = { 1.0, 1.5, 3.0, 0.8, 1.2, 8.0 };
m_mass       = mass_table[std::max(0, std::min(variant, 5))];
m_velocity_x = 0.0;
m_velocity_y = 0.0;
m_max_speed  = m_speed * 2.5;
m_use_gravity = true;
```

Replace the movement section of `_process()`:

```cpp
void Astrophage::_process(double delta) {
    if (m_is_burrowing) return;

    Vector2 pos    = get_global_position();
    Vector2 to_sun = m_sun_position - pos;
    double dist    = to_sun.length();
    if (dist <= 0.001) return;

    Vector2 dir = to_sun / static_cast<float>(dist);

    if (m_use_gravity) {
        // GRAVITY_CONST tuned so enemies arrive in ~8–12s from spawn radius 390px
        const double GRAVITY_CONST = 18000.0;
        double accel = GRAVITY_CONST / (dist * dist / m_mass);
        accel = std::min(accel, 400.0);

        m_velocity_x += dir.x * accel * delta;
        m_velocity_y += dir.y * accel * delta;

        // Cap to terminal velocity (affected by Cryo slow etc.)
        double current_speed = std::sqrt(m_velocity_x*m_velocity_x + m_velocity_y*m_velocity_y);
        double capped_speed  = std::min(current_speed, m_max_speed * m_speed_modifier);
        if (current_speed > 0.001) {
            m_velocity_x = (m_velocity_x / current_speed) * capped_speed;
            m_velocity_y = (m_velocity_y / current_speed) * capped_speed;
        }

        set_global_position(pos + Vector2(
            static_cast<float>(m_velocity_x * delta),
            static_cast<float>(m_velocity_y * delta)
        ));
    } else {
        // Legacy: straight-line (keep for testing/fallback)
        set_global_position(pos + dir * static_cast<float>(m_speed * m_speed_modifier * delta));
    }

    if (dist < 40.0f) {
        emit_signal("reached_corona");
        queue_free();
    }
}
```

> Add `m_velocity_x(0.0), m_velocity_y(0.0), m_mass(1.0), m_max_speed(150.0), m_use_gravity(true)` to the constructor initializer list.

---

## 10. Physics — Gravity-Curved Projectiles

Upgraded Helios Cannon (level ≥ 2) and Tardigrade Bomb (level ≥ 2) fire **physics projectiles** that arc under stellar gravity. Shots from the outer ring curve more visibly. Shots aimed "outward" can still curve back and hit enemies on re-entry.

### New File: `scripts/entities/physics_projectile.gd`

```gdscript
extends Node2D

const GRAVITY_CONST:  float = 12000.0   # lighter than enemy gravity
const MAX_LIFETIME:   float = 4.0       # auto-despawn if no hit
const CORONA_RADIUS:  float = 40.0      # absorbed by sun if too close

var damage:     float   = 80.0
var tower_type: String  = "helios_cannon"
var velocity:   Vector2 = Vector2.ZERO
var sun_pos:    Vector2 = Vector2(640, 360)
var lifetime:   float   = 0.0

const RING_RADII:            Array = [80.0, 140.0, 210.0, 290.0]
const RING_BOOST_DAMAGE_MULT: float = 1.15    # +15% per ring crossed inward
const RING_DEFLECT_ANGLE:     float = 0.12    # radians of deflection on outward cross

var _last_dist_to_sun:    float = 9999.0
var _rings_crossed_inward: int  = 0

@onready var sprite = $Sprite2D

func setup(dmg: float, initial_velocity: Vector2, sun_center: Vector2, type: String):
    damage     = dmg
    velocity   = initial_velocity
    sun_pos    = sun_center
    tower_type = type

func _process(delta: float):
    lifetime += delta
    if lifetime > MAX_LIFETIME:
        queue_free()
        return

    var pos    = global_position
    var to_sun = sun_pos - pos
    var dist   = to_sun.length()

    if dist < CORONA_RADIUS:
        queue_free()
        return

    # Stellar gravity pull
    var accel_mag = GRAVITY_CONST / max(dist * dist, 100.0)
    accel_mag = min(accel_mag, 600.0)
    velocity += to_sun.normalized() * accel_mag * delta

    global_position += velocity * delta
    rotation = atan2(velocity.y, velocity.x)

    _check_ring_crossings()

    # Collision check against enemies
    for enemy in get_tree().get_nodes_in_group("astrophage"):
        if not is_instance_valid(enemy):
            continue
        if global_position.distance_to(enemy.global_position) < 14.0:
            enemy.take_hit(damage, tower_type)
            queue_free()
            return

func _check_ring_crossings():
    var dist = global_position.distance_to(sun_pos)
    for r in RING_RADII:
        if _last_dist_to_sun > r and dist <= r:
            # Crossed inward — damage boost
            _rings_crossed_inward += 1
            damage *= RING_BOOST_DAMAGE_MULT
            _flash_ring(r)
        elif _last_dist_to_sun < r and dist >= r:
            # Crossed outward — slight deflection
            var deflect = Vector2(-velocity.y, velocity.x).normalized()
            velocity += deflect * velocity.length() * RING_DEFLECT_ANGLE
    _last_dist_to_sun = dist

func _flash_ring(radius: float):
    var ring_mgr = get_tree().get_first_node_in_group("orbital_ring_manager")
    if ring_mgr and ring_mgr.has_method("flash_ring_at_radius"):
        ring_mgr.flash_ring_at_radius(radius)
```

### New Scene: `scenes/entities/physics_projectile.tscn`

```
Node2D  [physics_projectile.gd]
└── Sprite2D  [texture: bullet_physics_1.png]
```

No CollisionShape2D needed — distance checks are done manually in `_process()`.

### Changes to `orbital_tower.gd`

In `_spawn_bullet()`, branch on upgrade level:

```gdscript
func _spawn_bullet(target, dmg: float, type: String):
    var use_physics = (
        (type == "helios_cannon"   and upgrade_level >= 2) or
        (type == "tardigrade_bomb" and upgrade_level >= 2)
    )

    if use_physics:
        _spawn_physics_projectile(target, dmg, type)
    else:
        # Original homing bullet — unchanged
        var bullet = bullet_scene.instantiate()
        get_tree().current_scene.add_child(bullet)
        bullet.global_position = global_position
        bullet.setup(dmg, target, type, chain_count)

func _spawn_physics_projectile(target, dmg: float, type: String):
    var phys_scene = preload("res://scenes/entities/physics_projectile.tscn")
    var proj = phys_scene.instantiate()
    get_tree().current_scene.add_child(proj)
    proj.global_position = global_position

    # C++ method computes the launch velocity including orbital momentum
    var launch_vel = compute_physics_launch_velocity(target.global_position, 280.0)
    proj.setup(dmg, launch_vel, sun_pos, type)
```

Add to `orbital_ring_manager.gd`:

```gdscript
func flash_ring_at_radius(radius: float):
    for ring in rings:
        if abs(ring.radius - radius) < 5.0:
            var tween = ring.create_tween()
            tween.tween_property(ring, "modulate", Color(1.5, 1.2, 0.5), 0.05)
            tween.tween_property(ring, "modulate", Color.WHITE, 0.3)
            break
```

---

## 11. Physics — Slingshot Orbital Shots

A **Slingshot Shot** is a Helios Cannon special mode (right-click the tower, costs 50 SC). The projectile launches tangentially — solar gravity pulls it into a partial orbital arc, and it strikes enemies from the opposite side of the Sun. Great for hitting enemies behind your own ring line.

### Changes to `scripts/entities/orbital_tower.gd`

```gdscript
func try_slingshot_shot():
    if tower_type != "helios_cannon":
        return
    if not GameState.spend_credits(50):
        return   # not enough SC

    var phys_scene = preload("res://scenes/entities/physics_projectile.tscn")
    var proj = phys_scene.instantiate()
    get_tree().current_scene.add_child(proj)
    proj.global_position = global_position

    # Tangential launch — gravity curves it into orbit, then spirals inward
    var orbital_tangent = Vector2(-sin(angle), cos(angle))
    var inward          = (sun_pos - global_position).normalized()
    var sling_vel       = orbital_tangent * 420.0 + inward * 60.0

    proj.setup(160.0, sling_vel, sun_pos, "helios_cannon")  # 2× damage — it's expensive
    AudioManager.play_sfx("slingshot_fire")
```

Wire to right-click in `orbital_slot.gd`:

```gdscript
func _input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
        if event.pressed and _is_hovered and placed_tower != null:
            if placed_tower.tower_type == "helios_cannon":
                placed_tower.try_slingshot_shot()
```

> Add a HUD tooltip: *"Right-click Helios Cannon → Slingshot Shot (50 SC)"* visible when hovering an occupied Helios Cannon slot.

---

## 12. Physics — Ring Collision Damage Boost

Physics projectiles gain **+15% damage** each time they cross a ring boundary inward (closer to the Sun). This is already implemented inside `physics_projectile.gd` in Section 10 (`_check_ring_crossings()`). No additional changes needed.

**Summary of behavior:**
- Projectile crosses Ring 4 → Ring 3 boundary inward: damage × 1.15, ring flashes gold
- Projectile crosses Ring 3 → Ring 2 inward: damage × 1.15 again (cumulative)
- Projectile crosses a boundary **outward**: slight angular deflection (0.12 rad), no damage change
- At max inward crossings (4 rings): theoretical max multiplier = 1.15⁴ ≈ 1.75× damage

---

## 13. C++ Extensions for Physics

These additions expose the physics launch calculation to GDScript and bind the slingshot mode flag.

### `gdextension/src/orbital_tower.h`

Add to `private:`:

```cpp
bool   m_slingshot_mode;
double m_slingshot_charge;
```

Add to `public:`:

```cpp
bool    get_slingshot_ready() const { return m_slingshot_charge >= 1.0; }
void    set_slingshot_mode(bool v)  { m_slingshot_mode = v; }
Vector2 compute_physics_launch_velocity(const Vector2& target_pos, double base_speed) const;
```

### `gdextension/src/orbital_tower.cpp`

```cpp
Vector2 OrbitalTower::compute_physics_launch_velocity(
    const Vector2& target_pos, double base_speed) const
{
    Vector2 to_target = (target_pos - get_global_position()).normalized();

    // Tangent to the orbital path — perpendicular to the radial direction
    Vector2 tangent(
        static_cast<float>(-std::sin(m_angle)),
        static_cast<float>( std::cos(m_angle))
    );

    // Inherit 60% of the tower's current orbital velocity
    double orbital_contribution = m_angular_velocity * m_ring_radius * 0.6;

    return to_target * static_cast<float>(base_speed)
         + tangent   * static_cast<float>(orbital_contribution);
}
```

In `_bind_methods()`:

```cpp
ClassDB::bind_method(
    D_METHOD("compute_physics_launch_velocity", "target_pos", "base_speed"),
    &OrbitalTower::compute_physics_launch_velocity
);
ClassDB::bind_method(D_METHOD("get_slingshot_ready"), &OrbitalTower::get_slingshot_ready);
ClassDB::bind_method(D_METHOD("set_slingshot_mode", "v"), &OrbitalTower::set_slingshot_mode);
```

Also add to constructor initializer list:

```cpp
m_slingshot_mode(false), m_slingshot_charge(0.0)
```

---

## 14. Updated Wave Manager (Full Reference)

Complete top section of `scripts/managers/wave_manager.gd` with all v2 systems integrated:

```gdscript
extends Node

const WAVE_COUNT: int = 12
const VARIANT_MAP: Dictionary = {
    "drifter":  0,
    "bloom":    1,
    "burrower": 2,
    "mimic":    3,
    "farmer":   4,
    "prime":    5,
}

var current_wave:    int        = 0
var wave_data:       Dictionary = {}
var spawn_queue:     Array      = []
var active_enemies:  int        = 0
var wave_active:     bool       = false
var spawn_timer:     float      = 0.0
var event_triggered: bool       = false
var _wave_start_time: float     = 0.0

@export var astrophage_scene: PackedScene

signal wave_started(wave_num: int, wave_name: String, tutorial_hint: String)
signal wave_complete(wave_num: int, reward: int)
signal all_waves_complete
signal event_fired(event_type: String, event_data: Dictionary)

func start_wave(wave_num: int):
    if wave_num > WAVE_COUNT:
        emit_signal("all_waves_complete")
        return

    current_wave     = wave_num
    event_triggered  = false
    _wave_start_time = Time.get_ticks_msec() / 1000.0

    var path = "res://data/waves/wave_%02d.json" % wave_num
    if not FileAccess.file_exists(path):
        push_error("Wave file missing: " + path)
        return

    var file  = FileAccess.open(path, FileAccess.READ)
    wave_data = JSON.parse_string(file.get_as_text())
    file.close()

    var wave_type = wave_data.get("wave_type", "normal")
    var hint      = wave_data.get("tutorial_hint", "")
    emit_signal("wave_started", wave_num, wave_data.get("name", "Wave %d" % wave_num), hint)
    GameState.set_phase(GameState.Phase.WAVE_ACTIVE)

    match wave_type:
        "clash", "boss": _start_clash_wave()
        "formation":     _start_formation_wave()
        _:               _start_normal_wave()

func _process(delta):
    if not wave_active:
        return
    if spawn_queue.size() > 0:
        spawn_timer -= delta
        if spawn_timer <= 0:
            var entry = spawn_queue.pop_front()
            _spawn_enemy_at(entry.get("variant", 0), _random_spawn_pos())
            spawn_timer = wave_data.get("spawn_interval", 2.0)
    _check_events()
    _check_wave_clear()

func _random_spawn_pos() -> Vector2:
    var angle = randf() * TAU
    return Vector2(640, 360) + Vector2(cos(angle), sin(angle)) * 390.0

func _on_enemy_defeated(_reward: int):
    active_enemies -= 1

func _on_enemy_breached():
    GameState.on_enemy_breach()
```

---

## 15. Testing Checklist v2

Complete this checklist in order — catch regressions early.

### Wave System

- [ ] Wave 1 spawns 6 Drifters at 3.5s interval — feels tutorial-slow
- [ ] Wave 6 spawns 10 Drifters simultaneously in a ring (clash group 1, `delay_before: 0.0`)
- [ ] Wave 6 second clash group arrives at ~5s delay
- [ ] Wave 6 third clash group arrives at ~14s delay
- [ ] Wave 9 all three clash groups fire with correct delays
- [ ] Wave 11 spawns 94+ enemies across three bursts
- [ ] Wave 12 Prime spawns at `delay_before: 35.0` after the opening clash
- [ ] Wave 12 total enemy count = 107 before Prime's minion spawns
- [ ] Wave banner shows next-wave preview after each wave clear
- [ ] Clash wave banner reads "MASSIVE WAVE APPROACHING — N ENEMIES!"
- [ ] Boss wave banner reads "☠  ASTROPHAGE PRIME DETECTED" before wave 12
- [ ] Counter-attack fires when wave clears faster than `escalation_threshold_seconds`
- [ ] Counter-attack banner text appears: "⚠  COUNTER-ATTACK!"
- [ ] Ghost preview lines appear during prep phase, cleared when wave starts
- [ ] V-shape spawns enemies in a V pointing at the Sun
- [ ] Ring spawns enemies evenly distributed around the spawn circle
- [ ] Spiral spawns enemies along a curved arm

### Physics — Enemies

- [ ] Drifters visibly accelerate as they approach the Sun
- [ ] Burrowers move more steadily than Mimics (mass difference visible)
- [ ] Prime barely accelerates — feels like it chooses its own trajectory
- [ ] Cryo slow still works correctly under gravity movement (speed modifier applied)

### Physics — Projectiles

- [ ] Helios Cannon at upgrade level ≥ 2 fires a physics projectile with visible arc
- [ ] Tardigrade Bomb at upgrade level ≥ 2 fires a physics projectile
- [ ] Physics projectile curves visibly compared to homing bullet
- [ ] Outer-ring physics shot curves more than inner-ring shot
- [ ] Ring briefly flashes gold when projectile crosses inward
- [ ] Damage increases after each ring crossing (+15% per ring, shown or logged)
- [ ] Slingshot shot costs 50 SC — deducted correctly
- [ ] Slingshot projectile arcs around Sun, can hit enemies on far side
- [ ] Physics projectile auto-despawns after 4 seconds if no hit

### Boss — Astrophage Prime

- [ ] Prime enters Shell phase first — immune to all except Bio-Lab
- [ ] Prime transitions to Active on Shell HP depletion
- [ ] Prime transitions to Frenzy on Active HP depletion — red modulate, scale 2.5×
- [ ] Frenzy phase spawns 2 Drifters every 1.5 seconds
- [ ] Drifters spawned by Prime grant Sol Credits when killed
- [ ] Frenzy minion spawning stops when Prime dies
- [ ] `prime_phase_shift.wav` plays on phase transition

### C++ Bindings

- [ ] `compute_physics_launch_velocity()` callable from GDScript — no errors in output
- [ ] `get_slingshot_ready()` returns correct boolean
- [ ] Enemy `m_mass` set correctly per variant in `setup()` (check with print in test build)
- [ ] Gravity acceleration visibly scales with 1/r² — enemies noticeably faster close to Sun

---

## 16. Glossary Additions

| Term | Definition |
|------|-----------|
| **Clash Wave** | A wave where enemies spawn in simultaneous bursts instead of one-by-one. Creates PvZ-style "huge wave" moments. |
| **Clash Group** | A single burst within a clash wave. Each group has a `delay_before` to stagger bursts. |
| **Formation** | A geometric spawn pattern: `ring`, `v_shape`, `spiral`, `random`, or `center_top`. |
| **Escalation Counter-Attack** | A bonus retaliatory wave that fires if the player clears a wave faster than `escalation_threshold_seconds`. |
| **Wave Preview** | Ghost path lines drawn during the prep phase showing incoming enemy approach vectors. |
| **Physics Projectile** | A projectile that curves under stellar gravity. Fired by upgraded Helios Cannon and Tardigrade Bomb. |
| **Slingshot Shot** | Helios Cannon special: fires tangentially so the shot arcs around the Sun and strikes from the opposite side. Costs 50 SC. |
| **Ring Collision Boost** | Physics projectiles gain +15% damage each time they cross a ring boundary inward, up to 4 rings. |
| **Stellar Gravity (Enemy)** | Enemy movement driven by `F = GRAVITY_CONST / r²` rather than constant speed. All enemies accelerate toward the Sun. |
| **GRAVITY_CONST** | Tuned constant replacing G×M in the simplified gravity formula. 18000.0 for enemies, 12000.0 for projectiles. |
| **Mass** | Per-variant enemy property that controls gravity resistance. Drifter = 1.0 (light), Prime = 8.0 (nearly immune). |
| **Frenzy Phase** | Astrophage Prime's final phase — faster, larger, and continuously spawns Drifter minions until killed. |

---

## 17. Asset Revision Guide

### Art Direction

The goal is a sharp, dark sci-fi look — consistent with the game's existing UI (dark deep-space background, glowing orange Sun, cyan-gold HUD).

| Principle | Spec |
|-----------|------|
| Palette | Deep navy/black, electric cyan (`#00E5FF`) and solar gold (`#FFB830`) accents |
| Silhouettes | High contrast, readable at 32–64px, strong outer rim light |
| Enemies | Organic alien microorganisms — glowing cellular membranes, tendrils, bioluminescent spots |
| Towers | Already good — compact mechanical hex modules. No changes needed unless revising |
| Style | Clean stylized sci-fi digital painting. NOT pixel art. NOT cartoon. NOT photorealistic |

### Enemy Animation Sets

Each of the 5 standard enemies + 3 Prime phases needs these animations. All use `AnimatedSprite2D` in Godot.

> ⚠️ **Transparent-body enemies (Bloom, Photon Mimic):** These have semi-transparent cellular membranes. Do NOT use remove.bg for these — it will eat into the translucent parts. Instead, use **GIMP → Colors → Color to Alpha** which mathematically removes only the background color while preserving partial transparency. Generate these two enemies on a **magenta (#FF00FF)** background instead of lime green for cleanest results. See the Gemini prompts file for full details.

**Standard enemy animations (Drifter, Bloom, Burrower, Mimic, Farmer):**

| Animation | Frames | FPS | Loop |
|-----------|--------|-----|------|
| `idle` | 2 | 4 | Yes |
| `move` | 4 | 8 | Yes |
| `hit` | 2 | 10 | No |
| `die` | 4 | 10 | No |

**Astrophage Prime (boss) — 3 separate sprite sets:**

| Phase | Animations | Frames | Notes |
|-------|------------|--------|-------|
| `shell` | idle (2), move (4) | 6 total | No hit/die — shell can only be broken by Bio-Lab |
| `active` | idle (2), move (4), die (4) | 10 total | Die plays only on Shell→Active transition |
| `frenzy` | idle (2), move (4), die (4) | 10 total | Die plays when Prime is actually killed |

Switch Prime's `AnimatedSprite2D` texture to the correct phase sprite set when `prime_phase` changes.

### Enemy Descriptions

**Drifter** — free-floating alien microorganism  
- Colors: coral-orange membrane (`#FF5030`), warm amber inner glow  
- Shape: irregular rounded cell body, ~48×48px, trailing micro-filaments  

**Bloom** — bloated alien cell that splits into 3 Drifters on direct damage  
- Colors: magenta-pink body (`#FF2080`), glowing green core (`#00FF88`)  
- Shape: round and swollen, ~52×52px, surface tension visible  

**Coronal Burrower** — armored organism that drills into the corona  
- Colors: dark burnt-sienna carapace (`#4A2000`), amber glowing seams (`#FF8C00`)  
- Shape: segmented teardrop with drill tip, ~40×56px  

**Photon Mimic** — cloaked disc that absorbs photon energy (invisible to Photon Splitters)  
- Colors: iridescent purple-cyan shimmer (`#5020DD` → `#00AAFF`), mostly transparent  
- Shape: layered concentric disc, ~50×50px, fades to nothing at edges  

**Solar Farmer** — star-shaped organism that absorbs energy-type damage and gains HP  
- Colors: solar gold (`#FFB830`), bright photon-absorber tips (`#FFFF60`)  
- Shape: 5-armed star, ~54×54px, arms retract during movement  

**Astrophage Prime (Shell)** — sealed, armored, nearly impervious  
- Colors: dark charcoal plates (`#252535`), dim cyan cracks (`#004466`)  
- Shape: large multi-layered disc, ~80×80px  

**Astrophage Prime (Active)** — shell cracked open, orange core exposed, tentacles out  
- Colors: deep orange-red core (`#FF4400`), dark cracked shell fragments  
- Shape: ~80×80px, 4–6 organic tentacles extending outward  

**Astrophage Prime (Frenzy)** — enraged, white-hot core, maximum tentacle spread  
- Colors: blood-red body (`#CC0000`), near-white-hot center  
- Shape: ~80×80px, 6–8 tentacles fully flared, energy distortion halo  

### Projectile & FX Sprites

| File | Frames | Description |
|------|--------|-------------|
| `bullet_bio_1/2/3.png` | 3 | Green organic orb (`#00FF88`), frame 3 = motion blur trail |
| `bullet_cryo_1/2.png` | 2 | Ice shard (`#80C8FF`), frame 2 = frost trail |
| `bullet_photon_1/2.png` | 2 | Thin cyan-white laser bolt (`#00E5FF`), frame 2 = stretched |
| `bullet_tardigrade_1/2.png` | 2 | Olive-green bomb shell, frame 2 = spinning |
| `bullet_physics_1/2.png` | 2 | **New** — amber-gold teardrop (`#FFB830`), frame 2 = curved trail |
| `cryo_slow.png` | 1 | Ice ring overlay for slowed enemies, center transparent |
| `explosion_sheet.png` | 6 | White flash → orange fireball → smoke → fade, 64×64 per frame |
| `wave_preview_line.png` | 1 | Small faint red dot/arrow (`#FF3322`, 40% alpha) for ghost path lines |

### Audio

#### Background Music — `assets/audio/bgm/`

| File | When | Mood |
|------|------|------|
| `main_menu.ogg` | Main menu | Mysterious slow ambient, sparse strings, hopeful but ominous |
| `waves_1.ogg` | Waves 1–4 | Tense minimal — low strings, distant radar pings |
| `waves_2.ogg` | Waves 5–8 | More active — percussion kicks in, rising stakes |
| `waves_3.ogg` *(new)* | Waves 9–11 | Driving urgent — full percussion, brass stabs, relentless |
| `boss.ogg` *(new)* | Wave 12 | Intense climax — full orchestra, distorted bass |
| `end.ogg` | End screen | Resolution — victory fanfare or grief fade |

#### SFX — `assets/audio/sfx/`

| File | Status | Description |
|------|--------|-------------|
| `enemy_die.wav` | Revise | Wet organic burst, membrane pop, ~0.2s |
| `enemy_breach.wav` | Revise | Deep thud + rising alarm tone, ~0.5s |
| `wave_start.wav` | Revise | Radar ping + low rumble, ~0.6s |
| `wave_clear.wav` | Revise | Short rising chime, clean, ~0.5s |
| `sun_hurt.wav` | Revise | Deep solar groan, resonant low frequency, ~0.7s |
| `game_over.wav` | Revise | Slow descending tone + reverb tail, ~2.0s |
| `flare_trigger.wav` | Keep | Works as-is |
| `physics_fire.wav` | **New** | Low charged "whomp", heavier than normal shoot, ~0.4s |
| `clash_incoming.wav` | **New** | Deep space rumble building to surge, plays per clash burst, ~1.0s |
| `counter_attack.wav` | **New** | Two-tone alarm sting, urgent, ~0.5s |
| `prime_phase_shift.wav` | **New** | Massive resonant boom on phase transition, ~1.5s |
| `slingshot_fire.wav` | **New** | Elastic energy twang + whoosh, ~0.5s |

**Free SFX sources:** freesound.org (Creative Commons filter), sfxr.me / jsfxr.com, kenney.nl/assets

### File Naming & Godot Setup

```
assets/sprites/enemies/
  Drifter_idle_1.png       Drifter_idle_2.png
  Drifter_move_1.png  ...  Drifter_move_4.png
  Drifter_hit_1.png        Drifter_hit_2.png
  Drifter_die_1.png   ...  Drifter_die_4.png
  [repeat for Bloom, Coronal Burrower, Photon Mimic, Solar Farmer]

  ASTROPHAGE PRIME_shell_idle_1.png  ...  ASTROPHAGE PRIME_shell_move_4.png
  ASTROPHAGE PRIME_active_idle_1.png ...  ASTROPHAGE PRIME_active_die_4.png
  ASTROPHAGE PRIME_frenzy_idle_1.png ...  ASTROPHAGE PRIME_frenzy_die_4.png

assets/sprites/fx/
  bullet_bio_1.png  bullet_bio_2.png  bullet_bio_3.png
  bullet_cryo_1.png  bullet_cryo_2.png
  bullet_photon_1.png  bullet_photon_2.png
  bullet_tardigrade_1.png  bullet_tardigrade_2.png
  bullet_physics_1.png  bullet_physics_2.png  [NEW]
  cryo_slow.png
  explosion_sheet.png
  wave_preview_line.png  [NEW]
```

In Godot, load via `SpriteFrames` resource: add each animation by name, drag PNGs in order as frames, set FPS and loop as listed above.

---

> **Build order:** Wave JSONs first → Wave Banner → Clash Spawning → Stellar Gravity → Physics Projectiles → Slingshot → Prime Frenzy → Wave Preview → Escalation.
>
> **Asset order:** Idle frames for all enemies first to confirm art style, then move/hit/die. Towers last since they already look good.
>
> *"Defend me, defend me! — Oa ka Perk!"*


---

## 18. Using Cursor + Codex Together

You now have access to both **Cursor** (AI code editor) and **Codex** (your main AI agent). Here is how to use them together effectively for Perk the Star.

### What Each Tool is Best At

| Tool | Best For | Not Great For |
|------|----------|---------------|
| **Codex** | Large refactors across many files, generating whole new systems from a description, running and testing code in a sandbox | Fine UI tweaks, quick one-liners, explaining why something broke |
| **Cursor** | In-editor autocomplete and inline edits, understanding your existing codebase, quick fixes and debugging while you're actively coding, chatting about a specific file open in front of you | Long multi-file generations from scratch |

Think of it this way: **Codex architects, Cursor finishes**.

---

### Workflow: Cursor for GDScript, Codex for C++

Your project splits naturally along this line:

**Use Cursor for GDScript work:**
- Open `scripts/managers/wave_manager.gd` in Cursor
- Highlight the `_start_normal_wave()` function → Cmd+K → "Add clash wave support using this new JSON field: clash_groups"
- Cursor can see your whole GDScript codebase and suggest changes that respect your existing variable names

**Use Codex for C++ GDExtension work:**
- Codex is better for generating the `astrophage.cpp` gravity physics changes because it can write a full implementation from a spec without needing to see the surrounding code
- Give Codex the header file (`astrophage.h`) and tell it exactly what to add
- Paste the output into Cursor for cleanup and integration

---

### Cursor-Specific Tips for This Project

**1. Add your project as context**
Open the entire `perk-the-star` folder in Cursor. This lets Cursor's codebase indexing understand your node structure, signal names, and variable naming conventions before you ask it anything.

**2. Use `@file` references**
In Cursor chat, type `@wave_manager.gd` to pull that file into context. This is much more reliable than pasting code manually. Example:
```
@wave_manager.gd — add a _start_clash_wave() method that reads clash_groups from wave_data and spawns each group with a delay using create_timer
```

**3. Use `.cursorrules` for your project conventions**
Create a file called `.cursorrules` in your project root. Cursor reads this before every prompt. Add your conventions so it never generates code that breaks them:

```
# .cursorrules — Perk the Star
- This is a Godot 4 project with C++ GDExtension
- GDScript files use snake_case for functions and variables
- Signals are emitted with emit_signal(), not signal.emit() 
- All enemy variants are defined in astrophage.gd Variant enum
- VARIANT_MAP in wave_manager.gd maps string names to enum ints
- Do not use global variables
- Wave JSON files are in data/waves/ named wave_01.json through wave_12.json
- The sun center is always Vector2(640, 360)
- Spawn radius from sun center is 390.0 px
```

**4. Cursor for debugging the physics**
When your gravity-curved projectiles behave weirdly, open `physics_projectile.gd` in Cursor and use inline chat (Cmd+K on the `_process` function) to ask: "Why might this projectile spiral inward too fast?" — Cursor can reason about the math in context.

**5. Use Cursor's multi-file edit**
For the wave JSON changes (replacing all 12 files), you can ask Cursor in one message:
```
Update all files in data/waves/ — add the "wave_type" field set to "normal" for waves 1-5, "clash" for waves 6, 9, 11, "formation" for waves 7, 10, and "boss" for wave 12
```
Cursor will propose edits to all 12 files at once for you to accept.

---

### Codex + Cursor Handoff Pattern

This is the most efficient pattern for the v2 features:

```
1. Codex: Generate the full implementation spec / skeleton
   → "Write the _start_clash_wave() function for wave_manager.gd given this JSON format..."
   → Codex outputs a complete function

2. Cursor: Paste into the file, use Cursor to integrate it
   → Cursor sees your existing code and flags any naming conflicts
   → Use Cmd+K: "Make this consistent with the existing _start_normal_wave() style"

3. Cursor: Debug and test inline
   → Run the game, see an error, highlight the error line in Cursor
   → Cmd+K: "Fix this: [paste error]"
```

---

### Quick Reference — Which to Use for Each V2 Feature

| Feature | Use |
|---------|-----|
| Replace all 12 wave JSONs | Cursor multi-file edit |
| `_start_clash_wave()` in wave_manager.gd | Codex to draft → Cursor to integrate |
| Wave banner GDScript additions | Cursor (it's a small UI file) |
| `astrophage.cpp` gravity physics | Codex (C++ generation from spec) |
| `physics_projectile.gd` (new file) | Codex to generate → Cursor to refine |
| Ring flash in orbital_ring_manager.gd | Cursor (quick one-function add) |
| Prime frenzy minion spawning | Cursor (extending existing astrophage.gd) |
| `.cursorrules` file | Write once, benefits everything after |

---
*Guide v2.2 — Perk the Star | CMSC 21 Group H | Geo Ceff Gabaisen & Dexter Juevesano*
*All rights reserved.*
