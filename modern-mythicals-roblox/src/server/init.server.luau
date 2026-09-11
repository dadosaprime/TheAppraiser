--!strict
-- Server bootstrap. Builds remotes, starts services, wires the network layer to
-- the game systems. This is the single entry point Rojo turns into a Script under
-- ServerScriptService.Server.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

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
local TrainingDummies = require(script.TrainingDummies)
local StreetGang = require(script.StreetGang)
local LootService = require(script.LootService)
local SoulService = require(script.SoulService)
local CosmeticService = require(script.CosmeticService)
local StoreService = require(script.StoreService)

-- ── Start services ──────────────────────────────────────────────────────────
DataService.init()
SoulService.init()
SpawnService.init()
TerrainGenerator.init()
TrainingDummies.init()
StreetGang.init()
LootService.init()
CosmeticService.init()
StoreService.init()

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
	-- Choosing a class is one-time for now. Every class starts with its first
	-- TWO trees at rank 1 (plus the basic attack, wherever it lives), so each
	-- class opens with an attack and a signature ability, not a single button.
	if profile.class == nil then
		profile.class = classId
		local class = Classes.get(classId)
		if class then
			for _, treeId in { class.trees[1], class.trees[2], class.attackTree } do
				if treeId then
					profile.perks[treeId] = math.max(profile.perks[treeId] or 0, 1)
				end
			end
		end
		-- Playtest: seed shards so progression can be exercised immediately.
		profile.soulShards += GameConfig.Playtest.StartingShards
		profile.cash += GameConfig.Playtest.StartingCash
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

-- A press that reaches us late is thrown away, never run later: one click is
-- one activation, and nothing is stored. Also one request at a time per player.
local STALE_SECONDS = 0.35
local activating: { [Player]: boolean } = {}
Net.get("ActivateAbility").OnServerEvent:Connect(function(player, payload)
	if type(payload) ~= "table" then
		return
	end
	if type(payload.t) == "number" and Workspace:GetServerTimeNow() - payload.t > STALE_SECONDS then
		return -- arrived too late; the moment has passed
	end
	if activating[player] then
		return
	end
	activating[player] = true
	local slot = payload.slot
	if payload.attack == true then
		-- Left-click: the class's basic attack, whichever slot holds it.
		local profile = DataService.get(player)
		local class = profile and profile.class and Classes.get(profile.class)
		slot = if class then table.find(class.trees, class.attackTree) else nil
	end
	if type(slot) ~= "number" then
		activating[player] = nil
		return
	end
	local result = AbilityService.activate(player, slot, payload.aimPoint)
	activating[player] = nil
	Net.get("AbilityFeedback"):FireClient(player, {
		slot = slot,
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
	if GameConfig.Playtest.WerewolfStartsShifted and profile and profile.class == "Werewolf" then
		task.delay(1, function()
			local class = Classes.get("Werewolf")
			local shiftSlot = class and table.find(class.trees, "TheTurning")
			if shiftSlot and character.Parent and player.Character == character then
				AbilityService.activate(player, shiftSlot, nil)
			end
		end)
	end
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
	activating[player] = nil
end)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end

-- ── Fixed combat step (bleedouts, DOTs later) ───────────────────────────────
RunService.Heartbeat:Connect(function()
	CombatService.step()
end)

print("[ModernMythicals] Server started.")
