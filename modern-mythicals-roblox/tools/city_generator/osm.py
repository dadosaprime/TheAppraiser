"""OpenStreetMap import via the Overpass API. (Automation doc § Part Seven.)

Queries building footprints and streets for a bounding box and projects lat/lon
to studs (~1 stud ≈ 1 foot). This is the 'real geometry, fictional tenants'
principle: OSM gives genuine parcel widths, setbacks, and block rhythm; the
businesses standing on those plots are invented in the plot list.

Network access is optional — the generator can run entirely from the authored
plot list (see generate.py). This module is here so a real-map pass is a config
change, not a rewrite. OSM data is ODbL: a credits line in the game covers it.
"""

from __future__ import annotations

import json
import math
import os
import urllib.parse
import urllib.request

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
FEET_PER_DEGREE_LAT = 364000.0  # ~ constant


def _feet_per_degree_lon(lat_deg: float) -> float:
    return 365000.0 * math.cos(math.radians(lat_deg))


def project(lat: float, lon: float, origin_lat: float, origin_lon: float) -> tuple[float, float]:
    """Project lat/lon to (x, z) studs relative to an origin. ~1 stud = 1 foot."""
    x = (lon - origin_lon) * _feet_per_degree_lon(origin_lat)
    z = -(lat - origin_lat) * FEET_PER_DEGREE_LAT  # north is -Z
    return x, z


def query(bbox: tuple[float, float, float, float], cache_dir: str = "osm_cache") -> dict:
    """Fetch buildings + highways in bbox = (south, west, north, east).

    Results are cached to disk so repeated generation is offline and fast.
    """
    os.makedirs(cache_dir, exist_ok=True)
    cache_key = "_".join(f"{c:.5f}" for c in bbox) + ".json"
    cache_path = os.path.join(cache_dir, cache_key)
    if os.path.exists(cache_path):
        with open(cache_path, encoding="utf-8") as f:
            return json.load(f)

    s, w, n, e = bbox
    ql = f"""
    [out:json][timeout:60];
    (
      way["building"]({s},{w},{n},{e});
      way["highway"]({s},{w},{n},{e});
    );
    out geom;
    """
    data = urllib.parse.urlencode({"data": ql}).encode()
    req = urllib.request.Request(
        OVERPASS_URL,
        data=data,
        headers={"User-Agent": "modern-mythicals-citygen/0.1 (ODbL attribution honored)"},
    )
    with urllib.request.urlopen(req, timeout=90) as resp:
        result = json.loads(resp.read().decode())

    with open(cache_path, "w", encoding="utf-8") as f:
        json.dump(result, f)
    return result


def footprints(result: dict, origin_lat: float, origin_lon: float) -> list[dict]:
    """Extract building footprints as lists of projected (x, z) points."""
    out = []
    for el in result.get("elements", []):
        if el.get("type") == "way" and "building" in el.get("tags", {}) and "geometry" in el:
            pts = [project(p["lat"], p["lon"], origin_lat, origin_lon) for p in el["geometry"]]
            tags = el.get("tags", {})
            # OSM building heights are inconsistent; floors default when absent.
            levels = tags.get("building:levels")
            floors = int(levels) if levels and levels.isdigit() else 2
            out.append({"points": pts, "floors": floors})
    return out
