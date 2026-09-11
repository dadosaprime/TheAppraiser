--!strict
-- Soul Ranks & Shards — the progression spine. (Design doc § II.)
--
-- Each Soul rank has 10 boxes. Every box at a given rank costs the same;
-- cost scales linearly with rank (triangular total curve). Every box grants a
-- small increment; the TENTH box triggers the rank-up event with the big jump.
--
--   Rank 1: 1,000 shards/box  → 10,000 to complete
--   Rank 2: 2,000 shards/box  → 20,000
--   ...
--   Rank 10: 10,000 shards/box → 100,000
--   Cumulative to Soul 10: 550,000 shards.

local SoulRanks = {}

SoulRanks.MAX_RANK = 10
SoulRanks.BOXES_PER_RANK = 10
SoulRanks.SHARDS_PER_BOX_PER_RANK = 1000 -- box cost = rank * this

-- Small per-box increments, alternating so no box is a dead purchase.
-- The 10th box adds the large rank-up jump on top.
SoulRanks.INCREMENT_HEALTH = 1
SoulRanks.INCREMENT_SOUL_POOL = 1
SoulRanks.RANKUP_HEALTH_JUMP = 10
SoulRanks.RANKUP_SOUL_POOL_JUMP = 10

SoulRanks.BASE_HEALTH = 100
SoulRanks.BASE_SOUL_POOL = 20

-- Shard cost of the next box at a given rank.
function SoulRanks.boxCost(rank: number): number
	assert(rank >= 1 and rank <= SoulRanks.MAX_RANK, "rank out of range")
	return rank * SoulRanks.SHARDS_PER_BOX_PER_RANK
end

-- Cost to complete an entire rank (all 10 boxes).
function SoulRanks.rankCost(rank: number): number
	return SoulRanks.boxCost(rank) * SoulRanks.BOXES_PER_RANK
end

-- Cumulative shards to reach the START of a given rank (i.e. finish all below).
function SoulRanks.cumulativeToRank(rank: number): number
	local total = 0
	for r = 1, rank - 1 do
		total += SoulRanks.rankCost(r)
	end
	return total
end

-- Is the player allowed to buy the next box? (Rank cap + affordability.)
function SoulRanks.canBuyBox(rank: number, boxesInRank: number, shards: number): boolean
	if rank >= SoulRanks.MAX_RANK and boxesInRank >= SoulRanks.BOXES_PER_RANK then
		return false -- fully maxed
	end
	return shards >= SoulRanks.boxCost(rank)
end

-- Apply one box purchase. Returns the mutated progression fields.
-- Handles the tenth-box rank-up rollover and the big stat jump.
function SoulRanks.applyBox(
	rank: number,
	boxesInRank: number,
	health: number,
	soulPool: number
): (number, number, number, number, boolean)
	local rankedUp = false
	local boxIndex = boxesInRank + 1

	-- Alternating small increment on every box.
	if boxIndex % 2 == 1 then
		health += SoulRanks.INCREMENT_HEALTH
	else
		soulPool += SoulRanks.INCREMENT_SOUL_POOL
	end

	if boxIndex >= SoulRanks.BOXES_PER_RANK then
		-- Tenth box: the rank-up event.
		rankedUp = true
		health += SoulRanks.RANKUP_HEALTH_JUMP
		soulPool += SoulRanks.RANKUP_SOUL_POOL_JUMP
		if rank < SoulRanks.MAX_RANK then
			rank += 1
			boxesInRank = 0
		else
			boxesInRank = SoulRanks.BOXES_PER_RANK -- stay maxed
		end
	else
		boxesInRank = boxIndex
	end

	return rank, boxesInRank, health, soulPool, rankedUp
end

return SoulRanks
