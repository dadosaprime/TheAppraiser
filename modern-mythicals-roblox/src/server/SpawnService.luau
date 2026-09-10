--!strict
-- Rotating hot-zone spawning. (Design doc § VIII "Spawn design".)
--
-- Static respawns get boring. Instead: a few districts run hot each night, spawn
-- density climbs the longer players linger, and once a zone crosses an escalation
-- threshold, something bigger shows up to see what's killing everything.
--
-- This is the scheduling skeleton — it decides WHAT spawns WHERE and HOW DENSE.
-- Actually instancing an enemy model is left to a spawner hook (needs AssetIds).

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.GameConfig)
local Enemies = require(Shared.Enemies)

local SpawnService = {}

export type Zone = {
	id: string,
	displayName: string,
	factions: { string }, -- which enemy factions can spawn here
	baseDensity: number, -- multiplier at zone activation
	elite: string?, -- archetype id that arrives on escalation
}

-- Miami zones. Faction mix per the design doc (New Order + gangs downtown,
-- Naraka in the Everglades, etc.).
SpawnService.Zones = {
	ClubBeach = {
		id = "ClubBeach",
		displayName = "Club / Beach District",
		factions = { "New Order", "Darkling Gang" },
		baseDensity = 0.6,
		elite = "RiddenLeader",
	},
	Downtown = {
		id = "Downtown",
		displayName = "Downtown Miami",
		factions = { "New Order", "Darkling Gang", "Joi Boyz" },
		baseDensity = 1.0,
		elite = "NewOrderAwakened",
	},
	Everglades = {
		id = "Everglades",
		displayName = "The Everglades",
		factions = { "Naraka" },
		baseDensity = 0.8,
		elite = "NarakaElder",
	},
} :: { [string]: Zone }

-- Live per-zone runtime state.
type ZoneState = {
	hot: boolean,
	activatedAt: number,
	felled: number, -- enemies killed here this night; drives escalation
	eliteSpawned: boolean,
}
local zoneStates: { [string]: ZoneState } = {}

local function pickHotZones()
	local ids = {}
	for id in SpawnService.Zones do
		table.insert(ids, id)
	end
	-- Shuffle and take the configured number of hot zones.
	for i = #ids, 2, -1 do
		local j = math.random(i)
		ids[i], ids[j] = ids[j], ids[i]
	end
	for _, id in ids do
		zoneStates[id] = { hot = false, activatedAt = 0, felled = 0, eliteSpawned = false }
	end
	for i = 1, math.min(GameConfig.Spawns.HotZonesPerNight, #ids) do
		local st = zoneStates[ids[i]]
		st.hot = true
		st.activatedAt = os.clock()
	end
end

-- Current spawn density for a zone (climbs with dwell time, capped).
function SpawnService.densityFor(zoneId: string): number
	local zone = SpawnService.Zones[zoneId]
	local st = zoneStates[zoneId]
	if not zone or not st or not st.hot then
		return 0
	end
	local minutes = (os.clock() - st.activatedAt) / 60
	local ramp = 1 + minutes * GameConfig.Spawns.DensityRampPerMinute
	return math.min(zone.baseDensity * ramp, zone.baseDensity * GameConfig.Spawns.DensityCap)
end

-- Report a kill in a zone; may trigger the elite escalation.
function SpawnService.reportKill(zoneId: string)
	local st = zoneStates[zoneId]
	local zone = SpawnService.Zones[zoneId]
	if not st or not zone then
		return
	end
	st.felled += 1
	if not st.eliteSpawned and st.felled >= GameConfig.Spawns.EscalationThreshold and zone.elite then
		st.eliteSpawned = true
		local elite = Enemies.get(zone.elite)
		if elite then
			SpawnService.spawnEnemy(zoneId, elite.id)
			print(("[Spawn] Escalation in %s — %s arrives."):format(zone.displayName, elite.displayName))
		end
	end
end

-- Hook: instance an enemy model in the world. Needs AssetIds + a nav mesh.
SpawnService.spawnEnemy = function(_zoneId: string, _archetypeId: string) end

function SpawnService.startNight()
	pickHotZones()
end

function SpawnService.init()
	SpawnService.startNight()
end

return SpawnService
