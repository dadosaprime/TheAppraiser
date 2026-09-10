--!strict
-- Soul Ranks, Shards, and perk purchasing — the progression authority.
--
-- Shards buy BOTH rank boxes and perks from the same pool. That tension (push the
-- ceiling vs. get wider now) is the central meta, so all spending funnels through
-- here where it is validated server-side.

local Shared = game:GetService("ReplicatedStorage").Shared
local SoulRanks = require(Shared.SoulRanks)
local PerkTrees = require(Shared.PerkTrees)
local Classes = require(Shared.Classes)

local DataService = require(script.Parent.DataService)

local ProgressionService = {}

export type Result = { ok: boolean, err: string?, profile: any? }

local function fail(err: string): Result
	return { ok = false, err = err }
end

-- Award Soul Shards (from kills, quests). Central entry point.
function ProgressionService.awardShards(player: Player, amount: number)
	local profile = DataService.get(player)
	if not profile or amount <= 0 then
		return
	end
	profile.soulShards += amount
	DataService.markDirty(player)
	ProgressionService._push(player, profile)
end

-- Buy the next Soul-rank box.
function ProgressionService.purchaseBox(player: Player): Result
	local profile = DataService.get(player)
	if not profile then
		return fail("profile not loaded")
	end
	if not SoulRanks.canBuyBox(profile.soulRank, profile.boxesInRank, profile.soulShards) then
		return fail("cannot buy box (maxed or not enough shards)")
	end

	local cost = SoulRanks.boxCost(profile.soulRank)
	profile.soulShards -= cost

	local rank, boxes, health, pool, rankedUp = SoulRanks.applyBox(
		profile.soulRank,
		profile.boxesInRank,
		profile.health,
		profile.soulPool
	)
	profile.soulRank, profile.boxesInRank = rank, boxes
	profile.health, profile.soulPool = health, pool

	DataService.markDirty(player)
	ProgressionService._push(player, profile)
	return { ok = true, profile = profile, err = if rankedUp then "RANK_UP" else nil }
end

-- Is a tree one this player is allowed to buy into?
-- (Own class's 5 trees + the shared Defense tree + any crossover they bought access to.)
local function treeAllowed(profile: any, treeId: string): boolean
	if treeId == PerkTrees.SHARED_DEFENSE then
		return true
	end
	if profile.crossoverAccess[treeId] then
		return true
	end
	local class = profile.class and Classes.get(profile.class)
	if class then
		for _, id in class.trees do
			if id == treeId then
				return true
			end
		end
	end
	return false
end

-- Buy the next rank of a perk tree.
function ProgressionService.purchasePerk(player: Player, treeId: string): Result
	local profile = DataService.get(player)
	if not profile then
		return fail("profile not loaded")
	end
	local tree = PerkTrees.get(treeId)
	if not tree then
		return fail("unknown tree")
	end
	if not treeAllowed(profile, treeId) then
		return fail("tree not accessible — buy crossover access from the Church of Sol")
	end

	local current = profile.perks[treeId] or 0
	if current >= PerkTrees.MAX_RANK then
		return fail("tree already maxed")
	end

	local nextRank = current + 1
	local rankDef = tree.ranks[nextRank]
	if not rankDef then
		return fail("no such rank")
	end
	if profile.soulShards < rankDef.shardCost then
		return fail("not enough shards")
	end

	profile.soulShards -= rankDef.shardCost
	profile.perks[treeId] = nextRank

	DataService.markDirty(player)
	ProgressionService._push(player, profile)
	return { ok = true, profile = profile }
end

-- Grant crossover-tree ACCESS (called after a Robux purchase is verified elsewhere).
function ProgressionService.grantCrossoverAccess(player: Player, treeId: string): Result
	local profile = DataService.get(player)
	if not profile then
		return fail("profile not loaded")
	end
	if not PerkTrees.get(treeId) then
		return fail("unknown tree")
	end
	profile.crossoverAccess[treeId] = true
	DataService.markDirty(player)
	ProgressionService._push(player, profile)
	return { ok = true, profile = profile }
end

-- Wired by init.server.luau to push profile updates to the owning client.
ProgressionService._push = function(_player: Player, _profile: any) end

return ProgressionService
