"""Interior furnishing for explorable buildings, by type. Every piece is a
primitive Part (plus the occasional glow). Placement is seeded, keeps a walking
lane from the street door to the stairs, and stays off the stair band.
"""

from __future__ import annotations

import random

from rbxlx import Part, PointLight

FH = 14.0

WOOD = (110, 82, 52)
DARKWOOD = (70, 50, 34)
STEEL = (90, 92, 98)
BLACK = (22, 22, 26)
CLOTH = (70, 40, 60)
GRAY = (120, 120, 126)


def _box(name, x, y, z, sx, sy, sz, color, material="Wood", lights=None, transparency=0.0) -> Part:
    return Part(name=name, position=(x, y, z), size=(sx, sy, sz), color=color, material=material,
                lights=lights or [], transparency=transparency)


class Room:
    """Usable floor area: x-range, z-range, floor top y, a lane to keep clear."""

    def __init__(self, tag: str, floor: int, x0: float, x1: float, z0: float, z1: float, y: float,
                 lane_x: float, rng: random.Random):
        self.tag, self.floor = tag, floor
        self.x0, self.x1, self.z0, self.z1, self.y = x0, x1, z0, z1, y
        self.lane_x = lane_x
        self.rng = rng
        self.taken: list[tuple[float, float, float]] = []  # (x, z, radius)
        self.n = 0

    def name(self, kind: str) -> str:
        self.n += 1
        return f"{kind}_{self.tag}_{self.floor}_{self.n}"

    def spot(self, radius: float, tries: int = 24) -> tuple[float, float] | None:
        for _ in range(tries):
            x = self.rng.uniform(self.x0 + radius, self.x1 - radius)
            z = self.rng.uniform(self.z0 + radius, self.z1 - radius)
            if abs(x - self.lane_x) < 4.5 + radius * 0.5:
                continue
            if all((x - tx) ** 2 + (z - tz) ** 2 >= (radius + tr) ** 2 for tx, tz, tr in self.taken):
                self.taken.append((x, z, radius))
                return x, z
        return None

    @property
    def width(self):
        return self.x1 - self.x0

    @property
    def depth(self):
        return self.z1 - self.z0


# ── Pieces ──────────────────────────────────────────────────────────────────

def table_and_chairs(r: Room, parts: list[Part], chairs: int = 2):
    s = r.spot(3.5)
    if not s:
        return
    x, z = s
    parts.append(_box(r.name("tablepost"), x, r.y + 1.3, z, 0.6, 2.6, 0.6, DARKWOOD))
    parts.append(_box(r.name("tabletop"), x, r.y + 2.75, z, 3.6, 0.3, 3.6, WOOD))
    offs = [(2.6, 0), (-2.6, 0), (0, 2.6), (0, -2.6)]
    for dx, dz in offs[:chairs]:
        parts.append(_box(r.name("chair"), x + dx, r.y + 0.9, z + dz, 1.4, 1.8, 1.4, BLACK, "Fabric"))


def couch(r: Room, parts: list[Part]):
    s = r.spot(3.5)
    if s:
        x, z = s
        parts.append(_box(r.name("couch"), x, r.y + 1.2, z, 6, 2.4, 2.6, CLOTH, "Fabric"))
        parts.append(_box(r.name("couchback"), x, r.y + 2.4, z + 1.0, 6, 1.2, 0.6, CLOTH, "Fabric"))


def bed(r: Room, parts: list[Part]):
    s = r.spot(3.8)
    if s:
        x, z = s
        parts.append(_box(r.name("bed"), x, r.y + 1.0, z, 6, 2.0, 4.2, (150, 140, 160), "Fabric"))
        parts.append(_box(r.name("headboard"), x + 3.1, r.y + 2.2, z, 0.4, 3.6, 4.2, DARKWOOD))


def tv(r: Room, parts: list[Part], color=(120, 150, 210)):
    s = r.spot(2.5)
    if s:
        x, z = s
        parts.append(_box(r.name("tvstand"), x, r.y + 1.0, z, 4, 2.0, 1.4, BLACK, "Metal"))
        parts.append(_box(r.name("tv"), x, r.y + 3.2, z, 4, 2.4, 0.3, color, "Neon",
                          lights=[PointLight(color=color, brightness=0.7, range=12)]))


def kitchen(r: Room, parts: list[Part]):
    # Counter along the far x wall + fridge.
    x = r.x1 - 1.6
    length = min(10, r.depth - 4)
    z = r.z0 + 2 + length / 2
    parts.append(_box(r.name("counter"), x, r.y + 1.6, z, 2.4, 3.2, length, GRAY, "Concrete"))
    parts.append(_box(r.name("fridge"), x, r.y + 2.9, z + length / 2 + 1.8, 2.6, 5.8, 2.6, (200, 200, 205), "Metal"))
    r.taken.append((x, z, 2.5))


def desk(r: Room, parts: list[Part]):
    s = r.spot(3.0)
    if s:
        x, z = s
        parts.append(_box(r.name("desk"), x, r.y + 1.5, z, 5, 0.4, 2.6, WOOD))
        parts.append(_box(r.name("deskpanel"), x, r.y + 0.75, z + 1.0, 5, 1.5, 0.3, DARKWOOD))
        parts.append(_box(r.name("chair"), x, r.y + 0.9, z - 2.2, 1.5, 1.8, 1.5, BLACK, "Fabric"))
        parts.append(_box(r.name("monitor"), x + 1.2, r.y + 2.7, z + 0.6, 1.6, 1.0, 0.2, (160, 190, 235), "Neon"))


def cabinet(r: Room, parts: list[Part]):
    s = r.spot(1.6)
    if s:
        x, z = s
        parts.append(_box(r.name("cabinet"), x, r.y + 2.0, z, 2.0, 4.0, 2.0, STEEL, "Metal"))


def partition(r: Room, parts: list[Part]):
    s = r.spot(4.5)
    if s:
        x, z = s
        parts.append(_box(r.name("partition"), x, r.y + 2.5, z, 8, 5, 0.3, (140, 150, 170), "Fabric"))


def plant(r: Room, parts: list[Part]):
    s = r.spot(1.2)
    if s:
        x, z = s
        parts.append(_box(r.name("pot"), x, r.y + 0.7, z, 1.4, 1.4, 1.4, (100, 60, 40)))
        parts.append(_box(r.name("plant"), x, r.y + 2.6, z, 2.2, 2.4, 2.2, (30, 90, 45), "Plastic"))


def rack(r: Room, parts: list[Part]):
    s = r.spot(6.5)
    if not s:
        return
    x, z = s
    length = 12
    for dx in (-length / 2 + 0.3, length / 2 - 0.3):
        parts.append(_box(r.name("rackpost"), x + dx, r.y + 5, z, 0.5, 10, 3, STEEL, "Metal"))
    for h in (3, 6, 9):
        parts.append(_box(r.name("shelf"), x, r.y + h, z, length, 0.3, 3, STEEL, "Metal"))
        # a few boxes on the shelf
        for i in range(r.rng.randint(1, 3)):
            bx = x + r.rng.uniform(-length / 2 + 1.5, length / 2 - 1.5)
            parts.append(_box(r.name("shelfbox"), bx, r.y + h + 1.2, z, 2.2, 2.2, 2.2, (130, 105, 70)))


def crate_stack(r: Room, parts: list[Part]):
    s = r.spot(2.6)
    if s:
        x, z = s
        for i in range(r.rng.randint(1, 3)):
            parts.append(_box(r.name("crate"), x + r.rng.uniform(-0.4, 0.4), r.y + 2 + i * 4, z, 4, 4, 4, (125, 98, 62)))


def drum(r: Room, parts: list[Part]):
    s = r.spot(1.6)
    if s:
        x, z = s
        parts.append(_box(r.name("drum"), x, r.y + 1.8, z, 2.5, 3.6, 2.5, r.rng.choice([(40, 60, 110), (120, 60, 30), (60, 60, 64)]), "Metal"))


def bar_counter(r: Room, parts: list[Part], neon=(255, 170, 90)):
    # Counter along the low-x wall, back-bar glow behind it, stools in front.
    length = min(r.depth - 4, 28)
    zc = r.z0 + 2 + length / 2
    x = r.x0 + 4.5
    parts.append(_box(r.name("bar"), x, r.y + 1.8, zc, 2.6, 3.6, length, DARKWOOD))
    parts.append(_box(r.name("barglow"), r.x0 + 1.2, r.y + 7.5, zc, 0.3, 0.5, length, neon, "Neon",
                      lights=[PointLight(color=neon, brightness=0.8, range=16)]))
    for i in range(int(length // 4)):
        parts.append(_box(r.name("stool"), x + 2.6, r.y + 1.2, r.z0 + 4 + i * 4, 1.2, 2.4, 1.2, BLACK, "Metal"))
    r.taken.append((x + 1, zc, length / 2))


def booth(r: Room, parts: list[Part]):
    # Bench against the high-x wall.
    x = r.x1 - 1.8
    z = r.rng.uniform(r.z0 + 4, r.z1 - 4)
    if all(abs(z - tz) > 4 for tx, tz, tr in r.taken if tx > r.x1 - 5):
        parts.append(_box(r.name("booth"), x, r.y + 1.2, z, 2.4, 2.4, 6, CLOTH, "Fabric"))
        parts.append(_box(r.name("boothtable"), x - 2.6, r.y + 1.4, z, 2.4, 2.8, 4, WOOD))
        r.taken.append((x, z, 3.5))


def dance_floor(r: Room, parts: list[Part], neon):
    x = (r.x0 + r.x1) / 2 + r.width * 0.15
    z = (r.z0 + r.z1) / 2
    size = min(14, r.width * 0.4, r.depth * 0.6)
    parts.append(_box(r.name("dancefloor"), x, r.y + 0.15, z, size, 0.3, size, neon, "Neon", transparency=0.45,
                      lights=[PointLight(color=neon, brightness=1.0, range=size * 1.3)]))
    r.taken.append((x, z, size / 2))
    # DJ booth + speakers at the far z edge
    parts.append(_box(r.name("djbooth"), x, r.y + 1.8, r.z1 - 2.5, 8, 3.6, 3, BLACK, "Metal"))
    for dx in (-6, 6):
        parts.append(_box(r.name("speaker"), x + dx, r.y + 3, r.z1 - 2.5, 3, 6, 3, BLACK, "Fabric"))


def shelving_aisle(r: Room, parts: list[Part]):
    s = r.spot(5.5)
    if not s:
        return
    x, z = s
    length = 10
    parts.append(_box(r.name("aisle"), x, r.y + 2.5, z, 1.4, 5, length, STEEL, "Metal"))
    for h in (1.6, 3.4):
        parts.append(_box(r.name("aisleshelf"), x, r.y + h, z, 2.6, 0.2, length, STEEL, "Metal"))
        for i in range(3):
            parts.append(_box(r.name("goods"), x + r.rng.choice([-0.8, 0.8]), r.y + h + 0.8, z - length / 2 + 1.5 + i * 3.5, 0.9, 1.4, 2.4,
                              r.rng.choice([(200, 60, 60), (60, 120, 200), (230, 200, 80), (80, 180, 90)]), "Plastic"))


def drink_fridge(r: Room, parts: list[Part]):
    x = r.x1 - 1.8
    z = r.z1 - 4
    parts.append(_box(r.name("drinkfridge"), x, r.y + 3, z, 2.6, 6, 3.2, (210, 215, 220), "Metal"))
    parts.append(_box(r.name("fridgeglass"), x - 1.35, r.y + 3, z, 0.2, 5.2, 2.8, (120, 230, 240), "Neon",
                      lights=[PointLight(color=(120, 230, 240), brightness=0.8, range=12)]))
    r.taken.append((x, z, 2.5))


def shop_counter(r: Room, parts: list[Part]):
    x = r.lane_x + 6.5
    z = r.z0 + 3.5
    parts.append(_box(r.name("shopcounter"), x, r.y + 1.6, z, 6, 3.2, 2.2, DARKWOOD))
    r.taken.append((x, z, 3.5))


def floor_lamp(r: Room, parts: list[Part]):
    s = r.spot(1.0)
    if s:
        x, z = s
        parts.append(_box(r.name("lamppost"), x, r.y + 2.5, z, 0.3, 5, 0.3, STEEL, "Metal"))
        parts.append(_box(r.name("lampshade"), x, r.y + 5.4, z, 1.6, 1.2, 1.6, (255, 220, 170), "Neon",
                          lights=[PointLight(color=(255, 205, 150), brightness=0.9, range=14)]))


# ── Per-type layouts ────────────────────────────────────────────────────────

def furnish_room(kind: str, r: Room, parts: list[Part], neon=None):
    g = r.rng
    if kind == "WAREHOUSE":
        for _ in range(2 if r.width > 90 else 1):
            rack(r, parts)
        for _ in range(g.randint(3, 6)):
            crate_stack(r, parts)
        for _ in range(g.randint(1, 3)):
            drum(r, parts)
    elif kind == "OFFICE":
        for _ in range(g.randint(3, 6)):
            desk(r, parts)
        for _ in range(2):
            cabinet(r, parts)
        for _ in range(g.randint(1, 2)):
            partition(r, parts)
        plant(r, parts)
    elif kind in ("BAR", "CLUB"):
        n = neon or (255, 170, 90)
        if r.floor == 0:
            bar_counter(r, parts, neon=n)
            if kind == "CLUB":
                dance_floor(r, parts, n)
            for _ in range(2):
                booth(r, parts)
            for _ in range(g.randint(2, 4)):
                table_and_chairs(r, parts)
        else:
            # Upstairs lounge / storage.
            for _ in range(2):
                couch(r, parts)
            table_and_chairs(r, parts)
            for _ in range(g.randint(1, 3)):
                crate_stack(r, parts)
    elif kind == "RESTAURANT":
        for _ in range(g.randint(4, 7)):
            table_and_chairs(r, parts, chairs=2)
        kitchen(r, parts)
    elif kind == "APTS":
        bed(r, parts)
        couch(r, parts)
        tv(r, parts)
        kitchen(r, parts)
        floor_lamp(r, parts)
        table_and_chairs(r, parts, chairs=2)
    elif kind == "SHOP":
        shop_counter(r, parts)
        for _ in range(3 if r.width > 50 else 2):
            shelving_aisle(r, parts)
        drink_fridge(r, parts)
    else:
        for _ in range(2):
            crate_stack(r, parts)
