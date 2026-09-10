"""The plot system — authored spine + procedural fill. (Miami spec § II.)

The strip is a list of plots along a road spline. Each plot is a slot with a
type, a width, and optionally a named landmark. Landmark plots load a hand-built
model (referenced by name → asset id); procedural plots are generated from a
facade kit with seeded variation.

'Move the House of Sol three plots north' is a one-line change to a config file.
This module reads that config and lays plots out along their road splines.
"""

from __future__ import annotations

import json
from dataclasses import dataclass


@dataclass
class Plot:
    index: int
    street: str            # "COLLINS" | "ABBOTT" | "SERVICE"
    side: str              # "OCEAN" | "INLAND"
    width: float           # studs of street frontage
    type: str              # CLUB|BAR|RESTAURANT|OFFICE|WAREHOUSE|LOT|VACANT|LANDMARK|APTS
    floors: int = 2
    neon: str | None = None
    crowd: float = 0.0     # 0-1, drives NPC density and audio
    landmark: str | None = None  # None for procedural plots

    # Filled in during layout.
    x: float = 0.0         # start position along the spline
    z: float = 0.0         # cross-street offset (set from street + side)


@dataclass
class Road:
    name: str
    z: float               # cross-street position of the road centerline
    plot_depth: float      # how deep buildings sit off the road


@dataclass
class DistrictConfig:
    name: str
    strip_length: float
    depth: float
    part_budget: int
    roads: dict[str, Road]
    plots: list[Plot]
    neon_palette: dict[str, list[int]]
    # Optional real-map pass (see osm.py): [lat, lon] origin and [s, w, n, e] bbox.
    osm_origin: list[float] | None = None
    osm_bbox: list[float] | None = None

    @staticmethod
    def load(path: str) -> "DistrictConfig":
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        roads = {
            name: Road(name=name, z=r["z"], plot_depth=r["plot_depth"])
            for name, r in data["roads"].items()
        }
        # Strip underscore-prefixed keys (inline notes/comments) before construction.
        plots = [
            Plot(**{k: v for k, v in p.items() if not k.startswith("_")})
            for p in data["plots"]
        ]
        return DistrictConfig(
            name=data["name"],
            strip_length=data["strip_length"],
            depth=data["depth"],
            part_budget=data.get("part_budget", 30000),
            roads=roads,
            plots=plots,
            neon_palette=data.get("neon_palette", {}),
            osm_origin=data.get("osm_origin"),
            osm_bbox=data.get("osm_bbox"),
        )


def layout(config: DistrictConfig) -> list[Plot]:
    """Assign world x/z to each plot, packing them along their road spline.

    Plots pack sequentially per (street, side); the cursor advances by each
    plot's width so blocks read as continuous frontage. Cross-street position
    comes from the road centerline plus its plot depth, flipped by side.
    """
    cursors: dict[tuple[str, str], float] = {}
    for plot in config.plots:
        road = config.roads.get(plot.street)
        if road is None:
            raise ValueError(f"plot {plot.index}: unknown street {plot.street!r}")
        key = (plot.street, plot.side)
        x = cursors.get(key, 0.0)
        plot.x = x
        offset = road.plot_depth if plot.side == "INLAND" else -road.plot_depth
        plot.z = road.z + offset
        cursors[key] = x + plot.width
    return config.plots
