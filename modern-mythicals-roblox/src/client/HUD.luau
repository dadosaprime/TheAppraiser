--!strict
-- Minimal HUD, built in code (no Studio needed). Shows class, Soul Rank + box
-- progress, Soul Shards, and a five-slot hotbar with the class's ability names.
-- Intentionally plain — this is a functional scaffold, not the final art pass.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Classes = require(Shared.Classes)
local PerkTrees = require(Shared.PerkTrees)
local SoulRanks = require(Shared.SoulRanks)

local player = Players.LocalPlayer

local HUD = {}

local gui: ScreenGui
local rankLabel: TextLabel
local shardLabel: TextLabel
local slotButtons: { TextButton } = {}

local function makeLabel(parent: Instance, text: string, pos: UDim2, size: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(15, 12, 24)
	label.TextColor3 = Color3.fromRGB(235, 230, 245)
	label.Font = Enum.Font.GothamMedium
	label.TextScaled = true
	label.Text = text
	label.Position = pos
	label.Size = size
	label.Parent = parent
	return label
end

function HUD.build()
	gui = Instance.new("ScreenGui")
	gui.Name = "ModernMythicalsHUD"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	rankLabel = makeLabel(gui, "Soul Rank —", UDim2.fromScale(0.01, 0.02), UDim2.fromScale(0.18, 0.05))
	shardLabel = makeLabel(gui, "Shards: —", UDim2.fromScale(0.01, 0.08), UDim2.fromScale(0.18, 0.05))

	-- Five-slot hotbar centered at the bottom.
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.fromScale(0.5, 0.98)
	bar.Size = UDim2.fromScale(0.5, 0.09)
	bar.BackgroundTransparency = 1
	bar.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0.01, 0)
	layout.Parent = bar

	for slot = 1, 5 do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromScale(0.19, 1)
		btn.BackgroundColor3 = Color3.fromRGB(28, 22, 40)
		btn.TextColor3 = Color3.fromRGB(230, 225, 240)
		btn.Font = Enum.Font.Gotham
		btn.TextScaled = true
		btn.Text = tostring(slot)
		btn.Parent = bar
		slotButtons[slot] = btn
	end
end

-- Update the hotbar labels from the player's class.
function HUD.setClass(classId: string?)
	if not classId then
		return
	end
	local class = Classes.get(classId)
	if not class then
		return
	end
	for slot = 1, 5 do
		local treeId = class.trees[slot]
		local tree = treeId and PerkTrees.get(treeId)
		slotButtons[slot].Text = ("%d\n%s"):format(slot, tree and tree.ability or "")
	end
end

-- Refresh live numbers from a pushed profile.
function HUD.update(profile: any)
	if not profile then
		return
	end
	rankLabel.Text = ("Soul Rank %d  [%d/%d]"):format(
		profile.soulRank,
		profile.boxesInRank,
		SoulRanks.BOXES_PER_RANK
	)
	shardLabel.Text = ("Shards: %d"):format(profile.soulShards)
	HUD.setClass(profile.class)
end

-- Flash a slot on cooldown / error feedback.
function HUD.flashSlot(slot: number, feedback: any)
	local btn = slotButtons[slot]
	if not btn then
		return
	end
	local color = feedback.ok and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(140, 50, 50)
	btn.BackgroundColor3 = color
	task.delay(0.2, function()
		btn.BackgroundColor3 = Color3.fromRGB(28, 22, 40)
	end)
end

return HUD
