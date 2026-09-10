--!strict
-- The Fury meter — the Werewolf's resource. (ClassPerkTrees doc.)
--
-- Werewolves do not spend Soul Pool to shift. Fury BUILDS by dealing and taking
-- damage and DRAINS while shifted; when it runs out the wolf reverts. Human form
-- is the wind-up, not dead time. This is the only class whose resource rewards
-- staying in the fight. Numbers are PLACEHOLDERS for playtest.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Net = require(Shared.Net)
local GameConfig = require(Shared.GameConfig)

local DataService = require(script.Parent.DataService)

local Fury = {}

Fury.MAX = 100
Fury.SHIFT_COST = 40 -- minimum Fury to shift
Fury.DRAIN_PER_SECOND = 6 -- rank 4 ("Sustained Form") slows this
Fury.REGEN_PER_SECOND = 3 -- health regen while shifted; rank 2 faster
Fury.GAIN_DEALT = 0.35 -- Fury per point of damage dealt
Fury.GAIN_TAKEN = 0.5 -- Fury per point of damage taken

local fury: { [Player]: number } = {}
local shiftRank: { [Player]: number } = {}
local lastPushed: { [Player]: string } = {}

-- Hooks set by AbilityEffects (which owns shift state) to avoid a require cycle.
Fury.isShifted = function(_player: Player): boolean
	return false
end
Fury.endShift = function(_player: Player) end

local function isWerewolf(player: Player): boolean
	local profile = DataService.get(player)
	return profile ~= nil and profile.class == "Werewolf"
end

function Fury.get(player: Player): number
	return fury[player] or 0
end

function Fury.add(player: Player, amount: number)
	if amount <= 0 or not isWerewolf(player) then
		return
	end
	fury[player] = math.clamp((fury[player] or 0) + amount, 0, Fury.MAX)
end

function Fury.canShift(player: Player): boolean
	return GameConfig.Playtest.WerewolfStartsShifted or Fury.get(player) >= Fury.SHIFT_COST
end

function Fury.setShiftRank(player: Player, rank: number)
	shiftRank[player] = rank
end

local function push(player: Player, shifted: boolean)
	local f = math.floor(Fury.get(player) + 0.5)
	local key = f .. ":" .. tostring(shifted)
	if lastPushed[player] == key then
		return
	end
	lastPushed[player] = key
	Net.get("StatusUpdated"):FireClient(player, {
		fury = f,
		furyMax = Fury.MAX,
		shiftCost = Fury.SHIFT_COST,
		shifted = shifted,
	})
end

function Fury.init()
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			fury[player] = 0
			lastPushed[player] = nil
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		fury[player] = nil
		shiftRank[player] = nil
		lastPushed[player] = nil
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		for _, player in Players:GetPlayers() do
			if isWerewolf(player) then
				local shifted = Fury.isShifted(player)
				if shifted then
					local rank = shiftRank[player] or 1
					-- Fast regen: the beast heals.
					local c = player.Character
					local h = c and c:FindFirstChildOfClass("Humanoid")
					if h and h.Health > 0 then
						local regen = Fury.REGEN_PER_SECOND * (if rank >= 2 then 1.4 else 1)
						h.Health = math.min(h.Health + regen * dt, h.MaxHealth)
					end
					-- Drain: the form is borrowed time.
					if not GameConfig.Playtest.WerewolfStartsShifted then
						local drain = Fury.DRAIN_PER_SECOND * (if rank >= 4 then 0.6 else 1)
						fury[player] = math.max((fury[player] or 0) - drain * dt, 0)
						if fury[player] <= 0 then
							Fury.endShift(player)
							shifted = false
						end
					end
				end
				if acc >= 0.2 then
					push(player, shifted)
				end
			end
		end
		if acc >= 0.2 then
			acc = 0
		end
	end)
end

return Fury
