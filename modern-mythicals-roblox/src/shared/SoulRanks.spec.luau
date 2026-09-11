--!nocheck
-- TestEZ spec for the Soul-Rank economy. Excluded from Rojo builds
-- (globIgnorePaths: **/*.spec.luau). Runnable on real Roblox servers via the
-- Open Cloud Luau Execution API in CI, or under a local TestEZ runner.

return function()
	local SoulRanks = require(game.ReplicatedStorage.Shared.SoulRanks)

	describe("box and rank costs", function()
		it("scales box cost linearly with rank", function()
			expect(SoulRanks.boxCost(1)).to.equal(1000)
			expect(SoulRanks.boxCost(5)).to.equal(5000)
			expect(SoulRanks.boxCost(10)).to.equal(10000)
		end)

		it("costs 10x the box to complete a rank", function()
			expect(SoulRanks.rankCost(1)).to.equal(10000)
			expect(SoulRanks.rankCost(10)).to.equal(100000)
		end)

		it("sums to 550,000 shards for Soul 10 (design doc figure)", function()
			local total = 0
			for r = 1, SoulRanks.MAX_RANK do
				total += SoulRanks.rankCost(r)
			end
			expect(total).to.equal(550000)
		end)
	end)

	describe("applyBox", function()
		it("rolls the tenth box into a rank-up", function()
			local rank, boxes, health, pool = 1, 9, 100, 20
			local rankedUp
			rank, boxes, health, pool, rankedUp = SoulRanks.applyBox(rank, boxes, health, pool)
			expect(rankedUp).to.equal(true)
			expect(rank).to.equal(2)
			expect(boxes).to.equal(0)
			-- rank-up jump applied on top of the per-box increment
			expect(health > 100).to.equal(true)
			expect(pool > 20).to.equal(true)
		end)

		it("gives every box a small increment (no dead purchases)", function()
			local h0, p0 = 100, 20
			local _, _, h1, p1 = SoulRanks.applyBox(1, 0, h0, p0)
			expect((h1 - h0) + (p1 - p0) > 0).to.equal(true)
		end)

		it("does not advance past the max rank", function()
			local rank, boxes = SoulRanks.applyBox(10, 9, 100, 20)
			expect(rank).to.equal(10)
		end)
	end)

	describe("canBuyBox", function()
		it("rejects when shards are short", function()
			expect(SoulRanks.canBuyBox(1, 0, 999)).to.equal(false)
			expect(SoulRanks.canBuyBox(1, 0, 1000)).to.equal(true)
		end)
	end)
end
