"""Facade kit — turns plots and streets into Parts with seeded variation.

Ten authored buildings and a kit of facade pieces produce a strip where every
building feels placed. Buildings get windows (some lit), doors, awnings and
signs; streets get sidewalks, palms, parked cars, dumpsters, fire escapes and
lamps. Everything is a primitive Part with an optional PointLight — no assets.
Landmark plots emit a tagged placeholder the Studio side swaps for a hand-built
model by asset id.
"""

from __future__ import annotations

import random

from plots import Plot
from rbxlx import Part, PointLight, proximity_prompt
import furnish

FLOOR_HEIGHT = 14.0  # studs per floor
BUILDING_DEPTH = 40.0

_TYPE_COLOR = {
    "CLUB": (40, 30, 55),
    "BAR": (48, 38, 44),
    "RESTAURANT": (60, 52, 44),
    "OFFICE": (70, 72, 80),
    "WAREHOUSE": (58, 58, 60),
    "APTS": (78, 70, 62),
    "SHOP": (66, 62, 58),
    "LOT": (52, 52, 50),
    "VACANT": (45, 45, 48),
    "LANDMARK": (90, 80, 70),
}

# Which fraction of windows are lit, and what color, per building type.
_WINDOW_LIT = {
    "CLUB": (0.55, (200, 120, 255)),
    "BAR": (0.5, (255, 190, 110)),
    "RESTAURANT": (0.65, (255, 210, 140)),
    "OFFICE": (0.35, (170, 200, 230)),
    "WAREHOUSE": (0.08, (255, 200, 120)),
    "APTS": (0.5, (255, 215, 150)),
    "SHOP": (0.6, (170, 235, 240)),
}

NEON_HINT = {"BLUE": (30, 120, 255), "MAGENTA": (255, 40, 200), "PINK": (255, 80, 160), "CYAN": (40, 230, 230), "ORANGE": (255, 150, 40), "GREEN": (40, 230, 120)}

_CAR_COLORS = [
    (200, 200, 205), (30, 30, 34), (120, 20, 30), (20, 40, 90),
    (150, 150, 155), (210, 190, 60), (60, 90, 70), (240, 240, 240),
]


def _seeded(*keys) -> random.Random:
    # Deterministic per key so regeneration is stable.
    return random.Random(":".join(str(k) for k in keys))


def _front_z(plot: Plot, depth: float) -> float:
    """World z of the street-facing wall."""
    return plot.z - depth / 2 if plot.side == "INLAND" else plot.z + depth / 2


def _out(plot: Plot) -> float:
    """+1/-1 along z pointing from the building toward the street."""
    return -1.0 if plot.side == "INLAND" else 1.0


# ── Buildings ───────────────────────────────────────────────────────────────

def _windows(plot: Plot, height: float, depth: float, rng: random.Random, dim: bool) -> list[Part]:
    parts: list[Part] = []
    lit_frac, lit_color = _WINDOW_LIT.get(plot.type, (0.3, (255, 210, 150)))
    if dim:
        lit_frac *= 0.4
    fz = _front_z(plot, depth) + _out(plot) * 0.2
    usable = plot.width - 10
    per_floor = max(1, int(usable // 9))
    step = usable / per_floor
    for floor in range(plot.floors):
        y = floor * FLOOR_HEIGHT + FLOOR_HEIGHT * 0.55
        if floor == 0 and plot.type in ("CLUB", "BAR", "RESTAURANT", "SHOP"):
            y = FLOOR_HEIGHT * 0.62  # storefront glazing sits a little higher
        for i in range(per_floor):
            x = plot.x + 5 + step * (i + 0.5)
            lit = rng.random() < lit_frac
            parts.append(
                Part(
                    name=f"win_{plot.index}_{floor}_{i}",
                    position=(x, y, fz),
                    size=(4.2, 5.0, 0.3),
                    color=lit_color if lit else (18, 22, 30),
                    material="Neon" if lit else "Glass",
                )
            )
    return parts


def _door_and_awning(plot: Plot, depth: float, rng: random.Random, neon_rgb: list[int] | None) -> list[Part]:
    parts: list[Part] = []
    fz = _front_z(plot, depth)
    cx = plot.x + plot.width / 2
    o = _out(plot)
    # Door (a slab on solid buildings; explorable ones have a real opening).
    if not is_explorable(plot):
        parts.append(
            Part(
                name=f"door_{plot.index}",
                position=(cx, 4.5, fz + o * 0.25),
                size=(6, 9, 0.5),
                color=(24, 20, 28),
                material="Metal",
            )
        )
    if plot.type in ("CLUB", "BAR", "RESTAURANT"):
        # Awning over the door, in the venue's neon color when it has one.
        color = tuple(neon_rgb) if neon_rgb else (110, 30, 40)
        parts.append(
            Part(
                name=f"awning_{plot.index}",
                position=(cx, 10.2, fz + o * 2.2),
                size=(min(14, plot.width - 6), 0.6, 4.5),
                color=color,
                material="Fabric",
                lights=[PointLight(color=(255, 225, 190), brightness=1.4, range=22)],
            )
        )
        # Sign board above the awning.
        parts.append(
            Part(
                name=f"sign_{plot.index}",
                position=(cx, 12.6, fz + o * 0.6),
                size=(min(16, plot.width - 4), 3, 0.8),
                color=color if neon_rgb else (40, 36, 44),
                material="Neon" if neon_rgb else "Metal",
            )
        )
    elif plot.type == "APTS":
        # Porch light — the only warmth on a residential street.
        parts.append(
            Part(
                name=f"porch_{plot.index}",
                position=(cx + 4, 9.5, fz + o * 0.6),
                size=(0.8, 0.8, 0.6),
                color=(255, 210, 140),
                material="Neon",
                lights=[PointLight(color=(255, 200, 130), brightness=1.1, range=18)],
            )
        )
    elif plot.type == "WAREHOUSE":
        # Roll-up loading door.
        parts.append(
            Part(
                name=f"rollup_{plot.index}",
                position=(cx, 6, fz + o * 0.3),
                size=(16, 12, 0.6),
                color=(44, 46, 50),
                material="Metal",
            )
        )
    return parts


def build_plot(plot: Plot, neon_palette: dict[str, list[int]], dim: bool = False) -> list[Part]:
    """All parts for one plot. `dim` marks the Far Row: fewer lit windows,
    weaker neon — the strip going quiet."""
    rng = _seeded(plot.street, plot.side, plot.index)
    parts: list[Part] = []

    if plot.type in ("LOT", "VACANT"):
        parts.append(
            Part(
                name=f"{plot.type}_{plot.index}",
                position=(plot.x + plot.width / 2, 0.5, plot.z),
                size=(plot.width, 1, BUILDING_DEPTH),
                color=_TYPE_COLOR.get(plot.type, (50, 50, 50)),
                material="Asphalt" if plot.type == "LOT" else "Cobblestone",
            )
        )
        if plot.type == "LOT":
            # A couple of parked cars in the lot.
            for i in range(2):
                parts.extend(build_car(plot.x + 12 + i * 22, plot.z, rng, along_x=False))
        return parts

    if plot.type == "LANDMARK":
        h = plot.floors * FLOOR_HEIGHT
        parts.append(
            Part(
                name=f"LANDMARK::{plot.landmark or 'Unknown'}",
                position=(plot.x + plot.width / 2, h / 2, plot.z),
                size=(plot.width, h, 50),
                color=_TYPE_COLOR["LANDMARK"],
                material="Concrete",
                transparency=0.35,
            )
        )
        fz = _front_z(plot, 50)
        o = _out(plot)
        if plot.landmark == "HouseOfSol":
            # "Warm interior light spilling onto a dark street is the whole
            # exterior read, and it is the only warm light on Abbott Avenue."
            parts.append(
                Part(
                    name="HouseOfSol_DoorLight",
                    position=(plot.x + plot.width / 2, 9, fz + o * 1.0),
                    size=(3, 3, 1),
                    color=(255, 200, 120),
                    material="Neon",
                    lights=[PointLight(color=(255, 190, 110), brightness=4.0, range=70)],
                )
            )
        elif plot.landmark == "SteelZebra":
            # Boarded up since 2018: plywood over the doors, one dead sign.
            parts.append(
                Part(
                    name="SteelZebra_Boards",
                    position=(plot.x + plot.width / 2, 6, fz + o * 0.4),
                    size=(22, 12, 0.6),
                    color=(96, 78, 52),
                    material="Wood",
                )
            )
            parts.append(
                Part(
                    name="SteelZebra_DeadSign",
                    position=(plot.x + plot.width / 2, 20, fz + o * 0.8),
                    size=(26, 4, 0.8),
                    color=(40, 40, 42),
                    material="Metal",
                )
            )
        elif plot.landmark == "VampireBar":
            # The one nice door on the cheap end of the strip.
            parts.append(
                Part(
                    name="VampireBar_Awning",
                    position=(plot.x + plot.width / 2, 10.2, fz + o * 2.2),
                    size=(14, 0.6, 4.5),
                    color=(20, 24, 60),
                    material="Fabric",
                    lights=[PointLight(color=(120, 140, 255), brightness=2.0, range=26)],
                )
            )
        return parts

    # ── Procedural building ─────────────────────────────────────────────────
    height = plot.floors * FLOOR_HEIGHT
    depth = BUILDING_DEPTH + rng.uniform(-6, 6)
    color = _TYPE_COLOR.get(plot.type, (60, 60, 60))
    explorable = is_explorable(plot)
    if explorable:
        parts.extend(build_explorable(plot, height, depth, rng))
    else:
        parts.append(
            Part(
                name=f"{plot.type}_{plot.index}",
                position=(plot.x + plot.width / 2, height / 2, plot.z),
                size=(plot.width - 2, height, depth),
                color=color,
                material="Concrete" if plot.type != "WAREHOUSE" else "Metal",
            )
        )
    parts.extend(_windows(plot, height, depth, rng, dim))

    neon_rgb = neon_palette.get(plot.neon) if plot.neon else None
    parts.extend(_door_and_awning(plot, depth, rng, neon_rgb))

    # Roofline neon band on the trendy strip (Collins only; Abbott gets none).
    if neon_rgb and plot.street == "COLLINS":
        band_z = _front_z(plot, depth) + _out(plot) * 0.3
        bright = 1.0 if not dim else 0.45
        c = tuple(int(v * bright) for v in neon_rgb)
        parts.append(
            Part(
                name=f"neon_{plot.index}",
                position=(plot.x + plot.width / 2, height - 3, band_z),
                size=(plot.width - 4, 1.5, 0.5),
                color=c,
                material="Neon",
                lights=[PointLight(color=tuple(neon_rgb), brightness=2.6 * bright, range=60)],
            )
        )

    # Rear: decorative fire escape on the alley wall for solid buildings two
    # floors or taller (explorable ones get a real, climbable one).
    if plot.floors >= 2 and plot.street == "COLLINS" and not explorable:
        parts.extend(build_fire_escape(plot, height, depth))

    return parts


# ── Street furniture ────────────────────────────────────────────────────────

def build_sidewalk(name: str, z: float, length: float, width: float) -> list[Part]:
    return [
        Part(
            name=f"sidewalk_{name}",
            position=(length / 2, 0.55, z),
            size=(length, 0.6, width),
            color=(120, 118, 112),
            material="Concrete",
        )
    ]


def build_palm(x: float, z: float, rng: random.Random) -> list[Part]:
    h = 16 + rng.uniform(-3, 4)
    trunk = (74, 58, 40)
    frond = (26, 70, 38)
    return [
        Part(name=f"palm_{int(x)}_{int(z)}_trunk", position=(x, h / 2, z), size=(1.2, h, 1.2), color=trunk, material="Wood"),
        Part(name=f"palm_{int(x)}_{int(z)}_crown", position=(x, h + 0.5, z), size=(3, 3, 3), color=frond, material="Plastic"),
        Part(name=f"palm_{int(x)}_{int(z)}_f1", position=(x, h + 1.2, z), size=(11, 0.4, 2.2), color=frond, material="Plastic"),
        Part(name=f"palm_{int(x)}_{int(z)}_f2", position=(x, h + 1.2, z), size=(2.2, 0.4, 11), color=frond, material="Plastic"),
    ]


def build_car(x: float, z: float, rng: random.Random, along_x: bool = True) -> list[Part]:
    """A parked car: body + cabin. Cover for running fights down the strip."""
    color = rng.choice(_CAR_COLORS)
    body = (14, 3, 6) if along_x else (6, 3, 14)
    cabin = (7, 2.4, 5.4) if along_x else (5.4, 2.4, 7)
    return [
        Part(name=f"car_{int(x)}_{int(z)}_body", position=(x, 1.5 + 0.6, z), size=body, color=color, material="Metal"),
        Part(name=f"car_{int(x)}_{int(z)}_cabin", position=(x, 3.0 + 1.8, z), size=cabin, color=(20, 24, 30), material="Glass"),
    ]


def build_dumpster(x: float, z: float) -> list[Part]:
    return [
        Part(name=f"dumpster_{int(x)}_{int(z)}", position=(x, 2.5, z), size=(7, 5, 4.5), color=(30, 60, 40), material="Metal"),
        Part(name=f"dumpster_{int(x)}_{int(z)}_lid", position=(x, 5.2, z), size=(7.2, 0.4, 4.7), color=(24, 48, 32), material="Metal"),
    ]


def build_fire_escape(plot: Plot, height: float, depth: float) -> list[Part]:
    """Ladder + per-floor platforms on the alley-facing wall. Climb geometry
    for the Werewolf and the Vampire."""
    parts: list[Part] = []
    back_z = plot.z + depth / 2 if plot.side == "INLAND" else plot.z - depth / 2
    o = 1.0 if plot.side == "INLAND" else -1.0
    x = plot.x + plot.width * 0.65
    parts.append(
        Part(
            name=f"fe_{plot.index}_ladder",
            position=(x, height / 2, back_z + o * 0.9),
            size=(1.2, height - 2, 0.4),
            color=(40, 40, 44),
            material="Metal",
        )
    )
    for floor in range(1, plot.floors):
        parts.append(
            Part(
                name=f"fe_{plot.index}_p{floor}",
                position=(x, floor * FLOOR_HEIGHT + 0.5, back_z + o * 2.2),
                size=(9, 0.5, 4),
                color=(46, 46, 50),
                material="Metal",
            )
        )
    return parts


def build_alley_light(x: float, z: float, y: float = 11.0) -> list[Part]:
    """One working light every eighty studs — dim, warm, and lonely."""
    return [
        Part(
            name=f"alleylight_{int(x)}_{int(z)}",
            position=(x, y, z),
            size=(1.2, 0.6, 1.2),
            color=(255, 200, 130),
            material="Neon",
            lights=[PointLight(color=(255, 190, 120), brightness=1.3, range=34)],
        )
    ]


def build_streetlights(
    name: str,
    z: float,
    length: float,
    road_width: float,
    spacing: float,
    color: tuple[int, int, int],
    brightness: float,
) -> list[Part]:
    """Lamp posts down both sides of a road. Collins gets dense cool-white;
    Abbott gets sparse sodium orange (the tone break the spec calls for).
    Each post is a Frankenstein 'live source' candidate."""
    parts: list[Part] = []
    offset = road_width / 2 + 4
    x = spacing / 2
    i = 0
    while x < length:
        for side, sz in (("L", z - offset), ("R", z + offset)):
            parts.append(
                Part(
                    name=f"lamp_{name}_{i}{side}_post",
                    position=(x, 9, sz),
                    size=(1, 18, 1),
                    color=(60, 60, 64),
                    material="Metal",
                )
            )
            parts.append(
                Part(
                    name=f"lamp_{name}_{i}{side}_head",
                    position=(x, 18.5, sz),
                    size=(2.5, 1, 2.5),
                    color=color,
                    material="Neon",
                    lights=[PointLight(color=color, brightness=brightness, range=80)],
                )
            )
        x += spacing
        i += 1
    return parts


def build_road(name: str, z: float, length: float, width: float, material: str) -> list[Part]:
    return [
        Part(
            name=f"road_{name}",
            position=(length / 2, 0.25, z),
            size=(length, 0.5, width),
            color=(35, 35, 38),
            material=material,
        )
    ]


def build_cross_alley(x: float, z0: float, z1: float, width: float = 18.0) -> list[Part]:
    return [
        Part(
            name=f"crossalley_{int(x)}",
            position=(x, 0.3, (z0 + z1) / 2),
            size=(width, 0.6, abs(z1 - z0)),
            color=(30, 30, 33),
            material="Cobblestone",
        )
    ]


# ── Explorable interiors ────────────────────────────────────────────────────
# Some buildings are hollow: open floors joined by switchback stairs, a
# climbable fire escape on the alley wall with a doorway onto each upper floor,
# a ladder to the roof, and a loot crate on every level — bigger the higher up.

_EXPLORE_CHANCE = {
    "WAREHOUSE": 0.55,
    "OFFICE": 0.45,
    "CLUB": 0.35,
    "BAR": 0.4,
    "APTS": 0.3,
    "SHOP": 0.25,
    "RESTAURANT": 0.2,
}


def is_explorable(plot: Plot) -> bool:
    if plot.explore is not None:
        return plot.explore
    if plot.floors < 2 or plot.type not in _EXPLORE_CHANCE:
        return False
    return _seeded("explore", plot.street, plot.index).random() < _EXPLORE_CHANCE[plot.type]


def build_loot_crate(tag: str, tier: str, x: float, y: float, z: float) -> Part:
    """A crate with a Press-E prompt. Name encodes the tier for LootService."""
    color = {"S": (120, 92, 58), "M": (140, 104, 60), "L": (170, 130, 70)}[tier]
    return Part(
        name=f"LootCrate_{tier}_{tag}",
        position=(x, y + 1.5, z),
        size=(3, 3, 3),
        color=color,
        material="Wood",
        extras=[proximity_prompt("Open", {"S": "Crate", "M": "Stash", "L": "Cache"}[tier])],
    )


def build_explorable(plot: Plot, height: float, depth: float, rng: random.Random) -> list[Part]:
    parts: list[Part] = []
    x0, x1 = plot.x + 1, plot.x + plot.width - 1
    w = x1 - x0
    cx = (x0 + x1) / 2
    color = _TYPE_COLOR.get(plot.type, (60, 60, 60))
    mat = "Concrete" if plot.type != "WAREHOUSE" else "Metal"
    o = _out(plot)                       # toward the street
    fz = plot.z - o * (-depth / 2)       # street wall z  (= plot.z + o*depth/2... keep explicit below)
    fz = plot.z + o * (depth / 2)        # street wall
    bz = plot.z - o * (depth / 2)        # alley wall
    T = 1.0                              # wall thickness
    tag = f"{plot.street}{plot.index}"

    def wall(name, x, y, z, sx, sy, sz):
        parts.append(Part(name=f"{name}_{tag}", position=(x, y, z), size=(sx, sy, sz), color=color, material=mat))

    # Side walls.
    wall("wallL", x0 + T / 2, height / 2, plot.z, T, height, depth)
    wall("wallR", x1 - T / 2, height / 2, plot.z, T, height, depth)
    # Street wall with a doorway gap in the middle.
    gap = 8.0
    seg = (w - gap) / 2
    wall("wallF1", x0 + seg / 2, height / 2, fz, seg, height, T)
    wall("wallF2", x1 - seg / 2, height / 2, fz, seg, height, T)
    wall("wallFlintel", cx, height - (height - 10) / 2, fz, gap, height - 10, T)
    # Alley wall: solid except a doorway column at the fire-escape x on each upper floor.
    xfe = plot.x + plot.width * 0.65
    col_w = 6.0
    wall("wallB1", (x0 + (xfe - col_w / 2)) / 2, height / 2, bz, (xfe - col_w / 2) - x0, height, T)
    wall("wallB2", ((xfe + col_w / 2) + x1) / 2, height / 2, bz, x1 - (xfe + col_w / 2), height, T)
    wall("wallBg", xfe, FLOOR_HEIGHT / 2, bz, col_w, FLOOR_HEIGHT, T)  # ground floor solid
    for f in range(1, plot.floors):
        y_open_top = f * FLOOR_HEIGHT + 9.0
        lintel_h = (f + 1) * FLOOR_HEIGHT - y_open_top
        wall(f"wallBl{f}", xfe, y_open_top + lintel_h / 2, bz, col_w, lintel_h, T)

    # Stairs: switchback along x next to the left wall; alternate direction per floor.
    steps = 14
    run = 1.5
    stair_len = steps * run
    zs = plot.z - o * (depth / 2 - 5)   # a strip near the alley wall
    for f in range(0, plot.floors - 1):
        base_y = f * FLOOR_HEIGHT + 0.5
        forward = (f % 2 == 0)
        xs = x0 + 3 if forward else x1 - 3
        for i in range(1, steps + 1):
            rise = i * 1.0
            sx = xs + (i - 0.5) * run if forward else xs - (i - 0.5) * run
            parts.append(Part(name=f"stair_{tag}_{f}_{i}", position=(sx, base_y + rise / 2, zs),
                              size=(run, rise, 5), color=(70, 70, 76), material="Concrete"))
        # Next floor's slab needs a hole over the stair run: handled in slabs below.

    # Floor slabs (ground + uppers) with a stairwell hole, and the roof.
    def slab(f: int, with_hole: bool):
        y = f * FLOOR_HEIGHT
        name = f"slab_{tag}_{f}" if f < plot.floors else f"roof_{tag}"
        zc_lo, zc_hi = zs - 3.5, zs + 3.5   # stair strip
        if not with_hole:
            parts.append(Part(name=name, position=(cx, y, plot.z), size=(w, 1, depth), color=(52, 52, 56), material="Concrete"))
            return
        # Strip along z outside the stair band.
        z_lo_edge, z_hi_edge = plot.z - depth / 2, plot.z + depth / 2
        a0, a1 = z_lo_edge, min(zc_lo, z_hi_edge)
        b0, b1 = max(zc_hi, z_lo_edge), z_hi_edge
        if a1 > a0:
            parts.append(Part(name=name + "a", position=(cx, y, (a0 + a1) / 2), size=(w, 1, a1 - a0), color=(52, 52, 56), material="Concrete"))
        if b1 > b0:
            parts.append(Part(name=name + "b", position=(cx, y, (b0 + b1) / 2), size=(w, 1, b1 - b0), color=(52, 52, 56), material="Concrete"))
        # The stair band itself, minus the run the stairs arrive through.
        prev = f - 1
        forward = (prev % 2 == 0)
        hole_x0 = (x0 + 3) if forward else (x1 - 3 - stair_len)
        hole_x1 = hole_x0 + stair_len
        if hole_x0 > x0:
            parts.append(Part(name=name + "c", position=((x0 + hole_x0) / 2, y, zs), size=(hole_x0 - x0, 1, zc_hi - zc_lo), color=(52, 52, 56), material="Concrete"))
        if x1 > hole_x1:
            parts.append(Part(name=name + "d", position=((hole_x1 + x1) / 2, y, zs), size=(x1 - hole_x1, 1, zc_hi - zc_lo), color=(52, 52, 56), material="Concrete"))

    slab(0, False)
    for f in range(1, plot.floors):
        slab(f, True)
    slab(plot.floors, False)  # roof, no hole; reached by the exterior ladder

    # Exterior fire escape: climbable truss ladder + a platform at each upper floor
    # doorway. Then a truss from the top platform up past the roof edge.
    bz_out = bz - o * 2.0
    for f in range(1, plot.floors):
        parts.append(Part(name=f"fe_{tag}_p{f}", position=(xfe, f * FLOOR_HEIGHT + 0.5, bz - o * 2.5),
                          size=(9, 0.6, 5), color=(46, 46, 50), material="Metal"))
    ladder_h = int(plot.floors * FLOOR_HEIGHT + 4)
    ladder_h += ladder_h % 2
    parts.append(Part(name=f"fe_{tag}_ladder", position=(xfe + 5.5, ladder_h / 2, bz_out),
                      size=(2, ladder_h, 2), color=(40, 40, 44), material="Metal", cls="TrussPart"))

    # Interior lights: one dim warm bulb per floor.
    for f in range(plot.floors):
        parts.append(Part(name=f"bulb_{tag}_{f}", position=(cx, f * FLOOR_HEIGHT + FLOOR_HEIGHT - 2, plot.z),
                          size=(0.8, 0.5, 0.8), color=(255, 205, 140), material="Neon",
                          lights=[PointLight(color=(255, 195, 130), brightness=0.9, range=max(w, depth) * 0.9)]))

    # Furnish every floor: usable area = inside the walls, on the street side of
    # the stair band, with a clear lane from the door to the stairs.
    lo, hi = sorted((fz, bz))
    lo += 2.5
    hi -= 2.5
    cands = [(lo, min(hi, zs - 4.5)), (max(lo, zs + 4.5), hi)]
    zr = max(cands, key=lambda c: c[1] - c[0])
    neon_rgb = tuple(NEON_HINT.get(plot.neon, (255, 170, 90))) if plot.neon else None
    for f in range(plot.floors):
        room = furnish.Room(tag, f, x0 + 2.5, x1 - 2.5, zr[0], zr[1], f * FLOOR_HEIGHT + 0.5, cx, rng)
        furnish.furnish_room(plot.type, room, parts, neon=neon_rgb)

    # Loot: ground floor small, each upper floor medium, roof large.
    lx = cx + o * 0 + (w / 2 - 6)
    lz = plot.z + o * (depth / 2 - 6)
    parts.append(build_loot_crate(f"{tag}_g", "S", lx, 1.0, lz))
    for f in range(1, plot.floors):
        parts.append(build_loot_crate(f"{tag}_f{f}", "M", lx - rng.uniform(0, w * 0.4), f * FLOOR_HEIGHT + 0.5, lz))
    parts.append(build_loot_crate(f"{tag}_roof", "L", cx - rng.uniform(-w * 0.3, w * 0.3), plot.floors * FLOOR_HEIGHT + 0.5, plot.z))
    return parts
