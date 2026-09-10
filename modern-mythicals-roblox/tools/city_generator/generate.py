#!/usr/bin/env python3
"""Modern Mythicals city generator.

Reads a district config (authored plot list + road splines) and emits a .rbxlx
place fragment of anchored Parts — buildings, roads, neon, landmark placeholders.
No Studio, no CSG, no SurfaceAppearance, no baked terrain.

Usage:
    python generate.py --config config/miami_club_district.json --out ../../build/miami.rbxlx

Optional real-map pass (needs network; ODbL attribution required in-game):
    python generate.py --config config/miami_club_district.json --osm --out build/miami.rbxlx
"""

from __future__ import annotations

import argparse
import os
import sys

import facade_kit
from plots import DistrictConfig, layout
from rbxlx import Part, Place


def generate(config_path: str, out_path: str, use_osm: bool = False) -> int:
    config = DistrictConfig.load(config_path)
    place = Place()

    # Roads first (flat slabs).
    for name, road in config.roads.items():
        material = "Asphalt" if name != "SERVICE" else "Cobblestone"
        for part in facade_kit.build_road(name, road.z, config.strip_length, 50, material):
            place.add(part)

    # Streetlights — the city lights itself. Collins: dense, cool white.
    # Abbott: sparse sodium orange, no neon (the tone break). Service road: none.
    for part in facade_kit.build_streetlights(
        "COLLINS", config.roads["COLLINS"].z, config.strip_length, 50, 110, (235, 240, 255), 2.2
    ):
        place.add(part)
    if "ABBOTT" in config.roads:
        for part in facade_kit.build_streetlights(
            "ABBOTT", config.roads["ABBOTT"].z, config.strip_length, 50, 260, (255, 170, 80), 1.4
        ):
            place.add(part)

    # Beach ground slab (east of Collins).
    place.add(
        Part(
            name="Beach",
            position=(config.strip_length / 2, 0.25, config.roads["COLLINS"].z - 350),
            size=(config.strip_length, 0.5, 300),
            color=(210, 200, 170),
            material="Sand",
        )
    )

    # Plots.
    laid = layout(config)
    for plot in laid:
        for part in facade_kit.build_plot(plot, config.neon_palette):
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
    print(
        f"District: {config.name}  ({config.strip_length}×{config.depth} studs, "
        f"budget {config.part_budget})"
    )
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
        h = fp["floors"] * facade_kit.FLOOR_HEIGHT
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
    parser.add_argument("--out", required=True, help="output .rbxlx path")
    parser.add_argument("--osm", action="store_true", help="overlay real OSM footprints")
    args = parser.parse_args()
    return generate(args.config, args.out, use_osm=args.osm)


if __name__ == "__main__":
    raise SystemExit(main())
