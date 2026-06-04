"""Generate the Perk the Star defense presentation PDF."""

from __future__ import annotations

import math
from pathlib import Path
from textwrap import wrap

from reportlab.lib import colors
from reportlab.lib.pagesizes import landscape
from reportlab.lib.units import inch
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "Perk_The_Star_Defense_Deck.pdf"

PAGE_W, PAGE_H = landscape((13.333 * inch, 7.5 * inch))
MARGIN_X = 0.55 * inch
MARGIN_Y = 0.48 * inch

INK = colors.HexColor("#06101d")
PANEL = colors.HexColor("#091827")
PANEL_2 = colors.HexColor("#0d2234")
CYAN = colors.HexColor("#38ddff")
CYAN_DARK = colors.HexColor("#14566c")
GOLD = colors.HexColor("#f5c45b")
ORANGE = colors.HexColor("#ff7048")
RED = colors.HexColor("#ff3d47")
GREEN = colors.HexColor("#62f0a7")
VIOLET = colors.HexColor("#b891ff")
TEXT = colors.HexColor("#e7f6ff")
MUTED = colors.HexColor("#91aeca")
WHITE = colors.white


def asset(path: str) -> Path:
    return ROOT / path


BG = asset("assets/sprites/backgrounds/battle_nebula_hq.png")
MENU_BG = asset("assets/sprites/backgrounds/menu_nebula.png")

TOWER_ASSETS = [
    ("Photon", "assets/sprites/clean/towers/photon_splitter.png", GOLD),
    ("Cryo", "assets/sprites/clean/towers/cryo_probe.png", CYAN),
    ("Bio-Lab", "assets/sprites/clean/towers/bio_lab.png", GREEN),
    ("Magnetic", "assets/sprites/clean/towers/magnetic_net.png", VIOLET),
    ("Helios", "assets/sprites/clean/towers/helios_cannon.png", ORANGE),
    ("Tardigrade", "assets/sprites/clean/towers/tardigrade_bomb.png", colors.HexColor("#ff83b8")),
]

ENEMY_ASSETS = [
    ("Drifter", "Baseline push", "assets/sprites/clean/enemies/drifter_idle_1.png", ORANGE),
    ("Bloom", "Splitter", "assets/sprites/clean/enemies/bloom_idle_1.png", GOLD),
    ("Burrower", "Sun drain", "assets/sprites/clean/enemies/coronal_idle_1.png", colors.HexColor("#c88952")),
    ("Mimic", "Photon counter", "assets/sprites/clean/enemies/photon_idle_1.png", VIOLET),
    ("Farmer", "Energy absorb", "assets/sprites/clean/enemies/solar_idle_1.png", GREEN),
    ("Prime", "Wave 12 boss", "assets/sprites/clean/enemies/astrophage-shell_idle_1.png", RED),
]


def register_fonts() -> None:
    fonts = {
        "Electrolize": asset("assets/fonts/Electrolize-Regular.ttf"),
        "KenneyFuture": asset("assets/fonts/Kenney Future.ttf"),
        "KenneyFutureNarrow": asset("assets/fonts/Kenney Future Narrow.ttf"),
    }
    for name, path in fonts.items():
        if path.exists():
            pdfmetrics.registerFont(TTFont(name, str(path)))


def fit_font(text: str, font: str, max_size: int, min_size: int, width: float) -> int:
    for size in range(max_size, min_size - 1, -1):
        if pdfmetrics.stringWidth(text, font, size) <= width:
            return size
    return min_size


def draw_image_cover(c: canvas.Canvas, path: Path, x: float, y: float, w: float, h: float, alpha: float = 1.0) -> None:
    if not path.exists():
        return
    img = ImageReader(str(path))
    iw, ih = img.getSize()
    scale = max(w / iw, h / ih)
    sw, sh = iw * scale, ih * scale
    c.saveState()
    c.setFillAlpha(alpha)
    c.drawImage(img, x + (w - sw) / 2, y + (h - sh) / 2, sw, sh, mask="auto")
    c.restoreState()


def draw_image_fit(c: canvas.Canvas, path: Path, x: float, y: float, w: float, h: float, alpha: float = 1.0) -> None:
    if not path.exists():
        return
    img = ImageReader(str(path))
    iw, ih = img.getSize()
    scale = min(w / iw, h / ih)
    sw, sh = iw * scale, ih * scale
    c.saveState()
    c.setFillAlpha(alpha)
    c.drawImage(img, x + (w - sw) / 2, y + (h - sh) / 2, sw, sh, mask="auto")
    c.restoreState()


def line_height(size: float) -> float:
    return size * 1.24


def draw_wrapped(
    c: canvas.Canvas,
    text: str,
    x: float,
    y: float,
    width: float,
    font: str = "Electrolize",
    size: int = 15,
    color: colors.Color = TEXT,
    leading: float | None = None,
    max_lines: int | None = None,
) -> float:
    c.setFont(font, size)
    c.setFillColor(color)
    avg = max(pdfmetrics.stringWidth("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", font, size) / 52, 1)
    chars = max(14, int(width / avg * 0.92))
    lines: list[str] = []
    for chunk in text.split("\n"):
        lines.extend(wrap(chunk, chars) if chunk else [""])
    if max_lines is not None:
        lines = lines[:max_lines]
    step = leading or line_height(size)
    cy = y
    for item in lines:
        c.drawString(x, cy, item)
        cy -= step
    return cy


def draw_centered(c: canvas.Canvas, text: str, x: float, y: float, width: float, font: str, size: int, color: colors.Color) -> None:
    c.setFont(font, size)
    c.setFillColor(color)
    text_w = pdfmetrics.stringWidth(text, font, size)
    c.drawString(x + (width - text_w) / 2, y, text)


def draw_bullet_list(
    c: canvas.Canvas,
    items: list[str],
    x: float,
    y: float,
    width: float,
    font_size: int = 14,
    gap: float = 11,
    color: colors.Color = TEXT,
) -> float:
    cy = y
    for item in items:
        c.setFillColor(CYAN)
        c.circle(x + 3, cy + 4, 2.3, fill=1, stroke=0)
        cy = draw_wrapped(c, item, x + 13, cy, width - 13, size=font_size, color=color, max_lines=3)
        cy -= gap
    return cy


def set_alpha_fill(c: canvas.Canvas, color: colors.Color, alpha: float) -> None:
    c.setFillColor(color)
    c.setFillAlpha(alpha)


def panel(c: canvas.Canvas, x: float, y: float, w: float, h: float, title: str | None = None, accent: colors.Color = CYAN) -> None:
    c.saveState()
    set_alpha_fill(c, PANEL, 0.82)
    c.roundRect(x, y, w, h, 10, fill=1, stroke=0)
    c.setFillAlpha(1)
    c.setStrokeColor(accent)
    c.setLineWidth(0.9)
    c.roundRect(x, y, w, h, 10, fill=0, stroke=1)
    c.setStrokeColor(CYAN_DARK)
    c.line(x + 14, y + h - 16, x + w - 14, y + h - 16)
    if title:
        c.setFont("KenneyFutureNarrow", 12)
        c.setFillColor(accent)
        c.drawString(x + 18, y + h - 12, title.upper())
    c.restoreState()


def tag(c: canvas.Canvas, text: str, x: float, y: float, color: colors.Color = CYAN, w: float | None = None) -> float:
    c.setFont("KenneyFutureNarrow", 10)
    tw = pdfmetrics.stringWidth(text, "KenneyFutureNarrow", 10)
    width = w or tw + 18
    c.saveState()
    c.setFillColor(color)
    c.setFillAlpha(0.14)
    c.roundRect(x, y, width, 18, 7, fill=1, stroke=0)
    c.setFillAlpha(1)
    c.setStrokeColor(color)
    c.setLineWidth(0.6)
    c.roundRect(x, y, width, 18, 7, fill=0, stroke=1)
    c.setFillColor(color)
    c.drawCentredString(x + width / 2, y + 5, text)
    c.restoreState()
    return width


def slide_base(c: canvas.Canvas, num: int, kicker: str, title: str, bg: Path = BG) -> None:
    draw_image_cover(c, bg, 0, 0, PAGE_W, PAGE_H)
    c.saveState()
    c.setFillColor(INK)
    c.setFillAlpha(0.72)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    c.setFillAlpha(1)
    c.restoreState()

    c.saveState()
    c.setStrokeColor(CYAN_DARK)
    c.setLineWidth(0.45)
    for i in range(10):
        x = (i + 1) * PAGE_W / 11
        c.line(x, 0.35 * inch, x, PAGE_H - 0.35 * inch)
    c.restoreState()

    c.setStrokeColor(CYAN)
    c.setLineWidth(1.0)
    c.rect(0.28 * inch, 0.28 * inch, PAGE_W - 0.56 * inch, PAGE_H - 0.56 * inch, fill=0, stroke=1)
    c.setStrokeColor(GOLD)
    c.setLineWidth(0.65)
    c.rect(0.34 * inch, 0.34 * inch, PAGE_W - 0.68 * inch, PAGE_H - 0.68 * inch, fill=0, stroke=1)

    kx, ky = MARGIN_X, PAGE_H - 0.69 * inch
    c.setFillColor(GOLD)
    c.circle(kx + 4, ky + 5, 4, fill=1, stroke=0)
    c.setFont("KenneyFutureNarrow", 10)
    c.setFillColor(MUTED)
    c.drawString(kx + 17, ky, kicker.upper())

    title_size = fit_font(title, "KenneyFuture", 37, 25, PAGE_W - 2 * MARGIN_X)
    c.setFont("KenneyFuture", title_size)
    c.setFillColor(TEXT)
    c.drawString(MARGIN_X, PAGE_H - 1.08 * inch, title)

    c.setFont("KenneyFutureNarrow", 8)
    c.setFillColor(MUTED)
    c.drawRightString(PAGE_W - MARGIN_X, 0.23 * inch, f"{num:02d} / 12")
    c.drawString(MARGIN_X, 0.23 * inch, "PERK THE STAR | SOL DEFENSE CORPS")


def draw_sun_orbits(c: canvas.Canvas, cx: float, cy: float, radius: float, rings: list[tuple[str, int, int, colors.Color]], labels: bool = True) -> None:
    c.saveState()
    for idx, (_, _, _, col) in enumerate(rings):
        r = radius * (0.46 + idx * 0.18)
        c.setStrokeColor(col)
        c.setLineWidth(1.0)
        c.setDash(4, 4)
        c.circle(cx, cy, r, fill=0, stroke=1)
        c.setDash()
        slots = rings[idx][2]
        for s in range(slots):
            ang = -math.pi / 2 + (math.tau * s / slots) + idx * 0.12
            px, py = cx + math.cos(ang) * r, cy + math.sin(ang) * r
            c.setFillColor(col)
            c.circle(px, py, 3.2, fill=1, stroke=0)
    c.setFillColor(GOLD)
    c.setFillAlpha(0.25)
    c.circle(cx, cy, radius * 0.24, fill=1, stroke=0)
    c.setFillAlpha(1)
    c.setFillColor(colors.HexColor("#ffe28a"))
    c.circle(cx, cy, radius * 0.16, fill=1, stroke=0)
    if labels:
        c.setFont("KenneyFutureNarrow", 8.5)
        for idx, (name, period, slots, col) in enumerate(rings):
            y = cy + radius * 0.45 - idx * 22
            c.setFillColor(col)
            c.drawString(cx + radius * 0.88, y, f"{name}: {period}s | {slots} slots")
    c.restoreState()


def slide_1(c: canvas.Canvas) -> None:
    slide_base(c, 1, "DEFENSE BRIEFING", "Perk the Star", MENU_BG)
    draw_sun_orbits(
        c,
        PAGE_W * 0.68,
        PAGE_H * 0.49,
        210,
        [
            ("Corona Belt", 6, 4, GOLD),
            ("Chromosphere", 11, 6, CYAN),
            ("Photosphere", 17, 8, GREEN),
            ("Outer Veil", 26, 10, VIOLET),
        ],
        labels=False,
    )
    draw_image_fit(c, asset("assets/sprites/clean/enemies/astrophage-shell_idle_1.png"), PAGE_W * 0.57, PAGE_H * 0.30, 185, 185, 0.82)
    c.setFont("KenneyFutureNarrow", 22)
    c.setFillColor(CYAN)
    c.drawString(MARGIN_X, PAGE_H - 1.65 * inch, "Single-player orbital tower defense")
    draw_wrapped(
        c,
        "Defend me, defend me! - Oa ka Perk!",
        MARGIN_X,
        PAGE_H - 2.12 * inch,
        420,
        "Electrolize",
        20,
        GOLD,
    )
    draw_bullet_list(
        c,
        [
            "Godot 4.6 prototype with GDScript gameplay and C++ GDExtension entity types.",
            "Towers orbit on four rings, turning placement into timing and coverage.",
            "Built for a five-minute defense demo by Group H: Geo Ceff Gabaisen and Dexter Juevesano.",
        ],
        MARGIN_X,
        PAGE_H - 2.85 * inch,
        405,
        15,
    )
    tag(c, "CMSC 21-A", MARGIN_X, 1.0 * inch, CYAN)
    tag(c, "SOL DEFENSE CORPS", MARGIN_X + 105, 1.0 * inch, GOLD)


def slide_2(c: canvas.Canvas) -> None:
    slide_base(c, 2, "PREMISE", "The Sun is dimming, and the defense window is closing.")
    panel(c, MARGIN_X, 1.05 * inch, 4.7 * inch, 4.65 * inch, "Narrative hook", GOLD)
    draw_wrapped(
        c,
        "The premise borrows the eerie science-fiction pressure of Project Hail Mary: Astrophage-like microorganisms feed on stellar energy, and a slow luminosity drop becomes an existential clock.",
        MARGIN_X + 0.25 * inch,
        5.08 * inch,
        4.1 * inch,
        size=15,
        color=TEXT,
    )
    draw_bullet_list(
        c,
        [
            "Luminosity reports escalate from 0.3% to 2.1% to 4.8% and rising.",
            "The player becomes Sol Commander with twelve waves to keep luminosity above zero.",
            "The gameplay twist is orbital placement: towers sweep across timed engagement arcs.",
        ],
        MARGIN_X + 0.25 * inch,
        3.62 * inch,
        4.1 * inch,
        13,
    )
    panel(c, 5.65 * inch, 1.05 * inch, 6.95 * inch, 4.65 * inch, "Threat model", CYAN)
    draw_sun_orbits(
        c,
        8.27 * inch,
        3.23 * inch,
        155,
        [
            ("Corona Belt", 6, 4, GOLD),
            ("Chromosphere", 11, 6, CYAN),
            ("Photosphere", 17, 8, GREEN),
            ("Outer Veil", 26, 10, VIOLET),
        ],
        labels=True,
    )
    draw_image_fit(c, asset("assets/sprites/clean/enemies/drifter_idle_1.png"), 10.65 * inch, 3.7 * inch, 90, 90)
    draw_image_fit(c, asset("assets/sprites/clean/enemies/bloom_idle_1.png"), 10.95 * inch, 2.45 * inch, 110, 110)
    draw_image_fit(c, asset("assets/sprites/clean/enemies/solar_idle_1.png"), 9.98 * inch, 1.55 * inch, 100, 100)


def slide_3(c: canvas.Canvas) -> None:
    slide_base(c, 3, "GAME IDENTITY", "You command an orbital defense network, not a static grid.")
    roles = [
        ("PLAYER", "Sol Commander: build, upgrade, sell, and trigger Solar Flare."),
        ("OBJECTIVE", "Clear 12 waves while keeping luminosity greater than 0%."),
        ("ECONOMY", "Sol Credits from kills and wave rewards fund towers and upgrades."),
        ("SETTING", "Top-down orbital space around a living Sun."),
        ("OUTCOME", "Win by clearing Prime; lose when the Sun is extinguished."),
    ]
    x = MARGIN_X
    y = 5.22 * inch
    for idx, (label, body) in enumerate(roles):
        px = x + (idx % 2) * 5.9 * inch
        py = y - (idx // 2) * 1.2 * inch
        panel(c, px, py - 0.66 * inch, 5.35 * inch, 0.86 * inch, None, CYAN if idx % 2 == 0 else GOLD)
        tag(c, label, px + 0.15 * inch, py - 0.36 * inch, GOLD, 82)
        draw_wrapped(c, body, px + 1.28 * inch, py - 0.20 * inch, 3.75 * inch, size=12.5, color=TEXT, max_lines=2)
    panel(c, 6.55 * inch, 0.85 * inch, 5.75 * inch, 1.35 * inch, "Core sentence", ORANGE)
    draw_wrapped(
        c,
        "Every credit should buy time, coverage, or control. A beautiful orbit means nothing if the Sun goes dark.",
        6.82 * inch,
        1.67 * inch,
        5.1 * inch,
        size=15,
        color=GOLD,
        max_lines=3,
    )
    draw_sun_orbits(c, 2.75 * inch, 1.49 * inch, 95, [("C", 6, 4, GOLD), ("Ch", 11, 6, CYAN), ("P", 17, 8, GREEN), ("O", 26, 10, VIOLET)], False)


def slide_4(c: canvas.Canvas) -> None:
    slide_base(c, 4, "THREAT ROSTER", "Each Astrophage variant breaks a lazy strategy.")
    start_x = MARGIN_X
    start_y = 4.88 * inch
    cell_w = 3.82 * inch
    cell_h = 1.66 * inch
    for idx, (name, role, path, col) in enumerate(ENEMY_ASSETS):
        px = start_x + (idx % 3) * (cell_w + 0.27 * inch)
        py = start_y - (idx // 3) * (cell_h + 0.34 * inch)
        panel(c, px, py - cell_h, cell_w, cell_h, None, col)
        draw_image_fit(c, asset(path), px + 0.05 * inch, py - cell_h + 0.14 * inch, 1.2 * inch, 1.2 * inch)
        c.setFont("KenneyFutureNarrow", 18)
        c.setFillColor(col)
        c.drawString(px + 1.35 * inch, py - 0.50 * inch, name.upper())
        draw_wrapped(c, role, px + 1.35 * inch, py - 0.82 * inch, 2.1 * inch, size=12.5, color=TEXT)
        tag(c, ["SLOW", "SPLIT", "BURROW", "MIMIC", "ABSORB", "SHELL"][idx], px + 1.35 * inch, py - 1.31 * inch, col)
    draw_wrapped(
        c,
        "Design rule: Mimics punish Photon-only builds, Farmers punish raw energy damage, Burrowers punish weak support coverage, and Prime is the final counterplay exam.",
        MARGIN_X,
        0.88 * inch,
        PAGE_W - 2 * MARGIN_X,
        size=14,
        color=MUTED,
    )


def slide_5(c: canvas.Canvas) -> None:
    slide_base(c, 5, "ORBITAL KIT", "Six towers ride four rings with different engagement rhythms.")
    for idx, (name, path, col) in enumerate(TOWER_ASSETS):
        px = MARGIN_X + idx * 1.43 * inch
        draw_image_fit(c, asset(path), px, 4.42 * inch, 0.82 * inch, 0.82 * inch)
        draw_centered(c, name, px - 0.14 * inch, 4.23 * inch, 1.1 * inch, "KenneyFutureNarrow", 9.5, col)
    draw_sun_orbits(
        c,
        3.3 * inch,
        2.38 * inch,
        132,
        [
            ("Corona Belt", 6, 4, GOLD),
            ("Chromosphere", 11, 6, CYAN),
            ("Photosphere", 17, 8, GREEN),
            ("Outer Veil", 26, 10, VIOLET),
        ],
        True,
    )
    panel(c, 6.45 * inch, 1.1 * inch, 5.92 * inch, 3.75 * inch, "Ring logic", GOLD)
    rows = [
        ("Corona Belt", "6s", "4 slots", "fast early intercept"),
        ("Chromosphere", "11s", "6 slots", "control plus finishers"),
        ("Photosphere", "17s", "8 slots", "Bio-Lab and Magnetic Net"),
        ("Outer Veil", "26s", "10 slots", "long engagement windows"),
    ]
    y = 4.26 * inch
    for name, period, slots, best in rows:
        c.setFont("KenneyFutureNarrow", 12)
        c.setFillColor(CYAN)
        c.drawString(6.75 * inch, y, name.upper())
        c.setFillColor(GOLD)
        c.drawString(8.55 * inch, y, period)
        c.setFillColor(MUTED)
        c.drawString(9.15 * inch, y, slots)
        c.setFillColor(TEXT)
        c.drawString(10.04 * inch, y, best)
        y -= 0.54 * inch
    draw_wrapped(c, "Position updates use polar math: x = sun_x + r cos(theta), y = sun_y + r sin(theta).", 6.75 * inch, 1.78 * inch, 5.1 * inch, size=12.5, color=MUTED)


def slide_6(c: canvas.Canvas) -> None:
    slide_base(c, 6, "PLAYER FLOW", "The Tower Bay stays live, so adaptation happens mid-wave.")
    left = [
        "Build: select tower 1-6 or Tower Bay, then click an orbital slot.",
        "Manage: click placed towers for upgrade stats, cost, and sell refund.",
        "Waves: Space or Enter starts; Auto Start is optional and saved.",
        "Flare: press F during a wave when charged every three cleared waves.",
    ]
    right = [
        "Camera: mouse wheel zoom, drag, WASD, edge pan, and Center Sun.",
        "Intel: wave briefing shows counts, warning tags, and counter hints.",
        "Pause: Esc opens Codex, Settings, Retry, and Main Menu.",
        "Defense posture: react while combat is running, not only between waves.",
    ]
    panel(c, MARGIN_X, 1.05 * inch, 5.75 * inch, 4.55 * inch, "Controls", CYAN)
    draw_bullet_list(c, left, MARGIN_X + 0.28 * inch, 4.9 * inch, 5.1 * inch, 14)
    panel(c, 6.95 * inch, 1.05 * inch, 5.65 * inch, 4.55 * inch, "Briefing loop", GOLD)
    draw_bullet_list(c, right, 7.23 * inch, 4.9 * inch, 5.0 * inch, 14)
    tag(c, "BUILD", MARGIN_X + 0.3 * inch, 0.74 * inch, GOLD)
    tag(c, "ADAPT", MARGIN_X + 1.15 * inch, 0.74 * inch, CYAN)
    tag(c, "SURVIVE", MARGIN_X + 2.02 * inch, 0.74 * inch, GREEN)


def slide_7(c: canvas.Canvas) -> None:
    slide_base(c, 7, "CAMPAIGN ARC", "Twelve JSON waves introduce counters before the Prime exam.")
    waves = [
        (1, "First Contact", "Drifters only", CYAN),
        (3, "Splitting Point", "Bloom introduced", GOLD),
        (4, "Going Under", "Burrower needs Bio-Lab", ORANGE),
        (5, "Invisible Hand", "Mimic forces diversity", VIOLET),
        (6, "Solar Storm", "Auto flare + Cryo disruption", RED),
        (7, "Night Side", "Inner rings blind 20s", CYAN),
        (8, "The Harvest", "Solar Farmer arrives", GREEN),
        (10, "Research Surge", "Bio-Lab 4x speed", GOLD),
        (12, "Astrophage Prime", "Boss + Frenzy event", RED),
    ]
    base_x = 0.9 * inch
    y = 4.8 * inch
    step = 1.22 * inch
    c.setStrokeColor(CYAN_DARK)
    c.setLineWidth(2)
    c.line(base_x + 0.25 * inch, y + 0.1 * inch, base_x + 10.75 * inch, y + 0.1 * inch)
    for idx, (wave, name, note, col) in enumerate(waves):
        x = base_x + idx * step
        c.setFillColor(col)
        c.circle(x + 0.25 * inch, y + 0.1 * inch, 10, fill=1, stroke=0)
        c.setFont("KenneyFutureNarrow", 11)
        c.setFillColor(INK)
        c.drawCentredString(x + 0.25 * inch, y + 0.05 * inch, str(wave))
        c.saveState()
        c.translate(x + 0.16 * inch, y - 0.28 * inch)
        c.rotate(-58)
        c.setFillColor(TEXT)
        c.drawString(0, 0, name)
        c.restoreState()
        draw_wrapped(c, note, x - 0.10 * inch, 2.07 * inch if idx % 2 else 1.40 * inch, 1.1 * inch, size=9, color=MUTED, max_lines=3)
    panel(c, MARGIN_X, 0.74 * inch, 11.75 * inch, 0.78 * inch, None, GOLD)
    draw_wrapped(
        c,
        "Wave data lives in data/waves/wave_01.json through wave_12.json. Events such as ring_blind, bio_lab_boost, mid_wave_autoflare, and prime_frenzy can be tuned without recompiling.",
        MARGIN_X + 0.22 * inch,
        1.16 * inch,
        11.2 * inch,
        size=12,
        color=TEXT,
        max_lines=2,
    )


def slide_8(c: canvas.Canvas) -> None:
    slide_base(c, 8, "RUN QUALITY", "Victory is not binary; remaining luminosity is the score.")
    stats = [
        ("Luminosity", "0-100%", "Sun health, not restorable", GOLD),
        ("Sol Credits", "0+", "Build and upgrade economy", CYAN),
        ("Flare Charge", "3 waves", "Manual radial burst", ORANGE),
        ("Performance", "tracked", "End-screen run quality", GREEN),
    ]
    for idx, (label, value, note, col) in enumerate(stats):
        px = MARGIN_X + idx * 3.05 * inch
        panel(c, px, 4.0 * inch, 2.68 * inch, 1.42 * inch, None, col)
        c.setFont("KenneyFuture", 20)
        c.setFillColor(col)
        c.drawString(px + 0.18 * inch, 4.78 * inch, value)
        c.setFont("KenneyFutureNarrow", 12)
        c.setFillColor(TEXT)
        c.drawString(px + 0.18 * inch, 4.45 * inch, label.upper())
        draw_wrapped(c, note, px + 0.18 * inch, 4.20 * inch, 2.25 * inch, size=9.8, color=MUTED, max_lines=2)
    panel(c, MARGIN_X, 1.0 * inch, 11.75 * inch, 2.3 * inch, "Victory ranks", GOLD)
    ranks = [
        ("FULL SHINE", ">80%", GOLD),
        ("BRIGHT", "60-80%", CYAN),
        ("DIM BUT ALIVE", "20-60%", GREEN),
        ("LAST LIGHT", "1-20%", ORANGE),
        ("SUN EXTINGUISHED", "0%", RED),
    ]
    x = MARGIN_X + 0.42 * inch
    for name, rng, col in ranks:
        tag(c, name, x, 2.35 * inch, col, 1.84 * inch)
        draw_centered(c, rng, x, 2.00 * inch, 1.84 * inch, "KenneyFutureNarrow", 13, TEXT)
        x += 2.18 * inch


def slide_9(c: canvas.Canvas) -> None:
    slide_base(c, 9, "IMPLEMENTATION", "Signals keep the HUD reactive while combat rules stay centralized.")
    panel(c, MARGIN_X, 1.05 * inch, 4.55 * inch, 4.7 * inch, "Stack", CYAN)
    draw_bullet_list(
        c,
        [
            "Engine: Godot 4.6, Forward Plus, 1920 x 1080.",
            "Gameplay: GDScript modules in scripts/game/.",
            "Native types: C++ GDExtension in gdextension/src/.",
            "Data: JSON waves plus static catalog.",
            "Settings: user://settings.cfg.",
        ],
        MARGIN_X + 0.25 * inch,
        5.05 * inch,
        4.0 * inch,
        13,
    )
    panel(c, 5.55 * inch, 1.05 * inch, 7.05 * inch, 4.7 * inch, "Architecture pattern", GOLD)
    nodes = [
        ("HUD", 6.1, 4.55, CYAN),
        ("signals", 7.95, 4.55, MUTED),
        ("game.gd", 9.7, 4.55, GOLD),
        ("state dict", 9.7, 3.25, GREEN),
        ("HUD render", 7.35, 3.25, CYAN),
    ]
    for label, x, y, col in nodes:
        tag(c, label, x * inch, y * inch, col, 1.24 * inch)
    c.setStrokeColor(MUTED)
    c.setLineWidth(1.2)
    arrows = [
        (7.34, 4.66, 7.95, 4.66),
        (9.18, 4.66, 9.70, 4.66),
        (10.32, 4.47, 10.32, 3.62),
        (9.70, 3.36, 8.58, 3.36),
    ]
    for x1, y1, x2, y2 in arrows:
        c.line(x1 * inch, y1 * inch, x2 * inch, y2 * inch)
    draw_wrapped(
        c,
        "HUD buttons emit intent. game.gd owns spawning, targeting, damage, wave events, and end states. It returns one display dictionary so UI scripts can render without owning combat rules.",
        6.0 * inch,
        2.35 * inch,
        6.2 * inch,
        size=13,
        color=TEXT,
    )


def slide_10(c: canvas.Canvas) -> None:
    slide_base(c, 10, "CLASSES & STRUCTURES", "The core layer is C++ plus two autoload coordinators.")
    panel(c, MARGIN_X, 1.0 * inch, 7.25 * inch, 4.75 * inch, "C++ GDExtension layer", CYAN)
    cpp_rows = [
        ("Astrophage", "Variant, HP, cloaking, burrowing, and Prime phase state."),
        ("OrbitalTower", "Ring orbit, engagement arc, firing, and upgrade-ready tower state."),
        ("SunNode", "Luminosity, burrower drain, and expression/health surface."),
        ("WaveData", "Load and parse JSON wave definitions for spawn/event data."),
    ]
    y = 5.02 * inch
    for name, body in cpp_rows:
        tag(c, "C++", MARGIN_X + 0.25 * inch, y - 0.03 * inch, CYAN, 0.62 * inch)
        c.setFont("KenneyFutureNarrow", 15)
        c.setFillColor(GOLD)
        c.drawString(MARGIN_X + 1.05 * inch, y, name)
        draw_wrapped(c, body, MARGIN_X + 2.62 * inch, y, 4.35 * inch, size=12.5, color=TEXT, max_lines=2)
        y -= 0.85 * inch
    panel(c, 8.1 * inch, 1.0 * inch, 4.5 * inch, 4.75 * inch, "Autoloads", GOLD)
    autoloads = [
        ("GameState", "Luminosity, credits, phase flags, saved settings."),
        ("MusicManager", "Menu, wave, and boss BGM routing."),
    ]
    y = 4.9 * inch
    for name, body in autoloads:
        tag(c, "AUTOLOAD", 8.38 * inch, y - 0.03 * inch, GOLD, 0.96 * inch)
        c.setFont("KenneyFutureNarrow", 16)
        c.setFillColor(CYAN)
        c.drawString(9.58 * inch, y, name)
        draw_wrapped(c, body, 8.38 * inch, y - 0.44 * inch, 3.72 * inch, size=12.3, color=TEXT, max_lines=2)
        y -= 1.35 * inch
    draw_wrapped(
        c,
        "Slide intentionally limited to the C++ and Autoload layers for defense focus.",
        8.38 * inch,
        1.57 * inch,
        3.7 * inch,
        size=11,
        color=MUTED,
    )


def slide_11(c: canvas.Canvas) -> None:
    slide_base(c, 11, "ASSETS & PRESENTATION", "The final art direction is dark sci-fi operations, not cozy pixel art.")
    panel(c, MARGIN_X, 3.45 * inch, 11.75 * inch, 2.18 * inch, "Final sprite set: assets/sprites/clean", CYAN)
    for idx, (_, path, col) in enumerate(TOWER_ASSETS):
        x = MARGIN_X + 0.38 * inch + idx * 1.78 * inch
        draw_image_fit(c, asset(path), x, 4.20 * inch, 0.75 * inch, 0.75 * inch)
        c.setStrokeColor(col)
        c.setLineWidth(0.8)
        c.circle(x + 0.38 * inch, 4.58 * inch, 0.47 * inch, fill=0, stroke=1)
    for idx, (name, _, path, col) in enumerate(ENEMY_ASSETS[:4]):
        x = MARGIN_X + 0.55 * inch + idx * 2.52 * inch
        draw_image_fit(c, asset(path), x, 3.58 * inch, 0.55 * inch, 0.55 * inch)
        draw_centered(c, name, x - 0.15 * inch, 3.49 * inch, 0.9 * inch, "KenneyFutureNarrow", 8.5, col)
    panel(c, MARGIN_X, 1.0 * inch, 5.75 * inch, 1.95 * inch, "Visual grammar", GOLD)
    draw_bullet_list(
        c,
        [
            "Deep nebula backgrounds with cyan/gold HUD framing.",
            "Organic Astrophage silhouettes over clean tactical tower modules.",
            "Readable 1080p operations UI with compact panels and status tags.",
        ],
        MARGIN_X + 0.25 * inch,
        2.36 * inch,
        5.1 * inch,
        11.2,
        gap=7,
    )
    panel(c, 6.95 * inch, 1.0 * inch, 5.65 * inch, 1.95 * inch, "Provenance", CYAN)
    draw_bullet_list(
        c,
        [
            "Kenney Sci-fi UI, Kenney Future fonts, Electrolize.",
            "Screaming Brain Studios nebula backgrounds.",
            "Credits documented in assets/licenses/THIRD_PARTY_ASSETS.md.",
        ],
        7.2 * inch,
        2.36 * inch,
        5.0 * inch,
        11.2,
        gap=7,
    )


def slide_12(c: canvas.Canvas) -> None:
    slide_base(c, 12, "DEMO CLOSE", "Show the orbit, show the counters, then let Prime test the system.", MENU_BG)
    flow = [
        "Main menu -> Play",
        "Build on Corona Belt during Wave 1",
        "Show Wave Intel tags and counter hint",
        "Upgrade a tower mid-wave",
        "Trigger Solar Flare or jump to Prime",
        "Victory or Sun Extinguished rank screen",
    ]
    panel(c, MARGIN_X, 1.05 * inch, 5.35 * inch, 4.72 * inch, "Live demo route", GOLD)
    y = 5.0 * inch
    for idx, item in enumerate(flow, start=1):
        c.setFillColor(GOLD)
        c.circle(MARGIN_X + 0.43 * inch, y + 0.03 * inch, 10, fill=1, stroke=0)
        c.setFillColor(INK)
        c.setFont("KenneyFutureNarrow", 11)
        c.drawCentredString(MARGIN_X + 0.43 * inch, y - 0.03 * inch, str(idx))
        draw_wrapped(c, item, MARGIN_X + 0.78 * inch, y + 0.08 * inch, 4.0 * inch, size=13.5, color=TEXT, max_lines=2)
        y -= 0.63 * inch
    draw_sun_orbits(c, 9.05 * inch, 3.37 * inch, 165, [("C", 6, 4, GOLD), ("Ch", 11, 6, CYAN), ("P", 17, 8, GREEN), ("O", 26, 10, VIOLET)], False)
    draw_image_fit(c, asset("assets/sprites/clean/enemies/astrophage-shell_idle_1.png"), 8.24 * inch, 2.38 * inch, 1.65 * inch, 1.65 * inch, 0.86)
    draw_wrapped(
        c,
        "Closing line: Every credit should buy time, coverage, or control. A beautiful orbit means nothing if the Sun goes dark.",
        6.78 * inch,
        1.23 * inch,
        5.45 * inch,
        size=16,
        color=GOLD,
        max_lines=3,
    )
    draw_centered(c, "QUESTIONS?", 7.0 * inch, 0.72 * inch, 4.85 * inch, "KenneyFuture", 26, CYAN)


SLIDES = [
    slide_1,
    slide_2,
    slide_3,
    slide_4,
    slide_5,
    slide_6,
    slide_7,
    slide_8,
    slide_9,
    slide_10,
    slide_11,
    slide_12,
]


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    register_fonts()
    pdf = canvas.Canvas(str(OUT), pagesize=(PAGE_W, PAGE_H))
    pdf.setTitle("Perk the Star - Defense Presentation")
    pdf.setAuthor("Group H | CMSC 21-A")
    for draw_slide in SLIDES:
        draw_slide(pdf)
        pdf.showPage()
    pdf.save()
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
