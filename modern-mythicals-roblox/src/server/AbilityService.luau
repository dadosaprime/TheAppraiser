--!strict
-- Ability activation — the "one tree, one button" dispatcher.
--
-- The client sends a hotbar slot (1-5). The server looks up which tree occupies
-- that slot for the player's class, checks the owned rank and cooldown, and runs
-- the ability's effect at that rank. Rank 0 (not owned) is rejected.
--
-- Effects themselves are intentionally thin here: each is a hook that will call
-- into CombatService / movement / VFX. What matters at this layer is that
-- activation is AUTHORITATIVE and cooldowns cannot be spoofed by the client.

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.GameConfig)
local Classes = require(Shared.Classes)
local PerkTrees = require(Shared.PerkTrees)

local DataService = require(script.Parent.DataService)
local AbilityEffects = require(script.Parent.AbilityEffects)
local SoulService = require(script.Parent.SoulService)

local AbilityService = {}

-- cooldowns[player][treeId] = os.clock() timestamp when the ability is ready again
local cooldowns: { [Player]: { [string]: number } } = {}

-- Base cooldown per role (seconds). PLACEHOLDER — tune per ability in playtest.
-- Ranks generally shorten these; that scaling lives in the effect handlers.
local BASE_COOLDOWN: { [string]: number } = {
	["basic attack"] = 0.6,
	["basic attack + sustain"] = 0.8,
	["heavy offense"] = 8,
	["heavy offense / control"] = 8,
	["defense + melee"] = 6,
	["defense / signature"] = 1.2, -- parry is fast; the window is the skill test
	["control"] = 10,
	["control / team"] = 12,
	["mobility offense"] = 5,
	["escape"] = 14,
	["movement"] = 4,
	["utility / unlock"] = 2,
	["utility / tracking"] = 10,
	["stealth + movement"] = 8,
	["burst"] = 0, -- gated by being in stealth, not a timer
	["revive / support"] = 3,
	["sustain / self-res"] = 999, -- once per night; handled specially
	["the shift"] = 1,
	["offense"] = 0.6,
}

-- Soul cost per role. The basic attack is free (mundane); supernatural
-- abilities draw from the pool. The Werewolf's shift and claws are free here
-- because the shift's price is a locked slice of the pool instead (see
-- SoulService.lock). PLACEHOLDER — tune in playtest.
local SOUL_COST: { [string]: number } = {
	["basic attack"] = 0,
	["basic attack + sustain"] = 0,
	["offense"] = 0,
	["the shift"] = 0,
	["heavy offense"] = 8,
	["heavy offense / control"] = 8,
	["defense + melee"] = 0, -- held form: locks Soul instead
	["defense / signature"] = 2,
	["control"] = 7,
	["control / team"] = 8,
	["mobility offense"] = 5,
	["escape"] = 8,
	["movement"] = 4,
	["utility / unlock"] = 3,
	["utility / tracking"] = 4,
	["stealth + movement"] = 0, -- held form: locks Soul instead
	["burst"] = 4,
	["revive / support"] = 10,
	["sustain / self-res"] = 0,
}

function AbilityService.soulCost(treeId: string): number
	local tree = PerkTrees.get(treeId)
	return if tree then (SOUL_COST[tree.role] or 0) else 0
end

local function readyAt(player: Player, treeId: string): number
	local perPlayer = cooldowns[player]
	if not perPlayer then
		return 0
	end
	return perPlayer[treeId] or 0
end

local function setCooldown(player: Player, treeId: string, seconds: number)
	cooldowns[player] = cooldowns[player] or {}
	cooldowns[player][treeId] = os.clock() + math.max(seconds, GameConfig.Combat.GlobalCooldownSeconds)
end

-- Resolve which tree sits on a hotbar slot for this player's class.
local function treeForSlot(classId: string, slot: number): string?
	local class = Classes.get(classId)
	if not class then
		return nil
	end
	return class.trees[slot] -- trees are stored in slot order 1..5
end

export type ActivateResult = { ok: boolean, err: string?, cooldown: number? }

-- Main entry: client requested activation of a hotbar slot.
function AbilityService.activate(player: Player, slot: number, target: any?): ActivateResult
	local profile = DataService.get(player)
	if not profile or not profile.class then
		return { ok = false, err = "no class chosen" }
	end
	if slot < 1 or slot > 5 then
		return { ok = false, err = "bad slot" }
	end

	local treeId = treeForSlot(profile.class, slot)
	if not treeId then
		return { ok = false, err = "no ability on slot" }
	end

	local rank = profile.perks[treeId] or 0
	if rank < 1 then
		return { ok = false, err = "ability not unlocked — buy rank 1" }
	end

	local now = os.clock()
	local ready = readyAt(player, treeId)
	if now < ready then
		return { ok = false, err = "on cooldown", cooldown = ready - now }
	end

	local tree = PerkTrees.get(treeId)
	assert(tree, "tree missing")

	-- Spend Soul first (supernatural abilities only), refund if the effect refuses.
	local cost = SOUL_COST[tree.role] or 0
	if cost > 0 and not SoulService.trySpend(player, cost) then
		return { ok = false, err = ("Not enough Soul — %d needed"):format(cost) }
	end

	-- Run the effect. Effects may return a cooldown override and/or a refusal.
	local cdOverride, err = AbilityService.runEffect(player, treeId, rank, target)
	if err then
		if cost > 0 then
			SoulService.restore(player, cost)
		end
		return { ok = false, err = err }
	end
	local cd = cdOverride or BASE_COOLDOWN[tree.role] or 1
	setCooldown(player, treeId, cd)

	return { ok = true, cooldown = cd }
end

-- Effect dispatcher. Returns an optional cooldown override.
-- Real effects live in AbilityEffects.luau keyed by tree id; trees without an
-- entry yet fall through to a log line so the button still "works".
function AbilityService.runEffect(player: Player, treeId: string, rank: number, target: any?): (number?, string?)
	local tree = PerkTrees.get(treeId)
	if not tree then
		return nil
	end
	local effect = AbilityEffects[treeId]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if effect and character and humanoid and root and root:IsA("BasePart") and humanoid.Health > 0 then
		-- `target` is a world point (under the player's cursor). Aim from chest
		-- height toward it; fall back to facing direction.
		local aim = root.CFrame.LookVector
		if typeof(target) == "Vector3" then
			local d = target - (root.Position + Vector3.new(0, 0.5, 0))
			if d.Magnitude > 1 then
				aim = d.Unit
			end
		end
		return effect({
			player = player,
			character = character,
			humanoid = humanoid,
			root = root,
			rank = rank,
			aim = aim,
		})
	end
	local rankDef = tree.ranks[rank]
	print(("[Ability] %s used %s (%s) rank %d — %s"):format(
		player.Name,
		tree.ability,
		treeId,
		rank,
		rankDef and rankDef.effect or "?"
	))
	return nil
end

function AbilityService.clearPlayer(player: Player)
	cooldowns[player] = nil
end

return AbilityService
