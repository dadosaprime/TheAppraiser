#!/usr/bin/env python3
"""Modern Mythicals city generator.

Reads a district config (authored plot list + road splines) and emits a .rbxlx
/ .rbxmx of anchored Parts — buildings with facades, roads, sidewalks, the back
alley, palms, parked cars, lamps, neon, landmark placeholders. No Studio, no
CSG, no SurfaceAppearance, no baked terrain.

Usage:
    python generate.py --config config/miami_club_district.json --out ../../map/GeneratedCity.rbxmx
"""

from __future__ import annotations

import argparse
import os
import random
import sys

import facade_kit as fk
from plots import DistrictConfig, layout
from rbxlx import Part, Place


def generate(config_path: str, out_path: str, use_osm: bool = False) -> int:
    config = DistrictConfig.load(config_path)
    place = Place()
    L = config.strip_length
    collins = config.roads["COLLINS"].z
    rng = random.Random("miami-street-furniture")

    # ── Ground: roads, sidewalks, beach ────────────────────────────────────
    for name, road in config.roads.items():
        material = "Asphalt" if name != "SERVICE" else "Cobblestone"
        for part in fk.build_road(name, road.z, L, 50, material):
            place.add(part)
    # Collins: wide sidewalk on the building side, palm-lined walk on the ocean side.
    for part in fk.build_sidewalk("COLLINS_inland", collins + 32.5, L, 15):
        place.add(part)
    for part in fk.build_sidewalk("COLLINS_ocean", collins - 45, L, 40):
        place.add(part)
    for part in fk.build_sidewalk("ABBOTT_inland", config.roads["ABBOTT"].z + 32.5, L, 15):
        place.add(part)
    place.add(
        Part(
            name="Beach",
            position=(L / 2, 0.25, collins - 215),
            size=(L, 0.5, 300),
            color=(210, 200, 170),
            material="Sand",
        )
    )

    # ── Lamps: the city lights itself ──────────────────────────────────────
    for part in fk.build_streetlights("COLLINS", collins, L, 50, 110, (235, 240, 255), 3.5):
        place.add(part)
    for part in fk.build_streetlights("ABBOTT", config.roads["ABBOTT"].z, L, 50, 260, (255, 170, 80), 2.2):
        place.add(part)
    for part in fk.build_streetlights("BEACHWALK", collins - 190, L, 0, 150, (255, 235, 200), 2.6):
        place.add(part)

    # ── Palms along the ocean-side walk ────────────────────────────────────
    x = 30.0
    while x < L:
        for part in fk.build_palm(x + rng.uniform(-4, 4), collins - 48 + rng.uniform(-6, 6), rng):
            place.add(part)
        x += 60

    # ── Parked cars: both curbs of Collins, thinner on Abbott ──────────────
    for z_curb, occupancy in ((collins + 21, 0.7), (collins - 21, 0.55)):
        x = 20.0
        while x < L - 10:
            if rng.random() < occupancy:
                for part in fk.build_car(x, z_curb, rng):
                    place.add(part)
            x += 42
    x = 40.0
    while x < L - 10:
        if rng.random() < 0.35:
            for part in fk.build_car(x, config.roads["ABBOTT"].z + 21, rng):
                place.add(part)
        x += 60

    # ── Plots (buildings, lots, landmarks) ─────────────────────────────────
    laid = layout(config)
    far_row_from = getattr(config, "far_row_from", None)
    for plot in laid:
        dim = far_row_from is not None and plot.street == "COLLINS" and plot.x >= far_row_from
        for part in fk.build_plot(plot, config.neon_palette, dim=dim):
            place.add(part)

    # ── The back alley behind the trendy row ───────────────────────────────
    # "The single most important piece of geometry in the district."
    alley_z0 = collins + 60 + fk.BUILDING_DEPTH / 2 + 2   # rear wall of Collins buildings
    alley_z1 = alley_z0 + 35
    place.add(
        Part(
            name="BackAlley",
            position=(L / 2, 0.3, (alley_z0 + alley_z1) / 2),
            size=(L, 0.6, alley_z1 - alley_z0),
            color=(28, 28, 31),
            material="Cobblestone",
        )
    )
    x = 35.0
    while x < L:
        if rng.random() < 0.8:
            for part in fk.build_dumpster(x + rng.uniform(-6, 6), alley_z0 + 5 + rng.uniform(0, 6)):
                place.add(part)
        x += 90
    x = 40.0
    while x < L:
        for part in fk.build_alley_light(x, alley_z0 + 1.2):
            place.add(part)
        x += 80

    # ── Cross-alleys through the back blocks (farm zone) ───────────────────
    service_back = config.roads["SERVICE"].z + 45 + fk.BUILDING_DEPTH / 2 + 2
    abbott_front = config.roads["ABBOTT"].z + 60 - fk.BUILDING_DEPTH / 2 - 2
    for cx in (L * 0.25, L * 0.5, L * 0.75):
        for part in fk.build_cross_alley(cx, service_back, abbott_front):
            place.add(part)
        for part in fk.build_alley_light(cx + 8, (service_back + abbott_front) / 2, y=10):
            place.add(part)

    if use_osm:
        _osm_pass(config, place)

    # Budget check — the real ceiling is instance count, and it's a phone budget.
    if place.count() > config.part_budget:
        print(
            f"WARNING: {place.count()} parts exceeds budget {config.part_budget}. "
            "Compress geography (delete boring blocks, shrink block lengths).",
            file=sys.stderr,
        )

    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    place.write(out_path)
    print(f"Wrote {place.count()} parts → {out_path}")
    print(f"District: {config.name}  ({config.strip_length}×{config.depth} studs, budget {config.part_budget})")
    return 0


def _osm_pass(config: DistrictConfig, place: Place) -> None:
    """Optional: overlay real building footprints from OpenStreetMap."""
    import osm

    origin = config.osm_origin
    bbox = config.osm_bbox
    if not origin or not bbox:
        print("No osm_origin/osm_bbox in config; skipping OSM pass.", file=sys.stderr)
        return
    result = osm.query(tuple(bbox))
    for i, fp in enumerate(osm.footprints(result, origin[0], origin[1])):
        pts = fp["points"]
        if len(pts) < 3:
            continue
        xs = [p[0] for p in pts]
        zs = [p[1] for p in pts]
        cx, cz = sum(xs) / len(xs), sum(zs) / len(zs)
        w = max(xs) - min(xs)
        d = max(zs) - min(zs)
        h = fp["floors"] * fk.FLOOR_HEIGHT
        place.add(
            Part(
                name=f"osm_building_{i}",
                position=(cx, h / 2, cz),
                size=(max(w, 4), h, max(d, 4)),
                color=(64, 64, 68),
                material="Concrete",
            )
        )


def main() -> int:
    parser = argparse.ArgumentParser(description="Modern Mythicals city generator")
    parser.add_argument("--config", required=True, help="district config JSON")
    parser.add_argument("--out", required=True, help="output .rbxlx/.rbxmx path")
    parser.add_argument("--osm", action="store_true", help="overlay real OSM footprints")
    args = parser.parse_args()
    return generate(args.config, args.out, use_osm=args.osm)


if __name__ == "__main__":
    raise SystemExit(main())
