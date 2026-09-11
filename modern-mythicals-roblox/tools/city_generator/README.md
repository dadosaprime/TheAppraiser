# City Generator

Turns an authored **plot list** (+ optional OpenStreetMap footprints) into a
`.rbxlx` place fragment of anchored Parts. No Studio, no CSG, no
`SurfaceAppearance`, no baked terrain — so the output flows straight through the
headless publish pipeline.

## Run it

```bash
pip install -r requirements.txt

# Authored plot list only (offline, deterministic):
python generate.py --config config/miami_club_district.json --out ../../build/miami.rbxlx

# Overlay real Miami building footprints from OpenStreetMap (needs network + osm_* config):
python generate.py --config config/miami_club_district.json --osm --out ../../build/miami.rbxlx
```

The output opens directly in Studio (drag the `.rbxlx` in) or can be merged into a
Rojo build.

## How it works

| File | Job |
|---|---|
| `plots.py` | Loads a district config; lays plots out along named road splines. |
| `facade_kit.py` | Turns each plot into a building shell + neon band (Collins only); landmark plots become tagged placeholders. |
| `rbxlx.py` | Minimal Roblox-XML writer (primitive Parts only). |
| `osm.py` | Optional Overpass API import — real footprints, "fictional tenants". |
| `generate.py` | Orchestrates the above and enforces the part budget. |
| `config/*.json` | The authored spine. **This is where your judgment lives** — a text file you can read and edit. |

## Editing the map

The plot list is the map. To move the House of Sol, change its `index` (plots pack
in ascending index per street). To re-skin the strip, change `neon` colors or
`type`s. To add Downtown or the Everglades, add another config file. "Move the
House of Sol three plots north" is a one-line change.

Landmark plots (`"type": "LANDMARK"`) emit a semi-transparent placeholder named
`LANDMARK::<name>`. The Studio/Rojo side swaps each for a hand-built interior model
by asset id — those three interiors (Steel Zebra, House of Sol, vampire bar) are
the only genuinely hand-built work in the district.

## Attribution

OSM data is **ODbL licensed** — if you use the `--osm` pass, the game must show an
attribution/credits line. A single label covers it.
