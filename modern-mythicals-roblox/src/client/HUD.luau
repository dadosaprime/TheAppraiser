--!strict
-- Minimal HUD, built in code (no Studio needed). Shows Soul Rank + box
-- progress, Soul Shards, a five-slot hotbar with the class's ability names and
-- owned ranks, a toast line for messages, and a keybind hint.
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
local classLabel: TextLabel
local toastLabel: TextLabel
local slotButtons: { TextButton } = {}
local toastSerial = 0

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

	classLabel = makeLabel(gui, "—", UDim2.fromScale(0.01, 0.02), UDim2.fromScale(0.18, 0.05))
	rankLabel = makeLabel(gui, "Soul Rank —", UDim2.fromScale(0.01, 0.08), UDim2.fromScale(0.18, 0.05))
	shardLabel = makeLabel(gui, "Shards: —", UDim2.fromScale(0.01, 0.14), UDim2.fromScale(0.18, 0.05))

	toastLabel = makeLabel(gui, "", UDim2.fromScale(0.3, 0.02), UDim2.fromScale(0.4, 0.05))
	toastLabel.BackgroundTransparency = 1
	toastLabel.TextColor3 = Color3.fromRGB(255, 225, 150)

	local hint = makeLabel(
		gui,
		"Click / 1 attack   ·   2–5 abilities   ·   Shift+1–5 buy rank   ·   B buy Soul box",
		UDim2.fromScale(0.25, 0.905),
		UDim2.fromScale(0.5, 0.03)
	)
	hint.BackgroundTransparency = 1
	hint.TextColor3 = Color3.fromRGB(150, 145, 170)

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

-- Refresh live numbers + hotbar labels from a pushed profile.
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

	local class = profile.class and Classes.get(profile.class)
	classLabel.Text = class and class.displayName or "No class"
	for slot = 1, 5 do
		local treeId = class and class.trees[slot]
		local tree = treeId and PerkTrees.get(treeId)
		local owned = treeId and (profile.perks[treeId] or 0) or 0
		if tree then
			slotButtons[slot].Text = ("%d  %s\nrank %d/%d"):format(slot, tree.ability, owned, PerkTrees.MAX_RANK)
			slotButtons[slot].TextColor3 = if owned > 0 then Color3.fromRGB(230, 225, 240) else Color3.fromRGB(120, 115, 135)
		else
			slotButtons[slot].Text = tostring(slot)
		end
	end
end

-- Short message at the top; fades after a moment.
function HUD.toast(msg: string)
	toastSerial += 1
	local mine = toastSerial
	toastLabel.Text = msg
	task.delay(2.5, function()
		if toastSerial == mine then
			toastLabel.Text = ""
		end
	end)
end

-- Flash a slot on cooldown / error feedback.
function HUD.flashSlot(slot: number, feedback: any)
	local btn = slotButtons[slot]
	if not btn then
		return
	end
	btn.BackgroundColor3 = if feedback.ok then Color3.fromRGB(60, 120, 60) else Color3.fromRGB(140, 50, 50)
	task.delay(0.2, function()
		btn.BackgroundColor3 = Color3.fromRGB(28, 22, 40)
	end)
end

return HUD
