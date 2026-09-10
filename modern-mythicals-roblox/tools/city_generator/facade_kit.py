"""Facade kit — turns a plot into a small set of Parts with seeded variation.

Ten authored buildings and a kit of ~30 facade pieces produce a strip where every
building feels placed. Here we generate a building shell (box) plus a few facade
accents (a sign strip, a neon band on the trendy row). Landmark plots are emitted
as a single tagged placeholder Part the Rojo/Studio side swaps for a hand-built
model by asset id.
"""

from __future__ import annotations

import random

from plots import Plot
from rbxlx import Part, PointLight

FLOOR_HEIGHT = 14.0  # studs per floor


_TYPE_COLOR = {
    "CLUB": (40, 30, 55),
    "BAR": (48, 38, 44),
    "RESTAURANT": (60, 52, 44),
    "OFFICE": (70, 72, 80),
    "WAREHOUSE": (58, 58, 60),
    "APTS": (78, 70, 62),
    "LOT": (52, 52, 50),
    "VACANT": (45, 45, 48),
    "LANDMARK": (90, 80, 70),
}


def _seeded(plot: Plot) -> random.Random:
    # Deterministic per plot so regeneration is stable.
    return random.Random(f"{plot.street}:{plot.side}:{plot.index}")


def build_plot(plot: Plot, neon_palette: dict[str, list[int]]) -> list[Part]:
    rng = _seeded(plot)
    parts: list[Part] = []

    if plot.type in ("LOT", "VACANT"):
        # Flat ground slab only.
        parts.append(
            Part(
                name=f"{plot.type}_{plot.index}",
                position=(plot.x + plot.width / 2, 0.5, plot.z),
                size=(plot.width, 1, 40),
                color=_TYPE_COLOR.get(plot.type, (50, 50, 50)),
                material="Asphalt",
            )
        )
        return parts

    if plot.type == "LANDMARK":
        # Tagged placeholder — Studio/Rojo swaps in the hand-built interior model.
        parts.append(
            Part(
                name=f"LANDMARK::{plot.landmark or 'Unknown'}",
                position=(plot.x + plot.width / 2, plot.floors * FLOOR_HEIGHT / 2, plot.z),
                size=(plot.width, plot.floors * FLOOR_HEIGHT, 50),
                color=_TYPE_COLOR["LANDMARK"],
                material="Concrete",
                transparency=0.35,
            )
        )
        if plot.landmark == "HouseOfSol":
            # "Warm interior light spilling onto a dark street is the whole
            # exterior read, and it is the only warm light on Abbott Avenue."
            door_z = plot.z - 26 if plot.side == "INLAND" else plot.z + 26
            parts.append(
                Part(
                    name="HouseOfSol_DoorLight",
                    position=(plot.x + plot.width / 2, 9, door_z),
                    size=(3, 3, 1),
                    color=(255, 200, 120),
                    material="Neon",
                    lights=[PointLight(color=(255, 190, 110), brightness=4.0, range=70)],
                )
            )
        return parts

    # Procedural building shell.
    height = plot.floors * FLOOR_HEIGHT
    depth = 40 + rng.uniform(-6, 6)
    color = _TYPE_COLOR.get(plot.type, (60, 60, 60))
    parts.append(
        Part(
            name=f"{plot.type}_{plot.index}",
            position=(plot.x + plot.width / 2, height / 2, plot.z),
            size=(plot.width - 2, height, depth),
            color=color,
            material="Concrete" if plot.type != "WAREHOUSE" else "Metal",
        )
    )

    # Neon band on the trendy row (Collins only; Abbott gets none).
    if plot.neon and plot.street == "COLLINS":
        rgb = neon_palette.get(plot.neon, [255, 40, 200])
        band_z = plot.z + (depth / 2 if plot.side == "INLAND" else -depth / 2)
        parts.append(
            Part(
                name=f"neon_{plot.index}",
                position=(plot.x + plot.width / 2, height - 3, band_z),
                size=(plot.width - 4, 1.5, 0.5),
                color=(rgb[0], rgb[1], rgb[2]),
                material="Neon",
                lights=[PointLight(color=(rgb[0], rgb[1], rgb[2]), brightness=2.6, range=60)],
            )
        )

    return parts


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
