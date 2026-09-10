--!strict
-- Server bootstrap. Builds remotes, starts services, wires the network layer to
-- the game systems. This is the single entry point Rojo turns into a Script under
-- ServerScriptService.Server.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Net = require(Shared.Net)
local Classes = require(Shared.Classes)
local GameConfig = require(Shared.GameConfig)

-- Build the network layer FIRST, before any service loads, so a failing
-- service surfaces as an error in Output instead of a client that waits forever.
Net.build()

local DataService = require(script.DataService)
local ProgressionService = require(script.ProgressionService)
local AbilityService = require(script.AbilityService)
local CombatService = require(script.CombatService)
local SpawnService = require(script.SpawnService)
local TerrainGenerator = require(script.TerrainGenerator)

-- ── Start services ──────────────────────────────────────────────────────────
DataService.init()
SpawnService.init()
TerrainGenerator.init()

-- ── Push helpers: send fresh profile to a client ────────────────────────────
local function pushProfile(player: Player, profile: any)
	Net.get("ProfileUpdated"):FireClient(player, profile)
end
ProgressionService._push = pushProfile

-- ── Combat events → clients (HUD / VFX) ─────────────────────────────────────
CombatService.onCombatEvent = function(char, applied, dmgType, healthLeft, downed)
	local player = Players:GetPlayerFromCharacter(char)
	if player then
		Net.get("CombatEvent"):FireClient(player, {
			applied = applied,
			dmgType = dmgType,
			healthLeft = healthLeft,
			downed = downed,
		})
	end
end

-- ── Remote handlers ─────────────────────────────────────────────────────────
Net.get("RequestProfile").OnServerInvoke = function(player)
	local profile = DataService.get(player)
	return profile
end

Net.get("ChooseClass").OnServerInvoke = function(player, classId)
	if type(classId) ~= "string" or not Classes.get(classId) then
		return { ok = false, err = "unknown class" }
	end
	local profile = DataService.get(player)
	if not profile then
		return { ok = false, err = "profile not loaded" }
	end
	-- Choosing a class is one-time for now; grant rank 1 of the basic-attack tree
	-- so the player has a usable button immediately.
	if profile.class == nil then
		profile.class = classId
		local class = Classes.get(classId)
		if class then
			profile.perks[class.trees[1]] = math.max(profile.perks[class.trees[1]] or 0, 1)
		end
		-- Playtest: seed shards so progression can be exercised immediately.
		profile.soulShards += GameConfig.Playtest.StartingShards
		DataService.markDirty(player)
		pushProfile(player, profile)
		return { ok = true }
	end
	return { ok = false, err = "class already chosen" }
end

Net.get("PurchaseBox").OnServerInvoke = function(player)
	local result = ProgressionService.purchaseBox(player)
	if result.ok and result.rankedUp and result.profile then
		Net.get("Toast"):FireClient(player, ("Soul Rank %d!"):format(result.profile.soulRank))
	end
	return result
end

Net.get("PurchasePerk").OnServerInvoke = function(player, treeId)
	if type(treeId) ~= "string" then
		return { ok = false, err = "bad tree id" }
	end
	return ProgressionService.purchasePerk(player, treeId)
end

Net.get("ActivateAbility").OnServerEvent:Connect(function(player, payload)
	if type(payload) ~= "table" or type(payload.slot) ~= "number" then
		return
	end
	local result = AbilityService.activate(player, payload.slot, payload.target)
	Net.get("AbilityFeedback"):FireClient(player, {
		slot = payload.slot,
		ok = result.ok,
		err = result.err,
		cooldown = result.cooldown,
	})
end)

-- ── Register/cleanup combat state per character ─────────────────────────────
local function onCharacter(player: Player, character: Model)
	local profile = DataService.get(player)
	local maxHealth = profile and profile.health or 100
	CombatService.register(character, maxHealth)
	character.Destroying:Connect(function()
		CombatService.unregister(character)
	end)
end

local function onPlayer(player: Player)
	DataService.loaded(player, function(profile)
		pushProfile(player, profile)
	end)
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(function(player)
	AbilityService.clearPlayer(player)
end)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end

-- ── Fixed combat step (bleedouts, DOTs later) ───────────────────────────────
RunService.Heartbeat:Connect(function()
	CombatService.step()
end)

print("[ModernMythicals] Server started.")
