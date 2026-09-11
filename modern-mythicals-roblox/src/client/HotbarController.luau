--!strict
-- Hotbar input. One tree, one button — keys 1..5 map straight to ability slots.
-- The client only REQUESTS activation; the server is authoritative (see AbilityService).
--
-- Playtest keybinds (documented in the HUD hint):
--   Left click   basic attack (slot 1)
--   1-5          activate the ability on that slot
--   Shift + 1-5  buy the next rank of the tree on that slot (Soul Shards)
--   B            buy the next Soul-Rank box (Soul Shards)

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Net = require(Shared.Net)
local Classes = require(Shared.Classes)

local HotbarController = {}

-- Set by the client bootstrap from the latest profile.
HotbarController.currentClass = nil :: string?
-- Slot that holds the class's basic attack (for the local cooldown mirror).
HotbarController.attackSlot = nil :: number?

-- Called with (slot, feedback) so the HUD can flash cooldowns/errors.
HotbarController.onFeedback = function(_slot: number, _feedback: any) end
-- Called with a short player-facing message (purchases, errors).
HotbarController.onMessage = function(_msg: string) end

local KEY_TO_SLOT: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
}

-- World point under the mouse cursor. Mouse.Hit ignores the local character; the
-- FX folder is filtered so projectiles don't block their own aim.
local function aimPoint(): Vector3?
	local mouse = Players.LocalPlayer:GetMouse()
	local fx = Workspace:FindFirstChild("FX")
	if fx then
		mouse.TargetFilter = fx
	end
	return mouse.Hit.Position
end

-- One press is one request. A slot on cooldown (mirrored from the server's
-- last answer) is not sent at all, and a press is never queued: if the last
-- request has not been answered yet, the new press is dropped. Every request
-- carries the synced clock so the server can discard anything that arrives
-- late instead of running a backlog after the fight is over.
local readyAt: { [number]: number } = {}
local inFlight = false
local inFlightSince = 0

local function canSend(slot: number?): boolean
	local now = Workspace:GetServerTimeNow()
	if inFlight and now - inFlightSince < 0.5 then
		return false
	end
	if slot and (readyAt[slot] or 0) > now then
		return false
	end
	inFlight = true
	inFlightSince = now
	return true
end

local function shiftHeld(): boolean
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
end

local function purchasePerkForSlot(slot: number)
	local classId = HotbarController.currentClass
	if not classId then
		HotbarController.onMessage("Choose a class first.")
		return
	end
	local class = Classes.get(classId :: any)
	local treeId = class and class.trees[slot]
	if not treeId then
		return
	end
	local result = Net.get("PurchasePerk"):InvokeServer(treeId)
	if type(result) ~= "table" then
		return
	end
	if result.ok then
		local rank = result.profile and result.profile.perks[treeId] or 0
		HotbarController.onMessage(("%s → rank %d"):format(treeId, rank))
	else
		HotbarController.onMessage(result.err or "purchase failed")
	end
end

local function purchaseBox()
	local result = Net.get("PurchaseBox"):InvokeServer()
	if type(result) ~= "table" then
		return
	end
	if result.ok then
		HotbarController.onMessage(if result.rankedUp then "SOUL RANK UP!" else "Bought a Soul box.")
	else
		HotbarController.onMessage(result.err or "cannot buy box")
	end
end

function HotbarController.start()
	local activate = Net.get("ActivateAbility")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Left click = the class's basic attack (server resolves which slot).
			if canSend(HotbarController.attackSlot) then
				activate:FireServer({ attack = true, aimPoint = aimPoint(), t = Workspace:GetServerTimeNow() })
			end
			return
		end
		local slot = KEY_TO_SLOT[input.KeyCode]
		if slot then
			if shiftHeld() then
				task.spawn(purchasePerkForSlot, slot)
			elseif canSend(slot) then
				-- Aim at the point under the cursor; the server validates it.
				activate:FireServer({ slot = slot, aimPoint = aimPoint(), t = Workspace:GetServerTimeNow() })
			end
		elseif input.KeyCode == Enum.KeyCode.B then
			task.spawn(purchaseBox)
		end
	end)

	Net.get("AbilityFeedback").OnClientEvent:Connect(function(feedback)
		inFlight = false
		if type(feedback) == "table" and feedback.slot then
			if type(feedback.cooldown) == "number" and feedback.cooldown > 0 then
				readyAt[feedback.slot] = Workspace:GetServerTimeNow() + feedback.cooldown
			end
			HotbarController.onFeedback(feedback.slot, feedback)
		end
	end)
end

return HotbarController
