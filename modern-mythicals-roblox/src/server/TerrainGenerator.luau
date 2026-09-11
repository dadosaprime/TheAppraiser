--!strict
-- Seeded runtime terrain. (Automation doc § "The terrain problem, solved".)
--
-- Terrain is NEVER baked into the place file (that would require Studio on a GUI
-- machine and break the headless pipeline). Instead a normal Script regenerates
-- identical terrain from a fixed seed at server start, using engine Terrain APIs.
-- Every server produces the same world deterministically; players can't tell.
--
-- The city itself is Parts (from the Python generator). This module handles only
-- the natural ground the city doesn't cover — chiefly the Everglades zone.

local Workspace = game:GetService("Workspace")

local TerrainGenerator = {}

TerrainGenerator.SEED = 20260816 -- fixed → deterministic across servers

-- Everglades footprint (studs). Kept modest; outdoor terrain is cheap and breaks
-- the visual monotony of city geometry.
local EVERGLADES = {
	origin = Vector3.new(4000, 0, 0),
	size = Vector3.new(2048, 64, 2048),
	waterLevel = -2,
}

-- Deterministic value noise. `phase` is drawn ONCE per generation from the
-- seeded RNG so adjacent cells stay spatially coherent (rolling, not jagged).
local function noise2(phase: number, x: number, z: number): number
	return math.noise(x / 96 + phase, z / 96 + phase)
end

function TerrainGenerator.generateEverglades()
	local terrain = Workspace.Terrain
	local rng = Random.new(TerrainGenerator.SEED)
	local phase = rng:NextNumber(0, 1000)

	local o = EVERGLADES.origin
	local s = EVERGLADES.size
	local step = 64 -- coarse voxel fill; good enough for a night swamp

	for x = 0, s.X - step, step do
		for z = 0, s.Z - step, step do
			local h = noise2(phase, x, z) * 6 -- gentle undulation
			local groundTop = o.Y + h
			local region = Region3.new(
				Vector3.new(o.X + x, o.Y - 8, o.Z + z),
				Vector3.new(o.X + x + step, groundTop, o.Z + z + step)
			):ExpandToGrid(4)
			terrain:FillRegion(region, 4, Enum.Material.Mud)

			-- Water sits in the low spots — the swamp read.
			if h < EVERGLADES.waterLevel then
				local water = Region3.new(
					Vector3.new(o.X + x, groundTop, o.Z + z),
					Vector3.new(o.X + x + step, o.Y + EVERGLADES.waterLevel, o.Z + z + step)
				):ExpandToGrid(4)
				terrain:FillRegion(water, 4, Enum.Material.Water)
			end
		end
	end
	print("[Terrain] Everglades generated from seed", TerrainGenerator.SEED)
end

function TerrainGenerator.init()
	-- Guard: only generate if not already present (hot reload / rejoin).
	if Workspace.Terrain:GetAttribute("EvergladesGenerated") then
		return
	end
	TerrainGenerator.generateEverglades()
	Workspace.Terrain:SetAttribute("EvergladesGenerated", true)
end

return TerrainGenerator
