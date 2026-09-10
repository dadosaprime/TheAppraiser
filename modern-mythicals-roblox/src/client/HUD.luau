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
	["heavy offense"] = 8, ["heavy offense / control"] = 8,
	["defense / signature"] = 2, ["control"] = 7, ["control / team"] = 8,
	["mobility offense"] = 5, ["escape"] = 8, ["movement"] = 4, ["utility / unlock"] = 3,
	["utility / tracking"] = 4, ["burst"] = 4, ["revive / support"] = 10,
}
-- Held forms lock a share of the pool instead of costing Soul.
local LOCK_PCT: { [string]: number } = { ["the shift"] = 40, ["defense + melee"] = 35, ["stealth + movement"] = 30 }
local FORM_LABEL: { [string]: string } = { shift = "WOLF FORM", aegis = "FLAME SHIELD", vanish = "VANISHED" }
local FORM_COLOR: { [string]: Color3 } = {
	shift = Color3.fromRGB(120, 20, 30),
	aegis = Color3.fromRGB(140, 70, 20),
	vanish = Color3.fromRGB(40, 45, 80),
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
local soulFill: Frame
local soulText: TextLabel
local soulLock: Frame
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

	-- Health and Soul (all classes). The Werewolf's shift greys out a slice of Soul.
	local _, hf, ht = makeBar(gui, UDim2.fromScale(0.01, 0.20), UDim2.fromScale(0.18, 0.035), Color3.fromRGB(70, 200, 110))
	healthFill, healthText = hf, ht
	local sr, sf, st = makeBar(gui, UDim2.fromScale(0.01, 0.245), UDim2.fromScale(0.18, 0.035), Color3.fromRGB(120, 130, 255))
	soulFill, soulText = sf, st
	soulText.Text = "SOUL"
	-- Locked slice: grey, anchored to the right end of the bar.
	soulLock = Instance.new("Frame")
	soulLock.AnchorPoint = Vector2.new(1, 0)
	soulLock.Position = UDim2.fromScale(1, 0)
	soulLock.Size = UDim2.fromScale(0, 1)
	soulLock.BackgroundColor3 = Color3.fromRGB(95, 95, 105)
	soulLock.BorderSizePixel = 0
	soulLock.ZIndex = 2
	soulLock.Parent = sr
	st.ZIndex = 3

	formBadge = makeLabel(gui, "WOLF FORM", UDim2.fromScale(0.01, 0.29), UDim2.fromScale(0.18, 0.04))
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
		"Click = attack   ·   1–5 abilities   ·   Shift+1–5 buy rank   ·   B buy Soul box   ·   K store",
		UDim2.fromScale(0.25, 0.855),
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
	for slot = 1, 5 do
		local treeId = class and class.trees[slot]
		local tree = treeId and PerkTrees.get(treeId)
		local owned = treeId and (profile.perks[treeId] or 0) or 0
		if tree then
			local tag = if class and treeId == class.attackTree then "🖱 " else ""
			local cost = SOUL_COST[tree.role] or 0
			local lockPct = LOCK_PCT[tree.role]
			local costText = if lockPct then ("  ·  locks %d%%"):format(lockPct) elseif cost > 0 then ("  ·  %d Soul"):format(cost) else ""
			slotButtons[slot].Text = ("%d  %s%s\nrank %d/%d%s"):format(slot, tag, tree.ability, owned, PerkTrees.MAX_RANK, costText)
			slotButtons[slot].TextColor3 = if owned > 0 then Color3.fromRGB(230, 225, 240) else Color3.fromRGB(120, 115, 135)
		else
			slotButtons[slot].Text = tostring(slot)
		end
	end
end

-- Transient combat status from the server (Soul, lock, shifted).
function HUD.setStatus(status: any)
	if type(status) ~= "table" then
		return
	end
	if type(status.soul) == "number" and type(status.soulMax) == "number" and status.soulMax > 0 then
		local lockedAmt = if type(status.soulLocked) == "number" then status.soulLocked else 0
		soulFill.Size = UDim2.fromScale(math.clamp(status.soul / status.soulMax, 0, 1), 1)
		soulLock.Size = UDim2.fromScale(math.clamp(lockedAmt / status.soulMax, 0, 1), 1)
		soulText.Text = if lockedAmt > 0
			then ("SOUL %d / %d   ·   %d locked"):format(status.soul, status.soulMax - lockedAmt, lockedAmt)
			else ("SOUL %d / %d"):format(status.soul, status.soulMax)
	end
	if status.form ~= nil then
		local form = status.form
		if type(form) == "string" and form ~= "" then
			formBadge.Text = FORM_LABEL[form] or string.upper(form)
			formBadge.BackgroundColor3 = FORM_COLOR[form] or Color3.fromRGB(60, 60, 70)
			formBadge.Visible = true
		else
			formBadge.Visible = false
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
