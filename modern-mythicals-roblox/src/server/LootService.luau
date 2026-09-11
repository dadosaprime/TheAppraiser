--!strict
-- Loot crates. The generator places crates named "LootCrate_<tier>_<tag>" with a
-- ProximityPrompt child on the floors and roofs of explorable buildings. This
-- service wires every prompt: open it, get Soul Shards + Cash scaled by tier,
-- the crate goes dark, and it respawns a few minutes later. Higher floors pay
-- more, so climbing is worth it. Numbers are PLACEHOLDERS for playtest.

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Net = require(Shared.Net)

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local Effects = require(script.Parent.Effects)

local LootService = {}

local RESPAWN_SECONDS = 180
local GOLD = Color3.fromRGB(255, 215, 90)

-- Shard and cash ranges per tier: S = ground floor, M = upper floors, L = roof.
local TIERS: { [string]: { shards: { number }, cash: { number }, label: string } } = {
	S = { shards = { 60, 120 }, cash = { 10, 30 }, label = "Crate" },
	M = { shards = { 120, 260 }, cash = { 30, 60 }, label = "Stash" },
	L = { shards = { 260, 500 }, cash = { 60, 120 }, label = "Cache" },
}

local function tierOf(crate: Instance): string?
	return crate.Name:match("^LootCrate_([SML])_")
end

local function open(player: Player, crate: BasePart, prompt: ProximityPrompt)
	if crate:GetAttribute("Looted") then
		return
	end
	local tier = TIERS[tierOf(crate) or "S"]
	local profile = DataService.get(player)
	if not tier or not profile then
		return
	end
	crate:SetAttribute("Looted", true)
	prompt.Enabled = false

	local shards = math.random(tier.shards[1], tier.shards[2])
	local cash = math.random(tier.cash[1], tier.cash[2])
	ProgressionService.awardShards(player, shards) -- pushes the profile
	profile.cash += cash
	DataService.markDirty(player)
	ProgressionService._push(player, profile)

	Effects.burst(crate.Position, GOLD, 4, 0.5)
	Effects.damageNumber(crate.Position, shards, GOLD)
	Net.get("Toast"):FireClient(player, ("%s: +%d Shards, +$%d"):format(tier.label, shards, cash))

	local color0 = crate.Color
	crate.Transparency = 0.7
	crate.Color = Color3.fromRGB(60, 50, 40)
	task.delay(RESPAWN_SECONDS, function()
		if crate.Parent then
			crate.Transparency = 0
			crate.Color = color0
			crate:SetAttribute("Looted", nil)
			prompt.Enabled = true
		end
	end)
end

local function wire(prompt: ProximityPrompt)
	local crate = prompt.Parent
	if not crate or not crate:IsA("BasePart") or not tierOf(crate) then
		return
	end
	prompt.Triggered:Connect(function(player)
		open(player, crate, prompt)
	end)
end

function LootService.init()
	local count = 0
	for _, d in Workspace:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			wire(d)
			count += 1
		end
	end
	Workspace.DescendantAdded:Connect(function(d)
		if d:IsA("ProximityPrompt") then
			wire(d)
		end
	end)
	print(("[Loot] %d crates wired."):format(count))
end

return LootService
