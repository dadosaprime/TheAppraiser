--!strict
-- The Soul Pool — the resource every class but the Werewolf's shift spends.
--
-- From the tabletop: mundane actions are free; supernatural ones cost Soul from
-- your pool. Here the basic attack is free and every other ability has a cost.
-- Soul regenerates slowly and refills faster on kills, so a fight feeds you. The
-- pool's MAX is the profile's soulPool, which Soul-Rank boxes grow (+1 each) —
-- so buying boxes visibly widens the bar. Numbers are PLACEHOLDERS for playtest.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Net = require(Shared.Net)

local DataService = require(script.Parent.DataService)

local SoulService = {}

SoulService.REGEN_PER_SECOND = 1.2
SoulService.KILL_RESTORE = 6
SoulService.SHIFT_REGEN_HP = 3 -- health per second while the Werewolf is shifted

local soul: { [Player]: number } = {}
local locked: { [Player]: number } = {} -- Soul set aside while shifted (grey on the bar)
local lockRank: { [Player]: number } = {}
local lastPushed: { [Player]: string } = {}

local function maxFor(player: Player): number
	local profile = DataService.get(player)
	return if profile then math.max(profile.soulPool, 1) else 20
end

function SoulService.get(player: Player): number
	return soul[player] or 0
end

function SoulService.max(player: Player): number
	return maxFor(player)
end

function SoulService.locked(player: Player): number
	return locked[player] or 0
end

-- The usable ceiling: max minus whatever the form has locked away.
local function capFor(player: Player): number
	return math.max(maxFor(player) - (locked[player] or 0), 0)
end

-- Werewolf shift: set `amount` of the pool aside. It goes grey, can't be spent,
-- and won't refill until the form is dropped. Soul above the new cap is pushed
-- down into the lock — that's the price of the buff.
function SoulService.lock(player: Player, amount: number, rank: number)
	locked[player] = math.clamp(amount, 0, maxFor(player))
	lockRank[player] = rank
	soul[player] = math.min(soul[player] or 0, capFor(player))
end

function SoulService.unlock(player: Player)
	locked[player] = nil
	lockRank[player] = nil
end

function SoulService.isShifted(player: Player): boolean
	return (locked[player] or 0) > 0
end

-- Spend `cost`; returns false (and spends nothing) if short.
function SoulService.trySpend(player: Player, cost: number): boolean
	if cost <= 0 then
		return true
	end
	local have = soul[player] or 0
	if have < cost then
		return false
	end
	soul[player] = have - cost
	return true
end

function SoulService.restore(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	soul[player] = math.min((soul[player] or 0) + amount, capFor(player))
end

local function push(player: Player)
	local s = math.floor((soul[player] or 0) + 0.5)
	local m = maxFor(player)
	local l = math.floor((locked[player] or 0) + 0.5)
	local key = s .. "/" .. m .. "/" .. l
	if lastPushed[player] == key then
		return
	end
	lastPushed[player] = key
	Net.get("StatusUpdated"):FireClient(player, { soul = s, soulMax = m, soulLocked = l, shifted = l > 0 })
end

function SoulService.init()
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			locked[player] = nil -- a new body holds no form
			lockRank[player] = nil
			soul[player] = maxFor(player) -- respawn with a full pool
			lastPushed[player] = nil
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		soul[player] = nil
		locked[player] = nil
		lockRank[player] = nil
		lastPushed[player] = nil
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		for _, player in Players:GetPlayers() do
			local cap = capFor(player)
			local cur = soul[player]
			if cur == nil then
				soul[player] = cap
			else
				soul[player] = math.min(cur + SoulService.REGEN_PER_SECOND * dt, cap)
			end
			-- The beast heals while the form holds.
			if (locked[player] or 0) > 0 then
				local c = player.Character
				local h = c and c:FindFirstChildOfClass("Humanoid")
				if h and h.Health > 0 then
					local mult = if (lockRank[player] or 1) >= 2 then 1.4 else 1
					h.Health = math.min(h.Health + SoulService.SHIFT_REGEN_HP * mult * dt, h.MaxHealth)
				end
			end
			if acc >= 0.2 then
				push(player)
			end
		end
		if acc >= 0.2 then
			acc = 0
		end
	end)
end

return SoulService
