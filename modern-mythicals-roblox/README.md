# Modern Mythicals — Roblox

A co-op action RPG *loosely based* on the Modern Mythicals setting from Common Sense Games.
This is the game codebase: a headless, no-Studio build pipeline (Rojo + Open Cloud) with the
rules engine, class/perk data, and a Python city generator that turns OpenStreetMap data into
a playable Roblox map.

> ## ⛔ NOT CANON — HARD FIREWALL
>
> Everything in this repository is **Roblox game design and nothing else.** It *consumes* the
> Modern Mythicals canon (the MM-Bible in Dropbox); it never writes it. Class abilities, perk
> names, rank effects, invented businesses, and map geometry here are **game assets only** and
> have no standing in the universe. To make something here canon, it has to be written into a
> proper canon document first. See the design docs for the full firewall statement.

---

## What this is

| Layer | Tech | Status |
|---|---|---|
| Rules engine + game systems | Luau (Rojo-managed source tree) | Skeleton in place, seeded with real design data |
| Class / Perk / economy data | Luau data modules in `src/shared` | **Complete** — all 5 classes × 5 trees × 5 ranks, shared Defense tree, Soul Ranks, 3 currencies |
| City map | Python generator → `.rbxlx` from OpenStreetMap | Generator scaffold + Miami Club District plot list |
| Build & publish | Rojo build → Open Cloud Place Publishing API, driven from CI | GitHub Actions workflow (publish gated behind secrets) |
| Terrain | Seeded runtime `Script` (never baked into the place file) | Skeleton |

Nothing here requires Roblox Studio. The three constraints that keep it headless (no CSG unions,
no `SurfaceAppearance`, no baked terrain) are respected throughout.

## Repository layout

```
modern-mythicals-roblox/
├── default.project.json        # Rojo project — maps src/ into the DataModel
├── rokit.toml                  # toolchain pins (rojo, stylua, selene, lune)
├── wally.toml                  # Luau package dependencies
├── selene.toml / stylua.toml   # lint + format config
├── src/
│   ├── shared/                 # ReplicatedStorage.Shared — data + types + net registry
│   ├── server/                 # ServerScriptService.Server — authoritative game logic
│   └── client/                 # StarterPlayerScripts.Client — input + HUD
├── map/                        # generated city (.rbxmx) — output of the generator, gitignored
├── tools/city_generator/       # Python: OSM → plots → .rbxmx
└── .github/workflows/ci.yml    # lint → build → (publish, gated)
```

## Getting started (local, no Studio needed to build)

```bash
# 1. Install the toolchain (one time)
cargo install rokit   # or download from https://github.com/rojo-rbx/rokit
rokit install         # installs rojo, stylua, selene, lune per rokit.toml

# 2. Install Luau packages
wally install

# 3. Build a place file
rojo build -o ModernMythicals.rbxl

# 4. Generate the Miami map into map/ (Rojo picks it up as Workspace.Map)
cd tools/city_generator
pip install -r requirements.txt
python generate.py --config config/miami_club_district.json --out ../../map/GeneratedCity.rbxmx
cd ../..

# 5. Build again — the place now has ground, a spawn point, the city, and the
#    night lighting, so it is playable the moment it opens in Studio.
rojo build -o build/ModernMythicals.rbxl
```

Run steps 3–5 in that order (generate the map before the final build). The
`.rbxl` opens directly in Studio — no Rojo plugin required for a first test.

To iterate live: `rojo serve` and connect from Studio (optional), or publish headlessly via the
CI pipeline (see `.github/workflows/ci.yml`).

## The core design in one screen

- **5 classes:** Witch, Werewolf, Vampire, Frankenstein, Immortal.
- **One tree, one button:** every class has exactly 5 perk trees; each tree = one ability on one
  hotbar slot, with 5 ranks. Ranks upgrade the ability you already have — they never add a 6th
  button. The only way to a 6th ability is a **crossover tree** bought from the Church of Sol.
- **Progression:** earn **Soul Shards**, spend them on Soul-Rank boxes (10 per rank, triangular
  cost curve) *and* on perks — from the same pool. That tension is the whole meta.
- **3 currencies:** Soul Shards (earned only), Cash/gold (drops), Robux (cosmetics + tree *access*,
  never raw stats).
- **Perpetual night**, rotating hot-zone spawns, enemies built from the *same* perk data as players.
- **PvP:** stat-normalized 3v3 arenas, 4-minute matches, seasonal boards.

Full design lives in the Dropbox docs (`GenieWorkspace/CSG/ModernMythical/Roblox/`). The Luau data
modules in `src/shared` are the machine-readable version of those docs.

## Open items carried from the design docs

- PvP entrance to replace the cut "Arena" (Two-Doors principle; back blocks, not another sports bar).
- **Parry window in milliseconds** — flagged in the docs as "the most important number in the game".
- City launch order (Miami first, or move New Orleans / Tampa earlier).
- Fury build/drain rates, Charm NPC/player multipliers, crossover pricing — all need playtest tuning.
