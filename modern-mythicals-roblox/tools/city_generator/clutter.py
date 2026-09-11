"""Alley and street clutter — the texture that makes a strip read as lived-in.
Trash, cardboard, pallets, puddles (reflective at night), AC units, wires,
fences, hydrants, benches, trash cans, velvet ropes at club doors."""

from __future__ import annotations

import random

from rbxlx import Part, PointLight


def _b(name, x, y, z, sx, sy, sz, color, material="Plastic", transparency=0.0, lights=None) -> Part:
    return Part(name=name, position=(x, y, z), size=(sx, sy, sz), color=color, material=material,
                transparency=transparency, lights=lights or [])


def alley(length: float, z0: float, z1: float, rear_wall_z: float, rng: random.Random) -> list[Part]:
    parts: list[Part] = []
    x = 12.0
    i = 0
    while x < length - 10:
        i += 1
        zc = rng.uniform(z0 + 2, z1 - 2)
        roll = rng.random()
        if roll < 0.35:  # trash bags cluster
            for j in range(rng.randint(2, 4)):
                parts.append(_b(f"trash_{i}_{j}", x + rng.uniform(-2, 2), 0.9, zc + rng.uniform(-1.5, 1.5),
                                1.6, 1.4, 1.6, (28, 30, 34)))
        elif roll < 0.55:  # cardboard
            for j in range(rng.randint(1, 3)):
                parts.append(_b(f"cardboard_{i}_{j}", x + j * 2.6, 1.0 + (0 if j < 2 else 2), zc,
                                2.5, 2.0, 2.5, (140, 112, 76), "Wood"))
        elif roll < 0.7:  # pallets
            for j in range(rng.randint(1, 3)):
                parts.append(_b(f"pallet_{i}_{j}", x, 0.75 + j * 0.5, zc, 4, 0.5, 4, (110, 84, 52), "Wood"))
        elif roll < 0.9:  # puddle — reflective under the lamps
            parts.append(_b(f"puddle_{i}", x, 0.62, zc, rng.uniform(4, 8), 0.1, rng.uniform(3, 5),
                            (20, 22, 30), "Glass", transparency=0.35))
        else:  # shopping cart-ish
            parts.append(_b(f"cart_{i}", x, 1.8, zc, 3, 2.6, 1.8, (140, 140, 146), "Metal"))
        x += rng.uniform(16, 30)

    # AC units on the rear walls, a wire across the alley now and then.
    x = 20.0
    j = 0
    while x < length:
        j += 1
        parts.append(_b(f"ac_{j}", x + rng.uniform(-6, 6), rng.uniform(8, 12), rear_wall_z - 1.4,
                        3, 2.5, 2.6, (150, 150, 155), "Metal"))
        if j % 2 == 0:
            parts.append(_b(f"wire_{j}", x, 12.5, (z0 + z1) / 2, 0.2, 0.2, z1 - z0 + 2, (20, 20, 22), "Plastic"))
        x += 55
    # Fence along the far edge of the alley, with gaps.
    x = 0.0
    k = 0
    while x < length:
        k += 1
        seg = rng.uniform(24, 40)
        if rng.random() < 0.7:
            parts.append(_b(f"fence_{k}", x + seg / 2, 4, z1 + 0.6, seg, 8, 0.3, (110, 110, 116), "Metal", transparency=0.55))
        x += seg + rng.uniform(6, 14)
    return parts


def street(length: float, collins_z: float, club_door_xs: list[float], rng: random.Random) -> list[Part]:
    parts: list[Part] = []
    inland_walk = collins_z + 32.5
    ocean_walk = collins_z - 45
    # Hydrants + trash cans on the inland sidewalk, benches + cans on the ocean walk.
    x = 70.0
    n = 0
    while x < length:
        n += 1
        parts.append(_b(f"hydrant_{n}", x, 1.5, inland_walk - 5, 1.0, 2.6, 1.0, (200, 40, 40)))
        parts.append(_b(f"can_{n}", x + 30, 1.6, inland_walk - 5.5, 1.6, 3.0, 1.6, (30, 70, 45), "Metal"))
        x += 150
    x = 45.0
    n = 0
    while x < length:
        n += 1
        parts.append(_b(f"bench_{n}", x, 1.4, ocean_walk + 12, 5.5, 0.6, 1.8, (110, 84, 52), "Wood"))
        parts.append(_b(f"benchback_{n}", x, 2.4, ocean_walk + 12.8, 5.5, 1.4, 0.4, (110, 84, 52), "Wood"))
        if n % 2 == 0:
            parts.append(_b(f"ocan_{n}", x + 12, 1.6, ocean_walk + 12, 1.6, 3.0, 1.6, (30, 70, 45), "Metal"))
        x += 90
    # Velvet ropes at club doors: two gold posts and a red rope.
    for i, dx in enumerate(club_door_xs):
        z = collins_z + 27
        parts.append(_b(f"rope_{i}_p1", dx - 4, 1.8, z, 0.5, 3.6, 0.5, (200, 170, 70), "Metal"))
        parts.append(_b(f"rope_{i}_p2", dx + 4, 1.8, z, 0.5, 3.6, 0.5, (200, 170, 70), "Metal"))
        parts.append(_b(f"rope_{i}_r", dx, 2.8, z, 8, 0.3, 0.3, (150, 20, 40), "Fabric"))
    return parts
