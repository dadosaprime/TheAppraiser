--!strict
-- Minimal HUD, built in code (no Studio needed). Shows Soul Rank + box
-- progress, Soul Shards, a five-slot hotbar with the class's ability names and
-- owned ranks, a toast line for messages, and a keybind hint.
-- Intentionally plain — this is a functional scaffold, not the final art pass.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Classes = require(Shared.Classes)
local PerkTrees = require(Shared.PerkTrees)
local SoulRanks = require(Shared.SoulRanks)

local player = Players.LocalPlayer

-- Mirror of the server's per-role Soul costs, for display only.
local SOUL_COST: { [string]: number } = {
	["heavy offense"] = 8, ["heavy offense / control"] = 8, ["defense + melee"] = 6,
	["defense / signature"] = 2, ["control"] = 7, ["control / team"] = 8,
	["mobility offense"] = 5, ["escape"] = 8, ["movement"] = 4, ["utility / unlock"] = 3,
	["utility / tracking"] = 4, ["stealth + movement"] = 6, ["burst"] = 4, ["revive / support"] = 10,
}

local HUD = {}

local gui: ScreenGui
local rankLabel: TextLabel
local shardLabel: TextLabel
local classLabel: TextLabel
local toastLabel: TextLabel
local slotButtons: { TextButton } = {}
local toastSerial = 0
local healthFill: Frame
local healthText: TextLabel
local furyRow: Frame
local furyFill: Frame
local furyText: TextLabel
local soulFill: Frame
local soulText: TextLabel
local formBadge: TextLabel
local currentClass: string? = nil

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

local function makeBar(parent: Instance, pos: UDim2, size: UDim2, color: Color3): (Frame, Frame, TextLabel)
	local row = Instance.new("Frame")
	row.Position = pos
	row.Size = size
	row.BackgroundColor3 = Color3.fromRGB(15, 12, 24)
	row.BackgroundTransparency = 0.35
	row.BorderSizePixel = 0
	row.Parent = parent
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = row
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(240, 236, 250)
	text.TextStrokeTransparency = 0.4
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Text = ""
	text.Parent = row
	return row, fill, text
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

	-- Health (all classes) and Fury (Werewolf only).
	local _, hf, ht = makeBar(gui, UDim2.fromScale(0.01, 0.20), UDim2.fromScale(0.18, 0.035), Color3.fromRGB(70, 200, 110))
	healthFill, healthText = hf, ht
	local _, sf, st = makeBar(gui, UDim2.fromScale(0.01, 0.245), UDim2.fromScale(0.18, 0.035), Color3.fromRGB(120, 130, 255))
	soulFill, soulText = sf, st
	soulText.Text = "SOUL"
	local fr, ff, ft = makeBar(gui, UDim2.fromScale(0.01, 0.29), UDim2.fromScale(0.18, 0.035), Color3.fromRGB(230, 90, 40))
	furyRow, furyFill, furyText = fr, ff, ft
	furyRow.Visible = false

	formBadge = makeLabel(gui, "WOLF FORM", UDim2.fromScale(0.01, 0.335), UDim2.fromScale(0.18, 0.04))
	formBadge.BackgroundColor3 = Color3.fromRGB(120, 20, 30)
	formBadge.BackgroundTransparency = 0.15
	formBadge.Visible = false

	-- Live health from the local character (replicates from the server).
	RunService.RenderStepped:Connect(function()
		local c = player.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if h and h.MaxHealth > 0 then
			local frac = math.clamp(h.Health / h.MaxHealth, 0, 1)
			healthFill.Size = UDim2.fromScale(frac, 1)
			healthText.Text = ("HP %d / %d"):format(math.floor(h.Health + 0.5), math.floor(h.MaxHealth + 0.5))
		end
	end)

	toastLabel = makeLabel(gui, "", UDim2.fromScale(0.3, 0.02), UDim2.fromScale(0.4, 0.05))
	toastLabel.BackgroundTransparency = 1
	toastLabel.TextColor3 = Color3.fromRGB(255, 225, 150)

	local hint = makeLabel(
		gui,
		"Click = attack   ·   1–5 abilities   ·   Shift+1–5 buy rank   ·   B buy Soul box",
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
	currentClass = profile.class
	classLabel.Text = class and class.displayName or "No class"
	furyRow.Visible = profile.class == "Werewolf"
	for slot = 1, 5 do
		local treeId = class and class.trees[slot]
		local tree = treeId and PerkTrees.get(treeId)
		local owned = treeId and (profile.perks[treeId] or 0) or 0
		if tree then
			local tag = if class and treeId == class.attackTree then "🖱 " else ""
			local cost = SOUL_COST[tree.role] or 0
			local costText = if cost > 0 then ("  ·  %d Soul"):format(cost) else ""
			slotButtons[slot].Text = ("%d  %s%s\nrank %d/%d%s"):format(slot, tag, tree.ability, owned, PerkTrees.MAX_RANK, costText)
			slotButtons[slot].TextColor3 = if owned > 0 then Color3.fromRGB(230, 225, 240) else Color3.fromRGB(120, 115, 135)
		else
			slotButtons[slot].Text = tostring(slot)
		end
	end
end

-- Transient combat status from the server (Fury, shifted).
function HUD.setStatus(status: any)
	if type(status) ~= "table" then
		return
	end
	if type(status.soul) == "number" and type(status.soulMax) == "number" and status.soulMax > 0 then
		soulFill.Size = UDim2.fromScale(math.clamp(status.soul / status.soulMax, 0, 1), 1)
		soulText.Text = ("SOUL %d / %d"):format(status.soul, status.soulMax)
	end
	if currentClass == "Werewolf" and type(status.fury) == "number" and type(status.furyMax) == "number" then
		local frac = math.clamp(status.fury / status.furyMax, 0, 1)
		furyFill.Size = UDim2.fromScale(frac, 1)
		local cost = status.shiftCost or 0
		furyText.Text = if status.shifted
			then ("FURY %d — draining"):format(status.fury)
			else ("FURY %d / %d  (shift at %d)"):format(status.fury, status.furyMax, cost)
		furyFill.BackgroundColor3 = if status.fury >= cost then Color3.fromRGB(255, 110, 40) else Color3.fromRGB(150, 60, 30)
	end
	if status.shifted ~= nil then
		formBadge.Visible = status.shifted == true
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
