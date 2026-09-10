--!strict
-- Player data persistence.
--
-- The design doc calls for "DataStore persistence" as a fully-automatable layer.
-- This service owns the in-memory PlayerProfile for each session and saves it to a
-- DataStore. It is written to sit on top of ProfileService (session locking +
-- reconciliation) when the Wally package is installed; until then it uses a plain
-- DataStore wrapper with autosave so the rest of the codebase can be built and
-- tested against a stable API.
--
-- Public API is deliberately small:
--   DataService.init()
--   DataService.get(player)      -> PlayerProfile?    (nil until loaded)
--   DataService.loaded(player)   -> Signal-ish; calls cb once profile is ready
--   DataService.markDirty(player)                     (schedules a save)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local SoulRanks = require(Shared.SoulRanks)

local DataService = {}

local STORE_NAME = "PlayerProfiles_v1"
local AUTOSAVE_INTERVAL = 60 -- seconds
local profileStore = DataStoreService:GetDataStore(STORE_NAME)

type Profile = {
	class: string?,
	soulRank: number,
	boxesInRank: number,
	soulShards: number,
	cash: number,
	health: number,
	soulPool: number,
	perks: { [string]: number },
	crossoverAccess: { [string]: boolean },
	cosmetics: { [string]: boolean },
	stats: { nightsPlayed: number, enemiesFelled: number, arenaWins: number },
}

local profiles: { [Player]: Profile } = {}
local waiters: { [Player]: { (Profile) -> () } } = {}
local dirty: { [Player]: boolean } = {}

local function defaultProfile(): Profile
	return {
		class = nil,
		soulRank = 1,
		boxesInRank = 0,
		soulShards = 0,
		cash = 0,
		health = SoulRanks.BASE_HEALTH,
		soulPool = SoulRanks.BASE_SOUL_POOL,
		perks = {},
		crossoverAccess = {},
		cosmetics = {},
		stats = { nightsPlayed = 0, enemiesFelled = 0, arenaWins = 0 },
	}
end

-- Fill any missing keys after a schema change (cheap reconciliation).
local function reconcile(loaded: any): Profile
	local base = defaultProfile()
	if type(loaded) ~= "table" then
		return base
	end
	for key, value in base do
		if loaded[key] == nil then
			loaded[key] = value
		end
	end
	return loaded :: Profile
end

local function key(player: Player): string
	return "player_" .. player.UserId
end

local function load(player: Player)
	local ok, result = pcall(function()
		return profileStore:GetAsync(key(player))
	end)
	if not player.Parent then
		return -- left during load
	end
	local profile = reconcile(ok and result or nil)
	if not ok then
		warn(("[DataService] load failed for %s; using fresh profile"):format(player.Name))
	end
	profiles[player] = profile
	for _, cb in waiters[player] or {} do
		task.spawn(cb, profile)
	end
	waiters[player] = nil
end

local function save(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local ok, err = pcall(function()
		profileStore:SetAsync(key(player), profile)
	end)
	if ok then
		dirty[player] = nil
	else
		warn(("[DataService] save failed for %s: %s"):format(player.Name, tostring(err)))
	end
end

function DataService.get(player: Player): Profile?
	return profiles[player]
end

-- Register a callback that fires once the profile is loaded (or immediately if it
-- already is). Cheap stand-in for a Signal.
function DataService.loaded(player: Player, cb: (Profile) -> ())
	local existing = profiles[player]
	if existing then
		task.spawn(cb, existing)
		return
	end
	waiters[player] = waiters[player] or {}
	table.insert(waiters[player], cb)
end

function DataService.markDirty(player: Player)
	dirty[player] = true
end

function DataService.init()
	Players.PlayerAdded:Connect(load)
	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profiles[player] = nil
		waiters[player] = nil
		dirty[player] = nil
	end)
	-- Handle players already present (Studio play solo / hot reload).
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end

	-- Autosave loop for dirty profiles.
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in dirty do
				if player.Parent then
					save(player)
				end
			end
		end
	end)

	-- Best-effort flush on server shutdown.
	game:BindToClose(function()
		if RunService:IsStudio() then
			return
		end
		for _, player in Players:GetPlayers() do
			save(player)
		end
		task.wait(2)
	end)
end

return DataService
